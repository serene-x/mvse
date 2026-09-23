"""Import explicitly selected products from public brand storefronts.
Run with --fetch to download missing source pages; otherwise rebuild from /tmp/mvse-research.
Retains source URLs and dates. Never estimates swatch colours from product photographs.
"""

import concurrent.futures
import hashlib
import html
import json
import re
import sys
import tempfile
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

from compact_beauty_details import compact_details

ROOT = Path(__file__).resolve().parents[1]
CACHE = Path(tempfile.gettempdir()) / "mvse-research"
OUT = ROOT / "glowmatch/assets/catalog"
SITES = {
    "rare": ("Rare Beauty", "https://www.rarebeauty.com"),
    "kosas": ("Kosas", "https://kosas.com"),
    "saie": ("Saie", "https://saiehello.com"),
    "tower28": ("Tower 28", "https://www.tower28beauty.com"),
    "glossier": ("Glossier", "https://www.glossier.com"),
    "merit": ("MERIT", "https://www.meritbeauty.com"),
}
SELECT = {
    "rare": {
        "foundation": "true-to-myself-natural-matte-longwear-foundation liquid-touch-weightless-foundation-1 positive-light-tinted-moisturizer-broad-spectrum-spf-20-sunscreen",
        "concealer": "liquid-touch-brightening-concealer positive-light-under-eye-brightener-1",
        "blush": "soft-pinch-liquid-blush soft-pinch-matte-bouncy-blush soft-pinch-luminous-powder-blush stay-vulnerable-melting-blush",
        "lip": "soft-pinch-lip-oil-stick soft-pinch-tinted-lip-oil find-comfort-lip-butter kind-words-matte-lipstick stay-vulnerable-glossy-lip-balm lip-souffle-matte-lip-cream",
        "bronzer": "warm-wishes-soft-matte-powder-bronzer warm-wishes-effortless-bronzer-stick",
        "contour": "soft-pinch-liquid-contour",
        "highlighter": "positive-light-silky-touch-highlighter",
        "powder": "true-to-myself-tinted-pressed-finishing-powder",
        "brow": "brow-harmony-flexible-lifting-gel brow-harmony-precision-pencil",
        "eyeshadow": "all-of-the-above-weightless-eyeshadow-stick stay-vulnerable-liquid-eyeshadow",
    },
    "kosas": {
        "foundation": "revealer-skin-improving-foundation-spf-25",
        "concealer": "revealer-concealer revealer-extra-bright",
        "powder": "cloud-set cloud-set-loose",
        "blush": "blush-is-life impressionist-multistick",
        "lip": "wet-lip-oil-gloss wet-stick weightless-lip-color lip-pulse lipfuel",
        "brow": "brow-pop air-brow-tinted air-brow-clear brow-pop-nano",
        "bronzer": "the-sun-show",
        "mascara": "soulgazer-mascara",
        "eyeliner": "soulgazer",
        "highlighter": "shiny-objects",
    },
    "saie": {
        "foundation": "slip-tint-tinted-moisturizer glowy-super-skin-tint-foundation",
        "concealer": "slip-tint-concealer",
        "blush": "dew-blush supersuede glow-sculpt",
        "bronzer": "dew-bronze sun-melt supersuede-radiant-baked-bronzer",
        "highlighter": "glowy-super-gel-luminizer",
        "eyeshadow": "supersuede-baked-eyeshadow",
        "powder": "slip-tint-undetectable-baked-setting-powder",
        "lip": "glossybounce lip-liner-101",
        "mascara": "mascara-101",
        "setting_spray": "cityset-lightweight-setting-spray",
    },
    "glossier": {
        "foundation": "stretch-fluid-foundation perfecting-skin-tint",
        "concealer": "stretch-balm-concealer",
        "blush": "cloud-paint cloud-paint-plush-blush",
        "lip": "balm-dotcom lip-glaze ultralip lip-line generation-g lip-gloss",
        "brow": "boy-brow boy-brow-arch",
        "eyeliner": "no-1-pencil",
        "eyeshadow": "lidstar skylight",
    },
    "tower28": {
        "foundation": "swipe-foundation sunnydays-tinted-spf",
        "concealer": "swipe-serum-concealer",
        "lip": "shineon-plumping-lip-jelly shine-on-lip-gloss-jelly shineon-milky-lip-jelly lipsoftie-lip-treatment oneliner-multi-liner",
        "blush": "beachplease-luminous-tinted-balm-blush getset-blur-set-matte-powder-blush",
        "powder": "getset-blur-set-pressed-powder",
        "contour": "sculptino-soft-cream-contour",
        "bronzer": "bronzino-illuminating-bronzer",
        "eyeshadow": "gogo-shimmer-eyeshadow-stick",
        "mascara": "makewaves-mascara",
    },
    "merit": {
        "lip": "signature-lip-blush signature-lip-liner",
        "foundation": "the-uniform-spf-45",
    },
}
ALIASES = {
    "liquid-touch-weightless-foundation-1": "Liquid Touch Weightless Foundation",
    "dew-blush": "Dew Blush Liquid Blush",
    "beachplease-luminous-tinted-balm-blush": "BeachPlease Lip + Cheek Cream Blush",
    "balm-dotcom": "Balm Dotcom",
}


def clean(s):
    return (
        re.sub(r"\s+", " ", html.unescape(re.sub("<[^>]+>", " ", s or "")))
        .strip()
        .replace("™", "")
        .replace("®", "")
        .replace("—", ", ")
        .replace("–", "-")
    )


class Blocks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
        self.blocks = []
        self.skip = 0

    def handle_starttag(self, t, a):
        if t in ["script", "style"]:
            self.skip += 1
        if t in ["p", "div", "li", "section"]:
            self.stack.append([t, ""])

    def handle_data(self, d):
        if not self.skip:
            for x in self.stack:
                x[1] += d + " "

    def handle_endtag(self, t):
        if t in ["script", "style"]:
            self.skip = max(0, self.skip - 1)
        if self.stack and self.stack[-1][0] == t:
            _, s = self.stack.pop()
            s = clean(s)
            if (
                80 < len(s) < 24000
                and s.count(",") >= 9
                and re.search(
                    r"\b(aqua|water|dimethicone|isododecane|mica|octyldodecanol|hydrogenated polyisobutene)\b",
                    s,
                    re.I,
                )
            ):
                self.blocks.append(s)


def grab(url, path):
    if path.exists():
        return path.read_text()
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    s = urllib.request.urlopen(req, timeout=35).read().decode()
    path.write_text(s)
    return s


CACHE.mkdir(parents=True, exist_ok=True)
for brand_id, (_, domain) in SITES.items():
    path = CACHE / (brand_id + ".json")
    if not path.exists():
        if "--fetch" not in sys.argv:
            raise SystemExit(
                "Missing source cache. Run with --fetch to download public brand records."
            )
        grab(domain + "/products.json?limit=250", path)
base = json.loads((OUT / "products.json").read_text())
bykey = {(p["brand"].lower() + "|" + p["name"].lower()): p for p in base}
details = {}
additions = []
jobs = []
for b, cats in SELECT.items():
    products = {
        p["handle"]: p
        for p in json.loads((CACHE / (b + ".json")).read_text())["products"]
    }
    for cat, handles in cats.items():
        for h in handles.split():
            if h in products:
                jobs.append((b, cat, h, products[h]))
            else:
                print("Missing handle", b, h)


def fetchjob(j):
    b, cat, h, p = j
    path = CACHE / (b + "--" + h + ".html")
    if "--fetch" in sys.argv:
        try:
            grab(SITES[b][1] + "/products/" + h, path)
        except Exception as e:
            print("Page unavailable", b, h, type(e).__name__)
    return j


if "--fetch" in sys.argv:
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        list(pool.map(fetchjob, jobs))
for b, cat, h, p in jobs:
    cat = {
        "powder": "setting_product",
        "setting_spray": "setting_product",
        "contour": "bronzer",
    }.get(cat, cat)
    brand, domain = SITES[b]
    name = ALIASES.get(h, clean(p["title"]))
    key = brand.lower() + "|" + name.lower()
    url = domain + "/products/" + h
    old = bykey.get(key)
    pid = (
        old["id"]
        if old
        else "catalog-" + hashlib.sha256((brand + "|" + name).encode()).hexdigest()[:16]
    )
    row = dict(old or {})
    row.update(
        id=pid,
        name=name,
        brand=brand,
        category=cat,
        image_url=p["images"][0]["src"] if p["images"] else None,
        image_source="brand_site",
        data_source="brand",
        data_notes="Manufacturer: " + url,
        price_usd=float(p["variants"][0]["price"]),
        price_source="brand",
        price_as_of="2026-09-23",
        mention_count=0,
    )
    if not old:
        row["summary"] = {
            "foundation": "A complexion base. Choose a shade below to see the brand’s options.",
            "concealer": "Concealer for targeted coverage.",
            "blush": "Cheek colour. Available shades are listed below.",
            "lip": "Lip colour and care.",
            "powder": "Setting powder for your makeup.",
            "brow": "Brow colour and styling.",
            "bronzer": "Bronzer for adding warmth.",
            "contour": "Contour makeup for adding definition.",
            "highlighter": "Highlighter for the face.",
            "eyeshadow": "Colour for the eyes.",
            "eyeliner": "Liner for the eyes.",
            "mascara": "Mascara for the lashes.",
            "setting_spray": "A finishing spray for makeup.",
        }.get(cat, "")
    additions.append(row)
    bykey[key] = row
    path = CACHE / (b + "--" + h + ".html")
    s = path.read_text() if path.exists() else ""
    blocks = Blocks()
    blocks.feed(s)
    # Keep leaf ingredient lists. Never merge lists from different shade groups.
    rawlists = sorted(set(blocks.blocks), key=len)
    lists = []
    for x in rawlists:
        if not any(y in x for y in lists):
            lists.append(x)
    lists = [
        x
        for x in lists
        if not any(
            w in x.lower()
            for w in [
                "add to bag",
                "add to cart",
                "your cart",
                "what is it",
                "why we",
                "details airy",
                "free shipping",
            ]
        )
    ][:20]
    # Extract only the actual ingredient sequence; discard explanatory prose.
    vetted = []
    first_ingredient = r"(?:Water(?:/Aqua/Eau)?|Aqua(?:/Water/Eau)?|Isododecane|Dimethicone|Mica|Octyldodecanol|Hydrogenated Polyisobutene|Ricinus Communis[^,]*|Diisostearyl Malate|Caprylic/Capric Triglyceride|Squalane|Talc|Synthetic Fluorphlogopite|C12-15 Alkyl Benzoate|Coco-Caprylate/Caprate|Polyglyceryl-2 Triisostearate|C9-12 Alkane)"
    for x in lists:
        m = re.search(first_ingredient + r"\s*,", x, re.I)
        if not m:
            continue
        prefix = x[: m.start()]
        if len(prefix) > 500:
            continue
        x = x[m.start() :]
        # Reject ingredient-benefit prose; a real INCI sequence has short comma entries.
        if any(len(t) > 200 for t in x.split(",")[:8]):
            continue
        x = re.split(
            r"Please refer|Please consult|Ingredients are subject|For the most|Ingredient lists may|As we continue|Dermatologist Approved|Clinically Tested|Size:",
            x,
            flags=re.I,
        )[0].strip()
        label = re.search(r"([A-Z][A-Z /0-9.-]{2,60})(?:INGREDIENTS)?:?\s*$", prefix)
        vetted.append(((label[1].strip() + ": ") if label else "") + x)
    lists = vetted
    meta = {}
    m = re.search(r"var productMetafieldData\s*=\s*", s)
    if m:
        try:
            meta = json.JSONDecoder().raw_decode(s[m.end() :])[0]
        except ValueError:
            pass
    shades = []
    opts = [o["name"].lower() for o in p["options"]]
    shadeindex = next(
        (
            i + 1
            for i, o in enumerate(opts)
            if any(k in o for k in ["shade", "color", "colour"])
        ),
        None,
    )
    if shadeindex:
        seen = set()
        for v in p["variants"]:
            n = v.get("option" + str(shadeindex))
            vm = meta.get(str(v["id"]), {})
            if not n or n in seen:
                continue
            seen.add(n)
            desc = clean(vm.get("shade_description", ""))
            img = v.get("featured_image") or {}
            alt = img.get("alt") or ""
            # Official image alt descriptions are shade-specific, unlike arbitrary hex sampling.
            if not desc and len(alt) > len(n) + 12 and n.lower() in alt.lower():
                desc = clean(alt)
            # Structured, explicit shade descriptions published by each brand.
            rm = re.search(r"SDG.Data.variantDescriptions\s*=\s*", s)
            if b == "rare" and rm:
                try:
                    desc = clean(
                        json.JSONDecoder()
                        .raw_decode(s[rm.end() :])[0]
                        .get(n.lower(), desc)
                    )
                except ValueError:
                    pass
            if b == "saie":
                sm = re.search(
                    r"_variants\["
                    + str(v["id"])
                    + r'\]\.subtitle\s*=\s*("(?:[^"\\]|\\.)*")',
                    s,
                )
                if sm:
                    try:
                        desc = clean(json.loads(sm[1]))
                    except ValueError:
                        pass
            if b == "glossier":
                gm = re.search(
                    r'<p[^>]*class="pi__option-soi[^"]*"[^>]*>\s*'
                    + re.escape(n)
                    + r" is ([^<]+)",
                    s,
                    re.I,
                )
                if gm:
                    desc = clean(gm[1])
            # Rare's compact brand shade descriptions, from explicit named entries.
            m = re.search(r"<b>" + re.escape(n) + r"</b>\s*[–—-]\s*([^<]+)", s, re.I)
            if m:
                desc = clean(m[1])
            inci = clean(vm.get("ingredients", ""))
            shades.append(
                {
                    "id": "brand-" + str(v["id"]),
                    "name": n,
                    "description": desc,
                    "url": url + "?variant=" + str(v["id"]),
                    "image": img.get("src"),
                    "available": v["available"],
                    "ingredients": inci,
                }
            )
    # Assign explicitly labeled shade lists, never pool different shades.
    for sh in shades:
        if sh["ingredients"]:
            continue
        for raw in lists:
            label = re.escape(sh["name"].upper())
            m = re.search(
                r"(?:^|[. ]+)"
                + label
                + r"(?: INGREDIENTS\s*:?|\s*:)\s*(.*?)(?=\s+[A-Z][A-Z /0-9.-]{2,60}(?: INGREDIENTS\s*:?|\s*:)|$)",
                raw,
            )
            if m and m[1].count(",") >= 8 and len(m[1]) < 2000:
                sh["ingredients"] = m[1].strip()
                break
    # Shared INCI only when no shade-specific headings exist.
    shared = (
        lists[0]
        if len(lists) == 1
        and len(lists[0]) < 1800
        and not re.search(r"[A-Z][A-Z /0-9.-]{2,60}:", lists[0])
        else ""
    )
    details[key] = {
        "url": url,
        "checked": "2026-09-23",
        "shades": shades,
        "ingredient_lists": lists,
        "ingredients": shared,
        "source": "Brand catalogue",
    }
legacy_path = CACHE / "legacy_catalog.json"
if legacy_path.exists():
    legacy = json.loads(legacy_path.read_text())
    lookup = {
        p["id"]: p["brand"].lower() + "|" + p["name"].lower()
        for p in legacy["products"]
    }
    for sh in legacy["shades"]:
        key = lookup.get(sh["product_id"])
        if not key or key in {
            p["brand"].lower() + "|" + p["name"].lower() for p in additions
        }:
            continue
        d = details.setdefault(
            key,
            {
                "url": "",
                "checked": "",
                "source": "Legacy catalogue; verify shade on packaging",
                "shades": [],
                "ingredients": "",
                "ingredient_lists": [],
            },
        )
        d["shades"].append(
            {
                "id": sh["id"],
                "name": sh["shade_name"],
                "description": "",
                "url": "",
                "ingredients": "",
                "available": True,
            }
        )
details = compact_details(details, list(bykey.values()))
# Reviewed corrections survive subsequent source imports.
overrides_path = OUT / "details_overrides.json"
if overrides_path.exists():
    for key, patch in json.loads(overrides_path.read_text()).items():
        details[key] = {**details.get(key, {}), **patch}
        if patch.get("sephora_url") and key in bykey:
            bykey[key]["sephora_url"] = patch["sephora_url"]
(OUT / "brand_products.json").write_text(
    json.dumps(additions, ensure_ascii=False, indent=2) + "\n"
)
(OUT / "details.json").write_text(
    json.dumps(details, ensure_ascii=False, indent=2) + "\n"
)
(OUT / "products.json").write_text(
    json.dumps(list(bykey.values()), ensure_ascii=False, indent=2) + "\n"
)
print(
    "Products",
    len(bykey),
    "brand records",
    len(details),
    "shades",
    sum(len(x["shades"]) for x in details.values()),
    "with ingredients",
    sum(bool(x["ingredients"]) for x in details.values()),
)
