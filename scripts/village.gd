class_name Village
extends RefCounted
## A village: paved square with a well, market stalls, lamp posts and benches, surrounded by a
## shop (trader + stash), a tavern, a smithy (with a forge station), barracks with guards, houses,
## a watchtower and rural buildings, gardens and carts; roads to the square; villagers and kids.
##
## Big towns (styles "city_capital", "city_market", "city_port") are the same, bigger: a wider
## square with a notice board, town walls with gatehouses, specialist traders (weaponsmith,
## armorer, alchemist), a workshop, a temple, more people - and in the capital the King's castle.
##
## plan() runs in the level's layout() (reserves flat ground and roads before the terrain is
## built); build() runs in the level's build().

const SQUARE_R := 11.0

var center := Vector3.ZERO
var style := "town"         # village: "town", "farm", "hamlet", "fort", "fishing"; big towns: "city_*"
var houses := 5
var villagers := 8
var name := "Village"
var slots: Array = []       # [{"pos": Vector3, "yaw": float (deg), "type": String}]
var rng := RandomNumberGenerator.new()
var city := false
var square_r := SQUARE_R
var gates: Array = []       # big towns: gate angles (radians, 0 = +z)
var wall_r := 0.0
var portal := false         # VesPer's portal stands on this square (the location's start village)

const FOOTPRINT := {"shop": 6.5, "tavern": 9.0, "blacksmith": 6.5, "barracks": 8.0, "house": 6.5, "watchtower": 3.5,
	"stable": 6.5, "granary": 4.0, "coop": 4.5, "sawmill": 6.0, "garden": 4.0, "fishing_hut": 4.5,
	"armorer": 6.5, "alchemist": 6.5, "workshop": 7.0, "temple": 9.5, "castle": 15.0}


static func plan(w: Node3D, c: Vector3, village_style := "town", house_count := 5, villager_count := 8, village_name := "Village", seed_value := 1) -> Village:
	var v := Village.new()
	v.center = c
	v.style = village_style
	v.houses = house_count
	v.villagers = villager_count
	v.name = village_name
	v.rng.seed = seed_value
	v.city = village_style.begins_with("city_")
	v.square_r = 17.0 if v.city else SQUARE_R
	var types: Array = ["shop", "tavern", "barracks", "blacksmith"]
	if v.city:
		types += ["armorer", "alchemist", "workshop", "temple"]
	for i in house_count:
		types.append("house")
	match village_style:
		"farm":
			types += ["stable", "granary", "coop", "garden", "garden"]
		"fort":
			types += ["watchtower", "watchtower", "stable"]
		"fishing":
			types += ["garden", "sawmill"]
		"hamlet":
			types += ["garden", "coop"]
		"city_capital":
			types += ["barracks", "stable", "garden", "garden", "granary"]
		"city_port":
			types += ["fishing_hut", "fishing_hut", "garden", "sawmill"]
		"city_market":
			types += ["stable", "garden", "coop", "granary"]
		_:
			types += ["watchtower", "stable", "garden"]
	var taken: Array = []
	if v.city:
		# the main gate faces where travellers come from (the location's start), two more around
		var s: Vector3 = w.cfg.get("player_start", Vector3.ZERO)
		var a0 := atan2(s.x - c.x, s.z - c.z)
		v.gates = [a0, a0 + 2.2, a0 - 2.2]
		if village_style == "city_capital":
			var cp := c + Vector3(sin(a0 + PI), 0, cos(a0 + PI)) * (v.square_r + 34.0)
			v.slots.append({"pos": cp, "yaw": rad_to_deg(a0), "type": "castle"})
			taken.append([Vector2(cp.x, cp.z), FOOTPRINT["castle"]])
	# candidate plots on rings, keeping clear of roads, other zones and each other
	var rings: Array = [v.square_r + 12.0, v.square_r + 24.0, v.square_r + 36.0, v.square_r + 48.0] if v.city else [SQUARE_R + 10.0, SQUARE_R + 22.0, SQUARE_R + 33.0]
	for t in types:
		var fp: float = FOOTPRINT[t]
		var placed := false
		for ring: float in rings:
			if placed:
				break
			var steps := int(TAU * ring / 6.0)
			var off := v.rng.randf() * TAU
			for k in steps:
				var a := off + TAU * k / steps
				var p := c + Vector3(sin(a), 0, cos(a)) * (ring + fp * 0.3)
				if v._free(w, p, fp, taken):
					var to_c := c - p
					var yaw := rad_to_deg(atan2(to_c.x, to_c.z))
					v.slots.append({"pos": p, "yaw": yaw, "type": t})
					taken.append([Vector2(p.x, p.z), fp])
					placed = true
					break
	# reserve the ground: square, plots and a road from every door to the square
	w.add_zone(Vector2(c.x, c.z), v.square_r + 1.5)
	w.paint_circle(Vector2(c.x, c.z), v.square_r, 1)
	for s in v.slots:
		var p: Vector3 = s["pos"]
		w.add_zone(Vector2(p.x, p.z), FOOTPRINT[s["type"]] + 1.0)
		if s["type"] in ["shop", "tavern", "house", "barracks", "blacksmith", "armorer", "alchemist", "workshop", "temple", "castle"]:
			var door: Vector3 = p + (c - p).normalized() * (float(FOOTPRINT[s["type"]]) * 0.75)
			w.add_path(Vector2(door.x, door.z), Vector2(c.x, c.z), 2.6)
	var radius := v.square_r
	if v.city:
		for s in v.slots:
			var p: Vector3 = s["pos"]
			radius = maxf(radius, Vector2(p.x - c.x, p.z - c.z).length() + float(FOOTPRINT[s["type"]]))
		v.wall_r = radius + 6.0
		for g: float in v.gates:
			var dir := Vector2(sin(g), cos(g))
			w.add_path(Vector2(c.x, c.z), Vector2(c.x, c.z) + dir * (v.wall_r + 30.0), 4.0)
		# the whole town is level ground, without trees
		w.add_zone(Vector2(c.x, c.z), v.wall_r + 3.0)
	w.add_landmark(Loc.t(village_name), Vector2(c.x, c.z), v.square_r if not v.city else v.wall_r * 0.5, Color(0.85, 0.75, 0.55) if not v.city else Color(1.0, 0.85, 0.45))
	w.villages.append(v)
	w.nav_areas.append([c, (v.wall_r + 4.0) if v.city else 52.0])
	return v


## Where a big town's gate road ends outside the walls (connect the level's roads here).
func gate_road_end(i := 0) -> Vector2:
	var g: float = gates[i]
	return Vector2(center.x, center.z) + Vector2(sin(g), cos(g)) * (wall_r + 30.0)


func _free(w: Node3D, p: Vector3, fp: float, taken: Array) -> bool:
	var p2 := Vector2(p.x, p.z)
	if maxf(absf(p.x), absf(p.z)) > w.half - 45.0:
		return false
	for tk in taken:
		if p2.distance_to(tk[0]) < fp + float(tk[1]) + 2.0:
			return false
	for seg in w.path_segments:
		if Geometry2D.get_closest_point_to_segment(p2, seg[0], seg[1]).distance_to(p2) < fp + float(seg[2]) * 0.5 + 1.5:
			return false
	for z in w.zones:
		var zc: Vector2 = z[0]
		if p2.distance_to(zc) < fp + float(z[1]) + 1.0:
			return false
	for l in w.lakes:
		var lc: Vector2 = l[0]
		if p2.distance_to(lc) < fp + float(l[1]) * 1.3 + 2.0:
			return false
	# keep the gate roads of a big town clear
	var c2 := Vector2(center.x, center.z)
	for g: float in gates:
		var end := c2 + Vector2(sin(g), cos(g)) * 120.0
		if Geometry2D.get_closest_point_to_segment(p2, c2, end).distance_to(p2) < fp + 3.5:
			return false
	return true


func build(w: Node3D) -> void:
	var c := center
	if style == "city_capital" and ResourceLoader.exists(TBuild.HERO_STATUE):
		TBuild.hero_statue(w, c, 180.0)
	else:
		VBuild.well(w, c)
	var sr := square_r
	# technology learned from the player (see TechProps)
	var tech: int = w.tech_level
	var poles: Array = []
	var lamps := 6 if city else 4
	for i in lamps:
		var a := TAU * i / float(lamps) + PI * 0.25
		var lp := c + Vector3(sin(a), 0, cos(a)) * (sr - 1.0)
		if tech >= 3:
			poles.append(TechProps.electric_lamp(w, lp))
		else:
			VBuild.lamp_post(w, lp)
	if tech >= 3:
		var gen := TechProps.generator(w, c + Vector3(sin(4.25), 0, cos(4.25)) * (sr - 1.4), rad_to_deg(4.25))
		for i in poles.size():
			TechProps.wire(w, poles[i], poles[(i + 1) % poles.size()], 0.06)
		TechProps.wire(w, gen, poles[1], 0.04)
	if tech >= 2:
		TechProps.radio_mast(w, c + Vector3(sin(1.1), 0, cos(1.1)) * (sr - 1.6))
	if tech >= 1:
		for i in (2 if tech >= 3 else 1):
			var dr := DroneFlyer.new()
			dr.center = c
			dr.radius = 12.0 + i * 6.0 + (8.0 if city else 0.0)
			dr.height = 10.0 + i * 3.0
			dr.speed = 0.2 + i * 0.07
			w.add_child(dr)
	if portal:
		var pa := 5.2
		var pp := c + Vector3(sin(pa), 0, cos(pa)) * (sr - 2.0)
		var vp := VesPortal.new()
		vp.world = w
		vp.position = Vector3(pp.x, w.ground(pp.x, pp.z), pp.z)
		vp.rotation.y = pa + PI
		w.add_child(vp)
		w.portal = vp
	var cloths := [Color(0.75, 0.2, 0.15), Color(0.2, 0.4, 0.7), Color(0.85, 0.65, 0.2), Color(0.3, 0.55, 0.3), Color(0.55, 0.25, 0.55), Color(0.85, 0.85, 0.8)]
	var stall_spots := []
	var stalls := 6 if city else 3
	for i in stalls:
		var a := TAU * i / float(stalls) + 0.5
		var p := c + Vector3(sin(a), 0, cos(a)) * (9.5 if city else 6.5)
		VBuild.market_stall(w, p, rad_to_deg(atan2(c.x - p.x, c.z - p.z)), cloths[i % cloths.size()], rng)
		stall_spots.append([p + (c - p).normalized() * -1.2, atan2(p.x - c.x, p.z - c.z), "idle"])
	for i in (6 if city else 3):
		var a := TAU * i / (6.0 if city else 3.0) + 1.55
		var p := c + Vector3(sin(a), 0, cos(a)) * (13.5 if city else 8.5)
		VBuild.bench(w, p, rad_to_deg(atan2(c.x - p.x, c.z - p.z)))
	if not city:
		VBuild.cart(w, c + Vector3(3.0, 0, -8.5), 60.0 + rng.randf() * 40.0)
	VBuild.signpost(w, c + Vector3(-2.5, 0, 3.5), 20.0, [Loc.t(name)])
	var board_pos := Vector3.ZERO
	if city:
		var ba: float = gates[0] + 0.45
		board_pos = c + Vector3(sin(ba), 0, cos(ba)) * 5.0
		TBuild.notice_board(w, board_pos, rad_to_deg(ba))
		TBuild.town_wall(w, c, wall_r, gates)
	var works: Array = stall_spots.duplicate()
	var socials: Array = [c + Vector3(2.5, 0, 2.5), c + Vector3(-3.0, 0, 1.0), c + Vector3(0.5, 0, -3.0)]
	var trader_spot := {}
	var guard_spots: Array = []
	var priest_spot := []
	for s in slots:
		var p: Vector3 = s["pos"]
		var yaw: float = s["yaw"]
		var r := {}
		match s["type"]:
			"house":
				var roofs := [Color(0.75, 0.3, 0.22), Color(0.45, 0.5, 0.65), Color(0.55, 0.45, 0.35), Color(0.35, 0.45, 0.35)]
				var walls := [Color(0.93, 0.89, 0.8), Color(0.9, 0.85, 0.72), Color(0.86, 0.88, 0.85), Color(0.95, 0.9, 0.85)]
				Buildings.house(w, p, yaw, Vector3(rng.randf_range(6.0, 7.5), 4.0, rng.randf_range(4.8, 5.6)), roofs[rng.randi() % roofs.size()], walls[rng.randi() % walls.size()])
				if rng.randf() < 0.5 and not city:
					var gp := p + (p - c).normalized() * 7.0
					works.append([VBuild.garden(w, gp, yaw, rng), 0.0, "work"])
			"shop":
				r = VBuild.shop(w, p, yaw)
				trader_spot = r
			"tavern":
				r = VBuild.tavern(w, p, yaw)
				socials += r.get("social", [])
				works.append(r["work"])
			"blacksmith":
				r = VBuild.blacksmith(w, p, yaw)
				# a forge station at the forge (every smithy)
				var fs := CraftStation.new()
				fs.world = w
				fs.kind = "forge"
				fs.build_visual = false
				(r["node"] as Node3D).add_child(fs)
				fs.position = Vector3(-2.5, Buildings.FLOOR, -0.9)
				if city:
					_trader(w, "weapons", r["work"][0], float(r["work"][1]) + PI, p)
				else:
					works.append(r["work"])
			"armorer":
				r = TBuild.armorer(w, p, yaw)
				_trader(w, "armor", r["trader"], r["trader_yaw"], p)
			"alchemist":
				r = TBuild.alchemist(w, p, yaw)
				_trader(w, "alchemy", r["trader"], r["trader_yaw"], p)
			"workshop":
				r = TBuild.workshop(w, p, yaw)
				works.append(r["work"])
			"temple":
				r = TBuild.temple(w, p, yaw)
				priest_spot = r["work"]
			"castle":
				r = TBuild.castle(w, p, yaw)
				_king(w, r)
				for gp in r["guards"]:
					w.spawn_guard("guard", gp)
			"barracks":
				r = VBuild.barracks(w, p, yaw)
				guard_spots += r["guards"]
			"watchtower":
				r = VBuild.watchtower(w, p, yaw)
				guard_spots.append(r["lookout"])
			"stable":
				r = VBuild.stable(w, p, yaw)
				works.append(r["work"])
			"granary":
				VBuild.granary(w, p, yaw)
			"coop":
				r = VBuild.chicken_coop(w, p, yaw)
				if w.has_method("add_animals"):
					w.add_animals("chicken", r["chickens"], 5)
			"sawmill":
				r = VBuild.sawmill(w, p, yaw)
				works.append(r["work"])
			"fishing_hut":
				r = VBuild.fishing_hut(w, p, yaw)
				if r.has("work"):
					works.append(r["work"])
			"garden":
				works.append([VBuild.garden(w, p, yaw, rng), 0.0, "work"])
	# trader + stash
	if not trader_spot.is_empty():
		_trader(w, "general", trader_spot["trader"], trader_spot["trader_yaw"], center)
		var st := StashChest.new()
		st.world = w
		w.add_child(st)
		st.global_position = trader_spot["stash"]
		st.rotation.y = trader_spot["stash_yaw"]
	# the town's leading citizen stands by the notice board
	if city and style == "city_market":
		_notable(w, "mayor", "Mayor Corvin", "Mayor of Ravenmoor", "people/business", {"Suit": Color(0.2, 0.2, 0.25), "Tie": Color(0.6, 0.1, 0.1)}, board_pos, gates[0])
	elif city and style == "city_port":
		_notable(w, "harbourmaster", "Harbourmaster Brine", "Harbourmaster", "people/farmer", {"LightBlue": Color(0.15, 0.22, 0.4), "Beige": Color(0.7, 0.66, 0.6)}, board_pos, gates[0])
	# guards
	for gp in guard_spots:
		w.spawn_guard("guard_archer" if gp.y > c.y + 4.0 else "guard", gp)
	w.spawn_guard("guard", c + Vector3(4.0, 0, 6.0))
	if city:
		for g: float in gates:
			var side := Vector3(cos(g), 0, -sin(g))
			var inner := c + Vector3(sin(g), 0, cos(g)) * (wall_r - 4.0)
			w.spawn_guard("guard", inner + side * 3.5)
			w.spawn_guard("guard", inner - side * 3.5)
	# villagers
	var homes: Array = []
	for h in w.homes:
		if not h["taken"] and Vector2(h["out"].x - c.x, h["out"].z - c.z).length() < maxf(70.0, wall_r):
			homes.append(h)
	var used_names := {}
	# personalities: every one once (at least one brave), then about one in three brave
	var traits: Array = VillagerTalk.PERSONALITIES.duplicate()
	traits.erase("brave")
	for i in range(traits.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = traits[i]
		traits[i] = traits[j]
		traits[j] = tmp
	traits.push_front("brave")
	var count := mini(villagers, homes.size())
	for i in count:
		var h: Dictionary = homes[i]
		h["taken"] = true
		var vil := Villager.new()
		vil.world = w
		if i < traits.size():
			vil.personality = traits[i]
		else:
			vil.personality = "brave" if rng.randf() < 0.34 else traits[rng.randi() % traits.size()]
		vil.gender = "f" if i % 2 == 1 else "m"
		vil.vname = _unique_name(vil.gender, used_names)
		vil.model_file = People.FEMALE[rng.randi() % People.FEMALE.size()] if vil.gender == "f" else People.MALE[rng.randi() % People.MALE.size()]
		vil.colors = People.random_colors(vil.model_file, rng)
		vil.voice_pitch = rng.randf_range(0.93, 1.08)
		vil.home = h
		var wk: Array = works[i % works.size()] if not works.is_empty() else [c, 0.0, "idle"]
		vil.work = {"pos": wk[0], "yaw": wk[1], "anim": wk[2]}
		vil.job = {"hammer": "Blacksmith", "work": "Farmer", "idle": "Merchant"}.get(str(wk[2]), "Villager")
		if h.get("kind", "") == "tavern":
			vil.job = "Innkeeper"
		if i == 1 and not priest_spot.is_empty():
			vil.job = "Priest"
			vil.personality = "kind"
			vil.work = {"pos": priest_spot[0], "yaw": priest_spot[1], "anim": "idle"}
		vil.social = socials[i % socials.size()]
		w.add_child(vil)
		vil.global_position = h["in"]
	# kids live with the villagers and play on the square
	if count == 0:
		return
	var ball := KidBall.new()
	ball.world = w
	ball.home = c + Vector3(-4.0, 0.0, -4.0)
	w.add_child(ball)
	ball.global_position = ball.home + Vector3(0, 0.4, 0)
	var kids: Array = []
	for i in (4 if city else rng.randi_range(2, 4)):
		var kid := Kid.new()
		kid.world = w
		kid.gender = "m" if i % 2 == 0 else "f"
		kid.vname = _unique_name(kid.gender, used_names)
		kid.job = "Child"
		kid.model_file = ["people/woman_casual", "people/woman"][i % 2] if kid.gender == "f" else ["people/casual", "people/hoodie"][i % 2]
		kid.colors = People.random_colors(kid.model_file, rng)
		kid.voice_pitch = rng.randf_range(1.0, 1.12)
		kid.home = homes[i % count]
		kid.village_center = c
		kid.social = c
		kid.work = {"pos": c, "yaw": 0.0, "anim": "idle"}
		kid.ball = ball
		kids.append(kid)
	for kid in kids:
		for other in kids:
			if other != kid:
				kid.playmates.append(other)
		w.add_child(kid)
		kid.global_position = kid.home["in"]


func _unique_name(gender: String, used: Dictionary) -> String:
	var names: Array = VillagerLines.FEMALE_NAMES if gender == "f" else VillagerLines.MALE_NAMES
	var nm: String = names[rng.randi() % names.size()]
	var tries := 0
	while used.has(nm) and tries < 20:
		nm = names[rng.randi() % names.size()]
		tries += 1
	used[nm] = true
	return Loc.t(nm)


## A trader (QuestGiver with a shop). kind: general / weapons / armor / alchemy.
func _trader(w: Node3D, kind: String, pos: Vector3, yaw: float, near: Vector3) -> QuestGiver:
	var tg := QuestGiver.new()
	tg.world = w
	tg.role = "trader"
	tg.shop_kind = kind
	tg.id = "trader_%s_%d" % [kind, int(near.x * 10.0 + near.z)]
	var female := rng.randf() < 0.4
	tg.title = {"general": "Trader", "weapons": "Weaponsmith", "armor": "Armorer", "alchemy": "Alchemist"}[kind]
	tg.model_file = ("people/woman_dress" if female else "people/farmer") if kind == "alchemy" else (("people/woman_casual" if female else "people/worker") if kind != "general" else "people/business")
	tg.colors = People.random_colors(tg.model_file, rng)
	tg.display_name = _unique_name("f" if tg.model_file.begins_with("people/woman") else "m", {})
	# named traders who also give travel quests
	if kind == "alchemy" and style == "city_capital":
		tg.id = "alchemist"
		tg.display_name = Loc.t("Royal Alchemist Ysolde")
		tg.model_file = "people/woman_dress"
		tg.colors = {"Dress": Color(0.25, 0.45, 0.35), "Hair": Color(0.85, 0.75, 0.5)}
	elif kind == "weapons" and style == "city_port":
		tg.id = "smith"
		tg.display_name = Loc.t("Hilda the Smith")
		tg.model_file = "people/woman_casual"
		tg.colors = {"Hair_Brown": Color(0.6, 0.25, 0.1), "Hair_Blond": Color(0.6, 0.25, 0.1)}
	w.add_child(tg)
	tg.global_position = pos
	tg.rotation.y = yaw
	w.town_npcs[tg.id] = tg
	return tg


## A named townsperson who gives quests.
func _notable(w: Node3D, id: String, full_name: String, title: String, model: String, colors: Dictionary, pos: Vector3, face: float) -> QuestGiver:
	var g := QuestGiver.new()
	g.world = w
	g.id = id
	g.display_name = Loc.t(full_name)
	g.title = title
	g.model_file = model
	g.colors = colors
	w.add_child(g)
	var p := pos + Vector3(cos(face), 0, -sin(face)) * 1.8
	g.global_position = Vector3(p.x, w.ground(p.x, p.z), p.z)
	g.rotation.y = face
	w.town_npcs[id] = g
	return g


## The King on his throne, and the Royal Postmaster at the castle door.
func _king(w: Node3D, r: Dictionary) -> void:
	var k := QuestGiver.new()
	k.world = w
	k.id = "king"
	k.display_name = Loc.t("King Aldemar")
	k.title = "King of the Realm"
	k.model_file = "people/business"
	k.colors = {"Suit": Color(0.35, 0.1, 0.4), "Tie": Color(0.9, 0.75, 0.25), "Hair": Color(0.75, 0.72, 0.68)}
	k.crown = true
	w.add_child(k)
	k.global_position = r["king"]
	k.rotation.y = r["king_yaw"]
	w.town_npcs["king"] = k
	var pm := QuestGiver.new()
	pm.world = w
	pm.id = "postmaster"
	pm.display_name = Loc.t("Postmaster Pell")
	pm.title = "Royal Post"
	pm.model_file = "people/man2"
	pm.colors = {"Shirt": Color(0.2, 0.3, 0.6), "Pants": Color(0.2, 0.2, 0.25)}
	w.add_child(pm)
	pm.global_position = r["herald"]
	pm.rotation.y = r["herald_yaw"]
	w.town_npcs["postmaster"] = pm
