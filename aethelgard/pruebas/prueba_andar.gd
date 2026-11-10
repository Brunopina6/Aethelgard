extends SceneTree
# Prueba: carga una escena (zona o mapa) y hace correr al jugador a la derecha, abajo, izquierda,
# arriba y luego lo deja quieto, pulsando las flechas. Se graba con --write-movie.

var esc: Node
var frames := 0
const PLAN := [["ui_right", 12], ["ui_down", 12], ["ui_left", 12], ["ui_up", 12], ["", 12]]
# (10/11) dirección que debe tener el desplazamiento de cada tramo, y «quieto» al final
const ESPERADO := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2.ZERO]
var inicio_tramo := Vector2.ZERO
var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _terminar() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true




func _initialize() -> void:
	var nombre := "zona"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("escena="):
			nombre = a.substr(7)
	esc = load("res://%s.tscn" % nombre).instantiate()
	root.add_child(esc)


func _process(_d: float) -> bool:
	frames += 1
	var t := frames - 8
	if t < 0:
		return false
	var i := t / 12
	if t % 12 == 0:
		if i > 0:
			var d: Vector2 = esc.jugador.position - inicio_tramo
			var e: Vector2 = ESPERADO[i - 1]
			if e == Vector2.ZERO and d.length() > 6.0:
				_fallo("tramo %d: sin flechas, Kael sigue moviéndose (%s)" % [i - 1, d.round()])
			elif e != Vector2.ZERO and d.dot(e) < 15.0:
				_fallo("tramo %d (%s): Kael no avanza hacia ese lado (%s)" % [i - 1, PLAN[i - 1][0], d.round()])
		inicio_tramo = esc.jugador.position
	if i >= PLAN.size():
		return _terminar()
	for a in ["ui_right", "ui_down", "ui_left", "ui_up"]:
		Input.action_release(a)
	if PLAN[i][0] != "":
		Input.action_press(PLAN[i][0])
	if t % 12 == 6:
		print("paso ", i, " anim ", esc.sprite.animation, " frame ", esc.sprite.frame, " pos ", esc.jugador.position.round(),
			" destino ", esc.tiene_destino, " vector ", Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	return false
