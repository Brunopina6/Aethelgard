extends "res://pruebas/prueba_magia_agua_v12.gd"
# V12 (14/11), fase 3C: la magia Agua APAGADA (la de siempre) frente a ENCENDIDA (vfx/agua_v12.gd) en el MISMO combate
# y momento, con ventana: Agua (nivel I) y Maremoto (nivel III). Mismo grupo, misma semilla («semilla=N»), mismo turno.
# Agua va a Grimfang (el del centro). Un primer lanzamiento sin capturas mide en qué fotograma llega el golpe; luego, apagado y encendido, capturas a:
#   anticipación (golpe − 0,7 s), vuelo/ola (golpe − 0,2 s), impacto (+0,07 s), impacto pleno (+0,33 s),
#   disipación (+1,0 s) y final (+1,8 s)
# y, desde el lanzamiento hasta golpe + 2 s, tiempo de fotograma (medio, p95 y máximo, ms) y llamadas de dibujo (media y
# máxima), aparte para el tramo del impacto (golpe → +1,5 s). Argumento: salida=<carpeta>. Medidas de PC: NO de Android.

const MOMENTOS := [["anticipacion", -0.7], ["vuelo", -0.2], ["impacto", 0.07], ["impacto_pleno", 0.33],
	["disipacion", 1.0], ["final", 1.8]]

var _salida := ""
var _medidas := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			_salida = a.substr(7)
	super._initialize()


func _probar() -> void:
	await _esperar(10)
	if _salida == "":
		_ok(false, "falta salida=<carpeta>")
	DirAccess.make_dir_recursive_absolute(_salida)
	for nivel in [1, 3]:
		var golpe: int = await _lanzar(false, nivel, -1, "")      # ensayo: en qué fotograma llega el golpe
		if golpe < 0:
			_ok(false, "%s: no golpea en el ensayo" % NOMBRE[nivel])
			continue
		for encendido in [false, true]:
			await _lanzar(encendido, nivel, golpe, "%s_%s" % [NOMBRE[nivel].to_lower(), "encendido" if encendido else "apagado"])
	AG.elegir(false)
	var txt := "Magia Agua v12, medidas de PC (%s, %s, %dx%d)\n" % [RenderingServer.get_video_adapter_name(),
		ProjectSettings.get_setting("rendering/renderer/rendering_method"), root.size.x, root.size.y]
	for caso in _medidas:
		txt += "%s: %s\n" % [caso, JSON.stringify(_medidas[caso])]
	var f := FileAccess.open(_salida.path_join("medidas_agua.txt"), FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print(txt)
	_limpiar_metas()
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# Lanza y, si «golpe» ≥ 0, captura y mide. Devuelve el fotograma del primer golpe.
func _lanzar(encendido: bool, nivel: int, golpe: int, nombre: String) -> int:
	AG.elegir(encendido)
	if not await _combate():
		_ok(false, "%s: no llega el turno de Lya" % nombre)
		return -1
	c.actor["pm"] = 999
	var antes := _vida()
	var fotos := {}
	for m in MOMENTOS:
		fotos[golpe + int(round(float(m[1]) * 30.0))] = m[0]
	var tiempos: Array = []
	var tiempos_impacto: Array = []
	var dibujos: Array = []
	var dibujos_impacto: Array = []
	var sucio := 0
	var primero := -1
	var fr := 0
	var ultima := Time.get_ticks_usec()
	if nivel == 1:                                     # a Grimfang, el del centro (el primero está en el borde)
		c.accion = "magia"
		c.magia_sel = "Agua"
		c.nivel_sel = 1
		c._aplicar(c.enemigos[1])
	else:
		c._elegir_hechizo("Agua", nivel, true)
	while fr < 900:
		await _esperar(1)
		fr += 1
		var ahora := Time.get_ticks_usec()
		var ms := (ahora - ultima) / 1000.0
		ultima = ahora
		if primero < 0 and _vida() != antes:
			primero = fr
			if golpe < 0:
				break
		if golpe < 0:
			continue
		var d := float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if sucio > 0:
			sucio -= 1
		else:
			tiempos.append(ms)
			if fr >= golpe and fr <= golpe + 45:
				tiempos_impacto.append(ms)
		dibujos.append(d)
		if fr >= golpe and fr <= golpe + 45:
			dibujos_impacto.append(d)
		if fotos.has(fr):
			root.get_texture().get_image().save_png(_salida.path_join("agua_%s_%s.png" % [nombre, fotos[fr]]))
			sucio = 2
		if fr >= golpe + 60:
			break
	if golpe >= 0:
		_ok(primero == golpe, "%s: el golpe llega en el fotograma %d y no en el %d" % [nombre, primero, golpe])
		_medidas[nombre] = {"todo": _resumen(tiempos, dibujos), "impacto": _resumen(tiempos_impacto, dibujos_impacto)}
	for i in 1500:
		if c.estado != "accion":
			break
		await _esperar(1)
	c.queue_free()
	c = null
	await _esperar(30)
	return primero


func _resumen(tiempos: Array, dibujos: Array) -> Dictionary:
	if tiempos.is_empty():
		return {}
	var orden := tiempos.duplicate()
	orden.sort()
	var media := 0.0
	for x in tiempos:
		media += x
	var dm := 0.0
	for x in dibujos:
		dm += x
	return {"ms_medio": snappedf(media / tiempos.size(), 0.01), "ms_p95": snappedf(orden[int(orden.size() * 0.95)], 0.01),
		"ms_max": snappedf(orden.max(), 0.01), "dibujos_medio": snappedf(dm / maxf(dibujos.size(), 1), 0.1),
		"dibujos_max": dibujos.max(), "fotogramas": tiempos.size()}
