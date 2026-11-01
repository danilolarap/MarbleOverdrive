shader_type spatial;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(0.2, 0.8, 0.9, 1.0);
void fragment() {
    float scan = smoothstep(0.65, 0.72, fract(UV.y * 22.0 - TIME * 0.12));
    float border = step(0.04, UV.x) * step(UV.x, 0.96) * step(0.035, UV.y) * step(UV.y, 0.965);
    ALBEDO = mix(tint.rgb * 0.55, tint.rgb * (0.055 + scan * 0.025), border);
}
