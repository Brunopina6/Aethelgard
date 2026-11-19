extends "res://pruebas/prueba_erebo_video.gd"
# V12 (14/11): cuánto tiempo de JUEGO corre el ATB durante la invocación de siempre (teatro 3D), sin saltar: desde
# _invocar_sobre hasta que el combate vuelve a «esperando». Con «erebo_nueva» mide «Ladrón de Corazones». Sirve para
# que el vídeo dé exactamente el mismo tiempo de ATB (invocacion_erebo_video.gd, ATB_TEATRO). Datos aislados.
# (19/11, PC-10) La vuelta del combate se espera por RELOJ (antes, 3000 fotogramas, y al agotarse se imprimía la medida
# como si hubiera vuelto): al agotarse, «FALLO: …» y salida 1. Lo medido (tiempo de JUEGO, «reloj») no cambia. El
# combate es el de Grimfang (GRUPOS[9]), el que usaba antes de que _combate pidiera el grupo (661c1c5): desde entonces
# esta herramienta se paraba con un error de script por llamar a _combate() sin él.

const TOPE_VUELTA_MS := 180000


func _probar() -> void:
	await _esperar(10)
	V.elegir("no")
	for caso in ["medida"]:
		var grim: Dictionary = await _combate(9)
		if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
			_ok(false, "no llega el turno de Lya")
			break
		c.armonia = 1.0
		var r0 := reloj
		var atb0: float = c.enemigos[0]["atb"]
		c._invocar_sobre(grim)
		var t0 := Time.get_ticks_msec()
		var vuelve := false
		while Time.get_ticks_msec() - t0 < TOPE_VUELTA_MS:
			await process_frame
			reloj += root.get_process_delta_time()
			if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
				vuelve = true
				break
		if not vuelve:
			_ok(false, "el combate no vuelve tras la invocación en %d s de reloj (estado %s, %.2f s de juego)" % [
				TOPE_VUELTA_MS / 1000, c.estado, reloj - r0])
		else:
			print("TEATRO %s (%s): %.2f s de juego hasta volver; ATB enemigo %.1f → %.1f" % [" ".join(OS.get_cmdline_user_args()), "nueva" if "erebo_nueva" in OS.get_cmdline_user_args() else "siempre", reloj - r0, atb0, c.enemigos[0]["atb"]])
		c.queue_free()
		c = null
		Engine.time_scale = 1.0
		await _esperar(5)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
