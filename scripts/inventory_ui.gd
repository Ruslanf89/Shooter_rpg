class_name InventoryUI
extends Control
## Inventory window (I). Equipment slots, 30-slot bag, character stats, tooltips with comparison.
## Drag items between slots; right-click equips / unequips (sells to a trader, moves to the stash).
## mode: "bag", "trade" (shop panel on the left) or "stash" (stash panel on the left).

signal closed

const SLOT := 64.0

var world: Node
var mode := "bag"
var shop: Array = []              # trader stock (items)
var trader_name := ""
var shop_kind := "general"         # general / weapons / armor / alchemy
var salvage_mode := false
var _root: HBoxContainer
var _tip: PanelContainer
var _tip2: PanelContainer
var _stats: Label
var _gold: Label
var _slots: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_root = HBoxContainer.new()
	_root.add_theme_constant_override("separation", 18)
	center.add_child(_root)
	_tip = _make_tip()
	_tip2 = _make_tip()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world.player.input_locked = true
	refresh()


func _make_tip() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.04, 0.04, 0.07, 0.96), Color(0.6, 0.55, 0.4)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.visible = false
	p.z_index = 10
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	p.add_child(vb)
	add_child(p)
	return p


static func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _panel(title: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.06, 0.06, 0.1, 0.94), Color(0.8, 0.65, 0.3)))
	_root.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	var l := Game.make_label(title, 24, Color(1.0, 0.84, 0.4))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	return vb


func refresh() -> void:
	for c in _root.get_children():
		c.queue_free()
	_slots.clear()
	var inv: Dictionary = Game.inventory
	if mode == "trade":
		var vb := _panel(trader_name if trader_name != "" else Loc.t("Trader"))
		vb.add_child(_grid("shop", shop.size(), 4, shop))
		var hint := Game.make_label(Loc.t("Right-click: buy / sell"), 15, Color(0.75, 0.75, 0.8))
		vb.add_child(hint)
		if shop_kind in ["general", "weapons"]:
			var ammo := Game.make_button(Loc.t("Buy 60 ammo") + "  (%d)" % _ammo_price(), 300.0)
			ammo.pressed.connect(_buy_ammo)
			vb.add_child(ammo)
		var goods: Array = {"general": ["bandage", "health_potion"], "alchemy": ["health_potion", "mana_potion", "greater_potion"]}.get(shop_kind, [])
		for g in goods:
			var price := _goods_price(g)
			var gb := Game.make_button(Loc.t("Buy") + " " + Loc.t(Crafting.CONSUMABLES[g][0]) + "  (%d)" % price, 300.0)
			gb.add_theme_font_size_override("font_size", 18)
			gb.custom_minimum_size = Vector2(300, 40)
			gb.pressed.connect(_buy_goods.bind(g))
			vb.add_child(gb)
	elif mode == "stash":
		var vb := _panel(Loc.t("Stash"))
		vb.add_child(_grid("stash", inv["stash"].size(), 8, inv["stash"]))
	# equipment + stats
	var ev := _panel(Loc.t("Equipment"))
	var eg := GridContainer.new()
	eg.columns = 2
	eg.add_theme_constant_override("h_separation", 10)
	eg.add_theme_constant_override("v_separation", 6)
	ev.add_child(eg)
	for s in Items.SLOTS:
		var box := VBoxContainer.new()
		var lab := Game.make_label(Loc.t(_slot_label(s)) + (" *" if s == inv.get("active", "") else ""), 14, Color(0.8, 0.8, 0.85))
		box.add_child(lab)
		box.add_child(_slot("equip", s, inv["equip"].get(s, {})))
		eg.add_child(box)
	_stats = Game.make_label("", 16, Color(0.9, 0.9, 0.92))
	_stats.custom_minimum_size = Vector2(260, 0)
	ev.add_child(_stats)
	_update_stats()
	# bag
	var bv := _panel(Loc.t("Bag"))
	bv.add_child(_grid("bag", inv["bag"].size(), 6, inv["bag"]))
	_gold = Game.make_label("", 22, Color(1.0, 0.85, 0.3))
	bv.add_child(_gold)
	_gold.text = Loc.t("Gold") + ": %d" % int(inv["gold"])
	var sv := Game.make_button((Loc.t("Salvage mode: ON") if salvage_mode else Loc.t("Salvage mode: off")), 300.0)
	sv.custom_minimum_size = Vector2(300, 40)
	sv.add_theme_font_size_override("font_size", 17)
	sv.pressed.connect(func() -> void:
		salvage_mode = not salvage_mode
		refresh())
	bv.add_child(sv)
	var pc := Crafting.pouch("consumables")
	var potions := Game.make_label("%s %d   %s %d   %s %d" % [Loc.t("Potions [H]"), int(pc.get("health_potion", 0)) + int(pc.get("greater_potion", 0)), Loc.t("Mana [J]"), int(pc.get("mana_potion", 0)), Loc.t("Bandages"), int(pc.get("bandage", 0))], 15, Color(1.0, 0.7, 0.65))
	bv.add_child(potions)
	var hint2 := Game.make_label(Loc.t("Salvage mode: right-click breaks an item into materials") if salvage_mode else Loc.t("Drag to move  -  right-click to equip  -  [I] / [Esc] close"), 14, Color(1.0, 0.6, 0.4) if salvage_mode else Color(0.7, 0.7, 0.75))
	bv.add_child(hint2)


func _slot_label(s: String) -> String:
	return {"weapon1": "Weapon 1", "weapon2": "Weapon 2", "helmet": "Helmet", "armor": "Body Armor", "gloves": "Gloves", "boots": "Boots", "amulet": "Amulet"}[s]


func _grid(container: String, count: int, columns: int, arr: Array) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	for i in count:
		var it = arr[i] if i < arr.size() else null
		g.add_child(_slot(container, i, it if it is Dictionary else {}))
	return g


func _slot(container: String, key, item: Dictionary) -> ItemSlot:
	var s := ItemSlot.new()
	s.ui = self
	s.container = container
	s.key = key
	s.item = item if item != null else {}
	s.custom_minimum_size = Vector2(SLOT, SLOT)
	_slots.append(s)
	return s


func _update_stats() -> void:
	var p: Player = world.player
	var lvl: int = Game.progress["level"]
	var dps := p.weapon_damage() * float(p.wdef.get("pellets", 1)) / float(p.wdef.get("interval", 0.1))
	_stats.text = "%s %d   (%d / %d XP)\n%s: %d\n%s: %d\n%s: %d  (-%d%%)\n%s: %d\n%s: %d%%\n%s: +%d%%" % [
		Loc.t("Level"), lvl, int(Game.progress["xp"]), Skills.xp_to_next(lvl),
		Loc.t("Health"), int(p.max_health), Loc.t("Mana"), int(p.max_mana),
		Loc.t("Armor"), int(p.armor), int(100.0 - 10000.0 / (100.0 + p.armor)),
		Loc.t("Weapon DPS"), int(dps), Loc.t("Critical chance"), int(5 + p.eq("crit")),
		Loc.t("Move speed"), int((p.move_mult - 1.0) * 100.0)]


# --------------------------------------------------------------------------- item moves

func _item_at(container: String, key):
	var inv: Dictionary = Game.inventory
	match container:
		"equip":
			var it = inv["equip"].get(key, {})
			return it if it is Dictionary and not it.is_empty() else null
		"shop":
			return shop[key] if key < shop.size() else null
		_:
			var it = inv[container][key]
			return it if it is Dictionary and not it.is_empty() else null


func _put(container: String, key, item) -> void:
	var inv: Dictionary = Game.inventory
	match container:
		"equip":
			inv["equip"][key] = item if item != null else {}
		"shop":
			shop[key] = item
		_:
			inv[container][key] = item


func can_place(item, container: String, key) -> bool:
	if item == null:
		return true
	if container != "equip":
		return true
	if item["kind"] == "weapon":
		return str(key).begins_with("weapon")
	return item["base"] == key


## Drag from (fc, fk) to (tc, tk).
func move(fc: String, fk, tc: String, tk) -> void:
	if fc == tc and fk == tk:
		return
	var a = _item_at(fc, fk)
	var b = _item_at(tc, tk)
	if a == null:
		return
	if fc == "shop" and tc != "shop":
		if tc == "bag" and b == null:
			_buy(fk, tk)
		return
	if tc == "shop":
		if fc == "bag":
			_sell(fk)
		return
	if not can_place(a, tc, tk) or not can_place(b, fc, fk):
		Game.play_sound("empty", null, -4.0)
		return
	if fc == "equip" and str(fk).begins_with("weapon") and b == null and tc != "equip":
		# don't leave the player without any weapon
		var other := "weapon2" if fk == "weapon1" else "weapon1"
		if _item_at("equip", other) == null:
			world.hud.show_message(Loc.t("You need at least one weapon"), Color(1.0, 0.5, 0.3), 1.5)
			return
	_put(tc, tk, a)
	_put(fc, fk, b)
	Game.play_sound("pickup_item", null, -6.0)
	_changed()


## Right-click: quick action.
func quick(container: String, key) -> void:
	var it = _item_at(container, key)
	if it == null:
		return
	match container:
		"bag":
			if salvage_mode:
				var y := Crafting.salvage(it)
				Game.inventory["bag"][key] = null
				var parts := []
				for k in y:
					parts.append("+%d %s" % [int(y[k]), Crafting.mat_name(k)])
				world.hud.show_message(", ".join(parts), Color(0.8, 0.95, 0.7), 2.0)
				Game.play_sound("impact_stone", null, -4.0, 1.5)
				_changed()
			elif mode == "trade":
				_sell(key)
			elif mode == "stash":
				var free := _free_index(Game.inventory["stash"])
				if free >= 0:
					move("bag", key, "stash", free)
			else:
				var slot := Items.slot_for(it)
				if it["kind"] == "weapon" and _item_at("equip", "weapon1") != null and _item_at("equip", "weapon2") == null:
					slot = "weapon2"
				elif it["kind"] == "weapon":
					slot = Game.inventory.get("active", "weapon1")
				move("bag", key, "equip", slot)
		"equip":
			var free := _free_index(Game.inventory["bag"])
			if free >= 0:
				move("equip", key, "bag", free)
		"stash":
			var free := _free_index(Game.inventory["bag"])
			if free >= 0:
				move("stash", key, "bag", free)
		"shop":
			var free := _free_index(Game.inventory["bag"])
			if free >= 0:
				_buy(key, free)


func _free_index(arr: Array) -> int:
	for i in arr.size():
		if arr[i] == null or (arr[i] is Dictionary and arr[i].is_empty()):
			return i
	return -1


func buy_price(it: Dictionary) -> int:
	return Items.value(it) * 3


func _buy(shop_i: int, bag_i: int) -> void:
	var it = shop[shop_i]
	if it == null:
		return
	var price := buy_price(it)
	if int(Game.inventory["gold"]) < price:
		world.hud.show_message(Loc.t("Not enough gold"), Color(1.0, 0.45, 0.3), 1.4)
		Game.play_sound("empty", null, -4.0)
		return
	Game.inventory["gold"] = int(Game.inventory["gold"]) - price
	Game.inventory["bag"][bag_i] = it
	shop[shop_i] = null
	Game.play_sound("pickup_coins", null, -3.0)
	_changed()


func _sell(bag_i: int) -> void:
	var it = Game.inventory["bag"][bag_i]
	if not it is Dictionary or it.is_empty():
		return
	Game.inventory["gold"] = int(Game.inventory["gold"]) + Items.value(it)
	Game.inventory["bag"][bag_i] = null
	var free := _free_index(shop)
	if free >= 0:
		shop[free] = it
	Game.play_sound("pickup_coins", null, -3.0)
	_changed()


func _goods_price(id: String) -> int:
	var base: int = {"bandage": 8, "health_potion": 20, "mana_potion": 20, "greater_potion": 70}.get(id, 20)
	return base + base * Game.level_index * 2


func _buy_goods(id: String) -> void:
	var price := _goods_price(id)
	if int(Game.inventory["gold"]) < price:
		world.hud.show_message(Loc.t("Not enough gold"), Color(1.0, 0.45, 0.3), 1.4)
		Game.play_sound("empty", null, -4.0)
		return
	Game.inventory["gold"] = int(Game.inventory["gold"]) - price
	var c := Crafting.pouch("consumables")
	c[id] = int(c.get(id, 0)) + (2 if id == "bandage" else 1)
	Game.play_sound("pickup_coins", null, -3.0)
	_changed()


func _ammo_price() -> int:
	return 20 + Game.level_index * 25


func _buy_ammo() -> void:
	var price := _ammo_price()
	if int(Game.inventory["gold"]) < price:
		world.hud.show_message(Loc.t("Not enough gold"), Color(1.0, 0.45, 0.3), 1.4)
		return
	Game.inventory["gold"] = int(Game.inventory["gold"]) - price
	world.player.add_ammo(60)
	_changed()


func _changed() -> void:
	var p: Player = world.player
	p.weapon_item["mag"] = p.mag
	p.equip_active()
	_tip.visible = false
	_tip2.visible = false
	refresh()


# --------------------------------------------------------------------------- tooltips

func show_tip(slot: ItemSlot) -> void:
	if slot.item.is_empty():
		_tip.visible = false
		_tip2.visible = false
		return
	_fill(_tip, slot.item, slot.container == "shop")
	var pos := slot.get_global_rect().position + Vector2(SLOT + 8, 0)
	_tip.visible = true
	_tip.reset_size()
	if pos.x + _tip.size.x > size.x:
		pos.x = slot.get_global_rect().position.x - _tip.size.x - 8
	_tip.global_position = Vector2(pos.x, clampf(pos.y, 0, size.y - _tip.size.y))
	# compare with what's equipped
	_tip2.visible = false
	if slot.container != "equip":
		var cmp = null
		if slot.item["kind"] == "weapon":
			cmp = _item_at("equip", Game.inventory.get("active", "weapon1"))
		else:
			cmp = _item_at("equip", slot.item["base"])
		if cmp != null:
			_fill(_tip2, cmp, false, Loc.t("Equipped"))
			_tip2.visible = true
			_tip2.reset_size()
			var p2 := _tip.global_position + Vector2(_tip.size.x + 6, 0)
			if p2.x + _tip2.size.x > size.x:
				p2.x = _tip.global_position.x - _tip2.size.x - 6
			_tip2.global_position = p2


func hide_tip() -> void:
	_tip.visible = false
	_tip2.visible = false


func _fill(tip: PanelContainer, item: Dictionary, shop_item: bool, header := "") -> void:
	var vb: VBoxContainer = tip.get_child(0)
	for c in vb.get_children():
		c.queue_free()
	if header != "":
		vb.add_child(Game.make_label(header, 14, Color(0.7, 0.7, 0.75)))
	var first := true
	for line in Items.tooltip(item):
		vb.add_child(Game.make_label(line[0], 20 if first else 16, line[1]))
		first = false
	if shop_item:
		vb.add_child(Game.make_label(Loc.t("Price") + ": %d" % buy_price(item), 16, Color(1.0, 0.75, 0.3)))
	if int(item["level"]) > int(Game.progress["level"]) + 3:
		vb.add_child(Game.make_label(Loc.t("Much stronger than you - use carefully"), 14, Color(1.0, 0.5, 0.4)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	world.player.input_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()
	queue_free()


# --------------------------------------------------------------------------- slot control

class ItemSlot extends Panel:
	var ui: InventoryUI
	var container := "bag"
	var key
	var item: Dictionary = {}

	func _ready() -> void:
		var q := int(item.get("quality", -1))
		var border := Items.quality_color(q) if q >= 0 else Color(0.3, 0.3, 0.35)
		add_theme_stylebox_override("panel", InventoryUI._slot_style(border, q >= 0))
		mouse_entered.connect(func() -> void: ui.show_tip(self))
		mouse_exited.connect(func() -> void: ui.hide_tip())

	func _draw() -> void:
		if item.is_empty():
			return
		ItemIcons.draw_icon(self, item, size)
		var lvl := str(item["level"])
		draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 5), lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			ui.quick(container, key)

	func _get_drag_data(_pos: Vector2):
		if item.is_empty():
			return null
		var prev := Panel.new()
		prev.size = Vector2(56, 56)
		prev.modulate.a = 0.8
		prev.add_theme_stylebox_override("panel", InventoryUI._slot_style(Items.quality_color(item["quality"]), true))
		set_drag_preview(prev)
		return {"container": container, "key": key}

	func _can_drop_data(_pos: Vector2, data) -> bool:
		return data is Dictionary and data.has("container")

	func _drop_data(_pos: Vector2, data) -> void:
		ui.move(data["container"], data["key"], container, key)


static func _slot_style(border: Color, filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(border.r * 0.15, border.g * 0.15, border.b * 0.15, 0.95) if filled else Color(0.08, 0.08, 0.1, 0.9)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	return sb
