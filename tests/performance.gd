extends Node
## Reproducible CPU/resource measurements; does not assert a hardware FPS target.
func _ready() -> void:
	call_deferred("run")

func scene_metrics(node: Node, metrics: Dictionary, meshes: Dictionary, materials: Dictionary, bounds: Array) -> void:
	metrics.nodes += 1
	var mesh: Mesh
	var surface: Material
	if node is MeshInstance3D:
		mesh = node.mesh
		surface = node.material_override
		bounds.append([node.transform, mesh.get_aabb() if mesh else AABB()])
	elif node is MultiMeshInstance3D:
		mesh = node.multimesh.mesh
		surface = node.material_override
		metrics.multimesh_instances += node.multimesh.instance_count
	if mesh:
		metrics.mesh_nodes += 1
		meshes[mesh.get_instance_id()] = true
		if mesh.get_surface_count() > 0:
			var arrays := mesh.surface_get_arrays(0)
			metrics.vertices += arrays[Mesh.ARRAY_VERTEX].size()
			if surface == null:
				surface = mesh.surface_get_material(0)
		if surface:
			materials[surface.get_instance_id()] = true
	for child in node.get_children():
		scene_metrics(child, metrics, meshes, materials, bounds)

func run() -> void:
	var track := TrackGenerator.new()
	track.generate(42)
	var queries: Array[Vector3] = []
	for i in range(1000):
		var sample := track.sample_at(track.total_length * i / 1000.0)
		queries.append(sample.position + sample.normal * (1.65 if i % 2 else -1.65) + sample.up * 0.8)
	var timings: Array[float] = []
	for batch in range(5):
		var started := Time.get_ticks_usec()
		for point in queries:
			track.closest(point)
		timings.append((Time.get_ticks_usec() - started) / 1000.0)
	timings.sort()
	var report := {"closest_1000_median_ms": timings[2], "worlds": {}}
	for id in GameCatalog.SCENARIOS:
		var view := TrackView.new()
		view.track = track
		view.scenario_id = id
		var started := Time.get_ticks_usec()
		add_child(view)
		var metrics := {"nodes": 0, "mesh_nodes": 0, "multimesh_instances": 0, "vertices": 0}
		var meshes := {}
		var materials := {}
		var bounds := []
		scene_metrics(view, metrics, meshes, materials, bounds)
		metrics.unique_meshes = meshes.size()
		metrics.unique_materials = materials.size()
		metrics.bounds_hash = var_to_bytes(bounds).hex_encode().sha256_text()
		metrics.build_and_inspect_ms = (Time.get_ticks_usec() - started) / 1000.0
		report.worlds[id] = metrics
		view.free()
	var label := "after" if "--after" in OS.get_cmdline_user_args() else "before"
	var output := FileAccess.open("res://tools/performance-" + label + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("PERFORMANCE %s: closest x1000 median %.3f ms" % [label, timings[2]])
	for id in report.worlds:
		print("%s meshes=%d materials=%d vertices=%d" % [id, report.worlds[id].unique_meshes, report.worlds[id].unique_materials, report.worlds[id].vertices])
	get_tree().quit()
