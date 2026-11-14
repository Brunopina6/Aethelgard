extends SceneTree
# V12 (14/11): la invocación cinematográfica de Érebo en vídeo (invocacion_erebo_video.gd), opción de Auditoría
# APAGADA por defecto, en un combate de verdad con datos aislados y «erebo=exito»:
#   apagado    → sin ajuste no hay vídeo: se usa el teatro de siempre (inv_erebo aparece)
#   vídeos     → los dos .ogv se cargan como VideoStreamTheora, duran ≈20,0 s y ≈6,8 s y se reproducen
#   abreviada  → el vídeo tapa el combate, el teatro NO se crea, el estado sigue en «accion» todo el rato (no se abre
#                otro turno), el resultado se aplica UNA vez al acabar, la música vuelve a su volumen y no quedan restos
#   saltar     → un toque de verdad corta el vídeo enseguida y el resultado se aplica igual, una vez; también si se toca
#                durante el fundido de entrada (no debe tomarse por fallo ni sacar el teatro)
#   ATB        → el vídeo da el MISMO tiempo de ATB que la invocación de siempre (V.ATB_TEATRO), sea cual sea su duración
#   primera    → «1.ª completa»: la primera vez el vídeo completo; después, el abreviado
# No toca la partida real: archivo de partida de prueba y user:// aislado del ejecutor.

const ARCHIVO := "user://prueba_erebo_video.save"

var P
var G
var V
var c = null
var fallos: Array = []
var hechos: Array = []
var reloj := 0.0              # tiempo de juego (el ejecutor puede ir más rápido que el reloj real)


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	V = load("res://invocacion_erebo_video.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		reloj += root.get_process_delta_time()
		if c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _capa() -> Node:
	return root.find_child("EreboCinematica", true, false)


func _probar() -> void:
	await _esperar(10)
	_ok(V.permitido(), "la opción solo existe en Auditoría o editor y esta prueba corre en el editor")
	_ok(V.modo() == "no", "sin ajuste la opción debe estar apagada (está «%s»)" % V.modo())
	_ok(V.ruta_para_ahora() == "", "apagada no debe elegir vídeo")
	await _videos()
	await _invocar("apagado", "", false)
	V.elegir("abreviada")
	await _invocar("abreviada", "", true)
	await _invocar("saltar", "saltar", true)
	await _invocar("saltar durante el fundido", "saltar_pronto", true)
	V.elegir("primera")
	var r1: String = V.ruta_para_ahora()
	_ok(r1 == V.COMPLETA, "primera: la primera vez debe ser la completa (%s)" % r1)
	await _invocar("primera (completa, saltada)", "saltar", true)
	var r2: String = V.ruta_para_ahora()
	_ok(r2 == V.ABREVIADA, "primera: después debe ser la abreviada (%s)" % r2)
	V.elegir("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _videos() -> void:
	for par in [[V.COMPLETA, 20.0], [V.ABREVIADA, 6.8]]:
		var ruta: String = par[0]
		_ok(ResourceLoader.exists(ruta), "falta %s" % ruta)
		if not ResourceLoader.exists(ruta):
			continue
		var s = load(ruta)
		_ok(s is VideoStreamTheora, "%s no es VideoStreamTheora (%s)" % [ruta, s])
		var vp := VideoStreamPlayer.new()
		vp.stream = s
		root.add_child(vp)
		vp.play()
		await _esperar(20)
		var largo: float = vp.get_stream_length()
		_ok(absf(largo - par[1]) < 0.25, "%s dura %.2f s (esperado ≈%.1f)" % [ruta, largo, par[1]])
		_ok(vp.is_playing(), "%s no se reproduce" % ruta)
		var pos: float = vp.stream_position
		_ok(pos > 0.05, "%s no avanza (posición %.3f)" % [ruta, pos])
		print("VIDEO %s: %.2f s, posición %.3f tras 20 fotogramas" % [ruta.get_file(), largo, pos])
		vp.stop()
		vp.queue_free()
		await _esperar(2)
	hechos.append("vídeos")


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


func _tocar() -> void:
	# un toque de verdad en el centro de la pantalla (lo recoge «fuera», como en el juego)
	for pulsado in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pulsado
		ev.position = Vector2(640, 360)
		ev.global_position = ev.position
		root.push_input(ev)
	await _esperar(2)
	if not c.saltar_invocacion:
		# sin ventana el toque no llega a «fuera»: se salta con Esc, la otra entrada real (_unhandled_input)
		print("AVISO: sin ventana el toque no llega; se salta con Esc (ui_cancel)")
		var ac := InputEventAction.new()
		ac.action = "ui_cancel"
		ac.pressed = true
		root.push_input(ac)
		await _esperar(1)
	_ok(c.saltar_invocacion, "la entrada para saltar no llega al combate")


# modo: "" (hasta el final), "saltar" (toque a los 0,9 s del vídeo) o "saltar_pronto" (toque durante el fundido)
func _invocar(caso: String, modo: String, video: bool) -> void:
	var grim: Dictionary = await _combate()
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % caso)
		c.queue_free()
		await _esperar(5)
		return
	var i_mus := AudioServer.get_bus_index("Musica")
	var db0 := AudioServer.get_bus_volume_db(i_mus)
	c.armonia = 1.0
	# ATB lento y desde cero para poder comprobar cuánto corre (sin llegar al tope)
	for f in c.heroes + c.enemigos:
		f["vel"] = 2.0
		f["atb"] = 0.0
	var pv0: int = grim["hp"]
	var quitados := [0]
	var hp_previo := [pv0]
	c._invocar_sobre(grim)
	var atb0 := {}
	for h in c.heroes:
		atb0[h["nombre"]] = h["atb"]
	var vio_capa := false
	var vio_teatro := false
	var siempre_accion := true
	var bajo_musica := false
	var tocado := false
	var t_capa := -1.0
	var t_fin_capa := -1.0
	var f_capa := 0
	var anuncios := {"corazon": 0, "vacia": 0}
	var reg_previo := ""
	for i in 3000:
		var capa := _capa()
		if capa != null:
			if not vio_capa:
				t_capa = reloj
			vio_capa = true
			f_capa += 1
			if c.estado != "accion":
				siempre_accion = false
			if AudioServer.get_bus_volume_db(i_mus) < db0 - 1.0:
				bajo_musica = true
			if not tocado and ((modo == "saltar" and reloj - t_capa > 0.9) or (modo == "saltar_pronto" and f_capa == 2)):
				tocado = true
				await _tocar()
		elif vio_capa and t_fin_capa < 0:
			t_fin_capa = reloj
		if c.inv_erebo != null and not vio_teatro:
			vio_teatro = true
			if not video:
				await _esperar(30)
				if c.inv_erebo != null:
					c.inv_erebo.saltar()
		if grim["hp"] != hp_previo[0]:
			quitados[0] += 1
			hp_previo[0] = grim["hp"]
		if c.registro.text != reg_previo:
			reg_previo = c.registro.text
			if "arranca el corazón" in reg_previo:
				anuncios["corazon"] += 1
			if "sale vacía" in reg_previo:
				anuncios["vacia"] += 1
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
		await _esperar(1)
	var t_vuelta := reloj
	var atb1 := {}
	for h in c.heroes:
		atb1[h["nombre"]] = h["atb"]
	await _esperar(5)
	if grim["hp"] != hp_previo[0]:
		quitados[0] += 1
	_ok(vio_capa == video, "%s: vídeo %s (esperado %s)" % [caso, vio_capa, video])
	if not video:
		_ok(vio_teatro, "%s: apagada debe usarse el teatro de siempre" % caso)
	else:
		_ok(not vio_teatro, "%s: con vídeo no debe crearse el teatro 3D" % caso)
		_ok(siempre_accion, "%s: el estado sale de «accion» durante el vídeo (podría abrirse otro turno)" % caso)
		_ok(bajo_musica, "%s: la música no se aparta durante el vídeo" % caso)
		var dura := t_fin_capa - t_capa
		if modo.begins_with("saltar"):
			_ok(dura < 3.0, "%s: saltar no corta el vídeo (%.1f s)" % [caso, dura])
		else:
			_ok(dura > 6.6 and dura < 12.0, "%s: el vídeo abreviado dura %.1f s en pantalla (esperado ≈7,5 s)" % [caso, dura])
		# ATB: el mismo tiempo que la invocación de siempre con éxito, más lo que corre normal tras el vídeo
		var nueva_sel: bool = load("res://invocacion_erebo_nueva.gd").elegida()
		var presupuesto: float = V.atb_teatro(nueva_sel, true)
		var t_post := t_vuelta - t_fin_capa + 1.0 / 30.0
		for h in c.heroes:
			if h["hp"] <= 0 or h["nombre"] == "Lya":         # (a quien invoca, su turno le deja el ATB a 0, como siempre)
				continue
			var esperado: float = minf(100.0, atb0[h["nombre"]] + 2.0 * (presupuesto + t_post))
			_ok(absf(atb1[h["nombre"]] - esperado) < 0.6, "%s: ATB de %s %.2f (esperado %.2f = invocación de siempre)" % [caso, h["nombre"], atb1[h["nombre"]], esperado])
		print("%s: vídeo en pantalla %.2f s; ATB %s (presupuesto %.2f s + %.2f s después)" % [caso, dura, atb1, presupuesto, t_post])
	_ok(quitados[0] == 1, "%s: los PV del enemigo cambian %d veces (debe ser 1)" % [caso, quitados[0]])
	_ok(grim["hp"] <= 0 and pv0 > 0, "%s: el resultado (éxito forzado) no se aplica (%d → %d)" % [caso, pv0, grim["hp"]])
	_ok(anuncios["corazon"] == 1 and anuncios["vacia"] == 0, "%s: el registro anuncia el resultado %s (debe ser un «arranca el corazón»)" % [caso, anuncios])
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(i_mus), db0), "%s: la música no vuelve a su volumen (%.1f / %.1f dB)" % [caso, AudioServer.get_bus_volume_db(i_mus), db0])
	_ok(_capa() == null, "%s: queda la capa del vídeo" % caso)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "%s: el tiempo no vuelve a 1" % caso)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
	hechos.append(caso)
