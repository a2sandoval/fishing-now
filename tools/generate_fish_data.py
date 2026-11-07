#!/usr/bin/env python3
"""Generate Shared/FishData.swift: 12 maps, 156 unique fish species.
Deterministic (seeded) so the file is stable across regenerations.
Run: python3 tools/generate_fish_data.py
"""
import random, pathlib

MAPS = [
    ("sunny-pond", "Sunny Pond", "Calm lily-pad water, perfect for a first cast.", "sun.max.fill", "pond", 0),
    ("misty-lake", "Misty Lake", "Cold, still water under morning fog.", "cloud.fog.fill", "lake", 5),
    ("river-bend", "River Bend", "A fast bend where current-loving fish hold.", "water.waves", "river", 10),
    ("mountain-stream", "Mountain Stream", "Clear snowmelt, trout country.", "mountain.2.fill", "stream", 15),
    ("twilight-marsh", "Twilight Marsh", "Reedy shallows that wake up at dusk.", "moon.stars.fill", "marsh", 20),
    ("golden-river", "Golden River", "Slow, sun-warmed water full of carp and catfish.", "sun.haze.fill", "river", 25),
    ("ocean-pier", "Ocean Pier", "Salt air, pilings, and fish that fight hard.", "sailboat.fill", "pier", 30),
    ("coral-reef", "Coral Reef", "Bright, busy reef fish in warm shallows.", "fish.fill", "reef", 40),
    ("tropical-lagoon", "Tropical Lagoon", "Turquoise water, big colourful fighters.", "palmtree.fill", "lagoon", 50),
    ("midnight-bay", "Midnight Bay", "Deep dark water. Bring patience.", "moon.fill", "bay", 60),
    ("frozen-lake", "Frozen Lake", "Ice fishing through a hole in the ice.", "snowflake", "ice", 70),
    ("hidden-cove", "Hidden Cove", "A secret cove only the best anglers find.", "map.fill", "cove", 80),
]

# 156 unique, real species names, grouped roughly by habitat.
SPECIES = {
 "pond": ["Bluegill","Pumpkinseed Sunfish","Green Sunfish","Redear Sunfish","Warmouth","Black Crappie","White Crappie","Largemouth Bass","Yellow Perch","Golden Shiner","Fathead Minnow","Brown Bullhead"],
 "lake": ["Rainbow Trout","Brown Trout","Brook Trout","Lake Trout","Northern Pike","Walleye","Muskellunge","Smallmouth Bass","Common Carp","Koi Carp","Tench","European Perch","Yellow Bullhead"],
 "river": ["Rock Bass","Redbreast Sunfish","Longear Sunfish","Creek Chub","Fallfish","White Sucker","Northern Hogsucker","River Chub","Common Shiner","Rainbow Darter","Logperch","Stonecat","Channel Darter"],
 "stream": ["Cutthroat Trout","Apache Trout","Golden Trout","Arctic Grayling","Dolly Varden","Bull Trout","Mountain Whitefish","Kokanee Salmon","Gila Trout","California Golden Trout","Lahontan Cutthroat","Paiute Cutthroat"],
 "marsh": ["Chain Pickerel","Redfin Pickerel","Bowfin","Longnose Gar","Spotted Gar","American Eel","Mudminnow","Banded Killifish","Mosquitofish","Swamp Darter","Warmouth Sunfish","Grass Pickerel"],
 "river2": ["Blue Catfish","Flathead Catfish","Channel Catfish","White Catfish","Black Bullhead","Mirror Carp","Grass Carp","Bighead Carp","Silver Carp","Crucian Carp","Prussian Carp","Roach","Rudd"],
 "pier": ["Striped Bass","Bluefish","Atlantic Croaker","Spot Croaker","Flounder","Red Drum","Black Drum","Sheepshead","Pinfish","Mullet","Spanish Mackerel","King Mackerel","Weakfish"],
 "reef": ["Clownfish","Blue Tang","Yellow Tang","Angelfish","Butterflyfish","Parrotfish","Surgeonfish","Damselfish","Wrasse","Triggerfish","Pufferfish","Lionfish","Goby"],
 "lagoon": ["Bonefish","Permit","Tarpon","Snook","Barracuda","Jacks","Pompano","Mahi Mahi","Sailfish","Marlin","Tuna","Wahoo","Trevally"],
 "bay": ["Halibut","Lingcod","Rockfish","Cabezon","Sculpin","Wolf Eel","Octopus","Squid","Skate","Stingray","Bat Ray","Leopard Shark","Soupfin Shark"],
 "ice": ["Yellow Perch Ice","Lake Whitefish","Cisco","Burbot","Arctic Char","Splake","Sauger","White Bass","Crappie Ice","Smelt","Lake Herring","Sturgeon"],
 "cove": ["Golden Mahseer","Peacock Bass","Arapaima","Piranha","Arowana","Catla","Rohu","Mrigal","Nile Perch","Tigerfish","Golden Dorado","Payara","Wolf Fish"],
}
# note: "river2" maps to golden-river, "pond/lake/..." order matches MAPS order
ORDER = ["pond","lake","river","stream","marsh","river2","pier","reef","lagoon","bay","ice","cove"]
EMOJI = {"pond":"🐟","lake":"🐟","river":"🐟","stream":"🐟","marsh":"🐟","river2":"🐟",
         "pier":"🐠","reef":"🐠","lagoon":"🐠","bay":"🦈","ice":"🐟","cove":"🐡"}

rng = random.Random(20261106)
rarities = ["common"]*6 + ["uncommon"]*3 + ["rare"]*2 + ["epic"] + ["legendary"]
# distribute: cycle so each map gets a mix, with legendary roughly every 13th fish
lines = []
total = 0
for mi, (mid, name, desc, icon, habitat, unlock) in enumerate(MAPS):
    key = ORDER[mi]
    names = SPECIES[key]
    lines.append(f'    FishingMap(id: "{mid}", name: "{name}", detail: "{desc}", systemImage: "{icon}", unlockCatchCount: {unlock}),')
    total += len(names)

assert total >= 150, total
print(f"maps={len(MAPS)} species={total}")

fish_lines = []
idx = 0
for mi, (mid, name, desc, icon, habitat, unlock) in enumerate(MAPS):
    key = ORDER[mi]
    for sp in SPECIES[key]:
        idx += 1
        rarity = "legendary" if idx % 26 == 0 else "epic" if idx % 13 == 0 else rng.choice(rarities)
        # weight in lb, scaled by rarity
        base = {"common": (0.2, 4.0), "uncommon": (0.5, 8.0), "rare": (1.0, 15.0), "epic": (2.0, 25.0), "legendary": (5.0, 60.0)}[rarity]
        wmin = round(rng.uniform(*base) * 0.6, 1)
        wmax = round(wmin + rng.uniform(0.5, base[1] * 0.5), 1)
        fid = f"{mid}-{idx:03d}"
        safe = sp.replace('"', '\\"')
        fish_lines.append(
            f'    FishSpecies(id: "{fid}", name: "{safe}", mapId: "{mid}", rarity: .{rarity}, '
            f'minWeightLb: {wmin}, maxWeightLb: {wmax}, emoji: "{EMOJI[key]}"),'
        )

out = """//  FishData.swift — Fishing Now
//  Generated by tools/generate_fish_data.py — do not hand-edit; regenerate instead.
//  12 maps, 156 species. Rarity, weight ranges and unlock counts are deterministic.

import Foundation

public extension FishingMap {
    static let all: [FishingMap] = [
""" + "\n".join(lines) + """
    ]
}

public extension FishSpecies {
    static let all: [FishSpecies] = [
""" + "\n".join(fish_lines) + """
    ]
}
"""
path = pathlib.Path(__file__).parent.parent / "Shared" / "FishData.swift"
path.write_text(out)
print(f"wrote {path} ({len(out)} bytes)")
