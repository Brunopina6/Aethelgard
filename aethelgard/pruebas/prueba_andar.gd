extends SceneTree
# Prueba: carga una escena (zona o mapa) y hace correr al jugador a la derecha, abajo, izquierda,
# arriba y luego lo deja quieto, pulsando las flechas. Se graba con --write-movie.

var esc: Node
var frames := 0
const PLAN := [["ui_right", 12], ["ui_down", 12], ["ui_left", 12], ["ui_up", 12], ["", 12]]


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
	if i >= PLAN.size():
		return true
	for a in ["ui_right", "ui_down", "ui_left", "ui_up"]:
		Input.action_release(a)
	if PLAN[i][0] != "":
		Input.action_press(PLAN[i][0])
	if t % 12 == 6:
		print("paso ", i, " anim ", esc.sprite.animation, " frame ", esc.sprite.frame, " pos ", esc.jugador.position.round(),
			" destino ", esc.tiene_destino, " vector ", Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	return false
