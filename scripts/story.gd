class_name Story
extends Node
## A location's story layer: conversations with replies, NPC greetings and topics that change with
## what you have done, clues to inspect, people who come and go, and small scripted moments.
##
## Data: res://data/story/<location>.json (see northvale.json). Spoken text are line ids from
## data/dialogue.json (voiced, "_uk" variants for Ukrainian); replies, titles and clue texts are
## English and translated through Loc (data/uk.json). Places come from the level script:
## clue_spots(), story_npcs(), story_points().
##
## Conversation: {"start": node, "nodes": {id: node}}. Node:
##   "say": line id, "who": npc id ("" = the one you talk to, "player" = you, "boss" = the boss
##   you met), "do": [effects], "event": scripted moment, "wait": true (moment plays first),
##   "choices": [{"text", "to", "if", "do"}], "next": node or [[condition, node], ...],
##   "end": button text when the conversation ends here.
## "to"/"next" can also be "end" (close) or "hub" (the npc's topics).
## Conditions (all must hold, "!" negates): flag:x, done:q, active:q, ready:q, avail:q, started:q,
##   step:q:n, trust:npc:n, night, evening, raid.
## Effects: accept, step, complete (the conversation's quest, or ":quest"), flag:x, unflag:x,
##   trust:npc:n, give:consumables|gadgets|materials:id:n, gold:n, event:name.
## NPC hubs ("npcs": {id: {"greet": [{"if", "line"|"convo", "do"}], "topics": [{"text", "if", "line"|
##   "convo"|"event", "do", "hub": false = the conversation ends without going back to the topics}]}}).

var world: Node
var data: Dictionary = {}
var _npc: QuestGiver
var _cid := ""
var _quest := ""
var _to_hub := false
var _completed := false
var _boss: Enemy                     # the boss whose introduction is playing
var _voice: AudioStreamPlayer        # thoughts and voices of people who aren't nearby
var _dynamic := {}                   # npc id -> QuestGiver (people who come and go)
var _intro_t := 0.0
var _overlay: CanvasLayer
var _overlay_t := 0.0
var _kill_pos := {}                  # name / type of an enemy -> where it last died (clues "at_kill")
var _homes := {}                     # npc id -> [position, yaw] of story people who move ("static")


func load_story(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		push_warning("Story: could not read " + path)
		return false
	data = d
	return true


func _ready() -> void:
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX"
	_voice.volume_db = 4.0
	add_child(_voice)
	# optional clues that are always there (a cabinet, a map on a wall...)
	for cid in data.get("static_clues", []):
		spawn_clue(cid, "")
	refresh_npcs.call_deferred()


# --------------------------------------------------------------------------- conditions / effects

func check(cond: String) -> bool:
	for part in cond.split(" ", false):
		var neg := part.begins_with("!")
		if neg:
			part = part.substr(1)
		if _check1(part) == neg:
			return false
	return true


func _check1(c: String) -> bool:
	var a := c.split(":")
	var q: QuestManager = world.quests
	match a[0]:
		"flag":
			return bool(Game.flags.get(a[1], false))
		"done", "active", "ready":
			return q != null and q.status(a[1]) == a[0]
		"avail":
			return q != null and q.status(a[1]) == "available"
		"started":
			return q != null and q.status(a[1]) in ["active", "ready", "done"]
		"step":
			return q != null and q.status(a[1]) == "active" and q.step_index(a[1]) == int(a[2])
		"trust":
			return int(Game.flags.get("trust_" + a[1], 0)) >= int(a[2])
		"night":
			return world.day_night != null and world.day_night.is_night()
		"evening":
			return world.day_night != null and (world.day_night.hour >= 17.0 or world.day_night.hour < 5.0)
		"raid":
			return world.raid_t > 0.0
	push_warning("Story: unknown condition " + c)
	return false


func apply(effects: Array) -> void:
	for e: String in effects:
		var a := e.split(":")
		var q: QuestManager = world.quests
		var qid := _quest if a.size() < 2 else a[1]
		match a[0]:
			"accept":
				q.accept(qid)
			"step":
				q.on_talk_step(qid)
			"complete":
				q.complete(qid)
				_completed = true
			"flag":
				Game.flags[a[1]] = true
			"unflag":
				Game.flags.erase(a[1])
			"trust":
				Game.flags["trust_" + a[1]] = int(Game.flags.get("trust_" + a[1], 0)) + int(a[2])
			"give":
				var n := int(a[3])
				if a[1] == "materials":
					Crafting.add(a[2], n)
				else:
					var pouch := Crafting.pouch(a[1])
					pouch[a[2]] = int(pouch.get(a[2], 0)) + n
			"gold":
				world.player.add_gold(int(a[1]))
			"event":
				_event(a[1])
			_:
				push_warning("Story: unknown effect " + e)


# --------------------------------------------------------------------------- talking

func _has_quest_convo(npc_id: String) -> bool:
	var q: QuestManager = world.quests
	for d in [q.ready_for(npc_id), q.talk_step_for(npc_id), q.available_for(npc_id)]:
		if not d.is_empty() and d.has("convo"):
			return true
	return false


## Starts talking with `npc`. False when the story has nothing for them (the old dialogue runs).
func talk(npc: QuestGiver) -> bool:
	if not data.get("npcs", {}).has(npc.id) and not _has_quest_convo(npc.id):
		return false
	var q: QuestManager = world.quests
	_npc = npc
	world._talking = npc
	var d := q.ready_for(npc.id)
	if not d.is_empty():
		if d.get("convo", {}).has("done"):
			run(d["convo"]["done"], d["id"])
			return true
		return false
	d = q.talk_step_for(npc.id)
	if not d.is_empty():
		run(q.current_step(d["id"])["convo"], d["id"])
		return true
	d = q.available_for(npc.id)
	if not d.is_empty():
		if d.get("convo", {}).has("offer"):
			run(d["convo"]["offer"], d["id"])
			return true
		return false
	hub(npc)
	return true


func run(convo_id: String, quest_id := "", to_hub := false) -> void:
	if not data.get("convos", {}).has(convo_id):
		push_warning("Story: no conversation " + convo_id)
		world.end_dialogue()
		return
	_cid = convo_id
	_quest = quest_id
	_to_hub = to_hub
	_completed = false
	_show_node(str(data["convos"][convo_id].get("start", "start")))


func _show_node(nid: String) -> void:
	if nid == "end":
		_finish()
		return
	if nid == "hub":
		if _npc and is_instance_valid(_npc):
			hub(_npc)
		else:
			world.end_dialogue()
		return
	var node: Dictionary = data["convos"][_cid]["nodes"].get(nid, {})
	if node.is_empty():
		push_warning("Story: %s has no node %s" % [_cid, nid])
		_finish()
		return
	apply(node.get("do", []))
	if node.has("event"):
		if node.get("wait", false):
			world.hud.hide_dialogue()
			world.player.input_locked = true
			await _event(node["event"])
			if not is_inside_tree():
				return
		else:
			_event(node["event"])
	var buttons := []
	for c: Dictionary in node.get("choices", []):
		if check(c.get("if", "")):
			buttons.append([Loc.t(c["text"]), _choose.bind(c)])
	if buttons.is_empty():
		if node.has("next"):
			buttons.append([Loc.t("Continue"), func() -> void: _show_node(_resolve(node["next"]))])
		else:
			buttons.append([Loc.t(node.get("end", "Goodbye")), _finish])
	if node.has("say"):
		var title := ""
		if _quest != "":
			title = world.quests.get_def(_quest).get("title", "")
		_show_line(node.get("who", ""), node["say"], title, buttons)
	elif node.has("next"):
		_show_node(_resolve(node["next"]))
	else:
		_finish()


func _resolve(nxt) -> String:
	if nxt is String:
		return nxt
	for opt in nxt:
		if check(str(opt[0])):
			return str(opt[1])
	return "end"


func _choose(c: Dictionary) -> void:
	apply(c.get("do", []))
	_show_node(str(c.get("to", "end")))


func _finish() -> void:
	var npc := _npc
	var boss := _boss
	_cid = ""
	if boss:
		_boss = null
		world.truce = false
		world.end_dialogue()
		if is_instance_valid(boss):
			boss.aggro()
		return
	if _to_hub and npc and is_instance_valid(npc):
		hub(npc)
		return
	if _completed and npc and is_instance_valid(npc):
		var q: QuestManager = world.quests
		if not (q.ready_for(npc.id).is_empty() and q.talk_step_for(npc.id).is_empty() and q.available_for(npc.id).is_empty()):
			_completed = false
			world.talk(npc)
			return
	world.end_dialogue()


## The npc's greeting (or the line of a topic) with the topics you can ask about.
func hub(npc: QuestGiver, line_id := "") -> void:
	_npc = npc
	_cid = ""
	_quest = ""
	world._talking = npc
	var d: Dictionary = data.get("npcs", {}).get(npc.id, {})
	if line_id == "":
		for g: Dictionary in d.get("greet", []):
			if check(g.get("if", "")):
				apply(g.get("do", []))
				if g.has("convo"):
					run(g["convo"], "", true)
					return
				line_id = g.get("line", "")
				break
	var buttons := []
	for t: Dictionary in d.get("topics", []):
		if check(t.get("if", "")):
			buttons.append([Loc.t(t["text"]), _topic.bind(npc, t)])
	if world.journey:
		buttons += world.journey.options_for(npc.id, npc)
	if npc.role == "trader":
		buttons.append([Loc.t("Trade"), func() -> void:
			world.end_dialogue()
			world.open_shop(npc)])
	buttons.append([Loc.t("Goodbye"), world.end_dialogue])
	if line_id == "":
		line_id = npc.id + "_hello"
	_show_line("", line_id, "", buttons)


func _topic(npc: QuestGiver, t: Dictionary) -> void:
	apply(t.get("do", []))
	if t.has("convo"):
		run(t["convo"], "", t.get("hub", true))
	elif t.has("event"):
		await _event(t["event"])
		if is_inside_tree() and is_instance_valid(npc):
			hub(npc, t.get("line", ""))
	else:
		hub(npc, t.get("line", ""))


func _speaker(who: String) -> Node3D:
	match who:
		"":
			return _npc
		"player":
			return null
		"boss":
			return _boss
	if world.quests.npcs.has(who):
		return world.quests.npcs[who]
	return _dynamic.get(who)


func _show_line(who: String, line_id: String, quest_title: String, buttons: Array) -> void:
	var sp := _speaker(who)
	var lid := Loc.line(line_id)
	var dur := 0.0
	var who_name := Loc.t("You")
	var who_title := Loc.t("Soldier")
	if sp is QuestGiver:
		var g := sp as QuestGiver
		who_name = g.display_name
		who_title = Loc.t(g.title)
		if world.player and g.global_position.distance_to(world.player.global_position) < 18.0:
			dur = g.speak(line_id)
		else:
			dur = _play(line_id, g.voice_pitch)
	elif sp is Enemy:
		who_name = (sp as Enemy).display_name
		who_title = Loc.t(data.get("boss_titles", {}).get((sp as Enemy).type, "Enemy"))
		dur = _play(line_id, 0.92)
	else:
		dur = _play(line_id, 1.0)
	world.player.input_locked = true
	world.hud.show_dialogue(who_name, who_title, Loc.t(quest_title), QuestManager.line_text(lid), buttons, dur, QuestManager.line_translation(lid))


## Plays a voice line without a speaker in the world (thoughts, someone who isn't nearby).
func _play(line_id: String, pitch := 1.0) -> float:
	var lid := Loc.line(line_id)
	var path := "res://assets/voice/%s.wav" % lid
	var text := QuestManager.line_text(lid)
	if not ResourceLoader.exists(path):
		return 2.0 + text.length() / 15.0
	var stream: AudioStream = load(path)
	_voice.stream = stream
	_voice.pitch_scale = pitch
	_voice.play()
	return stream.get_length() / pitch


# --------------------------------------------------------------------------- clues

## A clue spot for `cid` at its place from the level (quest_id "" = optional, always there).
## A clue with "at_kill": <enemy name> lies where that enemy died (if it died this visit).
func spawn_clue(cid: String, quest_id: String) -> Node:
	var spots: Dictionary = world.level.clue_spots() if world.level.has_method("clue_spots") else {}
	if not spots.has(cid) or not data.get("clues", {}).has(cid):
		push_warning("Story: no clue " + cid)
		return null
	var p: Vector3 = spots[cid]
	var ak: String = data["clues"][cid].get("at_kill", "")
	if ak != "" and _kill_pos.has(ak):
		var kp: Vector3 = _kill_pos[ak]
		p = Vector3(kp.x, p.y, kp.z)
	return spawn_clue_at(cid, quest_id, p)


func spawn_clue_at(cid: String, quest_id: String, p: Vector3) -> Node:
	var def: Dictionary = data["clues"].get(cid, {})
	var c := ClueSpot.new()
	c.world = world
	c.story = self
	c.clue_id = cid
	c.quest_id = quest_id
	c.def = def
	c.subtle = quest_id == "" and def.get("subtle", true)
	world.add_child(c)
	# y > 0.5: that high above the ground (on a table, a shelf)
	c.global_position = Vector3(p.x, world.ground(p.x, p.z) + (p.y if p.y > 0.5 else 0.15), p.z)
	return c


## Shows what you find at a clue (note + the soldier's thought) and applies its effects.
func show_clue(cid: String) -> void:
	var def: Dictionary = data.get("clues", {}).get(cid, {})
	if def.is_empty():
		return
	world.hud.show_note(Loc.t(def.get("title", "")), Loc.t(def.get("text", "")))
	Game.play_sound(def.get("sound", "page"), null, -6.0)
	if def.has("line"):
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if is_inside_tree():
				_play(def["line"]))
	if def.has("flag"):
		Game.flags[def["flag"]] = true
	apply(def.get("do", []))


# --------------------------------------------------------------------------- people who come and go

## Puts story people where they belong now (the first place whose condition holds), or removes them.
func refresh_npcs() -> void:
	if not world.level.has_method("story_npcs"):
		return
	for n: Dictionary in world.level.story_npcs():
		var place: Dictionary = {}
		for pl: Dictionary in n["places"]:
			if check(pl.get("if", "")):
				place = pl
				break
		var id: String = n["id"]
		if n.get("static", false):
			_move_static(id, place)
			continue
		var cur: QuestGiver = _dynamic.get(id)
		if place.is_empty():
			if cur and is_instance_valid(cur):
				if world._talking == cur:
					continue
				cur.queue_free()
				world.quests.npcs.erase(id)
			_dynamic.erase(id)
			continue
		var pos: Vector3 = place["pos"]
		if cur and is_instance_valid(cur):
			if Vector2(cur.global_position.x - pos.x, cur.global_position.z - pos.z).length() < 1.0:
				continue
			if world._talking == cur:
				continue
			cur.queue_free()
		var g := QuestGiver.new()
		g.world = world
		g.id = id
		g.display_name = Loc.t(n["name"])
		g.title = n.get("title", "")
		g.model_file = n.get("model", "people/man1")
		g.colors = n.get("colors", {})
		g.head_height = n.get("head", 1.62)
		g.voice_pitch = n.get("pitch", 1.0)
		g.child = n.get("child", false)
		g.pose = place.get("pose", "")
		world.add_child(g)
		g.global_position = Vector3(pos.x, world.ground(pos.x, pos.z), pos.z)
		g.rotation.y = deg_to_rad(place.get("yaw", 0.0))
		_dynamic[id] = g
		world.quests.npcs[id] = g


## A level npc who goes somewhere else for a while (place {} = back home).
func _move_static(id: String, place: Dictionary) -> void:
	var g: QuestGiver = world.quests.npcs.get(id)
	if g == null or not is_instance_valid(g) or world._talking == g:
		return
	if not _homes.has(id):
		_homes[id] = [g.global_position, g.rotation.y]
	var pos: Vector3 = _homes[id][0]
	var yaw: float = _homes[id][1]
	if not place.is_empty():
		pos = place["pos"]
		pos.y = world.ground(pos.x, pos.z)
		yaw = deg_to_rad(place.get("yaw", 0.0))
	if g.global_position.distance_to(pos) < 0.5:
		return
	g.global_position = pos
	g.rotation.y = yaw


func on_accept(_id: String) -> void:
	refresh_npcs.call_deferred()
	apply(data.get("on_accept", {}).get(_id, []))


func on_step(_id: String, _step: int) -> void:
	refresh_npcs.call_deferred()


func on_complete(id: String) -> void:
	refresh_npcs.call_deferred()
	apply(data.get("on_complete", {}).get(id, []))


## A boss or a named enemy died: something it carried may be left behind.
func on_enemy_killed(e: Enemy) -> void:
	_kill_pos[e.title_override if e.title_override != "" else e.type] = e.global_position
	var k: Dictionary = data.get("on_kill", {}).get(e.type, {})
	if k.is_empty() or (k.get("boss", true) and not e.boss):
		return
	if k.has("clue"):
		spawn_clue_at(k["clue"], "", e.global_position)
	apply(k.get("do", []))


# --------------------------------------------------------------------------- boss introductions

func _process(delta: float) -> void:
	if _overlay:
		_overlay_t -= delta
		if _overlay_t <= 0.0 or (world.hud and not world.hud.dialogue.visible and _overlay_t < 9.0):
			_overlay.queue_free()
			_overlay = null
	_intro_t -= delta
	if _intro_t > 0.0 or world.player == null or world.player.input_locked or world.player.dead:
		return
	_intro_t = 0.3
	var intros: Dictionary = data.get("boss_intro", {})
	if intros.is_empty():
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if not en.boss or en.state == Enemy.State.DEAD or not intros.has(en.type):
			continue
		var key: String = "intro_" + en.type
		if Game.flags.get(key, false):
			continue
		var it: Dictionary = intros[en.type]
		if en.global_position.distance_to(world.player.global_position) > float(it.get("radius", 15.0)) or not en._has_los:
			continue
		Game.flags[key] = true
		_boss = en
		_npc = null
		world.truce = true
		_cid = ""
		run(it["convo"], "")
		return


# --------------------------------------------------------------------------- scripted moments

func _event(ev: String) -> void:
	match ev:
		"drone_recording":
			_show_recording(str(data.get("recording", "res://assets/textures/story/drone_recording.png")))
		"drone_flight":
			await _drone_flight()
		"rest":
			var p: Player = world.player
			if int(Game.inventory.get("gold", 0)) >= 5:
				Game.inventory["gold"] = int(Game.inventory.get("gold", 0)) - 5
				p.health = p.max_health
				p.mana = p.max_mana
				Game.play_sound("heal", null, -4.0, 0.9)
				world.hud.show_message(Loc.t("You rest by the fire: health and mana restored"), Color(1.0, 0.9, 0.6), 3.0)
			else:
				world.hud.show_message(Loc.t("Not enough gold"), Color(1.0, 0.5, 0.4), 2.0)
		"bell":
			var bp: Vector3 = world.level.story_points().get("bell", world.player.global_position) if world.level.has_method("story_points") else world.player.global_position
			Game.play_sound("bell", bp, 6.0, 0.9)
		_:
			if data.get("notes", {}).has(ev):
				var n: Dictionary = data["notes"][ev]
				world.hud.show_note(Loc.t(n.get("title", "")), Loc.t(n.get("text", "")))
			else:
				push_warning("Story: unknown event " + ev)


## The drone's recording: a grainy night picture on a little screen beside the dialogue.
func _show_recording(path: String) -> void:
	if _overlay:
		_overlay.queue_free()
	_overlay = CanvasLayer.new()
	_overlay.layer = 6
	add_child(_overlay)
	_overlay_t = 16.0
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.02, 0.95)
	sb.border_color = Color(0.25, 0.25, 0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(6)
	frame.add_theme_stylebox_override("panel", sb)
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.12
	frame.anchor_bottom = 0.12
	frame.offset_left = -60
	frame.offset_right = 600
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(frame)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(640, 360)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(holder)
	var tr := TextureRect.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	holder.add_child(tr)
	holder.add_child(_static_rect(0.22))
	var rec := Game.make_label("● REC   03:12:44", 18, Color(1.0, 0.25, 0.2))
	rec.position = Vector2(12, 8)
	holder.add_child(rec)
	var blink := rec.create_tween().set_loops()
	blink.tween_property(rec, "modulate:a", 0.25, 0.5)
	blink.tween_property(rec, "modulate:a", 1.0, 0.5)
	Game.play_sound("pickup_tech", null, -6.0)


## Video noise and scanlines over the whole rect (strength: alpha of the noise).
func _static_rect(strength: float) -> ColorRect:
	var cr := ColorRect.new()
	cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float strength = 0.2;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = h(floor(UV * vec2(320.0, 180.0)) + floor(TIME * 24.0) * 1.37);
	float scan = 0.5 + 0.5 * sin(UV.y * 600.0 + TIME * 8.0);
	float roll = smoothstep(0.0, 0.03, abs(fract(UV.y - TIME * 0.17) - 0.5));
	COLOR = vec4(vec3(n), strength * (0.7 + 0.3 * scan) + (1.0 - roll) * 0.15);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", strength)
	cr.material = m
	return cr


## VesPer's repaired drone flies over the valley towards the east road; the picture breaks up.
func _drone_flight() -> void:
	var pts: Dictionary = world.level.story_points() if world.level.has_method("story_points") else {}
	if not pts.has("flight_from") or not pts.has("flight_to"):
		return
	var a: Vector3 = pts["flight_from"]
	var b: Vector3 = pts["flight_to"]
	a.y = world.ground(a.x, a.z) + 2.0
	var top := Vector3(lerpf(a.x, b.x, 0.3), world.ground(a.x, a.z) + 34.0, lerpf(a.z, b.z, 0.3))
	b.y = world.ground(b.x, b.z) + 26.0
	var cam := Camera3D.new()
	cam.fov = 82.0
	cam.far = 900.0
	cam.cull_mask = world.player.camera.cull_mask
	world.add_child(cam)
	cam.global_position = a
	cam.current = true
	var ov := CanvasLayer.new()
	ov.layer = 45
	add_child(ov)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(root)
	var noise := _static_rect(0.12)
	root.add_child(noise)
	var rec := Game.make_label("● REC    FPV    %d%%" % 87, 22, Color(1.0, 0.25, 0.2))
	rec.position = Vector2(30, 24)
	root.add_child(rec)
	var buzz := AudioStreamPlayer.new()
	buzz.bus = "SFX"
	if Game.sounds.has("drone_buzz"):
		buzz.stream = Game.sounds["drone_buzz"][0]
		buzz.volume_db = -6.0
		add_child(buzz)
		buzz.play()
	var t := 0.0
	var dur := 8.0
	while t < dur and is_inside_tree():
		var dt := get_process_delta_time()
		t += dt
		var k := t / dur
		var p: Vector3
		if k < 0.35:
			p = a.lerp(top, ease(k / 0.35, -2.0))
		else:
			p = top.lerp(b, (k - 0.35) / 0.65)
		cam.global_position = p
		var look := b + Vector3(0, -22.0, 0) if k > 0.2 else top + (b - a).normalized() * 10.0
		cam.look_at(look, Vector3.UP)
		cam.rotate_object_local(Vector3.FORWARD, sin(t * 1.7) * 0.05)
		(noise.material as ShaderMaterial).set_shader_parameter("strength", 0.12 + maxf(0.0, (k - 0.82) / 0.18) * 0.9)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(buzz):
		buzz.queue_free()
	ov.queue_free()
	if is_instance_valid(cam):
		cam.queue_free()
	if world.player and world.player.camera:
		world.player.camera.current = true
