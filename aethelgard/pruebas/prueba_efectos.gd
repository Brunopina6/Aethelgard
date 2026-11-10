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
# Tanda 3 (T-083):
#  12. La Garganta 3D (partes «garganta3d»): se escucha desde Kael; la cascada grande y el viento del abismo suenan en
#      bucle por Ambiente y siguen a quien escucha (la cascada, a su altura; el viento, a lo largo del abismo y bajo los
#      puentes); el eco está en Efectos y Ambiente y se quita al salir; pasos de roca en la cornisa y de tablas en un
#      puente colgante, también los de Lya y Garon (un nodo de pasos cada uno, desde su pie, en el espacio, y más bajos
#      que los de Kael); las gotas caen en la pared de roca; guardar, la puerta, el ascensor sin fuerza, la palanca (con
#      el puente y la puerta, desde donde están), el ascensor, el cofre raro y examinar suenan una vez aunque se pulse
#      dos veces; la emboscada, una, y en el combate ya no hay eco.
#  13. Artes (parte «artes»): los efectos que pide artes.gd existen, suenan una vez, por Efectos y con su prioridad;
#      el Aliento, uno a la vez; la coraza que absorbe, dos a la vez como mucho; la esquiva.
#  14. Oakhaven (parte «oakhaven»): fuentes 2D de la taberna (bucle, más cuanto más cerca, callada lejos, con fundido) y
#      del cuervo (de vez en cuando, solo cerca), la campana una vez y la ola de faroles.
#  15. Efectos en el espacio (parte «espacio»): con «pos» suenan desde ese punto con su distancia de referencia; sin
#      escucha 3D suenan normal; el máximo de voces 3D.
# Tanda 4 (T-097):
#  16. Las bestias del bestiario (parte «bestias»): cada efecto de BESTIAS existe, carga (QOA, mono, 48 kHz) y suena una
#      vez aunque se pida dos veces, por Efectos; los avisos acaban antes del impacto de su ficha y tienen prioridad 3;
#      la voz sale de su familia (herido y caída con Sonido.recibe), no tienen «_ataque»; el Posadero suena por encima
#      (más prioridad y, con dos voces sonando, la suya entra).
#  17. Los héroes quietos (parte «quietos»): Kael, Lya y Garon parados suenan con su gesto (cada uno el suyo), nunca dos
#      a la vez, por Efectos y con prioridad 0; andando, ninguno.
# Tanda 5:
#  18. Las voces de los héroes (parte «heroes»): Kael, Lya y Garon con su esfuerzo, herido, jadeo (una vez con poca
#      vida, otra tras curarse), alivio y victoria; prioridad 1 (victoria 3), una a la vez; en un combate de verdad, el
#      golpe de un enemigo hace quejarse al héroe y la magia sigue sin pedir voces.
#  19. Las cuerdas y el viento de los puentes de la Garganta 3D (parte «cuerdas»): suenan de vez en cuando (no en bucle),
#      desde el punto de su línea más cercano a quien escucha, por Ambiente; lejos (más de «max»), nada.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const GARGANTA3D := "res://zonas3d/garganta_3d.tscn"
const T3 := preload("res://zonas3d/garganta/trazado.gd")
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
	if _parte("espacio"):
		await _espacio()
	if _parte("artes"):
		await _artes()
	if _parte("oakhaven"):
		await _oakhaven()
	if _parte("bestias"):
		await _bestias()
	if _parte("quietos"):
		await _quietos()
	if _parte("heroes"):
		await _heroes()
	if _parte("cuerdas"):
		await _cuerdas()
	if _parte("ciudad"):
		await _ciudad_viva()
	if _parte("mezcla"):
		await _mezcla()
	if _parte("garganta3d"):
		await _garganta3d()
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
			var hz_esperado: int = load("res://pruebas/prueba_audio_memoria.gd").FRECUENCIA.get(ruta, 48000)   # tanda 7: bucles bajados
			if not s is AudioStreamWAV or s.format != AudioStreamWAV.FORMAT_QOA or s.stereo or s.mix_rate != hz_esperado:
				_fallo("1: %s no es QOA mono a %d Hz" % [ruta, hz_esperado])
				continue
			# bucles: los emisores 3D y las fuentes 2D, salvo las que suenan de vez en cuando («cada»: el cuervo)
			var bucle: bool = (d.has("tres_d") or d.has("dos_d")) and not d.get("dos_d", {}).has("cada") \
				and not d.get("tres_d", {}).has("cada")
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
	var max_pasos := int(Son.EFECTOS["paso_hierba"]["max"])     # 3 desde la tanda 3 (Kael, Lya y Garon)
	if iguales > max_pasos:
		_fallo("2: suenan %d pasos de hierba a la vez (máximo %d)" % [iguales, max_pasos])
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
	if Son.voz({"hero": true, "modelo": "x", "nombre": "Nadie"}, "ataque") != null:
		_fallo("8: un héroe sin familia (FAMILIAS_HEROE) tiene voz")
	_limpiar()
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


# ================================================================= tanda 3

const ARTES := ["arte_alba", "arte_ocaso", "arte_hora_dorada", "arte_escarcha", "arte_lumbre", "renacer", "aliento",
	"barrera_absorbe", "barrera_rota", "brasa", "esquiva"]


func _sonando_de(nombre: String) -> int:
	var n := 0
	for x in Son._todas():
		if x.playing and x.get_meta("efecto", "") == nombre:
			n += 1
	return n


# Una escena 3D mínima con su cámara (la que escucha si no hay oyente de personaje).
func _escena_3d() -> void:
	var raiz := Node3D.new()
	raiz.name = "Espacio"
	var cam := Camera3D.new()
	cam.name = "Cam"
	raiz.add_child(cam)
	cam.owner = raiz
	var ps := PackedScene.new()
	ps.pack(raiz)
	raiz.free()
	change_scene_to_packed(ps)
	await _esperar(3)
	current_scene.get_node("Cam").make_current()
	await _esperar(1)


# 15. Efectos en el espacio.
func _espacio() -> void:
	await _escena_vacia()
	_limpiar()
	var p = Son.efecto("gota", {"pos": Vector3(3, 0, 0)})
	if p == null or p is AudioStreamPlayer3D:
		_fallo("15: sin escucha 3D, un efecto con «pos» no suena normal (%s)" % str(p))
	await _escena_3d()
	_limpiar()
	var q = Son.efecto("puente_baja", {"pos": Vector3(0, 0, -20)})
	if not q is AudioStreamPlayer3D or q.get_parent() != current_scene:
		_fallo("15: con «pos» y una cámara 3D, el efecto no suena desde un reproductor 3D de la escena (%s)" % str(q))
	elif absf(q.unit_size - 14.0) > 0.01 or q.global_position.distance_to(Vector3(0, 0, -20)) > 0.01 or q.max_db > 0.0 \
			or q.attenuation_filter_db != 0.0 or String(q.bus) != "Efectos":
		_fallo("15: el puente que baja no suena desde su sitio con su «en_3d» (unidad %.1f, en %s)" % [q.unit_size, q.global_position])
	var g = Son.efecto("gota", {"pos": Vector3(2, 0, 0)})
	if not g is AudioStreamPlayer3D or absf(g.unit_size - float(Son.EN_3D["unidad"])) > 0.01 or String(g.bus) != "Ambiente":
		_fallo("15: una gota en el espacio no lleva la distancia por defecto ni su bus")
	if Son.registro.is_empty() or not Son.registro[Son.registro.size() - 1][4] is Vector3:
		_fallo("15: el registro no apunta dónde sonó")
	# como mucho VOCES_3D a la vez; sin hueco, lo menos importante no quita nada
	_limpiar()
	var nombres := ["cofre", "tesoro", "palanca", "puente_baja", "guardado", "posada", "misterio", "union", "nivel",
		"carga_jefe", "pagina", "examinar"]
	for i in nombres.size():
		Son.efecto(nombres[i], {"pos": Vector3(i, 0, -5)})
	var en_3d := 0
	for x in Son._voces3d:
		if is_instance_valid(x) and x.playing:
			en_3d += 1
	if en_3d != Son.VOCES_3D:
		_fallo("15: doce efectos en el espacio ocupan %d voces 3D (esperaba %d)" % [en_3d, Son.VOCES_3D])
	if _n("examinar") != 0 or _n("pagina") != 0:
		_fallo("15: sin voces 3D libres, algo menos importante quita una (examinar %d, página %d)" % [_n("examinar"), _n("pagina")])
	await _escena_vacia()
	var vivos: int = Son._voces3d.filter(func(x): return is_instance_valid(x)).size()
	if vivos != 0:
		_fallo("15: quedan %d reproductores 3D de la escena anterior" % vivos)
	hechos.append("efectos en el espacio (%d voces 3D)" % en_3d)


# 13. Las artes nuevas (artes.gd pide sus efectos por estos nombres; combate.gd los engancha).
func _artes() -> void:
	await _escena_vacia()
	var A = load("res://artes.gd")
	var pide: Array = []
	for fam in A.SONIDO_LANZAR:
		for n in A.SONIDO_LANZAR[fam]:
			if not n in pide:
				pide.append(n)
	for k in A.SONIDO_ESTADO:
		if not A.SONIDO_ESTADO[k] in pide:
			pide.append(A.SONIDO_ESTADO[k])
	for n in ARTES + pide:
		if not Son.EFECTOS.has(n):
			_fallo("13: falta «%s» en el catálogo (lo piden artes.gd o combate.gd)" % n)
	for n in ARTES:
		if not Son.EFECTOS.has(n):
			continue
		_limpiar()
		var p = Son.efecto(n)
		var q = Son.efecto(n)
		var d: Dictionary = Son.EFECTOS[n]
		if p == null or q != null or _n(n) != 1:
			_fallo("13: «%s» pedido dos veces en el mismo instante suena %d veces" % [n, _n(n)])
			continue
		if String(p.bus) != "Efectos":
			_fallo("13: «%s» no va por Efectos (%s)" % [n, p.bus])
		var esperada := 1 if n in ["aliento", "barrera_absorbe"] else (2 if n == "esquiva" else 3)
		if int(d.get("p", 1)) != esperada:
			_fallo("13: «%s» tiene prioridad %d (esperaba %d)" % [n, int(d.get("p", 1)), esperada])
	_limpiar()
	for i in 3:
		Son._ultimo.erase("aliento")
		Son.efecto("aliento")
	if _sonando_de("aliento") != 1:
		_fallo("13: suenan %d Alientos a la vez (uno como mucho)" % _sonando_de("aliento"))
	_limpiar()
	for i in 4:
		Son._ultimo.erase("barrera_absorbe")
		Son.efecto("barrera_absorbe")
	if _sonando_de("barrera_absorbe") > 2 or _n("barrera_absorbe") != 4:
		_fallo("13: la coraza que absorbe: %d a la vez (máximo 2), %d de 4" % [_sonando_de("barrera_absorbe"), _n("barrera_absorbe")])
	_limpiar()
	Son.efecto("barrera_absorbe")
	await _juego(0.03)
	if Son.efecto("barrera_absorbe") != null:
		_fallo("13: la coraza que absorbe suena dos veces en menos de 0,05 s")
	_limpiar()
	hechos.append("artes (%d efectos; los %d que pide artes.gd están)" % [ARTES.size(), pide.size()])


# 14. Oakhaven: fuentes 2D (taberna y cuervo), la campana y la ola de faroles. Una ciudad de mentira con casillas de
# 64 px y quien anda.
func _oakhaven() -> void:
	await _escena_vacia()
	_limpiar()
	var c := Node2D.new()
	c.name = "OakhavenFalsa"
	root.add_child(c)
	var quien := Node2D.new()
	c.add_child(quien)
	var t := 64.0
	var puerta := Vector2(16, 25) * t
	var letrero := Vector2(13, 25.5) * t
	quien.position = puerta + Vector2(0, 1) * t
	var tab = Son.fuente_2d(c, "taberna", puerta, quien)
	var cue = Son.fuente_2d(c, "cuervo", letrero, quien)
	if tab == null or cue == null:
		_fallo("14: no se crean las fuentes de la taberna y del cuervo")
		c.queue_free()
		return
	if tab.bus != &"Ambiente" or tab.stream == null or tab.stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		_fallo("14: la taberna no es un bucle por Ambiente")
	if Son.fuente_2d(c, "golpe", puerta, quien) != null or Son.fuente_2d(c, "rio_2d", puerta, quien) != null:
		_fallo("14: fuente_2d acepta un efecto que no es una fuente del mundo")
	await _juego(0.2)
	var al_entrar: float = tab.volume_db
	var niveles := []
	var sonando := []
	for casillas in [1.0, 5.0, 13.0]:
		quien.position = puerta + Vector2(0, casillas) * t
		await _juego(1.4)
		niveles.append(tab.volume_db)
		sonando.append(tab.playing)
	print("TABERNA a 1, 5 y 13 casillas: %s dB, sonando %s (al entrar %.1f dB)" % [str(niveles.map(func(v): return snappedf(v, 0.1))),
		str(sonando), al_entrar])
	var db: float = Son.EFECTOS["taberna"]["db"]
	if not (sonando[0] and sonando[1]) or sonando[2]:
		_fallo("14: la taberna suena cerca y no lejos: %s" % str(sonando))
	elif absf(niveles[0] - db) > 1.0 or niveles[1] > niveles[0] - 4.0:
		_fallo("14: la taberna no suena más cuanto más cerca (%s dB)" % str(niveles))
	if al_entrar > niveles[0] - 3.0:
		_fallo("14: la taberna empieza de golpe (%.1f dB a los 0,2 s)" % al_entrar)
	# el cuervo: cerca, de vez en cuando; lejos, nunca
	quien.position = letrero + Vector2(1.5, 0) * t
	Son.reiniciar_contadores()
	await _juego(30.0)
	var cerca_n := _n("cuervo")
	quien.position = letrero + Vector2(20, 0) * t
	Son.reiniciar_contadores()
	await _juego(25.0)
	var lejos_n := _n("cuervo")
	if cerca_n < 2 or cerca_n > 8 or lejos_n != 0:
		_fallo("14: el cuervo chirría %d veces en 30 s cerca y %d en 25 s lejos" % [cerca_n, lejos_n])
	if cue.stream != null and cue.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD:
		_fallo("14: el cuervo suena en bucle")
	# la campana, una vez; la ola de faroles (cinco seguidos: tres a la vez como mucho)
	_limpiar()
	Son.efecto("campana")
	Son.efecto("campana")
	if _n("campana") != 1 or String(Son.EFECTOS["campana"].get("bus", "")) != "Ambiente":
		_fallo("14: la campana suena %d veces (o no va por Ambiente)" % _n("campana"))
	for i in 5:
		Son.efecto("farol", {"retraso": 0.15 * i, "db": -2.0 * i})
	var max_a_la_vez := 0
	for f in 40:
		await process_frame
		max_a_la_vez = maxi(max_a_la_vez, _sonando_de("farol"))
	if _n("farol") != 5 or max_a_la_vez > 3:
		_fallo("14: la ola de faroles: suenan %d de 5, %d a la vez (máximo 3)" % [_n("farol"), max_a_la_vez])
	c.queue_free()
	await _esperar(3)
	hechos.append("Oakhaven (taberna %s dB a 1/5/13 casillas, cuervo %d veces cerca y %d lejos, campana y faroles)" % [
		str(niveles.map(func(v): return snappedf(v, 0.1))), cerca_n, lejos_n])


# Kael en «p», con la y del suelo de debajo (como prueba_garganta3d).
func _poner3(r, p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 2.0, 0), p - Vector3(0, 6.0, 0))
	var hit: Dictionary = r.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		p.y = hit["position"].y
	r._colocar_kael(p)
	r._ultima = p


func _efectos_bus() -> Dictionary:
	var d := {}
	for b in ["Efectos", "Ambiente", "Musica", "Interfaz"]:
		d[b] = AudioServer.get_bus_effect_count(AudioServer.get_bus_index(b))
	return d


# 12. La Garganta 3D.
func _garganta3d() -> void:
	await _escena_vacia()
	var efectos_antes := _efectos_bus()
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto"]:
		Engine.set_meta(k, {})
	# Gorthor ya vencido: así la arena (donde se mira la cascada de cerca) no empieza su combate
	Engine.set_meta("combates_ganados", {"garganta_gorthor": true})
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # Lya y Garon en el grupo
	if Engine.has_meta("grupo_activo"):
		Engine.remove_meta("grupo_activo")
	change_scene_to_file(GARGANTA3D)
	if not await _hasta(func(): return _en_escena(GARGANTA3D), 120.0):
		_fallo("12: no se abre la Garganta 3D")
		return
	await _esperar(20)
	var r = current_scene
	parte = "garganta3d: oyente, bucles y eco"
	var oy = r.get_node_or_null("Oyente")
	if oy == null or not oy.is_current() or oy.sigue != r.kael:
		_fallo("12: no se escucha desde Kael")
	var cascada = r.get_node_or_null("Sonido_cascada_grande")
	var vientos: Array = r.get_children().filter(func(x): return x is AudioStreamPlayer3D and x.get_meta("efecto", "") == "viento_abismo")
	if cascada == null or vientos.size() != 2:
		_fallo("12: falta la cascada o los dos vientos del abismo (%s, %d)" % [str(cascada), vientos.size()])
		return
	for x in [cascada] + vientos:
		if not x.playing or x.bus != &"Ambiente" or x.stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			_fallo("12: «%s» no suena en bucle por Ambiente" % x.name)
	var con_eco: Array = Son.eco_activo()
	var efectos_dentro := _efectos_bus()
	if con_eco != ["Efectos", "Ambiente"] or efectos_dentro["Efectos"] != efectos_antes["Efectos"] + 1 \
			or efectos_dentro["Ambiente"] != efectos_antes["Ambiente"] + 1 or efectos_dentro["Musica"] != efectos_antes["Musica"] \
			or efectos_dentro["Interfaz"] != efectos_antes["Interfaz"]:
		_fallo("12: el eco no está (solo) en Efectos y Ambiente (%s; efectos %s → %s)" % [str(con_eco), str(efectos_antes), str(efectos_dentro)])
	# la cascada suena desde su caída a la altura de quien escucha; el viento, desde el eje del abismo
	_poner3(r, Vector3(-8.5, 0, -31.0))                    # la arena
	await _esperar(4)
	var o: Vector3 = Son.posicion_oyente()
	if absf(cascada.global_position.y - o.y) > 0.8 or absf(cascada.global_position.x - 3.6) > 0.01:
		_fallo("12: la cascada no suena a la altura de quien escucha (%s; oyente %s)" % [cascada.global_position, o])
	var eje = vientos[0] if absf(vientos[0].global_position.x - T3.X_CAMINO_O) > 1.0 else vientos[1]
	if absf(eje.global_position.z - o.z) > 0.8 or absf(eje.global_position.x - (T3.X_BORDE_O + T3.X_BORDE_E) * 0.5) > 0.01:
		_fallo("12: el viento del abismo no se pone frente a quien escucha (%s; oyente %s)" % [eje.global_position, o])
	var d_cascada: float = o.distance_to(cascada.global_position)
	# pasos: un nodo por personaje; Kael en la cornisa (roca) y por un puente colgante (tablas); Lya y Garon, desde su pie
	parte = "garganta3d: pasos"
	var cuerpos := {"Kael": r.kael}
	if r.grupo != null:
		for m in r.grupo.miembros:
			cuerpos[m["nombre"]] = m["nodo"]
	if cuerpos.size() != 3:
		_fallo("12: en la Garganta no van Lya y Garon (%s)" % str(cuerpos.keys()))
	for n in cuerpos:
		var nodos: Array = cuerpos[n].get_children().filter(func(x): return String(x.name).begins_with("Pasos"))
		if nodos.size() != 1:
			_fallo("12: %s lleva %d nodos de pasos (uno)" % [n, nodos.size()])
	_poner3(r, Vector3(T3.X_CAMINO_O, 0, 25.0))
	if r.grupo != null:
		r.grupo.colocar(Vector3.BACK)
	await _esperar(10)
	_limpiar()
	for n in cuerpos:
		var pn = cuerpos[n].get_node_or_null("Pasos")
		if pn != null:
			pn.pasos = 0
	r.destino = r._ajustar_destino(Vector3(T3.X_CAMINO_O, 0, 12.5))
	for f in 300:
		r.pasos = 0
		await process_frame
		if r.destino == null and f > 60:
			break
	for f in 45:                                           # que lleguen los de detrás
		r.pasos = 0
		await process_frame
	var kael_madera := 0
	var kael_piedra := 0
	var kael_otro := 0
	var comp := 0
	var comp_lejos := 0
	for x in Son.registro:
		if not String(x[1]).begins_with("paso_"):
			continue
		if x[4] == null:
			if x[1] == "paso_madera":
				kael_madera += 1
			elif x[1] == "paso_piedra":
				kael_piedra += 1
			else:
				kael_otro += 1
		else:
			comp += 1
			var pie: Vector3 = x[4]
			if absf(pie.x - T3.X_CAMINO_O) > 1.6 or pie.y < T3.ALTO - 2.5 or pie.y > T3.ALTO + 1.0:
				comp_lejos += 1
	var info := "Kael %d de tablas y %d de roca; compañeros %d en el espacio" % [kael_madera, kael_piedra, comp]
	print("GARGANTA3D pasos: ", info)
	if kael_madera < 3 or kael_piedra < 1 or kael_otro != 0:
		_fallo("12: por la cornisa y un puente, los pasos de Kael: %s (otros %d)" % [info, kael_otro])
	if comp < 3 or comp_lejos > 0:
		_fallo("12: los pasos de Lya y Garon no suenan desde su pie en el espacio (%d, %d fuera del camino)" % [comp, comp_lejos])
	var total_pasos := 0
	var por_cuerpo := []
	for n in cuerpos:
		var pn = cuerpos[n].get_node_or_null("Pasos")
		if pn == null:
			continue
		total_pasos += int(pn.pasos)
		por_cuerpo.append("%s %d/%d" % [n, int(pn.sonados), int(pn.pasos)])
		if n == "Kael":
			if pn.ultimo != null and pn.ultimo is AudioStreamPlayer3D:
				_fallo("12: los pasos de Kael (quien escucha) suenan en el espacio")
		elif int(pn.pasos) > 0 and (pn.ultimo == null or not pn.ultimo is AudioStreamPlayer3D
				or absf(pn.ultimo.unit_size - float(Son.PASO_3D["unidad"])) > 0.01):
			_fallo("12: los pasos de %s no son de un reproductor 3D con la distancia de los pasos" % n)
		if n != "Kael" and absf(float(pn.db) - float(Son.DB_PASOS.get(n, 0.0))) > 0.001:
			_fallo("12: los pasos de %s no llevan su volumen (%.1f dB)" % [n, float(pn.db)])
	var sonados := kael_madera + kael_piedra + kael_otro + comp
	print("GARGANTA3D pisadas que suenan por cuerpo: ", ", ".join(por_cuerpo))
	if sonados > total_pasos or sonados < total_pasos * 0.85:
		_fallo("12: %d pisadas y %d pasos que suenan (ni duplicados ni perdidos: %s)" % [total_pasos, sonados, ", ".join(por_cuerpo)])
	if not is_instance_valid(r) or current_scene != r or r.saliendo:
		_fallo("12: la Garganta se ha ido durante la prueba (¿un encuentro?)")
		return
	# las gotas caen en la roca
	parte = "garganta3d: gotas"
	_limpiar()
	var gotas := 0
	var en_roca := 0
	for k in 4:
		Son._ultimo.clear()
		Son._det_t = 0.0
		await _esperar(2)
		for x in Son.registro:
			if String(x[1]).begins_with("gota") and x[4] is Vector3:
				gotas += 1
				var gp: Vector3 = x[4]
				var muro: float = T3.muro_oeste(gp.z) if gp.x < 0.0 else T3.muro_este(gp.z)
				if absf(gp.x - muro) < 1.0:
					en_roca += 1
		Son.registro.clear()
	if gotas < 3 or en_roca != gotas:
		_fallo("12: las gotas: %d en el espacio, %d en la pared de roca" % [gotas, en_roca])
	# los efectos de la 2D, una vez cada uno (dos pulsaciones seguidas)
	parte = "garganta3d: efectos de la 2D"
	var acciones := [["guardado_1", ["guardado"]], ["puerta", ["cerrada"]], ["ascensor_arriba", ["atascado"]]]
	for a in acciones:
		_limpiar()
		r._bloqueo = 0.0
		r.cerca = a[0]
		r._accion()
		r._accion()
		r._bloqueo = 0.0
		r.cerca = a[0]
		r._accion()                                        # sin el bloqueo de la pulsación: la espera del efecto
		for k in a[1]:
			if _n(k) != 1:
				_fallo("12: «%s» suena %d veces (una)" % [k, _n(k)])
		if _n("ascensor") != 0:
			_fallo("12: sin la palanca, suena el ascensor")
	_poner3(r, T3.PALANCA + Vector3(-1.6, 0, 1.0))
	await _esperar(3)
	_limpiar()
	r._bloqueo = 0.0
	r.cerca = "palanca"
	r._accion()
	r._accion()
	await _juego(1.8)
	for k in ["palanca", "puente_baja", "puerta_abre"]:
		if _n(k) != 1:
			_fallo("12: la palanca: «%s» suena %d veces (una)" % [k, _n(k)])
	for x in Son.registro:
		if x[1] == "puente_baja" and (not x[4] is Vector3 or x[4].distance_to((T3.BISAGRA + T3.APOYO) * 0.5) > 0.1):
			_fallo("12: el puente no suena desde el levadizo (%s)" % str(x[4]))
		if x[1] == "puerta_abre" and (not x[4] is Vector3 or x[4].distance_to(T3.PUERTA + Vector3(0, 1.5, 0)) > 0.1):
			_fallo("12: la puerta no suena desde la puerta (%s)" % str(x[4]))
		if x[1] == "palanca" and x[4] != null:
			_fallo("12: la palanca (junto a Kael) suena en el espacio")
	await _hasta(func(): return not r.tirando, 30.0)
	_limpiar()
	r._bloqueo = 0.0
	r.cerca = "ascensor_arriba"
	r._accion()
	r._accion()
	if _n("ascensor") != 1 or _n("atascado") != 0:
		_fallo("12: con la palanca, el ascensor: viaje %d, atascado %d" % [_n("ascensor"), _n("atascado")])
	await _hasta(func(): return not r.viajando, 30.0)
	if not is_instance_valid(r) or current_scene != r or r.saliendo:
		_fallo("12: la Garganta se ha ido durante la prueba (¿un encuentro?)")
		return
	_limpiar()
	r._abrir_cofre()
	await _juego(0.5)
	r._abrir_cofre()
	await _juego(0.5)
	if _n("cofre") != 1 or _n("tesoro") != 1:
		_fallo("12: el cofre raro: cofre %d, premio %d" % [_n("cofre"), _n("tesoro")])
	_limpiar()
	r._bloqueo = 0.0
	r.cerca = "detalle_p2"
	r._accion()
	r._accion()
	if _n("examinar") != 1:
		_fallo("12: examinar los pilares suena %d veces" % _n("examinar"))
	# la emboscada, una vez; en el combate, sin eco
	parte = "garganta3d: emboscada"
	await _juego(0.5)
	_limpiar()
	r._encuentro()
	if not await _hasta(func(): return _en_escena("res://combate.tscn"), 60.0):
		_fallo("12: la emboscada no lleva al combate")
		return
	await _esperar(5)
	if _n("emboscada") != 1:
		_fallo("12: la emboscada suena %d veces" % _n("emboscada"))
	var fx_ahora := _efectos_bus()
	if not Son.eco_activo().is_empty() or fx_ahora["Efectos"] != efectos_antes["Efectos"] or fx_ahora["Ambiente"] != efectos_antes["Ambiente"]:
		_fallo("12: en el combate sigue el eco de la Garganta (%s; %s)" % [str(Son.eco_activo()), str(fx_ahora)])
	if is_instance_valid(cascada):
		_fallo("12: en el combate sigue la cascada")
	await _escena_vacia()
	hechos.append("Garganta 3D (oyente, cascada a %.0f m, vientos, eco, %s, gotas %d, efectos de la 2D una vez)" % [d_cascada, info, gotas])


# ================================================================= tanda 4

# 16. Las seis bestias del bestiario (solo el catálogo: combate las engancha). Impacto de cada ataque según su ficha (s
# desde el principio del clip): el aviso que suena al empezar el ataque acaba antes (con 0,1 s de margen).
const IMPACTO_FICHA := {"zarzalin_aviso_colmillo": 0.47, "cencerrante_aviso_alarma": 0.73, "cencerrante_aviso_campanada": 0.53,
	"velaria_aviso_destello": 0.70, "velaria_aviso_corte": 0.50, "custodio_aviso_portazo": 0.83, "custodio_aviso_martillo": 0.83,
	"hilandera_aviso_mordida": 0.73, "hilandera_aviso_trama": 0.83, "posadero_aviso_cierre": 0.97, "posadero_aviso_llave": 0.87}


func _bestias() -> void:
	await _escena_vacia()
	var n := 0
	for fam in Son.BESTIAS:
		var grupos: Array = Son.BESTIAS[fam]
		for k in 3:
			for nombre in grupos[k]:
				n += 1
				var d: Dictionary = Son.EFECTOS.get(nombre, {})
				if d.is_empty():
					_fallo("16: falta «%s» en el catálogo" % nombre)
					continue
				var rutas: Array = []
				for i in int(d.get("n", 1)):
					rutas.append(Son.EF + d["a"] + (str(i + 1) if d.has("n") else "") + ".wav")
				for ruta in rutas:
					var s = load(ruta) if ResourceLoader.exists(ruta) else null
					if not s is AudioStreamWAV or s.format != AudioStreamWAV.FORMAT_QOA or s.stereo or s.mix_rate != 48000:
						_fallo("16: %s no carga como QOA mono a 48 kHz" % ruta)
					elif k == 0 and IMPACTO_FICHA.has(nombre) and s.get_length() > float(IMPACTO_FICHA[nombre]) + 0.1:
						_fallo("16: el aviso «%s» dura %.2f s y su impacto llega a %.2f s" % [nombre, s.get_length(), IMPACTO_FICHA[nombre]])
				_limpiar()
				var p = Son.efecto(nombre)
				var q = Son.efecto(nombre)
				if p == null or q != null or _n(nombre) != 1:
					_fallo("16: «%s» pedido dos veces en el mismo instante suena %d veces" % [nombre, _n(nombre)])
				elif String(p.bus) != "Efectos":
					_fallo("16: «%s» no va por Efectos (%s)" % [nombre, p.bus])
				var pr := int(d.get("p", 1))
				if k == 0 and pr != 3:
					_fallo("16: el aviso «%s» tiene prioridad %d (esperaba 3)" % [nombre, pr])
				if fam == "posadero" and pr < 3:
					_fallo("16: «%s» (el jefe opcional) tiene prioridad %d: debe sonar por encima" % [nombre, pr])
		# la voz por su familia: herido y caída con recibe(); sin voz de «ataque» (el aviso hace ese papel)
		var q := {"hero": false, "clave": fam, "nombre": fam, "hp": 5}
		if Son.familia(q) != fam:
			_fallo("16: la clave «%s» no lleva a su familia (%s)" % [fam, Son.familia(q)])
		_limpiar()
		Son.recibe(q)
		q["hp"] = 0
		await _juego(0.4)
		Son.recibe(q)
		if _n(fam + "_herido") != 1 or _n(fam + "_caida") != 1:
			_fallo("16: %s: herido %d, caída %d (esperaba 1 y 1)" % [fam, _n(fam + "_herido"), _n(fam + "_caida")])
		if Son.voz(q, "ataque") != null:
			_fallo("16: %s tiene voz de «ataque»" % fam)
	for clave in ["custodio_cal", "hilandera_eco", "posadero_hueco"]:
		if Son.familia({"clave": clave}) == "":
			_fallo("16: la clave de la ficha «%s» no tiene familia" % clave)
	# el Posadero por encima: con dos voces de otras bestias sonando (el máximo), su voz entra; la de otra bestia, no
	_limpiar()
	Son.voz({"hero": false, "clave": "velaria", "nombre": "V"}, "herido")
	Son.voz({"hero": false, "clave": "zarzalin", "nombre": "Z"}, "herido")
	var po = Son.voz({"hero": false, "clave": "posadero", "nombre": "P"}, "herido")
	if po == null:
		_fallo("16: con dos voces sonando, la del Posadero no entra")
	_limpiar()
	Son.voz({"hero": false, "clave": "posadero", "nombre": "P"}, "herido")
	Son.voz({"hero": false, "clave": "custodio", "nombre": "C"}, "caida")
	if Son.voz({"hero": false, "clave": "zarzalin", "nombre": "Z"}, "herido") != null:
		_fallo("16: una voz de herido quita la del Posadero")
	_limpiar()
	hechos.append("bestias (%d efectos de 6 bestias: cargan, una vez, avisos antes del impacto, voces por familia, el Posadero por encima)" % n)

# 17. Los héroes quietos en la exploración 3D: un gesto discreto de cada uno al rato de pararse, uno a la vez.
func _quietos() -> void:
	await _escena_vacia()
	_limpiar()
	var sup := func(_p): return "hierba"
	var cuerpos := {}
	for nombre in ["Kael", "Lya", "Garon"]:
		var n3 := Node3D.new()
		n3.name = nombre
		root.add_child(n3)
		cuerpos[nombre] = Son.pasos_3d(n3, sup)
	var a_la_vez := 0
	var desde := -1                                           # sin ventana el driver es mudo y nada acaba solo: un
	for i in int(45.0 * 30):                                  # gesto se da por acabado a los 2 s (duran 1,6 como mucho)
		await process_frame
		var ahora: int = Son.grupo_sonando("quieto")
		a_la_vez = maxi(a_la_vez, ahora)
		if ahora > 0 and desde < 0:
			desde = i
		elif ahora > 0 and i - desde >= 60:
			for p in Son._todas():
				if p.get_meta("grupo", "") == "quieto":
					p.stop()
			desde = -1
	for nombre in cuerpos:
		var g: int = cuerpos[nombre].gestos
		var efecto: String = Son.QUIETO_DE[nombre]
		if g < 1 or _n(efecto) < 1:
			_fallo("17: %s parado 45 s no hace ningún gesto (%d; descartes %s)" % [nombre, g, str(Son.descartes)])
		elif g > 3:
			_fallo("17: %s hace %d gestos en 45 s (demasiados: no es discreto)" % [nombre, g])
		var d: Dictionary = Son.EFECTOS[efecto]
		if int(d.get("p", 1)) != 0 or String(d.get("bus", "Efectos")) != "Efectos":
			_fallo("17: «%s» no va por Efectos con prioridad 0" % efecto)
	if a_la_vez > 1:
		_fallo("17: suenan %d gestos de quieto a la vez (uno como mucho)" % a_la_vez)
	# andando, ninguno: Garon se mueve sin parar 30 s
	var garon: Node3D = cuerpos["Garon"].cuerpo
	var antes: int = cuerpos["Garon"].gestos
	for i in int(30.0 * 30):
		garon.position.x += 2.0 / 30.0
		await process_frame
	if cuerpos["Garon"].gestos != antes:
		_fallo("17: Garon andando hace gestos de quieto")
	var info := "%d/%d/%d gestos" % [cuerpos["Kael"].gestos, cuerpos["Lya"].gestos, antes]
	for nombre in cuerpos:
		cuerpos[nombre].cuerpo.queue_free()
	_limpiar()
	hechos.append("quietos (Kael, Lya y Garon: %s en 45 s, uno a la vez; andando, ninguno)" % info)

# ================================================================= tanda 5

# 18. Las voces de los héroes en combate (no verbales).
func _heroes() -> void:
	await _escena_vacia()
	var gd: Dictionary = Son.EFECTOS.get("guardia", {})          # la Guardia de Garon: su propio efecto
	if gd.is_empty() or int(gd.get("p", 0)) != 2 or String(gd.get("bus", "Efectos")) != "Efectos" or gd["a"] == Son.EFECTOS["defensa"]["a"]:
		_fallo("18: falta «guardia» (propio, por Efectos, prioridad 2)")
	_limpiar()
	if Son.efecto("guardia") == null or Son.efecto("guardia") != null:
		_fallo("18: «guardia» pedido dos veces en el mismo instante no suena una vez")
	for nombre in ["Kael", "Lya", "Garon"]:
		var fam: String = Son.FAMILIAS_HEROE[nombre]
		var h := {"hero": true, "nombre": nombre, "modelo": "x", "hp": 100, "hp_max": 100}
		for ev in ["esfuerzo", "herido", "jadeo", "alivio", "victoria"]:
			var d: Dictionary = Son.EFECTOS.get(fam + "_" + ev, {})
			if d.is_empty():
				_fallo("18: falta «%s_%s»" % [fam, ev])
				continue
			var esperada := 3 if ev == "victoria" else 1
			if int(d.get("p", 1)) != esperada or d.get("grupo", "") != "voz_heroe" or String(d.get("bus", "Efectos")) != "Efectos":
				_fallo("18: «%s_%s» no va por Efectos con prioridad %d y grupo voz_heroe" % [fam, ev, esperada])
			if int(d.get("p", 1)) >= int(Son.EFECTOS["golpe"]["p"]) and ev != "victoria":
				_fallo("18: «%s_%s» no queda por debajo de los golpes" % [fam, ev])
		_limpiar()
		Son.voz(h, "ataque")
		if _n(fam + "_esfuerzo") != 1:
			_fallo("18: %s al lanzarse: esfuerzo %d (esperaba 1)" % [nombre, _n(fam + "_esfuerzo")])
		_limpiar()
		h["hp"] = 80
		Son.recibe(h)
		await _juego(1.0)
		if _n(fam + "_herido") != 1 or _n(fam + "_jadeo") != 0:
			_fallo("18: %s con 80 %% de vida: herido %d, jadeo %d (esperaba 1 y 0)" % [nombre, _n(fam + "_herido"), _n(fam + "_jadeo")])
		_limpiar()
		h["hp"] = 20
		Son.recibe(h)
		await _juego(1.0)
		Son._ultimo.clear()
		Son.recibe(h)
		await _juego(1.0)
		if _n(fam + "_jadeo") != 1:
			_fallo("18: %s con poca vida y dos golpes: jadeo %d (esperaba 1)" % [nombre, _n(fam + "_jadeo")])
		_limpiar()
		Son.voz(h, "alivio")
		Son._ultimo.clear()
		Son.recibe(h)
		await _juego(1.0)
		if _n(fam + "_alivio") != 1 or _n(fam + "_jadeo") != 1:
			_fallo("18: %s: alivio %d y, otra vez con poca vida, jadeo %d (esperaba 1 y 1)" % [nombre, _n(fam + "_alivio"), _n(fam + "_jadeo")])
		_limpiar()
		h["hp"] = 0
		Son.recibe(h)
		if _n(fam + "_herido") != 1:
			_fallo("18: %s cae y no se queja (herido %d)" % [nombre, _n(fam + "_herido")])
	# una voz de héroe a la vez; la victoria, de uno que siga en pie
	_limpiar()
	Son.voz({"hero": true, "nombre": "Kael", "hp": 9}, "ataque")
	Son.voz({"hero": true, "nombre": "Lya", "hp": 9}, "ataque")
	if Son.grupo_sonando("voz_heroe") != 1:
		_fallo("18: suenan %d voces de héroes a la vez (una como mucho)" % Son.grupo_sonando("voz_heroe"))
	_limpiar()
	var v: String = Son.victoria_heroes([{"hero": true, "nombre": "Kael", "hp": 0}, {"hero": true, "nombre": "Garon", "hp": 50}])
	await _juego(1.2)
	if v != "garon_victoria" or _n("garon_victoria") != 1:
		_fallo("18: la victoria no la celebra quien sigue en pie (%s, %d)" % [v, _n("garon_victoria")])
	if Son.victoria_heroes([{"hero": true, "nombre": "Kael", "hp": 0}]) != "":
		_fallo("18: celebra la victoria un héroe caído")
	# combate de verdad (grupo 7, el limo): el golpe del limo hace quejarse a Kael; una magia no pide voces
	var c = await _nuevo_combate(7)
	var hk: Dictionary = c.heroes[0]
	var e: Dictionary = c.enemigos[0]
	_sin_vida(hk)
	_sin_vida(e)
	_limpiar()
	await c._animar_golpe(e, hk, 1, "")
	await _juego(0.4)
	var fk: String = Son.familia(hk)
	if fk == "" or _n(fk + "_herido") != 1:
		_fallo("18: el limo golpea a %s y no se queja (%s)" % [hk.get("nombre", "?"), str(Son.contador)])
	_limpiar()
	await c._animar_golpe(hk, e, 1, "")
	await _juego(0.4)
	var esfuerzo := _n(fk + "_esfuerzo")
	_limpiar()
	await c._animar_golpe(hk, e, 1, "Agua")
	await _juego(0.4)
	if _suma(fk + "_") != 0:
		_fallo("18: la magia de %s pide su voz (%s): el catálogo mágico no cambia" % [hk.get("nombre", "?"), str(Son.contador)])
	c.queue_free()
	await _esperar(3)
	_limpiar()
	hechos.append("voces de los héroes (Kael, Lya y Garon: esfuerzo, herido, jadeo, alivio y victoria; una a la vez; en combate, el golpe del limo hace quejarse a %s y su ataque físico da %d esfuerzo)" % [hk.get("nombre", "?"), esfuerzo])

# 19. Fuentes 3D de vez en cuando (las cuerdas que crujen y el viento en ellas): una escena 3D con su cámara.
func _cuerdas() -> void:
	await _escena_3d()
	_limpiar()
	var a := Vector3(-3, 0, -10)
	var b := Vector3(-3, 0, 10)
	var f = Son.fuente_linea(current_scene, "puente_cruje", a, b)
	var g = Son.fuente_linea(current_scene, "viento_cuerdas", a, b)
	var lejos = Son.fuente_linea(current_scene, "puente_cruje", Vector3(80, 0, 0), Vector3(90, 0, 0), -3.0)
	if not f is Node3D or f is AudioStreamPlayer3D or g == null or lejos == null:
		_fallo("19: fuente_linea con «cada» no crea una fuente de vez en cuando (%s)" % str(f))
		return
	var puntos_bien := true
	var vistos := 0
	for i in int(40.0 * 30):
		await process_frame
		for x in Son._voces3d:
			if is_instance_valid(x) and x.playing and x.get_meta("efecto", "") in ["puente_cruje", "viento_cuerdas"]:
				var q: Vector3 = x.global_position
				if absf(q.x + 3.0) > 0.01 or absf(q.z) > 10.01 or String(x.bus) != "Ambiente":
					puntos_bien = false
				x.stop()                                         # sin ventana nada acaba solo
				vistos += 1
	if f.veces < 3 or g.veces < 1:
		_fallo("19: en 40 s las cuerdas suenan %d veces y el viento %d (esperaba 3 o más y 1 o más)" % [f.veces, g.veces])
	if lejos.veces != 0:
		_fallo("19: unas cuerdas a 80 m suenan %d veces (más allá de su «max»)" % lejos.veces)
	if not puntos_bien:
		_fallo("19: las cuerdas no suenan en el punto de su línea más cercano, por Ambiente")
	var cruje: int = f.veces
	var silba: int = g.veces
	await _escena_vacia()
	hechos.append("cuerdas (en 40 s: cuerdas %d, viento %d; lejos, 0)" % [cruje, silba])

# ================================================================= tanda 6

# 20. Oakhaven vivo: una ciudad de mentira (casillas de 64 px) con quien anda y su cámara.
func _ciudad_viva() -> void:
	await _escena_vacia()
	_limpiar()
	var M = root.get_node("Musica")
	M.pedir("ciudad")
	var ciudad := Node2D.new()
	root.add_child(ciudad)
	var quien := Node2D.new()
	ciudad.add_child(quien)
	var cam := Camera2D.new()
	quien.add_child(cam)
	cam.make_current()
	var t := 64.0
	var plaza := Vector2(40.5, 26) * t
	var p = Son.fuente_2d(ciudad, "plaza_murmullo", plaza, quien)
	var m = Son.fuente_2d(ciudad, "mercado_murmullo", Vector2(54, 29.5) * t, quien)
	var f = Son.fuente_2d(ciudad, "fuente_plaza", plaza + Vector2(0, 1) * t, quien)
	if p == null or m == null or f == null:
		_fallo("20: no se crean las fuentes de la plaza, el mercado o la fuente")
		ciudad.queue_free()
		return
	quien.position = plaza + Vector2(0, 1.5) * t
	await _juego(1.5)
	var cerca_p: float = p.volume_db
	var cerca_f: float = f.volume_db
	quien.position = plaza + Vector2(0, 30) * t                # lejos de todo
	await _juego(2.0)
	if cerca_p <= -8.0 or cerca_f <= -14.0:
		_fallo("20: junto a la fuente de la plaza no suenan lo bastante (plaza %.1f dB, fuente %.1f dB)" % [cerca_p, cerca_f])
	if p.playing or f.playing or m.playing:
		_fallo("20: lejos de la plaza y del mercado siguen sonando")
	for x in [p, m, f]:
		if String(x.bus) != "Ambiente":
			_fallo("20: «%s» no va por Ambiente" % x.get_meta("efecto", "?"))
	# la hora: de noche, grillo y mochuelo (ningún pájaro de día) y la campana; sin hora, lo de siempre
	Son.fijar_momento(ciudad, "noche")
	Son._momento_escena = current_scene                      # (la ciudad de mentira cuelga de root: vale la escena actual)
	_limpiar()
	await _juego(0.2)
	Son._campana_t = 0.05
	for i in 8:
		Son._det_t = 0.0
		Son._ultimo.clear()
		await _juego(0.3)
	if Son._det_ctx != "ciudad_noche":
		_fallo("20: con la hora fijada a «noche», los detalles no son los de «ciudad_noche» (%s)" % Son._det_ctx)
	if _n("pajaro") + _n("pajaro_ciudad") > 0 or _n("grillo") + _n("mochuelo") == 0:
		_fallo("20: de noche suenan pájaros de día o no suena la noche (%s)" % str(Son.contador))
	if _n("campana") != 1:
		_fallo("20: la campana de la hora suena %d veces (esperaba 1)" % _n("campana"))
	await _escena_vacia()
	if Son.momento_actual() != "":
		_fallo("20: la hora se queda al cambiar de escena")
	# en 3D, las mismas fuentes como emisores en bucle
	await _escena_3d()
	var e = Son.fuente_3d(current_scene, "fuente_plaza", Vector3(0, 0, -3))
	if not e is AudioStreamPlayer3D or not e.playing or String(e.bus) != "Ambiente":
		_fallo("20: la fuente de la plaza no vale como emisor 3D (T-103)")
	ciudad.queue_free()
	M.pedir("silencio")
	await _escena_vacia()
	_limpiar()
	hechos.append("ciudad viva (plaza %.1f dB y fuente %.1f dB al lado, callados lejos; de noche, grillo y mochuelo; la campana de la hora; la fuente en 3D)" % [cerca_p, cerca_f])

# ================================================================= tanda 7

# 21. La mezcla: la música que se aparta solo en combate y el limitador del Master.
func _mezcla() -> void:
	await _escena_vacia()
	var M = root.get_node("Musica")
	var im := AudioServer.get_bus_index("Musica")
	var lim := false
	for k in AudioServer.get_bus_effect_count(0):
		var fx := AudioServer.get_bus_effect(0, k)
		if fx is AudioEffectHardLimiter and absf(fx.ceiling_db - float(Son.LIMITE["techo_db"])) < 0.01:
			lim = true
	if Son.LIMITADOR_MASTER and not lim:
		_fallo("21: no está el limitador al final del Master")
	M.pedir("combate")
	await _juego(0.3)
	var comp: AudioEffectCompressor = null
	for k in AudioServer.get_bus_effect_count(im):
		if AudioServer.get_bus_effect(im, k) is AudioEffectCompressor:
			comp = AudioServer.get_bus_effect(im, k)
	if Son.APARTAR_MUSICA_EN_COMBATE and (comp == null or String(comp.sidechain) != "Efectos" or comp.ratio > 3.0):
		_fallo("21: en combate la música no se aparta con un compresor suave que escuche a Efectos")
	M.pedir("pradera")
	await _juego(0.3)
	var queda := 0
	for k in AudioServer.get_bus_effect_count(im):
		if AudioServer.get_bus_effect(im, k) is AudioEffectCompressor:
			queda += 1
	if queda != 0 or Son.musica_apartada():
		_fallo("21: fuera del combate la música sigue apartándose (%d compresores)" % queda)
	M.pedir("silencio")
	await _juego(0.2)
	hechos.append("mezcla (en combate la música se aparta; fuera, no; limitador del Master a %.1f dB)" % float(Son.LIMITE["techo_db"]))