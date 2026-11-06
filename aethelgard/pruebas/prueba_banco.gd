extends SceneTree
# Lanza el banco de pruebas de Pastos Verdes (lo mismo que el botón «PRUEBA») y termina al acabar.
# Uso: --path aethelgard --script res://pruebas/prueba_banco.gd   (sin --headless: necesita dibujar)
# Opcional: «-- sin_vsync» para medir la capacidad del PC sin el límite de la pantalla.

var v: Node
var n := 0


func _initialize() -> void:
	if "sin_vsync" in OS.get_cmdline_user_args():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	change_scene_to_file("res://prototipos/sendero_puente.tscn")


func _process(_d: float) -> bool:
	n += 1
	if n == 30:
		if "tope" in OS.get_cmdline_user_args():
			current_scene._empezar_banco(current_scene.BANCO_TOPE)
		elif "diag" in OS.get_cmdline_user_args():
			current_scene._empezar_banco(current_scene.BANCO_DIAG)
		else:
			current_scene._empezar_banco()
	if n > 30 and not Engine.has_meta("banco_proto"):
		return n > 40 and current_scene.tabla_banco != null
	return false
