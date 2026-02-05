shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 300.0) = 8.0;
uniform float frequency : hint_range(0.0, 10.0) = 3.0;
uniform float speed : hint_range(0.0, 10.0) = 1.5;
uniform float tightness : hint_range(0.0, 5.0) = 0.3;

uniform sampler2D normal_map : hint_normal;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

uniform vec2 mouse_pos = vec2(0.0, 0.0);
uniform float pull_radius = 150.0;
uniform float pull_strength = 20.0;

void vertex() {
    float t = TIME * speed;

    // Onda viento
    float anchor = smoothstep(0, tightness, UV.x);
    float wave = sin(UV.y * frequency * 6.28318 + t) * amplitude * anchor;
    VERTEX.y += wave;

    // Atracción al ratón estilo Mario 64
    vec2 to_mouse = mouse_pos - VERTEX;
    float dist = length(to_mouse);

    if (dist < pull_radius) {
        float force = (1.0 - dist / pull_radius) * pull_strength;
        VERTEX += normalize(to_mouse) * force;
    }
}

void fragment() {
    vec4 albedo = texture(TEXTURE, UV);

    vec3 n = texture(normal_map, UV).rgb;
    n = n * 2.0 - 1.0;
    n.xy *= normal_strength;
    n = normalize(n);

    vec3 light_dir = normalize(vec3(-0.4, -0.7, 0.6));
    float ndotl = clamp(dot(n, light_dir), 0.0, 1.0);

    vec3 lit = albedo.rgb * (0.8 + ndotl * 0.6);

    COLOR = vec4(lit, albedo.a);
}
