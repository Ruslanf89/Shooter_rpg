class_name WorldEvents
extends Node
## Random world events (one at a time, every 4-8 minutes):
##   ambush   - a merchant's caravan is attacked on a road; save the merchant for a reward
##   raid     - at night, monsters attack the village; guards fight alongside you
##   elite    - a named elite monster roams the wilds (great loot)
##   merchant - a travelling merchant waits on a road for a few minutes (opens a shop)

var world: Node
var _t := 180.0
var _active := ""
var _left := 0.0
var _enemies: Array = []
var _npc: Node3D
var _marker: Node3D


func _process(delta: float) -> void:
	if world.finished or world.player == null:
		return
	if _active != "":
		_update_active(delta)
		return
	_t -= delta
	if _t <= 0.0:
		_t = randf_range(240.0, 480.0)
		start_random()


func start_random() -> String:
	if _active != "":
		return "An event is already running: " + _active
	var options := ["ambush", "elite", "merchant"]
	if world.day_night.is_night() and world.level.get("village") != null:
		options.append("raid")
		options.append("raid")
	var e: String = options[randi() % options.size()]
	call("_start_" + e)
	return "Started event: " + e


func _enemy_types() -> Array:
	var types: Array = []
	for en in get_tree().get_nodes_in_group("enemies"):
		if not en.neutral and not en.boss and not types.has(en.type):
			types.append(en.type)
	return types if not types.is_empty() else ["bandit"]


func _road_point(min_d: float, max_d: float) -> Vector3:
	var pp: Vector3 = world.player.global_position
	for i in 40:
		var seg: Array = world.path_segments[randi() % world.path_segments.size()]
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var q := a.lerp(b, randf())
		var d := q.distance_to(Vector2(pp.x, pp.z))
		if d > min_d and d < max_d:
			return Vector3(q.x, world.ground(q.x, q.y), q.y)
	var ang := randf() * TAU
	var p := pp + Vector3(cos(ang), 0, sin(ang)) * (min_d + max_d) * 0.5
	return Vector3(p.x, world.ground(p.x, p.z), p.z)


func _spawn(type: String, pos: Vector3, level: int, elite := false) -> Enemy:
	var e := Enemy.new()
	e.type = type
	e.world = world
	e.level = level
	e.elite = elite
	e.position = world.free_spot(pos if Enemy.TYPES[type].get("guard", false) else world.clear_of_npcs(pos)) + Vector3(0, 0.3, 0)
	world.add_child(e)
	e.died.connect(world._on_enemy_died)
	_enemies.append(e)
	return e


func _beacon(pos: Vector3, color: Color) -> void:
	_marker = Node3D.new()
	world.add_child(_marker)
	_marker.global_position = pos
	var beam := CylinderMesh.new()
	beam.top_radius = 0.3
	beam.bottom_radius = 1.2
	beam.height = 40.0
	MeshKit.inst(_marker, beam, Vector3(0, 20, 0), MeshKit.glow(Color(color, 0.12)))
	world.event_target = pos


func _start_ambush() -> void:
	_active = "ambush"
	var p := _road_point(60.0, 140.0)
	VBuild.cart(world, p, randf() * 360.0)
	var v := Villager.new()
	v.world = world
	v.vname = VillagerLines.MALE_NAMES[randi() % VillagerLines.MALE_NAMES.size()]
	v.job = "Merchant"
	v.model_file = "people/farmer"
	v.colors = People.random_colors(v.model_file, RandomNumberGenerator.new())
	var spot := p + Vector3(2.0, 0, 0)
	v.home = {"door": null, "out": spot, "in": spot, "bed": spot, "bed_yaw": 0.0, "table": spot}
	v.work = {"pos": spot, "yaw": 0.0, "anim": "idle"}
	v.social = spot
	v.hp = 200.0
	v.mortal = true
	v.personality = "brave"
	world.add_child(v)
	v.global_position = spot
	_npc = v
	var types := _enemy_types()
	var lv: int = world.enemy_level_at(p)
	for i in 4 + randi() % 3:
		_spawn(types[randi() % types.size()], p + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), lv)
	_beacon(p, Color(1.0, 0.6, 0.2))
	_left = 240.0
	world.hud.show_message(Loc.t("A merchant's caravan is under attack! Help them (check the map)"), Color(1.0, 0.65, 0.3), 5.0)
	Game.play_sound("scream", p, 6.0, 1.0)


func _start_raid() -> void:
	_active = "raid"
	var v: Village = world.level.village
	var c := v.center
	var types := _enemy_types()
	var lv: int = world.enemy_level_at(c) + 1
	for i in 8 + randi() % 5:
		var a := randf() * TAU
		var e := _spawn(types[randi() % types.size()], c + Vector3(cos(a), 0, sin(a)) * randf_range(35.0, 50.0), lv, i == 0)
		e.home = c
		e.call_deferred("aggro")
	_beacon(c, Color(1.0, 0.2, 0.15))
	_left = 300.0
	world.hud.show_message(Loc.t("The dead are attacking %s! Defend the village") % Loc.t(v.name), Color(1.0, 0.3, 0.25), 5.0)
	Game.play_sound("roar", c, 8.0, 0.7)
	for g in get_tree().get_nodes_in_group("enemies"):
		if g.neutral:
			g.home = c


func _start_elite() -> void:
	_active = "elite"
	var p := _road_point(80.0, 180.0)
	var types := _enemy_types()
	var e := _spawn(types[randi() % types.size()], p, world.zone_levels().y + 2, true)
	e.max_hp *= 1.6
	e.hp = e.max_hp
	e.display_name = Loc.t("Dread") + " " + e.display_name
	if e.name_label:
		e.name_label.text = "%s %d  %s" % [Loc.t("Lv"), e.level, e.display_name]
	_beacon(p, Color(1.0, 0.85, 0.25))
	_left = 420.0
	world.hud.show_message(Loc.t("A dreadful creature roams the land... (check the map)"), Color(1.0, 0.85, 0.3), 5.0)


func _start_merchant() -> void:
	_active = "merchant"
	var p := _road_point(40.0, 110.0)
	VBuild.cart(world, p, randf() * 360.0)
	var t := QuestGiver.new()
	t.world = world
	t.id = "wandering_merchant"
	t.display_name = Loc.t("Wandering Merchant")
	t.title = "Trader"
	t.role = "trader"
	t.model_file = "people/adventurer"
	t.colors = {"LightGreen": Color(0.55, 0.3, 0.45), "Green": Color(0.3, 0.2, 0.3)}
	world.add_child(t)
	t.global_position = p + Vector3(2.0, 0, 1.0)
	_npc = t
	world.trader_stock = []      # new goods
	_beacon(p, Color(0.4, 0.9, 1.0))
	_left = 300.0
	world.hud.show_message(Loc.t("A wandering merchant has stopped on the road (check the map)"), Color(0.5, 0.9, 1.0), 5.0)


func _update_active(delta: float) -> void:
	_left -= delta
	var alive := 0
	for e in _enemies:
		if is_instance_valid(e) and e.state != Enemy.State.DEAD:
			alive += 1
	match _active:
		"ambush":
			if not is_instance_valid(_npc) or _npc._dead:
				world.hud.show_message(Loc.t("The merchant was killed..."), Color(0.8, 0.5, 0.4), 3.0)
				_end()
			elif alive == 0:
				_reward(Loc.t("Caravan saved!"), 2)
				_end()
		"raid", "elite":
			if alive == 0:
				_reward(Loc.t("Village saved!") if _active == "raid" else Loc.t("The dread creature is dead!"), 3)
				world.hero_t = 900.0
				world.raid_t = 600.0
				world.ai_villagers_react("react_raid", 2.0)
				Brain.event("raid", "Monsters raided Northvale at night and the Outsider fought them off with the guards" if _active == "raid" else "The Outsider killed a dreadful creature that stalked the valley", {"importance": 3})
				_end()
		_:
			pass
	if _left <= 0.0:
		_end()


func _reward(text: String, quality: int) -> void:
	var p: Player = world.player
	var xp: int = Skills.kill_xp(world.zone_levels().y, 200.0, true, false) * 2
	p.add_xp(xp)
	var gold: int = 60 * world.zone_levels().y
	p.add_gold(gold, true)
	var it := Items.generate(world.zone_levels().y, Items.roll_quality(1.5, quality - 1))
	LootDrop.spawn(world, p.global_position + (-p.global_transform.basis.z) * 2.0, it)
	world.hud.show_loot(text, ["+%d XP" % xp, "+%d %s" % [gold, Loc.t("gold")], Items.display_name(it)])
	Game.play_sound("quest_done", null, -2.0)


func _end(keep_npc := false) -> void:
	_active = ""
	_enemies.clear()
	world.event_target = Vector3.INF
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
	if _npc and is_instance_valid(_npc) and not keep_npc:
		var n := _npc
		var tw := n.create_tween()
		tw.tween_interval(20.0)
		tw.tween_callback(n.queue_free)
	_npc = null
