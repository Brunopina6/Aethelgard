extends SceneTree
# Prueba de los efectos de sonido (T-083; sonido.gd). Sin ventana, con datos aislados y «-- 3d sin_prologo». Es MUDA:
# comprueba qué suena, cuántas veces, por qué bus y con qué límites. Cómo sale de verdad por el altavoz lo mide
# prueba_efectos_senal (con ventana) y cómo suena lo escucha una persona (las muestras de D:\REBELUM_diagnostico).
#   1. Catálogo: cada efecto tiene sus archivos (QOA, mono, 48 kHz; el derivado ni satura ni es mudo) y un bus de
#      sonido.gd; el río y la cascada son bucles y lo demás no; nada de Suno.
#   2. Una vez por evento: pedido dos veces en el mismo instante, suena una; las variantes no se repiten seguidas y el
#      tono varía poco.
#   3. Límites y prioridades: no más de «max» iguales ni más voces que VOCES; sin hueco, un golpe no quita nada más
#      importante y una victoria sí; mientras suena la victoria, lo demás va más bajo.
#   4. Cortar, retrasar, cambiar de escena (lo programado ya no suena; Efectos se apaga; «cruza» y la interfaz siguen),
#      pausa del árbol (Efectos se para, la interfaz no) y de la app (todo), y silencio (volumen 0 o bus callado: no
#      suena ni ocupa voz).
#   5. Combate de verdad: un ataque físico suena una vez; una magia no suena (el catálogo mágico no cambia); el golpe
#      a quien se defiende suena a escudo; defensa, poción, Embuir, victoria y monedas, huida y derrota, una vez.
#   6. Pastos Verdes 3D: se escucha desde Kael; el río (que sigue a quien escucha) y la cascada suenan por Ambiente en
#      bucle; andando por el camino los pasos suenan a piedra y fuera a hierba, y parado no suena ninguno; el cofre
#      suena una vez (tapa y premio); la emboscada suena y, en el combate, el río y la cascada ya no están.
#   7. Zona 2D: los pasos siguen los fotogramas del muñeco con el suelo de la zona; cofre, posada sin dinero y
#      emboscada. Garganta: puerta sellada, ascensor sin fuerza, palanca y puente, y guardado. Menús y tienda.
# Tanda 2 (T-083):
#   8. Voces de los enemigos en combates de verdad: el limo, Grimfang, el Gólem de ámbar y Gorthor suenan con su
#      familia, una vez por evento (ataque al lanzarse, herido, caída), la magia no las pide, los héroes no tienen voz;
#      el segundo tajo del doble ataque suena más bajo; Gorthor de rodillas, «Acabar» y su mordisco; congelar, una vez.
#      API: una voz por enemigo, dos voces a la vez como mucho, la furia más fuerte.
#   9. Agua 2D: el río de una llanura suena más cuanto más cerca, se calla lejos (y deja de sonar), con un fundido, y
#      se apaga al salir de la zona; en la Garganta (abismo) y en una ciudad no hay agua que suene.
#  10. Interfaz y mundo: el Diario (pasar hoja solo si cambia, cerrar), el brazalete (una vez por detalle) y el altar.
#      Garganta: la puerta suena al abrirse (tras la palanca), el ascensor ya viaja y el nido (emboscada y cofre raro).
#  11. Aleatorio: los efectos no tocan el generador global (randi() sale igual con y sin sonidos).

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const PARTIDA := "user://prueba_efectos.save"

var fallos: Array = []
var hechos: Array = []
var Son
var R
var parte := ""                                    # por dónde va (si se acaba el tiempo, se dice dónde)
var limite_ms := 0
var partes := ""                                   # «partes=api,combate…»: solo esas (para buscar un fallo)


func _initialize() -> void:
	limite_ms = Time.get_ticks_msec() + 450 * 1000
	for a in OS.get_cmdline_user_args():
		if a.begins_with("partes="):
			partes = a.substr(7)
	_probar.call_deferred()


func _process(_d: float) -> bool:
	if limite_ms > 0 and Time.get_ticks_msec() > limite_ms:
		limite_ms = 0
		_fallo("se acaba el tiempo en «%s»" % parte)
		print("FALLOS: %d" % fallos.size())
		quit(1)
	return false


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _parte(nombre: String) -> bool:
	parte = nombre
	print("PARTE ", nombre)
	return partes == "" or nombre.get_slice(" ", 0) in partes.split(",")


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _juego(s: float) -> void:                     # segundos de juego (con --fixed-fps 30, 30 fotogramas cada uno)
	await _esperar(int(ceil(s * 30.0)))


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _n(nombre: String) -> int:
	return int(Son.contador.get(nombre, 0))


func _suma(prefijo: String) -> int:
	var t := 0
	for k in Son.contador:
		if String(k).begins_with(prefijo):
			t += int(Son.contador[k])
	return t


func _golpes() -> int:
	return _n("golpe") + _n("golpe_critico") + _n("golpe_defendido")


# Empieza cada parte en limpio: nada sonando y los contadores a cero.
func _limpiar() -> void:
	for p in Son._todas():
		Son._parar_fundido(p)
		p.stop()
	Son._bajar_hasta.clear()
	Son.reiniciar_contadores()


func _en_escena(ruta: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == ruta and not R.cambiando


func _probar() -> void:
	Son = root.get_node("Sonido")
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", PARTIDA)   # el guardado automático escribe aquí, no en la partida
	Engine.set_meta("partida_lista", true)
	await _esperar(3)
	if _parte("catalogo"):
		_catalogo()
	if _parte("api"):
		await _api()
	if _parte("combate"):
		await _combate()
	if _parte("region"):
		await _region3d()
	if _parte("zona"):
		await _zona2d()
	if _parte("garganta"):
		await _garganta()
	if _parte("menus"):
		await _menus()
	if _parte("voces"):
		await _voces()
	if _parte("agua"):
		await _agua2d()
	if _parte("interfaz"):
		await _interfaz()
	if _parte("azar"):
		_azar()
	print("OK efectos: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Catálogo y archivos.
func _catalogo() -> void:
	var n := 0
	for nombre in Son.EFECTOS:
		var d: Dictionary = Son.EFECTOS[nombre]
		if not String(d.get("bus", "Efectos")) in Son.BUSES:
			_fallo("1: «%s» va por un bus que no es de sonido.gd" % nombre)
		if d.has("codigo"):
			continue
		var rutas: Array = []
		if d.has("n"):
			for i in int(d["n"]):
				rutas.append(Son.EF + d["a"] + str(i + 1) + ".wav")
		else:
			rutas.append(Son.EF + d["a"] + ".wav")
		for ruta in rutas:
			n += 1
			if "suno" in ruta.to_lower():
				_fallo("1: %s parece de Suno" % ruta)
			if not ResourceLoader.exists(ruta):
				_fallo("1: falta %s («%s»)" % [ruta, nombre])
				continue
			var s = load(ruta)
			if not s is AudioStreamWAV or s.format != AudioStreamWAV.FORMAT_QOA or s.stereo or s.mix_rate != 48000:
				_fallo("1: %s no es QOA mono a 48 kHz" % ruta)
				continue
			var bucle: bool = d.has("tres_d") or d.has("dos_d")
			if (s.loop_mode == AudioStreamWAV.LOOP_FORWARD) != bucle:
				_fallo("1: %s %s debería ser un bucle" % [ruta, "no" if bucle else "sí y no"])
			var w := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(ruta))   # el derivado, sin comprimir
			var b: PackedByteArray = w.data                # (una vez: cada «w.data» copia todo el sonido)
			var pico := 0.0
			var suma := 0.0
			var muestras := 0
			for i in range(0, b.size(), 2):
				var v := absf(b.decode_s16(i) / 32767.0)
				pico = maxf(pico, v)
				suma += v * v
				muestras += 1
			var rms := sqrt(suma / maxf(1.0, muestras))
			if pico >= 0.99 or rms < 0.002 or w.get_length() < 0.03:
				_fallo("1: %s satura o es casi mudo (pico %.2f, RMS %.4f, %.2f s)" % [ruta, pico, rms, w.get_length()])
	hechos.append("catálogo (%d efectos, %d archivos)" % [Son.EFECTOS.size(), n])


# 2 a 4. La API: una vez, variantes, límites, prioridades, cortar, retrasar, cambio de escena, pausa y silencio.
func _api() -> void:
	_limpiar()
	var p = Son.efecto("golpe")
	var q = Son.efecto("golpe")
	if p == null or q != null or _n("golpe") != 1:
		_fallo("2: dos golpes pedidos en el mismo instante suenan %d veces" % _n("golpe"))
	var anterior := ""
	var seguidas := 0
	var vistas := {}
	var tonos: Array = []
	for i in 24:
		Son._ultimo.erase("paso_hierba")
		var r = Son.efecto("paso_hierba")
		if r == null:
			_fallo("2: un paso no suena")
			break
		var ruta: String = Son.registro[Son.registro.size() - 1][2]
		if ruta == anterior:
			seguidas += 1
		anterior = ruta
		vistas[ruta] = true
		tonos.append(r.pitch_scale)
	tonos.sort()
	if seguidas > 0:
		_fallo("2: la misma variante suena dos veces seguidas (%d veces)" % seguidas)
	if vistas.size() < 5:
		_fallo("2: solo suenan %d de las 6 variantes de la hierba" % vistas.size())
	if tonos.is_empty() or tonos[0] < 0.93 or tonos[tonos.size() - 1] > 1.07 or tonos[tonos.size() - 1] - tonos[0] < 0.02:
		_fallo("2: el tono de los pasos no varía un poco (%s)" % str(tonos))
	var iguales := 0
	for x in Son._todas():
		if x.playing and x.get_meta("efecto", "") == "paso_hierba":
			iguales += 1
	if iguales > 2:
		_fallo("2: suenan %d pasos de hierba a la vez (máximo 2)" % iguales)
	hechos.append("una vez, variantes (%d) y tono %.3f-%.3f" % [vistas.size(), tonos[0], tonos[tonos.size() - 1]])

	# 3. voces y prioridades
	_limpiar()
	for nombre in ["cofre", "tesoro", "palanca", "puente_baja", "guardado", "posada", "misterio", "union", "nivel", "carga_jefe"]:
		Son.efecto(nombre)
	if Son.sonando("Efectos") != Son.VOCES["Efectos"]:
		_fallo("3: diez efectos importantes ocupan %d voces (esperaba %d)" % [Son.sonando("Efectos"), Son.VOCES["Efectos"]])
	if Son.efecto("golpe") != null:
		_fallo("3: sin hueco, un golpe (prioridad 2) quita algo más importante")
	var v = Son.efecto("victoria")
	if v == null or not v.playing:
		_fallo("3: sin hueco, la victoria no suena")
	if Son.sonando("Efectos") > Son.VOCES["Efectos"]:
		_fallo("3: hay %d voces sonando en Efectos (máximo %d)" % [Son.sonando("Efectos"), Son.VOCES["Efectos"]])
	Son.cortar("puente_baja", 0.0)                       # deja un hueco
	var g = Son.efecto("golpe")
	# su volumen del catálogo, menos lo que baja la prioridad, más la variación al azar de cada vez (±0,7 dB, sonido.gd):
	# antes se comparaba con −6 dB fijos y el golpe está a −5, así que fallaba más o menos la mitad de las veces
	if g == null or g.volume_db > Son.EFECTOS["golpe"]["db"] - Son.ATENUAR_DB + 0.75:
		_fallo("3: mientras suena la victoria, un golpe no va más bajo (%s dB)" % (str(g.volume_db) if g else "no suena"))
	hechos.append("voces y prioridades")

	# 4. cortar y retrasar
	Son.cortar("victoria")
	if not await _hasta(func(): return not v.playing, 5.0):
		_fallo("4: cortar no apaga la victoria")
	_limpiar()
	Son.efecto("tesoro", {"retraso": 0.3})
	if _n("tesoro") != 0:
		_fallo("4: el efecto con retraso suena enseguida")
	await _juego(0.5)
	if _n("tesoro") != 1:
		_fallo("4: el efecto con retraso suena %d veces" % _n("tesoro"))
	# cambio de escena
	_limpiar()
	var largo = Son.efecto("puente_baja")
	var cruza = Son.efecto("portal")
	var ui = Son.efecto("ui_abrir")
	Son.efecto("tesoro", {"retraso": 0.3})
	var vacia := Node.new()
	vacia.name = "Vacia"
	var ps := PackedScene.new()
	ps.pack(vacia)
	vacia.free()
	change_scene_to_packed(ps)
	await _esperar(2)
	if ui.has_meta("tween"):
		_fallo("4: al cambiar de escena se corta la interfaz")
	await _juego(0.6)
	if _n("tesoro") != 0:
		_fallo("4: lo programado suena después de cambiar de escena")
	if largo.playing:
		_fallo("4: tras cambiar de escena sigue sonando un efecto de la anterior")
	if not cruza.playing:
		_fallo("4: el portal («cruza») se corta al cambiar de escena")
	# pausa del árbol y de la app
	_limpiar()
	var ef = Son.efecto("puente_baja")
	var it = Son.efecto("ui_tic")
	paused = true
	await _esperar(2)
	if ef.can_process():
		_fallo("4: con el árbol en pausa, los efectos siguen")
	if not it.can_process():
		_fallo("4: con el árbol en pausa, la interfaz se para")
	paused = false
	await _esperar(2)
	Son.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	if not ef.stream_paused:
		_fallo("4: al pausar la app, el efecto que sonaba no se pausa")
	if Son.efecto("golpe") != null:
		_fallo("4: con la app en pausa empieza un efecto nuevo")
	Son.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	if ef.stream_paused:
		_fallo("4: al volver a la app, el efecto sigue en pausa")
	# silencio
	_limpiar()
	Son.fijar("Efectos", 0)
	if Son.efecto("golpe") != null or Son.sonando("Efectos") != 0:
		_fallo("4: con Efectos al 0 % suena (u ocupa una voz)")
	Son.fijar("Efectos", 100)
	var i := AudioServer.get_bus_index("Efectos")
	AudioServer.set_bus_mute(i, true)
	if Son.efecto("golpe") != null:
		_fallo("4: con el bus Efectos callado suena")
	AudioServer.set_bus_mute(i, false)
	Son.reiniciar_contadores()
	if Son.efecto("golpe") == null:
		_fallo("4: con el volumen de vuelta, no suena")
	hechos.append("cortar, retrasar, cambio de escena, pausa y silencio")


# 5. Combate de verdad (Kael contra el grupo 7): las acciones se llaman a mano, con el ATB parado.
func _nuevo_combate(grupo := 7) -> Node:
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael"])
	Engine.set_meta("grupo_combate", grupo)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("desde_mapa", false)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(30)
	for x in c.heroes + c.enemigos:
		x["vel"] = 0.0
		x["atb"] = 0.0
	c.cola.clear()
	return c


func _combate() -> void:
	var c = await _nuevo_combate()
	var h: Dictionary = c.heroes[0]
	var e: Dictionary = c.enemigos[0]
	e["hp_max"] = 9999
	e["hp"] = 9999
	parte = "combate: golpe de Kael"
	_limpiar()
	await c._animar_golpe(h, e, 1, "")
	await _juego(0.4)
	if _golpes() != 1:
		_fallo("5: un ataque físico de Kael suena %d veces" % _golpes())
	parte = "combate: magia"
	_limpiar()
	await c._animar_golpe(h, e, 1, "Fuego")
	await _juego(0.4)
	var tras_magia: Dictionary = Son.contador.duplicate()
	if not tras_magia.is_empty():
		_fallo("5: una magia suena (%s): el catálogo mágico no cambia" % str(tras_magia))
	parte = "combate: defensa"
	_limpiar()
	c.actor = h
	h["hp"] = h["hp_max"]
	await c._defender()
	await _juego(0.6)
	if _n("defensa") != 1:
		_fallo("5: defender suena %d veces" % _n("defensa"))
	parte = "combate: golpe al que se defiende"
	_limpiar()
	await c._animar_golpe(e, h, 1, "")
	await _juego(0.4)
	if _n("golpe_defendido") != 1 or _n("golpe") + _n("golpe_critico") != 0:
		_fallo("5: el golpe a quien se defiende no suena a escudo una vez (%s)" % str(Son.contador))
	parte = "combate: poción"
	_limpiar()
	load("res://inventario.gd").agregar_objeto("Poción", 1)
	h["hp"] = maxi(1, h["hp_max"] - 10)
	c.actor = h
	await c._usar_objeto("Poción", h)
	await _juego(0.6)
	if _n("pocion") != 1:
		_fallo("5: la poción suena %d veces" % _n("pocion"))
	parte = "combate: Embuir"
	_limpiar()
	c.actor = h
	await c._embuir("Fuego")
	await _juego(0.6)
	if _n("embuir") != 1:
		_fallo("5: Embuir suena %d veces" % _n("embuir"))
	parte = "combate: victoria"
	_limpiar()
	var oro := 0
	for x in c.enemigos:
		oro += int(x.get("oro", 0))
		x["hp"] = 0
	c._comprobar_fin()
	await _juego(7.0)                                    # experiencia, monedas y el menú del final
	if _n("victoria") != 1 or _n("derrota") != 0:
		_fallo("5: al ganar, victoria %d y derrota %d" % [_n("victoria"), _n("derrota")])
	if _n("monedas") != (1 if oro > 0 else 0):
		_fallo("5: al ganar %d monedas, las monedas suenan %d veces" % [oro, _n("monedas")])
	c.queue_free()
	await _esperar(3)
	c = await _nuevo_combate()
	parte = "combate: huida"
	_limpiar()
	c._escapar()
	await _juego(3.0)
	if _n("huida") != 1:
		_fallo("5: huir suena %d veces" % _n("huida"))
	c.queue_free()
	await _esperar(3)
	c = await _nuevo_combate()
	parte = "combate: derrota"
	_limpiar()
	for x in c.heroes:
		x["hp"] = 0
	c._comprobar_fin()
	await _juego(4.0)
	if _n("derrota") != 1 or _n("victoria") != 0:
		_fallo("5: al perder, derrota %d y victoria %d" % [_n("derrota"), _n("victoria")])
	c.queue_free()
	await _esperar(3)
	hechos.append("combate (golpe, magia muda, defensa, escudo, poción, Embuir, victoria, huida y derrota)")


# 6. Pastos Verdes 3D.
func _andar(r, desde: Vector3, hasta: Vector3, segundos: float) -> float:
	r._colocar_kael(Vector3(desde.x, r.altura(desde.x, desde.z), desde.z))
	await _esperar(3)
	_limpiar()
	r.destino = r._ajustar_destino(Vector3(hasta.x, 0, hasta.z))
	var f := 0
	while f < int(segundos * 30.0) and r.destino != null:
		r.pasos = 0                                      # sin encuentros mientras anda (solo en la prueba)
		await process_frame
		f += 1
	return f / 30.0


func _region3d() -> void:
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})   # sin las escenas de la misión
	change_scene_to_file(REGION)
	if not await _hasta(func(): return _en_escena(REGION), 90.0):
		_fallo("6: no se abre Pastos Verdes 3D")
		return
	await _esperar(20)
	var r = current_scene
	var oyente = r.get_node_or_null("Oyente")
	if oyente == null or not oyente.is_current():
		_fallo("6: no se escucha desde Kael")
	var rio = r.get_node_or_null("Sonido_rio")
	var cascada = r.get_node_or_null("Sonido_cascada")
	for x in [rio, cascada]:
		if x == null or not x.playing or x.bus != &"Ambiente" or x.stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			_fallo("6: el río o la cascada no suenan en bucle por Ambiente")
			return
	r._colocar_kael(Vector3(13.3, r.altura(13.3, -2.0), -2.0))   # a la salida del puente
	await _esperar(4)
	if absf(rio.global_position.z - (-2.0)) > 0.6 or absf(rio.global_position.x - r.RIO_X) > 0.01:
		_fallo("6: el río no se pone frente a quien escucha (%s)" % rio.global_position)
	# pasos por el camino de losas
	parte = "region: pasos por el camino"
	var t := await _andar(r, Vector3(-16, 0, 16), Vector3(-3, 0, 5), 8.0)
	var pasos := _suma("paso_")
	if pasos < 3:
		_fallo("6: andando %.1f s por el camino suenan %d pasos" % [t, pasos])
	elif _n("paso_piedra") < pasos * 0.6:
		_fallo("6: por el camino de losas, %d de %d pasos suenan a piedra" % [_n("paso_piedra"), pasos])
	if t > 0.0 and pasos / t > 6.5:
		_fallo("6: %d pasos en %.1f s: demasiados" % [pasos, t])
	var info := "camino: %d pasos en %.1f s (%d de piedra)" % [pasos, t, _n("paso_piedra")]
	# parado
	_limpiar()
	await _juego(1.5)
	if _suma("paso_") > 0:
		_fallo("6: Kael parado y suenan %d pasos" % _suma("paso_"))
	# fuera del camino
	t = await _andar(r, Vector3(-14, 0, 2), Vector3(-14, 0, -7), 6.0)
	pasos = _suma("paso_")
	if pasos < 2 or _n("paso_hierba") < pasos * 0.6:
		_fallo("6: por la hierba, %d de %d pasos suenan a hierba (%.1f s)" % [_n("paso_hierba"), pasos, t])
	info += "; hierba: %d en %.1f s" % [pasos, t]
	print("PASOS ", info)
	# el cofre
	parte = "region: cofre"
	_limpiar()
	r._abrir_cofre()
	await _juego(0.6)
	r._abrir_cofre()
	await _juego(0.6)
	if _n("cofre") != 1 or _n("tesoro") != 1:
		_fallo("6: el cofre suena %d veces y el premio %d" % [_n("cofre"), _n("tesoro")])
	# la emboscada, y en el combate ya no están el río ni la cascada
	parte = "region: emboscada"
	_limpiar()
	r._encuentro()
	if not await _hasta(func(): return _en_escena("res://combate.tscn"), 60.0):
		_fallo("6: la emboscada no lleva al combate")
		return
	await _esperar(5)
	if _n("emboscada") != 1:
		_fallo("6: la emboscada suena %d veces" % _n("emboscada"))
	if is_instance_valid(rio) or is_instance_valid(cascada):
		_fallo("6: en el combate siguen el río o la cascada")
	hechos.append("Pastos Verdes 3D (%s)" % info)


# 7. Zona 2D, Garganta, menús y tienda.
func _zona2d() -> void:
	Engine.set_meta("lugar", {"indice": 1, "nombre": "Gran Bosque Verde", "tipo": "lugar", "zona": "llanura", "texto": "x"})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file("res://zona.tscn")
	if not await _hasta(func(): return _en_escena("res://zona.tscn"), 60.0):
		_fallo("7: no se abre la zona")
		return
	await _esperar(10)
	var z = current_scene
	var camino: Array = z.caminos[0]
	z.jugador.position = camino[mini(1, camino.size() - 1)] * z.T   # el punto 0 es la salida: allí se vuelve al mapa
	await _esperar(3)
	_limpiar()
	z.destino = camino[mini(4, camino.size() - 1)] * z.T
	z.tiene_destino = true
	for f in 120:
		z.pasos = 0
		await process_frame
	var pasos := _suma("paso_")
	var otros := pasos - _n("paso_hierba") - _n("paso_grava") - _n("paso_madera")
	if pasos < 3 or otros != 0:
		_fallo("7: andando 4 s por una llanura suenan %d pasos (%d de otro suelo)" % [pasos, otros])
	z.tiene_destino = false
	_limpiar()
	var cerrado = null
	for c in z.cofres:
		if not c[2]:
			cerrado = c
			break
	if cerrado != null:
		z._abrir_cofre(cerrado)
		await _juego(0.6)
		if _n("cofre") != 1 or _n("tesoro") != 1:
			_fallo("7: el cofre de la zona suena %d veces y el premio %d" % [_n("cofre"), _n("tesoro")])
	var inv = load("res://inventario.gd")
	var oro: int = inv.oro()
	inv.gastar_oro(oro)
	_limpiar()
	z._posada()
	if _n("ui_error") != 1 or _n("posada") != 0:
		_fallo("7: la posada sin dinero no suena a error una vez")
	inv.ganar_oro(oro)
	_limpiar()
	if z.saliendo:
		_fallo("7: la zona ya estaba saliendo antes de la emboscada (la prueba llevó a Kael a la salida)")
	z._encuentro()
	await _juego(0.3)
	if _n("emboscada") != 1:
		_fallo("7: la emboscada de la zona suena %d veces" % _n("emboscada"))
	await _hasta(func(): return _en_escena("res://combate.tscn"), 60.0)
	await _esperar(5)
	hechos.append("zona 2D (%d pasos)" % pasos)


func _garganta() -> void:
	change_scene_to_file("res://garganta.tscn")
	if not await _hasta(func(): return _en_escena("res://garganta.tscn"), 60.0):
		_fallo("7: no se abre la Garganta")
		return
	await _esperar(10)
	var g = current_scene
	_limpiar()
	g.pieza_cerca = {"tipo": "puerta"}
	g._accion()
	if g.Progreso.estado(g.NOMBRE, "palanca"):
		_fallo("7: la palanca ya estaba bajada (la prueba no es de partida nueva)")
		return
	g.pieza_cerca = {"tipo": "ascensor_arriba", "otro": g.jugador.position}
	g._accion()
	g._tirar_palanca()
	await _juego(1.6)                                    # la puerta se abre 1,3 s después de la palanca (tanda 2)
	g.pieza_cerca = {"tipo": "guardado", "pos": g.jugador.position}
	g._accion()
	for k in ["cerrada", "atascado", "palanca", "puente_baja", "puerta_abre", "guardado"]:
		if _n(k) != 1:
			_fallo("7: en la Garganta, «%s» suena %d veces" % [k, _n(k)])
	# tanda 2: con la palanca bajada el ascensor viaja; no hay río en el abismo; el cofre raro y el nido
	_limpiar()
	g.pieza_cerca = {"tipo": "ascensor_arriba", "otro": g.jugador.position}
	g._accion()
	await _juego(0.8)
	if _n("ascensor") != 1 or _n("atascado") != 0:
		_fallo("10: con la palanca bajada, el ascensor: viaje %d, atascado %d" % [_n("ascensor"), _n("atascado")])
	if g.get_node_or_null("Sonido_rio_2d") != null:
		_fallo("9: en la Garganta (abismo) suena un río")
	_limpiar()
	for c in g.cofres:
		if c[1] == g._id_cofre(g.COFRE_NIDO * g.T) and not c[2]:
			g._abrir_cofre(c)
	await _juego(0.6)
	if _n("cofre") != 1 or _n("tesoro") != 1:
		_fallo("10: el cofre raro del nido: cofre %d, premio %d" % [_n("cofre"), _n("tesoro")])
	_limpiar()
	g._combate_fijo("garganta_nido", 6, "normal", Vector2(30.8, 44.0), "¡Algo se mueve en el nido!")
	await _juego(0.3)
	if _n("emboscada") != 1:
		_fallo("10: el combate del nido empieza con la emboscada %d veces" % _n("emboscada"))
	await _hasta(func(): return _en_escena("res://combate.tscn"), 60.0)
	await _esperar(5)
	await _escena_vacia()                                # que el combate del nido no siga sonando en las partes siguientes
	hechos.append("Garganta (puerta, ascensor, cofre raro y nido)")


# Una escena vacía: lo que había (un combate con su ATB, una zona) deja de existir y de sonar.
func _escena_vacia() -> void:
	var vacia := Node.new()
	vacia.name = "Vacia"
	var ps := PackedScene.new()
	ps.pack(vacia)
	vacia.free()
	change_scene_to_packed(ps)
	await _esperar(3)


func _menus() -> void:
	load("res://grupo.gd").datos()
	_limpiar()
	var m = load("res://menus.gd").new()
	root.add_child(m)
	await _esperar(2)
	m._ir_a_pestana("Objetos")
	m._cerrar()
	await _esperar(2)
	if _n("ui_abrir") != 1 or _n("ui_tic") != 1 or _n("ui_cerrar") != 1:
		_fallo("7: el menú del grupo: abrir %d, pestaña %d, cerrar %d" % [_n("ui_abrir"), _n("ui_tic"), _n("ui_cerrar")])
	var inv = load("res://inventario.gd")
	_limpiar()
	var t = load("res://tienda.gd").new()
	root.add_child(t)
	await _esperar(2)
	inv.ganar_oro(100)
	t._comprar_objeto("Poción")
	inv.gastar_oro(inv.oro())
	Son._ultimo.clear()
	t._comprar_objeto("Poción")
	t._cerrar()
	await _esperar(2)
	if _n("monedas") != 1 or _n("ui_error") != 1 or _n("ui_cerrar") != 1:
		_fallo("7: la tienda: monedas %d, error %d, cerrar %d" % [_n("monedas"), _n("ui_error"), _n("ui_cerrar")])
	hechos.append("menús y tienda")


# ================================================================= tanda 2

func _registro_de(prefijo: String) -> Array:
	return Son.registro.filter(func(x): return String(x[1]).begins_with(prefijo))


func _sin_vida(f: Dictionary) -> void:                     # que no muera en la prueba: mucha vida
	f["hp_max"] = 9999
	f["hp"] = 9999


# 8. Voces de los enemigos en combates de verdad (con el ATB parado) y la API.
func _voces() -> void:
	await _escena_vacia()
	# el limo (grupo 7): se lanza, recibe, la magia no pide voces y cae
	var c = await _nuevo_combate(7)
	var h: Dictionary = c.heroes[0]
	var e: Dictionary = c.enemigos[0]
	_sin_vida(h)
	_sin_vida(e)
	if Son.familia(e) != "limo":
		_fallo("8: el slime no tiene la familia del limo («%s»)" % Son.familia(e))
	parte = "voces: el limo se lanza"
	_limpiar()
	await c._animar_golpe(e, h, 1, "")
	await _juego(0.4)
	if _n("limo_ataque") != 1 or _golpes() != 1:
		_fallo("8: el limo se lanza: su voz %d, golpes %d (esperaba 1 y 1)" % [_n("limo_ataque"), _golpes()])
	parte = "voces: el limo recibe"
	_limpiar()
	await c._animar_golpe(h, e, 1, "")
	await _juego(0.4)
	if _n("limo_herido") != 1 or _suma("limo_") != 1:
		_fallo("8: Kael golpea al limo: herido %d (%s)" % [_n("limo_herido"), str(Son.contador)])
	parte = "voces: la magia no pide voces"
	_limpiar()
	await c._animar_golpe(h, e, 1, "Agua")
	await _juego(0.4)
	if not Son.contador.is_empty():
		_fallo("8: una magia pide sonidos (%s): el catálogo mágico no cambia" % str(Son.contador))
	parte = "voces: el limo cae"
	_limpiar()
	e["hp"] = 1
	await c._animar_golpe(h, e, 5, "")
	await _juego(0.4)
	if _n("limo_caida") != 1 or _n("limo_herido") != 0:
		_fallo("8: el golpe que tumba al limo: caída %d, herido %d" % [_n("limo_caida"), _n("limo_herido")])
	c.queue_free()
	await _esperar(3)
	# Grimfang (grupo 9): voz al lanzarse y el doble tajo (el segundo, más bajo); herido; congelar una vez
	c = await _nuevo_combate(9)
	h = c.heroes[0]
	var g: Dictionary = c.enemigos[0]
	_sin_vida(h)
	_sin_vida(g)
	parte = "voces: Grimfang ataca"
	_limpiar()
	await c._animar_golpe(g, h, 1, "")
	await _juego(0.4)
	var tajos := _registro_de("golpe")
	if _n("goblin_ataque") != 1 or tajos.size() != 2:
		_fallo("8: Grimfang ataca: su voz %d, tajos que suenan %d (esperaba 1 y 2)" % [_n("goblin_ataque"), tajos.size()])
	elif absf(float(tajos[1][0]) - float(tajos[0][0]) - 0.62) > 0.2:
		_fallo("8: los dos tajos de Grimfang no van separados como su animación (%.2f s)" % (float(tajos[1][0]) - float(tajos[0][0])))
	var info := "Grimfang: voz y 2 tajos"
	parte = "voces: Grimfang recibe"
	_limpiar()
	await c._animar_golpe(h, g, 1, "")
	await _juego(0.4)
	if _n("goblin_herido") != 1 or _n("goblin_caida") != 0:
		_fallo("8: Kael golpea a Grimfang: herido %d, caída %d" % [_n("goblin_herido"), _n("goblin_caida")])
	parte = "voces: congelar"
	_limpiar()
	g["congelado"] = 0                                     # (si Kael lleva Frostfang, su golpe de antes ya lo congeló)
	c._congelar(g)
	c._congelar(g)                                         # ya congelado: solo renueva las rondas
	if _n("congelar") != 1:
		_fallo("8: congelar dos veces seguidas suena %d veces (esperaba 1)" % _n("congelar"))
	c.queue_free()
	await _esperar(3)
	# el Gólem de ámbar (grupo 6) tiene su propia voz, aunque lleva el dibujo del guardián de piedra
	c = await _nuevo_combate(6)
	h = c.heroes[0]
	_sin_vida(h)
	var gol: Dictionary = {}
	for x in c.enemigos:
		if x.get("clave", "") == "golem_ambar":
			gol = x
	if gol.is_empty():
		_fallo("8: en el grupo 6 no está el Gólem de ámbar (¿combate.gd no apunta la clave?)")
	else:
		parte = "voces: el Gólem de ámbar"
		_limpiar()
		await c._animar_golpe(gol, h, 1, "")
		await _juego(0.4)
		if _n("ambar_ataque") != 1 or _n("piedra_ataque") != 0:
			_fallo("8: el Gólem de ámbar se lanza: ámbar %d, piedra %d" % [_n("ambar_ataque"), _n("piedra_ataque")])
	c.queue_free()
	await _esperar(3)
	# Gorthor (grupo 5): su mordisco, el golpe que lo deja de rodillas, la caída y «Acabar»
	c = await _nuevo_combate(5)
	await _juego(2.5)                                      # su presentación (su nombre en grande)
	h = c.heroes[0]
	var go: Dictionary = c.enemigos[0]
	_sin_vida(h)
	parte = "voces: Gorthor muerde"
	_limpiar()
	go["devora"] = true
	await c._animar_golpe(go, h, 1, "")
	go["devora"] = false
	await _juego(0.4)
	if _n("gorthor_ataque") != 1 or _n("gorthor_devorar") != 1:
		_fallo("8: Gorthor devora: ataque %d, mordisco %d (esperaba 1 y 1)" % [_n("gorthor_ataque"), _n("gorthor_devorar")])
	parte = "voces: Gorthor cae de rodillas"
	_limpiar()
	go["hp"] = 1
	await c._animar_golpe(h, go, 50, "")
	await _juego(0.4)
	if _n("gorthor_herido") != 1 or not go.get("rendido", false):
		_fallo("8: el golpe que deja a Gorthor de rodillas: herido %d, rendido %s" % [_n("gorthor_herido"), go.get("rendido", false)])
	_limpiar()
	c._decidir(go)
	await _juego(0.3)
	if _n("gorthor_caida") != 1:
		_fallo("8: Gorthor cae de rodillas y su caída suena %d veces" % _n("gorthor_caida"))
	await _juego(1.2)
	_limpiar()
	c._acabar(go)
	await _juego(0.4)
	if _n("gorthor_muerte") != 1 or _n("golpe_critico") != 1:
		_fallo("8: «Acabar»: su muerte %d, el golpe %d" % [_n("gorthor_muerte"), _n("golpe_critico")])
	c.queue_free()
	await _esperar(3)
	# la API: los héroes no tienen voz; una voz por enemigo; dos a la vez como mucho; la furia, más fuerte
	parte = "voces: API"
	_limpiar()
	if Son.voz({"hero": true, "modelo": "kael3d", "nombre": "Kael"}, "ataque") != null:
		_fallo("8: un héroe tiene voz")
	var a := {"hero": false, "clave": "grimfang", "nombre": "A"}
	var b := {"hero": false, "clave": "slime", "nombre": "B"}
	var d := {"hero": false, "clave": "guardian", "nombre": "C"}
	var p1 = Son.voz(a, "ataque")
	var p2 = Son.voz(a, "herido")
	if p1 == null or p2 == null or not p1.get_meta("apagando", false):
		_fallo("8: la voz nueva de un enemigo no corta la suya anterior")
	_limpiar()
	Son.voz(a, "ataque")
	Son.voz(b, "ataque")
	Son.voz(d, "ataque")
	var vivas := 0
	for x in Son._todas():
		if x.playing and x.get_meta("grupo", "") == "voz" and not x.get_meta("apagando", false):
			vivas += 1
	if vivas != 2:
		_fallo("8: tres enemigos a la vez: suenan %d voces (máximo 2)" % vivas)
	_limpiar()
	a["furia"] = true
	var f = Son.voz(a, "ataque")
	if f == null or f.volume_db < float(Son.EFECTOS["goblin_ataque"]["db"]) + 1.2:
		_fallo("8: con furia, el ataque no suena más fuerte (%s dB)" % (str(f.volume_db) if f else "no suena"))
	# pasos de varios personajes 3D (animaciones pondrá los de Lya y Garon): uno por cuerpo, sin duplicar
	var cuerpos: Array = []
	for i in 3:
		var n3 := Node3D.new()
		root.add_child(n3)
		cuerpos.append(n3)
	var sup := func(_p): return "hierba"
	var pa = Son.pasos_3d(cuerpos[0], sup)
	var pb = Son.pasos_3d(cuerpos[0], sup, -3.0)
	Son.pasos_3d(cuerpos[1], sup, -3.0)
	Son.pasos_3d(cuerpos[2], sup, -3.0)
	var n_pasos := 0
	for n3 in cuerpos:
		for hijo in n3.get_children():
			if String(hijo.name).begins_with("Pasos"):
				n_pasos += 1
	if pa != pb or n_pasos != 3 or float(pb.db) != -3.0:
		_fallo("8: pasos de tres cuerpos: %d nodos (esperaba 3, uno por cuerpo; pedirlo dos veces no duplica)" % n_pasos)
	for n3 in cuerpos:
		n3.queue_free()
	hechos.append("voces (limo, %s, ámbar, Gorthor: mordisco, rodillas y «Acabar»; magia muda; API; pasos de 3 cuerpos)" % info)


# 9. El agua de las zonas 2D: más cerca, más fuerte; lejos, en silencio; con fundido; se apaga al salir.
func _agua2d() -> void:
	Engine.set_meta("lugar", {"indice": 1, "nombre": "Gran Bosque Verde", "tipo": "lugar", "zona": "llanura", "texto": "x"})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file("res://zona.tscn")
	if not await _hasta(func(): return _en_escena("res://zona.tscn"), 60.0):
		_fallo("9: no se abre la zona")
		return
	await _esperar(10)
	var z = current_scene
	var e = z.get_node_or_null("Sonido_rio_2d")
	if e == null or e.bus != &"Ambiente" or e.stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		_fallo("9: en una llanura con río no hay agua que suene en bucle por Ambiente")
		return
	# sitios de tierra a distintas distancias del agua (las mide el propio emisor)
	var quiero := [0.3, 3.0, 6.0, 11.0]
	var sitios := []
	for q in quiero:
		sitios.append(null)
	var guardado: Vector2 = z.jugador.position
	for y in range(3, z.ALTO - 4):
		for x in range(3, z.ANCHO - 4):
			var pos: Vector2 = Vector2(x + 0.5, y + 0.5) * z.T
			if z._en_agua(pos) or z.muros[y * z.ANCHO + x] != 0:
				continue
			z.jugador.position = pos
			e._buscar()
			for i in quiero.size():
				if sitios[i] != null:
					continue
				var vale := false
				if i == quiero.size() - 1:                 # el último: «lejos» o más
					vale = e.distancia >= quiero[i]
				else:
					vale = absf(e.distancia - quiero[i]) < (0.3 if i == 0 else 0.5)
				if vale:
					sitios[i] = pos
	z.jugador.position = guardado
	if sitios.has(null):
		_fallo("9: no se encuentran sitios a %s casillas del agua (%s)" % [str(quiero), str(sitios)])
		return
	var niveles := []
	var sonando := []
	for i in sitios.size():
		z.jugador.position = sitios[i]
		for k in int(1.6 * 30.0):                          # con el fundido de 0,8 s y la búsqueda cada 0,12 s
			z.pasos = 0
			z.tiene_destino = false
			await process_frame
		niveles.append(e.volume_db)
		sonando.append(e.playing)
	print("AGUA2D distancias %s → %s dB, sonando %s" % [str(quiero), str(niveles.map(func(v): return snappedf(v, 0.1))), str(sonando)])
	if not (sonando[0] and sonando[1] and sonando[2]) or sonando[3]:
		_fallo("9: suena cerca y lejos no: %s (a %s casillas)" % [str(sonando), str(quiero)])
	elif not (niveles[0] > niveles[1] + 3.0 and niveles[1] > niveles[2] + 2.0):
		_fallo("9: el río no suena más cuanto más cerca: %s dB" % str(niveles))
	elif absf(niveles[0] - float(Son.EFECTOS["rio_2d"]["db"])) > 1.5:
		_fallo("9: en la orilla el río no va a su volumen del catálogo (%.1f dB)" % niveles[0])
	# fundido: al volver a la orilla desde lejos, no salta de golpe
	z.jugador.position = sitios[0]
	for k in 6:
		z.pasos = 0
		await process_frame
	if e.volume_db > niveles[0] - 6.0:
		_fallo("9: al llegar a la orilla el río salta de golpe (%.1f dB a los 0,2 s)" % e.volume_db)
	for k in int(1.2 * 30.0):
		z.pasos = 0
		await process_frame
	# al salir (combate o mapa), el agua se funde y deja de sonar
	z.saliendo = true
	for k in int(1.2 * 30.0):
		await process_frame
	if e.playing:
		_fallo("9: al salir de la zona el río sigue sonando")
	z.saliendo = false
	# sin agua de verdad, no hay emisor (la lava, el veneno, el hielo y el abismo, de momento, nada)
	var falsa := ZonaFalsa.new()
	var con_lava := ZonaFalsa.new()
	con_lava.estilo = {"agua": "lava"}
	con_lava.agua_v = PackedByteArray([0, 1, 1, 0])
	if Son.agua_zona(falsa) != null or Son.agua_zona(con_lava) != null:
		_fallo("9: suena agua donde no hay (o es lava)")
	falsa.free()
	con_lava.free()
	hechos.append("agua 2D (%s dB a %s casillas)" % [str(niveles.map(func(v): return snappedf(v, 0.1))), str(quiero)])


class ZonaFalsa extends Node2D:
	var ANCHO := 1
	var ALTO := 1
	var estilo := {"agua": "agua"}
	var agua_v := PackedByteArray([0, 0, 0, 0])


# 10. Interfaz y mundo: el Diario, el brazalete y el altar de una zona.
func _interfaz() -> void:
	_limpiar()
	var d = load("res://diario.gd").new()
	root.add_child(d)
	await _esperar(2)
	d._ir_a_pestana("Combate")
	d._ir_a_pestana("Combate")                             # ya está en esa pestaña: no se pasa ninguna hoja
	d._cerrar()
	await _esperar(2)
	if _n("libro_hoja") != 1 or _n("libro_cerrar") != 1 or _n("ui_tic") != 0:
		_fallo("10: el Diario: hoja %d, cerrar %d, tic %d (esperaba 1, 1 y 0)" % [_n("libro_hoja"), _n("libro_cerrar"), _n("ui_tic")])
	Engine.set_meta("lugar", {"indice": 1, "nombre": "Gran Bosque Verde", "tipo": "lugar", "zona": "llanura", "texto": "x"})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file("res://zona.tscn")
	if not await _hasta(func(): return _en_escena("res://zona.tscn"), 60.0):
		_fallo("10: no se abre la zona")
		return
	await _esperar(10)
	var z = current_scene
	var info := "Diario"
	if z.detalles.is_empty():
		print("AVISO 10: este lugar no tiene detalles de lore: el brazalete no se prueba aquí")
	else:
		_limpiar()
		z.brillados.clear()
		z.jugador.position = z.detalles[0][0].position + Vector2(z.RADIO_BRAZALETE * 0.5, 0)
		z._brazalete()
		z._brazalete()                                     # ya brilló por este detalle: no otra vez
		if _n("brazalete") != (0 if load("res://progreso.gd").visto(z.detalles[0][1]["id"]) else 1):
			_fallo("10: el brazalete suena %d veces junto a un detalle sin ver" % _n("brazalete"))
		info += ", brazalete"
	_limpiar()
	z.cofre_cerca = null
	z.detalle_cerca = null
	z.npc_cerca = null
	z._accion()                                            # examinar el altar
	if _n("examinar") != 1:
		_fallo("10: examinar el altar suena %d veces" % _n("examinar"))
	await _escena_vacia()
	hechos.append(info + " y altar")


# 11. El sonido no usa el generador aleatorio global: la secuencia de randi() es la misma con y sin efectos.
func _azar() -> void:
	_limpiar()
	var falso := {"hero": false, "clave": "grimfang", "nombre": "Z"}
	seed(20261109)
	var sin_sonido := [randi(), randi(), randf(), randi_range(0, 1000)]
	seed(20261109)
	for i in 12:
		Son._ultimo.clear()
		Son.efecto("paso_hierba")
		Son.golpe(i % 3 == 0)
		Son.voz(falso, "ataque" if i % 2 == 0 else "herido")
		Son.efecto("monedas")
	var con_sonido := [randi(), randi(), randf(), randi_range(0, 1000)]
	if sin_sonido != con_sonido:
		_fallo("11: los efectos cambian el generador aleatorio global (%s ≠ %s)" % [str(sin_sonido), str(con_sonido)])
	_limpiar()
	hechos.append("aleatorio propio")
