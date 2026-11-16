extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 5, PASAJES VIEJOS. Maqueta del agente C (sectores 5 y 6) sobre el
# trazado mínimo de M0. Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§3; contrato: docs/v12/CIUDAD_OAKHAVEN.md; lo hecho
# aquí: docs/v12/ciudad_sectores/C.md. Bordes acordados (plano.gd, CONEXIONES; no se cambian aquí): Paso Cubierto de la
# Botica (x −30, z 54..57, cota 2), Pasaje de las Velas (z 50, x −70..−68, cota 2) y Arco de los Pasajes (x −30,
# z 80..83, cota 1).
#
# Coordenadas de CIUDAD (x este, z sur, y arriba). Todo es PROPUESTA [P] salvo lo marcado [C] (ciudades/oakhaven.gd: el
# callejón de Pip «al fondo, una grieta con luz», la grieta «paso estrecho y escondido al Patio de las Velas», el Patio de
# las Velas «rincón escondido» con un altar pequeño y velas encendidas). La Botica de Selene [C] está al otro lado del Paso
# Cubierto, en la plaza (sector 2, agente A): aquí NO se duplica.
#   - NORTE (cota 2): el Pasaje de las Velas baja del Patio del Cuervo; el Callejón de las Macetas [P] (al oeste) y el
#     Callejón Alto [P] (al este) salen de él; la Plazuela del Pozo [P] (ensanche para orientarse, pozo, árbol, el taller
#     del cestero [P]) y el Paso Cubierto de la Botica (corredor bajo una casa) hasta la plaza.
#   - EL SECRETO [C]: del Callejón Alto sale el callejón de Pip, SIN SALIDA; al fondo, la grieta (1,2 m, entre dos muros)
#     baja al Patio de las Velas (cota 1,45), que no tiene otra entrada. En la maqueta la grieta se anda; cuando haya
#     sistemas, se abrirá tras el secreto de Pip [C] (pendiente de la vida del sector, no de la maqueta).
#   - CENTRO-OESTE (cota 1,5): el Patio de los Vecinos [P] (fuente, tendedero, árbol, niños), con la Escalera de las
#     Macetas [P] y la Bajada de los Vecinos [P] desde el norte, el Rincón del Sol [P] (sin salida, banco al sol junto a la
#     muralla) y un paso bajo casa a la Calle Baja.
#   - SUR (cota 1): la Calle Baja [P], la Plazuela del Arco [P] con el arco (paso bajo casa) hacia la Puerta del Sur, el
#     Pasaje Bajo las Casas [P] (corredor cubierto 2 → 1 desde la plazuela del pozo), la Escalerilla de la Botica [P]
#     (atajo del Paso Cubierto al Arco, con un paso bajo casa y una escalera de piedra de 3 m) y el Huerto de la Muralla
#     [P] (sin salida: bancales, pozo y cobertizo), tras otro paso bajo casa.
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "pasajes"

# ---------------------------------------------------------------------------------------------------- suelo
# Rampas: «z» de norte a sur, «x» de oeste a este. Las escaleras son rampas (≤ 40 %); los niveles distintos los separan
# casas y muros (sin saltos de más de 0,3 m entre casillas vecinas).
const SUELOS := [
	["pasajes", Rect2(-70.0, 50.0, 2.0, 8.5), "", 2.0, 2.0],          # 0 Pasaje de las Velas (borde z 50, cota 2), 2 m
	["pasajes", Rect2(-86.0, 52.0, 16.0, 2.0), "", 2.0, 2.0],         # 1 Callejón de las Macetas [P], 2 m
	["pasajes", Rect2(-86.0, 54.0, 2.0, 11.0), "z", 2.0, 1.5],        # 2 Escalera de las Macetas [P] (rampa suave)
	["pasajes", Rect2(-68.0, 56.0, 18.0, 2.5), "", 2.0, 2.0],         # 3 Callejón Alto [P], 2,5 m
	["pasajes", Rect2(-57.0, 58.5, 2.0, 5.5), "", 2.0, 2.0],          # 4 callejón de Pip [C], sin salida
	["pasajes", Rect2(-56.6, 64.0, 1.2, 2.5), "z", 2.0, 1.44],        # 5 la grieta [C]: 1,2 m, baja al patio (22 %)
	["pasajes", Rect2(-63.0, 66.5, 13.0, 8.0), "", 1.44, 1.44],       # 6 Patio de las Velas [C] (solo por la grieta)
	["pasajes", Rect2(-50.0, 52.0, 12.0, 13.0), "", 2.0, 2.0],        # 7 Plazuela del Pozo [P]
	["pasajes", Rect2(-38.0, 54.0, 8.0, 3.0), "", 2.0, 2.0],          # 8 Paso Cubierto de la Botica (borde x −30, cota 2)
	["pasajes", Rect2(-34.0, 57.0, 2.0, 12.0), "", 2.0, 2.0],         # 9 Escalerilla de la Botica [P], tramo alto
	["pasajes", Rect2(-34.0, 69.0, 2.0, 3.0), "z", 2.0, 1.0],         # 10 su escalera de piedra (33 %)
	["pasajes", Rect2(-34.0, 72.0, 2.0, 4.0), "", 1.0, 1.0],          # 11 su tramo bajo
	["pasajes", Rect2(-44.0, 65.0, 2.0, 11.0), "z", 2.0, 1.0],        # 12 Pasaje Bajo las Casas [P] (9 %)
	["pasajes", Rect2(-44.0, 76.0, 14.0, 7.0), "", 1.0, 1.0],         # 13 Plazuela del Arco [P] (borde x −30, cota 1)
	["pasajes", Rect2(-72.0, 79.0, 28.0, 3.0), "", 1.0, 1.0],         # 14 Calle Baja [P], 3 m
	["pasajes", Rect2(-72.0, 77.0, 2.0, 2.0), "z", 1.5, 1.0],         # 15 paso bajo casa del Patio de los Vecinos (25 %)
	["pasajes", Rect2(-90.0, 65.0, 22.0, 12.0), "", 1.5, 1.5],        # 16 Patio de los Vecinos [P]
	["pasajes", Rect2(-70.0, 58.5, 2.0, 6.5), "z", 2.0, 1.5],         # 17 Bajada de los Vecinos [P]
	["pasajes", Rect2(-97.0, 69.0, 7.0, 2.0), "", 1.5, 1.5],          # 18 Rincón del Sol [P], sin salida
	["pasajes", Rect2(-58.0, 82.0, 2.0, 4.0), "", 1.0, 1.0],          # 19 paso bajo casa al huerto
	["pasajes", Rect2(-70.0, 86.0, 20.0, 6.0), "", 1.0, 1.0],         # 20 Huerto de la Muralla [P], sin salida
	["pasajes", Rect2(-96.0, 50.0, 10.0, 12.0), "", 2.0, 2.0],        # 21 Corral del Rincón [P], sin salida
]

# ---------------------------------------------------------------------------------------------------- bloques
# Casas de anchos, alturas y fondos distintos; los pasos bajo casa y los corredores, «cubierta» (la planta de encima).
const BLOQUES := [
	# murallas [C: Oakhaven amurallada; aquí, el rincón suroeste]
	["muralla_oeste_s", "pasajes", Rect2(-100.0, 50.0, 3.0, 43.0), 0.0, 10.0, "muro", true],
	["muralla_so_o", "pasajes", Rect2(-100.0, 93.0, 30.0, 2.5), 0.0, 8.0, "muro", true],
	["muralla_so_e", "pasajes", Rect2(-70.0, 93.0, 40.0, 2.5), 0.0, 8.0, "muro", true],
	# norte: Callejón de las Macetas y Pasaje de las Velas
	["tapia_macetas", "pasajes", Rect2(-86.0, 50.0, 16.0, 2.0), 2.0, 2.6, "muro", true],
	["maceta_1", "pasajes", Rect2(-83.0, 52.0, 0.5, 0.5), 2.0, 0.6, "decor", true],
	["maceta_2", "pasajes", Rect2(-80.0, 52.0, 0.5, 0.5), 2.0, 0.6, "decor", true],
	["maceta_3", "pasajes", Rect2(-73.0, 52.0, 0.5, 0.5), 2.0, 0.6, "decor", true],
	# Corral del Rincón [P]: gallinero y leña; una tapia lo separa de la Escalera de las Macetas
	["muro_corral_e", "pasajes", Rect2(-86.4, 54.0, 0.4, 8.0), 2.0, 1.6, "muro", true],
	["gallinero", "pasajes", Rect2(-95.5, 50.5, 3.0, 2.5), 2.0, 1.6, "bajo", true],
	["lena_corral", "pasajes", Rect2(-89.0, 50.3, 2.5, 1.0), 2.0, 1.2, "bajo", true],
	["lenera", "pasajes", Rect2(-90.0, 62.0, 4.0, 3.0), 1.75, 1.4, "bajo", true],
	["casa_macetas", "pasajes", Rect2(-84.0, 54.0, 14.0, 11.0), 1.75, 6.0, "casa", true],
	# Callejón Alto: casas al norte y al sur, un banco, la boca del callejón de Pip
	["casa_alto_n1", "pasajes", Rect2(-68.0, 50.0, 9.0, 6.0), 2.0, 6.5, "casa", true],
	["casa_alto_n2", "pasajes", Rect2(-59.0, 50.0, 9.0, 6.0), 2.0, 5.2, "casa", true],
	["hoja_alto", "pasajes", Rect2(-53.7, 56.0, 1.4, 0.08), 2.0, 2.3, "puerta", false],
	["banco_alto", "pasajes", Rect2(-66.0, 56.1, 1.8, 0.5), 2.0, 0.45, "bajo", true],
	["casa_velas_no", "pasajes", Rect2(-68.0, 58.5, 11.0, 8.0), 1.6, 6.0, "casa", true],
	["casa_pip_e", "pasajes", Rect2(-55.0, 58.5, 5.0, 8.0), 1.6, 5.5, "casa", true],
	# la grieta [C]: dos muros a los lados (la luz del patio se ve al fondo del callejón)
	["grieta_muro_o", "pasajes", Rect2(-57.0, 64.0, 0.4, 2.5), 1.44, 4.5, "muro", true],
	["grieta_muro_e", "pasajes", Rect2(-55.4, 64.0, 0.4, 2.5), 1.44, 4.5, "muro", true],
	# el Patio de las Velas [C]: el altar pequeño con las velas, contra el muro norte
	["altar_velas", "pasajes", Rect2(-60.0, 66.5, 2.4, 0.7), 1.44, 1.0, "bajo", true],
	["velas_altar", "pasajes", Rect2(-59.6, 66.6, 1.6, 0.4), 2.44, 0.25, "decor", false],
	["casa_velas_o", "pasajes", Rect2(-68.0, 66.5, 5.0, 12.5), 1.0, 6.0, "casa", true],
	["hoja_vecinos_e", "pasajes", Rect2(-68.08, 71.3, 0.08, 1.4), 1.5, 2.3, "puerta", false],
	["casa_velas_s", "pasajes", Rect2(-63.0, 74.5, 19.0, 4.5), 1.0, 5.5, "casa", true],
	["hoja_baja_n", "pasajes", Rect2(-52.7, 78.92, 1.4, 0.08), 1.0, 2.3, "puerta", false],
	# Plazuela del Pozo: pozo con caño, árbol, banco, el puesto y el taller del cestero [P]
	["tapia_pozo_n", "pasajes", Rect2(-50.0, 50.0, 12.0, 2.0), 2.0, 4.0, "muro", true],
	["pozo_plazuela", "pasajes", Rect2(-47.5, 60.0, 1.8, 1.8), 2.0, 0.9, "bajo", true],
	["pozo_cano", "pasajes", Rect2(-46.9, 60.6, 0.6, 0.6), 2.9, 1.4, "decor", true],
	["banco_pozo", "pasajes", Rect2(-49.6, 62.5, 0.6, 1.8), 2.0, 0.45, "bajo", true],
	["arbol_pozo", "pasajes", Rect2(-41.0, 58.0, 0.55, 0.55), 2.0, 2.8, "arbol", true],
	["copa_pozo", "pasajes", Rect2(-43.6, 55.4, 6.0, 6.0), 4.6, 3.0, "copa", false],
	["puesto_cestero", "pasajes", Rect2(-39.6, 62.4, 1.4, 2.0), 2.0, 1.1, "bajo", true],
	["casa_escalerilla_o", "pasajes", Rect2(-38.0, 57.0, 4.0, 8.0), 2.0, 6.0, "casa", true],
	["hoja_cestero", "pasajes", Rect2(-38.08, 60.3, 0.08, 1.4), 2.0, 2.3, "puerta", false],
	["casa_pozo_s", "pasajes", Rect2(-50.0, 65.0, 6.0, 9.5), 1.44, 6.0, "casa", true],
	# Paso Cubierto de la Botica: la casa de encima (sigue la del lado de la plaza)
	["casa_corredor_n", "pasajes", Rect2(-38.0, 50.0, 8.0, 4.0), 2.0, 6.5, "casa", true],
	["cubierta_corredor", "pasajes", Rect2(-38.0, 54.0, 8.0, 3.0), 4.8, 3.2, "cubierta", false],
	# Escalerilla de la Botica: un paso bajo casa y casas estrechas a los lados
	["casa_borde_e", "pasajes", Rect2(-32.0, 57.0, 2.0, 19.0), 2.0, 6.0, "casa", true],
	["cubierta_escalerilla", "pasajes", Rect2(-34.0, 60.0, 2.0, 3.0), 4.8, 3.0, "cubierta", false],
	["casa_bajo_e", "pasajes", Rect2(-42.0, 65.0, 8.0, 11.0), 1.5, 6.5, "casa", true],
	["hoja_pasaje_bajo", "pasajes", Rect2(-42.08, 70.3, 0.08, 1.4), 1.4, 2.3, "puerta", false],
	["hoja_escalerilla", "pasajes", Rect2(-34.08, 65.3, 0.08, 1.4), 2.0, 2.3, "puerta", false],
	# Pasaje Bajo las Casas: corredor cubierto en su tramo central
	["cubierta_pasaje_bajo", "pasajes", Rect2(-44.0, 67.0, 2.0, 6.0), 4.6, 3.0, "cubierta", false],
	# Plazuela del Arco: el arco (paso bajo casa) hacia la Puerta del Sur, un banco
	["casa_arco_n", "pasajes", Rect2(-32.0, 76.0, 2.0, 3.4), 1.0, 6.0, "casa", true],
	["arco_pasajes", "pasajes", Rect2(-32.0, 79.4, 2.0, 3.6), 4.0, 2.0, "cubierta", false],
	["banco_arco", "pasajes", Rect2(-42.5, 77.2, 2.4, 0.5), 1.0, 0.45, "bajo", true],
	["casa_arco_s", "pasajes", Rect2(-44.0, 83.0, 14.0, 10.0), 1.0, 5.0, "casa", true],
	# Calle Baja: casas al sur, banco, el paso al huerto
	["banco_baja", "pasajes", Rect2(-50.0, 79.1, 1.8, 0.5), 1.0, 0.45, "bajo", true],
	["casa_baja_s1", "pasajes", Rect2(-72.0, 82.0, 14.0, 4.0), 1.0, 5.5, "casa", true],
	["casa_baja_s2", "pasajes", Rect2(-56.0, 82.0, 12.0, 4.0), 1.0, 6.5, "casa", true],
	["cubierta_paso_huerto", "pasajes", Rect2(-58.0, 82.0, 2.0, 4.0), 3.8, 3.0, "cubierta", false],
	# Huerto de la Muralla: bancales, pozo, cobertizo
	["casa_huerto_o", "pasajes", Rect2(-72.0, 86.0, 2.0, 7.0), 1.0, 4.5, "casa", true],
	["cobertizo_huerto", "pasajes", Rect2(-50.0, 86.0, 6.0, 7.0), 1.0, 3.5, "casa", true],
	["hoja_cobertizo", "pasajes", Rect2(-50.08, 87.8, 0.08, 1.4), 1.0, 2.2, "puerta", false],
	["bancal_1", "pasajes", Rect2(-64.0, 88.0, 5.0, 0.8), 1.0, 0.35, "bajo", true],
	["bancal_2", "pasajes", Rect2(-64.0, 90.0, 5.0, 0.8), 1.0, 0.35, "bajo", true],
	["bancal_3", "pasajes", Rect2(-69.0, 88.0, 4.0, 0.8), 1.0, 0.35, "bajo", true],
	["pozo_huerto", "pasajes", Rect2(-53.0, 89.5, 1.2, 1.2), 1.0, 0.9, "bajo", true],
	# Patio de los Vecinos: fuente, tendedero, árbol; el paso bajo casa a la Calle Baja
	["fuente_vecinos", "pasajes", Rect2(-81.0, 69.0, 2.0, 2.0), 1.5, 0.8, "bajo", true],
	["fuente_vecinos_cano", "pasajes", Rect2(-80.3, 69.7, 0.6, 0.6), 2.3, 1.2, "decor", true],
	["tendedero_poste_1", "pasajes", Rect2(-79.2, 67.4, 0.2, 0.2), 1.5, 2.2, "muro", true],
	["tendedero_poste_2", "pasajes", Rect2(-73.2, 67.4, 0.2, 0.2), 1.5, 2.2, "muro", true],
	["tendedero_ropa", "pasajes", Rect2(-79.0, 67.45, 6.0, 0.1), 2.6, 1.0, "cubierta", false],
	["arbol_vecinos", "pasajes", Rect2(-88.6, 74.4, 0.55, 0.55), 1.5, 2.8, "arbol", true],
	["copa_vecinos", "pasajes", Rect2(-91.0, 72.0, 5.5, 5.5), 4.2, 3.0, "copa", false],
	["casa_vecinos_s", "pasajes", Rect2(-90.0, 77.0, 18.0, 8.0), 1.5, 6.0, "casa", true],
	["casa_paso_vecinos", "pasajes", Rect2(-70.0, 77.0, 2.0, 2.0), 1.0, 6.0, "casa", true],
	["cubierta_paso_vecinos", "pasajes", Rect2(-72.0, 77.0, 2.0, 2.0), 4.3, 2.5, "cubierta", false],
	# Rincón del Sol y las casas del oeste
	["casa_sol_n", "pasajes", Rect2(-97.0, 62.0, 7.0, 7.0), 1.5, 6.0, "casa", true],
	["casa_sol_s", "pasajes", Rect2(-97.0, 71.0, 7.0, 14.0), 1.5, 5.5, "casa", true],
	["banco_sol", "pasajes", Rect2(-96.8, 69.2, 0.6, 1.6), 1.5, 0.45, "bajo", true],
	["casas_muralla_so", "pasajes", Rect2(-97.0, 85.0, 25.0, 8.0), 1.0, 5.0, "casa", true],
]
# Las casas que la escena aclara cuando tapan a Kael (además de las cubiertas y las copas): las que quedan al SUR de lo
# andable (la cámara mira desde el sur). Las dice prueba_ciudad_plano (sección 8).
const OCULTABLES := ["casa_macetas", "casa_velas_no", "casa_pip_e", "grieta_muro_o", "grieta_muro_e", "casa_velas_s",
	"casa_baja_s1", "casa_baja_s2", "casa_pozo_s", "casa_bajo_e", "casa_escalerilla_o", "casa_borde_e", "casa_arco_s",
	"casa_huerto_o", "casa_vecinos_s", "casa_paso_vecinos", "casa_sol_n", "casa_sol_s", "muralla_so_e"]

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; el resto, sitios de vida
# (vecinos trabajando, niños, fuentes) para la fase de vida.
const ANCLAS := {
	"referencia": Vector3(-56.0, 1.44, 70.0),       # el Patio de las Velas [C] (ref_pasajes del plano)
	"grieta_pip": Vector3(-56.0, 1.72, 65.25),     # la grieta [C]: el secreto de Pip
	"pip": Vector3(-56.0, 2.0, 61.0),               # Pip [C], en su callejón
	"velas": Vector3(-58.8, 1.44, 67.8),            # ante el altar de las velas [C]
	"fuente_pozo": Vector3(-46.6, 2.0, 59.2),       # el pozo de la plazuela [P]
	"ninos_pozo": Vector3(-44.5, 2.0, 63.0),        # niños jugando [P]
	"cestero": Vector3(-40.2, 2.0, 60.0),           # el cestero trabajando a su puerta [P]
	"vecina_tendiendo": Vector3(-76.0, 1.5, 68.2),  # tendiendo la ropa [P]
	"ninos_vecinos": Vector3(-77.0, 1.5, 73.0),     # niños jugando en el patio [P]
	"fuente_vecinos": Vector3(-80.0, 1.5, 72.0),    # la fuente del patio [P]
	"sol": Vector3(-95.5, 1.5, 70.0),               # el banco al sol del rincón [P]
	"huertano": Vector3(-61.0, 1.0, 89.4),          # entre los bancales [P]
	"gallinas": Vector3(-91.0, 2.0, 56.0),          # una vecina con las gallinas del corral [P]
	"puerta_corral": Vector3(-93.5, 2.0, 61.95),
	"n_corral": Vector3(-91.0, 2.0, 53.0),
	"puerta_macetas": Vector3(-77.0, 2.0, 53.95),
	"puerta_alto": Vector3(-53.0, 2.0, 56.05),
	"puerta_velas_no": Vector3(-62.0, 2.0, 58.45),
	"puerta_cestero": Vector3(-38.05, 2.0, 61.0),
	"puerta_pasaje_bajo": Vector3(-42.05, 1.454545, 71.0),
	"puerta_escalerilla": Vector3(-33.95, 2.0, 66.0),
	"puerta_baja_n": Vector3(-52.0, 1.0, 79.05),
	"puerta_baja_s": Vector3(-65.0, 1.0, 81.95),
	"puerta_arco": Vector3(-38.0, 1.0, 82.95),
	"puerta_cobertizo": Vector3(-50.05, 1.0, 88.5),
	"puerta_vecinos_e": Vector3(-68.05, 1.5, 72.0),
	"puerta_vecinos_s": Vector3(-80.0, 1.5, 76.95),
	"n_velas": Vector3(-69.0, 2.0, 51.0),
	"n_macetas_e": Vector3(-69.0, 2.0, 53.0),
	"n_macetas_o": Vector3(-85.0, 2.0, 53.0),
	"n_velas_s": Vector3(-69.0, 2.0, 57.25),
	"n_alto_pip": Vector3(-56.0, 2.0, 57.25),
	"n_pip": Vector3(-56.0, 2.0, 61.0),
	"n_grieta": Vector3(-56.0, 1.72, 65.25),
	"n_patio_velas": Vector3(-56.0, 1.44, 70.0),
	"n_pozo_o": Vector3(-48.0, 2.0, 57.25),
	"n_pozo": Vector3(-43.0, 2.0, 55.5),
	"n_corredor": Vector3(-33.0, 2.0, 55.5),
	"n_botica": Vector3(-31.0, 2.0, 55.5),
	"n_bajo_n": Vector3(-43.0, 2.0, 64.5),
	"n_arco_o": Vector3(-43.0, 1.0, 80.25),
	"n_esc_s": Vector3(-33.0, 1.0, 80.25),
	"n_arco": Vector3(-31.0, 1.0, 81.5),
	"n_baja": Vector3(-57.0, 1.0, 80.25),
	"n_baja_o": Vector3(-71.0, 1.0, 80.25),
	"n_huerto": Vector3(-57.0, 1.0, 88.5),
	"n_vecinos_s": Vector3(-71.0, 1.5, 76.0),
	"n_vecinos_ne": Vector3(-69.0, 1.5, 66.0),
	"n_vecinos_no": Vector3(-85.0, 1.5, 66.0),
	"n_vecinos_o": Vector3(-88.0, 1.5, 70.0),
	"n_sol": Vector3(-94.0, 1.5, 70.0),
}

# Puertas previstas (los interiores NO existen: la escena dice «Aún no se puede entrar (en obras).»). Formato del barrio:
# fuera, mira (rotation.y al salir: 0 norte, PI sur, PI/2 oeste, −PI/2 este), radio, texto, ancla del umbral, nombre.
# Los nombres de oficio son [P].
const PUERTAS := {
	"casa_macetas": {"fuera": Vector3(-77.0, 2.0, 52.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_macetas", "nombre": "Casa"},
	"casa_alto": {"fuera": Vector3(-53.0, 2.0, 57.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_alto", "nombre": "Casa"},
	"casa_velas_no": {"fuera": Vector3(-62.0, 2.0, 57.1), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_velas_no", "nombre": "Casa"},
	"cestero": {"fuera": Vector3(-39.4, 2.0, 61.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en el taller",
		"ancla": "puerta_cestero", "nombre": "Taller del cestero"},
	"casa_pasaje_bajo": {"fuera": Vector3(-43.4, 1.454545, 71.0), "mira": PI / 2.0, "radio": 1.6,
		"texto": "Entrar en la casa", "ancla": "puerta_pasaje_bajo", "nombre": "Casa"},
	"casa_escalerilla": {"fuera": Vector3(-32.6, 2.0, 66.0), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_escalerilla", "nombre": "Casa"},
	"casa_baja_n": {"fuera": Vector3(-52.0, 1.0, 80.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_baja_n", "nombre": "Casa"},
	"casa_baja_s": {"fuera": Vector3(-65.0, 1.0, 80.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_baja_s", "nombre": "Casa"},
	"casa_arco": {"fuera": Vector3(-38.0, 1.0, 81.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_arco", "nombre": "Casa"},
	"cobertizo": {"fuera": Vector3(-51.4, 1.0, 88.5), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en el cobertizo",
		"ancla": "puerta_cobertizo", "nombre": "Cobertizo del huerto"},
	"casa_vecinos_e": {"fuera": Vector3(-69.4, 1.5, 72.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_vecinos_e", "nombre": "Casa"},
	"casa_corral": {"fuera": Vector3(-93.5, 2.0, 60.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_corral", "nombre": "Casa"},
	"casa_vecinos_s": {"fuera": Vector3(-80.0, 1.5, 75.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_vecinos_s", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros). Sus extremos en los bordes (n_velas, n_botica, n_arco)
# enlazan con el grafo global del plano (c_pasaje_velas, c_paso_botica, c_arco_pasajes). Dos ramas sin salida: el
# callejón de Pip con la grieta y el Patio de las Velas, y el huerto; el Rincón del Sol cuelga del Patio de los Vecinos.
const GRAFO := {
	"n_velas": ["n_macetas_e"],
	"n_macetas_e": ["n_velas", "n_velas_s", "n_macetas_o"],
	"n_macetas_o": ["n_macetas_e", "n_vecinos_no", "n_corral"],
	"n_corral": ["n_macetas_o"],
	"n_velas_s": ["n_macetas_e", "n_alto_pip", "n_vecinos_ne"],
	"n_alto_pip": ["n_velas_s", "n_pip", "n_pozo_o"],
	"n_pip": ["n_alto_pip", "n_grieta"],
	"n_grieta": ["n_pip", "n_patio_velas"],
	"n_patio_velas": ["n_grieta"],
	"n_pozo_o": ["n_alto_pip", "n_pozo"],
	"n_pozo": ["n_pozo_o", "n_corredor", "n_bajo_n"],
	"n_corredor": ["n_pozo", "n_botica", "n_esc_s"],
	"n_botica": ["n_corredor"],
	"n_bajo_n": ["n_pozo", "n_arco_o"],
	"n_arco_o": ["n_bajo_n", "n_esc_s", "n_baja"],
	"n_esc_s": ["n_corredor", "n_arco_o", "n_arco"],
	"n_arco": ["n_esc_s"],
	"n_baja": ["n_arco_o", "n_baja_o", "n_huerto"],
	"n_huerto": ["n_baja"],
	"n_baja_o": ["n_baja", "n_vecinos_s"],
	"n_vecinos_s": ["n_baja_o", "n_vecinos_ne"],
	"n_vecinos_ne": ["n_vecinos_s", "n_vecinos_no", "n_velas_s"],
	"n_vecinos_no": ["n_vecinos_ne", "n_macetas_o", "n_vecinos_o"],
	"n_vecinos_o": ["n_vecinos_no", "n_sol"],
	"n_sol": ["n_vecinos_o"],
}

# ---------------------------------------------------------------------------------------------------- cámara
const CAMARA_ZONAS := []


# ==================================================================================================== funciones (contrato)

static func suelo_en(x: float, z: float) -> int:
	return C.suelo_en(SUELOS, x, z)


static func bloque_en(x: float, z: float) -> String:
	return C.bloque_en(BLOQUES, x, z)


static func andable(x: float, z: float) -> bool:
	return C.andable(SUELOS, BLOQUES, x, z)


static func altura(x: float, z: float) -> float:
	return C.altura(SUELOS, x, z)


static func sector_de(x: float, z: float) -> String:
	return ID if suelo_en(x, z) >= 0 else ""


static func ancla(id: String) -> Vector3:
	return C.ancla(ANCLAS, SUELOS, id)
