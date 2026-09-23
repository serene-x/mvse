require('dotenv').config({ quiet: true });
const fs = require('fs');
(async () => {
  const h = {
    apikey: process.env.SUPABASE_ANON_KEY,
    Authorization: 'Bearer ' + process.env.SUPABASE_ANON_KEY,
  };
  const r = await fetch(
    process.env.SUPABASE_URL +
      '/rest/v1/product_key_ingredients?select=*,ingredients(*),products(name,brand)',
    { headers: h },
  );
  if (!r.ok) throw Error('Ingredient read ' + r.status);
  const rows = await r.json();
  const out = {};
  for (const row of rows) {
    const p = row.products;
    if (!p) continue;
    delete row.products;
    (out[p.brand.toLowerCase() + '|' + p.name.toLowerCase()] ??= []).push(row);
  }
  fs.writeFileSync(
    'glowmatch/assets/catalog/key_ingredients.json',
    JSON.stringify(out, null, 2) + '\n',
  );
  console.log('Cached', rows.length, 'ingredient references.');
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
