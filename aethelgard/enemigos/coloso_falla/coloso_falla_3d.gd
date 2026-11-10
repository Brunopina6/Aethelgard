extends Node3D
# El Coloso de la Falla (V9, jefe de la Garganta 3D): el modelo 3D del combate. Gigantesco guardián de piedra con
# inscripciones antiguas. Modelo, esqueleto y clips hechos con Blender por enemigos/coloso_falla/fuente/crear_coloso.py
# (obra propia).
#
# Misma interfaz que guardian_bosque_3d.gd: combate.gd lo crea con .new() y ruta_modelo (MODELOS con "tipo": "3d") o se
# instancia en una escena. Tiene los métodos que el combate llama a un enemigo 3D (reposo, correr, herida, morir,
# cansada, mirar, mirar_frente, victoria, revivir, entrada, lanzar_magia/punto_magia/fin_magia, preparar_golpe…) y:
#   atacar(ataque, al_impactar)  "ataque" (puñetazo) o "golpe_fuerte" (puño al suelo que lanza rocas); espera con
#                                await hasta volver al reposo. Acepta alias: punetazo, puno_al_suelo, terremoto…
#   ataque(al_impactar)          el puñetazo
#   cargar(ataque)               el aviso del ataque cargado: echa el brazo atrás y las runas laten (bucle «carga»)
#                                hasta que el combate llame a golpe_fuerte() o a reposo()
#   golpe_fuerte(al_impactar)    el puño al suelo, desde la carga sin repetir nada: brotan lascas y saltan rocas
#   fase2()                      las runas se encienden y las placas se abren (segunda fase); espera al final
#   dormir() / despertar()       dormido como una estatua (bucle, de pie y con musgo) / despierta hasta el reposo
#   senalar_grietas(si)          enciende (o apaga) las grietas del pecho y la espalda: los puntos vulnerables. En la
#                                fase 2 se encienden solas
#   alcance(ataque), nucleo() (= corazon()), puno() (= punta_rama()), punto_vulnerable(espalda), en_fase2()
# NO tiene avisar(): así combate.gd no lo lleva por el camino de Zarzalín. Como tiene despertar(), combate.gd lo lleva
# por _anim_guardian (ataca desde su sitio): el puño llega lejos (alcance) y las rocas brotan delante de él.
# Señales:
#   aviso(ataque)        al empezar la carga (primer latido, 0,167 s): el combate puede mostrar «Cargando»
#   impacto(ataque)      el instante del golpe, UNA vez por ataque: puñetazo a 0,6 s, puño al suelo a 0,667 s
#   placas_abiertas      en fase2, cuando las placas saltan (1,033 s): destello, tinte y texto del combate. Sale
#                        también como coraza_desplegada (el nombre del Guardián), en el mismo instante
#   ataque_terminado(ataque), clip_terminado(clip)
#
# Piezas que se esconden con la escala de su hueso (el GLB las trae así): el brillo de las grietas vulnerables
# («grietas»: lo esconde este guion en la fase 1 salvo que se señalen), las grietas de la derrota, el musgo de estatua
# (solo «dormido») y las lascas y rocas del golpe fuerte. Las placas de hombros y antebrazos están cerradas en todos los
# clips salvo fase2: en la fase 2 este guion las mantiene abiertas (la pose final de fase2) y flotando un poco.
# Luz de las runas: el material emisivo (runas, ojos y grietas) brilla según la escala del hueso «nucleo» de cada
# clip: late en la carga, se enciende en la fase 2, se apaga al ser derrotado y apenas respira dormido.

signal aviso(ataque: String)
signal impacto(ataque: String)
signal placas_abiertas
signal coraza_desplegada
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)

const RUTA_MODELO := "res://enemigos/coloso_falla/coloso_falla.glb"
const ALTURA := 4.16                         # del suelo a lo alto de los monolitos de la espalda, en reposo
const CENTRO := Vector3(0.0, 2.8, 0.45)      # el núcleo del pecho en reposo (efectos y números de daño)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como goblin_3d.gd y guardian_bosque_3d.gd
const CLIPS := ["reposo", "ataque", "carga", "golpe_fuerte", "herido", "fase2", "derrota", "dormido"]
const BUCLES := ["reposo", "carga", "dormido"]
# Anclas (segundos desde el principio del clip; fotograma de Blender - 1, a 30 fps), las de crear_coloso.py:
#   ataque        echa el brazo hasta 0,33, puñetazo hacia abajo; IMPACTO a 0,6 (fotograma 19); acaba a 1,5 en reposo
#   golpe_fuerte  desde la carga, el brazo da la vuelta por encima (0,37); IMPACTO a 0,667 (21): el puño en el suelo a
#                 1,72 m por delante; las lascas brotan hasta 0,77 y se hunden hasta 1,5; las rocas vuelan de 0,7 a
#                 1,5; acaba a 2,07 en el reposo
#   carga         bucle de 1,2 s; el primer latido a 0,167 (6)
#   fase2         se recoge, las runas arden; las placas saltan a 1,033 (32) y quedan fijas a 1,233 (38); el brillo de
#                 las grietas crece de 0,9 a 1,033; acaba a 2,57 en el reposo con las placas abiertas
#   herido        el golpe a 0,1 s; acaba a 0,77
#   derrota       se agrieta a 0,3, cede a 0,9, de rodillas a 1,3 y vencido a 1,83; acaba a 2,5 y se queda así
const ATAQUES := {
	"ataque": {"impacto": 18.0 / 30.0},
	"golpe_fuerte": {"impacto": 20.0 / 30.0},
}
const ALIAS := {"punetazo": "ataque", "puñetazo": "ataque", "golpe": "ataque", "puno": "ataque",
	"golpe_de_piedra": "ataque", "latigazo": "ataque",
	"puno_al_suelo": "golpe_fuerte", "derrumbe": "golpe_fuerte", "terremoto": "golpe_fuerte", "sismo": "golpe_fuerte",
	"lluvia_de_rocas": "golpe_fuerte", "rocas": "golpe_fuerte", "juicio": "golpe_fuerte"}
const PRIMER_LATIDO := 5.0 / 30.0
const PLACAS_SALTAN := 31.0 / 30.0           # fase2: señal placas_abiertas
const PLACAS_FIJAS := 37.0 / 30.0            # fase2: desde aquí las placas ya están en su pose abierta
const GRIETAS_CRECE := 27.0 / 30.0           # fase2: el brillo de las grietas sigue escondido hasta aquí
const DESPERTAR := 1.6                       # segundos de mezcla de la estatua al reposo
const PLACAS := ["placa_hombro.L", "placa_hombro.R", "placa_antebrazo.L", "placa_antebrazo.R"]
const OCULTO := 0.01
const LARGO_PUNO := 0.62                     # del hueso «mano» a los nudillos
# Las grietas vulnerables en el modelo en reposo (de crear_coloso.py; Godot: x, z de Blender, -y de Blender)
const GRIETA_PECHO := Vector3(0.06, 2.66, 0.493)
const GRIETA_ESPALDA := Vector3(-0.08, 2.72, -0.511)
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.3
const MEZCLA_ATAQUE := 0.15
const MEZCLA_DESDE_CARGA := 0.12
const MEZCLA_GOLPE := 0.08
const RITMO_CANSADO := 0.8
const LUZ := Color(1.0, 0.62, 0.25)

@export var ruta_modelo := RUTA_MODELO
@export var escala := 1.0
@export var dormido_al_empezar := false      # en la región: aparece dormido, de pie como una estatua
var rutas_extra: Array = []

var anim: AnimationPlayer
var skel: Skeleton3D
var caida: Node3D       # mismo esquema que guardian_bosque_3d.gd: caida > pivote (mira) > ajuste (escala) > modelo
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
var _hueso_nucleo := -1
var _hueso_grietas := -1
var _senaladas := false
var _peso_grietas := 0.0
var _peso_placas := 0.0
var _placas := []                 # [indice, posición abierta, giro abierto]
var _tiempo := 0.0
var _runas: StandardMaterial3D    # copia propia del material emisivo (cada Coloso brilla por su cuenta)
var _halos: Array[MeshInstance3D] = []
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
		push_warning("coloso_falla_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	for n in BUCLES:                          # el .import no lleva los bucles (como el Guardián): los pone el guion
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in CLIPS:
		nombres[n] = n
	nombres["Idle"] = "reposo"
	_hueso_nucleo = skel.find_bone("nucleo")
	_hueso_grietas = skel.find_bone("grietas")
	_preparar_placas()
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
	push_warning("coloso_falla_3d: no encuentro el modelo en %s" % ruta_modelo)


func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _buscar_esqueleto(c)
		if s != null:
			return s
	return null


# La pose abierta de cada placa: la del final de «fase2» (la fase 2 la mantiene).
func _preparar_placas() -> void:
	if not anim.has_animation("fase2"):
		return
	var a := anim.get_animation("fase2")
	for h in PLACAS:
		var i := skel.find_bone(h)
		if i < 0:
			continue
		var pos: Vector3 = skel.get_bone_rest(i).origin
		var rot: Quaternion = skel.get_bone_rest(i).basis.get_rotation_quaternion()
		for k in a.get_track_count():
			if not String(a.track_get_path(k)).ends_with(":" + h):
				continue
			match a.track_get_type(k):
				Animation.TYPE_POSITION_3D:
					pos = a.position_track_interpolate(k, a.length)
				Animation.TYPE_ROTATION_3D:
					rot = a.rotation_track_interpolate(k, a.length)
		_placas.append([i, pos, rot])


# El material «runas» (runas, ojos y grietas), propio de este Coloso, y los halos de las grietas vulnerables.
func _preparar_luz() -> void:
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat := m.get_active_material(i) as StandardMaterial3D
			if mat != null and mat.emission_enabled:
				_runas = mat.duplicate() as StandardMaterial3D
				m.set_surface_override_material(i, _runas)
	if _hueso_grietas < 0:
		return
	var sujeta := BoneAttachment3D.new()
	sujeta.name = "SujetaGrietas"
	skel.add_child(sujeta)
	sujeta.bone_name = "grietas"
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
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
	_halo_mat.albedo_texture = tex
	_halo_mat.albedo_color = Color(LUZ, 0.0)
	_halo_mat.render_priority = 1
	# con prueba de profundidad: el halo de la espalda no se ve a través del pecho
	var reposo_grietas := skel.get_bone_global_rest(_hueso_grietas).affine_inverse()
	for punto in [GRIETA_PECHO + Vector3(0, 0, 0.22), GRIETA_ESPALDA + Vector3(0, 0, -0.22)]:
		var q := QuadMesh.new()
		q.size = Vector2(0.85, 0.85)
		var h := MeshInstance3D.new()
		h.name = "HaloGrieta"
		h.mesh = q
		h.material_override = _halo_mat
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		h.position = reposo_grietas * punto
		sujeta.add_child(h)
		_halos.append(h)


# ---------------------------------------------------------------- cada fotograma

func _process(delta: float) -> void:
	if anim == null or skel == null:
		return
	_tiempo += delta
	var actual := String(anim.current_animation)
	var en_fase2 := _clip == "fase2" and actual == "fase2"
	var t := anim.current_animation_position
	# las grietas vulnerables: escondidas en la fase 1 (salvo señaladas); en la transformación las lleva el clip
	if en_fase2:
		if t < GRIETAS_CRECE:
			_peso_grietas = 0.0
			skel.set_bone_pose_scale(_hueso_grietas, Vector3.ONE * OCULTO)
		else:
			_peso_grietas = 1.0
	elif _hueso_grietas >= 0 and _clip != "dormido":
		var quiere := fase >= 2 or _senaladas
		_peso_grietas = move_toward(_peso_grietas, 1.0 if quiere else 0.0, delta / 0.3)
		skel.set_bone_pose_scale(_hueso_grietas, Vector3.ONE * lerpf(OCULTO, 1.0, _peso_grietas))
	# las placas: abiertas (y flotando) en la fase 2; en la transformación las lleva el clip hasta que quedan fijas
	if en_fase2 and t < PLACAS_FIJAS:
		_peso_placas = 0.0
	else:
		if en_fase2:
			_peso_placas = 1.0
		var abrir := fase >= 2 and not _muerta and _clip != "dormido"
		_peso_placas = move_toward(_peso_placas, 1.0 if abrir else 0.0, delta / 0.35)
		if _peso_placas > 0.0:
			for k in _placas.size():
				var p: Array = _placas[k]
				var flota := Vector3(0, 0.025 * sin(_tiempo * 2.2 + k * 1.3), 0)
				skel.set_bone_pose_position(p[0], skel.get_bone_pose_position(p[0]).lerp(p[1] + flota, _peso_placas))
				skel.set_bone_pose_rotation(p[0], skel.get_bone_pose_rotation(p[0]).slerp(p[2], _peso_placas))
	_actualizar_luz()
	if _eventos.is_empty() or actual != _clip:
		return
	var pos := t + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		var e: Array = _eventos.pop_front()
		(e[1] as Callable).call()


# Brillo según el latido del clip (escala del hueso «nucleo»: 0,6 vencido, 0,66 dormido … 1,65 en la transformación),
# algo más fuerte con las placas abiertas (fase 2).
func energia_runas() -> float:
	if _hueso_nucleo < 0:
		return 1.0
	var s := skel.get_bone_pose_scale(_hueso_nucleo).x
	return clampf(1.0 + (s - 1.0) * 2.6, 0.0, 2.6) * (1.0 + 0.3 * _peso_placas)


func _actualizar_luz() -> void:
	var e := energia_runas()
	if _runas != null:
		_runas.emission_energy_multiplier = e
	if _halo_mat != null:
		var latido := 0.75 + 0.25 * sin(_tiempo * 4.0)
		_halo_mat.albedo_color.a = clampf(_peso_grietas * latido * (0.25 + 0.3 * minf(e, 2.0)), 0.0, 0.85)
		for h in _halos:
			h.visible = _peso_grietas > 0.02


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


# Enciende (o apaga) el brillo de las grietas del pecho y de la espalda: los puntos vulnerables (con un halo que late).
# En la fase 2 se encienden solas.
func senalar_grietas(si := true) -> void:
	_senaladas = si


func grietas_visibles() -> bool:
	return _peso_grietas > 0.5


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta or anim == null:
		return
	_cargando = false
	_reproducir("reposo", MEZCLA_REPOSO)


# El Coloso no corre: si el combate se lo pide, se queda en su reposo (ataca desde su sitio).
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


# Aviso del ataque cargado: echa el brazo atrás y las runas laten (bucle) hasta golpe_fuerte() o reposo(). «aviso»
# sale una vez, en el primer latido (aunque un golpe lo corte antes).
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


# Paso a la segunda fase: se recoge, las runas arden, se yergue y las placas saltan (señales placas_abiertas y
# coraza_desplegada) y las grietas se encienden. No lo interrumpe un golpe. Al acabar queda en reposo con las placas
# abiertas y emite clip_terminado("fase2").
func fase2() -> void:
	if _muerta or anim == null or fase >= 2:
		return
	fase = 2
	_cargando = false
	_transformando = true
	var saltan := func():
		placas_abiertas.emit()
		coraza_desplegada.emit()
	_reproducir("fase2", 0.2, 0.0, [[PLACAS_SALTAN, saltan]])
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


# Se agrieta, cede y cae de rodillas con las runas apagadas (el combate lo desvanece después).
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


# Dormido en la región antes del combate: de pie, inmóvil como una estatua, con musgo y las runas casi apagadas.
func dormir() -> void:
	if anim == null:
		return
	_muerta = false
	_cargando = false
	_reproducir("dormido", 0.0)


# Despierta: las runas se encienden, el musgo se retira y queda en reposo (1,6 s). Emite clip_terminado("despertar").
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


# Al empezar el combate: despierta (de estatua al reposo) y emite clip_terminado("entrada").
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


# Magia: las runas laten un momento (la pose de la carga) y la luz nace en el núcleo del pecho (punto_magia).
func lanzar_magia() -> void:
	if _muerta or anim == null:
		return
	_reproducir("carga", 0.2)
	await _esperar(0.45)


func fin_magia() -> void:
	if not _cargando:
		reposo()


# Para el combate genérico (_anim_fisico_3d): el «golpe» es el puñetazo.
func preparar_golpe() -> void:
	atacar("ataque")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


func punto_magia() -> Vector3:
	return nucleo()


# El núcleo del pecho en el mundo (efectos, magia y Érebo).
func nucleo() -> Vector3:
	return _punto_hueso("nucleo", 0.0, global_position + CENTRO * escala)


func corazon() -> Vector3:
	return nucleo()


# Los nudillos del puño derecho (el del puñetazo y el del golpe al suelo) en el mundo.
func puno() -> Vector3:
	return _punto_hueso("mano.R", LARGO_PUNO, global_position + Vector3(0, 1.0, 1.5) * escala)


func punta_rama() -> Vector3:
	return puno()


# La grieta vulnerable del pecho (o de la espalda) en el mundo: donde apuntar los efectos de un golpe crítico.
func punto_vulnerable(espalda := false) -> Vector3:
	if skel == null or _hueso_grietas < 0:
		return global_position + CENTRO * escala
	var reposo_g := skel.get_bone_global_rest(_hueso_grietas)
	var ahora := skel.get_bone_global_pose(_hueso_grietas)
	ahora.basis = ahora.basis.orthonormalized()          # la escala del hueso es la del brillo: no cuenta aquí
	var local := reposo_g.affine_inverse() * (GRIETA_ESPALDA if espalda else GRIETA_PECHO)
	return skel.global_transform * (ahora * local)


func _punto_hueso(hueso: String, largo: float, si_no: Vector3) -> Vector3:
	if skel == null:
		return si_no
	var i := skel.find_bone(hueso)
	if i < 0:
		return si_no
	var t := skel.global_transform * skel.get_bone_global_pose(i)
	return t.origin + t.basis.y.normalized() * largo * escala


# ---------------------------------------------------------------- medidas de los clips (sin reproducirlos)

# Cuánto llega por delante de sus pies en el impacto, en metros de este nodo (con «escala»): los nudillos del
# puñetazo, o el punto donde el puño toca el suelo en golpe_fuerte (y brotan las lascas).
func alcance(ataque: String) -> float:
	var a := _nombre_ataque(ataque)
	if not ATAQUES.has(a):
		return 0.0
	if a == "golpe_fuerte":
		return _rocas_en(ATAQUES[a]["impacto"]).z * escala
	return _punta_en(a, ATAQUES[a]["impacto"]).z * escala


# Dónde brotan las lascas del golpe fuerte (el hueso «rocas», sin padre: su pista es la posición en el modelo).
func _rocas_en(t: float) -> Vector3:
	if anim == null or skel == null or not anim.has_animation("golpe_fuerte"):
		return Vector3.ZERO
	var a := anim.get_animation("golpe_fuerte")
	for k in a.get_track_count():
		if a.track_get_type(k) == Animation.TYPE_POSITION_3D and String(a.track_get_path(k)).ends_with(":rocas"):
			return a.position_track_interpolate(k, t)
	return Vector3.ZERO


# Nudillos del puño derecho (LARGO_PUNO por el hueso mano.R) en el espacio del modelo en el segundo t de un clip.
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
	return g.origin + g.basis.y.normalized() * LARGO_PUNO
