#!/usr/bin/env python3
"""
Catalog generator for Farm Rush.

Produces 100 vehicles and 100 farmer items as:
  - lib/data/vehicles_catalog.dart   (Dart source consumed by the Flutter app)
  - lib/data/farmer_items_catalog.dart
  - functions/seed/vehicles.json      (Firestore seed data)
  - functions/seed/farmer_items.json

Everything is data-driven so prices / tiers / unlock rules live in one place.
Two vehicles and two farmer items are flagged free-unlock so guests / new
users can play immediately.
"""
import json
import os
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB_DATA = ROOT / "lib" / "data"
SEED = ROOT / "functions" / "seed"
LIB_DATA.mkdir(parents=True, exist_ok=True)
SEED.mkdir(parents=True, exist_ok=True)

# Rarity drives the frame glow colour a player earns when they own/equip it.
TIERS = [
    # name,       rarity,       coin_mult, gem_price, glow
    ("Starter",   "common",     1,         0,   "none"),
    ("Bronze",    "common",     3,         0,   "none"),
    ("Silver",    "uncommon",   8,         0,   "silver"),
    ("Gold",      "rare",       20,        0,   "gold"),
    ("Platinum",  "epic",       0,         120, "gold"),
    ("Diamond",   "epic",       0,         280, "rainbow"),
    ("Legendary", "legendary",  0,         600, "legendary"),
]

VEHICLE_FAMILIES = [
    # family,        base_speed, base_capacity, base_power, emoji
    ("Tractor",       10, 20, 12, "🚜"),
    ("Harvester",     8,  40, 30, "🌾"),
    ("Pickup Truck",  16, 30, 6,  "🛻"),
    ("Hay Baler",     7,  50, 18, "🧺"),
    ("Crop Duster",   22, 14, 20, "✈️"),
    ("Delivery Van",  18, 45, 4,  "🚐"),
    ("Quad Bike",     20, 10, 8,  "🏍️"),
    ("Combine",       9,  60, 40, "🚛"),
    ("Fishing Boat",  14, 35, 10, "⛵"),
    ("Monster Truck", 15, 25, 16, "🛞"),
    ("Seed Drill",    6,  30, 24, "🌱"),
    ("Orchard Cart",  12, 22, 14, "🍎"),
    ("Milk Tanker",   13, 55, 5,  "🥛"),
    ("Sprinkler Rig", 11, 18, 9,  "💧"),
]

VEHICLE_PREFIXES = [
    "Rusty", "Trusty", "Turbo", "Country", "Harvest", "Golden", "Prairie",
    "Thunder", "Blaze", "Comet", "Meadow", "Sunset", "Ranger", "Royal",
    "Mega", "Nitro", "Aurora", "Phoenix", "Titan", "Galaxy",
]

ITEM_CATEGORIES = [
    # category,   families (name, base_boost, emoji, boost_stat)
    ("Hat",       [("Straw Hat", "💛"), ("Cowboy Hat", "🤠"), ("Sun Cap", "🧢"),
                   ("Bucket Hat", "🪣"), ("Crown", "👑")], "harvestSpeed"),
    ("Outfit",    [("Overalls", "👕"), ("Raincoat", "🧥"), ("Flannel", "🟥"),
                   ("Apron", "🎽"), ("Explorer Vest", "🦺")], "staminaMax"),
    ("Tool",      [("Watering Can", "🚿"), ("Scythe", "🪓"), ("Pitchfork", "🔱"),
                   ("Shovel", "🥄"), ("Shears", "✂️")], "toolPower"),
    ("Pet",       [("Farm Dog", "🐕"), ("Barn Cat", "🐈"), ("Duckling", "🐥"),
                   ("Piglet", "🐖"), ("Pony", "🐴")], "coinBonus"),
    ("Booster",   [("Coffee", "☕"), ("Energy Drink", "🥤"), ("Vitamins", "💊"),
                   ("Lucky Clover", "🍀"), ("Golden Apple", "🍏")], "allRound"),
]

ITEM_PREFIXES = [
    "Simple", "Handy", "Shiny", "Lucky", "Antique", "Deluxe", "Enchanted",
    "Festive", "Vintage", "Royal", "Cosmic", "Radiant", "Mythic", "Ancient",
]


def coin_price(index, mult):
    base = 150 + index * 35
    return base * mult


def build_vehicles():
    vehicles = []
    counter = 0
    # Walk tiers x families so the catalogue is varied and progressive.
    for t_i, (tier, rarity, coin_mult, gem_price, glow) in enumerate(TIERS):
        for f_i, (family, spd, cap, pwr, emoji) in enumerate(VEHICLE_FAMILIES):
            if counter >= 100:
                break
            prefix = VEHICLE_PREFIXES[counter % len(VEHICLE_PREFIXES)]
            scale = 1 + t_i * 0.6
            is_free = counter in (0, 1)  # first two tractors are free
            currency = "gems" if gem_price > 0 else "coins"
            price = gem_price if gem_price > 0 else coin_price(counter, coin_mult)
            if is_free:
                price = 0
            vehicles.append({
                "id": f"veh_{counter:03d}",
                "name": f"{prefix} {family}",
                "family": family,
                "tier": tier,
                "rarity": "common" if is_free else rarity,
                "currency": "free" if is_free else currency,
                "price": price,
                "speed": round(spd * scale, 1),
                "capacity": int(cap * scale),
                "harvestPower": round(pwr * scale, 1),
                "glow": "none" if is_free else glow,
                "emoji": emoji,
                "freeUnlock": is_free,
                "colorHex": _color_for(rarity),
            })
            counter += 1
        if counter >= 100:
            break
    # Top up to exactly 100 if families ran short.
    while len(vehicles) < 100:
        i = len(vehicles)
        vehicles.append({
            "id": f"veh_{i:03d}", "name": f"Galaxy Combine MK{i}",
            "family": "Combine", "tier": "Legendary", "rarity": "legendary",
            "currency": "gems", "price": 600 + i, "speed": 18.0,
            "capacity": 90, "harvestPower": 70.0, "glow": "legendary",
            "emoji": "🚛", "freeUnlock": False, "colorHex": _color_for("legendary"),
        })
    return vehicles[:100]


def build_items():
    items = []
    counter = 0
    for t_i, (tier, rarity, coin_mult, gem_price, glow) in enumerate(TIERS):
        for cat, families, stat in ITEM_CATEGORIES:
            for (base_name, emoji) in families:
                if counter >= 100:
                    break
                prefix = ITEM_PREFIXES[counter % len(ITEM_PREFIXES)]
                boost = round(1 + t_i * 0.35, 2)
                is_free = counter in (0, 1)  # straw hat + simple overalls free
                currency = "gems" if gem_price > 0 else "coins"
                price = gem_price if gem_price > 0 else coin_price(counter, coin_mult)
                if is_free:
                    price = 0
                items.append({
                    "id": f"itm_{counter:03d}",
                    "name": f"{prefix} {base_name}",
                    "category": cat,
                    "tier": tier,
                    "rarity": "common" if is_free else rarity,
                    "currency": "free" if is_free else currency,
                    "price": price,
                    "boostStat": stat,
                    "boostValue": 1.0 if is_free else boost,
                    "glow": "none" if is_free else glow,
                    "emoji": emoji,
                    "freeUnlock": is_free,
                    "colorHex": _color_for(rarity),
                })
                counter += 1
            if counter >= 100:
                break
        if counter >= 100:
            break
    while len(items) < 100:
        i = len(items)
        items.append({
            "id": f"itm_{i:03d}", "name": f"Mythic Charm {i}", "category": "Booster",
            "tier": "Legendary", "rarity": "legendary", "currency": "gems",
            "price": 500 + i, "boostStat": "allRound", "boostValue": 3.0,
            "glow": "legendary", "emoji": "🍀", "freeUnlock": False,
            "colorHex": _color_for("legendary"),
        })
    return items[:100]


def _color_for(rarity):
    return {
        "common": "0xFF9E9E9E",
        "uncommon": "0xFF4CAF50",
        "rare": "0xFF2196F3",
        "epic": "0xFF9C27B0",
        "legendary": "0xFFFF9800",
    }.get(rarity, "0xFF9E9E9E")


def dart_header(name):
    return (
        "// GENERATED FILE - do not edit by hand.\n"
        "// Regenerate with: python3 tool/generate_catalog.py\n"
        f"// {name}\n\n"
    )


def emit_vehicles_dart(vehicles):
    out = [dart_header("100 purchasable vehicles.")]
    out.append("import '../models/vehicle.dart';\n\n")
    out.append("const List<Vehicle> kVehicleCatalog = <Vehicle>[\n")
    for v in vehicles:
        out.append(
            "  Vehicle(\n"
            f"    id: '{v['id']}',\n"
            f"    name: {json.dumps(v['name'])},\n"
            f"    family: {json.dumps(v['family'])},\n"
            f"    tier: {json.dumps(v['tier'])},\n"
            f"    rarity: Rarity.{v['rarity']},\n"
            f"    currency: Currency.{v['currency']},\n"
            f"    price: {v['price']},\n"
            f"    speed: {float(v['speed'])},\n"
            f"    capacity: {v['capacity']},\n"
            f"    harvestPower: {float(v['harvestPower'])},\n"
            f"    glow: Glow.{v['glow']},\n"
            f"    emoji: {json.dumps(v['emoji'])},\n"
            f"    freeUnlock: {str(v['freeUnlock']).lower()},\n"
            f"    colorHex: {v['colorHex']},\n"
            "  ),\n"
        )
    out.append("];\n")
    (LIB_DATA / "vehicles_catalog.dart").write_text("".join(out))


def emit_items_dart(items):
    out = [dart_header("100 purchasable farmer items.")]
    out.append("import '../models/farmer_item.dart';\n\n")
    out.append("const List<FarmerItem> kFarmerItemCatalog = <FarmerItem>[\n")
    for it in items:
        out.append(
            "  FarmerItem(\n"
            f"    id: '{it['id']}',\n"
            f"    name: {json.dumps(it['name'])},\n"
            f"    category: {json.dumps(it['category'])},\n"
            f"    tier: {json.dumps(it['tier'])},\n"
            f"    rarity: Rarity.{it['rarity']},\n"
            f"    currency: Currency.{it['currency']},\n"
            f"    price: {it['price']},\n"
            f"    boostStat: {json.dumps(it['boostStat'])},\n"
            f"    boostValue: {float(it['boostValue'])},\n"
            f"    glow: Glow.{it['glow']},\n"
            f"    emoji: {json.dumps(it['emoji'])},\n"
            f"    freeUnlock: {str(it['freeUnlock']).lower()},\n"
            f"    colorHex: {it['colorHex']},\n"
            "  ),\n"
        )
    out.append("];\n")
    (LIB_DATA / "farmer_items_catalog.dart").write_text("".join(out))


def main():
    vehicles = build_vehicles()
    items = build_items()
    emit_vehicles_dart(vehicles)
    emit_items_dart(items)
    (SEED / "vehicles.json").write_text(json.dumps(vehicles, indent=2))
    (SEED / "farmer_items.json").write_text(json.dumps(items, indent=2))
    free_v = [v["id"] for v in vehicles if v["freeUnlock"]]
    free_i = [i["id"] for i in items if i["freeUnlock"]]
    print(f"Generated {len(vehicles)} vehicles, {len(items)} items.")
    print(f"Free vehicles: {free_v}")
    print(f"Free items: {free_i}")


if __name__ == "__main__":
    main()
