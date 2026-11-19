extends "res://pruebas/prueba_erebo_hibrida.gd"
# V12, Érebo híbrida (15/11): GRABACIÓN para revisar la invocación híbrida dentro del juego, con sonido: combate de verdad
# (Kael, Lya y Garon) → Lya invoca a Érebo sobre el primer enemigo → híbrida → vuelta al combate con el resultado, hasta
# que se recupera el control. No es una prueba: se lanza con el Movie Maker de Godot (--write-movie). Datos aislados
# (archivo de partida de prueba); la opción se elige solo en la sesión y se deja en «no» al acabar.
# Uso: godot --path aethelgard --write-movie <salida.avi> --fixed-fps 30 --resolution 1280x720
#      --script res://pruebas/grabar_erebo_hibrida.gd -- erebo=exito|fallo grupo=9 modo=hibrida [saltar=agarra]
# Esperas (19/11, PC-10): el turno de Lya y la vuelta del combate tras la invocación se esperan por RELOJ (antes, 3000 y
# 1800 fotogramas, y al agotarse se seguía grabando en silencio y salía con 0). Al agotarse: «FALLO: …», «FALLOS: 1», la
# opción en «no» y salida 1. Los topes son holgados porque el Movie Maker graba más despacio que el tiempo real.
# Ojo: si se agota a MITAD de la híbrida, Godot se cierra con 0xC0000005 al salir (con ventana y sin ella; también
# saliendo sin más, sin liberar el combate): el código sigue siendo distinto de 0 y el FALLO ya está escrito.
const TOPE_LYA_MS := 120000
const TOPE_INVOCACION_MS := 300000

var _modo := "hibrida"
var _grupo := 9
var _saltar_en := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("modo="):
			_modo = a.substr(5)
		elif a.begins_with("grupo="):
			_grupo = int(a.substr(6))
		elif a.begins_with("saltar="):
			_saltar_en = a.substr(7)
	root.size = Vector2i(1280, 720)
	super._initialize()


func _probar() -> void:
	await _esperar(10)
	H.elegir_modo(_modo)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", _grupo)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(semilla)
	for e in c.enemigos:
		e["atb"] = randf() * 30.0
	var t_lya := Time.get_ticks_msec()
	while true:                                       # Kael y Garon se defienden hasta que le toca a Lya
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		if Time.get_ticks_msec() - t_lya > TOPE_LYA_MS:
			await _abortar("no llega el turno de Lya en %d s (estado %s)" % [TOPE_LYA_MS / 1000, c.estado])
			return
		await _esperar(1)
	var obj: Dictionary = c.enemigos[0]
	c.armonia = 1.0
	c._actualizar()
	await _esperar(75)                                # 2,5 s de combate con el menú de Lya y la Armonía llena
	var pv0: int = obj["hp"]
	# (15/11) tiempos para el análisis del sonido: el Movie Maker graba un fotograma por fotograma de proceso, así que el
	# segundo del MP4 es fotogramas / 30. También el volumen del bus de música antes, durante y después.
	var i_mus := AudioServer.get_bus_index("Musica")
	var t_inicio := Engine.get_process_frames() / 30.0
	print("GRAB inicio %.2f · música %.2f dB" % [t_inicio, AudioServer.get_bus_volume_db(i_mus)])
	var mus_min := 999.0
	var ult_reg: Array = []
	c._invocar_sobre(obj)
	var saltado := false
	var t_inv := Time.get_ticks_msec()
	while true:
		if Time.get_ticks_msec() - t_inv > TOPE_INVOCACION_MS:
			await _abortar("el combate no vuelve tras la invocación en %d s (estado %s, última fase %s)" % [
				TOPE_INVOCACION_MS / 1000, c.estado, ult_reg[-1][0] if ult_reg.size() > 0 else "ninguna"])
			return
		await _esperar(1)
		var inv = c.get_node_or_null("EreboHibrida")
		mus_min = minf(mus_min, AudioServer.get_bus_volume_db(i_mus))
		if inv != null:
			ult_reg = inv.registro.duplicate()
		if _saltar_en != "" and not saltado and inv != null:
			for r in inv.registro:
				if r[0] == _saltar_en and inv._t_juego > r[1] + 0.5:
					saltado = true
					var ac := InputEventAction.new()
					ac.action = "ui_cancel"
					ac.pressed = true
					root.push_input(ac)
					break
		if c.estado != "accion":
			break
	print("GRAB vuelta %.2f · música %.2f dB (la más baja durante: %.2f dB)" % [Engine.get_process_frames() / 30.0,
		AudioServer.get_bus_volume_db(i_mus), mus_min])
	for r in ult_reg:
		if r[1] is float:
			print("GRAB fase %s %.2f" % [r[0], t_inicio + r[1]])
	print("GRABACION grupo %d %s %s: PV %d → %d · estado %s%s" % [_grupo, _modo, forzado, pv0, obj["hp"], c.estado,
		" · saltada en «%s»" % _saltar_en if saltado else ""])
	await _esperar(120)                               # 4 s de vuelta al combate, con el control recuperado
	H.elegir_modo("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	quit(0)


# Al agotarse una espera: lo dice, deja la opción en «no» y los datos de prueba como al empezar, y sale con 1. No vuelve
# (quien llama no sigue).
func _abortar(texto: String) -> void:
	print("FALLO: ", texto)
	print("FALLOS: 1")
	H.elegir_modo("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo", "archivo_partida_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(1)
	await create_timer(3600.0).timeout             # no llega: quit() cierra al acabar este fotograma
