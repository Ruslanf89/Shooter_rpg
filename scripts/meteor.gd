class_name Meteor
extends Node3D
## Ground-targeted strike: a glowing warning circle, then a flaming rock falls and explodes.
## Used by the player's Meteor skill and by boss attacks.

var world: Node
var radius := 7.0
var damage := 220.0
var source := "player"
var delay := 1.0
var _t := 0.0
var _rock: Node3D
var _circle: MeshInstance3D
var _fell := false


## Spawns a strike at `pos` (snapped to the ground).
static func strike(w: Node, pos: Vector3, r: float, dmg: float, src: String, warn_time: float) -> Meteor:
	var m := Meteor.new()
	m.world = w
	m.radius = r
	m.damage = dmg
	m.source = src
	m.delay = warn_time
	w.add_child(m)
	m.global_position = Vector3(pos.x, w.ground(pos.x, pos.z), pos.z)
	return m


func _ready() -> void:
	var col := Color(1.0, 0.25, 0.1) if source != "player" else Color(1.0, 0.6, 0.2)
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.05
	disc.radial_segments = 40
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, 0.25)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = false
	_circle = MeshKit.inst(self, disc, Vector3(0, 0.15, 0), m)
	var edge := TorusMesh.new()
	edge.inner_radius = radius - 0.25
	edge.outer_radius = radius
	edge.rings = 48
	edge.ring_segments = 4
	MeshKit.inst(self, edge, Vector3(0, 0.15, 0), MeshKit.unshaded(col), Vector3.ZERO, Vector3(1, 0.1, 1))
	var tw := create_tween().set_loops()
	tw.tween_property(m, "albedo_color:a", 0.45, 0.25)
	tw.tween_property(m, "albedo_color:a", 0.15, 0.25)

	_rock = Node3D.new()
	add_child(_rock)
	_rock.position = Vector3(-8, 40, 6)
	MeshKit.sphere(_rock, 0.9, Vector3.ZERO, MeshKit.mat(Color(0.25, 0.15, 0.1)))
	MeshKit.sphere(_rock, 1.6, Vector3.ZERO, MeshKit.glow(Color(1.0, 0.45, 0.1, 0.6)))
	var trail := CPUParticles3D.new()
	var tm := SphereMesh.new()
	tm.radius = 0.5
	tm.height = 1.0
	tm.radial_segments = 6
	tm.rings = 3
	tm.material = MeshKit.glow(Color(1.0, 0.5, 0.15, 0.6))
	trail.mesh = tm
	trail.amount = 60
	trail.lifetime = 0.6
	trail.local_coords = false
	trail.spread = 30.0
	trail.gravity = Vector3(0, 3, 0)
	trail.scale_amount_min = 0.5
	trail.scale_amount_max = 1.5
	_rock.add_child(trail)
	trail.emitting = true
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.2)
	l.light_energy = 4.0
	l.omni_range = 14.0
	_rock.add_child(l)
	_rock.visible = false


func _process(delta: float) -> void:
	_t += delta
	var fall_time := 0.45
	if _t >= delay - fall_time and not _fell:
		_rock.visible = true
		var k := clampf((_t - (delay - fall_time)) / fall_time, 0.0, 1.0)
		_rock.position = Vector3(-8, 40, 6).lerp(Vector3.ZERO, k * k)
		if k >= 1.0:
			_fell = true
			_rock.queue_free()
			_circle.get_parent().visible = true
			Explosion.spawn(world, global_position + Vector3(0, 0.3, 0), radius, damage, source)
			queue_free()
