// Synchronize public catalog data only. Never includes credentials in output.
require('dotenv').config({ quiet: true });
const fs = require('fs');
const path = require('node:path');
const { tmpdir } = require('node:os');
const base = process.env.SUPABASE_URL;
const headers = {
  apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  Authorization: 'Bearer ' + process.env.SUPABASE_SERVICE_ROLE_KEY,
  'Content-Type': 'application/json',
};
async function api(path, body) {
  const r = await fetch(base + '/rest/v1/' + path, {
    method: body ? 'POST' : 'GET',
    headers: {
      ...headers,
      ...(body
        ? { Prefer: 'resolution=merge-duplicates,return=representation' }
        : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!r.ok)
    throw new Error(
      'Catalog request failed ' + r.status + ' ' + (await r.json()).message,
    );
  return r.json();
}
(async () => {
  const oldProducts = await api('products?select=id,name,brand');
  const oldShades = await api(
    'product_shades?select=id,product_id,shade_name,hex_color',
  );
  const cache = path.join(tmpdir(), 'mvse-research');
  fs.mkdirSync(cache, { recursive: true });
  fs.writeFileSync(
    path.join(cache, 'legacy_catalog.json'),
    JSON.stringify({ products: oldProducts, shades: oldShades }),
  );
  if (!process.argv.includes('--write')) {
    console.log(
      'Read',
      oldProducts.length,
      'products and',
      oldShades.length,
      'shades',
    );
    return;
  }
  const rows = JSON.parse(
    fs.readFileSync('glowmatch/assets/catalog/brand_products.json'),
  );
  const details = JSON.parse(
    fs.readFileSync('glowmatch/assets/catalog/details.json'),
  );
  // Only catalogue fields are included in the upsert.
  const allowed = [
    'name',
    'brand',
    'category',
    'image_url',
    'image_source',
    'data_notes',
    'price_usd',
    'price_source',
    'price_as_of',
    'summary',
    'data_source',
  ];
  const payload = rows.map((p) =>
    Object.fromEntries(
      allowed.map((k) => [k, k === 'price_source' ? 'brand' : (p[k] ?? null)]),
    ),
  );
  const products = await api('products?on_conflict=name,brand', payload);
  const shades = [];
  for (const p of products) {
    const d = details[p.brand.toLowerCase() + '|' + p.name.toLowerCase()];
    for (const s of d?.shades ?? [])
      shades.push({ product_id: p.id, shade_name: s });
  }
  for (let i = 0; i < shades.length; i += 200)
    await api(
      'product_shades?on_conflict=product_id,shade_name',
      shades.slice(i, i + 200),
    );
  console.log(
    'Synced',
    products.length,
    'brand product records and',
    shades.length,
    'named shades.',
  );
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
