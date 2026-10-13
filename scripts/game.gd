extends Node
## Autoload "Game": location sequence, input bindings, scene switching, sound bank,
## ambience and shared UI helpers.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const WORLD_SCENE := "res://scenes/world.tscn"
const LOADING_SCENE := "res://scenes/loading.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"
const RATE := 22050
const SND := "res://assets/sounds/"

## Enemy level range per location (min, max); bosses are max + 2.
const ZONE_LEVELS := [Vector2i(1, 6), Vector2i(6, 12), Vector2i(12, 19), Vector2i(19, 27), Vector2i(27, 36), Vector2i(36, 45)]

const LEVELS := [
	{"script": "res://scripts/levels/northvale.gd", "name": "Northvale", "subtitle": "The Abbey Grounds", "music": "northvale",
		"tip": "Kill enemies to gain XP. Every level gives a talent point - open the Skill Book with [K]."},
	{"script": "res://scripts/levels/darkwood.gd", "name": "Darkwood", "subtitle": "Forest of the Restless Dead", "music": "darkwood",
		"tip": "Necromancers raise skeletons and heal their allies - kill them first. Watch out for the Grave Lord's meteors."},
	{"script": "res://scripts/levels/farmlands.gd", "name": "Goldfield Farms", "subtitle": "The Gnoll Uprising", "music": "farmlands",
		"tip": "Shoot the red barrels to blow up groups of gnolls. Brutes and golems slam the ground - step out of the red circle."},
	{"script": "res://scripts/levels/frostpeak.gd", "name": "Frostpeak Pass", "subtitle": "Where the Yetis Roam", "music": "darkwood",
		"tip": "Frost Wraiths throw ice that slows you. Fire spells are extra handy against the cold."},
	{"script": "res://scripts/levels/emberforge.gd", "name": "Emberforge Canyon", "subtitle": "The Burning Lands", "music": "darkwood",
		"tip": "Never step into lava - it burns fast. Frost magic keeps fire elementals in check."},
	{"script": "res://scripts/levels/sunkencoast.gd", "name": "The Sunken Coast", "subtitle": "Curse of Captain Bones", "music": "northvale",
		"tip": "Giant crabs are tough but slow. Look for treasure chests hidden around every location."},
]
const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_DB := -18.0          # loudness (RMS dBFS) every track is brought to
const MUSIC_DB_COMBAT := -15.0

## Music per location: playlists for day and night (they rotate), plus a combat track picked
## when a fight starts. rpg/ = AlkaKrab's Fantasy RPG Music Vol. 2, loops/ = Andrew Sitkov's
## Music Loops Mini Set.
const MUSIC := [
	{"day": ["rpg/light_ambient_1", "loops/medieval_theme_1", "rpg/ambient_6"], "night": ["rpg/night_ambient_2", "loops/mystical_1"], "combat": "rpg/action_1"},
	{"day": ["rpg/ambient_5", "loops/mystical_2", "rpg/ambient_3"], "night": ["rpg/night_ambient_3", "loops/mystical_1", "rpg/night_ambient_4"], "combat": "rpg/action_2"},
	{"day": ["rpg/light_ambient_2", "loops/medieval_theme_2", "rpg/ambient_2"], "night": ["rpg/night_ambient_4", "loops/mystical_2"], "combat": "rpg/action_3"},
	{"day": ["rpg/ambient_7", "loops/mystical_3", "rpg/ambient_8"], "night": ["rpg/night_ambient_5", "loops/mystical_1"], "combat": "rpg/action_4"},
	{"day": ["rpg/ambient_9", "loops/medieval_theme_2", "rpg/ambient_4"], "night": ["rpg/night_ambient_1", "loops/mystical_3"], "combat": "rpg/action_5"},
	{"day": ["rpg/light_ambient_3", "loops/medieval_theme_1", "rpg/ambient_10"], "night": ["rpg/night_ambient_2", "loops/mystical_2"], "combat": "rpg/action_1"},
]
const MUSIC_COMBAT := ["loops/battle_1", "loops/battle_2", "loops/battle_3", "loops/battle_4", "loops/battle_5",
	"loops/epic_battle_1", "loops/epic_battle_2", "loops/epic_drums", "loops/fight_till_dying", "loops/steel_enemy", "loops/army_of_death"]
const MUSIC_BOSS := ["loops/heart_of_warrior", "loops/unbreakable", "loops/hard_rock", "loops/rage_machine",
	"loops/lets_rock_1", "loops/lets_rock_2", "loops/fatality_racer", "loops/rhythm_of_life"]
const MUSIC_CAPITAL := ["rpg/light_ambient_4", "loops/dreams_of_glory", "loops/time_of_heroes"]
const MUSIC_TOWN := ["rpg/light_ambient_5", "loops/hope", "loops/revival_of_hero"]
const MUSIC_CAVE := ["loops/mystical_3", "loops/mystical_2"]
const MUSIC_VICTORY := "loops/stay_strong_unbreakable"

## Measured loudness of each track [RMS dBFS, peak dBFS]: the RPG album is mastered 15-25 dB
## quieter than the loops, so every track gets its own gain (see music_gain).
const MUSIC_LOUDNESS := {
	"rpg/action_1": [-26.4, -11.7], "rpg/action_2": [-28.2, -13.7], "rpg/action_3": [-26.7, -12.0], "rpg/action_4": [-25.0, -10.7],
	"rpg/action_5": [-28.5, -13.7], "rpg/ambient_1": [-31.8, -16.2], "rpg/ambient_10": [-31.9, -16.0], "rpg/ambient_2": [-27.3, -12.1],
	"rpg/ambient_3": [-33.7, -17.7], "rpg/ambient_4": [-32.8, -15.8], "rpg/ambient_5": [-29.2, -15.3], "rpg/ambient_6": [-28.6, -13.1],
	"rpg/ambient_7": [-30.4, -16.5], "rpg/ambient_8": [-33.8, -13.5], "rpg/ambient_9": [-35.9, -20.7], "rpg/complete": [-38.0, -22.1],
	"rpg/death": [-38.4, -19.8], "rpg/light_ambient_1": [-34.4, -19.8], "rpg/light_ambient_2": [-33.3, -19.2], "rpg/light_ambient_3": [-38.8, -25.4],
	"rpg/light_ambient_4": [-35.2, -21.7], "rpg/light_ambient_5": [-34.9, -22.0], "rpg/night_ambient_1": [-38.9, -22.2], "rpg/night_ambient_2": [-38.2, -19.0],
	"rpg/night_ambient_3": [-41.7, -21.1], "rpg/night_ambient_4": [-42.0, -28.6], "rpg/night_ambient_5": [-35.7, -20.5], "rpg/strange": [-42.5, -26.7],
	"rpg/victory": [-30.5, -14.2],
	"loops/army_of_death": [-19.4, -3.7], "loops/battle_1": [-18.9, -4.4], "loops/battle_2": [-19.0, -1.2], "loops/battle_3": [-19.3, -3.0],
	"loops/battle_4": [-16.3, -3.2], "loops/battle_5": [-16.9, -3.2], "loops/dreams_of_glory": [-16.1, 0.0], "loops/epic_battle_1": [-11.5, 0.0],
	"loops/epic_battle_2": [-10.5, 0.0], "loops/epic_drums": [-15.2, -1.4], "loops/fatality_racer": [-13.7, -4.0], "loops/fight_till_dying": [-17.0, -2.7],
	"loops/hard_rock": [-14.1, -1.2], "loops/heart_of_warrior": [-13.9, 0.0], "loops/hope": [-15.9, -1.7], "loops/lets_rock_1": [-16.3, -1.3],
	"loops/lets_rock_2": [-16.2, -1.0], "loops/medieval_theme_1": [-21.2, -4.3], "loops/medieval_theme_2": [-22.4, -6.4], "loops/mystical_1": [-20.7, -8.9],
	"loops/mystical_2": [-20.6, -6.8], "loops/mystical_3": [-15.1, -1.3], "loops/rage_machine": [-9.8, 0.0], "loops/revival_of_hero": [-13.9, 0.0],
	"loops/rhythm_of_life": [-16.9, -2.9], "loops/stay_strong_unbreakable": [-12.2, -0.5], "loops/steel_enemy": [-16.3, -0.9],
	"loops/time_of_heroes": [-14.6, 0.0], "loops/unbreakable": [-11.7, -0.5],
}

var mouse_sensitivity := 0.0022
var settings := {"fullscreen": true, "vsync": true, "quality": 2, "sensitivity": 1.0, "master": 0.8, "music": 0.55, "sfx": 0.9,
	"cutscenes": true, "narration": 0, "ui_scale": 0.0}    # ui_scale: 0 = auto, else 0.5 .. 2.0    # narration: 0 = English, 1 = Ukrainian
var sounds: Dictionary = {}        # name -> Array[AudioStream]
var sound_pitch := {"shell": 2.2, "potion": 1.3, "player_hit": 1.0, "impact_stone": 1.3, "land": 0.6, "slam": 0.7}
var level_index := 0
var admin := false                 # logged in as admin (F1 panel, ~ console, level select)
var god_mode := false
var inventory := {}                # bag, stash, equipment, gold (see Items.new_inventory)
var carry: Dictionary = {}          # ammo carried into the next location
var _carry_at_start: Dictionary = {}
var progress: Dictionary = Skills.new_progress()   # level / xp / talents, kept across locations
var _progress_at_start: Dictionary = {}
var stats := {"kills": 0, "fired": 0, "hit": 0, "time": 0.0}
var _stats_at_start: Dictionary = {}
var locations: Dictionary = {}     # "<index>" -> {"visited", "complete", "quests": {id: {status, progress}}}
var flags: Dictionary = {}         # story flags: "portal" (VesPer's portals are built), ...
var journey: Dictionary = {}       # travel quests across locations (see Journey)
var arrive_at := ""                # "portal": the next location load puts you at its portal
var _ambience: AudioStreamPlayer
var _dread: AudioStreamPlayer        # horror drone layered under every level's ambience
var _music: AudioStreamPlayer
var _music2: AudioStreamPlayer       # crossfade partner
var _sting: AudioStreamPlayer        # short cues (quest complete, victory...)
var _music_tw: Tween
var _music_key := ""
var _music_vol := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_setup_input()
	_build_sounds()
	_ambience = AudioStreamPlayer.new()
	_ambience.volume_db = -14.0
	_ambience.bus = "SFX"
	add_child(_ambience)
	_dread = AudioStreamPlayer.new()
	_dread.volume_db = -17.0
	_dread.bus = "SFX"
	add_child(_dread)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music2 = AudioStreamPlayer.new()
	_music2.bus = "Music"
	add_child(_music2)
	_sting = AudioStreamPlayer.new()
	_sting.bus = "Music"
	_sting.volume_db = -2.0
	add_child(_sting)
	load_settings()


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.physical_keycode == KEY_F11:
		settings["fullscreen"] = not settings["fullscreen"]
		apply_settings()
		save_settings()
		if is_embedded():
			var scene := get_tree().current_scene
			if scene and "hud" in scene and scene.hud:
				scene.hud.show_message(Loc.t("Fullscreen doesn't work inside the editor's Game tab - see README"), Color(1, 0.7, 0.4), 3.0)


# --------------------------------------------------------------------------- settings

func _setup_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
	# the music bus never clips, whatever gain a quiet track gets
	var mb := AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(mb) == 0:
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -1.0
		AudioServer.add_bus_effect(mb, lim)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for key in settings:
			settings[key] = cf.get_value("settings", key, settings[key])
	apply_settings()


func save_settings() -> void:
	var cf := ConfigFile.new()
	for key in settings:
		cf.set_value("settings", key, settings[key])
	cf.save(SETTINGS_PATH)


func apply_settings() -> void:
	var win := get_window()
	if is_embedded():
		pass   # the editor's Game tab controls the window; fullscreen isn't possible there
	elif settings["fullscreen"]:
		win.mode = Window.MODE_FULLSCREEN
	else:
		if win.mode != Window.MODE_WINDOWED:
			win.mode = Window.MODE_WINDOWED
		# large window by default: 85% of the screen, centered
		var screen := DisplayServer.screen_get_usable_rect(win.current_screen)
		var target := Vector2i(int(screen.size.x * 0.85), int(screen.size.y * 0.85))
		if win.size.x < target.x * 0.9:
			win.size = target
			win.position = screen.position + (screen.size - target) / 2
	# UI scale: the UI already grows with the window (stretch mode); this multiplies on top
	win.content_scale_factor = ui_scale()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED)
	mouse_sensitivity = 0.0022 * float(settings["sensitivity"])
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, float(settings["master"]))))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(0.0001, float(settings["music"]))))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(0.0001, float(settings["sfx"]))))
	var scene := get_tree().current_scene if get_tree() else null
	if scene and scene.has_method("apply_quality"):
		scene.apply_quality()


func ui_scale() -> float:
	var s := float(settings.get("ui_scale", 0.0))
	return 1.0 if s <= 0.0 else clampf(s, 0.5, 2.0)


## True when the game runs inside the editor's Game tab (F5 with embedding on).
func is_embedded() -> bool:
	return Engine.has_method("is_embedded_in_editor") and Engine.call("is_embedded_in_editor")


# --------------------------------------------------------------------------- music

## Gain (dB) that brings a track to the target loudness without clipping.
func music_gain(key: String, target := MUSIC_DB) -> float:
	var l: Array = MUSIC_LOUDNESS.get(key, [target, -6.0])
	return clampf(target - float(l[0]), -20.0, minf(24.0, -1.0 - float(l[1])))


## Length of a track in seconds (0 if missing).
func music_length(key: String) -> float:
	var s := _music_stream(key)
	return s.get_length() if s else 0.0


func _music_stream(key: String) -> AudioStream:
	for path in ["res://assets/music/%s.ogg" % key, "res://assets/music/%s.wav" % key, "res://assets/music/music_%s.wav" % key, "res://assets/music/music_%s.ogg" % key, "res://assets/music/music_%s.mp3" % key]:
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Crossfades to a music track. key: "rpg/<name>" (assets/music/rpg/<name>.ogg, AlkaKrab's
## Fantasy RPG Music Vol. 2), "loops/<name>" (assets/music/loops/<name>.wav, Andrew Sitkov's
## Music Loops Mini Set) or an older "<name>" (assets/music/music_<name>.*). Every track is
## levelled to `target` loudness.
func play_music(key: String, fade := 2.5, target := MUSIC_DB) -> void:
	if key == "" or key == _music_key:
		return
	var stream := _music_stream(key)
	if stream == null:
		return
	_music_key = key
	var wav := stream as AudioStreamWAV
	if wav and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)
	# the new track starts on the idle player and fades in while the old one fades out
	var old := _music
	_music = _music2
	_music2 = old
	if _music_tw and _music_tw.is_valid():
		_music_tw.kill()
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	_music_vol = music_gain(key, target)
	_music_tw = create_tween().set_parallel(true)
	_music_tw.tween_property(_music, "volume_db", _music_vol, fade)
	if old.playing:
		_music_tw.tween_property(old, "volume_db", -40.0, fade)
		_music_tw.chain().tween_callback(old.stop)


## A short musical cue over the music (quest complete, victory, death, travel): the music dips
## while it plays. name: complete / victory / death / strange.
func stinger(name: String) -> void:
	var path := "res://assets/music/rpg/%s.ogg" % name
	if not ResourceLoader.exists(path):
		return
	var s: AudioStream = load(path)
	if "loop" in s:
		s.set("loop", false)
	_sting.stream = s
	_sting.volume_db = music_gain("rpg/" + name, MUSIC_DB + 2.0)
	_sting.play()
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", _music_vol - 12.0, 0.3)
	tw.tween_interval(maxf(0.5, s.get_length() - 0.6))
	tw.tween_property(_music, "volume_db", _music_vol, 1.5)

func stop_music(fade := 1.5) -> void:
	_music_key = ""
	if _music_tw and _music_tw.is_valid():
		_music_tw.kill()
	_music_tw = create_tween().set_parallel(true)
	for m: AudioStreamPlayer in [_music, _music2]:
		if m.playing:
			_music_tw.tween_property(m, "volume_db", -40.0, fade)
	_music_tw.chain().tween_callback(func() -> void:
		_music.stop()
		_music2.stop())


func stop_ambience() -> void:
	_ambience.stop()
	_dread.stop()


# --------------------------------------------------------------------------- flow

func start_game() -> void:
	start_game_state()
	Brain.new_world()      # the AI brains forget the previous hero
	if settings.get("cutscenes", true) and ResourceLoader.exists(INTRO_SCENE):
		get_tree().paused = false
		get_tree().change_scene_to_file(INTRO_SCENE)
	else:
		_begin_level()


func play_ending() -> void:
	save_now()
	get_tree().paused = false
	_ambience.stop()
	_dread.stop()
	get_tree().change_scene_to_file(ENDING_SCENE)


## Saved state of a location (created on first use).
func loc_state(i := -1) -> Dictionary:
	var k := str(level_index if i < 0 else i)
	if not locations.has(k):
		locations[k] = {"visited": false, "complete": false, "quests": {}}
	return locations[k]


## Through VesPer's portal to another location (quests, chests and progress there are kept).
func travel_to(i: int) -> void:
	save_now()
	level_index = clampi(i, 0, LEVELS.size() - 1)
	arrive_at = "portal"
	_begin_level()


## After dying: back at the location's portal (or start), nothing lost but some gold.
func respawn() -> void:
	save_now()
	arrive_at = "portal"
	_begin_level()


## After the opening cinematic.
func begin_first_level() -> void:
	_begin_level()


## Continue the saved character from its last location.
func continue_game() -> void:
	if not SaveGame.load_into_game():
		start_game()
		return
	_begin_level()


## Admin: jump straight into a location with a character at that zone's level.
func start_at_level(i: int) -> void:
	start_game_state()
	level_index = i
	var zone_level: int = ZONE_LEVELS[i].x
	progress["level"] = zone_level
	progress["points"] = zone_level - 1
	# gear that fits the zone so the location is playable right away
	inventory["equip"]["weapon1"] = Items.generate(zone_level, 2, "weapon", "rifle")
	inventory["equip"]["weapon2"] = Items.generate(zone_level, 2, "weapon", "shotgun")
	for s in ["helmet", "armor", "gloves", "boots"]:
		inventory["equip"][s] = Items.generate(zone_level, 1, "armor", s)
	inventory["gold"] = 200 * zone_level
	_begin_level()


func start_game_state() -> void:
	level_index = 0
	locations = {}
	flags = {}
	journey = {}
	arrive_at = ""
	carry = {}
	progress = Skills.new_progress()
	stats = {"kills": 0, "fired": 0, "hit": 0, "time": 0.0}
	inventory = Items.new_inventory()


func next_level(new_carry: Dictionary) -> void:
	level_index = mini(level_index + 1, LEVELS.size() - 1)
	carry = new_carry
	_begin_level()


## Restart the current location with the ammo you entered it with.
func retry_level() -> void:
	carry = _carry_at_start.duplicate()
	stats = _stats_at_start.duplicate()
	progress = _progress_at_start.duplicate(true)
	_begin_level()


func _begin_level() -> void:
	if inventory.is_empty():
		inventory = Items.new_inventory()
	SaveGame.save()
	_carry_at_start = carry.duplicate()
	_stats_at_start = stats.duplicate()
	_progress_at_start = progress.duplicate(true)
	get_tree().paused = false
	get_tree().change_scene_to_file(LOADING_SCENE)


func current_level() -> Dictionary:
	return LEVELS[level_index]


func is_last_level() -> bool:
	return level_index >= LEVELS.size() - 1


func add_stats(kills: int, fired: int, hit: int, time: float) -> void:
	stats["kills"] += kills
	stats["fired"] += fired
	stats["hit"] += hit
	stats["time"] += time


func go_to_menu() -> void:
	save_now()
	get_tree().paused = false
	_ambience.stop()
	_dread.stop()
	get_tree().change_scene_to_file(MENU_SCENE)
	play_music("rpg/ambient_1")


func quit_game() -> void:
	save_now()
	get_tree().quit()


## Saves the character; while in a location the world first copies the player's state.
func save_now() -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("store_state"):
		scene.store_state()
	if not inventory.is_empty():
		SaveGame.save()


func play_ambience(kind: String) -> void:
	var key := "amb_" + kind
	if not sounds.has(key):
		return
	var s: AudioStream = sounds[key][0]
	if _ambience.stream != s or not _ambience.playing:
		_ambience.stream = s
		_ambience.play()
	if sounds.has("amb_horror") and not _dread.playing:
		_dread.stream = sounds["amb_horror"][0]
		_dread.play()


# --------------------------------------------------------------------------- input

func _setup_input() -> void:
	_bind_keys("move_forward", [KEY_W, KEY_UP])
	_bind_keys("move_back", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("jump", [KEY_SPACE])
	_bind_keys("sprint", [KEY_SHIFT])
	_bind_keys("reload", [KEY_R])
	_bind_keys("map", [KEY_M, KEY_TAB])
	_bind_keys("pause", [KEY_ESCAPE, KEY_P])
	_bind_keys("frost_arrow", [KEY_Q])
	_bind_keys("frost_nova", [KEY_E])
	_bind_keys("skill_fireball", [KEY_X, KEY_3])
	_bind_keys("skill_heal", [KEY_C, KEY_4])
	_bind_keys("skill_lightning", [KEY_G, KEY_5])
	_bind_keys("skill_blink", [KEY_V, KEY_6])
	_bind_keys("skill_meteor", [KEY_T, KEY_7])
	_bind_keys("skill_book", [KEY_K])
	_bind_keys("interact", [KEY_F])
	_bind_keys("flashlight", [KEY_L])
	_bind_keys("inventory", [KEY_I])
	_bind_keys("use_potion", [KEY_H])
	_bind_keys("use_mana", [KEY_J])
	_bind_keys("gadget", [KEY_B])
	_bind_keys("gadget_next", [KEY_N])
	_bind_keys("craft", [KEY_U])
	_bind_keys("admin_panel", [KEY_F1])
	_bind_keys("console", [KEY_QUOTELEFT])
	_bind_keys("weapon_1", [KEY_1])
	_bind_keys("weapon_2", [KEY_2])
	_bind_mouse("weapon_next", MOUSE_BUTTON_WHEEL_DOWN)
	_bind_mouse("weapon_prev", MOUSE_BUTTON_WHEEL_UP)
	_bind_mouse("shoot", MOUSE_BUTTON_LEFT)
	_bind_mouse("aim", MOUSE_BUTTON_RIGHT)


func _bind_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _bind_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


# --------------------------------------------------------------------------- sound

## Plays a random variant of a sound. Pass a Vector3 as `at` for a positional 3D sound.
func play_sound(sound: String, at: Variant = null, volume_db := 0.0, pitch := 1.0) -> void:
	if not sounds.has(sound):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var variants: Array = sounds[sound]
	var stream: AudioStream = variants[randi() % variants.size()]
	pitch *= sound_pitch.get(sound, 1.0)
	if at is Vector3:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.unit_size = 10.0
		p3.max_distance = 80.0
		p3.stream = stream
		p3.volume_db = volume_db
		p3.pitch_scale = pitch * randf_range(0.92, 1.08)
		scene.add_child(p3)
		p3.global_position = at
		p3.finished.connect(p3.queue_free)
		p3.play()
	else:
		var p2 := AudioStreamPlayer.new()
		p2.bus = "SFX"
		p2.process_mode = Node.PROCESS_MODE_ALWAYS
		p2.stream = stream
		p2.volume_db = volume_db
		p2.pitch_scale = pitch * randf_range(0.95, 1.05)
		scene.add_child(p2)
		p2.finished.connect(p2.queue_free)
		p2.play()


func _load_set(sound: String, files: Array) -> void:
	var list: Array = []
	for f in files:
		var path: String = SND + f
		if ResourceLoader.exists(path):
			list.append(load(path))
	if not list.is_empty():
		sounds[sound] = list


func _numbered(prefix: String, count: int, ext := ".ogg", start := 0, pad := 3) -> Array:
	var out := []
	for i in count:
		out.append(prefix + str(start + i).pad_zeros(pad) + ext)
	return out


func _build_sounds() -> void:
	# generated sounds (UI and creature voices)
	sounds["hit"] = [_wav(_gen_tone(1500.0, 1400.0, 0.06))]
	sounds["cast"] = [_wav(_gen_tone(250.0, 760.0, 0.75, false, 0.05, 0.25))]
	sounds["spell_hit"] = [_wav(_gen_boom(0.5, 0.12, 7.0, 50.0, 0.2))]
	sounds["enemy_die"] = [_wav(_gen_tone(320.0, 70.0, 0.55, true, 0.03, 0.15))]
	sounds["aggro"] = [_wav(_gen_tone(150.0, 95.0, 0.35, true, 0.08, 0.2))]
	sounds["swing"] = [_wav(_gen_whoosh(0.25))]
	sounds["empty"] = [_wav(_gen_click(2600.0, 140.0, 0.08))]
	sounds["shot"] = [_wav(_gen_boom(0.45, 0.35, 11.0, 70.0, 0.6))]
	sounds["player_hit"] = [_wav(_gen_tone(120.0, 55.0, 0.25, false, 0.0, 0.5))]
	var chime := _gen_tone(660.0, 660.0, 0.12)
	chime.append_array(_gen_tone(880.0, 880.0, 0.12))
	chime.append_array(_gen_tone(1320.0, 1320.0, 0.35, false, 0.02))
	sounds["heal"] = [_wav(chime)]
	var acc := _gen_tone(523.0, 523.0, 0.1)
	acc.append_array(_gen_tone(784.0, 784.0, 0.22))
	sounds["quest_accept"] = [_wav(acc)]
	sounds["quest_progress"] = [_wav(_gen_tone(988.0, 1318.0, 0.25))]
	var fan := _gen_tone(523.0, 523.0, 0.12)
	fan.append_array(_gen_tone(659.0, 659.0, 0.12))
	fan.append_array(_gen_tone(784.0, 784.0, 0.12))
	fan.append_array(_gen_tone(1046.0, 1046.0, 0.4))
	sounds["quest_done"] = [_wav(fan)]
	sounds["lightning"] = [_wav(_gen_crackle(0.6))]
	sounds["blink"] = [_wav(_gen_tone(300.0, 1600.0, 0.3, false, 0.0, 0.4))]
	sounds["fire_cast"] = [_wav(_gen_boom(0.6, 0.06, 4.0, 45.0, 0.0))]
	sounds["explosion"] = [_wav(_gen_boom(1.6, 0.08, 2.5, 38.0, 0.8))]
	var wind := _wav(_gen_wind(8.0))
	wind.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wind.loop_end = int(8.0 * RATE)
	sounds["amb_wind"] = [wind]
	sounds["drone_buzz"] = [_loop(_gen_buzz(1.0))]
	sounds["generator"] = [_loop(_gen_engine(1.0))]
	sounds["artillery"] = [_wav(_gen_boom(3.0, 0.02, 1.6, 30.0, 0.15)), _wav(_gen_boom(3.5, 0.015, 1.3, 26.0, 0.1))]

	# recorded CC0 sounds (assets/sounds) override the generated ones when present
	_load_set("shot", ["ak_shot_1.wav", "ak_shot_2.wav", "ak_shot_3.wav", "ak_shot_4.wav", "ak_shot_5.wav", "ak_shot_6.wav"])
	_load_set("mag_out", ["metalClick.ogg"])
	_load_set("mag_in", ["metalLatch.ogg"])
	_load_set("bolt", ["drawKnife1.ogg"])
	_load_set("step_grass", _numbered("footstep_grass_", 5))
	_load_set("step_stone", _numbered("footstep_concrete_", 5))
	_load_set("impact_wood", _numbered("impactWood_light_", 5))
	_load_set("impact_ground", _numbered("impactSoft_medium_", 5))
	_load_set("impact_stone", _numbered("impactMetal_light_", 5))
	_load_set("flesh", _numbered("impactPunch_medium_", 5))
	_load_set("player_hit", _numbered("impactPunch_medium_", 5))
	_load_set("shell", _numbered("impactMetal_light_", 5))
	_load_set("pickup_ammo", ["beltHandle1.ogg", "beltHandle2.ogg"])
	_load_set("potion", _numbered("impactGlass_light_", 5))
	_load_set("frost_cast", ["frost_cast.wav"])
	_load_set("frost_hit", ["frost_hit.wav"])
	_load_set("frost_nova", ["frost_nova.wav"])
	_load_set("ice_shatter", ["ice_shatter_1.ogg", "ice_shatter_2.ogg", "ice_shatter_3.ogg", "ice_shatter_4.ogg", "ice_shatter_5.ogg"])
	_load_set("explosion", ["explosion_1.ogg", "explosion_2.ogg", "explosion_3.ogg", "explosion_4.ogg", "explosion_5.ogg"])
	# jump: cloth rustle + a soft breath; landing: heavy boot on the surface underfoot
	_load_set("jump", ["cloth1.ogg", "cloth2.ogg", "cloth3.ogg", "cloth4.ogg", "clothBelt.ogg", "clothBelt2.ogg"])
	_load_set("jump_breath", ["cr_breath.ogg", "cr_breath_02.ogg"])
	_load_set("land", _numbered("impactSoft_heavy_", 5))
	_load_set("step_snow", _numbered("footstep_snow_", 5))
	_load_set("step_wood", _numbered("footstep_wood_", 5))
	_load_set("step_carpet", _numbered("footstep_carpet_", 5))
	_load_set("player_hit", ["player_grunt_1.wav", "player_grunt_2.wav", "player_grunt_6.wav"])
	_load_set("pickup_ammo", ["metal_01.ogg", "metal_02.ogg", "metal_03.ogg", "metal_04.ogg", "metal_05.ogg", "metal_06.ogg"])
	_load_set("potion", ["glass_01.ogg", "glass_02.ogg", "glass_03.ogg", "glass_04.ogg", "glass_05.ogg"])
	_load_set("drink", ["plop_01.ogg", "plop_02.ogg"])
	_load_set("level_up", ["gong_01.ogg"])
	_load_set("enemy_yell", _numbered("enemy_yell_", 12, ".wav", 1, 1))
	_load_set("enemy_death", _numbered("enemy_death_", 6, ".wav", 1, 1))
	_load_set("splash", ["splash_01.ogg", "splash_02.ogg"])
	_load_set("slam", ["slam_01.ogg", "slam_02.ogg", "slam_03.ogg"])
	# pickups by item type
	_load_set("pickup_item", ["handleSmallLeather.ogg", "handleSmallLeather2.ogg", "cloth3.ogg"])
	_load_set("pickup_coins", ["handleCoins.ogg", "handleCoins2.ogg"])
	_load_set("pickup_tech", ["ui_click_003.ogg", "ui_switch_002.ogg", "ui_switch_005.ogg", "ui_toggle_002.ogg"])
	_load_set("pickup_glass", ["ui_glass_001.ogg", "glass_01.ogg", "glass_03.ogg"])
	_load_set("pickup_bone", _numbered("impactWood_light_", 5))
	_load_set("chest", ["creak1.ogg", "creak2.ogg", "creak3.ogg"])
	_load_set("chest_latch", ["metalLatch.ogg", "metalClick.ogg"])
	_load_set("door_open", ["doorOpen_1.ogg", "doorOpen_2.ogg"])
	_load_set("door_close", ["doorClose_1.ogg", "doorClose_2.ogg", "doorClose_3.ogg", "doorClose_4.ogg"])
	# horror creatures
	_load_set("zombie", _numbered("zombie-", 24, ".wav", 1, 1))
	_load_set("monster", _numbered("monster-", 18, ".wav", 1, 1) + _numbered("cr_monster_", 20, ".ogg", 1, 2))
	_load_set("roar", _numbered("cr_roar_", 6, ".ogg", 1, 2) + _numbered("cr_troll_", 3, ".ogg", 1, 2))
	_load_set("ghost", _numbered("ghost_moan_", 5, ".wav", 1, 2))
	_load_set("bug", _numbered("cr_bug_", 13, ".ogg", 1, 2) + _numbered("cr_slime_", 8, ".ogg", 1, 2))
	_load_set("hound", ["cr_barking_01.ogg", "cr_barking_02.ogg", "cr_howl.ogg"] + _numbered("cr_grunt_", 9, ".ogg", 1, 2))
	_load_set("creature_die", _numbered("cr_die_", 4, ".ogg", 1, 2) + _numbered("cr_hurt_", 5, ".ogg", 1, 2))
	_load_set("creature_attack", _numbered("cr_attack_", 5, ".ogg", 1, 2) + _numbered("cr_spit_", 3, ".ogg", 1, 2))
	_load_set("scream", ["cr_scream_01.ogg", "cr_scream_02.ogg"] + _numbered("cr_weird_", 9, ".ogg", 1, 2))
	_load_set("amb_horror", ["amb_horror.ogg"])
	if sounds.has("amb_horror"):
		var ah = sounds["amb_horror"][0]
		if "loop" in ah:
			ah.loop = true
	_load_set("amb_forest", ["ambience_forest.ogg"])
	if sounds.has("amb_forest"):
		var amb = sounds["amb_forest"][0]
		if "loop" in amb:
			amb.loop = true


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Gunshot / explosion: sharp noise crack + low-passed body + low thump.
func _gen_boom(dur: float, lowpass: float, decay: float, thump_hz: float, crack: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * lowpass
		var c := randf_range(-1.0, 1.0) * exp(-t * 90.0) * crack
		var body := lp * exp(-t * decay) * 1.6
		var thump := sin(TAU * thump_hz * t) * exp(-t * 20.0)
		b[i] = c + body + thump * 0.8
	return b


## Metallic click used for reload sounds.
func _gen_click(freq: float, decay: float, dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	for i in b.size():
		var t := float(i) / RATE
		var ring := sin(TAU * freq * t) * exp(-t * decay) * 0.45
		var noise := randf_range(-1.0, 1.0) * exp(-t * decay * 2.5) * 0.6
		b[i] = ring + noise
	return b


func _loop(samples: PackedFloat32Array) -> AudioStreamWAV:
	var w := _wav(samples)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = samples.size()
	return w


## FPV drone: several detuned props (whole-Hz frequencies so a 1 s buffer loops seamlessly).
func _gen_buzz(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for f: float in [196.0, 203.0, 211.0, 219.0]:
			var ph := TAU * f * t
			s += sin(ph) + 0.5 * sin(ph * 2.0) + 0.25 * sin(ph * 3.0)
		s *= 0.85 + 0.15 * sin(TAU * 7.0 * t)
		b[i] = s * 0.07 + randf_range(-0.03, 0.03)
	return b


## Petrol generator: low chugging pulses.
func _gen_engine(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	for i in b.size():
		var t := float(i) / RATE
		var pulse := pow(0.5 + 0.5 * sin(TAU * 24.0 * t), 6.0)
		var s := sin(TAU * 48.0 * t) * 0.5 + sin(TAU * 96.0 * t) * 0.2 + randf_range(-0.4, 0.4) * pulse
		b[i] = s * (0.3 + 0.7 * pulse) * 0.35
	return b


func _gen_tone(f0: float, f1: float, dur: float, square := false, vibrato := 0.0, noise := 0.0) -> PackedFloat32Array:
	var b := _buf(dur)
	var n := b.size()
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		var f := lerpf(f0, f1, k) * (1.0 + sin(k * 40.0) * vibrato)
		phase += TAU * f / RATE
		var s := sin(phase)
		if square:
			s = signf(s) * 0.6
		var env := minf(1.0, k * 20.0) * (1.0 - k)
		b[i] = (s + randf_range(-1.0, 1.0) * noise) * env * 0.7
	return b


## Electric crackle: random sharp impulses over buzzing noise.
func _gen_crackle(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var n := b.size()
	var burst := 0.0
	for i in n:
		var k := float(i) / n
		if randf() < 0.004:
			burst = 1.0
		burst *= 0.995
		var buzz := sin(TAU * 120.0 * i / RATE) * 0.25
		b[i] = (randf_range(-1.0, 1.0) * (0.25 + burst) + buzz * burst) * (1.0 - k) * 0.9
	return b


## Seamlessly looping wind howl for dark locations.
func _gen_wind(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var f := int(0.6 * RATE)
	var raw := PackedFloat32Array()
	raw.resize(n + f)
	var lp := 0.0
	var lp2 := 0.0
	for i in n + f:
		var t := float(i) / RATE
		var gust := 0.55 + 0.45 * sin(TAU * t / dur * 2.0) * sin(TAU * t / dur * 3.0 + 1.0)
		lp += (randf_range(-1.0, 1.0) - lp) * (0.02 + 0.03 * gust)
		lp2 += (lp - lp2) * 0.2
		raw[i] = lp2 * 6.0 * gust
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = raw[i]
		if i < f:
			b[i] = lerpf(raw[n + i], raw[i], float(i) / f)
	return b


func _gen_whoosh(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var n := b.size()
	var lp := 0.0
	for i in n:
		var k := float(i) / n
		lp += (randf_range(-1.0, 1.0) - lp) * 0.08
		b[i] = lp * sin(PI * k) * 2.5
	return b


# --------------------------------------------------------------------------- UI helpers

func make_label(text: String, size := 24, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	return l


func make_button(text: String, width := 300.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.14, 0.26, 0.92), Color(0.8, 0.65, 0.3)))
	b.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.25, 0.45, 0.96), Color(1.0, 0.85, 0.4)))
	b.add_theme_stylebox_override("pressed", _button_style(Color(0.06, 0.08, 0.18, 1.0), Color(1.0, 0.85, 0.4)))
	b.add_theme_stylebox_override("focus", _button_style(Color(0, 0, 0, 0), Color(1.0, 0.9, 0.55)))
	b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.pressed.connect(func() -> void: play_sound("hit", null, -10.0, 0.7))
	return b


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	return sb
