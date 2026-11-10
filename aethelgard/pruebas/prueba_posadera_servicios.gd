extends SceneTree
# «¿Qué va a ser?»: el botón POSADA de la ciudad 2D pregunta antes de descansar (ciudades/oakhaven_posada.gd,
# menu_dialogo; ciudad_oakhaven.gd, _boton_posada; zona.gd, _boton_posada). Sin ventana, con «-- sin_prologo». Partida
# propia (user://prueba_posadera_servicios.save). No hace falta la misión de la posadera: va con «Tres favores» sin
# empezar.
#   1. Pulsar POSADA abre la pregunta (no descansa todavía); hablar con la posadera ya no la saca.
#   2. «Dormir»: al acabar la pregunta, descansa como siempre (cobra 30, cura, escena al despertar); con la noche gratis,
#      la opción lo dice y no cobra.
#   3. «Sopa del día»: cobra 10, recupera los PV y no los PM, y avisa con la sopa del día.
#   4. «Un rumor»: al acabar, la posadera cuenta el primer rumor sin oír en su caja, y queda oído; luego, el siguiente.
#   5. «Nada, gracias»: no cobra ni cambia nada.
#   6. Sin monedas, la sopa no se cobra ni cura, y lo dice.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const Posada := preload("res://ciudades/oakhaven_posada.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_posadera_servicios.save"
const DORMIR := 1
const SOPA := 2
const RUMOR := 3
const NADA := 4

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
	await _boton(z)
	await _dormir(z)
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


# Pulsa POSADA (el botón de verdad) y recorre la pregunta eligiendo «opcion».
func _posada(z, opcion: int) -> void:
	frases.clear()
	z._boton_hud("POSADA").pressed.emit()
	if not await _hasta(func(): return D.current_timeline != null, 5.0):
		_fallo("POSADA no abre la pregunta")
		return
	await _recorrer(opcion)


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


func _herir() -> void:
	for h in G.activos():
		G.guardar_vida(h, 1, 0)


# 1. El botón pregunta; hablar con la posadera, no.
func _boton(z) -> void:
	var oro: int = I.oro()
	z._boton_hud("POSADA").pressed.emit()
	if not await _hasta(func(): return D.current_timeline != null, 5.0):
		_fallo("1: POSADA no abre la pregunta")
		return
	await _hasta(func(): return frases.any(func(t): return "¿Qué va a ser?" in t), 5.0)
	if not frases.any(func(t): return "¿Qué va a ser?" in t):
		_fallo("1: la posadera no pregunta «¿Qué va a ser?» (%s)" % [frases])
	if I.oro() != oro:
		_fallo("1: al pulsar POSADA ya se cobra la noche")
	await _recorrer(NADA)
	for v in 4:
		if Oak.dialogo_de("posadera", v).ends_with("oak_posadera_servicios.dtl"):
			_fallo("1: hablar con la posadera aún saca la pregunta")
	print("BOTÓN: ", frases)


# 2. Dormir.
func _dormir(z) -> void:
	I.ganar_oro(100 - I.oro())
	_herir()
	if not "Dormir (%d monedas)" % Posada.PRECIO_DORMIR in Posada.menu_dialogo():
		_fallo("2: la pregunta no dice el precio de la noche")
	await _posada(z, DORMIR)
	if not await _hasta(func(): return D.current_timeline != null, 6.0):     # la escena al despertar
		_fallo("2: «Dormir» no lleva a descansar")
		return
	var e: Dictionary = G.estadisticas("Kael")
	if I.oro() != 100 - Posada.PRECIO_DORMIR or int(G.datos()["Kael"]["pv"]) != e["pv_max"] \
			or int(G.datos()["Kael"]["pm"]) != e["pm_max"]:
		_fallo("2: «Dormir» no cobra %d o no cura (oro %d, %s)" % [Posada.PRECIO_DORMIR, I.oro(), G.datos()["Kael"]])
	if D.current_timeline.resource_path != Oak.escena_posada():
		_fallo("2: al despertar sale %s" % D.current_timeline.resource_path)
	await _recorrer(1)
	P.poner_estado(Oak.NOMBRE, "noche_gratis")
	if not "Dormir (invita la casa)" in Posada.menu_dialogo():
		_fallo("2: con la noche gratis, la opción no lo dice")
	var oro: int = I.oro()
	await _posada(z, DORMIR)
	await _hasta(func(): return D.current_timeline != null, 6.0)
	if I.oro() != oro or P.estado(Oak.NOMBRE, "noche_gratis"):
		_fallo("2: la noche gratis cobra o no se gasta (oro %d → %d)" % [oro, I.oro()])
	await _recorrer(1)
	await _esperar(30)
	print("DORMIR: oro %d" % I.oro())


# 3. Sopa.
func _sopa(z) -> void:
	I.ganar_oro(100 - I.oro())
	_herir()
	await _posada(z, SOPA)
	var e: Dictionary = G.estadisticas("Kael")
	if I.oro() != 100 - Posada.PRECIO_COMER:
		_fallo("3: la sopa no cobra %d (oro %d)" % [Posada.PRECIO_COMER, I.oro()])
	if int(G.datos()["Kael"]["pv"]) != e["pv_max"] or int(G.datos()["Kael"]["pm"]) != 0:
		_fallo("3: la sopa no deja PV llenos y PM como estaban (%s)" % [G.datos()["Kael"]])
	if not await _hasta(func(): return Posada.sopa_del_dia() in z.aviso.text and z.aviso.modulate.a > 0.5, 5.0):
		_fallo("3: no sale el aviso de la sopa («%s»)" % z.aviso.text)
	print("SOPA: ", z.aviso.text)


# 4. Rumores.
func _rumores(z) -> void:
	for vez in 2:
		var esperado: Dictionary = Posada.rumores_disponibles()[0]
		await _posada(z, RUMOR)
		if not await _hasta(func(): return D.current_timeline != null, 5.0):
			_fallo("4: tras pedir un rumor, la posadera no lo cuenta")
			return
		await _recorrer(1)
		if not esperado["texto"] in frases:
			_fallo("4: la posadera no cuenta «%s» (dijo %s)" % [esperado["texto"], frases])
		if not Posada.rumor_oido(esperado["id"]):
			_fallo("4: el rumor %s no queda oído" % esperado["id"])
		print("RUMOR %d: %s" % [vez + 1, esperado["texto"]])


# 5. Nada.
func _nada(z) -> void:
	var oro: int = I.oro()
	var oidos: int = Posada.RUMORES.filter(func(r): return Posada.rumor_oido(r["id"])).size()
	await _posada(z, NADA)
	await _esperar(20)
	if I.oro() != oro or D.current_timeline != null \
			or Posada.RUMORES.filter(func(r): return Posada.rumor_oido(r["id"])).size() != oidos:
		_fallo("5: «Nada, gracias» cambia algo (oro %d → %d)" % [oro, I.oro()])


# 6. Sin monedas.
func _sin_monedas(z) -> void:
	I.gastar_oro(I.oro())
	_herir()
	await _posada(z, SOPA)
	if int(G.datos()["Kael"]["pv"]) != 1:
		_fallo("6: sin monedas, la sopa cura igual")
	if not await _hasta(func(): return "No te llega" in z.aviso.text, 5.0):
		_fallo("6: sin monedas no lo dice («%s»)" % z.aviso.text)
