extends SceneTree
# Prueba del sonido (T-030, D-064; sonido.gd): buses, volúmenes guardados, pestaña «Ajustes» con teclado y bus de cada
# reproductor. Sin ventana; con datos aislados (ejecutar_pruebas.ps1): escribe y borra user://ajustes.cfg. Es una
# prueba MUDA: comprueba adónde va cada sonido y con qué volumen, no cómo suena (eso se escucha aparte).
#   1. Existen Musica, Efectos, Interfaz y Ambiente, hacia Master; sin ajustes guardados, a 0 dB y sin silenciar.
#   2. Leer los ajustes (lo que hace el juego al abrirse) no escribe user://ajustes.cfg.
#   3. 50 % son unos -6 dB, 0 % silencia y más de 100 se queda en 100; se guarda y se vuelve a leer igual; un valor que
#      no es un número deja ese bus al 100 %.
#   4. Pestaña «Ajustes» con teclado (eventos simulados): E llega a Ajustes, ↓ entra en la fila de Música, Intro en ◀
#      baja un 10 % (una sola vez) y el foco se queda en ◀; ▶ lo sube; ↓ pasa a Efectos; Esc cierra.
#      La primera pulsación no da un fotograma de más de 100 ms (medido sin el tope de 30 fps; hasta 3 primeras, 19/11).
#   5. Nada suena por Master: en el código, cada AudioStreamPlayer.new() elige su bus; en un combate de verdad, todos
#      los reproductores van a buses de sonido.gd; el sonido al escribir de Dialogic va a Interfaz.

const ARCHIVO := "user://ajustes.cfg"

var fallos: Array = []
var hechos: Array = []
var Son
var Ent


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _tecla(codigo: Key, pulsada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = pulsada
	Input.parse_input_event(e)


# Como _pulsar, pero devuelve lo que dura el peor fotograma (ms) mientras se procesa la tecla.
func _pulsar_midiendo(codigo: Key, esperar := 4) -> float:
	var peor := 0.0
	var ant := Time.get_ticks_usec()
	_tecla(codigo, true)
	for i in 2 + esperar:
		if i == 2:
			_tecla(codigo, false)
		await process_frame
		var ahora := Time.get_ticks_usec()
		peor = maxf(peor, (ahora - ant) / 1000.0)
		ant = ahora
	return peor


func _pulsar(codigo: Key, esperar := 4) -> void:
	_tecla(codigo, true)
	await _esperar(2)
	_tecla(codigo, false)
	await _esperar(esperar)


func _foco() -> Control:
	return root.get_viewport().gui_get_focus_owner()


func _clave_foco() -> String:
	return Ent.clave(_foco()) if _foco() != null else ""


func _db(bus: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func _mudo(bus: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))


func _borrar_ajustes() -> void:
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))


func _probar() -> void:
	Son = root.get_node("Sonido")
	Ent = root.get_node("Entrada")
	await _esperar(3)
	_buses()
	_sin_escribir()
	_volumenes()
	await _pestana_ajustes()
	await _nada_por_master()
	_borrar_ajustes()
	Son.cargar()
	print("OK audio: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Los buses de default_bus_layout.tres.
func _buses() -> void:
	var nombres: Array = []
	for i in AudioServer.bus_count:
		nombres.append(String(AudioServer.get_bus_name(i)))
	if nombres != ["Master", "Musica", "Efectos", "Interfaz", "Ambiente"]:
		_fallo("1: los buses son %s" % [nombres])
		return
	for b in Son.BUSES:
		var i := AudioServer.get_bus_index(b)
		if String(AudioServer.get_bus_send(i)) != "Master":
			_fallo("1: %s no va a Master (%s)" % [b, AudioServer.get_bus_send(i)])
	_borrar_ajustes()
	Son.cargar()
	for b in Son.BUSES:
		if absf(_db(b)) > 0.001 or _mudo(b) or Son.volumen(b) != 100:
			_fallo("1: sin ajustes guardados, %s no está al 100 %% (%.2f dB, mudo %s)" % [b, _db(b), _mudo(b)])
	hechos.append("buses")


# 2. Leer no escribe.
func _sin_escribir() -> void:
	_borrar_ajustes()
	Son.cargar()
	if FileAccess.file_exists(ARCHIVO):
		_fallo("2: leer los ajustes ha creado %s" % ARCHIVO)
	hechos.append("leer no escribe")


# 3. Volúmenes, recortes, guardado y lectura.
func _volumenes() -> void:
	Son.fijar("Musica", 50)
	if absf(_db("Musica") - linear_to_db(0.5)) > 0.01 or _mudo("Musica"):
		_fallo("3: al 50 %%, Musica está a %.2f dB (esperaba %.2f)" % [_db("Musica"), linear_to_db(0.5)])
	if not FileAccess.file_exists(ARCHIVO):
		_fallo("3: cambiar un volumen no lo guarda")
	Son.fijar("Efectos", 0)
	if not _mudo("Efectos"):
		_fallo("3: al 0 %, Efectos no se silencia")
	Son.fijar("Interfaz", 80)
	Son.fijar("Interfaz", 130)
	if Son.volumen("Interfaz") != 100:
		_fallo("3: 130 no se queda en 100 (%d)" % Son.volumen("Interfaz"))
	Son.fijar("Ambiente", -20)
	if Son.volumen("Ambiente") != 0:
		_fallo("3: -20 no se queda en 0 (%d)" % Son.volumen("Ambiente"))
	# como al abrir el juego otra vez: buses a 0 dB y se leen los ajustes
	for i in AudioServer.bus_count:
		AudioServer.set_bus_volume_db(i, 0.0)
		AudioServer.set_bus_mute(i, false)
	Son.cargar()
	if Son.volumen("Musica") != 50 or absf(_db("Musica") - linear_to_db(0.5)) > 0.01:
		_fallo("3: al volver a leer, Musica no está al 50 %% (%d, %.2f dB)" % [Son.volumen("Musica"), _db("Musica")])
	if Son.volumen("Efectos") != 0 or not _mudo("Efectos"):
		_fallo("3: al volver a leer, Efectos no sigue en silencio")
	if Son.volumen("Interfaz") != 100 or Son.volumen("Ambiente") != 0:
		_fallo("3: al volver a leer, Interfaz %d y Ambiente %d" % [Son.volumen("Interfaz"), Son.volumen("Ambiente")])
	# un archivo con un valor que no es un número
	var c := ConfigFile.new()
	c.set_value("volumen", "Musica", "mucho")
	c.set_value("volumen", "Efectos", 40)
	c.save(ARCHIVO)
	Son.cargar()
	if Son.volumen("Musica") != 100 or Son.volumen("Efectos") != 40:
		_fallo("3: con un valor raro, Musica %d (esperaba 100) y Efectos %d (esperaba 40)" % [Son.volumen("Musica"), Son.volumen("Efectos")])
	_borrar_ajustes()
	Son.cargar()
	hechos.append("volúmenes")


# 4. La pestaña «Ajustes» del menú del grupo, con el teclado.
func _pestana_ajustes() -> void:
	await _pulsar(KEY_SHIFT)                       # una tecla cualquiera: modo teclado
	var m = load("res://menus.gd").new()
	m.pestana = "Habilidades"
	var cerrado := [false]
	m.cerrado.connect(func(): cerrado[0] = true)
	root.add_child(m)
	await _esperar(2)
	await _pulsar(KEY_E)
	if m.pestana != "Ajustes" or _clave_foco() != "pestana:Ajustes":
		_fallo("4: E no lleva a Ajustes con el foco en su pestaña (%s, «%s»)" % [m.pestana, _clave_foco()])
	await _pulsar(KEY_DOWN)
	if not _clave_foco().begins_with("volumen:Musica:"):
		_fallo("4: ↓ desde la pestaña no entra en la fila de Música («%s»)" % _clave_foco())
	if _clave_foco() == "volumen:Musica:1":
		await _pulsar(KEY_LEFT)
	if _clave_foco() != "volumen:Musica:-1":
		_fallo("4: no llego a ◀ de Música («%s»)" % _clave_foco())
	for b in Son.VISIBLES:                         # lo que cuesta crear cada muestra (sin guardarla)
		var u := Time.get_ticks_usec()
		var w = Son._wav(Son._muestra(b), Son.HZ)
		print("  muestra de %s: %.1f ms, %.2f s de sonido" % [b, (Time.get_ticks_usec() - u) / 1000.0, w.get_length()])
	# rend3 (13/11): se mide el PEOR fotograma de la pulsación, no la suma de los 6 fotogramas de espera. Antes, con el
	# PC cargado, la suma pasaba de 100 ms sin que hubiera ningún parón (2026-11-09: 118 ms; con el PC libre, 51-97 ms).
	# PC-13 (19/11): fallaba suelta 3 de cada 10 veces (101-139 ms). Medido: (a) Recursos deja el juego a 30 fps
	# (Engine.max_fps), y el «peor fotograma» se llevaba hasta 33 ms de espera OCIOSA del fotograma anterior (más o
	# menos según lo que hiciera la prueba en él: crear las muestras, justo antes); por eso se mide sin tope, solo el
	# trabajo; (b) no hay pico propio de la primera pulsación: crear la muestra cuesta ≈4 ms y el resto es repintar la
	# pestaña entera (menus.gd _pintar_de_nuevo, ≈75-90 ms en cada pulsación, también la 2.ª y la 3.ª), así que queda
	# a ras del límite y un tropiezo suelto del PC lo pasa. El límite sigue en 100 ms y se sigue midiendo una primera
	# pulsación de verdad; si la pasa, se repite como primera (sin la muestra ni su reproductor, lo único que solo hace
	# la primera) hasta 2 veces más y vale la mejor: un coste de cada primera pulsación falla igual; un tropiezo, no.
	# AJUSTES_19_11: la causa de fondo, arreglada: ◀ ▶ ya no repintan la pestaña entera, solo su fila (menus.gd
	# _volumen_en_su_fila; prueba_ajustes_parcial comprueba que se ve igual que un repintado). Medido en el PC: la
	# primera pulsación ≈4-9 ms (crear la muestra) y las demás ≈2 ms. El límite sigue en 100 ms (no se relaja).
	var fps_antes := Engine.max_fps
	Engine.max_fps = 0
	await _esperar(2)
	var intentos: Array = []
	for intento in 3:
		if intento > 0:
			Son.fijar("Musica", 100)                   # como antes de la primera: Música al 100 % y sin su muestra
			Son._sonidos.erase("Musica")
			var rep = Son._muestras.get("Musica")
			if rep != null:
				rep.queue_free()
			Son._muestras.erase("Musica")
			await _esperar(2)
		intentos.append(snappedf(await _pulsar_midiendo(KEY_ENTER), 0.1))
		if intentos.back() <= 100.0:
			break
	if Son.volumen("Musica") != 90:                   # cada intento: una pulsación, un paso (100 → 90)
		_fallo("4: una pulsación de Intro en ◀ deja Música en %d (esperaba 90)" % Son.volumen("Musica"))
	var estable := await _pulsar_midiendo(KEY_ENTER)   # informativo: una pulsación cualquiera (Música 90 → 80)
	Son.fijar("Musica", 90)
	m._pintar_de_nuevo()
	await _esperar(2)
	Engine.max_fps = fps_antes
	var ms: float = intentos.min()
	print("  primera pulsación en ◀ de Música (crear su muestra y poner al día su fila), sin tope de fps: peor fotograma %s ms"
		% ", ".join(intentos.map(func(x): return "%.1f" % x)) + "; una pulsación cualquiera: %.1f ms" % estable)
	if ms > 100.0:
		_fallo("4: la primera pulsación en Música da un fotograma de %.0f ms en el PC (un parón visible en el móvil; %d intentos: %s)"
			% [ms, intentos.size(), intentos])
	# (revisión 19/11) la comprobación de «Música en 90» va arriba, tras los intentos; aquí sobraba (Son.fijar la deja
	# en 90 tras la pulsación informativa) y, si fallaba, se imprimía dos veces
	if absf(_db("Musica") - linear_to_db(0.9)) > 0.01:
		_fallo("4: Música al 90 %% está a %.2f dB" % _db("Musica"))
	if _clave_foco() != "volumen:Musica:-1" or not _foco().has_focus(true):
		_fallo("4: tras bajar, el foco no sigue (visible) en ◀ de Música («%s»)" % _clave_foco())
	if Ent.buscar(m, "volumen:Musica:-1") == null:
		_fallo("4: no está el botón ◀ de Música")
	await _pulsar(KEY_RIGHT)
	if _clave_foco() != "volumen:Musica:1":
		_fallo("4: → no pasa a ▶ de Música («%s»)" % _clave_foco())
	await _pulsar(KEY_ENTER)
	if Son.volumen("Musica") != 100:
		_fallo("4: ▶ no vuelve a subir Música a 100 (%d)" % Son.volumen("Musica"))
	await _pulsar(KEY_DOWN)
	if not _clave_foco().begins_with("volumen:Efectos:"):
		_fallo("4: ↓ no pasa a la fila de Efectos («%s»)" % _clave_foco())
	var c := ConfigFile.new()
	if c.load(ARCHIVO) != OK or int(c.get_value("volumen", "Musica", -1)) != 100:
		_fallo("4: el archivo de ajustes no guarda Música al 100")
	await _pulsar(KEY_ESCAPE)
	if not cerrado[0]:
		_fallo("4: Esc no cierra el menú")
	await _esperar(2)
	_borrar_ajustes()
	Son.cargar()
	hechos.append("pestaña Ajustes")


# 5. Ningún reproductor suena por Master.
func _nada_por_master() -> void:
	var re := RegEx.create_from_string("(\\w+)\\s*:?=\\s*AudioStreamPlayer(2D|3D)?\\.new\\(\\)")
	var sin_bus: Array = []
	var vistos := 0
	for ruta in _scripts("res://"):
		var lineas := FileAccess.get_file_as_string(ruta).split("\n")
		for i in lineas.size():
			var r := re.search(lineas[i])
			if r == null:
				continue
			vistos += 1
			var v := r.get_string(1)
			var ok := false
			for j in range(i + 1, mini(i + 12, lineas.size())):
				if lineas[j].strip_edges().begins_with(v + ".bus ="):
					ok = true
					break
			if not ok:
				sin_bus.append("%s:%d (%s)" % [ruta, i + 1, v])
	if vistos < 7:
		_fallo("5: solo encuentro %d reproductores creados en el código (¿ha cambiado la forma de crearlos?)" % vistos)
	if not sin_bus.is_empty():
		_fallo("5: reproductores sin bus: %s" % ", ".join(sin_bus))
	if ProjectSettings.get_setting("dialogic/audio/type_sound_bus", "Master") != "Interfaz":
		_fallo("5: el sonido al escribir de Dialogic no va a Interfaz")
	# un combate de verdad (Kael contra el grupo 7)
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael"])
	Engine.set_meta("grupo_combate", 7)
	Engine.set_meta("tipo_combate", "normal")
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(30)
	var reps := _reproductores(c)
	var malos: Array = []
	for p in reps:
		if not String(p.bus) in Son.BUSES:
			malos.append("%s → %s" % [p.get_path(), p.bus])
	if reps.size() < 2:
		_fallo("5: en el combate solo hay %d reproductores (esperaba la música y los del menú)" % reps.size())
	if not malos.is_empty():
		_fallo("5: en el combate suenan por otro bus: %s" % ", ".join(malos))
	if c.get("musica") == null or String(c.musica.bus) != "Musica":
		_fallo("5: la música del combate no va a Musica")
	c.queue_free()
	await _esperar(3)
	hechos.append("nada por Master (%d reproductores en el código, %d en el combate)" % [vistos, reps.size()])


func _reproductores(n: Node) -> Array:
	var r: Array = []
	if n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D:
		r.append(n)
	for h in n.get_children(true):
		r.append_array(_reproductores(h))
	return r


func _scripts(dir: String) -> Array:
	var r: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return r
	for f in d.get_files():
		if f.ends_with(".gd"):
			r.append(dir.path_join(f))
	for s in d.get_directories():
		if s in ["addons", "pruebas", ".godot"] or s.begins_with("."):
			continue
		r.append_array(_scripts(dir.path_join(s)))
	return r
