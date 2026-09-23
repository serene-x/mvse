-- Beauty shopping app — Supabase schema
-- Run in the Supabase SQL Editor (or via `supabase db push`).
-- Order: extensions -> tables -> RLS -> policies -> triggers -> realtime.

create extension if not exists "pgcrypto";

-- users  (1:1 with auth.users)
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  skin_tone_desc text,
  undertone text check (undertone in ('cool','neutral','warm','olive') or undertone is null),
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- products
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text not null,
  category text not null check (category in ('foundation','blush','lip')),
  ingredient_list text,
  sephora_url text,
  ulta_url text,
  created_at timestamptz not null default now()
);
create index if not exists products_category_idx on public.products(category);
create index if not exists products_brand_idx on public.products(brand);

-- product_shades
create table if not exists public.product_shades (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  shade_name text not null,
  hex_color text check (hex_color ~ '^#[0-9A-Fa-f]{6}$'),
  unique (product_id, shade_name)
);
create index if not exists product_shades_product_idx on public.product_shades(product_id);

-- creators
create table if not exists public.creators (
  id uuid primary key default gen_random_uuid(),
  tiktok_handle text not null unique,
  shade_profile jsonb not null default '{}'::jsonb,
  skin_tone_desc text,
  created_at timestamptz not null default now()
);

-- shade_twins  (symmetric pairing of creators)
create table if not exists public.shade_twins (
  creator_a_id uuid not null references public.creators(id) on delete cascade,
  creator_b_id uuid not null references public.creators(id) on delete cascade,
  confidence_score numeric(4,3) not null check (confidence_score between 0 and 1),
  created_at timestamptz not null default now(),
  primary key (creator_a_id, creator_b_id),
  check (creator_a_id < creator_b_id)  -- canonicalize ordering, no self-pairs
);
create index if not exists shade_twins_b_idx on public.shade_twins(creator_b_id);

-- tiktok_mentions
create table if not exists public.tiktok_mentions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  video_url text not null,
  sentiment_tags jsonb not null default '{}'::jsonb,
  view_count bigint not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists tiktok_mentions_product_idx on public.tiktok_mentions(product_id);
create index if not exists tiktok_mentions_created_idx on public.tiktok_mentions(created_at desc);

-- user_owned_products  (user's vanity)
create table if not exists public.user_owned_products (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  shade_name text,
  hex_color text check (hex_color ~ '^#[0-9A-Fa-f]{6}$' or hex_color is null),
  created_at timestamptz not null default now(),
  primary key (user_id, product_id, shade_name)
);

-- user_saved_products  (wishlist)
create table if not exists public.user_saved_products (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

-- updated_at trigger for users
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end$$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.tg_set_updated_at();

-- Auto-create public.users row when an auth.users row is inserted
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Row Level Security
alter table public.users               enable row level security;
alter table public.products            enable row level security;
alter table public.product_shades      enable row level security;
alter table public.creators            enable row level security;
alter table public.shade_twins         enable row level security;
alter table public.tiktok_mentions     enable row level security;
alter table public.user_owned_products enable row level security;
alter table public.user_saved_products enable row level security;

-- ---------- users: owner-only read/update; insert handled by trigger ----------
drop policy if exists "users self select" on public.users;
create policy "users self select" on public.users
  for select to authenticated
  using (auth.uid() = id);

drop policy if exists "users self update" on public.users;
create policy "users self update" on public.users
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "users self insert" on public.users;
create policy "users self insert" on public.users
  for insert to authenticated
  with check (auth.uid() = id);

-- ---------- catalog tables: public read, no client write ----------
drop policy if exists "products readable" on public.products;
create policy "products readable" on public.products
  for select to anon, authenticated using (true);

drop policy if exists "product_shades readable" on public.product_shades;
create policy "product_shades readable" on public.product_shades
  for select to anon, authenticated using (true);

drop policy if exists "creators readable" on public.creators;
create policy "creators readable" on public.creators
  for select to anon, authenticated using (true);

drop policy if exists "shade_twins readable" on public.shade_twins;
create policy "shade_twins readable" on public.shade_twins
  for select to anon, authenticated using (true);

drop policy if exists "tiktok_mentions readable" on public.tiktok_mentions;
create policy "tiktok_mentions readable" on public.tiktok_mentions
  for select to anon, authenticated using (true);

-- Writes to catalog tables happen via service_role (bypasses RLS).

-- ---------- user_owned_products: owner-only CRUD ----------
drop policy if exists "owned select self" on public.user_owned_products;
create policy "owned select self" on public.user_owned_products
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "owned insert self" on public.user_owned_products;
create policy "owned insert self" on public.user_owned_products
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "owned update self" on public.user_owned_products;
create policy "owned update self" on public.user_owned_products
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "owned delete self" on public.user_owned_products;
create policy "owned delete self" on public.user_owned_products
  for delete to authenticated using (auth.uid() = user_id);

-- ---------- user_saved_products: owner-only CRUD ----------
drop policy if exists "saved select self" on public.user_saved_products;
create policy "saved select self" on public.user_saved_products
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "saved insert self" on public.user_saved_products;
create policy "saved insert self" on public.user_saved_products
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "saved delete self" on public.user_saved_products;
create policy "saved delete self" on public.user_saved_products
  for delete to authenticated using (auth.uid() = user_id);

-- Realtime: products + tiktok_mentions
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'products'
  ) then
    execute 'alter publication supabase_realtime add table public.products';
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tiktok_mentions'
  ) then
    execute 'alter publication supabase_realtime add table public.tiktok_mentions';
  end if;
end$$;
