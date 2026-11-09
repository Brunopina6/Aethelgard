extends Node3D
# Cencerrante, la campana con patas (T-097, bestiario 01): segunda bestia, de apoyo, en un camino abandonado.
# Modelo del bestiario del usuario (Meshy + Blender, D-075) con los clips nuevos de enemigos/cencerrante/fuentes_blender/.
#
# Se usa como Zarzalín (enemigos/zarzalin/zarzalin_3d.gd) y los demás enemigos 3D del combate: combate.gd puede crearlo
# con .new() y ruta_modelo, o instanciar cencerrante_3d.tscn (que ya trae el modelo). Mantiene los métodos que el
# combate llama a un enemigo 3D (reposo, correr, herida, morir, cansada, mirar, mirar_frente, revivir…) y añade:
#   atacar(ataque, al_impactar)  «campanada_baja» (carga de lado y hace sonar la campana bajo); espera con await
#   avisar(ataque)               «toque_de_alarma»: la campana toma impulso y repica (el aviso de la ficha: el siguiente
#                                golpe de un aliado irá reforzado o, si está solo, prepara su ataque); vuelve al reposo
#   recibir_golpe(), derrota(), entrada()
# Señales:
#   aviso(ataque)       el repique del toque de alarma (0,733 s después de avisar): indicador y sonido
#   impacto(ataque)     el instante del golpe, UNA vez por ataque: daño, sonido y reacción del objetivo
#   ataque_terminado(ataque), clip_terminado(clip)
# La regla del aviso (refuerzo con límite de una activación) es del combate: aquí solo están el gesto y su ancla.
#
# El clip ya lleva el avance de la carga (el marco se adelanta 0,48 m) y vuelve a su sitio: la posición lógica del
# combate va aparte. alcance(ataque) dice cuánto adelanta la boca de la campana en el impacto, para colocarlo delante
# del objetivo.

signal aviso(ataque: String)
signal impacto(ataque: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/cencerrante/cencerrante_completo.glb"
const ALTURA := 1.52                         # metros del suelo a lo alto del marco (Érebo lo lee: _altura)
const CENTRO := Vector3(0.0, 0.95, 0.0)      # centro del cuerpo: la campana (efectos y números de daño)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como goblin_3d.gd
const LARGO_CAMPANA := 0.505                 # del enganche a la boca de la campana (hueso «bell» de Blender)
# Clips del GLB. En bucle, solo el reposo y el andar a saltitos.
const CLIPS := ["reposo", "toque_de_alarma", "campanada_baja", "recibir_golpe", "derrota", "entrada", "correr"]
const BUCLES := ["reposo", "correr"]
# Anclas de tiempo (segundos desde el principio del clip; fotograma de Blender - 1, a 30 fps), las de la ficha:
#   campanada_baja   toma impulso hacia atrás hasta 0,37, carga de lado, IMPACTO a 0,533 (fotograma 17) con la campana
#                    abajo y adelante, y vuelve a su sitio hasta 1,167 con el vaivén amortiguado
#   toque_de_alarma  la campana toma impulso hacia atrás (hasta 0,57) y REPICA a 0,733 (fotograma 23); acaba a 1,4
const ATAQUES := {
	"campanada_baja": {"impacto": 16.0 / 30.0},
}
const AVISOS := {
	"toque_de_alarma": {"repique": 22.0 / 30.0},
}
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.25
const MEZCLA_ATAQUE := 0.12
const MEZCLA_GOLPE := 0.06
const RITMO_CANSADO := 0.8                   # el reposo, más lento con poca vida (solo el reposo: los ataques no)

@export var ruta_modelo := RUTA_MODELO
@export var escala := 1.0                     # tamaño del modelo (1 = el del bestiario: 1,52 m de alto)
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
var _atacando := false
var _avisando := false
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
		push_warning("cencerrante_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
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
	push_warning("cencerrante_3d: no encuentro el modelo en %s" % ruta_modelo)


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


# Segundos desde que se llama a atacar() (o a avisar()) hasta su impacto (o su repique).

# ---------------------------------------------------------------- lo que pide el combate

func tiempo_impacto(ataque: String) -> float:
	if ATAQUES.has(ataque):
		return ATAQUES[ataque]["impacto"]
	if AVISOS.has(ataque):
		return AVISOS[ataque]["repique"]
	return 0.0


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta or anim == null:
		return
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


# Ataque: «campanada_baja». Emite impacto(ataque) y llama a al_impactar una sola vez, en el ancla del clip; vuelve al
# reposo y emite ataque_terminado. Si cae derrotado a medias, no golpea.
func atacar(ataque := "campanada_baja", al_impactar := Callable()) -> void:
	if _muerta or anim == null or not ATAQUES.has(ataque) or not anim.has_animation(ataque):
		return
	_atacando = true
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(ataque)
		if al_impactar.is_valid():
			al_impactar.call()
	_reproducir(ataque, MEZCLA_ATAQUE, 0.0, [[ATAQUES[ataque]["impacto"], golpe]])
	await _esperar_clip(ataque)
	if not hecho[0] and not _muerta:          # lo cortó otro clip antes del golpe: el daño se resuelve igual, una vez
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == ataque:
		reposo()
	ataque_terminado.emit(ataque)


# Toque de alarma: la campana toma impulso y repica (señal «aviso», una vez, en el repique) y vuelve al reposo.
# Espera con await hasta acabar el toque.
func avisar(ataque := "toque_de_alarma") -> void:
	if _muerta or anim == null or _atacando or not AVISOS.has(ataque) or not anim.has_animation(ataque):
		return
	_avisando = true
	var avisado := [false]
	var dar_aviso := func():
		if not avisado[0] and not _muerta:
			avisado[0] = true
			aviso.emit(ataque)
	_reproducir(ataque, 0.15, 0.0, [[AVISOS[ataque]["repique"], dar_aviso]])
	await _esperar_clip(ataque)
	dar_aviso.call()                          # aunque algo lo corte antes, el aviso sale una vez
	_avisando = false
	if not _muerta and _clip == ataque:
		reposo()
	clip_terminado.emit(ataque)


func recibir_golpe() -> void:
	if _muerta or anim == null or _atacando or _avisando or _entrando:
		return                                # atacando, avisando o entrando no se interrumpe
	_reproducir("recibir_golpe", MEZCLA_GOLPE)
	await _esperar_clip("recibir_golpe")
	if _muerta or _clip != "recibir_golpe":
		return
	reposo()


# Las patas ceden y cae de espaldas; se queda en el suelo (el combate lo desvanece después).
func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	if anim == null:
		return
	_reproducir("derrota", 0.1)
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


# Llega a su sitio en dos saltos desde 0,85 m por detrás (empieza ahí, sin mezcla) y queda en reposo.
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


# Para el combate genérico (_anim_fisico_3d): no lanza magia; el «golpe» es la campanada.
func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func preparar_golpe() -> void:
	atacar("campanada_baja")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


# Boca de la campana en el mundo (de ahí salen los efectos de sus golpes y de su toque).
func punto_magia() -> Vector3:
	return campana()


func campana() -> Vector3:
	if skel == null:
		return global_position + CENTRO
	var i := skel.find_bone("bell")
	if i < 0:
		return global_position + CENTRO
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y * LARGO_CAMPANA          # basis.y ya lleva la escala del modelo


# ---------------------------------------------------------------- medidas de los clips (sin reproducirlos)

# Cuánto adelanta la boca de la campana en el impacto respecto al reposo, en metros de este nodo (con «escala»).
func alcance(ataque: String) -> float:
	if not ATAQUES.has(ataque):
		return 0.0
	var en_impacto := _campana_en(ataque, ATAQUES[ataque]["impacto"])
	var en_reposo := _campana_en("reposo", 0.0)
	return (en_impacto.z - en_reposo.z) * escala


# Boca de la campana en el espacio del modelo en el segundo t de un clip (cinemática directa con las pistas del clip).
func _campana_en(clip: String, t: float) -> Vector3:
	if anim == null or skel == null or not anim.has_animation(clip):
		return Vector3.ZERO
	var a := anim.get_animation(clip)
	var cadena: Array[int] = []
	var i := skel.find_bone("bell")
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
	return g.origin + g.basis.y.normalized() * LARGO_CAMPANA
