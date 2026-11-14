extends SceneTree
# V12 (14/11/2026): capturas del banco de pruebas de Auditoría (banco_pruebas.gd), arriba y desplazado abajo, para
# revisar que se lee y que los botones caben. Con ventana; datos aislados. Uso: -- salida=<carpeta>

var salida := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	_probar.call_deferred()


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join(nombre))


func _probar() -> void:
	DirAccess.make_dir_recursive_absolute(salida)
	var b = load("res://banco_pruebas.tscn").instantiate()
	root.add_child(b)
	for i in 30:
		await process_frame
	await _foto("banco_arriba.png")
	b.marco.scroll_vertical = 10000
	for i in 10:
		await process_frame
	await _foto("banco_abajo.png")
	load("res://banco_pruebas.gd").salir()
	print("OK: 2 capturas en ", salida)
	print("FALLOS: 0")
	quit(0)
