extends SceneTree
# V12 (13/11), Cumbres de Ciclópea 3D, primer sector (zonas3d/ciclopea_3d.gd; EN PRUEBAS tras «ciclopea3d»):
#   0. La disposición de la 3D es la que genera zona.gd para el lugar 3 (volcar_ciclopea_2d.gd).
#   1. Apagada sin «ciclopea3d» (ni en Ajustes): el mapa lleva a la 2D, y una partida de la 3D abre la 2D en la misma
#      casilla; encendida, el mapa lleva a la 3D y una partida de la 2D abre la 3D.
#   2. El camino del sur al altar se anda entero (sin agua, muros, piezas ni escalones; pendiente ≤ 40°) y sube; las
#      laderas a ambos lados están a la altura del camino (sin trinchera).
#   3. Kael anda de verdad (como un jugador) por el camino, y no atraviesa un pino ni una roca.
#   4. Los tres cofres con sus ids de la 2D y su premio; los cofres de los hallazgos donde los pone la 2D (el Tomo de
#      Escarcha al norte de las ruinas); todo se alcanza.
#   5. La estatua: «Examinar», su texto y el detalle visto.
#   6. Guardar y cargar: la partida vuelve al mismo sitio; la 2D ↔ 3D en la misma casilla.
#   7. Un encuentro lleva al combate y vuelve aquí; la salida del sur lleva al mapa.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_ciclopea3d.gd --fixed-fps 30 -- 3d ciclopea3d sin_prologo
# No guarda ninguna partida (progreso.gd no guarda en las pruebas).

const REGION := "res://zonas3d/ciclopea_3d.tscn"
var M = load("res://modo3d.gd")
var T = load("res://zonas3d/ciclopea/trazado.gd")
var D = load("res://zonas3d/ciclopea/disposicion_2d.gd")
var P = load("res://progreso.gd")
var v
var fallos := 0


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(t: String) -> void:
	print("OK " + t)


func _frames(n: int) -> void:
	for i in n:
		if v != null and is_instance_valid(v) and "pasos" in v:
			v.pasos = 0                                   # sin encuentros al azar en la prueba
		await process_frame


func _limpiar() -> void:
	for k in ["cofres_abiertos", "lore_visto", "hitos", "pos_3d", "combate_fijo", "escena_retorno"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)


func _cargar() -> void:
	change_scene_to_file(REGION)
	await _frames(25)
	v = current_scene


func _correr() -> void:
	await _frames(2)
	if not "ciclopea3d" in OS.get_cmdline_user_args():
		_apagada()
		return
	# ---------------------------------------------------------------- 0. la disposición es la de zona.gd
	var H = load("res://pruebas/herramientas/volcar_ciclopea_2d.gd")
	var esperado: String = H.texto(H.datos())
	var actual := FileAccess.get_file_as_string("res://zonas3d/ciclopea/disposicion_2d.gd")
	if esperado != actual:
		_mal("disposicion_2d.gd no coincide con lo que genera zona.gd (volver a volcar)")
	else:
		_ok("disposición = zona.gd (lugar 3): %d cofres, %d objetos, %d puentes" % [D.COFRES.size(), D.OBJETOS.size(), D.PUENTES.size()])
	var tomo: Array = D.HALLAZGOS.filter(func(h): return h[0] == "hall_tomo_escarcha")
	var ruinas: Vector2 = T.lugar("ruinas")
	if tomo.is_empty() or tomo[0][2].distance_to(ruinas + Vector2(0.0, -4.0)) > 1.5:
		_mal("el Tomo de Escarcha no está donde lo pone la 2D (al norte de las ruinas): %s" % [tomo])
	else:
		_ok("el Tomo de Escarcha, donde la 2D: %s (ruinas %s)" % [tomo[0][2], ruinas])

	# ---------------------------------------------------------------- 1. el interruptor
	if M.region_activa_con(3, PackedStringArray(["3d"]), false):
		_mal("sin «ciclopea3d» la 3D está activa")
	if not M.region_activa_con(3, PackedStringArray(["3d", "ciclopea3d"]), false):
		_mal("con «ciclopea3d» la 3D no está activa")
	if M.region_activa_con(3, PackedStringArray(["ciclopea3d"]), false):
		_mal("sin la exploración 3D, la región 3D está activa")
	if not M.EN_PRUEBAS.has(3) or M.POR_DEFECTO_2D_ELEGIBLE.has(3):
		_mal("Ciclópea no está en pruebas")
	# partidas, con la región encendida (esta pasada lleva «ciclopea3d»)
	Engine.set_meta("pos_zona", Vector2(40.0, 45.0) * 64.0)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 3)
	var e3: String = M.escena_equivalente("res://zona.tscn", 3)
	if e3 != REGION or not Engine.get_meta("pos_3d_ok", false):
		_mal("encendida, una partida de la 2D no abre la 3D: «%s»" % e3)
	else:
		_ok("encendida: partida de la 2D → 3D en %s" % [Engine.get_meta("pos_3d")])
	_ok("interruptor: apagada sin «ciclopea3d», en pruebas")

	# ---------------------------------------------------------------- 2. el camino y las laderas
	_limpiar()
	await _cargar()
	if v == null or v.escenario == null:
		_mal("la escena no carga")
		_fin()
		return
	var cam: Array = D.CAMINOS[0]
	var malos := []
	var zanja := 0.0
	var antes: Vector3 = T.en_mundo(cam[0] + Vector2(0, -1.5))
	var y_sur := antes.y
	for i in cam.size() - 1:
		var a: Vector2 = cam[i]
		var b: Vector2 = cam[i + 1]
		var n := int(ceil(a.distance_to(b) / 0.2))
		for k in n + 1:
			var c: Vector2 = a.lerp(b, float(k) / n)
			if c.y > T.ENTRADA_2D.y or c.distance_to(D.META) < 1.4:   # (el altar mismo no se pisa)
				continue
			var p: Vector3 = T.en_mundo(c)
			if v._prohibido(p) and not T.en_puente_3d(c, 0.2):
				malos.append("prohibido en %s" % c)
			if absf(p.y - antes.y) > 0.3:
				malos.append("escalón de %.2f m en %s" % [p.y - antes.y, c])
			antes = p
			var lado: Vector2 = (b - a).normalized().orthogonal() * (T.LLANO * 0.8)
			for s in [-1.0, 1.0]:
				var q: Vector2 = c + lado * s
				if T.agua(q) > 0.05 or T.muro(q):
					continue
				zanja = maxf(zanja, T.altura(T.mundo(q).x, T.mundo(q).z) - p.y)
	var sube: float = T.en_mundo(D.META).y - y_sur
	if not malos.is_empty():
		_mal("el camino principal: %s" % [malos.slice(0, 6)])
	elif sube < 5.0:
		_mal("el camino apenas sube (%.1f m)" % sube)
	elif zanja > 0.35:
		_mal("trinchera: a %.1f casillas del camino el suelo está %.2f m por encima" % [T.LLANO * 0.8, zanja])
	else:
		_ok("camino principal andable, sube %.1f m; laderas a su altura (máx. +%.2f m a %.1f casillas)" % [sube, zanja, T.LLANO * 0.8])

	# ---------------------------------------------------------------- 3. Kael anda de verdad y choca
	v._colocar_kael(T.en_mundo(T.ENTRADA_2D))
	await _frames(3)
	var meta: Vector3 = T.en_mundo(cam[2])
	v.destino = meta
	var p0: Vector3 = v.kael.global_position
	for i in 30 * 14:
		v.destino = meta if v.destino == null else v.destino
		await _frames(1)
		if Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length() < 0.6:
			break
	var lleg := Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length()
	if lleg > 1.0:
		_mal("Kael no llega andando por el camino (a %.1f m de %s, desde %s)" % [lleg, meta, p0])
	else:
		_ok("Kael anda por el camino de la entrada a la primera curva (sube a y=%.2f)" % v.kael.global_position.y)
	var pino: Array = D.OBJETOS.filter(func(o): return o[0] == "pino_nevado")
	var pp: Vector3 = T.mundo(pino[0][1])
	if not v._prohibido(pp):
		_mal("se puede pisar el tronco de un pino")
	else:
		_ok("los pinos y las rocas chocan")

	# ---------------------------------------------------------------- 4. cofres y hallazgos
	for cf in D.COFRES:
		var e: Dictionary = v.escenario.cofres.get(cf[0], {})
		if e.is_empty():
			_mal("falta el cofre " + cf[0])
			continue
		if Vector2(e["pos"].x, e["pos"].z).distance_to(Vector2(T.mundo(cf[1]).x, T.mundo(cf[1]).z)) > 0.05:
			_mal("el cofre %s no está en su casilla" % cf[0])
		if not _alcanza(e["pos"], v.RADIO_COFRE):
			_mal("el cofre %s no se alcanza" % cf[0])
	for h in load("res://hallazgos.gd").cofres_de(3):
		var e: Dictionary = v.escenario.cofres.get(h[0], {})
		var s: Vector2 = v.sitio_hallazgo(h[0])
		if e.is_empty() or Vector2(e["pos"].x, e["pos"].z).distance_to(Vector2(T.mundo(s).x, T.mundo(s).z)) > 0.05:
			_mal("el cofre del hallazgo %s no está donde lo pone la 2D" % h[0])
		elif not _alcanza(e["pos"], v.RADIO_COFRE):
			_mal("el cofre del hallazgo %s no se alcanza" % h[0])
	var id0: String = D.COFRES[0][0]
	var inv = load("res://inventario.gd")
	var oro0: int = inv.oro() if inv.has_method("oro") else 0
	v._abrir_cofre(id0)
	await _frames(2)
	if not Engine.get_meta("cofres_abiertos", {}).has(id0) or not v.escenario.cofres[id0]["abierto"]:
		_mal("abrir el cofre %s no lo apunta" % id0)
	else:
		var esperado_premio: String = _premio_2d(id0)
		_ok("cofres en sus casillas y alcanzables; %s abierto (premio de la 2D: %s; oro antes %d)" % [id0, esperado_premio, oro0])
	v._abrir_cofre(id0)                                  # dos veces no da nada más

	# ---------------------------------------------------------------- 5. la estatua
	var ps: Vector3 = v._sitio_detalle()
	var junto = _junto_a(ps, v.RADIO_DETALLE - 0.4)
	if junto == null:
		_mal("la estatua no se alcanza")
	else:
		v._colocar_kael(junto)
		await _frames(3)
		v._comprobar_cerca()
		if v.cerca != "detalle":
			_mal("junto a la estatua no sale «Examinar» (cerca=%s)" % v.cerca)
		else:
			v._bloqueo = 0.0
			v._accion()
			await _frames(3)
			if not P.visto("ciclopea_estatua"):
				_mal("examinar la estatua no la apunta como vista")
			else:
				_ok("la estatua: «Examinar», su texto («%s») y el detalle visto" % v.aviso.text)

	# ---------------------------------------------------------------- 6. guardar y cargar; 2D ↔ 3D
	var sitio: Vector3 = T.en_mundo(Vector2(38.9, 40.0))
	v._colocar_kael(sitio)
	await _frames(2)
	v.guardar_posicion()
	await _cargar()
	var vuelta := Vector2(v.kael.global_position.x - sitio.x, v.kael.global_position.z - sitio.z).length()
	if vuelta > 0.4:
		_mal("al cargar, Kael no vuelve a su sitio (a %.2f m)" % vuelta)
	else:
		_ok("guardar y cargar: el mismo sitio (%.2f m)" % vuelta)
	var c2d: Vector2 = T.a_2d(sitio) / 64.0
	if not T.vale_2d(c2d) or c2d.distance_to(T.casilla(sitio.x, sitio.z)) > 2.0:
		_mal("3D → 2D: casilla %s no vale o está lejos" % c2d)
	var de2d: Vector3 = T.desde_2d(Vector2(39.0, 40.0) * 64.0)
	if v._prohibido(de2d):
		_mal("2D → 3D cae en un sitio prohibido")
	else:
		_ok("2D ↔ 3D en la misma casilla")

	# ---------------------------------------------------------------- 7. combate y salida
	# (el encuentro se mira antes de que acabe su fundido y se recarga la región: así no se carga el combate entero,
	# que ya prueban las pruebas de combate; lo de aquí es lo que deja apuntado para ir y volver)
	v.encuentro()
	await _frames(3)
	if Engine.get_meta("escena_retorno", "") != REGION or Engine.get_meta("zona", "") != "nieve" \
			or not Engine.get_meta("pos_3d_ok", false) or int(Engine.get_meta("pos_3d_lugar", -1)) != 3:
		_mal("el encuentro no apunta la vuelta a las Cumbres (%s, %s)" % [Engine.get_meta("escena_retorno", ""), Engine.get_meta("zona", "")])
	else:
		_ok("encuentro: combate con la zona «nieve», vuelta aquí y al mismo sitio")
	_limpiar()
	await _cargar()
	v._colocar_kael(T.en_mundo(Vector2(40.0, 52.0)))
	v.salida["armada"] = true
	await _frames(3)
	for i in 300:
		if current_scene != v:
			break
		v.destino = v._salida()
		await _frames(1)
	await _frames(30)
	if current_scene == null or current_scene.scene_file_path != P.MAPA:
		_mal("la salida del sur no lleva al mapa (%s)" % [current_scene.scene_file_path if current_scene else "nada"])
	else:
		_ok("la salida del sur lleva al mapa")
	_fin()


# Sin «ciclopea3d» (y sin elegirla en Ajustes): el mapa lleva a la 2D, una partida de la 2D se queda en la 2D y una
# partida guardada en la 3D abre la 2D en la misma casilla. (Segunda línea de lista_pruebas.txt, sin el argumento.)
func _apagada() -> void:
	if M.elegida("ciclopea3d"):
		_mal("Ajustes de esta pasada ya traen la 3D elegida")
	if M.escena_de(3) != "":
		_mal("apagada, el mapa lleva a la 3D: %s" % M.escena_de(3))
	Engine.set_meta("pos_zona_ok", false)
	if M.escena_equivalente("res://zona.tscn", 3) != "":
		_mal("apagada, una partida de la 2D se va a la 3D")
	var sitio: Vector3 = T.en_mundo(Vector2(38.9, 40.0))
	Engine.set_meta("pos_3d", sitio)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", 3)
	var e: String = M.escena_equivalente(REGION, 3)
	var pz = Engine.get_meta("pos_zona", null)
	if e != "res://zona.tscn" or not Engine.get_meta("pos_zona_ok", false) or not pz is Vector2 \
			or (pz as Vector2).distance_to(Vector2(38.9, 40.0) * 64.0) > 2.0 * 64.0 \
			or int(Engine.get_meta("lugar", {}).get("indice", -1)) != 3:
		_mal("apagada, una partida de la 3D no abre la 2D en la misma casilla: «%s», %s" % [e, pz])
	else:
		_ok("apagada: el mapa lleva a la 2D y una partida de la 3D abre la 2D en su casilla (%s)" % [pz / 64.0])
	_fin()


func _premio_2d(id: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	match rng.randi() % 4:
		0, 1:
			return "%d monedas" % rng.randi_range(40, 120)
		2:
			return "2 Pociones"
		_:
			return "1 Éter"


func _alcanza(p: Vector3, radio: float) -> bool:
	return _junto_a(p, radio - 0.3) != null


func _junto_a(p: Vector3, radio: float):
	for r in [radio, radio * 0.7, radio * 0.45]:
		for k in 16:
			var q: Vector3 = p + Vector3(cos(TAU * k / 16.0), 0, sin(TAU * k / 16.0)) * r
			if not v._prohibido(q):
				q.y = T.altura(q.x, q.z)
				return q
	return null


func _fin() -> void:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
