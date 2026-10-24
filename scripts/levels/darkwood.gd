extends RefCounted
## Location 2: Darkwood - twilight forest with a haunted graveyard, spiders and the undead.

const GRAVEYARD := Vector3(0, 0, 0)
const CHAPEL := Vector3(-124, 0, -110)
const HOLLOW := Vector3(124, 0, -104)
const RITUAL := Vector3(-124, 0, 116)
const SWAMP := Vector3(120, 0, 132)
var village: Village
var town: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 23, "hill_amp": 7.5,
		"player_start": Vector3(0, 0, -216), "player_yaw": PI,
		"sky": {"top_color": Color(0.05, 0.06, 0.15), "horizon_color": Color(0.32, 0.27, 0.42), "ground_color": Color(0.08, 0.08, 0.1),
			"sun_glow": Color(0.75, 0.82, 1.0), "cloud_color": Color(0.34, 0.33, 0.45), "cloud_shadow": Color(0.14, 0.14, 0.22),
			"cloud_cover": 0.62, "sun_size": 500.0},
		"sun_rot": Vector3(-38, 150, 0), "sun_color": Color(0.62, 0.7, 1.0), "sun_energy": 0.65, "ambient": 0.7, "exposure": 1.2,
		"fog_color": Color(0.22, 0.24, 0.34), "fog_density": 0.011, "color_saturation": 0.95,
		"grass_tint": Vector3(0.55, 0.62, 0.5), "grass_tint2": Vector3(0.45, 0.5, 0.48), "floor_tint": Vector3(0.62, 0.6, 0.55),
		"floor_amount": 0.95, "dirt_tint": Vector3(0.95, 0.82, 0.75), "rock_tint": Vector3(0.75, 0.75, 0.85),
		"stone_tint": Vector3(0.75, 0.75, 0.82), "field_tint": Vector3(0.7, 0.7, 0.6), "saturation": 0.9,
		"foliage": [Color(0.05, 0.08, 0.08), Color(0.15, 0.2, 0.17), Color(0.3, 0.3, 0.26)],
		"pine_foliage": [Color(0.03, 0.07, 0.06), Color(0.08, 0.15, 0.12), Color(0.2, 0.24, 0.2)],
		"bush_foliage": [Color(0.06, 0.1, 0.07), Color(0.14, 0.2, 0.13), Color(0.3, 0.32, 0.2)],
		"bark_tint": Color(0.6, 0.55, 0.6), "tree_style": "dead", "tree_count": 260, "tree_spacing": 6.0, "pine_ratio": 0.4,
		"rock_color": Color(0.8, 0.8, 0.9), "rock_count": 70,
		"grass_base": Color(0.07, 0.11, 0.06), "grass_tip": Color(0.22, 0.28, 0.17), "grass_per_chunk": 200,
		"ambience": "wind",
	}


func npcs() -> Array:
	return [
		{"id": "valen", "name": "Hunter Valen", "title": "Darkwood Hunter", "pos": Vector3(14, 0, -200), "yaw": 200, "model": "people/hoodie", "colors": {"Purple": Color(0.22, 0.3, 0.2), "LightBlue": Color(0.26, 0.22, 0.17), "White": Color(0.35, 0.3, 0.24)}},
		{"id": "mara", "name": "Old Mara", "title": "Herbalist", "pos": Vector3(-16, 0, -168), "yaw": 150, "model": "people/woman", "colors": {"White": Color(0.42, 0.36, 0.46), "Hair_Blond": Color(0.72, 0.72, 0.72), "Hair_Brown": Color(0.6, 0.6, 0.6), "Orange": Color(0.4, 0.3, 0.22)}},
		{"id": "edwin", "name": "Gravekeeper Edwin", "title": "Keeper of the Dead", "pos": Vector3(4, 0, -28), "yaw": 180, "model": "people/man1", "colors": {"Shirt": Color(0.2, 0.2, 0.22), "Shirt2": Color(0.12, 0.12, 0.13), "Pants": Color(0.1, 0.1, 0.11), "Hair": Color(0.6, 0.6, 0.6), "Hair2": Color(0.55, 0.55, 0.55)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": Vector3(-8, 0, -204), "yaw": 160, "model": "people/casual",
			"colors": People.vesper_colors(),
			"face": "res://assets/textures/vesper_face.png", "build": Vector3(1.22, 1.0, 1.18), "pitch": 1.25},
	]


func quests() -> Array:
	return [
		{"id": "dw_spiders", "giver": "valen", "title": "Spider Infestation", "type": "kill", "target": "spider", "count": 8, "label": "Darkwood Spiders slain", "xp": 400,
			"lines": {"offer": "dw_spiders_offer", "done": "dw_spiders_done"}},
		{"id": "dw_ghouls", "giver": "valen", "title": "Ghoul Hunt", "type": "kill", "target": "ghoul", "count": 6, "label": "Ghouls slain", "xp": 400, "requires": ["dw_spiders"],
			"lines": {"offer": "dw_ghouls_offer", "done": "dw_ghouls_done"}},
		{"id": "dw_dust", "giver": "mara", "title": "Grave Dust", "type": "gather", "item": "Grave Dust", "count": 6, "xp": 350,
			"spots": [Vector3(-8, 0, -14), Vector3(9, 0, -10), Vector3(-13, 0, 2), Vector3(12, 0, 4), Vector3(-6, 0, 7), Vector3(6, 0, -3), Vector3(15, 0, -16), Vector3(-17, 0, -6)],
			"lines": {"offer": "dw_dust_offer", "done": "dw_dust_done"}},
		{"id": "dw_charm", "giver": "mara", "to": "edwin", "title": "Mara's Charm", "type": "deliver", "item": "Warding Charm", "xp": 250, "requires": ["dw_dust"],
			"lines": {"offer": "dw_charm_offer", "done": "dw_charm_done"}},
		{"id": "dw_bones", "giver": "edwin", "title": "Bones of the Restless", "type": "collect", "target": "skeleton", "item": "Cursed Bone", "count": 8, "chance": 0.7, "xp": 400,
			"lines": {"offer": "dw_bones_offer", "done": "dw_bones_done"}},
		{"id": "dw_lord", "giver": "edwin", "title": "The Grave Lord", "type": "boss", "target": "grave_lord", "boss_pos": Vector3(0, 0, 10), "label": "Grave Lord slain", "xp": 800,
			"requires": ["dw_bones"], "lines": {"offer": "dw_lord_offer", "done": "dw_lord_done"}},
		{"id": "vesper_dw", "giver": "vesper", "title": "Signal Lost", "type": "gather", "item": "FPV Drone", "count": 1, "xp": 400,
			"spots": [CHAPEL + Vector3(2, 0, -3)], "lines": {"offer": "vesper_dw_offer", "done": "vesper_dw_done"}},
	]


func pois() -> Array:
	return [["obelisk", Vector3(-60, 0, -140), 0.0], ["cart", Vector3(60, 0, -160), 40.0], ["statue", Vector3(205, 0, -160), 270.0],
		["camp", Vector3(-184, 0, 24), 90.0], ["ruin", Vector3(40, 0, 184), 0.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	w.add_zone(Vector2(-28, -184), 8.0)
	var north := Vector2(0, -60)
	var south := Vector2(0, 60)
	w.add_path(Vector2(0, -224), north)
	w.add_path(north, Vector2(0, -24))
	w.add_path(south, Vector2(0, 24))
	w.add_path(north, Vector2(-60, -84))
	w.add_path(Vector2(-60, -84), Vector2(-100, -104))
	w.add_path(north, Vector2(60, -80))
	w.add_path(Vector2(60, -80), Vector2(100, -100))
	w.add_path(south, Vector2(-60, 90))
	w.add_path(Vector2(-60, 90), Vector2(-100, 110))
	w.add_path(south, Vector2(60, 100))
	w.add_path(Vector2(60, 100), Vector2(96, 124))
	w.add_path(Vector2(-44, 0), Vector2(-140, 10))
	w.add_zone(Vector2(0, 0), 30.0)
	w.add_zone(Vector2(CHAPEL.x, CHAPEL.z), 18.0)
	w.add_zone(Vector2(HOLLOW.x, HOLLOW.z), 18.0)
	w.add_zone(Vector2(RITUAL.x, RITUAL.z), 16.0)
	w.add_zone(Vector2(SWAMP.x, SWAMP.z), 14.0)
	w.add_zone(Vector2(0, -216), 8.0)
	w.add_lake(Vector2(SWAMP.x + 14, SWAMP.z + 8), 10.0, 1.8)
	w.add_lake(Vector2(SWAMP.x - 8, SWAMP.z + 16), 7.0, 1.5)
	w.paint_rect(Rect2(CHAPEL.x - 8, CHAPEL.z - 10, 16, 20), 1)
	w.paint_circle(Vector2(RITUAL.x, RITUAL.z), 9.0, 1)
	w.add_landmark("Old Graveyard", Vector2(0, 0), 22.0, Color(0.5, 0.5, 0.6))
	w.add_landmark("Ruined Chapel", Vector2(CHAPEL.x, CHAPEL.z), 12.0, Color(0.7, 0.65, 0.55))
	w.add_landmark("Spider Hollow", Vector2(HOLLOW.x, HOLLOW.z), 13.0, Color(0.85, 0.85, 0.85))
	w.add_landmark("Ritual Stones", Vector2(RITUAL.x, RITUAL.z), 11.0, Color(0.3, 0.9, 0.4))
	w.add_landmark("Black Swamp", Vector2(SWAMP.x, SWAMP.z), 13.0, Color(0.25, 0.35, 0.3))
	village = Village.plan(w, Vector3(-46, 0, -160), "hamlet", 5, 7, "Hollowmere", 21)
	# Ravenmoor, a walled market town
	town = Village.plan(w, Vector3(175, 0, 10), "city_market", 12, 14, "Ravenmoor", 55)
	w.add_path(town.gate_road_end(0), Vector2(60, -80), 4.0)
	w.plan_feature("crypt", Vector3(40, 0, 50), 10.0, "Crypt of the Grave Lord")
	w.plan_feature("ruined_castle", Vector3(-210, 0, 0), 16.0, "Blackthorn Ruins")
	w.plan_feature("watchtower", Vector3(30, 0, -170), 4.0)


func spawns() -> Array:
	var g := GRAVEYARD
	var c := CHAPEL
	var h := HOLLOW
	var r := RITUAL
	var s := SWAMP
	return [
		["skeleton", g + Vector3(-10, 0, -8)], ["skeleton", g + Vector3(10, 0, -6)], ["skeleton", g + Vector3(-12, 0, 6)],
		["skeleton", g + Vector3(12, 0, 8)], ["skeleton", g + Vector3(-4, 0, 12)], ["skeleton", g + Vector3(5, 0, -14)],
		["necromancer", g + Vector3(-6, 0, 0)], ["necromancer", g + Vector3(7, 0, 2)],
		["ghoul", c + Vector3(-4, 0, 3)], ["ghoul", c + Vector3(4, 0, -3)], ["ghoul", c + Vector3(-2, 0, -8)],
		["ghoul", c + Vector3(6, 0, 7)], ["necromancer", c + Vector3(0, 0, -2)],
		["spider", h + Vector3(-5, 0, -3)], ["spider", h + Vector3(4, 0, 5)], ["spider", h + Vector3(6, 0, -6)],
		["spider", h + Vector3(-6, 0, 6)], ["spider", h + Vector3(0, 0, -9)], ["spider", h + Vector3(9, 0, 2)],
		["necromancer", r + Vector3(-3, 0, 0)], ["necromancer", r + Vector3(3, 0, 1)],
		["skeleton", r + Vector3(0, 0, -8)], ["skeleton", r + Vector3(-7, 0, 5)], ["skeleton", r + Vector3(7, 0, 5)],
		["ghoul", s + Vector3(-4, 0, -4)], ["ghoul", s + Vector3(4, 0, -2)], ["ghoul", s + Vector3(0, 0, 6)],
		["ghoul", s + Vector3(-7, 0, 3)],
		["spider", Vector3(-70, 0, -40)], ["spider", Vector3(70, 0, 30)],
	]


func barrels() -> Array:
	return [Vector3(16, 0, 30), Vector3(-16, 0, 30), HOLLOW + Vector3(4, 0, -8), CHAPEL + Vector3(3, 0, 4),
		RITUAL + Vector3(5, 0, -4), SWAMP + Vector3(3, 0, -8)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	_graveyard(w, rng)
	_chapel(w, CHAPEL, rng)
	_hollow(w, HOLLOW, rng)
	_ritual(w, RITUAL)
	_swamp(w, SWAMP, rng)
	Props.torch(w, Vector3(-3, 0, -208), Color(0.5, 1.0, 0.5))
	Props.torch(w, Vector3(3, 0, -208), Color(0.5, 1.0, 0.5))
	# hunters' camp and Mara's cottage at the entrance
	Props.tent(w, Vector3(20, 0, -208), -30, Color(0.3, 0.32, 0.25))
	Props.campfire(w, Vector3(18, 0, -194))
	Props.house(w, Vector3(-32, 0, -188), 60, Vector3(5, 3.5, 4.5), Color(0.5, 0.45, 0.6), Color(0.55, 0.5, 0.45))
	Props.lantern(w, Vector3(-20, 0, -172))
	village.build(w)
	town.build(w)


func _graveyard(w: Node3D, rng: RandomNumberGenerator) -> void:
	var hw := 22.0
	Props.iron_fence(w, Vector3(-hw, 0, -hw), Vector3(-4, 0, -hw))
	Props.iron_fence(w, Vector3(4, 0, -hw), Vector3(hw, 0, -hw))
	Props.iron_fence(w, Vector3(hw, 0, -hw), Vector3(hw, 0, hw))
	Props.iron_fence(w, Vector3(-hw, 0, -hw), Vector3(-hw, 0, -4))
	Props.iron_fence(w, Vector3(-hw, 0, 4), Vector3(-hw, 0, hw))
	Props.iron_fence(w, Vector3(-hw, 0, hw), Vector3(-4, 0, hw))
	Props.iron_fence(w, Vector3(4, 0, hw), Vector3(hw, 0, hw))
	for row in range(-3, 3):
		for col in range(-4, 5):
			if abs(col) <= 1 or (row == 1 and abs(col) <= 2):
				continue
			if rng.randf() < 0.75:
				Props.tombstone(w, Vector3(col * 4.2 + rng.randf_range(-0.6, 0.6), 0, row * 5.0 - 2), rng.randf_range(-15, 15), rng)
	# crypt at the south side
	var st := Props.stone(Color(0.7, 0.7, 0.78), 0.4)
	var n := Props.pivot(w, Vector3(0, 0, 16))
	MeshKit.static_box(n, Vector3(8, 5, 6), Vector3(0, 2.5, 0), st)
	MeshKit.prism(n, Vector3(9, 2.5, 7), Vector3(0, 6.25, 0), st)
	MeshKit.box(n, Vector3(2.4, 3.2, 0.2), Vector3(0, 1.6, -3.05), MeshKit.unshaded(Color(0.02, 0.03, 0.02)))
	for x in [-3.0, 3.0]:
		MeshKit.cyl(n, 0.35, 0.4, 4.6, Vector3(x, 2.3, -3.4), st)
	MeshKit.box(n, Vector3(1.2, 0.5, 0.2), Vector3(0, 4.3, -3.15), MeshKit.mat(Color(0.3, 1.0, 0.4), 0.5, 0.0, 2.0))
	var l := OmniLight3D.new()
	l.light_color = Color(0.4, 1.0, 0.5)
	l.light_energy = 2.0
	l.omni_range = 10.0
	l.position = Vector3(0, 2.0, -4.5)
	n.add_child(l)
	Props.torch(w, Vector3(-5, 0, -23), Color(0.5, 1.0, 0.5))
	Props.torch(w, Vector3(5, 0, -23), Color(0.5, 1.0, 0.5))


func _chapel(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	Props.ruined_wall(w, o + Vector3(-7, 0, 0), 90, 18, 6.0, rng)
	Props.ruined_wall(w, o + Vector3(7, 0, 0), 90, 18, 6.0, rng)
	Props.ruined_wall(w, o + Vector3(0, 0, -9), 0, 14, 7.0, rng)
	Props.ruined_wall(w, o + Vector3(-5, 0, 9), 0, 4, 4.0, rng)
	Props.ruined_wall(w, o + Vector3(5, 0, 9), 0, 4, 4.0, rng)
	var st := Props.stone(Color(0.8, 0.78, 0.75), 0.4)
	var n := Props.pivot(w, o)
	MeshKit.static_box(n, Vector3(3, 1.1, 1.5), Vector3(0, 0.55, -6.5), st)
	for i in 4:
		MeshKit.static_box(n, Vector3(1.4, 0.4, 1.4), Vector3(rng.randf_range(-5, 5), 0.2, rng.randf_range(-6, 6)), st, Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 90), 0))
	Props.torch(w, o + Vector3(-2, 0, -7), Color(1.0, 0.55, 0.25))
	Props.torch(w, o + Vector3(2, 0, -7), Color(1.0, 0.55, 0.25))


func _hollow(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rock := Props.rock_mat(Color(0.8, 0.8, 0.9))
	var n := Props.pivot(w, o)
	for i in 8:
		var a := TAU * i / 8.0 + 0.3
		var r := rng.randf_range(2.0, 3.6)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 12.0, -r * 0.3, sin(a) * 12.0), rock)
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(3.0, 11.0)
		Props.web(w, o + Vector3(cos(a) * d, 0, sin(a) * d), rng.randf_range(0, 180), rng.randf_range(2.5, 4.5), rng.randf_range(1.5, 2.5))
	var egg := MeshKit.mat(Color(0.85, 0.85, 0.75), 0.6)
	for i in 12:
		MeshKit.sphere(n, rng.randf_range(0.25, 0.45), Vector3(rng.randf_range(-8, 8), 0.2, rng.randf_range(-8, 8)), egg, Vector3(1, 1.3, 1))


func _ritual(w: Node3D, o: Vector3) -> void:
	var st := Props.stone(Color(0.6, 0.62, 0.7), 0.35)
	var n := Props.pivot(w, o)
	for i in 7:
		var a := TAU * i / 7.0
		MeshKit.static_box(n, Vector3(1.2, 3.5, 0.7), Vector3(cos(a) * 8.0, 1.6, sin(a) * 8.0), st, Vector3(0, -rad_to_deg(a), 4))
	var glow := MeshKit.mat(Color(0.3, 1.0, 0.4), 0.5, 0.0, 2.5)
	for i in 16:
		var a := TAU * i / 16.0
		MeshKit.cyl(n, 0.1, 0.1, 0.05, Vector3(cos(a) * 4.0, 0.03, sin(a) * 4.0), glow, Vector3.ZERO, 6)
	MeshKit.static_box(n, Vector3(2.4, 1.0, 1.4), Vector3(0, 0.5, 0), st)
	var l := OmniLight3D.new()
	l.light_color = Color(0.35, 1.0, 0.45)
	l.light_energy = 2.5
	l.omni_range = 14.0
	l.position = Vector3(0, 2.0, 0)
	n.add_child(l)
	w.fire_lights.append(l)


func _swamp(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	Props.water(w, o + Vector3(14, 0, 8), 10.0, -0.5, Color(0.04, 0.08, 0.05), Color(0.12, 0.2, 0.1))
	Props.water(w, o + Vector3(-8, 0, 16), 7.0, -0.5, Color(0.04, 0.08, 0.05), Color(0.12, 0.2, 0.1))
	var n := Props.pivot(w, o)
	MeshKit.static_box(n, Vector3(4.5, 3.0, 4.0), Vector3(-2, 1.5, -6), Props.dark_wood())
	MeshKit.prism(n, Vector3(5.2, 2.0, 4.8), Vector3(-2, 4.0, -6), MeshKit.mat(Color(0.25, 0.22, 0.18)))
	MeshKit.box(n, Vector3(1.0, 1.8, 0.1), Vector3(-2, 0.9, -3.95), MeshKit.mat(Color(0.03, 0.03, 0.03)))
	var win := MeshKit.mat(Color(0.5, 1.0, 0.4), 0.5, 0.0, 2.0)
	MeshKit.box(n, Vector3(0.6, 0.5, 0.1), Vector3(-0.4, 1.8, -3.95), win)
	for i in 6:
		MeshKit.cyl(n, 0.15, 0.25, 3.0, Vector3(rng.randf_range(-10, 10), 1.0, rng.randf_range(-8, 10)), Props.dark_wood(), Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-20, 20)), 6)
