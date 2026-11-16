extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 8, LA RIBERA BAJA. Maqueta del agente B (sectores 3 y 8), sobre
# el trazado mínimo de M0. Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§3; contrato: docs/v12/CIUDAD_OAKHAVEN.md; lo de
# este sector, explicado: docs/v12/ciudad_sectores/B.md. Bordes acordados (plano.gd, CONEXIONES, no se cambian aquí):
# Rampa de los Carros (x 45, cota 0) y Escalera del Molino (z 55, cota 3).
#
# Coordenadas de CIUDAD (x este, z sur, y arriba). Todo [P] salvo lo marcado [C]. Es lo más bajo de la ciudad (−2).
#   - RAMPA DE LOS CARROS [P]: baja de las caravanas (0) al nivel de los almacenes (−2), entre casas y el almacén de
#     la puerta (14 %, para carros cargados).
#   - ESCALERA DEL MOLINO [P] (dos tramos al 40 % con rellano) junto a la ACEQUIA [P] y la rueda del MOLINO [P]; el
#     pretil sigue la escalera (1 m sobre ella) y en el rellano es un balcón sobre la rueda. El agua sale de una boca bajo
#     la Calle del Horno. Abajo, la placeta del molino y el PUENTE DE LOS CARROS [P] sobre la acequia.
#   - PATIO DE LOS ALMACENES [P]: el LAVADERO [P] cubierto junto a la acequia, el ANDÉN DE CARGA [P] (a −1, con su
#     rampa y su bordillo) ante el almacén grande, el ALMACÉN DEL ACEITE [P] y, al este, el pie de la TORRE DE LA
#     CAMPANA [C]. Desde el patio se ve, al norte y arriba, el pretil de la Calle del Horno con sus vecinos asomados.
#   - LA TORRE Y LA RONDA [C: ciudades/oakhaven.gd, «se sube por dentro: vista y paso a la ronda», la ronda «en alto,
#     solo desde la torre»]: la puerta de la torre está a pie de patio; la escalera sube POR DENTRO (el cuerpo de la
#     escalera de la torre [P], cerrado y cubierto) hasta el MIRADOR DE LA RONDA [P] y el ADARVE sobre la muralla del
#     este, con los tres faroles de la ronda [C: oak_faroles] y el cofre al final [C: oak_cofre_ronda]. Arriba, en la cara
#     sur de la torre, la puerta del campanario (la vista de la torre; el interior aún no existe).
#   - CALLEJÓN DE LOS FARDOS [P]: sin salida, al fondo del almacén; reserva de RASTREADORES [P] (lonas rasgadas).
#   - SENDA DE LA ACEQUIA, PASARELA y RINCÓN DE LA ACEQUIA [P]: un pequeño bucle junto al agua donde juegan los niños;
#     la acequia sale bajo la muralla sur por una reja (no es una salida: solo la Puerta del Sur sale al mapa).
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "ribera"

# ---------------------------------------------------------------------------------------------------- suelo
# Niveles distintos sin rampa entre ellos (el andén, la escalera y la ronda) quedan separados por un muro, un pretil o
# un bordillo: no hay saltos de más de 0,3 m entre casillas vecinas. Lo andable llega hasta la muralla sur (z 93).
const SUELOS := [
	["ribera", Rect2(45.0, 76.0, 1.0, 6.0), "", 0.0, 0.0],              # 0 entrada de los carros (borde x 45, cota 0)
	["ribera", Rect2(46.0, 76.0, 14.0, 6.0), "x", 0.0, -2.0],           # 1 Rampa de los Carros (14 %)
	["ribera", Rect2(60.0, 55.0, 3.0, 2.0), "", 3.0, 3.0],              # 2 Escalera del Molino, arriba (borde z 55, cota 3)
	["ribera", Rect2(60.0, 57.0, 3.0, 5.0), "z", 3.0, 1.0],             # 3 primer tramo (40 %)
	["ribera", Rect2(60.0, 62.0, 3.0, 2.0), "", 1.0, 1.0],              # 4 rellano (balcón sobre la rueda del molino)
	["ribera", Rect2(60.0, 64.0, 3.0, 7.5), "z", 1.0, -2.0],            # 5 segundo tramo (40 %)
	["ribera", Rect2(60.0, 71.5, 3.5, 4.5), "", -2.0, -2.0],            # 6 placeta del molino
	["ribera", Rect2(60.0, 76.0, 5.0, 6.0), "", -2.0, -2.0],            # 7 Puente de los Carros (sobre la acequia)
	["ribera", Rect2(65.0, 65.5, 10.5, 16.5), "", -2.0, -2.0],          # 8 patio, oeste (el lavadero)
	["ribera", Rect2(75.5, 68.0, 4.0, 14.0), "", -2.0, -2.0],           # 9 patio, al pie de la rampa del andén
	["ribera", Rect2(79.5, 65.5, 20.5, 16.5), "", -2.0, -2.0],          # 10 patio, este (bajo la torre)
	["ribera", Rect2(76.0, 61.0, 16.0, 4.0), "", -1.0, -1.0],           # 11 andén de carga
	["ribera", Rect2(76.0, 65.0, 3.0, 3.0), "z", -1.0, -2.0],           # 12 rampa del andén (33 %)
	["ribera", Rect2(100.0, 65.0, 3.0, 5.0), "", -2.0, -2.0],           # 13 pie de la torre, por dentro (puerta al patio)
	["ribera", Rect2(100.5, 70.0, 2.5, 12.5), "z", -2.0, 3.0],          # 14 escalera de la torre (40 %, cubierta)
	["ribera", Rect2(100.5, 82.5, 3.0, 10.5), "", 3.0, 3.0],            # 15 Mirador de la Ronda
	["ribera", Rect2(103.5, 65.0, 3.5, 28.0), "", 3.0, 3.0],            # 16 adarve (la ronda en alto) [C]
	["ribera", Rect2(89.5, 82.0, 4.5, 11.0), "", -2.0, -2.0],           # 17 Callejón de los Fardos (sin salida)
	["ribera", Rect2(65.0, 82.0, 2.0, 11.0), "", -2.0, -2.0],           # 18 Senda de la Acequia
	["ribera", Rect2(63.5, 89.75, 1.5, 2.0), "", -2.0, -2.0],           # 19 pasarela sobre la acequia
	["ribera", Rect2(59.0, 82.0, 4.5, 11.0), "", -2.0, -2.0],           # 20 Rincón de la Acequia
	["ribera", Rect2(92.0, 65.0, 8.0, 0.5), "", -2.0, -2.0],            # 21 ante el almacén del aceite y la torre
]

# ---------------------------------------------------------------------------------------------------- bloques
# Las hojas de puerta que dan al NORTE (Kael delante, al norte de ellas) tapan como la casa: van en OCULTABLES.
const BLOQUES := [
	# --- la Rampa de los Carros
	["casa_carros_1", "ribera", Rect2(45.0, 63.0, 7.0, 13.0), 0.0, 8.0, "casa", true],
	["hoja_carros_1", "ribera", Rect2(48.0, 75.92, 1.2, 0.08), -0.37, 2.3, "puerta", false],
	["casa_carros_2", "ribera", Rect2(52.0, 63.0, 8.0, 13.0), -1.5, 6.5, "casa", true],
	["hoja_carros_2", "ribera", Rect2(55.4, 75.92, 1.2, 0.08), -1.43, 2.3, "puerta", false],
	["almacen_puerta", "ribera", Rect2(45.0, 82.0, 14.0, 11.0), -1.0, 7.0, "casa", true],
	["hoja_almacen_puerta", "ribera", Rect2(51.3, 82.0, 1.4, 0.08), -0.86, 2.6, "puerta", false],
	["talud_oficios", "ribera", Rect2(45.0, 55.0, 15.0, 8.0), 0.0, 3.0, "terreno", true],
	# --- la Escalera del Molino, la acequia y el molino. El pretil, en tramos: su cima, 1 m sobre la escalera.
	["pretil_escalera_1", "ribera", Rect2(63.0, 55.0, 0.5, 2.5), -2.0, 6.0, "muro", true],
	["pretil_escalera_2", "ribera", Rect2(63.0, 57.5, 0.5, 2.5), -2.0, 5.8, "muro", true],
	["pretil_escalera_3", "ribera", Rect2(63.0, 60.0, 0.5, 2.0), -2.0, 4.8, "muro", true],
	["pretil_escalera_4", "ribera", Rect2(63.0, 62.0, 0.5, 2.0), -2.0, 3.9, "muro", true],   # el balcón sobre la rueda
	["pretil_escalera_5", "ribera", Rect2(63.0, 64.0, 0.5, 3.0), -2.0, 4.0, "muro", true],
	["pretil_escalera_6", "ribera", Rect2(63.0, 67.0, 0.5, 4.5), -2.0, 2.8, "muro", true],
	["boca_acequia", "ribera", Rect2(63.5, 55.0, 2.0, 1.0), -2.0, 5.0, "muro", true],   # el agua sale de bajo la calle
	["acequia", "ribera", Rect2(63.5, 55.0, 1.5, 38.0), -2.6, 0.3, "decor", false],
	["rueda_molino", "ribera", Rect2(63.75, 59.0, 1.0, 4.5), -2.6, 5.0, "decor", false],
	["molino", "ribera", Rect2(65.0, 57.0, 9.0, 8.5), -2.0, 6.5, "casa", true],
	["hoja_molino", "ribera", Rect2(68.9, 65.42, 1.4, 0.08), -2.0, 2.4, "puerta", false],
	["muro_anden_o", "ribera", Rect2(74.0, 56.0, 2.0, 9.5), -2.0, 3.0, "muro", true],
	["terraplen_ribera", "ribera", Rect2(65.0, 55.0, 35.0, 1.5), -2.0, 5.0, "terreno", true],   # bajo la Calle del Horno
	["terraplen_este", "ribera", Rect2(92.0, 56.5, 8.0, 2.0), -2.0, 5.0, "terreno", true],
	# --- el lavadero (cubierto, junto a la acequia)
	["pila_lavadero", "ribera", Rect2(65.0, 69.0, 1.2, 8.0), -2.0, 0.8, "bajo", true],
	["cubierta_lavadero", "ribera", Rect2(65.0, 68.5, 7.0, 9.0), 1.2, 0.5, "cubierta", false],
	["pilar_lav_1", "ribera", Rect2(71.4, 68.6, 0.4, 0.4), -2.0, 3.2, "muro", true],
	["pilar_lav_2", "ribera", Rect2(71.4, 77.0, 0.4, 0.4), -2.0, 3.2, "muro", true],
	["pilar_lav_3", "ribera", Rect2(65.0, 68.6, 0.4, 0.4), -2.0, 3.2, "muro", true],
	["pilar_lav_4", "ribera", Rect2(65.0, 77.0, 0.4, 0.4), -2.0, 3.2, "muro", true],
	# --- el andén de carga (con su bordillo al patio) y el almacén grande
	["almacen_grande", "ribera", Rect2(76.0, 55.5, 16.0, 5.5), -2.0, 7.0, "casa", true],
	["hoja_almacen_grande", "ribera", Rect2(83.3, 60.92, 1.4, 0.08), -1.0, 2.6, "puerta", false],
	["pretil_rampa_o", "ribera", Rect2(75.5, 65.0, 0.5, 3.0), -2.0, 1.9, "muro", true],
	["pretil_rampa_e", "ribera", Rect2(79.0, 65.0, 0.5, 3.0), -2.0, 1.9, "muro", true],
	["canto_anden", "ribera", Rect2(79.5, 65.0, 12.5, 0.5), -2.0, 2.0, "muro", true],   # 1 m sobre el andén
	["grua_anden", "ribera", Rect2(86.0, 61.0, 0.4, 0.4), -1.0, 4.5, "muro", true],
	["sacos_anden", "ribera", Rect2(88.5, 61.0, 2.4, 1.2), -1.0, 1.0, "bajo", true],
	# --- el patio: carro, cajas, barriles; el almacén del aceite; la torre
	["carro_almacen", "ribera", Rect2(84.0, 72.0, 3.2, 1.8), -2.0, 1.5, "bajo", true],
	["cajas_patio", "ribera", Rect2(88.0, 67.0, 2.0, 1.6), -2.0, 1.3, "bajo", true],
	["barriles", "ribera", Rect2(98.4, 77.0, 1.6, 1.6), -2.0, 1.1, "bajo", true],
	["almacen_aceite", "ribera", Rect2(92.0, 58.5, 8.0, 6.5), -2.0, 4.5, "casa", true],
	["hoja_aceite", "ribera", Rect2(95.4, 64.92, 1.2, 0.08), -2.0, 2.3, "puerta", false],
	["torre_campana", "ribera", Rect2(100.0, 57.0, 8.0, 8.0), -2.0, 20.0, "muro", true],
	["campanario", "ribera", Rect2(100.5, 57.5, 7.0, 7.0), 18.0, 4.0, "casa", false],
	["hoja_campanario", "ribera", Rect2(104.55, 64.92, 1.4, 0.08), 3.0, 2.4, "puerta", false],
	["lienzo_ne", "ribera", Rect2(102.0, 55.0, 5.0, 2.0), -2.0, 10.0, "muro", true],
	# --- el cuerpo de la escalera de la torre [P]: muros a los dos lados y cubierta; se entra por el pie (z 65..68)
	["muro_escalera_torre", "ribera", Rect2(100.0, 68.0, 0.5, 14.5), -2.0, 7.5, "muro", true],
	["muro_ronda", "ribera", Rect2(103.0, 65.0, 0.5, 17.5), -2.0, 7.5, "muro", true],
	["techo_escalera_torre", "ribera", Rect2(100.0, 65.0, 3.5, 17.5), 5.5, 1.0, "cubierta", false],
	# --- la ronda en alto: mirador, adarve, los tres faroles [C] y el cofre del final [C]
	["pretil_mirador_o", "ribera", Rect2(100.0, 82.5, 0.5, 10.5), -2.0, 6.0, "muro", true],
	["muralla_este_s", "ribera", Rect2(107.0, 55.0, 3.0, 40.0), -2.0, 6.3, "muro", true],
	["farol_ronda_1", "ribera", Rect2(106.7, 70.0, 0.3, 0.3), 3.0, 2.4, "muro", true],
	["farol_ronda_2", "ribera", Rect2(106.7, 78.0, 0.3, 0.3), 3.0, 2.4, "muro", true],
	["farol_ronda_3", "ribera", Rect2(106.7, 86.0, 0.3, 0.3), 3.0, 2.4, "muro", true],
	["banco_mirador", "ribera", Rect2(100.5, 92.5, 2.2, 0.5), 3.0, 0.45, "bajo", true],
	# --- los almacenes del sur y el Callejón de los Fardos
	["almacen_so", "ribera", Rect2(67.0, 82.0, 22.5, 11.0), -2.0, 6.0, "casa", true],
	["hoja_almacen_so_1", "ribera", Rect2(71.3, 82.0, 1.4, 0.08), -2.0, 2.6, "puerta", false],
	["hoja_almacen_so_2", "ribera", Rect2(83.3, 82.0, 1.4, 0.08), -2.0, 2.6, "puerta", false],
	["almacen_fondo", "ribera", Rect2(94.0, 82.0, 6.0, 11.0), -2.0, 5.0, "casa", true],
	["hoja_almacen_fondo", "ribera", Rect2(94.0, 87.3, 0.08, 1.4), -2.0, 2.6, "puerta", false],
	["fardos", "ribera", Rect2(89.5, 91.0, 4.5, 2.0), -2.0, 1.4, "bajo", true],
	["lonas_rasgadas", "ribera", Rect2(93.5, 85.0, 0.5, 2.5), -2.0, 0.9, "bajo", true],
	# --- la muralla sur y la reja de la acequia
	["muralla_sur_o", "ribera", Rect2(45.0, 93.0, 55.5, 2.5), -2.0, 10.0, "muro", true],
	["muralla_sur_e", "ribera", Rect2(100.5, 93.0, 9.5, 2.5), -2.0, 6.3, "muro", true],
	["reja_acequia", "ribera", Rect2(63.5, 92.5, 1.5, 0.5), -2.6, 1.5, "muro", false],
]
# Lo que la escena aclara cuando tapa a Kael (además de cubiertas y copas): lo que queda al SUR de lo andable.
const OCULTABLES := ["almacen_puerta", "hoja_almacen_puerta", "almacen_so", "hoja_almacen_so_1", "hoja_almacen_so_2",
	"almacen_fondo", "muralla_sur_o", "muralla_sur_e", "muro_escalera_torre"]   # (el muro, al sur de la puerta de la torre)

# ---------------------------------------------------------------------------------------------------- anclas
const ANCLAS := {
	"referencia": Vector3(96.0, -2.0, 72.0),        # bajo la Torre de la Campana [C]
	"reserva_rastreadores_almacen": Vector3(92.0, -2.0, 86.0),   # [P] el fondo del almacén: las lonas rasgadas
	# umbrales
	"puerta_almacen": Vector3(83.95, -1.0, 61.0),
	"puerta_molino": Vector3(69.6, -2.0, 65.5),
	"puerta_aceite": Vector3(96.0, -2.0, 65.05),
	"puerta_torre": Vector3(100.25, -2.0, 66.5),    # [C] «Pie de la torre: puerta de la torre» (se entra andando)
	"puerta_campanario": Vector3(105.25, 3.0, 65.0),
	"puerta_almacen_so": Vector3(72.0, -2.0, 81.95),
	"puerta_almacen_fondo": Vector3(93.95, -2.0, 88.0),
	"puerta_casa_carros": Vector3(48.6, -0.3714, 76.0),
	# vida y juego
	"bastian": Vector3(98.5, -2.0, 67.0),           # [C] Bastián (su sitio es la Calle Mayor): aquí, mirando a la ronda
	"farol_1": Vector3(106.2, 3.0, 70.15),          # [C] los tres faroles de la ronda (oak_faroles)
	"farol_2": Vector3(106.2, 3.0, 78.15),
	"farol_3": Vector3(106.2, 3.0, 86.15),
	"cofre_ronda": Vector3(105.25, 3.0, 92.0),      # [C] «un cofre al final» de la ronda (oak_cofre_ronda)
	"mirador": Vector3(102.0, 3.0, 90.5),           # el Mirador de la Ronda: se ve desde arriba el patio y el andén
	"lavanderas": Vector3(67.0, -2.0, 73.0),        # vecinas lavando bajo el lavadero
	"molinero": Vector3(69.6, -2.0, 67.0),
	"mozos_anden": Vector3(84.0, -1.0, 63.0),       # mozos de almacén cargando [P]
	"caballo_carro": Vector3(85.6, -2.0, 74.6),     # el caballo del carro del almacén
	"ninos_acequia": Vector3(61.25, -2.0, 88.0),    # niños echando barquitos en la acequia
	"rueda_molino": Vector3(61.5, 1.0, 63.0),       # el rellano de la escalera, balcón sobre la rueda
	# nodos del grafo
	"n_carros": Vector3(46.0, 0.0, 79.0),
	"n_puente": Vector3(62.0, -2.0, 79.0),
	"n_molino": Vector3(61.5, 3.0, 56.0),
	"n_escalera_pie": Vector3(61.5, -2.0, 73.0),
	"n_lavadero": Vector3(68.5, -2.0, 79.5),
	"n_senda": Vector3(66.0, -2.0, 81.0),
	"n_pasarela": Vector3(66.0, -2.0, 90.75),
	"n_rincon": Vector3(60.5, -2.0, 90.75),
	"n_patio": Vector3(81.0, -2.0, 76.0),
	"n_anden_pie": Vector3(77.5, -2.0, 70.0),
	"n_anden": Vector3(77.5, -1.0, 63.0),
	"n_callejon": Vector3(91.75, -2.0, 83.0),
	"n_pie_ronda": Vector3(101.5, -2.0, 68.0),
	"n_ronda": Vector3(101.75, 3.0, 84.0),
	"n_mirador": Vector3(105.25, 3.0, 84.0),
	"n_torre": Vector3(105.25, 3.0, 66.4),
}

# Puertas previstas (los interiores NO existen: «Aún no se puede entrar (en obras).»). La torre no está aquí: se entra
# andando por su pie y se sube por dentro (la escalera cubierta); arriba, la puerta del campanario.
const PUERTAS := {
	"almacen": {"fuera": Vector3(83.95, -1.0, 62.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_almacen", "nombre": "Almacén grande"},
	"molino": {"fuera": Vector3(69.6, -2.0, 66.9), "mira": PI, "radio": 1.6, "texto": "Entrar en el molino",
		"ancla": "puerta_molino", "nombre": "Molino"},
	"aceite": {"fuera": Vector3(96.0, -2.0, 66.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_aceite", "nombre": "Almacén del aceite"},
	"campanario": {"fuera": Vector3(105.25, 3.0, 66.4), "mira": PI, "radio": 1.6, "texto": "Subir al campanario",
		"ancla": "puerta_campanario", "nombre": "Torre de la Campana"},
	"almacen_so": {"fuera": Vector3(72.0, -2.0, 80.6), "mira": 0.0, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_almacen_so", "nombre": "Almacén"},
	"almacen_fondo": {"fuera": Vector3(92.6, -2.0, 88.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_almacen_fondo", "nombre": "Almacén del fondo"},
	"casa_carros": {"fuera": Vector3(48.6, -0.3714, 77.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_carros", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros). Sus extremos en los bordes (n_carros, n_molino) enlazan con
# el grafo global del plano (c_rampa_carros, c_escalera_molino).
const GRAFO := {
	"n_carros": ["n_puente"],
	"n_puente": ["n_carros", "n_escalera_pie", "n_lavadero", "n_rincon"],
	"n_molino": ["n_escalera_pie"],
	"n_escalera_pie": ["n_molino", "n_puente"],
	"n_lavadero": ["n_puente", "n_senda", "n_patio"],
	"n_senda": ["n_lavadero", "n_pasarela"],
	"n_pasarela": ["n_senda", "n_rincon"],
	"n_rincon": ["n_pasarela", "n_puente"],
	"n_patio": ["n_lavadero", "n_anden_pie", "n_callejon", "referencia"],
	"n_anden_pie": ["n_patio", "n_anden"],
	"n_anden": ["n_anden_pie"],
	"n_callejon": ["n_patio", "reserva_rastreadores_almacen"],
	"reserva_rastreadores_almacen": ["n_callejon"],
	"referencia": ["n_patio", "puerta_torre"],
	"puerta_torre": ["referencia", "n_pie_ronda"],
	"n_pie_ronda": ["puerta_torre", "n_ronda"],
	"n_ronda": ["n_pie_ronda", "n_mirador"],
	"n_mirador": ["n_ronda", "n_torre", "cofre_ronda"],
	"n_torre": ["n_mirador"],
	"cofre_ronda": ["n_mirador"],
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
