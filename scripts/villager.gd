class_name Villager
extends CharacterBody3D
## Villager with a daily routine, a personality and reactions:
##   routine: 22-6 sleep in bed, 6-7 home, 7-12 work, 12-13 lunch at home, 13-18 work,
##            18-20 chat on the square, 20-22 home.
##   monsters near: brave villagers grab a weapon and fight (they can be knocked out and get up
##            later); cowards and the superstitious run home and hide; the rest run to the guards.
##   the player: reacts to a gun pointed at them, shots in the village, being wanted.
## F opens a topic menu (town, rumours, about them, your weapon / world, help). They can be hurt by
## the player: they flee and scream, and the guards come after you (world.report_crime).

var world: Node
var vname := "Villager"
var job := "Villager"
var gender := "m"
var personality := "kind"
var mortal := false              # monsters kill instead of knocking out (event merchant)
var model_file := "people/casual"
var colors: Dictionary = {}
var home: Dictionary = {}          # {"door", "out", "in", "bed", "bed_yaw", "table"} (world space)
var work: Dictionary = {}          # {"pos", "yaw", "anim"} work spot
var social: Vector3 = Vector3.ZERO # spot on the village square
var hp := 60.0
var voice_pitch := 1.0
var blood_color := Color(0.6, 0.04, 0.04)

var anim: AnimationPlayer
var _visual: Node3D
var _label: Label3D
var _voice: AudioStreamPlayer3D
var _anims := {}
var _path: Array = []            # points still to walk to
var _activity := ""              # current activity (walk, work, home, sleep, social, flee, fight, hide, guards, knocked)
var _goal := ""                  # activity to start when the path is done
var _inside := true
var _flee_t := 0.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _door_close: HouseDoor
var _door_t := 0.0
var _dead := false
var _talking := false
var _anim_now := ""
var _repath_t := 0.0
var _steer_dir := Vector3.FORWARD
var _steer_t := 0.0
var _best_d := INF
var _nav_pts := PackedVector3Array()
var _nav_i := 0
var _nav_goal := Vector3.INF
var _nav_t := 0.0
var _np_t := 0.0
var _think_t := randf()
var _threat: Enemy
var _calm_t := 0.0
var _fought := false
var _stamina := 100.0
var _knock_t := 0.0
var _attack_cd := 0.0
var _weapon: Node3D
var _bark_cd := {}
var _met := false
var _gift_given := false
var _last_shots := 0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _speaker() -> String:
	return gender


func _ready() -> void:
	add_to_group("villagers")
	_setup_groups()
	floor_max_angle = deg_to_rad(50.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.75 * _size()
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	var built := People.build(_visual, model_file, colors, (1.58 if gender == "f" else 1.64) * _size())
	anim = built.get("anim")
	_after_model(built)
	_anims = {
		"idle": People.find_anim(anim, ["Idle", "Man_Idle", "Female_Idle"]),
		"walk": People.find_anim(anim, ["Walk", "Man_Walk", "Female_Walk"]),
		"run": People.find_anim(anim, ["Run", "Man_Run", "Female_Run"]),
		"work": People.find_anim(anim, ["Work_Kneel", "Interact", "Man_Punch", "Female_Punch"]),
		"hammer": People.find_anim(anim, ["Punch_Right", "Man_Punch", "Female_Punch"]),
		"attack": People.find_anim(anim, ["Sword_Slash", "Man_SwordSlash", "Female_SwordSlash", "Punch_Right"]),
		"shoot": People.find_anim(anim, ["Gun_Shoot", "Idle_Gun_Shoot", "Man_Punch", "Female_Punch"]),
		"sit": People.find_anim(anim, ["Man_Sitting", "Female_Sitting", "Idle_Neutral"]),
		"talk": People.find_anim(anim, ["Wave", "Man_Clapping", "Female_Clapping"]),
		"death": People.find_anim(anim, ["Death", "Man_Death", "Female_Death"]),
	}
	for k in ["idle", "walk", "run", "work", "hammer", "sit"]:
		if _anims[k] != "":
			anim.get_animation(_anims[k]).loop_mode = Animation.LOOP_LINEAR
	_label = Label3D.new()
	_label.text = "%s\n<%s>" % [vname, Loc.t(job)]
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0007
	_label.font_size = 36
	_label.outline_size = 8
	_label.modulate = Color(0.9, 0.9, 0.85)
	_label.position.y = 2.15 * _size()
	_label.visibility_range_end = 18.0
	add_child(_label)
	_voice = AudioStreamPlayer3D.new()
	_voice.bus = "SFX"
	_voice.unit_size = 6.0
	_voice.max_distance = 30.0
	_voice.position.y = 1.6 * _size()
	add_child(_voice)
	_last_pos = global_position
	_stamina = 70.0 + world.zone_levels().y * 12.0
	if mortal:
		_stamina = hp
		add_to_group("allies")
	world.day_night.hour_changed.connect(_on_hour)
	_on_hour.call_deferred(int(world.day_night.hour), true)


func _setup_groups() -> void:
	add_to_group("damageable")
	add_to_group("interactables")
	collision_layer = 16
	collision_mask = 1


func _size() -> float:
	return 1.0


func _after_model(_built: Dictionary) -> void:
	pass


# --------------------------------------------------------------------------- schedule

func _schedule(h: int) -> String:
	if h >= 22 or h < 6:
		return "sleep"
	if h < 7 or (h >= 12 and h < 13) or h >= 20:
		return "home"
	if h >= 18:
		return "social"
	return "work"


func _busy_with_danger() -> bool:
	return _activity in ["flee", "fight", "hide", "guards", "knocked"]


func _on_hour(h: int, instant := false) -> void:
	if _dead or _busy_with_danger():
		return
	var want := _schedule(h)
	if want == _activity or want == _goal:
		return
	_start(want, instant)


func _target_for(act: String) -> Vector3:
	match act:
		"sleep":
			return home["bed"] + Vector3(0.9, 0, 0).rotated(Vector3.UP, float(home.get("bed_yaw", 0.0)))
		"home", "hide":
			return home["table"] + Vector3(0.9, 0, 0.0)
		"work":
			return work["pos"]
	return social + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))


func _start(act: String, instant := false) -> void:
	_goal = act
	_unlie()
	var target := _target_for(act)
	var inside_target := act in ["sleep", "home", "hide"]
	if instant:
		global_position = target
		_inside = inside_target
		_path.clear()
		_arrive()
		return
	_path.clear()
	if _inside and not inside_target:
		_path.append(home["in"])
		_path.append(home["out"])
	elif not _inside and inside_target:
		_path.append(home["out"])
		_path.append(home["in"])
	_path.append(target)
	_activity = "walk"


func _arrive() -> void:
	_activity = _goal
	velocity = Vector3.ZERO
	match _activity:
		"sleep":
			_play("idle")
			_lie_down()
		"home", "hide":
			_play("sit" if randf() < 0.5 and _activity == "home" else "idle")
			if _activity == "hide" and is_instance_valid(home.get("door")) and home["door"].is_open:
				home["door"].npc_close()
		"work":
			rotation.y = float(work.get("yaw", rotation.y))
			_play(str(work.get("anim", "work")))
		_:
			_play("idle")


func _lie_down() -> void:
	rotation.y = float(home.get("bed_yaw", 0.0))
	global_position = home["bed"] + Vector3(0, 0.45, 0)
	_visual.rotation.x = -PI * 0.5
	_visual.position = Vector3(0, 0.2, 0.75)
	if anim:
		anim.pause()


func _unlie() -> void:
	if _visual.rotation.x != 0.0 and _activity == "sleep":
		_visual.rotation.x = 0.0
		_visual.position = Vector3.ZERO
		global_position = home["bed"] + Vector3(0.9, 0.1, 0).rotated(Vector3.UP, float(home.get("bed_yaw", 0.0)))
		if anim:
			anim.play()


func _play(key: String, speed := 1.0) -> void:
	var a: String = _anims.get(key, "")
	if a == "" or anim == null:
		return
	if a == _anim_now and anim.is_playing():
		anim.speed_scale = lerpf(anim.speed_scale, speed, 0.2)
		return
	_anim_now = a
	anim.speed_scale = speed
	anim.play(a, 0.3)


# --------------------------------------------------------------------------- main loop

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor() and _activity not in ["sleep", "knocked"]:
		velocity.y -= gravity * delta
	if _door_close and is_instance_valid(_door_close):
		_door_t -= delta
		if _door_t <= 0.0:
			_door_close.npc_close()
			_door_close = null
	_attack_cd -= delta
	for k in _bark_cd.keys():
		_bark_cd[k] -= delta
	_think_t -= delta
	if _think_t <= 0.0:
		_think_t = 0.6
		_think()
	match _activity:
		"knocked":
			_knock_t -= delta
			if _knock_t <= 0.0:
				_get_up()
			return
		"fight":
			_fight(delta)
			return
		"flee":
			_flee_t -= delta
			_flee(delta)
			if _flee_t <= 0.0:
				_resume()
			return
	if _talking:
		_face_player(delta)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if _activity == "walk":
		# nobody sees villagers far away walk: put them where they were going
		if global_position.distance_squared_to(world.player.global_position) > 6400.0 and not _path.is_empty():
			for pt in _path:
				_reached_point(pt)
			global_position = _path[-1]
			_path.clear()
			_arrive()
			return
		_walk(delta, 3.6 if _goal in ["hide", "guards", "fight"] else 1.7)
	elif _activity == "sleep":
		velocity = Vector3.ZERO
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if _activity in ["social", "guards"]:
			_face_player(delta, 6.0)


## A few times a second: look for monsters and watch what the player does.
func _think() -> void:
	if _talking or _activity == "knocked":
		return
	var p: Player = world.player
	var pd := global_position.distance_to(p.global_position)
	if pd > 90.0:
		return
	_threat = _nearest_threat(34.0 if personality == "brave" else 24.0)
	if _threat:
		_calm_t = 10.0
		if not _busy_with_danger() and not (_activity == "walk" and _goal in ["hide", "guards", "fight"]):
			_react_to_threat()
		return
	if _busy_with_danger() and _activity != "flee":
		_calm_t -= 0.6
		if _calm_t <= 0.0:
			if _fought and pd < 16.0:
				bark("thanks", 60.0)
			_fought = false
			_drop_weapon()
			_resume()
		return
	_react_to_player(p, pd)


func _nearest_threat(r: float) -> Enemy:
	var best: Enemy = null
	var bd := r
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.neutral or e.state == Enemy.State.DEAD:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < bd and (e.state == Enemy.State.CHASE or d < 14.0):
			bd = d
			best = e
	return best


func _react_to_threat() -> void:
	_unlie()
	match personality:
		"brave":
			_start_fight()
		"coward", "superstitious":
			bark("scream", 15.0)
			_start("hide")
		_:
			bark("to_guards", 15.0)
			_goal = "guards"
			_path = [_guard_spot()]
			if _inside:
				_path = [home["in"], home["out"], _guard_spot()]
			_activity = "walk"


func _guard_spot() -> Vector3:
	var best := social
	var bd := INF
	for g in get_tree().get_nodes_in_group("allies"):
		# guards on the ground (not the archers up on the watchtowers)
		if g is Enemy and g.state != Enemy.State.DEAD and g.global_position.y < global_position.y + 2.5:
			var d := global_position.distance_to(g.global_position)
			if d < bd:
				bd = d
				best = g.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	return best


func _react_to_player(p: Player, pd: float) -> void:
	if pd > 16.0 or _activity == "sleep":
		return
	if world.wanted_stars >= 2 and pd < 7.0:
		bark("greet_wanted", 20.0)
		if personality in ["coward", "kind", "superstitious", "gossip"]:
			_flee_t = 5.0
			_activity = "flee"
		return
	# a gun pointed at them
	if p.aiming:
		var to := (global_position + Vector3(0, 1.2, 0)) - p.camera.global_position
		if to.length() < 15.0 and (-p.camera.global_transform.basis.z).dot(to.normalized()) > 0.97:
			bark("gun_aimed_" + personality, 25.0)
			if personality == "coward":
				_flee_t = 4.0
				_activity = "flee"
			return
	# shots fired close by with no monsters around
	if world.shots_fired > _last_shots and pd < 14.0:
		bark("shots", 35.0)
	_last_shots = world.shots_fired
	if pd < 5.5:
		_ai_greet()


func _resume() -> void:
	_activity = ""
	_goal = ""
	_on_hour(int(world.day_night.hour))


func _walk(delta: float, spd := 1.7) -> void:
	if _path.is_empty():
		_arrive()
		return
	var target: Vector3 = _path[0]
	var to := target - global_position
	to.y = 0.0
	var reach := 0.45 if _path.size() > 1 else 0.6
	if to.length() < reach:
		_reached_point(target)
		_path.pop_front()
		_best_d = INF
		_nav_goal = Vector3.INF
		return
	# circling round something without getting closer: give up and pop over there
	if to.length() < _best_d - 0.3:
		_best_d = to.length()
		_np_t = 0.0
	else:
		_np_t += delta
		if _np_t > 6.0:
			global_position = target + Vector3(0, 0.1, 0)
			_np_t = 0.0
			return
	if _open_door_near():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_play("idle")
		return
	var dir := _steer(_nav_dir(target, delta), delta)
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 7.0 * delta))
	_play("run" if spd > 3.0 else "walk", _gait(spd))
	move_and_slide()
	if is_on_wall() and is_on_floor():
		_step_up(dir)
	_stuck_t += delta
	if _stuck_t > 1.2:
		if global_position.distance_to(_last_pos) < 0.4:
			_nav_t = 0.0
			var side := dir.cross(Vector3.UP) * (1.0 if randf() < 0.5 else -1.0)
			global_position += side * 0.5 + Vector3(0, 0.1, 0)
			_repath_t += 1.0
			if _repath_t > 4.0:
				global_position = target
				_repath_t = 0.0
		else:
			_repath_t = 0.0
		_last_pos = global_position
		_stuck_t = 0.0


func _reached_point(p: Vector3) -> void:
	if home.is_empty():
		return
	if p.distance_to(home["in"]) < 0.5:
		_inside = true
	elif p.distance_to(home["out"]) < 0.5:
		_inside = false


## Direction to walk towards `target`: along the navigation mesh where there is one (villages and
## towns), straight otherwise. The route is planned again every 1.5 s or when the target moves.
func _nav_dir(target: Vector3, delta: float) -> Vector3:
	_nav_t -= delta
	if _nav_t <= 0.0 or (_nav_goal.distance_to(target) > 1.5 and _nav_t < 1.2):
		_nav_goal = target
		_nav_t = 1.5
		_nav_pts = NavBuilder.path(world, global_position, target)
		_nav_i = 1
	var goal := target
	if _nav_pts.size() > 1:
		while _nav_i < _nav_pts.size() - 1 and _flat(_nav_pts[_nav_i] - global_position).length() < 0.5:
			_nav_i += 1
		goal = _nav_pts[mini(_nav_i, _nav_pts.size() - 1)]
	var to := _flat(goal - global_position)
	if to.length() < 0.05:
		to = _flat(target - global_position)
	return to.normalized() if to.length() > 0.01 else -global_transform.basis.z


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Walk / run animation speed matching the real speed (so feet don't slide; kids are smaller).
func _gait(spd: float) -> float:
	return clampf(spd / ((3.4 if spd > 2.2 else 1.5) * _size()), 0.6, 1.9)


func _steer(dir: Vector3, delta: float) -> Vector3:
	_steer_t -= delta
	if _steer_t > 0.0:
		return _steer_dir
	if not is_on_wall():
		return dir
	# blocked: take the first free direction in a fan around the wanted one, for a moment
	var from := global_transform.translated(Vector3(0, 0.2, 0))
	for a: float in [0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8, 2.5, -2.5]:
		var d := dir.rotated(Vector3.UP, a)
		if not test_move(from, d * 0.4):
			if a != 0.0:
				_steer_dir = d
				_steer_t = 0.35
			return d
	return dir


## Opens the home door when close; returns true while it is still swinging (wait for it).
func _open_door_near() -> bool:
	if home.is_empty() or not is_instance_valid(home.get("door")):
		return false
	var d: HouseDoor = home["door"]
	if d.global_position.distance_to(global_position) < 2.4:
		if not d.is_open:
			d.npc_open()
		_door_close = d
		_door_t = 4.0
		return d._busy or not d.is_open
	return false


func _step_up(dir: Vector3) -> void:
	var up := Vector3(0, 0.4, 0)
	if test_move(global_transform, up):
		return
	if test_move(global_transform.translated(up), dir * 0.3):
		return
	global_position += up + dir * 0.1


func _face_player(delta: float, max_dist := 100.0) -> void:
	_face_point(world.player.global_position, delta, max_dist)


func _face_point(pt: Vector3, delta: float, max_dist := 100.0) -> void:
	var to := pt - global_position
	to.y = 0.0
	if to.length() < max_dist and to.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 5.0 * delta))


func _flee(delta: float) -> void:
	var away: Vector3 = global_position - world.player.global_position
	if _threat and is_instance_valid(_threat):
		away = global_position - _threat.global_position
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3.FORWARD
	var dir := away.normalized()
	velocity.x = dir.x * 4.8
	velocity.z = dir.z * 4.8
	velocity.y -= gravity * delta
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	_play("run")
	move_and_slide()
	if is_on_wall():
		velocity = dir.rotated(Vector3.UP, 1.2) * 4.8


# --------------------------------------------------------------------------- fighting

func _start_fight() -> void:
	_goal = "fight"
	_fought = true
	_path.clear()
	add_to_group("allies")
	bark("fight_cry", 12.0)
	_take_weapon()
	if _inside and not home.is_empty():
		# out of the house first
		_path = [home["in"], home["out"]]
		_activity = "walk"
	else:
		_activity = "fight"


func _ranged() -> bool:
	return world.tech_level >= 2


## Pitchfork or axe at first; muskets and later rifles once they've learned from the player.
func _take_weapon() -> void:
	if _weapon:
		return
	_weapon = Node3D.new()
	_weapon.position = Vector3(0.3, 1.0 * _size(), -0.25)
	add_child(_weapon)
	var wood := MeshKit.mat(Color(0.45, 0.3, 0.18))
	var metal := MeshKit.mat(Color(0.45, 0.45, 0.48), 0.35, 0.85)
	if _ranged():
		_weapon.rotation_degrees = Vector3(0, 0, 0)
		MeshKit.box(_weapon, Vector3(0.05, 0.07, 0.75 if world.tech_level < 4 else 0.85), Vector3(0, 0, -0.2), wood)
		MeshKit.cyl(_weapon, 0.012, 0.012, 0.7, Vector3(0, 0.03, -0.5), metal, Vector3(90, 0, 0), 6)
	elif randf() < 0.5:
		_weapon.rotation_degrees = Vector3(-35, 0, 0)
		MeshKit.cyl(_weapon, 0.02, 0.02, 1.6, Vector3(0, 0.3, 0), wood, Vector3.ZERO, 6)
		for x in [-0.07, 0.0, 0.07]:
			MeshKit.cyl(_weapon, 0.006, 0.006, 0.28, Vector3(x, 1.2, 0), metal, Vector3.ZERO, 4)
	else:
		_weapon.rotation_degrees = Vector3(-35, 0, 0)
		MeshKit.cyl(_weapon, 0.02, 0.02, 0.9, Vector3(0, 0.1, 0), wood, Vector3.ZERO, 6)
		MeshKit.box(_weapon, Vector3(0.02, 0.16, 0.22), Vector3(0, 0.5, -0.08), metal)


func _drop_weapon() -> void:
	if not mortal:
		remove_from_group("allies")
	if _weapon:
		_weapon.queue_free()
		_weapon = null


func _fight(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _threat == null or not is_instance_valid(_threat) or _threat.state == Enemy.State.DEAD:
		_threat = _nearest_threat(30.0)
	if _threat == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_play("idle")
		return
	var to := _threat.global_position - global_position
	to.y = 0.0
	var d := to.length()
	var want := 12.0 if _ranged() else 1.8
	_face_point(_threat.global_position, delta * 2.0)
	if d > want:
		var dir := _steer(_nav_dir(_threat.global_position, delta), delta)
		velocity.x = dir.x * 3.8
		velocity.z = dir.z * 3.8
		_play("run")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_attack_cd = 1.6 if _ranged() else 1.3
			_strike()
		elif _anim_now != _anims.get("attack") and _anim_now != _anims.get("shoot"):
			_play("idle")
	move_and_slide()


func _strike() -> void:
	var lvl: int = world.zone_levels().y
	var dmg := 9.0 * (1.0 + 0.12 * lvl)
	if _ranged():
		_play("shoot")
		var from := global_position + Vector3(0, 1.4 * _size(), 0)
		var to := _threat.global_position + Vector3(0, 1.0, 0)
		Game.play_sound("shot", from, -6.0, 0.7 if world.tech_level < 4 else 1.0)
		Fx.light_flash(world, from - global_transform.basis.z * 0.7, Color(1.0, 0.7, 0.4), 2.0, 5.0, 0.08)
		if randf() < (0.55 if world.tech_level < 4 else 0.75):
			_threat.npc_damage(dmg * (1.4 if world.tech_level >= 4 else 1.0), self)
			Fx.burst(world, to, _threat.blood_color, 8, 2.5, 0.03, 0.4)
	else:
		_play("attack", 1.3)
		Game.play_sound("swing", global_position, -8.0)
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if is_instance_valid(_threat) and _threat.state != Enemy.State.DEAD and global_position.distance_to(_threat.global_position) < 2.6:
				_threat.npc_damage(dmg, self)
				Game.play_sound("flesh", _threat.global_position, -6.0))


## Monsters target villagers only while they fight (see Enemy._pick_target).
func can_be_attacked() -> bool:
	return not _dead and (_activity == "fight" or mortal)


## Hit by a monster: villagers are never killed by monsters, they get knocked out.
func monster_damage(amount: float, _attacker: Node3D) -> void:
	if _dead or _activity == "knocked":
		return
	_stamina -= amount
	Fx.burst(world, global_position + Vector3(0, 1.2, 0), blood_color, 8, 2.0, 0.03, 0.4)
	if _stamina <= 0.0:
		if mortal:
			_die()
			return
		_knock_out()
	elif _activity != "fight":
		bark("scream", 8.0)
		_flee_t = 6.0
		_activity = "flee"


func _knock_out() -> void:
	_drop_weapon()
	_activity = "knocked"
	_knock_t = 40.0
	bark("knocked", 1.0)
	if _anims.get("death", "") != "":
		anim.play(_anims["death"], 0.1)
		_anim_now = _anims["death"]
	_label.modulate = Color(0.6, 0.6, 0.6)


func _get_up() -> void:
	_stamina = 70.0 + world.zone_levels().y * 12.0
	_label.modulate = Color(0.9, 0.9, 0.85)
	bark("recover", 1.0)
	_anim_now = ""
	_resume()


# --------------------------------------------------------------------------- talking

func bark(key: String, cooldown: float) -> void:
	if _bark_cd.get(key, 0.0) > 0.0 or _voice.playing:
		return
	_bark_cd[key] = cooldown
	var id := VillagerTalk.pick(_speaker(), key)
	if id != "":
		speak(id)


func prompt() -> String:
	if _dead or _activity == "knocked":
		return ""
	return Loc.t("Talk to") + " " + vname


func _greeting_key() -> String:
	if _activity == "sleep":
		return "sleepy"
	if world.wanted_stars > 0:
		return "greet_wanted"
	if not _met:
		_met = true
		return "tech_%d" % world.tech_level
	if world.hero_t > 0.0:
		return "greet_hero_" + personality
	if world.weather in ["rain", "storm"] and randf() < 0.5:
		return "greet_rain"
	if world.raid_t > 0.0 and randf() < 0.5:
		return "greet_after_raid"
	if world.day_night.is_night():
		return "greet_night_" + personality
	return "greet_day_" + personality


func interact() -> void:
	if _dead or _activity == "knocked":
		return
	_talking = true
	if Brain.active():
		_ai_talk()
		return
	_say(_greeting_key(), _greeting_key() not in ["greet_wanted", "sleepy"])


## Speaks a line and shows the topic menu (or just Goodbye).
func _say(key: String, with_topics := true) -> void:
	var id := VillagerTalk.pick(_speaker(), key, "greet_day_kind")
	_play("talk")
	var dur := speak(id)
	world.player.input_locked = true
	var lid := Loc.line(id)
	var buttons := []
	if with_topics:
		buttons.append([Loc.t("The town"), func() -> void: _say("town_%d" % world.tech_level)])
		buttons.append([Loc.t("Rumours"), func() -> void: _say("rumour_%d" % world.tech_level)])
		buttons.append([Loc.t("About you"), func() -> void: _say("self_" + personality)])
		buttons.append([Loc.t("My weapon"), func() -> void: _say("tech_%d" % world.tech_level)])
		buttons.append([Loc.t("Need help?"), _help])
		buttons += _extra_topics()
	buttons.append([Loc.t("Go away"), _leave])
	world.hud.show_dialogue(vname, Loc.t(job), "", QuestManager.line_text(lid), buttons, dur, QuestManager.line_translation(lid))


func _help() -> void:
	match personality:
		"kind":
			if not _gift_given:
				_gift_given = true
				var p: Player = world.player
				p.add_mana(40.0)
				p.add_gold(15 + world.zone_levels().y * 4)
				_say("gift_kind")
				return
			_say("ask_help")
		"grumpy":
			_say("gift_no")
		_:
			_say("ask_help")


## Extra replies for special villagers (town traders, the notice board...): [[text, Callable]].
func _extra_topics() -> Array:
	if job == "Priest":
		return [[Loc.t("Ask for a blessing"), _bless]]
	return []


## The priest's blessing: health and mana restored (once every few minutes).
static var _blessed_at := -1000000


func _bless() -> void:
	var now := Time.get_ticks_msec()
	if now - _blessed_at < 300000:
		_say("gift_no")
		return
	_blessed_at = now
	var p: Player = world.player
	p.health = p.max_health
	p.mana = p.max_mana
	Game.play_sound("heal", null, -2.0, 0.9)
	Fx.burst(world, p.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.95, 0.6), 30, 3.0, 0.05, 1.0, -2.0)
	world.hud.show_message(Loc.t("You feel blessed: health and mana restored"), Color(1.0, 0.95, 0.6), 2.5)
	_say("gift_kind")


## "Go away": close the talk, with a short goodbye.
func _leave() -> void:
	_end_talk()
	_bark_cd.erase("bye")
	bark("kid_bye" if _speaker() == "kid" else "bye_" + personality, 0.0)


func _end_talk() -> void:
	_talking = false
	_voice.stop()
	world.player.input_locked = false
	world.hud.hide_dialogue()
	_anim_now = ""
	# a villager stopped on the way somewhere carries on walking
	if not _busy_with_danger() and _activity != "walk":
		_arrive()


# --------------------------------------------------------------------------- AI brain (Northvale)

var _ai_greet_at := 0


## Who this villager is, for the AI brain (the id is stable across visits: name + job).
func ai_info() -> Dictionary:
	return {"npc": "ashford_%s_%s" % [vname, job], "name": vname, "job": job, "personality": personality, "gender": _speaker()}


## The shout pool for this villager's kind ("vil:<personality>:<m|f>", children "vil:kid:kid").
func ai_kind() -> String:
	return "vil:kid:kid" if _speaker() == "kid" else "vil:%s:%s" % [personality, gender]


func ai_say(text: String, audio: String) -> float:
	return Brain.say_at(self, text, audio, 1.35 if _speaker() == "kid" else 1.95, voice_pitch, Color(0.9, 0.95, 1.0))


func ai_free() -> bool:
	return not _dead and not _talking and _activity not in ["knocked", "sleep", "flee", "hide", "fight"]


## A greeting written by the AI when the player walks past (every couple of minutes at most).
func _ai_greet() -> void:
	var now := Time.get_ticks_msec()
	if now < _ai_greet_at or not ai_free() or not Brain.can_bark():
		return
	_ai_greet_at = now + randi_range(90000, 180000)
	var r := await Brain.bark(ai_kind(), "greet_night" if world.day_night.is_night() else "greet_day")
	if is_instance_valid(self) and ai_free():
		ai_say(r.get("text", ""), r.get("audio", ""))


## A conversation through the AI brain: the villager answers in character, with three replies.
func _ai_talk(said := "") -> void:
	_play("talk")
	world.player.input_locked = true
	var leave := [Loc.t("Go away"), _leave]
	world.hud.show_dialogue(vname, Loc.t(job), "", "…", [leave], 0.5)
	var req := ai_info()
	req["choice"] = said
	req["ctx"] = world.ai_context()
	var r := await Brain.talk(req)
	if not is_instance_valid(self) or not _talking:
		return
	var s := Brain.load_voice(r.get("audio", ""))
	var dur := 3.0
	if s:
		_voice.stream = s
		_voice.pitch_scale = voice_pitch
		_voice.play()
		dur = s.get_length() / voice_pitch
	var buttons := []
	for c in r.get("choices", []):
		var reply: String = c
		buttons.append([reply, func() -> void: _ai_talk(reply)])
	if _speaker() != "kid":
		buttons.append([Loc.t("Need help?"), _help])
		buttons += _extra_topics()
	buttons.append(leave)
	world.hud.show_dialogue(vname, Loc.t(job), "", r.get("line", "…"), buttons, dur)


func speak(line_id: String) -> float:
	var id := Loc.line(line_id)
	var path := "res://assets/voice/%s.wav" % id
	if not ResourceLoader.exists(path):
		return 3.0
	var s: AudioStream = load(path)
	_voice.stream = s
	_voice.pitch_scale = voice_pitch
	_voice.play()
	return s.get_length() / voice_pitch


# --------------------------------------------------------------------------- harm by the player

## Hit by the player (bullets, spells, explosions). Returns true if killed.
func take_damage(amount: float, _pos: Vector3, _dir: Vector3, _kind := "bullet") -> bool:
	if _dead:
		return false
	hp -= amount
	_unlie()
	_talking = false
	world.damage_number(global_position + Vector3(0, 1.8, 0), amount, "bullet")
	if hp <= 0.0:
		_die()
		world.report_crime(3, global_position)
		return true
	_drop_weapon()
	_threat = null
	_flee_t = 18.0
	_activity = "flee"
	bark("scream", 2.0)
	world.report_crime(1, global_position)
	return false


func apply_burn(_dps: float, _duration: float) -> void:
	pass


func _die() -> void:
	_dead = true
	_drop_weapon()
	remove_from_group("damageable")
	remove_from_group("interactables")
	remove_from_group("villagers")
	collision_layer = 0
	_label.visible = false
	Game.play_sound("enemy_death", global_position, -2.0, 1.25 if gender == "f" else 1.0)
	if _anims.get("death", "") != "":
		anim.play(_anims["death"], 0.1)
	var tw := create_tween()
	tw.tween_interval(90.0)
	tw.tween_callback(queue_free)
