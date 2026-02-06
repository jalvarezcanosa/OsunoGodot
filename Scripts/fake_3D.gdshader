shader_type canvas_item;

uniform vec2 rect_size; // tamaño real de la carta
uniform vec2 atlas_offset;
uniform vec2 card_size;
uniform vec2 atlas_size;

// Efecto 3D
uniform float fov : hint_range(1, 179) = 90.0;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float x_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float inset : hint_range(0, 1) = 0.0;

// Brillo
uniform float edge_brightness : hint_range(1.0, 5.0) = 2.0;

varying vec2 o;
varying vec3 p;

void vertex() {
	float sin_b = sin(y_rot * PI / 180.0);
	float cos_b = cos(y_rot * PI / 180.0);
	float sin_c = sin(x_rot * PI / 180.0);
	float cos_c = cos(x_rot * PI / 180.0);

	mat3 inv_rot_mat;
	inv_rot_mat[0] = vec3(cos_b, 0.0, -sin_b);
	inv_rot_mat[1] = vec3(sin_b * sin_c, cos_c, cos_b * sin_c);
	inv_rot_mat[2] = vec3(sin_b * cos_c, -sin_c, cos_b * cos_c);

	float t = tan(fov * PI / 360.0);

	p = inv_rot_mat * vec3(UV - 0.5, 0.5 / t);
	float v = (0.5 / t) + 0.5;
	p.xy *= v * inv_rot_mat[2].z;
	o = v * inv_rot_mat[2].xy;

	// Reducimos rect_size a la mitad
	VERTEX += (UV - 0.5) * rect_size * 0.5 * t * (1.0 - inset);
}

void fragment() {
	if (cull_back && p.z <= 0.0) discard;

	vec2 uv = (p.xy / p.z).xy - o;
	vec2 local_uv = uv + 0.5;

	vec2 atlas_uv = (atlas_offset + local_uv * card_size) / atlas_size;
	vec4 col = texture(TEXTURE, atlas_uv);

	vec3 normal = vec3(0.0, 0.0, 1.0);
	vec3 view_dir = normalize(p);
	float fresnel = pow(1.0 - dot(normal, view_dir), 2.0);
	col.rgb *= mix(1.0, edge_brightness, fresnel);

	col.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

	COLOR = col;
}
