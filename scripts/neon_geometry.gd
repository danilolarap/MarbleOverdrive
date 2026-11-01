class_name NeonGeometry
extends RefCounted
## Shared native 3D primitives; no external models or textures.
const MESH_CACHE_LIMIT := 512
static var _mesh_cache: Dictionary = {}

static func shared_mesh(kind: String, parameters: Variant) -> PrimitiveMesh:
	# Exact parameter bytes avoid rounding geometry. Weak references do not keep
	# completed races alive; the entry cap bounds metadata across arbitrary seeds.
	var key := kind + ":" + var_to_bytes(parameters).hex_encode()
	if _mesh_cache.has(key):
		var existing = _mesh_cache[key].get_ref()
		if existing != null:
			return existing
	if _mesh_cache.size() >= MESH_CACHE_LIMIT:
		for old_key in _mesh_cache.keys():
			if _mesh_cache[old_key].get_ref() == null:
				_mesh_cache.erase(old_key)
		if _mesh_cache.size() >= MESH_CACHE_LIMIT:
			_mesh_cache.erase(_mesh_cache.keys()[0])
	var mesh: PrimitiveMesh
	match kind:
		"box":
			var box_mesh := BoxMesh.new()
			box_mesh.size = parameters
			mesh = box_mesh
		"sphere":
			var sphere_mesh := SphereMesh.new()
			sphere_mesh.radius = parameters
			sphere_mesh.height = parameters * 2
			sphere_mesh.radial_segments = 32
			sphere_mesh.rings = 16
			mesh = sphere_mesh
		"ring":
			var torus_mesh := TorusMesh.new()
			torus_mesh.inner_radius = parameters[0] - parameters[1]
			torus_mesh.outer_radius = parameters[0] + parameters[1]
			torus_mesh.rings = 32
			torus_mesh.ring_segments = 8
			mesh = torus_mesh
		"cylinder":
			var cylinder_mesh := CylinderMesh.new()
			cylinder_mesh.bottom_radius = parameters[0]
			cylinder_mesh.height = parameters[1]
			cylinder_mesh.top_radius = parameters[2]
			cylinder_mesh.radial_segments = int(parameters[3])
			mesh = cylinder_mesh
	_mesh_cache[key] = weakref(mesh)
	return mesh

static func material(color: Color, emission: float = 0.0, metallic: float = 0.0, roughness: float = 0.4) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	if emission > 0:
		if emission >= 0.5:
			result.albedo_color = color.darkened(0.65)
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = minf(emission, 0.8)
	return result

static func box(parent: Node3D, at: Vector3, dimensions: Vector3, surface: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shared_mesh("box", dimensions)
	instance.material_override = surface
	instance.position = at
	parent.add_child(instance)
	return instance

static func beam(parent: Node3D, begin: Vector3, end: Vector3, width: float, height: float, surface: Material) -> MeshInstance3D:
	var instance := box(parent, (begin + end) / 2, Vector3(width, height, begin.distance_to(end) + 0.04), surface)
	instance.basis = Basis.looking_at(end - begin, Vector3.UP)
	return instance

static func sphere(parent: Node3D, radius: float, surface: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shared_mesh("sphere", radius)
	instance.material_override = surface
	parent.add_child(instance)
	return instance

static func ring(parent: Node3D, radius: float, thickness: float, surface: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shared_mesh("ring", PackedFloat64Array([radius, thickness]))
	instance.material_override = surface
	parent.add_child(instance)
	return instance

static func beam_transform(begin: Vector3, end: Vector3, width: float, height: float) -> Transform3D:
	var basis := Basis.looking_at(end - begin, Vector3.UP)
	return Transform3D(Basis(basis.x * width, basis.y * height, basis.z * (begin.distance_to(end) + 0.05)), (begin + end) / 2)

static func batch_boxes(parent: Node3D, transforms: Array[Transform3D], surface: Material) -> MultiMeshInstance3D:
	var batch := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = shared_mesh("box", Vector3.ONE)
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
	batch.multimesh = multimesh
	batch.material_override = surface
	parent.add_child(batch)
	return batch

static func consolidate_boxes(parent: Node3D) -> void:
	# Call only after constructing static decoration, never on moving items.
	# Preserve exact transforms and material identity while reducing submissions.
	var groups: Dictionary = {}
	for child in parent.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var material: Material = child.material_override
			var key := material.get_instance_id()
			if not groups.has(key):
				groups[key] = {"material": material, "transforms": []}
			groups[key].transforms.append(child.transform * Transform3D(Basis.IDENTITY.scaled(child.mesh.size), Vector3.ZERO))
			child.free()
	for entry in groups.values():
		var transforms: Array[Transform3D] = []
		transforms.assign(entry.transforms)
		batch_boxes(parent, transforms, entry.material)
