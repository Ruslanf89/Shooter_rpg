class_name QuestManager
extends Node
## Quest state for the current location. Quest types:
##   kill    - kill `count` enemies of `target` (type or array of types) while active
##   collect - enemies of `target` drop `item` (chance) while active; pick up `count`
##   gather  - glowing `item`s appear at `spots` while active; pick up `count`
##   boss    - spawns `target` at `boss_pos` on accept; kill it
##   deliver - carry `item` to npc `to` (that npc completes it)
## Statuses: locked -> available -> active -> ready -> done.

signal changed

var world: Node
var defs: Array = []
var state: Dictionary = {}
var npcs: Dictionary = {}       # npc id -> QuestGiver
var tracked := ""               # quest the waypoint follows (last accepted)
static var _dialogue: Dictionary

const ENDING_QUEST := "sc_bones"

## One quest per location ends with the locals teaching you their magic (quest id -> skill).
const LESSONS := {"nv_letter": "heal", "dw_charm": "frostbite", "gf_flour": "fireball",
	"fp_supplies": "frost_nova", "ec_report": "meteor", "sc_lamp": "chain_lightning"}


static func dialogue() -> Dictionary:
	if _dialogue.is_empty():
		var f := FileAccess.open("res://data/dialogue.json", FileAccess.READ)
		if f:
			_dialogue = JSON.parse_string(f.get_as_text())
	return _dialogue


static func line_text(line_id: String) -> String:
	var lines: Dictionary = dialogue().get("lines", {})
	return lines[line_id][1] if lines.has(line_id) else "..."


## English translation for lines written in another language (or "").
static func line_translation(line_id: String) -> String:
	var lines: Dictionary = dialogue().get("lines", {})
	if lines.has(line_id) and lines[line_id].size() > 2:
		return lines[line_id][2]
	return ""


func setup(w: Node, quest_defs: Array) -> void:
	world = w
	defs = quest_defs
	# progress in this location is kept between visits (Game.loc_state)
	var saved: Dictionary = Game.loc_state()["quests"]
	for q in defs:
		state[q["id"]] = {"status": "locked", "progress": 0}
		if saved.has(q["id"]):
			state[q["id"]] = {"status": str(saved[q["id"]].get("status", "locked")), "progress": int(saved[q["id"]].get("progress", 0))}
	changed.connect(_store)
	_update_unlocks()
	_respawn_active.call_deferred()


func _store() -> void:
	Game.loc_state()["quests"] = state.duplicate(true)


## Coming back to a location: bosses and quest items of quests still in progress are back.
func _respawn_active() -> void:
	for q in defs:
		var s: Dictionary = state[q["id"]]
		if s["status"] != "active":
			continue
		match q["type"]:
			"boss":
				world.spawn_boss(q["target"], q["boss_pos"])
			"gather":
				var spots: Array = q["spots"]
				for i in range(int(s["progress"]), spots.size()):
					world.spawn_gather_item(q["id"], q["item"], spots[i])


func get_def(id: String) -> Dictionary:
	for q in defs:
		if q["id"] == id:
			return q
	return {}


func status(id: String) -> String:
	return state[id]["status"]


func _update_unlocks() -> void:
	for q in defs:
		if state[q["id"]]["status"] != "locked":
			continue
		var ok := true
		for r in q.get("requires", []):
			if state[r]["status"] != "done":
				ok = false
		if ok:
			state[q["id"]]["status"] = "available"
	changed.emit()


## Who completes a quest: the giver, or the delivery target.
func turn_in_npc(q: Dictionary) -> String:
	return q.get("to", q["giver"]) if q["type"] == "deliver" else q["giver"]


func ready_for(npc_id: String) -> Dictionary:
	for q in defs:
		if state[q["id"]]["status"] == "ready" and turn_in_npc(q) == npc_id:
			return q
	return {}


func available_for(npc_id: String) -> Dictionary:
	for q in defs:
		if state[q["id"]]["status"] == "available" and q["giver"] == npc_id:
			return q
	return {}


func active_for(npc_id: String) -> Dictionary:
	for q in defs:
		if state[q["id"]]["status"] == "active" and q["giver"] == npc_id:
			return q
	return {}


## Marker shown over an NPC: "!" quest available, "?" ready to turn in, "." in progress.
func marker_for(npc_id: String) -> String:
	if not ready_for(npc_id).is_empty():
		return "?"
	var jm: String = world.journey.marker_for(npc_id) if world.journey else ""
	if jm == "?":
		return "?"
	if not available_for(npc_id).is_empty() or jm == "!":
		return "!"
	if not active_for(npc_id).is_empty():
		return "."
	return ""


func accept(id: String) -> void:
	var q := get_def(id)
	state[id]["status"] = "active"
	state[id]["progress"] = 0
	tracked = id
	Game.journey.erase("tracked")
	Game.play_sound("quest_accept", null, -4.0)
	world.hud.show_message(Loc.t("Quest accepted: %s") % Loc.t(q["title"]), Color(1.0, 0.85, 0.4), 2.5)
	match q["type"]:
		"boss":
			world.spawn_boss(q["target"], q["boss_pos"])
		"gather":
			for p: Vector3 in q["spots"]:
				world.spawn_gather_item(id, q["item"], p)
		"deliver":
			state[id]["status"] = "ready"
			state[id]["progress"] = 1
	changed.emit()


func complete(id: String) -> void:
	var q := get_def(id)
	state[id]["status"] = "done"
	world.clear_gather_items(id)
	var xp: int = int(q.get("xp", 200) * pow(Game.level_index + 1, 1.7))
	world.player.add_gold(int(25 * pow(Game.level_index + 1, 1.5)), true)
	world.player.add_xp(xp)
	world.player.add_ammo_silent(q.get("ammo", 30))
	world.player.mana = world.player.max_mana
	Game.stinger("complete")
	world.hud.show_quest_complete(q["title"], xp)
	world.hero_t = maxf(world.hero_t, 300.0)
	if LESSONS.has(id):
		var teacher := turn_in_npc(q)
		var tname: String = Loc.t(npcs[teacher].display_name) if npcs.has(teacher) else teacher
		world.player.teach.call_deferred(LESSONS[id], tname)
	_update_unlocks()
	if id == "vesper_drone" and not Game.flags.get("portal", false):
		Game.flags["portal"] = true
		world.portal_unlocked()
	if id == ENDING_QUEST:
		# the story ends here: VesPer tells his story at the lighthouse
		world.start_ending()
	elif all_done():
		world.location_complete()


func all_done() -> bool:
	for q in defs:
		if state[q["id"]]["status"] != "done":
			return false
	return true


func done_count() -> int:
	var n := 0
	for q in defs:
		if state[q["id"]]["status"] == "done":
			n += 1
	return n


func _matches(q: Dictionary, type: String) -> bool:
	var t = q["target"]
	return t == type if t is String else type in t


func _advance(id: String, amount := 1) -> void:
	var q := get_def(id)
	var s: Dictionary = state[id]
	if s["status"] != "active":
		return
	s["progress"] = mini(int(q.get("count", 1)), s["progress"] + amount)
	var label := "%s: %d / %d" % [Loc.t(q.get("item", q.get("label", "Progress"))), s["progress"], q.get("count", 1)]
	world.hud.show_message(label, Color(1.0, 0.9, 0.55), 1.5)
	if s["progress"] >= int(q.get("count", 1)):
		s["status"] = "ready"
		Game.play_sound("quest_progress", null, -4.0, 1.2)
		var npc: QuestGiver = npcs.get(turn_in_npc(q))
		world.hud.show_message(Loc.t("%s complete! Return to %s") % [q["title"], npc.display_name if npc else "the quest giver"], Color(1.0, 0.85, 0.3), 3.0)
	changed.emit()


func on_enemy_killed(e: Enemy) -> void:
	for q in defs:
		if state[q["id"]]["status"] != "active":
			continue
		match q["type"]:
			"kill", "boss":
				if _matches(q, e.type):
					_advance(q["id"])
			"collect":
				if _matches(q, e.type) and randf() < float(q.get("chance", 0.6)):
					world.spawn_gather_item(q["id"], q["item"], Vector3(e.global_position.x + randf_range(-0.6, 0.6), 0, e.global_position.z + randf_range(-0.6, 0.6)))


func on_item_gathered(quest_id: String) -> void:
	_advance(quest_id)


## Lines for the quest log: [title, detail, is_ready].
func log_entries() -> Array:
	var out := []
	for q in defs:
		var s: Dictionary = state[q["id"]]
		if s["status"] == "active" or s["status"] == "ready":
			var detail := ""
			if s["status"] == "ready":
				var npc: QuestGiver = npcs.get(turn_in_npc(q))
				detail = (Loc.t("Deliver to %s") if q["type"] == "deliver" else Loc.t("Return to %s")) % (npc.display_name if npc else "?")
			else:
				detail = "%s  %d / %d" % [Loc.t(q.get("item", q.get("label", ""))), s["progress"], q.get("count", 1)]
			out.append([q["title"], detail, s["status"] == "ready"])
	if world.journey:
		out += world.journey.log_entries()
	return out


## Where the quest waypoint points: {"pos": Vector3, "label": String} or {} when there is nothing.
## Follows the last accepted quest; without an active quest it points to the nearest "!" NPC.
func objective_target(from: Vector3) -> Dictionary:
	if world.journey:
		var jt: Dictionary = world.journey.objective_target(from)
		if not jt.is_empty():
			return jt
	var order := []
	if state.has(tracked) and state[tracked]["status"] in ["active", "ready"]:
		order.append(get_def(tracked))
	for q in defs:
		if state[q["id"]]["status"] in ["active", "ready"] and q["id"] != tracked:
			order.append(q)
	for q: Dictionary in order:
		var s: Dictionary = state[q["id"]]
		if s["status"] == "ready":
			var npc: QuestGiver = npcs.get(turn_in_npc(q))
			if npc:
				return {"pos": npc.global_position + Vector3(0, 2.2, 0), "label": "%s: %s" % [Loc.t(q["title"]), npc.display_name]}
			continue
		var best := {}
		var best_d := INF
		# quest items lying around (gathered objects and enemy drops) come first
		for g in world.get_tree().get_nodes_in_group("gather_items"):
			if g.quest_id == q["id"] and not g.is_queued_for_deletion():
				var d: float = from.distance_to(g.global_position)
				if d < best_d:
					best_d = d
					best = {"pos": g.global_position + Vector3(0, 1.0, 0), "label": "%s: %s" % [Loc.t(q["title"]), Loc.t(q["item"])]}
		if best.is_empty() and q["type"] in ["kill", "collect", "boss"]:
			for e in world.get_tree().get_nodes_in_group("enemies"):
				if _matches(q, e.type) and (q["type"] != "boss" or e.boss):
					var d: float = from.distance_to(e.global_position)
					if d < best_d:
						best_d = d
						best = {"pos": e.global_position + Vector3(0, 2.0, 0), "label": "%s: %s" % [Loc.t(q["title"]), e.display_name]}
		if not best.is_empty():
			return best
	if world.event_target != Vector3.INF:
		return {"pos": world.event_target + Vector3(0, 2.0, 0), "label": Loc.t("Event")}
	var best_npc := {}
	var nd := INF
	for id in npcs:
		var npc: QuestGiver = npcs[id]
		if marker_for(id) in ["!", "?"]:
			var d: float = from.distance_to(npc.global_position)
			if d < nd:
				nd = d
				best_npc = {"pos": npc.global_position + Vector3(0, 2.2, 0), "label": Loc.t("New quest: %s") % npc.display_name}
	return best_npc