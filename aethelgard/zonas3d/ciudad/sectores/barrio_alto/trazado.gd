extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 7, BARRIO ALTO DE LAS RAÍCES [P]. Trazado MÍNIMO de M0: la Calle
# del Árbol (escalinata de tres tramos con rellanos, 4 → 12), el paseo de la Casa del Concejo [C] (cota 10), la plaza del
# Árbol (12), la rampa a la terraza de las Raíces (16) y el Árbol Milenario [C] (gigante: su copa se ve desde toda la
# ciudad y entra en la maqueta lejana). Lo llena el agente de maqueta D (sectores 4 y 7): jardines, miradores, Doña
# Encina [C], el pórtico de piedra entre las raíces [P] (en lugar del templo de vidrieras de la imagen, que NO se hace).
# Bordes acordados (plano.gd, CONEXIONES): Calle del Árbol (z −15, cota 4), Escaleras de las Terrazas arriba (x −30,
# cota 12) y Subida de la Colina (z −15, cota 10).
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "barrio_alto"

const SUELOS := [
	["barrio_alto", Rect2(-5.0, -17.0, 10.0, 2.0), "", 4.0, 4.0],       # pie de la Calle del Árbol (borde z −15, cota 4)
	["barrio_alto", Rect2(-5.0, -26.0, 10.0, 9.0), "z", 7.0, 4.0],      # tramo 1 (33 %)
	["barrio_alto", Rect2(-5.0, -30.0, 10.0, 4.0), "", 7.0, 7.0],       # rellano 1
	["barrio_alto", Rect2(-5.0, -39.0, 10.0, 9.0), "z", 10.0, 7.0],     # tramo 2
	["barrio_alto", Rect2(-5.0, -45.0, 10.0, 6.0), "", 10.0, 10.0],     # rellano 2
	["barrio_alto", Rect2(5.0, -45.0, 51.0, 6.0), "", 10.0, 10.0],      # paseo del Concejo (hasta el mirador)
	["barrio_alto", Rect2(50.0, -39.0, 4.0, 24.0), "", 10.0, 10.0],     # bajada a la Colina (borde z −15, cota 10)
	["barrio_alto", Rect2(-5.0, -51.0, 10.0, 6.0), "z", 12.0, 10.0],    # tramo 3
	["barrio_alto", Rect2(-26.0, -70.0, 52.0, 19.0), "", 12.0, 12.0],   # plaza del Árbol
	["barrio_alto", Rect2(-30.0, -64.0, 4.0, 4.0), "", 12.0, 12.0],     # hacia las Terrazas (borde x −30, cota 12)
	["barrio_alto", Rect2(-5.0, -82.0, 10.0, 12.0), "z", 16.0, 12.0],   # rampa de las Raíces (33 %)
	["barrio_alto", Rect2(-25.0, -90.0, 50.0, 8.0), "", 16.0, 16.0],    # terraza de las Raíces, al pie del Árbol
]

const BLOQUES := [
	["ladera_o", "barrio_alto", Rect2(-30.0, -45.0, 25.0, 30.0), 4.0, 6.0, "terreno", true],
	["ladera_e", "barrio_alto", Rect2(5.0, -39.0, 45.0, 24.0), 4.0, 6.0, "terreno", true],
	["banda_plaza_o", "barrio_alto", Rect2(-26.0, -51.0, 21.0, 6.0), 10.0, 2.0, "terreno", true],
	["banda_plaza_e", "barrio_alto", Rect2(5.0, -51.0, 22.0, 6.0), 10.0, 2.0, "terreno", true],
	["concejo", "barrio_alto", Rect2(27.0, -62.0, 23.0, 17.0), 10.0, 9.0, "casa", true],
	["banda_raices_o", "barrio_alto", Rect2(-26.0, -82.0, 21.0, 12.0), 12.0, 4.0, "terreno", true],
	["banda_raices_e", "barrio_alto", Rect2(5.0, -82.0, 21.0, 12.0), 12.0, 4.0, "terreno", true],
	["portico_pilar_o", "barrio_alto", Rect2(-6.5, -71.0, 1.0, 1.0), 12.0, 4.5, "muro", true],
	["portico_pilar_e", "barrio_alto", Rect2(5.5, -71.0, 1.0, 1.0), 12.0, 4.5, "muro", true],
	["portico_dintel", "barrio_alto", Rect2(-6.5, -71.0, 13.0, 1.0), 16.5, 1.0, "cubierta", false],
	["arbol_tronco", "barrio_alto", Rect2(-6.0, -92.0, 12.0, 7.0), 16.0, 16.0, "arbol", true],
	["arbol_copa", "barrio_alto", Rect2(-26.0, -112.0, 52.0, 46.0), 30.0, 20.0, "copa", false],
	["muralla_norte", "barrio_alto", Rect2(-30.0, -96.0, 90.0, 4.0), 12.0, 10.0, "muro", true],
]
const OCULTABLES := []

const ANCLAS := {
	"referencia": Vector3(0.0, 16.0, -83.0),        # al pie del Árbol Milenario [C]
	"puerta_concejo": Vector3(38.0, 10.0, -45.0),
	"mirador_concejo": Vector3(55.0, 10.0, -42.0),  # el final del paseo: la vista del valle
	"n_pie": Vector3(0.0, 4.0, -16.0),
	"n_paseo": Vector3(30.0, 10.0, -42.0),
	"n_colina": Vector3(52.0, 10.0, -16.0),
	"n_plaza": Vector3(0.0, 12.0, -60.0),
	"n_terrazas": Vector3(-29.0, 12.0, -62.0),
	"n_raices": Vector3(0.0, 16.0, -83.0),
}

const PUERTAS := {
	"concejo": {"fuera": Vector3(38.0, 10.0, -43.6), "mira": PI, "radio": 1.6, "texto": "Entrar en la Casa del Concejo",
		"ancla": "puerta_concejo", "nombre": "Casa del Concejo"},
}

const GRAFO := {}
const CAMARA_ZONAS := []


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
