extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 2, PLAZA DEL TAPIZ Y GRAN MERCADO. Trazado de EJEMPLO hecho por M0
# con el nivel que se espera de cada sector (plano en docs/v12/CIUDAD_OAKHAVEN_PLAN.md §2; contrato en
# docs/v12/CIUDAD_OAKHAVEN.md). Es del agente de maqueta A (sectores 1 y 2): puede cambiar todo lo de DENTRO, pero no las
# cotas ni los anchos de sus bordes (plano.gd, CONEXIONES): Calle Mayor (z 62, cota 0), Calle del Árbol (z −15, cota 4),
# Calle del Cuervo (x −30, cota 2), Calle del Mercado (x 45, cota 3) y Paso Cubierto de la Botica (x −30, cota 2).
#
# Coordenadas de CIUDAD (x este, z sur, y arriba; origen en el centro de la fuente). Lo que hay [P] salvo lo marcado [C].
#   - Plaza ALTA (cota 4): la fuente de la Plaza del Tapiz [C] en el centro, con su pilón; la tienda [C] al este; al
#     norte, el pie de la Calle del Árbol hacia el Barrio Alto.
#   - ESCALINATA (4 → 2) de 20 m de ancho, con pretiles a los lados.
#   - Plaza BAJA (cota 2): el mercado, con la LONJA (seis pilares y su tejado: un paso cubierto), puestos y el tablón del
#     Gremio [C] en la fachada este; salen la Calle del Cuervo al oeste y la del Mercado al este (sube a 3).
#   - Calle MAYOR (2 → 0) al sur, con un SOPORTAL [P] en su lado este (pilares y planta encima).
#   - Callejón y PASO CUBIERTO de la Botica [P]: la Botica de Selene [C] al sur de la plaza; el paso va bajo una casa
#     hasta los Pasajes Viejos (x −30).
# Cómo se lee cada lista: zonas3d/ciudad/trazado_comun.gd (formatos del barrio).

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "plaza_tapiz"

# ---------------------------------------------------------------------------------------------------- suelo
const SUELOS := [
	["plaza_tapiz", Rect2(-5.0, -15.0, 10.0, 3.0), "", 4.0, 4.0],        # pie de la Calle del Árbol (borde z −15, cota 4)
	["plaza_tapiz", Rect2(-17.0, -12.0, 34.0, 16.0), "", 4.0, 4.0],      # plaza alta 34×16, con la fuente
	["plaza_tapiz", Rect2(-10.0, 4.0, 20.0, 6.0), "z", 4.0, 2.0],        # escalinata (33 %)
	["plaza_tapiz", Rect2(-17.0, 10.0, 40.0, 20.0), "", 2.0, 2.0],       # plaza baja (el mercado) 40×20
	["plaza_tapiz", Rect2(-30.0, 20.0, 13.0, 6.0), "", 2.0, 2.0],        # Calle del Cuervo (borde x −30, cota 2)
	["plaza_tapiz", Rect2(23.0, 20.0, 20.0, 6.0), "x", 2.0, 3.0],        # Calle del Mercado: sube 1 m hacia los Oficios
	["plaza_tapiz", Rect2(43.0, 20.0, 2.0, 6.0), "", 3.0, 3.0],          # su remate llano (borde x 45, cota 3)
	["plaza_tapiz", Rect2(-4.0, 30.0, 8.0, 30.0), "z", 2.0, 0.0],        # Calle Mayor: baja 2 m hacia la Puerta del Sur
	["plaza_tapiz", Rect2(4.0, 30.0, 4.0, 30.0), "z", 2.0, 0.0],         # el soportal (la misma pendiente)
	["plaza_tapiz", Rect2(-4.0, 60.0, 8.0, 2.0), "", 0.0, 0.0],          # remate llano de la Calle Mayor (borde z 62, cota 0)
	["plaza_tapiz", Rect2(-17.0, 30.0, 3.0, 24.0), "", 2.0, 2.0],        # callejón de la Botica (norte-sur)
	["plaza_tapiz", Rect2(-30.0, 54.0, 16.0, 3.0), "", 2.0, 2.0],        # Paso Cubierto de la Botica (borde x −30, cota 2)
]

# ---------------------------------------------------------------------------------------------------- bloques
# Los pilares del soportal siguen la pendiente de la calle: base = 2 − (z − 30)/15; arriba, todos a 5,2.
const BLOQUES := [
	# la fuente [C] (el aspecto dorado es de la referencia [P])
	["fuente_pilon", "plaza_tapiz", Rect2(-3.0, -3.0, 6.0, 6.0), 4.0, 0.7, "bajo", true],
	["fuente_columna", "plaza_tapiz", Rect2(-0.6, -0.6, 1.2, 1.2), 4.7, 2.2, "decor", true],
	# la escalinata: pretiles arriba y muros de contención a los lados
	["pretil_o", "plaza_tapiz", Rect2(-17.0, 3.6, 7.0, 0.4), 4.0, 1.0, "muro", true],
	["pretil_e", "plaza_tapiz", Rect2(10.0, 3.6, 7.0, 0.4), 4.0, 1.0, "muro", true],
	["muro_escalinata_o", "plaza_tapiz", Rect2(-17.0, 4.0, 7.0, 6.0), 2.0, 2.0, "terreno", true],
	["muro_escalinata_e", "plaza_tapiz", Rect2(10.0, 4.0, 13.0, 6.0), 2.0, 2.0, "terreno", true],
	# fachadas de la plaza alta
	["casa_n_o", "plaza_tapiz", Rect2(-17.0, -15.0, 12.0, 3.0), 4.0, 7.0, "casa", true],
	["casa_n_e", "plaza_tapiz", Rect2(5.0, -15.0, 12.0, 3.0), 4.0, 7.0, "casa", true],
	["hoja_casa_plaza", "plaza_tapiz", Rect2(10.3, -12.08, 1.4, 0.08), 4.0, 2.4, "puerta", false],
	["casa_o_alta", "plaza_tapiz", Rect2(-30.0, -15.0, 13.0, 19.0), 4.0, 8.0, "casa", true],
	["tienda", "plaza_tapiz", Rect2(17.0, -15.0, 28.0, 19.0), 4.0, 8.0, "casa", true],
	["hoja_tienda", "plaza_tapiz", Rect2(16.92, -5.7, 0.08, 1.4), 4.0, 2.4, "puerta", false],
	# fachadas de la plaza baja
	["casa_o_baja", "plaza_tapiz", Rect2(-30.0, 4.0, 13.0, 16.0), 2.0, 8.0, "casa", true],
	["casa_gremio", "plaza_tapiz", Rect2(23.0, 4.0, 22.0, 16.0), 2.0, 8.0, "casa", true],
	["tablon_gremio", "plaza_tapiz", Rect2(22.6, 14.0, 0.4, 2.4), 2.0, 2.2, "decor", true],
	# la lonja: seis pilares y su tejado (cubierta: se aclara si tapa a Kael)
	["lonja_p1", "plaza_tapiz", Rect2(8.0, 13.0, 0.5, 0.5), 2.0, 4.0, "muro", true],
	["lonja_p2", "plaza_tapiz", Rect2(13.75, 13.0, 0.5, 0.5), 2.0, 4.0, "muro", true],
	["lonja_p3", "plaza_tapiz", Rect2(19.5, 13.0, 0.5, 0.5), 2.0, 4.0, "muro", true],
	["lonja_p4", "plaza_tapiz", Rect2(8.0, 24.5, 0.5, 0.5), 2.0, 4.0, "muro", true],
	["lonja_p5", "plaza_tapiz", Rect2(13.75, 24.5, 0.5, 0.5), 2.0, 4.0, "muro", true],
	["lonja_p6", "plaza_tapiz", Rect2(19.5, 24.5, 0.5, 0.5), 2.0, 4.0, "muro", true],
	["lonja_tejado", "plaza_tapiz", Rect2(7.5, 12.5, 13.0, 13.0), 6.0, 0.6, "cubierta", false],
	# puestos del mercado (sitio de la Feria de los Oficios [P])
	["puesto_1", "plaza_tapiz", Rect2(-12.0, 14.0, 2.4, 1.4), 2.0, 1.3, "bajo", true],
	["puesto_2", "plaza_tapiz", Rect2(-6.0, 22.0, 2.4, 1.4), 2.0, 1.3, "bajo", true],
	["puesto_3", "plaza_tapiz", Rect2(-13.0, 22.0, 2.4, 1.4), 2.0, 1.3, "bajo", true],
	# el sur de la plaza: casas al sur de la Calle del Cuervo, la Botica de Selene [C], el paso cubierto
	["casa_cuervo_s", "plaza_tapiz", Rect2(-30.0, 26.0, 13.0, 28.0), 2.0, 7.0, "casa", true],
	["botica", "plaza_tapiz", Rect2(-14.0, 31.0, 9.0, 13.0), 2.0, 6.5, "casa", true],
	["hoja_botica", "plaza_tapiz", Rect2(-14.08, 36.3, 0.08, 1.4), 2.0, 2.3, "puerta", false],
	["casa_mayor_so", "plaza_tapiz", Rect2(-14.0, 45.0, 9.0, 15.0), 1.0, 7.0, "casa", true],
	["casa_paso_s", "plaza_tapiz", Rect2(-30.0, 57.0, 16.0, 5.0), 2.0, 6.0, "casa", true],
	["cubierta_paso", "plaza_tapiz", Rect2(-26.0, 54.0, 12.0, 3.0), 4.8, 4.0, "cubierta", false],
	# la Calle Mayor: el soportal (pilares y planta encima) y las casas del este
	["cubierta_soportal", "plaza_tapiz", Rect2(4.0, 30.0, 4.0, 30.0), 5.2, 3.8, "cubierta", false],
	["pilar_soportal_1", "plaza_tapiz", Rect2(4.0, 33.8, 0.4, 0.4), 2.0 - 4.0 / 15.0, 3.2 + 4.0 / 15.0, "muro", true],
	["pilar_soportal_2", "plaza_tapiz", Rect2(4.0, 37.8, 0.4, 0.4), 2.0 - 8.0 / 15.0, 3.2 + 8.0 / 15.0, "muro", true],
	["pilar_soportal_3", "plaza_tapiz", Rect2(4.0, 41.8, 0.4, 0.4), 2.0 - 12.0 / 15.0, 3.2 + 12.0 / 15.0, "muro", true],
	["pilar_soportal_4", "plaza_tapiz", Rect2(4.0, 45.8, 0.4, 0.4), 2.0 - 16.0 / 15.0, 3.2 + 16.0 / 15.0, "muro", true],
	["pilar_soportal_5", "plaza_tapiz", Rect2(4.0, 49.8, 0.4, 0.4), 2.0 - 20.0 / 15.0, 3.2 + 20.0 / 15.0, "muro", true],
	["pilar_soportal_6", "plaza_tapiz", Rect2(4.0, 53.8, 0.4, 0.4), 2.0 - 24.0 / 15.0, 3.2 + 24.0 / 15.0, "muro", true],
	["pilar_soportal_7", "plaza_tapiz", Rect2(4.0, 57.8, 0.4, 0.4), 2.0 - 28.0 / 15.0, 3.2 + 28.0 / 15.0, "muro", true],
	["casa_sur_e", "plaza_tapiz", Rect2(8.0, 31.0, 15.0, 13.0), 2.0, 7.0, "casa", true],
	["casa_mercado_s", "plaza_tapiz", Rect2(23.0, 26.0, 22.0, 18.0), 2.5, 7.0, "casa", true],
	["casa_e_baja", "plaza_tapiz", Rect2(8.0, 45.0, 37.0, 17.0), 0.5, 7.0, "casa", true],
]
# Las casas que la escena aclara cuando tapan a Kael (además de las cubiertas y las copas): las que quedan al SUR de lo
# andable (la cámara mira desde el sur).
const OCULTABLES := ["casa_cuervo_s", "casa_paso_s", "botica", "casa_sur_e", "casa_mercado_s"]

# ---------------------------------------------------------------------------------------------------- anclas
# Puntos EN el suelo (la «y» la da altura()). «puerta_*» son umbrales; «n_*», nodos del grafo; «reserva_*», lugares
# reservados del plan §3.
const ANCLAS := {
	"referencia": Vector3(0.0, 4.0, -4.6),          # ante la fuente, lado norte
	"fuente_sur": Vector3(0.0, 4.0, 3.4),           # ante la fuente, lado de la escalinata
	"tablon_gremio": Vector3(21.6, 2.0, 15.2),      # ante el tablón del Gremio [C]
	"lonja": Vector3(14.0, 2.0, 19.0),              # bajo la lonja (paso cubierto)
	"soportal": Vector3(6.0, 1.0, 45.0),            # bajo el soportal
	"paso_cubierto": Vector3(-20.0, 2.0, 55.5),     # bajo la casa del Paso Cubierto
	"reserva_feria_plaza": Vector3(-8.0, 2.0, 18.0),
	"puerta_tienda": Vector3(16.95, 4.0, -5.0),
	"puerta_botica": Vector3(-14.05, 2.0, 37.0),
	"puerta_casa_plaza": Vector3(11.0, 4.0, -12.0),
	"n_pie_arbol": Vector3(0.0, 4.0, -13.5),
	"n_alta": Vector3(8.0, 4.0, 0.0),
	"n_escalinata": Vector3(0.0, 3.0, 7.0),
	"n_baja": Vector3(0.0, 2.0, 20.0),
	"n_baja_so": Vector3(-15.5, 2.0, 19.0),
	"n_cuervo": Vector3(-28.0, 2.0, 23.0),
	"n_mercado": Vector3(42.0, 2.95, 23.0),
	"n_mayor": Vector3(0.0, 1.0, 45.0),
	"n_mayor_s": Vector3(0.0, 0.0, 61.0),
	"n_callejon": Vector3(-15.5, 2.0, 42.0),
	"n_callejon_s": Vector3(-15.5, 2.0, 55.5),
	"n_paso": Vector3(-28.0, 2.0, 55.5),
}

# Puertas previstas (los interiores NO existen: la escena dice «Aún no se puede entrar (en obras).»). Formato del barrio:
# fuera (donde aparece Kael y el centro del botón), mira (rotation.y al salir: 0 norte, PI sur, PI/2 oeste, −PI/2 este),
# radio del botón, texto, ancla del umbral.
const PUERTAS := {
	"tienda": {"fuera": Vector3(15.6, 4.0, -5.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la tienda",
		"ancla": "puerta_tienda", "nombre": "Tienda"},
	"botica": {"fuera": Vector3(-15.4, 2.0, 37.0), "mira": PI / 2.0, "radio": 1.6, "texto": "Entrar en la botica",
		"ancla": "puerta_botica", "nombre": "Botica de Selene"},
	"casa_plaza": {"fuera": Vector3(11.0, 4.0, -10.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la casa",
		"ancla": "puerta_casa_plaza", "nombre": "Casa"},
}

# El grafo del sector (tramos RECTOS que se andan enteros, como en el barrio). Sus extremos en los bordes (n_pie_arbol,
# n_cuervo, n_mercado, n_mayor_s, n_paso) enlazan con el grafo global del plano (c_<conexión>).
const GRAFO := {
	"n_pie_arbol": ["n_alta"],
	"n_alta": ["n_pie_arbol", "n_escalinata"],
	"n_escalinata": ["n_alta", "n_baja"],
	"n_baja": ["n_escalinata", "n_baja_so", "n_cuervo", "n_mercado", "n_mayor"],
	"n_baja_so": ["n_baja", "n_callejon"],
	"n_cuervo": ["n_baja"],
	"n_mercado": ["n_baja"],
	"n_mayor": ["n_baja", "n_mayor_s"],
	"n_mayor_s": ["n_mayor"],
	"n_callejon": ["n_baja_so", "n_callejon_s"],
	"n_callejon_s": ["n_callejon", "n_paso"],
	"n_paso": ["n_callejon_s"],
}

# ---------------------------------------------------------------------------------------------------- cámara
# Zonas locales (modos del barrio: «x» riel de este a oeste, «eje» tramo de norte a sur, «libre»); fuera de ellas el foco
# es Kael. En el paso cubierto, un riel de este a oeste (como la calle comercial del barrio). (Un «eje» en el callejón de
# la Botica, con su atraso, hacía saltar el foco al cruzar el borde de su zona en la plaza baja: 0,71 m por 0,25 m de
# Kael; una zona debe quedar lejos de lo andable que no es suyo, o no ponerse.)
const CAMARA_ZONAS := [
	{"sector": "plaza_tapiz", "rect": Rect2(-31.0, 51.0, 19.0, 9.0), "modo": "x", "x": Vector2(-28.0, -15.5), "z_riel": 55.5},
]


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
