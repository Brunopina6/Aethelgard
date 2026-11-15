extends RefCounted
# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11, fase 0): EL TRAZADO, como datos estáticos. Es el CONTRATO común de la
# región (zonas3d/barrio/barrio.gd), los interiores (agente B), las rutinas y la misión (agente C), las pruebas
# (pruebas/prueba_barrio_trazado.gd) y, más adelante, el generador de Blender (fuente/crear_barrio.py, que leerá
# barrio.json escrito desde aquí). Plan: docs/v12/BARRIO_OAKHAVEN_PLAN.md §2 y §11; lo real: docs/v12/BARRIO_OAKHAVEN.md.
# Todo es PROPUESTA [P]: el barrio solo existe en el banco de pruebas de Auditoría y está apagado fuera de él.
#
# Ejes de la escena: x al este, z al sur, y arriba; el origen es el centro de la plaza. Unos 128 m de bucle:
#   caravanas (T1) → calle comercial (T2) → plaza (T3) → patio de talleres (T4) → calle de las casas (T5) → atajo (T6)
#   → caravanas.
# La cámara NUNCA gira (mira siempre al norte): en los tramos de este a oeste, lo alto solo al norte y el lado sur
# ≤ 1,6 m sobre la calle a menos de 4 m del paso; en los de norte a sur, la cámara va fija en su eje.
#
# DÓNDE SE PISA: los rectángulos de SUELOS (con su cota; las rampas son lineales y continuas, también en los dos tramos de
# escalones del atajo, como el callejón de la muestra de la calle), menos lo sólido de BLOQUES que cae dentro (carros,
# puestos, el mostrador, la pila de cajas…). andable() y altura() salen SOLO de aquí, y el blockout de barrio.gd construye
# el suelo y los choques con estos mismos números: si se cambia una cota, cambia todo a la vez.
# Las anclas (ANCLAS) son puntos EN el suelo: ancla(id) les pone la altura de altura() (la «y» escrita es la misma, para
# leerla; la prueba comprueba que coinciden).

# ---------------------------------------------------------------------------------------------------- sectores
# Los 6 tramos del plan (§2) con su Rect2 (x0, z0, ancho, fondo). Dos se han ajustado para que cada uno contenga su paso
# entero: «talleres» llega hasta z −8 (el pie de la rampa) y «residencial» va de x −44 a −5 (toda su calle). Se usan para
# la visibilidad por sector y lo que no se pisa; para lo que se pisa manda el sector de su SUELO (sector_de).
const SECTORES := {
	"caravanas": Rect2(-52.0, -14.0, 20.0, 22.0),
	"comercial": Rect2(-32.0, -9.0, 22.0, 16.0),
	"plaza": Rect2(-10.0, -12.0, 20.0, 20.0),
	"talleres": Rect2(-13.0, -30.0, 24.0, 22.0),
	"residencial": Rect2(-44.0, -40.0, 39.0, 16.0),
	"atajo": Rect2(-46.0, -30.0, 6.0, 24.0),
}
# Cotas de cada tramo (la más baja y la más alta de su suelo).
const COTAS := {
	"caravanas": Vector2(0.0, 0.0),
	"comercial": Vector2(0.0, 0.4),
	"plaza": Vector2(0.4, 0.4),
	"talleres": Vector2(0.4, 1.4),
	"residencial": Vector2(1.4, 1.4),
	"atajo": Vector2(0.0, 1.4),
}
const ORDEN := ["caravanas", "comercial", "plaza", "talleres", "residencial", "atajo"]
# Los tramos de este a oeste (la regla del lado sur bajo).
const TRAMOS_EO := ["caravanas", "comercial", "residencial"]

# ---------------------------------------------------------------------------------------------------- suelo
# [sector, Rect2, eje de la pendiente ("" llano, "x" o "z"), cota al principio del rectángulo, cota al final].
# «Al principio» es su lado oeste (eje x) o norte (eje z): Rect2.position. Los rectángulos no se pisan unos a otros
# (Rect2 es semiabierto: el borde final pertenece al vecino).
const SUELOS := [
	["caravanas", Rect2(-50.0, -8.0, 18.0, 12.0), "", 0.0, 0.0],       # patio de caravanas 18×12
	["comercial", Rect2(-32.0, -1.0, 22.0, 6.0), "x", 0.0, 0.4],       # calle comercial 22×6: sube 0,4 hacia la plaza
	["plaza", Rect2(-10.0, -8.0, 19.0, 15.0), "", 0.4, 0.4],           # plaza del mercado 19×15
	["talleres", Rect2(-5.0, -18.0, 10.0, 10.0), "z", 1.4, 0.4],       # rampa del patio (10 %): 0,4 en z −8 → 1,4 en z −18
	["talleres", Rect2(-5.0, -30.0, 10.0, 12.0), "", 1.4, 1.4],        # patio de talleres, arriba (hasta la calle T5)
	["residencial", Rect2(-44.0, -30.0, 39.0, 4.0), "", 1.4, 1.4],     # calle de las casas 39×4
	["atajo", Rect2(-44.0, -26.0, 4.0, 4.0), "", 1.4, 1.4],            # atajo: arriba
	["atajo", Rect2(-44.0, -22.0, 4.0, 3.0), "z", 1.4, 0.7],           # primer tramo de escalones
	["atajo", Rect2(-44.0, -19.0, 4.0, 6.0), "", 0.7, 0.7],            # rellano (con el arco de paso)
	["atajo", Rect2(-44.0, -13.0, 4.0, 3.0), "z", 0.7, 0.0],           # segundo tramo de escalones
	["atajo", Rect2(-44.0, -10.0, 4.0, 2.0), "", 0.0, 0.0],            # atajo: abajo, junto al establo
]

# ---------------------------------------------------------------------------------------------------- bloques
# Lo que se levanta (el blockout y, después, la guía del kit): [id, sector, Rect2 en planta, base (y del suelo de
# debajo), alto sobre la base, tipo, sólido]. Tipo: casa (con tejado), muro, bajo (vallas, puestos, pretiles), puerta,
# decor, terreno. Lo sólido lleva su caja de choque y, si cae en el suelo, deja de ser andable (sin margen).
const BLOQUES := [
	# T1 caravanas: el muro oeste con el arco de caravanas (rastrillo bajado), el establo al norte, el carro, el abrevadero
	# y, al sur y bajo, el pozo, el heno y la valla.
	["muro_oeste_n", "caravanas", Rect2(-53.0, -44.0, 3.0, 39.8), 0.0, 4.5, "muro", true],
	["torre_arco_n", "caravanas", Rect2(-53.5, -4.2, 3.5, 1.6), 0.0, 6.0, "muro", true],
	["rastrillo", "caravanas", Rect2(-51.4, -2.6, 0.4, 3.2), 0.0, 4.0, "puerta", true],
	["torre_arco_s", "caravanas", Rect2(-53.5, 0.6, 3.5, 1.6), 0.0, 6.0, "muro", true],
	["dintel_arco", "caravanas", Rect2(-53.5, -2.6, 3.5, 3.2), 4.6, 1.4, "muro", false],
	["muro_oeste_s", "caravanas", Rect2(-53.0, 2.2, 3.0, 8.0), 0.0, 4.5, "muro", true],
	["establo", "caravanas", Rect2(-50.0, -15.0, 6.0, 7.0), 0.0, 4.2, "casa", true],
	["carro_caravana", "caravanas", Rect2(-47.0, 1.0, 3.0, 2.0), 0.0, 1.8, "decor", true],
	["abrevadero", "caravanas", Rect2(-50.0, -5.0, 0.8, 2.0), 0.0, 0.7, "bajo", true],
	["pozo", "caravanas", Rect2(-38.1, 4.1, 1.4, 1.4), 0.0, 0.9, "muro", true],
	["heno", "caravanas", Rect2(-48.0, 4.4, 3.0, 1.2), 0.0, 1.2, "decor", true],
	["valla_sur", "caravanas", Rect2(-50.0, 5.8, 18.0, 0.3), 0.0, 1.0, "bajo", true],
	# T2 calle comercial: fachadas al norte (tienda, HORNO con su mostrador a la calle y chimenea, tienda); al sur, bajo.
	["tienda_o", "comercial", Rect2(-32.0, -9.0, 6.0, 8.0), 0.0, 6.5, "casa", true],
	["horno", "comercial", Rect2(-26.0, -9.0, 8.0, 8.0), 0.0, 6.0, "casa", true],
	["chimenea_horno", "comercial", Rect2(-21.0, -7.0, 1.2, 1.2), 6.0, 2.2, "muro", false],
	["hoja_horno", "comercial", Rect2(-22.7, -1.0, 1.4, 0.08), 0.18, 2.3, "puerta", false],
	["mostrador_horno", "comercial", Rect2(-20.6, -1.0, 2.2, 0.6), 0.2, 1.0, "bajo", true],
	["tienda_e", "comercial", Rect2(-18.0, -9.0, 8.0, 8.0), 0.0, 7.0, "casa", true],
	["puesto_c1", "comercial", Rect2(-30.0, 5.4, 4.0, 1.6), 0.0, 1.4, "bajo", true],
	["puesto_c2", "comercial", Rect2(-24.0, 5.4, 3.0, 1.6), 0.0, 1.2, "bajo", true],
	["cajones_c1", "comercial", Rect2(-17.0, 5.3, 2.0, 1.2), 0.0, 0.8, "decor", true],
	["carro_horno", "comercial", Rect2(-14.8, 3.6, 2.6, 1.4), 0.3, 1.5, "decor", true],
	["cajones_c2", "comercial", Rect2(-12.0, 5.6, 2.0, 1.0), 0.0, 0.9, "decor", true],
	# T3 plaza: la muralla de Oakhaven al este con el postigo cerrado (decorado), la lonja al noreste, puestos bajos. Sin
	# fuente (es de la Plaza del Tapiz).
	["muralla_oak", "plaza", Rect2(9.0, -16.0, 2.5, 28.0), 0.0, 8.0, "muro", true],
	["postigo", "plaza", Rect2(8.92, -2.0, 0.1, 2.0), 0.4, 2.4, "puerta", false],
	["casa_plaza_no", "plaza", Rect2(-10.0, -12.0, 5.0, 4.0), 0.0, 6.0, "casa", true],
	["cobertizo", "plaza", Rect2(-13.0, -12.0, 3.0, 3.0), 0.0, 3.0, "casa", true],
	["lonja", "plaza", Rect2(5.0, -12.0, 4.0, 4.0), 0.0, 6.0, "casa", true],
	["puesto_pan", "plaza", Rect2(-4.0, 3.6, 2.4, 1.4), 0.4, 1.4, "bajo", true],
	["puesto_p2", "plaza", Rect2(2.0, 4.0, 2.4, 1.4), 0.4, 1.3, "bajo", true],
	["puesto_p3", "plaza", Rect2(-7.5, -5.5, 2.0, 1.2), 0.4, 1.2, "bajo", true],
	["pretil_plaza", "plaza", Rect2(-10.0, 7.2, 19.0, 0.4), 0.0, 1.0, "muro", true],
	# T4 patio de talleres: el TALLER del carretero al oeste (bajo: no tapa la calle T5) con su portón al este, la
	# tonelería de decorado al este, la pila de cajas y las ruedas apoyadas.
	["taller", "talleres", Rect2(-13.0, -22.0, 8.0, 10.0), 1.4, 3.4, "casa", true],
	["porton_taller", "talleres", Rect2(-5.0, -20.4, 0.08, 1.8), 1.4, 2.8, "puerta", false],
	["toneleria", "talleres", Rect2(5.0, -30.0, 4.0, 18.0), 0.4, 5.0, "casa", true],
	["pila_patio", "talleres", Rect2(2.6, -24.0, 1.6, 1.6), 1.4, 1.2, "decor", true],
	["ruedas", "talleres", Rect2(-4.9, -15.5, 0.4, 1.6), 0.9, 1.1, "decor", true],
	["casa_patio_n", "talleres", Rect2(-5.0, -38.0, 10.0, 8.0), 1.4, 6.0, "casa", true],
	["casa_tonel_n", "talleres", Rect2(5.0, -38.0, 6.0, 8.0), 1.4, 6.0, "casa", true],
	# T5 calle de las casas: casas al norte (la VIVIENDA en x −26..−18), huertos bajos al sur, el muro del arrabal.
	["casa_esquina_no", "residencial", Rect2(-50.0, -38.0, 6.0, 8.0), 1.4, 6.0, "casa", true],
	["casa_r1", "residencial", Rect2(-44.0, -38.0, 9.0, 8.0), 1.4, 6.0, "casa", true],
	["casa_r2", "residencial", Rect2(-35.0, -38.0, 9.0, 8.0), 1.4, 7.0, "casa", true],
	["vivienda", "residencial", Rect2(-26.0, -38.0, 8.0, 8.0), 1.4, 6.5, "casa", true],
	["hoja_vivienda", "residencial", Rect2(-22.7, -30.0, 1.4, 0.08), 1.4, 2.4, "puerta", false],
	["casa_r4", "residencial", Rect2(-18.0, -38.0, 13.0, 8.0), 1.4, 6.5, "casa", true],
	["huertos", "residencial", Rect2(-40.0, -26.0, 35.0, 8.0), 0.0, 1.4, "terreno", true],
	["valla_huertos", "residencial", Rect2(-40.0, -25.7, 26.5, 0.2), 1.4, 0.9, "bajo", true],
	["tendedero", "residencial", Rect2(-33.0, -30.5, 4.0, 0.1), 3.6, 0.1, "decor", false],
	["muro_arrabal_n", "residencial", Rect2(-54.0, -44.0, 67.0, 1.5), 0.0, 4.0, "muro", true],
	# T6 atajo: callejón entre casas, con un arco de paso sin techo y una hornacina; al este, abierto a los huertos arriba.
	["casa_atajo_o", "atajo", Rect2(-50.0, -30.0, 6.0, 15.0), 0.7, 6.0, "casa", true],
	["casa_atajo_e", "atajo", Rect2(-40.0, -18.0, 8.0, 10.0), 0.4, 6.0, "casa", true],
	["valla_atajo", "atajo", Rect2(-39.9, -26.0, 0.2, 4.0), 1.4, 0.9, "bajo", true],
	["arco_atajo", "atajo", Rect2(-44.0, -17.0, 4.0, 0.6), 3.9, 0.6, "muro", false],
	["hornacina", "atajo", Rect2(-40.1, -14.6, 0.1, 0.8), 2.0, 1.0, "decor", false],
]

# ---------------------------------------------------------------------------------------------------- anclas
# Nombres FIJOS del contrato (plan §11). Puntos en el suelo, en metros (la «y» = altura(x, z)).
const INICIO := Vector3(-38.5, 0.0, 1.0)
const ANCLAS := {
	"inicio": Vector3(-38.5, 0.0, 1.0),               # al entrar desde el banco: en el patio de caravanas, mirando al este
	"arco_caravanas": Vector3(-49.4, 0.0, -1.0),      # delante del rastrillo bajado (decorado)
	"postigo_oak": Vector3(8.4, 0.4, -1.0),           # delante del postigo cerrado de la muralla de Oakhaven (decorado)
	"carro_caravana": Vector3(-45.5, 0.0, 0.2),       # junto al carro de caravana (donde se coge la caja)
	"pozo": Vector3(-37.4, 0.0, 3.4),                 # delante del pozo (lado sur, bajo)
	"abrevadero": Vector3(-48.6, 0.0, -4.0),          # delante del abrevadero
	"establo_caballo": Vector3(-48.0, 0.0, -6.8),     # donde está atada Avena, ante el establo
	"gancho_cepillo": Vector3(-45.6, 0.0, -7.4),      # bajo el gancho del cepillo, en la pared del establo
	"puerta_horno": Vector3(-22.0, 0.182, -1.0),      # el umbral del horno (en la fachada)
	"mostrador_horno": Vector3(-19.5, 0.227, 0.2),    # delante del mostrador que da a la calle
	"carro_horno": Vector3(-13.5, 0.336, 2.9),        # junto al carro de reparto del horno, parado
	"puesto_plaza": Vector3(-2.8, 0.4, 2.9),          # delante del puesto del pan de la plaza
	"pila_patio": Vector3(2.0, 1.4, -23.2),           # junto a la pila de cajas del patio
	"puerta_taller": Vector3(-4.6, 1.4, -19.5),       # delante del portón del taller (lado este)
	"puerta_vivienda": Vector3(-22.0, 1.4, -30.0),    # el umbral de la vivienda (en la fachada)
	# nodos del grafo (en la calle, nunca en el eje de una puerta)
	"n_carav": Vector3(-41.0, 0.0, 2.0),
	"n_establo": Vector3(-46.5, 0.0, -5.5),
	"n_pozo": Vector3(-36.5, 0.0, 2.5),
	"n_com_o": Vector3(-30.0, 0.036, 2.0),
	"n_horno": Vector3(-24.5, 0.136, 1.5),
	"n_com_e": Vector3(-12.0, 0.364, 1.5),
	"n_plaza_o": Vector3(-8.0, 0.4, 2.0),
	"n_plaza": Vector3(0.0, 0.4, 0.0),
	"n_patio_s": Vector3(0.0, 0.55, -9.5),
	"n_patio_n": Vector3(0.0, 1.4, -24.0),
	"n_res_e": Vector3(-7.5, 1.4, -28.0),
	"n_res_c": Vector3(-25.0, 1.4, -27.2),
	"n_res_o": Vector3(-41.0, 1.4, -28.0),
	"n_atajo_n": Vector3(-42.0, 1.4, -24.0),
	"n_atajo_s": Vector3(-42.0, 0.0, -9.0),
}
# Los nombres que el contrato exige (la prueba mira que estén todos).
const ANCLAS_CONTRATO := ["inicio", "arco_caravanas", "postigo_oak", "carro_caravana", "pozo", "abrevadero",
	"establo_caballo", "gancho_cepillo", "puerta_horno", "mostrador_horno", "carro_horno", "puesto_plaza", "pila_patio",
	"puerta_taller", "puerta_vivienda", "n_carav", "n_establo", "n_pozo", "n_com_o", "n_horno", "n_com_e", "n_plaza_o",
	"n_plaza", "n_patio_s", "n_patio_n", "n_res_e", "n_res_c", "n_res_o", "n_atajo_n", "n_atajo_s"]

# Umbrales (Rect2 en x, z): nadie se para dentro (los NPC los cruzan sin detenerse). Las anclas «puerta_*» son el propio
# umbral; ninguna otra ancla ni nodo cae dentro.
const PASOS := {
	"paso_horno": Rect2(-22.8, -1.0, 1.6, 1.2),
	"paso_taller": Rect2(-5.0, -20.3, 1.2, 1.6),
	"paso_vivienda": Rect2(-22.8, -30.0, 1.6, 1.2),
	"paso_atajo": Rect2(-44.0, -17.0, 4.0, 1.0),        # bajo el arco del atajo
}

# Puertas a los interiores (agente B). «fuera»: donde aparece Kael al salir (y el centro del botón); «mira»: hacia dónde
# mira al salir, ángulo de rotation.y de Godot (0 = norte, PI = sur, −PI/2 = este); «radio» del botón; «texto» del
# botón. Además (no en el plan, para B y C): «ancla» del umbral y «paso» (su umbral en PASOS).
const PUERTAS := {
	"horno": {"fuera": Vector3(-22.0, 0.182, -0.3), "mira": PI, "radio": 1.6, "texto": "Entrar en el horno",
		"ancla": "puerta_horno", "paso": "paso_horno"},
	"taller": {"fuera": Vector3(-4.0, 1.4, -19.5), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en el taller",
		"ancla": "puerta_taller", "paso": "paso_taller"},
	"vivienda": {"fuera": Vector3(-22.0, 1.4, -29.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_vivienda", "paso": "paso_vivienda"},
}

# El grafo de caminos de los NPC (agente C): nodo → vecinos. Simétrico; cada arista es un tramo RECTO que se puede andar
# entero (sin búsqueda de caminos).
const GRAFO := {
	"n_carav": ["n_establo", "n_pozo", "n_com_o", "n_atajo_s"],
	"n_establo": ["n_carav", "n_atajo_s"],
	"n_pozo": ["n_carav", "n_com_o"],
	"n_com_o": ["n_carav", "n_pozo", "n_horno"],
	"n_horno": ["n_com_o", "n_com_e"],
	"n_com_e": ["n_horno", "n_plaza_o"],
	"n_plaza_o": ["n_com_e", "n_plaza"],
	"n_plaza": ["n_plaza_o", "n_patio_s"],
	"n_patio_s": ["n_plaza", "n_patio_n"],
	"n_patio_n": ["n_patio_s", "n_res_e"],
	"n_res_e": ["n_patio_n", "n_res_c"],
	"n_res_c": ["n_res_e", "n_res_o"],
	"n_res_o": ["n_res_c", "n_atajo_n"],
	"n_atajo_n": ["n_res_o", "n_atajo_s"],
	"n_atajo_s": ["n_atajo_n", "n_establo", "n_carav"],
}
# El bucle que anda Kael en la prueba (y el recorrido de las capturas).
const BUCLE := ["inicio", "n_com_o", "n_horno", "n_com_e", "n_plaza_o", "n_plaza", "n_patio_s", "n_patio_n", "n_res_e",
	"n_res_c", "n_res_o", "n_atajo_n", "n_atajo_s", "n_establo", "n_carav", "inicio"]

# ---------------------------------------------------------------------------------------------------- cámara
# La MISMA cámara que la muestra de la calle (su camara_muestra): 10,8 m sobre el foco, 14,2 m al sur, 25° hacia abajo,
# campo de 38°, sin girar nunca. La prueba comprueba que los números siguen siendo los de la muestra.
const OFFSET_CAMARA := Vector3(0.0, 10.8, 14.2)
const INCLINACION := 25.0
const CAMPO := 38.0
const MARGEN_CAMARA := 2.5          # metros de fundido (smoothstep) desde el borde de cada zona hacia dentro
# Zonas: el foco de cada una y su peso (smoothstep de la distancia al borde de su rectángulo); el foco final es la media
# pesada, así que es continuo. Modos:
#   "x"     riel de este a oeste: x = clamp(Kael.x, x), z = z_riel + min(0, Kael.z − z_riel)·0,55 (como la muestra)
#   "eje"   tramo de norte a sur: x = eje, z = clamp(Kael.z, z)
#   "libre" plaza: x y z siguen a Kael dentro de sus límites
# Los rectángulos se salen de lo andable al menos MARGEN_CAMARA (todo lo que se pisa tiene alguna zona con peso) y se
# solapan entre tramos vecinos (ahí la cámara pasa de una a otra sin saltos).
const CAMARA_ZONAS := [
	{"sector": "caravanas", "rect": Rect2(-56.0, -13.0, 27.0, 21.0), "modo": "x", "x": Vector2(-49.0, -36.0), "z_riel": 0.5},
	{"sector": "comercial", "rect": Rect2(-35.0, -5.0, 27.0, 13.0), "modo": "x", "x": Vector2(-29.0, -13.0), "z_riel": 2.0},
	{"sector": "plaza", "rect": Rect2(-13.0, -11.0, 26.0, 21.0), "modo": "libre", "x": Vector2(-6.0, 5.0), "z": Vector2(-5.0, 4.0)},
	{"sector": "talleres", "rect": Rect2(-8.0, -33.0, 16.0, 27.0), "modo": "eje", "eje": 0.0, "z": Vector2(-29.0, -8.0)},
	{"sector": "residencial", "rect": Rect2(-47.0, -34.0, 44.0, 11.0), "modo": "x", "x": Vector2(-41.0, -8.0), "z_riel": -28.0},
	{"sector": "atajo", "rect": Rect2(-47.0, -28.0, 10.0, 22.0), "modo": "eje", "eje": -42.0, "z": Vector2(-27.0, -8.0)},
]


# ==================================================================================================== funciones

# El índice del SUELO que hay en (x, z), o −1.
static func suelo_en(x: float, z: float) -> int:
	var q := Vector2(x, z)
	for i in SUELOS.size():
		if (SUELOS[i][1] as Rect2).has_point(q):
			return i
	return -1


# El bloque sólido que ocupa (x, z), o "".
static func bloque_en(x: float, z: float) -> String:
	var q := Vector2(x, z)
	for b in BLOQUES:
		if b[6] and (b[2] as Rect2).has_point(q):
			return b[0]
	return ""


# ¿Se puede estar en (x, z)? En un suelo y fuera de todo lo sólido.
static func andable(x: float, z: float) -> bool:
	return suelo_en(x, z) >= 0 and bloque_en(x, z) == ""


# La cota de lo que se pisa en (x, z). Fuera de los suelos, la del suelo más cercano (para colocar cosas al borde).
static func altura(x: float, z: float) -> float:
	var i := suelo_en(x, z)
	if i < 0:
		i = _suelo_cercano(x, z)
	var s: Array = SUELOS[i]
	var r: Rect2 = s[1]
	match String(s[2]):
		"x":
			return lerpf(s[3], s[4], clampf((x - r.position.x) / r.size.x, 0.0, 1.0))
		"z":
			return lerpf(s[3], s[4], clampf((z - r.position.y) / r.size.y, 0.0, 1.0))
	return float(s[3])


static func _suelo_cercano(x: float, z: float) -> int:
	var mejor := 0
	var dmin := INF
	for i in SUELOS.size():
		var r: Rect2 = SUELOS[i][1]
		var c := Vector2(clampf(x, r.position.x, r.end.x), clampf(z, r.position.y, r.end.y))
		var d := c.distance_to(Vector2(x, z))
		if d < dmin:
			dmin = d
			mejor = i
	return mejor


# El sector de (x, z): el de su suelo si se pisa; si no, el primer rectángulo de SECTORES que lo contiene; si no, "".
static func sector_de(x: float, z: float) -> String:
	var i := suelo_en(x, z)
	if i >= 0:
		return SUELOS[i][0]
	var q := Vector2(x, z)
	for s in ORDEN:
		if (SECTORES[s] as Rect2).has_point(q):
			return s
	return ""


# El umbral (PASOS) en el que cae (x, z), o "".
static func en_paso(x: float, z: float) -> String:
	var q := Vector2(x, z)
	for p in PASOS:
		if (PASOS[p] as Rect2).has_point(q):
			return p
	return ""


# Un ancla exterior, en el suelo. Un nombre que no existe avisa y da el inicio.
static func ancla(id: String) -> Vector3:
	if not ANCLAS.has(id):
		push_warning("Barrio: no hay ancla «%s»" % id)
		return INICIO
	var a: Vector3 = ANCLAS[id]
	return Vector3(a.x, altura(a.x, a.z), a.z)


# ---------------------------------------------------------------------------------------------------- cámara

# Lo que pesa cada zona de cámara en (x, z): 0 fuera de su rectángulo, 1 a MARGEN_CAMARA o más de su borde.
static func peso_zona(zona: Dictionary, x: float, z: float) -> float:
	var r: Rect2 = zona["rect"]
	var d := minf(minf(x - r.position.x, r.end.x - x), minf(z - r.position.y, r.end.y - z))
	if d <= 0.0:
		return 0.0
	return smoothstep(0.0, MARGEN_CAMARA, d)


static func _foco_zona(zona: Dictionary, k: Vector3) -> Vector2:
	match String(zona["modo"]):
		"x":
			var zr: float = zona["z_riel"]
			var rx: Vector2 = zona["x"]
			return Vector2(clampf(k.x, rx.x, rx.y), zr + minf(0.0, k.z - zr) * 0.55)
		"eje":
			var ez: Vector2 = zona["z"]
			return Vector2(float(zona["eje"]), clampf(k.z, ez.x, ez.y))
	var lx: Vector2 = zona["x"]
	var lz: Vector2 = zona["z"]
	return Vector2(clampf(k.x, lx.x, lx.y), clampf(k.z, lz.x, lz.y))


# La suma de los pesos en (x, z) (la prueba exige > 0 en todo lo que se pisa).
static func peso_total(x: float, z: float) -> float:
	var s := 0.0
	for zona in CAMARA_ZONAS:
		s += peso_zona(zona, x, z)
	return s


# Adónde va el foco de la cámara con Kael en k (la cámara se pone en foco + OFFSET_CAMARA). Altura: k.y·0,6, como la
# muestra.
static func foco_camara(k: Vector3) -> Vector3:
	var suma := 0.0
	var acc := Vector2.ZERO
	var cerca: Dictionary = CAMARA_ZONAS[0]
	var dmax := -INF
	for zona in CAMARA_ZONAS:
		var w := peso_zona(zona, k.x, k.z)
		if w > 0.0:
			acc += _foco_zona(zona, k) * w
			suma += w
		var r: Rect2 = zona["rect"]
		var d := minf(minf(k.x - r.position.x, r.end.x - k.x), minf(k.z - r.position.y, r.end.y - k.z))
		if d > dmax:
			dmax = d
			cerca = zona
	var f := acc / suma if suma > 0.0 else _foco_zona(cerca, k)   # (fuera de todas: la zona más cercana)
	return Vector3(f.x, k.y * 0.6, f.y)


# Pone la cámara del barrio mirando al foco: misma altura, inclinación y campo que la muestra, sin giro.
static func poner_camara(c: Camera3D, foco: Vector3) -> void:
	c.projection = Camera3D.PROJECTION_PERSPECTIVE
	c.global_position = foco + OFFSET_CAMARA
	c.global_rotation = Vector3(deg_to_rad(-INCLINACION), 0.0, 0.0)
	c.fov = CAMPO
