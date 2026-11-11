extends Node3D
# Tolvanera, el espíritu de polvo de la tormenta (V12, PROTOTIPO del 12/11/2026, especialista de animaciones). Modelo y
# clips de enemigos/tolvanera/fuentes_blender/crear_tolvanera.py (Blender por guion, obra propia); tiempos en
# tolvanera_clips.json. NO está en GRUPOS ni en los encuentros (ver docs/memory/agents/animaciones_v12_desierto_personajes.md).
#
# Mismo contrato que los enemigos 3D del combate (zarzalin_3d.gd) y lo suyo:
#   avisar()                     se encoge y aviva las brasas (señal aviso) y espera así la ráfaga
#   atacar("rafaga", cb)         a un héroe: se lanza 0,4 m (impacto a 0,433 s; desde el aviso)
#   atacar("torbellino", cb)     a todos: alto y fino, se desploma en una ola de arena (impacto a 0,867 s)
#   curarse_viento()             el viento le cura: crece y se aviva (señal curado a 0,73 s)
#   asentar_agua()               el Agua le hace más daño: se aplasta y se vuelve barro un momento (en vez de
#                                recibir_golpe cuando el golpe es de Agua)
# El polvo gira por el sombreado (tolvanera_polvo.gdshader) y los escombros, por este script (hueso «escombros»).

signal aviso(ataque: String)
signal impacto(ataque: String)
signal curado()
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/tolvanera/tolvanera.glb"
const ATLAS := "res://enemigos/tolvanera/tolvanera_atlas.png"
const ALTURA := 1.95
const CENTRO := Vector3(0.0, 1.0, 0.0)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)
const BUCLES := ["reposo", "correr"]
const ATAQUES := {"rafaga": {"impacto": 13.0 / 30.0}, "torbellino": {"impacto": 26.0 / 30.0}}
const VUELTAS_ESCOMBROS := 0.45             # vueltas por segundo de piedras, esquirlas y el jirón
# Materiales del polvo: [superficie, alfa, velocidad, vetas_u]
const CAPAS := {"nucleo": [0.85, 0.65, 2.0, Color(0.40, 0.30, 0.20)], "polvo": [0.45, 0.45, 3.0, Color(0.55, 0.42, 0.28)],
	"falda": [0.6, 0.9, 4.0, Color(0.50, 0.38, 0.25)]}

@export var escala := 1.0
var anim: AnimationPlayer
var skel: Skeleton3D
var pivote: Node3D
var _mats: Array[ShaderMaterial] = []
var _mat_brasas: ShaderMaterial
var _i_escombros := -1
var _giro_escombros := 0.0
var _tw_giro: Tween
var _muerta := false
var _atacando := false
var _cargando := false
var _clip := ""
var _eventos: Array = []
static var _ruido: NoiseTexture2D


func _ready() -> void:
	process_priority = 10
	pivote = Node3D.new()
	add_child(pivote)
	var m: Node3D = (load(RUTA_MODELO) as PackedScene).instantiate()
	m.scale = Vector3.ONE * escala
	pivote.add_child(m)
	anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skel = _esqueleto(m)
	if skel:
		_i_escombros = skel.find_bone("escombros")
	for n in BUCLES:
		if anim and anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	_materiales(m)
	mirar(FRENTE_ENEMIGO, 0.0)
	reposo()


func _esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _esqueleto(c)
		if s:
			return s
	return null


func _materiales(m: Node) -> void:
	if _ruido == null:
		_ruido = NoiseTexture2D.new()
		_ruido.width = 128
		_ruido.height = 128
		_ruido.seamless = true
		var fn := FastNoiseLite.new()
		fn.frequency = 0.035
		fn.fractal_octaves = 3
		_ruido.noise = fn
	var sh_polvo: Shader = load("res://enemigos/tolvanera/tolvanera_polvo.gdshader")
	_mat_brasas = ShaderMaterial.new()
	_mat_brasas.shader = load("res://enemigos/tolvanera/tolvanera_brasas.gdshader")
	_mat_brasas.render_priority = 2
	var escombros := StandardMaterial3D.new()
	escombros.albedo_texture = load(ATLAS)
	escombros.roughness = 0.6
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var malla: Mesh = (mi as MeshInstance3D).mesh
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in malla.get_surface_count():
			var nombre := String(malla.surface_get_material(s).resource_name) if malla.surface_get_material(s) else ""
			var mat: Material = escombros
			if CAPAS.has(nombre):
				var sm := ShaderMaterial.new()
				sm.shader = sh_polvo
				sm.set_shader_parameter("ruido", _ruido)
				sm.set_shader_parameter("alfa", CAPAS[nombre][0])
				sm.set_shader_parameter("velocidad", CAPAS[nombre][1])
				sm.set_shader_parameter("vetas_u", CAPAS[nombre][2])
				sm.set_shader_parameter("color_sombra", CAPAS[nombre][3])
				sm.render_priority = {"falda": -1, "nucleo": 0, "polvo": 1}[nombre]
				_mats.append(sm)
				mat = sm
			elif nombre == "brasas":
				mat = _mat_brasas
			(mi as MeshInstance3D).set_surface_override_material(s, mat)


func _param(nombre: String, v) -> void:
	for sm in _mats:
		sm.set_shader_parameter(nombre, v)


# ---------------------------------------------------------------- clips, anclas y escombros

func _process(delta: float) -> void:
	if skel and _i_escombros >= 0:
		_giro_escombros = fmod(_giro_escombros + delta * TAU * VUELTAS_ESCOMBROS, TAU)
		var eje := (skel.get_bone_rest(_i_escombros).basis.inverse() * Vector3.UP).normalized()
		skel.set_bone_pose_rotation(_i_escombros, skel.get_bone_pose_rotation(_i_escombros) * Quaternion(eje, _giro_escombros))
	if _eventos.is_empty() or anim == null or String(anim.current_animation) != _clip:
		return
	var pos := anim.current_animation_position + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		(_eventos.pop_front()[1] as Callable).call()


func _reproducir(clip: String, mezcla: float, eventos: Array = []) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_eventos = eventos.duplicate()
	_eventos.sort_custom(func(a, b): return a[0] < b[0])
	_clip = clip
	if String(anim.current_animation) == clip and clip in BUCLES:
		return
	anim.play(clip, mezcla)
	if anim.current_animation == clip:
		anim.seek(0.0, false)


func _esperar_clip(clip: String) -> void:
	while is_inside_tree() and anim != null and _clip == clip and String(anim.current_animation) == clip:
		await get_tree().process_frame


func play(nombre: String, transicion := 0.2) -> void:
	_reproducir(nombre, transicion)


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if anim != null and anim.has_animation(clip) else 0.0


func tiempo_impacto(ataque: String) -> float:
	return ATAQUES.get(ataque, {}).get("impacto", 0.0)


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if not _muerta:
		_cargando = false
		_reproducir("reposo", 0.3)


func andar() -> void:
	correr()


func correr() -> void:
	if not _muerta:
		_reproducir("correr", 0.2)


func cansada(si: bool) -> void:
	if anim:
		anim.speed_scale = 0.8 if si else 1.0
	_param("velocidad", 0.35 if si else 0.55)


func herida() -> void:
	recibir_golpe()


func morir() -> void:
	derrota()


func victoria() -> void:
	reposo()


func revivir() -> void:
	_muerta = false
	_param("desvanecer", 1.0)
	reposo()


func avisar(ataque := "rafaga") -> void:
	if _muerta or _atacando:
		return
	_cargando = true
	var dado := [false]
	var dar := func():
		if not dado[0]:
			dado[0] = true
			aviso.emit(ataque)
	_reproducir("aviso_rafaga", 0.15, [[9.0 / 30.0, dar]])
	await _esperar_clip("aviso_rafaga")
	dar.call()


func atacar(ataque: String, al_impactar := Callable()) -> void:
	if _muerta or not ATAQUES.has(ataque):
		return
	_atacando = true
	_cargando = false
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(ataque)
		if al_impactar.is_valid():
			al_impactar.call()
	_reproducir(ataque, 0.1, [[ATAQUES[ataque]["impacto"], golpe]])
	await _esperar_clip(ataque)
	if not hecho[0] and not _muerta:
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == ataque:
		reposo()
	ataque_terminado.emit(ataque)


func curarse_viento() -> void:
	if _muerta:
		return
	_reproducir("curarse_viento", 0.15, [[22.0 / 30.0, func(): curado.emit()]])
	var t := create_tween()
	t.tween_method(func(v): _param("velocidad", v), 0.55, 1.1, 0.6)
	t.tween_method(func(v): _param("velocidad", v), 1.1, 0.55, 0.7)
	await _esperar_clip("curarse_viento")
	if not _muerta and _clip == "curarse_viento":
		reposo()


func asentar_agua() -> void:
	if _muerta or _atacando:
		return
	_reproducir("agua_asienta", 0.05)
	var t := create_tween()
	t.tween_method(func(v): _param("barro", v), 0.0, 0.85, 0.15)
	t.tween_interval(0.6)
	t.tween_method(func(v): _param("barro", v), 0.85, 0.0, 0.6)
	await _esperar_clip("agua_asienta")
	if not _muerta and _clip == "agua_asienta":
		reposo()


func recibir_golpe() -> void:
	if _muerta or _atacando:
		return
	_reproducir("recibir_golpe", 0.06)
	await _esperar_clip("recibir_golpe")
	if not _muerta and _clip == "recibir_golpe":
		if _cargando:
			_reproducir("aviso_rafaga", 0.2)
		else:
			reposo()


func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	_reproducir("derrota", 0.1)
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_method(func(v): _param("desvanecer", v), 1.0, 0.0, 1.2)
	t.parallel().tween_method(func(v): _mat_brasas.set_shader_parameter("intensidad", v), 1.0, 0.0, 1.2)
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


func entrada() -> void:
	if _muerta:
		return
	_param("desvanecer", 0.0)
	var t := create_tween()
	t.tween_method(func(v): _param("desvanecer", v), 0.0, 1.0, 0.8)
	_reproducir("entrada", 0.0)
	await _esperar_clip("entrada")
	if not _muerta and _clip == "entrada":
		reposo()
	clip_terminado.emit("entrada")


func mirar(dir: Vector3, dur := 0.2) -> void:
	if pivote == null:
		return
	var meta := atan2(dir.x, dir.z)
	meta = pivote.rotation.y + wrapf(meta - pivote.rotation.y, -PI, PI)
	if _tw_giro and _tw_giro.is_valid():
		_tw_giro.kill()
	if dur <= 0.0:
		pivote.rotation.y = meta
		return
	_tw_giro = create_tween()
	_tw_giro.tween_property(pivote, "rotation:y", meta, dur)


func mirar_frente(dur := 0.25) -> void:
	mirar(FRENTE_ENEMIGO, dur)


func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func preparar_golpe() -> void:
	atacar("rafaga")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


func punto_magia() -> Vector3:
	return ojos()


func ojos() -> Vector3:
	if skel == null:
		return global_position + Vector3(0, 1.45, 0)
	var i := skel.find_bone("ojos")
	return (skel.global_transform * skel.get_bone_global_pose(i)).origin if i >= 0 else global_position
