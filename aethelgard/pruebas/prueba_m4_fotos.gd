extends SceneTree
# Capturas (CON VENTANA) de M4 (los niveles III) y de C2 (armas especiales), iguales para antes y después: la misma
# semilla y el mismo guion. Las artes se lanzan con _lanzar_arte (existe en las dos versiones): antes, los III se
# aplicaban sin su seña propia, la Brasa no levantaba y las armas no hacían nada.
#   Kael 20, Lya 18 y Garon 20 contra Grimfang (zona Ceniza: nadie huye solo): la pestaña del Alba con la Hora Dorada;
#   la Hora Dorada; el Invierno Guardián; Grimfang rompe la coraza helada de Kael; la Última Brasa; Kael cae y se levanta;
#   Garon con las Fauces golpea (y se cura); Kael con la Guardiana en guardia recibe un golpe (y lo devuelve).
# Uso: -- <carpeta de salida>. Datos aislados; el combate no guarda.

const ARCHIVO := "user://prueba_m4_fotos.save"

var P
var G
var I
var X
var salida := ""
var c = null
var congelar := true
var fotos := 0
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	X = load("res://equipo_extra.gd")
	var args := OS.get_cmdline_user_args()
	salida = args[0] if not args.is_empty() and not args[0].contains("=") else "user://fotos_m4"
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


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _hasta(cond: Callable, max := 600) -> bool:
	for i in max:
		if cond.call():
			return true
		await _esperar(1)
	return cond.call()


func _libre() -> bool:
	return c.estado == "esperando" or c.estado == "menu"


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


func _actua(e: Dictionary, foto: String) -> void:
	for h in c.heroes:
		h["atb"] = 0.0
	for i in range(c.cola.size() - 1, -1, -1):
		if c.cola[i].get("hero", false):
			c.cola.remove_at(i)
	congelar = false
	e["atb"] = 99.9
	var pv := {}
	var bar := {}
	for h in c.heroes:
		pv[h["nombre"]] = h["hp"]
		bar[h["nombre"]] = int(h.get("barrera", 0))
	var hecho := false
	for i in 900:
		if not hecho and c.heroes.any(func(h): return h["hp"] != pv[h["nombre"]] or int(h.get("barrera", 0)) != int(bar[h["nombre"]])):
			hecho = true
			await _esperar(6)
			await _foto(foto)
		if c.estado == "menu" and c.menu.activo:
			c._defender()
		if hecho and _libre():
			break
		await _esperar(1)
	if not hecho:
		await _foto(foto)
	congelar = true


func _probar() -> void:
	await _esperar(10)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "inventario"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in {"Kael": 20, "Lya": 18, "Garon": 20}:
		G.datos()[n]["nivel"] = {"Kael": 20, "Lya": 18, "Garon": 20}[n]
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	for q in [["Garon", "arma", "fauces_gorthor"], ["Kael", "arma", "guardiana_ambar"]]:
		X.conseguir(q[2])
		I.equipar(q[0], q[1], q[2])
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("fondo_combate", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 9)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(20261109)
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	var garon := _heroe("Garon")
	var grim: Dictionary = c.enemigos[0]
	grim["hp"] = 2000
	grim["hp_max"] = 2000
	if not await _turno_de("Kael"):
		return _fin()
	c._menu_magia(4)
	await _esperar(15)
	await _foto("01_alba_kael_20")
	c._lanzar_arte("Alba", 3, [lya, garon])
	await _hasta(func(): return lya["atb"] > 90.0, 200)
	await _esperar(12)
	await _foto("02_hora_dorada")
	await _hasta(_libre, 400)
	if not await _turno_de("Kael"):
		return _fin()
	c._lanzar_arte("Escarcha", 3, [kael, lya, garon])
	await _hasta(func(): return int(kael.get("barrera", 0)) > 0, 200)
	await _esperar(14)
	await _foto("03_invierno_guardian")
	await _hasta(_libre, 400)
	kael["barrera"] = 2
	for h in c.heroes:                               # que Grimfang vaya a Kael (el más débil)
		if h != kael:
			h["barrera"] = 0
	kael["hp"] = 60
	await _actua(grim, "04_coraza_helada_rota")
	await _esperar(20)
	if not await _turno_de("Lya"):
		return _fin()
	c._lanzar_arte("Lumbre", 3, [kael, lya, garon])
	await _hasta(func(): return float(kael.get("brasa", 0.0)) > 0.0, 200)
	await _esperar(14)
	await _foto("05_ultima_brasa")
	await _hasta(_libre, 400)
	var real = c._quitar_pv(kael, 99999)
	c._golpe_visual(kael, 99999 if real == null else real, "")
	await _esperar(16)
	await _foto("06_kael_cae_con_brasa")
	await _esperar(30)
	if not await _turno_de("Garon"):
		return _fin()
	garon["hp"] = int(garon["hp_max"] * 0.5)
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(grim)
	var e0: int = grim["hp"]
	await _hasta(func(): return grim["hp"] < e0, 300)
	await _esperar(8)
	await _foto("07_fauces_golpe")
	await _hasta(_libre, 400)
	_fin()


func _fin() -> void:
	print("fotos: %d" % fotos)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
