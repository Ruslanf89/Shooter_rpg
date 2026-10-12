extends RefCounted
## Location 5: Emberforge Canyon - volcanic canyon with lava pools, hellhounds, imps and fire cultists.

const WARD := Vector3(0, 0, -184)
const LAVA_LAKE := Vector3(80, 0, -36)
const DEN := Vector3(-120, 0, -80)
const SPIRES := Vector3(124, 0, 100)
const ALTAR := Vector3(-110, 0, 110)
const HEART := Vector3(0, 0, 172)
const SCOUT := Vector3(64, 0, -140)
const LAVA2 := Vector3(-40, 0, 20)
const LAVA3 := Vector3(30, 0, 90)
const NEST := Vector3(170, 0, 30)        # the Canyon Tyrant's nest
var village: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 67, "hill_amp": 10.0, "weather": "embers",
		"player_start": Vector3(0, 0, -224), "player_yaw": PI,
		"sky": {"top_color": Color(0.22, 0.08, 0.06), "horizon_color": Color(0.85, 0.35, 0.14), "ground_color": Color(0.2, 0.1, 0.08),
			"sun_glow": Color(1.0, 0.55, 0.25), "cloud_color": Color(0.32, 0.22, 0.2), "cloud_shadow": Color(0.12, 0.07, 0.06), "cloud_cover": 0.72},
		"sun_rot": Vector3(-25, -120, 0), "sun_color": Color(1.0, 0.6, 0.35), "sun_energy": 1.15, "ambient": 0.8,
		"fog_color": Color(0.45, 0.2, 0.12), "fog_density": 0.008, "color_saturation": 1.1,
		"grass_tint": Vector3(0.38, 0.28, 0.22), "grass_tint2": Vector3(0.3, 0.22, 0.2), "floor_tint": Vector3(0.45, 0.32, 0.26), "floor_amount": 0.8,
		"dirt_tint": Vector3(0.95, 0.5, 0.35), "rock_tint": Vector3(0.6, 0.45, 0.4), "stone_tint": Vector3(0.6, 0.5, 0.48),
		"field_tint": Vector3(0.6, 0.4, 0.3), "saturation": 0.55,
		"foliage": [Color(0.05, 0.04, 0.04), Color(0.16, 0.1, 0.08), Color(0.35, 0.15, 0.06)],
		"pine_foliage": [Color(0.05, 0.04, 0.04), Color(0.12, 0.08, 0.06), Color(0.25, 0.12, 0.05)],
		"bush_foliage": [Color(0.08, 0.05, 0.04), Color(0.2, 0.1, 0.06), Color(0.45, 0.2, 0.06)],
		"bark_tint": Color(0.3, 0.25, 0.25), "tree_style": "dead", "tree_count": 110, "tree_spacing": 8.0, "pine_ratio": 0.0,
		"rock_color": Color(0.6, 0.5, 0.48), "rock_count": 90, "bush_count": 50, "shrubs": false, "log_count": 10,
		"grass_base": Color(0.3, 0.12, 0.06), "grass_tip": Color(0.65, 0.32, 0.12), "grass_per_chunk": 60,
		"ambience": "wind",
	}


func npcs() -> Array:
	return [
		{"id": "kaelen", "name": "Archmage Kaelen", "title": "Keeper of the Ward", "pos": WARD + Vector3(4, 0, 5), "yaw": 180, "model": "people/business", "colors": {"Suit": Color(0.16, 0.18, 0.36), "Tie": Color(0.8, 0.62, 0.2), "Hair": Color(0.75, 0.75, 0.78)}},
		{"id": "ryla", "name": "Scout Ryla", "title": "Kingdom Scout", "pos": SCOUT, "yaw": 150, "model": "people/woman_casual", "colors": {"Shirt": Color(0.34, 0.4, 0.27), "Pants": Color(0.32, 0.25, 0.18), "Hair": Color(0.55, 0.3, 0.15)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": Vector3(-10, 0, -204), "yaw": 160, "model": "people/casual",
			"colors": {"White": "print", "LightBlue": Color(0.06, 0.06, 0.07), "Red_Dark": Color(0.16, 0.16, 0.17), "Hair": Color(0.16, 0.1, 0.06), "Skin": Color(0.88, 0.68, 0.6)},
			"face": "res://assets/textures/vesper_face.png", "pitch": 1.25},
	]


func quests() -> Array:
	var crystals := []
	for c in [LAVA_LAKE, LAVA2, LAVA3]:
		for k in 3:
			var a := TAU * k / 3.0 + 0.5
			crystals.append(c + Vector3(cos(a), 0, sin(a)) * (16.0 if c == LAVA_LAKE else 11.0))
	return [
		{"id": "ec_hounds", "giver": "kaelen", "title": "Hounds of Flame", "type": "kill", "target": "hellhound", "count": 8, "label": "Hellhounds slain", "xp": 600,
			"lines": {"offer": "ec_hounds_offer", "done": "ec_hounds_done"}},
		{"id": "ec_crystals", "giver": "kaelen", "title": "Fuel for the Ward", "type": "gather", "item": "Fire Crystal", "count": 6, "xp": 550, "spots": crystals,
			"lines": {"offer": "ec_crystals_offer", "done": "ec_crystals_done"}},
		{"id": "ec_pyrax", "giver": "kaelen", "title": "Pyrax the Infernal", "type": "boss", "target": "pyrax", "boss_pos": HEART + Vector3(0, 0, -4), "label": "Pyrax banished", "xp": 1200,
			"requires": ["ec_hounds", "ec_crystals", "ec_report"], "lines": {"offer": "ec_pyrax_offer", "done": "ec_pyrax_done"}},
		{"id": "ec_horns", "giver": "ryla", "title": "Imp Horns", "type": "collect", "target": "fire_imp", "item": "Imp Horn", "count": 6, "chance": 0.75, "xp": 550,
			"lines": {"offer": "ec_horns_offer", "done": "ec_horns_done"}},
		{"id": "ec_cultists", "giver": "ryla", "title": "Break the Ritual", "type": "kill", "target": "flame_cultist", "count": 6, "label": "Flame Cultists slain", "xp": 600,
			"requires": ["ec_horns"], "lines": {"offer": "ec_cultists_offer", "done": "ec_cultists_done"}},
		{"id": "ec_report", "giver": "ryla", "to": "kaelen", "title": "Urgent Report", "type": "deliver", "item": "Scout's Report", "xp": 300,
			"requires": ["ec_cultists"], "lines": {"offer": "ec_report_offer", "done": "ec_report_done"}},
		{"id": "ec_raptors", "giver": "ryla", "title": "Raptor Cull", "type": "kill", "target": "raptor", "count": 6, "label": "Raptors slain", "xp": 600,
			"lines": {"offer": "ec_raptors_offer", "done": "ec_raptors_done"}},
		{"id": "ec_tyrant", "giver": "ryla", "title": "The Canyon Tyrant", "type": "boss", "target": "canyon_tyrant", "boss_pos": NEST + Vector3(0, 0, -4), "label": "Canyon Tyrant slain", "xp": 1100,
			"requires": ["ec_raptors"], "lines": {"offer": "ec_tyrant_offer", "done": "ec_tyrant_done"}},
		{"id": "vesper_ec", "giver": "vesper", "title": "Eyes on the Spires", "type": "gather", "item": "Drone Camera", "count": 1, "xp": 600,
			"spots": [SPIRES + Vector3(-9, 0, -8)], "lines": {"offer": "vesper_ec_offer", "done": "vesper_ec_done"}},
	]


func pois() -> Array:
	return [["obelisk", Vector3(-184, 0, -16), 0.0], ["ruin", Vector3(184, 0, -60), 90.0], ["crystals", Vector3(-60, 0, 64), -1.0],
		["statue", Vector3(144, 0, 176), 200.0], ["cart", Vector3(-50, 0, -150), 10.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	var cross := Vector2(0, -70)
	var mid := Vector2(0, 60)
	w.add_path(Vector2(0, -230), Vector2(0, -160))
	w.add_path(Vector2(0, -160), cross)
	w.add_path(cross, Vector2(-96, -80))
	w.add_path(cross, Vector2(44, -60))
	w.add_path(cross, mid)
	w.add_path(mid, Vector2(0, 144))
	w.add_path(mid, Vector2(100, 92))
	w.add_path(mid, Vector2(-88, 104))
	w.add_path(Vector2(0, -160), Vector2(56, -140))
	w.add_path(mid, Vector2(NEST.x - 14, NEST.z + 4))
	for z in [[WARD, 16.0], [DEN, 14.0], [SPIRES, 16.0], [ALTAR, 16.0], [HEART, 22.0], [SCOUT, 6.0], [NEST, 18.0]]:
		var zp: Vector3 = z[0]
		w.add_zone(Vector2(zp.x, zp.z), z[1])
	for l in [[LAVA_LAKE, 14.0], [LAVA2, 8.0], [LAVA3, 7.0], [HEART + Vector3(-16, 0, 6), 6.0], [HEART + Vector3(16, 0, 6), 6.0]]:
		var lp: Vector3 = l[0]
		w.add_lake(Vector2(lp.x, lp.z), l[1], 2.0)
	w.paint_circle(Vector2(WARD.x, WARD.z), 9.0, 1)
	w.paint_circle(Vector2(HEART.x, HEART.z), 14.0, 1)
	w.add_landmark("Ward Circle", Vector2(WARD.x, WARD.z), 10.0, Color(0.5, 0.6, 1.0))
	w.add_landmark("Lava Lake", Vector2(LAVA_LAKE.x, LAVA_LAKE.z), 14.0, Color(1.0, 0.4, 0.1))
	w.add_landmark("Hellhound Den", Vector2(DEN.x, DEN.z), 11.0, Color(0.6, 0.25, 0.2))
	w.add_landmark("Imp Spires", Vector2(SPIRES.x, SPIRES.z), 12.0, Color(0.9, 0.5, 0.2))
	w.add_landmark("Cultist Altar", Vector2(ALTAR.x, ALTAR.z), 12.0, Color(0.85, 0.2, 0.15))
	w.paint_circle(Vector2(NEST.x, NEST.z), 13.0, 0)
	w.add_landmark("Tyrant's Nest", Vector2(NEST.x, NEST.z), 13.0, Color(0.8, 0.55, 0.3))
	w.add_landmark("Heart of the Inferno", Vector2(HEART.x, HEART.z), 14.0, Color(1.0, 0.3, 0.1))
	village = Village.plan(w, Vector3(-62, 0, -170), "fort", 4, 6, "Cinder Hold", 51)
	w.plan_feature("crypt", Vector3(160, 0, -150), 10.0, "Ashen Tomb")
	w.plan_feature("ruined_castle", Vector3(-190, 0, 20), 16.0, "Burnt Citadel")


func spawns() -> Array:
	var d := DEN
	var s := SPIRES
	var a := ALTAR
	return [
		["hellhound", d + Vector3(3, 0, 2)], ["hellhound", d + Vector3(-4, 0, -3)], ["hellhound", d + Vector3(1, 0, -6)],
		["hellhound", d + Vector3(6, 0, -4)], ["hellhound", d + Vector3(-2, 0, 5)], ["hellhound", d + Vector3(-7, 0, 1)],
		["hellhound", Vector3(40, 0, 0)], ["hellhound", Vector3(-60, 0, -20)], ["hellhound", Vector3(-68, 0, -12)],
		["fire_imp", s + Vector3(-5, 0, -4)], ["fire_imp", s + Vector3(5, 0, -3)], ["fire_imp", s + Vector3(-4, 0, 6)],
		["fire_imp", s + Vector3(6, 0, 7)], ["fire_imp", s + Vector3(0, 0, -9)], ["fire_imp", s + Vector3(9, 0, 1)],
		["magma_golem", LAVA_LAKE + Vector3(-17, 0, 6)], ["magma_golem", LAVA_LAKE + Vector3(10, 0, 15)], ["magma_golem", LAVA_LAKE + Vector3(17, 0, -6)],
		["flame_cultist", a + Vector3(-5, 0, -4)], ["flame_cultist", a + Vector3(5, 0, -3)], ["flame_cultist", a + Vector3(-4, 0, 6)],
		["flame_cultist", a + Vector3(6, 0, 6)], ["flame_cultist", a + Vector3(0, 0, -9)], ["flame_cultist", a + Vector3(-9, 0, 0)],
		["magma_golem", HEART + Vector3(-8, 0, -14)], ["magma_golem", HEART + Vector3(8, 0, -14)],
		# raptor packs: around the nest, and two hunting packs in the canyon
		["raptor", NEST + Vector3(-12, 0, 8)], ["raptor", NEST + Vector3(-14, 0, -6)], ["raptor", NEST + Vector3(-9, 0, 14)],
		["raptor", Vector3(100, 0, -95)], ["raptor", Vector3(104, 0, -90)], ["raptor", Vector3(97, 0, -88)],
		["raptor", Vector3(-135, 0, 15)], ["raptor", Vector3(-130, 0, 20)], ["raptor", Vector3(-138, 0, 24)],
	]


func barrels() -> Array:
	return [ALTAR + Vector3(9, 0, -6), ALTAR + Vector3(-8, 0, 8), SPIRES + Vector3(-10, 0, 2), DEN + Vector3(9, 0, 7)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	_ward(w, WARD)
	for l in [[LAVA_LAKE, 14.0], [LAVA2, 8.0], [LAVA3, 7.0], [HEART + Vector3(-16, 0, 6), 6.0], [HEART + Vector3(16, 0, 6), 6.0]]:
		Props.lava(w, l[0], l[1], -0.9)
	_spires(w, SPIRES, rng)
	_altar(w, ALTAR)
	_heart(w, HEART, rng)
	_nest(w, NEST, rng)
	var rk := Props.rock_mat(Color(0.6, 0.48, 0.45))
	var n := Props.pivot(w, DEN)
	for i in 7:
		var a := TAU * i / 7.0
		var r := rng.randf_range(2.0, 3.5)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 11.0, -r * 0.3, sin(a) * 11.0), rk)
	Props.tent(w, SCOUT + Vector3(3, 0, -3), 120, Color(0.35, 0.3, 0.2))
	Props.crate(w, SCOUT + Vector3(-2.5, 0, 1.5), 20)
	village.build(w)


func _ward(w: Node3D, o: Vector3) -> void:
	var st := Props.stone(Color(0.7, 0.68, 0.75), 0.4)
	var rune := MeshKit.mat(Color(0.4, 0.6, 1.0), 0.5, 0.0, 2.5)
	var n := Props.pivot(w, o)
	for i in 6:
		var a := TAU * i / 6.0
		MeshKit.static_box(n, Vector3(1.0, 4.5, 1.0), Vector3(cos(a) * 9.0, 2.25, sin(a) * 9.0), st)
		MeshKit.sphere(n, 0.4, Vector3(cos(a) * 9.0, 4.9, sin(a) * 9.0), rune)
	for i in 24:
		var a := TAU * i / 24.0
		MeshKit.cyl(n, 0.12, 0.12, 0.05, Vector3(cos(a) * 6.5, 0.04, sin(a) * 6.5), rune, Vector3.ZERO, 6)
	var dome := MeshKit.sphere(n, 10.0, Vector3(0, 0, 0), MeshKit.glow(Color(0.3, 0.5, 1.0, 0.06)), Vector3(1, 0.6, 1))
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 0.7, 1.0)
	l.light_energy = 2.0
	l.omni_range = 16.0
	l.position.y = 3.0
	n.add_child(l)
	Props.tent(w, o + Vector3(-5, 0, -2), 70, Color(0.3, 0.3, 0.55))
	Props.crate(w, o + Vector3(5, 0, -4), 30)


func _spires(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rk := Props.rock_mat(Color(0.55, 0.4, 0.38))
	var n := Props.pivot(w, o)
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var h := rng.randf_range(8.0, 16.0)
		var p := Vector3(cos(a) * 13.0, h * 0.5 - 0.5, sin(a) * 13.0)
		MeshKit.cyl(n, 0.4, 2.4, h, p, rk, Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)), 7)
		var sh := CylinderShape3D.new()
		sh.radius = 1.8
		sh.height = h
		var b := StaticBody3D.new()
		b.position = p
		var cs := CollisionShape3D.new()
		cs.shape = sh
		b.add_child(cs)
		n.add_child(b)
	Props.campfire(w, o)


func _altar(w: Node3D, o: Vector3) -> void:
	var st := Props.stone(Color(0.45, 0.35, 0.35), 0.4)
	var n := Props.pivot(w, o)
	MeshKit.static_box(n, Vector3(4, 1.2, 2.2), Vector3(0, 0.6, 0), st)
	MeshKit.box(n, Vector3(3.6, 0.1, 1.8), Vector3(0, 1.25, 0), MeshKit.mat(Color(0.6, 0.05, 0.03), 0.4, 0.0, 1.2))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		Props.torch(w, o + Vector3(cos(a) * 8.0, 0, sin(a) * 8.0), Color(1.0, 0.35, 0.1))
	Props.ruined_wall(w, o + Vector3(0, 0, -12), 0, 14, 5.0, RandomNumberGenerator.new())


## The Canyon Tyrant's nest: a ring of boulders, a hollow of dry brush with huge speckled eggs,
## rib cages and bones of its prey, a broken cart of an unlucky trader.
func _nest(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rk := Props.rock_mat(Color(0.62, 0.48, 0.42))
	var bone := MeshKit.mat(Color(0.9, 0.86, 0.76), 0.8)
	var n := Props.pivot(w, o)
	for i in 9:
		var a := TAU * i / 9.0 + 0.2
		if absf(wrapf(a - PI, -PI, PI)) < 0.45:
			continue   # the way in faces the canyon path (-x)
		var r := rng.randf_range(2.2, 3.8)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 15.0, -r * 0.25, sin(a) * 15.0), rk)
	# brush hollow and eggs
	var brush := MeshKit.mat(Color(0.42, 0.3, 0.18), 1.0)
	MeshKit.cyl(n, 3.6, 4.2, 0.6, Vector3(0, 0.2, 6), brush, Vector3.ZERO, 14)
	var egg := MeshKit.mat(Color(0.86, 0.8, 0.66), 0.6)
	var spot := MeshKit.mat(Color(0.5, 0.32, 0.22), 0.7)
	for i in 5:
		var a := TAU * i / 5.0
		var p := Vector3(cos(a) * 1.6, 0.95, 6.0 + sin(a) * 1.6)
		MeshKit.sphere(n, 0.55, p, egg, Vector3(0.85, 1.25, 0.85))
		for k in 3:
			MeshKit.sphere(n, 0.09, p + Vector3(cos(a + k) * 0.42, 0.1 + k * 0.18, sin(a + k) * 0.42), spot)
	# rib cages and scattered bones
	for c in [Vector3(-6, 0, -7), Vector3(7, 0, -5)]:
		var yaw := rng.randf_range(0, 180)
		var cage := Node3D.new()
		cage.position = c
		cage.rotation_degrees.y = yaw
		n.add_child(cage)
		MeshKit.cyl(cage, 0.12, 0.12, 3.2, Vector3(0, 0.25, 0), bone, Vector3(90, 0, 0), 6)
		for k in 6:
			for s in [-1.0, 1.0]:
				MeshKit.cyl(cage, 0.06, 0.08, 1.5, Vector3(s * 0.55, 0.75, -1.3 + k * 0.5), bone, Vector3(0, 0, s * -28.0), 6)
		MeshKit.collider_box(cage, Vector3(1.6, 1.4, 3.2), Vector3(0, 0.7, 0))
	for i in 14:
		MeshKit.cyl(n, 0.05, 0.06, rng.randf_range(0.5, 1.2), Vector3(rng.randf_range(-10, 10), 0.06, rng.randf_range(-10, 10)), bone, Vector3(90, rng.randf_range(0, 180), 0), 6)
	MeshKit.sphere(n, 0.45, Vector3(3.5, 0.3, -9), bone, Vector3(1.2, 0.9, 1.4))
	if PropKit.enabled():
		PropKit.put(n, "Vase_Rubble_Medium", Vector3(-9, 0, 4), 30.0)
		PropKit.put(n, "Bag", Vector3(-8, 0, 6), 70.0)
		PropKit.put(n, "Shield_Wooden", Vector3(-7.4, 0.05, 2.6), 40.0)
	Props.crate(w, o + Vector3(-10, 0, 3), 35)


func _heart(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rk := Props.rock_mat(Color(0.5, 0.38, 0.35))
	var n := Props.pivot(w, o)
	for p in [[Vector3(-20, -2, 14), 10.0], [Vector3(20, -2, 14), 10.0], [Vector3(0, -3, 24), 12.0]]:
		MeshKit.static_sphere(n, p[1], p[0], rk)
	var glow := MeshKit.mat(Color(1.0, 0.35, 0.05), 0.5, 0.0, 3.0)
	for i in 8:
		var a := TAU * i / 8.0
		MeshKit.cyl(n, 0.3, 0.3, 0.05, Vector3(cos(a) * 10.0, 0.04, sin(a) * 10.0), glow, Vector3.ZERO, 8)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.4, 0.1)
	l.light_energy = 3.0
	l.omni_range = 22.0
	l.position.y = 4.0
	n.add_child(l)
	w.fire_lights.append(l)
