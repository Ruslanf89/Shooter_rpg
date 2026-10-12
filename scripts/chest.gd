class_name TreasureChest
extends StaticBody3D
## Hidden treasure chest built from planks with iron bands, rivets, a lock and a rounded lid.
## Press F: the latch clicks, the lid creaks open, gold light spills out and the loot pops out
## and flies into the player, followed by a loot list on the HUD.

const W := 1.1        # width (x)
const D := 0.7        # depth (z)
const H := 0.55       # body height

var world: Node
var _lid: Node3D
var _glow: OmniLight3D
var _opened := false


func _ready() -> void:
	add_to_group("interactables")
	set_meta("surface", "wood")
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(W, 0.85, D)
	cs.shape = sh
	cs.position.y = 0.42
	add_child(cs)
	var wood := MeshKit.textured("Planks021", Color(0.78, 0.5, 0.3), 1.6, 0.35, 0.85)
	var dark := MeshKit.textured("Planks021", Color(0.45, 0.3, 0.2), 1.6, 0.35, 0.8)
	var iron := MeshKit.mat(Color(0.17, 0.16, 0.16), 0.55, 0.85)
	var brass := MeshKit.mat(Color(0.78, 0.6, 0.25), 0.35, 0.9)

	# body: horizontal planks with thin dark gaps, a bottom board and inner floor
	MeshKit.box(self, Vector3(W - 0.04, H * 0.55, D - 0.04), Vector3(0, H * 0.275, 0), dark)
	var rows := 4
	for r in rows:
		var y := 0.03 + (H - 0.04) * (r + 0.5) / rows
		var ph := (H - 0.04) / rows - 0.012
		for side in [-1.0, 1.0]:
			MeshKit.box(self, Vector3(W, ph, 0.035), Vector3(0, y, side * (D * 0.5 - 0.0175)), wood, Vector3(0, 0, randf_range(-0.6, 0.6)))
			MeshKit.box(self, Vector3(0.035, ph, D - 0.07), Vector3(side * (W * 0.5 - 0.0175), y, 0), wood)
	MeshKit.box(self, Vector3(W + 0.03, 0.04, D + 0.03), Vector3(0, 0.02, 0), dark)
	# iron corner posts, vertical bands with rivets, side handles
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			MeshKit.box(self, Vector3(0.06, H + 0.01, 0.06), Vector3(x * (W * 0.5 - 0.02), H * 0.5, z * (D * 0.5 - 0.02)), iron)
	for bx in [-0.3, 0.3]:
		for side in [-1.0, 1.0]:
			MeshKit.box(self, Vector3(0.07, H, 0.012), Vector3(bx, H * 0.5, side * (D * 0.5 + 0.004)), iron)
			for k in 3:
				MeshKit.sphere(self, 0.011, Vector3(bx, 0.08 + k * 0.18, side * (D * 0.5 + 0.012)), iron)
	for side in [-1.0, 1.0]:
		var handle := TorusMesh.new()
		handle.inner_radius = 0.05
		handle.outer_radius = 0.068
		handle.rings = 14
		handle.ring_segments = 6
		MeshKit.inst(self, handle, Vector3(side * (W * 0.5 + 0.03), H * 0.62, 0), iron, Vector3(0, 0, 90))
		MeshKit.box(self, Vector3(0.012, 0.09, 0.12), Vector3(side * (W * 0.5 + 0.006), H * 0.72, 0), iron)
	# lock plate with keyhole
	MeshKit.box(self, Vector3(0.14, 0.17, 0.02), Vector3(0, H - 0.1, D * 0.5 + 0.012), brass)
	MeshKit.box(self, Vector3(0.022, 0.05, 0.01), Vector3(0, H - 0.11, D * 0.5 + 0.024), MeshKit.mat(Color(0.03, 0.03, 0.03)))
	# gold heaped inside (seen once the lid is open)
	var heap := MeshKit.sphere(self, 0.42, Vector3(0, H * 0.55, 0), MeshKit.mat(Color(0.85, 0.65, 0.22), 0.45, 0.7), Vector3(1.15, 0.28, 0.7))
	heap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# rounded lid: planks around a half cylinder, hinged at the back
	_lid = Node3D.new()
	_lid.position = Vector3(0, H, -D * 0.5)
	add_child(_lid)
	var segs := 7
	var r := D * 0.5
	# planks laid on a true half circle (each plank is tangent to the arc)
	var plank_w := 2.0 * r * sin(PI / segs * 0.5) + 0.004
	for i in segs:
		var a := PI * (i + 0.5) / segs
		var p := Vector3(0, sin(a) * r, D * 0.5 - cos(a) * r)
		MeshKit.box(_lid, Vector3(W, 0.035, plank_w), p, wood, Vector3(rad_to_deg(a) - 90.0, 0, 0))
	# half-disc end caps
	for x in [-W * 0.5 + 0.02, W * 0.5 - 0.02]:
		var cap := SphereMesh.new()
		cap.radius = r
		cap.height = r
		cap.is_hemisphere = true
		cap.radial_segments = 16
		cap.rings = 6
		var ci := MeshKit.inst(_lid, cap, Vector3(x, 0, D * 0.5), dark)
		ci.scale = Vector3(0.04 / r, 1, 1)
	for bx in [-0.3, 0.3, -W * 0.5 + 0.03, W * 0.5 - 0.03]:
		for i in segs:
			var a := PI * (i + 0.5) / segs
			var p := Vector3(bx, sin(a) * (r + 0.02), D * 0.5 - cos(a) * (r + 0.02))
			MeshKit.box(_lid, Vector3(0.07, 0.012, plank_w + 0.01), p, iron, Vector3(rad_to_deg(a) - 90.0, 0, 0))
			if i % 2 == 0:
				MeshKit.sphere(_lid, 0.01, p + Vector3(0, sin(a), -cos(a)) * 0.008, iron)

	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.8, 0.4)
	_glow.light_energy = 0.0
	_glow.omni_range = 4.0
	_glow.position = Vector3(0, 0.9, 0)
	add_child(_glow)


func prompt() -> String:
	return Loc.t("Open treasure chest")


func interact() -> void:
	if _opened:
		return
	_opened = true
	remove_from_group("interactables")
	Game.play_sound("chest_latch", global_position, -2.0)
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func() -> void: Game.play_sound("chest", global_position, 0.0, 0.85))
	# lid: a small jolt, then swings open with a slight bounce
	tw.tween_property(_lid, "rotation_degrees:x", -12.0, 0.12)
	tw.tween_property(_lid, "rotation_degrees:x", -8.0, 0.1)
	tw.tween_property(_lid, "rotation_degrees:x", -112.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_glow, "light_energy", 1.1, 0.6)
	tw.tween_callback(_release_loot)
	tw.tween_property(_glow, "light_energy", 0.35, 1.5)


func _release_loot() -> void:
	Fx.burst(world, global_position + Vector3(0, 0.7, 0), Color(1.0, 0.85, 0.3), 50, 3.5, 0.035, 1.2, 2.5)
	var zl: Vector2i = Game.ZONE_LEVELS[Game.level_index]
	var lvl := randi_range(zl.x, zl.y)
	var xp := int(Skills.kill_xp(lvl, 100.0, true, false) * 0.8)
	var gold := randi_range(15, 30) * lvl
	var ammo := 30 * randi_range(1, 2)
	var loot := [["coins", Loc.t("Gold coins") + "  (+%d)" % gold], ["ammo", Loc.t("Ammunition") + "  (+%d)" % ammo]]
	if randf() < 0.6:
		loot.append(["potion", Loc.t("Mana potion")])
	# one or two items lie in the chest
	for i in (2 if randf() < 0.3 else 1):
		var it := Items.generate(lvl, Items.roll_quality(1.0, 1))
		LootDrop.spawn(world, global_position + global_transform.basis.z * 1.2 + Vector3(randf_range(-0.6, 0.6), 0, 0), it)
		loot.append(["item", Items.display_name(it)])
	world.player.add_xp(xp)
	var p: Player = world.player
	for i in loot.size():
		var kind: String = loot[i][0]
		if kind == "item":
			continue
		var item := _loot_visual(kind)
		world.add_child(item)
		item.global_position = global_position + Vector3(0, 0.7, 0)
		var up := item.global_position + Vector3(randf_range(-0.6, 0.6), 1.2 + i * 0.25, randf_range(-0.6, 0.6))
		var tw := item.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(item, "global_position", up, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(item, "rotation:y", TAU, 0.6)
		tw.tween_method(func(t: float) -> void:
			if is_instance_valid(p):
				item.global_position = up.lerp(p.global_position + Vector3(0, 1.2, 0), t * t)
				item.scale = Vector3.ONE * (1.0 - t * 0.7), 0.0, 1.0, 0.45)
		tw.tween_callback(func() -> void:
			match kind:
				"coins":
					Game.play_sound("pickup_coins", null, -2.0)
					p.add_gold(gold, true)
				"ammo":
					Game.play_sound("pickup_ammo", null, -4.0)
					p.add_ammo_silent(ammo)
				"potion":
					Game.play_sound("potion", null, -4.0)
					p.mana = p.max_mana
			item.queue_free())
	var lines := []
	for l in loot:
		lines.append(l[1])
	world.hud.show_loot(Loc.t("Treasure Chest"), lines)


func _loot_visual(kind: String) -> Node3D:
	var n := Node3D.new()
	match kind:
		"coins":
			var gold := MeshKit.mat(Color(1.0, 0.8, 0.28), 0.25, 0.95)
			for i in 6:
				MeshKit.cyl(n, 0.07, 0.07, 0.016, Vector3(randf_range(-0.02, 0.02), i * 0.018, randf_range(-0.02, 0.02)), gold, Vector3.ZERO, 14)
			MeshKit.cyl(n, 0.07, 0.07, 0.016, Vector3(0.12, 0.04, 0.0), gold, Vector3(70, 0, 0), 14)
		"ammo":
			MeshKit.box(n, Vector3(0.26, 0.14, 0.16), Vector3.ZERO, MeshKit.mat(Color(0.25, 0.3, 0.2), 0.7))
			MeshKit.box(n, Vector3(0.27, 0.03, 0.17), Vector3(0, 0.06, 0), MeshKit.mat(Color(0.15, 0.17, 0.12), 0.6))
			for i in 4:
				MeshKit.cyl(n, 0.012, 0.012, 0.06, Vector3(-0.08 + i * 0.05, 0.1, 0), MeshKit.mat(Color(0.85, 0.65, 0.25), 0.3, 0.9), Vector3.ZERO, 6)
		"potion":
			MeshKit.sphere(n, 0.08, Vector3.ZERO, MeshKit.mat(Color(0.3, 0.5, 1.0), 0.1, 0.0, 1.5))
			MeshKit.cyl(n, 0.025, 0.03, 0.08, Vector3(0, 0.1, 0), MeshKit.mat(Color(0.7, 0.85, 1.0), 0.1))
			MeshKit.cyl(n, 0.028, 0.028, 0.03, Vector3(0, 0.15, 0), MeshKit.mat(Color(0.45, 0.3, 0.18)))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.4)
	l.light_energy = 0.8
	l.omni_range = 1.5
	n.add_child(l)
	return n
