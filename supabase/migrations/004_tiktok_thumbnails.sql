-- Adds thumbnail_url to tiktok_mentions, populated by the
-- supabase/functions/tiktok-oembed Edge Function.

alter table public.tiktok_mentions
  add column if not exists thumbnail_url text;

-- Partial index for the Edge Function backfill loop: cheap "give me rows
-- that still need a thumbnail" query.
create index if not exists tiktok_mentions_missing_thumbnail_idx
  on public.tiktok_mentions(id)
  where thumbnail_url is null;
