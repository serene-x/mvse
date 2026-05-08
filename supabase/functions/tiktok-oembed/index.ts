// supabase/functions/tiktok-oembed/index.ts
//
// Backfills thumbnail_url on public.tiktok_mentions by hitting TikTok's
// oEmbed endpoint for each row missing a thumbnail.
//
// Deploy:
//   supabase functions deploy tiktok-oembed --no-verify-jwt
//
// Invoke:
//   curl -X POST 'https://<project-ref>.functions.supabase.co/tiktok-oembed?limit=50' \
//        -H 'Authorization: Bearer <SERVICE_ROLE_KEY>'
//
// Schedule (recommended): wire to pg_cron or call periodically from your
// admin tool / GitHub Action. Free-tier-friendly: idempotent, batched.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OEMBED_ENDPOINT = "https://www.tiktok.com/oembed";
const USER_AGENT = "GlowMatch-EdgeFn/1.0 (+thumbnail-backfill)";

interface MentionRow {
  id: string;
  video_url: string;
}

interface Failure {
  id: string;
  error: string;
}

async function fetchThumbnail(videoUrl: string): Promise<string | null> {
  const resp = await fetch(`${OEMBED_ENDPOINT}?url=${encodeURIComponent(videoUrl)}`, {
    headers: { "User-Agent": USER_AGENT, "Accept": "application/json" },
  });
  if (!resp.ok) throw new Error(`oembed ${resp.status}`);
  const json = await resp.json() as { thumbnail_url?: string };
  return json.thumbnail_url ?? null;
}

Deno.serve(async (req) => {
  if (!["GET", "POST"].includes(req.method)) {
    return new Response("Method not allowed", { status: 405 });
  }

  const sb = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  const url = new URL(req.url);
  const limit = Math.min(Number(url.searchParams.get("limit") ?? 25), 100);

  const { data, error } = await sb
    .from("tiktok_mentions")
    .select("id, video_url")
    .is("thumbnail_url", null)
    .limit(limit);

  if (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }

  const rows = (data ?? []) as MentionRow[];
  let updated = 0;
  const failures: Failure[] = [];

  for (const row of rows) {
    try {
      const thumb = await fetchThumbnail(row.video_url);
      if (!thumb) {
        failures.push({ id: row.id, error: "no thumbnail_url in oembed response" });
        continue;
      }
      const { error: updErr } = await sb
        .from("tiktok_mentions")
        .update({ thumbnail_url: thumb })
        .eq("id", row.id);
      if (updErr) {
        failures.push({ id: row.id, error: updErr.message });
      } else {
        updated += 1;
      }
    } catch (e) {
      failures.push({ id: row.id, error: e instanceof Error ? e.message : String(e) });
    }
  }

  return Response.json({
    scanned: rows.length,
    updated,
    failed: failures.length,
    failures: failures.slice(0, 20),
  });
});
