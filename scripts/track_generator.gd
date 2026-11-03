class_name TrackGenerator
extends RefCounted
## Seeded modules in 3D, with continuous deck edges and real elevation.
const WIDTH := 10.0
const STEP := 2.0
const SAMPLES := 34
const DEFAULT_LEVEL := 0.7
## Slope limits as rise/run per 2 m step. Gap connectors are never driven on, so they may be steeper.
const MAX_SLOPE := 0.62
const MAX_GAP_SLOPE := 1.0
const MAX_BEND := 0.19
const MAX_GAP_BEND := 0.36
## Placement and recovery keep clear of gaps: nothing sits on or just before a lip.
const GAP_NO_PLACE_BEFORE := 10.0
const GAP_NO_PLACE_AFTER := 4.0
## Run-up: restarting at 12 m/s, 24 m of acceleration reaches ~31 m/s, above the 22 m/s a jump needs.
const GAP_RECOVERY_BACK := 24.0
const GAP_HAZARD_CLEARANCE := 40.0
var points := PackedVector3Array()
var distances := PackedFloat32Array()
var sections: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
## Each gap is {start, end, cells, drop, section}: the deck, rails and collision are absent between
## start and end, while `points` stays continuous so closest()/sample_at() keep working.
var gaps: Array[Dictionary] = []
var genome: Array[Dictionary] = []
var used_fallback := false
var level_value := DEFAULT_LEVEL
var total_length := 0.0
var seed_value := 1

## `level` (0 gentle .. 1 extreme) sets the target difficulty the evolutionary designer aims for.
func generate(course_seed: int, level: float = DEFAULT_LEVEL) -> bool:
	seed_value = course_seed
	level_value = clampf(level, 0.0, 1.0)
	used_fallback = false
	genome = TrackAI.new().evolve(course_seed, level_value)
	if _build(genome) and validate():
		return true
	# Safety net: the pre-AI layout is deterministic and always valid.
	used_fallback = true
	genome = TrackAI.legacy_genome(course_seed)
	return _build(genome) and validate()

func _build(plan: Array[Dictionary]) -> bool:
	points.clear()
	distances.clear()
	sections.clear()
	hazards.clear()
	gaps.clear()
	total_length = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var origin := Vector3(0, TrackAI.START_Y, 0)
	points.append(origin)
	distances.append(0)
	var sequence: Array[Dictionary] = [{"kind": "straight", "dy": 0.0, "cells": 0, "pairs": 0}]
	sequence.append_array(plan)
	sequence.append({"kind": "finish", "dy": 0.0, "cells": 0, "pairs": 0})
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	for section_index in range(sequence.size()):
		var gene: Dictionary = sequence[section_index]
		var kind: String = gene.kind
		var start := total_length
		var base_index := points.size() - 1
		var end_x := side * rng.randf_range(22, 31)
		# Straight sections, jumps and plunges keep their heading: the marble is not steered in the air.
		if kind in ["straight", "finish", "jump", "plunge"]:
			end_x = origin.x
		var drop := TrackAI.landing_drop(gene)
		var gap_first := SAMPLES / 2
		var gap_last: int = gap_first + int(gene.cells)
		for sample_index in range(1, SAMPLES + 1):
			var t := sample_index / float(SAMPLES)
			var blend := t * t * (3 - 2 * t)
			var height: float = origin.y + gene.dy * blend
			if kind == "jump":
				var c := clampf((sample_index - gap_first) / float(gene.cells), 0.0, 1.0)
				height -= drop * c * c * (3 - 2 * c)
			var point := Vector3(lerpf(origin.x, end_x, blend), height, origin.z - 68 * t)
			total_length += points[-1].distance_to(point)
			points.append(point)
			distances.append(total_length)
		sections.append({"kind": kind, "start": start, "end": total_length})
		if kind == "jump":
			gaps.append({"start": distances[base_index + gap_first], "end": distances[base_index + gap_last], "cells": gene.cells, "drop": drop, "section": section_index})
		var pairs: int = gene.pairs if kind in ["hazard", "curve"] else 0
		if pairs > 0:
			for factor in TrackAI.HAZARD_FACTORS[pairs]:
				var distance: float = lerpf(start, total_length, factor)
				var sample := sample_at(distance)
				var offset := rng.randf_range(1.5, 2.2)
				# Mirrored neutral hazards give both assigned halves the same risk.
				for hazard_side in [-1, 1]:
					hazards.append({"position": sample.position + sample.normal * offset * hazard_side, "radius": 0.9})
		origin = points[-1]
		side *= -1
	return true

func validate() -> bool:
	if points.size() < 3 or WIDTH < 6 * 0.8 or total_length < 500:
		return false
	for i in range(1, points.size()):
		var segment := points[i] - points[i - 1]
		var loose := is_gap_segment(i - 1) or (i > 1 and is_gap_segment(i - 2))
		if not points[i].is_finite() or segment.z >= 0 or segment.length() > 4:
			return false
		if absf(segment.y / segment.z) > (MAX_GAP_SLOPE if is_gap_segment(i - 1) else MAX_SLOPE):
			return false
		if points[i].y < TrackAI.MIN_Y - 3 or points[i].y > TrackAI.MAX_Y + 4:
			return false
		if i > 1:
			var previous := (points[i - 1] - points[i - 2]).normalized()
			if previous.angle_to(segment.normalized()) > (MAX_GAP_BEND if loose else MAX_BEND):
				return false
	for i in range(1, sections.size()):
		if absf(sections[i].start - sections[i - 1].end) > 0.01:
			return false
	for gap in gaps:
		# Never in the opening run, the finish approach, or taller than a marble can safely drop.
		if gap.start < 100 or gap.end > total_length - 80 or gap.drop > TrackAI.MAX_LANDING_DROP:
			return false
	if hazards.size() > TrackAI.MAX_HAZARD_PAIRS * 2:
		return false
	for hazard in hazards:
		var nearest := closest(hazard.position)
		var offset: float = absf((hazard.position - nearest.position).dot(nearest.normal))
		if WIDTH / 2 - offset - hazard.radius < 2 * 0.8:
			return false
		if is_gap(nearest.distance, GAP_HAZARD_CLEARANCE, 12.0):
			return false
	return true

## True when `distance` lies inside a gap, widened by `before` metres ahead of the lip and `after` past the landing.
func is_gap(distance: float, before: float = 0.0, after: float = 0.0) -> bool:
	for gap in gaps:
		if distance >= gap.start - before and distance <= gap.end + after:
			return true
	return false

## Whether the deck segment between points[i] and points[i + 1] is missing.
func is_gap_segment(i: int) -> bool:
	if gaps.is_empty() or i < 0 or i >= points.size() - 1:
		return false
	return is_gap((distances[i] + distances[i + 1]) / 2)

func is_placement_blocked(distance: float) -> bool:
	return is_gap(distance, GAP_NO_PLACE_BEFORE, GAP_NO_PLACE_AFTER)

## Where a marble that fell or got stuck at `progress` is put back: before the lip if it failed a jump.
func recovery_distance(progress: float) -> float:
	for gap in gaps:
		if progress >= gap.start - 1.0 and progress <= gap.end + 1.0:
			return maxf(0.0, gap.start - GAP_RECOVERY_BACK)
	return progress

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
		if is_gap_segment(i):
			continue
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
