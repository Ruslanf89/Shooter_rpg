extends RefCounted
## Location 1: Northvale - sunny valley with the abbey, vineyard, kobold mine and bandits.

const ABBEY := Vector3(0, 0, -124)
const VINEYARD := Vector3(156, 0, -24)
const MINE := Vector3(-180, 0, 20)
const CAMP := Vector3(124, 0, 156)
const DEN := Vector3(-110, 0, 164)
const TOWER := Vector3(176, 0, -150)
const FARM := Vector3(-140, 0, -144)
const LAKE := Vector3(64, 0, -56)
const S := 1.3   # abbey scale
const VESPER := Vector3(-18, 0, -82)
const DRONE_TREE := Vector3(-38, 0, -68)
const TREE_PLATFORM := 11.0

var _drone_spot := DRONE_TREE + Vector3(2, TREE_PLATFORM, 0)   # set in build()
var village: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 11, "hill_amp": 6.0,
		"player_start": ABBEY + Vector3(0, 0, 23.5), "player_yaw": PI, "tree_spacing": 7.5,
		"sky": {"top_color": Color(0.28, 0.5, 0.88), "horizon_color": Color(0.8, 0.86, 0.95), "ground_color": Color(0.35, 0.38, 0.3),
			"sun_glow": Color(1.0, 0.86, 0.62), "cloud_color": Color(1.0, 0.98, 0.94), "cloud_shadow": Color(0.62, 0.68, 0.82), "cloud_cover": 0.55},
		"sun_rot": Vector3(-34, -40, 0), "sun_color": Color(1.0, 0.88, 0.7), "sun_energy": 1.4, "ambient": 1.0,
		"fog_color": Color(0.74, 0.82, 0.92), "fog_density": 0.0035, "color_saturation": 1.18,
		"grass_tint": Vector3(1.05, 1.0, 0.55), "grass_tint2": Vector3(0.92, 1.0, 0.5), "floor_tint": Vector3(1, 0.92, 0.58),
		"dirt_tint": Vector3(1.45, 1.0, 0.72), "rock_tint": Vector3(1.2, 1.1, 0.95), "stone_tint": Vector3(1.1, 1.04, 0.92),
		"field_tint": Vector3(1.5, 1.15, 0.7), "saturation": 1.1,
		"foliage": [Color(0.2, 0.3, 0.06), Color(0.5, 0.6, 0.14), Color(0.88, 0.78, 0.28)],
		"pine_foliage": [Color(0.08, 0.18, 0.07), Color(0.18, 0.33, 0.11), Color(0.38, 0.48, 0.18)],
		"bark_tint": Color(1.15, 0.75, 0.42), "tree_style": "oak", "tree_count": 230, "pine_ratio": 0.15,
		"grass_base": Color(0.24, 0.36, 0.08), "grass_tip": Color(0.64, 0.66, 0.22),
		"ambience": "forest",
	}


func npcs() -> Array:
	return [
		{"id": "aldric", "name": "Brother Aldric", "title": "Abbey Priest", "pos": ABBEY + Vector3(6.5, 0, 21), "yaw": 200, "model": "people/man2",
			"colors": {"Shirt": Color(0.32, 0.24, 0.17), "Pants": Color(0.26, 0.2, 0.14), "Hair": Color(0.55, 0.52, 0.5)}},
		{"id": "maybell", "name": "Farmer Maybell", "title": "Stonefield Farm", "pos": FARM + Vector3(2, 0, 3), "yaw": 160, "model": "people/woman_casual",
			"colors": {"Shirt": Color(0.36, 0.46, 0.33), "Pants": Color(0.3, 0.24, 0.18), "Hair": Color(0.5, 0.32, 0.18), "outfit": "apron"}},
		{"id": "brannock", "name": "Sergeant Brannock", "title": "Northvale Guard", "pos": Vector3(8, 0, 43), "yaw": 200, "model": "people/adventurer",
			"colors": {"LightGreen": Color(0.4, 0.45, 0.55), "Green": Color(0.22, 0.27, 0.38)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": VESPER, "yaw": 120, "model": "people/casual",
			"colors": People.vesper_colors(),
			"face": "res://assets/textures/vesper_face.png", "build": Vector3(1.22, 1.0, 1.18), "pitch": 1.25},
	]


func quests() -> Array:
	return [
		{"id": "nv_wolves", "giver": "aldric", "title": "Wolves at the Door", "type": "kill", "target": "wolf", "count": 6, "label": "Timber Wolves slain", "xp": 300,
			"lines": {"offer": "nv_wolves_offer", "done": "nv_wolves_done"}},
		{"id": "nv_candles", "giver": "aldric", "title": "Candles in the Dark", "type": "collect", "target": ["kobold", "geomancer"], "item": "Kobold Candle", "count": 6, "chance": 0.65, "xp": 350,
			"lines": {"offer": "nv_candles_offer", "done": "nv_candles_done"}},
		{"id": "nv_grain", "giver": "maybell", "title": "The Lost Harvest", "type": "gather", "item": "Sack of Grain", "count": 5, "xp": 300,
			"spots": [FARM + Vector3(-8, 0, 7), FARM + Vector3(12, 0, 12), Vector3(-40, 0, -40), Vector3(-22, 0, -56), VINEYARD + Vector3(-19, 0, 15), Vector3(25, 0, 42), Vector3(-50, 0, 30)],
			"lines": {"offer": "nv_grain_offer", "done": "nv_grain_done"}},
		{"id": "nv_letter", "giver": "maybell", "to": "aldric", "title": "A Letter for the Abbey", "type": "deliver", "item": "Sealed Letter", "xp": 200, "requires": ["nv_grain"],
			"lines": {"offer": "nv_letter_offer", "done": "nv_letter_done"}},
		{"id": "nv_bandana", "giver": "brannock", "title": "The Red Bandanas", "type": "collect", "target": "bandit", "item": "Red Bandana", "count": 6, "chance": 0.7, "xp": 350,
			"lines": {"offer": "nv_bandana_offer", "done": "nv_bandana_done"}},
		{"id": "nv_captain", "giver": "brannock", "title": "Head of the Snake", "type": "boss", "target": "captain", "boss_pos": CAMP + Vector3(0, 0, 3), "label": "Bandit Captain slain", "xp": 600,
			"requires": ["nv_bandana"], "lines": {"offer": "nv_captain_offer", "done": "nv_captain_done"}},
		{"id": "vesper_drone", "giver": "vesper", "title": "Drone in the Treetops", "type": "gather", "item": "FPV Drone", "count": 1, "xp": 300,
			"spots": [_drone_spot], "lines": {"offer": "vesper_drone_offer", "done": "vesper_drone_done"}},
		{"id": "vesper_battery", "giver": "vesper", "title": "Fresh Batteries", "type": "collect", "target": "bandit", "item": "Drone Battery", "count": 4, "chance": 0.6, "xp": 350,
			"requires": ["vesper_drone"], "lines": {"offer": "vesper_battery_offer", "done": "vesper_battery_done"}},
	]


func pois() -> Array:
	return [["statue", Vector3(-56, 0, -20), 30.0], ["arch", Vector3(190, 0, 50), 90.0], ["camp", Vector3(-176, 0, -64), 0.0],
		["ruin", Vector3(60, 0, 180), 15.0], ["cart", Vector3(-60, 0, 84), 60.0], ["obelisk", Vector3(215, 0, 215), 20.0],
		["camp", Vector3(200, 0, 60), 200.0], ["ruin", Vector3(-215, 0, -215), 40.0], ["statue", Vector3(110, 0, -215), 160.0], ["cart", Vector3(-160, 0, 110), 120.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	var gate := Vector2(0, -60)
	var cross := Vector2(0, 30)
	var e1 := Vector2(70, 28)
	var vine := Vector2(124, -24)
	var w1 := Vector2(-70, 32)
	var mine := Vector2(-144, 20)
	var s1 := Vector2(0, 96)
	var j := Vector2(0, -24)
	w.add_path(gate, j)
	w.add_path(j, cross)
	w.add_path(cross, e1)
	w.add_path(e1, vine)
	w.add_path(vine, Vector2(164, -128))
	w.add_path(cross, w1)
	w.add_path(w1, mine)
	w.add_path(cross, s1)
	w.add_path(s1, Vector2(92, 144))
	w.add_path(s1, Vector2(-84, 152))
	w.add_path(j, Vector2(-60, -70))
	w.add_path(Vector2(-60, -70), Vector2(-116, -128))
	for z in [[Vector2(0, -100), 38.0], [Vector2(VINEYARD.x, VINEYARD.z), 22.0], [Vector2(MINE.x, MINE.z), 24.0],
			[Vector2(CAMP.x, CAMP.z), 20.0], [Vector2(DEN.x, DEN.z), 14.0], [Vector2(TOWER.x, TOWER.z), 14.0],
			[Vector2(FARM.x, FARM.z), 18.0], [cross, 8.0]]:
		w.add_zone(z[0], z[1])
	w.add_zone(Vector2(DRONE_TREE.x, DRONE_TREE.z), 9.0)
	w.add_zone(Vector2(ABBEY.x, ABBEY.z - 18.0), 31.0)   # the abbey church runs back behind the courtyard
	w.add_zone(Vector2(MINE.x - 34, MINE.z), 16.0)   # the cave chamber under the hill
	w.paint_circle(Vector2(MINE.x - 34, MINE.z), 11.5, 0)
	w.paint_rect(Rect2(MINE.x - 26, MINE.z - 3, 24, 6), 0)
	w.add_landmark("Old Oak", Vector2(DRONE_TREE.x, DRONE_TREE.z), 6.0, Color(0.35, 0.55, 0.25))
	w.add_lake(Vector2(LAKE.x, LAKE.z), 13.0, 2.8)
	village = Village.plan(w, Vector3(0, 0, 38), "town", 6, 9, "Ashford", 11)
	w.paint_rect(Rect2(ABBEY.x - 21.5, ABBEY.z + 7.8, 43, 23.4), 1)
	w.paint_rect(Rect2(FARM.x - 12, FARM.z - 4, 10, 14), 2)
	w.add_landmark("Northvale Abbey", Vector2(ABBEY.x, ABBEY.z + 8), 16.0, Color(0.85, 0.82, 0.7))
	w.add_landmark("Vineyard", Vector2(VINEYARD.x, VINEYARD.z), 15.0, Color(0.55, 0.3, 0.6))
	w.add_landmark("Kobold Mine", Vector2(MINE.x + 2, MINE.z), 13.0, Color(0.55, 0.45, 0.3))
	w.add_landmark("Bandit Camp", Vector2(CAMP.x, CAMP.z), 14.0, Color(0.75, 0.25, 0.2))
	w.add_landmark("Wolf Den", Vector2(DEN.x, DEN.z), 9.0, Color(0.5, 0.5, 0.5))
	w.add_landmark("Old Tower", Vector2(TOWER.x, TOWER.z), 9.0, Color(0.6, 0.5, 0.7))
	w.add_landmark("Stonefield Farm", Vector2(FARM.x, FARM.z), 11.0, Color(0.8, 0.65, 0.35))
	w.add_landmark("Mirror Lake", Vector2(LAKE.x, LAKE.z), 13.0, Color(0.3, 0.5, 0.8))
	w.plan_feature("ruined_castle", Vector3(200, 0, 150), 16.0, "Ruined Keep")
	w.plan_feature("crypt", Vector3(-60, 0, -180), 10.0, "Old Crypt")
	w.plan_feature("sawmill", Vector3(-100, 0, 60), 7.0)


func spawns() -> Array:
	var m := MINE
	var d := DEN
	var c := CAMP
	var v := VINEYARD
	var t := TOWER
	var f := FARM
	return [
		["kobold", m + Vector3(5, 0, -5)], ["kobold", m + Vector3(8, 0, 4)], ["kobold", m + Vector3(12, 0, -2)],
		["geomancer", m + Vector3(10, 0, -9)],
		# inside the cave (the tunnel runs to x -24, the chamber is around x -34)
		["kobold", m + Vector3(-14, 0, 0.8)], ["kobold", m + Vector3(-31, 0, 5)], ["kobold", m + Vector3(-37, 0, -4)],
		["geomancer", m + Vector3(-39, 0, 2)],
		["wolf", d + Vector3(3, 0, 2)], ["wolf", d + Vector3(-4, 0, -3)], ["wolf", d + Vector3(1, 0, -6)],
		["wolf", d + Vector3(6, 0, -4)], ["wolf", d + Vector3(-2, 0, 5)],
		["wolf", Vector3(-60, 0, -10)], ["wolf", Vector3(50, 0, 70)], ["wolf", Vector3(-80, 0, 90)],
		["bandit", c + Vector3(-3, 0, -2)], ["bandit", c + Vector3(3, 0, 3)], ["bandit", c + Vector3(-4, 0, 4)],
		["bandit", c + Vector3(5, 0, -3)], ["cultist", c + Vector3(0, 0, -9)], ["cultist", c + Vector3(-1, 0, 10)],
		["bandit", c + Vector3(-3, 0, 6)],
		["wolf", Vector3(-160, 0, -30)], ["wolf", Vector3(-156, 0, -26)], ["wolf", Vector3(40, 0, 200)], ["wolf", Vector3(44, 0, 204)],
		["wolf", Vector3(205, 0, 95)], ["wolf", Vector3(200, 0, 100)],
		["bandit", Vector3(196, 0, 56)], ["bandit", Vector3(204, 0, 64)], ["bandit", Vector3(-164, 0, 114)], ["bandit", Vector3(-156, 0, 106)],
		["bandit", v + Vector3(-12, 0, -8)], ["bandit", v + Vector3(0, 0, 9.5)],
		["cultist", v + Vector3(-8, 0, 0)], ["cultist", v + Vector3(4, 0, -9.5)],
		["cultist", t + Vector3(4, 0, 4)], ["cultist", t + Vector3(-5, 0, 2)], ["cultist", t + Vector3(0, 0, -6)],
		["bandit", f + Vector3(5, 0, 4)], ["bandit", f + Vector3(-6, 0, 6)], ["bandit", f + Vector3(4, 0, -6)],
	]


func barrels() -> Array:
	return [MINE + Vector3(8, 0, -7), MINE + Vector3(10, 0, 10), CAMP + Vector3(-6, 0, -11), CAMP + Vector3(5, 0, 10),
		CAMP + Vector3(-11, 0, 3), VINEYARD + Vector3(-13, 0, -10), TOWER + Vector3(5, 0, -4), FARM + Vector3(1, 0, 7)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	_abbey(w, ABBEY)
	_vineyard(w, VINEYARD, rng)
	_mine(w, MINE, rng)
	_camp(w, CAMP, rng)
	_den(w, DEN, rng)
	_tower(w, TOWER, rng)
	_farm(w, FARM)
	var top := Props.climb_tree(w, DRONE_TREE, TREE_PLATFORM, 125.0)
	var out := Vector2(top.x - DRONE_TREE.x, top.z - DRONE_TREE.z).normalized() * 0.7
	_drone_spot = Vector3(top.x + out.x, TREE_PLATFORM + 0.05, top.z + out.y)
	Props.water(w, LAKE, 13.0, -0.7, Color(0.08, 0.25, 0.32), Color(0.3, 0.55, 0.55))
	# fishing dock
	var dock := Props.pivot(w, LAKE + Vector3(-12, 0, 6), 60)
	MeshKit.static_box(dock, Vector3(2.0, 0.2, 7), Vector3(0, 0.1, 3), Props.wood())
	for z in [1.0, 3.5, 6.0]:
		MeshKit.cyl(dock, 0.12, 0.12, 2.0, Vector3(0.9, -0.6, z), Props.dark_wood())
		MeshKit.cyl(dock, 0.12, 0.12, 2.0, Vector3(-0.9, -0.6, z), Props.dark_wood())
	village.build(w)


func _abbey(w: Node3D, o: Vector3) -> void:
	var stone := Props.stone(Color(1.12, 1.06, 0.94), 0.28)
	var stone_dark := Props.stone(Color(0.88, 0.84, 0.78), 0.28)
	var roof := Props.roof(Color(0.5, 0.62, 1.35))
	var gold := MeshKit.mat(Color(0.95, 0.75, 0.25), 0.4, 0.6)
	var dark := MeshKit.mat(Color(0.06, 0.06, 0.08))
	var n := Props.pivot(w, o)

	# the abbey church: its west front faces the courtyard, the rest runs back behind it
	GothicChurch.place(w, o + Vector3(0, 0, 6.0 * S))
	w.building_areas.append([Vector2(o.x, o.z), 13.0])

	# square bell tower (front-left)
	MeshKit.static_box(n, Vector3(5, 18, 5), Vector3(-11.5, 9, 3), stone)
	MeshKit.box(n, Vector3(5.4, 0.6, 5.4), Vector3(-11.5, 13.0, 3), stone_dark)
	MeshKit.box(n, Vector3(5.4, 0.6, 5.4), Vector3(-11.5, 18.0, 3), stone_dark)
	MeshKit.box(n, Vector3(1.8, 2.6, 0.2), Vector3(-11.5, 15.5, 5.55), dark)
	MeshKit.cyl(n, 0.6, 0.9, 1.0, Vector3(-11.5, 15.4, 5.2), gold, Vector3.ZERO, 10)
	MeshKit.cyl(n, 0.0, 4.0, 7.0, Vector3(-11.5, 21.8, 3), roof, Vector3(0, 45, 0), 4)
	MeshKit.cyl(n, 0.05, 0.05, 1.5, Vector3(-11.5, 26.0, 3), gold)

	# round crenellated keep (back-right)
	var keep := Vector3(13, 0, -5)
	var cs := CylinderShape3D.new()
	cs.radius = 3.6
	cs.height = 17.0
	var kb := StaticBody3D.new()
	kb.position = keep + Vector3(0, 8.5, 0)
	var kcs := CollisionShape3D.new()
	kcs.shape = cs
	kb.add_child(kcs)
	n.add_child(kb)
	MeshKit.cyl(n, 3.4, 3.7, 17.0, keep + Vector3(0, 8.5, 0), stone, Vector3.ZERO, 20)
	MeshKit.cyl(n, 4.1, 3.6, 1.2, keep + Vector3(0, 17.4, 0), stone_dark, Vector3.ZERO, 20)
	for i in 12:
		var a := TAU * i / 12.0
		MeshKit.box(n, Vector3(1.0, 1.2, 0.8), keep + Vector3(cos(a) * 3.8, 18.6, sin(a) * 3.8), stone, Vector3(0, -rad_to_deg(a), 0))
	for h in [5.0, 9.5, 14.0]:
		MeshKit.box(n, Vector3(0.6, 1.4, 0.3), keep + Vector3(0, h, 3.65), dark)

	# side wing
	MeshKit.static_box(n, Vector3(8, 6, 8), Vector3(-1.0 - 13, 3, -2), stone)
	MeshKit.prism(n, Vector3(9, 3.5, 8.8), Vector3(-14, 7.75, -2), roof)

	# courtyard railings with an iron gate, and the fountain
	var cx := 17.0 * S
	var front := o.z + 24.0 * S
	var back := o.z + 6.0 * S
	for s in [-1.0, 1.0]:
		IronFence.run(w, Vector3(o.x + s * cx, 0, back), Vector3(o.x + s * cx, 0, front), true, false)
		IronFence.run(w, Vector3(o.x + s * cx, 0, front), Vector3(o.x + s * 2.95, 0, front), true, false)
	IronFence.gate(w, Vector3(o.x, 0, front), 0.0, 4.4)
	_churchyard(w, o + Vector3(0, 0, 6.0 * S))
	Props.lantern(w, o + Vector3(-4.8, 0, 25.6) * S)
	Props.lantern(w, o + Vector3(4.8, 0, 25.6) * S)
	MeshKit.static_cyl(n, 2.6, 0.9, Vector3(0, 0.45, 15), stone_dark, 16)
	MeshKit.cyl(n, 2.3, 2.3, 0.1, Vector3(0, 0.86, 15), MeshKit.mat(Color(0.25, 0.5, 0.75), 0.1, 0.2), Vector3.ZERO, 16)
	MeshKit.cyl(n, 0.3, 0.35, 2.2, Vector3(0, 1.6, 15), stone)
	MeshKit.cyl(n, 0.9, 0.4, 0.4, Vector3(0, 2.8, 15), stone, Vector3.ZERO, 12)
	MeshKit.sphere(n, 0.25, Vector3(0, 3.2, 15), gold)
	for p in [Vector3(-15, 0, 9), Vector3(-15, 0, 10.2), Vector3(-13.8, 0, 9.4)]:
		Props.crate(w, o + p * S, randf_range(0, 40))
	Props.barrel(w, o + Vector3(15, 0, 8.5) * S)
	Props.barrel(w, o + Vector3(15.2, 0, 10) * S)
	Props.hay_bale(w, o + Vector3(14.5, 0, 19) * S)
	n.scale = Vector3.ONE * S


## A small fenced churchyard beside the church (c: the church's west front, church-local metres):
## rows of headstones, crosses and grave slabs, a chest tomb, a bench and a gate to the east.
func _churchyard(w: Node3D, c: Vector3) -> void:
	var x0 := 12.2
	var x1 := 24.6
	var z0 := -20.2
	var z1 := -28.8
	var gz := (z0 + z1) * 0.5
	var g := 1.655        # half the gateway, piers included
	IronFence.run(w, c + Vector3(x0, 0, z0), c + Vector3(x1, 0, z0))
	IronFence.run(w, c + Vector3(x1, 0, z0), c + Vector3(x1, 0, gz + g), false, false)
	IronFence.run(w, c + Vector3(x1, 0, gz - g), c + Vector3(x1, 0, z1), false, true)
	IronFence.run(w, c + Vector3(x1, 0, z1), c + Vector3(x0, 0, z1), false, true)
	IronFence.run(w, c + Vector3(x0, 0, z1), c + Vector3(x0, 0, z0), false, false)
	IronFence.gate(w, c + Vector3(x1, 0, gz), 90.0, 1.8, 2.0)
	var n := Props.pivot(w, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var stones := [Props.stone(Color(0.78, 0.78, 0.76), 0.6), Props.stone(Color(0.62, 0.64, 0.58), 0.6), Props.rock_mat(Color(0.9, 0.92, 0.85))]
	var earth := MeshKit.mat(Color(0.26, 0.3, 0.14), 1.0)
	for x in [14.0, 16.5, 19.0, 21.5]:
		for z in [-21.7, -23.9, -26.1]:
			if rng.randf() < 0.12:
				continue
			var p := Vector3(x + rng.randf_range(-0.3, 0.3), 0, z + rng.randf_range(-0.2, 0.2))
			var m: Material = stones[rng.randi() % stones.size()]
			var tilt := Vector3(rng.randf_range(-6, 6), rng.randf_range(-8, 8), rng.randf_range(-5, 5))
			var kind := rng.randi() % 4
			# a low grave mound in front of the stone (the grave runs east, towards -z)
			MeshKit.box(n, Vector3(0.8, 0.12, 1.7), p + Vector3(0, 0.06, -0.95), earth)
			match kind:
				0, 1:   # headstone with a rounded top
					var hs := _holder(n, p, tilt)
					MeshKit.static_box(hs, Vector3(0.62, 0.75, 0.13), Vector3(0, 0.37, 0), m)
					MeshKit.cyl(hs, 0.31, 0.31, 0.13, Vector3(0, 0.75, 0), m, Vector3(90, 0, 0), 14)
				2:      # stone cross
					var cr := _holder(n, p, tilt)
					MeshKit.static_box(cr, Vector3(0.4, 0.2, 0.3), Vector3(0, 0.1, 0), m)
					MeshKit.box(cr, Vector3(0.14, 1.2, 0.12), Vector3(0, 0.8, 0), m)
					MeshKit.box(cr, Vector3(0.6, 0.13, 0.12), Vector3(0, 1.1, 0), m)
				_:      # a flat ledger slab with a small headstone
					MeshKit.static_box(n, Vector3(0.9, 0.18, 1.9), p + Vector3(0, 0.09, -0.95), m)
					MeshKit.box(n, Vector3(0.5, 0.45, 0.1), p + Vector3(0, 0.4, 0.05), m)
	# a chest tomb and a bench by the gate
	var tomb: Material = stones[0]
	MeshKit.static_box(n, Vector3(1.1, 0.8, 2.1), Vector3(22.8, 0.4, -27.6), tomb)
	MeshKit.box(n, Vector3(1.25, 0.12, 2.25), Vector3(22.8, 0.86, -27.6), stones[1])
	MeshKit.static_box(n, Vector3(1.6, 0.08, 0.42), Vector3(23.6, 0.45, -21.2), Props.wood())
	for e in [-0.65, 0.65]:
		MeshKit.box(n, Vector3(0.1, 0.45, 0.4), Vector3(23.6 + e, 0.22, -21.2), stones[1])

func _holder(n: Node3D, p: Vector3, rot_deg: Vector3) -> Node3D:
	var h := Node3D.new()
	h.position = p
	h.rotation_degrees = rot_deg
	n.add_child(h)
	return h


func _vineyard(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var leaf := MeshKit.mat(Color(0.25, 0.48, 0.15))
	var grape := MeshKit.mat(Color(0.42, 0.15, 0.48), 0.4)
	var hw := 15.0
	var hd := 12.0
	Props.fence(w, o + Vector3(-hw, 0, -hd), o + Vector3(hw, 0, -hd))
	Props.fence(w, o + Vector3(hw, 0, -hd), o + Vector3(hw, 0, hd))
	Props.fence(w, o + Vector3(-hw, 0, -hd), o + Vector3(-hw, 0, -3))
	Props.fence(w, o + Vector3(-hw, 0, 3), o + Vector3(-hw, 0, hd))
	Props.fence(w, o + Vector3(-hw, 0, hd), o + Vector3(-4, 0, hd))
	Props.fence(w, o + Vector3(4, 0, hd), o + Vector3(hw, 0, hd))
	var n := Props.pivot(w, o)
	for i in 6:
		var x := -10.0 + i * 4.0
		MeshKit.static_box(n, Vector3(0.9, 1.5, 14), Vector3(x, 0.75, 0), leaf)
		for j in 7:
			var side := 0.5 if j % 2 == 0 else -0.5
			MeshKit.sphere(n, 0.2, Vector3(x + side, 1.0, -6 + j * 2.0), grape, Vector3(1, 1.4, 1))
	Props.house(w, o + Vector3(4, 0, -19), 0.0, Vector3(9, 4.5, 6), Color(0.55, 0.65, 1.3))
	for p in [Vector3(-3, 0, -15.5), Vector3(-4.2, 0, -16), Vector3(-3.6, 0, -14.4)]:
		Props.barrel(w, o + p)
	Props.crate(w, o + Vector3(12, 0, -16), rng.randf_range(0, 45))


func _mine(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rock := Props.rock_mat(Color(1.25, 1.15, 1.0))
	var iron := MeshKit.mat(Color(0.3, 0.3, 0.32), 0.5, 0.6)
	var wood := Props.dark_wood()
	var n := Props.pivot(w, o)
	# the mine itself: a tunnel into the hill and a crystal cave at its end (Cave, runs towards -x)
	Cave.create(w, o + Vector3(-4, 0, 0), PI * 0.5, 23)
	for r in [[Vector3(-5, -5, -9), 6.5], [Vector3(-5, -5, 9), 6.5], [Vector3(-9, -3, -14), 7.5], [Vector3(-9, -3, 14), 7.5]]:
		MeshKit.static_sphere(n, r[1], r[0], rock)
	for z in [-0.6, 0.6]:
		MeshKit.box(n, Vector3(16, 0.08, 0.08), Vector3(4, 0.12, z), iron)
	for i in 11:
		MeshKit.box(n, Vector3(0.3, 0.08, 1.7), Vector3(-3 + i * 1.5, 0.04, 0), wood)
	MeshKit.static_box(n, Vector3(1.4, 0.9, 1.1), Vector3(4, 0.75, 0), MeshKit.mat(Color(0.42, 0.29, 0.16)))
	for p in [Vector3(3.5, 0.25, -0.6), Vector3(4.5, 0.25, -0.6), Vector3(3.5, 0.25, 0.6), Vector3(4.5, 0.25, 0.6)]:
		MeshKit.cyl(n, 0.22, 0.22, 0.08, p, iron, Vector3(90, 0, 0), 10)
	for i in 4:
		MeshKit.sphere(n, 0.25, Vector3(3.6 + (i % 2) * 0.6, 1.25, -0.25 + (i / 2) * 0.5), rock)
	Props.lantern(w, o + Vector3(-2.5, 0, -3.6))
	Props.lantern(w, o + Vector3(-2.5, 0, 3.6))
	Props.lantern(w, o + Vector3(11, 0, -6))
	Props.crate(w, o + Vector3(6, 0, 8), rng.randf_range(0, 45))
	Props.crate(w, o + Vector3(7, 0, 8.6), rng.randf_range(0, 45))


func _camp(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	Props.tent(w, o + Vector3(-8, 0, -6), 20, Color(0.6, 0.16, 0.12))
	Props.tent(w, o + Vector3(8, 0, -7), -15, Color(0.5, 0.4, 0.24))
	Props.tent(w, o + Vector3(-9, 0, 7), 160, Color(0.6, 0.16, 0.12))
	Props.tent(w, o + Vector3(9, 0, 6), 200, Color(0.5, 0.4, 0.24))
	Props.campfire(w, o)
	Props.palisade(w, o, 15.0, -30.0, 120.0)
	for p in [Vector3(-3, 0, -11), Vector3(-2, 0, -11.6), Vector3(4, 0, 11)]:
		Props.crate(w, o + p, rng.randf_range(0, 45))
	Props.barrel(w, o + Vector3(11, 0, -1))
	Props.barrel(w, o + Vector3(11.5, 0, 0.2))
	Props.torch(w, o + Vector3(-6, 0, 0))


func _den(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rock := Props.rock_mat()
	var bone := MeshKit.mat(Color(0.92, 0.9, 0.82))
	var n := Props.pivot(w, o)
	for i in 7:
		var a := TAU * i / 7.0 + 0.4
		var r := rng.randf_range(1.6, 3.2)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 10.0, -r * 0.35, sin(a) * 10.0), rock)
	for i in 8:
		MeshKit.cyl(n, 0.05, 0.05, rng.randf_range(0.4, 0.8), Vector3(rng.randf_range(-6, 6), 0.06, rng.randf_range(-6, 6)), bone, Vector3(90, rng.randf_range(0, 180), 0), 6)
	MeshKit.static_box(n, Vector3(0.7, 0.7, 6), Vector3(-5, 0.35, 3), Props.dark_wood(), Vector3(0, 35, 0))


func _tower(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var stone := Props.stone(Color(1.1, 1.05, 1.0), 0.4)
	var n := Props.pivot(w, o)
	# broken round tower
	var cs := CylinderShape3D.new()
	cs.radius = 3.2
	cs.height = 9.0
	var b := StaticBody3D.new()
	b.position = Vector3(0, 4.5, 0)
	var c := CollisionShape3D.new()
	c.shape = cs
	b.add_child(c)
	n.add_child(b)
	MeshKit.cyl(n, 3.0, 3.3, 9.0, Vector3(0, 4.5, 0), stone, Vector3.ZERO, 16)
	for i in 7:
		var a := TAU * i / 12.0
		MeshKit.box(n, Vector3(1.0, rng.randf_range(0.8, 3.0), 0.8), Vector3(cos(a) * 3.0, 9.8, sin(a) * 3.0), stone, Vector3(0, -rad_to_deg(a), 0))
	MeshKit.box(n, Vector3(1.6, 2.6, 0.3), Vector3(0, 1.3, 3.2), MeshKit.mat(Color(0.05, 0.05, 0.06)))
	Props.ruined_wall(w, o + Vector3(-7, 0, 5), 30, 8, 3.0, rng)
	Props.ruined_wall(w, o + Vector3(6, 0, 6), -40, 6, 2.5, rng)
	# ritual circle
	var glow := MeshKit.mat(Color(0.7, 0.3, 1.0), 0.5, 0.0, 2.0)
	for i in 8:
		var a := TAU * i / 8.0
		MeshKit.cyl(n, 0.08, 0.08, 0.05, Vector3(cos(a) * 3.0, 0.03, 6 + sin(a) * 3.0), glow, Vector3.ZERO, 6)
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.3, 1.0)
	l.omni_range = 7.0
	l.light_energy = 1.5
	l.position = Vector3(0, 1.0, 6)
	n.add_child(l)


func _farm(w: Node3D, o: Vector3) -> void:
	Props.house(w, o + Vector3(6, 0, -6), 0, Vector3(8, 4.2, 6), Color(1.3, 0.55, 0.4))
	Props.fence(w, o + Vector3(-13, 0, -5), o + Vector3(-13, 0, 11))
	Props.fence(w, o + Vector3(-13, 0, 11), o + Vector3(-1, 0, 11))
	Props.haystack(w, o + Vector3(9, 0, 6))
	Props.hay_bale(w, o + Vector3(5, 0, 8), 30)
	Props.scarecrow(w, o + Vector3(-7, 0, 3), 20)
	Props.well(w, o + Vector3(-1, 0, -9))
