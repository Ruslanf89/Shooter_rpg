class_name CraftUI
extends Control
## Crafting window. [U] opens the field kit anywhere (ammo, bandages); stations add their own
## recipes: alchemy table (potions, gunpowder), workbench (grenades, mines, turrets, FPV drones),
## forge (weapons and armor of your level in a chosen quality, upgrades and rerolls).
## Salvaging gear is in the inventory ([I], salvage mode).

var world: Node
var station := "field"
var _list: VBoxContainer
var _detail: VBoxContainer
var _mats: Label
var _sel := {}
var _quality := 0


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
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	center.add_child(root)
	# recipe list
	var lp := _panel(root, Loc.t(Crafting.STATION_NAMES[station]))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(340, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	sc.add_child(_list)
	# details + materials
	var rp := _panel(root, Loc.t("Details"))
	rp.custom_minimum_size = Vector2(470, 0)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	_detail.custom_minimum_size = Vector2(470, 330)
	rp.add_child(_detail)
	rp.add_child(HSeparator.new())
	rp.add_child(Game.make_label(Loc.t("Your materials"), 17, Color(1.0, 0.84, 0.4)))
	_mats = Game.make_label("", 14, Color(0.85, 0.85, 0.88))
	_mats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mats.custom_minimum_size = Vector2(470, 0)
	rp.add_child(_mats)
	var hint := Game.make_label(Loc.t("[Esc] close  -  salvage gear in the inventory [I]"), 13, Color(0.65, 0.65, 0.7))
	rp.add_child(hint)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world.player.input_locked = true
	_fill_list()
	_refresh()


func _panel(parent: Control, title: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", InventoryUI._style(Color(0.06, 0.06, 0.1, 0.95), Color(0.8, 0.65, 0.3)))
	parent.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	var l := Game.make_label(title, 22, Color(1.0, 0.84, 0.4))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	return vb


func _entry(text: String, sel: Dictionary, color := Color(1.0, 0.92, 0.72)) -> void:
	var b := Game.make_button(text, 0.0)
	b.custom_minimum_size = Vector2(0, 32)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", color)
	b.pressed.connect(func() -> void:
		_sel = sel
		_refresh())
	_list.add_child(b)


func _header(text: String) -> void:
	var l := Game.make_label(text, 15, Color(0.6, 0.8, 1.0))
	_list.add_child(l)


func _fill_list() -> void:
	_header(Loc.t("Field kit (anywhere)"))
	for r in Crafting.RECIPES:
		if r["station"] == "field":
			_entry(Crafting.recipe_name(r), {"kind": "recipe", "id": r["id"]})
	if station in ["alchemy", "workbench"]:
		_header(Loc.t(Crafting.STATION_NAMES[station]))
		for r in Crafting.RECIPES:
			if r["station"] == station:
				_entry(Crafting.recipe_name(r), {"kind": "recipe", "id": r["id"]})
	if station == "forge":
		_header(Loc.t("Forge a weapon"))
		for b in Items.WEAPONS:
			_entry(Loc.t(Items.WEAPONS[b]["name"]), {"kind": "gear", "id": b})
		_header(Loc.t("Forge armor"))
		for b in Items.ARMOR:
			_entry(Loc.t(Items.ARMOR[b]["name"]), {"kind": "gear", "id": b})
		_header(Loc.t("Improve gear"))
		_entry(Loc.t("Upgrade / reroll an item"), {"kind": "upgrade"}, Color(0.85, 0.7, 1.0))
	var first := Crafting.RECIPES[0]
	_sel = {"kind": "recipe", "id": first["id"]}
	if station != "field":
		for r in Crafting.RECIPES:
			if r["station"] == station:
				_sel = {"kind": "recipe", "id": r["id"]}
				break
		if station == "forge":
			_sel = {"kind": "gear", "id": "rifle"}


func _cost_lines(cost: Dictionary) -> void:
	for k in cost:
		var have: int = int(Game.inventory.get("gold", 0)) if k == "gold" else Crafting.count(k)
		var need := int(cost[k])
		var name: String = Loc.t("Gold") if k == "gold" else Crafting.mat_name(k)
		var line := "  %s   %d / %d" % [name, mini(have, 99999), need]
		if Crafting.RARE.has(k):
			line += "   (" + Loc.t(Crafting.RARE[k][1]) + ")"
		_detail.add_child(Game.make_label(line, 15, Color(0.55, 1.0, 0.55) if have >= need else Color(1.0, 0.45, 0.4)))


func _craft_button(text: String, enabled: bool, cb: Callable) -> void:
	var b := Game.make_button(text, 260.0)
	b.custom_minimum_size = Vector2(260, 44)
	b.add_theme_font_size_override("font_size", 19)
	b.disabled = not enabled
	b.pressed.connect(cb)
	_detail.add_child(b)


func _refresh() -> void:
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	match _sel.get("kind", ""):
		"recipe":
			_show_recipe(Crafting.recipe(_sel["id"]))
		"gear":
			_show_gear(_sel["id"])
		"upgrade":
			_show_upgrade()
	_update_mats()


func _show_recipe(r: Dictionary) -> void:
	_detail.add_child(Game.make_label(Crafting.recipe_name(r), 22, Color(1.0, 0.9, 0.6)))
	var d := Game.make_label(Crafting.recipe_desc(r), 15, Color(0.85, 0.85, 0.9))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(d)
	_detail.add_child(Game.make_label(Loc.t("Needs:"), 15, Color(0.8, 0.8, 0.85)))
	_cost_lines(r["cost"])
	_craft_button(Loc.t("Craft"), Crafting.has_all(r["cost"]), func() -> void:
		if Crafting.craft(r, world.player):
			Game.play_sound("pickup_tech", null, -4.0)
			world.hud.show_message(Loc.t("Crafted") + ": " + Crafting.recipe_name(r), Color(0.7, 1.0, 0.6), 1.5)
		_refresh())


func _show_gear(base: String) -> void:
	var lvl := int(Game.progress["level"])
	var name: String = Items.WEAPONS[base]["name"] if Items.WEAPONS.has(base) else Items.ARMOR[base]["name"]
	_detail.add_child(Game.make_label(Loc.t(name) + "   " + Loc.t("Level") + " %d" % lvl, 22, Color(1.0, 0.9, 0.6)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_detail.add_child(row)
	for q in 5:
		var b := Button.new()
		b.text = Loc.t(Items.QUALITY[q]["name"])
		b.toggle_mode = true
		b.button_pressed = q == _quality
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Items.quality_color(q))
		b.add_theme_color_override("font_pressed_color", Items.quality_color(q).lightened(0.4))
		b.pressed.connect(func() -> void:
			_quality = q
			_refresh())
		row.add_child(b)
	var preview := Items.generate(lvl, _quality, "", base)
	for line in Items.tooltip(preview).slice(2, 4):
		_detail.add_child(Game.make_label(line[0], 15, line[1]))
	var bonus := Game.make_label(Loc.t("%d random bonuses") % Items.QUALITY[_quality]["affixes"], 14, Color(0.55, 0.85, 1.0))
	_detail.add_child(bonus)
	_detail.add_child(Game.make_label(Loc.t("Needs:"), 15, Color(0.8, 0.8, 0.85)))
	var cost := Crafting.gear_cost(base, lvl, _quality)
	_cost_lines(cost)
	_craft_button(Loc.t("Forge"), Crafting.has_all(cost), func() -> void:
		var it := Crafting.forge(base, lvl, _quality)
		if it.is_empty():
			world.hud.show_message(Loc.t("Your bag is full"), Color(1.0, 0.45, 0.35), 1.5)
		else:
			Game.play_sound("impact_stone", null, -2.0, 1.4)
			Game.play_sound("pickup_item", null, -4.0)
			world.hud.show_message(Loc.t("Forged") + ": " + Items.display_name(it), Items.quality_color(it["quality"]), 2.0)
		_refresh())


func _show_upgrade() -> void:
	_detail.add_child(Game.make_label(Loc.t("Upgrade / reroll an item"), 20, Color(0.85, 0.7, 1.0)))
	var items := []
	for s in Items.SLOTS:
		var it = Game.inventory["equip"].get(s, {})
		if it is Dictionary and not it.is_empty():
			items.append(it)
	for it in Game.inventory["bag"]:
		if it is Dictionary and not it.is_empty():
			items.append(it)
	var grid := GridContainer.new()
	grid.columns = 2
	_detail.add_child(grid)
	var chosen = _sel.get("item")
	for it in items.slice(0, 12):
		var b := Button.new()
		b.text = Items.display_name(it) + "  %d" % it["level"]
		b.custom_minimum_size = Vector2(230, 28)
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Items.quality_color(it["quality"]))
		b.toggle_mode = true
		b.button_pressed = chosen == it
		b.pressed.connect(func() -> void:
			_sel["item"] = it
			_refresh())
		grid.add_child(b)
	if chosen == null or not chosen in items:
		_detail.add_child(Game.make_label(Loc.t("Pick an item above."), 15, Color(0.75, 0.75, 0.8)))
		return
	var up := Crafting.upgrade_cost(chosen)
	if up.is_empty():
		_detail.add_child(Game.make_label(Loc.t("Already Legendary"), 15, Items.quality_color(4)))
	else:
		_detail.add_child(Game.make_label(Loc.t("Upgrade to %s:") % Loc.t(Items.QUALITY[int(chosen["quality"]) + 1]["name"]), 15, Items.quality_color(int(chosen["quality"]) + 1)))
		_cost_lines(up)
		_craft_button(Loc.t("Upgrade"), Crafting.has_all(up), func() -> void:
			if Crafting.upgrade(chosen):
				Game.play_sound("level_up", null, -6.0, 1.3)
				world.player.equip_active()
				world.player.recalc_stats()
			_refresh())
	if not chosen["affixes"].is_empty():
		_detail.add_child(Game.make_label(Loc.t("New random bonuses:"), 15, Color(0.55, 0.85, 1.0)))
		var rc := Crafting.reroll_cost(chosen)
		_cost_lines(rc)
		_craft_button(Loc.t("Reroll"), Crafting.has_all(rc), func() -> void:
			if Crafting.reroll(chosen):
				Game.play_sound("cast", null, -6.0, 1.4)
				world.player.recalc_stats()
			_refresh())


func _update_mats() -> void:
	var parts := []
	for k in Crafting.MATERIALS:
		var n := Crafting.count(k)
		if n > 0:
			parts.append("%s %d" % [Crafting.mat_name(k), n])
	var c := Crafting.pouch("consumables")
	var g := Crafting.pouch("gadgets")
	var bag := []
	for k in c:
		if int(c[k]) > 0:
			bag.append("%s %d" % [Loc.t(Crafting.CONSUMABLES[k][0]), int(c[k])])
	for k in g:
		if int(g[k]) > 0:
			bag.append("%s %d" % [Loc.t(Crafting.GADGETS[k][0]), int(g[k])])
	_mats.text = ("  ·  ".join(parts) if not parts.is_empty() else Loc.t("None yet - monsters drop materials, and you can gather ore, herbs and timber [F]")) \
		+ ("\n" + "  ·  ".join(bag) if not bag.is_empty() else "") + "\n" + Loc.t("Gold") + ": %d" % int(Game.inventory.get("gold", 0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("craft") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	world.player.input_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
