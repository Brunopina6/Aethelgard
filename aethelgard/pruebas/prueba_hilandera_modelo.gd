extends SceneTree
# Prueba de la Hilandera del Eco (T-097, bestiario 01, élite; HILANDERA_19_11): el modelo, sus clips y sus anclas de
# tiempo, sin ventana.  --headless --script res://pruebas/prueba_hilandera_modelo.gd --fixed-fps 30
# Comprueba (y acaba con «FALLOS: n»):
#  - el GLB importado trae los 4 clips del usuario y los 4 nuevos; en la escena, en bucle solo reposo y correr; cada clip
#    gira los 22 huesos (no se queda nada de un clip anterior, como la caída de la derrota)
#  - la mordida, la trama, la marca (aviso_mordida), el golpe y la entrada acaban en la pose del reposo; los bucles
#    cierran sin salto
#  - material de Compatibility y texturas 2048 × 2048 comprimidas para la GPU (como las del Cencerrante)
#  - atacar(): la señal aviso UNA vez al empezar y la señal impacto UNA vez y en su ancla (mordida_resonante 0,733 s,
#    trama_de_eco 0,833 s), también con pausa y si recibe un golpe a medias; luego vuelve al reposo
#  - avisar(): el clip aviso_mordida, la señal aviso UNA vez a 0,40 s, sin impacto, y vuelve al reposo
#  - recibir golpe vuelve al reposo; la derrota la deja en el suelo, quieta, sin atacar ni avisar; revivir y entrada
#    acaban en reposo (la entrada empieza 1,0 m por detrás); el alcance de la mordida; ALTURA; creada con .new()

const ESCENA := "res://enemigos/hilandera/hilandera_3d.tscn"
const GUION := "res://enemigos/hilandera/hilandera_3d.gd"
const GLB := "res://enemigos/hilandera/hilandera_completo.glb"
const DEL_USUARIO := ["reposo", "mordida_resonante", "trama_de_eco", "recibir_golpe"]
const NUEVOS := ["aviso_mordida", "derrota", "entrada", "correr"]
const BUCLES := ["reposo", "correr"]
const TOL := 0.05                     # 1,5 fotogramas a 30 fps
const DT := 1.0 / 30.0

var fallos := 0
var registro := {}                     # señales recibidas: nombre -> [[fotograma, posición del clip, args]]


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
	print("== Hilandera del Eco: modelo y clips")
	await _comprobar_glb()
	await _comprobar_escena()
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
	_ok(n.find_children("*", "Camera3D", true, false).is_empty(), "el GLB no trae cámaras")
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
	for c in ["mordida_resonante", "trama_de_eco", "aviso_mordida", "recibir_golpe", "entrada"]:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, "reposo", 0.0)
		_ok(d.x < 1.0 and d.y < 0.005, "%s acaba en la pose del reposo (giro %.2f°, posición %.4f m)" % [c, d.x, d.y])
	for c in BUCLES:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, c, 0.0)
		_ok(d.x < 0.5 and d.y < 0.002, "%s cierra el bucle sin salto (%.2f°, %.4f m)" % [c, d.x, d.y])
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var mat := mi.get_active_material(0) as StandardMaterial3D
	_ok(mat != null, "material StandardMaterial3D (Compatibility)")
	if mat != null:
		for par in [["color", mat.albedo_texture], ["normales", mat.normal_texture], ["rugosidad y metal", mat.roughness_texture]]:
			var t: Texture2D = par[1]
			if t == null:
				_ok(false, "textura de " + par[0])
				continue
			var cfg := ConfigFile.new()
			cfg.load(t.resource_path + ".import")
			var modo: int = cfg.get_value("params", "compress/mode", 0)
			_ok(t.get_width() == 2048 and t.get_height() == 2048, "%s: %d × %d (%s)" % [par[0], t.get_width(), t.get_height(), t.resource_path.get_file()])
			_ok(modo == 2, "%s: compress/mode=%d (comprimida para la GPU)" % [par[0], modo])
	print("  malla: ", mi.mesh.get_faces().size() / 3, " triángulos, huesos ", sk.get_bone_count(), ", caja ", mi.get_aabb())
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

func _nuevo() -> Node3D:
	var z: Node3D = load(ESCENA).instantiate()
	root.add_child(z)
	for s in ["aviso", "impacto", "ataque_terminado", "clip_terminado"]:
		z.connect(s, _anotar.bind(z, s))
	return z


func _anotar(a, z: Node3D, s: String) -> void:
	if not registro.has(s):
		registro[s] = []
	registro[s].append([Engine.get_process_frames(), z.anim.current_animation_position, a])


func _veces(s: String) -> int:
	return registro.get(s, []).size()


func _raiz(z: Node3D) -> Vector3:
	return z.skel.get_bone_pose_position(z.skel.find_bone("root"))


func _comprobar_escena() -> void:
	var z := _nuevo()
	await _esperar(3)
	_ok(z.anim != null and z.skel != null, "la escena tiene AnimationPlayer y esqueleto")
	_ok(String(z.anim.current_animation) == "reposo", "empieza en reposo")
	for c in z.anim.get_animation_list():
		var bucle: bool = z.anim.get_animation(c).loop_mode != Animation.LOOP_NONE
		_ok(bucle == (String(c) in BUCLES), "%s: %s" % [c, "en bucle" if bucle else "una vez"])
	_ok(is_equal_approx(float(z.get("ALTURA")), 1.50), "ALTURA para la invocación de Érebo: %s m" % str(z.get("ALTURA")))
	var al: float = z.alcance("mordida_resonante")
	_ok(al > 0.05 and al < 1.0, "la mordida adelanta las mandíbulas %.3f m en el impacto" % al)
	var frente: float = z._cabeza_en("reposo", 0.0).z
	_ok(frente > 0.3 and frente < 1.2, "en reposo, las mandíbulas %.3f m por delante de su sitio" % frente)
	var yaw := rad_to_deg(z.pivote.rotation.y)
	_ok(absf(yaw - rad_to_deg(atan2(0.8, 0.6))) < 0.5, "mira a los héroes como los enemigos 3D (giro %.1f°)" % yaw)
	var raiz_reposo := _raiz(z)
	await _ataque(z, "mordida_resonante", 22.0 / 30.0)
	await _ataque(z, "trama_de_eco", 25.0 / 30.0)
	# la marca (avisar)
	registro.clear()
	var f0 := Engine.get_process_frames()
	var fin_aviso := [false]
	var avisa := func():
		await z.avisar()
		fin_aviso[0] = true
	avisa.call()
	await _esperar(4)
	_ok(String(z.anim.current_animation) == "aviso_mordida", "avisar() pone el clip aviso_mordida")
	z.recibir_golpe()                                   # avisando no se corta
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "aviso_mordida", "avisando, un golpe recibido no corta la marca")
	while not fin_aviso[0] and Engine.get_process_frames() - f0 < 120:
		await process_frame
	var av: Array = registro.get("aviso", [])
	_ok(av.size() == 1 and _veces("impacto") == 0, "avisar(): señal aviso una vez (%d), sin impacto (%d)" % [av.size(), _veces("impacto")])
	if av.size() == 1:
		var t: float = (av[0][0] - f0) * DT
		_ok(absf(t - 12.0 / 30.0) <= TOL and av[0][2] == "mordida_resonante", "aviso de la marca a %.3f s (0,40)" % t)
	await _esperar(3)
	_ok(String(z.anim.current_animation) == "reposo", "tras la marca, reposo: " + String(z.anim.current_animation))
	# pausa a mitad de un ataque: el impacto llega una vez
	for ataque in ["mordida_resonante", "trama_de_eco"]:
		registro.clear()
		f0 = Engine.get_process_frames()
		var llamadas := [0]
		var fin := [false]
		var tarea := func():
			await z.atacar(ataque, func(): llamadas[0] += 1)
			fin[0] = true
		tarea.call()
		await _esperar(6)
		paused = true
		await _esperar(30)
		_ok(_veces("impacto") == 0, "%s: con el juego en pausa no golpea" % ataque)
		paused = false
		await _esperar(3)
		z.recibir_golpe()                               # atacando no se corta
		await _esperar(2)
		_ok(String(z.anim.current_animation) == ataque, "%s: atacando, un golpe recibido no corta el ataque" % ataque)
		while not fin[0] and Engine.get_process_frames() - f0 < 200:
			await process_frame
		_ok(_veces("impacto") == 1 and llamadas[0] == 1, "%s: tras la pausa y el golpe, un impacto (%d) y una llamada (%d)" % [ataque, _veces("impacto"), llamadas[0]])
		await _esperar(5)
	# golpe desde el reposo
	z.recibir_golpe()
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "recibir_golpe", "recibir_golpe desde el reposo")
	await _esperar(25)
	_ok(String(z.anim.current_animation) == "reposo", "vuelve al reposo: " + String(z.anim.current_animation))
	# correr
	z.correr()
	await _esperar(20)
	_ok(String(z.anim.current_animation) == "correr", "correr: corretea en bucle")
	z.mirar_frente(0.0)
	z.reposo()
	await _esperar(10)
	# entrada
	registro.clear()
	f0 = Engine.get_process_frames()
	z.entrada()
	await _esperar(2)
	var p_inicio := _raiz(z)
	_ok(p_inicio.z < -0.8, "entrada: empieza %.2f m por detrás de su sitio" % -p_inicio.z)
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "entrada", "entrada termina (%.2f s) y avisa" % ((Engine.get_process_frames() - f0) * DT))
	await _esperar(10)
	_ok(String(z.anim.current_animation) == "reposo", "tras la entrada, reposo")
	var p_fin := _raiz(z)
	_ok(Vector2(p_fin.x, p_fin.z).length() < 0.03 and absf(p_fin.y - raiz_reposo.y) < 0.03, "y en su sitio (raíz a %s; en reposo %s)" % [p_fin, raiz_reposo])
	# derrota
	registro.clear()
	f0 = Engine.get_process_frames()
	z.morir()
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "derrota", "derrota termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	var caida := _raiz(z)
	_ok(caida.y < raiz_reposo.y - 0.15, "cae al suelo: la raíz baja de %.3f a %.3f m" % [raiz_reposo.y, caida.y])
	z.herida()
	z.atacar("mordida_resonante")
	z.avisar()
	await _esperar(20)
	_ok(_veces("impacto") == 0 and _veces("aviso") == 0, "derrotada no ataca ni avisa")
	_ok(_raiz(z).distance_to(caida) < 0.01, "y se queda quieta en el suelo")
	z.revivir()
	await _esperar(20)
	_ok(String(z.anim.current_animation) == "reposo" and absf(_raiz(z).y - raiz_reposo.y) < 0.05, "revivir: reposo y de pie (raíz %.3f m)" % _raiz(z).y)
	z.queue_free()
	await _esperar(2)
	# liberada a mitad de un ataque: sin errores
	var z2 := _nuevo()
	await _esperar(3)
	z2.atacar("trama_de_eco", func(): pass)
	await _esperar(8)
	z2.queue_free()
	await _esperar(30)
	_ok(true, "liberada a mitad de un ataque, sin errores (el registro lo diría)")
	# como la crea el combate: .new() con ruta_modelo
	var z3: Node3D = load(GUION).new()
	z3.ruta_modelo = GLB
	root.add_child(z3)
	await _esperar(3)
	_ok(z3.anim != null and String(z3.anim.current_animation) == "reposo", "creada con .new() y ruta_modelo: en reposo")
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
	var av: Array = registro.get("aviso", [])
	_ok(av.size() == 1 and av[0][2] == ataque and av[0][0] - f0 <= 1, "%s: la señal aviso una vez y al empezar (%d)" % [ataque, av.size()])
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
