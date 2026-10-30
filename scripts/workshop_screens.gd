class_name WorkshopScreens
extends RefCounted
var budget_labels: Array[Label] = []
var start_button: Button

func menu(ui) -> void:
	var root = ui._clear("menu")
	var bar := HBoxContainer.new()
	root.add_child(bar)
	var brand = ui.label("M / O    //    SHARED TRACK DUEL", 18, ui.accent)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(brand)
	bar.add_child(ui.label(tr("PAIR") % [Session.player_name(0), Session.player_name(1)], 18))
	ui.spacer(root)
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 30)
	root.add_child(hero)
	var launch := VBoxContainer.new()
	launch.custom_minimum_size.x = 390
	hero.add_child(launch)
	launch.add_child(ui.label("MARBLE", 60))
	launch.add_child(ui.label("OVERDRIVE", 60, ui.accent))
	launch.add_child(ui.paragraph(tr("TAGLINE"), 17))
	launch.add_child(ui.button(tr("PLAY"), ui.show_setup, true))
	launch.add_child(ui.button(tr("PROFILE"), ui.show_profiles))
	var discovery := HBoxContainer.new()
	launch.add_child(discovery)
	for entry in [["SCENARIOS", ui.show_scenarios], ["GUIDE", ui.show_guide]]:
		var btn = ui.button(tr(entry[0]), entry[1])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		discovery.add_child(btn)
	var utility := HBoxContainer.new()
	launch.add_child(utility)
	for entry in [["SETTINGS", ui.show_settings], ["CONTROLS", ui.show_controls]]:
		var btn = ui.button(tr(entry[0]), entry[1])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		utility.add_child(btn)
	launch.add_child(ui.button(tr("QUIT"), func(): ui.get_tree().quit()))
	var showcase = ui.card(hero)
	showcase.add_child(ui.label(tr("SCENE_" + Session.scenario), 28))
	showcase.add_child(ui.paragraph(tr("SCENE_" + Session.scenario + "_DESC"), 16))
	var preview := SubViewportContainer.new()
	preview.set_script(preload("res://scripts/menu_preview.gd"))
	preview.custom_minimum_size = Vector2(550, 280)
	showcase.add_child(preview)
	showcase.add_child(ui.paragraph(tr("HOW_BODY"), 17))
	ui.spacer(root)
	root.add_child(ui.label(tr("EDITION_BADGE"), 14, ui.muted))
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

