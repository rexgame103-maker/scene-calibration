shader_type canvas_item;
render_mode unshaded;
// Follow the four inner corners of the photographed paper mount.
void vertex() {
	vec2 p = VERTEX / vec2(332.0, 307.0);
	VERTEX.x += p.x * p.y * 12.0;
	VERTEX.y -= p.x * 22.0;
}
