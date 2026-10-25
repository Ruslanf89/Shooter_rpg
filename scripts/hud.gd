class_name Hud
extends CanvasLayer
## In-game UI: crosshair, health, ammo, enemy counter, minimap, full map, pause and end screens.

const MINI_SIZE := 210.0
const MINI_SCALE := 1.3
const BIG_SIZE := 600.0

var world: Node
var player: Player

var root: Control
var crosshair: Control
var minimap: Control
var bigmap_panel: Control
var bigmap: Control
var health_bar: ProgressBar
var health_fill: StyleBoxFlat
var health_label: Label
var mana_bar: ProgressBar
var mana_label: Label
var action_bar: Control
var boss_panel: Control
var boss_name: Label
var boss_bar: ProgressBar
var title_label: Label
var subtitle_label: Label
var xp_bar: Control
var xp_popup: Label
var book: Control
var book_grid: GridContainer
var book_points: Label
var _xp_t := 0.0
var _quest_signal := false
var prompt_label: Label
var dialogue: Control
var dlg_name: Label
var dlg_quest: Label
var dlg_text: Label
var dlg_trans: Label
var dlg_buttons: VBoxContainer
var _dlg_scroll: ScrollContainer
var _dlg_actions: Array = []
var quest_log: VBoxContainer
var _dlg_t := 0.0
var _dlg_dur := 1.0
var ammo_label: Label
var weapon_label: Label
var info_label: Label
var wanted_bar: Control
var torch_label: Label
var _dusk_hinted := false
var reserve_label: Label
var status_label: Label
var counter_label: Label
var message_label: Label
var killfeed: VBoxContainer
var vignette: TextureRect
var pause_panel: Control
var resume_button: Button
var end_panel: Control
var end_title: Label
var end_stats: Label
var end_first_button: Button

var _hit_t := 0.0
var _hit_color := Color.WHITE
var _dmg_indicators: Array = []    # [source_pos: Vector3, time_left: float]
var _msg_t := 0.0
var _title_t := 0.0
var _vignette_a := 0.0
var _won := false
var _objective := {}               # quest waypoint {pos, label} (QuestManager.objective_target)
var note_panel: PanelContainer      # what you read when you inspect a clue (title + text)
var note_title: Label
var note_text: Label
var _note_t := 0.0
var _obj_t := 0.0


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_vignette()
	_build_crosshair()
	_build_health()
	_build_ammo()
	_build_counter()
	_build_minimap()
	_build_action_bar()
	_build_boss_bar()
	_build_messages()
	_build_bigmap()
	_build_quest_ui()
	_build_note()
	_build_skill_book()
	_build_pause()
	_build_end()


# --------------------------------------------------------------------------- building

func _place(c: Control, anchors: Vector4, offsets: Vector4) -> void:
	c.anchor_left = anchors.x
	c.anchor_top = anchors.y
	c.anchor_right = anchors.z
	c.anchor_bottom = anchors.w
	c.offset_left = offsets.x
	c.offset_top = offsets.y
	c.offset_right = offsets.z
	c.offset_bottom = offsets.w


func _panel_style(alpha := 0.55) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.11, alpha)
	sb.border_color = Color(0.85, 0.7, 0.3, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)
	return p


func _build_vignette() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0.7, 0.0, 0.0, 0.0))
	grad.set_color(1, Color(0.7, 0.0, 0.0, 0.9))
	grad.add_point(0.55, Color(0.7, 0.0, 0.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	vignette = TextureRect.new()
	vignette.texture = tex
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.modulate.a = 0.0
	root.add_child(vignette)


func _build_crosshair() -> void:
	crosshair = Control.new()
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.draw.connect(_draw_crosshair)
	root.add_child(crosshair)


func _bar(max_value: float, fill: StyleBoxFlat, width := 220.0, height := 20.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, height)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg.set_corner_radius_all(4)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _build_health() -> void:
	var p := _panel()
	_place(p, Vector4(0, 1, 0, 1), Vector4(20, -118, 340, -20))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	p.add_child(vb)
	vb.add_child(Game.make_label(Loc.t("HEALTH"), 14, Color(0.85, 0.85, 0.85)))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	health_fill = StyleBoxFlat.new()
	health_fill.bg_color = Color(0.3, 0.85, 0.3)
	health_bar = _bar(Player.MAX_HEALTH, health_fill)
	hb.add_child(health_bar)
	health_label = Game.make_label("100", 26)
	hb.add_child(health_label)
	vb.add_child(Game.make_label(Loc.t("MANA"), 14, Color(0.7, 0.8, 1.0)))
	var mb := HBoxContainer.new()
	mb.add_theme_constant_override("separation", 10)
	vb.add_child(mb)
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.25, 0.5, 1.0)
	mana_bar = _bar(Player.MAX_MANA, mana_fill, 220.0, 14.0)
	mb.add_child(mana_bar)
	mana_label = Game.make_label("100", 18, Color(0.75, 0.85, 1.0))
	mb.add_child(mana_label)


## Spell slots for every learned active skill at the bottom center, WoW-style, plus the XP bar.
func _build_action_bar() -> void:
	action_bar = Control.new()
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(action_bar, Vector4(0.5, 1, 0.5, 1), Vector4(-300, -96, 300, -20))
	action_bar.draw.connect(_draw_action_bar)
	root.add_child(action_bar)
	xp_bar = Control.new()
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(xp_bar, Vector4(0.5, 1, 0.5, 1), Vector4(-300, -122, 300, -102))
	xp_bar.draw.connect(_draw_xp_bar)
	root.add_child(xp_bar)
	xp_popup = Game.make_label("", 20, Color(0.75, 0.55, 1.0))
	xp_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(xp_popup, Vector4(0.5, 1, 0.5, 1), Vector4(-200, -158, 200, -128))
	root.add_child(xp_popup)


func _build_quest_ui() -> void:
	prompt_label = Game.make_label("", 22, Color(1.0, 0.95, 0.7))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(prompt_label, Vector4(0, 0.58, 1, 0.58), Vector4(0, 0, 0, 34))
	root.add_child(prompt_label)

	quest_log = VBoxContainer.new()
	quest_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_log.add_theme_constant_override("separation", 2)
	_place(quest_log, Vector4(1, 0, 1, 0), Vector4(-340, 260, -20, 560))
	root.add_child(quest_log)

	# compact side panel: who is talking, what they say, numbered replies (1-9 keys, Esc = leave)
	dialogue = PanelContainer.new()
	dialogue.add_theme_stylebox_override("panel", _panel_style(0.92))
	_place(dialogue, Vector4(0, 0.5, 0, 0.5), Vector4(24, -200, 504, 200))
	root.add_child(dialogue)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	dialogue.add_child(vb)
	dlg_name = Game.make_label("", 20, Color(0.45, 1.0, 0.45))
	dlg_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(dlg_name)
	dlg_quest = Game.make_label("", 17, Color(1.0, 0.85, 0.35))
	dlg_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(dlg_quest)
	var text_scroll := ScrollContainer.new()
	text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(text_scroll)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scroll.add_child(tv)
	dlg_text = Game.make_label("", 17, Color(0.95, 0.95, 0.95))
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_text.visible_ratio = 0.0
	tv.add_child(dlg_text)
	dlg_trans = Game.make_label("", 14, Color(0.7, 0.75, 0.8))
	dlg_trans.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_trans.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(dlg_trans)
	var sep := HSeparator.new()
	vb.add_child(sep)
	_dlg_scroll = ScrollContainer.new()
	_dlg_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_dlg_scroll)
	dlg_buttons = VBoxContainer.new()
	dlg_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_buttons.add_theme_constant_override("separation", 4)
	_dlg_scroll.add_child(dlg_buttons)
	dialogue.visible = false


## The clue / note panel (top centre): a title and a few lines of text that fade out.
func _build_note() -> void:
	note_panel = PanelContainer.new()
	var sb := _panel_style(0.9)
	sb.bg_color = Color(0.13, 0.11, 0.08, 0.93)
	sb.border_color = Color(0.75, 0.62, 0.38, 0.9)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	note_panel.add_theme_stylebox_override("panel", sb)
	note_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(note_panel, Vector4(0.5, 0.06, 0.5, 0.06), Vector4(-330, 0, 330, 0))
	root.add_child(note_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_panel.add_child(vb)
	note_title = Game.make_label("", 21, Color(1.0, 0.86, 0.5))
	note_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(note_title)
	note_text = Game.make_label("", 17, Color(0.95, 0.92, 0.85))
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text.custom_minimum_size = Vector2(620, 0)
	vb.add_child(note_text)
	note_panel.visible = false


## Shows a note (a clue, a page, a record) for `duration` seconds (0: long enough to read it).
func show_note(title: String, text: String, duration := 0.0) -> void:
	note_title.text = title
	note_title.visible = title != ""
	note_text.text = text
	note_panel.reset_size()
	note_panel.visible = true
	note_panel.modulate.a = 1.0
	_note_t = duration if duration > 0.0 else clampf(4.0 + text.length() / 16.0, 5.0, 22.0)


func hide_note() -> void:
	_note_t = 0.0
	note_panel.visible = false


func set_prompt(text: String) -> void:
	prompt_label.text = text


func show_dialogue(npc_name: String, npc_title: String, quest_title: String, text: String, buttons: Array, duration: float, translation := "") -> void:
	dlg_trans.text = translation
	dlg_trans.visible = translation != ""
	dlg_name.text = Loc.t("%s  <%s>") % [npc_name, npc_title]
	dlg_quest.text = quest_title
	dlg_quest.visible = quest_title != ""
	dlg_text.text = text
	dlg_text.visible_ratio = 0.0
	_dlg_t = 0.0
	_dlg_dur = maxf(1.0, duration * 0.9)
	set_dialogue_buttons(buttons)
	dialogue.visible = true
	bigmap_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Streaming (AI) dialogue: the text grows while it's being written (no typewriter on top).
func stream_dialogue_text(text: String) -> void:
	dlg_text.text = text
	_dlg_t = 1.0
	_dlg_dur = 0.001
	dlg_text.visible_ratio = 1.0


## Replaces the reply buttons ([[text, Callable], ...]) without touching the text.
func set_dialogue_buttons(buttons: Array) -> void:
	for c in dlg_buttons.get_children():
		dlg_buttons.remove_child(c)
		c.queue_free()
	_dlg_actions.clear()
	var first: Button = null
	for i in buttons.size():
		var b: Array = buttons[i]
		var btn := Game.make_button("%d.  %s" % [i + 1, b[0]], 0.0)
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(b[1])
		dlg_buttons.add_child(btn)
		_dlg_actions.append(b[1])
		if first == null:
			first = btn
	_dlg_scroll.custom_minimum_size = Vector2(0, minf(buttons.size() * 40.0, 7 * 40.0))
	dialogue.visible = true
	bigmap_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if first:
		first.grab_focus.call_deferred()


func hide_dialogue() -> void:
	dialogue.visible = false
	if not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Loot list on the right side of the screen that fades out after a few seconds.
func show_loot(title_text: String, lines: Array) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(0.7))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(panel, Vector4(1, 0.5, 1, 0.5), Vector4(-360, -60, -30, 60))
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	vb.add_child(t)
	for i in lines.size():
		var l := Label.new()
		l.text = "+  " + str(lines[i])
		l.add_theme_font_size_override("font_size", 17)
		l.modulate.a = 0.0
		vb.add_child(l)
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.25).set_delay(0.3 + i * 0.25)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(4.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(panel.queue_free)


func show_quest_complete(quest_title: String, xp: int) -> void:
	title_label.text = Loc.t("QUEST COMPLETE")
	subtitle_label.text = "%s   +%d XP" % [Loc.t(quest_title), xp]
	_title_t = 3.5


func _refresh_quest_log() -> void:
	for c in quest_log.get_children():
		c.queue_free()
	if world.quests == null:
		return
	var header := Game.make_label(Loc.t("QUESTS  %d / %d") % [world.quests.done_count(), world.quests.defs.size()], 18, Color(1.0, 0.85, 0.4))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quest_log.add_child(header)
	for e in world.quests.log_entries():
		var t := Game.make_label(Loc.t(e[0]), 16, Color(1.0, 0.85, 0.35) if e[2] else Color(1.0, 0.95, 0.8))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quest_log.add_child(t)
		var d := Game.make_label("- " + e[1], 14, Color(0.6, 1.0, 0.5) if e[2] else Color(0.85, 0.85, 0.85))
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quest_log.add_child(d)
	if world.quests.log_entries().is_empty() and not world.quests.all_done():
		var h := Game.make_label(Loc.t("Find quest givers (yellow ! on the map)"), 14, Color(0.85, 0.85, 0.85))
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quest_log.add_child(h)


func _build_skill_book() -> void:
	book = ColorRect.new()
	book.color = Color(0, 0, 0, 0.65)
	book.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(book)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	book.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(0.96))
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Game.make_label(Loc.t("SKILL BOOK"), 40, Color(1.0, 0.84, 0.38))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	book_points = Game.make_label("", 20, Color(0.8, 0.65, 1.0))
	book_points.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(book_points)
	book_grid = GridContainer.new()
	book_grid.columns = 4
	book_grid.add_theme_constant_override("h_separation", 10)
	book_grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(book_grid)
	var close := Game.make_button(Loc.t("Close  [K]"))
	close.pressed.connect(toggle_skill_book)
	vb.add_child(close)
	book.visible = false


func _refresh_skill_book() -> void:
	for c in book_grid.get_children():
		c.queue_free()
	var prog: Dictionary = player.progress
	book_points.text = Loc.t("Level %d    -    Talent points: %d") % [prog["level"], prog["points"]]
	for id in Skills.ORDER:
		var def: Dictionary = Skills.LIST[id]
		var r := player.rank(id)
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.1, 0.18, 0.95) if r > 0 else Color(0.06, 0.06, 0.08, 0.95)
		sb.border_color = Color(0.85, 0.7, 0.3, 0.9) if r > 0 else Color(0.35, 0.35, 0.4)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", sb)
		card.custom_minimum_size = Vector2(290, 140)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		card.add_child(hb)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		icon.draw.connect(func() -> void:
			icon.draw_rect(Rect2(Vector2.ZERO, Vector2(64, 64)), Color(0.04, 0.06, 0.12))
			_draw_icon(icon, id, Vector2(32, 32), r > 0, 0.85)
			icon.draw_rect(Rect2(Vector2.ZERO, Vector2(64, 64)), Color(0.85, 0.7, 0.3, 0.8), false, 2.0))
		hb.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info)
		var head := "%s   %s" % [Loc.t(def["name"]), ("[" + def["key"] + "]") if def["type"] == "active" else Loc.t("(passive)")]
		info.add_child(Game.make_label(head, 18, Color(1.0, 0.9, 0.6) if r > 0 else Color(0.75, 0.75, 0.75)))
		var stars := ""
		for i in def["max"]:
			stars += "◆ " if i < r else "◇ "
		info.add_child(Game.make_label(Loc.t("Rank %d / %d   %s") % [r, def["max"], stars], 14, Color(0.8, 0.65, 1.0)))
		var desc := Game.make_label(Loc.t(def["desc"]), 12, Color(0.85, 0.85, 0.9))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(190, 0)
		info.add_child(desc)
		if def["type"] == "active":
			info.add_child(Game.make_label(Loc.t("%d mana   %.1fs cooldown") % [def["mana"], def["cd"]], 12, Color(0.55, 0.75, 1.0)))
		var btn := Button.new()
		btn.add_theme_font_size_override("font_size", 15)
		if r >= def["max"]:
			btn.text = Loc.t("Mastered")
			btn.disabled = true
		elif prog["level"] < def["level"]:
			btn.text = Loc.t("Requires level %d") % def["level"]
			btn.disabled = true
		else:
			btn.text = Loc.t("Learn") if r == 0 else Loc.t("Upgrade")
			btn.disabled = prog["points"] <= 0
			btn.pressed.connect(func() -> void:
				if player.learn(id):
					_refresh_skill_book())
		info.add_child(btn)
		book_grid.add_child(card)


func toggle_skill_book() -> void:
	if world.finished or pause_panel.visible:
		return
	book.visible = not book.visible
	get_tree().paused = book.visible
	if book.visible:
		bigmap_panel.visible = false
		_refresh_skill_book()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_boss_bar() -> void:
	boss_panel = _panel()
	_place(boss_panel, Vector4(0.5, 0, 0.5, 0), Vector4(-240, 68, 240, 120))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	boss_panel.add_child(vb)
	boss_name = Game.make_label("", 18, Color(1.0, 0.6, 0.2))
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(boss_name)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.15, 0.1)
	boss_bar = _bar(100.0, fill, 440.0, 14.0)
	vb.add_child(boss_bar)
	boss_panel.visible = false


func _build_ammo() -> void:
	var p := _panel()
	# fixed size, anchored to the bottom-right corner; anything too long is cut with "..." instead
	# of pushing the panel off the screen (long Ukrainian weapon names and status texts)
	_place(p, Vector4(1, 1, 1, 1), Vector4(-318, -142, -20, -20))
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.clip_contents = true
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.alignment = BoxContainer.ALIGNMENT_END
	p.add_child(vb)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(top)
	ammo_label = Game.make_label("30", 48, Color(1.0, 0.95, 0.8))
	top.add_child(ammo_label)
	reserve_label = Game.make_label("/ 90", 28, Color(0.8, 0.8, 0.8))
	reserve_label.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(reserve_label)
	status_label = Game.make_label("", 16, Color(1.0, 0.6, 0.3))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.custom_minimum_size = Vector2(0, 22)
	vb.add_child(status_label)
	weapon_label = Game.make_label("", 16, Color(1.0, 0.85, 0.4))
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vb.add_child(weapon_label)
	torch_label = Game.make_label("", 16, Color(1.0, 0.95, 0.7))
	_place(torch_label, Vector4(1, 1, 1, 1), Vector4(-318, -170, -20, -146))
	torch_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	torch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(torch_label)


func _build_counter() -> void:
	var p := _panel()
	_place(p, Vector4(0.5, 0, 0.5, 0), Vector4(-190, 16, 190, 60))
	counter_label = Game.make_label("", 22, Color(1.0, 0.88, 0.6))
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(counter_label)


func _build_minimap() -> void:
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", _panel_style(0.0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(frame, Vector4(1, 0, 1, 0), Vector4(-MINI_SIZE - 20, 16, -20, 16 + MINI_SIZE))
	root.add_child(frame)
	minimap = Control.new()
	minimap.clip_contents = true
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minimap.draw.connect(_draw_minimap)
	frame.add_child(minimap)
	var hint := Game.make_label("", 15, Color(1, 1, 1, 0.85))
	info_label = hint
	_place(hint, Vector4(1, 0, 1, 0), Vector4(-MINI_SIZE - 20, 20 + MINI_SIZE, -20, 40 + MINI_SIZE))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)
	wanted_bar = Control.new()
	wanted_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(wanted_bar, Vector4(1, 0, 1, 0), Vector4(-MINI_SIZE - 20, 44 + MINI_SIZE, -20, 74 + MINI_SIZE))
	wanted_bar.draw.connect(_draw_wanted)
	root.add_child(wanted_bar)
	killfeed = VBoxContainer.new()
	killfeed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	killfeed.alignment = BoxContainer.ALIGNMENT_BEGIN
	_place(killfeed, Vector4(0, 0, 0, 0), Vector4(20, 20, 360, 200))
	root.add_child(killfeed)


func _build_messages() -> void:
	message_label = Game.make_label("", 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(message_label, Vector4(0, 0.4, 1, 0.4), Vector4(0, 0, 0, 40))
	root.add_child(message_label)
	title_label = Game.make_label("", 72, Color(1.0, 0.84, 0.38))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(title_label, Vector4(0, 0.13, 1, 0.13), Vector4(0, 0, 0, 90))
	root.add_child(title_label)
	subtitle_label = Game.make_label("", 28, Color(0.92, 0.95, 1.0))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(subtitle_label, Vector4(0, 0.13, 1, 0.13), Vector4(0, 96, 0, 134))
	root.add_child(subtitle_label)


func _build_bigmap() -> void:
	bigmap_panel = PanelContainer.new()
	bigmap_panel.add_theme_stylebox_override("panel", _panel_style(0.85))
	bigmap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(bigmap_panel, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-BIG_SIZE / 2 - 14, -BIG_SIZE / 2 - 40, BIG_SIZE / 2 + 14, BIG_SIZE / 2 + 30))
	root.add_child(bigmap_panel)
	var vb := VBoxContainer.new()
	bigmap_panel.add_child(vb)
	var title := Game.make_label(Loc.t("NORTHVALE      red = melee   purple = caster   yellow = ammo      [M] close"), 16, Color(1.0, 0.85, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	bigmap = Control.new()
	bigmap.custom_minimum_size = Vector2(BIG_SIZE, BIG_SIZE)
	bigmap.clip_contents = true
	bigmap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bigmap.draw.connect(_draw_bigmap)
	vb.add_child(bigmap)
	bigmap_panel.visible = false


func _overlay(title_text: String, title_color: Color) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	var title := Game.make_label(title_text, 72, title_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	dim.visible = false
	return [dim, vb, title]


func _build_pause() -> void:
	var o := _overlay(Loc.t("PAUSED"), Color(1.0, 0.85, 0.4))
	pause_panel = o[0]
	var vb: VBoxContainer = o[1]
	resume_button = Game.make_button(Loc.t("Resume"))
	resume_button.pressed.connect(_set_paused.bind(false))
	vb.add_child(resume_button)
	var restart := Game.make_button(Loc.t("Return to the portal"))
	restart.pressed.connect(func() -> void:
		_set_paused(false)
		player.global_position = world.respawn_point()
		player.velocity = Vector3.ZERO)
	vb.add_child(restart)
	var settings := Game.make_button(Loc.t("Settings"))
	settings.pressed.connect(func() -> void:
		var s := SettingsMenu.new()
		root.add_child(s)
		s.closed.connect(settings.grab_focus))
	vb.add_child(settings)
	var menu := Game.make_button(Loc.t("Main Menu"))
	menu.pressed.connect(Game.go_to_menu)
	vb.add_child(menu)
	var quit := Game.make_button(Loc.t("Exit Game"))
	quit.pressed.connect(Game.quit_game)
	vb.add_child(quit)


func _build_end() -> void:
	var o := _overlay("", Color.WHITE)
	end_panel = o[0]
	var vb: VBoxContainer = o[1]
	end_title = o[2]
	end_stats = Game.make_label("", 24, Color(0.92, 0.92, 0.92))
	end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(end_stats)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vb.add_child(spacer)
	end_first_button = Game.make_button(Loc.t("Play Again"))
	end_first_button.pressed.connect(func() -> void:
		if _won:
			Game.start_game()
		else:
			Game.respawn())
	vb.add_child(end_first_button)
	var menu := Game.make_button(Loc.t("Main Menu"))
	menu.pressed.connect(Game.go_to_menu)
	vb.add_child(menu)
	var quit := Game.make_button(Loc.t("Exit Game"))
	quit.pressed.connect(Game.quit_game)
	vb.add_child(quit)


# --------------------------------------------------------------------------- public API

func show_message(text: String, color := Color.WHITE, duration := 2.0) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	_msg_t = duration


func hit_marker(killed: bool, headshot: bool) -> void:
	_hit_t = 0.2
	if killed:
		_hit_color = Color(1.0, 0.2, 0.15)
	elif headshot:
		_hit_color = Color(1.0, 0.85, 0.2)
	else:
		_hit_color = Color.WHITE


func damage_taken(source_pos: Vector3) -> void:
	_dmg_indicators.append([source_pos, 1.2])
	_vignette_a = minf(_vignette_a + 0.45, 0.9)


func on_kill(enemy_name: String) -> void:
	var l := Game.make_label(Loc.t("Killed  ") + enemy_name, 18, Color(1.0, 0.85, 0.6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	killfeed.add_child(l)
	if killfeed.get_child_count() > 5:
		killfeed.get_child(0).queue_free()
	var tw := l.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)


func show_end(win: bool) -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	bigmap_panel.visible = false
	pause_panel.visible = false
	end_panel.visible = true
	_won = win
	end_title.text = Loc.t("VICTORY!") if win else Loc.t("YOU DIED")
	end_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if win else Color(0.95, 0.2, 0.15))
	end_first_button.text = Loc.t("Play Again") if win else Loc.t("Respawn")
	var st: Dictionary = Game.stats
	var secs := int(st["time"])
	var fired: int = st["fired"]
	var acc := 0 if fired == 0 else int(100.0 * st["hit"] / fired)
	var subtitle := Loc.t("All six lands are safe again!") if win else Loc.t("You fell in %s...") % Loc.t(Game.current_level()["name"])
	end_stats.text = Loc.t("%s\n\nLocation %d / %d\nTotal kills: %d\nTime: %d:%02d\nAccuracy: %d%%") % [subtitle,
		Game.level_index + 1, Game.LEVELS.size(), st["kills"], secs / 60, secs % 60, acc]
	end_first_button.grab_focus()


func show_title(title: String, subtitle: String) -> void:
	title_label.text = Loc.t(title).to_upper()
	subtitle_label.text = Loc.t(subtitle)
	_title_t = 5.0
	show_message(Loc.t("Talk to NPCs with a yellow !  [F]   -   [M] map   [K] skills   [U] crafting   [H] potion   [B] gadget"), Color(1.0, 0.9, 0.6), 7.0)


func show_level_cleared(next_name: String) -> void:
	title_label.text = Loc.t("LOCATION CLEARED!")
	subtitle_label.text = Loc.t("Next: %s - travel there by VesPer's portal whenever you're ready") % Loc.t(next_name)
	_title_t = 7.0
	Game.play_sound("pickup_ammo", null, 0.0, 0.7)


# --------------------------------------------------------------------------- loop

func _unhandled_input(event: InputEvent) -> void:
	if world.finished:
		return
	if dialogue.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
			# the last option is always the way out (Goodbye / Go away / Not now)
			get_viewport().set_input_as_handled()
			if not _dlg_actions.is_empty():
				(_dlg_actions[-1] as Callable).call()
			else:
				world.end_dialogue()
		elif event is InputEventKey and event.pressed and not event.echo:
			var k: int = (event as InputEventKey).physical_keycode - KEY_1
			if k >= 0 and k < mini(9, _dlg_actions.size()):
				get_viewport().set_input_as_handled()
				Game.play_sound("hit", null, -10.0, 0.7)
				(_dlg_actions[k] as Callable).call()
		return
	if event.is_action_pressed("skill_book") or (book.visible and event.is_action_pressed("pause")):
		toggle_skill_book()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map") and not get_tree().paused:
		bigmap_panel.visible = not bigmap_panel.visible
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_pressed() and not get_tree().paused \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_paused(p: bool) -> void:
	get_tree().paused = p
	pause_panel.visible = p
	if p:
		bigmap_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		resume_button.grab_focus()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if player == null:
		return
	var hp_frac := player.health / player.max_health
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	mana_bar.max_value = player.max_mana
	_xp_t -= delta
	xp_popup.modulate.a = clampf(_xp_t, 0.0, 1.0)
	xp_bar.queue_redraw()
	health_label.text = str(ceili(player.health))
	if hp_frac > 0.6:
		health_fill.bg_color = Color(0.3, 0.85, 0.3)
	elif hp_frac > 0.3:
		health_fill.bg_color = Color(0.95, 0.75, 0.2)
	else:
		health_fill.bg_color = Color(0.9, 0.2, 0.15)

	ammo_label.text = str(player.mag)
	ammo_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25) if player.mag <= 7 else Color(1.0, 0.95, 0.8))
	reserve_label.text = Loc.t(" / %d") % player.reserve
	if player.reloading:
		status_label.text = Loc.t("RELOADING...")
	elif player.mag == 0 and player.reserve == 0:
		status_label.text = Loc.t("NO AMMO!")
	elif player.mag <= 7 and player.reserve > 0:
		status_label.text = Loc.t("LOW AMMO  [R]")
	else:
		status_label.text = ""
	if player.uses_mana():
		ammo_label.text = "-"
		reserve_label.text = ""
		status_label.text = Loc.t("Mana") + " %d" % int(player.wdef.get("mana", 0))
	weapon_label.text = Items.display_name(player.weapon_item)
	weapon_label.add_theme_color_override("font_color", Items.quality_color(player.weapon_item.get("quality", 0)))
	var dn = world.day_night
	info_label.text = Loc.t("%s   %s %s   %d %s") % [Loc.t("[M] Map"), Loc.t("Night") if dn.is_night() else Loc.t("Day"), dn.clock_text(), int(Game.inventory.get("gold", 0)), Loc.t("gold")]
	wanted_bar.queue_redraw()
	var lit: bool = player.flashlight != null and player.flashlight.visible
	torch_label.visible = lit or dn.daylight < 0.45
	torch_label.text = (Loc.t("[L] Flashlight: ON") if lit else Loc.t("[L] Flashlight: off"))
	torch_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6) if lit else Color(0.8, 0.8, 0.85, 0.8))
	if dn.daylight < 0.35 and not _dusk_hinted and not lit:
		_dusk_hinted = true
		show_message(Loc.t("It's getting dark - press [L] to turn on your flashlight"), Color(1.0, 0.92, 0.6), 6.0)
	elif dn.daylight > 0.6:
		_dusk_hinted = false
	if world.quests:
		counter_label.text = Loc.t("QUESTS COMPLETE   %d / %d") % [world.quests.done_count(), world.quests.defs.size()]
		if not _quest_signal:
			_quest_signal = true
			world.quests.changed.connect(_refresh_quest_log)
			_refresh_quest_log()
		_obj_t -= delta
		if _obj_t <= 0.0:
			_obj_t = 0.25
			_objective = world.quests.objective_target(player.global_position)
	if dialogue.visible:
		_dlg_t += delta
		dlg_text.visible_ratio = clampf(_dlg_t / _dlg_dur, 0.0, 1.0)

	_hit_t -= delta
	for i in range(_dmg_indicators.size() - 1, -1, -1):
		_dmg_indicators[i][1] -= delta
		if _dmg_indicators[i][1] <= 0.0:
			_dmg_indicators.remove_at(i)
	var low := 0.0
	if player.health < 40.0:
		low = 0.4 * (1.0 - player.health / 40.0)
	_vignette_a = move_toward(_vignette_a, low, delta * 1.2)
	vignette.modulate.a = maxf(_vignette_a, low)

	_msg_t -= delta
	message_label.modulate.a = clampf(_msg_t, 0.0, 1.0)
	if note_panel.visible:
		_note_t -= delta
		note_panel.modulate.a = clampf(_note_t * 1.5, 0.0, 1.0)
		if _note_t <= 0.0:
			note_panel.visible = false
	_title_t -= delta
	title_label.modulate.a = clampf(_title_t, 0.0, 1.0)
	subtitle_label.modulate.a = clampf(_title_t, 0.0, 1.0)

	mana_bar.value = player.mana
	mana_label.text = str(int(player.mana))

	var boss: Enemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e.boss and e.state == Enemy.State.CHASE:
			boss = e
			break
	boss_panel.visible = boss != null
	if boss:
		boss_name.text = boss.display_name + (Loc.t("   (frozen)") if boss.frozen_t > 0.0 else "")
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp

	action_bar.queue_redraw()
	crosshair.queue_redraw()
	minimap.queue_redraw()
	if bigmap_panel.visible:
		bigmap.queue_redraw()


# --------------------------------------------------------------------------- drawing

## Procedural spell icons, used by the action bar and the skill book.
func _draw_icon(ctrl: Control, id: String, c: Vector2, usable: bool, s := 1.0) -> void:
	var dim := Color(0.45, 0.47, 0.55)
	match id:
		"frost_arrow":
			var ice := Color(0.65, 0.88, 1.0) if usable else dim
			ctrl.draw_line(c + Vector2(-22, 22) * s, c + Vector2(18, -18) * s, ice, 5.0 * s)
			ctrl.draw_colored_polygon(PackedVector2Array([c + Vector2(24, -24) * s, c + Vector2(8, -18) * s, c + Vector2(18, -8) * s]), Color.WHITE if usable else ice)
			for k in 3:
				ctrl.draw_line(c + Vector2(-22 + k * 6, 22 - k * 6) * s, c + Vector2(-28 + k * 6, 10 - k * 6) * s, ice, 2.0 * s)
		"frost_nova":
			var ice := Color(0.65, 0.88, 1.0) if usable else dim
			for k in 6:
				var d := Vector2.from_angle(TAU * k / 6.0)
				ctrl.draw_line(c, c + d * 24.0 * s, ice, 4.0 * s)
				ctrl.draw_line(c + d * 14.0 * s, c + (d * 14.0 + d.rotated(0.8) * 8.0) * s, ice, 2.5 * s)
				ctrl.draw_line(c + d * 14.0 * s, c + (d * 14.0 + d.rotated(-0.8) * 8.0) * s, ice, 2.5 * s)
			ctrl.draw_circle(c, 5.0 * s, Color.WHITE if usable else ice)
		"fireball":
			var f := Color(1.0, 0.5, 0.1) if usable else dim
			ctrl.draw_colored_polygon(PackedVector2Array([c + Vector2(-26, 22) * s, c + Vector2(-2, 2) * s, c + Vector2(6, 14) * s]), Color(f, 0.6))
			ctrl.draw_circle(c + Vector2(6, -6) * s, 15.0 * s, f)
			ctrl.draw_circle(c + Vector2(8, -8) * s, 8.0 * s, Color(1.0, 0.9, 0.5) if usable else dim.lightened(0.2))
		"heal":
			var g := Color(0.4, 1.0, 0.45) if usable else dim
			ctrl.draw_rect(Rect2(c + Vector2(-7, -22) * s, Vector2(14, 44) * s), g)
			ctrl.draw_rect(Rect2(c + Vector2(-22, -7) * s, Vector2(44, 14) * s), g)
		"chain_lightning":
			var l := Color(0.8, 0.85, 1.0) if usable else dim
			var pts := PackedVector2Array([c + Vector2(6, -26) * s, c + Vector2(-10, -2) * s, c + Vector2(4, -2) * s, c + Vector2(-8, 26) * s, c + Vector2(14, -6) * s, c + Vector2(0, -6) * s, c + Vector2(12, -26) * s])
			ctrl.draw_colored_polygon(pts, l)
		"blink":
			var p := Color(0.75, 0.55, 1.0) if usable else dim
			for k in 3:
				var o := Vector2(-16 + k * 12, 0) * s
				ctrl.draw_polyline(PackedVector2Array([c + o + Vector2(-6, -16) * s, c + o + Vector2(6, 0) * s, c + o + Vector2(-6, 16) * s]), Color(p, 0.4 + k * 0.3), 4.0 * s)
		"meteor":
			var m := Color(1.0, 0.45, 0.15) if usable else dim
			for k in 3:
				ctrl.draw_line(c + Vector2(-24 + k * 6, -24) * s, c + Vector2(0 + k * 4, 0) * s, Color(m, 0.6), 3.0 * s)
			ctrl.draw_circle(c + Vector2(6, 8) * s, 13.0 * s, Color(0.35, 0.22, 0.15) if usable else dim.darkened(0.3))
			ctrl.draw_arc(c + Vector2(6, 8) * s, 14.0 * s, 0.0, TAU, 24, m, 3.0 * s)
		"toughness":
			ctrl.draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -20) * s, c + Vector2(18, -20) * s, c + Vector2(18, 4) * s, c + Vector2(0, 24) * s, c + Vector2(-18, 4) * s]), Color(0.75, 0.3, 0.25) if usable else dim)
		"arcane_mind":
			ctrl.draw_circle(c, 18.0 * s, Color(0.35, 0.5, 1.0) if usable else dim)
			ctrl.draw_circle(c, 8.0 * s, Color(0.75, 0.85, 1.0) if usable else dim.lightened(0.2))
		"marksman":
			var col := Color(1.0, 0.85, 0.4) if usable else dim
			ctrl.draw_arc(c, 18.0 * s, 0.0, TAU, 24, col, 3.0 * s)
			ctrl.draw_line(c + Vector2(-26, 0) * s, c + Vector2(26, 0) * s, col, 2.0 * s)
			ctrl.draw_line(c + Vector2(0, -26) * s, c + Vector2(0, 26) * s, col, 2.0 * s)
		"frostbite":
			ctrl.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -24) * s, c + Vector2(10, 0) * s, c + Vector2(0, 24) * s, c + Vector2(-10, 0) * s]), Color(0.6, 0.85, 1.0) if usable else dim)
		"quick_hands":
			var col := Color(0.9, 0.9, 0.9) if usable else dim
			ctrl.draw_arc(c, 18.0 * s, -PI * 0.5, PI * 1.2, 24, col, 4.0 * s)
			ctrl.draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -2) * s, c + Vector2(-10, -2) * s, c + Vector2(-18, 10) * s]), col)


func _draw_xp_bar() -> void:
	var prog: Dictionary = player.progress
	var need := Skills.xp_to_next(prog["level"])
	var frac := 1.0 if prog["level"] >= Skills.MAX_LEVEL else clampf(float(prog["xp"]) / need, 0.0, 1.0)
	var r := Rect2(Vector2(0, 6), Vector2(xp_bar.size.x, 10))
	xp_bar.draw_rect(r, Color(0.05, 0.05, 0.1, 0.85))
	xp_bar.draw_rect(Rect2(r.position, Vector2(r.size.x * frac, r.size.y)), Color(0.6, 0.35, 1.0))
	for k in range(1, 10):
		xp_bar.draw_line(Vector2(r.size.x * k / 10.0, r.position.y), Vector2(r.size.x * k / 10.0, r.end.y), Color(0, 0, 0, 0.5), 1.0)
	xp_bar.draw_rect(r, Color(0.85, 0.7, 0.3, 0.8), false, 1.5)
	var font := ThemeDB.fallback_font
	var txt := "Level %d    %d / %d XP" % [prog["level"], prog["xp"], need]
	if prog["level"] >= Skills.MAX_LEVEL:
		txt = "Level %d (max)" % prog["level"]
	if prog["points"] > 0:
		txt += Loc.t("    -    %d talent points!  Press [K]") % prog["points"]
	xp_bar.draw_string_outline(font, Vector2(4, 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	xp_bar.draw_string(font, Vector2(4, 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.5) if prog["points"] > 0 else Color(0.85, 0.8, 1.0))


func show_xp(amount: int) -> void:
	xp_popup.text = Loc.t("+%d XP") % amount
	_xp_t = 1.6


func show_level_up(level: int) -> void:
	title_label.text = Loc.t("LEVEL UP!")
	subtitle_label.text = Loc.t("You reached level %d  -  new talent point, press [K] to spend it") % level
	_title_t = 4.0


func _draw_action_bar() -> void:
	var ids: Array = []
	for id in Skills.ORDER:
		if Skills.LIST[id]["type"] == "active" and player.rank(id) > 0:
			ids.append(id)
	var font := ThemeDB.fallback_font
	var start_x := (action_bar.size.x - ids.size() * 84.0) * 0.5
	for i in ids.size():
		var id: String = ids[i]
		var def: Dictionary = Skills.LIST[id]
		var s := [def["key"], player.cds.get(id, 0.0), def["cd"], def["mana"]]
		var r := Rect2(Vector2(start_x + i * 84.0 + 6.0, 0), Vector2(72, 72))
		var cd: float = s[1]
		var total: float = s[2]
		var cost: float = s[3]
		var usable: bool = player.mana >= cost
		action_bar.draw_rect(r, Color(0.05, 0.08, 0.15, 0.85))
		var c := r.get_center()
		_draw_icon(action_bar, id, c, usable)
		if cd > 0.0:
			var frac := clampf(cd / total, 0.0, 1.0)
			var pts := PackedVector2Array([c])
			var steps := 24
			for k in steps + 1:
				var a := -PI * 0.5 + TAU * frac * k / steps
				var d := Vector2.from_angle(a)
				var t := 36.0 / maxf(absf(d.x), absf(d.y))
				pts.append(c + d * t)
			if frac > 0.03:
				action_bar.draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
			var txt := "%.1f" % cd if cd < 10.0 else str(int(cd))
			action_bar.draw_string_outline(font, c + Vector2(-14, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color.BLACK)
			action_bar.draw_string(font, c + Vector2(-14, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		if not usable:
			action_bar.draw_rect(r, Color(0.1, 0.2, 0.6, 0.35))
		action_bar.draw_rect(r, Color(0.85, 0.7, 0.3, 0.9), false, 2.0)
		action_bar.draw_string_outline(font, r.position + Vector2(5, 17), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
		action_bar.draw_string(font, r.position + Vector2(5, 17), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.6))
		action_bar.draw_string_outline(font, r.position + Vector2(40, 68), str(int(cost)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color.BLACK)
		action_bar.draw_string(font, r.position + Vector2(40, 68), str(int(cost)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.8, 1.0))


func _draw_crosshair() -> void:
	var c := crosshair.size * 0.5
	if not player.dead and not bigmap_panel.visible:
		var col := Color(1, 1, 1, 0.9)
		if player.aiming:
			crosshair.draw_circle(c, 2.5, Color(0, 0, 0, 0.6))
			crosshair.draw_circle(c, 1.5, col)
		else:
			var gap := 5.0 + player.spread * 350.0 + Vector2(player.velocity.x, player.velocity.z).length() * 1.2
			var ln := 9.0
			for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				crosshair.draw_line(c + d * gap, c + d * (gap + ln), Color(0, 0, 0, 0.6), 4.0)
				crosshair.draw_line(c + d * gap, c + d * (gap + ln), col, 2.0)
			crosshair.draw_circle(c, 1.5, col)
	if _hit_t > 0.0:
		var hc := Color(_hit_color, clampf(_hit_t / 0.2, 0.0, 1.0))
		for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			crosshair.draw_line(c + d * 6.0, c + d * 14.0, hc, 2.5)
	_draw_waypoint()
	for ind in _dmg_indicators:
		var src: Vector3 = ind[0]
		var t: float = ind[1]
		var local := player.global_transform.basis.inverse() * (src - player.global_position)
		var ang := -PI * 0.5 + atan2(local.x, -local.z)
		crosshair.draw_arc(c, 90.0, ang - 0.35, ang + 0.35, 20, Color(1, 0.1, 0.1, clampf(t, 0.0, 1.0) * 0.85), 7.0)


## Quest waypoint: a diamond with distance and objective over the target, or an arrow on the
## screen edge pointing towards it when it is off-screen.
func _draw_waypoint() -> void:
	if _objective.is_empty() or player.dead or bigmap_panel.visible or dialogue.visible or book.visible:
		return
	var cam := player.camera
	var wp: Vector3 = _objective["pos"]
	if cam.global_position.distance_to(wp) < 1.0:
		return
	if absf((cam.global_transform.affine_inverse() * wp).z) < 0.02:
		return     # exactly in the camera's plane: it can't be projected
	var size := crosshair.size
	var c := size * 0.5
	var margin := 60.0
	var behind := cam.is_position_behind(wp)
	var sp := cam.unproject_position(wp)
	var dist := player.global_position.distance_to(wp)
	var col := Color(1.0, 0.82, 0.25)
	var font := ThemeDB.fallback_font
	var dist_text := "%d m" % int(dist)
	if not behind and Rect2(Vector2(margin, margin), size - Vector2(margin, margin) * 2.0).has_point(sp):
		var s := 9.0 + 3.0 * sin(Time.get_ticks_msec() * 0.005)
		var pts := PackedVector2Array([sp + Vector2(0, -s), sp + Vector2(s, 0), sp + Vector2(0, s), sp + Vector2(-s, 0)])
		crosshair.draw_colored_polygon(pts, Color(col, 0.85))
		pts.append(pts[0])
		crosshair.draw_polyline(pts, Color.BLACK, 2.0)
		var w := font.get_string_size(dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		crosshair.draw_string_outline(font, sp + Vector2(-w * 0.5, s + 18), dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
		crosshair.draw_string(font, sp + Vector2(-w * 0.5, s + 18), dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		var label: String = _objective["label"]
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		crosshair.draw_string_outline(font, sp + Vector2(-lw * 0.5, -s - 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color.BLACK)
		crosshair.draw_string(font, sp + Vector2(-lw * 0.5, -s - 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.95, 0.8))
		return
	var d := sp - c
	if behind:
		d = -d
	if d.length() < 1.0:
		d = Vector2(0, 1)
	var lim := c - Vector2(margin, margin)
	var k := minf(lim.x / maxf(absf(d.x), 0.001), lim.y / maxf(absf(d.y), 0.001))
	var ep := c + d * k
	var fwd := d.normalized()
	var side := Vector2(-fwd.y, fwd.x)
	var tri := PackedVector2Array([ep + fwd * 16.0, ep - fwd * 8.0 + side * 12.0, ep - fwd * 8.0 - side * 12.0])
	crosshair.draw_colored_polygon(tri, Color(col, 0.9))
	tri.append(tri[0])
	crosshair.draw_polyline(tri, Color.BLACK, 2.0)
	var tp := ep - fwd * 34.0 + Vector2(-18, 6)
	crosshair.draw_string_outline(font, tp, dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color.BLACK)
	crosshair.draw_string(font, tp, dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)


## Wanted stars under the minimap (red, blinking while guards can see you).
func _draw_wanted() -> void:
	var stars: int = world.wanted_stars if "wanted_stars" in world else 0
	if stars <= 0:
		return
	var blink := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.012)
	var w := wanted_bar.size.x
	for i in 5:
		var c := Vector2(w - 16.0 - (4 - i) * 30.0, 14.0)
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI * 0.5 + TAU * k / 10.0
			var r := 12.0 if k % 2 == 0 else 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		var col := Color(1.0, 0.25, 0.2, blink) if i < stars else Color(0.3, 0.3, 0.3, 0.6)
		wanted_bar.draw_colored_polygon(pts, col)
	var f := ThemeDB.fallback_font
	wanted_bar.draw_string_outline(f, Vector2(0, 20), Loc.t("WANTED"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
	wanted_bar.draw_string(f, Vector2(0, 20), Loc.t("WANTED"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.35, 0.3))


func _draw_minimap() -> void:
	var pp := Vector2(player.global_position.x, player.global_position.z)
	var yaw := player.rotation.y
	_draw_map(minimap, pp, MINI_SCALE, yaw, false)
	var c := minimap.size * 0.5
	_draw_arrow(minimap, c, Vector2(0, -1), 8.0)
	var n := c + Vector2(0, -1).rotated(yaw) * (MINI_SIZE * 0.5 - 14.0)
	minimap.draw_circle(n, 9.0, Color(0, 0, 0, 0.6))
	minimap.draw_string(ThemeDB.fallback_font, n + Vector2(-5, 5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.4))


func _draw_bigmap() -> void:
	var half: float = world.map_half
	var scl := BIG_SIZE / (half * 2.0)
	_draw_map(bigmap, Vector2.ZERO, scl, 0.0, true)
	var c := bigmap.size * 0.5
	var pp := Vector2(player.global_position.x, player.global_position.z)
	var yaw := player.rotation.y
	_draw_arrow(bigmap, c + pp * scl, Vector2(-sin(yaw), -cos(yaw)), 10.0)


func _draw_map(ctrl: Control, origin: Vector2, scl: float, rot: float, labels: bool) -> void:
	var c := ctrl.size * 0.5
	var half: float = world.map_half
	ctrl.draw_rect(Rect2(Vector2.ZERO, ctrl.size), Color(0.12, 0.2, 0.1, 0.9))
	ctrl.draw_set_transform(c, rot, Vector2.ONE)
	ctrl.draw_rect(Rect2((Vector2(-half, -half) - origin) * scl, Vector2(half, half) * 2.0 * scl), Color(0.27, 0.42, 0.19))
	for seg in world.path_segments:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		ctrl.draw_line((a - origin) * scl, (b - origin) * scl, Color(0.62, 0.5, 0.32), maxf(2.0, 3.5 * scl))
	for lm in world.landmarks:
		var lp: Vector2 = lm["pos"]
		var lr: float = lm["radius"]
		var lc: Color = lm["color"]
		ctrl.draw_circle((lp - origin) * scl, lr * scl, Color(lc, 0.5))
	var view := ctrl.size.length() * 0.5 + 4.0
	for tp: Vector2 in world.tree_points:
		var tpp := (tp - origin) * scl
		if absf(tpp.x) < view and absf(tpp.y) < view:
			ctrl.draw_circle(tpp, maxf(1.5, 1.3 * scl), Color(0.1, 0.24, 0.08))
	for pk in get_tree().get_nodes_in_group("pickups"):
		var kp := Vector2((pk as Node3D).global_position.x, (pk as Node3D).global_position.z)
		ctrl.draw_circle((kp - origin) * scl, 3.0, Color(1.0, 0.85, 0.2))
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		var ep := (Vector2(e.global_position.x, e.global_position.z) - origin) * scl
		var r := 6.0 if e.boss else 3.5
		ctrl.draw_circle(ep, r + 1.3, Color(0, 0, 0, 0.8))
		ctrl.draw_circle(ep, r, Color(1.0, 0.5, 0.1) if e.boss else (Color(0.75, 0.35, 1.0) if e.ranged else Color(1.0, 0.2, 0.15)))
	for g in get_tree().get_nodes_in_group("gather_items"):
		var gp := (Vector2((g as Node3D).global_position.x, (g as Node3D).global_position.z) - origin) * scl
		ctrl.draw_circle(gp, 4.5, Color(0, 0, 0, 0.8))
		ctrl.draw_circle(gp, 3.5, Color(0.35, 0.95, 1.0))
	if not _objective.is_empty():
		var op3: Vector3 = _objective["pos"]
		var op := (Vector2(op3.x, op3.z) - origin) * scl
		if not labels:
			# minimap: keep the target on the rim when it is out of range
			var edge := ctrl.size.x * 0.5 - 12.0
			if op.length() > edge:
				op = op.normalized() * edge
		var pulse := 1.0 + 0.25 * sin(Time.get_ticks_msec() * 0.006)
		ctrl.draw_arc(op, 10.0 * pulse, 0.0, TAU, 24, Color(0, 0, 0, 0.75), 5.0)
		ctrl.draw_arc(op, 10.0 * pulse, 0.0, TAU, 24, Color(1.0, 0.82, 0.25), 2.5)
	var font2 := ThemeDB.fallback_font
	for n in get_tree().get_nodes_in_group("npcs"):
		var npc := n as QuestGiver
		var np := (Vector2(npc.global_position.x, npc.global_position.z) - origin) * scl
		var mk: String = world.quests.marker_for(npc.id) if world.quests else ""
		ctrl.draw_circle(np, 7.0, Color(0, 0, 0, 0.8))
		ctrl.draw_circle(np, 5.5, Color(0.35, 0.9, 0.35))
		if mk != "":
			var mc := Color(0.6, 0.6, 0.6) if mk == "." else Color(1.0, 0.85, 0.1)
			var txt := "?" if mk == "." else mk
			# keep the glyph upright even on the rotating minimap
			ctrl.draw_set_transform(c + np.rotated(rot), 0.0, Vector2.ONE)
			ctrl.draw_string_outline(font2, Vector2(-5, 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color.BLACK)
			ctrl.draw_string(font2, Vector2(-5, 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, mc)
			ctrl.draw_set_transform(c, rot, Vector2.ONE)
	ctrl.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if labels:
		var font := ThemeDB.fallback_font
		for lm in world.landmarks:
			var lp: Vector2 = lm["pos"]
			var text: String = lm["name"]
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			var sp := c + (lp - origin) * scl + Vector2(-w * 0.5, 5)
			ctrl.draw_string_outline(font, sp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
			ctrl.draw_string(font, sp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.92, 0.7))


func _draw_arrow(ctrl: Control, pos: Vector2, fwd: Vector2, s: float) -> void:
	var side := Vector2(-fwd.y, fwd.x)
	var pts := PackedVector2Array([pos + fwd * s, pos - fwd * s * 0.6 + side * s * 0.7, pos - fwd * s * 0.25, pos - fwd * s * 0.6 - side * s * 0.7])
	ctrl.draw_colored_polygon(pts, Color.WHITE)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ctrl.draw_polyline(outline, Color.BLACK, 1.5)
