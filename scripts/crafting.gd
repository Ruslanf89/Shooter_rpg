class_name Crafting
extends RefCounted
## Crafting: materials (dropped by monsters, gathered from nodes, salvaged from gear), recipes for
## the field kit (anywhere), the alchemy table, the workbench (tech gadgets only you know how to
## build) and the forge (weapons and armor of your level, upgrades and rerolls).
## Materials, consumables and gadgets are counts in Game.inventory["materials" / "consumables" /
## "gadgets"].

const MATERIALS := {
	"scrap": ["Scrap Metal", Color(0.62, 0.62, 0.66)],
	"hide": ["Beast Hide", Color(0.6, 0.42, 0.25)],
	"bone": ["Bone Shards", Color(0.92, 0.9, 0.8)],
	"chitin": ["Chitin", Color(0.45, 0.5, 0.3)],
	"ectoplasm": ["Ectoplasm", Color(0.5, 1.0, 0.8)],
	"cloth": ["Linen Scraps", Color(0.85, 0.8, 0.68)],
	"fang": ["Sharp Fang", Color(1.0, 0.98, 0.9)],
	"essence": ["Arcane Essence", Color(0.75, 0.45, 1.0)],
	"timber": ["Timber", Color(0.65, 0.45, 0.25)],
	"iron_ore": ["Iron Ore", Color(0.6, 0.45, 0.4)],
	"silver_ore": ["Silver Ore", Color(0.82, 0.85, 0.95)],
	"sulfur": ["Sulfur", Color(1.0, 0.88, 0.2)],
	"herb": ["Healing Herb", Color(0.35, 0.85, 0.3)],
	"glowcap": ["Glowcap", Color(0.3, 0.75, 1.0)],
	"gunpowder": ["Gunpowder", Color(0.35, 0.35, 0.35)],
	"blight_dust": ["Blight Dust", Color(0.55, 0.65, 0.35)],
	"star_iron": ["Star Iron", Color(0.6, 0.8, 1.0)],
	"frost_lotus": ["Frost Lotus", Color(0.75, 0.92, 1.0)],
	"ember_core": ["Ember Core", Color(1.0, 0.45, 0.1)],
	"abyssal_pearl": ["Abyssal Pearl", Color(0.45, 0.35, 0.95)],
}

## Only found in one location: [location index, how].
const RARE := {"blight_dust": [1, "Darkwood ghouls"], "star_iron": [3, "Frostpeak trolls, yetis and silver veins"],
	"frost_lotus": [3, "Frostpeak herbs and wraiths"], "ember_core": [4, "Emberforge golems and imps"],
	"abyssal_pearl": [5, "Sunken Coast clams and the drowned"]}

## Monster drops: type -> [[material, chance, min, max], ...]
const DROPS := {
	"wolf": [["hide", 0.7, 1, 2], ["fang", 0.25, 1, 1]], "snow_wolf": [["hide", 0.7, 1, 2], ["fang", 0.3, 1, 1]],
	"hellhound": [["hide", 0.6, 1, 2], ["fang", 0.35, 1, 1], ["sulfur", 0.3, 1, 1]],
	"gnoll": [["hide", 0.55, 1, 2], ["cloth", 0.3, 1, 1]], "gnoll_brute": [["hide", 0.7, 1, 3], ["fang", 0.3, 1, 1]],
	"gnoll_shaman": [["cloth", 0.5, 1, 2], ["herb", 0.4, 1, 2], ["essence", 0.15, 1, 1]],
	"frost_yeti": [["hide", 0.8, 2, 3], ["star_iron", 0.12, 1, 1]], "ice_troll": [["hide", 0.5, 1, 2], ["star_iron", 0.18, 1, 1]],
	"kobold": [["scrap", 0.5, 1, 2], ["sulfur", 0.2, 1, 1]], "geomancer": [["iron_ore", 0.4, 1, 2], ["essence", 0.12, 1, 1]],
	"bandit": [["scrap", 0.6, 1, 2], ["cloth", 0.5, 1, 2]], "captain": [["scrap", 1.0, 2, 4], ["cloth", 1.0, 2, 3]],
	"cap_bandit": [["scrap", 1.0, 2, 3]], "pirate": [["scrap", 0.6, 1, 2], ["cloth", 0.5, 1, 2], ["abyssal_pearl", 0.06, 1, 1]],
	"cultist": [["cloth", 0.6, 1, 2], ["essence", 0.15, 1, 1]], "flame_cultist": [["cloth", 0.6, 1, 2], ["sulfur", 0.4, 1, 1], ["essence", 0.15, 1, 1]],
	"necromancer": [["cloth", 0.6, 1, 2], ["ectoplasm", 0.4, 1, 1], ["essence", 0.2, 1, 1]],
	"sea_witch": [["cloth", 0.5, 1, 2], ["ectoplasm", 0.4, 1, 1], ["abyssal_pearl", 0.15, 1, 1]],
	"spider": [["chitin", 0.7, 1, 2]], "crab": [["chitin", 0.8, 1, 3], ["abyssal_pearl", 0.06, 1, 1]],
	"skeleton": [["bone", 0.75, 1, 2]], "ghoul": [["bone", 0.5, 1, 2], ["blight_dust", 0.3, 1, 1]],
	"drowned": [["bone", 0.6, 1, 2], ["abyssal_pearl", 0.1, 1, 1]],
	"frost_wraith": [["ectoplasm", 0.6, 1, 2], ["frost_lotus", 0.1, 1, 1]],
	"golem": [["scrap", 0.8, 2, 3], ["iron_ore", 0.4, 1, 2]], "magma_golem": [["scrap", 0.6, 1, 3], ["ember_core", 0.25, 1, 1]],
	"fire_imp": [["sulfur", 0.5, 1, 2], ["ember_core", 0.12, 1, 1]],
	"raptor": [["hide", 0.7, 1, 2], ["fang", 0.45, 1, 2], ["bone", 0.3, 1, 1]],
	"canyon_tyrant": [["hide", 1.0, 4, 6], ["fang", 1.0, 3, 5], ["bone", 1.0, 3, 4], ["ember_core", 1.0, 1, 2]],
	"wild_dino": [["hide", 1.0, 2, 4], ["fang", 0.8, 2, 3], ["bone", 0.7, 1, 3], ["essence", 0.3, 1, 1]],
}

const CONSUMABLES := {
	"health_potion": ["Health Potion", "Restores half your health", Color(0.95, 0.25, 0.25)],
	"greater_potion": ["Greater Health Potion", "Restores all your health", Color(1.0, 0.45, 0.3)],
	"mana_potion": ["Mana Potion", "Restores 60% of your mana", Color(0.35, 0.55, 1.0)],
	"bandage": ["Bandage", "Heals a quarter of your health over 4 s", Color(0.9, 0.88, 0.8)],
}

const GADGETS := {
	"grenade": ["Frag Grenade", "Thrown, explodes after 2 s", Color(0.35, 0.4, 0.25)],
	"landmine": ["Landmine", "Placed at your feet, blows up the first monster that steps on it", Color(0.5, 0.45, 0.3)],
	"turret": ["Sentry Turret", "Placed in front of you, shoots monsters for 40 s", Color(0.6, 0.65, 0.7)],
	"fpv_drone": ["FPV Strike Drone", "Flies to the monster you aim at and explodes - VesPer would be proud", Color(0.75, 0.15, 0.1)],
}

## Recipes. station: field (anywhere) / alchemy / workbench / forge.
## out: {"type": "consumable"|"gadget"|"material"|"ammo", "id", "count"}
const RECIPES := [
	{"id": "ammo_pack", "station": "field", "cost": {"scrap": 3}, "out": {"type": "ammo", "count": 60}},
	{"id": "bandage", "station": "field", "cost": {"cloth": 2}, "out": {"type": "consumable", "id": "bandage", "count": 2}},
	{"id": "health_potion", "station": "alchemy", "cost": {"herb": 2, "bone": 1}, "out": {"type": "consumable", "id": "health_potion", "count": 1}},
	{"id": "mana_potion", "station": "alchemy", "cost": {"glowcap": 2, "herb": 1}, "out": {"type": "consumable", "id": "mana_potion", "count": 1}},
	{"id": "greater_potion", "station": "alchemy", "cost": {"frost_lotus": 1, "herb": 2, "essence": 1}, "out": {"type": "consumable", "id": "greater_potion", "count": 1}},
	{"id": "gunpowder", "station": "alchemy", "cost": {"sulfur": 2, "timber": 1}, "out": {"type": "material", "id": "gunpowder", "count": 2}},
	{"id": "grenade", "station": "workbench", "cost": {"scrap": 2, "gunpowder": 1}, "out": {"type": "gadget", "id": "grenade", "count": 2}},
	{"id": "landmine", "station": "workbench", "cost": {"scrap": 3, "gunpowder": 2}, "out": {"type": "gadget", "id": "landmine", "count": 1}},
	{"id": "turret", "station": "workbench", "cost": {"scrap": 8, "gunpowder": 2, "iron_ore": 2}, "out": {"type": "gadget", "id": "turret", "count": 1}},
	{"id": "fpv_drone", "station": "workbench", "cost": {"scrap": 5, "gunpowder": 2, "essence": 1}, "out": {"type": "gadget", "id": "fpv_drone", "count": 1}},
	{"id": "ammo_crate", "station": "workbench", "cost": {"scrap": 6, "gunpowder": 1}, "out": {"type": "ammo", "count": 200}},
]

const STATION_NAMES := {"field": "Field Kit", "alchemy": "Alchemy Table", "workbench": "Workbench", "forge": "Forge"}

## Extra cost per quality when forging: essences (and rare materials for the top two).
const QUALITY_COST := [{}, {"essence": 2}, {"essence": 5}, {"essence": 10, "fang": 2}, {"essence": 18, "star_iron": 1, "ember_core": 1, "abyssal_pearl": 1}]


static func mats() -> Dictionary:
	if not Game.inventory.has("materials"):
		Game.inventory["materials"] = {}
	return Game.inventory["materials"]


static func pouch(kind: String) -> Dictionary:
	if not Game.inventory.has(kind):
		Game.inventory[kind] = {}
	return Game.inventory[kind]


static func count(id: String) -> int:
	return int(mats().get(id, 0))


static func add(id: String, n: int) -> void:
	mats()[id] = count(id) + n


static func mat_name(id: String) -> String:
	return Loc.t(MATERIALS[id][0]) if MATERIALS.has(id) else id


static func has_all(cost: Dictionary) -> bool:
	for k in cost:
		if k == "gold":
			if int(Game.inventory.get("gold", 0)) < int(cost[k]):
				return false
		elif count(k) < int(cost[k]):
			return false
	return true


static func pay(cost: Dictionary) -> void:
	for k in cost:
		if k == "gold":
			Game.inventory["gold"] = int(Game.inventory["gold"]) - int(cost[k])
		else:
			mats()[k] = count(k) - int(cost[k])


static func recipe(id: String) -> Dictionary:
	for r in RECIPES:
		if r["id"] == id:
			return r
	return {}


static func recipe_name(r: Dictionary) -> String:
	var o: Dictionary = r["out"]
	match o["type"]:
		"consumable":
			return Loc.t(CONSUMABLES[o["id"]][0]) + (" x%d" % o["count"] if o["count"] > 1 else "")
		"gadget":
			return Loc.t(GADGETS[o["id"]][0]) + (" x%d" % o["count"] if o["count"] > 1 else "")
		"material":
			return mat_name(o["id"]) + " x%d" % o["count"]
		"ammo":
			return Loc.t("Ammo") + " x%d" % o["count"]
	return r["id"]


static func recipe_desc(r: Dictionary) -> String:
	var o: Dictionary = r["out"]
	match o["type"]:
		"consumable":
			return Loc.t(CONSUMABLES[o["id"]][1])
		"gadget":
			return Loc.t(GADGETS[o["id"]][1])
		"material":
			return Loc.t("Used for grenades, mines and drones")
		"ammo":
			return Loc.t("Rounds for your guns")
	return ""


## Crafts a simple recipe. Returns false if materials are missing.
static func craft(r: Dictionary, player: Player) -> bool:
	if not has_all(r["cost"]):
		return false
	pay(r["cost"])
	var o: Dictionary = r["out"]
	match o["type"]:
		"consumable", "gadget":
			var p := pouch("consumables" if o["type"] == "consumable" else "gadgets")
			p[o["id"]] = int(p.get(o["id"], 0)) + int(o["count"])
		"material":
			add(o["id"], int(o["count"]))
		"ammo":
			player.add_ammo_silent(int(o["count"]))
	return true


# --------------------------------------------------------------------------- forge

static func ore_for(level: int) -> String:
	return "iron_ore" if level < 19 else "silver_ore"


## Cost of forging a weapon / armor piece of `base` at `level` and `quality`.
static func gear_cost(base: String, level: int, quality: int) -> Dictionary:
	var ore := ore_for(level)
	var c := {}
	if Items.WEAPONS.has(base):
		c = {ore: 4, "timber": 2, "scrap": 3}
	elif base == "amulet":
		c = {ore: 2, "essence": 2, "fang": 1}
	else:
		c = {ore: 2, "hide": 3, "cloth": 2}
	for k in QUALITY_COST[quality]:
		c[k] = int(c.get(k, 0)) + int(QUALITY_COST[quality][k])
	c["gold"] = 15 * level * (quality + 1)
	return c


static func forge(base: String, level: int, quality: int) -> Dictionary:
	var c := gear_cost(base, level, quality)
	if not has_all(c):
		return {}
	var it := Items.generate(level, quality, "", base)
	if not Items.add_to_bag(Game.inventory, it):
		return {}
	pay(c)
	return it


static func upgrade_cost(it: Dictionary) -> Dictionary:
	var q: int = it["quality"]
	if q >= 4:
		return {}
	var c := {ore_for(it["level"]): 2, "essence": [2, 5, 10, 18][q], "gold": 30 * int(it["level"]) * (q + 1)}
	if q == 3:
		for k in ["star_iron", "ember_core", "abyssal_pearl"]:
			c[k] = 1
	return c


## Raises an item's quality by one (with one more bonus).
static func upgrade(it: Dictionary) -> bool:
	var c := upgrade_cost(it)
	if c.is_empty() or not has_all(c):
		return false
	pay(c)
	it["quality"] = int(it["quality"]) + 1
	var pool: Array = (Items.WEAPON_AFFIXES if it["kind"] == "weapon" else Items.ARMOR_AFFIXES).duplicate()
	pool.shuffle()
	for stat in pool:
		if not it["affixes"].has(stat):
			it["affixes"][stat] = Items._roll_affix(stat, it["level"], it["quality"])
			break
	it["name"] = Items.make_name(it)
	return true


static func reroll_cost(it: Dictionary) -> Dictionary:
	return {"essence": 3, "gold": 20 * int(it["level"])}


## New random bonuses, same number of them.
static func reroll(it: Dictionary) -> bool:
	var c := reroll_cost(it)
	if it["affixes"].is_empty() or not has_all(c):
		return false
	pay(c)
	var n: int = it["affixes"].size()
	var pool: Array = (Items.WEAPON_AFFIXES if it["kind"] == "weapon" else Items.ARMOR_AFFIXES).duplicate()
	pool.shuffle()
	it["affixes"] = {}
	for i in mini(n, pool.size()):
		it["affixes"][pool[i]] = Items._roll_affix(pool[i], it["level"], it["quality"])
	return true


## What breaking an item down gives.
static func salvage_yield(it: Dictionary) -> Dictionary:
	var q: int = it["quality"]
	var y := {"scrap": 2 + int(it["level"]) / 8}
	var e: int = [0, 1, 3, 6, 12][q]
	if q == 0 and randf() < 0.3:
		e = 1
	if e > 0:
		y["essence"] = e
	if it["kind"] == "armor" and it["base"] != "amulet":
		y["hide" if randf() < 0.5 else "cloth"] = 1
	return y


static func salvage(it: Dictionary) -> Dictionary:
	var y := salvage_yield(it)
	for k in y:
		add(k, int(y[k]))
	return y


## Materials a dead monster leaves behind: {material: count}.
static func roll_drops(type: String, elite: bool, boss: bool) -> Dictionary:
	var out := {}
	for d in DROPS.get(type, []):
		var chance: float = d[1] * (1.6 if elite else 1.0)
		if boss or randf() < chance:
			out[d[0]] = int(out.get(d[0], 0)) + randi_range(int(d[2]), int(d[3])) * (2 if elite or boss else 1)
	if elite:
		out["essence"] = int(out.get("essence", 0)) + randi_range(1, 2)
	if boss:
		out["essence"] = int(out.get("essence", 0)) + randi_range(3, 5)
	return out


## What a gathering node gives in a location: node kind -> [[material, chance, min, max]].
static func node_yield(kind: String, loc: int) -> Dictionary:
	var out := {}
	match kind:
		"ore":
			out[ore_for(Game.ZONE_LEVELS[loc].x)] = randi_range(1, 3)
			if loc == 3 and randf() < 0.18:
				out["star_iron"] = 1
		"herb":
			out["herb"] = randi_range(1, 3)
			if loc == 3 and randf() < 0.3:
				out["frost_lotus"] = 1
		"mushroom":
			out["glowcap"] = randi_range(1, 3)
		"wood":
			out["timber"] = randi_range(2, 3)
		"sulfur":
			out["sulfur"] = randi_range(1, 3)
		"clam":
			out["chitin"] = randi_range(0, 1)
			if randf() < 0.35:
				out["abyssal_pearl"] = 1
	return out


## Which nodes grow where (weights).
static func node_kinds(loc: int) -> Array:
	match loc:
		0: return ["ore", "ore", "herb", "herb", "mushroom", "wood", "wood", "sulfur"]
		1: return ["mushroom", "mushroom", "mushroom", "herb", "wood", "wood", "ore", "sulfur"]
		2: return ["herb", "herb", "wood", "ore", "ore", "sulfur", "sulfur"]
		3: return ["ore", "ore", "ore", "herb", "herb", "wood"]
		4: return ["sulfur", "sulfur", "sulfur", "ore", "ore", "wood"]
		_: return ["herb", "wood", "ore", "clam", "clam", "clam", "sulfur"]
