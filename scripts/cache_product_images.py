"""Cache catalog packshots locally so rendering does not depend on CORS proxies."""

import concurrent.futures
import html
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "glowmatch/assets"
manifest_path = ASSETS / "catalog/images.json"
previous = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
products = json.loads((ASSETS / "catalog/products.json").read_text())


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=18) as response:
        return response.read(), response.headers.get("Content-Type", "")


def cache(p):
    if (
        p["id"] in previous
        and (ROOT / "glowmatch" / previous[p["id"]]["asset"]).exists()
    ):
        return p["id"], previous[p["id"]]
    url = p.get("image_url")
    try:
        if not url and p.get("data_notes", "").startswith("Manufacturer: "):
            page = p["data_notes"].removeprefix("Manufacturer: ")
            raw, _ = get(page)
            content = raw.decode()
            match = re.search(
                r'<meta[^>]*property="og:image(?::url)?"[^>]*content="([^"]+)"', content
            )
            if match:
                url = html.unescape(match[1])
                if url.startswith("//"):
                    url = "https:" + url
        if not url:
            return None
        url = (
            url + ("&" if "?" in url else "?") + "width=640"
            if "cdn.shopify.com" in url
            else url
        )
        raw, kind = get(url)
        if not kind.startswith("image/"):
            return None
        suffix = {
            "image/jpeg": "jpg",
            "image/png": "png",
            "image/webp": "webp",
            "image/avif": "avif",
        }.get(kind.split(";")[0])
        if not suffix:
            return None
        name = p["id"] + "." + suffix
        (ASSETS / "products" / name).write_bytes(raw)
        return p["id"], {"asset": "assets/products/" + name, "source": url}
    except Exception:
        return None


with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    results = [r for r in pool.map(cache, products) if r]
manifest = dict(results)
(ASSETS / "catalog/images.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"Cached {len(manifest)} real product images out of {len(products)} products.")
