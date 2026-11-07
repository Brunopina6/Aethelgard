extends "res://prototipos/sendero_puente.gd"
# Pastos Verdes en 3D: la primera región jugable de la exploración 3D (rama experimental rebelum-alpha).
#
# Solo se llega con la exploración 3D activa (modo3d.gd): el mapa muestra Pastos Verdes como lugar 10 y entra
# aquí. Sin ella, el juego es el de siempre. El escenario es el del prototipo (prototipos/sendero_puente.gd: camino,
# puente, río, cascada, árboles, hierba, faroles y fauna) y la región cumple el contrato de una zona 2D (zona.gd):
#   - encuentros por pasos con progreso.gd y combate con vuelta (escena_retorno) al mismo sitio;
#   - guardado automático al entrar, tras cada combate (combate.gd) y al pausar o cerrar la app (guardar_posicion);
#   - salida al mapa por los dos extremos del camino, que se marcan en el suelo.
# Pendiente (TASKS.md, T-022): Lya y Garon siguiendo a Kael, Tilo, la estela, el cofre, el combate fijo y la misión.

const INDICE := 10                       # lugar del mapa (modo3d.PASTOS_VERDES y mapa.gd, LUGAR_PASTOS)
const ZONA := "llanura"                  # para progreso.gd (zona limpia, incienso) y el fondo del combate
const LONG_PASO := 0.5                   # metros andados por cada «paso» de los encuentros
const PASOS_MIN := 40                    # pasos seguros al entrar (como zona.gd)
const PROB_ENCUENTRO := 0.012            # como zona.gd
const RADIO_SALIDA := 1.3                # metros: al llegar tan cerca de una salida, se vuelve al mapa
const ARMAR_SALIDA := 2.5                # una salida solo funciona después de alejarse de ella esta distancia
const BOTONES_BANCO := ["PRUEBA", "DIAG", "TOPE", "ARB"]   # bancos del prototipo: no son para el juego

var pasos := 0
var saliendo := false
var salidas: Array = []                  # [{"pos": Vector3, "armada": bool}]
var fundido: ColorRect
var aviso: Label
var _recorrido := 0.0                    # metros andados desde el último paso
var _ultima := Vector3.ZERO


func _ready() -> void:
	super()                              # escenario, Kael al principio del camino, cámara, fauna y título
	info.visible = false                 # la ayuda de teclas del prototipo no es para el juego
	_crear_fundido()
	_crear_salidas()
	if Engine.get_meta("pos_3d_ok", false) and Engine.get_meta("pos_3d_lugar", -1) == INDICE:
		_colocar_kael(Engine.get_meta("pos_3d"))       # vuelve del combate o de una partida guardada aquí
	_ultima = kael.global_position
	for s in salidas:
		s["armada"] = _dist_plana(kael.global_position, s["pos"]) > ARMAR_SALIDA
	Engine.set_meta("zona", ZONA)
	load("res://progreso.gd").guardar(scene_file_path)   # guardado automático al entrar (como zona.gd)


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
	for s in salidas:
		var dist := _dist_plana(p, s["pos"])
		if not s["armada"]:
			s["armada"] = dist > ARMAR_SALIDA
		elif dist < RADIO_SALIDA:
			_salir()
			return


# ================================================================= encuentros

func _paso() -> void:
	pasos += 1
	var prog = load("res://progreso.gd")
	if prog.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	# progreso.gd: pasos seguros, luego sube despacio; casi nada si la zona está «limpia» o con incienso
	if randf() < prog.prob_encuentro(PROB_ENCUENTRO, pasos, PASOS_MIN, ZONA):
		_encuentro()


func _encuentro() -> void:
	if saliendo:
		return
	saliendo = true
	guardar_posicion()                   # el combate vuelve aquí, al mismo sitio
	Engine.set_meta("zona", ZONA)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("escena_retorno", scene_file_path)
	_mostrar_aviso("¡Emboscada!")
	fundido.color = Color(1, 1, 1, 0)
	var t := create_tween()
	for i in 3:
		t.tween_property(fundido, "color:a", 0.85, 0.07)
		t.tween_property(fundido, "color:a", 0.0, 0.07)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


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

func _crear_fundido() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 50
	add_child(capa)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(fundido)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.size = Vector2(1280, 60)
	aviso.position = Vector2(0, 560)
	aviso.add_theme_font_size_override("font_size", 34)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	aviso.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.08, 0.85))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.modulate.a = 0.0
	capa.add_child(aviso)


func _mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	var t := create_tween()
	t.tween_property(aviso, "modulate:a", 1.0, 0.2)
	t.tween_interval(1.6)
	t.tween_property(aviso, "modulate:a", 0.0, 0.5)
