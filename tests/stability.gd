extends Node
## Exercise render-resource and audio teardown through real menu transitions.
func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("run")

func settle(frames: int = 3) -> void:
	for frame in range(frames):
		await get_tree().process_frame

func run() -> void:
	var host := load("res://scenes/main.tscn").instantiate() as Node
	add_child(host)
	for iteration in range(12):
		host.ui.show_menu()
		host.audio.tone(510)
		await settle()
		Session.light = iteration % 2 == 0
		Session.language = "es" if iteration % 2 == 0 else "en"
		Session.update_preferences()
		host.ui.show_controls()
		await settle()
		host.ui.show_settings()
		await settle()
		host.ui.show_setup()
		await settle()
		host.start_race(42 + iteration)
		await settle()
		host.race.place_item(0)
		host.ui.toggle_pause()
		Session.update_preferences()
		await settle()
		host.ui.toggle_pause()
		host.race.placement_time = 0
		for frame in range(40):
			await get_tree().physics_frame
		host.race.marbles[0].activate_power()
		host.audio.tone(740, 0.2)
		await settle()
		host.race.marbles[1].health = 0
		await settle()
		print("Lifecycle %d / 12 complete" % (iteration + 1))
	host.clear_race()
	host.queue_free()
	await settle(8)
	print("PASS: 12 graphical menu/theme/placement/pause/race/results/audio lifecycles")
	get_tree().quit()
