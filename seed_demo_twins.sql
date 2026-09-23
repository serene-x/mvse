-- Synthetic development fixtures, enabled with apply_migrations.js --demo.
-- Demo handles use mvse_demo_ and video URLs use the reserved .invalid domain.
-- Cleanup: delete the corresponding mentions, videos, then creators.

insert into public.creators (tiktok_handle, skin_tone_desc, is_demo, shade_profile) values
('mvse_demo_ava', 'light-medium, warm (demo profile)', true, '{
  "Rare Beauty":    [{"product": "Liquid Touch Weightless Foundation", "shade": "240W"},
                     {"product": "Soft Pinch Liquid Blush",            "shade": "Hope"}],
  "Summer Fridays": [{"product": "Lip Butter Balm",                    "shade": "Vanilla"}]
}'::jsonb),
('mvse_demo_noor', 'light-medium (demo profile)', true, '{
  "Rare Beauty": [{"product": "Liquid Touch Weightless Foundation", "shade": "240W"}],
  "NARS":        [{"product": "Sheer Glow Foundation",              "shade": "Deauville"}],
  "Saie":        [{"product": "Dew Blush Liquid Blush",             "shade": "Sunkissed"}]
}'::jsonb),
('mvse_demo_jade', 'medium, warm (demo profile)', true, '{
  "Rare Beauty":       [{"product": "Liquid Touch Weightless Foundation", "shade": "240W"}],
  "Armani Beauty":     [{"product": "Luminous Silk Perfect Glow Flawless Foundation", "shade": "7"}],
  "Charlotte Tilbury": [{"product": "Matte Revolution Lipstick",          "shade": "Pillow Talk"}]
}'::jsonb)
on conflict (tiktok_handle) do nothing;

insert into public.tiktok_videos (video_url, creator_id, creator_handle, caption, status, is_demo)
select v.url, c.id, c.tiktok_handle, v.caption, 'ready', true
from (values
  ('https://demo.mvse.invalid/ava-shade-tour',  'mvse_demo_ava',
   '[MVSE demo seed] Shade tour — synthetic demo data that powers the For You feed. Not a real TikTok.'),
  ('https://demo.mvse.invalid/noor-favorites',  'mvse_demo_noor',
   '[MVSE demo seed] Current favorites — synthetic demo data that powers the For You feed. Not a real TikTok.'),
  ('https://demo.mvse.invalid/jade-everyday',   'mvse_demo_jade',
   '[MVSE demo seed] Everyday picks — synthetic demo data that powers the For You feed. Not a real TikTok.')
) as v(url, handle, caption)
join public.creators c on c.tiktok_handle = v.handle
on conflict (video_url) do nothing;

-- Demo mentions: what each demo twin "recommends". Products chosen to NOT
-- overlap the demo user's typical starter collection so For You has content.
insert into public.tiktok_mentions (product_id, video_id, video_url, sentiment_tags, view_count, confirmed, is_demo)
select p.id, tv.id, tv.video_url, m.tags::jsonb, m.views, true, true
from (values
  ('https://demo.mvse.invalid/ava-shade-tour', 'Charlotte Tilbury', 'Hollywood Flawless Filter',            '["glowy","natural"]',      12400),
  ('https://demo.mvse.invalid/ava-shade-tour', 'Glow Recipe',       'Watermelon Glow Niacinamide Dew Drops','["dewy","glowy"]',          9800),
  ('https://demo.mvse.invalid/ava-shade-tour', 'Laneige',           'Lip Sleeping Mask',                    '["hydrating","balmy"]',     15200),
  ('https://demo.mvse.invalid/noor-favorites', 'Supergoop!',        'Unseen Sunscreen SPF 40',              '["invisible","smooth"]',    11100),
  ('https://demo.mvse.invalid/noor-favorites', 'Rare Beauty',       'Soft Pinch Liquid Blush',              '["blendable","pigmented"]', 20400),
  ('https://demo.mvse.invalid/noor-favorites', 'Summer Fridays',    'Lip Butter Balm',                      '["hydrating","balmy"]',     13300),
  ('https://demo.mvse.invalid/jade-everyday',  'EltaMD',            'UV Clear Broad-Spectrum SPF 46',       '["gentle","no-cast"]',       8700),
  ('https://demo.mvse.invalid/jade-everyday',  'NARS',              'Radiant Creamy Concealer',             '["creamy","natural"]',      17600),
  ('https://demo.mvse.invalid/jade-everyday',  'Saie',              'Dew Blush Liquid Blush',               '["dewy","natural"]',         7900)
) as m(video_url, brand, product, tags, views)
join public.tiktok_videos tv on tv.video_url = m.video_url
join public.products p on p.brand = m.brand and p.name = m.product
where not exists (
  select 1 from public.tiktok_mentions existing
  where existing.product_id = p.id and existing.video_url = m.video_url
);

-- Backfill is_demo on any demo rows created BEFORE the is_demo column existed
-- (the inserts above skip already-present rows, so their flag would otherwise
-- stay at the column default of false and leak into real mention counts).
-- Identified by their reserved demo markers. Idempotent.
update public.creators        set is_demo = true where tiktok_handle like 'mvse_demo_%'            and is_demo = false;
update public.tiktok_videos   set is_demo = true where video_url like 'https://demo.mvse.invalid/%' and is_demo = false;
update public.tiktok_mentions set is_demo = true where video_url like 'https://demo.mvse.invalid/%' and is_demo = false;
