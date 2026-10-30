extends Node

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("run")

func run() -> void:
	Session.language = "es"
	Session.light = false
	Session.update_preferences()
	var host := load("res://scenes/main.tscn").instantiate() as Node
	add_child(host)
	host.start_race(42)
	await get_tree().physics_frame
	await snapshot("3d-placement")
	host.race.placement_time = 0
	for i in range(360):
		await get_tree().physics_frame
	await snapshot("3d-race-start")
	for i in range(360):
		await get_tree().physics_frame
	await snapshot("3d-race-curve")
	host.race.marbles[1].activate_power()
	for i in range(36):
		await get_tree().physics_frame
	await snapshot("3d-jump")
	Session.light = true
	Session.update_preferences()
	await snapshot("3d-daylight")
	host.clear_race()
	host.queue_free()
	for frame in range(4):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	get_tree().quit()

func snapshot(filename: String) -> void:
	for i in range(3):
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/" + filename + ".png")
	print("Captured " + filename)
