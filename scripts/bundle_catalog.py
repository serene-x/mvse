"""Build the offline catalog from the checked-in SQL seeds. No network required."""

import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
files = [
    "seed.sql",
    "seed_ingredients.sql",
    "seed_products_v2.sql",
    "seed_products_v3.sql",
    "seed_products_v4.sql",
]
# SQL strings must remain intact when removing comments (URLs can contain --).
token = r"'(?:[^']|'')*'"
comment = re.compile(token + r"|--[^\n]*")
statements = []
columns = set()
for filename in files:
    path = ROOT / filename
    if not path.exists():
        continue
    sql = comment.sub(lambda m: "" if m[0].startswith("--") else m[0], path.read_text())
    pattern = (
        r"insert into public\.products\s*\((.*?)\)\s*values\s*((?:"
        + token
        + r"|[^;'])*?)(?:on conflict[^;]*)?;"
    )
    for match in re.finditer(pattern, sql, re.I | re.S):
        cols, values = match.groups()
        columns.update(c.strip() for c in cols.split(","))
        statements.append(f"INSERT OR IGNORE INTO products ({cols}) VALUES {values};")
conn = sqlite3.connect(":memory:")
conn.row_factory = sqlite3.Row
# Let SQLite preserve numeric values rather than coercing everything to text.
conn.execute(
    "CREATE TABLE products ("
    + ",".join(f'"{c}"' for c in sorted(columns))
    + ", UNIQUE(name,brand))"
)
for statement in statements:
    conn.execute(statement)
for match in re.finditer(
    r"update public\.products\s+set\s+(?:" + token + r"|[^;'])*;",
    (ROOT / "seed_enrichment.sql").read_text(),
    re.I,
):
    statement = match[0].replace("public.products", "products")
    conn.execute(statement)
rows = []
for row in conn.execute("SELECT * FROM products"):
    data = {k: v for k, v in dict(row).items() if v is not None}
    data["id"] = (
        "catalog-"
        + hashlib.sha256((data["brand"] + "|" + data["name"]).encode()).hexdigest()[:16]
    )
    data["mention_count"] = 0
    data["data_source"] = "seed"
    rows.append(data)
extra = ROOT / "glowmatch/assets/catalog/brand_products.json"
if extra.exists():
    merged = {(r["brand"].lower(), r["name"].lower()): r for r in rows}
    for row in json.loads(extra.read_text()):
        merged[(row["brand"].lower(), row["name"].lower())] = row
    rows = list(merged.values())
assert len({r["id"] for r in rows}) == len(rows)
output = ROOT / "glowmatch/assets/catalog/products.json"
output.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n")
print(
    f"Bundled {len(rows)} products across {len({r['category'] for r in rows})} categories."
)
