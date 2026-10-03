shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	COLOR = vec4(textureLod(screen_texture, SCREEN_UV, 3.5).rgb, 1.0);
}
