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

