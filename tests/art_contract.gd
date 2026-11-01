extends Node
var errors := 0
var checked_instances := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		errors += 1
		push_error(message)

func inspect_decoration(node: Node) -> void:
	check(not node is CollisionObject3D, "District decoration introduced gameplay collisions")
	if node is MultiMeshInstance3D and DisplayServer.get_name() != "headless":
		for i in range(node.multimesh.instance_count):
			var bounds: AABB = node.global_transform * node.multimesh.get_instance_transform(i) * node.multimesh.mesh.get_aabb()
			# TrackGenerator confines road edges to |x|<=36 and deck height >=12.
			check(bounds.end.y < 11 or bounds.position.x > 37 or bounds.end.x < -37, "Decoration enters the racing corridor: " + str(bounds))
			checked_instances += 1
	for child in node.get_children():
		inspect_decoration(child)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var group := Node3D.new()
	add_child(group)
	var surface := NeonGeometry.material(Color.WHITE)
	var box := NeonGeometry.box(group, Vector3(3, 4, 5), Vector3(2, 3, 4), surface)
	box.rotation.y = 0.5
	var expected := box.transform * box.mesh.get_aabb()
	NeonGeometry.consolidate_boxes(group)
	var batch := group.get_child(0) as MultiMeshInstance3D
	var actual := batch.multimesh.get_instance_transform(0) * batch.multimesh.mesh.get_aabb()
	# Dummy RenderingServer returns identity transforms: bounds need a real renderer.
	if DisplayServer.get_name() != "headless":
		check(actual.is_equal_approx(expected) and batch.material_override == surface, "Static batching changed geometry/material")
	group.free()
	check(Session.fresh_profile().light, "New profiles must start in light mode")
	Session.light = false
	Session.quality = "economy"
	Session.save()
	Session.light = true
	Session.quality = "balanced"
	Session.load_preferences()
	check(not Session.light and Session.quality == "economy", "Saved dark theme/quality was overwritten")
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		for key in preload("res://localization/art_direction.gd").TEXT:
			check(tr(key) != key, "Missing localized text: " + key)
	for seed_value in [42, 781, 12345]:
		for id in DistrictKit.PROFILES:
			for quality in ["balanced", "economy"]:
				Session.quality = quality
				var track := TrackGenerator.new()
				track.generate(seed_value)
				var view := TrackView.new()
				view.track = track
				view.scenario_id = id
				add_child(view)
				inspect_decoration(view.city_root)
				check(view.checkpoint_distances.size() == 3, "Sector gates missing")
				check(view.sun.shadow_enabled == (quality == "balanced"), "Shadow quality not applied")
				for i in range(20):
					view.feedback(Vector3.ZERO, Color.CYAN)
				check(view.pulse_positions.size() <= 10 and view.effects.sparks.size() <= 48, "Effects exceeded their budget")
				view.effects._process(1.0)
				check(view.effects.sparks.is_empty(), "Expired sparks were retained")
				view.free()
	if DisplayServer.get_name() == "headless":
		print("SKIP: instance bounds require graphical art_contract.tscn (dummy renderer returns identity)")
	print("PASS: visual contracts, saved settings, translations, FX limits and %d decoration bounds" % checked_instances if errors == 0 else "FAIL: art contracts (%d)" % errors)
	get_tree().quit(errors)
