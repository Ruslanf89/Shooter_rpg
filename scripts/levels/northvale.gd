extends RefCounted
## Location 1: Northvale - a farming valley around Saint Shkvarok Church (церква святого Шкварка).
## North: the church on its rise, the cemetery behind it, the bell tower. West: the old kobold mine.
## Centre: the village. East: Maybell's farm and the granary. South-east of the church: the Old Oak
## and VesPer's lean-to. South-east road: the Red Bandana camp. East: the blocked road to Darkwood.
## The story (conversations, clues, people) is in res://data/story/northvale.json.

const CHURCH := Vector3(0, 0, -124)
const S := 1.3   # church grounds scale
const CEMETERY := Vector3(0, 0, -188)
const OAK := Vector3(44, 0, -96)
const TREE_PLATFORM := 11.0
const VESPER := Vector3(30, 0, -80)
const VILLAGE := Vector3(0, 0, 38)
const GUARD_POST := Vector3(10, 0, 104)
const START := Vector3(-26, 0, 146)
const FARM := Vector3(150, 0, -12)
const GRANARY := Vector3(92, 0, 8)
const MINE := Vector3(-180, 0, 20)
const SHELTER := Vector3(-122, 0, 42)     # the ruined shelter on the mine road (the missing guard)
const CAMP := Vector3(124, 0, 156)
const EAST_GATE := Vector3(214, 0, -14)
const DEN := Vector3(-110, 0, 164)
const TOWER := Vector3(176, 0, -150)
const LAKE := Vector3(64, 0, -56)

var _drone_spot := OAK + Vector3(2, TREE_PLATFORM, 0)   # set in build()
var village: Village


func config() -> Dictionary:
	return {
		"half": 280.0, "seed": 11, "hill_amp": 6.0,
		"player_start": START, "player_yaw": -0.68, "tree_spacing": 7.5,
		"sky": {"top_color": Color(0.36, 0.5, 0.74), "horizon_color": Color(0.8, 0.84, 0.88), "ground_color": Color(0.35, 0.38, 0.3),
			"sun_glow": Color(1.0, 0.88, 0.7), "cloud_color": Color(0.96, 0.96, 0.95), "cloud_shadow": Color(0.58, 0.62, 0.7), "cloud_cover": 0.68},
		"sun_rot": Vector3(-34, -40, 0), "sun_color": Color(1.0, 0.9, 0.76), "sun_energy": 1.25, "ambient": 1.0,
		"fog_color": Color(0.74, 0.79, 0.84), "fog_density": 0.0042, "color_saturation": 1.08,
		"grass_tint": Vector3(1.0, 1.0, 0.6), "grass_tint2": Vector3(0.9, 1.0, 0.55), "floor_tint": Vector3(1, 0.92, 0.62),
		"dirt_tint": Vector3(1.3, 1.0, 0.75), "rock_tint": Vector3(1.12, 1.08, 1.0), "stone_tint": Vector3(1.05, 1.02, 0.95),
		"field_tint": Vector3(1.45, 1.15, 0.72), "saturation": 1.04,
		"foliage": [Color(0.18, 0.28, 0.07), Color(0.44, 0.55, 0.15), Color(0.8, 0.74, 0.3)],
		"pine_foliage": [Color(0.08, 0.18, 0.07), Color(0.18, 0.33, 0.11), Color(0.38, 0.48, 0.18)],
		"bark_tint": Color(1.1, 0.75, 0.45), "tree_style": "oak", "tree_count": 230, "pine_ratio": 0.15,
		"grass_base": Color(0.22, 0.34, 0.09), "grass_tip": Color(0.58, 0.62, 0.24),
		"wheat_base": Color(0.5, 0.42, 0.16), "wheat_tip": Color(0.92, 0.8, 0.42),
		"ambience": "forest",
	}


func story_file() -> String:
	return "res://data/story/northvale.json"


func npcs() -> Array:
	return [
		{"id": "aldric", "name": "Brother Aldric", "title": "Priest of Saint Shkvarok", "pos": CHURCH + Vector3(6.5, 0, 21), "yaw": 200, "model": "people/man2",
			"colors": {"Shirt": Color(0.32, 0.24, 0.17), "Pants": Color(0.26, 0.2, 0.14), "Hair": Color(0.55, 0.52, 0.5)}},
		{"id": "maybell", "name": "Farmer Maybell", "title": "Maybell's Farm", "pos": FARM + Vector3(-4, 0, 5), "yaw": 250, "model": "people/woman_casual",
			"colors": {"Shirt": Color(0.36, 0.46, 0.33), "Pants": Color(0.3, 0.24, 0.18), "Hair": Color(0.5, 0.32, 0.18), "outfit": "apron"}},
		{"id": "brannock", "name": "Sergeant Brannock", "title": "Northvale Guard", "pos": GUARD_POST + Vector3(-6.5, 0, 0.5), "yaw": -35, "model": "people/adventurer",
			"colors": {"LightGreen": Color(0.4, 0.45, 0.55), "Green": Color(0.22, 0.27, 0.38)}},
		{"id": "vesper", "name": "VesPerFPV", "title": "FPV Pilot", "pos": VESPER + Vector3(0.5, 0, 3.2), "yaw": -20, "model": "people/casual",
			"colors": People.vesper_colors(),
			"face": "res://assets/textures/vesper_face.png", "build": Vector3(1.22, 1.0, 1.18), "pitch": 1.25},
		{"id": "olek", "name": "Old Olek", "title": "Gravedigger", "pos": CEMETERY + Vector3(-3.5, 0, 11.5), "yaw": 15, "model": "people/farmer",
			"colors": {"LightBlue": Color(0.3, 0.29, 0.26), "Beige": Color(0.48, 0.42, 0.34), "Hair": Color(0.82, 0.8, 0.76)}},
		{"id": "iva", "name": "Iva", "title": "Village Child", "pos": VILLAGE + Vector3(5.5, 0, -7.5), "yaw": 210, "model": "people/woman_casual", "child": true,
			"colors": {"Shirt": Color(0.75, 0.3, 0.25), "Pants": Color(0.3, 0.3, 0.42), "Hair": Color(0.62, 0.4, 0.2)}, "pitch": 1.08},
	]


## People who come and go with the story (see Story.refresh_npcs). "static": an npc above who moves.
func story_npcs() -> Array:
	return [
		{"id": "stepan", "name": "Guard Stepan", "title": "Northvale Guard", "model": "people/man1",
			"colors": {"Shirt": Color(0.42, 0.44, 0.48), "Shirt2": Color(0.55, 0.12, 0.1), "Pants": Color(0.22, 0.2, 0.18), "Hair": Color(0.3, 0.2, 0.1)},
			"places": [
				{"if": "done:nv_missing", "pos": GUARD_POST + Vector3(-4.0, 0, -4.5), "yaw": -60},
				{"if": "ready:nv_missing", "pos": GUARD_POST + Vector3(-5.5, 0, 2.6), "yaw": -100},
				{"if": "active:nv_missing", "pos": SHELTER + Vector3(1.2, 0, -1.5), "yaw": 140, "pose": "Crouch_Idle"},
			]},
		# everyone comes to the church once the east road has been checked
		{"id": "brannock", "static": true, "places": [{"if": "ready:nv_road_east", "pos": CHURCH + Vector3(3.5, 0, 24.5), "yaw": 150}]},
		{"id": "vesper", "static": true, "places": [{"if": "ready:nv_road_east", "pos": CHURCH + Vector3(10.0, 0, 21.5), "yaw": 230}]},
	]


## Places for the story's clues (y > 0.5: that high above the ground).
func clue_spots() -> Dictionary:
	var c := CEMETERY
	return {
		"grey_wolf": Vector3(-20, 0, -60),
		"grave_1": c + Vector3(-8.0, 0, -1.0), "grave_2": c + Vector3(-3.0, 0, -3.4), "grave_3": c + Vector3(4.0, 0, -1.0),
		"yard_niche": c + Vector3(9.6, 0.7, -5.2), "yard_branch": c + Vector3(-12.0, 1.0, -7.6), "yard_prints": Vector3(6, 0, -172.5),
		"yard_mushrooms": c + Vector3(12.4, 0, -7.4),
		"foreman_shard": MINE + Vector3(-36, 0, 2),
		"black_cloth": EAST_GATE + Vector3(5.5, 1.5, 5.0), "barricade": EAST_GATE + Vector3(11.0, 0, 0.5),
		"vesper_page_1": c + Vector3(13.5, 0, -10.6), "vesper_page_2": OAK + Vector3(-2.8, 0, 2.6),
		# optional clues (always there)
		"vesper_cloth": _lt(Vector3(0.8, 0, -0.6)), "vesper_map": _lt(Vector3(-1.0, 1.25, -1.45)),
		"records": CHURCH + Vector3(8.1, 1.0, -9.0), "prayer_book": CHURCH + Vector3(-3.0, 1.15, -24.5),
		"notice_board": VILLAGE + Vector3(-9.0, 1.4, -4.6), "guard_map": _gp(Vector3(-0.5, 1.0, 0.3)),
		"broken_shield": _gp(Vector3(1.8, 0.9, 1.5)), "granary_stain": GRANARY + Vector3(-3.15, 1.6, 1.0),
	}


## A point of VesPer's lean-to / Brannock's guard post given in the building's own frame.
func _lt(p: Vector3) -> Vector3:
	return VESPER + p.rotated(Vector3.UP, deg_to_rad(15.0))


func _gp(p: Vector3) -> Vector3:
	return GUARD_POST + p.rotated(Vector3.UP, deg_to_rad(-90.0))


## Fixed points for scripted moments.
func story_points() -> Dictionary:
	return {"bell": CHURCH + Vector3(-11.5 * S, 15.4 * S, 3 * S), "flight_from": VESPER + Vector3(0, 0, 3), "flight_to": EAST_GATE + Vector3(12, 0, 0)}


func quests() -> Array:
	var c := CEMETERY
	var yard_aim := GUARD_POST + Vector3(1, 0, 13.5)
	return [
		{"id": "nv_stranger", "giver": "brannock", "title": "The Stranger in the Meadow", "auto": true, "xp": 150,
			"hint": "Follow the waypoint to the guard post on the south road.",
			"steps": [
				{"type": "goto", "pos": GUARD_POST + Vector3(-5, 0, 0), "radius": 9.0, "label": "Reach the guard post"},
				{"type": "talk", "npc": "brannock", "convo": "brannock_meet", "label": "Talk to Sergeant Brannock"},
				{"type": "shoot", "label": "Practice targets hit", "face": yard_aim,
					"targets": [GUARD_POST + Vector3(9, 0, 8), GUARD_POST + Vector3(11.5, 0, 11), GUARD_POST + Vector3(8.5, 0, 13.5),
						GUARD_POST + Vector3(11.5, 0, 16.5), GUARD_POST + Vector3(9, 0, 19)]},
			],
			"convo": {"done": "stranger_done"}, "lines": {"offer": "brannock_meet_1", "done": "stranger_done_1"},
			"reward": {"gold": 10, "ammo": 60, "consumables": {"bandage": 2}}},
		{"id": "nv_wolves", "giver": "aldric", "title": "Wolves at the Door", "requires": ["nv_stranger"], "xp": 300,
			"steps": [
				{"type": "kill", "target": "wolf", "count": 5, "label": "Timber Wolves slain"},
				{"type": "spawn_kill", "label": "Hunt the grey-muzzled wolf", "spawn": [{"type": "wolf", "pos": Vector3(-22, 0, -58), "name": "Grey-Muzzled Wolf", "levels": 1}]},
				{"type": "inspect", "clues": ["grey_wolf"], "label": "Examine the dead wolf"},
			],
			"convo": {"offer": "wolves_offer", "done": "wolves_done"}, "lines": {"offer": "nv_wolves_offer", "done": "nv_wolves_done"},
			"reward": {"materials": {"hide": 3}, "consumables": {"health_potion": 1}}},
		{"id": "nv_grain", "giver": "maybell", "title": "The Lost Harvest", "requires": ["nv_stranger"], "xp": 300,
			"steps": [{"type": "gather", "item": "Sack of Grain", "count": 5,
				"spots": [{"pos": GRANARY + Vector3(-0.5, 0, -5.5), "note": "grey_sack"}, Vector3(118, 0, 3), FARM + Vector3(22, 0, 14),
					FARM + Vector3(4, 0, -30), FARM + Vector3(-12, 0, 13)]}],
			"convo": {"offer": "grain_offer", "done": "grain_done"}, "lines": {"offer": "nv_grain_offer", "done": "nv_grain_done"},
			"reward": {"gold": 35, "consumables": {"health_potion": 2}}},
		{"id": "nv_letter", "giver": "maybell", "to": "aldric", "title": "A Letter for the Church", "type": "deliver", "item": "Sealed Letter", "xp": 200,
			"requires": ["nv_grain"],
			"convo": {"offer": "letter_offer", "done": "letter_done"}, "lines": {"offer": "nv_letter_offer", "done": "nv_letter_done"},
			"reward": {"consumables": {"health_potion": 1, "bandage": 2}}},
		{"id": "nv_churchyard", "giver": "aldric", "title": "The Churchyard That Would Not Sleep", "requires": ["nv_wolves", "nv_letter"], "xp": 450,
			"steps": [
				{"type": "inspect", "clues": ["grave_1", "grave_2", "grave_3"], "label": "Open graves inspected"},
				{"type": "inspect", "clues": ["yard_niche", "yard_branch", "yard_prints"], "label": "Traces of the black residue"},
				{"type": "inspect", "clues": ["yard_mushrooms"], "label": "Search by the rear wall"},
				{"type": "spawn_kill", "label": "Blighted wolves slain",
					"spawn": [{"type": "wolf", "pos": c + Vector3(14, 0, -16), "name": "Blighted Timber Wolf", "levels": 1, "aggro": true},
						{"type": "wolf", "pos": c + Vector3(18, 0, -12), "name": "Blighted Timber Wolf", "levels": 1, "aggro": true}]},
			],
			"convo": {"offer": "churchyard_offer", "done": "churchyard_done"}, "lines": {"offer": "nv_churchyard_offer", "done": "nv_churchyard_done"},
			"reward": {"gold": 30}, "flags": ["church_key"]},
		{"id": "nv_candles", "giver": "aldric", "title": "Candles for the Altar", "requires": ["nv_churchyard"], "xp": 400,
			"steps": [
				{"type": "collect", "target": "kobold", "item": "Church Candle", "count": 6, "chance": 0.8},
				{"type": "spawn_kill", "label": "Kobold Foreman slain", "spawn": [{"type": "kobold", "pos": MINE + Vector3(-37, 0, 1), "name": "Kobold Foreman", "elite": true}]},
				{"type": "inspect", "clues": ["foreman_shard"], "label": "Search the foreman"},
			],
			"convo": {"offer": "candles_offer", "done": "candles_done"}, "lines": {"offer": "nv_candles_offer", "done": "nv_candles_done"},
			"reward": {"materials": {"scrap": 3, "cloth": 2}}},
		{"id": "nv_bandana", "giver": "brannock", "title": "The Red Bandanas", "requires": ["nv_stranger"], "xp": 350,
			"steps": [{"type": "collect", "target": "bandit", "item": "Red Bandana", "count": 6, "chance": 0.7}],
			"convo": {"offer": "bandana_offer", "done": "bandana_done"}, "lines": {"offer": "nv_bandana_offer", "done": "nv_bandana_done"},
			"reward": {"gold": 40, "item": ["armor", "", 1]}},
		{"id": "nv_missing", "giver": "brannock", "title": "The Missing Guard", "requires": ["nv_bandana"], "xp": 400,
			"steps": [
				{"type": "goto", "pos": SHELTER, "radius": 16.0, "label": "Search the old mining track"},
				{"type": "spawn_kill", "label": "Attackers driven off",
					"spawn": [{"type": "kobold", "pos": SHELTER + Vector3(8, 0, 6), "aggro": true}, {"type": "kobold", "pos": SHELTER + Vector3(-7, 0, 7), "aggro": true},
						{"type": "kobold", "pos": SHELTER + Vector3(4, 0, -9), "aggro": true}, {"type": "wolf", "pos": SHELTER + Vector3(12, 0, -3), "aggro": true},
						{"type": "wolf", "pos": SHELTER + Vector3(-10, 0, -6), "aggro": true}]},
				{"type": "talk", "npc": "stepan", "convo": "stepan_found", "label": "Talk to the wounded guard"},
				{"type": "gather", "item": "Patrol Badge", "count": 1, "spots": [SHELTER + Vector3(-5.5, 0, 3.0)]},
			],
			"convo": {"offer": "missing_offer", "done": "missing_done"}, "lines": {"offer": "nv_missing_offer", "done": "nv_missing_done"},
			"reward": {"gold": 30}, "flags": ["guard_token"]},
		{"id": "nv_ledger", "giver": "brannock", "title": "The Captain's Ledger", "requires": ["nv_missing"], "xp": 450,
			"steps": [
				{"type": "goto", "pos": CAMP + Vector3(-4, 0, -24), "radius": 10.0, "label": "Scout the Red Bandana camp"},
				{"type": "gather", "item": "Captain's Ledger", "count": 1, "spots": [{"pos": CAMP + Vector3(-9.0, 1.0, -7.4), "note": "ledger_entry"}]},
			],
			"convo": {"offer": "ledger_offer", "done": "ledger_done"}, "lines": {"offer": "nv_ledger_offer", "done": "nv_ledger_done"},
			"reward": {"gold": 25}, "flags": ["camp_key"]},
		{"id": "nv_captain", "giver": "brannock", "title": "The Captain's Last Stand", "requires": ["nv_ledger"], "xp": 700,
			"steps": [{"type": "boss", "target": "captain", "boss_pos": CAMP + Vector3(0, 0, 3), "label": "Red Bandana Captain slain"}],
			"convo": {"offer": "captain_offer", "done": "captain_done"}, "lines": {"offer": "nv_captain_offer", "done": "nv_captain_done"},
			"reward": {"gold": 80, "item": ["weapon", "", 2]}, "flags": ["captain_dead"]},
		{"id": "nv_road_east", "giver": "aldric", "title": "The Road East", "requires": ["nv_captain"], "xp": 500, "portal": true,
			"steps": [
				{"type": "goto", "pos": EAST_GATE, "radius": 12.0, "label": "Check the east road"},
				{"type": "spawn_kill", "label": "Blighted wolves slain",
					"spawn": [{"type": "wolf", "pos": EAST_GATE + Vector3(6, 0, -13), "name": "Blighted Timber Wolf", "levels": 1, "aggro": true},
						{"type": "wolf", "pos": EAST_GATE + Vector3(8, 0, 11), "name": "Blighted Timber Wolf", "levels": 1, "aggro": true},
						{"type": "wolf", "pos": EAST_GATE + Vector3(2, 0, 15), "name": "Blighted Timber Wolf", "levels": 1, "aggro": true},
						{"type": "wolf", "pos": EAST_GATE + Vector3(-3, 0, -16), "name": "Blighted Timber Wolf", "levels": 1, "aggro": true}]},
				{"type": "inspect", "clues": ["black_cloth", "barricade"], "label": "Search the blocked gate"},
			],
			"convo": {"offer": "road_offer", "done": "road_done"}, "lines": {"offer": "nv_road_offer", "done": "nv_road_done"},
			"reward": {"gold": 60, "consumables": {"health_potion": 2}}},
		{"id": "vesper_drone", "giver": "vesper", "title": "Drone in the Treetops", "requires": ["nv_stranger"], "xp": 300,
			"steps": [{"type": "gather", "item": "FPV Drone", "count": 1, "spots": [_drone_spot]}],
			"convo": {"offer": "drone_offer", "done": "drone_done"}, "lines": {"offer": "vesper_drone_offer", "done": "vesper_drone_done"},
			"reward": {"gadgets": {"fpv_drone": 1}}},
		{"id": "vesper_battery", "giver": "vesper", "title": "Fresh Batteries", "requires": ["vesper_drone"], "xp": 350,
			"steps": [{"type": "gather", "item": "Drone Battery", "count": 4,
				"spots": [CAMP + Vector3(3.6, 0.95, -10.4), {"pos": CAMP + Vector3(5.0, 0.95, -10.4), "note": "battery_mark"},
					CAMP + Vector3(6.6, 0, -9.0), CAMP + Vector3(4.2, 0, -8.6)]}],
			"convo": {"offer": "battery_offer", "done": "battery_done"}, "lines": {"offer": "vesper_battery_offer", "done": "vesper_battery_done"},
			"reward": {"materials": {"essence": 1, "scrap": 3}}},
		{"id": "vesper_notebook", "giver": "vesper", "title": "The Farmer's Notebook", "requires": ["vesper_drone", "nv_bandana"], "xp": 350,
			"steps": [
				{"type": "inspect", "clues": ["vesper_page_1", "vesper_page_2"], "label": "Pages found"},
				{"type": "gather", "item": "VesPer's Notebook", "count": 1, "spots": [{"pos": _lt(Vector3(-2.6, 0, 3.6)), "note": "notebook_entries"}]},
			],
			"convo": {"offer": "notebook_offer", "done": "notebook_done"}, "lines": {"offer": "vesper_notebook_offer", "done": "vesper_notebook_done"},
			"reward": {"gold": 20}},
		{"id": "vesper_lesson", "giver": "vesper", "title": "A Lesson in Survival", "requires": ["vesper_battery"], "xp": 350,
			"steps": [{"type": "gather", "item": "Parts", "count": 3, "label": "Parts found",
				"spots": [{"pos": MINE + Vector3(16, 0, 6), "item": "Strip of Metal"}, {"pos": VILLAGE + Vector3(6.2, 0, 3.0), "item": "Length of Cord"},
					{"pos": OAK + Vector3(3.2, 0, 2.8), "item": "Piece of Wood"}]}],
			"convo": {"offer": "lesson_offer", "done": "lesson_done"}, "lines": {"offer": "vesper_lesson_offer", "done": "vesper_lesson_done"},
			"reward": {"gadgets": {"fpv_drone": 2}}},
	]


func pois() -> Array:
	return [["statue", Vector3(-56, 0, -20), 30.0], ["arch", Vector3(190, 0, 50), 90.0], ["camp", Vector3(-176, 0, -64), 0.0],
		["ruin", Vector3(60, 0, 180), 15.0], ["cart", Vector3(-60, 0, 84), 60.0], ["obelisk", Vector3(215, 0, 215), 20.0],
		["camp", Vector3(200, 0, 60), 200.0], ["ruin", Vector3(-215, 0, -215), 40.0], ["statue", Vector3(110, 0, -215), 160.0], ["cart", Vector3(-160, 0, 110), 120.0]]


func layout(w: Node3D) -> void:
	for p in pois():
		var pp: Vector3 = p[1]
		w.add_zone(Vector2(pp.x, pp.z), 8.0)
	var cross := Vector2(0, 26)
	var s1 := Vector2(0, 96)
	var j := Vector2(0, -24)
	var gate := Vector2(0, -60)
	# the main road comes in from the south past the guard post and the well
	w.add_path(Vector2(0, 262), s1)
	w.add_path(s1, cross)
	w.add_path(cross, j)
	w.add_path(j, gate)
	w.add_path(gate, Vector2(0, -90))
	# round the church to the cemetery behind it
	w.add_path(Vector2(0, -90), Vector2(30, -96), 2.2)
	w.add_path(Vector2(30, -96), Vector2(33, -150), 2.2)
	w.add_path(Vector2(33, -150), Vector2(20, -175), 2.2)
	w.add_path(Vector2(20, -175), Vector2(4, -178), 2.2)
	# east: the farm road past the granary to Maybell's, then the blocked road to Darkwood
	w.add_path(cross, Vector2(60, 26))
	w.add_path(Vector2(60, 26), Vector2(GRANARY.x - 4, GRANARY.z + 6))
	w.add_path(Vector2(GRANARY.x - 4, GRANARY.z + 6), Vector2(FARM.x - 18, FARM.z + 4))
	w.add_path(Vector2(FARM.x + 14, FARM.z), Vector2(EAST_GATE.x, EAST_GATE.z))
	w.add_path(Vector2(EAST_GATE.x, EAST_GATE.z), Vector2(EAST_GATE.x + 26, EAST_GATE.z - 3), 2.6)
	w.add_path(Vector2(FARM.x + 4, FARM.z - 18), Vector2(TOWER.x - 6, TOWER.z + 14), 2.2)
	# west: the narrow mine track
	w.add_path(cross, Vector2(-70, 30))
	w.add_path(Vector2(-70, 30), Vector2(-144, 20), 2.6)
	# south-east to the bandit camp, south-west to the den
	w.add_path(s1, Vector2(92, 144))
	w.add_path(s1, Vector2(-84, 152))
	# north-west: an old track to the crypt
	w.add_path(j, Vector2(-60, -70), 2.2)
	w.add_path(Vector2(-60, -70), Vector2(-60, -168), 2.2)
	# a faint trail to VesPer's lean-to
	w.add_path(Vector2(6, -62), Vector2(VESPER.x - 3, VESPER.z + 5), 1.4)
	for z in [[Vector2(0, -100), 38.0], [Vector2(MINE.x, MINE.z), 24.0], [Vector2(CAMP.x, CAMP.z), 21.0], [Vector2(DEN.x, DEN.z), 14.0],
			[Vector2(TOWER.x, TOWER.z), 14.0], [Vector2(FARM.x, FARM.z), 22.0], [Vector2(GRANARY.x, GRANARY.z), 9.0],
			[Vector2(CEMETERY.x, CEMETERY.z), 19.0], [Vector2(GUARD_POST.x + 3, GUARD_POST.z + 8), 15.0], [Vector2(VESPER.x, VESPER.z), 6.5],
			[Vector2(SHELTER.x, SHELTER.z), 8.0], [Vector2(EAST_GATE.x, EAST_GATE.z), 12.0], [Vector2(START.x, START.z), 9.0], [cross, 8.0]]:
		w.add_zone(z[0], z[1])
	w.add_zone(Vector2(OAK.x, OAK.z), 9.0)
	w.add_zone(Vector2(CHURCH.x, CHURCH.z - 18.0), 31.0)   # the church runs back behind its courtyard
	w.add_zone(Vector2(CHURCH.x, CHURCH.z - 40.0), 22.0)
	w.add_zone(Vector2(MINE.x - 34, MINE.z), 16.0)   # the cave chamber under the hill
	w.paint_circle(Vector2(MINE.x - 34, MINE.z), 11.5, 0)
	w.paint_rect(Rect2(MINE.x - 26, MINE.z - 3, 24, 6), 0)
	w.add_landmark("Old Oak", Vector2(OAK.x, OAK.z), 6.0, Color(0.35, 0.55, 0.25))
	w.add_lake(Vector2(LAKE.x, LAKE.z), 13.0, 2.8)
	village = Village.plan(w, VILLAGE, "town", 6, 9, "Northvale", 11)
	village.staff = {
		"tavern": {"id": "marta", "name": "Marta", "title": "The Crooked Ladle", "model": "people/woman_dress",
			"colors": {"Dress": Color(0.45, 0.24, 0.18), "Hair": Color(0.32, 0.2, 0.12)}},
		"blacksmith": {"id": "danylo", "name": "Danylo", "title": "Smith", "model": "people/worker", "shop": "weapons",
			"colors": {"Shirt": Color(0.3, 0.27, 0.24), "Pants": Color(0.2, 0.18, 0.16), "Hair": Color(0.15, 0.1, 0.06)}},
	}
	w.paint_rect(Rect2(CHURCH.x - 21.5, CHURCH.z + 7.8, 43, 23.4), 1)
	w.paint_rect(Rect2(FARM.x + 8, FARM.z + 8, 26, 22), 2)
	w.add_landmark("Saint Shkvarok Church", Vector2(CHURCH.x, CHURCH.z + 8), 16.0, Color(0.85, 0.82, 0.7))
	w.add_landmark("Cemetery", Vector2(CEMETERY.x, CEMETERY.z), 12.0, Color(0.6, 0.62, 0.58))
	w.add_landmark("Guard Post", Vector2(GUARD_POST.x, GUARD_POST.z), 7.0, Color(0.7, 0.3, 0.25))
	w.add_landmark("Maybell's Farm", Vector2(FARM.x, FARM.z), 12.0, Color(0.8, 0.65, 0.35))
	w.add_landmark("Granary", Vector2(GRANARY.x, GRANARY.z), 5.0, Color(0.8, 0.7, 0.45))
	w.add_landmark("Old Mine", Vector2(MINE.x + 2, MINE.z), 13.0, Color(0.55, 0.45, 0.3))
	w.add_landmark("Red Bandana Camp", Vector2(CAMP.x, CAMP.z), 14.0, Color(0.75, 0.25, 0.2))
	w.add_landmark("Wolf Den", Vector2(DEN.x, DEN.z), 9.0, Color(0.5, 0.5, 0.5))
	w.add_landmark("Old Tower", Vector2(TOWER.x, TOWER.z), 9.0, Color(0.6, 0.5, 0.7))
	w.add_landmark("Mirror Lake", Vector2(LAKE.x, LAKE.z), 13.0, Color(0.3, 0.5, 0.8))
	w.add_landmark("East Gate", Vector2(EAST_GATE.x, EAST_GATE.z), 8.0, Color(0.45, 0.4, 0.35))
	w.plan_feature("ruined_castle", Vector3(200, 0, 150), 16.0, "Ruined Keep")
	w.plan_feature("crypt", Vector3(-60, 0, -180), 10.0, "Old Crypt")
	w.plan_feature("sawmill", Vector3(-96, 0, 64), 7.0)


func spawns() -> Array:
	var m := MINE
	var d := DEN
	var c := CAMP
	var t := TOWER
	var f := FARM
	return [
		# kobold scavengers in and around the old mine
		["kobold", m + Vector3(5, 0, -5)], ["kobold", m + Vector3(8, 0, 4)], ["kobold", m + Vector3(12, 0, -2)], ["kobold", m + Vector3(10, 0, -9)],
		["kobold", m + Vector3(-14, 0, 0.8)], ["kobold", m + Vector3(-31, 0, 5)], ["kobold", m + Vector3(-37, 0, -4)], ["kobold", m + Vector3(-39, 0, 2)],
		["kobold", m + Vector3(-34, 0, -1)], ["kobold", m + Vector3(16, 0, 7)],
		# timber wolves: the den, the church road, the field edges
		["wolf", d + Vector3(3, 0, 2)], ["wolf", d + Vector3(-4, 0, -3)], ["wolf", d + Vector3(1, 0, -6)], ["wolf", d + Vector3(6, 0, -4)],
		["wolf", Vector3(-34, 0, -48)], ["wolf", Vector3(-38, 0, -44)], ["wolf", Vector3(30, 0, -36)], ["wolf", Vector3(-46, 0, -12)],
		["wolf", f + Vector3(24, 0, -34)], ["wolf", f + Vector3(28, 0, -30)], ["wolf", Vector3(118, 0, 40)],
		["wolf", Vector3(-160, 0, -30)], ["wolf", Vector3(-156, 0, -26)], ["wolf", Vector3(40, 0, 200)], ["wolf", Vector3(44, 0, 204)],
		["wolf", t + Vector3(4, 0, 6)], ["wolf", t + Vector3(-5, 0, 3)],
		# the Red Bandanas: the camp and their lookouts on the roads
		["bandit", c + Vector3(-3, 0, -2)], ["bandit", c + Vector3(3, 0, 3)], ["bandit", c + Vector3(-4, 0, 4)], ["bandit", c + Vector3(5, 0, -3)],
		["bandit", c + Vector3(0, 0, -9)], ["bandit", c + Vector3(-1, 0, 10)], ["bandit", c + Vector3(-3, 0, 6)],
		["bandit", Vector3(196, 0, 56)], ["bandit", Vector3(204, 0, 64)], ["bandit", Vector3(-164, 0, 114)], ["bandit", Vector3(-156, 0, 106)],
		["bandit", Vector3(92, 0, 132)], ["bandit", t + Vector3(0, 0, -6)],
	]


func barrels() -> Array:
	return [MINE + Vector3(8, 0, -7), MINE + Vector3(10, 0, 10), CAMP + Vector3(-6, 0, -11), CAMP + Vector3(5, 0, 10),
		CAMP + Vector3(-11, 0, 3), TOWER + Vector3(5, 0, -4), FARM + Vector3(-17, 0, -9)]


func build(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	_church(w, CHURCH)
	_cemetery(w, CEMETERY, rng)
	_mine(w, MINE, rng)
	_camp(w, CAMP, rng)
	_den(w, DEN, rng)
	_tower(w, TOWER, rng)
	_farm(w, FARM, rng)
	_granary(w, GRANARY, rng)
	_guard_post(w, GUARD_POST)
	_lean_to(w, VESPER, rng)
	_ruined_shelter(w, SHELTER, rng)
	_east_gate(w, EAST_GATE, rng)
	_notice_board(w, VILLAGE + Vector3(-9.4, 0, -4.8), 64.0)
	var top := Props.climb_tree(w, OAK, TREE_PLATFORM, 125.0)
	var out := Vector2(top.x - OAK.x, top.z - OAK.z).normalized() * 0.7
	_drone_spot = Vector3(top.x + out.x, TREE_PLATFORM + 0.05, top.z + out.y)
	Props.water(w, LAKE, 13.0, -0.7, Color(0.08, 0.25, 0.32), Color(0.3, 0.55, 0.55))
	# fishing dock
	var dock := Props.pivot(w, LAKE + Vector3(-12, 0, 6), 60)
	MeshKit.static_box(dock, Vector3(2.0, 0.2, 7), Vector3(0, 0.1, 3), Props.wood())
	for z in [1.0, 3.5, 6.0]:
		MeshKit.cyl(dock, 0.12, 0.12, 2.0, Vector3(0.9, -0.6, z), Props.dark_wood())
		MeshKit.cyl(dock, 0.12, 0.12, 2.0, Vector3(-0.9, -0.6, z), Props.dark_wood())
	village.build(w)


# --------------------------------------------------------------------------- Saint Shkvarok Church

func _church(w: Node3D, o: Vector3) -> void:
	var stone := Props.stone(Color(1.12, 1.06, 0.94), 0.28)
	var stone_dark := Props.stone(Color(0.88, 0.84, 0.78), 0.28)
	var roof := Props.roof(Color(0.5, 0.62, 1.35))
	var gold := MeshKit.mat(Color(0.95, 0.75, 0.25), 0.4, 0.6)
	var dark := MeshKit.mat(Color(0.06, 0.06, 0.08))
	var n := Props.pivot(w, o)

	# the church: its west front faces the courtyard, the rest runs back behind it
	GothicChurch.place(w, o + Vector3(0, 0, 6.0 * S))
	w.building_areas.append([Vector2(o.x, o.z), 13.0])

	# the squat bell tower (front-left) with its old crack, mended in mismatched stone
	MeshKit.static_box(n, Vector3(5, 18, 5), Vector3(-11.5, 9, 3), stone)
	MeshKit.box(n, Vector3(5.4, 0.6, 5.4), Vector3(-11.5, 13.0, 3), stone_dark)
	MeshKit.box(n, Vector3(5.4, 0.6, 5.4), Vector3(-11.5, 18.0, 3), stone_dark)
	MeshKit.box(n, Vector3(1.8, 2.6, 0.2), Vector3(-11.5, 15.5, 5.55), dark)
	MeshKit.cyl(n, 0.6, 0.9, 1.0, Vector3(-11.5, 15.4, 5.2), gold, Vector3.ZERO, 10)
	MeshKit.cyl(n, 0.0, 4.0, 7.0, Vector3(-11.5, 21.8, 3), roof, Vector3(0, 45, 0), 4)
	MeshKit.cyl(n, 0.05, 0.05, 1.5, Vector3(-11.5, 26.0, 3), gold)
	var patch := Props.stone(Color(0.72, 0.7, 0.66), 0.5)
	for i in 7:
		MeshKit.box(n, Vector3(0.55, 0.4, 0.08), Vector3(-9.2 - (i % 2) * 0.3, 3.0 + i * 1.3, 5.53), patch, Vector3(0, 0, -12 + (i % 3) * 9))

	# round crenellated keep (back-right)
	var keep := Vector3(13, 0, -5)
	var cs := CylinderShape3D.new()
	cs.radius = 3.6
	cs.height = 17.0
	var kb := StaticBody3D.new()
	kb.position = keep + Vector3(0, 8.5, 0)
	var kcs := CollisionShape3D.new()
	kcs.shape = cs
	kb.add_child(kcs)
	n.add_child(kb)
	MeshKit.cyl(n, 3.4, 3.7, 17.0, keep + Vector3(0, 8.5, 0), stone, Vector3.ZERO, 20)
	MeshKit.cyl(n, 4.1, 3.6, 1.2, keep + Vector3(0, 17.4, 0), stone_dark, Vector3.ZERO, 20)
	for i in 12:
		var a := TAU * i / 12.0
		MeshKit.box(n, Vector3(1.0, 1.2, 0.8), keep + Vector3(cos(a) * 3.8, 18.6, sin(a) * 3.8), stone, Vector3(0, -rad_to_deg(a), 0))
	for h in [5.0, 9.5, 14.0]:
		MeshKit.box(n, Vector3(0.6, 1.4, 0.3), keep + Vector3(0, h, 3.65), dark)

	# side wing (the priest's quarters)
	MeshKit.static_box(n, Vector3(8, 6, 8), Vector3(-1.0 - 13, 3, -2), stone)
	MeshKit.prism(n, Vector3(9, 3.5, 8.8), Vector3(-14, 7.75, -2), roof)

	# courtyard railings with an iron gate, and the fountain
	var cx := 17.0 * S
	var front := o.z + 24.0 * S
	var back := o.z + 6.0 * S
	for s in [-1.0, 1.0]:
		IronFence.run(w, Vector3(o.x + s * cx, 0, back), Vector3(o.x + s * cx, 0, front), true, false)
		IronFence.run(w, Vector3(o.x + s * cx, 0, front), Vector3(o.x + s * 2.95, 0, front), true, false)
	IronFence.gate(w, Vector3(o.x, 0, front), 0.0, 4.4)
	_churchyard(w, o + Vector3(0, 0, 6.0 * S))
	Props.lantern(w, o + Vector3(-4.8, 0, 25.6) * S)
	Props.lantern(w, o + Vector3(4.8, 0, 25.6) * S)
	MeshKit.static_cyl(n, 2.6, 0.9, Vector3(0, 0.45, 15), stone_dark, 16)
	MeshKit.cyl(n, 2.3, 2.3, 0.1, Vector3(0, 0.86, 15), MeshKit.mat(Color(0.25, 0.5, 0.75), 0.1, 0.2), Vector3.ZERO, 16)
	MeshKit.cyl(n, 0.3, 0.35, 2.2, Vector3(0, 1.6, 15), stone)
	MeshKit.cyl(n, 0.9, 0.4, 0.4, Vector3(0, 2.8, 15), stone, Vector3.ZERO, 12)
	MeshKit.sphere(n, 0.25, Vector3(0, 3.2, 15), gold)
	for p in [Vector3(-15, 0, 9), Vector3(-15, 0, 10.2), Vector3(-13.8, 0, 9.4)]:
		Props.crate(w, o + p * S, randf_range(0, 40))
	Props.barrel(w, o + Vector3(15, 0, 8.5) * S)
	Props.barrel(w, o + Vector3(15.2, 0, 10) * S)
	Props.hay_bale(w, o + Vector3(14.5, 0, 19) * S)
	n.scale = Vector3.ONE * S
	# the faded sign by the gate
	_sign(w, o + Vector3(4.2, 0, 24.0 * S + 0.6), 0.0, "Церква святого Шкварка")
	# inside: the records cabinet in the south aisle and the lectern by the crossing
	var cab := Props.pivot(w, o + Vector3(8.7, 0, -9.0), -90)
	MeshKit.static_box(cab, Vector3(1.6, 2.0, 0.6), Vector3(0, 1.0, 0), Props.dark_wood())
	MeshKit.box(cab, Vector3(0.75, 1.7, 0.04), Vector3(-0.39, 1.0, 0.31), Props.wood())
	MeshKit.box(cab, Vector3(0.75, 1.7, 0.04), Vector3(0.39, 1.0, 0.31), Props.wood())
	MeshKit.box(cab, Vector3(0.12, 0.16, 0.05), Vector3(0, 1.05, 0.34), MeshKit.mat(Color(0.3, 0.28, 0.25), 0.4, 0.8))
	var lec := Props.pivot(w, o + Vector3(-3.0, 0, -24.5), 180)
	MeshKit.static_cyl(lec, 0.14, 1.0, Vector3(0, 0.5, 0), Props.dark_wood(), 8)
	MeshKit.box(lec, Vector3(0.6, 0.06, 0.45), Vector3(0, 1.08, 0), Props.dark_wood(), Vector3(-18, 0, 0))
	MeshKit.box(lec, Vector3(0.52, 0.08, 0.38), Vector3(0, 1.14, 0.0), MeshKit.mat(Color(0.35, 0.12, 0.08)), Vector3(-18, 0, 0))


## A small painted wooden sign on a post.
func _sign(w: Node3D, p: Vector3, yaw: float, text: String) -> void:
	var n := Props.pivot(w, p, yaw)
	MeshKit.static_box(n, Vector3(0.12, 1.4, 0.12), Vector3(0, 0.7, 0), Props.dark_wood())
	MeshKit.box(n, Vector3(1.5, 0.45, 0.06), Vector3(0, 1.3, 0.08), MeshKit.mat(Color(0.62, 0.5, 0.36)))
	var l := Label3D.new()
	l.text = text
	l.font_size = 30
	l.pixel_size = 0.0042
	l.modulate = Color(0.22, 0.14, 0.08)
	l.outline_size = 0
	l.position = Vector3(0, 1.3, 0.115)
	n.add_child(l)


## A small fenced churchyard beside the church (c: the church's west front, church-local metres):
## rows of headstones, crosses and grave slabs, a chest tomb, a bench and a gate to the east.
func _churchyard(w: Node3D, c: Vector3) -> void:
	var x0 := 12.2
	var x1 := 24.6
	var z0 := -20.2
	var z1 := -28.8
	var gz := (z0 + z1) * 0.5
	var g := 1.655        # half the gateway, piers included
	IronFence.run(w, c + Vector3(x0, 0, z0), c + Vector3(x1, 0, z0))
	IronFence.run(w, c + Vector3(x1, 0, z0), c + Vector3(x1, 0, gz + g), false, false)
	IronFence.run(w, c + Vector3(x1, 0, gz - g), c + Vector3(x1, 0, z1), false, true)
	IronFence.run(w, c + Vector3(x1, 0, z1), c + Vector3(x0, 0, z1), false, true)
	IronFence.run(w, c + Vector3(x0, 0, z1), c + Vector3(x0, 0, z0), false, false)
	IronFence.gate(w, c + Vector3(x1, 0, gz), 90.0, 1.8, 2.0)
	var n := Props.pivot(w, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var stones := _grave_stones()
	var earth := MeshKit.mat(Color(0.26, 0.3, 0.14), 1.0)
	for x in [14.0, 16.5, 19.0, 21.5]:
		for z in [-21.7, -23.9, -26.1]:
			if rng.randf() < 0.12:
				continue
			var p := Vector3(x + rng.randf_range(-0.3, 0.3), 0, z + rng.randf_range(-0.2, 0.2))
			MeshKit.box(n, Vector3(0.8, 0.12, 1.7), p + Vector3(0, 0.06, -0.95), earth)
			_headstone(n, p, stones, rng)
	var tomb: Material = stones[0]
	MeshKit.static_box(n, Vector3(1.1, 0.8, 2.1), Vector3(22.8, 0.4, -27.6), tomb)
	MeshKit.box(n, Vector3(1.25, 0.12, 2.25), Vector3(22.8, 0.86, -27.6), stones[1])
	MeshKit.static_box(n, Vector3(1.6, 0.08, 0.42), Vector3(23.6, 0.45, -21.2), Props.wood())
	for e in [-0.65, 0.65]:
		MeshKit.box(n, Vector3(0.1, 0.45, 0.4), Vector3(23.6 + e, 0.22, -21.2), stones[1])


func _grave_stones() -> Array:
	return [Props.stone(Color(0.78, 0.78, 0.76), 0.6), Props.stone(Color(0.62, 0.64, 0.58), 0.6), Props.rock_mat(Color(0.9, 0.92, 0.85))]


## One grave marker at `p` (the grave runs towards -z): headstone, stone cross or ledger slab.
func _headstone(n: Node3D, p: Vector3, stones: Array, rng: RandomNumberGenerator, kind := -1) -> void:
	var m: Material = stones[rng.randi() % stones.size()]
	var tilt := Vector3(rng.randf_range(-6, 6), rng.randf_range(-8, 8), rng.randf_range(-5, 5))
	if kind < 0:
		kind = rng.randi() % 4
	match kind:
		0, 1:
			var hs := _holder(n, p, tilt)
			MeshKit.static_box(hs, Vector3(0.62, 0.75, 0.13), Vector3(0, 0.37, 0), m)
			MeshKit.cyl(hs, 0.31, 0.31, 0.13, Vector3(0, 0.75, 0), m, Vector3(90, 0, 0), 14)
		2:
			var cr := _holder(n, p, tilt)
			MeshKit.static_box(cr, Vector3(0.4, 0.2, 0.3), Vector3(0, 0.1, 0), m)
			MeshKit.box(cr, Vector3(0.14, 1.2, 0.12), Vector3(0, 0.8, 0), m)
			MeshKit.box(cr, Vector3(0.6, 0.13, 0.12), Vector3(0, 1.1, 0), m)
		3:
			MeshKit.static_box(n, Vector3(0.9, 0.18, 1.9), p + Vector3(0, 0.09, -0.95), m)
			MeshKit.box(n, Vector3(0.5, 0.45, 0.1), p + Vector3(0, 0.4, 0.05), m)
		_:   # a weathered wooden marker
			var wm := _holder(n, p, tilt)
			MeshKit.static_box(wm, Vector3(0.1, 0.9, 0.08), Vector3(0, 0.45, 0), Props.dark_wood())
			MeshKit.box(wm, Vector3(0.5, 0.09, 0.07), Vector3(0, 0.7, 0), Props.dark_wood())


func _holder(n: Node3D, p: Vector3, rot_deg: Vector3) -> Node3D:
	var h := Node3D.new()
	h.position = p
	h.rotation_degrees = rot_deg
	n.add_child(h)
	return h


## The old cemetery behind the church: a low stone wall broken near the rear gate, rows of uneven
## headstones and wooden markers, two family vaults, three graves opened from inside, a dead stump
## with pale mushrooms by the rear wall, and boot prints that cross the grass to the church.
func _cemetery(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var wall := Props.stone(Color(0.78, 0.78, 0.74), 0.45)
	var n := Props.pivot(w, o)
	var hx := 15.0
	var hz := 10.0
	# low dry-stone wall: open at the front (towards the church), the rear gate and a collapsed stretch
	for seg in [[Vector3(-hx, 0, hz), Vector3(-2.2, 0, hz)], [Vector3(2.2, 0, hz), Vector3(hx, 0, hz)],
			[Vector3(-hx, 0, -hz), Vector3(7.5, 0, -hz)], [Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz)],
			[Vector3(hx, 0, -hz + 3.5), Vector3(hx, 0, hz)]]:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		var along_x := absf(b.x - a.x) > absf(b.z - a.z)
		MeshKit.static_box(n, Vector3(length + 0.5 if along_x else 0.5, 0.85, 0.5 if along_x else length + 0.5), mid + Vector3(0, 0.42, 0), wall)
	# the broken corner by the rear gate: fallen stones in the grass
	for i in 6:
		MeshKit.static_box(n, Vector3(rng.randf_range(0.35, 0.6), rng.randf_range(0.25, 0.4), rng.randf_range(0.3, 0.5)),
			Vector3(rng.randf_range(9.0, 14.5), 0.15, -hz + rng.randf_range(-1.2, 1.4)), wall, Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 90), rng.randf_range(-20, 20)))
	for gp in [Vector3(-2.2, 0, hz), Vector3(2.2, 0, hz)]:
		MeshKit.static_box(n, Vector3(0.6, 1.3, 0.6), gp + Vector3(0, 0.65, 0), wall)
	var stones := _grave_stones()
	var grass_dead := MeshKit.mat(Color(0.32, 0.3, 0.18), 1.0)
	var fresh := MeshKit.mat(Color(0.24, 0.17, 0.1), 1.0)
	var pit := MeshKit.mat(Color(0.05, 0.04, 0.03), 1.0)
	var open_graves := [Vector3(-8.0, 0, -1.0), Vector3(-3.0, 0, -3.4), Vector3(4.0, 0, -1.0)]
	for row in 3:
		for col in 9:
			var p := Vector3(-11.5 + col * 2.9 + rng.randf_range(-0.3, 0.3), 0, 6.0 - row * 4.6 + rng.randf_range(-0.3, 0.3))
			var skip := false
			for og: Vector3 in open_graves:
				if p.distance_to(og) < 1.8:
					skip = true
			for vp: Vector3 in [Vector3(9.6, 0, -6.2), Vector3(-11.0, 0, 3.2)]:
				if absf(p.x - vp.x) < 2.4 and p.z - vp.z < 3.6 and p.z - vp.z > -2.4:
					skip = true
			if skip or rng.randf() < 0.15:
				continue
			MeshKit.box(n, Vector3(0.8, 0.1, 1.7), p + Vector3(0, 0.05, -0.95), grass_dead)
			_headstone(n, p, stones, rng, rng.randi() % 5)
			if rng.randf() < 0.3:   # dead flowers
				for k in 3:
					MeshKit.cyl(n, 0.012, 0.012, 0.35, p + Vector3(rng.randf_range(-0.25, 0.25), 0.17, -0.4), MeshKit.mat(Color(0.3, 0.25, 0.15)), Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 25)), 4)
	# the three open graves: a dark pit, heaped fresh earth and the lid shoved aside from below
	for i in open_graves.size():
		var p: Vector3 = open_graves[i]
		_headstone(n, p, stones, rng, 0 if i != 1 else 3)
		MeshKit.box(n, Vector3(0.86, 0.1, 1.76), p + Vector3(0, 0.05, -1.0), pit)
		for side in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.22, 0.2, 2.1), p + Vector3(side * 0.54, 0.1, -1.0), fresh)
			MeshKit.box(n, Vector3(1.3, 0.2, 0.22), p + Vector3(0, 0.1, -1.0 + side * 0.99), fresh)
		MeshKit.static_box(n, Vector3(0.8, 0.45, 1.7), p + Vector3(1.15, 0.2, -1.0), fresh, Vector3(0, 0, 22))
		MeshKit.box(n, Vector3(0.9, 0.12, 1.8), p + Vector3(-0.95, 0.35, -1.1), stones[1], Vector3(4, 12, 62))
		for k in 5:
			MeshKit.sphere(n, rng.randf_range(0.12, 0.22), p + Vector3(rng.randf_range(-0.8, 1.4), 0.05, rng.randf_range(-2.4, 0.4)), fresh, Vector3(1, 0.5, 1))
	# family vaults, one with an open burial niche (black residue inside)
	for v in [[Vector3(9.6, 0, -6.2), true], [Vector3(-11.0, 0, 3.2), false]]:
		var vp: Vector3 = v[0]
		MeshKit.static_box(n, Vector3(2.6, 1.3, 2.2), vp + Vector3(0, 0.65, 0), stones[0])
		MeshKit.box(n, Vector3(2.9, 0.18, 2.5), vp + Vector3(0, 1.36, 0), stones[1])
		MeshKit.prism(n, Vector3(2.9, 0.6, 2.5), vp + Vector3(0, 1.75, 0), stones[1], Vector3(0, 90, 0))
		if v[1]:
			MeshKit.box(n, Vector3(1.0, 0.55, 0.05), vp + Vector3(0, 0.62, 1.11), pit)
			MeshKit.box(n, Vector3(0.9, 0.05, 0.3), vp + Vector3(0, 0.36, 1.2), MeshKit.mat(Color(0.03, 0.03, 0.035), 0.3))
			MeshKit.box(n, Vector3(1.05, 0.6, 0.12), vp + Vector3(1.2, 0.3, 1.5), stones[1], Vector3(0, 30, 75))
	# the broken branch by the rear wall, smeared black
	MeshKit.cyl(n, 0.06, 0.1, 1.6, Vector3(-12.0, 0.9, -7.8), Props.dark_wood(), Vector3(0, 30, 60), 6)
	MeshKit.sphere(n, 0.1, Vector3(-11.6, 1.2, -7.6), MeshKit.mat(Color(0.03, 0.03, 0.03), 0.25), Vector3(1.6, 0.5, 1))
	# the dead stump with pale mushrooms
	var bark := Nature.bark_material(Color(0.75, 0.62, 0.5))
	MeshKit.static_cyl(n, 0.55, 0.9, Vector3(12.6, 0.45, -8.4), bark, 9)
	MeshKit.cyl(n, 0.12, 0.2, 1.2, Vector3(13.2, 0.55, -8.0), bark, Vector3(0, 0, -60), 6)
	var cap := MeshKit.mat(Color(0.86, 0.9, 0.82), 0.6, 0.0, 0.35)
	for k in 7:
		var mp := Vector3(12.6 + rng.randf_range(-0.6, 0.7), 0.0, -8.4 + rng.randf_range(-0.5, 0.8))
		MeshKit.cyl(n, 0.025, 0.03, 0.12, mp + Vector3(0, 0.06, 0), MeshKit.mat(Color(0.9, 0.9, 0.85)), Vector3.ZERO, 5)
		MeshKit.sphere(n, rng.randf_range(0.06, 0.1), mp + Vector3(0, 0.13, 0), cap, Vector3(1, 0.45, 1))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.75, 0.95, 0.85)
	glow.light_energy = 0.35
	glow.omni_range = 2.5
	glow.position = Vector3(12.6, 0.4, -8.0)
	n.add_child(glow)
	# boot prints across the grass towards the church - two different soles
	var print_m := MeshKit.mat(Color(0.12, 0.1, 0.07), 1.0)
	for i in 10:
		var bp := Vector3(10.5 - i * 0.55 + (0.18 if i % 2 == 0 else -0.18), 0.012, 13.0 + i * 0.75)
		MeshKit.box(n, Vector3(0.12, 0.012, 0.27 if i % 3 != 0 else 0.33), bp, print_m, Vector3(0, -35, 0))
	# a gravedigger's spade and a lantern by the front gap
	MeshKit.cyl(n, 0.03, 0.03, 1.3, Vector3(-4.0, 0.62, 10.8), Props.wood(), Vector3(12, 0, 4), 6)
	MeshKit.box(n, Vector3(0.24, 0.3, 0.03), Vector3(-4.08, 0.12, 10.75), MeshKit.mat(Color(0.35, 0.35, 0.36), 0.5, 0.7))
	Props.lantern(w, o + Vector3(3.0, 0, hz + 0.8))


# --------------------------------------------------------------------------- the village's edges

## Brannock's guard post at the south entrance: a squat timber house on a stone base, open to the
## road, with a watch platform and a fenced practice yard behind it.
func _guard_post(w: Node3D, o: Vector3) -> void:
	var n := Props.pivot(w, o, -90.0)       # local +z faces the road (west)
	var stone := Props.stone(Color(0.9, 0.88, 0.82), 0.35)
	var timber := Props.dark_wood()
	var planks := Props.wood()
	var roof := Props.roof(Color(0.5, 0.42, 0.36))
	MeshKit.static_box(n, Vector3(7.0, 0.5, 5.0), Vector3(0, 0.25, 0), stone)
	MeshKit.static_box(n, Vector3(7.0, 3.0, 0.25), Vector3(0, 2.0, -2.4), planks)
	MeshKit.static_box(n, Vector3(0.25, 3.0, 5.0), Vector3(-3.4, 2.0, 0), planks)
	MeshKit.static_box(n, Vector3(0.25, 3.0, 5.0), Vector3(3.4, 2.0, 0), planks)
	for x in [-3.4, 3.4, -1.2, 1.2]:
		MeshKit.static_box(n, Vector3(0.22, 3.2, 0.22), Vector3(x, 2.1, 2.4), timber)
	MeshKit.box(n, Vector3(7.8, 0.18, 6.2), Vector3(0, 3.75, 0.1), roof, Vector3(-11, 0, 0))
	# map table with charcoal drawings
	MeshKit.static_box(n, Vector3(1.8, 0.08, 1.1), Vector3(-0.5, 0.95, 0.0), planks)
	for lx in [-1.3, 0.3]:
		for lz in [-0.45, 0.45]:
			MeshKit.box(n, Vector3(0.08, 0.45, 0.08), Vector3(lx, 0.72, lz), timber)
	MeshKit.box(n, Vector3(1.4, 0.01, 0.8), Vector3(-0.5, 1.0, 0.0), MeshKit.mat(Color(0.86, 0.8, 0.66)))
	for i in 4:
		MeshKit.box(n, Vector3(0.5 + i * 0.1, 0.012, 0.02), Vector3(-0.6 + i * 0.12, 1.006, -0.2 + i * 0.13), MeshKit.mat(Color(0.12, 0.1, 0.09)), Vector3(0, i * 37, 0))
	# weapon rack: spears, axes, two bows
	MeshKit.box(n, Vector3(1.8, 0.1, 0.2), Vector3(2.0, 1.7, -2.2), timber)
	for i in 4:
		MeshKit.cyl(n, 0.025, 0.025, 2.1, Vector3(1.3 + i * 0.45, 1.25, -2.15), planks, Vector3(0, 0, 4), 5)
		if i < 2:
			MeshKit.cyl(n, 0.0, 0.05, 0.25, Vector3(1.3 + i * 0.45, 2.4, -2.15), MeshKit.mat(Color(0.5, 0.5, 0.52), 0.4, 0.8), Vector3.ZERO, 5)
	# the board with a rough drawing of the captain
	MeshKit.box(n, Vector3(1.0, 0.8, 0.04), Vector3(-1.7, 1.9, -2.24), MeshKit.mat(Color(0.82, 0.76, 0.62)))
	MeshKit.sphere(n, 0.17, Vector3(-1.7, 2.0, -2.21), MeshKit.mat(Color(0.15, 0.12, 0.1)), Vector3(1, 1.2, 0.1))
	MeshKit.box(n, Vector3(0.36, 0.06, 0.01), Vector3(-1.7, 2.14, -2.2), MeshKit.mat(Color(0.7, 0.12, 0.1)))
	# two bunks, a cold stove, the confiscation chest
	for bz in [-1.4, 0.9]:
		MeshKit.static_box(n, Vector3(0.9, 0.45, 1.9), Vector3(-2.75, 0.72, bz), timber)
		MeshKit.box(n, Vector3(0.8, 0.12, 1.8), Vector3(-2.75, 1.0, bz), MeshKit.mat(Color(0.55, 0.5, 0.4)))
	MeshKit.static_box(n, Vector3(0.7, 0.9, 0.7), Vector3(2.8, 0.95, 0.6), MeshKit.mat(Color(0.18, 0.18, 0.2), 0.6, 0.5))
	MeshKit.static_box(n, Vector3(1.0, 0.6, 0.6), Vector3(2.6, 0.8, -1.4), timber)
	# the broken shield of the guard who vanished near the mine
	MeshKit.cyl(n, 0.42, 0.42, 0.06, Vector3(1.8, 0.95, 1.5), MeshKit.mat(Color(0.45, 0.3, 0.2)), Vector3(70, 20, 0), 12)
	# red cloth marker by the door
	MeshKit.box(n, Vector3(0.05, 1.0, 0.45), Vector3(3.55, 2.4, 2.45), MeshKit.mat(Color(0.62, 0.12, 0.1)))
	# watch platform beside the house
	var wp := Vector3(-5.6, 0, -1.0)
	for dx in [-1.0, 1.0]:
		for dz in [-1.0, 1.0]:
			MeshKit.static_box(n, Vector3(0.2, 4.4, 0.2), wp + Vector3(dx, 2.2, dz), timber)
	MeshKit.static_box(n, Vector3(2.4, 0.15, 2.4), wp + Vector3(0, 4.2, 0), planks)
	for k in 4:
		var a := k * PI * 0.5
		MeshKit.static_box(n, Vector3(2.4, 0.8, 0.08), wp + Vector3(sin(a) * 1.16, 4.7, cos(a) * 1.16), planks, Vector3(0, rad_to_deg(a) + 90, 0))
	for dx in [-1.0, 1.0]:
		for dz in [-1.0, 1.0]:
			MeshKit.box(n, Vector3(0.14, 2.0, 0.14), wp + Vector3(dx, 5.3, dz), timber)
	MeshKit.cyl(n, 0.0, 2.1, 1.2, wp + Vector3(0, 6.9, 0), roof, Vector3(0, 45, 0), 4)
	for k in 7:
		MeshKit.box(n, Vector3(0.6, 0.06, 0.08), wp + Vector3(0, 0.4 + k * 0.55, 1.15), timber)
	# the practice yard behind (south of) the house
	var y0 := o + Vector3(-1.0, 0, 5.0)
	var y1 := o + Vector3(16.0, 0, 22.0)
	Props.fence(w, Vector3(y0.x, 0, y0.z), Vector3(y1.x, 0, y0.z))
	Props.fence(w, Vector3(y1.x, 0, y0.z), Vector3(y1.x, 0, y1.z))
	Props.fence(w, Vector3(y1.x, 0, y1.z), Vector3(y0.x, 0, y1.z))
	Props.fence(w, Vector3(y0.x, 0, y1.z), Vector3(y0.x, 0, y0.z + 9.0))
	# hay bales behind the targets catch stray shots
	for k in 4:
		Props.hay_bale(w, o + Vector3(14.6, 0, 8.5 + k * 3.4), 90.0)
	# the firing line: a plank on two stones
	var fl := Props.pivot(w, o + Vector3(1.0, 0, 13.5))
	MeshKit.box(fl, Vector3(0.25, 0.06, 2.4), Vector3(0, 0.03, 0), MeshKit.mat(Color(0.85, 0.82, 0.7)))


## VesPer's lean-to near the Old Oak: salvaged planks, a weatherproof sheet, a bedroll, a dented pot,
## a hand-drawn map and a box of drone parts. Bushes and a fallen tree hide it from the road.
func _lean_to(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var n := Props.pivot(w, o, 15.0)
	var planks := Props.wood()
	var timber := Props.dark_wood()
	var sheet := MeshKit.mat(Color(0.3, 0.38, 0.32), 0.9)
	for x in [-1.6, 1.6]:
		MeshKit.static_box(n, Vector3(0.14, 2.2, 0.14), Vector3(x, 1.1, -1.6), timber)
		MeshKit.box(n, Vector3(0.12, 1.0, 0.12), Vector3(x, 0.5, 1.2), timber)
	# back wall of mismatched planks
	for i in 6:
		MeshKit.box(n, Vector3(0.55, 1.9 + rng.randf_range(-0.2, 0.15), 0.06), Vector3(-1.4 + i * 0.56, 0.95, -1.65), planks if i % 2 == 0 else timber)
	MeshKit.collider_box(n, Vector3(3.4, 2.0, 0.2), Vector3(0, 1.0, -1.65))
	# the sheet roof sloping to the front
	MeshKit.box(n, Vector3(3.8, 0.04, 3.4), Vector3(0, 1.6, -0.2), sheet, Vector3(-22, 0, 0))
	# bedroll, pot over a cold fire, the parts box
	MeshKit.box(n, Vector3(0.8, 0.12, 1.9), Vector3(0.8, 0.06, -0.6), MeshKit.mat(Color(0.42, 0.36, 0.26)))
	MeshKit.cyl(n, 0.2, 0.2, 0.75, Vector3(0.8, 0.14, 0.4), MeshKit.mat(Color(0.5, 0.42, 0.3)), Vector3(0, 0, 90), 8)
	MeshKit.cyl(n, 0.22, 0.18, 0.22, Vector3(-0.8, 0.31, 1.6), MeshKit.mat(Color(0.32, 0.32, 0.34), 0.5, 0.6), Vector3(0, 0, 9), 10)
	for k in 5:
		var a := TAU * k / 5.0
		MeshKit.sphere(n, 0.12, Vector3(-0.8 + cos(a) * 0.38, 0.06, 1.6 + sin(a) * 0.38), Props.rock_mat())
	MeshKit.static_box(n, Vector3(0.6, 0.35, 0.45), Vector3(-1.0, 0.18, -0.9), planks)
	MeshKit.box(n, Vector3(0.1, 0.1, 0.06), Vector3(-1.1, 0.4, -0.9), MeshKit.mat(Color(0.85, 0.75, 0.2), 0.4, 0.6))
	MeshKit.box(n, Vector3(0.24, 0.015, 0.03), Vector3(-0.85, 0.38, -0.82), MeshKit.mat(Color(0.12, 0.12, 0.12)), Vector3(0, 30, 0))
	MeshKit.box(n, Vector3(0.24, 0.015, 0.03), Vector3(-0.85, 0.38, -0.82), MeshKit.mat(Color(0.12, 0.12, 0.12)), Vector3(0, -60, 0))
	# the hand-drawn map pinned to the back wall
	MeshKit.box(n, Vector3(0.7, 0.5, 0.01), Vector3(-1.0, 1.25, -1.6), MeshKit.mat(Color(0.86, 0.8, 0.66)))
	MeshKit.box(n, Vector3(0.4, 0.01, 0.012), Vector3(-1.05, 1.3, -1.594), MeshKit.mat(Color(0.7, 0.1, 0.08)), Vector3(0, 0, 25))
	# a fallen tree and bushes towards the road
	var bark := Nature.bark_material(Color(1.1, 0.8, 0.5))
	MeshKit.static_cyl(n, 0.4, 7.0, Vector3(-4.2, 0.4, 2.5), bark, 10).rotation_degrees = Vector3(90, 0, 70)
	var bushes := []
	for k in 7:
		var bp: Vector3 = o + Vector3(-3.5 + rng.randf_range(-1.8, 1.8), 0, 4.2 + rng.randf_range(-1.4, 1.8)).rotated(Vector3.UP, deg_to_rad(15.0))
		bushes.append(Vector3(bp.x, w.ground(bp.x, bp.z), bp.z))
	Nature.plant_bushes(w, bushes, w.cfg["foliage"], rng)


## The ruined shelter on the old mine track where the missing guard hid.
func _ruined_shelter(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	Props.ruined_wall(w, o + Vector3(-3.0, 0, -2.0), 10.0, 6.0, 2.4, rng)
	Props.ruined_wall(w, o + Vector3(2.5, 0, -3.5), 95.0, 4.5, 1.8, rng)
	var n := Props.pivot(w, o)
	for i in 5:
		MeshKit.static_box(n, Vector3(3.2, 0.08, 0.3), Vector3(rng.randf_range(-1.5, 1.5), 0.15 + i * 0.05, rng.randf_range(-1.5, 1.0)), Props.dark_wood(),
			Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 180), rng.randf_range(-8, 8)))
	VBuild.cart(w, o + Vector3(-6.0, 0, 4.5), 120.0)
	MeshKit.box(n, Vector3(0.9, 0.04, 0.5), Vector3(1.6, 0.03, -1.0), MeshKit.mat(Color(0.35, 0.05, 0.04), 0.4))


## The collapsed timber gate on the road east, a fallen tree across it and the dark woods beyond.
func _east_gate(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var n := Props.pivot(w, o + Vector3(11.0, 0, 0), 0.0)
	var timber := Props.dark_wood()
	for z in [-3.2, 3.2]:
		MeshKit.static_box(n, Vector3(0.45, 4.2, 0.45), Vector3(0, 2.1, z), timber)
	MeshKit.box(n, Vector3(0.4, 0.4, 7.2), Vector3(0.6, 0.35, 0.6), timber, Vector3(0, 8, 78))
	for i in 5:
		MeshKit.static_box(n, Vector3(0.12, 2.2, 0.35), Vector3(-0.6 + rng.randf_range(-0.3, 0.3), 1.0, -2.4 + i * 1.2), Props.wood(),
			Vector3(rng.randf_range(-35, 35), 0, rng.randf_range(-20, 20)))
	var bark := Nature.bark_material(Color(1.1, 0.8, 0.5))
	var log := MeshKit.static_cyl(n, 0.7, 14.0, Vector3(3.0, 0.7, 0.0), bark, 12)
	log.rotation_degrees = Vector3(90, 22, 0)
	# the branch the black cloth caught on
	var bn := Props.pivot(w, o + Vector3(5.5, 0, 5.0))
	MeshKit.cyl(bn, 0.08, 0.14, 2.2, Vector3(0, 1.1, 0), timber, Vector3(0, 0, 8), 6)
	MeshKit.cyl(bn, 0.04, 0.07, 1.2, Vector3(0.35, 1.5, 0), timber, Vector3(0, 0, -55), 5)
	MeshKit.box(bn, Vector3(0.35, 0.5, 0.02), Vector3(0.62, 1.4, 0.05), MeshKit.mat(Color(0.05, 0.05, 0.05), 0.8), Vector3(0, 0, -12))


## The village notice board on the square: a missing-person notice, a wolf warning, a camp sketch.
func _notice_board(w: Node3D, p: Vector3, yaw: float) -> void:
	var n := Props.pivot(w, p, yaw)
	for x in [-0.9, 0.9]:
		MeshKit.static_box(n, Vector3(0.14, 2.1, 0.14), Vector3(x, 1.05, 0), Props.dark_wood())
	MeshKit.box(n, Vector3(2.0, 1.1, 0.08), Vector3(0, 1.45, 0), Props.wood())
	MeshKit.prism(n, Vector3(2.3, 0.35, 0.5), Vector3(0, 2.18, 0), Props.roof(Color(0.55, 0.4, 0.3)), Vector3(0, 90, 0))
	var paper := [Color(0.9, 0.86, 0.74), Color(0.84, 0.8, 0.68), Color(0.92, 0.9, 0.82)]
	for i in 3:
		MeshKit.box(n, Vector3(0.5, 0.62, 0.01), Vector3(-0.6 + i * 0.6, 1.45 + (i % 2) * 0.06, 0.05), MeshKit.mat(paper[i]), Vector3(0, 0, -4 + i * 4))


# --------------------------------------------------------------------------- around the valley

func _mine(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rock := Props.rock_mat(Color(1.25, 1.15, 1.0))
	var iron := MeshKit.mat(Color(0.3, 0.3, 0.32), 0.5, 0.6)
	var wood := Props.dark_wood()
	var n := Props.pivot(w, o)
	# the mine itself: a tunnel into the hill and a cave at its end (Cave, runs towards -x)
	Cave.create(w, o + Vector3(-4, 0, 0), PI * 0.5, 23)
	for r in [[Vector3(-5, -5, -9), 6.5], [Vector3(-5, -5, 9), 6.5], [Vector3(-9, -3, -14), 7.5], [Vector3(-9, -3, 14), 7.5]]:
		MeshKit.static_sphere(n, r[1], r[0], rock)
	for z in [-0.6, 0.6]:
		MeshKit.box(n, Vector3(16, 0.08, 0.08), Vector3(4, 0.12, z), iron)
	for i in 11:
		MeshKit.box(n, Vector3(0.3, 0.08, 1.7), Vector3(-3 + i * 1.5, 0.04, 0), wood)
	MeshKit.static_box(n, Vector3(1.4, 0.9, 1.1), Vector3(4, 0.75, 0), MeshKit.mat(Color(0.42, 0.29, 0.16)))
	for p in [Vector3(3.5, 0.25, -0.6), Vector3(4.5, 0.25, -0.6), Vector3(3.5, 0.25, 0.6), Vector3(4.5, 0.25, 0.6)]:
		MeshKit.cyl(n, 0.22, 0.22, 0.08, p, iron, Vector3(90, 0, 0), 10)
	for i in 4:
		MeshKit.sphere(n, 0.25, Vector3(3.6 + (i % 2) * 0.6, 1.25, -0.25 + (i / 2) * 0.5), rock)
	# a broken cart on its side and the warning sign
	MeshKit.static_box(n, Vector3(1.3, 0.8, 1.0), Vector3(9.5, 0.45, 3.2), MeshKit.mat(Color(0.4, 0.28, 0.16)), Vector3(0, 30, 80))
	MeshKit.cyl(n, 0.22, 0.22, 0.08, Vector3(10.4, 0.22, 2.4), iron, Vector3(0, 30, 0), 10)
	_sign(w, o + Vector3(2.5, 0, 3.4), 90.0, Loc.t("Unstable tunnels!"))
	Props.lantern(w, o + Vector3(-2.5, 0, -3.6))
	Props.lantern(w, o + Vector3(-2.5, 0, 3.6))
	Props.lantern(w, o + Vector3(11, 0, -6))
	Props.crate(w, o + Vector3(6, 0, 8), rng.randf_range(0, 45))
	Props.crate(w, o + Vector3(7, 0, 8.6), rng.randf_range(0, 45))


## The Red Bandana camp in an old charcoal-burners' clearing: palisade, tents, cookfire, the supply
## shelter (with VesPer's batteries) and the captain's plank-walled tent with his table.
func _camp(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	Props.tent(w, o + Vector3(8, 0, -7), -15, Color(0.5, 0.4, 0.24))
	Props.tent(w, o + Vector3(-9, 0, 7), 160, Color(0.6, 0.16, 0.12))
	Props.tent(w, o + Vector3(9, 0, 6), 200, Color(0.5, 0.4, 0.24))
	Props.campfire(w, o)
	Props.palisade(w, o, 15.0, -30.0, 120.0)
	Props.crate(w, o + Vector3(4, 0, 11), rng.randf_range(0, 45))
	Props.barrel(w, o + Vector3(11, 0, -1))
	Props.barrel(w, o + Vector3(11.5, 0, 0.2))
	Props.torch(w, o + Vector3(-6, 0, 0))
	var timber := Props.dark_wood()
	var planks := Props.wood()
	var red := MeshKit.mat(Color(0.62, 0.12, 0.1))
	# the captain's tent: plank walls on three sides, red cloth roof, open to the yard
	var ct := Props.pivot(w, o + Vector3(-9, 0, -7), 30.0)
	MeshKit.static_box(ct, Vector3(4.6, 2.0, 0.15), Vector3(0, 1.0, -2.4), planks)
	MeshKit.static_box(ct, Vector3(0.15, 2.0, 4.8), Vector3(-2.3, 1.0, 0), planks)
	MeshKit.static_box(ct, Vector3(0.15, 2.0, 4.8), Vector3(2.3, 1.0, 0), planks)
	MeshKit.prism(ct, Vector3(5.0, 1.4, 5.2), Vector3(0, 2.7, 0), red)
	for x in [-2.3, 2.3]:
		MeshKit.box(ct, Vector3(0.14, 2.8, 0.14), Vector3(x, 1.4, 2.4), timber)
	MeshKit.static_box(ct, Vector3(1.6, 0.08, 0.9), Vector3(0, 0.92, -0.6), planks)
	for lx in [-0.7, 0.7]:
		MeshKit.box(ct, Vector3(0.08, 0.9, 0.08), Vector3(lx, 0.45, -0.6), timber)
	MeshKit.box(ct, Vector3(0.7, 0.01, 0.5), Vector3(0.3, 0.965, -0.7), MeshKit.mat(Color(0.86, 0.8, 0.64)), Vector3(0, 12, 0))
	MeshKit.static_box(ct, Vector3(0.9, 0.5, 0.6), Vector3(-1.4, 0.25, -1.6), timber)
	# the supply shelter: a roof on posts over stolen sacks, tools and crates
	var ss := Props.pivot(w, o + Vector3(5, 0, -10), 0.0)
	for x in [-2.2, 2.2]:
		for z in [-1.4, 1.4]:
			MeshKit.static_box(ss, Vector3(0.16, 2.4, 0.16), Vector3(x, 1.2, z), timber)
	MeshKit.box(ss, Vector3(5.0, 0.12, 3.4), Vector3(0, 2.45, 0), planks, Vector3(8, 0, 0))
	for cx in [-1.4, 0.0]:
		MeshKit.static_box(ss, Vector3(0.9, 0.9, 0.9), Vector3(cx, 0.45, -0.4), planks)
	var sack := MeshKit.mat(Color(0.75, 0.66, 0.48), 0.95)
	for k in 4:
		MeshKit.sphere(ss, 0.38, Vector3(1.3 + (k % 2) * 0.6, 0.35, -0.6 + (k / 2) * 0.6), sack, Vector3(1, 1.25, 0.9))
	MeshKit.box(ss, Vector3(0.05, 0.05, 1.3), Vector3(-2.0, 1.0, 0.2), MeshKit.mat(Color(0.4, 0.4, 0.42), 0.4, 0.8), Vector3(70, 0, 0))
	# red cloth tied to the stakes
	for k in 5:
		var a := deg_to_rad(-20.0 + k * 32.0)
		var cp := o + Vector3(cos(a) * 15.4, 0, sin(a) * 15.4)
		var cn := Props.pivot(w, cp, rad_to_deg(a))
		MeshKit.box(cn, Vector3(0.04, 0.5, 0.18), Vector3(0, 2.0, 0), red, Vector3(0, 0, 10))


func _den(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var rock := Props.rock_mat()
	var bone := MeshKit.mat(Color(0.92, 0.9, 0.82))
	var n := Props.pivot(w, o)
	for i in 7:
		var a := TAU * i / 7.0 + 0.4
		var r := rng.randf_range(1.6, 3.2)
		MeshKit.static_sphere(n, r, Vector3(cos(a) * 10.0, -r * 0.35, sin(a) * 10.0), rock)
	for i in 8:
		MeshKit.cyl(n, 0.05, 0.05, rng.randf_range(0.4, 0.8), Vector3(rng.randf_range(-6, 6), 0.06, rng.randf_range(-6, 6)), bone, Vector3(90, rng.randf_range(0, 180), 0), 6)
	MeshKit.static_box(n, Vector3(0.7, 0.7, 6), Vector3(-5, 0.35, 3), Props.dark_wood(), Vector3(0, 35, 0))


func _tower(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var stone := Props.stone(Color(1.1, 1.05, 1.0), 0.4)
	var n := Props.pivot(w, o)
	# broken round tower, an old lookout over the eastern woods
	var cs := CylinderShape3D.new()
	cs.radius = 3.2
	cs.height = 9.0
	var b := StaticBody3D.new()
	b.position = Vector3(0, 4.5, 0)
	var c := CollisionShape3D.new()
	c.shape = cs
	b.add_child(c)
	n.add_child(b)
	MeshKit.cyl(n, 3.0, 3.3, 9.0, Vector3(0, 4.5, 0), stone, Vector3.ZERO, 16)
	for i in 7:
		var a := TAU * i / 12.0
		MeshKit.box(n, Vector3(1.0, rng.randf_range(0.8, 3.0), 0.8), Vector3(cos(a) * 3.0, 9.8, sin(a) * 3.0), stone, Vector3(0, -rad_to_deg(a), 0))
	MeshKit.box(n, Vector3(1.6, 2.6, 0.3), Vector3(0, 1.3, 3.2), MeshKit.mat(Color(0.05, 0.05, 0.06)))
	Props.ruined_wall(w, o + Vector3(-7, 0, 5), 30, 8, 3.0, rng)
	Props.ruined_wall(w, o + Vector3(6, 0, 6), -40, 6, 2.5, rng)
	Props.campfire(w, o + Vector3(1.5, 0, 7.0))


## Maybell's farm: the long low farmhouse with its blue door, wheat, the coop, a garden, the stone
## oven, a rain barrel and the fence the wolves broke.
func _farm(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	Props.house(w, o + Vector3(6, 0, -6), 270.0, Vector3(9.5, 4.0, 5.2), Color(0.95, 0.78, 0.45), Color(0.95, 0.94, 0.9))
	var n := Props.pivot(w, o)
	# porch bench and boots by the door (the house's door faces west, towards the village)
	MeshKit.static_box(n, Vector3(0.45, 0.08, 1.6), Vector3(-1.0, 0.45, -3.0), Props.wood())
	for k in 2:
		MeshKit.box(n, Vector3(0.12, 0.25, 0.28), Vector3(-1.4, 0.12, -1.8 + k * 0.35), MeshKit.mat(Color(0.2, 0.15, 0.1)))
	# fences, the broken stretch where the wolves came in
	Props.fence(w, o + Vector3(-14, 0, -6), o + Vector3(-14, 0, 12))
	Props.fence(w, o + Vector3(-14, 0, 12), o + Vector3(-3, 0, 12))
	Props.fence(w, o + Vector3(2, 0, 12), o + Vector3(6, 0, 12))
	for k in 3:
		MeshKit.static_box(n, Vector3(0.12, 0.12, 1.8), Vector3(-0.8 + k * 0.6, 0.08, 12.4 + k * 0.3), Props.wood(), Vector3(0, 70 + k * 20, 6))
	# the wheat field south-east of the house is painted in layout() (the terrain grows the wheat)
	Props.scarecrow(w, o + Vector3(22, 0, 19), 200)
	VBuild.chicken_coop(w, o + Vector3(-9, 0, 7), 90.0)
	if w.has_method("add_animals"):
		w.add_animals("chicken", o + Vector3(-6.5, 0, 7), 4)
	VBuild.garden(w, o + Vector3(-8, 0, -4), 0.0, rng)
	# stone oven and rain barrel
	MeshKit.static_box(n, Vector3(1.4, 1.0, 1.4), Vector3(-1.0, 0.5, -16.5), Props.stone(Color(0.9, 0.86, 0.8)))
	MeshKit.sphere(n, 0.75, Vector3(-1.0, 1.0, -16.5), Props.stone(Color(0.85, 0.8, 0.75)), Vector3(1, 0.7, 1))
	Props.barrel(w, o + Vector3(1.0, 0, -2.0))
	Props.haystack(w, o + Vector3(12, 0, -14))
	Props.hay_bale(w, o + Vector3(9, 0, 5), 30)
	Props.well(w, o + Vector3(-3, 0, -12))
	# torn sacks along the field track
	var torn := MeshKit.mat(Color(0.72, 0.64, 0.48), 0.95)
	for k in 4:
		MeshKit.box(n, Vector3(0.7, 0.05, 0.5), Vector3(-18.0 - k * 5.0, 0.03, 8.0 + rng.randf_range(-1.5, 1.5)), torn, Vector3(0, rng.randf_range(0, 180), 0))


## The granary on the farm road: a tall timber store raised on stone piers, double doors with iron
## straps, a ladder to the inspection loft. Grain spills out of the back; damp black mould on a wall.
func _granary(w: Node3D, o: Vector3, rng: RandomNumberGenerator) -> void:
	var n := Props.pivot(w, o, 0.0)
	var stone := Props.stone(Color(0.88, 0.85, 0.8), 0.4)
	var planks := Props.wood()
	var timber := Props.dark_wood()
	for x in [-2.4, 0.0, 2.4]:
		for z in [-3.0, 0.0, 3.0]:
			MeshKit.static_box(n, Vector3(0.6, 0.9, 0.6), Vector3(x, 0.45, z), stone)
	MeshKit.static_box(n, Vector3(6.0, 4.2, 7.0), Vector3(0, 3.0, 0), planks)
	MeshKit.prism(n, Vector3(6.8, 2.2, 7.6), Vector3(0, 6.2, 0), Props.roof(Color(0.55, 0.45, 0.36)), Vector3(0, 0, 0))
	for z in [-3.52, 3.52]:
		for x in [-2.95, 2.95]:
			MeshKit.box(n, Vector3(0.18, 4.3, 0.18), Vector3(x, 3.0, z), timber)
	# double doors (east, towards the road) with iron straps
	for dz in [-0.62, 0.62]:
		MeshKit.box(n, Vector3(0.06, 2.4, 1.2), Vector3(3.03, 2.1, dz), timber)
		for sy in [1.4, 2.8]:
			MeshKit.box(n, Vector3(0.02, 0.1, 1.1), Vector3(3.07, sy, dz), MeshKit.mat(Color(0.25, 0.25, 0.27), 0.4, 0.8))
	# steps up to the doors and the loft ladder
	MeshKit.static_box(n, Vector3(1.2, 0.3, 1.8), Vector3(3.7, 0.15, 0), planks)
	MeshKit.static_box(n, Vector3(0.8, 0.3, 1.8), Vector3(3.5, 0.45, 0), planks)
	for side in [-0.3, 0.3]:
		MeshKit.box(n, Vector3(0.06, 5.4, 0.06), Vector3(-3.2, 2.7, 2.0 + side), timber, Vector3(0, 0, -6))
	for k in 9:
		MeshKit.box(n, Vector3(0.05, 0.05, 0.6), Vector3(-3.1 - k * 0.06, 0.6 + k * 0.55, 2.0), timber)
	# the black mould on the west wall
	var mould := MeshKit.mat(Color(0.05, 0.06, 0.05), 0.9)
	for k in 5:
		MeshKit.box(n, Vector3(0.02, rng.randf_range(0.3, 0.8), rng.randf_range(0.4, 1.0)), Vector3(-3.02, 1.4 + rng.randf_range(-0.3, 0.6), 1.0 + rng.randf_range(-0.8, 0.8)), mould)
	# grain spilled in a trail out of the back
	var grain := MeshKit.mat(Color(0.86, 0.74, 0.42), 0.95)
	for k in 9:
		MeshKit.sphere(n, rng.randf_range(0.08, 0.16), Vector3(rng.randf_range(-0.6, 0.6), 0.03, -4.0 - k * 0.7), grain, Vector3(2.0, 0.25, 1.4))
