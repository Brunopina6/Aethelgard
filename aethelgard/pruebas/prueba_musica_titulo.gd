extends SceneTree
# La canción del título (V12, 11/11: «REBELUM — When the World Forgets»; musica.gd contexto «titulo»; la pantalla de
# inicio nueva, portada/inicio_alternativo.tscn). Sin ventana, con datos aislados:
#   1. Al entrar en la pantalla de inicio suena la canción, desde el principio, una sola reproducción, por el bus Musica
#      y en bucle.
#   2. Al pasar de la carga al menú («TOCA PARA EMPEZAR») y al abrir Opciones, sigue sin reiniciarse ni duplicarse.
#   3. Al irse al juego (el mapa), se funde y se calla: ninguna reproducción del título sigue sonando.
#   4. Al volver a la pantalla de inicio, empieza otra vez desde el principio (una sola reproducción).
#   5. Respeta el volumen: con el bus Musica en silencio, no se oye (el bus manda).
# La canción es privada (Suno, fuera de Git): si no está en esta copia, se avisa y la prueba no falla.
# Las esperas van en milisegundos reales: el audio avanza con el reloj, no con --fixed-fps.

const ESCENA := "res://portada/inicio_alternativo.tscn"
var Mu
var fallos := 0
var fase := "entrar"
var t0 := 0
var pos_a := 0.0
var marca := 0


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _initialize() -> void:
	Mu = root.get_node_or_null("Musica")
	var ruta: String = load("res://musica.gd").CONTEXTOS["titulo"]["musica"]
	if not ResourceLoader.exists(ruta):
		print("AVISO: la canción del título (%s) es privada y no está en esta copia: nada que probar" % ruta)
		print("FALLOS: 0")
		quit(0)
		return
	Engine.set_meta("partida_lista", true)
	change_scene_to_file(ESCENA)
	t0 = Time.get_ticks_msec()


func _ms() -> int:
	return Time.get_ticks_msec() - t0


func _sonando_titulo() -> Array:
	var r: Array = []
	var ruta: String = Mu.CONTEXTOS["titulo"]["musica"]
	for n in ["a", "b"]:
		var p: AudioStreamPlayer = Mu.capas["musica"][n]
		if p.playing and p.stream != null and p.stream.resource_path == ruta:
			r.append(p)
	return r


func _process(_d: float) -> bool:
	if _ms() > 90000:
		_mal("se pasa de tiempo en «%s»" % fase)
		return _fin()
	match fase:
		"entrar":
			if _ms() > 3000:
				var s := _sonando_titulo()
				if Mu.contexto != "titulo" or s.size() != 1:
					_mal("1: al entrar no suena la canción una sola vez (contexto %s, %d reproducciones)" % [Mu.contexto, s.size()])
					return _fin()
				var p: AudioStreamPlayer = s[0]
				if String(p.bus) != "Musica" or not p.stream.get("loop"):
					_mal("1: la canción no va por el bus Musica o no está en bucle (%s, bucle %s)" % [p.bus, p.stream.get("loop")])
				pos_a = Mu.posicion_musica()
				if pos_a < 0.0 or pos_a > 6.0:
					_mal("1: no empieza desde el principio (va por %.1f s)" % pos_a)
				fase = "menu"
				marca = _ms()
		"menu":
			var e = current_scene
			if e != null and e.has_method("_abrir_menu") and str(e.get("estado")) != "menu":
				e.call("_abrir_menu")
			if _ms() - marca > 2500:
				var s := _sonando_titulo()
				var pos: float = Mu.posicion_musica()
				if s.size() != 1 or pos <= pos_a:
					_mal("2: al abrir el menú la canción se reinicia o se duplica (%d, %.1f → %.1f s)" % [s.size(), pos_a, pos])
				pos_a = pos
				if e != null and e.has_method("_abrir_opciones"):
					e.call("_abrir_opciones")
				fase = "opciones"
				marca = _ms()
		"opciones":
			if _ms() - marca > 2000:
				var s := _sonando_titulo()
				var pos: float = Mu.posicion_musica()
				if s.size() != 1 or pos <= pos_a:
					_mal("2: al abrir Opciones la canción se reinicia o se duplica (%d, %.1f → %.1f s)" % [s.size(), pos_a, pos])
				change_scene_to_file("res://mapa.tscn")
				fase = "juego"
				marca = _ms()
		"juego":
			if _ms() - marca > 4000:
				if not _sonando_titulo().is_empty():
					_mal("3: al ir al juego la canción del título sigue sonando")
				change_scene_to_file(ESCENA)
				fase = "volver"
				marca = _ms()
		"volver":
			if _ms() - marca > 3000:
				var s := _sonando_titulo()
				var pos: float = Mu.posicion_musica()
				if s.size() != 1 or pos < 0.0 or pos > 6.0:
					_mal("4: al volver al título no empieza desde el principio una sola vez (%d, %.1f s)" % [s.size(), pos])
				var bus := AudioServer.get_bus_index("Musica")
				AudioServer.set_bus_mute(bus, true)
				if not AudioServer.is_bus_mute(bus):
					_mal("5: el bus Musica no se deja silenciar")
				AudioServer.set_bus_mute(bus, false)
				return _fin()
	return false


func _fin() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
