class_name Skills
extends RefCounted
## Player skill / talent definitions and the XP curve.

const MAX_LEVEL := 50

## type: "active" (has key, mana, cooldown) or "passive".
const LIST := {
	"frost_arrow": {"name": "Frost Arrow", "type": "active", "action": "frost_arrow", "key": "Q", "max": 5, "level": 1, "mana": 20.0, "cd": 0.8,
		"desc": "Ice shard that freezes one enemy for 3 s, then deals frost damage over time. +30% damage per rank."},
	"frost_nova": {"name": "Frost Nova", "type": "active", "action": "frost_nova", "key": "E", "max": 5, "level": 1, "mana": 45.0, "cd": 10.0,
		"desc": "Freezes every enemy within 10 m for 4 s. +30% damage and +2 m radius per rank."},
	"fireball": {"name": "Fireball", "type": "active", "action": "skill_fireball", "key": "X", "max": 5, "level": 2, "mana": 30.0, "cd": 2.5,
		"desc": "Hurls a fireball that explodes for 60 damage in 4 m and sets enemies on fire. +30% damage per rank."},
	"heal": {"name": "Renew", "type": "active", "action": "skill_heal", "key": "C", "max": 5, "level": 2, "mana": 40.0, "cd": 12.0,
		"desc": "Instantly restores 35% of your health (+10% per rank)."},
	"chain_lightning": {"name": "Chain Lightning", "type": "active", "action": "skill_lightning", "key": "G", "max": 5, "level": 3, "mana": 35.0, "cd": 5.0,
		"desc": "Lightning strikes the enemy you aim at for 70 damage and jumps to 3 more (+1 per rank)."},
	"blink": {"name": "Blink", "type": "active", "action": "skill_blink", "key": "V", "max": 1, "level": 4, "mana": 25.0, "cd": 6.0,
		"desc": "Teleports you 12 m in the direction you look."},
	"meteor": {"name": "Meteor", "type": "active", "action": "skill_meteor", "key": "T", "max": 1, "level": 6, "mana": 70.0, "cd": 30.0,
		"desc": "Calls a meteor down where you aim: 220 damage in a 7 m blast."},
	"toughness": {"name": "Toughness", "type": "passive", "max": 10, "level": 1, "desc": "+10% maximum health per rank."},
	"arcane_mind": {"name": "Arcane Mind", "type": "passive", "max": 10, "level": 1, "desc": "+12 maximum mana and +0.5 mana regeneration per rank."},
	"marksman": {"name": "Marksman", "type": "passive", "max": 10, "level": 1, "desc": "+6% weapon damage per rank."},
	"frostbite": {"name": "Frostbite", "type": "passive", "max": 5, "level": 2, "desc": "Freezes last 0.7 s longer and frost damage +20% per rank."},
	"quick_hands": {"name": "Quick Hands", "type": "passive", "max": 5, "level": 3, "desc": "Reload 10% faster per rank."},
}

const ORDER := ["frost_arrow", "frost_nova", "fireball", "heal", "chain_lightning", "blink", "meteor",
	"toughness", "arcane_mind", "marksman", "frostbite", "quick_hands"]


## XP needed to go from `level` to the next one (about 720k XP from 1 to 50).
static func xp_to_next(level: int) -> int:
	return int(60.0 * pow(level, 1.65)) + 40


## XP for killing an enemy of this level (base_hp = the type's level-1 health).
static func kill_xp(enemy_level: int, base_hp: float, elite: bool, boss: bool) -> int:
	var xp := 18.0 * pow(enemy_level, 1.25) * pow(base_hp / 100.0, 0.6)
	if elite:
		xp *= 2.5
	if boss:
		xp *= 8.0
	return int(xp)


static func new_progress() -> Dictionary:
	return {"level": 1, "xp": 0, "points": 0, "ranks": {"frost_arrow": 1, "frost_nova": 1}}
