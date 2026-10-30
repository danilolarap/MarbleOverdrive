extends Node

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("capture")

func capture() -> void:
	var host := load("res://scenes/main.tscn").instantiate() as Node
	add_child(host)
	await get_tree().process_frame
	Session.language = "es"
	Session.light = true
	Session.update_preferences()
	for page in ["menu", "settings", "setup", "controls"]:
		host.ui.call("show_" + page)
		await snapshot("light-es-" + page)
	host.start_race(42)
	await get_tree().physics_frame
	await snapshot("light-es-placement")
	Session.language = "es"
	Session.light = false
	Session.update_preferences()
	await snapshot("dark-placement")
	host.ui.show_controls()
	await snapshot("dark-es-controls")
	host.ui.show_hud()
	host.ui.toggle_pause()
	Session.update_preferences()
	await snapshot("pause")
	host.ui.toggle_pause()
	Session.save()
	host.clear_race()
	host.queue_free()
	for frame in range(4):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	get_tree().quit()

func snapshot(filename: String) -> void:
	for i in range(3):
		await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png("res://tools/" + filename + ".png")
	print("Screenshot %s: %s" % [filename, error_string(error)])
