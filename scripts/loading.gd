extends Control
## Loading screen shown while the next location is generated.

var _frames := 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var info: Dictionary = Game.current_level()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.08, 0.1, 0.16))
	grad.set_color(1, Color(0.02, 0.02, 0.04))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.1, 1.1)
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	for item in [
			["LOCATION %d / %d" % [Game.level_index + 1, Game.LEVELS.size()], 22, Color(0.8, 0.8, 0.85)],
			[info["name"].to_upper(), 80, Color(1.0, 0.84, 0.38)],
			[info["subtitle"], 30, Color(0.92, 0.95, 1.0)],
			["", 20, Color.WHITE],
			[info["tip"], 20, Color(0.75, 0.85, 1.0)],
			["", 20, Color.WHITE],
			["Loading...", 22, Color(0.8, 0.8, 0.8)]]:
		var l := Game.make_label(item[0], item[1], item[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 3:
		get_tree().change_scene_to_file(Game.WORLD_SCENE)
