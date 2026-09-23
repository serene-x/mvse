require('dotenv').config({ quiet: true });
(async () => {
  const ref = new URL(process.env.SUPABASE_URL).hostname.split('.')[0];
  const url = `https://api.supabase.com/v1/projects/${ref}/config/auth`;
  const headers = {
    Authorization: 'Bearer ' + process.env.SUPABASE_ACCESS_TOKEN,
    'Content-Type': 'application/json',
  };
  const r = await fetch(url, { headers });
  if (!r.ok) throw Error('Could not read auth configuration.');
  const config = await r.json();
  const allowed = new Set(
    (config.uri_allow_list ?? '').split(',').filter(Boolean),
  );
  for (const origin of ['http://127.0.0.1:8080/', 'http://localhost:8080/'])
    allowed.add(origin);
  const patch = { uri_allow_list: [...allowed].join(',') };
  if (config.site_url === 'http://localhost:3000')
    patch.site_url = 'http://127.0.0.1:8080/';
  const update = await fetch(url, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(patch),
  });
  if (!update.ok) throw Error('Could not update local auth redirects.');
  console.log(
    'Configured local verification redirects. Existing non-local settings preserved.',
  );
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
