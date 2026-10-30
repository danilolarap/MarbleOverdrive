extends Node
var errors := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		errors += 1
		push_error(message)

func exhaustive_closest(track: TrackGenerator, location: Vector3) -> Dictionary:
	var best := INF
	var distance := 0.0
	for i in range(track.points.size() - 1):
		var nearest := Geometry3D.get_closest_point_to_segment(location, track.points[i], track.points[i + 1])
		var squared := location.distance_squared_to(nearest)
		if squared < best:
			best = squared
			distance = track.distances[i] + track.points[i].distance_to(nearest)
	return track.sample_at(distance)

func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 829343
	var count := 0
	for seed_value in range(1, 65):
		var track := TrackGenerator.new()
		check(track.generate(seed_value), "Track generation changed")
		var queries: Array[Vector3] = []
		for i in range(90):
			queries.append(Vector3(random.randf_range(-600, 600), random.randf_range(-150, 180), random.randf_range(-900, 200)))
		for i in range(0, track.points.size(), 11):
			queries.append(track.points[i])
			queries.append(track.points[i] + Vector3(0, 0.8, 0))
		for point in queries:
			var expected := exhaustive_closest(track, point)
			var actual := track.closest(point)
			check(absf(expected.distance - actual.distance) < 0.0001 and expected.position.distance_to(actual.position) < 0.0001, "Closest-point regression at seed %d / %s" % [seed_value, point])
			count += 1
	var first := NeonGeometry.shared_mesh("sphere", 0.8)
	var second := NeonGeometry.shared_mesh("sphere", 0.8)
	check(first == second, "Repeated sphere geometry was duplicated")
	var root := Node3D.new()
	add_child(root)
	var a := NeonGeometry.material(Color.CYAN)
	var b := NeonGeometry.material(Color.ORANGE)
	var batch_a := NeonGeometry.batch_boxes(root, [Transform3D.IDENTITY], a)
	var batch_b := NeonGeometry.batch_boxes(root, [Transform3D.IDENTITY], b)
	check(batch_a.multimesh.mesh == batch_b.multimesh.mesh, "Repeated batch geometry was duplicated")
	check(batch_a.material_override == a and batch_b.material_override == b, "Shared geometry leaked colors across batches")
	check(a != NeonGeometry.material(Color.CYAN), "Mutable material factories must remain independent")
	for i in range(800):
		NeonGeometry.shared_mesh("box", Vector3(i + 1, 2, 3))
	check(NeonGeometry._mesh_cache.size() <= NeonGeometry.MESH_CACHE_LIMIT, "Geometry cache metadata grows without bound")
	root.queue_free()
	print("PASS: %d exact closest-point comparisons, shared meshes, independent colors and bounded cache" % count if errors == 0 else "FAIL: optimization")
	get_tree().quit(0 if errors == 0 else 1)
