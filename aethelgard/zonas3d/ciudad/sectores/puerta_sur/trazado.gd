extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11; EXPERIMENTAL): sector 1, PUERTA DEL SUR Y CARAVANAS. Trazado MÍNIMO de M0: el suelo de
# sus calles principales a la cota correcta y sus bordes de conexión, para que la ciudad entera se recorra. Lo llena el
# agente de maqueta A (sectores 1 y 2); el ejemplo del nivel esperado es sectores/plaza_tapiz/trazado.gd. Bordes
# acordados (plano.gd, CONEXIONES): Calle Mayor (z 62, cota 0), Rampa de los Carros (x 45, cota 0) y Arco de los
# Pasajes (x −30, cota 1). La Puerta del Sur [C] es la ÚNICA salida al mapa; en la maqueta no se sale (Volver al banco).
# Contrato y formatos: docs/v12/CIUDAD_OAKHAVEN.md y zonas3d/ciudad/trazado_comun.gd.

const C := preload("res://zonas3d/ciudad/trazado_comun.gd")
const ID := "puerta_sur"

const SUELOS := [
	["puerta_sur", Rect2(-4.0, 62.0, 8.0, 18.0), "", 0.0, 0.0],         # Calle Mayor, tramo sur (borde z 62, cota 0)
	["puerta_sur", Rect2(-26.0, 80.0, 67.0, 10.0), "", 0.0, 0.0],       # patio de caravanas
	["puerta_sur", Rect2(-4.0, 90.0, 8.0, 3.0), "", 0.0, 0.0],          # explanada de la Puerta del Sur
	["puerta_sur", Rect2(-30.0, 80.0, 1.0, 3.0), "", 1.0, 1.0],         # Arco de los Pasajes (borde x −30, cota 1)
	["puerta_sur", Rect2(-29.0, 80.0, 3.0, 3.0), "x", 1.0, 0.0],        # su rampa hasta el patio
	["puerta_sur", Rect2(41.0, 76.0, 4.0, 6.0), "", 0.0, 0.0],          # salida a la Rampa de los Carros (borde x 45, cota 0)
]

const BLOQUES := [
	["muralla_sur_o", "puerta_sur", Rect2(-30.0, 93.0, 26.0, 2.5), 0.0, 8.0, "muro", true],
	["torre_puerta_o", "puerta_sur", Rect2(-7.0, 93.0, 3.0, 3.5), 0.0, 9.5, "muro", true],
	["puerta_sur", "puerta_sur", Rect2(-4.0, 93.0, 8.0, 0.5), 0.0, 5.0, "puerta", true],
	["dintel_puerta", "puerta_sur", Rect2(-4.0, 93.0, 8.0, 2.5), 5.5, 2.5, "muro", false],
	["torre_puerta_e", "puerta_sur", Rect2(4.0, 93.0, 3.0, 3.5), 0.0, 9.5, "muro", true],
	["muralla_sur_e", "puerta_sur", Rect2(7.0, 93.0, 38.0, 2.5), 0.0, 8.0, "muro", true],
	["establo", "puerta_sur", Rect2(-26.0, 70.0, 12.0, 10.0), 0.0, 5.0, "casa", true],
	["casa_mayor_o", "puerta_sur", Rect2(-12.0, 66.0, 7.0, 14.0), 0.0, 7.0, "casa", true],
	["cuerpo_guardia", "puerta_sur", Rect2(8.0, 70.0, 14.0, 10.0), 0.0, 6.0, "casa", true],
	["casa_mayor_e", "puerta_sur", Rect2(24.0, 66.0, 16.0, 14.0), 0.0, 7.0, "casa", true],
	["carro_caravana", "puerta_sur", Rect2(10.0, 84.0, 3.0, 2.0), 0.0, 1.8, "decor", true],
	["abrevadero", "puerta_sur", Rect2(-20.0, 82.0, 0.8, 2.5), 0.0, 0.7, "bajo", true],
]
const OCULTABLES := ["muralla_sur_o", "torre_puerta_o", "puerta_sur", "dintel_puerta", "torre_puerta_e", "muralla_sur_e"]

const ANCLAS := {
	"referencia": Vector3(0.0, 0.0, 91.5),          # ante la Puerta del Sur [C]
	"rotulo": Vector3(0.0, 0.0, 81.0),              # (el rótulo del sector, sobre el patio: en la puerta quedaba pegado a la cámara)
	"inicio": Vector3(0.0, 0.0, 86.0),
	"reserva_rastreadores_caravanas": Vector3(25.0, 0.0, 85.0),
	"puerta_establo": Vector3(-20.0, 0.0, 80.0),
	"puerta_guardia": Vector3(15.0, 0.0, 80.0),
	"n_mayor_n": Vector3(0.0, 0.0, 63.0),
	"n_patio": Vector3(0.0, 0.0, 85.0),
	"n_arco": Vector3(-29.5, 1.0, 81.5),
	"n_carros": Vector3(44.0, 0.0, 79.0),
}

const PUERTAS := {
	"establo": {"fuera": Vector3(-20.0, 0.0, 81.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el establo",
		"ancla": "puerta_establo", "nombre": "Establo"},
	"cuerpo_guardia": {"fuera": Vector3(15.0, 0.0, 81.4), "mira": PI, "radio": 1.6, "texto": "Entrar en el cuerpo de guardia",
		"ancla": "puerta_guardia", "nombre": "Cuerpo de guardia"},
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
