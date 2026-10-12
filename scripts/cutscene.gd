class_name Cutscene
extends CanvasLayer
## Story flyover before each level: letterbox bars, a chapter title, four narrated shots over the
## level's landmarks (voice from assets/voice/cs<level>_<n>[_uk].wav) and a descent to the player.
## Space / Enter / Esc skips. Emits `finished` when done.

signal finished

const NUMERALS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]

var world: Node
var level := 0
var _cam: Camera3D
var _shots: Array = []        # {"from", "to", "look_from", "look_to", "time"}
var _shot := -1
var _t := 0.0
var _voice: AudioStreamPlayer
var _top: ColorRect
var _bottom: ColorRect
var _sub: Label
var _sub2: Label
var _chapter: Label
var _chapter_name: Label
var _fade: ColorRect
var _ending := false
var _uk := false


func _ready() -> void:
	layer = 50
	_uk = int(Game.settings.get("narration", 0)) == 1
	_build_ui()
	_cam = Camera3D.new()
	_cam.fov = 60.0
	_cam.far = 900.0
	_cam.cull_mask = world.player.camera.cull_mask
	world.add_child(_cam)
	_cam.current = true
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX"
	_voice.volume_db = 4.0
	_voice.pitch_scale = 1.0
	add_child(_voice)
	_plan()
	world.player.input_locked = true
	world.player.weapon_layer.visible = false
	world.hud.visible = false
	_set_enemy_labels(false)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.2)
	_next_shot()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_top = ColorRect.new()
	_top.color = Color.BLACK
	_top.anchor_right = 1.0
	_top.anchor_bottom = 0.12
	root.add_child(_top)
	_bottom = ColorRect.new()
	_bottom.color = Color.BLACK
	_bottom.anchor_top = 0.84
	_bottom.anchor_right = 1.0
	_bottom.anchor_bottom = 1.0
	root.add_child(_bottom)
	_sub = _label(26, Color(0.95, 0.93, 0.88))
	_sub.anchor_left = 0.1
	_sub.anchor_right = 0.9
	_sub.anchor_top = 0.855
	_sub.anchor_bottom = 0.93
	root.add_child(_sub)
	_sub2 = _label(17, Color(0.7, 0.7, 0.72))
	_sub2.anchor_left = 0.1
	_sub2.anchor_right = 0.9
	_sub2.anchor_top = 0.93
	_sub2.anchor_bottom = 0.98
	root.add_child(_sub2)
	var info: Dictionary = Game.current_level()
	_chapter = _label(30, Color(0.85, 0.7, 0.4))
	_chapter.text = ("РОЗДІЛ " if _uk else "CHAPTER ") + NUMERALS[mini(level, NUMERALS.size() - 1)]
	_chapter.anchor_right = 1.0
	_chapter.anchor_top = 0.36
	_chapter.anchor_bottom = 0.42
	root.add_child(_chapter)
	_chapter_name = _label(64, Color(1.0, 0.9, 0.7))
	_chapter_name.text = "%s\n%s" % [str(info["name"]).to_upper(), info["subtitle"]]
	_chapter_name.add_theme_font_size_override("font_size", 60)
	_chapter_name.anchor_right = 1.0
	_chapter_name.anchor_top = 0.42
	_chapter_name.anchor_bottom = 0.62
	root.add_child(_chapter_name)
	for l: Label in [_chapter, _chapter_name]:
		l.modulate.a = 0.0
		var tw := l.create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(l, "modulate:a", 1.0, 1.0)
		tw.tween_interval(2.8)
		tw.tween_property(l, "modulate:a", 0.0, 1.0)
	var skip := _label(15, Color(0.6, 0.6, 0.62))
	skip.text = "[Space]  skip"
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.anchor_left = 0.7
	skip.anchor_right = 0.98
	skip.anchor_top = 0.03
	skip.anchor_bottom = 0.09
	root.add_child(skip)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Four shots: high establishing orbit, orbit around landmark A, dolly towards landmark B,
## and a descent behind the player's starting spot.
func _plan() -> void:
	var half: float = world.half
	var lms: Array = world.landmarks.duplicate()
	var wanted: Array = world.cfg.get("cutscene", [])
	var picks := []
	for name in wanted:
		for lm in lms:
			if lm["name"] == name:
				picks.append(lm)
	lms.sort_custom(func(a, b): return float(a["radius"]) > float(b["radius"]))
	for lm in lms:
		if picks.size() >= 2:
			break
		if not picks.has(lm):
			picks.append(lm)
	var c := Vector3.ZERO
	_shots.append({"orbit": c, "radius": half * 0.75, "height": 70.0, "a0": -2.4, "a1": -1.7, "look_y": 0.0})
	if picks.size() > 0:
		var p: Vector2 = picks[0]["pos"]
		_shots.append({"orbit": Vector3(p.x, 0, p.y), "radius": float(picks[0]["radius"]) + 18.0, "height": 12.0, "a0": 0.4, "a1": 1.5, "look_y": 3.0})
	if picks.size() > 1:
		var p: Vector2 = picks[1]["pos"]
		var t := Vector3(p.x, 0, p.y)
		var dir := (Vector3(-p.x, 0, -p.y) if p.length() > 1.0 else Vector3(0, 0, -1)).normalized()
		_shots.append({"from": t + dir * 55.0 + Vector3(0, 22, 0), "to": t + dir * 22.0 + Vector3(0, 7, 0), "look_from": t + Vector3(0, 2, 0), "look_to": t + Vector3(0, 3, 0)})
	var start: Vector3 = world.player.global_position
	var fwd: Vector3 = -world.player.global_transform.basis.z
	_shots.append({"from": start - fwd * 26.0 + Vector3(0, 16, 0), "to": start - fwd * 2.0 + Vector3(0, 1.8, 0),
		"look_from": start + fwd * 10.0, "look_to": start + fwd * 30.0 + Vector3(0, 1.5, 0)})
	for i in _shots.size():
		_shots[i]["time"] = _line_length(i + 1) + 1.2


func _line_path(n: int) -> String:
	return "res://assets/voice/cs%d_%d%s.wav" % [level, n, "_uk" if _uk else ""]


func _line_length(n: int) -> float:
	var path := _line_path(n)
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path)
		return maxf(4.5, s.get_length() / _voice.pitch_scale)
	return 6.0


func _next_shot() -> void:
	_shot += 1
	_t = 0.0
	if _shot >= _shots.size():
		_end()
		return
	var n := _shot + 1
	var id := "cs%d_%d%s" % [level, n, "_uk" if _uk else ""]
	_sub.text = QuestManager.line_text(id) if QuestManager.dialogue().get("lines", {}).has(id) else ""
	_sub2.text = QuestManager.line_translation(id)
	for l in [_sub, _sub2]:
		l.modulate.a = 0.0
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.5).set_delay(0.3)
	var path := _line_path(n)
	if ResourceLoader.exists(path):
		_voice.stream = load(path)
		_voice.play()


func _process(delta: float) -> void:
	if _ending or _shot < 0 or _shot >= _shots.size():
		return
	_t += delta
	var s: Dictionary = _shots[_shot]
	var k := clampf(_t / float(s["time"]), 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var pos: Vector3
	var look: Vector3
	if s.has("orbit"):
		var a := lerpf(float(s["a0"]), float(s["a1"]), e)
		var o: Vector3 = s["orbit"]
		pos = o + Vector3(sin(a), 0, cos(a)) * float(s["radius"]) + Vector3(0, float(s["height"]), 0)
		look = o + Vector3(0, float(s["look_y"]), 0)
	else:
		pos = (s["from"] as Vector3).lerp(s["to"], e)
		look = (s["look_from"] as Vector3).lerp(s["look_to"], e)
	pos.y = maxf(pos.y, world.ground(pos.x, pos.z) + 1.6)
	_cam.global_position = pos
	if pos.distance_to(look) > 0.1:
		_cam.look_at(look)
	if _t >= float(s["time"]):
		_next_shot()


func _unhandled_input(event: InputEvent) -> void:
	if _ending:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_end()


func _end() -> void:
	if _ending:
		return
	_ending = true
	_voice.stop()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	tw.tween_callback(func() -> void:
		_cam.queue_free()
		world.player.camera.current = true
		world.player.input_locked = false
		world.player.weapon_layer.visible = true
		_set_enemy_labels(true)
		world.hud.visible = true
		for l in [_sub, _sub2, _chapter, _chapter_name, _top, _bottom]:
			l.visible = false)
	tw.tween_property(_fade, "color:a", 0.0, 0.6)
	tw.tween_callback(func() -> void:
		finished.emit()
		queue_free())


func _set_enemy_labels(on: bool) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.name_label:
			e.name_label.visible = on