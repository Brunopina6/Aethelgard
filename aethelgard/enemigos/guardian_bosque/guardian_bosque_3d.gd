extends Node3D
# El Guardián del Bosque Olvidado (fase 3, jefe de «El bosque que no recuerda»): el modelo 3D del combate.
# Modelo, esqueleto y clips hechos con Blender por enemigos/guardian_bosque/fuente/crear_guardian.py (obra propia).
#
# Se usa como los enemigos 3D del combate (zarzalin_3d.gd): combate.gd lo crea con .new() y ruta_modelo (MODELOS con
# "tipo": "3d") o se instancia en una escena. Tiene los métodos que el combate llama a un enemigo 3D (reposo, correr,
# herida, morir, cansada, mirar, mirar_frente, victoria, revivir, entrada, lanzar_magia/punto_magia/fin_magia,
# preparar_golpe…) y además:
#   atacar(ataque, al_impactar)  "ataque" (latigazo de rama) o "golpe_fuerte" (descarga con raíces); espera con await
#                                hasta volver al reposo. Acepta alias: latigazo, raices, juicio…
#   ataque(al_impactar)          el latigazo de rama
#   cargar(ataque)               el aviso del ataque cargado: se encorva y el corazón late (bucle «carga») hasta que el
#                                combate llame a golpe_fuerte() o a reposo()
#   golpe_fuerte(al_impactar)    la descarga del ataque cargado (raíces al suelo), desde la carga sin repetir nada
#   fase2()                      se yergue y despliega la coraza de raíces (paso a la segunda fase); espera al final
#   dormir() / despertar()       dormido en la región (bucle, arrodillado bajo el musgo) / se levanta hasta el reposo
#   alcance(ataque), corazon(), punta_rama(), en_fase2()
# NO tiene avisar(): así combate.gd no lo lleva por el camino de Zarzalín (galopar hasta el héroe y volver de
# espaldas). El Guardián ataca desde su sitio: la rama llega lejos (alcance) y las raíces brotan delante de él.
# Señales:
#   aviso(ataque)        al empezar la carga (primer latido, 0,13 s): el combate puede mostrar «Cargando»
#   impacto(ataque)      el instante del golpe, UNA vez por ataque: latigazo a 0,6 s, raíces a 0,667 s
#   coraza_desplegada    en fase2, cuando la coraza ya se ve (0,93 s): destello, tinte y texto del combate
#   ataque_terminado(ataque), clip_terminado(clip)
#
# Piezas que se esconden con la escala de su hueso (el GLB las trae así; este guion solo esconde la coraza en la
# fase 1): coraza (fase 2), musgo del sueño (solo «dormido») y raíces del suelo (solo «golpe_fuerte»).
# Luz del corazón: el material emisivo (corazón, ojos y venas) brilla según la escala del hueso «corazon» de cada
# clip: late en la carga, se enciende en la fase 2 y se apaga al ser derrotado. Un halo suave acompaña al corazón.

signal aviso(ataque: String)
signal impacto(ataque: String)
signal coraza_desplegada
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/guardian_bosque/guardian_bosque.glb"
const ALTURA := 3.75                         # del suelo a la copa (Érebo: el pecho a ALTURA·0,55 = el corazón, 2,06 m)
const CENTRO := Vector3(0.0, 2.06, 0.6)      # el corazón en reposo (efectos y números de daño)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como goblin_3d.gd y zarzalin_3d.gd
const CLIPS := ["reposo", "ataque", "carga", "golpe_fuerte", "herido", "fase2", "derrota", "dormido"]
const BUCLES := ["reposo", "carga", "dormido"]
# Anclas (segundos desde el principio del clip; fotograma de Blender - 1, a 30 fps), las de crear_guardian.py:
#   ataque        alza la rama hasta 0,33, latigazo; IMPACTO a 0,6 (fotograma 19); acaba a 1,37 en el reposo
#   golpe_fuerte  desde la pose de carga, se yergue hasta 0,37, descarga; IMPACTO a 0,667 (21): las raíces brotan
#                 delante (1,7 m) hasta 0,77 y se retiran hasta 1,4; acaba a 1,97 en el reposo
#   carga         bucle de 1,2 s; el primer latido a 0,133 (5)
#   fase2         se recoge, late, se yergue a 1,03 (32) y la coraza se ve entera a 1,23 (38); acaba a 2,57
#   herido        el golpe a 0,1 s; acaba a 0,77
#   derrota       cae de rodillas a 1,1 y queda vencido a 1,63; acaba a 2,37 y se queda así
const ATAQUES := {
	"ataque": {"impacto": 18.0 / 30.0},
	"golpe_fuerte": {"impacto": 20.0 / 30.0},
}
const ALIAS := {"latigazo": "ataque", "latigazo_de_raiz": "ataque", "golpe": "ataque", "colmillo_lateral": "ataque",
	"raices": "golpe_fuerte", "raices_que_aprisionan": "golpe_fuerte", "juicio": "golpe_fuerte",
	"juicio_del_bosque": "golpe_fuerte", "embestida_espinosa": "golpe_fuerte"}
const PRIMER_LATIDO := 4.0 / 30.0
const CORAZA_VISIBLE := 28.0 / 30.0
const CORAZA_CRECE := 21.0 / 30.0            # fase2: la coraza sigue escondida en el clip hasta el fotograma 22
const DESPERTAR := 1.4                       # segundos de mezcla del sueño al reposo
const CORAZA := ["coraza", "coraza.L", "coraza.R"]
const OCULTO := 0.01
const DISTANCIA_RAICES := 1.7                # las raíces de golpe_fuerte brotan a 1,7 m delante de sus pies
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.3
const MEZCLA_ATAQUE := 0.15
const MEZCLA_DESDE_CARGA := 0.12
const MEZCLA_GOLPE := 0.08
const RITMO_CANSADO := 0.8
const LUZ := Color(0.8, 1.0, 0.45)

@export var ruta_modelo := RUTA_MODELO
@export var escala := 1.0
@export var dormido_al_empezar := false      # en la región: aparece dormido bajo el musgo
var rutas_extra: Array = []

var anim: AnimationPlayer
var skel: Skeleton3D
var caida: Node3D       # mismo esquema que zarzalin_3d.gd: caida > pivote (mira) > ajuste (escala) > modelo
var pivote: Node3D
var ajuste: Node3D
var nombres := {}
var fase := 1
var _yaw0 := 0.0
var _tw_giro: Tween
var _muerta := false
var _cansada := false
var _cargando := false
var _atacando := false
var _transformando := false
var _entrando := false
var _clip := ""
var _eventos: Array = []
var _huesos_coraza: Array[int] = []
var _hueso_corazon := -1
var _luz: StandardMaterial3D      # copia propia del material emisivo (cada Guardián brilla por su cuenta)
var _halo: MeshInstance3D
var _halo_mat: StandardMaterial3D


func _ready() -> void:
	process_priority = 10                    # después del AnimationPlayer: lee y corrige la pose de este fotograma
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
		push_warning("guardian_bosque_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	for n in BUCLES:                          # el .import ya los pone en bucle; por si se reimporta sin esa opción
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in CLIPS:
		nombres[n] = n
	nombres["Idle"] = "reposo"
	for h in CORAZA:
		var i := skel.find_bone(h)
		if i >= 0:
			_huesos_coraza.append(i)
	_hueso_corazon = skel.find_bone("corazon")
	_preparar_luz()
	mirar(FRENTE_ENEMIGO, 0.0)
	if dormido_al_empezar:
		dormir()
	else:
		reposo()


func _cargar_modelo() -> void:
	for r in [ruta_modelo] + rutas_extra:
		if ResourceLoader.exists(r):
			var escena = load(r)
			if escena is PackedScene:
				ajuste.add_child(escena.instantiate())
				return
	push_warning("guardian_bosque_3d: no encuentro el modelo en %s" % ruta_modelo)


func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _buscar_esqueleto(c)
		if s != null:
			return s
	return null


# El material «luz» (corazón, ojos y venas), propio de este Guardián, y el halo del corazón.
func _preparar_luz() -> void:
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat := m.get_active_material(i) as StandardMaterial3D
			if mat != null and mat.emission_enabled:
				_luz = mat.duplicate() as StandardMaterial3D
				m.set_surface_override_material(i, _luz)
	if _hueso_corazon < 0:
		return
	var sujeta := BoneAttachment3D.new()
	sujeta.name = "SujetaCorazon"
	skel.add_child(sujeta)
	sujeta.bone_name = "corazon"
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	_halo_mat = StandardMaterial3D.new()
	_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_halo_mat.no_depth_test = true
	_halo_mat.albedo_texture = tex
	_halo_mat.albedo_color = Color(LUZ, 0.6)
	_halo_mat.render_priority = 1
	var q := QuadMesh.new()
	q.size = Vector2(0.95, 0.95)
	_halo = MeshInstance3D.new()
	_halo.name = "HaloCorazon"
	_halo.mesh = q
	_halo.material_override = _halo_mat
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sujeta.add_child(_halo)


# ---------------------------------------------------------------- cada fotograma

func _process(delta: float) -> void:
	if anim == null or skel == null:
		return
	# fase 1: la coraza, escondida dentro del pecho. En la transformación, hasta que empieza a crecer (la mezcla desde
	# el reposo la sacaría a medias); después crece con el clip.
	var oculta := fase < 2
	if _clip == "fase2":
		oculta = String(anim.current_animation) == "fase2" and anim.current_animation_position < CORAZA_CRECE
	if oculta:
		for i in _huesos_coraza:
			skel.set_bone_pose_scale(i, Vector3.ONE * OCULTO)
	_actualizar_luz()
	if _eventos.is_empty() or String(anim.current_animation) != _clip:
		return
	var pos := anim.current_animation_position + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		var e: Array = _eventos.pop_front()
		(e[1] as Callable).call()


# Brillo según el latido del clip (escala del hueso «corazon»: 0,6 vencido … 1,5 en la transformación).
func _actualizar_luz() -> void:
	if _hueso_corazon < 0:
		return
	var s := skel.get_bone_pose_scale(_hueso_corazon).x
	var energia := clampf(1.0 + (s - 1.0) * 2.6, 0.2, 2.3)
	if _luz != null:
		_luz.emission_energy_multiplier = energia
	if _halo_mat != null:
		_halo_mat.albedo_color.a = clampf(0.25 + (energia - 0.2) * 0.3, 0.05, 0.85)


# ---------------------------------------------------------------- clips y anclas

func _reproducir(clip: String, mezcla: float, desde := 0.0, eventos: Array = []) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_eventos = eventos.duplicate()
	_eventos.sort_custom(func(a, b): return a[0] < b[0])
	_clip = clip
	anim.speed_scale = RITMO_CANSADO if (_cansada and clip == "reposo") else 1.0
	if String(anim.current_animation) == clip:
		if not (clip in BUCLES and desde == 0.0):
			anim.seek(desde, true)
	else:
		anim.play(clip, mezcla)
		if desde > 0.0:
			anim.seek(desde, true)


func _esperar_clip(clip: String) -> void:
	while is_inside_tree() and anim != null and _clip == clip and String(anim.current_animation) == clip:
		await get_tree().process_frame


func _esperar(segundos: float) -> void:
	if is_inside_tree():
		await get_tree().create_timer(segundos).timeout


func play(nombre: String, transicion := 0.2) -> void:
	_reproducir(nombres.get(nombre, nombre), transicion)


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if anim != null and anim.has_animation(clip) else 0.0


func _nombre_ataque(ataque: String) -> String:
	return ALIAS.get(ataque, ataque) if not ATAQUES.has(ataque) else ataque


# Segundos desde que se llama a atacar() hasta su impacto.
func tiempo_impacto(ataque: String) -> float:
	var a := _nombre_ataque(ataque)
	return ATAQUES[a]["impacto"] if ATAQUES.has(a) else 0.0


func en_fase2() -> bool:
	return fase >= 2


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta or anim == null:
		return
	_cargando = false
	_reproducir("reposo", MEZCLA_REPOSO)


# El Guardián no corre: si el combate se lo pide, se queda en su reposo (ataca desde su sitio).
func andar() -> void:
	reposo()


func correr() -> void:
	reposo()


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


# Ataque: emite impacto(ataque) y llama a al_impactar una sola vez, en el ancla del clip; vuelve al reposo y emite
# ataque_terminado. Si cae derrotado a medias, no golpea. golpe_fuerte, tras cargar(), sigue desde la carga.
func atacar(ataque := "ataque", al_impactar := Callable()) -> void:
	var clip := _nombre_ataque(ataque)
	if _muerta or anim == null or not ATAQUES.has(clip) or not anim.has_animation(clip):
		return
	var desde_carga := _cargando
	_cargando = false
	_atacando = true
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(clip)
		if al_impactar.is_valid():
			al_impactar.call()
	_reproducir(clip, MEZCLA_DESDE_CARGA if desde_carga else MEZCLA_ATAQUE, 0.0, [[ATAQUES[clip]["impacto"], golpe]])
	await _esperar_clip(clip)
	if not hecho[0] and not _muerta:          # lo cortó otro clip antes del golpe: el daño se resuelve igual, una vez
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == clip:
		reposo()
	ataque_terminado.emit(clip)


func ataque(al_impactar := Callable()) -> void:
	await atacar("ataque", al_impactar)


func golpe_fuerte(al_impactar := Callable()) -> void:
	await atacar("golpe_fuerte", al_impactar)


# Aviso del ataque cargado: se encorva y el corazón late (bucle) hasta golpe_fuerte() o reposo(). «aviso» sale una
# vez, en el primer latido (aunque un golpe lo corte antes).
func cargar(ataque := "golpe_fuerte") -> void:
	if _muerta or anim == null or _atacando or _transformando:
		return
	_cargando = true
	var avisado := [false]
	var dar_aviso := func():
		if not avisado[0]:
			avisado[0] = true
			aviso.emit(ataque)
	_reproducir("carga", 0.25, 0.0, [[PRIMER_LATIDO, dar_aviso]])
	await _esperar(PRIMER_LATIDO + 0.05)
	dar_aviso.call()


# Paso a la segunda fase: se recoge, el corazón late, se yergue y despliega la coraza (señal coraza_desplegada).
# No lo interrumpe un golpe. Al acabar queda en reposo con la coraza y emite clip_terminado("fase2").
func fase2() -> void:
	if _muerta or anim == null or fase >= 2:
		return
	fase = 2
	_cargando = false
	_transformando = true
	_reproducir("fase2", 0.2, 0.0, [[CORAZA_VISIBLE, func(): coraza_desplegada.emit()]])
	await _esperar_clip("fase2")
	_transformando = false
	if _muerta:
		return
	if _clip == "fase2":
		reposo()
	clip_terminado.emit("fase2")


# Pone la fase sin la animación (por ejemplo, al reintentar el combate desde la segunda fase).
func poner_fase(n: int) -> void:
	fase = n


func recibir_golpe() -> void:
	if _muerta or anim == null or _atacando or _transformando or _entrando:
		return
	_reproducir("herido", MEZCLA_GOLPE)
	await _esperar_clip("herido")
	if _muerta or _clip != "herido":
		return
	if _cargando:
		_reproducir("carga", 0.2)
	else:
		reposo()


# Se desmorona y queda de rodillas, con la luz del corazón casi apagada (el combate lo desvanece después).
func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	_cargando = false
	if anim == null:
		return
	_reproducir("derrota", 0.12)
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


# Dormido en la región antes del combate: arrodillado, inmóvil y cubierto de musgo (bucle).
func dormir() -> void:
	if anim == null:
		return
	_muerta = false
	_cargando = false
	_reproducir("dormido", 0.0)


# Se levanta del sueño: el musgo se retira y queda en reposo (1,4 s). Emite clip_terminado("despertar").
func despertar() -> void:
	if anim == null or _muerta:
		return
	_entrando = true
	if _clip != "dormido":
		_reproducir("dormido", 0.0)
		await get_tree().process_frame
	_reproducir("reposo", DESPERTAR)
	await _esperar(DESPERTAR)
	_entrando = false
	clip_terminado.emit("despertar")


# Al empezar el combate: despierta (de dormido al reposo) y emite clip_terminado("entrada").
func entrada() -> void:
	if _muerta or anim == null:
		return
	await despertar()
	clip_terminado.emit("entrada")


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


# Magia (las esporas): el corazón late un momento y la luz nace en él (punto_magia).
func lanzar_magia() -> void:
	if _muerta or anim == null:
		return
	_reproducir("carga", 0.2)
	await _esperar(0.45)


func fin_magia() -> void:
	if not _cargando:
		reposo()


# Para el combate genérico (_anim_fisico_3d): el «golpe» es el latigazo.
func preparar_golpe() -> void:
	atacar("ataque")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


func punto_magia() -> Vector3:
	return corazon()


# El corazón en el mundo (efectos de la luz, las esporas y Érebo).
func corazon() -> Vector3:
	return _punto_hueso("corazon", 0.0, global_position + CENTRO * escala)


# La punta de la rama del latigazo (mano derecha) en el mundo.
func punta_rama() -> Vector3:
	return _punto_hueso("mano.R", 0.55, global_position + Vector3(0, 1.0, 0.6) * escala)


func _punto_hueso(hueso: String, largo: float, si_no: Vector3) -> Vector3:
	if skel == null:
		return si_no
	var i := skel.find_bone(hueso)
	if i < 0:
		return si_no
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y.normalized() * largo * escala


# ---------------------------------------------------------------- medidas de los clips (sin reproducirlos)

# Cuánto llega por delante de sus pies en el impacto, en metros de este nodo (con «escala»): la punta de la rama del
# latigazo, o el centro de las raíces que brotan en golpe_fuerte.
func alcance(ataque: String) -> float:
	var a := _nombre_ataque(ataque)
	if a == "golpe_fuerte":
		return DISTANCIA_RAICES * escala
	if a != "ataque":
		return 0.0
	return _punta_en("ataque", ATAQUES["ataque"]["impacto"]).z * escala


# Punta de la rama (cola del hueso mano.R) en el espacio del modelo en el segundo t de un clip.
func _punta_en(clip: String, t: float) -> Vector3:
	if anim == null or skel == null or not anim.has_animation(clip):
		return Vector3.ZERO
	var a := anim.get_animation(clip)
	var cadena: Array[int] = []
	var i := skel.find_bone("mano.R")
	while i >= 0:
		cadena.push_front(i)
		i = skel.get_bone_parent(i)
	var g := Transform3D.IDENTITY
	for b in cadena:
		var rest := skel.get_bone_rest(b)
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var esc := Vector3.ONE
		var sufijo := ":" + skel.get_bone_name(b)
		for k in a.get_track_count():
			if not String(a.track_get_path(k)).ends_with(sufijo):
				continue
			match a.track_get_type(k):
				Animation.TYPE_POSITION_3D:
					pos = a.position_track_interpolate(k, t)
				Animation.TYPE_ROTATION_3D:
					rot = a.rotation_track_interpolate(k, t)
				Animation.TYPE_SCALE_3D:
					esc = a.scale_track_interpolate(k, t)
		g = g * Transform3D(Basis(rot) * Basis.from_scale(esc), pos)
	return g.origin + g.basis.y.normalized() * 0.55
