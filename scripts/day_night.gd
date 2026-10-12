class_name DayNight
extends Node
## Day / night cycle: 1 real minute = 1 game hour (24 min per day). Moves the sun and a moon
## light, fades the sky to a starry night, darkens ambient light and fog, and brightens lamps.
## The level config's sun/sky/fog values are the "noon" look. With Sky3D (world.sky3d) the sky,
## sun and moon are Sky3D's: this node only feeds it the hour and keeps the fog, ambient and lamps.

signal hour_changed(hour: int)

const NIGHT_TOP := Color(0.008, 0.012, 0.03)
const NIGHT_HORIZON := Color(0.025, 0.035, 0.06)
const NIGHT_FOG := Color(0.02, 0.025, 0.04)
const DUSK := Color(1.0, 0.5, 0.25)

var world: Node
var hour := 8.0
var hours_per_second := 1.0 / 60.0
var frozen := false
var daylight := 1.0          # 0 night .. 1 full day
var _moon: DirectionalLight3D
var _sky_mat: ShaderMaterial
var _base := {}
var _last_hour := -1
var _tick := 0.0


func _ready() -> void:
	var env: Environment = world.environment
	var cfg: Dictionary = world.cfg
	if world.sky3d == null:
		_sky_mat = env.sky.sky_material as ShaderMaterial
	var sky: Dictionary = cfg["sky"]
	_base = {"top": sky.get("top_color", Color(0.25, 0.45, 0.85)), "horizon": sky.get("horizon_color", Color(0.75, 0.82, 0.92)),
		"ground": sky.get("ground_color", Color(0.3, 0.33, 0.3)), "cloud": sky.get("cloud_color", Color(1, 0.97, 0.92)),
		"cloud_shadow": sky.get("cloud_shadow", Color(0.62, 0.66, 0.78)), "sun_energy": world.sun.light_energy,
		"sun_color": world.sun.light_color, "sun_yaw": (cfg.get("sun_rot", world.sun.rotation_degrees) as Vector3).y, "ambient": env.ambient_light_energy,
		"fog": env.fog_light_color, "fog_density": env.fog_density, "exposure": env.tonemap_exposure}
	if world.sky3d:
		_base["sun_energy"] = float(cfg.get("sun_energy", 1.3))
	else:
		_moon = DirectionalLight3D.new()
		_moon.light_color = Color(0.55, 0.65, 0.95)
		_moon.light_energy = 0.0
		_moon.shadow_enabled = true
		_moon.directional_shadow_max_distance = 80.0
		world.add_child(_moon)
	hour = float(cfg.get("start_hour", 8.5))
	_apply()


func set_hour(h: float) -> void:
	hour = fposmod(h, 24.0)
	_apply()


func is_night() -> bool:
	return daylight < 0.3


func clock_text() -> String:
	return "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]


func _process(delta: float) -> void:
	if not frozen:
		hour = fposmod(hour + delta * hours_per_second, 24.0)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.1
		_apply()
	if int(hour) != _last_hour:
		_last_hour = int(hour)
		hour_changed.emit(_last_hour)


func _apply() -> void:
	var env: Environment = world.environment
	# sun goes up at 6:00, highest at 12:00, down at 18:00
	var a := (hour - 6.0) / 12.0 * PI
	var elev := sin(a)                                   # -1 .. 1
	daylight = smoothstep(-0.18, 0.22, elev)
	var twilight := clampf(1.0 - absf(elev) / 0.3, 0.0, 1.0) * smoothstep(-0.25, 0.0, elev)
	var elev_deg := rad_to_deg(asin(clampf(elev, -1.0, 1.0)))
	var night := 1.0 - daylight
	var sun_k := clampf(world.cave_dim * 1.6 + 0.05, 0.0, 1.0)   # deep in a cave the sun barely reaches
	if world.sky3d:
		_apply_sky3d(sun_k)
		_apply_common(env, night, twilight)
		return
	var yaw: float = float(_base["sun_yaw"]) + (hour - 12.0) * 12.0
	world.sun.rotation_degrees = Vector3(-maxf(elev_deg, 2.0), yaw, 0)
	world.sun.light_energy = float(_base["sun_energy"]) * daylight * sun_k
	world.sun.light_color = (_base["sun_color"] as Color).lerp(DUSK, twilight * 0.8)
	world.sun.visible = daylight > 0.01
	# moon: opposite side of the sky, strongest around midnight
	_moon.rotation_degrees = Vector3(-clampf(-elev_deg, 10.0, 60.0), yaw + 180.0, 0)
	_moon.light_energy = 0.16 * night
	_moon.visible = night > 0.02
	# sky, ambient, fog, exposure
	var top: Color = (_base["top"] as Color).lerp(NIGHT_TOP, night)
	var hor: Color = (_base["horizon"] as Color).lerp(NIGHT_HORIZON, night).lerp(DUSK, twilight * 0.45)
	_sky_mat.set_shader_parameter("top_color", top)
	_sky_mat.set_shader_parameter("horizon_color", hor)
	_sky_mat.set_shader_parameter("ground_color", (_base["ground"] as Color).lerp(Color(0.01, 0.01, 0.015), night))
	_sky_mat.set_shader_parameter("cloud_color", (_base["cloud"] as Color).lerp(Color(0.06, 0.07, 0.1), night).lerp(DUSK, twilight * 0.4))
	_sky_mat.set_shader_parameter("cloud_shadow", (_base["cloud_shadow"] as Color).lerp(Color(0.02, 0.025, 0.04), night))
	_sky_mat.set_shader_parameter("night", night)
	_sky_mat.set_shader_parameter("moon_dir", -_moon.global_transform.basis.z)
	env.ambient_light_energy = float(_base["ambient"]) * lerpf(0.1, 1.0, daylight) * world.cave_dim
	_apply_common(env, night, twilight)


var _sky3d_energy := -1.0


## Sky3D: the hour moves its sun, moon and stars; the sun is dimmed in caves and bad weather.
func _apply_sky3d(sun_k: float) -> void:
	var tod: Node = world.sky3d.get("tod")
	if tod and absf(float(tod.get("current_time")) - hour) > 0.0005:
		tod.set("current_time", hour)
	var e := float(_base["sun_energy"]) * sun_k
	if absf(e - _sky3d_energy) > 0.01:
		_sky3d_energy = e
		world.sky3d.get("sky").set("sun_light_energy", e)
	# the sky itself already darkens the ambient light at night: only a little extra here
	world.environment.ambient_light_energy = float(_base["ambient"]) * lerpf(0.55, 1.0, daylight) * world.cave_dim


func _apply_common(env: Environment, night: float, twilight: float) -> void:
	env.fog_light_color = (_base["fog"] as Color).lerp(NIGHT_FOG, night).lerp(DUSK * 0.6, twilight * 0.3) * lerpf(0.06, 1.0, world.cave_dim)
	env.fog_density = float(_base["fog_density"]) * lerpf(1.35, 1.0, daylight)
	env.glow_intensity = lerpf(1.0, 0.55, daylight)
	world.lamp_mult = lerpf(1.8, 0.55, daylight)
	# the first-person gun is lit separately: darken it at night (the flashlight brightens it)
	var p = world.player
	if p and p.weapon_cam and p.weapon_cam.environment:
		var torch: float = 0.35 if p.flashlight and p.flashlight.visible else 0.0
		p.weapon_cam.environment.ambient_light_energy = lerpf(0.1, 0.75, daylight) * lerpf(0.4, 1.0, world.cave_dim) + torch
