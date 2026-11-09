extends SceneTree
# Charlas de posada (narrativa, 09/11): conversaciones de los héroes al descansar en el Cuervo (ciudades/oakhaven.gd,
# CHARLAS_POSADA; diálogos en dialogos/oakhaven/charlas/). Sin ventana, con «-- sin_prologo». Partida propia.
#   1. Los datos: de 4 a 9 charlas, cada una con su diálogo, un hito que ya existe (o una condición, como un combate fijo
#      ganado de la Garganta) y un grupo de héroes.
#   2. El texto: de 4 a 6 frases; solo hablan los del grupo y todos dicen algo; cada frase cabe en la caja (110 letras
#      como mucho) y tiene su intención (CHARLAS_POSADA, «intenciones»); Kael y Lya, su gesto (extra_data de la lista); nada
#      de Érebo ni de corazones o recuerdos guardados, ni nombres de Final Fantasy X.
#   3. Cada charla se recorre entera con Dialogic, sin errores, con esas frases y esos personajes.
#   4. Cuál toca: ninguna sin su hito o sin su grupo; la más nueva sin ver; vista, la siguiente; sin charlas, la escena
#      de posada de siempre.
#   5. Partidas antiguas: sin «mazmorras», o con la ciudad pero sin ninguna «charla_…», cargan y valen «sin ver»; lo
#      visto se guarda y se lee con lo demás de la ciudad (la noche gratis sigue).
#   6. En la ciudad: descansar en la posada abre la charla que toca y queda vista; la siguiente noche, la de siempre.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_charlas_posada.save"
const HITOS := ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo", "oak_favores", "oak_faroles",
	"oak_lavanda"]
const HEROES := ["Kael", "Lya", "Garon"]
const COMBATES := ["garganta_nido", "garganta_gorthor"]      # combates fijos de garganta.gd y garganta_3d.gd
const GESTOS := {"kael": ["ligero", "brazalete", "sorpresa", "decidido", "duda"],
	"lya": ["inquieta", "preocupada", "decidida", "duda", "firme"]}
const PROHIBIDAS := ["érebo", "erebo", "corazón", "corazones", "recuerdo", "recuerdos", "memoria", "tidus", "yuna",
	"spira", "sinh"]
const MAX_LETRAS := 110

var P
var G
var R
var D
var fallos: Array = []
var eventos: Array = []                   # [quien, texto] del diálogo en curso


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


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)


func _probar() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	_limpiar()
	_datos()
	if D != null:
		D.timeline_started.connect(func(): eventos.clear())
		D.event_handled.connect(_al_evento)
		await _recorrer_todas()
	else:
		_fallo("hace falta Dialogic")
	_cual_toca()
	_partidas_antiguas()
	if D != null:
		await _en_la_ciudad()
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1 y 2. Los datos y el texto.
func _datos() -> void:
	var n: int = Oak.CHARLAS_POSADA.size()
	if n < 4 or n > 9:
		_fallo("1: hay %d charlas (de 4 a 9)" % n)
	var ids := {}
	for c in Oak.CHARLAS_POSADA:
		if ids.has(c["id"]):
			_fallo("1: charla repetida %s" % c["id"])
		ids[c["id"]] = true
		if not c.has("hito") and not c.has("si"):
			_fallo("1: %s no dice con qué se desbloquea" % c["id"])
		if c.has("hito") and not c["hito"] in HITOS:
			_fallo("1: %s se desbloquea con «%s», que no es un hito que exista" % [c["id"], c["hito"]])
		if c.has("si") and Oak.error_condicion(c["si"]) != "":
			_fallo("1: %s: %s" % [c["id"], Oak.error_condicion(c["si"])])
		if c.has("si") and str(c["si"]).begins_with("ganado:") and not str(c["si"]).trim_prefix("ganado:") in COMBATES:
			_fallo("1: %s depende del combate «%s», que no existe" % [c["id"], c["si"]])
		if c["grupo"].is_empty() or not c["grupo"].all(func(q): return q in HEROES) or not "Kael" in c["grupo"]:
			_fallo("1: el grupo de %s no vale (%s)" % [c["id"], c["grupo"]])
		var ruta: String = Oak.ruta_charla(c["id"])
		if not FileAccess.file_exists(ruta):
			_fallo("1: falta %s" % ruta)
			continue
		_revisar_texto(c, FileAccess.get_file_as_string(ruta))
	var d := DirAccess.open(Oak.RUTA_CHARLAS)
	if d != null:
		for f in d.get_files():
			if f.get_extension() == "dtl" and not ids.has(f.get_basename()):
				_fallo("1: %s no está en CHARLAS_POSADA" % f)


func _revisar_texto(c: Dictionary, texto: String) -> void:
	var lineas := texto.split("\n")
	var frases := 0
	var hablan := {}
	var gesto := {}                               # último gesto pedido por personaje desde su última frase
	for i in lineas.size():
		var l := lineas[i].strip_edges()
		var m := RegEx.create_from_string("^update (\\w+) \\[extra_data=\"(\\w+)\"\\]").search(l)
		if m != null:
			var quien_g := m.get_string(1)
			if not m.get_string(2) in GESTOS.get(quien_g, []):
				_fallo("2: %s: gesto «%s» de %s no está en la lista" % [c["id"], m.get_string(2), quien_g])
			gesto[quien_g] = true
			continue
		var f := RegEx.create_from_string("^(\\w+): (.+)$").search(l)
		if f == null:
			continue
		var quien := f.get_string(1)
		var t := f.get_string(2)
		frases += 1
		hablan[quien] = true
		var nombre := quien.capitalize()
		if not nombre in c["grupo"]:
			_fallo("2: %s: habla %s, que no está en su grupo %s" % [c["id"], nombre, c["grupo"]])
		if t.length() > MAX_LETRAS:
			_fallo("2: %s: %d letras: «%s»" % [c["id"], t.length(), t])
		for p in PROHIBIDAS:
			if RegEx.create_from_string("(?i)\\b%s\\b" % p).search(t) != null:
				_fallo("2: %s: «%s» dice «%s»" % [c["id"], t, p])
		# la intención de esta frase (CHARLAS_POSADA, «intenciones», en su orden): de quien habla
		var ints: Array = c.get("intenciones", [])
		if frases > ints.size() or not str(ints[frases - 1]).begins_with(nombre + ":"):
			_fallo("2: %s: «%s» no tiene su intención (de %s) en su sitio" % [c["id"], t, nombre])
		if GESTOS.has(quien) and not gesto.get(quien, false):
			_fallo("2: %s: «%s» (%s) no pide gesto" % [c["id"], t, quien])
		gesto[quien] = false
	if frases < 4 or frases > 6:
		_fallo("2: %s: %d frases (de 4 a 6)" % [c["id"], frases])
	if c.get("intenciones", []).size() != frases:
		_fallo("2: %s: %d intenciones para %d frases" % [c["id"], c.get("intenciones", []).size(), frases])
	if texto.contains("
#") or texto.begins_with("#"):
		_fallo("2: %s: lleva comentarios (Dialogic los imprime en la consola)" % c["id"])
	for q in c["grupo"]:
		if not hablan.has(q.to_lower()):
			_fallo("2: %s: %s está en el grupo y no dice nada" % [c["id"], q])
	print("CHARLA %s | %s | %d frases | %s" % [c["id"], c.get("hito", c.get("si", "")), frases, c["tema"]])


# 3. Recorrer cada charla con Dialogic.
func _al_evento(ev) -> void:
	if ev is DialogicTextEvent:
		var ch = ev.character
		eventos.append([ch.get_identifier() if ch != null else "", ev.text])


func _recorrer_todas() -> void:
	G.empezar_solo()
	G.unir("Lya")
	G.unir("Garon")
	for c in Oak.CHARLAS_POSADA:
		var ruta: String = Oak.ruta_charla(c["id"])
		eventos.clear()
		D.start(ruta)
		await _hasta(func(): return D.current_timeline != null, 5.0)
		var limite := Time.get_ticks_msec() + 20000
		var ultimo := 0
		while D.current_timeline != null and Time.get_ticks_msec() < limite:
			await process_frame
			var f := Engine.get_process_frames()
			if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and f - ultimo >= 4:
				D.Inputs.handle_input()
				ultimo = f
		if D.current_timeline != null:
			_fallo("3: %s no termina" % c["id"])
			D.end_timeline(true)
		await _esperar(4)
		var esperadas := 0
		for l in FileAccess.get_file_as_string(ruta).split("\n"):
			if RegEx.create_from_string("^(kael|lya|garon): ").search(l.strip_edges()) != null:
				esperadas += 1
		if eventos.size() != esperadas:
			_fallo("3: %s: Dialogic enseña %d frases y el archivo tiene %d" % [c["id"], eventos.size(), esperadas])
		for e in eventos:
			if e[0] == "" or not e[0].capitalize() in c["grupo"]:
				_fallo("3: %s: una frase sin personaje del grupo (%s)" % [c["id"], e[0]])
		print("RECORRIDA %s: %d frases" % [c["id"], eventos.size()])


# 4. Cuál toca.
func _cual_toca() -> void:
	_limpiar()
	G.empezar_solo()
	if Oak.charla_posada() != "":
		_fallo("4: sin hitos toca «%s»" % Oak.charla_posada())
	P.poner_hito("pv_03")
	if Oak.charla_posada() != "":
		_fallo("4: con Kael solo toca «%s»" % Oak.charla_posada())
	G.unir("Lya")
	if Oak.charla_posada() != "charla_conocerse":
		_fallo("4: con Lya y PV-03 toca «%s» y no charla_conocerse" % Oak.charla_posada())
	for h in ["pv_05", "pv_06", "pv_07"]:
		P.poner_hito(h)
	if Oak.charla_posada() != "charla_conocerse":
		_fallo("4: sin Garon en el grupo toca «%s»" % Oak.charla_posada())
	G.unir("Garon")
	var vistas: Array = []
	for i in 6:
		var id := Oak.charla_posada()
		if id == "":
			break
		vistas.append(id)
		var ruta := Oak.escena_al_despertar()
		if ruta != Oak.ruta_charla(id) or not Oak.charla_vista(id):
			_fallo("4: al despertar no sale %s o no queda vista (%s)" % [id, ruta])
	if vistas != ["charla_mano", "charla_miedo_garon", "charla_cama_grande", "charla_conocerse"]:
		_fallo("4: el orden de las charlas es %s" % [vistas])
	if Oak.escena_al_despertar() != Oak.escena_posada():
		_fallo("4: sin charlas nuevas no sale la escena de posada de siempre")
	P.poner_hito("oak_faroles")
	if Oak.charla_posada() != "charla_miedo_kael":
		_fallo("4: con «Los faroles de la ronda» hecha no toca charla_miedo_kael (%s)" % Oak.charla_posada())
	Oak.marcar_charla("charla_miedo_kael")
	Engine.set_meta("combates_ganados", {"garganta_nido": true})
	if Oak.charla_posada() != "charla_puentes":
		_fallo("4: tras el nido de la Garganta no toca charla_puentes (%s)" % Oak.charla_posada())
	Engine.set_meta("combates_ganados", {"garganta_nido": true, "garganta_gorthor": true})
	if Oak.charla_posada() != "charla_gorthor":
		_fallo("4: tras ganar a Gorthor no toca charla_gorthor (%s)" % Oak.charla_posada())
	print("ORDEN ", vistas)


# 5. Partidas antiguas.
func _partidas_antiguas() -> void:
	var base := {"grupo_activo": ["Kael", "Lya"], "hitos": {"pv_02": true, "pv_03": true}, "escena_guardada": "res://mapa.tscn"}
	_limpiar()
	P.restaurar(base.duplicate(true))               # sin «mazmorras»
	if Oak.charla_posada() != "charla_conocerse" or Oak.charla_vista("charla_conocerse"):
		_fallo("5: una partida sin «mazmorras» no tiene la charla sin ver (%s)" % Oak.charla_posada())
	var con_ciudad := base.duplicate(true)
	con_ciudad["mazmorras"] = {Oak.NOMBRE: {"noche_gratis": true, "favores": true}}
	_limpiar()
	P.restaurar(con_ciudad)                          # con la ciudad, sin ninguna charla
	if Oak.charla_posada() != "charla_conocerse":
		_fallo("5: una partida con la ciudad y sin charlas no tiene la charla sin ver")
	Oak.marcar_charla("charla_conocerse")
	_borrar()
	if not P.guardar("res://mapa.tscn"):
		_fallo("5: no se guarda la partida de prueba")
		return
	_limpiar()
	P.cargar()
	if not Oak.charla_vista("charla_conocerse"):
		_fallo("5: lo visto no se lee al cargar")
	if not P.estado(Oak.NOMBRE, "noche_gratis") or not P.estado(Oak.NOMBRE, "favores"):
		_fallo("5: al guardar lo visto se pierde lo demás de la ciudad")
	if Oak.charla_posada() != "":
		_fallo("5: tras cargar vuelve a tocar «%s»" % Oak.charla_posada())


# 6. En la ciudad.
func _en_la_ciudad() -> void:
	_limpiar()
	_borrar()
	G.empezar_solo()
	P.poner_hito("pv_03")
	G.unir("Lya")
	var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
	Engine.set_meta("lugar", {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == CIUDAD \
			and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("6: no se abre la ciudad")
		return
	var z = current_scene
	await _esperar(10)
	for noche in [Oak.ruta_charla("charla_conocerse"), Oak.escena_posada()]:
		load("res://inventario.gd").ganar_oro(100)
		z._posada()
		if not await _hasta(func(): return D.current_timeline != null, 8.0):
			_fallo("6: al descansar no empieza ningún diálogo")
			return
		var ruta: String = D.current_timeline.resource_path
		if ruta != noche:
			_fallo("6: al descansar sale %s y no %s" % [ruta, noche])
		else:
			print("POSADA ", ruta.get_file())
		await _hasta(func(): return D.current_state == D.States.IDLE, 5.0)
		await _esperar(10)
		D.end_timeline(true)
		await _esperar(10)
	if not Oak.charla_vista("charla_conocerse"):
		_fallo("6: la charla de la posada no queda vista")
