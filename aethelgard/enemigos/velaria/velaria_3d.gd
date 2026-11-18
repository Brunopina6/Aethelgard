extends Node3D
# Velaria, la polilla de alas como postigos de farol (T-097, bestiario 01): hostigadora de ruinas húmedas.
# Modelo del bestiario del usuario (Meshy + Blender, D-075) con los clips nuevos de enemigos/velaria/fuentes_blender/.
#
# Se usa como Zarzalín y Cencerrante (enemigos/*/): combate.gd puede crearlo con .new() y ruta_modelo, o instanciar
# velaria_3d.tscn (que ya trae el modelo). Mantiene los métodos que el combate llama a un enemigo 3D (reposo, correr,
# herida, morir, cansada, mirar, mirar_frente, revivir…) y añade:
#   atacar(ataque, al_impactar)  «corte_de_ala» (se eleva y pasa en diagonal con un golpe corto) o «destello_de_velo»
#                                (repliega las alas para concentrar la luz y las abre al soltarla: el proyectil);
#                                espera con await hasta volver al reposo
#   avisar(ataque)               anuncia el destello: repliega las alas (señal «aviso») y se queda con la luz
#                                concentrada (aviso_espera) hasta que el combate llame a atacar("destello_de_velo")
#   recibir_golpe(), derrota(), entrada()
# Señales:
#   aviso(ataque)       las alas ya están replegadas (0,4 s después de avisar): el combate puede mostrar su indicador
#   impacto(ataque)     el instante del golpe, UNA vez por ataque. En el destello es el instante en que suelta la luz
#                       (abre las alas): el viaje del proyectil y su golpe son del combate
#   ataque_terminado(ataque), clip_terminado(clip)
#
# Vuela: en el reposo flota 0,23 m por encima del suelo. El corte de ala ya lleva su avance (0,39 m) y vuelve a su sitio:
# la posición lógica del combate va aparte. alcance(ataque) dice cuánto adelanta la cabeza en el impacto.

signal aviso(ataque: String)
signal impacto(ataque: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/velaria/velaria_completo.glb"
const ALTURA := 1.38                         # metros del suelo a la punta de las alas, flotando (Érebo lo lee: _altura)
const CENTRO := Vector3(0.0, 0.75, 0.0)      # centro del cuerpo (efectos y números de daño)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como goblin_3d.gd
const LARGO_CABEZA := 0.127                  # del cuello a la punta de la cabeza (hueso «head» de Blender)
# Clips del GLB. En bucle, solo el reposo, la espera con la luz concentrada y el aleteo.
const CLIPS := ["reposo", "destello_de_velo", "corte_de_ala", "recibir_golpe", "derrota", "entrada", "aviso_espera",
	"correr"]
const BUCLES := ["reposo", "aviso_espera", "correr"]
# Anclas de tiempo (segundos desde el principio del clip; fotograma de Blender - 1, a 30 fps), las de la ficha:
#   destello_de_velo  repliega las alas hasta 0,4 (fotograma 13; quietas hasta 0,533, el 17) y las abre: SUELTA LA LUZ a
#                     0,70 (fotograma 22); acaba a 1,267 en la pose del reposo
#   corte_de_ala      se eleva hasta 0,27, se lanza en diagonal y GOLPEA a 0,50 (fotograma 16); vuelve hasta 1,167
const ATAQUES := {
	"destello_de_velo": {"impacto": 21.0 / 30.0, "carga": 16.0 / 30.0},
	"corte_de_ala": {"impacto": 15.0 / 30.0},
}
const ALAS_REPLEGADAS := 12.0 / 30.0         # destello_de_velo: las alas ya están replegadas (fotograma 13)
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.25
const MEZCLA_ATAQUE := 0.12
const MEZCLA_DESDE_CARGA := 0.1
const MEZCLA_GOLPE := 0.06
const RITMO_CANSADO := 0.8                   # el reposo, más lento con poca vida (solo el reposo: los ataques no)

@export var ruta_modelo := RUTA_MODELO
@export var escala := 1.0                     # tamaño del modelo (1 = el del bestiario: 1,15 m de alas, flotando)
var rutas_extra: Array = []

var anim: AnimationPlayer
var skel: Skeleton3D
var caida: Node3D       # mismo esquema que maga_3d.gd: caida > pivote (mira) > ajuste (escala) > modelo
var pivote: Node3D
var ajuste: Node3D
var nombres := {}       # compatibilidad con maga_3d.gd: nombre lógico -> clip
var _yaw0 := 0.0        # el modelo mira a +Z
var _tw_giro: Tween
var _muerta := false
var _cansada := false
var _cargando := false  # tras avisar(): con la luz concentrada hasta soltarla
var _atacando := false
var _entrando := false
var _clip := ""         # el último clip pedido
var _eventos: Array = []   # [[segundo, Callable]] pendientes del clip actual, en orden


func _ready() -> void:
	process_priority = 10                    # después del AnimationPlayer: lee la posición del clip de este fotograma
	caida = Node3D.new()
	caida.name = "Caida"
	pivote = Node3D.new()
	pivote.name = "Pivote"
	ajuste = Node3D.new()
	ajuste.name = "Ajuste"
	var previos := get_children()
	add_child(caida)
	caida.add_child(pivote)
	pivote.add_child(ajuste)
	if previos.is_empty():
		_cargar_modelo()
	else:
		for c in previos:
			c.reparent(ajuste, false)
	ajuste.scale = Vector3.ONE * escala
	anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	skel = _buscar_esqueleto(self)
	if anim == null or skel == null:
		push_warning("velaria_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	for n in BUCLES:                          # el .import ya los pone en bucle; por si se reimporta sin esa opción
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in CLIPS:
		nombres[n] = n
	nombres["Idle"] = "reposo"
	nombres["Running"] = "correr"
	nombres["Walking"] = "correr"
	mirar(FRENTE_ENEMIGO, 0.0)
	reposo()


func _cargar_modelo() -> void:
	for r in [ruta_modelo] + rutas_extra:
		if ResourceLoader.exists(r):
			var escena = load(r)
			if escena is PackedScene:
				ajuste.add_child(escena.instantiate())
				return
	push_warning("velaria_3d: no encuentro el modelo en %s" % ruta_modelo)


func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _buscar_esqueleto(c)
		if s != null:
			return s
	return null


# ---------------------------------------------------------------- clips y anclas

# Cada ancla salta en el fotograma más cercano a su segundo del clip (como mucho, medio fotograma de diferencia): este
# nodo se procesa después del AnimationPlayer (process_priority), así que lee la posición que se va a dibujar.
func _process(delta: float) -> void:
	if _eventos.is_empty() or anim == null:
		return
	if String(anim.current_animation) != _clip:
		return
	var pos := anim.current_animation_position + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		var e: Array = _eventos.pop_front()
		(e[1] as Callable).call()


# Pone un clip (desde el segundo «desde») con sus anclas [[segundo, Callable]]. Las anclas de un clip anterior que no
# hayan llegado se descartan (salvo las que el que llama asegura por su cuenta, como el impacto).
func _reproducir(clip: String, mezcla: float, desde := 0.0, eventos: Array = []) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_eventos = eventos.duplicate()
	_eventos.sort_custom(func(a, b): return a[0] < b[0])
	_clip = clip
	anim.speed_scale = RITMO_CANSADO if (_cansada and clip == "reposo") else 1.0
	if String(anim.current_animation) == clip:
		if not (clip in BUCLES and desde == 0.0):   # un bucle que ya suena sigue sin saltar; lo demás vuelve a empezar
			anim.seek(desde, true)
	else:
		anim.play(clip, mezcla)
		if desde > 0.0:
			anim.seek(desde, true)


# Espera a que acabe el clip, a que otro lo sustituya o a que el nodo salga del árbol.
func _esperar_clip(clip: String) -> void:
	while is_inside_tree() and anim != null and _clip == clip and String(anim.current_animation) == clip:
		await get_tree().process_frame


func play(nombre: String, transicion := 0.2) -> void:
	_reproducir(nombres.get(nombre, nombre), transicion)


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if anim != null and anim.has_animation(clip) else 0.0


# Segundos desde que se llama a atacar() hasta su impacto (el destello, desde la luz concentrada si está avisando).
func tiempo_impacto(ataque: String) -> float:
	if not ATAQUES.has(ataque):
		return 0.0
	var d: Dictionary = ATAQUES[ataque]
	if ataque == "destello_de_velo" and _cargando:
		return d["impacto"] - d["carga"]
	return d["impacto"]


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta or anim == null:
		return
	_cargando = false
	_reproducir("reposo", MEZCLA_REPOSO)


func andar() -> void:
	correr()


func correr() -> void:
	if _muerta or anim == null:
		return
	_reproducir("correr", 0.12)


func cansada(si: bool) -> void:
	_cansada = si
	if not _muerta and anim != null and _clip == "reposo":
		anim.speed_scale = RITMO_CANSADO if si else 1.0


func herida() -> void:
	recibir_golpe()


func morir() -> void:
	derrota()


func victoria() -> void:
	reposo()


func revivir() -> void:
	if not _muerta:
		return
	_muerta = false
	reposo()


# Ataque: «corte_de_ala» o «destello_de_velo» (si está avisando, el destello sigue desde la luz concentrada). Emite impacto(ataque) y llama a al_impactar una sola vez, en el
# ancla del clip; vuelve al reposo y emite ataque_terminado. Si cae derrotado a medias, no golpea.
func atacar(ataque: String, al_impactar := Callable()) -> void:
	if _muerta or anim == null or not ATAQUES.has(ataque) or not anim.has_animation(ataque):
		return
	var d: Dictionary = ATAQUES[ataque]
	var desde := 0.0
	if ataque == "destello_de_velo" and _cargando:
		desde = d["carga"]                    # sigue desde la pose de carga del aviso (0,4 s): sin repetir la preparación
	_cargando = false
	_atacando = true
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(ataque)
		if al_impactar.is_valid():
			al_impactar.call()
	_reproducir(ataque, MEZCLA_DESDE_CARGA if desde > 0.0 else MEZCLA_ATAQUE, desde, [[d["impacto"], golpe]])
	await _esperar_clip(ataque)
	if not hecho[0] and not _muerta:          # lo cortó otro clip antes del golpe: el daño se resuelve igual, una vez
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == ataque:
		reposo()
	ataque_terminado.emit(ataque)


# Anuncia el destello: repliega las alas para concentrar la luz (señal «aviso», una vez, con las alas replegadas, a
# 0,4 s) y se queda así, flotando (aviso_espera), hasta que el combate llame a atacar("destello_de_velo") o a reposo().
func avisar(ataque := "destello_de_velo") -> void:
	if _muerta or anim == null or _atacando or ataque != "destello_de_velo":
		return
	_cargando = true
	var avisado := [false]
	var dar_aviso := func():
		if not avisado[0] and not _muerta:
			avisado[0] = true
			aviso.emit(ataque)
	var a_la_espera := func():
		if _cargando and not _muerta:
			_reproducir("aviso_espera", 0.05)
	_reproducir("destello_de_velo", 0.15, 0.0, [[ALAS_REPLEGADAS, dar_aviso], [ATAQUES[ataque]["carga"], a_la_espera]])
	await _esperar_clip("destello_de_velo")
	dar_aviso.call()                          # aunque un golpe lo corte antes, el aviso sale una vez


func recibir_golpe() -> void:
	if _muerta or anim == null or _atacando or _entrando:
		return                                # atacando o entrando no se interrumpe (el combate ya muestra el golpe)
	_reproducir("recibir_golpe", MEZCLA_GOLPE)
	await _esperar_clip("recibir_golpe")
	if _muerta or _clip != "recibir_golpe":
		return
	if _cargando:
		_reproducir("aviso_espera", 0.2)
	else:
		reposo()


# Cae de lado y se queda quieto (el combate lo desvanece después, como a los demás enemigos 3D).
func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	_cargando = false
	if anim == null:
		return
	_reproducir("derrota", 0.1)
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


# Llega a su sitio de un salto desde 0,85 m por detrás (empieza ahí, sin mezcla) y queda en reposo.
func entrada() -> void:
	if _muerta or anim == null:
		return
	_entrando = true
	_reproducir("entrada", 0.0)
	await _esperar_clip("entrada")
	_entrando = false
	if _muerta:
		return
	if _clip == "entrada":
		reposo()
	clip_terminado.emit("entrada")


# Gira para mirar en la dirección «dir» (en el mundo; la cámara del combate está en +Z).
func mirar(dir: Vector3, dur := 0.2) -> void:
	if pivote == null:
		return
	var meta := atan2(dir.x, dir.z) - _yaw0
	var actual := pivote.rotation.y
	meta = actual + wrapf(meta - actual, -PI, PI)
	if _tw_giro != null and _tw_giro.is_valid():
		_tw_giro.kill()
	if dur <= 0.0:
		pivote.rotation.y = meta
		return
	_tw_giro = create_tween()
	_tw_giro.tween_property(pivote, "rotation:y", meta, dur)


func mirar_frente(dur := 0.25) -> void:
	mirar(FRENTE_ENEMIGO, dur)


# Para el combate genérico (_anim_fisico_3d): no lanza magia; el «golpe» es el corte de ala.
func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func preparar_golpe() -> void:
	atacar("corte_de_ala")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


# Centro del cuerpo, donde concentra la luz (de ahí salen el destello y los efectos de sus golpes).
func punto_magia() -> Vector3:
	return luz()


# El pecho, donde se ve la luz que concentra (a media altura del hueso «body»).
func luz() -> Vector3:
	if skel == null:
		return global_position + CENTRO
	var i := skel.find_bone("body")
	if i < 0:
		return global_position + CENTRO
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y * 0.2


# Punta de la cabeza en el mundo.


func cabeza() -> Vector3:
	if skel == null:
		return global_position + CENTRO
	var i := skel.find_bone("head")
	if i < 0:
		return global_position + CENTRO
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y * LARGO_CABEZA          # basis.y ya lleva la escala del modelo


# ---------------------------------------------------------------- medidas de los clips (sin reproducirlos)

# Cuánto adelanta la cabeza en el impacto del ataque respecto al reposo, en metros de este nodo (con «escala»).
func alcance(ataque: String) -> float:
	if not ATAQUES.has(ataque):
		return 0.0
	var en_impacto := _cabeza_en(ataque, ATAQUES[ataque]["impacto"])
	var en_reposo := _cabeza_en("reposo", 0.0)
	return (en_impacto.z - en_reposo.z) * escala


# Punta de la cabeza en el espacio del modelo en el segundo t de un clip (cinemática directa con las pistas del clip).
func _cabeza_en(clip: String, t: float) -> Vector3:
	if anim == null or skel == null or not anim.has_animation(clip):
		return Vector3.ZERO
	var a := anim.get_animation(clip)
	var cadena: Array[int] = []
	var i := skel.find_bone("head")
	while i >= 0:
		cadena.push_front(i)
		i = skel.get_bone_parent(i)
	var g := Transform3D.IDENTITY
	for b in cadena:
		var rest := skel.get_bone_rest(b)
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var sufijo := ":" + skel.get_bone_name(b)
		for k in a.get_track_count():
			if not String(a.track_get_path(k)).ends_with(sufijo):
				continue
			match a.track_get_type(k):
				Animation.TYPE_POSITION_3D:
					pos = a.position_track_interpolate(k, t)
				Animation.TYPE_ROTATION_3D:
					rot = a.rotation_track_interpolate(k, t)
		g = g * Transform3D(Basis(rot), pos)
	return g.origin + g.basis.y.normalized() * LARGO_CABEZA
