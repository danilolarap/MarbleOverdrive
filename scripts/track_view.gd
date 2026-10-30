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
var transit: Node3D
var _materials: Dictionary = {}

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
	if scenario_id == "CITY":
		_create_city()
		_city_details()
	else:
		var scenery := ScenarioWorld.new()
		scenery.scenario_id = scenario_id
		scenery.course_seed = track.seed_value
		add_child(scenery)
		city_root = scenery
	_create_hazards()
	_create_cursors()
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
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)

func _apply_environment() -> void:
	var environment := environment_node.environment
	environment.background_color = Color("a4b6c5") if light else Color("060e24")
	if scenario_id != "CITY":
		var world_color: Color = GameCatalog.WORLD_COLORS[scenario_id][0]
		environment.background_color = world_color.lightened(0.56) if light else world_color
	environment.ambient_light_color = Color("b4c6d6") if light else Color("91b5d6")
	environment.ambient_light_energy = 0.45 if light else 0.8
	environment.fog_light_color = Color("a4b6c5") if light else Color("0b1c39")
	if scenario_id != "CITY":
		environment.fog_light_color = environment.background_color
	environment.fog_density = 0.0015 if light else 0.003
	sun.light_color = Color("dcefff") if light else Color("89bbef")
	sun.light_energy = 0.95 if light else 1.1
	if road_material:
		road_material.set_shader_parameter("daylight", light)

func _create_road() -> void:
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edge_batches: Array = [[], []]
	var glass_batches: Array[Transform3D] = []
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
			for height in [0.06, 1.35]:
				var begin: Vector3 = a.position + a.normal * 5 * side + a.up * height
				var end: Vector3 = b.position + b.normal * 5 * side + b.up * height
				edge_batches[side_index].append(NeonGeometry.beam_transform(begin, end, 0.06, 0.06))
			var begin: Vector3 = a.position + a.normal * 5.05 * side + a.up * 0.65
			var end: Vector3 = b.position + b.normal * 5.05 * side + b.up * 0.65
			glass_batches.append(NeonGeometry.beam_transform(begin, end, 0.06, 1.25))
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
		NeonGeometry.batch_boxes(self, batch, view_material(Color("29d8f2") if side_index == 0 else Color("ff9c3f"), 3.0))
	var glass := view_material(Color(0.15, 0.5, 0.7, 0.11), 0, 0.1, 0.15).duplicate() as StandardMaterial3D
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	NeonGeometry.batch_boxes(self, glass_batches, glass)
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

func _create_city() -> void:
	city_root = Node3D.new()
	add_child(city_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = track.seed_value + 91081
	var buildings: Array[Transform3D] = []
	var cyan_windows: Array[Transform3D] = []
	var amber_windows: Array[Transform3D] = []
	var outlines: Array[Transform3D] = []
	for z_index in range(-1, 21):
		for side in [-1, 1]:
			for row in range(2):
				var x: float = side * (57.0 + row * 32 + rng.randf_range(0, 7))
				var z := -z_index * 30.0 + rng.randf_range(-5, 5)
				var height := rng.randf_range(26, 80) + row * 15
				var width := rng.randf_range(13, 22)
				var depth := rng.randf_range(16, 23)
				buildings.append(Transform3D(Basis.IDENTITY.scaled(Vector3(width, height, depth)), Vector3(x, height / 2, z)))
				outlines.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.09, height, 0.09)), Vector3(x - side * width / 2, height / 2, z + depth / 2)))
				for floor_index in range(3, int(height) - 2, 4):
					for column in range(4):
						if rng.randf() < 0.60:
							continue
						var transform := Transform3D(Basis.IDENTITY.scaled(Vector3(1.2, 1.6, 0.06)), Vector3(x - width * 0.35 + column * width * 0.22, floor_index, z + depth / 2 + 0.04))
						var side_transform := Transform3D(Basis.IDENTITY.scaled(Vector3(0.06, 1.4, 1.3)), Vector3(x - side * width / 2 - side * 0.04, floor_index, z - depth * 0.35 + column * depth * 0.23))
						if side == -1:
							cyan_windows.append(transform)
							cyan_windows.append(side_transform)
						else:
							amber_windows.append(transform)
							amber_windows.append(side_transform)
				if row == 0 and z_index % 3 == 0:
					var sign := Label3D.new()
					sign.text = ["M / O", "NEON", "OVERDRIVE", "夜 CITY"][posmod(z_index, 4)]
					sign.position = Vector3(x, minf(height - 4, 32), z + depth / 2 + 0.1)
					sign.font_size = 90
					sign.pixel_size = 0.055
					sign.modulate = Color("44e6ff") if side == -1 else Color("ffad54")
					city_root.add_child(sign)
	NeonGeometry.batch_boxes(city_root, buildings, view_material(Color("253249"), 0, 0.45, 0.4))
	NeonGeometry.batch_boxes(city_root, cyan_windows, view_material(Color("16445e"), 0.5))
	NeonGeometry.batch_boxes(city_root, amber_windows, view_material(Color("68442e"), 0.5))
	NeonGeometry.batch_boxes(city_root, outlines, view_material(Color("2c748c"), 1.5))
	NeonGeometry.box(city_root, Vector3(0, -0.4, -260), Vector3(350, 0.5, 760), view_material(Color("061324"), 0, 0.6, 0.28))
	for x in [-45, 45]:
		NeonGeometry.box(city_root, Vector3(x, -0.08, -260), Vector3(0.15, 0.1, 760), view_material(Color("1b5779"), 1))

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

func _city_details() -> void:
	var frame := view_material(Color("244b63"), 0, 0.7)
	var neon := view_material(Color("438eb7"), 0.8)
	var warm := view_material(Color("b36880"), 0.5)
	var frames: Array[Transform3D] = []
	var trims: Array[Transform3D] = []
	for z in range(30, -620, -40):
		for side in [-1, 1]:
			var x: float = side * 46.0
			frames.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.6, 24, 0.6)), Vector3(x, 12, z)))
			trims.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.12, 8, 0.15)), Vector3(x - side * 0.35, 18, z)))
			NeonGeometry.box(city_root, Vector3(x - side * 1.2, 24, z), Vector3(3, 0.15, 0.5), neon)
			# Layered rooftop antennas and stepped building crowns.
			NeonGeometry.box(city_root, Vector3(side * 62, 54, z - 5), Vector3(8, 3, 11), frame)
			NeonGeometry.box(city_root, Vector3(side * 62, 60, z - 5), Vector3(0.25, 10, 0.25), neon)
			NeonGeometry.box(city_root, Vector3(side * 49, 29, z - 12), Vector3(0.4, 8, 4), warm)
			var shop := Label3D.new()
			shop.text = "ION\nLAB" if posmod(z, 80) == 30 else "M/O\nZEN"
			shop.position = Vector3(side * 48.7, 29, z - 12)
			shop.rotation.y = -side * PI / 2
			shop.font_size = 80
			shop.pixel_size = 0.018
			shop.modulate = Color("f5bedb")
			city_root.add_child(shop)
	NeonGeometry.batch_boxes(city_root, frames, frame)
	NeonGeometry.batch_boxes(city_root, trims, neon)
	NeonGeometry.box(city_root, Vector3(-43, 41, -260), Vector3(2.6, 0.4, 650), frame)
	NeonGeometry.box(city_root, Vector3(-43, 41.3, -260), Vector3(0.1, 0.1, 650), neon)
	transit = Node3D.new()
	city_root.add_child(transit)
	NeonGeometry.box(transit, Vector3.ZERO, Vector3(2.5, 2.5, 12), view_material(Color("637c98"), 0, 0.6))
	NeonGeometry.box(transit, Vector3(0, 0.6, -1), Vector3(2.6, 0.7, 8), neon)
	NeonGeometry.box(transit, Vector3(0, -0.9, 0), Vector3(2.6, 0.15, 12), warm)

func _create_cursors() -> void:
	for i in range(2):
		var node := Node3D.new()
		add_child(node)
		var tint := Color("34e4ef") if i == 0 else Color("ffb14a")
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
	if transit:
		transit.position = Vector3(-43, 43, 45 - fmod(clock * 14, 650))
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
		effect.node.scale = Vector3.ONE * maxf(0.1, (1 - effect.time / 0.5) * 16)
		if effect.time <= 0:
			effect.node.queue_free()
	pulse_positions = pulse_positions.filter(func(effect): return effect.time > 0)


