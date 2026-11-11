extends SceneTree
# Héroes v2 (fase B, V12): capturas de un COMBATE REAL (combate.tscn, grupo de 3, en automático) antes y después.
#   godot --path aethelgard --script res://pruebas/fotos_heroes_v2_combate.gd -- salida=<carpeta> grupo=3 auto [antes]
# Con «antes», el combate de siempre. Sin él, los héroes v2 SIN tocar combate.gd: para la prueba, los scripts v2 toman
# la ruta de los originales en la caché de recursos (take_over_path), que es lo mismo que haría el cambio de una línea
# documentado en el informe (HeroesV2.script_de). Solo en esta prueba; el juego no lo hace.
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
	if not antes:
		# los enemigos que heredan de maga_3d.gd se cargan ANTES de cambiar la ruta (heredan del original)
		for r in ["res://goblin_3d.gd", "res://kael_3d.gd", "res://maga_3d.gd", "res://garon_3d.gd"]:
			_guardar.append(load(r))
		var pares := {"res://personajes/heroes_v2/kael_v2_3d.gd": "res://kael_3d.gd",
			"res://personajes/heroes_v2/lya_v2_3d.gd": "res://maga_3d.gd",
			"res://personajes/heroes_v2/garon_v2_3d.gd": "res://garon_3d.gd"}
		for v2 in pares:
			var s: Script = load(v2)
			_guardar.append(s)
			s.take_over_path(pares[v2])
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
