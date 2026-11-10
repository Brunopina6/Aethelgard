extends SceneTree
# Prueba del Guardián del Bosque Olvidado (fase 3): el modelo hecho con Blender, sus clips, su presupuesto móvil y su
# guion de combate (enemigos/guardian_bosque/guardian_bosque_3d.gd), creado con .new() como en combate.gd.
#   sin ventana:  --headless --script res://pruebas/prueba_guardian_modelo.gd --fixed-fps 30
# Comprueba (y acaba con «FALLOS: n»):
#  - el GLB importado trae los 8 clips (reposo, ataque, carga, golpe_fuerte, herido, fase2, derrota, dormido); cada
#    clip escribe todos los huesos; con el guion, en bucle solo reposo, carga y dormido (como zarzalin_3d.gd, el bucle
#    lo pone el guion: el .import queda sin subrecursos)
#  - presupuesto: ≤ 12 000 triángulos, ≤ 30 huesos, ≤ 2 materiales (corteza con colores de vértice y luz emisiva),
#    sin texturas
#  - los bucles cierran sin salto; ataque, golpe_fuerte, herido y fase2 acaban en la pose del reposo
#  - piezas escondidas por escala: musgo solo en dormido, raíces del suelo solo en golpe_fuerte, coraza fuera de dormido
#  - el guion: empieza en reposo y mira a los héroes; en la fase 1 la coraza queda escondida; el latigazo y el golpe
#    fuerte (tras cargar) dan su impacto UNA vez y en su ancla (0,6 s y 0,667 s); cargar avisa una vez; un golpe
#    recibido reacciona y vuelve a la carga; fase2 despliega la coraza (señal) y la deja; la luz del corazón late;
#    derrota se queda de rodillas y ya no ataca; dormir/despertar; alcance; ALTURA para Érebo
#  - el encuadre propuesto para MODELOS de combate.gd (misma cámara que _crear_rig_3d): dónde caen los pies, el
#    corazón y la copa, y la barra de vida que se propone

const GLB := "res://enemigos/guardian_bosque/guardian_bosque.glb"
const GUION := "res://enemigos/guardian_bosque/guardian_bosque_3d.gd"
const CLIPS := ["reposo", "ataque", "carga", "golpe_fuerte", "herido", "fase2", "derrota", "dormido"]
const BUCLES := ["reposo", "carga", "dormido"]
const MAX_TRIANGULOS := 12000
const MAX_HUESOS := 30
const TOL := 0.05
const DT := 1.0 / 30.0
# Encuadre propuesto (MODELOS["guardian_bosque"])
const VP := Vector2i(1000, 1120)
const ALTO_VISTA := 4.6
const CENTRO_Y := 1.95
const ESC := 0.6

var fallos := 0
var registro := {}
var fotos := ""                        # con ventana: carpeta de las capturas (prueba_guardian_fotos.gd o «fotos=…»)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
	_correr.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + texto)
	if not cond:
		fallos += 1


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	print("== Guardián del Bosque: modelo, clips y guion")
	await _comprobar_glb()
	await _comprobar_guion()
	_encuadre()
	if fotos != "":
		await _capturas()
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
	_ok(sk.get_bone_count() <= MAX_HUESOS, "huesos: %d (máximo %d)" % [sk.get_bone_count(), MAX_HUESOS])
	for c in lista:
		var a := ap.get_animation(c)
		print("  %s: %.3f s, %d pistas (bucle al importar: %d; lo pone el guion)" % [c, a.length, a.get_track_count(), a.loop_mode])
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
	_ok(tris > 3000 and tris <= MAX_TRIANGULOS, "triángulos: %d (máximo %d)" % [tris, MAX_TRIANGULOS])
	_ok(superficies <= 2 and mats.size() <= 2, "materiales: %d en %d superficies (%s)" % [mats.size(), superficies, ", ".join(mats.keys())])
	_ok(texturas == 0, "sin texturas (colores de vértice): %d" % texturas)
	var corteza: StandardMaterial3D = mats.get("corteza")
	var luz: StandardMaterial3D = mats.get("luz")
	_ok(corteza != null and corteza.vertex_color_use_as_albedo, "corteza: color de los vértices como albedo")
	_ok(luz != null and luz.emission_enabled, "luz: emisiva (corazón, ojos y venas)")
	for m in mats.values():
		_ok(m.cull_mode == BaseMaterial3D.CULL_BACK, "%s: una cara (cull back; las hojas tienen sus dos caras)" % m.resource_name)
	# color de los vértices: el de la luz es (0,8; 1; 0,45) en sRGB, (0,61; 1; 0,17) en lineal. El material debe leerlo
	# en el espacio en que lo guarda la importación.
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		for i in m.get_surface_count():
			var mat := (mi as MeshInstance3D).get_active_material(i) as StandardMaterial3D
			if mat == null or mat.resource_name != "luz":
				continue
			var cols: PackedColorArray = m.surface_get_arrays(i)[Mesh.ARRAY_COLOR]
			if cols.is_empty():
				continue
			var c: Color = cols[0]
			var en_srgb := absf(c.r - 0.8) < 0.05
			print("  color de vértice de la luz importado: ", c, " (", "sRGB" if en_srgb else "lineal", ")")
			if corteza != null:
				_ok(corteza.vertex_color_is_srgb == en_srgb, "corteza lee los colores de vértice en su espacio (vertex_color_is_srgb=%s)" % corteza.vertex_color_is_srgb)
	# bucles sin salto; los clips de acción acaban en la pose del reposo
	for c in BUCLES:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, c, 0.0)
		_ok(d.x < 0.5 and d.y < 0.003, "%s cierra el bucle sin salto (%.2f°, %.4f m)" % [c, d.x, d.y])
	for c in ["ataque", "golpe_fuerte", "herido", "fase2"]:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, "reposo", 0.0)
		_ok(d.x < 1.0 and d.y < 0.005, "%s acaba en la pose del reposo (giro %.2f°, posición %.4f m)" % [c, d.x, d.y])
	var dc := _diferencia_pose(ap, sk, "golpe_fuerte", 0.0, "carga", 0.0)
	_ok(dc.x < 1.0 and dc.y < 0.005, "golpe_fuerte empieza en la pose de la carga (%.2f°, %.4f m)" % [dc.x, dc.y])
	# piezas escondidas por la escala de su hueso
	for c in lista:
		var a := ap.get_animation(c)
		var musgo := _escala_max(a, sk, "musgo")
		var raices := _escala_max(a, sk, "raices_suelo")
		var coraza := _escala_max(a, sk, "coraza")
		_ok((musgo > 0.9) == (c == "dormido"), "%s: musgo del sueño %s (escala máx. %.2f)" % [c, "visible" if musgo > 0.9 else "escondido", musgo])
		_ok((raices > 0.9) == (c == "golpe_fuerte"), "%s: raíces del suelo %s (%.2f)" % [c, "brotan" if raices > 0.9 else "escondidas", raices])
		_ok((coraza < 0.05) == (c == "dormido"), "%s: coraza en el clip %.2f (la fase 1 la esconde el guion)" % [c, coraza])
	n.queue_free()
	await _esperar(2)


func _escala_max(a: Animation, sk: Skeleton3D, hueso: String) -> float:
	var mx := 0.0
	for k in a.get_track_count():
		if a.track_get_type(k) == Animation.TYPE_SCALE_3D and String(a.track_get_path(k)).ends_with(":" + hueso):
			var t := 0.0
			while t <= a.length + 0.001:
				mx = maxf(mx, a.scale_track_interpolate(k, t).x)
				t += DT
			return mx
	return 1.0


func _diferencia_pose(ap: AnimationPlayer, sk: Skeleton3D, c1: String, t1: float, c2: String, t2: float) -> Vector2:
	var a1 := ap.get_animation(c1)
	var a2 := ap.get_animation(c2)
	var giro := 0.0
	var mov := 0.0
	for i in sk.get_bone_count():
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
	_ok(is_equal_approx(float(g.get("ALTURA")), 3.75), "ALTURA para la invocación de Érebo: %s m" % str(g.get("ALTURA")))
	_ok(not g.has_method("avisar"), "sin avisar(): combate.gd no lo lleva por el camino de Zarzalín")
	for m in ["reposo", "correr", "herida", "morir", "cansada", "mirar", "mirar_frente", "victoria", "revivir",
			"entrada", "lanzar_magia", "punto_magia", "fin_magia", "preparar_golpe", "golpear", "fin_golpe",
			"atacar", "ataque", "cargar", "golpe_fuerte", "fase2", "dormir", "despertar", "alcance"]:
		_ok(g.has_method(m), "tiene " + m + "()")
	_ok(_escala_hueso(g, "coraza") < 0.05 and _escala_hueso(g, "coraza.R") < 0.05,
		"fase 1: la coraza, escondida (escala %.2f)" % _escala_hueso(g, "coraza"))
	_ok(_escala_hueso(g, "musgo") < 0.05, "en reposo, sin el musgo del sueño")
	var corazon: Vector3 = g.corazon()
	_ok(corazon.y > 1.8 and corazon.y < 2.3, "el corazón a %.2f m del suelo" % corazon.y)
	var al: float = g.alcance("ataque")
	_ok(al > 1.6 and al < 3.0, "el latigazo llega %.2f m por delante en el impacto" % al)
	_ok(is_equal_approx(g.alcance("raices"), 1.7), "las raíces brotan a %.2f m (alias «raices»)" % g.alcance("raices"))
	# luz en reposo
	var luz0: float = g._luz.emission_energy_multiplier if g._luz != null else -1.0
	_ok(luz0 > 0.8 and luz0 < 1.4, "luz del corazón en reposo: %.2f" % luz0)

	# latigazo
	await _ataque(g, "ataque", 18.0 / 30.0, "latigazo desde el reposo")
	# carga: aviso una vez; un golpe recibido vuelve a la carga; la luz late
	registro.clear()
	var f0 := Engine.get_process_frames()
	g.cargar()
	var luz_max := 0.0
	for i in 40:
		await process_frame
		luz_max = maxf(luz_max, g._luz.emission_energy_multiplier)
	_ok(_veces("aviso") == 1, "cargar(): señal aviso una vez (%d)" % _veces("aviso"))
	if _veces("aviso") == 1:
		var t: float = (registro["aviso"][0][0] - f0) * DT
		_ok(t <= 0.3, "aviso en el primer latido: %.3f s" % t)
	_ok(_clip(g) == "carga" and g.anim.get_animation("carga").loop_mode == Animation.LOOP_LINEAR, "se queda en la carga (bucle)")
	_ok(luz_max > 1.4, "el corazón late: la luz sube a %.2f" % luz_max)
	g.recibir_golpe()
	await _esperar(3)
	_ok(_clip(g) == "herido", "en carga, un golpe recibido reacciona")
	await _esperar(30)
	_ok(_clip(g) == "carga", "y vuelve a la carga: " + _clip(g))
	await _ataque(g, "golpe_fuerte", 20.0 / 30.0, "golpe fuerte desde la carga")
	# un golpe a mitad del latigazo no lo corta
	registro.clear()
	var llamadas := [0]
	var fin := [false]
	var tarea := func():
		await g.atacar("latigazo", func(): llamadas[0] += 1)
		fin[0] = true
	tarea.call()
	await _esperar(5)
	g.recibir_golpe()
	await _esperar(2)
	_ok(_clip(g) == "ataque", "atacando, un golpe recibido no corta el latigazo (alias «latigazo»)")
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
	_ok(_escala_hueso(g, "coraza") < 0.1, "fase2 empieza con la coraza escondida (%.2f)" % _escala_hueso(g, "coraza"))
	g.recibir_golpe()
	await _esperar(2)
	_ok(_clip(g) == "fase2", "un golpe no interrumpe la transformación")
	var luz_f2 := 0.0
	while not hecho[0] and Engine.get_process_frames() - f0 < 150:
		await process_frame
		luz_f2 = maxf(luz_f2, g._luz.emission_energy_multiplier)
	_ok(hecho[0], "fase2 termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	_ok(_veces("coraza_desplegada") == 1, "señal coraza_desplegada una vez (%d)" % _veces("coraza_desplegada"))
	if _veces("coraza_desplegada") == 1:
		var tc: float = (registro["coraza_desplegada"][0][0] - f0) * DT
		_ok(absf(tc - 28.0 / 30.0) <= TOL + DT, "la coraza se despliega a %.3f s (ancla 0,933)" % tc)
	_ok(luz_f2 > 1.9, "en la transformación el corazón brilla más: %.2f" % luz_f2)
	_ok(g.en_fase2() and g.fase == 2, "queda en la fase 2")
	await _esperar(12)
	_ok(_clip(g) == "reposo", "y en reposo: " + _clip(g))
	_ok(_escala_hueso(g, "coraza") > 0.95 and _escala_hueso(g, "coraza.L") > 0.95, "con la coraza puesta (%.2f)" % _escala_hueso(g, "coraza"))
	await _ataque(g, "ataque", 18.0 / 30.0, "latigazo en la fase 2")
	_ok(_escala_hueso(g, "coraza") > 0.95, "la coraza sigue tras atacar")
	# magia (esporas): nace en el corazón
	await g.lanzar_magia()
	var pm: Vector3 = g.punto_magia()
	_ok(pm.distance_to(g.corazon()) < 0.01 and pm.y > 1.5, "la magia nace en el corazón (%.2f m de alto)" % pm.y)
	g.fin_magia()
	await _esperar(12)
	# correr: no corre, sigue en reposo
	g.correr()
	await _esperar(3)
	_ok(_clip(g) == "reposo", "correr(): el Guardián no corre, sigue en reposo")
	# derrota
	registro.clear()
	f0 = Engine.get_process_frames()
	g.morir()
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 150:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "derrota", "derrota termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	await _esperar(5)
	var cadera: Vector3 = g.skel.get_bone_global_pose(g.skel.find_bone("cadera")).origin
	_ok(cadera.y < 0.85, "queda de rodillas (cadera a %.2f m)" % cadera.y)
	_ok(g._luz.emission_energy_multiplier < 0.6, "con el corazón casi apagado (%.2f)" % g._luz.emission_energy_multiplier)
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
	g.dormir()
	await _esperar(10)
	_ok(_clip(g) == "dormido" and g.anim.get_animation("dormido").loop_mode == Animation.LOOP_LINEAR, "dormir(): dormido en bucle")
	_ok(_escala_hueso(g, "musgo") > 0.95 and _escala_hueso(g, "musgo_suelo") > 0.95, "cubierto de musgo")
	cadera = g.skel.get_bone_global_pose(g.skel.find_bone("cadera")).origin
	_ok(cadera.y < 0.85, "arrodillado (cadera a %.2f m)" % cadera.y)
	registro.clear()
	f0 = Engine.get_process_frames()
	g.entrada()
	while _veces("clip_terminado") < 2 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	var nombres_fin: Array = registro.get("clip_terminado", []).map(func(r): return r[2])
	_ok(nombres_fin == ["despertar", "entrada"], "entrada(): despierta y avisa (%s, %.2f s)" % [str(nombres_fin), (Engine.get_process_frames() - f0) * DT])
	_ok(_clip(g) == "reposo" and _escala_hueso(g, "musgo") < 0.05, "de pie y sin musgo")
	g.queue_free()
	# el modelo dormido tal cual, sin guion (para la región)
	var n: Node = (load(GLB) as PackedScene).instantiate()
	root.add_child(n)
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	ap.play("dormido")
	await _esperar(5)
	_ok(sk.get_bone_pose_scale(sk.find_bone("coraza")).x < 0.05 and sk.get_bone_pose_scale(sk.find_bone("musgo")).x > 0.95,
		"el GLB solo, con «dormido»: sin coraza y con el musgo (para la región)")
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
	var pies := cam.unproject_position(Vector3.ZERO)
	var copa := cam.unproject_position(Vector3(0, 3.75, 0))
	var brazos_alto := cam.unproject_position(Vector3(0, 4.15, 0))
	var corazon := cam.unproject_position(Vector3(0, 2.06, 0))
	var px_m := VP.y / ALTO_VISTA * ESC
	print("  encuadre vp %s, alto_vista %.2f, centro_y %.2f, esc %.2f: %.1f px por metro en la escena" % [VP, ALTO_VISTA, CENTRO_Y, ESC, px_m])
	print("    pies y=%.0f, corazón y=%.0f, copa y=%.0f, brazos en alto y=%.0f (px de la ventana 3D)" % [pies.y, corazon.y, copa.y, brazos_alto.y])
	print("    en la escena (×esc, desde el origen del rig): pies %.0f, copa %.0f → barra_y propuesta %.0f" % [pies.y * ESC, copa.y * ESC, copa.y * ESC - 30.0])
	_ok(brazos_alto.y > 0.0 and pies.y < VP.y, "el Guardián cabe en la ventana 3D (brazos en alto y pies)")
	_ok(px_m > 130.0 and px_m < 190.0, "escala en la escena %.0f px/m (Kael: 179 px/m; 3,75 m → %.0f px)" % [px_m, px_m * 3.75])
	vp.queue_free()


# ---------------------------------------------------------------- capturas en un combate de verdad (con ventana)

# El Guardián en combate.tscn (grupo 9: Grimfang solo), en la ventana 3D de Grimfang con el encuadre propuesto y los
# pies donde estaban los de Grimfang; los héroes al lado dan la escala. Cada clip en su momento clave.
func _capturas() -> void:
	DirAccess.make_dir_recursive_absolute(fotos)
	Engine.set_meta("grupo_combate", 9)
	var c: Node = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(20)
	c.estado = "fin"                                  # sin turnos: solo se miran los clips
	await _esperar(5)
	await _foto("00_grimfang_antes")
	var e: Dictionary = c.enemigos[0]
	var g := _poner_en_combate(c, e)
	await _esperar(20)
	await _foto("01_reposo_junto_a_los_heroes")
	# cada clip, parado en su momento (el reloj del juego no corre igual con ventana: se pone la pose exacta)
	for f in [["02_ataque_alza_la_rama", "ataque", 10, 1], ["03_ataque_impacto", "ataque", 18, 1],
			["04_carga_latido", "carga", 4, 1], ["05_golpe_fuerte_se_yergue", "golpe_fuerte", 11, 1],
			["06_golpe_fuerte_impacto", "golpe_fuerte", 20, 1], ["07_golpe_fuerte_raices", "golpe_fuerte", 23, 1],
			["08_herido", "herido", 3, 1], ["09_fase2_se_recoge", "fase2", 13, 2], ["10_fase2_se_yergue", "fase2", 31, 2],
			["11_fase2_coraza", "fase2", 37, 2], ["12_reposo_fase2", "reposo", 0, 2], ["13_derrota", "derrota", 71, 2],
			["14_dormido", "dormido", 0, 1]]:
		await _pose(g, f[1], f[2] / 30.0, f[3])
		await _foto(f[0])
	# el despertar, en marcha (de dormido al reposo)
	g.anim.speed_scale = 1.0
	g.fase = 1
	g.dormir()
	await _esperar(5)
	g.entrada()
	await _esperar(20)
	await _foto("15_despertar")
	await _esperar(40)
	c.queue_free()
	await _esperar(5)


# Para el modelo en un instante de un clip (sin mezcla), con la fase dada (la coraza la esconde el guion en la fase 1).
func _pose(g: Node3D, clip: String, t: float, fase_g: int) -> void:
	g.fase = fase_g
	g._clip = clip
	g._eventos = []
	g.anim.speed_scale = 1.0
	g.anim.play(clip, 0.0)
	g.anim.seek(t, true)
	g.anim.speed_scale = 0.0
	await _esperar(3)


func _poner_en_combate(c: Node, e: Dictionary) -> Node3D:
	var viejo: Node3D = e["p3d"]
	var vp: SubViewport = viejo.get_parent()
	viejo.queue_free()
	var q: float = c.res_personajes
	var rig: Node2D = e["rig"]
	var cuerpo: Node2D = e["cuerpo"]
	var pie_antes: Vector2 = rig.position + cuerpo.position * rig.scale
	vp.size = Vector2i(int(VP.x * q), int(VP.y * q))
	var cam: Camera3D = e["cam3d"]
	cam.size = ALTO_VISTA
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, CENTRO_Y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, CENTRO_Y, 0))
	var g: Node3D = load(GUION).new()
	g.ruta_modelo = GLB
	vp.add_child(g)
	rig.scale = Vector2(ESC, ESC)
	cuerpo.position = cam.unproject_position(Vector3.ZERO) / q
	var spr: Sprite2D = e["partes"]["sprite"]
	spr.position = -cuerpo.position
	spr.scale = Vector2.ONE / q
	spr.modulate = Color.WHITE
	rig.position = pie_antes - cuerpo.position * ESC
	e["rig_base"] = rig.position
	e["pos"] = rig.position
	e["pie"] = cuerpo.position
	e["p3d"] = g
	e["centro_ofs"] = cam.unproject_position(Vector3(0, 1.9, 0)) / q * ESC
	var arriba: Vector2 = c._a_pantalla(rig.position + cam.unproject_position(Vector3(0, 3.75, 0)) / q * ESC)
	if e.has("barra_hp"):
		e["barra_hp"].position = arriba + Vector2(-60, -10)
		e["lbl_hp"].position = arriba + Vector2(-60, -38)
		e["lbl_estado"].position = arriba + Vector2(-60, -66)
	e["nombre"] = "Guardián del Bosque"
	c._actualizar()
	print("  en combate: pies del Guardián en %s (los de Grimfang), rig en %s; vp %s" % [pie_antes, rig.position, vp.size])
	return g


func _foto(nombre: String) -> void:
	var dibujado: bool = await _esperar_dibujo()
	if not dibujado:
		print("  AVISO: la ventana no dibuja (¿minimizada?); la captura %s puede salir vacía" % nombre)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [fotos, nombre])
	print("  captura ", nombre)


func _esperar_dibujo() -> bool:
	var dibujado := [false]
	var al_dibujar := func(): dibujado[0] = true
	RenderingServer.frame_post_draw.connect(al_dibujar, CONNECT_ONE_SHOT)
	var n := 0
	while not dibujado[0] and n < 10:
		await process_frame
		n += 1
	if RenderingServer.frame_post_draw.is_connected(al_dibujar):
		RenderingServer.frame_post_draw.disconnect(al_dibujar)
	return dibujado[0]
