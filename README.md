# mvse

Two apps that share one Supabase project:

- **mvse Admin** — Electron desktop tool. Browse TikTok in the left pane;
  captured videos run through Whisper + Claude Vision + NLP and land in the
  catalog. Right pane is a React UI for confirming product/shade matches.
- **mvse** — Flutter consumer app (iOS, Android, web). Discovery, shade
  twins, search, owned-products onboarding. Lives in [`glowmatch/`](glowmatch).

## Repo layout

```
.
├── electron/                Main process, preloads, content script, network interceptor
├── services/                Node-side: Claude, Whisper, Supabase, media (yt-dlp/ffmpeg), queue
├── src/                     React renderer (Vite)
├── glowmatch/               Flutter consumer app
├── supabase/migrations/     SQL migrations
├── schema.sql               Base schema
├── seed.sql                 20 product catalog seed
├── apply_migrations.js      Run all migrations + seed via Supabase Management API
├── inspect_extractions.js   Dump latest NLP/Vision output for review
└── check_catalog.js         Print catalog state
```

## Setup

```bash
cp .env.example .env
# Fill in:
#   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
#   SUPABASE_ACCESS_TOKEN  (Personal Access Token from supabase.com/dashboard/account/tokens)
#   ANTHROPIC_API_KEY
#   OPENAI_API_KEY

brew install yt-dlp
npm install
node apply_migrations.js     # creates schema, seeds 20 products, runs all migrations
npm run dev                  # boots Electron + Vite
```

For the Flutter app see [`glowmatch/README.md`](glowmatch/README.md).

## Pipeline

1. The TikTok BrowserView keeps a persistent session, so your login survives restarts.
2. The content script and a CDP network interceptor both feed into the queue —
   one parses the DOM, the other parses TikTok's internal JSON API. Whichever
   resolves first wins; the queue dedupes by URL.
3. For each video the worker downloads the mp4, runs Whisper for the transcript,
   pulls 3 keyframes for Claude Vision, and runs Claude NLP over transcript +
   caption + top comments. Each step's result is cached on the row, so to re-run
   one step (e.g. after tweaking the NLP prompt) you NULL just that column.
4. Unknown brands/products mentioned in a video get auto-discovered by Claude
   (with web search) — verified against Sephora/Ulta and added to the catalog
   above a confidence threshold.
5. The right-pane Creator UI shows extracted (product, shade) candidates per
   creator. Confirming a candidate links it to a real `product_id` + `shade_id`,
   which is what powers shade-twin discovery in the consumer app.

## Useful commands

```bash
node apply_migrations.js         # idempotent
node inspect_extractions.js      # print recent NLP+Vision output
node check_catalog.js            # show catalog row counts and samples
```

To force a single pipeline step to re-run for everything:

```sql
update tiktok_videos set nlp_result = null, status = 'queued';   -- re-NLP only
update tiktok_videos set vision_result = null, status = 'queued'; -- re-Vision only
```

## Things to know

- **DOM selectors drift.** TikTok rotates `data-e2e` attributes — when capture
  starts missing fields, look at `electron/contentScript.js`. The CDP path in
  `electron/interceptor.js` is the more durable signal source.
- **In-memory queue.** Videos with non-terminal status are picked back up on
  startup via `queue.rehydrate()`.
- **Per-step caching.** `transcript`, `vision_result`, `nlp_result` columns
  on `tiktok_videos` cache outputs. Skip-if-not-null logic in the worker.
- **Costs.** Whisper ~$0.006/min, Claude Vision on 3 frames ~$0.02, Claude NLP
  ~$0.005, web search lookups ~$0.05/unknown product. Budget ~$0.05–0.50 per
  video depending on how many unknowns it mentions.
- **ToS.** This is a personal curation tool. Don't use it to scrape content
  you don't have authorization to use.
