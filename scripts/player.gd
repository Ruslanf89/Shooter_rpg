class_name Player
extends CharacterBody3D
## First-person player: AK-47 (hitscan, recoil, reload, casings), frost magic (mana),
## movement with footsteps, health with regeneration.

signal died

const WALK_SPEED := 5.5
const SPRINT_SPEED := 8.5
const JUMP_VELOCITY := 5.2
const MAX_HEALTH := 100.0
const MAG_SIZE := 30
const MAX_RESERVE := 600
const FIRE_INTERVAL := 0.1          # 600 rounds per minute
const DAMAGE := 34.0
const HEADSHOT_MULT := 2.5
const REGEN_DELAY := 6.0
const REGEN_RATE := 4.0

const MAX_MANA := 100.0
const MANA_REGEN := 1.5
const NOVA_RADIUS := 10.0
const NOVA_FREEZE := 4.0
const NOVA_DAMAGE := 20.0

const HIP_POS := Vector3(0.24, -0.2, -0.6)
const HIP_ROT := Vector3(0.0, 0.07, 0.0)
const ADS_POS := Vector3(0.0, -0.086, -0.56)
const SPRINT_POS := Vector3(0.1, -0.26, -0.55)

var world: Node
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var health := MAX_HEALTH
var mana := MAX_MANA
var mag := MAG_SIZE
var move_mult := 1.0
var noclip := false                # admin: fly through walls
var reserve := 90
var dead := false
var reloading := false
var aiming := false
var sprinting := false
var spread := 0.0
var fire_cd := 0.0
var cds: Dictionary = {}           # skill id -> cooldown remaining
var since_damage := 99.0
var max_health := MAX_HEALTH
var max_mana := MAX_MANA
var progress: Dictionary           # shared with Game.progress (level, xp, points, ranks)
var slow_t := 0.0
var gadget := ""                 # selected gadget id (see Crafting.GADGETS)
var _bandage_t := 0.0
var input_locked := false          # true while a dialogue window is open
var _fall_speed := 0.0
var climbing: ClimbSpot = null      # tree being climbed
var _climb_angle := 0.0
var _climb_h := 0.0
var _climb_snd := 0.0

var head: Node3D
var camera: Camera3D
var weapon_cam: Camera3D
var gun_pivot: Node3D
var gun_kick: Node3D
var gun: Node3D
var mag_node: Node3D
var mag_base := Vector3.ZERO
var bolt: Node3D
var bolt_base := Vector3.ZERO
var muzzle: Node3D
var eject_port: Node3D
var flash: Node3D
var flash_light: OmniLight3D
var cast_orb: Node3D

var _kick := 0.0
var _bob_t := 0.0
var _sway := Vector2.ZERO
var _flash_t := 0.0
var _shake := 0.0
var _cast_t := 0.0
var _burst := 0
var _since_shot := 99.0
var _recoil_accum := 0.0
var _step_dist := 0.0
var _shot_count := 0

static var _flash_tex: ImageTexture


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4 | 8 | 16
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.3

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)

	head = Node3D.new()
	head.position.y = 1.62
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 75.0
	camera.near = 0.05
	camera.far = 600.0
	camera.set_cull_mask_value(2, false)   # the gun is drawn by the weapon camera instead
	head.add_child(camera)
	camera.current = true

	_build_weapon_view()
	progress = Game.progress
	_build_gun()
	recalc_stats()
	health = max_health
	mana = max_mana


func apply_carry(carry: Dictionary) -> void:
	if carry.has("reserve"):
		reserve = int(carry["reserve"])


# --------------------------------------------------------------------------- progression

func rank(skill: String) -> int:
	return int(progress["ranks"].get(skill, 0))


func recalc_stats() -> void:
	var lvl: int = progress["level"]
	var hp_frac := health / max_health if max_health > 0.0 else 1.0
	max_health = (MAX_HEALTH + (lvl - 1) * 8.0 + eq("health")) * (1.0 + 0.1 * rank("toughness"))
	max_mana = MAX_MANA + (lvl - 1) * 6.0 + 12.0 * rank("arcane_mind") + eq("mana")
	health = minf(max_health, hp_frac * max_health)
	armor = Items.total_armor(_armor_only())
	move_mult = float(wdef.get("move", 1.0)) * (1.0 + eq("speed") / 100.0)


func _armor_only() -> Dictionary:
	var d := {}
	for s in ["helmet", "armor", "gloves", "boots", "amulet"]:
		d[s] = inv()["equip"].get(s, {})
	return d


func add_xp(amount: int) -> void:
	if progress["level"] >= Skills.MAX_LEVEL:
		return
	amount = int(amount * (1.0 + eq("xp") / 100.0))
	progress["xp"] += amount
	var leveled := false
	while progress["level"] < Skills.MAX_LEVEL and progress["xp"] >= Skills.xp_to_next(progress["level"]):
		progress["xp"] -= Skills.xp_to_next(progress["level"])
		progress["level"] += 1
		progress["points"] += 1
		leveled = true
	if leveled:
		recalc_stats()
		health = max_health
		mana = max_mana
		Game.play_sound("level_up", null, -2.0)
		world.hud.show_level_up(progress["level"])
		Fx.burst(world, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.85, 0.3), 50, 5.0, 0.06, 1.2, -2.0)
		Fx.light_flash(world, global_position + Vector3(0, 2.0, 0), Color(1.0, 0.85, 0.4), 5.0, 10.0, 1.0)


func learn(skill: String) -> bool:
	var def: Dictionary = Skills.LIST[skill]
	if progress["points"] <= 0 or rank(skill) >= def["max"] or progress["level"] < def["level"]:
		return false
	progress["points"] -= 1
	progress["ranks"][skill] = rank(skill) + 1
	recalc_stats()
	Game.play_sound("potion", null, -4.0, 0.8)
	return true


## The locals teach you their magic (quest reward): +1 rank, needs no talent point or level.
func teach(skill: String, teacher: String) -> void:
	var def: Dictionary = Skills.LIST[skill]
	if rank(skill) < int(def["max"]):
		progress["ranks"][skill] = rank(skill) + 1
	recalc_stats()
	Game.play_sound("heal", null, -2.0, 0.8)
	Fx.burst(world, global_position + Vector3(0, 1.0, 0), Color(0.5, 0.7, 1.0), 40, 4.0, 0.05, 1.2, -2.0)
	Fx.light_flash(world, global_position + Vector3(0, 2.0, 0), Color(0.5, 0.7, 1.0), 4.0, 8.0, 0.8)
	var lines := ["%s  -  %s %d" % [Loc.t(def["name"]), Loc.t("rank"), rank(skill)]]
	if def["type"] == "active":
		lines.append(Loc.t("Cast it with [%s]") % def["key"])
	world.hud.show_loot(Loc.t("%s taught you magic") % teacher, lines)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## The gun lives on render layer 2 and is drawn by a second camera on top of the world,
## so it never clips into walls (standard FPS trick).
var weapon_layer: CanvasLayer
var flashlight: SpotLight3D


## Torch on the gun: a soft shadowed beam. Toggle with L.
func toggle_flashlight() -> void:
	if flashlight == null:
		flashlight = SpotLight3D.new()
		flashlight.light_color = Color(1.0, 0.95, 0.85)
		flashlight.light_energy = 4.0
		flashlight.spot_range = 45.0
		flashlight.spot_angle = 26.0
		flashlight.spot_angle_attenuation = 1.6
		flashlight.spot_attenuation = 0.7
		flashlight.shadow_enabled = true
		flashlight.light_volumetric_fog_energy = 0.5
		flashlight.position = Vector3(0.2, -0.15, -0.3)
		camera.add_child(flashlight)
		flashlight.visible = false
	flashlight.visible = not flashlight.visible
	Game.play_sound("pickup_tech", null, -8.0, 1.2)


func _build_weapon_view() -> void:
	var layer := CanvasLayer.new()
	weapon_layer = layer
	layer.layer = 0
	add_child(layer)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(container)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.handle_input_locally = false
	vp.msaa_3d = Viewport.MSAA_4X
	container.add_child(vp)

	weapon_cam = Camera3D.new()
	weapon_cam.fov = 62.0
	weapon_cam.near = 0.01
	weapon_cam.far = 20.0
	weapon_cam.cull_mask = 2
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.7)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	weapon_cam.environment = env
	vp.add_child(weapon_cam)
	weapon_cam.current = true


# --------------------------------------------------------------------------- gun model

static func _wood_material() -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.frequency = 0.03
	n.fractal_octaves = 3
	var g := Gradient.new()
	g.set_color(0, Color(0.3, 0.12, 0.05))
	g.set_color(1, Color(0.62, 0.3, 0.12))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(40, 40, 3)
	m.roughness = 0.45
	m.clearcoat_enabled = true
	m.clearcoat = 0.4
	return m


static func _metal_material(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = MeshKit.detail_texture()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(25, 25, 25)
	m.metallic = 0.75
	m.roughness = rough
	return m


static func _flash_texture() -> ImageTexture:
	if _flash_tex:
		return _flash_tex
	var s := 128
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s, s) * 0.5
	for y in s:
		for x in s:
			var d := Vector2(x, y) - c
			var r := d.length() / (s * 0.5)
			var a := d.angle()
			var spikes := pow(absf(cos(a * 3.0)), 18.0) * 0.8 + pow(absf(cos(a * 3.0 + 0.5)), 30.0) * 0.4
			var v := clampf((1.0 - r) * (0.35 + spikes * 1.4), 0.0, 1.0)
			v = pow(v, 1.3) + clampf(1.0 - r * 3.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 0.85, 0.55, clampf(v, 0.0, 1.0)))
	_flash_tex = ImageTexture.create_from_image(img)
	return _flash_tex


func _build_gun() -> void:
	gun_pivot = Node3D.new()
	gun_pivot.position = HIP_POS
	camera.add_child(gun_pivot)
	gun_kick = Node3D.new()
	gun_pivot.add_child(gun_kick)
	gun = Node3D.new()
	gun_kick.add_child(gun)
	# muzzle flash: crossed star cards (re-parented to each weapon's muzzle)
	flash = Node3D.new()
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = _flash_texture()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var front := QuadMesh.new()
	front.size = Vector2(0.22, 0.22)
	MeshKit.inst(flash, front, Vector3(0, 0, -0.02), fm)
	var side := QuadMesh.new()
	side.size = Vector2(0.12, 0.3)
	MeshKit.inst(flash, side, Vector3(0, 0, -0.13), fm, Vector3(90, 0, 0))
	MeshKit.inst(flash, side, Vector3(0, 0, -0.13), fm, Vector3(90, 90, 0))
	flash.visible = false
	flash_light = OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.75, 0.4)
	flash_light.light_energy = 3.5
	flash_light.omni_range = 8.0
	flash_light.visible = false
	# frost orb shown in the left hand while casting
	cast_orb = Node3D.new()
	cast_orb.position = Vector3(-0.24, -0.2, -0.62)
	camera.add_child(cast_orb)
	MeshKit.sphere(cast_orb, 0.012, Vector3.ZERO, MeshKit.unshaded(Color(0.85, 0.95, 1.0)))
	MeshKit.sphere(cast_orb, 0.026, Vector3.ZERO, MeshKit.glow(Color(0.4, 0.7, 1.0, 0.4)))
	cast_orb.visible = false
	for n in camera.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.layers = 2
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for mi in flash.get_children():
		(mi as MeshInstance3D).layers = 2
	equip_active()


# --------------------------------------------------------------------------- equipment

var weapon_item: Dictionary = {}     # the equipped item in the active weapon slot
var wdef: Dictionary = {}            # its weapon definition (Items.WEAPONS)
var _hip := HIP_POS
var _ads := ADS_POS
var armor := 0.0
var _model_base := ""
var _reload_tw: Tween


func inv() -> Dictionary:
	return Game.inventory


## Sum of an affix over the equipped items (the inactive weapon doesn't count).
func eq(stat: String) -> float:
	var s := 0.0
	var equip: Dictionary = inv()["equip"]
	var active: String = inv().get("active", "weapon1")
	for slot in equip:
		var it = equip[slot]
		if not it is Dictionary or it.is_empty() or (str(slot).begins_with("weapon") and slot != active):
			continue
		s += float(it["affixes"].get(stat, 0.0))
	return s


## Activates the weapon in the active slot (rebuilding the first-person model) and refreshes stats.
func equip_active() -> void:
	var equip: Dictionary = inv()["equip"]
	var slot: String = inv().get("active", "weapon1")
	if equip.get(slot, {}).is_empty():
		slot = "weapon2" if slot == "weapon1" else "weapon1"
	if equip.get(slot, {}).is_empty():
		equip["weapon1"] = Items.generate(1, 0, "weapon", "pistol")
		slot = "weapon1"
	inv()["active"] = slot
	if not weapon_item.is_empty():
		weapon_item["mag"] = mag
	weapon_item = equip[slot]
	wdef = Items.weapon_def(weapon_item)
	mag = int(weapon_item.get("mag", wdef["mag"]))
	if _model_base != weapon_item["base"]:
		_model_base = weapon_item["base"]
		if flash.get_parent():
			flash.get_parent().remove_child(flash)
		if flash_light.get_parent():
			flash_light.get_parent().remove_child(flash_light)
		for c in gun.get_children():
			c.free()
		var parts := WeaponModels.build(_model_base, gun)
		mag_node = parts["mag"]
		bolt = parts["bolt"]
		muzzle = parts["muzzle"]
		eject_port = parts["eject"]
		_hip = parts["hip"]
		_ads = parts["ads"]
		mag_base = mag_node.position
		bolt_base = bolt.position
		muzzle.add_child(flash)
		muzzle.add_child(flash_light)
		gun.rotation_degrees = Vector3.ZERO
	if _reload_tw and _reload_tw.is_valid():
		_reload_tw.kill()
	mag_node.visible = true
	reloading = false
	recalc_stats()


func switch_weapon(slot := "") -> void:
	if reloading or dead:
		return
	var cur: String = inv().get("active", "weapon1")
	if slot == "":
		slot = "weapon2" if cur == "weapon1" else "weapon1"
	if slot == cur or inv()["equip"].get(slot, {}).is_empty():
		return
	weapon_item["mag"] = mag
	inv()["active"] = slot
	Game.play_sound("bolt", null, -6.0, 1.2)
	gun_pivot.position += Vector3(0, -0.3, 0.1)
	equip_active()


func mag_size() -> int:
	return int(wdef.get("mag", 30))


func uses_mana() -> bool:
	return wdef.get("fire", "") == "spell"


## Damage per hit of the active weapon including skills and equipment.
func weapon_damage() -> float:
	return Items.weapon_damage(weapon_item) * (1.0 + 0.06 * rank("marksman")) * (1.0 + (eq("dmg") - float(weapon_item["affixes"].get("dmg", 0.0))) / 100.0)


func crit_roll() -> float:
	var chance := 0.05 + eq("crit") / 100.0
	if randf() < chance:
		return 1.8 + eq("crit_dmg") / 100.0
	return 1.0


func add_gold(amount: int, silent := false) -> void:
	amount = int(amount * (1.0 + eq("gold") / 100.0))
	inv()["gold"] = int(inv()["gold"]) + amount
	if not silent:
		world.hud.show_message(Loc.t("+%d %s") % [amount, Loc.t("gold")], Color(1.0, 0.85, 0.3), 1.2)

## Box stretched between two points in gun space (forearms / sleeves).
func _limb(a: Vector3, b: Vector3, thickness: float, material: Material) -> void:
	var m := BoxMesh.new()
	m.size = Vector3(thickness, thickness, a.distance_to(b))
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) * 0.5)
	gun.add_child(mi)


# --------------------------------------------------------------------------- input / movement

func _unhandled_input(event: InputEvent) -> void:
	if dead or input_locked:
		return
	if event.is_action_pressed("interact"):
		world.interact()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("flashlight"):
		toggle_flashlight()
		return
	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		world.open_inventory()
		return
	if event.is_action_pressed("use_potion"):
		use_healing()
		return
	if event.is_action_pressed("use_mana"):
		use_mana_potion()
		return
	if event.is_action_pressed("gadget"):
		use_gadget()
		return
	if event.is_action_pressed("gadget_next"):
		next_gadget(true)
		return
	if event.is_action_pressed("craft"):
		get_viewport().set_input_as_handled()
		world.open_craft("field")
		return
	var mm := event as InputEventMouseMotion
	if mm and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := Game.mouse_sensitivity * (0.55 if aiming else 1.0)
		rotate_y(-mm.relative.x * sens)
		head.rotate_x(-mm.relative.y * sens)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))
		_sway += Vector2(-mm.relative.x, mm.relative.y) * 0.00025
		_sway = _sway.limit_length(0.04)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _bandage_t > 0.0 and not dead:
		_bandage_t -= delta
		health = minf(max_health, health + max_health * 0.25 / 4.0 * delta)
	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		move_and_slide()
		return

	if input_locked:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
		if climbing == null:
			move_and_slide()
		return

	if climbing:
		_climb_step(delta)
		return

	if noclip:
		var nin := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var fly := camera.global_transform.basis * Vector3(nin.x, 0, nin.y)
		if Input.is_action_pressed("jump"):
			fly.y += 1.0
		if Input.is_action_pressed("sprint"):
			fly.y -= 1.0
		global_position += fly.normalized() * 22.0 * delta if fly.length() > 0.01 else Vector3.ZERO
		velocity = Vector3.ZERO
		collision_mask = 0
		return
	collision_mask = 1 | 4 | 8 | 16
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		Game.play_sound("jump", null, -10.0)
		Game.play_sound("jump_breath", null, -20.0, randf_range(1.15, 1.35))
		_footstep(-14.0)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	aiming = Input.is_action_pressed("aim") and not reloading and _cast_t <= 0.0
	sprinting = Input.is_action_pressed("sprint") and input.y < -0.1 and not aiming and is_on_floor()
	var speed := (SPRINT_SPEED if sprinting else WALK_SPEED) * move_mult
	if aiming:
		speed *= 0.6
	if slow_t > 0.0:
		slow_t -= delta
		speed *= 0.5
	var accel := (14.0 if is_on_floor() else 3.0) * speed
	velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	var was_air := not is_on_floor()
	if was_air:
		_fall_speed = maxf(_fall_speed, -velocity.y)
	move_and_slide()
	if is_on_wall() and is_on_floor() and dir.length() > 0.1:
		_step_up(dir)
	if was_air and is_on_floor():
		_land(_fall_speed)
		_fall_speed = 0.0

	var hs := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and hs > 1.0:
		_step_dist += hs * delta
		if _step_dist > (2.6 if sprinting else 2.1):
			_step_dist = 0.0
			_footstep(-10.0 if sprinting else -14.0)

	fire_cd -= delta
	for k in cds:
		cds[k] = maxf(0.0, cds[k] - delta)
	_since_shot += delta
	var wants_fire := Input.is_action_pressed("shoot") if wdef.get("auto", true) else Input.is_action_just_pressed("shoot")
	if wants_fire and fire_cd <= 0.0 and not reloading and not sprinting and _cast_t <= 0.0:
		if uses_mana():
			if _spend_mana(float(wdef["mana"])):
				_shoot()
			else:
				fire_cd = 0.4
		elif mag > 0:
			_shoot()
		else:
			fire_cd = 0.3
			Game.play_sound("empty", null, -6.0)
			_start_reload()
	if not Input.is_action_pressed("shoot"):
		_burst = 0
	if Input.is_action_just_pressed("reload"):
		_start_reload()
	if Input.is_action_just_pressed("weapon_1"):
		switch_weapon("weapon1")
	elif Input.is_action_just_pressed("weapon_2"):
		switch_weapon("weapon2")
	elif Input.is_action_just_pressed("weapon_next") or Input.is_action_just_pressed("weapon_prev"):
		switch_weapon()
	for id in Skills.ORDER:
		var def: Dictionary = Skills.LIST[id]
		if def["type"] == "active" and Input.is_action_just_pressed(def["action"]):
			cast(id)

	# recoil recovery: pull the view back down after a burst
	if _since_shot > 0.12 and _recoil_accum > 0.0:
		var r := minf(_recoil_accum, deg_to_rad(9.0) * delta)
		_recoil_accum -= r
		head.rotation.x -= r * 0.75

	spread = move_toward(spread, 0.0, delta * 0.12)
	since_damage += delta
	if since_damage > REGEN_DELAY and health < max_health:
		health = minf(max_health, health + REGEN_RATE * (1.0 + 0.02 * progress["level"]) * (1.0 + eq("regen") / 100.0) * delta)
	mana = minf(max_mana, mana + (MANA_REGEN + 0.5 * rank("arcane_mind")) * delta)


## Walk up small ledges (steps, doorsteps, plinths) up to 0.42 m instead of getting stuck.
func _step_up(dir: Vector3) -> void:
	var up := Vector3(0, 0.42, 0)
	if test_move(global_transform, up):
		return
	var raised := global_transform.translated(up)
	if test_move(raised, dir.normalized() * 0.3):
		return
	global_position += up + dir.normalized() * 0.12
	velocity.y = minf(velocity.y, 0.0)


# --------------------------------------------------------------------------- climbing

func start_climb(spot: ClimbSpot, from_top := false) -> void:
	climbing = spot
	if from_top:
		_climb_angle = spot.face_angle
		_climb_h = spot.top_height - 0.3
	else:
		var off := global_position - spot.tree_base
		_climb_angle = atan2(off.x, off.z)
		_climb_h = clampf(global_position.y - spot.tree_base.y, 0.0, spot.top_height)
	velocity = Vector3.ZERO
	_fall_speed = 0.0
	Game.play_sound("step_grass", null, -6.0)
	world.hud.show_message(Loc.t("[W/S] climb   [A/D] around the trunk   [Space] let go"), Color(0.85, 0.95, 1.0), 3.5)


## Climbing: W/S up and down the trunk, A/D around it, Space lets go. Reaching the top puts the
## player on the branch platform; reaching the bottom steps off.
func _climb_step(delta: float) -> void:
	var spot := climbing
	sprinting = true        # lowers the gun and blocks shooting
	aiming = false
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var up := -input.y
	_climb_h = clampf(_climb_h + up * 2.2 * delta, 0.0, spot.top_height)
	_climb_angle += input.x * 1.3 * delta
	var r := spot.radius_at(_climb_h) + 0.5
	var target := spot.tree_base + Vector3(sin(_climb_angle) * r, _climb_h, cos(_climb_angle) * r)
	global_position = global_position.lerp(target, minf(1.0, delta * 10.0))
	velocity = Vector3.ZERO
	if absf(up) > 0.1 or absf(input.x) > 0.1:
		_climb_snd -= delta
		if _climb_snd <= 0.0:
			_climb_snd = 0.42
			Game.play_sound("step_grass", null, -11.0, randf_range(0.75, 1.0))
	if _climb_h >= spot.top_height - 0.01 and up > 0.1:
		climbing = null
		sprinting = false
		global_position = spot.top_pos + Vector3(0, 0.15, 0)
		world.hud.show_message(Loc.t("You climbed to the top!"), Color(0.7, 1.0, 0.6), 2.0)
	elif _climb_h <= 0.0 and up < -0.1:
		climbing = null
		sprinting = false
	elif Input.is_action_just_pressed("jump"):
		climbing = null
		sprinting = false
		velocity = Vector3(sin(_climb_angle), 0, cos(_climb_angle)) * 3.5 + Vector3(0, 2.5, 0)


func _land(fall_speed: float) -> void:
	if fall_speed > 4.0:
		Game.play_sound("land", null, -10.0 + minf(fall_speed, 12.0) * 0.5, 0.8)
		_footstep(-5.0, 0.8)
		_kick = maxf(_kick, 0.5)
		if fall_speed > 7.5:
			Game.play_sound("jump_breath", null, -14.0, 0.9)
	else:
		_footstep(-9.0, 0.85)


func _footstep(volume: float, pitch := 1.0) -> void:
	for wz in world.water_zones:
		var c: Vector2 = wz[0]
		if c.distance_to(Vector2(global_position.x, global_position.z)) < float(wz[1]) and global_position.y < float(wz[2]) + 0.1:
			Game.play_sound("splash", null, volume + 2.0)
			return
	Game.play_sound("step_" + surface_under(), null, volume, pitch)


## "wood" (floors, platforms), "stone" (paving, stone floors), "snow" or "grass".
func surface_under() -> String:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.6, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit["collider"] is Node:
		var n: Node = hit["collider"]
		var s := ""
		while n and s == "":
			s = String(n.get_meta("surface", ""))
			n = n.get_parent() if not n is Terrain else null
		if s == "wood" or s == "stone":
			return s
	if world.terrain.mask_at(global_position.x, global_position.z).g > 0.5:
		return "stone"
	return "snow" if world.cfg.get("grass_tex", "") == "Snow006" else "grass"


func _process(delta: float) -> void:
	weapon_cam.global_transform = camera.global_transform
	if dead:
		return

	camera.fov = lerpf(camera.fov, float(wdef.get("ads_fov", 55.0)) if aiming else 75.0, minf(1.0, 12.0 * delta))

	var hspeed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and hspeed > 0.5:
		_bob_t += delta * hspeed * 1.7
	var bob_amt := 0.004 if aiming else 0.018
	var bob := Vector3(sin(_bob_t) * bob_amt, -absf(cos(_bob_t)) * bob_amt, 0)
	_sway = _sway.lerp(Vector2.ZERO, minf(1.0, 8.0 * delta))

	var base := _hip
	var target_rot := HIP_ROT + Vector3(_sway.y * 2.0, _sway.x * 2.0, 0)
	if aiming:
		base = _ads
		target_rot = Vector3(_sway.y, _sway.x, 0) * 0.6
	elif sprinting:
		base = _hip + Vector3(-0.12, -0.06, 0.05)
		target_rot = Vector3(-0.35, 0.9, 0.25)
	if _cast_t > 0.0:
		_cast_t -= delta
		base += Vector3(0.05, -0.12, 0.05)
		target_rot += Vector3(-0.3, -0.2, -0.3)
		cast_orb.visible = true
		cast_orb.scale = Vector3.ONE * (1.0 + sin(_cast_t * 40.0) * 0.15)
	else:
		cast_orb.visible = false
	gun_pivot.position = gun_pivot.position.lerp(base + bob + Vector3(_sway.x, _sway.y, 0), minf(1.0, 14.0 * delta))
	gun_pivot.rotation = gun_pivot.rotation.lerp(target_rot, minf(1.0, 10.0 * delta))

	_kick = move_toward(_kick, 0.0, delta * 10.0)
	gun_kick.position = Vector3(0, _kick * 0.01, _kick * (0.03 if aiming else 0.065))
	gun_kick.rotation.x = _kick * (0.035 if aiming else 0.1)
	bolt.position = bolt_base + Vector3(0, 0, _kick * (0.07 if wdef.get("fire", "") != "pellets" else 0.12))

	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			flash.visible = false
			flash_light.visible = false

	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake * 0.06
		camera.v_offset = randf_range(-1.0, 1.0) * _shake * 0.06
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


# --------------------------------------------------------------------------- shooting

func _shoot() -> void:
	var kind: String = wdef.get("fire", "hitscan")
	fire_cd = float(wdef["interval"]) / (1.0 + eq("rate") / 100.0)
	if not uses_mana():
		mag -= 1
	_burst += 1
	_since_shot = 0.0
	_shot_count += 1
	world.shots_fired += 1
	var b := camera.global_transform.basis
	var s := ((0.003 if aiming else 0.018) + spread) * (float(wdef["spread"]) / 0.018 if kind != "pellets" else 1.0)
	if not is_on_floor():
		s += 0.05
	elif Vector2(velocity.x, velocity.z).length() > 1.0:
		s += 0.012
	var dmg := weapon_damage()
	match kind:
		"pellets":
			Game.play_sound("shot", null, -2.0, float(wdef["pitch"]))
			var ps: float = float(wdef["spread"]) * (0.7 if aiming else 1.0)
			for i in int(wdef["pellets"]):
				var d := (-b.z + b.x * randf_range(-ps, ps) + b.y * randf_range(-ps, ps)).normalized()
				_hitscan(d, dmg, i == 0)
		"bolt":
			Game.play_sound("swing", null, -2.0, 0.7)
			Game.play_sound("chest_latch", null, -8.0, 1.5)
			_launch_projectile("bolt", dmg)
			mag_node.visible = false
		"grenade":
			Game.play_sound("shot", null, -4.0, 0.45)
			_launch_projectile("grenade", dmg)
			mag_node.rotation.z += TAU / 6.0
		"flame":
			_flame(dmg)
		"spell":
			var el: String = wdef.get("element", "frost")
			var sp := dmg * (1.0 + eq("spell") / 100.0)
			if el == "lightning":
				_cast_lightning(sp, 2)
			else:
				_cast_projectile(el, sp)
			_kick = 0.6
			return
		_:
			Game.play_sound("shot", null, -5.0, float(wdef["pitch"]))
			var dir := (-b.z + b.x * randf_range(-s, s) + b.y * randf_range(-s, s)).normalized()
			_hitscan(dir, dmg, true)

	# recoil: climbs over a spray, drifts sideways in a pattern
	var rec: float = float(wdef["recoil"]) / 0.6
	var climb := deg_to_rad(clampf(0.45 + _burst * 0.06, 0.45, 1.1) * (0.45 if aiming else 1.0) * rec)
	head.rotation.x = clampf(head.rotation.x + climb, deg_to_rad(-88.0), deg_to_rad(88.0))
	_recoil_accum += climb
	rotate_y(deg_to_rad(sin(_burst * 0.7) * 0.25 + randf_range(-0.15, 0.15)) * (0.5 if aiming else 1.0) * minf(rec, 2.0))
	_kick = minf(1.0 + rec * 0.2, 1.8)
	spread = minf(spread + 0.006, 0.055)
	camera.fov += 0.6 * minf(rec, 3.0)
	if kind in ["hitscan", "pellets", "grenade"]:
		flash.visible = true
		flash.rotation.z = randf() * TAU
		flash.scale = Vector3.ONE * randf_range(0.8, 1.25) * (1.6 if kind == "pellets" else 1.0)
		flash_light.visible = true
		_flash_t = 0.045
		if kind != "grenade":
			_eject_casing()
		if _shot_count % 3 == 0:
			_muzzle_smoke()
	if mag == 0:
		_start_reload()


## One bullet / pellet along `dir`.
func _hitscan(dir: Vector3, base_dmg: float, effects: bool) -> void:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 300.0, 1 | 4 | 16)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var pos: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var col: Object = hit["collider"]
	if col and col.has_method("bullet_hit"):
		col.bullet_hit(base_dmg)
		Game.play_sound("impact_stone", pos, -6.0, 0.8)
		Fx.burst(world, pos, Color(1.0, 0.8, 0.4), 6, 4.0, 0.02, 0.2)
	elif col and col.has_method("take_damage") and not col is Player:
		var headshot: bool = col.has_method("is_head_hit") and col.is_head_hit(pos)
		var dmg := base_dmg * (HEADSHOT_MULT if headshot else 1.0) * crit_roll() * randf_range(0.9, 1.1)
		var killed: bool = col.take_damage(dmg, pos, dir, "crit" if headshot else "bullet")
		world.shots_hit += 1
		world.hud.hit_marker(killed, headshot)
		if effects:
			Game.play_sound("flesh", pos, -4.0)
		if headshot:
			Game.play_sound("hit", null, -6.0, 1.3)
		Fx.burst(world, pos, col.blood_color if "blood_color" in col else Color(0.6, 0.05, 0.05), 12, 3.0, 0.035, 0.5)
	else:
		var surface: String = col.get_meta("surface", "stone") if col else "stone"
		if effects:
			match surface:
				"wood":
					Game.play_sound("impact_wood", pos, -6.0)
				"ground":
					Game.play_sound("impact_ground", pos, -6.0)
				_:
					Game.play_sound("impact_stone", pos, -8.0)
		Fx.burst(world, pos, Color(0.5, 0.35, 0.2) if surface == "wood" else Color(0.7, 0.68, 0.62), 6, 3.0, 0.03, 0.4)
		world.add_bullet_hole(pos, normal)


func _launch_projectile(kind: String, dmg: float) -> void:
	var p := Projectile.new()
	p.kind = kind
	p.world = world
	p.damage = dmg
	world.add_child(p)
	var hit := _aim_point(200.0, 1 | 4 | 16)
	var fwd := -camera.global_transform.basis.z
	var target: Vector3 = hit["position"] if not hit.is_empty() else camera.global_position + fwd * 200.0
	var start := muzzle.global_position
	# the muzzle is drawn by the weapon camera; start from a point in front of the eye instead
	start = camera.global_position + fwd * 0.6 + camera.global_transform.basis.x * 0.12 - camera.global_transform.basis.y * 0.08
	p.launch(start, (target - start).normalized())


## Flamethrower: a short cone of fire that burns everything in front of you.
func _flame(dmg: float) -> void:
	if _shot_count % 4 == 0:
		Game.play_sound("fire_cast", null, -12.0, randf_range(1.3, 1.6))
	var fwd := -camera.global_transform.basis.z
	for node in get_tree().get_nodes_in_group("damageable"):
		var e: Node3D = node
		var to := e.global_position + Vector3(0, 1.0, 0) - camera.global_position
		var d := to.length()
		if d < 10.0 and fwd.dot(to / d) > 0.9 and _visible_from(camera.global_position, e):
			var killed: bool = e.take_damage(dmg * randf_range(0.8, 1.2), e.global_position + Vector3(0, 1.2, 0), fwd, "fire")
			if not killed and e.has_method("apply_burn"):
				e.apply_burn(dmg * 1.5, 3.0)
			if killed:
				world.hud.hit_marker(true, false)
	Fx.flame_spray(world, camera.global_position + fwd * 0.8 - camera.global_transform.basis.y * 0.2, fwd)

func _eject_casing() -> void:
	var shell := RigidBody3D.new()
	shell.collision_layer = 0
	shell.collision_mask = 1
	shell.mass = 0.02
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.012, 0.012, 0.04)
	cs.shape = bx
	shell.add_child(cs)
	MeshKit.cyl(shell, 0.006, 0.006, 0.04, Vector3.ZERO, MeshKit.mat(Color(0.85, 0.62, 0.25), 0.3, 0.8), Vector3(90, 0, 0), 6)
	world.add_child(shell)
	var b := camera.global_transform.basis
	shell.global_position = eject_port.global_position
	shell.linear_velocity = velocity + b.x * randf_range(2.5, 3.5) + b.y * randf_range(1.5, 2.5) + b.z * randf_range(0.0, 0.8)
	shell.angular_velocity = Vector3(randf_range(-20, 20), randf_range(-20, 20), randf_range(-20, 20))
	# the tween belongs to the casing, so it is cleaned up together with it
	var tw := shell.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void: Game.play_sound("shell", shell.global_position, -14.0))
	tw.tween_interval(2.5)
	tw.tween_callback(shell.queue_free)


func _muzzle_smoke() -> void:
	var p := CPUParticles3D.new()
	var m := SphereMesh.new()
	m.radius = 0.06
	m.height = 0.12
	m.radial_segments = 6
	m.rings = 3
	m.material = MeshKit.glow(Color(0.5, 0.5, 0.5, 0.12))
	p.mesh = m
	p.amount = 6
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 0.8
	p.direction = Vector3.UP
	p.spread = 40.0
	p.gravity = Vector3(0, 0.3, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.scale_amount_min = 1.0
	p.scale_amount_max = 3.0
	world.add_child(p)
	p.global_position = muzzle.global_position
	p.emitting = true
	p.finished.connect(p.queue_free)


func _start_reload() -> void:
	if reloading or dead or uses_mana() or mag >= mag_size() or reserve <= 0:
		return
	reloading = true
	var empty := mag == 0
	_reload_tw = create_tween()
	var tw := _reload_tw
	tw.set_speed_scale(2.0 / maxf(float(wdef.get("reload", 2.0)), 0.3) / (1.0 - 0.1 * rank("quick_hands")) * (1.0 + eq("reload") / 100.0))
	tw.tween_property(gun, "rotation_degrees", Vector3(-10, 20, 30), 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(Game.play_sound.bind("mag_out", null, -3.0))
	tw.tween_property(mag_node, "position", mag_base + Vector3(0, -0.4, 0.1), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: mag_node.visible = false)
	tw.tween_interval(0.35)
	tw.tween_callback(func() -> void: mag_node.visible = true)
	tw.tween_property(mag_node, "position", mag_base + Vector3(0, -0.06, 0.03), 0.25)
	tw.tween_property(mag_node, "position", mag_base, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(Game.play_sound.bind("mag_in", null, -3.0))
	tw.tween_interval(0.15)
	if empty:
		tw.tween_property(gun, "rotation_degrees", Vector3(-5, 30, -10), 0.2)
		tw.tween_callback(Game.play_sound.bind("bolt", null, -3.0))
		tw.tween_property(bolt, "position", bolt_base + Vector3(0, 0, 0.08), 0.1)
		tw.tween_property(bolt, "position", bolt_base, 0.06)
		tw.tween_interval(0.15)
	tw.tween_property(gun, "rotation_degrees", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_finish_reload)


func _finish_reload() -> void:
	reloading = false
	if dead:
		return
	var take := mini(mag_size() - mag, reserve)
	mag_node.visible = true
	mag += take
	reserve -= take


# --------------------------------------------------------------------------- magic

func _spend_mana(cost: float) -> bool:
	if mana < cost:
		world.hud.show_message(Loc.t("Not enough mana"), Color(0.5, 0.7, 1.0), 1.0)
		Game.play_sound("empty", null, -4.0, 0.6)
		return false
	mana -= cost
	return true


## Tries to cast an active skill (checks rank, cooldown, mana).
func cast(id: String) -> void:
	if dead or world.finished:
		return
	var def: Dictionary = Skills.LIST[id]
	var r := rank(id)
	if r <= 0:
		world.hud.show_message(Loc.t("%s not learned yet  -  press [K]") % def["name"], Color(0.8, 0.8, 0.8), 1.2)
		return
	if cds.get(id, 0.0) > 0.0:
		return
	if id == "frost_arrow" and reloading:
		return
	if not _spend_mana(def["mana"]):
		return
	cds[id] = def["cd"]
	var power := 1.0 + 0.3 * (r - 1)
	match id:
		"frost_arrow": _cast_projectile("frost", 28.0 * power)
		"frost_nova": _cast_frost_nova(power, r)
		"fireball": _cast_projectile("fire", 60.0 * power)
		"heal": _cast_heal(r)
		"chain_lightning": _cast_lightning(70.0 * power, 3 + (r - 1))
		"blink": _cast_blink()
		"meteor": _cast_meteor()


func _frost_mult() -> float:
	return 1.0 + 0.2 * rank("frostbite")


func _freeze_bonus() -> float:
	return 0.7 * rank("frostbite")


## Point under the crosshair (up to `max_dist`).
func _aim_point(max_dist: float, mask := 1 | 4) -> Dictionary:
	var from := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + fwd * max_dist, mask)
	return get_world_3d().direct_space_state.intersect_ray(q)


func _cast_projectile(kind: String, dmg: float) -> void:
	_cast_t = 0.35
	Game.play_sound("frost_cast" if kind == "frost" else "fire_cast", null, -3.0)
	var from := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var hit := _aim_point(200.0)
	var target: Vector3 = hit["position"] if not hit.is_empty() else from + fwd * 200.0
	var start := from + fwd * 0.6 - camera.global_transform.basis.x * 0.2 - camera.global_transform.basis.y * 0.15
	var p := FrostBolt.new()
	p.kind = kind
	p.world = world
	if kind == "frost":
		p.damage = dmg * _frost_mult()
		p.freeze_time = 3.0 + _freeze_bonus()
		p.dot_dps = 7.0 * _frost_mult()
	else:
		p.damage = dmg
	world.add_child(p)
	p.launch(start, target - start)
	world.shots_fired += 1


func _cast_frost_nova(power: float, r: int) -> void:
	_cast_t = 0.45
	Game.play_sound("frost_nova", null, -1.0)
	var radius := NOVA_RADIUS + 2.0 * (r - 1)
	var hits := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e.global_position.distance_to(global_position) <= radius:
			var killed := e.take_damage(NOVA_DAMAGE * power * _frost_mult() * randf_range(0.9, 1.1), e.global_position + Vector3(0, 1.5, 0), Vector3.ZERO, "frost")
			if not killed:
				e.apply_frost(NOVA_FREEZE + _freeze_bonus(), 5.0 * _frost_mult(), 5.0)
			hits += 1
	if hits > 0:
		world.hud.hit_marker(false, false)
	_nova_effect(radius)


func _cast_heal(r: int) -> void:
	_cast_t = 0.4
	var amount := max_health * (0.35 + 0.1 * (r - 1))
	health = minf(max_health, health + amount)
	Game.play_sound("heal", null, -2.0)
	world.hud.show_message(Loc.t("+%d HEALTH") % int(amount), Color(0.4, 1.0, 0.45), 1.2)
	Fx.burst(world, global_position + Vector3(0, 1.0, 0), Color(0.45, 1.0, 0.5), 40, 3.0, 0.05, 1.2, -3.0)
	Fx.light_flash(world, global_position + Vector3(0, 1.5, 0), Color(0.4, 1.0, 0.5), 4.0, 8.0, 0.8)


func _cast_lightning(dmg: float, jumps: int) -> void:
	_cast_t = 0.35
	# first target: the enemy closest to the crosshair direction
	var fwd := -camera.global_transform.basis.z
	var best: Enemy = null
	var best_score := 0.0
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		var to := e.global_position + Vector3(0, 1.0, 0) - camera.global_position
		var d := to.length()
		if d > 35.0:
			continue
		var dot := fwd.dot(to / d)
		if dot > 0.9 and dot - d * 0.002 > best_score and _visible_from(camera.global_position, e):
			best = e
			best_score = dot - d * 0.002
	Game.play_sound("lightning", null, -2.0)
	var from := camera.global_position + fwd * 0.6 - camera.global_transform.basis.y * 0.2 - camera.global_transform.basis.x * 0.2
	if best == null:
		var hit := _aim_point(30.0)
		var to_pt: Vector3 = hit["position"] if not hit.is_empty() else from + fwd * 30.0
		_bolt_visual(from, to_pt)
		return
	var hit_list: Array = []
	var current := best
	var dmg_now := dmg
	while current and hit_list.size() <= jumps:
		var to_pos := current.global_position + Vector3(0, 1.0, 0)
		_bolt_visual(from, to_pos)
		hit_list.append(current)
		var killed := current.take_damage(dmg_now * randf_range(0.9, 1.1), to_pos, Vector3.ZERO, "lightning")
		if not killed:
			current.stun(0.6)
		world.hud.hit_marker(killed, false)
		Fx.burst(world, to_pos, Color(0.7, 0.85, 1.0), 12, 4.0, 0.03, 0.3)
		from = to_pos
		dmg_now *= 0.8
		var next: Enemy = null
		var nd := 9.0
		for node in get_tree().get_nodes_in_group("enemies"):
			var e := node as Enemy
			if e in hit_list:
				continue
			var d := e.global_position.distance_to(current.global_position)
			if d < nd:
				nd = d
				next = e
		current = next


func _visible_from(from: Vector3, e: Enemy) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, e.global_position + Vector3(0, 1.0, 0), 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Jagged glowing lightning bolt between two points (fades quickly).
func _bolt_visual(a: Vector3, b: Vector3) -> void:
	var im := ImmediateMesh.new()
	var mat := MeshKit.unshaded(Color(0.75, 0.88, 1.0))
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var segs := maxi(6, int(a.distance_to(b) / 1.2))
	var prev := a
	var dir := (b - a)
	var side := dir.cross(Vector3.UP).normalized()
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var p := a + dir * t
		if i < segs:
			p += side * randf_range(-0.5, 0.5) + Vector3(0, randf_range(-0.4, 0.4), 0)
		im.surface_add_vertex(prev)
		im.surface_add_vertex(p)
		prev = p
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	var glow := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.06
	cm.height = a.distance_to(b)
	cm.radial_segments = 6
	glow.mesh = cm
	glow.material_override = MeshKit.glow(Color(0.5, 0.7, 1.0, 0.5))
	world.add_child(glow)
	glow.global_position = (a + b) * 0.5
	glow.look_at(b, Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.FORWARD)
	glow.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	Fx.light_flash(world, b, Color(0.6, 0.8, 1.0), 4.0, 8.0, 0.2)
	var tw := mi.create_tween()
	tw.tween_interval(0.15)
	tw.tween_callback(mi.queue_free)
	tw.tween_callback(glow.queue_free)


func _cast_blink() -> void:
	var fwd := -camera.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var from := global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + fwd * 12.0, 1 | 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var dist := 12.0
	if not hit.is_empty():
		dist = maxf(0.0, from.distance_to(hit["position"]) - 0.8)
	Fx.burst(world, global_position + Vector3(0, 1.0, 0), Color(0.7, 0.5, 1.0), 30, 3.0, 0.05, 0.6, 0.0)
	var target := global_position + fwd * dist
	target.y = maxf(target.y, world.ground(target.x, target.z) + 0.1)
	global_position = target
	velocity = Vector3.ZERO
	Game.play_sound("blink", null, -3.0)
	Fx.burst(world, global_position + Vector3(0, 1.0, 0), Color(0.7, 0.5, 1.0), 30, 3.0, 0.05, 0.6, 0.0)
	camera.fov += 12.0


func _cast_meteor() -> void:
	_cast_t = 0.5
	var hit := _aim_point(60.0, 1)
	var pos: Vector3
	if hit.is_empty():
		var fwd := -camera.global_transform.basis.z
		pos = camera.global_position + fwd * 40.0
	else:
		pos = hit["position"]
	Game.play_sound("fire_cast", null, 0.0, 0.6)
	Meteor.strike(world, pos, 7.0, 220.0, "player", 1.0)


func _nova_effect(radius := NOVA_RADIUS) -> void:
	var root := Node3D.new()
	world.add_child(root)
	root.global_position = global_position
	var ice := StandardMaterial3D.new()
	ice.albedo_color = Color(0.7, 0.9, 1.0, 0.75)
	ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.emission_enabled = true
	ice.emission = Color(0.4, 0.7, 1.0)
	ice.emission_energy_multiplier = 0.8
	ice.roughness = 0.1
	var spikes: Array[Node3D] = []
	for ring in 3:
		var r := radius * (0.25 + ring * 0.32)
		var count := 10 + ring * 6
		for i in count:
			var a := TAU * i / count + ring * 0.3
			var s := Node3D.new()
			root.add_child(s)
			var p := Vector3(cos(a) * r, 0, sin(a) * r)
			s.global_position = global_position + p
			s.position.y = world.ground(s.global_position.x, s.global_position.z) - global_position.y
			s.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
			MeshKit.cyl(s, 0.0, randf_range(0.18, 0.32), randf_range(0.8, 1.6), Vector3(0, 0.5, 0), ice, Vector3.ZERO, 5)
			s.scale = Vector3(1, 0.01, 1)
			spikes.append(s)
	var tw := root.create_tween().set_parallel(true)
	for i in spikes.size():
		tw.tween_property(spikes[i], "scale", Vector3.ONE, 0.18).set_delay(float(i) / spikes.size() * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.9)
	tw.chain().tween_property(root, "scale", Vector3(1, 0.01, 1), 0.4)
	tw.chain().tween_callback(root.queue_free)
	Fx.burst(world, global_position + Vector3(0, 0.5, 0), Color(0.8, 0.95, 1.0), 60, 11.0, 0.07, 0.8, 1.0)
	Fx.light_flash(world, global_position + Vector3(0, 1.5, 0), Color(0.5, 0.8, 1.0), 6.0, 16.0, 0.6)


# --------------------------------------------------------------------------- pickups / damage

func add_ammo_silent(amount: int) -> void:
	reserve = mini(MAX_RESERVE, reserve + amount)


func add_ammo(amount: int) -> void:
	reserve = mini(MAX_RESERVE, reserve + amount)
	Game.play_sound("pickup_ammo", null, -2.0)
	world.hud.show_message(Loc.t("+%d AMMO") % amount, Color(1.0, 0.88, 0.4), 1.5)
	if mag == 0:
		_start_reload()


# --------------------------------------------------------------------------- consumables / gadgets

## [H]: a health potion (or a greater one, or a bandage).
func use_healing() -> void:
	var c := Crafting.pouch("consumables")
	for id in ["health_potion", "greater_potion", "bandage"]:
		if int(c.get(id, 0)) <= 0:
			continue
		if health >= max_health - 0.5:
			world.hud.show_message(Loc.t("Your health is full"), Color(0.8, 0.8, 0.8), 1.2)
			return
		c[id] = int(c[id]) - 1
		match id:
			"health_potion":
				health = minf(max_health, health + max_health * 0.5)
			"greater_potion":
				health = max_health
			"bandage":
				_bandage_t = 4.0
		Game.play_sound("drink" if id != "bandage" else "pickup_item", null, -2.0)
		world.hud.show_message(Loc.t(Crafting.CONSUMABLES[id][0]) + "  (%d %s)" % [int(c[id]), Loc.t("left")], Color(1.0, 0.5, 0.45), 1.4)
		return
	world.hud.show_message(Loc.t("No healing items - craft them [U] or buy potions from an alchemist"), Color(1.0, 0.6, 0.5), 2.0)


## [J]: a mana potion.
func use_mana_potion() -> void:
	var c := Crafting.pouch("consumables")
	if int(c.get("mana_potion", 0)) <= 0:
		world.hud.show_message(Loc.t("No mana potions"), Color(0.6, 0.7, 1.0), 1.4)
		return
	c["mana_potion"] = int(c["mana_potion"]) - 1
	add_mana(max_mana * 0.6)


## [B]: use the selected gadget ([N] picks the next one).
func use_gadget() -> void:
	var g := Crafting.pouch("gadgets")
	if gadget == "" or int(g.get(gadget, 0)) <= 0:
		next_gadget(false)
	if gadget == "":
		world.hud.show_message(Loc.t("No gadgets - build them at a workbench"), Color(0.8, 0.8, 0.8), 1.6)
		return
	g[gadget] = int(g[gadget]) - 1
	match gadget:
		"grenade":
			Gadgets.throw_grenade(self)
		"landmine":
			Gadgets.place_mine(self)
		"turret":
			Gadgets.place_turret(self)
		"fpv_drone":
			Gadgets.launch_drone(self)
	if int(g[gadget]) <= 0:
		next_gadget(false)


func next_gadget(announce: bool) -> void:
	var g := Crafting.pouch("gadgets")
	var keys: Array = Crafting.GADGETS.keys()
	var start := keys.find(gadget)
	for i in range(1, keys.size() + 1):
		var k: String = keys[(start + i) % keys.size()]
		if int(g.get(k, 0)) > 0:
			gadget = k
			if announce:
				world.hud.show_message(Loc.t(Crafting.GADGETS[k][0]) + " x%d" % int(g[k]), Color(0.85, 0.9, 0.7), 1.2)
			return
	gadget = ""


func add_mana(amount: float) -> void:
	mana = minf(max_mana, mana + amount)
	Game.play_sound("potion", null, -4.0)
	get_tree().create_timer(0.25).timeout.connect(Game.play_sound.bind("drink", null, -2.0, 0.8))
	world.hud.show_message(Loc.t("+%d MANA") % int(amount), Color(0.45, 0.7, 1.0), 1.5)


func take_damage(amount: float, source_pos: Vector3) -> void:
	if dead or world.finished or Game.god_mode:
		return
	# armor: 100 armor halves the damage
	amount *= 100.0 / (100.0 + armor)
	health -= amount
	since_damage = 0.0
	_shake = 0.25
	Game.play_sound("player_hit", null, -3.0)
	world.hud.damage_taken(source_pos)
	if health <= 0.0:
		health = 0.0
		_die()


func _die() -> void:
	dead = true
	aiming = false
	gun_pivot.visible = false
	cast_orb.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(head, "position:y", 0.35, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation:z", deg_to_rad(75.0), 0.9)
	died.emit()
