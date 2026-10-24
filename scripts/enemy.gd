class_name Enemy
extends CharacterBody3D
## Hostile NPC. Melee types run up and hit, ranged types keep distance and cast spells,
## bosses can charge. Can be frozen and take frost damage over time.

signal died(enemy: Enemy)

const TYPES := {
	# Northvale
	"kobold": {"name": "Kobold Digger", "hp": 70.0, "speed": 4.6, "damage": 7.0, "range": 1.9, "cooldown": 1.1, "ranged": false, "scale": 0.75, "height": 1.35, "aggro": 16.0},
	"geomancer": {"name": "Kobold Geomancer", "hp": 60.0, "speed": 3.8, "damage": 11.0, "range": 20.0, "cooldown": 2.6, "ranged": true, "scale": 0.8, "height": 1.45, "aggro": 22.0, "spell": "fire"},
	"wolf": {"name": "Timber Wolf", "hp": 55.0, "speed": 7.0, "damage": 6.0, "range": 2.0, "cooldown": 0.9, "ranged": false, "scale": 1.0, "height": 1.1, "aggro": 18.0},
	"bandit": {"name": "Red Bandit", "hp": 100.0, "speed": 5.0, "damage": 10.0, "range": 2.1, "cooldown": 1.2, "ranged": false, "scale": 1.0, "height": 1.8, "aggro": 18.0},
	"cap_bandit": {"name": "Cap the Bandit", "hp": 240.0, "speed": 5.4, "damage": 14.0, "range": 2.3, "cooldown": 1.0, "ranged": false, "scale": 1.05, "height": 1.9, "aggro": 20.0},
	"cultist": {"name": "Shadow Cultist", "hp": 75.0, "speed": 4.0, "damage": 13.0, "range": 24.0, "cooldown": 3.0, "ranged": true, "scale": 1.0, "height": 1.8, "aggro": 24.0, "spell": "shadow"},
	"captain": {"name": "Bandit Captain", "hp": 320.0, "speed": 5.2, "damage": 18.0, "range": 2.5, "cooldown": 1.4, "ranged": false, "scale": 1.3, "height": 2.35, "aggro": 20.0, "boss": true},
	# Darkwood
	"spider": {"name": "Darkwood Spider", "hp": 65.0, "speed": 7.5, "damage": 7.0, "range": 2.1, "cooldown": 0.9, "ranged": false, "scale": 1.0, "height": 0.9, "aggro": 18.0},
	"skeleton": {"name": "Restless Skeleton", "hp": 95.0, "speed": 4.6, "damage": 11.0, "range": 2.1, "cooldown": 1.2, "ranged": false, "scale": 1.0, "height": 1.8, "aggro": 18.0},
	"ghoul": {"name": "Rotting Ghoul", "hp": 85.0, "speed": 6.4, "damage": 9.0, "range": 2.0, "cooldown": 1.0, "ranged": false, "scale": 1.0, "height": 1.7, "aggro": 20.0},
	"necromancer": {"name": "Necromancer", "hp": 85.0, "speed": 4.0, "damage": 14.0, "range": 24.0, "cooldown": 2.8, "ranged": true, "scale": 1.0, "height": 1.85, "aggro": 25.0, "spell": "necro"},
	"grave_lord": {"name": "The Grave Lord", "hp": 800.0, "speed": 4.8, "damage": 24.0, "range": 3.0, "cooldown": 1.5, "ranged": false, "scale": 1.6, "height": 2.9, "aggro": 22.0, "boss": true, "charge": true},
	# Goldfield Farms
	"gnoll": {"name": "Gnoll Raider", "hp": 100.0, "speed": 5.4, "damage": 11.0, "range": 2.2, "cooldown": 1.1, "ranged": false, "scale": 1.05, "height": 1.9, "aggro": 19.0},
	"gnoll_brute": {"name": "Gnoll Brute", "hp": 190.0, "speed": 4.6, "damage": 18.0, "range": 2.6, "cooldown": 1.5, "ranged": false, "scale": 1.3, "height": 2.4, "aggro": 19.0},
	"gnoll_shaman": {"name": "Gnoll Shaman", "hp": 90.0, "speed": 4.2, "damage": 15.0, "range": 24.0, "cooldown": 2.6, "ranged": true, "scale": 1.0, "height": 1.85, "aggro": 25.0, "spell": "nature"},
	"golem": {"name": "Harvest Golem", "hp": 240.0, "speed": 3.6, "damage": 20.0, "range": 2.6, "cooldown": 1.7, "ranged": false, "scale": 1.3, "height": 2.4, "aggro": 17.0},
	"warlord": {"name": "Gnoll Warlord Gash", "hp": 1100.0, "speed": 5.4, "damage": 26.0, "range": 3.0, "cooldown": 1.4, "ranged": false, "scale": 1.6, "height": 3.0, "aggro": 24.0, "boss": true, "charge": true},
	# Frostpeak Pass
	"snow_wolf": {"name": "Snow Wolf", "hp": 80.0, "speed": 7.4, "damage": 8.0, "range": 2.0, "cooldown": 0.9, "ranged": false, "scale": 1.0, "height": 1.1, "aggro": 19.0},
	"ice_troll": {"name": "Ice Troll", "hp": 180.0, "speed": 4.8, "damage": 17.0, "range": 2.6, "cooldown": 1.4, "ranged": false, "scale": 1.3, "height": 2.4, "aggro": 19.0},
	"frost_wraith": {"name": "Frost Wraith", "hp": 90.0, "speed": 4.4, "damage": 13.0, "range": 24.0, "cooldown": 2.6, "ranged": true, "scale": 1.0, "height": 2.0, "aggro": 25.0, "spell": "ice"},
	"frost_yeti": {"name": "Frost Yeti", "hp": 220.0, "speed": 4.2, "damage": 19.0, "range": 2.6, "cooldown": 1.5, "ranged": false, "scale": 1.3, "height": 2.4, "aggro": 18.0},
	"frostmaw": {"name": "Frostmaw the Ancient", "hp": 1400.0, "speed": 5.0, "damage": 28.0, "range": 3.4, "cooldown": 1.5, "ranged": false, "scale": 1.8, "height": 3.5, "aggro": 24.0, "boss": true, "charge": true},
	# Emberforge Canyon
	"hellhound": {"name": "Hellhound", "hp": 95.0, "speed": 7.8, "damage": 10.0, "range": 2.0, "cooldown": 0.9, "ranged": false, "scale": 1.0, "height": 1.1, "aggro": 20.0},
	"fire_imp": {"name": "Fire Imp", "hp": 80.0, "speed": 5.5, "damage": 12.0, "range": 22.0, "cooldown": 2.2, "ranged": true, "scale": 0.8, "height": 1.3, "aggro": 24.0, "spell": "fire"},
	"magma_golem": {"name": "Magma Golem", "hp": 280.0, "speed": 3.8, "damage": 22.0, "range": 2.8, "cooldown": 1.7, "ranged": false, "scale": 1.4, "height": 2.6, "aggro": 18.0},
	"flame_cultist": {"name": "Flame Cultist", "hp": 110.0, "speed": 4.4, "damage": 16.0, "range": 24.0, "cooldown": 2.6, "ranged": true, "scale": 1.0, "height": 1.8, "aggro": 25.0, "spell": "fire"},
	"raptor": {"name": "Canyon Raptor", "hp": 85.0, "speed": 8.2, "damage": 11.0, "range": 2.3, "cooldown": 0.95, "ranged": false, "scale": 1.2, "height": 1.7, "aggro": 24.0},
	"canyon_tyrant": {"name": "The Canyon Tyrant", "hp": 1600.0, "speed": 6.2, "damage": 34.0, "range": 4.6, "cooldown": 1.6, "ranged": false, "scale": 3.0, "height": 5.2, "aggro": 30.0, "boss": true, "charge": true},
	"pyrax": {"name": "Pyrax the Infernal", "hp": 1700.0, "speed": 5.4, "damage": 30.0, "range": 3.4, "cooldown": 1.4, "ranged": false, "scale": 1.9, "height": 3.6, "aggro": 26.0, "boss": true, "charge": true},
	# Sunken Coast
	"crab": {"name": "Giant Crab", "hp": 140.0, "speed": 5.0, "damage": 12.0, "range": 2.2, "cooldown": 1.2, "ranged": false, "scale": 1.0, "height": 1.0, "aggro": 17.0},
	"drowned": {"name": "Drowned Sailor", "hp": 120.0, "speed": 6.2, "damage": 13.0, "range": 2.0, "cooldown": 1.0, "ranged": false, "scale": 1.0, "height": 1.8, "aggro": 20.0},
	"sea_witch": {"name": "Sea Witch", "hp": 110.0, "speed": 4.4, "damage": 16.0, "range": 24.0, "cooldown": 2.6, "ranged": true, "scale": 1.0, "height": 2.0, "aggro": 25.0, "spell": "water"},
	"pirate": {"name": "Cursed Pirate", "hp": 140.0, "speed": 5.2, "damage": 15.0, "range": 2.3, "cooldown": 1.2, "ranged": false, "scale": 1.0, "height": 1.85, "aggro": 19.0},
	"guard": {"name": "Town Guard", "hp": 200.0, "speed": 5.4, "damage": 16.0, "range": 2.4, "cooldown": 1.0, "ranged": false, "scale": 1.0, "height": 1.8, "aggro": 34.0, "guard": true},
	"guard_archer": {"name": "Guard Crossbowman", "hp": 150.0, "speed": 5.0, "damage": 14.0, "range": 26.0, "cooldown": 1.8, "ranged": true, "scale": 1.0, "height": 1.8, "aggro": 38.0, "spell": "bolt", "guard": true},
	"wild_dino": {"name": "Wandering Terror", "hp": 700.0, "speed": 6.8, "damage": 25.0, "range": 3.2, "cooldown": 1.4, "ranged": false, "scale": 2.0, "height": 3.2, "aggro": 26.0, "charge": true},
	"captain_bones": {"name": "Captain Bones", "hp": 1900.0, "speed": 5.4, "damage": 32.0, "range": 3.2, "cooldown": 1.3, "ranged": false, "scale": 1.7, "height": 3.1, "aggro": 26.0, "boss": true, "charge": true},
}

## Special abilities per type (see _use_abilities).
const ABILITIES := {
	"cultist": ["shield"], "captain": ["slam", "enrage"], "spider": ["web"], "necromancer": ["summon", "heal"],
	"grave_lord": ["slam", "meteor", "enrage"], "gnoll_brute": ["slam"], "gnoll_shaman": ["heal"], "golem": ["slam"], "canyon_tyrant": ["slam", "enrage"], "wild_dino": ["slam"],
	"warlord": ["slam", "meteor", "enrage"],
	"ice_troll": ["slam"], "frost_yeti": ["slam"], "frostmaw": ["slam", "meteor", "enrage"], "frost_wraith": ["shield"],
	"magma_golem": ["slam"], "flame_cultist": ["heal"], "pyrax": ["slam", "meteor", "enrage"],
	"crab": ["slam"], "sea_witch": ["heal", "summon"], "captain_bones": ["slam", "meteor", "enrage", "summon"],
}

## What necromancer-style summoners raise.
const SUMMONS := {"necromancer": "skeleton", "sea_witch": "drowned", "captain_bones": "pirate"}

## Animated glTF models (assets/models). Types without an entry keep their hand-built model.
const MODELS := {
	"wolf": {"file": "wolf", "head": 0.95, "quad": true, "idle": "Idle", "walk": "Walk", "run": "Gallop", "attack": "Attack", "death": "Death", "hit": "Idle_HitReact_Left"},
	"spider": {"file": "spider", "head": 0.7, "quad": true, "idle": "Spider_Idle", "walk": "Spider_Walk", "run": "Spider_Walk", "attack": "Spider_Attack", "death": "Spider_Death"},
	"skeleton": {"file": "skeleton", "head": 1.65, "idle": "Skeleton_Idle", "walk": "Skeleton_Running", "run": "Skeleton_Running", "attack": "Skeleton_Attack", "death": "Skeleton_Death"},
	"grave_lord": {"file": "skeleton2", "head": 2.6, "tint": Color(0.65, 0.95, 0.7), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Sword", "death": "Death", "hit": "HitReact"},
	"ghoul": {"file": "zombie", "head": 1.55, "idle": "Idle", "walk": "Walk", "run": "Run_Arms", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"necromancer": {"file": "ghost", "head": 1.75, "tint": Color(0.55, 1.0, 0.6), "idle": "Flying_Idle", "walk": "Flying_Idle", "run": "Fast_Flying", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"bandit": {"file": "people/man1", "head": 1.6, "colors": {"Shirt": Color(0.3, 0.24, 0.17), "Shirt2": Color(0.45, 0.1, 0.08), "Pants": Color(0.2, 0.19, 0.16), "Shoes": Color(0.14, 0.1, 0.07)},
		"alt_file": "people/man2", "alt_colors": {"Shirt": Color(0.42, 0.12, 0.09), "Pants": Color(0.24, 0.21, 0.16), "Hair": Color(0.12, 0.08, 0.05)},
		"bandana": Color(0.72, 0.07, 0.06), "weapon": "machete", "idle": "Man_Idle", "walk": "Man_Walk", "run": "Man_Run", "attack": "Man_SwordSlash", "death": "Man_Death"},
	"captain": {"file": "people/man2", "head": 2.05, "colors": {"Shirt": Color(0.12, 0.11, 0.1), "Pants": Color(0.16, 0.12, 0.09), "Hair": Color(0.1, 0.07, 0.05)},
		"bandana": Color(0.6, 0.05, 0.05), "weapon": "sword", "idle": "Man_Idle", "walk": "Man_Walk", "run": "Man_Run", "attack": "Man_SwordSlash", "death": "Man_Death"},
	"guard": {"file": "people/man1", "head": 1.62, "colors": {"Shirt": Color(0.5, 0.52, 0.56), "Shirt2": Color(0.18, 0.25, 0.5), "Pants": Color(0.2, 0.2, 0.22), "Shoes": Color(0.1, 0.08, 0.06), "Hair": Color(0.2, 0.14, 0.08)},
		"weapon": "sword", "idle": "Man_Idle", "walk": "Man_Walk", "run": "Man_Run", "attack": "Man_SwordSlash", "death": "Man_Death"},
	"guard_archer": {"file": "people/man2", "head": 1.62, "colors": {"Shirt": Color(0.2, 0.27, 0.52), "Pants": Color(0.22, 0.22, 0.24), "Hair": Color(0.35, 0.22, 0.1)},
		"idle": "Man_Idle", "walk": "Man_Walk", "run": "Man_Run", "attack": "Man_Punch", "death": "Man_Death"},
	"cultist": {"file": "hooded", "head": 1.6, "tint": Color(0.7, 0.5, 1.0), "idle": "Idle_Neutral", "walk": "Walk", "run": "Run", "attack": "Punch_Right", "death": "Death", "hit": "HitRecieve"},
	"gnoll": {"file": "orc", "head": 1.7, "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Weapon", "death": "Death", "hit": "HitReact"},
	"gnoll_shaman": {"file": "orc", "head": 1.65, "tint": Color(0.85, 1.0, 0.6), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Wave", "death": "Death", "hit": "HitReact"},
	"gnoll_brute": {"file": "orc", "head": 2.15, "tint": Color(0.75, 0.6, 0.5), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"golem": {"path": "monsters/golem/golem.fbx", "texture": "monsters/golem/GOLEM_SKIN_rock_12.png", "head_bone": "GOLEM_ Head", "head": 2.4,
		"tint": Color(1.05, 0.95, 0.8), "idle": "idle", "walk": "walkNormal", "attack": "attack3", "attacks": ["attack3", "attack4", "attack6", "attack7"]},
	"warlord": {"file": "demon", "head": 2.7, "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Weapon", "death": "Death", "hit": "HitReact"},
	"snow_wolf": {"file": "wolf", "head": 0.95, "quad": true, "tint": Color(1.6, 1.65, 1.8), "idle": "Idle", "walk": "Walk", "run": "Gallop", "attack": "Attack", "death": "Death", "hit": "Idle_HitReact_Left"},
	"ice_troll": {"file": "orc", "head": 2.15, "tint": Color(0.6, 0.85, 1.25), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"frost_wraith": {"file": "ghost", "head": 1.75, "tint": Color(0.6, 0.85, 1.4), "idle": "Flying_Idle", "walk": "Flying_Idle", "run": "Fast_Flying", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"frost_yeti": {"file": "yeti", "head": 2.2, "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"frostmaw": {"file": "yeti", "head": 3.2, "tint": Color(0.8, 0.9, 1.2), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Weapon", "death": "Death", "hit": "HitReact"},
	"hellhound": {"file": "wolf", "head": 0.95, "quad": true, "tint": Color(0.7, 0.25, 0.15), "idle": "Idle", "walk": "Walk", "run": "Gallop", "attack": "Attack", "death": "Death", "hit": "Idle_HitReact_Left"},
	"fire_imp": {"file": "demon", "head": 1.15, "tint": Color(1.3, 0.75, 0.4), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"magma_golem": {"path": "monsters/golem/golem.fbx", "texture": "monsters/golem/GOLEM_SKIN_rock_12.png", "head_bone": "GOLEM_ Head", "head": 2.55,
		"tint": Color(0.42, 0.24, 0.2), "glow": Color(1.0, 0.32, 0.05), "idle": "idle", "walk": "walkNormal", "attack": "attack3", "attacks": ["attack3", "attack4", "attack6", "attack7"]},
	"raptor": {"path": "monsters/raptor/raptor.fbx", "yaw": 278.0, "texture": "monsters/raptor/CHARCHAROSAURUS.png", "head_bone": "CHARCHAROSAURSUS_ Head", "head": 1.5, "quad": true,
		"tint": Color(1.0, 0.85, 0.7), "idle": "idle", "walk": "walk", "attack": "bite", "hit": "getHitHeavy"},
	"canyon_tyrant": {"path": "monsters/raptor/raptor.fbx", "yaw": 278.0, "texture": "monsters/raptor/CHARCHAROSAURUS.png", "head_bone": "CHARCHAROSAURSUS_ Head", "head": 5.0, "quad": true,
		"tint": Color(0.75, 0.38, 0.28), "glow": Color(0.35, 0.08, 0.0), "idle": "idle", "walk": "walk", "attack": "bite", "hit": "getHitHeavy"},
	"wild_dino": {"path": "monsters/raptor/raptor.fbx", "yaw": 278.0, "texture": "monsters/raptor/CHARCHAROSAURUS.png", "head_bone": "CHARCHAROSAURSUS_ Head", "head": 2.9, "quad": true,
		"tint": Color(0.8, 0.8, 0.75), "level_tints": {1: Color(0.45, 0.55, 0.42), 2: Color(1.05, 0.85, 0.5), 3: Color(1.35, 1.45, 1.6), 5: Color(0.6, 0.85, 0.8)},
		"idle": "idle", "walk": "walk", "attack": "bite", "hit": "getHitHeavy"},
	"flame_cultist": {"file": "hooded", "head": 1.6, "tint": Color(1.2, 0.45, 0.25), "idle": "Idle_Neutral", "walk": "Walk", "run": "Run", "attack": "Punch_Right", "death": "Death", "hit": "HitRecieve"},
	"pyrax": {"file": "demon", "head": 3.3, "tint": Color(1.25, 0.6, 0.4), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Weapon", "death": "Death", "hit": "HitReact"},
	"crab": {"file": "spider", "head": 0.75, "quad": true, "tint": Color(1.6, 0.6, 0.35), "idle": "Spider_Idle", "walk": "Spider_Walk", "run": "Spider_Walk", "attack": "Spider_Attack", "death": "Spider_Death"},
	"drowned": {"file": "zombie", "head": 1.55, "tint": Color(0.6, 0.95, 0.9), "idle": "Idle", "walk": "Walk", "run": "Run_Arms", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"sea_witch": {"file": "ghost", "head": 1.75, "tint": Color(0.5, 1.1, 1.0), "idle": "Flying_Idle", "walk": "Flying_Idle", "run": "Fast_Flying", "attack": "Punch", "death": "Death", "hit": "HitReact"},
	"pirate": {"file": "skeleton2", "head": 1.62, "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Sword", "death": "Death", "hit": "HitReact"},
	"captain_bones": {"file": "skeleton2", "head": 2.8, "tint": Color(1.1, 0.95, 0.75), "idle": "Idle", "walk": "Walk", "run": "Run", "attack": "Sword", "death": "Death", "hit": "HitReact"},
}

const LEASH := 40.0
const LOSE_TIME := 6.0     # guards give up on a wanted player unseen this long...
const LOSE_DIST := 70.0    # ...or this far away

const HUMANOIDS := ["bandit", "cap_bandit", "captain", "cultist", "gnoll", "gnoll_brute", "gnoll_shaman", "warlord", "ghoul", "kobold", "geomancer",
	"ice_troll", "flame_cultist", "drowned", "pirate", "captain_bones", "fire_imp", "pyrax"]

enum State { IDLE, CHASE, DEAD, RETURN }

static var _bar_tex: ImageTexture

var type := "bandit"
var level := 1                     # set by the world before adding; scales health and damage
var elite := false                 # tougher named variant with better loot
var base_hp := 100.0
var _far := false
var _far_t := randf() * 0.5
var foe: Node3D = null              # current target when it isn't the player (guards, villagers, monsters)
var _pick_t := randf() * 0.5
var neutral := false               # guards: peaceful until the player is wanted
var world: Node
var display_name := ""
var title_override := ""            # named monsters (travel quests): shown instead of the type name
var max_hp := 100.0
var hp := 100.0
var speed := 4.0
var damage := 10.0
var attack_range := 2.0
var cooldown := 1.0
var ranged := false
var boss := false
var can_charge := false
var aggro_range := 18.0
var spell_kind := "fire"
var blood_color := Color(0.6, 0.04, 0.04)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var state := State.IDLE
var home := Vector3.ZERO
var frozen_t := 0.0
var chill_t := 0.0
var _dot_dps := 0.0
var _dot_t := 0.0
var _dot_tick := 0.0
var _wander_target := Vector3.ZERO
var _wander_wait := 0.0
var _wander_timer := 0.0
var _attack_cd := 0.0
var _attack_t := -1.0
var _attack_done := false
var _charge_t := 0.0
var _charge_cd := 3.0
var _charge_dir := Vector3.ZERO
var _avoid_t := 0.0
var _avoid_angle := 0.0
var _strafe_sign := 1.0
var _strafe_t := 0.0
var _los_t := 0.0
var _unseen_t := 0.0               # guards: how long the wanted player has been out of sight
var _has_los := false
var _walk_phase := 0.0
var _hurt_t := 0.0
var _voice_t := randf_range(4.0, 12.0)
var _scale := 1.0
var _height := 1.8
var _eye_height := 1.6
var _bob_offset := 0.0

var visual: Node3D
var head_node: Node3D
var head_radius := 0.2
var _head_base := Vector3.ZERO
var l_arm: Node3D
var r_arm: Node3D
var l_leg: Node3D
var r_leg: Node3D
var legs: Array[Node3D] = []
var tail: Node3D
var cast_glow: Array[Node3D] = []
var name_label: Label3D
var bar_bg: Sprite3D
var bar_fg: Sprite3D
var ice_block: MeshInstance3D

var summoned := false
var abilities: Array = []
var _ability_cd: Dictionary = {}
var shield_hp := 0.0
var _shield_fx: MeshInstance3D
var enraged := false
var _summons_left := 2
var stun_t := 0.0
var _burn_t := 0.0
var _burn_dps := 0.0
var _burn_tick := 0.0
var _burn_fx: CPUParticles3D
var _slam_t := -1.0
var _slam_ring: Node3D
var _hit_t := 0.0
var anim: AnimationPlayer
var _anim_map: Dictionary = {}
var _anim_current := ""
var _model_cfg: Dictionary = {}
var _attack_anims: Array = []

# GEQO fight tactics (see Tactics): firing spots, flanking, hiding when badly hurt
const FLANKERS := ["wolf", "snow_wolf", "hellhound", "raptor", "gnoll", "gnoll_brute", "kobold", "bandit", "cap_bandit",
	"skeleton", "ghoul", "pirate", "drowned", "spider", "crab"]
const COWARDS := ["bandit", "cap_bandit", "kobold", "gnoll", "cultist", "flame_cultist", "pirate", "geomancer", "gnoll_shaman"]
var tactics: Tactics
var _tactic_t := randf_range(0.5, 2.0)

# AI brain shouts (Northvale): which personality speaks for this enemy, and how high its voice is
const AI_KINDS := {"bandit": "bandit", "cap_bandit": "bandit", "captain": "captain", "kobold": "kobold", "geomancer": "geomancer", "cultist": "cultist"}
var _ai_pitch := randf_range(0.92, 1.06)
var _ai_hurt_said := false
var _ai_taunt_t := randf_range(6.0, 14.0)
var _coward := false
var _covered := false
var _cover_t := 0.0


## Models that come without materials (FBX + a texture): one textured material for every surface,
## with the type's tint and an optional glow (lava cracks). Some types change colour per location.
func _skin_model(model: Node3D, cfg: Dictionary) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/models/" + str(cfg["texture"]))
	var tint: Color = cfg.get("tint", Color.WHITE)
	var by_level: Dictionary = cfg.get("level_tints", {})
	if by_level.has(Game.level_index):
		tint = by_level[Game.level_index]
	m.albedo_color = tint
	m.roughness = 0.85
	if cfg.has("glow"):
		m.emission_enabled = true
		m.emission = cfg["glow"]
		m.emission_energy_multiplier = 1.4
		m.emission_texture = m.albedo_texture
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			mi.set_surface_override_material(i, m)


func _ready() -> void:
	var cfg: Dictionary = TYPES[type]
	display_name = Loc.t(cfg["name"])
	base_hp = cfg["hp"]
	max_hp = base_hp * (1.0 + 0.18 * (level - 1)) * (2.6 if elite else 1.0)
	hp = max_hp
	speed = cfg["speed"] * (1.08 if elite else 1.0)
	damage = cfg["damage"] * (1.0 + 0.12 * (level - 1)) * (1.4 if elite else 1.0)
	if elite:
		display_name = Loc.t("Elite") + " " + display_name
	if _has_gun():
		display_name = Loc.t("Guard Rifleman" if world.tech_level >= 4 else "Guard Musketeer")
	if title_override != "":
		display_name = Loc.t(title_override)
	attack_range = cfg["range"]
	cooldown = cfg["cooldown"]
	ranged = cfg["ranged"]
	aggro_range = cfg["aggro"]
	spell_kind = cfg.get("spell", "fire")
	boss = cfg.get("boss", false)
	can_charge = cfg.get("charge", false)
	neutral = cfg.get("guard", false)
	if neutral:
		add_to_group("allies")
	_scale = cfg["scale"]
	_height = cfg["height"]
	_eye_height = _height * 0.85
	_bob_offset = randf() * TAU

	add_to_group("enemies")
	add_to_group("damageable")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_max_angle = deg_to_rad(50.0)
	home = global_position
	_wander_target = home
	_wander_wait = randf_range(0.5, 3.0)
	_attack_cd = randf_range(0.0, 1.0)

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5 if type == "wolf" or type == "spider" else 0.36 * _scale
	cap.height = maxf(_height, cap.radius * 2.0 + 0.01)
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)

	_coward = type in COWARDS and randf() < 0.4
	abilities = ABILITIES.get(type, [])
	for a in abilities:
		_ability_cd[a] = randf_range(2.0, 5.0)

	visual = Node3D.new()
	add_child(visual)
	if MODELS.has(type) and _build_model(MODELS[type]):
		_scale = 1.0
	else:
		_build_procedural()
	visual.scale = Vector3.ONE * _scale * (1.15 if elite else 1.0)
	if elite:
		var aura := OmniLight3D.new()
		aura.light_color = Color(1.0, 0.75, 0.25)
		aura.light_energy = 1.2
		aura.omni_range = 3.5
		aura.position.y = 0.6
		add_child(aura)
	if head_node:
		_head_base = head_node.position
	for g in cast_glow:
		g.visible = false
	_build_overhead(_height + 0.3)
	_build_ice_block()
	_build_effects()
	rotation.y = randf() * TAU


func _build_procedural() -> void:
	match type:
		"kobold": _build_kobold(false)
		"geomancer": _build_kobold(true)
		"wolf": _build_wolf()
		"bandit": _build_bandit(false)
		"captain": _build_bandit(true)
		"cap_bandit": _build_cap_bandit()
		"cultist": _build_cultist()
		"spider": _build_spider()
		"skeleton": _build_skeleton(false)
		"grave_lord": _build_skeleton(true)
		"ghoul": _build_ghoul()
		"necromancer": _build_necromancer()
		"gnoll": _build_gnoll(0)
		"gnoll_brute": _build_gnoll(1)
		"gnoll_shaman": _build_gnoll(2)
		"warlord": _build_gnoll(3)
		"golem": _build_golem()


## Loads an animated glTF, scales it so its head bone sits at cfg.head meters, tints it,
## and attaches the headshot target to the head bone. Returns false if it can't be used.
func _build_model(cfg: Dictionary) -> bool:
	# some types alternate between two body models ("alt_file" / "alt_colors")
	if cfg.has("alt_file") and randf() < 0.5:
		cfg = cfg.duplicate()
		cfg["file"] = cfg["alt_file"]
		cfg["colors"] = cfg.get("alt_colors", cfg.get("colors", {}))
	var model: Node3D
	var person := str(cfg.get("file", "")).begins_with("people/")
	if person:
		# humans (bandits, guards): Universal Base Characters with painted clothes
		var pc: Dictionary = cfg.get("colors", {}).duplicate()
		pc["outfit"] = cfg.get("outfit", "guard" if cfg.get("guard", false) or TYPES[type].get("guard", false) else "bandit")
		var built := People.build(visual, cfg["file"], pc, float(cfg["head"]))
		if built.is_empty():
			return false
		model = built["model"]
		anim = built["anim"]
	else:
		# "path": any model under assets/models (e.g. an FBX); "file": a Quaternius .glb
		var path: String = "res://assets/models/" + str(cfg["path"]) if cfg.has("path") else "res://assets/models/%s.glb" % cfg["file"]
		if not ResourceLoader.exists(path):
			return false
		var scene := load(path) as PackedScene
		if scene == null:
			return false
		model = scene.instantiate()
		visual.add_child(model)
		model.rotation.y = deg_to_rad(float(cfg.get("yaw", 180.0)))   # Quaternius models face +Z, ours face -Z
		anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if cfg.has("texture"):
			_skin_model(model, cfg)
	if anim == null:
		model.queue_free()
		return false
	_model_cfg = cfg
	var names := anim.get_animation_list()
	for key in ["idle", "walk", "run", "attack", "death", "hit"]:
		if not cfg.has(key):
			continue
		var want: String = cfg[key]
		for n in names:
			if n == want or n.ends_with("|" + want) or n.contains("|" + want + "|"):
				_anim_map[key] = n
				break
	# several attack swings to pick from
	_attack_anims.clear()
	for want in cfg.get("attacks", []):
		for n in names:
			if n == want or n.ends_with("|" + want):
				_attack_anims.append(n)
				break
	for key in ["idle", "walk", "run"]:
		if _anim_map.has(key):
			anim.get_animation(_anim_map[key]).loop_mode = Animation.LOOP_LINEAR
	if _anim_map.has("idle"):
		anim.play(_anim_map["idle"])
		anim.seek(randf() * 0.5, true)
	# measure the head bone in the idle pose and scale to the wanted height
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	var head_y := 0.0
	var head_bone := -1
	var sk: Skeleton3D = null
	if not skeletons.is_empty():
		sk = skeletons[0]
		head_bone = sk.find_bone(str(cfg.get("head_bone", "Head")))
		if head_bone >= 0:
			var gp := sk.global_transform * sk.get_bone_global_pose(head_bone).origin
			head_y = gp.y - global_position.y
	# models placed by path (FBX) can be authored at any unit size and off-centre: measure the
	# head from the lowest bone (the feet), and re-centre on the root bone after scaling
	var low_y := 0.0
	if cfg.has("path") and sk:
		low_y = INF
		for b in sk.get_bone_count():
			low_y = minf(low_y, (sk.global_transform * sk.get_bone_global_pose(b).origin).y - global_position.y)
		if head_bone >= 0:
			head_y -= low_y
	if head_y <= (0.0001 if cfg.has("path") else 0.05):
		head_y = 1.6
	var s: float = float(cfg["head"]) / head_y
	if person:
		s = model.scale.x
	else:
		model.scale = Vector3.ONE * s
	if cfg.has("path") and sk:
		var root_l := visual.to_local(sk.global_transform * sk.get_bone_global_pose(0).origin)
		var feet := INF
		for b in sk.get_bone_count():
			feet = minf(feet, visual.to_local(sk.global_transform * sk.get_bone_global_pose(b).origin).y)
		model.position -= Vector3(root_l.x, feet - float(cfg.get("foot_offset", 0.05)), root_l.z)
	if cfg.has("tint") and not cfg.has("texture"):
		var tint: Color = cfg["tint"]
		for n in model.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var m := mi.get_active_material(i)
				if m is BaseMaterial3D:
					var dm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
					dm.albedo_color = dm.albedo_color * tint
					mi.set_surface_override_material(i, dm)
	if cfg.has("colors") and not person:
		var colors: Dictionary = cfg["colors"]
		for n in model.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var m := mi.get_active_material(i)
				if m is BaseMaterial3D and colors.has(m.resource_name):
					var dm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
					var c: Color = colors[m.resource_name]
					dm.albedo_color = c * randf_range(0.85, 1.1)
					dm.albedo_color.a = 1.0
					mi.set_surface_override_material(i, dm)
	if sk and (cfg.has("bandana") or cfg.has("weapon") or _has_gun()):
		_attach_gear(sk, cfg, s)
	# headshot target follows the head bone
	if sk and head_bone >= 0:
		var att := BoneAttachment3D.new()
		att.bone_idx = head_bone
		sk.add_child(att)
		head_node = att
	else:
		head_node = _pivot(Vector3(0, float(cfg["head"]), 0))
	head_radius = 0.2 * float(cfg["head"]) / 1.6
	if cfg.get("quad", false):
		head_radius = 0.3
	# casters get glowing hands so the player can see the cast coming
	if ranged or "heal" in abilities or "shield" in abilities:
		var col := _spell_color()
		var g := MeshKit.sphere(visual, 0.25, Vector3(0, _height * 0.7, -0.5), MeshKit.glow(Color(col, 0.75)))
		cast_glow.append(g)
	return true


func _spell_color() -> Color:
	match spell_kind:
		"fire": return Color(1.0, 0.45, 0.1)
		"necro": return Color(0.35, 1.0, 0.35)
		"nature": return Color(0.8, 1.0, 0.25)
		"ice": return Color(0.6, 0.85, 1.0)
		"water": return Color(0.3, 0.9, 0.85)
		"bolt": return Color(0.95, 0.85, 0.6)
		_: return Color(0.65, 0.25, 1.0)


func _build_effects() -> void:
	_burn_fx = CPUParticles3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.12
	fm.height = 0.24
	fm.radial_segments = 6
	fm.rings = 3
	fm.material = MeshKit.glow(Color(1.0, 0.5, 0.1, 0.7))
	_burn_fx.mesh = fm
	_burn_fx.amount = 24
	_burn_fx.lifetime = 0.6
	_burn_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_burn_fx.emission_box_extents = Vector3(0.3, _height * 0.4, 0.3)
	_burn_fx.position.y = _height * 0.5
	_burn_fx.gravity = Vector3(0, 3.0, 0)
	_burn_fx.local_coords = false
	_burn_fx.emitting = false
	add_child(_burn_fx)
	_shield_fx = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = maxf(0.8, _height * 0.6)
	sm.height = sm.radius * 2.0
	_shield_fx.mesh = sm
	_shield_fx.material_override = MeshKit.glow(Color(0.6, 0.4, 1.0, 0.25))
	_shield_fx.position.y = _height * 0.5
	_shield_fx.visible = false
	add_child(_shield_fx)


# --------------------------------------------------------------------------- models

func _pivot(pos: Vector3, parent: Node3D = null) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	(parent if parent else visual).add_child(p)
	return p


func _legs(pants: Material, boots: Material, thick := 0.17) -> void:
	l_leg = _pivot(Vector3(-0.13, 0.9, 0))
	MeshKit.box(l_leg, Vector3(thick, 0.82, thick + 0.02), Vector3(0, -0.41, 0), pants)
	MeshKit.box(l_leg, Vector3(thick + 0.02, 0.15, 0.28), Vector3(0, -0.83, -0.04), boots)
	r_leg = _pivot(Vector3(0.13, 0.9, 0))
	MeshKit.box(r_leg, Vector3(thick, 0.82, thick + 0.02), Vector3(0, -0.41, 0), pants)
	MeshKit.box(r_leg, Vector3(thick + 0.02, 0.15, 0.28), Vector3(0, -0.83, -0.04), boots)


func _robe(cloth: Material) -> void:
	MeshKit.cyl(visual, 0.24, 0.45, 1.0, Vector3(0, 0.5, 0), cloth)


func _torso_arms(skin: Material, shirt: Material, arm_mat: Material, arm_thick := 0.14) -> void:
	MeshKit.box(visual, Vector3(0.5, 0.66, 0.28), Vector3(0, 1.23, 0), shirt)
	MeshKit.box(visual, Vector3(0.52, 0.09, 0.3), Vector3(0, 0.93, 0), MeshKit.mat(Color(0.22, 0.15, 0.08)))
	l_arm = _pivot(Vector3(-0.33, 1.5, 0))
	MeshKit.box(l_arm, Vector3(arm_thick, 0.6, arm_thick + 0.01), Vector3(0, -0.28, 0), arm_mat)
	MeshKit.sphere(l_arm, 0.08, Vector3(0, -0.62, 0), skin)
	r_arm = _pivot(Vector3(0.33, 1.5, 0))
	MeshKit.box(r_arm, Vector3(arm_thick, 0.6, arm_thick + 0.01), Vector3(0, -0.28, 0), arm_mat)
	MeshKit.sphere(r_arm, 0.08, Vector3(0, -0.62, 0), skin)
	head_node = _pivot(Vector3(0, 1.76, 0))
	head_radius = 0.2


func _hand_glow(color: Color) -> void:
	for arm in [l_arm, r_arm]:
		var g := MeshKit.sphere(arm, 0.13, Vector3(0, -0.66, 0), MeshKit.glow(Color(color, 0.8)))
		cast_glow.append(g)


func _eyes(parent: Node3D, color: Color, y: float, z: float, spread := 0.07, size := 0.03) -> void:
	var m := MeshKit.unshaded(color)
	MeshKit.sphere(parent, size, Vector3(-spread, y, z), m)
	MeshKit.sphere(parent, size, Vector3(spread, y, z), m)


func _build_kobold(caster: bool) -> void:
	var fur := MeshKit.mat(Color(0.50, 0.36, 0.22))
	var fur_dark := MeshKit.mat(Color(0.32, 0.22, 0.13))
	var rags := MeshKit.mat(Color(0.42, 0.38, 0.30))
	var robe := MeshKit.mat(Color(0.55, 0.16, 0.10))
	blood_color = Color(0.55, 0.05, 0.03)
	if caster:
		_robe(robe)
		_torso_arms(fur, robe, robe)
	else:
		_legs(rags, fur_dark)
		_torso_arms(fur, fur, fur)
		MeshKit.box(visual, Vector3(0.52, 0.3, 0.3), Vector3(0, 1.0, 0), rags)
	MeshKit.sphere(head_node, 0.19, Vector3.ZERO, fur)
	MeshKit.box(head_node, Vector3(0.15, 0.13, 0.25), Vector3(0, -0.05, -0.18), fur)
	MeshKit.sphere(head_node, 0.04, Vector3(0, -0.02, -0.31), MeshKit.mat(Color(0.1, 0.06, 0.05)))
	MeshKit.box(head_node, Vector3(0.07, 0.16, 0.13), Vector3(-0.15, 0.13, 0.02), fur_dark, Vector3(0, 0, 25))
	MeshKit.box(head_node, Vector3(0.07, 0.16, 0.13), Vector3(0.15, 0.13, 0.02), fur_dark, Vector3(0, 0, -25))
	_eyes(head_node, Color(1.0, 0.85, 0.2), 0.04, -0.16, 0.08)
	MeshKit.cyl(head_node, 0.05, 0.055, 0.24, Vector3(0, 0.28, 0), MeshKit.mat(Color(0.95, 0.92, 0.8)))
	MeshKit.sphere(head_node, 0.05, Vector3(0, 0.44, 0), MeshKit.unshaded(Color(1.0, 0.8, 0.3)), Vector3(1, 1.6, 1))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.4)
	light.light_energy = 1.0
	light.omni_range = 4.0
	light.position = Vector3(0, 0.5, 0)
	head_node.add_child(light)
	if caster:
		var wood := MeshKit.mat(Color(0.35, 0.22, 0.1))
		MeshKit.cyl(r_arm, 0.025, 0.025, 1.3, Vector3(0, -0.62, -0.05), wood, Vector3.ZERO, 6)
		MeshKit.sphere(r_arm, 0.09, Vector3(0, 0.0, -0.05), MeshKit.unshaded(Color(1.0, 0.5, 0.15)))
		_hand_glow(Color(1.0, 0.45, 0.1))
	else:
		var wood := MeshKit.mat(Color(0.4, 0.26, 0.12))
		var iron := MeshKit.mat(Color(0.35, 0.35, 0.38), 0.5, 0.5)
		MeshKit.box(r_arm, Vector3(0.04, 0.04, 0.7), Vector3(0, -0.62, -0.28), wood)
		MeshKit.box(r_arm, Vector3(0.05, 0.42, 0.06), Vector3(0, -0.62, -0.6), iron)


func _build_wolf() -> void:
	var fur := MeshKit.mat(Color(0.45, 0.43, 0.40))
	var fur_dark := MeshKit.mat(Color(0.28, 0.27, 0.26))
	MeshKit.box(visual, Vector3(0.42, 0.44, 1.05), Vector3(0, 0.72, 0.08), fur)
	MeshKit.box(visual, Vector3(0.48, 0.52, 0.45), Vector3(0, 0.8, -0.3), fur_dark)
	head_node = _pivot(Vector3(0, 0.96, -0.62))
	MeshKit.box(head_node, Vector3(0.3, 0.28, 0.32), Vector3.ZERO, fur)
	MeshKit.box(head_node, Vector3(0.16, 0.14, 0.26), Vector3(0, -0.05, -0.25), fur_dark)
	MeshKit.box(head_node, Vector3(0.06, 0.04, 0.05), Vector3(0, 0.0, -0.39), MeshKit.mat(Color(0.05, 0.05, 0.05)))
	MeshKit.prism(head_node, Vector3(0.09, 0.15, 0.06), Vector3(-0.09, 0.21, 0.06), fur_dark)
	MeshKit.prism(head_node, Vector3(0.09, 0.15, 0.06), Vector3(0.09, 0.21, 0.06), fur_dark)
	_eyes(head_node, Color(1.0, 0.8, 0.2), 0.05, -0.16, 0.08)
	head_radius = 0.26
	for p in [Vector3(-0.14, 0.52, -0.35), Vector3(0.14, 0.52, -0.35), Vector3(-0.14, 0.52, 0.42), Vector3(0.14, 0.52, 0.42)]:
		var leg := _pivot(p)
		MeshKit.box(leg, Vector3(0.11, 0.52, 0.12), Vector3(0, -0.26, 0), fur_dark)
		legs.append(leg)
	tail = _pivot(Vector3(0, 0.86, 0.58))
	MeshKit.box(tail, Vector3(0.1, 0.1, 0.5), Vector3(0, 0, 0.24), fur)
	tail.rotation.x = 0.5


func _build_bandit(captain: bool) -> void:
	var skin := MeshKit.mat(Color(0.86, 0.67, 0.53))
	var leather := MeshKit.mat(Color(0.36, 0.23, 0.12))
	var pants := MeshKit.mat(Color(0.2, 0.2, 0.23))
	var boots := MeshKit.mat(Color(0.1, 0.08, 0.06))
	var red := MeshKit.mat(Color(0.72, 0.08, 0.08))
	var steel := MeshKit.mat(Color(0.7, 0.72, 0.75), 0.3, 0.8)
	_legs(pants, boots)
	_torso_arms(skin, leather, leather)
	MeshKit.sphere(head_node, 0.17, Vector3.ZERO, skin)
	MeshKit.box(head_node, Vector3(0.3, 0.14, 0.12), Vector3(0, -0.06, -0.12), red)
	MeshKit.sphere(head_node, 0.18, Vector3(0, 0.04, 0.02), red, Vector3(1.0, 0.85, 1.0))
	_eyes(head_node, Color(0.05, 0.05, 0.05), 0.03, -0.155, 0.06, 0.025)
	MeshKit.box(visual, Vector3(0.52, 0.5, 0.05), Vector3(0, 1.25, -0.15), red)
	if captain:
		var plate := MeshKit.mat(Color(0.45, 0.45, 0.5), 0.4, 0.7)
		MeshKit.box(l_arm, Vector3(0.26, 0.14, 0.26), Vector3(0, 0.02, 0), plate)
		MeshKit.box(r_arm, Vector3(0.26, 0.14, 0.26), Vector3(0, 0.02, 0), plate)
		MeshKit.box(visual, Vector3(0.55, 1.2, 0.04), Vector3(0, 0.95, 0.17), red, Vector3(8, 0, 0))
		MeshKit.cyl(head_node, 0.28, 0.28, 0.04, Vector3(0, 0.12, 0), MeshKit.mat(Color(0.1, 0.1, 0.1)))
		MeshKit.cyl(head_node, 0.13, 0.16, 0.16, Vector3(0, 0.2, 0), MeshKit.mat(Color(0.1, 0.1, 0.1)))
		MeshKit.box(r_arm, Vector3(0.05, 0.08, 1.1), Vector3(0, -0.62, -0.55), steel)
		MeshKit.box(r_arm, Vector3(0.25, 0.05, 0.05), Vector3(0, -0.62, -0.06), MeshKit.mat(Color(0.8, 0.65, 0.2), 0.4, 0.7))
	else:
		MeshKit.box(r_arm, Vector3(0.04, 0.06, 0.55), Vector3(0, -0.62, -0.28), steel)
		MeshKit.box(r_arm, Vector3(0.16, 0.04, 0.04), Vector3(0, -0.62, -0.03), leather)


static var _print_shirt: StandardMaterial3D


## White t-shirt with a grey sketch print (rows of little drawings).
static func _shirt_material() -> StandardMaterial3D:
	if _print_shirt:
		return _print_shirt
	var s := 128
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.94, 0.94, 0.92))
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for row in range(4, s, 16):
		var x := 0
		while x < s:
			var w := rng.randi_range(6, 14)
			var h := rng.randi_range(4, 9)
			var col := Color(0.3, 0.32, 0.36) if rng.randf() < 0.7 else Color(0.55, 0.57, 0.6)
			for yy in h:
				for xx in w:
					# sketchy outlines instead of solid blocks
					if yy == 0 or yy == h - 1 or xx == 0 or xx == w - 1 or rng.randf() < 0.25:
						img.set_pixel((x + xx) % s, (row + yy) % s, col)
			x += w + rng.randi_range(2, 6)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(2.5, 2.5, 2.5)
	m.roughness = 0.9
	_print_shirt = m
	return m


## Unique bandit: flat cap, printed white t-shirt, black trousers, dark sneakers, watch.
## Bandana around the head and a blade in the right hand, placed in the idle pose and then
## pinned to the bones so they follow the animation. Sizes are in metres for a 1.62 m head height.
func _has_gun() -> bool:
	return TYPES[type].get("guard", false) and world != null and world.tech_level >= 2


func _attach_gear(sk: Skeleton3D, cfg: Dictionary, _s: float) -> void:
	var k: float = float(cfg["head"]) / 1.62
	var fwd := -global_transform.basis.z
	if cfg.has("bandana"):
		var hb := sk.find_bone("Head")
		if hb >= 0:
			var att := BoneAttachment3D.new()
			att.bone_idx = hb
			sk.add_child(att)
			var hp := (sk.global_transform * sk.get_bone_global_pose(hb)).origin
			var holder := Node3D.new()
			add_child(holder)
			holder.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP).scaled(Vector3.ONE * k), hp + Vector3.UP * 0.135 * k)
			var bm := MeshKit.mat(cfg["bandana"], 0.9)
			var tm := TorusMesh.new()
			tm.inner_radius = 0.125
			tm.outer_radius = 0.152
			tm.rings = 20
			tm.ring_segments = 6
			var band := MeshKit.inst(holder, tm, Vector3.ZERO, bm, Vector3(-8, 0, 0))
			band.scale = Vector3(1.0, 0.9, 1.12)
			MeshKit.box(holder, Vector3(0.045, 0.14, 0.015), Vector3(0.025, -0.07, 0.165), bm, Vector3(18, 0, 14))
			MeshKit.box(holder, Vector3(0.045, 0.12, 0.015), Vector3(-0.02, -0.06, 0.168), bm, Vector3(14, 0, -10))
			holder.reparent(att, true)
	if cfg.has("weapon") or _has_gun():
		var pb := sk.find_bone("Palm.R")
		if pb < 0:
			pb = sk.find_bone("hand_r")
		if pb >= 0:
			var att := BoneAttachment3D.new()
			att.bone_idx = pb
			sk.add_child(att)
			var pp := (sk.global_transform * sk.get_bone_global_pose(pb)).origin
			var holder := Node3D.new()
			add_child(holder)
			holder.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP).scaled(Vector3.ONE * k), pp + Vector3.DOWN * 0.05 * k)
			var steel := MeshKit.mat(Color(0.62, 0.62, 0.66), 0.3, 0.85)
			var grip := MeshKit.mat(Color(0.2, 0.13, 0.08))
			if _has_gun():
				# the guards learned gunsmithing from the player: musket, later a rifle
				var wood := MeshKit.mat(Color(0.38, 0.24, 0.14))
				var rifle: bool = world.tech_level >= 4
				MeshKit.box(holder, Vector3(0.045, 0.09, 0.42), Vector3(0, -0.02, 0.12), wood)
				MeshKit.box(holder, Vector3(0.04, 0.05, 0.5 if rifle else 0.62), Vector3(0, 0.01, -0.3 if rifle else -0.36), wood)
				MeshKit.cyl(holder, 0.012, 0.014, 0.75 if rifle else 0.9, Vector3(0, 0.04, -0.5 if rifle else -0.6), steel, Vector3(90, 0, 0), 6)
				if rifle:
					MeshKit.box(holder, Vector3(0.035, 0.12, 0.05), Vector3(0, -0.08, -0.12), steel)
					MeshKit.cyl(holder, 0.018, 0.018, 0.18, Vector3(0, 0.1, -0.1), steel, Vector3(90, 0, 0), 6)
				holder.reparent(att, true)
				return
			var big: bool = cfg["weapon"] == "sword"
			if big and Arms.enabled():
				Arms.sword(holder, 0.95)
				holder.reparent(att, true)
				return
			var blade_len := 0.85 if big else 0.55
			MeshKit.cyl(holder, 0.018, 0.02, 0.14, Vector3.ZERO, grip, Vector3(90, 0, 0), 6)
			MeshKit.box(holder, Vector3(0.14 if big else 0.06, 0.02, 0.025), Vector3(0, 0, -0.075), steel)
			MeshKit.box(holder, Vector3(0.006, 0.05 if big else 0.07, blade_len), Vector3(0, 0.0, -0.08 - blade_len * 0.5), steel, Vector3(8, 0, 0))
			holder.reparent(att, true)


func _build_cap_bandit() -> void:
	var skin := MeshKit.mat(Color(0.93, 0.76, 0.66))
	var shirt := _shirt_material()
	var pants := MeshKit.mat(Color(0.08, 0.08, 0.09))
	var shoes := MeshKit.mat(Color(0.2, 0.2, 0.22))
	var sole := MeshKit.mat(Color(0.12, 0.12, 0.13))
	var cap := MeshKit.mat(Color(0.42, 0.42, 0.4))
	var hair := MeshKit.mat(Color(0.22, 0.16, 0.11))
	_legs(pants, shoes, 0.21)
	for leg in [l_leg, r_leg]:
		MeshKit.box(leg, Vector3(0.23, 0.05, 0.31), Vector3(0, -0.9, -0.05), sole)
	_torso_arms(skin, shirt, skin, 0.13)
	# a bit broader in the chest and belly, shirt hangs over the waist
	MeshKit.box(visual, Vector3(0.58, 0.5, 0.34), Vector3(0, 1.17, 0), shirt)
	for arm in [l_arm, r_arm]:
		MeshKit.box(arm, Vector3(0.18, 0.26, 0.19), Vector3(0, -0.1, 0), shirt)   # short sleeves
	# watch on the left wrist
	MeshKit.box(l_arm, Vector3(0.155, 0.05, 0.155), Vector3(0, -0.53, 0), MeshKit.mat(Color(0.05, 0.05, 0.06), 0.3, 0.4))
	MeshKit.box(l_arm, Vector3(0.06, 0.055, 0.06), Vector3(0, -0.53, -0.07), MeshKit.mat(Color(0.75, 0.78, 0.82), 0.2, 0.8))
	# head: short dark hair under a grey flat cap with a brim
	MeshKit.sphere(head_node, 0.17, Vector3.ZERO, skin, Vector3(1.0, 1.05, 1.0))
	MeshKit.sphere(head_node, 0.172, Vector3(0, 0.02, 0.025), hair, Vector3(1.0, 0.95, 1.0))
	MeshKit.cyl(head_node, 0.185, 0.19, 0.09, Vector3(0, 0.12, 0.0), cap, Vector3(-4, 0, 0), 16)
	MeshKit.box(head_node, Vector3(0.24, 0.025, 0.13), Vector3(0, 0.085, -0.2), cap, Vector3(-8, 0, 0))
	_eyes(head_node, Color(0.15, 0.1, 0.08), 0.0, -0.158, 0.06, 0.022)
	MeshKit.box(head_node, Vector3(0.07, 0.02, 0.02), Vector3(0, -0.09, -0.16), MeshKit.mat(Color(0.7, 0.45, 0.42)))
	# weapon: wooden baseball bat
	MeshKit.cyl(r_arm, 0.045, 0.025, 0.8, Vector3(0, -0.62, -0.4), MeshKit.mat(Color(0.65, 0.45, 0.25), 0.6), Vector3(90, 0, 0), 10)


func _build_cultist() -> void:
	var robe := MeshKit.mat(Color(0.30, 0.12, 0.40))
	var robe_dark := MeshKit.mat(Color(0.16, 0.06, 0.22))
	var skin := MeshKit.mat(Color(0.75, 0.68, 0.72))
	blood_color = Color(0.45, 0.05, 0.25)
	_robe(robe)
	_torso_arms(skin, robe, robe)
	MeshKit.box(visual, Vector3(0.12, 0.66, 0.02), Vector3(0, 1.23, -0.15), MeshKit.mat(Color(0.8, 0.65, 0.2), 0.4, 0.6))
	MeshKit.sphere(head_node, 0.21, Vector3(0, 0.02, 0.02), robe_dark)
	MeshKit.cyl(head_node, 0.0, 0.14, 0.22, Vector3(0, 0.25, 0.06), robe_dark, Vector3(-20, 0, 0), 8)
	MeshKit.box(head_node, Vector3(0.22, 0.2, 0.06), Vector3(0, -0.02, -0.17), MeshKit.mat(Color(0.02, 0.02, 0.03)))
	_eyes(head_node, Color(0.85, 0.4, 1.0), 0.0, -0.205, 0.05, 0.022)
	_hand_glow(Color(0.65, 0.25, 1.0))


func _build_spider() -> void:
	var chitin := MeshKit.mat(Color(0.16, 0.12, 0.1), 0.6)
	var hairy := MeshKit.mat(Color(0.28, 0.2, 0.14))
	var mark := MeshKit.mat(Color(0.7, 0.1, 0.08))
	blood_color = Color(0.4, 0.6, 0.15)
	MeshKit.sphere(visual, 0.55, Vector3(0, 0.75, 0.5), hairy, Vector3(1.0, 0.8, 1.2))
	MeshKit.sphere(visual, 0.16, Vector3(0, 1.15, 0.55), mark)
	MeshKit.sphere(visual, 0.35, Vector3(0, 0.6, -0.15), chitin)
	head_node = _pivot(Vector3(0, 0.6, -0.52))
	MeshKit.sphere(head_node, 0.22, Vector3.ZERO, chitin)
	for i in 3:
		_eyes(head_node, Color(1.0, 0.15, 0.1), 0.08 - i * 0.05, -0.19, 0.05 + i * 0.03, 0.03)
	MeshKit.cyl(head_node, 0.0, 0.04, 0.22, Vector3(-0.07, -0.16, -0.12), MeshKit.mat(Color(0.1, 0.1, 0.1)), Vector3(20, 0, 0), 5)
	MeshKit.cyl(head_node, 0.0, 0.04, 0.22, Vector3(0.07, -0.16, -0.12), MeshKit.mat(Color(0.1, 0.1, 0.1)), Vector3(20, 0, 0), 5)
	head_radius = 0.3
	for side in [-1.0, 1.0]:
		for i in 4:
			var z := -0.35 + i * 0.22
			var leg := _pivot(Vector3(side * 0.25, 0.65, z))
			leg.rotation.y = side * (0.4 - i * 0.27)
			var upper := _pivot(Vector3.ZERO, leg)
			upper.rotation.z = side * -0.9
			MeshKit.box(upper, Vector3(0.6, 0.07, 0.07), Vector3(side * 0.3, 0, 0), hairy)
			var lower := _pivot(Vector3(side * 0.6, 0, 0), upper)
			lower.rotation.z = side * 1.9
			MeshKit.box(lower, Vector3(0.75, 0.06, 0.06), Vector3(side * 0.37, 0, 0), chitin)
			legs.append(leg)


func _build_skeleton(lord: bool) -> void:
	var bone := MeshKit.mat(Color(0.88, 0.85, 0.74))
	var rust := MeshKit.mat(Color(0.45, 0.3, 0.2), 0.6, 0.4)
	var dark := MeshKit.mat(Color(0.08, 0.08, 0.1))
	blood_color = Color(0.85, 0.82, 0.72)
	_legs(bone, bone, 0.08)
	MeshKit.box(visual, Vector3(0.36, 0.14, 0.18), Vector3(0, 0.95, 0), bone)
	MeshKit.cyl(visual, 0.05, 0.05, 0.5, Vector3(0, 1.2, 0.04), bone, Vector3.ZERO, 6)
	for i in 4:
		MeshKit.box(visual, Vector3(0.42 - i * 0.04, 0.04, 0.24), Vector3(0, 1.28 + i * 0.09, 0), bone)
	l_arm = _pivot(Vector3(-0.27, 1.55, 0))
	MeshKit.box(l_arm, Vector3(0.07, 0.6, 0.07), Vector3(0, -0.3, 0), bone)
	r_arm = _pivot(Vector3(0.27, 1.55, 0))
	MeshKit.box(r_arm, Vector3(0.07, 0.6, 0.07), Vector3(0, -0.3, 0), bone)
	head_node = _pivot(Vector3(0, 1.78, 0))
	MeshKit.sphere(head_node, 0.16, Vector3.ZERO, bone, Vector3(0.95, 1.0, 1.05))
	MeshKit.box(head_node, Vector3(0.18, 0.08, 0.15), Vector3(0, -0.13, -0.05), bone)
	MeshKit.sphere(head_node, 0.045, Vector3(-0.06, 0.0, -0.13), dark)
	MeshKit.sphere(head_node, 0.045, Vector3(0.06, 0.0, -0.13), dark)
	var eye_col := Color(0.3, 1.0, 0.45) if lord else Color(0.4, 0.75, 1.0)
	_eyes(head_node, eye_col, 0.0, -0.15, 0.06, 0.018)
	head_radius = 0.18
	if lord:
		var plate := MeshKit.mat(Color(0.2, 0.22, 0.25), 0.4, 0.7)
		MeshKit.box(visual, Vector3(0.55, 0.5, 0.32), Vector3(0, 1.32, 0), plate)
		MeshKit.box(l_arm, Vector3(0.3, 0.16, 0.3), Vector3(0, 0.02, 0), plate)
		MeshKit.box(r_arm, Vector3(0.3, 0.16, 0.3), Vector3(0, 0.02, 0), plate)
		for i in 5:
			MeshKit.cyl(head_node, 0.0, 0.03, 0.18, Vector3(-0.12 + i * 0.06, 0.18, 0.0), MeshKit.mat(Color(0.3, 0.9, 0.4), 0.5, 0.0, 1.5), Vector3.ZERO, 4)
		MeshKit.box(r_arm, Vector3(0.08, 0.12, 1.5), Vector3(0, -0.6, -0.75), MeshKit.mat(Color(0.25, 0.3, 0.28), 0.3, 0.8))
		MeshKit.box(visual, Vector3(0.6, 1.3, 0.04), Vector3(0, 0.95, 0.2), MeshKit.mat(Color(0.12, 0.2, 0.14)), Vector3(8, 0, 0))
		var l := OmniLight3D.new()
		l.light_color = Color(0.3, 1.0, 0.4)
		l.omni_range = 5.0
		l.light_energy = 1.5
		head_node.add_child(l)
	else:
		MeshKit.box(r_arm, Vector3(0.04, 0.06, 0.65), Vector3(0, -0.6, -0.3), rust)
		MeshKit.cyl(l_arm, 0.28, 0.28, 0.05, Vector3(-0.05, -0.45, 0), MeshKit.mat(Color(0.35, 0.25, 0.15)), Vector3(0, 0, 90), 12)


func _build_ghoul() -> void:
	var skin := MeshKit.mat(Color(0.5, 0.56, 0.45))
	var rags := MeshKit.mat(Color(0.28, 0.25, 0.22))
	var claw := MeshKit.mat(Color(0.15, 0.12, 0.1))
	blood_color = Color(0.25, 0.35, 0.15)
	_legs(rags, skin)
	_torso_arms(skin, skin, skin, 0.12)
	MeshKit.box(visual, Vector3(0.54, 0.35, 0.3), Vector3(0, 1.0, 0), rags)
	head_node.position = Vector3(0, 1.62, -0.14)
	MeshKit.sphere(head_node, 0.17, Vector3.ZERO, skin)
	MeshKit.box(head_node, Vector3(0.18, 0.1, 0.12), Vector3(0, -0.11, -0.1), MeshKit.mat(Color(0.2, 0.1, 0.1)))
	_eyes(head_node, Color(1.0, 0.9, 0.3), 0.03, -0.15, 0.06, 0.025)
	for arm in [l_arm, r_arm]:
		for k in 3:
			MeshKit.box(arm, Vector3(0.025, 0.025, 0.16), Vector3(-0.04 + k * 0.04, -0.68, -0.08), claw, Vector3(-30, 0, 0))


func _build_necromancer() -> void:
	var robe := MeshKit.mat(Color(0.1, 0.1, 0.12))
	var trim := MeshKit.mat(Color(0.25, 0.7, 0.3), 0.5, 0.0, 0.8)
	var bone := MeshKit.mat(Color(0.88, 0.85, 0.74))
	blood_color = Color(0.4, 0.05, 0.05)
	_robe(robe)
	_torso_arms(bone, robe, robe)
	MeshKit.box(visual, Vector3(0.1, 0.66, 0.02), Vector3(0, 1.23, -0.15), trim)
	MeshKit.sphere(head_node, 0.22, Vector3(0, 0.02, 0.03), robe)
	MeshKit.sphere(head_node, 0.15, Vector3(0, -0.01, -0.06), bone)
	_eyes(head_node, Color(0.4, 1.0, 0.4), 0.01, -0.2, 0.05, 0.025)
	MeshKit.cyl(r_arm, 0.025, 0.025, 1.5, Vector3(0, -0.6, -0.05), MeshKit.mat(Color(0.2, 0.15, 0.1)), Vector3.ZERO, 6)
	MeshKit.sphere(r_arm, 0.1, Vector3(0, 0.15, -0.05), bone)
	_hand_glow(Color(0.35, 1.0, 0.4))


func _build_gnoll(kind: int) -> void:
	# 0 raider, 1 brute, 2 shaman, 3 warlord
	var fur := MeshKit.mat(Color(0.72, 0.56, 0.34))
	var spots := MeshKit.mat(Color(0.35, 0.25, 0.15))
	var mane := MeshKit.mat(Color(0.25, 0.17, 0.1))
	var leather := MeshKit.mat(Color(0.4, 0.26, 0.14))
	var iron := MeshKit.mat(Color(0.45, 0.45, 0.48), 0.4, 0.7)
	_legs(fur, mane, 0.2)
	_torso_arms(fur, fur, fur, 0.16)
	MeshKit.box(visual, Vector3(0.54, 0.4, 0.32), Vector3(0, 1.05, 0), leather)
	for i in 6:
		MeshKit.sphere(visual, 0.05, Vector3(randf_range(-0.2, 0.2), randf_range(1.3, 1.5), -0.15), spots)
	head_node.position = Vector3(0, 1.74, -0.06)
	MeshKit.sphere(head_node, 0.18, Vector3.ZERO, fur)
	MeshKit.box(head_node, Vector3(0.14, 0.14, 0.28), Vector3(0, -0.04, -0.2), fur)
	MeshKit.box(head_node, Vector3(0.07, 0.06, 0.06), Vector3(0, 0.0, -0.35), MeshKit.mat(Color(0.05, 0.05, 0.05)))
	MeshKit.prism(head_node, Vector3(0.1, 0.18, 0.06), Vector3(-0.12, 0.2, 0.02), mane)
	MeshKit.prism(head_node, Vector3(0.1, 0.18, 0.06), Vector3(0.12, 0.2, 0.02), mane)
	MeshKit.box(head_node, Vector3(0.08, 0.3, 0.3), Vector3(0, 0.05, 0.15), mane)
	_eyes(head_node, Color(1.0, 0.6, 0.1), 0.05, -0.14, 0.07, 0.025)
	match kind:
		0:
			MeshKit.box(r_arm, Vector3(0.04, 0.04, 0.6), Vector3(0, -0.62, -0.3), MeshKit.mat(Color(0.4, 0.26, 0.12)))
			MeshKit.box(r_arm, Vector3(0.04, 0.25, 0.18), Vector3(0, -0.55, -0.55), iron)
		1:
			MeshKit.cyl(r_arm, 0.07, 0.12, 0.9, Vector3(0, -0.62, -0.45), MeshKit.mat(Color(0.4, 0.26, 0.12)), Vector3(90, 0, 0), 8)
			for side in [-1.0, 1.0]:
				MeshKit.cyl(visual, 0.0, 0.06, 0.25, Vector3(side * 0.3, 1.62, 0.05), MeshKit.mat(Color(0.9, 0.85, 0.75)), Vector3(0, 0, -side * 40), 5)
		2:
			var feathers := [MeshKit.mat(Color(0.8, 0.2, 0.1)), MeshKit.mat(Color(0.2, 0.5, 0.8)), MeshKit.mat(Color(0.95, 0.85, 0.3))]
			for i in 5:
				MeshKit.box(head_node, Vector3(0.04, 0.3, 0.02), Vector3(-0.12 + i * 0.06, 0.28, 0.08), feathers[i % 3], Vector3(0, 0, -20 + i * 10))
			MeshKit.cyl(r_arm, 0.03, 0.03, 1.6, Vector3(0, -0.6, -0.05), MeshKit.mat(Color(0.35, 0.22, 0.1)), Vector3.ZERO, 6)
			MeshKit.sphere(r_arm, 0.09, Vector3(0, 0.22, -0.05), MeshKit.unshaded(Color(0.75, 1.0, 0.3)))
			_hand_glow(Color(0.75, 1.0, 0.25))
		3:
			var red := MeshKit.mat(Color(0.65, 0.1, 0.08))
			MeshKit.box(visual, Vector3(0.58, 0.55, 0.34), Vector3(0, 1.3, 0), iron)
			MeshKit.box(l_arm, Vector3(0.32, 0.16, 0.32), Vector3(0, 0.02, 0), iron)
			MeshKit.box(r_arm, Vector3(0.32, 0.16, 0.32), Vector3(0, 0.02, 0), iron)
			MeshKit.box(visual, Vector3(0.6, 1.3, 0.04), Vector3(0, 0.95, 0.2), red, Vector3(8, 0, 0))
			MeshKit.box(head_node, Vector3(0.05, 0.12, 0.2), Vector3(-0.08, 0.05, -0.18), red)
			MeshKit.box(r_arm, Vector3(0.05, 0.05, 1.3), Vector3(0, -0.62, -0.6), MeshKit.mat(Color(0.35, 0.22, 0.1)))
			MeshKit.box(r_arm, Vector3(0.05, 0.55, 0.4), Vector3(0, -0.5, -1.15), iron)


func _build_golem() -> void:
	var rust := MeshKit.mat(Color(0.5, 0.32, 0.18), 0.6, 0.5)
	var metal := MeshKit.mat(Color(0.35, 0.33, 0.3), 0.5, 0.6)
	var sack := MeshKit.mat(Color(0.75, 0.65, 0.42))
	blood_color = Color(0.25, 0.2, 0.15)
	l_leg = _pivot(Vector3(-0.2, 0.9, 0))
	MeshKit.cyl(l_leg, 0.1, 0.12, 0.85, Vector3(0, -0.42, 0), metal, Vector3.ZERO, 8)
	MeshKit.box(l_leg, Vector3(0.3, 0.12, 0.4), Vector3(0, -0.85, -0.05), rust)
	r_leg = _pivot(Vector3(0.2, 0.9, 0))
	MeshKit.cyl(r_leg, 0.1, 0.12, 0.85, Vector3(0, -0.42, 0), metal, Vector3.ZERO, 8)
	MeshKit.box(r_leg, Vector3(0.3, 0.12, 0.4), Vector3(0, -0.85, -0.05), rust)
	MeshKit.cyl(visual, 0.38, 0.34, 0.85, Vector3(0, 1.3, 0), rust, Vector3.ZERO, 12)
	MeshKit.cyl(visual, 0.4, 0.4, 0.06, Vector3(0, 1.55, 0), metal)
	MeshKit.cyl(visual, 0.4, 0.4, 0.06, Vector3(0, 1.05, 0), metal)
	MeshKit.cyl(visual, 0.06, 0.08, 0.5, Vector3(0.15, 1.95, 0.15), metal, Vector3.ZERO, 6)
	l_arm = _pivot(Vector3(-0.48, 1.55, 0))
	MeshKit.box(l_arm, Vector3(0.18, 0.7, 0.18), Vector3(0, -0.35, 0), metal)
	MeshKit.box(l_arm, Vector3(0.24, 0.2, 0.24), Vector3(0, -0.72, 0), rust)
	r_arm = _pivot(Vector3(0.48, 1.55, 0))
	MeshKit.box(r_arm, Vector3(0.18, 0.7, 0.18), Vector3(0, -0.35, 0), metal)
	MeshKit.box(r_arm, Vector3(0.04, 0.06, 0.6), Vector3(0, -0.72, -0.3), MeshKit.mat(Color(0.35, 0.22, 0.1)))
	MeshKit.box(r_arm, Vector3(0.03, 0.12, 0.7), Vector3(0, -0.66, -0.72), MeshKit.mat(Color(0.75, 0.75, 0.78), 0.3, 0.8), Vector3(25, 0, 0))
	head_node = _pivot(Vector3(0, 1.88, 0))
	MeshKit.box(head_node, Vector3(0.38, 0.32, 0.34), Vector3.ZERO, sack)
	MeshKit.box(head_node, Vector3(0.28, 0.05, 0.02), Vector3(0, 0.03, -0.18), MeshKit.unshaded(Color(1.0, 0.6, 0.1)))
	head_radius = 0.24


func _build_overhead(y: float) -> void:
	name_label = Label3D.new()
	name_label.text = "%s %d  %s" % [Loc.t("Lv"), level, display_name]
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 40
	name_label.fixed_size = true
	name_label.pixel_size = 0.0011 if boss else 0.0009
	name_label.outline_size = 10
	name_label.modulate = level_color()
	if elite:
		name_label.outline_modulate = Color(0.5, 0.35, 0.0)
		name_label.pixel_size *= 1.15
	name_label.position.y = y + 0.18
	name_label.visibility_range_end = 45.0 if boss else 32.0
	add_child(name_label)

	if _bar_tex == null:
		var img := Image.create_empty(64, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_bar_tex = ImageTexture.create_from_image(img)
	bar_bg = Sprite3D.new()
	bar_bg.texture = _bar_tex
	bar_bg.pixel_size = 0.012 * (1.6 if boss else 1.0)
	bar_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bar_bg.modulate = Color(0, 0, 0, 0.75)
	bar_bg.position.y = y
	bar_bg.visible = false
	add_child(bar_bg)
	bar_fg = Sprite3D.new()
	bar_fg.texture = _bar_tex
	bar_fg.pixel_size = bar_bg.pixel_size
	bar_fg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bar_fg.modulate = Color(0.9, 0.12, 0.1)
	bar_fg.region_enabled = true
	bar_fg.region_rect = Rect2(0, 0, 64, 8)
	bar_fg.render_priority = 1
	bar_fg.position.y = y
	bar_fg.visible = false
	add_child(bar_fg)


func _build_ice_block() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.6, 0.85, 1.0, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic_specular = 1.0
	m.emission_enabled = true
	m.emission = Color(0.3, 0.6, 1.0)
	m.emission_energy_multiplier = 0.4
	m.rim_enabled = true
	m.rim = 1.0
	var bm := BoxMesh.new()
	var w := (1.3 if type == "wolf" or type == "spider" else 0.9) * (_scale if type != "wolf" and type != "spider" else 1.0)
	bm.size = Vector3(w, _height + 0.2, w if type != "wolf" and type != "spider" else 1.6)
	ice_block = MeshInstance3D.new()
	ice_block.mesh = bm
	ice_block.material_override = m
	ice_block.position.y = (_height + 0.2) * 0.5
	ice_block.visible = false
	add_child(ice_block)


func _update_bar() -> void:
	var w := maxf(1.0, 64.0 * clampf(hp / max_hp, 0.0, 1.0))
	bar_fg.region_rect = Rect2(0, 0, w, 8)
	bar_fg.offset = Vector2(-32.0 + w * 0.5, 0)
	bar_bg.visible = true
	bar_fg.visible = true


# --------------------------------------------------------------------------- frost

## Freeze for `freeze` seconds, then frost damage `dps` per second for `duration` seconds.
func apply_frost(freeze: float, dps: float, duration: float) -> void:
	if state == State.DEAD:
		return
	var f := freeze * (0.4 if boss else 1.0)
	frozen_t = maxf(frozen_t, f)
	chill_t = maxf(chill_t, f + 3.0)
	_dot_dps = maxf(_dot_dps, dps)
	_dot_t = maxf(_dot_t, duration)
	_dot_tick = minf(_dot_tick, 1.0)
	ice_block.visible = true
	ice_block.scale = Vector3.ONE * 0.6
	create_tween().tween_property(ice_block, "scale", Vector3.ONE, 0.15)
	_end_attack()
	_charge_t = 0.0
	name_label.modulate = Color(0.5, 0.8, 1.0)
	if state == State.IDLE:
		aggro()


func _unfreeze() -> void:
	ice_block.visible = false
	Game.play_sound("ice_shatter", global_position, -4.0)
	Fx.burst(world, global_position + Vector3(0, _height * 0.5, 0), Color(0.7, 0.9, 1.0), 16, 4.0, 0.06, 0.6)


func _process_frost(delta: float) -> void:
	if _dot_t > 0.0:
		_dot_t -= delta
		_dot_tick -= delta
		if _dot_tick <= 0.0:
			_dot_tick = 1.0
			take_damage(_dot_dps, global_position + Vector3(0, _height, 0), Vector3.ZERO, "frost")
	if chill_t > 0.0:
		chill_t -= delta
		if chill_t <= 0.0 and state != State.DEAD:
			name_label.modulate = level_color()
	if elite:
		name_label.outline_modulate = Color(0.5, 0.35, 0.0)
		name_label.pixel_size *= 1.15


# --------------------------------------------------------------------------- status effects

## Safety net: an enemy pushed under the terrain (or outside the map) is put back on top.
func _keep_above_ground() -> void:
	var p := global_position
	var lim: float = world.half - 6.0
	var moved := false
	if absf(p.x) > lim or absf(p.z) > lim:
		p.x = clampf(p.x, -lim, lim)
		p.z = clampf(p.z, -lim, lim)
		moved = true
	var g: float = world.ground(p.x, p.z)
	if p.y < g - 0.6:
		# pushed under the terrain (usually out of a building): rescue to the nearest open spot
		var spot: Vector3 = world.free_spot(p, 0.45 * maxf(_scale, 1.0), maxf(_height, 1.0))
		p = spot + Vector3(0, 0.4, 0)
		velocity = Vector3.ZERO
		home = spot
		_wander_target = spot
		moved = true
	if moved:
		global_position = p


func stun(t: float) -> void:
	if state != State.DEAD and not boss:
		stun_t = maxf(stun_t, t)
		_end_attack()


func apply_burn(dps: float, duration: float) -> void:
	if state == State.DEAD:
		return
	_burn_dps = maxf(_burn_dps, dps)
	_burn_t = maxf(_burn_t, duration)
	_burn_fx.emitting = true


func _process_burn(delta: float) -> void:
	if _burn_t <= 0.0:
		return
	_burn_t -= delta
	_burn_tick -= delta
	if _burn_tick <= 0.0:
		_burn_tick = 1.0
		take_damage(_burn_dps, global_position + Vector3(0, _height, 0), Vector3.ZERO, "fire")
	if _burn_t <= 0.0 and _burn_fx:
		_burn_fx.emitting = false


# --------------------------------------------------------------------------- abilities

func _use_abilities(delta: float) -> void:
	var player: Player = world.player
	var dist := global_position.distance_to(player.global_position)
	for a in abilities:
		_ability_cd[a] -= delta
		if _ability_cd[a] > 0.0:
			continue
		match a:
			"enrage":
				if not enraged and hp < max_hp * 0.35:
					_enrage()
				_ability_cd[a] = 1.0
			"heal":
				var target := _wounded_ally(16.0)
				if target:
					_cast_support(target, "heal")
					_ability_cd[a] = 9.0
					return
				_ability_cd[a] = 1.0
			"shield":
				var target := _unshielded_ally(16.0)
				if target:
					_cast_support(target, "shield")
					_ability_cd[a] = 12.0
					return
				_ability_cd[a] = 1.0
			"summon":
				if _summons_left > 0 and dist < 30.0:
					_summon()
					_ability_cd[a] = 20.0
					return
				_ability_cd[a] = 2.0
			"web":
				if _has_los and dist > 4.0 and dist < 18.0:
					_shoot_web(player)
					_ability_cd[a] = randf_range(6.0, 9.0)
					return
				_ability_cd[a] = 1.0
			"slam":
				if dist < 4.5:
					_begin_slam()
					_ability_cd[a] = randf_range(7.0, 10.0)
					return
				_ability_cd[a] = 0.5
			"meteor":
				if _has_los and dist < 35.0:
					_boss_meteors(player)
					_ability_cd[a] = randf_range(10.0, 14.0)
					return
				_ability_cd[a] = 1.0


func _wounded_ally(r: float) -> Enemy:
	var best: Enemy = null
	var worst := 0.7
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e.global_position.distance_to(global_position) < r and e.hp / e.max_hp < worst:
			worst = e.hp / e.max_hp
			best = e
	return best


func _unshielded_ally(r: float) -> Enemy:
	var best: Enemy = null
	var bd := r
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e.shield_hp <= 0.0 and e.state == State.CHASE:
			var d := e.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = e
	return best


func _cast_support(target: Enemy, what: String) -> void:
	_play_attack_anim(1.0)
	var col := Color(0.4, 1.0, 0.45) if what == "heal" else Color(0.7, 0.45, 1.0)
	var a := global_position + Vector3(0, _height * 0.75, 0)
	var b := target.global_position + Vector3(0, target._height * 0.6, 0)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.07
	cm.bottom_radius = 0.07
	cm.height = maxf(0.1, a.distance_to(b))
	cm.radial_segments = 6
	beam.mesh = cm
	beam.material_override = MeshKit.glow(Color(col, 0.6))
	world.add_child(beam)
	beam.global_position = (a + b) * 0.5
	if a.distance_to(b) > 0.2:
		beam.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.FORWARD)
		beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var tw := beam.create_tween()
	tw.tween_interval(0.35)
	tw.tween_callback(beam.queue_free)
	Fx.burst(world, b, col, 20, 2.5, 0.05, 0.8, -2.0)
	if what == "heal":
		var amount := target.max_hp * 0.3
		target.hp = minf(target.max_hp, target.hp + amount)
		target._update_bar()
		world.damage_number(b, amount, "heal")
		Game.play_sound("heal", b, -4.0)
	else:
		target.shield_hp = 60.0 + target.max_hp * 0.2
		target._shield_fx.visible = true
		Game.play_sound("cast", b, -6.0, 1.4)


func _summon() -> void:
	_summons_left -= 1
	_play_attack_anim(1.0)
	Game.play_sound("cast", global_position, 0.0, 0.5)
	world.hud.show_message("%s raises the dead!" % display_name, Color(0.5, 1.0, 0.5), 1.5)
	for i in 2:
		var a := randf() * TAU
		var p := global_position + Vector3(cos(a) * 2.5, 0, sin(a) * 2.5)
		Fx.burst(world, Vector3(p.x, world.ground(p.x, p.z) + 0.3, p.z), Color(0.35, 1.0, 0.4), 25, 3.0, 0.06, 0.8, -3.0)
		world.spawn_extra(SUMMONS.get(type, "skeleton"), p)


func _shoot_web(player: Player) -> void:
	_play_attack_anim(0.7)
	Game.play_sound("swing", global_position, -4.0, 0.6)
	var from := global_position + Vector3(0, _height * 0.6, 0) + (-global_transform.basis.z) * 0.7
	var sp := Spell.new()
	sp.kind = "web"
	sp.damage = 5.0
	sp.direction = (player.global_position + Vector3(0, 1.0, 0) - from).normalized()
	world.add_child(sp)
	sp.global_position = from


func _begin_slam() -> void:
	_slam_t = 0.0
	_play_attack_anim(0.9)
	var r := 4.5 * (_scale if boss else 1.0)
	_slam_ring = Node3D.new()
	world.add_child(_slam_ring)
	_slam_ring.global_position = Vector3(global_position.x, world.ground(global_position.x, global_position.z) + 0.12, global_position.z)
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.04
	disc.radial_segments = 36
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.2, 0.1, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	MeshKit.inst(_slam_ring, disc, Vector3.ZERO, m)
	_slam_ring.set_meta("radius", r)
	_slam_ring.scale = Vector3(0.1, 1, 0.1)
	_slam_ring.create_tween().tween_property(_slam_ring, "scale", Vector3.ONE, 0.8)


func _process_slam(delta: float) -> void:
	_slam_t += delta
	if _slam_t >= 0.85:
		_slam_t = -1.0
		var r: float = _slam_ring.get_meta("radius")
		var center := _slam_ring.global_position
		_slam_ring.queue_free()
		Game.play_sound("slam", center, 4.0, 0.7)
		Fx.burst(world, center + Vector3(0, 0.3, 0), Color(0.45, 0.38, 0.3), 40, r * 1.5, 0.12, 1.0, 9.0)
		var player: Player = world.player
		var d := player.global_position.distance_to(center)
		player.shake(clampf(1.0 - d / (r * 3.0), 0.0, 1.0) * 0.7)
		if d <= r and absf(player.global_position.y - center.y) < 2.5:
			player.take_damage(damage * 1.3 * gap_mult(), center)
			player.slow_t = 1.5


func _boss_meteors(player: Player) -> void:
	_play_attack_anim(1.0)
	Game.play_sound("cast", global_position, 2.0, 0.45)
	world.hud.show_message("%s calls down fire!  Move!" % display_name, Color(1.0, 0.4, 0.2), 1.5)
	var count := 4 if enraged else 3
	for i in count:
		var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-7, 7), 0, randf_range(-7, 7))
		var p := player.global_position + Vector3(player.velocity.x, 0, player.velocity.z) * 0.6 + off
		Meteor.strike(world, p, 3.5, 32.0 * gap_mult(), "enemy", 1.5 + i * 0.25)


func _enrage() -> void:
	enraged = true
	speed *= 1.35
	damage *= 1.3
	cooldown *= 0.7
	world.hud.show_message("%s becomes ENRAGED!" % display_name, Color(1.0, 0.2, 0.15), 2.0)
	Game.play_sound("aggro", global_position, 6.0, 0.4)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.2, 0.1)
	l.light_energy = 2.5
	l.omni_range = 6.0
	l.position.y = _height * 0.6
	add_child(l)
	create_tween().tween_property(visual, "scale", visual.scale * 1.12, 0.4)


func _play_attack_anim(duration: float) -> void:
	if anim and not _attack_anims.is_empty():
		_anim_map["attack"] = _attack_anims[randi() % _attack_anims.size()]
	if anim and _anim_map.has("attack"):
		var n: String = _anim_map["attack"]
		anim.play(n, 0.1, anim.get_animation(n).length / duration)
		_anim_current = n


# --------------------------------------------------------------------------- AI

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	# idle enemies far from the player pause (cheap distance check, a few times a second)
	if state == State.IDLE and world.player:
		_far_t -= delta
		if _far_t <= 0.0:
			_far_t = 0.5
			_far = global_position.distance_squared_to(world.player.global_position) > 8100.0
			if anim:
				anim.speed_scale = 0.0 if _far else 1.0
		if _far:
			return
	# idle groans / growls so creatures can be heard before they're seen
	_voice_t -= delta
	if _voice_t <= 0.0:
		_voice_t = randf_range(5.0, 11.0) if state == State.IDLE else randf_range(2.5, 5.0)
		var v := voice()
		if v != "human" and world.player and world.player.global_position.distance_to(global_position) < 45.0:
			Game.play_sound(v, global_position, -8.0 if state == State.IDLE else -3.0, _voice_pitch())
	if not is_on_floor():
		velocity.y -= gravity * delta
	_keep_above_ground()
	_process_frost(delta)
	_process_burn(delta)
	if state == State.DEAD:
		return
	_hit_t = maxf(0.0, _hit_t - delta)
	if frozen_t > 0.0 or stun_t > 0.0:
		var was_frozen := frozen_t > 0.0
		frozen_t = maxf(0.0, frozen_t - delta)
		stun_t = maxf(0.0, stun_t - delta)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if anim:
			anim.speed_scale = 0.0
		if was_frozen and frozen_t <= 0.0:
			_unfreeze()
		return
	if anim:
		anim.speed_scale = 1.0
	if _slam_t >= 0.0:
		_process_slam(delta)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_animate(delta)
		return
	if state == State.CHASE and _attack_t < 0.0 and _charge_t <= 0.0 and foe == null and not neutral:
		_use_abilities(delta)

	_pick_t -= delta
	if _pick_t <= 0.0:
		_pick_t = 0.5
		_pick_target()
	var player: Node3D = _tgt()
	_attack_cd -= delta
	_charge_cd -= delta
	_hurt_t = maxf(0.0, _hurt_t - delta)
	var to_p := player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()

	_los_t -= delta
	if _los_t <= 0.0:
		_los_t = 0.2 + randf() * 0.1
		_has_los = dist < maxf(aggro_range, attack_range) + 10.0 and _can_see(player)
	_unseen_t = 0.0 if _has_los or state != State.CHASE else _unseen_t + delta

	var desired := Vector3.ZERO
	if state == State.IDLE:
		desired = _idle(delta, player, dist)
	elif state == State.CHASE:
		var from_home := Vector2(global_position.x - home.x, global_position.z - home.z).length()
		if not _alive(player) or world.finished:
			state = State.IDLE
			_attack_t = -1.0
			_wander_target = home
			foe = null
		elif neutral and world.wanted_stars == 0 and foe == null:
			_evade()
		elif from_home > LEASH * (1.4 if boss else (5.0 if neutral else 1.0)) and _charge_t <= 0.0:
			_evade()
		elif neutral and foe == null and (_unseen_t > LOSE_TIME or dist > LOSE_DIST):
			# guards lose a wanted player who broke line of sight or got far away
			_evade()
		else:
			desired = _chase(delta, player, to_p, dist)
	elif state == State.RETURN:
		desired = _return_home(delta)

	if chill_t > 0.0:
		desired *= 0.5
	if desired.length_squared() > 0.01 and _charge_t <= 0.0:
		desired += _separation() * speed * 0.6
		if _avoid_t > 0.0:
			desired = desired.rotated(Vector3.UP, _avoid_angle)
	_avoid_t -= delta

	var accel := 60.0 if _charge_t > 0.0 else 25.0
	velocity.x = move_toward(velocity.x, desired.x, accel * delta)
	velocity.z = move_toward(velocity.z, desired.z, accel * delta)
	move_and_slide()

	if desired.length_squared() > 0.5 and is_on_wall() and _avoid_t <= 0.0:
		if _charge_t > 0.0:
			_charge_t = 0.0
		_avoid_t = randf_range(0.6, 1.2)
		_avoid_angle = (1.0 if randf() < 0.5 else -1.0) * randf_range(0.9, 1.6)

	_animate(delta)


## Gave up the chase: run home, heal to full, ignore damage until back.
func _evade() -> void:
	if state == State.CHASE:
		ai_bark("flee", 0.7)
		if AI_KINDS.has(type):
			Brain.event("flee", "", {"mob": AI_KINDS[type]})
	state = State.RETURN
	_end_attack()
	_slam_t = -1.0
	if _slam_ring and is_instance_valid(_slam_ring):
		_slam_ring.queue_free()
	for g in cast_glow:
		g.visible = false


func _return_home(delta: float) -> Vector3:
	var to := home - global_position
	to.y = 0.0
	hp = minf(max_hp, hp + max_hp * 0.3 * delta)
	_update_bar()
	if to.length() < 2.0:
		state = State.IDLE
		hp = max_hp
		bar_bg.visible = false
		bar_fg.visible = false
		_wander_target = home
		_wander_wait = randf_range(1.0, 3.0)
		return Vector3.ZERO
	var d := to.normalized()
	_face(d, delta, 8.0)
	return d * speed * 1.4


func _idle(delta: float, player: Node3D, dist: float) -> Vector3:
	if _alive(player) and not world.finished and dist < aggro_range and _has_los and (not neutral or world.wanted_stars > 0 or foe != null):
		aggro()
		return Vector3.ZERO
	if _wander_wait > 0.0:
		_wander_wait -= delta
		return Vector3.ZERO
	_wander_timer -= delta
	var to_t := _wander_target - global_position
	to_t.y = 0.0
	if to_t.length() < 0.8 or _wander_timer <= 0.0:
		_wander_wait = randf_range(2.0, 5.0)
		_wander_timer = 8.0
		var a := randf() * TAU
		var r := randf_range(1.5, 7.0 if type == "golem" else 6.0)
		_wander_target = home + Vector3(cos(a) * r, 0, sin(a) * r)
		return Vector3.ZERO
	var d := to_t.normalized()
	_face(d, delta, 4.0)
	return d * speed * 0.35


func _chase(delta: float, player: Node3D, to_p: Vector3, dist: float) -> Vector3:
	var dir := to_p / maxf(dist, 0.001)
	if _charge_t > 0.0:
		_charge_t -= delta
		_face(_charge_dir, delta, 12.0)
		if dist <= attack_range + 0.4:
			_charge_t = 0.0
			_attack_cd = 0.0
			_begin_attack()
			return Vector3.ZERO
		return _charge_dir * speed * 2.8
	_face(dir, delta, 8.0)
	if _attack_t >= 0.0:
		_update_attack(delta, player, dist)
		return Vector3.ZERO
	_tactic_tick(delta, player, dist)
	_ai_taunt_t -= delta
	if _ai_taunt_t <= 0.0:
		_ai_taunt_t = randf_range(9.0, 18.0)
		if dist < 25.0 and _has_los:
			ai_bark("taunt", 0.6)
	var tv := _tactic_move(delta, player, dist)
	if tv != Vector3.INF:
		return tv
	if ranged:
		if _has_los and dist <= attack_range and _attack_cd <= 0.0:
			_begin_attack()
			return Vector3.ZERO
		if not _has_los or dist > attack_range * 0.85:
			return dir * speed
		if dist < 7.0:
			return -dir * speed * 0.7
		_strafe_t -= delta
		if _strafe_t <= 0.0:
			_strafe_t = randf_range(1.0, 2.5)
			_strafe_sign = -_strafe_sign
		return dir.cross(Vector3.UP) * _strafe_sign * speed * 0.45
	if can_charge and _charge_cd <= 0.0 and _has_los and dist > 6.0 and dist < 18.0:
		_charge_t = 1.1
		_charge_cd = randf_range(6.0, 9.0)
		_charge_dir = dir
		Game.play_sound("aggro", global_position, 2.0, 0.55)
		world.hud.show_message("%s charges!" % display_name, Color(1.0, 0.5, 0.2), 1.2)
		return dir * speed * 2.8
	if dist <= attack_range:
		if _attack_cd <= 0.0:
			_begin_attack()
		return Vector3.ZERO
	return dir * speed


## Asks Tactics for a better place to stand every few seconds while fighting.
func _tactic_tick(delta: float, player: Node3D, dist: float) -> void:
	if neutral or boss or dist > 45.0 or not Tactics.available():
		return
	_tactic_t -= delta
	if _tactic_t > 0.0:
		return
	_tactic_t = randf_range(2.5, 4.0)
	var mode := ""
	if _coward and not _covered and hp < max_hp * 0.25:
		mode = "cover"
	elif ranged:
		mode = "fire"
	elif type in FLANKERS and dist > attack_range + 3.0 and _pack_size() >= 2:
		mode = "flank"
	if mode == "":
		if tactics:
			tactics.spot = Vector3.INF
		return
	if tactics == null:
		tactics = Tactics.new()
		tactics.enemy = self
		add_child(tactics)
	tactics.request(mode, player)


func _pack_size() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.state == State.CHASE and not e.neutral and (e as Node3D).global_position.distance_squared_to(global_position) < 625.0:
			n += 1
	return n


## Movement towards the tactical spot, or Vector3.INF to use the normal chase.
func _tactic_move(delta: float, player: Node3D, dist: float) -> Vector3:
	if tactics == null or tactics.spot == Vector3.INF:
		return Vector3.INF
	var to_s := tactics.spot - global_position
	to_s.y = 0.0
	var d := to_s.length()
	match tactics.spot_mode:
		"cover":
			if d > 1.2:
				_face(to_s / d, delta, 10.0)
				return to_s / d * speed * 1.1
			# hiding: catch some breath, then fight on
			_cover_t += delta
			hp = minf(max_hp, hp + max_hp * 0.04 * delta)
			_update_bar()
			if _cover_t > 4.0:
				_covered = true
				tactics.spot = Vector3.INF
			return Vector3.ZERO
		"fire":
			if not ranged or (_has_los and dist <= attack_range and _attack_cd <= 0.0 and d < 4.0):
				return Vector3.INF
			if d > 1.5:
				return to_s / d * speed
		"flank":
			# go round to the side, then close in; forget the spot if the target ran off
			var spot_to_t := Vector2(tactics.spot.x - player.global_position.x, tactics.spot.z - player.global_position.z).length()
			if d < 1.5 or dist <= attack_range + 2.5 or spot_to_t > attack_range + 9.0:
				tactics.spot = Vector3.INF
				return Vector3.INF
			return to_s / d * speed * 1.05
	return Vector3.INF


func _begin_attack() -> void:
	_attack_t = 0.0
	_attack_done = false
	_play_attack_anim(1.0 if ranged else 0.65)
	if ranged:
		Game.play_sound("cast", global_position, -4.0, 1.0 if spell_kind == "fire" else 0.75)
		for g in cast_glow:
			g.visible = true
	else:
		Game.play_sound("swing", global_position, -6.0, 0.7 if boss else 1.0)
		if voice() != "human" and randf() < 0.6:
			Game.play_sound("creature_attack" if voice() in ["monster", "bug"] else voice(), global_position, -2.0, _voice_pitch())


func _update_attack(delta: float, player: Node3D, dist: float) -> void:
	_attack_t += delta
	if ranged:
		if not _attack_done and _attack_t >= 0.75:
			_attack_done = true
			_cast_spell(player)
		if _attack_t >= 1.0:
			_end_attack()
	else:
		if not _attack_done and _attack_t >= 0.35:
			_attack_done = true
			if dist <= attack_range + 0.6 and _alive(player):
				_hurt(player, damage * randf_range(0.85, 1.15))
		if _attack_t >= 0.65:
			_end_attack()


func _end_attack() -> void:
	if _attack_t >= 0.0:
		_attack_cd = cooldown * randf_range(0.85, 1.2)
	_attack_t = -1.0
	for g in cast_glow:
		g.visible = false


func _cast_spell(player: Node3D) -> void:
	var fwd := -global_transform.basis.z
	var from := global_position + Vector3(0, _eye_height * 0.8, 0) + fwd * 0.7
	var target := player.global_position + Vector3(0, 1.2, 0)
	# guards with the player's technology shoot muskets / rifles instead of crossbows
	if neutral and world.tech_level >= 2:
		_gunshot(from, target, player)
		return
	var travel := from.distance_to(target) / Spell.SPEED
	if "velocity" in player:
		target += Vector3(player.velocity.x, 0, player.velocity.z) * travel * 0.5
	var sp := Spell.new()
	sp.kind = spell_kind
	sp.damage = damage
	sp.player_mult = gap_mult()
	sp.from_guard = neutral
	sp.direction = (target - from).normalized()
	world.add_child(sp)
	sp.global_position = from


## Hitscan shot with a tracer (guards from tech level 2: muskets, rifles from level 4).
func _gunshot(from: Vector3, target: Vector3, tg: Node3D) -> void:
	Game.play_sound("shot", from, -4.0, 0.75 if world.tech_level < 4 else 1.1)
	var miss := Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)) * (0.6 if world.tech_level < 4 else 0.25)
	var end := target + miss
	if randf() < (0.6 if world.tech_level < 4 else 0.8):
		_hurt(tg, damage * (1.0 if world.tech_level < 4 else 1.4))
		end = target
	var tracer := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.012
	cm.bottom_radius = 0.012
	cm.height = from.distance_to(end)
	tracer.mesh = cm
	tracer.material_override = MeshKit.glow(Color(1.0, 0.85, 0.5, 0.7))
	world.add_child(tracer)
	tracer.global_position = (from + end) * 0.5
	tracer.look_at(end, Vector3.UP if absf((end - from).normalized().y) < 0.99 else Vector3.FORWARD)
	tracer.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	Fx.light_flash(world, from, Color(1.0, 0.7, 0.4), 2.0, 5.0, 0.08)
	tracer.create_tween().tween_property(tracer, "scale", Vector3(0.1, 1, 0.1), 0.12).finished.connect(tracer.queue_free)


## The player unless something else is being fought.
func _tgt() -> Node3D:
	if foe and is_instance_valid(foe) and _alive(foe):
		return foe
	foe = null
	return world.player


func _alive(n: Node3D) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if n is Player:
		return not (n as Player).dead
	if n is Enemy:
		return (n as Enemy).state != State.DEAD
	if n.has_method("can_be_attacked"):
		return n.can_be_attacked()
	return false


## Damage to whatever is being fought. Hits from monsters never count as the player's crime.
func _hurt(n: Node3D, amount: float) -> void:
	if n is Player:
		(n as Player).take_damage(amount * gap_mult(), global_position)
	elif n is Enemy:
		(n as Enemy).npc_damage(amount, self)
	elif n.has_method("monster_damage"):
		n.monster_damage(amount, self)


## Damage from another NPC (monster hitting a guard, guard hitting a monster): no crime, no
## evading, the attacker becomes the target.
func npc_damage(amount: float, attacker: Node3D) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	_hurt_t = 0.15
	if not _ai_hurt_said and hp > 0.0 and hp < max_hp * 0.4:
		_ai_hurt_said = true
		ai_bark("hurt", 0.8)
	_update_bar()
	world.damage_number(global_position + Vector3(0, _height, 0), amount, "bullet")
	if not neutral or world.wanted_stars == 0:
		foe = attacker
	if state != State.CHASE:
		state = State.CHASE
	if hp <= 0.0:
		_die()


## Who to fight. Monsters: the player or the closest ally (guard / fighting villager), the player
## wins when about as close. Guards: the player when wanted, otherwise nearby monsters.
func _pick_target() -> void:
	var me := global_position
	if neutral:
		if world.wanted_stars > 0:
			foe = null
			return
		var best: Node3D = null
		var bd := 30.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.neutral or e.state == State.DEAD:
				continue
			var d := me.distance_to(e.global_position)
			if d < bd and (e.state == State.CHASE or d < 18.0):
				bd = d
				best = e
		foe = best
		if foe and state == State.IDLE:
			state = State.CHASE
		return
	var p: Player = world.player
	var pd := me.distance_to(p.global_position) if p and not p.dead else INF
	var best: Node3D = null
	var bd := aggro_range * (1.5 if state == State.CHASE else 1.0)
	for a in get_tree().get_nodes_in_group("allies"):
		if not _alive(a):
			continue
		var d := me.distance_to(a.global_position)
		if d < bd:
			bd = d
			best = a
	if best and bd * 1.3 < pd:
		foe = best
		if state == State.IDLE:
			aggro()
	else:
		foe = null


func _can_see(player: Node3D) -> bool:
	var from := global_position + Vector3(0, _eye_height, 0)
	var to := player.global_position + Vector3(0, 1.5, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self:
			continue
		var d: Vector3 = global_position - (e as Node3D).global_position
		d.y = 0.0
		var l := d.length()
		if l < 1.6 and l > 0.01:
			push += d / l * (1.6 - l)
	return push


func _face(dir: Vector3, delta: float, rate: float) -> void:
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(rate * delta, 0.0, 1.0))


## Becomes hostile and pulls nearby allies too.
func aggro() -> void:
	if state != State.IDLE:
		return
	state = State.CHASE
	if boss:
		ai_bark("boss_intro", 1.0)
	else:
		ai_bark("aggro", 0.55)
	var v := voice()
	if v == "human":
		Game.play_sound("enemy_yell", global_position, -4.0, 0.75 if boss else 1.0)
	else:
		Game.play_sound("scream" if v == "zombie" and randf() < 0.3 else v, global_position, 0.0, _voice_pitch())
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and (e as Node3D).global_position.distance_to(global_position) < 12.0 and e.neutral == neutral:
			e.call_deferred("aggro")


## A short voiced shout from the AI brain (Northvale mobs): spotted you, hurt, fleeing, taunts...
func ai_bark(event: String, chance := 1.0) -> void:
	if not AI_KINDS.has(type) or randf() > chance or not Brain.can_bark():
		return
	var r := await Brain.bark(AI_KINDS[type], event)
	if not is_instance_valid(self) or (state == State.DEAD and event != "kill_player"):
		return
	# the voice profile's pitch and effect, a little different for every bandit
	var pitch: float = float(r.get("pitch", 1.0)) * (1.0 if boss else _ai_pitch)
	Brain.say_at(self, r.get("text", ""), r.get("audio", ""), _height + 0.25, pitch, Color(1.0, 0.7, 0.55), str(r.get("fx", "plain")))


## Which family of sounds this creature makes.
func voice() -> String:
	match type:
		"wolf", "snow_wolf", "hellhound":
			return "hound"
		"spider", "crab":
			return "bug"
		"necromancer", "frost_wraith", "sea_witch":
			return "ghost"
		"skeleton", "ghoul", "drowned", "pirate", "captain_bones", "grave_lord":
			return "zombie"
		"raptor":
			return "hound"
		"golem", "frost_yeti", "ice_troll", "magma_golem", "frostmaw", "warlord", "pyrax", "gnoll_brute", "canyon_tyrant", "wild_dino":
			return "roar"
		"gnoll", "gnoll_shaman", "fire_imp", "kobold", "geomancer":
			return "monster"
	return "human"


func _voice_pitch() -> float:
	return clampf(1.15 / maxf(_scale * (1.4 if boss else 1.0), 0.5), 0.55, 1.4) * (1.5 if type == "kobold" else 1.0)


func xp_value() -> int:
	return int(Skills.kill_xp(level, base_hp, elite, boss) * (0.3 if summoned else 1.0))


## Name colour by how dangerous the enemy is for the player: grey (trivial) .. red / purple.
func level_color() -> Color:
	if neutral:
		return Color(0.55, 0.75, 1.0)
	if boss:
		return Color(1.0, 0.5, 0.1)
	if elite:
		return Color(1.0, 0.82, 0.25)
	var d := level - int(Game.progress.get("level", 1))
	if d <= -6:
		return Color(0.6, 0.6, 0.6)
	if d <= -2:
		return Color(0.45, 0.95, 0.45)
	if d <= 1:
		return Color(1.0, 0.95, 0.45)
	if d <= 4:
		return Color(1.0, 0.55, 0.2)
	if d <= 7:
		return Color(1.0, 0.25, 0.2)
	return Color(0.85, 0.3, 1.0)


func is_head_hit(pos: Vector3) -> bool:
	return head_node != null and head_node.global_position.distance_to(pos) < head_radius * _scale * 1.4


## Returns true if this hit killed the enemy. kind: "bullet", "crit" (headshot), "frost".
## Level gap to the player (positive: the monster is stronger).
func level_gap() -> int:
	return level - int(Game.progress.get("level", 1))


## How much harder this monster hits the player: far stronger monsters are deadly
## (+10 levels about x4, +20 levels about x11 - a one-shot), weaker ones hit a bit softer.
func gap_mult() -> float:
	var g := level_gap()
	if g <= 0:
		return maxf(0.55, 1.0 + g * 0.04)
	return 1.0 + 0.12 * g + 0.02 * g * g


## How much of the player's damage gets through: stronger monsters shrug most of it off.
func gap_resist() -> float:
	var g := level_gap()
	if g <= 0:
		return 1.0 + minf(0.5, -g * 0.03)
	return 1.0 / (1.0 + 0.08 * g + 0.012 * g * g)


func take_damage(amount: float, hit_pos: Vector3, dir: Vector3, kind := "bullet") -> bool:
	if state == State.DEAD:
		return false
	amount *= gap_resist()
	if state == State.RETURN:
		world.damage_number(hit_pos, 0.0, "evade")
		return false
	if shield_hp > 0.0:
		var absorbed := minf(shield_hp, amount)
		shield_hp -= absorbed
		amount -= absorbed
		if shield_hp <= 0.0:
			_shield_fx.visible = false
			Game.play_sound("potion", global_position, -4.0, 0.6)
		if amount <= 0.0:
			world.damage_number(hit_pos, absorbed, "absorb")
			return false
	hp -= amount
	_hurt_t = 0.15
	if not _ai_hurt_said and hp > 0.0 and hp < max_hp * 0.4:
		_ai_hurt_said = true
		ai_bark("hurt", 0.8)
	if dir.length_squared() > 0.01:
		_last_hit_dir = dir.normalized()
	if anim and _anim_map.has("hit") and _attack_t < 0.0 and _hit_t <= 0.0 and kind != "frost" and kind != "fire":
		_hit_t = 0.4
		anim.play(_anim_map["hit"], 0.05, 1.5)
		_anim_current = _anim_map["hit"]
	_update_bar()
	world.damage_number(hit_pos, amount, kind)
	if frozen_t <= 0.0 and not boss:
		velocity += Vector3(dir.x, 0, dir.z) * 1.5
	if state == State.IDLE:
		aggro()
	if neutral:
		world.report_crime(3 if hp <= 0.0 else 2, global_position)
	if hp <= 0.0:
		_die()
		return true
	return false


func _die() -> void:
	state = State.DEAD
	remove_from_group("enemies")
	remove_from_group("damageable")
	remove_from_group("allies")
	collision_layer = 0
	collision_mask = 1
	velocity = Vector3.ZERO
	name_label.visible = false
	bar_bg.visible = false
	bar_fg.visible = false
	if ice_block.visible:
		_unfreeze()
	for g in cast_glow:
		g.visible = false
	if _burn_fx:
		_burn_fx.emitting = false
	_shield_fx.visible = false
	if _slam_ring and is_instance_valid(_slam_ring):
		_slam_ring.queue_free()
	var v := voice()
	if v == "human":
		Game.play_sound("enemy_death", global_position, -3.0, 0.7 if boss else 1.0)
	elif v == "ghost":
		Game.play_sound("ghost", global_position, -1.0, 0.7)
	else:
		Game.play_sound("creature_die" if v in ["bug", "hound"] else v, global_position, -1.0, _voice_pitch() * 0.85)
	visual.scale = Vector3.ONE * _scale
	var push := _last_hit_dir * 3.0 + Vector3(0, 1.5, 0)
	if not _start_ragdoll(push):
		_rigid_fall(push)
	var tw := create_tween()
	tw.tween_interval(10.0)
	tw.tween_callback(queue_free)
	died.emit(self)


var _last_hit_dir := Vector3.ZERO


## Ragdoll for skinned models: unscaled RigidBody capsules for the main bones, joined with
## cone-twist joints. Every frame the bodies drive the skeleton (works at any model scale).
var _rag_sk: Skeleton3D
var _rag: Array = []          # [bone index, RigidBody3D, body-to-bone offset]
var _rag_joints: Array = []


func _start_ragdoll(push: Vector3) -> bool:
	if anim == null:
		return false
	var skels := visual.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return false
	var sk: Skeleton3D = skels[0]
	anim.active = false          # freeze the current pose as the starting point
	var skg := sk.global_transform
	var gs := skg.basis.get_scale().x
	var order := []
	for i in sk.get_bone_count():
		var bname := sk.get_bone_name(i).to_lower()
		if bname.contains("end") or bname.contains("index") or bname.contains("thumb") or bname.contains("middle") \
				or bname.contains("ring") or bname.contains("pinky") or bname.contains("toe") or bname.contains("eye") \
				or bname.contains("jaw") or bname.contains("ik") or bname.contains("pole") or bname.contains("root") \
				or bname.contains("ear") or bname.contains("finger"):
			continue
		var length := 0.0
		var dir := Vector3.UP
		var children := sk.get_bone_children(i)
		if not children.is_empty():
			var c := sk.get_bone_rest(children[0]).origin
			length = c.length() * gs
			if c.length() > 0.0001:
				dir = c.normalized()
		var is_head := bname.contains("head")
		if length < 0.1 * _height and not is_head and not order.is_empty():
			continue
		order.append([i, length if length > 0.02 else 0.15 * _height, dir])
		if order.size() >= 16:
			break
	if order.size() < 2:
		anim.active = true
		return false
	var bodies := {}
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.05
	for o in order:
		var i: int = o[0]
		var bone_world := skg * sk.get_bone_global_pose(i)
		var body_xf := Transform3D(bone_world.basis.orthonormalized(), bone_world.origin)
		var rb := RigidBody3D.new()
		rb.collision_layer = 0
		rb.collision_mask = 1
		rb.mass = 2.0
		rb.linear_damp = 0.3
		rb.angular_damp = 3.0
		rb.physics_material_override = pm
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		var length: float = o[1]
		var radius := clampf(length * 0.3, 0.04 * _height, 0.13 * _height)
		cap.radius = radius
		cap.height = maxf(length, radius * 2.0 + 0.02)
		cs.shape = cap
		var y_axis: Vector3 = o[2]
		var x_axis := y_axis.cross(Vector3.FORWARD if absf(y_axis.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
		var z_axis := x_axis.cross(y_axis).normalized()
		cs.transform = Transform3D(Basis(x_axis, y_axis, z_axis), y_axis * length * 0.5)
		rb.add_child(cs)
		world.add_child(rb)
		rb.global_transform = body_xf
		rb.linear_velocity = push * randf_range(0.7, 1.2)
		rb.angular_velocity = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
		_rag.append([i, rb, body_xf.affine_inverse() * bone_world])
		bodies[i] = rb
	for entry in _rag:
		var parent := sk.get_bone_parent(entry[0])
		while parent >= 0 and not bodies.has(parent):
			parent = sk.get_bone_parent(parent)
		if parent < 0:
			continue
		var j := ConeTwistJoint3D.new()
		world.add_child(j)
		j.global_position = (entry[1] as RigidBody3D).global_position
		j.node_a = (bodies[parent] as Node).get_path()
		j.node_b = (entry[1] as Node).get_path()
		j.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(50.0))
		j.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(30.0))
		_rag_joints.append(j)
	_rag_sk = sk
	return true


func _process(_delta: float) -> void:
	if _rag_sk == null or not is_instance_valid(_rag_sk):
		return
	var inv := _rag_sk.global_transform.affine_inverse()
	for entry in _rag:
		var rb: RigidBody3D = entry[1]
		if is_instance_valid(rb):
			_rag_sk.set_bone_global_pose(entry[0], inv * (rb.global_transform * (entry[2] as Transform3D)))


func _exit_tree() -> void:
	for entry in _rag:
		if is_instance_valid(entry[1]):
			entry[1].queue_free()
	for j in _rag_joints:
		if is_instance_valid(j):
			j.queue_free()


## Hand-built models: the whole body becomes one rigid body that tumbles over.
func _rigid_fall(push: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.collision_layer = 0
	rb.collision_mask = 1
	rb.mass = 40.0
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.6 * _scale, _height * 0.9, 0.5 * _scale)
	cs.shape = bx
	cs.position.y = _height * 0.45
	rb.add_child(cs)
	world.add_child(rb)
	rb.global_transform = global_transform
	visual.reparent(rb)
	rb.apply_central_impulse(push * 40.0)
	rb.apply_torque_impulse(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 60.0 + global_transform.basis.x * 40.0)
	var tw := rb.create_tween()
	tw.tween_interval(10.0)
	tw.tween_callback(rb.queue_free)


func _animate_model() -> void:
	if _attack_t >= 0.0 or _slam_t >= 0.0 or _hit_t > 0.0:
		return
	if anim.is_playing() and _anim_current == _anim_map.get("attack", "") and anim.current_animation_position < anim.current_animation_length * 0.95:
		return
	var hs := Vector2(velocity.x, velocity.z).length()
	var key := "idle"
	if hs > speed * 0.6:
		key = "run"
	elif hs > 0.4:
		key = "walk"
	if not _anim_map.has(key):
		key = "walk" if _anim_map.has("walk") else "idle"
	if not _anim_map.has(key):
		return
	var n: String = _anim_map[key]
	var spd := 1.0
	if key == "walk" or key == "run":
		spd = clampf(hs / (speed if key == "run" else speed * 0.4), 0.6, 1.6)
	if n != _anim_current or not anim.is_playing():
		anim.play(n, 0.2, spd)
		_anim_current = n
	else:
		anim.speed_scale = spd


func _animate(delta: float) -> void:
	if anim:
		_animate_model()
		visual.scale = Vector3.ONE * _scale * (1.0 + _hurt_t * 0.3)
		return
	var hs := Vector2(velocity.x, velocity.z).length()
	if hs > 0.3:
		_walk_phase += delta * (4.0 + hs * 2.0)
	var swing := sin(_walk_phase) * clampf(hs / 3.0, 0.0, 1.0) * 0.7

	if legs.size() == 4:
		legs[0].rotation.x = swing
		legs[3].rotation.x = swing
		legs[1].rotation.x = -swing
		legs[2].rotation.x = -swing
		tail.rotation.y = sin(_walk_phase * 1.3) * 0.35
	elif legs.size() == 8:
		for i in 8:
			var s := 1.0 if (i % 2 == 0) != (i >= 4) else -1.0
			legs[i].rotation.x = swing * 0.6 * s
	if legs.size() > 0 and head_node:
		var lunge := 0.25 if _attack_t >= 0.2 and _attack_t < 0.5 else 0.0
		head_node.position = head_node.position.lerp(_head_base + Vector3(0, -lunge * 0.4, -lunge), minf(1.0, 20.0 * delta))
	if l_leg:
		l_leg.rotation.x = swing
		r_leg.rotation.x = -swing

	if l_arm:
		var arm_l := -swing * 0.8
		var arm_r := swing * 0.8
		if _charge_t > 0.0:
			arm_r = 2.2
		if _attack_t >= 0.0:
			if ranged:
				arm_l = 1.4
				arm_r = 1.4
			elif _attack_t < 0.35:
				arm_r = lerpf(0.0, 2.7, _attack_t / 0.35)
			else:
				arm_r = lerpf(2.7, 0.4, clampf((_attack_t - 0.35) / 0.12, 0.0, 1.0))
			r_arm.rotation.x = arm_r
		else:
			r_arm.rotation.x = lerpf(r_arm.rotation.x, arm_r, minf(1.0, 12.0 * delta))
		l_arm.rotation.x = lerpf(l_arm.rotation.x, arm_l, minf(1.0, 12.0 * delta))

	visual.position.y = sin(Time.get_ticks_msec() * 0.003 + _bob_offset) * 0.015
	visual.scale = Vector3.ONE * _scale * (1.0 + _hurt_t * 0.6)
