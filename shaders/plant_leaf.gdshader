shader_type spatial;
render_mode cull_disabled, specular_disabled, ambient_light_disabled;

uniform vec4 paint : source_color = vec4(0.28, 0.40, 0.19, 1.0);

void fragment() {
    float across = abs(UV.x - 0.5) * 2.0;
    float midrib = 1.0 - smoothstep(0.012, 0.026, across);
    float vein_phase = fract(UV.y * 7.0 - across * 0.72);
    float veins = (1.0 - smoothstep(0.015, 0.038, min(vein_phase, 1.0 - vein_phase)))
        * smoothstep(0.08, 0.22, across) * (1.0 - smoothstep(0.74, 1.0, across));
    float edge = smoothstep(0.85, 1.0, across);
    vec3 color = paint.rgb * COLOR.rgb;
    color *= 0.92 + 0.12 * sin(UV.y * 3.14159265);
    color = mix(color, color * vec3(1.25, 1.17, 1.08), midrib * 0.65 + veins * 0.20);
    color *= 1.0 - edge * 0.18;
    if (!FRONT_FACING) {
        NORMAL = -NORMAL;
        color *= vec3(0.96, 1.02, 0.92);
    }
    ALBEDO = color;
    EMISSION = color * 0.06;
    ROUGHNESS = 0.92;
}

void light() {
    float facing = max(dot(NORMAL, LIGHT), 0.0);
    float band = mix(0.20, 0.58, smoothstep(0.10, 0.34, facing));
    band = mix(band, 1.0, smoothstep(0.56, 0.78, facing));
    DIFFUSE_LIGHT += LIGHT_COLOR * band * ATTENUATION / 3.14159265;
}
