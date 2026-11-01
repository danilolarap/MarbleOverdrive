class_name WorkshopScreens
extends RefCounted
var budget_labels: Array[Label] = []
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
	root.add_child(row)
	for i in range(2):
		var index := i
		var col = ui.card(row, Session.players[i].color)
		col.add_child(ui.label(tr("PLAYER%d" % (i + 1)), 20, ui.accent))
		var heading := HBoxContainer.new()
		col.add_child(heading)
		var badge := MarbleBadge.new()
		badge.player_index = i
		heading.add_child(badge)
		var name = ui.label(Session.player_name(i), 30)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name)
		var data: Dictionary = Session.profiles[Session.player_name(i)]
		col.add_child(ui.paragraph(tr("PERSONAL_STATS") % [data.matches, data.wins, data.losses, data.draws], 17))
		col.add_child(ui.label(tr("PROFILE_SELECT"), 16, ui.muted))
		var picker := OptionButton.new()
		var names: Array = Session.profiles.keys()
		for profile_name in names:
			picker.add_item(profile_name)
			picker.set_item_disabled(picker.item_count - 1, profile_name == Session.player_name(1 - i))
		picker.selected = names.find(Session.player_name(i))
		col.add_child(picker)
		picker.item_selected.connect(func(choice):
			if not Session.select_profile(names[choice], index):
				ui.show_error("PROFILE_CONFLICT"))
		var input := LineEdit.new()
		input.add_to_group("pilot_profile_names")
		input.set_meta("pilot", i)
		input.placeholder_text = tr("NAME")
		input.max_length = 20
		col.add_child(input)
		var create = ui.button(tr("PROFILE_CREATE"), func():
			if not Session.create_profile(input.text, index):
				ui.show_error("NAME_ERROR"))
		create.add_to_group("profile_create_buttons")
		create.set_meta("pilot", i)
		col.add_child(create)
	var prefs = ui.card(root)
	ui.language_row(prefs)
	ui.add_notice(root)

func setup(ui) -> void:
	budget_labels.clear()
	var root = ui._clear("setup")
	ui.header(root, tr("SETUP"), tr("SETUP_NOTE"))
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
	world_row.add_child(ui.button(tr("GUIDE"), func(): ui.show_guide("setup")))
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
		col.add_child(ui.label("%s  /  %s" % [tr("PLAYER%d" % (i + 1)), Session.player_name(i)], 23, ui.accent))
		var tabs := TabContainer.new()
		tabs.add_to_group("pilot_workshop_tabs")
		tabs.use_hidden_tabs_for_min_size = false
		tabs.add_theme_stylebox_override("panel", ui.box(Color(ui.panel_color, 0.4)))
		tabs.add_theme_stylebox_override("tab_selected", ui.box(ui.panel_color.lightened(0.05), ui.accent))
		tabs.add_theme_stylebox_override("tab_unselected", ui.box(ui.panel_color.darkened(0.06), Color(ui.muted, 0.2)))
		tabs.add_theme_color_override("font_selected_color", ui.accent)
		tabs.add_theme_color_override("font_unselected_color", ui.muted)
		tabs.add_theme_font_size_override("font_size", 16)
		col.add_child(tabs)
		var appearance := VBoxContainer.new()
		appearance.name = tr("APPEARANCE")
		tabs.add_child(appearance)
		var strategy := VBoxContainer.new()
		strategy.add_theme_constant_override("separation", 6)
		strategy.name = tr("STRATEGY")
		tabs.add_child(strategy)
		col = appearance
		var paint := HBoxContainer.new()
		col.add_child(paint)
		var badge := MarbleBadge.new()
		badge.player_index = i
		paint.add_child(badge)
		var paint_options := VBoxContainer.new()
		paint_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		paint.add_child(paint_options)
		paint_options.add_child(ui.label(tr("PRIMARY"), 14, ui.muted))
		var palette := GridContainer.new()
		palette.columns = 6
		paint_options.add_child(palette)
		for color_index in range(GameCatalog.PALETTE.size()):
			var tint: Color = GameCatalog.PALETTE[color_index]
			var chosen := tint
			var swatch := Button.new()
			swatch.text = "●" if Session.players[i].color == tint else ""
			swatch.tooltip_text = tr("SWATCH_%d" % color_index)
			swatch.custom_minimum_size = Vector2(40, 34)
			swatch.add_theme_stylebox_override("normal", ui.box(tint.darkened(0.45), tint))
			palette.add_child(swatch)
			swatch.pressed.connect(func():
				Session.players[index].color = chosen
				for other in palette.get_children():
					other.text = ""
				swatch.text = "●")
		var finishing := HBoxContainer.new()
		col.add_child(finishing)
		var pattern := OptionButton.new()
		pattern.add_to_group("pattern_selectors")
		pattern.set_meta("pilot", i)
		pattern.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for id in GameCatalog.PATTERNS:
			pattern.add_item(tr("PAT_" + id))
		pattern.selected = GameCatalog.PATTERNS.find(Session.players[i].pattern)
		finishing.add_child(pattern)
		pattern.item_selected.connect(func(choice): Session.players[index].pattern = GameCatalog.PATTERNS[choice])
		var secondary := OptionButton.new()
		secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for color_index in range(GameCatalog.PALETTE.size()):
			secondary.add_item(tr("SECONDARY") + ": " + tr("SWATCH_%d" % color_index))
		secondary.selected = maxi(0, GameCatalog.PALETTE.find(Session.players[i].secondary))
		finishing.add_child(secondary)
		secondary.item_selected.connect(func(choice): Session.players[index].secondary = GameCatalog.PALETTE[choice])
		col = strategy
		col.add_child(ui.label(tr("POWERS"), 20, ui.accent))
		var power := OptionButton.new()
		for id in Session.POWER_IDS:
			power.add_item(tr(id))
		power.selected = Session.POWER_IDS.find(Session.players[i].power)
		col.add_child(power)
		var power_desc = ui.paragraph(tr(Session.players[i].power + "_DESC"), 15)
		col.add_child(power_desc)
		power.item_selected.connect(func(choice):
			Session.players[index].power = Session.POWER_IDS[choice]
			power_desc.text = tr(Session.POWER_IDS[choice] + "_DESC"))
		var budget = ui.label("", 17)
		col.add_child(budget)
		budget_labels.append(budget)
		for slot in range(3):
			item_selector(ui, col, i, slot)
	var footer := HBoxContainer.new()
	root.add_child(footer)
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
	refresh_budgets(ui)

func item_selector(ui, parent: Node, player: int, slot: int) -> void:
	var picker := OptionButton.new()
	picker.add_to_group("loadout_pickers")
	picker.set_meta("pilot", player)
	picker.set_meta("slot", slot)
	for category in ["EQUIPMENT", "TRAPS"]:
		picker.add_separator(tr(category))
		for id in Session.ITEM_IDS:
			if GameCatalog.ITEMS[id].category != category:
				continue
			picker.add_item("%02d   %s   /   %d" % [slot + 1, tr(id), GameCatalog.ITEMS[id].cost])
			picker.set_item_metadata(picker.item_count - 1, id)
			if id == Session.players[player].items[slot]:
				picker.selected = picker.item_count - 1
	parent.add_child(picker)
	var description = ui.paragraph(tr(Session.players[player].items[slot] + "_SHORT"), 14)
	description.tooltip_text = tr(Session.players[player].items[slot] + "_DESC")
	parent.add_child(description)
	picker.item_selected.connect(func(choice):
		var chosen: String = picker.get_item_metadata(choice)
		var previous: String = Session.players[player].items[slot]
		if chosen != previous and chosen in Session.players[player].items:
			for option in range(picker.item_count):
				if picker.get_item_metadata(option) == previous:
					picker.selected = option
			ui.show_error("DUPLICATE_ITEM")
			return
		Session.players[player].items[slot] = chosen
		description.text = tr(chosen + "_SHORT")
		description.tooltip_text = tr(chosen + "_DESC")
		refresh_budgets(ui))

func refresh_budgets(ui) -> void:
	var valid := true
	for i in range(2):
		var legal := GameCatalog.valid_loadout(Session.players[i].items)
		valid = valid and legal
		if i < budget_labels.size() and is_instance_valid(budget_labels[i]):
			budget_labels[i].text = tr("BUDGET") % GameCatalog.loadout_cost(Session.players[i].items)
			budget_labels[i].add_theme_color_override("font_color", ui.accent if legal else Color("d35172"))
	if is_instance_valid(start_button):
		start_button.disabled = not valid
	if not valid:
		ui.show_error("LOADOUT_ERROR")
	elif is_instance_valid(ui.notice) and ui.notice.text in [tr("LOADOUT_ERROR"), tr("DUPLICATE_ITEM")]:
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
