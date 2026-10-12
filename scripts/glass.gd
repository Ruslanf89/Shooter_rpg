class_name Glass
extends RefCounted
## Window glass from the Textured Glass Material Pack (CC0): normal-mapped, slightly refracting
## panes. Houses get leaded "cube" panes, the castle stained glass, bottles plain green glass.

const DIR := "res://assets/textures/glass/"

static var _cache := {}


static func enabled() -> bool:
	return ResourceLoader.exists(DIR + "cube_normal.png")


static func _make(normal: String, color: Color, normal_scale: float, uv: Vector3, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = "Glass_" + normal + str(color.to_html())   # KitBuild.put shares materials by name
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.roughness = 0.12
	m.metallic_specular = 0.7
	m.normal_enabled = true
	m.normal_texture = load(DIR + normal + "_normal.png")
	m.normal_scale = normal_scale
	m.uv1_scale = uv
	m.refraction_enabled = true
	m.refraction_scale = 0.025
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow > 0.0:
		# stained glass seems to glow a little from the light behind it
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b)
		m.emission_energy_multiplier = glow
	return m


## Leaded window panes for houses, shops and taverns.
static func window() -> Material:
	if not _cache.has("window"):
		_cache["window"] = _make("cube", Color(0.82, 0.9, 0.92, 0.22), 0.7, Vector3(2.0, 2.0, 1.0))
	return _cache["window"]


## Coloured stained glass for the castle and the temple.
static func stained() -> Material:
	if not _cache.has("stained"):
		_cache["stained"] = _make("voronoi", Color(0.35, 0.45, 0.95, 0.6), 1.0, Vector3(1.5, 1.5, 1.0), 0.35)
	return _cache["stained"]


## Green bottle glass.
static func bottle() -> Material:
	if not _cache.has("bottle"):
		_cache["bottle"] = _make("blury", Color(0.3, 0.6, 0.35, 0.55), 0.4, Vector3.ONE)
	return _cache["bottle"]
