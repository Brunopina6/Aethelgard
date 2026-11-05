extends SceneTree
# Prueba de la escena de muestra (prototipos/sendero_puente.tscn): Kael recorre el sendero, cruza el
# puente y sigue al otro lado. Hace una foto al llegar a cada punto y apunta posición y FPS.
# Si en 10 s no llega a un punto, lo dice y pasa al siguiente.
# Uso: --path aethelgard --script res://pruebas/prueba_sendero.gd --fixed-fps 30 -- <carpeta> [movil]

var v: Node
var n := 0
var salida := ""
var etapa := -1
var desde := 0
const RUTA := [["2_sendero", Vector3(-9, 0, 9)], ["3_curva", Vector3(-3, 0, 5)], ["4_entrada_puente", Vector3(5.3, 0, -2)],
	["5_sobre_puente", Vector3(9, 0, -2)], ["6_otro_lado", Vector3(12.7, 0, -2)], ["7_final", Vector3(16, 0, -6)]]


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	v = load("res://prototipos/sendero_puente.tscn").instantiate()
	root.add_child(v)


func _foto(nombre: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [salida, nombre])
	print(nombre, "  kael=", v.kael.global_position.snapped(Vector3.ONE * 0.1), "  fps=", Engine.get_frames_per_second(),
		"  tapados=", v.tapados.size())


func _siguiente() -> void:
	etapa += 1
	desde = n
	if etapa < RUTA.size():
		v.destino = RUTA[etapa][1]


func _process(_d: float) -> bool:
	n += 1
	if n == 60:
		_foto("1_inicio")
		_siguiente()
	elif etapa >= 0 and etapa < RUTA.size():
		var meta: Vector3 = RUTA[etapa][1]
		var lejos := Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length()
		if v.destino == null or n - desde > 300:
			if lejos > 0.5:
				print("  ¡no llegó a ", RUTA[etapa][0], "! se quedó en ", v.kael.global_position.snapped(Vector3.ONE * 0.1),
					" (destino ", v.destino, ")")
			_foto(RUTA[etapa][0])
			_siguiente()
			if etapa == RUTA.size():
				v.distancia = 30.0
	elif etapa == RUTA.size() and n - desde == 30:
		_foto("8_lejos_30m")
		return true
	return false
