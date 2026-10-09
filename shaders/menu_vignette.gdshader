shader_type canvas_item;
void fragment() {
    vec2 p=UV*2.0-1.0;
    float edge=smoothstep(0.4,1.35,length(p*vec2(0.82,1.0)));
    float grain=fract(sin(dot(floor(UV*vec2(1500.0,850.0)),vec2(12.98,78.23)))*43758.54);
    float menu_shade = 1.0 - smoothstep(0.23, 0.62, UV.x);
    COLOR=vec4(0.018,0.028,0.021,menu_shade*0.75+edge*0.17+grain*0.016);
}
