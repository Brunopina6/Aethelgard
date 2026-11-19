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
#           (CIERRES_19_11) «golpe_enemigo:impacto+N» → N fotogramas después de que el golpe quite PV a Kael;
#           «ene:clave=valor» pone ese valor en el enemigo (p. ej. ene:vc_ataque=aguijon); el registro dice qué estática
#           de combate.gd le toca («DIAG estatica») y, con el arreglo de PC-21, el «impacto» guardado y desde qué
#           guiones se llama al llegar («DIAG impacto desde»)
#   antes=liberar_inv,liberar_c_cola,esperar... → lo que se hace justo antes del quit()
#   antes=cerrar_ventana → en lugar de quit(): lo que hace Godot al cerrar la ventana con el ratón (la notificación
#           WM_CLOSE_REQUEST a todos los nodos y la señal close_requested de la raíz, con la que SceneTree sale solo)
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
		var e: Dictionary = c.enemigos[0]
		var p3 = c._p3d(e)
		print("DIAG golpe de %s a %s · Gorthor.es %s · hoguera %s" % [e.get("nombre", "?"), h.get("nombre", "?"),
			load("res://combate_gorthor.gd").es(e), p3 != null and p3.has_method("hoguera")])
		c.estado = "accion"
		if "gt_ataque" in OS.get_cmdline_user_args():   # Gorthor v12: su Hoguera (combate_gorthor.gd animar_golpe, estática)
			e["gt_ataque"] = "hoguera"
		for a in OS.get_cmdline_user_args():          # (CIERRES_19_11) «ene:clave=valor» → e[clave] = valor (el ataque)
			if a.begins_with("ene:") and "=" in a:
				e[a.substr(4).get_slice("=", 0)] = a.get_slice("=", 1)
		var Cus = load("res://combate_meshy_e01.gd")   # (el Custodio sin «e01_ataque» da el golpe al momento, sin su 3D:
		if Cus.es(e) and not e.has("e01_ataque"):        #  se le pone el de su Prensa, o su Portón con «e01_porton», como su turno)
			e["e01_ataque"] = {"id": 999, "ataque": Cus.ATAQUE_ID_A2 if "e01_porton" in OS.get_cmdline_user_args()
				else Cus.ATAQUE_ID, "principal": h, "resto": [], "dano_resto": 1, "golpeados": {}, "t_impacto": -1}
		# (CIERRES_19_11) qué estática de combate.gd _animar_golpe le toca (mismo orden que allí) y, con el arreglo de
		# PC-21, la prueba de que de verdad pasa por ella: un «impacto» guardado nuevo en c._impactos, que se envuelve
		# para apuntar, al llegar el golpe, desde qué guiones se llama (Engine.capture_script_backtraces)
		var quien := _estatica_de(e)
		var guardados0: int = c._impactos.size() if "_impactos" in c else -1
		var hp0: int = int(h["hp"])
		c._animar_golpe(e, h, 1, "")
		var nuevos: Array = []
		if guardados0 >= 0:
			for k in c._impactos:
				if k >= guardados0:
					nuevos.append(k)
					var orig: Callable = c._impactos[k]
					c._impactos[k] = func():
						var guiones := []
						for b in Engine.capture_script_backtraces():
							for i in b.get_frame_count():
								var g: String = b.get_frame_file(i).get_file() + ":" + b.get_frame_function(i)
								if not g in guiones:
									guiones.append(g)
						print("DIAG impacto desde ", guiones)
						orig.call()
		print("DIAG estatica %s · %s" % [quien, ("impacto guardado nuevo %s" % [nuevos]) if guardados0 >= 0
			else "sin c._impactos (combate.gd sin el arreglo de PC-21)"])
		var tras := _fase.substr(14)
		if tras.begins_with("impacto"):              # «impacto+N»: N fotogramas después de que el golpe quite PV a Kael
			var t := 0
			while int(h["hp"]) == hp0 and t < 900:
				await process_frame
				t += 1
			print("DIAG impacto %s en el fotograma %d (PV %d → %d)" % [int(h["hp"]) != hp0, t, hp0, int(h["hp"])])
			tras = tras.get_slice("+", 1) if "+" in tras else "0"
		for i in int(tras):
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


# (CIERRES_19_11) la rama de combate.gd _animar_golpe que anima el golpe de «e», en el mismo orden que allí (golpe
# físico, sin magia): el nombre del guion de la estática, o «otra» si no es ninguna de las estáticas de los enemigos v12.
func _estatica_de(e: Dictionary) -> String:
	if c.brama != null and load("res://combate_bramavidrio.gd").es(e):
		return "bramavidrio (método del nodo, no estática)"
	for r in ["humbaba", "vidracran", "centinela", "golem"]:
		if load("res://combate_%s.gd" % r).es(e):
			return "combate_%s.gd" % r
	if load("res://combate_gorthor.gd").es(e) and e.has("gt_ataque"):
		return "combate_gorthor.gd"
	for r in ["peon", "velador", "meshy_e01"]:
		if load("res://combate_%s.gd" % r).es(e):
			return "combate_%s.gd" % r
	if load("res://combate_velaria.gd").de_ella(c, e):
		return "combate_velaria.gd"
	if load("res://combate_cencerrante.gd").de_el(c, e):
		return "combate_cencerrante.gd"
	if load("res://combate_hilandera.gd").de_ella(c, e):          # (19/11, HILANDERA_19_11)
		return "combate_hilandera.gd"
	return "otra (no es estática de enemigo v12)"


func _salir(codigo: int, texto: String) -> void:
	print(texto)
	var cerrar := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("captura=") and DisplayServer.get_name() != "headless":   # (CIERRES_19_11) PNG del último fotograma
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			print("DIAG captura ", a.substr(8), " ", img.save_png(a.substr(8)))
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
				"cerrar_ventana":
					cerrar = true
				_:
					print("DIAG paso desconocido ", paso)
			print("DIAG paso ", paso, " hecho")
	H.elegir_modo("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo", "archivo_partida_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if cerrar:
		print("DIAG cierra la ventana (WM_CLOSE_REQUEST y close_requested), sin quit()")
		root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		root.close_requested.emit()
		return
	print("DIAG quit(%d)" % codigo)
	quit(codigo)
