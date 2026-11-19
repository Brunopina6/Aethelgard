extends Node3D
# Hilandera del Eco, el artrópodo de la gruta que orienta las placas del lomo hacia los sonidos (T-097, bestiario 01;
# élite). Modelo del bestiario del usuario (Meshy + Blender, D-075; licencia de Meshy SIN CONFIRMAR: solo APK de prueba
# privadas) con los clips nuevos de enemigos/hilandera/fuentes_blender/crear_clips.py.
#
# Se usa como el Cencerrante (enemigos/cencerrante/cencerrante_3d.gd) y los demás enemigos 3D del combate: combate.gd lo
# crea con .new() y ruta_modelo (o instancia hilandera_3d.tscn). Mantiene los métodos que el combate llama a un enemigo
# 3D (reposo, correr, herida, morir, cansada, mirar, mirar_frente, revivir…) y añade:
#   atacar(ataque, al_impactar)  «mordida_resonante» (alza el frente, abre las patas delanteras y avanza con las
#                                mandíbulas) o «trama_de_eco» (alza las placas del abdomen y libera un pulso); con await
#   avisar(ataque)               «mordida_resonante»: el turno en que MARCA a su presa (clip aviso_mordida: la postura de
#                                aviso de la mordida, las placas orientadas y un temblor); vuelve al reposo
#   recibir_golpe(), derrota(), entrada()
# Señales:
#   aviso(ataque)       la postura de aviso: al empezar cada ataque (alza el frente o las placas) y, en avisar(), en el
#                       punto alto de la marca (0,40 s). El combate pide con ella «hilandera_aviso_mordida» o
#                       «hilandera_aviso_trama» (combate.gd _sonidos_bestia)
#   impacto(ataque)     el instante del golpe o del pulso, UNA vez por ataque: daño, sonido y reacción
#   ataque_terminado(ataque), clip_terminado(clip)
#
# El clip de la mordida ya lleva el avance de las mandíbulas y vuelve a su sitio: la posición lógica del combate va
# aparte. alcance(ataque) dice cuánto adelanta la cabeza en el impacto, para colocarla delante de su presa.

signal aviso(ataque: String)
signal impacto(ataque: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/hilandera/hilandera_completo.glb"
const ALTURA := 1.50                         # metros del suelo a lo alto de las placas (Érebo lo lee: _altura)
const CENTRO := Vector3(0.0, 0.9, 0.0)       # centro del cuerpo (efectos y números de daño)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como goblin_3d.gd
const LARGO_CABEZA := 0.36                   # del cuello a la punta de las mandíbulas (hueso «head» 0,29 m + quelíceros)
# Clips del GLB. En bucle, solo el reposo y el correteo.
const CLIPS := ["reposo", "mordida_resonante", "trama_de_eco", "recibir_golpe", "derrota", "entrada", "correr",
	"aviso_mordida"]
const BUCLES := ["reposo", "correr"]
# Anclas de tiempo (segundos desde el principio del clip; fotograma de Blender - 1, a 30 fps), las de la ficha:
#   mordida_resonante  alza el frente y abre las patas delanteras hasta 0,37 (fotograma 12), avanza y MUERDE a 0,733
#                      (fotograma 23); vuelve a su sitio hasta 1,4
#   trama_de_eco       alza las placas del abdomen hasta 0,37 (fotograma 12), las tensa hasta 0,667 y suelta el PULSO a
#                      0,833 (fotograma 26); se recoge hasta 1,433
#   aviso_mordida      la postura de aviso en 0,23-0,40 (fotogramas 8-13: el aviso, a 0,40), dos temblores y al reposo
#                      a 1,233
const ATAQUES := {
	"mordida_resonante": {"impacto": 22.0 / 30.0},
	"trama_de_eco": {"impacto": 25.0 / 30.0},
}
const AVISOS := {
	"mordida_resonante": {"clip": "aviso_mordida", "aviso": 12.0 / 30.0},
}
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.25
const MEZCLA_ATAQUE := 0.12
const MEZCLA_GOLPE := 0.06
const RITMO_CANSADO := 0.8                   # el reposo, más lento con poca vida (solo el reposo: los ataques no)

@export var ruta_modelo := RUTA_MODELO
@export var escala := 1.0                     # tamaño del modelo (1 = el del bestiario: 1,50 m de alto)
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
		push_warning("hilandera_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	for n in CLIPS:                           # (por si se reimporta con otras opciones: bucle solo donde toca)
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR if n in BUCLES else Animation.LOOP_NONE
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
	push_warning("hilandera_3d: no encuentro el modelo en %s" % ruta_modelo)


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


# Segundos desde que se llama a atacar() hasta su impacto (o desde avisar() hasta su aviso).
func tiempo_impacto(ataque: String) -> float:
	if ATAQUES.has(ataque):
		return ATAQUES[ataque]["impacto"]
	return 0.0


func tiempo_aviso(ataque: String) -> float:
	return AVISOS[ataque]["aviso"] if AVISOS.has(ataque) else 0.0


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


# Ataque: «mordida_resonante» o «trama_de_eco». Emite aviso(ataque) al empezar (su postura de aviso), e impacto(ataque)
# y al_impactar una sola vez, en el ancla del clip; vuelve al reposo y emite ataque_terminado. Si cae derrotada a
# medias, no golpea.
func atacar(ataque := "mordida_resonante", al_impactar := Callable()) -> void:
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
	aviso.emit(ataque)
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


# La marca de la mordida: la postura de aviso, las placas orientadas hacia la presa y un temblor (señal «aviso», una
# vez, en el punto alto); vuelve al reposo. Espera con await hasta acabar.
func avisar(ataque := "mordida_resonante") -> void:
	if _muerta or anim == null or _atacando or not AVISOS.has(ataque):
		return
	var clip: String = AVISOS[ataque]["clip"]
	if not anim.has_animation(clip):
		return
	_avisando = true
	var avisado := [false]
	var dar_aviso := func():
		if not avisado[0] and not _muerta:
			avisado[0] = true
			aviso.emit(ataque)
	_reproducir(clip, 0.15, 0.0, [[AVISOS[ataque]["aviso"], dar_aviso]])
	await _esperar_clip(clip)
	dar_aviso.call()                          # aunque algo lo corte antes, el aviso sale una vez
	_avisando = false
	if not _muerta and _clip == clip:
		reposo()
	clip_terminado.emit(clip)


func recibir_golpe() -> void:
	if _muerta or anim == null or _atacando or _avisando or _entrando:
		return                                # atacando, avisando o entrando no se interrumpe
	_reproducir("recibir_golpe", MEZCLA_GOLPE)
	await _esperar_clip("recibir_golpe")
	if _muerta or _clip != "recibir_golpe":
		return
	reposo()


# Las patas ceden hacia fuera y cae sobre el vientre; se queda en el suelo (el combate la desvanece después).
func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	if anim == null:
		return
	_reproducir("derrota", 0.1)
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


# Llega correteando desde 1,0 m por detrás (empieza ahí, sin mezcla) y queda en reposo.
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


# Para el combate genérico (_anim_fisico_3d): no lanza magia; el «golpe» es la mordida.
func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func preparar_golpe() -> void:
	atacar("mordida_resonante")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


# De dónde salen los efectos: el pulso de la trama, de las placas del lomo; lo demás, de las mandíbulas.
func punto_magia() -> Vector3:
	return placas()


func placas() -> Vector3:
	return _hueso_global("abdomen", 0.25)


func mandibulas() -> Vector3:
	return _hueso_global("head", LARGO_CABEZA)


func _hueso_global(nombre: String, largo: float) -> Vector3:
	if skel == null:
		return global_position + CENTRO
	var i := skel.find_bone(nombre)
	if i < 0:
		return global_position + CENTRO
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y * largo                  # basis.y ya lleva la escala del modelo


# ---------------------------------------------------------------- medidas de los clips (sin reproducirlos)

# Cuánto adelanta la punta de las mandíbulas en el impacto respecto al reposo, en metros de este nodo (con «escala»).
func alcance(ataque: String) -> float:
	if not ATAQUES.has(ataque):
		return 0.0
	var en_impacto := _cabeza_en(ataque, ATAQUES[ataque]["impacto"])
	var en_reposo := _cabeza_en("reposo", 0.0)
	return (en_impacto.z - en_reposo.z) * escala


# Punta de las mandíbulas en el espacio del modelo en el segundo t de un clip (cinemática directa con sus pistas).
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
