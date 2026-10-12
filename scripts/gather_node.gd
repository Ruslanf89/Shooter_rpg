class_name GatherNode
extends Node3D
## Something to harvest for crafting (press F): an ore vein, a herb bush, glowcap mushrooms,
## a fallen log, sulfur crystals or a clam on the beach. Grows back after a few minutes.

const REGROW := 360.0

var world: Node
var kind := "ore"
var _visual: Node3D
var _regrow := 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("gather_nodes")
	_visual = Node3D.new()
	add_child(_visual)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 31.0 + global_position.z * 17.0)
	_visual.rotation.y = rng.randf() * TAU
	match kind:
		"ore":
			var rock := Props.rock_mat(Color(0.9, 0.85, 0.8))
			MeshKit.sphere(_visual, 0.7, Vector3(0, 0.15, 0), rock, Vector3(1.2, 0.8, 1.0))
			MeshKit.sphere(_visual, 0.45, Vector3(0.5, 0.05, 0.3), rock, Vector3(1.0, 0.8, 1.1))
			var vein := MeshKit.mat(Color(0.85, 0.6, 0.45) if Game.level_index < 3 else Color(0.85, 0.88, 1.0), 0.25, 0.9, 0.3)
			for i in 7:
				var a := rng.randf() * TAU
				MeshKit.box(_visual, Vector3(0.12, 0.08, 0.05), Vector3(cos(a) * 0.6, 0.25 + rng.randf() * 0.35, sin(a) * 0.5), vein, Vector3(rng.randf() * 90, rng.randf() * 90, 0))
			MeshKit.collider_box(_visual, Vector3(1.4, 1.0, 1.2), Vector3(0, 0.3, 0))
		"herb":
			var leaf := MeshKit.mat(Color(0.25, 0.55, 0.2), 0.9)
			for i in 9:
				var a := TAU * i / 9.0
				MeshKit.sphere(_visual, 0.14, Vector3(cos(a) * 0.18, 0.18 + rng.randf() * 0.1, sin(a) * 0.18), leaf, Vector3(1.0, 0.5, 2.0))
			var flower := MeshKit.mat(Color(0.95, 0.4, 0.6) if Game.level_index != 3 else Color(0.75, 0.9, 1.0), 0.6, 0.0, 0.4)
			for i in 5:
				MeshKit.sphere(_visual, 0.045, Vector3(rng.randf_range(-0.2, 0.2), 0.36, rng.randf_range(-0.2, 0.2)), flower)
		"mushroom":
			var stem := MeshKit.mat(Color(0.85, 0.82, 0.72), 0.7)
			var cap := MeshKit.mat(Color(0.25, 0.65, 1.0), 0.5, 0.0, 1.0)
			for i in 6:
				var p := Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
				var s := rng.randf_range(0.6, 1.2)
				MeshKit.cyl(_visual, 0.02 * s, 0.03 * s, 0.14 * s, p + Vector3(0, 0.07 * s, 0), stem, Vector3.ZERO, 6)
				MeshKit.sphere(_visual, 0.07 * s, p + Vector3(0, 0.15 * s, 0), cap, Vector3(1, 0.5, 1))
			var l := OmniLight3D.new()
			l.light_color = Color(0.3, 0.7, 1.0)
			l.light_energy = 0.6
			l.omni_range = 2.0
			l.position.y = 0.3
			_visual.add_child(l)
		"wood":
			var bark := MeshKit.mat(Color(0.35, 0.25, 0.16), 0.95)
			MeshKit.cyl(_visual, 0.28, 0.32, 2.4, Vector3(0, 0.3, 0), bark, Vector3(0, 0, 90), 10)
			MeshKit.cyl(_visual, 0.27, 0.27, 0.02, Vector3(1.21, 0.3, 0), MeshKit.mat(Color(0.75, 0.6, 0.4)), Vector3(0, 0, 90), 10)
			MeshKit.box(_visual, Vector3(0.05, 0.25, 0.12), Vector3(0.3, 0.62, 0), MeshKit.mat(Color(0.5, 0.5, 0.55), 0.3, 0.8), Vector3(0, 0, -20))
			MeshKit.cyl(_visual, 0.02, 0.02, 0.5, Vector3(0.4, 0.8, 0), MeshKit.mat(Color(0.45, 0.3, 0.18)), Vector3(0, 0, -20), 6)
			MeshKit.collider_box(_visual, Vector3(2.4, 0.6, 0.6), Vector3(0, 0.3, 0))
		"sulfur":
			var rock := Props.rock_mat(Color(0.7, 0.65, 0.55))
			MeshKit.sphere(_visual, 0.5, Vector3(0, 0.05, 0), rock, Vector3(1.3, 0.6, 1.1))
			var crystal := MeshKit.mat(Color(1.0, 0.88, 0.2), 0.3, 0.0, 0.5)
			for i in 6:
				var prism := PrismMesh.new()
				prism.size = Vector3(0.12, 0.35, 0.12)
				MeshKit.inst(_visual, prism, Vector3(rng.randf_range(-0.35, 0.35), 0.35, rng.randf_range(-0.3, 0.3)), crystal, Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 25)))
		_:
			var shell := MeshKit.mat(Color(0.75, 0.7, 0.8), 0.4, 0.2)
			MeshKit.sphere(_visual, 0.22, Vector3(0, 0.06, 0), shell, Vector3(1.2, 0.35, 1.0))
			MeshKit.sphere(_visual, 0.21, Vector3(0, 0.13, -0.05), shell, Vector3(1.2, 0.3, 1.0))
			MeshKit.sphere(_visual, 0.04, Vector3(0, 0.1, 0.12), MeshKit.mat(Color(0.6, 0.5, 1.0), 0.2, 0.0, 1.2))
	MeshKit.merge_children(_visual)


func ready_to_harvest() -> bool:
	return _regrow <= 0.0


func prompt() -> String:
	if not ready_to_harvest():
		return ""
	return {"ore": Loc.t("Mine ore"), "herb": Loc.t("Pick herbs"), "mushroom": Loc.t("Pick glowcaps"), "wood": Loc.t("Chop timber"),
		"sulfur": Loc.t("Break sulfur"), "clam": Loc.t("Open clam")}.get(kind, Loc.t("Gather"))


func interact() -> void:
	if not ready_to_harvest():
		return
	var found := Crafting.node_yield(kind, Game.level_index)
	Game.play_sound({"ore": "impact_stone", "wood": "impact_wood", "sulfur": "impact_stone"}.get(kind, "pickup_item"), global_position, -4.0)
	Fx.burst(world, global_position + Vector3(0, 0.4, 0), Color(0.8, 0.75, 0.6), 10, 2.0, 0.03, 0.5)
	MaterialDrop.collect(world, found)
	_regrow = REGROW
	_visual.visible = false
	remove_from_group("interactables")


func _process(delta: float) -> void:
	if _regrow > 0.0:
		_regrow -= delta
		if _regrow <= 0.0:
			_visual.visible = true
			add_to_group("interactables")
