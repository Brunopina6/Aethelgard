extends "res://pruebas/prueba_erebo_video.gd"
# V12 (15/11): GRABACIÓN para que el usuario revise la invocación cinematográfica de Érebo dentro del juego, con sonido:
# combate de verdad (Kael, Lya y Garon contra Grimfang) → Lya invoca a Érebo → vídeo («abreviada» o «completa») →
# vuelta al combate con el resultado. No es una prueba: se lanza con el Movie Maker de Godot (--write-movie), que
# graba imagen y audio a ritmo fijo. Datos aislados (archivo de partida de prueba). La opción de vídeo se elige SOLO en
# la sesión (V.elegir) y se deja en «no» al acabar.
# Uso: godot --path aethelgard --write-movie <salida.avi> --fixed-fps 30 --resolution 1280x720
#      --script res://pruebas/grabar_erebo_transicion.gd -- erebo=exito modo=abreviada|completa

var _modo := "abreviada"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("modo="):
			_modo = a.substr(5)
	root.size = Vector2i(1280, 720)
	super._initialize()


func _grupo3() -> Dictionary:
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
	Engine.set_meta("grupo_combate", 9)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(semilla)
	for e in c.enemigos:
		e["atb"] = randf() * 30.0
	for i in 3000:                                    # Kael y Garon se defienden hasta que le toca a Lya
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await _esperar(1)
	return c.enemigos[0]


func _probar() -> void:
	await _esperar(10)
	V.elegir(_modo)
	var grim: Dictionary = await _grupo3()
	c.armonia = 1.0
	c._actualizar()
	await _esperar(75)                                # 2,5 s de combate con el menú de Lya y la Armonía llena
	c._invocar_sobre(grim)
	var visto := false
	for i in 30 * 40:                                 # hasta 40 s: entra el vídeo y vuelve el combate
		await _esperar(1)
		if _capa() != null:
			visto = true
		elif visto:
			break
	print("vídeo visto: %s · PV de Grimfang: %d · estado: %s" % [visto, grim["hp"], c.estado])
	await _esperar(120)                               # 4 s de vuelta al combate, con el resultado
	V.elegir("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	quit(0)
