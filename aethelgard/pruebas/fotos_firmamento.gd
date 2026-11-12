extends SceneTree
# Capturas y medidas del Firmamento de los Ecos (V12, 12/11; interruptor orbes_v12 encendido solo aquí), para que el
# usuario compare los tres conceptos. Con ventana y datos aislados:
#   Godot --path aethelgard --script res://pruebas/fotos_firmamento.gd -- <carpeta> <ancho>x<alto> [medir]
# Escribe en <carpeta>: <ancho>x<alto>_<concepto>_<escena>.png y, con «medir», medidas_<ancho>x<alto>.txt (tiempo por
# fotograma sin límite ni vsync, dibujo en CPU y GPU, llamadas de dibujo, primitivas, memoria de vídeo y de texturas;
# es el PC, NO el Redmi).
# Escenas: 0_vacio (sin orbes ni nodos: «antes de usarlo»), 1_kael, 2_lya, 3_garon (con nodos despiertos, disponibles,
# caros, bloqueados y dormidos), 4_confirmar, 5_energia (la energía a medio camino), 6_estallido, 7_cerca (pellizco).

const O := preload("res://firmamento/orbes.gd")

var salida := ""
var tam := Vector2i(1280, 720)
var medir := false
var f
var lineas: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	salida = a[0]
	var t: PackedStringArray = a[1].split("x")
	tam = Vector2i(int(t[0]), int(t[1]))
	medir = "medir" in a
	DisplayServer.window_set_size(tam)
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	# Como fotos_portada.gd: si la ventana no llega a ese tamaño, se compone lo que se ve en el teléfono (el lienzo de
	# 1280×720 escalado y centrado, con bandas negras: «canvas_items» y aspecto «keep»).
	if img.get_size() != tam:
		var escala := minf(float(tam.x) / img.get_width(), float(tam.y) / img.get_height())
		img.resize(int(img.get_width() * escala), int(img.get_height() * escala), Image.INTERPOLATE_LANCZOS)
		var lienzo := Image.create(tam.x, tam.y, false, img.get_format())
		lienzo.fill(Color.BLACK)
		lienzo.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = lienzo
	var ruta := "%s/%dx%d_%s.png" % [salida, tam.x, tam.y, nombre]
	img.save_png(ruta)
	print("CAPTURA ", ruta)


func _preparar(despiertos: Dictionary, orbes: int) -> void:
	for k in ["firmamento", "grupo", "inventario"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var G = load("res://grupo.gd")
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 12
	O.ganar(200, "fotos")
	for h in despiertos:
		for id in despiertos[h]:
			var m := O.desbloquear(h, id)
			if m != "":
				print("aviso: ", h, " ", id, ": ", m)
	var d: Dictionary = Engine.get_meta("firmamento")
	d["orbes"] = orbes


const DESPIERTOS := {
	"Kael": ["k_inicio", "k_filo1", "k_filo2", "k_crit1", "k_filo3", "k_vie1", "k_vie3", "k_mem1"],
	"Lya": ["l_inicio", "l_ma1", "l_ma3", "l_am1", "l_am2", "l_am3", "l_ma2", "l_me1"],
	"Garon": ["g_inicio", "g_mu1", "g_mu2", "g_mu4", "g_ra1", "g_ra2", "g_ra4", "g_me1", "g_me3"],
}


func _correr() -> void:
	Engine.set_meta("orbes_v12", true)
	print("ventana ", DisplayServer.window_get_size(), " lienzo ", root.get_texture().get_size())
	f = load("res://firmamento/firmamento.gd").new()
	_preparar({}, 0)
	root.add_child(f)
	await _esperar(5)
	for e in f.ESTILOS:
		f.poner_estilo(e)
		# 0: vacío, antes de usarlo
		_preparar({}, 0)
		f._poner_heroe("Kael")
		await _esperar(8)
		await _foto("%s_0_vacio" % e)
		# 1-3: con nodos
		_preparar(DESPIERTOS, 4)
		for i in 3:
			var h: String = ["Kael", "Lya", "Garon"][i]
			f._poner_heroe(h)
			f.elegir({"Kael": "k_crit2", "Lya": "l_ma4", "Garon": "g_mu3"}[h])
			await _esperar(8)
			await _foto("%s_%d_%s" % [e, i + 1, h.to_lower()])
		# 4: confirmar
		f._poner_heroe("Kael")
		f.elegir("k_vie2")
		f._accion()
		await _esperar(4)
		await _foto("%s_4_confirmar" % e)
		# 5-6: animación (se para el reloj en dos instantes)
		f._accion()
		f.set_process(false)
		var t0: float = f.t
		f.t = t0 + f.T_VIAJE * 0.55
		f._fija.queue_redraw()
		f._viva.queue_redraw()
		f._luz.queue_redraw()
		f._actualizar_fondo()
		await _esperar(2)
		await _foto("%s_5_energia" % e)
		f.t = t0 + f.T_VIAJE + 0.18
		f._fija.queue_redraw()
		f._viva.queue_redraw()
		f._luz.queue_redraw()
		f._actualizar_fondo()
		await _esperar(2)
		await _foto("%s_6_estallido" % e)
		f.t = t0 + 3.0
		f.set_process(true)
		await _esperar(3)
		# 7: de cerca
		f.elegir("k_crit1")
		f._zoom_en(f.en_pantalla("k_crit1"), 1.8)
		await _esperar(4)
		await _foto("%s_7_cerca" % e)
		f._encuadrar()
		if medir:
			await _medir(e)
	if medir:
		var fa := FileAccess.open("%s/medidas_%dx%d.txt" % [salida, tam.x, tam.y], FileAccess.WRITE)
		fa.store_string("\n".join(lineas) + "\n")
		fa.close()
	quit()


func _medir(e: String) -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	f.fps_reposo = 10000.0                     # redibujar todos los fotogramas (lo peor: animado sin pausa)
	_preparar(DESPIERTOS, 4)
	f._poner_heroe("Kael")
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await _esperar(60)
	var n := 0
	var gpu := 0.0
	var cpu := 0.0
	var dibujos := 0
	var prim := 0
	var inicio := Time.get_ticks_usec()
	while Time.get_ticks_usec() - inicio < 4000000:
		await process_frame
		n += 1
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		dibujos += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var ms := (Time.get_ticks_usec() - inicio) / 1000.0 / n
	var l := "%s %dx%d (ventana %s): %.2f ms por fotograma (%.0f FPS sin límite); dibujo CPU %.2f ms, GPU %.2f ms; %d llamadas de dibujo, %d primitivas; memoria de vídeo %.1f MB (texturas %.1f MB); estática %.1f MB" % [
		e, tam.x, tam.y, DisplayServer.window_get_size(), ms, 1000.0 / ms, cpu / n, gpu / n, dibujos / n, prim / n,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0,
		OS.get_static_memory_usage() / 1048576.0]
	lineas.append(l)
	print(l)
	f.fps_reposo = 30.0
	Engine.max_fps = 60
