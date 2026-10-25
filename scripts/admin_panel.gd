class_name AdminPanel
extends Control
## In-game admin tools (only after logging in as admin in the main menu).
##   F1: clickable panel. ~: command console (type `help`).

var world: Node
var _panel: PanelContainer
var _console: PanelContainer
var _log: RichTextLabel
var _entry: LineEdit
var _history: Array = []
var _hist_i := 0

const HELP := """Commands:
  time <hour|day|night|dawn|dusk>   set the time of day
  timescale <x>        speed of the day cycle (1 = normal)
  freeze               stop / resume the clock
  god                  toggle god mode
  level <n>            set character level (1-50)
  xp <n>               give experience
  gold <n>             give gold
  give <weapon|armor|base> [quality 0-4] [level]   e.g. give sniper 4 30
  ammo                 full ammo
  heal                 full health and mana
  tp <landmark|x z>    teleport (e.g. tp Northvale, tp 100 -50)
  spawn <type> [n] [level]   spawn enemies in front of you
  killall              kill all hostile enemies nearby
  quests               complete all quests (next level unlocks)
  levelgo <1-6>        jump to a location
  wanted <0-5>         set wanted stars
  weather <clear|rain|storm|fog>
  event                start a random world event
  noclip               toggle flying through walls
  clear                clear the console"""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_build_console()


func _style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.06, 0.94)
	sb.border_color = Color(0.85, 0.25, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _style())
	_panel.position = Vector2(20, 120)
	_panel.visible = false
	add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panel.add_child(vb)
	vb.add_child(Game.make_label(Loc.t("ADMIN PANEL") + "  [F1]", 22, Color(1.0, 0.45, 0.35)))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	vb.add_child(g)
	var buttons := [
		["God mode", "god"], ["Full heal", "heal"], ["Full ammo", "ammo"],
		["Dawn 6:00", "time dawn"], ["Noon 12:00", "time day"], ["Dusk 19:00", "time dusk"],
		["Midnight", "time night"], ["Time x10", "timescale 10"], ["Time x1", "timescale 1"],
		["Level +5", "levelup5"], ["+10 000 XP", "xp 10000"], ["+5000 gold", "gold 5000"],
		["Legendary weapon", "give weapon 4"], ["Epic armor set", "armorset"], ["Kill nearby", "killall"],
		["Complete quests", "quests"], ["Spawn elite", "spawnelite"], ["Clear wanted", "wanted 0"],
		["Rain", "weather rain"], ["Storm", "weather storm"], ["Clear sky", "weather clear"],
		["World event", "event"], ["Noclip", "noclip"], ["Console  [~]", "console"],
	]
	for b in buttons:
		var btn := Button.new()
		btn.text = Loc.t(b[0])
		btn.custom_minimum_size = Vector2(170, 34)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_button.bind(b[1]))
		g.add_child(btn)
	vb.add_child(Game.make_label(Loc.t("Teleport"), 16, Color(0.9, 0.85, 0.7)))
	var tg := GridContainer.new()
	tg.columns = 3
	tg.add_theme_constant_override("h_separation", 6)
	tg.add_theme_constant_override("v_separation", 4)
	vb.add_child(tg)
	for lm in world.landmarks:
		var btn := Button.new()
		btn.text = str(lm["name"])
		btn.custom_minimum_size = Vector2(170, 30)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func() -> void: run("tp " + str(lm["name"])))
		tg.add_child(btn)
	vb.add_child(Game.make_label(Loc.t("Locations"), 16, Color(0.9, 0.85, 0.7)))
	var lg := HBoxContainer.new()
	vb.add_child(lg)
	for i in Game.LEVELS.size():
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.tooltip_text = Loc.t(Game.LEVELS[i]["name"])
		btn.custom_minimum_size = Vector2(40, 30)
		btn.pressed.connect(func() -> void: run("levelgo %d" % (i + 1)))
		lg.add_child(btn)


func _button(cmd: String) -> void:
	match cmd:
		"levelup5":
			run("level %d" % (int(Game.progress["level"]) + 5))
		"armorset":
			for s in ["helmet", "armor", "gloves", "boots", "amulet"]:
				Game.inventory["equip"][s] = Items.generate(int(Game.progress["level"]), 3, "armor", s)
			world.player.equip_active()
			_print("Epic armor equipped")
		"spawnelite":
			var f: Vector3 = -world.player.global_transform.basis.z
			var types: Array = []
			for e in get_tree().get_nodes_in_group("enemies"):
				if not e.neutral and not e.boss and not types.has(e.type):
					types.append(e.type)
			if types.is_empty():
				types = ["bandit"]
			var e := Enemy.new()
			e.type = types[randi() % types.size()]
			e.world = world
			e.level = int(Game.progress["level"])
			e.elite = true
			e.position = world.free_spot(world.player.global_position + f * 10.0) + Vector3(0, 0.3, 0)
			world.add_child(e)
			e.died.connect(world._on_enemy_died)
		"console":
			_toggle_console()
		_:
			run(cmd)


func _build_console() -> void:
	_console = PanelContainer.new()
	_console.add_theme_stylebox_override("panel", _style())
	_console.anchor_right = 1.0
	_console.offset_left = 20
	_console.offset_right = -20
	_console.offset_top = 10
	_console.offset_bottom = 330
	_console.visible = false
	add_child(_console)
	var vb := VBoxContainer.new()
	_console.add_child(vb)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 15)
	vb.add_child(_log)
	_entry = LineEdit.new()
	_entry.placeholder_text = Loc.t("type a command (help)")
	_entry.add_theme_font_size_override("font_size", 17)
	_entry.text_submitted.connect(func(t: String) -> void:
		run(t)
		_history.append(t)
		_hist_i = _history.size()
		_entry.text = "")
	vb.add_child(_entry)
	_print("Admin console. Type [b]help[/b] for commands.")


func _print(text: String) -> void:
	_log.append_text(text + "\n")


func toggle_panel() -> void:
	_panel.visible = not _panel.visible
	_update_mouse()


func _toggle_console() -> void:
	_console.visible = not _console.visible
	if _console.visible:
		_entry.grab_focus.call_deferred()
		_entry.text = ""
	_update_mouse()


func _update_mouse() -> void:
	var open := _panel.visible or _console.visible
	world.player.input_locked = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not Game.admin:
		return
	if event.is_action_pressed("admin_panel"):
		get_viewport().set_input_as_handled()
		toggle_panel()
	elif event.is_action_pressed("console"):
		get_viewport().set_input_as_handled()
		_toggle_console()


func _input(event: InputEvent) -> void:
	if not _console.visible or not event is InputEventKey or not event.pressed:
		return
	var k := event as InputEventKey
	if k.keycode == KEY_QUOTELEFT:
		get_viewport().set_input_as_handled()
		_toggle_console()
	elif k.keycode == KEY_UP and not _history.is_empty():
		_hist_i = maxi(0, _hist_i - 1)
		_entry.text = _history[_hist_i]
		_entry.caret_column = _entry.text.length()
	elif k.keycode == KEY_DOWN and not _history.is_empty():
		_hist_i = mini(_history.size(), _hist_i + 1)
		_entry.text = _history[_hist_i] if _hist_i < _history.size() else ""


# --------------------------------------------------------------------------- commands

func run(line: String) -> void:
	var parts := line.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	_print("> " + line)
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)
	var p: Player = world.player
	match cmd:
		"help":
			_print(HELP)
		"clear":
			_log.clear()
		"time":
			var h := 12.0
			if args.is_empty():
				_print("Time: " + world.day_night.clock_text())
				return
			match args[0]:
				"day", "noon": h = 12.0
				"night", "midnight": h = 0.0
				"dawn": h = 6.0
				"dusk": h = 19.0
				_: h = float(args[0])
			world.day_night.set_hour(h)
			world.day_night.hour_changed.emit(int(h))
			_print("Time set to " + world.day_night.clock_text())
		"timescale":
			world.day_night.hours_per_second = (1.0 / 60.0) * float(args[0] if args.size() > 0 else "1")
			_print("Day cycle speed x%s" % (args[0] if args.size() > 0 else "1"))
		"freeze":
			world.day_night.frozen = not world.day_night.frozen
			_print("Clock frozen" if world.day_night.frozen else "Clock running")
		"god":
			Game.god_mode = not Game.god_mode
			_print("God mode " + ("ON" if Game.god_mode else "OFF"))
		"level":
			var lv := clampi(int(args[0]) if args.size() > 0 else 1, 1, Skills.MAX_LEVEL)
			var gained := lv - int(Game.progress["level"])
			Game.progress["level"] = lv
			Game.progress["xp"] = 0
			Game.progress["points"] = maxi(0, int(Game.progress["points"]) + gained)
			p.recalc_stats()
			p.health = p.max_health
			p.mana = p.max_mana
			_print("Level %d" % lv)
		"xp":
			p.add_xp(int(args[0]) if args.size() > 0 else 1000)
			_print("XP given")
		"gold":
			p.add_gold(int(args[0]) if args.size() > 0 else 1000, true)
			_print("Gold: %d" % int(Game.inventory["gold"]))
		"give":
			var base := args[0] if args.size() > 0 else "weapon"
			var q := int(args[1]) if args.size() > 1 else -1
			var lv := int(args[2]) if args.size() > 2 else int(Game.progress["level"])
			var it: Dictionary
			if base == "weapon" or base == "armor":
				it = Items.generate(lv, q, base)
			elif Items.WEAPONS.has(base) or Items.ARMOR.has(base):
				it = Items.generate(lv, q, "", base)
			else:
				_print("Unknown item. Weapons: " + ", ".join(Items.WEAPONS.keys()) + "   Armor: " + ", ".join(Items.ARMOR.keys()))
				return
			if Items.add_to_bag(Game.inventory, it):
				_print("Added to bag: " + Items.display_name(it))
			else:
				LootDrop.spawn(world, p.global_position + Vector3(0, 0, -2), it)
				_print("Bag full, dropped: " + Items.display_name(it))
		"ammo":
			p.reserve = Player.MAX_RESERVE
			p.mag = p.mag_size()
			_print("Ammo full")
		"heal":
			p.health = p.max_health
			p.mana = p.max_mana
			_print("Healed")
		"tp":
			if args.size() >= 2 and args[0].is_valid_float():
				var x := float(args[0])
				var z := float(args[1])
				p.global_position = Vector3(x, world.ground(x, z) + 0.5, z)
				_print("Teleported")
				return
			var name := " ".join(args).to_lower()
			for lm in world.landmarks:
				if str(lm["name"]).to_lower().begins_with(name):
					var lp: Vector2 = lm["pos"]
					var spot: Vector3 = world.free_spot(Vector3(lp.x, 0, lp.y + float(lm["radius"]) * 0.6))
					p.global_position = spot + Vector3(0, 0.3, 0)
					_print("Teleported to " + str(lm["name"]))
					return
			_print("No landmark '%s'" % name)
		"spawn":
			var type := args[0] if args.size() > 0 else "bandit"
			if not Enemy.TYPES.has(type):
				_print("Types: " + ", ".join(Enemy.TYPES.keys()))
				return
			var n := int(args[1]) if args.size() > 1 else 1
			var lv: int = int(args[2]) if args.size() > 2 else world.enemy_level_at(p.global_position)
			var f := -p.global_transform.basis.z
			for i in n:
				var e := Enemy.new()
				e.type = type
				e.world = world
				e.level = lv
				e.position = world.free_spot(p.global_position + f * 10.0 + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))) + Vector3(0, 0.3, 0)
				world.add_child(e)
				e.died.connect(world._on_enemy_died)
			_print("Spawned %d %s (Lv %d)" % [n, type, lv])
		"killall":
			var k := 0
			for e in get_tree().get_nodes_in_group("enemies"):
				if not e.neutral and e.global_position.distance_to(p.global_position) < 60.0:
					e.take_damage(1e9, e.global_position + Vector3(0, 1, 0), Vector3.UP, "bullet")
					k += 1
			_print("Killed %d" % k)
		"quests":
			for q in world.quests.defs:
				var st: String = world.quests.status(q["id"])
				if st != "done":
					world.quests.state[q["id"]]["status"] = "ready"
					world.quests.complete(q["id"])
			_print("All quests completed")
		"levelgo":
			var i := clampi((int(args[0]) if args.size() > 0 else 1) - 1, 0, Game.LEVELS.size() - 1)
			world.store_state()
			Game.level_index = i
			Game.carry = {"reserve": p.reserve}
			Game._begin_level()
		"wanted":
			var s := clampi(int(args[0]) if args.size() > 0 else 0, 0, 5)
			if s == 0:
				world.wanted_stars = 0
				for e in get_tree().get_nodes_in_group("enemies"):
					if e.neutral and e.state == Enemy.State.CHASE:
						e._evade()
			else:
				world.report_crime(s, p.global_position)
				world.wanted_stars = s
			_print("Wanted: %d" % s)
		"weather":
			world.set_weather(args[0] if args.size() > 0 else "clear")
			_print("Weather: " + (args[0] if args.size() > 0 else "clear"))
		"event":
			_print(world.events.start_random())
		"noclip":
			p.noclip = not p.noclip
			_print("Noclip " + ("ON (Space up, Shift down)" if p.noclip else "OFF"))
		_:
			_print("Unknown command. Type help.")
