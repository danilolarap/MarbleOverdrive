shader_type canvas_item;
uniform bool light_mode = true;
void fragment() {
    vec3 paper = light_mode ? vec3(0.89, 0.91, 0.88) : vec3(0.035, 0.055, 0.065);
    float reading = 1.0 - smoothstep(0.32, 0.72, UV.x);
    float top = (1.0 - smoothstep(0.02, 0.19, UV.y)) * 0.55;
    float bottom = smoothstep(0.80, 1.0, UV.y) * 0.75;
    COLOR = vec4(paper, max(reading * 0.97, max(top, bottom)));
}
