class_name MaterialDrop
extends Node3D
## Crafting materials left by a monster: a small pouch with a soft glow. Walk over it to collect.

var world: Node
var items: Dictionary = {}       # material -> count
var _t := randf() * 10.0
var _visual: Node3D


func _ready() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var col: Color = Crafting.MATERIALS[items.keys()[0]][1] if not items.is_empty() else Color.WHITE
	MeshKit.sphere(_visual, 0.12, Vector3(0, 0.1, 0), MeshKit.mat(Color(0.5, 0.36, 0.22), 0.9), Vector3(1, 0.8, 1))
	MeshKit.cyl(_visual, 0.04, 0.07, 0.06, Vector3(0, 0.21, 0), MeshKit.mat(Color(0.45, 0.32, 0.2), 0.9), Vector3.ZERO, 8)
	MeshKit.sphere(_visual, 0.045, Vector3(0.06, 0.2, 0.06), MeshKit.mat(col, 0.4, 0.0, 1.5))
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 0.7
	l.omni_range = 1.8
	l.position.y = 0.4
	add_child(l)
	var start := position
	position += Vector3(0, 0.7, 0)
	create_tween().tween_property(self, "position", start, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var life := create_tween()
	life.tween_interval(240.0)
	life.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta
	_visual.position.y = sin(_t * 2.5) * 0.03
	if world and world.player and not world.player.dead and world.player.global_position.distance_to(global_position) < 1.6:
		collect(world, items)
		queue_free()


## Adds materials to the pouch and shows what was found.
static func collect(w: Node, found: Dictionary) -> void:
	var parts := []
	for k in found:
		if int(found[k]) <= 0:
			continue
		Crafting.add(k, int(found[k]))
		parts.append("+%d %s" % [int(found[k]), Crafting.mat_name(k)])
	if parts.is_empty():
		return
	Game.play_sound("pickup_item", null, -6.0, 1.2)
	w.hud.show_message(", ".join(parts), Color(0.8, 0.95, 0.7), 2.0)
	if w.has_method("on_materials_found"):
		w.on_materials_found(found)


static func spawn(w: Node, pos: Vector3, found: Dictionary) -> void:
	if found.is_empty():
		return
	var d := MaterialDrop.new()
	d.world = w
	d.items = found
	d.position = Vector3(pos.x, w.ground(pos.x, pos.z) + 0.05, pos.z)
	w.add_child(d)
