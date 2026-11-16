extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 1, PUERTA DEL SUR Y CARAVANAS. Maqueta del agente A (blockout
# recorrible a escala de los personajes, NO acabado). Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§4; contrato:
# docs/v12/CIUDAD_OAKHAVEN.md; lo de este sector: docs/v12/ciudad_sectores/A.md. Bordes acordados (plano.gd, CONEXIONES,
# no se cambian aquí): Calle Mayor (z 62, x −4..4, cota 0), Rampa de los Carros (x 45, z 76..82, cota 0) y Arco de los
# Pasajes (x −30, z 80..83, cota 1). La Puerta del Sur [C] es la ÚNICA salida al mapa; en la maqueta no se sale (Volver al
# banco).
#
# Coordenadas de CIUDAD (x este, z sur, y arriba). Todo [P] salvo lo marcado [C] (ciudades/oakhaven.gd: Puerta del Sur,
# Calle Mayor, cuerpo de guardia, soportal de la guardia con el libro, patio de la guardia con los requisados, Aldric).
#   - CALLE MAYOR, tramo sur (cota 0), con el SOPORTAL DE LA GUARDIA [C] al este (pilares y la planta del cuerpo de
#     guardia encima; el libro de guardia en su atril) y la casa de la Calle Mayor al oeste.
#   - EXPLANADA ante la Puerta del Sur (cota 0): el ensanche para orientarse; Aldric [C] junto a la puerta; el pilón [P].
#   - CUERPO DE GUARDIA [C] y su PATIO [C] (los trastos requisados y su cofre [C oak_cofre_requisados]) junto a la puerta.
#   - PATIO DE CARAVANAS (cota 0), el del barrio (plan §4) repartido aquí: el ESTABLO con Brena y Avena [P], abrevadero,
#     pozo, heno y cerca; carros de caravana con sus LONAS y un toldo de lonas entre ellos (paso cubierto; ahí la
#     reserva de Rastreadores [P]); el carro de portes de Tobías [P]; sale la Rampa de los Carros a la Ribera Baja.
#   - MUELLE DE CARGA [P] (cota 1) ante el almacén de portes [P], con su escalera: un fondo sin salida con razón (portes).
#   - Al oeste, la TERRAZA DEL ARCO [P] (cota 1) que llega del Arco de los Pasajes, con su escalera de piedra a la
#     explanada; el CALLEJÓN DE LOS ARRIEROS [P] (atajo en rampa del arco a la Calle Mayor sin cruzar la explanada); un
#     PASO BAJO CASA [P] que lleva al PATIO DEL POZO [P] (sin salida: pozo, niños jugando, vivienda, banco).
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "puerta_sur"

# ---------------------------------------------------------------------------------------------------- suelo
const SUELOS := [
	# cota 0: la Calle Mayor, el soportal, la explanada, el patio de la guardia y el de caravanas
	["puerta_sur", Rect2(-4.0, 62.0, 8.0, 19.0), "", 0.0, 0.0],          # Calle Mayor, tramo sur (borde z 62, cota 0)
	["puerta_sur", Rect2(-5.0, 62.0, 1.0, 13.0), "", 0.0, 0.0],          # su acera oeste (sigue la de la plaza, x −5)
	["puerta_sur", Rect2(4.0, 62.0, 4.0, 19.0), "", 0.0, 0.0],           # soportal de la guardia [C]
	["puerta_sur", Rect2(-7.0, 81.0, 25.0, 12.0), "", 0.0, 0.0],         # explanada ante la Puerta del Sur
	["puerta_sur", Rect2(8.0, 76.0, 10.0, 5.0), "", 0.0, 0.0],           # patio de la guardia [C]
	["puerta_sur", Rect2(18.0, 73.0, 23.0, 20.0), "", 0.0, 0.0],         # patio de caravanas
	["puerta_sur", Rect2(41.0, 76.0, 4.0, 6.0), "", 0.0, 0.0],           # salida a la Rampa de los Carros (borde x 45, cota 0)
	# cota 1: el muelle de carga [P] y su escalera
	["puerta_sur", Rect2(31.0, 66.0, 10.0, 4.0), "", 1.0, 1.0],          # muelle de carga ante el almacén de portes
	["puerta_sur", Rect2(35.0, 70.0, 3.0, 3.0), "z", 1.0, 0.0],          # escalera del muelle (33 %)
	# cota 1: el oeste (Terraza del Arco, callejón de los Arrieros, paso bajo casa y patio del pozo)
	["puerta_sur", Rect2(-30.0, 80.0, 1.0, 3.0), "", 1.0, 1.0],          # Arco de los Pasajes (borde x −30, cota 1)
	["puerta_sur", Rect2(-29.0, 79.0, 19.0, 12.0), "", 1.0, 1.0],        # Terraza del Arco
	["puerta_sur", Rect2(-10.0, 85.0, 3.0, 3.0), "x", 1.0, 0.0],         # escalera de piedra a la explanada (33 %)
	["puerta_sur", Rect2(-14.0, 75.0, 4.0, 4.0), "", 1.0, 1.0],          # callejón de los Arrieros, arriba
	["puerta_sur", Rect2(-10.0, 75.0, 6.0, 4.0), "x", 1.0, 0.0],         # su rampa a la Calle Mayor (17 %)
	["puerta_sur", Rect2(-23.0, 72.0, 3.0, 7.0), "", 1.0, 1.0],          # paso bajo la casa
	["puerta_sur", Rect2(-29.0, 65.0, 15.0, 7.0), "", 1.0, 1.0],         # patio del pozo (sin salida)
]

# ---------------------------------------------------------------------------------------------------- bloques
const BLOQUES := [
	# la muralla sur y la Puerta del Sur [C]
	["muralla_sur_o", "puerta_sur", Rect2(-30.0, 93.0, 26.0, 2.5), 0.0, 8.0, "muro", true],
	["torre_puerta_o", "puerta_sur", Rect2(-7.0, 93.0, 3.0, 3.5), 0.0, 9.5, "muro", true],
	["puerta_sur", "puerta_sur", Rect2(-4.0, 93.0, 8.0, 0.5), 0.0, 5.0, "puerta", true],
	["dintel_puerta", "puerta_sur", Rect2(-4.0, 93.0, 8.0, 2.5), 5.5, 2.5, "muro", false],
	["torre_puerta_e", "puerta_sur", Rect2(4.0, 93.0, 3.0, 3.5), 0.0, 9.5, "muro", true],
	["muralla_sur_e", "puerta_sur", Rect2(7.0, 93.0, 38.0, 2.5), 0.0, 8.0, "muro", true],
	# explanada: el pilón [P] (fuente de la puerta) y un banco al pie de la muralla
	["pilon_puerta", "puerta_sur", Rect2(-6.4, 89.4, 1.8, 1.8), 0.0, 0.8, "bajo", true],
	["cano_pilon", "puerta_sur", Rect2(-5.75, 90.05, 0.5, 0.5), 0.8, 1.0, "decor", true],
	["banco_explanada", "puerta_sur", Rect2(9.0, 92.3, 3.2, 0.6), 0.0, 0.45, "bajo", true],
	# Calle Mayor, oeste: la casa de la Calle Mayor (puerta a la calle)
	["casa_mayor_o", "puerta_sur", Rect2(-14.0, 62.0, 9.0, 13.0), 0.0, 7.0, "casa", true],
	["hoja_casa_mayor", "puerta_sur", Rect2(-5.08, 67.3, 0.08, 1.4), 0.0, 2.4, "puerta", false],
	# el cuerpo de guardia [C], su soportal [C] (la planta encima, pilares, el atril del libro) y su patio [C]
	["cuerpo_guardia", "puerta_sur", Rect2(8.0, 62.0, 10.0, 14.0), 0.0, 6.5, "casa", true],
	["hoja_guardia", "puerta_sur", Rect2(7.92, 71.3, 0.08, 1.4), 0.0, 2.4, "puerta", false],
	["cubierta_soportal_guardia", "puerta_sur", Rect2(4.0, 62.0, 4.0, 14.0), 3.6, 2.9, "cubierta", false],
	["pilar_guardia_1", "puerta_sur", Rect2(4.0, 65.8, 0.4, 0.4), 0.0, 3.6, "muro", true],
	["pilar_guardia_2", "puerta_sur", Rect2(4.0, 69.8, 0.4, 0.4), 0.0, 3.6, "muro", true],
	["pilar_guardia_3", "puerta_sur", Rect2(4.0, 73.8, 0.4, 0.4), 0.0, 3.6, "muro", true],
	["atril_libro_guardia", "puerta_sur", Rect2(7.4, 66.0, 0.5, 0.5), 0.0, 1.1, "decor", true],
	["valla_patio_guardia", "puerta_sur", Rect2(17.8, 73.0, 0.2, 5.0), 0.0, 1.1, "bajo", true],
	["trastos_requisados", "puerta_sur", Rect2(16.4, 76.1, 1.4, 1.2), 0.0, 1.0, "decor", true],
	["cofre_requisados", "puerta_sur", Rect2(14.8, 76.1, 0.9, 0.6), 0.0, 0.6, "decor", true],
	# el establo (del barrio): Brena y Avena [P]; abrevadero, pozo, heno, cerca, gancho del cepillo
	["establo", "puerta_sur", Rect2(18.0, 62.0, 12.0, 11.0), 0.0, 5.0, "casa", true],
	["hoja_establo", "puerta_sur", Rect2(23.3, 72.92, 1.4, 0.08), 0.0, 2.4, "puerta", false],
	["media_puerta_cuadra_1", "puerta_sur", Rect2(19.6, 72.92, 1.6, 0.08), 0.0, 1.2, "puerta", false],
	["media_puerta_cuadra_2", "puerta_sur", Rect2(26.8, 72.92, 1.6, 0.08), 0.0, 1.2, "puerta", false],
	["gancho_cepillo", "puerta_sur", Rect2(25.2, 72.92, 0.3, 0.08), 1.4, 0.3, "decor", false],
	["abrevadero", "puerta_sur", Rect2(18.2, 74.6, 0.8, 2.4), 0.0, 0.7, "bajo", true],
	["cerca_establo", "puerta_sur", Rect2(18.0, 77.6, 4.5, 0.2), 0.0, 1.0, "bajo", true],
	["pozo_establo", "puerta_sur", Rect2(30.6, 74.4, 1.4, 1.4), 0.0, 0.9, "muro", true],
	["heno", "puerta_sur", Rect2(28.2, 73.3, 1.4, 1.2), 0.0, 1.2, "decor", true],
	# caravanas: carros con sus lonas, el toldo de lonas entre ellos (reserva de Rastreadores [P]), el carro de portes
	["carro_caravana_1", "puerta_sur", Rect2(21.0, 82.5, 3.0, 2.0), 0.0, 1.6, "decor", true],
	["lona_carro_1", "puerta_sur", Rect2(21.0, 82.5, 3.0, 2.0), 1.6, 0.9, "cubierta", false],
	["carro_caravana_2", "puerta_sur", Rect2(31.0, 85.0, 3.0, 2.0), 0.0, 1.6, "decor", true],
	["lona_carro_2", "puerta_sur", Rect2(31.0, 85.0, 3.0, 2.0), 1.6, 0.9, "cubierta", false],
	["toldo_lonas", "puerta_sur", Rect2(24.0, 83.0, 7.0, 4.5), 2.7, 0.2, "cubierta", false],
	["poste_toldo_1", "puerta_sur", Rect2(24.0, 87.2, 0.25, 0.25), 0.0, 2.7, "muro", true],
	["poste_toldo_2", "puerta_sur", Rect2(30.75, 82.8, 0.25, 0.25), 0.0, 2.7, "muro", true],
	["carro_portes", "puerta_sur", Rect2(36.5, 82.0, 3.0, 2.0), 0.0, 1.6, "decor", true],
	["pila_cajas", "puerta_sur", Rect2(38.4, 76.4, 1.6, 1.6), 0.0, 1.3, "decor", true],
	["fardos", "puerta_sur", Rect2(36.0, 89.6, 2.6, 1.6), 0.0, 1.2, "decor", true],
	["banco_caravanas", "puerta_sur", Rect2(26.0, 92.3, 3.0, 0.6), 0.0, 0.45, "bajo", true],
	# el muelle de carga [P]: almacén de portes, taludes y pretiles; la casa del este y el cobertizo de carros
	["almacen_portes", "puerta_sur", Rect2(31.0, 62.0, 14.0, 4.0), 1.0, 6.0, "casa", true],
	["hoja_almacen", "puerta_sur", Rect2(35.8, 65.92, 1.6, 0.08), 1.0, 2.6, "puerta", false],
	["talud_muelle_o", "puerta_sur", Rect2(30.0, 66.0, 1.0, 7.0), 0.0, 1.0, "terreno", true],
	["talud_muelle_s1", "puerta_sur", Rect2(31.0, 70.0, 4.0, 3.0), 0.0, 1.0, "terreno", true],
	["talud_muelle_s2", "puerta_sur", Rect2(38.0, 70.0, 3.0, 3.0), 0.0, 1.0, "terreno", true],
	["pretil_muelle_1", "puerta_sur", Rect2(31.0, 69.6, 4.0, 0.4), 1.0, 0.9, "bajo", true],
	["pretil_muelle_2", "puerta_sur", Rect2(38.0, 69.6, 3.0, 0.4), 1.0, 0.9, "bajo", true],
	["sacos_muelle", "puerta_sur", Rect2(39.2, 66.4, 1.6, 1.2), 1.0, 1.0, "decor", true],
	["casa_este", "puerta_sur", Rect2(41.0, 66.0, 4.0, 10.0), 0.0, 6.5, "casa", true],
	["cobertizo_carros", "puerta_sur", Rect2(41.0, 82.0, 4.0, 11.0), 0.0, 3.5, "casa", true],
	# el oeste: el arco, la terraza (taludes, pretiles, banco, tendedero), el callejón de los Arrieros
	["muro_arco_n", "puerta_sur", Rect2(-30.0, 79.0, 1.0, 1.0), 0.0, 5.0, "muro", true],
	["muro_arco_s", "puerta_sur", Rect2(-30.0, 83.0, 1.0, 10.0), 0.0, 5.0, "muro", true],
	["dintel_arco_pasajes", "puerta_sur", Rect2(-30.5, 80.0, 1.5, 3.0), 3.8, 1.2, "cubierta", false],
	["talud_terraza_1", "puerta_sur", Rect2(-10.0, 79.0, 6.0, 2.0), 0.0, 1.0, "terreno", true],
	["talud_terraza_2", "puerta_sur", Rect2(-10.0, 81.0, 3.0, 4.0), 0.0, 1.0, "terreno", true],
	["talud_terraza_3", "puerta_sur", Rect2(-10.0, 88.0, 3.0, 5.0), 0.0, 1.0, "terreno", true],
	["arriate_terraza", "puerta_sur", Rect2(-29.0, 91.0, 19.0, 2.0), 0.0, 1.4, "terreno", true],
	["pretil_terraza_n", "puerta_sur", Rect2(-10.4, 79.0, 0.4, 6.0), 1.0, 0.9, "bajo", true],
	["pretil_terraza_s", "puerta_sur", Rect2(-10.4, 88.0, 0.4, 3.0), 1.0, 0.9, "bajo", true],
	["banco_terraza", "puerta_sur", Rect2(-20.0, 90.2, 3.0, 0.6), 1.0, 0.45, "bajo", true],
	["tendedero_terraza", "puerta_sur", Rect2(-27.0, 86.0, 4.0, 0.1), 3.6, 0.1, "decor", false],
	["pretil_callejon", "puerta_sur", Rect2(-10.0, 78.6, 6.0, 0.4), 0.5, 0.9, "bajo", true],
	["hornacina_arrieros", "puerta_sur", Rect2(-12.6, 74.92, 0.8, 0.08), 2.0, 1.0, "decor", false],
	# el paso bajo casa y el patio del pozo (sin salida)
	["casa_paso_o", "puerta_sur", Rect2(-30.0, 72.0, 7.0, 7.0), 1.0, 5.5, "casa", true],
	["hoja_casa_terraza", "puerta_sur", Rect2(-26.7, 78.92, 1.4, 0.08), 1.0, 2.4, "puerta", false],
	["casa_paso_e", "puerta_sur", Rect2(-20.0, 72.0, 6.0, 7.0), 1.0, 6.5, "casa", true],
	["cubierta_paso_pozo", "puerta_sur", Rect2(-23.0, 72.0, 3.0, 7.0), 3.8, 3.7, "cubierta", false],
	["muro_pozo_o", "puerta_sur", Rect2(-30.0, 65.0, 1.0, 7.0), 1.0, 4.0, "muro", true],
	["casa_pozo_n", "puerta_sur", Rect2(-30.0, 62.0, 8.0, 3.0), 1.0, 5.0, "casa", true],
	["hoja_casa_pozo", "puerta_sur", Rect2(-26.7, 64.92, 1.4, 0.08), 1.0, 2.4, "puerta", false],
	["casa_pozo_ne", "puerta_sur", Rect2(-22.0, 62.0, 8.0, 3.0), 1.0, 6.0, "casa", true],
	["pozo_patio", "puerta_sur", Rect2(-18.0, 67.3, 1.4, 1.4), 1.0, 0.9, "muro", true],
	["banco_pozo", "puerta_sur", Rect2(-28.6, 68.0, 0.6, 2.6), 1.0, 0.45, "bajo", true],
	["tinajas_pozo", "puerta_sur", Rect2(-15.4, 65.2, 1.2, 1.2), 1.0, 0.8, "decor", true],
]
# Lo que la escena aclara cuando tapa a Kael (además de las cubiertas y copas): la muralla y la puerta (la cámara queda
# encima con Kael junto a ellas), las casas al sur del patio del pozo, el cobertizo al sur de la Rampa de los Carros, el
# muro al sur del Arco de los Pasajes y el tendedero de la terraza (cuerdas a 3,6 m).
const OCULTABLES := ["muralla_sur_o", "torre_puerta_o", "puerta_sur", "dintel_puerta", "torre_puerta_e", "muralla_sur_e",
	"casa_paso_o", "casa_paso_e", "cobertizo_carros", "muro_arco_s", "tendedero_terraza"]

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; «reserva_*», lugares
# reservados del plan §3; los demás, sitios de gente prevista (vecinos, niños, caballos) y de cosas.
const ANCLAS := {
	"referencia": Vector3(0.0, 0.0, 91.5),          # ante la Puerta del Sur [C]
	"rotulo": Vector3(0.0, 0.0, 81.0),              # (el rótulo del sector, sobre el patio: en la puerta quedaba pegado a la cámara)
	"inicio": Vector3(0.0, 0.0, 86.0),
	"reserva_rastreadores_caravanas": Vector3(25.0, 0.0, 85.0),   # [P] bajo el toldo de lonas
	# gente prevista
	"aldric": Vector3(3.0, 0.0, 90.6),              # Aldric [C], de guardia junto a la puerta
	"guardia_soportal": Vector3(6.2, 0.0, 66.2),    # un guardia [C mundo vivo] ante el libro de guardia
	"brena": Vector3(22.6, 0.0, 75.0),              # Brena [P], la encargada del establo
	"avena": Vector3(20.4, 0.0, 75.8),              # Avena [P], la yegua, atada ante el establo
	"porteador": Vector3(35.0, 0.0, 80.0),          # Tobías [P], el porteador, entre el carro y la pila
	"arriero_muelle": Vector3(36.0, 1.0, 67.6),     # un mozo de portes [P] en el muelle
	"ninos_pozo": Vector3(-24.0, 1.0, 69.0),        # niños jugando en el patio del pozo
	"vecina_pozo": Vector3(-19.6, 1.0, 68.0),       # una vecina sacando agua
	"ninos_terraza": Vector3(-16.0, 1.0, 84.0),     # niños en la Terraza del Arco
	"vecino_terraza": Vector3(-18.5, 1.0, 89.6),    # un vecino en el banco de la terraza
	"viajero_pilon": Vector3(-4.0, 0.0, 89.0),      # un viajero bebiendo en el pilón
	# cosas
	"libro_guardia": Vector3(6.6, 0.0, 66.25),      # el libro de guardia [C] (nota)
	"cofre_requisados": Vector3(15.25, 0.0, 77.3),  # los requisados [C oak_cofre_requisados]
	"pilon": Vector3(-5.5, 0.0, 88.6),
	"pozo_patio": Vector3(-17.3, 1.0, 69.4),
	"abrevadero": Vector3(19.6, 0.0, 77.0),
	# umbrales
	"puerta_establo": Vector3(24.0, 0.0, 73.05),
	"puerta_guardia": Vector3(7.95, 0.0, 72.0),
	"puerta_casa_mayor": Vector3(-4.95, 0.0, 68.0),
	"puerta_almacen": Vector3(36.6, 1.0, 66.05),
	"puerta_casa_terraza": Vector3(-26.0, 1.0, 79.05),
	"puerta_casa_pozo": Vector3(-26.0, 1.0, 65.05),
	# nodos del grafo
	"n_mayor_n": Vector3(0.0, 0.0, 63.0),
	"n_mayor": Vector3(0.0, 0.0, 72.0),
	"n_soportal": Vector3(6.0, 0.0, 72.0),
	"n_callejon_e": Vector3(0.0, 0.0, 77.0),
	"n_explanada": Vector3(0.0, 0.0, 86.0),
	"n_puerta": Vector3(0.0, 0.0, 91.0),
	"n_guardia": Vector3(13.0, 0.0, 79.0),
	"n_caravanas": Vector3(29.0, 0.0, 79.0),
	"n_establo": Vector3(24.0, 0.0, 75.0),
	"n_lonas": Vector3(26.5, 0.0, 85.0),
	"n_carros": Vector3(43.0, 0.0, 79.0),
	"n_muelle_pie": Vector3(36.5, 0.0, 75.0),
	"n_muelle": Vector3(36.5, 1.0, 68.0),
	"n_callejon": Vector3(-12.0, 1.0, 77.0),
	"n_terraza": Vector3(-18.0, 1.0, 86.5),
	"n_arco": Vector3(-29.5, 1.0, 81.5),
	"n_paso_s": Vector3(-21.5, 1.0, 80.0),
	"n_pozo": Vector3(-21.5, 1.0, 68.0),
}

# Puertas previstas (los interiores NO existen: la escena dice «Aún no se puede entrar (en obras).»). Formato del barrio:
# fuera (donde aparece Kael y el centro del botón), mira (rotation.y al salir: 0 norte, PI sur, PI/2 oeste, −PI/2 este),
# radio del botón, texto, ancla del umbral.
const PUERTAS := {
	"establo": {"fuera": Vector3(24.0, 0.0, 74.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el establo",
		"ancla": "puerta_establo", "nombre": "Establo"},
	"cuerpo_guardia": {"fuera": Vector3(6.6, 0.0, 72.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en el cuerpo de guardia",
		"ancla": "puerta_guardia", "nombre": "Cuerpo de guardia"},
	"casa_mayor": {"fuera": Vector3(-3.6, 0.0, 68.0), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_mayor", "nombre": "Casa"},
	"almacen_portes": {"fuera": Vector3(36.6, 1.0, 67.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_almacen", "nombre": "Almacén de portes"},
	"casa_terraza": {"fuera": Vector3(-26.0, 1.0, 80.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_terraza", "nombre": "Casa"},
	"casa_pozo": {"fuera": Vector3(-26.0, 1.0, 66.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_pozo", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros). Sus extremos en los bordes (n_mayor_n, n_carros, n_arco)
# enlazan con el grafo global del plano (c_calle_mayor, c_rampa_carros, c_arco_pasajes).
const GRAFO := {
	"n_mayor_n": ["n_mayor"],
	"n_mayor": ["n_mayor_n", "n_soportal", "n_callejon_e"],
	"n_soportal": ["n_mayor"],
	"n_callejon_e": ["n_mayor", "n_explanada", "n_callejon"],
	"n_explanada": ["n_callejon_e", "n_puerta", "n_guardia", "n_terraza"],
	"n_puerta": ["n_explanada"],
	"n_guardia": ["n_explanada", "n_caravanas"],
	"n_caravanas": ["n_guardia", "n_establo", "n_lonas", "n_carros", "n_muelle_pie"],
	"n_establo": ["n_caravanas"],
	"n_lonas": ["n_caravanas"],
	"n_carros": ["n_caravanas"],
	"n_muelle_pie": ["n_caravanas", "n_muelle"],
	"n_muelle": ["n_muelle_pie"],
	"n_callejon": ["n_callejon_e", "n_terraza"],
	"n_terraza": ["n_explanada", "n_callejon", "n_arco", "n_paso_s"],
	"n_arco": ["n_terraza"],
	"n_paso_s": ["n_terraza", "n_pozo"],
	"n_pozo": ["n_paso_s"],
}

# ---------------------------------------------------------------------------------------------------- cámara
# Sin zonas: el foco es Kael (la cámara, al sur, sobre la explanada y el patio; junto a la muralla la escena la aclara).
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
