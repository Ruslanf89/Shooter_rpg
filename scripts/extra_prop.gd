@tool
class_name ExtraProp
extends Node3D
## A game object you place by hand in a level's extras scene (scenes/levels/<level>_extra.tscn).
## Pick `kind` in the Inspector; in the editor it shows as a coloured placeholder box, in the
## game the real building / prop / creature is built here. Rotate it (Y) to turn it: the arrow
## shows the front (door side). It always sits on the ground; raise it (Y) to lift it above.

const KINDS := ["house", "tavern", "blacksmith", "shop", "barracks", "watchtower", "stable", "granary", "chicken_coop",
	"sawmill", "fishing_hut", "gatehouse", "ruined_castle", "crypt", "well", "market_stall", "lamp_post", "bench",
	"cart", "signpost", "lantern", "torch", "campfire", "tent", "crate", "barrel", "hay_bale", "haystack", "fence",
	"ruined_wall", "climb_tree", "treasure_chest", "enemy", "animal"]

## Placeholder size in the editor (width, height, depth).
const SIZES := {"house": Vector3(9, 6, 7), "tavern": Vector3(13, 9, 9), "blacksmith": Vector3(9, 5, 7), "shop": Vector3(9, 5, 7),
	"barracks": Vector3(12, 5, 7), "watchtower": Vector3(3.6, 11, 3.6), "stable": Vector3(10, 3.4, 5), "granary": Vector3(5, 6.4, 5),
	"chicken_coop": Vector3(6, 2.2, 6), "sawmill": Vector3(8, 3.4, 10), "fishing_hut": Vector3(4.2, 4.6, 8), "gatehouse": Vector3(9.5, 8, 3),
	"ruined_castle": Vector3(22, 8, 22), "crypt": Vector3(14, 6, 15), "well": Vector3(2.6, 3.5, 2.6), "market_stall": Vector3(2.8, 2.5, 2.2),
	"lamp_post": Vector3(0.8, 3.2, 0.8), "bench": Vector3(1.8, 0.9, 0.5), "cart": Vector3(2.0, 1.5, 4.0), "signpost": Vector3(1.4, 2.8, 1.4),
	"lantern": Vector3(0.6, 2.6, 0.6), "torch": Vector3(0.4, 2.6, 0.4), "campfire": Vector3(2, 1, 2), "tent": Vector3(4, 2.8, 5),
	"crate": Vector3(0.9, 0.9, 0.9), "barrel": Vector3(0.9, 1, 0.9), "hay_bale": Vector3(1.6, 1, 1), "haystack": Vector3(3, 2.6, 3),
	"fence": Vector3(0.3, 1.3, 10), "ruined_wall": Vector3(8, 4, 1), "climb_tree": Vector3(10, 18, 10), "treasure_chest": Vector3(1.1, 0.9, 0.7),
	"enemy": Vector3(1, 2, 1), "animal": Vector3(1, 1.2, 1.6)}

@export_enum("house", "tavern", "blacksmith", "shop", "barracks", "watchtower", "stable", "granary", "chicken_coop",
	"sawmill", "fishing_hut", "gatehouse", "ruined_castle", "crypt", "well", "market_stall", "lamp_post", "bench",
	"cart", "signpost", "lantern", "torch", "campfire", "tent", "crate", "barrel", "hay_bale", "haystack", "fence",
	"ruined_wall", "climb_tree", "treasure_chest", "enemy", "animal") var kind := "house":
	set(v):
		kind = v
		_refresh()

@export_group("House")
## Width, height, depth of a house (metres before the 1.35 scale-up).
@export var house_size := Vector3(6.5, 4.0, 5.0)
@export var roof_color := Color(0.75, 0.3, 0.22)
@export var wall_color := Color(0.93, 0.89, 0.8)

@export_group("Enemy / animal")
## Enemy type, e.g. bandit, ghoul, skeleton, spider, gnoll, ice_troll, hellhound, drowned, pirate...
@export var enemy_type := "bandit"
## 0 = the level of the location at this spot.
@export var enemy_level := 0
@export var elite := false
@export var count := 1
## deer, rabbit, crow, chicken
@export var animal := "deer"

@export_group("Other")
## Fence and ruined wall length (metres).
@export var length := 10.0:
	set(v):
		length = v
		_refresh()
## Signpost text (one arm per line).
@export_multiline var sign_text := "Ashford"
## Tent / market stall cloth colour.
@export var cloth_color := Color(0.6, 0.18, 0.12)
## Climbable tree platform height.
@export var tree_height := 11.0


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	for c in get_children():
		if c.has_meta("_preview"):
			c.free()
	var size: Vector3 = SIZES.get(kind, Vector3.ONE)
	if kind in ["fence", "ruined_wall"]:
		size.z = length if kind == "fence" else size.z
		size.x = length if kind == "ruined_wall" else size.x
	var color := Color(0.3, 0.6, 1.0, 0.35)
	if kind in ["enemy"]:
		color = Color(1.0, 0.2, 0.15, 0.5)
	elif kind in ["animal", "climb_tree"]:
		color = Color(0.3, 0.9, 0.3, 0.4)
	elif kind in ["treasure_chest"]:
		color = Color(1.0, 0.8, 0.2, 0.6)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	box.mesh = bm
	box.material_override = m
	box.position.y = size.y * 0.5
	box.set_meta("_preview", true)
	add_child(box)
	# arrow on the ground pointing to the front (+z)
	var arrow := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(minf(size.x, 2.0), 0.05, minf(size.z * 0.4, 2.0))
	arrow.mesh = pm
	var am := StandardMaterial3D.new()
	am.albedo_color = Color(1.0, 0.9, 0.2)
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow.material_override = am
	arrow.rotation_degrees = Vector3(90, 0, 0)
	arrow.position = Vector3(0, 0.05, size.z * 0.5 + pm.size.z * 0.5)
	arrow.set_meta("_preview", true)
	add_child(arrow)
	var l := Label3D.new()
	l.text = kind if kind != "enemy" else "enemy: %s x%d" % [enemy_type, count]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64
	l.pixel_size = 0.01
	l.outline_size = 12
	l.position.y = size.y + 0.6
	l.no_depth_test = true
	l.set_meta("_preview", true)
	add_child(l)


# --------------------------------------------------------------------------- in game

func _spot(w: Node) -> Vector3:
	var gp := global_position
	var lift := maxf(0.0, gp.y - w.ground(gp.x, gp.z))
	return Vector3(gp.x, lift, gp.z)


func _yaw() -> float:
	return global_rotation_degrees.y


## Buildings and props (built with the level, before the player exists).
func build_static(w: Node) -> void:
	var p := _spot(w)
	var yaw := _yaw()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.x * 13.0 + p.z * 7.0)
	var r := {}
	match kind:
		"house": Buildings.house(w, p, yaw, house_size, roof_color, wall_color)
		"tavern": VBuild.tavern(w, p, yaw)
		"blacksmith": VBuild.blacksmith(w, p, yaw)
		"shop": set_meta("result", VBuild.shop(w, p, yaw))
		"barracks": set_meta("result", VBuild.barracks(w, p, yaw))
		"watchtower": VBuild.watchtower(w, p, yaw)
		"stable": VBuild.stable(w, p, yaw)
		"granary": VBuild.granary(w, p, yaw)
		"chicken_coop": set_meta("result", VBuild.chicken_coop(w, p, yaw))
		"sawmill": VBuild.sawmill(w, p, yaw)
		"fishing_hut": VBuild.fishing_hut(w, p, yaw)
		"gatehouse": VBuild.gatehouse(w, p, yaw)
		"ruined_castle": VBuild.ruined_castle(w, p, yaw, rng)
		"crypt": set_meta("result", VBuild.crypt(w, p, yaw))
		"well": VBuild.well(w, p)
		"market_stall": VBuild.market_stall(w, p, yaw, cloth_color, rng)
		"lamp_post": VBuild.lamp_post(w, p)
		"bench": VBuild.bench(w, p, yaw)
		"cart": VBuild.cart(w, p, yaw)
		"signpost": VBuild.signpost(w, p, yaw, Array(sign_text.split("\n", false)))
		"lantern": Props.lantern(w, p)
		"torch": Props.torch(w, p)
		"campfire": Props.campfire(w, p)
		"tent": Props.tent(w, p, yaw, cloth_color)
		"crate": Props.crate(w, p, yaw)
		"barrel": Props.barrel(w, p)
		"hay_bale": Props.hay_bale(w, p, yaw)
		"haystack": Props.haystack(w, p)
		"fence":
			var half := global_transform.basis.z.normalized() * length * 0.5
			Props.fence(w, p - half, p + half)
		"ruined_wall": Props.ruined_wall(w, p, yaw, length, 4.0, rng)
		"climb_tree": Props.climb_tree(w, p, tree_height, yaw)
		"treasure_chest":
			var c := TreasureChest.new()
			c.world = w
			w.add_child(c)
			c.global_position = w.free_spot(Vector3(p.x, 0, p.z), 0.7, 1.0) + Vector3(0, p.y, 0)
			c.rotation.y = deg_to_rad(yaw)


## Creatures and NPCs (added after the player exists).
func build_dynamic(w: Node) -> void:
	var p := _spot(w)
	match kind:
		"enemy":
			if not Enemy.TYPES.has(enemy_type):
				push_warning("ExtraProp: unknown enemy type '%s'" % enemy_type)
				return
			for i in count:
				var e := Enemy.new()
				e.type = enemy_type
				e.world = w
				e.level = enemy_level if enemy_level > 0 else w.enemy_level_at(p)
				e.elite = elite
				var size: Vector2 = w._enemy_size(enemy_type)
				var at := Vector3(p.x, 0, p.z) + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)) * (0.0 if count == 1 else 1.0)
				e.position = w.free_spot(at, size.x, size.y) + Vector3(0, 0.3, 0)
				e.set_meta("spawn", [enemy_type, at])
				w.add_child(e)
				e.died.connect(w._on_enemy_died)
		"animal":
			w.add_animals(animal, Vector3(p.x, 0, p.z), count)
		"shop":
			var r: Dictionary = get_meta("result", {})
			if r.is_empty():
				return
			var tg := QuestGiver.new()
			tg.world = w
			tg.id = "trader_extra_%d" % int(p.x)
			tg.display_name = Loc.t("Trader")
			tg.title = "Trader"
			tg.role = "trader"
			tg.model_file = "people/business"
			w.add_child(tg)
			tg.global_position = r["trader"]
			tg.rotation.y = r["trader_yaw"]
			var st := StashChest.new()
			st.world = w
			w.add_child(st)
			st.global_position = r["stash"]
			st.rotation.y = r["stash_yaw"]
		"barracks":
			var r: Dictionary = get_meta("result", {})
			for gp in r.get("guards", []):
				w.spawn_guard("guard", gp)
		"chicken_coop":
			var r: Dictionary = get_meta("result", {})
			if r.has("chickens"):
				w.add_animals("chicken", r["chickens"], 5)
