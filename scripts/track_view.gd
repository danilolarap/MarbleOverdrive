class_name TrackView
extends Node3D

var track: TrackGenerator
var light := false:
	set(value):
		light = value
		if is_inside_tree() and environment_node:
			_apply_environment()
var cursors: Array[Vector3] = []
var cursor_colors: Array[Color] = []
var pulse_positions: Array[Dictionary] = []
var cursor_nodes: Array[Node3D] = []
var environment_node: WorldEnvironment
var sun: DirectionalLight3D
var road_material: ShaderMaterial
var clock := 0.0
var city_root: Node3D
var scenario_id := "CITY"
var _materials: Dictionary = {}
var checkpoint_distances: Array[float] = []
var checkpoint_counts := [0, 0]
var effects: RaceEffects
var racing_marbles: Array[RacingMarble] = []

func view_material(color: Color, emission: float = 0.0, metallic: float = 0.0, roughness: float = 0.4) -> StandardMaterial3D:
	var key := var_to_bytes([color, emission, metallic, roughness]).hex_encode()
	if not _materials.has(key):
		_materials[key] = NeonGeometry.material(color, emission, metallic, roughness)
	return _materials[key]

func set_placement(placing: bool) -> void:
	if city_root:
		city_root.visible = not placing
	if road_material:
		road_material.set_shader_parameter("tactical", placing)

func _ready() -> void:
	_create_environment()
	_create_road()
	if DistrictKit.PROFILES.has(scenario_id):
		var district := DistrictKit.new()
		district.profile = DistrictKit.PROFILES[scenario_id]
		district.course_seed = track.seed_value
		district.economy = Session.quality == "economy"
		add_child(district)
		city_root = district
	else:
		var scenery := ScenarioWorld.new()
		scenery.scenario_id = scenario_id
		scenery.course_seed = track.seed_value
		add_child(scenery)
		city_root = scenery
	_create_hazards()
	_create_cursors()
	_create_gates()
	effects = RaceEffects.new()
	add_child(effects)
	_apply_environment()

func _create_environment() -> void:
	environment_node = WorldEnvironment.new()
	environment_node.environment = Environment.new()
	var environment := environment_node.environment
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_density = 0.003
	add_child(environment_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.shadow_enabled = Session.quality != "economy"
	sun.directional_shadow_max_distance = 65
	add_child(sun)

func _apply_environment() -> void:
	var environment := environment_node.environment
	environment.background_color = Color("aebbbf") if light else Color("101d2b")
	if DistrictKit.PROFILES.has(scenario_id):
		var profile: DistrictProfile = DistrictKit.PROFILES[scenario_id]
		environment.background_color = profile.day_sky if light else profile.night_sky
	else:
		var world_color: Color = GameCatalog.WORLD_COLORS[scenario_id][0]
		environment.background_color = world_color.lightened(0.56) if light else world_color
	environment.ambient_light_color = Color("c4d1d3") if light else Color("acbfd0")
	environment.ambient_light_energy = 0.48 if light else 0.72
	environment.fog_light_color = environment.background_color
	environment.fog_density = 0.0018 if light else 0.003
	sun.light_color = Color("ffecd0") if light else Color("b6cad9")
	sun.light_energy = 1.15 if light else 0.85
	if road_material:
		road_material.set_shader_parameter("daylight", light)

func _create_road() -> void:
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edge_batches: Array = [[], []]
	var guard_batches: Array[Transform3D] = []
	for i in range(track.points.size() - 1):
		var a := track.sample_at(track.distances[i])
		var b := track.sample_at(track.distances[i + 1])
		var vertices: Array[Vector3] = [a.position - a.normal * 5, b.position - b.normal * 5, a.position + a.normal * 5, a.position + a.normal * 5, b.position - b.normal * 5, b.position + b.normal * 5]
		var uvs: Array[Vector2] = [Vector2(0, track.distances[i]), Vector2(0, track.distances[i + 1]), Vector2(1, track.distances[i]), Vector2(1, track.distances[i]), Vector2(0, track.distances[i + 1]), Vector2(1, track.distances[i + 1])]
		for vertex_index in range(6):
			road.set_normal(a.up)
			road.set_uv(uvs[vertex_index])
			road.add_vertex(vertices[vertex_index])
		for side_index in range(2):
			var side := -1 if side_index == 0 else 1
			for height in [0.08]:
				var begin: Vector3 = a.position + a.normal * 5 * side + a.up * height
				var end: Vector3 = b.position + b.normal * 5 * side + b.up * height
				edge_batches[side_index].append(NeonGeometry.beam_transform(begin, end, 0.06, 0.06))
			var begin: Vector3 = a.position + a.normal * 5.05 * side + a.up * 0.48
			var end: Vector3 = b.position + b.normal * 5.05 * side + b.up * 0.48
			guard_batches.append(NeonGeometry.beam_transform(begin, end, 0.24, 0.95))
	var deck := MeshInstance3D.new()
	deck.mesh = road.commit()
	road_material = ShaderMaterial.new()
	road_material.shader = preload("res://shaders/road.gdshader")
	deck.material_override = road_material
	add_child(deck)
	for side_index in range(2):
		var batch: Array[Transform3D] = []
		for transform in edge_batches[side_index]:
			batch.append(transform)
		NeonGeometry.batch_boxes(self, batch, view_material(Color("43c6d8") if side_index == 0 else Color("ed66cf"), 0.5))
	NeonGeometry.batch_boxes(self, guard_batches, view_material(Color("4b555c"), 0, 0.55, 0.6))
	var fixtures: Array[Transform3D] = []
	var ribs: Array[Transform3D] = []
	for distance in range(4, int(track.total_length), 8):
		var sample := track.sample_at(distance)
		for side in [-1, 1]:
			var p: Vector3 = sample.position + sample.normal * 5.05 * side
			ribs.append(Transform3D(Basis(sample.normal * 0.36, sample.up * 1.35, -sample.tangent * 0.3), p + sample.up * 0.65))
			fixtures.append(Transform3D(Basis(sample.normal * 0.28, sample.up * 0.09, -sample.tangent * 0.8), p + sample.up * 1.36))
	NeonGeometry.batch_boxes(self, ribs, view_material(Color("242d34"), 0, 0.4))
	NeonGeometry.batch_boxes(self, fixtures, view_material(Color("cad178"), 0.4))
	var supports: Array[Transform3D] = []
	for distance in range(8, int(track.total_length), 24):
		var sample := track.sample_at(distance)
		var p: Vector3 = sample.position
		supports.append(Transform3D(Basis.IDENTITY.scaled(Vector3(2.2, p.y - 1, 2.2)), Vector3(p.x, (p.y - 1) / 2, p.z)))
		NeonGeometry.box(self, p - Vector3(0, 0.45, 0), Vector3(11, 0.5, 1), view_material(Color("18314a"), 0, 0.6))
	NeonGeometry.batch_boxes(self, supports, view_material(Color("10253b"), 0, 0.6))
	for section in track.sections:
		if section.kind in ["ramp", "drop"]:
			for distance in range(int(section.start) + 8, int(section.end) - 5, 10):
				var sample := track.sample_at(distance)
				var p: Vector3 = sample.position + sample.up * 0.025
				var material := view_material(Color("19a2bb") if section.kind == "drop" else Color("377486"), 0.5)
				NeonGeometry.beam(self, p - sample.normal * 3.5 - sample.tangent * 0.6, p + sample.tangent * 0.6, 0.1, 0.035, material)
				NeonGeometry.beam(self, p + sample.normal * 3.5 - sample.tangent * 0.6, p + sample.tangent * 0.6, 0.1, 0.035, material)
	var finish := track.sample_at(track.total_length - 4)
	for row in range(10):
		for column in range(2):
			var block := NeonGeometry.box(self, finish.position + finish.normal * (-4.5 + row) + finish.tangent * (column - 0.5) + finish.up * 0.02, Vector3(1, 0.025, 1), view_material(Color("e1f7ff") if (row + column) % 2 == 0 else Color("101726"), 0.2))
			block.basis = Basis(finish.normal, finish.up, -finish.tangent)
	for side in [-1, 1]:
		NeonGeometry.box(self, finish.position + finish.normal * 5 * side + Vector3.UP * 3, Vector3(0.3, 6, 0.3), view_material(Color("7de8ff"), 1.5))
	NeonGeometry.beam(self, finish.position + finish.normal * 5 + Vector3.UP * 6, finish.position - finish.normal * 5 + Vector3.UP * 6, 0.2, 0.25, view_material(Color("7de8ff"), 2.5))
	var banner := Label3D.new()
	banner.text = tr("FINISH")
	banner.position = finish.position + Vector3.UP * 6.8
	banner.font_size = 80
	banner.pixel_size = 0.025
	add_child(banner)
	NeonGeometry.consolidate_boxes(self)

func _create_hazards() -> void:
	for hazard in track.hazards:
		var node := Node3D.new()
		node.position = hazard.position
		add_child(node)
		var red := view_material(Color("fb507d"), 2)
		NeonGeometry.ring(node, 1.0, 0.07, red).position.y = 0.1
		var core := NeonGeometry.sphere(node, 0.7, view_material(Color("661d40"), 0.4, 0.6))
		core.position.y = 0.6
		for i in range(6):
			var angle := i * TAU / 6
			var direction := Vector3(cos(angle), 0, sin(angle))
			NeonGeometry.beam(node, direction * 0.45 + Vector3.UP * 0.3, direction * 0.9 + Vector3.UP * 1.2, 0.12, 0.12, red)

func _create_cursors() -> void:
	for i in range(2):
		var node := Node3D.new()
		add_child(node)
		var tint := Color("43c6d8") if i == 0 else Color("ed66cf")
		NeonGeometry.ring(node, 2.4, 0.13, view_material(tint, 3))
		NeonGeometry.box(node, Vector3(0, 4, 0), Vector3(0.15, 8, 0.15), view_material(tint, 2))
		var tag := Label3D.new()
		tag.text = "P%d" % (i + 1)
		tag.position.y = 10
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.font_size = 90
		tag.pixel_size = 0.08
		tag.modulate = tint
		node.add_child(tag)
		cursor_nodes.append(node)

func _process(delta: float) -> void:
	clock += delta
	for marble in racing_marbles:
		var index := marble.player_index
		if checkpoint_counts[index] < checkpoint_distances.size() and marble.progress >= checkpoint_distances[checkpoint_counts[index]]:
			checkpoint_counts[index] += 1
			feedback(marble.position, marble.tint, 2.5)
	for i in range(cursor_nodes.size()):
		cursor_nodes[i].visible = i < cursors.size()
		if i < cursors.size():
			cursor_nodes[i].position = cursors[i] + Vector3.UP * 0.1
	for effect in pulse_positions:
		if not effect.has("node"):
			var ring := NeonGeometry.ring(self, 1, 0.025, view_material(effect.color, 3))
			ring.position = effect.position
			effect.node = ring
		effect.time -= delta
		effect.node.scale = Vector3.ONE * maxf(0.1, (1 - effect.time / 0.5) * effect.get("radius", 8.0))
		if effect.time <= 0:
			effect.node.queue_free()
	pulse_positions = pulse_positions.filter(func(effect): return effect.time > 0)

func feedback(at: Vector3, color: Color, radius: float = 2.0) -> void:
	if pulse_positions.size() < 10:
		pulse_positions.append({"position": at, "time": 0.5, "color": color, "radius": radius})
	if effects:
		effects.burst(at, color)

func _create_gates() -> void:
	var steel := view_material(Color("4b555c"), 0, 0.55, 0.5)
	var mark := view_material(Color("ccd472"), 0.5)
	for index in [1, 3, 5]:
		var distance: float = track.sections[index].end
		checkpoint_distances.append(distance)
		var sample := track.sample_at(distance)
		var gate := Node3D.new()
		gate.position = sample.position
		gate.basis = Basis(sample.normal, sample.up, -sample.tangent)
		add_child(gate)
		for side in [-1, 1]:
			NeonGeometry.box(gate, Vector3(side * 5.55, 3, 0), Vector3(0.7, 6, 0.65), steel)
			NeonGeometry.box(gate, Vector3(side * 5.55, 5.6, 0.35), Vector3(0.32, 0.5, 0.05), mark)
		NeonGeometry.box(gate, Vector3(0, 6.1, 0), Vector3(11.8, 0.65, 0.7), steel)
		var title := Label3D.new()
		title.text = "%s  %02d    /    M / O" % [tr("TRACK_SECTOR"), checkpoint_distances.size()]
		title.position = Vector3(0, 6.1, 0.38)
		title.font_size = 48
		title.pixel_size = 0.013
		title.outline_size = 0
		title.modulate = Color("e5e8cb")
		gate.add_child(title)
		NeonGeometry.consolidate_boxes(gate)


