shader_type spatial;
void fragment() {
	float wave = sin(UV.x * 120.0 + TIME * 0.6) * sin(UV.y * 170.0 - TIME * 0.4);
	ALBEDO = vec3(0.02, 0.18, 0.24) + wave * 0.025;
	METALLIC = 0.45;
	ROUGHNESS = 0.23;
	EMISSION = vec3(0.01, 0.06, 0.07) * max(wave, 0.0);
}
