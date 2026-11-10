extends SceneTree
# Capturas del Coloso de la Falla (V9, jefe 2), CON VENTANA: en el combate (el inicio con su respaldo 2D, el Puño de la
# Falla cargado, la ventana con los puntos débiles, el cambio de fase y la coraza rúnica) y en la Garganta 3D (dormido
# al fondo de la grieta, visto desde su vuelta y desde el pilar del peregrino). Argumentos (después de --):
# «salida=<carpeta> 3d garganta3d sin_prologo auto». No es una prueba: no falla; solo guarda PNG para revisarlos.

const K := preload("res://combate_coloso.gd")
const REGION := "res://zonas3d/garganta_3d.tscn"

var salida := "user://fotos_coloso"
var c: Node
var n := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	DirAccess.make_dir_recursive_absolute(salida)
	seed(5)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_coloso.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("grupo_combate", K.GRUPO)
	Engine.set_meta("combate_fijo", K.COMBATE)
	Engine.set_meta("desde_mapa", false)
	Engine.set_meta("zona", "garganta")
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


func _coloso() -> Dictionary:
	for e in c.enemigos:
		if K.es_coloso(e):
			return e
	return {}


func _hasta(cond: Callable, maximo: int) -> void:
	for i in maximo:
		if cond.call():
			return
		await process_frame


func _fotos() -> void:
	await _esperar(150)
	await _foto("combate_inicio")
	var g := _coloso()
	if not g.is_empty():
		g["cargando"] = true
		g["objetivo_carga"] = c.heroes[0]
		c._marcar_aviso(g, true)
		c._actualizar()
		await _esperar(10)
		await _foto("combate_puno_cargado")
		g["atb"] = 99.99
		await _hasta(func(): return g.get("expuesto", false), 600)
		await _esperar(12)
		await _foto("combate_expuesto")
		c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.45))
		await _hasta(func(): return g.get("fase2", false) and not g.get("fase2_pendiente", false), 600)
		await _esperar(25)
		await _foto("combate_cambio_fase")
		await _esperar(70)
		await _foto("combate_coraza_runica")
	c.queue_free()
	await _esperar(5)
	change_scene_to_file(REGION)
	await _esperar(90)
	var r = current_scene
	if r != null and "coloso" in r:
		r.pasos = 0
		r._colocar_kael(r.VUELTA_COLOSO)
		r._ultima = r.VUELTA_COLOSO
		await _esperar(90)
		await _foto("garganta_desde_la_vuelta")
		var T = load("res://zonas3d/garganta/trazado.gd")
		r._colocar_kael(T.PILAR_PEREGRINO + Vector3(-0.6, 0, 3.0))
		r._ultima = r.kael.global_position
		await _esperar(90)
		await _foto("garganta_desde_el_pilar")
	quit(0)
