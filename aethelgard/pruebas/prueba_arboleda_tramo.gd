extends SceneTree
# V12 (16/11): Arboleda Mítica, tramo EXPERIMENTAL «La escalera de la Hospedería» (zonas3d/arboleda_tramo/,
# docs/v12/ARBOLEDA_HOSPEDERIA.md; plan: docs/v12/SUNKEN_ARBOLEDA_PLAN.md §3.8). Con ventana (lee píxeles), como
# prueba_isla. Todo en la partida AISLADA del banco (banco_pruebas.gd): la de siempre no se lee ni se escribe.
#   A. Nadie más la enlaza: mapa.gd, mapamundi_3d.gd e isla.gd no la nombran; solo el banco, recursos.gd (EXCLUIR) y
#      musica.gd; fuera de las APK 0, 1 y 2; isla_paso.png sin cambios (suma MD5); no se precarga; música «viento».
#   B. Máscara combinada (isla_paso + paso_extra): desde LLEGADA se llega a la terraza, a la puerta y a la cornisa, y
#      ninguna celda nueva queda suelta.
#   B2. Con las piezas y los vecinos puestos (_choca_pieza y _choca_npc, como al andar): desde la puerta de la terraza se
#      llega al lino y al banco de la cornisa (las macetas cerraban el único paso: revisión del 16/11), y Kael anda de
#      verdad hasta el lino siguiendo ese camino.
#   C. Andar de verdad: de lo alto de la escalera de piedra a la puerta, con destino (toque/ratón) y con teclas en
#      diagonal (resbala por un eje y no se atasca).
#   D. Kael queda tapado detrás de cada pieza nueva y detrás del mostrador (lectura de píxel, como prueba_tapa).
#   E. Lumi sin flor dice su frase [C]; Nívea habla; con la flor, el hito isla_flor_lumi queda en la partida del banco
#      (y en su archivo), y el dibujo se ve en la Hospedería. La Cinta de Lumi sigue fuera (hallazgos.gd).
#   F. Hospedería: entrar (la isla se oculta), Yedra, dormir (cobra 20 y cura), sin dinero (aviso de error), guardar
#      dentro (pos_isla = la puerta de la terraza; al volver a cargar se aparece fuera), salir, ir al portal y al mapa.
#   H. «Volver al banco» (Recursos.cambiar_escena con destino el banco) suelta las texturas de la isla y del tramo (grupo
#      «zona»), y salir del banco hacia otra escena suelta lo que hubiera (revisión del 16/11).
#   G. Frases ≤ 110 y sin vetos (D-033 y D-073; y nada que explique la niebla).
# Uso: godot --path aethelgard --resolution 1600x720 --script res://pruebas/prueba_arboleda_tramo.gd -- <carpeta> sin_prologo
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const ESCENA := "res://zonas3d/arboleda_tramo/arboleda_tramo.tscn"
const CARPETA := "res://zonas3d/arboleda_tramo/"
const MD5_PASO := "51de81365d11faaf016a5a507565c269"      # isla/isla_paso.png el 16/11 (6ad4ad6)
const ARRIBA_PIEDRA := Vector2(2200, 2112)                  # lo alto de la escalera de piedra (ya se llegaba)
var salida := ""
var fallos := 0
var hechos: Array = []
var R
var BP
var P
var G
var I


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(salida)
	R = root.get_node("Recursos")
	BP = load("res://banco_pruebas.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	_correr.call_deferred()


func _ok(c: bool, que: String) -> void:
	if not c:
		fallos += 1
		print("FALLO: ", que)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _foto(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [salida, n])


# (18/11) espera por RELOJ: la escena llega con Recursos.cambiar_escena, que carga en segundo plano y tarda en tiempo
# real. Antes contaba 1200 fotogramas, que con --fixed-fps y una pantalla de 144 Hz o más son 4-8 s reales; si la carga
# tardaba más, la prueba seguía y pedía la escena siguiente con el cambio aún en curso, y Recursos.cambiar_escena la
# ignoraba (la misma carrera que prueba_bosque_pastos, docs/v12/PRUEBAS_CARRERAS_18_11.md). Si a los 60 s no ha
# terminado, falla con un mensaje propio y termina ahí, sin pedir nada más.
func _esperar_escena(ruta: String, segundos := 60.0) -> Node:
	var t0 := Time.get_ticks_msec()
	while R.cambiando or current_scene == null or current_scene.scene_file_path != ruta:
		if Time.get_ticks_msec() - t0 > int(segundos * 1000.0):
			_ok(false, "%s no termina de cargarse en %d s (R.cambiando=%s, escena=%s): no se pide nada más" % [ruta,
				int(segundos), R.cambiando, current_scene.scene_file_path if current_scene != null else "(ninguna)"])
			print("FALLOS: %d" % fallos)
			quit(1)
			await process_frame                    # no vuelve: el proceso termina en este fotograma
			return null
		await process_frame
	await _frames(3)
	return current_scene


func _correr() -> void:
	_estatico()
	_mascara()
	await _juego()
	print("HECHO:\n  " + "\n  ".join(hechos))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= A y G (sin escena)

static func _sin_tildes(t: String) -> String:
	var r := t.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		r = r.replace(par[0], par[1])
	return r


func _estatico() -> void:
	_ok(FileAccess.get_md5("res://isla/isla_paso.png") == MD5_PASO, "A: isla_paso.png ha cambiado")
	for f in ["res://mapa.gd", "res://zonas3d/mapamundi_3d.gd", "res://isla.gd", "res://isla.tscn", "res://zona.gd",
			"res://progreso.gd", "res://hallazgos.gd"]:
		_ok(not FileAccess.get_file_as_string(f).contains("arboleda_tramo"), "A: %s nombra el tramo" % f)
	var nombran: Array = []
	_buscar("res://", nombran)
	nombran.sort()
	_ok(nombran == ["res://banco_pruebas.gd", "res://musica.gd", "res://recursos.gd"],
		"A: lo nombran fuera de su carpeta y de pruebas/: %s" % str(nombran))
	var cfg := ConfigFile.new()
	cfg.load("res://export_presets.cfg")
	_ok("zonas3d/*" in str(cfg.get_value("preset.0", "exclude_filter", "")), "A: la APK estable no excluye zonas3d/*")
	for k in [1, 2]:
		_ok("zonas3d/arboleda_tramo/*" in str(cfg.get_value("preset.%d" % k, "exclude_filter", "")),
			"A: el preset %d no excluye el tramo" % k)
	_ok(CARPETA in R.EXCLUIR, "A: el tramo no está en EXCLUIR (se precargaría)")
	var en_comun: Array = R.grupos["comun"].keys().filter(func(k): return str(k).begins_with(CARPETA))
	_ok(en_comun.is_empty(), "A: hay recursos del tramo en la precarga común: %s" % str(en_comun))
	var n := Node2D.new()
	n.scene_file_path = ESCENA
	_ok(load("res://musica.gd").contexto_de(n) == "viento", "A: el tramo no tiene la música de viento")
	n.free()
	_ok(BP.EXPLORAR.has("arboleda") and BP.EXPLORAR["arboleda"].get("escena", "") == ESCENA, "A: falta la entrada del banco")
	_ok("arboleda_flor" in BP.METAS_SESION, "A: «arboleda_flor» no es de la sesión del banco")
	_ok(load("res://hallazgos.gd").FUERA.has("cinta_lumi"), "E: la Cinta de Lumi ha salido de FUERA")
	hechos.append("A: nadie más la enlaza; fuera de las APK 0-2; isla_paso intacta; sin precarga; música «viento»")
	# G: frases
	var F = load(CARPETA + "lumi_flor.gd")
	var H = load(CARPETA + "hospederia.gd")
	var frases: Array = [F.PIDE, F.GRACIAS, F.AL_DAR, F.DESPUES, H.YEDRA["con_dibujo"]]
	frases += F.NIVEA["frases"] + H.YEDRA["frases"]
	for l in H.DESCANSO:
		frases.append(l[1])
	var CD = load("res://pruebas/prueba_ciudad_datos.gd")
	var vetos: Array = CD.PROHIBIDO_D033 + CD.PROHIBIDO_NEUTRO + ["niebla"]
	for f in frases:
		_ok(f.length() <= 110, "G: frase de más de 110: %s" % f)
		for v in vetos:
			_ok(not _sin_tildes(f).contains(v), "G: «%s» en: %s" % [v, f])
	hechos.append("G: %d frases ≤ 110 y sin vetos (D-033, D-073, niebla)" % frases.size())


func _buscar(dir: String, nombran: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if sub.begins_with(".") or (dir + sub + "/") in ["res://addons/", "res://pruebas/", "res://zonas3d/arboleda_tramo/"]:
			continue
		_buscar(dir + sub + "/", nombran)
	for f in d.get_files():
		if f.get_extension() in ["gd", "tscn", "tres"] and FileAccess.get_file_as_string(dir + f).contains("arboleda_tramo"):
			nombran.append(dir + f)


# ================================================================= B (máscara combinada)

func _mascara() -> void:
	var paso: Image = load("res://isla/isla_paso.png").get_image()
	var extra: Image = load(CARPETA + "tramo/paso_extra.png").get_image()
	var w := paso.get_width()
	var h := paso.get_height()
	var anda := func(x: int, y: int) -> bool: return paso.get_pixel(x, y).r > 0.5 or extra.get_pixel(x, y).r > 0.5
	var alc := PackedByteArray()
	alc.resize(w * h)
	var ini := Vector2i(1444 / 4, 2624 / 4)
	var cola := [ini.y * w + ini.x]
	alc[cola[0]] = 1
	var n := 0
	while not cola.is_empty():
		var k: int = cola.pop_back()
		n += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var x: int = k % w + d.x
			var y: int = k / w + d.y
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			if alc[y * w + x] == 0 and anda.call(x, y):
				alc[y * w + x] = 1
				cola.append(y * w + x)
	var T = load(CARPETA + "arboleda_tramo.gd")
	var puerta: Vector2 = T.PUERTA_HOSPEDERIA
	_ok(alc[int(puerta.y / 4) * w + int(puerta.x / 4)] == 1, "B: no se llega a la puerta de la Hospedería")
	for p in T.PIEZAS:
		var q: Vector2 = p["pies"]
		_ok(alc[int(q.y / 4) * w + int(q.x / 4)] == 1, "B: no se llega a la pieza %s" % p["imagen"])
	var sueltas := 0
	for y in h:
		for x in w:
			if extra.get_pixel(x, y).r > 0.5 and alc[y * w + x] == 0:
				sueltas += 1
	_ok(sueltas == 0, "B: %d celdas nuevas sueltas" % sueltas)
	_ok(n > 118713, "B: la parte alcanzable no crece (%d)" % n)
	hechos.append("B: alcanzables desde LLEGADA %d celdas (antes 118 713); puerta, cornisa y piezas alcanzables; 0 sueltas" % n)


# ================================================================= C-F (con la escena)

func _juego() -> void:
	BP.preparar_partida()                          # la partida aislada del banco
	BP.poner_grupo(BP.EXPLORAR["arboleda"]["activos"])
	Engine.set_meta("arboleda_flor", false)
	R.cambiar_escena(ESCENA)
	var v = await _esperar_escena(ESCENA)
	_ok(v != null, "C: no se abre el tramo")
	if v == null:
		return
	await _frames(20)
	_foto("1_llegada")
	_ok(v.jugador.position.distance_to(v.LLEGADA) < 2.0, "C: Kael no aparece en la llegada")
	# E: Lumi sin flor (frase [C]) y Nívea
	var lumi = v.lumi
	v.jugador.position = lumi[0].position + Vector2(-50, 10)
	v._comprobar_cerca()
	_ok(v.boton.visible and v.boton.text == "Hablar con Lumi", "E: junto a Lumi no sale «Hablar con Lumi»")
	v._accion()
	_ok(v.aviso.text.contains("¡Yo nunca he bajado!"), "E: sin flor, Lumi no dice su frase [C]: " + v.aviso.text)
	for k in 2:
		v._accion()
	_ok(v.aviso.text.contains(load(CARPETA + "lumi_flor.gd").PIDE), "E: Lumi no pide la flor: " + v.aviso.text)
	_ok(not P.hito("isla_flor_lumi"), "E: sin flor ya está el hito")
	var nivea = v.npcs[-1]
	v.jugador.position = nivea[0].position + Vector2(45, 8)
	v._comprobar_cerca()
	_ok(v.boton.text == "Hablar con Nívea", "E: junto a Nívea: " + v.boton.text)
	v._accion()
	_ok(v.aviso.text.begins_with("Abuela Nívea:"), "E: Nívea no habla")
	_foto("2_plaza_lumi_nivea")
	hechos.append("E: Lumi (frase [C] y luego la petición [P]) y Nívea en la plaza")
	await _cornisa(v)                              # (antes de _andar: D mide con Kael como lo deja _andar)
	await _andar(v)
	await _tapado_piezas(v)
	await _hospederia(v)


func _andar(v) -> void:
	_ok(v._se_anda(ARRIBA_PIEDRA), "C: lo alto de la escalera de piedra no se anda")
	v.jugador.position = ARRIBA_PIEDRA
	v.camara.reset_smoothing()
	v.destino = v.PUERTA_HOSPEDERIA
	v.tiene_destino = true
	var f := 0
	while f < 240 and v.jugador.position.distance_to(v.PUERTA_HOSPEDERIA) > 8.0:
		await process_frame
		f += 1
		if not v.tiene_destino and v.jugador.position.distance_to(v.PUERTA_HOSPEDERIA) > 8.0:
			break
	var d1: float = v.jugador.position.distance_to(v.PUERTA_HOSPEDERIA)
	_foto("3_puente_destino")
	# con destino en línea recta puede quedarse en un borde (como en toda la isla): entonces, por el puente
	if d1 > 8.0:
		for w in [Vector2(2270, 2140), Vector2(2320, 2130), v.PUERTA_HOSPEDERIA]:
			v.destino = w
			v.tiene_destino = true
			for k in 150:
				await process_frame
				if v.jugador.position.distance_to(w) < 8.0:
					break
	var d2: float = v.jugador.position.distance_to(v.PUERTA_HOSPEDERIA)
	_ok(d2 < 10.0, "C: tocando, Kael no llega a la puerta (queda a %.0f px)" % d2)
	# teclas en diagonal (↗) desde lo alto de la escalera de piedra: resbala por un eje y cruza el puente
	v.jugador.position = ARRIBA_PIEDRA + Vector2(0, 24)
	v.tiene_destino = false
	Input.action_press("ui_right")
	Input.action_press("ui_up")
	var max_x := 0.0
	var quieto := 0
	var antes: Vector2 = v.jugador.position
	for k in 150:
		await process_frame
		max_x = maxf(max_x, v.jugador.position.x)
		quieto = quieto + 1 if v.jugador.position.distance_to(antes) < 0.01 else 0
		antes = v.jugador.position
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	_ok(max_x > 2300.0, "C: con teclas en diagonal no cruza el puente (x máx %.0f)" % max_x)
	_foto("4_teclas_diagonal")
	hechos.append("C: tocando llega a la puerta (en línea recta: a %.0f px%s); con ↗ cruza el puente y sube hasta x %.0f, %s (parado %d fotogramas al final: el muro de la casa)" % [
		d1, "" if d1 <= 8.0 else ", por el puente sí", max_x, str(v.jugador.position), quieto])


# B2: BFS en celdas de 4 px por la terraza, el paso y la cornisa, con lo que mira _se_anda al andar (las piezas, los
# vecinos y la máscara combinada). Del lino (no bloquea) se pide su celda; del banco (bloquea 26), llegar a su lado.
const ZONA_CORNISA := Rect2(2150, 1880, 650, 380)

func _cornisa(v) -> void:
	var r := ZONA_CORNISA
	var w := int(r.size.x / 4)
	var h := int(r.size.y / 4)
	var centro := func(k: int) -> Vector2: return r.position + Vector2((k % w) * 4 + 2, (k / w) * 4 + 2)
	var anda := func(p: Vector2) -> bool: return not v._choca_pieza(p) and not v._choca_npc(p) and v._se_anda(p)
	var lino: Vector2
	var banco: Vector2
	var r_banco := 0.0
	for s in v.piezas:
		if "lino" in s.get_meta("pieza"):
			lino = s.position
		elif "banco" in s.get_meta("pieza"):
			banco = s.position
			r_banco = s.get_meta("bloquea")
	var ini := int((v.PUERTA_HOSPEDERIA.y - r.position.y) / 4) * w + int((v.PUERTA_HOSPEDERIA.x - r.position.x) / 4)
	_ok(anda.call(centro.call(ini)), "B2: la puerta de la terraza no se anda")
	var padre := PackedInt32Array()
	padre.resize(w * h)
	padre.fill(-2)
	padre[ini] = -1
	var cola := [ini]
	var i := 0
	var k_lino := -1
	var d_lino := INF
	var d_banco := INF
	while i < cola.size():
		var k: int = cola[i]
		i += 1
		var p: Vector2 = centro.call(k)
		if p.distance_to(lino) < d_lino:
			d_lino = p.distance_to(lino)
			k_lino = k
		d_banco = minf(d_banco, p.distance_to(banco))
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var x: int = k % w + d.x
			var y: int = k / w + d.y
			if x < 0 or y < 0 or x >= w or y >= h or padre[y * w + x] != -2:
				continue
			if anda.call(centro.call(y * w + x)):
				padre[y * w + x] = k
				cola.append(y * w + x)
	_ok(d_lino < 6.0, "B2: desde la puerta no se llega al lino (la celda más cerca, a %.0f px)" % d_lino)
	_ok(d_banco < r_banco + 8.0, "B2: desde la puerta no se llega al banco (a %.0f px; bloquea %.0f)" % [d_banco, r_banco])
	# andar de verdad: de la puerta al lino, con destino (toque) por el camino del BFS, un punto cada 12 px
	var camino: Array = []
	var k2 := k_lino
	while k2 >= 0:
		camino.push_front(centro.call(k2))
		k2 = padre[k2]
	v.jugador.position = v.PUERTA_HOSPEDERIA
	v.camara.reset_smoothing()
	for j in range(3, camino.size() + 2, 3):
		var meta: Vector2 = camino[mini(j, camino.size() - 1)]
		v.destino = meta
		v.tiene_destino = true
		for f in 30:
			await process_frame
			if v.jugador.position.distance_to(meta) < 6.0 or not v.tiene_destino:
				break
	var fin: float = v.jugador.position.distance_to(lino)
	_ok(fin < 12.0, "B2: andando por el camino, Kael se queda a %.0f px del lino (%s)" % [fin, str(v.jugador.position)])
	await _frames(5)
	_foto("3b_cornisa_lino")
	v.tiene_destino = false                         # (si no, seguiría andando hacia el lino)
	v.jugador.position = v.PUERTA_HOSPEDERIA
	v.camara.reset_smoothing()
	hechos.append("B2: con piezas y vecinos, de la puerta al lino (celda a %.0f px) y al banco (a %.0f px, bloquea %.0f): %d celdas; andando, Kael llega a %.0f px del lino (%d puntos)" % [
		d_lino, d_banco, r_banco, cola.size(), fin, camino.size()])


# D: para cada pieza, Kael detrás (sus pies 5 px por encima de los de la pieza): donde se ven a la vez la pieza y Kael,
# el píxel es el de la pieza (A == B), con la prueba hecha solo donde la pieza se ve (B != C) y Kael también (E != C).
func _tapado_piezas(v) -> void:
	var tapadas := 0
	for s in v.piezas:
		var r = await _tapado(v, s, s.position + Vector2(0, -5))
		_ok(r != null, "D: no hay dónde probar la pieza %s" % s.get_meta("pieza"))
		if r == null:
			continue
		_ok(r, "D: Kael NO queda tapado detrás de %s" % s.get_meta("pieza"))
		if r:
			tapadas += 1
	hechos.append("D: Kael tapado detrás de %d de %d piezas de la terraza" % [tapadas, v.piezas.size()])


func _captura() -> Image:
	await _frames(3)
	return root.get_viewport().get_texture().get_image()


func _tapado(v, pieza: CanvasItem, pies_kael: Vector2, alto := 60):
	v.jugador.position = pies_kael
	v.camara.reset_smoothing()
	v._poner_z()
	await _frames(4)
	var xf: Transform2D = root.get_viewport().get_canvas_transform()
	pieza.visible = true
	v.sprite.visible = true
	var a: Image = await _captura()
	v.sprite.visible = false
	var b: Image = await _captura()
	pieza.visible = false
	var c: Image = await _captura()
	v.sprite.visible = true
	var e: Image = await _captura()
	pieza.visible = true
	var probados := 0
	var bien := 0
	for dy in range(-alto, -2, 3):
		for dx in range(-24, 25, 3):
			var p: Vector2 = xf * (pies_kael + Vector2(dx, dy))
			var x := int(p.x)
			var y := int(p.y)
			if x < 0 or y < 0 or x >= a.get_width() or y >= a.get_height():
				continue
			if _dif(b, c, x, y) < 0.25 or _dif(e, c, x, y) < 0.25:     # la pieza y Kael, bien opacos ahí
				continue
			probados += 1
			if _dif(a, b, x, y) < 0.03:
				bien += 1
	if probados < 3:
		return null
	if bien < int(probados * 0.9):
		var n := str(pieza.get_meta("pieza", "fondo")).get_file().get_basename()
		for par in [[a, "A"], [b, "B"], [c, "C"], [e, "E"]]:
			par[0].save_png("%s/fallo_tapa_%s_%s.png" % [salida, n, par[1]])
		print("tapa %s: %d de %d píxeles bien" % [n, bien, probados])
	return bien >= int(probados * 0.9)


func _sitio_tapado(v) -> Vector2:
	var h = v.hosp
	var tapa: Image = h.tapa_tex.get_image()
	var mejor := Vector2.ZERO
	var cubre := 0
	for y in range(0, h.paso_img.get_height(), 2):
		for x in range(0, h.paso_img.get_width(), 2):
			if h.paso_img.get_pixel(x, y).r < 0.5:
				continue
			var zs: float = h.suelo_img.get_pixel(x, y).r
			if zs <= 0.0:
				continue
			# cuántas muestras del cuerpo (de 4 a 32 px sobre los pies, ±16 px a los lados) tienen delante algo más cercano
			var n := 0
			for dy in range(4, 33, 4):
				var yy := (y * 4 + 2 - dy) / 2
				if yy < 0:
					break
				for dx in [-8, -4, 0, 4, 8]:
					var xx := clampi(x * 2 + 1 + dx, 0, tapa.get_width() - 1)
					var d := tapa.get_pixel(xx, yy).r
					if d > zs + 0.02 and d < zs + 0.4:
						n += 1
			if n > cubre:
				cubre = n
				mejor = h.ORIGEN + Vector2(x * 4 + 2, y * 4 + 2)
	return mejor if cubre >= 28 else Vector2.ZERO          # (de 40 muestras: 8 filas × 5 columnas)

static func _dif(a: Image, b: Image, x: int, y: int) -> float:
	var p := a.get_pixel(x, y)
	var q := b.get_pixel(x, y)
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)


func _hospederia(v) -> void:
	# entrar
	v.jugador.position = v.PUERTA_HOSPEDERIA
	v.camara.reset_smoothing()
	v._comprobar_cerca()
	_ok(v.boton.text == "Entrar en la Hospedería", "F: en la puerta no sale «Entrar en la Hospedería»: " + v.boton.text)
	_foto("5_puerta")
	v._accion()
	for k in 60:
		await process_frame
		if v.dentro and not v.en_transicion:
			break
	await _frames(20)
	_ok(v.dentro, "F: no se entra en la Hospedería")
	var fuera_visibles: Array = v.exterior.filter(func(c): return c.visible)
	_ok(fuera_visibles.is_empty(), "F: dentro se siguen viendo %d cosas de la isla" % fuera_visibles.size())
	_ok(v.hosp.visible, "F: el interior no se ve")
	_ok(v.camara.limit_left == int(v.hosp.ORIGEN.x), "F: la cámara no cambia sus límites al interior")
	_ok(v.jugador.position.distance_to(v.hosp.entrada()) < 2.0, "F: Kael no aparece en la entrada de dentro")
	_foto("6_interior")
	# Yedra
	v.jugador.position = v.hosp.ORIGEN + v.hosp.anclas["mostrador"]
	v._comprobar_cerca()
	_ok(v.boton.text == "Hablar con Yedra", "F: junto al mostrador: " + v.boton.text)
	v._accion()
	_ok(v.aviso.text.begins_with("Yedra:"), "F: Yedra no habla")
	# Kael detrás de un mueble queda tapado (la tapa del interior): el sitio andable con algo delante más cercano, como
	# prueba_tapa (dentro solo se pisa el suelo que se ve, así que «detrás» es poco: los pies junto a un mueble)
	var detras := _sitio_tapado(v)
	_ok(detras != Vector2.ZERO, "D: dentro no hay ningún sitio andable con un mueble delante")
	if detras != Vector2.ZERO:
		var r = await _tapado(v, v.hosp.fondo, detras, 32)
		_ok(r == true, "D: Kael no queda tapado detrás de un mueble en %s (%s)" % [str(detras), str(r)])
		hechos.append("D: dentro, Kael tapado por el mueble que tiene delante en %s" % str(detras - v.hosp.ORIGEN))
	# dormir: cobra 20 y cura
	G.datos()["Kael"]["pv"] = 1
	var oro_antes: int = I.oro()
	v.jugador.position = v.hosp.ORIGEN + v.hosp.anclas["cama"]
	v._comprobar_cerca()
	_ok(v.boton.text == "Dormir (20 monedas)", "F: junto a la cama: " + v.boton.text)
	v._accion()
	_ok(I.oro() == oro_antes - 20, "F: dormir no cobra 20 (%d → %d)" % [oro_antes, I.oro()])
	_ok(int(G.datos()["Kael"]["pv"]) != 1, "F: dormir no cura a Kael")
	await _frames(45)
	_foto("7_dormir")
	# sin dinero
	v.hosp.descansando = false
	I.datos()["oro"] = 5
	_ok(not v.hosp.dormir(), "F: sin dinero se duerme")
	_ok(I.oro() == 5 and v.aviso.text.contains("No tienes monedas"), "F: sin dinero no avisa o cobra: " + v.aviso.text)
	I.datos()["oro"] = oro_antes
	hechos.append("F: entrar (isla oculta, límites de cámara), Yedra, dormir (−20, cura) y sin dinero (aviso)")
	# guardar dentro: pos_isla en la puerta de la terraza; al volver a cargar, fuera
	v.guardar_posicion()
	_ok(Engine.get_meta("pos_isla", Vector2.ZERO) == v.PUERTA_HOSPEDERIA and Engine.get_meta("pos_isla_ok", false),
		"F: guardar dentro no deja pos_isla en la puerta de la terraza")
	_ok(P.guardar(ESCENA), "F: no se guarda en la partida del banco")
	var leida = P.leer(P.archivo())
	_ok(leida != null and leida.get("pos_isla", Vector2.ZERO) == v.PUERTA_HOSPEDERIA, "F: el archivo del banco no tiene pos_isla de la terraza")
	_ok(P.archivo() == BP.ARCHIVO, "F: no se guarda en el archivo del banco: " + P.archivo())
	R.cambiar_escena(ESCENA)
	v = await _esperar_escena(ESCENA)
	await _frames(10)
	_ok(not v.dentro and v.jugador.position.distance_to(v.PUERTA_HOSPEDERIA) < 2.0,
		"F: al volver a cargar no se aparece en la terraza (%s)" % str(v.jugador.position))
	hechos.append("F: guardar dentro → pos_isla en la puerta de la terraza; al cargar, Kael en la terraza")
	# E: con la flor
	Engine.set_meta("arboleda_flor", true)
	v.jugador.position = v.lumi[0].position + Vector2(-50, 10)
	v._comprobar_cerca()
	v._accion()
	_ok(P.hito("isla_flor_lumi"), "E: con la flor no queda el hito")
	var guardada = P.leer(P.archivo())
	_ok(guardada != null and guardada.get("hitos", {}).get("isla_flor_lumi", false), "E: el hito no está en la partida del banco")
	await _frames(100)
	_ok(v.aviso.text.contains("Entonces abajo no es gris."), "E: Lumi no da las gracias: " + v.aviso.text)
	_foto("8_flor_lumi")
	v.jugador.position = v.PUERTA_HOSPEDERIA
	v._comprobar_cerca()
	await v.entrar_hospederia(true)
	await _frames(5)
	_ok(v.hosp.dibujo != null and v.hosp.dibujo.visible, "E: el dibujo de Lumi no se ve en la pared")
	v.jugador.position = v.hosp.ORIGEN + v.hosp.anclas["dibujo"] + Vector2(0, 115)
	v.camara.reset_smoothing()
	v._comprobar_cerca()
	_ok(v.boton.text == "Mirar el dibujo", "E: junto al dibujo: " + v.boton.text)
	await _frames(10)
	_foto("9_dibujo")
	hechos.append("E: con la flor, «Entonces abajo no es gris.», el hito en la partida del banco y el dibujo en la pared")
	# salir, portal y mapa
	v.jugador.position = v.hosp.puerta()
	v._comprobar_cerca()
	_ok(v.boton.text == "Salir a la terraza", "F: en la puerta de dentro: " + v.boton.text)
	v._accion()
	for k in 60:
		await process_frame
		if not v.dentro and not v.en_transicion:
			break
	await _frames(10)
	_ok(not v.dentro and v.jugador.position.distance_to(v.PUERTA_HOSPEDERIA) < 20.0, "F: al salir no se vuelve a la terraza")
	_ok(v.exterior.all(func(c): return c.visible), "F: al salir la isla no vuelve")
	v.jugador.position = v.PORTAL + Vector2(0, 40)
	v.camara.reset_smoothing()
	v._comprobar_cerca()
	_ok(v.boton.text == "Bajar al mundo", "F: junto al portal: " + v.boton.text)
	v._accion()
	var m = await _esperar_escena("res://mapa.tscn")
	_ok(m != null, "F: no se llega al mapa")
	var en_zona: Array = R.grupos["zona"].keys().filter(func(k): return str(k).begins_with(CARPETA))
	_ok(en_zona.is_empty(), "F: en el mapa siguen cargados %d recursos del tramo" % en_zona.size())
	hechos.append("F: salir a la terraza, bajar por el portal y llegar al mapa (recursos del tramo soltados)")
	await _volver_al_banco()
	BP.salir()
	_ok(not FileAccess.file_exists(BP.ARCHIVO), "F: la partida del banco no se borra al salir")


# H: lo de la isla y del tramo (grupo «zona» de Recursos) no se queda en memoria al volver al banco ni al salir de él.
func _de_zona() -> Array:
	return R.grupos["zona"].keys().filter(func(k): return str(k).begins_with(CARPETA) or str(k).begins_with("res://isla/"))


func _volver_al_banco() -> void:
	R.cambiar_escena(ESCENA)
	var v = await _esperar_escena(ESCENA)
	_ok(v != null and not _de_zona().is_empty(), "H: al volver al tramo no se carga nada de la isla ni del tramo en «zona»")
	var n := _de_zona().size()
	R.cambiar_escena(BP.ESCENA)                    # (como el botón «Volver al banco» de recursos.gd)
	var b = await _esperar_escena(BP.ESCENA)
	_ok(b != null, "H: no se vuelve al banco")
	_ok(_de_zona().is_empty(), "H: en el banco siguen cargados %d recursos de la isla o del tramo" % _de_zona().size())
	R.guardar("res://pruebas/zona_de_prueba", Resource.new(), "zona")
	R.cambiar_escena(ESCENA)                       # salir del banco (a una exploración; hacia la carga, igual)
	v = await _esperar_escena(ESCENA)
	_ok(v != null and not R.grupos["zona"].has("res://pruebas/zona_de_prueba"), "H: al salir del banco no se suelta «zona»")
	hechos.append("H: en el tramo %d recursos de la isla y del tramo en «zona»; al volver al banco, 0; al salir del banco, «zona» se suelta" % n)
