// Nix desde el FBX (piloto APAGADO, 14/11): material del CUERPO = el de los héroes v2 (heroe_v2.gdshader, copiado tal
// cual; si cambia aquél, cambiar también éste) + EMISIÓN SUAVE SOLO EN EL IRIS para que los ojos amatista se lean a la
// distancia del juego (exploración y combate), sin brillar como un faro.
//
// La máscara va sobre la propia textura, sin textura nueva ni coste de memoria: dentro de los dos rectángulos del atlas
// donde están los iris (medidos en Blender, fuente_blender/p11_iris.py) y solo en los texeles violetas (color
// normalizado: azul y rojo por encima del verde). Así quedan fuera la esclerótica (gris o blanca: sin rojo sobre verde),
// la piel (el rojo manda, no el azul), las pestañas y la pupila (oscuras o sin rojo). La emisión es el color del propio
// iris por un factor pequeño (×0,35 de cerca; ×0,9 a la distancia del juego, donde el ojo es de 1-3 píxeles y además
// se usa el color del texel exacto del iris en vez de la mezcla del mipmap) y nunca toca nada más.
// Lo pone nix_fbx.gd (poner_iris) solo en la malla «cuerpo_nix» cuando el interruptor nix_fbx está encendido.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert_wrap, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool tiene_normal = false;
uniform float relieve = 1.0;
uniform sampler2D rugosidad_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool tiene_rugosidad = false;
uniform vec4 canal_rugosidad = vec4(0.0, 1.0, 0.0, 0.0);
uniform sampler2D metal_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool tiene_metal = false;
uniform vec4 canal_metal = vec4(0.0, 0.0, 1.0, 0.0);
uniform float rugosidad = 1.0;
uniform float metal = 0.0;
uniform float umbral_metal = 0.45;
uniform float rugosidad_mate = 0.72;
uniform float especular_mate = 0.28;
uniform vec2 rugosidad_metal = vec2(0.22, 0.6);
uniform float borde = 0.2;
uniform float tinte_borde = 0.4;
uniform float reflejo = 0.5;
uniform vec3 cielo : source_color = vec3(0.78, 0.84, 0.95);
uniform vec3 suelo : source_color = vec3(0.30, 0.26, 0.22);
uniform float energia_entorno = 1.0;
// iris: rectángulos del atlas (u0, v0, u1, v1; v hacia abajo, como UV en Godot), umbrales y brillo
uniform vec4 iris_a = vec4(0.4619, 0.3555, 0.4893, 0.3926);
uniform vec4 iris_b = vec4(0.3145, 0.2471, 0.3408, 0.2764);
uniform vec2 iris_azul = vec2(0.12, 0.30);     // (azul - verde) / máximo
uniform vec2 iris_rojo = vec2(0.02, 0.08);     // (rojo - verde) / máximo
uniform vec2 iris_brillo = vec2(0.35, 0.9);    // factor de cerca (retrato, diálogo) y a la distancia del juego
// «de lejos» = texeles del atlas por píxel de pantalla (vale igual con la cámara ortográfica del combate y la de
// perspectiva de la exploración): de cerca hasta el primero, de lejos desde el segundo
uniform vec2 iris_densidad = vec2(1.5, 6.0);
uniform float iris_nitidez = 1.0;              // de lejos, cuánto color del texel exacto del iris (0: el del mipmap)

float en_rect(vec2 uv, vec4 r) {
	vec2 d = step(r.xy, uv) * step(uv, r.zw);
	return d.x * d.y;
}

void fragment() {
	vec4 a = texture(albedo_tex, UV) * color;
	ALBEDO = a.rgb;
	float r = rugosidad;
	if (tiene_rugosidad) {
		r *= dot(texture(rugosidad_tex, UV), canal_rugosidad);
	}
	float mt = metal;
	if (tiene_metal) {
		mt *= dot(texture(metal_tex, UV), canal_metal);
	}
	float m = smoothstep(umbral_metal - 0.12, umbral_metal + 0.12, mt);
	r = mix(max(r, rugosidad_mate), clamp(r, rugosidad_metal.x, rugosidad_metal.y), m);
	ROUGHNESS = r;
	METALLIC = m * 0.85;
	SPECULAR = mix(especular_mate, 0.5, m);
	if (tiene_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = relieve;
	}
	RIM = borde;
	RIM_TINT = tinte_borde;
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 rf = reflect(-v, n);
	vec3 entorno = mix(suelo, cielo, smoothstep(-0.35, 0.55, rf.y));
	EMISSION = entorno * a.rgb * m * reflejo * (1.0 - r * 0.7) * energia_entorno;
	// iris (las derivadas, fuera del «if»; dentro solo se lee el texel exacto, sin derivadas: solo en los dos rectángulos)
	vec2 tpp = fwidth(UV) * vec2(textureSize(albedo_tex, 0));
	float lejos = smoothstep(iris_densidad.x, iris_densidad.y, max(tpp.x, tpp.y));
	if (en_rect(UV, iris_a) + en_rect(UV, iris_b) > 0.0) {
		// el texel exacto (nivel 0): de lejos el mipmap mezcla el iris con la piel y las pestañas y se perdía el violeta
		vec3 a0 = textureLod(albedo_tex, UV, 0.0).rgb * color.rgb;
		float mx = max(a0.r, max(a0.g, a0.b));
		vec3 c = a0 / max(mx, 0.001);
		float iris = smoothstep(iris_azul.x, iris_azul.y, c.b - c.g) * smoothstep(iris_rojo.x, iris_rojo.y, c.r - c.g)
			* smoothstep(0.01, 0.04, mx);
		// de lejos, el color del texel exacto en vez de la mezcla del mipmap (que daba color piel): el violeta se lee
		// por su color, sin tener que subir la emisión hasta que se vea blanco
		ALBEDO = mix(ALBEDO, a0, iris * lejos * iris_nitidez);
		EMISSION += a0 * iris * mix(iris_brillo.x, iris_brillo.y, lejos);
	}
}
