extends Node
## Run against isolated APPDATA; this suite intentionally exercises persistence.
var failures: Array[String] = []
var host: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func press_key(code: int) -> void:
	# Direct viewport injection also works with the headless DisplayServer.
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	get_viewport().push_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	get_viewport().push_input(release)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var generator := TrackGenerator.new()
	for course_seed in range(1, 301):
		check(generator.generate(course_seed), "Invalid generated seed %d" % course_seed)
		var original := generator.points.duplicate()
		generator.generate(course_seed)
		check(original == generator.points, "Seed not deterministic")
		check(generator.sections.size() == 8, "Missing modules")
	for action in Session.DEFAULT_KEYS:
		check(InputMap.has_action(action), "Missing action: " + action)
		check(not InputMap.action_get_events(action).is_empty(), "Unbound action")
	check(not Session.bind_key("p1_power", KEY_P), "Duplicate binding accepted")
	check(not Session.bind_key("p1_power", KEY_ESCAPE), "Reserved binding accepted")
	check(Session.bind_key("p1_power", KEY_Z), "Valid rebind rejected")
	Session.keys = Session.DEFAULT_KEYS.duplicate()
	Session.apply_keys()
	host = load("res://scenes/main.tscn").instantiate()
	add_child(host)
	await get_tree().process_frame
	check(host.ui.screen == "menu", "Menu did not load")
	for method in ["show_profiles", "show_settings", "show_controls", "show_setup"]:
		host.ui.call(method)
		await get_tree().process_frame
	Session.language = "es"
	Session.light = true
	Session.update_preferences()
	check(tr("PLAY") == "Jugar duelo local", "Spanish catalog not active")
	for method in ["show_menu", "show_profiles", "show_settings", "show_controls", "show_setup"]:
		host.ui.call(method)
		await get_tree().process_frame
	Session.language = "en"
	Session.light = false
	Session.update_preferences()
	check(tr("PLAY") == "Play local duel", "English catalog not active")
	var test_name := "Check%d" % (Time.get_ticks_usec() % 1000000)
	check(Session.create_profile(test_name), "Profile creation failed")
	check(not Session.create_profile(test_name), "Duplicate profile accepted")
	Session.save()
	var cfg := ConfigFile.new()
	check(cfg.load(Session.SAVE_PATH) == OK, "Saved profile not readable")
	check(cfg.get_value("data", "active") == test_name, "Active profile did not persist")
	var before: int = Session.profiles[Session.active].matches
	host.start_race(42)
	await get_tree().physics_frame
	var race: DuelRace = host.race
	check(race.phase == "placement", "Placement missing")
	check(race.placement_time > 29, "Placement must start with thirty seconds")
	check(host.ui.placement_ui and is_instance_valid(host.ui.placement_map), "Tactical placement UI missing")
	var frozen_time := race.placement_time
	host.ui.toggle_pause()
	for frame in range(6):
		await get_tree().process_frame
	check(is_equal_approx(race.placement_time, frozen_time), "Pause must freeze the placement clock")
	host.ui.toggle_pause()
	check(race.marbles[0] is RigidBody3D, "Marbles must use 3D physics")
	check(race.camera is Camera3D, "3D camera missing")
	check(race.track.points[0].y > 5, "Road must be elevated")
	race.cursor_distances[0] = 55.0
	var place_event := InputEventKey.new()
	place_event.physical_keycode = KEY_SPACE
	place_event.keycode = KEY_SPACE
	place_event.pressed = true
	get_viewport().push_input(place_event)
	await get_tree().process_frame
	check(race.placed[0] == 1, "Keyboard placement failed: " + str(race.messages))
	var release_event := InputEventKey.new()
	release_event.physical_keycode = KEY_SPACE
	release_event.keycode = KEY_SPACE
	release_event.pressed = false
	get_viewport().push_input(release_event)
	race.placement_time = DuelRace.PLACEMENT_DURATION
	check(not race.can_place(Vector3.ZERO), "Start zone allowed")
	host.ui.placement_map.cache_validity()
	check(host.ui.placement_map.cells.any(func(cell): return cell.valid), "Map must show legal positions while items remain")
	for i in range(2):
		for j in range(1 if i == 0 else 0, 3):
			race.cursor_distances[i] = 55.0 + (i * 3 + j) * 65.0
			if race.can_place(race.cursor_location(i)):
				check(race.place_item(i), "Valid placement failed")
	check(not race.can_place(race.items[0].position), "Overlapping placement accepted")
	host.ui.placement_map.cache_validity()
	check(not host.ui.placement_map.cells.is_empty(), "Map must show placement regions")
	check(host.ui.placement_map.cells.any(func(cell): return not cell.valid), "Map must show forbidden positions")
	var placement_ticks := 0
	while race.phase == "placement" and placement_ticks < 3650:
		await get_tree().physics_frame
		placement_ticks += 1
	check(placement_ticks >= 3580 and placement_ticks <= 3610, "Placement duration is not 30 seconds")
	press_key(KEY_Q)
	check(race.marbles[0].power_cooldown > 0, "Power keyboard input did not activate EMP")
	check(not race.marbles[0].activate_power(), "Power cooldown bypassed")
	check(race.marbles[1].activate_power(), "Jump did not activate")
	check(race.marbles[1].is_protected(), "Jump protection missing")
	var jump_start: float = race.marbles[1].position.y
	for frame in range(24):
		await get_tree().physics_frame
	check(race.marbles[1].position.y > jump_start + 0.6, "Jump must lift the rigid body in 3D")
	for frame in range(180):
		await get_tree().physics_frame
	var recovery_count := [0]
	race.marbles[0].recovered.connect(func(): recovery_count[0] += 1)
	Input.action_press("p1_brake")
	for frame in range(390):
		await get_tree().physics_frame
	check(race.marbles[0].braking, "Held brake stopped before the key was released")
	check(race.marbles[0].linear_velocity.length() < 1.0, "Holding brake must stop the marble")
	check(recovery_count[0] == 0, "Intentional braking triggered stuck recovery")
	var stopped_at: float = race.marbles[0].progress
	Input.action_release("p1_brake")
	for frame in range(90):
		await get_tree().physics_frame
	check(not race.marbles[0].braking and race.marbles[0].progress > stopped_at + 2, "Release must resume acceleration")
	Input.action_press("p1_brake")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(race.marbles[0].braking, "Brake must reactivate immediately without a cooldown")
	Input.action_release("p1_brake")
	var ticks := 0
	while race.phase != "finished" and ticks < 9000:
		await get_tree().physics_frame
		ticks += 1
		if ticks % 120 == 0:
			for marble in race.marbles:
				check(marble.position.is_finite(), "Non-finite 3D body position")
				check(race.camera.is_position_in_frustum(marble.position), "Shared camera lost a player")
	check(race.phase == "finished", "Race did not finish; marbles may be stuck")
	check(host.ui.screen == "results", "Results screen missing")
	check(Session.profiles[Session.active].matches == before + 1, "Statistics not recorded exactly once")
	print("RACE seed=42 time=%.2f progress=[%.1f, %.1f] health=[%.0f, %.0f]" % [race.race_time, race.marbles[0].progress, race.marbles[1].progress, race.marbles[0].health, race.marbles[1].health])
	Session.players[0].power = "PHASE"
	host.start_race(314159)
	await get_tree().physics_frame
	race = host.race
	race.placement_time = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(race.marbles[0].activate_power(), "Phase did not activate")
	check(race.marbles[0].phased > 0, "Phase state missing")
	var ramp: Dictionary = race.track.sections.filter(func(section): return section.kind == "ramp")[0]
	var slope := race.track.sample_at((ramp.start + ramp.end) / 2)
	var body := race.marbles[0]
	body.freeze = true
	body.position = slope.position - slope.normal * 1.65 + slope.up * (RacingMarble.RADIUS + 0.04)
	body.linear_velocity = Vector3.ZERO
	body.freeze = false
	Input.action_press("p1_brake")
	for frame in range(300):
		await get_tree().physics_frame
	check(absf(body.progress - slope.distance) < 1.5, "Held brake must prevent rolling down a slope")
	check(absf(body.linear_velocity.dot(slope.tangent)) < 0.4, "Held brake must stop forward and reverse slope motion")
	Input.action_release("p1_brake")
	host.ui.toggle_pause()
	check(get_tree().paused, "Pause failed")
	Session.update_preferences()
	check(get_tree().paused and is_instance_valid(host.ui.pause_overlay), "Preference refresh lost pause overlay")
	host.ui.toggle_pause()
	check(not get_tree().paused, "Resume failed")
	race.marbles[1].health = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(host.ui.result_data.get("reason") == "BY_HEALTH", "Health victory failed")
	# Race actual physics across multiple module orders and curvatures.
	for course_seed in [1, 2, 7, 23, 99, 12345, 2147483646]:
		host.start_race(course_seed)
		await get_tree().physics_frame
		race = host.race
		race.placement_time = 0
		var frames := 0
		while race.phase != "finished" and frames < 6000:
			await get_tree().physics_frame
			frames += 1
		check(race.phase == "finished", "Physics reachability failed for seed %d" % course_seed)
		print("PHYSICS seed=%d finish=%.2fs" % [course_seed, race.race_time])
	host.ui.show_menu()
	check(not is_instance_valid(host.race), "Menu did not clean race")
	# Render screenshots when run without --headless.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tools/menu-preview.png")
		host.ui.show_setup()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tools/setup-preview.png")
		host.start_race(42)
		host.race.placement_time = 0
		for i in range(360):
			await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tools/race-preview.png")
	host.clear_race()
	host.queue_free()
	await get_tree().process_frame
	print("PASS: 300 deterministic seeds, screens in both locales/themes, profiles, input, placement, powers, physics finish, health win, rematch, pause" if failures.is_empty() else "FAIL: %d checks" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
