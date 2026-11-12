extends "res://personajes/heroes_v2/kael_v2_3d.gd"
# Kael v3 (V12; detrás de la elección «Protagonistas: v3 (prueba)», APAGADA por defecto).
#
# Hereda TODO de kael_v2_3d.gd (mismos clips, instantes, API de combate, exploración y conversación) y solo cambia:
#   - el modelo: personajes/heroes_v3/kael/kael_v3.glb, con GEOMETRÍA PROPIA (crear_heroes_v3.py y kael_v3.py: cabeza
#     chibi, pelo por mechones, abrigo en piezas, manos con dedos) sobre el MISMO esqueleto, así que valen los clips
#     de la biblioteca común y los del especialista de combate;
#   - la cara (heroe_v3_ayudante.gd): ojos y boca de atlas propio y cejas que se mueven;
#   - los materiales: color por vértice, luz pintada y contorno.
# Si falta el GLB v3, se comporta como Kael v2 (y si falta también ese, como el original).

const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const AyudanteV3 := preload("res://personajes/heroes_v3/heroe_v3_ayudante.gd")

var es_v3 := false


func _cargar_modelo() -> void:
	var glb: String = HeroesV3.GLB["Kael"]
	if ResourceLoader.exists(glb) and (ruta_modelo in HeroesV2.ORIGINALES["Kael"] or ruta_modelo == ""
			or ruta_modelo == HeroesV2.GLB["Kael"]):
		ruta_modelo = glb
		es_v3 = true
	super._cargar_modelo()


func _ready() -> void:
	super._ready()
	HeroesV3.cambiar_ayudante(self, "Kael", AyudanteV3)
