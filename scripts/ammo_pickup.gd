class_name AmmoPickup
extends Area3D
## Loot dropped by enemies: an ammo box (kind "ammo") or a mana potion (kind "mana").
## Walk over it to collect.

const MANA_AMOUNT := 40.0

var kind := "ammo"
var amount := 30
var _t := 0.0
var _visual: Node3D


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.0
	cs.shape = sh
	cs.position.y = 0.5
	add_child(cs)

	_visual = Node3D.new()
	_visual.position.y = 0.5
	add_child(_visual)
	var light := OmniLight3D.new()
	light.light_energy = 0.9
	light.omni_range = 2.5
	_visual.add_child(light)
	if kind == "mana":
		var glass := MeshKit.glow(Color(0.35, 0.6, 1.0, 0.55))
		MeshKit.sphere(_visual, 0.17, Vector3(0, 0, 0), glass)
		MeshKit.sphere(_visual, 0.13, Vector3(0, -0.02, 0), MeshKit.mat(Color(0.2, 0.45, 1.0), 0.2, 0.0, 2.0))
		MeshKit.cyl(_visual, 0.05, 0.06, 0.14, Vector3(0, 0.2, 0), glass, Vector3.ZERO, 8)
		MeshKit.cyl(_visual, 0.055, 0.05, 0.06, Vector3(0, 0.3, 0), MeshKit.mat(Color(0.55, 0.38, 0.2)), Vector3.ZERO, 8)
		light.light_color = Color(0.35, 0.6, 1.0)
	else:
		MeshKit.box(_visual, Vector3(0.55, 0.3, 0.32), Vector3.ZERO, MeshKit.mat(Color(0.28, 0.34, 0.18)))
		MeshKit.box(_visual, Vector3(0.56, 0.06, 0.33), Vector3(0, 0.05, 0), MeshKit.mat(Color(0.95, 0.75, 0.2)))
		var brass := MeshKit.mat(Color(0.85, 0.65, 0.25), 0.35, 0.7)
		for i in 4:
			MeshKit.cyl(_visual, 0.025, 0.025, 0.14, Vector3(-0.15 + i * 0.1, 0.22, 0), brass, Vector3.ZERO, 8)
		light.light_color = Color(1.0, 0.85, 0.4)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * 1.6
	_visual.position.y = 0.55 + sin(_t * 3.0) * 0.1


func _on_body_entered(body: Node3D) -> void:
	var p := body as Player
	if p and not p.dead:
		if kind == "mana":
			p.add_mana(MANA_AMOUNT)
		else:
			p.add_ammo(amount)
		queue_free()
