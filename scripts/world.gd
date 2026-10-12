extends Node3D
## Loads the current location (see scripts/levels/*.gd), builds terrain, vegetation and props,
## spawns the player and enemies, and handles level clear / death / victory.

var cfg: Dictionary
var level: RefCounted
var half := 140.0
var map_half := 140.0
var rng := RandomNumberGenerator.new()
var terrain: Terrain
var player: Player
var hud: Hud

# filled by the level script in layout()
var landmarks: Array = []       # {name, pos: Vector2, radius, color}
var path_segments: Array = []   # [Vector2 a, Vector2 b, float width]
var zones: Array = []           # [Vector2 center, float radius]  flattened, kept free of trees
var lakes: Array = []           # [Vector2 center, float radius, float depth]
var paint_ops: Array = []       # ["rect", Rect2, channel] / ["circle", Vector2, r, channel]
var tree_points: Array = []     # Vector2, for the map
var building_areas: Array = []   # [Vector2 centre, float radius] - no grass grows here (house floors)

var water_zones: Array = []     # [Vector2 center, float radius, float level]
var fire_lights: Array[OmniLight3D] = []
var flicker_lights: Array = []     # [OmniLight3D, base energy] - lanterns that stutter now and then
var _scream_t := 25.0
var lamp_mult := 1.0               # lantern brightness (higher at night), set by DayNight
var cave_dim := 1.0                # < 1 while the player is inside a cave (set by Cave, used by DayNight)
var day_night: DayNight
var _save_t := 120.0
var wanted_stars := 0
var tech_level := 0                # how much of the player's technology this land has learned (0..5)
var _wanted_t := 0.0
var _escalate_t := 0.0
var _reinforce_t := 0.0
var homes: Array = []            # houses villagers can live in (see Buildings.house)
var villages: Array = []
var events: WorldEvents
var event_target := Vector3.INF
var weather := "clear"
var hero_t := 0.0                  # villagers greet the player as a hero for a while after saving them
var raid_t := 0.0                  # villagers talk about the last raid for a while
var _rain: CPUParticles3D
var _storm_t := 0.0
var _weather_t := 300.0
var _night_t := 30.0
var _night_spawned: Array = []
var admin_panel: AdminPanel
var extras: ExtraRoot
var features: Array = []        # [type, Vector3, yaw] planned in layout, built after the level
var spinners: Array = []        # [Node3D, Vector3 angular speed]

var enemies_total := 0
var enemies_alive := 0
var kills := 0
var shots_fired := 0
var shots_hit := 0
var elapsed := 0.0
var finished := false

var _holes: Array[Node3D] = []
var _hole_mesh: QuadMesh


func _ready() -> void:
	var info: Dictionary = Game.current_level()
	level = load(info["script"]).new()
	cfg = level.config()
	half = cfg.get("half", 140.0)
	map_half = half
	rng.seed = cfg.get("seed", 1)
	_hole_mesh = QuadMesh.new()
	_hole_mesh.size = Vector2(0.09, 0.09)
	_hole_mesh.material = MeshKit.unshaded(Color(0.05, 0.05, 0.05))

	tech_level = Game.level_index
	level.layout(self)
	# VesPer's portal stands in the village nearest to where you arrive
	var bestv: Village = null
	var bd := INF
	var ps: Vector3 = cfg["player_start"]
	for v: Village in villages:
		var d := v.center.distance_to(ps)
		if not v.city and d < bd:
			bd = d
			bestv = v
	if bestv:
		bestv.portal = true
	_build_environment()
	day_night = DayNight.new()
	day_night.world = self
	add_child(day_night)

	terrain = Terrain.new()
	terrain.half = half
	terrain.hill_amp = cfg.get("hill_amp", 6.0)
	terrain.sea_z = cfg.get("sea_z", 0.0)
	terrain.seed_value = cfg.get("seed", 1)
	terrain.flat_zones = zones
	terrain.lakes = lakes
	terrain.paths = path_segments
	terrain.mask_size = 1024 if half > 200.0 else 512
	add_child(terrain)
	terrain.generate()
	terrain.init_mask()
	for seg in path_segments:
		terrain.paint_segment(seg[0], seg[1], seg[2], 0)
	for op in paint_ops:
		if op[0] == "rect":
			terrain.paint_rect(op[1], op[2])
		else:
			terrain.paint_circle(op[1], op[2], op[3])
	terrain.apply_material(cfg)

	level.build(self)
	_build_features()
	extras = ExtraRoot.load_for(self, info["script"])
	if extras:
		extras.build_static()
	_build_vegetation()
	_build_walls()

	player = Player.new()
	player.world = self
	var start: Vector3 = cfg["player_start"]
	player.position = Vector3(start.x, ground(start.x, start.z) + 0.3, start.z)
	player.rotation.y = cfg.get("player_yaw", PI)
	# travelling (or respawning): step out of VesPer's portal
	if Game.arrive_at == "portal" and portal and portal.is_built():
		var ap := portal.arrival_point()
		player.position = Vector3(ap.x, ground(ap.x, ap.z) + 0.3, ap.z)
		player.rotation.y = portal.rotation.y
	Game.arrive_at = ""
	add_child(player)
	terrain.set_camera(player.camera)
	player.apply_carry(Game.carry)
	player.camera.far = [250.0, 400.0, 600.0, 800.0][Game.settings.get("quality", 2)]
	player.died.connect(_on_player_died)

	_spawn_enemies(level.spawns())
	if level.has_method("barrels"):
		for p: Vector3 in level.barrels():
			var b := ExplosiveBarrel.new()
			b.world = self
			add_child(b)
			b.global_position = Vector3(p.x, ground(p.x, p.z), p.z)

	hud = Hud.new()
	hud.world = self
	hud.player = player
	add_child(hud)

	# quests and quest givers
	quests = QuestManager.new()
	add_child(quests)
	if level.has_method("npcs"):
		for n in level.npcs():
			var g := QuestGiver.new()
			g.world = self
			g.id = n["id"]
			g.display_name = Loc.t(n["name"])
			g.title = n["title"]
			g.model_file = n.get("model", "people/casual")
			g.tint = n.get("tint", Color(1, 1, 1))
			g.colors = n.get("colors", {})
			g.face_texture = n.get("face", "")
			g.cap_color = n.get("cap", Color(0, 0, 0, 0))
			g.voice_pitch = n.get("pitch", 1.0)
			g.head_height = n.get("head", 1.62)
			var np: Vector3 = n["pos"]
			add_child(g)
			g.global_position = Vector3(np.x, ground(np.x, np.z), np.z)
			g.rotation.y = deg_to_rad(n.get("yaw", 0.0))
			quests.npcs[g.id] = g
	for id in town_npcs:
		quests.npcs[id] = town_npcs[id]
	quests.setup(self, level.quests() if level.has_method("quests") else [])
	if level.has_method("pois"):
		for poi in level.pois():
			Props.poi(self, poi[0], poi[1], poi[2] if poi.size() > 2 else 0.0)
			var chest := TreasureChest.new()
			chest.world = self
			add_child(chest)
			var cp: Vector3 = poi[1] + Vector3(1.5, 0, 1.5).rotated(Vector3.UP, deg_to_rad(poi[2] if poi.size() > 2 else 0.0))
			chest.global_position = free_spot(cp, 0.7, 1.0)
			chest.rotation.y = randf() * TAU
	_build_weather(cfg.get("weather", ""))
	if extras:
		extras.build_dynamic()
	var merged := MeshBatcher.bake(self)
	if OS.has_environment("SHOT_MODE"):
		print("BATCHED ", merged, " meshes")
	events = WorldEvents.new()
	events.world = self
	add_child(events)
	_spawn_wildlife()
	admin_panel = AdminPanel.new()
	admin_panel.world = self
	hud.root.add_child(admin_panel)
	var first_visit: bool = not Game.loc_state().get("visited", false)
	Game.loc_state()["visited"] = true
	_spawn_gather_nodes()
	NavBuilder.build(self, nav_areas)
	journey = Journey.new()
	journey.world = self
	add_child(journey)
	if Game.settings.get("cutscenes", true) and first_visit:
		var cs := Cutscene.new()
		cs.world = self
		cs.level = Game.level_index
		cs.finished.connect(func() -> void: hud.show_title(info["name"], info["subtitle"]))
		add_child(cs)
	else:
		hud.show_title(info["name"], info["subtitle"])
	if Game.is_embedded() and Game.settings["fullscreen"]:
		hud.show_message(Loc.t("Tip: fullscreen only works when the game runs in its own window (see README)"), Color(1, 0.8, 0.5), 6.0)
	Game.play_ambience(cfg.get("ambience", "forest"))
	_update_music()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if not finished:
		elapsed += delta
	var t := Time.get_ticks_msec() * 0.001
	for i in fire_lights.size():
		fire_lights[i].light_energy = 2.2 + sin(t * 9.0 + i) * 0.35 + sin(t * 23.0 + i * 2.0) * 0.25
	for s in spinners:
		var node: Node3D = s[0]
		node.rotation += s[1] * delta
	for i in flicker_lights.size():
		var fl: Array = flicker_lights[i]
		var l: OmniLight3D = fl[0]
		var k := sin(t * (1.3 + (i % 5) * 0.23) + i * 2.3)
		# mostly steady, with short stutters
		l.light_energy = float(fl[1]) * lamp_mult * (0.15 + randf() * 0.4 if k > 0.97 or (k > 0.9 and randf() < 0.3) else 1.0)
	if player == null or hud == null:
		return
	_process_respawns()
	_process_lava(delta)
	_process_wanted(delta)
	_process_weather(delta)
	_process_night(delta)
	_process_roamer(delta)
	_music_t -= delta
	if _music_t <= 0.0:
		_music_t = 1.0
		_update_music()
	hero_t = maxf(0.0, hero_t - delta)
	raid_t = maxf(0.0, raid_t - delta)
	_save_t -= delta
	if _save_t <= 0.0:
		_save_t = 120.0
		Game.save_now()
	# something screams far away now and then
	_scream_t -= delta
	if _scream_t <= 0.0 and not finished:
		_scream_t = randf_range(35.0, 80.0)
		var a := randf() * TAU
		var sp := player.global_position + Vector3(cos(a), 0, sin(a)) * 60.0
		Game.play_sound(["scream", "zombie", "roar", "ghost", "hound"].pick_random(), sp, 4.0, randf_range(0.7, 0.9))
	if _weather:
		_weather.global_position = player.global_position + Vector3(0, 12, 0)
	# interaction prompt
	_interactable = null
	if not player.dead and not player.input_locked and player.climbing == null:
		var best := 3.5
		for n in get_tree().get_nodes_in_group("interactables"):
			var d: float = (n as Node3D).global_position.distance_to(player.global_position)
			if d < best:
				best = d
				_interactable = n
	hud.set_prompt(("[F]  " + _interactable.prompt()) if _interactable else "")


var quests: QuestManager
var respawn_time := 60.0          # seconds before a killed (non-boss) enemy returns
var _interactable: Node
var _respawns: Array = []        # {"t": time, "type": String, "pos": Vector3}
var _gather_items: Array = []
var _talking: QuestGiver
var _weather: CPUParticles3D
var lava_zones: Array = []       # [Vector2 center, float radius, float level]
var _lava_tick := 0.0


var _inv_ui: InventoryUI
var trader_stock: Array = []
var portal: VesPortal
var town_npcs: Dictionary = {}    # id -> QuestGiver built by towns (king, mayor, traders...)
var nav_areas: Array = []        # [Vector3 centre, float radius] - where navigation meshes are baked
var journey: Journey
var _ui: Control


func _ui_open() -> bool:
	return (_ui and is_instance_valid(_ui) and not _ui.is_queued_for_deletion()) or (_inv_ui and is_instance_valid(_inv_ui) and not _inv_ui.is_queued_for_deletion())


## VesPer's portal: pick where to go.
func open_travel() -> void:
	if _ui_open():
		return
	var t := TravelUI.new()
	t.world = self
	hud.root.add_child(t)
	_ui = t


## A white flash, then off to another location.
func travel(i: int) -> void:
	if journey:
		journey.before_travel(i)
	store_state()
	player.input_locked = true
	var flash := ColorRect.new()
	flash.color = Color(0.7, 0.9, 1.0, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.root.add_child(flash)
	Game.stinger("strange")
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 1.0, 0.6)
	tw.tween_callback(func() -> void: Game.travel_to(i))


## Crafting window: "field" (anywhere), "forge", "workbench" or "alchemy".
func open_craft(station: String) -> void:
	if _ui_open():
		return
	var c := CraftUI.new()
	c.world = self
	c.station = station
	hud.root.add_child(c)
	_ui = c


## VesPer finished his portals (after his drone quest).
func portal_unlocked() -> void:
	for p in get_tree().get_nodes_in_group("portals"):
		p.refresh()
	hud.show_message(Loc.t("VesPer built a portal in the village - use it to travel between lands"), Color(0.55, 0.9, 1.0), 6.0)
	Game.play_sound("blink", null, -4.0, 0.7)


## Crafting materials to gather: ore veins, herbs, mushrooms, logs, sulfur, clams on the beach.
func _spawn_gather_nodes() -> void:
	var kinds := Crafting.node_kinds(Game.level_index)
	var r := RandomNumberGenerator.new()
	r.seed = cfg.get("seed", 1) * 7 + 3
	var placed := 0
	var tries := 0
	while placed < 48 and tries < 600:
		tries += 1
		var kind: String = kinds[r.randi() % kinds.size()]
		var p := Vector3(r.randf_range(-half * 0.85, half * 0.85), 0, r.randf_range(-half * 0.85, half * 0.85))
		if kind == "clam":
			if not cfg.has("sea_z"):
				continue
			p.z = float(cfg["sea_z"]) - r.randf_range(2.0, 12.0)
		elif not _free_for_node(p):
			continue
		var g := GatherNode.new()
		g.world = self
		g.kind = kind
		g.position = Vector3(p.x, ground(p.x, p.z), p.z)
		add_child(g)
		placed += 1


func _free_for_node(p: Vector3) -> bool:
	var p2 := Vector2(p.x, p.z)
	for z in zones:
		if p2.distance_to(z[0]) < float(z[1]) + 3.0:
			return false
	for a in building_areas:
		if p2.distance_to(a[0]) < float(a[1]) + 2.0:
			return false
	for wz in water_zones:
		if p2.distance_to(wz[0]) < float(wz[1]) + 2.0 and ground(p.x, p.z) < float(wz[2]) + 0.5:
			return false
	for l in lakes:
		if p2.distance_to(l[0]) < float(l[1]) + 3.0:
			return false
	for lz in lava_zones:
		if p2.distance_to(lz[0]) < float(lz[1]) + 3.0:
			return false
	if cfg.has("sea_z") and p.z > float(cfg["sea_z"]) - 14.0:
		return false
	return true


var _music_t := 0.0
var _combat_hold := 0.0
var _victory_hold := 0.0
var _music_mode := ""
var _music_track := ""
var _track_t := 0.0                 # seconds the current track has been playing
var _pool_pos := {}                 # mode -> index into its playlist (they rotate)


## Music follows what's happening: rock for a boss fight, battle music when monsters are after
## you (it lingers a few seconds), a heroic theme after finishing the location, mystical music in
## caves, the town theme inside a big town, otherwise the location's day or night playlist.
## Playlists rotate: a track plays through (short loops twice) and then the next one starts.
func _update_music() -> void:
	if player == null or day_night == null:
		return
	var set: Dictionary = Game.MUSIC[Game.level_index]
	var p := player.global_position
	var fighting := false
	var boss := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.neutral and e.state == Enemy.State.CHASE and e.foe == null and e.global_position.distance_to(p) < 45.0:
			fighting = true
			if e.boss:
				boss = true
				break
	_combat_hold = 10.0 if fighting else maxf(0.0, _combat_hold - 1.0)
	_victory_hold = maxf(0.0, _victory_hold - 1.0)
	_track_t += 1.0
	var mode := "day"
	var pool: Array = set["day"]
	if boss:
		mode = "boss"
		pool = Game.MUSIC_BOSS
	elif _combat_hold > 0.0:
		mode = "combat"
		pool = Game.MUSIC_COMBAT + [set["combat"]]
	elif _victory_hold > 0.0:
		mode = "victory"
		pool = [Game.MUSIC_VICTORY]
	elif cave_dim < 0.8:
		mode = "cave"
		pool = Game.MUSIC_CAVE
	else:
		for v: Village in villages:
			if v.city and Vector2(p.x - v.center.x, p.z - v.center.z).length() < v.wall_r:
				mode = "capital" if v.style == "city_capital" else "town"
				pool = Game.MUSIC_CAPITAL if mode == "capital" else Game.MUSIC_TOWN
		if mode == "day" and day_night.is_night():
			mode = "night"
			pool = set["night"]
	# a fight keeps its track (a boss fight goes from battle music straight to rock)
	if mode == "combat" and _music_mode == "combat":
		return
	if mode != _music_mode:
		_music_mode = mode
		if mode in ["combat", "boss"]:
			_pool_pos[mode] = randi() % pool.size()
		_start_track(pool[int(_pool_pos.get(mode, 0)) % pool.size()], mode)
		return
	var length := Game.music_length(_music_track)
	var plays := 2.0 if length < 70.0 else 1.0
	if pool.size() > 1 and length > 0.0 and _track_t > length * plays - 4.0:
		_pool_pos[mode] = int(_pool_pos.get(mode, 0)) + 1
		_start_track(pool[int(_pool_pos[mode]) % pool.size()], mode)


func _start_track(key: String, mode: String) -> void:
	if key == _music_track:
		return
	_music_track = key
	_track_t = 0.0
	var loud := mode in ["combat", "boss", "victory"]
	Game.play_music(key, 1.5 if loud else 4.0, Game.MUSIC_DB_COMBAT if loud else Game.MUSIC_DB)


## Respawn point: in front of the portal (once built), else the location's start.
func respawn_point() -> Vector3:
	if portal and portal.is_built():
		return portal.arrival_point()
	var s: Vector3 = cfg["player_start"]
	return Vector3(s.x, ground(s.x, s.z) + 0.3, s.z)


## Opens the inventory window ("bag"), a trader's shop ("trade") or the stash ("stash").
func open_inventory(mode := "bag", trader := "") -> InventoryUI:
	if _inv_ui and is_instance_valid(_inv_ui) and not _inv_ui.is_queued_for_deletion():
		return _inv_ui
	if mode == "trade" and trader_stock.is_empty():
		var zl := zone_levels()
		trader_stock.resize(16)
		for i in 10:
			trader_stock[i] = Items.generate(randi_range(zl.x, zl.y), Items.roll_quality(0.6), "", "", 0.6)
	_inv_ui = InventoryUI.new()
	_inv_ui.world = self
	_inv_ui.mode = mode
	_inv_ui.shop = trader_stock
	_inv_ui.trader_name = trader
	hud.root.add_child(_inv_ui)
	return _inv_ui


func interact() -> void:
	if _interactable and is_instance_valid(_interactable):
		_interactable.interact()


# --------------------------------------------------------------------------- dialogue

func talk(npc: QuestGiver) -> void:
	_talking = npc
	# replies every conversation can have: travel quests, trading
	var extra: Array = journey.options_for(npc.id, npc) if journey else []
	if npc.role == "trader":
		extra.append([Loc.t("Trade"), func() -> void:
			end_dialogue()
			open_shop(npc)])
	var leave := [Loc.t("Go away"), end_dialogue]
	var q := quests.ready_for(npc.id)
	if not q.is_empty():
		var qid: String = q["id"]
		_say(npc, q["lines"]["done"], q["title"], [[Loc.t("Complete Quest"), func() -> void:
			quests.complete(qid)
			if not quests.available_for(npc.id).is_empty() and not finished:
				talk(npc)
			else:
				end_dialogue()]] + extra + [leave])
		return
	q = quests.available_for(npc.id)
	if not q.is_empty():
		var qid: String = q["id"]
		_say(npc, q["lines"]["offer"], q["title"], [[Loc.t("Accept"), func() -> void:
			quests.accept(qid)
			end_dialogue()]] + extra + [[Loc.t("Not now"), end_dialogue]])
		return
	var line := npc.id + ("_wait" if not quests.active_for(npc.id).is_empty() else "_hello")
	if not QuestManager.dialogue().get("lines", {}).has(line):
		line = "shop_hello_" + ("f" if npc.model_file.begins_with("people/woman") else "m")
	_say(npc, line, "", extra + [leave])


## A trader's shop window (their stock is kept while you're in the location).
func open_shop(npc: QuestGiver) -> void:
	if npc.stock.is_empty():
		var zl := zone_levels()
		npc.stock.resize(16)
		var kind: String = {"weapons": "weapon", "armor": "armor"}.get(npc.shop_kind, "")
		var n := 0 if npc.shop_kind == "alchemy" else 10
		for i in n:
			npc.stock[i] = Items.generate(randi_range(zl.x, zl.y), Items.roll_quality(0.6), kind, "", 0.6)
	var ui := open_inventory("trade", npc.display_name)
	ui.shop = npc.stock
	ui.shop_kind = npc.shop_kind
	ui.refresh()

func _say(npc: QuestGiver, line_id: String, quest_title: String, buttons: Array) -> void:
	var dur := npc.speak(line_id)
	player.input_locked = true
	var lid := Loc.line(line_id)
	hud.show_dialogue(npc.display_name, Loc.t(npc.title), Loc.t(quest_title), QuestManager.line_text(lid), buttons, dur, QuestManager.line_translation(lid))


func end_dialogue() -> void:
	if _talking and is_instance_valid(_talking):
		_talking.stop_speaking()
	_talking = null
	player.input_locked = false
	hud.hide_dialogue()


# --------------------------------------------------------------------------- quests support

func spawn_boss(type: String, pos: Vector3) -> void:
	var e := Enemy.new()
	e.type = type
	e.world = self
	e.level = zone_levels().y + 2
	var size: Vector2 = _enemy_size(type)
	e.position = free_spot(clear_of_npcs(pos), size.x, size.y) + Vector3(0, 0.3, 0)
	add_child(e)
	e.died.connect(_on_enemy_died)
	Fx.light_flash(self, e.position + Vector3(0, 2, 0), Color(1.0, 0.3, 0.2), 6.0, 15.0, 1.5)
	hud.show_message(Loc.t("%s has appeared! (check the map)") % e.display_name, Color(1.0, 0.45, 0.25), 3.0)


func spawn_gather_item(quest_id: String, item: String, pos: Vector3) -> void:
	var g := GatherItem.new()
	g.world = self
	g.quest_id = quest_id
	g.item = item
	add_child(g)
	# a spot with y > 0.5 is that high above the ground (e.g. up in a tree)
	g.global_position = Vector3(pos.x, ground(pos.x, pos.z) + (pos.y if pos.y > 0.5 else 0.0), pos.z)
	_gather_items.append(g)


func clear_gather_items(quest_id: String) -> void:
	for g in _gather_items:
		if is_instance_valid(g) and g.quest_id == quest_id:
			g.queue_free()


## After Captain Bones: a moment for the quest-complete banner, then the ending cinematic.
func start_ending() -> void:
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if is_inside_tree():
			Game.play_ending())


func location_complete() -> void:
	if Game.is_last_level():
		hud.show_message(Loc.t("All quests complete!"), Color(1.0, 0.85, 0.35), 3.0)
		get_tree().create_timer(3.0).timeout.connect(_finish.bind(true))
	else:
		_level_cleared()


func _process_respawns() -> void:
	for i in range(_respawns.size() - 1, -1, -1):
		var r: Dictionary = _respawns[i]
		if elapsed < r["t"]:
			continue
		var pos: Vector3 = r["pos"]
		if not Enemy.TYPES[r["type"]].get("guard", false):
			pos = clear_of_npcs(pos)
		# don't pop in right next to the player - but never hold a camp empty for more than 20 s extra
		if player.global_position.distance_to(pos) < 20.0 and r.get("waited", 0.0) < 20.0:
			r["t"] = elapsed + 5.0
			r["waited"] = r.get("waited", 0.0) + 5.0
			continue
		_respawns.remove_at(i)
		var e := Enemy.new()
		e.type = r["type"]
		e.world = self
		e.level = enemy_level_at(pos)
		e.elite = randf() < 0.06
		var size: Vector2 = _enemy_size(e.type)
		e.position = free_spot(pos, size.x, size.y) + Vector3(0, 0.3, 0)
		e.set_meta("spawn", [r["type"], pos])
		add_child(e)
		e.died.connect(_on_enemy_died)
		enemies_alive += 1


func _process_lava(delta: float) -> void:
	_lava_tick -= delta
	if _lava_tick > 0.0 or player.dead:
		return
	_lava_tick = 0.5
	for lz in lava_zones:
		var c: Vector2 = lz[0]
		if c.distance_to(Vector2(player.global_position.x, player.global_position.z)) < float(lz[1]) and player.global_position.y < float(lz[2]) + 0.4:
			player.take_damage(9.0, player.global_position + Vector3(0, -1, 0))
			hud.show_message(Loc.t("You are burning in the lava!"), Color(1.0, 0.4, 0.1), 0.8)
			return


func _build_weather(kind: String) -> void:
	if kind == "":
		return
	_weather = CPUParticles3D.new()
	var m := SphereMesh.new()
	m.radial_segments = 4
	m.rings = 2
	if kind == "snow":
		m.radius = 0.04
		m.height = 0.08
		m.material = MeshKit.unshaded(Color(0.95, 0.97, 1.0))
		_weather.amount = 900
		_weather.lifetime = 7.0
		_weather.gravity = Vector3(0.4, -1.6, 0.2)
	else:
		m.radius = 0.035
		m.height = 0.07
		m.material = MeshKit.unshaded(Color(1.0, 0.5, 0.15))
		_weather.amount = 400
		_weather.lifetime = 6.0
		_weather.gravity = Vector3(0.3, 1.0, 0.1)
	_weather.mesh = m
	_weather.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_weather.emission_box_extents = Vector3(30, 8, 30)
	_weather.local_coords = false
	_weather.direction = Vector3.DOWN
	_weather.spread = 30.0
	_weather.initial_velocity_min = 0.2
	_weather.initial_velocity_max = 1.0
	_weather.preprocess = 6.0
	add_child(_weather)


# --------------------------------------------------------------------------- API for level scripts

func ground(x: float, z: float) -> float:
	return terrain.height_at(x, z) if terrain else 0.0


func add_path(a: Vector2, b: Vector2, width := 4.0) -> void:
	path_segments.append([a, b, width])


func add_zone(c: Vector2, r: float) -> void:
	zones.append([c, r])


func add_lake(c: Vector2, r: float, depth: float) -> void:
	lakes.append([c, r, depth])


func paint_rect(r: Rect2, channel: int) -> void:
	paint_ops.append(["rect", r, channel])


func paint_circle(c: Vector2, r: float, channel: int) -> void:
	paint_ops.append(["circle", c, r, channel])


func add_landmark(lname: String, pos: Vector2, radius: float, color: Color) -> void:
	landmarks.append({"name": lname, "pos": pos, "radius": radius, "color": color})


## Reserves flat ground for a landmark near `hint` (searching outward) and builds it later:
## "crypt", "ruined_castle", "fishing_hut", "gatehouse", "watchtower", "sawmill", "granary".
func plan_feature(type: String, hint: Vector3, radius: float, label := "") -> void:
	for ring in range(0, 12):
		var steps := 1 if ring == 0 else 10
		for k in steps:
			var a := TAU * k / steps + ring
			var p := hint + Vector3(cos(a), 0, sin(a)) * ring * 8.0
			if maxf(absf(p.x), absf(p.z)) > half - 40.0 - radius:
				continue
			if is_clear(Vector2(p.x, p.z), radius):
				add_zone(Vector2(p.x, p.z), radius)
				features.append([type, p, rad_to_deg(atan2(-p.x, -p.z))])
				if label != "":
					add_landmark(label, Vector2(p.x, p.z), radius * 0.6, Color(0.55, 0.55, 0.6))
				return


func _build_features() -> void:
	var frng := RandomNumberGenerator.new()
	frng.seed = int(cfg.get("seed", 1)) * 7
	for f in features:
		var p: Vector3 = f[1]
		var yaw: float = f[2]
		match f[0]:
			"crypt":
				var r := VBuild.crypt(self, p, yaw)
				var chest := TreasureChest.new()
				chest.world = self
				add_child(chest)
				chest.global_position = r["treasure"] + Vector3(0, 0.2, 0)
				chest.rotation.y = deg_to_rad(yaw)
				var types: Array = []
				for e in get_tree().get_nodes_in_group("enemies"):
					if not e.neutral and not e.boss and not types.has(e.type):
						types.append(e.type)
				if not types.is_empty():
					for i in 3:
						var e := Enemy.new()
						e.type = types[frng.randi() % types.size()]
						e.world = self
						e.level = zone_levels().y
						e.elite = i == 0
						e.position = r["inside"] + Vector3(frng.randf_range(-1.5, 1.5), 0.3, frng.randf_range(-2, 2))
						e.set_meta("spawn", [e.type, r["inside"]])
						add_child(e)
						e.died.connect(_on_enemy_died)
			"ruined_castle":
				VBuild.ruined_castle(self, p, yaw, frng)
				var chest := TreasureChest.new()
				chest.world = self
				add_child(chest)
				chest.global_position = free_spot(p + Vector3(2, 0, 2), 0.7, 1.0)
			"fishing_hut":
				VBuild.fishing_hut(self, p, yaw)
			"gatehouse":
				VBuild.gatehouse(self, p, yaw)
			"watchtower":
				VBuild.watchtower(self, p, yaw)
			"sawmill":
				VBuild.sawmill(self, p, yaw)
			"granary":
				VBuild.granary(self, p, yaw)


func is_clear(p: Vector2, margin: float) -> bool:
	for z in zones:
		var c: Vector2 = z[0]
		if p.distance_to(c) < float(z[1]) + margin:
			return false
	for l in lakes:
		var lc: Vector2 = l[0]
		if p.distance_to(lc) < float(l[1]) * 1.15 + margin:
			return false
	for seg in path_segments:
		if Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) < float(seg[2]) * 0.5 + 1.5 + margin:
			return false
	return true


# --------------------------------------------------------------------------- game flow

## Nearest spot to `p` (searching outward in rings) where a creature of the given size
## doesn't overlap buildings, rocks, trees or props. Returns a point on the ground.
func free_spot(p: Vector3, radius := 0.6, height := 2.0) -> Vector3:
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = 1
	var space := get_world_3d().direct_space_state
	for ring in range(0, 14):
		var count := 1 if ring == 0 else 10 + ring * 2
		for i in count:
			var a := TAU * i / count + ring * 0.37
			var c := Vector3(p.x + cos(a) * ring * 1.2, 0, p.z + sin(a) * ring * 1.2)
			var gy := ground(c.x, c.z)
			# capsule floats 0.35 m above the ground so the terrain itself isn't counted
			q.transform = Transform3D(Basis(), Vector3(c.x, gy + 0.35 + height * 0.5, c.z))
			if space.intersect_shape(q, 1).is_empty():
				return Vector3(c.x, gy, c.z)
	return Vector3(p.x, ground(p.x, p.z), p.z)


const NPC_SAFE_RADIUS := 32.0   # hostile monsters never spawn closer than this to a quest giver


## Where quest givers stand (level NPCs, town folk such as the King and traders, VesPer's portal).
func _npc_safe_points() -> Array:
	var pts := []
	if level.has_method("npcs"):
		for n in level.npcs():
			pts.append(n["pos"])
	for id in town_npcs:
		if is_instance_valid(town_npcs[id]):
			pts.append((town_npcs[id] as Node3D).global_position)
	if quests:
		for id in quests.npcs:
			if is_instance_valid(quests.npcs[id]):
				pts.append((quests.npcs[id] as Node3D).global_position)
	if portal and is_instance_valid(portal):
		pts.append(portal.global_position)
	return pts


## Moves a hostile spawn point out of the quest givers' safe circles (straight away from the NPC),
## so nobody has to fight a camp just to talk to someone.
func clear_of_npcs(p: Vector3, radius := NPC_SAFE_RADIUS, pts: Array = []) -> Vector3:
	if pts.is_empty():
		pts = _npc_safe_points()
	for iter in 6:
		var moved := false
		for q: Vector3 in pts:
			var d := Vector2(p.x - q.x, p.z - q.z)
			if d.length() < radius:
				if d.length() < 0.5:
					d = Vector2(1, 0).rotated(randf() * TAU)
				var np := Vector2(q.x, q.z) + d.normalized() * (radius + 1.0)
				p = Vector3(clampf(np.x, -half + 20.0, half - 20.0), p.y, clampf(np.y, -half + 20.0, half - 20.0))
				moved = true
		if not moved:
			break
	return p


func _spawn_enemies(list: Array) -> void:
	var safe := _npc_safe_points()
	for entry in list:
		var p: Vector3 = entry[1]
		if not Enemy.TYPES[entry[0]].get("guard", false):
			p = clear_of_npcs(p, NPC_SAFE_RADIUS, safe)
		var e := Enemy.new()
		e.type = entry[0]
		e.world = self
		e.level = enemy_level_at(p)
		e.elite = not Enemy.TYPES[e.type].get("boss", false) and randf() < 0.06
		var size: Vector2 = _enemy_size(e.type)
		var spot := free_spot(p, size.x, size.y)
		e.position = spot + Vector3(0, 0.3, 0)
		e.set_meta("spawn", [entry[0], p])     # respawns come back here, outside the safe circles
		add_child(e)
		e.died.connect(_on_enemy_died)
	enemies_total = list.size()
	enemies_alive = enemies_total


## (capsule radius, height) used when checking spawn space.
func _enemy_size(type: String) -> Vector2:
	var cfg: Dictionary = Enemy.TYPES[type]
	var s: float = cfg["scale"]
	if type == "wolf" or type == "spider":
		return Vector2(0.55, 1.2)
	return Vector2(0.4 * s, maxf(cfg["height"], 1.0))


## Adds an enemy mid-fight (necromancer summons). Counts toward the total.
func spawn_extra(type: String, p: Vector3) -> void:
	if finished:
		return
	var e := Enemy.new()
	e.type = type
	e.world = self
	e.level = enemy_level_at(p)
	e.summoned = true
	e.position = free_spot(p) + Vector3(0, 0.3, 0)
	add_child(e)
	e.died.connect(_on_enemy_died)
	enemies_total += 1
	enemies_alive += 1
	e.call_deferred("aggro")


func _on_enemy_died(e: Enemy) -> void:
	enemies_alive -= 1
	kills += 1
	hud.on_kill(e.display_name)
	var xp := e.xp_value()
	var gap: int = int(Game.progress["level"]) - e.level
	if gap >= 6:
		xp = int(xp * maxf(0.1, 1.0 - (gap - 5) * 0.2))
	player.add_xp(xp)
	hud.show_xp(xp)
	var heal := player.eq("lifesteal")
	if heal > 0.0:
		player.health = minf(player.max_health, player.health + heal)
	_drop_loot(e)
	quests.on_enemy_killed(e)
	if journey:
		journey.on_enemy_killed(e)
	if e.has_meta("spawn") and not e.boss:
		var sp: Array = e.get_meta("spawn")
		_respawns.append({"t": elapsed + respawn_time, "type": sp[0], "pos": sp[1]})
	if e.summoned:
		return
	var base := Vector3(e.global_position.x, 0, e.global_position.z)
	if e.boss or randf() < 0.7:
		var ammo := AmmoPickup.new()
		ammo.amount = 60 if e.boss else 30
		add_child(ammo)
		ammo.global_position = base + Vector3(0, ground(base.x, base.z), 0)
	var potion_chance := 1.0 if e.boss else (0.4 if e.ranged else 0.2)
	if randf() < potion_chance:
		var potion := AmmoPickup.new()
		potion.kind = "mana"
		add_child(potion)
		var pp := base + Vector3(0.9, 0, 0.6)
		potion.global_position = pp + Vector3(0, ground(pp.x, pp.z), 0)


## Enemy level for a spot: low near the player's start, highest far away; zone range from Game.
func zone_levels() -> Vector2i:
	return Game.ZONE_LEVELS[Game.level_index]


func enemy_level_at(p: Vector3) -> int:
	var zl := zone_levels()
	var start: Vector3 = cfg["player_start"]
	var t := clampf(Vector2(p.x - start.x, p.z - start.z).length() / (half * 1.5), 0.0, 1.0)
	return clampi(int(round(lerpf(zl.x, zl.y, t))) + randi_range(-1, 1), zl.x, zl.y)


## Gold and sometimes an item from a dead enemy (elites and bosses always drop something good).
func _drop_loot(e: Enemy) -> void:
	if e.summoned:
		return
	var base := e.global_position
	if randf() < (1.0 if e.boss or e.elite else 0.55):
		var coins := int(randi_range(2, 6) * e.level * (6.0 if e.boss else (3.0 if e.elite else 1.0)))
		LootDrop.spawn(self, base + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), {}, coins)
	if not e.neutral:
		MaterialDrop.spawn(self, base + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8)), Crafting.roll_drops(e.type, e.elite, e.boss))
	var drops := 0
	if e.boss:
		drops = 2
	elif e.elite or randf() < 0.07:
		drops = 1
	for i in drops:
		var luck := 2.0 if e.boss else (1.0 if e.elite else 0.0)
		var it := Items.generate(e.level, Items.roll_quality(luck, 2 if e.boss else 0), "", "", luck)
		LootDrop.spawn(self, base + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2)), it)


## Copies the player's state into Game before saving.
func store_state() -> void:
	if player and is_instance_valid(player):
		player.weapon_item["mag"] = player.mag
		Game.carry = {"reserve": player.reserve}


# --------------------------------------------------------------------------- weather / wildlife / night

## "clear", "rain", "storm" or "fog". Levels with their own weather (snow, embers) keep it.
func set_weather(kind: String) -> void:
	weather = kind
	if _rain and is_instance_valid(_rain):
		_rain.queue_free()
		_rain = null
	environment.fog_density = cfg.get("fog_density", 0.004) * 1.8 * (3.0 if kind == "fog" else (1.6 if kind in ["rain", "storm"] else 1.0))
	if day_night:
		day_night._base["fog_density"] = environment.fog_density
		day_night._base["sun_energy"] = cfg.get("sun_energy", 1.3) * (0.45 if kind in ["rain", "storm"] else (0.7 if kind == "fog" else 1.0))
		var cover: float = 0.95 if kind in ["rain", "storm"] else cfg["sky"].get("cloud_cover", 0.5)
		if sky3d:
			sky3d.get("sky").set("cumulus_coverage", cover)
			sky3d.get("sky").set("cirrus_coverage", 0.9 if kind in ["rain", "storm"] else 0.5)
		elif day_night._sky_mat:
			day_night._sky_mat.set_shader_parameter("cloud_cover", cover)
	if kind == "rain" or kind == "storm":
		_rain = CPUParticles3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.012, 0.45, 0.012)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.7, 0.75, 0.85, 0.35)
		m.material = mat
		_rain.mesh = m
		_rain.amount = 2200 if kind == "storm" else 1400
		_rain.lifetime = 1.4
		_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_rain.emission_box_extents = Vector3(28, 2, 28)
		_rain.local_coords = false
		_rain.direction = Vector3(0.15, -1, 0.05)
		_rain.spread = 3.0
		_rain.gravity = Vector3(0, -12, 0)
		_rain.initial_velocity_min = 16.0
		_rain.initial_velocity_max = 20.0
		_rain.preprocess = 1.5
		add_child(_rain)


func _process_weather(delta: float) -> void:
	if _rain and is_instance_valid(_rain):
		_rain.global_position = player.global_position + Vector3(0, 14, 0)
	if weather == "storm":
		_storm_t -= delta
		if _storm_t <= 0.0:
			_storm_t = randf_range(6.0, 18.0)
			var a := randf() * TAU
			var p := player.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(60, 150)
			Fx.light_flash(self, p + Vector3(0, 80, 0), Color(0.75, 0.8, 1.0), 14.0, 400.0, 0.35)
			get_tree().create_timer(randf_range(0.6, 2.0)).timeout.connect(func() -> void:
				Game.play_sound("explosion", p, 10.0, 0.35))
	# levels without their own weather change it now and then
	if cfg.get("weather", "") == "":
		_weather_t -= delta
		if _weather_t <= 0.0:
			_weather_t = randf_range(240.0, 600.0)
			var r := randf()
			set_weather("clear" if r < 0.5 else ("rain" if r < 0.72 else ("fog" if r < 0.88 else "storm")))


func _spawn_wildlife() -> void:
	var lush: bool = cfg.get("shrubs", true)
	var kinds: Array = ["deer", "deer", "rabbit", "rabbit", "rabbit", "crow"] if lush else ["crow", "crow", "rabbit"]
	if cfg.get("weather", "") == "embers":
		kinds = ["crow"]
	var count := int(28 * pow(half / 140.0, 2.0) * 0.18)
	for i in count:
		var p := _random_point(30.0)
		if not is_clear(p, 1.0):
			continue
		var k: String = kinds[rng.randi() % kinds.size()]
		var n := 1 if k == "deer" else (3 if k == "crow" else 2)
		for j in n:
			add_animals(k, Vector3(p.x + rng.randf_range(-3, 3), 0, p.y + rng.randf_range(-3, 3)), 1)


func add_animals(kind: String, pos: Vector3, count: int) -> void:
	for i in count:
		var a := Animal.new()
		a.world = self
		a.kind = kind
		a.owned = kind == "chicken"
		var q := pos + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))
		a.position = Vector3(q.x, ground(q.x, q.z) + 0.2, q.z)
		add_child(a)


## At night extra packs of monsters roam near the player (stronger, outside villages).
func _process_night(delta: float) -> void:
	_night_t -= delta
	if _night_t > 0.0:
		return
	_night_t = 45.0
	for e in _night_spawned.duplicate():
		if not is_instance_valid(e) or e.state == Enemy.State.DEAD:
			_night_spawned.erase(e)
	if not day_night.is_night():
		# at dawn the night creatures crumble away
		for e in _night_spawned:
			if is_instance_valid(e) and e.state == Enemy.State.IDLE and e.global_position.distance_to(player.global_position) > 30.0:
				e.queue_free()
		_night_spawned.clear()
		return
	if _night_spawned.size() >= 10:
		return
	var types: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.neutral and not e.boss and not types.has(e.type):
			types.append(e.type)
	if types.is_empty():
		return
	var v = level.get("village")
	for tries in 10:
		var a := randf() * TAU
		var p := player.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(45.0, 70.0)
		if maxf(absf(p.x), absf(p.z)) > half - 40.0:
			continue
		if v and Vector2(p.x - v.center.x, p.z - v.center.z).length() < 45.0:
			continue
		if clear_of_npcs(p, NPC_SAFE_RADIUS + 10.0) != p:
			continue
		var t: String = types[randi() % types.size()]
		for i in randi_range(2, 4):
			var e := Enemy.new()
			e.type = t
			e.world = self
			e.level = enemy_level_at(p) + 2
			e.position = free_spot(p + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))) + Vector3(0, 0.3, 0)
			add_child(e)
			e.died.connect(_on_enemy_died)
			_night_spawned.append(e)
		break


# --------------------------------------------------------------------------- roaming terror

## Locations where a rare giant dinosaur (the Wandering Terror) roams the whole map.
const ROAMER_LEVELS := [1, 2, 3, 5]
var _roamer: Enemy
var _roamer_t := randf_range(90.0, 200.0)   # seconds until it (re)appears
var _roamer_goal := Vector3.ZERO
var _roamer_step := 0.0
var _roamer_seen := false


## A random far point it may walk to: inside the map, away from villages, towns and quest givers.
func _roamer_point(near: Vector3, min_d: float, max_d: float) -> Vector3:
	var safe := _npc_safe_points()
	for tries in 30:
		var a := randf() * TAU
		var p := near + Vector3(cos(a), 0, sin(a)) * randf_range(min_d, max_d)
		if maxf(absf(p.x), absf(p.z)) > half - 45.0:
			continue
		var ok := true
		for v: Village in villages:
			if Vector2(p.x - v.center.x, p.z - v.center.z).length() < (v.wall_r if v.city else 40.0) + 25.0:
				ok = false
		if ok and clear_of_npcs(p, NPC_SAFE_RADIUS + 15.0, safe) == p:
			return Vector3(p.x, ground(p.x, p.z), p.z)
	return Vector3.INF


func _process_roamer(delta: float) -> void:
	if not Game.level_index in ROAMER_LEVELS:
		return
	if _roamer == null or not is_instance_valid(_roamer):
		_roamer = null
		_roamer_t -= delta
		if _roamer_t > 0.0:
			return
		_roamer_t = 30.0
		var p := _roamer_point(player.global_position, 110.0, 170.0)
		if p == Vector3.INF:
			return
		var e := Enemy.new()
		e.type = "wild_dino"
		e.world = self
		e.level = zone_levels().y + 3
		e.position = free_spot(p, 0.9, 3.0) + Vector3(0, 0.3, 0)
		add_child(e)
		e.died.connect(_on_enemy_died)
		e.died.connect(func(_e: Enemy) -> void:
			hud.show_message(Loc.t("The Wandering Terror is slain!"), Color(1.0, 0.85, 0.4), 3.0)
			_roamer_t = randf_range(720.0, 1080.0))
		enemies_alive += 1
		_roamer = e
		_roamer_seen = false
		_roamer_goal = _roamer_point(p, 60.0, 140.0)
		return
	if _roamer.state == Enemy.State.DEAD:
		return
	var d := _roamer.global_position.distance_to(player.global_position)
	if not _roamer_seen and d < 70.0:
		_roamer_seen = true
		hud.show_message(Loc.t("The ground shakes... a Wandering Terror roams nearby!"), Color(1.0, 0.55, 0.3), 3.5)
		Game.play_sound("roar", _roamer.global_position, 6.0, 0.55)
	# it walks from place to place across the map (moving its home), unless it's hunting someone
	_roamer_step -= delta
	if _roamer_step > 0.0 or _roamer.state != Enemy.State.IDLE:
		return
	_roamer_step = 6.0
	if _roamer_goal == Vector3.INF or Vector2(_roamer.home.x - _roamer_goal.x, _roamer.home.z - _roamer_goal.z).length() < 8.0:
		_roamer_goal = _roamer_point(_roamer.home, 60.0, 140.0)
		return
	var nh := _roamer.home.move_toward(Vector3(_roamer_goal.x, _roamer.home.y, _roamer_goal.z), 9.0)
	_roamer.home = Vector3(nh.x, ground(nh.x, nh.z), nh.z)
	if d > 95.0:
		# far away and unseen: it just moves along (idle enemies far from you are paused)
		_roamer.global_position = _roamer.home + Vector3(0, 0.3, 0)


# --------------------------------------------------------------------------- crime / guards

## Called when the player hurts (1), badly hurts (2) or kills (3) a villager or guard.
func report_crime(severity: int, pos: Vector3) -> void:
	if OS.has_environment("SHOT_MODE"):
		print("CRIME ", severity, " from ", get_stack())
	var old := wanted_stars
	if severity > wanted_stars:
		wanted_stars = severity
	elif _escalate_t <= 0.0:
		wanted_stars += 1
	wanted_stars = clampi(wanted_stars, 1, 5)
	if wanted_stars != old:
		_escalate_t = 15.0
	_wanted_t = 25.0 + wanted_stars * 15.0
	if old == 0:
		hud.show_message(Loc.t("Crime! The guards are after you"), Color(1.0, 0.3, 0.25), 3.0)
		Game.play_sound("bell" if Game.sounds.has("bell") else "level_up", pos, 2.0, 0.8)
	var reach := 60.0 + wanted_stars * 25.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.neutral and e.global_position.distance_to(pos) < reach:
			e.aggro()


func _process_wanted(delta: float) -> void:
	_escalate_t -= delta
	if wanted_stars <= 0:
		return
	var seen := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.neutral and e.state == Enemy.State.CHASE and e._has_los:
			seen = true
			break
	if seen:
		_wanted_t = maxf(_wanted_t, 8.0 + wanted_stars * 4.0)
	else:
		_wanted_t -= delta
	if _wanted_t <= 0.0:
		wanted_stars = 0
		hud.show_message(Loc.t("You lost the guards"), Color(0.6, 1.0, 0.6), 2.5)
		return
	# reinforcements from 2 stars up
	_reinforce_t -= delta
	if wanted_stars >= 2 and _reinforce_t <= 0.0:
		_reinforce_t = 40.0 / wanted_stars
		var guards := 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.neutral:
				guards += 1
		if guards < 4 + wanted_stars * 3:
			var a := randf() * TAU
			var p := player.global_position + Vector3(cos(a), 0, sin(a)) * 38.0
			var g := spawn_guard("guard_archer" if randf() < 0.35 else "guard", p, false)
			g.call_deferred("aggro")


## Adds a town guard (neutral until the player commits a crime).
func spawn_guard(type: String, pos: Vector3, respawn := true) -> Enemy:
	var e := Enemy.new()
	e.type = type
	e.world = self
	e.level = zone_levels().y + 3
	e.position = free_spot(pos, 0.45, 1.8) + Vector3(0, 0.3, 0)
	if respawn:
		e.set_meta("spawn", [type, pos])
	add_child(e)
	e.died.connect(_on_enemy_died)
	return e


## Every quest here is done: a reward, and a hint where to go next (travel by portal).
func _level_cleared() -> void:
	if Game.loc_state().get("complete", false):
		return
	Game.loc_state()["complete"] = true
	Game.stinger("victory")
	_victory_hold = 45.0
	var next: Dictionary = Game.LEVELS[Game.level_index + 1]
	hud.show_level_cleared(next["name"])
	var xp: int = Skills.kill_xp(zone_levels().y, 300.0, true, true) * 3
	player.add_xp(xp)
	player.add_gold(100 * zone_levels().y, true)
	Game.save_now()


func _on_player_died() -> void:
	Game.stinger("death")
	# dying costs a tenth of your gold (a fifth when the guards were after you)
	var fine := int(int(Game.inventory.get("gold", 0)) * (0.2 if wanted_stars > 0 else 0.1))
	Game.inventory["gold"] = int(Game.inventory.get("gold", 0)) - fine
	wanted_stars = 0
	_finish(false)


func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	Game.add_stats(kills, shots_fired, shots_hit, elapsed)
	get_tree().create_timer(1.6).timeout.connect(hud.show_end.bind(win))


func add_bullet_hole(pos: Vector3, normal: Vector3) -> void:
	var q := MeshInstance3D.new()
	q.mesh = _hole_mesh
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(q)
	q.global_position = pos + normal * 0.012
	var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	q.look_at(q.global_position - normal, up)
	_holes.append(q)
	if _holes.size() > 80:
		_holes.pop_front().queue_free()


## Floating combat text.
func damage_number(pos: Vector3, amount: float, kind: String) -> void:
	var l := Label3D.new()
	l.text = str(int(round(amount)))
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.no_depth_test = true
	l.font_size = 48
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 10
	l.outline_render_priority = 9
	match kind:
		"crit":
			l.pixel_size = 0.0016
			l.modulate = Color(1.0, 0.85, 0.15)
			l.text += "!"
		"frost":
			l.pixel_size = 0.0011
			l.modulate = Color(0.55, 0.85, 1.0)
		"fire":
			l.pixel_size = 0.0012
			l.modulate = Color(1.0, 0.55, 0.15)
		"lightning":
			l.pixel_size = 0.0013
			l.modulate = Color(0.75, 0.75, 1.0)
		"heal":
			l.pixel_size = 0.0011
			l.modulate = Color(0.4, 1.0, 0.45)
			l.text = "+" + l.text
		"absorb":
			l.pixel_size = 0.001
			l.modulate = Color(0.75, 0.65, 1.0)
			l.text = Loc.t("absorbed")
		_:
			l.pixel_size = 0.0011
			l.modulate = Color(1, 1, 1)
	add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0.3, randf_range(-0.3, 0.3))
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.3, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


# --------------------------------------------------------------------------- building

func _build_environment() -> void:
	var sky_cfg: Dictionary = cfg["sky"]
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	for key in sky_cfg:
		sky_mat.set_shader_parameter(key, sky_cfg[key])
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = cfg.get("ambient", 1.0)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = cfg.get("exposure", 1.0)
	env.adjustment_enabled = true
	# horror grade: washed-out colours, harder contrast, thicker greyer fog
	env.adjustment_saturation = cfg.get("color_saturation", 1.15) * 0.78
	env.adjustment_contrast = 1.12
	env.fog_enabled = true
	env.fog_light_color = (cfg.get("fog_color", Color(0.7, 0.8, 0.9)) as Color).lerp(Color(0.55, 0.58, 0.6), 0.35)
	env.fog_density = cfg.get("fog_density", 0.004) * 1.8
	env.fog_aerial_perspective = 0.6
	env.fog_sky_affect = 0.3
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.6
	if ResourceLoader.exists(SKY3D_SCRIPT) and not cfg.get("no_sky3d", false):
		_build_sky3d(env)
		apply_quality()
		return
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	environment = env

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = cfg.get("sun_rot", Vector3(-40, -35, 0))
	sun.light_color = cfg.get("sun_color", Color(1.0, 0.92, 0.78))
	sun.light_energy = cfg.get("sun_energy", 1.3)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	add_child(sun)
	apply_quality()


const SKY3D_SCRIPT := "res://addons/sky_3d/src/Sky3D.gd"
var environment: Environment
var sun: DirectionalLight3D
var sky3d: WorldEnvironment         # Sky3D (sky, sun, moon, stars, clouds) when the addon is present


## Sky3D (TokisanGames, MIT): physically based sky with sun, moon, stars and drifting clouds.
## It brings its own Environment, sun and moon; our look (fog, grading, glow, SSAO) is copied onto
## its Environment. DayNight still owns the clock and feeds the hour to Sky3D's TimeOfDay.
func _build_sky3d(template: Environment) -> void:
	sky3d = (load(SKY3D_SCRIPT) as GDScript).new()
	sky3d.name = "Sky3D"
	add_child(sky3d)
	var env: Environment = sky3d.environment
	for prop in ["ambient_light_energy", "tonemap_mode", "tonemap_exposure", "adjustment_enabled", "adjustment_saturation",
			"adjustment_contrast", "fog_enabled", "fog_light_color", "fog_density", "fog_aerial_perspective", "fog_sky_affect",
			"glow_enabled", "glow_intensity", "glow_bloom", "ssao_enabled", "ssao_radius", "ssao_intensity"]:
		env.set(prop, template.get(prop))
	environment = env
	sky3d.set("fog_enabled", false)            # our own fog stays (caves, weather, night)
	sky3d.set("sky_contribution", 0.85)
	sky3d.set("night_sky_contribution", 0.6)
	var tod: Node = sky3d.get("tod")
	tod.set("game_time_enabled", false)        # DayNight drives the time
	tod.set("celestials_calculations", 0)      # SIMPLE: sunrise 6:00, noon overhead, sunset 18:00
	tod.set("utc", 0.0)
	tod.set("longitude", 0.0)
	# the sun's path runs through the level's sun direction (azimuth, folded into -90..90)
	var yaw: float = (cfg.get("sun_rot", Vector3(-40, -35, 0)) as Vector3).y
	tod.set("latitude", deg_to_rad(wrapf(yaw, -90.0, 90.0)))
	var dome: Node = sky3d.get("sky")
	dome.set("sun_light_color", cfg.get("sun_color", Color(1.0, 0.92, 0.78)))
	dome.set("sun_light_energy", cfg.get("sun_energy", 1.3))
	dome.set("moon_light_energy", 0.22)
	dome.set("cumulus_coverage", float(cfg["sky"].get("cloud_cover", 0.55)))
	dome.set("ground_color", cfg["sky"].get("ground_color", Color(0.3, 0.33, 0.3)))
	sun = sky3d.get("sun")
	sun.shadow_blur = 1.5
	var moon: DirectionalLight3D = sky3d.get("moon")
	moon.directional_shadow_max_distance = 80.0
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS


## Applies the Graphics Quality setting (0 Low, 1 Medium, 2 High, 3 Ultra).
func apply_quality() -> void:
	var q: int = Game.settings.get("quality", 2)
	environment.ssao_enabled = q >= 1
	environment.glow_enabled = q >= 1
	environment.ssil_enabled = q >= 3
	environment.ssr_enabled = q >= 3
	sun.directional_shadow_max_distance = [60.0, 90.0, 120.0, 170.0][q]
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if q <= 1 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	RenderingServer.directional_soft_shadow_filter_set_quality([RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][q])
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_2X, Viewport.MSAA_4X][q]
	if player:
		player.camera.far = [250.0, 400.0, 600.0, 800.0][q]


func _grass_mult() -> float:
	return [0.35, 0.65, 1.0, 1.4][Game.settings.get("quality", 2)]


func _random_point(margin: float) -> Vector2:
	return Vector2(rng.randf_range(-half + margin, half - margin), rng.randf_range(-half + margin, half - margin))


func _build_vegetation() -> void:
	# counts in the level configs are for the original 280 m maps; scale them with the area
	var area := pow(half / 140.0, 2.0)
	var count := int(cfg.get("tree_count", 200) * area)
	var spacing: float = cfg.get("tree_spacing", 7.0)
	var pts: Array = []
	var grid := {}    # Vector2i cell -> Array of tree points, for the spacing check
	var tries := 0
	while pts.size() < count and tries < count * 40:
		tries += 1
		var p := _random_point(14.0)
		if not is_clear(p, 3.0) or terrain.slope_at(p.x, p.y) > 0.55:
			continue
		var cell := Vector2i(floori(p.x / spacing), floori(p.y / spacing))
		var crowded := false
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for q: Vector2 in grid.get(cell + Vector2i(dx, dz), []):
					if p.distance_squared_to(q) < spacing * spacing:
						crowded = true
		if crowded:
			continue
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(p)
		tree_points.append(p)
		pts.append(Vector3(p.x, ground(p.x, p.y), p.y))
	# backdrop trees on the mountain rim
	for i in int(cfg.get("tree_count", 200) * 0.45 * area):
		var p := _random_point(6.0)
		if maxf(absf(p.x), absf(p.y)) < half - 30.0 or terrain.slope_at(p.x, p.y) > 0.9:
			continue
		pts.append(Vector3(p.x, ground(p.x, p.y), p.y))
	Nature.plant_trees(self, pts, cfg, rng)

	var lush: bool = cfg.get("shrubs", true)
	var bushes: Array = []
	var shrubs: Array = []
	for i in int(cfg.get("bush_count", 120) * area):
		var p := _random_point(14.0)
		if is_clear(p, 0.5) and ground(p.x, p.y) > -0.2:
			(shrubs if lush and i % 2 == 0 else bushes).append(Vector3(p.x, ground(p.x, p.y), p.y))
	Nature.plant_bushes(self, bushes, cfg.get("bush_foliage", cfg["foliage"]), rng, cfg.get("leaf_snow", 0.0))
	var bt: Array = cfg.get("bush_foliage", cfg["foliage"])
	var plant_tint := Nature._kit_tint(bt[1], Nature.LEAF_REF, cfg.get("leaf_snow", 0.0))
	Nature.plant_kit(self, shrubs, ["Plant_1_Big", "Plant_7_Big", "Plant_1", "Plant_7"], plant_tint, Vector2(1.0, 2.0), 120.0, true, rng)

	# ferns in the undergrowth around the trees
	var ferns: Array = []
	if lush and not tree_points.is_empty():
		for i in int(cfg.get("fern_count", 220) * area):
			var tp: Vector2 = tree_points[rng.randi() % tree_points.size()]
			var p := tp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.5, 6.0)
			if is_clear(p, 0.0) and ground(p.x, p.y) > -0.2:
				ferns.append(Vector3(p.x, ground(p.x, p.y), p.y))
	Nature.plant_kit(self, ferns, ["Fern_1"], plant_tint, Vector2(1.4, 2.6), 60.0, false, rng)
	# flowers, grass clumps, clover, mushrooms and pebbles
	var cover: Array = []
	for i in int(cfg.get("cover_count", 900) * area):
		var p := _random_point(10.0)
		if is_clear(p, 0.3) and ground(p.x, p.y) > -0.1:
			cover.append(Vector3(p.x, ground(p.x, p.y), p.y))
	Nature.scatter_cover(self, cover, cfg, rng)

	# fallen logs
	var logs: Array = []
	for i in int(cfg.get("log_count", 6) * area):
		var p := _random_point(20.0)
		if is_clear(p, 3.0) and terrain.slope_at(p.x, p.y) < 0.3:
			logs.append(Vector3(p.x, ground(p.x, p.y), p.y))
	var wood_tint: Color = Color(1, 1, 1).lerp(cfg.get("bark_tint", Color(1, 1, 1)), 0.4)
	Nature.place_models(self, logs, Nature.model_parts("dead_tree_trunk_02"), rng, Vector2(3.5, 5.0), true, 150.0, wood_tint, false, 0.2)

	var rocks: Array = []
	for i in int(cfg.get("rock_count", 45) * area):
		var p := _random_point(14.0)
		if is_clear(p, 1.5):
			rocks.append(Vector3(p.x, ground(p.x, p.y), p.y))
	var rc: Color = cfg.get("rock_color", Color(1.2, 1.2, 1.2))
	Nature.place_rocks(self, rocks, rng, not cfg.has("rock_color"), Color(rc.r / 1.2, rc.g / 1.2, rc.b / 1.2))

	var grass_mat := ShaderMaterial.new()
	grass_mat.shader = load("res://shaders/grass.gdshader")
	grass_mat.set_shader_parameter("base_color", cfg.get("grass_base", Color(0.22, 0.36, 0.08)))
	grass_mat.set_shader_parameter("tip_color", cfg.get("grass_tip", Color(0.6, 0.66, 0.22)))
	grass_mat.set_shader_parameter("blade_height", 0.5)
	var tuft := Terrain.make_tuft(rng, 10, 0.5, 0.045, 0.28)
	terrain.scatter_tufts(tuft, grass_mat, int(cfg.get("grass_per_chunk", 260) * _grass_mult()), rng, 45.0 + 15.0 * _grass_mult(), -1, Vector2(0.8, 1.3), building_areas)
	if cfg.has("wheat_base"):
		var wheat_mat := ShaderMaterial.new()
		wheat_mat.shader = load("res://shaders/grass.gdshader")
		wheat_mat.set_shader_parameter("base_color", cfg["wheat_base"])
		wheat_mat.set_shader_parameter("tip_color", cfg["wheat_tip"])
		wheat_mat.set_shader_parameter("blade_height", 1.2)
		wheat_mat.set_shader_parameter("wind_strength", 0.2)
		var wheat := Terrain.make_tuft(rng, 14, 1.2, 0.06, 0.35)
		terrain.scatter_tufts(wheat, wheat_mat, int(900 * minf(1.0, _grass_mult() + 0.2)), rng, 80.0, 2, Vector2(0.85, 1.15))


func _build_walls() -> void:
	var wall := half - 3.0
	MeshKit.collider_box(self, Vector3(2, 80, wall * 2 + 4), Vector3(-wall, 30, 0))
	MeshKit.collider_box(self, Vector3(2, 80, wall * 2 + 4), Vector3(wall, 30, 0))
	MeshKit.collider_box(self, Vector3(wall * 2 + 4, 80, 2), Vector3(0, 30, -wall))
	MeshKit.collider_box(self, Vector3(wall * 2 + 4, 80, 2), Vector3(0, 30, wall))
