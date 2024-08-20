shader_type canvas_item;


uniform vec4 outline_color;
uniform int padding = 0;
uniform int border_size = 1;


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 size = TEXTURE_PIXEL_SIZE;

	float alpha = 0.0;
	float offset = float(padding + border_size);
	alpha += texture(TEXTURE, UV + vec2(-size.x, 0) * offset).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, 0) * offset).a;
	alpha += texture(TEXTURE, UV + vec2(0, size.y) * offset).a;
	alpha += texture(TEXTURE, UV + vec2(0, -size.y) * offset).a;
	alpha = clamp(alpha, 0.0, 1.0);

	alpha -= texture(TEXTURE, UV + vec2(-size.x, 0) * float(padding)).a;
	alpha -= texture(TEXTURE, UV + vec2(size.x, 0) * float(padding)).a;
	alpha -= texture(TEXTURE, UV + vec2(0, size.y) * float(padding)).a;
	alpha -= texture(TEXTURE, UV + vec2(0, -size.y) * float(padding)).a;
	alpha = clamp(alpha, 0.0, 1.0);

	COLOR = mix(color, outline_color, clamp(alpha - color.a, 0.0, 1.0));
}
