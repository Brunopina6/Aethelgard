extends Node3D
# Vidracrán, el escorpión de vidrio (V12, PROTOTIPO del 12/11/2026, especialista de animaciones). Modelo y clips de
# enemigos/vidracran/fuentes_blender/crear_vidracran.py (Blender por guion, obra propia); tiempos en
# vidracran_clips.json. NO está en GRUPOS ni en los encuentros: lo que haría falta en el combate está en
# docs/memory/agents/animaciones_v12_desierto_personajes.md.
#
# Mismo contrato que los enemigos 3D del combate (zarzalin_3d.gd): reposo, correr, herida, morir, cansada, mirar,
# mirar_frente, revivir, atacar(ataque, al_impactar), recibir_golpe, derrota, entrada. Y lo suyo:
#   enterrarse()          escarba y se hunde; queda «enterrado» (solo la cola fuera): puede_ser_objetivo() = false
#   avisar()              enterrado: el bulbo late dos veces (señal aviso) y sigue enterrado
#   atacar("emerger_aguijon", cb)   solo enterrado: revienta la arena y pica (impacto a 0,5 s); queda en reposo
#   atacar("pinzas", cb)            fuera: tenaza con avance de 0,25 m (impacto a 0,467 s)
# Señales: aviso(ataque), impacto(ataque), ataque_terminado(ataque), clip_terminado(clip), enterrado_cambio(si).
# El combate debe moverlo bajo el objetivo MIENTRAS está enterrado (no se ve: solo la cola, que puede ir con él).

signal aviso(ataque: String)
signal impacto(ataque: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)
signal enterrado_cambio(si: bool)

const RUTA_MODELO := "res://enemigos/vidracran/vidracran.glb"
const ATLAS := "res://enemigos/vidracran/vidracran_atlas.png"
const ALTURA := 0.55                         # del suelo al lomo con la cola (sin el bulbo: 1,0)
const CENTRO := Vector3(0.0, 0.35, 0.0)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)
const CLIPS := ["reposo", "pinzas", "enterrarse", "enterrado", "aviso_aguijon", "emerger_aguijon", "recibir_golpe",
	"derrota", "entrada", "correr"]
const BUCLES := ["reposo", "enterrado", "correr"]
const ATAQUES := {"pinzas": {"impacto": 14.0 / 30.0}, "emerger_aguijon": {"impacto": 15.0 / 30.0}}
const LATIDOS := [4.0 / 30.0, 12.0 / 30.0]  # aviso_aguijon: los dos latidos del bulbo
const BRILLO := {"reposo": 1.0, "enterrado": 1.4, "pinzas": 1.3, "emerger_aguijon": 2.4, "correr": 1.0,
	"entrada": 1.2, "recibir_golpe": 1.8, "enterrarse": 1.2}

@export var escala := 1.0
# V12, encuentro del desierto (12/11): combate.gd lo crea con .new() y pone ruta_modelo (como a Zarzalín).
@export var ruta_modelo := RUTA_MODELO
var anim: AnimationPlayer
var skel: Skeleton3D
var pivote: Node3D
var enterrado := false
var _mat_vidrio: ShaderMaterial
var _mat_brillo: ShaderMaterial
var _halo: MeshInstance3D
var _brillo := 1.0
var _tw_brillo: Tween
var _tw_giro: Tween
var _muerta := false
var _atacando := false
var _clip := ""
var _eventos: Array = []


func _ready() -> void:
	process_priority = 10
	pivote = Node3D.new()
	pivote.name = "Pivote"
	add_child(pivote)
	var m: Node3D = (load(ruta_modelo if ruta_modelo != "" else RUTA_MODELO) as PackedScene).instantiate()
	m.scale = Vector3.ONE * escala
	pivote.add_child(m)
	anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skel = _esqueleto(m)
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


# Superficies por nombre: «caparazon» → vidrio ámbar; «brillo» → bulbo y ojos. Y el halo del bulbo (aditivo).
func _materiales(m: Node) -> void:
	var atlas: Texture2D = load(ATLAS)
	_mat_vidrio = ShaderMaterial.new()
	_mat_vidrio.shader = load("res://enemigos/vidracran/vidracran_vidrio.gdshader")
	_mat_vidrio.set_shader_parameter("atlas", atlas)
	_mat_brillo = ShaderMaterial.new()
	_mat_brillo.shader = load("res://enemigos/vidracran/vidracran_brillo.gdshader")
	_mat_brillo.set_shader_parameter("atlas", atlas)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var malla: Mesh = (mi as MeshInstance3D).mesh
		for s in malla.get_surface_count():
			var nombre := String(malla.surface_get_material(s).resource_name) if malla.surface_get_material(s) else ""
			(mi as MeshInstance3D).set_surface_override_material(s, _mat_brillo if nombre.begins_with("brillo") else _mat_vidrio)
	if skel == null:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "aguijon"
	skel.add_child(ba)
	_halo = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 0.55)
	_halo.mesh = q
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	var mh := StandardMaterial3D.new()
	mh.albedo_texture = g
	mh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mh.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mh.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mh.no_depth_test = false
	mh.albedo_color = Color(0.35, 1.0, 0.5)
	_halo.material_override = mh
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ba.add_child(_halo)
	_halo.position = Vector3(0, 0.0, 0)


func _poner_brillo(v: float) -> void:
	_brillo = v
	if _mat_brillo:
		_mat_brillo.set_shader_parameter("intensidad", v)
	if _halo:
		var k := clampf(v / 1.4, 0.0, 3.0)
		(_halo.material_override as StandardMaterial3D).albedo_color = Color(0.35, 1.0, 0.5) * clampf(0.25 * v, 0.0, 1.0)
		_halo.scale = Vector3.ONE * (0.6 + 0.4 * k)


func _brillo_a(v: float, dur: float) -> void:
	if _tw_brillo and _tw_brillo.is_valid():
		_tw_brillo.kill()
	_tw_brillo = create_tween()
	_tw_brillo.tween_method(_poner_brillo, _brillo, v, dur)


# ---------------------------------------------------------------- clips y anclas (como zarzalin_3d.gd)

func _process(delta: float) -> void:
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
	if BRILLO.has(clip):
		_brillo_a(BRILLO[clip], 0.3)


func _esperar_clip(clip: String) -> void:
	while is_inside_tree() and anim != null and _clip == clip and String(anim.current_animation) == clip:
		await get_tree().process_frame


func play(nombre: String, transicion := 0.2) -> void:
	_reproducir(nombre, transicion)


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if anim != null and anim.has_animation(clip) else 0.0


func tiempo_impacto(ataque: String) -> float:
	return ATAQUES.get(ataque, {}).get("impacto", 0.0)


func puede_ser_objetivo() -> bool:
	return not enterrado and not _muerta


# V12, encuentro del desierto (12/11): cuánto adelanta la pinza en el impacto (combate.gd lo usa para plantarlo
# delante del objetivo, como a Zarzalín); el aguijón pica donde está, sin avance.
func alcance(ataque: String) -> float:
	return 0.25 if ataque == "pinzas" else 0.0


# V12, encuentro del desierto: en el combate no hay suelo; con «si», lo que queda bajo y = 0 (el cuerpo enterrado) no
# se dibuja (vidracran_vidrio/brillo.gdshader, «suelo_y»). Sin llamarla, como en el prototipo.
func recortar_suelo(si := true) -> void:
	var y := -0.01 if si else -1000.0
	for m in [_mat_vidrio, _mat_brillo]:
		if m != null:
			m.set_shader_parameter("suelo_y", y)


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta:
		return
	_reproducir("enterrado" if enterrado else "reposo", 0.25)


func andar() -> void:
	correr()


func correr() -> void:
	if not _muerta and not enterrado:
		_reproducir("correr", 0.12)


func cansada(si: bool) -> void:
	if anim:
		anim.speed_scale = 0.8 if si else 1.0


func herida() -> void:
	recibir_golpe()


func morir() -> void:
	derrota()


func victoria() -> void:
	reposo()


func revivir() -> void:
	_muerta = false
	_poner_brillo(1.0)
	_mat_vidrio.set_shader_parameter("apagar", 1.0)
	reposo()


func enterrarse() -> void:
	if _muerta or enterrado or _atacando:
		return
	_reproducir("enterrarse", 0.12)
	await _esperar_clip("enterrarse")
	if _muerta or _clip != "enterrarse":
		return
	enterrado = true
	enterrado_cambio.emit(true)
	_reproducir("enterrado", 0.1)


func avisar(ataque := "emerger_aguijon") -> void:
	if _muerta or not enterrado:
		return
	var avisado := [false]
	var latido := func():
		_poner_brillo(3.5)
		_brillo_a(1.4, 0.22)
		if not avisado[0]:
			avisado[0] = true
			aviso.emit(ataque)
	_reproducir("aviso_aguijon", 0.1, [[LATIDOS[0], latido], [LATIDOS[1], latido]])
	await _esperar_clip("aviso_aguijon")
	if not avisado[0]:
		avisado[0] = true
		aviso.emit(ataque)
	if enterrado and not _muerta and _clip == "aviso_aguijon":
		_reproducir("enterrado", 0.1)


func atacar(ataque: String, al_impactar := Callable()) -> void:
	if _muerta or not ATAQUES.has(ataque):
		return
	if ataque == "emerger_aguijon" and not enterrado:
		ataque = "pinzas"                     # fuera de la arena no puede emerger: tenaza
	elif ataque == "pinzas" and enterrado:
		ataque = "emerger_aguijon"
	_atacando = true
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(ataque)
		if al_impactar.is_valid():
			al_impactar.call()
	if ataque == "emerger_aguijon":
		enterrado = false
		enterrado_cambio.emit(false)
	_reproducir(ataque, 0.08, [[ATAQUES[ataque]["impacto"], golpe]])
	await _esperar_clip(ataque)
	if not hecho[0] and not _muerta:
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == ataque:
		reposo()
	ataque_terminado.emit(ataque)


func recibir_golpe() -> void:
	if _muerta or _atacando or enterrado:
		return
	_reproducir("recibir_golpe", 0.06)
	await _esperar_clip("recibir_golpe")
	if not _muerta and _clip == "recibir_golpe":
		reposo()


func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	enterrado = false
	_reproducir("derrota", 0.1)
	_brillo_a(0.0, 1.4)
	var t := create_tween()
	t.tween_method(func(v): _mat_vidrio.set_shader_parameter("apagar", v), 1.0, 0.25, 1.4)
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


func entrada() -> void:
	if _muerta:
		return
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
	atacar("pinzas")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


func punto_magia() -> Vector3:
	return bulbo()


# El bulbo de la cola en el mundo (de ahí sale el destello del aviso y el efecto del picotazo).
func bulbo() -> Vector3:
	if skel == null:
		return global_position + Vector3(0, 0.9, 0)
	var i := skel.find_bone("aguijon")
	return (skel.global_transform * skel.get_bone_global_pose(i)).origin if i >= 0 else global_position
