class_name VillagerTalk
extends RefCounted
## Picks villager / kid lines from data/villager_talk.json (voiced as vt_<m|f|kid>_<key>_<n>).

const PERSONALITIES := ["brave", "coward", "gossip", "grumpy", "kind", "superstitious"]

static var _counts: Dictionary


static func counts() -> Dictionary:
	if _counts.is_empty():
		var f := FileAccess.open("res://data/villager_talk.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				for k in d:
					_counts[k] = (d[k] as Array).size()
	return _counts


static func has(key: String) -> bool:
	return counts().has(key)


## Line id for a speaker ("m", "f" or "kid") and key; falls back to `fallback` when missing.
static func pick(speaker: String, key: String, fallback := "") -> String:
	if not has(key):
		key = fallback
	if not has(key):
		return ""
	var prefix := "vt_kid_" if speaker == "kid" else "vt_%s_" % speaker
	return "%s%s_%d" % [prefix, key, randi_range(1, int(counts()[key]))]
