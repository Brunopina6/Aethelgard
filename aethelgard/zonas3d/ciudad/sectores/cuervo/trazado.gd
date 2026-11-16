extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 6, PATIO DEL CUERVO. Maqueta del agente C (sectores 5 y 6) sobre el
# trazado mínimo de M0. Plano: docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2-§3; contrato: docs/v12/CIUDAD_OAKHAVEN.md; lo hecho
# aquí: docs/v12/ciudad_sectores/C.md. Bordes acordados (plano.gd, CONEXIONES; no se cambian aquí): Calle del Cuervo
# (x −30, z 20..26, cota 2), Escaleras de las Terrazas (z −5, x −62..−58, cota 3) y Pasaje de las Velas (z 50,
# x −70..−68, cota 2).
#
# Coordenadas de CIUDAD (x este, z sur, y arriba). Todo es PROPUESTA [P] salvo lo marcado [C] (ciudades/oakhaven.gd: la
# Taberna del Cuervo Oxidado, «la posada», con su «letrero de hierro con un cuervo que chirría»; el Patio del Cuervo con
# sus barriles, el favor de la posadera, y su mesa de juego, oak_mesa_parejas, «Jugar a las parejas»; la posadera a la
# puerta; la Calle del Cuervo de la plaza al barrio; los demás juegos de taberna, ciudades/taberna_juegos.gd, DENTRO).
#   - ARRIBA (cota 3): la Taberna del Cuervo Oxidado [C] al norte, con su letrero colgado de un brazo sobre la puerta
#     (de cara al sur, a la cámara), un hastial y una chimenea que asoman sobre los tejados vecinos, y un porche con
#     mesas (la terraza); delante, el Patio del Cuervo (plaza de encuentro, patio y porche ≈ 600 m²): fuente, árbol con
#     bancos, los barriles [C], la mesa de parejas [C] y, al suroeste, el sitio de la Feria de los Oficios [P]
#     (FERIA_PATIO: un carro y unos bancos corridos que la Feria sustituye). Al oeste, el Corral de la Posada [P] (sin
#     salida: cuadra, abrevadero, caballos); al noreste, el Pie de las Escaleras [P] (arranque de las Escaleras de las
#     Terrazas, con su arco y una fuente), ensanche aparte: una casa estrecha lo separa del porche.
#   - CALLEJÓN DE SERVICIO: el Callejón del Tonel [P] baja del Pie de las Escaleras a la Calle del Cuervo por detrás del
#     patio, con el almacén de la posada [P] y un paso bajo casa. NO es un atajo (es unos metros más largo que cruzar el
#     patio): es el camino de los barriles, del almacén a la calle y al patio [P, para la fase de vida].
#   - LA CALLE DEL CUERVO [C] baja de 3 a 2 hacia la plaza, con un soportal [P] (pilares y planta encima) y la tonelería
#     [P] en su lado norte.
#   - ABAJO (cota 2): el Corro de los Niños [P] (sitio de juego, rayuela, árbol, un tronco de banco), separado del patio
#     por un pretil y un muro de tierra con una escalinata; de él sale el Pasaje de las Velas hacia los Pasajes Viejos y
#     el Callejón del Corro [P], que sube a la boca de la Calle del Cuervo (otro bucle), con una puerta en su recodo.
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "cuervo"

# ---------------------------------------------------------------------------------------------------- suelo
# La Calle del Cuervo es una rampa en x de 3 (x −50) a 2 (x −32): h(x) = 3 − (x + 50)/18. El soportal sigue la MISMA
# pendiente (sus cotas son h(−48) y h(−36)).
const SUELOS := [
	["cuervo", Rect2(-32.0, 20.0, 2.0, 6.0), "", 2.0, 2.0],              # 0 Calle del Cuervo, remate (borde x −30, cota 2)
	["cuervo", Rect2(-50.0, 20.0, 18.0, 6.0), "x", 3.0, 2.0],            # 1 Calle del Cuervo [C]: baja 1 m hacia la plaza
	["cuervo", Rect2(-48.0, 18.0, 12.0, 2.0), "x", 3.0 - 2.0 / 18.0, 3.0 - 14.0 / 18.0],   # 2 el soportal [P]
	["cuervo", Rect2(-58.0, 20.0, 8.0, 6.0), "", 3.0, 3.0],              # 3 boca de la calle, ante el patio
	["cuervo", Rect2(-88.0, 9.0, 30.0, 18.0), "", 3.0, 3.0],             # 4 Patio del Cuervo [C] (plaza de encuentro)
	["cuervo", Rect2(-88.0, 5.0, 20.0, 4.0), "", 3.0, 3.0],              # 5 terraza de la taberna (porche)
	["cuervo", Rect2(-68.0, -5.0, 10.0, 14.0), "", 3.0, 3.0],            # 6 Pie de las Escaleras [P] (borde z −5, cota 3)
	["cuervo", Rect2(-97.0, -1.0, 9.0, 10.0), "", 3.0, 3.0],             # 7 Corral de la Posada [P], sin salida
	["cuervo", Rect2(-80.0, 27.0, 6.0, 3.0), "z", 3.0, 2.0],             # 8 escalinata del corro (33 %)
	["cuervo", Rect2(-86.0, 30.0, 22.0, 9.0), "", 2.0, 2.0],             # 9 Corro de los Niños [P]
	["cuervo", Rect2(-70.0, 39.0, 2.0, 11.0), "", 2.0, 2.0],             # 10 Pasaje de las Velas (borde z 50, cota 2)
	["cuervo", Rect2(-58.0, -2.0, 10.0, 2.5), "", 3.0, 3.0],             # 11 Callejón del Tonel [P], tramo este-oeste
	["cuervo", Rect2(-50.0, 0.5, 2.0, 19.5), "", 3.0, 3.0],              # 12 Callejón del Tonel, tramo norte-sur (2 m)
	["cuervo", Rect2(-58.0, 26.0, 2.0, 7.0), "z", 3.0, 2.0],             # 13 Callejón del Corro [P]: baja (14 %)
	["cuervo", Rect2(-64.0, 33.0, 8.0, 2.0), "", 2.0, 2.0],              # 14 Callejón del Corro, al corro
]

# ---------------------------------------------------------------------------------------------------- bloques
const BLOQUES := [
	["muralla_oeste", "cuervo", Rect2(-100.0, -5.0, 3.0, 55.0), 0.0, 10.0, "muro", true],
	# la Taberna del Cuervo Oxidado [C]: el letrero de hierro [C] cuelga de un brazo sobre la puerta, de cara al sur (la
	# cámara mira al norte: de canto no se veía); un hastial [P] y la chimenea asoman 3-4 m sobre los tejados vecinos
	# (casa_tonel_n 11, casa_barriles 10) para que la taberna se reconozca desde la boca de la Calle del Cuervo
	["taberna_cuervo", "cuervo", Rect2(-88.0, -5.0, 20.0, 10.0), 3.0, 8.5, "casa", true],
	["hastial_taberna", "cuervo", Rect2(-81.0, -3.0, 6.0, 6.0), 11.5, 2.5, "casa", true],
	["chimenea_taberna", "cuervo", Rect2(-72.2, -3.7, 1.6, 1.6), 11.5, 3.5, "decor", true],
	["hoja_taberna", "cuervo", Rect2(-78.7, 5.0, 1.4, 0.08), 3.0, 2.4, "puerta", false],
	["brazo_letrero", "cuervo", Rect2(-76.25, 5.0, 0.1, 0.95), 6.9, 0.1, "decor", false],
	["letrero_cuervo", "cuervo", Rect2(-76.9, 5.85, 1.4, 0.1), 6.0, 0.9, "decor", false],
	["porche_taberna", "cuervo", Rect2(-87.5, 5.0, 7.0, 3.0), 5.6, 0.4, "cubierta", false],
	["poste_porche_1", "cuervo", Rect2(-87.5, 7.7, 0.3, 0.3), 3.0, 2.6, "muro", true],
	["poste_porche_2", "cuervo", Rect2(-80.8, 7.7, 0.3, 0.3), 3.0, 2.6, "muro", true],
	["mesa_terraza_1", "cuervo", Rect2(-86.5, 5.6, 1.2, 1.0), 3.0, 0.8, "bajo", true],
	["mesa_terraza_2", "cuervo", Rect2(-83.5, 5.6, 1.2, 1.0), 3.0, 0.8, "bajo", true],
	# Corral de la Posada [P]: cuadra y abrevadero
	["cuadra", "cuervo", Rect2(-97.0, -5.0, 9.0, 4.0), 3.0, 4.5, "casa", true],
	["hoja_cuadra", "cuervo", Rect2(-92.7, -1.0, 1.4, 0.08), 3.0, 2.6, "puerta", false],
	["abrevadero_corral", "cuervo", Rect2(-95.5, 3.0, 0.8, 3.0), 3.0, 0.7, "bajo", true],
	# el Patio del Cuervo: fuente, árbol con bancos, barriles [C], la mesa de parejas [C]; la Feria [P] en FERIA_PATIO
	# (los caños, 0,5 m: finos de verdad; con 0,6 el redondeo de Rect2 los dejaba en 0,6000001 y tapaban a Kael)
	["casa_patio_o", "cuervo", Rect2(-97.0, 9.0, 9.0, 18.0), 3.0, 7.0, "casa", true],
	["hoja_casa_patio", "cuervo", Rect2(-88.0, 17.3, 0.08, 1.4), 3.0, 2.4, "puerta", false],
	["fuente_cuervo", "cuervo", Rect2(-84.0, 13.0, 3.0, 3.0), 3.0, 0.7, "bajo", true],
	["fuente_cuervo_cano", "cuervo", Rect2(-82.75, 14.25, 0.5, 0.5), 3.7, 1.6, "decor", true],
	["arbol_patio", "cuervo", Rect2(-63.0, 14.0, 0.55, 0.55), 3.0, 3.2, "arbol", true],
	["copa_patio", "cuervo", Rect2(-66.7, 10.3, 8.0, 8.0), 5.8, 3.5, "copa", false],
	["banco_patio_1", "cuervo", Rect2(-65.2, 17.2, 2.4, 0.5), 3.0, 0.45, "bajo", true],
	["banco_patio_2", "cuervo", Rect2(-86.0, 21.0, 0.5, 2.4), 3.0, 0.45, "bajo", true],
	["banco_patio_3", "cuervo", Rect2(-60.2, 13.0, 0.5, 2.4), 3.0, 0.45, "bajo", true],
	["barriles_patio", "cuervo", Rect2(-60.4, 9.6, 1.8, 1.2), 3.0, 1.1, "bajo", true],
	# la mesa de juego del patio [C] (oak_mesa_parejas, «Jugar a las parejas», taberna_parejas.gd)
	["mesa_parejas", "cuervo", Rect2(-70.5, 11.5, 1.6, 1.0), 3.0, 0.8, "bajo", true],
	# la vida de cada día en el sitio de la Feria [P]: el carro de la posada y unos bancos corridos (la Feria los sustituye)
	["carro_posada", "cuervo", Rect2(-82.6, 18.0, 2.6, 1.4), 3.0, 1.2, "bajo", true],
	["bancos_feria", "cuervo", Rect2(-79.0, 21.4, 3.0, 0.5), 3.0, 0.45, "bajo", true],
	# el desnivel al corro: pretil arriba, muro de tierra con la tapa a la cota del patio
	["pretil_corro_o", "cuervo", Rect2(-88.0, 26.6, 8.0, 0.4), 3.0, 0.9, "muro", true],
	["pretil_corro_e", "cuervo", Rect2(-74.0, 26.6, 16.0, 0.4), 3.0, 0.9, "muro", true],
	["terreno_corro_o", "cuervo", Rect2(-86.0, 27.0, 6.0, 3.0), 2.0, 1.0, "terreno", true],
	["terreno_corro_e", "cuervo", Rect2(-74.0, 27.0, 16.0, 3.0), 2.0, 1.0, "terreno", true],
	# el Corro de los Niños [P]
	["casa_corro_o", "cuervo", Rect2(-97.0, 27.0, 11.0, 12.0), 2.0, 6.5, "casa", true],
	["casas_corro_so", "cuervo", Rect2(-97.0, 39.0, 27.0, 11.0), 2.0, 6.0, "casa", true],
	["casas_corro_se", "cuervo", Rect2(-68.0, 39.0, 12.0, 11.0), 2.0, 5.5, "casa", true],
	["casa_callejon_corro", "cuervo", Rect2(-64.0, 35.0, 8.0, 4.0), 2.0, 5.0, "casa", true],
	["casa_corro_ne", "cuervo", Rect2(-64.0, 30.0, 6.0, 3.0), 2.0, 4.5, "casa", true],
	# la casa del oeste abre al corro por su cara ESTE (la cámara la ve; la de norte no se veía)
	["hoja_corro", "cuervo", Rect2(-86.0, 35.8, 0.08, 1.4), 2.0, 2.3, "puerta", false],
	# la puerta del Pasaje de las Velas (cara oeste, de canto para la cámara): un tejadillo saliente la señala desde arriba
	["hoja_pasaje", "cuervo", Rect2(-68.08, 44.3, 0.08, 1.4), 2.0, 2.3, "puerta", false],
	["tejadillo_pasaje", "cuervo", Rect2(-68.8, 44.0, 0.8, 2.0), 4.6, 0.25, "cubierta", false],
	["arbol_corro", "cuervo", Rect2(-73.0, 36.0, 0.55, 0.55), 2.0, 2.6, "arbol", true],
	["copa_corro", "cuervo", Rect2(-76.0, 33.0, 6.5, 6.5), 4.6, 3.0, "copa", false],
	["tronco_corro", "cuervo", Rect2(-77.0, 37.4, 3.0, 0.6), 2.0, 0.45, "bajo", true],
	["rayuela_corro", "cuervo", Rect2(-84.0, 31.0, 1.0, 4.0), 2.0, 0.04, "decor", false],
	# el Pie de las Escaleras [P]: arco sobre el arranque, fuente; una casa estrecha lo separa del porche (ensanche aparte)
	["arco_escaleras", "cuervo", Rect2(-62.6, -5.0, 4.6, 1.2), 6.3, 0.9, "cubierta", false],
	["pilar_arco_escaleras", "cuervo", Rect2(-62.6, -4.6, 0.55, 0.55), 3.0, 3.3, "muro", true],
	["fuente_escaleras", "cuervo", Rect2(-66.5, 0.0, 2.0, 2.0), 3.0, 0.7, "bajo", true],
	["fuente_escaleras_cano", "cuervo", Rect2(-65.75, 0.75, 0.5, 0.5), 3.7, 1.3, "decor", true],
	["casa_pie", "cuervo", Rect2(-68.0, 5.0, 4.0, 4.0), 3.0, 5.5, "casa", true],
	["hoja_pie", "cuervo", Rect2(-66.7, 9.0, 1.4, 0.08), 3.0, 2.4, "puerta", false],
	["casa_escalera_e", "cuervo", Rect2(-58.0, -5.0, 10.0, 3.0), 3.0, 6.0, "casa", true],
	["hoja_escalera", "cuervo", Rect2(-53.7, -2.0, 1.4, 0.08), 3.0, 2.4, "puerta", false],
	# el Callejón del Tonel [P], de servicio: el almacén de la posada (su puerta, de canto para la cámara, lleva un
	# tejadillo saliente), casas a los lados y un paso bajo casa
	["casa_barriles", "cuervo", Rect2(-58.0, 0.5, 8.0, 19.5), 3.0, 7.0, "casa", true],
	["hoja_almacen", "cuervo", Rect2(-50.0, 3.3, 0.08, 1.4), 3.0, 2.4, "puerta", false],
	["tejadillo_almacen", "cuervo", Rect2(-50.0, 3.0, 0.8, 2.0), 5.6, 0.25, "cubierta", false],
	["paso_tonel", "cuervo", Rect2(-50.0, 8.0, 2.0, 4.0), 5.8, 3.2, "cubierta", false],
	["casa_tonel_n", "cuervo", Rect2(-48.0, -5.0, 18.0, 13.0), 3.0, 8.0, "casa", true],
	# la Calle del Cuervo: el soportal (pilares que siguen la rampa y planta encima), la tonelería, un banco
	["casa_soportal", "cuervo", Rect2(-48.0, 8.0, 18.0, 10.0), 2.5, 7.5, "casa", true],
	["hoja_toneleria", "cuervo", Rect2(-42.7, 18.0, 1.4, 0.08), 2.55, 2.3, "puerta", false],
	["casa_soportal_e", "cuervo", Rect2(-36.0, 18.0, 6.0, 2.0), 2.0, 8.0, "casa", true],
	["cubierta_soportal", "cuervo", Rect2(-48.0, 18.0, 12.0, 2.0), 5.6, 3.5, "cubierta", false],
	["pilar_soportal_1", "cuervo", Rect2(-47.6, 19.6, 0.4, 0.4), 3.0 - 2.8 / 18.0, 2.6 + 2.8 / 18.0, "muro", true],
	["pilar_soportal_2", "cuervo", Rect2(-44.0, 19.6, 0.4, 0.4), 3.0 - 6.4 / 18.0, 2.6 + 6.4 / 18.0, "muro", true],
	["pilar_soportal_3", "cuervo", Rect2(-40.4, 19.6, 0.4, 0.4), 3.0 - 10.0 / 18.0, 2.6 + 10.0 / 18.0, "muro", true],
	["pilar_soportal_4", "cuervo", Rect2(-36.8, 19.6, 0.4, 0.4), 3.0 - 13.6 / 18.0, 2.6 + 13.6 / 18.0, "muro", true],
	["puesto_tonelero", "cuervo", Rect2(-38.6, 18.2, 1.6, 0.8), 2.25, 1.0, "bajo", true],
	["banco_calle", "cuervo", Rect2(-44.0, 25.3, 2.4, 0.5), 2.53, 0.45, "bajo", true],
	["casa_calle_s1", "cuervo", Rect2(-56.0, 26.0, 10.0, 12.0), 2.5, 6.5, "casa", true],
	# su puerta, en la cara oeste, al recodo del Callejón del Corro (al fondo del tramo este-oeste: la cámara la ve)
	["hoja_calle_s", "cuervo", Rect2(-56.08, 33.3, 0.08, 1.4), 2.0, 2.3, "puerta", false],
	["casa_calle_s2", "cuervo", Rect2(-46.0, 26.0, 9.0, 12.0), 2.2, 8.0, "casa", true],
	["casa_calle_s3", "cuervo", Rect2(-37.0, 26.0, 7.0, 12.0), 2.0, 6.0, "casa", true],
	["casas_cuervo_s", "cuervo", Rect2(-56.0, 38.0, 26.0, 12.0), 2.0, 5.5, "casa", true],
]
# Las casas que la escena aclara cuando tapan a Kael (además de las cubiertas y las copas): las que quedan al SUR de lo
# andable (la cámara mira desde el sur). Las dice prueba_ciudad_plano (sección 8), que mira cada metro; repasadas casilla a
# casilla (0,25 m): casa_corro_ne tapa a Kael pegado al pretil del patio (z 26,3) y casa_pie, desde el Pie de las Escaleras;
# el hastial y la chimenea de la taberna, desde la terraza baja de las Terrazas (al norte).
const OCULTABLES := ["casa_patio_o", "casa_barriles", "casa_calle_s1", "casa_calle_s2", "casa_calle_s3", "casa_corro_o",
	"casas_corro_so", "casas_corro_se", "casa_callejon_corro", "casa_corro_ne", "casa_pie", "hastial_taberna",
	"chimenea_taberna"]

# El sitio de la Feria de los Oficios [P] en el patio (plan §3: la celebración): un área, no un punto, que deja libres el
# paso de 3 m a la escalinata del corro (z 23,5..26,6) y el centro del patio (el nodo n_patio, en −68; 20). Contiene el
# ancla global reserva_feria_patio (−74; 22). El carro y los bancos corridos de dentro son de cada día: la Feria los quita.
const FERIA_PATIO := Rect2(-84.0, 16.5, 12.0, 7.0)

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; el resto, sitios de vida.
const ANCLAS := {
	"referencia": Vector3(-78.0, 3.0, 6.4),         # ante la Taberna del Cuervo Oxidado [C], bajo su letrero
	"reserva_feria_patio": Vector3(-74.0, 3.0, 22.0),   # [P] Feria de los Oficios: la celebración (dentro de FERIA_PATIO)
	"posadera": Vector3(-76.4, 3.0, 6.6),           # la posadera [C], a la puerta
	"parroquianos": Vector3(-85.0, 3.0, 7.2),       # en las mesas del porche [P]
	"barriles": Vector3(-61.5, 3.0, 10.2),          # los barriles del patio [C] (favor de la posadera)
	"mesa_parejas": Vector3(-69.7, 3.0, 13.2),      # la mesa de juego [C] (oak_mesa_parejas, «Jugar a las parejas»)
	"fuente_patio": Vector3(-82.5, 3.0, 17.0),      # la fuente del patio [P]
	"ninos_patio": Vector3(-70.0, 3.0, 25.0),       # niños jugando [P], junto al pretil (fuera del sitio de la Feria)
	"mozo_almacen": Vector3(-49.0, 3.0, 6.0),       # el mozo sacando barriles del almacén [P] (callejón de servicio)
	"ninos_corro": Vector3(-82.0, 2.0, 34.0),       # niños jugando a la rayuela [P]
	"caballo_1": Vector3(-93.5, 3.0, 3.5),          # caballos en el corral de la posada [P]
	"caballo_2": Vector3(-93.5, 3.0, 6.5),
	"mozo_cuadra": Vector3(-91.0, 3.0, 4.5),        # el mozo de la cuadra trabajando [P]
	"tonelero": Vector3(-39.8, 2.433333, 19.0),     # el tonelero, bajo el soportal [P]
	"fuente_escaleras": Vector3(-65.5, 3.0, 2.6),   # la fuente del Pie de las Escaleras [P]
	"puerta_taberna": Vector3(-78.0, 3.0, 5.0),
	"puerta_cuadra": Vector3(-92.0, 3.0, -0.95),
	"puerta_casa_patio": Vector3(-87.95, 3.0, 18.0),
	"puerta_toneleria": Vector3(-42.0, 2.555556, 18.05),
	"puerta_calle_s": Vector3(-56.05, 2.0, 34.0),
	"puerta_corro": Vector3(-85.95, 2.0, 36.5),
	"puerta_pie": Vector3(-66.0, 3.0, 9.05),
	"puerta_escalera": Vector3(-53.0, 3.0, -1.95),
	"puerta_almacen": Vector3(-49.95, 3.0, 4.0),
	"puerta_pasaje": Vector3(-68.05, 2.0, 45.0),
	"n_terrazas": Vector3(-60.0, 3.0, -4.0),
	"n_pie_e": Vector3(-60.0, 3.0, -0.75),
	"n_pie": Vector3(-61.5, 3.0, 7.5),
	"n_lane_ne": Vector3(-49.0, 3.0, -0.75),
	"n_lane_s": Vector3(-49.0, 2.944444, 23.0),
	"n_cuervo_e": Vector3(-31.0, 2.0, 23.0),
	"n_boca": Vector3(-57.0, 3.0, 23.0),
	"n_patio": Vector3(-68.0, 3.0, 20.0),           # fuera del sitio de la Feria (no corta las rutas cuando se monte)
	"n_terraza": Vector3(-78.0, 3.0, 7.5),
	"n_corral": Vector3(-92.0, 3.0, 7.5),
	"n_cuadra": Vector3(-92.0, 3.0, 1.0),
	"n_escalinata": Vector3(-77.0, 2.5, 28.5),
	"n_corro": Vector3(-77.0, 2.0, 34.0),
	"n_corro_e": Vector3(-69.0, 2.0, 34.0),
	"n_corro_lane": Vector3(-57.0, 2.0, 34.0),
	"n_velas": Vector3(-69.0, 2.0, 49.5),
}

# Puertas previstas (los interiores NO existen: la escena dice «Aún no se puede entrar (en obras).»). Formato del barrio:
# fuera, mira (rotation.y al salir: 0 norte, PI sur, PI/2 oeste, −PI/2 este), radio, texto, ancla del umbral, nombre.
# Los oficios son [P].
const PUERTAS := {
	"taberna": {"fuera": Vector3(-78.0, 3.0, 6.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la taberna",
		"ancla": "puerta_taberna", "nombre": "Taberna del Cuervo Oxidado"},
	"cuadra": {"fuera": Vector3(-92.0, 3.0, 0.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la cuadra",
		"ancla": "puerta_cuadra", "nombre": "Cuadra de la posada"},
	"casa_patio": {"fuera": Vector3(-86.6, 3.0, 18.0), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_patio", "nombre": "Casa"},
	"toneleria": {"fuera": Vector3(-42.0, 2.555556, 19.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la tonelería",
		"ancla": "puerta_toneleria", "nombre": "Tonelería"},
	"casa_calle_s": {"fuera": Vector3(-57.4, 2.0, 34.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_calle_s", "nombre": "Casa"},
	"casa_corro": {"fuera": Vector3(-84.6, 2.0, 36.5), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_corro", "nombre": "Casa"},
	"casa_pie": {"fuera": Vector3(-66.0, 3.0, 10.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_pie", "nombre": "Casa"},
	"casa_escalera": {"fuera": Vector3(-53.0, 3.0, -0.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_escalera", "nombre": "Casa"},
	"casa_pasaje": {"fuera": Vector3(-69.4, 2.0, 45.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_pasaje", "nombre": "Casa"},
	"almacen": {"fuera": Vector3(-48.6, 3.0, 4.0), "mira": -PI / 2.0, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_almacen", "nombre": "Almacén de la posada"},
}

# El grafo del sector (tramos RECTOS que se andan enteros). Sus extremos en los bordes (n_cuervo_e, n_terrazas, n_velas)
# enlazan con el grafo global del plano (c_calle_cuervo, c_escaleras_terrazas, c_pasaje_velas). Bucles: patio → boca →
# Callejón del Corro → corro → escalinata → patio, y patio → Pie de las Escaleras → Callejón del Tonel → calle → boca.
const GRAFO := {
	"n_terrazas": ["n_pie_e"],
	"n_pie_e": ["n_terrazas", "n_pie", "n_lane_ne"],
	"n_pie": ["n_pie_e", "n_patio"],
	"n_lane_ne": ["n_pie_e", "n_lane_s"],
	"n_lane_s": ["n_lane_ne", "n_cuervo_e", "n_boca"],
	"n_cuervo_e": ["n_lane_s"],
	"n_boca": ["n_lane_s", "n_patio", "n_corro_lane"],
	"n_patio": ["n_boca", "n_terraza", "n_escalinata", "n_pie"],
	"n_terraza": ["n_patio", "n_corral"],
	"n_corral": ["n_terraza", "n_cuadra"],
	"n_cuadra": ["n_corral"],
	"n_escalinata": ["n_patio", "n_corro"],
	"n_corro": ["n_escalinata", "n_corro_e"],
	"n_corro_e": ["n_corro", "n_velas", "n_corro_lane"],
	"n_corro_lane": ["n_corro_e", "n_boca"],
	"n_velas": ["n_corro_e"],
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
