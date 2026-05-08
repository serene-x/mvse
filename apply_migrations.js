// One-shot: applies schema, seed, and all migrations to the linked Supabase
// project via the Management API. Idempotent for schema/migrations (CREATE
// IF NOT EXISTS / CREATE OR REPLACE). Skips seed.sql if products already
// has rows.
//
// Run: node apply_migrations.js

const fs = require('node:fs');
const path = require('node:path');

const [major] = process.versions.node.split('.').map(Number);
if (major < 18) {
  console.error(`Need Node 18+ (current: ${process.versions.node})`);
  process.exit(1);
}

const ROOT = __dirname;
const ENV_FILE = path.join(ROOT, '.env');

function loadEnv() {
  const out = {};
  for (const line of fs.readFileSync(ENV_FILE, 'utf8').split('\n')) {
    const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
    if (m) out[m[1]] = m[2].replace(/^['"]|['"]$/g, '');
  }
  return out;
}

const env = loadEnv();
const URL_RE = /^https:\/\/([a-z0-9]+)\.supabase\.co/;
const projectRef = (env.SUPABASE_URL?.match(URL_RE) ?? [])[1];
const pat = env.SUPABASE_ACCESS_TOKEN;

if (!projectRef) { console.error('Could not parse project ref from SUPABASE_URL'); process.exit(1); }
if (!pat)        { console.error('SUPABASE_ACCESS_TOKEN missing'); process.exit(1); }

const ENDPOINT = `https://api.supabase.com/v1/projects/${projectRef}/database/query`;

async function runSql(sql, label) {
  process.stdout.write(`==> ${label.padEnd(36)} `);
  const res = await fetch(ENDPOINT, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${pat}`,
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
  try { return JSON.parse(text); } catch { return text; }
}

(async () => {
  console.log(`project: ${projectRef}\n`);

  // 1. Base schema
  await runSql(fs.readFileSync(path.join(ROOT, 'schema.sql'), 'utf8'), 'schema.sql');

  // 2. Seed only if empty
  const countResult = await runSql(
    'select count(*)::int as n from public.products;',
    'check products count'
  );
  const n = countResult?.[0]?.n ?? 0;
  if (n > 0) {
    console.log(`    (products has ${n} rows, skipping seed.sql)`);
  } else {
    await runSql(fs.readFileSync(path.join(ROOT, 'seed.sql'), 'utf8'), 'seed.sql');
  }

  // 3. Migrations in order
  const migrations = [
    '002_admin_tool.sql',
    '003_glowmatch_views.sql',
    '004_tiktok_thumbnails.sql',
    '005_per_step_results.sql',
    '006_shade_twins_from_videos.sql',
    '007_products_unique_brand_name.sql',
  ];
  for (const f of migrations) {
    const sql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', f), 'utf8');
    await runSql(sql, f);
  }

  // 4. Sanity checks
  console.log('\n--- sanity ---');
  const tables = await runSql(
    `select tablename from pg_tables where schemaname='public' order by tablename;`,
    'list public tables'
  );
  console.log('   tables:', tables.map(r => r.tablename).join(', '));

  const seeds = await runSql(
    `select count(*)::int as n from public.products;`,
    'product count'
  );
  console.log('   products:', seeds[0].n);

  const shades = await runSql(
    `select count(*)::int as n from public.product_shades;`,
    'shade count'
  );
  console.log('   shades:', shades[0].n);

  console.log('\n✓ database ready.');
})().catch(err => {
  console.error('\n✗ Failed:', err.message);
  process.exit(1);
});
