extends RefCounted
# El buscador de metales de Kael en pantalla (V12; docs/v12/BUSCADOR.md; la lógica es buscador.gd).
#
# - Botón «BUSCADOR» (abajo a la izquierda, junto al joystick) para sacarlo o guardarlo. Solo existe si Kael lo tiene
#   (buscador.gd, tiene; se lo presta la cartógrafa al empezar la misión).
# - Con él fuera: un indicador de cercanía (una barra de siete marcas que se encienden de verde a oro) y un pitido que
#   se acelera al acercarse (más agudo si lo cercano es raro). Arriba, lo que pasa: «Nada», «Algo hay cerca», «¡Aquí
#   mismo!» y el nivel del buscador.
# - Encima de un hallazgo, «EXCAVAR»: Kael cava un momento (polvo y su sonido) y sale lo que hubiera (buscador.excavar).
#   Lo raro y lo único se anuncian aparte; la misión se entera (mision.hallazgo).
# - Con la tormenta: el buscador falla (la aguja tiembla y no se fía) y, fuerte, no oye nada: «La tormenta tapa la
#   señal». No se puede excavar.
# Los pitidos se generan aquí (un tono corto), o se usan los de sonido.gd si existen (buscador_pitido, _raro).

const Buscador := preload("res://buscador.gd")
const MARCAS := 7
const ORO := Color("E8C46A")
const VERDE := Color(0.55, 0.90, 0.55)
const APAGADO := Color(0.25, 0.22, 0.20, 0.7)
const EXCAVAR_SEG := 1.1

var region: Node3D
var capa: CanvasLayer
var boton: Button
var panel: Control
var marcas: Array = []
var estado: Label
var boton_excavar: Button
var boton_mejorar: Button
var activo := false
var cavando := 0.0
var intensidad := 0.0
var raro := false
var _t_pitido := 0.0
var _jugador: AudioStreamPlayer
var _tono: AudioStreamWAV
var _tono_raro: AudioStreamWAV
var _estorbo := 0.0
var _pos := Vector3.ZERO
var ultimo_hallazgo := {}


func _init(r: Node3D, c: CanvasLayer) -> void:
	region = r
	capa = c


func construir() -> void:
	boton = Button.new()
	boton.text = "BUSCADOR"
	boton.position = Vector2(40, 330)
	boton.custom_minimum_size = Vector2(200, 64)
	boton.add_theme_font_size_override("font_size", 24)
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(alternar)
	capa.add_child(boton)
	panel = Control.new()
	panel.position = Vector2(40, 30)
	panel.size = Vector2(460, 120)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	capa.add_child(panel)
	var fondo := ColorRect.new()
	fondo.color = Color(0.10, 0.07, 0.05, 0.62)
	fondo.size = panel.size
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fondo)
	for i in MARCAS:
		var m := ColorRect.new()
		m.size = Vector2(46, 24 + i * 5)
		m.position = Vector2(16 + i * 56, 84 - (24 + i * 5))
		m.color = APAGADO
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(m)
		marcas.append(m)
	estado = Label.new()
	estado.position = Vector2(16, 88)
	estado.size = Vector2(430, 28)
	estado.add_theme_font_size_override("font_size", 20)
	estado.add_theme_color_override("font_color", Color(1.0, 0.94, 0.80))
	panel.add_child(estado)
	boton_excavar = Button.new()
	boton_excavar.text = "EXCAVAR"
	boton_excavar.position = Vector2(960, 500)
	boton_excavar.custom_minimum_size = Vector2(290, 84)
	boton_excavar.add_theme_font_size_override("font_size", 30)
	boton_excavar.focus_mode = Control.FOCUS_NONE
	boton_excavar.visible = false
	boton_excavar.pressed.connect(excavar)
	capa.add_child(boton_excavar)
	boton_mejorar = Button.new()                                 # las investigaciones de Kael (buscador.gd, MEJORAS)
	boton_mejorar.text = "MEJORAR"
	boton_mejorar.position = Vector2(40, 404)
	boton_mejorar.custom_minimum_size = Vector2(200, 56)
	boton_mejorar.add_theme_font_size_override("font_size", 22)
	boton_mejorar.focus_mode = Control.FOCUS_NONE
	boton_mejorar.visible = false
	boton_mejorar.pressed.connect(mejorar)
	capa.add_child(boton_mejorar)
	_jugador = AudioStreamPlayer.new()
	_jugador.bus = "Efectos" if AudioServer.get_bus_index("Efectos") >= 0 else "Master"
	region.add_child(_jugador)
	_tono = _pitido(1046.0)
	_tono_raro = _pitido(1568.0)
	refrescar()


static func _pitido(hz: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.07)
	var m := PackedFloat32Array()
	m.resize(n)
	for i in n:
		var t := float(i) / rate
		var env := minf(1.0, t * 400.0) * exp(-t * 28.0)
		m[i] = (sin(TAU * hz * t) + 0.25 * sin(TAU * hz * 2.0 * t)) * env * 0.35
	return load("res://menu_combate.gd")._wav(m, rate)


# Si Kael no tiene el buscador, ni el botón (se lo presta la cartógrafa).
func refrescar() -> void:
	boton.visible = Buscador.tiene()
	if not Buscador.tiene():
		activo = false
	panel.visible = activo
	boton.text = "GUARDAR" if activo else "BUSCADOR"
	boton_mejorar.visible = activo and Buscador.nivel() < 3


func alternar() -> void:
	if not Buscador.tiene() or cavando > 0.0:
		return
	activo = not activo
	Sonido.efecto("ui_tic") if not Sonido.definicion("ui_tic").is_empty() else null
	refrescar()


func ocupado() -> bool:
	return cavando > 0.0


func actualizar(delta: float, pos: Vector3, estorbo: float) -> void:
	_pos = pos
	_estorbo = estorbo
	if cavando > 0.0:
		cavando -= delta
		if cavando <= 0.0:
			_terminar_excavar()
		return
	if not activo:
		boton_excavar.visible = false
		return
	var s: Dictionary = Buscador.senal(region.REGION_BUSCADOR, region.SEMILLA, Vector2(pos.x, pos.z))
	intensidad = float(s["intensidad"])
	raro = bool(s["raro"])
	if estorbo >= 0.99:
		intensidad = 0.0                                        # la tormenta fuerte: no oye nada
	elif estorbo > 0.0:
		intensidad = clampf(intensidad * (1.0 - estorbo) + randf_range(0.0, 0.35) * estorbo, 0.0, 1.0)   # no se fía
	var encendidas := int(round(intensidad * MARCAS))
	for i in MARCAS:
		(marcas[i] as ColorRect).color = (VERDE.lerp(ORO, float(i) / (MARCAS - 1)) if i < encendidas else APAGADO)
	var se_puede := puede_excavar()
	boton_excavar.visible = se_puede
	if estorbo >= 0.99:
		estado.text = "La tormenta tapa la señal"
	elif estorbo > 0.0:
		estado.text = "La arena ciega el buscador: no te fíes"
	elif se_puede:
		estado.text = "¡Aquí mismo!" + (" Suena distinto…" if raro else "")
	elif intensidad > 0.0:
		estado.text = "Algo hay cerca" + (" (y suena raro)" if raro and intensidad > 0.4 else "")
	else:
		estado.text = "Nada · buscador nivel %d" % Buscador.nivel()
	_t_pitido -= delta
	if intensidad > 0.02 and _t_pitido <= 0.0:
		_t_pitido = lerpf(1.3, 0.11, intensidad)
		_pitar()


func _pitar() -> void:
	var clave := "buscador_pitido_raro" if raro else "buscador_pitido"
	if not Sonido.definicion(clave).is_empty():
		Sonido.efecto(clave)
		return
	_jugador.stream = _tono_raro if raro else _tono
	_jugador.pitch_scale = lerpf(0.9, 1.15, intensidad)
	_jugador.play()


# Encima de algo (lo que excavar sacaría) y sin tormenta.
func puede_excavar() -> bool:
	if not activo or _estorbo > 0.0 or cavando > 0.0:
		return false
	var radio: float = Buscador.NIVELES[Buscador.nivel()]["cavar"]
	for h in Buscador.pendientes(region.REGION_BUSCADOR, region.SEMILLA):
		if Vector2(_pos.x, _pos.z).distance_to(h["pos"]) <= radio:
			return true
	return false


func excavar() -> void:
	if not puede_excavar():
		if activo and _estorbo > 0.0:
			region._mostrar_aviso("Con esta arena no se puede cavar. Busca cobijo.")
		return
	cavando = EXCAVAR_SEG
	boton_excavar.visible = false
	region._parar_kael()
	if not Sonido.definicion("excavar_arena").is_empty():
		Sonido.efecto("excavar_arena")
	var polvo := CPUParticles3D.new()                           # una nube corta de arena donde cava
	polvo.one_shot = true
	polvo.amount = 24
	polvo.lifetime = 0.9
	polvo.explosiveness = 0.6
	polvo.direction = Vector3(0, 1, 0)
	polvo.spread = 55.0
	polvo.initial_velocity_min = 1.5
	polvo.initial_velocity_max = 3.0
	polvo.gravity = Vector3(0, -4.0, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.92, 0.78, 0.55)
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mt
	polvo.mesh = q
	polvo.position = _pos + Vector3(0.0, 0.2, -0.5)
	region.add_child(polvo)
	polvo.emitting = true
	polvo.get_tree().create_timer(1.6).timeout.connect(polvo.queue_free)


func _terminar_excavar() -> void:
	var r: Dictionary = Buscador.excavar(region.REGION_BUSCADOR, region.SEMILLA, Vector2(_pos.x, _pos.z))
	ultimo_hallazgo = r
	if r.is_empty():
		region._mostrar_aviso("Solo arena.")
		return
	region._mostrar_aviso(r["texto"], 2.6)
	if r.get("raro", false) and not Sonido.definicion("hallazgo").is_empty():
		Sonido.efecto("hallazgo")
	region.mision.hallazgo(region, r)
	region.guardar_posicion()
	load("res://progreso.gd").guardar(region.scene_file_path)   # lo desenterrado no se pierde (ni se repite al recargar)


# Kael afina el buscador con lo desenterrado (nivel 2: 2 Fragmentos de espada y 1 Mineral rúnico; nivel 3: 2 Reliquias
# de vidrio y 5 Monedas antiguas). Sin materiales, dice lo que falta. Se guarda al subir.
func mejorar() -> void:
	if cavando > 0.0:
		return
	var antes := Buscador.nivel()
	region._mostrar_aviso(Buscador.investigar(), 2.8)
	if Buscador.nivel() > antes:
		if not Sonido.definicion("hallazgo").is_empty():
			Sonido.efecto("hallazgo")
		refrescar()
		if not region.en_banco():
			region.guardar_posicion()
			load("res://progreso.gd").guardar(region.scene_file_path)
