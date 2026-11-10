extends SceneTree
# Capturas del combate contra el Guardián del Bosque (fase 3), CON VENTANA y «-- auto»: el inicio, la segunda fase y
# varios momentos del combate. «salida=<carpeta>». No es una prueba: no falla; solo guarda PNG.

var salida := "user://fotos_guardian"
var c: Node
var n := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	DirAccess.make_dir_recursive_absolute(salida)
	seed(3)
	Engine.set_meta("grupo_combate", 11)
	Engine.set_meta("combate_fijo", "pastos_guardian")
	Engine.set_meta("desde_mapa", false)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	_fotos.call_deferred()


func _esperar(k: int) -> void:
	for i in k:
		await process_frame


func _foto(nombre: String) -> void:
	await _esperar(2)
	root.get_texture().get_image().save_png(salida.path_join("%02d_%s.png" % [n, nombre]))
	n += 1
	print("foto: ", nombre)


func _guardian() -> Dictionary:
	for e in c.enemigos:
		if str(e.get("clave", "")) == "guardian_bosque":
			return e
	return {}


func _fotos() -> void:
	await _esperar(150)
	await _foto("inicio")
	for i in 3:
		await _esperar(110)
		await _foto("fase1_%d" % i)
	var g := _guardian()
	if not g.is_empty():
		c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.45))
		for i in 200:
			if g.get("fase2", false) and not g.get("fase2_pendiente", false):
				break
			await process_frame
		await _esperar(20)
		await _foto("cambio_fase")
		await _esperar(60)
		await _foto("fase2")
		for i in 3:
			await _esperar(110)
			await _foto("fase2_%d" % i)
	quit(0)
