class_name SettingsMenu
extends ColorRect
## Full-screen settings overlay: display, graphics quality, mouse and volume.

signal closed

const QUALITY := ["Low", "Medium", "High", "Ultra"]

var _first: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0, 0, 0, 0.7)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.13, 0.96)
	sb.border_color = Color(0.85, 0.7, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Game.make_label(Loc.t("SETTINGS"), 44, Color(1.0, 0.84, 0.38))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)

	_first = _check(grid, Loc.t("Fullscreen  (F11)"), "fullscreen")
	_check(grid, Loc.t("VSync"), "vsync")
	grid.add_child(_label(Loc.t("Graphics quality")))
	var opt := OptionButton.new()
	for q in QUALITY:
		opt.add_item(q)
	opt.select(int(Game.settings["quality"]))
	opt.custom_minimum_size = Vector2(260, 40)
	opt.add_theme_font_size_override("font_size", 20)
	opt.item_selected.connect(func(i: int) -> void: _change("quality", i))
	grid.add_child(opt)
	_slider(grid, Loc.t("Mouse sensitivity"), "sensitivity", 0.2, 3.0)
	_slider(grid, Loc.t("Master volume"), "master", 0.0, 1.0)
	_slider(grid, Loc.t("Music volume"), "music", 0.0, 1.0)
	_slider(grid, Loc.t("Effects volume"), "sfx", 0.0, 1.0)
	grid.add_child(_label(Loc.t("UI scale")))
	var uh := HBoxContainer.new()
	var us := HSlider.new()
	us.min_value = 0.45
	us.max_value = 2.0
	us.step = 0.05
	us.value = float(Game.settings.get("ui_scale", 0.0)) if float(Game.settings.get("ui_scale", 0.0)) > 0.0 else 0.45
	us.custom_minimum_size = Vector2(200, 30)
	us.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var uv := Game.make_label("", 18)
	uv.custom_minimum_size = Vector2(70, 0)
	var show := func(v: float) -> void: uv.text = Loc.t("Auto") if v < 0.5 else "%d%%" % int(v * 100.0)
	show.call(us.value)
	# applied when the slider is released, so the menu doesn't jump while dragging
	us.value_changed.connect(func(v: float) -> void: show.call(v))
	us.drag_ended.connect(func(_c: bool) -> void: _change("ui_scale", 0.0 if us.value < 0.5 else us.value))
	uh.add_child(us)
	uh.add_child(uv)
	grid.add_child(uh)
	_check(grid, Loc.t("Story cutscenes"), "cutscenes")
	grid.add_child(_label(Loc.t("Narration language")))
	var lang := OptionButton.new()
	lang.add_item("English")
	lang.add_item("Українська (Ukrainian)")
	lang.select(int(Game.settings.get("narration", 0)))
	lang.custom_minimum_size = Vector2(260, 40)
	lang.add_theme_font_size_override("font_size", 20)
	lang.item_selected.connect(func(i: int) -> void: _change("narration", i))
	grid.add_child(lang)

	var note := Game.make_label(Loc.t("Grass density changes apply when the next location loads."), 15, Color(0.75, 0.75, 0.8))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(note)
	var back := Game.make_button(Loc.t("Back"))
	back.pressed.connect(_close)
	vb.add_child(back)
	_first.grab_focus.call_deferred()


func _label(text: String) -> Label:
	var l := Game.make_label(text, 22, Color(0.92, 0.92, 0.95))
	l.custom_minimum_size = Vector2(240, 0)
	return l


func _check(grid: GridContainer, text: String, key: String) -> CheckButton:
	grid.add_child(_label(text))
	var c := CheckButton.new()
	c.button_pressed = bool(Game.settings[key])
	c.toggled.connect(func(on: bool) -> void: _change(key, on))
	grid.add_child(c)
	return c


func _slider(grid: GridContainer, text: String, key: String, lo: float, hi: float) -> void:
	grid.add_child(_label(text))
	var hb := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(200, 30)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var val := Game.make_label(Loc.t("%d%%") % int(s.value * 100.0), 18)
	val.custom_minimum_size = Vector2(60, 0)
	s.value_changed.connect(func(v: float) -> void:
		val.text = Loc.t("%d%%") % int(v * 100.0)
		_change(key, v))
	hb.add_child(s)
	hb.add_child(val)
	grid.add_child(hb)


func _change(key: String, value: Variant) -> void:
	Game.settings[key] = value
	Game.apply_settings()


func _close() -> void:
	Game.save_settings()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
