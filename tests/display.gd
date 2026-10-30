extends Node
var errors := 0

func verify(condition: bool, message: String) -> void:
	if not condition:
		errors += 1
		push_error(message)

func settle() -> void:
	for frame in range(6):
		await RenderingServer.frame_post_draw

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("run")

func run() -> void:
	Session.fullscreen = false
	Session.apply_display()
	var host := load("res://scenes/main.tscn").instantiate() as Node
	add_child(host)
	host.ui.show_settings()
	for resolution in [Vector2i(1280, 720), Vector2i(1100, 900), Vector2i(1600, 900)]:
		DisplayServer.window_set_size(resolution)
		await settle()
		var canvas := get_viewport().get_visible_rect().size
		var window := DisplayServer.window_get_size()
		verify(absf(canvas.x / canvas.y - float(window.x) / window.y) < 0.003, "Canvas letterboxed at %s" % resolution)
	Session.fullscreen = true
	Session.update_preferences()
	await settle()
	var monitor := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var window := DisplayServer.window_get_size()
	verify(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, "Fullscreen setting did not enter exclusive mode")
	verify(window == monitor, "Fullscreen window did not cover monitor: %s / %s" % [window, monitor])
	get_viewport().get_texture().get_image().save_png("res://tools/fullscreen-settings.png")
	print("FULLSCREEN window=%s monitor=%s canvas=%s" % [window, monitor, get_viewport().get_visible_rect().size])
	Session.fullscreen = false
	Session.update_preferences()
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await settle()
	host.queue_free()
	await settle()
	print("PASS: display fills three window aspect ratios and the full monitor" if errors == 0 else "FAIL: display")
	get_tree().quit(0 if errors == 0 else 1)
