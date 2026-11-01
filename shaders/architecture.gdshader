shader_type spatial;
// Repeated panel relief, corrosion and service seams without texture assets.
uniform vec4 tint : source_color = vec4(0.25, 0.3, 0.35, 1.0);
void fragment() {
    vec2 cell = fract(UV * vec2(5.0, 12.0));
    vec2 aa = max(fwidth(UV * vec2(5.0, 12.0)), vec2(0.006));
    float panel = smoothstep(0.0, aa.x + 0.016, cell.x) * smoothstep(0.0, aa.y + 0.025, cell.y);
    float stain = sin(UV.x * 73.0) * sin(UV.y * 23.0) * 0.025;
    ALBEDO = tint.rgb * (0.72 + panel * 0.28) + stain;
    ROUGHNESS = 0.62 + (1.0 - panel) * 0.2;
    METALLIC = 0.32;
}
