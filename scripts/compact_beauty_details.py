"""Keep shade names under their product; formula and buying link belong to the product."""

import re


def compact_details(details, products):
    skincare = {
        "cleanser",
        "moisturizer",
        "serum",
        "sunscreen",
        "toner",
        "exfoliant",
        "mask",
        "eye_cream",
        "face_oil",
        "treatment",
        "mist",
        "skincare",
    }
    categories = {
        p["brand"].lower() + "|" + p["name"].lower(): p["category"] for p in products
    }
    for key, detail in details.items():
        variants = detail.get("shades", [])
        descriptions = {
            s["name"]: s["description"] for s in variants if s.get("description")
        }
        # Keep one published ingredient list at product level. Strip headings and
        # subsequent shade lists from the brand page, not individual ingredients.
        candidates = (
            [detail.get("ingredients", "")]
            + [s.get("ingredients", "") for s in variants]
            + detail.get("ingredient_lists", [])
        )
        formula = ""
        for candidate in candidates:
            candidate = re.sub(r"^[A-Z][A-Z /0-9.-]*:\s*", "", candidate)
            candidate = re.split(r"\s+[A-Z][A-Z /0-9.-]{2,60}:", candidate)[0].strip()
            candidate = re.split(
                r"\.\s+(?=[A-Z][A-Z +,/0-9-]{2,}(?:\s+[A-Z][a-z]|$))", candidate
            )[0].strip()
            candidate = re.split(
                r"\.\s+(?!(?:May Contain|Peut Contenir|Active Ingredient))[^.:]{1,70}:",
                candidate,
                flags=re.I,
            )[0].strip()
            if candidate.count(",") >= 8 and len(candidate) < 4000:
                formula = candidate
                break
        detail["ingredients"] = formula
        detail["shades"] = (
            list(dict.fromkeys(s["name"] for s in variants))
            if categories.get(key) not in skincare
            else []
        )
        # Only the short colour references used for recommendations. No variant
        # IDs, URLs, photos, stock status, or repeated formulas are stored.
        detail["shade_descriptions"] = descriptions if detail["shades"] else {}
        detail.pop("ingredient_lists", None)
    return details
