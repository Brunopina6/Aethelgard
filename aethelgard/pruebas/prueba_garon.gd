extends SceneTree
var c: Node
var n := 0
var hp0 := -1
var atb_visto := {}
var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _terminar() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
func _process(_d: float) -> bool:
	n += 1
	if n % 30 == 0:
		var g = null
		for h in c.heroes:
			if h["nombre"] == "Garon": g = h
		var total: int = 0
		for e in c.enemigos:
			total += int(e["hp"])
		if hp0 < 0:
			hp0 = total
		atb_visto[snappedf(float(g["atb"]), 1.0)] = true
		print(n, " estado=", c.estado, " ts=", Engine.time_scale, " paused=", paused, " garon atb=", g["atb"], " emb=", g.get("embuir",""), "/", g.get("embuir_turnos",0), " reg=", c.registro.text, " enem=", c.enemigos.map(func(e): return e["hp"]))
	if n <= 1100:
		return false
	# (10/11) con aserciones: el combate avanza (los enemigos pierden vida), la barra de Garon se mueve y nada se queda
	# en pausa ni a otra velocidad
	var fin: int = 0
	for e in c.enemigos:
		fin += int(e["hp"])
	if fin >= hp0:
		_fallo("en 1100 fotogramas los enemigos no pierden vida (%d → %d)" % [hp0, fin])
	if atb_visto.size() < 3:
		_fallo("la barra ATB de Garon no se mueve")
	if paused or not is_equal_approx(Engine.time_scale, 1.0):
		_fallo("el combate se queda en pausa o a velocidad %.2f" % Engine.time_scale)
	return _terminar()
