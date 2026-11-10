extends SceneTree
# Botones del teléfono (10/11, visto en el Redmi: bajar el volumen pasaba los textos a «teclado»): volumen, atrás,
# menú, encendido, multimedia y teclas sin código (como el sensor de huellas) no cambian el modo de entrada; una tecla
# de verdad sí, y el dedo vuelve a «puntero». Usa el autoload Entrada (entrada.gd) sin escenas.

var fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _tecla(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	return e


func _probar() -> void:
	var E = root.get_node("Entrada")
	E.modo = "puntero"
	for k in [KEY_VOLUMEDOWN, KEY_VOLUMEUP, KEY_VOLUMEMUTE, KEY_BACK, KEY_MENU, KEY_STANDBY, KEY_MEDIAPLAY, KEY_UNKNOWN]:
		E._mirar(_tecla(k))
		if E.modo != "puntero":
			fallos += 1
			print("FALLO: la tecla del sistema %s cambió el modo a «%s»" % [OS.get_keycode_string(k), E.modo])
			E.modo = "puntero"
	E._mirar(_tecla(KEY_A))
	if E.modo != "teclado":
		fallos += 1
		print("FALLO: una tecla de verdad (A) no pasa a «teclado»")
	var t := InputEventScreenTouch.new()
	t.pressed = true
	E._mirar(t)
	if E.modo != "puntero":
		fallos += 1
		print("FALLO: tocar la pantalla no vuelve a «puntero»")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
