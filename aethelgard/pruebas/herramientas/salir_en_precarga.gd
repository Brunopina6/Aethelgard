extends SceneTree
# Reproduce con la portada de verdad (portada/inicio_alternativo.tscn, que hereda la carga de carga.gd): espera a que su
# precarga en hilo tenga «objetivo» en curso (en_curso) y entonces:
#   modo=salir   sale del juego en ese mismo fotograma (como prueba_musica_titulo al acabar con la carga a medias);
#   modo=cambiar cambia a mapa.tscn (como la prueba al ir al juego) y sale 3 s después.
# Sin ventana, con datos aislados. -- objetivo=res://ciudad_oakhaven.tscn modo=salir [3d sin_prologo]
# Antes de PRECARGA_19_11, «salir» dejaba en la salida de errores «Parse Error: Failed. [Resource file
# res://ciudad_oakhaven.tscn:6]» (el fallo de prueba_musica_titulo en la batería del 19/11, 5 de 5 pasadas); desde
# entonces carga.gd (_exit_tree) espera a que acabe y no sale nada (5 de 5). Con ventana (a_la_vez=6) se ve igual.

const ESCENA := "res://portada/inicio_alternativo.tscn"
var objetivo := "res://ciudad_oakhaven.tscn"
var modo := "salir"
var t0 := 0
var visto := -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("objetivo="):
			objetivo = a.substr(9)
		elif a.begins_with("modo="):
			modo = a.substr(5)
	Engine.set_meta("partida_lista", true)
	change_scene_to_file(ESCENA)
	t0 = Time.get_ticks_msec()


func _process(_d: float) -> bool:
	var ms := Time.get_ticks_msec() - t0
	if visto >= 0:
		if ms - visto > 3000:
			print("salgo 3 s después del cambio de escena (estado de %s: %d)" % [objetivo, ResourceLoader.load_threaded_get_status(objetivo)])
			return true
		return false
	if ms > 150000:
		print("RESULTADO: no llegó a pedir %s en 150 s" % objetivo)
		return true
	var e = current_scene
	if e == null or not "en_curso" in e:
		return false
	if objetivo in e.en_curso:
		print("a los %d ms la portada tiene en curso %s (estado %d; hechos %d de %d)" % [ms, e.en_curso, 			ResourceLoader.load_threaded_get_status(objetivo), e.hechos, e.total])
		if modo == "cambiar":
			change_scene_to_file("res://mapa.tscn")
			visto = ms
			return false
		print("salgo ahora")
		return true
	return false
