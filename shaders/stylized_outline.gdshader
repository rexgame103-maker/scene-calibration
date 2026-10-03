shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.075, 0.052, 0.045, 1.0);
uniform float outline_width : hint_range(0.0, 0.08, 0.001) = 0.009;

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
