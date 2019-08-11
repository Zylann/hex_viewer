shader_type canvas_item;

uniform sampler2D u_gradient;

void fragment() {
	float key = texture(TEXTURE, UV).r;
	vec3 col = texture(u_gradient, vec2(key, 0)).rgb;
	COLOR = vec4(col, COLOR.a);
}
