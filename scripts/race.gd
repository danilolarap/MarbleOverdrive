class_name DuelRace
extends Node3D

signal completed(winner: int, reason: String, race_time: float)
signal notification(message: String)
const PLACEMENT_DURATION := 30.0
const ITEM_SOUNDS := {"BOOST": "boost", "REPAIR": "repair", "SHIELD": "shield", "GRIP": "grip", "MAGNET": "hit_magnet", "BARRIER": "hit_barrier", "OIL": "hit_oil", "SHOCK": "hit_shock"}
const POWER_SOUNDS := {"EMP": "emp", "JUMP": "jump", "PHASE": "phase"}
var track := TrackGenerator.new()
var world: Node3D
var view: TrackView
var camera: Camera3D
var marbles: Array[RacingMarble] = []
var items: Array[TacticalItem] = []
var phase := "placement"
var placement_time := PLACEMENT_DURATION
var race_time := 0.0
var cursor_distances := [170.0, 330.0]
var cursor_offsets := [-1.65, 1.65]
var placed := [0, 0]
var messages := ["", ""]
var audio: Node
var valid := false
var camera_initialized := false
var camera_target := Vector3.ZERO
var _in_gap := [false, false]

func initialize(course_seed: int) -> bool:
	valid = track.generate(course_seed)
	return valid

func _ready() -> void:
	if not valid:
		return
	world = Node3D.new()
	add_child(world)
	view = TrackView.new()
	view.track = track
	view.scenario_id = Session.scenario
	view.light = Session.light
	world.add_child(view)
	view.set_placement(true)
	world.visible = false
	track.build_walls(world)
	camera = Camera3D.new()
	camera.fov = 62
	camera.near = 0.15
	camera.far = 1000
	add_child(camera)
	camera.current = true
	for index in range(2):
		var marble := RacingMarble.new()
		marble.player_index = index
		marble.tint = Session.players[index].color
		marble.secondary_tint = Session.players[index].secondary
		marble.pattern_id = Session.players[index].pattern
		marble.power_id = Session.players[index].power
		marble.track = track
		var start := track.sample_at(6)
		marble.position = start.position + start.normal * (-1.65 if index == 0 else 1.65) + start.up * (RacingMarble.RADIUS + 0.06)
		world.add_child(marble)
		marble.power_fired.connect(_on_power)
		marble.recovered.connect(func():
			_sound("recover")
			notification.emit("RECOVERY"))
		marbles.append(marble)
		marble.damaged.connect(func(at, tint): view.feedback(at, tint, 1.5))
	view.racing_marbles = marbles
	view.cursor_colors = [marbles[0].tint, marbles[1].tint]
	_update_camera(1.0)

func _physics_process(delta: float) -> void:
	if not valid or phase == "finished":
		return
	if phase == "placement":
		var second_before := ceili(placement_time)
		placement_time -= delta
		if ceili(placement_time) != second_before and placement_time > 0 and second_before <= 5:
			_sound("countdown", 1.0 if second_before > 1 else 1.5)
		for i in range(2):
			var left := KEY_A if i == 0 else KEY_LEFT
			var right := KEY_D if i == 0 else KEY_RIGHT
			var up := KEY_W if i == 0 else KEY_UP
			var down := KEY_S if i == 0 else KEY_DOWN
			var target := next_target(i)
			if signf(cursor_offsets[i]) != (-1.0 if target == 0 else 1.0):
				cursor_offsets[i] = -1.65 if target == 0 else 1.65
			cursor_distances[i] = clampf(cursor_distances[i] + (float(Input.is_physical_key_pressed(right)) - float(Input.is_physical_key_pressed(left))) * 65 * delta, 26, track.total_length - 24)
			cursor_offsets[i] = clampf(cursor_offsets[i] + (float(Input.is_physical_key_pressed(down)) - float(Input.is_physical_key_pressed(up))) * 3 * delta, -3 if target == 0 else 0.8, -0.8 if target == 0 else 3)
		view.cursors = [cursor_location(0), cursor_location(1)]
		if placement_time <= 0:
			phase = "race"
			world.visible = true
			view.set_placement(false)
			camera_initialized = false
			view.cursors.clear()
			for marble in marbles:
				marble.racing = true
				marble.freeze = false
			if audio:
				audio.play("go")
	else:
		race_time += delta
		for marble in marbles:
			for item in items:
				if item.try_affect(marble):
					view.feedback(item.position + Vector3.UP * 0.3, GameCatalog.ITEMS[item.kind].color)
					_sound(ITEM_SOUNDS.get(item.kind, "ui_select"))
			for i in range(track.hazards.size()):
				var hazard: Dictionary = track.hazards[i]
				if marble.position.distance_to(hazard.position) < hazard.radius + RacingMarble.RADIUS and race_time - marble.last_hit.get(i, -10.0) > 1.1:
					marble.last_hit[i] = race_time
					marble.damage(18)
					_sound("hazard")
					if not marble.is_protected():
						marble.slowed = 0.5
		_check_winner()
	# Camera smoothing runs on rendered frames, not the physics tick.

func cursor_location(index: int) -> Vector3:
	var sample := track.sample_at(cursor_distances[index])
	return sample.position + sample.normal * cursor_offsets[index]

func place_item(index: int) -> bool:
	if placed[index] >= 3:
		messages[index] = "EMPTY"
		return false
	var point := cursor_location(index)
	if not can_place(point, index):
		messages[index] = "INVALID"
		_sound("invalid")
		return false
	var item := TacticalItem.new()
	item.position = point
	item.kind = Session.players[index].items[placed[index]]
	item.owner_index = index
	var sample := track.sample_at(cursor_distances[index])
	item.basis = Basis(sample.normal, sample.up, -sample.tangent)
	world.add_child(item)
	items.append(item)
	placed[index] += 1
	cursor_offsets[index] = -1.65 if next_target(index) == 0 else 1.65
	messages[index] = "PLACED"
	_sound("place_trap" if GameCatalog.is_trap(item.kind) else "place_equipment", 1.0 + index * 0.06)
	return true

func next_item(index: int) -> String:
	return Session.players[index].items[mini(placed[index], 2)]

func next_target(index: int) -> int:
	return GameCatalog.target_lane(index, next_item(index))

func can_place(point: Vector3, player_index: int = -1, item_id: String = "") -> bool:
	return placement_issue(point, player_index, item_id) == ""

## Why an item cannot go at `point` (a translation key), or "" when it can.
func placement_issue(point: Vector3, player_index: int = -1, item_id: String = "") -> String:
	var sample := track.closest(point)
	var offset: float = (point - sample.position).dot(sample.normal)
	if player_index >= 0:
		if placed[player_index] >= 3:
			return "ISSUE_DONE"
		var id := next_item(player_index) if item_id == "" else item_id
		var lane := GameCatalog.target_lane(player_index, id)
		if absf(offset) < 0.8:
			return "ISSUE_CENTER"
		if (offset < 0) != (lane == 0):
			return "ISSUE_HALF"
	if sample.distance < 26 or sample.distance > track.total_length - 24:
		return "ISSUE_ENDS"
	if track.is_placement_blocked(sample.distance):
		return "ISSUE_GAP"
	if point.distance_to(sample.position) > 3.1:
		return "ISSUE_EDGE"
	# Each obstacle retains a continuous route around it on the 10 m deck.
	for item in items:
		var other := track.closest(item.position)
		var other_offset: float = (item.position - other.position).dot(other.normal)
		if signf(offset) == signf(other_offset) and point.distance_to(item.position) < 8:
			return "ISSUE_ITEM"
	for hazard in track.hazards:
		if point.distance_to(hazard.position) < 8:
			return "ISSUE_HAZARD"
	return ""

func _sound(id: String, pitch: float = 1.0) -> void:
	if audio and audio.has_method("play"):
		audio.play(id, pitch)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if phase == "placement":
		if event.physical_keycode == KEY_SPACE:
			place_item(0)
		elif event.physical_keycode == KEY_ENTER:
			place_item(1)
	elif phase == "race":
		for index in range(2):
			if event.is_action_pressed("p%d_power" % (index + 1)):
				marbles[index].activate_power()
			elif event.is_action_pressed("p%d_brake" % (index + 1)):
				_sound("brake")

func _on_power(marble: RacingMarble) -> void:
	_sound(POWER_SOUNDS.get(marble.power_id, "jump"))
	if marble.power_id != "EMP":
		return
	view.feedback(marble.position, marble.tint, 8.0)
	var rival := marbles[1 - marble.player_index]
	if rival.position.distance_to(marble.position) <= 16 and not rival.is_protected():
		rival.damage(12)
		var normal: Vector3 = track.sample_at(rival.progress).normal
		rival.apply_central_impulse(normal * (6 if rival.player_index == 1 else -6))
		rival.slowed = 0.65

func _check_winner() -> void:
	var dead := [marbles[0].health <= 0, marbles[1].health <= 0]
	var finished := [marbles[0].progress >= track.total_length - 4, marbles[1].progress >= track.total_length - 4]
	var winner := -2
	var reason := "BY_FINISH"
	if dead[0] and dead[1]:
		winner = -1
	elif dead[0] or dead[1]:
		winner = 1 if dead[0] else 0
		reason = "BY_HEALTH"
	elif finished[0] and finished[1]:
		winner = -1
	elif finished[0] or finished[1]:
		winner = 0 if finished[0] else 1
	if winner == -2:
		return
	if winner == -1:
		reason = "BY_DRAW"
	phase = "finished"
	for marble in marbles:
		marble.racing = false
		marble.freeze = true
	Session.record_result(winner)
	_sound("finish")
	if audio and audio.has_method("stop_rolling"):
		audio.stop_rolling()
	for marble in marbles:
		if winner < 0 or marble.player_index == winner:
			view.feedback(marble.position, marble.tint, 5.0)
	completed.emit(winner, reason, race_time)

func _process(delta: float) -> void:
	if valid and is_instance_valid(camera):
		_update_camera(delta)
	if not valid or marbles.size() < 2:
		return
	for i in range(2):
		var marble := marbles[i]
		var over_gap := phase == "race" and track.is_gap(marble.progress)
		if over_gap != _in_gap[i]:
			_sound("gap" if over_gap else "land", 1.0 + i * 0.05)
			_in_gap[i] = over_gap
		if audio and audio.has_method("set_rolling"):
			audio.set_rolling(i, marble.linear_velocity.length(), phase == "race" and not over_gap and marble.airborne <= 0)

func _exit_tree() -> void:
	if audio and audio.has_method("stop_rolling"):
		audio.stop_rolling()

func _update_camera(delta: float) -> void:
	var target: Vector3
	var eye: Vector3
	if phase == "placement":
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 400
		target = track.sample_at(track.total_length / 2).position
		eye = target + Vector3(70, 350, 0)
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		var middle := (marbles[0].position + marbles[1].position) / 2
		var sample := track.sample_at((marbles[0].progress + marbles[1].progress) / 2)
		var forward: Vector3 = sample.tangent
		forward.y = 0
		forward = forward.normalized()
		var spread := marbles[0].position.distance_to(marbles[1].position)
		var separation := maxf(0, spread - 6)
		target = middle + forward * 9 + Vector3.UP * 0.6
		eye = middle - forward * (17 + separation * 0.8) + Vector3.UP * (9 + separation * 0.48)
	if not camera_initialized or phase == "placement":
		camera.position = eye
		camera_target = target
		camera_initialized = true
	else:
		camera.position = camera.position.lerp(eye, 1 - exp(-delta * 4))
		camera_target = camera_target.lerp(target, 1 - exp(-delta * 5))
	camera.look_at(camera_target, Vector3.LEFT if phase == "placement" else Vector3.UP)
