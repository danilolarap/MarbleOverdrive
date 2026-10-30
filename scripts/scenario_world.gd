class_name ScenarioWorld
extends Node3D
## Twelve original geometric environments share the same competitive road physics.
var scenario_id := "PLAYGROUND"
var course_seed := 42
var motors: Array[Node3D] = []
var water_material: ShaderMaterial
var rng := RandomNumberGenerator.new()
var dark: StandardMaterial3D
var accent: StandardMaterial3D
var soft: StandardMaterial3D
var _materials: Dictionary = {}

func scene_material(color: Color, emission: float = 0.0, metallic: float = 0.0, roughness: float = 0.4) -> StandardMaterial3D:
	# Scenery surfaces are immutable and owned only by this environment.
	var key := var_to_bytes([color, emission, metallic, roughness]).hex_encode()
	if not _materials.has(key):
		_materials[key] = NeonGeometry.material(color, emission, metallic, roughness)
	return _materials[key]

func _ready() -> void:
	rng.seed = course_seed + GameCatalog.SCENARIOS.find(scenario_id) * 7301
	var colors: Array = GameCatalog.WORLD_COLORS[scenario_id]
	dark = scene_material(colors[0].lightened(0.12), 0, 0.3)
	accent = scene_material(colors[1], 0.8)
	soft = scene_material(colors[1].darkened(0.35), 0, 0.1)
	NeonGeometry.box(self, Vector3(0, -1, -260), Vector3(340, 1, 760), dark)
	for section in range(-1, 11):
		for side in [-1, 1]:
			var origin := Vector3(side * rng.randf_range(57, 70), 0, -section * 55.0)
			var prop := Node3D.new()
			prop.position = origin
			add_child(prop)
			match scenario_id:
				"PLAYGROUND": playground(prop, section)
				"ZOO": zoo(prop, section)
				"SPACEPORT": spaceport(prop, section)
				"VOLCANO": volcano(prop)
				"ICE": ice(prop)
				"OCEAN": ocean(prop, section)
				"JUNGLE": jungle(prop)
				"DESERT": desert(prop, section)
				"CANDY": candy(prop, section)
				"FACTORY": factory(prop, section)
				"SKY_GARDENS": gardens(prop)
	if scenario_id == "OCEAN":
		var water := NeonGeometry.box(self, Vector3(0, 0.3, -260), Vector3(340, 0.2, 760), soft)
		water_material = ShaderMaterial.new()
		water_material.shader = preload("res://shaders/water.gdshader")
		water.material_override = water_material
	# A distinctive entrance sign is readable on the first straight.
	var sign := Label3D.new()
	sign.text = tr("SCENE_" + scenario_id)
	sign.font_size = 100
	sign.pixel_size = 0.04
	sign.position = Vector3(-40, 30, -65)
	sign.modulate = GameCatalog.WORLD_COLORS[scenario_id][1]
	add_child(sign)

func cylinder(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, top: float = -1, sides: int = 16) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = NeonGeometry.shared_mesh("cylinder", PackedFloat64Array([radius, height, radius if top < 0 else top, sides]))
	node.material_override = material
	node.position = position
	parent.add_child(node)
	return node

func tree(parent: Node3D, position: Vector3, scale_value: float = 1) -> void:
	var stem := scene_material(Color("4c3c40"))
	cylinder(parent, position + Vector3.UP * 4 * scale_value, 0.6 * scale_value, 8 * scale_value, stem)
	var leaf := scene_material(Color("315f54"), 0, 0, 0.9)
	var crown := NeonGeometry.sphere(parent, 4 * scale_value, leaf)
	crown.position = position + Vector3.UP * 9 * scale_value
	crown.scale = Vector3(1, 1.4, 1)

func playground(parent: Node3D, index: int) -> void:
	if posmod(index, 2) == 0:
		var axle := Node3D.new()
		axle.position.y = 19
		parent.add_child(axle)
		var wheel := NeonGeometry.ring(axle, 14, 0.25, accent)
		wheel.rotation.x = PI / 2
		for i in range(10):
			var point := Vector3(cos(i * TAU / 10) * 14, sin(i * TAU / 10) * 14, 0)
			NeonGeometry.beam(axle, Vector3.ZERO, point, 0.12, 0.12, soft)
			NeonGeometry.box(axle, point - Vector3(0, 1, 0), Vector3(2.5, 2, 2), scene_material(Color.from_hsv(i / 10.0, 0.55, 0.8), 0.3))
		motors.append(axle)
		for x in [-5, 5]:
			NeonGeometry.beam(parent, Vector3(x, 0, -2), Vector3(0, 19, 0), 0.6, 0.6, dark)
	else:
		cylinder(parent, Vector3(0, 1, 0), 11, 2, soft)
		cylinder(parent, Vector3(0, 13, 0), 12, 5, accent, 1)
		for i in range(8):
			var p := Vector3(cos(i * TAU / 8) * 8, 6, sin(i * TAU / 8) * 8)
			cylinder(parent, p, 0.15, 10, accent)
			NeonGeometry.sphere(parent, 1.5, scene_material(Color.from_hsv(i / 8.0, 0.6, 0.9))).position = p

func zoo(parent: Node3D, index: int) -> void:
	parent.position.y = 12
	NeonGeometry.box(parent, Vector3(0, -6, 0), Vector3(28, 12, 30), dark)
	NeonGeometry.box(parent, Vector3(0, 0.3, 0), Vector3(27, 0.5, 29), scene_material(Color("335549")))
	for side in [-1, 1]:
		for n in range(-4, 5):
			cylinder(parent, Vector3(side * 14, 1.5, n * 3.5), 0.12, 3, soft)
		NeonGeometry.beam(parent, Vector3(side * 14, 2.3, -14), Vector3(side * 14, 2.3, 14), 0.1, 0.12, accent)
	var giraffe := posmod(index, 2) == 0
	var animal := scene_material(Color("caab6a").darkened(0.3) if giraffe else Color("8796ad").darkened(0.25), 0, 0, 0.8)
	var body := NeonGeometry.sphere(parent, 3.1, animal)
	body.position.y = 4 if giraffe else 3.6
	body.scale = Vector3(1.6, 0.9, 0.9)
	for x in [-2, 2]:
		for z in [-1.6, 1.6]:
			cylinder(parent, Vector3(x, 2, z), 0.35 if giraffe else 0.7, 4, animal)
	if giraffe:
		NeonGeometry.beam(parent, Vector3(2, 4, 0), Vector3(4, 11, 0), 1.2, 1.2, animal)
		var head := NeonGeometry.sphere(parent, 1.3, animal)
		head.position = Vector3(4.5, 11.6, 0)
		head.scale.x = 1.6
		for z in [-0.5, 0.5]:
			cylinder(parent, Vector3(4, 13, z), 0.12, 1.2, dark)
	else:
		NeonGeometry.sphere(parent, 2, animal).position = Vector3(3.8, 5.1, 0)
		for z in [-1.8, 1.8]:
			var ear := NeonGeometry.sphere(parent, 1.8, animal)
			ear.position = Vector3(3, 5.2, z)
			ear.scale = Vector3(0.3, 1, 1)
		NeonGeometry.beam(parent, Vector3(5.2, 4.6, 0), Vector3(6.2, 1.8, 0), 0.8, 0.8, animal)
	tree(parent, Vector3(-10, 0, -9))

func spaceport(parent: Node3D, index: int) -> void:
	cylinder(parent, Vector3(0, 1, 0), 12, 2, dark)
	NeonGeometry.ring(parent, 10, 0.18, accent).position.y = 2.1
	cylinder(parent, Vector3(0, 13, 0), 3, 22, scene_material(Color("afb8cc"), 0, 0.7))
	cylinder(parent, Vector3(0, 27, 0), 3, 7, soft, 0)
	for side in [-1, 1]:
		NeonGeometry.box(parent, Vector3(side * 3, 5, 0), Vector3(0.5, 7, 5), accent)
		NeonGeometry.box(parent, Vector3(side * 9, 17, 0), Vector3(1, 34, 1), dark)
	NeonGeometry.box(parent, Vector3(0, 29, -3), Vector3(20, 1, 1), soft)
	if posmod(index, 2) == 0:
		var dish := NeonGeometry.ring(parent, 6, 0.7, accent)
		dish.position = Vector3(-15, 18, 0)
		dish.rotation.x = 0.8

func volcano(parent: Node3D) -> void:
	var height := rng.randf_range(20, 38)
	cylinder(parent, Vector3(0, height / 2, 0), 22, height, dark, 6, 10)
	NeonGeometry.ring(parent, 5.8, 0.9, accent).position.y = height
	for i in range(4):
		var x := rng.randf_range(-5, 5)
		NeonGeometry.beam(parent, Vector3(x, height - 0.1, 5), Vector3(x * 2.4, 1, 20), 1.4, 0.3, accent)
		NeonGeometry.sphere(parent, rng.randf_range(1, 2), accent).position = Vector3(x, height + 4 + i * 3, 0)

func ice(parent: Node3D) -> void:
	for i in range(7):
		var height := rng.randf_range(8, 30)
		var node := cylinder(parent, Vector3(rng.randf_range(-12, 12), height / 2, rng.randf_range(-10, 10)), 3, height, soft if i % 2 == 0 else accent, 0, 5)
		node.rotation.z = rng.randf_range(-0.2, 0.2)

func ocean(parent: Node3D, index: int) -> void:
	cylinder(parent, Vector3(0, 1, 0), 14, 3, scene_material(Color("b5a27e").darkened(0.4)), 12)
	for i in range(3):
		tree(parent, Vector3(-7 + i * 6, 2, -4), 0.8)
	var tower := cylinder(parent, Vector3(8, 13, 4), 2, 24, scene_material(Color("d9d8d3")), 1.4)
	NeonGeometry.ring(parent, 2, 0.3, accent).position = tower.position + Vector3.UP * 12
	if posmod(index, 2) == 0:
		NeonGeometry.box(parent, Vector3(8, 26, 4), Vector3(3, 2, 3), accent)

func jungle(parent: Node3D) -> void:
	for i in range(6):
		tree(parent, Vector3(rng.randf_range(-13, 13), 0, rng.randf_range(-13, 13)), rng.randf_range(1.4, 2.2))
	NeonGeometry.box(parent, Vector3(0, 4, 0), Vector3(12, 8, 10), dark)
	for side in [-1, 1]:
		cylinder(parent, Vector3(side * 7, 10, 0), 1.3, 20, soft, 1)
	NeonGeometry.beam(parent, Vector3(-7, 20, 0), Vector3(7, 20, 0), 1, 1, accent)

func _process(delta: float) -> void:
	for motor in motors:
		motor.rotate_z(delta * 0.12)

