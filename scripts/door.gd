class_name HouseDoor
extends Node3D
## Hinged plank door. This node is the hinge (at floor level); the slab is an AnimatableBody3D
## child so it blocks the player and creatures when closed. Press F to open / close.

@export var width := 1.2
@export var height := 2.2
@export var open_angle := 105.0       # degrees; positive swings towards -z (into the house)
var is_open := false
@export var style := "plank"          # "iron": a wrought-iron gate leaf (railings, churchyards)
@export var start_open := false
var _slab: AnimatableBody3D
var _shape: CollisionShape3D
var _busy := false


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("doors")
	_slab = AnimatableBody3D.new()
	_slab.sync_to_physics = false
	_slab.set_meta("surface", "wood")
	add_child(_slab)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(width, height, 0.08)
	cs.shape = sh
	cs.position = Vector3(width * 0.5, height * 0.5, 0)
	_slab.add_child(cs)
	_shape = cs
	if style == "iron":
		_build_iron()
	elif style == "church" or height > 3.5:
		_build_church()
	elif not KitBuild.door(_slab, width, height):
		_build_planks()
	if start_open:
		is_open = true
		_slab.rotation_degrees.y = open_angle


## A wrought-iron leaf: frame, spear-topped bars rising towards the middle of the gateway, scrolls.
func _build_iron() -> void:
	var ir := MeshKit.mat(Color(0.07, 0.07, 0.075), 0.45, 0.75)
	var crest := 0.32
	for y in [0.12, height * 0.42]:
		MeshKit.box(_slab, Vector3(width, 0.05, 0.04), Vector3(width * 0.5, y, 0), ir)
	MeshKit.box(_slab, Vector3(0.06, height - 0.1, 0.05), Vector3(0.03, (height - 0.1) * 0.5 + 0.05, 0), ir)
	MeshKit.box(_slab, Vector3(0.05, height - crest, 0.05), Vector3(width - 0.03, (height - crest) * 0.5, 0), ir)
	var count := maxi(3, int(width / 0.13))
	var prev := Vector3.ZERO
	for i in count + 1:
		var x := width * i / count
		var top := height - crest + crest * sin(0.5 * PI * x / width)
		if i > 0 and i < count:
			MeshKit.cyl(_slab, 0.011, 0.011, top - 0.1, Vector3(x, 0.1 + (top - 0.1) * 0.5, 0), ir, Vector3.ZERO, 6)
			MeshKit.cyl(_slab, 0.0, 0.032, 0.12, Vector3(x, top + 0.06, 0), ir, Vector3.ZERO, 4)
		# the arched top rail follows the bar tops
		var p := Vector3(x, top - 0.16, 0)
		if i > 0:
			var d := p - prev
			MeshKit.box(_slab, Vector3(d.length() + 0.02, 0.05, 0.04), (p + prev) * 0.5, ir, Vector3(0, 0, rad_to_deg(atan2(d.y, d.x))))
		prev = p
	# scrollwork in the upper panel: two big rings and two small ones between them
	var y0 := height * 0.42
	var y1 := height - crest - 0.16
	for sc in [[0.3, 0.5, 0.24], [0.7, 0.5, 0.24], [0.5, 0.2, 0.16], [0.5, 0.8, 0.16]]:
		var r: float = (y1 - y0) * sc[2]
		var ring := TorusMesh.new()
		ring.inner_radius = r
		ring.outer_radius = r + 0.02
		ring.rings = 16
		ring.ring_segments = 4
		MeshKit.inst(_slab, ring, Vector3(width * sc[0], y0 + (y1 - y0) * sc[1], 0), ir, Vector3(90, 0, 0))


## A tall church door leaf, after medieval cathedral west doors (Salisbury, Lichfield): square-headed
## oak boards filling the doorway up to the lintel, long wrought-iron strap hinges with scrolled
## ends on both faces, rows of nail heads along the straps and a ring handle.
func _build_church() -> void:
	var oak := MeshKit.textured("Planks021", Color(0.5, 0.34, 0.22), 0.9, 0.35, 0.72)
	var iron := MeshKit.mat(Color(0.08, 0.075, 0.07), 0.55, 0.8)
	var boards := maxi(4, int(round(width / 0.24)))
	var bw := width / boards
	for i in boards:
		var d := 0.085 + (0.012 if i % 2 == 0 else 0.0)
		MeshKit.box(_slab, Vector3(bw - 0.01, height, d), Vector3(bw * (i + 0.5), height * 0.5, 0), oak)
	var hinges := [0.45, height * 0.36, height * 0.64, height - 0.45]
	for side in [-1.0, 1.0]:
		var z: float = side * 0.058
		for y: float in hinges:
			MeshKit.box(_slab, Vector3(width * 0.9, 0.1, 0.02), Vector3(width * 0.45, y, z), iron)
			# scrolled end: a ring and two curled branches
			var ring := TorusMesh.new()
			ring.inner_radius = 0.07
			ring.outer_radius = 0.1
			ring.rings = 14
			ring.ring_segments = 4
			MeshKit.inst(_slab, ring, Vector3(width * 0.9 + 0.06, y, z), iron, Vector3(90, 0, 0))
			for b in [-1.0, 1.0]:
				MeshKit.box(_slab, Vector3(0.38, 0.05, 0.018), Vector3(width * 0.74, y + b * 0.11, z), iron, Vector3(0, 0, b * 22.0))
			# nail heads along the strap
			for k in range(1, 7):
				MeshKit.box(_slab, Vector3(0.035, 0.035, 0.03), Vector3(width * 0.9 * k / 7.0, y, z + side * 0.008), iron)
	# ring handle on the outer face, near the free edge
	var handle := TorusMesh.new()
	handle.inner_radius = 0.09
	handle.outer_radius = 0.115
	handle.rings = 16
	handle.ring_segments = 5
	MeshKit.inst(_slab, handle, Vector3(width - 0.28, 1.1, 0.075), iron, Vector3(90, 0, 0))
	MeshKit.box(_slab, Vector3(0.12, 0.12, 0.02), Vector3(width - 0.28, 1.2, 0.068), iron)


func _build_planks() -> void:
	var wood := MeshKit.textured("Planks021", Color(0.6, 0.4, 0.26), 1.4, 0.3, 0.8)
	var iron := MeshKit.mat(Color(0.14, 0.13, 0.13), 0.5, 0.85)
	var planks := 5
	for i in planks:
		var pw := width / planks
		MeshKit.box(_slab, Vector3(pw - 0.012, height - 0.02, 0.07), Vector3(pw * (i + 0.5), height * 0.5, 0), wood)
	for y in [0.35, height - 0.4]:
		MeshKit.box(_slab, Vector3(width * 0.92, 0.07, 0.02), Vector3(width * 0.47, y, 0.045), iron)
		MeshKit.box(_slab, Vector3(width * 0.92, 0.07, 0.02), Vector3(width * 0.47, y, -0.045), iron)
	MeshKit.box(_slab, Vector3(width - 0.1, 0.12, 0.05), Vector3(width * 0.5, height * 0.5, -0.04), wood, Vector3(0, 0, -rad_to_deg(atan2(height - 1.0, width))))
	for side in [-1.0, 1.0]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.045
		ring.outer_radius = 0.06
		ring.rings = 12
		ring.ring_segments = 5
		MeshKit.inst(_slab, ring, Vector3(width - 0.17, 1.0, side * 0.06), iron, Vector3(90, 0, 0))
		MeshKit.sphere(_slab, 0.03, Vector3(width - 0.17, 1.06, side * 0.05), iron)


func prompt() -> String:
	if style == "iron":
		return Loc.t("Close gate") if is_open else Loc.t("Open gate")
	return Loc.t("Close door") if is_open else Loc.t("Open door")


func interact() -> void:
	if _busy:
		return
	_busy = true
	# not solid while swinging, so it never wedges anyone between itself and the wall
	_shape.set_deferred("disabled", true)
	is_open = not is_open
	Game.play_sound("door_open" if is_open else "door_close", global_position + Vector3(0, 1.2, 0), -2.0)
	var tw := create_tween()
	tw.tween_property(_slab, "rotation_degrees:y", open_angle if is_open else 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_busy = false
		_shape.set_deferred("disabled", false))


## Villagers open and close doors as they walk through.
func npc_open() -> void:
	if not is_open and not _busy:
		interact()


func npc_close() -> void:
	if is_open and not _busy:
		interact()