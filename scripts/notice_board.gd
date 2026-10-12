class_name NoticeBoard
extends Node3D
## Town notice board: bounties for this location (kill so many of a monster for gold and XP).
## Up to three active bounties; they're paid out as soon as the last one falls.

var world: Node


func _ready() -> void:
	add_to_group("interactables")
	var wood := Props.wood()
	var dark := Props.dark_wood()
	for x in [-1.1, 1.1]:
		MeshKit.static_box(self, Vector3(0.15, 2.6, 0.15), Vector3(x, 1.3, 0), dark)
	MeshKit.box(self, Vector3(2.4, 1.4, 0.08), Vector3(0, 1.6, 0), wood)
	MeshKit.box(self, Vector3(2.7, 0.12, 0.5), Vector3(0, 2.45, 0.05), dark, Vector3(-15, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 13.0 + position.z)
	var paper := MeshKit.mat(Color(0.92, 0.88, 0.75), 0.95)
	for i in 7:
		MeshKit.box(self, Vector3(rng.randf_range(0.35, 0.5), rng.randf_range(0.4, 0.55), 0.01), Vector3(rng.randf_range(-0.9, 0.9), rng.randf_range(1.15, 2.05), 0.05), paper, Vector3(0, 0, rng.randf_range(-8, 8)))
	MeshKit.sphere(self, 0.03, Vector3(-0.6, 1.9, 0.06), MeshKit.mat(Color(0.8, 0.1, 0.1)))
	var l := Label3D.new()
	l.text = Loc.t("BOUNTIES")
	l.font_size = 64
	l.pixel_size = 0.005
	l.modulate = Color(0.25, 0.15, 0.08)
	l.position = Vector3(0, 2.28, 0.06)
	add_child(l)


func prompt() -> String:
	return Loc.t("Read the notice board")


func interact() -> void:
	_show()


func _show() -> void:
	var j: Journey = world.journey
	var offers := j.board_offers()
	var buttons := []
	for i in offers.size():
		var b: Dictionary = offers[i]
		var name: String = Loc.t(Enemy.TYPES[b["target"]]["name"])
		buttons.append([Loc.t("Take: kill %d %s - %d gold") % [int(b["count"]), name, int(b["gold"])], func() -> void:
			j.take_bounty(i)
			_show()])
	buttons.append([Loc.t("Go away"), _close])
	var lines := []
	for b in j.st()["bounties"]:
		lines.append("- %s  %d / %d  (%s)" % [Loc.t(Enemy.TYPES[b["target"]]["name"]), int(b["progress"]), int(b["count"]), Loc.t(Game.LEVELS[int(b["loc"])]["name"])])
	var text := Loc.t("Monsters plague the roads. The town pays for every one you put down.")
	if not lines.is_empty():
		text += "\n\n" + Loc.t("Your bounties:") + "\n" + "\n".join(lines)
	if offers.is_empty():
		text += "\n\n" + Loc.t("No new bounties posted. Come back another time.")
	world.player.input_locked = true
	world.hud.show_dialogue(Loc.t("Notice Board"), Loc.t("Bounties"), "", text, buttons, 0.5)


func _close() -> void:
	world.player.input_locked = false
	world.hud.hide_dialogue()
