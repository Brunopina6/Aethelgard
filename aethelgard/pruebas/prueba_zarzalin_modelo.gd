extends SceneTree
# Prueba de Zarzalín (T-097): el modelo, sus clips y sus anclas de tiempo; con «fotos=<carpeta>», además, capturas
# desde la cámara del combate de verdad (combate.tscn, sin tocar combate.gd).
#   sin ventana:  --headless --script res://pruebas/prueba_zarzalin_modelo.gd --fixed-fps 30
#   con capturas: --script res://pruebas/prueba_zarzalin_modelo.gd --fixed-fps 30 -- fotos=<carpeta> [tam=1.25]
#   (prueba_zarzalin_fotos.gd es esta misma con la carpeta que le da ejecutar_pruebas.ps1 -Manual)
# Comprueba (y acaba con «FALLOS: n»):
#  - el GLB importado trae los 6 clips pedidos y los 3 de apoyo; en la escena, en bucle solo reposo, aviso_espera y correr;
#    cada clip escribe los 12 huesos (no se queda nada de un clip anterior, como el giro de la derrota)
#  - los ataques y el golpe acaban en la pose del reposo, y los bucles empiezan y acaban igual
#  - texturas: 2048 × 2048 comprimidas para la GPU (memoria estimada en el registro)
#  - la señal impacto sale UNA vez por ataque y en su ancla (±0,05 s): colmillo 0,467 s, embestida 0,567 s, y 0,167 s
#    desde la carga del aviso; también con pausa y si recibe un golpe a medias; luego vuelve al reposo
#  - el aviso: «aviso» al bajar el hocico (0,267 s), dos golpes de pezuña (0,467 y 0,733 s) y la espera en bucle
#  - recibir golpe vuelve al reposo (o a la carga si estaba avisando); derrota se queda quieta y no ataca; revivir y
#    entrada acaban en reposo; el alcance de la embestida; ALTURA para Érebo; creado con .new() como en el combate
# Las capturas: escala junto a Grimfang, reposo, entrada, aviso, galope, embestida e impacto en Kael, colmillo, golpe
# recibido y derrota, y las texturas sin comprimir frente a las comprimidas para la GPU, con su diferencia.

const ESCENA := "res://enemigos/zarzalin/zarzalin_3d.tscn"
const GUION := "res://enemigos/zarzalin/zarzalin_3d.gd"
const GLB := "res://enemigos/zarzalin/zarzalin_completo.glb"
const PEDIDOS := ["reposo", "embestida_espinosa", "colmillo_lateral", "recibir_golpe", "derrota", "entrada"]
const APOYO := ["aviso_embestida", "aviso_espera", "correr"]
const BUCLES := ["reposo", "aviso_espera", "correr"]
const TOL := 0.05                     # 1,5 fotogramas a 30 fps
const DT := 1.0 / 30.0
# Encuadre propuesto para el combate (MODELOS de combate.gd): ventana 3D de 940 × 420 a 1,5 m de alto (280 px/m,
# como Grimfang), mirando a 0,48 m del suelo, y la misma escala 2D que los enemigos 3D (0,6).
const VP := Vector2i(940, 420)
const ALTO_VISTA := 1.5
const CENTRO_Y := 0.48
const ESC := 0.6
# Con «tam=<factor>» las capturas lo muestran más grande (la ventana 3D crece con él: misma nitidez)
var tam := 1.0

var fallos := 0
var fotos := ""
var registro := {}                     # señales recibidas: nombre -> [[fotograma, posición del clip, args]]


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
		if a.begins_with("tam="):
			tam = float(a.substr(4))
	_correr.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + texto)
	if not cond:
		fallos += 1


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	print("== Zarzalín: modelo y clips")
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
	for c in PEDIDOS + APOYO:
		_ok(c in lista, "existe el clip " + c)
	for c in lista:
		var a := ap.get_animation(c)
		print("  %s: %.3f s, %d pistas (bucle al importar: %d; lo pone el guion de la escena)" % [c, a.length, a.get_track_count(), a.loop_mode])
		var huesos := {}
		for k in a.get_track_count():
			var p := String(a.track_get_path(k))
			if a.track_get_type(k) == Animation.TYPE_ROTATION_3D and ":" in p:
				huesos[p.get_slice(":", 1)] = true
		_ok(huesos.size() == sk.get_bone_count(), "%s gira los %d huesos (tiene %d)" % [c, sk.get_bone_count(), huesos.size()])
	# los ataques y el golpe acaben en la pose del reposo; los bucles, como empiezan
	for c in ["embestida_espinosa", "colmillo_lateral", "recibir_golpe", "entrada"]:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, "reposo", 0.0)
		_ok(d.x < 1.0 and d.y < 0.005, "%s acaba en la pose del reposo (giro %.2f°, posición %.4f m)" % [c, d.x, d.y])
	for c in BUCLES:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, c, 0.0)
		_ok(d.x < 0.5 and d.y < 0.002, "%s cierra el bucle sin salto (%.2f°, %.4f m)" % [c, d.x, d.y])
	var d2 := _diferencia_pose(ap, sk, "aviso_embestida", ap.get_animation("aviso_embestida").length, "aviso_espera", 0.0)
	_ok(d2.x < 1.0 and d2.y < 0.005, "aviso_embestida acaba donde empieza aviso_espera (%.2f°, %.4f m)" % [d2.x, d2.y])
	# material y texturas
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var mat := mi.get_active_material(0) as StandardMaterial3D
	_ok(mat != null, "material StandardMaterial3D (Compatibility)")
	if mat != null:
		var total := 0.0
		for par in [["color", mat.albedo_texture], ["normales", mat.normal_texture], ["rugosidad y metal", mat.roughness_texture]]:
			var t: Texture2D = par[1]
			if t == null:
				_ok(false, "textura de " + par[0])
				continue
			var cfg := ConfigFile.new()
			cfg.load(t.resource_path + ".import")
			var vram: bool = cfg.get_value("params", "compress/mode", 0) == 2
			_ok(t.get_width() == 2048 and t.get_height() == 2048, "%s: %d × %d (%s)" % [par[0], t.get_width(), t.get_height(), t.resource_path.get_file()])
			_ok(vram, "%s: importada comprimida para la GPU (compress/mode=2; normal_map=%d)" % [par[0], cfg.get_value("params", "compress/normal_map", 0)])
			var img := t.get_image()
			if img != null:
				var mb := _memoria_mb(img)
				total += mb
				print("    formato %d, comprimida %s, mipmaps %s: %.1f MB en la GPU" % [img.get_format(), img.is_compressed(), img.has_mipmaps(), mb])
		if total > 0.0:
			print("  texturas: %.1f MB en la GPU (las tres)" % total)
		print("  metal %.2f (canal %d), rugosidad %.2f (canal %d), normal %s, caras %d" % [mat.metallic, mat.metallic_texture_channel,
			mat.roughness, mat.roughness_texture_channel, mat.normal_enabled, mat.cull_mode])
	print("  malla: ", mi.mesh.get_faces().size() / 3, " triángulos, huesos ", sk.get_bone_count(), ", caja ", mi.get_aabb())
	n.queue_free()
	await _esperar(2)


func _memoria_mb(img: Image) -> float:
	return img.get_data_size() / 1048576.0


# Diferencia (máximo giro en grados, máximo desplazamiento en m) entre la pose de dos clips en dos instantes.
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
	for s in ["aviso", "pezuna", "impacto", "ataque_terminado", "clip_terminado"]:
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
	_ok(is_equal_approx(float(z.get("ALTURA")), 0.92), "ALTURA para la invocación de Érebo: %s m" % str(z.get("ALTURA")))
	var al: float = z.alcance("embestida_espinosa")
	_ok(al > 0.6 and al < 0.67, "la embestida adelanta el hocico %.3f m en el impacto" % al)
	var al2: float = z.alcance("colmillo_lateral")
	_ok(absf(al2) < 0.05, "el colmillo lateral no avanza el hocico en el impacto (%.3f m): barre de lado" % al2)
	var yaw := rad_to_deg(z.pivote.rotation.y)
	_ok(absf(yaw - rad_to_deg(atan2(0.8, 0.6))) < 0.5, "mira a los héroes como los enemigos 3D (giro %.1f°)" % yaw)

	# ataques desde el reposo
	for par in [["colmillo_lateral", 14.0 / 30.0], ["embestida_espinosa", 17.0 / 30.0]]:
		await _ataque(z, par[0], par[1], "desde el reposo")
	# aviso de la embestida
	registro.clear()
	var f0 := Engine.get_process_frames()
	z.avisar()
	await _esperar(40)
	var av: Array = registro.get("aviso", [])
	_ok(av.size() == 1, "avisar(): señal aviso una vez (%d)" % av.size())
	if av.size() == 1:
		var t: float = (av[0][0] - f0) * DT
		_ok(absf(t - 8.0 / 30.0) <= TOL, "aviso al bajar el hocico: %.3f s (ficha 0,267)" % t)
	var pz: Array = registro.get("pezuna", [])
	_ok(pz.size() == 2, "dos golpes de pezuña (%d)" % pz.size())
	for i in mini(pz.size(), 2):
		var t: float = (pz[i][0] - f0) * DT
		var esperado: float = [14.0 / 30.0, 22.0 / 30.0][i]
		_ok(absf(t - esperado) <= TOL and pz[i][2] == i + 1, "golpe de pezuña %d a %.3f s (clip %.3f)" % [i + 1, t, esperado])
	_ok(String(z.anim.current_animation) == "aviso_espera", "tras el aviso, espera en carga (bucle): " + String(z.anim.current_animation))
	# un golpe durante la carga: reacciona y vuelve a la carga
	z.recibir_golpe()
	await _esperar(3)
	_ok(String(z.anim.current_animation) == "recibir_golpe", "en carga, recibir_golpe reacciona")
	await _esperar(25)
	_ok(String(z.anim.current_animation) == "aviso_espera", "y vuelve a la carga: " + String(z.anim.current_animation))
	await _ataque(z, "embestida_espinosa", 5.0 / 30.0, "desde la carga del aviso")
	# pausa a mitad de un ataque: el impacto llega una vez, en su sitio del clip
	registro.clear()
	f0 = Engine.get_process_frames()
	var llamadas := [0]
	var fin := [false]
	var tarea := func():
		await z.atacar("colmillo_lateral", func(): llamadas[0] += 1)
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
	if _veces("impacto") == 1:
		var pos: float = registro["impacto"][0][1]
		_ok(absf(pos - 14.0 / 30.0) <= DT * 0.5 + 0.001, "en el clip, a %.3f s (ancla 0,467)" % pos)
	# un golpe recibido a mitad de un ataque no lo corta
	registro.clear()
	llamadas[0] = 0
	fin[0] = false
	tarea.call()
	await _esperar(5)
	z.recibir_golpe()
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "colmillo_lateral", "atacando, un golpe recibido no corta el ataque")
	while not fin[0]:
		await process_frame
	_ok(_veces("impacto") == 1 and llamadas[0] == 1, "y su impacto sale una vez (%d, %d)" % [_veces("impacto"), llamadas[0]])
	# golpe desde el reposo
	await _esperar(10)
	z.recibir_golpe()
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "recibir_golpe", "recibir_golpe desde el reposo")
	await _esperar(30)
	_ok(String(z.anim.current_animation) == "reposo", "vuelve al reposo: " + String(z.anim.current_animation))
	# correr y vuelta
	z.correr()
	await _esperar(20)
	_ok(String(z.anim.current_animation) == "correr" and z.anim.get_animation("correr").loop_mode == Animation.LOOP_LINEAR, "correr: galope en bucle")
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
	z.recibir_golpe()                                   # entrando no se corta
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	var te := (Engine.get_process_frames() - f0) * DT
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "entrada", "entrada termina (%.2f s) y avisa" % te)
	await _esperar(10)
	_ok(String(z.anim.current_animation) == "reposo", "tras la entrada, reposo")
	var p_fin: Vector3 = z.skel.get_bone_pose_position(z.skel.find_bone("root"))
	_ok(p_fin.length() < 0.03, "y en su sitio (raíz a %.3f m)" % p_fin.length())
	# derrota
	registro.clear()
	f0 = Engine.get_process_frames()
	z.morir()                                           # lo que llama el combate
	while _veces("clip_terminado") == 0 and Engine.get_process_frames() - f0 < 120:
		await process_frame
	_ok(_veces("clip_terminado") == 1 and registro["clip_terminado"][0][2] == "derrota", "derrota termina (%.2f s)" % ((Engine.get_process_frames() - f0) * DT))
	var giro_raiz: float = rad_to_deg(z.skel.get_bone_pose_rotation(z.skel.find_bone("root")).get_angle())
	_ok(giro_raiz > 80.0, "cae de lado (raíz girada %.0f°)" % giro_raiz)
	z.herida()
	z.atacar("embestida_espinosa")
	z.avisar()
	await _esperar(20)
	_ok(_veces("impacto") == 0 and _veces("aviso") == 0, "derrotado no ataca ni avisa")
	_ok(String(z.anim.current_animation) in ["", "derrota"], "y se queda quieto: '%s'" % String(z.anim.current_animation))
	z.revivir()
	await _esperar(20)
	giro_raiz = rad_to_deg(z.skel.get_bone_pose_rotation(z.skel.find_bone("root")).get_angle())
	_ok(String(z.anim.current_animation) == "reposo" and giro_raiz < 1.0, "revivir: reposo y de pie (raíz %.1f°)" % giro_raiz)
	z.queue_free()
	await _esperar(2)
	# liberado a mitad de un ataque (fin del combate, huida): sin errores
	var z2 := _nuevo()
	await _esperar(3)
	z2.atacar("embestida_espinosa", func(): pass)
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


func _ataque(z: Node3D, ataque: String, esperado: float, como: String) -> void:
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
	_ok(imp.size() == 1 and llamadas[0] == 1, "%s %s: un impacto (%d) y una llamada al combate (%d)" % [ataque, como, imp.size(), llamadas[0]])
	if imp.size() >= 1:
		var t: float = (imp[0][0] - f0) * DT
		_ok(absf(t - esperado) <= TOL, "%s %s: impacto a %.3f s de la orden (esperado %.3f ± %.2f)" % [ataque, como, t, esperado, TOL])
		var ancla: float = z.ATAQUES[ataque]["impacto"]
		var pos: float = imp[0][1]
		_ok(absf(pos - ancla) <= DT * 0.5 + 0.001, "%s %s: el clip va por %.3f s al golpear (ancla %.3f, medio fotograma)" % [ataque, como, pos, ancla])
	_ok(_veces("ataque_terminado") == 1, "%s: ataque_terminado una vez" % ataque)
	await _esperar(2)
	_ok(String(z.anim.current_animation) == "reposo", "%s: vuelve al reposo" % ataque)
	await _esperar(8)


# ---------------------------------------------------------------- capturas desde la cámara del combate

# Espera a que se dibuje el fotograma (como mucho 10: si la ventana no puede dibujar, minimizada, no se queda colgada:
# avisa y sigue) y guarda la pantalla.
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


# Combate de verdad (Pastos Verdes, Kael contra un enemigo 3D) y Zarzalín en la ventana 3D de ese enemigo, con el
# encuadre propuesto. El combate no avanza turnos (estado «fin»): la prueba mueve a Zarzalín y llama a los efectos
# del combate (_golpe_visual) en el instante de cada impacto, como haría combate.gd.
func _capturas() -> void:
	DirAccess.make_dir_recursive_absolute(fotos)
	for grupo in [0, 9]:
		Engine.set_meta("grupo_combate", grupo)
		var c: Node = load("res://combate.tscn").instantiate()
		root.add_child(c)
		await _esperar(20)
		c.estado = "fin"
		await _esperar(5)
		if grupo == 0:
			await _foto("00_grimfang_dos_enemigos_antes")
		else:
			await _foto("01_grimfang_en_su_sitio_antes")
		var e: Dictionary = c.enemigos[0] if grupo == 9 else c.enemigos[c.enemigos.size() - 1]
		var z := _poner_en_combate(c, e)
		await _esperar(15)
		if grupo == 0:
			await _foto("02_escala_zarzalin_junto_a_grimfang")
			c.queue_free()
			await _esperar(5)
			continue
		await _escenas_combate(c, e, z)
		c.queue_free()
		await _esperar(5)
	await _comparar_texturas()


# Antes y después de comprimir las texturas para la GPU: el mismo jabalí, en la misma pose y con la luz del combate,
# con las JPG originales sin comprimir (izquierda) y con las texturas importadas (derecha). Imprime la diferencia.
func _comparar_texturas() -> void:
	var tam_vp := Vector2i(int(VP.x * 0.75), int(VP.y * 0.75))     # como en el combate (res_personajes 0,75)
	var lienzo := Control.new()
	lienzo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(lienzo)
	var fondo := ColorRect.new()
	fondo.color = Color(0.32, 0.45, 0.25)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lienzo.add_child(fondo)
	var vistas: Array[SubViewport] = []
	var bichos: Array[Node3D] = []
	for i in 2:
		var vp := SubViewport.new()
		vp.size = tam_vp
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		lienzo.add_child(vp)
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ALTO_VISTA
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(1.0, 0.86, 0.78)
		env.ambient_light_energy = 0.6
		cam.environment = env
		vp.add_child(cam)
		var ang := deg_to_rad(12.0)
		cam.look_at_from_position(Vector3(0, CENTRO_Y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, CENTRO_Y, 0))
		cam.current = true
		var luz := DirectionalLight3D.new()
		luz.light_color = Color("FFE2B0").lerp(Color(1.0, 0.8, 0.6), 0.3)
		luz.light_energy = 1.3
		luz.rotation_degrees = Vector3(-35, -40, 0)
		vp.add_child(luz)
		var relleno := DirectionalLight3D.new()
		relleno.light_color = Color("7FA0D8")
		relleno.light_energy = 0.3
		relleno.rotation_degrees = Vector3(-15, 140, 0)
		vp.add_child(relleno)
		var z: Node3D = load(ESCENA).instantiate()
		vp.add_child(z)
		var muestra := TextureRect.new()
		muestra.texture = vp.get_texture()
		muestra.position = Vector2(20 + i * (tam_vp.x + 20), 200)
		lienzo.add_child(muestra)
		vistas.append(vp)
		bichos.append(z)
	await _esperar(3)
	# la de la izquierda, con las JPG originales sin comprimir (con mipmaps, como las importadas)
	var mi: MeshInstance3D = bichos[0].find_children("*", "MeshInstance3D", true, false)[0]
	var mat := (mi.get_active_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	for par in [["albedo_texture", "Image_0"], ["roughness_texture", "Image_1"], ["metallic_texture", "Image_1"], ["normal_texture", "Image_2"]]:
		var img := Image.load_from_file("res://enemigos/zarzalin/zarzalin_completo_%s.jpg" % par[1])
		img.generate_mipmaps()
		mat.set(par[0], ImageTexture.create_from_image(img))
	mi.material_override = mat
	for z in bichos:
		z.anim.play("reposo")
		z.anim.seek(0.5, true)
		z.anim.pause()
	await _esperar(4)
	await _esperar_dibujo()
	var a := vistas[0].get_texture().get_image()
	var b := vistas[1].get_texture().get_image()
	a.save_png("%s/80_texturas_jpg_sin_comprimir.png" % fotos)
	b.save_png("%s/81_texturas_comprimidas_gpu.png" % fotos)
	var dif := Image.create(a.get_width(), a.get_height(), false, Image.FORMAT_RGBA8)
	var suma := 0.0
	var n := 0
	var mayor := 0.0
	var sobre4 := 0
	var sobre16 := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca.a < 0.5 and cb.a < 0.5:
				continue
			var d := (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0
			suma += d
			n += 1
			mayor = maxf(mayor, d)
			if d > 4.0 / 255.0:
				sobre4 += 1
			if d > 16.0 / 255.0:
				sobre16 += 1
			var v := clampf(d * 8.0, 0.0, 1.0)
			dif.set_pixel(x, y, Color(v, v, v, 1.0))
	dif.save_png("%s/82_diferencia_x8.png" % fotos)
	if n > 0:
		print("  texturas sin comprimir frente a comprimidas: diferencia media %.2f/255, máxima %.0f/255; píxeles con más de 4/255: %.1f %%, con más de 16/255: %.2f %% (de %d píxeles del jabalí)" % [
			suma / n * 255.0, mayor * 255.0, 100.0 * sobre4 / n, 100.0 * sobre16 / n, n])
	lienzo.queue_free()
	await _esperar(2)


func _poner_en_combate(c: Node, e: Dictionary) -> Node3D:
	var viejo: Node3D = e["p3d"]
	var vp: SubViewport = viejo.get_parent()
	viejo.queue_free()
	var q: float = c.res_personajes
	var rig: Node2D = e["rig"]
	var cuerpo: Node2D = e["cuerpo"]
	var pie_antes: Vector2 = rig.position + cuerpo.position * rig.scale
	vp.size = Vector2i(int(VP.x * tam * q), int(VP.y * tam * q))
	var cam: Camera3D = e["cam3d"]
	cam.size = ALTO_VISTA
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, CENTRO_Y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, CENTRO_Y, 0))
	var z: Node3D = load(ESCENA).instantiate()
	vp.add_child(z)
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
	e["p3d"] = z
	e["centro_ofs"] = cam.unproject_position(Vector3(0, 0.5, 0)) / q * ESC
	var arriba: Vector2 = c._a_pantalla(rig.position + cam.unproject_position(Vector3(0, 1.05, 0)) / q * ESC)
	if e.has("barra_hp"):
		e["barra_hp"].position = arriba + Vector2(-60, 0)
		e["lbl_hp"].position = arriba + Vector2(-60, -28)
		e["lbl_estado"].position = arriba + Vector2(-60, -56)
	e["nombre"] = "Zarzalín"
	c._actualizar()
	_veces_senal(z, "impacto")
	return z


func _escenas_combate(c: Node, e: Dictionary, z: Node3D) -> void:
	var kael: Dictionary = c.heroes[0]
	var rig: Node2D = e["rig"]
	var base: Vector2 = rig.position
	await _foto("10_reposo")
	await _esperar(16)
	await _foto("11_reposo_medio_ciclo")
	# entrada
	z.entrada()
	await _esperar(1)
	await _foto("20_entrada_inicio")
	await _esperar(9)
	await _foto("21_entrada_salto")
	await _esperar(5)
	await _foto("22_entrada_aterriza")
	await _esperar(12)
	await _foto("23_entrada_sacude")
	await _esperar(20)
	await _foto("24_entrada_fin_reposo")
	# aviso
	z.avisar()
	await _esperar(8)
	await _foto("30_aviso_hocico_bajo")
	await _esperar(3)
	await _foto("31_aviso_pata_alzada")
	await _esperar(3)
	await _foto("32_aviso_golpe_pezuna")
	await _esperar(30)
	await _foto("33_aviso_espera_carga")
	# embestida contra Kael: se acerca galopando (la posición lógica del combate) y el clip pone el último avance
	var px_m: float = VP.y * tam / ALTO_VISTA * ESC   # píxeles de la escena por metro
	var ida := Vector3(1, 0, 0.1).normalized()
	var hocico_reposo := 0.635 * ida.x * px_m          # del pie al hocico, en pantalla, mirando a la derecha
	# los colmillos llegan al frente de Kael (unos 30 px antes de su centro) en el impacto
	var pie_x: float = c._centro(kael).x - 30.0 - hocico_reposo - z.alcance("embestida_espinosa") * px_m
	var destino := Vector2(pie_x - e["cuerpo"].position.x * ESC, base.y + (c._suelo_de(kael).y - c._suelo_de(e).y))
	z.mirar(ida, 0.15)
	z.correr()
	rig.z_index = 5                                    # como en combate.gd al atacar: por delante de los demás
	var t := c.create_tween()
	t.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _esperar(8)
	await _foto("40_embestida_galope")
	while t.is_running():
		await process_frame
	var golpe := func():
		c._golpe_visual(kael, 24, "")
	z.atacar("embestida_espinosa", golpe)
	await _esperar(3)
	await _foto("41_embestida_empuje")
	while _veces_senal(z, "impacto") == 0:
		await process_frame
	await _foto("42_embestida_impacto")
	await _esperar(5)
	await _foto("43_embestida_aterriza")
	await _esperar(20)
	await _foto("44_embestida_vuelve")
	while String(z.anim.current_animation) != "reposo":
		await process_frame
	# colmillo lateral
	z.atacar("colmillo_lateral", golpe)
	await _esperar(9)
	await _foto("50_colmillo_gira")
	while _veces_senal(z, "impacto") < 2:
		await process_frame
	await _foto("51_colmillo_impacto")
	while String(z.anim.current_animation) != "reposo":
		await process_frame
	z.mirar(-ida, 0.2)
	z.correr()
	var t2 := c.create_tween()
	t2.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _esperar(8)
	await _foto("52_vuelve_galopando")
	while t2.is_running():
		await process_frame
	z.mirar_frente(0.25)
	z.reposo()
	rig.z_index = 0
	await _esperar(20)
	# recibir golpe (Kael le golpea: los efectos del combate llaman a herida())
	c._golpe_visual(e, 30, "")
	await _esperar(4)
	await _foto("60_recibir_golpe")
	await _esperar(30)
	# derrota (como _restablecer_color: morir() y el desvanecido del combate a los 0,9 s)
	e["hp"] = 0
	c._restablecer_color(e)
	await _esperar(10)
	await _foto("70_derrota_cae")
	await _esperar(12)
	await _foto("71_derrota_en_el_suelo")
	await _esperar(10)
	await _foto("72_derrota_desvaneciendo")


func _veces_senal(z: Node3D, s: String) -> int:
	if not z.has_meta("cuenta_" + s):
		z.set_meta("cuenta_" + s, 0)
		z.connect(s, func(_a): z.set_meta("cuenta_" + s, int(z.get_meta("cuenta_" + s)) + 1))
	return int(z.get_meta("cuenta_" + s))
