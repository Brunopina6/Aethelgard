extends Node3D
# Un NPC de la familia chibi V12 (personajes/npc_v12/<oficio>/<oficio>.glb, de fuente/crear_npc_chibi.py).
# Una persona = un oficio (la malla, el esqueleto común y sus clips) + su atlas (<persona>.png: colores y cara).
#
#   var n = preload("res://personajes/npc_v12/npc_chibi.gd").crear("guardia", "guardia_ronda")
#   padre.add_child(n)
#   n.clip("caminar")          reposo, caminar, correr (niños), hablar, saludar, tarea (la de su oficio)
#   n.avanzar(delta)           la animación NO corre sola: quien la gestiona (zonas3d/oakhaven/mundo_vivo.gd) la avanza
#                              cada fotograma de cerca, a saltos de lejos y nada fuera de la vista (barato en el móvil)
#
# Sin el GLB (o sin el atlas) no pone nada y «listo» queda en false: quien lo usa sigue con lo de siempre.

const RUTA := "res://personajes/npc_v12/%s/%s.glb"
const ATLAS := "res://personajes/npc_v12/%s/%s.png"
const MEZCLA := 0.25
const EN_BUCLE := ["reposo", "caminar", "correr", "tarea"]
# Velocidad al andar de cada oficio (m/s), la que no hace patinar los pies (crear_npc_chibi.py, «velocidad» de cada
# <oficio>.json): el clip se acelera o frena según lo que ande de verdad.
const VELOCIDAD := {"herrero": 0.81, "mercader": 0.765, "alquimista": 0.78, "guardia": 0.827, "campesino": 0.78,
	"campesina": 0.757, "anciano": 0.733, "anciana": 0.718, "nino": 0.546, "nina": 0.531, "viajero": 0.796,
	"barrendero": 0.765}
const VELOCIDAD_CORRER := {"nino": 1.347, "nina": 1.309}

static var _escenas := {}          # oficio → PackedScene
static var _materiales := {}       # persona → StandardMaterial3D (uno por persona, compartido)

var oficio := ""
var persona := ""
var listo := false
var anim: AnimationPlayer
var malla: MeshInstance3D
var actual := ""
var _vuelta := "reposo"            # el clip al que vuelve uno que no es de bucle
var _vel := 1.0


static func crear(oficio_: String, persona_: String) -> Node3D:
	var n: Node3D = load("res://personajes/npc_v12/npc_chibi.gd").new()
	n.oficio = oficio_
	n.persona = persona_
	n.name = "NPC_" + persona_
	n._montar()
	return n


static func existe(oficio_: String) -> bool:
	return ResourceLoader.exists(RUTA % [oficio_, oficio_])


static func material_de(oficio_: String, persona_: String) -> StandardMaterial3D:
	if _materiales.has(persona_):
		return _materiales[persona_]
	var ruta := ATLAS % [oficio_, persona_]
	if not ResourceLoader.exists(ruta):
		return null
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(ruta)
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materiales[persona_] = m
	return m


func _montar() -> void:
	var ruta := RUTA % [oficio, oficio]
	if not ResourceLoader.exists(ruta):
		return
	if not _escenas.has(oficio):
		_escenas[oficio] = load(ruta)
	var m: Node3D = (_escenas[oficio] as PackedScene).instantiate()
	m.name = "Modelo"
	add_child(m)
	malla = m.find_child("*_malla", true, false) as MeshInstance3D
	if malla == null:
		for c in m.find_children("*", "MeshInstance3D", true, false):
			malla = c
			break
	var mat := material_de(oficio, persona)
	if malla != null and mat != null:
		malla.material_override = mat
	anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		return
	for c in EN_BUCLE:
		if anim.has_animation(c):
			anim.get_animation(c).loop_mode = Animation.LOOP_LINEAR
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	anim.animation_finished.connect(func(c: StringName):
		if not String(c) in EN_BUCLE:
			clip(_vuelta))
	clip("reposo")
	anim.seek(randf() * anim.current_animation_length, true)     # dos vecinos no respiran a la vez
	listo = true


func tiene(c: String) -> bool:
	return anim != null and anim.has_animation(c)


# Pone un clip (si ya está, no lo reinicia). «vuelta»: a qué vuelve uno que no es de bucle (hablar, saludar).
func clip(c: String, vuelta := "", velocidad := 1.0) -> void:
	if anim == null or not anim.has_animation(c):
		return
	if vuelta != "":
		_vuelta = vuelta
	elif c in EN_BUCLE:
		_vuelta = c
	_vel = velocidad
	if actual == c and anim.is_playing():
		return
	actual = c
	anim.play(c, MEZCLA)


func avanzar(delta: float) -> void:
	if anim != null:
		anim.advance(delta * _vel)          # la velocidad del clip, aquí (speed_scale queda en 1)


# El clip de andar a la velocidad real (m/s): «correr» si es un niño y va deprisa.
func andar(velocidad: float) -> void:
	if VELOCIDAD_CORRER.has(oficio) and velocidad > 0.9:
		clip("correr", "", velocidad / VELOCIDAD_CORRER[oficio])
	else:
		clip("caminar", "", velocidad / VELOCIDAD.get(oficio, 0.78))


func velocidad_natural() -> float:
	return VELOCIDAD.get(oficio, 0.78)


func sombra(si: bool) -> void:
	if malla != null:
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if si else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
