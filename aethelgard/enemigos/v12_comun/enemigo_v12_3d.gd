extends Node3D
# Base de los enemigos 3D de la fase C de la V12 (12/11/2026, especialista de animaciones): el Guardián de piedra
# (guardian_piedra_3d.gd), el Gólem de ámbar (golem_ambar_3d.gd) y Gorthor (gorthor_3d.gd). Modelos, texturas,
# esqueletos y clips hechos con Blender por guion (enemigos/<nombre>/fuente/, obra propia).
#
# Interfaz con combate.gd (la del goblin_3d.gd de Grimfang y del Gorthor de antes, para que entren por el mismo
# camino, _anim_ataque_3d): corre hasta el objetivo, atacar_hacha(cb) o golpe_fuerte(cb) (con rabia o al descargar el
# golpe cargado), vuelve, reposo(), herida(), morir(), cansada(), mirar(), mirar_frente(), entrada(), victoria(),
# revivir(). El daño se resuelve UNA vez, en el instante del impacto del clip (su JSON y EVENTOS de cada guion).
# No tiene avisar() (eso es Zarzalín), ni despertar() (Guardián del Bosque), ni avanzar()/retroceder() (Garon).
# Ganchos que el combate puede llamar (ver el informe docs/memory/agents/animaciones_v12_enemigos.md; si no se
# llaman, el enemigo funciona igual con sus golpes de siempre):
#   cargar()        el turno de aviso del golpe devastador / del Pisotón: se queda en la pose de carga (bucle)
#   aturdido()      su carga se interrumpe (V11): se tambalea hasta su turno siguiente (si tiene el clip)
#   fase2()         el cambio de fase al 50 % (Gorthor: «¡Furia del Abismo!»): ruge y su brillo se enciende
#   devorar(cb)     el mordisco de Gorthor (impacto al cerrar las fauces)
#   rendirse()      el último aliento: cae de rodillas y espera la decisión de Kael (bucle «rendido»)
#   retirarse()     perdonado: se da la vuelta y se arrastra (el combate lo desliza y lo desvanece)
# Señales: impacto(ataque), ataque_terminado(ataque), clip_terminado(clip) y evento(clip, nombre) para cada instante
# con nombre del clip (rugido, trago, pisotón, rodillas…: sonidos y efectos).
#
# Brillo: el material «brillo» (ojos, runas, vetas, filo) sigue en cada fotograma la escala X del hueso «luz» del clip
# (se apaga en la derrota, sube en la carga) por energia_brillo; en la fase 2, por MULT_FASE2.

signal impacto(ataque: String)
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)
signal evento(clip: String, nombre: String)

const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)    # mira a los héroes, como goblin_3d.gd y zarzalin_3d.gd
const MEZCLA_REPOSO := 0.25
const MEZCLA_ATAQUE := 0.12
const MEZCLA_GOLPE := 0.06
const RITMO_CANSADO := 0.85
const MULT_FASE2 := 2.2
const BUCLES_BASE := ["reposo", "caminar", "correr", "carga_espera", "rendido", "arrastrarse", "aturdido"]

@export var ruta_modelo := ""                 # la de MODELOS (combate.gd); vacía: la de cada guion
@export var escala := 1.0
@export var calidad := ""                     # vacío: prototipos/calidad_proto.gd; «bajo» usa la textura de 512

# lo que pone cada enemigo en _configurar()
var ruta_glb := ""
var texturas := {"alto": "", "bajo": ""}
var color_brillo := Color(1, 1, 1)
var energia_brillo := 1.6
var eventos_clip := {}                       # clip -> {nombre: segundos}; «impacto» resuelve el golpe
var ambar_superficie := false                # el Gólem: su material de resina (brillante y con luz propia)

var anim: AnimationPlayer
var skel: Skeleton3D
var caida: Node3D
var pivote: Node3D
var ajuste: Node3D
var nombres := {}
var calidad_usada := ""
var _mat_brillo: StandardMaterial3D
var _hueso_luz := -1
var _yaw0 := 0.0
var _tw_giro: Tween
var _muerta := false
var _cansada := false
var _cargando := false
var _atacando := false
var _entrando := false
var _rendido := false
var _aturdido := false
var _en_fase := false
var _fase2 := false
var _clip := ""
var _eventos: Array = []


func _configurar() -> void:
	pass


func _ready() -> void:
	process_priority = 10                     # después del AnimationPlayer (lee la posición de este fotograma)
	_configurar()
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
		push_warning("enemigo_v12_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto (%s)" % ruta_glb)
		return
	for n in BUCLES_BASE:
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in anim.get_animation_list():
		nombres[n] = n
	nombres["Idle"] = "reposo"
	nombres["Running"] = "correr"
	nombres["Walking"] = "caminar"
	_hueso_luz = skel.find_bone("luz")
	_materiales()
	mirar(FRENTE_ENEMIGO, 0.0)
	reposo()


func calidad_en_uso() -> String:
	if calidad != "":
		return calidad
	if ResourceLoader.exists("res://prototipos/calidad_proto.gd"):
		return str(load("res://prototipos/calidad_proto.gd").actual())
	return "alto"


func _cargar_modelo() -> void:
	for r in [ruta_modelo, ruta_glb]:
		if r != "" and ResourceLoader.exists(r):
			var escena = load(r)
			if escena is PackedScene:
				ajuste.add_child(escena.instantiate())
				return
	push_warning("enemigo_v12_3d: no encuentro el modelo en %s" % ruta_glb)


func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _buscar_esqueleto(c)
		if s != null:
			return s
	return null


# Materiales por el nombre de cada superficie del GLB (el GLB no lleva imágenes): el atlas WebP de la calidad en uso
# por la oclusión horneada en el color de vértice, la resina del Gólem y el brillo, que anima _process.
func _materiales() -> void:
	calidad_usada = calidad_en_uso()
	var ruta_tex: String = texturas["bajo"] if calidad_usada == "bajo" else texturas["alto"]
	var tex: Texture2D = load(ruta_tex) if ResourceLoader.exists(ruta_tex) else null
	_mat_brillo = StandardMaterial3D.new()
	_mat_brillo.albedo_color = color_brillo * 0.45
	_mat_brillo.emission_enabled = true
	_mat_brillo.emission = color_brillo
	_mat_brillo.emission_energy_multiplier = energia_brillo
	_mat_brillo.roughness = 0.4
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var orig := m3.mesh.surface_get_material(i)
			var nombre := orig.resource_name if orig != null else ""
			if nombre.ends_with("_brillo"):
				m3.set_surface_override_material(i, _mat_brillo)
				continue
			m3.set_surface_override_material(i, _material_atlas(ruta_tex, tex, nombre.ends_with("_ambar")))


# El material de la piel (atlas, o la resina del Gólem): no cambia de un enemigo a otro, así que se COMPARTE entre todos
# los que usan la misma textura (antes, uno nuevo por enemigo y superficie). Al liberar un enemigo mientras otro igual
# seguía vivo (el combate y su precarga, o dos en la misma escena), su material se liberaba y el servidor de render
# avisaba «Parameter "material" is null» (material_get_instance_shader_parameters, material_casts_shadows...: medido el
# 13/11 con pruebas/prueba_enemigos_v12 y un guion aparte que crea dos y libera uno). Compartido no se libera y gasta
# menos. El del brillo sigue siendo uno por enemigo: su energía cambia en cada fotograma (_process).
static var _atlas_compartidos := {}


static func _material_atlas(ruta_tex: String, tex: Texture2D, ambar: bool) -> StandardMaterial3D:
	var clave := "%s|%s" % [ruta_tex, ambar]
	if _atlas_compartidos.has(clave):
		return _atlas_compartidos[clave]
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ambar:
		mat.roughness = 0.28
		mat.metallic_specular = 0.75
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission = Color(1.0, 0.72, 0.38)
		mat.emission_energy_multiplier = 0.22
		mat.rim_enabled = true
		mat.rim = 0.25
		mat.rim_tint = 0.6
	_atlas_compartidos[clave] = mat
	return mat


# ---------------------------------------------------------------- reproducción con instantes

func _process(delta: float) -> void:
	if anim == null:
		return
	if _mat_brillo != null and _hueso_luz >= 0:
		var s: float = maxf(skel.get_bone_pose_scale(_hueso_luz).x, 0.0)
		_mat_brillo.emission_energy_multiplier = energia_brillo * s * (MULT_FASE2 if _fase2 else 1.0)
	if _eventos.is_empty() or String(anim.current_animation) != _clip:
		return
	var pos := anim.current_animation_position + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		var e: Array = _eventos.pop_front()
		(e[1] as Callable).call()


# Pone un clip desde «desde» con sus instantes con nombre (evento) y los que pida quien llama ([[segundo, Callable]]).
func _reproducir(clip: String, mezcla: float, desde := 0.0, extra: Array = []) -> bool:
	if anim == null or not anim.has_animation(clip):
		return false
	_eventos = extra.duplicate()
	for nombre in eventos_clip.get(clip, {}):
		var s: float = eventos_clip[clip][nombre]
		if s >= desde and nombre != "impacto" and nombre != "carga":
			_eventos.append([s, evento.emit.bind(clip, nombre)])
	_eventos.sort_custom(func(a, b): return a[0] < b[0])
	_clip = clip
	anim.speed_scale = RITMO_CANSADO if (_cansada and clip == "reposo") else 1.0
	if String(anim.current_animation) == clip:
		if not (clip in BUCLES_BASE and desde == 0.0):
			anim.seek(desde, true)
	else:
		anim.play(clip, mezcla)
		if desde > 0.0:
			anim.seek(desde, true)
	return true


func _esperar_clip(clip: String) -> void:
	while is_inside_tree() and anim != null and _clip == clip and String(anim.current_animation) == clip:
		await get_tree().process_frame


func tiene(clip: String) -> bool:
	return anim != null and anim.has_animation(clip)


func play(nombre: String, transicion := 0.2) -> void:
	_reproducir(nombres.get(nombre, nombre), transicion)


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if tiene(clip) else 0.0


func clip_actual() -> String:
	return _clip


func instante(clip: String, nombre: String) -> float:
	return float(eventos_clip.get(clip, {}).get(nombre, -1.0))


# Segundos desde que se pide el ataque hasta su impacto (el golpe fuerte, desde la carga si estaba cargando).
func tiempo_impacto(ataque: String) -> float:
	var clip := _clip_de(ataque)
	var t := instante(clip, "impacto")
	if clip == "golpe_fuerte" and _cargando:
		t -= maxf(instante(clip, "carga"), 0.0)
	return t


func _clip_de(ataque: String) -> String:
	match ataque:
		"atacar_hacha", "preparar_golpe":
			return "ataque"
		"devorar":
			return "devorar" if tiene("devorar") else "ataque"
	return ataque


func brillo_actual() -> float:
	return _mat_brillo.emission_energy_multiplier if _mat_brillo != null else 0.0


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta or anim == null:
		return
	if _rendido:                              # de rodillas: el combate no lo levanta (solo Kael decide)
		_reproducir("rendido", MEZCLA_REPOSO)
		return
	_cargando = false
	_aturdido = false
	_reproducir("reposo", MEZCLA_REPOSO)


func andar() -> void:
	if _muerta or _rendido or anim == null:
		return
	if not _reproducir("caminar", 0.15):
		correr()


func correr() -> void:
	if _muerta or anim == null:
		return
	if _rendido:
		_reproducir("arrastrarse", 0.2)
		return
	_reproducir("correr", 0.12)


func cansada(si: bool) -> void:
	_cansada = si
	if not _muerta and anim != null and _clip == "reposo":
		anim.speed_scale = RITMO_CANSADO if si else 1.0


func herida() -> void:
	recibir_golpe()


func recibir_golpe() -> void:
	if _muerta or anim == null or _atacando or _entrando or _rendido or _en_fase:
		return                                # no se corta un ataque, la entrada, la fase ni la rendición
	_reproducir("recibir_golpe", MEZCLA_GOLPE)
	await _esperar_clip("recibir_golpe")
	if _muerta or _clip != "recibir_golpe":
		return
	if _cargando:
		_reproducir("carga_espera", 0.2)
	elif _aturdido and tiene("aturdido"):
		_reproducir("aturdido", 0.2)
	else:
		reposo()


func morir() -> void:
	derrota()


func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	_cargando = false
	if anim == null:
		return
	var clip := "derrota_rendido" if (_rendido and tiene("derrota_rendido")) else "derrota"
	_reproducir(clip, 0.12)
	await _esperar_clip(clip)
	clip_terminado.emit(clip)


func victoria() -> void:
	if _muerta or _rendido or anim == null:
		return
	_cargando = false
	if not _reproducir("victoria", 0.2):
		reposo()


func revivir() -> void:
	if not _muerta and not _rendido:
		return
	_muerta = false
	_rendido = false
	reposo()


func entrada() -> void:
	if _muerta or anim == null or not tiene("entrada"):
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


# Un ataque: el clip con su impacto (al_impactar y la señal impacto, UNA vez), vuelve al reposo y avisa al acabar.
# Si otro clip lo corta antes del golpe, el daño se resuelve igual (una vez). Derrotado a medias, no golpea.
func atacar(ataque: String, al_impactar := Callable(), desde := 0.0) -> void:
	var clip := _clip_de(ataque)
	if _muerta or anim == null or not tiene(clip):
		if al_impactar.is_valid() and not _muerta:
			al_impactar.call()
		return
	_cargando = false
	_aturdido = false
	_atacando = true
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(ataque)
		if al_impactar.is_valid():
			al_impactar.call()
	var t := instante(clip, "impacto")
	_reproducir(clip, MEZCLA_ATAQUE if desde <= 0.0 else 0.1, desde, [[t, golpe]] if t >= 0.0 else [])
	await _esperar_clip(clip)
	if not hecho[0] and not _muerta:
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == clip:
		reposo()
	ataque_terminado.emit(ataque)


func atacar_hacha(al_golpear := Callable()) -> void:
	await atacar("ataque", al_golpear)


func golpe_fuerte(al_golpear := Callable()) -> void:
	var desde := maxf(instante("golpe_fuerte", "carga"), 0.0) if _cargando else 0.0
	await atacar("golpe_fuerte", al_golpear, desde)


func devorar(al_morder := Callable()) -> void:
	await atacar("devorar", al_morder)


# El aviso del golpe devastador (o del Pisotón): alza el arma o los puños y se queda en la carga.
func cargar(_ataque := "golpe_fuerte") -> void:
	if _muerta or _rendido or anim == null or _atacando:
		return
	_cargando = true
	_reproducir("carga", 0.2)
	await _esperar_clip("carga")
	if _cargando and not _muerta and _clip == "carga":
		_reproducir("carga_espera", 0.1)


func aturdido() -> void:
	if _muerta or _rendido or anim == null:
		return
	_cargando = false
	_aturdido = true
	if not _reproducir("aturdido", 0.15):
		_reproducir("recibir_golpe", MEZCLA_GOLPE)


func fase2() -> void:
	if _muerta or anim == null:
		return
	_fase2 = true
	if not tiene("fase2"):
		return
	_cargando = false
	_en_fase = true
	_reproducir("fase2", 0.15)
	await _esperar_clip("fase2")
	_en_fase = false
	if not _muerta and _clip == "fase2":
		reposo()
	clip_terminado.emit("fase2")


func en_fase2() -> bool:
	return _fase2


func rendirse() -> void:
	if _muerta or anim == null:
		return
	_rendido = true
	_cargando = false
	_atacando = false
	if not _reproducir("rendirse", 0.12):
		return
	await _esperar_clip("rendirse")
	if _rendido and not _muerta and _clip == "rendirse":
		_reproducir("rendido", 0.2)
	clip_terminado.emit("rendirse")


func esta_rendido() -> bool:
	return _rendido


func retirarse() -> void:
	if _muerta or anim == null:
		return
	_rendido = true
	mirar(Vector3(-1, 0, -0.25), 0.35)
	_reproducir("arrastrarse", 0.25)


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


func lanzar_magia() -> void:
	pass


func fin_magia() -> void:
	pass


func preparar_golpe() -> void:
	atacar("ataque")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


func punto_magia() -> Vector3:
	return hueso_mundo("cabeza", Vector3.ZERO)


# Un punto (local) de un hueso en el mundo (efectos y pruebas). Sin el hueso: el centro del cuerpo.
func hueso_mundo(hueso: String, local := Vector3.ZERO) -> Vector3:
	if skel == null or skel.find_bone(hueso) < 0:
		return global_position + Vector3(0, 1.0, 0)
	var t := skel.global_transform * skel.get_bone_global_pose(skel.find_bone(hueso))
	return t * local
