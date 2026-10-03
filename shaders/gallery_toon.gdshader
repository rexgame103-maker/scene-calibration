shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;

uniform vec4 paint : source_color = vec4(0.6, 0.4, 0.15, 1.0);
uniform vec3 half_size = vec3(0.5);
uniform bool box_ink = false;
uniform float ink_width = 0.012;
uniform float grain = 0.02;
uniform float glow = 0.0;
varying vec3 object_position;
varying vec3 object_normal;

float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 39.425))) * 43758.5453); }
void vertex() {
    object_position = VERTEX;
    object_normal = NORMAL;
}
void fragment() {
    vec3 color = paint.rgb;
    float fleck = hash(floor(object_position * vec3(28.0, 36.0, 75.0)));
    color *= 1.0 - step(0.78, fleck) * grain;
    if (box_ink) {
        vec3 edge = half_size - abs(object_position);
        vec3 n = abs(object_normal);
        float distance_to_edge = n.y > 0.5 ? min(edge.x, edge.z) : (n.x > 0.5 ? min(edge.y, edge.z) : min(edge.x, edge.y));
        float w = ink_width * (0.85 + 0.15 * sin(object_position.x * 32.0 + object_position.y * 18.0 + object_position.z * 23.0));
        color = mix(vec3(0.009, 0.006, 0.004), color, smoothstep(w, w + 0.003, distance_to_edge));
    }
    ALBEDO = color;
    EMISSION = color * (0.045 + glow);
    ROUGHNESS = 1.0;
}
void light() {
    float facing = max(dot(NORMAL, LIGHT), 0.0);
    float band = facing > 0.65 ? 1.0 : (facing > 0.25 ? 0.48 : 0.09);
    float shadow = ATTENUATION;
    DIFFUSE_LIGHT += LIGHT_COLOR * band * shadow / 3.14159265;
}


