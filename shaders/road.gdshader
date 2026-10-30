shader_type spatial;
render_mode cull_disabled;
uniform bool daylight = false;
uniform bool tactical = false;

void fragment() {
	vec3 base = daylight ? vec3(0.16, 0.24, 0.32) : vec3(0.04, 0.08, 0.12);
	if (tactical) {
		base = vec3(0.18, 0.28, 0.38);
	}
	float grain = fract(sin(dot(UV * vec2(730.0, 115.0), vec2(12.9898, 78.233))) * 43758.5453);
	float seam = 1.0 - smoothstep(0.0, 0.025, abs(fract(UV.y * 0.2) - 0.5));
	float lane = (1.0 - smoothstep(0.0015, 0.004, abs(UV.x - 0.5))) * step(0.65, fract(UV.y * 0.22));
	float edge = smoothstep(0.43, 0.49, abs(UV.x - 0.5));
	ALBEDO = base + grain * 0.012 + vec3(seam * 0.025 + lane * 0.2);
	METALLIC = 0.65;
	ROUGHNESS = 0.22 + grain * 0.07;
	SPECULAR = 0.85;
	EMISSION = vec3(0.04, 0.19, 0.27) * (seam * 0.1 + edge * 0.25 + lane * 0.8);
}
