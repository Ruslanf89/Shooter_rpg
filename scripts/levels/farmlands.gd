extends RefCounted
## Location 3: Goldfield Farms - golden evening farmland overrun by gnolls and harvest golems.

const FARM := Vector3(0, 0, -56)
const ORCHARD := Vector3(132, 0, -116)
const CAMP := Vector3(-120, 0, 140)
const POND := Vector3(152, 0, 112)
const FIELDS := [Rect2(-120, -30, 60, 60), Rect2(30, 10, 68, 52), Rect2(-150, -164, 60, 45)]
var village: Village
var capital: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 37, "hill_amp": 5.0,
		"player_start": Vector3(0, 0, -220), "player_yaw": PI,
		"sky": {"top_color": Color(0.3, 0.42, 0.75), "horizon_color": Color(1.0, 0.72, 0.45), "ground_color": Color(0.4, 0.32, 0.25),
			"sun_glow": Color(1.0, 0.7, 0.4), "cloud_color": Color(1.0, 0.86, 0.72), "cloud_shadow": Color(0.72, 0.52, 0.55), "cloud_cover": 0.45},
		"sun_rot": Vector3(-20, -60, 0), "sun_color": Color(1.0, 0.78, 0.52), "sun_energy": 1.45, "ambient": 0.95,
		"fog_color": Color(0.95, 0.78, 0.62), "fog_density": 0.004, "color_saturation": 1.2,
		"grass_tint": Vector3(1.4, 1.15, 0.5), "grass_tint2": Vector3(1.6, 1.25, 0.5), "floor_tint": Vector3(1.3, 1.1, 0.6),
		"dirt_tint": Vector3(1.5, 1.1, 0.8), "rock_tint": Vector3(1.3, 1.15, 0.95), "stone_tint": Vector3(1.2, 1.1, 0.95),
		"field_tint": Vector3(2.1, 1.55, 0.85), "saturation": 1.25,
		"foliage": [Color(0.35, 0.18, 0.04), Color(0.78, 0.5, 0.12), Color(1.0, 0.82, 0.32)],
		"pine_foliage": [Color(0.12, 0.2, 0.06), Color(0.3, 0.38, 0.12), Color(0.55, 0.55, 0.2)],
		"bush_foliage": [Color(0.3, 0.3, 0.06), Color(0.6, 0.55, 0.15), Color(0.9, 0.75, 0.3)],
		"bark_tint": Color(1.2, 0.8, 0.5), "tree_style": "oak", "tree_count": 100, "tree_spacing": 9.0, "pine_ratio": 0.12,
		"grass_base": Color(0.36, 0.38, 0.1), "grass_tip": Color(0.88, 0.76, 0.3),
		"wheat_base": Color(0.55, 0.42, 0.12), "wheat_tip": Color(1.0, 0.86, 0.42),
		"ambience": "forest",
	}


func npcs() -> Array:
	return [
		{"id": "haldor", "name": "Farmer Haldor", "title": "Goldfield Farm", "pos": FARM + Vector3(4, 0, 5), "yaw": 180, "model": "people/farmer"},
		{"id": "millie", "name": "Millie", "title": "The Miller", "pos": FARM + Vector3(23, 0, -6), "yaw": 220, "model": "people/woman_dress", "colors": {"Dress": Color(0.72, 0.66, 0.55), "Hair": Color(0.6, 0.4, 0.2)}},
		{"id": "ostrand", "name": "Captain Ostrand", "title": "Kingdom's Watch", "pos": Vector3(10, 0, -200), "yaw": 200, "model": "people/adventurer", "colors": {"LightGreen": Color(0.38, 0.44, 0.58), "Green": Color(0.2, 0.25, 0.4), "Gold": Color(0.85, 0.7, 0.3)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": Vector3(-8, 0, -204), "yaw": 160, "model": "people/casual",
			"colors": {"White": "print", "LightBlue": Color(0.06, 0.06, 0.07), "Red_Dark": Color(0.16, 0.16, 0.17), "Hair": Color(0.16, 0.1, 0.06), "Skin": Color(0.88, 0.68, 0.6)},
			"face": "res://assets/textures/vesper_face.png", "pitch": 1.25},
	]


func quests() -> Array:
	var wheat := []
	for f: Rect2 in FIELDS:
		for k in 4:
			wheat.append(Vector3(f.position.x + f.size.x * (0.2 + 0.2 * k), 0, f.position.y + f.size.y * (0.3 + 0.13 * k)))
	return [
		{"id": "gf_gnolls", "giver": "ostrand", "title": "The Gnoll Raiders", "type": "kill", "target": "gnoll", "count": 10, "label": "Gnoll Raiders slain", "xp": 450,
			"lines": {"offer": "gf_gnolls_offer", "done": "gf_gnolls_done"}},
		{"id": "gf_shamans", "giver": "ostrand", "title": "Silence the Shamans", "type": "kill", "target": "gnoll_shaman", "count": 4, "label": "Gnoll Shamans slain", "xp": 400,
			"requires": ["gf_gnolls"], "lines": {"offer": "gf_shamans_offer", "done": "gf_shamans_done"}},
		{"id": "gf_warlord", "giver": "ostrand", "title": "Gash the Warlord", "type": "boss", "target": "warlord", "boss_pos": CAMP + Vector3(0, 0, 3), "label": "Warlord slain", "xp": 900,
			"requires": ["gf_shamans"], "lines": {"offer": "gf_warlord_offer", "done": "gf_warlord_done"}},
		{"id": "gf_gears", "giver": "haldor", "title": "Mad Machines", "type": "collect", "target": "golem", "item": "Golem Gear", "count": 5, "chance": 0.8, "xp": 450,
			"lines": {"offer": "gf_gears_offer", "done": "gf_gears_done"}},
		{"id": "gf_wheat", "giver": "millie", "title": "Scattered Harvest", "type": "gather", "item": "Wheat Sheaf", "count": 8, "xp": 400, "spots": wheat,
			"lines": {"offer": "gf_wheat_offer", "done": "gf_wheat_done"}},
		{"id": "gf_flour", "giver": "millie", "to": "haldor", "title": "Fresh Flour", "type": "deliver", "item": "Sack of Flour", "xp": 250, "requires": ["gf_wheat"],
			"lines": {"offer": "gf_flour_offer", "done": "gf_flour_done"}},
		{"id": "vesper_gf", "giver": "vesper", "title": "Barn Landing", "type": "gather", "item": "FPV Drone", "count": 1, "xp": 450,
			"spots": [Vector3(-14.6, 3.05, -62.0)], "lines": {"offer": "vesper_gf_offer", "done": "vesper_gf_done"}},
	]


func pois() -> Array:
	return [["ruin", Vector3(-190, 0, -44), 0.0], ["statue", Vector3(60, 0, 144), 180.0], ["cart", Vector3(-36, 0, -156), 20.0], ["arch", Vector3(230, 0, -150), 90.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	w.add_path(Vector2(0, -224), Vector2(0, -80))
	w.add_path(Vector2(0, -80), Vector2(0, 20))
	w.add_path(Vector2(0, 20), Vector2(0, 84))
	w.add_path(Vector2(0, 84), Vector2(-84, 124))
	w.add_path(Vector2(0, -24), Vector2(100, -100))
	w.add_path(Vector2(0, 84), Vector2(124, 100))
	w.add_path(Vector2(0, -120), Vector2(-80, -132))
	w.add_zone(Vector2(FARM.x, FARM.z), 26.0)
	w.add_zone(Vector2(ORCHARD.x, ORCHARD.z), 18.0)
	w.add_zone(Vector2(CAMP.x, CAMP.z), 22.0)
	w.add_zone(Vector2(0, -216), 8.0)
	for f: Rect2 in FIELDS:
		w.add_zone(f.get_center(), maxf(f.size.x, f.size.y) * 0.55)
		w.paint_rect(f, 2)
	w.add_lake(Vector2(POND.x, POND.z), 12.0, 2.5)
	w.paint_rect(Rect2(FARM.x - 6, FARM.z - 4, 14, 10), 1)
	w.add_landmark("Goldfield Farm", Vector2(FARM.x, FARM.z), 15.0, Color(0.9, 0.7, 0.35))
	w.add_landmark("Orchard", Vector2(ORCHARD.x, ORCHARD.z), 13.0, Color(0.85, 0.5, 0.2))
	w.add_landmark("Gnoll War Camp", Vector2(CAMP.x, CAMP.z), 16.0, Color(0.75, 0.25, 0.15))
	w.add_landmark("Duck Pond", Vector2(POND.x, POND.z), 12.0, Color(0.3, 0.5, 0.8))
	for f: Rect2 in FIELDS:
		w.add_landmark("Wheat", f.get_center(), minf(f.size.x, f.size.y) * 0.45, Color(0.95, 0.8, 0.3))
	village = Village.plan(w, Vector3(60, 0, -165), "farm", 5, 8, "Wheatley", 31)
	# Kingsreach, the royal capital, with the King's castle
	capital = Village.plan(w, Vector3(180, 0, 20), "city_capital", 14, 16, "Kingsreach", 77)
	w.add_path(capital.gate_road_end(0), Vector2(60, -70), 4.0)
	w.plan_feature("ruined_castle", Vector3(190, 0, 190), 16.0, "Old Fort")
	w.plan_feature("granary", Vector3(-60, 0, 0), 5.0)
	w.plan_feature("crypt", Vector3(-200, 0, -60), 10.0, "Farmers' Crypt")


func spawns() -> Array:
	var o := ORCHARD
	var c := CAMP
	var p := POND
	return [
		["golem", Vector3(-80, 0, 10)], ["golem", Vector3(-100, 0, -10)], ["golem", Vector3(70, 0, 50)],
		["golem", Vector3(90, 0, 30)], ["golem", Vector3(-120, 0, -130)],
		["gnoll", Vector3(-60, 0, 30)], ["gnoll", Vector3(50, 0, 60)], ["gnoll", Vector3(-110, 0, -124)], ["gnoll", Vector3(-90, 0, -140)],
		["gnoll", FARM + Vector3(6, 0, 8)], ["gnoll", FARM + Vector3(-9, 0, 9)], ["gnoll", FARM + Vector3(14, 0, -8)],
		["gnoll_shaman", FARM + Vector3(-4, 0, -2)], ["gnoll_shaman", FARM + Vector3(18, 0, 2)],
		["gnoll", o + Vector3(-5, 0, 4)], ["gnoll", o + Vector3(5, 0, -4)], ["gnoll", o + Vector3(0, 0, 8)],
		["gnoll_brute", o + Vector3(2, 0, 0)], ["gnoll_shaman", o + Vector3(-6, 0, -6)],
		["gnoll_brute", p + Vector3(-14, 0, -6)], ["gnoll", p + Vector3(-16, 0, 4)], ["gnoll", p + Vector3(-10, 0, -14)],
		["gnoll", c + Vector3(-5, 0, -6)], ["gnoll", c + Vector3(6, 0, -5)], ["gnoll", c + Vector3(-8, 0, 5)],
		["gnoll_brute", c + Vector3(4, 0, 6)], ["gnoll_brute", c + Vector3(-3, 0, 9)],
		["gnoll_shaman", c + Vector3(8, 0, 2)], ["gnoll_shaman", c + Vector3(-9, 0, -2)],
		["gnoll", Vector3(-40, 0, 100)], ["gnoll", Vector3(80, 0, -20)], ["gnoll", Vector3(-70, 0, -70)],
	]


func barrels() -> Array:
	return [CAMP + Vector3(6, 0, -7), CAMP + Vector3(-8, 0, 6), CAMP + Vector3(8, 0, 7), FARM + Vector3(16, 0, 6),
		ORCHARD + Vector3(3, 0, 3), POND + Vector3(-15, 0, 0), Vector3(-60, 0, 40)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	_farm(w, FARM)
	_orchard(w, ORCHARD, rng)
	_camp(w, CAMP, rng)
	Props.water(w, POND, 12.0, -0.6, Color(0.1, 0.25, 0.3), Color(0.4, 0.55, 0.5))
	for f: Rect2 in FIELDS:
		var a := f.position
		var b := f.end
		Props.fence(w, Vector3(a.x, 0, a.y), Vector3(b.x, 0, a.y))
		Props.fence(w, Vector3(a.x, 0, b.y), Vector3(b.x - 8, 0, b.y))
		Props.scarecrow(w, Vector3(f.get_center().x + 4, 0, f.get_center().y - 3), rng.randf_range(0, 360))
	for i in 10:
		var f: Rect2 = FIELDS[i % FIELDS.size()]
		Props.haystack(w, Vector3(f.end.x + 3, 0, f.position.y + 4 + i * 2.5))
	village.build(w)
	capital.build(w)


func _farm(w: Node3D, o: Vector3) -> void:
	Props.house(w, o + Vector3(8, 0, -6), 0, Vector3(9, 4.5, 7), Color(1.3, 0.55, 0.4))
	# red barn
	Buildings.barn(w, o + Vector3(-12, 0, -4), 90)

	Props.windmill(w, o + Vector3(24, 0, -14), -20)
	Props.well(w, o + Vector3(0, 0, 8))
	Props.haystack(w, o + Vector3(-18, 0, 8))
	Props.hay_bale(w, o + Vector3(-6, 0, 6), 10)
	Props.hay_bale(w, o + Vector3(-6, 1, 6), 40)
	Props.barrel(w, o + Vector3(13, 0, 2))
	Props.crate(w, o + Vector3(14, 0, 3.5), 20)
	Props.fence(w, o + Vector3(-20, 0, 14), o + Vector3(-6, 0, 14))
	Props.lantern(w, o + Vector3(3, 0, -1))


func _orchard(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var pts := []
	for gx in range(-2, 3):
		for gz in range(-2, 3):
			if gx == 0 and gz == 0:
				continue
			var x := o.x + gx * 7.0 + rng.randf_range(-0.8, 0.8)
			var z := o.z + gz * 7.0 + rng.randf_range(-0.8, 0.8)
			pts.append(Vector3(x, w.ground(x, z), z))
	var cfg: Dictionary = w.cfg.duplicate()
	cfg["pine_ratio"] = 0.0
	Nature.plant_trees(w, pts, cfg, rng)
	for i in 6:
		Props.crate(w, o + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10)), rng.randf_range(0, 90))


func _camp(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var hide := Color(0.55, 0.42, 0.28)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		Props.tent(w, o + Vector3(cos(a) * 13.0, 0, sin(a) * 13.0), -rad_to_deg(a) - 90, hide if i % 2 == 0 else Color(0.45, 0.3, 0.2))
	Props.campfire(w, o)
	Props.palisade(w, o, 20.0, 90.0, 300.0)
	var bone := MeshKit.mat(Color(0.92, 0.88, 0.78))
	var paint := [MeshKit.mat(Color(0.7, 0.15, 0.1)), MeshKit.mat(Color(0.2, 0.35, 0.7)), MeshKit.mat(Color(0.85, 0.7, 0.2))]
	for i in 4:
		var a := TAU * i / 4.0
		var n := Props.pivot(w, o + Vector3(cos(a) * 7.0, 0, sin(a) * 7.0), rng.randf_range(0, 360))
		for k in 4:
			MeshKit.box(n, Vector3(0.7 - k * 0.08, 0.8, 0.7 - k * 0.08), Vector3(0, 0.4 + k * 0.8, 0), paint[(i + k) % 3])
		MeshKit.sphere(n, 0.3, Vector3(0, 3.5, 0), bone)
		MeshKit.box(n, Vector3(1.6, 0.12, 0.12), Vector3(0, 2.8, 0), bone)
		MeshKit.collider_box(n, Vector3(0.7, 3.4, 0.7), Vector3(0, 1.7, 0))
	Props.torch(w, o + Vector3(-4, 0, -12))
	Props.torch(w, o + Vector3(4, 0, -12))
	# warlord banner
	var b := Props.pivot(w, o + Vector3(0, 0, 9))
	MeshKit.static_box(b, Vector3(0.2, 6, 0.2), Vector3(0, 3, 0), Props.dark_wood())
	MeshKit.box(b, Vector3(1.8, 2.6, 0.05), Vector3(0.95, 4.4, 0), MeshKit.mat(Color(0.65, 0.12, 0.08)))
	MeshKit.sphere(b, 0.3, Vector3(0, 6.2, 0), bone)
