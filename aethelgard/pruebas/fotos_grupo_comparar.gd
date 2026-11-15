extends SceneTree
# V12 (15/11): COMPARACIÓN DEL GRUPO COMPLETO (Kael, Lya, Garon y Nix) para que el usuario decida sobre Nix (altura frente
# a los chibi, capucha y flequillo). SOLO CAPTURAS: no cambia ningún modelo, proporción, escala ni ajuste del juego.
# Con ventana y datos aislados (APPDATA y LOCALAPPDATA en una carpeta temporal). Los interruptores se encienden SOLO en
# esta sesión (Engine.set_meta) y se quitan al acabar:
#   heroes_version = originales | v2 | v3       (personajes/heroes_v2/heroes_v2.gd)
#   nix_fbx = true solo al CREAR a la «Nix FBX» (personajes/nix/fbx/nix_fbx.gd); la «Nix antigua» se crea con él a false
# Escalas: las de la exploración (zonas3d/grupo_3d.gd, ESCALA: Kael y Garon 1, Lya 0,6/0,67, Nix 0,56/0,67), que son
# las mismas proporciones que el combate (combate.gd: 0,67, 0,6, 0,67 y 0,56). Todos normalizados a 1,7 m por huesos
# (maga_3d.gd, ALTURA) antes de esa escala.
# Postura «de pie»: el reposo de exploración (activar_esperas sin esperas al azar); Garon con su «Calma» (la guardia
# tranquila que le pone grupo_3d.gd al explorar).
#
#   --script res://pruebas/fotos_grupo_comparar.gd --fixed-fps 30 -- modo=<estudio|escena|hoja> version=<originales|v2|v3>
#       salida=<carpeta>
# Modos:
#   estudio  estudio neutro (fondo gris, suelo gris, regla de alturas cada 0,5 m): Kael, Lya, Garon, Nix antigua y Nix
#            FBX en fila, ortográfica (misma escala para todos): frente, tres cuartos, perfil y espalda; la cámara de
#            exploración del juego (45°, 9 m, FOV 38; lo más cerca que deja el zoom); cabezas de cerca (frente y desde
#            arriba). Mide la altura visible de cada uno (píxeles de su silueta sola, de frente, sin lo que sobresale
#            por encima de la cabeza a más de 0,2 m de su eje) y la escribe en alturas_<version>.txt.
#   escena   lo mismo en Pastos Verdes 3D (luz y suelo del juego; Kael y el grupo del juego ocultos y quietos, sin
#            encuentros): frente, tres cuartos y perfil con teleobjetivo, y la cámara de exploración del juego.
#   hoja     compone hoja_<version>.png con las capturas de estudio y escena de esa variante, y con version=resumen la
#            hoja resumen (frente de las tres variantes, estudio y escena) y alturas en el título de cada celda.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}
const ESCALA := {"Kael": 1.0, "Lya": 0.6 / 0.67, "Garon": 1.0, "NixAntigua": 0.56 / 0.67, "NixFBX": 0.56 / 0.67}
const ORDEN := ["Kael", "Lya", "Garon", "NixAntigua", "NixFBX"]
const ROTULO := {"Kael": "Kael", "Lya": "Lya", "Garon": "Garon", "NixAntigua": "Nix antigua", "NixFBX": "Nix FBX"}
const SEP := 0.95                                   # m entre personajes
const ALTO_ORTO := 2.75                             # m de alto en la vista ortográfica
const CENTRO_Y := 0.95
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const SITIO_ESCENA := Vector3(-3.0, 0, 5.0)         # el prado (fotos_nix_revision.gd, prueba_anim_pies.gd)

var salida := ""
var modo := ""
var version := "originales"
var n_fotos := 0
var registro: Array = []
var mundo: Node3D
var cam: Camera3D
var hs := {}                                        # clave → personaje
var rotulos: Array = []                             # Label3D de nombre y altura (solo en las vistas ortográficas)
var regla: Array = []
var alturas := {}                                   # clave → texto de su altura
var medidas := {}                                   # clave → lo que devuelve _medir
var suelo_y := 0.0
var region: Node
var adelante := Vector3(0, 0, 1)                    # del sitio de la fila hacia la cámara de las fotos


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("modo="):
			modo = a.substr(5)
		elif a.begins_with("version="):
			version = a.substr(8)
	if salida == "" or modo == "":
		print("FALLO: falta modo= o salida=")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	if version in ["originales", "v2", "v3"]:
		Engine.set_meta("heroes_version", version)     # solo esta sesión
	_correr.call_deferred()


func _correr() -> void:
	var rec := root.get_node_or_null("Recursos")         # el contador de FPS (de desarrollo) no sale en las fotos
	if rec != null and rec.get("lbl_fps") != null:
		rec.lbl_fps.visible = false
	match modo:
		"estudio": await _estudio()
		"escena": await _escena()
		"plano": await _plano()
		"hoja": await _hojas()
	var f := FileAccess.open(salida.path_join("registro_%s_%s.txt" % [modo, version]), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(registro) + "\n")
		f.close()
	for k in ["nix_v12", "nix_fbx", "heroes_version", "pos_3d_ok", "hitos", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	print("FOTOS: %d en %s" % [n_fotos, salida])
	quit(0)


func _log(t: String) -> void:
	print(t)
	registro.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join(nombre + ".png"))
	n_fotos += 1


# ====================================================================================================== PERSONAJES
func _script_de(clave: String) -> String:
	var s: String = ORIGINAL[clave][0]
	if version == "v2":
		return HeroesV2.SCRIPTS[s]
	if version == "v3":
		return HeroesV3.SCRIPTS[s]
	return s


func _crear(clave: String, padre: Node) -> Node3D:
	var h: Node3D
	if clave.begins_with("Nix"):
		Engine.set_meta("nix_fbx", clave == "NixFBX")  # se decide en _init (nix_3d.gd): solo para crearla
		h = load("res://personajes/nix/nix_3d.gd").new()
		Engine.remove_meta("nix_fbx")
	else:
		h = load(_script_de(clave)).new()
		h.ruta_modelo = ORIGINAL[clave][1]
	h.name = clave
	padre.add_child(h)
	h.scale = Vector3.ONE * ESCALA[clave]
	return h


# De pie, como en la exploración: el reposo de exploración sin esperas al azar; Garon, su «Calma» (grupo_3d.gd _crear).
func _de_pie(h: Node3D) -> void:
	if h.has_method("activar_esperas"):
		h.activar_esperas(true)
	if h.get("esperas") != null:
		h.esperas.pausa = true
	h.reposo()
	if h.has_method("_guardia_viva") and h.anim.has_animation("Juicio"):
		var lib: AnimationLibrary = h.anim.get_animation_library("")
		if not lib.has_animation("Calma"):
			var calma: Animation = h._guardia_viva("Juicio")
			calma.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation("Calma", calma)
		h.play("Calma", 0.0)


# «grados» desde mirar a la cámara de las fotos (adelante): 45 = tres cuartos, 90 = perfil, 180 = espalda.
func _girar(h: Node3D, grados: float) -> void:
	h.mirar(adelante.rotated(Vector3.UP, deg_to_rad(grados)), 0.0)


func _girar_todos(grados: float) -> void:
	for k in hs:
		_girar(hs[k], grados)


func _hueso(h: Node3D, parte: String) -> Vector3:
	var sk: Skeleton3D = h.skel
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).ends_with(parte):
			return sk.global_transform * sk.get_bone_global_pose(i).origin
	return Vector3.INF


func _poner_fila(base: Vector3) -> void:
	for i in ORDEN.size():
		var k: String = ORDEN[i]
		hs[k] = _crear(k, mundo)
		hs[k].position = base + (-adelante).cross(Vector3.UP).normalized() * (i - 2) * SEP   # de izquierda a derecha
	await _frames(20)
	for k in hs:
		_de_pie(hs[k])
		_girar(hs[k], 0)
	await _frames(45)
	for k in hs:
		var h: Node3D = hs[k]
		_log("%s: script %s · modelo %s · escala %.3f" % [k, h.get_script().resource_path, String(h.get("ruta_modelo")), h.scale.x])


# ====================================================================================================== CÁMARA
func _orto(centro: Vector3, alto: float, desde := Vector3(0, 0, 7)) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = alto
	cam.look_at_from_position(centro + desde, centro, Vector3.UP)   # a 7 m: el LOD 0 de la Nix antigua (< 9 m)


func _persp(desde: Vector3, a: Vector3, fov: float) -> void:
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = fov
	cam.look_at_from_position(desde, a, Vector3.UP)


# La cámara de exploración (prototipos/vista3d.gd _colocar_camara, GIRO 0): inclinación 45°, FOV 38, mirando 0,9 m por
# encima del centro; 9 m es lo más cerca que deja el zoom (DIST_MIN).
func _camara_exploracion(centro: Vector3, dist := 9.0) -> void:
	var ang := deg_to_rad(45.0)
	var ojo := centro + Vector3(0, 0.9, 0)
	_persp(ojo + Vector3(0, 0, 1) * cos(ang) * dist + Vector3.UP * sin(ang) * dist, ojo, 38.0)


# ====================================================================================================== MEDIR
# Las armas que lleva (sable de Kael, bastón o cetro, espadas y escudo de Garon): se ocultan para medir el cuerpo.
func _armas(h: Node3D) -> Array:
	var r: Array = []
	for p in ["sable", "vara", "espada", "espada_izq", "escudo"]:
		var a = h.get(p)
		if a is Node3D and (a as Node3D).visible:
			r.append(a)
	return r


# La silueta de lo visible contra «fondo»: fila de lo más alto, de lo más bajo y columnas extremas.
func _silueta(fondo: Image) -> Dictionary:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var top := -1
	var bot := -1
	var izq := 99999
	var der := -1
	for y in img.get_height():
		var hay := false
		for x in range(0, img.get_width(), 2):
			var a := img.get_pixel(x, y)
			var b := fondo.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
				hay = true
				izq = mini(izq, x)
				der = maxi(der, x)
		if hay:
			if top < 0:
				top = y
			bot = y
	return {"top": top, "bot": bot, "izq": izq, "der": der}


# Altura visible (m) por la silueta en la vista ortográfica de frente: solo «h» visible contra la escena sin nadie;
# «alto», sin sus armas (cuerpo, pelo, capucha o sombrero); «con_armas», con ellas.
func _medir(h: Node3D, alto_orto: float, centro_y: float) -> Dictionary:
	for k in hs:
		hs[k].visible = false
	for r in rotulos + regla:
		r.visible = false
	await _frames(3)
	await RenderingServer.frame_post_draw
	var fondo := root.get_texture().get_image()
	h.visible = true
	var armas := _armas(h)
	for a in armas:
		a.visible = false
	var s: Dictionary = await _silueta(fondo)
	for a in armas:
		a.visible = true
	var s2: Dictionary = await _silueta(fondo)
	for k in hs:
		hs[k].visible = true
	for r in rotulos + regla:
		r.visible = true
	var mpp := alto_orto / float(fondo.get_height())
	var suelo_px := (centro_y + alto_orto * 0.5 - suelo_y) / mpp     # fila del suelo en la imagen
	var r := {"alto": (suelo_px - int(s["top"])) * mpp, "alto_silueta": (int(s["bot"]) - int(s["top"])) * mpp,
		"alto_con_armas": (suelo_px - int(s2["top"])) * mpp, "ancho": (int(s["der"]) - int(s["izq"])) * mpp,
		"armas": armas.size()}
	var cuello := _hueso(h, "Neck")
	var cab := _hueso(h, "HeadTop_End")
	r["cuello"] = cuello.y - suelo_y if cuello != Vector3.INF else -1.0
	r["cabeza_hueso"] = cab.y - suelo_y if cab != Vector3.INF else -1.0
	r["cabezas"] = float(r["alto"]) / maxf(float(r["alto"]) - float(r["cuello"]), 0.001)   # alto / (de lo alto al cuello)
	return r


func _medir_todos() -> void:
	var lineas: PackedStringArray = []
	lineas.append("Alturas medidas en el modelo (%s) · Godot 4.7.2 · %s" % [version, Time.get_datetime_string_from_system()])
	lineas.append("Escala del juego en exploración (grupo_3d.gd ESCALA), de pie en su reposo de exploración, de frente.")
	lineas.append("alto = del suelo a lo más alto del cuerpo (pelo, capucha o sombrero incluidos) con sus armas ocultas, por")
	lineas.append("la silueta en vista ortográfica de frente; con_armas = con el sable, bastón, cetro o espadas a la vista;")
	lineas.append("ancho = el del cuerpo sin armas; cuello = altura del hueso del cuello; coronilla = la del hueso")
	lineas.append("HeadTop_End (lo alto del cráneo en el esqueleto, sin pelo, capucha ni sombrero; -1 si no lo tiene);")
	lineas.append("«cabezas» = alto / (alto − cuello): proporción aproximada (cuántas «cabezas» mide de alto).")
	lineas.append("")
	for k in ORDEN:
		var m: Dictionary = await _medir(hs[k], ALTO_ORTO, CENTRO_Y)
		medidas[k] = m
		alturas[k] = ("%.2f m" % float(m["alto"])).replace(".", ",")
		var t := "%-11s escala %.3f · alto %.3f m · con_armas %.3f m · ancho %.3f m · cuello %.3f m · coronilla %.3f m · ~%.1f cabezas · armas ocultas al medir: %d" % [
			ROTULO[k], ESCALA[k], m["alto"], m["alto_con_armas"], m["ancho"], m["cuello"], m["cabeza_hueso"], m["cabezas"], m["armas"]]
		lineas.append(t)
		_log("MEDIDA " + t)
	var f := FileAccess.open(salida.path_join("alturas_%s.txt" % version), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lineas) + "\n")
		f.close()


# Nombre y altura bajo los pies (bajo el suelo: solo se ven en las vistas ortográficas horizontales) y regla cada 0,5 m.
func _rotular(base: Vector3) -> void:
	for i in ORDEN.size():
		var k: String = ORDEN[i]
		var l := Label3D.new()
		l.text = "%s\n%s" % [ROTULO[k], alturas.get(k, "")]
		l.font_size = 40
		l.outline_size = 8
		l.pixel_size = 0.0028
		l.modulate = Color(1, 1, 1)
		l.outline_modulate = Color(0.1, 0.1, 0.12)
		l.position = base + Vector3((i - 2) * SEP, -0.17, 0.4)
		l.shaded = false
		mundo.add_child(l)
		rotulos.append(l)


func _regla(base: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.27, 0.3)
	for y in [0.5, 1.0, 1.5, 2.0]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(5.6, 0.006, 0.006)
		mi.mesh = bm
		mi.material_override = mat
		mi.position = base + Vector3(0, y, -0.9)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mundo.add_child(mi)
		regla.append(mi)
		var l := Label3D.new()
		l.text = ("%.1f m" % y).replace(".", ",")
		l.font_size = 32
		l.pixel_size = 0.0028
		l.modulate = Color(0.2, 0.22, 0.25)
		l.position = base + Vector3(-2.3, y + 0.05, -0.9)
		l.shaded = false
		mundo.add_child(l)
		regla.append(l)


# ====================================================================================================== ESTUDIO
func _estudio() -> void:
	mundo = Node3D.new()
	root.add_child(mundo)
	# La luz de la exploración (prototipos/sendero_puente.gd _crear_ambiente, perfil con sombras): sol cálido 1,05,
	# ambiente azul 0,38, exposición 0,58, saturación 1,3 y contraste 1,1; con fondo gris liso en vez de cielo. (Con la
	# luz del estudio de fotos_nix_fbx.gd, filmic y ambiente 0,55, Lya original salía casi blanca: quemada.)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.86, 0.9, 0.96)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.7, 0.88)
	env.ambient_light_energy = 0.38
	env.tonemap_exposure = 0.58
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.3
	env.adjustment_contrast = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.9, 0.72)
	sol.light_energy = 1.05
	sol.rotation_degrees = Vector3(-48, -35, 0)
	sol.shadow_enabled = true
	mundo.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.52, 0.55)
	suelo.material_override = mat
	mundo.add_child(suelo)
	cam = Camera3D.new()
	cam.near = 0.05
	mundo.add_child(cam)
	cam.current = true
	suelo_y = 0.0
	_regla(Vector3.ZERO)
	await _poner_fila(Vector3.ZERO)
	_orto(Vector3(0, CENTRO_Y, 0), ALTO_ORTO)
	await _frames(5)
	await _medir_todos()
	_rotular(Vector3.ZERO)
	await _vistas_orto("estudio", Vector3(0, CENTRO_Y, 0))
	for r in rotulos + regla:
		r.visible = false
	_girar_todos(0)
	await _frames(15)
	_camara_exploracion(Vector3.ZERO)
	await _frames(5)
	await _foto("estudio_%s_5_camara_exploracion_9m" % version)
	await _cabezas("estudio")


func _vistas_orto(pre: String, centro: Vector3) -> void:
	for v in [["1_frente", 0.0], ["2_tres_cuartos", 45.0], ["3_perfil", 90.0], ["4_espalda", 180.0]]:
		_girar_todos(v[1])
		await _frames(15)
		_orto(centro, ALTO_ORTO)
		await _frames(3)
		await _foto("%s_%s_%s" % [pre, version, v[0]])


# Cabezas de cerca: cada uno solo en el centro de la imagen (los demás ocultos), de frente y desde la cámara de
# exploración (45° desde arriba), a la misma escala para todos (ortográfica de 0,9 m de alto).
func _cabezas(pre: String) -> void:
	_girar_todos(0)
	for r in rotulos + regla:
		r.visible = false
	await _frames(15)
	for k in ORDEN:
		for o in hs:
			hs[o].visible = o == k
		var cuello := _hueso(hs[k], "Neck")              # de 9 cm bajo el cuello a 81 cm por encima: todas las cabezas
		var c := Vector3(hs[k].global_position.x, cuello.y + 0.36, hs[k].global_position.z)
		_orto(c, 0.9, adelante * 2.5)                  # (a 2,5 m: en la escena, sin ramas ni hierba por medio)
		await _frames(3)
		await _foto("%s_%s_6_cabeza_frente_%s" % [pre, version, k])
		var a := deg_to_rad(45.0)
		_orto(c, 0.9, (adelante * cos(a) + Vector3.UP * sin(a)) * 2.5)
		await _frames(3)
		await _foto("%s_%s_7_cabeza_arriba_%s" % [pre, version, k])
	for o in hs:
		hs[o].visible = true


# ====================================================================================================== ESCENA
func _cargar_region(ruta: String) -> bool:
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # sin escenas de llegada
	Engine.set_meta("grupo_activo", ["Kael"])
	change_scene_to_file(ruta)
	for i in 900:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ruta and current_scene.get("kael") != null:
			break
	region = current_scene
	if region == null or region.get("kael") == null:
		_log("FALLO: no cargó %s" % ruta)
		return false
	await _frames(30)
	return true


# Plano cenital (ortográfica de 48 m de ancho) alrededor de «centro=x,z», para elegir sitio, y alturas del suelo.
func _plano() -> void:
	var c := Vector3.ZERO
	var ruta := REGION
	for a in OS.get_cmdline_user_args():
		if a.begins_with("centro="):
			var p := a.substr(7).split(",")
			c = Vector3(float(p[0]), 0, float(p[1]))
		elif a.begins_with("region="):
			ruta = a.substr(7)
	if not await _cargar_region(ruta):
		return
	region.set("pasos", -100000)
	for cl in region.find_children("*", "CanvasLayer", true, false):
		cl.visible = false
	cam = Camera3D.new()
	cam.far = 400.0
	region.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 27.0
	cam.look_at_from_position(c + Vector3(0, 80, 0.01), c, Vector3.UP)
	await _frames(10)
	await _foto("plano_%s_%d_%d" % [ruta.get_file().get_basename(), int(c.x), int(c.z)])
	_log("Kael del juego en %s" % str(region.kael.global_position))
	for z in range(-12, 13, 2):
		var fila := "z %+5.1f:" % (c.z + z)
		for x in range(-20, 21, 2):
			var y := _suelo(c + Vector3(x, 0, z))
			fila += " %5.2f" % y
		_log(fila)


func _escena() -> void:
	if not await _cargar_region(REGION):
		return
	region.set("pasos", -100000)                      # sin encuentros
	# Kael del juego: lejos y oculto (sin tocarlo: no se mueve si nadie le da órdenes); la interfaz, oculta
	region.kael.visible = false
	if region.get("grupo") != null:
		region.grupo.visible = false
	for c in region.find_children("*", "CanvasLayer", true, false):
		c.visible = false
	mundo = Node3D.new()
	region.add_child(mundo)
	var sitio := SITIO_ESCENA
	for a in OS.get_cmdline_user_args():
		if a.begins_with("sitio="):
			var p := a.substr(6).split(",")
			sitio = Vector3(float(p[0]), 0, float(p[1]))
		elif a.begins_with("desde="):                  # dirección (x,z) del sitio hacia la cámara de las fotos
			var p := a.substr(6).split(",")
			adelante = Vector3(float(p[0]), 0, float(p[1])).normalized()
	var y := _suelo(sitio)
	suelo_y = 0.0 if is_nan(y) else y
	var base := Vector3(sitio.x, suelo_y, sitio.z)
	_log("escena: Pastos Verdes, fila en %s, cámara hacia %s" % [str(base), str(adelante)])
	cam = Camera3D.new()
	cam.near = 0.05
	cam.far = 400.0
	mundo.add_child(cam)
	cam.current = true
	await _poner_fila(base)
	for k in hs:                                      # cada uno sobre su suelo
		var p: Vector3 = hs[k].global_position
		var yy := _suelo(p)
		if not is_nan(yy):
			hs[k].global_position.y = yy
		_log("%s en %s" % [k, str(hs[k].global_position.snapped(Vector3.ONE * 0.01))])
	# teleobjetivo de frente (casi sin perspectiva), a la altura del pecho: frente, tres cuartos y perfil
	var c := base + Vector3(0, 0.95, 0)
	for v in [["1_frente", 0.0], ["2_tres_cuartos", 45.0], ["3_perfil", 90.0]]:
		_girar_todos(v[1])
		region.set("pasos", -100000)
		await _frames(15)
		# a 8 m (no 8,5-9,5: ahí la Nix antigua, que viene de lejos, no enseña ni su LOD 0 ni su LOD 1 por la
		# histéresis de sus rangos de visibilidad, nix_3d.gd LOD) y alta (1,9 m): la hierba de delante queda fuera
		_persp(c + Vector3(0, 0.95, 0) + adelante * 8.0, c, 20.0)
		await _frames(3)
		await _foto("escena_%s_%s" % [version, v[0]])
	# la cámara del juego mira siempre desde +Z (vista3d.gd, GIRO 0): en fila a lo ancho (x), cada uno sobre su suelo y
	# de cara a ella
	var i := 0
	for k in ORDEN:
		var p := base + Vector3((i - 2) * SEP, 0, 0)
		var yy := _suelo(p)
		hs[k].global_position = Vector3(p.x, base.y if is_nan(yy) else yy, p.z)
		hs[k].mirar(Vector3(0, 0, 1), 0.0)
		i += 1
	await _frames(15)
	_camara_exploracion(base)
	await _frames(5)
	await _foto("escena_%s_5_camara_exploracion_9m" % version)
	_camara_exploracion(base, 20.0)
	await _frames(5)
	await _foto("escena_%s_5b_camara_exploracion_20m_por_defecto" % version)
	adelante = Vector3(0, 0, 1)                       # las cabezas, como en el juego: desde +Z
	await _cabezas("escena")


# El suelo físico bajo «p» (un rayo vertical, como fotos_nix_revision.gd _poner); NAN si no hay.
func _suelo(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 6.0, p.z), Vector3(p.x, p.y - 10.0, p.z))
	var r: Dictionary = region.get_world_3d().direct_space_state.intersect_ray(q)
	return NAN if r.is_empty() else float(r["position"].y)


# ====================================================================================================== HOJAS
func _celda(nombre: String, rotulo: String, recorte := []) -> Array:
	return [salida.path_join(nombre + ".png"), rotulo, recorte]


func _alturas_de(v: String) -> String:
	var ruta := salida.path_join("alturas_%s.txt" % v)
	if not FileAccess.file_exists(ruta):
		return ""
	var r: PackedStringArray = []
	for l in FileAccess.get_file_as_string(ruta).split("\n"):
		var nombre := l.substr(0, 11).strip_edges()
		if nombre in ROTULO.values() and " alto " in l:
			var i := l.find(" alto ")
			r.append("%s %s m" % [nombre, l.substr(i + 6, 5).strip_edges().replace(".", ",")])
	return " · ".join(r)


func _hojas() -> void:
	var exp_recorte := [240, 150, 800, 450]           # el centro de la cámara de exploración (a 1280×720)
	if version != "resumen":
		var v := version
		var alt := _alturas_de(v)
		var celdas := [
			_celda("estudio_%s_1_frente" % v, "estudio · frente (ortográfica)"),
			_celda("estudio_%s_2_tres_cuartos" % v, "estudio · tres cuartos"),
			_celda("estudio_%s_3_perfil" % v, "estudio · perfil"),
			_celda("estudio_%s_4_espalda" % v, "estudio · espalda"),
			_celda("estudio_%s_5_camara_exploracion_9m" % v, "estudio · cámara de exploración (45°, 9 m), recorte", exp_recorte),
			_celda("escena_%s_5_camara_exploracion_9m" % v, "Pastos Verdes · cámara de exploración (45°, 9 m), recorte", exp_recorte),
			_celda("escena_%s_1_frente" % v, "Pastos Verdes · frente (teleobjetivo)"),
			_celda("escena_%s_2_tres_cuartos" % v, "Pastos Verdes · tres cuartos"),
			_celda("escena_%s_3_perfil" % v, "Pastos Verdes · perfil"),
		]
		await _hoja({"salida": salida.path_join("hoja_%s.png" % v), "columnas": 3, "ancho": 640, "celdas": celdas,
			"titulo": "Grupo completo · protagonistas %s + Nix antigua + Nix FBX · escala del juego, misma luz y cámara\nAltura sin armas (medida en el modelo): %s" % [v, alt]})
		var cab: Array = []
		var cuadro := [280, 0, 720, 720]               # el centro de la imagen (la cabeza), cuadrado
		for k in ORDEN:
			cab.append(_celda("estudio_%s_6_cabeza_frente_%s" % [v, k], "%s · frente" % ROTULO[k], cuadro))
		for k in ORDEN:
			cab.append(_celda("estudio_%s_7_cabeza_arriba_%s" % [v, k], "%s · desde arriba (45°)" % ROTULO[k], cuadro))
		for k in ORDEN:
			cab.append(_celda("escena_%s_6_cabeza_frente_%s" % [v, k], "%s · Pastos, frente" % ROTULO[k], cuadro))
		for k in ORDEN:
			cab.append(_celda("escena_%s_7_cabeza_arriba_%s" % [v, k], "%s · Pastos, desde arriba" % ROTULO[k], cuadro))
		await _hoja({"salida": salida.path_join("hoja_%s_cabezas.png" % v), "columnas": 5, "ancho": 360, "celdas": cab,
			"titulo": "Cabezas a la misma escala (ortográfica de 0,9 m de alto) · protagonistas %s · capucha y flequillo de Nix" % v})
		return
	var res: Array = []
	for v in ["originales", "v2", "v3"]:
		res.append(_celda("estudio_%s_1_frente" % v, "estudio · protagonistas %s (altura sin armas bajo cada uno)" % v))
		res.append(_celda("escena_%s_1_frente" % v, "Pastos Verdes · protagonistas %s" % v))
	await _hoja({"salida": salida.path_join("hoja_resumen.png"), "columnas": 2, "ancho": 900, "celdas": res,
		"titulo": "Resumen · Kael, Lya, Garon, Nix antigua y Nix FBX de frente, a la escala del juego · tres variantes de protagonistas"})


func _hoja(h: Dictionary) -> void:
	var cols: int = int(h.get("columnas", 3))
	var ancho: int = int(h.get("ancho", 480))
	var celdas: Array = h["celdas"] if h.has("celdas") else []
	var imgs: Array = []
	for cd in celdas:
		var img := Image.load_from_file(cd[0])
		if img == null:
			_log("FALTA %s" % cd[0])
			img = Image.create(64, 36, false, Image.FORMAT_RGB8)
		img.convert(Image.FORMAT_RGB8)
		if cd.size() > 2 and cd[2] is Array and not (cd[2] as Array).is_empty():
			var r: Array = cd[2]
			img = img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
		var alto_i := int(round(float(img.get_height()) * ancho / img.get_width()))
		img.resize(ancho, alto_i, Image.INTERPOLATE_LANCZOS)
		imgs.append(img)
	var filas := int(ceil(float(celdas.size()) / cols))
	var rot := 30
	var cab := 56 if not "\n" in str(h.get("titulo", "")) else 88
	var marg := 8
	var y_fila: Array = []
	var yy := cab
	for f in filas:
		y_fila.append(yy)
		var mx := 0
		for j in range(f * cols, mini((f + 1) * cols, imgs.size())):
			mx = maxi(mx, imgs[j].get_height())
		yy += mx + rot + marg
	var tam := Vector2i(cols * (ancho + marg) + marg, yy + marg)
	var vp := SubViewport.new()
	vp.size = tam
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var fondo := ColorRect.new()
	fondo.color = Color(0.12, 0.12, 0.14)
	fondo.size = Vector2(tam)
	vp.add_child(fondo)
	var t := Label.new()
	t.text = h.get("titulo", "")
	t.position = Vector2(marg, 10)
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	vp.add_child(t)
	for i in imgs.size():
		var cx := marg + (i % cols) * (ancho + marg)
		var cy: int = y_fila[i / cols]
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(imgs[i])
		tr.position = Vector2(cx, cy)
		vp.add_child(tr)
		var l := Label.new()
		l.text = celdas[i][1]
		l.position = Vector2(cx + 2, cy + imgs[i].get_height() + 2)
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
		vp.add_child(l)
	await _frames(3)
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(h["salida"])
	n_fotos += 1
	vp.queue_free()
	await _frames(2)
