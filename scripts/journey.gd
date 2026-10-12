class_name Journey
extends Node
## Travel quests that span several locations (Game.journey keeps their state between visits):
## the King's main line, couriers, an escort and rare-material requests - plus bounties from the
## town notice boards. Steps:
##   talk    - speak to `npc` in location `loc`
##   deliver - carry `item` to `npc` in `loc` (talk with an item)
##   kill    - kill `count` of `target` in `loc`; with "spawn" a named elite appears there
##   fetch   - bring `count` x `material` (crafting material) to `npc` in `loc`
##   escort  - in `loc`, someone waits at `start`; bring them to the portal alive
## NPC ids are quest givers from the level scripts or the towns (king, mayor, postmaster...).

var world: Node
var _escort: Node3D

const QUESTS := {
	"jq_summons": {"title": "A Royal Summons", "giver": "aldric", "loc": 0, "xp": 0.5, "gold": 8,
		"steps": [{"type": "talk", "loc": 2, "npc": "king", "line": "jq_summons_s0"}]},
	"jq_blight": {"title": "The Grey Blight", "giver": "king", "loc": 2, "requires": ["jq_summons"], "xp": 0.8, "gold": 14,
		"steps": [{"type": "talk", "loc": 1, "npc": "mayor", "line": "jq_blight_s0"},
			{"type": "kill", "loc": 1, "target": "ghoul", "count": 1, "spawn": {"type": "ghoul", "pos": Vector3(-124, 0, 100), "name": "Blight Herald"}},
			{"type": "talk", "loc": 2, "npc": "king", "line": "jq_blight_s2"}]},
	"jq_stariron": {"title": "Steel and Thunder", "giver": "king", "loc": 2, "requires": ["jq_blight"], "xp": 0.9, "gold": 16,
		"steps": [{"type": "talk", "loc": 3, "npc": "thorgrim", "line": "jq_stariron_s0"},
			{"type": "fetch", "loc": 2, "npc": "king", "material": "star_iron", "count": 5, "line": "jq_stariron_s1"}]},
	"jq_envoy": {"title": "The King's Envoy", "giver": "king", "loc": 2, "requires": ["jq_stariron"], "xp": 1.0, "gold": 20,
		"steps": [{"type": "escort", "loc": 2, "who": "Lady Elsbeth", "model": "people/woman_dress", "colors": {"Dress": Color(0.45, 0.15, 0.4), "Hair": Color(0.3, 0.18, 0.1)}},
			{"type": "talk", "loc": 4, "npc": "kaelen", "line": "jq_envoy_s1"},
			{"type": "kill", "loc": 4, "target": "magma_golem", "count": 1, "spawn": {"type": "magma_golem", "pos": Vector3(-150, 0, 70), "name": "The Ash Tyrant"}},
			{"type": "talk", "loc": 2, "npc": "king", "line": "jq_envoy_s3"}]},
	"jq_crown": {"title": "The Sunken Crown", "giver": "king", "loc": 2, "requires": ["jq_envoy"], "xp": 1.2, "gold": 30, "item": 4,
		"steps": [{"type": "talk", "loc": 5, "npc": "harbourmaster", "line": "jq_crown_s0"},
			{"type": "fetch", "loc": 5, "npc": "harbourmaster", "material": "abyssal_pearl", "count": 3, "line": "jq_crown_s1"},
			{"type": "talk", "loc": 2, "npc": "king", "line": "jq_crown_s2"}]},
	"jq_letters": {"title": "Royal Mail", "giver": "postmaster", "loc": 2, "xp": 0.35, "gold": 10,
		"steps": [{"type": "deliver", "loc": 1, "npc": "mayor", "item": "Sealed Royal Letter", "line": "jq_letters_s0"}]},
	"jq_salt": {"title": "Salt for the Capital", "giver": "harbourmaster", "loc": 5, "xp": 0.35, "gold": 12,
		"steps": [{"type": "deliver", "loc": 2, "npc": "postmaster", "item": "Barrel of Sea Salt", "line": "jq_salt_s0"}]},
	"jq_grain": {"title": "Grain for the King's Kitchen", "giver": "maybell", "loc": 0, "xp": 0.4, "gold": 6,
		"steps": [{"type": "deliver", "loc": 2, "npc": "postmaster", "item": "Sack of Northvale Grain", "line": "jq_grain_s0"}]},
	"jq_pilgrim": {"title": "The Lost Pilgrim", "giver": "mayor", "loc": 1, "xp": 0.6, "gold": 12,
		"steps": [{"type": "escort", "loc": 1, "who": "Brother Tomas", "model": "people/man2", "start": Vector3(-180, 0, 28),
			"colors": {"Shirt": Color(0.35, 0.28, 0.2), "Pants": Color(0.3, 0.24, 0.18), "Hair": Color(0.5, 0.5, 0.5)}},
			{"type": "talk", "loc": 1, "npc": "mayor", "line": "jq_pilgrim_s1"}]},
	"jq_lotus": {"title": "Frost Lotus", "giver": "alchemist", "loc": 2, "xp": 0.5, "gold": 10, "potions": 3,
		"steps": [{"type": "fetch", "loc": 2, "npc": "alchemist", "material": "frost_lotus", "count": 4, "line": "jq_lotus_s0"}]},
	"jq_cores": {"title": "Ember Cores", "giver": "smith", "loc": 5, "xp": 0.6, "gold": 14, "item": 3,
		"steps": [{"type": "fetch", "loc": 5, "npc": "smith", "material": "ember_core", "count": 3, "line": "jq_cores_s0"}]},
	"jq_dust": {"title": "Dust of the Blight", "giver": "aldric", "loc": 0, "requires": ["jq_summons"], "xp": 0.45, "gold": 8, "mana": 3,
		"steps": [{"type": "fetch", "loc": 0, "npc": "aldric", "material": "blight_dust", "count": 5, "line": "jq_dust_s0"}]},
}

## Who stands where (for the log and the waypoint when they're in another location).
const NPC_NAMES := {"king": "King Aldemar", "mayor": "Mayor Corvin", "postmaster": "Postmaster Pell", "alchemist": "Royal Alchemist Ysolde",
	"harbourmaster": "Harbourmaster Brine", "smith": "Hilda the Smith", "aldric": "Brother Aldric", "maybell": "Farmer Maybell",
	"thorgrim": "Thorgrim", "kaelen": "Kaelen"}


func st() -> Dictionary:
	if not Game.journey.has("q"):
		Game.journey["q"] = {}
	if not Game.journey.has("bounties"):
		Game.journey["bounties"] = []
	return Game.journey


func qs(id: String) -> Dictionary:
	return st()["q"].get(id, {})


func status(id: String) -> String:
	var s := qs(id)
	if not s.is_empty():
		return s["status"]
	for r in QUESTS[id].get("requires", []):
		if status(r) != "done":
			return "locked"
	return "available"


func step_of(id: String) -> Dictionary:
	var s := qs(id)
	var steps: Array = QUESTS[id]["steps"]
	return steps[int(s.get("step", 0))] if not s.is_empty() and int(s["step"]) < steps.size() else {}


func here() -> int:
	return Game.level_index


func _ready() -> void:
	_spawn_for_steps.call_deferred()


## Named elites and people to escort that belong in this location right now.
func _spawn_for_steps() -> void:
	for id in QUESTS:
		if status(id) != "active":
			continue
		var stp := step_of(id)
		if int(stp.get("loc", -1)) != here():
			continue
		match stp["type"]:
			"kill":
				if stp.has("spawn") and int(qs(id).get("progress", 0)) < int(stp["count"]):
					_spawn_named(id, stp["spawn"])
			"escort":
				_spawn_escort(id, stp)


func _spawn_named(id: String, sp: Dictionary) -> void:
	var e := Enemy.new()
	e.type = sp["type"]
	e.world = world
	e.level = world.zone_levels().y + 1
	e.elite = true
	e.title_override = sp["name"]
	e.set_meta("journey", id)
	var p: Vector3 = sp["pos"]
	p = world.clear_of_npcs(p)
	e.position = world.free_spot(Vector3(p.x, world.ground(p.x, p.z), p.z), 0.8, 2.4) + Vector3(0, 0.3, 0)
	world.add_child(e)
	e.died.connect(world._on_enemy_died)


func _spawn_escort(id: String, stp: Dictionary) -> void:
	if _escort and is_instance_valid(_escort):
		return
	var start: Vector3
	if stp.has("start"):
		start = stp["start"]
	elif world.town_npcs.has("king"):
		# the King's envoy waits outside the castle
		start = (world.town_npcs["king"] as Node3D).global_position
	else:
		start = world.respawn_point()
	var v := EscortNPC.new()
	v.world = world
	v.quest_id = id
	v.vname = Loc.t(stp["who"])
	v.model_file = stp.get("model", "people/man2")
	v.colors = stp.get("colors", {})
	v.gender = "f" if v.model_file.begins_with("people/woman") else "m"
	var spot: Vector3 = world.free_spot(Vector3(start.x, world.ground(start.x, start.z), start.z) + Vector3(2.0, 0, 2.0), 0.4, 1.8)
	v.home = {"door": null, "out": spot, "in": spot, "bed": spot, "bed_yaw": 0.0, "table": spot}
	v.work = {"pos": spot, "yaw": 0.0, "anim": "idle"}
	v.social = spot
	world.add_child(v)
	v.global_position = spot
	_escort = v


# --------------------------------------------------------------------------- progress

func accept(id: String) -> void:
	st()["q"][id] = {"status": "active", "step": 0, "progress": 0}
	st()["tracked"] = id
	if world.quests:
		world.quests.tracked = ""
	Game.play_sound("quest_accept", null, -4.0)
	world.hud.show_message(Loc.t("Quest accepted: %s") % Loc.t(QUESTS[id]["title"]), Color(1.0, 0.85, 0.4), 2.5)
	_after_step_change(id)


func _advance(id: String) -> void:
	var s := qs(id)
	s["step"] = int(s["step"]) + 1
	s["progress"] = 0
	if int(s["step"]) >= QUESTS[id]["steps"].size():
		_complete(id)
		return
	Game.play_sound("quest_progress", null, -4.0, 1.2)
	world.hud.show_message(Loc.t("%s: %s") % [Loc.t(QUESTS[id]["title"]), objective_text(id)], Color(1.0, 0.85, 0.3), 3.5)
	_after_step_change(id)


func _after_step_change(id: String) -> void:
	var stp := step_of(id)
	if not stp.is_empty() and int(stp["loc"]) == here():
		match stp["type"]:
			"kill":
				if stp.has("spawn"):
					_spawn_named(id, stp["spawn"])
			"escort":
				_spawn_escort(id, stp)
	world.quests.changed.emit()


func _complete(id: String) -> void:
	var q: Dictionary = QUESTS[id]
	qs(id)["status"] = "done"
	var p: Player = world.player
	var lvl := int(Game.progress["level"])
	var xp := int(Skills.xp_to_next(lvl) * float(q.get("xp", 0.5)))
	var gold := int(q.get("gold", 10)) * lvl
	p.add_xp(xp)
	p.add_gold(gold, true)
	var lines := ["+%d XP" % xp, "+%d %s" % [gold, Loc.t("gold")]]
	if q.has("item"):
		var it := Items.generate(lvl, int(q["item"]), "", "", 2.0)
		if Items.add_to_bag(Game.inventory, it):
			lines.append(Items.display_name(it))
	for k in ["potions", "mana"]:
		if q.has(k):
			var c := Crafting.pouch("consumables")
			var cid := "greater_potion" if k == "potions" else "mana_potion"
			c[cid] = int(c.get(cid, 0)) + int(q[k])
			lines.append("%s x%d" % [Loc.t(Crafting.CONSUMABLES[cid][0]), int(q[k])])
	world.hud.show_loot(Loc.t("QUEST COMPLETE") + ": " + Loc.t(q["title"]), lines)
	Game.stinger("complete")
	world.hero_t = maxf(world.hero_t, 300.0)
	if st().get("tracked", "") == id:
		st().erase("tracked")
	world.quests.changed.emit()


func on_enemy_killed(e: Enemy) -> void:
	for id in QUESTS:
		if status(id) != "active":
			continue
		var stp := step_of(id)
		if stp.get("type", "") != "kill" or int(stp["loc"]) != here() or e.type != stp["target"]:
			continue
		if stp.has("spawn") and e.get_meta("journey", "") != id:
			continue
		var s := qs(id)
		s["progress"] = int(s["progress"]) + 1
		if int(s["progress"]) >= int(stp["count"]):
			_advance(id)
	# bounties
	for b in st()["bounties"]:
		if b["status"] == "active" and int(b["loc"]) == here() and e.type == b["target"]:
			b["progress"] = int(b["progress"]) + 1
			world.hud.show_message("%s: %d / %d" % [Loc.t("Bounty"), int(b["progress"]), int(b["count"])], Color(1.0, 0.85, 0.5), 1.5)
			if int(b["progress"]) >= int(b["count"]):
				b["status"] = "done"
				world.player.add_gold(int(b["gold"]), true)
				world.player.add_xp(int(b["xp"]))
				world.hud.show_loot(Loc.t("Bounty complete!"), ["+%d %s" % [int(b["gold"]), Loc.t("gold")], "+%d XP" % int(b["xp"])])
				Game.play_sound("quest_done", null, -2.0)
	_clean_bounties()


func _clean_bounties() -> void:
	var keep := []
	for b in st()["bounties"]:
		if b["status"] != "done":
			keep.append(b)
	st()["bounties"] = keep


## The escort reached the portal.
func escort_arrived(id: String) -> void:
	_escort = null
	world.hud.show_message(Loc.t("Safe and sound!"), Color(0.6, 1.0, 0.6), 2.0)
	_advance(id)


func escort_failed(id: String) -> void:
	_escort = null
	world.hud.show_message(Loc.t("%s failed - they will wait again next time you come here") % Loc.t(QUESTS[id]["title"]), Color(1.0, 0.45, 0.35), 4.0)


## Leaving with the escort beside you counts as getting them to the portal.
func before_travel(_to: int) -> void:
	if _escort and is_instance_valid(_escort) and not _escort._dead and _escort.global_position.distance_to(world.player.global_position) < 12.0:
		var id: String = _escort.quest_id
		escort_arrived(id)


# --------------------------------------------------------------------------- dialogue

## Extra replies for an NPC: [[text, Callable]]. Offers, step talks, deliveries, hand-ins.
func options_for(npc_id: String, npc: Node) -> Array:
	var out := []
	for id in QUESTS:
		var q: Dictionary = QUESTS[id]
		var stv := status(id)
		if stv == "available" and q["giver"] == npc_id and int(q["loc"]) == here():
			out.append(["[!] " + Loc.t(q["title"]), _offer.bind(id, npc)])
		elif stv == "active":
			var stp := step_of(id)
			if stp.get("npc", "") != npc_id or int(stp["loc"]) != here():
				continue
			match stp["type"]:
				"talk":
					out.append(["[?] " + Loc.t(q["title"]), _step_talk.bind(id, npc)])
				"deliver":
					out.append(["[?] " + Loc.t("Hand over: %s") % Loc.t(stp["item"]), _step_talk.bind(id, npc)])
				"fetch":
					var have := Crafting.count(stp["material"])
					if have >= int(stp["count"]):
						out.append(["[?] " + Loc.t("Hand over %d %s") % [int(stp["count"]), Crafting.mat_name(stp["material"])], _step_fetch.bind(id, npc)])
	return out


func marker_for(npc_id: String) -> String:
	var m := ""
	for o in options_for(npc_id, null):
		var t: String = o[0]
		if t.begins_with("[?]"):
			return "?"
		if t.begins_with("[!]"):
			m = "!"
	return m


func _speak(npc: Node, line: String, title: String, buttons: Array) -> void:
	if npc and npc.has_method("speak"):
		var dur: float = npc.speak(line)
		var lid := Loc.line(line)
		var nm: String = npc.display_name
		var tt: String = npc.title if "title" in npc else ""
		world.player.input_locked = true
		world.hud.show_dialogue(nm, Loc.t(tt), Loc.t(title), QuestManager.line_text(lid), buttons, dur, QuestManager.line_translation(lid))


func _offer(id: String, npc: Node) -> void:
	var q: Dictionary = QUESTS[id]
	_speak(npc, id + "_offer", q["title"], [[Loc.t("Accept"), func() -> void:
		accept(id)
		world.end_dialogue()], [Loc.t("Not now"), world.end_dialogue]])


func _step_talk(id: String, npc: Node) -> void:
	var stp := step_of(id)
	var last: bool = int(qs(id)["step"]) == QUESTS[id]["steps"].size() - 1
	_speak(npc, stp.get("line", id + "_done"), QUESTS[id]["title"], [[Loc.t("Continue"), func() -> void:
		_advance(id)
		world.end_dialogue()]])
	if last:
		pass


func _step_fetch(id: String, npc: Node) -> void:
	var stp := step_of(id)
	Crafting.pay({stp["material"]: int(stp["count"])})
	_speak(npc, stp.get("line", id + "_done"), QUESTS[id]["title"], [[Loc.t("Continue"), func() -> void:
		_advance(id)
		world.end_dialogue()]])


# --------------------------------------------------------------------------- log and waypoint

func objective_text(id: String) -> String:
	var stp := step_of(id)
	if stp.is_empty():
		return ""
	var where := Loc.t(Game.LEVELS[int(stp["loc"])]["name"])
	var who := Loc.t(NPC_NAMES.get(stp.get("npc", ""), stp.get("npc", "")))
	var t := ""
	match stp["type"]:
		"talk":
			t = Loc.t("Talk to %s") % who
		"deliver":
			t = Loc.t("Deliver %s to %s") % [Loc.t(stp["item"]), who]
		"kill":
			t = (Loc.t("Slay %s") % Loc.t(stp["spawn"]["name"])) if stp.has("spawn") else "%s %d / %d" % [Loc.t("Kill"), int(qs(id).get("progress", 0)), int(stp["count"])]
		"fetch":
			t = Loc.t("Bring %s %d / %d to %s") % [Crafting.mat_name(stp["material"]), mini(Crafting.count(stp["material"]), int(stp["count"])), int(stp["count"]), who]
		"escort":
			t = Loc.t("Escort %s to the portal") % Loc.t(stp["who"])
	if int(stp["loc"]) != here():
		t += "  (" + where + ")"
	return t


## [title, detail, ready] for the quest log.
func log_entries() -> Array:
	var out := []
	for id in QUESTS:
		if status(id) == "active":
			out.append([QUESTS[id]["title"], objective_text(id), int(step_of(id).get("loc", -1)) == here() and step_of(id)["type"] in ["talk", "deliver"]])
	for b in st()["bounties"]:
		if b["status"] == "active":
			out.append([Loc.t("Bounty") + ": " + Loc.t(Enemy.TYPES[b["target"]]["name"]), "%d / %d  (%s)" % [int(b["progress"]), int(b["count"]), Loc.t(Game.LEVELS[int(b["loc"])]["name"])], false])
	return out


## Where the waypoint points for the tracked travel quest, or {}.
func objective_target(from: Vector3) -> Dictionary:
	var id: String = st().get("tracked", "")
	if id == "" or status(id) != "active":
		return {}
	var stp := step_of(id)
	var title := Loc.t(QUESTS[id]["title"])
	if int(stp["loc"]) != here():
		if world.portal and world.portal.is_built():
			return {"pos": world.portal.arrival_point() + Vector3(0, 2.5, 0), "label": "%s: %s" % [title, Loc.t("travel to %s (portal)") % Loc.t(Game.LEVELS[int(stp["loc"])]["name"])]}
		return {}
	match stp["type"]:
		"talk", "deliver", "fetch":
			var npc = world.quests.npcs.get(stp["npc"])
			if npc:
				return {"pos": npc.global_position + Vector3(0, 2.2, 0), "label": "%s: %s" % [title, npc.display_name]}
		"kill":
			var best := {}
			var bd := INF
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.type == stp["target"] and (not stp.has("spawn") or e.get_meta("journey", "") == id):
					var d: float = from.distance_to(e.global_position)
					if d < bd:
						bd = d
						best = {"pos": e.global_position + Vector3(0, 2.2, 0), "label": "%s: %s" % [title, e.display_name]}
			return best
		"escort":
			if _escort and is_instance_valid(_escort):
				if from.distance_to(_escort.global_position) > 15.0:
					return {"pos": _escort.global_position + Vector3(0, 2.2, 0), "label": "%s: %s" % [title, _escort.vname]}
				if world.portal:
					return {"pos": world.portal.arrival_point() + Vector3(0, 2.5, 0), "label": "%s: %s" % [title, Loc.t("the portal")]}
	return {}


# --------------------------------------------------------------------------- bounties

## Three bounty offers for this location's notice board (kept until taken).
func board_offers() -> Array:
	var key := "board_%d" % here()
	if not st().has(key) or st()[key].is_empty():
		var types := []
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.neutral and not e.boss and not e.elite and not types.has(e.type) and e.get_meta("journey", "") == "":
				types.append(e.type)
		types.shuffle()
		var offers := []
		var zl: Vector2i = world.zone_levels()
		for t in types.slice(0, 3):
			var n := randi_range(6, 12)
			offers.append({"target": t, "count": n, "loc": here(), "progress": 0, "status": "offer",
				"gold": n * zl.y * 12, "xp": int(Skills.kill_xp(zl.y, 120.0, false, false) * n * 1.5)})
		st()[key] = offers
	return st()[key]


func take_bounty(i: int) -> void:
	var key := "board_%d" % here()
	var b: Dictionary = st()[key][i]
	if st()["bounties"].size() >= 3:
		world.hud.show_message(Loc.t("You can hold three bounties at a time"), Color(1.0, 0.6, 0.4), 2.0)
		return
	b["status"] = "active"
	st()["bounties"].append(b)
	st()[key].remove_at(i)
	Game.play_sound("quest_accept", null, -4.0)
	world.hud.show_message(Loc.t("Bounty taken: %s x%d") % [Loc.t(Enemy.TYPES[b["target"]]["name"]), int(b["count"])], Color(1.0, 0.85, 0.4), 2.5)
	world.quests.changed.emit()
