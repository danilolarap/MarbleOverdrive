extends Node
## Same pose/seed/window for both quality levels; no fixed-fps flag.
func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Session.fullscreen = false
	Session.light = false
	Session.sound = false
	var host := load("res://scenes/main.tscn").instantiate() as Node
	add_child(host)
	var report := []
	for id in ["CITY", "FACTORY", "TRANSIT"]:
		for quality in ["balanced", "economy"]:
			Session.scenario = id
			Session.quality = quality
			Session.update_preferences()
			host.start_race(42)
			var race: DuelRace = host.race
			race.set_physics_process(false)
			race.phase = "race"
			race.world.visible = true
			race.view.set_placement(false)
			var sample := race.track.sample_at(100)
			for i in range(2):
				race.marbles[i].progress = 100
				race.marbles[i].position = sample.position + sample.normal * (-1.65 if i == 0 else 1.65) + sample.up * 0.86
			race.camera_initialized = false
			race._update_camera(1.0)
			host.ui.show_hud()
			for frame in range(60):
				await RenderingServer.frame_post_draw
			var durations: Array[float] = []
			var previous := Time.get_ticks_usec()
			for frame in range(180):
				await RenderingServer.frame_post_draw
				var current := Time.get_ticks_usec()
				durations.append((current - previous) / 1000.0)
				previous = current
			durations.sort()
			var metric := {"world": id, "quality": quality, "median_ms": durations[90], "p95_ms": durations[171], "draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))}
			report.append(metric)
			print("BENCHMARK ", metric)
	var output := FileAccess.open("res://tools/art-benchmark.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	host.clear_race()
	host.queue_free()
	for frame in range(6):
		await get_tree().process_frame
	get_tree().quit()
