class_name Loc
extends RefCounted
## Localization. Text is written in English in the code; when Ukrainian is chosen in Settings,
## Loc.t() looks the English text up in data/uk.json (English -> Ukrainian). Missing entries
## fall back to English. Format strings are translated before formatting:
##   Loc.t("Quest accepted: %s") % Loc.t(title)

static var _uk: Dictionary


static func is_uk() -> bool:
	return int(Game.settings.get("narration", 0)) == 1


static func table() -> Dictionary:
	if _uk.is_empty():
		var f := FileAccess.open("res://data/uk.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_uk = d
	return _uk


static func t(text: String) -> String:
	if not is_uk() or text == "":
		return text
	return table().get(text, text)


## Dialogue line id for the current language: "<id>_uk" when Ukrainian is chosen and exists.
static func line(line_id: String) -> String:
	if is_uk():
		var lines: Dictionary = QuestManager.dialogue().get("lines", {})
		if lines.has(line_id + "_uk"):
			return line_id + "_uk"
	return line_id
