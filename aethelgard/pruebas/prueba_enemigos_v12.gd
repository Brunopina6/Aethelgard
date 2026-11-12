extends SceneTree
# V12, fase C: los modelos nuevos del Guardián de piedra, el Gólem de ámbar y Gorthor (enemigos/*/…_3d.gd).
# Sin ventana, «-- auto» no hace falta. Comprueba, para cada uno:
#   - que carga (GLB, esqueleto, AnimationPlayer, materiales y la textura de cada calidad: 1024 y 512);
#   - triángulos (presupuesto: 8 000; Gorthor, jefe, 10 000) y que coinciden con su JSON;
#   - los clips: todos los de su JSON, con su duración (±1 fotograma) y su bucle, y los instantes del guion = JSON;
#   - los bucles cierran (la pose del principio = la del final) y los pies apoyados no patinan (reposo y esperas);
#   - en marcha (30 fps fijos): atacar_hacha y golpe_fuerte emiten impacto UNA vez, en su fotograma (±2), llaman al
#     golpe una vez y vuelven al reposo; desde cargar(), el golpe fuerte empieza en su instante de carga; las señales
#     evento salen; un golpe recibido no corta un ataque; derrota apaga el brillo;
#   - Gorthor: la boca cerrada en reposo, abierta al rugir; fase2 multiplica el brillo; devorar muerde en su instante;
#     rendirse lo deja de rodillas (y herida no lo levanta); acabar con él de rodillas usa derrota_rendido; retirarse
#     se da la vuelta y se arrastra;
#   - el Gólem: aturdido;
#   - el encuadre del combate (la cámara de combate.gd, _crear_rig_3d): proyecta los huesos y la punta del arma en
#     todos los clips y dice qué «vp», «alto_vista», «centro_y» y «barra_y» hacen falta para que nada se corte.
# Termina con «FALLOS: n» y quit(1) si algo falla.

const JSON_RUTAS := {
	"guardian_piedra": "res://enemigos/guardian_piedra/guardian_piedra_clips.json",
	"golem_ambar": "res://enemigos/golem_ambar/golem_ambar_clips.json",
	"gorthor": "res://enemigos/gorthor/gorthor_clips.json",
}
const GUIONES := {
	"guardian_piedra": "res://enemigos/guardian_piedra/guardian_piedra_3d.gd",
	"golem_ambar": "res://enemigos/golem_ambar/golem_ambar_3d.gd",
	"gorthor": "res://enemigos/gorthor/gorthor_3d.gd",
}
const PRESUPUESTO := {"guardian_piedra": 8000, "golem_ambar": 8000, "gorthor": 10000}
# píxeles de escena por metro que se quieren en el combate (Kael: 800 / 3,0 × 0,67 = 179) y escala del rig
const PX_M := {"guardian_piedra": 165.0, "golem_ambar": 165.0, "gorthor": 175.0}
const ESC := 0.6
# lo que se proyecta además de los huesos (puntas que sobresalen): [hueso, punto local]
const PUNTAS := {
	"guardian_piedra": [["arma", Vector3(0, 1.45, 0)], ["arma", Vector3(0, -0.25, 0)], ["cabeza", Vector3(0, 0.45, 0)],
		["aureola", Vector3(0.0, 0.0, 0.5)], ["aureola", Vector3(0.0, 0.0, -0.5)]],
	"golem_ambar": [["mano.L", Vector3(0, 0.35, 0)], ["mano.R", Vector3(0, 0.35, 0)], ["nido", Vector3(0, 0.45, 0)]],
	"gorthor": [["arma", Vector3(0, 1.25, 0.46)], ["arma", Vector3(0, -0.25, 0)], ["cabeza", Vector3(0, 0.85, 0)],
		["mandibula", Vector3(0, 0.6, 0)]],
}

var fallos := 0
var raiz: Node3D


func _initialize() -> void:
	raiz = Node3D.new()
	root.add_child(raiz)
	_todo.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if cond:
		print("  ok   ", texto)
	else:
		fallos += 1
		print("  FALLO ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _leer_json(ruta: String) -> Dictionary:
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _nuevo(nombre: String, calidad := "alto") -> Node3D:
	var p = load(GUIONES[nombre]).new()
	p.calidad = calidad
	raiz.add_child(p)
	return p


func _todo() -> void:
	for nombre in ["guardian_piedra", "golem_ambar", "gorthor"]:
		print("== ", nombre)
		await _modelo(nombre)
		await _en_marcha(nombre)
		_encuadre(nombre)
	await _combate_real()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# El combate de verdad (combate.tscn) con los cambios de pruebas/herramientas/parche_enemigos_v12.gd aplicados EN
# MEMORIA a una copia de combate.gd (el archivo no se toca), con «-- auto» o sin él (entonces los héroes no actúan y
# solo atacan los enemigos): cada combate fijo corre 75 s de juego. Comprueba que el parche encaja y compila, que el
# enemigo lleva su modelo nuevo, que sus golpes llegan (impacto) y, con Gorthor, que la fase 2 y el último aliento
# ponen sus clips. Los errores de guion los cuenta el ejecutor.
func _combate_real() -> void:
	print("== combate de verdad con los modelos propios (interruptor enemigos_v12; el parche ya está en combate.gd)")
	Engine.set_meta("enemigos_v12", true)
	for caso in [[4, "", "guardian", "guardian3d"], [6, "garganta_nido", "golem_ambar", "golem_ambar3d"],
			[5, "garganta_gorthor", "gorthor", "gorthor_v12"]]:
		for k in ["grupo_combate", "combate_fijo"]:
			if Engine.has_meta(k):
				Engine.remove_meta(k)
		Engine.set_meta("grupo_combate", caso[0])
		if caso[1] != "":
			Engine.set_meta("combate_fijo", caso[1])
		Engine.set_meta("desde_mapa", false)
		var c = load("res://combate.tscn").instantiate()
		root.add_child(c)
		await _esperar(5)
		var e: Dictionary = {}
		for x in c.enemigos:
			if str(x.get("clave", "")) == caso[2]:
				e = x
		_ok(not e.is_empty() and e["modelo"] == caso[3], "  grupo %d: %s con «%s»" % [caso[0], caso[2], e.get("modelo")])
		if e.is_empty():
			c.queue_free()
			continue
		var p = c._p3d(e)
		var golpes := [0]
		var clips := {}
		p.impacto.connect(func(_a): golpes[0] += 1)
		for f in c.heroes:                            # que el combate dure: los héroes aguantan
			f["hp_max"] = 9999
			f["hp"] = 9999
		for i in 75 * 30:
			await process_frame
			if is_instance_valid(p):
				clips[p.clip_actual()] = true
			if caso[2] == "gorthor" and i == 30 * 20 and e["hp"] > e["hp_max"] * 0.5:
				c._quitar_pv(e, e["hp"] - int(e["hp_max"] * 0.45))      # la fase 2
			if caso[2] == "gorthor" and i == 30 * 45 and e["hp"] > 0:
				c._quitar_pv(e, e["hp"])                                # el último aliento (con «auto», el perdón)
			if str(c.get("estado")) == "fin":
				break
		print("    clips vistos: ", clips.keys())
		var ataco: bool = clips.has("ataque") or clips.has("golpe_fuerte") or clips.has("devorar")
		_ok(ataco or clips.has("carga"), "    actúa: ataca o carga (con el azar puede caer antes de golpear)")
		_ok(not ataco or golpes[0] >= 1, "    sus golpes llegan (%d impactos)" % golpes[0])
		if caso[2] == "gorthor":
			_ok(clips.has("fase2"), "    la fase 2 pone su clip")
			_ok(clips.has("rendirse") or clips.has("rendido"), "    el último aliento lo pone de rodillas")
		c.queue_free()
		await _esperar(5)
	Engine.remove_meta("enemigos_v12")


func _triangulos(p: Node) -> int:
	var t := 0
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		for i in m.get_surface_count():
			var arr := m.surface_get_arrays(i)
			var idx = arr[Mesh.ARRAY_INDEX]
			t += (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
	return t


func _modelo(nombre: String) -> void:
	var d := _leer_json(JSON_RUTAS[nombre])
	_ok(not d.is_empty(), "su JSON se lee")
	var p := _nuevo(nombre)
	await _esperar(2)
	_ok(p.anim != null and p.skel != null, "carga el GLB con su esqueleto y su AnimationPlayer")
	if p.anim == null:
		return
	var tris := _triangulos(p)
	_ok(tris == int(d.get("triangulos", -1)), "triángulos: %d (JSON %s)" % [tris, d.get("triangulos")])
	_ok(tris <= PRESUPUESTO[nombre], "dentro del presupuesto (%d)" % PRESUPUESTO[nombre])
	_ok(p.skel.get_bone_count() == int(d.get("huesos", -1)), "huesos: %d" % p.skel.get_bone_count())
	# materiales y texturas
	var con_tex := 0
	var con_brillo := 0
	var color_min := 1.0
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		for i in m3.mesh.get_surface_count():
			var mat := m3.get_surface_override_material(i) as StandardMaterial3D
			if mat == null:
				continue
			if mat.albedo_texture != null:
				con_tex += 1
			if mat.emission_enabled and mat.albedo_texture == null:
				con_brillo += 1
			var cols = m3.mesh.surface_get_arrays(i)[Mesh.ARRAY_COLOR]
			if cols != null:
				for c in cols:
					color_min = minf(color_min, c.r)
	_ok(con_tex >= 1 and con_brillo == 1, "materiales: %d con atlas y 1 de brillo" % con_tex)
	print("       oclusión (color de vértice): mínimo %.3f (0,38-0,45 si llega en sRGB)" % color_min)
	_ok(color_min > 0.3 and color_min < 0.5, "la oclusión llega en sRGB (vertex_color_is_srgb = true es lo correcto)")
	for cal in ["alto", "bajo"]:
		var ruta: String = p.texturas[cal]
		var tx: Texture2D = load(ruta) if ResourceLoader.exists(ruta) else null
		_ok(tx != null and tx.get_width() == (1024 if cal == "alto" else 512), "textura %s: %s" % [cal, ruta.get_file()])
	# clips: los del JSON, duraciones, bucles e instantes
	var clips: Dictionary = d.get("clips", {})
	for c in clips:
		var info: Dictionary = clips[c]
		_ok(p.anim.has_animation(c), "clip «%s»" % c)
		if not p.anim.has_animation(c):
			continue
		var a: Animation = p.anim.get_animation(c)
		_ok(absf(a.length - float(info["duracion"])) <= 1.0 / 30.0 + 0.001,
			"  %s: %.3f s (JSON %.3f)" % [c, a.length, float(info["duracion"])])
		_ok((a.loop_mode == Animation.LOOP_LINEAR) == bool(info["bucle"]), "  %s: bucle %s" % [c, info["bucle"]])
		var ev: Dictionary = info.get("eventos", {})
		var mio: Dictionary = p.eventos_clip.get(c, {})
		for k in ev:
			_ok(mio.has(k) and absf(float(mio[k]) - float(ev[k])) < 0.002, "  %s: instante «%s» %.3f s" % [c, k, float(ev[k])])
		if bool(info["bucle"]):
			_ok(_cierra(p, c), "  %s: el bucle cierra sin salto" % c)
	for minimo in ["reposo", "caminar", "correr", "ataque", "recibir_golpe", "derrota", "entrada", "victoria"]:
		_ok(clips.has(minimo), "tiene el mínimo «%s»" % minimo)
	# pies apoyados en las esperas
	for c in ["reposo", "carga_espera", "rendido"]:
		if p.anim.has_animation(c):
			var desliz := _deslizamiento(p, c)
			_ok(desliz < 0.03, "  %s: los pies no patinan (%.3f m)" % [c, desliz])
	if nombre == "gorthor":
		var cerrada := _angulo_boca(p, "reposo", 0.0)
		var rugido := _angulo_boca(p, "entrada", 1.9)
		_ok(cerrada < 1.0, "boca cerrada en reposo (%.1f°)" % cerrada)
		_ok(rugido > 40.0, "boca abierta al rugir (%.1f°)" % rugido)
		_ok(_angulo_boca(p, "devorar", 0.9) < 3.0 and _angulo_boca(p, "devorar", 0.6) > 40.0,
			"devorar: abierta a 0,6 s y cerrada en el mordisco (0,9 s)")
	p.queue_free()
	var pb := _nuevo(nombre, "bajo")
	await _esperar(2)
	var tb: Texture2D = null
	for mi in pb.find_children("*", "MeshInstance3D", true, false):
		var mt := (mi as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		if mt != null and mt.albedo_texture != null:
			tb = mt.albedo_texture
	_ok(tb != null and tb.get_width() == 512, "con calidad baja usa la textura de 512")
	pb.queue_free()
	await _esperar(1)


# Pose de todos los huesos en el segundo t de un clip (con el AnimationPlayer, sin mezcla).
func _pose(p, clip: String, t: float) -> Array:
	p.anim.play(clip, 0.0)
	p.anim.seek(t, true)
	p.skel.force_update_all_bone_transforms()
	var out := []
	for i in p.skel.get_bone_count():
		out.append(p.skel.get_bone_global_pose(i))
	return out


func _cierra(p, clip: String) -> bool:
	var a := _pose(p, clip, 0.0)
	var b := _pose(p, clip, p.anim.get_animation(clip).length - 0.0001)
	for i in a.size():
		if (a[i].origin - b[i].origin).length() > 0.01:
			return false
	return true


func _deslizamiento(p, clip: String) -> float:
	var peor := 0.0
	for pie in ["pie.L", "pie.R"]:
		var i: int = p.skel.find_bone(pie)
		if i < 0:
			continue
		var ini := Vector3.INF
		var dur: float = p.anim.get_animation(clip).length
		for k in 13:
			var t := dur * k / 12.0
			p.anim.play(clip, 0.0)
			p.anim.seek(t, true)
			p.skel.force_update_all_bone_transforms()
			var o: Vector3 = p.skel.get_bone_global_pose(i).origin
			if ini == Vector3.INF:
				ini = o
			peor = maxf(peor, Vector2(o.x - ini.x, o.z - ini.z).length())
	return peor


func _angulo_boca(p, clip: String, t: float) -> float:
	var i: int = p.skel.find_bone("mandibula")
	p.anim.play(clip, 0.0)
	p.anim.seek(t, true)
	p.skel.force_update_all_bone_transforms()
	var q: Quaternion = p.skel.get_bone_pose_rotation(i)
	var q0: Quaternion = p.skel.get_bone_rest(i).basis.get_rotation_quaternion()
	return rad_to_deg((q0.inverse() * q).get_angle())


# ---------------------------------------------------------------- en marcha (30 fps fijos)

func _en_marcha(nombre: String) -> void:
	var p := _nuevo(nombre)
	await _esperar(3)
	var ev_recibidos := []
	p.evento.connect(func(c, n): ev_recibidos.append("%s:%s" % [c, n]))
	# entrada: sus eventos y vuelve al reposo
	p.entrada()
	await _esperar(int(p.duracion("entrada") * 30) + 12)
	_ok(p.clip_actual() == "reposo", "tras la entrada, reposo")
	for k in p.eventos_clip.get("entrada", {}):
		_ok(ev_recibidos.has("entrada:" + k), "  señal evento «entrada:%s»" % k)
	# ataque normal
	await _medir_ataque(p, "atacar_hacha", "ataque", false)
	# golpe fuerte sin cargar y desde la carga
	await _medir_ataque(p, "golpe_fuerte", "golpe_fuerte", false)
	p.cargar()
	await _esperar(int(p.duracion("carga") * 30) + 6)
	_ok(p.clip_actual() == "carga_espera", "cargar(): se queda en carga_espera")
	p.herida()
	await _esperar(int(p.duracion("recibir_golpe") * 30) + 6)
	_ok(p.clip_actual() == "carga_espera", "herido mientras carga, vuelve a la carga")
	await _medir_ataque(p, "golpe_fuerte", "golpe_fuerte", true)
	# un golpe recibido no corta un ataque
	var cortado := [false]
	p.atacar_hacha(func(): pass)
	await _esperar(5)
	p.herida()
	await _esperar(2)
	_ok(p.clip_actual() == "ataque", "herida() no corta el ataque")
	await _esperar(int(p.duracion("ataque") * 30) + 8)
	if nombre == "golem_ambar":
		p.cargar()
		await _esperar(10)
		p.aturdido()
		await _esperar(4)
		_ok(p.clip_actual() == "aturdido", "aturdido(): el clip de tambalearse")
		p.reposo()
		await _esperar(4)
	if nombre == "gorthor":
		var antes: float = p.brillo_actual()
		p.fase2()
		await _esperar(int(p.duracion("fase2") * 30) + 10)
		_ok(p.en_fase2() and p.clip_actual() == "reposo", "fase2(): ruge y vuelve al reposo")
		_ok(ev_recibidos.has("fase2:rugido"), "  señal evento «fase2:rugido»")
		_ok(p.brillo_actual() > antes * 1.8, "  el brillo de la fase 2 (×%.1f)" % (p.brillo_actual() / maxf(antes, 0.001)))
		await _medir_ataque(p, "devorar", "devorar", false)
		_ok(ev_recibidos.has("devorar:trago"), "  señal evento «devorar:trago»")
		p.rendirse()
		await _esperar(int(p.duracion("rendirse") * 30) + 10)
		_ok(p.clip_actual() == "rendido" and p.esta_rendido(), "rendirse(): de rodillas, en «rendido»")
		p.herida()
		p.reposo()
		await _esperar(4)
		_ok(p.clip_actual() == "rendido", "  herida() y reposo() no lo levantan")
		p.retirarse()
		await _esperar(12)
		_ok(p.clip_actual() == "arrastrarse", "retirarse(): se arrastra")
		_ok(absf(wrapf(p.pivote.rotation.y - atan2(-1.0, -0.25), -PI, PI)) < 0.1, "  mirando hacia atrás (-X)")
		p.queue_free()
		p = _nuevo(nombre)
		await _esperar(3)
		p.rendirse()
		await _esperar(int(p.duracion("rendirse") * 30) + 6)
		p.morir()
		await _esperar(3)
		_ok(p.clip_actual() == "derrota_rendido", "acabar con él de rodillas: derrota_rendido")
		await _esperar(int(p.duracion("derrota_rendido") * 30) + 4)
		_ok(p.brillo_actual() < 0.05, "  el brillo se apaga")
	else:
		p.morir()
		await _esperar(int(p.duracion("derrota") * 30) + 6)
		_ok(p.clip_actual() == "derrota", "morir(): derrota")
		_ok(p.brillo_actual() < 0.05, "  el brillo se apaga (%.2f)" % p.brillo_actual())
	p.queue_free()
	await _esperar(1)


func _medir_ataque(p, metodo: String, clip: String, desde_carga: bool) -> void:
	var golpes := [0]
	var senales := [0]
	var f_imp := [-1]
	var f := [0]
	var con := func(_a): senales[0] += 1
	p.impacto.connect(con)
	var cb := func():
		golpes[0] += 1
		f_imp[0] = f[0]
	var esperado: float = p.tiempo_impacto(metodo)
	match metodo:
		"atacar_hacha":
			p.atacar_hacha(cb)
		"golpe_fuerte":
			p.golpe_fuerte(cb)
		"devorar":
			p.devorar(cb)
	var total := int(p.duracion(clip) * 30) + 12
	for i in total:
		await process_frame
		f[0] += 1
	p.impacto.disconnect(con)
	var fr_esperado := int(round(esperado * 30.0))
	_ok(golpes[0] == 1 and senales[0] == 1, "%s%s: un impacto y un golpe" % [metodo, " (desde la carga)" if desde_carga else ""])
	_ok(absf(f_imp[0] - fr_esperado) <= 2, "  en su fotograma: %d (esperado %d, %.3f s)" % [f_imp[0], fr_esperado, esperado])
	_ok(p.clip_actual() == "reposo", "  y vuelve al reposo")


# ---------------------------------------------------------------- encuadre del combate

func _encuadre(nombre: String) -> void:
	var p := _nuevo(nombre)
	var px_vp: float = PX_M[nombre] / ESC            # píxeles de la ventana 3D por metro
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	var vp := SubViewport.new()
	vp.size = Vector2i(1000, 1000)
	vp.own_world_3d = true
	raiz.add_child(vp)
	vp.add_child(cam)
	p.reparent(vp)
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, sin(ang) * 6.0, cos(ang) * 6.0), Vector3.ZERO)
	cam.current = true
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var cabeza_y := INF
	var por_lo := ["", ""]
	var por_hi := ["", ""]
	for c in p.anim.get_animation_list():
		if c in ["arrastrarse", "derrota", "derrota_rendido", "victoria"]:   # se van o se funden (no cuentan para el encuadre)
			continue
		var dur: float = p.anim.get_animation(c).length
		for k in 9:
			p.anim.play(c, 0.0)
			p.anim.seek(dur * k / 8.0, true)
			p.skel.force_update_all_bone_transforms()
			var pts := []
			for i in p.skel.get_bone_count():
				var bn: String = p.skel.get_bone_name(i)
				if bn in ["escombros", "luz", "onda"]:
					continue
				pts.append(p.hueso_mundo(bn, Vector3.ZERO))
			for pt in PUNTAS[nombre]:
				pts.append(p.hueso_mundo(pt[0], pt[1]))
			for q in pts:
				# en metros de la vista de la cámara (x a la derecha, y arriba), con el modelo mirando a los héroes
				var s: Vector2 = cam.unproject_position(q)
				for eje in 2:
					if s[eje] < lo[eje]:
						lo[eje] = s[eje]
						por_lo[eje] = "%s %.2f s" % [c, dur * k / 8.0]
					if s[eje] > hi[eje]:
						hi[eje] = s[eje]
						por_hi[eje] = "%s %.2f s" % [c, dur * k / 8.0]
			if c == "reposo" and k == 0:
				for q in pts:
					cabeza_y = minf(cabeza_y, cam.unproject_position(q).y)
	# unproject: 1000 px = 10 m de alto → 100 px/m, origen del mundo en el centro (500, 500)
	var m_lo := (lo - Vector2(500, 500)) / 100.0
	var m_hi := (hi - Vector2(500, 500)) / 100.0
	var margen := 0.25
	var alto_vista := snappedf((m_hi.y - m_lo.y) + 2 * margen, 0.1)
	var centro_y := snappedf(-(m_lo.y + m_hi.y) / 2.0 / cos(ang), 0.05)
	var ancho := 2.0 * maxf(absf(m_lo.x), absf(m_hi.x)) + 2 * margen
	var vpv := Vector2i(int(ceil(ancho * px_vp / 10.0) * 10), int(ceil(alto_vista * px_vp / 10.0) * 10))
	var cab_m := -(cabeza_y - 500.0) / 100.0             # lo alto de la cabeza en reposo, en metros de vista
	var cab_px: float = vpv.y / 2.0 - (cab_m - centro_y * cos(ang)) * px_vp
	var barra_y := snappedf(cab_px * ESC - 34.0, 1.0)
	print("       encuadre: x %.2f…%.2f m, y %.2f…%.2f m de vista (izq. %s; der. %s; abajo %s; arriba %s)" % [m_lo.x, m_hi.x,
		-m_hi.y, -m_lo.y, por_lo[0], por_hi[0], por_hi[1], por_lo[1]])
	print("       PROPUESTA MODELOS[\"%s\"]: esc %.2f, vp %s, alto_vista %.1f, centro_y %.2f, barra_y %.0f (%.0f px/m)" % [
		nombre, ESC, vpv, alto_vista, centro_y, barra_y, PX_M[nombre]])
	_ok(vpv.x * vpv.y <= 1600 * 1400, "  la ventana 3D no pasa de 1600×1400 (%s)" % vpv)
	p.queue_free()
	vp.queue_free()
