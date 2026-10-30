extends Node
var errors: Array[String] = []
var host: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	check(Session.profile_slots.size() == 2 and Session.player_name(0) != Session.player_name(1), "Exactly two different pilot slots required")
	var name_a := "Nova%d" % (Time.get_ticks_usec() % 100000)
	var name_b := "Atlas%d" % (Time.get_ticks_usec() % 100000)
	check(Session.create_profile(name_a, 0), "Create P1 profile")
	check(Session.create_profile(name_b, 1), "Create P2 profile")
	check(not Session.select_profile(name_a, 1), "Duplicate pilot profile accepted")
	Session.record_result(0)
	check(Session.profiles[name_a].wins == 1 and Session.profiles[name_b].losses == 1, "Individual win/loss tracking")
	Session.record_result(-1)
	check(Session.profiles[name_a].draws == 1 and Session.profiles[name_b].draws == 1, "Individual draw tracking")
	Session.players[0].pattern = "CHECKER"
	Session.players[0].secondary = Color("ef69df")
	Session.save()
	var config := ConfigFile.new()
	check(config.load(Session.SAVE_PATH) == OK, "Profile pair persistence")
	check(config.get_value("data", "slots").size() == 2, "Saved pilot slots")
	check(config.get_value("data", "profiles")[name_a].marble.pattern == "CHECKER", "Appearance persistence")
	check(not GameCatalog.valid_loadout(["BOOST", "BOOST", "OIL"]), "Duplicate equipment accepted")
	check(not GameCatalog.valid_loadout(["BOOST", "SHIELD", "BARRIER"]), "Over-budget loadout accepted")
	check(GameCatalog.valid_loadout(["BOOST", "REPAIR", "GRIP"]), "Valid defensive loadout rejected")
	check(GameCatalog.SCENARIOS.size() > 10, "More than ten selectable worlds required")
	host = load("res://scenes/main.tscn").instantiate()
	add_child(host)
	host.start_race(42)
	await get_tree().process_frame
	var race: DuelRace = host.race
	for i in range(0, race.track.hazards.size(), 2):
		var a: Vector3 = race.track.hazards[i].position
		var b: Vector3 = race.track.hazards[i + 1].position
		var middle := (a + b) / 2
		check(race.track.closest(middle).position.distance_to(middle) < 0.01, "Neutral hazards must be mirrored around the road")
	for owner in range(2):
		for id in Session.ITEM_IDS:
			var sample := race.track.sample_at(55)
			var target := GameCatalog.target_lane(owner, id)
			var correct: Vector3 = sample.position + sample.normal * (-1.65 if target == 0 else 1.65)
			var wrong: Vector3 = sample.position - sample.normal * (-1.65 if target == 0 else 1.65)
			check(race.can_place(correct, owner, id), "Allowed half rejected for " + id)
			check(not race.can_place(wrong, owner, id), "Wrong half accepted for " + id)
			var item := TacticalItem.new()
			item.kind = id
			item.owner_index = owner
			var marble := race.marbles[target]
			var other := race.marbles[1 - target]
			var original := other.position
			other.position = marble.position
			item.position = marble.position
			race.world.add_child(item)
			if id == "BARRIER":
				check((other.normal_collision_mask() & item.obstacle.collision_layer) == 0, "Owner physically collides with own barrier")
				check((marble.normal_collision_mask() & item.obstacle.collision_layer) != 0, "Rival does not collide with targeted barrier")
			check(not item.try_affect(other), "Item affected wrong player: " + id)
			other.position = original
			marble.health = 50
			marble.shield_points = 0
			marble.grip_time = 0
			marble.slowed = 0
			check(item.try_affect(marble), "Intended player did not trigger " + id)
			check(not item.try_affect(marble), "Item triggered twice: " + id)
			match id:
				"REPAIR": check(marble.health == 68, "Repair amount")
				"SHIELD":
					marble.damage(25)
					check(marble.health == 45 and marble.shield_points == 0, "Shield absorption capped at twenty")
				"GRIP": check(marble.grip_time == 3, "Stabilizer duration")
				"MAGNET": check(marble.health == 42 and marble.slowed == 1.4, "Magnet tuning")
				"BARRIER": check(marble.health == 30, "Barrier damage")
				"SHOCK": check(marble.health == 32, "Shock damage")
			item.queue_free()
	# Repair cannot exceed maximum health; boost cannot add forward speed above 48.
	var probe := RacingMarble.new()
	probe.track = race.track
	var flat := race.track.sample_at(55)
	probe.position = flat.position + flat.up * (RacingMarble.RADIUS + 0.05) - flat.normal * 1.65
	race.world.add_child(probe)
	probe.freeze = false
	probe.linear_velocity = flat.tangent * 47
	await get_tree().physics_frame
	var boost := TacticalItem.new()
	boost.kind = "BOOST"
	boost.position = probe.position
	race.world.add_child(boost)
	check(boost.try_affect(probe), "Boost contact")
	check(probe.boost_time == 2.5, "Boost duration must be bounded to 2.5 seconds")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(probe.linear_velocity.dot(flat.tangent) <= 48.1, "Boost exceeded its forward speed cap")
	var repair := TacticalItem.new()
	repair.kind = "REPAIR"
	repair.position = probe.position
	race.world.add_child(repair)
	probe.health = 95
	check(repair.try_affect(probe) and probe.health == 100, "Repair exceeded maximum health")
	probe.queue_free()
	boost.queue_free()
	repair.queue_free()
	# The actual placement path must switch to the opponent's half after Boost.
	race.cursor_distances[0] = 55
	race.cursor_offsets[0] = -1.65
	check(race.place_item(0), "Initial equipment placement")
	check(race.next_target(0) == 1 and race.cursor_offsets[0] > 0, "Trap cursor did not switch to opponent")
	race.cursor_offsets[0] = -1.65
	check(not race.place_item(0), "Placement bypassed side restriction")
	for id in GameCatalog.SCENARIOS:
		Session.scenario = id
		host.start_race(42)
		await get_tree().physics_frame
		race = host.race
		check(race.view.scenario_id == id, "World selection did not reach scene")
		race.placement_time = 0
		var frames := 0
		while race.phase != "finished" and frames < 6000:
			await get_tree().physics_frame
			frames += 1
		check(race.phase == "finished", "World race did not finish: " + id)
		check(minf(race.marbles[0].progress, race.marbles[1].progress) > race.track.total_length * 0.85, "A pilot could not traverse the 3D road: " + id)
		print("WORLD %s physics finish %.2fs" % [id, race.race_time])
	host.clear_race()
	host.queue_free()
	await get_tree().process_frame
	print("PASS: 12 worlds, 2 profiles, individual stats, skin persistence, 16 item/owner combinations, lane restrictions, costs and complete races" if errors.is_empty() else "FAIL: %d checks" % errors.size())
	get_tree().quit(0 if errors.is_empty() else 1)
