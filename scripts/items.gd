class_name Items
extends RefCounted
## Equipment: weapon and armor definitions, quality tiers, random affixes, item generation,
## names, values and tooltip text. An item is a Dictionary:
##   {"uid", "kind": "weapon"|"armor", "base", "level", "quality" (0..4), "affixes": {stat: value},
##    "name", "mag" (weapons: rounds currently loaded)}

const QUALITY := [
	{"name": "Common", "color": Color(0.85, 0.85, 0.85), "mult": 1.0, "affixes": 0, "weight": 60.0},
	{"name": "Uncommon", "color": Color(0.35, 0.95, 0.35), "mult": 1.12, "affixes": 1, "weight": 26.0},
	{"name": "Rare", "color": Color(0.35, 0.6, 1.0), "mult": 1.25, "affixes": 2, "weight": 10.0},
	{"name": "Epic", "color": Color(0.75, 0.4, 1.0), "mult": 1.42, "affixes": 3, "weight": 3.4},
	{"name": "Legendary", "color": Color(1.0, 0.62, 0.15), "mult": 1.65, "affixes": 4, "weight": 0.6},
]

## Weapon bases. dmg = per bullet / pellet at item level 1, Common.
##   fire: "hitscan" | "pellets" | "bolt" | "grenade" | "flame" | "spell"
const WEAPONS := {
	"pistol": {"name": "Pistol", "dmg": 26.0, "interval": 0.17, "auto": false, "mag": 12, "reload": 1.2, "spread": 0.012, "recoil": 0.9, "fire": "hitscan", "pitch": 1.35, "ads_fov": 60.0},
	"smg": {"name": "SMG", "dmg": 15.0, "interval": 0.065, "auto": true, "mag": 32, "reload": 1.6, "spread": 0.022, "recoil": 0.35, "fire": "hitscan", "pitch": 1.25, "ads_fov": 58.0},
	"rifle": {"name": "Assault Rifle", "dmg": 34.0, "interval": 0.1, "auto": true, "mag": 30, "reload": 2.0, "spread": 0.018, "recoil": 0.6, "fire": "hitscan", "pitch": 1.0, "ads_fov": 55.0},
	"shotgun": {"name": "Shotgun", "dmg": 14.0, "pellets": 8, "interval": 0.85, "auto": false, "mag": 6, "reload": 2.4, "spread": 0.065, "recoil": 2.2, "fire": "pellets", "pitch": 0.7, "ads_fov": 62.0},
	"sniper": {"name": "Sniper Rifle", "dmg": 125.0, "interval": 1.25, "auto": false, "mag": 5, "reload": 2.6, "spread": 0.002, "recoil": 3.0, "fire": "hitscan", "pitch": 0.6, "ads_fov": 22.0},
	"lmg": {"name": "Machine Gun", "dmg": 30.0, "interval": 0.075, "auto": true, "mag": 80, "reload": 3.6, "spread": 0.03, "recoil": 0.5, "fire": "hitscan", "pitch": 0.85, "ads_fov": 58.0, "move": 0.85},
	"crossbow": {"name": "Crossbow", "dmg": 140.0, "interval": 0.3, "auto": false, "mag": 1, "reload": 1.3, "spread": 0.0, "recoil": 1.0, "fire": "bolt", "pitch": 1.0, "ads_fov": 45.0},
	"flamethrower": {"name": "Flamethrower", "dmg": 9.0, "interval": 0.06, "auto": true, "mag": 100, "reload": 3.0, "spread": 0.0, "recoil": 0.05, "fire": "flame", "pitch": 1.0, "ads_fov": 70.0},
	"launcher": {"name": "Grenade Launcher", "dmg": 160.0, "interval": 0.9, "auto": false, "mag": 4, "reload": 3.0, "spread": 0.0, "recoil": 2.5, "fire": "grenade", "pitch": 0.5, "ads_fov": 60.0},
	"staff_frost": {"name": "Frost Staff", "dmg": 42.0, "interval": 0.55, "auto": true, "mag": 0, "reload": 0.0, "spread": 0.0, "recoil": 0.3, "fire": "spell", "element": "frost", "mana": 6.0, "ads_fov": 65.0},
	"staff_fire": {"name": "Fire Staff", "dmg": 48.0, "interval": 0.65, "auto": true, "mag": 0, "reload": 0.0, "spread": 0.0, "recoil": 0.3, "fire": "spell", "element": "fire", "mana": 7.0, "ads_fov": 65.0},
	"staff_storm": {"name": "Storm Staff", "dmg": 38.0, "interval": 0.5, "auto": true, "mag": 0, "reload": 0.0, "spread": 0.0, "recoil": 0.3, "fire": "spell", "element": "lightning", "mana": 6.0, "ads_fov": 65.0},
}

const ARMOR := {
	"helmet": {"name": "Helmet", "armor": 0.8},
	"armor": {"name": "Body Armor", "armor": 1.6},
	"gloves": {"name": "Gloves", "armor": 0.5},
	"boots": {"name": "Boots", "armor": 0.6},
	"amulet": {"name": "Amulet", "armor": 0.0},
}

const SLOTS := ["weapon1", "weapon2", "helmet", "armor", "gloves", "boots", "amulet"]

## Affixes: [display text, min per level, max per level, flat (true) or percent].
const AFFIXES := {
	"dmg": ["+%d%% damage", 6.0, 16.0],
	"crit": ["+%d%% critical chance", 2.0, 7.0],
	"crit_dmg": ["+%d%% critical damage", 10.0, 35.0],
	"rate": ["+%d%% fire rate", 4.0, 12.0],
	"reload": ["+%d%% reload speed", 6.0, 18.0],
	"health": ["+%d health", 0.0, 0.0],
	"armor": ["+%d armor", 0.0, 0.0],
	"speed": ["+%d%% move speed", 3.0, 8.0],
	"mana": ["+%d mana", 0.0, 0.0],
	"regen": ["+%d%% health regeneration", 10.0, 35.0],
	"spell": ["+%d%% spell damage", 6.0, 18.0],
	"xp": ["+%d%% experience", 4.0, 10.0],
	"gold": ["+%d%% gold found", 8.0, 25.0],
	"lifesteal": ["+%d life per kill", 0.0, 0.0],
}
const WEAPON_AFFIXES := ["dmg", "crit", "crit_dmg", "rate", "reload", "spell", "lifesteal", "xp"]
const ARMOR_AFFIXES := ["health", "armor", "speed", "mana", "regen", "spell", "xp", "gold", "crit"]

const LEGENDARY_NAMES := {
	"pistol": "Last Word", "smg": "Hornet's Nest", "rifle": "Widowmaker", "shotgun": "Gravedigger", "sniper": "Silent Requiem",
	"lmg": "Iron Tempest", "crossbow": "Nightingale", "flamethrower": "Dragon's Breath", "launcher": "Doomsayer",
	"staff_frost": "Heart of Winter", "staff_fire": "Emberfang", "staff_storm": "Thunderlord",
	"helmet": "Crown of the Watcher", "armor": "Plate of the Last Bastion", "gloves": "Gravehands", "boots": "Striders of Dusk", "amulet": "Eye of the Blight",
}

static var _uid := 0


static func quality_color(q: int) -> Color:
	return QUALITY[clampi(q, 0, 4)]["color"]


## Random quality; `luck` shifts the odds towards rare items (0 normal, 1 elite, 2 boss).
static func roll_quality(luck := 0.0, min_q := 0) -> int:
	var weights := []
	var total := 0.0
	for i in QUALITY.size():
		var w: float = QUALITY[i]["weight"] * pow(1.0 + luck, i * 0.9)
		if i < min_q:
			w = 0.0
		weights.append(w)
		total += w
	var r := randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return min_q


static func random_base(kind := "") -> Array:
	if kind == "":
		kind = "weapon" if randf() < 0.45 else "armor"
	var keys: Array = (WEAPONS if kind == "weapon" else ARMOR).keys()
	return [kind, keys[randi() % keys.size()]]


## New item. kind/base empty = random; quality < 0 = random.
static func generate(level: int, quality := -1, kind := "", base := "", luck := 0.0) -> Dictionary:
	if base == "":
		var kb := random_base(kind)
		kind = kb[0]
		base = kb[1]
	elif kind == "":
		kind = "weapon" if WEAPONS.has(base) else "armor"
	if quality < 0:
		quality = roll_quality(luck)
	level = clampi(level, 1, 50)
	_uid += 1
	var item := {"uid": "%d_%d" % [Time.get_ticks_usec(), _uid], "kind": kind, "base": base, "level": level, "quality": quality, "affixes": {}}
	var pool: Array = (WEAPON_AFFIXES if kind == "weapon" else ARMOR_AFFIXES).duplicate()
	if base == "amulet":
		pool = ["health", "mana", "spell", "xp", "gold", "crit", "dmg", "regen"]
	pool.shuffle()
	var n: int = QUALITY[quality]["affixes"] + (1 if base == "amulet" else 0)
	for i in mini(n, pool.size()):
		item["affixes"][pool[i]] = _roll_affix(pool[i], level, quality)
	if kind == "weapon":
		item["mag"] = int(WEAPONS[base]["mag"])
	item["name"] = make_name(item)
	return item


static func _roll_affix(stat: String, level: int, quality: int) -> float:
	var q: float = 1.0 + quality * 0.15
	match stat:
		"health":
			return roundf(randf_range(6.0, 12.0) * level * q * 0.6 + 10.0)
		"armor":
			return roundf(randf_range(1.0, 2.0) * level * q + 3.0)
		"mana":
			return roundf(randf_range(3.0, 6.0) * level * q * 0.4 + 8.0)
		"lifesteal":
			return roundf(randf_range(1.0, 2.0) * level * q * 0.5 + 2.0)
	var a: Array = AFFIXES[stat]
	return roundf(randf_range(a[1], a[2]) * q)


static func base_name(item: Dictionary) -> String:
	var b: String = item["base"]
	return (WEAPONS[b]["name"] if WEAPONS.has(b) else ARMOR[b]["name"])


static func make_name(item: Dictionary) -> String:
	var q: int = item["quality"]
	if q == 4:
		return LEGENDARY_NAMES.get(item["base"], base_name(item))
	var prefix: String = ["Worn", "Sturdy", "Fine", "Masterwork", ""][q]
	return prefix + " " + base_name(item)


## Display name in the current language (legendary names stay as they are).
static func display_name(item: Dictionary) -> String:
	var q: int = item["quality"]
	if q == 4:
		return str(item["name"])
	var prefix: String = ["Worn", "Sturdy", "Fine", "Masterwork", ""][q]
	return Loc.t(prefix) + " " + Loc.t(base_name(item))


# --------------------------------------------------------------------------- stats

static func weapon_def(item: Dictionary) -> Dictionary:
	return WEAPONS.get(item.get("base", "rifle"), WEAPONS["rifle"])


static func level_mult(level: int) -> float:
	return 1.0 + 0.16 * (level - 1)


## Damage per bullet / pellet / projectile, before player bonuses.
static func weapon_damage(item: Dictionary) -> float:
	var d := weapon_def(item)
	return float(d["dmg"]) * level_mult(item["level"]) * float(QUALITY[item["quality"]]["mult"]) * (1.0 + item["affixes"].get("dmg", 0.0) / 100.0)


static func armor_value(item: Dictionary) -> float:
	if item.get("kind", "") != "armor":
		return 0.0
	var f: float = ARMOR[item["base"]]["armor"]
	return roundf((3.0 + item["level"] * 1.6) * f * float(QUALITY[item["quality"]]["mult"])) + item["affixes"].get("armor", 0.0)


static func value(item: Dictionary) -> int:
	return int((8.0 + item["level"] * 6.0) * pow(1.0 + item["quality"], 1.8))


## Lines for the tooltip: [text, color].
static func tooltip(item: Dictionary) -> Array:
	var lines := []
	var q: int = item["quality"]
	lines.append([display_name(item), quality_color(q)])
	lines.append([Loc.t(QUALITY[q]["name"]) + "  " + Loc.t(base_name(item)) + "   " + Loc.t("Level") + " %d" % item["level"], Color(0.75, 0.75, 0.78)])
	if item["kind"] == "weapon":
		var d := weapon_def(item)
		var dmg := weapon_damage(item)
		if d["fire"] == "pellets":
			lines.append([Loc.t("Damage") + ": %d x %d" % [int(dmg), int(d["pellets"])], Color.WHITE])
		else:
			lines.append([Loc.t("Damage") + ": %d" % int(dmg), Color.WHITE])
		lines.append([Loc.t("Fire rate") + ": %.1f/s" % (1.0 / float(d["interval"])), Color(0.85, 0.85, 0.85)])
		if int(d["mag"]) > 0:
			lines.append([Loc.t("Magazine") + ": %d" % int(d["mag"]), Color(0.85, 0.85, 0.85)])
		else:
			lines.append([Loc.t("Mana per shot") + ": %d" % int(d["mana"]), Color(0.5, 0.7, 1.0)])
	else:
		var av := armor_value(item)
		if av > 0.0:
			lines.append([Loc.t("Armor") + ": %d" % int(av), Color.WHITE])
	for stat in item["affixes"]:
		lines.append([Loc.t(AFFIXES[stat][0]) % int(item["affixes"][stat]), Color(0.55, 0.85, 1.0)])
	lines.append([Loc.t("Value") + ": %d " % value(item) + Loc.t("gold"), Color(1.0, 0.85, 0.35)])
	return lines


## Sum of an affix over all equipped items.
static func total(equip: Dictionary, stat: String) -> float:
	var s := 0.0
	for slot in equip:
		var it = equip[slot]
		if it is Dictionary and not it.is_empty():
			s += float(it["affixes"].get(stat, 0.0))
	return s


static func total_armor(equip: Dictionary) -> float:
	var s := 0.0
	for slot in equip:
		var it = equip[slot]
		if it is Dictionary and not it.is_empty():
			s += armor_value(it)
	return s


## Slot an item goes into ("weapon1" for weapons; the caller may pick weapon2).
static func slot_for(item: Dictionary) -> String:
	return "weapon1" if item["kind"] == "weapon" else str(item["base"])


## Fresh inventory for a new character: AK + pistol, empty bag/stash, some gold.
static func new_inventory() -> Dictionary:
	var bag := []
	bag.resize(30)
	var stash := []
	stash.resize(40)
	var equip := {}
	for s in SLOTS:
		equip[s] = {}
	equip["weapon1"] = generate(1, 0, "weapon", "rifle")
	equip["weapon2"] = generate(1, 0, "weapon", "pistol")
	return {"bag": bag, "stash": stash, "equip": equip, "gold": 50, "active": "weapon1",
		"materials": {}, "consumables": {"health_potion": 2}, "gadgets": {}}


## Puts an item into the first free bag slot. Returns false when the bag is full.
static func add_to_bag(inv: Dictionary, item: Dictionary) -> bool:
	var bag: Array = inv["bag"]
	for i in bag.size():
		if bag[i] == null or (bag[i] is Dictionary and bag[i].is_empty()):
			bag[i] = item
			return true
	return false
