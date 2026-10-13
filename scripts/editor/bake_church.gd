extends Node
## Open scenes/editor/bake_church.tscn and press F6 (Run Current Scene): it builds the abbey church
## from code (scripts/gothic_church.gd) as named, separately editable parts and saves it to
## scenes/buildings/abbey_church.scn, which the game then uses instead of building it from code.
## It never overwrites your edited church: delete abbey_church.scn first to start over from code.


func _ready() -> void:
	var path := GothicChurch.SCENE
	if ResourceLoader.exists(path):
		print("BAKE: %s already exists - not overwriting your edits. Delete it first to rebuild the church from code." % path)
		get_tree().quit()
		return
	var root := Node3D.new()
	root.name = "AbbeyChurch"
	root.set_script(load("res://scripts/abbey_church.gd"))
	GothicChurch.build(root, true)
	_own(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		err = ResourceSaver.save(packed, path, ResourceSaver.FLAG_COMPRESS)
	print("BAKE: saved %s (%s), %d nodes" % [path, error_string(err), _count(root)])
	root.free()
	get_tree().quit()


func _own(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		_own(c, root)


func _count(n: Node) -> int:
	var k := 1
	for c in n.get_children():
		k += _count(c)
	return k
