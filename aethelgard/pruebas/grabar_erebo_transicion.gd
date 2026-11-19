extends "res://pruebas/prueba_erebo_video.gd"
# V12 (15/11): GRABACIÓN para que el usuario revise la invocación cinematográfica de Érebo dentro del juego, con sonido:
# combate de verdad (Kael, Lya y Garon contra Grimfang) → Lya invoca a Érebo → vídeo («abreviada» o «completa») →
# vuelta al combate con el resultado. No es una prueba: se lanza con el Movie Maker de Godot (--write-movie), que
# graba imagen y audio a ritmo fijo. Datos aislados (archivo de partida de prueba). La opción de vídeo se elige SOLO en
# la sesión (V.elegir) y se deja en «no» al acabar.
# Uso: godot --path aethelgard --write-movie <salida.avi> --fixed-fps 30 --resolution 1280x720
#      --script res://pruebas/grabar_erebo_transicion.gd -- erebo=exito modo=abreviada|completa
# Esperas (19/11, PC-10): el turno de Lya y el vídeo se esperan por RELOJ (antes, 3000 y 1200 fotogramas, y al agotarse
# se seguía grabando en silencio y salía con 0). Al agotarse: «FALLO: …», «FALLOS: 1», la opción en «no» y salida 1.
# Los topes son holgados porque el Movie Maker graba más despacio que el tiempo real.
const TOPE_LYA_MS := 120000
const TOPE_VIDEO_MS := 300000

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
	var t_lya := Time.get_ticks_msec()
	while true:                                       # Kael y Garon se defienden hasta que le toca a Lya
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		if Time.get_ticks_msec() - t_lya > TOPE_LYA_MS:
			await _abortar("no llega el turno de Lya en %d s (estado %s)" % [TOPE_LYA_MS / 1000, c.estado])
			return {}
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
	var t_video := Time.get_ticks_msec()
	while true:                                       # entra el vídeo y vuelve el combate
		if Time.get_ticks_msec() - t_video > TOPE_VIDEO_MS:
			await _abortar("el vídeo %s en %d s (estado %s)" % ["no termina" if visto else "no entra",
				TOPE_VIDEO_MS / 1000, c.estado])
			return
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


# Al agotarse una espera: lo dice, deja la opción en «no» y los datos de prueba como al empezar, y sale con 1. No vuelve
# (quien llama no sigue).
func _abortar(texto: String) -> void:
	print("FALLO: ", texto)
	print("FALLOS: 1")
	V.elegir("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo", "archivo_partida_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(1)
	await create_timer(3600.0).timeout             # no llega: quit() cierra al acabar este fotograma
