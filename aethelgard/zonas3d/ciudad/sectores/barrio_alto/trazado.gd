extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 7, BARRIO ALTO DE LAS RAÍCES [P]. MAQUETA del agente D (sectores 4
# y 7) sobre el trazado mínimo de M0. Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§3; contrato: docs/v12/CIUDAD_OAKHAVEN.md;
# lo hecho aquí: docs/v12/ciudad_sectores/D.md. Lo que hay es PROPUESTA [P] salvo lo marcado [C].
# Bordes acordados (plano.gd, CONEXIONES, no se tocan): Calle del Árbol (z −15, x −5..5, cota 4) desde la plaza, Escaleras
# de las Terrazas arriba (x −30, z −64..−60, cota 12) y Subida de la Colina (z −15, x 50..54, cota 10) desde los Oficios.
# Ancla global que cae aquí: «ref_barrio_alto» (0, 16, −83, al pie del Árbol).
#
#   - CALLE DEL ÁRBOL [P] (4 → 12): el eje visual de la ciudad, tres tramos de escalinata (33 %) con dos rellanos; en el
#     primero, dos casas con su puerta y dos cipreses; en el segundo sale el paseo del Concejo.
#   - PASEO DEL CONCEJO [P] (10): la Casa del Concejo [C] con su atrio (dentro, el tapiz [C]: la maqueta no enseña nada más),
#     casas con puerta al norte y un pretil al sur sobre los jardines; acaba en el MIRADOR DEL CONCEJO (sin salida, con la
#     vista del valle, plan §2). Del paseo baja al sur el borde con la SUBIDA DE LA COLINA [C] (llano a la cota 10, con
#     una casa, banco y ciprés).
#   - PLAZA DEL ÁRBOL [P] (12): jardines (dos parterres con cipreses), bancos, casas con puerta; al oeste, el paso de las
#     Terrazas (el atajo desde la taberna llega aquí).
#   - RAMPA DE LAS RAÍCES (12 → 16), dos tramos con un rellano, y el PÓRTICO DE PIEDRA ENTRE LAS RAÍCES [P] arriba (en
#     lugar del templo de vidrieras de la imagen, que NO se hace; sin función narrativa).
#   - TERRAZA DE LAS RAÍCES (16): el ÁRBOL MILENARIO [C] gigante con sus raíces, que se anda ALREDEDOR (por delante, por
#     los dos lados y por detrás, bajo una raíz en arco); Doña Encina [C según el plan], guarda del Árbol, junto al pórtico;
#     el MIRADOR DE LAS RAÍCES al oeste (sin salida, con la vista de la ciudad).
# La puerta del crematorio no es de este sector (la Colina la dibuja «oficios») y aquí no se construye nada bajo ella.
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "barrio_alto"

# ---------------------------------------------------------------------------------------------------- suelo
const SUELOS := [
	# Calle del Árbol
	["barrio_alto", Rect2(-5.0, -17.0, 10.0, 2.0), "", 4.0, 4.0],       # 0 pie (borde z −15, cota 4)
	["barrio_alto", Rect2(-5.0, -26.0, 10.0, 9.0), "z", 7.0, 4.0],      # 1 tramo 1 (33 %)
	["barrio_alto", Rect2(-8.0, -30.0, 16.0, 4.0), "", 7.0, 7.0],       # 2 rellano 1 (más ancho: dos casas)
	["barrio_alto", Rect2(-5.0, -39.0, 10.0, 9.0), "z", 10.0, 7.0],     # 3 tramo 2
	["barrio_alto", Rect2(-5.0, -45.0, 10.0, 6.0), "", 10.0, 10.0],     # 4 rellano 2 (sale el paseo del Concejo)
	["barrio_alto", Rect2(-5.0, -51.0, 10.0, 6.0), "z", 12.0, 10.0],    # 5 tramo 3
	# Plaza del Árbol y el paso de las Terrazas
	["barrio_alto", Rect2(-16.0, -64.0, 32.0, 13.0), "", 12.0, 12.0],   # 6 plaza del Árbol
	["barrio_alto", Rect2(-30.0, -64.0, 14.0, 4.0), "", 12.0, 12.0],    # 7 paso de las Terrazas (borde x −30, cota 12)
	# Rampa de las Raíces (12 → 16)
	["barrio_alto", Rect2(-4.0, -70.0, 8.0, 6.0), "z", 14.0, 12.0],     # 8 primer tramo (33 %)
	["barrio_alto", Rect2(-6.0, -73.0, 12.0, 3.0), "", 14.0, 14.0],     # 9 rellano de las Raíces
	["barrio_alto", Rect2(-4.0, -79.0, 8.0, 6.0), "z", 16.0, 14.0],     # 10 segundo tramo
	# Terraza de las Raíces (16), alrededor del tronco (x −4,5..4,5; z −89,5..−83,5)
	["barrio_alto", Rect2(-18.0, -83.5, 36.0, 4.5), "", 16.0, 16.0],    # 11 delante del Árbol (el pórtico, la referencia)
	["barrio_alto", Rect2(-18.0, -89.5, 13.5, 6.0), "", 16.0, 16.0],    # 12 lado oeste
	["barrio_alto", Rect2(4.5, -89.5, 13.5, 6.0), "", 16.0, 16.0],      # 13 lado este
	["barrio_alto", Rect2(-18.0, -92.0, 36.0, 2.5), "", 16.0, 16.0],    # 14 detrás del Árbol (bajo la raíz en arco)
	# Paseo del Concejo (10), su atrio, el mirador y el borde con la Subida de la Colina
	["barrio_alto", Rect2(5.0, -44.0, 53.0, 4.0), "", 10.0, 10.0],      # 15 paseo (x 54..58: el mirador)
	["barrio_alto", Rect2(28.0, -40.0, 14.0, 3.0), "", 10.0, 10.0],     # 16 atrio del Concejo
	["barrio_alto", Rect2(50.0, -40.0, 4.0, 25.0), "", 10.0, 10.0],     # 17 hacia la Colina (borde z −15, cota 10)
]

# ---------------------------------------------------------------------------------------------------- bloques
const BLOQUES := [
	# --- Calle del Árbol: casas y jardines a los lados, escalonados con la escalinata
	["jardin_bajo_o", "barrio_alto", Rect2(-30.0, -26.0, 15.0, 11.0), 4.0, 2.5, "terreno", true],
	["casa_calle_o", "barrio_alto", Rect2(-15.0, -26.0, 10.0, 8.0), 4.0, 6.5, "casa", true],
	["jardincillo_o", "barrio_alto", Rect2(-15.0, -18.0, 10.0, 3.0), 4.0, 0.6, "terreno", true],
	["huerto_calle_o", "barrio_alto", Rect2(-30.0, -34.0, 10.0, 8.0), 4.0, 4.0, "terreno", true],
	["casa_rellano_o", "barrio_alto", Rect2(-20.0, -34.0, 12.0, 8.0), 7.0, 6.0, "casa", true],
	["jardinera_r1_o", "barrio_alto", Rect2(-8.0, -34.0, 3.0, 4.0), 7.0, 1.0, "terreno", true],
	["cipres_r1_o", "barrio_alto", Rect2(-8.0, -30.0, 0.5, 0.5), 7.0, 6.0, "arbol", true],
	["ladera_o", "barrio_alto", Rect2(-30.0, -45.0, 25.0, 11.0), 4.0, 6.0, "terreno", true],
	["banda_plaza_o", "barrio_alto", Rect2(-30.0, -51.0, 25.0, 6.0), 10.0, 2.0, "terreno", true],
	["casa_calle_e", "barrio_alto", Rect2(5.0, -26.0, 9.0, 9.0), 4.0, 6.0, "casa", true],
	["jardincillo_e", "barrio_alto", Rect2(5.0, -17.0, 9.0, 2.0), 4.0, 0.6, "terreno", true],
	["jardinera_r1_e", "barrio_alto", Rect2(5.0, -34.0, 3.0, 4.0), 7.0, 1.0, "terreno", true],
	["cipres_r1_e", "barrio_alto", Rect2(7.5, -30.0, 0.5, 0.5), 7.0, 6.0, "arbol", true],
	["casa_rellano_e", "barrio_alto", Rect2(8.0, -34.0, 10.0, 8.0), 7.0, 5.5, "casa", true],
	["ladera_e1", "barrio_alto", Rect2(14.0, -26.0, 36.0, 11.0), 4.0, 3.0, "terreno", true],
	["jardines_concejo", "barrio_alto", Rect2(18.0, -34.0, 32.0, 8.0), 4.0, 4.5, "terreno", true],
	# la BALAUSTRADA de la escalinata (plan §3), sobre el terreno de los lados (no resta suelo): junto al tramo 2 y el
	# rellano 2 (cota 10) y junto al tramo 3, encima de las bandas de la plaza (cota 12)
	["balaustrada_arbol_o1", "barrio_alto", Rect2(-5.4, -45.0, 0.4, 11.0), 10.0, 0.9, "bajo", true],
	["balaustrada_arbol_o2", "barrio_alto", Rect2(-5.4, -51.0, 0.4, 6.0), 12.0, 0.9, "bajo", true],
	["balaustrada_arbol_e1", "barrio_alto", Rect2(5.0, -40.0, 0.4, 6.0), 10.0, 0.9, "bajo", true],
	["balaustrada_arbol_e2", "barrio_alto", Rect2(5.0, -51.0, 0.4, 7.0), 12.0, 0.9, "bajo", true],
	# --- paseo del Concejo: la ladera al sur con su pretil, el atrio, las casas y el Concejo [C] al norte
	["ladera_e2_o", "barrio_alto", Rect2(5.0, -40.0, 23.0, 6.0), 4.0, 6.0, "terreno", true],
	["ladera_e2_c", "barrio_alto", Rect2(28.0, -37.0, 14.0, 3.0), 4.0, 6.0, "terreno", true],
	["ladera_e2_e", "barrio_alto", Rect2(42.0, -40.0, 8.0, 6.0), 4.0, 6.0, "terreno", true],
	["pretil_paseo_o", "barrio_alto", Rect2(5.0, -40.4, 23.0, 0.4), 10.0, 0.9, "bajo", true],
	["pretil_paseo_e", "barrio_alto", Rect2(42.0, -40.4, 8.0, 0.4), 10.0, 0.9, "bajo", true],
	["pretil_atrio", "barrio_alto", Rect2(28.0, -37.4, 14.0, 0.4), 10.0, 0.9, "bajo", true],
	["pretil_atrio_o", "barrio_alto", Rect2(27.6, -40.0, 0.4, 3.0), 10.0, 0.9, "bajo", true],
	["pretil_atrio_e", "barrio_alto", Rect2(42.0, -40.0, 0.4, 3.0), 10.0, 0.9, "bajo", true],
	["banco_atrio", "barrio_alto", Rect2(28.0, -39.6, 0.5, 2.2), 10.0, 0.45, "bajo", true],
	["cipres_atrio_o", "barrio_alto", Rect2(29.2, -37.9, 0.5, 0.5), 10.0, 6.0, "arbol", true],
	["cipres_atrio_e", "barrio_alto", Rect2(40.3, -37.9, 0.5, 0.5), 10.0, 6.0, "arbol", true],
	["banda_plaza_e", "barrio_alto", Rect2(5.0, -51.0, 11.0, 7.0), 10.0, 2.0, "terreno", true],
	["casa_paseo_1", "barrio_alto", Rect2(16.0, -54.0, 8.0, 10.0), 10.0, 5.5, "casa", true],
	["concejo", "barrio_alto", Rect2(24.0, -62.0, 22.0, 18.0), 10.0, 9.0, "casa", true],
	["hoja_concejo", "barrio_alto", Rect2(34.0, -44.0, 2.0, 0.08), 10.0, 3.0, "puerta", false],
	["casa_paseo_3", "barrio_alto", Rect2(46.0, -54.0, 10.0, 10.0), 10.0, 6.0, "casa", true],
	["jardin_paseo_e", "barrio_alto", Rect2(56.0, -54.0, 4.0, 10.0), 10.0, 1.0, "terreno", true],
	["relleno_paseo_n", "barrio_alto", Rect2(46.0, -62.0, 14.0, 8.0), 10.0, 3.0, "terreno", true],
	["relleno_concejo_n", "barrio_alto", Rect2(24.0, -64.0, 36.0, 2.0), 10.0, 4.0, "terreno", true],
	# --- el Mirador del Concejo (sin salida, la vista del valle) y el borde con la Subida de la Colina
	["pretil_mirador", "barrio_alto", Rect2(57.6, -44.0, 0.4, 4.0), 10.0, 1.0, "bajo", true],
	["banco_mirador", "barrio_alto", Rect2(55.0, -44.0, 2.0, 0.5), 10.0, 0.45, "bajo", true],
	["borde_mirador", "barrio_alto", Rect2(54.0, -40.0, 6.0, 4.0), 10.0, 1.0, "terreno", true],
	["casa_bajada", "barrio_alto", Rect2(54.0, -36.0, 6.0, 10.0), 10.0, 5.0, "casa", true],
	["talud_bajada", "barrio_alto", Rect2(54.0, -26.0, 6.0, 11.0), 8.0, 2.5, "terreno", true],
	["banco_bajada", "barrio_alto", Rect2(50.0, -24.0, 0.5, 2.0), 10.0, 0.45, "bajo", true],
	["cipres_bajada", "barrio_alto", Rect2(50.0, -20.0, 0.5, 0.5), 10.0, 6.0, "arbol", true],
	# el pretil oeste del paso hacia la Colina, sobre el terreno (no resta suelo): 0,9 m sobre la cota 10 y, donde el
	# terreno baja (jardines a 8,5, ladera a 7), muro de contención hasta abajo
	["pretil_colina_1", "barrio_alto", Rect2(49.6, -40.0, 0.4, 6.0), 10.0, 0.9, "bajo", true],
	["pretil_colina_2", "barrio_alto", Rect2(49.6, -34.0, 0.4, 8.0), 8.5, 2.4, "muro", true],
	["pretil_colina_3", "barrio_alto", Rect2(49.6, -26.0, 0.4, 11.0), 7.0, 3.9, "muro", true],
	# --- Plaza del Árbol: parterres con cipreses, bancos, casas con puerta; el paso de las Terrazas con su seto
	["jardin_plaza_o", "barrio_alto", Rect2(-14.0, -61.5, 6.0, 6.5), 12.0, 0.6, "bajo", true],
	["jardin_plaza_e", "barrio_alto", Rect2(8.0, -61.5, 6.0, 6.5), 12.0, 0.6, "bajo", true],
	["cipres_plaza_o", "barrio_alto", Rect2(-11.25, -58.5, 0.5, 0.5), 12.6, 6.0, "arbol", true],
	["cipres_plaza_e", "barrio_alto", Rect2(10.75, -58.5, 0.5, 0.5), 12.6, 6.0, "arbol", true],
	["banco_plaza_o", "barrio_alto", Rect2(-12.2, -55.0, 2.4, 0.5), 12.0, 0.45, "bajo", true],   # en la cara sur del parterre
	["banco_plaza_e", "barrio_alto", Rect2(9.8, -55.0, 2.4, 0.5), 12.0, 0.45, "bajo", true],
	["casa_plaza_e", "barrio_alto", Rect2(16.0, -64.0, 8.0, 10.0), 12.0, 6.0, "casa", true],
	["casa_plaza_n_o", "barrio_alto", Rect2(-16.0, -70.0, 10.0, 6.0), 12.0, 4.5, "casa", true],
	["jardinera_raices_o", "barrio_alto", Rect2(-6.0, -70.0, 2.0, 6.0), 12.0, 2.0, "terreno", true],
	["jardinera_raices_e", "barrio_alto", Rect2(4.0, -70.0, 2.0, 6.0), 12.0, 2.0, "terreno", true],
	["casa_plaza_n_e", "barrio_alto", Rect2(6.0, -70.0, 12.0, 6.0), 12.0, 5.0, "casa", true],
	["jardin_poniente", "barrio_alto", Rect2(-30.0, -60.0, 14.0, 9.0), 10.0, 2.0, "terreno", true],
	# setos y pretiles de los bordes de la plaza, sobre el terreno de al lado (no restan suelo ni tocan el borde con las
	# Terrazas): el seto del paso sigue en línea con el pretil del sur de T4
	["seto_poniente", "barrio_alto", Rect2(-30.0, -60.0, 14.0, 0.4), 12.0, 0.9, "bajo", true],
	["seto_plaza_o", "barrio_alto", Rect2(-16.4, -60.0, 0.4, 9.0), 12.0, 0.9, "bajo", true],
	["pretil_plaza_so", "barrio_alto", Rect2(-16.0, -51.0, 11.0, 0.4), 12.0, 0.9, "bajo", true],
	["pretil_plaza_se", "barrio_alto", Rect2(5.0, -51.0, 11.0, 0.4), 12.0, 0.9, "bajo", true],
	["casa_paso_n", "barrio_alto", Rect2(-30.0, -72.0, 14.0, 8.0), 12.0, 6.0, "casa", true],
	# --- bandas entre la plaza y la terraza de las Raíces
	["banda_raices_o", "barrio_alto", Rect2(-16.0, -79.0, 10.0, 9.0), 12.0, 4.0, "terreno", true],
	["banda_raices_o2", "barrio_alto", Rect2(-6.0, -79.0, 2.0, 6.0), 14.0, 2.0, "terreno", true],
	["banda_raices_e2", "barrio_alto", Rect2(4.0, -79.0, 2.0, 6.0), 14.0, 2.0, "terreno", true],
	["banda_raices_e", "barrio_alto", Rect2(6.0, -79.0, 12.0, 9.0), 12.0, 4.0, "terreno", true],
	["poniente_raices", "barrio_alto", Rect2(-30.0, -79.0, 14.0, 7.0), 12.0, 4.0, "terreno", true],
	["poniente_alto", "barrio_alto", Rect2(-30.0, -92.0, 12.0, 13.0), 12.0, 4.5, "terreno", true],
	["levante_raices", "barrio_alto", Rect2(18.0, -82.0, 42.0, 18.0), 12.0, 4.0, "terreno", true],
	["levante_alto", "barrio_alto", Rect2(28.0, -92.0, 32.0, 10.0), 12.0, 4.0, "terreno", true],
	["levante_rincon", "barrio_alto", Rect2(18.0, -92.0, 10.0, 2.0), 12.0, 4.0, "terreno", true],
	["casa_raices_e", "barrio_alto", Rect2(18.0, -90.0, 10.0, 8.0), 16.0, 5.0, "casa", true],
	# --- el Árbol Milenario [C], sus raíces, el pórtico de piedra entre ellas [P], el mirador de las Raíces
	["arbol_tronco", "barrio_alto", Rect2(-4.5, -89.5, 9.0, 6.0), 16.0, 18.0, "arbol", true],
	["arbol_copa", "barrio_alto", Rect2(-26.0, -112.0, 52.0, 46.0), 30.0, 20.0, "copa", false],
	["raiz_o", "barrio_alto", Rect2(-12.0, -87.5, 7.5, 1.2), 16.0, 0.9, "arbol", true],
	["raiz_so", "barrio_alto", Rect2(-10.0, -83.2, 4.0, 1.0), 16.0, 0.7, "arbol", true],
	["raiz_e", "barrio_alto", Rect2(4.5, -86.5, 8.0, 1.2), 16.0, 0.9, "arbol", true],
	["raiz_se", "barrio_alto", Rect2(6.0, -83.2, 4.0, 1.0), 16.0, 0.7, "arbol", true],
	["raiz_arco", "barrio_alto", Rect2(1.5, -92.0, 1.5, 2.5), 18.4, 1.0, "cubierta", false],
	["portico_pilar_o", "barrio_alto", Rect2(-5.5, -80.5, 1.0, 1.0), 16.0, 4.5, "muro", true],
	["portico_pilar_e", "barrio_alto", Rect2(4.5, -80.5, 1.0, 1.0), 16.0, 4.5, "muro", true],
	["portico_dintel", "barrio_alto", Rect2(-5.5, -80.5, 11.0, 1.0), 20.5, 1.0, "cubierta", false],
	["pretil_raices_o", "barrio_alto", Rect2(-18.0, -79.4, 12.5, 0.4), 16.0, 0.9, "bajo", true],
	["pretil_raices_e", "barrio_alto", Rect2(5.5, -79.4, 12.5, 0.4), 16.0, 0.9, "bajo", true],
	["banco_mirador_raices", "barrio_alto", Rect2(-17.5, -83.0, 0.5, 2.4), 16.0, 0.45, "bajo", true],
	["banco_encina", "barrio_alto", Rect2(-9.0, -80.9, 2.4, 0.5), 16.0, 0.45, "bajo", true],
	["muralla_norte", "barrio_alto", Rect2(-30.0, -96.0, 90.0, 4.0), 12.0, 10.0, "muro", true],
]
# Lo que la escena aclara cuando tapa a Kael (además de cubiertas y copas): las dos casas de la Calle del Árbol que quedan
# al sur del rellano 1, la casa del borde de la Colina (al sur del mirador) y el TRONCO del Árbol cuando Kael anda por
# detrás de él y los pilares del pórtico (la cámara está al sur).
const OCULTABLES := ["casa_calle_o", "casa_calle_e", "casa_bajada", "arbol_tronco", "portico_pilar_o", "portico_pilar_e"]

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; el resto, sitios con
# nombre (vecinos, miradores).
const ANCLAS := {
	"referencia": Vector3(0.0, 16.0, -83.0),        # al pie del Árbol Milenario [C] (= ref_barrio_alto)
	"rotulo": Vector3(0.0, 16.0, -81.0),
	"encina": Vector3(-8.0, 16.0, -81.6),           # Doña Encina [C según el plan], guarda del Árbol, junto al pórtico
	"mirador_raices": Vector3(-16.0, 16.0, -81.0),  # sin salida: la vista de la ciudad
	"tras_arbol": Vector3(0.0, 16.0, -91.0),        # detrás del tronco, bajo la raíz en arco
	"mirador_concejo": Vector3(56.0, 10.0, -42.0),  # sin salida: la vista del valle
	"atrio_concejo": Vector3(35.0, 10.0, -38.5),    # ante la Casa del Concejo [C] (el tapiz [C] está dentro)
	"vecino_paseo": Vector3(24.0, 10.0, -42.0),     # un vecino riega los jardines del paseo
	"vecina_plaza": Vector3(-4.0, 12.0, -57.0),
	"ninos_plaza": Vector3(4.0, 12.0, -56.0),       # niños jugando en la plaza del Árbol [C mundo vivo, sitio P]
	"banco_bajada": Vector3(51.4, 10.0, -23.0),
	"puerta_concejo": Vector3(35.0, 10.0, -44.0),
	"puerta_casa_rellano_o": Vector3(-8.0, 7.0, -28.0),
	"puerta_casa_rellano_e": Vector3(7.95, 7.0, -28.0),
	"puerta_casa_paseo_1": Vector3(20.0, 10.0, -44.0),
	"puerta_casa_paseo_3": Vector3(51.0, 10.0, -44.0),
	"puerta_casa_bajada": Vector3(53.95, 10.0, -31.0),
	"puerta_casa_plaza_e": Vector3(15.95, 12.0, -59.0),
	"puerta_casa_plaza_n_o": Vector3(-11.0, 12.0, -64.0),
	"puerta_casa_paso_n": Vector3(-23.0, 12.0, -64.0),
	"puerta_casa_raices_e": Vector3(17.95, 16.0, -86.0),
	"n_pie": Vector3(0.0, 4.0, -16.0),
	"n_rellano1": Vector3(0.0, 7.0, -28.0),
	"n_rellano2": Vector3(0.0, 10.0, -42.0),
	"n_paseo": Vector3(20.0, 10.0, -42.0),
	"n_concejo": Vector3(35.0, 10.0, -42.0),
	"n_paseo_e": Vector3(52.0, 10.0, -42.0),
	"n_mirador": Vector3(56.0, 10.0, -42.0),
	"n_colina": Vector3(52.0, 10.0, -16.0),
	"n_plaza_s": Vector3(0.0, 12.0, -53.0),
	"n_plaza": Vector3(0.0, 12.0, -62.0),
	"n_terrazas": Vector3(-29.0, 12.0, -62.0),
	"n_raices": Vector3(0.0, 14.0, -71.5),
	"n_arbol": Vector3(0.0, 16.0, -81.0),
	"n_arbol_o": Vector3(-15.0, 16.0, -81.0),
	"n_arbol_no": Vector3(-15.0, 16.0, -91.0),
	"n_tras_arbol": Vector3(0.0, 16.0, -91.0),
	"n_arbol_ne": Vector3(15.0, 16.0, -91.0),
	"n_arbol_e": Vector3(15.0, 16.0, -81.0),
}

# Puertas previstas (los interiores NO existen: la escena dice «Aún no se puede entrar (en obras).»). Formato del barrio:
# fuera, mira (0 norte, PI sur, PI/2 oeste, −PI/2 este), radio, texto, ancla del umbral.
const PUERTAS := {
	"concejo": {"fuera": Vector3(35.0, 10.0, -42.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la Casa del Concejo",
		"ancla": "puerta_concejo", "nombre": "Casa del Concejo"},
	"casa_rellano_o": {"fuera": Vector3(-6.6, 7.0, -28.0), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_rellano_o", "nombre": "Casa"},
	"casa_rellano_e": {"fuera": Vector3(6.6, 7.0, -28.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_rellano_e", "nombre": "Casa"},
	"casa_paseo_1": {"fuera": Vector3(20.0, 10.0, -42.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_paseo_1", "nombre": "Casa"},
	"casa_paseo_3": {"fuera": Vector3(51.0, 10.0, -42.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_paseo_3", "nombre": "Casa"},
	"casa_bajada": {"fuera": Vector3(52.6, 10.0, -31.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_bajada", "nombre": "Casa"},
	"casa_plaza_e": {"fuera": Vector3(14.6, 12.0, -59.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_plaza_e", "nombre": "Casa"},
	"casa_plaza_n_o": {"fuera": Vector3(-11.0, 12.0, -62.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_plaza_n_o", "nombre": "Casa"},
	"casa_paso_n": {"fuera": Vector3(-23.0, 12.0, -62.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_paso_n", "nombre": "Casa"},
	"casa_raices_e": {"fuera": Vector3(16.6, 16.0, -86.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_raices_e", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros). Sus extremos en los bordes (n_pie hacia la plaza, n_terrazas
# hacia las Terrazas, n_colina hacia los Oficios) enlazan con el grafo global del plano (c_calle_arbol, c_terrazas_altas,
# c_subida_colina). El anillo n_arbol → n_arbol_o → n_arbol_no → n_tras_arbol → n_arbol_ne → n_arbol_e → n_arbol rodea
# el tronco.
const GRAFO := {
	"n_pie": ["n_rellano1"],
	"n_rellano1": ["n_pie", "n_rellano2"],
	"n_rellano2": ["n_rellano1", "n_paseo", "n_plaza_s"],
	"n_paseo": ["n_rellano2", "n_concejo"],
	"n_concejo": ["n_paseo", "n_paseo_e"],
	"n_paseo_e": ["n_concejo", "n_mirador", "n_colina"],
	"n_mirador": ["n_paseo_e"],
	"n_colina": ["n_paseo_e"],
	"n_plaza_s": ["n_rellano2", "n_plaza"],
	"n_plaza": ["n_plaza_s", "n_terrazas", "n_raices"],
	"n_terrazas": ["n_plaza"],
	"n_raices": ["n_plaza", "n_arbol"],
	"n_arbol": ["n_raices", "n_arbol_o", "n_arbol_e"],
	"n_arbol_o": ["n_arbol", "n_arbol_no"],
	"n_arbol_no": ["n_arbol_o", "n_tras_arbol"],
	"n_tras_arbol": ["n_arbol_no", "n_arbol_ne"],
	"n_arbol_ne": ["n_tras_arbol", "n_arbol_e"],
	"n_arbol_e": ["n_arbol_ne", "n_arbol"],
}

# ---------------------------------------------------------------------------------------------------- cámara
# Sin zonas: el foco es Kael. (Un «eje» en la Calle del Árbol, de 10 m de ancho, haría saltar el foco ≈ 0,7 m por 0,25 m
# de Kael junto a sus bordes, más de los 0,6 que admite la prueba; calculado, no probado.)
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
