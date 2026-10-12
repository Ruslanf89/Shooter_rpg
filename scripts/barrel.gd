class_name ExplosiveBarrel
extends StaticBody3D
## Red powder barrel. Shoot it (or hit it with fire/explosions) and it blows up.

var world: Node
var hp := 20.0
var _exploded := false


func _ready() -> void:
	add_to_group("barrels")
	set_meta("surface", "wood")
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.45
	sh.height = 1.1
	cs.shape = sh
	cs.position.y = 0.55
	add_child(cs)
	var red := MeshKit.mat(Color(0.62, 0.1, 0.07), 0.5)
	var band := MeshKit.mat(Color(0.25, 0.25, 0.27), 0.4, 0.7)
	MeshKit.cyl(self, 0.45, 0.45, 1.1, Vector3(0, 0.55, 0), red, Vector3.ZERO, 14)
	for y in [0.15, 0.55, 0.95]:
		MeshKit.cyl(self, 0.47, 0.47, 0.06, Vector3(0, y, 0), band, Vector3.ZERO, 14)
	MeshKit.box(self, Vector3(0.5, 0.3, 0.02), Vector3(0, 0.6, 0.455), MeshKit.mat(Color(0.95, 0.85, 0.2)))
	MeshKit.sphere(self, 0.07, Vector3(0, 0.6, 0.47), MeshKit.mat(Color(0.1, 0.1, 0.1)))


## Called by bullets.
func bullet_hit(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		ignite()


func ignite() -> void:
	if _exploded:
		return
	_exploded = true
	remove_from_group("barrels")
	var pos := global_position + Vector3(0, 0.6, 0)
	queue_free()
	Explosion.spawn(world, pos, 6.0, 130.0, "barrel")
