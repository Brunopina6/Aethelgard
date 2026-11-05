extends SceneTree
var c: Node
var n := 0
func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
func _process(_d: float) -> bool:
	n += 1
	if n % 30 == 0:
		var g = null
		for h in c.heroes:
			if h["nombre"] == "Garon": g = h
		print(n, " estado=", c.estado, " ts=", Engine.time_scale, " paused=", paused, " garon atb=", g["atb"], " emb=", g.get("embuir",""), "/", g.get("embuir_turnos",0), " reg=", c.registro.text, " enem=", c.enemigos.map(func(e): return e["hp"]))
	return n > 750
