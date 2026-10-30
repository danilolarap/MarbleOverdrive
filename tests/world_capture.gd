extends Node
var host: Node

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("run")

func snap(name: String) -> void:
	for frame in range(4):
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/" + name + ".png")
	print("Captured " + name)

func run() -> void:
	Session.language = "es"
	Session.light = false
	Session.update_preferences()
	host = load("res://scenes/main.tscn").instantiate()
	add_child(host)
	for page in ["show_menu", "show_profiles", "show_setup", "show_scenarios", "show_guide"]:
		host.ui.call(page)
		await snap("expanded-" + page)
	for id in GameCatalog.SCENARIOS:
		Session.scenario = id
		host.start_race(42)
		host.race.placement_time = 0
		for frame in range(500):
			await get_tree().physics_frame
		await snap("world-" + id.to_lower())
	Session.fullscreen = true
	Session.update_preferences()
	await snap("fullscreen-expanded")
	print("FULLSCREEN viewport=%s window=%s aspect=%s" % [get_viewport().get_visible_rect().size, DisplayServer.window_get_size(), get_tree().root.content_scale_aspect])
	Session.fullscreen = false
	Session.update_preferences()
	host.clear_race()
	host.queue_free()
	for frame in range(5):
		await get_tree().process_frame
	get_tree().quit()
