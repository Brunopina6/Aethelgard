extends SceneTree
# Capturas de LOS INTERIORES del barrio experimental de Oakhaven (agente B; zonas3d/barrio/interiores.gd, en pruebas;
# solo desde el banco de Auditoría): la puerta de cada uno vista desde fuera (con la cámara del juego) y cada interior
# con su cámara propia y Kael en varios sitios, más unos detalles de cerca (la boca del horno, el clavo vacío de la
# galga, la galga en la repisa, el rincón de Nela). Con las llamadas de dibujo y las primitivas de cada foto. No es una
# prueba: las revisa una persona. Lánzalo con APPDATA y LOCALAPPDATA en una carpeta aislada, nunca la real.
#
#   perfil=bajo|medio|alto · res=1600x720 · salida=<carpeta> · solo=horno|taller|vivienda
# Uso: --path aethelgard --resolution 1600x720 --script res://pruebas/fotos_barrio_interiores.gd -- 3d sin_prologo
#      perfil=bajo salida=D:/REBELUM_diagnostico/barrio_oakhaven/b

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
# [nombre, interior («» = fuera), sitio de Kael (ancla «int_*», o «puerta» = delante de la puerta, por fuera), mirada
#  (rotation.y), cámara de detalle [posición local, punto local al que mira] o [], paso abierto]
const FOTOS := [
	["horno_0_puerta_fuera", "", "puerta:horno", PI, [], ""],
	["horno_1_obrador", "horno", "int_horno_artesa", PI, [], ""],
	["horno_2_tienda", "horno", "int_horno_mostrador", 0.0, [], ""],
	["horno_3_zona_de_maela", "horno", "int_horno_mesa", PI, [], ""],
	["horno_4_detalle_boca", "horno", "int_horno_boca", 0.0, [Vector3(3.2, 1.9, 4.2), Vector3(2.0, 1.1, 1.6)], ""],
	["taller_0_porton_fuera", "", "puerta:taller", -PI / 2.0, [], ""],
	["taller_1_nave", "taller", "int_taller_potro", PI, [], ""],
	["taller_2_clavo_vacio", "taller", "int_taller_clavo", PI, [], ""],
	["taller_3_detalle_clavo", "taller", "int_taller_clavo", 0.0, [Vector3(6.4, 1.75, 2.6), Vector3(6.2, 1.6, 0.0)], ""],
	["taller_4_trastienda_cerrada", "taller", "int_taller_paso_trastienda", PI / 2.0, [], ""],
	["taller_5_trastienda_abierta", "taller", "int_taller_banco_corte", PI, [], "trastienda"],
	["vivienda_0_puerta_fuera", "", "puerta:vivienda", PI, [], ""],
	["vivienda_1_cocina", "vivienda", "int_vivienda_repisa", PI / 2.0, [], ""],
	["vivienda_2_alcoba", "vivienda", "int_vivienda_rincon", PI, [], ""],
	["vivienda_3_mesa", "vivienda", "int_vivienda_mesa", 0.0, [], ""],
	["vivienda_4_detalle_repisa", "vivienda", "int_vivienda_repisa", PI / 2.0, [Vector3(2.4, 2.1, 5.9), Vector3(0.6, 1.5, 4.7)], ""],
	["vivienda_5_detalle_rincon", "vivienda", "int_vivienda_rincon", PI, [Vector3(5.6, 1.7, 3.3), Vector3(5.5, 0.4, 1.0)], ""],
]

var perfil := "bajo"
var salida := "D:/REBELUM_diagnostico/barrio_oakhaven/b"
var tam := Vector2i(1600, 720)
var solo := ""
var v
var frames := 0
var fase := 0
var f_fase := 0
var i_foto := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("solo="):
			solo = a.substr(5)
		elif a.begins_with("res="):
			var p: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(tam)
	root.size = tam
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(ESCENA)
	fase = 1


func _foto(nombre: String) -> void:
	var ruta := "%s/barrio_b_%s_%s_%dx%d.png" % [salida, nombre, perfil, tam.x, tam.y]
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_size() != tam:
		img.convert(Image.FORMAT_RGBA8)
		var movil := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		movil.fill(Color(0, 0, 0, 1))
		var esc := minf(float(tam.x) / img.get_width(), float(tam.y) / img.get_height())
		if not is_equal_approx(esc, 1.0):
			img.resize(int(img.get_width() * esc), int(img.get_height() * esc), Image.INTERPOLATE_LANCZOS)
		movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = movil
	img.save_png(ruta)
	var vp := root.get_viewport_rid()
	var vis := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	var dib := RenderingServer.viewport_get_render_info(vp, vis, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var prim := RenderingServer.viewport_get_render_info(vp, vis, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
	print("FOTO %s · %s: 3D: llamadas %d · primitivas %d · Kael %s · %s" % [nombre, perfil, dib, prim, str(v.kael.global_position), ruta])


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
				v = current_scene
				v.boton_recargar.visible = false
				_fase(2)
		2:
			while i_foto < FOTOS.size() and solo != "" and not String(FOTOS[i_foto][0]).begins_with(solo):
				i_foto += 1
			if i_foto >= FOTOS.size():
				return true
			var f: Array = FOTOS[i_foto]
			if frames - f_fase == 2:
				_preparar(f)
			elif frames - f_fase == 50:
				var det: Array = f[4]
				if not det.is_empty():
					v.set_process(false)
					var o: Vector3 = v.interiores.ORIGEN[f[1]]
					v.cam.look_at_from_position(o + det[0], o + det[1], Vector3.UP)
					v.cam.fov = 40.0
			elif frames - f_fase == 70:
				v.boton_accion.visible = false
				_foto(f[0])
				v.kael.visible = false                    # lo que cuesta la sala sola (sin Kael ni el grupo)
				if v.grupo != null:
					v.grupo.visible = false
			elif frames - f_fase == 74:
				var vp := root.get_viewport_rid()
				var vis := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
				print("SALA %s · %s: 3D: llamadas %d · objetos %d · primitivas %d (sin Kael ni el grupo; total con la interfaz %d)" % [
					f[0], perfil,
					RenderingServer.viewport_get_render_info(vp, vis, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
					RenderingServer.viewport_get_render_info(vp, vis, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME),
					RenderingServer.viewport_get_render_info(vp, vis, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
					RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
				v.kael.visible = true
				if v.grupo != null:
					v.grupo.visible = true
				v.set_process(true)
				i_foto += 1
				_fase(2)
	return false


func _preparar(f: Array) -> void:
	var id: String = f[1]
	v.interiores.abrir_paso("trastienda", f[5] == "trastienda")
	if id == "" and v.interior != "":
		v._pasar_fuera()
	elif id != "" and v.interior != id:
		if v.interior != "":
			v._pasar_fuera()
		v._pasar_dentro(id)
	var sitio: String = f[2]
	var p: Vector3
	if sitio.begins_with("puerta:"):
		var d: Dictionary = T.PUERTAS[sitio.substr(7)]
		var umbral := T.ancla(d["ancla"])
		var fuera: Vector3 = d["fuera"]
		p = fuera + Vector3(fuera.x - umbral.x, 0, fuera.z - umbral.z).normalized() * 1.4
	else:
		p = v.interiores.ancla(sitio)
	v._colocar_kael(p)
	v._mirar_kael(float(f[3]))
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames
