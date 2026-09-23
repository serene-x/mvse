-- shade_name is part of user_owned_products' primary key, so it is implicitly
-- NOT NULL — which made it impossible to add a shade-less product (any
-- skincare product) to your collection. Default it to '' ; the app treats ''
-- and "no shade" as the same thing at the repository boundary.
-- The shade-twin RPCs already coalesce(shade_name, ''), so they're unaffected.

alter table public.user_owned_products
  alter column shade_name set default '';
