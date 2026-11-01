class_name TacticalItem
extends Node3D

const RADIUS := 0.9
var kind := "BOOST"
var owner_index := 0
var consumed := false
var pulse := 0.0
var obstacle: StaticBody3D
var icon: Node3D

func _ready() -> void:
	var color: Color = GameCatalog.ITEMS[kind].color
	var material := NeonGeometry.material(color, 0.65)
	var housing := NeonGeometry.material(Color("353f43"), 0, 0.45, 0.55)
	NeonGeometry.box(self, Vector3(0, 0.045, 0), Vector3(1.85, 0.09, 1.85), housing)
	NeonGeometry.ring(self, 0.9, 0.065, material).position.y = 0.08
	icon = Node3D.new()
	add_child(icon)
	if kind == "BARRIER":
		obstacle = StaticBody3D.new()
		var target := 1 - owner_index
		obstacle.collision_layer = 2 if target == 0 else 16
		obstacle.collision_mask = 4 << target
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.6, 1.3, 0.5)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position.y = 0.65
		obstacle.add_child(collision)
		add_child(obstacle)
		NeonGeometry.box(icon, Vector3(0, 0.65, 0), Vector3(1.7, 1.3, 0.25), NeonGeometry.material(Color("352034"), 0, 0.7))
		for x in [-0.6, 0, 0.6]:
			NeonGeometry.box(icon, Vector3(x, 0.65, 0.15), Vector3(0.12, 1.2, 0.08), material).rotation.z = -0.25
	elif kind == "BOOST":
		NeonGeometry.box(icon, Vector3(0, 0.2, 0), Vector3(1.6, 0.25, 1.7), NeonGeometry.material(Color("16382e"), 0, 0.5)).rotation.x = -0.15
		for z in [-0.5, 0.1, 0.7]:
			NeonGeometry.beam(icon, Vector3(-0.55, 0.4, z), Vector3(0, 0.4, z - 0.35), 0.08, 0.08, material)
			NeonGeometry.beam(icon, Vector3(0.55, 0.4, z), Vector3(0, 0.4, z - 0.35), 0.08, 0.08, material)
	elif kind == "REPAIR":
		NeonGeometry.box(icon, Vector3(0, 0.55, 0), Vector3(0.35, 1.1, 0.3), material)
		NeonGeometry.box(icon, Vector3(0, 0.55, 0), Vector3(1.1, 0.35, 0.3), material)
	elif kind == "SHIELD":
		for side in [-1, 1]:
			NeonGeometry.box(icon, Vector3(side * 0.7, 0.8, 0), Vector3(0.18, 1.6, 0.25), housing)
			NeonGeometry.box(icon, Vector3(side * 0.58, 0.8, 0.15), Vector3(0.07, 1.3, 0.08), material)
		NeonGeometry.box(icon, Vector3(0, 1.55, 0), Vector3(1.5, 0.2, 0.25), material)
	elif kind == "OIL":
		NeonGeometry.sphere(icon, 0.8, NeonGeometry.material(Color("402959"), 0.3, 0.65)).scale = Vector3(1, 0.08, 1)
	elif kind == "SHOCK":
		for i in range(3):
			NeonGeometry.beam(icon, Vector3(-0.4 + i * 0.25, i * 0.4, 0), Vector3(0.15 + i * 0.15, 0.4 + i * 0.4, 0), 0.15, 0.15, material)
	elif kind == "GRIP":
		for z in [-0.4, 0, 0.4]:
			NeonGeometry.box(icon, Vector3(0, 0.12, z), Vector3(1.4, 0.15, 0.15), material)
	else:
		# Horseshoe magnet: distinguish slowdown from the shield gate at speed.
		for side in [-1, 1]:
			NeonGeometry.box(icon, Vector3(side * 0.45, 0.75, 0), Vector3(0.3, 0.8, 0.35), housing)
			NeonGeometry.box(icon, Vector3(side * 0.45, 1.12, 0), Vector3(0.31, 0.22, 0.36), material)
		NeonGeometry.box(icon, Vector3(0, 0.35, 0), Vector3(1.2, 0.3, 0.35), material)
	var marker := NeonGeometry.sphere(self, 0.13, NeonGeometry.material(Session.players[owner_index].color, 2))
	marker.position = Vector3(0, 1.7, 0)
	var tag := Label3D.new()
	tag.text = "P%d / %s" % [GameCatalog.target_lane(owner_index, kind) + 1, "!" if GameCatalog.is_trap(kind) else "+"]
	tag.position.y = 2.1
	tag.font_size = 32
	tag.pixel_size = 0.015
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = color.lightened(0.2)
	add_child(tag)

func _process(delta: float) -> void:
	pulse += delta
	if icon and not consumed and kind in ["MAGNET", "REPAIR"]:
		icon.position.y = sin(pulse * 2) * 0.06

func try_affect(marble: RacingMarble) -> bool:
	if consumed or marble.is_protected():
		return false
	var target := GameCatalog.target_lane(owner_index, kind)
	if marble.player_index != target:
		return false
	if position.distance_to(marble.position) > RADIUS + RacingMarble.RADIUS + 0.3:
		return false
	consumed = true
	match kind:
		"BOOST":
			marble.boost_time = 2.5
			var tangent: Vector3 = marble.track.sample_at(marble.progress).tangent
			var boost := maxf(0, minf(10, 48 - marble.linear_velocity.dot(tangent)))
			marble.apply_central_impulse(tangent * boost)
		"REPAIR": marble.health = minf(RacingMarble.MAX_HEALTH, marble.health + 18)
		"SHIELD":
			marble.shield_time = 5
			marble.shield_points = 20
		"GRIP":
			marble.grip_time = 3
			marble.slowed = 0
		"MAGNET":
			if marble.grip_time <= 0:
				marble.slowed = maxf(marble.slowed, 1.4)
			marble.damage(8)
		"OIL":
			if marble.grip_time <= 0:
				marble.slowed = maxf(marble.slowed, 0.85)
		"SHOCK": marble.damage(18)
		"BARRIER":
			marble.damage(20)
			marble.linear_velocity *= 0.6
	if is_instance_valid(obstacle):
		obstacle.queue_free()
	visible = false
	return true
