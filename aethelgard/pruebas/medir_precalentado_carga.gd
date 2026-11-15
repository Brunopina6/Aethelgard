extends SceneTree
# MEDIDA (15/11), no prueba: ¿el precalentado de la muestra en la carga (muestra_calle.precalentar_en) evita que la
# PRIMERA entrada a la muestra compile programas? Con una carpeta de datos NUEVA (caché de sombreadores vacía):
#   con=si: monta el precalentado 24 fotogramas (como carga.gd), cuenta la caché antes y después; luego entra en la
#           muestra y lee del diagnóstico cuánto creció la caché en la entrada y cuánto tardó el primer dibujo;
#   con=no: entra directamente.
# Uso: --path aethelgard --resolution 1600x720 --script res://pruebas/medir_precalentado_carga.gd -- 3d sin_prologo
#      perfil=bajo con=si|no   (lanzar con APPDATA/LOCALAPPDATA en una carpeta vacía cada vez)
const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const D := preload("res://zonas3d/muestra_calle/diagnostico_tirones.gd")
var con := true


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("con="):
			con = a.trim_prefix("con=") == "si"
		elif a.begins_with("perfil="):
			Engine.set_meta("calidad_proto", a.trim_prefix("perfil="))
	Engine.set_meta("archivo_partida_prueba", "user://medir_precalentado_carga.save")
	_medir.call_deferred()


func _medir() -> void:
	load("res://progreso.gd").cargar()
	Engine.set_meta("partida_lista", true)
	await process_frame
	var c0 := D._archivos("user://shader_cache")
	if con:
		var u0 := Time.get_ticks_usec()
		var nodo := Node.new()
		root.add_child(nodo)
		var vp = load("res://zonas3d/muestra_calle/muestra_calle.gd").precalentar_en(nodo)
		var montado := vp != null                    # (luego se libera: un objeto liberado compara igual a null)
		for i in 24:
			await process_frame
		nodo.queue_free()
		await process_frame
		print("[medida] precalentado: %s · %.0f ms · caché %d → %d" % ["montado" if montado else "NULO",
			(Time.get_ticks_usec() - u0) / 1000.0, c0, D._archivos("user://shader_cache")])
	change_scene_to_file(MUESTRA)
	for i in 30:
		await process_frame
	print("[medida] con=%s · caché al final %d" % ["si" if con else "no", D._archivos("user://shader_cache")])
	quit(0)
