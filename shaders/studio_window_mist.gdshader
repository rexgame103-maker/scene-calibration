shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 mist_color : source_color = vec4(0.94, 0.77, 0.48, 1.0);
uniform float density : hint_range(0.0, 0.4) = 0.085;
uniform vec3 half_extent = vec3(2.4, 1.5, 1.5);
varying vec3 local_surface;

void vertex() { local_surface = VERTEX; }

void fragment() {
    vec3 origin = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
    vec3 ray = normalize(local_surface - origin);
    vec3 inv_ray = 1.0 / (ray + vec3(0.000001));
    vec3 a = (-half_extent - origin) * inv_ray;
    vec3 b = (half_extent - origin) * inv_ray;
    vec3 near_t = min(a, b);
    vec3 far_t = max(a, b);
    float entry = max(max(near_t.x, near_t.y), max(near_t.z, 0.0));
    float leave = min(min(far_t.x, far_t.y), far_t.z);
    // Compatibility renderer uses OpenGL NDC depth. Stop at opaque furniture.
    float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
    vec4 view_point = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    view_point /= view_point.w;
    vec3 solid = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * view_point).xyz;
    leave = min(leave, dot(solid - origin, ray));
    float step_size = max(leave - entry, 0.0) / 40.0;
    float amount = 0.0;
    for (int i = 0; i < 40; i++) {
        vec3 p = origin + ray * (entry + (float(i) + 0.5) * step_size);
        float travel = p.x + 2.4;
        float source_height = p.y + 1.5 + travel * 0.445;
        float window_mask = smoothstep(1.24, 1.38, source_height) * (1.0 - smoothstep(2.82, 2.98, source_height));
        window_mask *= 1.0 - smoothstep(1.25, 1.49, abs(p.z));
        float slats = mix(1.0, 0.25 + 0.75 * smoothstep(-0.2, 0.35, sin(source_height * 76.6)), smoothstep(2.12, 2.25, source_height));
        float wisps = 0.78 + 0.22 * sin(p.x * 3.1 + p.z * 2.3 + TIME * 0.12) * sin(p.y * 4.7 - p.z * 2.8);
        amount += window_mask * slats * wisps * (1.0 - smoothstep(3.0, 4.8, travel)) * step_size;
    }
    ALBEDO = mist_color.rgb;
    ALPHA = clamp(1.0 - exp(-amount * density), 0.0, 0.38);
}
