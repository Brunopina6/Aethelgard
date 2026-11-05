extends Node3D
# Maga 3D (modelo de Meshy con esqueleto Mixamo) — basado en el script del autor.
#
# El FBX solo trae 3 animaciones: "Running", "Walking" y una pose quieta con los brazos
# abiertos y un nombre raro (_01a19663_...). No hay "Idle" ni "Casting", así que la pose
# quieta hace de reposo y los gestos (brazos relajados, conjuro, golpe, herida, cansancio,
# victoria y caída) se hacen por código con gestos_3d.gd.
# Si más adelante añades animaciones llamadas "Idle" o "Casting", se usarán solas.
#
# Puede usarse de dos formas:
#  - Pegado en el nodo raíz de una escena que ya tiene el modelo dentro (como tu script original).
#  - Creado por código (lo hace el combate): carga el modelo de "ruta_modelo".

signal gesto_terminado

@export var ruta_modelo := "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"
const RUTAS_EXTRA := ["res://maga.fbx", "res://maga.glb"]
const ALTURA := 1.7                                  # altura final en metros
const FRENTE := Vector3(-0.8, 0.0, 0.6)              # 3/4 mirando a los enemigos (a la izquierda)

var anim: AnimationPlayer
var skel: Skeleton3D
var gestos             # gestos_3d.gd (SkeletonModifier3D)
var caida: Node3D       # se inclina al caer derrotada
var pivote: Node3D      # gira para mirar a un lado u otro
var ajuste: Node3D      # escala y centra el modelo
var nombres := {}       # nombre lógico -> nombre real de la animación
var rutas_extra: Array = RUTAS_EXTRA
var _yaw0 := 0.0
var _tw_giro: Tween
var _tw_caida: Tween
var _cansada := false
var _muerta := false
# Arma en la mano derecha (cetro), según el inventario. Kael pone usa_vara = false porque lleva su sable.
const DIR_VARA := Vector3(0.15, 1.0, 0.0)     # en el reposo la vara apunta arriba y un poco adelante
var usa_vara := true
var heroe := "Lya"
var vara: Node3D
var _vara_punta := 0.5


func _ready() -> void:
	caida = Node3D.new()
	pivote = Node3D.new()
	ajuste = Node3D.new()
	var previos := get_children()
	add_child(caida)
	caida.add_child(pivote)
	pivote.add_child(ajuste)
	if previos.is_empty():
		_cargar_modelo()
	else:
		for c in previos:
			c.reparent(ajuste, false)

	anim = find_child("AnimationPlayer", true, false)
	skel = _buscar_esqueleto(self)
	if anim == null or skel == null:
		push_warning("maga_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	print(anim.get_animation_list())  # muestra los nombres reales
	_mapear_animaciones()

	gestos = load("res://gestos_3d.gd").new()
	skel.add_child(gestos)
	gestos.preparar()
	_normalizar()
	_yaw0 = _angulo(_adelante_mundo())
	mirar(FRENTE, 0.0)
	reposo()
	if usa_vara:
		_crear_vara()


# ---------------------------------------------------------------- cetro

func _crear_vara() -> void:
	if not ResourceLoader.exists("res://inventario.gd"):
		return
	var arma: Dictionary = load("res://inventario.gd").arma_de(heroe)
	if arma.is_empty() or not ResourceLoader.exists(arma["modelo"]):
		return
	if gestos.idx.get("mano_d", -1) < 0 or gestos.idx.get("dedo_d", -1) < 0:
		return
	vara = Node3D.new()
	vara.visible = false
	skel.add_child(vara)
	var largo: float = gestos.escala * arma["largo"]
	var mi := MeshInstance3D.new()
	mi.mesh = load(arma["modelo"])
	# metal al 40 %: sin cielo que reflejar, el metal puro se ve negro
	mi.material_override = load("res://material_arma.gd").de_arma(arma, 0.4)
	mi.scale = Vector3.ONE * largo
	vara.add_child(mi)
	_vara_punta = arma["punta"] * largo
	gestos.al_terminar = _actualizar_vara
	vara.visible = true


# La vara sigue a la palma de la mano derecha cada fotograma; al conjurar apunta al cielo.
func _actualizar_vara(sk: Skeleton3D) -> void:
	var mano := sk.get_bone_global_pose(gestos.idx["mano_d"])
	var palma := (mano.origin + sk.get_bone_global_pose(gestos.idx["dedo_d"]).origin) * 0.5
	var hoja: Vector3 = gestos.dir(DIR_VARA)                  # siempre derecha, gire como gire la mano
	var filo: Vector3 = gestos.adelante
	var w: float = gestos.peso.get("conjuro", 0.0)
	if w > 0.001:
		hoja = hoja.slerp(gestos.dir(Vector3(0.25, 1.0, 0.0)), w)
	filo = (filo - hoja * filo.dot(hoja)).normalized()
	vara.global_transform = sk.global_transform * Transform3D(Basis(filo, hoja, filo.cross(hoja)), palma)


func _cargar_modelo() -> void:
	var rutas: Array = [ruta_modelo] + rutas_extra
	for r in rutas:
		if ResourceLoader.exists(r):
			var escena = load(r)
			if escena is PackedScene:
				ajuste.add_child(escena.instantiate())
				return
	push_warning("maga_3d: no encuentro el modelo en %s" % str(rutas))


func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _buscar_esqueleto(c)
		if s != null:
			return s
	return null


func _mapear_animaciones() -> void:
	var lista := anim.get_animation_list()
	for n in lista:
		var b := String(n).to_lower()
		if "run" in b or "correr" in b:
			nombres["Running"] = n
		elif "walk" in b or "andar" in b:
			nombres["Walking"] = n
		elif "idle" in b or "reposo" in b:
			nombres["Idle"] = n
		elif "cast" in b or "magia" in b:
			nombres["Casting"] = n
	if not nombres.has("Idle"):   # la pose quieta del nombre raro hace de reposo
		for n in lista:
			if String(n) != "RESET" and not (n in nombres.values()):
				nombres["Idle"] = n
				break
	for k in ["Idle", "Walking", "Running"]:
		if nombres.has(k):
			anim.get_animation(nombres[k]).loop_mode = Animation.LOOP_LINEAR


# Deja a la maga con 1,7 m de alto, los pies en el suelo (y = 0) y centrada.
func _normalizar() -> void:
	var h := _medidas()
	if h.y <= 0.001:
		return
	ajuste.scale *= ALTURA / h.y
	var m := _medidas()
	ajuste.position -= Vector3(m.x, m.z, _cadera_local().z)


# Devuelve (x de la cadera, altura total, y del suelo) medidos desde este nodo.
# Los huesos de las puntas de los pies quedan unos 4 cm por encima de la suela.
func _medidas() -> Vector3:
	var bajo := INF
	var alto := -INF
	for i in skel.get_bone_count():
		var p := to_local(skel.global_transform * skel.get_bone_global_rest(i).origin)
		var n := skel.get_bone_name(i)
		if "Toe" in n:
			bajo = minf(bajo, p.y)
		if "HeadTop" in n or n.ends_with("Head"):
			alto = maxf(alto, p.y)
	if bajo == INF or alto == -INF:
		return Vector3.ZERO
	var largo := alto - bajo
	return Vector3(_cadera_local().x, largo * 1.03, bajo - largo * 0.025)


func _cadera_local() -> Vector3:
	var i: int = gestos.idx.get("cadera", -1)
	if i < 0:
		return Vector3.ZERO
	return to_local(skel.global_transform * skel.get_bone_global_rest(i).origin)


func _adelante_mundo() -> Vector3:
	var v: Vector3 = skel.global_transform.basis * gestos.adelante
	v.y = 0.0
	return v.normalized()


func _angulo(v: Vector3) -> float:
	return atan2(v.x, v.z)


# ---------------------------------------------------------------- animaciones del modelo

func play(nombre: String, transicion := 0.2) -> void:
	if anim == null:
		return
	var real: String = nombres.get(nombre, nombre)
	if anim.has_animation(real) and anim.current_animation != real:
		anim.play(real, transicion)  # transición suave


func andar() -> void:
	_base_movimiento()
	play("Walking")


func correr() -> void:
	_base_movimiento()
	play("Running")


func _base_movimiento() -> void:
	gestos.quitar_todos(0.15)
	gestos.respirar = 0.0
	anim.speed_scale = 1.0


# ---------------------------------------------------------------- gestos

func reposo() -> void:
	play("Idle", 0.25)
	gestos.respirar = 1.0
	gestos.quitar_todos(0.3, ["cansada"])
	gestos.poner("reposo", 1.0, 0.3)
	cansada(_cansada)


# Con poca vida: espalda encorvada y movimientos más lentos.
func cansada(si: bool) -> void:
	_cansada = si
	if _muerta:
		return
	gestos.poner("cansada", 1.0 if si else 0.0, 0.5)
	anim.speed_scale = 0.75 if si else 1.0


# Alza las manos para lanzar un hechizo. Espera con "await" a que termine de levantarlas.
func lanzar_magia() -> void:
	if nombres.has("Casting"):
		play("Casting", 0.2)
	else:
		reposo()
		gestos.poner("conjuro", 1.0, 0.45)
	await get_tree().create_timer(0.5).timeout


func fin_magia() -> void:
	gestos.quitar("conjuro", 0.4)
	if nombres.has("Casting"):
		reposo()


func preparar_golpe() -> void:
	reposo()
	gestos.poner("golpe_prep", 1.0, 0.25)


func golpear() -> void:
	gestos.quitar("golpe_prep", 0.1)
	gestos.poner("golpe", 1.0, 0.1)


func fin_golpe() -> void:
	gestos.quitar("golpe", 0.35)


# Recibe un golpe: se echa atrás un momento y vuelve.
func herida() -> void:
	if _muerta:
		return
	gestos.poner("herida", 1.0, 0.07)
	await get_tree().create_timer(0.35).timeout
	gestos.quitar("herida", 0.4)


func victoria() -> void:
	if _muerta:
		return
	cansada(false)
	reposo()
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)          # se gira hacia la cámara
	gestos.poner("victoria", 1.0, 0.45)
	var t := create_tween()
	t.tween_property(ajuste, "position:y", ajuste.position.y + 0.15, 0.18).set_ease(Tween.EASE_OUT)
	t.tween_property(ajuste, "position:y", ajuste.position.y, 0.22).set_ease(Tween.EASE_IN)


# Cae al suelo de lado (hacia la derecha de la pantalla).
func morir() -> void:
	if _muerta:
		return
	_muerta = true
	play("Idle", 0.2)
	anim.speed_scale = 0.0
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3)
	gestos.poner("caida", 1.0, 0.5)
	if _tw_caida != null and _tw_caida.is_valid():
		_tw_caida.kill()
	_tw_caida = create_tween().set_parallel(true)
	_tw_caida.tween_property(caida, "rotation_degrees:z", -84.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw_caida.tween_property(caida, "position", Vector3(-0.88, 0.1, 0.0), 0.55)


func revivir() -> void:
	if not _muerta:
		return
	_muerta = false
	anim.speed_scale = 1.0
	gestos.quitar("caida", 0.4)
	if _tw_caida != null and _tw_caida.is_valid():
		_tw_caida.kill()
	_tw_caida = create_tween().set_parallel(true)
	_tw_caida.tween_property(caida, "rotation_degrees:z", 0.0, 0.5)
	_tw_caida.tween_property(caida, "position", Vector3.ZERO, 0.5)
	reposo()


# Gira a la maga para que mire en la dirección "dir" (en el mundo; la cámara está en +Z).
func mirar(dir: Vector3, dur := 0.2) -> void:
	if pivote == null:
		return
	var meta := _angulo(dir) - _yaw0
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
	mirar(FRENTE, dur)


# Punto donde nace la luz del hechizo: la cabeza del cetro o, sin cetro, entre las dos manos.
func punto_magia() -> Vector3:
	if vara != null and vara.visible:
		return vara.global_transform * Vector3(0, _vara_punta, 0)
	var i: int = gestos.idx.get("mano_i", -1)
	var j: int = gestos.idx.get("mano_d", -1)
	if i < 0 or j < 0:
		return to_global(Vector3(0, ALTURA * 1.1, 0))
	var a := skel.global_transform * skel.get_bone_global_pose(i).origin
	var b := skel.global_transform * skel.get_bone_global_pose(j).origin
	return (a + b) * 0.5 + Vector3(0, 0.12, 0)


# ---------------------------------------------------------------- tu ejemplo original

func atacar() -> void:
	await lanzar_magia()
	await get_tree().create_timer(0.6).timeout
	fin_magia()
	gesto_terminado.emit()
