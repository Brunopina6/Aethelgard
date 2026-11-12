extends SceneTree
# Capturas de la magia negra (V12, fase E, 12/11), para que las revise una persona. Con ventana.
# Uso: «-- salida=<carpeta>». Enciende el interruptor de desarrollo (magia_negra_v12 = Kael, todo) solo en esta prueba:
# Kael (nivel 12), Lya y Garon contra tres Slimes (con vida de sobra, para que nadie caiga entre capturas).
#   00-09: el menú: pestañas con la de magia negra (y el DÚO), lista de escuelas, la página de cada escuela, el panel de
#          objetivo con «Débil», Kael preparando (círculo e icono de reloj de arena) y los estados sobre los enemigos.
#   e_<forma>_1..3: cada efecto en tres momentos (los avanzados se ven distintos de los básicos de su escuela).
# No toca la partida de verdad (archivo propio y sin guardar).

var c = null
var salida := ""
const MN := preload("res://magia_negra.gd")


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_magia_negra")
	Engine.set_meta("archivo_partida_prueba", "user://fotos_magia_negra.save")
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String, espera := 8, jpg := false) -> void:
	await _esperar(espera)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(salida)
	if jpg:
		img.save_jpg(salida.path_join(nombre + ".jpg"), 0.85)
	else:
		img.save_png(salida.path_join(nombre + ".png"))
	print("FOTO ", nombre)


func _probar() -> void:
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 12
		G.datos()[n]["libros"] = {}
	Engine.set_meta("magia_negra_v12", "Kael")
	Engine.set_meta("magia_negra_v12_todo", true)
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("grupo_combate", 1)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(90)
	c.set_process(false)
	for e in c.enemigos:
		e["hp_max"] = 4000
		e["hp"] = 4000
	var kael: Dictionary = c.heroes[0]
	kael["mp_max"] = 300
	kael["mp"] = 300
	c.heroes[1]["atb"] = 60.0                       # Lya con media barra: el DÚO sale en las pestañas
	c.actor = kael
	c._mostrar_menu()
	await _foto("00_menu")
	c._menu_magia(1)
	await _foto("01_pestanas_magia")
	c._menu_magia(c.PESTANA_NEGRA)
	await _foto("02_lista_escuelas")
	c._pagina_escuelas(1)
	await _foto("02b_lista_escuelas_pagina2")
	c._pagina_escuelas(0)
	var i := 3
	for fam in MN.ESCUELAS:
		c._menu_escuela(fam)
		await _foto("%02d_escuela_%s" % [i, fam.substr(6)])
		i += 1
	c._menu_escuela("negra_debilitamiento", 1)
	await _foto("08b_escuela_debilitamiento_pagina2")
	c._menu_escuela("negra_hielo")
	c._elegir_negra("negra_hielo", 1)
	await _foto("09_objetivo_debil_hielo")
	c._limpiar_objetivo()
	c._menu_escuela("negra_gravedad")
	c._elegir_negra("negra_gravedad", 1)
	await _foto("10_objetivo_resiste_gravedad")
	c._limpiar_objetivo()
	# preparando: el círculo se queda y el HUD enseña el reloj de arena
	c.actor = kael
	c._lanzar_negra("negra_fuego", 4, c.enemigos.duplicate())
	await _foto("11_prepara_sol_de_ceniza", 30)
	c._conjuro_roto(kael)
	kael.erase("conjuro")
	await _esperar(40)
	# estados sobre los enemigos
	MN.aplicar_estado(c.enemigos[0], "lento", 2)
	MN.aplicar_estado(c.enemigos[0], "def_baja", 3)
	MN.aplicar_estado(c.enemigos[1], "marca", 3)
	c._marca_visual(c.enemigos[1])
	MN.aplicar_estado(c.enemigos[2], "prision", 1)
	c._prision_visual(c.enemigos[2])
	c._actualizar()
	await _foto("12_estados_enemigos")
	for e in c.enemigos:
		e.erase("mn")
		c._quitar_nodo_negra(e, "mn_marca_nodo")
		c._quitar_nodo_negra(e, "mn_prision_nodo")
	c._ocultar_menu()
	await _esperar(30)
	# efectos: cada hechizo, en tres momentos
	for fam in MN.ESCUELAS:
		for nv in range(1, MN.cuantos(fam) + 1):
			var d: Dictionary = MN.datos(fam, nv)
			var objs: Array = c.enemigos.duplicate() if d["a"] == "enemigos" else [c.enemigos[1]]
			c.actor = kael
			c._resolver_negra(kael, fam, nv, objs)
			var t0 := 0
			for k in 3:
				var hasta: int = [24, 40, 58][k]
				await _esperar(hasta - t0)
				t0 = hasta
				await _foto("e_%s_%d_%s_%d" % [fam.substr(6), nv, d["forma"], k + 1], 0, true)
			await _esperar(90)
			for e in c.enemigos:
				e["hp"] = e["hp_max"]
				e["quemadura"] = 0
				e.erase("mn")
				c._quitar_nodo_negra(e, "mn_marca_nodo")
				c._quitar_nodo_negra(e, "mn_prision_nodo")
				c._apagar_llama(e)
			c._actualizar()
	print("FOTOS EN ", salida)
	quit(0)
