shader_type canvas_item;
#include "res://shaders/marble_designs.gdshaderinc"
// A lit, slowly turning sphere using the same finishes as the race marble.
uniform vec4 primary_color : source_color;
uniform vec4 secondary_color : source_color;
uniform int pattern = 0;
uniform float spin = 0.35;
uniform float phase = 0.0;

mat3 md_rot_y(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat3(vec3(c, 0.0, -s), vec3(0.0, 1.0, 0.0), vec3(s, 0.0, c));
}

mat3 md_rot_x(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	vec3 v = vec3(p.x, -p.y, sqrt(max(0.0, 1.0 - r * r)));
	mat3 turn = md_rot_y(TIME * spin + phase) * md_rot_x(0.35);
	vec3 o = normalize(turn * v);
	vec3 albedo;
	vec3 emission;
	float metallic;
	float roughness;
	design_surface(pattern, o, primary_color.rgb, secondary_color.rgb, TIME, albedo, emission, metallic, roughness);
	vec3 n = normalize(transpose(turn) * design_normal(pattern, o));
	vec3 light = normalize(vec3(-0.5, 0.6, 0.8));
	vec3 half_vector = normalize(light + vec3(0.0, 0.0, 1.0));
	float diffuse = max(dot(n, light), 0.0);
	float gloss = mix(220.0, 10.0, roughness);
	float specular = pow(max(dot(n, half_vector), 0.0), gloss) * mix(0.45, 1.0, metallic) * (1.0 - roughness * 0.7);
	vec3 bounce = reflect(vec3(0.0, 0.0, -1.0), n);
	vec3 sky = mix(vec3(0.05, 0.07, 0.12), vec3(0.78, 0.88, 1.0), smoothstep(-0.2, 0.8, bounce.y));
	float fresnel = pow(1.0 - max(n.z, 0.0), 3.0);
	vec3 base = albedo * (0.18 + 0.82 * diffuse) * (1.0 - metallic * 0.55) + albedo * sky * metallic * 0.75;
	vec3 color = base + vec3(specular) + sky * fresnel * 0.28 + emission;
	color *= 1.0 - smoothstep(0.75, 1.0, r) * 0.25;
	COLOR = vec4(color, 1.0 - smoothstep(0.96, 1.0, r));
}
