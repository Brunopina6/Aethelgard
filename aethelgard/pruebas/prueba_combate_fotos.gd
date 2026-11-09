extends SceneTree
# Capturas (CON VENTANA) de lo nuevo de T-091 y T-092 para revisarlo a ojo: las pestañas de las artes en el menú de
# magia, lanzar el Compás del Alba, el Segundo Aliento y su icono de estado, la Lumbre de Retorno, la ranura Accesorio
# del menú Grupo, las artes en Habilidades y la tienda con los libros y el Farol. Datos aislados (ejecutar_pruebas.ps1
# -Manual, o con APPDATA propio); el combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo.
# Uso: -- <carpeta de salida>. Los enemigos no actúan mientras se fotografía (la prueba les vacía la barra): solo se
# miran los menús y los efectos, no el equilibrio.

const ARCHIVO := "user://prueba_combate_fotos.save"

var P
var G
var I
var salida := ""
var c = null
var fotos: Array = []
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	var args := OS.get_cmdline_user_args()
	salida = args[0] if not args.is_empty() and not args[0].contains("=") else "user://fotos_combate"
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if c != null and is_instance_valid(c):
			for e in c.enemigos:                       # los enemigos esperan: solo se miran los menús y los efectos
				e["atb"] = 0.0


func _foto(nombre: String) -> void:
	await _esperar(2)
	var img := root.get_viewport().get_texture().get_image()
	var ruta := salida.path_join(nombre + ".png")
	if img == null or img.is_empty() or img.save_png(ruta) != OK:
		fallos.append("no se pudo guardar " + ruta)
		return
	fotos.append(ruta)
	print("foto: ", ruta, " (", img.get_width(), " × ", img.get_height(), ")")


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


# Espera al menú de un héroe; a los demás los pone en guardia.
func _turno_de(n: String) -> bool:
	for i in 1800:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(12)
				return true
			c._defender()
		await _esperar(1)
	fallos.append("no llega el turno de " + n)
	return false


func _probar() -> void:
	await _esperar(5)
	await _combate()
	await _menus()
	await _tienda()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("fotos: %d en %s" % [fotos.size(), salida])
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _combate() -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 8)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	if not await _turno_de("Kael"):
		return
	c._menu_magia(1)
	await _esperar(15)
	await _foto("01_magia_kael_nivel_I")             # I · II · III y, detrás, el icono del Alba (apagado)
	c._menu_magia(3)
	await _esperar(15)
	await _foto("01b_magia_kael_nivel_III")          # las de siempre: Infierno y Cólera del Cielo (el nombre más largo)
	c._menu_magia(4)
	await _esperar(15)
	await _foto("02_magia_kael_alba")                # la pestaña del Alba: Compás y Peso del Ocaso
	c._elegir_hechizo("Alba", 1)
	await _esperar(15)
	await _foto("03_compas_elegir_aliado")           # «TOCA A UN ALIADO»: la flecha sobre Lya
	c._confirmar_objetivo(_heroe("Lya"))
	for i in 90:
		if c.registro.text == "Kael lanza Compás del Alba" and i > 40:
			break
		await _esperar(1)
	await _foto("04_compas_lanzado")
	if not await _turno_de("Lya"):
		return
	_heroe("Kael")["hp"] = int(_heroe("Kael")["hp_max"] * 0.55)
	c._actualizar()
	c._menu_magia(4)
	await _esperar(15)
	await _foto("05_magia_lya_lumbre")               # Lumbre de Retorno apagada («Nadie ha caído.») y Segundo Aliento
	c._elegir_hechizo("Lumbre", 2)
	await _esperar(55)
	await _foto("06_segundo_aliento")
	if not await _turno_de("Kael"):
		return
	await _foto("07_iconos_aliento")                 # la hoja del Aliento junto a los nombres; Kael se cura al empezar
	c._defender()
	if not await _turno_de("Lya"):
		return
	var kael := _heroe("Kael")
	c._quitar_pv(kael, 99999)                        # Kael cae (como si le hubieran golpeado)
	c._restablecer_color(kael)
	c._actualizar()
	await _esperar(30)
	c._menu_magia(4)
	await _esperar(15)
	await _foto("08_lumbre_de_retorno_lista")
	c._elegir_hechizo("Lumbre", 1)
	await _esperar(12)
	c._confirmar_objetivo(kael)
	await _esperar(70)
	await _foto("09_lumbre_de_retorno_vuelve")       # Kael se levanta con un cuarto de su vida
	c.queue_free()
	c = null
	await _esperar(5)


func _menus() -> void:
	_limpiar()
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	G.datos()["Kael"]["nivel"] = 9
	G.datos()["Lya"]["nivel"] = 4
	I.agregar("farol_peregrino")
	I.equipar("Kael", "accesorio", "farol_peregrino")
	for p in ["Grupo", "Habilidades", "Objetos"]:
		var m = load("res://menus.gd").new()
		m.pestana = p
		root.add_child(m)
		await _esperar(15)
		await _foto({"Grupo": "10_grupo_accesorio", "Habilidades": "11_habilidades_artes", "Objetos": "12_objetos_equipo"}[p])
		m.queue_free()
		await _esperar(3)


func _tienda() -> void:
	_limpiar()
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad", "zona": "llanura", "texto": "x"})
	I.ganar_oro(600)
	for p in ["Magias", "Equipo"]:
		var t = load("res://tienda.gd").new()
		t.pestana = p
		root.add_child(t)
		await _esperar(15)
		await _foto({"Magias": "13_tienda_libros", "Equipo": "14_tienda_oakhaven_farol"}[p])
		t.queue_free()
		await _esperar(3)
