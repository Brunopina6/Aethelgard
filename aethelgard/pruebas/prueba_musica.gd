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
		"res://isla.tscn": "viento", "res://garganta.tscn": "mazmorra", "res://zonas3d/garganta_3d.tscn": "mazmorra", "res://zonas3d/pastos_verdes_3d.tscn": "pradera",
		"res://ciudad_oakhaven.tscn": "ciudad",          # Oakhaven hecha a mano (T-089, hereda de zona.gd)
		"res://zonas3d/oakhaven_3d.tscn": "ciudad",      # Oakhaven 3D (T-103)
		# V12 (19/11, C-10): la ciudad completa, el barrio y la muestra de la calle (las tres, Oakhaven en el banco)
		# suenan como Oakhaven 3D, no en «silencio»
		"res://zonas3d/ciudad/ciudad.tscn": "ciudad", "res://zonas3d/barrio/barrio.tscn": "ciudad",
		"res://zonas3d/muestra_calle/muestra_calle.tscn": "ciudad",
		"res://escena_que_no_existe.tscn": "silencio"}
	for ruta in casos:
		var n := Node.new()
		n.scene_file_path = ruta
		if Mus.contexto_de(n) != casos[ruta]:
			_fallo("1: %s da «%s» (esperaba «%s»)" % [ruta, Mus.contexto_de(n), casos[ruta]])
		n.free()
	var lugares := [[{"tipo": "ciudad", "zona": "llanura"}, "ciudad"], [{"tipo": "lugar", "zona": "bosque"}, "bosque"],
		[{"tipo": "lugar", "zona": "desierto"}, "desierto"], [{"tipo": "lugar", "zona": "llanura"}, "pradera"],
		[{"tipo": "lugar", "zona": "nieve"}, "viento"]]
	var z := Node.new()
	z.scene_file_path = "res://zona.tscn"
	for l in lugares:
		Engine.set_meta("lugar", l[0])
		if Mus.contexto_de(z) != l[1]:
			_fallo("1: una zona %s da «%s» (esperaba «%s»)" % [l[0], Mus.contexto_de(z), l[1]])
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
	hechos.append("contextos y pistas")


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
	hechos.append("pedir, fundir y no reiniciar")


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
