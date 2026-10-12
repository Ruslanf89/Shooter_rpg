class_name StashChest
extends StaticBody3D
## Personal storage chest in every trader's shop (shared between locations). Press F.

var world: Node


func _ready() -> void:
	add_to_group("interactables")
	set_meta("surface", "wood")
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.2, 0.8, 0.7)
	cs.shape = sh
	cs.position.y = 0.4
	add_child(cs)
	var wood := MeshKit.textured("Planks021", Color(0.45, 0.32, 0.5), 1.6, 0.35, 0.85)
	var iron := MeshKit.mat(Color(0.75, 0.6, 0.25), 0.35, 0.9)
	MeshKit.box(self, Vector3(1.2, 0.6, 0.7), Vector3(0, 0.3, 0), wood)
	MeshKit.box(self, Vector3(1.22, 0.18, 0.72), Vector3(0, 0.69, 0), wood)
	for x in [-0.45, 0.0, 0.45]:
		MeshKit.box(self, Vector3(0.06, 0.8, 0.74), Vector3(x, 0.4, 0), iron)
	MeshKit.box(self, Vector3(0.16, 0.18, 0.03), Vector3(0, 0.55, 0.37), iron)


func prompt() -> String:
	return Loc.t("Open stash")


func interact() -> void:
	Game.play_sound("chest", global_position, -4.0, 1.1)
	world.open_inventory("stash")
