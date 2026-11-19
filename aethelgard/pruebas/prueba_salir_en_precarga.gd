extends SceneTree
# PRECARGA_19_11_REVISION: cerrar el juego con la precarga de la pantalla de inicio a medias no deja errores.
# Sin ventana, con datos aislados. Entra en la portada de verdad (portada/inicio_alternativo.tscn, que hereda la carga de
# carga.gd; sin ventana carga un archivo cada vez), espera a que tenga res://ciudad_oakhaven.tscn en curso y sale en ese
# mismo fotograma. Antes de PRECARGA_19_11 la salida dejaba «Parse Error: Failed. [Resource file
# res://ciudad_oakhaven.tscn:6]» (5 de 5): el ejecutor la da por FALLIDA con ese patrón. Desde entonces carga.gd
# (_exit_tree) espera a que acabe (con tope: Recursos.esperar_en_hilo) y apunta por dónde iba la carga en el .log.
# La prueba falla por sí misma si ciudad_oakhaven.tscn ya no está en la precarga o si no llega a estar en curso a tiempo.
# Herramienta hermana con más modos: pruebas/herramientas/salir_en_precarga.gd. El cierre durante Recursos.cambiar_escena
# lo prueba prueba_salir_en_cambio.gd.

const ESCENA := "res://portada/inicio_alternativo.tscn"
const OBJETIVO := "res://ciudad_oakhaven.tscn"
const TOPE_MS := 120000
var t0 := 0
var visto_en_lista := false


func _initialize() -> void:
	Engine.set_meta("partida_lista", true)
	change_scene_to_file(ESCENA)
	t0 = Time.get_ticks_msec()


func _process(_d: float) -> bool:
	var ms := Time.get_ticks_msec() - t0
	if ms > TOPE_MS:
		print("FALLO: en %d ms la portada no llegó a tener %s en curso" % [TOPE_MS, OBJETIVO])
		print("FALLOS: 1")
		return true
	var e = current_scene
	if e == null or not "en_curso" in e or not "pendientes" in e or e.total == 0:
		return false
	if not visto_en_lista:
		if not (OBJETIVO in e.pendientes or OBJETIVO in e.en_curso):
			print("FALLO: %s no está en la precarga de la portada (%d archivos): la prueba ya no comprueba nada" % [OBJETIVO, e.total])
			print("FALLOS: 1")
			return true
		visto_en_lista = true
	if OBJETIVO in e.en_curso:
		print("a los %d ms la portada tiene en curso %s (estado %d; hechos %d de %d); salgo en este fotograma"
			% [ms, e.en_curso, ResourceLoader.load_threaded_get_status(OBJETIVO), e.hechos, e.total])
		print("FALLOS: 0")
		return true
	return false
