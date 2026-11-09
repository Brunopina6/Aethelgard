extends Node3D
# Zarzalín, el jabalí de corteza (T-097): enemigo inicial de Pastos Verdes en la versión experimental.
# Modelo del bestiario del usuario (Meshy + Blender, D-075) con los clips nuevos de enemigos/zarzalin/fuentes_blender/.
#
# Se usa como los enemigos 3D del combate (goblin_3d.gd): combate.gd puede crearlo con .new() y ruta_modelo, o
# instanciar zarzalin_3d.tscn (que ya trae el modelo). Mantiene los métodos que el combate llama a un enemigo 3D
# (reposo, correr, herida, morir, cansada, mirar, mirar_frente, revivir…) y añade:
#   atacar(ataque, al_impactar)  embestida_espinosa o colmillo_lateral; espera con await hasta volver al reposo
#   avisar(ataque)               anuncia la embestida: baja el hocico, dos golpes de pezuña y se queda en carga
#   recibir_golpe(), derrota(), entrada()
# Señales:
#   aviso(ataque)       el hocico ya está bajo (0,267 s después de avisar): el combate puede mostrar su indicador
#   pezuna(n)           cada golpe de pezuña del aviso (1 a 0,467 s y 2 a 0,733 s), para el sonido de tierra
#   impacto(ataque)     el instante del golpe, UNA vez por ataque: daño, sonido y reacción del objetivo
#   ataque_terminado(ataque), clip_terminado(clip)
#
# El clip ya lleva el avance del ataque y vuelve a su sitio (la embestida adelanta el hocico 0,635 m en el impacto y
# 0,87 m al aterrizar). La posición lógica del combate va aparte: no hay que sumar otro avance durante el clip.
# alcance(ataque) dice cuánto adelanta el hocico en el impacto, para colocarlo delante del objetivo.

signal aviso(ataque: String)
signal pezuna(n: int)
signal impacto(ataque: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/zarzalin/zarzalin_completo.glb"
const ALTURA := 0.92                         # metros del suelo al lomo (Érebo lo lee: invocacion_erebo.gd, _altura)
const LARGO := 1.35                          # del hocico a la cola
const CENTRO := Vector3(0.0, 0.5, 0.0)       # centro del cuerpo (efectos y números de daño)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como goblin_3d.gd
const LARGO_CABEZA := 0.366                  # del cuello a la punta del hocico (hueso «head» de Blender)
# Clips del GLB. En bucle, solo el reposo, la espera en carga y el galope.
const CLIPS := ["reposo", "embestida_espinosa", "colmillo_lateral", "recibir_golpe", "derrota", "entrada",
	"aviso_embestida", "aviso_espera", "correr"]
const BUCLES := ["reposo", "aviso_espera", "correr"]
# Anclas de tiempo (segundos desde el principio del clip; fotograma de Blender - 1, a 30 fps), las de la ficha:
#   embestida_espinosa  retrocede y se agacha hasta 0,4 (fotograma 13), salta, IMPACTO a 0,567 (18), aterriza a 0,73,
#                       vuelve a su sitio y acaba a 1,267 en la pose del reposo
#   colmillo_lateral    gira la cabeza a su derecha hasta 0,3, barre y su IMPACTO es a 0,467 (15); acaba a 1,033
const ATAQUES := {
	"embestida_espinosa": {"impacto": 17.0 / 30.0, "carga": 12.0 / 30.0},
	"colmillo_lateral": {"impacto": 14.0 / 30.0},
}
const HOCICO_BAJO := 8.0 / 30.0              # aviso_embestida: el hocico llega abajo (fotograma 9)
const GOLPES_PEZUNA := [14.0 / 30.0, 22.0 / 30.0]   # aviso_embestida: los dos golpes de pezuña (fotogramas 15 y 23)
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.25
const MEZCLA_ATAQUE := 0.12
const MEZCLA_DESDE_CARGA := 0.1
const MEZCLA_GOLPE := 0.06
const RITMO_CANSADO := 0.8                   # el reposo, más lento con poca vida (solo el reposo: los ataques no)

@export var ruta_modelo := RUTA_MODELO
@export var escala := 1.0                     # tamaño del modelo (1 = el del bestiario: 0,92 m de alto)
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
var _cargando := false  # tras avisar(): en la pose de carga hasta la embestida
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
		push_warning("zarzalin_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
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
	push_warning("zarzalin_3d: no encuentro el modelo en %s" % ruta_modelo)


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


# Segundos desde que se llama a atacar() hasta su impacto (la embestida, desde la carga si está avisando).
func tiempo_impacto(ataque: String) -> float:
	if not ATAQUES.has(ataque):
		return 0.0
	var d: Dictionary = ATAQUES[ataque]
	if ataque == "embestida_espinosa" and _cargando:
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


# Ataque: «embestida_espinosa» o «colmillo_lateral». Emite impacto(ataque) y llama a al_impactar una sola vez, en el
# ancla del clip; vuelve al reposo y emite ataque_terminado. Si cae derrotado a medias, no golpea.
func atacar(ataque: String, al_impactar := Callable()) -> void:
	if _muerta or anim == null or not ATAQUES.has(ataque) or not anim.has_animation(ataque):
		return
	var d: Dictionary = ATAQUES[ataque]
	var desde := 0.0
	if ataque == "embestida_espinosa" and _cargando:
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


# Avisa de la embestida: baja el hocico (señal «aviso»), da dos golpes de pezuña y se queda en carga respirando hasta
# que el combate llame a atacar("embestida_espinosa") o a reposo().
func avisar(ataque := "embestida_espinosa") -> void:
	if _muerta or anim == null or _atacando:
		return
	_cargando = true
	var avisado := [false]
	var dar_aviso := func():
		if not avisado[0]:
			avisado[0] = true
			aviso.emit(ataque)
	var ev: Array = [[HOCICO_BAJO, dar_aviso]]
	for i in GOLPES_PEZUNA.size():
		ev.append([GOLPES_PEZUNA[i], pezuna.emit.bind(i + 1)])
	_reproducir("aviso_embestida", 0.2, 0.0, ev)
	await _esperar_clip("aviso_embestida")
	dar_aviso.call()                          # aunque un golpe lo corte antes, el aviso sale una vez
	if _cargando and not _muerta and (_clip == "aviso_embestida"):
		_reproducir("aviso_espera", 0.1)


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


# Para el combate genérico (_anim_fisico_3d): no lanza magia; el «golpe» es el colmillo lateral.
func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func preparar_golpe() -> void:
	atacar("colmillo_lateral")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


# Punta del hocico en el mundo (de ahí salen los efectos de sus golpes).
func punto_magia() -> Vector3:
	return hocico()


func hocico() -> Vector3:
	if skel == null:
		return global_position + Vector3(0, 0.5, 0)
	var i := skel.find_bone("head")
	if i < 0:
		return global_position + Vector3(0, 0.5, 0)
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y * LARGO_CABEZA          # basis.y ya lleva la escala del modelo


# ---------------------------------------------------------------- medidas de los clips (sin reproducirlos)

# Cuánto adelanta el hocico en el impacto del ataque respecto al reposo, en metros de este nodo (con «escala»).
func alcance(ataque: String) -> float:
	if not ATAQUES.has(ataque):
		return 0.0
	var en_impacto := _hocico_en(ataque, ATAQUES[ataque]["impacto"])
	var en_reposo := _hocico_en("reposo", 0.0)
	return (en_impacto.z - en_reposo.z) * escala


# Punta del hocico en el espacio del modelo en el segundo t de un clip (cinemática directa con las pistas del clip).
func _hocico_en(clip: String, t: float) -> Vector3:
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
