extends SceneTree
# Prueba de los rincones de Pastos Verdes 3D (12/11, narrativa y exploración: zonas3d/pastos_rincones.gd, textos en
# dialogos/notas/pastos_rincones.gd y dialogos/pastos/rincon_nido.dtl). Con «-- 3d sin_prologo». La región guarda de
# verdad, pero en el archivo propio de la prueba (Engine «archivo_partida_prueba»): no toca ninguna partida real.
#   1. Textos: cada comentario en dos líneas de su caja (70 letras como mucho), con gesto, espera e intención de la
#      lista; avisos en dos líneas; el diálogo del nido, solo Kael y Garon y frases de 110 letras como mucho; nada de
#      Érebo, corazones, recuerdos ni otras sagas.
#   2. Sitios: el montón, el pie del nido y las bandadas, fuera del camino y de lo prohibido, lejos de lo que ya se
#      examina (Tilo, estela, cofre, lavanda, notas, el bosque), del centinela y de las salidas; el nido, en su árbol y
#      a la altura de una rama.
#   3. Kael solo: dejar una piedra (hito, piedra arriba, aviso, comentario de Kael; la segunda vez, nada nuevo); el nido
#      sin Garon (no llega, sin premio); asomarse en el puente (comentario de Kael, una vez).
#   4. Pájaros: la bandada sale volando al acercarse Kael, se pierde, y vuelve a posarse cuando Kael se aleja.
#   5. La partida guardada lleva los hitos nuevos; al volver a entrar, la piedra sigue arriba.
#   6. Con Lya y Garon: el diálogo del nido recorrido con Dialogic (abierto por su ruta), el premio una sola vez
#      (25 monedas y una moneda antigua), el comentario de Lya, y el puente con su charla de grupo.
#   7. Partida antigua (sin estos hitos): carga, el nido brilla y la piedra no está.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ARCHIVO := "user://prueba_rincones_pastos.save"
const T := preload("res://dialogos/notas/pastos_rincones.gd")
const C := preload("res://dialogos/comentarios.gd")
var BQ                                            # zonas3d/bosque_pastos.gd (con load: usa Sonido, que no existe al compilar la prueba)
const NP := preload("res://dialogos/notas/pastos_verdes.gd")
const GESTOS := ["", "ligero", "firme", "duda", "sorpresa", "decidido", "brazalete", "inquieta", "preocupada", "decidida"]
const ESPERAS := {"Kael": ["espera_vigilar", "espera_empunadura", "espera_brazalete", "espera_impaciencia"],
	"Lya": ["espera_flor", "espera_cetro", "espera_pelo"],
	"Garon": ["espera_hombros", "espera_espalda", "espera_apoyarse"]}
const PROHIBIDAS := ["érebo", "erebo", "corazón", "corazon", "recuerdo", "memoria", "tidus", "yuna", "spira", "sinh",
	"final fantasy"]
const HITOS := ["rin_piedra", "rin_nido", "rin_puente_solo", "rin_puente_lya", "rin_puente_grupo"]
const MISION := ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo"]

var P
var R
var D
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


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta(C.META, {})


func _borrar_archivo() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _probar() -> void:
	P = load("res://progreso.gd")
	BQ = load("res://zonas3d/bosque_pastos.gd")
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	if not load("res://modo3d.gd").activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		quit(1)
		return
	if D != null:
		D.event_handled.connect(func(ev):
			if ev is DialogicTextEvent:
				eventos.append([ev.character.get_identifier() if ev.character != null else "", ev.text]))
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar_archivo()
	await _textos()
	await _kael_solo()
	await _con_el_grupo()
	await _partida_antigua()
	_borrar_archivo()
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= 1. textos

func _textos() -> void:
	var capa := CanvasLayer.new()
	root.add_child(capa)
	var total := 0
	for m in T.COMENTARIOS:
		for v in T.COMENTARIOS[m]:
			var f: Dictionary = T.COMENTARIOS[m][v]
			var todas: Array = [f]
			if f.has("respuesta"):
				todas.append(f["respuesta"])
			var presentes: Array = {"solo": ["Kael"], "lya": ["Kael", "Lya"], "grupo": ["Kael", "Lya", "Garon"]}[v]
			for x in todas:
				total += 1
				var t: String = x["texto"]
				if not x["quien"] in presentes:
					_fallo("1: en «%s/%s» habla %s, que no está" % [m, v, x["quien"]])
				if t.length() > 70:
					_fallo("1: %d letras: %s" % [t.length(), t])
				_prohibidas(t)
				if not x.get("gesto", "") in GESTOS:
					_fallo("1: gesto «%s» en «%s»" % [x.get("gesto"), t])
				if x.get("espera", "") == "" or not x["espera"] in ESPERAS.get(x["quien"], []):
					_fallo("1: espera «%s» no es de %s" % [x.get("espera"), x["quien"]])
				if x.get("intencion", "") == "":
					_fallo("1: «%s» sin intención" % t)
				var caja := C._caja(x)
				capa.add_child(caja)
				await _esperar(2)
				var lineas: int = caja.get_node("lineas/frase").get_line_count()
				if lineas > 2:
					_fallo("1: «%s» ocupa %d líneas" % [t, lineas])
				print("FRASE %s/%s %s | %d letras | %d línea(s) | %s" % [m, v, x["quien"], t.length(), lineas, t])
				caja.free()
	capa.free()
	var aviso := Label.new()                       # como el aviso de la región (1000 px, letra de 30)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 100)
	aviso.add_theme_font_size_override("font_size", 30)
	root.add_child(aviso)
	for k in T.TEXTOS:
		var t: String = T.TEXTOS[k]
		aviso.text = t % T.NIDO_MONEDAS if "%d" in t else t
		_prohibidas(t)
		await _esperar(2)
		if aviso.get_line_count() > 2:
			_fallo("1: el aviso «%s» ocupa %d líneas" % [k, aviso.get_line_count()])
		print("AVISO %s | %d línea(s) | %s" % [k, aviso.get_line_count(), aviso.text])
	aviso.free()
	for k in T.BOTONES:
		if T.BOTONES[k].length() > 16:
			_fallo("1: el botón «%s» es largo para el móvil" % T.BOTONES[k])
	var dtl := FileAccess.get_file_as_string(T.DIALOGO_NIDO)
	if dtl == "":
		_fallo("1: falta %s" % T.DIALOGO_NIDO)
	var re := RegEx.create_from_string("^(\\w+): (.*)$")
	var frases := 0
	for l in dtl.split("\n"):
		var mm := re.search(l.strip_edges())
		if mm == null:
			continue
		frases += 1
		if not mm.get_string(1) in ["kael", "garon"]:
			_fallo("1: en el nido habla «%s»" % mm.get_string(1))
		if mm.get_string(2).length() > 110:
			_fallo("1: frase larga en el nido: %s" % mm.get_string(2))
		_prohibidas(mm.get_string(2))
	if frases < 2 or frases > 6:
		_fallo("1: el diálogo del nido tiene %d frases (de 2 a 6)" % frases)
	print("TEXTOS: %d frases de comentario, %d del nido" % [total, frases])


func _prohibidas(t: String) -> void:
	for p in PROHIBIDAS:
		if RegEx.create_from_string("(?i)\\b%s\\b" % p).search(t) != null:
			_fallo("1: «%s» dice «%s»" % [t, p])


# ================================================================= región

func _entrar(hitos: Array, grupo: Array) -> Object:
	for h in hitos:
		P.poner_hito(h)
	if "pv_06" in hitos:
		Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	Engine.set_meta("grupo_activo", grupo)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION \
			and current_scene.get("kael") != null and not R.cambiando, 120.0):
		_fallo("no se abre Pastos Verdes 3D")
		return null
	var r = current_scene
	if not await _hasta(func(): return r.rincones != null and r.rincones.puntos.size() == 3 and r.rincones.bandadas.size() == 3, 10.0):
		_fallo("la región no crea los rincones (3 puntos y 3 bandadas)")
		return null
	await _esperar(10)
	return r


# El suelo bajo «p»: en el puente, su tablero (lo primero que choca al bajar desde arriba); fuera, el terreno (allí el
# rayo podría dar en una copa, que choca para que la cámara la vea).
func _suelo(r, p: Vector3) -> Vector3:
	if absf(p.x - r.RIO_X) > 4.5:
		return Vector3(p.x, r.altura(p.x, p.z), p.z)
	var e: PhysicsDirectSpaceState3D = r.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 30.0, p.z), Vector3(p.x, -30.0, p.z))
	if r.kael is CollisionObject3D:
		q.exclude = [r.kael.get_rid()]
	var h := e.intersect_ray(q)
	return h["position"] if not h.is_empty() else Vector3(p.x, r.altura(p.x, p.z), p.z)


# Pone a Kael junto a «p» (del lado de la cámara) y mira qué botón sale.
func _ir(r, p: Vector3, lado := Vector3(0, 0, 0.9)) -> void:
	r._colocar_kael(_suelo(r, p + lado))
	r._ultima = r.kael.global_position
	await _esperar(4)
	r._comprobar_cerca()


func _comentario(r) -> Dictionary:
	if r._capa_ui == null:
		return {}
	for n in r._capa_ui.get_children():
		if n.name.begins_with("comentario") and not n.is_queued_for_deletion():
			return {"quien": n.get_meta("quien"), "texto": n.get_meta("texto")}
	return {}


func _espera_comentario(r, texto: String, que: String) -> void:
	if not await _hasta(func(): return _comentario(r).get("texto", "") == texto, 5.0):
		_fallo("%s: no sale el comentario «%s» (sale %s)" % [que, texto, _comentario(r)])
	else:
		print("COMENTARIO %s: %s" % [que, texto])
	r._quitar_comentarios()
	await _esperar(2)


# ================================================================= 2-5. Kael solo

func _kael_solo() -> void:
	_limpiar()
	var r = await _entrar(["pv_02"], ["Kael"])
	if r == null:
		return
	var rc = r.rincones
	_sitios(r, rc)
	# 3a. el montón
	await _ir(r, rc.monton.global_position, Vector3(0.3, 0, 1.15))
	if r.cerca != "rin:piedra" or r.boton_accion.text != T.BOTONES["piedra"] or not r.boton_accion.visible:
		_fallo("3: junto al montón no sale «%s» (cerca «%s», botón «%s»)" % [T.BOTONES["piedra"], r.cerca, r.boton_accion.text])
	r._accion()
	await _esperar(6)
	if not P.hito("rin_piedra") or rc.piedra_tuya == null:
		_fallo("3: dejar la piedra no pone el hito o no se ve la piedra")
	if r.aviso.text != T.TEXTOS["piedra_dejar"]:
		_fallo("3: al dejar la piedra sale «%s»" % r.aviso.text)
	await _espera_comentario(r, T.COMENTARIOS["piedra"]["solo"]["texto"], "3 montón solo")
	r._comprobar_cerca()
	if r.boton_accion.text != T.BOTONES["piedra_ya"]:
		_fallo("3: tras dejarla, el botón dice «%s»" % r.boton_accion.text)
	var piedras: int = rc.monton.get_child_count()
	r._bloqueo_accion = 0.0
	r._accion()
	await _esperar(6)
	if r.aviso.text != T.TEXTOS["piedra_ya"] or rc.monton.get_child_count() != piedras:
		_fallo("3: la segunda vez cambia algo (aviso «%s»)" % r.aviso.text)
	# 3b. el nido sin Garon
	var oro: int = load("res://inventario.gd").oro()
	await _ir(r, rc.puntos[1]["nodo"].global_position, Vector3(0, 0, 0.3))
	if r.cerca != "rin:nido" or r.boton_accion.text != T.BOTONES["nido"]:
		_fallo("3: al pie del árbol no sale «%s» (cerca «%s»)" % [T.BOTONES["nido"], r.cerca])
	r._accion()
	await _esperar(6)
	if P.hito("rin_nido") or load("res://inventario.gd").oro() != oro or rc.ocupado():
		_fallo("3: sin Garon, Kael sube al nido o recibe algo")
	if r.aviso.text != T.TEXTOS["nido_lejos"]:
		_fallo("3: sin Garon, el nido dice «%s»" % r.aviso.text)
	if D != null and D.current_timeline != null:
		_fallo("3: sin Garon se abre el diálogo del nido")
	await _espera_comentario(r, T.COMENTARIOS["nido_lejos"]["solo"]["texto"], "3 nido solo")
	# 3c. el puente
	await _ir(r, r.rincones.PUENTE, Vector3(0.3, 0, 0.2))
	if r.cerca != "rin:puente" or r.boton_accion.text != T.BOTONES["puente"]:
		_fallo("3: en el centro del puente no sale «%s» (cerca «%s», Kael en %s)" % [T.BOTONES["puente"], r.cerca, r.kael.global_position])
	r._accion()
	await _esperar(4)
	if not P.hito("rin_puente_solo"):
		_fallo("3: asomarse no pone «rin_puente_solo»")
	await _espera_comentario(r, T.COMENTARIOS["puente"]["solo"]["texto"], "3 puente solo")
	r._comprobar_cerca()
	if r.cerca == "rin:puente":
		_fallo("3: tras asomarse, el botón del puente sigue")
	# 4. pájaros
	await _pajaros(r, rc)
	# 5. la partida guardada
	var d = P.leer(ARCHIVO)
	if d == null:
		_fallo("5: no se ha guardado la partida de la prueba")
	else:
		var h: Dictionary = d.get("hitos", {})
		for x in ["rin_piedra", "rin_puente_solo"]:
			if not h.get(x, false):
				_fallo("5: la partida guardada no lleva «%s»" % x)
		if h.get("rin_nido", false):
			_fallo("5: la partida guardada lleva el nido sin haber subido")
		print("GUARDADA: ", h)


func _sitios(r, rc) -> void:
	var otros := {"Tilo": r.tilo.global_position, "la estela": r.estela.global_position, "el cofre": r.cofre.global_position,
		"la lavanda": r.LAVANDA_CERCA, "el centinela": r.CENTINELA}
	for n in NP.NOTAS:
		otros[n["id"]] = n["cerca"]
	var sitios_bq := {"SITIO_ARBOL": BQ.SITIO_ARBOL, "SITIO_LIRIOS": BQ.SITIO_LIRIOS, "SITIO_SURCOS": BQ.SITIO_SURCOS,
		"SITIO_RAMAS": BQ.SITIO_RAMAS, "SITIO_RUINAS": BQ.SITIO_RUINAS, "SITIO_MANANTIAL": BQ.SITIO_MANANTIAL,
		"SITIO_COFRE": BQ.SITIO_COFRE, "SITIO_CLARO": BQ.SITIO_CLARO, "SITIO_ORBE": BQ.SITIO_ORBE, "SITIO_PERRO": BQ.SITIO_PERRO}
	for k in sitios_bq:
		otros["bosque " + k] = sitios_bq[k]
	for rec in BQ.RECOLECCION:
		otros[rec[0]] = rec[2]
	for i in BQ.SITIOS_HUELLAS.size():
		otros["huellas %d" % i] = BQ.SITIOS_HUELLAS[i]
	for i in r.salidas.size():
		otros["salida %d" % i] = r.salidas[i]["pos"]
	var mios := {"montón": rc.monton.global_position, "pie del nido": rc.puntos[1]["nodo"].global_position}
	for b in rc.bandadas:
		mios["bandada %s" % b["centro"]] = b["centro"]
	for m in mios:
		var p: Vector3 = mios[m]
		if r._prohibido(p):
			_fallo("2: %s está en zona prohibida (%s)" % [m, p])
		var ds: float = r._dist_sendero(p)
		if ds < 1.5:
			_fallo("2: %s está en el camino (%.1f m)" % [m, ds])
		for k in otros:
			var lejos: float = 4.0 if k == "el centinela" else (3.0 if k.begins_with("salida") else r.RADIO_ACCION + 0.5)
			if r._dist_plana(p, otros[k]) < lejos:
				_fallo("2: %s está pegado a %s (%.1f m)" % [m, k, r._dist_plana(p, otros[k])])
		print("SITIO %s: %s, a %.1f m del camino" % [m, p, ds])
	if rc.arbol_seco == null or r._dist_plana(rc.arbol_seco.global_position, rc.SITIO_NIDO) > 3.0:
		_fallo("2: el árbol seco del nido no está cerca de su sitio %s" % rc.SITIO_NIDO)
	var alto: float = rc.nido.global_position.y - r.altura(rc.nido.global_position.x, rc.nido.global_position.z)
	if alto < 1.5 or alto > 3.2:
		_fallo("2: el nido está a %.1f m del suelo" % alto)
	if rc.brillo_nido == null:
		_fallo("2: el nido no brilla antes de subir")
	if r._dist_plana(rc.puntos[1]["nodo"].global_position, rc.nido.global_position) > 1.6:
		_fallo("2: el botón del nido queda lejos del nido")


func _pajaros(r, rc) -> void:
	var b: Dictionary = rc.bandadas[0]
	if b["estado"] != "posadas" or not b["mmi"].visible:
		_fallo("4: la bandada no empieza posada")
	var antes: int = rc.aves_asustadas
	await _ir(r, b["centro"], Vector3(2.0, 0, 1.6))
	if not await _hasta(func(): return b["estado"] == "vuelo", 2.0):
		_fallo("4: la bandada no sale volando con Kael a 2,6 m")
		return
	if rc.aves_asustadas != antes + 1:
		_fallo("4: se cuentan %d sustos" % (rc.aves_asustadas - antes))
	await _esperar(30)
	var alto: float = b["aves"][0]["pos"].y - b["aves"][0]["base"].y
	if alto < 0.5:
		_fallo("4: al segundo de volar, el primer pájaro solo ha subido %.2f m" % alto)
	if not await _hasta(func(): return b["estado"] == "fuera" and not b["mmi"].visible, 5.0):
		_fallo("4: la bandada no se pierde de vista")
	await _esperar(30 * 5)
	if b["estado"] != "fuera":
		_fallo("4: con Kael cerca, la bandada vuelve antes de tiempo")
	await _ir(r, b["centro"], Vector3(0, 0, 12.0))     # lejos (al sur, en el camino; no hacia PV-03)
	if not await _hasta(func(): return b["estado"] == "posadas" and b["mmi"].visible, rc.VUELTA + rc.BAJADA + 5.0):
		_fallo("4: la bandada no vuelve a posarse (estado «%s»)" % b["estado"])
	else:
		print("PÁJAROS: salen volando, suben %.1f m, se van y vuelven a posarse" % alto)


# ================================================================= 6. con Lya y Garon

func _con_el_grupo() -> void:
	var d = P.leer(ARCHIVO)
	if d == null:
		return
	_limpiar()
	P.restaurar(d)
	var r = await _entrar(MISION, ["Kael", "Lya", "Garon"])
	if r == null:
		return
	var rc = r.rincones
	if rc.piedra_tuya == null or r._dist_plana(rc.piedra_tuya.global_position, rc.monton.global_position) > 0.2:
		_fallo("5: al volver a entrar, la piedra de Kael no está en el montón")
	if not P.hito("rin_piedra"):
		_fallo("5: tras cargar, falta «rin_piedra»")
	_sitios(r, rc)                                  # con la misión hecha, también el bosque está
	var Inv = load("res://inventario.gd")
	var oro: int = Inv.oro()
	var monedas_antiguas: int = Inv.cantidad(T.NIDO_OBJETO)
	await _ir(r, rc.puntos[1]["nodo"].global_position, Vector3(0, 0, 0.3))
	if r.cerca != "rin:nido":
		_fallo("6: con Garon, al pie del árbol no sale el nido (cerca «%s»)" % r.cerca)
	eventos.clear()
	r._accion()
	if D != null:
		if not await _hasta(func(): return D.current_timeline != null, 5.0):
			_fallo("6: con Garon no se abre el diálogo del nido")
		elif D.current_timeline.resource_path != T.DIALOGO_NIDO:
			_fallo("6: se abre otro diálogo: %s" % D.current_timeline.resource_path)
		var limite := Time.get_ticks_msec() + 20000
		var ultimo := 0
		while D.current_timeline != null and Time.get_ticks_msec() < limite:
			await process_frame
			var fr := Engine.get_process_frames()
			if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and fr - ultimo >= 4:
				D.Inputs.handle_input()
				ultimo = fr
		if D.current_timeline != null:
			_fallo("6: el diálogo del nido no termina")
			D.end_timeline(true)
		for e in eventos:
			if not e[0] in ["kael", "garon"]:
				_fallo("6: en el nido habla «%s»: %s" % [e[0], e[1]])
		if eventos.size() != 6:
			_fallo("6: el nido enseña %d frases (6 en el archivo)" % eventos.size())
		print("NIDO: %d frases con Dialogic" % eventos.size())
	if not await _hasta(func(): return P.hito("rin_nido") and not rc.ocupado(), 6.0):
		_fallo("6: tras el diálogo, Kael no sube al nido")
		return
	await _esperar(4)
	if Inv.oro() != oro + T.NIDO_MONEDAS or Inv.cantidad(T.NIDO_OBJETO) != monedas_antiguas + 1:
		_fallo("6: el nido da %d monedas y %d «%s»" % [Inv.oro() - oro, Inv.cantidad(T.NIDO_OBJETO) - monedas_antiguas, T.NIDO_OBJETO])
	if r.aviso.text != T.TEXTOS["nido_premio"] % T.NIDO_MONEDAS:
		_fallo("6: el aviso del nido dice «%s»" % r.aviso.text)
	if rc.brillo_nido != null:
		_fallo("6: el nido sigue brillando vacío")
	await _espera_comentario(r, T.COMENTARIOS["nido_premio"]["grupo"]["texto"], "6 nido con Lya")
	r._comprobar_cerca()
	if r.cerca == "rin:nido":
		_fallo("6: tras subir, el botón del nido sigue")
	rc.accion("nido")                                # pulsado otra vez (a mano): nada nuevo
	rc._subir_al_nido()
	await _esperar(40)
	if Inv.oro() != oro + T.NIDO_MONEDAS or Inv.cantidad(T.NIDO_OBJETO) != monedas_antiguas + 1:
		_fallo("6: el premio del nido se repite")
	# el puente: la charla del grupo, aunque ya se asomara Kael solo
	await _ir(r, rc.PUENTE, Vector3(0.3, 0, 0.2))
	if r.cerca != "rin:puente":
		_fallo("6: con el grupo, el puente no ofrece asomarse (cerca «%s»)" % r.cerca)
	r._accion()
	await _esperar(4)
	if not P.hito("rin_puente_grupo") or P.hito("rin_puente_lya"):
		_fallo("6: asomarse con el grupo pone otros hitos")
	await _espera_comentario(r, T.COMENTARIOS["puente"]["grupo"]["texto"], "6 puente grupo")
	var d2 = P.leer(ARCHIVO)
	if d2 == null or not d2.get("hitos", {}).get("rin_nido", false) or not d2.get("hitos", {}).get("rin_puente_grupo", false):
		_fallo("6: la partida guardada no lleva el nido y el puente del grupo")
	elif int(d2.get("inventario", {}).get("objetos", {}).get(T.NIDO_OBJETO, 0)) != monedas_antiguas + 1:
		_fallo("6: la partida guardada no lleva la moneda antigua del nido")


# ================================================================= 7. partida antigua

func _partida_antigua() -> void:
	_limpiar()
	P.restaurar({"grupo_activo": ["Kael", "Lya", "Garon"], "escena_guardada": "res://mapa.tscn",
		"hitos": {"pv_02": true, "pv_03": true, "pv_05": true}})
	for h in HITOS:
		if P.hito(h):
			_fallo("7: una partida antigua trae «%s»" % h)
	var r = await _entrar([], ["Kael", "Lya", "Garon"])
	if r == null:
		return
	var rc = r.rincones
	if rc.piedra_tuya != null or rc.brillo_nido == null:
		_fallo("7: en una partida antigua, la piedra ya está o el nido no brilla")
	if not rc.disponible("nido") or not rc.disponible("puente"):
		_fallo("7: en una partida antigua, el nido o el puente no están disponibles")
	print("ANTIGUA: carga con el montón sin piedra y el nido con su brillo")
