extends SceneTree
# Capturas del arte del Mar de Cristal (V12, gráficos): cada pieza sola (estudio: el modelo alto con el perfil alto y
# el ligero con el bajo) y una escena de prueba montada con las piezas en los sitios del contrato (docs/v12/DISENO_V12.md):
# campamento, caravana, oasis, cañón y cobijo, nicho con el esqueleto, ruinas y trampilla, la arena que tiembla, el
# espejismo, la tormenta (viento 1) y las ondas de calor (solo alto). La escena de prueba NO es la región (la región es
# zonas3d/mar_cristal_3d.*, del coordinador): el suelo de dunas, el estanque, la luz y la bruma son de esta prueba.
# Anota llamadas de dibujo, primitivas, GPU y FPS (en PC: no dice nada del Redmi). Las capturas las revisa una persona.
# Uso: --path aethelgard --script res://pruebas/fotos_desierto_arte.gd -- salida=<carpeta> [perfiles=alto,bajo]
#      [res=1280x720] [solo=piezas|escena]
# No toca ninguna partida: no carga progreso ni guarda nada.

const Arte := preload("res://zonas3d/mar_cristal/materiales_arte.gd")
const Calidad := preload("res://prototipos/calidad_proto.gd")

# Dónde va cada pieza en la escena de prueba: [id, x, z, giro en grados]
const MONTAJE := [
	["tienda_a", 32.5, 89.5, 0.0], ["tienda_b", 41.0, 93.0, 0.0], ["fogata", 37.0, 95.0, 0.0],
	["caravana_barril", 34.5, 93.6, 30.0], ["caravana_cajas", 29.0, 93.5, -10.0],
	["caravana_carro", 50.0, 60.0, 0.0], ["caravana_cajas", 52.8, 62.3, 25.0], ["caravana_barril", 47.2, 62.8, 0.0],
	["caravana_tela", 53.5, 57.8, 0.0],
	["palmera_a", 69.0, 66.5, 0.0], ["palmera_b", 80.5, 68.0, 0.0], ["palmera_a", 78.0, 79.5, 140.0],
	["palmera_b", 66.5, 77.5, 200.0], ["palmera_a", 83.5, 74.5, 70.0],
	["juncos", 68.5, 70.5, 0.0], ["juncos", 72.0, 79.0, 60.0], ["juncos", 79.5, 72.0, 120.0], ["juncos", 75.5, 64.6, 200.0],
	["juncos", 70.0, 75.5, 300.0], ["juncos", 81.0, 77.0, 30.0],
	["roca_canon_b", 5.0, 30.0, 0.0], ["roca_canon_b", 4.0, 41.0, 180.0], ["roca_cobijo", 14.0, 48.0, 0.0],
	["roca_canon_b", 5.5, 60.0, 0.0], ["roca_canon_b", 4.5, 72.0, 180.0], ["roca_canon_a", 15.5, 21.5, 0.0],
	["roca_canon_d", 16.5, 70.0, 0.0], ["roca_canon_c", 13.0, 36.0, 40.0], ["roca_canon_c", 12.5, 79.0, 200.0],
	["esqueleto", 8.4, 30.6, 0.0],
	["ruinas_arco", 45.0, 15.5, 0.0], ["ruinas_columna_a", 39.5, 19.0, 0.0], ["ruinas_columna_b", 50.5, 19.5, 0.0],
	["ruinas_columna_c", 47.5, 26.5, 15.0], ["ruinas_columna_d", 37.5, 13.5, 0.0], ["ruinas_muro", 53.0, 12.5, -10.0],
	["ruinas_columna_a", 41.0, 11.0, 0.0], ["trampilla", 45.0, 22.0, 0.0],
	["huesos_costillas", 73.5, 35.0, -8.0],
]
# Encuadres de juego (cámara al norte, 50°, 20 m, como vista3d.gd): [nombre, punto de mira (x, z), distancia]
const SITIOS := [
	["e01_campamento", 36.0, 92.0, 20.0],
	["e02_caravana", 50.0, 60.5, 20.0],
	["e03_oasis", 74.0, 72.0, 24.0],
	["e04_canon_cobijo", 13.0, 48.0, 22.0],
	["e05_nicho_esqueleto", 9.5, 31.0, 9.0],
	["e06_ruinas", 45.0, 18.0, 22.0],
	["e07_trampilla", 45.0, 22.0, 9.0],
	["e08_arena_que_tiembla", 74.0, 36.0, 26.0],
	["e09_espejismo", 81.0, 31.0, 14.0],
]
const ESTUDIO := Vector3(400.0, 0.0, 400.0)

var salida := "D:/REBELUM_diagnostico/v12/arte/fotos"
var perfiles: Array = ["alto", "bajo"]
var tam := Vector2i(1280, 720)
var solo := ""
var filtro: Array = []          # piezas=a,b: solo esas piezas en el estudio
var p: Dictionary = {}
var nombre_perfil := ""
var mundo: Node3D
var cam: Camera3D
var sol: DirectionalLight3D
var env: Environment
var ruido_dunas := FastNoiseLite.new()
var ruido_suave := FastNoiseLite.new()
var fallos := 0
var _gpu: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("res="):
			var r: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(r[0]), int(r[1]))
		elif a.begins_with("piezas="):
			filtro = Array(a.substr(7).split(","))
		elif a.begins_with("solo="):
			solo = a.substr(5)
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(tam)
	root.size = tam
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	ruido_dunas.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido_dunas.frequency = 0.022
	ruido_dunas.seed = 31
	ruido_suave.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido_suave.frequency = 0.05
	ruido_suave.seed = 7
	_correr.call_deferred()


func _correr() -> void:
	for nombre in perfiles:
		nombre_perfil = String(nombre)
		p = Calidad.PERFILES[nombre_perfil].duplicate()
		Arte.liberar()
		_montar_mundo()
		await _frames(10)
		if solo != "escena":
			await _estudio()
		if solo != "piezas":
			await _escena()
		mundo.queue_free()
		await _frames(3)
	Arte.liberar()
	print("FOTOS hechas en %s · fallos %d" % [salida, fallos])
	if fallos > 0:
		print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# ---------------------------------------------------------------- mundo

func _montar_mundo() -> void:
	mundo = Node3D.new()
	mundo.name = "MundoPrueba"
	root.add_child(mundo)
	root.scaling_3d_scale = float(p.get("escala_3d", 1.0))
	root.msaa_3d = Viewport.MSAA_2X if int(p.get("msaa", 0)) >= 2 else Viewport.MSAA_DISABLED
	env = Environment.new()
	var cielo := Sky.new()
	var mc := ProceduralSkyMaterial.new()
	mc.sky_top_color = Color(0.36, 0.55, 0.80)
	mc.sky_horizon_color = Color(0.98, 0.84, 0.66)
	mc.ground_horizon_color = Color(0.98, 0.84, 0.66)
	mc.ground_bottom_color = Color(0.80, 0.62, 0.45)
	mc.sun_angle_max = 20.0
	cielo.sky_material = mc
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.72, 0.62)       # relleno cálido: la sombra del desierto no es gris
	env.ambient_light_energy = 0.36 if not bool(p.get("sombras", false)) else 0.16   # ver informe: con sombras, el ambiente cuenta más
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true                                   # bruma cálida
	env.fog_light_color = Color(0.97, 0.82, 0.64)
	env.fog_density = 0.0055 if not bool(p.get("sombras", false)) else 0.0028
	env.fog_sky_affect = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	sol = DirectionalLight3D.new()                          # sol de media tarde desde el suroeste: sombras largas
	sol.rotation_degrees = Vector3(-36, -38, 0)
	sol.light_color = Color(1.0, 0.85, 0.66)
	sol.light_energy = 0.95
	sol.shadow_enabled = bool(p.get("sombras", false))
	sol.directional_shadow_max_distance = maxf(30.0, float(p.get("dist_sombras", 40.0)))
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if int(p.get("sombra_tramos", 1)) <= 1 \
		else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	RenderingServer.directional_shadow_atlas_set_size(int(p.get("sombra_res", 2048)), true)
	mundo.add_child(sol)
	cam = Camera3D.new()
	cam.fov = 38.0
	cam.far = 500.0
	mundo.add_child(cam)
	cam.current = true
	_suelo()
	_estanque()
	for m in MONTAJE:
		var n := Arte.modelo(String(m[0]), p)
		mundo.add_child(n)
		n.position = Vector3(m[1], _altura(m[1], m[2]), m[2])
		n.rotation_degrees.y = m[3]
		if n.get_child_count() == 0:
			fallos += 1
			print("FALLO: la pieza %s no tiene nada" % m[0])
	var esp := Arte.modelo("palmera_a", p, true)
	esp.name = "Espejismo"
	mundo.add_child(esp)
	esp.position = Vector3(82.0, _altura(82.0, 30.0), 30.0)
	_fuego(Vector3(37.0, 0.2, 95.0))
	var kael := MeshInstance3D.new()                        # referencia de escala (1,75 m), no es Kael
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.75
	kael.mesh = cap
	var mk := StandardMaterial3D.new()
	mk.albedo_color = Color(0.45, 0.12, 0.12)
	kael.material_override = mk
	kael.name = "Escala"
	mundo.add_child(kael)
	var arrastre := Arte.arena_arrastrada(p)
	mundo.add_child(arrastre)
	Arte.intensidad_viento(mundo, Arte.VIENTO_CALMA)


func _altura(x: float, z: float) -> float:
	var n := ruido_dunas.get_noise_2d(x, z * 1.7)
	var h := pow(1.0 - absf(n), 3.0) * 3.2 + ruido_suave.get_noise_2d(x, z) * 0.5
	# llano donde hay cosas (las piezas se asientan en y ≈ 0) y en el cañón
	var llano := 1.0
	for s in [[36.0, 92.0, 9.0], [50.0, 60.0, 7.0], [74.0, 72.0, 13.0], [45.0, 18.0, 12.0], [10.0, 50.0, 10.0],
			[74.0, 35.0, 11.0], [82.0, 30.0, 4.0], [45.0, 100.0, 6.0]]:
		var d := Vector2(x - s[0], z - s[1]).length()
		llano = minf(llano, smoothstep(s[2], s[2] * 1.9, d))
	llano = minf(llano, smoothstep(18.0, 26.0, x))
	h *= llano
	var d_o := Vector2(x - 74.0, z - 72.0).length()          # el estanque
	if d_o < 7.0:
		h -= 0.9 * pow(1.0 - d_o / 7.0, 1.5)
	return h


func _suelo() -> void:
	var paso := 1.0 if Arte.detalle_alto(p) else 2.0
	var x0 := -12.0
	var z0 := -12.0
	var nx := int(124.0 / paso)
	var nz := int(136.0 / paso)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in nx + 1:
		for j in nz + 1:
			var x := x0 + i * paso
			var z := z0 + j * paso
			var c := Color(1, 1, 1)
			var d_o := Vector2(x - 74.0, z - 72.0).length()
			c = c.lerp(Color(0.78, 0.66, 0.56), clampf(1.0 - (d_o - 6.0) / 3.0, 0.0, 1.0))   # arena mojada
			if x < 20.0:
				c = c * Color(1.0, 0.92, 0.86)                                              # polvo rojizo del cañón
			st.set_color(c)
			st.set_uv(Vector2(x, z))
			st.add_vertex(Vector3(x, _altura(x, z), z))
	for i in nx:
		for j in nz:
			var a := i * (nz + 1) + j
			var b := a + nz + 1
			for k in [a, b, a + 1, b, b + 1, a + 1]:
				st.add_index(k)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Suelo"
	mi.mesh = st.commit()
	mi.material_override = Arte.mat_arena(p)
	mundo.add_child(mi)
	# el suelo del estudio: un llano grande
	var pl := PlaneMesh.new()
	pl.size = Vector2(60, 60)
	pl.subdivide_width = 30
	pl.subdivide_depth = 30
	var est := MeshInstance3D.new()
	est.mesh = pl
	est.position = ESTUDIO
	est.material_override = Arte.mat_arena(p)
	mundo.add_child(est)


func _estanque() -> void:
	# agua de prueba: disco con color de vértice (hondo en el centro, turquesa en la orilla)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 32
	var r := 7.4
	var centro := Vector3(74.0, -0.32, 72.0)
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		for t in [[0.0, 0.55], [0.55, 1.0]]:
			var c0 := Color(0.05, 0.22, 0.30, 0.95).lerp(Color(0.20, 0.62, 0.62, 0.55), t[0])
			var c1 := Color(0.05, 0.22, 0.30, 0.95).lerp(Color(0.20, 0.62, 0.62, 0.55), t[1])
			var pts := [centro + Vector3(cos(a0), 0, sin(a0)) * r * t[0], centro + Vector3(cos(a1), 0, sin(a1)) * r * t[0],
				centro + Vector3(cos(a1), 0, sin(a1)) * r * t[1], centro + Vector3(cos(a0), 0, sin(a0)) * r * t[1]]
			var cols := [c0, c0, c1, c1]
			for q in [0, 2, 1, 0, 3, 2]:
				st.set_color(cols[q])
				st.set_normal(Vector3.UP)
				st.add_vertex(pts[q])
	var mi := MeshInstance3D.new()
	mi.name = "Estanque"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.06
	m.metallic_specular = 0.8
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mundo.add_child(mi)


func _fuego(pos: Vector3) -> void:
	var f := CPUParticles3D.new()
	f.amount = 24
	f.lifetime = 0.7
	f.position = pos
	f.direction = Vector3.UP
	f.spread = 12.0
	f.initial_velocity_min = 0.6
	f.initial_velocity_max = 1.2
	f.gravity = Vector3(0, 0.6, 0)
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.15
	f.scale_amount_min = 0.6
	f.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.28, 0.4)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.55, 0.18, 0.8)
	m.vertex_color_use_as_albedo = true
	q.material = m
	f.mesh = q
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.9, 0.5, 1), Color(1, 0.4, 0.1, 0.6), Color(0.6, 0.15, 0.05, 0)])
	f.color_ramp = g
	mundo.add_child(f)
	if bool(p.get("luces_faroles", false)):
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.6, 0.3)
		luz.light_energy = 1.2
		luz.omni_range = 6.0
		luz.position = pos + Vector3(0, 0.6, 0)
		mundo.add_child(luz)


# ---------------------------------------------------------------- capturas

func _medir(n: int) -> void:
	_gpu.clear()
	for i in n:
		await process_frame
		var g := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		if g > 0.0 and g < 1000.0:
			_gpu.append(g)


func _mediana(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var o := a.duplicate()
	o.sort()
	return o[o.size() / 2]


func _foto(nombre: String) -> void:
	var ruta := "%s/%s_%s_%dx%d.png" % [salida, nombre, nombre_perfil, tam.x, tam.y]
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(ruta)
	var dib := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("DIBUJO %s %s: llamadas %d · primitivas %d · objetos %d · GPU %.2f ms (mediana) · %d FPS" % [
		nombre_perfil, nombre, dib, prim, obj, _mediana(_gpu), Engine.get_frames_per_second()])


func _camara_juego(objetivo: Vector3, dist: float, incl := 50.0) -> void:
	var a := deg_to_rad(incl)
	var ojo := objetivo + Vector3(0, 0.9, 0)
	cam.global_position = ojo + Vector3(0, sin(a), cos(a)) * dist
	cam.look_at(ojo, Vector3.UP)
	var k := mundo.get_node_or_null("Escala") as Node3D
	if k != null:
		k.position = objetivo + Vector3(0, 0.875, 2.2)


func _aabb(n: Node) -> AABB:
	var caja := AABB()
	var primero := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var t: Transform3D = (n as Node3D).global_transform.affine_inverse() * m.global_transform
		var b: AABB = t * m.get_aabb()
		caja = b if primero else caja.merge(b)
		primero = false
	return caja


func _estudio() -> void:
	var esc := mundo.get_node_or_null("Escala") as Node3D
	for id in Arte.PIEZAS:
		if not filtro.is_empty() and not String(id) in filtro:
			continue
		var n := Arte.modelo(String(id), p)
		mundo.add_child(n)
		n.position = ESTUDIO
		var caja := _aabb(n)
		var vis := caja
		vis.position.y = maxf(caja.position.y, 0.0)
		vis.size.y = maxf(0.5, caja.end.y - vis.position.y)
		var centro := ESTUDIO + vis.get_center()
		var radio := maxf(vis.size.length() * 0.5, 1.0)
		var dist := radio / sin(deg_to_rad(19.0)) * 1.05
		var dir := Vector3(0.55, 0.62, 1.0).normalized()
		cam.global_position = centro + dir * dist
		cam.look_at(centro, Vector3.UP)
		if esc != null:
			esc.position = ESTUDIO + Vector3(caja.end.x + 0.8, 0.875, caja.end.z * 0.5)
		await _medir(14)
		var info := "%s %s" % [id, Arte.ruta(String(id), p).get_file()]
		_foto("p_" + String(id))
		print("PIEZA %s · %s · caja %s" % [nombre_perfil, info, str(caja.size.snapped(Vector3.ONE * 0.1))])
		n.queue_free()
		await process_frame


func _escena() -> void:
	for s in SITIOS:
		var obj := Vector3(s[1], _altura(s[1], s[2]), s[2])
		_camara_juego(obj, s[3])
		await _medir(40)
		_foto(String(s[0]))
	# vista de conjunto (desde el sur, alta) y desde la entrada
	_camara_juego(Vector3(45.0, 0.0, 58.0), 92.0, 58.0)
	await _medir(30)
	_foto("e10_conjunto")
	_camara_juego(Vector3(45.0, 0.0, 96.0), 30.0, 38.0)
	await _medir(30)
	_foto("e11_desde_la_entrada")
	# la tormenta: viento 1, bruma de arena, luz baja (lo decide la región; aquí, una aproximación)
	var arr := mundo.get_node_or_null("ArenaArrastrada") as Node3D
	var obj := Vector3(50.0, 0.0, 60.5)
	if arr != null:
		arr.position = obj
	Arte.intensidad_viento(mundo, 1.0)
	env.fog_density = 0.045
	env.fog_light_color = Color(0.86, 0.66, 0.46)
	sol.light_energy = 0.55
	_camara_juego(obj, 20.0)
	await _medir(40)
	_foto("e12_tormenta_caravana")
	_camara_juego(Vector3(36.0, 0.0, 92.0), 20.0)
	if arr != null:
		arr.position = Vector3(36.0, 0.0, 92.0)
	await _medir(40)
	_foto("e13_tormenta_campamento")
	Arte.intensidad_viento(mundo, Arte.VIENTO_CALMA)
	env.fog_density = 0.0055 if not bool(p.get("sombras", false)) else 0.0028
	env.fog_light_color = Color(0.97, 0.82, 0.64)
	sol.light_energy = 0.95
	# las ondas de calor (solo alto): sobre la arena entre la caravana y las ruinas
	var calor := Arte.calor(p, Vector2(18, 10))
	if calor != null:
		mundo.add_child(calor)
		calor.position = Vector3(50.0, 0.35, 56.0)
		_camara_juego(Vector3(50.0, 0.0, 60.5), 20.0)
		await _medir(40)
		_foto("e14_calor")
	# el espejismo revelado a medias
	Arte.mat_espejismo().set_shader_parameter("espejismo", 0.35)
	_camara_juego(Vector3(81.0, 0.0, 31.0), 14.0)
	await _medir(30)
	_foto("e15_espejismo_desvaneciendo")
	Arte.mat_espejismo().set_shader_parameter("espejismo", 1.0)
