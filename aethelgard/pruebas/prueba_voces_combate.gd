extends SceneTree
# Las voces de los héroes en combate (sonido.gd, tanda 5), en un combate de verdad, sin ventana y con datos aislados:
# el esfuerzo de Kael al saltar y el de Lya al golpear, una vez por ataque; el alivio al tomar una Poción que cura PV
# (y nada con el Éter); la Cura (magia protegida, D-048) no pide alivio; y el gesto de victoria, una vez al ganar.
# Se mira lo que pide combate.gd (señal «voz_pedida»), no lo que suena. El combate no guarda.

const ARCHIVO := "user://prueba_voces_combate.save"

var P
var G
var I
var c = null
var congelar := true
var voces: Array = []                             # [quién, evento]
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if congelar and c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


func _hasta(cond: Callable, max := 600) -> bool:
	for i in max:
		if cond.call():
			return true
		await _esperar(1)
	return cond.call()


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _turno_de(n: String) -> bool:
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(3)
				return true
			c._defender()
		await _esperar(1)
	_ok(false, "no llega el turno de " + n)
	return false


func _libre() -> bool:
	return c.estado == "esperando" or c.estado == "menu" or c.estado == "fin"


func _cuenta(quien: String, evento: String) -> int:
	return voces.filter(func(v): return v[0] == quien and v[1] == evento).size()


func _probar() -> void:
	await _esperar(10)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "inventario"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 9)
	c = load("res://combate.tscn").instantiate()
	c.voz_pedida.connect(func(q: String, ev: String): voces.append([q, ev]))
	root.add_child(c)
	seed(20261109)
	var grim: Dictionary = c.enemigos[0]
	grim["hp"] = 3000
	grim["hp_max"] = 3000
	# Kael salta (una voz) y Lya golpea (una voz)
	if await _turno_de("Kael"):
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(grim)
		await _hasta(_libre, 400)
		_ok(_cuenta("Kael", "ataque") == 1, "Kael: su esfuerzo se pide %d veces en un ataque" % _cuenta("Kael", "ataque"))
	if await _turno_de("Lya"):
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(grim)
		await _hasta(_libre, 400)
		_ok(_cuenta("Lya", "ataque") == 1, "Lya: su esfuerzo se pide %d veces en un ataque" % _cuenta("Lya", "ataque"))
	# Poción (alivio) y Éter (nada)
	if await _turno_de("Kael"):
		var kael := _heroe("Kael")
		kael["hp"] = int(kael["hp_max"] * 0.4)
		I.agregar_objeto("Poción", 1)
		c._usar_objeto("Poción", kael)
		await _hasta(_libre, 400)
		_ok(_cuenta("Kael", "alivio") == 1, "Poción: el alivio se pide %d veces" % _cuenta("Kael", "alivio"))
	if await _turno_de("Lya"):
		var lya := _heroe("Lya")
		lya["mp"] = 1
		I.agregar_objeto("Éter", 1)
		c._usar_objeto("Éter", lya)
		await _hasta(_libre, 400)
		_ok(_cuenta("Lya", "alivio") == 0, "Éter: pide un alivio")
	# la Cura (magia protegida) no pide alivio
	if await _turno_de("Lya"):
		var kael2 := _heroe("Kael")
		kael2["hp"] = int(kael2["hp_max"] * 0.4)
		var antes := voces.size()
		c._elegir_hechizo("Cura", 1, true)
		await _hasta(_libre, 400)
		_ok(voces.slice(antes).all(func(v): return v[1] != "alivio"), "Cura: pide un alivio (D-048: no)")
	# victoria: el gesto, una vez
	grim["hp"] = 1
	if await _turno_de("Kael"):
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(grim)
		await _hasta(func(): return c.estado == "fin", 400)
		await _esperar(10)
		_ok(_cuenta("", "victoria") == 1, "victoria: el gesto se pide %d veces" % _cuenta("", "victoria"))
	c.queue_free()
	await _esperar(5)
	print("voces: ", voces)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
