shader_type spatial;
#include "res://shaders/marble_designs.gdshaderinc"
uniform vec4 primary_color : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(1.0);
uniform int pattern = 0;
uniform float flash = 0.0;
varying vec3 object_dir;

void vertex() {
	object_dir = normalize(VERTEX);
	if (pattern == MD_GEM) {
		VERTEX = design_vertex(pattern, VERTEX);
		NORMAL = design_normal(pattern, object_dir);
	}
}

void fragment() {
	vec3 o = normalize(object_dir);
	vec3 albedo;
	vec3 emission;
	float metallic;
	float roughness;
	design_surface(pattern, o, primary_color.rgb, secondary_color.rgb, TIME, albedo, emission, metallic, roughness);
	// Relief and facets live in object space, so they roll with the marble.
	NORMAL = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(design_normal(pattern, o), 0.0))).xyz);
	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	ALBEDO = mix(albedo * 0.9, vec3(1.0), flash * 0.65);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.85;
	EMISSION = emission + albedo * (0.06 + rim * 0.22) + vec3(flash * 0.4);
}
