class_name WorkshopScreens
extends RefCounted
const TILE := 66.0
const POWER_TINT := Color("ffd36b")
var strategy_widgets: Array = []
var start_button: Button

func menu(ui) -> void:
	var root = ui._clear("menu")
	ui.menu_background()
	var bar := HBoxContainer.new()
	root.add_child(bar)
	var brand = ui.label("M / O     //     " + tr("UNDERGROUND"), 16, ui.accent)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(brand)
	bar.add_child(ui.label(tr("PAIR") % [Session.player_name(0), Session.player_name(1)], 16))
	ui.spacer(root)
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 40)
	root.add_child(hero)
	var launch := VBoxContainer.new()
	launch.custom_minimum_size.x = 540
	launch.add_theme_constant_override("separation", 10)
	hero.add_child(launch)
	launch.add_child(ui.label("01 / " + tr("DUEL"), 16, ui.accent))
	for entry in [["MARBLE", 92, ui.ink], ["OVERDRIVE", 96, ui.accent]]:
		var title = ui.label(entry[0], entry[1], entry[2])
		title.add_theme_font_override("font", ui.title_font)
		launch.add_child(title)
	launch.add_child(ui.paragraph(tr("MENU_BRIEF"), 20))
	var play = ui.button(tr("PLAY") + "    /    >>", ui.show_setup, true)
	play.custom_minimum_size.y = 58
	launch.add_child(play)
	play.grab_focus()
	var options := GridContainer.new()
	options.columns = 2
	options.add_theme_constant_override("h_separation", 12)
	options.add_theme_constant_override("v_separation", 10)
	launch.add_child(options)
	for entry in [["PROFILE", ui.show_profiles], ["SCENARIOS", ui.show_scenarios], ["GUIDE", ui.show_guide], ["CONTROLS", ui.show_controls], ["SETTINGS", ui.show_settings], ["QUIT", func(): ui.get_tree().quit()]]:
		var action = ui.button(tr(entry[0]), entry[1])
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options.add_child(action)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(side)
	ui.spacer(side)
	ui.spacer(root)
	var lower := HBoxContainer.new()
	root.add_child(lower)
	var edition = ui.paragraph(tr("EDITION_BADGE") + "\n" + tr("LOCAL"), 13)
	edition.size_flags_vertical = Control.SIZE_SHRINK_END
	lower.add_child(edition)
	var feed = ui.card(lower)
	feed.custom_minimum_size.x = 440
	feed.add_child(ui.label(tr("CIRCUIT_LIVE"), 13, ui.accent))
	feed.add_child(ui.label(tr("SCENE_" + Session.scenario), 26))
	feed.add_child(ui.paragraph(tr("SCENE_" + Session.scenario + "_DESC"), 16))
	ui.add_notice(root)
func profiles(ui) -> void:
	var root = ui._clear("profiles")
	ui.header(root, tr("PILOTS"), tr("PROFILE_NOTE"))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	for i in range(2):
		var index := i
		var col = ui.card(row, Session.players[i].color)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 16)

		# Encabezado del piloto
		var pilot_header := HBoxContainer.new()
		col.add_child(pilot_header)

		var pilot_title = ui.label(
			"P0%d  /  %s" % [i + 1, tr("PLAYER%d" % (i + 1))],
			16,
			ui.accent
		)
		pilot_header.add_child(pilot_title)

		# Identidad del perfil
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", 12)
		col.add_child(heading)

		var badge := MarbleBadge.new()
		badge.player_index = i
		heading.add_child(badge)

		var name = ui.label(Session.player_name(i), 28)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name)

		# Estadísticas
		var data: Dictionary = Session.profiles[Session.player_name(i)]
		col.add_child(ui.label(tr("PERSONAL_STATS") % [
			data.matches,
			data.wins,
			data.losses,
			data.draws
		], 16))

		var separator := HSeparator.new()
		col.add_child(separator)

		# Selector de perfil
		col.add_child(ui.label(tr("PROFILE_SELECT"), 15, ui.muted))

		var picker := OptionButton.new()
		picker.custom_minimum_size.y = 46
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var names: Array = Session.profiles.keys()
		for profile_name in names:
			picker.add_item(profile_name)
			picker.set_item_disabled(
				picker.item_count - 1,
				profile_name == Session.player_name(1 - i)
			)

		picker.selected = names.find(Session.player_name(i))
		col.add_child(picker)

		picker.item_selected.connect(func(choice):
			if not Session.select_profile(names[choice], index):
				ui.show_error("PROFILE_CONFLICT")
		)

		# Crear perfil
		var input := LineEdit.new()
		input.add_to_group("pilot_profile_names")
		input.set_meta("pilot", i)
		input.placeholder_text = tr("NAME")
		input.max_length = 20
		input.custom_minimum_size.y = 46
		col.add_child(input)

		var create = ui.button(tr("PROFILE_CREATE"), func():
			if not Session.create_profile(input.text, index):
				ui.show_error("NAME_ERROR")
		)
		create.add_to_group("profile_create_buttons")
		create.set_meta("pilot", i)
		col.add_child(create)

	var prefs = ui.card(root)
	ui.language_row(prefs)
	ui.add_notice(root)

## Step 1: marble workshop. Every finish is a live preview tile with the pilot's own colours.
func setup(ui) -> void:
	var root = ui._clear("setup")
	ui.header(root, tr("APPEARANCE"), tr("WORKSHOP_STEP") + "   ·   " + tr("WORKSHOP_NOTE"))
	var world_row := HBoxContainer.new()
	root.add_child(world_row)
	world_row.add_child(ui.label(tr("WORLD"), 17, ui.accent))
	var worlds := OptionButton.new()
	worlds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id in GameCatalog.SCENARIOS:
		worlds.add_item(tr("SCENE_" + id))
	worlds.selected = GameCatalog.SCENARIOS.find(Session.scenario)
	world_row.add_child(worlds)
	worlds.item_selected.connect(func(choice):
		Session.scenario = GameCatalog.SCENARIOS[choice]
		Session.save())
	world_row.add_child(ui.button(tr("SCENARIOS"), func(): ui.show_scenarios("setup")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for i in range(2):
		var index := i
		var col = ui.card(row, Session.players[i].color)
		col.add_theme_constant_override("separation", 8)
		col.add_child(ui.label("%s  /  %s" % [tr("PLAYER%d" % (i + 1)), Session.player_name(i)], 23, ui.accent))
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 18)
		col.add_child(top)
		var badge := MarbleBadge.new()
		badge.player_index = i
		badge.badge_size = 150
		badge.spin = 0.6
		top.add_child(badge)
		var colors := VBoxContainer.new()
		colors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(colors)
		var grid := GridContainer.new()
		for field in ["color", "secondary"]:
			colors.add_child(ui.label(tr("PRIMARY" if field == "color" else "SECONDARY"), 14, ui.muted))
			colors.add_child(_palette(ui, i, field, grid))
		var design_label = ui.label("", 17, ui.accent)
		design_label.set_meta("pilot", i)
		design_label.add_to_group("design_labels")
		col.add_child(design_label)
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		col.add_child(grid)
		for id in GameCatalog.PATTERNS:
			var design: String = id
			var tile := Button.new()
			tile.custom_minimum_size = Vector2(TILE, TILE)
			tile.tooltip_text = tr("PAT_" + id)
			tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			tile.add_to_group("design_tiles")
			tile.set_meta("pilot", i)
			tile.set_meta("design", id)
			var preview := MarbleBadge.new()
			preview.player_index = i
			preview.design = id
			preview.badge_size = TILE - 14
			preview.spin = 0.25
			preview.position = Vector2(7, 7)
			tile.add_child(preview)
			grid.add_child(tile)
			tile.pressed.connect(func():
				Session.players[index].pattern = design
				_click(ui, "ui_select")
				_refresh_tiles(ui, grid, index))
		_refresh_tiles(ui, grid, i)
	var footer := HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(ui.paragraph(tr("WORKSHOP_HINT"), 15))
	var next = ui.button(tr("NEXT_STRATEGY"), ui.show_strategy, true)
	next.add_to_group("workshop_next")
	footer.add_child(next)
	ui.add_notice(root)

func _click(ui, sound: String) -> void:
	if is_instance_valid(ui.host.audio):
		ui.host.audio.play(sound)

func _toggle_style(ui, selected: bool, tint: Color, hover: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = ui.box(ui.panel_color.lightened(0.07) if selected else Color(ui.panel_color, 0.55), tint if selected else Color(ui.muted, 0.22))
	style.set_border_width_all(3 if selected else 1)
	if hover:
		style.border_color = tint.lightened(0.25) if selected else Color(tint, 0.7)
	style.set_content_margin_all(4)
	style.shadow_size = 6 if selected else 2
	style.shadow_color = Color(tint, 0.35) if selected else style.shadow_color
	return style

func _style_toggle(ui, target: Button, selected: bool, tint: Color) -> void:
	target.add_theme_stylebox_override("normal", _toggle_style(ui, selected, tint))
	target.add_theme_stylebox_override("hover", _toggle_style(ui, selected, tint, true))
	target.add_theme_stylebox_override("pressed", _toggle_style(ui, true, tint, true))
	target.add_theme_stylebox_override("focus", _toggle_style(ui, selected, tint, true))
	target.add_theme_stylebox_override("disabled", _toggle_style(ui, selected, Color(tint, 0.4)))

func _refresh_tiles(ui, grid: GridContainer, player: int) -> void:
	for tile in grid.get_children():
		_style_toggle(ui, tile, tile.get_meta("design") == Session.players[player].pattern, Session.players[player].color)
	for design_label in ui.get_tree().get_nodes_in_group("design_labels"):
		if design_label.get_meta("pilot") == player:
			design_label.text = tr("DESIGN_LABEL") % tr("PAT_" + Session.players[player].pattern)

func _palette(ui, player: int, field: String, tiles: GridContainer) -> GridContainer:
	var palette := GridContainer.new()
	palette.columns = 6
	palette.add_theme_constant_override("h_separation", 5)
	for color_index in range(GameCatalog.PALETTE.size()):
		var tint: Color = GameCatalog.PALETTE[color_index]
		var swatch := Button.new()
		swatch.tooltip_text = tr("SWATCH_%d" % color_index)
		swatch.custom_minimum_size = Vector2(36, 30)
		swatch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		swatch.add_to_group(field + "_swatches")
		swatch.set_meta("pilot", player)
		palette.add_child(swatch)
		swatch.pressed.connect(func():
			Session.players[player][field] = tint
			_click(ui, "ui_select")
			_refresh_swatches(ui, palette, player, field)
			_refresh_tiles(ui, tiles, player))
	_refresh_swatches(ui, palette, player, field)
	return palette

func _refresh_swatches(ui, palette: GridContainer, player: int, field: String) -> void:
	for k in range(palette.get_child_count()):
		var swatch: Button = palette.get_child(k)
		var tint: Color = GameCatalog.PALETTE[k]
		var chosen: bool = Session.players[player][field] == tint
		var style: StyleBoxFlat = ui.box(tint.darkened(0.35), tint)
		style.set_content_margin_all(2)
		if chosen:
			style.set_border_width_all(3)
			style.border_color = ui.ink
		swatch.text = "✓" if chosen else ""
		swatch.add_theme_color_override("font_color", Color("0d1520"))
		for state in ["normal", "hover", "pressed", "focus"]:
			swatch.add_theme_stylebox_override(state, style)

## Step 2: race strategy. Powers and items are cards with symbols, energy is a visible meter.
func strategy(ui) -> void:
	strategy_widgets.clear()
	var root = ui._clear("strategy")
	ui.header(root, tr("STRATEGY"), tr("STRATEGY_STEP") + "   ·   " + tr("STRATEGY_NOTE"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for i in range(2):
		var index := i
		var col = ui.card(row, Session.players[i].color)
		col.add_theme_constant_override("separation", 5)
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", 12)
		col.add_child(heading)
		var badge := MarbleBadge.new()
		badge.player_index = i
		badge.badge_size = 42
		heading.add_child(badge)
		heading.add_child(ui.label("%s  /  %s" % [tr("PLAYER%d" % (i + 1)), Session.player_name(i)], 22, ui.accent))
		col.add_child(ui.label(tr("CHOOSE_POWER"), 18, ui.accent))
		var powers := HBoxContainer.new()
		powers.add_theme_constant_override("separation", 6)
		col.add_child(powers)
		var power_cards := {}
		for id in Session.POWER_IDS:
			var power: String = id
			var choice := _choice_card(ui, power, POWER_TINT, tr(power + "_SHORT"), 0, 58.0)
			choice.add_to_group("power_cards")
			choice.set_meta("pilot", i)
			choice.set_meta("id", power)
			powers.add_child(choice)
			power_cards[power] = choice
			choice.pressed.connect(func():
				Session.players[index].power = power
				strategy_widgets[index].detail.text = tr(power + "_DESC")
				_click(ui, "ui_select")
				refresh_strategy(ui))
		col.add_child(ui.label(tr("CHOOSE_ITEMS"), 18, ui.accent))
		var slots := HBoxContainer.new()
		slots.add_theme_constant_override("separation", 6)
		col.add_child(slots)
		var slot_views: Array = []
		for slot in range(3):
			slot_views.append(_slot_view(ui, slots, slot))
		var meter_row := HBoxContainer.new()
		meter_row.add_theme_constant_override("separation", 10)
		col.add_child(meter_row)
		var meter := EnergyMeter.new()
		meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meter_row.add_child(meter)
		var energy = ui.label("", 16)
		meter_row.add_child(energy)
		var item_cards := {}
		for category in ["EQUIPMENT", "TRAPS"]:
			var tint := Color("64efba") if category == "EQUIPMENT" else Color("ff829c")
			col.add_child(ui.label(tr(category).to_upper() + "   ·   " + tr("CATEGORY_" + category), 14, tint.darkened(0.4) if Session.light else tint))
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 5)
			col.add_child(grid)
			for id in Session.ITEM_IDS:
				if GameCatalog.ITEMS[id].category != category:
					continue
				var item: String = id
				var choice := _choice_card(ui, item, GameCatalog.ITEMS[item].color, tr(item + "_SHORT"), GameCatalog.ITEMS[item].cost)
				choice.add_to_group("loadout_cards")
				choice.set_meta("pilot", i)
				choice.set_meta("id", item)
				grid.add_child(choice)
				item_cards[item] = choice
				choice.pressed.connect(func():
					strategy_widgets[index].detail.text = tr(item + "_DESC")
					toggle_item(ui, index, item))
		var detail = ui.paragraph(tr("TAP_TO_REMOVE"), 14)
		detail.custom_minimum_size.y = 34
		col.add_child(detail)
		strategy_widgets.append({"powers": power_cards, "items": item_cards, "slots": slot_views, "meter": meter, "energy": energy, "detail": detail})
	var footer := HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(ui.button(tr("BACK_WORKSHOP"), ui.show_setup))
	footer.add_child(ui.button(tr("GUIDE"), func(): ui.show_guide("strategy")))
	var seed_input := LineEdit.new()
	seed_input.placeholder_text = tr("SEED")
	seed_input.text = ui.selected_seed
	seed_input.max_length = 10
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_input.text_changed.connect(func(value): ui.selected_seed = value.strip_edges())
	footer.add_child(seed_input)
	start_button = ui.button(tr("START"), func():
		var raw: String = ui.selected_seed
		if raw != "" and (not raw.is_valid_int() or int(raw) < 1 or int(raw) > 2147483646):
			ui.show_error("SEED_ERROR")
			return
		ui.host.start_race(int(raw) if raw != "" else randi_range(1, 2147483646)), true)
	footer.add_child(start_button)
	ui.add_notice(root)
	refresh_strategy(ui)

func _choice_card(ui, kind: String, tint: Color, subtitle: String, cost: int = 0, height: float = 52.0) -> Button:
	var choice := Button.new()
	choice.custom_minimum_size = Vector2(0, height)
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	choice.tooltip_text = tr(kind + "_DESC")
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 8
	layout.offset_right = -8
	layout.add_theme_constant_override("separation", 9)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice.add_child(layout)
	var icon := ItemIcon.new()
	icon.kind = kind
	icon.tint = tint.darkened(0.3) if Session.light else tint
	icon.icon_size = height - 16
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	layout.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(text)
	var title = ui.label(tr(kind) + ("   " + "●".repeat(cost) if cost > 0 else ""), 15)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(title)
	var note = ui.label(subtitle, 12, ui.muted)
	note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(note)
	var order = ui.label("", 22, ui.accent)
	order.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	order.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(order)
	choice.set_meta("icon", icon)
	choice.set_meta("order", order)
	return choice

func _slot_view(ui, parent: Node, slot: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	panel.add_child(layout)
	layout.add_child(ui.label(str(slot + 1), 22, ui.muted))
	var icon := ItemIcon.new()
	icon.icon_size = 34
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	layout.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(text)
	var name = ui.label("", 14)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(name)
	var target = ui.label("", 12)
	text.add_child(target)
	return {"panel": panel, "icon": icon, "name": name, "target": target}

## Click a card to add it to the next free slot, click a chosen card to remove it.
func toggle_item(ui, player: int, id: String) -> bool:
	var items: Array = Session.players[player].items
	if id in items:
		items.erase(id)
	elif items.size() >= 3:
		ui.show_error("SLOTS_FULL")
		_click(ui, "invalid")
		refresh_strategy(ui)
		return false
	elif GameCatalog.loadout_cost(items) + int(GameCatalog.ITEMS[id].cost) > GameCatalog.BUDGET:
		ui.show_error("NO_ENERGY_ERROR")
		_click(ui, "invalid")
		refresh_strategy(ui)
		return false
	else:
		items.append(id)
	_click(ui, "ui_select")
	refresh_strategy(ui)
	return true

func refresh_strategy(ui) -> void:
	var valid := true
	for i in range(mini(2, strategy_widgets.size())):
		var widgets: Dictionary = strategy_widgets[i]
		var player: Dictionary = Session.players[i]
		var tint: Color = player.color
		for id in widgets.powers:
			_style_toggle(ui, widgets.powers[id], player.power == id, tint)
		var items: Array = player.items
		var spent := GameCatalog.loadout_cost(items)
		for id in widgets.items:
			var choice: Button = widgets.items[id]
			var chosen: bool = id in items
			var affordable: bool = chosen or (items.size() < 3 and spent + int(GameCatalog.ITEMS[id].cost) <= GameCatalog.BUDGET)
			_style_toggle(ui, choice, chosen, tint)
			choice.modulate.a = 1.0 if affordable else 0.45
			(choice.get_meta("icon") as ItemIcon).dimmed = not affordable
			(choice.get_meta("order") as Label).text = str(items.find(id) + 1) if chosen else ""
			choice.tooltip_text = tr(id + "_DESC") + ("" if affordable else "\n" + tr("SLOTS_FULL" if items.size() >= 3 else "NO_ENERGY_ERROR"))
		for slot in range(3):
			var view: Dictionary = widgets.slots[slot]
			var filled := slot < items.size()
			var id: String = items[slot] if filled else ""
			var item_tint: Color = GameCatalog.ITEMS[id].color if filled else ui.muted
			view.panel.add_theme_stylebox_override("panel", _toggle_style(ui, filled, item_tint))
			view.icon.kind = id
			view.icon.tint = item_tint.darkened(0.3) if Session.light else item_tint
			view.icon.dimmed = not filled
			view.name.text = tr(id) if filled else tr("SLOT_EMPTY")
			var trap := filled and GameCatalog.is_trap(id)
			view.target.text = (tr("FOR_RIVAL") if trap else tr("FOR_SELF")) if filled else ""
			view.target.add_theme_color_override("font_color", Color("ff829c") if trap else Color("64efba"))
		var legal := GameCatalog.valid_loadout(items)
		valid = valid and legal
		widgets.meter.set_spent(spent)
		widgets.energy.text = tr("ENERGY_LEFT") % spent + ("" if items.size() == 3 else "   ·   " + tr("NEED_MORE") % (3 - items.size()))
		widgets.energy.add_theme_color_override("font_color", ui.ink if legal else Color("d35172"))
	if is_instance_valid(start_button):
		start_button.disabled = not valid
	if valid and is_instance_valid(ui.notice) and ui.notice.text in [tr("LOADOUT_ERROR"), tr("SLOTS_FULL"), tr("NO_ENERGY_ERROR")]:
		ui.notice.text = ""

func gallery(ui) -> void:
	var root = ui._clear("scenarios")
	ui.header(root, tr("SCENARIOS"), tr("SCENARIOS_NOTE"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for id in GameCatalog.SCENARIOS:
		var chosen: String = id
		var col = ui.card(grid, GameCatalog.WORLD_COLORS[id][1] if Session.scenario == id else Color.TRANSPARENT)
		var art := ScenarioThumbnail.new()
		art.scenario_id = id
		col.add_child(art)
		var title = ui.paragraph(tr("SCENE_" + id), 19)
		title.add_theme_color_override("font_color", ui.ink)
		col.add_child(title)
		var description = ui.paragraph(tr("SCENE_" + id + "_DESC"), 14)
		description.custom_minimum_size.y = 42
		col.add_child(description)
		col.add_child(ui.button(tr("SELECTED") if id == Session.scenario else tr("SELECT_WORLD"), func():
			Session.scenario = chosen
			Session.save()
			ui.show_scenarios(ui.scene_return), id == Session.scenario))
	root.add_child(ui.label(tr("SCENE_" + Session.scenario) + "    /    " + tr("BACK"), 16, ui.accent))

func guide(ui) -> void:
	var root = ui._clear("guide")
	ui.header(root, tr("LIBRARY"), tr("GUIDE_NOTE"))
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	for category in ["EQUIPMENT", "TRAPS", "POWERS"]:
		var chosen: String = category
		tabs.add_child(ui.button(tr(category), func():
			ui.guide_category = chosen
			ui.show_guide(ui.guide_return), ui.guide_category == category))
	root.add_child(ui.paragraph(tr("CATEGORY_" + ui.guide_category), 18))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var entries: Array = Session.POWER_IDS if ui.guide_category == "POWERS" else Session.ITEM_IDS
	for id in entries:
		if ui.guide_category != "POWERS" and GameCatalog.ITEMS[id].category != ui.guide_category:
			continue
		var tint: Color = GameCatalog.ITEMS[id].color if GameCatalog.ITEMS.has(id) else ui.accent
		var col = ui.card(grid, tint)
		col.custom_minimum_size = Vector2(500, 130)
		col.add_child(ui.label(tr(id), 24, tint.darkened(0.45) if Session.light else tint))
		if GameCatalog.ITEMS.has(id):
			col.add_child(ui.label(tr("COST") % GameCatalog.ITEMS[id].cost, 17))
		col.add_child(ui.paragraph(tr(id + "_DESC"), 18))
	root.add_child(ui.paragraph(tr("BALANCE_NOTE"), 15))
