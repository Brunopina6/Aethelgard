extends SceneTree
# MEDIDA (19/11, TRANSPARENCIAS_19_11, PC-9): ¿oscurecen las transparencias con la escala 3D < 1 (perfiles bajo y
# medio) en Compatibility? Pinta una fila de cuadros NEGROS al 50 % de cada tipo de transparencia que usa el juego
# (mezcla, recorte, trama, prepasada de profundidad, multiplicar, sombreado propio con ALPHA, color de vértice,
# Sprite3D) sobre un suelo opaco de color conocido, y lee el color en el centro de cada cuadro con cada configuración
# (escala 3D 1,0 / 0,8 / 0,75, MSAA, ambiente sencillo o el de la muestra de la calle con y sin resplandor).
# No es una prueba: mide y guarda capturas y un JSON. Con ventana (no --headless):
#   Godot --resolution 640x360 --script res://pruebas/herramientas/medir_transparencias.gd -- salida=<carpeta>

const SUELO := Color(0.8, 0.8, 0.8)
const CAPA := Color(0.0, 0.0, 0.0, 0.5)

var salida := "user://"
var cam: Camera3D
var ambiente: Environment
var cuadros: Array = []          # [nombre, posición 3D del centro]
var configs: Array = []
var ci := 0
var frames := 0
var resultado := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	DirAccess.make_dir_recursive_absolute(salida)
	var we := WorldEnvironment.new()
	ambiente = Environment.new()
	we.environment = ambiente
	root.add_child(we)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.0
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 10, 0.001), Vector3.ZERO, Vector3.FORWARD)
	cam.current = true
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-60, 30, 0)
	root.add_child(sol)
	# Suelo opaco: mitad izquierda StandardMaterial sin luz; mitad derecha sombreado propio como el de la calle
	# (unshaded, depth_draw_opaque).
	var suelo_std := StandardMaterial3D.new()
	suelo_std.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	suelo_std.albedo_color = SUELO
	_plano(Vector3(0, 0, -1.0), Vector2(14, 2.0), suelo_std)
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, cull_back, depth_draw_opaque;\nvoid fragment(){ ALBEDO = vec3(0.8); }\n"
	var suelo_sh := ShaderMaterial.new()
	suelo_sh.shader = sh
	_plano(Vector3(0, 0, 1.0), Vector2(14, 2.0), suelo_sh)
	var tipos := _materiales()
	var n := tipos.size()
	for i in n:
		var x := -5.0 + 10.0 * float(i) / float(n - 1)
		for fila in [-1.0, 1.0]:
			var p := Vector3(x, 0.05, fila)
			var t: Array = tipos[i]
			if t[1] == null:
				var s := Sprite3D.new()
				var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
				img.fill(CAPA)
				s.texture = ImageTexture.create_from_image(img)
				s.pixel_size = 0.07
				s.axis = Vector3.Axis.AXIS_Y
				s.position = p
				root.add_child(s)
			else:
				var m: MeshInstance3D = _plano(p, Vector2(0.55, 0.55), t[1])
				if t[0] == "vertice":
					m.mesh = _plano_vertice()
			cuadros.append([t[0] + ("_std" if fila < 0 else "_sh"), p])
	cuadros.append(["suelo_std", Vector3(0, 0.0, -1.7)])
	cuadros.append(["suelo_sh", Vector3(0, 0.0, 1.7)])
	for env in ["simple", "calle", "calle_glow"]:
		for e in [[1.0, 0], [1.0, 2], [0.8, 0], [0.75, 0], [0.75, 2], [0.99, 0]]:
			configs.append({"env": env, "escala": e[0], "msaa": e[1]})


func _materiales() -> Array:
	var r := []
	var base := func(f: Callable) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = CAPA
		f.call(m)
		return m
	r.append(["mezcla", base.call(func(m): m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA)])
	r.append(["mezcla_luz", base.call(func(m):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL)])
	r.append(["prepasada", base.call(func(m): m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS)])
	r.append(["trama", base.call(func(m): m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH)])
	r.append(["recorte", base.call(func(m):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4)])
	r.append(["multiplicar", base.call(func(m):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		m.albedo_color = Color(0.5, 0.5, 0.5, 1.0))])
	r.append(["premult", base.call(func(m):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA)])
	r.append(["vertice", base.call(func(m):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color.WHITE)])
	for modo in ["blend_mix", "blend_mul", "blend_premul_alpha"]:
		var s := Shader.new()
		var col := "ALBEDO = vec3(0.0); ALPHA = 0.5;"
		if modo == "blend_mul":
			col = "ALBEDO = vec3(0.5);"
		s.code = "shader_type spatial;\nrender_mode unshaded, %s, depth_draw_never, cull_disabled;\nvoid fragment(){ %s }\n" % [modo, col]
		var sm := ShaderMaterial.new()
		sm.shader = s
		r.append(["sh_" + modo.substr(6), sm])
	r.append(["sprite3d", null])
	# multiplicar con otros grises (¿cómo escala el error con resplandor?) y con niebla apagada
	for g in [1.0, 0.9, 0.75]:
		r.append(["mul_%03d" % int(g * 100), base.call(func(m):
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			m.albedo_color = Color(g, g, g, 1.0))])
	r.append(["sumar", base.call(func(m):     # el humo y las motas del alto de la muestra (BLEND_MODE_ADD)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.1, 0.1, 0.1, 1.0))])
	var s2 := Shader.new()
	s2.code = "shader_type spatial;\nrender_mode unshaded, blend_mul, depth_draw_never, cull_disabled, fog_disabled;\nvoid fragment(){ ALBEDO = vec3(0.5); }\n"
	var sm2 := ShaderMaterial.new()
	sm2.shader = s2
	r.append(["sh_mul_sinniebla", sm2])
	return r


func _plano(p: Vector3, tam: Vector2, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tam
	m.mesh = pm
	m.material_override = mat
	m.position = p
	root.add_child(m)
	return m


func _plano_vertice() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := 0.275
	var v := [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_color(CAPA)
		st.set_normal(Vector3.UP)
		st.add_vertex(v[i])
	return st.commit()


func _aplicar(c: Dictionary) -> void:
	var vp := root.get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = c.escala
	vp.msaa_3d = Viewport.MSAA_2X if c.msaa == 2 else Viewport.MSAA_DISABLED
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.2, 0.4, 0.2)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color.WHITE
	var calle: bool = c.env != "simple"
	ambiente.fog_enabled = calle
	ambiente.fog_light_color = Color(0.86, 0.76, 0.62)
	ambiente.fog_density = 0.0025
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC if calle else Environment.TONE_MAPPER_LINEAR
	ambiente.tonemap_exposure = 0.86 if calle else 1.0
	ambiente.adjustment_enabled = calle
	ambiente.adjustment_saturation = 1.12
	ambiente.adjustment_contrast = 1.12
	ambiente.glow_enabled = c.env == "calle_glow"
	ambiente.glow_intensity = 0.35
	ambiente.glow_bloom = 0.02
	ambiente.glow_hdr_threshold = 1.1


func _process(_d: float) -> bool:
	if ci >= configs.size():
		var f := FileAccess.open(salida.path_join("medidas.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(resultado, "  "))
		f.close()
		print("MEDIR_TRANSPARENCIAS FIN %d configuraciones -> %s" % [configs.size(), salida])
		return true
	var c: Dictionary = configs[ci]
	if frames == 0:
		_aplicar(c)
	frames += 1
	if frames < 12:
		return false
	var img := root.get_viewport().get_texture().get_image()
	var clave := "%s_e%.2f_m%d" % [c.env, c.escala, c.msaa]
	img.save_png(salida.path_join(clave + ".png"))
	var med := {}
	for q in cuadros:
		var px := cam.unproject_position(q[1]) * Vector2(img.get_size()) / root.get_viewport().get_visible_rect().size
		var col := img.get_pixelv(Vector2i(px).clamp(Vector2i.ZERO, img.get_size() - Vector2i.ONE))
		med[q[0]] = [snappedf(col.r, 0.001), snappedf(col.g, 0.001), snappedf(col.b, 0.001), snappedf(col.a, 0.001)]
	resultado[clave] = med
	print("%s %s" % [clave, JSON.stringify(med)])
	ci += 1
	frames = 0
	return false
