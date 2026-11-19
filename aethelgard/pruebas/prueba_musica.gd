extends SceneTree
# Prueba del gestor de música y ambiente (musica.gd; T-030, D-067). Sin ventana, con datos aislados y «-- sin_prologo».
# Es MUDA: comprueba qué pista se asigna, que empieza (reproduciendo y con el volumen subiendo), que no se duplica ni se
# corta, y que respeta los buses. La escucha real se registra aparte.
#   1. Cada escena y lugar tiene su contexto; cada pista existe, es un bucle y va comprimida (QOA).
#   2. Pedir un contexto: la pista empieza y sube; al cambiar, la vieja se funde y se para.
#   3. Volver a pedir el mismo contexto no la reinicia.
#   4. Pausar la app pausa las pistas; volver las reanuda.
#   5. Nunca hay más de dos reproductores por capa ni suena nada por Master; con «Sin sonido» en Ambiente, el bus calla.
#   6. Escenas de verdad: mapa → Oakhaven → combate → mapa. En el combate se calla la exploración (su música es la del
#      combate, por el bus Musica) y al volver sigue desde donde iba, sin empezar otra vez.

var fallos: Array = []
var hechos: Array = []
var Mus
var Son
var R


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _amb() -> Dictionary:
	return Mus.capas["ambiente"]


func _probar() -> void:
	Mus = root.get_node("Musica")
	Son = root.get_node("Sonido")
	R = root.get_node("Recursos")
	await _esperar(3)
	_contextos()
	await _pedir_y_fundir()
	await _pausa()
	_reproductores()
	await _escenas()
	print("OK música: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Escenas, lugares y pistas.
func _contextos() -> void:
	var casos := {"res://carga.tscn": "carga", "res://combate.tscn": "combate", "res://mapa.tscn": "mapa",
		"res://isla.tscn": "arboleda", "res://garganta.tscn": "mazmorra", "res://zonas3d/garganta_3d.tscn": "mazmorra", "res://zonas3d/pastos_verdes_3d.tscn": "pradera",
		"res://ciudad_oakhaven.tscn": "ciudad",          # Oakhaven hecha a mano (T-089, hereda de zona.gd)
		"res://zonas3d/oakhaven_3d.tscn": "ciudad",      # Oakhaven 3D (T-103)
		# V12 (19/11, C-10): la ciudad completa, el barrio y la muestra de la calle (las tres, Oakhaven en el banco)
		# suenan como Oakhaven 3D, no en «silencio»
		"res://zonas3d/ciudad/ciudad.tscn": "ciudad", "res://zonas3d/barrio/barrio.tscn": "ciudad",
		"res://zonas3d/muestra_calle/muestra_calle.tscn": "ciudad",
		# V12 (19/11, AM-9): el puerto de Sunken City 3D (olas y gaviotas) y la Arboleda (viento y campanillas)
		"res://zonas3d/sunken_3d.tscn": "puerto", "res://zonas3d/arboleda_tramo/arboleda_tramo.tscn": "arboleda",
		"res://escena_que_no_existe.tscn": "silencio"}
	for ruta in casos:
		var n := Node.new()
		n.scene_file_path = ruta
		if Mus.contexto_de(n) != casos[ruta]:
			_fallo("1: %s da «%s» (esperaba «%s»)" % [ruta, Mus.contexto_de(n), casos[ruta]])
		n.free()
	var lugares := [[{"tipo": "ciudad", "zona": "llanura"}, "ciudad"], [{"tipo": "lugar", "zona": "bosque"}, "bosque"],
		[{"tipo": "lugar", "zona": "desierto"}, "desierto"], [{"tipo": "lugar", "zona": "llanura"}, "pradera"],
		[{"tipo": "lugar", "zona": "nieve"}, "viento"],
		[{"indice": 5, "nombre": "Sunken City", "tipo": "ciudad", "zona": "llanura"}, "puerto"]]   # (19/11, AM-9: la 2D)
	var z := Node.new()
	z.scene_file_path = "res://zona.tscn"
	for l in lugares:
		Engine.set_meta("lugar", l[0])
		if Mus.contexto_de(z) != l[1]:
			_fallo("1: una zona %s da «%s» (esperaba «%s»)" % [l[0], Mus.contexto_de(z), l[1]])
	# (revisión 19/11) la Sunken 2D como puerto es una propuesta [P] con interruptor: apagado, vuelve a «ciudad» como
	# antes del 19/11 (y la Sunken 3D sigue en «puerto»)
	var sunken := {"indice": 5, "nombre": "Sunken City", "tipo": "ciudad", "zona": "llanura"}
	var M: Script = Mus.get_script()
	if not M.get("puerto_sunken_2d") is bool:
		_fallo("1: musica.gd no tiene el interruptor «puerto_sunken_2d» de la Sunken City 2D")
	else:
		var antes_i: bool = M.get("puerto_sunken_2d")
		M.set("puerto_sunken_2d", false)
		Engine.set_meta("lugar", sunken)
		if Mus.contexto_de(z) != "ciudad":
			_fallo("1: con «puerto_sunken_2d» apagado, la Sunken City 2D da «%s» (esperaba «ciudad»)" % Mus.contexto_de(z))
		var n3 := Node.new()
		n3.scene_file_path = "res://zonas3d/sunken_3d.tscn"
		if Mus.contexto_de(n3) != "puerto":
			_fallo("1: con «puerto_sunken_2d» apagado, la Sunken 3D da «%s» (esperaba «puerto»)" % Mus.contexto_de(n3))
		n3.free()
		M.set("puerto_sunken_2d", antes_i)
		if Mus.contexto_de(z) != "puerto":
			_fallo("1: con «puerto_sunken_2d» encendido, la Sunken City 2D da «%s»" % Mus.contexto_de(z))
	z.free()
	Engine.remove_meta("lugar")
	for c in Mus.CONTEXTOS:
		for capa in ["musica", "ambiente"]:
			var ruta: String = Mus.CONTEXTOS[c].get(capa, "")
			if ruta == "":
				continue
			var s = load(ruta) if ResourceLoader.exists(ruta) else null
			if s == null and Mus.CONTEXTOS[c].get("privada", false):   # V12: título y Pastos (Suno; en Git desde el 11/11)
				print("AVISO: «%s» pide %s, que es privada y no está en esta copia: silencio" % [c, ruta])
				continue
			if s is AudioStreamOggVorbis:                 # V12: los vientos del desierto (OGG, bucle en su .import)
				if not s.loop and not Mus.CONTEXTOS[c].get("bucle", false):   # la del título se pone en bucle al sonar
					_fallo("1: %s (OGG) no es un bucle" % ruta)
				elif "suno" in ruta.to_lower():
					_fallo("1: %s parece una canción de Suno" % ruta)
			elif not s is AudioStreamWAV:
				_fallo("1: «%s» pide %s, que no existe" % [c, ruta])
			elif s.loop_mode != AudioStreamWAV.LOOP_FORWARD or s.format != AudioStreamWAV.FORMAT_QOA:
				_fallo("1: %s no es un bucle comprimido (bucle %d, formato %d)" % [ruta, s.loop_mode, s.format])
			elif "suno" in ruta.to_lower():
				_fallo("1: %s parece una canción de Suno" % ruta)
	_regiones()
	hechos.append("contextos y pistas")


# 1b. V12 (19/11, AM-9): Sunken con olas y gaviotas; la Arboleda con campanillas (y sin ellas dentro de la Hospedería).
func _regiones() -> void:
	# (revisión 19/11: sin indexar a ciegas; si falta un contexto, un fallo con su nombre y no un error de script que
	# corte la prueba a medias)
	for ctx in ["puerto", "arboleda", "arboleda_interior"]:
		if not Mus.CONTEXTOS.has(ctx):
			_fallo("1b: no existe el contexto «%s» en musica.gd" % ctx)
	var puerto: String = Mus.CONTEXTOS.get("puerto", {}).get("ambiente", "")
	if puerto.ends_with("viento.wav") or not ResourceLoader.exists(puerto) or not load(puerto) is AudioStreamOggVorbis \
			or not load(puerto).loop:
		_fallo("1b: el puerto no tiene su bucle de olas (pide %s)" % puerto)
	var arb: Dictionary = Mus.CONTEXTOS.get("arboleda", {})
	var dentro: Dictionary = Mus.CONTEXTOS.get("arboleda_interior", {})
	var amb_a: String = arb.get("ambiente", "")
	if amb_a == "" or dentro.get("ambiente", "") != amb_a \
			or float(dentro.get("db", 0.0)) > float(arb.get("db", 0.0)) - 6.0:
		_fallo("1b: dentro de la Hospedería el viento no es la misma pista al menos 6 dB más baja")
	var esperado := {"puerto": "gaviota", "arboleda": "campanillas"}
	for ctx in esperado:
		var lista: Array = Son.DETALLES.get(ctx, {}).get("efectos", [])
		if not esperado[ctx] in lista:
			_fallo("1b: los detalles de «%s» no tienen «%s» (%s)" % [ctx, esperado[ctx], str(lista)])
		for e in lista:
			var d: Dictionary = Son.EFECTOS.get(e, {})
			if d.is_empty() or String(d.get("bus", "")) != "Ambiente":
				_fallo("1b: el detalle «%s» de «%s» no está en el catálogo o no va por Ambiente" % [e, ctx])
				continue
			for i in int(d.get("n", 1)):
				var r: String = Son.ruta_archivo(d, i if d.has("n") else -1)
				if not ResourceLoader.exists(r) or not load(r) is AudioStreamWAV:
					_fallo("1b: falta %s («%s»)" % [r, e])
	for ctx in ["arboleda_interior", "viento", "mapa"]:   # dentro y en las montañas, sin campanillas ni gaviotas
		for e in Son.DETALLES.get(ctx, {}).get("efectos", []):
			if e in ["campanillas", "gaviota"]:
				_fallo("1b: «%s» suena en «%s»" % [e, ctx])


# 2 y 3. Pedir, fundir y no reiniciar.
func _pedir_y_fundir() -> void:
	var antes: int = Mus.arranques
	Mus.pedir("pradera")
	await _esperar(2)
	var p: AudioStreamPlayer = _amb()["activo"]
	if not p.playing or p.stream == null or not p.stream.resource_path.ends_with("pradera.wav") or p.bus != &"Ambiente":
		_fallo("2: «pradera» no empieza con su pista por el bus Ambiente")
	if Mus.arranques != antes + 1:
		_fallo("2: empezar «pradera» hizo %d arranques" % (Mus.arranques - antes))
	var v0 := p.volume_db
	await _esperar(30)
	if p.volume_db <= v0:
		_fallo("2: el volumen no sube al empezar (%.1f → %.1f dB)" % [v0, p.volume_db])
	await _esperar(60)
	if absf(p.volume_db - (-6.0)) > 0.5:
		_fallo("2: tras el fundido, la pradera está a %.1f dB (esperaba -6)" % p.volume_db)
	Mus.pedir("mapa")
	await _esperar(2)
	var q: AudioStreamPlayer = _amb()["activo"]
	if q == p or not q.playing or not q.stream.resource_path.ends_with("viento.wav"):
		_fallo("2: «mapa» no funde a su pista en el otro reproductor")
	await _esperar(60)
	if p.playing:
		_fallo("2: la pista vieja sigue sonando tras su fundido")
	var arr: int = Mus.arranques
	Mus.pedir("mapa")
	await _esperar(5)
	if Mus.arranques != arr or _amb()["activo"] != q or not q.playing:
		_fallo("3: volver a pedir el mismo contexto reinicia la pista")
	await _detalles_region()
	hechos.append("pedir, fundir y no reiniciar")


# 3b. V12 (19/11, AM-9): en el puerto suenan gaviotas; en la Arboleda, campanillas; al entrar en la Hospedería
# («arboleda_interior») el viento sigue sin reiniciarse, baja y no suena ningún detalle.
func _detalles_region() -> void:
	for par in [["puerto", "gaviota"], ["arboleda", "campanillas"]]:
		Mus.pedir(par[0])
		await _esperar(3)
		var p: AudioStreamPlayer = _amb()["activo"]
		if not Mus.CONTEXTOS.has(par[0]):              # (revisión 19/11: un fallo con su nombre, no un error de script)
			_fallo("3b: no existe el contexto «%s» (se pidió y suena «%s»)" % [par[0], Mus.contexto])
		elif not p.playing or p.stream == null or p.stream.resource_path != Mus.CONTEXTOS[par[0]].get("ambiente", ""):
			_fallo("3b: «%s» no suena con su pista" % par[0])
		var antes := int(Son.contador.get(par[1], 0))
		var vistos := {}
		for k in 40:                               # forzar el siguiente detalle (sin esperar 10-25 s)
			Son._det_t = 0.0
			Son._ultimo.clear()
			await _esperar(1)
			if Son.registro.size() > 0:
				vistos[Son.registro[Son.registro.size() - 1][1]] = true
		if int(Son.contador.get(par[1], 0)) <= antes:
			_fallo("3b: en «%s» no suena «%s» (sonaron %s)" % [par[0], par[1], str(vistos.keys())])
		Son.cortar()
	var p: AudioStreamPlayer = _amb()["activo"]
	var arr: int = Mus.arranques
	await _esperar(70)
	var v0 := p.volume_db
	if not p.playing:
		_fallo("3b: antes de entrar en la Hospedería no suena el viento de la Arboleda (contexto «%s»)" % Mus.contexto)
	if not Mus.CONTEXTOS.has("arboleda_interior"):
		_fallo("3b: no existe el contexto de la Hospedería («arboleda_interior»)")
	Mus.pedir("arboleda_interior")
	await _esperar(80)
	if Mus.contexto != "arboleda_interior":
		_fallo("3b: al entrar en la Hospedería el contexto es «%s»" % Mus.contexto)
	if Mus.arranques != arr or _amb()["activo"] != p or not p.playing:
		_fallo("3b: al entrar en la Hospedería el viento se reinicia o se calla")
	if p.volume_db > v0 - 6.0:
		_fallo("3b: dentro de la Hospedería el viento no baja (%.1f → %.1f dB)" % [v0, p.volume_db])
	var n := 0
	for k in 40:
		Son._det_t = 0.0
		Son._ultimo.clear()
		var c0 := int(Son.contador.get("campanillas", 0)) + int(Son.contador.get("rafaga_hierba", 0))
		await _esperar(1)
		n += int(Son.contador.get("campanillas", 0)) + int(Son.contador.get("rafaga_hierba", 0)) - c0
	if n > 0:
		_fallo("3b: dentro de la Hospedería suenan %d detalles" % n)
	Mus.pedir("arboleda")
	hechos.append("regiones (gaviotas, campanillas, Hospedería)")


# 4. Pausa de la app.
func _pausa() -> void:
	var sonando: Array = []
	for k in ["a", "b"]:
		if _amb()[k].playing:
			sonando.append(_amb()[k])
	Mus.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	for p in sonando:                              # (uno parado no tiene nada que pausar)
		if not p.stream_paused:
			_fallo("4: al pausar la app, el ambiente que sonaba no se pausa")
	Mus.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _esperar(2)
	if _amb()["activo"].stream_paused or not _amb()["activo"].playing:
		_fallo("4: al volver a la app, el ambiente no sigue")
	hechos.append("pausa")


# 5. Reproductores y buses.
func _reproductores() -> void:
	var n := 0
	for h in Mus.get_children():
		if h is AudioStreamPlayer:
			n += 1
			if not String(h.bus) in ["Musica", "Ambiente"]:
				_fallo("5: un reproductor del gestor suena por %s" % h.bus)
	if n != 4:
		_fallo("5: el gestor tiene %d reproductores (esperaba 4: dos por capa)" % n)
	Son.fijar("Ambiente", 0)
	if not AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambiente")):
		_fallo("5: con «Sin sonido» en Ambiente, el bus no calla")
	Son.fijar("Ambiente", 100)
	hechos.append("reproductores y buses")


# 6. Escenas de verdad.
func _escenas() -> void:
	change_scene_to_file("res://mapa.tscn")
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == "res://mapa.tscn" and Mus.contexto == "mapa", 30.0):
		_fallo("6: en el mapa, el contexto es «%s»" % Mus.contexto)
		return
	await _esperar(40)
	var viento: AudioStreamPlayer = _amb()["activo"]
	viento.seek(12.0)                              # como si llevara un rato sonando
	await _esperar(2)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad", "zona": "llanura", "texto": "x"})
	R.cambiar_escena("res://zona.tscn")
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == "res://zona.tscn" and Mus.contexto == "ciudad", 60.0):
		_fallo("6: en Oakhaven, el contexto es «%s»" % Mus.contexto)
	await _esperar(40)
	var guardada: float = Mus._posiciones.get("res://audio/ambiente/viento.wav", -1.0)
	if guardada < 11.0:
		_fallo("6: al salir del mapa no se recuerda por dónde iba el viento (%.1f s)" % guardada)
	# combate (su música va por el bus Musica; la exploración se calla)
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael"])
	Engine.set_meta("grupo_combate", 7)
	Engine.set_meta("tipo_combate", "normal")
	change_scene_to_file("res://combate.tscn")
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == "res://combate.tscn" and Mus.contexto == "combate", 30.0):
		_fallo("6: en el combate, el contexto es «%s»" % Mus.contexto)
	await _esperar(60)
	if _amb()["a"].playing or _amb()["b"].playing:
		_fallo("6: durante el combate sigue sonando el ambiente")
	var musica_combate = current_scene.get("musica")
	if musica_combate == null or not musica_combate.playing or musica_combate.bus != &"Musica":
		_fallo("6: la música del combate no suena por el bus Musica")
	var arr: int = Mus.arranques
	change_scene_to_file("res://mapa.tscn")
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == "res://mapa.tscn" and Mus.contexto == "mapa", 30.0):
		_fallo("6: al volver al mapa, el contexto es «%s»" % Mus.contexto)
	await _esperar(5)
	var vuelta: AudioStreamPlayer = _amb()["activo"]
	if Mus.arranques != arr + 1 or not vuelta.playing or not vuelta.stream.resource_path.ends_with("viento.wav"):
		_fallo("6: al volver al mapa, el viento no vuelve a sonar")
	elif vuelta.get_playback_position() < 11.0:
		_fallo("6: al volver al mapa, el viento empieza de cero (%.1f s) en vez de seguir" % vuelta.get_playback_position())
	var sonando := 0
	for h in Mus.get_children():
		if h is AudioStreamPlayer and h.playing:
			sonando += 1
	if sonando > 2:
		_fallo("6: suenan %d reproductores a la vez" % sonando)
	Engine.remove_meta("lugar")
	hechos.append("mapa → Oakhaven → combate → mapa")
