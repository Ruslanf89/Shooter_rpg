extends RefCounted
## Location 4: Frostpeak Pass - snowy mountain pass with yetis, trolls and wraiths.

const OUTPOST := Vector3(0, 0, -184)
const LAKE := Vector3(-110, 0, -40)
const RIDGE := Vector3(120, 0, -110)
const TROLLS := Vector3(136, 0, 64)
const HOLLOW := Vector3(-136, 0, 116)
const CAVES := Vector3(0, 0, 176)
var village: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 51, "hill_amp": 9.0, "weather": "snow",
		"player_start": Vector3(0, 0, -224), "player_yaw": PI,
		"sky": {"top_color": Color(0.45, 0.55, 0.7), "horizon_color": Color(0.85, 0.88, 0.92), "ground_color": Color(0.7, 0.72, 0.75),
			"sun_glow": Color(0.95, 0.95, 1.0), "cloud_color": Color(0.92, 0.93, 0.96), "cloud_shadow": Color(0.62, 0.66, 0.74), "cloud_cover": 0.75},
		"sun_rot": Vector3(-30, 30, 0), "sun_color": Color(0.9, 0.93, 1.0), "sun_energy": 1.1, "ambient": 1.1,
		"fog_color": Color(0.82, 0.86, 0.92), "fog_density": 0.009, "color_saturation": 0.9,
		"grass_tex": "Snow006", "grass_tint": Vector3(1.0, 1.0, 1.04), "grass_tint2": Vector3(0.93, 0.95, 1.0), "floor_tint": Vector3(2, 2.0, 2.2), "floor_amount": 0.4,
		"dirt_tint": Vector3(1.3, 1.25, 1.25), "rock_tint": Vector3(1, 1.02, 1.1), "stone_tint": Vector3(1, 1.0, 1.05),
		"field_tint": Vector3(1.5, 1.5, 1.6), "saturation": 0.12,
		"foliage": [Color(0.1, 0.16, 0.12), Color(0.3, 0.4, 0.3), Color(0.55, 0.6, 0.5)], "leaf_snow": 0.75, "shrubs": false,
		"pine_foliage": [Color(0.06, 0.12, 0.1), Color(0.16, 0.28, 0.2), Color(0.3, 0.4, 0.32)],
		"bush_foliage": [Color(0.3, 0.35, 0.35), Color(0.7, 0.75, 0.78), Color(0.95, 0.97, 1.0)],
		"bark_tint": Color(0.6, 0.55, 0.55), "tree_style": "oak", "tree_count": 200, "tree_spacing": 7.5, "pine_ratio": 0.85,
		"rock_color": Color(1.1, 1.1, 1.2), "rock_count": 70,
		"grass_base": Color(0.6, 0.65, 0.65), "grass_tip": Color(0.95, 0.97, 1.0), "grass_per_chunk": 70,
		"ambience": "wind",
	}


func npcs() -> Array:
	return [
		{"id": "thorgrim", "name": "Thorgrim Ironbeard", "title": "Outpost Commander", "pos": OUTPOST + Vector3(5, 0, 6), "yaw": 180, "model": "people/worker", "colors": {"Worker_Vest": Color(0.4, 0.3, 0.2), "Worker_Yellow": Color(0.45, 0.42, 0.38), "Moustache": Color(0.5, 0.25, 0.12)}},
		{"id": "sila", "name": "Ranger Sila", "title": "Ranger of the Pass", "pos": LAKE + Vector3(19, 0, -8), "yaw": 240, "model": "people/woman_casual", "colors": {"Shirt": Color(0.28, 0.4, 0.34), "Pants": Color(0.3, 0.25, 0.2), "Hair": Color(0.15, 0.1, 0.07)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": Vector3(-10, 0, -206), "yaw": 160, "model": "people/casual",
			"colors": {"White": "print", "LightBlue": Color(0.06, 0.06, 0.07), "Red_Dark": Color(0.16, 0.16, 0.17), "Hair": Color(0.16, 0.1, 0.06), "Skin": Color(0.88, 0.68, 0.6)},
			"face": "res://assets/textures/vesper_face.png", "build": Vector3(1.22, 1.0, 1.18), "pitch": 1.25},
	]


func quests() -> Array:
	var lotus := []
	for i in 8:
		var a := TAU * i / 8.0
		lotus.append(LAKE + Vector3(cos(a) * 17.0, 0, sin(a) * 17.0))
	return [
		{"id": "fp_wolves", "giver": "thorgrim", "title": "Hungry Wolves", "type": "kill", "target": "snow_wolf", "count": 8, "label": "Snow Wolves slain", "xp": 500,
			"lines": {"offer": "fp_wolves_offer", "done": "fp_wolves_done"}},
		{"id": "fp_trolls", "giver": "thorgrim", "title": "Trolls in the Pass", "type": "kill", "target": "ice_troll", "count": 6, "label": "Ice Trolls slain", "xp": 550,
			"requires": ["fp_wolves"], "lines": {"offer": "fp_trolls_offer", "done": "fp_trolls_done"}},
		{"id": "fp_frostmaw", "giver": "thorgrim", "title": "Frostmaw the Ancient", "type": "boss", "target": "frostmaw", "boss_pos": CAVES + Vector3(0, 0, -6), "label": "Frostmaw slain", "xp": 1000,
			"requires": ["fp_trolls", "fp_supplies"], "lines": {"offer": "fp_frostmaw_offer", "done": "fp_frostmaw_done"}},
		{"id": "fp_fur", "giver": "sila", "title": "Warm Cloaks", "type": "collect", "target": "frost_yeti", "item": "Yeti Fur", "count": 6, "chance": 0.75, "xp": 500,
			"lines": {"offer": "fp_fur_offer", "done": "fp_fur_done"}},
		{"id": "fp_lotus", "giver": "sila", "title": "Frost Lotus", "type": "gather", "item": "Frost Lotus", "count": 6, "xp": 450, "spots": lotus,
			"lines": {"offer": "fp_lotus_offer", "done": "fp_lotus_done"}},
		{"id": "fp_supplies", "giver": "sila", "to": "thorgrim", "title": "Supplies for the Outpost", "type": "deliver", "item": "Outpost Supplies", "xp": 300,
			"requires": ["fp_lotus"], "lines": {"offer": "fp_supplies_offer", "done": "fp_supplies_done"}},
		{"id": "vesper_fp", "giver": "vesper", "title": "Frozen Rotors", "type": "gather", "item": "FPV Drone", "count": 1, "xp": 500,
			"spots": [LAKE + Vector3(-12, 0, 11)], "lines": {"offer": "vesper_fp_offer", "done": "vesper_fp_done"}},
	]


func pois() -> Array:
	return [["cairn", Vector3(-184, 0, -140), 0.0], ["crystals", Vector3(70, 0, 144), 0.0], ["ruin", Vector3(60, 0, -36), 30.0],
		["statue", Vector3(176, 0, 160), 225.0], ["cairn", Vector3(-190, 0, 40), 0.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	var cross := Vector2(0, -60)
	var mid := Vector2(0, 80)
	w.add_path(Vector2(0, -230), Vector2(0, -160))
	w.add_path(Vector2(0, -160), cross)
	w.add_path(cross, Vector2(-76, -50))
	w.add_path(cross, Vector2(100, -100))
	w.add_path(cross, mid)
	w.add_path(mid, Vector2(0, 150))
	w.add_path(mid, Vector2(110, 64))
	w.add_path(mid, Vector2(-110, 110))
	w.add_zone(Vector2(OUTPOST.x, OUTPOST.z), 20.0)
	w.add_zone(Vector2(RIDGE.x, RIDGE.z), 14.0)
	w.add_zone(Vector2(TROLLS.x, TROLLS.z), 18.0)
	w.add_zone(Vector2(HOLLOW.x, HOLLOW.z), 16.0)
	w.add_zone(Vector2(CAVES.x, CAVES.z), 22.0)
	w.add_lake(Vector2(LAKE.x, LAKE.z), 14.0, 1.5)
	w.paint_rect(Rect2(OUTPOST.x - 12, OUTPOST.z - 10, 24, 22), 1)
	w.add_landmark("Ironbeard Outpost", Vector2(OUTPOST.x, OUTPOST.z), 14.0, Color(0.7, 0.6, 0.5))
	w.add_landmark("Frozen Lake", Vector2(LAKE.x, LAKE.z), 14.0, Color(0.6, 0.8, 1.0))
	w.add_landmark("Wolf Ridge", Vector2(RIDGE.x, RIDGE.z), 11.0, Color(0.7, 0.7, 0.75))
	w.add_landmark("Troll Camp", Vector2(TROLLS.x, TROLLS.z), 14.0, Color(0.45, 0.6, 0.85))
	w.add_landmark("Yeti Hollow", Vector2(HOLLOW.x, HOLLOW.z), 12.0, Color(0.85, 0.9, 1.0))
	w.add_landmark("Ice Caves", Vector2(CAVES.x, CAVES.z), 14.0, Color(0.5, 0.75, 1.0))
	village = Village.plan(w, Vector3(-62, 0, -165), "fort", 5, 7, "Fort Winterhold", 41)
	w.plan_feature("ruined_castle", Vector3(190, 0, -10), 16.0, "Frozen Keep")
	w.plan_feature("crypt", Vector3(-190, 0, 30), 10.0, "Ice Tomb")
	w.plan_feature("gatehouse", Vector3(0, 0, -120), 6.0)


func spawns() -> Array:
	var r := RIDGE
	var t := TROLLS
	var h := HOLLOW
	var c := CAVES
	return [
		["snow_wolf", r + Vector3(3, 0, 2)], ["snow_wolf", r + Vector3(-4, 0, -3)], ["snow_wolf", r + Vector3(1, 0, -6)],
		["snow_wolf", r + Vector3(6, 0, -4)], ["snow_wolf", r + Vector3(-2, 0, 5)],
		["snow_wolf", Vector3(-60, 0, -120)], ["snow_wolf", Vector3(60, 0, 20)], ["snow_wolf", Vector3(-50, 0, 40)], ["snow_wolf", Vector3(-56, 0, 48)],
		["ice_troll", t + Vector3(-5, 0, -4)], ["ice_troll", t + Vector3(5, 0, -3)], ["ice_troll", t + Vector3(-4, 0, 6)],
		["ice_troll", t + Vector3(6, 0, 7)], ["ice_troll", t + Vector3(0, 0, -9)], ["frost_wraith", t + Vector3(0, 0, 2)], ["frost_wraith", t + Vector3(9, 0, 0)],
		["frost_yeti", h + Vector3(-4, 0, 3)], ["frost_yeti", h + Vector3(5, 0, -4)], ["frost_yeti", h + Vector3(0, 0, 8)],
		["frost_yeti", h + Vector3(-7, 0, -6)], ["frost_yeti", h + Vector3(8, 0, 5)], ["frost_wraith", h + Vector3(0, 0, -2)],
		["frost_wraith", c + Vector3(-8, 0, -12)], ["frost_wraith", c + Vector3(8, 0, -12)], ["frost_yeti", c + Vector3(0, 0, -16)],
		["snow_wolf", LAKE + Vector3(-20, 0, 10)], ["snow_wolf", LAKE + Vector3(-22, 0, 14)],
	]


func barrels() -> Array:
	return [TROLLS + Vector3(-9, 0, 2), TROLLS + Vector3(10, 0, -6), TROLLS + Vector3(2, 0, 10), HOLLOW + Vector3(10, 0, -2)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	_outpost(w, OUTPOST)
	Props.water(w, LAKE, 14.0, -0.6, Color(0.55, 0.7, 0.82), Color(0.85, 0.93, 0.98))
	Props.tent(w, LAKE + Vector3(22, 0, -12), 210, Color(0.35, 0.45, 0.35))
	Props.campfire(w, LAKE + Vector3(17, 0, -13))
	_troll_camp(w, TROLLS, rng)
	_hollow(w, HOLLOW, rng)
	_caves(w, CAVES, rng)
	Props.poi(w, "cairn", RIDGE + Vector3(9, 0, 9), 0.0)
	village.build(w)


func _outpost(w: Node3D, o: Vector3) -> void:
	Props.house(w, o + Vector3(-7, 0, -3), 90, Vector3(7, 4, 5), Color(0.5, 0.55, 0.65), Color(0.7, 0.68, 0.65))
	Props.house(w, o + Vector3(8, 0, -4), -90, Vector3(6, 4, 5), Color(0.5, 0.55, 0.65), Color(0.7, 0.68, 0.65))
	Props.palisade(w, o, 14.0, 200.0, 340.0)
	Props.campfire(w, o + Vector3(0, 0, 2))
	Props.torch(w, o + Vector3(-4, 0, 11))
	Props.torch(w, o + Vector3(4, 0, 11))
	for p in [Vector3(-3, 0, -8), Vector3(-1.8, 0, -8.5), Vector3(3, 0, -9)]:
		Props.crate(w, o + p, randf_range(0, 45))
	Props.barrel(w, o + Vector3(10, 0, 4))


func _troll_camp(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var bone := MeshKit.mat(Color(0.9, 0.88, 0.8))
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		Props.tent(w, o + Vector3(cos(a) * 11.0, 0, sin(a) * 11.0), -rad_to_deg(a) - 90, Color(0.75, 0.75, 0.78))
	Props.campfire(w, o)
	var n := Props.pivot(w, o)
	for i in 10:
		MeshKit.cyl(n, 0.06, 0.06, rng.randf_range(0.5, 1.0), Vector3(rng.randf_range(-7, 7), 0.07, rng.randf_range(-7, 7)), bone, Vector3(90, rng.randf_range(0, 180), 0), 6)
	MeshKit.static_box(n, Vector3(0.3, 4.0, 0.3), Vector3(-3, 2.0, -3), Props.dark_wood())
	MeshKit.sphere(n, 0.35, Vector3(-3, 4.2, -3), bone)


func _hollow(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rk := Props.rock_mat(Color(1.3, 1.32, 1.45))
	var n := Props.pivot(w, o)
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		var r := rng.randf_range(2.5, 4.5)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 13.0, -r * 0.3, sin(a) * 13.0), rk)


func _caves(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rk := Props.rock_mat(Color(1.2, 1.25, 1.4))
	var ice := MeshKit.mat(Color(0.55, 0.8, 1.0), 0.1, 0.0, 0.8)
	var n := Props.pivot(w, o)
	for p in [[Vector3(-14, -2, 6), 9.0], [Vector3(14, -2, 6), 9.0], [Vector3(0, -3, 16), 11.0], [Vector3(-22, -2, -4), 7.0], [Vector3(22, -2, -4), 7.0]]:
		MeshKit.static_sphere(n, p[1], p[0], rk)
	for i in 14:
		var a := rng.randf_range(-PI, 0.0)
		var d := rng.randf_range(6.0, 14.0)
		MeshKit.cyl(n, 0.0, rng.randf_range(0.4, 0.9), rng.randf_range(2.0, 5.0), Vector3(cos(a) * d, 1.2, sin(a) * d * 0.6), ice, Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-20, 20)), 6)
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 0.8, 1.0)
	l.light_energy = 2.5
	l.omni_range = 18.0
	l.position = Vector3(0, 3, -4)
	n.add_child(l)
