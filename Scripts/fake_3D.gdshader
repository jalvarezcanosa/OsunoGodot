shader_type canvas_item;

uniform vec2 rect_size;

// --- ATLAS ---
uniform vec2 atlas_offset; // píxeles dentro del atlas
uniform vec2 card_size;    // tamaño de la carta (ej: 168x260)
uniform vec2 atlas_size;   // tamaño total del atlas

// --- 3D EFFECT ---
uniform float fov : hint_range(1, 179) = 90.0;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float x_rot : hint_range(-360.0, 360.0) = 0.0;
uniform float inset : hint_range(0, 1) = 0.0;

// --- BRILLO ---
uniform float edge_brightness : hint_range(1.0, 5.0) = 2.0; // brillo máximo en bordes

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

	VERTEX += (UV - 0.5) * rect_size * t * (1.0 - inset);
}

void fragment() {
	if (cull_back && p.z <= 0.0) discard;

	vec2 uv = (p.xy / p.z).xy - o;
	vec2 local_uv = uv + 0.5;

	// ATLAS UV FINAL
	vec2 atlas_uv = (atlas_offset + local_uv * card_size) / atlas_size;
	vec4 col = texture(TEXTURE, atlas_uv);

	// --- FRESNEL / BRILLO DE BORDES ---
	vec3 normal = vec3(0.0, 0.0, 1.0);       // normal local de la carta
	vec3 view_dir = normalize(p);             // dirección hacia cámara
	float fresnel = pow(1.0 - dot(normal, view_dir), 2.0); // más suave, más visible
	col.rgb *= mix(1.0, edge_brightness, fresnel);

	// recorte limpio
	col.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

	COLOR = col;
}
