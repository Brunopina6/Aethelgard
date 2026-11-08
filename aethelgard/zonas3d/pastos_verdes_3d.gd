extends "res://prototipos/sendero_puente.gd"
# Pastos Verdes en 3D: la primera región jugable de la exploración 3D (rama experimental rebelum-alpha).
#
# Solo se llega con la exploración 3D activa (modo3d.gd): el mapa muestra Pastos Verdes como lugar 10 y entra
# aquí. Sin ella, el juego es el de siempre. El escenario es el del prototipo (prototipos/sendero_puente.gd: camino,
# puente, río, cascada, árboles, hierba, faroles y fauna) y la región cumple el contrato de una zona 2D (zona.gd):
#   - encuentros por pasos con progreso.gd y combate con vuelta (escena_retorno) al mismo sitio;
#   - guardado automático al entrar, tras cada combate (combate.gd), tras cada escena de la misión y al pausar o
#     cerrar la app (guardar_posicion);
#   - salida al mapa por los dos extremos del camino, que se marcan en el suelo.
# Misión del corte alfa (biblia v3 §6, aprobado como alfa, no canon): PV-02 al entrar, PV-03 en el camino, Tilo
# junto al puente (PV-05 y su recordatorio), la estela del camino (detalle de lore), el centinela del mirador
# (PV-06 y combate fijo «pastos_centinela»), PV-07 tras ganarlo y la mecha de Tilo (PV-14). Los hitos se guardan en
# la partida (progreso.gd, «hitos»).
# Pendiente (TASKS.md, T-022): Lya y Garon siguiendo a Kael, el cofre y la cinemática del mirador.

const INDICE := 10                       # lugar del mapa (modo3d.PASTOS_VERDES y mapa.gd, LUGAR_PASTOS)
const ZONA := "llanura"                  # para progreso.gd (zona limpia, incienso) y el fondo del combate
const LONG_PASO := 0.5                   # metros andados por cada «paso» de los encuentros
const PASOS_MIN := 40                    # pasos seguros al entrar (como zona.gd)
const PROB_ENCUENTRO := 0.012            # como zona.gd
const RADIO_SALIDA := 1.3                # metros: al llegar tan cerca de una salida, se vuelve al mapa
const ARMAR_SALIDA := 2.5                # una salida solo funciona después de alejarse de ella esta distancia
# Bancos del prototipo que no sirven en la región (experimentos de árboles y del perfil medio). PRUEBA y TOPE se
# quedan: miden la región en el móvil igual que se midió el prototipo.
const BOTONES_BANCO := ["DIAG", "ARB"]

# misión
const ESPERA_PV02 := 2.5                 # segundos tras entrar (deja ver el título de la zona)
const RADIO_PV03 := 3.5
const CENTINELA := Vector3(2.6, 0, -10.5) # la estatua del guardián en el mirador (sendero_puente.gd)
const RADIO_CENTINELA := 4.5
const COMBATE_CENTINELA := "pastos_centinela"
const GRUPO_CENTINELA := 0               # combate.gd, GRUPOS[0]: dos Grimfang («Quietos. Dos.», PV-06)
const RADIO_ACCION := 2.2                # metros para hablar o examinar
const ID_ESTELA := "pastos_estela"       # progreso.gd, DETALLES[10]

var pasos := 0
var saliendo := false
var salidas: Array = []                  # [{"pos": Vector3, "armada": bool}]
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var tilo: Node3D
var estela: Node3D
var cerca := ""                          # "tilo", "estela" o ""
var dialogo_actual := ""
var _recorrido := 0.0                    # metros andados desde el último paso
var _ultima := Vector3.ZERO
var _t_entrada := 0.0
var _bloqueo_accion := 0.0               # tras un diálogo, la misma pulsación no vuelve a abrir otro
var _centinela_armado := true


func _ready() -> void:
	super()                              # escenario, Kael al principio del camino, cámara, fauna y título
	info.visible = false                 # la ayuda de teclas del prototipo no es para el juego
	_crear_interfaz()
	_crear_salidas()
	_crear_personajes()
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and Engine.get_meta("pos_3d_lugar", -1) == INDICE
	if vuelve and not en_banco():
		_colocar_kael(Engine.get_meta("pos_3d"))       # vuelve del combate o de una partida guardada aquí
	_ultima = kael.global_position
	for s in salidas:
		s["armada"] = _dist_plana(kael.global_position, s["pos"]) > ARMAR_SALIDA
	# si se vuelve de perder contra el centinela, no se repite hasta alejarse y volver
	_centinela_armado = _dist_plana(kael.global_position, CENTINELA) > RADIO_CENTINELA
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
	Engine.set_meta("zona", ZONA)
	if not en_banco():
		load("res://progreso.gd").guardar(scene_file_path)   # guardado automático al entrar (como zona.gd)


# Banco de medida en marcha (botones PRUEBA y TOPE de vista3d.gd): la escena se recarga en cada caso y Kael recorre
# la ruta del banco desde el principio del camino, sin encuentros, misión, salidas ni guardado.
func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


func _colocar_kael(p: Vector3) -> void:
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	_colocar_camara(1.0)


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# El panel del prototipo trae botones de bancos de medida. En la región solo quedan CAL (perfil de calidad) y
# RND (rendimiento), útiles mientras la exploración 3D sea experimental.
func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in BOTONES_BANCO:
			n.queue_free()


# Al cambiar de perfil se recarga la escena: antes se apunta dónde está Kael para no volver al principio.
func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


func _process(delta: float) -> void:
	_t_entrada += delta
	_bloqueo_accion = maxf(0.0, _bloqueo_accion - delta)
	if en_banco():
		boton_accion.visible = false
		super(delta)
		if is_inside_tree():             # al acabar cada caso, el banco recarga la escena dentro de super()
			_ultima = kael.global_position
		return
	if ocupado():                        # diálogo abierto: Kael quieto y sin pasos
		_parar_kael()
		boton_accion.visible = false
		return
	super(delta)
	if saliendo or kael == null:
		return
	var p := kael.global_position
	var d := _dist_plana(p, _ultima)
	_ultima = p
	if d < 2.0:                          # un salto grande (recolocación) no cuenta como andar
		_recorrido += d
		while _recorrido >= LONG_PASO and not saliendo:
			_recorrido -= LONG_PASO
			_paso()
	if saliendo:
		return
	for s in salidas:
		var dist := _dist_plana(p, s["pos"])
		if not s["armada"]:
			s["armada"] = dist > ARMAR_SALIDA
		elif dist < RADIO_SALIDA:
			_salir()
			return
	_comprobar_mision()
	_comprobar_cerca()


func _unhandled_input(ev: InputEvent) -> void:
	if ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return dg != null and dg.current_timeline != null


func _parar_kael() -> void:
	destino = null
	if movimiento != "":
		movimiento = ""
		kael.reposo()


# ================================================================= encuentros

func _paso() -> void:
	pasos += 1
	var prog = load("res://progreso.gd")
	if prog.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	# progreso.gd: pasos seguros, luego sube despacio; casi nada si la zona está «limpia» o con incienso
	if randf() < prog.prob_encuentro(PROB_ENCUENTRO, pasos, PASOS_MIN, ZONA):
		_encuentro()


func _encuentro(fijo := "", grupo := -1) -> void:
	if saliendo:
		return
	saliendo = true
	guardar_posicion()                   # el combate vuelve aquí, al mismo sitio
	Engine.set_meta("zona", ZONA)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("escena_retorno", scene_file_path)
	if fijo != "":                       # combate fijo: ese grupo y, al ganarlo, no se repite (combate.gd)
		Engine.set_meta("grupo_combate", grupo)
		Engine.set_meta("combate_fijo", fijo)
	_mostrar_aviso("¡Emboscada!" if fijo == "" else "¡Al centinela!")
	fundido.color = Color(1, 1, 1, 0)
	var t := create_tween()
	for i in 3:
		t.tween_property(fundido, "color:a", 0.85, 0.07)
		t.tween_property(fundido, "color:a", 0.0, 0.07)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


# ================================================================= misión del corte alfa (PV-02 a PV-14)

func _comprobar_mision() -> void:
	var P = load("res://progreso.gd")
	var p := kael.global_position
	if not P.hito("pv_02"):
		if _t_entrada >= ESPERA_PV02:
			_escena_mision("pv_02")
		return
	if not P.hito("pv_03") and _dist_plana(p, SENDERO[2]) < RADIO_PV03:
		_escena_mision("pv_03")
		return
	var en_mirador := _dist_plana(p, CENTINELA) < RADIO_CENTINELA
	if not en_mirador:
		_centinela_armado = true
		return
	if not P.hito("pv_05"):
		return                           # sin hablar antes con Tilo, el mirador es solo un mirador
	if not P.ganado(COMBATE_CENTINELA):
		if _centinela_armado:
			_centinela_armado = false
			_escena_mision("pv_06")      # al terminar, el combate fijo (_al_terminar_dialogo)
	elif not P.hito("pv_07"):
		_escena_mision("pv_07")


# Pone el hito y abre su diálogo. Sin Dialogic, el hito se pone igual (la misión no se atasca).
func _escena_mision(id: String) -> void:
	load("res://progreso.gd").poner_hito(id)
	if not _empezar_dialogo(id):
		_tras_dialogo(id)


func _empezar_dialogo(nombre: String) -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or dg.current_timeline != null:
		return false
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = nombre
	dg.start(nombre)
	return true


func _al_terminar_dialogo() -> void:
	var id := dialogo_actual
	dialogo_actual = ""
	_bloqueo_accion = 0.35
	_tras_dialogo(id)


func _tras_dialogo(id: String) -> void:
	var P = load("res://progreso.gd")
	match id:
		"pv_06":
			_encuentro(COMBATE_CENTINELA, GRUPO_CENTINELA)
			return
		"pv_14":
			P.poner_hito("mecha_tilo")
			_mostrar_aviso("Tilo te da una mecha de su farol.")
	if id.begins_with("pv_"):
		guardar_posicion()
		P.guardar(scene_file_path)       # la misión avanza: se guarda (no hace nada en las pruebas)


# ================================================================= acción: hablar y examinar

func _comprobar_cerca() -> void:
	var p := kael.global_position
	cerca = ""
	if tilo != null and _dist_plana(p, tilo.global_position) < RADIO_ACCION:
		cerca = "tilo"
		boton_accion.text = "Hablar con Tilo"
	elif estela != null and _dist_plana(p, estela.global_position) < RADIO_ACCION:
		cerca = "estela"
		boton_accion.text = "Examinar"
	boton_accion.visible = cerca != ""


func _accion() -> void:
	if _bloqueo_accion > 0.0 or ocupado() or saliendo:
		return
	var P = load("res://progreso.gd")
	match cerca:
		"tilo":
			_mirar_a(tilo, kael.global_position)
			if not P.hito("pv_05"):
				_escena_mision("pv_05")
			elif not P.ganado(COMBATE_CENTINELA):
				_empezar_dialogo("pv_tilo")
			elif not P.hito("pv_14"):
				_escena_mision("pv_14")
			else:
				_empezar_dialogo("pv_tilo_fin")
		"estela":
			var d: Dictionary = P.detalles_de(INDICE)[0]
			_mostrar_aviso(d["texto"], 4.0)
			var acto: Dictionary = P.ver_detalle(ID_ESTELA)
			if not acto.is_empty():
				get_tree().create_timer(4.6).timeout.connect(func():
					if is_instance_valid(self):
						_mostrar_aviso("Nueva página en el Diario: «%s»" % acto["escena"]))


func _mirar_a(n: Node3D, objetivo: Vector3) -> void:
	var dir := objetivo - n.global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		n.rotation.y = atan2(dir.x, dir.z)


# ================================================================= personajes y objetos de la región

# Un sitio a un lado del camino (ni encima de él ni en el río) cerca de «c».
func _sitio_junto_al_camino(c: Vector3) -> Vector3:
	for r in [0.0, 0.8, 1.6, 2.4, 3.2]:
		for k in 8:
			var a := TAU * k / 8.0
			var q: Vector3 = c + Vector3(cos(a), 0, sin(a)) * r
			var ds := _dist_sendero(q)
			if ds > 1.7 and ds < 3.2 and not _prohibido(q):
				return Vector3(q.x, altura(q.x, q.z), q.z)
	return Vector3(c.x, altura(c.x, c.z), c.z)


func _crear_personajes() -> void:
	tilo = _crear_tilo(_sitio_junto_al_camino(Vector3(2.8, 0, -4.2)))
	estela = _crear_estela(_sitio_junto_al_camino(Vector3(-6.5, 0, 6.0)))


func _mat_simple(c: Color, brillo := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if brillo:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _pieza(padre: Node3D, malla: Mesh, mat: Material, pos: Vector3, giro := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	mi.position = pos
	mi.rotation = giro
	padre.add_child(mi)
	return mi


# Tilo, el farolero (personaje provisional, aprobado para la alfa): figura sencilla con abrigo, sombrero y la
# pértiga con el farol encendido. Respira despacio. Kael no lo atraviesa.
func _crear_tilo(p: Vector3) -> Node3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p
	add_child(cuerpo)
	var figura := Node3D.new()
	cuerpo.add_child(figura)
	var abrigo := CapsuleMesh.new()
	abrigo.radius = 0.27
	abrigo.height = 1.25
	_pieza(figura, abrigo, _mat_simple(Color(0.47, 0.32, 0.2)), Vector3(0, 0.63, 0))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.17
	cabeza.height = 0.34
	_pieza(figura, cabeza, _mat_simple(Color(0.95, 0.8, 0.68)), Vector3(0, 1.42, 0))
	var barba := SphereMesh.new()
	barba.radius = 0.12
	barba.height = 0.2
	_pieza(figura, barba, _mat_simple(Color(0.9, 0.9, 0.86)), Vector3(0, 1.32, 0.1))
	var sombrero := CylinderMesh.new()
	sombrero.top_radius = 0.06
	sombrero.bottom_radius = 0.24
	sombrero.height = 0.34
	_pieza(figura, sombrero, _mat_simple(Color(0.2, 0.35, 0.22)), Vector3(0, 1.68, 0))
	var vara := CylinderMesh.new()
	vara.top_radius = 0.02
	vara.bottom_radius = 0.025
	vara.height = 2.0
	_pieza(figura, vara, _mat_simple(Color(0.42, 0.3, 0.18)), Vector3(0.36, 1.0, 0.05))
	var farol := SphereMesh.new()
	farol.radius = 0.09
	farol.height = 0.18
	_pieza(figura, farol, _mat_simple(Color(1.0, 0.85, 0.45), true), Vector3(0.36, 2.05, 0.05))
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.4
	cil.height = 1.8
	col.shape = cil
	col.position.y = 0.9
	cuerpo.add_child(col)
	_mirar_a(cuerpo, kael.global_position)
	var t := figura.create_tween().set_loops()
	t.tween_property(figura, "position:y", 0.025, 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(figura, "position:y", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	return cuerpo


# La estela del camino: losa de piedra con el anillo partido tallado (detalle de lore de progreso.gd).
func _crear_estela(p: Vector3) -> Node3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p
	add_child(cuerpo)
	var piedra := _mat_detalle(Color(0.62, 0.6, 0.56), 0.8, false, 1.0)
	var losa := BoxMesh.new()
	losa.size = Vector3(0.6, 1.5, 0.24)
	_pieza(cuerpo, losa, piedra, Vector3(0, 0.75, 0))
	var anillo := TorusMesh.new()
	anillo.inner_radius = 0.13
	anillo.outer_radius = 0.19
	_pieza(cuerpo, anillo, _mat_detalle(Color(0.4, 0.38, 0.36), 0.8, false, 1.0), Vector3(0, 1.05, 0.12), Vector3(PI / 2, 0, 0))
	var grieta := BoxMesh.new()
	grieta.size = Vector3(0.05, 0.16, 0.06)
	_pieza(cuerpo, grieta, _mat_simple(Color(0.25, 0.24, 0.23)), Vector3(0.14, 1.12, 0.14), Vector3(0, 0, 0.5))
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(0.7, 1.5, 0.4)
	col.shape = caja
	col.position.y = 0.75
	cuerpo.add_child(col)
	_mirar_a(cuerpo, Vector3(SENDERO[2].x, p.y, SENDERO[2].z))
	return cuerpo


# ================================================================= guardado y salidas

# Recursos la llama al pausar o cerrar la app (y antes de guardar), para volver justo aquí.
func guardar_posicion() -> void:
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_3d_ok", false)  # la próxima vez se entra por el principio del camino
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena(load("res://progreso.gd").MAPA)


# Una salida en cada extremo del camino: la del principio, un poco más allá del sitio donde se entra, y la del
# final del sendero. Se marcan con un círculo dorado y un letrero que mira siempre a la cámara.
func _crear_salidas() -> void:
	var a: Vector3 = SENDERO[0]
	var hacia_fuera: Vector3 = (SENDERO[0] - SENDERO[1]).normalized()
	for p in [a + hacia_fuera * 3.0, SENDERO[SENDERO.size() - 1]]:
		var suelo := Vector3(p.x, altura(p.x, p.z), p.z)
		salidas.append({"pos": suelo, "armada": false})
		_marca_salida(suelo)


func _marca_salida(p: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.88, 0.5, 0.35)
	var disco := CylinderMesh.new()
	disco.top_radius = RADIO_SALIDA
	disco.bottom_radius = RADIO_SALIDA
	disco.height = 0.02
	disco.radial_segments = 32
	var mi := MeshInstance3D.new()
	mi.mesh = disco
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p + Vector3(0, 0.06, 0)
	add_child(mi)
	var letrero := Label3D.new()
	letrero.text = "Mapa del mundo"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 48
	letrero.outline_size = 12
	letrero.modulate = Color(1.0, 0.96, 0.85)
	letrero.outline_modulate = Color(0.2, 0.15, 0.08, 0.8)
	letrero.pixel_size = 0.01
	letrero.position = p + Vector3(0, 2.2, 0)
	add_child(letrero)


# ================================================================= pantalla

func _crear_interfaz() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 50
	add_child(capa)
	boton_accion = Button.new()
	boton_accion.position = Vector2(980, 600)
	boton_accion.custom_minimum_size = Vector2(270, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa.add_child(boton_accion)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 100)
	aviso.position = Vector2(140, 500)
	aviso.add_theme_font_size_override("font_size", 30)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	aviso.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.08, 0.85))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.modulate.a = 0.0
	capa.add_child(aviso)
	fundido = ColorRect.new()            # el último: tapa también el botón y el aviso al fundir a negro
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(fundido)


func _mostrar_aviso(texto: String, segundos := 1.6) -> void:
	aviso.text = texto
	var t := create_tween()
	t.tween_property(aviso, "modulate:a", 1.0, 0.2)
	t.tween_interval(segundos)
	t.tween_property(aviso, "modulate:a", 0.0, 0.5)
