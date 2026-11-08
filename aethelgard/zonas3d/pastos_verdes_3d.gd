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
# El grupo: Lya y Garon siguen a Kael (zonas3d/grupo_3d.gd) si están en el grupo de la partida (grupo.gd). Con
# «grupo»: false en el perfil de calidad no salen (lo usa el banco GRUPO para medir lo que cuestan).
# Pendiente (TASKS.md, T-022): el cofre y la cinemática del mirador.

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
# Botón «GRUPO»: lo que cuestan Lya y Garon en cada perfil, sin tope de FPS (sin grupo y con grupo, a 20 m), y el
# perfil bajo con el grupo y su tope de 30 FPS, como se jugará.
const BANCO_GRUPO := [["bajo", 20.0, false, {"grupo": false}, "bajo sin grupo"], ["bajo", 20.0, false, {}, "bajo con grupo"],
	["medio", 20.0, false, {"grupo": false}, "medio sin grupo"], ["medio", 20.0, false, {}, "medio con grupo"],
	["alto", 20.0, false, {"grupo": false}, "alto sin grupo"], ["alto", 20.0, false, {}, "alto con grupo"],
	["bajo", 20.0, false, {}, "bajo con grupo", true]]

# misión
const ESPERA_PV02 := 2.5                 # segundos tras entrar (deja ver el título de la zona)
const RADIO_PV03 := 3.5
const CENTINELA := Vector3(2.6, 0, -10.5) # la estatua del guardián en el mirador (sendero_puente.gd)
const RADIO_CENTINELA := 4.5
const COMBATE_CENTINELA := "pastos_centinela"
const GRUPO_CENTINELA := 0               # combate.gd, GRUPOS[0]: dos Grimfang («Quietos. Dos.», PV-06)
const RADIO_ACCION := 2.2                # metros para hablar o examinar
const ID_ESTELA := "pastos_estela"       # progreso.gd, DETALLES[10]
# cofre: junto al árbol mágico de la salida del puente (sendero_puente.gd, SITIOS_MAGICOS), del lado de la cámara para
# que no lo tape la copa. Se abre una sola vez en toda la partida («cofres_abiertos», como los cofres de zona.gd).
const COFRE_ARBOL := Vector3(16, 0, 2)
const ID_COFRE := "pastos3d_arbol_magico"
const COFRE_ANCHO := 0.9
const COFRE_FONDO := 0.56
const COFRE_ALTO := 0.42                 # la caja; la tapa curva sube otros COFRE_FONDO / 2
const COFRE_ABIERTA := -105.0            # grados que gira la tapa sobre la bisagra de atrás
# Cinemática del mirador (PV-07, biblia v3 §6.2, aprobada como alfa): plano guiado sin texto sobre la cascada que sube
# hasta la ciudad flotante, y después la conversación. Tomas: [segundo, posición de la cámara, hacia dónde mira].
# Las dos últimas van altas (grúa): más bajas enseñaban las laderas peladas del borde y las lomas del norte (que suben
# a unos 18 m a z = −60) tapaban media ciudad (capturas de prueba_region3d_fotos del 08/11).
# A 22 m, bajo la ciudad se ve cielo (más abajo parecía apoyada en las lomas).
const CINE_TOMAS := [[3.5, Vector3(4.1, 3.4, -5.0), Vector3(9.0, -2.5, -16.0)],   # baja hacia la cascada
	[7.0, Vector3(6.5, 8.0, -9.0), Vector3(9.0, -0.5, -18.0)],                    # sube y la mira desde arriba
	[11.0, Vector3(4.0, 22.0, -4.0), Vector3(10.0, 34.0, -128.0)]]                # y alza la vista a la ciudad flotante
const CINE_VUELTA := 1.2                 # segundos para volver a la cámara de juego
# Campanas: [segundo, tono (respecto a do5), volumen]. Sin música: «Promised Horizon» es de Suno y no es libre.
const CINE_NOTAS := [[0.6, 1.0, -10.0], [1.5, 1.498, -11.0], [2.4, 2.0, -12.0], [3.3, 2.52, -13.0],
	[9.4, 1.0, -12.0], [9.4, 1.26, -13.0], [9.4, 1.498, -13.0], [9.9, 2.0, -15.0]]

var pasos := 0
var saliendo := false
var salidas: Array = []                  # [{"pos": Vector3, "armada": bool}]
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var tilo: Node3D
var estela: Node3D
var grupo: Node3D                        # zonas3d/grupo_3d.gd (null si no sale nadie)
var cofre: Node3D
var tapa_cofre: Node3D
var brillo_cofre: MeshInstance3D         # destello que llama la atención mientras está cerrado
var objetivo: Label                      # arriba a la izquierda: qué toca ahora en la misión
var _objetivo_texto := "-"
var marcador: Node3D                     # rombo dorado sobre quien la misión necesita ahora (Tilo o el centinela)
var cinematica := false                  # mientras dura, la cámara es de la cinemática y no hay control
var cinematicas_vistas := 0              # cuántas veces ha empezado en esta escena (las pruebas miran que no se repita)
var _cine_t := 0.0
var _cine_inicio: Transform3D
var _cine_notas := 0                     # campanas que ya han sonado
var _cine_capa: CanvasLayer
var _cine_franjas: Array = []
var _cine_saltar: Button
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
	_crear_grupo()
	_ultima = kael.global_position
	for s in salidas:
		s["armada"] = _dist_plana(kael.global_position, s["pos"]) > ARMAR_SALIDA
	# si se vuelve de perder contra el centinela, no se repite hasta alejarse y volver
	_centinela_armado = _dist_plana(kael.global_position, CENTINELA) > RADIO_CENTINELA
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
	Engine.set_meta("zona", ZONA)
	_preparar_sonidos()
	if not en_banco():
		load("res://progreso.gd").guardar(scene_file_path)   # guardado automático al entrar (como zona.gd)


# Los sonidos hechos por código se generan al cargar (detrás del fundido), no al usarlos: generarlos en el momento
# daba un tirón al abrir el cofre. Solo los que pueden sonar en esta visita.
func _preparar_sonidos() -> void:
	var P = load("res://progreso.gd")
	if not cofre_abierto():
		sonido_cofre()
	if P.hito("pv_05") and not P.hito("pv_07"):
		campana()


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
	var bg := Button.new()                   # en el sitio que deja DIAG
	bg.text = "GRUPO"
	bg.position = Vector2(1160, 140)
	bg.custom_minimum_size = Vector2(108, 56)
	bg.focus_mode = Control.FOCUS_NONE
	bg.pressed.connect(func(): _empezar_banco(BANCO_GRUPO))
	capa.add_child(bg)


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
	_actualizar_objetivo()
	if cinematica:                       # la cinemática mueve la cámara; Kael, quieto y sin pasos
		_paso_cinematica(delta)
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
	if cinematica:                       # sin control: solo se puede saltar (botón, Intro o Escape)
		if ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel"):
			_saltar_cinematica()
		get_viewport().set_input_as_handled()
		return
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
		_empezar_cinematica_mirador()


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
		"pv_03":                         # Lya llega corriendo por el camino, por detrás
			_unir("Lya", kael.global_position + _atras_en_camino(kael.global_position) * 4.0)
		"pv_05":                         # Garon esperaba junto a Tilo
			_unir("Garon", tilo.global_position)
		"pv_14":
			P.poner_hito("mecha_tilo")
			_mostrar_aviso("Tilo te da una mecha de su farol.")
	if id.begins_with("pv_"):
		guardar_posicion()
		P.guardar(scene_file_path)       # la misión avanza: se guarda (no hace nada en las pruebas)


# ================================================================= objetivo y marcador
# En la pantalla del móvil, la misión se entiende mejor si se ve qué toca ahora: una línea arriba a la izquierda y un
# rombo dorado sobre quien la misión necesita. Los textos salen de los diálogos de la misión (Tilo: «saludar antes al
# viejo», «el centinela del mirador»; Lya: «el bosque está al noreste»), sin contar nada nuevo.

func texto_objetivo() -> String:
	var P = load("res://progreso.gd")
	if not P.hito("pv_02"):
		return ""
	if not P.hito("pv_03"):
		return "Sigue el camino."
	if not P.hito("pv_05"):
		return "Sigue el camino hasta el puente."
	if not P.ganado(COMBATE_CENTINELA):
		return "Saluda al centinela del mirador."
	if not P.hito("pv_07"):
		return "Vuelve junto al centinela."
	if not P.hito("pv_14"):
		return "Vuelve a hablar con Tilo."
	return "Sigue el camino hacia el noreste."


func _actualizar_objetivo() -> void:
	if objetivo == null:
		return
	objetivo.visible = not (cinematica or ocupado() or saliendo or en_banco()) and _objetivo_texto != ""
	var t := texto_objetivo()
	if t == _objetivo_texto:
		return
	_objetivo_texto = t
	objetivo.text = "Objetivo: " + t
	if t != "":                                       # objetivo nuevo: un destello suave para que se note
		objetivo.modulate = Color(1.6, 1.4, 0.8)
		create_tween().tween_property(objetivo, "modulate", Color.WHITE, 1.2)
	_poner_marcador()


# El rombo va sobre Tilo cuando toca hablar con él y sobre el centinela cuando toca ir al mirador.
func _poner_marcador() -> void:
	var P = load("res://progreso.gd")
	var donde = null
	if tilo != null and P.hito("pv_03") and (not P.hito("pv_05") or (P.hito("pv_07") and not P.hito("pv_14"))):
		donde = tilo.global_position + Vector3(0, 2.5, 0)
	elif P.hito("pv_05") and not P.hito("pv_07"):
		donde = Vector3(CENTINELA.x, altura(CENTINELA.x, CENTINELA.z) + 3.6, CENTINELA.z)   # a 4,4 m se salía por arriba
	if donde == null:
		if marcador != null:
			marcador.visible = false
		return
	if marcador == null:
		marcador = Node3D.new()
		marcador.name = "Marcador"
		add_child(marcador)
		var rombo := SphereMesh.new()                 # 4 lados y 2 anillos: un rombo
		rombo.radius = 0.16
		rombo.height = 0.42
		rombo.radial_segments = 4
		rombo.rings = 2
		var oro := StandardMaterial3D.new()
		oro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		oro.albedo_color = Color(1.0, 0.82, 0.32)
		var pieza := _pieza(marcador, rombo, oro, Vector3.ZERO)
		pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_destello(marcador, Vector3.ZERO, 0.7)
		var giro := pieza.create_tween().set_loops()
		giro.tween_property(pieza, "rotation:y", TAU, 2.4).from(0.0)
		var sube := marcador.create_tween().set_loops()
		sube.tween_property(pieza, "position:y", 0.15, 0.8).set_trans(Tween.TRANS_SINE)
		sube.tween_property(pieza, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	marcador.position = donde
	marcador.visible = true


# ================================================================= cinemática del mirador (PV-07)
# El hito se pone y se guarda ANTES de la animación: si la cinemática se salta o la app se cierra a medias, no se
# repite ni da nada dos veces. La animación solo enseña: al terminar (o al saltarla) vuelven la cámara de juego, el
# control y la interfaz, y empieza la conversación PV-07. Lya y Garon se quedan quietos detrás de Kael.

func _empezar_cinematica_mirador() -> void:
	var P = load("res://progreso.gd")
	P.poner_hito("pv_07")
	guardar_posicion()
	P.guardar(scene_file_path)
	_parar_kael()
	boton_accion.visible = false
	cinematica = true
	cinematicas_vistas += 1
	_cine_t = 0.0
	_cine_notas = 0
	_cine_inicio = cam.global_transform
	_interfaz_cinematica(true)


func _paso_cinematica(delta: float) -> void:
	_cine_t += delta
	while _cine_notas < CINE_NOTAS.size() and _cine_t >= CINE_NOTAS[_cine_notas][0]:
		var n: Array = CINE_NOTAS[_cine_notas]
		_sonar(campana(), n[2], n[1], &"Musica")         # la melodía de campanas es música (sonido.gd)
		_cine_notas += 1
	var fin: float = CINE_TOMAS[CINE_TOMAS.size() - 1][0] + CINE_VUELTA
	if _cine_t >= fin:
		_terminar_cinematica()
		return
	cam.global_transform = _cine_camara(_cine_t)


# La cámara en el segundo «t»: de la de juego a las tomas y vuelta a la de juego, suavizando cada tramo.
func _cine_camara(t: float) -> Transform3D:
	var claves: Array = [[0.0, _cine_inicio]]
	for toma in CINE_TOMAS:
		claves.append([toma[0], Transform3D(Basis(), toma[1]).looking_at(toma[2], Vector3.UP)])
	claves.append([CINE_TOMAS[CINE_TOMAS.size() - 1][0] + CINE_VUELTA, _camara_juego()])
	for i in claves.size() - 1:
		if t <= claves[i + 1][0]:
			var k := smoothstep(claves[i][0], claves[i + 1][0], t)
			return (claves[i][1] as Transform3D).interpolate_with(claves[i + 1][1], k)
	return claves[claves.size() - 1][1]


# Dónde pone la cámara el juego con Kael parado (lo mismo que _colocar_camara de vista3d.gd).
func _camara_juego() -> Transform3D:
	var ang := deg_to_rad(inclinacion)
	var atras := Vector3(sin(deg_to_rad(GIRO)), 0, cos(deg_to_rad(GIRO)))
	var ojo := kael.global_position + Vector3(0, 0.9, 0)
	var pos := ojo + atras * cos(ang) * distancia + Vector3.UP * sin(ang) * distancia
	return Transform3D(Basis(), pos).looking_at(ojo, Vector3.UP)


func _saltar_cinematica() -> void:
	if cinematica:
		_terminar_cinematica()


func _terminar_cinematica() -> void:
	cinematica = false
	foco = kael.global_position
	_colocar_camara(1.0)
	_interfaz_cinematica(false)
	if not _empezar_dialogo("pv_07"):
		_tras_dialogo("pv_07")


# Franjas negras arriba y abajo, el botón «Saltar» y, mientras, sin los botones del panel de pruebas.
func _interfaz_cinematica(si: bool) -> void:
	if _cine_capa == null:
		_cine_capa = CanvasLayer.new()
		_cine_capa.layer = 60
		add_child(_cine_capa)
		for arriba in [true, false]:
			var f := ColorRect.new()
			f.color = Color(0, 0, 0, 1)
			f.mouse_filter = Control.MOUSE_FILTER_IGNORE
			f.size = Vector2(1280, 0)
			f.position = Vector2(0, 0 if arriba else 720)
			_cine_capa.add_child(f)
			_cine_franjas.append(f)
		_cine_saltar = Button.new()
		_cine_saltar.text = "Saltar"
		_cine_saltar.position = Vector2(1070, 652)
		_cine_saltar.custom_minimum_size = Vector2(190, 62)
		_cine_saltar.add_theme_font_size_override("font_size", 26)
		_cine_saltar.focus_mode = Control.FOCUS_NONE
		_cine_saltar.pressed.connect(_saltar_cinematica)
		_cine_capa.add_child(_cine_saltar)
	_cine_capa.visible = si
	info.get_parent().visible = not si          # el panel del prototipo (CAL, RND y los bancos)
	if si:
		var t := create_tween().set_parallel(true)
		t.tween_property(_cine_franjas[0], "size:y", 72.0, 0.5)
		t.tween_property(_cine_franjas[1], "size:y", 72.0, 0.5)
		t.tween_property(_cine_franjas[1], "position:y", 648.0, 0.5)
	else:
		for f in _cine_franjas:
			f.size.y = 0.0
		_cine_franjas[1].position.y = 720.0


func _sonar(stream: AudioStream, vol_db: float, tono := 1.0, bus := &"Efectos") -> void:
	var son := AudioStreamPlayer.new()
	son.stream = stream
	son.volume_db = vol_db
	son.pitch_scale = tono
	son.bus = bus                                           # buses y volúmenes: sonido.gd
	add_child(son)
	son.play()
	son.finished.connect(son.queue_free)


# Una campana suave (do5, 2,5 s), hecha por código como los sonidos del menú. Las notas de la cinemática son esta misma
# campana con otro tono (pitch_scale): así solo se genera una vez y no hay tirón al empezar.
static var _campana: AudioStreamWAV


static func campana() -> AudioStreamWAV:
	if _campana == null:
		var hz := 22050
		var m := PackedFloat32Array()
		m.resize(int(hz * 2.5))
		for i in m.size():
			var t := float(i) / hz
			var env := minf(1.0, t * 300.0) * exp(-t * 2.2)
			m[i] = (sin(TAU * 523.25 * t) + 0.35 * sin(TAU * 1046.5 * t) * exp(-t * 2.0)
				+ 0.12 * sin(TAU * 1569.75 * t) * exp(-t * 4.0)) * env * 0.5
		_campana = load("res://menu_combate.gd")._wav(m, hz)
	return _campana


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
	elif cofre != null and not cofre_abierto() and _dist_plana(p, cofre.global_position) < RADIO_ACCION:
		cerca = "cofre"
		boton_accion.text = "Abrir cofre"
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
		"cofre":
			_abrir_cofre()


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
	cofre = _crear_cofre(_sitio_cofre())


# Los que están ahora en el grupo (grupo.gd, activos: la misma fuente que el combate, los menús y la partida) siguen a
# Kael, detrás de él y mirando camino adelante. Con la misión, Lya llega en PV-03 («¡Kael! ¿De verdad pensabas irte
# sin mí?») y Garon en PV-05, junto a Tilo («Os acompaño»): antes, Kael va solo. En los bancos salen siempre los dos
# (miden lo que cuestan).
func _crear_grupo() -> void:
	if not perfil.get("grupo", true):
		return
	var G = load("res://grupo.gd")
	# una partida de antes de «grupo_activo» que llega a la misión por primera vez: la misión empieza con Kael solo
	if not en_banco() and not Engine.has_meta("grupo_activo") and not load("res://progreso.gd").hito("pv_02"):
		G.empezar_solo()
	var activos: Array = G.EN_EL_GRUPO if en_banco() else G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	grupo = load("res://zonas3d/grupo_3d.gd").new()
	grupo.name = "Grupo"
	add_child(grupo)
	grupo.preparar(self, kael, nombres)
	grupo.colocar(_atras_en_camino(kael.global_position))


# La misión une a alguien: entra en el grupo de la partida (grupo.gd) y aparece siguiendo a Kael.
func _unir(n: String, desde: Vector3) -> void:
	var G = load("res://grupo.gd")
	G.unir(n)
	if grupo != null and n in G.activos():
		grupo.unir(n, desde)


# Hacia dónde queda «atrás» en el camino desde «p»: hacia el principio del tramo de SENDERO más cercano.
func _atras_en_camino(p: Vector3) -> Vector3:
	var mejor := INF
	var atras: Vector3 = (SENDERO[0] - SENDERO[1]).normalized()
	for i in SENDERO.size() - 1:
		var a: Vector3 = SENDERO[i]
		var b: Vector3 = SENDERO[i + 1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var dist := (Vector2(a.x, a.z) + ab * t).distance_to(Vector2(p.x, p.z))
		if dist < mejor:
			mejor = dist
			atras = Vector3(-ab.x, 0.0, -ab.y).normalized()
	return atras


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


# ================================================================= cofre

func cofre_abierto() -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(ID_COFRE)


# Junto al árbol mágico, del lado de la cámara y hacia el puente, en un sitio andable, fuera del camino y sin tronco,
# roca ni nada a su alrededor. Siempre el mismo (la escena sale igual cada vez).
func _sitio_cofre() -> Vector3:
	var hacia := Vector3(-0.6, 0.0, 0.8).normalized()
	for r in [2.0, 2.4, 1.7, 2.8]:
		for giro in [0.0, 20.0, -20.0, 40.0, -40.0, 60.0, -60.0]:
			var q: Vector3 = COFRE_ARBOL + hacia.rotated(Vector3.UP, deg_to_rad(giro)) * r
			if _prohibido(q) or _dist_sendero(q) < 1.3:
				continue
			q.y = altura(q.x, q.z)
			if _hueco_libre(q, 0.8):
				return q
	var p := COFRE_ARBOL + hacia * 2.0
	return Vector3(p.x, altura(p.x, p.z), p.z)


# Nada a la altura de las rodillas en un círculo de «radio» alrededor de «p», y el suelo es el del terreno.
func _hueco_libre(p: Vector3, radio: float) -> bool:
	var espacio := get_world_3d().direct_space_state
	var centro := p + Vector3(0, 0.5, 0)
	for k in 8:
		var a := TAU * k / 8.0
		var q := PhysicsRayQueryParameters3D.create(centro, centro + Vector3(cos(a), 0, sin(a)) * radio)
		if not espacio.intersect_ray(q).is_empty():
			return false
	var abajo := espacio.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 2.0, 0), p - Vector3(0, 1.0, 0)))
	return not abajo.is_empty() and absf(abajo["position"].y - p.y) < 0.1


# Cofre de madera con herrajes dorados y tapa curva, hecho con formas sencillas (sin modelos de terceros). Kael no lo
# atraviesa. Cerrado, un destello le llama la atención; abierto, se ven las monedas del fondo.
func _crear_cofre(p: Vector3) -> Node3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Cofre"
	cuerpo.position = p
	add_child(cuerpo)
	var madera := _mat_detalle(Color(0.52, 0.32, 0.17), 0.9, false, 0.8)
	var dorado := StandardMaterial3D.new()
	dorado.albedo_color = Color(0.95, 0.76, 0.3)
	dorado.metallic = 0.6
	dorado.roughness = 0.35
	var caja := BoxMesh.new()
	caja.size = Vector3(COFRE_ANCHO, COFRE_ALTO, COFRE_FONDO)
	_pieza(cuerpo, caja, madera, Vector3(0, COFRE_ALTO * 0.5, 0))
	var zocalo := BoxMesh.new()
	zocalo.size = Vector3(COFRE_ANCHO + 0.03, 0.05, COFRE_FONDO + 0.03)
	_pieza(cuerpo, zocalo, dorado, Vector3(0, 0.025, 0))
	var r := COFRE_FONDO * 0.5
	var bandas := [-COFRE_ANCHO * 0.5 + 0.1, COFRE_ANCHO * 0.5 - 0.1]
	for x in bandas:
		var banda := BoxMesh.new()
		banda.size = Vector3(0.06, COFRE_ALTO + 0.01, COFRE_FONDO + 0.02)
		_pieza(cuerpo, banda, dorado, Vector3(x, COFRE_ALTO * 0.5, 0))
	var placa := BoxMesh.new()                              # cerradura
	placa.size = Vector3(0.12, 0.14, 0.02)
	_pieza(cuerpo, placa, dorado, Vector3(0, COFRE_ALTO - 0.07, r + 0.01))
	var ojo := BoxMesh.new()
	ojo.size = Vector3(0.025, 0.05, 0.01)
	_pieza(cuerpo, ojo, _mat_simple(Color(0.12, 0.08, 0.05)), Vector3(0, COFRE_ALTO - 0.08, r + 0.022))
	# el fondo, que solo se ve con la tapa abierta: madera oscura y monedas que brillan un poco
	var fondo := PlaneMesh.new()
	fondo.size = Vector2(COFRE_ANCHO - 0.08, COFRE_FONDO - 0.08)
	_pieza(cuerpo, fondo, _mat_simple(Color(0.17, 0.1, 0.06)), Vector3(0, COFRE_ALTO + 0.003, 0))
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color(1.0, 0.82, 0.3)
	oro.metallic = 0.7
	oro.roughness = 0.3
	oro.emission_enabled = true
	oro.emission = Color(1.0, 0.75, 0.25)
	oro.emission_energy_multiplier = 0.6
	var moneda := CylinderMesh.new()
	moneda.top_radius = 0.04
	moneda.bottom_radius = 0.04
	moneda.height = 0.012
	moneda.radial_segments = 10
	for k in 9:
		var mp := Vector3(-0.3 + 0.075 * k, COFRE_ALTO + 0.01 + 0.006 * (k % 3), 0.11 * sin(k * 2.3))
		_pieza(cuerpo, moneda, oro, mp, Vector3(0.25 * sin(k * 1.7), 0, 0.25 * cos(k * 1.3)))
	# tapa: gira sobre la bisagra del borde de atrás
	tapa_cofre = Node3D.new()
	tapa_cofre.name = "Tapa"
	tapa_cofre.position = Vector3(0, COFRE_ALTO, -r)
	cuerpo.add_child(tapa_cofre)
	_pieza(tapa_cofre, _malla_tapa(COFRE_ANCHO, r), madera, Vector3(0, 0, r))
	for x in bandas:
		_pieza(tapa_cofre, _malla_tapa(0.06, r + 0.012), dorado, Vector3(x, 0, r))
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(COFRE_ANCHO, COFRE_ALTO + r, COFRE_FONDO)
	col.shape = forma
	col.position.y = (COFRE_ALTO + r) * 0.5
	cuerpo.add_child(col)
	# La cerradura mira hacia la cámara (que nunca gira), un poco hacia el puente: con ella de espaldas, de cerca
	# parecía un barril (capturas de prueba_region3d_fotos del 08/11).
	_mirar_a(cuerpo, p + Vector3(-0.35, 0, 1.0))
	if cofre_abierto():
		tapa_cofre.rotation.x = deg_to_rad(COFRE_ABIERTA)
	else:
		brillo_cofre = _destello(cuerpo, Vector3(0, COFRE_ALTO + 0.05, r + 0.05), 0.25)
		var t := brillo_cofre.create_tween().set_loops()
		t.tween_property(brillo_cofre, "scale", Vector3.ONE * 0.42, 0.5).set_trans(Tween.TRANS_SINE)   # 0,55 tapaba la cerradura
		t.tween_property(brillo_cofre, "scale", Vector3.ONE * 0.15, 0.6).set_trans(Tween.TRANS_SINE)
		t.tween_interval(1.2)
	return cuerpo


# Medio cilindro tumbado a lo largo de X (la tapa curva): eje en y = 0, de z = -radio a z = +radio, con sus dos tapas
# y la cara de abajo (se ve al abrir). Triángulos en el sentido de las agujas del reloj vistos desde fuera (Godot).
func _malla_tapa(ancho: float, radio: float, lados := 14) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -ancho * 0.5
	var x1 := ancho * 0.5
	for i in lados:
		var a0 := PI * i / lados
		var a1 := PI * (i + 1) / lados
		var n0 := Vector3(0, sin(a0), cos(a0))
		var n1 := Vector3(0, sin(a1), cos(a1))
		var a := Vector3(x0, n0.y * radio, n0.z * radio)
		var b := Vector3(x1, n0.y * radio, n0.z * radio)
		var c := Vector3(x1, n1.y * radio, n1.z * radio)
		var d := Vector3(x0, n1.y * radio, n1.z * radio)
		for v in [[a, n0], [d, n1], [c, n1], [a, n0], [c, n1], [b, n0]]:
			st.set_normal(v[1])
			st.add_vertex(v[0])
		for lado in [-1.0, 1.0]:                            # tapas de los lados: medio disco
			var x: float = x1 if lado > 0.0 else x0
			var centro := Vector3(x, 0, 0)
			var q0 := Vector3(x, n0.y * radio, n0.z * radio)
			var q1 := Vector3(x, n1.y * radio, n1.z * radio)
			var orden: Array = [centro, q0, q1] if lado > 0.0 else [centro, q1, q0]
			for v in orden:
				st.set_normal(Vector3(lado, 0, 0))
				st.add_vertex(v)
	for v in [Vector3(x1, 0, radio), Vector3(x1, 0, -radio), Vector3(x0, 0, -radio),
			Vector3(x1, 0, radio), Vector3(x0, 0, -radio), Vector3(x0, 0, radio)]:
		st.set_normal(Vector3.DOWN)
		st.add_vertex(v)
	return st.commit()


# Destello dorado: un cuadrado que mira siempre a la cámara, con un degradado redondo y mezcla aditiva.
func _destello(padre: Node3D, pos: Vector3, tam: float) -> MeshInstance3D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.96, 0.75, 1.0), Color(1.0, 0.78, 0.3, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	var q := QuadMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = Vector3.ONE * tam
	padre.add_child(mi)
	return mi


# Abre el cofre: primero se apunta como abierto, luego se da el premio y se guarda. Así el premio sale una sola vez
# aunque se pulse dos veces, y si el guardado fallara, el cofre y el premio se pierden juntos (van en el mismo archivo).
func _abrir_cofre() -> void:
	if cofre == null or cofre_abierto():
		return
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[ID_COFRE] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	var premio := _premio_cofre(ID_COFRE)
	_parar_kael()
	var hacia := cofre.global_position - kael.global_position
	hacia.y = 0.0
	if hacia.length() > 0.05:
		kael.mirar(hacia, 0.2)
	boton_accion.visible = false
	_animar_cofre()
	_mostrar_aviso("¡Has encontrado %s!" % premio, 2.2)
	guardar_posicion()
	load("res://progreso.gd").guardar(scene_file_path)


# El premio, como en los cofres de las zonas 2D (zona.gd, _abrir_cofre): monedas, pociones o éter, siempre el mismo
# para el mismo cofre.
func _premio_cofre(id: String) -> String:
	var inv = load("res://inventario.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	match rng.randi() % 4:
		0, 1:
			var oro := rng.randi_range(40, 120)
			inv.ganar_oro(oro)
			return "%d monedas" % oro
		2:
			inv.agregar_objeto("Poción", 2)
			return "2 Pociones"
		_:
			inv.agregar_objeto("Éter", 1)
			return "1 Éter"


func _animar_cofre() -> void:
	if brillo_cofre != null:
		brillo_cofre.queue_free()
		brillo_cofre = null
	var t := tapa_cofre.create_tween()
	t.tween_property(tapa_cofre, "rotation:x", deg_to_rad(COFRE_ABIERTA), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var luz := _destello(cofre, Vector3(0, COFRE_ALTO + 0.25, 0), 0.3)
	var t2 := luz.create_tween()
	t2.tween_property(luz, "scale", Vector3.ONE * 1.9, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(luz.material_override, "albedo_color:a", 0.0, 0.75)
	t2.tween_callback(luz.queue_free)
	var son := AudioStreamPlayer.new()
	son.stream = sonido_cofre()
	son.volume_db = -6.0                                    # como los sonidos del menú (menu_combate.gd)
	son.bus = &"Efectos"                                    # buses y volúmenes: sonido.gd
	add_child(son)
	son.play()
	son.finished.connect(son.queue_free)


# Sonido del cofre, hecho por código como los del menú (menu_combate.gd, sonidos_ui): el golpe seco de la tapa de
# madera y, encima, un arpegio brillante que sube (do, mi, sol, do). Dura 0,9 s. Se genera una vez y se guarda: hacerlo
# al abrir el cofre daba un tirón de unos 180 ms (medido en el PC el 08/11), así que _ready lo prepara al cargar.
static var _sonido_cofre: AudioStreamWAV


static func sonido_cofre() -> AudioStreamWAV:
	if _sonido_cofre == null:
		_sonido_cofre = _generar_sonido_cofre()
	return _sonido_cofre


static func _generar_sonido_cofre() -> AudioStreamWAV:
	var hz := 22050
	var m := PackedFloat32Array()
	m.resize(int(hz * 0.9))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ruido := 0.0
	var notas := [1046.5, 1318.5, 1568.0, 2093.0]
	for i in m.size():
		var t := float(i) / hz
		ruido = lerpf(ruido, rng.randf_range(-1.0, 1.0), 0.25)          # ruido suavizado: madera, no siseo
		var v := ruido * exp(-t * 38.0) * 0.5 + sin(TAU * 150.0 * t) * exp(-t * 30.0) * 0.4
		for k in notas.size():
			var t0 := t - 0.12 - 0.07 * k
			if t0 > 0.0:
				var env := minf(1.0, t0 * 200.0) * exp(-t0 * 5.5)
				v += (sin(TAU * notas[k] * t0) + 0.3 * sin(TAU * notas[k] * 2.0 * t0)) * env * 0.11
		m[i] = v
	return load("res://menu_combate.gd")._wav(m, hz)


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
	objetivo = Label.new()                           # arriba a la izquierda (CAL, RND y los bancos van a la derecha)
	objetivo.position = Vector2(24, 18)
	objetivo.add_theme_font_size_override("font_size", 26)
	objetivo.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	objetivo.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.08, 0.9))
	objetivo.add_theme_constant_override("outline_size", 8)
	objetivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objetivo.visible = false
	capa.add_child(objetivo)
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
