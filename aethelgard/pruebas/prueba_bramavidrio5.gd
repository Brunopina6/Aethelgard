extends SceneTree
# Prueba de Bramavidrio v5, «la v4 resuelta» (V12, 12/11, noche; enemigos/bramavidrio/v5/, fuente/crear_bramavidrio5.py;
# informe docs/memory/agents/animaciones_v12_bramavidrio5.md). Sin ventana y con datos aislados (ejecutar_pruebas.ps1).
# Lo común a todas las versiones (huesos, clips, instantes, guion, chorro, encuadre de la ventana 3D) lo mira
# prueba_bramavidrio_modelo.gd («version=5»); esta mira lo propio de la v5:
#   A. Los datos del generador (bramavidrio5_clips.json): CERO pares de triángulos que se atraviesen en TODOS los clips
#      (cada 0,1 s y en los instantes del contrato: mandíbulas, colmillos, labios, dientes y cabeza), presupuesto de
#      triángulos (≤ 18 000 / 8 000 / 3 500), el esfínter sin pliegues y las mandíbulas cerradas sin pisarse.
#   B. Las normales horneadas: existen en alto (1024) y medio (512), comprimidas para la GPU, y la piel las usa en esos
#      perfiles (en el bajo, no).
#   C. La boca, fotograma a fotograma con el modelo de verdad (creado como en el combate):
#      reposo: las cuatro mandíbulas CERRADAS y los colmillos plegados en todo el bucle;
#      embestida: se abren a mitad de camino con los colmillos fuera y MUERDEN (cerradas, colmillos desplegados) en 1,0;
#      rugido: abiertas de más con los colmillos erizados; Aliento: abiertas en la descarga; derrota: flojas al final;
#      ningún clip las cierra «de más» (más allá de cerradas).
#   D. El movimiento orgánico: en la embestida la base se lanza antes que la cabeza (seguimiento: la velocidad máxima
#      del cuello junto al agujero llega antes que la de la cabeza); en la herida es al revés (el golpe baja de la cabeza a
#      la cola); mientras fija a su objetivo (0,6 a 0,8 s) el cuello tiembla pero la cabeza se queda clavada (mira al
#      grupo con menos de 6° de error); y el bucle del reposo no se repite a los 3 s (dura 6 s, con la mirada).
#   E. El ENCUADRE en el combate real (grupo 13, la cámara de _crear_rig_3d y la escena del combate): en el aviso de la
#      Fractura (el tramo que se repite) y en toda la descarga del Aliento, las puntas de la corona y de las mandíbulas
#      quedan DENTRO de la pantalla (lienzo de 1280 × 720, el mismo en 20:9 y en 16:9: stretch canvas_items con aspect
#      keep) y de la ventana 3D. Con «comparar» mide también la v4 (solo imprime).
# «solo=A,C» para algunas partes.

const ARCHIVO := "user://prueba_bramavidrio5.save"
const G5 := "res://enemigos/bramavidrio/v5/bramavidrio5_3d.gd"
const JSON5 := "res://enemigos/bramavidrio/v5/bramavidrio5_clips.json"
const DT := 1.0 / 30.0
# px del lienzo que se piden por dentro del borde de arriba, medidos con su dibujo quieto: en el combate el dibujo de cada
# luchador «respira» (combate.gd, _process: escala vertical ± 1,2 % y giro ± 0,8° sobre sus pies), y en el de Bramavidrio,
# con el agujero a la izquierda y la cabeza 600-700 px más allá, eso mueve lo alto de la cabeza unos ± 17 px
const MARGEN := 20.0

var fallos := 0
var partes := "ABCDE"
var comparar := false
var P
var G
var B


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	B = load("res://combate_bramavidrio.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			partes = a.substr(5).replace(",", "")
		if a == "comparar":
			comparar = true
	_correr.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + texto)
	if not cond:
		fallos += 1


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	await _esperar(5)
	if "A" in partes:
		_datos()
	if "B" in partes:
		await _normales()
	if "C" in partes or "D" in partes:
		await _boca_y_movimiento()
	if "E" in partes:
		await _encuadre_combate(5)
		if comparar:
			await _encuadre_combate(4)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ---------------------------------------------------------------- A. los datos del generador

func _datos() -> void:
	print("== A. los datos del generador (%s)" % JSON5)
	var f := FileAccess.open(JSON5, FileAccess.READ)
	_ok(f != null, "existe el JSON")
	if f == null:
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var tot: Dictionary = d.get("intersecciones_total", {})
	var instantes := 0
	for c in d.get("intersecciones", {}):
		instantes += (d["intersecciones"][c] as Array).size()
	_ok(tot.size() == 10, "roces comprobados en los 10 clips (%d)" % tot.size())
	var suma := 0
	for c in tot:
		suma += int(tot[c])
	_ok(suma == 0 and instantes >= 250, "CERO pares de triángulos que se atraviesan en %d instantes de los 10 clips (%s)" % [instantes, str(tot)])
	var tris: Dictionary = d.get("triangulos", {})
	_ok(int(tris.get("alto", 99999)) <= 18000 and int(tris.get("medio", 99999)) <= 8000 and int(tris.get("bajo", 99999)) <= 3500,
		"presupuesto de triángulos: %s (≤ 18 000 / 8 000 / 3 500)" % str(tris))
	var e: Dictionary = d.get("esfinter", {})
	_ok(float(e.get("paso_radial_minimo_m", -1.0)) > 0.0, "el esfínter se frunce sin pliegues (paso radial mínimo %s m)" % str(e.get("paso_radial_minimo_m")))
	_ok(float(e.get("holgura_cuadrantes_m", -1.0)) > 0.0, "las mandíbulas y sus colmillos se quedan en su cuadrante, abiertas o cerradas (holgura %s m; los roces de verdad, arriba)" % str(e.get("holgura_cuadrantes_m")))
	var g: Dictionary = d.get("garganta_desde_camara", {})
	_ok(float(g.get("max_entrada", 9.0)) < 1.0, "desde la cámara del combate el anclaje del chorro cae dentro de la entrada de la garganta (%.2f)" % float(g.get("max_entrada", 9.0)))
	_ok((d.get("corona", []) as Array).size() == 5, "el JSON trae las cinco puntas de la corona")
	# 2.ª vuelta: ninguna mandíbula se separa de la cabeza y la piel que las une no se rompe ni se aplasta
	var sep: Dictionary = d.get("separacion_bisagra_m", {})
	var peor_sep := 0.0
	for c in sep:
		for m in sep[c]:
			peor_sep = maxf(peor_sep, float(sep[c][m]))
	_ok(sep.size() == 10 and peor_sep < 0.005, "en los 10 clips cada mandíbula sigue en su bisagra del collar (separación máx. %.4f m)" % peor_sep)
	var est: Dictionary = d.get("piel_boca_estiramiento", {})
	var e_max := 0.0
	var e_min := 9.0
	for c in est:
		e_max = maxf(e_max, float(est[c][0]))
		e_min = minf(e_min, float(est[c][1]))
	_ok(est.size() == 10 and e_max < 2.5 and e_min > 0.2,
		"la piel continua de la boca (belfos, encías y mejillas) se estira como mucho ×%.2f y se recoge hasta ×%.2f" % [e_max, e_min])


# ---------------------------------------------------------------- B. las normales horneadas

func _normales() -> void:
	print("== B. las normales horneadas")
	var S = load(G5)
	for perfil in ["alto", "medio"]:
		var ruta: String = S.NORMALES[perfil]
		var t: Texture2D = load(ruta)
		var lado := 1024 if perfil == "alto" else 512
		_ok(t != null and t.get_width() == lado, "[%s] %s de %d px" % [perfil, ruta.get_file(), t.get_width() if t != null else 0])
		if t != null:
			var img := t.get_image()
			_ok(img != null and img.is_compressed() and img.has_mipmaps(), "[%s] normales comprimidas para la GPU y con mipmaps (%s)" %
				[perfil, img.get_format() if img != null else -1])
	for perfil in ["alto", "medio", "bajo"]:
		var g: Node3D = S.new()
		g.calidad = perfil
		root.add_child(g)
		await _esperar(2)
		var usa := false
		for m in g._mats["piel"]:
			if (m as ShaderMaterial).get_shader_parameter("normales") != null:
				usa = true
		_ok(usa == (perfil != "bajo") and g.con_normales == usa, "[%s] la piel %s las normales" % [perfil, "usa" if usa else "no usa"])
		g.queue_free()
		await _esperar(2)


# ---------------------------------------------------------------- C y D. la boca y el movimiento, fotograma a fotograma

func _pos_hueso(g: Node3D, h: String) -> Vector3:
	var i: int = g.skel.find_bone(h)
	return g.skel.global_transform * g.skel.get_bone_global_pose(i).origin / g.escala


func _giro_hueso(g: Node3D, h: String) -> Quaternion:
	var i: int = g.skel.find_bone(h)
	return g.skel.get_bone_global_pose(i).basis.get_rotation_quaternion()


func _boca_y_movimiento() -> void:
	print("== C y D. la boca y el movimiento (el guion creado como en el combate)")
	var g: Node3D = load(G5).new()
	g.calidad = "alto"
	root.add_child(g)
	await _esperar(3)
	_ok(g.anim != null and g.skel != null, "el guion encuentra el modelo")
	if g.anim == null:
		return
	g._eventos = []
	g._espera = []
	var resumen := {}
	var min_ap := INF
	var vel := {}
	var mira_max := 0.0
	var tiembla := 0.0
	var descarga_min := INF
	var salto := [0.0, 0.0]
	var tray := {"cabeza": [], "base": []}                # embestida, de 0,8 a 1,0 s: [t, posición]
	for c in g.CLIPS:
		g._clip = c
		g.anim.play(c, 0.0)
		g.anim.speed_scale = 0.0
		var largo: float = g.anim.get_animation(c).length
		var t := 0.0
		var ap_max := 0.0
		var ap_min := INF
		var co_max := 0.0
		var co_min := INF
		var prev := {}
		while t <= largo + 0.001:
			g.anim.seek(t, true)
			g.anim.advance(0.0)
			var ap: float = g.apertura_mandibulas()
			var co := 0.0
			for k in 4:
				co += g.colmillos(k) / 4.0
				min_ap = minf(min_ap, g.apertura_mandibulas(k))
			ap_max = maxf(ap_max, ap)
			ap_min = minf(ap_min, ap)
			co_max = maxf(co_max, co)
			co_min = minf(co_min, co)
			if c == "ataque" and absf(t - 1.0) < 0.001:
				_ok(ap < 0.08 and co > 0.85, "embestida: en el mordisco (1,0 s) las mandíbulas CERRADAS (%.2f) con los colmillos desplegados (%.2f)" % [ap, co])
			if c == "ataque" and t >= 0.85 and t <= 0.97:
				salto = [maxf(salto[0], ap), maxf(salto[1], co)]
			if c == "ataque_aliento" and t >= 1.9 and t <= 2.6:
				descarga_min = minf(descarga_min, ap)
			if c == "derrota" and absf(t - largo) < 0.02:
				_ok(ap > 0.2 and ap < 0.8, "derrota: al final las mandíbulas quedan flojas, entreabiertas (%.2f)" % ap)
			if c == "ataque" and t >= 0.8 - 0.001 and t <= 1.0 + 0.001:
				tray["cabeza"].append([t, _pos_hueso(g, "cabeza")])
				tray["base"].append([t, _giro_hueso(g, "col_09")])
			# D: velocidades de la cabeza y del cuello junto al agujero
			if c in ["ataque", "herida"]:
				var pc := _pos_hueso(g, "cabeza")
				var pb := _pos_hueso(g, "col_09")
				if prev.has("c"):
					if not vel.has(c):
						vel[c] = {"cabeza": [0.0, 0.0], "base": [0.0, 0.0]}
					var vc: float = pc.distance_to(prev["c"]) / DT
					var vb: float = pb.distance_to(prev["b"]) / DT
					var lim := 1.05 if c == "ataque" else 0.6
					if t <= lim:
						if vc > vel[c]["cabeza"][0]:
							vel[c]["cabeza"] = [vc, t]
						if vb > vel[c]["base"][0]:
							vel[c]["base"] = [vb, t]
				prev["c"] = pc
				prev["b"] = pb
			# D: mientras fija, la cabeza clavada en el grupo y el cuello temblando
			if c == "ataque" and t >= 0.62 and t <= 0.8:
				var dir: Vector3 = (g.boca() - g.origen_chorro()).normalized()
				if not prev.has("dir0"):
					prev["dir0"] = dir
					prev["cuello0"] = _pos_hueso(g, "col_04")
				mira_max = maxf(mira_max, rad_to_deg(dir.angle_to(prev["dir0"])))
				tiembla = maxf(tiembla, _pos_hueso(g, "col_04").distance_to(prev["cuello0"]))
			t += DT
		resumen[c] = [snappedf(ap_min, 0.01), snappedf(ap_max, 0.01), snappedf(co_min, 0.01), snappedf(co_max, 0.01)]
	print("   mandíbulas (mín., máx.) y colmillos (mín., máx.) por clip: %s" % str(resumen))
	if "C" in partes:
		_ok(resumen["reposo"][1] < 0.06 and resumen["reposo"][3] < 0.15,
			"reposo: las mandíbulas CERRADAS (máx. %.2f) y los colmillos plegados (máx. %.2f) en todo el bucle" % [resumen["reposo"][1], resumen["reposo"][3]])
		_ok(resumen["rugido"][1] > 1.05 and resumen["rugido"][3] > 1.03,
			"rugido: abiertas de más (%.2f) con los colmillos erizados (%.2f)" % [resumen["rugido"][1], resumen["rugido"][3]])
		_ok(resumen["ataque_sismico"][1] > 0.85 and resumen["ataque_aliento"][1] > 0.95,
			"la Fractura y el Aliento abren las mandíbulas (%.2f y %.2f)" % [resumen["ataque_sismico"][1], resumen["ataque_aliento"][1]])
		_ok(min_ap > -0.03, "ningún clip las cierra de más (apertura mínima de una mandíbula %.3f)" % min_ap)
		_ok(resumen["subterraneo"][1] < 0.06, "bajo la arena, cerradas (%.2f)" % resumen["subterraneo"][1])
		_ok(descarga_min > 0.8, "Aliento: abiertas en toda la descarga (1,9 a 2,6 s; mínimo %.2f)" % descarga_min)
		_ok(salto[0] > 0.6 and salto[1] > 0.95, "embestida: en el salto (0,85 a 0,97 s) se abren (%.2f) con los colmillos fuera (%.2f)" % salto)
	if "D" in partes:
		var at: Dictionary = vel.get("ataque", {"cabeza": [0.0, 0.0], "base": [0.0, 0.0]})
		var he: Dictionary = vel.get("herida", {"cabeza": [0.0, 0.0], "base": [0.0, 0.0]})
		print("   velocidad máxima (m/s, s): embestida %s · herida %s" % [str(at), str(he)])
		# qué parte de su recorrido del salto lleva cada uno: la cabeza, su camino; el cuello junto al agujero, su GIRO (la
		# curva del cuerpo: su posición también cambia porque el cuerpo sale del agujero a la vez que la cabeza)
		var avance := {"cabeza": [], "base": []}
		var trc: Array = tray["cabeza"]
		var trb: Array = tray["base"]
		var tot_c: float = maxf((trc[-1][1] as Vector3).distance_to(trc[0][1]), 0.0001)
		var tot_b: float = maxf((trb[-1][1] as Quaternion).angle_to(trb[0][1]), 0.0001)
		for e in trc:
			avance["cabeza"].append(snappedf((e[1] as Vector3).distance_to(trc[0][1]) / tot_c, 0.01))
		for e in trb:
			avance["base"].append(snappedf((e[1] as Quaternion).angle_to(trb[0][1]) / tot_b, 0.01))
		print("   embestida, de 0,8 a 1,0 s: parte del salto hecha por la cabeza %s y del giro del cuello junto al agujero %s" %
			[str(avance["cabeza"]), str(avance["base"])])
		var llega := {}                                    # cuándo llega cada uno al 95 % de su recorrido
		for q in ["cabeza", "base"]:
			for i in avance[q].size():
				if avance[q][i] >= 0.95:
					llega[q] = 0.8 + i * DT
					break
		_ok(llega.get("base", 9.0) < llega.get("cabeza", 0.0) - 0.02,
			"embestida: el látigo: el cuello junto al agujero llega a su sitio (%.2f s) antes que la cabeza (%.2f s), que llega la última" %
			[llega.get("base", 9.0), llega.get("cabeza", 0.0)])
		_ok(he["cabeza"][1] < he["base"][1],
			"herida: el golpe baja de la cabeza a la cola (la cabeza a %.2f s, el cuello a %.2f s)" % [he["cabeza"][1], he["base"][1]])
		_ok(mira_max < 6.0 and tiembla > 0.01, "embestida, fijando: la boca clavada en su objetivo (gira %.1f° como mucho) mientras el cuello tiembla (%.3f m)" % [mira_max, tiembla])
		_ok(absf(g.anim.get_animation("reposo").length - 6.0) < 0.01, "el reposo dura 6 s (dos respiraciones y la mirada que pasa de un héroe a otro)")
	g.anim.speed_scale = 1.0
	g.queue_free()
	await _esperar(2)


# ---------------------------------------------------------------- E. el encuadre en el combate real

func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "prueba_curar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# El punto en el lienzo SIN la sacudida de la pantalla (combate_bramavidrio.gd la hace moviendo c.capa.offset): la
# sacudida es pasajera y no cambia el encuadre.
var capa_combate: CanvasLayer = null


func _en_lienzo(z: Dictionary, w: Vector3) -> Vector2:
	var spr: Sprite2D = z["partes"]["sprite"]
	var cam: Camera3D = z["cam3d"]
	var s: Vector2 = spr.get_global_transform_with_canvas() * cam.unproject_position(w)
	if capa_combate != null and is_instance_valid(capa_combate):
		s -= capa_combate.offset
	return s


func _encuadre_combate(version: int) -> void:
	print("== E. el encuadre en el combate real, versión %d" % version)
	_limpiar()
	Engine.set_meta("bramavidrio_version", version)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", B.GRUPO)
	Engine.set_meta("combate_fijo", B.COMBATE)
	seed(5)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	var z: Dictionary = c.enemigos[0]
	var p = c._p3d(z)
	_ok(p != null and int(p.VERSION) == version, "el combate usa la versión %d (%s)" % [version, p.get_script().resource_path if p != null else "—"])
	if p == null:
		c.queue_free()
		return
	await _esperar(240)                                   # la emersión de la entrada (y que acabe la sacudida de la cámara)
	c.set_process(false)                                  # sin turnos: el modelo lo mueve esta prueba
	c.set_physics_process(false)
	(z["cuerpo"] as Node2D).scale = Vector2.ONE                 # su dibujo quieto (sin la respiración del combate)
	(z["cuerpo"] as Node2D).rotation = 0.0
	capa_combate = c.capa if "capa" in c else null
	var lienzo: Rect2 = root.get_visible_rect()
	var vp: Vector2 = (z["cam3d"] as Camera3D).get_viewport().get_visible_rect().size
	print("   lienzo %s, ventana 3D %s" % [lienzo, vp])
	var serie := {}                                       # clip → [[s, y más alta], …] cada ~0,2 s (para el informe)
	var medir := func(etiqueta: String, peor: Dictionary, clip: String, ts: float) -> void:
		var pts: PackedVector3Array = p.puntos_silueta() if p.has_method("puntos_silueta") else _silueta_aprox(p)
		var arriba := INF
		for iw in pts.size():
			var w: Vector3 = pts[iw]
			var s: Vector2 = _en_lienzo(z, w)
			var v: Vector2 = (z["cam3d"] as Camera3D).unproject_position(w)
			arriba = minf(arriba, s.y)
			if s.y < peor.get("y", INF):
				peor["y"] = s.y
				peor["donde"] = etiqueta + " " + ["cuerno izq.", "cuerno lat. izq.", "cuerno der.", "cuerno lat. der.", "cresta",
					"mandíbula arriba", "mandíbula izq.", "mandíbula abajo", "mandíbula der."][mini(iw, 8)]
			if s.x < peor.get("x0", INF):
				peor["x0"] = s.x
				peor["donde_x"] = etiqueta
			peor["x1"] = maxf(peor.get("x1", -INF), s.x)
			peor["vp_y"] = minf(peor.get("vp_y", INF), v.y)
		if not serie.has(clip):
			serie[clip] = []
		if (serie[clip] as Array).is_empty() or ts - float(serie[clip][-1][0]) >= 0.19:
			serie[clip].append([snappedf(ts, 0.01), roundi(arriba)])
	var jugar := func(clip: String, peores: Array) -> void:   # peores: [[desde, hasta, dict], …]
		while String(p.anim.current_animation) == clip:
			await process_frame
			var ts: float = p.anim.current_animation_position
			for q in peores:
				if ts >= q[0] - 0.001 and ts <= q[1] + 0.001:
					medir.call("%s %.2f s" % [clip, ts], q[2], clip, ts)
	# 0) el reposo (un bucle entero, 6 s o los que dure)
	var peor_0 := {}
	p.reposo()
	await _esperar(12)
	var largo_reposo: float = p.anim.get_animation("reposo").length
	for i in int(largo_reposo * 30.0):
		await process_frame
		medir.call("reposo %.2f s" % p.anim.current_animation_position, peor_0, "reposo", float(i) / 30.0)
	# 1) el aviso de la Fractura y su tramo de espera (2,5 s), y su caída
	var peor_f := {}
	var peor_fc := {}
	p.avisar("sismico")
	for i in 75:
		await process_frame
		medir.call("aviso Fractura %.2f s" % p.anim.current_animation_position, peor_f, "ataque_sismico", p.anim.current_animation_position)
	p.atacar("sismico")
	await jugar.call("ataque_sismico", [[0.0, 2.1, peor_f], [2.1, 9.0, peor_fc]])
	await _esperar(20)
	# 2) el Aliento entero (la descarga de 1,85 a 2,6 s aparte)
	var peor_a := {}
	var peor_d := {}
	p.atacar("aliento")
	await jugar.call("ataque_aliento", [[0.0, 9.0, peor_a], [1.85, 2.6, peor_d]])
	await _esperar(20)
	# 3) el rugido, la embestida, la herida y la derrota
	var peor_r := {}
	p.rugir()
	await jugar.call("rugido", [[0.0, 9.0, peor_r]])
	var peor_e := {}
	p.atacar("embestida")
	await jugar.call("ataque", [[0.0, 9.0, peor_e]])
	await _esperar(20)
	var peor_h := {}
	p.herida()
	await _esperar(2)
	await jugar.call("herida", [[0.0, 9.0, peor_h]])
	var peor_m := {}
	p.morir()
	await _esperar(2)
	await jugar.call("derrota", [[0.0, 9.0, peor_m]])
	for par in [["reposo", peor_0], ["Fractura (aviso)", peor_f], ["Fractura (caída)", peor_fc], ["Aliento", peor_a],
			["descarga del Aliento", peor_d], ["rugido", peor_r], ["embestida", peor_e], ["herida", peor_h], ["derrota", peor_m]]:
		var pe: Dictionary = par[1]
		print("   v%d %s: lo más alto de la cabeza a y = %.0f px del lienzo (%s); x de %.0f (%s) a %.0f; en la ventana 3D, y = %.0f" %
			[version, par[0], pe.get("y", 0.0), pe.get("donde", "—"), pe.get("x0", 0.0), pe.get("donde_x", "—"), pe.get("x1", 0.0),
			pe.get("vp_y", 0.0)])
	print("   v%d, lo más alto (y del lienzo) cada 0,2 s: %s" % [version, str(serie)])
	if version == 5:
		for par in [["el aviso de la Fractura", peor_f], ["la caída de la Fractura", peor_fc], ["la descarga del Aliento", peor_d]]:
			var pe: Dictionary = par[1]
			_ok(pe.get("y", -1.0) >= lienzo.position.y + MARGEN and pe.get("vp_y", -1.0) >= 0.0,
				"%s: los cuernos y la corona DENTRO de la pantalla (lo más alto a %.0f px del borde de arriba; %s)" %
				[par[0], pe.get("y", -1.0) - lienzo.position.y, pe.get("donde", "—")])
			_ok(pe.get("x0", -1.0) >= lienzo.position.x and pe.get("x1", 1e9) <= lienzo.end.x,
				"%s: y por los lados (x de %.0f a %.0f)" % [par[0], pe.get("x0", 0.0), pe.get("x1", 0.0)])
	c.queue_free()
	await _esperar(5)
	Engine.remove_meta("bramavidrio_version")


# Para comparar con la v4 (sin puntos_silueta): las mismas puntas de la corona de la v5 con el hueso «cabeza» de la v4
# (la cabeza tiene el mismo origen y tamaño; los cuernos de la v4 son algo más altos: la medida la favorece).
func _silueta_aprox(p) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var S = load(G5)
	var i: int = p.skel.find_bone("cabeza")
	var m: Transform3D = p.skel.global_transform * (p.skel.get_bone_global_pose(i) * p.skel.get_bone_global_rest(i).affine_inverse())
	for q in S.CORONA:
		pts.append(m * q)
	return pts
