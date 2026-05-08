-- Unique (brand, name) on products so the auto-discovery worker can upsert
-- without accidentally creating duplicates of catalog entries. Existing seed
-- data already satisfies this; if a future row collides, the upsert will
-- merge instead of erroring.

alter table public.products
  drop constraint if exists products_brand_name_uniq;

alter table public.products
  add constraint products_brand_name_uniq unique (brand, name);
