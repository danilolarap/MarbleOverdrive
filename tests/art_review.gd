extends Node
## Graphical acceptance matrix; isolated data directory required by the launcher.
var host: Node
var failures := 0
var report: Array[Dictionary] = []

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("run")

func snap(filename: String) -> void:
	for frame in range(36):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png("res://tools/art-" + filename + ".png")
	if result != OK:
		failures += 1
	report.append({"capture": filename, "draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), "primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))})
	print("ART ", report[-1])

func run() -> void:
	Session.fullscreen = false
	Session.sound = false
	Session.update_preferences()
	host = load("res://scenes/main.tscn").instantiate()
	add_child(host)
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		DisplayServer.window_set_size(dimensions)
		for light_mode in [true, false]:
			for locale in ["es", "en"]:
				Session.language = locale
				Session.light = light_mode
				Session.update_preferences()
				host.ui.show_menu()
				await snap("menu-%d-%s-%s" % [dimensions.x, str(light_mode), locale])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Session.language = "es"
	Session.light = true
	Session.update_preferences()
	for page in ["profiles", "settings", "setup", "scenarios", "guide", "controls"]:
		host.ui.call("show_" + page)
		await snap(page)
	for id in ["CITY", "FACTORY", "TRANSIT"]:
		for light_mode in [true, false]:
			Session.light = light_mode
			Session.scenario = id
			Session.update_preferences()
			host.start_race(42 if light_mode else 781)
			for i in range(2):
				host.race.place_item(i)
			await snap(id + "-placement-" + str(light_mode))
			host.race.placement_time = 0
			for frame in range(420):
				await get_tree().physics_frame
			await snap(id + "-race-" + str(light_mode))
			if id == "CITY":
				host.ui.toggle_pause()
				await snap("pause-" + str(light_mode))
				host.ui.toggle_pause()
				host.ui.show_results(0, "BY_FINISH", 19.42)
				await snap("results-" + str(light_mode))
	Session.quality = "economy"
	Session.update_preferences()
	host.start_race(12345)
	host.race.placement_time = 0
	for frame in range(420):
		await get_tree().physics_frame
	await snap("economy")
	var file := FileAccess.open("res://tools/art-render-metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	host.clear_race()
	host.queue_free()
	for frame in range(6):
		await get_tree().process_frame
	get_tree().quit(failures)
