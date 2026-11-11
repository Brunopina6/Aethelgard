extends SceneTree
# Capturas de Bramavidrio (V12; con ventana): para revisar a ojo el modelo definitivo, sus clips y su aparición.
#   --script res://pruebas/fotos_bramavidrio.gd -- salida=<carpeta> [perfiles=alto,medio,bajo] [solo=combate|region]
# 1. Combate: la cámara de _crear_rig_3d (ortográfica, 12° desde arriba) con el encuadre propuesto para MODELOS
#    (prueba_bramavidrio_modelo.gd), el gusano mirando a los héroes y recortado bajo la arena; cada clip en sus
#    instantes clave → combate_<perfil>.png (hoja de 4 × 3) y cada foto suelta.
# 2. Región: el Mar de Cristal de verdad (zonas3d/mar_cristal_3d.tscn) con Kael en la arena que tiembla: el surco con
#    las aletas, la emersión, el rugido y la cámara de la presentación → region_<perfil>.png (hoja) y cada foto.
# No mide rendimiento. Los datos van a la carpeta aislada de la pasada (ejecutar_pruebas.ps1 -Manual).

const GUION := "res://enemigos/bramavidrio/bramavidrio_3d.gd"
const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const TAM := Vector2i(900, 700)
const ALTO_VISTA := 5.1                    # el encuadre propuesto (pasada 2: vp 1920 × 1000, alto_vista 5,1, centro_y 1,45)
const CENTRO_Y := 1.45
const TOMAS := [["reposo", 0.0], ["emerger", 0.45], ["emerger", 1.1], ["rugido", 0.9], ["ataque", 0.7],
	["ataque", 1.0], ["ataque_sismico", 1.6], ["ataque_sismico", 2.55], ["ataque_aliento", 1.5],
	["ataque_aliento", 2.1], ["herida", 0.15], ["derrota", 3.4]]

var salida := ""
var perfiles: Array = ["alto", "medio", "bajo"]
var solo := ""
var fotos: Array = []
var fallos := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("solo="):
			solo = a.substr(5)
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_bramavidrio")
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = TAM
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(salida.path_join(nombre + ".png"))
	print("  foto ", nombre)
	return img


func _hoja(imgs: Array, columnas: int, nombre: String) -> void:
	if imgs.is_empty():
		return
	var w: int = imgs[0].get_width() / 2
	var h: int = imgs[0].get_height() / 2
	var filas := int(ceil(imgs.size() / float(columnas)))
	var hoja := Image.create(w * columnas, h * filas, false, Image.FORMAT_RGBA8)
	for i in imgs.size():
		var im: Image = imgs[i].duplicate()
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		hoja.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % columnas) * w, (i / columnas) * h))
	hoja.save_png(salida.path_join(nombre + ".png"))
	print("HOJA ", salida.path_join(nombre + ".png"))


func _correr() -> void:
	print("== Fotos de Bramavidrio en ", salida)
	if solo != "region":
		for p in perfiles:
			await _combate(p)
	if solo != "combate":
		for p in perfiles:
			await _region(p)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ---------------------------------------------------------------- combate

func _combate(perfil: String) -> void:
	var escena := Node3D.new()
	root.add_child(escena)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.70, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78)              # como _crear_rig_3d
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	escena.add_child(we)
	var luz := DirectionalLight3D.new()
	luz.light_color = Color(1.0, 0.86, 0.62)
	luz.light_energy = 1.3
	luz.rotation_degrees = Vector3(-35, -40, 0)
	luz.shadow_enabled = perfil != "bajo"
	escena.add_child(luz)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color(0.55, 0.65, 0.95)
	relleno.light_energy = 0.3
	relleno.rotation_degrees = Vector3(-15, 140, 0)
	escena.add_child(relleno)
	var suelo := MeshInstance3D.new()                             # el suelo del combate en el desierto (el fondo 2D)
	var pl := PlaneMesh.new()
	pl.size = Vector2(60, 60)
	suelo.mesh = pl
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.80, 0.64, 0.44)
	ms.roughness = 1.0
	suelo.material_override = ms
	escena.add_child(suelo)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ALTO_VISTA
	escena.add_child(cam)
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, CENTRO_Y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, CENTRO_Y, 0))
	cam.current = true
	var g: Node3D = load(GUION).new()
	g.calidad = perfil
	escena.add_child(g)
	await _esperar(4)
	if g.anim == null:
		fallos += 1
		print("FALLO: [%s] el modelo no carga" % perfil)
		escena.queue_free()
		return
	var imgs: Array = []
	for t in TOMAS:
		g._clip = t[0]
		g._eventos = []
		g._espera = []
		g.anim.play(t[0], 0.0)
		g.anim.seek(float(t[1]), true)
		g.anim.speed_scale = 0.0
		await _esperar(3)
		imgs.append(await _foto("combate_%s_%s_%.2f" % [perfil, t[0], t[1]]))
	await _hoja(imgs, 4, "combate_%s" % perfil)
	escena.queue_free()
	await _esperar(3)


# ---------------------------------------------------------------- la región, de verdad

func _region(perfil: String) -> void:
	var P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("incienso", 100000)
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	var v = null
	for i in 600:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION:
			v = current_scene
			break
	if v == null:
		fallos += 1
		print("FALLO: [%s] la región no carga" % perfil)
		return
	await _esperar(30)
	v.clima.sistemicas = false
	if v.clima.has_method("en_tormenta") and v.clima.en_tormenta():
		print("  (tormenta en curso)")
	v._colocar_kael(Vector3(80.0, 0.0, 40.0))
	v._ultima = v.kael.global_position
	await _esperar(20)
	var gz = v.gusano
	var imgs: Array = []
	gz._empezar_aviso(v.kael.global_position)
	await _esperar(12)
	imgs.append(await _foto("region_%s_1_aviso" % perfil))
	await _esperar(22)
	imgs.append(await _foto("region_%s_2_surco" % perfil))
	gz.surco_pos = v.kael.global_position + Vector3(1.0, 0.0, -0.5)
	gz.surco_pos.y = v.kael.global_position.y
	for i in 200:                                                 # el surco llega: la aparición
		await process_frame
		if gz.estado == "aparicion":
			break
	var marcas := [[12, "3_rompe"], [16, "4_sube"], [30, "5_cuelga"], [40, "6_baja"], [36, "7_ruge"], [20, "8_ruge2"],
		[20, "9_vuelve"]]
	for m in marcas:
		await _esperar(int(m[0]))
		if current_scene != v:
			break
		imgs.append(await _foto("region_%s_%s" % [perfil, m[1]]))
	await _hoja(imgs, 3, "region_%s" % perfil)
	for i in 400:                                                 # deja que llegue el combate y vuelve a empezar
		await process_frame
		if current_scene != v:
			break
	await _esperar(30)
