extends "res://invocacion_erebo.gd"
# T-101: la invocación NUEVA de Érebo («Ladrón de Corazones»), variante que se elige en Ajustes. La de siempre
# (invocacion_erebo.gd) sigue intacta y es la que sale por defecto.
#
# Sigue docs/erebo/invocacion_erebo_cinematica.md (P1-P11, ≈11,8 s; fallo ≈9 s) con las recomendaciones de D1-D12 que
# siguen abiertas (T-072), como variante experimental:
#   D6 emerge 0,3 m atrás y se acerca flotando · D7 surge con la pose quieta · D8 levita 5 cm y su escala es al menos ×1
#   D4 el contacto se ve por detrás de su hombro derecho · D2 un solo clip, «Extraer», con la mano abierta.
# Y conserva el arreglo medido en la Fase 1: Érebo se coloca POR LA MANO (la punta de su mano derecha, en el contacto,
# cae en el pecho real del enemigo), con su escala y una IK de alcance que corrige lo que quede.
# Kael y Lya reaccionan con gestos propios (Kael, protector, se pone en guardia y aparta la cara al estallar; Lya
# sostiene el conjuro y, al acabar, respira hondo).
# Nada del acto III: el orbe va vacío, sin hilos cálidos ni reverencia, y el título es «Ladrón de Corazones».
# Las reglas no cambian (las de invocacion_erebo.gd): mismo dado (randf una vez, salvo jefes), el resultado se aplica
# UNA vez en el fotograma en que se cierran las palmas (o al saltar), y tocar la pantalla la salta.

const AJUSTES := "user://ajustes.cfg"
const SECCION := "combate"
const CLAVE := "erebo_nueva"
const PROFUNDIDAD := 0.133         # torso delante del Spine2 × alto (Grimfang, medido en el plan final §1.3)
const T_CONTACTO := 0.80           # «Extraer»: la mano abierta llega al máximo (plan final §1.2)

var kael: Node3D                   # Kael mirando (lo crea esta invocación si ctx.kael es true)
var _luces := []                   # [luz, energía] para devolverlas al acabar o al saltar
var _ambiente: Environment
var _amb0 := 0.0
var _tw_luces: Array = []


# ---------------------------------------------------------------- Ajustes: cuál se ve

static func elegida() -> bool:
	for a in OS.get_cmdline_user_args():           # pruebas: -- erebo_nueva / erebo_actual
		if a == "erebo_nueva":
			return true
		if a == "erebo_actual":
			return false
	var c := ConfigFile.new()
	return c.load(AJUSTES) == OK and bool(c.get_value(SECCION, CLAVE, false))


static func elegir(si: bool) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		var err := c.load(AJUSTES)
		if err != OK:
			return err
	c.set_value(SECCION, CLAVE, si)
	return c.save(AJUSTES)


# ---------------------------------------------------------------- la secuencia

func _secuencia(ctx: Dictionary) -> void:
	_invocador = ctx.invocador
	_objetivo = ctx.objetivo
	var es_jefe: bool = ctx.get("es_jefe", false)
	var exito: bool = es_jefe or randf() < PROB_MUERTE          # el mismo dado que la de siempre
	if ctx.has("forzar"):
		exito = es_jefe or ctx.forzar == "exito"
	resultado = {"exito": exito, "muerte": exito and not es_jefe, "dano_pct_actual": DANO_JEFE if es_jefe else (1.0 if exito else 0.0)}
	await _preparar(ctx)
	if ctx.get("kael", false):
		await _crear_kael()
	_guardar_luces()

	# anclas: L (pies de Lya), N (enemigo), u (del enemigo hacia Lya), lados A (el de la cámara) y B
	var pies: Vector3 = _invocador.global_position
	var n: Vector3 = _objetivo.global_position
	var u: Vector3 = pies - n
	u.y = 0.0
	u = u.normalized()
	var lado_a: Vector3 = u.cross(Vector3.UP).normalized()
	if camara != null and lado_a.dot(camara.global_position - n) < 0.0:
		lado_a = -lado_a
	var lado_b := -lado_a
	_lado = lado_a
	_hacia = u
	var arriba := Vector3.UP

	# colocación POR LA MANO: el pecho real del enemigo, la punta de la mano en el contacto y la escala
	var pecho := _pecho(_objetivo, u)
	var objetivo_mano := pecho - u * 0.05                       # 5 cm dentro
	erebo.global_position = n + u * 0.95
	erebo.mirar(-u, 0.0)
	var o: Vector3 = erebo.punta_en("Extraer", T_CONTACTO)       # (adelante, arriba, derecha) a escala 1
	var k := clampf((pecho.y - n.y) / maxf(o.y, 0.01), 0.8, 1.6)
	if pecho.y - n.y >= 0.7:
		k = maxf(k, 1.0)
	erebo.scale = Vector3.ONE * k
	var der_e := (-u).cross(Vector3.UP).normalized()             # la derecha de Érebo (mira a -u)
	var e1 := objetivo_mano - (-u) * o.x * k - der_e * o.z * k
	e1.y = n.y
	var e0 := e1 + u * 0.3
	erebo.global_position = e0
	erebo.mano_objetivo = objetivo_mano
	_e1 = e1

	# P1 · El bastón (0-1,0 s): Lya alza el cetro, la luz baja, Kael se vuelve hacia ella
	if _invocador.has_method("lanzar_magia"):
		_invocador.lanzar_magia()
	_kael_gesto("mirar", pies)
	sonar(SND % "susurros", -8.0)
	_bajar_luz(0.6, 0.7)
	plano(pies + lado_a * 2.4 - u * 0.4 + arriba * 1.0, pies + arriba * 1.1, 0.0, 40.0)
	plano(pies + lado_a * 2.1 - u * 0.4 + arriba * 1.0, pies + arriba * 1.15, 0.9, 36.0)
	await esperar(0.9)
	if saltada(): return

	# P2 · La sombra se desprende (1,0-1,9 s): cámara a ras de suelo que la sigue
	_apagar_sombra(_invocador)
	sonar(SND % "sombra", -3.0)
	plano(pies + lado_a * 0.9 + arriba * 0.25 - u * 0.2, pies - u * 0.6, 0.0, 50.0)
	plano(n + u * 1.2 + lado_a * 0.9 + arriba * 0.25, n + u * 0.6, 0.8, 50.0)
	_alerta(0.5)
	await _hasta_fin(sombra.viajar.bind(pies, e0, 0.8))
	if saltada(): return

	# P3 · El suelo cede (1,9-2,5 s): junto al enemigo, el pozo en el centro
	plano(n + lado_a * 0.8 - u * 0.4 + arriba * 0.35, e0 + arriba * 0.1, 0.0, 46.0)
	sacudir(0.015, 0.6)
	_alerta(1.0)
	sombra.ocultar(0.4)
	evento.emit("invocacion")                                   # el título
	await esperar(0.6)
	if saltada(): return

	# P4 · Emerge (2,5-4,4 s): grúa que orbita 140° del lado A al B mientras sube con la pose quieta
	_orbitar(e0, lado_a, lado_b, u, 1.9)
	_kael_gesto("guardia", e0)
	_objetivo_mira(e0)
	await _hasta_fin(erebo.emerger_quieto.bind(1.9, 0.05))
	if saltada(): return

	# P5 · Presencia (4,4-5,1 s): por encima del hombro del enemigo, la máscara arriba
	var mascara: Vector3 = e0 + arriba * 1.25 * k
	plano(n - u * 0.9 + lado_b * 0.85 + arriba * 0.85, mascara, 0.0, 45.0)
	plano(n - u * 0.8 + lado_b * 0.8 + arriba * 0.85, mascara, 0.6, 45.0)
	sonar(SND % "pulso", -4.0, 0.8)
	await esperar(0.6)
	if saltada(): return

	# P6 · Inevitable (5,1-5,9 s) y P7 · La mano entra: por detrás de su hombro derecho, se acerca y mete la mano
	var hombro := e1 + der_e * 0.9 * k + u * 0.55 * k + arriba * 1.05 * k
	plano(hombro + u * 0.2, objetivo_mano, 0.0, 34.0)
	plano(hombro, objetivo_mano, 1.2, 30.0)
	erebo.deslizar(e1, 0.8)
	var medio := (pecho + e1 + arriba * 0.9) * 0.5
	_plano_p8 = [medio + lado_b * 2.4, medio]                 # P8: al agarrar, corte al plano lateral (_al_contacto)
	var exito_mano := exito
	await _hasta_fin(erebo.extraer_abierto.bind(exito_mano, 1.2, _al_contacto.bind(pecho)))
	if saltada(): return

	if not exito:
		# fallo: la mano sale vacía; Érebo se queda quieto un momento y se hunde
		evento.emit("fallo")
		_aplicar_resultado()
		_kael_gesto("fallo", Vector3.ZERO)
		_lya_gesto("fallo")
		await esperar(0.4)
		if saltada(): return
		await _salida_nueva(pies)
		return

	# P8 · Arrancar (6,8-8,2 s) ya ha pasado dentro de extraer_abierto, con el plano lateral; se aparta con el orbe
	var e2 := e1 + u * 0.6
	erebo.deslizar(e2, 0.7)
	erebo.mirar((-u + lado_a * 1.4).normalized(), 0.5)          # se vuelve hacia la cámara para presentar el orbe
	await esperar(0.2)                                          # (se aparta mientras empieza el latido)
	if saltada(): return

	# P9 · El latido: de frente a la máscara, tres latidos y silencio; P10 · Fractura (_al_estallar)
	var ante := e2 + arriba * 0.85 * k
	plano(e2 + lado_a * 2.0 * k + u * 0.25 + arriba * 1.0 * k, ante, 0.0, 34.0)
	await _hasta_fin(erebo.aplastar.bind(_al_estallar, [0.32, 0.28, 0.24], 0.3, true))
	if saltada(): return
	await esperar(0.05)
	if saltada(): return

	# P11 · Calma: se hunde, la sombra vuelve, la cámara vuelve a la del teatro
	await _salida_nueva(pies)


var _e1 := Vector3.ZERO
var _plano_p8: Array = []


# El contacto: cámara lenta, pausa de impacto, onda en el pecho y el enemigo se arquea.
func _al_contacto(pecho: Vector3) -> void:
	sonar(SND % "pulso", 0.0)
	evento.emit("contacto")
	_onda_pecho(pecho)
	sacudir(0.02, 0.15)
	if _objetivo.has_method("herida"):
		_objetivo.herida()
	await congelar(0.35, 0.12)
	get_tree().create_timer(0.25).timeout.connect(func():     # los dedos se cierran dentro: corte al lateral (P8)
		if not saltada() and not _plano_p8.is_empty():
			plano(_plano_p8[0], _plano_p8[1], 0.0, 38.0)
			if resultado.get("exito", false):
				_vaciar())                                      # «vacío»: el enemigo se queda sin fuerzas mientras tira


func _al_estallar() -> void:
	sonar(SND % "fractura", 0.0)
	sonar(SND % "resonancia", -4.0)
	destello(Color(1.0, 0.8, 0.88, 0.4), 0.15)
	sacudir(0.06, 0.4)
	_aplicar_resultado()
	_kael_gesto("aparta", Vector3.ZERO)
	var l: Vector3 = erebo.global_position
	plano(l + _lado * 3.8 + _hacia * 0.5 + Vector3(0, 1.5, 0), l + Vector3(0, 0.9, 0), 0.0, 42.0)


func _salida_nueva(pies: Vector3) -> void:
	if camara != null:                                          # la cámara vuelve a la del teatro mientras se hunde
		if _cam_tw != null and _cam_tw.is_valid():
			_cam_tw.kill()
		_cam_tw = create_tween().set_parallel(true)
		_cam_tw.tween_property(camara, "global_transform", _cam_trans, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cam_tw.tween_property(camara, "fov", _cam_fov, 1.3)
	_lya_gesto("fin")
	_kael_gesto("fin", pies)
	_subir_luz(1.2)
	erebo.hundirse(true)                                         # (≈1,45 s: baja, se disuelve y se cierra el pozo)
	await esperar(0.4)
	if saltada(): return
	sonar(SND % "sombra", -8.0, 0.85)                           # la sombra vuelve a Lya mientras él se hunde
	await _hasta_fin(sombra.viajar.bind(erebo.global_position, pies, 0.6, true))
	if saltada(): return
	sombra.ocultar(0.25)
	await esperar(0.3)
	if saltada(): return
	_reponer_sombra()
	if _invocador.has_method("fin_magia"):
		_invocador.fin_magia()


# ---------------------------------------------------------------- cámara

# Grúa en órbita alrededor de «c», del lado A al lado B pasando por delante (140°), subiendo de 0,3 a 1,0 m.
func _orbitar(c: Vector3, lado_a: Vector3, lado_b: Vector3, u: Vector3, dur: float) -> void:
	if camara == null:
		return
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	camara.fov = 52.0
	var desde := lado_a
	var hasta := (lado_b + u * 0.8).normalized()
	var ang := desde.signed_angle_to(hasta, Vector3.UP)
	_cam_tw = create_tween()
	_cam_tw.tween_method(func(t: float):
		var e := t * t * (3.0 - 2.0 * t)
		var d := desde.rotated(Vector3.UP, ang * e)
		var pos := c + d * lerpf(1.6, 2.4, e) + Vector3(0, lerpf(0.3, 1.0, e), 0)
		camara.look_at_from_position(pos, c + Vector3(0, lerpf(0.5, 1.1, e), 0)), 0.0, 1.0, dur)


# ---------------------------------------------------------------- luz

func _guardar_luces() -> void:
	_luces.clear()
	var raiz: Node = _objetivo.get_parent()
	for l in raiz.find_children("*", "DirectionalLight3D", true, false):
		_luces.append([l, l.light_energy])
	var we = raiz.find_children("*", "WorldEnvironment", true, false)
	if not we.is_empty() and we[0].environment != null:
		_ambiente = we[0].environment
		_amb0 = _ambiente.ambient_light_energy


func _bajar_luz(factor: float, dur: float) -> void:
	for par in _luces:
		if is_instance_valid(par[0]):
			_luz_a(par[0], "light_energy", par[1] * factor, dur)
	if _ambiente != null:
		_luz_a(_ambiente, "ambient_light_energy", _amb0 * factor, dur)


func _subir_luz(dur: float) -> void:
	for par in _luces:
		if is_instance_valid(par[0]):
			_luz_a(par[0], "light_energy", par[1], dur)
	if _ambiente != null:
		_luz_a(_ambiente, "ambient_light_energy", _amb0, dur)


func _reponer_luces() -> void:
	for tw in _tw_luces:
		if tw != null and tw.is_valid():
			tw.kill()
	_tw_luces.clear()
	for par in _luces:
		if is_instance_valid(par[0]):
			par[0].light_energy = par[1]
	if _ambiente != null:
		_ambiente.ambient_light_energy = _amb0


# ---------------------------------------------------------------- el enemigo

# El pecho real: su hueso Spine2 (sigue la pose y la escala) y la profundidad del torso; sin esqueleto (dibujo 2D),
# a la altura de siempre.
func _pecho(o: Node3D, u: Vector3) -> Vector3:
	var sk = o.get("skel")
	var g = o.get("gestos")
	if sk != null and g != null and g.idx.get("pecho", -1) >= 0:
		var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(g.idx["pecho"]).origin
		var alto: float = _altura(o) * o.global_transform.basis.get_scale().y
		return p + u * PROFUNDIDAD * alto
	return o.global_position + Vector3(0, _altura(o) * 0.55, 0) + u * 0.1


func _alerta(cuanto: float) -> void:
	var g = _objetivo.get("gestos")
	if g != null and g.has_method("poner"):
		g.registrar("alerta_erebo", {"+columna": [Vector3(0, 0, -1), -6.0], "+cabeza": [Vector3(0, 0, -1), 10.0]})
		g.poner("alerta_erebo", cuanto, 0.3)


func _objetivo_mira(p: Vector3) -> void:
	if _objetivo.has_method("mirar"):
		var d := p - _objetivo.global_position
		d.y = 0.0
		if d.length() > 0.01:
			_objetivo.mirar(d.normalized(), 0.4)


func _vaciar() -> void:
	var g = _objetivo.get("gestos")
	if g != null and g.has_method("poner"):
		g.quitar("alerta_erebo", 0.3)
		g.poner("cansada", 1.0, 0.4)                            # «vacío»: el pecho cae, la cabeza baja


# ---------------------------------------------------------------- Kael y Lya

func _crear_kael() -> void:
	var raiz: Node = _objetivo.get_parent()
	kael = load("res://kael_3d.gd").new()
	kael.name = "KaelMira"
	raiz.add_child(kael)
	var pies: Vector3 = _invocador.global_position
	var u: Vector3 = (pies - _objetivo.global_position)
	u.y = 0.0
	u = u.normalized()
	var lado := u.cross(Vector3.UP).normalized()
	if camara != null and lado.dot(camara.global_position - pies) > 0.0:
		lado = -lado                                             # detrás de Lya, del lado lejos de la cámara
	kael.global_position = pies + u * 0.7 + lado * 0.9
	kael.mirar(-u, 0.0)
	for i in 3:
		await get_tree().process_frame
	var g = kael.gestos
	# guardia: medio paso atrás con el peso atrás y la cabeza alta (el sable sigue al hombro)
	g.registrar("k_guardia_erebo", {"+columna": [Vector3(0, 0, -1), -7.0], "+cabeza": [Vector3(0, 0, -1), -6.0],
		"brazo_i": [Vector3(0.55, -0.4, -0.5), 70], "antebrazo_i": [Vector3(0.6, 0.3, 0.2), 90]})
	# al estallar aparta la cara y se cubre con el antebrazo izquierdo (el del brazalete)
	g.registrar("k_aparta_erebo", {"+cabeza": [Vector3(0, 1, 0), 32.0], "+pecho": [Vector3(0, 1, 0), 10.0],
		"brazo_i": [Vector3(0.75, 0.35, -0.2), 130], "antebrazo_i": [Vector3(0.1, 1, 0.6), 150]})


func _kael_gesto(que: String, hacia: Vector3) -> void:
	if kael == null or not is_instance_valid(kael):
		return
	var g = kael.gestos
	match que:
		"mirar":
			var d := hacia - kael.global_position
			d.y = 0.0
			if d.length() > 0.05:
				kael.mirar(d.normalized(), 0.5)
		"guardia":
			var d := hacia - kael.global_position
			d.y = 0.0
			if d.length() > 0.05:
				kael.mirar(d.normalized(), 0.35)
			g.poner("k_guardia_erebo", 1.0, 0.35)
			var t := create_tween()
			t.tween_property(kael, "global_position", kael.global_position + _hacia * 0.22, 0.4).set_trans(Tween.TRANS_SINE)
		"aparta":
			g.poner("k_aparta_erebo", 1.0, 0.12)
			get_tree().create_timer(0.9).timeout.connect(func():
				if is_instance_valid(kael): kael.gestos.quitar("k_aparta_erebo", 0.5))
		"fallo":
			g.quitar("k_guardia_erebo", 0.4)
			if kael.activar_esperas():                       # resopla, impaciente (su propia espera)
				kael.esperas.pausa = true
				kael.esperas.forzar("espera_impaciencia")
		"fin":
			g.quitar("k_guardia_erebo", 0.6)
			var d := _invocador.global_position - kael.global_position
			d.y = 0.0
			if d.length() > 0.05:
				kael.mirar(d.normalized(), 0.6)                  # mira a Lya


func _lya_gesto(que: String) -> void:
	var g = _invocador.get("gestos")
	if g == null:
		return
	match que:
		"fallo":
			g.poner("cansada", 0.6, 0.4)                          # se le escapa el aire
			get_tree().create_timer(1.0).timeout.connect(func():
				if is_instance_valid(_invocador): _invocador.gestos.quitar("cansada", 0.6))
		"fin":
			g.registrar("l_respiro_erebo", {"+pecho": [Vector3(0, 0, -1), 6.0], "+cabeza": [Vector3(0, 0, -1), 10.0]})
			g.poner("l_respiro_erebo", 1.0, 0.5)                 # baja la cabeza y respira hondo
			get_tree().create_timer(1.1).timeout.connect(func():
				if is_instance_valid(_invocador): _invocador.gestos.quitar("l_respiro_erebo", 0.6))


func _al_saltar() -> void:
	super._al_saltar()
	_reponer_luces()
	if kael != null and is_instance_valid(kael):
		kael.queue_free()
		kael = null
	var g = _objetivo.get("gestos") if _objetivo != null else null
	if g != null and g.has_method("quitar"):
		g.quitar("alerta_erebo", 0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and kael != null and is_instance_valid(kael):
		kael.queue_free()


func _luz_a(obj: Object, prop: String, valor: float, dur: float) -> void:
	var t := create_tween()
	t.tween_property(obj, prop, valor, dur)
	_tw_luces.append(t)


# Espera a que acabe una corrutina de Érebo o de la sombra, o a que se salte la cinemática. Al saltar, limpiar() mata
# sus tweens y un «await tween.finished» ya no volvería nunca: así la invocación termina igual.
func _hasta_fin(c: Callable) -> void:
	var fin := {"si": false}
	var corre := func():
		await c.call()
		fin["si"] = true
	corre.call()
	while not fin["si"] and not saltada():
		await get_tree().process_frame
