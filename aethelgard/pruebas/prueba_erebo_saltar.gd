extends SceneTree
# Saltar la invocación de Érebo en cualquier momento no cuelga el combate (aviso de animaciones, 09/11): con la de
# siempre, saltarla durante el aplastamiento del orbe dejaba la coreografía esperando un tween que limpiar() había
# matado, y combate.gd esperaba a que acabara. Se salta en cuatro momentos (al surgir Érebo, al meter la mano, al
# sostener el orbe y durante el aplastamiento) y en cada uno: el resultado se aplica una vez, el combate vuelve a su
# curso (estado «esperando» o «menu») y el tiempo vuelve a 1. Sin ventana, con datos aislados y «erebo=exito».

const ARCHIVO := "user://prueba_erebo_saltar.save"
const MOMENTOS := ["invocacion", "penetra", "sostiene", "pulso"]

var P
var G
var c = null
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _probar() -> void:
	await _esperar(10)
	for m in MOMENTOS:
		await _saltar_en(m)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _saltar_en(momento: String) -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 9)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	var grim: Dictionary = c.enemigos[0]
	var aplicado := [0]
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await _esperar(1)
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % momento)
		c.queue_free()
		await _esperar(5)
		return
	c.armonia = 1.0
	var pv0: int = grim["hp"]
	c._invocar_sobre(grim)
	var visto := [false]
	var conectado := false
	for i in 900:                                    # espera a la invocación y a su momento
		if not conectado and c.inv_erebo != null:
			conectado = true
			c.inv_erebo.evento.connect(func(n: String): if n == momento: visto[0] = true)
			if c.inv_erebo.erebo != null:
				c.inv_erebo.erebo.evento.connect(func(n: String): if n == momento: visto[0] = true)
		if conectado and c.inv_erebo != null and c.inv_erebo.erebo != null and not c.inv_erebo.erebo.evento.is_connected(_nada):
			c.inv_erebo.erebo.evento.connect(_nada)
			c.inv_erebo.erebo.evento.connect(func(n: String): if n == momento: visto[0] = true)
		if visto[0]:
			break
		await process_frame
	_ok(visto[0], "%s: la invocación no llega a ese momento" % momento)
	if visto[0] and c.inv_erebo != null:
		await process_frame
		c.inv_erebo.saltar()                         # como al tocar la pantalla
	var vuelve := false
	for i in 600:
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			vuelve = true
			break
		await process_frame
	_ok(vuelve, "%s: saltar la invocación cuelga el combate (estado %s)" % [momento, c.estado])
	_ok(is_equal_approx(Engine.time_scale, 1.0), "%s: el tiempo no vuelve a 1 (%s)" % [momento, Engine.time_scale])
	_ok(grim["hp"] < pv0 or grim["hp"] <= 0, "%s: el resultado (éxito forzado) no se aplica" % momento)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
	hechos.append(momento)


func _nada(_n: String) -> void:
	pass
