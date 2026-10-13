class_name Kid
extends Villager
## Village child: plays tag with the other kids, kicks a ball around the square, chases chickens
## and now and then tags along behind the player asking about the gun and the world "up there".
## Can't be hurt (layer 32: bullets, spells and monsters ignore them). Runs home to hide from
## monsters and goes to bed at dusk (home at 20, asleep 21-7). Walks on the village navmesh.

const STROLL := 1.1
const RUN := 2.9

var village_center := Vector3.ZERO
var playmates: Array = []          # the other kids of the village
var ball: KidBall

static var _tag_it := {}           # village key -> the kid who is "it"
static var _ball_owner := {}       # village key -> the kid going for the ball
static var _follower := {}         # village key -> the kid following the player
static var _bark_t := {}           # village key -> time of the last kid bark (msec)

var _mode := ""
var _mode_t := 0.0
var _goal_pt := Vector3.ZERO       # current target (re-chosen now and then, not every frame)
var _goal_t := 0.0
var _resting := true               # arrived: stay put until the target moves away
var _tag_cd := 0.0
var _chatter_t := 6.0
var _follow_cd := 30.0             # seconds until this kid may follow the player again
var _chicken: Animal
var _prog_pos := Vector3.ZERO
var _prog_t := 0.0
var _want := Vector3.ZERO


func _speaker() -> String:
	return "kid"


func _setup_groups() -> void:
	add_to_group("kids")
	add_to_group("interactables")
	collision_layer = 32
	collision_mask = 1


func _size() -> float:
	return 0.62


func _after_model(built: Dictionary) -> void:
	var sk: Skeleton3D = built.get("skeleton")
	if sk:
		sk.add_child(KidProportions.new())


func _schedule(h: int) -> String:
	if h >= 21 or h < 7:
		return "sleep"
	if h >= 20:
		return "home"
	return "play"


func _on_hour(h: int, instant := false) -> void:
	if _activity == "play" and _schedule(h) != "play" and not instant:
		bark("kid_bedtime", 120.0)
	super(h, instant)


func _target_for(act: String) -> Vector3:
	if act == "play":
		return _near_square(5.0)
	return super(act)


func _arrive() -> void:
	super()
	if _activity == "play":
		_pick_mode()


func _near_square(r: float) -> Vector3:
	var a := randf() * TAU
	return village_center + Vector3(sin(a), 0, cos(a)) * randf_range(1.5, r)


func _key() -> int:
	return int(village_center.x * 7.0 + village_center.z)


## Kids chatter less: one bark per village every 10 s at most.
func bark(key: String, cooldown: float) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_bark_t.get(_key(), -100000)) < 10000:
		return
	if _bark_cd.get(key, 0.0) > 0.0 or _voice.playing:
		return
	_bark_t[_key()] = now
	super(key, cooldown)


# --------------------------------------------------------------------------- loop

func _physics_process(delta: float) -> void:
	if _activity != "play" or _talking:
		super(delta)
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	_think_t -= delta
	if _think_t <= 0.0:
		_think_t = 0.6
		_think()
	if _activity != "play":
		return
	_tag_cd -= delta
	_mode_t -= delta
	_goal_t -= delta
	_follow_cd -= delta
	for k in _bark_cd.keys():
		_bark_cd[k] -= delta
	if _mode_t <= 0.0:
		_pick_mode()
	# far from the player nobody sees them play
	if global_position.distance_squared_to(world.player.global_position) > 3600.0:
		return
	match _mode:
		"tag":
			_tag(delta)
		"ball":
			_ball(delta)
		"chickens":
			_chase_chickens(delta)
		"follow":
			_follow(delta)
		_:
			_stroll(delta)
	# not getting anywhere (cornered, stuck on a fence): do something else
	_prog_t += delta
	if _prog_t > 3.0:
		if not _resting and global_position.distance_to(_prog_pos) < 0.6:
			_mode = "stroll"
			_goal_pt = _near_square(9.0)
			_nav_t = 0.0
		_prog_pos = global_position
		_prog_t = 0.0


func _think() -> void:
	if _talking:
		return
	_threat = _nearest_threat(28.0)
	if _threat:
		_calm_t = 12.0
		if _activity != "hide" and _goal != "hide" and _activity != "sleep":
			_unlie()
			_stop_following()
			bark("kid_scared", 10.0)
			_start("hide")
		return
	if _activity == "hide" or _goal == "hide":
		_calm_t -= 0.6
		if _calm_t <= 0.0:
			_resume()


func _pick_mode() -> void:
	_stop_following()
	_mode_t = randf_range(20.0, 40.0)
	var p: Player = world.player
	var options := ["stroll", "stroll"]
	if playmates.size() > 0:
		options += ["tag", "tag"]
	if ball and is_instance_valid(ball):
		options += ["ball", "ball"]
	_chicken = _find_chicken()
	if _chicken:
		options.append("chickens")
	# following the player is rare: one kid at a time, then not again for a couple of minutes
	var f = _follower.get(_key())
	if _follow_cd <= 0.0 and (f == null or not is_instance_valid(f)) and world.wanted_stars == 0 \
			and p.global_position.distance_to(global_position) < 10.0 and randf() < 0.35:
		options = ["follow"]
	_mode = options[randi() % options.size()]
	if _mode in ["tag", "ball"]:
		# a group game: everyone joins
		for k in playmates:
			if is_instance_valid(k) and k._activity == "play" and k._mode != "follow":
				k._mode = _mode
				k._mode_t = _mode_t
				k._goal_t = 0.0
		if _mode == "tag":
			_tag_it[_key()] = self
		else:
			_ball_owner[_key()] = self
	if _mode == "follow":
		_follower[_key()] = self
		_mode_t = 15.0
		_follow_cd = 120.0
		_chatter_t = 3.0
	_goal_pt = _near_square(9.0)
	_goal_t = 0.0


func _stop_following() -> void:
	if _follower.get(_key()) == self:
		_follower.erase(_key())


func _find_chicken() -> Animal:
	var best: Animal = null
	var bd := 30.0
	for a in get_tree().get_nodes_in_group("animals"):
		if a.kind == "chicken" and not a._dead:
			var d := village_center.distance_to(a.global_position)
			if d < bd:
				bd = d
				best = a
	return best


## Moves towards a point on the navmesh. Stops within `near`, and only sets off again when the
## target is more than twice that far (no flicker between standing and running).
## Returns the remaining distance.
func _go(target: Vector3, spd: float, delta: float, near := 0.6) -> float:
	var d := _flat(target - global_position).length()
	if _resting and d > near * 2.0:
		_resting = false
	elif not _resting and d < near:
		_resting = true
	# the wanted velocity is smoothed on its own: bumping into things (move_and_slide) must not
	# make the kid spin or flicker
	if _resting:
		_want = _want.move_toward(Vector3.ZERO, 12.0 * delta)
		_play("idle")
	else:
		var dir := _steer(_nav_dir(target, delta), delta)
		_want = _want.lerp(dir * spd, minf(1.0, 6.0 * delta))
		if _want.length() > 0.3:
			rotation.y = lerp_angle(rotation.y, atan2(-_want.x, -_want.z), minf(1.0, 6.0 * delta))
		_play("run" if spd > 2.2 else "walk", _gait(_want.length()))
	velocity.x = _want.x
	velocity.z = _want.z
	move_and_slide()
	if is_on_wall() and is_on_floor():
		_step_up(_flat(velocity).normalized())
	return d


func _stroll(delta: float) -> void:
	_go(_goal_pt, STROLL, delta)
	if _resting and _goal_t <= 0.0:
		_goal_t = randf_range(2.0, 5.0)
		_goal_pt = _near_square(9.0)


func _tag(delta: float) -> void:
	var it: Kid = _tag_it.get(_key())
	if it == null or not is_instance_valid(it) or it._mode != "tag" or it._activity != "play":
		_tag_it[_key()] = self
		it = self
	if _tag_cd > 0.0:
		# just got tagged: count to three
		_go(global_position, 0.0, delta)
		return
	if it == self:
		var best: Kid = null
		var bd := 25.0
		for k in playmates:
			if is_instance_valid(k) and k._mode == "tag" and k._activity == "play" and k._tag_cd <= 0.0:
				var d := global_position.distance_to(k.global_position)
				if d < bd:
					bd = d
					best = k
		if best == null:
			_stroll(delta)
			return
		if _go(best.global_position, RUN, delta, 0.4) < 0.9:
			_tag_it[_key()] = best
			best._tag_cd = 3.0
			_goal_t = 0.0
			bark("kid_play", 8.0)
	else:
		var away := _flat(global_position - it.global_position)
		if away.length() < 6.0:
			# run off to a spot on the far side of the square, chosen once a second
			if _goal_t <= 0.0:
				_goal_t = 1.2
				var target := global_position + away.normalized() * 5.0
				if target.distance_to(village_center) > 12.0:
					target = village_center + (target - village_center).normalized() * 9.0 + away.normalized().cross(Vector3.UP) * 4.0
				_goal_pt = target
			_go(_goal_pt, RUN * 0.92, delta)
		else:
			_stroll(delta)


func _ball(delta: float) -> void:
	if ball == null or not is_instance_valid(ball):
		_mode = "stroll"
		return
	var bp := ball.global_position
	var owner_kid = _ball_owner.get(_key())
	if owner_kid == null or not is_instance_valid(owner_kid) or owner_kid._mode != "ball" or owner_kid._activity != "play":
		_ball_owner[_key()] = self
		owner_kid = self
	if owner_kid == self:
		if _go(bp, RUN * 0.85, delta, 0.5) < 0.7 and ball.linear_velocity.length() < 2.0:
			# pass to a playmate, who goes for it next
			var mate: Kid = null
			for k in playmates:
				if is_instance_valid(k) and k._mode == "ball" and k._activity == "play":
					mate = k
					if randf() < 0.5:
						break
			var to := mate.global_position if mate else _near_square(8.0)
			ball.kick(global_position, to, randf_range(2.5, 4.0))
			_ball_owner[_key()] = mate if mate else self
			_goal_t = 0.0
			if randf() < 0.25:
				bark("kid_play", 10.0)
	else:
		# wait for the pass a few metres away, facing the ball
		if _goal_t <= 0.0:
			_goal_t = randf_range(3.0, 5.0)
			_goal_pt = bp + _flat(global_position - bp).normalized() * randf_range(4.0, 6.0)
		_go(_goal_pt, STROLL * 1.5, delta)
		if _resting:
			_face_point(bp, delta)


func _chase_chickens(delta: float) -> void:
	if _chicken == null or not is_instance_valid(_chicken) or _chicken._dead:
		_chicken = _find_chicken()
		if _chicken == null:
			_mode = "stroll"
			return
	if _goal_t <= 0.0:
		_goal_t = 0.6
		_goal_pt = _chicken.global_position
	if _go(_goal_pt, RUN * 0.8, delta, 1.2) < 2.5:
		_chicken.scare(global_position)


func _follow(delta: float) -> void:
	var p: Player = world.player
	if world.wanted_stars > 0 or p.global_position.distance_to(village_center) > 30.0:
		_pick_mode()
		return
	var to := _flat(p.global_position - global_position)
	if _goal_t <= 0.0 or _goal_pt.distance_to(p.global_position) > 3.5:
		_goal_t = 0.8
		_goal_pt = p.global_position - to.normalized() * 2.5
	_go(_goal_pt, RUN * 0.85 if to.length() > 7.0 else STROLL * 1.3, delta, 1.0)
	if _resting:
		_face_player(delta)
	_chatter_t -= delta
	if _chatter_t <= 0.0:
		_chatter_t = randf_range(14.0, 22.0)
		if to.length() < 6.0:
			bark(["kid_follow", "kid_gun", "kid_world"][randi() % 3], 6.0)


# --------------------------------------------------------------------------- talking

func prompt() -> String:
	return Loc.t("Talk to") + " " + vname


func interact() -> void:
	_talking = true
	if Brain.active():
		_ai_talk()
		return
	var key: String = ["kid_gun", "kid_world", "kid_play", "kid_follow"][randi() % 4]
	if _activity == "sleep":
		key = "kid_bedtime"
	elif _activity == "hide" or _threat:
		key = "kid_scared"
	_say(key, false)


## Kids can't be hurt.
func take_damage(_amount: float, _pos: Vector3, _dir: Vector3, _kind := "bullet") -> bool:
	return false


func monster_damage(_amount: float, _attacker: Node3D) -> void:
	pass


func can_be_attacked() -> bool:
	return false
