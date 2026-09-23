// Apply only the explicitly named migration, without reseeding the catalogue.
require('dotenv').config({ quiet: true });
const fs = require('node:fs'),
  path = require('node:path');
(async () => {
  const name = process.argv[2];
  if (!/^\d{3}_[a-z_]+\.sql$/.test(name ?? ''))
    throw Error('Pass a migration filename.');
  const ref = new URL(process.env.SUPABASE_URL).hostname.split('.')[0];
  const sql = fs.readFileSync(
    path.join(__dirname, '../supabase/migrations', name),
    'utf8',
  );
  const r = await fetch(
    `https://api.supabase.com/v1/projects/${ref}/database/query`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.SUPABASE_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query: sql }),
    },
  );
  if (!r.ok) throw Error(`Migration failed (${r.status}).`);
  console.log(`Applied ${name}`);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
