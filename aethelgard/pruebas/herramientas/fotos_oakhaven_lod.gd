extends SceneTree
# Capturas de Oakhaven 3D para comparar la simplificación de los edificios (zonas3d/oakhaven/ciudad.gd, _con_lod) antes y
# después de cambiar SurfaceTool.generate_lod (obsoleto) (rend3, 13/11). Sin caché de edificios (se juntan siempre), con
# semilla fija y --fixed-fps: dos pasadas con el mismo código deben dar la misma imagen (se comprueba con «repetir»).
# CON ventana y datos aislados.
# Uso: Godot --path aethelgard --resolution 1280x720 --fixed-fps 30 --script res://pruebas/herramientas/fotos_oakhaven_lod.gd --
#        salida=<carpeta> etiqueta=<x> [perfiles=bajo,medio,alto] 3d sin_prologo

const OAK := "res://zonas3d/oakhaven_3d.tscn"
const SITIOS := {"llegada": null, "norte": Vector3(0, 0, -12), "este": Vector3(12, 0, 0), "lejos": Vector3(0, 0, -24)}
var salida := ""
var etiqueta := ""
var perfiles: Array = ["bajo", "medio", "alto"]


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("oakhaven_sin_cache", true)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	var R = root.get_node("Recursos")
	for pf in perfiles:
		seed(7)
		Engine.set_meta("calidad_proto", pf)
		Engine.set_meta("pos_3d_ok", false)
		change_scene_to_file(OAK)
		while current_scene == null or current_scene.scene_file_path != OAK or R.cambiando or current_scene.get("kael") == null:
			await process_frame
		await _esperar(60)
		var v = current_scene
		var llegada: Vector3 = v.kael.global_position
		var c = v.get("ciudad")
		print("FOTOS %s: simplificados %s, lods %s" % [pf, str(c.get("simplificados")) if c else "?", str(c.get("lods_hechos")) if c else "?"])
		for s in SITIOS:
			v._colocar_kael(llegada if SITIOS[s] == null else llegada + SITIOS[s])
			Engine.time_scale = 1.0
			await _esperar(20)
			Engine.time_scale = 0.0
			await _esperar(3)
			root.get_texture().get_image().save_png(salida.path_join("oak_%s_%s_%s.png" % [pf, s, etiqueta]))
		Engine.time_scale = 1.0
	print("FOTOS FIN")
	quit()
