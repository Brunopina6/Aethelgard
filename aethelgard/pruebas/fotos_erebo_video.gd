extends "res://pruebas/prueba_erebo_video.gd"
# V12 (14/11): la invocación cinematográfica de Érebo en VÍDEO dentro de un combate de verdad, CON VENTANA:
# capturas en momentos clave del vídeo (por su posición de reproducción) y, mientras se ve, tiempo de fotograma real
# (medio, p95, máximo y fotogramas de más de 50 ms), duración en pantalla y hasta dónde llegó el vídeo.
# Argumento: salida=<carpeta>. Medidas de PC: NO son resultados de Android.

var _salida := ""
var _medidas := {}
const MARCAS := {"abreviada": [0.5, 1.4, 2.62, 3.5, 4.6, 5.25, 6.4], "completa": [2.6, 4.6, 6.0, 7.6, 9.95, 10.6, 12.6, 16.0, 17.2, 19.5]}


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
	for m in ["abreviada", "completa"]:
		V.elegir(m)
		await _ver(m)
	V.elegir("no")
	var txt := "Invocación de Érebo en vídeo, medidas de PC (%s, %s)\n" % [RenderingServer.get_video_adapter_name(), ProjectSettings.get_setting("rendering/renderer/rendering_method")]
	for k in _medidas:
		txt += "%s: %s\n" % [k, JSON.stringify(_medidas[k])]
	var f := FileAccess.open(_salida.path_join("medidas_video.txt"), FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print(txt)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _ver(m: String) -> void:
	var grim: Dictionary = await _combate()
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % m)
		c.queue_free()
		c = null
		await _esperar(5)
		return
	c.armonia = 1.0
	c._invocar_sobre(grim)
	var vp: VideoStreamPlayer = null
	for i in 600:
		var capa := _capa()
		if capa != null:
			for n in capa.get_children():
				if n is VideoStreamPlayer:
					vp = n
			if vp != null and vp.is_playing():
				break
		await process_frame
	_ok(vp != null, "%s: no aparece el reproductor" % m)
	if vp == null:
		c.queue_free()
		c = null
		await _esperar(5)
		return
	var t0 := Time.get_ticks_usec()
	var ultima := t0
	var tiempos: Array = []
	var marcas: Array = MARCAS[m].duplicate()
	var sucio := 0
	var pos_max := 0.0
	var t_juego := 0.0                       # tiempo de JUEGO: el ejecutor usa --fixed-fps 30 y el vídeo avanza con él
	while is_instance_valid(vp) and _capa() != null:
		await process_frame
		t_juego += Engine.time_scale / 30.0
		var ahora := Time.get_ticks_usec()
		var ms := (ahora - ultima) / 1000.0
		ultima = ahora
		if sucio > 0:
			sucio -= 1
		else:
			tiempos.append(ms)
		if not is_instance_valid(vp):
			break
		var pos: float = vp.stream_position
		pos_max = maxf(pos_max, pos)
		if marcas.size() > 0 and pos >= marcas[0] and vp.visible:
			root.get_texture().get_image().save_png(_salida.path_join("video_%s_%05.2fs.png" % [m, marcas[0]]))
			marcas.pop_front()
			sucio = 2
	var dura := (Time.get_ticks_usec() - t0) / 1000000.0
	var orden := tiempos.duplicate()
	orden.sort()
	var media := 0.0
	var largos := 0
	for x in tiempos:
		media += x
		if x > 50.0:
			largos += 1
	_medidas[m] = {"segundos_en_pantalla_juego": snappedf(t_juego, 0.01), "segundos_en_pantalla_reloj": snappedf(dura, 0.01), "posicion_maxima": snappedf(pos_max, 0.01),
		"ms_medio": snappedf(media / maxf(tiempos.size(), 1), 0.01), "ms_p95": snappedf(orden[int(orden.size() * 0.95)] if orden.size() > 0 else 0.0, 0.01),
		"ms_max": snappedf(orden.max() if orden.size() > 0 else 0.0, 0.01), "fotogramas_mas_50ms": largos, "fotogramas": tiempos.size(),
		"capturas_sin_hacer": marcas}
	_ok(marcas.is_empty(), "%s: quedaron capturas sin hacer %s (el vídeo no llegó a esas posiciones)" % [m, marcas])
	for i in 1500:
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
		await process_frame
	_ok(grim["hp"] <= 0, "%s: el resultado no se aplica" % m)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
