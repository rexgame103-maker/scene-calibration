shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float color_steps : hint_range(2.0, 12.0, 1.0) = 7.0;
uniform float posterize_strength : hint_range(0.0, 1.0, 0.01) = 0.12;
uniform float outline_strength : hint_range(0.0, 1.5, 0.01) = 0.18;
uniform float outline_threshold : hint_range(0.01, 0.5, 0.005) = 0.105;
uniform float outline_width : hint_range(0.5, 3.0, 0.05) = 1.15;
uniform float paper_strength : hint_range(0.0, 0.25, 0.005) = 0.055;
uniform float hatch_strength : hint_range(0.0, 0.3, 0.005) = 0.015;
uniform float saturation : hint_range(0.0, 1.5, 0.01) = 0.92;
uniform float warmth : hint_range(-0.3, 0.3, 0.005) = 0.065;
uniform vec3 ink_color : source_color = vec3(0.055, 0.038, 0.030);

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

void fragment() {
	ivec2 screen_size_i = textureSize(screen_texture, 0);
	vec2 pixel = outline_width / vec2(screen_size_i);
	vec2 uv = SCREEN_UV;

	vec3 center = texture(screen_texture, uv).rgb;
	vec3 left_color = texture(screen_texture, uv - vec2(pixel.x, 0.0)).rgb;
	vec3 right_color = texture(screen_texture, uv + vec2(pixel.x, 0.0)).rgb;
	vec3 up_color = texture(screen_texture, uv - vec2(0.0, pixel.y)).rgb;
	vec3 down_color = texture(screen_texture, uv + vec2(0.0, pixel.y)).rgb;

	float left_luma = luminance(left_color);
	float right_luma = luminance(right_color);
	float up_luma = luminance(up_color);
	float down_luma = luminance(down_color);
	float luma_gradient = length(vec2(right_luma - left_luma, down_luma - up_luma));
	float color_gradient = 0.45 * (
		length(right_color - left_color) + length(down_color - up_color)
	);
	float edge_value = max(luma_gradient * 1.35, color_gradient);
	float edge = smoothstep(outline_threshold, outline_threshold + 0.145, edge_value);

	float luma = luminance(center);
	float stepped_luma = floor(luma * color_steps + 0.5) / color_steps;
	vec3 stepped_color = center * (stepped_luma / max(luma, 0.035));
	vec3 stylized = mix(center, stepped_color, posterize_strength);

	float stylized_luma = luminance(stylized);
	stylized = mix(vec3(stylized_luma), stylized, saturation);
	stylized += vec3(warmth * 0.32, warmth * 0.10, -warmth * 0.22);
	stylized = pow(max(stylized, vec3(0.0)), vec3(0.94));

	vec2 fragment_pixel = FRAGCOORD.xy;
	float paper_noise = hash21(floor(fragment_pixel * 0.48));
	float broad_noise = hash21(floor(fragment_pixel * 0.11));
	float paper = (paper_noise - 0.5) * 0.65 + (broad_noise - 0.5) * 0.35;
	stylized += paper * paper_strength * (0.45 + stylized_luma * 0.55);

	float dark_area = smoothstep(0.68, 0.12, stylized_luma);
	float diagonal_a = sin((fragment_pixel.x + fragment_pixel.y) * 0.34);
	float diagonal_b = sin((fragment_pixel.x - fragment_pixel.y) * 0.27 + 1.7);
	float hatch = smoothstep(0.72, 0.98, max(diagonal_a, diagonal_b) * 0.5 + 0.5);
	stylized *= 1.0 - hatch * hatch_strength * dark_area;

	stylized = mix(stylized, ink_color, edge * outline_strength);
	COLOR = vec4(clamp(stylized, vec3(0.0), vec3(1.0)), 1.0);
}
