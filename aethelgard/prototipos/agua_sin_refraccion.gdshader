// Agua sin refracción para los perfiles bajo y medio del prototipo (copia de shaders/water.gdshader
// sin la textura de pantalla: con ella, Godot copia la pantalla entera en cada fotograma aunque la
// refracción esté apagada). Opaca: no se mezcla con lo de detrás, más barata en móviles.
// El shader original no se toca; el perfil alto lo sigue usando con su refracción.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_1 : source_color = vec4(0.04, 0.22, 0.28, 1.0);
uniform vec4 albedo_2 : source_color = vec4(0.18, 0.52, 0.56, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D wave_noise : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float wave_size = 1.5;
uniform float wave_speed = 0.015;
uniform float texture_scale = 0.05;
uniform sampler2D normal_1 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_2 : hint_normal, filter_linear_mipmap, repeat_enable;

varying float altura;


float ola(vec2 uv) {
	return textureLod(wave_noise, uv + TIME * wave_speed, 0.0).r;
}


void vertex() {
	vec2 uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * texture_scale;
	float h = ola(uv);
	altura = h;
	VERTEX.y += h * wave_size;
	float e = 0.01;
	float paso = e / max(texture_scale, 0.0001);
	float dx = (ola(uv + vec2(e, 0.0)) - h) * wave_size / paso;
	float dz = (ola(uv + vec2(0.0, e)) - h) * wave_size / paso;
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}


void fragment() {
	vec2 d1 = TIME * wave_speed * vec2(1.0, 0.4);
	vec2 d2 = TIME * wave_speed * vec2(-0.7, -1.0);
	NORMAL_MAP = mix(texture(normal_1, UV + d1).rgb, texture(normal_2, UV + d2).rgb, 0.5);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);
	ALBEDO = mix(albedo_1.rgb, albedo_2.rgb, clamp(altura * 0.6 + fresnel * 0.4, 0.0, 1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
