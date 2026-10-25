class_name QuestManager
extends Node
## Quest state for the current location.
##
## A quest is either one objective (the old style: the quest itself has a "type") or a list of
## "steps" done in order. Objective types:
##   kill       - kill `count` enemies of `target` (type or array of types)
##   collect    - enemies of `target` drop `item` (chance) while active; pick up `count`
##   gather     - glowing items appear at `spots` (Vector3, or {"pos", "item", "note"}); pick them up
##   boss       - spawns `target` at `boss_pos` / `pos`; kill it
##   deliver    - carry `item` to npc `to` (that npc completes it)
##   goto       - reach `pos` (within `radius`)
##   talk       - talk to `npc` (the conversation `convo` ends the step)
##   inspect    - look at the clue spots `clues` (ids; texts and places come from the level story)
##   shoot      - shoot the practice targets at `targets`
##   spawn_kill - the enemies in `spawn` ([{"type", "pos", "name"}]) appear; kill them all
## After the last step the quest is "ready": go back to `turn_in` (default: the giver, or `to` for
## deliveries). Statuses: locked -> available -> active -> ready -> done.
## Optional: "reward" {"gold", "ammo", "consumables": {id: n}, "gadgets": {...}, "materials": {...},
## "item": [kind, base, quality]}, "flags" (set when done), "portal" (VesPer builds his portals).

signal changed

var world: Node
var defs: Array = []
var state: Dictionary = {}
var npcs: Dictionary = {}       # npc id -> QuestGiver
var tracked := ""               # quest the waypoint follows (last accepted)
static var _dialogue: Dictionary
var _step_nodes: Dictionary = {}   # quest id -> nodes spawned for its current step
var _goto_t := 0.0

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
		state[q["id"]] = {"status": "locked", "progress": 0, "step": 0, "found": []}
		if saved.has(q["id"]):
			var s: Dictionary = saved[q["id"]]
			state[q["id"]] = {"status": str(s.get("status", "locked")), "progress": int(s.get("progress", 0)),
				"step": int(s.get("step", 0)), "found": (s.get("found", []) as Array).duplicate()}
	changed.connect(_store)
	_update_unlocks()
	_respawn_active.call_deferred()


func _store() -> void:
	Game.loc_state()["quests"] = state.duplicate(true)


## Coming back to a location: what the current step of each quest in progress needs is back.
func _respawn_active() -> void:
	for q in defs:
		if state[q["id"]]["status"] == "active":
			_enter_step(q["id"])


func get_def(id: String) -> Dictionary:
	for q in defs:
		if q["id"] == id:
			return q
	return {}


func status(id: String) -> String:
	return state[id]["status"] if state.has(id) else ""


# --------------------------------------------------------------------------- steps

func steps_of(q: Dictionary) -> Array:
	return q["steps"] if q.has("steps") else [q]


func step_index(id: String) -> int:
	return int(state[id].get("step", 0))


## The objective the quest is on now ({} when it has none left).
func current_step(id: String) -> Dictionary:
	var q := get_def(id)
	if q.is_empty():
		return {}
	var st := steps_of(q)
	var i := step_index(id)
	return st[i] if i < st.size() else {}


func _spots(stp: Dictionary) -> Array:
	var out := []
	for s in stp.get("spots", []):
		out.append(s if s is Dictionary else {"pos": s})
	return out


func step_count(stp: Dictionary) -> int:
	match stp.get("type", ""):
		"gather":
			return int(stp.get("count", _spots(stp).size()))
		"inspect":
			return (stp.get("clues", []) as Array).size()
		"shoot":
			return (stp.get("targets", []) as Array).size()
		"spawn_kill":
			return (stp.get("spawn", []) as Array).size()
		"kill", "collect":
			return int(stp.get("count", 1))
	return 1


## Words for the log / progress messages.
func step_label(stp: Dictionary) -> String:
	if stp.has("label"):
		return Loc.t(stp["label"])
	match stp.get("type", ""):
		"gather", "collect":
			return Loc.t(stp.get("item", "Items"))
		"talk":
			var npc: QuestGiver = npcs.get(stp.get("npc", ""))
			return Loc.t("Talk to %s") % (npc.display_name if npc else stp.get("npc", "?"))
		"goto":
			return Loc.t("Go to the marked place")
		"shoot":
			return Loc.t("Targets hit")
		"inspect":
			return Loc.t("Clues found")
	return Loc.t("Progress")


## Spawns what the current step needs (items, targets, clue spots, enemies).
func _enter_step(id: String) -> void:
	_clear_step(id)
	var stp := current_step(id)
	var s: Dictionary = state[id]
	var found: Array = s.get("found", [])
	var nodes: Array = []
	match stp.get("type", ""):
		"boss":
			world.spawn_boss(stp["target"], stp.get("boss_pos", stp.get("pos", Vector3.ZERO)))
		"gather":
			var sp := _spots(stp)
			for i in sp.size():
				if i in found:
					continue
				var g = world.spawn_gather_item(id, sp[i].get("item", stp.get("item", "Item")), sp[i]["pos"])
				if g:
					g.set_meta("spot", i)
					if sp[i].has("note"):
						g.set_meta("note", sp[i]["note"])
		"shoot":
			var tg: Array = stp["targets"]
			for i in tg.size():
				if i in found:
					continue
				var t := PracticeTarget.new()
				t.world = world
				t.quest_id = id
				t.index = i
				world.add_child(t)
				var p: Vector3 = tg[i]
				t.global_position = Vector3(p.x, world.ground(p.x, p.z), p.z)
				t.face(stp.get("face", Vector3.ZERO))
				nodes.append(t)
		"inspect":
			for cid in stp["clues"]:
				if cid in found:
					continue
				var c: Node = world.spawn_clue(cid, id) if world.has_method("spawn_clue") else null
				if c:
					nodes.append(c)
		"spawn_kill":
			var sp: Array = stp["spawn"]
			for i in range(int(s["progress"]), sp.size()):
				var e: Enemy = world.spawn_quest_enemy(sp[i], id)
				if e:
					nodes.append(e)
		"deliver":
			s["status"] = "ready"
			s["progress"] = 1
	_step_nodes[id] = nodes
	if world.get("story") and world.story:
		world.story.on_step(id, step_index(id))


func _clear_step(id: String) -> void:
	world.clear_gather_items(id)
	for n in _step_nodes.get(id, []):
		# quest enemies stay where they are (alive ones keep fighting, dead ones fall as usual)
		if is_instance_valid(n) and not n is Enemy and not n is PracticeTarget:
			n.queue_free()
	_step_nodes.erase(id)


func _next_step(id: String) -> void:
	var q := get_def(id)
	var s: Dictionary = state[id]
	_clear_step(id)
	s["step"] = step_index(id) + 1
	s["progress"] = 0
	s["found"] = []
	if step_index(id) >= steps_of(q).size():
		s["status"] = "ready"
		Game.play_sound("quest_progress", null, -4.0, 1.2)
		var npc: QuestGiver = npcs.get(turn_in_npc(q))
		world.hud.show_message(Loc.t("%s complete! Return to %s") % [Loc.t(q["title"]), npc.display_name if npc else Loc.t("the quest giver")], Color(1.0, 0.85, 0.3), 3.0)
		if world.get("story") and world.story:
			world.story.on_step(id, step_index(id))
	else:
		Game.play_sound("quest_progress", null, -6.0, 1.0)
		var nxt := current_step(id)
		world.hud.show_message(Loc.t("New objective: %s") % step_label(nxt), Color(1.0, 0.9, 0.55), 3.0)
		_enter_step(id)
	changed.emit()


# --------------------------------------------------------------------------- unlocks / givers

func _update_unlocks() -> void:
	for q in defs:
		if state[q["id"]]["status"] != "locked":
			continue
		var ok := true
		for r in q.get("requires", []):
			if not state.has(r) or state[r]["status"] != "done":
				ok = false
		if ok and q.has("if") and world.get("story") and world.story:
			ok = world.story.check(q["if"])
		if ok:
			state[q["id"]]["status"] = "available"
			if q.get("auto", false):
				accept.call_deferred(q["id"])
	changed.emit()


## Who completes a quest: "turn_in", the delivery target, or the giver.
func turn_in_npc(q: Dictionary) -> String:
	if q.has("turn_in"):
		return q["turn_in"]
	return q.get("to", q["giver"]) if q.get("type", "") == "deliver" else q["giver"]


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


## An active quest whose current step is talking to this npc ({} if none).
func talk_step_for(npc_id: String) -> Dictionary:
	for q in defs:
		if state[q["id"]]["status"] != "active":
			continue
		var stp := current_step(q["id"])
		if stp.get("type", "") == "talk" and stp.get("npc", "") == npc_id:
			return q
	return {}


## Marker shown over an NPC: "!" quest available, "?" ready to turn in / talk now, "." in progress.
func marker_for(npc_id: String) -> String:
	if not ready_for(npc_id).is_empty() or not talk_step_for(npc_id).is_empty():
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
	if q.is_empty() or state[id]["status"] != "available":
		return
	state[id]["status"] = "active"
	state[id]["progress"] = 0
	state[id]["step"] = 0
	state[id]["found"] = []
	tracked = id
	Game.journey.erase("tracked")
	Game.play_sound("quest_accept", null, -4.0)
	world.hud.show_message(Loc.t("Quest accepted: %s") % Loc.t(q["title"]), Color(1.0, 0.85, 0.4), 2.5)
	if q.has("hint"):
		var hint: String = Loc.t(q["hint"])
		world.get_tree().create_timer(2.8).timeout.connect(func() -> void:
			if is_instance_valid(world) and world.hud:
				world.hud.show_message(hint, Color(0.85, 0.95, 1.0), 4.5))
	_enter_step(id)
	if world.get("story") and world.story:
		world.story.on_accept(id)
	changed.emit()


func complete(id: String) -> void:
	var q := get_def(id)
	if q.is_empty() or state[id]["status"] == "done":
		return
	state[id]["status"] = "done"
	_clear_step(id)
	var xp: int = int(q.get("xp", 200) * pow(Game.level_index + 1, 1.7))
	var rw: Dictionary = q.get("reward", {})
	world.player.add_gold(int(rw.get("gold", 25) * pow(Game.level_index + 1, 1.5)), true)
	world.player.add_xp(xp)
	world.player.add_ammo_silent(rw.get("ammo", q.get("ammo", 30)))
	world.player.mana = world.player.max_mana
	_give_rewards(q)
	for f in q.get("flags", []):
		Game.flags[f] = true
	Game.stinger("complete")
	world.hud.show_quest_complete(q["title"], xp)
	world.hero_t = maxf(world.hero_t, 300.0)
	var giver := turn_in_npc(q)
	world.ai_villagers_react("react_quest", 2.0)
	Brain.event("quest_done", "The Outsider helped %s with '%s'" % [npcs[giver].display_name if npcs.has(giver) else giver, q["title"]], {"npc": giver, "importance": 2})
	if LESSONS.has(id):
		var teacher := turn_in_npc(q)
		var tname: String = Loc.t(npcs[teacher].display_name) if npcs.has(teacher) else teacher
		world.player.teach.call_deferred(LESSONS[id], tname)
	_update_unlocks()
	if q.get("portal", false) and not Game.flags.get("portal", false):
		Game.flags["portal"] = true
		world.portal_unlocked()
	if world.get("story") and world.story:
		world.story.on_complete(id)
	if id == ENDING_QUEST:
		# the story ends here: VesPer tells his story at the lighthouse
		world.start_ending()
	elif all_done():
		world.location_complete()


## Items, potions, gadgets and materials from a quest (shown in the loot list).
func _give_rewards(q: Dictionary) -> void:
	var rw: Dictionary = q.get("reward", {})
	var lines := []
	for kind in ["consumables", "gadgets"]:
		var pouch := Crafting.pouch(kind)
		var table: Dictionary = Crafting.CONSUMABLES if kind == "consumables" else Crafting.GADGETS
		for k in rw.get(kind, {}):
			var n := int(rw[kind][k])
			pouch[k] = int(pouch.get(k, 0)) + n
			lines.append("%s x%d" % [Loc.t(table[k][0]) if table.has(k) else k, n])
	for k in rw.get("materials", {}):
		var n := int(rw["materials"][k])
		Crafting.add(k, n)
		lines.append("%s x%d" % [Crafting.mat_name(k), n])
	if rw.has("item"):
		var spec: Array = rw["item"]
		var it := Items.generate(world.zone_levels().y, int(spec[2]), spec[0], spec[1])
		if Items.add_to_bag(Game.inventory, it):
			lines.append(Items.display_name(it))
		else:
			lines.append(Loc.t("Bag full - item lost"))
	if not lines.is_empty():
		world.hud.show_loot(Loc.t("Reward"), lines)


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


func _matches(stp: Dictionary, type: String) -> bool:
	var t = stp.get("target", "")
	return t == type if t is String else type in t


func _advance(id: String, amount := 1) -> void:
	var s: Dictionary = state[id]
	if s["status"] != "active":
		return
	var stp := current_step(id)
	var n := step_count(stp)
	s["progress"] = mini(n, int(s["progress"]) + amount)
	if n > 1:
		world.hud.show_message("%s: %d / %d" % [step_label(stp), s["progress"], n], Color(1.0, 0.9, 0.55), 1.5)
	if int(s["progress"]) >= n:
		_next_step(id)
	else:
		changed.emit()


# --------------------------------------------------------------------------- events

func on_enemy_killed(e: Enemy) -> void:
	for q in defs:
		var id: String = q["id"]
		if state[id]["status"] != "active":
			continue
		var stp := current_step(id)
		match stp.get("type", ""):
			"kill", "boss":
				if _matches(stp, e.type) and (stp["type"] != "boss" or e.boss):
					_advance(id)
			"collect":
				if _matches(stp, e.type) and randf() < float(stp.get("chance", 0.6)):
					world.spawn_gather_item(id, stp["item"], Vector3(e.global_position.x + randf_range(-0.6, 0.6), 0, e.global_position.z + randf_range(-0.6, 0.6)))
			"spawn_kill":
				if e.get_meta("quest", "") == id:
					_advance(id)


## A quest item was picked up (`item`: the GatherItem, for gathered spots).
func on_item_gathered(quest_id: String, item: Node = null) -> void:
	if not state.has(quest_id):
		return
	var stp := current_step(quest_id)
	if not stp.get("type", "") in ["gather", "collect"]:
		return
	if item and item.has_meta("spot"):
		(state[quest_id]["found"] as Array).append(int(item.get_meta("spot")))
	if item and item.has_meta("note") and world.get("story") and world.story:
		world.story.show_clue(str(item.get_meta("note")))
	_advance(quest_id)


## A clue spot was inspected.
func on_clue(quest_id: String, clue_id: String) -> void:
	if not state.has(quest_id) or state[quest_id]["status"] != "active":
		return
	var stp := current_step(quest_id)
	if stp.get("type", "") != "inspect" or not clue_id in stp["clues"]:
		return
	var found: Array = state[quest_id]["found"]
	if clue_id in found:
		return
	found.append(clue_id)
	_advance(quest_id)


func on_target_hit(quest_id: String, index: int) -> void:
	if not state.has(quest_id) or state[quest_id]["status"] != "active":
		return
	var found: Array = state[quest_id]["found"]
	if index in found:
		return
	found.append(index)
	_advance(quest_id)


## The conversation of a "talk" step has finished.
func on_talk_step(quest_id: String) -> void:
	if state.has(quest_id) and state[quest_id]["status"] == "active" and current_step(quest_id).get("type", "") == "talk":
		_advance(quest_id)


func _process(delta: float) -> void:
	_goto_t -= delta
	if _goto_t > 0.0 or world == null or world.player == null:
		return
	_goto_t = 0.25
	var pp: Vector3 = world.player.global_position
	for q in defs:
		var id: String = q["id"]
		if state[id]["status"] != "active":
			continue
		var stp := current_step(id)
		if stp.get("type", "") == "goto":
			var p: Vector3 = stp["pos"]
			if Vector2(pp.x - p.x, pp.z - p.z).length() < float(stp.get("radius", 8.0)):
				_advance(id)


# --------------------------------------------------------------------------- log / waypoint

## Lines for the quest log: [title, detail, is_ready].
func log_entries() -> Array:
	var out := []
	for q in defs:
		var s: Dictionary = state[q["id"]]
		if s["status"] == "active" or s["status"] == "ready":
			var detail := ""
			if s["status"] == "ready":
				var npc: QuestGiver = npcs.get(turn_in_npc(q))
				detail = (Loc.t("Deliver to %s") if q.get("type", "") == "deliver" else Loc.t("Return to %s")) % (npc.display_name if npc else "?")
			else:
				var stp := current_step(q["id"])
				var n := step_count(stp)
				detail = step_label(stp) if n <= 1 else "%s  %d / %d" % [step_label(stp), s["progress"], n]
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
		var id: String = q["id"]
		var s: Dictionary = state[id]
		var title := Loc.t(q["title"])
		if s["status"] == "ready":
			var npc: QuestGiver = npcs.get(turn_in_npc(q))
			if npc:
				return {"pos": npc.global_position + Vector3(0, 2.2, 0), "label": "%s: %s" % [title, npc.display_name]}
			continue
		var stp := current_step(id)
		var best := {}
		var best_d := INF
		match stp.get("type", ""):
			"goto":
				var p: Vector3 = stp["pos"]
				return {"pos": Vector3(p.x, world.ground(p.x, p.z) + 2.0, p.z), "label": "%s: %s" % [title, step_label(stp)]}
			"talk":
				var npc: QuestGiver = npcs.get(stp["npc"])
				if npc:
					return {"pos": npc.global_position + Vector3(0, 2.2, 0), "label": "%s: %s" % [title, npc.display_name]}
			"inspect", "shoot", "spawn_kill":
				for n in _step_nodes.get(id, []):
					if is_instance_valid(n) and not n.is_queued_for_deletion() and not (n is Enemy and (n as Enemy).state == Enemy.State.DEAD):
						var d: float = from.distance_to((n as Node3D).global_position)
						if d < best_d:
							best_d = d
							best = {"pos": (n as Node3D).global_position + Vector3(0, 1.6, 0), "label": "%s: %s" % [title, step_label(stp)]}
		# quest items lying around (gathered objects and enemy drops) come first
		for g in world.get_tree().get_nodes_in_group("gather_items"):
			if g.quest_id == id and not g.is_queued_for_deletion():
				var d: float = from.distance_to(g.global_position)
				if d < best_d:
					best_d = d
					best = {"pos": g.global_position + Vector3(0, 1.0, 0), "label": "%s: %s" % [title, Loc.t(g.item)]}
		if best.is_empty() and stp.get("type", "") in ["kill", "collect", "boss"]:
			for e in world.get_tree().get_nodes_in_group("enemies"):
				if _matches(stp, e.type) and (stp["type"] != "boss" or e.boss):
					var d: float = from.distance_to(e.global_position)
					if d < best_d:
						best_d = d
						best = {"pos": e.global_position + Vector3(0, 2.0, 0), "label": "%s: %s" % [title, e.display_name]}
		if not best.is_empty():
			return best
	if world.event_target != Vector3.INF:
		return {"pos": world.event_target + Vector3(0, 2.0, 0), "label": Loc.t("Event")}
	var best_npc := {}
	var nd := INF
	for id in npcs:
		var npc: QuestGiver = npcs[id]
		if not is_instance_valid(npc):
			continue
		if marker_for(id) in ["!", "?"]:
			var d: float = from.distance_to(npc.global_position)
			if d < nd:
				nd = d
				best_npc = {"pos": npc.global_position + Vector3(0, 2.2, 0), "label": Loc.t("New quest: %s") % npc.display_name}
	return best_npc
