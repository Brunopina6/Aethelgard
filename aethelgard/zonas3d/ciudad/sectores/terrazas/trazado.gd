extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 4, LAS TERRAZAS [P] (viviendas escalonadas). MAQUETA del agente D
# (sectores 4 y 7) sobre el trazado mínimo de M0. Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§4; contrato:
# docs/v12/CIUDAD_OAKHAVEN.md; lo hecho aquí: docs/v12/ciudad_sectores/D.md. Todo es PROPUESTA [P]: el barrio de vecinos
# no tiene canon propio. Bordes acordados (plano.gd, CONEXIONES, no se tocan): Escaleras de las Terrazas (z −5, x −62..−58,
# cota 3) desde el Patio del Cuervo y su remate alto (x −30, z −64..−60, cota 12) hacia el Barrio Alto. Anclas globales que
# caen aquí: «ref_terrazas» (−60, 12, −64, el lavadero) y «reserva_piezas_patio» (−80, 10, −50).
#
# El recorrido es el ATAJO de la taberna al barrio alto sin pasar por la plaza: sube en zigzag por cuatro terrazas.
#   base (3) ── Escalinata de las Glicinias [P] (centro, dos tramos y un rellano con pérgola) ──► T1 (6)
#   T1, Calle de las Casas: la calle residencial del barrio (plan §4): la VIVIENDA de Odila y Nela [P] con su patio
#       delantero (rosal, banco), tendederos, huertos abajo, el pretil con vistas al Patio del Cuervo.
#   T1 ── Atajo de la Hornacina [P] (oeste: el atajo del barrio, dos tramos de escalones, arco y hornacina) ──► T2 (8)
#   T2 y la Plazuela de los Juegos [P]: el ensanche para orientarse, con la fuente de las Terrazas y sitio de niños.
#   T2 ── Escalera del Este [P] (dos tramos y rellano) ──► T3 (10)
#   T3, Calle del Patio: pasa BAJO la Casa Puente [P] (paso bajo edificio) y acaba al oeste en el PATIO DE LA PIEZA
#       [P] (callejón sin salida con razón: el sitio reservado de la Pieza Huérfana, plan §3).
#   T3 ── Escalera del Lavadero [P] (centro, dos tramos y rellano) ──► T4 (12)
#   T4, Terraza del Lavadero [P]: el lavadero cubierto de la terraza alta (la referencia), ropa tendida, y al este el
#       remate hacia el Barrio Alto (x −30).
# Las terrazas suben hacia el NORTE (la cámara está al sur): las casas de cada terraza tienen su fachada al norte de su
# calle y su espalda contra la terraza de arriba; las que quedan al sur de la calle de arriba son OCULTABLES (la escena las
# aclara cuando tapan a Kael). Los escalones son rampas continuas (≤ 33 %), como el atajo del barrio.
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "terrazas"

# ---------------------------------------------------------------------------------------------------- suelo
const SUELOS := [
	# base y Escalinata de las Glicinias [P] (3 → 6)
	["terrazas", Rect2(-62.0, -7.0, 4.0, 2.0), "", 3.0, 3.0],           # 0 pie (borde z −5, cota 3)
	["terrazas", Rect2(-62.0, -12.0, 4.0, 5.0), "z", 4.5, 3.0],         # 1 primer tramo (30 %)
	["terrazas", Rect2(-65.0, -15.0, 10.0, 3.0), "", 4.5, 4.5],         # 2 rellano de las glicinias (con pérgola)
	["terrazas", Rect2(-62.0, -20.0, 4.0, 5.0), "z", 6.0, 4.5],         # 3 segundo tramo
	# T1 (6): Calle de las Casas
	["terrazas", Rect2(-97.0, -25.0, 59.0, 5.0), "", 6.0, 6.0],         # 4 la calle
	["terrazas", Rect2(-79.0, -28.0, 10.0, 3.0), "", 6.0, 6.0],         # 5 patio delantero de la vivienda de Odila y Nela
	# Atajo de la Hornacina [P] (6 → 8)
	["terrazas", Rect2(-90.0, -28.0, 4.0, 3.0), "z", 7.0, 6.0],         # 6 primer tramo de escalones (33 %)
	["terrazas", Rect2(-90.0, -32.0, 4.0, 4.0), "", 7.0, 7.0],          # 7 rellano, con el arco y la hornacina
	["terrazas", Rect2(-90.0, -35.0, 4.0, 3.0), "z", 8.0, 7.0],         # 8 segundo tramo
	# T2 (8) y la Plazuela de los Juegos [P]
	["terrazas", Rect2(-97.0, -41.0, 53.0, 6.0), "", 8.0, 8.0],         # 9 la calle
	["terrazas", Rect2(-74.0, -47.0, 16.0, 6.0), "", 8.0, 8.0],         # 10 la plazuela (con la calle, 16 × 12)
	# Escalera del Este [P] (8 → 10)
	["terrazas", Rect2(-48.0, -44.0, 4.0, 3.0), "z", 9.0, 8.0],         # 11
	["terrazas", Rect2(-48.0, -46.0, 4.0, 2.0), "", 9.0, 9.0],          # 12 rellano
	["terrazas", Rect2(-48.0, -49.0, 4.0, 3.0), "z", 10.0, 9.0],        # 13
	# T3 (10): Calle del Patio y el Patio de la Pieza [P]
	["terrazas", Rect2(-74.0, -53.0, 30.0, 4.0), "", 10.0, 10.0],       # 14 la calle (bajo la Casa Puente en x −66..−60)
	["terrazas", Rect2(-87.0, -58.0, 13.0, 9.0), "", 10.0, 10.0],       # 15 el patio (sin salida)
	# Escalera del Lavadero [P] (10 → 12)
	["terrazas", Rect2(-56.0, -56.0, 4.0, 3.0), "z", 11.0, 10.0],       # 16
	["terrazas", Rect2(-56.0, -57.0, 4.0, 1.0), "", 11.0, 11.0],        # 17 rellano
	["terrazas", Rect2(-56.0, -60.0, 4.0, 3.0), "z", 12.0, 11.0],       # 18
	# T4 (12): Terraza del Lavadero [P]
	["terrazas", Rect2(-70.0, -66.0, 40.0, 6.0), "", 12.0, 12.0],       # 19 la terraza (borde x −30, cota 12)
	["terrazas", Rect2(-66.0, -72.0, 12.0, 6.0), "", 12.0, 12.0],       # 20 el ensanche del lavadero
]

# ---------------------------------------------------------------------------------------------------- bloques
const BLOQUES := [
	# --- base: bancales de huertos y la ladera entre la base y T1, la pérgola de las glicinias
	["huerto_o", "terrazas", Rect2(-97.0, -12.0, 35.0, 7.0), 3.0, 1.2, "terreno", true],
	["huerto_e", "terrazas", Rect2(-58.0, -12.0, 28.0, 7.0), 3.0, 1.2, "terreno", true],
	["banda_1_o", "terrazas", Rect2(-97.0, -20.0, 32.0, 8.0), 3.0, 3.0, "terreno", true],
	["banda_1_e", "terrazas", Rect2(-55.0, -20.0, 25.0, 8.0), 3.0, 3.0, "terreno", true],
	["jardinera_glicinia_o", "terrazas", Rect2(-65.0, -20.0, 3.0, 5.0), 4.5, 1.5, "terreno", true],
	["jardinera_glicinia_e", "terrazas", Rect2(-58.0, -20.0, 3.0, 5.0), 4.5, 1.5, "terreno", true],
	["glicinia_o", "terrazas", Rect2(-65.5, -20.5, 4.0, 5.5), 7.0, 1.6, "copa", false],
	["glicinia_e", "terrazas", Rect2(-58.5, -20.5, 4.0, 5.5), 7.0, 1.6, "copa", false],
	["pergola_glicinias", "terrazas", Rect2(-65.0, -15.0, 10.0, 3.0), 7.2, 0.5, "cubierta", false],
	["banco_rellano", "terrazas", Rect2(-64.8, -14.6, 0.5, 2.2), 4.5, 0.45, "bajo", true],
	["muralla_oeste_n", "terrazas", Rect2(-100.0, -92.0, 3.0, 87.0), 0.0, 18.0, "muro", true],
	# --- T1, Calle de las Casas: pretil al sur, casas al norte (OCULTABLES: quedan al sur de T2)
	["pretil_t1_o", "terrazas", Rect2(-97.0, -20.4, 35.0, 0.4), 6.0, 0.9, "bajo", true],
	["pretil_t1_e", "terrazas", Rect2(-58.0, -20.4, 20.0, 0.4), 6.0, 0.9, "bajo", true],
	["pretil_t1_fin", "terrazas", Rect2(-38.4, -25.0, 0.4, 4.6), 6.0, 0.9, "bajo", true],
	["banco_t1", "terrazas", Rect2(-84.0, -20.9, 2.4, 0.5), 6.0, 0.45, "bajo", true],
	["banda_t1_fin", "terrazas", Rect2(-38.0, -35.0, 8.0, 15.0), 3.0, 3.0, "terreno", true],
	["casa_atajo_o", "terrazas", Rect2(-97.0, -35.0, 7.0, 10.0), 6.0, 6.0, "casa", true],
	["casa_atajo_e", "terrazas", Rect2(-86.0, -35.0, 7.0, 10.0), 6.0, 5.0, "casa", true],
	["vivienda_odila", "terrazas", Rect2(-78.0, -35.0, 8.0, 7.0), 6.0, 6.5, "casa", true],
	["hoja_vivienda", "terrazas", Rect2(-74.7, -28.0, 1.4, 0.08), 6.0, 2.4, "puerta", false],
	["tapia_patio_o", "terrazas", Rect2(-79.0, -35.0, 1.0, 7.0), 6.0, 2.2, "muro", true],
	["tapia_patio_e", "terrazas", Rect2(-70.0, -35.0, 1.0, 7.0), 6.0, 2.2, "muro", true],
	["banco_vivienda", "terrazas", Rect2(-78.6, -27.6, 2.2, 0.5), 6.0, 0.45, "bajo", true],
	["rosal_vivienda", "terrazas", Rect2(-71.0, -27.7, 0.6, 0.6), 6.0, 1.2, "decor", true],
	["casa_t1_c", "terrazas", Rect2(-69.0, -35.0, 7.0, 10.0), 6.0, 5.5, "casa", true],
	["casa_glicinia", "terrazas", Rect2(-62.0, -35.0, 9.0, 10.0), 6.0, 6.5, "casa", true],
	["glicinia_fachada", "terrazas", Rect2(-62.0, -25.7, 9.0, 0.7), 8.6, 1.4, "copa", false],
	["casa_t1_e1", "terrazas", Rect2(-53.0, -33.0, 8.0, 8.0), 6.0, 4.5, "casa", true],
	["ladera_t1_e1", "terrazas", Rect2(-53.0, -35.0, 8.0, 2.0), 6.0, 2.0, "terreno", true],
	["casa_t1_e2", "terrazas", Rect2(-45.0, -35.0, 7.0, 10.0), 6.0, 7.0, "casa", true],
	["tendedero_t1", "terrazas", Rect2(-52.0, -24.2, 6.0, 0.1), 8.5, 0.1, "cubierta", false],
	["tendedero_patio", "terrazas", Rect2(-78.0, -26.6, 6.0, 0.1), 8.5, 0.1, "cubierta", false],
	# --- Atajo de la Hornacina (del barrio): el arco de paso y la hornacina en la pared de la casa del este
	["arco_atajo", "terrazas", Rect2(-90.0, -30.6, 4.0, 0.6), 9.9, 0.6, "cubierta", false],
	["hornacina", "terrazas", Rect2(-86.1, -30.25, 0.1, 0.5), 8.0, 1.0, "decor", false],
	# --- T2 y la Plazuela de los Juegos: casas al norte (OCULTABLES: al sur de T3), la fuente, la glicinia, el pretil
	["casa_t2_o", "terrazas", Rect2(-97.0, -49.0, 10.0, 8.0), 8.0, 6.0, "casa", true],
	["casa_t2_c", "terrazas", Rect2(-87.0, -49.0, 13.0, 8.0), 8.0, 5.0, "casa", true],
	["muro_plazuela", "terrazas", Rect2(-74.0, -49.0, 16.0, 2.0), 8.0, 2.0, "terreno", true],
	["pretil_plazuela", "terrazas", Rect2(-74.0, -49.4, 8.0, 0.4), 10.0, 0.9, "bajo", true],
	["casa_t2_e", "terrazas", Rect2(-58.0, -49.0, 10.0, 8.0), 8.0, 6.0, "casa", true],
	["casa_t2_fin", "terrazas", Rect2(-44.0, -41.0, 6.0, 6.0), 8.0, 5.0, "casa", true],
	["huerto_t2_fin", "terrazas", Rect2(-38.0, -41.0, 8.0, 6.0), 6.0, 2.0, "terreno", true],
	["relleno_t2_e", "terrazas", Rect2(-44.0, -49.0, 14.0, 8.0), 8.0, 2.0, "terreno", true],
	["fuente_terrazas", "terrazas", Rect2(-67.5, -45.5, 3.0, 3.0), 8.0, 0.8, "bajo", true],
	["fuente_terrazas_cano", "terrazas", Rect2(-66.3, -44.3, 0.6, 0.6), 8.8, 1.4, "decor", true],
	["glicinia_plazuela_tronco", "terrazas", Rect2(-73.6, -46.6, 0.5, 0.5), 8.0, 2.8, "arbol", true],
	["glicinia_plazuela", "terrazas", Rect2(-75.0, -48.0, 4.0, 4.0), 10.6, 1.6, "copa", false],
	["banco_plazuela", "terrazas", Rect2(-61.0, -46.6, 2.4, 0.5), 8.0, 0.45, "bajo", true],
	["tendedero_t2", "terrazas", Rect2(-96.0, -37.6, 5.0, 0.1), 10.5, 0.1, "cubierta", false],
	# --- T3: la Casa Puente (paso bajo edificio), el Patio de la Pieza (sin salida), las casas al norte
	["casa_patio_o", "terrazas", Rect2(-97.0, -58.0, 10.0, 9.0), 10.0, 5.5, "casa", true],
	["casa_patio_n", "terrazas", Rect2(-97.0, -66.0, 23.0, 8.0), 10.0, 7.0, "casa", true],
	["peana_pieza", "terrazas", Rect2(-82.0, -57.6, 3.0, 1.0), 10.0, 0.6, "bajo", true],
	["casa_t3_o", "terrazas", Rect2(-74.0, -60.0, 8.0, 7.0), 10.0, 6.0, "casa", true],
	["casa_puente", "terrazas", Rect2(-66.0, -60.0, 10.0, 7.0), 10.0, 6.5, "casa", true],
	["paso_casa_puente", "terrazas", Rect2(-66.0, -53.0, 6.0, 4.0), 12.8, 3.7, "cubierta", false],
	["casa_t3_e", "terrazas", Rect2(-52.0, -60.0, 8.0, 7.0), 10.0, 5.0, "casa", true],
	["relleno_t3_e", "terrazas", Rect2(-44.0, -60.0, 14.0, 11.0), 10.0, 1.5, "terreno", true],
	# --- T4: el lavadero cubierto (la referencia), sus pilares, la ropa tendida, las casas altas, huertos y muralla
	["casa_t4_o", "terrazas", Rect2(-74.0, -66.0, 4.0, 6.0), 12.0, 5.0, "casa", true],
	["lavadero", "terrazas", Rect2(-63.0, -70.5, 6.0, 2.5), 12.0, 0.8, "bajo", true],
	["tejadillo_lavadero", "terrazas", Rect2(-64.0, -71.5, 8.0, 4.5), 14.8, 0.4, "cubierta", false],
	["pilar_lavadero_1", "terrazas", Rect2(-64.0, -71.5, 0.4, 0.4), 12.0, 2.8, "muro", true],
	["pilar_lavadero_2", "terrazas", Rect2(-56.4, -71.5, 0.4, 0.4), 12.0, 2.8, "muro", true],
	["pilar_lavadero_3", "terrazas", Rect2(-64.0, -67.4, 0.4, 0.4), 12.0, 2.8, "muro", true],
	["pilar_lavadero_4", "terrazas", Rect2(-56.4, -67.4, 0.4, 0.4), 12.0, 2.8, "muro", true],
	["tendedero_lavadero", "terrazas", Rect2(-55.4, -71.6, 0.1, 4.0), 14.4, 0.1, "cubierta", false],
	["casa_alta_1", "terrazas", Rect2(-97.0, -80.0, 12.0, 14.0), 12.0, 7.0, "casa", true],
	["casa_alta_2", "terrazas", Rect2(-85.0, -79.0, 11.0, 13.0), 12.0, 6.0, "casa", true],
	["casa_alta_3", "terrazas", Rect2(-74.0, -80.0, 8.0, 14.0), 12.0, 8.0, "casa", true],
	["casa_lavadero_n", "terrazas", Rect2(-66.0, -80.0, 12.0, 8.0), 12.0, 5.0, "casa", true],
	["casa_t4_n1", "terrazas", Rect2(-54.0, -76.0, 10.0, 10.0), 12.0, 6.5, "casa", true],
	["casa_t4_n2", "terrazas", Rect2(-44.0, -74.0, 8.0, 8.0), 12.0, 5.0, "casa", true],
	["huerto_t4_e", "terrazas", Rect2(-36.0, -80.0, 6.0, 14.0), 12.0, 0.8, "terreno", true],
	["banco_t4", "terrazas", Rect2(-38.0, -65.9, 2.4, 0.5), 12.0, 0.45, "bajo", true],
	["huertos_altos", "terrazas", Rect2(-97.0, -89.0, 67.0, 9.0), 12.0, 1.5, "terreno", true],
	["muralla_norte_o", "terrazas", Rect2(-97.0, -92.0, 67.0, 3.0), 12.0, 8.0, "muro", true],
]
# Lo que la escena aclara cuando tapa a Kael (además de cubiertas y copas): las casas de cada terraza, que quedan al SUR de
# la calle de la terraza de arriba (la cámara mira desde el sur).
const OCULTABLES := ["casa_atajo_o", "casa_atajo_e", "vivienda_odila", "casa_t1_c", "casa_glicinia", "casa_t1_e1",
	"casa_t1_e2", "casa_t2_o", "casa_t2_c", "casa_t2_e", "casa_t2_fin", "casa_t3_o", "casa_puente", "casa_t3_e",
	"casa_patio_o", "casa_t4_o"]

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; el resto, sitios con
# nombre para la vida del sector (vecinos trabajando, niños jugando) y los lugares reservados del plan §3.
const ANCLAS := {
	"referencia": Vector3(-60.0, 12.0, -64.0),       # ante el lavadero de la terraza alta [P] (= ref_terrazas)
	"rotulo": Vector3(-60.0, 12.0, -64.0),
	"reserva_piezas_patio": Vector3(-80.0, 10.0, -50.0),   # [P] el Patio de la Pieza: la Pieza Huérfana (sin implementar)
	"glicinias": Vector3(-60.0, 4.5, -13.5),         # rellano de la escalinata, bajo la pérgola
	"banco_glicinias": Vector3(-63.8, 4.5, -13.5),
	"odila_costura": Vector3(-76.5, 6.0, -26.6),     # Odila [P] cose a la puerta de su casa
	"nela_juego": Vector3(-71.0, 6.0, -22.5),        # Nela [P] juega en la calle, ante su casa
	"vecina_tendedero": Vector3(-49.0, 6.0, -23.0),  # tendiendo ropa en T1
	"banco_t1": Vector3(-82.8, 6.0, -21.6),          # el banco del pretil (vista sobre los huertos y el Patio del Cuervo)
	"mirador_t1": Vector3(-39.5, 6.0, -22.5),        # el fin de T1: vista al este, sobre la plaza
	"hornacina": Vector3(-86.6, 7.0, -30.0),         # ante la hornacina del atajo (velas)
	"ninos_juego_1": Vector3(-71.0, 8.0, -44.0),     # niños jugando en la plazuela [C mundo vivo, sitio P]
	"ninos_juego_2": Vector3(-62.0, 8.0, -42.5),
	"fuente_terrazas": Vector3(-66.0, 8.0, -41.8),   # ante la fuente de la plazuela
	"vecino_patio": Vector3(-84.0, 10.0, -51.0),     # un vecino barre su patio (el de la Pieza)
	"lavandera_1": Vector3(-61.0, 12.0, -67.6),      # lavanderas en el lavadero
	"lavandera_2": Vector3(-58.0, 12.0, -71.6),
	"tendedero_lavadero": Vector3(-55.0, 12.0, -68.5),
	"puerta_vivienda": Vector3(-74.0, 6.0, -28.0),
	"puerta_casa_glicinia": Vector3(-57.5, 6.0, -25.0),
	"puerta_casa_t1_e2": Vector3(-41.5, 6.0, -25.0),
	"puerta_casa_t2_o": Vector3(-92.0, 8.0, -41.0),
	"puerta_casa_t2_c": Vector3(-80.0, 8.0, -41.0),
	"puerta_casa_t2_fin": Vector3(-44.05, 8.0, -38.0),
	"puerta_casa_patio": Vector3(-86.95, 10.0, -53.5),
	"puerta_casa_t3_e": Vector3(-48.0, 10.0, -53.0),
	"puerta_casa_t4_o": Vector3(-69.95, 12.0, -63.0),
	"puerta_casa_t4_n1": Vector3(-49.0, 12.0, -66.0),
	"n_pie": Vector3(-60.0, 3.0, -6.0),
	"n_rellano": Vector3(-60.0, 4.5, -13.5),
	"n_t1": Vector3(-60.0, 6.0, -22.5),
	"n_t1_o": Vector3(-88.0, 6.0, -22.5),
	"n_t1_e": Vector3(-40.0, 6.0, -22.5),
	"n_atajo": Vector3(-88.0, 7.0, -30.0),
	"n_t2_o": Vector3(-88.0, 8.0, -38.0),
	"n_t2": Vector3(-66.0, 8.0, -38.0),
	"n_plazuela": Vector3(-62.0, 8.0, -44.0),
	"n_t2_e": Vector3(-46.0, 8.0, -38.0),
	"n_escalera_e": Vector3(-46.0, 9.0, -45.0),
	"n_t3_e": Vector3(-46.0, 10.0, -51.0),
	"n_t3_c": Vector3(-54.0, 10.0, -51.0),
	"n_t3": Vector3(-63.0, 10.0, -51.0),
	"n_patio": Vector3(-80.0, 10.0, -51.0),
	"n_escalera_lav": Vector3(-54.0, 11.0, -56.5),
	"n_t4": Vector3(-54.0, 12.0, -63.0),
	"n_lavadero": Vector3(-60.0, 12.0, -67.0),
	"n_t4_o": Vector3(-68.5, 12.0, -63.0),
	"n_t4_e": Vector3(-31.0, 12.0, -62.0),
}

# Puertas previstas (los interiores NO existen: la escena dice «Aún no se puede entrar (en obras).»). Formato del barrio:
# fuera (donde aparece Kael y el centro del botón), mira (rotation.y al salir: 0 norte, PI sur, PI/2 oeste, −PI/2 este),
# radio del botón, texto, ancla del umbral. La vivienda de Odila y Nela es la del barrio (plan §4: su interior se
# reutilizará tal cual).
const PUERTAS := {
	"vivienda_odila": {"fuera": Vector3(-74.0, 6.0, -26.6), "mira": PI, "radio": 1.6, "texto": "Llamar a la casa de Odila",
		"ancla": "puerta_vivienda", "nombre": "Casa de Odila y Nela"},
	"casa_glicinia": {"fuera": Vector3(-57.5, 6.0, -23.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_glicinia", "nombre": "Casa de las Glicinias"},
	"casa_t1_e2": {"fuera": Vector3(-41.5, 6.0, -23.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t1_e2", "nombre": "Casa"},
	"casa_t2_o": {"fuera": Vector3(-92.0, 8.0, -39.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t2_o", "nombre": "Casa"},
	"casa_t2_c": {"fuera": Vector3(-80.0, 8.0, -39.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t2_c", "nombre": "Casa"},
	"casa_t2_fin": {"fuera": Vector3(-45.4, 8.0, -38.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t2_fin", "nombre": "Casa"},
	"casa_patio": {"fuera": Vector3(-85.6, 10.0, -53.5), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_patio", "nombre": "Casa del patio"},
	"casa_t3_e": {"fuera": Vector3(-48.0, 10.0, -51.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t3_e", "nombre": "Casa"},
	"casa_t4_o": {"fuera": Vector3(-68.6, 12.0, -63.0), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t4_o", "nombre": "Casa"},
	"casa_t4_n1": {"fuera": Vector3(-49.0, 12.0, -64.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_t4_n1", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros, como en el barrio). Sus extremos en los bordes (n_pie hacia el
# Patio del Cuervo, n_t4_e hacia el Barrio Alto) enlazan con el grafo global del plano (c_escaleras_terrazas,
# c_terrazas_altas). La ruta principal es el atajo de la taberna al barrio alto.
const GRAFO := {
	"n_pie": ["n_rellano"],
	"n_rellano": ["n_pie", "n_t1"],
	"n_t1": ["n_rellano", "n_t1_o", "n_t1_e"],
	"n_t1_o": ["n_t1", "n_atajo"],
	"n_t1_e": ["n_t1"],
	"n_atajo": ["n_t1_o", "n_t2_o"],
	"n_t2_o": ["n_atajo", "n_t2"],
	"n_t2": ["n_t2_o", "n_plazuela", "n_t2_e"],
	"n_plazuela": ["n_t2"],
	"n_t2_e": ["n_t2", "n_escalera_e"],
	"n_escalera_e": ["n_t2_e", "n_t3_e"],
	"n_t3_e": ["n_escalera_e", "n_t3_c"],
	"n_t3_c": ["n_t3_e", "n_t3", "n_escalera_lav"],
	"n_t3": ["n_t3_c", "n_patio"],
	"n_patio": ["n_t3"],
	"n_escalera_lav": ["n_t3_c", "n_t4"],
	"n_t4": ["n_escalera_lav", "n_lavadero", "n_t4_o", "n_t4_e"],
	"n_lavadero": ["n_t4"],
	"n_t4_o": ["n_t4"],
	"n_t4_e": ["n_t4"],
}

# ---------------------------------------------------------------------------------------------------- cámara
# Sin zonas: el foco es Kael. (Un «eje» en el atajo o en las escaleras, de 4 m de ancho, no se pone: con el margen de 2,5 m
# de las zonas, el foco saltaría al entrar en una zona tan estrecha; calculado, no probado.)
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
