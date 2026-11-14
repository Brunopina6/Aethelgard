extends SceneTree
# V12 (14/11): el orbe EXPERIMENTAL de Érebo (erebo_orbe_v12.gd), apagado por defecto, en un combate de verdad con
# datos aislados y «erebo=exito» (en la lista se pasa también con «erebo_nueva» para la otra invocación):
#   apagado     → en «orbe_fuera» no se crea nada y el resultado es el de siempre
#   encendido   → nace EN ese evento (el agarre), sobre el orbe, con su presupuesto de partículas; lanza la onda,
#                 se borra solo y el resultado (daño/muerte) es idéntico al apagado
#   saltar      → saltando la invocación con el efecto vivo no queda nada en el árbol
#   repetir     → tres invocaciones seguidas: nunca hay más de uno a la vez y al final ninguno
#   salir       → borrando el combate (cambio de escena) con el efecto vivo no queda nada
# No toca la partida real: archivo de partida de prueba y user:// aislado del ejecutor.

const ARCHIVO := "user://prueba_erebo_orbe_v12.save"

var P
var G
var EO
var c = null
var fallos: Array = []
var hechos: Array = []
var _max_vivos := 0


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	EO = load("res://erebo_orbe_v12.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _vivos() -> int:
	var n := 0
	for x in root.find_children("*", "Node3D", true, false):
		if x.get_script() == EO and not x.is_queued_for_deletion():
			n += 1
	return n


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		_max_vivos = maxi(_max_vivos, _vivos())
		if c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _probar() -> void:
	await _esperar(10)
	_ok(EO.permitido(), "la opción solo existe en Auditoría o editor y esta prueba corre en el editor")
	EO.elegir(false)
	var r0: Dictionary = await _invocar("apagado", "")
	EO.elegir(true)
	var r1: Dictionary = await _invocar("encendido", "")
	_ok(r0.get("muerte_o_dano") == r1.get("muerte_o_dano"), "el resultado cambia con el efecto (%s / %s)" % [r0, r1])
	await _invocar("saltar", "saltar")
	_max_vivos = 0
	for i in 3:
		await _invocar("repetir %d" % (i + 1), "")
	_ok(_max_vivos <= 1, "repetir: llegó a haber %d efectos a la vez" % _max_vivos)
	await _invocar("salir", "salir")
	EO.elegir(false)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _combate() -> Dictionary:
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
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await _esperar(1)
	return c.enemigos[0]


# modo: "" (hasta el final), "saltar" o "salir" (con el efecto vivo)
func _invocar(caso: String, modo: String) -> Dictionary:
	var grim: Dictionary = await _combate()
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % caso)
		c.queue_free()
		await _esperar(5)
		return {}
	c.armonia = 1.0
	var pv0: int = grim["hp"]
	var visto := {"orbe_fuera": false, "efecto": null, "frame_ok": false}
	c._invocar_sobre(grim)
	var conectado := false
	for i in 1200:
		if not conectado and c.inv_erebo != null and c.inv_erebo.erebo != null:
			conectado = true
			var er = c.inv_erebo.erebo
			er.evento.connect(func(n: String):
				if n == "orbe_fuera":
					visto["orbe_fuera"] = true
					visto["efecto"] = er._orbe_v12                       # creado en ESTE evento (la conexión de Érebo va antes)
					var ef = er._orbe_v12
					if ef != null and is_instance_valid(ef):
						visto["frame_ok"] = ef.global_position.distance_to(er.orbe.global_position) < 0.02
						visto["particulas"] = ef.numero_particulas()
						visto["esperadas"] = 96 if er.calidad == "alta" else 48)
		if visto["orbe_fuera"]:
			break
		await _esperar(1)
	_ok(visto["orbe_fuera"], "%s: la invocación no llega a sacar el orbe" % caso)
	var encendido := caso != "apagado"
	var ef = visto["efecto"]
	if encendido:
		_ok(ef != null, "%s: con la opción activa no nace el efecto en «orbe_fuera»" % caso)
		_ok(visto["frame_ok"], "%s: el efecto no está sobre el orbe al nacer" % caso)
		_ok(visto.get("particulas", -1) == visto.get("esperadas", -2), "%s: partículas %s (esperadas %s)" % [caso, visto.get("particulas"), visto.get("esperadas")])
	else:
		_ok(ef == null, "%s: con la opción apagada se crea el efecto" % caso)
	if modo == "saltar":
		await _esperar(3)
		c.inv_erebo.saltar()
		await _esperar(4)
		_ok(_vivos() == 0, "%s: tras saltar quedan %d efectos" % [caso, _vivos()])
	elif modo == "salir":
		await _esperar(3)
		c.queue_free()
		c = null
		await _esperar(4)
		_ok(_vivos() == 0, "%s: tras borrar el combate quedan %d efectos" % [caso, _vivos()])
		Engine.time_scale = 1.0
		hechos.append(caso)
		return {}
	elif encendido and ef != null:
		var onda := false
		for i in 120:
			if not is_instance_valid(ef):
				break
			if ef.onda_lanzada():
				onda = true
				break
			await _esperar(1)
		_ok(onda, "%s: la onda no se lanza" % caso)
	var vuelve := false
	for i in 1500:
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			vuelve = true
			break
		await _esperar(1)
	_ok(vuelve, "%s: el combate no vuelve a su curso (estado %s)" % [caso, c.estado])
	await _esperar(5)
	_ok(_vivos() == 0, "%s: al terminar quedan %d efectos" % [caso, _vivos()])
	_ok(is_equal_approx(Engine.time_scale, 1.0), "%s: el tiempo no vuelve a 1" % caso)
	var r := {"muerte_o_dano": grim["hp"] <= 0 or grim["hp"] < pv0}
	_ok(r["muerte_o_dano"], "%s: el resultado (éxito forzado) no se aplica" % caso)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
	hechos.append(caso)
	return r
