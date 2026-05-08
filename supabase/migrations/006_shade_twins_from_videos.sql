-- Derive shade equivalences from video co-occurrence in extracted_entities.
-- "Shades A and B are twins" iff they were both confirmed (product_id +
-- shade_id set, reviewed=true) on entries from the same TikTok video — i.e.
-- a creator described both as parts of one person's complexion.

-- For a given (product, shade) the user owns, return all OTHER (product, shade)
-- pairs that co-occurred in at least one video, ranked by how many videos
-- back the equivalence.
create or replace function public.shade_equivalences_for(
  p_product_id uuid,
  p_shade_id   uuid,
  p_limit      int default 50
)
returns table (
  product_id     uuid,
  shade_id       uuid,
  brand          text,
  product_name   text,
  shade_name     text,
  hex_color      text,
  shared_videos  int
) language sql stable as $$
  with anchor_videos as (
    select distinct ee.video_id
    from public.extracted_entities ee
    where ee.reviewed   = true
      and ee.product_id = p_product_id
      and ee.shade_id   = p_shade_id
  )
  select
    pr.id            as product_id,
    ps.id            as shade_id,
    pr.brand,
    pr.name          as product_name,
    ps.shade_name,
    ps.hex_color,
    count(distinct ee.video_id)::int as shared_videos
  from public.extracted_entities ee
  join anchor_videos av on av.video_id = ee.video_id
  join public.product_shades ps on ps.id = ee.shade_id
  join public.products pr        on pr.id = ee.product_id
  where ee.reviewed = true
    and ee.product_id is not null
    and ee.shade_id   is not null
    and not (ee.product_id = p_product_id and ee.shade_id = p_shade_id)
  group by pr.id, ps.id, pr.brand, pr.name, ps.shade_name, ps.hex_color
  order by shared_videos desc
  limit p_limit;
$$;

grant execute on function public.shade_equivalences_for(uuid, uuid, int) to anon, authenticated;

-- For a logged-in user: for each shade they own, surface the strongest
-- twin candidates that they don't already own.
create or replace function public.shade_twins_for_user(p_user_id uuid, p_limit int default 50)
returns table (
  source_product_id uuid,
  source_shade_id   uuid,
  twin_product_id   uuid,
  twin_shade_id     uuid,
  brand             text,
  product_name      text,
  shade_name        text,
  hex_color         text,
  shared_videos     int
) language sql stable as $$
  with user_shades as (
    -- match user_owned_products → product_shades by shade_name (case-insensitive)
    select uop.product_id,
           ps.id as shade_id
    from public.user_owned_products uop
    join public.product_shades ps
      on ps.product_id = uop.product_id
     and lower(ps.shade_name) = lower(coalesce(uop.shade_name, ''))
    where uop.user_id = p_user_id
  ),
  user_owned_pairs as (
    select product_id, shade_id from user_shades
  ),
  twins as (
    select
      us.product_id as source_product_id,
      us.shade_id   as source_shade_id,
      eq.*
    from user_shades us
    cross join lateral public.shade_equivalences_for(us.product_id, us.shade_id, 100) eq
    where (eq.product_id, eq.shade_id) not in (select * from user_owned_pairs)
  )
  select
    source_product_id, source_shade_id,
    product_id   as twin_product_id,
    shade_id     as twin_shade_id,
    brand, product_name, shade_name, hex_color,
    shared_videos
  from twins
  order by shared_videos desc
  limit p_limit;
$$;

grant execute on function public.shade_twins_for_user(uuid, int) to authenticated;
