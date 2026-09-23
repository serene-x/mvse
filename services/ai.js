const fs = require('node:fs');
const path = require('node:path');
const Anthropic = require('@anthropic-ai/sdk');

const MODEL = process.env.ANTHROPIC_MODEL || 'claude-sonnet-4-6';

let cached;
function client() {
  if (cached) return cached;
  if (!process.env.ANTHROPIC_API_KEY)
    throw new Error('ANTHROPIC_API_KEY missing');
  cached = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  return cached;
}

function imageBlock(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const mediaType =
    ext === '.png'
      ? 'image/png'
      : ext === '.webp'
        ? 'image/webp'
        : 'image/jpeg';
  return {
    type: 'image',
    source: {
      type: 'base64',
      media_type: mediaType,
      data: fs.readFileSync(filePath).toString('base64'),
    },
  };
}

function parseJson(text) {
  const trimmed = text
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/```\s*$/, '');
  return JSON.parse(trimmed);
}

const VISION_SYSTEM = `You are an OCR + product-recognition assistant for a beauty curation tool.
You will be shown still frames from a TikTok beauty video. Extract any visible product
or packaging information. Reply with STRICT JSON only — no prose, no markdown — matching:

{
  "products": [
    { "brand": string|null, "product_name": string|null, "shade": string|null, "confidence": number }
  ],
  "packaging_text": [string],
  "notes": string
}

Confidence is 0..1. Use null when unsure. Do not hallucinate brands.`;

async function extractFromFrames(framePaths, { videoUrl } = {}) {
  if (!framePaths?.length)
    return { products: [], packaging_text: [], notes: 'no frames' };

  const resp = await client().messages.create({
    model: MODEL,
    max_tokens: 1024,
    system: VISION_SYSTEM,
    messages: [
      {
        role: 'user',
        content: [
          ...framePaths.map(imageBlock),
          {
            type: 'text',
            text: `Source video: ${videoUrl ?? '(unknown)'}\nReturn JSON.`,
          },
        ],
      },
    ],
  });

  const text = resp.content.find((b) => b.type === 'text')?.text ?? '{}';
  try {
    return parseJson(text);
  } catch {
    return { products: [], packaging_text: [], notes: text };
  }
}

const NLP_SYSTEM = `You are an NLP extractor for a beauty curation tool. You receive
three signals from a TikTok beauty video: the spoken-word TRANSCRIPT (most authoritative
when present), the CAPTION, and the top COMMENTS. Combine them to extract structured info.
Reply with STRICT JSON only — no prose, no markdown — matching this schema:

{
  "products":   [ { "brand": string|null, "product_name": string|null } ],
  "shades":     [ { "brand": string|null, "product_name": string|null, "shade": string } ],
  "sentiment_descriptors": [string],
  "skin_tone_language":    [string],
  "audience_signals":      [string],
  "is_shade_match_video":  boolean,
  "creator_self_description": string|null,
  "notes": string
}

Field guidance:
- products / shades: only what's explicitly mentioned. Don't invent brands.
- sentiment_descriptors: short phrases on PERFORMANCE — "blends easily", "no oxidizing",
  "lasts all day", "patchy on dry skin", "subtle flush". Lift phrases from transcript first,
  then comments.
- skin_tone_language: ANY skin-tone or undertone phrases in any source. e.g. "NC30",
  "medium-tan warm", "olive deep", "fair pink-toned".
- audience_signals: phrases the creator uses to target a specific viewer.
  Examples: "if you're my shade twin", "for my deep-skin girlies",
  "if you're medium-tan with warm undertones this is for you".
- is_shade_match_video: true ONLY if the video is explicitly framed as a shade-match /
  shade-twin recommendation. Otherwise false.
- creator_self_description: short phrase describing the creator's own skin if they state it
  ("I'm NC25 warm", "deep-tan olive"), else null.
- notes: anything important that didn't fit above. Keep short.

Empty arrays / null when nothing applies. Never invent.`;

async function extractFromTextSignals({
  caption,
  comments = [],
  transcript = null,
}) {
  const commentBlock = comments
    .slice(0, 50)
    .map(
      (c, i) =>
        `${i + 1}. (@${c.author ?? 'anon'}, ${c.like_count ?? 0} likes) ${c.text ?? ''}`,
    )
    .join('\n');

  const userMsg = [
    `TRANSCRIPT:\n${transcript?.trim() || '(none)'}`,
    `CAPTION:\n${caption || '(none)'}`,
    `TOP COMMENTS:\n${commentBlock || '(none)'}`,
  ].join('\n\n');

  const resp = await client().messages.create({
    model: MODEL,
    max_tokens: 1500,
    system: NLP_SYSTEM,
    messages: [{ role: 'user', content: [{ type: 'text', text: userMsg }] }],
  });

  const text = resp.content.find((b) => b.type === 'text')?.text ?? '{}';
  try {
    return parseJson(text);
  } catch {
    return {
      products: [],
      shades: [],
      sentiment_descriptors: [],
      skin_tone_language: [],
      audience_signals: [],
      is_shade_match_video: false,
      creator_self_description: null,
      notes: text,
    };
  }
}

const FIND_PRODUCT_SYSTEM = `You are a beauty product researcher. Given a brand and product
name guessed from a TikTok video, find the canonical product on sephora.com or ulta.com
using web search. Verify each URL actually points to the product page, not a search results page.

Reply with STRICT JSON only — no prose, no markdown — matching:

{
  "found":       boolean,
  "brand":       string,
  "name":        string,
  "category":    "foundation" | "blush" | "lip" | "skincare" | "other",
  "sephora_url": string|null,
  "ulta_url":    string|null,
  "confidence":  number,
  "notes":       string
}

Rules:
- confidence: 1.0 = exact match verified on retailer page; 0.7+ = high
  confidence; 0.5-0.7 = plausible; <0.5 = guess.
- Do not invent URLs. Only include URLs that resolve to a product page.
- category: pick the closest among the listed values.
- If you cannot find a confident match, set found=false and confidence=0.`;

async function findProductOnline(brand, productName) {
  const resp = await client().messages.create({
    model: MODEL,
    max_tokens: 1024,
    system: FIND_PRODUCT_SYSTEM,
    tools: [{ type: 'web_search_20250305', name: 'web_search', max_uses: 3 }],
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: `Brand: ${brand}\nProduct: ${productName}\n\nFind this on sephora.com or ulta.com.`,
          },
        ],
      },
    ],
  });

  const textBlocks = resp.content.filter((b) => b.type === 'text');
  const finalText = textBlocks.at(-1)?.text ?? '{}';

  try {
    return parseJson(finalText);
  } catch {
    return { found: false, confidence: 0, notes: finalText.slice(0, 500) };
  }
}

module.exports = {
  MODEL,
  extractFromFrames,
  extractFromTextSignals,
  findProductOnline,
};
