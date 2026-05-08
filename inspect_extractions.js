// Quick quality probe. Prints last 5 ready videos and what was extracted.
const fs = require('node:fs');
const path = require('node:path');

const env = Object.fromEntries(
  fs.readFileSync(path.join(__dirname, '.env'), 'utf8')
    .split('\n')
    .map(l => l.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/))
    .filter(Boolean)
    .map(m => [m[1], m[2].replace(/^['"]|['"]$/g, '')])
);

const REF = (env.SUPABASE_URL.match(/https:\/\/([a-z0-9]+)\.supabase\.co/) || [])[1];
const ENDPOINT = `https://api.supabase.com/v1/projects/${REF}/database/query`;

async function sql(query) {
  const r = await fetch(ENDPOINT, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.SUPABASE_ACCESS_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ query }),
  });
  if (!r.ok) { console.error(await r.text()); process.exit(1); }
  return r.json();
}

(async () => {
  // Status counts
  const counts = await sql(`select status, count(*)::int as n from tiktok_videos group by status order by n desc;`);
  console.log('--- video status ---');
  for (const r of counts) console.log(`  ${r.status.padEnd(14)} ${r.n}`);

  // Last 5 ready videos with their NLP output
  console.log('\n--- last 5 ready videos ---');
  const videos = await sql(`
    select id, video_url, creator_handle,
           left(coalesce(transcript,''), 240) as transcript_head,
           length(coalesce(transcript,'')) as transcript_len,
           nlp_result
    from tiktok_videos
    where status='ready'
    order by processed_at desc nulls last
    limit 5;
  `);
  for (const v of videos) {
    console.log(`\n@${v.creator_handle}  ${v.video_url}`);
    console.log(`  transcript (${v.transcript_len} chars): ${v.transcript_head?.replace(/\n/g,' ')}`);
    const r = v.nlp_result || {};
    console.log(`  products:        ${JSON.stringify(r.products ?? [])}`);
    console.log(`  shades:          ${JSON.stringify(r.shades ?? [])}`);
    console.log(`  sentiment:       ${JSON.stringify(r.sentiment_descriptors ?? [])}`);
    console.log(`  skin_tone_lang:  ${JSON.stringify(r.skin_tone_language ?? [])}`);
    if (r.audience_signals)        console.log(`  audience:        ${JSON.stringify(r.audience_signals)}`);
    if (r.is_shade_match_video)    console.log(`  ★ shade match video: yes`);
    if (r.creator_self_description) console.log(`  creator says:    ${r.creator_self_description}`);
  }

  // Sample extracted_entities
  console.log('\n--- extracted_entities sample (last 12) ---');
  const ents = await sql(`
    select source, brand_guess, product_guess, shade_guess,
           left(coalesce(raw_text, ''), 120) as raw_head
    from extracted_entities
    order by created_at desc
    limit 12;
  `);
  for (const e of ents) {
    const tag = e.source.padEnd(12);
    const brand = (e.brand_guess ?? '—').padEnd(20);
    const prod  = (e.product_guess ?? '—').padEnd(40);
    const shade = (e.shade_guess ?? '—').padEnd(15);
    console.log(`  ${tag} ${brand} ${prod} ${shade} ${e.raw_head?.replace(/\n/g,' ') ?? ''}`);
  }
})();
