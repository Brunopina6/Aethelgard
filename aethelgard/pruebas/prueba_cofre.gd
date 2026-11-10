extends SceneTree
# Prueba: abre un cofre y cruza el río por un puente (y comprueba que fuera del puente el agua bloquea).
# (10/11: con aserciones; antes solo imprimía.)

var z: Node
var frames := 0
var paso := 0
var desde := Vector2.ZERO
var objetivo := Vector2.ZERO
var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _terminar() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true




func _initialize() -> void:
	z = load("res://zona.tscn").instantiate()
	root.add_child(z)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 4:
		var inv = load("res://inventario.gd")
		var c: Array = z.cofres[0]
		z.jugador.position = c[0].position + Vector2(0, 60)
		z._comprobar_cerca()
		var oro_antes: int = inv.oro()
		var obj_antes: Dictionary = inv.datos()["objetos"].duplicate()
		print("botón: ", z.boton_examinar.text)
		z._accion()
		print("cofre abierto=", c[2], "  oro ", oro_antes, " -> ", inv.oro(), "  objetos ", obj_antes, " -> ", inv.datos()["objetos"])
		if not c[2]:
			_fallo("el cofre no queda abierto")
		if inv.oro() <= oro_antes and inv.datos()["objetos"] == obj_antes:
			_fallo("el cofre no da nada (ni oro ni objetos)")
		z._comprobar_cerca()
		print("después, botón: ", z.boton_examinar.text if z.boton_examinar.visible else "(oculto)")
		if z.boton_examinar.visible and "Abrir" in z.boton_examinar.text:
			_fallo("un cofre abierto se puede volver a abrir")
		# cruzar el primer puente
		var pu: Array = z.puentes[0]
		desde = pu[0] - pu[1] * (pu[2] * 0.5 + 60.0)
		objetivo = pu[0] + pu[1] * (pu[2] * 0.5 + 60.0)
		z.jugador.position = desde
		z.destino = objetivo
		z.tiene_destino = true
		print("en el centro del puente: agua=", z._peso(z.agua_v, pu[0] / z.T) > 0.55, "  bloquea=", z._en_agua(pu[0]))
		if z._en_agua(pu[0]):
			_fallo("el centro del puente bloquea el paso")
	if frames > 4 and frames % 60 == 0 and frames < 700:
		var p: Vector2 = z.jugador.position
		var pu: Array = z.puentes[0]
		var dd: Vector2 = p - pu[0]
		print("f", frames, " a lo largo ", int(dd.dot(pu[1])), " de lado ", int(dd.dot(pu[1].orthogonal())), " agua ", z._en_agua(p), " destino ", z.tiene_destino)
	if frames == 700:
		print("cruza el puente: ", z.jugador.position.distance_to(objetivo) < 40.0, " (queda ", int(z.jugador.position.distance_to(objetivo)), " px)")
		if z.jugador.position.distance_to(objetivo) >= 40.0:
			_fallo("no cruza el puente (quedan %d px)" % int(z.jugador.position.distance_to(objetivo)))
		return _terminar()
	return false
