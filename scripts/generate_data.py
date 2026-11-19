"""
Synthetic data generator for a fictional online store.

Creates four CSV files in data/raw/ (customers, products, orders, order_items)
with a fixed seed, so the output is reproducible. All names, emails and
amounts are invented. Only the Python standard library is used.

Usage:
    python scripts/generate_data.py                 # default sizes
    python scripts/generate_data.py --orders 20000  # bigger dataset

The data deliberately includes a few real-world quirks that the Dataform
staging layer has to clean: duplicated customer rows (updates), extra
whitespace and mixed case in text fields, and cancelled orders.
"""
from __future__ import annotations

import argparse
import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "raw"

FIRST_NAMES = ["Lucia", "Hugo", "Martina", "Mateo", "Sofia", "Leo", "Valeria", "Daniel",
               "Paula", "Pablo", "Julia", "Alvaro", "Carmen", "Diego", "Elena", "Mario",
               "Irene", "Javier", "Sara", "Adrian", "Noa", "Bruno", "Alba", "Marcos"]
LAST_NAMES = ["Garcia", "Rodriguez", "Gonzalez", "Fernandez", "Lopez", "Martinez",
              "Sanchez", "Perez", "Gomez", "Martin", "Jimenez", "Ruiz", "Hernandez",
              "Diaz", "Moreno", "Alvarez", "Romero", "Navarro", "Torres", "Dominguez"]
REGIONS = {
    "Madrid": ["Madrid", "Alcala de Henares", "Getafe"],
    "Cataluna": ["Barcelona", "Girona", "Tarragona"],
    "Andalucia": ["Sevilla", "Malaga", "Granada"],
    "Comunidad Valenciana": ["Valencia", "Alicante", "Castellon"],
    "Castilla-La Mancha": ["Toledo", "Albacete", "Ciudad Real"],
    "Galicia": ["A Coruna", "Vigo", "Santiago"],
}
CATEGORIES = {
    "Electronics": (["Headphones", "Keyboard", "Mouse", "Monitor", "Webcam", "Speaker"], (15, 400)),
    "Home": (["Lamp", "Chair", "Desk", "Shelf", "Rug", "Mirror"], (10, 250)),
    "Sports": (["Yoga mat", "Dumbbells", "Bike light", "Water bottle", "Backpack"], (8, 120)),
    "Books": (["Data engineering", "SQL cookbook", "Cloud patterns", "Python guide"], (12, 60)),
    "Kitchen": (["Coffee maker", "Kettle", "Knife set", "Blender", "Pan"], (15, 180)),
}
CHANNELS = ["web", "app", "marketplace"]
PAYMENT_METHODS = ["card", "paypal", "bizum", "transfer"]
STATUSES = ["delivered"] * 85 + ["shipped"] * 7 + ["cancelled"] * 5 + ["returned"] * 3


def _messy(text: str, rng: random.Random) -> str:
    """Introduce the kind of formatting noise found in real source systems."""
    roll = rng.random()
    if roll < 0.05:
        return f"  {text.upper()} "
    if roll < 0.10:
        return text.lower()
    return text


def generate(n_customers: int, n_orders: int, start: date, end: date, seed: int) -> dict[str, int]:
    rng = random.Random(seed)
    OUT.mkdir(parents=True, exist_ok=True)
    span_days = (end - start).days

    # --- customers (with ~3% duplicated rows representing later updates)
    customers = []
    for cid in range(1, n_customers + 1):
        region = rng.choice(list(REGIONS))
        first, last = rng.choice(FIRST_NAMES), rng.choice(LAST_NAMES)
        signup = start - timedelta(days=rng.randint(0, 720))
        customers.append({
            "customer_id": cid,
            "first_name": _messy(first, rng),
            "last_name": _messy(last, rng),
            "email": f"{first}.{last}{cid}@example.com".lower(),
            "city": rng.choice(REGIONS[region]),
            "region": region,
            "country": "ES",
            "signup_date": signup.isoformat(),
            "updated_at": datetime.combine(signup, datetime.min.time()).isoformat(),
        })
    for c in rng.sample(customers, k=max(1, n_customers * 3 // 100)):
        moved = dict(c)
        moved["region"] = rng.choice(list(REGIONS))
        moved["city"] = rng.choice(REGIONS[moved["region"]])
        moved["updated_at"] = (datetime.fromisoformat(c["updated_at"])
                               + timedelta(days=rng.randint(30, 400))).isoformat()
        customers.append(moved)
    rng.shuffle(customers)

    # --- products
    products = []
    pid = 1
    for category, (items, (lo, hi)) in CATEGORIES.items():
        for item in items:
            for tier in ("Basic", "Pro"):
                price = round(rng.uniform(lo, hi) * (1.6 if tier == "Pro" else 1.0), 2)
                products.append({
                    "product_id": pid,
                    "product_name": f"{item} {tier}",
                    "category": category,
                    "unit_price": f"{price:.2f}",
                    "unit_cost": f"{price * rng.uniform(0.45, 0.7):.2f}",
                    "is_active": "true" if rng.random() > 0.05 else "false",
                })
                pid += 1

    # --- orders and order items (more orders towards the end: the store grows)
    orders, items = [], []
    item_id = 1
    for oid in range(1, n_orders + 1):
        offset = int(span_days * (rng.random() ** 0.8))
        order_ts = datetime.combine(start + timedelta(days=offset), datetime.min.time()) \
            + timedelta(minutes=rng.randint(0, 1439))
        orders.append({
            "order_id": oid,
            "customer_id": rng.randint(1, n_customers),
            "order_ts": order_ts.isoformat(sep=" "),
            "channel": rng.choice(CHANNELS),
            "payment_method": rng.choice(PAYMENT_METHODS),
            "status": rng.choice(STATUSES),
            "shipping_cost": f"{rng.choice([0, 0, 3.99, 4.99, 6.99]):.2f}",
        })
        for product in rng.sample(products, k=rng.choices([1, 2, 3, 4], [55, 25, 15, 5])[0]):
            discount = rng.choices([0, 0.05, 0.10, 0.20], [70, 12, 12, 6])[0]
            items.append({
                "order_item_id": item_id,
                "order_id": oid,
                "product_id": product["product_id"],
                "quantity": rng.choices([1, 2, 3, 5], [70, 20, 7, 3])[0],
                "unit_price": product["unit_price"],
                "discount_pct": f"{discount:.2f}",
            })
            item_id += 1

    tables = {"customers": customers, "products": products, "orders": orders, "order_items": items}
    for name, rows in tables.items():
        with open(OUT / f"{name}.csv", "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    return {name: len(rows) for name, rows in tables.items()}


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--customers", type=int, default=800)
    ap.add_argument("--orders", type=int, default=6000)
    ap.add_argument("--start", type=date.fromisoformat, default=date(2024, 1, 1))
    ap.add_argument("--end", type=date.fromisoformat, default=date(2025, 12, 31))
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    counts = generate(args.customers, args.orders, args.start, args.end, args.seed)
    for name, n in counts.items():
        print(f"{name:<12} {n:>6} rows -> data/raw/{name}.csv")


if __name__ == "__main__":
    main()
