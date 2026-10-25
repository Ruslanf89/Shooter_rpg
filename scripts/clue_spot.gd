class_name ClueSpot
extends Node3D
## Something you can look at closely (F): a disturbed grave, a stain, a page, a cabinet of records.
## Shows its note (title + text from the level story), may play the soldier's thought, sets story
## flags and counts for the quest step that asked for it. Quest clues glint faintly so they can be
## found; optional ones (`subtle`) only show their prompt when you are close.

var world: Node
var story: Story
var clue_id := ""
var quest_id := ""             # "" for optional clues that are always there
var def: Dictionary = {}       # from the story: title, text, line, flag, needs, needs_text, once
var subtle := false
var _glint: CPUParticles3D
var _done := false


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("clues")
	if not subtle:
		_glint = CPUParticles3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.02
		sm.height = 0.04
		sm.radial_segments = 4
		sm.rings = 2
		sm.material = MeshKit.unshaded(Color(1.0, 0.92, 0.65))
		_glint.mesh = sm
		_glint.amount = 6
		_glint.lifetime = 1.6
		_glint.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_glint.emission_sphere_radius = 0.35
		_glint.gravity = Vector3(0, 0.25, 0)
		_glint.initial_velocity_min = 0.0
		_glint.initial_velocity_max = 0.1
		_glint.position.y = 0.3
		add_child(_glint)


func prompt() -> String:
	return Loc.t("Inspect: %s") % Loc.t(def.get("title", "Clue"))


func interact() -> void:
	if _done:
		return
	var needs: String = def.get("needs", "")
	if needs != "" and not story.check(needs):
		world.hud.show_message(Loc.t(def.get("needs_text", "You can't do that yet.")), Color(1.0, 0.8, 0.55), 2.5)
		Game.play_sound("door_locked" if Game.sounds.has("door_locked") else "pickup_item", null, -6.0, 0.8)
		return
	story.show_clue(clue_id)
	if quest_id != "":
		_done = true
		world.quests.on_clue(quest_id, clue_id)
		queue_free()
	elif def.get("once", false):
		_done = true
		remove_from_group("interactables")
		if _glint:
			_glint.emitting = false
