extends Node
## EDITOR TOOL. Open scenes/editor/make_reference.tscn and press F6 (Run Current Scene).
## For every location it builds the level like the game does, then saves a snapshot of the
## generated terrain, buildings, trees, roads and NPC spots to
##   scenes/levels/reference/<level>_reference.scn
## and creates scenes/levels/<level>_extra.tscn (only if it doesn't exist yet - your edits are
## never overwritten). Open an extras scene to place your own things against the reference.
## Run it again after changing a level script to refresh the reference.

const SKIP := ["Enemy", "Villager", "Animal", "Player", "QuestGiver", "LootDrop", "GatherItem", "ExtraRoot", "AdminPanel", "Projectile"]

var _status: Label


func _ready() -> void:
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 28)
	_status.position = Vector2(40, 40)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	layer.add_child(_status)
	Game.settings["cutscenes"] = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/levels/reference"))
	var only := OS.get_environment("REF_LEVEL")
	for i in Game.LEVELS.size():
		if only != "" and int(only) != i:
			continue
		await _make(i)
	_status.text = "Done! References saved in scenes/levels/reference/.\nOpen scenes/levels/<level>_extra.tscn to edit. You can close this window."
	print("REFERENCE_DONE")
	if OS.has_environment("REF_QUIT"):
		get_tree().quit()


func _make(i: int) -> void:
	var info: Dictionary = Game.LEVELS[i]
	var id: String = str(info["script"]).get_file().get_basename()
	_status.text = "Building %s (%d / %d)..." % [info["name"], i + 1, Game.LEVELS.size()]
	await get_tree().process_frame
	Game.start_game_state()
	Game.level_index = i
	var world: Node3D = load(Game.WORLD_SCENE).instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	_status.text = "Saving %s..." % info["name"]
	await get_tree().process_frame

	var root := Node3D.new()
	root.name = "Reference_" + id
	var count := _copy(world, world, root)
	# sun so the snapshot is lit in the editor
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, -40, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	# landmark names, NPCs and the player start, floating above the map
	for lm in world.landmarks:
		var lp: Vector2 = lm["pos"]
		_label(root, str(lm["name"]), Vector3(lp.x, world.ground(lp.x, lp.y) + 18.0, lp.y), Color(1.0, 0.9, 0.5), 0.06)
	for n in world.get_tree().get_nodes_in_group("npcs"):
		_label(root, "NPC: " + str(n.display_name), n.global_position + Vector3(0, 3.0, 0), Color(0.5, 1.0, 0.5), 0.02)
		_marker(root, n.global_position, Color(0.3, 1.0, 0.3))
	var start: Vector3 = world.cfg["player_start"]
	start.y = world.ground(start.x, start.z)
	_label(root, "PLAYER START", start + Vector3(0, 4.0, 0), Color(0.5, 0.8, 1.0), 0.03)
	_marker(root, start, Color(0.3, 0.6, 1.0))
	_set_owner(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	var ref_path := "res://scenes/levels/reference/%s_reference.scn" % id
	var err := ResourceSaver.save(packed, ref_path, ResourceSaver.FLAG_COMPRESS)
	print("REFERENCE %s nodes=%d err=%d" % [id, count, err])
	root.free()
	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_make_extra_scene(id, ref_path)


func _skip(n: Node) -> bool:
	if n is CanvasLayer or n is Light3D or n is CPUParticles3D or n is GPUParticles3D or n is Camera3D or n is OccluderInstance3D:
		return true
	var sc = n.get_script()
	if sc and str(sc.get_global_name()) in SKIP:
		return true
	return false


func _copy(n: Node, world: Node3D, root: Node3D) -> int:
	var count := 0
	for c in n.get_children():
		if _skip(c):
			continue
		if c is MeshInstance3D and (c as MeshInstance3D).mesh and (c as MeshInstance3D).is_visible_in_tree() and not (c as MeshInstance3D).mesh is ImmediateMesh:
			var src := c as MeshInstance3D
			var mi := MeshInstance3D.new()
			mi.mesh = src.mesh
			mi.material_override = src.material_override
			for s in src.mesh.get_surface_count():
				var om := src.get_surface_override_material(s)
				if om:
					mi.set_surface_override_material(s, om)
			mi.transform = src.global_transform
			mi.cast_shadow = src.cast_shadow
			root.add_child(mi)
			count += 1
		elif c is MultiMeshInstance3D and not n is Terrain:
			var src := c as MultiMeshInstance3D
			var mm := MultiMeshInstance3D.new()
			mm.multimesh = src.multimesh
			mm.material_override = src.material_override
			mm.transform = src.global_transform
			root.add_child(mm)
			count += 1
		elif c is Label3D:
			var l := (c as Label3D).duplicate(0) as Label3D
			l.transform = (c as Label3D).global_transform
			root.add_child(l)
		count += _copy(c, world, root)
	return count


func _label(root: Node3D, text: String, pos: Vector3, color: Color, size: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 96
	l.pixel_size = size
	l.outline_size = 16
	l.modulate = color
	l.no_depth_test = true
	l.position = pos
	root.add_child(l)


func _marker(root: Node3D, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 2.0
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.position = pos + Vector3(0, 1.0, 0)
	root.add_child(mi)


func _set_owner(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_set_owner(c, owner_node)


## Creates the extras scene for a level if it doesn't exist (never overwrites your edits).
func _make_extra_scene(id: String, ref_path: String) -> void:
	var path := "res://scenes/levels/%s_extra.tscn" % id
	if ResourceLoader.exists(path):
		return
	var root := ExtraRoot.new()
	root.name = id.capitalize().replace(" ", "") + "Extras"
	root.reference_scene = ref_path
	var example := ExtraProp.new()
	example.name = "ExampleLantern_DeleteMe"
	example.kind = "lantern"
	var info: Dictionary = {}
	for l in Game.LEVELS:
		if str(l["script"]).get_file().get_basename() == id:
			info = l
	var start: Vector3 = (load(info["script"]).new()).config()["player_start"]
	example.position = start + Vector3(3, 0, -4)
	root.add_child(example)
	example.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, path)
	root.free()
	print("EXTRA_SCENE created ", path)
