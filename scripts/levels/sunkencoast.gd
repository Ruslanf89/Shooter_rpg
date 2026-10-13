extends RefCounted
## Location 6: The Sunken Coast - sunny shore with crabs, drowned sailors, sea witches and pirates.

const SEA_Z := 116.0
const DOCKS := Vector3(-84, 0, 76)
const LIGHTHOUSE := Vector3(156, 0, 72)

var balcony_y := 19.0     # lighthouse balcony height, set in build()
const BEACH := Vector3(60, 0, 100)
const VILLAGE := Vector3(-70, 0, -80)
const SMUGGLERS := Vector3(124, 0, -96)
const COVE := Vector3(-215, 0, -95)
const BOSS := Vector3(10, 0, 104)
var village: Village
var port: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 83, "hill_amp": 6.0, "sea_z": SEA_Z,
		"player_start": Vector3(0, 0, -224), "player_yaw": PI,
		"sky": {"top_color": Color(0.2, 0.48, 0.9), "horizon_color": Color(0.78, 0.88, 0.97), "ground_color": Color(0.35, 0.45, 0.5),
			"sun_glow": Color(1.0, 0.92, 0.75), "cloud_color": Color(1.0, 1.0, 1.0), "cloud_shadow": Color(0.65, 0.72, 0.85), "cloud_cover": 0.45},
		"sun_rot": Vector3(-48, -20, 0), "sun_color": Color(1.0, 0.95, 0.85), "sun_energy": 1.5, "ambient": 1.05,
		"fog_color": Color(0.75, 0.85, 0.95), "fog_density": 0.003, "color_saturation": 1.15,
		"grass_tint": Vector3(1.1, 1.08, 0.7), "grass_tint2": Vector3(1.2, 1.15, 0.7), "floor_tint": Vector3(1.2, 1.1, 0.75),
		"dirt_tint": Vector3(2.1, 1.85, 1.3), "rock_tint": Vector3(1.2, 1.15, 1.05), "stone_tint": Vector3(1.15, 1.1, 1),
		"field_tint": Vector3(4.6, 4.0, 2.9), "field_saturation": 0.25, "saturation": 1.1,
		"foliage": [Color(0.12, 0.3, 0.08), Color(0.35, 0.6, 0.15), Color(0.75, 0.85, 0.3)],
		"pine_foliage": [Color(0.08, 0.2, 0.08), Color(0.2, 0.38, 0.12), Color(0.4, 0.55, 0.2)],
		"bark_tint": Color(1.1, 0.85, 0.6), "tree_style": "oak", "tree_count": 150, "tree_spacing": 8.0, "pine_ratio": 0.1,
		"grass_base": Color(0.28, 0.4, 0.1), "grass_tip": Color(0.7, 0.75, 0.3),
		"ambience": "forest",
	}


func npcs() -> Array:
	return [
		{"id": "gale", "name": "Old Gale", "title": "Fisherman", "pos": DOCKS + Vector3(4, 0, -6), "yaw": 200, "model": "people/farmer", "colors": {"LightBlue": Color(0.2, 0.28, 0.45), "Beige": Color(0.75, 0.72, 0.65)}},
		{"id": "nessa", "name": "Nessa", "title": "Lighthouse Keeper", "pos": LIGHTHOUSE + Vector3(-8, 0, -6), "yaw": 220, "model": "people/woman_dress", "colors": {"Dress": Color(0.24, 0.33, 0.52), "Hair": Color(0.35, 0.2, 0.1)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": Vector3(-8, 0, -206), "yaw": 160, "model": "people/casual",
			"colors": {"White": "print", "LightBlue": Color(0.06, 0.06, 0.07), "Red_Dark": Color(0.16, 0.16, 0.17), "Hair": Color(0.16, 0.1, 0.06), "Skin": Color(0.88, 0.68, 0.6)},
			"face": "res://assets/textures/vesper_face.png", "build": Vector3(1.22, 1.0, 1.18), "pitch": 1.25},
	]


func quests() -> Array:
	var pearls := []
	for i in 9:
		pearls.append(Vector3(-120 + i * 30, 0, SEA_Z - 6 + (i % 3) * 3))
	return [
		{"id": "sc_crabs", "giver": "gale", "title": "Crab Problems", "type": "kill", "target": "crab", "count": 8, "label": "Giant Crabs slain", "xp": 650,
			"lines": {"offer": "sc_crabs_offer", "done": "sc_crabs_done"}},
		{"id": "sc_drowned", "giver": "gale", "title": "Rest for the Drowned", "type": "kill", "target": "drowned", "count": 8, "label": "Drowned Sailors put to rest", "xp": 650,
			"requires": ["sc_crabs"], "lines": {"offer": "sc_drowned_offer", "done": "sc_drowned_done"}},
		{"id": "sc_bones", "giver": "gale", "title": "Captain Bones", "type": "boss", "target": "captain_bones", "boss_pos": BOSS, "label": "Captain Bones slain", "xp": 1500,
			"requires": ["sc_drowned", "sc_coins", "sc_lamp"], "lines": {"offer": "sc_bones_offer", "done": "sc_bones_done"}},
		{"id": "sc_pearls", "giver": "nessa", "title": "Pearls for the Lens", "type": "gather", "item": "Sea Pearl", "count": 6, "xp": 550, "spots": pearls,
			"lines": {"offer": "sc_pearls_offer", "done": "sc_pearls_done"}},
		{"id": "sc_coins", "giver": "nessa", "title": "Cursed Gold", "type": "collect", "target": "pirate", "item": "Cursed Doubloon", "count": 8, "chance": 0.75, "xp": 650,
			"lines": {"offer": "sc_coins_offer", "done": "sc_coins_done"}},
		{"id": "sc_lamp", "giver": "nessa", "to": "gale", "title": "Oil for the Night", "type": "deliver", "item": "Lamp Oil", "xp": 300,
			"requires": ["sc_pearls"], "lines": {"offer": "sc_lamp_offer", "done": "sc_lamp_done"}},
		{"id": "vesper_sc", "giver": "vesper", "title": "Lighthouse Rescue", "type": "gather", "item": "FPV Drone", "count": 1, "xp": 650,
			"spots": [Vector3(LIGHTHOUSE.x, balcony_y + 0.1, LIGHTHOUSE.z - 2.45)], "lines": {"offer": "vesper_sc_offer", "done": "vesper_sc_done"}},
	]


func pois() -> Array:
	return [["shipwreck", Vector3(-136, 0, 112), 30.0], ["arch", Vector3(184, 0, -24), 90.0], ["statue", Vector3(-120, 0, -164), 30.0],
		["camp", Vector3(36, 0, -124), 0.0], ["cart", Vector3(-176, 0, -44), 70.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	var cross := Vector2(0, -60)
	var shore := Vector2(0, 60)
	w.add_path(Vector2(0, -230), cross)
	w.add_path(cross, Vector2(-60, -76))
	w.add_path(cross, Vector2(100, -90))
	w.add_path(cross, shore)
	w.add_path(shore, Vector2(-76, 64))
	w.add_path(shore, Vector2(136, 64))
	for z in [[DOCKS, 12.0], [LIGHTHOUSE, 14.0], [VILLAGE, 18.0], [SMUGGLERS, 16.0], [COVE, 12.0]]:
		var zp: Vector3 = z[0]
		w.add_zone(Vector2(zp.x, zp.z), z[1])
	w.paint_rect(Rect2(-280, SEA_Z - 22, 560, 60), 2)   # sandy beach band
	w.add_landmark("Fishing Docks", Vector2(DOCKS.x, DOCKS.z), 10.0, Color(0.6, 0.45, 0.3))
	w.add_landmark("Lighthouse", Vector2(LIGHTHOUSE.x, LIGHTHOUSE.z), 10.0, Color(0.95, 0.95, 0.9))
	w.add_landmark("Crab Beach", Vector2(BEACH.x, BEACH.z), 12.0, Color(1.0, 0.6, 0.35))
	w.add_landmark("Drowned Village", Vector2(VILLAGE.x, VILLAGE.z), 14.0, Color(0.4, 0.7, 0.7))
	w.add_landmark("Smugglers' Camp", Vector2(SMUGGLERS.x, SMUGGLERS.z), 13.0, Color(0.7, 0.4, 0.3))
	w.add_landmark("Pirate Cove", Vector2(COVE.x, COVE.z), 10.0, Color(0.5, 0.35, 0.3))
	village = Village.plan(w, Vector3(-40, 0, 10), "fishing", 5, 8, "Saltmarsh", 61)
	# Saltmere, the walled port town
	port = Village.plan(w, Vector3(-172, 0, 52), "city_port", 12, 14, "Saltmere", 66)
	w.add_path(port.gate_road_end(0), Vector2(-60, 5), 4.0)
	w.plan_feature("fishing_hut", DOCKS + Vector3(-18, 0, 4), 5.0)
	w.plan_feature("fishing_hut", DOCKS + Vector3(18, 0, 6), 5.0)
	w.plan_feature("ruined_castle", Vector3(200, 0, -200), 16.0, "Smugglers' Keep")
	w.plan_feature("crypt", Vector3(-190, 0, -150), 10.0, "Sailors' Crypt")


func spawns() -> Array:
	var b := BEACH
	var v := VILLAGE
	var s := SMUGGLERS
	return [
		["crab", b + Vector3(-5, 0, -2)], ["crab", b + Vector3(5, 0, 2)], ["crab", b + Vector3(-9, 0, 4)], ["crab", b + Vector3(10, 0, -3)],
		["crab", b + Vector3(0, 0, 6)], ["crab", b + Vector3(15, 0, 4)], ["crab", Vector3(-30, 0, 100)], ["crab", Vector3(-44, 0, 104)], ["crab", Vector3(-16, 0, 96)],
		["drowned", v + Vector3(-5, 0, -4)], ["drowned", v + Vector3(5, 0, -3)], ["drowned", v + Vector3(-4, 0, 6)], ["drowned", v + Vector3(6, 0, 7)],
		["drowned", v + Vector3(0, 0, -9)], ["drowned", v + Vector3(-9, 0, 0)], ["sea_witch", v + Vector3(0, 0, 2)], ["sea_witch", v + Vector3(10, 0, -6)],
		["pirate", s + Vector3(-5, 0, -4)], ["pirate", s + Vector3(5, 0, -3)], ["pirate", s + Vector3(-4, 0, 6)], ["pirate", s + Vector3(6, 0, 6)],
		["pirate", s + Vector3(0, 0, -9)], ["pirate", s + Vector3(-9, 0, 1)],
		["pirate", COVE + Vector3(4, 0, -3)], ["pirate", COVE + Vector3(-3, 0, 4)], ["sea_witch", COVE + Vector3(0, 0, 0)],
		["drowned", Vector3(-40, 0, 60)], ["drowned", Vector3(50, 0, 50)],
	]


func barrels() -> Array:
	return [SMUGGLERS + Vector3(9, 0, -5), SMUGGLERS + Vector3(-8, 0, 8), SMUGGLERS + Vector3(2, 0, 10), COVE + Vector3(6, 0, 4), DOCKS + Vector3(-7, 0, -6)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	Props.sea(w, Vector3(0, 0, SEA_Z + 140), Vector2(640, 300), -0.55)
	_docks(w, DOCKS)
	_lighthouse(w, LIGHTHOUSE)
	_village(w, VILLAGE, rng)
	_smugglers(w, SMUGGLERS, rng)
	var rk := Props.rock_mat(Color(1.15, 1.1, 1.0))
	var n := Props.pivot(w, COVE)
	for i in 6:
		var a := TAU * i / 6.0
		var r := rng.randf_range(2.5, 4.5)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 12.0, -r * 0.3, sin(a) * 12.0), rk)
	Props.campfire(w, COVE + Vector3(2, 0, 2))
	for i in 12:
		var p := Vector3(rng.randf_range(-250, 250), 0, rng.randf_range(SEA_Z - 15, SEA_Z + 2))
		MeshKit.static_sphere(Props.pivot(w, p), rng.randf_range(0.8, 2.0), Vector3(0, -0.3, 0), rk)
	village.build(w)
	port.build(w)


func _docks(w: Node3D, o: Vector3) -> void:
	var n := Props.pivot(w, o)
	n.position.y = 0.0
	for i in 2:
		var x := -2.0 + i * 4.0
		MeshKit.static_box(n, Vector3(2.2, 0.25, 26), Vector3(x, 0.6, 18), Props.wood())
		for z in range(6, 32, 4):
			MeshKit.cyl(n, 0.15, 0.15, 4.0, Vector3(x - 1.0, -1.2, z), Props.dark_wood())
			MeshKit.cyl(n, 0.15, 0.15, 4.0, Vector3(x + 1.0, -1.2, z), Props.dark_wood())
	Props.house(w, o + Vector3(-6, 0, -4), 90, Vector3(6, 3.6, 5), Color(0.45, 0.55, 0.75), Color(0.85, 0.82, 0.75))
	for p in [Vector3(4, 0, -2), Vector3(5, 0, -0.5)]:
		Props.barrel(w, o + p)
	Props.crate(w, o + Vector3(-1, 0, 1), 20)
	# small boat
	var boat := Props.pivot(w, o + Vector3(6, 0, 20), 10)
	boat.position.y = -0.4
	MeshKit.box(boat, Vector3(1.6, 0.6, 4.5), Vector3(0, 0.2, 0), Props.dark_wood())
	MeshKit.prism(boat, Vector3(1.6, 1.2, 0.6), Vector3(0, 0.2, 2.5), Props.dark_wood(), Vector3(90, 0, 0))


func _lighthouse(w: Node3D, o: Vector3) -> void:
	var n := Props.pivot(w, o)
	var red := MeshKit.mat(Color(0.75, 0.12, 0.1))
	balcony_y = Buildings.lighthouse(w, n)
	w.building_areas.append([Vector2(o.x, o.z), 4.5])
	MeshKit.cyl(n, 1.5, 1.5, 2.2, Vector3(0, 23.4, 0), MeshKit.glow(Color(1.0, 0.9, 0.6, 0.5)), Vector3.ZERO, 12)
	MeshKit.cyl(n, 0.0, 1.9, 1.6, Vector3(0, 25.3, 0), red, Vector3.ZERO, 12)
	var beam := Node3D.new()
	beam.position.y = 23.4
	n.add_child(beam)
	var sl := SpotLight3D.new()
	sl.light_color = Color(1.0, 0.92, 0.7)
	sl.light_energy = 6.0
	sl.spot_range = 80.0
	sl.spot_angle = 12.0
	beam.add_child(sl)
	var bm := CylinderMesh.new()
	bm.top_radius = 0.4
	bm.bottom_radius = 4.0
	bm.height = 40.0
	MeshKit.inst(beam, bm, Vector3(0, 0, -20), MeshKit.glow(Color(1.0, 0.9, 0.6, 0.08)), Vector3(90, 0, 0))
	w.spinners.append([beam, Vector3(0, 0.6, 0)])
	Props.house(w, o + Vector3(-9, 0, 3), 180, Vector3(5, 3.4, 4.5), Color(0.75, 0.3, 0.25), Color(0.92, 0.9, 0.85))


func _village(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var p := o + Vector3(cos(a) * 11.0, 0, sin(a) * 11.0)
		if i % 2 == 0:
			Props.house(w, p, -rad_to_deg(a) + 90, Vector3(5.5, 3.6, 4.5), Color(0.4, 0.5, 0.45), Color(0.6, 0.65, 0.6))
		else:
			Props.ruined_wall(w, p, -rad_to_deg(a), 8, 3.0, rng)
	Props.well(w, o)
	var weed := MeshKit.mat(Color(0.2, 0.4, 0.3))
	var n := Props.pivot(w, o)
	for i in 14:
		MeshKit.sphere(n, rng.randf_range(0.3, 0.6), Vector3(rng.randf_range(-12, 12), 0.1, rng.randf_range(-12, 12)), weed, Vector3(1, 0.3, 1))


func _smugglers(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		Props.tent(w, o + Vector3(cos(a) * 11.0, 0, sin(a) * 11.0), -rad_to_deg(a) - 90, Color(0.3, 0.25, 0.22))
	Props.campfire(w, o)
	for i in 6:
		Props.crate(w, o + Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)), rng.randf_range(0, 90))
	Props.palisade(w, o, 15.0, 60.0, 230.0)
