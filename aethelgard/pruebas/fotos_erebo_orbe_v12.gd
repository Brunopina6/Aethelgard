extends "res://pruebas/prueba_erebo_orbe_v12.gd"
# V12 (14/11): comparación del orbe experimental de Érebo APAGADO frente a ENCENDIDO en el MISMO combate y condiciones
# (éxito forzado, Lya invoca sobre el mismo enemigo, la invocación elegida por los argumentos). Con ventana.
# Para cada caso: capturas a +0,15 s, +0,45 s y +0,8 s del agarre («orbe_fuera») y, durante 1,2 s desde el agarre,
# tiempo de fotograma (medio y máximo, ms) y llamadas de dibujo (media y máxima). Argumento: salida=<carpeta>.
# Medidas de PC: NO son resultados de Android.

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
	for caso in ["apagado", "encendido"]:
		EO.elegir(caso == "encendido")
		await _fotos(caso)
	EO.elegir(false)
	var txt := "Orbe experimental de Érebo, medidas de PC (%s, %s)\n" % [RenderingServer.get_video_adapter_name(), ProjectSettings.get_setting("rendering/renderer/rendering_method")]
	for caso in _medidas:
		txt += "%s: %s\n" % [caso, JSON.stringify(_medidas[caso])]
	var f := FileAccess.open(_salida.path_join("medidas_orbe.txt"), FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print(txt)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _fotos(caso: String) -> void:
	var grim: Dictionary = await _combate()
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % caso)
		return
	c.armonia = 1.0
	var agarre := [false]
	c._invocar_sobre(grim)
	for i in 1200:
		if c.inv_erebo != null and c.inv_erebo.erebo != null and not c.inv_erebo.erebo.evento.is_connected(_marca.bind(agarre)):
			c.inv_erebo.erebo.evento.connect(_marca.bind(agarre))
		if agarre[0]:
			break
		await process_frame
	_ok(agarre[0], "%s: no llega al agarre" % caso)
	var t0 := Time.get_ticks_usec()
	var tiempos: Array = []
	var dibujos: Array = []
	var ultima := t0
	var fotos := {0.15: false, 0.45: false, 0.8: false}
	var t := 0.0                                   # tiempo de JUEGO (el ejecutor usa --fixed-fps 30)
	var sucio := 0                                 # fotogramas afectados por guardar una captura: no se miden
	var primero := -1.0
	while true:
		await process_frame
		t += Engine.time_scale / 30.0
		var ahora := Time.get_ticks_usec()
		var ms := (ahora - ultima) / 1000.0
		ultima = ahora
		if primero < 0.0:
			primero = ms                           # el fotograma del agarre (crear el efecto, sombreadores en frío)
		elif sucio > 0:
			sucio -= 1
		else:
			tiempos.append(ms)
		dibujos.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		for m in fotos:
			if not fotos[m] and t >= m:
				fotos[m] = true
				root.get_texture().get_image().save_png(_salida.path_join("erebo_orbe_%s_%03d.png" % [caso, int(m * 100)]))
				sucio = 2
		if t >= 1.2:
			break
	var media := 0.0
	for x in tiempos:
		media += x
	var orden := tiempos.duplicate()
	orden.sort()
	var dmedia := 0.0
	for x in dibujos:
		dmedia += x
	_medidas[caso] = {"ms_medio": snappedf(media / maxf(tiempos.size(), 1), 0.01),
		"ms_p95": snappedf(orden[int(orden.size() * 0.95)] if orden.size() > 0 else 0.0, 0.01),
		"ms_max": snappedf(orden.max() if orden.size() > 0 else 0.0, 0.01), "ms_primer_fotograma": snappedf(primero, 0.01),
		"dibujos_medio": snappedf(dmedia / maxf(dibujos.size(), 1), 0.1), "dibujos_max": dibujos.max(), "fotogramas_medidos": tiempos.size()}
	for i in 1500:
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
		await process_frame
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)


func _marca(n: String, agarre: Array) -> void:
	if n == "orbe_fuera":
		agarre[0] = true
