class_name ItemIcons
extends RefCounted
## Item icons. Weapons and armor use painted/rendered pictures from
## res://assets/item_icons/<base>/<quality>.png (common, uncommon, rare, epic, legendary);
## materials, potions, gadgets, gold and ammo use res://assets/item_icons/misc/<id>.png.
## Anything without a picture falls back to the small vector drawing below.

const QUALITY_NAMES := ["common", "uncommon", "rare", "epic", "legendary"]
static var _cache: Dictionary = {}


static func _load(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## Picture of a material / consumable / gadget / "gold" / "ammo" (null if there is none).
static func misc(id: String) -> Texture2D:
	return _load("res://assets/item_icons/misc/%s.png" % id)


## A row of small pictures with counts, e.g. [["herb", 3, "Healing Herb"], ...]. Hover shows the name.
static func count_row(entries: Array, icon_size := 40) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	for e in entries:
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(icon_size, icon_size)
		cell.tooltip_text = "%s x%d" % [e[2], int(e[1])]
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		var tex := misc(e[0])
		var n := int(e[1])
		cell.draw.connect(func() -> void:
			cell.draw_rect(Rect2(Vector2.ZERO, cell.size), Color(0.08, 0.09, 0.12, 0.85))
			if tex:
				cell.draw_texture_rect(tex, Rect2(Vector2(2, 2), cell.size - Vector2(4, 4)), false)
			else:
				cell.draw_string(ThemeDB.fallback_font, Vector2(3, 15), String(e[2]).left(3), HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			var txt := str(n)
			var f := ThemeDB.fallback_font
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var pos := Vector2(cell.size.x - w - 3, cell.size.y - 4)
			cell.draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0))
			cell.draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1)))
		row.add_child(cell)
	return row


static func draw_icon(c: CanvasItem, item: Dictionary, size: Vector2) -> void:
	var q: int = clampi(int(item.get("quality", 0)), 0, 4)
	var tex := _load("res://assets/item_icons/%s/%s.png" % [str(item.get("base", "")), QUALITY_NAMES[q]])
	if tex:
		c.draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
		c.draw_circle(Vector2(56, 8) * (size.x / 64.0), 4.0 * size.x / 64.0, Items.quality_color(q))
		return
	_draw_vector(c, item, size)


## The original vector icons (fallback).
static func _draw_vector(c: CanvasItem, item: Dictionary, size: Vector2) -> void:
	var col := Items.quality_color(item["quality"])
	var dark := Color(0.12, 0.12, 0.14)
	var metal := Color(0.55, 0.57, 0.6)
	var wood := Color(0.55, 0.33, 0.18)
	var s := size.x / 64.0
	var o := Vector2(0, 0)
	var r := func(x: float, y: float, w: float, h: float, color: Color) -> void:
		c.draw_rect(Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s), color)
	match item["base"]:
		"pistol":
			r.call(14, 22, 34, 9, metal)
			r.call(30, 30, 9, 18, dark)
			r.call(46, 23, 4, 4, dark)
		"smg":
			r.call(10, 24, 40, 9, metal)
			r.call(30, 32, 6, 16, dark)
			r.call(18, 32, 6, 12, dark)
			r.call(50, 26, 6, 5, dark)
		"rifle":
			r.call(4, 26, 56, 6, metal)
			r.call(36, 24, 16, 9, wood)
			r.call(30, 32, 6, 14, wood)
			r.call(4, 26, 12, 10, wood)
		"shotgun":
			r.call(4, 25, 56, 5, metal)
			r.call(4, 30, 46, 4, dark)
			r.call(30, 29, 14, 7, wood)
			r.call(4, 26, 14, 10, wood)
		"sniper":
			r.call(2, 30, 60, 4, metal)
			r.call(22, 20, 22, 6, dark)
			r.call(4, 30, 16, 9, Color(0.3, 0.35, 0.25))
		"lmg":
			r.call(4, 24, 56, 8, metal)
			r.call(24, 32, 14, 12, Color(0.3, 0.33, 0.25))
			r.call(52, 32, 2, 12, dark)
		"crossbow":
			r.call(10, 30, 46, 6, wood)
			c.draw_line(o + Vector2(14, 14) * s, o + Vector2(14, 52) * s, metal, 3.0 * s)
			c.draw_line(o + Vector2(14, 14) * s, o + Vector2(40, 33) * s, Color(0.9, 0.9, 0.8), 1.2)
			c.draw_line(o + Vector2(14, 52) * s, o + Vector2(40, 33) * s, Color(0.9, 0.9, 0.8), 1.2)
		"flamethrower":
			r.call(8, 24, 46, 7, metal)
			c.draw_circle(o + Vector2(28, 40) * s, 8 * s, Color(0.6, 0.12, 0.08))
			c.draw_circle(o + Vector2(56, 27) * s, 4 * s, Color(1.0, 0.55, 0.15))
		"launcher":
			r.call(8, 22, 44, 12, metal)
			c.draw_circle(o + Vector2(26, 28) * s, 10 * s, Color(0.3, 0.33, 0.25))
		"staff_frost", "staff_fire", "staff_storm":
			c.draw_line(o + Vector2(14, 56) * s, o + Vector2(46, 14) * s, wood, 4.0 * s)
			var g: Color = {"staff_frost": Color(0.45, 0.8, 1.0), "staff_fire": Color(1.0, 0.45, 0.12), "staff_storm": Color(0.7, 0.65, 1.0)}[item["base"]]
			c.draw_circle(o + Vector2(48, 12) * s, 7 * s, g)
		"helmet":
			c.draw_circle(o + Vector2(32, 32) * s, 16 * s, metal)
			r.call(14, 32, 36, 14, Color(0, 0, 0, 0))
			r.call(16, 30, 32, 5, dark)
			r.call(14, 38, 36, 4, metal)
		"armor":
			var pts := PackedVector2Array([Vector2(18, 14), Vector2(46, 14), Vector2(52, 24), Vector2(46, 28), Vector2(46, 52), Vector2(18, 52), Vector2(18, 28), Vector2(12, 24)])
			for i in pts.size():
				pts[i] = o + pts[i] * s
			c.draw_colored_polygon(pts, metal)
			r.call(30, 16, 4, 34, dark)
		"gloves":
			r.call(14, 24, 14, 22, Color(0.4, 0.3, 0.22))
			r.call(36, 24, 14, 22, Color(0.4, 0.3, 0.22))
			r.call(14, 40, 14, 6, metal)
			r.call(36, 40, 14, 6, metal)
		"boots":
			r.call(16, 16, 10, 28, Color(0.35, 0.25, 0.18))
			r.call(16, 40, 18, 8, Color(0.35, 0.25, 0.18))
			r.call(38, 16, 10, 28, Color(0.35, 0.25, 0.18))
			r.call(38, 40, 18, 8, Color(0.35, 0.25, 0.18))
		"amulet":
			c.draw_arc(o + Vector2(32, 26) * s, 14 * s, 0.3, PI - 0.3, 16, Color(0.9, 0.75, 0.3), 2.0)
			c.draw_circle(o + Vector2(32, 44) * s, 7 * s, col)
	# quality gem in the corner
	c.draw_circle(o + Vector2(56, 8) * s, 4 * s, col)
