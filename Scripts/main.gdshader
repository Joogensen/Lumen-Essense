shader_type canvas_item;

void fragment() {
    vec4 tex_col = texture(TEXTURE, UV);
    COLOR.rgb = tex_col.rgb;
    COLOR.a = tex_col.a;
}
