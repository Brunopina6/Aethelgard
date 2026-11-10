extends SceneTree
# Diálogos y avisos de «El bosque que no recuerda» (fase 3, narrativa, 10/11; docs/fase3_bosque/AVENTURA_JUGABLE.md).
# Sin ventana. No guarda nada.
#   1. Registro: los 15 diálogos de la tabla están en dialogic/directories/dtl_directory con su ruta, existen y se
#      cargan; el Guardián (guardian_bosque.dch) está en dch_directory y se carga.
#   2. Texto: de 2 a 6 frases; solo hablan los presentes (en el bosque, Kael, Lya, Garon, Tilo y el Guardián; con Doña
#      Encina, ella); cada frase cabe en la caja (110 letras como mucho); Kael y Lya piden un gesto de la lista antes de
#      cada frase suya; sin comentarios; nada de Érebo ni de corazones o recuerdos, ni nombres de Final Fantasy X.
#   3. Cada diálogo se abre por su nombre con Dialogic y se recorre entero: tantas frases como el archivo, cada una con
#      su personaje.
#   4. Avisos (dialogos/notas/bosque.gd, TEXTOS): las claves exactas, frases cortas, sin palabras prohibidas, y
#      «objetivo_pistas» con un %d que se rellena.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const DIALOGOS := {
	"bq_tilo_1": "bosque", "bq_arbol": "bosque", "bq_pista_planta": "bosque", "bq_pista_rastro": "bosque",
	"bq_senda": "bosque", "bq_pista_inscripcion": "bosque", "bq_pistas": "bosque", "bq_guardian": "bosque",
	"bq_purificado": "bosque", "bq_derrotado": "bosque", "bq_tilo_durante": "bosque", "bq_tilo_purificado": "bosque",
	"bq_tilo_derrotado": "bosque", "oak_encina_bosque_purificado": "oakhaven", "oak_encina_bosque_derrotado": "oakhaven"}
const PRESENTES := {"bosque": ["kael", "lya", "garon", "tilo", "guardian_bosque"], "oakhaven": ["encina", "kael"]}
const GRUPO_TRES := ["bq_guardian", "bq_purificado", "bq_derrotado"]     # con Kael, Lya y Garon: los tres hablan
const GESTOS := {"kael": ["ligero", "brazalete", "sorpresa", "decidido", "duda"],
	"lya": ["inquieta", "preocupada", "decidida", "duda", "firme"]}
const PROHIBIDAS := ["érebo", "erebo", "corazón", "corazones", "recuerdo", "recuerdos", "memoria", "tidus", "yuna",
	"spira", "sinh"]
const MAX_LETRAS := 110
const NOTAS := "res://dialogos/notas/bosque.gd"
const CLAVES := ["arbol_marcado", "rec_hierba_lunar", "rec_musgo_piedra", "rec_savia_clara", "ramas_bloqueadas",
	"manantial", "manantial_ya", "ciervo", "cofre_senda", "guardian_dormido_pronto", "claro_purificado",
	"claro_derrotado", "elixir_fase1", "purificacion", "fase2", "objetivo_pistas"]

var D
var fallos: Array = []
var eventos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _hasta(cond: Callable, segundos := 10.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _ruta(nombre: String) -> String:
	return "res://dialogos/%s/%s.dtl" % [DIALOGOS[nombre], nombre]


func _probar() -> void:
	_registro()
	for n in DIALOGOS:
		if FileAccess.file_exists(_ruta(n)):
			_revisar_texto(n, FileAccess.get_file_as_string(_ruta(n)))
	_avisos()
	D = root.get_node_or_null("Dialogic")
	if D == null:
		_fallo("3: hace falta Dialogic")
	else:
		D.timeline_started.connect(func(): eventos.clear())
		D.event_handled.connect(_al_evento)
		for n in DIALOGOS:
			await _recorrer(n)
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Registro.
func _registro() -> void:
	var dtl: Dictionary = ProjectSettings.get_setting("dialogic/directories/dtl_directory", {})
	var dch: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	for n in DIALOGOS:
		if dtl.get(n, "") != _ruta(n):
			_fallo("1: %s no está registrado con %s (está: «%s»)" % [n, _ruta(n), dtl.get(n, "")])
		if not ResourceLoader.exists(_ruta(n)):
			_fallo("1: no existe %s" % _ruta(n))
		elif not load(_ruta(n)) is DialogicTimeline:
			_fallo("1: %s no se carga como línea de tiempo" % _ruta(n))
	var ruta_g := "res://dialogos/personajes/guardian_bosque.dch"
	if dch.get("guardian_bosque", "") != ruta_g:
		_fallo("1: guardian_bosque no está en dch_directory")
	var g = load(ruta_g) if ResourceLoader.exists(ruta_g) else null
	if not g is DialogicCharacter:
		_fallo("1: guardian_bosque.dch no se carga como personaje")
	else:
		print("PERSONAJE guardian_bosque: %s" % g.display_name)
	for q in PRESENTES["bosque"] + PRESENTES["oakhaven"]:
		if not dch.has(q):
			_fallo("1: el personaje %s no está registrado" % q)


# 2. Texto.
func _revisar_texto(n: String, texto: String) -> void:
	var frases := 0
	var hablan := {}
	var gesto := {}
	var re_gesto := RegEx.create_from_string("^update (\\w+) \\[extra_data=\"(\\w+)\"\\]$")
	var re_frase := RegEx.create_from_string("^(\\w+): (.+)$")
	for linea in texto.split("\n"):
		var l := linea.strip_edges()
		if l == "":
			continue
		if l.begins_with("#"):
			_fallo("2: %s lleva comentarios (Dialogic los imprime en la consola)" % n)
			continue
		if l.begins_with("join ") or l.begins_with("leave "):
			var quien_j := l.split(" ")[1]
			if not quien_j in ["kael", "lya"]:
				_fallo("2: %s: «%s» (solo Kael y Lya tienen retrato vivo)" % [n, l])
			continue
		if l.begins_with("[signal arg=\"oak:"):         # la señal de Oakhaven que marca el diálogo como dicho (fase 3)
			continue
		var m := re_gesto.search(l)
		if m != null:
			if not m.get_string(2) in GESTOS.get(m.get_string(1), []):
				_fallo("2: %s: gesto «%s» de %s no está en la lista" % [n, m.get_string(2), m.get_string(1)])
			gesto[m.get_string(1)] = true
			continue
		var f := re_frase.search(l)
		if f == null:
			_fallo("2: %s: línea que no es una frase ni un evento conocido: «%s»" % [n, l])
			continue
		var quien := f.get_string(1)
		var t := f.get_string(2)
		frases += 1
		hablan[quien] = true
		if not quien in PRESENTES[DIALOGOS[n]]:
			_fallo("2: %s: habla %s, que no está presente" % [n, quien])
		if t.length() > MAX_LETRAS:
			_fallo("2: %s: %d letras: «%s»" % [n, t.length(), t])
		for p in PROHIBIDAS:
			if RegEx.create_from_string("(?i)\\b%s\\b" % p).search(t) != null:
				_fallo("2: %s: «%s» dice «%s»" % [n, t, p])
		if t.contains("[") or t.contains("{"):
			_fallo("2: %s: «%s» lleva corchetes o llaves (Dialogic los interpreta)" % [n, t])
		if GESTOS.has(quien) and DIALOGOS[n] == "bosque" and not gesto.get(quien, false):
			_fallo("2: %s: «%s» (%s) no pide gesto" % [n, t, quien])
		gesto[quien] = false
	if frases < 2 or frases > 6:
		_fallo("2: %s: %d frases (de 2 a 6)" % [n, frases])
	if n in GRUPO_TRES:
		for q in ["kael", "lya", "garon"]:
			if not hablan.has(q):
				_fallo("2: %s: %s está en el grupo y no dice nada" % [n, q])
	print("TEXTO %s | %d frases | hablan %s" % [n, frases, ", ".join(hablan.keys())])


# 3. Recorrer cada diálogo con Dialogic, abierto por su nombre.
func _al_evento(ev) -> void:
	if ev is DialogicTextEvent:
		var ch = ev.character
		eventos.append([ch.get_identifier() if ch != null else "", ev.text])


func _recorrer(n: String) -> void:
	eventos.clear()
	D.start(n)
	if not await _hasta(func(): return D.current_timeline != null, 5.0):
		_fallo("3: %s no se abre por su nombre" % n)
		return
	var limite := Time.get_ticks_msec() + 20000
	var ultimo := 0
	while D.current_timeline != null and Time.get_ticks_msec() < limite:
		await process_frame
		var fr := Engine.get_process_frames()
		if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and fr - ultimo >= 4:
			D.Inputs.handle_input()
			ultimo = fr
	if D.current_timeline != null:
		_fallo("3: %s no termina" % n)
		D.end_timeline(true)
	for i in 4:
		await process_frame
	var esperadas := 0
	var re := RegEx.create_from_string("^(\\w+): ")
	for l in FileAccess.get_file_as_string(_ruta(n)).split("\n"):
		if re.search(l.strip_edges()) != null:
			esperadas += 1
	if eventos.size() != esperadas:
		_fallo("3: %s: Dialogic enseña %d frases y el archivo tiene %d" % [n, eventos.size(), esperadas])
	for e in eventos:
		if e[0] == "" or not e[0] in PRESENTES[DIALOGOS[n]]:
			_fallo("3: %s: una frase sin personaje presente («%s»: %s)" % [n, e[0], e[1]])
	print("RECORRIDO %s: %d frases" % [n, eventos.size()])


# 4. Avisos de la región.
func _avisos() -> void:
	if not ResourceLoader.exists(NOTAS):
		_fallo("4: falta %s" % NOTAS)
		return
	var textos: Dictionary = load(NOTAS).TEXTOS
	for k in CLAVES:
		if not textos.has(k):
			_fallo("4: falta la clave «%s»" % k)
	for k in textos:
		if not k in CLAVES:
			_fallo("4: clave de más «%s»" % k)
		var t: String = textos[k]
		if t.strip_edges() == "" or t.length() > 90:
			_fallo("4: «%s» vacío o largo (%d letras): «%s»" % [k, t.length(), t])
		for p in PROHIBIDAS:
			if RegEx.create_from_string("(?i)\\b%s\\b" % p).search(t) != null:
				_fallo("4: «%s» dice «%s»" % [k, p])
		print("AVISO %s: %s" % [k, t])
	var o: String = textos.get("objetivo_pistas", "")
	if o.count("%d") != 1 or o.count("%") != 1:
		_fallo("4: objetivo_pistas necesita un solo %%d: «%s»" % o)
	else:
		print("OBJETIVO con 2: %s" % (o % 2))
