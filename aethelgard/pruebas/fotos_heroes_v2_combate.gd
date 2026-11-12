extends SceneTree
# Héroes v2 (fase B, V12): capturas de un COMBATE REAL (combate.tscn, grupo de 3, en automático) antes y después.
#   godot --path aethelgard --script res://pruebas/fotos_heroes_v2_combate.gd -- salida=<carpeta> grupo=3 auto [antes]
# Con «antes», el combate de siempre (Engine.set_meta("heroes_v2", false)); sin él, los héroes v2 (true), como la
# opción de Ajustes «Protagonistas». Con «semilla=N» los dos combates siguen el mismo guion (mismos instantes).
# No escribe partidas (el combate de pruebas no guarda) y se ejecuta con datos aislados (ejecutar_pruebas.ps1).

var salida := "user://fotos_heroes_v2_combate"
var antes := false
var c: Node
var _guardar := []          # referencias a los scripts originales (que no se liberen)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("salida="):
			salida = arg.substr(7)
		elif arg == "antes":
			antes = true
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280, 720)
	# 13/11: combate.gd ya pide el script con HeroesV2.script_de: basta el interruptor, como la opción de Ajustes
	# (antes, sin ese enganche, la prueba cambiaba las rutas en la caché con take_over_path).
	Engine.set_meta("heroes_v2", not antes)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	_fotos.call_deferred()


func _fotos() -> void:
	var etiqueta := "antes" if antes else "despues"
	for i in 16:
		await create_timer(1.6 if i > 0 else 2.5).timeout
		await process_frame
		root.get_texture().get_image().save_png(salida.path_join("combate_%s_%02d.png" % [etiqueta, i]))
	print("FOTOS: 16 (", etiqueta, ")")
	quit(0)
