@tool
class_name ExtraRoot
extends Node3D
## Root of a hand-edited level extras scene (scenes/levels/<level>_extra.tscn).
## Everything you put under it appears in the game on top of the generated level:
##   - ExtraProp nodes: game buildings, props, enemies, animals (see extra_prop.gd)
##   - any model you drag in (.glb / .gltf / .tscn), lights, particles, your own scenes
## In the editor the generated level (terrain, buildings, trees, roads) is shown as a grey
## reference to place things against. It is not part of this scene and never loads in the game.

## Give dragged-in models solid collision (so you can't walk through them).
@export var auto_collision := true
## Lift models that are below the ground up onto it (handy when y was left at 0 on a hill).
@export var lift_buried_models := true

## Show the generated level while editing (made by scenes/editor/make_reference.tscn).
@export var show_reference := true:
	set(v):
		show_reference = v
		_update_reference()
@export_file("*.scn") var reference_scene := ""

var world: Node
var _ref: Node


func _ready() -> void:
	_update_reference()


func _update_reference() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _ref and is_instance_valid(_ref):
		_ref.queue_free()
		_ref = null
	if show_reference and reference_scene != "" and ResourceLoader.exists(reference_scene):
		# added without an owner: visible in the editor, never saved into this scene
		_ref = (load(reference_scene) as PackedScene).instantiate()
		_ref.name = "_Reference (editor only)"
		add_child(_ref, false, Node.INTERNAL_MODE_BACK)

## Loads scenes/levels/<id>_extra.tscn for the current level (or returns null).
static func load_for(w: Node, level_script: String) -> ExtraRoot:
	var id := level_script.get_file().get_basename()
	var path := "res://scenes/levels/%s_extra.tscn" % id
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var root := scene.instantiate()
	if not root is ExtraRoot:
		push_warning("%s: the root node should use extra_root.gd" % path)
		root.queue_free()
		return null
	var er := root as ExtraRoot
	var ref := er.get_node_or_null("_Reference")
	if ref:
		er.remove_child(ref)
		ref.free()
	er.world = w
	w.add_child(er)
	return er


## Phase 1 (with the level buildings): props, buildings, models.
func build_static() -> void:
	for c in get_children():
		if c is ExtraProp:
			(c as ExtraProp).build_static(world)
		elif c is Node3D:
			_prepare_model(c as Node3D)


## Phase 2 (after the player exists): enemies, animals, traders, guards.
func build_dynamic() -> void:
	for c in get_children():
		if c is ExtraProp:
			(c as ExtraProp).build_dynamic(world)


func _prepare_model(n: Node3D) -> void:
	if n is Light3D or n is GPUParticles3D or n is CPUParticles3D or n is Camera3D:
		return
	if lift_buried_models:
		var gp := n.global_position
		var g: float = world.ground(gp.x, gp.z)
		if gp.y < g - 0.05:
			n.global_position = Vector3(gp.x, g, gp.z)
	if not auto_collision:
		return
	# only add collision when the model has none of its own
	if not n.find_children("*", "CollisionShape3D", true, false).is_empty() or n is CollisionObject3D:
		return
	for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = m.mesh.create_trimesh_shape()
		body.add_child(cs)
		m.add_child(body)
