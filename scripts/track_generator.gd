class_name TrackGenerator
extends RefCounted
## Seeded modules in 3D, with continuous deck edges and real elevation.
const WIDTH := 10.0
const STEP := 2.0
const MODULES := ["straight", "curve", "ramp", "drop", "hazard"]
const SAMPLES := 34
var points := PackedVector3Array()
var distances := PackedFloat32Array()
var sections: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var total_length := 0.0
var seed_value := 1

func generate(course_seed: int) -> bool:
	seed_value = course_seed
	points.clear()
	distances.clear()
	sections.clear()
	hazards.clear()
	total_length = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = course_seed
	var origin := Vector3(0, 22, 0)
	points.append(origin)
	distances.append(0)
	var sequence: Array[String] = ["straight"]
	var shuffled := MODULES.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporary: String = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temporary
	for kind in shuffled:
		sequence.append(kind)
	sequence.append("curve")
	sequence.append("finish")
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	for kind in sequence:
		var start := total_length
		var end_x := side * rng.randf_range(22, 31)
		var end_y := origin.y
		if kind in ["straight", "finish"]:
			end_x = origin.x
		if kind == "ramp":
			end_y += rng.randf_range(7, 10)
		elif kind == "drop":
			end_y -= rng.randf_range(10, 13)
		elif kind == "curve":
			end_y += rng.randf_range(-2, 2)
		end_y = clampf(end_y, 12, 36)
		for sample_index in range(1, SAMPLES + 1):
			var t := sample_index / float(SAMPLES)
			var blend := t * t * (3 - 2 * t)
			var point := Vector3(lerpf(origin.x, end_x, blend), lerpf(origin.y, end_y, blend), origin.z - 68 * t)
			total_length += points[-1].distance_to(point)
			points.append(point)
			distances.append(total_length)
		sections.append({"kind": kind, "start": start, "end": total_length})
		if kind == "hazard":
			for factor in [0.32, 0.70]:
				var distance: float = lerpf(start, total_length, factor)
				var sample := sample_at(distance)
				var offset := rng.randf_range(1.5, 2.2)
				# Mirrored neutral hazards give both assigned halves the same risk.
				for hazard_side in [-1, 1]:
					hazards.append({"position": sample.position + sample.normal * offset * hazard_side, "radius": 0.9})
		origin = points[-1]
		side *= -1
	return validate()

func validate() -> bool:
	if points.size() < 3 or WIDTH < 6 * 0.8 or total_length < 500:
		return false
	for i in range(1, points.size()):
		var segment := points[i] - points[i - 1]
		if not points[i].is_finite() or segment.z >= 0 or segment.length() > 4 or absf(segment.y / segment.z) > 0.32:
			return false
		if i > 1:
			var previous := (points[i - 1] - points[i - 2]).normalized()
			if previous.angle_to(segment.normalized()) > 0.19:
				return false
	for i in range(1, sections.size()):
		if absf(sections[i].start - sections[i - 1].end) > 0.01:
			return false
	for hazard in hazards:
		var nearest := closest(hazard.position)
		var offset: float = absf((hazard.position - nearest.position).dot(nearest.normal))
		if WIDTH / 2 - offset - hazard.radius < 2 * 0.8:
			return false
	return true

func sample_at(distance: float) -> Dictionary:
	distance = clampf(distance, 0, total_length)
	var low := 0
	var high := distances.size() - 2
	while low < high:
		var middle := (low + high) / 2
		if distances[middle + 1] < distance:
			low = middle + 1
		else:
			high = middle
	var index := low
	var fraction := (distance - distances[index]) / maxf(0.001, distances[index + 1] - distances[index])
	var tangent := (points[index + 1] - points[index]).normalized()
	var lateral := tangent.cross(Vector3.UP).normalized()
	var up := lateral.cross(tangent).normalized()
	return {"position": points[index].lerp(points[index + 1], fraction), "tangent": tangent, "normal": lateral, "up": up, "distance": distance}

func closest(location: Vector3) -> Dictionary:
	# Z is strictly decreasing (validated at generation). Binary-search the
	# containing segment, then expand only while a segment's Z interval can
	# beat the best full 3D distance. This remains exact even far off the road.
	var low := 0
	var high := points.size() - 2
	while low < high:
		var middle := (low + high) / 2
		if points[middle + 1].z > location.z:
			low = middle + 1
		else:
			high = middle
	var best_index := low
	var best_point := Geometry3D.get_closest_point_to_segment(location, points[low], points[low + 1])
	var best := location.distance_squared_to(best_point)
	var left := low - 1
	var right := low + 1
	while left >= 0 or right < points.size() - 1:
		var left_bound := INF if left < 0 else maxf(0, points[left + 1].z - location.z)
		var right_bound := INF if right >= points.size() - 1 else maxf(0, location.z - points[right].z)
		if left_bound * left_bound > best:
			left = -1
			left_bound = INF
		if right_bound * right_bound > best:
			right = points.size() - 1
			right_bound = INF
		if left_bound == INF and right_bound == INF:
			break
		var index := left if left_bound <= right_bound else right
		if index == left:
			left -= 1
		else:
			right += 1
		var nearest := Geometry3D.get_closest_point_to_segment(location, points[index], points[index + 1])
		var squared := location.distance_squared_to(nearest)
		if squared < best or (squared == best and index < best_index):
			best = squared
			best_index = index
			best_point = nearest
	return sample_at(distances[best_index] + points[best_index].distance_to(best_point))

func section_at(distance: float) -> String:
	for section in sections:
		if distance <= section.end:
			return section.kind
	return "finish"

func build_walls(parent: Node) -> void:
	var body := StaticBody3D.new()
	body.name = "RoadAndRailsCollision"
	body.collision_layer = 1
	body.collision_mask = 12
	parent.add_child(body)
	var faces := PackedVector3Array()
	for i in range(points.size() - 1):
		var a := sample_at(distances[i])
		var b := sample_at(distances[i + 1])
		var left_a: Vector3 = a.position - a.normal * WIDTH / 2
		var right_a: Vector3 = a.position + a.normal * WIDTH / 2
		var left_b: Vector3 = b.position - b.normal * WIDTH / 2
		var right_b: Vector3 = b.position + b.normal * WIDTH / 2
		faces.append_array(PackedVector3Array([left_a, left_b, right_a, right_a, left_b, right_b]))
		for side in [-1, 1]:
			var begin: Vector3 = a.position + a.normal * (WIDTH / 2 + 0.1) * side + a.up * 0.85
			var end: Vector3 = b.position + b.normal * (WIDTH / 2 + 0.1) * side + b.up * 0.85
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.22, 1.9, begin.distance_to(end) + 0.08)
			var collider := CollisionShape3D.new()
			collider.shape = shape
			collider.position = (begin + end) / 2
			collider.basis = Basis.looking_at(end - begin, Vector3.UP)
			body.add_child(collider)
	var surface := ConcavePolygonShape3D.new()
	surface.backface_collision = true
	surface.set_faces(faces)
	var deck := CollisionShape3D.new()
	deck.shape = surface
	body.add_child(deck)
