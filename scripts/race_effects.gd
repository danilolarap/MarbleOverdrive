class_name RaceEffects
extends MeshInstance3D
## At most 48 short, opaque sparks in one draw; never affects simulation.
var sparks: Array[Dictionary] = []
var geometry := ImmediateMesh.new()
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 181
	mesh = geometry
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material

func burst(at: Vector3, color: Color) -> void:
	for i in range(6 if Session.quality == "economy" else 10):
		if sparks.size() >= 48:
			break
		sparks.append({"at": at, "velocity": Vector3(random.randf_range(-3, 3), random.randf_range(1, 4), random.randf_range(-3, 3)), "life": 0.45, "color": color})

func _process(delta: float) -> void:
	if sparks.is_empty():
		if geometry.get_surface_count() > 0:
			geometry.clear_surfaces()
		return
	geometry.clear_surfaces()
	geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for spark in sparks:
		spark.life -= delta
		spark.velocity.y -= delta * 7
		spark.at += spark.velocity * delta
		var width := maxf(0, spark.life) * 0.12
		geometry.surface_set_color(spark.color)
		geometry.surface_add_vertex(spark.at + Vector3(width, 0, 0))
		geometry.surface_add_vertex(spark.at - Vector3(width, 0, 0))
		geometry.surface_add_vertex(spark.at - spark.velocity * 0.06)
	geometry.surface_end()
	sparks = sparks.filter(func(spark): return spark.life > 0)
