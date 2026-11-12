extends "res://personajes/heroes_v2/lya_v2_3d.gd"
# Lya v3 (V12; detrás de la elección «Protagonistas: v3 (prueba)», APAGADA por defecto).
#
# Hereda TODO de lya_v2_3d.gd (mismos clips, instantes y API de combate, exploración y conversación) y solo cambia
# el modelo (personajes/heroes_v3/lya/lya_v3.glb: GEOMETRÍA PROPIA sobre el MISMO esqueleto, crear_heroes_v3.py y
# lya_v3.py), la cara y los materiales (heroe_v3_ayudante.gd). Si falta el GLB v3, se comporta como su v2.

const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const AyudanteV3 := preload("res://personajes/heroes_v3/heroe_v3_ayudante.gd")

var es_v3 := false


func _cargar_modelo() -> void:
	var glb: String = HeroesV3.GLB["Lya"]
	if ResourceLoader.exists(glb) and (ruta_modelo in HeroesV2.ORIGINALES["Lya"] or ruta_modelo == ""
			or ruta_modelo == HeroesV2.GLB["Lya"]):
		ruta_modelo = glb
		es_v3 = true
	super._cargar_modelo()


func _ready() -> void:
	super._ready()
	HeroesV3.cambiar_ayudante(self, "Lya", AyudanteV3)
