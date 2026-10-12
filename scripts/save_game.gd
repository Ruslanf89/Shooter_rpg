class_name SaveGame
extends RefCounted
## Saves the character between sessions (user://save.json): location, level / XP / skills,
## inventory, equipment, gold, stash and ammo. Written when a location is entered or completed,
## every 2 minutes, and when quitting.

const PATH := "user://save.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## Reads the save without applying it ({} when there is none).
static func peek() -> Dictionary:
	if not exists():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func save() -> void:
	var data := {
		"version": 2,
		"level_index": Game.level_index,
		"progress": Game.progress,
		"inventory": Game.inventory,
		"carry": Game.carry,
		"stats": Game.stats,
		"locations": Game.locations,
		"flags": Game.flags,
		"journey": Game.journey,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


## Loads into Game. Returns false if there is no (valid) save.
static func load_into_game() -> bool:
	if not exists():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return false
	Game.level_index = clampi(int(d.get("level_index", 0)), 0, Game.LEVELS.size() - 1)
	var prog: Dictionary = d.get("progress", Skills.new_progress())
	prog["level"] = int(prog.get("level", 1))
	prog["xp"] = int(prog.get("xp", 0))
	prog["points"] = int(prog.get("points", 0))
	var ranks: Dictionary = prog.get("ranks", {})
	for k in ranks:
		ranks[k] = int(ranks[k])
	Game.progress = prog
	Game.inventory = _fix_inventory(d.get("inventory", Items.new_inventory()))
	Game.carry = d.get("carry", {})
	Game.stats = d.get("stats", {"kills": 0, "fired": 0, "hit": 0, "time": 0.0})
	Game.locations = _fix_numbers(d.get("locations", {}))
	Game.flags = d.get("flags", {})
	Game.journey = _fix_numbers(d.get("journey", {}))
	# continuing puts you at the portal once VesPer has built them
	Game.arrive_at = "portal" if Game.flags.get("portal", false) else ""
	return true


## JSON loads every number as a float: turn whole numbers back into ints (deep).
static func _fix_numbers(v):
	if v is Dictionary:
		for k in v:
			v[k] = _fix_numbers(v[k])
	elif v is Array:
		for i in v.size():
			v[i] = _fix_numbers(v[i])
	elif v is float and v == floorf(v) and absf(v) < 1e9:
		return int(v)
	return v


## JSON turns ints into floats and nulls stay nulls: normalise the loaded inventory.
static func _fix_inventory(inv: Dictionary) -> Dictionary:
	var fresh := Items.new_inventory()
	for key in ["bag", "stash"]:
		var arr: Array = inv.get(key, fresh[key])
		var size: int = fresh[key].size()
		arr.resize(size)
		for i in size:
			arr[i] = _fix_item(arr[i])
		inv[key] = arr
	var equip: Dictionary = inv.get("equip", fresh["equip"])
	for s in Items.SLOTS:
		equip[s] = _fix_item(equip.get(s, {}))
		if equip[s] == null:
			equip[s] = {}
	inv["equip"] = equip
	inv["gold"] = int(inv.get("gold", 0))
	for key in ["materials", "consumables", "gadgets"]:
		var d: Dictionary = inv.get(key, {})
		for k in d.keys():
			d[k] = int(d[k])
		inv[key] = d
	inv["active"] = str(inv.get("active", "weapon1"))
	return inv


static func _fix_item(it):
	if not it is Dictionary or it.is_empty():
		return null
	it["level"] = int(it.get("level", 1))
	it["quality"] = int(it.get("quality", 0))
	if it.has("mag"):
		it["mag"] = int(it["mag"])
	if not it.has("affixes"):
		it["affixes"] = {}
	return it


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
