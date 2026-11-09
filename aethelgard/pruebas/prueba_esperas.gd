extends SceneTree
# Esperas de exploración (personalidad de los héroes, 09/11): esperas_3d.gd y los clips de animaciones/esperas/.
# Con «-- 3d sin_prologo», sin ventana. Termina con «FALLOS: n» y quit(1) si algo falla.
#   1. Cada héroe (Kael, Lya y Garon) suelto: tiene sus clips de espera (los de ESPERADOS), de duración y coste
#      razonables (pistas y claves), empiezan y acaban en su reposo y, al acabar, vuelve a su reposo con sus gestos
#      (Lya: los brazos relajados y el cetro derecho).
#   2. Se disparan solas al estar quieto (con la espera acortada), nunca dos veces seguidas la misma, y se cortan al
#      moverse (marcha) y al ponerle otra animación. En combate (sin activar_esperas) no hay.
#   3. En Pastos Verdes 3D, con Lya y Garon: quietos el tiempo de verdad (6 a 9 s), los tres hacen una espera y dos no
#      empiezan a la vez; al andar Kael con el stick, se cortan todas.

const HEROES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}
const ESPERADOS := {
	"Kael": ["espera_vigilar", "espera_empunadura", "espera_brazalete", "espera_impaciencia"],
	"Lya": ["espera_flor", "espera_cetro", "espera_pelo"],
	"Garon": ["espera_hombros", "espera_espalda", "espera_apoyarse"],
}
const DURACION := Vector2(3.0, 7.0)          # segundos de cada espera
const CLAVES_MAX := 3000                     # claves por clip (20 muestras por segundo y las pistas quietas con una)
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const DT := 1.0 / 30.0

var fallos: Array = []
var fotos := ""                              # con «fotos=<carpeta>» (y ventana): capturas en la región


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _esperar(int(ceil(s / DT)))


func _probar() -> void:
	await _esperar(3)
	if not "solo_region" in OS.get_cmdline_user_args():
		for h in HEROES:
			await _heroe(h)
		await _combate_sin_esperas()
	if not "sin_region" in OS.get_cmdline_user_args():
		await _region()
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= 1 y 2. cada héroe suelto

func _heroe(h: String) -> void:
	var c = load(HEROES[h]).new()
	c.name = "Prueba_" + h
	root.add_child(c)
	await _esperar(8)
	if c.get("anim") == null:
		_fallo("%s sin modelo" % h)
		return
	if not c.activar_esperas():
		_fallo("%s: activar_esperas() no carga sus esperas" % h)
		c.queue_free()
		return
	var e = c.esperas
	var ap: AnimationPlayer = c.anim
	var lista: Array = e.clips.duplicate()
	lista.sort()
	var esperados: Array = ESPERADOS[h].duplicate()
	esperados.sort()
	print("CLIPS %s: %s" % [h, ", ".join(lista)])
	if lista != esperados:
		_fallo("%s: sus esperas son %s y deberían ser %s" % [h, lista, esperados])
	var huesos: int = c.skel.get_bone_count()
	for n in e.clips:
		var a: Animation = ap.get_animation(e.BIBLIOTECA + "/" + n)
		var claves := 0
		for t in a.get_track_count():
			claves += a.track_get_key_count(t)
		print("CLIP %s %s: %.2f s, %d pistas (%d huesos), %d claves, bucle %s" % [h, n, a.length, a.get_track_count(),
			huesos, claves, a.loop_mode != Animation.LOOP_NONE])
		if a.length < DURACION.x or a.length > DURACION.y:
			_fallo("%s %s dura %.2f s" % [h, n, a.length])
		if a.get_track_count() > huesos * 2:
			_fallo("%s %s: %d pistas para %d huesos" % [h, n, a.get_track_count(), huesos])
		if claves > CLAVES_MAX:
			_fallo("%s %s: %d claves (como mucho %d)" % [h, n, claves, CLAVES_MAX])
		if a.loop_mode != Animation.LOOP_NONE:
			_fallo("%s %s va en bucle" % [h, n])
	# su reposo de exploración (Garon: la guardia tranquila, como en grupo_3d.gd)
	if h == "Garon":
		var lib: AnimationLibrary = ap.get_animation_library("")
		if not lib.has_animation("Calma"):
			var calma: Animation = c._guardia_viva("Juicio")
			calma.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation("Calma", calma)
		c.play("Calma", 0.0)
	else:
		c.reposo()
	await _segundos(0.5)
	var reposo := String(ap.current_animation)
	var gestos_reposo := _gestos_puestos(c)
	# cada espera, de principio a fin: vuelve a su reposo con sus gestos
	for n in e.clips:
		e.forzar(n)
		await _esperar(2)
		if e.actual != n or String(ap.current_animation) != e.BIBLIOTECA + "/" + n:
			_fallo("%s: forzar(%s) no la pone" % [h, n])
			continue
		if c.vara != null and c.vara_mano < 0.5:
			await _segundos(0.2)
			if c.vara_mano < 0.99:
				_fallo("%s: el cetro no va con la mano durante la espera" % h)
		var a: Animation = ap.get_animation(e.BIBLIOTECA + "/" + n)
		await _segundos(a.length + 0.6)
		if e.actual != "" or String(ap.current_animation) != reposo:
			_fallo("%s: tras %s está en «%s» (debería volver a «%s»)" % [h, n, ap.current_animation, reposo])
		if _gestos_puestos(c) != gestos_reposo:
			_fallo("%s: tras %s sus gestos son %s (antes %s)" % [h, n, _gestos_puestos(c), gestos_reposo])
		if c.vara != null and c.vara_mano > 0.01:
			_fallo("%s: el cetro sigue con la mano tras %s" % [h, n])
	# se disparan solas al estar quieto, sin repetirse seguidas
	var vistas: Array = []
	for vez in 6:
		e.proxima = 0.4
		e.t_quieto = 0.0
		e.olvidar_turno()
		var empezo := false
		for i in 45:
			await process_frame
			if e.actual != "":
				empezo = true
				break
		if not empezo:
			_fallo("%s: quieto no empieza ninguna espera (vez %d)" % [h, vez])
			break
		vistas.append(e.actual)
		await _segundos(0.6)
		# se corta al moverse: marcha() como en la exploración
		if vez % 2 == 0:
			c.marcha(4.2)
			await _esperar(2)
			if e.actual != "":
				_fallo("%s: andar no corta la espera" % h)
			if c.marcha_actual() == "":
				_fallo("%s: tras cortar la espera no anda" % h)
			print("CORTE %s: andando corta «%s» → «%s»" % [h, vistas[-1], ap.current_animation])
			c.parar_marcha()
			if h == "Garon":
				c.play("Calma", 0.3)
		else:
			c.reposo()                                # otra animación cualquiera también la corta
			await _esperar(2)
			if e.actual != "":
				_fallo("%s: reposo() no corta la espera" % h)
			if h == "Garon":
				c.play("Calma", 0.3)
		await _segundos(0.5)
		if _gestos_puestos(c) != gestos_reposo and h != "Garon":
			_fallo("%s: tras cortar, sus gestos son %s (antes %s)" % [h, _gestos_puestos(c), gestos_reposo])
	print("SEGUIDAS %s: %s" % [h, ", ".join(vistas)])
	for i in range(1, vistas.size()):
		if vistas[i] == vistas[i - 1]:
			_fallo("%s repite «%s» dos veces seguidas" % [h, vistas[i]])
	c.queue_free()
	await _esperar(3)


func _gestos_puestos(c) -> Dictionary:
	var r := {}
	for k in c.gestos.objetivo:
		if c.gestos.objetivo[k] > 0.001:
			r[k] = snappedf(c.gestos.objetivo[k], 0.01)
	return r


# En combate nadie llama a activar_esperas(): quieto mucho rato, sigue en su reposo.
func _combate_sin_esperas() -> void:
	var c = load(HEROES["Kael"]).new()
	root.add_child(c)
	await _esperar(6)
	c.reposo()
	await _segundos(12.0)
	if c.esperas != null or String(c.anim.current_animation).begins_with("esperas/"):
		_fallo("Kael hace esperas sin activarlas (combate)")
	else:
		print("COMBATE: sin esperas tras 12 s quieto")
	c.queue_free()
	await _esperar(3)


# ================================================================= 3. en la región

func _region() -> void:
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # Lya y Garon en el grupo; sin escenas
	for m in ["grupo_activo", "calidad_extra"]:
		if Engine.has_meta(m):
			Engine.remove_meta(m)
	change_scene_to_file(REGION)
	var r = null
	for i in 600:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null:
			r = current_scene
			break
	if r == null:
		_fallo("no se llega a Pastos Verdes")
		return
	await _esperar(20)
	if fotos != "":
		r.distancia = 9.0                                    # el zoom más cercano del juego
		r.info.get_parent().visible = false                  # sin el panel de pruebas
		r.objetivo.get_parent().visible = false
	var cuerpos := {"Kael": r.kael}
	if r.grupo != null:
		for m in r.grupo.miembros:
			cuerpos[m["nombre"]] = m["nodo"]
	if cuerpos.size() < 3:
		_fallo("en la región no están los tres (%s)" % [cuerpos.keys()])
	# quietos: cada uno, una espera; nunca dos empiezan a menos de SEPARACION_GRUPO
	var empiezos := {}
	var t := 0.0
	var n_foto := 0
	while t < 26.0 and (empiezos.size() < cuerpos.size() or (fotos != "" and t < 24.0)):
		if fotos != "" and n_foto % 10 == 0:
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_jpg(fotos.path_join("region_%04d.jpg" % n_foto), 0.9)
		else:
			await process_frame
		n_foto += 1
		t += DT
		for n in cuerpos:
			var e = cuerpos[n].get("esperas")
			if e == null:
				continue
			if e.actual != "" and not empiezos.has(n):
				empiezos[n] = [t, e.actual]
				print("REGIÓN: %s empieza «%s» a los %.1f s quieto" % [n, e.actual, t])
	for n in cuerpos:
		if cuerpos[n].get("esperas") == null:
			_fallo("REGIÓN: %s no tiene esperas" % n)
		elif not empiezos.has(n):
			_fallo("REGIÓN: %s no hace ninguna espera en 26 s quieto" % n)
		elif empiezos[n][0] < 5.9:
			_fallo("REGIÓN: %s empieza su espera demasiado pronto (%.1f s)" % [n, empiezos[n][0]])
	var tiempos: Array = empiezos.values().map(func(x): return x[0])
	tiempos.sort()
	for i in range(1, tiempos.size()):
		if tiempos[i] - tiempos[i - 1] < 2.9:
			_fallo("REGIÓN: dos esperas empiezan a la vez (%.1f y %.1f s)" % [tiempos[i - 1], tiempos[i]])
	# Kael anda con el stick: se cortan todas (los acompañantes, al echar a andar tras él)
	var alguna := false
	for n in cuerpos:
		if cuerpos[n].esperas != null and cuerpos[n].esperas.actual != "":
			alguna = true
	if not alguna:
		cuerpos["Kael"].esperas.forzar()
	Input.action_press("ui_left", 1.0)
	await _segundos(2.5)
	Input.action_release("ui_left")
	for n in cuerpos:
		var e = cuerpos[n].esperas
		if e != null and e.actual != "":
			_fallo("REGIÓN: %s sigue con «%s» después de andar" % [n, e.actual])
		print("REGIÓN: tras andar, %s en «%s»" % [n, cuerpos[n].anim.current_animation])
