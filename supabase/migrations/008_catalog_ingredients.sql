-- Expand product categories and add ingredient, provenance and claim tables.

alter table public.products drop constraint if exists products_category_check;
alter table public.products add constraint products_category_check check (category in (
  -- makeup
  'foundation','concealer','blush','bronzer','highlighter','eyeshadow',
  'eyeliner','mascara','brow','lip','setting_product',
  -- skincare
  'cleanser','moisturizer','serum','sunscreen','toner','exfoliant','mask',
  'eye_cream','face_oil','treatment','mist',
  -- generic buckets (admin auto-discovery may only know this much)
  'skincare','other'
));

alter table public.products
  add column if not exists summary text,                    -- plain-language "what this is"
  add column if not exists finish text,                     -- makeup: matte/satin/natural/radiant/dewy...
  add column if not exists coverage text,                   -- makeup: sheer/light/medium/full
  add column if not exists how_it_wears text,               -- makeup: wear/oxidation notes
  add column if not exists skincare_benefits text,          -- makeup formulas with skincare claims
  add column if not exists ingredient_list_source text,     -- URL/label for where the INCI list came from
  add column if not exists ingredient_list_updated_at timestamptz,
  add column if not exists region text,                     -- market the data reflects (US/EU/KR...) — formulas differ by region
  add column if not exists data_notes text,                 -- Formula caveats: reformulations, batch variation
  add column if not exists data_source text not null default 'seed'
    check (data_source in ('seed','admin_pipeline','retailer','brand','manual'));

-- Pre-existing rows came from the curated seed catalog.
update public.products set data_source = 'seed' where data_source is null;

-- ingredients: the ingredient library
create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  inci_name text not null unique,
  common_name text,
  what_it_does text,                          -- one-line function summary
  functions jsonb not null default '[]'::jsonb,   -- e.g. ["humectant","antioxidant"]
  simple_explanation text,                    -- plain language, analogy-friendly
  science_explanation text,                   -- "go deeper" level
  evidence_level text check (evidence_level in
    ('well_established','promising','limited','contested') or evidence_level is null),
  evidence_summary text,                      -- Evidence summary
  -- classification used by the purging-vs-breakout classifier (ingredient inference)
  is_cell_turnover_active boolean not null default false,
  active_family text,                         -- 'retinoid','aha','bha','vitamin_c','peptide','humectant',...
  pairs_well jsonb not null default '[]'::jsonb,   -- [{"with": "...", "note": "..."}]
  pairs_poorly jsonb not null default '[]'::jsonb,
  -- Ingredient filter flags
  pregnancy_caution boolean not null default false,
  pregnancy_note text,
  is_fragrance boolean not null default false,
  is_essential_oil boolean not null default false,
  common_allergen boolean not null default false,
  comedogenic_rating int check (comedogenic_rating between 0 and 5),
  comedogenic_note text,                      -- must convey that these ratings are old/contested data
  sources jsonb not null default '[]'::jsonb, -- [{"title","url","publisher"}] — only verified links, never invented
  data_source text not null default 'seed'
    check (data_source in ('seed','admin_pipeline','retailer','brand','manual')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists ingredients_set_updated_at on public.ingredients;
create trigger ingredients_set_updated_at
  before update on public.ingredients
  for each row execute function public.tg_set_updated_at();

-- product_key_ingredients: the tappable buttons on a product page
create table if not exists public.product_key_ingredients (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  role_in_product text,          -- what it's meant to do in THIS product
  form_note text,                -- e.g. "as a derivative — gentler, but weaker evidence than the pure form"
  concentration_pct numeric(5,2),          -- null = brand does not disclose
  concentration_source text check (concentration_source in
    ('brand_disclosed','product_name','regulatory_label') or concentration_source is null),
  display_order int not null default 0,
  data_source text not null default 'seed'
    check (data_source in ('seed','admin_pipeline','retailer','brand','manual')),
  unique (product_id, ingredient_id)
);
create index if not exists product_key_ingredients_product_idx
  on public.product_key_ingredients(product_id);
create index if not exists product_key_ingredients_ingredient_idx
  on public.product_key_ingredients(ingredient_id);

-- claims: Contested or popular claims
-- Attached to a product, an ingredient, or both.
create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id) on delete cascade,
  claim text not null,           -- the popular belief, stated fairly
  reality text not null,         -- Assessment, counter-evidence and unknowns
  confidence text not null check (confidence in
    ('well_supported','mixed','depends_on_formula','contested','unsupported')),
  sources jsonb not null default '[]'::jsonb,
  data_source text not null default 'seed'
    check (data_source in ('seed','admin_pipeline','retailer','brand','manual')),
  created_at timestamptz not null default now(),
  check (product_id is not null or ingredient_id is not null)
);
create index if not exists claims_product_idx on public.claims(product_id);
create index if not exists claims_ingredient_idx on public.claims(ingredient_id);

-- RLS: catalog pattern — public read, writes via service_role only
alter table public.ingredients             enable row level security;
alter table public.product_key_ingredients enable row level security;
alter table public.claims                  enable row level security;

drop policy if exists "ingredients readable" on public.ingredients;
create policy "ingredients readable" on public.ingredients
  for select to anon, authenticated using (true);

drop policy if exists "product_key_ingredients readable" on public.product_key_ingredients;
create policy "product_key_ingredients readable" on public.product_key_ingredients
  for select to anon, authenticated using (true);

drop policy if exists "claims readable" on public.claims;
create policy "claims readable" on public.claims
  for select to anon, authenticated using (true);

-- product_with_mention_count: rebuild with the new columns
-- (drop + recreate because CREATE OR REPLACE can't reorder columns)
drop view if exists public.product_with_mention_count;
create view public.product_with_mention_count as
select
  p.id, p.name, p.brand, p.category, p.ingredient_list,
  p.sephora_url, p.ulta_url, p.created_at,
  p.summary, p.finish, p.coverage, p.how_it_wears, p.skincare_benefits,
  p.ingredient_list_source, p.ingredient_list_updated_at,
  p.region, p.data_notes, p.data_source,
  coalesce(m.cnt, 0) as mention_count,
  m.last_mentioned
from public.products p
left join (
  select product_id, count(*)::int as cnt, max(created_at) as last_mentioned
  from public.tiktok_mentions
  group by product_id
) m on m.product_id = p.id;

grant select on public.product_with_mention_count to anon, authenticated;
