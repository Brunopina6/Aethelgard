extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 4, LAS TERRAZAS [P] (viviendas escalonadas). Trazado MÍNIMO de M0:
# cuatro terrazas (6, 8, 10 y 12) unidas por tramos de escalera alternos, a la cota correcta, y sus bordes de conexión;
# lo llena el agente de maqueta D (sectores 4 y 7): casas con patios, glicinias, el lavadero de arriba, el patio de la
# Pieza Huérfana [P], el atajo con escalones del barrio. Bordes acordados (plano.gd, CONEXIONES): Escaleras de las
# Terrazas (z −5, cota 3) y su remate alto (x −30, cota 12).
# Entre dos terrazas, una banda de «terreno» cuya tapa es el suelo de la de arriba (las casas de cada terraza tienen su
# fachada en esa banda): así lo de abajo nunca tapa a Kael desde la cámara (al sur).
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "terrazas"

const SUELOS := [
	["terrazas", Rect2(-62.0, -6.0, 4.0, 1.0), "", 3.0, 3.0],           # pie de las escaleras (borde z −5, cota 3)
	["terrazas", Rect2(-62.0, -14.0, 4.0, 8.0), "z", 6.0, 3.0],         # escalera 1 (37,5 %)
	["terrazas", Rect2(-90.0, -22.0, 50.0, 8.0), "", 6.0, 6.0],         # terraza 1
	["terrazas", Rect2(-44.0, -30.0, 4.0, 8.0), "z", 8.0, 6.0],         # escalera 2
	["terrazas", Rect2(-90.0, -38.0, 50.0, 8.0), "", 8.0, 8.0],         # terraza 2
	["terrazas", Rect2(-90.0, -46.0, 4.0, 8.0), "z", 10.0, 8.0],        # escalera 3
	["terrazas", Rect2(-90.0, -54.0, 50.0, 8.0), "", 10.0, 10.0],       # terraza 3 (el patio de la Pieza Huérfana)
	["terrazas", Rect2(-44.0, -60.0, 4.0, 6.0), "z", 12.0, 10.0],       # escalera 4
	["terrazas", Rect2(-90.0, -68.0, 60.0, 8.0), "", 12.0, 12.0],       # terraza 4, el lavadero (borde x −30, cota 12)
]

const BLOQUES := [
	["base_terraza_1_o", "terrazas", Rect2(-90.0, -14.0, 28.0, 9.0), 3.0, 3.0, "terreno", true],
	["base_terraza_1_e", "terrazas", Rect2(-58.0, -14.0, 28.0, 9.0), 3.0, 3.0, "terreno", true],
	["banda_2_o", "terrazas", Rect2(-90.0, -30.0, 46.0, 8.0), 6.0, 2.0, "terreno", true],
	["banda_2_e", "terrazas", Rect2(-40.0, -30.0, 10.0, 8.0), 6.0, 2.0, "terreno", true],
	["banda_3", "terrazas", Rect2(-86.0, -46.0, 56.0, 8.0), 8.0, 2.0, "terreno", true],
	["banda_4_o", "terrazas", Rect2(-90.0, -60.0, 46.0, 6.0), 10.0, 2.0, "terreno", true],
	["banda_4_e", "terrazas", Rect2(-40.0, -60.0, 10.0, 6.0), 10.0, 2.0, "terreno", true],
	["casas_lavadero", "terrazas", Rect2(-90.0, -80.0, 60.0, 12.0), 12.0, 6.0, "casa", true],
	["lavadero", "terrazas", Rect2(-62.0, -67.5, 4.0, 2.0), 12.0, 0.8, "bajo", true],
	["muralla_oeste_n", "terrazas", Rect2(-100.0, -92.0, 3.0, 87.0), 0.0, 18.0, "muro", true],
]
const OCULTABLES := []

const ANCLAS := {
	"referencia": Vector3(-60.0, 12.0, -64.0),      # el lavadero de la terraza alta [P]
	"reserva_piezas_patio": Vector3(-80.0, 10.0, -50.0),
	"n_pie": Vector3(-60.0, 3.0, -5.5),
	"n_t1": Vector3(-60.0, 6.0, -18.0),
	"n_t2": Vector3(-60.0, 8.0, -34.0),
	"n_t3": Vector3(-60.0, 10.0, -50.0),
	"n_t4": Vector3(-34.0, 12.0, -62.0),
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
