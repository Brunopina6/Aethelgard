// Héroes v3 (V12): luz «pintada» común al cuerpo y a la cara. Compatibility (GLES3): light() propio.
//   - Difusa en dos tonos con un terminador suave (media lambert + escalón suavizado) mezclada con el degradado
//     continuo, para que no parezca recortado; la sombra no es gris: se tiñe (fría en tela y pelo, cálida en la piel).
//   - Borde de luz del lado iluminado (silueta legible sobre fondos oscuros), con la luz de la escena.
//   - Brillos por tipo de material (el tipo va en el alfa del color por vértice): metal (brillo nítido teñido),
//     pelo (franja de brillo que sigue a la luz, rota por las hebras), cristal (destello), cuero (brillo ancho y suave).
uniform float terminador = 0.42;            // dónde cae la sombra propia (0..1 en media lambert)
uniform float suavidad = 0.14;              // ancho del paso de luz a sombra
uniform float degradado = 0.60;             // cuánto degradado continuo se mezcla con el escalón
uniform float nivel_sombra = 0.40;          // luz que queda en la sombra propia (con el tinte)
uniform float exposicion = 0.56;            // la luz plena (el escalón da más luz que una lambert: se compensa)
uniform vec3 sombra_fria : source_color = vec3(0.70, 0.74, 0.95);
uniform vec3 sombra_calida : source_color = vec3(0.90, 0.86, 0.96);
uniform float borde_luz = 0.22;
uniform float brillo_pelo = 0.30;
uniform vec3 color_brillo_pelo : source_color = vec3(0.55, 0.70, 1.0);

varying float v_tipo;
varying float v_hebra;

void light() {
	float t = v_tipo;
	float w = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float paso = smoothstep(terminador - suavidad, terminador + suavidad, w);
	float luz = mix(paso, w, degradado);
	float sombra_proy = ATTENUATION;
	luz *= mix(0.4, 1.0, sombra_proy);
	bool piel = t > 0.5 && t < 1.5;
	vec3 tinte = piel ? sombra_calida : sombra_fria;
	vec3 c = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += c * mix(tinte * nivel_sombra, vec3(1.0), luz) * exposicion;
	float nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float borde = pow(1.0 - nv, 3.0) * smoothstep(0.3, 0.8, w) * sombra_proy;
	DIFFUSE_LIGHT += c * borde * borde_luz;
	vec3 h = normalize(LIGHT + VIEW);
	float nh = max(dot(NORMAL, h), 0.0);
	if (t > 2.5 && t < 3.5) {               // metal
		SPECULAR_LIGHT += c * ALBEDO * (pow(nh, 48.0) * 2.5 + pow(nh, 8.0) * 0.25) * luz;
	} else if (t > 4.5 && t < 5.5) {        // pelo: franja que sigue a la luz, rota por las hebras
		float anillo = smoothstep(0.82, 0.95, nh) * smoothstep(0.35, 0.75, v_hebra);
		SPECULAR_LIGHT += c * color_brillo_pelo * anillo * brillo_pelo * luz;
	} else if (t > 3.5 && t < 4.5) {        // cristal
		SPECULAR_LIGHT += c * (pow(nh, 64.0) * 2.0 + pow(nh, 6.0) * 0.3 * ALBEDO);
	} else if (t > 1.5 && t < 2.5) {        // cuero
		SPECULAR_LIGHT += c * pow(nh, 16.0) * 0.12 * luz;
	}
}
