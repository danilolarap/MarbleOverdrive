class_name DistrictKit
extends Node3D
## Decoration only. All geometry stays outside the validated racing corridor.
## Batches are split into 80 m cells, allowing real frustum/distance culling.
const PROFILES := {
	"CITY": preload("res://environments/downtown.tres"),
	"FACTORY": preload("res://environments/power.tres"),
	"TRANSIT": preload("res://environments/transit.tres")
}
var profile: DistrictProfile
var course_seed := 42
var economy := false
var rng := RandomNumberGenerator.new()
var batches: Dictionary = {}
var surfaces: Dictionary = {}
var trains: Array[Node3D] = []
var elapsed := 0.0

func _ready() -> void:
	rng.seed = course_seed + 91081
	for key in ["metal", "concrete"]:
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/architecture.gdshader")
		material.set_shader_parameter("tint", profile.get(key))
		surfaces[key] = material
	surfaces.trim = NeonGeometry.material(Color("19262e"), 0, 0.55, 0.5)
	surfaces.window = NeonGeometry.material(profile.warm.darkened(0.25), 0.38)
	surfaces.accent = NeonGeometry.material(profile.accent, 0.55)
	surfaces.yellow = NeonGeometry.material(Color("c6ce64"), 0, 0.3)
	for key in ["sign_cyan", "sign_yellow"]:
		var sign_material := ShaderMaterial.new()
		sign_material.shader = preload("res://shaders/signage.gdshader")
		sign_material.set_shader_parameter("tint", profile.accent if key == "sign_cyan" else Color("d3cb67"))
		surfaces[key] = sign_material
	# Low service level, roads and parapets establish the height of the circuit.
	add_box("trim", Vector3(0, -6, -260), Vector3(520, 3, 900))
	for side in [-1, 1]:
		for z in range(40, -620, -38):
			# Rooftops below the lowest drivable deck (12 m); no colliders.
			var roof_height := rng.randf_range(3, 7)
			add_box("metal", Vector3(side * 22, roof_height / 2 - 3, z), Vector3(24, roof_height, 25))
			add_box("concrete", Vector3(side * 22, roof_height - 2.7, z), Vector3(25, 0.4, 26))
			add_box("trim", Vector3(side * 22, roof_height - 1.5, z - 3), Vector3(8, 2, 9))
		add_box("metal", Vector3(side * 48, 4, -260), Vector3(12, 8, 740))
		add_box("concrete", Vector3(side * 48, 8.2, -260), Vector3(12, 0.4, 740))
		for z in range(70, -670, -20):
			add_box("window", Vector3(side * 47, 8.5, z), Vector3(0.16, 0.1, 6))
		for layer in range(2 if economy else 3):
			for index in range(-2, 19):
				var x: float = side * (63 + layer * 53 + rng.randf_range(-3, 6))
				var z := -index * profile.spacing + rng.randf_range(-6, 6)
				var height := rng.randf_range(30, 74) * profile.tower_height + layer * 18
				if profile.industrial and layer == 0:
					height = rng.randf_range(20, 34)
				build_tower(Vector3(x, 0, z), Vector3(rng.randf_range(18, 27), height, rng.randf_range(20, 28)), side, layer, index)
		for z in range(35, -640, -75):
			# Service ducts, platforms and diagonal braces, all beyond |x|=42.
			add_box("concrete", Vector3(side * 46, 18, z), Vector3(7, 1, 14))
			add_box("metal", Vector3(side * 45, 9, z), Vector3(1.4, 18, 1.4))
			add_beam("trim", Vector3(side * 43, 18, z - 6), Vector3(side * 53, 9, z - 6), 0.6, 0.6)
			add_box("yellow", Vector3(side * 42.6, 18.7, z), Vector3(0.15, 0.25, 12))
			if profile.industrial:
				for y in [12, 14]:
					add_box("metal", Vector3(side * 46, y, z - 30), Vector3(1.2, 1.2, 74))
		# Elevated transit stays alongside the circuit, never crossing camera sightlines.
		var rail_y := 46.0 if profile.transit_hub else 12.0
		add_box("metal", Vector3(side * 50, rail_y, -260), Vector3(4, 1.2, 740))
		add_box("accent", Vector3(side * 48, rail_y + 0.4, -260), Vector3(0.08, 0.12, 740))
		if profile.transit_hub:
			for z in range(20, -640, -110):
				add_box("concrete", Vector3(side * 56, rail_y + 6, z), Vector3(17, 1.2, 35))
				add_box("metal", Vector3(side * 62, rail_y / 2, z), Vector3(2, rail_y, 3))
		var train := Node3D.new()
		add_child(train)
		train.position = Vector3(side * 50, rail_y + 2, 0)
		for car in range(3):
			NeonGeometry.box(train, Vector3(0, 0, car * 10), Vector3(3, 2.5, 9), surfaces.concrete)
			NeonGeometry.box(train, Vector3(-side * 1.52, 0.3, car * 10), Vector3(0.05, 0.65, 7), surfaces.accent)
		NeonGeometry.consolidate_boxes(train)
		trains.append(train)
	flush_batches()

func build_tower(origin: Vector3, dimensions: Vector3, side: int, layer: int, index: int) -> void:
	var height := dimensions.y
	var face_x := origin.x - side * (dimensions.x / 2 + 0.06)
	add_box("metal" if posmod(index, 3) else "concrete", origin + Vector3.UP * height / 2, dimensions)
	add_box("trim", origin + Vector3.UP * (height + 0.5), Vector3(dimensions.x + 1.3, 1, dimensions.z + 1.3))
	add_box("concrete", origin + Vector3(2, height + 3, -2), Vector3(dimensions.x * 0.52, 6, dimensions.z * 0.58))
	# Strong vertical ribs and blank floor bands balance the illuminated windows.
	for edge in [-1, 1]:
		add_box("trim", Vector3(face_x, height / 2, origin.z + edge * dimensions.z * 0.42), Vector3(0.8, height, 1.2))
	for floor_y in range(8, int(height) - 2, 5 if layer == 0 else 9):
		for column in range(4):
			if rng.randf() < 0.48:
				continue
			add_box("window", Vector3(face_x, floor_y, origin.z + (column - 1.5) * dimensions.z * 0.21), Vector3(0.08, 0.8, 2.7))
			add_box("window", Vector3(origin.x + (column - 1.5) * dimensions.x * 0.2, floor_y, origin.z + dimensions.z / 2 + 0.06), Vector3(2.7, 0.8, 0.08))
	if layer > 0:
		return
	# Vent housings, fins, conduits and antennas share the same batched cube mesh.
	add_box("trim", origin + Vector3(0, height + 7, 0), Vector3(6, 2, 5))
	for fin in range(5):
		add_box("concrete", origin + Vector3(-2 + fin, height + 8.1, 0), Vector3(0.22, 0.3, 4.5))
	add_box("metal", origin + Vector3(6, height + 7, 6), Vector3(0.22, 14, 0.22))
	add_box("accent", origin + Vector3(6, height + 14, 6), Vector3(0.35, 0.3, 0.35))
	if profile.industrial:
		for offset in [-5, 5]:
			add_box("concrete", origin + Vector3(offset, height + 8, 0), Vector3(3, 16, 3))
			add_box("yellow", origin + Vector3(offset, height + 12, 0), Vector3(3.1, 1.3, 3.1))
	if posmod(index, 3) == 0:
		billboard(Vector3(face_x - side * 0.3, minf(height - 6, 30), origin.z), side, index)
	if posmod(index, 3) == 1:
		add_box("concrete", Vector3(face_x, 15, origin.z), Vector3(2.5, 4, dimensions.z + 4))

func billboard(at: Vector3, side: int, index: int) -> void:
	var mount := Node3D.new()
	mount.position = at
	mount.rotation.y = -side * PI / 2
	add_child(mount)
	var material: Material = surfaces.sign_cyan if posmod(index, 2) else surfaces.sign_yellow
	NeonGeometry.box(mount, Vector3.ZERO, Vector3(13, 7, 0.5), surfaces.trim)
	NeonGeometry.box(mount, Vector3(0, 0, 0.28), Vector3(12.5, 6.5, 0.06), material)
	var label := Label3D.new()
	label.text = ["M / O\nAFTER HOURS", "VECTOR\nTRANSIT", "ION WORKS\n" + profile.code][posmod(index / 3, 3)]
	label.font_size = 64
	label.pixel_size = 0.032
	label.position.z = 0.35
	label.modulate = Color("d9e2d6")
	label.outline_size = 0
	mount.add_child(label)
	for child in mount.get_children():
		if child is GeometryInstance3D:
			child.visibility_range_end = 190 if economy else 290

func add_box(surface: String, at: Vector3, dimensions: Vector3) -> void:
	put(surface, Transform3D(Basis.IDENTITY.scaled(dimensions), at))

func add_beam(surface: String, a: Vector3, b: Vector3, width: float, height: float) -> void:
	put(surface, NeonGeometry.beam_transform(a, b, width, height))

func put(surface: String, transform: Transform3D) -> void:
	var key := surface + ":" + str(floori(transform.origin.z / 80)) + ":" + str(floori(transform.origin.x / 80))
	if not batches.has(key):
		batches[key] = {"surface": surface, "transforms": []}
	batches[key].transforms.append(transform)

func flush_batches() -> void:
	for entry in batches.values():
		var transforms: Array[Transform3D] = []
		transforms.assign(entry.transforms)
		var batch := NeonGeometry.batch_boxes(self, transforms, surfaces[entry.surface])
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch.visibility_range_end = 260 if economy else 440
		batch.visibility_range_end_margin = 20
	batches.clear()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	for i in range(trains.size()):
		trains[i].position.z = 90 - fposmod(elapsed * (13 if i == 0 else -10) + i * 220, 740)
