extends Control

var host: Node
var screen := "menu"
var content: Control
var ink := Color.WHITE
var muted := Color("8fa8c0")
var accent := Color("34e4ef")
var panel_color := Color("101e30")
var rebinding := ""
var binding_button: Button
var notice: Label
var notice_until := 0
var hud_labels: Array[Dictionary] = []
var phase_label: Label
var countdown_label: Label
var hint_label: Label
var footer_label: Label
var pause_overlay: Control
var result_data := {}
var selected_seed := ""
var placement_ui := false
var placement_map: TacticalMap
var workshop := WorkshopScreens.new()
var scene_return := "menu"
var guide_return := "menu"
var guide_category := "EQUIPMENT"

func show_scenarios(origin: String = "menu") -> void:
	scene_return = origin
	workshop.gallery(self)

func show_guide(origin: String = "menu") -> void:
	guide_return = origin
	workshop.guide(self)

func _draw() -> void:
	if screen == "hud" and placement_ui:
		draw_rect(Rect2(Vector2.ZERO, size), Color("edf2f6") if Session.light else Color("091523"))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Session.preferences_changed.connect(_preferences_changed)
	apply_theme()
	show_menu()

func apply_theme() -> void:
	ink = Color("122d43") if Session.light else Color("eaf5ff")
	muted = Color("48657a") if Session.light else Color("91abc4")
	accent = Color("087d91") if Session.light else Color("34e4ef")
	panel_color = Color("ffffff") if Session.light else Color("101e30")
	var design := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "DejaVu Sans"])
	design.default_font = font
	design.default_font_size = 18
	for type in ["Label", "Button", "CheckButton", "LineEdit", "OptionButton", "PopupMenu"]:
		design.set_color("font_color", type, ink)
		design.set_color("font_hover_color", type, ink)
		design.set_color("font_pressed_color", type, accent)
	design.set_color("font_placeholder_color", "LineEdit", muted)
	for type in ["Button", "OptionButton", "LineEdit"]:
		design.set_stylebox("normal", type, box(panel_color, Color(muted, 0.3)))
		design.set_stylebox("hover", type, box(panel_color.lightened(0.08), accent))
		design.set_stylebox("pressed", type, box(panel_color, accent))
		design.set_stylebox("focus", type, box(Color(0, 0, 0, 0), accent))
	design.set_stylebox("panel", "PopupMenu", box(panel_color, muted))
	design.set_constant("separation", "VBoxContainer", 14)
	design.set_constant("separation", "HBoxContainer", 20)
	theme = design

func box(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = border
	style.shadow_color = Color(0.01, 0.03, 0.07, 0.13 if Session.light else 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	style.border_width_bottom = 2
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func label(text: String, font_size: int = 18, color: Color = Color.TRANSPARENT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", ink if color == Color.TRANSPARENT else color)
	return result

func paragraph(text: String, font_size: int = 18) -> Label:
	var result := label(text, font_size, muted)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var result := Button.new()
	result.set_script(preload("res://scripts/arcade_button.gd"))
	result.text = text
	result.custom_minimum_size.y = 48
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		result.add_theme_stylebox_override("normal", box(accent, accent))
		result.add_theme_stylebox_override("hover", box(accent.lightened(0.15), ink))
		result.add_theme_color_override("font_color", Color("071925") if not Session.light else Color.WHITE)
		result.add_theme_color_override("font_hover_color", Color("071925") if not Session.light else Color.WHITE)
	result.pressed.connect(func():
		host.audio.tone(500, 0.045)
		callback.call())
	return result

func card(parent: Node, color: Color = Color.TRANSPARENT) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_script(preload("res://scripts/arcade_panel.gd"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", box(panel_color, Color(muted, 0.25) if color == Color.TRANSPARENT else color))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	return column

func _clear(next_screen: String) -> VBoxContainer:
	screen = next_screen
	placement_map = null
	queue_redraw()
	rebinding = ""
	if is_instance_valid(pause_overlay):
		remove_child(pause_overlay)
		pause_overlay.queue_free()
	pause_overlay = null
	hud_labels.clear()
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 30)
	add_child(content)
	var root := VBoxContainer.new()
	content.add_child(root)
	return root

func header(root: VBoxContainer, title: String, subtitle: String = "") -> void:
	root.add_child(label("M / O     //     " + tr("LOCAL"), 12, accent))
	var line := HBoxContainer.new()
	root.add_child(line)
	var title_label := label(title, 34)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(title_label)
	if screen != "menu":
		line.add_child(button(tr("BACK"), _back))
	if subtitle != "":
		root.add_child(paragraph(subtitle))

func spacer(parent: Node) -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(space)

func add_notice(parent: Node) -> void:
	notice = label("", 16, Color("de647c") if Session.light else Color("ff91a4"))
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(notice)
	if Session.save_failed:
		notice.text = tr("SAVE_ERROR")

func show_error(message: String) -> void:
	if is_instance_valid(notice):
		notice.text = tr(message)
		notice_until = Time.get_ticks_msec() + 3500

func show_menu() -> void:
	host.clear_race()
	Session.save()
	workshop.menu(self)

func show_setup() -> void:
	workshop.setup(self)

func show_profiles() -> void:
	workshop.profiles(self)

func language_row(parent: Node) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.add_child(label(tr("LANGUAGE")))
	var picker := OptionButton.new()
	picker.add_item("English")
	picker.add_item("Español")
	picker.selected = 1 if Session.language == "es" else 0
	row.add_child(picker)
	picker.item_selected.connect(func(index):
		Session.language = "es" if index == 1 else "en"
		Session.update_preferences())

func show_settings() -> void:
	var root := _clear("settings")
	header(root, tr("SETTINGS"))
	var col := card(root)
	col.add_child(paragraph(tr("FULLSCREEN_HELP"), 17))
	language_row(col)
	var theme_picker := OptionButton.new()
	theme_picker.add_item(tr("DARK"))
	theme_picker.add_item(tr("LIGHT"))
	theme_picker.selected = 1 if Session.light else 0
	var row := HBoxContainer.new()
	col.add_child(row)
	row.add_child(label(tr("THEME")))
	row.add_child(theme_picker)
	theme_picker.item_selected.connect(func(index):
		Session.light = index == 1
		Session.update_preferences())
	for setting in ["fullscreen", "sound"]:
		var setting_id: String = setting
		var toggle := CheckButton.new()
		toggle.text = tr(setting.to_upper())
		toggle.button_pressed = Session.get(setting)
		col.add_child(toggle)
		toggle.toggled.connect(func(value):
			Session.set(setting_id, value)
			Session.update_preferences())
	col.add_child(label(tr("BINDINGS"), 24))
	col.add_child(paragraph(tr("REBIND"), 16))
	var keys_row := HBoxContainer.new()
	col.add_child(keys_row)
	for i in range(2):
		var key_col := VBoxContainer.new()
		key_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		keys_row.add_child(key_col)
		key_col.add_child(label(Session.player_name(i)))
		for action_type in ["power", "brake"]:
			var action := "p%d_%s" % [i + 1, action_type]
			var bind := button(tr(action_type.to_upper()) + "   [ " + Session.key_label(action) + " ]", func(): pass)
			bind.pressed.connect(func():
				rebinding = action
				binding_button = bind
				bind.text = tr("PRESS_KEY"))
			key_col.add_child(bind)
	col.add_child(button(tr("RESET_KEYS"), func():
		Session.keys = Session.DEFAULT_KEYS.duplicate()
		Session.apply_keys()
		Session.save()
		show_settings()))
	add_notice(root)

func show_controls() -> void:
	var root := _clear("controls")
	header(root, tr("CONTROLS"), tr("CONTROLS_SUMMARY"))
	var row := HBoxContainer.new()
	root.add_child(row)
	for i in range(2):
		var col := card(row)
		col.add_child(label(Session.player_name(i), 24, Session.players[i].color.darkened(0.45) if Session.light else Session.players[i].color))
		var diagram := KeyboardDiagram.new()
		diagram.player_index = i
		diagram.mode = "both"
		col.add_child(diagram)
	var help := card(root)
	help.add_child(label(tr("TACTICAL_MAP"), 23))
	help.add_child(paragraph(tr("MAP_HELP"), 18))
	help.add_child(paragraph(tr("GLOBAL_KEYS"), 17))

func show_placement() -> void:
	placement_ui = true
	var root := _clear("hud")
	var top := HBoxContainer.new()
	root.add_child(top)
	phase_label = label(tr("PLACEMENT"), 30, accent)
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(phase_label)
	top.add_child(label(tr("TIME_TO_PLACE"), 17, muted))
	countdown_label = label("30.0", 42)
	top.add_child(countdown_label)
	hint_label = paragraph(tr("PLACEMENT_STEPS"), 17)
	root.add_child(hint_label)
	var map_col := card(root)
	map_col.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_col.add_child(label(tr("TACTICAL_MAP"), 18, muted))
	placement_map = TacticalMap.new()
	placement_map.race = host.race
	placement_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_col.add_child(placement_map)
	var row := HBoxContainer.new()
	root.add_child(row)
	for i in range(2):
		var col := card(row)
		col.add_theme_constant_override("separation", 6)
		var heading := HBoxContainer.new()
		col.add_child(heading)
		var title := label(Session.player_name(i), 22, Session.players[i].color.darkened(0.45) if Session.light else Session.players[i].color)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		var counter := label("0 / 3", 22)
		heading.add_child(counter)
		var next_item := label("", 20)
		col.add_child(next_item)
		var status := paragraph("", 15)
		col.add_child(status)
		var diagram := KeyboardDiagram.new()
		diagram.player_index = i
		col.add_child(diagram)
		hud_labels.append({"speed": counter, "status": status, "actions": next_item})
	footer_label = paragraph("", 14)
	root.add_child(footer_label)
	add_notice(root)
func show_hud() -> void:
	if is_instance_valid(host.race) and host.race.phase == "placement":
		show_placement()
		return
	placement_ui = false
	var root := _clear("hud")
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	root.add_child(row)
	var action_labels: Array[Label] = []
	for i in range(2):
		var col := card(row, Session.players[i].color)
		var panel := col.get_parent() as PanelContainer
		panel.add_theme_stylebox_override("panel", box(Color(panel_color, 0.96 if Session.light else 0.9), Color(Session.players[i].color, 0.7)))
		col.add_theme_constant_override("separation", 5)
		col.add_child(label(Session.player_name(i), 16, Session.players[i].color.darkened(0.35) if Session.light else Session.players[i].color))
		var speed := label("", 45)
		col.add_child(speed)
		var health := ProgressBar.new()
		health.show_percentage = false
		health.max_value = 100
		health.custom_minimum_size.y = 6
		health.add_theme_stylebox_override("background", box(Color(muted, 0.15)))
		health.add_theme_stylebox_override("fill", box(Session.players[i].color))
		col.add_child(health)
		var status := label("", 15, muted)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(status)
		var actions := label("", 20)
		actions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_labels.append(actions)
		hud_labels.append({"speed": speed, "health": health, "status": status, "actions": actions})
		if i == 0:
			var middle := VBoxContainer.new()
			middle.custom_minimum_size.x = 290
			row.add_child(middle)
			var brand := label("MARBLE / OVERDRIVE", 23, accent)
			brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			middle.add_child(brand)
			phase_label = label(tr("PLACEMENT"), 17, accent)
			phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			middle.add_child(phase_label)
			countdown_label = label("5.0", 30)
			countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			middle.add_child(countdown_label)
	spacer(root)
	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	for i in range(2):
		var action_card := card(bottom, Session.players[i].color)
		var panel := action_card.get_parent() as PanelContainer
		panel.custom_minimum_size.x = 350
		panel.add_theme_stylebox_override("panel", box(Color(panel_color, 0.96 if Session.light else 0.9), Color(Session.players[i].color, 0.6)))
		action_card.add_child(action_labels[i])
		if i == 0:
			var center := card(bottom)
			center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			center.custom_minimum_size.x = 280
			hint_label = paragraph("", 15)
			center.add_child(hint_label)
			footer_label = paragraph("", 14)
			center.add_child(footer_label)
			add_notice(center)
func _process(_delta: float) -> void:
	if is_instance_valid(notice) and notice_until > 0 and Time.get_ticks_msec() > notice_until:
		notice.text = ""
		notice_until = 0
	if screen != "hud" or not is_instance_valid(host.race):
		return
	var race: DuelRace = host.race
	if race.marbles.size() < 2:
		return
	var placing := race.phase == "placement"
	if placing != placement_ui:
		show_hud()
		return
	phase_label.text = tr("PLACEMENT") if placing else tr("RACE")
	countdown_label.text = "%.1f" % maxf(0, race.placement_time) if placing else "%05.1f" % race.race_time
	hint_label.text = tr("PLACEMENT_STEPS") if placing else tr("RACE_TIP")
	footer_label.text = tr("MAP_HELP_SHORT") if placing else "Esc · " + tr("PAUSED") + "     /     F11 · " + tr("FULLSCREEN")
	footer_label.text += "\n" + tr("SEED_LABEL") % race.track.seed_value
	for i in range(2):
		var marble := race.marbles[i]
		var data: Dictionary = hud_labels[i]
		if data.has("health"):
			data.health.value = marble.health
		if placing:
			data.speed.text = "%d / 3" % race.placed[i]
			var allowed := race.can_place(race.cursor_location(i), i)
			data.status.text = tr("EMPTY") if race.placed[i] >= 3 else tr("MAP_ALLOWED") if allowed else tr("MAP_REJECTED")
			data.status.add_theme_color_override("font_color", Color("166342") if Session.light else Color("88efb6") if allowed else Color("ff8da2"))
			if not allowed:
				data.status.add_theme_color_override("font_color", Color("a22340") if Session.light else Color("ff8da2"))
			var target := race.next_target(i)
			data.actions.text = (tr("NEXT") % [tr(race.next_item(i)), 3 - race.placed[i]] if race.placed[i] < 3 else tr("EMPTY")) + "\n" + tr("TARGET_SELF" if target == i else "TARGET_RIVAL") % Session.player_name(target)
		else:
			data.speed.text = "%03d  km/h" % roundi(marble.linear_velocity.length() * 3.6)
			var rank := 1 if marble.progress >= race.marbles[1 - i].progress else 2
			data.status.text = "%s %d/100   ·   %s %d/2   ·   %d%%" % [tr("HEALTH"), ceili(marble.health), tr("POSITION"), rank, int(marble.progress / race.track.total_length * 100)]
			if marble.shield_points > 0:
				data.status.text += " · " + tr("ACTIVE_SHIELD") % int(marble.shield_points)
			if marble.grip_time > 0:
				data.status.text += " · " + tr("ACTIVE_GRIP")
			data.actions.text = "%s [%s]  %s\n%s [%s]  %s" % [tr(marble.power_id), Session.key_label("p%d_power" % (i + 1)), tr("READY") if marble.power_cooldown <= 0 else "%.1fs" % marble.power_cooldown, tr("BRAKE"), Session.key_label("p%d_brake" % (i + 1)), tr("BRAKING") if marble.braking else tr("HOLD_KEY")]

func show_results(winner: int, reason: String, race_time: float) -> void:
	result_data = {"winner": winner, "reason": reason, "time": race_time}
	var root := _clear("results")
	spacer(root)
	var color: Color = Session.players[winner].color if winner >= 0 else accent
	var result_card := card(root, color)
	result_card.add_child(label("M / O    //    " + tr("RESULTS"), 18, accent))
	var headline := HBoxContainer.new()
	result_card.add_child(headline)
	if winner >= 0:
		var badge := MarbleBadge.new()
		badge.player_index = winner
		headline.add_child(badge)
	var title := paragraph(tr("NAMED_WINNER") % Session.player_name(winner) if winner >= 0 else tr("DRAW"), 48)
	title.add_theme_color_override("font_color", color.darkened(0.4) if Session.light else color)
	headline.add_child(title)
	result_card.add_child(label(tr(reason), 26))
	result_card.add_child(label(tr("TIME") % race_time, 22, muted))
	result_card.add_child(label(tr("SCENE_" + Session.scenario) + "  /  " + tr("SEED_LABEL") % host.race.track.seed_value, 17, muted))
	var pilots := HBoxContainer.new()
	result_card.add_child(pilots)
	for i in range(2):
		var stats: Dictionary = Session.profiles[Session.player_name(i)]
		var col := card(pilots)
		col.add_child(label(Session.player_name(i), 23, accent))
		col.add_child(paragraph(tr("PERSONAL_STATS") % [stats.matches, stats.wins, stats.losses, stats.draws], 17))
	var actions := HBoxContainer.new()
	result_card.add_child(actions)
	actions.add_child(button(tr("REMATCH"), func(): host.start_race(randi_range(1, 2147483646)), true))
	actions.add_child(button(tr("SETUP"), func():
		host.clear_race()
		show_setup()))
	actions.add_child(button(tr("MENU"), show_menu))
	spacer(root)
	add_notice(root)
func toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		if is_instance_valid(pause_overlay):
			pause_overlay.queue_free()
		pause_overlay = null
		return
	get_tree().paused = true
	pause_overlay = PanelContainer.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_theme_stylebox_override("panel", box(Color(panel_color, 0.97)))
	add_child(pause_overlay)
	var center := CenterContainer.new()
	pause_overlay.add_child(center)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 380
	center.add_child(col)
	col.add_child(label(tr("PAUSED"), 44))
	col.add_child(button(tr("RESUME"), toggle_pause, true))
	col.add_child(button(tr("MENU"), func():
		get_tree().paused = false
		pause_overlay.queue_free()
		show_menu()))

func _back() -> void:
	if screen == "hud":
		toggle_pause()
	elif screen == "scenarios":
		show_setup() if scene_return == "setup" else show_menu()
	elif screen == "guide":
		show_setup() if guide_return == "setup" else show_menu()
	else:
		show_menu()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if rebinding != "":
		if event.physical_keycode == KEY_ESCAPE:
			rebinding = ""
			show_settings()
		elif Session.bind_key(rebinding, event.physical_keycode):
			rebinding = ""
			show_settings()
		else:
			show_error("KEY_ERROR")
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE:
		_back()
		get_viewport().set_input_as_handled()

func _preferences_changed() -> void:
	apply_theme()
	match screen:
		"menu": show_menu()
		"settings": show_settings()
		"profiles": show_profiles()
		"controls": show_controls()
		"setup": show_setup()
		"scenarios": show_scenarios(scene_return)
		"guide": show_guide(guide_return)
		"hud":
			if is_instance_valid(host.race):
				host.race.view.light = Session.light
			var was_paused := get_tree().paused
			get_tree().paused = false
			show_hud()
			if was_paused:
				toggle_pause()
		"results": show_results(result_data.winner, result_data.reason, result_data.time)




