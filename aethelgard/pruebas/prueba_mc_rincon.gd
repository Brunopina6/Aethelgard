extends SceneTree
# Prueba del rincón del Mar de Cristal (V12, 12/11, narrativa y exploración): el hito del cobijo
# (zonas3d/mar_cristal/rincones.gd y dialogos/mar_cristal/mc_rin_hito*.dtl). Con «-- 3d mardecristal sin_prologo». La
# región guarda de verdad, pero en el archivo propio de la prueba (Engine «archivo_partida_prueba»).
#   1. Textos: las tres variantes, quién habla en cada una (Garon solo en la de grupo, Lya no en la de Kael solo), 70
#      letras como mucho, gestos que existen, nada reservado (Érebo, niebla, anillo, Morgath, Naira…); avisos en dos
#      líneas del aviso de la región y el botón corto.
#   2. Sitio: el hito es el de paisaje.gd (el trapo azul está en su palo), no es arena prohibida ni camino, su botón no
#      pisa el cobijo ni ningún otro botón de la región, nada del buscador se entierra encima y se ve en pantalla desde el
#      cobijo y desde la boca del cañón.
#   3. Se encuentra por el oído: lejos, el vidrio calla; a tiro de oído, suena (Sonido, con posición) y destella; con
#      tormenta, más a menudo y desde más lejos.
#   4. Con Lya y Garon: «Mirar el hito» abre mc_rin_hito, recorrido entero con Dialogic (7 frases, quién habla); al
#      acabar, el hito, dos Pociones una sola vez, el aviso y la partida guardada con todo. Otra vez: solo el aviso.
#      Ningún hito de la misión ni de Naira cambia.
#   5. Recarga desde la partida guardada: el hito sigue, sin premio nuevo.
#   6. Con Lya sola y con Kael solo: sus variantes; un diálogo cortado da el premio igual (una vez).
#   7. Partida antigua (con la misión a medias y sin el hito): carga, el rincón está por descubrir y la misión sigue igual.
#   8. Perfil bajo: el rincón se monta y su botón sale.

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const ARCHIVO := "user://prueba_mc_rincon.save"
const RC := preload("res://zonas3d/mar_cristal/rincones.gd")
const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const GESTOS := ["ligero", "firme", "duda", "sorpresa", "decidido", "brazalete", "inquieta", "preocupada", "decidida",
	"ligero+risa"]
const PROHIBIDAS := ["érebo", "erebo", "corazón", "corazon", "recuerdo", "recuerdos", "memoria", "niebla", "anillo",
	"morgath", "naira", "eclipse", "reina", "espejismos", "lente", "tidus", "yuna", "spira", "final fantasy"]
const VARIANTES := {"": ["kael", "lya", "garon"], "_lya": ["kael", "lya"], "_solo": ["kael"]}
const FRASES := {"": 7, "_lya": 6, "_solo": 4}
const HITOS_MISION := ["mc_inicio", "mc_caravana", "mc_sello", "mc_tormenta", "mc_ruinas", "mc_llave",
	"mc_superviviente", "mc_fin"]

var P
var R
var D
var Inv
var S
var fallos: Array = []
var eventos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


# (19/11, PC-10) por RELOJ, solo para montar la región: con --fixed-fps los fotogramas vuelan y una carga va en tiempo
# real. El resto espera en tiempo de JUEGO a propósito.
func _hasta_reloj(cond: Callable, segundos := 60.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(segundos * 1000.0):
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)


func _borrar_archivo() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _probar() -> void:
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	R = root.get_node("Recursos")
	S = root.get_node_or_null("Sonido")
	D = root.get_node_or_null("Dialogic")
	if not load("res://modo3d.gd").activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d mardecristal»)")
		quit(1)
		return
	if D != null:
		D.event_handled.connect(func(ev):
			if ev is DialogicTextEvent:
				eventos.append([ev.character.get_identifier() if ev.character != null else "", ev.text]))
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar_archivo()
	await _textos()
	await _grupo()
	await _recarga()
	await _variantes()
	await _partida_antigua()
	await _bajo()
	_borrar_archivo()
	Engine.remove_meta("archivo_partida_prueba")
	Engine.remove_meta("calidad_proto")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= 1. textos

func _prohibidas(t: String) -> void:
	for p in PROHIBIDAS:
		if RegEx.create_from_string("(?i)\\b%s\\b" % p).search(t) != null:
			_fallo("1: «%s» dice «%s»" % [t, p])


func _textos() -> void:
	if not "mc_rin_hito" in P.HITOS_MC_RINCONES or RC.HITO_ID != "mc_rin_hito":
		_fallo("1: el hito no está en progreso.gd (HITOS_MC_RINCONES)")
	var re := RegEx.create_from_string("^(\\w+): (.*)$")
	var re_gesto := RegEx.create_from_string("^update (\\w+) \\[extra_data=\"([^\"]*)\"\\]$")
	var re_join := RegEx.create_from_string("^join (\\w+) ")
	var total := 0
	for v in VARIANTES:
		var ruta := "res://dialogos/mar_cristal/%s%s.dtl" % [RC.DIALOGO, v]
		var dtl := FileAccess.get_file_as_string(ruta)
		if dtl == "":
			_fallo("1: falta %s" % ruta)
			continue
		var frases := 0
		var hablan := {}
		var unidos := {}
		for l in dtl.split("\n"):
			l = l.strip_edges()
			var mj := re_join.search(l)
			if mj != null:
				unidos[mj.get_string(1)] = true
			var mg := re_gesto.search(l)
			if mg != null and not mg.get_string(2) in GESTOS:
				_fallo("1: gesto «%s» en %s" % [mg.get_string(2), ruta])
			var mm := re.search(l)
			if mm == null:
				continue
			frases += 1
			total += 1
			var quien := mm.get_string(1)
			var t := mm.get_string(2)
			hablan[quien] = true
			if not quien in VARIANTES[v]:
				_fallo("1: en %s habla «%s», que no está" % [ruta, quien])
			if quien != "garon" and not unidos.has(quien):
				_fallo("1: en %s habla «%s» sin entrar (join)" % [ruta, quien])
			if t.length() > 70:
				_fallo("1: %d letras: %s" % [t.length(), t])
			_prohibidas(t)
			print("FRASE %s %s | %d letras | %s" % [v if v != "" else "_grupo", quien, t.length(), t])
		if unidos.has("garon"):
			_fallo("1: Garon entra con retrato en %s (aún no tiene)" % ruta)
		if frases != FRASES[v]:
			_fallo("1: %s tiene %d frases (%d esperadas)" % [ruta, frases, FRASES[v]])
		for q in VARIANTES[v]:
			if not hablan.has(q):
				_fallo("1: en %s no habla «%s»" % [ruta, q])
	var aviso := Label.new()                       # como el aviso de la región (1000 px, letra de 28)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 120)
	aviso.add_theme_font_size_override("font_size", 28)
	root.add_child(aviso)
	for k in RC.TEXTOS:
		aviso.text = RC.TEXTOS[k]
		_prohibidas(aviso.text)
		await _esperar(2)
		if aviso.get_line_count() > 2:
			_fallo("1: el aviso «%s» ocupa %d líneas" % [k, aviso.get_line_count()])
		print("AVISO %s | %d línea(s) | %s" % [k, aviso.get_line_count(), aviso.text])
	aviso.free()
	if RC.BOTON.length() > 16:
		_fallo("1: el botón «%s» es largo para el móvil" % RC.BOTON)
	print("TEXTOS: %d frases en %d variantes" % [total, VARIANTES.size()])


# ================================================================= región

func _entrar(grupo: Array, perfil := "alto") -> Object:
	Engine.set_meta("grupo_activo", grupo)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("incienso", 100000)            # sin encuentros al azar
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(REGION)
	if not await _hasta_reloj(func(): return current_scene != null and current_scene.scene_file_path == REGION \
			and current_scene.get("kael") != null and not R.cambiando, 120.0):
		_fallo("no se abre el Mar de Cristal en 120 s (R.cambiando=%s)" % R.cambiando)
		return null
	var r = current_scene
	await _esperar(20)
	if r.rincones == null or r.get_node_or_null("RinconHito") == null or r.rincones.vidrios.size() != 3:
		_fallo("la región no monta el rincón del hito (nodo y tres vidrios)")
		return null
	r.clima.sistemicas = false
	return r


func _poner(r, x: float, z: float) -> void:
	r._colocar_kael(Vector3(x, 0, z))
	r._ultima = r.kael.global_position


func _ir_al_hito(r) -> void:
	_poner(r, RC.HITO.x + 0.3, RC.HITO.y + 1.2)
	await _esperar(4)
	r._bloqueo = 0.0
	r._comprobar_cerca()


func _recorrer() -> void:
	var limite := Time.get_ticks_msec() + 25000
	var ultimo := 0
	while D.current_timeline != null and Time.get_ticks_msec() < limite:
		await process_frame
		var fr := Engine.get_process_frames()
		if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and fr - ultimo >= 4:
			D.Inputs.handle_input()
			ultimo = fr
	if D.current_timeline != null:
		_fallo("el diálogo del hito no termina")
		D.end_timeline(true)


func _sitio(r) -> void:
	var h := RC.pos_hito()
	var trapo = r.find_child("TrapoCobijo", true, false)
	if trapo == null or Vector2(trapo.global_position.x - h.x, trapo.global_position.z - h.z).length() > 0.6:
		_fallo("2: el trapo azul de paisaje.gd no está en el palo del hito (%s)" % [trapo.global_position if trapo != null else "sin trapo"])
	if T.prohibido(RC.HITO.x, RC.HITO.y) or T.en_camino(RC.HITO.x, RC.HITO.y):
		_fallo("2: el hito está en arena prohibida o en el camino")
	if RC.HITO.distance_to(T.COBIJO) < T.RADIO_COBIJO + RC.RADIO:
		_fallo("2: el botón del hito pisa el cobijo")
	for pz in r._piezas_al_alcance():
		if pz[0] == "rin_hito":
			continue
		var d: float = Vector2(pz[1].x - RC.HITO.x, pz[1].z - RC.HITO.y).length()
		if d < float(pz[2]) + RC.RADIO:
			_fallo("2: el botón del hito pisa el de «%s» (a %.1f m)" % [pz[0], d])
	var B = load("res://buscador.gd")
	for x in B.hallazgos(r.REGION_BUSCADOR, r.SEMILLA):
		if (x["pos"] as Vector2).distance_to(RC.HITO) < 1.5:
			_fallo("2: el buscador entierra «%s» encima del hito (a %.1f m)" % [x["id"], (x["pos"] as Vector2).distance_to(RC.HITO)])
	# se ve desde el cobijo y desde la boca del cañón (la cámara de la región, que mira al norte)
	for desde in [T.COBIJO, Vector2(24.0, 55.0), Vector2(27.0, 50.0)]:
		_poner(r, desde.x, desde.y)
		await _esperar(30)
		var arriba: Vector3 = h + Vector3(0, RC.ALTO_LAJAS + 1.2, 0)
		if not r.cam.is_position_in_frustum(arriba):
			_fallo("2: desde %s el hito no sale en pantalla" % desde)
		else:
			var px: Vector2 = r.cam.unproject_position(arriba)
			print("SITIO: desde %s el hito sale en pantalla en %s" % [desde, px])


func _oido(r) -> void:
	var antes: int = r.rincones.tintineos
	_poner(r, 60.0, 90.0)                           # lejos (más de 42 m): calla
	await _esperar(30 * 12)
	if r.rincones.tintineos != antes:
		_fallo("3: el vidrio suena desde %.0f m" % Vector2(60.0 - RC.HITO.x, 90.0 - RC.HITO.y).length())
	var c0: int = int(S.contador.get(RC.SONIDO, 0)) if S != null else 0
	_poner(r, RC.HITO.x + 6.0, RC.HITO.y + 14.0)    # a unos 15 m: suena (y destella)
	var visto_brillo := [false]
	if not await _hasta(func():
			visto_brillo[0] = visto_brillo[0] or r.rincones.destello.visible
			return r.rincones.tintineos > antes, 12.0):
		_fallo("3: a 15 m del hito el vidrio no suena")
	await _esperar(3)
	visto_brillo[0] = visto_brillo[0] or r.rincones.destello.visible
	if not visto_brillo[0]:
		_fallo("3: al sonar, el vidrio no destella")
	if S != null:
		var sono: int = int(S.contador.get(RC.SONIDO, 0)) - c0
		var con_pos := false
		for e in S.registro:
			if e[1] == RC.SONIDO and e[4] is Vector3:
				con_pos = (e[4] as Vector3).distance_to(RC.pos_hito()) < 2.5
		print("OÍDO: «%s» sonó %d vez/veces; con posición en el hito: %s; descartes %s" % [RC.SONIDO, sono, con_pos,
			S.descartes.keys().filter(func(k): return k.begins_with(RC.SONIDO))])
		if sono < 1 and S.descartes.get(RC.SONIDO + ":sin_archivo", 0) > 0:
			_fallo("3: falta el archivo de «%s»" % RC.SONIDO)
		elif sono >= 1 and not con_pos:
			_fallo("3: el vidrio no suena desde el hito")
	# a 35 m, en calma no se oye; con tormenta sí, y más a menudo
	_poner(r, RC.HITO.x + 20.0, RC.HITO.y + 28.0)
	var lejos := Vector2(20.0, 28.0).length()
	await _esperar(30 * 12)
	var calma: int = r.rincones.tintineos
	await _esperar(30 * 12)
	if r.rincones.tintineos != calma:
		_fallo("3: en calma, el vidrio se oye a %.0f m" % lejos)
	r.clima.empezar_tormenta(false)
	var t0: int = r.rincones.tintineos
	await _esperar(30 * 14)
	var en_tormenta: int = r.rincones.tintineos - t0
	if en_tormenta < 3:
		_fallo("3: con tormenta, a %.0f m, el vidrio suena %d veces en 14 s (se esperan 3 o más)" % [lejos, en_tormenta])
	print("OÍDO: a %.0f m, en calma 0 veces en 12 s; con tormenta %d en 14 s" % [lejos, en_tormenta])
	r.clima._amainar()
	r.clima.fuerza = 0.0
	await _esperar(10)


# ================================================================= 4. con Lya y Garon

func _grupo() -> void:
	_limpiar()
	var r = await _entrar(["Kael", "Lya", "Garon"])
	if r == null:
		return
	await _sitio(r)
	await _oido(r)
	if RC.visto():
		_fallo("4: una partida nueva trae el hito visto")
	await _ir_al_hito(r)
	if r.cerca != "rin_hito" or not r.boton_accion.visible or r.boton_accion.text != RC.BOTON:
		_fallo("4: junto al hito no sale «%s» (cerca «%s», botón «%s», visible %s)" % [RC.BOTON, r.cerca, r.boton_accion.text, r.boton_accion.visible])
	var pociones: int = Inv.cantidad("Poción")
	var oro: int = Inv.oro()
	eventos.clear()
	r._accion()
	if D != null:
		if not await _hasta(func(): return D.current_timeline != null, 5.0):
			_fallo("4: «Mirar el hito» no abre el diálogo")
		else:
			if not D.current_timeline.resource_path.ends_with("/mc_rin_hito.dtl"):
				_fallo("4: con el grupo se abre «%s»" % D.current_timeline.resource_path)
			if Inv.cantidad("Poción") != pociones or RC.visto():
				_fallo("4: el premio llega antes de acabar el diálogo")
			await _recorrer()
			for e in eventos:
				if not e[0] in VARIANTES[""]:
					_fallo("4: en el hito habla «%s»: %s" % [e[0], e[1]])
			if eventos.size() != FRASES[""]:
				_fallo("4: el diálogo enseña %d frases (%d en el archivo)" % [eventos.size(), FRASES[""]])
			print("GRUPO: %d frases con Dialogic: %s" % [eventos.size(), eventos.map(func(e): return e[0])])
	await _esperar(10)
	if not RC.visto() or Inv.cantidad("Poción") != pociones + RC.POCIONES or Inv.oro() != oro:
		_fallo("4: tras el diálogo, hito %s, Pociones %d → %d, oro %d → %d" % [RC.visto(), pociones, Inv.cantidad("Poción"), oro, Inv.oro()])
	if r.aviso.text != RC.TEXTOS["premio"]:
		_fallo("4: el aviso del premio dice «%s»" % r.aviso.text)
	for h in HITOS_MISION + P.HITOS_NAIRA:
		if P.hito(h):
			_fallo("4: el rincón pone el hito «%s»" % h)
	var d = P.leer(ARCHIVO)
	if d == null or not d.get("hitos", {}).get(RC.HITO_ID, false):
		_fallo("4: la partida guardada no lleva «%s»" % RC.HITO_ID)
	elif int(d.get("inventario", {}).get("objetos", {}).get("Poción", 0)) != pociones + RC.POCIONES:
		_fallo("4: la partida guardada no lleva las Pociones del hito")
	# otra vez: solo el aviso, sin diálogo ni premio (y aunque el diálogo se diera por terminado otra vez)
	await _esperar(40)
	await _ir_al_hito(r)
	r._accion()
	await _esperar(10)
	if D != null and D.current_timeline != null:
		_fallo("4: la segunda vez vuelve a abrir el diálogo")
		D.end_timeline(true)
	if r.aviso.text != RC.TEXTOS["visto"]:
		_fallo("4: la segunda vez el aviso dice «%s»" % r.aviso.text)
	r.rincones.premio(r)
	r.rincones.dialogo_terminado(r, "mc_rin_hito")
	if Inv.cantidad("Poción") != pociones + RC.POCIONES:
		_fallo("4: el premio se repite (%d Pociones)" % Inv.cantidad("Poción"))
	print("GRUPO: premio una vez (+%d Pociones), guardado, y la segunda vez solo «%s»" % [RC.POCIONES, RC.TEXTOS["visto"]])


# ================================================================= 5. recarga

func _recarga() -> void:
	var d = P.leer(ARCHIVO)
	if d == null:
		_fallo("5: no hay partida guardada que cargar")
		return
	_limpiar()
	P.restaurar(d)
	var pociones: int = Inv.cantidad("Poción")
	var r = await _entrar(["Kael", "Lya", "Garon"])
	if r == null:
		return
	if not RC.visto():
		_fallo("5: tras cargar, falta «%s»" % RC.HITO_ID)
	await _ir_al_hito(r)
	r._accion()
	await _esperar(10)
	if (D != null and D.current_timeline != null) or Inv.cantidad("Poción") != pociones:
		_fallo("5: tras cargar, el hito vuelve a dar premio o diálogo")
		if D != null and D.current_timeline != null:
			D.end_timeline(true)
	print("RECARGA: el hito sigue visto y sin premio nuevo")


# ================================================================= 6. variantes por grupo

func _variantes() -> void:
	for caso in [[["Kael", "Lya"], "_lya"], [["Kael"], "_solo"]]:
		_limpiar()
		_borrar_archivo()
		var r = await _entrar(caso[0])
		if r == null:
			return
		await _ir_al_hito(r)
		var pociones: int = Inv.cantidad("Poción")
		eventos.clear()
		r._accion()
		if D != null:
			if not await _hasta(func(): return D.current_timeline != null, 5.0):
				_fallo("6: %s: no se abre el diálogo" % caso[1])
				continue
			if not D.current_timeline.resource_path.ends_with("/mc_rin_hito%s.dtl" % caso[1]):
				_fallo("6: con %s se abre «%s»" % [caso[0], D.current_timeline.resource_path])
			if caso[1] == "_lya":
				await _recorrer()
				if eventos.size() != FRASES["_lya"]:
					_fallo("6: _lya enseña %d frases" % eventos.size())
				for e in eventos:
					if e[0] == "garon":
						_fallo("6: sin Garon, Garon habla: %s" % e[1])
			else:
				await _esperar(60)                      # (con los retratos ya puestos: cortar en su entrada da errores de Dialogic)
				# y con la frase ya escrita: si se corta mientras Dialogic la escribe, al acabarla mira un
				# evento que ya no existe (is_question con índice -1); la prueba fallaba 1 de cada 3 veces
				await _hasta(func(): return D.current_state == D.States.IDLE, 5.0)
				D.end_timeline(true)                    # cortado a medias: el premio igual
		await _esperar(10)
		if not RC.visto() or Inv.cantidad("Poción") != pociones + RC.POCIONES:
			_fallo("6: %s: hito %s, Pociones %d → %d" % [caso[1], RC.visto(), pociones, Inv.cantidad("Poción")])
		r.rincones.premio(r)
		if Inv.cantidad("Poción") != pociones + RC.POCIONES:
			_fallo("6: %s: el premio se repite" % caso[1])
		print("VARIANTE %s: %s, premio una vez" % [caso[1], "recorrida" if caso[1] == "_lya" else "cortada"])


# ================================================================= 7. partida antigua

func _partida_antigua() -> void:
	_limpiar()
	_borrar_archivo()
	var hitos := {"pv_02": true, "pv_03": true, "pv_05": true, "mc_inicio": true, "mc_caravana": true}
	P.restaurar({"grupo_activo": ["Kael", "Lya", "Garon"], "escena_guardada": REGION, "hitos": hitos.duplicate(),
		"buscador": {"nivel": 1, "tiene": true}, "formato": 2})
	if RC.visto():
		_fallo("7: una partida antigua trae el hito")
	var r = await _entrar(["Kael", "Lya", "Garon"])
	if r == null:
		return
	await _ir_al_hito(r)
	if r.cerca != "rin_hito":
		_fallo("7: en una partida antigua el hito no se puede mirar (cerca «%s»)" % r.cerca)
	r._accion()
	if D != null:
		await _hasta(func(): return D.current_timeline != null, 5.0)
		if D.current_timeline != null:
			await _esperar(60)
			D.end_timeline(true)
	await _esperar(10)
	var ahora: Dictionary = Engine.get_meta("hitos", {})
	for h in ahora:
		if ahora[h] and not hitos.has(h) and h != RC.HITO_ID:
			_fallo("7: aparece el hito «%s»" % h)
	if not RC.visto() or P.hito("mc_sello"):
		_fallo("7: en una partida antigua el rincón no se completa o toca la misión")
	print("ANTIGUA: carga, el hito está por descubrir y la misión sigue en mc_caravana")


# ================================================================= 8. perfil bajo

func _bajo() -> void:
	_limpiar()
	var r = await _entrar(["Kael", "Lya", "Garon"], "bajo")
	if r == null:
		return
	await _ir_al_hito(r)
	if r.cerca != "rin_hito" or not r.boton_accion.visible:
		_fallo("8: en el perfil bajo no sale el botón del hito")
	print("BAJO: rincón montado (perfil %s) y botón «%s»" % [r.nombre_perfil, r.boton_accion.text])
