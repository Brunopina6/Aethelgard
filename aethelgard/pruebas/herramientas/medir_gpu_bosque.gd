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
#         [fotos] [n=60] [etiqueta=antes] [recuento]
# «recuento» (rend2, 12/11): además, en cada sitio y solo con la variante base, el recuento por categoría y por tipo de
# material (opaco, recortado = su sombreado tiene discard o alpha scissor, mezcla = transparente): piezas y vértices
# dentro de la cámara, capas (fragmentos por píxel) y parte de la pantalla que cubren, materiales y sombreados
# distintos, y las llamadas y primitivas sin la sombra del sol. Son las métricas que anticipan el coste en el Mali
# (tile-based, sin prepase: lo recortado no usa su eliminación de píxeles ocultos y los vértices pesan en el tiler).
# Las cifras del PC no son las del Redmi; sirven para comparar (antes/después, Gran Bosque/Pastos) en el mismo PC.
# Para parecerse al Mali-G57 (Godot no hace prepase de profundidad con Mali, Adreno, PowerVR ni Apple), lánzalo con un
# override.cfg temporal con rendering/driver/depth_prepass/enable=false (ver el informe).

const REGIONES := {"granbosque": "res://zonas3d/gran_bosque_3d.tscn", "pastos": "res://zonas3d/pastos_verdes_3d.tscn",
	"oakhaven": "res://zonas3d/oakhaven_3d.tscn", "garganta": "res://zonas3d/garganta_3d.tscn",
	"marcristal": "res://zonas3d/mar_cristal_3d.tscn"}
# Las demás regiones (rend2, segunda pasada): la llegada (donde deja a Kael la región) y sitios absolutos (los de
# medir_escenas.gd) o relativos a la llegada («+»).
const SITIOS_OTRAS := {
	"oakhaven": {"llegada": null, "+norte_12m": Vector3(0, 0, -12), "+este_12m": Vector3(12, 0, 0)},
	"garganta": {"llegada": null, "ruta_a": Vector3(-12, 0, 22), "ruta_b": Vector3(-12, 0, 10)},
	"marcristal": {"llegada": null, "campamento": Vector3(45, 0, 96), "campamento_b": Vector3(39, 0, 95)},
}
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
	# rend2, segunda pasada: el orden de dibujo del Gran Bosque probado en cualquier región, sin tocar su código: lo
	# recortado (discard o alfa recortado) después de lo opaco y lo más grande de lo opaco (el suelo) al final
	"~orden_generico": ["orden_generico"],
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
var recuento := false
var parpadeo := false                    # parpadeo: 8 fotogramas parados con la cámara corriéndose 3 cm, sin y con mipmaps
var igualdad := false                    # igualdad: capturas con el tiempo parado, con y sin el orden de dibujo (rend2)
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
		elif a == "recuento":
			recuento = true
		elif a == "igualdad":
			igualdad = true
		elif a == "parpadeo":
			parpadeo = true
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
	var sitios: Dictionary = SITIOS_GB if rg == "granbosque" else (SITIOS_PV if rg == "pastos" else SITIOS_OTRAS[rg])
	var llegada: Vector3 = v.kael.global_position
	for s in sitios:
		if not sitios_pedidos.is_empty() and not s in sitios_pedidos:
			continue
		v.set("pasos", -100000)
		var p: Vector3
		if rg == "granbosque":
			p = v._sitio_libre(load("res://zonas3d/gran_bosque/trazado.gd").en_mundo(sitios[s]))
		elif rg == "pastos":
			p = sitios[s]
		elif sitios[s] == null:
			p = llegada
		else:
			p = (llegada + sitios[s]) if s.begins_with("+") else sitios[s]
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
		if igualdad:
			await _capturas_igualdad(v, rg, pf, s)
		if parpadeo:
			await _capturas_parpadeo(v, rg, pf, s)
		for var_n in variantes:
			if not VARIANTES.has(var_n):
				continue
			if rg != "granbosque" and not var_n in ["base", "-sombras", "-personajes", "-hierba", "-particulas", "~orden_generico"]:
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
				var piezas: Array = _clasificar(v, rg) if recuento else []
				var cambios := _poner_conteo(v)
				await _esperar(4)
				var od := root.get_texture().get_image()
				fila["capas"] = _capas_medias(od)
				if fotos:
					od.save_png(salida.path_join("%s_%s_%s%s_capas.png" % [rg, pf, s, "_" + etiqueta if etiqueta != "" else ""]))
				if recuento:
					fila["recuento"] = await _recuento(piezas)
				_deshacer(cambios)
				if recuento:
					fila["sin_sombra_sol"] = await _sin_sombra_sol(v)
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
		elif c == "orden_generico":
			hecho.append_array(_orden_generico(v))
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


# ---------------------------------------------------------------- recuento por categoría y por tipo de material (rend2)

# El material con el que se dibuja una pieza (el de encima, el de la malla o el de las partículas).
func _materiales_de(gi: GeometryInstance3D) -> Array:
	if gi.material_override != null:
		return [gi.material_override]
	var r: Array = []
	var malla: Mesh = null
	if gi is MeshInstance3D:
		malla = (gi as MeshInstance3D).mesh
		for k in (gi as MeshInstance3D).get_surface_override_material_count():
			var m := (gi as MeshInstance3D).get_surface_override_material(k)
			if m != null:
				r.append(m)
	elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null:
		malla = (gi as MultiMeshInstance3D).multimesh.mesh
	elif gi is CPUParticles3D:
		malla = (gi as CPUParticles3D).mesh
	if r.is_empty() and malla != null:
		for k in malla.get_surface_count():
			if malla.surface_get_material(k) != null:
				r.append(malla.surface_get_material(k))
	return r


# «recortado»: su sombreado tiene discard o alpha scissor/hash (en el Mali no aprovecha la eliminación de píxeles
# ocultos y obliga a sombrear antes de saber si se ve); «mezcla»: transparente; «opaco»: lo demás.
func _tipo_material(gi: GeometryInstance3D) -> String:
	if gi is Label3D:
		return "mezcla"
	var peor := "opaco"
	for m in _materiales_de(gi):
		var t := "opaco"
		if m is ShaderMaterial and (m as ShaderMaterial).shader != null:
			var cod: String = (m as ShaderMaterial).shader.code
			if cod.contains("discard") or cod.contains("ALPHA_SCISSOR") or cod.contains("ALPHA_HASH"):
				t = "recortado"
			elif cod.contains("blend_add") or cod.contains("blend_mix") and cod.contains("ALPHA") or cod.contains("ALPHA =") or cod.contains("depth_draw_never"):
				t = "mezcla"
		elif m is BaseMaterial3D:
			var b := m as BaseMaterial3D
			if b.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH]:
				t = "recortado"
			elif b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or b.blend_mode != BaseMaterial3D.BLEND_MODE_MIX:
				t = "mezcla"
		if t == "recortado" or (t == "mezcla" and peor == "opaco"):
			peor = t
	return peor


func _vertices_malla(m: Mesh) -> int:
	if m == null:
		return 0
	if _verts_cache.has(m):
		return _verts_cache[m]
	var n := 0
	for k in m.get_surface_count():                 # (los índices, o los vértices si no tiene: lo que se procesa)
		var s: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), k)
		var idx: int = int(s.get("index_count", 0))
		n += idx if idx > 0 else int(s.get("vertex_count", 0))
	_verts_cache[m] = n
	return n


var _verts_cache := {}


func _vertices(gi: GeometryInstance3D) -> int:
	if gi is MeshInstance3D:
		return _vertices_malla((gi as MeshInstance3D).mesh)
	if gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null:
		var mm := (gi as MultiMeshInstance3D).multimesh
		var c: int = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		return c * _vertices_malla(mm.mesh)
	if gi is CPUParticles3D:
		return (gi as CPUParticles3D).amount * _vertices_malla((gi as CPUParticles3D).mesh)
	return 0


func _dentro(gi: GeometryInstance3D, cam: Camera3D, planos: Array) -> bool:
	if not gi.is_visible_in_tree():
		return false
	var caja: AABB = gi.global_transform * gi.get_aabb()
	if gi.visibility_range_end > 0.0 and cam.global_position.distance_to(caja.get_center()) > gi.visibility_range_end:
		return false
	for pl in planos:
		var fuera := true
		for i in 8:
			if (pl as Plane).distance_to(caja.get_endpoint(i)) <= 0.0:
				fuera = false
				break
		if fuera:
			return false
	return true


# [pieza, categoría, tipo de material, vértices, dentro de la cámara, da sombra, materiales]
func _clasificar(v: Node, rg: String) -> Array:
	var cam := root.get_camera_3d()
	var planos: Array = cam.get_frustum()
	var esc = v.get("escenario")
	var pjs: Array = []
	for nombre in ["kael", "grupo"]:
		var k = v.get(nombre)
		if k != null and k is Node:
			pjs.append(k)
	var r: Array = []
	for g in v.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var cat := ""
		for p in pjs:
			if p == gi or (p as Node).is_ancestor_of(gi):
				cat = "personajes"
		if cat == "" and rg == "granbosque":
			cat = _categoria(gi, esc)
		if cat == "":
			if gi is CPUParticles3D or gi is GPUParticles3D:
				cat = "particulas"
			elif gi is MultiMeshInstance3D:
				cat = "multimesh_" + String(gi.name).trim_prefix("@").get_slice("@", 0).to_lower()
			else:
				cat = "resto"
		var dentro := _dentro(gi, cam, planos)
		r.append([gi, cat, _tipo_material(gi), _vertices(gi), dentro,
			gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, _materiales_de(gi),
			_vertices_utiles(gi, planos) if dentro else 0])
	return r


# Vértices de los ejemplares de un MultiMesh que caen de verdad en la cámara (su origen con un margen de 4 m): el resto
# se envía igual (el trozo entero pasa el recorte) y en el Mali paga el sombreado de posición.
func _vertices_utiles(gi: GeometryInstance3D, planos: Array) -> int:
	if not gi is MultiMeshInstance3D or (gi as MultiMeshInstance3D).multimesh == null:
		return _vertices(gi)
	var mm := (gi as MultiMeshInstance3D).multimesh
	var por := _vertices_malla(mm.mesh)
	var n := 0
	for k in mm.instance_count:
		var o: Vector3 = gi.global_transform * (mm.get_instance_transform(k) * Vector3(0, 2.5, 0))
		var fuera := false
		for pl in planos:
			if (pl as Plane).distance_to(o) > 4.0:
				fuera = true
				break
		if not fuera:
			n += por
	return n


func _capas_y_cobertura(img: Image) -> Array:
	var tam := img.get_size()
	var suma := 0.0
	var cubre := 0
	var n := 0
	for y in range(int(tam.y * 0.1), tam.y, 4):
		for x in range(int(tam.x * 0.12), int(tam.x * 0.88), 4):
			var c := _capas_de(img.get_pixel(x, y).r)
			suma += c
			if c > 0.5:
				cubre += 1
			n += 1
	return [suma / maxf(n, 1), float(cubre) / maxf(n, 1)]


# Con los materiales de conteo puestos: para cada categoría y cada tipo de material, solo esas piezas a la vista.
func _recuento(piezas: Array) -> Dictionary:
	var grupos := {}
	for p in piezas:
		for clave in ["cat:" + p[1], "tipo:" + p[2]]:
			if not grupos.has(clave):
				grupos[clave] = {"piezas": 0, "dentro": 0, "vertices_dentro": 0, "vertices_utiles": 0, "vertices_sombra_dentro": 0,
					"materiales": {}, "sombreados": {}}
			var g: Dictionary = grupos[clave]
			g["piezas"] += 1
			if p[4]:
				g["dentro"] += 1
				g["vertices_dentro"] += p[3]
				g["vertices_utiles"] += p[7]
				if p[5]:
					g["vertices_sombra_dentro"] += p[3]
				for m in p[6]:
					g["materiales"][m] = true
					if m is ShaderMaterial:
						g["sombreados"][(m as ShaderMaterial).shader] = true
	var mats_total := {}
	var sh_total := {}
	for p in piezas:
		if p[4]:
			for m in p[6]:
				mats_total[m] = true
				if m is ShaderMaterial:
					sh_total[(m as ShaderMaterial).shader] = true
	for clave in grupos:
		var cat_o_tipo: String = String(clave).get_slice(":", 1)
		var es_cat: bool = String(clave).begins_with("cat:")
		var ocultas: Array = []
		for p in piezas:
			var gi: GeometryInstance3D = p[0]
			if (p[1] if es_cat else p[2]) != cat_o_tipo and gi.visible:
				ocultas.append(gi)
				gi.visible = false
		await _esperar(3)
		var cc := _capas_y_cobertura(root.get_texture().get_image())
		for gi in ocultas:
			gi.visible = true
		var g: Dictionary = grupos[clave]
		g["capas"] = snappedf(cc[0], 0.01)
		g["cobertura"] = snappedf(cc[1], 0.001)
		g["materiales"] = g["materiales"].size()
		g["sombreados"] = g["sombreados"].size()
	await _esperar(2)
	return {"grupos": grupos, "materiales_a_la_vista": mats_total.size(), "sombreados_propios_a_la_vista": sh_total.size()}


func _sin_sombra_sol(v: Node) -> Dictionary:
	var luces: Array = []
	for s in v.find_children("*", "DirectionalLight3D", true, false):
		if s.shadow_enabled:
			luces.append(s)
			s.shadow_enabled = false
	await _esperar(8)
	var ll := 0.0
	var pr := 0.0
	for i in 10:
		await process_frame
		ll += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		pr += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	for s in luces:
		s.shadow_enabled = true
	await _esperar(4)
	return {"llamadas": roundi(ll / 10.0), "primitivas": roundi(pr / 10.0), "luces_con_sombra": luces.size()}


# ---------------------------------------------------------------- ¿se ve igual? (rend2)
# Con el juego parado (time_scale 0: personajes, partículas y tweens quietos; el viento de los sombreados avanza un
# fotograma), tres capturas seguidas: «a» y «b» con el orden de dibujo del escenario (el ruido de un fotograma a otro)
# y «c» con todo render_priority a 0 (el orden de antes). Si c difiere de a como b, el orden no cambia la imagen.
func _capturas_igualdad(v: Node, rg: String, pf: String, s: String) -> void:
	Engine.time_scale = 0.0
	await _esperar(4)
	var base := salida.path_join("igualdad_%s_%s_%s" % [rg, pf, s])
	root.get_texture().get_image().save_png(base + "_a.png")
	await _esperar(1)
	root.get_texture().get_image().save_png(base + "_b.png")
	var hecho: Array = []
	for g in v.find_children("*", "GeometryInstance3D", true, false):
		for m in _materiales_de(g as GeometryInstance3D):
			if m is Material and (m as Material).render_priority != 0:
				hecho.append([m, "render_priority", (m as Material).render_priority])
				(m as Material).render_priority = 0
	await _esperar(1)
	root.get_texture().get_image().save_png(base + "_c.png")
	_deshacer(hecho)
	print("igualdad %s %s %s: %d materiales con orden" % [rg, pf, s, hecho.size()])
	var esc = v.get("escenario")                 # «d»: las copas de hojas con los cuadros enteros (sin recortar)
	if esc != null and esc.has_method("alternar_casco"):
		var n: int = esc.alternar_casco(false)
		await _esperar(1)
		root.get_texture().get_image().save_png(base + "_d.png")
		esc.alternar_casco(true)
		print("igualdad %s %s %s: %d copas con los cuadros enteros" % [rg, pf, s, n])
	if v.get("escenario") == null or not v.get("escenario").has_method("alternar_mipmaps"):   # «f»: el orden genérico
		var hecho_f := _orden_generico(v)
		await _esperar(1)
		root.get_texture().get_image().save_png(base + "_f.png")
		_deshacer(hecho_f)
		await _esperar(1)
	if esc != null and esc.has_method("alternar_mipmaps"):   # «e»: el atlas de matas al revés que en el perfil (gb_hojas_mipmaps)
		var con_mip: bool = bool(esc.perfil.get("gb_hojas_mipmaps", false))
		esc.alternar_mipmaps(not con_mip)
		await _esperar(1)
		root.get_texture().get_image().save_png(base + "_e.png")
		esc.alternar_mipmaps(con_mip)
	Engine.time_scale = 1.0
	await _esperar(3)


# Parpadeo (rend2, segunda pasada): con el juego parado, la cámara se corre 3 cm por fotograma (8 fotogramas), sin y con
# los mipmaps del atlas de matas. Lo que cambia de un fotograma al siguiente en las hojas lejanas es el centelleo.
func _capturas_parpadeo(v: Node, rg: String, pf: String, s: String) -> void:
	var esc = v.get("escenario")
	if esc == null or not esc.has_method("alternar_mipmaps"):
		return
	Engine.time_scale = 0.0
	await _esperar(3)
	var foco0: Vector3 = v.foco
	for con in [false, true]:
		esc.alternar_mipmaps(con)
		v.foco = foco0
		for k in 8:
			v.foco = foco0 + Vector3(0.03 * k, 0, 0)
			await _esperar(2)
			root.get_texture().get_image().save_png(salida.path_join("parpadeo_%s_%s_%s_%s_%d.png" % [rg, pf, s, "mip" if con else "sin", k]))
	esc.alternar_mipmaps(bool(esc.perfil.get("gb_hojas_mipmaps", false)))
	v.foco = foco0
	Engine.time_scale = 1.0
	await _esperar(3)


# render_priority por tipo de material, en tiempo de ejecución (deshacible): recortado 1; la pieza opaca con la caja más
# grande en planta (el suelo o el terreno) y el agua, 2. Devuelve lo cambiado para deshacerlo.
func _orden_generico(v: Node) -> Array:
	var hecho: Array = []
	var mayor: GeometryInstance3D = null
	var area := 0.0
	var vistos := {}
	for g in v.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var t := _tipo_material(gi)
		var caja: AABB = gi.global_transform * gi.get_aabb()
		if t == "opaco" and caja.size.x * caja.size.z > area and not gi is MultiMeshInstance3D:
			area = caja.size.x * caja.size.z
			mayor = gi
		if t == "recortado":
			for m in _materiales_de(gi):
				if m is Material and not vistos.has(m) and (m as Material).render_priority == 0:
					vistos[m] = true
					hecho.append([m, "render_priority", 0])
					(m as Material).render_priority = 1
	if mayor != null:
		for m in _materiales_de(mayor):
			if m is Material and not vistos.has(m) and (m as Material).render_priority == 0:
				hecho.append([m, "render_priority", 0])
				(m as Material).render_priority = 2
		print("  orden genérico: suelo = ", mayor.name, " · ", hecho.size(), " materiales")
	return hecho
