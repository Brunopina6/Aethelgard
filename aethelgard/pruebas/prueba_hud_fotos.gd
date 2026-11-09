extends SceneTree
# Capturas (CON VENTANA) del HUD de combate (T-099, y la parte de T-100 y T-101 que va en el HUD), para compararlas
# antes y después: el mismo guion, los mismos combates y los mismos momentos, con la semilla fija. Solo usa funciones
# que ya existían antes del cambio, para que la misma prueba saque las fotos de las dos versiones.
#   A. Grupo de tres (Kael, Lya y Garon, nivel 10) contra Slime, Grimfang y Slime: el menú de Kael, su magia, la pestaña
#      del Alba, elegir a Lya para el Compás y el anillo; el turno de un enemigo (el menú cerrado); Garon (menú, Esgrima
#      y después de Juicio); Lya con la Armonía llena; Kael con 0 PM y Lya caída, con el mando sobre MAGIA apagada.
#   B. Kael y Lya: el Compás apagado porque Lya ya espera su turno (y el mando sobre él), Peso del Ocaso, la Lumbre de
#      Retorno (quién vuelve) y Segundo Aliento (su duración).
#   C. Kael solo: el menú y el Compás apagado («Kael va solo»).
# Uso: -- <carpeta de salida> [movil]. Con «movil», el combate usa la calidad del móvil (menos partículas): sirve para
# ver las señas de las artes en el perfil bajo. Datos aislados (ejecutar_pruebas.ps1 -Manual, o con APPDATA propio); el
# combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo. Los enemigos no actúan salvo cuando la
# prueba lo pide (les vacía la barra): se miran el HUD y los efectos, no el equilibrio.

const ARCHIVO := "user://prueba_hud_fotos.save"
const SEMILLA := 20261109
const BOTONES := {"aceptar": JOY_BUTTON_A, "abajo": JOY_BUTTON_DPAD_DOWN, "arriba": JOY_BUTTON_DPAD_UP}

var P
var G
var salida := ""
var c = null
var congelar := true                              # los enemigos esperan (la barra a 0 en cada fotograma)
var fotos: Array = []
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	var args := OS.get_cmdline_user_args()
	salida = args[0] if not args.is_empty() and not args[0].contains("=") and args[0] != "movil" else "user://fotos_hud"
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


func _pulsar(que: String) -> void:
	for pulsado in [true, false]:
		var b := InputEventJoypadButton.new()
		b.device = 0
		b.button_index = BOTONES[que]
		b.pressed = pulsado
		Input.parse_input_event(b)
		await _esperar(2)
	await _esperar(4)


# Espera al menú de un héroe; a los demás los pone en guardia.
func _turno_de(n: String) -> bool:
	for i in 2400:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(14)
				return true
			c._defender()
		await _esperar(1)
	fallos.append("no llega el turno de " + n)
	return false


# Espera a que se cumpla «cond» (como mucho «max» fotogramas) y después «despues» fotogramas más.
func _hasta(cond: Callable, despues: int, max := 300) -> bool:
	for i in max:
		if cond.call():
			await _esperar(despues)
			return true
		await _esperar(1)
	return false


func _combate(activos: Dictionary, zona: String, grupo: int) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	congelar = true
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(SEMILLA)                                   # como la huella: después de _ready
	for e in c.enemigos:
		e["atb"] = 0.0


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(6)


func _probar() -> void:
	await _esperar(10)                              # el paso de --fixed-fps 30 se asienta en los primeros fotogramas
	await _tres()
	await _cerrar()
	await _dos()
	await _cerrar()
	await _uno()
	await _cerrar()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("fotos: %d en %s" % [fotos.size(), salida])
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- A. grupo de tres
func _tres() -> void:
	_combate({"Kael": 10, "Lya": 10, "Garon": 10}, "desierto", 2)
	if not await _turno_de("Kael"):
		return
	await _foto("01_tres_menu_kael")                 # el menú de órdenes y el grupo (PV, PM, ATB) y la Armonía
	c._menu_magia(1)
	await _esperar(15)
	await _foto("02_tres_magia_kael")                # submenú con su explicación: no debe chocar con el grupo
	c._menu_magia(4)
	await _esperar(15)
	await _foto("03_tres_alba_kael")
	var lya := _heroe("Lya")
	c._elegir_hechizo("Alba", 1)
	await _esperar(15)
	await _foto("04_tres_compas_objetivo")           # «TOCA A UN ALIADO»: la flecha sobre Lya
	var atb0: float = lya["atb"]
	c._confirmar_objetivo(lya)
	if await _hasta(func(): return lya["atb"] > atb0 + 30.0, 12, 200):
		await _foto("05_tres_compas_anillo")         # el efecto sobre Lya, 12 fotogramas después de aplicarse
	else:
		fallos.append("A: el Compás no llega a Lya")
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 0, 300)
	# un enemigo actúa: el menú cerrado y el grupo a la vista (si antes le toca a un héroe, se pone en guardia)
	congelar = false
	for e in c.enemigos:
		e["atb"] = 0.0
	var grim = c.enemigos.filter(func(e): return e["nombre"].begins_with("Grimfang"))
	if not grim.is_empty():
		grim[0]["atb"] = 99.9
	var llega := false
	for i in 300:
		if c.estado == "enemigo":
			llega = true
			break
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			c._defender()
		await _esperar(1)
	if llega:
		await _esperar(16)
		await _foto("06_tres_turno_enemigo")
	else:
		fallos.append("A: no llega el turno del enemigo")
	await _hasta(func(): return c.estado != "enemigo", 0, 400)
	congelar = true
	# Garon: su menú, Esgrima y después de Juicio (sus PM)
	if not await _turno_de("Garon"):
		return
	await _foto("07_garon_menu")
	c._menu_esgrima()
	await _esperar(15)
	await _foto("08_garon_esgrima")
	var obj = c.enemigos.filter(func(e): return e["hp"] > 0)[0]
	var pv0: int = obj["hp"]
	c._tecnica_garon("Juicio", obj)
	if await _hasta(func(): return obj["hp"] < pv0, 10, 300):
		await _foto("09_garon_tras_juicio")          # el menú cerrado: los PM que le quedan a Garon
	else:
		fallos.append("A: Juicio no llega")
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 0, 400)
	# Lya con la Armonía llena: Érebo se puede invocar
	c.armonia = 1.0
	c.menu.poner_armonia(1.0)
	if not await _turno_de("Lya"):
		return
	c.armonia = 1.0
	c.menu.poner_armonia(1.0)
	c._mostrar_menu()
	await _esperar(20)
	await _foto("10_lya_erebo_listo")
	c._defender()
	# Kael con 0 PM y Lya caída: MAGIA e INVOCACIÓN apagadas (y el mando sobre MAGIA)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	kael["mp"] = 0
	c._quitar_pv(lya, 99999)
	c._restablecer_color(lya)
	if c._p3d(lya) != null:
		c._p3d(lya).morir()
	c.armonia = 1.0
	c.menu.poner_armonia(1.0)
	c._mostrar_menu()
	await _esperar(20)
	await _foto("11_kael_0pm_lya_caida")
	await _pulsar("abajo")                           # con el mando, de ATACAR hacia abajo
	await _esperar(10)
	await _foto("12_mando_sobre_magia")
	c._menu_magia(1)
	await _esperar(15)
	await _foto("13_kael_0pm_magia")                 # las magias que no puede pagar
	c._mostrar_menu()
	await _esperar(6)


# ---------------------------------------------------------------- B. Kael y Lya
func _dos() -> void:
	_combate({"Kael": 9, "Lya": 10}, "desierto", 8)
	if not await _turno_de("Kael"):
		return
	var lya := _heroe("Lya")
	var kael := _heroe("Kael")
	lya["atb"] = 99.95                                # Lya ya espera su turno (entra en la cola por el camino normal)
	await _esperar(3)
	c._menu_magia(4)
	await _esperar(15)
	await _foto("14_dos_compas_lya_espera")
	await _pulsar("arriba")                          # con el mando, a la fila del Compás
	await _esperar(10)
	await _foto("15_mando_sobre_compas")
	var atb_e: float = c.enemigos[0]["atb"]
	for e in c.enemigos:
		e["atb"] = 60.0
	congelar = false
	c._elegir_hechizo("Alba", 2)
	if await _hasta(func(): return c.enemigos[0]["atb"] < 40.0, 10, 200):
		await _foto("16_peso_del_ocaso")
	else:
		fallos.append("B: Peso del Ocaso no retrasa a los enemigos (%s)" % atb_e)
	congelar = true
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 0, 300)
	# Lumbre de Retorno: Kael cae y Lya lo levanta
	if not await _turno_de("Lya"):
		return
	c._quitar_pv(kael, 99999)
	c._restablecer_color(kael)
	if c._p3d(kael) != null:
		c._p3d(kael).morir()
	c._actualizar()
	await _esperar(30)
	c._menu_magia(4)
	await _esperar(15)
	await _foto("17_lumbre_lista")
	c._elegir_hechizo("Lumbre", 1)
	await _esperar(12)
	c._confirmar_objetivo(kael)
	if await _hasta(func(): return kael["hp"] > 0, 14, 200):
		await _foto("18_lumbre_quien_vuelve")
	else:
		fallos.append("B: la Lumbre no levanta a Kael")
	await _hasta(func(): return c.estado == "esperando" or c.estado == "menu", 0, 300)
	# Segundo Aliento y su duración
	if not await _turno_de("Lya"):
		return
	kael["hp"] = int(kael["hp_max"] * 0.5)
	c._actualizar()
	c._elegir_hechizo("Lumbre", 2)
	if await _hasta(func(): return int(kael.get("aliento", 0)) > 0, 10, 200):
		await _foto("19_segundo_aliento")
	else:
		fallos.append("B: Segundo Aliento no llega")
	if not await _turno_de("Kael"):
		return
	await _foto("20_aliento_turnos")                 # Kael se ha curado al empezar su turno: le quedan dos


# ---------------------------------------------------------------- C. Kael solo
func _uno() -> void:
	_combate({"Kael": 5}, "llanura", 7)
	if not await _turno_de("Kael"):
		return
	await _foto("21_solo_menu")
	c._menu_magia(4)
	await _esperar(15)
	await _foto("22_solo_compas")
