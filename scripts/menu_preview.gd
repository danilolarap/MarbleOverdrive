extends SubViewportContainer
## Live 3D showroom, using the same road, city and marble geometry as races.
var camera: Camera3D
var track: TrackGenerator
var clock := 0.0
var center := Vector3.ZERO
var preview_viewport: SubViewport
var refresh_time := 0.0

func _ready() -> void:
	stretch = true
	stretch_shrink = 3 if Session.quality == "economy" else 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	preview_viewport = viewport
	viewport.size = Vector2i(900, 240)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED if Session.quality == "economy" else Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	track = TrackGenerator.new()
	track.generate(42)
	var view := TrackView.new()
	view.track = track
	view.scenario_id = Session.scenario
	view.light = Session.light
	viewport.add_child(view)
	var sample := track.sample_at(68)
	center = sample.position
	for i in range(2):
		var marble := RacingMarble.new()
		marble.track = track
		marble.player_index = i
		marble.tint = Session.players[i].color
		marble.secondary_tint = Session.players[i].secondary
		marble.pattern_id = Session.players[i].pattern
		marble.progress = 68
		marble.position = center + sample.normal * (-1.65 if i == 0 else 1.65) + Vector3.UP * RacingMarble.RADIUS
		viewport.add_child(marble)
	camera = Camera3D.new()
	camera.fov = 54
	viewport.add_child(camera)
	camera.position = center + Vector3(13, 9, 23)
	camera.look_at(center + Vector3(-9, 1, -12))
	camera.current = true

func _process(delta: float) -> void:
	clock += delta
	refresh_time += delta
	if refresh_time >= 1.0 / 30.0 and is_visible_in_tree():
		refresh_time = fmod(refresh_time, 1.0 / 30.0)
		preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if camera:
		camera.position.x = center.x + 13 + sin(clock * 0.12) * 1.5
		camera.look_at(center + Vector3(-9, 1, -12))
