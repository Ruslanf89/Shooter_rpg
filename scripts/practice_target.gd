class_name PracticeTarget
extends StaticBody3D
## A straw-and-plank target on a post (Brannock's yard). One bullet knocks it flat and counts for
## the quest step that put it there.

var world: Node
var quest_id := ""
var index := 0
var _board: Node3D
var _down := false


func _ready() -> void:
	set_meta("surface", "wood")
	collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.9, 1.9, 0.25)
	cs.shape = sh
	cs.position.y = 0.95
	add_child(cs)
	var wood := Props.dark_wood()
	MeshKit.box(self, Vector3(0.12, 1.1, 0.12), Vector3(0, 0.55, 0), wood)
	MeshKit.box(self, Vector3(0.7, 0.08, 0.12), Vector3(0, 0.06, 0), wood)
	_board = Node3D.new()
	_board.position = Vector3(0, 1.05, 0)
	add_child(_board)
	# straw boss with a painted bullseye
	MeshKit.cyl(_board, 0.42, 0.42, 0.18, Vector3(0, 0.38, 0), MeshKit.mat(Color(0.78, 0.66, 0.38), 1.0), Vector3(90, 0, 0), 20)
	var rings := [[0.36, Color(0.92, 0.9, 0.82)], [0.27, Color(0.15, 0.15, 0.17)], [0.18, Color(0.92, 0.9, 0.82)], [0.09, Color(0.75, 0.12, 0.08)]]
	for i in rings.size():
		MeshKit.cyl(_board, rings[i][0], rings[i][0], 0.01, Vector3(0, 0.38, 0.092 + i * 0.002), MeshKit.mat(rings[i][1], 0.95), Vector3(90, 0, 0), 20)


## Turns the painted side towards `p` (on the ground plane).
func face(p: Vector3) -> void:
	if p == Vector3.ZERO:
		return
	var d := p - global_position
	d.y = 0.0
	if d.length() > 0.1:
		rotation.y = atan2(d.x, d.z)


## Called by bullets.
func bullet_hit(_amount: float) -> void:
	if _down:
		return
	_down = true
	Game.play_sound("impact_wood", global_position, -2.0)
	var tw := create_tween()
	tw.tween_property(_board, "rotation_degrees:x", -88.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if world and world.quests:
		world.quests.on_target_hit(quest_id, index)
