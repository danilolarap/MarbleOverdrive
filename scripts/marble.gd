class_name RacingMarble
extends RigidBody3D

const RADIUS := 0.8
const MAX_HEALTH := 100.0
const ACCELERATION := 17.0
const TOP_SPEED := 39.0
const POWER_COOLDOWNS := {"EMP": 6.0, "JUMP": 5.0, "PHASE": 6.0}
signal power_fired(marble)
signal recovered
signal damaged(at: Vector3, color: Color)
var player_index := 0
var tint := Color.CYAN
var secondary_tint := Color.WHITE
var pattern_id := "SOLID"
var power_id := "EMP"
var track: TrackGenerator
var racing := false
var health := MAX_HEALTH
var progress := 0.0
var power_cooldown := 0.0
var braking := false
var airborne := 0.0
var phased := 0.0
var slowed := 0.0
var stuck_time := 0.0
var hurt_flash := 0.0
var shield_time := 0.0
var shield_points := 0.0
var grip_time := 0.0
var boost_time := 0.0
var elapsed := 0.0
var last_hit := {}
var recovery_position := Vector3.ZERO
var recover_pending := false
var shell: MeshInstance3D
var rotor: Node3D
var surface: ShaderMaterial
var aura: MeshInstance3D
var ground_ring: MeshInstance3D
var trail: Array[Vector3] = []
var trail_mesh: MeshInstance3D
var trail_geometry := ImmediateMesh.new()
var _last_flash := -1.0
var trail_tick := 0.0

func _ready() -> void:
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	continuous_cd = true
	linear_damp = 0.08
	angular_damp = 0.2
	lock_rotation = true
	collision_layer = 4 << player_index
	collision_mask = normal_collision_mask()
	can_sleep = false
	var physics := PhysicsMaterial.new()
	physics.bounce = 0.12
	physics.friction = 0.1
	physics_material_override = physics
	freeze = true
	surface = ShaderMaterial.new()
	surface.shader = preload("res://shaders/marble.gdshader")
	surface.set_shader_parameter("primary_color", tint)
	surface.set_shader_parameter("secondary_color", secondary_tint)
	surface.set_shader_parameter("pattern", GameCatalog.PATTERNS.find(pattern_id))
	shell = NeonGeometry.sphere(self, RADIUS, surface)
	rotor = Node3D.new()
	add_child(rotor)
	var luminous := NeonGeometry.material(tint, 3.5)
	for angle in [0, PI / 2]:
		var stripe := NeonGeometry.ring(rotor, RADIUS * 0.97, 0.032, luminous)
		stripe.rotation.z = angle
	aura = NeonGeometry.ring(self, RADIUS + 0.05, 0.026, luminous)
	aura.rotation.x = PI / 2
	var light := OmniLight3D.new()
	light.light_color = tint
	light.light_energy = 1.1
	light.omni_range = 3.5
	light.visible = Session.quality != "economy"
	light.position.y = 0.7
	add_child(light)
	var number := Label3D.new()
	number.text = "P%d / %s" % [player_index + 1, Session.player_name(player_index).left(12)]
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.position.y = 1.3
	number.font_size = 38
	number.pixel_size = 0.012
	number.modulate = tint.lightened(0.4)
	number.outline_size = 10
	add_child(number)
	trail_mesh = MeshInstance3D.new()
	trail_mesh.top_level = true
	trail_mesh.mesh = trail_geometry
	add_child(trail_mesh)
	var trail_material := NeonGeometry.material(tint, 1.8)
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail_mesh.material_override = trail_material
	var ground_material := NeonGeometry.material(Color(tint, 0.12), 0)
	ground_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_ring = NeonGeometry.ring(self, 0.9, 0.04, ground_material)
	ground_ring.top_level = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if recover_pending:
		state.transform.origin = recovery_position
		state.linear_velocity = track.sample_at(progress).tangent * 12.0
		recover_pending = false

func _physics_process(delta: float) -> void:
	if not racing:
		return
	elapsed += delta
	power_cooldown = maxf(0, power_cooldown - delta)
	braking = Input.is_action_pressed("p%d_brake" % (player_index + 1))
	airborne = maxf(0, airborne - delta)
	phased = maxf(0, phased - delta)
	slowed = maxf(0, slowed - delta)
	hurt_flash = maxf(0, hurt_flash - delta)
	shield_time = maxf(0, shield_time - delta)
	grip_time = maxf(0, grip_time - delta)
	boost_time = maxf(0, boost_time - delta)
	if shield_time <= 0:
		shield_points = 0
	if grip_time > 0:
		slowed = 0
	collision_mask = 1 if is_protected() else normal_collision_mask()
	var sample := track.closest(position)
	progress = sample.distance
	var tangent: Vector3 = sample.tangent
	var normal: Vector3 = sample.normal
	var lane := -1.65 if player_index == 0 else 1.65
	var error: float = (position - sample.position).dot(normal) - lane
	apply_central_force(normal * (-error * 95.0 - linear_velocity.dot(normal) * 12.0))
	var base_speed := 48.0 if boost_time > 0 else TOP_SPEED
	var target := base_speed * (0.42 if slowed > 0 else 1.0) * (1.4 if phased > 0 else 1.0)
	if braking:
		var forward_speed := linear_velocity.dot(tangent)
		# Cancel slope gravity while held, so a stopped marble stays stopped.
		apply_central_force(tangent * (-forward_speed * 16.0 + 9.8 * tangent.y))
		if absf(forward_speed) < 0.12:
			linear_velocity -= tangent * forward_speed
	else:
		apply_central_force(tangent * clampf((target - linear_velocity.dot(tangent)) * 2.5, -ACCELERATION, ACCELERATION))
	# Actual gravity/contact; downforce is disabled during an actual jump.
	if airborne <= 0:
		apply_central_force(-sample.up * 15.0)
	stuck_time = stuck_time + delta if linear_velocity.length() < 3 and not braking else 0.0
	if stuck_time > 2.0 or position.y < sample.position.y - 5 or absf(error) > 8:
		recovery_position = sample.position + normal * lane + sample.up * (RADIUS + 0.18)
		recover_pending = true
		stuck_time = 0
		recovered.emit()

func _process(delta: float) -> void:
	if not is_instance_valid(rotor):
		return
	rotor.rotate_x(-linear_velocity.length() * delta / RADIUS)
	var sample := track.sample_at(progress)
	shell.rotate(sample.normal, -linear_velocity.length() * delta / RADIUS)
	aura.visible = true
	var camera := get_viewport().get_camera_3d()
	if camera:
		aura.look_at(camera.global_position, Vector3.UP)
		aura.rotate_object_local(Vector3.RIGHT, PI / 2)
	var flash := 1.0 if hurt_flash > 0 else 0.3 if phased > 0 or shield_time > 0 else 0.0
	if flash != _last_flash:
		surface.set_shader_parameter("flash", flash)
		_last_flash = flash
	ground_ring.global_position = sample.position + sample.normal * (position - sample.position).dot(sample.normal) + sample.up * 0.04
	ground_ring.basis = Basis(sample.normal, sample.up, -sample.tangent)
	trail_tick += delta
	if racing and trail_tick >= 1.0 / 30.0:
		trail_tick = fmod(trail_tick, 1.0 / 30.0)
		if trail.size() > 0 and position.distance_to(trail[0]) > 6:
			trail.clear()
		trail.push_front(position - Vector3(0, 0.32, 0))
		if trail.size() > 7:
			trail.pop_back()
		_update_trail(sample.normal)

func _update_trail(normal: Vector3) -> void:
	if trail.size() < 2:
		return
	var mesh := trail_geometry
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(trail.size() - 1):
		var width := 0.15 * (1 - i / float(trail.size()))
		var lateral := normal * width
		for vertex in [trail[i] - lateral, trail[i + 1] - lateral, trail[i] + lateral, trail[i] + lateral, trail[i + 1] - lateral, trail[i + 1] + lateral]:
			mesh.surface_add_vertex(vertex)
	mesh.surface_end()

func activate_power() -> bool:
	if not racing or power_cooldown > 0:
		return false
	power_cooldown = POWER_COOLDOWNS[power_id]
	if power_id == "JUMP":
		airborne = 1.0
		apply_central_impulse(Vector3.UP * 7.0)
	elif power_id == "PHASE":
		phased = 0.8
		apply_central_impulse(track.sample_at(progress).tangent * 12)
	power_fired.emit(self)
	return true

func is_protected() -> bool:
	return airborne > 0 or phased > 0

func damage(amount: float) -> void:
	if not is_protected():
		var absorbed := minf(shield_points, amount)
		shield_points -= absorbed
		amount -= absorbed
		health = maxf(0, health - amount)
		if hurt_flash <= 0:
			damaged.emit(position, Color("ffc083"))
		hurt_flash = 0.25

func normal_collision_mask() -> int:
	# Each player collides only with barriers targeted at their own half.
	return 1 | 4 | 8 | (2 if player_index == 0 else 16)
