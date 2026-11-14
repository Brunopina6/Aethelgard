extends SceneTree
# V12 (14/11): Nix con su vestuario canónico (personajes/nix/fbx/, interruptores «nix_v12» y «nix_fbx» encendidos solo
# aquí) en un COMBATE REAL (combate.tscn, grupo Kael, Lya y Nix, en automático), para ver el brillo y los colores con
# la luz y el fondo de verdad del juego, no la de un estudio. «-- salida=<carpeta> [zona=llanura|desierto|...] [antes]»
# (con «antes», la Nix de siempre: el mismo combate sin nix_fbx). 12 capturas cada 1,5 s.
# No guarda partidas (todo en memoria) y se ejecuta con datos aislados (ejecutar_pruebas.ps1).

var salida := "user://fotos_nix_fbx_combate"
var antes := false
var zona := "llanura"
var c: Node


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("salida="):
			salida = arg.substr(7)
		elif arg.begins_with("zona="):
			zona = arg.substr(5)
		elif arg == "antes":
			antes = true
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280, 720)
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("nix_v12", true)
	if not antes:
		Engine.set_meta("nix_fbx", true)
	G.unir("Nix")
	G.formar(["Kael", "Lya", "Nix"])
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	_fotos.call_deferred()


func _fotos() -> void:
	var etiqueta := ("antes_" if antes else "vestuario_") + zona
	for i in 12:
		await create_timer(1.5 if i > 0 else 2.5).timeout
		await process_frame
		root.get_texture().get_image().save_png(salida.path_join("combate_%s_%02d.png" % [etiqueta, i]))
	print("FOTOS: 12 (", etiqueta, ")")
	for k in ["nix_v12", "nix_fbx", "zona", "tipo_combate", "grupo_combate"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(0)
