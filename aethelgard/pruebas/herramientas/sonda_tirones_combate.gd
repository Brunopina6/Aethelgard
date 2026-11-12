extends SceneTree
# Sonda de los tirones del PRIMER combate (rend2, 12/11). CON ventana y datos aislados. Un combate normal con Kael, Lya y
# Garon; en el turno de Kael mide lo que cuesta la primera vez (y la segunda, ya caliente): la lista de objetivos
# («TOCA UN ENEMIGO») y el primer golpe con su destello y su número. Para cada paso: lo que tarda la llamada y los
# fotogramas siguientes (el de la llamada incluye compilar sombreadores y dibujar letras nuevas).
# Uso: Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/sonda_tirones_combate.gd --
#        salida=<carpeta> [etiqueta=x] [sin_precalentar] [con_carga] [piezas]
# «con_carga»: antes del combate se carga en Recursos lo mismo que carga.gd al arrancar (sin eso, la primera vez se
# leerían del disco cosas que en el juego ya están en memoria: medir_escenas.gd no lo hace).
# «sin_precalentar» quita el precalentado 2D del combate (combate.gd, _precalentar_2d) para medir el antes.

var salida := ""
var etiqueta := ""
var c = null
var res := {}
var nuevos: Array = []                     # nodos que entran en el árbol en cada fotograma de la medida


func _nodo(nd: Node) -> void:
	if nuevos.size() > 0 and nuevos[-1].size() < 16:
		nuevos[-1].append("%s:%s" % [nd.get_class(), String(nd.name).left(24)])


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a == "sin_precalentar":
			Engine.set_meta("sin_precalentar_2d", true)
	if salida == "":
		salida = OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Engine.set_meta("archivo_partida_prueba", "user://sonda_tirones.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("zona", "pastos")
	Engine.set_meta("tipo_combate", "normal")
	node_added.connect(_nodo)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		Engine.max_fps = 0                          # (el combate pone su tope de 30: se quita para ver lo que cuesta)
		if c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


# Lo que tarda «paso» y los 4 fotogramas siguientes (tiempo de reloj entre fotogramas, sin tope ni sincronía).
func _medir(nombre: String, paso: Callable, n := 4, atb := true) -> void:
	await _esperar(3)
	nuevos = [[]]
	var t0 := Time.get_ticks_usec()
	paso.call()
	var llamada := (Time.get_ticks_usec() - t0) / 1000.0
	var fot: Array = []
	var ant := Time.get_ticks_usec()
	for i in n:
		await process_frame
		Engine.max_fps = 0
		if atb and c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0
		var ahora := Time.get_ticks_usec()
		fot.append(snappedf((ahora - ant) / 1000.0, 0.1))
		ant = ahora
		nuevos.append([])
	var peor: float = fot.max()
	var orden := fot.duplicate()
	orden.sort()
	res[nombre] = {"llamada_ms": snappedf(llamada, 0.1), "peor_fotograma_ms": peor, "en_el_fotograma": fot.find(peor),
		"mediana_ms": orden[orden.size() / 2], "fotogramas_ms": fot if n <= 8 else [],
		"nodos_antes_del_peor": nuevos[maxi(0, fot.find(peor) - 1)] + nuevos[fot.find(peor)]}
	print("SONDA %s: llamada %.1f ms, peor fotograma %.1f ms (n.º %d de %d), mediana %.1f" % [nombre, llamada, peor, fot.find(peor), n, orden[orden.size() / 2]])


func _turno_de(n: String) -> bool:
	for i in 1800:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(30)
				return true
			c._defender()
		await _esperar(1)
	return false


func _probar() -> void:
	await _esperar(5)
	var Dg = root.get_node_or_null("Recursos")
	if "con_carga" in OS.get_cmdline_user_args():      # como el arranque de verdad (carga.gd): lo común ya en Recursos
		var tc := Time.get_ticks_usec()
		var n := 0
		for ruta in Dg.listar():
			if not Dg.esta(ruta):
				var r = load(ruta)
				if r != null:
					Dg.guardar(ruta, r)
					n += 1
		res["carga_comun_ms"] = snappedf((Time.get_ticks_usec() - tc) / 1000.0, 1.0)
		res["carga_comun_archivos"] = n
		print("SONDA carga común: %d archivos en %.0f ms" % [n, res["carga_comun_ms"]])
		await _esperar(5)
	if Dg != null:
		Dg.precalentar_dialogos()
	var t0 := Time.get_ticks_usec()
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	res["ready_ms"] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
	if not await _turno_de("Kael"):
		print("FALLO: no llega el turno de Kael")
		quit(1)
		return
	var base: Array = []
	var ant := Time.get_ticks_usec()
	for i in 30:
		await process_frame
		var ahora := Time.get_ticks_usec()
		base.append((ahora - ant) / 1000.0)
		ant = ahora
	base.sort()
	res["fotograma_normal_ms"] = snappedf(base[base.size() / 2], 0.01)
	await _medir("objetivos_1", func(): c._menu_objetivo("atacar", ""))
	await _esperar(20)
	await _medir("volver_1", func(): c.volver_obj.call())
	await _esperar(20)
	await _medir("objetivos_2", func(): c._menu_objetivo("atacar", ""))
	await _esperar(20)
	if "piezas" in OS.get_cmdline_user_args():          # qué parte del primer ataque es la cara
		var kael_h: Dictionary = {}
		for h in c.heroes:
			if h["nombre"] == "Kael":
				kael_h = h
		var k = c._p3d(kael_h)
		for paso in [["mirar", func(): k.mirar(Vector3(-1, 0, 0.1), 0.15)], ["correr", func(): k.correr()],
				["reposo", func(): k.reposo()], ["prob_critico", func(): c.Extra.prob_critico(c.PROB_CRITICO, {})],
				["menu_cerrar", func(): c.menu.cerrar()], ["sonar_confirmar", func(): c.menu.sonar("confirmar")],
				["registro", func(): c.registro.text = "Kael ataca a Slime"], ["ocultar_panel", func(): c._ocultar_panel()],
				["limpiar_objetivo", func(): c._limpiar_objetivo()]]:
			var tp := Time.get_ticks_usec()
			paso[1].call()
			res["pieza_" + paso[0]] = snappedf((Time.get_ticks_usec() - tp) / 1000.0, 0.1)
			print("SONDA pieza %s: %.1f ms" % [paso[0], res["pieza_" + paso[0]]])
			await _esperar(5)
	# el primer ataque de verdad (animación, sonido, destello, número y vibración): 150 fotogramas
	await _medir("ataque_1", func(): c._confirmar_objetivo(c.objetivos_posibles[0]), 150)
	if not await _turno_de("Kael"):
		print("FALLO: no vuelve el turno de Kael")
		quit(1)
		return
	await _medir("objetivos_3", func(): c._menu_objetivo("atacar", ""))
	await _esperar(20)
	await _medir("ataque_2", func(): c._confirmar_objetivo(c.objetivos_posibles[0]), 150)
	var f := FileAccess.open(salida.path_join("sonda_%s_%s.json" % [Time.get_datetime_string_from_system().replace(":", ""), etiqueta]), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "\t"))
	f.close()
	print("SONDA FIN ", JSON.stringify(res))
	if FileAccess.file_exists("user://sonda_tirones.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sonda_tirones.save"))
	quit(0)
