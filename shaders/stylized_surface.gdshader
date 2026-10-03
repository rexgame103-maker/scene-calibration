shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.75, 0.65, 0.52, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.56, 0.45, 0.36, 1.0);
uniform vec4 paint_highlight_color : source_color = vec4(0.88, 0.78, 0.60, 1.0);
uniform vec4 stain_color : source_color = vec4(0.22, 0.19, 0.18, 1.0);
uniform vec4 wear_color : source_color = vec4(0.82, 0.68, 0.48, 1.0);

uniform float color_variation : hint_range(0.0, 0.5, 0.005) = 0.18;
uniform float brush_scale : hint_range(0.2, 10.0, 0.05) = 2.4;
uniform float brush_strength : hint_range(0.0, 1.0, 0.01) = 0.38;
uniform float patina_strength : hint_range(0.0, 1.0, 0.01) = 0.34;
uniform float stain_strength : hint_range(0.0, 1.0, 0.01) = 0.20;
uniform float roughness_value : hint_range(0.0, 1.0, 0.01) = 0.82;
uniform float specular_value : hint_range(0.0, 1.0, 0.01) = 0.24;
uniform float wear_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float wear_scale : hint_range(0.2, 12.0, 0.1) = 3.4;
uniform float desk_wear : hint_range(0.0, 1.0, 0.01) = 0.0;

// Optional architectural grid. Floors and walls still share this same master
// shader; individual material profiles decide whether the grid is visible.
uniform bool grid_enabled = false;
uniform vec4 grid_color : source_color = vec4(0.25, 0.22, 0.20, 1.0);
uniform float grid_cell_size : hint_range(0.1, 4.0, 0.05) = 1.0;
uniform float grid_line_width : hint_range(0.002, 0.25, 0.002) = 0.035;
uniform float grid_strength : hint_range(0.0, 1.0, 0.01) = 0.72;
uniform float grid_tile_variation : hint_range(0.0, 0.35, 0.01) = 0.08;
uniform vec2 grid_offset = vec2(0.0);

varying vec3 local_position;
varying vec3 local_normal;


float hash31(vec3 point) {
	point = fract(point * 0.1031);
	point += dot(point, point.yzx + 33.33);
	return fract((point.x + point.y) * point.z);
}


float value_noise(vec3 point) {
	vec3 cell = floor(point);
	vec3 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	float n000 = hash31(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, local.x);
	float nx10 = mix(n010, n110, local.x);
	float nx01 = mix(n001, n101, local.x);
	float nx11 = mix(n011, n111, local.x);
	return mix(mix(nx00, nx10, local.y), mix(nx01, nx11, local.y), local.z);
}


float fbm(vec3 point) {
	float result = 0.0;
	float amplitude = 0.55;
	mat3 rotation = mat3(
		vec3(0.80, 0.36, -0.48),
		vec3(-0.20, 0.91, 0.36),
		vec3(0.57, -0.19, 0.80)
	);
	for (int index = 0; index < 4; index++) {
		result += value_noise(point) * amplitude;
		point = rotation * point * 2.03 + vec3(4.7, 1.3, 8.1);
		amplitude *= 0.48;
	}
	return result;
}


void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}


void fragment() {
	vec3 object_position = local_position;
	vec3 object_normal = normalize(local_normal);
	vec3 absolute_normal = abs(object_normal);
	absolute_normal /= max(absolute_normal.x + absolute_normal.y + absolute_normal.z, 0.001);

	// Broad overlapping paint patches form the hand-painted base without using
	// the imported photographic texture.
	vec3 paint_position = object_position * brush_scale;
	float broad_paint = fbm(paint_position * 0.54 + object_normal * 1.7);
	float medium_paint = fbm(paint_position * 1.72 + vec3(7.4, 2.2, 5.8));
	float fine_paint = fbm(paint_position * 4.65 + vec3(2.1, 9.3, 3.7));
	float patch_mask = smoothstep(0.32, 0.78, broad_paint);
	float lifted_paint = smoothstep(0.58, 0.86, medium_paint);
	float rubbed_paint = smoothstep(0.18, 0.52, medium_paint) * (1.0 - lifted_paint);
	float pale_dab = smoothstep(0.53, 0.70, medium_paint) * (1.0 - smoothstep(0.76, 0.90, medium_paint));
	float dark_dab = smoothstep(0.63, 0.82, broad_paint) * smoothstep(0.48, 0.67, fine_paint);
	float chipped_dab = smoothstep(0.54, 0.72, fine_paint) * (1.0 - smoothstep(0.73, 0.84, fine_paint));

	// Triplanar elongated brush marks follow the surface instead of forming a grid.
	vec2 brush_xy = object_position.xy * vec2(0.55, 3.8);
	vec2 brush_xz = object_position.xz * vec2(0.55, 3.8);
	vec2 brush_zy = object_position.zy * vec2(0.55, 3.8);
	float brush_xy_noise = fbm(vec3(brush_xy * brush_scale, 2.8));
	float brush_xz_noise = fbm(vec3(brush_xz * brush_scale, 6.4));
	float brush_zy_noise = fbm(vec3(brush_zy * brush_scale, 9.1));
	float brush_field = brush_xy_noise * absolute_normal.z + brush_xz_noise * absolute_normal.y + brush_zy_noise * absolute_normal.x;
	float bristle = smoothstep(0.61, 0.82, brush_field) * smoothstep(0.46, 0.70, fine_paint);

	vec3 painted_color = mix(base_color.rgb, secondary_color.rgb, patch_mask * color_variation * 1.12);
	painted_color = mix(painted_color, paint_highlight_color.rgb, lifted_paint * patina_strength * 0.76);
	painted_color = mix(painted_color, secondary_color.rgb, rubbed_paint * patina_strength * 0.44);
	painted_color = mix(painted_color, paint_highlight_color.rgb, pale_dab * patina_strength * 0.28);
	painted_color = mix(painted_color, secondary_color.rgb, dark_dab * patina_strength * 0.24);
	painted_color = mix(painted_color, wear_color.rgb, chipped_dab * patina_strength * 0.14);
	painted_color = mix(painted_color, paint_highlight_color.rgb, bristle * brush_strength * 0.36);

	// Dominant-axis projection keeps the option usable on horizontal floors and
	// vertical walls without requiring UVs or an imported tile texture.
	if (grid_enabled) {
		vec2 grid_position = object_position.xz;
		if (absolute_normal.z >= absolute_normal.x && absolute_normal.z > absolute_normal.y) {
			grid_position = object_position.xy;
		} else if (absolute_normal.x > absolute_normal.y) {
			grid_position = object_position.zy;
		}
		vec2 grid_coordinate = grid_position / max(grid_cell_size, 0.001) + grid_offset;
		vec2 tile_coordinate = fract(grid_coordinate);
		vec2 border_distance = min(tile_coordinate, 1.0 - tile_coordinate);
		float nearest_border = min(border_distance.x, border_distance.y);
		float antialias_width = max(fwidth(grid_coordinate.x), fwidth(grid_coordinate.y)) * 0.85;
		float grid_line = 1.0 - smoothstep(grid_line_width, grid_line_width + antialias_width, nearest_border);
		float tile_random = hash31(vec3(floor(grid_coordinate), 17.3)) - 0.5;
		painted_color *= 1.0 + tile_random * grid_tile_variation;
		painted_color = mix(painted_color, grid_color.rgb, grid_line * grid_strength);
	}

	// Low areas collect soft grime. This stays irregular and avoids periodic scratches.
	float height_grime = smoothstep(0.42, -1.15, object_position.y);
	float stain_noise = smoothstep(0.48, 0.78, fbm(paint_position * 1.18 + vec3(13.2, 3.6, 1.4)));
	float stain_mask = stain_noise * (0.25 + height_grime * 0.75) * stain_strength;
	painted_color = mix(painted_color, stain_color.rgb, stain_mask * 0.62);

	// Edge-facing areas receive softly worn paint, similar to hand-painted PBR assets.
	float view_edge = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.4);
	float wear_noise = fbm(object_position * wear_scale + vec3(7.1, 13.7, 3.9));
	float edge_wear = view_edge * smoothstep(0.47, 0.76, wear_noise) * wear_strength;
	float top_wear = smoothstep(0.62, 0.96, object_normal.y) * smoothstep(0.64, 0.83, wear_noise) * wear_strength;
	float wear_mask = clamp(edge_wear * 0.38 + top_wear * 0.20, 0.0, 0.32);

	// Desk-only authored wear: a faded cup ring and two long work scratches.
	vec2 desk_uv = object_position.xz;
	float desk_ring = 1.0 - smoothstep(0.035, 0.095, abs(length((desk_uv - vec2(0.34, 0.05)) * vec2(0.78, 1.38)) - 0.43));
	float desk_drag_1 = 1.0 - smoothstep(0.010, 0.034, abs(desk_uv.y + 0.19 - sin(desk_uv.x * 2.7) * 0.025));
	float desk_drag_2 = 1.0 - smoothstep(0.010, 0.030, abs(desk_uv.y - 0.31 + sin(desk_uv.x * 3.8 + 1.2) * 0.018));
	float scratch_bounds_1 = smoothstep(-1.15, -0.72, desk_uv.x) * (1.0 - smoothstep(0.62, 1.05, desk_uv.x));
	float scratch_bounds_2 = smoothstep(-0.55, -0.28, desk_uv.x) * (1.0 - smoothstep(0.88, 1.16, desk_uv.x));
	float desk_drag = desk_drag_1 * scratch_bounds_1 + desk_drag_2 * scratch_bounds_2;
	float desk_area = smoothstep(0.92, 0.995, object_normal.y) * smoothstep(1.28, 0.28, length(desk_uv));
	wear_mask += clamp((desk_ring * 0.40 + desk_drag * 0.34) * desk_area * desk_wear, 0.0, 0.42);

	painted_color = mix(painted_color, wear_color.rgb, wear_mask);
	ALBEDO = clamp(painted_color, vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(roughness_value - lifted_paint * 0.05 + stain_mask * 0.08, 0.0, 1.0);
	SPECULAR = specular_value;
	METALLIC = 0.0;
}
