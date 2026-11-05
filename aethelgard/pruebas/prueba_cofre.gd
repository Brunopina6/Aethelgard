extends SceneTree
# Prueba: abre un cofre y cruza el río por un puente (y comprueba que fuera del puente el agua bloquea).

var z: Node
var frames := 0
var paso := 0
var desde := Vector2.ZERO
var objetivo := Vector2.ZERO


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
		z._comprobar_cerca()
		print("después, botón: ", z.boton_examinar.text if z.boton_examinar.visible else "(oculto)")
		# cruzar el primer puente
		var pu: Array = z.puentes[0]
		desde = pu[0] - pu[1] * (pu[2] * 0.5 + 60.0)
		objetivo = pu[0] + pu[1] * (pu[2] * 0.5 + 60.0)
		z.jugador.position = desde
		z.destino = objetivo
		z.tiene_destino = true
		print("en el centro del puente: agua=", z._peso(z.agua_v, pu[0] / z.T) > 0.55, "  bloquea=", z._en_agua(pu[0]))
	if frames > 4 and frames % 60 == 0 and frames < 700:
		var p: Vector2 = z.jugador.position
		var pu: Array = z.puentes[0]
		var dd: Vector2 = p - pu[0]
		print("f", frames, " a lo largo ", int(dd.dot(pu[1])), " de lado ", int(dd.dot(pu[1].orthogonal())), " agua ", z._en_agua(p), " destino ", z.tiene_destino)
	if frames == 700:
		print("cruza el puente: ", z.jugador.position.distance_to(objetivo) < 40.0, " (queda ", int(z.jugador.position.distance_to(objetivo)), " px)")
		return true
	return false
