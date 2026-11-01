shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

vec3 bright(vec3 c) {
	return max(c - vec3(0.72), vec3(0.0));
}
void fragment() {
	vec3 original = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		float angle = float(i) * 1.570796;
		vec2 direction = vec2(cos(angle), sin(angle)) * SCREEN_PIXEL_SIZE;
		glow += bright(textureLod(screen_texture, SCREEN_UV + direction * 5.0, 2.0).rgb) * 0.075;
	}
	float vignette = 1.0 - smoothstep(0.25, 0.78, distance(SCREEN_UV, vec2(0.5))) * 0.15;
	COLOR = vec4((original + glow * 0.45) * vignette, 1.0);
}
