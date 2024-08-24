shader_type canvas_item;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 world_uv = world_position / vec2(textureSize(TEXTURE, 0));
	COLOR = texture(TEXTURE, world_uv);
}
