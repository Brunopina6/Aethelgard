extends SceneTree
# Héroes v3 (V12): capturas de un COMBATE REAL (combate.tscn, grupo de 3, en automático) con la versión elegida.
#   godot --path aethelgard --script res://pruebas/fotos_heroes_v3_combate.gd -- salida=<carpeta> grupo=3 auto
#         semilla=7 version=originales|v2|v3
# Pone Engine.set_meta("heroes_version", ...), como la opción de Ajustes «Protagonistas». Con la misma semilla, los tres
# combates siguen el mismo guion (mismos instantes): las capturas se comparan una a una. No escribe partidas.

var salida := "user://fotos_heroes_v3_combate"
var version := "v3"
var c: Node


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("salida="):
			salida = arg.substr(7)
		elif arg.begins_with("version="):
			version = arg.substr(8)
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280, 720)
	Engine.set_meta("heroes_version", version)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	_fotos.call_deferred()


func _fotos() -> void:
	for i in 16:
		await create_timer(1.6 if i > 0 else 2.5).timeout
		await process_frame
		root.get_texture().get_image().save_png(salida.path_join("combate_%s_%02d.png" % [version, i]))
	print("FOTOS: 16 (", version, ")")
	quit(0)
