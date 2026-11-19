extends SceneTree
# Comentarios de los héroes al explorar (dialogos/comentarios.gd, narrativa 09/11). Sin ventana, con «-- sin_prologo».
#   1. Los datos: cada momento tiene una frase de Kael, otra de Lya y otra de Garon; cada frase cabe en dos líneas de su
#      caja (medido con la fuente de verdad) y no pasa de 70 letras; gestos y esperas de la lista acordada; nada de lo
#      que no se puede decir aún (Érebo, corazones, recuerdos) ni nombres de otras sagas.
#   2. Quién habla: solo los del grupo (Kael solo hasta PV-03; Lya desde PV-03; Garon desde PV-05), sin respuesta de
#      quien no está; se turnan; ninguna frase se repite y los momentos únicos salen una vez.
#   3. En Oakhaven (ciudad_oakhaven.gd): al llegar, tras abrir un cofre y al quedarse quieto sale un comentario de alguien
#      del grupo, abajo a la derecha y sin tapar el botón de examinar; un diálogo lo quita; la partida no cambia.
#   4. En una zona 2D (zona.gd, el Gran Bosque Verde): al llegar por primera vez en la sesión, «llegar:lugar_nuevo», y
#      tras abrir un cofre, «cofre»; al volver a entrar, ningún comentario de llegada.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const C := preload("res://dialogos/comentarios.gd")
const Oak := preload("res://ciudades/oakhaven.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_comentarios.save"
const HEROES := ["Kael", "Lya", "Garon"]
const GESTOS := ["", "ligero", "firme", "duda", "sorpresa", "decidido", "brazalete", "inquieta", "preocupada", "decidida"]
const ESPERAS := {"Kael": ["espera_vigilar", "espera_empunadura", "espera_brazalete", "espera_impaciencia"],
	"Lya": ["espera_flor", "espera_cetro", "espera_pelo"],
	"Garon": ["espera_hombros", "espera_espalda", "espera_apoyarse"]}
const PROHIBIDAS := ["érebo", "erebo", "corazón", "corazon", "recuerdo", "memoria", "tidus", "yuna", "spira", "sinh"]
const LARGO_MAX := 70

var P
var R
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
	R = root.get_node("Recursos")
	await _datos()
	_quien_habla()
	await _en_oakhaven()
	await _en_zona()
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	quit(1 if fallos.size() > 0 else 0)


# 1. Los datos.
func _datos() -> void:
	var capa := CanvasLayer.new()
	root.add_child(capa)
	var total := 0
	for m in C.MOMENTOS:
		var frases: Array = C.MOMENTOS[m]["frases"]
		for h in HEROES:
			if not frases.any(func(f): return f["quien"] == h):
				_fallo("1: «%s» no tiene frase de %s" % [m, h])
		if not C.ENGANCHES.has(m):
			_fallo("1: «%s» no dice dónde se engancha" % m)
		var todas: Array = frases.duplicate()
		for f in frases:
			if f.has("respuesta"):
				todas.append(f["respuesta"])
		for f in todas:
			total += 1
			var t: String = f["texto"]
			if t.length() > LARGO_MAX:
				_fallo("1: %d letras (más de %d): %s" % [t.length(), LARGO_MAX, t])
			for p in PROHIBIDAS:
				var re := RegEx.create_from_string("(?i)\\b%s\\b" % p)
				if re.search(t) != null:
					_fallo("1: «%s» dice «%s»" % [t, p])
			if not f["quien"] in HEROES:
				_fallo("1: habla alguien que no es un héroe: %s" % f["quien"])
			if not f.get("gesto", "") in GESTOS:
				_fallo("1: gesto desconocido «%s» en «%s»" % [f.get("gesto"), t])
			if f.get("espera", "") != "" and not f["espera"] in ESPERAS.get(f["quien"], []):
				_fallo("1: espera «%s» no es de %s" % [f["espera"], f["quien"]])
			if f.get("intencion", "") == "":
				_fallo("1: «%s» no dice su intención" % t)
			var caja := C._caja(f)
			capa.add_child(caja)
			await _esperar(2)
			var lineas: int = caja.get_node("lineas/frase").get_line_count()
			if lineas > 2:
				_fallo("1: «%s» ocupa %d líneas en su caja" % [t, lineas])
			print("FRASE %s | %d letras | %d línea(s) | %s" % [f["quien"], t.length(), lineas, t])
			caja.free()
	capa.free()
	print("FRASES %d" % total)
	_enganches()


# 1b (19/11, PC-12). ENGANCHES dice la verdad: cada escena que pide un momento (una llamada con el nombre del momento
# entre comillas: _comentar, _comentar_luego, _programar_comentario, Comentarios.elegir o «_comentario_pendiente =»)
# sale nombrada en su texto, y el
# tramo de esa escena (separados por «;») no dice «pendiente». Se miran las escenas que usan comentarios.gd.
const ESCENAS_COMENTARIOS := ["res://zona.gd", "res://ciudad_oakhaven.gd", "res://zonas3d/pastos_verdes_3d.gd",
	"res://zonas3d/garganta_3d.gd", "res://zonas3d/ciclopea_3d.gd", "res://zonas3d/gran_bosque_3d.gd"]


func _enganches() -> void:
	var llamadas := 0
	for ruta in ESCENAS_COMENTARIOS:
		var codigo := FileAccess.get_file_as_string(ruta)
		if codigo == "":
			_fallo("1b: no se puede leer %s" % ruta)
			continue
		var archivo: String = ruta.get_file()
		for m in C.MOMENTOS:
			var re := RegEx.create_from_string("((_comentar|_comentar_luego|_programar_comentario|elegir)\\(|_comentario_pendiente = )\"%s\"" % m)
			if re.search(codigo) == null:
				continue
			llamadas += 1
			var texto: String = C.ENGANCHES.get(m, "")
			var tramo := ""
			for t in texto.split(";"):
				if archivo in t:
					tramo = t
			if tramo == "":
				_fallo("1b: %s pide «%s», pero ENGANCHES no lo nombra («%s»)" % [archivo, m, texto])
			elif "pendiente" in tramo:
				_fallo("1b: %s ya pide «%s», pero ENGANCHES lo da por pendiente («%s»)" % [archivo, m, tramo.strip_edges()])
	if llamadas < 6:
		_fallo("1b: solo encuentro %d llamadas a comentarios en las escenas (¿ha cambiado la forma de pedirlos?)" % llamadas)
	print("ENGANCHES: %d llamadas comprobadas" % llamadas)


# 2. Quién habla.
func _quien_habla() -> void:
	if Engine.has_meta(C.META):
		Engine.remove_meta(C.META)
	for i in 6:
		var c := C.elegir("cofre", ["Kael"])
		if c.is_empty():
			break
		if c["quien"] != "Kael" or c.has("respuesta"):
			_fallo("2: con Kael solo habla %s (respuesta: %s)" % [c["quien"], c.has("respuesta")])
		C.apuntar(c)
	Engine.remove_meta(C.META)
	var c1 := C.elegir("cofre", ["Kael", "Lya"])
	if c1.get("quien", "") != "Kael" or c1.has("respuesta"):
		_fallo("2: con Kael y Lya, el primer cofre no es de Kael sin la respuesta de Garon (%s)" % [c1])
	C.apuntar(c1)
	var c2 := C.elegir("cofre", ["Kael", "Lya"])
	if c2.get("quien", "") != "Lya":
		_fallo("2: no se turnan: el segundo cofre es de %s" % c2.get("quien", "nadie"))
	C.apuntar(c2)
	if not C.elegir("cofre", ["Kael", "Lya"]).is_empty():
		_fallo("2: se repite una frase del cofre")
	Engine.remove_meta(C.META)
	var c3 := C.elegir("cofre", HEROES)
	if c3.get("respuesta", {}).get("quien", "") != "Garon":
		_fallo("2: con Garon presente no sale su respuesta")
	var l1 := C.elegir("llegar:oakhaven", HEROES)
	C.apuntar(l1)
	if not C.elegir("llegar:oakhaven", HEROES).is_empty():
		_fallo("2: la llegada a Oakhaven sale dos veces")
	Engine.remove_meta(C.META)


# 3. En Oakhaven, con Kael y Lya (después de PV-03, antes de PV-05).
func _en_oakhaven() -> void:
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	var G = load("res://grupo.gd")
	G.empezar_solo()
	P.poner_hito("pv_03")
	G.unir("Lya")
	if Engine.has_meta(C.META):
		Engine.remove_meta(C.META)
	var antes: Dictionary = {"mazmorras": Engine.get_meta("mazmorras", {}).duplicate(true), "hitos": Engine.get_meta("hitos", {}).duplicate(true)}
	var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
	Engine.set_meta("lugar", {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == CIUDAD \
			and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("3: no se abre la ciudad")
		return
	var z = current_scene
	# al llegar
	if not await _hasta(func(): return _caja(z) != null, 8.0):
		_fallo("3: al llegar nadie dice nada")
	else:
		_mirar_caja(z, "llegada", ["Kael", "Lya"])
		await _hasta(func(): return _caja(z) == null, 15.0)
	# un cofre
	var cofre = null
	for c in z.cofres:
		if c[1] == "oak_cofre_velas":
			cofre = c
	if cofre == null:
		_fallo("3: no está el cofre del Patio de las Velas")
	else:
		z.jugador.position = cofre[0].position + Vector2(0, 40)
		z._abrir_cofre(cofre)
		if not await _hasta(func(): return _caja(z) != null, 6.0):
			_fallo("3: tras abrir el cofre nadie dice nada")
		else:
			_mirar_caja(z, "cofre", ["Kael", "Lya"])
			await _hasta(func(): return _caja(z) == null, 15.0)
	# quieto (14 s; a 30 fotogramas por segundo fijos)
	z.tiene_destino = false
	z.jugador.velocity = Vector2.ZERO
	z.quieto_t = 0.0
	if not await _hasta(func(): return _caja(z) != null, 25.0):
		_fallo("3: quieto, nadie dice nada")
	else:
		_mirar_caja(z, "quieto", ["Kael", "Lya"])
		# un diálogo lo quita
		var D = root.get_node_or_null("Dialogic")
		z._empezar_dialogo("oak_posadera")
		if D != null:
			await _hasta(func():
				if D.current_timeline == null or D.current_state != D.States.IDLE:
					return false
				var i: int = D.current_event_idx
				return i >= 0 and i < D.current_timeline_events.size() and D.current_timeline_events[i] is DialogicTextEvent, 10.0)
		await _esperar(10)
		if _caja(z) != null:
			_fallo("3: con un diálogo abierto sigue el comentario")
		if D != null:
			D.end_timeline(true)
	await _esperar(5)
	if Engine.get_meta("hitos", {}) != antes["hitos"]:
		_fallo("3: los comentarios cambian los hitos")
	Engine.remove_meta("archivo_partida_prueba")


func _caja(z) -> Control:
	for n in z.ui.get_children():
		if n.name.begins_with("comentario") and not n.is_queued_for_deletion():
			return n
	return null


func _mirar_caja(z, que: String, presentes: Array) -> void:
	var caja := _caja(z)
	var quien: String = caja.get_meta("quien")
	print("COMENTARIO %s: %s — %s" % [que, quien, caja.get_meta("texto")])
	if not quien in presentes:
		_fallo("3: en «%s» habla %s, que no está en el grupo" % [que, quien])
	var r := caja.get_global_rect()
	var b: Rect2 = z.boton_examinar.get_global_rect()
	if r.intersects(b) or r.end.x > 1280.0 or r.end.y > 720.0 or r.position.x < 0.0:
		_fallo("3: la caja de «%s» (%s) se sale o tapa el botón de examinar (%s)" % [que, r, b])


# 4. En una zona 2D generada (zona.gd).
func _en_zona() -> void:
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	var l: Dictionary = load("res://mapa.gd").LUGARES[1]
	var z = await _abrir_zona(l)
	if z == null:
		return
	if not await _hasta(func(): return _caja(z) != null, 8.0):
		_fallo("4: al llegar a %s nadie dice nada" % l["nombre"])
	else:
		var caja := _caja(z)
		var t: String = caja.get_meta("texto")
		if not C.MOMENTOS["llegar:lugar_nuevo"]["frases"].any(func(f): return f["texto"] == t):
			_fallo("4: al llegar a una zona sale «%s», que no es de «llegar:lugar_nuevo»" % t)
		_mirar_caja(z, "zona, llegada", ["Kael", "Lya"])
		await _hasta(func(): return _caja(z) == null, 15.0)
	var cofre = null
	for c in z.cofres:
		if not c[2]:
			cofre = c
			break
	if cofre == null:
		print("AVISO 4: la zona no tiene cofres cerrados: el del cofre se prueba solo en Oakhaven")
	else:
		z._abrir_cofre(cofre)
		if not await _hasta(func(): return _caja(z) != null, 6.0):
			_fallo("4: tras abrir un cofre de la zona nadie dice nada")
		else:
			var t2: String = _caja(z).get_meta("texto")
			if not C.MOMENTOS["cofre"]["frases"].any(func(f): return f["texto"] == t2):
				_fallo("4: tras el cofre sale «%s», que no es del cofre" % t2)
			_mirar_caja(z, "zona, cofre", ["Kael", "Lya"])
			await _hasta(func(): return _caja(z) == null, 15.0)
	# otra vez al mismo sitio: sin comentario de llegada
	z = await _abrir_zona(l)
	if z == null:
		return
	if await _hasta(func(): return _caja(z) != null, 6.0):
		_fallo("4: al volver a %s se repite el comentario de llegada («%s»)" % [l["nombre"], _caja(z).get_meta("texto")])
	Engine.remove_meta("archivo_partida_prueba")


func _abrir_zona(l: Dictionary) -> Variant:
	Engine.set_meta("lugar", {"indice": 1, "nombre": l["nombre"], "tipo": l["tipo"], "zona": l.get("zona", "bosque"), "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	var vieja: int = current_scene.get_instance_id() if current_scene != null else 0
	change_scene_to_file("res://zona.tscn")
	if not await _hasta(func(): return current_scene != null and current_scene.get_instance_id() != vieja \
			and current_scene.scene_file_path == "res://zona.tscn" and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("4: no se abre la zona %s" % l["nombre"])
		return null
	return current_scene