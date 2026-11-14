extends "res://pruebas/prueba_erebo_video.gd"
# V12 (14/11): cuánto tiempo de JUEGO corre el ATB durante la invocación de siempre (teatro 3D), sin saltar: desde
# _invocar_sobre hasta que el combate vuelve a «esperando». Con «erebo_nueva» mide «Ladrón de Corazones». Sirve para
# que el vídeo dé exactamente el mismo tiempo de ATB (invocacion_erebo_video.gd, ATB_TEATRO). Datos aislados.


func _probar() -> void:
	await _esperar(10)
	V.elegir("no")
	for caso in ["medida"]:
		var grim: Dictionary = await _combate()
		if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
			_ok(false, "no llega el turno de Lya")
			break
		c.armonia = 1.0
		var r0 := reloj
		var atb0: float = c.enemigos[0]["atb"]
		c._invocar_sobre(grim)
		for i in 3000:
			await process_frame
			reloj += root.get_process_delta_time()
			if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
				break
		print("TEATRO %s (%s): %.2f s de juego hasta volver; ATB enemigo %.1f → %.1f" % [" ".join(OS.get_cmdline_user_args()), "nueva" if "erebo_nueva" in OS.get_cmdline_user_args() else "siempre", reloj - r0, atb0, c.enemigos[0]["atb"]])
		c.queue_free()
		c = null
		Engine.time_scale = 1.0
		await _esperar(5)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
