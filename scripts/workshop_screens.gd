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

