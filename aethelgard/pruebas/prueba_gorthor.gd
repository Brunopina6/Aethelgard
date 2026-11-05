extends SceneTree
# Prueba del jefe Gorthor: presentación, segunda fase al 50 %, último aliento y decisión (perdonar).
# Uso: --script prueba_gorthor.gd -- <carpeta> grupo=5

var c: Node
var frames := 0
var salida := ""
var g: Dictionary
var fase := 0


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("combate_fijo", "garganta_gorthor")
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _foto(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [salida, n])


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		g = c.enemigos[0]
	if frames == 30:
		_foto("1_presentacion")
		print("estado al empezar: ", c.estado, "  ", g["nombre"], " ", g["hp"], "/", g["hp_max"], "  música: ", c.musica != null)
	if frames == 120:
		var huir := ""
		for f in c.menu.filas:
			if f["item"]["texto"] == "HUIR":
				huir = "apagado" if f["item"].get("apagado", false) else "ENCENDIDO"
		print("HUIR ante el jefe: ", huir)
		c._quitar_pv(g, int(g["hp_max"] * 0.55))   # baja del 50 %
		print("fase2 pendiente: ", g.get("fase2_pendiente", false))
	if fase == 0 and g.get("fase2", false) and not g.get("fase2_pendiente", false) and c.estado == "accion":
		fase = 1
		print("cambio de fase en f", frames, ": ", c.registro.text, "  vel ", g["vel"])
	if fase == 1 and frames > 0 and c.registro.text.begins_with("¡") and frames % 40 == 0:
		pass
	if fase == 1 and c.estado != "accion":
		fase = 2
		_foto("2_fase2")
		print("pitch música: ", c.musica.pitch_scale if c.musica else -1.0)
		c._quitar_pv(g, 99999)                      # golpe final: se queda de rodillas
		print("rendido: ", g.get("rendido", false), "  hp ", g["hp"])
	if fase == 2 and not c.menu.filas.is_empty() and c.menu.filas[0]["item"]["texto"] == "PERDONAR":
		fase = 3
		var textos := []
		for f in c.menu.filas:
			textos.append(f["lbl"].text)
		print("decisión: ", textos, "  registro: ", c.registro.text)
		_foto("3_decision")
	if fase == 3 and c.estado == "fin":
		fase = 4
		print("fin: ", c.registro.text, "  decisiones ", Engine.get_meta("decisiones", {}), "  ganados ", Engine.get_meta("combates_ganados", {}))
	return frames > 700 or fase == 4
