extends "res://pruebas/prueba_erebo_hibrida.gd"
# HIBRIDA_SALIDA_19_11 (PC-19): herramienta MÍNIMA para el cierre con 0xC0000005 al hacer quit() a mitad de la invocación
# híbrida de Érebo (opción de Auditoría, APAGADA por defecto). No es una prueba de la batería.
# Combate de verdad (Kael y Lya, grupo 9), Lya invoca sobre el primer enemigo con la híbrida y se sale con quit(0) en la
# fase pedida. Si el proceso no acaba con 0, el cierre ha fallado.
# Uso: godot --headless --path aethelgard --script res://pruebas/herramientas/diag_salir_hibrida.gd --
#      erebo=exito [modo=hibrida] [fase=mano] [tras=0] [grupo=9]
#   fase  → sale en cuanto la híbrida apunta esa fase en su registro (senalar, aparece, mano, agarra...) y «tras»
#           fotogramas después; «fase=ninguna» no invoca (control: se sale con el combate en el menú de Lya)
#           «fotogramas:N» → N fotogramas después de invocar, con cualquier modo (no = teatro, abreviada = vídeo...)
#           «pieza:a+b» → bisección: solo esas piezas de la híbrida (nada, tween, senalar, montar, dirigir, estatica) y
#           sale «tras» (10) fotogramas después · «ataque:N» → el ataque de Lya · «golpe_enemigo:N» → el golpe del
#           primer enemigo (con «enemigos_v12 gt_ataque» y grupo=5, la Hoguera estática de Gorthor v12)
#   antes=liberar_inv,liberar_c_cola,esperar... → lo que se hace justo antes del quit()
# Medidas y causa: docs/v12/HIBRIDA_SALIDA_19_11.md. Sin datos reales: lánzala con APPDATA en una carpeta temporal.

var _modo := "hibrida"
var _fase := "mano"
var _tras := 0
var _grupo := 9


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("modo="):
			_modo = a.substr(5)
		elif a.begins_with("fase="):
			_fase = a.substr(5)
		elif a.begins_with("tras="):
			_tras = int(a.substr(5))
		elif a.begins_with("grupo="):
			_grupo = int(a.substr(6))
	super._initialize()


func _probar() -> void:
	await _esperar(10)
	H.elegir_modo(_modo if _fase != "ninguna" else "no")
	print("DIAG modo %s → híbrida %s · vídeo %s" % [_modo, H.modo(), V.modo()])
	var obj: Dictionary = await _combate(_grupo)
	if c.actor is not Dictionary or c.actor["nombre"] != "Lya":
		_salir(1, "FALLO: no llega el turno de Lya")
		return
	if _fase == "ninguna":
		_salir(0, "DIAG sale en el menú de Lya, sin invocar")
		return
	if _fase.begins_with("golpe_enemigo:"):          # el golpe del primer enemigo (combate.gd _animar_golpe) a medias
		var h: Dictionary = c.heroes[0]
		var p3 = c._p3d(c.enemigos[0])
		print("DIAG golpe de %s a %s · Gorthor.es %s · hoguera %s" % [c.enemigos[0].get("nombre", "?"), h.get("nombre", "?"),
			load("res://combate_gorthor.gd").es(c.enemigos[0]), p3 != null and p3.has_method("hoguera")])
		c.estado = "accion"
		if "gt_ataque" in OS.get_cmdline_user_args():   # Gorthor v12: su Hoguera (combate_gorthor.gd animar_golpe, estática)
			c.enemigos[0]["gt_ataque"] = "hoguera"
		c._animar_golpe(c.enemigos[0], h, 1, "")
		for i in int(_fase.substr(14)):
			await process_frame
		_salir(0, "DIAG sale %s fotogramas tras el golpe del enemigo (grupo %d) · estado %s" % [_fase.substr(14), _grupo, c.estado])
		return
	if _fase.begins_with("ataque:"):                 # el mismo patrón en el juego normal: el ataque de Lya (v12) a medias
		c.accion = "atacar"
		c._aplicar(obj)
		for i in int(_fase.substr(7)):
			await process_frame
		_salir(0, "DIAG sale %s fotogramas tras el ataque de Lya · v12 %s · estado %s · hijos %s" % [_fase.substr(7),
			A12.activo(c.actor if c.actor is Dictionary else {}), c.estado, c.get_children().map(func(x): return x.name).slice(-4)])
		return
	c.armonia = 1.0
	c._actualizar()
	if _fase.begins_with("pieza:"):                  # bisección: solo unas piezas de la híbrida, y salir 10 fotogramas después
		var inv = H.new()
		inv.name = "EreboHibrida"
		c.add_child(inv)
		inv._c = c
		inv._i_mus = AudioServer.get_bus_index("Musica")
		for p in _fase.substr(6).split("+"):
			match p:
				"nada":
					pass
				"tween":
					inv.create_tween().tween_method(func(v): AudioServer.set_bus_volume_db(inv._i_mus, v), 0.0, -18.0, 0.5)
				"senalar":
					inv._senalar(c, obj)
				"montar":
					inv._montar_escenario(c, obj)
				"dirigir":
					inv.dirigir(c, obj, false, true)
				"estatica":
					H.invocar(c, obj, false, func(_r): pass)
				_:
					print("DIAG pieza desconocida ", p)
		for i in int(_tras if _tras > 0 else 10):
			await process_frame
		_salir(0, "DIAG sale con las piezas %s" % _fase.substr(6))
		return
	c._invocar_sobre(obj)
	var t := Time.get_ticks_msec()
	var n := 0
	while Time.get_ticks_msec() - t < 120000:
		await process_frame
		n += 1
		if _fase.begins_with("fotogramas:") and n >= int(_fase.substr(11)):
			_salir(0, "DIAG sale %d fotogramas tras invocar (modo %s) · estado %s · hijos %s" % [n, _modo, c.estado,
				c.get_children().map(func(x): return x.name).slice(-6)])
			return
		var inv = c.get_node_or_null("EreboHibrida")
		if inv != null:
			for r in inv.registro:
				if r[0] == _fase:
					for i in _tras:
						await process_frame
					var fases := []
					for x in inv.registro:
						fases.append(x[0])
					_salir(0, "DIAG sale en «%s» +%d fotogramas · fases %s · estado %s" % [_fase, _tras, fases, c.estado])
					return
		if c.estado != "accion":
			break
	_salir(1, "FALLO: la híbrida no llega a «%s» (estado %s)" % [_fase, c.estado])


func _salir(codigo: int, texto: String) -> void:
	print(texto)
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("antes="):
			continue
		for paso in a.substr(6).split(","):
			var inv = c.get_node_or_null("EreboHibrida") if c != null and is_instance_valid(c) else null
			match paso:
				"liberar_inv":
					if inv != null:
						inv.free()
				"liberar_inv_cola":
					if inv != null:
						inv.queue_free()
				"liberar_c":
					c.free()
				"liberar_c_cola":
					c.queue_free()
				"esperar":
					for i in 5:
						await process_frame
				_:
					print("DIAG paso desconocido ", paso)
			print("DIAG paso ", paso, " hecho")
	H.elegir_modo("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo", "archivo_partida_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	print("DIAG quit(%d)" % codigo)
	quit(codigo)
