extends SceneTree
# Prueba: mapa -> zona -> mapa con Recursos.cambiar_escena (FPS, grupo «zona» y su liberación).

var frames := 0
var R


func _initialize() -> void:
	R = root.get_node("Recursos")
	change_scene_to_file("res://mapa.tscn")


func _info(t: String) -> void:
	var esc := current_scene
	print("%s | escena=%s fps_max=%d zona=%d comun=%d negro=%s" % [t, esc.scene_file_path if esc else "-",
		Engine.max_fps, R.grupos["zona"].size(), R.grupos["comun"].size(), R.negro.visible])


func _process(_d: float) -> bool:
	frames += 1
	if frames == 20:
		_info("mapa")
		current_scene._entrar()
	if frames == 200:
		_info("zona")
		current_scene._salir()
	if frames == 330:
		_info("de vuelta")
		return true
	return false
