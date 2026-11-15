extends SceneTree
# Capturas de la MUESTRA GRÁFICA de una calle de Oakhaven (zonas3d/muestra_calle/, en pruebas; solo desde el banco de
# pruebas de Auditoría) y del «antes»: la Calle del Cuervo de Oakhaven 3D, con LA MISMA CÁMARA respecto a Kael.
# No es una prueba (no está en lista_pruebas.txt): las capturas las revisa una persona. No toca ninguna partida.
#
#   escena=oakhaven   el antes: Kael en la Calle del Cuervo (OAK_KAEL), entre la Taberna del Cuervo Oxidado y la casa
#                     de 6×4; la cámara, como se pida
#   escena=muestra    el después: la muestra, con Kael en su sitio de comparación (muestra_calle.gd, SITIO_FOTO)
#   camaras=muestra,juego
#       muestra  la cámara de la muestra: 11 m sobre los pies de Kael, 14,2 m al sur, 26° hacia abajo, 38° de campo
#       juego    la cámara de juego de Oakhaven en esa calle (52°, 18 m, mira a 0,9 m sobre Kael): la que tiene hoy
#   perfiles=bajo,medio,alto · res=1600x720 · salida=<carpeta> · etiqueta=<texto del nombre del archivo>
#   vistas   (solo en la muestra) además, las vistas fijas de VISTAS (la puerta, la esquina, el callejón)
# Uso: --path aethelgard --script res://pruebas/fotos_muestra_calle.gd -- 3d sin_prologo escena=muestra salida=<carpeta>

const OAKHAVEN := "res://zonas3d/oakhaven_3d.tscn"
const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const OAK_KAEL := Vector3(21.5, 0.0, 26.0)            # Calle del Cuervo (casillas: x 6-35, z 25-27), ante la taberna
# La cámara de juego de Oakhaven ahí (oakhaven_3d.gd, CAMARA_CIUDAD [52°, 12-19 m] con la distancia de partida 18 m;
# vista3d._colocar_camara, quieto: sin adelanto): el ojo a 0,9 m sobre Kael.
const JUEGO_INCL := 52.0
const JUEGO_DIST := 18.0

var escena := "muestra"
var camaras: Array = ["muestra"]
var perfiles: Array = ["bajo"]
var salida := "D:/REBELUM_diagnostico/muestra_calle_15_11"
var etiqueta := ""
var tam := Vector2i(1600, 720)
var vistas := false
var vista_libre: Array = []
var ip := 0
var ic := 0
var iv := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var _gpu: Array = []
var _cpu: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("escena="):
			escena = a.substr(7)
		elif a.begins_with("camaras="):
			camaras = Array(a.substr(8).split(","))
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a.begins_with("res="):
			var p: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(p[0]), int(p[1]))
		elif a == "vistas":
			vistas = true
		elif a.begins_with("modo="):                 # muestra_calle.gd: gris | materiales | luz (las pasadas)
			Engine.set_meta("muestra_modo", a.substr(5))
		elif a.begins_with("vista="):               # una vista libre: x,y,z,mira_x,mira_y,mira_z,campo
			var n: PackedFloat64Array = PackedFloat64Array(Array(a.substr(6).split(",")).map(func(t): return float(t)))
			vista_libre = ["vista_libre", Vector3(n[0], n[1], n[2]), Vector3(n[3], n[4], n[5]), n[6]]
		elif a == "solo_luz":
			Engine.set_meta("muestra_solo_luz", true)
		elif a == "sin_titulo":
			Engine.set_meta("muestra_sin_titulo", true)
	if etiqueta == "":
		etiqueta = "antes" if escena == "oakhaven" else "despues"
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(tam)
	root.size = tam
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_muestra_calle.save")
	Engine.set_meta("oakhaven_sin_cache", true)
	_cargar()


func _cargar() -> void:
	Engine.set_meta("calidad_proto", perfiles[ip])
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(OAKHAVEN if escena == "oakhaven" else MUESTRA)
	v = null
	ic = 0
	iv = 0
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames
	_gpu.clear()
	_cpu.clear()


func _muestra() -> void:
	var rid := root.get_viewport_rid()
	var g := RenderingServer.viewport_get_measured_render_time_gpu(rid)
	if g > 0.0 and g < 1000.0:
		_gpu.append(g)
	_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu())


func _mediana(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var o := a.duplicate()
	o.sort()
	return o[o.size() / 2]


func _foto(nombre: String) -> void:
	var ruta := "%s/%s_%s_%s_%dx%d.png" % [salida, etiqueta, nombre, perfiles[ip], tam.x, tam.y]
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_size() != tam:                     # el proyecto conserva 16:9 (stretch «keep»): en el Redmi (20:9) se ve
		img.convert(Image.FORMAT_RGBA8)            # así, con franjas a los lados; la captura lo enseña igual
		var movil := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		movil.fill(Color(0, 0, 0, 1))
		var esc := minf(float(tam.x) / img.get_width(), float(tam.y) / img.get_height())
		if not is_equal_approx(esc, 1.0):
			img.resize(int(img.get_width() * esc), int(img.get_height() * esc), Image.INTERPOLATE_LANCZOS)
		movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = movil
	img.save_png(ruta)
	var dib := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("FOTO %s · %s · %s · %s: llamadas %d · primitivas %d · objetos %d · GPU %.2f ms · CPU %.2f ms (medianas) · %s" % [
		escena, etiqueta, nombre, perfiles[ip], dib, prim, obj, _mediana(_gpu), _mediana(_cpu), ruta])
	print("  cámara: posición %s · rotación %s · Kael %s" % [str(v.cam.global_position), str(v.cam.global_rotation_degrees),
		str(v.kael.global_position)])
	if v.get("materiales_sombra") != null:
		print("  luz de Kael: sol %.2f · cielo %.2f (sondas) · %d materiales con su sombra" % [v._sol_k, v._cielo_k, v.materiales_sombra.size()])


func _sitio() -> Vector3:
	if escena == "oakhaven":
		var p := OAK_KAEL
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 6.0, 0))
		var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
		if not r.is_empty():
			p.y = r["position"].y
		return p
	return v.SITIO_FOTO


func _poner_camara(cual: String) -> void:
	var k: Vector3 = v.kael.global_position
	var Muestra = load("res://zonas3d/muestra_calle/muestra_calle.gd")
	if cual == "muestra":
		Muestra.camara_muestra(v.cam, k)
	else:
		var ojo := k + Vector3(0, 0.9, 0)
		var ang := deg_to_rad(JUEGO_INCL)
		v.cam.global_position = ojo + Vector3(0, sin(ang), cos(ang)) * JUEGO_DIST
		v.cam.look_at(ojo, Vector3.UP)
		v.cam.fov = 38.0


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			var ruta := OAKHAVEN if escena == "oakhaven" else MUESTRA
			if current_scene != null and current_scene.scene_file_path == ruta and frames - f_fase >= 30:
				v = current_scene
				if escena == "oakhaven":
					v.en_posada = false
				v._colocar_kael(_sitio())
				if v.get("grupo") != null:
					v.grupo.colocar(Vector3.BACK)
				if v.get("boton_accion") != null:
					v.boton_accion.visible = false
				_fase(2)
		2:
			if frames - f_fase == 1:
				v.set_process(false)                 # la cámara se queda donde se pone (la escena no la mueve)
				_poner_camara(camaras[ic])
			elif frames - f_fase >= 40 and frames - f_fase < 70:
				_muestra()
			elif frames - f_fase == 70:
				_foto("camara_" + camaras[ic])
				v.set_process(true)
				ic += 1
				if ic < camaras.size():
					_fase(2)
				elif (vistas or not vista_libre.is_empty()) and escena == "muestra":
					_fase(3)
				else:
					_siguiente_perfil()
		3:
			if frames - f_fase == 1:
				v.set_process(false)
				var vi: Array = _vistas()[iv]
				v.cam.global_position = vi[1]
				v.cam.look_at(vi[2], Vector3.UP)
				v.cam.fov = vi[3]
			elif frames - f_fase >= 10 and frames - f_fase < 40:
				_muestra()
			elif frames - f_fase == 40:
				_foto(_vistas()[iv][0])
				v.set_process(true)
				iv += 1
				if iv < _vistas().size():
					_fase(3)
				else:
					_siguiente_perfil()
	if frames > 9000:
		print("FALLO: las fotos no terminaron (fase %d)" % fase)
		quit(1)
		return true
	return false


func _vistas() -> Array:
	var r: Array = (v.VISTAS as Array).duplicate() if vistas else []
	if not vista_libre.is_empty():
		r.append(vista_libre)
	return r


func _siguiente_perfil() -> void:
	ip += 1
	if ip >= perfiles.size():
		Engine.remove_meta("calidad_proto")
		print("FOTOS HECHAS")
		quit(0)
		return
	_cargar()
