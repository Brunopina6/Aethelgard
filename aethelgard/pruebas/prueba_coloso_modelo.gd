extends SceneTree
# Prueba del Coloso de la Falla (V9, jefe de la Garganta 3D): el modelo hecho con Blender, sus clips, su presupuesto
# móvil y su guion de combate (enemigos/coloso_falla/coloso_falla_3d.gd), creado con .new() como en combate.gd.
#   sin ventana:  --headless --script res://pruebas/prueba_coloso_modelo.gd --fixed-fps 30
# Comprueba (y acaba con «FALLOS: n»):
#  - el GLB importado trae los 8 clips (reposo, ataque, carga, golpe_fuerte, herido, fase2, derrota, dormido); cada
#    clip escribe todos los huesos; con el guion, en bucle solo reposo, carga y dormido
#  - presupuesto: ≤ 12 000 triángulos, ≤ 30 huesos, ≤ 2 materiales (piedra con colores de vértice y runas emisivas),
#    sin texturas; los colores de vértice leídos en su espacio
#  - los bucles cierran sin salto; ataque, golpe_fuerte, herido y fase2 acaban en la pose del reposo (fase2, salvo las
#    placas, que quedan abiertas); golpe_fuerte empieza en la pose de la carga
#  - piezas escondidas por escala: musgo solo en dormido, lascas y rocas solo en golpe_fuerte, grietas de la derrota
#    solo en derrota, brillo de las grietas vulnerables fuera de dormido
#  - el guion: empieza en reposo y mira a los héroes; en la fase 1 las grietas vulnerables no brillan salvo señaladas;
#    el puñetazo y el golpe fuerte (tras cargar) dan su impacto UNA vez y en su ancla (0,6 s y 0,667 s); cargar avisa
#    una vez; un golpe recibido reacciona y vuelve a la carga; fase2 abre las placas (señal) y las mantiene, también al
#    atacar; las runas laten y se encienden; derrota de rodillas con las runas apagadas y ya no ataca; dormido de pie
#    como una estatua y despertar; alcance; ALTURA para Érebo
#  - el encuadre propuesto para MODELOS de combate.gd (misma cámara que _crear_rig_3d): todo cabe en la ventana 3D en
#    todos los clips (manos, placas, cabeza, monolitos y rocas), y dónde caen los pies y lo alto

const GLB := "res://enemigos/coloso_falla/coloso_falla.glb"
const GUION := "res://enemigos/coloso_falla/coloso_falla_3d.gd"
const CLIPS := ["reposo", "ataque", "carga", "golpe_fuerte", "herido", "fase2", "derrota", "dormido"]
const BUCLES := ["reposo", "carga", "dormido"]
const PLACAS := ["placa_hombro.L", "placa_hombro.R", "placa_antebrazo.L", "placa_antebrazo.R"]
const MAX_TRIANGULOS := 12000
const MAX_HUESOS := 30
const TOL := 0.05
const DT := 1.0 / 30.0
# Encuadre propuesto (MODELOS["coloso_falla"])
const VP := Vector2i(1260, 1360)
const ALTO_VISTA := 6.2
const CENTRO_Y := 2.3
const ESC := 0.64

var fallos := 0
var registro := {}


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + texto)
	if not cond:
		fallos += 1


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	print("== Coloso de la Falla: modelo, clips y guion")
	await _comprobar_glb()
	await _comprobar_guion()
	await _encuadre()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ---------------------------------------------------------------- el GLB tal cual se importa

func _comprobar_glb() -> void:
	var ps: PackedScene = load(GLB)
	_ok(ps != null, "el GLB se carga: " + GLB)
	if ps == null:
		return
	var n: Node = ps.instantiate()
	root.add_child(n)
	var aps := n.find_children("*", "AnimationPlayer", true, false)
	var sks := n.find_children("*", "Skeleton3D", true, false)
	_ok(aps.size() == 1 and sks.size() == 1, "un AnimationPlayer y un esqueleto")
	if aps.is_empty() or sks.is_empty():
		return
	var ap: AnimationPlayer = aps[0]
	var sk: Skeleton3D = sks[0]
	var lista := Array(ap.get_animation_list()).map(func(x): return String(x))
	print("  clips: ", lista)
	for c in CLIPS:
		_ok(c in lista, "existe el clip " + c)
	_ok(lista.size() == CLIPS.size(), "solo esos 8 clips (%d)" % lista.size())
	_ok(sk.get_bone_count() <= MAX_HUESOS, "huesos: %d (máximo %d)" % [sk.get_bone_count(), MAX_HUESOS])
	for c in lista:
		var a := ap.get_animation(c)
		print("  %s: %.3f s, %d pistas" % [c, a.length, a.get_track_count()])
		var huesos := {}
		for k in a.get_track_count():
			var p := String(a.track_get_path(k))
			if a.track_get_type(k) == Animation.TYPE_ROTATION_3D and ":" in p:
				huesos[p.get_slice(":", 1)] = true
		_ok(huesos.size() == sk.get_bone_count(), "%s gira los %d huesos (tiene %d)" % [c, sk.get_bone_count(), huesos.size()])
	# malla y materiales
	var tris := 0
	var superficies := 0
	var mats := {}
	var texturas := 0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		if m == null:
			continue
		tris += m.get_faces().size() / 3
		superficies += m.get_surface_count()
		for i in m.get_surface_count():
			var mat := (mi as MeshInstance3D).get_active_material(i) as StandardMaterial3D
			if mat == null:
				continue
			mats[mat.resource_name] = mat
			if mat.albedo_texture != null or mat.emission_texture != null or mat.normal_texture != null:
				texturas += 1
	_ok(tris > 4000 and tris <= MAX_TRIANGULOS, "triángulos: %d (máximo %d)" % [tris, MAX_TRIANGULOS])
	_ok(superficies <= 2 and mats.size() <= 2, "materiales: %d en %d superficies (%s)" % [mats.size(), superficies, ", ".join(mats.keys())])
	_ok(texturas == 0, "sin texturas (colores de vértice): %d" % texturas)
	var piedra: StandardMaterial3D = mats.get("piedra")
	var runas: StandardMaterial3D = mats.get("runas")
	_ok(piedra != null and piedra.vertex_color_use_as_albedo, "piedra: color de los vértices como albedo")
	_ok(runas != null and runas.emission_enabled, "runas: emisivas (runas, ojos y grietas)")
	for m in mats.values():
		_ok(m.cull_mode == BaseMaterial3D.CULL_BACK, "%s: una cara (cull back)" % m.resource_name)
	# el color de vértice de las runas es (0,34; 0,26; 0,19) en sRGB, (0,093; 0,052; 0,026) en lineal
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		for i in m.get_surface_count():
			var mat := (mi as MeshInstance3D).get_active_material(i) as StandardMaterial3D
			if mat == null or mat.resource_name != "runas":
				continue
			var cols: PackedColorArray = m.surface_get_arrays(i)[Mesh.ARRAY_COLOR]
			if cols.is_empty():
				continue
			var c: Color = cols[0]
			var en_srgb := absf(c.r - 0.34) < 0.05
			print("  color de vértice de las runas importado: ", c, " (", "sRGB" if en_srgb else "lineal", ")")
			if piedra != null:
				_ok(piedra.vertex_color_is_srgb == en_srgb, "piedra lee los colores de vértice en su espacio (vertex_color_is_srgb=%s)" % piedra.vertex_color_is_srgb)
	# bucles sin salto; los clips de acción acaban en la pose del reposo
	for c in BUCLES:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, c, 0.0)
		_ok(d.x < 0.5 and d.y < 0.003, "%s cierra el bucle sin salto (%.2f°, %.4f m)" % [c, d.x, d.y])
	for c in ["ataque", "golpe_fuerte", "herido", "fase2"]:
		var excluir := PLACAS if c == "fase2" else []
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, "reposo", 0.0, excluir)
		_ok(d.x < 1.0 and d.y < 0.005, "%s acaba en la pose del reposo (giro %.2f°, posición %.4f m)" % [c, d.x, d.y])
	var dc := _diferencia_pose(ap, sk, "golpe_fuerte", 0.0, "carga", 0.0)
	_ok(dc.x < 1.0 and dc.y < 0.005, "golpe_fuerte empieza en la pose de la carga (%.2f°, %.4f m)" % [dc.x, dc.y])
	var dp := _diferencia_pose(ap, sk, "fase2", ap.get_animation("fase2").length, "reposo", 0.0)
	_ok(dp.y > 0.2, "fase2 acaba con las placas abiertas (%.2f m de la pose cerrada)" % dp.y)
	# piezas escondidas por la escala de su hueso
	for c in lista:
		var a := ap.get_animation(c)
		var musgo := _escala_max(a, "musgo")
		var rocas := _escala_max(a, "rocas")
		var proy := _escala_max(a, "proyectiles")
		var gd := _escala_max(a, "grietas_derrota")
		var gv := _escala_max(a, "grietas")
		_ok((musgo > 0.9) == (c == "dormido"), "%s: musgo %s (escala máx. %.2f)" % [c, "visible" if musgo > 0.9 else "escondido", musgo])
		_ok((rocas > 0.9) == (c == "golpe_fuerte") and (proy > 0.9) == (c == "golpe_fuerte"), "%s: lascas %.2f y rocas %.2f" % [c, rocas, proy])
		_ok((gd > 0.9) == (c == "derrota"), "%s: grietas de la derrota %.2f" % [c, gd])
		_ok((gv < 0.05) == (c == "dormido"), "%s: brillo de las grietas en el clip %.2f (la fase 1 lo esconde el guion)" % [c, gv])
	n.queue_free()
	await _esperar(2)


func _escala_max(a: Animation, hueso: String) -> float:
	var mx := 0.0
	for k in a.get_track_count():
		if a.track_get_type(k) == Animation.TYPE_SCALE_3D and String(a.track_get_path(k)).ends_with(":" + hueso):
			var t := 0.0
			while t <= a.length + 0.001:
				mx = maxf(mx, a.scale_track_interpolate(k, t).x)
				t += DT
			return mx
	return 1.0


func _diferencia_pose(ap: AnimationPlayer, sk: Skeleton3D, c1: String, t1: float, c2: String, t2: float, excluir: Array = []) -> Vector2:
	var a1 := ap.get_animation(c1)
	var a2 := ap.get_animation(c2)
	var giro := 0.0
	var mov := 0.0
	for i in sk.get_bone_count():
		if sk.get_bone_name(i) in excluir:
			continue
		var suf := ":" + sk.get_bone_name(i)
		var r1: Quaternion = _valor(a1, suf, Animation.TYPE_ROTATION_3D, t1, sk.get_bone_rest(i).basis.get_rotation_quaternion())
		var r2: Quaternion = _valor(a2, suf, Animation.TYPE_ROTATION_3D, t2, sk.get_bone_rest(i).basis.get_rotation_quaternion())
		giro = maxf(giro, rad_to_deg(r1.angle_to(r2)))
		var p1: Vector3 = _valor(a1, suf, Animation.TYPE_POSITION_3D, t1, sk.get_bone_rest(i).origin)
		var p2: Vector3 = _valor(a2, suf, Animation.TYPE_POSITION_3D, t2, sk.get_bone_rest(i).origin)
		mov = maxf(mov, p1.distance_to(p2))
	return Vector2(giro, mov)


func _valor(a: Animation, sufijo: String, tipo: int, t: float, defecto: Variant) -> Variant:
	for k in a.get_track_count():
		if a.track_get_type(k) == tipo and String(a.track_get_path(k)).ends_with(sufijo):
			return a.rotation_track_interpolate(k, t) if tipo == Animation.TYPE_ROTATION_3D else a.position_track_interpolate(k, t)
	return defecto


# ---------------------------------------------------------------- el guion, creado como en combate.gd

func _nuevo() -> Node3D:
	var g: Node3D = load(GUION).new()
	g.ruta_modelo = GLB
	root.add_child(g)
	for s in ["aviso", "impacto", "ataque_terminado", "clip_terminado"]:
		g.connect(s, func(a): _anotar(g, s, a))
	g.placas_abiertas.connect(func(): _anotar(g, "placas_abiertas", null))
	g.coraza_desplegada.connect(func(): _anotar(g, "coraza_desplegada", null))
	return g


func _anotar(g: Node3D, s: String, a) -> void:
	if not registro.has(s):
		registro[s] = []
	registro[s].append([Engine.get_process_frames(), g.anim.current_animation_position, a])


func _veces(s: String) -> int:
	return registro.get(s, []).size()


func _clip(g: Node3D) -> String:
	return String(g.anim.current_animation)


func _escala_hueso(g: Node3D, hueso: String) -> float:
	return g.skel.get_bone_pose_scale(g.skel.find_bone(hueso)).x


# Distancia de la placa del hombro derecho a su sitio cerrado (en el espacio de su padre).
func _apertura(g: Node3D) -> float:
	var i: int = g.skel.find_bone("placa_hombro.R")
	return g.skel.get_bone_pose_position(i).distance_to(g.skel.get_bone_rest(i).origin)


func _comprobar_guion() -> void:
	var g := _nuevo()
	await _esperar(3)
	_ok(g.anim != null and g.skel != null, "creado con .new() y ruta_modelo: tiene AnimationPlayer y esqueleto")
	if g.anim == null:
		return
	_ok(_clip(g) == "reposo", "empieza en reposo")
	for c in g.anim.get_animation_list():
		var bucle: bool = g.anim.get_animation(c).loop_mode != Animation.LOOP_NONE
		_ok(bucle == (String(c) in BUCLES), "%s: %s" % [c, "en bucle" if bucle else "una vez"])
	var yaw := rad_to_deg(g.pivote.rotation.y)
	_ok(absf(yaw - rad_to_deg(atan2(0.8, 0.6))) < 0.5, "mira a los héroes como los enemigos 3D (giro %.1f°)" % yaw)
	_ok(float(g.get("ALTURA")) >= 3.5, "ALTURA para la invocación de Érebo: %s m (≥ 3,5)" % str(g.get("ALTURA")))
	_ok(not g.has_method("avisar"), "sin avisar(): combate.gd no lo lleva por el camino de Zarzalín")
	_ok(g.has_method("despertar"), "con despertar(): combate.gd lo lleva por _anim_guardian (ataca desde su sitio)")
	for m in ["reposo", "andar", "correr", "herida", "recibir_golpe", "morir", "derrota", "cansada", "mirar",
			"mirar_frente", "victoria", "revivir", "entrada", "lanzar_magia", "punto_magia", "fin_magia",
			"preparar_golpe", "golpear", "fin_golpe", "atacar", "ataque", "cargar", "golpe_fuerte", "fase2",
			"poner_fase", "en_fase2", "dormir", "despertar", "alcance", "tiempo_impacto", "duracion", "play",
			"corazon", "nucleo", "punta_rama", "puno", "senalar_grietas", "punto_vulnerable"]:
		_ok(g.has_method(m), "tiene " + m + "()")
	await _esperar(10)
	_ok(_escala_hueso(g, "grietas") < 0.05, "fase 1: las grietas vulnerables no brillan (escala %.2f)" % _escala_hueso(g, "grietas"))
	_ok(_escala_hueso(g, "musgo") < 0.05, "en reposo, sin musgo")
	_ok(_apertura(g) < 0.01, "fase 1: las placas cerradas (%.3f m)" % _apertura(g))
	var nucleo: Vector3 = g.nucleo()
	_ok(nucleo.y > 2.4 and nucleo.y < 3.1, "el núcleo a %.2f m del suelo" % nucleo.y)
	var al: float = g.alcance("ataque")
	_ok(al > 1.5 and al < 3.2, "el puñetazo llega %.2f m por delante en el impacto" % al)
	var puno_y: float = g._punta_en("ataque", 18.0 / 30.0).y
	_ok(puno_y > 0.6 and puno_y < 2.2, "y a la altura de un héroe (%.2f m)" % puno_y)
	var ar: float = g.alcance("puno_al_suelo")
	_ok(ar > 1.2 and ar < 2.5, "el puño toca el suelo a %.2f m por delante (alias «puno_al_suelo»)" % ar)
	var luz0: float = g.energia_runas()
	_ok(luz0 > 0.8 and luz0 < 1.4, "runas en reposo: %.2f" % luz0)
	# señalar las grietas en la fase 1
	g.senalar_grietas(true)
	await _esperar(15)
	_ok(_escala_hueso(g, "grietas") > 0.95 and g.grietas_visibles(), "señaladas, las grietas brillan (%.2f)" % _escala_hueso(g, "grietas"))
	var pv: Vector3 = g.punto_vulnerable()
	var pe: Vector3 = g.punto_vulnerable(true)
	_ok(pv.y > 2.2 and pe.y > 2.2 and pv.distance_to(pe) > 0.8, "las grietas del pecho y la espalda, a los dos lados (%.2f m)" % pv.distance_to(pe))
	g.senalar_grietas(false)
	await _esperar(15)
	_ok(_escala_hueso(g, "grietas") < 0.05, "y se apagan al dejar de señalarlas")

	# puñetazo
	await _ataque(g, "ataque", 18.0 / 30.0, "puñetazo desde el reposo")
	# carga: aviso una vez; un golpe recibido vuelve a la carga; las runas laten
	registro.clear()
	var f0 := Engine.get_process_frames()
	g.cargar()
	var luz_max := 0.0
	for i in 40:
		await process_frame
		luz_max = maxf(luz_max, g.energia_runas())
	_ok(_veces("aviso") == 1, "cargar(): señal aviso una vez (%d)" % _veces("aviso"))
	if _veces("aviso") == 1:
		var t: float = (registro["aviso"][0][0] - f0) * DT
		_ok(t <= 0.3, "aviso en el primer latido: %.3f s" % t)
	_ok(_clip(g) == "carga" and g.anim.get_animation("carga").loop_mode == Animation.LOOP_LINEAR, "se queda en la carga (bucle)")
	_ok(luz_max > 1.6, "las runas laten: suben a %.2f" % luz_max)
	g.recibir_golpe()
	await _esperar(3)
	_ok(_clip(g) == "herido", "en carga, un golpe recibido reacciona")
	await _esperar(30)
	_ok(_clip(g) == "carga", "y vuelve a la carga: " + _clip(g))
	await _ataque(g, "golpe_fuerte", 20.0 / 30.0, "golpe fuerte desde la carga")
	# un golpe a mitad del puñetazo no lo corta
	registro.clear()
	var llamadas := [0]
	var fin := [false]
	var tarea := func():
		await g.atacar("punetazo", func(): llamadas[0] += 1)
		fin[0] = true
	tarea.call()
	await _esperar(5)
	g.recibir_golpe()
	await _esperar(2)
	_ok(_clip(g) == "ataque", "atacando, un golpe recibido no corta el puñetazo (alias «punetazo»)")
	while not fin[0]:
		await process_frame
	_ok(_veces("impacto") == 1 and llamadas[0] == 1, "y su impacto sale una vez (%d, %d)" % [_veces("impacto"), llamadas[0]])
	await _esperar(12)
	# fase 2
	registro.clear()
	f0 = Engine.get_process_frames()
	var hecho := [false]
	var t2 := func():
		await g.fase2()
		hecho[0] = true
	t2.call()
	await _esperar(5)
	_ok(_escala_hueso(g, "grietas") < 0.1 and _apertura(g) < 0.05, "fase2 empieza con las grietas apagadas y las placas cerradas")
	g.recibir_golpe()
	await _esperar(2)
	_ok(_clip(g) == "fase2", "un golpe no interrumpe la transformación")
	var luz_f2 := 0.0
	while not hecho[0] and Engine.get_process_frames() - f0 < 150:
		await process_frame
		luz_f2 = maxf(luz_f2, g.energia_runas())
	_ok(hecho[0], "fase2 termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	_ok(_veces("placas_abiertas") == 1 and _veces("coraza_desplegada") == 1, "señales placas_abiertas y coraza_desplegada una vez (%d, %d)" % [_veces("placas_abiertas"), _veces("coraza_desplegada")])
	if _veces("placas_abiertas") == 1:
		var tc: float = (registro["placas_abiertas"][0][0] - f0) * DT
		_ok(absf(tc - 31.0 / 30.0) <= TOL + DT, "las placas saltan a %.3f s (ancla 1,033)" % tc)
	_ok(luz_f2 > 2.2, "en la transformación las runas arden: %.2f" % luz_f2)
	_ok(g.en_fase2() and g.fase == 2, "queda en la fase 2")
	await _esperar(12)
	_ok(_clip(g) == "reposo", "y en reposo: " + _clip(g))
	_ok(_apertura(g) > 0.2, "con las placas abiertas (%.2f m)" % _apertura(g))
	_ok(_escala_hueso(g, "grietas") > 0.95, "y las grietas encendidas (%.2f)" % _escala_hueso(g, "grietas"))
	_ok(g.energia_runas() > 1.15, "las runas, más fuertes que en la fase 1 (%.2f)" % g.energia_runas())
	await _ataque(g, "ataque", 18.0 / 30.0, "puñetazo en la fase 2")
	_ok(_apertura(g) > 0.2, "las placas siguen abiertas tras atacar (%.2f m)" % _apertura(g))
	# magia: nace en el núcleo
	await g.lanzar_magia()
	var pm: Vector3 = g.punto_magia()
	_ok(pm.distance_to(g.nucleo()) < 0.01 and pm.y > 2.0, "la magia nace en el núcleo (%.2f m de alto)" % pm.y)
	g.fin_magia()
	await _esperar(12)
	g.correr()
	await _esperar(3)
	_ok(_clip(g) == "reposo", "correr(): el Coloso no corre, sigue en reposo")
	# derrota
	registro.clear()
	f0 = Engine.get_process_frames()
	g.morir()
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 150:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "derrota", "derrota termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	await _esperar(5)
	var cadera: Vector3 = g.skel.get_bone_global_pose(g.skel.find_bone("cadera")).origin
	_ok(cadera.y < 1.2, "queda de rodillas (cadera a %.2f m)" % cadera.y)
	_ok(_escala_hueso(g, "grietas_derrota") > 0.95, "agrietado")
	_ok(g.energia_runas() < 0.2, "con las runas apagadas (%.2f)" % g.energia_runas())
	registro.clear()
	g.herida()
	g.atacar("ataque")
	g.cargar()
	await _esperar(30)
	_ok(_veces("impacto") == 0 and _veces("aviso") == 0 and _clip(g) in ["derrota", ""],
		"derrotado ya no ataca ni avisa (impactos %d, avisos %d, clip «%s»)" % [_veces("impacto"), _veces("aviso"), _clip(g)])
	g.revivir()
	await _esperar(12)
	_ok(_clip(g) == "reposo", "revivir vuelve al reposo")
	# dormido y despertar
	g.poner_fase(1)
	g.dormir()
	await _esperar(20)
	_ok(_clip(g) == "dormido" and g.anim.get_animation("dormido").loop_mode == Animation.LOOP_LINEAR, "dormir(): dormido en bucle")
	_ok(_escala_hueso(g, "musgo") > 0.95, "con musgo de estatua")
	cadera = g.skel.get_bone_global_pose(g.skel.find_bone("cadera")).origin
	_ok(cadera.y > 1.5, "de pie, como una estatua (cadera a %.2f m)" % cadera.y)
	_ok(g.energia_runas() < 0.35, "las runas casi apagadas (%.2f)" % g.energia_runas())
	registro.clear()
	f0 = Engine.get_process_frames()
	g.entrada()
	while _veces("clip_terminado") < 2 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	var nombres_fin: Array = registro.get("clip_terminado", []).map(func(r): return r[2])
	_ok(nombres_fin == ["despertar", "entrada"], "entrada(): despierta y avisa (%s, %.2f s)" % [str(nombres_fin), (Engine.get_process_frames() - f0) * DT])
	_ok(_clip(g) == "reposo" and _escala_hueso(g, "musgo") < 0.05, "despierto, sin musgo")
	_ok(g.energia_runas() > 0.8, "y con las runas encendidas (%.2f)" % g.energia_runas())
	g.queue_free()
	# el modelo dormido tal cual, sin guion (para la región)
	var n: Node = (load(GLB) as PackedScene).instantiate()
	root.add_child(n)
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	ap.play("dormido")
	await _esperar(5)
	_ok(sk.get_bone_pose_scale(sk.find_bone("grietas")).x < 0.05 and sk.get_bone_pose_scale(sk.find_bone("musgo")).x > 0.95,
		"el GLB solo, con «dormido»: sin brillo en las grietas y con el musgo (para la región)")
	n.queue_free()
	await _esperar(2)


# Lanza un ataque y comprueba un impacto, una llamada, su ancla y la vuelta al reposo.
func _ataque(g: Node3D, ataque: String, ancla: float, texto: String) -> void:
	registro.clear()
	var llamadas := [0]
	var f0 := Engine.get_process_frames()
	await g.atacar(ataque, func(): llamadas[0] += 1)
	var dur := (Engine.get_process_frames() - f0) * DT
	_ok(_veces("impacto") == 1 and llamadas[0] == 1, "%s: un impacto (%d) y una llamada (%d)" % [texto, _veces("impacto"), llamadas[0]])
	if _veces("impacto") == 1:
		var pos: float = registro["impacto"][0][1]
		_ok(absf(pos - ancla) <= DT * 0.5 + 0.001, "%s: impacto en el clip a %.3f s (ancla %.3f)" % [texto, pos, ancla])
	_ok(_veces("ataque_terminado") == 1, "%s: ataque_terminado (%.2f s)" % [texto, dur])
	await _esperar(12)
	_ok(_clip(g) == "reposo", "%s: vuelve al reposo (%s)" % [texto, _clip(g)])


# ---------------------------------------------------------------- encuadre para MODELOS de combate.gd

# La misma cámara que _crear_rig_3d (ortográfica, 12° desde arriba). Cada clip, cada 0,1 s, con el Coloso girado hacia
# los héroes: los puntos extremos (nudillos, placas, cabeza, monolitos, pies, lascas y rocas) caen dentro de la ventana.
func _encuadre() -> void:
	var vp := SubViewport.new()
	vp.size = VP
	vp.own_world_3d = true
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ALTO_VISTA
	vp.add_child(cam)
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, CENTRO_Y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, CENTRO_Y, 0))
	var g: Node3D = load(GUION).new()
	g.ruta_modelo = GLB
	vp.add_child(g)
	await _esperar(3)
	var sk: Skeleton3D = g.skel
	# puntos: [hueso, largo por su eje y, margen en metros]
	var puntos := [["mano.R", 0.35, 0.45], ["mano.L", 0.35, 0.45], ["placa_hombro.R", 0.15, 0.6],
		["placa_hombro.L", 0.15, 0.6], ["placa_antebrazo.R", 0.0, 0.5], ["placa_antebrazo.L", 0.0, 0.5],
		["cabeza", 0.55, 0.3], ["pecho", 1.25, 0.25], ["pie.R", 0.5, 0.2], ["pie.L", 0.5, 0.2],
		["rocas", 0.6, 0.6], ["proyectiles", 0.0, 0.3]]
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	var peor := {}
	for c in CLIPS:
		g._clip = c
		g._eventos = []
		g.fase = 2 if c == "fase2" else 1
		g.anim.play(c, 0.0)
		g.anim.speed_scale = 0.0
		var largo: float = g.anim.get_animation(c).length
		var t := 0.0
		while t <= largo + 0.001:
			g.anim.seek(t, true)
			g.anim.advance(0.0)
			for p in puntos:
				var i := sk.find_bone(p[0])
				if sk.get_bone_pose_scale(i).x < 0.5:
					continue
				var tr := sk.global_transform * sk.get_bone_global_pose(i)
				var w: Vector3 = tr.origin + tr.basis.y.normalized() * p[1]
				var s := cam.unproject_position(w)
				var m: float = p[2] * VP.y / ALTO_VISTA
				for e in [s - Vector2(m, m), s + Vector2(m, m)]:
					if e.x < mn.x or e.y < mn.y or e.x > mx.x or e.y > mx.y:
						peor["%s %.1f s %s" % [c, t, p[0]]] = e
					mn = Vector2(minf(mn.x, e.x), minf(mn.y, e.y))
					mx = Vector2(maxf(mx.x, e.x), maxf(mx.y, e.y))
			t += 0.1
	var pies := cam.unproject_position(Vector3.ZERO)
	var alto := cam.unproject_position(Vector3(0, 4.16, 0))
	var px_m := VP.y / ALTO_VISTA * ESC
	print("  encuadre vp %s, alto_vista %.2f, centro_y %.2f, esc %.2f: %.1f px por metro en la escena" % [VP, ALTO_VISTA, CENTRO_Y, ESC, px_m])
	print("    lo que ocupa en todos los clips (px de la ventana 3D, con margen): x %.0f…%.0f, y %.0f…%.0f" % [mn.x, mx.x, mn.y, mx.y])
	print("    pies y=%.0f, alto (4,16 m) y=%.0f" % [pies.y, alto.y])
	print("    en la escena (×esc, desde el origen del rig): pies %.0f, alto %.0f → barra_y propuesta %.0f" % [pies.y * ESC, alto.y * ESC, alto.y * ESC - 30.0])
	for k in peor:
		var e: Vector2 = peor[k]
		if e.x < 0.0 or e.y < 0.0 or e.x > VP.x or e.y > VP.y:
			print("    fuera de la ventana: %s en %s" % [k, e])
	_ok(mn.x >= 0.0 and mx.x <= VP.x and mn.y >= 0.0 and mx.y <= VP.y, "el Coloso cabe en la ventana 3D en todos los clips")
	_ok(px_m > 130.0 and px_m < 190.0, "escala en la escena %.0f px/m (Kael: 179 px/m; 4,16 m → %.0f px)" % [px_m, px_m * 4.16])
	vp.queue_free()
	await _esperar(2)
