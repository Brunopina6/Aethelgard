extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 6, PATIO DEL CUERVO. Trazado MÍNIMO de M0 (suelos principales a su
# cota y bordes de conexión); lo llena el agente de maqueta C (sectores 5 y 6): la Taberna del Cuervo Oxidado [C] con su
# letrero, el patio de encuentro y los juegos [C], el sitio de la Feria de los Oficios [P]. Bordes acordados (plano.gd,
# CONEXIONES): Calle del Cuervo (x −30, cota 2), Escaleras de las Terrazas (z −5, cota 3) y Pasaje de las Velas (z 50,
# cota 2).
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "cuervo"

const SUELOS := [
	["cuervo", Rect2(-32.0, 20.0, 2.0, 6.0), "", 2.0, 2.0],             # Calle del Cuervo, remate (borde x −30, cota 2)
	["cuervo", Rect2(-58.0, 20.0, 26.0, 6.0), "x", 3.0, 2.0],           # Calle del Cuervo: baja 1 m hacia la plaza
	["cuervo", Rect2(-90.0, 5.0, 32.0, 35.0), "", 3.0, 3.0],            # Patio del Cuervo
	["cuervo", Rect2(-62.0, -5.0, 4.0, 10.0), "", 3.0, 3.0],            # hacia las Escaleras de las Terrazas (borde z −5)
	["cuervo", Rect2(-70.0, 40.0, 2.0, 1.0), "", 3.0, 3.0],             # Pasaje de las Velas: arriba
	["cuervo", Rect2(-70.0, 41.0, 2.0, 8.0), "z", 3.0, 2.0],            # su bajada
	["cuervo", Rect2(-70.0, 49.0, 2.0, 1.0), "", 2.0, 2.0],             # su remate (borde z 50, cota 2)
]

const BLOQUES := [
	["taberna_cuervo", "cuervo", Rect2(-88.0, -3.0, 20.0, 8.0), 3.0, 8.0, "casa", true],
	["letrero_cuervo", "cuervo", Rect2(-79.6, 4.9, 1.2, 0.1), 6.0, 1.0, "decor", false],
	["casa_n_cuervo", "cuervo", Rect2(-56.0, 5.0, 24.0, 15.0), 2.5, 7.0, "casa", true],
	["casas_cuervo_s", "cuervo", Rect2(-56.0, 27.0, 24.0, 20.0), 2.0, 6.0, "casa", true],
	["casas_patio_so", "cuervo", Rect2(-90.0, 41.0, 19.0, 9.0), 2.5, 6.0, "casa", true],
	["casas_patio_se", "cuervo", Rect2(-67.0, 41.0, 9.0, 9.0), 2.5, 6.0, "casa", true],
	["muralla_oeste", "cuervo", Rect2(-100.0, -5.0, 3.0, 55.0), 0.0, 10.0, "muro", true],
]
const OCULTABLES := ["casas_cuervo_s", "casas_patio_so", "casas_patio_se"]

const ANCLAS := {
	"referencia": Vector3(-78.0, 3.0, 6.4),         # ante la Taberna del Cuervo Oxidado [C]
	"reserva_feria_patio": Vector3(-74.0, 3.0, 22.0),
	"puerta_taberna": Vector3(-78.0, 3.0, 5.0),
	"n_cuervo_e": Vector3(-31.0, 2.0, 23.0),
	"n_patio": Vector3(-74.0, 3.0, 22.0),
	"n_terrazas": Vector3(-60.0, 3.0, -4.0),
	"n_velas": Vector3(-69.0, 2.0, 49.5),
}

const PUERTAS := {
	"taberna": {"fuera": Vector3(-78.0, 3.0, 6.4), "mira": PI, "radio": 1.6, "texto": "Entrar en la taberna",
		"ancla": "puerta_taberna", "nombre": "Taberna del Cuervo Oxidado"},
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
