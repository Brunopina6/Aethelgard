extends "res://pruebas/prueba_erebo_orbe_v12.gd"
# Rendimiento (14/11): qué cuesta dibujar la invocación de Érebo plano a plano, SOLO con cifras deterministas (nada de
# ms ni FPS: los tiempos se miden en el Redmi). Con ventana, en un combate de verdad (datos aislados del ejecutor) y con
# «movil» como en el teléfono (teatro al 70 %, Érebo con la mitad de partículas, sin sombras).
# Argumentos tras «--»: salida=<carpeta> etiqueta=<antes|despues> [erebo_nueva|erebo_actual] [movil] erebo=exito
# Cada 0,5 s de juego (el ejecutor fija 30 fotogramas por segundo de juego):
#   - llamadas de dibujo, primitivas y objetos del fotograma: en total y de cada ventana 3D que se ha dibujado (el teatro
#     de la invocación, los personajes del combate que quedan debajo, efectos...), con sus píxeles;
#   - captura del teatro (color) y su SOBREDIBUJADO (Viewport.DEBUG_DRAW_OVERDRAW: cada capa de fragmentos suma ~20 al
#     rojo) en tres pasadas: todo, sin los efectos (partículas, sprites, charco, orbe, sombra) y sin efectos ni el cuerpo
#     de Érebo. Las capas medias por píxel y el % de píxeles con 4 capas o más salen de esas imágenes.
# Las partículas llevan semilla fija (use_fixed_seed) para que las capturas de antes y después sean comparables.
# Escribe <salida>/planos_<etiqueta>.json, planos_<etiqueta>.txt y las capturas.

const CAPA_EFECTOS := 1 << 17         # (la 20, 1 << 19, es la del precalentado de erebo_3d.gd)
const CAPA_EREBO := 1 << 16
const ROJO_POR_CAPA := 20.4          # calibrado: 1, 2 y 3 capas = 20, 41 y 61 en el rojo (sonda de 14/11)

var _salida := ""
var _etiqueta := "medida"
var _muestras: Array = []
var _semilla := 1
var _compilados: Array = []
var _sin_capturas := false
var _t := 0.0
var _conectado := false
var _eventos: Array = []
var _fotograma := 0


# Archivos de la caché de sombreadores de Godot (como medir_cargas.gd): cada archivo nuevo, un programa compilado por
# primera vez. En el PC cuesta poco; en el Mali-G57, un tirón (la caché del ejecutor empieza vacía en cada pasada).
func _cache(dir := "user://shader_cache") -> int:
	var d := DirAccess.open(dir)
	if d == null:
		return 0
	var n := d.get_files().size()
	for s in d.get_directories():
		n += _cache(dir.path_join(s))
	return n


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			_salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			_etiqueta = a.substr(9)
		elif a == "sin_capturas":                      # solo los sombreadores compilados (sin pasadas de sobredibujado)
			_sin_capturas = true
	node_added.connect(_al_nacer)
	super._initialize()


func _al_nacer(n: Node) -> void:
	if n is CPUParticles3D and "use_fixed_seed" in n:
		n.use_fixed_seed = true
		n.seed = _semilla
		_semilla += 1


func _probar() -> void:
	await _esperar(10)
	if _salida == "":
		_ok(false, "falta salida=<carpeta>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_salida)
	EO.elegir(false)                                 # el orbe experimental, apagado (en el Redmi daba lo mismo)
	var rec = root.get_node_or_null("Recursos")
	if rec != null and rec.get("lbl_fps") != null:
		rec.lbl_fps.visible = false                  # el contador de FPS cambia entre pasadas y ensucia la comparación
	var grim: Dictionary = await _combate()
	_ok(c.actor is Dictionary and c.actor["nombre"] == "Lya", "no llega el turno de Lya")
	c.armonia = 1.0
	await _esperar(5)
	var base := _info_total()
	base["ventanas"] = _ventanas(null)
	print("COMBATE (antes de invocar): ", JSON.stringify(base))
	c._invocar_sobre(grim)
	var vp: SubViewport = null
	for i in 600:
		if c.inv_erebo != null:
			vp = c.inv_erebo.get_viewport()
			break
		await process_frame
	_ok(vp != null, "no aparece el teatro")
	if vp == null:
		quit(1)
		return
	var siguiente := 0.0
	var n := 0
	var cache0 := _cache()
	var cache_ant := cache0
	while c.inv_erebo != null and _t < 30.0:
		await process_frame
		_t += Engine.time_scale / 30.0
		var t := _t
		if not _conectado and c.inv_erebo != null and c.inv_erebo.erebo != null:
			_conectado = true
			c.inv_erebo.erebo.evento.connect(func(nom: String): _eventos.append([snappedf(_t, 0.01), nom]))
			c.inv_erebo.evento.connect(func(nom: String): _eventos.append([snappedf(_t, 0.01), "inv:" + nom]))
		if _sin_capturas and _fotograma < 12 and "fotos_inicio" in OS.get_cmdline_user_args():
			_fotograma += 1                            # el teatro al empezar (el precalentado no debe verse)
			vp.get_texture().get_image().save_png(_salida.path_join("inicio_%s_%02d.png" % [_etiqueta, _fotograma]))
		var ca := _cache()
		if ca != cache_ant:                           # programas compilados por primera vez en este fotograma
			_compilados.append([snappedf(t, 0.01), ca - cache_ant])
			cache_ant = ca
		if t >= siguiente and not _sin_capturas:
			siguiente += 0.5
			n += 1
			await _muestra(vp, t, n)
			cache_ant = _cache()                       # (las pasadas de sobredibujado compilan lo suyo: no cuentan)
	var txt := "Invocación de Érebo, medida determinista (%s; %s; %s)\n" % [_etiqueta, RenderingServer.get_video_adapter_name(),
		"nueva" if load("res://invocacion_erebo_nueva.gd").elegida() else "la de siempre"]
	txt += "COMBATE antes de invocar: %s\n" % JSON.stringify(base)
	txt += "Sombreadores compilados por primera vez durante la invocación (archivos nuevos en user://shader_cache): %d; [t, nuevos]: %s\n" % [
		cache_ant - cache0, JSON.stringify(_compilados)]
	txt += "Eventos [t, nombre]: %s\n" % JSON.stringify(_eventos)
	txt += "  t     llam  prim    obj | teatro llam prim | debajo llam prim px | capas todo/sin_ef/sin_ef_ni_erebo | >=4 capas %% | partic sprites\n"
	for m in _muestras:
		txt += "%5.2f %5d %6d %5d | %5d %6d | %4d %6d %7d | %4.2f %4.2f %4.2f | %5.1f %5.1f %5.1f | %3d %2d  %s\n" % [m.t, m.llamadas, m.primitivas,
			m.objetos, m.teatro.llamadas, m.teatro.primitivas, m.debajo.llamadas, m.debajo.primitivas, m.debajo.px,
			m.capas.todo, m.capas.sin_efectos, m.capas.sin_efectos_ni_erebo, m.cuatro.todo, m.cuatro.sin_efectos,
			m.cuatro.sin_efectos_ni_erebo, m.particulas, m.sprites, m.foto]
	var f := FileAccess.open(_salida.path_join("planos_%s.txt" % _etiqueta), FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	f = FileAccess.open(_salida.path_join("planos_%s.json" % _etiqueta), FileAccess.WRITE)
	f.store_string(JSON.stringify({"combate": base, "compilados": _compilados, "muestras": _muestras}, " "))
	f.close()
	print(txt)
	# la salida: la ventana entera cada 3 fotogramas mientras el teatro se funde y vuelve el combate (lo de debajo)
	# (el balanceo de los cuerpos y el brillo del ATB van con el reloj real, Time.get_ticks_msec: esos píxeles cambian de
	# una pasada a otra; el estado del combate, no)
	var estados := []
	for i in 45:
		await RenderingServer.frame_post_draw
		if i % 3 == 0 and not _sin_capturas:
			root.get_texture().get_image().save_png(_salida.path_join("salida_%s_%02d.png" % [_etiqueta, i]))
		if c != null:
			var e := [i, c.estado]
			for h in c.heroes + c.enemigos:
				e.append([h["nombre"], snappedf(h["atb"], 0.001), h["hp"]])
			for g in c.menu.grupo:
				e.append(g["brillo"].visible)
			estados.append(e)
	f = FileAccess.open(_salida.path_join("salida_estado_%s.json" % _etiqueta), FileAccess.WRITE)
	f.store_string(JSON.stringify(estados))
	f.close()
	for i in 1500:
		if c == null or c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
		await process_frame
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _info_total() -> Dictionary:
	return {"llamadas": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitivas": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"objetos": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)}


func _info_vp(v: Viewport) -> Dictionary:
	var rid := v.get_viewport_rid()
	var V := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	return {"llamadas": RenderingServer.viewport_get_render_info(rid, V, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"primitivas": RenderingServer.viewport_get_render_info(rid, V, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
		"objetos": RenderingServer.viewport_get_render_info(rid, V, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME)}


# Las ventanas 3D del árbol (menos «excepto») que se han dibujado en este fotograma: nombre del dueño, tamaño y cifras.
func _ventanas(excepto: Viewport) -> Array:
	var r := []
	for v in root.find_children("*", "SubViewport", true, false):
		if v == excepto or v.render_target_update_mode == SubViewport.UPDATE_DISABLED:
			continue
		var i := _info_vp(v)
		if i.llamadas > 0:
			i["tam"] = [v.size.x, v.size.y]
			i["modo"] = v.render_target_update_mode
			i["dentro_de"] = str(v.get_parent().name)
			r.append(i)
	return r


# Efectos y cuerpo de Érebo a sus capas (una vez por muestra; el juego no toca «layers»).
func _clasificar(vp: SubViewport) -> Dictionary:
	var cuenta := {"particulas": 0, "sprites": 0}
	var er = c.inv_erebo.erebo if c.inv_erebo != null else null
	for g in vp.find_children("*", "GeometryInstance3D", true, false):
		var efecto: bool = g is CPUParticles3D or g is SpriteBase3D or (er != null and (g == er.charco or g == er.orbe))
		var s = c.inv_erebo.sombra if c.inv_erebo != null else null
		if s != null and s.is_ancestor_of(g):
			efecto = true
		if efecto:
			g.layers = CAPA_EFECTOS
			if g.is_visible_in_tree():
				if g is CPUParticles3D:
					cuenta.particulas += g.amount
				elif g is SpriteBase3D:
					cuenta.sprites += 1
				var dueno := str(g.get_parent().get_script().resource_path.get_file()) if g.get_parent().get_script() != null else str(g.get_parent().name)
				cuenta.get_or_add("visibles", []).append("%s/%s%s" % [dueno, g.get_class(), (" px=%.4f" % g.pixel_size) if g is SpriteBase3D else ""])
		elif er != null and er.is_ancestor_of(g):
			g.layers = CAPA_EREBO
	return cuenta


func _capas(img: Image) -> Array:
	var d := img.get_data()                           # RGBA8 o RGB8
	var paso := 4 if img.get_format() == Image.FORMAT_RGBA8 else 3
	var suma := 0
	var cuatro := 0
	var total := 0
	for i in range(0, d.size(), paso * 2):            # un píxel de cada dos basta para la media
		var r := d[i]
		suma += r
		if r >= int(ROJO_POR_CAPA * 3.5):
			cuatro += 1
		total += 1
	return [snappedf(suma / ROJO_POR_CAPA / maxf(total, 1), 0.01), snappedf(100.0 * cuatro / maxf(total, 1), 0.1)]


func _muestra(vp: SubViewport, t: float, n: int) -> void:
	var m := {"t": snappedf(t, 0.01)}
	m.merge(_info_total())
	m["teatro"] = _info_vp(vp)
	m["teatro_px"] = vp.size.x * vp.size.y
	var otras := _ventanas(vp)
	var deb := {"llamadas": 0, "primitivas": 0, "px": 0, "ventanas": otras.size()}
	for o in otras:
		deb.llamadas += o.llamadas
		deb.primitivas += o.primitivas
		deb.px += o.tam[0] * o.tam[1]
	m["debajo"] = deb
	m["debajo_detalle"] = otras
	var cam := vp.get_camera_3d()
	if cam != null:
		m["camara"] = {"pos": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)], "fov": snappedf(cam.fov, 0.1)}
	m.merge(_clasificar(vp))
	var nombre := "erebo_%s_%02d_%03d" % [_etiqueta, n, int(t * 100)]
	m["foto"] = nombre
	var mascara := cam.cull_mask if cam != null else 0
	# 1) color
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(_salida.path_join(nombre + ".png"))
	# 2) sobredibujado: todo, sin efectos, sin efectos ni Érebo
	var capas := {}
	var cuatro := {}
	vp.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
	for paso in [["todo", mascara], ["sin_efectos", mascara & ~CAPA_EFECTOS], ["sin_efectos_ni_erebo", mascara & ~CAPA_EFECTOS & ~CAPA_EREBO]]:
		if cam != null:
			cam.cull_mask = paso[1]
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		if paso[0] == "todo":
			img.save_png(_salida.path_join(nombre + "_sobredibujado.png"))
		var r := _capas(img)
		capas[paso[0]] = r[0]
		cuatro[paso[0]] = r[1]
	vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED
	if cam != null:
		cam.cull_mask = mascara
	m["capas"] = capas
	m["cuatro"] = cuatro
	_muestras.append(m)
