extends SceneTree
# Oakhaven vivo (ciudades/oakhaven_vida.gd y ciudad_oakhaven.gd): lo que dicen vecinos y gente al pasar cerca. Sin
# ventana, con «-- sin_prologo». Partida propia (user://prueba_oakhaven_vida.save).
#   1. Los datos: los ocho vecinos de ciudades/oakhaven.gd, con tres frases o más; voces junto a una calle; cada frase en
#      una línea (48 letras como mucho, y medida en su etiqueta); condiciones bien escritas y franjas que existen; nada
#      de Érebo (D-033), de lo que espera decisión del usuario (D-073) ni de Final Fantasy X.
#   2. Qué frase toca: cambia con el estado de las misiones y con la franja (tras dormir, «manana»); no se repite hasta
#      que se acaban las que tocan.
#   3. En la ciudad: al pasar junto a la posadera, una frase suya sobre su cabeza; después, una pausa en la que nadie
#      más habla; la misma persona no repite enseguida; un diálogo la quita; tras dormir, frases de la mañana.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const Vida := preload("res://ciudades/oakhaven_vida.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_oakhaven_vida.save"
const T := 64.0
const PROHIBIDO := ["erebo", "ladron de corazones", "corazones", "recuerdo", "memoria", "olvido", "rocio", "cripta",
	"trampilla", "conclave", "crio", "hermano", "diecisiete", "alcantarilla", "tidus", "yuna", "spira", "sinh"]

var P
var R
var D
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


func _plano(t: String) -> String:
	var r := t.to_lower()
	for p in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		r = r.replace(p[0], p[1])
	return r


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	load("res://grupo.gd").empezar_solo()


func _probar() -> void:
	P = load("res://progreso.gd")
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	await _datos()
	_que_toca()
	await _en_la_ciudad()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Los datos.
func _datos() -> void:
	var ids: Array = Oak.NPCS.map(func(n): return n["id"])
	for id in ids:
		if not Vida.VECINOS.has(id):
			_fallo("1: %s no tiene frases" % id)
		elif Vida.VECINOS[id].size() < 3:
			_fallo("1: %s tiene %d frases (3 o más)" % [id, Vida.VECINOS[id].size()])
	for id in Vida.VECINOS:
		if not id in ids:
			_fallo("1: «%s» no es un vecino de Oakhaven" % id)
	var todas: Array = []
	for id in Vida.VECINOS:
		for f in Vida.VECINOS[id]:
			todas.append([id, f])
	for v in Vida.VOCES:
		if v["nombre"] == "" or v["frases"].size() < 3:
			_fallo("1: la voz %s no tiene nombre o tiene menos de tres frases" % v["id"])
		if not _junto_a_calle(v["casilla"]):
			_fallo("1: la voz %s sale de %s, lejos de cualquier calle" % [v["id"], v["casilla"]])
		for f in v["frases"]:
			todas.append([v["id"], f])
	var etiqueta := Label.new()
	etiqueta.add_theme_font_override("font", load("res://estilo.gd").normal())
	etiqueta.add_theme_font_size_override("font_size", 24)
	root.add_child(etiqueta)
	for e in todas:
		var f: Dictionary = e[1]
		var t: String = f["texto"]
		if t.length() > Vida.LARGO_MAX:
			_fallo("1: %s: %d letras: «%s»" % [e[0], t.length(), t])
		if f.has("si") and Oak.error_condicion(f["si"]) != "":
			_fallo("1: %s: %s" % [e[0], Oak.error_condicion(f["si"])])
		if not f.get("franja", "anochecer") in ["anochecer", "manana"]:
			_fallo("1: %s: franja desconocida «%s»" % [e[0], f["franja"]])
		var p := _plano(t)
		for x in PROHIBIDO:
			if RegEx.create_from_string("\\b%s" % x).search(p) != null:
				_fallo("1: %s: «%s» dice «%s»" % [e[0], t, x])
		etiqueta.text = "«%s»" % t
		await process_frame
		if etiqueta.get_minimum_size().x > 620.0:
			_fallo("1: %s: «%s» mide %d px (más de 620)" % [e[0], t, etiqueta.get_minimum_size().x])
	etiqueta.free()
	print("FRASES %d (vecinos %d, voces %d)" % [todas.size(), Vida.VECINOS.size(), Vida.VOCES.size()])


func _junto_a_calle(c: Vector2) -> bool:
	for l in Oak.LUGARES:
		if l["pisable"] and Rect2(l["rect"]).grow(1.6).has_point(c):
			return true
	return false


# 2. Qué frase toca.
func _que_toca() -> void:
	_limpiar()
	var dichos := {}
	var a := Vida.frase("aldric", "anochecer", dichos)
	if a != "Tres faroles apagados en la muralla. Mal asunto.":
		_fallo("2: sin los faroles, Aldric dice «%s»" % a)
	P.poner_hito("oak_faroles")
	if Vida.frase("aldric", "anochecer", {}) != "Faroles encendidos, puerta cerrada. Así sí.":
		_fallo("2: con los faroles encendidos, Aldric no lo nota")
	if Vida.frase("bastian", "anochecer", {}) != "¡Ciento doce! Los he contado dos veces.":
		_fallo("2: con los faroles encendidos, Bastián no lo nota")
	if Vida.frase("posadera", "manana", {}) != "¿Ya en pie? El pan acaba de salir.":
		_fallo("2: por la mañana, la posadera no lo nota")
	# sin repetir: con Albar (tres frases sin condición) salen las tres distintas y luego vuelve a empezar
	dichos = {}
	var vistas := {}
	for i in 3:
		var t := Vida.frase("albar", "anochecer", dichos)
		dichos[t] = true
		vistas[t] = true
	if vistas.size() != 3:
		_fallo("2: Albar repite antes de decir sus tres frases (%s)" % [vistas.keys()])
	if Vida.frase("albar", "anochecer", dichos) == "":
		_fallo("2: al acabarse, Albar se queda callado en vez de volver a empezar")
	for f in Vida.frases_de("voz_taberna"):
		if f.get("franja", "") == "manana" and Vida.frase("voz_taberna", "anochecer", {}) == f["texto"]:
			_fallo("2: por la tarde sale una frase de la mañana")


# 3. En la ciudad.
func _en_la_ciudad() -> void:
	_limpiar()
	var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
	Engine.set_meta("lugar", {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == CIUDAD \
			and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("3: no se abre la ciudad")
		return
	var z = current_scene
	await _esperar(10)
	var posadera = null
	var bastian = null
	for n in z.npcs:
		if n[1]["id"] == "posadera":
			posadera = n
		if n[1]["id"] == "bastian":
			bastian = n
	# junto a la posadera
	z.jugador.position = posadera[0].position + Vector2(70, 40)
	z.voz_pausa = 0.0
	if not await _hasta(func(): return is_instance_valid(z.voz_globo), 8.0):
		_fallo("3: junto a la posadera nadie dice nada")
		return
	var g: Node2D = z.voz_globo
	var texto: String = g.get_child(0).text
	print("VOZ %s: %s" % [g.get_meta("quien"), texto])
	if g.get_meta("quien") != "posadera" or not Vida.VECINOS["posadera"].any(func(f): return f["texto"] == texto):
		_fallo("3: junto a la posadera habla %s («%s»)" % [g.get_meta("quien"), texto])
	if g.global_position.y > posadera[0].position.y - 60.0 or absf(g.global_position.x - posadera[0].position.x) > 2.0:
		_fallo("3: la frase no sale sobre la cabeza de la posadera (%s / %s)" % [g.global_position, posadera[0].position])
	# después, pausa: junto a Bastián, nadie habla hasta que pasa
	await _hasta(func(): return not is_instance_valid(z.voz_globo), 15.0)
	z.jugador.position = bastian[0].position + Vector2(70, 40)
	await _esperar(30)
	if is_instance_valid(z.voz_globo):
		_fallo("3: sin pausa, %s habla justo después" % z.voz_globo.get_meta("quien"))
	z.voz_pausa = 0.0
	if not await _hasta(func(): return is_instance_valid(z.voz_globo), 8.0):
		_fallo("3: tras la pausa, junto a Bastián nadie dice nada")
	else:
		print("VOZ %s: %s" % [z.voz_globo.get_meta("quien"), z.voz_globo.get_child(0).text])
		# un diálogo la quita
		if D != null:
			z._empezar_dialogo("oak_posadera")
			await _texto_en_pantalla()
			if is_instance_valid(z.voz_globo):
				_fallo("3: con un diálogo abierto sigue la frase del vecino")
			D.end_timeline(true)
			await _esperar(30)
	# la misma persona no repite enseguida
	z.jugador.position = posadera[0].position + Vector2(70, 40)
	z.voz_pausa = 0.0
	await _esperar(20)
	if is_instance_valid(z.voz_globo) and z.voz_globo.get_meta("quien") == "posadera":
		_fallo("3: la posadera vuelve a hablar sin su pausa")
	# tras dormir, la mañana
	z._tras_posada()
	if D != null:
		await _hasta(func(): return D.current_timeline != null, 5.0)
		await _texto_en_pantalla()
		D.end_timeline(true)
		await _esperar(30)
	if z.franja != "manana":
		_fallo("3: tras dormir no es por la mañana")
	z.voz_quien.clear()
	z.voz_pausa = 0.0
	if not await _hasta(func(): return is_instance_valid(z.voz_globo), 8.0):
		_fallo("3: por la mañana, junto a la posadera, nadie dice nada")
	else:
		var t2: String = z.voz_globo.get_child(0).text
		print("VOZ (mañana) %s: %s" % [z.voz_globo.get_meta("quien"), t2])
		if t2 != "¿Ya en pie? El pan acaba de salir.":
			_fallo("3: por la mañana, la posadera dice «%s»" % t2)


# Espera a que una frase esté entera en pantalla (cerrar antes deja a Dialogic a medias con los retratos).
func _texto_en_pantalla() -> void:
	await _hasta(func():
		if D.current_timeline == null or D.current_state != D.States.IDLE:
			return false
		var i: int = D.current_event_idx
		return i >= 0 and i < D.current_timeline_events.size() and D.current_timeline_events[i] is DialogicTextEvent, 10.0)
	await _esperar(10)