extends SceneTree
# AM-8 (19/11, CONVERSACIONES_19_11): conversaciones que recuerdan decisiones del jugador y rumores con las rutinas de
# Oakhaven. TODO ES PROPUESTA [P] (docs/v12/CONVERSACIONES_19_11.md). Con «-- 3d sin_prologo»; partida propia
# (user://prueba_conversaciones.save, en la carpeta aislada de la pasada).
#   1. Datos de los comentarios de decisión (dialogos/comentarios.gd, DECISIONES): entre 6 y 10, ids sin repetir, marcados
#      «p»; cada condición bien escrita y de una decisión que el juego de verdad guarda (la clave y el valor están en el
#      código que la escribe); habla un héroe; ≤ 70 letras y dos líneas en su caja; gestos y esperas de la lista; con su
#      intención; nada reservado (D-033 y lo del barrio: Érebo, corazón, recuerdo, memoria, olvido, niebla, Sello, tapiz,
#      corona, aldea, niño…) ni de otras sagas; cada valor de decisión tiene al menos un comentario.
#   2. Datos de los rumores (ciudades/oakhaven_vida.gd, voz_corrillo): marcados «p»; junto a una calle y a más de 7 m de
#      las demás voces; ≤ 48 letras y ≤ 620 px; franjas que existen; las de decisión, con una decisión real; las demás,
#      una afirmación del barrio que existe y es verdad (o un tema de rumor del barrio); nada reservado.
#   3. Cada comentario sale SOLO con su decisión (no sin ella ni con el otro valor), UNA SOLA VEZ (ni en la misma sesión,
#      ni en una sesión nueva, ni tras guardar y cargar), solo si está quien habla (la respuesta, solo si está quien
#      responde), antes que las frases del momento y solo en sus momentos (no en el cofre).
#   4. Los rumores: sin decisiones no sale ninguno de decisión; con cada una, el suyo en la tarde y el anochecer y no a la
#      mañana; las afirmaciones, cada una en su franja.
#   5. En la Oakhaven 3D por defecto (zonas3d/oakhaven_3d.tscn) con Gorthor perdonado: al llegar sale un comentario de
#      esa decisión; si un diálogo lo quita enseguida, no consta como dicho y, quietos, salen los dos (el quitado otra
#      vez); quedan apuntados en la partida; en una sesión nueva ya no salen (la llegada de siempre); junto al Pórtico
#      del Concejo, por la tarde, el corrillo cuenta lo de Gorthor; ni los hitos ni las decisiones cambian.
#   6. La llegada a la Oakhaven 3D: no con Kael sin haber salido aún (sin pv_02) ni dentro de la posada; sí en la calle.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const C := preload("res://dialogos/comentarios.gd")
const Oak := preload("res://ciudades/oakhaven.gd")
const Vida := preload("res://ciudades/oakhaven_vida.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const REGION := "res://zonas3d/oakhaven_3d.tscn"
const ARCHIVO := "user://prueba_conversaciones.save"
const HEROES := ["Kael", "Lya", "Garon"]
const GESTOS := ["", "ligero", "firme", "duda", "sorpresa", "decidido", "brazalete", "inquieta", "preocupada", "decidida"]
const ESPERAS := {"Kael": ["espera_vigilar", "espera_empunadura", "espera_brazalete", "espera_impaciencia"],
	"Lya": ["espera_flor", "espera_cetro", "espera_pelo"],
	"Garon": ["espera_hombros", "espera_espalda", "espera_apoyarse"]}
# Las decisiones que el juego guarda de verdad («decisiones»), con el archivo que las escribe y cómo aparece ahí cada valor.
const DECISIONES_REALES := {
	"gorthor": {"archivo": "res://combate.gd", "clave": "\"nombre\": \"Gorthor el Devorador\"",
		"valores": {"perdonado": "_apuntar_decision(f, \"perdonado\")", "muerto": "_apuntar_decision(f, \"muerto\")"}},
	"guardian_bosque": {"archivo": "res://combate.gd", "clave": "Bosque.apuntar(",
		"valores": {"purificado": "Bosque.apuntar(\"purificado\")", "derrotado": "Bosque.apuntar(\"derrotado\")"}},
	"hierro_ferro": {"archivo": "res://ciudades/oakhaven.gd", "clave": "dec[\"hierro_ferro\"] =",
		"valores": {"entregado": "\"entregado\" if s == \"oak:hierro_entregar\" else \"kael\"",
			"kael": "\"entregado\" if s == \"oak:hierro_entregar\" else \"kael\""}},
	"pip_oak": {"archivo": "res://ciudades/oakhaven.gd", "clave": "d[\"pip_oak\"] = \"pagado\"",
		"valores": {"pagado": "d[\"pip_oak\"] = \"pagado\""}},
}
# Lo reservado (sin tildes y en minúsculas, por SUBCADENA): el de prueba_barrio_datos más lo de prueba_comentarios.
const PROHIBIDO := ["erebo", "corazon", "recuerd", "record", "memoria", "olvid", "rocio", "cripta", "trampilla", "conclave",
	"crio", "hermano", "diecisiete", "alcantarilla", "niebla", "sello", "tapiz", "corona", "aldea", "tidus", "yuna",
	"spira", "sinh", "ladron"]
const PROHIBIDO_PALABRA := ["nino", "ninos", "nina", "ninas"]
const TEMAS_RUMOR := ["caravana", "camino", "peaje", "precio", "guardia", "ronda", "portes", "harina", "hilo"]
const LARGO_COMENTARIO := 70

var P
var G
var fallos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _probar() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	await _datos_comentarios()
	await _datos_rumores()
	_logica_comentarios()
	_logica_rumores()
	await _en_oakhaven_3d()
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	quit(1 if fallos.size() > 0 else 0)


static func _plano(t: String) -> String:
	var s := t.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		s = s.replace(par[0], par[1])
	return s


func _reservado(t: String, donde: String) -> void:
	var p := _plano(t)
	for x in PROHIBIDO:
		if x in p:
			_fallo("%s: «%s» dice «%s»" % [donde, t, x])
	for x in PROHIBIDO_PALABRA:
		if RegEx.create_from_string("\\b%s\\b" % x).search(p) != null:
			_fallo("%s: «%s» dice «%s»" % [donde, t, x])


# «decision:k=v» → [k, v] si es una decisión real (DECISIONES_REALES y está en su código); si no, falla.
func _decision_real(si: String, donde: String) -> Array:
	if Oak.error_condicion(si) != "":
		_fallo("%s: condición mal escrita: %s" % [donde, Oak.error_condicion(si)])
		return []
	if not si.begins_with("decision:") or not "=" in si:
		_fallo("%s: la condición «%s» no es una decisión" % [donde, si])
		return []
	var kv := si.trim_prefix("decision:")
	var k := kv.get_slice("=", 0)
	var v := kv.get_slice("=", 1)
	if not DECISIONES_REALES.has(k) or not DECISIONES_REALES[k]["valores"].has(v):
		_fallo("%s: «%s» no es una decisión que guarde el juego" % [donde, si])
		return []
	var real: Dictionary = DECISIONES_REALES[k]
	var codigo := FileAccess.get_file_as_string(real["archivo"])
	if not real["clave"] in codigo or not real["valores"][v] in codigo:
		_fallo("%s: %s ya no escribe «%s» (busco «%s» y «%s»)" % [donde, real["archivo"], si, real["clave"], real["valores"][v]])
	return [k, v]


# 1. Datos de los comentarios de decisión.
func _datos_comentarios() -> void:
	var n: int = C.DECISIONES.size()
	if n < 6 or n > 10:
		_fallo("1: hay %d comentarios de decisión (entre 6 y 10)" % n)
	var ids := {}
	var cubiertos := {}
	var capa := CanvasLayer.new()
	root.add_child(capa)
	for f in C.DECISIONES:
		var id: String = f.get("id", "")
		if id == "" or ids.has(id):
			_fallo("1: id vacío o repetido «%s»" % id)
		ids[id] = true
		if not f.get("p", false):
			_fallo("1: «%s» no va marcado como propuesta («p»)" % id)
		var kv := _decision_real(f.get("si", ""), "1: " + id)
		if not kv.is_empty():
			cubiertos["%s=%s" % kv] = true
		var todas: Array = [f]
		if f.has("respuesta"):
			todas.append(f["respuesta"])
		for x in todas:
			var t: String = x["texto"]
			if not x["quien"] in HEROES:
				_fallo("1: %s: habla «%s», que no es un héroe" % [id, x["quien"]])
			if t.length() > LARGO_COMENTARIO:
				_fallo("1: %s: %d letras (más de %d): %s" % [id, t.length(), LARGO_COMENTARIO, t])
			if not x.get("gesto", "") in GESTOS:
				_fallo("1: %s: gesto desconocido «%s»" % [id, x.get("gesto")])
			if x.get("espera", "") != "" and not x["espera"] in ESPERAS.get(x["quien"], []):
				_fallo("1: %s: la espera «%s» no es de %s" % [id, x["espera"], x["quien"]])
			if x.get("intencion", "") == "":
				_fallo("1: %s: «%s» no dice su intención" % [id, t])
			_reservado(t, "1: " + id)
			var caja := C._caja(x)
			capa.add_child(caja)
			await _esperar(2)
			var lineas: int = caja.get_node("lineas/frase").get_line_count()
			if lineas > 2:
				_fallo("1: %s: «%s» ocupa %d líneas en su caja" % [id, t, lineas])
			print("DECISION %s | %s | %s | %d letras | %d línea(s) | %s" % [id, f["si"], x["quien"], t.length(), lineas, t])
			caja.free()
	capa.free()
	for k in DECISIONES_REALES:
		for v in DECISIONES_REALES[k]["valores"]:
			if not cubiertos.has("%s=%s" % [k, v]):
				_fallo("1: la decisión %s=%s no tiene comentario" % [k, v])
	print("COMENTARIOS DE DECISION: %d (%d valores de decisión cubiertos)" % [n, cubiertos.size()])


# 2. Datos de los rumores del corrillo.
func _datos_rumores() -> void:
	var voz := {}
	for v in Vida.VOCES:
		if v["id"] == "voz_corrillo":
			voz = v
	if voz.is_empty():
		_fallo("2: no está la voz «voz_corrillo» en oakhaven_vida.gd")
		return
	if not voz.get("p", false):
		_fallo("2: la voz del corrillo no va marcada como propuesta")
	var c: Vector2 = voz["casilla"]
	var junto := false
	for l in Oak.LUGARES:
		if l["pisable"] and Rect2(l["rect"]).grow(1.6).has_point(c):
			junto = true
	if not junto:
		_fallo("2: el corrillo (%s) no está junto a una calle" % c)
	for v in Vida.VOCES:
		if v["id"] != "voz_corrillo" and v["casilla"].distance_to(c) < 7.0:
			_fallo("2: el corrillo está a menos de 7 m de «%s» (se pisarían en la 3D)" % v["id"])
	var etiqueta := Label.new()
	etiqueta.add_theme_font_override("font", load("res://estilo.gd").normal())
	etiqueta.add_theme_font_size_override("font_size", 24)
	root.add_child(etiqueta)
	var de_decision := 0
	for f in voz["frases"]:
		var t: String = f["texto"]
		if not f.get("p", false):
			_fallo("2: «%s» no va marcada como propuesta" % t)
		if t.length() > Vida.LARGO_MAX:
			_fallo("2: «%s»: %d letras (más de %d)" % [t, t.length(), Vida.LARGO_MAX])
		var fr = f.get("franja", "tarde")
		if not (fr if fr is Array else [fr]).all(func(x): return x in Vida.FRANJAS):
			_fallo("2: «%s»: franja desconocida %s" % [t, fr])
		_reservado(t, "2")
		if f.has("si"):
			de_decision += 1
			_decision_real(f["si"], "2: «%s»" % t)
		elif f.has("af"):
			var af: Dictionary = Barrio.AFIRMACIONES.get(f["af"], {})
			if af.is_empty() or not af.get("verdad", false):
				_fallo("2: «%s»: la afirmación «%s» no existe en el barrio o no es verdad" % [t, f["af"]])
			if not f.get("de", "") in Barrio.FUENTES_OIDO:
				_fallo("2: «%s»: fuente «%s» que no es del barrio" % [t, f.get("de", "")])
		if not f.has("si") and not TEMAS_RUMOR.any(func(x): return x in _plano(t)):
			_fallo("2: «%s» no es de caravanas, caminos, precios ni guardia" % t)
		etiqueta.text = "«%s»" % t
		await process_frame
		if etiqueta.get_minimum_size().x > 620.0:
			_fallo("2: «%s» mide %d px (más de 620)" % [t, etiqueta.get_minimum_size().x])
		print("RUMOR | %s | %s | %d letras | %s" % [f.get("si", f.get("af", "-")), fr, t.length(), t])
	etiqueta.free()
	if de_decision < 6:
		_fallo("2: solo %d rumores dependen de una decisión" % de_decision)
	print("RUMORES: %d (%d de decisión)" % [voz["frases"].size(), de_decision])


func _limpiar_partida() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if Engine.has_meta(C.META):
		Engine.remove_meta(C.META)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)


func _decidir(k: String, v: String) -> void:
	var d: Dictionary = Engine.get_meta("decisiones", {})
	d[k] = v
	Engine.set_meta("decisiones", d)


func _es_decision(c: Dictionary) -> bool:
	return c.has("id") and c.has("si")


# 3. Cada comentario, solo con su decisión y una sola vez.
func _logica_comentarios() -> void:
	# sin ninguna decisión, ningún momento devuelve un comentario de decisión
	_limpiar_partida()
	for m in C.DECISIONES_EN + ["cofre"]:
		for i in 8:
			var c := C.elegir(m, HEROES)
			if c.is_empty():
				break
			if _es_decision(c):
				_fallo("3: sin decisiones sale «%s» en «%s»" % [c["texto"], m])
			C.apuntar(c)
	var dichos_sin: int = int(C.dichos().get("@cuenta", 0))
	print("3: sin decisiones, %d comentarios de siempre y ninguno de decisión" % dichos_sin)
	# con cada valor de decisión, salen exactamente los suyos, una vez
	for k in DECISIONES_REALES:
		for v in DECISIONES_REALES[k]["valores"]:
			var si := "decision:%s=%s" % [k, v]
			var esperados: Array = C.DECISIONES.filter(func(f): return f["si"] == si).map(func(f): return f["id"])
			_limpiar_partida()
			# el otro valor de la misma decisión no los saca
			for otro in DECISIONES_REALES[k]["valores"]:
				if otro != v:
					_decidir(k, otro)
					for c in _sacar("quieto", HEROES, 12):
						if c.get("si", "") == si:
							_fallo("3: con %s=%s sale «%s» (es de %s)" % [k, otro, c["texto"], si])
			_limpiar_partida()
			_decidir(k, v)
			# en el cofre, nunca
			var cf := C.elegir("cofre", HEROES)
			if _es_decision(cf):
				_fallo("3: en el cofre sale el comentario de decisión «%s»" % cf["texto"])
			if Engine.has_meta(C.META):
				Engine.remove_meta(C.META)
			# en «quieto» salen primero los suyos, todos, y luego lo de siempre
			var salidos: Array = []
			for i in 12:
				var c := C.elegir("quieto", HEROES)
				if c.is_empty():
					break
				if not _es_decision(c):
					break
				salidos.append(c["id"])
				if c.has("respuesta") != C.DECISIONES.filter(func(f): return f["id"] == c["id"])[0].has("respuesta"):
					_fallo("3: %s: con los tres en el grupo cambia su respuesta" % c["id"])
				C.apuntar(c)
			salidos.sort()
			esperados.sort()
			if salidos != esperados:
				_fallo("3: con %s salen %s y debían salir %s" % [si, salidos, esperados])
			# sesión nueva (otros «dichos»): ya no salen
			Engine.remove_meta(C.META)
			for c in _sacar("llegar:oakhaven", HEROES, 1) + _sacar("quieto", HEROES, 12):
				if _es_decision(c):
					_fallo("3: %s sale otra vez en una sesión nueva: «%s»" % [c["id"], c["texto"]])
			# guardar y cargar: siguen dichos
			if not P.guardar("res://mapa.tscn"):
				_fallo("3: no se puede guardar la partida de prueba")
			_limpiar_partida()
			P.cargar()
			if Engine.has_meta(C.META):
				Engine.remove_meta(C.META)
			for id in esperados:
				if not C.decision_dicha(id):
					_fallo("3: tras cargar, %s ya no consta como dicho" % id)
			if not C.decisiones_pendientes(HEROES).is_empty():
				_fallo("3: tras cargar, vuelven a estar pendientes %s" % [C.decisiones_pendientes(HEROES).map(func(f): return f["id"])])
			if str(Engine.get_meta("decisiones", {}).get(k, "")) != v:
				_fallo("3: los comentarios cambiaron la decisión %s" % k)
			print("3: %s → %s, una vez (también tras otra sesión y tras guardar y cargar)" % [si, esperados])
	# quien habla tiene que estar; la respuesta, solo si está quien responde
	_limpiar_partida()
	_decidir("gorthor", "muerto")
	var solo_kael := C.elegir("quieto", ["Kael"])
	if solo_kael.get("id", "") != "dec_gorthor_muerto_kael":
		_fallo("3: con Kael solo y Gorthor muerto no sale el de Kael (%s)" % solo_kael.get("id", solo_kael.get("texto", "nada")))
	elif solo_kael.has("respuesta"):
		_fallo("3: con Kael solo sale la respuesta de Lya")
	if C.decisiones_pendientes(["Kael"]).any(func(f): return f["quien"] != "Kael"):
		_fallo("3: con Kael solo están pendientes comentarios de otros")
	_limpiar_partida()
	_decidir("guardian_bosque", "derrotado")
	var sin_garon := C.elegir("llegar:lugar_nuevo", ["Kael", "Lya"])
	if sin_garon.get("id", "") != "dec_bosque_derrotado_lya" or sin_garon.has("respuesta"):
		_fallo("3: con Kael y Lya, el del bosque derrotado no sale sin la respuesta de Garon (%s)" % [sin_garon])
	# la llegada de siempre no se gasta con un comentario de decisión
	_limpiar_partida()
	_decidir("pip_oak", "pagado")
	var l1 := C.elegir("llegar:oakhaven", HEROES)
	C.apuntar(l1)
	var l2 := C.elegir("llegar:oakhaven", HEROES)
	if not _es_decision(l1) or l2.is_empty() or _es_decision(l2):
		_fallo("3: con Pip pagado, la llegada a Oakhaven no da primero el comentario y luego la de siempre (%s / %s)" \
			% [l1.get("texto", ""), l2.get("texto", "")])
	_limpiar_partida()


func _sacar(momento: String, presentes: Array, maximo: int) -> Array:
	var r: Array = []
	for i in maximo:
		var c := C.elegir(momento, presentes)
		if c.is_empty():
			break
		r.append(c)
		C.apuntar(c)
	return r


# 4. Rumores: el de cada decisión, solo con ella y en su franja.
func _logica_rumores() -> void:
	var voz: Array = Vida.frases_de("voz_corrillo")
	_limpiar_partida()
	for franja in Vida.FRANJAS:
		for t in _todo_lo_que_dice(franja):
			for f in voz:
				if f["texto"] == t and f.has("si"):
					_fallo("4: sin decisiones, el corrillo dice «%s»" % t)
	var af_por_franja := {"manana": "caravana_retraso", "tarde": "peaje_sube", "anochecer": "ronda_doble"}
	for franja in af_por_franja:
		var t: String = voz.filter(func(f): return f.get("af", "") == af_por_franja[franja])[0]["texto"]
		if not t in _todo_lo_que_dice(franja):
			_fallo("4: en la franja «%s» el corrillo no cuenta «%s»" % [franja, t])
	for f in voz:
		if not f.has("si"):
			continue
		_limpiar_partida()
		var kv: String = f["si"].trim_prefix("decision:")
		_decidir(kv.get_slice("=", 0), kv.get_slice("=", 1))
		var primera := Vida.frase("voz_corrillo", "tarde", {})
		if primera != f["texto"]:
			_fallo("4: con %s, la primera del corrillo por la tarde es «%s» (no la suya)" % [kv, primera])
		if not f["texto"] in _todo_lo_que_dice("anochecer"):
			_fallo("4: con %s, al anochecer no se cuenta «%s»" % [kv, f["texto"]])
		if f["texto"] in _todo_lo_que_dice("manana"):
			_fallo("4: con %s, se cuenta a la mañana (el corrillo es de después del trabajo)" % kv)
		for g in voz:
			if g.has("si") and g != f and g["texto"] in _todo_lo_que_dice("tarde"):
				_fallo("4: con %s también se cuenta «%s»" % [kv, g["texto"]])
		print("4: %s → «%s»" % [kv, f["texto"]])
	_limpiar_partida()


func _todo_lo_que_dice(franja: String) -> Array:
	var dichos := {}
	var r: Array = []
	for i in 30:
		var t := Vida.frase("voz_corrillo", franja, dichos)
		if t == "" or t in r:
			break
		r.append(t)
		dichos[t] = true
	return r


# 5. En la Oakhaven 3D por defecto.
func _en_oakhaven_3d() -> void:
	_limpiar_partida()
	G.empezar_solo()
	P.poner_hito("pv_02")
	P.poner_hito("pv_03")
	G.unir("Lya")
	P.poner_hito("pv_05")
	G.unir("Garon")
	_decidir("gorthor", "perdonado")
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)
	var antes := {"hitos": Engine.get_meta("hitos", {}).duplicate(true), "decisiones": Engine.get_meta("decisiones", {}).duplicate(true)}
	var v = await _abrir()
	if v == null:
		return
	print("5: grupo en la 3D: %s" % [G.activos()])
	var gorthor: Array = C.DECISIONES.filter(func(f): return f["si"] == "decision:gorthor=perdonado").map(func(f): return f["texto"])
	if not await _hasta(func(): return _caja(v) != null, 10.0):
		_fallo("5: al llegar a la Oakhaven 3D nadie dice nada")
	else:
		var t1: String = _caja(v).get_meta("texto")
		print("5: al llegar: %s — %s" % [_caja(v).get_meta("quien"), t1])
		if not t1 in gorthor:
			_fallo("5: al llegar sale «%s», no un comentario de Gorthor perdonado" % t1)
		_mirar_caja(v, "llegada")
		# (revisión 19/11) un diálogo justo después lo quita: no cuenta como dicho y vuelve a salir más tarde
		var D = root.get_node_or_null("Dialogic")
		var id1: String = C.DECISIONES.filter(func(f): return f["texto"] == t1)[0]["id"]
		await _esperar(10)
		D.start("npc_aldric")
		if not await _hasta(func(): return _caja(v) == null, 5.0):
			_fallo("5: con un diálogo abierto sigue el comentario en pantalla")
		await _esperar(3)
		if C.decision_dicha(id1) or C.dichos().has(t1):
			_fallo("5: %s, quitado por un diálogo a los pocos fotogramas, consta como dicho (no volvería a salir)" % id1)
		else:
			print("5: quitado por un diálogo: %s no consta como dicho" % id1)
		D.end_timeline()
		await _hasta(func(): return not v.ocupado(), 5.0)
		# quietos: los dos de Gorthor, el quitado incluido (14 s sin moverse; a 30 fotogramas por segundo fijos)
		var vistos: Array = []
		for i in 2:
			v._quieto_t = 0.0
			if not await _hasta(func(): return _caja(v) != null, 30.0):
				_fallo("5: quietos (%d), nadie dice nada" % (i + 1))
				break
			var t2: String = _caja(v).get_meta("texto")
			print("5: quietos: %s — %s" % [_caja(v).get_meta("quien"), t2])
			vistos.append(t2)
			await _hasta(func(): return _caja(v) == null, 20.0)
		vistos.sort()
		var esperados_g := gorthor.duplicate()
		esperados_g.sort()
		if vistos != esperados_g:
			_fallo("5: quietos salen %s y debían salir los dos de Gorthor %s (el quitado, otra vez)" % [vistos, esperados_g])
	for f in C.DECISIONES.filter(func(x): return x["si"] == "decision:gorthor=perdonado"):
		if not C.decision_dicha(f["id"]):
			_fallo("5: %s no queda apuntado en la partida" % f["id"])
	# el corrillo, por la tarde, junto al Pórtico del Concejo
	v.franja = "tarde"
	v._quitar_comentarios()
	v._quieto_t = -1000.0
	v.voz_dichos.clear()
	v._colocar_kael(Vector3(49.0, 0.0, 25.6))
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)
	v._t_voz = 0.0
	var rumor := "Unos vecinos: «Al goblin de la Garganta lo dejaron ir, dicen.»"
	if not await _hasta(func(): return v.aviso.text == rumor and v.aviso.modulate.a > 0.5, 12.0):
		_fallo("5: junto al Pórtico del Concejo no se oye el rumor de Gorthor (aviso: «%s»)" % v.aviso.text)
	else:
		print("5: rumor: %s" % v.aviso.text)
	# sesión nueva en la misma partida: la llegada de siempre, ya no la de Gorthor
	if Engine.has_meta(C.META):
		Engine.remove_meta(C.META)
	Engine.set_meta("pos_3d_ok", false)
	v = await _abrir()
	if v != null:
		if not await _hasta(func(): return _caja(v) != null, 10.0):
			_fallo("5: en la sesión nueva, al llegar nadie dice nada")
		else:
			var t3: String = _caja(v).get_meta("texto")
			print("5: sesión nueva, al llegar: %s" % t3)
			if not C.MOMENTOS["llegar:oakhaven"]["frases"].any(func(f): return f["texto"] == t3):
				_fallo("5: en la sesión nueva, al llegar sale «%s» (no la llegada de siempre)" % t3)
	if Engine.get_meta("hitos", {}) != antes["hitos"]:
		_fallo("5: cambian los hitos")
	if Engine.get_meta("decisiones", {}) != antes["decisiones"]:
		_fallo("5: cambian las decisiones")
	await _llegada_3d_condiciones()


# 6. (revisión 19/11) La llegada a la Oakhaven 3D solo se pide fuera de la posada y cuando Kael ya ha salido de Oakhaven
# (cond:kael_salio, hito pv_02): al empezar a jugar, con Kael solo, no sale «el alivio de volver».
func _llegada_3d_condiciones() -> void:
	var Sala = load("res://zonas3d/oakhaven/posada3d.gd")
	var casos := [
		{"que": "Kael solo, sin pv_02 (empieza la partida)", "pv_02": false, "posada": false, "sale": false},
		{"que": "tras pv_02, dentro de la posada", "pv_02": true, "posada": true, "sale": false},
		{"que": "tras pv_02, en la calle", "pv_02": true, "posada": false, "sale": true},
	]
	for caso in casos:
		_limpiar_partida()
		G.empezar_solo()
		if caso["pv_02"]:
			P.poner_hito("pv_02")
		Engine.set_meta("pos_3d_ok", caso["posada"])
		Engine.set_meta("pos_3d_lugar", 0)
		Engine.set_meta("pos_3d", Sala.ORIGEN + Sala.ENTRADA)
		var v = await _abrir()
		if v == null:
			return
		if caso["posada"] and not v.en_posada:
			_fallo("6: %s: Kael no empieza en la posada" % caso["que"])
		var salio := false                         # 200 fotogramas a 30 fijos: ~6,7 s de juego (la llegada, a los 2,5 s;
		for i in 200:                              # quietos, a los 14: aquí no entran)
			if _caja(v) != null:
				salio = true
				break
			await process_frame
		var texto: String = str(_caja(v).get_meta("texto")) if salio else "nada"
		print("6: %s: al llegar → %s" % [caso["que"], texto])
		if salio != caso["sale"]:
			_fallo("6: %s: al llegar %s" % [caso["que"], "sale «%s»" % texto if salio else "no sale nada"])
	Engine.set_meta("pos_3d_ok", false)
	_limpiar_partida()


func _abrir() -> Variant:
	var vieja: int = current_scene.get_instance_id() if current_scene != null else 0
	change_scene_to_file(REGION)
	if not await _hasta(func(): return current_scene != null and current_scene.get_instance_id() != vieja \
			and current_scene.scene_file_path == REGION and current_scene.get("kael") != null \
			and current_scene.get("capa_ui") != null, 90.0):
		_fallo("5: no se abre la Oakhaven 3D")
		return null
	return current_scene


func _caja(v) -> Control:
	if v == null or not is_instance_valid(v) or v.capa_ui == null:
		return null
	for n in v.capa_ui.get_children():
		if n.name.begins_with("comentario") and not n.is_queued_for_deletion():
			return n
	return null


func _mirar_caja(v, que: String) -> void:
	var caja := _caja(v)
	if caja == null:
		return
	var r := caja.get_global_rect()
	if r.end.x > 1280.0 or r.end.y > 720.0 or r.position.x < 0.0:
		_fallo("5: la caja de «%s» (%s) se sale de la pantalla" % [que, r])
	if v.boton_accion.visible and r.intersects(v.boton_accion.get_global_rect()):
		_fallo("5: la caja de «%s» tapa el botón de acción" % que)
