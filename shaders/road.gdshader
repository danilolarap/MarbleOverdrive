shader_type spatial;
render_mode cull_disabled;
uniform bool daylight = false;
uniform bool tactical = false;
void fragment() {
    vec3 base = daylight ? vec3(0.23, 0.27, 0.29) : vec3(0.16, 0.20, 0.23);
    float aa = max(fwidth(UV.y), 0.012);
    float seams = 1.0 - smoothstep(0.03, 0.03 + aa, abs(mod(UV.y, 5.0) - 2.5));
    float edge = smoothstep(0.415, 0.425, abs(UV.x - 0.5));
    float stripe = smoothstep(0.45, 0.55, fract(UV.y * 0.75 + UV.x * 14.0));
    float center = (1.0 - smoothstep(0.003, 0.006, abs(UV.x - 0.5))) * step(0.5, fract(UV.y * 0.16));
    float grip = 1.0 - smoothstep(0.12, 0.14, abs(abs(UV.x - 0.5) - 0.22));
    float tread = sin(UV.y * 22.0) * 0.012 / (1.0 + aa * 22.0);
    vec3 paint = mix(vec3(0.13, 0.15, 0.14), vec3(0.57, 0.59, 0.31), stripe);
    ALBEDO = mix(base - grip * 0.035 + tread - seams * 0.08, paint, edge);
    ALBEDO = mix(ALBEDO, vec3(0.70, 0.75, 0.72), center);
    if (tactical) { ALBEDO = vec3(0.20, 0.28, 0.32); }
    METALLIC = mix(0.35, 0.05, grip);
    ROUGHNESS = mix(0.48, 0.8, grip);
    SPECULAR = 0.5;
}