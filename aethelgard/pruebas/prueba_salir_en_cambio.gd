extends SceneTree
# PRECARGA_19_11_REVISION: cerrar el juego mientras Recursos.cambiar_escena carga la escena nueva en hilo no deja errores.
# Sin ventana, con datos aislados. Pide Recursos.cambiar_escena("res://combate.tscn") y sale en el primer fotograma en que
# su carga en hilo está en curso. Antes de PRECARGA_19_11_REVISION la salida dejaba «Parse Error: Failed. [Resource file
# res://combate.tscn:6]» (3 de 3): el ejecutor la da por FALLIDA con ese patrón. Desde entonces Recursos (_exit_tree)
# espera a esa escena (con tope: esperar_en_hilo). La prueba falla por sí misma si la carga no llega a estar en curso.

const OBJETIVO := "res://combate.tscn"
var n := 0
var pedido := false


func _initialize() -> void:
	Engine.set_meta("partida_lista", true)


func _process(_d: float) -> bool:
	n += 1
	var rec = root.get_node_or_null("Recursos")
	if rec == null:
		print("FALLO: no está el autoload Recursos")
		print("FALLOS: 1")
		return true
	if not pedido:
		if n >= 3:
			rec.cambiar_escena(OBJETIVO)
			pedido = true
		return false
	var st := ResourceLoader.load_threaded_get_status(OBJETIVO)
	if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		print("fotograma %d: %s cargándose en hilo (estado %d); salgo en este fotograma" % [n, OBJETIVO, st])
		print("FALLOS: 0")
		return true
	if n > 900 or rec.cambiando == false:
		print("FALLO: la carga en hilo de %s no llegó a estar en curso (estado %d, fotograma %d)" % [OBJETIVO, st, n])
		print("FALLOS: 1")
		return true
	return false
