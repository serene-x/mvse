-- Beauty admin tool — additions on top of schema.sql
-- Run after schema.sql.

create extension if not exists "pgcrypto";

-- tiktok_videos: canonical record per captured TikTok video
create table if not exists public.tiktok_videos (
  id uuid primary key default gen_random_uuid(),
  video_url text not null unique,
  creator_id uuid references public.creators(id),
  creator_handle text,
  caption text,
  posted_at timestamptz,
  view_count bigint,
  top_comments jsonb not null default '[]'::jsonb,    -- array of {text, author, like_count}
  transcript text,
  frames jsonb not null default '[]'::jsonb,          -- array of {path, vision_text}
  nlp_result jsonb,                                    -- output of caption+comments NLP
  status text not null default 'queued'
    check (status in ('queued','downloading','transcribing','vision','nlp','ready','failed')),
  error text,
  captured_at timestamptz not null default now(),
  processed_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists tiktok_videos_status_idx on public.tiktok_videos(status);
create index if not exists tiktok_videos_creator_idx on public.tiktok_videos(creator_id);

drop trigger if exists tiktok_videos_set_updated_at on public.tiktok_videos;
create trigger tiktok_videos_set_updated_at
  before update on public.tiktok_videos
  for each row execute function public.tg_set_updated_at();

-- tiktok_mentions: link videos -> products (with confirmation flag)
alter table public.tiktok_mentions
  add column if not exists video_id uuid references public.tiktok_videos(id) on delete cascade,
  add column if not exists confirmed boolean not null default false;
create index if not exists tiktok_mentions_video_idx on public.tiktok_mentions(video_id);

-- shade_twins: confirmation flag for human-reviewed pairs
alter table public.shade_twins
  add column if not exists confirmed boolean not null default false;

-- extracted_entities: raw NLP/Vision/Whisper hits before product linking
create table if not exists public.extracted_entities (
  id uuid primary key default gen_random_uuid(),
  video_id uuid not null references public.tiktok_videos(id) on delete cascade,
  source text not null check (source in ('whisper','vision','caption_nlp')),
  raw_text text,
  brand_guess text,
  product_guess text,
  shade_guess text,
  sentiment_tags jsonb not null default '[]'::jsonb,
  skin_tone_language text,
  product_id uuid references public.products(id),
  shade_id uuid references public.product_shades(id),
  reviewed boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists extracted_entities_video_idx on public.extracted_entities(video_id);
create index if not exists extracted_entities_unreviewed_idx
  on public.extracted_entities(reviewed) where reviewed = false;

-- RLS: admin tool writes via service_role (bypasses RLS); public can read
alter table public.tiktok_videos      enable row level security;
alter table public.extracted_entities enable row level security;

drop policy if exists "tiktok_videos readable" on public.tiktok_videos;
create policy "tiktok_videos readable" on public.tiktok_videos
  for select to anon, authenticated using (true);

drop policy if exists "extracted_entities readable" on public.extracted_entities;
create policy "extracted_entities readable" on public.extracted_entities
  for select to anon, authenticated using (true);

-- Realtime
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='tiktok_videos'
  ) then
    execute 'alter publication supabase_realtime add table public.tiktok_videos';
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='extracted_entities'
  ) then
    execute 'alter publication supabase_realtime add table public.extracted_entities';
  end if;
end$$;
