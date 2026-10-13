extends Control
## Main menu: live 3D village at dusk behind a dark gothic menu (Continue / New Game /
## Settings / Admin / Exit). Buttons glow like embers on hover; the title flickers.

const GOLD := Color(0.86, 0.68, 0.36)
const BONE := Color(0.93, 0.89, 0.8)
const EMBER := Color(1.0, 0.5, 0.22)
const BLOOD := Color(0.55, 0.04, 0.03)

var _title: Label
var _fade: ColorRect
var _buttons: Array[Button] = []
var _t := 0.0
var _busy := false
var _column: VBoxContainer


static func title_font() -> Font:
	var f := SystemFont.new()
	# the blackletter font has no Cyrillic letters: use a classic serif for Ukrainian
	if Loc.is_uk():
		f.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Times New Roman"])
	else:
		f.font_names = PackedStringArray(["Old English Text MT", "Cinzel Decorative", "Cinzel", "Trajan Pro", "Georgia", "Times New Roman"])
	f.font_weight = 700
	return f


static func serif_font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Georgia", "Palatino Linotype", "Times New Roman"])
	return f


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scene := MenuScene.new()
	add_child(scene)

	_build_overlays()
	_build_title()
	_build_buttons()
	_build_footer()

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 1.6).set_trans(Tween.TRANS_SINE)

	resized.connect(_fit)
	_fit.call_deferred()
	Game.stop_ambience()
	Game.play_music("rpg/ambient_1")
	Game.play_ambience("wind")


# --------------------------------------------------------------------------- layers

func _build_overlays() -> void:
	# darken the left side where the menu sits, and the corners (vignette)
	var side := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.6, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.82), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	side.texture = gt
	side.stretch_mode = TextureRect.STRETCH_SCALE
	side.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	side.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(side)
	var vig := TextureRect.new()
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.15), Color(0, 0, 0, 0.85)])
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5)
	vt.fill_to = Vector2(1.05, 1.05)
	vig.texture = vt
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)
	# embers floating up over the menu
	var em := CPUParticles2D.new()
	em.amount = 70
	em.lifetime = 7.0
	em.preprocess = 7.0
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = Vector2(900, 20)
	em.position = Vector2(640, 760)
	em.direction = Vector2(0.15, -1)
	em.spread = 25.0
	em.gravity = Vector2(8, -6)
	em.initial_velocity_min = 25.0
	em.initial_velocity_max = 70.0
	em.scale_amount_min = 1.5
	em.scale_amount_max = 4.0
	var cr := Gradient.new()
	cr.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	cr.colors = PackedColorArray([Color(1.0, 0.75, 0.35, 0.0), Color(1.0, 0.6, 0.25, 0.9), Color(0.8, 0.2, 0.05, 0.0)])
	em.color_ramp = cr
	add_child(em)
	resized.connect(func() -> void:
		em.position = Vector2(size.x * 0.5, size.y + 40)
		em.emission_rect_extents = Vector2(size.x * 0.6, 20))


func _build_title() -> void:
	_column = VBoxContainer.new()
	_column.position = Vector2(80, 60)
	_column.add_theme_constant_override("separation", 34)
	add_child(_column)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_column.add_child(box)
	_title = Label.new()
	_title.text = Loc.t("NORTHVALE")
	_title.add_theme_font_override("font", title_font())
	_title.add_theme_font_size_override("font_size", 104)
	_title.add_theme_color_override("font_color", BONE)
	_title.add_theme_color_override("font_outline_color", BLOOD)
	_title.add_theme_constant_override("outline_size", 14)
	_title.add_theme_color_override("font_shadow_color", Color(0.8, 0.1, 0.05, 0.55))
	_title.add_theme_constant_override("shadow_offset_x", 0)
	_title.add_theme_constant_override("shadow_offset_y", 0)
	_title.add_theme_constant_override("shadow_outline_size", 40)
	box.add_child(_title)
	var line := ColorRect.new()
	line.color = GOLD
	line.custom_minimum_size = Vector2(430, 2)
	box.add_child(line)
	var sub := Label.new()
	sub.text = _spaced(Loc.t("The Grey Blight").to_upper())
	sub.add_theme_font_override("font", serif_font())
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", GOLD)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	sub.add_theme_constant_override("outline_size", 6)
	box.add_child(sub)


func _spaced(s: String) -> String:
	var out := ""
	for ch in s:
		out += ch + " "
	return out.strip_edges()


func _build_buttons() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	_column.add_child(col)
	var save := SaveGame.peek()
	if not save.is_empty():
		var li := clampi(int(save.get("level_index", 0)), 0, Game.LEVELS.size() - 1)
		var lvl := int(save.get("progress", {}).get("level", 1))
		_add(col, Loc.t("Continue"), func() -> void: _go_ai(Game.continue_game), "%s  ·  %s %d" % [Loc.t(Game.LEVELS[li]["name"]), Loc.t("Level"), lvl])
	_add(col, Loc.t("New Game"), func() -> void: _go_ai(Game.start_game))
	_add(col, Loc.t("Settings"), func() -> void:
		var s := SettingsMenu.new()
		add_child(s)
		s.closed.connect(func() -> void: get_tree().reload_current_scene()))
	_add(col, Loc.t("Admin"), func() -> void:
		var a := AdminMenu.new()
		add_child(a)
		a.closed.connect(func() -> void: _buttons[0].grab_focus()), "", true)
	_add(col, Loc.t("Exit Game"), func() -> void: _go(Game.quit_game))
	_buttons[0].grab_focus.call_deferred()
	# the AI brain (Ollama + Qwen3 + Python) is needed to play: show how it's doing
	_ai_label = Label.new()
	_ai_label.visible = Brain.ENABLED
	_ai_label.add_theme_font_size_override("font_size", 18)
	_ai_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_ai_label.add_theme_constant_override("outline_size", 5)
	_ai_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ai_label.custom_minimum_size = Vector2(440, 0)
	col.add_child(_ai_label)
	_show_ai(Brain.status)
	Brain.status_changed.connect(_show_ai)
	# buttons fade in one after another
	for i in _buttons.size():
		var b := _buttons[i]
		b.modulate.a = 0.0
		var tw := b.create_tween()
		tw.tween_interval(0.5 + i * 0.09)
		tw.tween_property(b, "modulate:a", 1.0, 0.45)


var _ai_label: Label


func _show_ai(text: String) -> void:
	if not is_instance_valid(_ai_label):
		return
	_ai_label.text = ("●  " if Brain.is_ready else "○  ") + text
	_ai_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55) if Brain.is_ready else Color(1.0, 0.75, 0.4))


## Starting a game needs the AI brain; until it's ready the button only explains why.
func _go_ai(action: Callable) -> void:
	if Brain.is_ready or not Brain.ENABLED:
		_go(action)
		return
	_show_ai(Brain.status + "  -  " + Loc.t("the game needs the AI brain, please wait"))
	var tw := _ai_label.create_tween()
	tw.tween_property(_ai_label, "modulate", Color(1.6, 1.2, 0.8), 0.15)
	tw.tween_property(_ai_label, "modulate", Color.WHITE, 0.4)


func _add(col: VBoxContainer, text: String, action: Callable, note := "", dim := false) -> Button:
	var b := Button.new()
	b.text = "   " + text.to_upper()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(420, 56)
	b.add_theme_font_override("font", serif_font())
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color(0.75, 0.55, 0.5) if dim else BONE)
	b.add_theme_color_override("font_hover_color", EMBER)
	b.add_theme_color_override("font_focus_color", EMBER)
	b.add_theme_color_override("font_hover_pressed_color", Color(1.0, 0.8, 0.5))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.8, 0.5))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 6)
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	var hl := StyleBoxFlat.new()
	hl.bg_color = Color(0.5, 0.12, 0.05, 0.28)
	hl.border_color = EMBER
	hl.border_width_left = 3
	hl.shadow_color = Color(1.0, 0.35, 0.1, 0.25)
	hl.shadow_size = 12
	b.add_theme_stylebox_override("hover", hl)
	b.add_theme_stylebox_override("focus", hl)
	b.add_theme_stylebox_override("pressed", hl)
	b.pressed.connect(func() -> void:
		Game.play_sound("quest_accept", null, -8.0)
		action.call())
	b.mouse_entered.connect(func() -> void: b.grab_focus())
	b.focus_entered.connect(func() -> void:
		Game.play_sound("pickup_tech", null, -16.0, 0.6)
		b.create_tween().tween_property(b, "position:x", 14.0, 0.12).set_trans(Tween.TRANS_SINE))
	b.focus_exited.connect(func() -> void:
		b.create_tween().tween_property(b, "position:x", 0.0, 0.15).set_trans(Tween.TRANS_SINE))
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(440, 58 + (22 if note != "" else 0))
	wrap.add_child(b)
	if note != "":
		var n := Label.new()
		n.text = note
		n.position = Vector2(34, 52)
		n.add_theme_font_override("font", serif_font())
		n.add_theme_font_size_override("font_size", 16)
		n.add_theme_color_override("font_color", Color(GOLD, 0.85))
		wrap.add_child(n)
	col.add_child(wrap)
	var sep := ColorRect.new()
	sep.color = Color(GOLD, 0.25)
	sep.custom_minimum_size = Vector2(300, 1)
	col.add_child(sep)
	_buttons.append(b)
	return b


func _build_footer() -> void:
	var help := Label.new()
	help.text = Loc.t("WASD move   Shift sprint   Space jump   LMB shoot   RMB aim   R reload   1/2 weapons   Q E X C G V T skills   F use   I inventory   K skills   L flashlight   M map")
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.anchor_right = 1.0
	help.offset_left = 84
	help.offset_top = -40
	help.offset_bottom = -16
	help.offset_right = -190
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)
	var ver := Label.new()
	ver.text = "v1.0  ·  Godot 4.7"
	ver.add_theme_font_size_override("font_size", 13)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	ver.anchor_left = 1.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -170
	ver.offset_top = -40
	ver.offset_bottom = -16
	add_child(ver)


## Shrinks the title + buttons when they don't fit (big UI scale or small window).
func _fit() -> void:
	if _column == null:
		return
	var need := _column.get_combined_minimum_size().y
	var avail := size.y - 60.0 - 56.0
	var s := clampf(avail / maxf(need, 1.0), 0.45, 1.0)
	_column.scale = Vector2.ONE * s


func _go(action: Callable) -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	tw.tween_callback(action)


func _process(delta: float) -> void:
	_t += delta
	# the title's red glow breathes and sometimes flickers
	var f := 0.55 + 0.2 * sin(_t * 1.3)
	if randf() < 0.01:
		f = 0.15
	_title.add_theme_color_override("font_shadow_color", Color(0.8, 0.1, 0.05, f))
