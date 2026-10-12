class_name Spell
extends Area3D
## Magic projectile cast by ranged enemies (fire bolt or shadow bolt). Can be dodged.

const SPEED := 15.0

var kind := "fire"
var damage := 10.0
var direction := Vector3.FORWARD
var color := Color(1.0, 0.45, 0.1)
var _life := 4.0
var _done := false
var from_guard := false       # guard crossbow bolts only hit monsters
var player_mult := 1.0        # level-gap multiplier against the player (Enemy.gap_mult)


func _ready() -> void:
	match kind:
		"fire": color = Color(1.0, 0.45, 0.1)
		"necro": color = Color(0.35, 1.0, 0.35)
		"nature": color = Color(0.8, 1.0, 0.25)
		"web": color = Color(0.92, 0.92, 0.88)
		"ice": color = Color(0.6, 0.85, 1.0)
		"water": color = Color(0.3, 0.9, 0.85)
		_: color = Color(0.65, 0.25, 1.0)
	collision_layer = 0
	collision_mask = 1 | 2 | 4 | 16
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.3
	cs.shape = sh
	add_child(cs)

	MeshKit.sphere(self, 0.16, Vector3.ZERO, MeshKit.unshaded(color.lerp(Color.WHITE, 0.6)))
	MeshKit.sphere(self, 0.32, Vector3.ZERO, MeshKit.glow(Color(color, 0.55)))
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 5.0
	add_child(light)

	var trail := CPUParticles3D.new()
	var tm := SphereMesh.new()
	tm.radius = 0.1
	tm.height = 0.2
	tm.radial_segments = 6
	tm.rings = 3
	tm.material = MeshKit.glow(Color(color, 0.7))
	trail.mesh = tm
	trail.amount = 40
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.gravity = Vector3.ZERO
	trail.spread = 180.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.scale_amount_min = 0.4
	trail.scale_amount_max = 1.0
	add_child(trail)
	trail.emitting = true

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _done:
		return
	var e := body as Enemy
	if from_guard:
		if body is Player or (e and e.neutral) or body.has_method("monster_damage"):
			return
		if e:
			_done = true
			e.npc_damage(damage, null)
			Fx.burst(get_parent(), global_position, color, 10, 3.0, 0.04, 0.3, 2.0)
			queue_free()
			return
	elif e and not e.neutral:
		return    # monster spells fly through other monsters
	elif (e and e.neutral) or body.has_method("monster_damage"):
		_done = true
		if e:
			e.npc_damage(damage, null)
		else:
			body.monster_damage(damage, null)
		Fx.burst(get_parent(), global_position, color, 14, 3.5, 0.05, 0.4, 2.0)
		queue_free()
		return
	_done = true
	var p := body as Player
	var parent := get_parent()
	if kind == "fire":
		# fire bolts explode: the blast does the damage
		Explosion.spawn(parent, global_position, 2.5, damage * player_mult, "enemy")
		queue_free()
		return
	if p:
		p.take_damage(damage * player_mult, global_position - direction * 3.0)
		if kind == "web":
			p.slow_t = 2.5
			parent.hud.show_message(Loc.t("Webbed! You are slowed"), Color(0.9, 0.9, 0.85), 1.2)
		elif kind == "ice":
			p.slow_t = 1.5
			parent.hud.show_message(Loc.t("Chilled! You are slowed"), Color(0.6, 0.85, 1.0), 1.0)
	Fx.burst(parent, global_position, color, 18, 4.0, 0.06, 0.45, 2.0)
	Fx.light_flash(parent, global_position, color, 3.0, 6.0, 0.35)
	Game.play_sound("spell_hit", global_position, -3.0)
	queue_free()
