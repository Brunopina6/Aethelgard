extends "res://pruebas/recorrido_ciudad.gd"
# V12 (16/11): DIAGNÓSTICO de los ARREGLOS del recorrido de la ciudad (rama area-ciudad-recorrido-2). Herramienta, no
# prueba: no está en lista_pruebas.txt. Con los controles normales (entrar por el botón del banco, clics en coordenadas
# de ventana, flechas), reproduce y mide lo que no cubren recorrido_ciudad.gd ni diag_ciudad_visibilidad.gd:
#   1. ENTRADA: el grupo tapado de pies, cintura o cabeza en el primer cuadro (la hoja de la Puerta del Sur).
#   2. TOQUE en un sector SIN MONTAR: ante el Paso Cubierto de la Botica (bajo: 3 montados), tocar el suelo de los
#      Pasajes que se ve a 4-10 m: ¿se mueve Kael?
#   3. PARED con TECLAS: pegado a la pared norte del Paso de la Botica, ↑ 1,5 s y ↑+→ 1,5 s: ¿cuánto se desliza?
#   4. RÓTULOS: en el lavadero de las Terrazas y al norte de los rótulos de sector, ¿se ve el rótulo de sector a menos de
#      10 m de la cámara?
# Uso (con ventana): Godot --path aethelgard --script res://pruebas/diag_ciudad_arreglos.gd --fixed-fps 30
#   --resolution 1600x720 -- salida=<carpeta fuera del proyecto> [perfil=bajo] [video=0]
# Imprime «ARREGLOS: …» por apartado y «FALLOS: n» (n = apartados que no salen como deben tras los arreglos).


func _tapados(p: Vector3) -> Array:
	var desde: Vector3 = v.cam.global_position
	var r: Array = []
	for s in P.ORDEN:
		var t = P.trazado(s)
		var montado = v.cargador.montados.get(s)
		for x in Comun.tapan(t.BLOQUES, t.OCULTABLES, desde, p):
			if montado == null:
				continue
			if x[1]:
				if not montado.aclarado(String(x[0])):
					r.append("%s/%s (ocultable sin aclarar)" % [s, x[0]])
			else:
				r.append("%s/%s" % [s, x[0]])
	return r


func _grupo_tapado() -> Array:
	var r: Array = []
	if v.grupo == null:
		return r
	for n in v.grupo.nodos():
		var g: Vector3 = (n as Node3D).global_position
		for h in [0.25, 0.8, 1.4]:
			var t := _tapados(g + Vector3(0, h, 0))
			if not t.is_empty():
				r.append("%s a %.2f m: %s" % [n.name, h, ", ".join(t)])
	return r


func _apartado(ok: bool, txt: String) -> void:
	_nota("ARREGLOS: %s %s" % ["OK" if ok else "MAL", txt])
	if not ok:
		fallos += 1


func _jugar() -> void:
	await _frames(3)
	_preparar_rejilla()
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(BANCO)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == BANCO and current_scene.get("marco") != null:
			break
	await _segundos(1.0)
	var mal := await _entrar_desde_el_banco()
	if mal != "" or not _vivo():
		_apartado(false, "no se entra: " + mal)
		_terminar()
		return
	# 1. entrada
	await _frames(4)
	var g := _grupo_tapado()
	var foto := await _foto("entrada")
	_apartado(g.is_empty(), "1 entrada: grupo tapado en el primer cuadro: %s · foto %s" % [str(g), foto])
	# 2. toque en un sector sin montar
	# (como la verificación: primero la Calle Mayor; luego ante el Paso quedan montados puerta_sur, plaza_tapiz y cuervo)
	await _tramo("plaza_tapiz", "ir", "Calle Mayor (plaza)", P.punto_conexion(P.conexion("calle_mayor"), "b", 4.0))
	await _tramo("plaza_tapiz", "ir", "ante el Paso de la Botica", Vector3(-26.2, 2.0, 55.6), true, 0.3)
	var montados: Array = v.cargador.ids_montados()
	var perdidos := 0
	var probados := 0
	for w in [Vector3(-33.0, 2.0, 55.5), Vector3(-36.0, 2.0, 55.5), Vector3(-30.2, 2.0, 56.0)]:
		if _plana(_kael(), Vector3(-26.2, 2.0, 55.6)) > 0.4:
			await _tramo("plaza_tapiz", "ir", "ante el Paso de la Botica (otra vez)", Vector3(-26.2, 2.0, 55.6), false, 0.3)
		var k0 := _kael()
		var sin: bool = not v.cargador.montados.has("pasajes")
		var pp: Vector2 = v.cam.unproject_position(w)
		var ps = v._punto_suelo(pp)
		await _clic(pp)
		await _segundos(2.5)
		var k1 := _kael()
		probados += 1
		var movido := _plana(k0, k1)
		if movido < 0.5:
			perdidos += 1
		_nota("  toque en %s (pasajes %s; montados %s) en %s del viewport: _punto_suelo %s; Kael %s → %s (%.2f m)" % [_txt(w),
			"SIN MONTAR" if sin else "montado", ", ".join(v.cargador.ids_montados()), str(pp),
			_txt(ps) if ps != null else "null", _txt(k0), _txt(k1), movido])
	foto = await _foto("tras_tocar_pasajes")
	_apartado(perdidos == 0, "2 toque en un sector sin montar (montados al llegar: %s): %d de %d toques perdidos · foto %s" % [
		", ".join(montados), perdidos, probados, foto])
	# 3. pared con teclas
	await _tramo("plaza_tapiz", "ir", "pared norte del Paso de la Botica", Vector3(-28.6, 2.0, 54.4), false, 0.3)
	_tecla(KEY_UP, true)
	await _segundos(1.5)
	var k0 := _kael()
	_tecla(KEY_RIGHT, true)
	await _segundos(1.5)
	_tecla(KEY_RIGHT, false)
	_tecla(KEY_UP, false)
	await _frames(6)
	var k1 := _kael()
	foto = await _foto("pared_teclas")
	_apartado(absf(k1.x - k0.x) > 3.0, "3 pared con teclas: tras ↑ 1,5 s Kael en %s; con ↑+→ 1,5 s, a %s: %.2f m a lo largo de la pared (libre, ≈ 4,5) · foto %s" % [
		_txt(k0), _txt(k1), absf(k1.x - k0.x), foto])
	_tecla(KEY_LEFT, true)
	_tecla(KEY_UP, true)
	await _segundos(1.0)
	_tecla(KEY_LEFT, false)
	_tecla(KEY_UP, false)
	await _frames(6)
	var k2 := _kael()
	_nota("  ↑+← 1 s desde %s: a %s (%.2f m en x)" % [_txt(k1), _txt(k2), absf(k2.x - k1.x)])
	await _segundos(0.5)
	_nota("  Kael parado tras soltar: marcha «%s», movimiento «%s»" % [v.kael.marcha_actual() if v.kael.has_method("marcha_actual") else "-", v.movimiento])
	_apartado(not v.kael.has_method("marcha_actual") or v.kael.marcha_actual() == "", "3b al soltar las teclas tras deslizarse, Kael no sigue andando en el sitio")
	# 4. rótulos de sector cerca de la cámara
	var vistos: Array = []
	for x in [["plaza_tapiz", Vector3(0.0, 4.0, -15.0)], ["barrio_alto", Vector3(0.1, 16.0, -90.0)]]:
		await _tramo(x[0], "ir", "al norte del rótulo de %s" % x[0], x[1], true, 1.0)
		vistos.append_array(_rotulos_cerca())
	_apartado(vistos.is_empty(), "4 rótulos a menos de 10 m de la cámara y dibujados: %s" % str(vistos))
	_terminar()


func _rotulos_cerca() -> Array:
	var r: Array = []
	var c: Vector3 = v.cam.global_position
	for s in v.cargador.montados:
		for l in (v.cargador.montados[s] as Node).find_children("Rotulo_*", "Label3D", false, false):
			var d: float = (l as Node3D).global_position.distance_to(c)
			if d < 10.0 and ((l as GeometryInstance3D).visibility_range_begin <= d):
				r.append("%s/%s a %.1f m" % [s, l.name, d])
	return r
