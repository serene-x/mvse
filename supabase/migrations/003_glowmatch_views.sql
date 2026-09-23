-- GlowMatch consumer app: views + RPCs.
-- Run after schema.sql and 002_admin_tool.sql.

-- product_with_mention_count: discovery feed sort key
-- drop first: 008 widens this view's column list, and CREATE OR REPLACE
-- can't narrow it back when the runner re-applies migrations idempotently
drop view if exists public.product_with_mention_count;
create view public.product_with_mention_count as
select
  p.id, p.name, p.brand, p.category, p.ingredient_list,
  p.sephora_url, p.ulta_url, p.created_at,
  coalesce(m.cnt, 0) as mention_count,
  m.last_mentioned
from public.products p
left join (
  select product_id, count(*)::int as cnt, max(created_at) as last_mentioned
  from public.tiktok_mentions
  group by product_id
) m on m.product_id = p.id;

grant select on public.product_with_mention_count to anon, authenticated;

-- product_top_sentiments: top sentiment tags per product (flattened)
create or replace view public.product_top_sentiments as
select
  product_id,
  tag,
  count(*)::int as cnt
from public.tiktok_mentions tm,
     lateral jsonb_array_elements_text(
       case when jsonb_typeof(tm.sentiment_tags) = 'array' then tm.sentiment_tags else '[]'::jsonb end
     ) as tag
group by product_id, tag;

grant select on public.product_top_sentiments to anon, authenticated;

-- match_user_to_creators: Jaccard-ish similarity over (brand|product|shade)
-- tuples between user_owned_products and creators.shade_profile.
-- Best-effort scoring; tune for your data.
create or replace function public.match_user_to_creators(p_user_id uuid, p_limit int default 10)
returns table (
  creator_id uuid,
  tiktok_handle text,
  skin_tone_desc text,
  shared int,
  total int,
  similarity numeric
) language sql stable as $$
  with user_tuples as (
    select distinct
      lower(coalesce(p.brand, '')) || '|' ||
      lower(coalesce(p.name, '')) || '|' ||
      lower(coalesce(uop.shade_name, '')) as tup
    from public.user_owned_products uop
    join public.products p on p.id = uop.product_id
    where uop.user_id = p_user_id
  ),
  creator_tuples as (
    select
      c.id            as cid,
      c.tiktok_handle as handle,
      c.skin_tone_desc as tone,
      lower(coalesce(brand_key, '')) || '|' ||
      lower(coalesce(elem->>'product', '')) || '|' ||
      lower(coalesce(elem->>'shade', '')) as tup
    from public.creators c,
         lateral jsonb_each(coalesce(c.shade_profile, '{}'::jsonb)) as kv(brand_key, items),
         lateral jsonb_array_elements(
           case when jsonb_typeof(kv.items) = 'array' then kv.items else '[]'::jsonb end
         ) as elem
  ),
  agg as (
    select
      ct.cid, ct.handle, ct.tone,
      count(*) filter (where ut.tup is not null) as shared_n,
      count(distinct ct.tup)                     as total_n
    from creator_tuples ct
    left join user_tuples ut on ut.tup = ct.tup
    group by ct.cid, ct.handle, ct.tone
  )
  select
    cid, handle, tone, shared_n::int, total_n::int,
    case when total_n = 0 then 0
         else round(shared_n::numeric / total_n::numeric, 4)
    end as similarity
  from agg
  where shared_n > 0
  order by similarity desc, shared_n desc
  limit p_limit;
$$;

grant execute on function public.match_user_to_creators(uuid, int) to authenticated;

-- recommended_products_for_user: products mentioned by the user's twin
-- creators that the user does not currently own.
-- drop first: 015 widens this function's return type, and CREATE OR REPLACE
-- can't change a return type when the runner re-applies migrations
-- idempotently (015 re-creates the wide version right after).
drop function if exists public.recommended_products_for_user(uuid, int);
create function public.recommended_products_for_user(p_user_id uuid, p_limit int default 50)
returns table (
  id uuid,
  name text,
  brand text,
  category text,
  sephora_url text,
  ulta_url text,
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
    p.id, p.name, p.brand, p.category, p.sephora_url, p.ulta_url,
    tm.twin_count, tm.total_mentions
  from twin_mentions tm
  join public.products p on p.id = tm.product_id
  where tm.product_id not in (select product_id from user_owned)
  order by tm.twin_count desc, tm.total_mentions desc
  limit p_limit;
$$;

grant execute on function public.recommended_products_for_user(uuid, int) to authenticated;

-- your_shade_for_product: recommend a shade for a given product based on
-- shade twin matches. Returns the most-confidently-matched shade by
-- summing twin similarity scores per shade name.
create or replace function public.your_shade_for_product(p_user_id uuid, p_product_id uuid)
returns table (shade_name text, hex_color text, score numeric) language sql stable as $$
  with twins as (
    select creator_id, similarity from public.match_user_to_creators(p_user_id, 25)
  ),
  twin_shades as (
    -- Pull shades from the twins' shade_profile that are tagged for this product.
    select elem->>'shade' as shade_name, t.similarity
    from twins t
    join public.creators c on c.id = t.creator_id,
    lateral jsonb_each(coalesce(c.shade_profile, '{}'::jsonb)) as kv(brand_key, items),
    lateral jsonb_array_elements(
      case when jsonb_typeof(kv.items) = 'array' then kv.items else '[]'::jsonb end
    ) as elem
    join public.products p on p.id = p_product_id
    where lower(coalesce(brand_key, '')) = lower(coalesce(p.brand, ''))
      and lower(coalesce(elem->>'product', '')) = lower(coalesce(p.name, ''))
      and (elem->>'shade') is not null
  ),
  scored as (
    select shade_name, sum(similarity) as score
    from twin_shades
    group by shade_name
  )
  select s.shade_name, ps.hex_color, s.score
  from scored s
  left join public.product_shades ps
    on ps.product_id = p_product_id and lower(ps.shade_name) = lower(s.shade_name)
  order by s.score desc
  limit 1;
$$;

grant execute on function public.your_shade_for_product(uuid, uuid) to authenticated;
