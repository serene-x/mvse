-- Pricing, size, and demo-data hygiene.
--
-- THREE things, in one coherent migration so the shared view/RPC rebuilds
-- happen exactly once:
--
--  1. price + size on products (with provenance, like every other field).
--     Prices are TYPICAL US RETAIL captured on price_as_of — they drift, so
--     the UI always frames them as "typical retail, ~date", never a live
--     quote. Sizes come off the label / Open Beauty Facts and are stable.
--
--  2. category_price_stats view: per (category, size_unit) average price-per-
--     unit, so a product can be shown in context ("about average for a serum").
--
--  3. is_demo flags on creators/videos/mentions, and — critically — the
--     real-product surfaces (mention_count, top_sentiments, the "From TikTok"
--     list) now EXCLUDE demo rows. Demo data still drives the shade-twin /
--     For You engine (that's its whole purpose) but never masquerades as real
--     TikTok sentiment/mentions on a product page. Honesty rule, enforced in SQL.

-- 1. products: price + size, with provenance
alter table public.products
  -- Where the photo was mirrored FROM (the official brand/retailer URL), kept
  -- as provenance once image_url is repointed at our own Storage bucket.
  add column if not exists image_source_url text,
  add column if not exists price_usd numeric(8,2)
    check (price_usd is null or price_usd >= 0),
  add column if not exists price_source text
    check (price_source in ('retailer','brand','msrp','seed_estimate') or price_source is null),
  add column if not exists price_as_of date,
  add column if not exists size_value numeric(9,2)
    check (size_value is null or size_value > 0),
  add column if not exists size_unit text
    check (size_unit in ('ml','g') or size_unit is null),
  add column if not exists size_source text
    check (size_source in ('label','openbeautyfacts','retailer','brand','seed_estimate') or size_source is null);

-- Re-run 013's PAO backfill so any product inserted AFTER 013 (the v2 catalog)
-- still gets a category default. Idempotent: only fills NULLs.
update public.products set default_pao_months = case category
  when 'sunscreen'   then 12  when 'serum'       then 6   when 'treatment'   then 6
  when 'exfoliant'   then 12  when 'moisturizer' then 12  when 'cleanser'    then 12
  when 'toner'       then 12  when 'mask'        then 12  when 'eye_cream'   then 6
  when 'face_oil'    then 12  when 'foundation'  then 12  when 'concealer'   then 12
  when 'blush'       then 24  when 'lip'         then 18  else 12
end
where default_pao_months is null;

-- 2. is_demo flags
alter table public.creators       add column if not exists is_demo boolean not null default false;
alter table public.tiktok_videos  add column if not exists is_demo boolean not null default false;
alter table public.tiktok_mentions add column if not exists is_demo boolean not null default false;

-- 3. category_price_stats: average price-per-unit within (category, unit).
-- Only products with BOTH price and size contribute. Compared within the same
-- unit so ml-vs-g is never mixed.
create or replace view public.category_price_stats as
select
  category,
  size_unit,
  count(*)::int as n,
  round(avg(price_usd / size_value)::numeric, 4) as avg_price_per_unit,
  round(min(price_usd / size_value)::numeric, 4) as min_price_per_unit,
  round(max(price_usd / size_value)::numeric, 4) as max_price_per_unit
from public.products
where price_usd is not null and size_value is not null and size_value > 0 and size_unit is not null
group by category, size_unit;

grant select on public.category_price_stats to anon, authenticated;

-- product_with_mention_count: add price/size columns; count only REAL mentions.
-- (drop+recreate: extends the column list; 015 was the previous definition)
drop view if exists public.product_with_mention_count;
create view public.product_with_mention_count as
select
  p.id, p.name, p.brand, p.category, p.ingredient_list,
  p.sephora_url, p.ulta_url, p.created_at,
  p.summary, p.finish, p.coverage, p.how_it_wears, p.skincare_benefits,
  p.ingredient_list_source, p.ingredient_list_updated_at,
  p.region, p.data_notes, p.data_source,
  p.image_url, p.image_source, p.default_pao_months,
  p.price_usd, p.price_source, p.price_as_of,
  p.size_value, p.size_unit, p.size_source,
  coalesce(m.cnt, 0) as mention_count,
  m.last_mentioned
from public.products p
left join (
  select product_id, count(*)::int as cnt, max(created_at) as last_mentioned
  from public.tiktok_mentions
  where not coalesce(is_demo, false)          -- demo mentions never inflate real counts
  group by product_id
) m on m.product_id = p.id;

grant select on public.product_with_mention_count to anon, authenticated;

-- product_top_sentiments: exclude demo mentions so fabricated demo sentiment
-- never surfaces on a real product page.
create or replace view public.product_top_sentiments as
select
  product_id,
  tag,
  count(*)::int as cnt
from public.tiktok_mentions tm,
     lateral jsonb_array_elements_text(
       case when jsonb_typeof(tm.sentiment_tags) = 'array' then tm.sentiment_tags else '[]'::jsonb end
     ) as tag
where not coalesce(tm.is_demo, false)
group by product_id, tag;

grant select on public.product_top_sentiments to anon, authenticated;

-- recommended_products_for_user: add price/size to the For You card payload.
-- (Demo mentions ARE included here — this is the twin engine they exist for.)
-- drop+recreate: return type changes again (015 added image_url).
drop function if exists public.recommended_products_for_user(uuid, int);
create function public.recommended_products_for_user(p_user_id uuid, p_limit int default 50)
returns table (
  id uuid,
  name text,
  brand text,
  category text,
  sephora_url text,
  ulta_url text,
  image_url text,
  price_usd numeric,
  size_value numeric,
  size_unit text,
  twin_count int,
  total_mentions int
) language sql stable as $$
  with twins as (
    select creator_id from public.match_user_to_creators(p_user_id, 25)
  ),
  twin_mentions as (
    select tm.product_id,
           count(distinct v.creator_id)::int as twin_count,
           count(*)::int                     as total_mentions
    from public.tiktok_mentions tm
    join public.tiktok_videos v on v.id = tm.video_id
    where v.creator_id in (select creator_id from twins)
    group by tm.product_id
  ),
  user_owned as (
    select product_id from public.user_owned_products where user_id = p_user_id
  )
  select
    p.id, p.name, p.brand, p.category, p.sephora_url, p.ulta_url, p.image_url,
    p.price_usd, p.size_value, p.size_unit,
    tm.twin_count, tm.total_mentions
  from twin_mentions tm
  join public.products p on p.id = tm.product_id
  where tm.product_id not in (select product_id from user_owned)
  order by tm.twin_count desc, tm.total_mentions desc
  limit p_limit;
$$;

grant execute on function public.recommended_products_for_user(uuid, int) to authenticated;
