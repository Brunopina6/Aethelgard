extends SceneTree
# Capturas del BARRIO EXPERIMENTAL de Oakhaven (zonas3d/barrio/, en pruebas; solo desde el banco de Auditoría), fase 0:
# una por tramo con la cámara del juego (la de las zonas, sin girar) y Kael en un sitio de cada uno; con «plano», además
# una vista desde arriba de todo el blockout. No es una prueba (las capturas las revisa una persona). La partida es la
# del banco (su archivo, en user://): lánzalo con APPDATA y LOCALAPPDATA en una carpeta aislada, nunca la real.
#
#   perfil=bajo|medio|alto · res=1600x720 · salida=<carpeta> · plano
#   (fase A, 16/11) blockout: todo en cajas aunque haya tramos horneados (el «antes», con la MISMA cámara) ·
#   prefijo=<texto>: delante del nombre de cada captura (p. ej. antes_ / despues_)
#   (16/11, pulido) suelo: en vez de los tramos, el suelo en sombra con CÁMARAS FIJAS (las mismas antes y después del
#   rehorneado, sin depender de las zonas de cámara): la rampa de los talleres, el atajo y la sombra del muro de
#   caravanas, de lejos (la cámara del juego de la fase A) y de cerca; todos los sectores dibujados enteros.
# Uso: --path aethelgard --resolution 1600x720 --script res://pruebas/fotos_barrio.gd -- 3d sin_prologo perfil=bajo
#      salida=D:/REBELUM_diagnostico/barrio_oakhaven/fase0 plano

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
# [nombre, sitio de Kael (x, z)] por tramo, en el orden del bucle
const SITIOS := [
	["1_caravanas", Vector2(-42.0, 0.5)],
	["2_comercial", Vector2(-21.0, 1.8)],
	["3_plaza", Vector2(0.0, 1.0)],
	["4_talleres", Vector2(0.0, -17.0)],
	["5_residencial", Vector2(-24.0, -28.0)],
	["6_atajo", Vector2(-42.0, -15.5)],
]

# (pulido) [nombre, Kael (x, z), posición de la cámara, inclinación (grados)]: fijas
const SUELO := [
	["s1_rampa_talleres", Vector2(0.0, -13.5), Vector3(0.0, 11.37, 0.7), 25.0],
	["s2_atajo", Vector2(-42.0, -12.0), Vector3(-42.0, 11.08, 3.66), 25.0],
	["s3_muro_caravanas", Vector2(-46.0, -6.0), Vector3(-46.0, 10.8, 11.13), 25.0],
	["s4_rampa_cerca", Vector2(0.0, -13.5), Vector3(0.0, 3.55, -11.9), 58.0],
	["s5_atajo_cerca", Vector2(-42.0, -12.0), Vector3(-42.0, 3.07, -10.4), 58.0],
	["s6_caravanas_cerca", Vector2(-46.0, -6.0), Vector3(-46.0, 2.6, -4.4), 58.0],
]
var suelo := false
var perfil := "bajo"
var salida := "D:/REBELUM_diagnostico/barrio_oakhaven/fase0"
var tam := Vector2i(1600, 720)
var plano := false
var prefijo := ""
var v
var frames := 0
var fase := 0
var f_fase := 0
var i_sitio := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("res="):
			var p: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(p[0]), int(p[1]))
		elif a == "plano":
			plano = true
		elif a == "blockout":
			Engine.set_meta("barrio_solo_blockout", true)
		elif a.begins_with("prefijo="):
			prefijo = a.substr(8)
		elif a == "suelo":
			suelo = true
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(tam)
	root.size = tam
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()                           # la partida del banco (archivo propio en user://)
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(ESCENA)
	fase = 1


func _foto(nombre: String) -> void:
	var ruta := "%s/%sbarrio_%s_%s_%dx%d.png" % [salida, prefijo, nombre, perfil, tam.x, tam.y]
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_size() != tam:                       # (el proyecto conserva 16:9: franjas a los lados, como en el móvil)
		img.convert(Image.FORMAT_RGBA8)
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
	var vis: Array = v.sectores.keys().filter(func(q): return v.visibles.get(q, true))
	print("FOTO %s · %s: llamadas %d · primitivas %d · Kael %s · cámara %s · sectores %s · %s" % [nombre, perfil, dib, prim,
		str(v.kael.global_position), str(v.cam.global_position), str(vis), ruta])


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
				v = current_scene
				v.boton_recargar.visible = false
				_fase(4 if suelo else 2)
		2:
			if frames - f_fase == 30:
				var s: Vector2 = SITIOS[i_sitio][1]
				v._colocar_kael(Vector3(s.x, 0.0, s.y))
				if v.grupo != null:
					v.grupo.colocar(Vector3.BACK)
			elif frames - f_fase == 80:
				v.boton_accion.visible = false
				_foto(SITIOS[i_sitio][0])
				i_sitio += 1
				if i_sitio < SITIOS.size():
					_fase(2)
				elif plano:
					_fase(3)
				else:
					return true
		4:
			return _paso_suelo()
		3:
			if frames - f_fase == 1:
				v.set_process(false)
				v.cam.global_position = Vector3(-20.0, 95.0, -12.0)
				v.cam.global_rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
				v.cam.fov = 50.0
				v.cam.far = 400.0
				v.titulo.text = "Barrio de Oakhaven (en pruebas) · plano del blockout (norte arriba)"
			elif frames - f_fase == 20:
				_foto("0_plano")
				return true
	return false


# (pulido) el suelo con cámaras fijas, todos los sectores enteros
func _paso_suelo() -> bool:
	if frames - f_fase == 1:
		var c: Array = SUELO[i_sitio]
		v.set_process(true)
		v._colocar_kael(Vector3(c[1].x, 0.0, c[1].y))
		if v.grupo != null:
			v.grupo.colocar(Vector3.BACK)
	elif frames - f_fase == 40:
		var c: Array = SUELO[i_sitio]
		v.set_process(false)
		v.cam.global_position = c[2]
		v.cam.global_rotation = Vector3(deg_to_rad(-float(c[3])), 0.0, 0.0)
		v.cam.fov = 38.0
		for s in v.sectores:
			(v.sectores[s] as Node3D).visible = true
			for mi in v._detalle.get(s, []):
				(mi as MeshInstance3D).visible = true
		v.boton_accion.visible = false
	elif frames - f_fase == 46:
		_foto(SUELO[i_sitio][0])
		i_sitio += 1
		if i_sitio >= SUELO.size():
			return true
		_fase(4)
	return false


func _fase(n: int) -> void:
	fase = n
	f_fase = frames
