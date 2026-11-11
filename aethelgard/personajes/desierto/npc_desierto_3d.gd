extends Node3D
# Ismena y Oren en 3D (V12, PROTOTIPO del 12/11/2026, especialista de animaciones). Modelos y clips de
# personajes/desierto/fuentes_blender/crear_ismena_oren.py (Blender por guion, obra propia).
#
# INTERRUPTOR (apagado por defecto): el juego sigue con las cápsulas de zonas3d/mar_cristal_3d.gd mientras no se active
#   Engine.set_meta("npc_desierto_v12", true)          (o la constante ACTIVO_POR_DEFECTO)
# y mar_cristal_3d.gd lo use (cambio propuesto en docs/memory/agents/animaciones_v12_desierto_personajes.md).
#
# Uso:
#   var n = preload("res://personajes/desierto/npc_desierto_3d.gd").crear("ismena")   # o "oren"
#   padre.add_child(n)
#   n.hablar()            gesto al hablar (Ismena: señala con el lápiz; Oren: abre los brazos); no repite el mismo
#                         gesto dos frases seguidas: alterna con una variante (Ismena: reganar; Oren: encogerse)
#   n.gesto("mapa")       un clip concreto (vuelve solo al reposo)
#   n.en_dialogo(true)    durante un diálogo no hace gestos sueltos de espera
#   n.mirar_a(punto)      se gira despacio hacia un punto del mundo (quien le habla)
# Sola, en reposo: respira, cambia el peso y parpadea; cada 9-18 s hace un gesto de su oficio (Ismena: mirar el mapa o
# el camino del sur; Oren: se ríe solo), nunca el mismo dos veces seguidas.

const ACTIVO_POR_DEFECTO := false
const RUTA := "res://personajes/desierto/%s/%s.glb"
const ESPERAS := {"ismena": ["mapa", "horizonte"], "oren": ["risa"]}
const HABLAR := {"ismena": ["hablar", "reganar"], "oren": ["hablar", "encogerse"]}
const MEZCLA := 0.3

@export var quien := "ismena"
var anim: AnimationPlayer
var _hablando := false
var _ultimo_gesto := ""
var _espera := 0.0
var _rnd := RandomNumberGenerator.new()
var _tw_giro: Tween


static func activado() -> bool:
	return bool(Engine.get_meta("npc_desierto_v12", ACTIVO_POR_DEFECTO)) or "npc_desierto_v12" in OS.get_cmdline_user_args()


static func crear(nombre: String) -> Node3D:
	var n: Node3D = load("res://personajes/desierto/npc_desierto_3d.gd").new()
	n.quien = nombre
	n.name = nombre.capitalize()
	return n


func _ready() -> void:
	_rnd.seed = hash(quien) + int(Time.get_ticks_msec())
	var ruta := RUTA % [quien, quien]
	if not ResourceLoader.exists(ruta):
		push_warning("npc_desierto_3d: falta %s" % ruta)
		return
	var m: Node3D = (load(ruta) as PackedScene).instantiate()
	add_child(m)
	anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		return
	if anim.has_animation("reposo"):
		anim.get_animation("reposo").loop_mode = Animation.LOOP_LINEAR
	anim.animation_finished.connect(_al_acabar)
	anim.play("reposo")
	anim.seek(_rnd.randf_range(0.0, anim.current_animation_length), true)   # dos NPC no respiran a la vez
	_espera = _rnd.randf_range(6.0, 12.0)


func _process(delta: float) -> void:
	if anim == null or _hablando:
		return
	if String(anim.current_animation) != "reposo":
		return
	_espera -= delta
	if _espera <= 0.0:
		var lista: Array = ESPERAS.get(quien, [])
		if not lista.is_empty():
			gesto(_otro(lista))
		_espera = _rnd.randf_range(9.0, 18.0)


func _otro(lista: Array) -> String:
	if lista.size() == 1:
		return lista[0]
	var opciones := lista.filter(func(c): return c != _ultimo_gesto)
	return opciones[_rnd.randi() % opciones.size()]


func _al_acabar(clip: StringName) -> void:
	if String(clip) != "reposo":
		anim.play("reposo", MEZCLA)


func gesto(clip: String) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_ultimo_gesto = clip
	anim.play(clip, MEZCLA)


# Gesto al hablar. Si la frase anterior ya fue «hablar», la variante (no el mismo gesto en cada frase); a veces, nada.
func hablar() -> void:
	if anim == null:
		return
	var lista: Array = HABLAR.get(quien, ["hablar"])
	if _ultimo_gesto == lista[0] and _rnd.randf() < 0.5:
		_ultimo_gesto = ""
		return
	gesto(lista[1] if _ultimo_gesto == lista[0] else lista[0])


func en_dialogo(si: bool) -> void:
	_hablando = si
	if not si:
		_espera = _rnd.randf_range(4.0, 8.0)


func mirar_a(punto: Vector3, dur := 0.6) -> void:
	var d := punto - global_position
	if Vector2(d.x, d.z).length() < 0.05:
		return
	var meta := atan2(d.x, d.z)
	meta = rotation.y + wrapf(meta - rotation.y, -PI, PI)
	if _tw_giro != null and _tw_giro.is_valid():
		_tw_giro.kill()
	_tw_giro = create_tween()
	_tw_giro.tween_property(self, "rotation:y", meta, dur).set_trans(Tween.TRANS_SINE)
