class_name AdminMenu
extends ColorRect
## Main-menu admin overlay: login (admin / admin), then a level select to jump into any
## location with a character at that location's level. In game, F1 opens the admin panel and
## ~ the console (see admin_panel.gd).

signal closed

var _vb: VBoxContainer
var _user: LineEdit
var _pass: LineEdit
var _error: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0, 0, 0, 0.75)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.08, 0.97)
	sb.border_color = Color(0.85, 0.25, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 12)
	panel.add_child(_vb)
	if Game.admin:
		_show_levels()
	else:
		_show_login()


func _clear() -> void:
	for c in _vb.get_children():
		c.queue_free()


func _show_login() -> void:
	_clear()
	var title := Game.make_label(Loc.t("ADMIN LOGIN"), 40, Color(1.0, 0.45, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(title)
	_user = _field(Loc.t("Login"), false)
	_pass = _field(Loc.t("Password"), true)
	_pass.text_submitted.connect(func(_t: String) -> void: _try_login())
	_error = Game.make_label("", 18, Color(1.0, 0.4, 0.3))
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(_error)
	var ok := Game.make_button(Loc.t("Log in"))
	ok.pressed.connect(_try_login)
	_vb.add_child(ok)
	var back := Game.make_button(Loc.t("Back"))
	back.pressed.connect(_close)
	_vb.add_child(back)
	_user.grab_focus.call_deferred()


func _field(placeholder: String, secret: bool) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.secret = secret
	e.custom_minimum_size = Vector2(320, 44)
	e.add_theme_font_size_override("font_size", 22)
	_vb.add_child(e)
	return e


func _try_login() -> void:
	if _user.text.strip_edges().to_lower() == "admin" and _pass.text == "admin":
		Game.admin = true
		Game.play_sound("quest_accept", null, -4.0)
		_show_levels()
	else:
		_error.text = Loc.t("Wrong login or password")
		Game.play_sound("empty", null, -2.0)


func _show_levels() -> void:
	_clear()
	var title := Game.make_label(Loc.t("ADMIN: LEVEL SELECT"), 36, Color(1.0, 0.45, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(title)
	var note := Game.make_label(Loc.t("Starts the location with a character at its level. In game: F1 admin panel, ~ console."), 16, Color(0.8, 0.8, 0.85))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(560, 0)
	_vb.add_child(note)
	for i in Game.LEVELS.size():
		var info: Dictionary = Game.LEVELS[i]
		var zl: Vector2i = Game.ZONE_LEVELS[i]
		var b := Game.make_button("%d.  %s   (%s %d-%d)" % [i + 1, Loc.t(info["name"]), Loc.t("Lv"), zl.x, zl.y], 520.0)
		b.pressed.connect(Game.start_at_level.bind(i))
		_vb.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
	var god := CheckButton.new()
	god.text = Loc.t("God mode")
	god.button_pressed = Game.god_mode
	god.add_theme_font_size_override("font_size", 20)
	god.toggled.connect(func(on: bool) -> void: Game.god_mode = on)
	_vb.add_child(god)
	var out := Game.make_button(Loc.t("Log out"))
	out.pressed.connect(func() -> void:
		Game.admin = false
		Game.god_mode = false
		_show_login())
	_vb.add_child(out)
	var back := Game.make_button(Loc.t("Back"))
	back.pressed.connect(_close)
	_vb.add_child(back)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
