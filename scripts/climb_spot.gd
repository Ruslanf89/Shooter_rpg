class_name ClimbSpot
extends Node3D
## Interactable on a climbable tree. The one at the trunk base starts climbing up, the one on the
## branch platform starts climbing down. Positioned at the trunk centre (base) / on the platform.

var world: Node
var tree_base: Vector3          # trunk centre on the ground (world space)
var top_height := 10.0          # platform height above tree_base
var top_pos: Vector3            # where the player stands on the platform (world space)
var radius_bottom := 0.95       # trunk radius at the ground / at the platform
var radius_top := 0.6
var face_angle := 0.0           # side of the trunk with the rungs
var down := false               # true for the spot on the platform


func _ready() -> void:
	add_to_group("interactables")


func prompt() -> String:
	return Loc.t("Climb down") if down else Loc.t("Climb the tree")


func interact() -> void:
	world.player.start_climb(self, down)


## Trunk radius at height h above the base.
func radius_at(h: float) -> float:
	return lerpf(radius_bottom, radius_top, clampf(h / top_height, 0.0, 1.0))
