shader_type spatial;
uniform vec4 primary_color : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(1.0);
uniform int pattern = 0;
uniform float flash = 0.0;
void fragment() {
	float mask = 0.0;
	if (pattern == 1) { mask = step(0.55, fract(UV.x * 10.0 + UV.y * 3.0)); }
	if (pattern == 2) { mask = step(0.5, UV.x); }
	if (pattern == 3) { mask = step(0.6, fract(UV.y * 9.0)); }
	if (pattern == 4) { mask = mod(floor(UV.x * 12.0) + floor(UV.y * 8.0), 2.0); }
	if (pattern == 5) { mask = step(0.75, sin(UV.x * 55.0 + sin(UV.y * 28.0) * 4.0)); }
	vec3 color = mix(primary_color.rgb, secondary_color.rgb, mask);
	ALBEDO = mix(color * 0.75, vec3(1.0), flash);
	METALLIC = 0.55;
	ROUGHNESS = 0.18;
	SPECULAR = 0.85;
	EMISSION = color * 0.18 + vec3(flash * 0.7);
}
