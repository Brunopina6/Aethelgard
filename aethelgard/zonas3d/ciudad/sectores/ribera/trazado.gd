extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 8, LA RIBERA BAJA. Trazado MÍNIMO de M0 (suelos principales a su
# cota y bordes de conexión); lo llena el agente de maqueta B (sectores 3 y 8): la ronda en alto [C] hasta la Torre de la
# Campana, la acequia y el molino [P], los lavaderos. Bordes acordados (plano.gd, CONEXIONES): Rampa de los Carros (x 45,
# cota 0) y Escalera del Molino (z 55, cota 3).
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "ribera"

const SUELOS := [
	["ribera", Rect2(45.0, 76.0, 5.0, 6.0), "", 0.0, 0.0],              # entrada de los carros (borde x 45, cota 0)
	["ribera", Rect2(50.0, 76.0, 10.0, 6.0), "x", 0.0, -2.0],           # Rampa de los Carros (20 %)
	["ribera", Rect2(60.0, 70.0, 40.0, 20.0), "", -2.0, -2.0],          # patio de los almacenes
	["ribera", Rect2(60.0, 55.0, 3.0, 2.0), "", 3.0, 3.0],              # Escalera del Molino, arriba (borde z 55, cota 3)
	["ribera", Rect2(60.0, 57.0, 3.0, 13.0), "z", 3.0, -2.0],           # Escalera del Molino (38 %)
]

const BLOQUES := [
	["casa_rampa_n", "ribera", Rect2(46.0, 62.0, 14.0, 14.0), 0.0, 6.0, "casa", true],
	["almacen_n", "ribera", Rect2(66.0, 58.0, 30.0, 12.0), -2.0, 7.0, "casa", true],
	["torre_campana", "ribera", Rect2(100.0, 58.0, 8.0, 8.0), -2.0, 24.0, "muro", true],
	["muralla_este_s", "ribera", Rect2(107.0, 55.0, 3.0, 40.0), -2.0, 10.0, "muro", true],
	["casa_rampa_s", "ribera", Rect2(46.0, 84.0, 14.0, 8.0), 0.0, 5.0, "casa", true],
	["muralla_sur_e2", "ribera", Rect2(45.0, 93.0, 65.0, 2.5), -2.0, 10.0, "muro", true],
	["acequia", "ribera", Rect2(60.0, 90.6, 40.0, 1.4), -2.6, 0.4, "decor", false],
]
const OCULTABLES := ["casa_rampa_s", "muralla_sur_e2"]

const ANCLAS := {
	"referencia": Vector3(96.0, -2.0, 72.0),        # bajo la Torre de la Campana [C]
	"reserva_rastreadores_almacen": Vector3(92.0, -2.0, 86.0),
	"puerta_almacen": Vector3(80.0, -2.0, 70.0),
	"n_carros": Vector3(46.0, 0.0, 79.0),
	"n_patio": Vector3(80.0, -2.0, 80.0),
	"n_molino": Vector3(61.5, 3.0, 56.0),
}

const PUERTAS := {
	"almacen": {"fuera": Vector3(80.0, -2.0, 71.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el almacén",
		"ancla": "puerta_almacen", "nombre": "Almacén"},
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
