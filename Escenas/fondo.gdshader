shader_type canvas_item;

uniform sampler2D albedo_tex : hint_albedo;  // textura base (terreno)
uniform sampler2D normal_map : hint_normal;   // mapa de normales
uniform vec2 light_pos = vec2(0.5, 0.3);      // posición de la luz (0-1)
uniform vec3 light_color = vec3(1.0, 0.95, 0.8);
uniform float light_strength = 1.5;

void fragment() {
    vec2 uv = UV;

    // Color base del terreno
    vec3 base_color = texture(albedo_tex, uv).rgb;

    // Normal del mapa
    vec3 normal = texture(normal_map, uv).rgb * 2.0 - 1.0;

    // Dirección de la luz
    vec3 light_dir = normalize(vec3(light_pos - uv, 0.2));

    // Difuso
    float diff = max(dot(normal, light_dir), 0.0);

    // Color final con iluminación
    vec3 color = base_color * (0.3 + diff * light_color * light_strength);

    COLOR = vec4(color, 1.0);
}
