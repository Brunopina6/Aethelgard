extends SceneTree
# Coste de GPU del Gran Bosque Verde 3D frente a Pastos Verdes (V12, rendimiento del Gran Bosque, 12/11). CON ventana y
# datos aislados. En cada región, perfil y sitio: Kael quieto allí, la cámara de juego, y para cada variante (quitar una
# cosa cada vez: copas, troncos, sotobosque, hierba, haces, agua, sombras, partículas, el hueco tramado...) la mediana
# del tiempo de GPU de N fotogramas, las llamadas de dibujo y las primitivas; además el sobredibujado: «capas» =
# fragmentos rasterizados por píxel del 3D (ver _poner_conteo; calibrado con capas conocidas al empezar).
# Viewport.DEBUG_DRAW_OVERDRAW sí funciona en Compatibility, pero cambia también el vértice (no ve el hueco nuevo).
# Uso:
#   Godot --path aethelgard --resolution 1600x720 --script res://pruebas/herramientas/medir_gpu_bosque.gd --
#         salida=<carpeta> [regiones=granbosque,pastos] [perfiles=bajo,medio] [sitios=entrada,...] [variantes=todas|base]
#         [fotos] [n=60] [etiqueta=antes]
# Las cifras del PC no son las del Redmi; sirven para comparar (antes/después, Gran Bosque/Pastos) en el mismo PC.
# Para parecerse al Mali-G57 (Godot no hace prepase de profundidad con Mali, Adreno, PowerVR ni Apple), lánzalo con un
# override.cfg temporal con rendering/driver/depth_prepass/enable=false (ver el informe).

const REGIONES := {"granbosque": "res://zonas3d/gran_bosque_3d.tscn", "pastos": "res://zonas3d/pastos_verdes_3d.tscn"}
const SITIOS_GB := {
	"entrada": Vector2(40.0, 52.0),
	"puente": Vector2(41.6, 33.4),
	"ruinas": Vector2(47.6, 47.6),
	"campamento": Vector2(20.0, 39.0),
	"claro": Vector2(25.5, 28.6),
	"altar": Vector2(38.2, 8.2),
	"bosque_cerrado": Vector2(33.0, 41.0),
	"mirador": Vector2(49.4, 15.6),
}
# Pastos: los puntos del banco (vista3d.gd, BANCO_RUTA), donde se midió el medio a 30 FPS en el Redmi (v336), y dos más
const SITIOS_PV := {"banco_a": Vector3(-3, 0, 5), "banco_b": Vector3(5.3, 0, -2), "banco_c": Vector3(12.7, 0, -2),
	"ruinas": Vector3(-10.0, 0, -9.0), "claro": Vector3(15.0, 0, -15.0),
	"banco_a_34m": Vector3(-3, 0, 5), "banco_b_34m": Vector3(5.3, 0, -2)}   # «_34m»: la cámara a 34 m (en el Redmi, medio a 27,7 FPS)
# Variantes: nombre → categorías que se esconden (o «sombras», «hueco»)
const VARIANTES := {
	"base": [],
	"-hueco": ["hueco"],
	"-copas_hojas": ["copas_hojas"],
	"-copas_macizas": ["copas_macizas"],
	"-troncos": ["troncos"],
	"-sotobosque": ["sotobosque"],
	"-hierba": ["hierba"],
	"-haces": ["haces"],
	"-agua": ["agua"],
	"-sombras": ["sombras"],
	"-particulas": ["particulas"],
	"-suelo": ["suelo"],
	"-personajes": ["personajes"],
	# pruebas de sombreado (cambian el código de los sombreados del escenario mientras se mide)
	"~cerca_off": ["cod:return min(corte_h, smoothstep(0.44, 0.52, distance(p, hueco_a) / largo_h));=>return corte_h;"],
	"~cono_off": ["cod:corte_h = smoothstep(0.62, 1.0, d_h);=>"],
	"~cerca_mas": ["cod:smoothstep(0.44, 0.52, distance(p, hueco_a) / largo_h)=>smoothstep(0.48, 0.57, distance(p, hueco_a) / largo_h)"],
	"-relieve_suelo": ["relieve_suelo"],
	"-sombra_troncos": ["sombra_troncos"],
	"~hojas_lambert": ["cod:render_mode cull_disabled, specular_schlick_ggx;=>render_mode cull_disabled, specular_disabled, diffuse_lambert;"],
	"~maciza_lambert": ["cod:render_mode cull_back, diffuse_burley, specular_disabled;=>render_mode cull_back, diffuse_lambert, specular_disabled;"],
	"~hojas_sin_sombra": ["cod:render_mode cull_disabled, specular_schlick_ggx;=>render_mode cull_disabled, specular_schlick_ggx, shadows_disabled;"],
}

var salida := ""
var regiones: Array = ["granbosque", "pastos"]
var perfiles: Array = ["bajo", "medio", "alto"]
var sitios_pedidos: Array = []
var variantes: Array = VARIANTES.keys()
var fotos := false
var n_muestras := 60
var etiqueta := ""
var depurar := false
var amplia := 1.0                       # amplia=2: el 3D al doble de resolución (×4 fragmentos) para medir el coste por píxel
var R
var filas: Array = []
var calibra: Array = []                  # [capas, valor del canal rojo]
var _fondo: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3))


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("regiones="):
			regiones = Array(a.substr(9).split(","))
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("sitios="):
			sitios_pedidos = Array(a.substr(7).split(","))
		elif a.begins_with("variantes="):
			var v := a.substr(10)
			variantes = VARIANTES.keys() if v == "todas" else Array(v.split(","))
		elif a == "fotos":
			fotos = true
		elif a.begins_with("n="):
			n_muestras = int(a.substr(2))
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a.begins_with("extra="):                      # extra=sombras:false,gb_hojas_hasta:-1 (calidad_extra, A/B)
			var ex := {}
			for par in a.substr(6).split(","):
				var kv := par.split(":")
				ex[kv[0]] = (kv[1] == "true") if kv[1] in ["true", "false"] else (float(kv[1]) if kv[1].is_valid_float() else kv[1])
			Engine.set_meta("calidad_extra", ex)
		elif a == "depurar":
			depurar = true
		elif a.begins_with("amplia="):
			amplia = float(a.substr(7))
	if salida == "":
		salida = OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(salida)
	R = root.get_node("Recursos")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("archivo_partida_prueba", "user://medir_gpu_bosque.save")
	Engine.set_meta("incienso", 100000)
	var h := {}
	for id in ["pv_01", "pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo", "bq_inicio"]:
		h[id] = true
	Engine.set_meta("hitos", h)
	print("prepase de profundidad: ", ProjectSettings.get_setting("rendering/driver/depth_prepass/enable"),
		" · ventana ", DisplayServer.window_get_size(), " · ", RenderingServer.get_video_adapter_name())
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


# ---------------------------------------------------------------- calibración del sobredibujado
# Una escena vacía con 12 columnas: en la k, k planos uno detrás de otro. Con DEBUG_DRAW_OVERDRAW cada fragmento suma lo
# mismo; se apunta el verde medio de cada columna para pasar de color a capas.
func _calibrar() -> void:
	var raiz := Node3D.new()
	root.add_child(raiz)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	cam.position = Vector3(0, 0, 10)
	raiz.add_child(cam)
	cam.make_current()
	var mat := _mat_conteo_simple("cull_back")
	var ocultas: Array = []
	for c in root.find_children("*", "CanvasLayer", true, false):
		if c.visible:
			ocultas.append(c)
			c.visible = false
	RenderingServer.set_default_clear_color(Color.BLACK)
	root.use_hdr_2d = true                         # lienzo de coma flotante: no se satura en 1
	cam.size = 17.0
	for k in range(1, 41):
		for j in k:
			var mi := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.3, 6.0)
			mi.mesh = q
			mi.material_override = mat
			mi.position = Vector3(-14.0 + (k - 1) * 0.7, 0, -float(j) * 0.1)
			raiz.add_child(mi)
	await _esperar(6)
	var img := root.get_texture().get_image()
	var tam := img.get_size()
	var aspecto := float(tam.x) / tam.y
	if depurar:
		img.save_png(salida.path_join("calibracion.png"))
		print("código de conteo: ", mat.shader.code, " · cámara actual: ", root.get_camera_3d(), " · ", root.get_texture().get_size())
	calibra.append([0, img.get_pixel(tam.x / 2, 5).r])
	for k in range(1, 41):
		var x_mundo := -14.0 + (k - 1) * 0.7
		var px := int((x_mundo / (cam.size * aspecto * 0.5) * 0.5 + 0.5) * tam.x)
		calibra.append([k, img.get_pixel(px, tam.y / 2).r])
	print("calibración de capas (capas → rojo): ", calibra)
	for c in ocultas:
		c.visible = true
	RenderingServer.set_default_clear_color(_fondo)
	root.use_hdr_2d = false
	raiz.queue_free()
	await _esperar(2)


func _capas_de(g: float) -> float:
	for k in range(1, calibra.size()):
		var a: Array = calibra[k - 1]
		var b: Array = calibra[k]
		if g <= b[1] or k == calibra.size() - 1:
			if b[1] - a[1] < 0.0001:
				return float(b[0]) if g >= b[1] else float(a[0])
			return lerpf(a[0], b[0], (g - a[1]) / (b[1] - a[1]))
	return 0.0


# ---------------------------------------------------------------- medidas

func _correr() -> void:
	await _calibrar()
	for rg in regiones:
		for pf in perfiles:
			await _region(rg, pf)
	var nombre := "gpu_%s%s" % [Time.get_datetime_string_from_system().replace(":", ""), "_" + etiqueta if etiqueta != "" else ""]
	var f := FileAccess.open(salida.path_join(nombre + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"calibracion": calibra, "filas": filas}, "\t"))
	f.close()
	var txt := FileAccess.open(salida.path_join(nombre + ".txt"), FileAccess.WRITE)
	for fila in filas:
		txt.store_line("%s\t%s\t%s\t%s\tGPU %.2f ms (p90 %.2f)\tllamadas %d\tprimitivas %d\tcapas %.2f" % [fila["region"], fila["perfil"], fila["sitio"],
			fila["variante"], fila["gpu_ms"], fila["gpu_p90"], fila["llamadas"], fila["primitivas"], fila.get("capas", -1.0)])
	txt.close()
	if FileAccess.file_exists("user://medir_gpu_bosque.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://medir_gpu_bosque.save"))
	print("FIN ", salida.path_join(nombre + ".txt"))
	quit()


func _region(rg: String, pf: String) -> void:
	var escena: String = REGIONES[rg]
	Engine.set_meta("calidad_proto", pf)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(escena)
	var limite := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < limite and (current_scene == null or current_scene.scene_file_path != escena or current_scene.get("kael") == null or R.cambiando):
		await process_frame
	var v = current_scene
	await _esperar(90)                        # (las primeras medidas tras cargar salían altas)
	if amplia != 1.0:                         # más píxeles con la misma geometría: pesa más lo que cuesta por fragmento
		root.scaling_3d_scale *= amplia
	print("%s %s: escala del 3D %.2f" % [rg, pf, root.scaling_3d_scale])
	var D = root.get_node_or_null("Dialogic")
	if D != null and D.current_timeline != null:
		D.end_timeline()
	var sitios: Dictionary = SITIOS_GB if rg == "granbosque" else SITIOS_PV
	for s in sitios:
		if not sitios_pedidos.is_empty() and not s in sitios_pedidos:
			continue
		v.set("pasos", -100000)
		var p: Vector3
		if rg == "granbosque":
			p = v._sitio_libre(load("res://zonas3d/gran_bosque/trazado.gd").en_mundo(sitios[s]))
		else:
			p = sitios[s]
		v._colocar_kael(p)
		v.set("destino", null)
		if s.ends_with("_34m"):
			v.distancia = 34.0
		if rg == "granbosque" and s == "mirador":
			v.inclinacion = v.CAMARA_MIRADOR[0]
			v.distancia = v.CAMARA_MIRADOR[1]
		v.perfil_fps = 0
		Engine.max_fps = 0
		await _esperar(60)
		for var_n in variantes:
			if not VARIANTES.has(var_n):
				continue
			if rg == "pastos" and not var_n in ["base", "-sombras", "-personajes", "-hierba", "-particulas"]:
				continue
			var deshacer: Array = _aplicar(v, VARIANTES[var_n])
			await _esperar(12)
			var gpu: Array = []
			var llamadas := 0.0
			var prim := 0.0
			for i in n_muestras:
				await process_frame
				var g := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
				if g > 0.0 and g < 1000.0:
					gpu.append(g)
				llamadas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			gpu.sort()
			var fila := {"region": rg, "perfil": pf, "sitio": s, "variante": var_n,
				"gpu_ms": gpu[gpu.size() / 2] if not gpu.is_empty() else -1.0, "gpu_p90": gpu[int(gpu.size() * 0.9)] if not gpu.is_empty() else -1.0,
				"llamadas": roundi(llamadas / n_muestras), "primitivas": roundi(prim / n_muestras)}
			if var_n == "base":
				if fotos:
					var img := root.get_texture().get_image()
					img.save_png(salida.path_join("%s_%s_%s%s.png" % [rg, pf, s, "_" + etiqueta if etiqueta != "" else ""]))
				var cambios := _poner_conteo(v)
				await _esperar(4)
				var od := root.get_texture().get_image()
				fila["capas"] = _capas_medias(od)
				if fotos:
					od.save_png(salida.path_join("%s_%s_%s%s_capas.png" % [rg, pf, s, "_" + etiqueta if etiqueta != "" else ""]))
				_deshacer(cambios)
				RenderingServer.set_default_clear_color(_fondo)
				root.use_hdr_2d = false
				await _esperar(3)
			_deshacer(deshacer)
			filas.append(fila)
			print("%s %s %s %s: GPU %.2f ms (p90 %.2f) · llamadas %d · primitivas %d%s" % [rg, pf, s, var_n, fila["gpu_ms"], fila["gpu_p90"],
				fila["llamadas"], fila["primitivas"], " · capas %.2f" % fila["capas"] if fila.has("capas") else ""])


# ---------------------------------------------------------------- capas (fragmentos por píxel) de verdad
# DEBUG_DRAW_OVERDRAW cambia también el sombreado de vértices: no ve el hueco de las copas hecho en el vértice ni el
# viento. Aquí cada pieza se dibuja con una copia de su sombreado que conserva el vértice y en el píxel solo suma
# PASO (sin profundidad, sin luz, sin bruma ni mapeo de tonos): el resultado son los fragmentos que la GPU rasteriza
# por píxel (con las matas recortadas por alfa contadas enteras: en el Mali se sombrean igual antes de descartarse).
const PASO := 0.1                         # (más pequeño no sale: 0,025 por capa da 0; se calibra)
var _conteo_de := {}                      # Shader original → Shader de conteo
var _conteo_simple := {}                  # cara → ShaderMaterial


func _cara_de(codigo: String) -> String:
	if codigo.contains("cull_disabled"):
		return "cull_disabled"
	if codigo.contains("cull_front"):
		return "cull_front"
	return "cull_back"


func _modo_conteo(cara: String) -> String:
	return "render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, fog_disabled, %s;" % cara


func _mat_conteo_simple(cara: String) -> ShaderMaterial:
	if not _conteo_simple.has(cara):
		var s := Shader.new()
		s.code = "shader_type spatial;\n%s\nvoid fragment() {\n\tALBEDO = vec3(%f);\n}\n" % [_modo_conteo(cara), PASO]
		var m := ShaderMaterial.new()
		m.shader = s
		_conteo_simple[cara] = m
	return _conteo_simple[cara]


func _mat_conteo(g: GeometryInstance3D) -> Material:
	var mo := g.material_override
	if mo is ShaderMaterial and (mo as ShaderMaterial).shader != null:
		var sm := mo as ShaderMaterial
		var cod: String = sm.shader.code
		var i := cod.find("void fragment()")
		if cod.contains("void vertex()") and i > 0:
			if not _conteo_de.has(sm.shader):
				var nuevo := cod.substr(0, i) + "void fragment() {\n\tALBEDO = vec3(%f);\n}\n" % PASO
				var rm := nuevo.find("render_mode")
				if rm >= 0:
					nuevo = nuevo.substr(0, rm) + _modo_conteo(_cara_de(cod)) + nuevo.substr(nuevo.find(";", rm) + 1)
				else:
					nuevo = nuevo.replace("shader_type spatial;", "shader_type spatial;\n" + _modo_conteo("cull_back"))
				var s := Shader.new()
				s.code = nuevo
				_conteo_de[sm.shader] = s
			var copia := ShaderMaterial.new()
			copia.shader = _conteo_de[sm.shader]
			for u in sm.shader.get_shader_uniform_list():
				copia.set_shader_parameter(u["name"], sm.get_shader_parameter(u["name"]))
			return copia
		return _mat_conteo_simple(_cara_de(cod))
	if mo is BaseMaterial3D:
		return _mat_conteo_simple("cull_disabled" if (mo as BaseMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED else "cull_back")
	if g is CPUParticles3D or g is GPUParticles3D:
		return _mat_conteo_simple("cull_disabled")
	return _mat_conteo_simple("cull_back")


func _poner_conteo(v: Node) -> Array:
	var hecho: Array = []
	for g in v.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		hecho.append([gi, "material_override", gi.material_override])
		gi.material_override = _mat_conteo(gi)
	for we in v.find_children("*", "WorldEnvironment", true, false):
		hecho.append([we, "environment", we.environment])
		we.environment = null
	for c in root.find_children("*", "CanvasLayer", true, false):
		if c.visible:
			hecho.append([c, "visible", true])
			c.visible = false
	RenderingServer.set_default_clear_color(Color.BLACK)
	root.use_hdr_2d = true
	return hecho


# Capas medias por píxel en la parte del 3D (sin las franjas negras del 20:9 ni la interfaz de arriba).
func _capas_medias(img: Image) -> float:
	var tam := img.get_size()
	var x0 := int(tam.x * 0.12)
	var x1 := int(tam.x * 0.88)
	var y0 := int(tam.y * 0.1)
	var suma := 0.0
	var n := 0
	for y in range(y0, tam.y, 4):
		for x in range(x0, x1, 4):
			suma += _capas_de(img.get_pixel(x, y).r)
			n += 1
	return suma / maxf(n, 1)


func _categoria(n: Node, esc) -> String:
	var nombre := String(n.name).trim_prefix("@").get_slice("@", 0)
	if n is GPUParticles3D or n is CPUParticles3D:
		return "particulas"
	if not n is GeometryInstance3D:
		return ""
	# los nombres repetidos se vuelven «@MultiMeshInstance3D@n»: se mira el material
	var mo: Material = (n as GeometryInstance3D).material_override
	if esc != null and esc.get("_mat_hojas") != null and mo != null:
		if mo in esc._mat_hojas.values():
			return "copas_hojas"
		if mo in esc._mat_copa_maciza.values():
			return "copas_macizas"
		if mo == esc._mat_tronco or mo == esc._mat_macizo:
			return "troncos"
		if mo == esc._mat_macizo_fino or mo == esc._mat_flor_cache:
			return "sotobosque"
		if mo is ShaderMaterial and (mo as ShaderMaterial).shader != null:
			var cod: String = (mo as ShaderMaterial).shader.code
			if cod.contains("uniform vec3 abajo"):
				return "hierba"
			if cod.contains("ondula"):
				return "haces"
	if nombre.begins_with("MM_hojas_"):
		return "copas_hojas"
	if nombre.begins_with("MM_maciza_"):
		return "copas_macizas"
	if nombre.begins_with("MM_tronco") or nombre.begins_with("MM_pino"):
		return "troncos"
	if nombre in ["MM_helecho", "MM_mata", "MM_seta", "MM_flor"]:
		return "sotobosque"
	if nombre == "MM_hierba":
		return "hierba"
	if nombre == "Haz":
		return "haces"
	if nombre == "Agua":
		return "agua"
	if nombre == "Suelo":
		return "suelo"
	var p := n.get_parent()
	if p != null and String(p.name).begins_with("ArbolViejo"):
		var gi := n as GeometryInstance3D
		if gi.material_override is ShaderMaterial and String((gi.material_override as ShaderMaterial).shader.code).contains("ALPHA_SCISSOR"):
			return "copas_hojas"
		return "troncos"
	return ""


func _aplicar(v, cats: Array) -> Array:
	var hecho: Array = []
	for c in cats:
		if c.begins_with("cod:"):
			var par: PackedStringArray = c.substr(4).split("=>")
			var esc = v.get("escenario")
			var shaders := {}
			for m in esc.mats_hueco + esc._mat_hojas.values():
				shaders[(m as ShaderMaterial).shader] = true
			for s in shaders:
				var sh := s as Shader
				if sh.code.contains(par[0]):
					hecho.append([sh, "code", sh.code])
					sh.code = sh.code.replace(par[0], par[1])
		elif c == "sombras":
			for s in v.find_children("*", "DirectionalLight3D", true, false):
				hecho.append([s, "shadow_enabled", s.shadow_enabled])
				s.shadow_enabled = false
		elif c == "hueco":
			var esc = v.get("escenario")
			if esc != null:
				var mats: Array = esc.mats_hueco
				hecho.append([esc, "mats_hueco", mats])
				for m in mats:
					m.set_shader_parameter("hueco_r", 0.0)
				esc.mats_hueco = []
		elif c == "relieve_suelo":
			for n in v.find_children("Suelo", "MeshInstance3D", true, false):
				var ms := (n as MeshInstance3D).material_override as BaseMaterial3D
				if ms != null:
					hecho.append([ms, "normal_enabled", ms.normal_enabled])
					ms.normal_enabled = false
		elif c == "sombra_troncos":
			var esc = v.get("escenario")
			for n in v.find_children("*", "GeometryInstance3D", true, false):
				if _categoria(n, esc) == "troncos" and (n as GeometryInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
					hecho.append([n, "cast_shadow", GeometryInstance3D.SHADOW_CASTING_SETTING_ON])
					n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif c == "personajes":
			for nombre in ["kael", "grupo"]:
				var k = v.get(nombre)
				if k != null and k is Node3D:
					hecho.append([k, "visible", k.visible])
					k.visible = false
		else:
			var esc = v.get("escenario")
			for n in v.find_children("*", "Node3D", true, false):
				if _categoria(n, esc) == c and n.visible:
					hecho.append([n, "visible", true])
					n.visible = false
	if depurar:
		print("  ", cats, ": ", hecho.size(), " cambios ", hecho.slice(0, 4).map(func(h): return str(h[0].name) if h[0] is Node else str(h[0])))
	return hecho


func _deshacer(hecho: Array) -> void:
	for h in hecho:
		if is_instance_valid(h[0]) or h[0] is RefCounted:
			h[0].set(h[1], h[2])
