class_name TravelUI
extends Control
## VesPer's portal: pick a location to travel to. Shows each location's level range (red when
## it's far above you), whether you've been there, finished it, and which one is next.
## Number keys or click; Esc closes.

var world: Node
var _buttons: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0.02, 0.06, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", InventoryUI._style(Color(0.03, 0.06, 0.12, 0.95), Color(0.35, 0.75, 1.0)))
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var title := Game.make_label(Loc.t("VesPer's Portal"), 28, Color(0.55, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := Game.make_label(Loc.t("Where to?"), 16, Color(0.75, 0.8, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var plevel := int(Game.progress["level"])
	var next := -1
	for i in Game.LEVELS.size():
		if not Game.loc_state(i).get("complete", false):
			next = i
			break
	for i in Game.LEVELS.size():
		var info: Dictionary = Game.LEVELS[i]
		var zl: Vector2i = Game.ZONE_LEVELS[i]
		var st := Game.loc_state(i)
		var status := ""
		if i == Game.level_index:
			status = Loc.t("You are here")
		elif st.get("complete", false):
			status = Loc.t("Complete")
		elif st.get("visited", false):
			status = Loc.t("Visited")
		else:
			status = Loc.t("Unexplored")
		if i == next and i != Game.level_index:
			status += "  -  " + Loc.t("Next")
		var danger := Color(0.55, 1.0, 0.55)
		var warn := ""
		if plevel < zl.x - 5:
			danger = Color(1.0, 0.35, 0.3)
			warn = "  " + Loc.t("(deadly for you!)")
		elif plevel < zl.x:
			danger = Color(1.0, 0.85, 0.35)
			warn = "  " + Loc.t("(dangerous)")
		var b := Game.make_button("", 0.0)
		b.custom_minimum_size = Vector2(620, 58)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 18)
		b.text = "%d.  %s  -  %s\n      %s %d-%d%s     %s" % [i + 1, Loc.t(info["name"]), Loc.t(info["subtitle"]), Loc.t("Level"), zl.x, zl.y, warn, status]
		b.add_theme_color_override("font_color", danger.lerp(Color(1, 0.95, 0.85), 0.35))
		b.disabled = i == Game.level_index
		b.pressed.connect(_go.bind(i))
		vb.add_child(b)
		_buttons.append(b)
	var close := Game.make_button(Loc.t("Stay here") + "  [Esc]", 260.0)
	close.add_theme_font_size_override("font_size", 18)
	close.custom_minimum_size = Vector2(260, 42)
	close.pressed.connect(close_ui)
	vb.add_child(close)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world.player.input_locked = true
	Game.play_sound("blink", null, -10.0, 0.6)


func _go(i: int) -> void:
	world.player.input_locked = false
	Game.play_sound("blink", null, -2.0, 0.8)
	Game.play_sound("cast", null, -4.0, 0.6)
	world.travel(i)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close_ui()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode - KEY_1
		if k >= 0 and k < _buttons.size() and not _buttons[k].disabled:
			get_viewport().set_input_as_handled()
			_go(k)


func close_ui() -> void:
	world.player.input_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
