extends Node3D
# Humbaba, el Corazón del Bosque Muerto (V12, 12/11/2026, especialista de animaciones). Modelo, esqueleto de 72 huesos y
# 23 clips de fuente/crear_humbaba.py (Blender por guion, obra propia a partir de la lámina de referencia del usuario,
# que no se copia). Los instantes de cada clip (eventos) y los puntos del cuerpo en cada evento salen de
# humbaba_clips.json, que escribe el generador: este guion no tiene tiempos a mano.
#
# Contrato con el combate (el de los enemigos 3D de combate.gd, más lo suyo; combate_humbaba.gd lo usa):
#   reposo(), andar()/correr(), herida(), recibir_golpe(fuerte), tambalear(), morir()/derrota(), entrada(), victoria(),
#   revivir(), cansada(si), mirar(dir, dur), mirar_frente(dur), girar(izquierda) (paso de 45° en el sitio),
#   rugir(), atacar(ataque, al_impactar, al_evento): «puno», «raices», «aliento», «guadana», «ojo», «llamada», «abrazo»;
#   al_impactar se llama UNA vez por cada instante de daño del clip (IMPACTOS; el abrazo, dos: apretar_1 y apretar_2) y
#   al_evento(nombre) en cada evento con nombre del clip (aviso, hundir, aliento_inicio, rayo_inicio, invocar, agarre,
#   soltar…), en su fotograma; si el clip se corta, los impactos que falten se dan igual (una vez).
#   requiem_preparar(al_evento): se hunde y queda cargando (bucle) hasta requiem_descargar(al_impactar, al_evento),
#   que estalla y lo deja vulnerable (bucle); recuperarse() lo pone en pie.
#   cambiar_fase(n, al_evento): la transformación (fase 2: el núcleo se agrieta y se vuelve verde enfermizo; fase 3: la
#   armadura de corteza se rompe y el núcleo late expuesto), con su evento «cambio» en el instante del clip.
#   punto(nombre) → Vector3 global: «ojo», «nucleo», «boca», «mano_i», «mano_d», «baston_punta», «baston_cabeza».
# Señales: impacto(ataque), evento(clip, nombre), ataque_terminado(ataque), clip_terminado(clip).
# El brillo (ojo, núcleo, vetas) sigue en cada fotograma la escala X del hueso «luz» del clip (y la del «nucleo»).

signal impacto(ataque: String)
signal evento(clip: String, nombre: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const CARPETA := "res://enemigos/humbaba/"
const RUTAS := {"alto": CARPETA + "humbaba.glb", "medio": CARPETA + "humbaba_medio.glb", "bajo": CARPETA + "humbaba_bajo.glb"}
const TEXTURAS := {"alto": CARPETA + "humbaba_madera.webp", "medio": CARPETA + "humbaba_madera_medio.webp",
	"bajo": CARPETA + "humbaba_madera_bajo.webp"}
const JSON_CLIPS := CARPETA + "humbaba_clips.json"
const SH_MADERA := CARPETA + "humbaba_madera.gdshader"
const SH_BRILLO := CARPETA + "humbaba_brillo.gdshader"
const ALTURA := 13.3                          # metros del modelo (de los pies a la punta de la corona)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)
const BUCLES := ["idle", "idle_angry", "walk", "requiem_carga", "vulnerable"]
const ATAQUES := {"puno": "atk_puno", "raices": "atk_raices", "aliento": "atk_aliento", "guadana": "atk_guadana",
	"ojo": "atk_ojo", "llamada": "atk_llamada", "abrazo": "atk_abrazo", "requiem": "requiem_golpe"}
const IMPACTOS := {"atk_abrazo": ["apretar_1", "apretar_2"]}   # los demás: «impacto»
const GIRO := 45.0
# fases: color de la luz de las vetas y del núcleo, grietas y lo fuerte que late
const FASES := {
	1: {"vetas": Color(0.3, 0.98, 0.86), "nucleo": Color(1, 1, 1), "grietas": 0.0, "nucleo_e": 1.0},
	2: {"vetas": Color(0.62, 0.9, 0.32), "nucleo": Color(1.25, 1.55, 0.55), "grietas": 0.85, "nucleo_e": 1.25},
	3: {"vetas": Color(0.45, 1.0, 0.7), "nucleo": Color(1.35, 1.7, 0.75), "grietas": 1.0, "nucleo_e": 1.8},
}

@export var ruta_modelo := ""                 # vacío o la del alto: la versión de la calidad en uso
@export var calidad := ""                     # vacío: prototipos/calidad_proto.gd; «alto», «medio» o «bajo» la fuerza
@export var escala := 0.4                   # combate: 13,3 m → 5,3 (encuadre de MODELOS["humbaba"]); en el mundo, 1,0
@export var recortar := false                 # combate: lo que queda bajo el suelo no se dibuja

var anim: AnimationPlayer
var skel: Skeleton3D
var pivote: Node3D
var modelo: Node3D
var datos := {}                               # humbaba_clips.json
var calidad_usada := ""
var fase := 1
var vulnerable := false
var cargando := false
var _mat_madera: ShaderMaterial
var _mat_brillo: ShaderMaterial
var _armadura: Array = []
var _h_luz := -1
var _h_nucleo := -1
var _apagado := 1.0
var _tw_giro: Tween
var _muerta := false
var _atacando := false
var _clip := ""
var _eventos: Array = []


func _ready() -> void:
	process_priority = 10                     # después del AnimationPlayer
	pivote = Node3D.new()
	pivote.name = "Pivote"
	add_child(pivote)
	datos = leer_json()
	if escala < 0.99:                         # en el combate (escalado) se recorta lo que se hunde en la tierra
		recortar = true
	calidad_usada = calidad_en_uso()
	var ruta: String = RUTAS[calidad_usada]
	if ruta_modelo != "" and ruta_modelo != RUTAS["alto"] and ResourceLoader.exists(ruta_modelo):
		ruta = ruta_modelo
	if not ResourceLoader.exists(ruta):
		ruta = RUTAS["alto"]
		calidad_usada = "alto"
	modelo = (load(ruta) as PackedScene).instantiate()
	modelo.scale = Vector3.ONE * escala
	pivote.add_child(modelo)
	anim = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skel = _esqueleto(modelo)
	if anim:
		for n in BUCLES:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	if skel:
		_h_luz = skel.find_bone("luz")
		_h_nucleo = skel.find_bone("nucleo")
	_materiales()
	mirar(FRENTE_ENEMIGO, 0.0)
	reposo()


static func leer_json() -> Dictionary:
	if not FileAccess.file_exists(JSON_CLIPS):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(JSON_CLIPS))
	return d if d is Dictionary else {}


func calidad_en_uso() -> String:
	if calidad != "" and RUTAS.has(calidad):
		return calidad
	if ResourceLoader.exists("res://prototipos/calidad_proto.gd"):
		var c := str(load("res://prototipos/calidad_proto.gd").actual())
		if RUTAS.has(c):
			return c
	return "alto"


func _esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _esqueleto(c)
		if s:
			return s
	return null


func _shader(ruta: String) -> Shader:
	var codigo: String = (load(ruta) as Shader).code
	if not recortar:
		return load(ruta)
	var i := codigo.find("\n", codigo.find("shader_type"))
	var nuevo := Shader.new()
	nuevo.code = codigo.substr(0, i + 1) + "#define RECORTE\n" + codigo.substr(i + 1)
	return nuevo


# Superficies por el nombre de su material del GLB: «madera» y «brillo». La armadura (hombreras y brazales) es su propia
# malla («Humbaba_armadura»): en la fase 3 se rompe (se esconde; el combate pone las astillas).
func _materiales() -> void:
	var tex: Texture2D = load(TEXTURAS[calidad_usada]) if ResourceLoader.exists(TEXTURAS[calidad_usada]) else null
	_mat_madera = ShaderMaterial.new()
	_mat_madera.shader = _shader(SH_MADERA)
	_mat_madera.set_shader_parameter("textura", tex)
	_mat_brillo = ShaderMaterial.new()
	_mat_brillo.shader = _shader(SH_BRILLO)
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		if String(m.name).contains("armadura"):
			_armadura.append(m)
		for s in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(s)
			var nombre := orig.resource_name if orig != null else "madera"
			m.set_surface_override_material(s, _mat_brillo if nombre.begins_with("brillo") else _mat_madera)
	_poner_fase(fase)
	recortar_suelo(recortar)


# El combate no tiene suelo: lo que queda por debajo de y = 0 (garras y bastón hundidos) no se dibuja.
func recortar_suelo(si := true) -> void:
	var y := -0.02 * escala if si else -1000.0
	for m in [_mat_madera, _mat_brillo]:
		if m != null:
			m.set_shader_parameter("suelo", global_position.y + y if is_inside_tree() else y)


func _poner_fase(n: int) -> void:
	var f: Dictionary = FASES.get(n, FASES[1])
	_mat_madera.set_shader_parameter("color_luz", f["vetas"])
	_mat_madera.set_shader_parameter("grietas", f["grietas"])
	_mat_brillo.set_shader_parameter("color_nucleo", f["nucleo"])
	_mat_brillo.set_shader_parameter("grietas", f["grietas"])


func _process(delta: float) -> void:
	if skel != null and _h_luz >= 0:              # el brillo del clip (escala del hueso «luz»)
		var e := skel.get_bone_pose_scale(_h_luz).x * _apagado
		var en := skel.get_bone_pose_scale(_h_nucleo).x if _h_nucleo >= 0 else 1.0
		_mat_madera.set_shader_parameter("energia", e)
		_mat_brillo.set_shader_parameter("energia", e * 1.2)
		_mat_brillo.set_shader_parameter("energia_nucleo", e * en * float(FASES.get(fase, FASES[1])["nucleo_e"]))
	if _eventos.is_empty() or anim == null or String(anim.current_animation) != _clip:
		return
	var pos := anim.current_animation_position + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		(_eventos.pop_front()[1] as Callable).call()


# ---------------------------------------------------------------- clips

func info(clip: String) -> Dictionary:
	return datos.get("clips", {}).get(clip, {})


func eventos_de(clip: String) -> Dictionary:
	return info(clip).get("eventos", {})


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if anim != null and anim.has_animation(clip) else 0.0


func tiempo(clip: String, ev: String) -> float:
	return float(eventos_de(clip).get(ev, -1.0))


func _reproducir(clip: String, mezcla: float, extra: Array = []) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_clip = clip
	_eventos = []
	var evs := eventos_de(clip)
	for ev in evs:
		var nombre := String(ev)
		_eventos.append([float(evs[ev]), evento.emit.bind(clip, nombre)])
	_eventos.append_array(extra)
	_eventos.sort_custom(func(a, b): return a[0] < b[0])
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


func clip_actual() -> String:
	return _clip


func reposo() -> void:
	if _muerta:
		return
	if vulnerable:
		_reproducir("vulnerable", 0.3)
	elif cargando:
		_reproducir("requiem_carga", 0.3)
	else:
		_reproducir("idle_angry" if fase >= 2 else "idle", 0.35)


func andar() -> void:
	if not _muerta and not vulnerable:
		_reproducir("walk", 0.3)


func correr() -> void:
	andar()


# Paso de 45° en el sitio: al acabar el clip, el giro pasa al pivote (el clip termina en el reposo girado).
func girar(izquierda := true) -> void:
	if _muerta or vulnerable or cargando:
		return
	var clip := "turn_left" if izquierda else "turn_right"
	_reproducir(clip, 0.2)
	await _esperar_clip(clip)
	if _clip == clip:
		pivote.rotation.y += deg_to_rad(GIRO if izquierda else -GIRO)
		_reproducir("idle_angry" if fase >= 2 else "idle", 0.0)
		clip_terminado.emit(clip)


func cansada(si: bool) -> void:
	if anim:
		anim.speed_scale = 0.85 if si else 1.0


func herida() -> void:
	recibir_golpe(false)


func recibir_golpe(fuerte := false) -> void:
	if _muerta or _atacando or vulnerable or cargando:
		return
	var clip := "hit_heavy" if fuerte else "hit_light"
	_reproducir(clip, 0.06)
	await _esperar_clip(clip)
	if not _muerta and _clip == clip:
		reposo()


func tambalear() -> void:
	if _muerta or vulnerable or cargando:
		return
	_reproducir("stagger", 0.1)
	await _esperar_clip("stagger")
	if not _muerta and _clip == "stagger":
		reposo()


func rugir() -> void:
	if _muerta:
		return
	_reproducir("roar", 0.15)
	await _esperar_clip("roar")
	if not _muerta and _clip == "roar":
		reposo()
	clip_terminado.emit("roar")


func entrada() -> void:
	await rugir()
	clip_terminado.emit("entrada")


func victoria() -> void:
	if not _muerta:
		_reproducir("roar", 0.2)


func morir() -> void:
	derrota()


func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	_atacando = false
	vulnerable = false
	cargando = false
	_reproducir("death", 0.12)
	var t := create_tween()
	t.tween_property(self, "_apagado", 0.0, duracion("death") * 0.9)
	t.parallel().tween_method(_poner_apagar, 1.0, 0.35, duracion("death"))
	await _esperar_clip("death")
	clip_terminado.emit("death")


func revivir() -> void:
	_muerta = false
	_apagado = 1.0
	_mat_madera.set_shader_parameter("apagar", 1.0)
	_mat_brillo.set_shader_parameter("apagar", 1.0)
	reposo()


# ---------------------------------------------------------------- ataques

func atacar(ataque: String, al_impactar := Callable(), al_evento := Callable()) -> void:
	if _muerta:
		return
	var clip: String = ATAQUES.get(ataque, ataque)
	if anim == null or not anim.has_animation(clip):
		if al_impactar.is_valid():
			al_impactar.call()
		return
	_atacando = true
	var pendientes: Array = IMPACTOS.get(clip, ["impacto"]).duplicate()
	var extra: Array = []
	for ev in pendientes.duplicate():
		var nombre := String(ev)
		extra.append([tiempo(clip, nombre), _golpe_pendiente.bind(nombre, pendientes, ataque, al_impactar)])
	if al_evento.is_valid():
		var evs := eventos_de(clip)
		for ev in evs:
			var nombre := String(ev)
			extra.append([float(evs[ev]), _avisar.bind(al_evento, nombre)])
	_reproducir(clip, 0.12, extra)
	await _esperar_clip(clip)
	for nombre in pendientes.duplicate():                # cortado: lo que falte, una vez
		if _muerta:
			break
		pendientes.erase(nombre)
		impacto.emit(ataque)
		if al_impactar.is_valid():
			al_impactar.call()
	_atacando = false
	if not _muerta and _clip == clip and clip != "requiem_golpe":
		reposo()
	ataque_terminado.emit(ataque)


# El Réquiem, en dos turnos: el aviso (se hunde y queda cargando) y la descarga (estalla y queda vulnerable).
func requiem_preparar(al_evento := Callable()) -> void:
	if _muerta:
		return
	var extra: Array = []
	if al_evento.is_valid():
		var evs := eventos_de("requiem_inicio")
		for ev in evs:
			var nombre := String(ev)
			extra.append([float(evs[ev]), _avisar.bind(al_evento, nombre)])
	_atacando = true
	_reproducir("requiem_inicio", 0.15, extra)
	await _esperar_clip("requiem_inicio")
	_atacando = false
	if not _muerta:
		cargando = true
		_reproducir("requiem_carga", 0.1)


func requiem_descargar(al_impactar := Callable(), al_evento := Callable()) -> void:
	cargando = false
	await atacar("requiem", al_impactar, al_evento)
	if not _muerta:
		vulnerable = true
		_reproducir("vulnerable", 0.15)


func recuperarse() -> void:
	if _muerta or not vulnerable:
		vulnerable = false
		return
	vulnerable = false
	_reproducir("vulnerable_fin", 0.15)
	await _esperar_clip("vulnerable_fin")
	if not _muerta and _clip == "vulnerable_fin":
		reposo()


# La transformación de fase: el clip, y en su evento «cambio» el material de la fase (y en la 3, la armadura rota).
func cambiar_fase(n: int, al_evento := Callable()) -> void:
	if _muerta:
		return
	var extra: Array = [[tiempo("phase_transition", "cambio"), _cambio_ahora.bind(n)]]
	if al_evento.is_valid():
		var evs := eventos_de("phase_transition")
		for ev in evs:
			var nombre := String(ev)
			extra.append([float(evs[ev]), _avisar.bind(al_evento, nombre)])
	_atacando = true
	vulnerable = false
	cargando = false
	_reproducir("phase_transition", 0.15, extra)
	await _esperar_clip("phase_transition")
	_atacando = false
	if fase != n:                                  # (cortado antes del cambio)
		fase = n
		_poner_fase(n)
		if n >= 3:
			romper_armadura()
	if not _muerta and _clip == "phase_transition":
		reposo()
	clip_terminado.emit("phase_transition")


func romper_armadura() -> void:
	for m in _armadura:
		if is_instance_valid(m):
			m.visible = false


func armadura_rota() -> bool:
	return not _armadura.is_empty() and _armadura.all(func(m): return not m.visible)


# ---------------------------------------------------------------- orientación y puntos

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


const PUNTOS := {"ojo": ["ojo", 0.5], "nucleo": ["nucleo", 0.0], "boca": ["mandibula", 0.82], "mano_i": ["palma_i", 0.85],
	"mano_d": ["palma_d", 0.85], "baston_punta": ["baston", -4.1], "baston_cabeza": ["baston", 7.2]}


# Un punto del cuerpo en el mundo: [hueso, metros a lo largo de su eje Y desde su cabeza] (escala del modelo incluida).
func punto(nombre: String) -> Vector3:
	if skel == null or not PUNTOS.has(nombre):
		return global_position + Vector3(0, ALTURA * 0.6 * escala, 0)
	var i := skel.find_bone(PUNTOS[nombre][0])
	if i < 0:
		return global_position
	var t: Transform3D = skel.global_transform * skel.get_bone_global_pose(i)
	return t * Vector3(0, float(PUNTOS[nombre][1]), 0)


func punto_magia() -> Vector3:
	return punto("nucleo")


func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func puede_ser_objetivo() -> bool:
	return not _muerta


func muerta() -> bool:
	return _muerta


# ---------------------------------------------------------------- ayudas de los eventos

func _poner_apagar(v: float) -> void:
	_mat_madera.set_shader_parameter("apagar", v)
	_mat_brillo.set_shader_parameter("apagar", v)


func _avisar(cb: Callable, nombre: String) -> void:
	if not _muerta and cb.is_valid():
		cb.call(nombre)


func _golpe_pendiente(nombre: String, pendientes: Array, ataque: String, cb: Callable) -> void:
	if _muerta or not (nombre in pendientes):
		return
	pendientes.erase(nombre)
	impacto.emit(ataque)
	if cb.is_valid():
		cb.call()


func _cambio_ahora(n: int) -> void:
	fase = n
	_poner_fase(n)
	if n >= 3:
		romper_armadura()
