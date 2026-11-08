extends SceneTree
# Prueba del botón de desarrollo «Probar el prólogo (partida nueva)» de la pantalla de carga (carga.gd, T-081), con la
# exploración 3D activa («-- 3d») y teclas simuladas (Input.parse_input_event; no es hardware real). Con una partida
# experimental «de verdad» ya guardada en la carpeta aislada de la pasada:
#   1. Con la carga lista se ven los dos botones de prueba. ↓ sigue eligiendo «Probar la misión desde el principio»;
#      ← pasa al del prólogo y → vuelve; ↑ suelta el foco.
#   2. Intro en «Probar el prólogo»: partida nueva en la ranura de prueba (su propio archivo), Kael solo, en el mapa, y
#      el prólogo empieza con su puesta en escena (escena_dialogo.gd).
#   3. La partida de siempre no cambia.

const CARGA := "res://carga.tscn"
const MAPA := "res://mapa.tscn"

var P
var fallos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _tecla(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _esperar(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _esperar(3)


func _probar() -> void:
	P = load("res://progreso.gd")
	if not load("res://modo3d.gd").activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		quit(1)
		return
	for k in ["archivo_partida_prueba", "ranura_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	# la partida experimental «de verdad» (en la carpeta aislada), que no debe cambiar
	var siempre := {"grupo": load("res://grupo.gd").datos().duplicate(true), "hitos": {"pv_02": true, "pv_03": true},
		"grupo_activo": ["Kael", "Lya"], "escena_guardada": "res://mapa.tscn", "prologo_visto": true}
	P.escribir(siempre, P.GUARDADO_EXP)
	var huella := FileAccess.get_file_as_string(P.GUARDADO_EXP)

	# 1. La carga y sus dos botones
	change_scene_to_file(CARGA)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == CARGA \
			and current_scene.listo and current_scene.boton_prologo != null and current_scene.boton_prologo.visible, 180.0):
		_fallo("1: la pantalla de carga no termina o no enseña el botón del prólogo")
		_terminar()
		return
	var c = current_scene
	await _esperar(5)
	if not c.boton_prueba.visible:
		_fallo("1: falta el botón «Probar la misión desde el principio»")
	if c.boton_prologo.get_global_rect().intersects(c.boton_prueba.get_global_rect()):
		_fallo("1: los dos botones de prueba se tapan")
	await _tecla(KEY_DOWN)
	if not c.boton_prueba.has_focus():
		_fallo("1: ↓ ya no elige «Probar la misión desde el principio»")
	await _tecla(KEY_LEFT)
	if not c.boton_prologo.has_focus():
		_fallo("1: ← no pasa al botón del prólogo")
	await _tecla(KEY_RIGHT)
	if not c.boton_prueba.has_focus():
		_fallo("1: → no vuelve al botón de la misión")
	await _tecla(KEY_UP)
	if c.boton_prueba.has_focus() or c.boton_prologo.has_focus():
		_fallo("1: ↑ no suelta el foco")
	if current_scene != c:
		_fallo("1: moverse entre los botones ha empezado la partida")

	# 2. Intro en el del prólogo
	await _tecla(KEY_LEFT)
	await _tecla(KEY_ENTER)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == MAPA \
			and current_scene.get("escena_dialogo") != null, 60.0):
		_fallo("2: «Probar el prólogo» no lleva al mapa con el prólogo (escena: %s)" % \
			(current_scene.scene_file_path if current_scene != null else "?"))
	else:
		if not Engine.get_meta("ranura_prueba", false) or P.archivo() != P.GUARDADO_EXP_PRUEBA:
			_fallo("2: la partida del prólogo no va a la ranura de prueba (%s)" % P.archivo())
		if load("res://grupo.gd").activos() != ["Kael"]:
			_fallo("2: la partida del prólogo no es nueva (grupo: %s)" % [load("res://grupo.gd").activos()])
		if P.hito("pv_02"):
			_fallo("2: la partida del prólogo trae hitos de la de siempre")

	# 3. La partida de siempre, intacta
	if FileAccess.get_file_as_string(P.GUARDADO_EXP) != huella:
		_fallo("3: la partida de siempre ha cambiado")
	_terminar()


func _terminar() -> void:
	print("OK botón del prólogo: dos botones sin taparse, ↓ ← → ↑ como se espera; partida nueva en la ranura de prueba, en el mapa con el prólogo; la de siempre intacta")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
