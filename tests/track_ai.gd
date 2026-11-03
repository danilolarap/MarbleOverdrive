extends Node
## Evolutionary track designer: validity, determinism, difficulty control, and real physics through every gap.
## Run: godot --headless --path . --fixed-fps 120 res://tests/track_ai.tscn
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func mean_danger(track: TrackGenerator) -> float:
	var total := 0.0
	for gene in track.genome:
		total += TrackAI.danger(gene)
	return total / track.genome.size()

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var track := TrackGenerator.new()
	var with_jump: Array[int] = []
	var with_plunge := 0
	var fallbacks := 0
	var started := Time.get_ticks_usec()
	for course_seed in range(1, 301):
		check(track.generate(course_seed), "Seed %d failed validation" % course_seed)
		if track.used_fallback:
			fallbacks += 1
		check(track.sections.size() == 8 and track.genome.size() == TrackAI.FREE_GENES, "Seed %d has the wrong section count" % course_seed)
		var first := track.points.duplicate()
		var first_gaps := track.gaps.duplicate(true)
		track.generate(course_seed)
		check(first == track.points and first_gaps == track.gaps, "Seed %d is not deterministic" % course_seed)
		if not track.gaps.is_empty():
			with_jump.append(course_seed)
		for gene in track.genome:
			if gene.kind == "plunge":
				with_plunge += 1
				break
		for gap in track.gaps:
			check(gap.cells >= TrackAI.MIN_CELLS and gap.cells <= TrackAI.MAX_CELLS, "Gap width out of range")
			check(gap.drop <= TrackAI.MAX_LANDING_DROP, "Landing drop too tall")
			check(track.is_gap_segment(track.distances.find(gap.start)) , "Gap not registered on its first segment")
			check(track.recovery_distance((gap.start + gap.end) / 2) < gap.start - 10, "Recovery must restart well before the lip")
			check(not track.is_gap_segment(track.distances.find(gap.end)), "Deck must resume after the gap")
		for i in range(track.points.size() - 1):
			if not track.is_gap_segment(i):
				var slope := absf((track.points[i + 1].y - track.points[i].y) / (track.points[i + 1].z - track.points[i].z))
				check(slope <= TrackGenerator.MAX_SLOPE + 0.001, "Seed %d has an undrivable slope" % course_seed)
	var elapsed := (Time.get_ticks_usec() - started) / 1000.0
	print("AI: 300 seeds x2 in %.0f ms, %d with gaps, %d with plunges, %d fallbacks" % [elapsed, with_jump.size(), with_plunge, fallbacks])
	check(fallbacks == 0, "The evolutionary designer fell back to the classic layout %d times" % fallbacks)
	check(with_jump.size() > 150, "Gaps are too rare at the default level")
	# The difficulty level must actually steer the designer.
	var gentle := 0.0
	var extreme := 0.0
	for course_seed in range(1, 41):
		track.generate(course_seed, 0.0)
		gentle += mean_danger(track)
		track.generate(course_seed, 1.0)
		extreme += mean_danger(track)
	print("AI: mean danger level 0 = %.2f, level 1 = %.2f" % [gentle / 40, extreme / 40])
	check(extreme / 40 > gentle / 40 + 0.2, "Difficulty level does not change the courses")
	# The classic layout remains available as a valid fallback.
	for course_seed in range(1, 40):
		track.seed_value = course_seed
		check(track._build(TrackAI.legacy_genome(course_seed)) and track.validate() and track.gaps.is_empty(), "Classic layout invalid for seed %d" % course_seed)
	# Real physics: both marbles cross every gap and finish without a single recovery.
	var host: Node = load("res://scenes/main.tscn").instantiate()
	add_child(host)
	await get_tree().process_frame
	var tested := 0
	for course_seed in with_jump.slice(0, 8):
		host.start_race(course_seed)
		await get_tree().physics_frame
		var race = host.race
		race.placement_time = 0
		var recoveries := [0]
		for marble in race.marbles:
			marble.recovered.connect(func(): recoveries[0] += 1)
		var frames := 0
		while race.phase != "finished" and frames < 7200:
			await get_tree().physics_frame
			frames += 1
		check(race.phase == "finished", "Marbles could not finish seed %d (gaps: %d)" % [course_seed, race.track.gaps.size()])
		check(recoveries[0] == 0, "Seed %d needed %d recoveries; a jump is not clearable at cruise speed" % [course_seed, recoveries[0]])
		check(race.marbles[0].health > 0 and race.marbles[1].health > 0, "Seed %d was decided by health, not by reaching the finish" % course_seed)
		print("AI PHYSICS seed=%d gaps=%d finish=%.1fs recoveries=%d health=[%.0f, %.0f]" % [course_seed, race.track.gaps.size(), race.race_time, recoveries[0], race.marbles[0].health, race.marbles[1].health])
		tested += 1
	check(tested == 8, "Not enough seeds with gaps for the physics check")
	host.clear_race()
	host.queue_free()
	await get_tree().process_frame
	print("PASS: evolutionary track designer" if failures.is_empty() else "FAIL: %d checks" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
