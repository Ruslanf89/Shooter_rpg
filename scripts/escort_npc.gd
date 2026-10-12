class_name EscortNPC
extends Villager
## Someone to escort to the portal (travel quests). Follows the player, waits and calls out when
## left behind, monsters go for them (they can die), and the quest step completes when they reach
## the portal - or when you travel with them standing beside you.

var quest_id := ""
var _wait_call := 0.0
var _arrived := false


func _ready() -> void:
	mortal = true
	personality = "coward"
	hp = 260.0
	job = "Travelling with you"
	super()
	_stamina = 260.0 + world.zone_levels().y * 25.0


func _on_hour(_h: int, _instant := false) -> void:
	_activity = "escort"


func _physics_process(delta: float) -> void:
	if _dead or _arrived:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _talking:
		super(delta)
		return
	_activity = "escort"
	var p: Player = world.player
	var to := _flat(p.global_position - global_position)
	var d := to.length()
	# at the portal: done
	if world.portal and global_position.distance_to(world.portal.arrival_point()) < 5.0:
		_arrived = true
		world.journey.escort_arrived(quest_id)
		var tw := create_tween()
		tw.tween_property(self, "global_position", world.portal.global_position + Vector3(0, 0.3, 0), 1.5)
		tw.tween_callback(queue_free)
		return
	if d > 28.0:
		# too far ahead: wait and call
		velocity.x = 0.0
		velocity.z = 0.0
		_play("idle")
		_wait_call -= delta
		if _wait_call <= 0.0:
			_wait_call = 8.0
			world.hud.show_message(Loc.t("%s: Wait for me!") % vname, Color(1.0, 0.9, 0.6), 2.0)
			bark("scream", 6.0)
	elif d > 3.0:
		var spd := 4.6 if d > 8.0 else 2.2
		var dir := _steer(_nav_dir(p.global_position - to.normalized() * 2.5, delta), delta)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 7.0 * delta))
		_play("run" if spd > 3.0 else "walk", _gait(spd))
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_play("idle")
		_face_player(delta)
	move_and_slide()
	if is_on_wall() and is_on_floor():
		_step_up(_flat(velocity).normalized())


func _think() -> void:
	pass


## Escorts are always in danger: monsters may go for them.
func can_be_attacked() -> bool:
	return not _dead and not _arrived


func monster_damage(amount: float, _attacker: Node3D) -> void:
	if _dead or _arrived:
		return
	_stamina -= amount
	Fx.burst(world, global_position + Vector3(0, 1.2, 0), blood_color, 8, 2.0, 0.03, 0.4)
	if randf() < 0.3:
		bark("scream", 4.0)
	if _stamina <= 0.0:
		_die()
		world.journey.escort_failed(quest_id)


func take_damage(_amount: float, _pos: Vector3, _dir: Vector3, _kind := "bullet") -> bool:
	# the player can't hurt the person they're protecting
	return false


func prompt() -> String:
	return ""
