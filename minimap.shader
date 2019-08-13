shader_type canvas_item;

uniform sampler2D u_gradient;

void fragment() {
	float key = texture(TEXTURE, UV).r;
	if(key == 0.0) {
		COLOR = vec4(0, 0, 0, COLOR.a);
	} else {
		vec3 col = texture(u_gradient, vec2(key, 0)).rgb;
		COLOR = vec4(col, COLOR.a);
	}
}
