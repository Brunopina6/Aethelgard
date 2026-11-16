extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 3, CALLE DE LOS OFICIOS. Trazado MÍNIMO de M0 (suelos de las calles
# principales a su cota y bordes de conexión); lo llena el agente de maqueta B (sectores 3 y 8). Bordes acordados
# (plano.gd, CONEXIONES): Calle del Mercado (x 45, cota 3), Subida de la Colina (z −15, cota 10) y Escalera del Molino
# (z 55, cota 3). Este trazado dibuja también la Colina del Crematorio [C] (plano.COLINA, fuera de lo andable): su puerta
# sigue SELLADA y no se construye nada debajo.
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "oficios"

const SUELOS := [
	["oficios", Rect2(45.0, 20.0, 5.0, 6.0), "", 3.0, 3.0],             # remate de la Calle del Mercado (borde x 45, cota 3)
	["oficios", Rect2(50.0, 20.0, 40.0, 6.0), "x", 3.0, 7.0],           # Calle de los Oficios: sube 4 m al este (10 %)
	["oficios", Rect2(90.0, 6.0, 12.0, 34.0), "", 7.0, 7.0],            # plaza de la forja
	["oficios", Rect2(60.0, 26.0, 3.0, 27.0), "z", 4.15, 3.0],          # bajada al molino
	["oficios", Rect2(60.0, 53.0, 3.0, 2.0), "", 3.0, 3.0],             # su remate (borde z 55, cota 3)
	["oficios", Rect2(92.0, -10.0, 4.0, 16.0), "z", 8.5, 7.0],          # Subida de la Colina, primer tramo
	["oficios", Rect2(92.0, -14.0, 4.0, 4.0), "", 8.5, 8.5],            # rellano al pie del crematorio
	["oficios", Rect2(54.0, -14.0, 38.0, 4.0), "x", 10.0, 8.5],         # paseo al pie de la colina
	["oficios", Rect2(50.0, -15.0, 4.0, 5.0), "", 10.0, 10.0],          # llegada al Barrio Alto (borde z −15, cota 10)
]

const BLOQUES := [
	["carretero", "oficios", Rect2(50.0, 9.0, 10.0, 11.0), 3.0, 5.0, "casa", true],
	["forja_ferro", "oficios", Rect2(62.0, 9.0, 12.0, 11.0), 4.2, 6.0, "casa", true],
	["chimenea_forja", "oficios", Rect2(70.0, 11.0, 1.4, 1.4), 10.2, 3.0, "muro", false],
	["taller_hilda", "oficios", Rect2(76.0, 9.0, 10.0, 11.0), 5.6, 6.0, "casa", true],
	["casas_oficios_so", "oficios", Rect2(50.0, 27.0, 9.0, 12.0), 3.0, 5.0, "casa", true],
	["casas_oficios_s", "oficios", Rect2(64.0, 27.0, 26.0, 12.0), 4.4, 6.0, "casa", true],
	["casa_forja_s", "oficios", Rect2(90.0, 41.0, 12.0, 13.0), 7.0, 6.0, "casa", true],
	["ladera_colina", "oficios", Rect2(54.0, -10.0, 36.0, 19.0), 3.0, 5.5, "terreno", true],
	["muralla_este", "oficios", Rect2(102.0, -15.0, 3.0, 70.0), 0.0, 14.0, "muro", true],
	["colina", "oficios", Rect2(60.0, -60.0, 45.0, 45.0), 8.0, 6.0, "terreno", true],
	["crematorio", "oficios", Rect2(75.0, -50.0, 16.0, 14.0), 14.0, 8.0, "casa", true],
	["puerta_sellada", "oficios", Rect2(81.0, -36.1, 4.0, 0.1), 14.0, 3.5, "puerta", false],
]
const OCULTABLES := ["casas_oficios_so", "casas_oficios_s", "casa_forja_s"]

const ANCLAS := {
	"referencia": Vector3(68.0, 4.8, 21.4),         # ante la forja de Maese Ferro [C pendiente]
	"reserva_piezas_taller": Vector3(55.0, 3.5, 21.4),
	"puerta_forja": Vector3(68.0, 4.8, 20.0),
	"puerta_hilda": Vector3(81.0, 6.1, 20.0),
	"puerta_carretero": Vector3(55.0, 3.5, 20.0),
	"pie_crematorio": Vector3(80.0, 8.974, -13.0),    # al pie de la colina (la puerta del crematorio sigue sellada)
	"n_mercado_e": Vector3(46.0, 3.0, 23.0),
	"n_forja": Vector3(96.0, 7.0, 23.0),
	"n_molino": Vector3(61.5, 3.0, 54.0),
	"n_colina": Vector3(52.0, 10.0, -14.0),
}

const PUERTAS := {
	"forja": {"fuera": Vector3(68.0, 4.8, 21.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la forja",
		"ancla": "puerta_forja", "nombre": "Forja"},
	"taller_hilda": {"fuera": Vector3(81.0, 6.1, 21.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el taller",
		"ancla": "puerta_hilda", "nombre": "Taller de Hilda"},
	"carretero": {"fuera": Vector3(55.0, 3.5, 21.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el taller",
		"ancla": "puerta_carretero", "nombre": "Taller del carretero"},
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
