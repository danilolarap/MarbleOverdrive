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

func choose_item(pilot: int, slot: int, id: String) -> void:
	var picker := find_widget("loadout_pickers", pilot, slot) as OptionButton
	for i in range(picker.item_count):
		if picker.get_item_metadata(i) == id:
			picker.selected = i
			picker.item_selected.emit(i)
			return
	check(false, "Missing item in categorized picker: " + id)

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
	host.ui.show_setup()
	await settle()
	for tabs in get_tree().get_nodes_in_group("pilot_workshop_tabs"):
		tabs.current_tab = 1
	choose_item(0, 1, "BOOST")
	check(Session.players[0].items[1] == "MAGNET", "Duplicate item was not rejected by the UI")
	choose_item(0, 2, "SHIELD")
	check(host.ui.workshop.start_button.disabled, "Start remained enabled over budget")
	await snap("loadout-over-budget")
	choose_item(0, 0, "GRIP")
	check(not host.ui.workshop.start_button.disabled, "Start did not re-enable for a valid budget")
	check(host.ui.notice.text != tr("LOADOUT_ERROR"), "Budget warning persisted after fixing the loadout")
	await snap("final-strategy")
	Session.players[0].items = GameCatalog.DEFAULT_LOADOUT.duplicate()
	host.ui.show_setup()
	await snap("final-workshop")
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
	print("PASS: profile buttons, two workshop tabs, duplicate rejection, energy gating, category guides and both planning themes" if errors == 0 else "FAIL: workshop UI")
	get_tree().quit(0 if errors == 0 else 1)
