extends SceneTree
# Prueba de Cencerrante (T-097, segunda bestia del bestiario): el modelo, sus clips y sus anclas de tiempo; con
# «fotos=<carpeta>» (y ventana), además, capturas con la cámara del combate y la comparación de texturas.
#   sin ventana:  --headless --script res://pruebas/prueba_cencerrante_modelo.gd --fixed-fps 30
#   con capturas: --script res://pruebas/prueba_cencerrante_modelo.gd --fixed-fps 30 -- fotos=<carpeta>
#   (prueba_cencerrante_fotos.gd es esta misma con la carpeta que le da ejecutar_pruebas.ps1 -Manual)
# Comprueba (y acaba con «FALLOS: n»):
#  - el GLB importado trae los 4 clips del usuario y los 3 nuevos; en la escena, en bucle solo reposo y correr; cada clip
#    gira los 9 huesos (no se queda nada de un clip anterior, como la caída de la derrota)
#  - la campanada, el toque, el golpe y la entrada acaban en la pose del reposo, y los bucles cierran sin salto
#  - material de Compatibility y texturas 2048 × 2048: normales y rugosidad comprimidas para la GPU; el color, como diga
#    COLOR_COMPRIMIDO (la comparación de las capturas lo justifica)
#  - la señal impacto sale UNA vez por ataque y en su ancla (campanada_baja, 0,533 s), también con pausa y si recibe un
#    golpe a medias; luego vuelve al reposo
#  - avisar(): la señal aviso UNA vez, en el repique del toque de alarma (0,733 s), y vuelve al reposo
#  - recibir golpe vuelve al reposo; derrota cae de espaldas, se queda quieta y no ataca ni avisa; revivir y entrada
#    acaban en reposo; el alcance de la campanada; ALTURA para Érebo; creado con .new() como en el combate

const ESCENA := "res://enemigos/cencerrante/cencerrante_3d.tscn"
const GUION := "res://enemigos/cencerrante/cencerrante_3d.gd"
const GLB := "res://enemigos/cencerrante/cencerrante_completo.glb"
const DEL_USUARIO := ["reposo", "toque_de_alarma", "campanada_baja", "recibir_golpe"]
const NUEVOS := ["derrota", "entrada", "correr"]
const BUCLES := ["reposo", "correr"]
const COLOR_COMPRIMIDO := true        # la textura de color, también comprimida (ver la comparación de las capturas)
const TOL := 0.05                     # 1,5 fotogramas a 30 fps
const DT := 1.0 / 30.0
# Encuadre de las capturas: como la cámara del combate (ortográfica, 12° desde arriba), con 2,0 m de alto de vista
const ALTO_VISTA := 2.0
const CENTRO_Y := 0.8

var fallos := 0
var fotos := ""
var registro := {}                     # señales recibidas: nombre -> [[fotograma, posición del clip, args]]


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
	print("== Cencerrante: modelo y clips")
	await _comprobar_glb()
	await _comprobar_escena()
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
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var lista := Array(ap.get_animation_list()).map(func(x): return String(x))
	print("  clips: ", lista)
	for c in DEL_USUARIO + NUEVOS:
		_ok(c in lista, "existe el clip " + c)
	for c in lista:
		var a := ap.get_animation(c)
		print("  %s: %.3f s, %d pistas" % [c, a.length, a.get_track_count()])
		var huesos := {}
		for k in a.get_track_count():
			var p := String(a.track_get_path(k))
			if a.track_get_type(k) == Animation.TYPE_ROTATION_3D and ":" in p:
				huesos[p.get_slice(":", 1)] = true
		_ok(huesos.size() == sk.get_bone_count(), "%s gira los %d huesos (tiene %d)" % [c, sk.get_bone_count(), huesos.size()])
	for c in ["campanada_baja", "toque_de_alarma", "recibir_golpe", "entrada"]:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, "reposo", 0.0)
		_ok(d.x < 1.0 and d.y < 0.005, "%s acaba en la pose del reposo (giro %.2f°, posición %.4f m)" % [c, d.x, d.y])
	for c in BUCLES:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, c, 0.0)
		_ok(d.x < 0.5 and d.y < 0.002, "%s cierra el bucle sin salto (%.2f°, %.4f m)" % [c, d.x, d.y])
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var mat := mi.get_active_material(0) as StandardMaterial3D
	_ok(mat != null, "material StandardMaterial3D (Compatibility)")
	if mat != null:
		var total := 0.0
		for par in [["color", mat.albedo_texture, COLOR_COMPRIMIDO, 0], ["normales", mat.normal_texture, true, 1],
				["rugosidad y metal", mat.roughness_texture, true, 0]]:
			var t: Texture2D = par[1]
			if t == null:
				_ok(false, "textura de " + par[0])
				continue
			var cfg := ConfigFile.new()
			cfg.load(t.resource_path + ".import")
			var modo: int = cfg.get_value("params", "compress/mode", 0)
			var nm: int = cfg.get_value("params", "compress/normal_map", 0)
			_ok(t.get_width() == 2048 and t.get_height() == 2048, "%s: %d × %d (%s)" % [par[0], t.get_width(), t.get_height(), t.resource_path.get_file()])
			_ok((modo == 2) == par[2] and nm == par[3], "%s: compress/mode=%d (%s), normal_map=%d" % [par[0], modo,
				"comprimida para la GPU" if modo == 2 else "sin comprimir", nm])
			var img := t.get_image()
			if img != null:
				var mb := img.get_data_size() / 1048576.0
				total += mb
				print("    formato %d, comprimida %s, mipmaps %s: %.1f MB en la GPU" % [img.get_format(), img.is_compressed(), img.has_mipmaps(), mb])
		print("  texturas: %.1f MB en la GPU (las tres)" % total)
		print("  metal %.2f (canal %d), rugosidad %.2f, normal %s, caras %d, transparencia %d" % [mat.metallic,
			mat.metallic_texture_channel, mat.roughness, mat.normal_enabled, mat.cull_mode, mat.transparency])
	var caja := mi.get_aabb()
	print("  malla: ", mi.mesh.get_faces().size() / 3, " triángulos, huesos ", sk.get_bone_count(), ", caja ", caja)
	n.queue_free()
	await _esperar(2)


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


# ---------------------------------------------------------------- la escena con su guion

func _nuevo(padre: Node = null) -> Node3D:
	var z: Node3D = load(ESCENA).instantiate()
	(padre if padre != null else root).add_child(z)
	for s in ["aviso", "impacto", "ataque_terminado", "clip_terminado"]:
		z.connect(s, _anotar.bind(z, s))
	return z


func _anotar(a, z: Node3D, s: String) -> void:
	if not registro.has(s):
		registro[s] = []
	registro[s].append([Engine.get_process_frames(), z.anim.current_animation_position, a])


func _veces(s: String) -> int:
	return registro.get(s, []).size()


func _comprobar_escena() -> void:
	var z := _nuevo()
	await _esperar(3)
	_ok(z.anim != null and z.skel != null, "la escena tiene AnimationPlayer y esqueleto")
	_ok(String(z.anim.current_animation) == "reposo", "empieza en reposo")
	for c in z.anim.get_animation_list():
		var bucle: bool = z.anim.get_animation(c).loop_mode != Animation.LOOP_NONE
		_ok(bucle == (String(c) in BUCLES), "%s: %s" % [c, "en bucle" if bucle else "una vez"])
	_ok(is_equal_approx(float(z.get("ALTURA")), 1.52), "ALTURA para la invocación de Érebo: %s m" % str(z.get("ALTURA")))
	var al: float = z.alcance("campanada_baja")
	_ok(al > 0.2 and al < 0.8, "la campanada adelanta la boca de la campana %.3f m en el impacto" % al)
	var yaw := rad_to_deg(z.pivote.rotation.y)
	_ok(absf(yaw - rad_to_deg(atan2(0.8, 0.6))) < 0.5, "mira a los héroes como los enemigos 3D (giro %.1f°)" % yaw)
	# la campanada desde el reposo
	await _ataque(z, "campanada_baja", 16.0 / 30.0)
	# el toque de alarma
	registro.clear()
	var f0 := Engine.get_process_frames()
	var fin_aviso := [false]
	var avisa := func():
		await z.avisar()
		fin_aviso[0] = true
	avisa.call()
	await _esperar(4)
	z.recibir_golpe()                                   # avisando no se corta
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "toque_de_alarma", "avisando, un golpe recibido no corta el toque")
	while not fin_aviso[0] and Engine.get_process_frames() - f0 < 120:
		await process_frame
	var av: Array = registro.get("aviso", [])
	_ok(av.size() == 1, "avisar(): señal aviso una vez (%d)" % av.size())
	if av.size() == 1:
		var t: float = (av[0][0] - f0) * DT
		_ok(absf(t - 22.0 / 30.0) <= TOL and av[0][2] == "toque_de_alarma", "aviso en el repique: %.3f s (ficha 0,73)" % t)
		_ok(absf(float(av[0][1]) - 22.0 / 30.0) <= DT * 0.5 + 0.001, "el clip va por %.3f s en el repique" % float(av[0][1]))
	await _esperar(3)
	_ok(String(z.anim.current_animation) == "reposo", "tras el toque, reposo: " + String(z.anim.current_animation))
	# pausa a mitad de un ataque: el impacto llega una vez, en su sitio del clip
	registro.clear()
	f0 = Engine.get_process_frames()
	var llamadas := [0]
	var fin := [false]
	var tarea := func():
		await z.atacar("campanada_baja", func(): llamadas[0] += 1)
		fin[0] = true
	tarea.call()
	await _esperar(6)
	paused = true
	await _esperar(30)
	_ok(_veces("impacto") == 0, "con el juego en pausa no golpea")
	paused = false
	while not fin[0] and Engine.get_process_frames() - f0 < 200:
		await process_frame
	_ok(_veces("impacto") == 1 and llamadas[0] == 1, "tras la pausa, un impacto (%d) y una llamada (%d)" % [_veces("impacto"), llamadas[0]])
	# un golpe recibido a mitad de un ataque no lo corta
	registro.clear()
	llamadas[0] = 0
	fin[0] = false
	tarea.call()
	await _esperar(5)
	z.recibir_golpe()
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "campanada_baja", "atacando, un golpe recibido no corta el ataque")
	while not fin[0]:
		await process_frame
	_ok(_veces("impacto") == 1 and llamadas[0] == 1, "y su impacto sale una vez (%d, %d)" % [_veces("impacto"), llamadas[0]])
	# golpe desde el reposo
	await _esperar(10)
	z.recibir_golpe()
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "recibir_golpe", "recibir_golpe desde el reposo")
	await _esperar(25)
	_ok(String(z.anim.current_animation) == "reposo", "vuelve al reposo: " + String(z.anim.current_animation))
	# correr
	z.correr()
	await _esperar(20)
	_ok(String(z.anim.current_animation) == "correr" and z.anim.get_animation("correr").loop_mode == Animation.LOOP_LINEAR, "correr: a saltitos, en bucle")
	z.mirar_frente(0.0)
	z.reposo()
	await _esperar(10)
	# entrada
	registro.clear()
	f0 = Engine.get_process_frames()
	z.entrada()
	await _esperar(2)
	var p_inicio: Vector3 = z.skel.get_bone_pose_position(z.skel.find_bone("root"))
	_ok(p_inicio.z < -0.7, "entrada: empieza %.2f m por detrás de su sitio" % -p_inicio.z)
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "entrada", "entrada termina (%.2f s) y avisa" % ((Engine.get_process_frames() - f0) * DT))
	await _esperar(10)
	_ok(String(z.anim.current_animation) == "reposo", "tras la entrada, reposo")
	var p_fin: Vector3 = z.skel.get_bone_pose_position(z.skel.find_bone("root"))
	_ok(p_fin.length() < 0.03, "y en su sitio (raíz a %.3f m)" % p_fin.length())
	# derrota
	registro.clear()
	f0 = Engine.get_process_frames()
	z.morir()
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "derrota", "derrota termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	var giro_raiz: float = rad_to_deg(z.skel.get_bone_pose_rotation(z.skel.find_bone("root")).get_angle())
	var arriba: Vector3 = z.skel.get_bone_pose_rotation(z.skel.find_bone("root")) * Vector3.UP
	_ok(giro_raiz > 80.0 and arriba.z < -0.8, "cae de espaldas, lejos de los héroes (raíz girada %.0f°, arriba %.2f, %.2f, %.2f)" % [giro_raiz, arriba.x, arriba.y, arriba.z])
	z.herida()
	z.atacar("campanada_baja")
	z.avisar()
	await _esperar(20)
	_ok(_veces("impacto") == 0 and _veces("aviso") == 0, "derrotado no ataca ni avisa")
	z.revivir()
	await _esperar(20)
	giro_raiz = rad_to_deg(z.skel.get_bone_pose_rotation(z.skel.find_bone("root")).get_angle())
	_ok(String(z.anim.current_animation) == "reposo" and giro_raiz < 1.0, "revivir: reposo y de pie (raíz %.1f°)" % giro_raiz)
	z.queue_free()
	await _esperar(2)
	# liberado a mitad de un ataque: sin errores
	var z2 := _nuevo()
	await _esperar(3)
	z2.atacar("campanada_baja", func(): pass)
	await _esperar(8)
	z2.queue_free()
	await _esperar(30)
	_ok(true, "liberado a mitad de un ataque, sin errores (el registro lo diría)")
	# como lo crea el combate: .new() con ruta_modelo
	var z3: Node3D = load(GUION).new()
	z3.ruta_modelo = GLB
	root.add_child(z3)
	await _esperar(3)
	_ok(z3.anim != null and String(z3.anim.current_animation) == "reposo", "creado con .new() y ruta_modelo: en reposo")
	z3.queue_free()
	await _esperar(2)


func _ataque(z: Node3D, ataque: String, esperado: float) -> void:
	registro.clear()
	var llamadas := [0]
	var fin := [false]
	var f0 := Engine.get_process_frames()
	var tarea := func():
		await z.atacar(ataque, func(): llamadas[0] += 1)
		fin[0] = true
	tarea.call()
	while not fin[0] and Engine.get_process_frames() - f0 < 200:
		await process_frame
	var imp: Array = registro.get("impacto", [])
	_ok(imp.size() == 1 and llamadas[0] == 1, "%s: un impacto (%d) y una llamada al combate (%d)" % [ataque, imp.size(), llamadas[0]])
	if imp.size() >= 1:
		var t: float = (imp[0][0] - f0) * DT
		_ok(absf(t - esperado) <= TOL, "%s: impacto a %.3f s de la orden (esperado %.3f ± %.2f)" % [ataque, t, esperado, TOL])
		var pos: float = imp[0][1]
		_ok(absf(pos - esperado) <= DT * 0.5 + 0.001, "%s: el clip va por %.3f s al golpear (medio fotograma)" % [ataque, pos])
	_ok(_veces("ataque_terminado") == 1, "%s: ataque_terminado una vez" % ataque)
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "reposo", "%s: vuelve al reposo" % ataque)
	await _esperar(8)


# ---------------------------------------------------------------- capturas

func _foto(vp: Viewport, nombre: String) -> void:
	var dibujado := [false]
	var al_dibujar := func(): dibujado[0] = true
	RenderingServer.frame_post_draw.connect(al_dibujar, CONNECT_ONE_SHOT)
	var n := 0
	while not dibujado[0] and n < 10:
		await process_frame
		n += 1
	if not dibujado[0]:
		print("  AVISO: la ventana no dibuja; la captura %s puede salir vacía" % nombre)
	vp.get_texture().get_image().save_png("%s/%s.png" % [fotos, nombre])
	print("  captura ", nombre)


# Un estudio con la luz y la cámara del combate (ortográfica, 12° desde arriba, luz dorada y relleno azul).
func _estudio(tam: Vector2i, alto: float, centro_y: float) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tam
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = alto
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.45, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.ambient_light_energy = 0.6
	cam.environment = env
	vp.add_child(cam)
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, centro_y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, centro_y, 0))
	cam.current = true
	var luz := DirectionalLight3D.new()
	luz.light_color = Color("FFE2B0").lerp(Color(1.0, 0.8, 0.6), 0.3)
	luz.light_energy = 1.3
	luz.rotation_degrees = Vector3(-35, -40, 0)
	luz.shadow_enabled = true
	vp.add_child(luz)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color("7FA0D8")
	relleno.light_energy = 0.3
	relleno.rotation_degrees = Vector3(-15, 140, 0)
	vp.add_child(relleno)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.36, 0.42, 0.26)
	suelo.material_override = ms
	vp.add_child(suelo)
	return vp


# Cada clip en varios momentos, con Kael al lado para la escala; y las texturas sin comprimir frente a comprimidas.
func _capturas() -> void:
	DirAccess.make_dir_recursive_absolute(fotos)
	var vp := _estudio(Vector2i(1120, 840), ALTO_VISTA + 0.6, CENTRO_Y)
	var vista := TextureRect.new()
	vista.texture = vp.get_texture()
	root.add_child(vista)
	var z := _nuevo(vp)
	await _esperar(4)
	z.position = Vector3(-0.55, 0, 0)
	var kael = load("res://kael_3d.gd").new()
	vp.add_child(kael)
	kael.position = Vector3(1.0, 0, 0)
	await _esperar(8)
	kael.mirar(Vector3(-0.8, 0, 0.6), 0.0)
	await _esperar(20)
	await _foto(vp, "00_escala_junto_a_kael_reposo")
	kael.queue_free()
	z.position = Vector3.ZERO
	var momentos := {"toque_de_alarma": [0.2, 0.5, 22.0 / 30.0, 0.9], "campanada_baja": [0.3, 16.0 / 30.0, 0.8],
		"recibir_golpe": [0.15, 0.3], "entrada": [0.0, 0.2, 0.37, 0.7, 1.0], "correr": [0.0, 0.13, 0.27, 0.4],
		"derrota": [0.15, 0.3, 0.5, 0.67, 1.17]}
	for c in momentos:
		z.mirar_frente(0.0)
		z.anim.play(c, 0.0)
		for t in momentos[c]:
			z.anim.seek(t, true)
			z.anim.pause()
			await _esperar(3)
			await _foto(vp, "%s_%04.2f" % [c, t])
		z.anim.play("reposo", 0.0)
	vp.queue_free()
	vista.queue_free()
	await _esperar(3)
	await _comparar_texturas()


# Antes y después de comprimir la textura de color, en primer plano (la campana): con las tres comprimidas como en el
# juego (derecha) y con el color original sin comprimir (izquierda). Las normales y la rugosidad, comprimidas en las dos.
func _comparar_texturas() -> void:
	var vistas: Array = []
	var bichos: Array = []
	for i in 2:
		var vp := _estudio(Vector2i(700, 700), 0.75, 0.95)
		var muestra := TextureRect.new()
		muestra.texture = vp.get_texture()
		muestra.position = Vector2(i * 720, 0)
		root.add_child(muestra)
		var z: Node3D = load(ESCENA).instantiate()
		vp.add_child(z)
		vistas.append(vp)
		bichos.append(z)
	await _esperar(3)
	var mi: MeshInstance3D = bichos[0].find_children("*", "MeshInstance3D", true, false)[0]
	var mat := (mi.get_active_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	var img := Image.load_from_file(mat.albedo_texture.resource_path)
	img.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mi.material_override = mat
	for z in bichos:
		z.mirar(Vector3(0.35, 0, 1), 0.0)
		z.anim.play("reposo")
		z.anim.seek(0.0, true)
		z.anim.pause()
	await _esperar(6)
	await _foto(vistas[0], "80_color_sin_comprimir_primer_plano")
	await _foto(vistas[1], "81_color_comprimido_primer_plano")
	var a: Image = Image.load_from_file("%s/80_color_sin_comprimir_primer_plano.png" % fotos)
	var b: Image = Image.load_from_file("%s/81_color_comprimido_primer_plano.png" % fotos)
	var fondo := Color(0.32, 0.45, 0.25)
	var dif := Image.create(a.get_width(), a.get_height(), false, Image.FORMAT_RGBA8)
	var suma := 0.0
	var n := 0
	var mayor := 0.0
	var sobre8 := 0
	var sobre16 := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var d := (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0
			var v := clampf(d * 8.0, 0.0, 1.0)
			dif.set_pixel(x, y, Color(v, v, v, 1.0))
			if ca.is_equal_approx(fondo) and cb.is_equal_approx(fondo):
				continue
			suma += d
			n += 1
			mayor = maxf(mayor, d)
			if d > 8.0 / 255.0:
				sobre8 += 1
			if d > 16.0 / 255.0:
				sobre16 += 1
	dif.save_png("%s/82_diferencia_x8.png" % fotos)
	if n > 0:
		print("  COLOR sin comprimir frente a comprimido (primer plano): diferencia media %.2f/255, máxima %.0f/255; más de 8/255: %.2f %%, más de 16/255: %.3f %% (%d píxeles)" % [
			suma / n * 255.0, mayor * 255.0, 100.0 * sobre8 / n, 100.0 * sobre16 / n, n])
	for vp in vistas:
		vp.queue_free()
