extends SceneTree
# Prueba: detalle de lore en el Gran Bosque Verde (brazalete, Examinar, Diario) y reglas de ritmo.

var z: Node
var frames := 0
var P


func _initialize() -> void:
	P = load("res://progreso.gd")
	z = load("res://zona.tscn").instantiate()
	root.add_child(z)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 5:
		print("detalles en la zona: ", z.detalles.size())
		var dt: Array = z.detalles[0]
		z.jugador.position = dt[0].position + Vector2(0, 200)
		z._brazalete()
		print("brazalete brilló: ", z.brillados.has(dt[1]["id"]))
		z.jugador.position = dt[0].position + Vector2(0, 50)
		z.camara.global_position = z.jugador.position
		z._comprobar_cerca()
		print("botón: ", z.boton_examinar.text, " visible=", z.boton_examinar.visible)
		z._accion()
		print("aviso: ", z.aviso.text)
		print("visto: ", P.visto(dt[1]["id"]))
	if frames == 40:
		root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://lore.png")
		# ritmo
		print("nivel grupo ", P.nivel_grupo(), "  prob paso 41 bosque ", P.prob_encuentro(0.012, 41, 40, "bosque"),
			"  paso 100 ", P.prob_encuentro(0.012, 100, 40, "bosque"))
		print("exp nivel 1 en bosque (zona 4): x", P.mult_exp("bosque", "normal", 1), "  nivel 12 en llanura: x",
			P.mult_exp("llanura", "normal", 12), "  jefe: x", P.mult_exp("llanura", "jefe", 2))
		P.usar_incienso()
		print("con incienso: ", P.prob_encuentro(0.012, 100, 40, "bosque"))
		# acto I completo -> página del diario
		var acto := {}
		for l in [0, 1, 2]:
			for d in P.detalles_de(l):
				var r: Dictionary = P.ver_detalle(d["id"])
				if not r.is_empty():
					acto = r
		print("acto completado: ", acto.get("escena", "-"))
		return true
	return false
