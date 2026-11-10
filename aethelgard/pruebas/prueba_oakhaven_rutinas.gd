extends SceneTree
# Rutinas de los vecinos de Oakhaven y fauna (ciudades/oakhaven_vida.gd, RUTINAS y FAUNA; ciudad_oakhaven.gd). Sin
# ventana, con «-- sin_prologo». Partida propia (user://prueba_oakhaven_rutinas.save).
#   1. Los datos: los ocho vecinos con las tres franjas; cada sitio (y su paseo entero) en una calle, plaza o patio de
#      ciudades/oakhaven.gd, a 2,5 casillas o más de lo que se examina y de los demás vecinos a esa hora; la tarde es su
#      sitio de siempre y la posadera no se mueve de la puerta; «hace» de la lista; frases cortas y sin nada vetado.
#      La fauna: tipos, sitios dentro de la ciudad, franjas y comportamiento de fauna_simple.gd.
#   2. En la ciudad: al llegar es la tarde y cada vecino está en su sitio; al anochecer y por la mañana, cada uno donde le
#      toca (el que pasea, en su camino y moviéndose); el sonido sigue a la franja; la sombra va con su vecino.
#   3. El tiempo: a los DURACION_FRANJA s la tarde pasa al anochecer; el anochecer no pasa solo; dormir trae la mañana.
#   4. Las misiones siguen: por la mañana la posadera da «Tres favores» y Pip, que pasea por el mercado, habla y da el
#      cucharón; al anochecer, Rosa, de camino al Árbol, da las flores; mientras se habla, el paseo se para.
#   5. Salir y volver en la misma sesión: la franja se recuerda.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const Vida := preload("res://ciudades/oakhaven_vida.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const MAPA := "res://mapa.tscn"
const ARCHIVO := "user://prueba_oakhaven_rutinas.save"
const T := 64.0
const PROHIBIDO := ["erebo", "ladron de corazones", "corazones", "recuerdo", "memoria", "olvido", "rocio", "cripta",
	"trampilla", "conclave", "crio", "hermano", "diecisiete", "alcantarilla", "tidus", "yuna", "spira", "sinh"]

var P
var R
var D
var fallos: Array = []
var pregunta := false


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


func _probar() -> void:
	P = load("res://progreso.gd")
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	if D != null:
		D.Choices.question_shown.connect(func(_i): pregunta = true)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for k in ["oak_franja", "oak_franja_t"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	load("res://grupo.gd").empezar_solo()
	_datos()
	var z = await _abrir()
	if z != null:
		await _en_la_ciudad(z)
		await _tiempo(z)
		if D != null:
			await _misiones(z)
		await _volver()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# --------------------------------------------------------------- 1. datos

func _pisable(c: Vector2) -> bool:
	var dentro := false
	for l in Oak.LUGARES:
		var r := Rect2(l["rect"])
		if r.has_point(c):
			if not l["pisable"] or l["id"] == "grieta":
				return false
			dentro = true
	return dentro


func _examinables() -> Array:
	var r: Array = []
	for p in Oak.PIEZAS:
		r.append([p["id"], p["casilla"]])
	for n in Oak.NOTAS:
		if n.has("casilla"):
			r.append([n["id"], n["casilla"]])
	for c in Oak.COFRES:
		r.append([c["id"], c["casilla"]])
	for id in Oak.SITIOS_DETALLE:
		r.append([id, Oak.SITIOS_DETALLE[id]])
	r.append(["el pie del Árbol", Vector2(40, 9)])
	return r


# Los puntos de un sitio (o de su paseo, cada media casilla).
func _puntos(r: Dictionary) -> Array:
	var a: Vector2 = r["casilla"]
	if not r.has("hasta"):
		return [a]
	var b: Vector2 = r["hasta"]
	var pts: Array = []
	var n := int(ceil(a.distance_to(b) / 0.5))
	for i in n + 1:
		pts.append(a.lerp(b, float(i) / n))
	return pts


func _datos() -> void:
	var ex := _examinables()
	for d in Oak.NPCS:
		var id: String = d["id"]
		if not Vida.RUTINAS.has(id):
			_fallo("1: %s no tiene rutina" % id)
			continue
		for f in Vida.FRANJAS:
			var r := Vida.rutina(id, f)
			if r.is_empty():
				_fallo("1: %s no tiene rutina por la %s" % [id, f])
				continue
			if not r.get("hace", "") in Vida.HACE or (r["hace"] == "pasea") != r.has("hasta"):
				_fallo("1: %s (%s): «hace» %s y paseo %s no cuadran" % [id, f, r.get("hace"), r.has("hasta")])
			var t: String = r.get("frase", "")
			if t == "" or t.length() > Vida.LARGO_MAX or r.get("donde", "") == "":
				_fallo("1: %s (%s): sin frase, frase larga o sin «donde»" % [id, f])
			for x in PROHIBIDO:
				if RegEx.create_from_string("\\b%s" % x).search(_plano(t)) != null:
					_fallo("1: %s (%s) dice «%s»" % [id, f, x])
			for p in _puntos(r):
				if not _pisable(p):
					_fallo("1: %s (%s) pisa %s, que no es calle, plaza ni patio" % [id, f, p])
					break
				for e in ex:
					if p.distance_to(e[1]) < 2.5:
						_fallo("1: %s (%s) pasa a %.1f casillas de %s" % [id, f, p.distance_to(e[1]), e[0]])
						break
			for otro in Oak.NPCS:
				if otro["id"] == id:
					continue
				var o := Vida.rutina(otro["id"], f)
				if not o.is_empty():
					for p in _puntos(r):
						for q in _puntos(o):
							if p.distance_to(q) < 2.5:
								_fallo("1: por la %s, %s y %s se cruzan en %s" % [f, id, otro["id"], p])
								return
		if Vida.rutina(id, "tarde").get("casilla") != d["casilla"]:
			_fallo("1: por la tarde %s no está en su sitio de siempre" % id)
	for f in Vida.FRANJAS:
		if Vida.rutina("posadera", f).get("casilla") != Vida.rutina("posadera", "tarde").get("casilla"):
			_fallo("1: la posadera se mueve de la puerta del Cuervo por la %s" % f)
	for fa in Vida.FAUNA:
		if not fa["tipo"] in ["gato", "paloma", "gallina"] or not fa.get("como", "") in ["conejo", "pajaro"]:
			_fallo("1: fauna con tipo o comportamiento desconocido: %s" % [fa])
		if fa["franjas"].is_empty() or not fa["franjas"].all(func(x): return x in Vida.FRANJAS) or int(fa["cuantos"]) < 1:
			_fallo("1: fauna %s sin franjas válidas o sin cuántos" % fa["tipo"])
		for c in fa["sitios"]:
			if c.x < 1 or c.y < 1 or c.x > 79 or c.y > 55:
				_fallo("1: fauna %s fuera de la ciudad: %s" % [fa["tipo"], c])
	print("RUTINAS %d vecinos × %d franjas · FAUNA %d grupos" % [Vida.RUTINAS.size(), Vida.FRANJAS.size(), Vida.FAUNA.size()])


# --------------------------------------------------------------- 2. en la ciudad

func _abrir() -> Variant:
	var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
	Engine.set_meta("lugar", {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	var vieja: int = current_scene.get_instance_id() if current_scene != null else 0
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return current_scene != null and current_scene.get_instance_id() != vieja \
			and current_scene.scene_file_path == CIUDAD and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("no se abre la ciudad")
		return null
	await _esperar(8)
	return current_scene


func _vecino(z, id: String) -> Array:
	for n in z.npcs:
		if n[1].get("id", "") == id:
			return n
	return []


func _donde_toca(z, f: String, que: String) -> void:
	for n in z.npcs:
		var r := Vida.rutina(n[1]["id"], f)
		var p: Vector2 = n[0].position / T
		var bien := false
		for q in _puntos(r):
			bien = bien or p.distance_to(q) < 0.3
		if not bien:
			_fallo("2: %s: %s está en %s y le toca %s" % [que, n[1]["id"], p, r.get("casilla")])
		var sb = n[0].get_meta("sombra", null)
		if sb == null or sb.position.distance_to(n[0].position + Vector2(0, 2)) > 2.0:
			_fallo("2: %s: la sombra de %s no va con él" % [que, n[1]["id"]])
	var son = root.get_node_or_null("Sonido")
	if son != null and son.momento_actual() != Vida.MOMENTO_SONIDO[f]:
		_fallo("2: %s: suena «%s» y no «%s»" % [que, son.momento_actual(), Vida.MOMENTO_SONIDO[f]])


func _en_la_ciudad(z) -> void:
	if z.franja != "tarde":
		_fallo("2: al llegar no es la tarde (%s)" % z.franja)
	await _esperar(4)
	_donde_toca(z, "tarde", "al llegar")
	for f in ["anochecer", "manana"]:
		z._poner_franja(f, false)
		await _esperar(4)
		_donde_toca(z, f, f)
	# el que pasea se mueve
	z._poner_franja("anochecer", false)
	var b := _vecino(z, "bastian")
	var p0: Vector2 = b[0].position
	await _esperar(60)
	if b[0].position.distance_to(p0) < T * 0.5:
		_fallo("2: al anochecer Bastián no va de farol en farol")
	print("PASEO bastian %s → %s" % [p0 / T, b[0].position / T])


# --------------------------------------------------------------- 3. el tiempo

func _tiempo(z) -> void:
	z._poner_franja("tarde", false)
	z.franja_t = Vida.DURACION_FRANJA - 0.05
	await _esperar(10)
	if z.franja != "anochecer":
		_fallo("3: la tarde no pasa al anochecer (%s)" % z.franja)
	z.franja_t = Vida.DURACION_FRANJA - 0.05
	await _esperar(10)
	if z.franja != "anochecer":
		_fallo("3: el anochecer pasa solo a %s" % z.franja)
	z._tras_posada()
	if z.franja != "manana":
		_fallo("3: al despertar no es la mañana (%s)" % z.franja)
	if D != null:
		await _hasta(func(): return D.current_timeline != null, 5.0)
		await _recorrer([])
	await _esperar(30)                             # (el fundido de los que cambian de sitio)
	_donde_toca(z, "manana", "al despertar")


# --------------------------------------------------------------- 4. misiones

func _recorrer(elegir: Array) -> void:
	var cola := elegir.duplicate()
	pregunta = false
	var limite := Time.get_ticks_msec() + 20000
	var ultimo := 0
	while D.current_timeline != null and Time.get_ticks_msec() < limite:
		await process_frame
		var f := Engine.get_process_frames()
		if pregunta:
			await _esperar(10)
			pregunta = false
			D.Choices.select_choice(cola.pop_front() if not cola.is_empty() else 1)
			ultimo = Engine.get_process_frames()
			continue
		if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and f - ultimo >= 4:
			D.Inputs.handle_input()
			ultimo = f
	if D.current_timeline != null:
		D.end_timeline(true)
	await _esperar(6)


func _hablar(z, id: String) -> String:
	var n := _vecino(z, id)
	z.jugador.position = n[0].position + Vector2(36, 28)
	await _esperar(2)
	z._comprobar_cerca()
	var esperado: String = Oak.dialogo_de(id, n[2])
	z._accion()
	if not await _hasta(func(): return D.current_timeline != null, 5.0):
		_fallo("4: hablar con %s no abre ningún diálogo" % id)
		return ""
	var ruta: String = D.current_timeline.resource_path
	if ruta != esperado:
		_fallo("4: con %s se abre %s y tocaba %s" % [id, ruta, esperado])
	var antes: Vector2 = n[0].position
	await _esperar(30)
	if z.paseos.has(id) and n[0].position.distance_to(antes) > 1.0:
		_fallo("4: %s sigue paseando mientras habla" % id)
	await _recorrer([])
	return ruta


func _misiones(z) -> void:
	z._poner_franja("manana", false)
	await _esperar(6)
	await _hablar(z, "posadera")                   # oak_posadera
	await _hablar(z, "posadera")                   # oak_posadera_favores: la misión
	if Oak.estado_mision("oak_favores") != "en_curso":
		_fallo("4: por la mañana, la posadera no da «Tres favores» (%s)" % Oak.estado_mision("oak_favores"))
	await _hablar(z, "pip")                        # por el mercado: el cucharón
	if not P.estado(Oak.NOMBRE, "favor_cucharon"):
		_fallo("4: Pip, paseando por el mercado, no da el cucharón")
	z._poner_franja("anochecer", false)
	await _esperar(6)
	await _hablar(z, "rosa")                       # de camino al Árbol: las flores
	if not P.estado(Oak.NOMBRE, "favor_flores"):
		_fallo("4: Rosa, de camino al Árbol, no da las flores")
	print("MISIÓN favores: %s · cucharón %s · flores %s" % [Oak.estado_mision("oak_favores"),
		P.estado(Oak.NOMBRE, "favor_cucharon"), P.estado(Oak.NOMBRE, "favor_flores")])


# --------------------------------------------------------------- 5. salir y volver

func _volver() -> void:
	var z = current_scene
	z._poner_franja("anochecer", false)
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file(MAPA)
	await _hasta(func(): return current_scene != null and current_scene.scene_file_path == MAPA and not R.cambiando, 60.0)
	await _esperar(10)
	z = await _abrir()
	if z == null:
		return
	if z.franja != "anochecer":
		_fallo("5: al volver en la misma sesión no se recuerda la franja (%s)" % z.franja)
	await _esperar(4)
	_donde_toca(z, "anochecer", "al volver")
