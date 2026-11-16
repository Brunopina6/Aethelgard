extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 5, PASAJES VIEJOS. Trazado MÍNIMO de M0 (suelos principales a su
# cota y bordes de conexión); lo llena el agente de maqueta C (sectores 5 y 6): callejones, pasos bajo casas, el Patio de
# las Velas [C], la grieta de Pip [C] (secreto: solo su sitio). Bordes acordados (plano.gd, CONEXIONES): Paso Cubierto de
# la Botica (x −30, cota 2), Pasaje de las Velas (z 50, cota 2) y Arco de los Pasajes (x −30, cota 1).
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "pasajes"

# El callejón largo baja de 2 a 1 en 23 m; el Patio de las Velas, a su lado, sigue la MISMA pendiente (sin escalón).
const SUELOS := [
	["pasajes", Rect2(-70.0, 50.0, 2.0, 4.0), "", 2.0, 2.0],            # Pasaje de las Velas (borde z 50, cota 2)
	["pasajes", Rect2(-80.0, 54.0, 50.0, 3.0), "", 2.0, 2.0],           # callejón de la Botica (borde x −30, cota 2)
	["pasajes", Rect2(-50.0, 57.0, 2.0, 23.0), "z", 2.0, 1.0],          # callejón largo
	["pasajes", Rect2(-62.0, 66.0, 12.0, 8.0), "z", 2.0 - 9.0 / 23.0, 2.0 - 17.0 / 23.0],   # Patio de las Velas [C]
	["pasajes", Rect2(-50.0, 80.0, 20.0, 3.0), "", 1.0, 1.0],           # hacia el Arco de los Pasajes (borde x −30, cota 1)
]

const BLOQUES := [
	["casa_velas_n", "pasajes", Rect2(-78.0, 58.0, 16.0, 7.0), 2.0, 6.0, "casa", true],
	["casa_pasaje_e", "pasajes", Rect2(-47.0, 58.0, 17.0, 21.0), 1.0, 6.0, "casa", true],
	["arco_paso", "pasajes", Rect2(-50.0, 62.0, 2.0, 3.0), 4.8, 3.0, "cubierta", false],
	["casa_arco_s", "pasajes", Rect2(-50.0, 84.0, 20.0, 9.0), 1.0, 5.0, "casa", true],
	["casa_velas_s", "pasajes", Rect2(-62.0, 75.0, 11.0, 8.0), 1.0, 5.0, "casa", true],
	["muralla_so", "pasajes", Rect2(-100.0, 93.0, 70.0, 2.5), 0.0, 8.0, "muro", true],
	["muralla_oeste_s", "pasajes", Rect2(-100.0, 50.0, 3.0, 43.0), 0.0, 10.0, "muro", true],
]
const OCULTABLES := ["casa_velas_n", "casa_pasaje_e", "casa_arco_s", "casa_velas_s"]

const ANCLAS := {
	"referencia": Vector3(-56.0, 1.4348, 70.0),     # el Patio de las Velas [C]
	"grieta_pip": Vector3(-79.0, 2.0, 55.5),        # el fondo del callejón: el sitio de la grieta de Pip [C]
	"n_velas": Vector3(-69.0, 2.0, 51.0),
	"n_botica": Vector3(-31.0, 2.0, 55.5),
	"n_largo": Vector3(-49.0, 1.5, 68.5),
	"n_arco": Vector3(-31.0, 1.0, 81.5),
}

const PUERTAS := {}
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
