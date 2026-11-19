extends SceneTree
# V12 (19/11, C-6): capturas de la EMISIÓN DE LOS ORNAMENTOS de Nix (piloto FBX) en sus tres intensidades (básica,
# fuerte y suprema) y apagada, con la misma pose, y la medida de FUGAS: píxeles que se aclaran con la emisión fuera de
# los ornamentos. Solo capturas y medidas: no cambia nada del juego ni guarda partidas. Interruptores de sesión
# «nix_v12» y «nix_fbx» (solo dentro de la prueba).
#   --fixed-fps 30 -s res://pruebas/fotos_nix_emision.gd -- salida=<carpeta> [modo=estudio|combate] [zona=llanura]
# modo=estudio (por defecto): la luz del combate (sin resplandor) y un anochecer con resplandor de umbral 0,85 (el más
#   bajo de las zonas); cámaras: cuerpo entero de frente y de espalda (el emblema), la del combate (ortográfica, Nix ≈
#   205 px como en combate) y la de exploración (perspectiva, 10 m). Pose: el lanzamiento del culminante (1,6 s).
#   La referencia de las fugas se dibuja aparte: la ropa sin luz, blanca SOLO donde la fuente sin comprimir (la textura
#   .webp decodificada, con sus mipmaps) tiene oro o amatista en la huella del píxel; un píxel que se aclara con la
#   suprema (> 3/255) y que, con un margen de 1 píxel, no tiene ornamento en la referencia, es una fuga.
# modo=combate: un combate real (combate.tscn, Kael, Lya y Nix; la luz y el fondo del juego) con Nix quieta en su
#   guardia; los cuatro niveles y un recorte ×3 de Nix.

const ESC := 0.56 / 0.67
const POSE := "magia_culminante"
const POSE_T := 1.6
const NF := preload("res://personajes/nix/fbx/nix_fbx.gd")
const REF := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D metal_src : filter_linear_mipmap;
uniform sampler2D color_src : source_color, filter_linear_mipmap;
uniform bool negro = false;
void fragment() {
	if (negro) { ALBEDO = vec3(0.0); }
	else {
		vec4 mr = texture(metal_src, UV);
		vec3 a = texture(color_src, UV).rgb;
		float mx = max(a.r, max(a.g, a.b));
		vec3 c = a / max(mx, 0.001);
		float gema = step(mr.g, 0.25) * step(0.45, c.b - c.g) * step(0.05, c.r - c.g);
		ALBEDO = vec3(step(0.06, mr.b) + gema);
	}
}
"""

var salida := ""
var modo := "estudio"
var zona := "llanura"
var mundo: Node3D
var cam: Camera3D
var env: Environment
var luz: DirectionalLight3D
var rel: DirectionalLight3D
var nix: Node3D
var mat_ropa: ShaderMaterial
var n_fotos := 0
var informe: PackedStringArray = []
var rects := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("modo="):
			modo = a.substr(5)
		elif a.begins_with("zona="):
			zona = a.substr(5)
	if salida == "":
		print("FALLO: falta salida=")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	Engine.set_meta("nix_v12", true)
	Engine.set_meta("nix_fbx", true)
	if modo == "combate":
		_combate.call_deferred()
	else:
		_estudio.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _acabar() -> void:
	for k in ["nix_v12", "nix_fbx", "zona", "tipo_combate", "grupo_combate"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var f := FileAccess.open(salida.path_join("medidas_%s.txt" % modo), FileAccess.WRITE)
	f.store_string("\n".join(informe) + "\n")
	f.close()
	print("FOTOS: %d en %s" % [n_fotos, salida])
	quit(0)


func _nivel(i: int) -> void:
	nix.apagar_emision()
	nix._poner_emision(NF.NIVELES[i])


# ---------------------------------------------------------------- estudio
func _estudio() -> void:
	_mundo()
	nix = load("res://personajes/nix/nix_3d.gd").new()
	nix.name = "Nix"
	mundo.add_child(nix)
	nix.scale = Vector3.ONE * ESC
	await _frames(20)
	nix.mirar(Vector3(0, 0, 1), 0.0)
	await _frames(3)
	nix.reproducir(POSE, 0.0)
	nix.anim.seek(POSE_T, true)
	nix.anim.pause()
	await _frames(5)
	mat_ropa = (nix.find_child("ropa_nix", true, false) as MeshInstance3D).get_surface_override_material(0)
	print("SHADER de la ropa: ", mat_ropa.shader.resource_path)
	var ref := _material_referencia()
	var hojas := {}
	for luz_n in ["combate", "anochecer"]:
		_luz(luz_n)
		for cam_n in ["frente", "espalda", "combate", "exploracion"]:
			_camara(cam_n)
			rects[cam_n] = _rect_nix(cam_n)
			var imgs: Array = []
			for i in 4:
				_nivel(i)
				await _frames(3)
				imgs.append(await _foto("%s_%s_%d_%s" % [luz_n, cam_n, i, ["apagada", "basica", "fuerte", "suprema"][i]]))
			hojas["%s_%s" % [luz_n, cam_n]] = imgs
			# apagada = igual que antes: la misma foto con el material de siempre (heroe_v2.gdshader) en la ropa
			_nivel(0)
			var sh: Shader = mat_ropa.shader
			mat_ropa.shader = load("res://personajes/heroes_v2/heroe_v2.gdshader")
			await _frames(3)
			var antes := await _foto("%s_%s_antes_heroe_v2" % [luz_n, cam_n])
			mat_ropa.shader = sh
			var distintos := 0
			for y in antes.get_height():
				for x in antes.get_width():
					if antes.get_pixel(x, y) != imgs[0].get_pixel(x, y):
						distintos += 1
			var lin := "%s %s: apagada frente al material de siempre: %d píxeles distintos" % [luz_n, cam_n, distintos]
			print("MEDIDA ", lin)
			informe.append(lin)
			if luz_n == "combate":
				await _fugas(cam_n, imgs, ref)
	_nivel(0)
	_hoja(hojas)
	_acabar()


func _material_referencia() -> Array:
	# la fuente SIN comprimir (los .webp decodificados), con sus mipmaps
	var mr := Image.load_from_file(ProjectSettings.globalize_path("res://personajes/nix/fbx/nix_fbx_nix_ropa_mr_1024.webp"))
	var co := Image.load_from_file(ProjectSettings.globalize_path("res://personajes/nix/fbx/nix_fbx_nix_ropa_color_1024.webp"))
	mr.generate_mipmaps()
	co.generate_mipmaps()
	var sh := Shader.new()
	sh.code = REF
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("metal_src", ImageTexture.create_from_image(mr))
	m.set_shader_parameter("color_src", ImageTexture.create_from_image(co))
	var negro := ShaderMaterial.new()
	negro.shader = sh
	negro.set_shader_parameter("negro", true)
	return [m, negro]


# Fugas: con la suprema, píxeles que se aclaran fuera de la referencia de ornamentos (dilatada 1 px).
func _fugas(cam_n: String, imgs: Array, ref: Array) -> void:
	var ropa := nix.find_child("ropa_nix", true, false) as MeshInstance3D
	var cuerpo := nix.find_child("cuerpo_nix", true, false) as MeshInstance3D
	var cetro: Array = nix.vara.find_children("*", "MeshInstance3D", true, false) if nix.vara != null else []
	ropa.material_override = ref[0]
	cuerpo.material_override = ref[1]
	for c in cetro:
		c.material_override = ref[1]
	var bg := env.background_color
	env.background_color = Color.BLACK
	await _frames(3)
	await RenderingServer.frame_post_draw
	var r := root.get_texture().get_image()
	r.save_png(salida.path_join("referencia_%s.png" % cam_n))
	ropa.material_override = null
	cuerpo.material_override = null
	for c in cetro:
		c.material_override = null
	env.background_color = bg
	await _frames(3)
	var w := r.get_width()
	var h := r.get_height()
	# referencia dilatada 1 y 3 píxeles
	var m0 := PackedByteArray()
	m0.resize(w * h)
	for y in h:
		for x in w:
			m0[y * w + x] = 1 if r.get_pixel(x, y).r > 0.5 else 0
	var m1 := _dilatar(m0, w, h)
	var m3 := _dilatar(_dilatar(m1, w, h), w, h)
	for nv in [1, 2, 3]:
		var a: Image = imgs[0]
		var b: Image = imgs[nv]
		var dif := Image.create(w, h, false, Image.FORMAT_RGB8)
		var claros := 0
		var fuga := 0
		var fuga3 := 0
		var e_total := 0.0
		var e_fuga := 0.0
		var e_fuga3 := 0.0
		for y in h:
			for x in w:
				var d := b.get_pixel(x, y).get_luminance() - a.get_pixel(x, y).get_luminance()
				if d <= 3.0 / 255.0:
					continue
				claros += 1
				e_total += d
				var i := y * w + x
				if m1[i] == 1:
					dif.set_pixel(x, y, Color(minf(d * 4.0, 1.0), minf(d * 4.0, 1.0), 0.0))
				else:
					fuga += 1
					e_fuga += d
					if m3[i] == 0:
						fuga3 += 1
						e_fuga3 += d
					dif.set_pixel(x, y, Color(0.0, minf(0.3 + d * 4.0, 1.0), minf(0.3 + d * 4.0, 1.0)))
		dif.save_png(salida.path_join("diferencia_%s_%d.png" % [cam_n, nv]))
		var lin := "%s nivel %d (%.2f): %d píxeles más claros (energía %.2f); a más de 1 px de un ornamento %d (%.2f %% de la energía); a más de 3 px %d (%.2f %%)" % [
			cam_n, nv, NF.NIVELES[nv], claros, e_total, fuga, 100.0 * e_fuga / maxf(e_total, 0.0001), fuga3,
			100.0 * e_fuga3 / maxf(e_total, 0.0001)]
		print("MEDIDA ", lin)
		informe.append(lin)


func _dilatar(m: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var o := m.duplicate()
	for y in h:
		for x in w:
			if m[y * w + x] == 1:
				for yy in range(maxi(0, y - 1), mini(h, y + 2)):
					for xx in range(maxi(0, x - 1), mini(w, x + 2)):
						o[yy * w + xx] = 1
	return o


func _hoja(hojas: Dictionary) -> void:
	# una hoja por luz: filas = cámaras, columnas = apagada, básica, fuerte, suprema (recorte de Nix a 320×360)
	for luz_n in ["combate", "anochecer"]:
		var hoja := Image.create(320 * 4, 360 * 4, false, Image.FORMAT_RGB8)
		var fila := 0
		for cam_n in ["frente", "espalda", "combate", "exploracion"]:
			var imgs: Array = hojas["%s_%s" % [luz_n, cam_n]]
			for i in 4:
				var img: Image = imgs[i]
				var rec := _recorte_nix(img, cam_n)
				hoja.blit_rect(rec, Rect2i(0, 0, 320, 360), Vector2i(i * 320, fila * 360))
			fila += 1
		hoja.save_png(salida.path_join("HOJA_%s.png" % luz_n))


func _rect_nix(cam_n: String) -> Rect2i:
	var c := cam.unproject_position(Vector3(0, 0.75, 0))
	if cam_n in ["frente", "espalda"]:
		return Rect2i(clampi(int(c.x) - 320, 0, 640), 0, 640, 720)
	# combate y exploración: Nix pequeña, recorte de 160×180 ampliado ×2 sin suavizar
	return Rect2i(clampi(int(c.x) - 80, 0, 1280 - 160), clampi(int(c.y) - 90, 0, 720 - 180), 160, 180)


func _recorte_nix(img: Image, cam_n: String) -> Image:
	var r := img.get_region(rects[cam_n])
	r.convert(Image.FORMAT_RGB8)
	r.resize(320, 360, Image.INTERPOLATE_LANCZOS if cam_n in ["frente", "espalda"] else Image.INTERPOLATE_NEAREST)
	return r


func _mundo() -> void:
	mundo = Node3D.new()
	root.add_child(mundo)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	luz = DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, -40, 0)
	mundo.add_child(luz)
	rel = DirectionalLight3D.new()
	rel.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(rel)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	suelo.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.13, 0.12)
	suelo.material_override = m
	mundo.add_child(suelo)
	cam = Camera3D.new()
	mundo.add_child(cam)
	cam.current = true


func _luz(n: String) -> void:
	if n == "combate":            # combate.gd: ambiente cálido 0,6, principal FFE2B0 1,3, relleno 7FA0D8 0,3, sin glow
		env.background_color = Color(0.22, 0.24, 0.28)
		env.ambient_light_color = Color(1.0, 0.86, 0.78)
		env.ambient_light_energy = 0.6
		luz.light_color = Color("FFE2B0"); luz.light_energy = 1.3
		rel.light_color = Color("7FA0D8"); rel.light_energy = 0.3
		env.glow_enabled = false
	else:                         # anochecer oscuro (como Oakhaven) con resplandor de umbral bajo
		env.background_color = Color(0.06, 0.07, 0.11)
		env.ambient_light_color = Color(0.45, 0.5, 0.72)
		env.ambient_light_energy = 0.3
		luz.light_color = Color("FFB070"); luz.light_energy = 0.35
		rel.light_color = Color("7FA0D8"); rel.light_energy = 0.15
		env.glow_enabled = true
		env.glow_intensity = 1.0
		env.glow_bloom = 0.1
		env.glow_hdr_threshold = 0.85


func _camara(n: String) -> void:
	var c := Vector3(0, 0.8, 0)
	match n:
		"frente", "espalda":
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = 35.0
			var z := 3.1 if n == "frente" else -3.1
			cam.look_at_from_position(c + Vector3(0, 0.25, z), c, Vector3.UP)
		"combate":
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = 5.3                                   # Nix ≈ 205 px de alto en 720, como en el combate
			var ang := deg_to_rad(12.0)
			c = Vector3(0, 0.9, 0)
			cam.look_at_from_position(c + Vector3(0, sin(ang) * 6.0, cos(ang) * 6.0), c, Vector3.UP)
		"exploracion":
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = 35.0
			var ang2 := deg_to_rad(35.0)
			c = Vector3(0, 0.9, 0)
			cam.look_at_from_position(c + Vector3(0, sin(ang2) * 10.0, cos(ang2) * 10.0), c, Vector3.UP)


func _foto(nombre: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(salida.path_join(nombre + ".png"))
	n_fotos += 1
	return img


# ---------------------------------------------------------------- combate real
func _combate() -> void:
	var G = load("res://grupo.gd")
	G.datos()
	G.unir("Nix")
	G.formar(["Kael", "Lya", "Nix"])
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	var c: Node = load("res://combate.tscn").instantiate()
	root.add_child(c)
	c.MODO_PRUEBAS = false
	for e in c.enemigos:
		e["atb"] = 0.0
		e["vel"] = 0.0
	for h in c.heroes:
		h["atb"] = 0.0
		h["vel"] = 0.0
	var f: Dictionary = {}
	for h in c.heroes:
		if h["nombre"] == "Nix":
			f = h
	nix = c._p3d(f)
	if nix == null or nix.get("_mat_ropa") == null:
		print("FALLO: Nix FBX no está en el combate")
		quit(1)
		return
	await create_timer(2.5).timeout
	var imgs: Array = []
	for i in 4:
		_nivel(i)
		await _frames(4)
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var nombre := "combate_%s_%d_%s" % [zona, i, ["apagada", "basica", "fuerte", "suprema"][i]]
		img.save_png(salida.path_join(nombre + ".png"))
		n_fotos += 1
		imgs.append(img)
	# recorte de Nix (su sitio en la pantalla, del punto de la magia hacia abajo), ×3 sin suavizar, los cuatro juntos
	var cen: Vector2 = c._punto_magia(f)
	var g: Vector2 = c.escena.get_global_transform_with_canvas() * cen
	var rect := Rect2i(clampi(int(g.x) - 20, 0, 1280 - 180), clampi(int(g.y) - 40, 0, 720 - 240), 180, 240)
	var hoja := Image.create(180 * 3 * 4, 240 * 3, false, Image.FORMAT_RGB8)
	for i in 4:
		var r: Image = imgs[i].get_region(rect)
		r.convert(Image.FORMAT_RGB8)
		r.resize(540, 720, Image.INTERPOLATE_NEAREST)
		hoja.blit_rect(r, Rect2i(0, 0, 540, 720), Vector2i(i * 540, 0))
	hoja.save_png(salida.path_join("HOJA_combate_%s.png" % zona))
	informe.append("combate %s: recorte de Nix %s (pantalla 1280×720)" % [zona, str(rect)])
	_nivel(0)
	_acabar()
