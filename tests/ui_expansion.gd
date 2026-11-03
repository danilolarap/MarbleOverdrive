extends Node
var host: Node
var errors := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		errors += 1
		push_error(message)

func settle() -> void:
	for frame in range(3):
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

func snap(name: String) -> void:
	await settle()
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("res://tools/" + name + ".png")

func find_widget(group: String, pilot: int, slot: int = -1) -> Node:
	for widget in get_tree().get_nodes_in_group(group):
		if widget.get_meta("pilot") == pilot and (slot < 0 or widget.get_meta("slot", -1) == slot):
			return widget
	return null

func press_card(group: String, pilot: int, id: String) -> void:
	for widget in get_tree().get_nodes_in_group(group):
		if widget.get_meta("pilot") == pilot and widget.get_meta("id", widget.get_meta("design", "")) == id:
			widget.pressed.emit()
			return
	check(false, "Missing card %s for pilot %d in %s" % [id, pilot, group])

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("run")

func run() -> void:
	host = load("res://scenes/main.tscn").instantiate()
	add_child(host)
	host.ui.show_profiles()
	await settle()
	var names := ["Nova%d" % (Time.get_ticks_usec() % 10000), "Atlas%d" % (Time.get_ticks_usec() % 10000)]
	for pilot in range(2):
		var input := find_widget("pilot_profile_names", pilot) as LineEdit
		input.text = names[pilot]
		var create := find_widget("profile_create_buttons", pilot) as Button
		create.pressed.emit()
		await settle()
		check(Session.player_name(pilot) == names[pilot], "Profile button assigned the wrong player")
	Session.language = "es"
	Session.update_preferences()
	await snap("final-profiles")
	# Step 1: the workshop picks finishes and colours with preview tiles, not lists.
	host.ui.show_setup()
	await settle()
	check(get_tree().get_nodes_in_group("design_tiles").size() == GameCatalog.PATTERNS.size() * 2, "Every finish needs a preview tile per pilot")
	press_card("design_tiles", 1, "GALAXY")
	check(Session.players[1].pattern == "GALAXY", "Design tile did not select the finish")
	var swatch: Button = get_tree().get_nodes_in_group("secondary_swatches").filter(func(w): return w.get_meta("pilot") == 0)[3]
	swatch.pressed.emit()
	check(Session.players[0].secondary == GameCatalog.PALETTE[3], "Secondary colour swatch did not apply")
	await snap("final-workshop")
	get_tree().get_nodes_in_group("workshop_next")[0].pressed.emit()
	await settle()
	check(host.ui.screen == "strategy", "Workshop did not continue to the strategy screen")
	# Step 2: strategy cards. Defaults BOOST + MAGNET + OIL cost exactly 6.
	check(not host.ui.workshop.start_button.disabled, "Default loadout must be startable")
	press_card("power_cards", 0, "PHASE")
	check(Session.players[0].power == "PHASE", "Power card did not select the power")
	press_card("loadout_cards", 0, "BOOST")
	check(Session.players[0].items == ["MAGNET", "OIL"], "Clicking a chosen card must remove it")
	check(host.ui.workshop.start_button.disabled, "Start must wait for three items")
	press_card("loadout_cards", 0, "SHIELD")
	check(Session.players[0].items == ["MAGNET", "OIL", "SHIELD"], "Card did not fill the next slot")
	check(not host.ui.workshop.start_button.disabled, "Start did not enable for a valid loadout")
	press_card("loadout_cards", 0, "REPAIR")
	check(Session.players[0].items.size() == 3, "A fourth item was accepted")
	press_card("loadout_cards", 0, "OIL")
	press_card("loadout_cards", 0, "BARRIER")
	check(not "BARRIER" in Session.players[0].items, "An item over the energy budget was accepted")
	check(host.ui.workshop.start_button.disabled, "Start remained enabled with two items")
	await snap("loadout-over-budget")
	press_card("loadout_cards", 0, "GRIP")
	check(GameCatalog.valid_loadout(Session.players[0].items), "Valid loadout not reached")
	check(not host.ui.workshop.start_button.disabled, "Start did not re-enable for a valid budget")
	check(host.ui.notice.text != tr("NO_ENERGY_ERROR"), "Budget warning persisted after fixing the loadout")
	await snap("final-strategy")
	host.ui._back()
	check(host.ui.screen == "setup", "Escape on strategy must return to the workshop")
	Session.players[0].items = GameCatalog.DEFAULT_LOADOUT.duplicate()
	Session.players[0].power = "EMP"
	host.ui.show_strategy()
	await settle()
	for category in ["EQUIPMENT", "TRAPS", "POWERS"]:
		host.ui.guide_category = category
		host.ui.show_guide("setup")
		await snap("guide-" + category.to_lower())
	for light in [false, true]:
		Session.light = light
		Session.update_preferences()
		host.ui.show_scenarios("setup")
		await snap("gallery-light" if light else "gallery-dark")
		Session.players[0].pattern = "CHECKER"
		Session.players[1].pattern = "LIGHTNING"
		host.start_race(42)
		await settle()
		host.race.cursor_distances[0] = 55
		host.race.place_item(0)
		await snap("lane-trap-light" if light else "lane-trap-dark")
		host.clear_race()
	Session.light = false
	Session.update_preferences()
	for scene in ["CITY", "ZOO", "OCEAN"]:
		Session.scenario = scene
		host.start_race(42)
		host.race.placement_time = 0
		for frame in range(500):
			await get_tree().physics_frame
		await snap("world-" + scene.to_lower())
		host.race.marbles[1].health = 0
		await settle()
		if scene == "CITY":
			await snap("final-results")
	host.clear_race()
	host.queue_free()
	await settle()
	print("PASS: profile buttons, design tiles, strategy cards, slot and energy gating, category guides and both planning themes" if errors == 0 else "FAIL: workshop UI")
	get_tree().quit(0 if errors == 0 else 1)
