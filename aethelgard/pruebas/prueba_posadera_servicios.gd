extends SceneTree
# «¿Algo más?» de la posadera en la ciudad 2D (dialogos/oakhaven/oak_posadera_servicios.dtl, ciudades/oakhaven_posada.gd
# y ciudad_oakhaven.gd). Sin ventana, con «-- sin_prologo». Partida propia (user://prueba_posadera_servicios.save).
#   1. Hablando con la posadera, en su turno sale la pregunta (después de sus otros diálogos de siempre).
#   2. «Sopa del día»: cobra 10 monedas, recupera los PV y no los PM, avisa con la sopa del día y la partida se guarda.
#   3. «Un rumor»: al acabar, la posadera cuenta el primer rumor sin oír en su caja de diálogo, y queda oído; la vez
#      siguiente, el siguiente.
#   4. «Nada, gracias»: no cobra ni cambia nada.
#   5. Sin monedas, la sopa no se cobra ni cura, y lo dice.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const Posada := preload("res://ciudades/oakhaven_posada.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_posadera_servicios.save"
const SERVICIOS := "res://dialogos/oakhaven/oak_posadera_servicios.dtl"

var P
var G
var I
var R
var D
var fallos: Array = []
var pregunta := false
var frases: Array = []


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
	I = load("res://inventario.gd")
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	if D == null:
		_fallo("hace falta Dialogic")
		_terminar()
		return
	D.Choices.question_shown.connect(func(_i): pregunta = true)
	D.event_handled.connect(func(ev):
		if ev is DialogicTextEvent:
			frases.append(ev.text))
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	G.empezar_solo()
	P.poner_hito("oak_favores")                  # (con la misión en curso, sus diálogos de la misión van primero)
	var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
	Engine.set_meta("lugar", {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == CIUDAD \
			and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("no se abre la ciudad")
		_terminar()
		return
	var z = current_scene
	await _esperar(10)
	await _turno(z)
	await _sopa(z)
	await _rumores(z)
	await _nada(z)
	await _sin_monedas(z)
	_terminar()


func _terminar() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _posadera(z) -> Array:
	for n in z.npcs:
		if n[1]["id"] == "posadera":
			return n
	return []


# Habla con la posadera (como un jugador: a su lado, el botón y pulsar) y recorre lo que salga eligiendo «opcion».
# Devuelve la ruta del diálogo que se abrió.
func _hablar(z, opcion: int) -> String:
	var n := _posadera(z)
	z.jugador.position = n[0].position + Vector2(40, 30)
	await _esperar(3)
	z._comprobar_cerca()
	z._accion()
	if not await _hasta(func(): return D.current_timeline != null, 5.0):
		_fallo("hablar con la posadera no abre ningún diálogo")
		return ""
	var ruta: String = D.current_timeline.resource_path
	await _recorrer(opcion)
	return ruta


func _recorrer(opcion: int) -> void:
	pregunta = false
	var limite := Time.get_ticks_msec() + 20000
	var ultimo := 0
	while D.current_timeline != null and Time.get_ticks_msec() < limite:
		await process_frame
		var f := Engine.get_process_frames()
		if pregunta:
			await _esperar(10)
			pregunta = false
			D.Choices.select_choice(opcion)
			ultimo = Engine.get_process_frames()
			continue
		if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and f - ultimo >= 4:
			D.Inputs.handle_input()
			ultimo = f
	if D.current_timeline != null:
		_fallo("un diálogo no termina")
		D.end_timeline(true)
	await _esperar(6)


# Hasta su turno: los diálogos de siempre se turnan y la pregunta va la última.
func _a_su_turno(z) -> void:
	var n := _posadera(z)
	for i in 6:
		if Oak.dialogo_de("posadera", n[2]) == SERVICIOS:
			return
		await _hablar(z, 1)
	_fallo("1: la pregunta de los servicios no llega en el turno de la posadera")


func _turno(z) -> void:
	var vistos: Array = []
	var n := _posadera(z)
	for i in 4:
		vistos.append(Oak.dialogo_de("posadera", n[2] + i).get_file())
	if not "oak_posadera_servicios.dtl" in vistos:
		_fallo("1: en cuatro charlas con la posadera no sale «¿Algo más?» (%s)" % [vistos])
	print("TURNO ", vistos)


func _herir() -> void:
	for h in G.activos():
		G.guardar_vida(h, 1, 0)


func _sopa(z) -> void:
	await _a_su_turno(z)
	I.ganar_oro(100 - I.oro())
	_herir()
	var ruta := await _hablar(z, 1)
	if ruta != SERVICIOS:
		_fallo("2: se abre %s y no la pregunta" % ruta)
	var e: Dictionary = G.estadisticas("Kael")
	if I.oro() != 100 - Posada.PRECIO_COMER:
		_fallo("2: la sopa no cobra %d (oro %d)" % [Posada.PRECIO_COMER, I.oro()])
	if int(G.datos()["Kael"]["pv"]) != e["pv_max"] or int(G.datos()["Kael"]["pm"]) != 0:
		_fallo("2: la sopa no deja PV llenos y PM como estaban (%s)" % [G.datos()["Kael"]])
	if not await _hasta(func(): return Posada.sopa_del_dia() in z.aviso.text and z.aviso.modulate.a > 0.5, 5.0):
		_fallo("2: no sale el aviso de la sopa («%s»)" % z.aviso.text)
	print("SOPA: ", z.aviso.text)


func _rumores(z) -> void:
	for vez in 2:
		await _a_su_turno(z)
		var esperado: Dictionary = Posada.rumores_disponibles()[0]
		frases.clear()
		await _hablar(z, 2)
		if not await _hasta(func(): return D.current_timeline != null, 5.0):
			_fallo("3: tras pedir un rumor, la posadera no lo cuenta")
			return
		await _recorrer(1)
		if not esperado["texto"] in frases:
			_fallo("3: la posadera no cuenta «%s» (dijo %s)" % [esperado["texto"], frases])
		if not Posada.rumor_oido(esperado["id"]):
			_fallo("3: el rumor %s no queda oído" % esperado["id"])
		print("RUMOR %d: %s" % [vez + 1, esperado["texto"]])


func _nada(z) -> void:
	await _a_su_turno(z)
	var oro: int = I.oro()
	var oidos: Array = Posada.RUMORES.filter(func(r): return Posada.rumor_oido(r["id"]))
	await _hablar(z, 3)
	await _esperar(20)
	if I.oro() != oro or D.current_timeline != null \
			or Posada.RUMORES.filter(func(r): return Posada.rumor_oido(r["id"])).size() != oidos.size():
		_fallo("4: «Nada, gracias» cambia algo (oro %d → %d)" % [oro, I.oro()])


func _sin_monedas(z) -> void:
	await _a_su_turno(z)
	I.gastar_oro(I.oro())
	_herir()
	await _hablar(z, 1)
	if int(G.datos()["Kael"]["pv"]) != 1:
		_fallo("5: sin monedas, la sopa cura igual")
	if not await _hasta(func(): return "No te llega" in z.aviso.text, 5.0):
		_fallo("5: sin monedas no lo dice («%s»)" % z.aviso.text)
