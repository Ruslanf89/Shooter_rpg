class_name LootDrop
extends Node3D
## Item or gold lying on the ground. Items: a small model with a quality-coloured light beam and
## name tag, picked up with F. Gold: a coin pile collected by walking over it.

var world: Node
var item: Dictionary = {}       # empty = gold
var gold := 0
var _t := randf() * 10.0
var _visual: Node3D


func _ready() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	if item.is_empty():
		_build_gold()
	else:
		add_to_group("interactables")
		_build_item()
	# pop out of the corpse / chest
	var start := position
	position += Vector3(0, 0.8, 0)
	var tw := create_tween()
	tw.tween_property(self, "position", start, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var life := create_tween()
	life.tween_interval(240.0)
	life.tween_callback(queue_free)


func _build_gold() -> void:
	var m := MeshKit.mat(Color(1.0, 0.8, 0.28), 0.25, 0.95)
	for i in clampi(gold / 5 + 2, 2, 7):
		MeshKit.cyl(_visual, 0.06, 0.06, 0.014, Vector3(randf_range(-0.12, 0.12), 0.01 + i * 0.012, randf_range(-0.12, 0.12)), m, Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 12)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.3)
	l.light_energy = 0.6
	l.omni_range = 1.6
	l.position.y = 0.3
	add_child(l)


func _build_item() -> void:
	var q: int = item["quality"]
	var col := Items.quality_color(q)
	var base: String = item["base"]
	var metal := MeshKit.mat(Color(0.2, 0.2, 0.22), 0.4, 0.8)
	var accent := MeshKit.mat(col, 0.4, 0.3, 0.4)
	match base:
		"helmet":
			MeshKit.sphere(_visual, 0.16, Vector3(0, 0.12, 0), metal, Vector3(1, 0.8, 1.1))
			MeshKit.box(_visual, Vector3(0.34, 0.03, 0.36), Vector3(0, 0.07, 0), accent)
		"armor":
			MeshKit.box(_visual, Vector3(0.4, 0.45, 0.16), Vector3(0, 0.25, 0), metal)
			MeshKit.box(_visual, Vector3(0.42, 0.08, 0.18), Vector3(0, 0.4, 0), accent)
		"gloves":
			for s in [-1.0, 1.0]:
				MeshKit.box(_visual, Vector3(0.1, 0.06, 0.16), Vector3(s * 0.08, 0.05, 0), metal, Vector3(0, s * 20.0, 0))
				MeshKit.box(_visual, Vector3(0.1, 0.07, 0.04), Vector3(s * 0.08, 0.06, 0.09), accent, Vector3(0, s * 20.0, 0))
		"boots":
			for s in [-1.0, 1.0]:
				MeshKit.box(_visual, Vector3(0.1, 0.2, 0.1), Vector3(s * 0.08, 0.1, 0), metal)
				MeshKit.box(_visual, Vector3(0.1, 0.07, 0.2), Vector3(s * 0.08, 0.035, -0.05), accent)
		"amulet":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.08
			ring.outer_radius = 0.095
			MeshKit.inst(_visual, ring, Vector3(0, 0.12, 0), MeshKit.mat(Color(0.9, 0.75, 0.3), 0.3, 0.9), Vector3(90, 0, 0))
			MeshKit.sphere(_visual, 0.04, Vector3(0, 0.03, 0), MeshKit.mat(col, 0.1, 0.0, 1.5))
		_:
			# a weapon lying on its side
			var length := 0.9 if base in ["rifle", "sniper", "lmg", "shotgun", "flamethrower"] else (1.2 if base.begins_with("staff") else 0.5)
			MeshKit.box(_visual, Vector3(0.06, 0.1, length), Vector3(0, 0.06, 0), metal, Vector3(0, 0, 90))
			MeshKit.box(_visual, Vector3(0.07, 0.04, length * 0.4), Vector3(0, 0.06, length * 0.2), accent, Vector3(0, 0, 90))
	var beam := CylinderMesh.new()
	beam.top_radius = 0.02
	beam.bottom_radius = 0.12
	beam.height = 2.0 + q * 1.2
	beam.radial_segments = 8
	var b := MeshKit.inst(self, beam, Vector3(0, beam.height * 0.5, 0), MeshKit.glow(Color(col, 0.22)))
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 0.8 + q * 0.4
	l.omni_range = 2.5
	l.position.y = 0.5
	add_child(l)
	var tag := Label3D.new()
	tag.text = Items.display_name(item)
	tag.modulate = col
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.fixed_size = true
	tag.pixel_size = 0.0008
	tag.font_size = 36
	tag.outline_size = 10
	tag.position.y = 0.7
	tag.visibility_range_end = 25.0
	add_child(tag)


func prompt() -> String:
	return Loc.t("Pick up") + " " + Items.display_name(item)


func interact() -> void:
	if Items.add_to_bag(Game.inventory, item):
		Game.play_sound("pickup_item", null, -3.0)
		world.hud.show_message(Loc.t("Picked up") + ": " + Items.display_name(item), Items.quality_color(item["quality"]), 1.6)
		queue_free()
	else:
		world.hud.show_message(Loc.t("Your bag is full"), Color(1.0, 0.4, 0.3), 1.5)
		Game.play_sound("empty", null, -4.0)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * 0.8
	if item.is_empty() and world and world.player:
		var p: Player = world.player
		if not p.dead and p.global_position.distance_to(global_position) < 1.4:
			Game.play_sound("pickup_coins", null, -3.0)
			p.add_gold(gold)
			queue_free()


## Drops gold and/or an item at `pos` (ground height is taken from the world).
static func spawn(w: Node, pos: Vector3, it: Dictionary, coins := 0) -> LootDrop:
	var d := LootDrop.new()
	d.world = w
	d.item = it
	d.gold = coins
	d.position = Vector3(pos.x, w.ground(pos.x, pos.z) + 0.05, pos.z)
	w.add_child(d)
	return d
