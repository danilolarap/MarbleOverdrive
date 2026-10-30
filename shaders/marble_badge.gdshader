shader_type canvas_item;
uniform vec4 primary_color : source_color;
uniform vec4 secondary_color : source_color;
uniform int pattern = 0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float mask = 0.0;
	if (pattern == 1) { mask = step(0.55, fract(UV.x * 8.0 + UV.y * 3.0)); }
	if (pattern == 2) { mask = step(0.5, UV.x); }
	if (pattern == 3) { mask = step(0.6, fract(radius * 7.0)); }
	if (pattern == 4) { mask = mod(floor(UV.x * 9.0) + floor(UV.y * 9.0), 2.0); }
	if (pattern == 5) { mask = step(0.7, sin(UV.x * 48.0 + sin(UV.y * 30.0) * 3.0)); }
	float z = sqrt(max(0.0, 1.0 - radius * radius));
	vec3 n = vec3(p, z);
	vec3 light = normalize(vec3(-0.6, -0.6, 1.0));
	vec3 color = mix(primary_color.rgb, secondary_color.rgb, mask);
	float shade = max(0.22, dot(n, light));
	float glint = pow(max(0.0, dot(n, light)), 35.0);
	float ring = smoothstep(0.87, 0.93, radius) * (1.0 - smoothstep(0.96, 1.0, radius));
	COLOR = vec4(color * shade + vec3(glint * 0.8) + color * ring * 0.7, 1.0 - smoothstep(0.97, 1.0, radius));
}
