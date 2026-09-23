// Apply the base schema, migrations and catalogue seeds.

const fs = require('node:fs');
const path = require('node:path');

const [major] = process.versions.node.split('.').map(Number);
if (major < 18) {
  console.error(`Need Node 18+ (current: ${process.versions.node})`);
  process.exit(1);
}

const ROOT = __dirname;
require('dotenv').config({ path: path.join(ROOT, '.env') });
const env = process.env;
const URL_RE = /^https:\/\/([a-z0-9]+)\.supabase\.co/;
const projectRef = (env.SUPABASE_URL?.match(URL_RE) ?? [])[1];
const pat = env.SUPABASE_ACCESS_TOKEN;

if (!projectRef) {
  console.error('Could not parse project ref from SUPABASE_URL');
  process.exit(1);
}
if (!pat) {
  console.error('SUPABASE_ACCESS_TOKEN missing');
  process.exit(1);
}

const ENDPOINT = `https://api.supabase.com/v1/projects/${projectRef}/database/query`;

async function runSql(sql, label) {
  process.stdout.write(`==> ${label.padEnd(36)} `);
  const res = await fetch(ENDPOINT, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${pat}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query: sql }),
  });
  const text = await res.text();
  if (!res.ok) {
    console.log('FAILED');
    console.error(`    ${res.status} ${res.statusText}`);
    console.error('    ' + text.slice(0, 2000).replace(/\n/g, '\n    '));
    throw new Error(`SQL failed for ${label}`);
  }
  console.log('OK');
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

(async () => {
  console.log(`project: ${projectRef}\n`);

  // 1. Base schema
  await runSql(
    fs.readFileSync(path.join(ROOT, 'schema.sql'), 'utf8'),
    'schema.sql',
  );

  // 2. Seed only if empty
  const countResult = await runSql(
    'select count(*)::int as n from public.products;',
    'check products count',
  );
  const n = countResult?.[0]?.n ?? 0;
  if (n > 0) {
    console.log(`    (products has ${n} rows, skipping seed.sql)`);
  } else {
    await runSql(
      fs.readFileSync(path.join(ROOT, 'seed.sql'), 'utf8'),
      'seed.sql',
    );
  }

  // 3. Migrations in order
  const migrations = [
    '002_admin_tool.sql',
    '003_glowmatch_views.sql',
    '004_tiktok_thumbnails.sql',
    '005_per_step_results.sql',
    '006_shade_twins_from_videos.sql',
    '007_products_unique_brand_name.sql',
    '008_catalog_ingredients.sql',
    '009_ingredient_sources.sql',
    '010_profile_and_feedback.sql',
    '011_ingredient_flags.sql',
    '012_shade_observations.sql',
    '013_pao_and_price.sql',
    '014_owned_products_shade_default.sql',
    '015_product_images.sql',
    '016_pricing_size_demo.sql',
    '017_personal_beauty_data.sql',
    '018_reviewed_shade_reports.sql',
  ];
  for (const f of migrations) {
    const sql = fs.readFileSync(
      path.join(ROOT, 'supabase', 'migrations', f),
      'utf8',
    );
    await runSql(sql, f);
  }

  // 3b. Ingredient/skincare seed (idempotent — ON CONFLICT DO NOTHING inside)
  await runSql(
    fs.readFileSync(path.join(ROOT, 'seed_ingredients.sql'), 'utf8'),
    'seed_ingredients.sql',
  );

  // Catalogue seeds run after the schema migrations they depend on.
  for (const f of [
    'seed_products_v2.sql',
    'seed_products_v3.sql',
    'seed_products_v4.sql',
    'seed_enrichment.sql',
  ]) {
    const p = path.join(ROOT, f);
    if (fs.existsSync(p)) await runSql(fs.readFileSync(p, 'utf8'), f);
    else console.log(`    (${f} not present, skipping)`);
  }

  if (process.argv.includes('--demo')) {
    await runSql(
      fs.readFileSync(path.join(ROOT, 'seed_demo_twins.sql'), 'utf8'),
      'seed_demo_twins.sql',
    );
  }

  // 3d. Re-run the PAO default backfill AFTER seeding. Migration 016 backfills
  // during the migration phase — i.e. before the seed products exist — so any
  // seed product without an inline default_pao_months would otherwise stay
  // NULL on a fresh database. Idempotent: only fills NULLs.
  await runSql(
    `update public.products set default_pao_months = case category
       when 'sunscreen' then 12 when 'serum' then 6  when 'treatment' then 6
       when 'exfoliant' then 12 when 'moisturizer' then 12 when 'cleanser' then 12
       when 'toner' then 12 when 'mask' then 12 when 'eye_cream' then 6
       when 'face_oil' then 12 when 'foundation' then 12 when 'concealer' then 12
       when 'blush' then 24 when 'lip' then 18 else 12 end
     where default_pao_months is null;`,
    'backfill default_pao_months',
  );

  // 4. Sanity checks
  console.log('\n--- sanity ---');
  const tables = await runSql(
    `select tablename from pg_tables where schemaname='public' order by tablename;`,
    'list public tables',
  );
  console.log('   tables:', tables.map((r) => r.tablename).join(', '));

  const seeds = await runSql(
    `select count(*)::int as n from public.products;`,
    'product count',
  );
  console.log('   products:', seeds[0].n);

  const shades = await runSql(
    `select count(*)::int as n from public.product_shades;`,
    'shade count',
  );
  console.log('   shades:', shades[0].n);

  console.log('\n✓ database ready.');
})().catch((err) => {
  console.error('\n✗ Failed:', err.message);
  process.exit(1);
});
