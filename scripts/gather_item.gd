class_name GatherItem
extends Area3D
## Glowing quest item on the ground (gathered objects and enemy drops). Walk over it to pick it up.

var world: Node
var quest_id := ""
var item := ""
var _t := randf() * 10.0
var _visual: Node3D
var _still := false


func _ready() -> void:
	add_to_group("gather_items")
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.1
	cs.shape = sh
	cs.position.y = 0.5
	add_child(cs)
	_visual = Node3D.new()
	_visual.position.y = 0.45
	add_child(_visual)
	var col := _build_visual(item.to_lower())
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 1.4
	light.omni_range = 3.5
	light.position.y = 0.8
	add_child(light)
	# light beam so items can be spotted from far away
	var beam := CylinderMesh.new()
	beam.top_radius = 0.04
	beam.bottom_radius = 0.25
	beam.height = 6.0
	beam.radial_segments = 8
	var bm := MeshKit.glow(Color(col, 0.18))
	MeshKit.inst(self, beam, Vector3(0, 3.0, 0), bm)
	var sparkle := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.03
	sm.height = 0.06
	sm.radial_segments = 4
	sm.rings = 2
	sm.material = MeshKit.unshaded(col.lightened(0.4))
	sparkle.mesh = sm
	sparkle.amount = 12
	sparkle.lifetime = 1.5
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkle.emission_sphere_radius = 0.5
	sparkle.gravity = Vector3(0, 0.5, 0)
	sparkle.position.y = 0.5
	add_child(sparkle)
	body_entered.connect(_on_body_entered)


func _build_visual(n: String) -> Color:
	var glow := Color(1.0, 0.85, 0.3)
	if n.contains("drone"):
		_build_drone()
		glow = Color(1.0, 0.55, 0.15)
	elif n.contains("battery"):
		var pack := Node3D.new()
		pack.rotation_degrees = Vector3(0, 0, 8)
		_visual.add_child(pack)
		MeshKit.box(pack, Vector3(0.22, 0.08, 0.075), Vector3.ZERO, MeshKit.mat(Color(0.12, 0.12, 0.13), 0.5))
		MeshKit.box(pack, Vector3(0.222, 0.03, 0.077), Vector3(0, 0.0, 0), MeshKit.mat(Color(0.95, 0.75, 0.1)))
		MeshKit.cyl(pack, 0.008, 0.008, 0.12, Vector3(0.15, 0.02, 0.012), MeshKit.mat(Color(0.8, 0.1, 0.1)), Vector3(0, 0, 90), 5)
		MeshKit.cyl(pack, 0.008, 0.008, 0.12, Vector3(0.15, 0.02, -0.012), MeshKit.mat(Color(0.05, 0.05, 0.05)), Vector3(0, 0, 90), 5)
		MeshKit.box(pack, Vector3(0.03, 0.025, 0.04), Vector3(0.22, 0.02, 0), MeshKit.mat(Color(0.95, 0.8, 0.2)))
		glow = Color(0.4, 1.0, 0.5)
	elif n.contains("candle"):
		MeshKit.cyl(_visual, 0.06, 0.07, 0.3, Vector3.ZERO, MeshKit.mat(Color(0.95, 0.92, 0.8)))
		MeshKit.sphere(_visual, 0.05, Vector3(0, 0.2, 0), MeshKit.unshaded(Color(1, 0.8, 0.3)), Vector3(1, 1.6, 1))
	elif n.contains("grain") or n.contains("flour") or n.contains("supplies"):
		MeshKit.sphere(_visual, 0.28, Vector3.ZERO, MeshKit.mat(Color(0.75, 0.62, 0.4)), Vector3(1, 1.2, 0.9))
		MeshKit.cyl(_visual, 0.06, 0.1, 0.12, Vector3(0, 0.33, 0), MeshKit.mat(Color(0.6, 0.48, 0.3)))
	elif n.contains("dust"):
		MeshKit.sphere(_visual, 0.25, Vector3(0, -0.2, 0), MeshKit.mat(Color(0.5, 0.45, 0.55), 1.0, 0.0, 0.6), Vector3(1, 0.4, 1))
		glow = Color(0.7, 0.5, 1.0)
	elif n.contains("bone"):
		MeshKit.cyl(_visual, 0.04, 0.04, 0.5, Vector3.ZERO, MeshKit.mat(Color(0.9, 0.88, 0.78)), Vector3(0, 0, 80), 6)
		glow = Color(0.5, 1.0, 0.5)
	elif n.contains("bandana"):
		MeshKit.box(_visual, Vector3(0.35, 0.05, 0.35), Vector3.ZERO, MeshKit.mat(Color(0.75, 0.08, 0.08)), Vector3(0, 30, 10))
		glow = Color(1.0, 0.4, 0.3)
	elif n.contains("gear"):
		MeshKit.cyl(_visual, 0.22, 0.22, 0.06, Vector3.ZERO, MeshKit.mat(Color(0.5, 0.45, 0.4), 0.4, 0.8), Vector3(90, 0, 0), 10)
	elif n.contains("wheat"):
		MeshKit.cyl(_visual, 0.12, 0.06, 0.7, Vector3(0, 0.1, 0), MeshKit.mat(Color(0.95, 0.8, 0.35)), Vector3.ZERO, 8)
	elif n.contains("fur"):
		MeshKit.sphere(_visual, 0.3, Vector3.ZERO, MeshKit.mat(Color(0.95, 0.95, 1.0)), Vector3(1.3, 0.5, 1))
		glow = Color(0.8, 0.9, 1.0)
	elif n.contains("lotus"):
		for i in 5:
			var a := TAU * i / 5.0
			MeshKit.sphere(_visual, 0.1, Vector3(cos(a) * 0.12, 0, sin(a) * 0.12), MeshKit.mat(Color(0.5, 0.75, 1.0), 0.5, 0.0, 1.5), Vector3(1, 0.4, 1.8))
		glow = Color(0.4, 0.7, 1.0)
	elif n.contains("crystal"):
		MeshKit.cyl(_visual, 0.0, 0.15, 0.5, Vector3(0, 0.1, 0), MeshKit.mat(Color(1.0, 0.35, 0.1), 0.2, 0.0, 2.5), Vector3.ZERO, 5)
		glow = Color(1.0, 0.4, 0.1)
	elif n.contains("horn"):
		MeshKit.cyl(_visual, 0.0, 0.08, 0.4, Vector3.ZERO, MeshKit.mat(Color(0.3, 0.15, 0.1)), Vector3(0, 0, 60), 6)
		glow = Color(1.0, 0.5, 0.2)
	elif n.contains("pearl"):
		MeshKit.sphere(_visual, 0.12, Vector3.ZERO, MeshKit.mat(Color(0.95, 0.95, 1.0), 0.15, 0.3))
		glow = Color(0.8, 0.95, 1.0)
	elif n.contains("doubloon") or n.contains("coin"):
		MeshKit.cyl(_visual, 0.14, 0.14, 0.03, Vector3.ZERO, MeshKit.mat(Color(1.0, 0.8, 0.25), 0.3, 0.9), Vector3(90, 0, 0), 14)
	else:
		MeshKit.sphere(_visual, 0.15, Vector3.ZERO, MeshKit.mat(glow, 0.3, 0.0, 1.5))
	return glow


## Small 5-inch FPV quad: carbon frame, four motors with orange props, camera and antenna.
## It sits tilted in the branches instead of spinning like the other items.
func _build_drone() -> void:
	_still = true
	var d := Node3D.new()
	d.rotation_degrees = Vector3(14, 30, -9)
	d.scale = Vector3.ONE * 1.4
	_visual.add_child(d)
	var carbon := MeshKit.mat(Color(0.07, 0.07, 0.08), 0.35, 0.2)
	var metal := MeshKit.mat(Color(0.55, 0.55, 0.6), 0.3, 0.9)
	var prop := MeshKit.mat(Color(1.0, 0.45, 0.08), 0.5)
	MeshKit.box(d, Vector3(0.09, 0.045, 0.16), Vector3(0, 0.02, 0), carbon)
	MeshKit.box(d, Vector3(0.06, 0.03, 0.1), Vector3(0, 0.055, -0.01), MeshKit.mat(Color(0.85, 0.15, 0.1), 0.6))
	for i in 4:
		var a := deg_to_rad(45.0 + 90.0 * i)
		var tip := Vector3(cos(a), 0, sin(a)) * 0.15
		MeshKit.box(d, Vector3(0.21, 0.012, 0.028), tip * 0.5, carbon, Vector3(0, -rad_to_deg(a), 0))
		MeshKit.cyl(d, 0.018, 0.018, 0.03, tip + Vector3(0, 0.02, 0), metal, Vector3.ZERO, 10)
		MeshKit.cyl(d, 0.065, 0.065, 0.004, tip + Vector3(0, 0.04, 0), prop, Vector3.ZERO, 14)
	MeshKit.box(d, Vector3(0.03, 0.03, 0.03), Vector3(0, 0.04, -0.09), MeshKit.mat(Color(0.15, 0.15, 0.17)), Vector3(-25, 0, 0))
	MeshKit.cyl(d, 0.009, 0.009, 0.006, Vector3(0, 0.045, -0.106), MeshKit.mat(Color(0.2, 0.4, 0.9), 0.1, 0.5), Vector3(65, 0, 0), 8)
	MeshKit.cyl(d, 0.004, 0.004, 0.09, Vector3(0, 0.06, 0.1), MeshKit.mat(Color(0.1, 0.1, 0.1)), Vector3(55, 0, 0), 4)


func _process(delta: float) -> void:
	_t += delta
	if _still:
		return
	_visual.rotation.y += delta * 1.2
	_visual.position.y = 0.45 + sin(_t * 2.5) * 0.08


func _on_body_entered(body: Node3D) -> void:
	var p := body as Player
	if p and not p.dead and world.quests.status(quest_id) == "active":
		Game.play_sound(pickup_sound(item), null, -3.0)
		world.quests.on_item_gathered(quest_id, self)
		queue_free()


## Pickup sound that fits the item: electronics click, coins jingle, glassy things clink...
static func pickup_sound(item_name: String) -> String:
	var n := item_name.to_lower()
	for k in ["drone", "battery", "gear", "radio"]:
		if n.contains(k):
			return "pickup_tech"
	for k in ["coin", "doubloon", "gold"]:
		if n.contains(k):
			return "pickup_coins"
	for k in ["crystal", "pearl", "potion", "vial", "lotus"]:
		if n.contains(k):
			return "pickup_glass"
	for k in ["bone", "horn", "skull"]:
		if n.contains(k):
			return "pickup_bone"
	return "pickup_item"