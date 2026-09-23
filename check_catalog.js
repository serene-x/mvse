// Show what's in the catalog tables (products + shades) — the stuff that
// would be PRESERVED by the cleanup query.
const fs = require('node:fs');
const path = require('node:path');

const env = Object.fromEntries(
  fs
    .readFileSync(path.join(__dirname, '.env'), 'utf8')
    .split('\n')
    .map((l) => l.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/))
    .filter(Boolean)
    .map((m) => [m[1], m[2].replace(/^['"]|['"]$/g, '')]),
);
const REF = (env.SUPABASE_URL.match(/https:\/\/([a-z0-9]+)\.supabase\.co/) ||
  [])[1];
const ENDPOINT = `https://api.supabase.com/v1/projects/${REF}/database/query`;

async function sql(query) {
  const r = await fetch(ENDPOINT, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.SUPABASE_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query }),
  });
  return r.json();
}

(async () => {
  const counts = await sql(`
    select 'products' as table_name, count(*)::int as n from products union all
    select 'product_shades', count(*)::int from product_shades union all
    select 'tiktok_videos', count(*)::int from tiktok_videos union all
    select 'tiktok_mentions', count(*)::int from tiktok_mentions union all
    select 'extracted_entities', count(*)::int from extracted_entities union all
    select 'creators', count(*)::int from creators
    order by table_name;
  `);
  console.log('--- current row counts ---');
  for (const r of counts) console.log(`  ${r.table_name.padEnd(22)} ${r.n}`);

  console.log('\n--- products in catalog (will be PRESERVED) ---');
  const products = await sql(
    `select brand, name, category from products order by category, brand;`,
  );
  for (const p of products)
    console.log(`  ${p.category.padEnd(11)} ${p.brand.padEnd(20)} ${p.name}`);

  console.log('\n--- shades sample (will be PRESERVED) — first 15 ---');
  const shades = await sql(`
    select p.brand, p.name as product, ps.shade_name, ps.hex_color
    from product_shades ps join products p on p.id = ps.product_id
    order by p.brand, p.name, ps.shade_name limit 15;
  `);
  for (const s of shades) {
    console.log(
      `  ${s.brand.padEnd(20)} ${s.product.padEnd(45)} ${s.shade_name.padEnd(20)} ${s.hex_color ?? ''}`,
    );
  }
})();
