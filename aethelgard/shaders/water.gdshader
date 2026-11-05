// Agua 3D para Aethelgard (Godot 4.x, funciona en Compatibility y en Forward+).
// Olas: los vértices suben y bajan con una textura de ruido que se desplaza con el tiempo.
// Brillo: dos mapas de normales que se mueven en direcciones opuestas.
// Transparencia con refracción opcional (deforma lo que se ve debajo usando la pantalla).
//
// Cómo usarlo:
//   - Malla: un PlaneMesh con subdivisiones (32×32 en el móvil, 64×64 en PC) para que se noten las olas.
//   - wave_noise: NoiseTexture2D con «Seamless» activado (FastNoiseLite dentro).
//   - normal_1 y normal_2: NoiseTexture2D con «Seamless» y «As Normal Map» activados (dos semillas distintas).
//   - En el móvil, mejor enable_refraction = false: copiar la pantalla cada fotograma es caro.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

group_uniforms colores;
uniform vec4 albedo_1 : source_color = vec4(0.04, 0.22, 0.28, 1.0);   // tono base oscuro
uniform vec4 albedo_2 : source_color = vec4(0.18, 0.52, 0.56, 1.0);   // tono claro (crestas y bordes)
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

group_uniforms olas;
uniform sampler2D wave_noise : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float wave_size = 1.5;
uniform float wave_speed = 0.015;
uniform float texture_scale = 0.05;

group_uniforms normales;
uniform sampler2D normal_1 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_2 : hint_normal, filter_linear_mipmap, repeat_enable;

group_uniforms transparencia;
uniform bool enable_refraction = true;
uniform float refraction_strength : hint_range(0.0, 2.0) = 0.5;
uniform float transparency : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

varying float altura;   // altura de la ola (0 a 1) para mezclar los dos colores


float ola(vec2 uv) {
	return textureLod(wave_noise, uv + TIME * wave_speed, 0.0).r;
}


void vertex() {
	// UV en coordenadas del mundo: varios trozos de agua juntos encajan sin costuras
	vec2 uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * texture_scale;
	float h = ola(uv);
	altura = h;
	VERTEX.y += h * wave_size;
	// normal de la superficie deformada (si no, la luz se vería plana aunque haya olas)
	float e = 0.01;
	float paso = e / max(texture_scale, 0.0001);   // lo que mide «e» en metros
	float dx = (ola(uv + vec2(e, 0.0)) - h) * wave_size / paso;
	float dz = (ola(uv + vec2(0.0, e)) - h) * wave_size / paso;
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}


void fragment() {
	// dos mapas de normales que se mueven en direcciones opuestas
	vec2 d1 = TIME * wave_speed * vec2(1.0, 0.4);
	vec2 d2 = TIME * wave_speed * vec2(-0.7, -1.0);
	vec3 n = mix(texture(normal_1, UV + d1).rgb, texture(normal_2, UV + d2).rgb, 0.5);
	NORMAL_MAP = n;

	// color: más claro en las crestas y de lado (fresnel)
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);
	vec3 color = mix(albedo_1.rgb, albedo_2.rgb, clamp(altura * 0.6 + fresnel * 0.4, 0.0, 1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;

	if (enable_refraction) {
		// lo que hay detrás, deformado por las normales; se mezcla con el color del agua
		vec2 desvio = (n.rg * 2.0 - 1.0) * refraction_strength * 0.05;
		vec3 fondo = texture(screen_texture, SCREEN_UV + desvio).rgb;
		float ver = transparency * (1.0 - fresnel);   // de lado el agua refleja más y deja ver menos
		ALBEDO = color * (1.0 - ver);
		EMISSION = fondo * ver;
		ALPHA = 1.0;
	} else {
		ALBEDO = color;
		ALPHA = 1.0 - transparency;
	}
}
