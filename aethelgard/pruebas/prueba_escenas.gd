extends SceneTree
# Prueba: mapa -> zona -> mapa con Recursos.cambiar_escena (FPS, grupo «zona» y su liberación).
# Se ejecuta con «-- sin_prologo»: sin partida, el mapa lanza el prólogo (Dialogic) y, mientras hay un diálogo
# abierto, no actualiza el lugar cercano (mapa.gd, _process). Por eso, con el prólogo, _entrar() no hacía nada.
# Espera a que cada cambio de escena ocurra de verdad (con un tiempo real máximo) y termina con quit(1) y
# «FALLO» si alguno no llega. Al arrancar sin la pantalla de carga, la zona aún no está en caché: su carga en
# segundo plano puede no terminar y Recursos.cambiar_escena pasa a cargarla en síncrono (ESPERA_MAX_CARGA).

const ESPERA_MAX_MS := 20000

var frames := 0
var paso := 0
var t_paso := 0
var R


func _initialize() -> void:
	R = root.get_node("Recursos")
	change_scene_to_file("res://mapa.tscn")


func _info(t: String) -> void:
	var esc := current_scene
	print("%s | escena=%s fps_max=%d zona=%d comun=%d negro=%s" % [t, esc.scene_file_path if esc else "-",
		Engine.max_fps, R.grupos["zona"].size(), R.grupos["comun"].size(), R.negro.visible])


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	quit(1)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _siguiente() -> void:
	paso += 1
	t_paso = Time.get_ticks_msec()


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo("el paso %d no terminó en %d s (escena=%s)" % [paso, ESPERA_MAX_MS / 1000, _escena()])
		return false
	match paso:
		0:
			if frames == 20:
				_info("mapa")
				if _escena() != "res://mapa.tscn":
					_fallo("no empezó en el mapa (%s)" % _escena())
					return false
				current_scene._comprobar_cerca()            # el jugador aparece junto a Oakhaven
				if current_scene.cerca == null:
					_fallo("el jugador no está junto a ningún lugar del mapa")
					return false
				current_scene._entrar()
				_siguiente()
		1:
			if _escena() == "res://zona.tscn" and not R.cambiando:
				_info("zona")
				current_scene._salir()
				_siguiente()
		2:
			if _escena() == "res://mapa.tscn" and not R.cambiando:
				_info("de vuelta")
				print("OK mapa -> zona -> mapa")
				return true
	return false
