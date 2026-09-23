-- Product images.
--
-- image_url points at an OFFICIAL product photo (brand site / retailer CDN),
-- verified reachable at seed time. image_source records where it came from —
-- same provenance-first policy as every other data field. Images are
-- hotlinked, not copied: formulas and packshots change, and we'd rather show
-- the brand's current photo than a stale copy we can't stand behind.
-- The app renders a neutral branded placeholder when image_url is null or
-- the link rots — a missing photo is never treated as an error.

alter table public.products
  add column if not exists image_url text,
  add column if not exists image_source text
    check (image_source in ('brand_site','shopify_cdn','ulta_cdn','sephora_cdn','other')
           or image_source is null);

-- product_with_mention_count: rebuild with image columns.
-- Also adds default_pao_months, which 013 added to products but was never
-- widened into this view — the app reads it via Product.fromMap and silently
-- got null for any product fetched through the view.
-- (drop + recreate: CREATE OR REPLACE can't reorder/extend column lists)
drop view if exists public.product_with_mention_count;
create view public.product_with_mention_count as
select
  p.id, p.name, p.brand, p.category, p.ingredient_list,
  p.sephora_url, p.ulta_url, p.created_at,
  p.summary, p.finish, p.coverage, p.how_it_wears, p.skincare_benefits,
  p.ingredient_list_source, p.ingredient_list_updated_at,
  p.region, p.data_notes, p.data_source,
  p.image_url, p.image_source, p.default_pao_months,
  coalesce(m.cnt, 0) as mention_count,
  m.last_mentioned
from public.products p
left join (
  select product_id, count(*)::int as cnt, max(created_at) as last_mentioned
  from public.tiktok_mentions
  group by product_id
) m on m.product_id = p.id;

grant select on public.product_with_mention_count to anon, authenticated;

-- recommended_products_for_user: recreate to also return image_url.
-- (DROP first: CREATE OR REPLACE cannot change a function's return type.)
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
    tm.twin_count, tm.total_mentions
  from twin_mentions tm
  join public.products p on p.id = tm.product_id
  where tm.product_id not in (select product_id from user_owned)
  order by tm.twin_count desc, tm.total_mentions desc
  limit p_limit;
$$;

grant execute on function public.recommended_products_for_user(uuid, int) to authenticated;
