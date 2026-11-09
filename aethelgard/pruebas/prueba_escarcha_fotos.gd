extends SceneTree
# Capturas (CON VENTANA) de M3 (la Escarcha de Kael) y de la Guardia de Garon, para compararlas antes y después con el
# mismo guion y la misma semilla. Solo llama a lo nuevo si existe (has_method), así la misma prueba vale para la versión
# de antes: allí la Coraza se lanza por la ruta de las artes (con el dibujo genérico) pero no absorbe, y Garon no tiene
# Guardia (la embestida le da a Kael).
#   1. Kael (nivel 12): el menú de magia y la pestaña de la Escarcha; la Coraza sobre sí mismo; un golpe que absorbe y
#      otro que la rompe.
#   2. Kael, Lya y Garon contra Zarzalín: Esgrima de Garon; la Guardia sobre Kael; la embestida anunciada; el HUD.
# Uso: -- <carpeta de salida>. Datos aislados; el combate no guarda.

const ARCHIVO := "user://prueba_escarcha_fotos.save"

var P
var G
var salida := ""
var c = null
var congelar := true
var fotos := 0
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	var args := OS.get_cmdline_user_args()
	salida = args[0] if not args.is_empty() and not args[0].contains("=") else "user://fotos_escarcha"
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if congelar and c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


func _foto(nombre: String) -> void:
	await _esperar(2)
	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty() or img.save_png(salida.path_join(nombre + ".png")) != OK:
		fallos.append("no se pudo guardar " + nombre)
		return
	fotos += 1
	print("foto: ", nombre)


func _combate(activos: Dictionary, grupo: int) -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	congelar = true
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(20261109)


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(6)


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _turno_de(n: String) -> bool:
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(14)
				return true
			c._defender()
		await _esperar(1)
	fallos.append("no llega el turno de " + n)
	return false


func _hasta(cond: Callable, max := 600) -> bool:
	for i in max:
		if cond.call():
			return true
		await _esperar(1)
	return cond.call()


func _probar() -> void:
	await _esperar(10)
	await _escarcha()
	await _cerrar()
	await _guardia()
	await _cerrar()
	print("fotos: %d" % fotos)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _escarcha() -> void:
	_combate({"Kael": 12}, 9)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	c._menu_magia(1)
	await _esperar(15)
	await _foto("01_magia_kael_nivel_12")             # antes: I · II · III y el Alba; después, también la Escarcha
	c._menu_magia(5)
	await _esperar(15)
	await _foto("02_pestana_escarcha")
	c._lanzar_arte("Escarcha", 1, [kael])
	var b0: int = int(kael.get("barrera", 0))
	if await _hasta(func(): return int(kael.get("barrera", 0)) != b0, 200):
		await _esperar(12)
	await _foto("03_coraza")
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 400)
	var r1 = c._quitar_pv(kael, 20)                    # un golpe que la coraza absorbe entero (antes: le llega a los PV)
	c._golpe_visual(kael, 20 if r1 == null else r1, "")
	await _esperar(8)
	await _foto("04_coraza_absorbe")
	await _esperar(30)
	var resto := int(kael.get("barrera", 0)) + 25
	var real = c._quitar_pv(kael, resto)
	c._golpe_visual(kael, real if real != null else resto, "")
	await _esperar(10)
	await _foto("05_coraza_rota")
	await _esperar(20)


func _guardia() -> void:
	_combate({"Kael": 4, "Lya": 4, "Garon": 5}, 10)
	var z: Dictionary = c.enemigos[0]
	if not await _turno_de("Garon"):
		return
	var kael := _heroe("Kael")
	c._menu_esgrima()
	await _esperar(15)
	await _foto("06_esgrima_garon")                  # después, con la Guardia
	z["cargando"] = true                             # Zarzalín ya avisó: embestirá a Kael
	z["objetivo_carga"] = kael
	if c.has_method("_guardia"):
		c._guardia(kael)
		await _esperar(14)
	else:
		c._defender()
		await _esperar(14)
	await _foto("07_guardia_sobre_kael")
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 400)
	for h in c.heroes:
		h["atb"] = 0.0
	for i in range(c.cola.size() - 1, -1, -1):
		if c.cola[i].get("hero", false):
			c.cola.remove_at(i)
	var zp = c._p3d(z)
	var golpe := [false]
	if zp != null:
		zp.impacto.connect(func(_a): golpe[0] = true)
	congelar = false
	z["atb"] = 99.9
	if await _hasta(func(): return golpe[0], 600):
		await _esperar(6)
		await _foto("08_embestida")                  # antes, a Kael; después, a Garon, que le cubre
	congelar = true
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 400)
	await _esperar(20)
	await _foto("09_despues_de_la_embestida")
