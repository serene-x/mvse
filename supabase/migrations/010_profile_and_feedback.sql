-- Profile fields and per-product feedback, with stated/inferred provenance.

alter table public.users
  add column if not exists skin_type jsonb not null default '[]'::jsonb,        -- e.g. ["combination","sensitive"]
  add column if not exists skin_type_source text
    check (skin_type_source in ('stated','inferred') or skin_type_source is null),
  add column if not exists concerns jsonb not null default '[]'::jsonb,          -- e.g. ["acne","redness"]
  add column if not exists concerns_source text
    check (concerns_source in ('stated','inferred') or concerns_source is null),
  add column if not exists goals jsonb not null default '[]'::jsonb,
  add column if not exists sensitivities jsonb not null default '[]'::jsonb,     -- [{"label","ingredient_id"?,"source"}]
  add column if not exists inference_notes jsonb not null default '[]'::jsonb;   -- [{"field","value","reason","confidence"}] for transparency

-- user_product_feedback: one row per user–product interaction.
-- Kept separate from user_owned_products (ownership) so a user can log
-- feedback on products they've tried but no longer own, and vice versa.
create table if not exists public.user_product_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,

  -- overall
  liked text check (liked in ('yes','no','meh') or liked is null),
  still_using boolean,
  tried boolean not null default true,

  -- attribute ratings (skincare + makeup). Sparse: only what the user tapped.
  -- keys like {"texture":1,"absorption":-1,"scent":0,"hydration":1,
  --            "stinging":-1,"results":1,"color":1,"finish":-1,"coverage":1,
  --            "longevity":1,"oxidation":-1}  where 1=like, 0=meh, -1=dislike
  attribute_ratings jsonb not null default '{}'::jsonb,

  -- reaction capture
  reaction text check (reaction in ('none','breakout','irritation','dryness','other') or reaction is null),
  -- breakout detail (only when reaction='breakout')
  breakout_onset_days int,                 -- days after starting that it began
  breakout_location text                   -- usual zones vs new/unusual areas
    check (breakout_location in ('usual','new','both') or breakout_location is null),
  breakout_type text                       -- small uniform vs cystic/painful
    check (breakout_type in ('small_uniform','cystic_painful','mixed') or breakout_type is null),
  breakout_duration text                   -- how it's trending
    check (breakout_duration in ('improving','persistent','worsening','resolved') or breakout_duration is null),
  irritation_kind jsonb not null default '[]'::jsonb,   -- ["stinging","redness","itch","burning"]

  -- Other products started at the same time
  other_new_products boolean not null default false,    -- started other new products around the same time
  context_flags jsonb not null default '[]'::jsonb,     -- ["cycle","stress","seasonal","new_environment"]

  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id)
);
create index if not exists user_product_feedback_user_idx
  on public.user_product_feedback(user_id);
create index if not exists user_product_feedback_reaction_idx
  on public.user_product_feedback(user_id, reaction) where reaction is not null;

drop trigger if exists user_product_feedback_set_updated_at on public.user_product_feedback;
create trigger user_product_feedback_set_updated_at
  before update on public.user_product_feedback
  for each row execute function public.tg_set_updated_at();

-- RLS: owner-only CRUD, like the other per-user tables
alter table public.user_product_feedback enable row level security;

drop policy if exists "feedback select self" on public.user_product_feedback;
create policy "feedback select self" on public.user_product_feedback
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "feedback insert self" on public.user_product_feedback;
create policy "feedback insert self" on public.user_product_feedback
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "feedback update self" on public.user_product_feedback;
create policy "feedback update self" on public.user_product_feedback
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "feedback delete self" on public.user_product_feedback;
create policy "feedback delete self" on public.user_product_feedback
  for delete to authenticated using (auth.uid() = user_id);
