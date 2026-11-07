extends "res://prototipos/sendero_puente.gd"
# Escena de COMPARACIÓN de árboles (Fase 2.1 — calidad artística). Mismo terreno, luz y perfiles que Pastos Verdes,
# pero sin los árboles del mapa; en un claro, de izquierda a derecha:
#   1. el árbol actual (arce de Meshy con copa de matas fotográficas), como referencia;
#   2. candidato «pradera» (frondoso)   3. candidato «abedul» (copa ligera)   4. candidato «mágico» (ornamental).
# No cambia Pastos Verdes ni el juego. Abrir: prototipos/arboles_prueba.tscn (F6).

const FILA := [Vector3(-19.5, 0, 2.0), Vector3(-14.5, 0, 2.0), Vector3(-10.0, 0, 2.0), Vector3(-5.5, 0, 1.0)]


func _ready() -> void:
	arboles_mapa = false
	super._ready()


func _crear_escenario() -> void:
	super._crear_escenario()
	var est := load("res://prototipos/arbol_estilizado.gd")
	var p: Vector3 = FILA[0]
	if ResourceLoader.exists("res://modelos/arce/arce_copa.res"):
		_arbol_3d(Vector3(p.x, altura(p.x, p.z), p.z), "arce", 1.0, 0.6)
	for k in 3:
		var q: Vector3 = FILA[k + 1]
		est.crear(self, Vector3(q.x, altura(q.x, q.z), q.z), ["pradera", "abedul", "magico"][k], 1.0, 0.4 + k, tex_detalle)
