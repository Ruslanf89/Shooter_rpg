class_name HouseDoor
extends Node3D
## Hinged plank door. This node is the hinge (at floor level); the slab is an AnimatableBody3D
## child so it blocks the player and creatures when closed. Press F to open / close.

var width := 1.2
var height := 2.2
var open_angle := 105.0       # degrees; positive swings towards -z (into the house)
var is_open := false
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
	if KitBuild.door(_slab, width, height):
		return
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