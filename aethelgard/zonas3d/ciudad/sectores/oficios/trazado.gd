extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 3, CALLE DE LOS OFICIOS. Maqueta del agente B (sectores 3 y 8),
# sobre el trazado mínimo de M0. Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§4; contrato: docs/v12/CIUDAD_OAKHAVEN.md;
# lo de este sector, explicado: docs/v12/ciudad_sectores/b.md. Bordes acordados (plano.gd, CONEXIONES, no se cambian
# aquí): Calle del Mercado (x 45, cota 3), Subida de la Colina (z −15, cota 10) y Escalera del Molino (z 55, cota 3).
#
# Coordenadas de CIUDAD (x este, z sur, y arriba). Todo [P] salvo lo marcado [C]. La ladera sube hacia el norte: lo
# alto queda al norte de cada calle (la cámara mira desde el sur).
#   - CALLE DE LOS OFICIOS [C] (rampa al este, 3 → 7, 10 %): al norte, el taller de Hilda la Armera [C, su puesto a la
#     entrada de la calle], el Callejón del Carbón [P] (sin salida: la carbonera de la forja y su aprendiz), la forja de
#     Maese Ferro [C, «junto al yunque»] retranqueada tras el Ensanche de la Forja [P] (yunque, pila de temple y poste
#     de los caballos) y dos casas; al sur, un SOPORTAL [P] con planta encima.
#   - PASO DEL FUELLE [P]: un paso bajo las casas, del soportal a la Calle del Horno.
#   - CALLE DEL HORNO [P] (la calle comercial del barrio, plan §4), más baja: el horno de Maela [P, del barrio] y casas;
#     al sur, un pretil con la VISTA de la Ribera Baja (la torre, la acequia y los almacenes).
#   - PATIO DE LOS TALLERES [P] (el patio del barrio, plan §4) al final de la calle, a cota 7: el taller del carretero
#     Damián [P, del barrio], su carro, el abrevadero y un árbol. Al este de Ferro e Hilda (sin tercera forja).
#   - BAJADA AL MOLINO y PLACETA DE LA FUENTE [P] (sitio de juegos de niños) hacia la Escalera del Molino.
#   - ESCALERILLA DE LA COLINA [P]: atajo de la entrada de la calle al Paseo de la Colina (dos tramos al 19 y al 40 % con
#     rellano y banco).
#   - PASEO DE LA COLINA [P], al pie de la COLINA DEL CREMATORIO [C]: solo POR FUERA. La colina no es andable, la puerta
#     del crematorio sigue SELLADA (sin entrada prevista) y no se construye nada debajo. Albar [C] tiene allí su sitio.
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "oficios"

# ---------------------------------------------------------------------------------------------------- suelo
# La calle y lo que se abre a ella siguen la MISMA pendiente (y = 3 + 0,1·(x − 50)): no hay saltos entre ellos.
# La Calle del Horno: y = 3,1 + (x − 63)·1,9/33.
const SUELOS := [
	# Calle de los Oficios
	["oficios", Rect2(45.0, 20.0, 5.0, 6.0), "", 3.0, 3.0],             # 0 remate de la Calle del Mercado (borde x 45, cota 3)
	["oficios", Rect2(50.0, 20.0, 40.0, 6.0), "x", 3.0, 7.0],           # 1 Calle de los Oficios: sube 4 m al este (10 %)
	["oficios", Rect2(62.0, 17.0, 12.0, 3.0), "x", 4.2, 5.4],           # 2 Ensanche de la Forja (la misma pendiente)
	["oficios", Rect2(59.5, 13.0, 2.5, 7.0), "", 4.05, 4.05],           # 3 Callejón del Carbón (sin salida)
	["oficios", Rect2(64.0, 26.0, 24.0, 3.0), "x", 4.4, 6.8],           # 4 soportal (la misma pendiente)
	# Bajada al Molino y Placeta de la Fuente
	["oficios", Rect2(60.0, 26.0, 3.0, 27.0), "z", 4.15, 3.0],          # 5 bajada al molino (4 %)
	["oficios", Rect2(60.0, 53.0, 3.0, 2.0), "", 3.0, 3.0],             # 6 su remate (borde z 55, cota 3)
	["oficios", Rect2(50.0, 45.0, 10.0, 9.0), "", 3.15, 3.15],          # 7 Placeta de la Fuente
	# Paso del Fuelle y Calle del Horno
	["oficios", Rect2(77.0, 29.0, 2.5, 18.0), "z", 5.75, 3.98],         # 8 Paso del Fuelle, bajo las casas (10 %)
	["oficios", Rect2(63.0, 47.0, 33.0, 6.0), "x", 3.1, 5.0],           # 9 Calle del Horno (6 %)
	["oficios", Rect2(96.0, 47.0, 4.0, 6.0), "", 5.0, 5.0],             # 10 su rellano del este
	["oficios", Rect2(96.0, 30.0, 4.0, 17.0), "z", 7.0, 5.0],           # 11 bajada del patio (12 %)
	# Patio de los Talleres
	["oficios", Rect2(88.0, 4.0, 14.0, 16.0), "", 7.0, 7.0],            # 12 patio, norte (el carretero)
	["oficios", Rect2(90.0, 20.0, 12.0, 10.0), "", 7.0, 7.0],           # 13 patio, sur (el árbol)
	# Subida de la Colina, Paseo de la Colina y Escalerilla
	["oficios", Rect2(97.0, -10.0, 5.0, 14.0), "z", 8.5, 7.0],          # 14 subida del patio al paseo (11 %)
	["oficios", Rect2(97.0, -14.0, 5.0, 4.0), "", 8.5, 8.5],            # 15 rellano del este
	["oficios", Rect2(54.0, -14.0, 43.0, 4.0), "x", 10.0, 8.5],         # 16 Paseo de la Colina (3 %)
	["oficios", Rect2(50.0, -15.0, 4.0, 5.0), "", 10.0, 10.0],          # 17 llegada al Barrio Alto (borde z −15, cota 10)
	["oficios", Rect2(45.0, -14.0, 5.0, 4.0), "", 10.0, 10.0],          # 18 mirador de la escalerilla
	["oficios", Rect2(46.0, -10.0, 3.0, 10.0), "z", 10.0, 6.0],         # 19 escalerilla, tramo alto (40 %)
	["oficios", Rect2(46.0, 0.0, 3.0, 4.0), "", 6.0, 6.0],              # 20 su rellano (con banco)
	["oficios", Rect2(46.0, 4.0, 3.0, 16.0), "z", 6.0, 3.0],            # 21 tramo bajo (19 %)
]

# ---------------------------------------------------------------------------------------------------- bloques
# Las hojas de puerta que dan al NORTE (Kael delante, al norte de ellas) tapan como la casa: van en OCULTABLES. Las de
# las fachadas este u oeste caen entre dos casillas de 0,25 m (x .92 a .00) y no tapan.
const BLOQUES := [
	# --- al norte de la calle: Hilda, el carbón, la forja y dos casas
	["taller_hilda", "oficios", Rect2(50.0, 9.0, 9.5, 11.0), 3.0, 5.5, "casa", true],
	["hoja_hilda", "oficios", Rect2(54.3, 19.92, 1.4, 0.08), 3.5, 2.4, "puerta", false],
	["carbonera", "oficios", Rect2(59.5, 8.0, 2.5, 5.0), 4.05, 3.0, "casa", true],
	["monton_carbon", "oficios", Rect2(59.6, 13.0, 2.3, 1.4), 4.05, 1.1, "bajo", true],
	["forja_ferro", "oficios", Rect2(62.0, 8.0, 12.0, 9.0), 4.2, 6.0, "casa", true],
	["chimenea_forja", "oficios", Rect2(70.0, 10.0, 1.4, 1.4), 10.2, 3.5, "muro", false],
	["hoja_forja", "oficios", Rect2(67.3, 16.92, 1.4, 0.08), 4.8, 2.6, "puerta", false],
	["yunque", "oficios", Rect2(64.5, 18.2, 1.0, 0.6), 4.45, 0.8, "bajo", true],
	["pila_temple", "oficios", Rect2(71.0, 17.4, 1.6, 0.9), 5.1, 0.7, "bajo", true],
	["poste_caballos", "oficios", Rect2(73.3, 19.0, 0.3, 0.3), 5.3, 1.3, "muro", true],
	["casa_ne_1", "oficios", Rect2(74.5, 10.0, 6.0, 10.0), 5.4, 8.0, "casa", true],
	["hoja_casa_ne_1", "oficios", Rect2(76.9, 19.92, 1.2, 0.08), 5.7, 2.3, "puerta", false],
	["casa_ne_2", "oficios", Rect2(81.0, 9.0, 7.0, 11.0), 6.1, 6.0, "casa", true],
	["hoja_casa_ne_2", "oficios", Rect2(83.9, 19.92, 1.2, 0.08), 6.4, 2.3, "puerta", false],
	["ladera_colina", "oficios", Rect2(49.0, -10.0, 39.0, 18.0), 3.0, 5.5, "terreno", true],
	# --- al sur de la calle (entrada): la casa de la esquina, el puesto de Hilda, la casa de la bajada
	["casa_mercado_e", "oficios", Rect2(45.0, 26.0, 8.0, 12.5), 3.0, 8.0, "casa", true],
	["hoja_mercado_e", "oficios", Rect2(48.4, 26.0, 1.2, 0.08), 3.0, 2.3, "puerta", false],
	["puesto_hilda", "oficios", Rect2(51.0, 24.9, 2.4, 1.0), 3.1, 1.2, "bajo", true],
	["casa_bajada_o", "oficios", Rect2(53.5, 26.0, 6.5, 11.0), 3.35, 6.0, "casa", true],
	["hoja_bajada_o", "oficios", Rect2(59.92, 31.0, 0.08, 1.2), 3.9, 2.3, "puerta", false],
	# --- el soportal: pilares a la calle, la planta encima (cubierta) y las casas de detrás
	["muro_soportal_o", "oficios", Rect2(63.0, 26.0, 1.0, 3.0), 4.0, 4.4, "muro", true],
	["cubierta_soportal_o", "oficios", Rect2(64.0, 26.0, 13.0, 3.0), 8.0, 3.0, "cubierta", false],
	["cubierta_soportal_e", "oficios", Rect2(77.0, 26.0, 11.0, 3.0), 9.1, 2.0, "cubierta", false],
	["pilar_sop_1", "oficios", Rect2(64.0, 26.0, 0.4, 0.4), 4.4, 3.6, "muro", true],
	["pilar_sop_2", "oficios", Rect2(68.0, 26.0, 0.4, 0.4), 4.8, 3.2, "muro", true],
	["pilar_sop_3", "oficios", Rect2(72.0, 26.0, 0.4, 0.4), 5.2, 2.8, "muro", true],
	["pilar_sop_4", "oficios", Rect2(76.4, 26.0, 0.4, 0.4), 5.64, 2.36, "muro", true],
	["pilar_sop_5", "oficios", Rect2(80.6, 26.0, 0.4, 0.4), 6.06, 3.04, "muro", true],
	["pilar_sop_6", "oficios", Rect2(84.6, 26.0, 0.4, 0.4), 6.46, 2.64, "muro", true],
	["pilar_sop_7", "oficios", Rect2(87.6, 26.0, 0.4, 0.4), 6.76, 2.34, "muro", true],
	["casa_sop_1", "oficios", Rect2(63.0, 29.0, 7.0, 8.5), 4.0, 7.6, "casa", true],
	["hoja_sop_1", "oficios", Rect2(66.0, 29.0, 1.2, 0.08), 4.66, 2.3, "puerta", false],
	["hoja_sop_1_o", "oficios", Rect2(63.0, 32.8, 0.08, 1.2), 3.9, 2.3, "puerta", false],
	["casa_sop_2", "oficios", Rect2(70.0, 29.0, 7.0, 8.5), 4.6, 6.5, "casa", true],
	["casa_sop_3", "oficios", Rect2(79.5, 29.0, 8.5, 8.0), 5.0, 7.0, "casa", true],
	["casa_esquina", "oficios", Rect2(88.0, 26.0, 2.0, 4.0), 6.8, 6.0, "casa", true],
	["cubierta_fuelle", "oficios", Rect2(77.0, 30.0, 2.5, 9.0), 8.0, 3.0, "cubierta", false],
	# --- la Calle del Horno: casas con la fachada al sur y el horno de Maela
	["casa_horno_o", "oficios", Rect2(63.0, 38.0, 14.0, 9.0), 3.1, 7.0, "casa", true],
	["hoja_horno_o", "oficios", Rect2(68.4, 46.92, 1.2, 0.08), 3.4, 2.3, "puerta", false],
	["casa_horno_e", "oficios", Rect2(79.5, 37.5, 8.5, 9.5), 3.9, 6.0, "casa", true],
	["hoja_horno_e", "oficios", Rect2(83.4, 46.92, 1.2, 0.08), 4.2, 2.3, "puerta", false],
	["horno_maela", "oficios", Rect2(88.0, 30.0, 8.0, 17.0), 4.6, 6.0, "casa", true],
	["hoja_horno", "oficios", Rect2(90.4, 46.92, 1.2, 0.08), 4.7, 2.3, "puerta", false],
	["chimenea_horno", "oficios", Rect2(92.0, 33.0, 1.2, 1.2), 10.6, 2.2, "muro", false],
	["banco_horno", "oficios", Rect2(96.1, 38.0, 0.5, 2.2), 5.8, 0.45, "bajo", true],
	["pretil_horno_o", "oficios", Rect2(63.5, 53.0, 12.5, 0.4), 3.0, 1.2, "muro", true],
	["pretil_horno_c", "oficios", Rect2(76.0, 53.0, 12.0, 0.4), 3.85, 1.1, "muro", true],
	["pretil_horno_e", "oficios", Rect2(88.0, 53.0, 12.0, 0.4), 4.5, 1.2, "muro", true],
	["terreno_e", "oficios", Rect2(100.0, 30.0, 2.0, 25.0), 5.0, 2.0, "terreno", true],
	# --- la Placeta de la Fuente
	["casa_placeta_n", "oficios", Rect2(50.0, 39.0, 10.0, 6.0), 3.15, 7.0, "casa", true],
	["hoja_placeta_n", "oficios", Rect2(54.4, 44.92, 1.2, 0.08), 3.15, 2.3, "puerta", false],
	["casa_placeta_o", "oficios", Rect2(45.0, 39.0, 5.0, 16.0), 3.15, 9.0, "casa", true],
	["hoja_placeta_o", "oficios", Rect2(49.92, 48.4, 0.08, 1.2), 3.15, 2.3, "puerta", false],
	["fuente_pilon", "oficios", Rect2(53.5, 48.0, 3.0, 3.0), 3.15, 0.6, "bajo", true],
	["fuente_cano", "oficios", Rect2(54.7, 49.2, 0.6, 0.6), 3.75, 1.6, "decor", true],
	["pretil_placeta", "oficios", Rect2(50.0, 53.6, 10.0, 0.4), 3.15, 0.9, "muro", true],
	# --- el Patio de los Talleres
	["taller_carretero", "oficios", Rect2(88.0, -8.0, 9.0, 12.0), 7.0, 3.6, "casa", true],
	["porton_carretero", "oficios", Rect2(91.2, 3.92, 1.8, 0.08), 7.0, 2.6, "puerta", false],
	["carro_damian", "oficios", Rect2(93.5, 9.0, 3.2, 1.8), 7.0, 1.5, "bajo", true],
	["abrevadero_patio", "oficios", Rect2(100.4, 11.0, 1.2, 3.0), 7.0, 0.7, "bajo", true],
	["lena_patio", "oficios", Rect2(88.2, 5.0, 1.6, 2.4), 7.0, 1.3, "bajo", true],
	["tronco_patio", "oficios", Rect2(96.75, 23.75, 0.5, 0.5), 7.0, 3.0, "arbol", true],
	["copa_patio", "oficios", Rect2(94.5, 21.5, 5.0, 5.0), 9.5, 3.0, "copa", false],
	["muralla_este", "oficios", Rect2(102.0, -15.0, 3.0, 70.0), 0.0, 14.0, "muro", true],
	# --- la Escalerilla de la Colina (atajo de la Calle del Mercado al paseo)
	["muro_escalerilla", "oficios", Rect2(45.0, -10.0, 1.0, 30.0), 3.0, 7.5, "muro", true],
	["pretil_escalerilla", "oficios", Rect2(49.0, 8.0, 1.0, 12.0), 3.0, 3.5, "muro", true],
	["banco_escalerilla", "oficios", Rect2(48.4, 0.8, 0.5, 2.0), 6.0, 0.45, "bajo", true],
	["hornacina_escalerilla", "oficios", Rect2(45.9, 1.2, 0.1, 1.2), 6.6, 1.0, "decor", false],
	# --- el Paseo de la Colina y la Colina del Crematorio [C] (solo por fuera; la puerta, SELLADA)
	["pretil_colina", "oficios", Rect2(54.0, -15.0, 48.0, 1.0), 8.5, 1.5, "muro", true],
	["banco_paseo_1", "oficios", Rect2(62.0, -10.6, 2.2, 0.5), 9.7, 0.45, "bajo", true],
	["banco_paseo_2", "oficios", Rect2(84.0, -10.6, 2.2, 0.5), 8.95, 0.45, "bajo", true],
	["colina", "oficios", Rect2(60.0, -60.0, 45.0, 45.0), 8.0, 6.0, "terreno", true],
	["crematorio", "oficios", Rect2(75.0, -50.0, 16.0, 14.0), 14.0, 8.0, "casa", true],
	["puerta_sellada", "oficios", Rect2(81.0, -36.1, 4.0, 0.1), 14.0, 3.5, "puerta", false],
]
# Lo que la escena aclara cuando tapa a Kael (además de cubiertas y copas): lo que queda al SUR de lo andable.
const OCULTABLES := ["casa_mercado_e", "hoja_mercado_e", "casa_bajada_o", "muro_soportal_o", "casa_sop_1", "hoja_sop_1", "casa_sop_2",
	"casa_sop_3", "casa_esquina", "horno_maela", "chimenea_horno"]

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; el resto, sitios de vida
# (vecinos, caballos, niños) y de juego.
const ANCLAS := {
	"referencia": Vector3(68.0, 4.8, 21.4),          # ante la forja de Maese Ferro [C pendiente]
	"reserva_piezas_taller": Vector3(55.0, 3.5, 21.4),   # [P] Piezas Huérfanas: el taller de Hilda
	# umbrales
	"puerta_forja": Vector3(68.0, 4.8, 17.0),
	"puerta_hilda": Vector3(55.0, 3.5, 20.0),
	"puerta_carretero": Vector3(92.1, 7.0, 4.0),
	"puerta_horno": Vector3(91.0, 4.7121, 47.05),
	"puerta_casa_soportal": Vector3(66.6, 4.66, 28.95),
	"puerta_casa_placeta": Vector3(55.0, 3.15, 45.0),
	"puerta_casa_bajada": Vector3(60.05, 3.9115, 31.6),
	# vida y juego
	"ferro": Vector3(66.0, 4.6, 19.4),               # [C] «Herrería, junto al yunque»
	"hilda_puesto": Vector3(52.2, 3.22, 24.2),       # [C] su puesto a la entrada de la calle
	"aprendiz_carbon": Vector3(60.75, 4.05, 15.0),   # [C mundo vivo] el aprendiz de la forja, en la carbonera
	"caballo_forja": Vector3(73.0, 5.3, 20.6),       # un caballo esperando herraje, atado al poste
	"damian": Vector3(93.0, 7.0, 7.0),               # [P, del barrio] el carretero, ante su portón
	"caballo_carro": Vector3(97.5, 7.0, 10.0),       # el caballo del carro, junto al abrevadero
	"maela": Vector3(89.5, 4.6258, 48.6),            # [P, del barrio] la panadera, ante el horno
	"vecina_soportal": Vector3(75.0, 5.5, 27.5),
	"fuente_placeta": Vector3(55.0, 3.15, 52.0),
	"ninos_placeta": Vector3(57.5, 3.15, 52.0),      # niños jugando junto a la fuente
	"vista_ribera": Vector3(75.0, 3.7909, 52.0),     # el pretil de la Calle del Horno: la vista de la Ribera Baja
	"pie_crematorio": Vector3(80.0, 9.093, -12.0),   # al pie de la colina (la puerta del crematorio sigue sellada)
	"albar": Vector3(80.0, 9.093, -13.2),            # [C] Albar, «junto al crematorio»
	"banco_escalerilla": Vector3(47.5, 6.0, 1.8),
	# nodos del grafo
	"n_mercado_e": Vector3(46.0, 3.0, 22.5),
	"n_escalerilla_pie": Vector3(47.5, 3.0, 22.0),
	"n_escalerilla_alta": Vector3(47.5, 10.0, -12.0),
	"n_hilda": Vector3(55.0, 3.5, 22.5),
	"n_bajada": Vector3(61.5, 4.15, 22.5),
	"n_carbon": Vector3(60.75, 4.05, 15.0),
	"n_forja": Vector3(68.0, 4.8, 22.5),
	"n_fuelle": Vector3(78.25, 5.825, 22.5),
	"n_patio": Vector3(95.0, 7.0, 22.5),
	"n_patio_sur": Vector3(98.0, 7.0, 29.0),
	"n_carretero": Vector3(92.1, 7.0, 6.0),
	"n_subida_pie": Vector3(99.5, 7.0, 5.0),
	"n_rellano_colina": Vector3(99.5, 8.5, -12.0),
	"n_colina": Vector3(52.0, 10.0, -12.0),
	"n_bajada_horno": Vector3(61.5, 3.1278, 50.0),
	"n_molino": Vector3(61.5, 3.0, 54.0),
	"n_placeta": Vector3(55.0, 3.15, 52.0),
	"n_fuelle_s": Vector3(78.25, 3.978, 50.0),
	"n_horno": Vector3(91.0, 4.7121, 50.0),
	"n_rellano_e": Vector3(98.0, 5.0, 50.0),
}

# Puertas previstas (los interiores NO existen: «Aún no se puede entrar (en obras).»). mira: rotation.y al salir
# (0 norte, PI sur, PI/2 oeste, −PI/2 este).
const PUERTAS := {
	"forja": {"fuera": Vector3(68.0, 4.8, 18.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la forja",
		"ancla": "puerta_forja", "nombre": "Forja"},
	"taller_hilda": {"fuera": Vector3(55.0, 3.5, 21.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el taller",
		"ancla": "puerta_hilda", "nombre": "Taller de Hilda"},
	"carretero": {"fuera": Vector3(92.1, 7.0, 5.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el taller",
		"ancla": "puerta_carretero", "nombre": "Taller del carretero"},
	"horno": {"fuera": Vector3(91.0, 4.7121, 48.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el horno",
		"ancla": "puerta_horno", "nombre": "Horno"},
	"casa_soportal": {"fuera": Vector3(66.6, 4.66, 27.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_soportal", "nombre": "Casa"},
	"casa_placeta": {"fuera": Vector3(55.0, 3.15, 46.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_placeta", "nombre": "Casa"},
	"casa_bajada": {"fuera": Vector3(61.4, 3.9115, 31.6), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_bajada", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros). Sus extremos en los bordes (n_mercado_e, n_colina,
# n_molino) enlazan con el grafo global del plano (c_calle_mercado, c_subida_colina, c_escalera_molino).
const GRAFO := {
	"n_mercado_e": ["n_escalerilla_pie", "n_hilda"],
	"n_escalerilla_pie": ["n_mercado_e", "n_escalerilla_alta"],
	"n_escalerilla_alta": ["n_escalerilla_pie", "n_colina"],
	"n_hilda": ["n_mercado_e", "n_bajada"],
	"n_bajada": ["n_hilda", "n_forja", "n_carbon", "n_bajada_horno"],
	"n_carbon": ["n_bajada"],
	"n_forja": ["n_bajada", "n_fuelle"],
	"n_fuelle": ["n_forja", "n_patio", "n_fuelle_s"],
	"n_patio": ["n_fuelle", "n_patio_sur", "n_carretero", "n_subida_pie"],
	"n_patio_sur": ["n_patio", "n_rellano_e"],
	"n_carretero": ["n_patio"],
	"n_subida_pie": ["n_patio", "n_rellano_colina"],
	"n_rellano_colina": ["n_subida_pie", "pie_crematorio"],
	"pie_crematorio": ["n_rellano_colina", "n_colina"],
	"n_colina": ["pie_crematorio", "n_escalerilla_alta"],
	"n_bajada_horno": ["n_bajada", "n_molino", "n_placeta", "n_fuelle_s"],
	"n_molino": ["n_bajada_horno"],
	"n_placeta": ["n_bajada_horno"],
	"n_fuelle_s": ["n_fuelle", "n_bajada_horno", "n_horno"],
	"n_horno": ["n_fuelle_s", "n_rellano_e"],
	"n_rellano_e": ["n_horno", "n_patio_sur"],
}

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
