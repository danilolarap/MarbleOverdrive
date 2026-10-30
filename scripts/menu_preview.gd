extends SubViewportContainer
## Live 3D showroom, using the same road, city and marble geometry as races.
var camera: Camera3D
var track: TrackGenerator
var clock := 0.0
var center := Vector3.ZERO

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(900, 240)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	track = TrackGenerator.new()
	track.generate(42)
	var view := TrackView.new()
	view.track = track
	view.scenario_id = Session.scenario
	view.light = Session.light
	viewport.add_child(view)
	var sample := track.sample_at(100)
	center = sample.position
	for i in range(2):
		var marble := RacingMarble.new()
		marble.track = track
		marble.player_index = i
		marble.tint = Session.players[i].color
		marble.secondary_tint = Session.players[i].secondary
		marble.pattern_id = Session.players[i].pattern
		marble.progress = 100
		marble.position = center + sample.normal * (-1.65 if i == 0 else 1.65) + Vector3.UP * RacingMarble.RADIUS
		viewport.add_child(marble)
	camera = Camera3D.new()
	camera.fov = 60
	viewport.add_child(camera)
	camera.position = center + Vector3(3, 8, 19)
	camera.look_at(center + Vector3(0, 1, -8))
	camera.current = true

func _process(delta: float) -> void:
	clock += delta
	if camera:
		camera.position.x = center.x + 3 + sin(clock * 0.18) * 2
		camera.look_at(center + Vector3(0, 1, -8))
