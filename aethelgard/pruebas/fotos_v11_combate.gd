extends SceneTree
# Capturas del hito B de la V11 (para revisarlas una persona): el panel de objetivos a la derecha al ATACAR (grupo 2:
# dos Slimes y Grimfang), con un derrotado apagado, la lista de área de una magia que alcanza a todos, el menú de
# INVOCACIÓN y el aviso de un golpe preparado con su interrupción. Uso: «-- salida=<carpeta>». Con ventana.

var c = null
var salida := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_v11.save")
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await _esperar(8)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(salida)
	img.save_png(salida.path_join(nombre + ".png"))
	print("FOTO ", nombre)


func _probar() -> void:
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 5
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("grupo_combate", 2)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(60)
	c.set_process(false)
	c.actor = c.heroes[0]
	c._mostrar_menu()
	await _foto("00_menu")
	c._menu_objetivo("atacar", "")
	await _foto("01_objetivo_panel")
	c._apuntar(c.enemigos[2])
	await _foto("02_objetivo_tercero")
	c._limpiar_objetivo()
	c.enemigos[0]["hp"] = 0
	c.enemigos[0]["rig"].visible = false
	c._menu_objetivo("atacar", "")
	await _foto("03_derrotado_apagado")
	c._limpiar_objetivo()
	c.actor = c.heroes[1]
	c.menu.heroe_actual = c.heroes[1]
	c._menu_magia(2)
	await _foto("04_magia_area")
	c._invocar()
	await _foto("05_invocacion")
	c._atras()
	c._ocultar_menu()
	var g: Dictionary = c.enemigos[1]
	g["personalidad"] = "agresivo"
	g["cargando"] = true
	g["carga_recibido"] = 0
	c._marcar_aviso(g, true)
	c.registro.text = "%s alza el hacha: ¡va a por Kael! (Golpéalo fuerte para cortarlo)" % g["nombre"]
	c._actualizar()
	await _foto("06_aviso")
	c._quitar_pv(g, int(g["hp_max"] * 0.3))
	await _foto("07_interrumpido")
	c.actor = c.heroes[0]
	c.menu.heroe_actual = c.heroes[0]
	c.heroes[1]["atb"] = 60.0
	c._menu_magia(9)
	await _foto("08_duo_filo_arcano")
	print("FIN")
	quit(0)
