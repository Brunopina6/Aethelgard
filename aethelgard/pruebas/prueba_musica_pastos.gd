extends SceneTree
# La música de Pastos Verdes (V12, 11/11: «Pastoral Pulse», elegible en Ajustes; musica.gd «pradera_musica»). Sin
# ventana, con datos aislados y esperas en milisegundos reales (el audio va con el reloj):
#   1. Elegida, al entrar en Pastos Verdes 3D suena una sola vez por el bus Musica, en bucle desde 11,17 s, y el ambiente
#      de la pradera sigue sonando.
#   2. El bucle: cerca del final (2:44,28) vuelve a la sección central y no se para.
#   3. El combate la calla con un fundido y, al volver, sigue por donde iba (no desde el principio), una sola vez.
#   4. Al ir al mapa se calla.
#   5. Con «Solo ambiente» no suena (lo de siempre).
# Es «privada» (Suno Pro; en Git y en las APK desde el 11/11): si faltara en una copia, se avisa y no falla.

const PASTOS := "res://zonas3d/pastos_verdes_3d.tscn"
var Mu
var fallos := 0
var fase := "entrar"
var t0 := 0
var marca := 0
var pos_a := 0.0


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _initialize() -> void:
	Mu = root.get_node_or_null("Musica")
	var M = load("res://musica.gd")
	if not ResourceLoader.exists(M.CONTEXTOS["pradera_musica"]["musica"]):
		print("AVISO: la música de Pastos Verdes es privada y no está en esta copia: nada que probar")
		print("FALLOS: 0")
		quit(0)
		return
	for k in load("res://progreso.gd").CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("incienso", 100000)
	Engine.set_meta("calidad_proto", "bajo")
	M.elegir_musica_pastos(true)
	change_scene_to_file(PASTOS)
	t0 = Time.get_ticks_msec()
	marca = t0


func _ms() -> int:
	return Time.get_ticks_msec() - marca


func _sonando() -> Array:
	var r: Array = []
	var ruta: String = Mu.CONTEXTOS["pradera_musica"]["musica"]
	for n in ["a", "b"]:
		var p: AudioStreamPlayer = Mu.capas["musica"][n]
		if p.playing and p.stream != null and p.stream.resource_path == ruta:
			r.append(p)
	return r


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - t0 > 150000:
		_mal("se pasa de tiempo en «%s»" % fase)
		return _fin()
	match fase:
		"entrar":
			if current_scene != null and current_scene.scene_file_path == PASTOS and _ms() > 6000:
				var s := _sonando()
				if Mu.contexto != "pradera_musica" or s.size() != 1:
					_mal("1: al entrar no suena una sola vez (contexto %s, %d)" % [Mu.contexto, s.size()])
					return _fin()
				var p: AudioStreamPlayer = s[0]
				if String(p.bus) != "Musica" or not p.stream.get("loop") or absf(float(p.stream.get("loop_offset")) - 11.17) > 0.01:
					_mal("1: bus, bucle o punto de vuelta mal (%s, %s, %s)" % [p.bus, p.stream.get("loop"), p.stream.get("loop_offset")])
				var amb: AudioStreamPlayer = Mu.capas["ambiente"]["activo"]
				if not amb.playing:
					_mal("1: con la música, el ambiente de la pradera no suena")
				p.seek(163.0)                             # 2. cerca del final: debe volver a la sección central
				fase = "bucle"
				marca = Time.get_ticks_msec()
		"bucle":
			if _ms() > 2500:
				var s := _sonando()
				var pos: float = Mu.posicion_musica()
				if s.size() != 1 or pos < 11.0 or pos > 14.5:
					_mal("2: al final no vuelve a la sección central (%d, %.2f s)" % [s.size(), pos])
				pos_a = pos
				Mu.pedir("combate")                        # 3. el combate (su música la lleva combate.gd)
				fase = "combate"
				marca = Time.get_ticks_msec()
		"combate":
			if _ms() > 2500:
				if not _sonando().is_empty():
					_mal("3: en el combate la música de Pastos sigue sonando")
				Mu.pedir("pradera_musica")
				fase = "volver"
				marca = Time.get_ticks_msec()
		"volver":
			if _ms() > 1500:
				var s := _sonando()
				var pos: float = Mu.posicion_musica()
				if s.size() != 1 or pos < pos_a:
					_mal("3: al volver del combate no sigue por donde iba o se duplica (%d, %.2f → %.2f s)" % [s.size(), pos_a, pos])
				change_scene_to_file("res://mapa.tscn")
				fase = "mapa"
				marca = Time.get_ticks_msec()
		"mapa":
			if _ms() > 3500:
				if not _sonando().is_empty():
					_mal("4: en el mapa la música de Pastos sigue sonando")
				load("res://musica.gd").elegir_musica_pastos(false)
				change_scene_to_file(PASTOS)
				fase = "ambiente"
				marca = Time.get_ticks_msec()
		"ambiente":
			if current_scene != null and current_scene.scene_file_path == PASTOS and _ms() > 6000:
				if Mu.contexto != "pradera" or not _sonando().is_empty():
					_mal("5: con «Solo ambiente» suena la música (contexto %s)" % Mu.contexto)
				return _fin()
	return false


func _fin() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
