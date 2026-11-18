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
# Esperas de exploración (esperas_3d.gd): solo en la exploración, con activar_esperas().
var clave_esperas := ""                     # qué héroe es («Lya» si es este script tal cual; kael_3d.gd y garon_3d.gd
                                            # ponen el suyo): sus esperas y su porte al andar. «» = ninguno (enemigos)
var esperas: Node = null
# Durante una espera el cetro va con la mano (lo inclina, lo cruza delante…); fuera de ellas, siempre derecho.
var vara_mano := 0.0
var _vara_calibrar := false
var _vara_hoja_local := Vector3.UP
var _vara_filo_local := Vector3.FORWARD
var _tw_vara: Tween


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
	if clave_esperas == "" and get_script() != null and get_script().resource_path == "res://maga_3d.gd":
		clave_esperas = "Lya"                    # este script tal cual es Lya (los enemigos que heredan de él, no)
	for k in ESTILOS.get(clave_esperas, {}):
		gestos.registrar("porte_" + k, ESTILOS[clave_esperas][k])
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
	if _vara_calibrar:                                   # al empezar una espera: cómo va el cetro respecto a la mano
		var b0 := mano.basis.orthonormalized().inverse()
		_vara_hoja_local = b0 * hoja
		_vara_filo_local = b0 * filo
		_vara_calibrar = false
	if vara_mano > 0.001:
		var bm := mano.basis.orthonormalized()
		hoja = hoja.slerp((bm * _vara_hoja_local).normalized(), vara_mano)
		filo = filo.slerp((bm * _vara_filo_local).normalized(), vara_mano)
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
	if esperas != null:
		esperas.cortar()                             # cualquier otra animación corta la espera (esperas_3d.gd)
	var real: String = nombres.get(nombre, nombre)
	if anim.has_animation(real) and anim.current_animation != real:
		anim.play(real, _fundido_marcha if _fundido_marcha >= 0.0 else transicion)  # transición suave


func andar() -> void:
	_base_movimiento()
	play("Walking")
	_porte("andar")


func correr() -> void:
	_base_movimiento()
	play("Running")
	_porte("correr")


# Porte al andar y al correr (09/11): los clips de los tres héroes son el mismo movimiento de Meshy, así que cada uno
# lleva encima su manera de ir, como un giro que se suma al del clip (gestos_3d.gd, «+hueso»). El ritmo no cambia: lo
# fija la velocidad para que el pie apoyado no patine (marcha). Inclinarse adelante: eje (0, 0, -1), grados +.
const ESTILOS := {
	"Kael": {      # impaciente: echado hacia delante, con la cabeza alta, como quien tira del grupo
		"andar": {"+columna": [Vector3(0, 0, -1), 5.0], "+cabeza": [Vector3(0, 0, -1), -4.0]},
		"correr": {"+columna": [Vector3(0, 0, -1), 9.0], "+cabeza": [Vector3(0, 0, -1), -6.0]},
	},
	"Lya": {       # ligera y curiosa: erguida, mirando alrededor sin prisa
		"andar": {"+pecho": [Vector3(0, 0, -1), -3.0], "+cabeza": [Vector3(0, 1, 0), 9.0, 0.21],
			"+cuello": [Vector3(1, 0, 0), 3.0, 0.29, 1.0]},
		"correr": {"+columna": [Vector3(0, 0, -1), 4.0], "+cabeza": [Vector3(0, 0, -1), -3.0]},
	},
	"Garon": {     # sólido y veterano: el pecho fuera y la mirada al frente, algo baja
		"andar": {"+pecho": [Vector3(0, 0, -1), -4.0], "+cabeza": [Vector3(0, 0, -1), 5.0]},
		"correr": {"+columna": [Vector3(0, 0, -1), 6.0], "+pecho": [Vector3(0, 0, -1), -2.0]},
	},
}


func _porte(como: String) -> void:
	if gestos != null and gestos.gestos_def.has("porte_" + como):
		gestos.poner("porte_" + como, 1.0, 0.25)


func _base_movimiento() -> void:
	if esperas != null:
		esperas.cortar()
	gestos.quitar_todos(0.15)
	gestos.respirar = 0.0
	anim.speed_scale = 1.0


# ---------------------------------------------------------------- marcha por la exploración (T-084, tanda 2)
# Los clips de andar y correr son «en el sitio»: mientras un pie está apoyado, va hacia atrás a una velocidad fija, la
# del clip. Si el personaje avanza más deprisa que eso, el pie patina (en la exploración se andaba a 4,2 m/s con un clip
# de 1,2 m/s: el pie apoyado resbalaba a 3 m/s). marcha(v) elige el clip por la velocidad real en el suelo y ajusta su
# ritmo (anim.speed_scale) para que el pie apoyado se quede quieto: correr para la marcha normal (4,2 m/s, el clip de
# correr de Kael va a 3,9) y andar para ir despacio (el stick poco inclinado, acercarse, apartarse).
# Velocidad de cada clip sin patinar, en m/s para 1,7 m de alto (se escala con el tamaño del personaje): medida con
# pruebas/prueba_anim_pies.gd (2026-11-09). Los clips de los tres vienen del mismo movimiento (ciclo de 1,03 s al andar
# y de 0,63 s al correr) y apoyan el pie izquierdo en el 26 % del ciclo al andar y en el 29 % al correr: al cambiar de
# uno a otro se entra por el mismo punto de la zancada (el pie que estaba en el suelo sigue en el suelo).
var vel_andar := 1.50                       # Lya; kael_3d.gd y garon_3d.gd ponen las suyas
var vel_correr := 5.26
const APOYO_ANDAR := 0.26
const APOYO_CORRER := 0.29
# Ritmo mínimo y máximo de cada clip. Fuera de ellos patina un poco: mejor eso que un andar a cámara lenta o unas
# piernas que giran como molinillos. Al correr, hasta ×1,8: a 7,56 m/s (Kael corriendo hacia un toque lejano) el clip
# pediría ×1,94 (6,2 pasos por segundo) y con ×1,8 da 5,7 y el pie apoyado apenas se mueve (un 7 %).
const RITMO_ANDAR := Vector2(0.5, 1.9)
const RITMO_CORRER := Vector2(0.55, 1.8)
const VEL_QUIETO := 0.25                    # m/s: más despacio, no anda (quien la llama decide su reposo)
const CAMBIO_MARCHA := 0.08                 # ±8 % alrededor del punto de cambio: no parpadea entre andar y correr
# Al arrancar desde quieto, Kael pasa de golpe a 4,2 m/s (la velocidad del juego no cambia): mientras el reposo se
# funde con la marcha, los pies del reposo van con el cuerpo y resbalan. Por eso el arranque se funde en 0,1 s (no en
# 0,2) y entra por la mitad del apoyo del pie izquierdo (el pie bajo el cuerpo, como en el reposo).
const FUNDIDO_ARRANQUE := 0.1
const MEDIO_APOYO_ANDAR := 0.56
const MEDIO_APOYO_CORRER := 0.36
var _fundido_marcha := -1.0                 # si es ≥ 0, play() usa esta transición (la pone marcha() al arrancar)


# Clip y ritmo para ir a «v» m/s por el suelo. Devuelve "andar", "correr" o "" (por debajo de VEL_QUIETO: no toca nada
# y quien llama pone el reposo que quiera). Se llama en cada fotograma mientras se mueve; el combate no la usa.
func marcha(v: float) -> String:
	if anim == null or _muerta or v < VEL_QUIETO:
		return ""
	var e := _escala_mundo()
	var va := vel_andar * e
	var vc := vel_correr * e
	var cambio := sqrt(va * vc)             # los dos clips igual de lejos de su ritmo natural
	var antes := marcha_actual()
	var nueva := antes
	if antes == "":
		nueva = "correr" if v >= cambio else "andar"
	elif antes == "andar" and v > cambio * (1.0 + CAMBIO_MARCHA):
		nueva = "correr"
	elif antes == "correr" and v < cambio * (1.0 - CAMBIO_MARCHA):
		nueva = "andar"
	if nueva != antes:
		var fase := anim.current_animation_position / maxf(anim.current_animation_length, 0.001)
		_fundido_marcha = FUNDIDO_ARRANQUE if antes == "" else -1.0
		if nueva == "correr":
			correr()                         # cada personaje pone lo suyo: el sable al hombro, el viento en la capa…
		else:
			andar()
		_fundido_marcha = -1.0
		var entra: float
		if antes == "":                      # desde quieto: por la mitad del apoyo
			entra = MEDIO_APOYO_CORRER if nueva == "correr" else MEDIO_APOYO_ANDAR
		else:                                # de andar a correr o al revés: por el mismo punto de la zancada
			var desde := APOYO_ANDAR if antes == "andar" else APOYO_CORRER
			var hasta := APOYO_CORRER if nueva == "correr" else APOYO_ANDAR
			entra = fposmod(fase - desde + hasta, 1.0)
		anim.seek(entra * anim.current_animation_length, true)
	var lim: Vector2 = RITMO_CORRER if nueva == "correr" else RITMO_ANDAR
	anim.speed_scale = clampf(v / (vc if nueva == "correr" else va), lim.x, lim.y)
	return nueva


# Se para tras andar o correr: su reposo, pero sin que la zancada siga mientras se funde con él (el clip de marcha se
# congela durante la mezcla). Si no, en esa mezcla el pie que iba en el aire seguía su ciclo y daba un paso más con el
# cuerpo ya quieto (y sonaba: Sonido.pasos_3d). Si vuelve a andar antes, marcha() pone su ritmo.
const FUNDIDO_PARADA := 0.3


func parar_marcha() -> void:
	var venia := marcha_actual() != ""
	reposo()
	if not venia or anim == null:
		return
	var ritmo := anim.speed_scale                  # el que deja el reposo (más lento si está cansado)
	anim.speed_scale = 0.0
	get_tree().create_timer(FUNDIDO_PARADA).timeout.connect(func():
		if is_instance_valid(self) and anim.speed_scale == 0.0 and not _muerta:
			anim.speed_scale = ritmo)


# "andar" o "correr" si está sonando uno de sus clips de marcha, o "".
func marcha_actual() -> String:
	if anim == null:
		return ""
	var actual := String(anim.current_animation)
	if actual == "":
		return ""
	if actual == String(nombres.get("Running", "")):
		return "correr"
	if actual == String(nombres.get("Andar_normal", nombres.get("Walking", ""))):
		return "andar"
	return ""


# Cuánto mide respecto a los 1,7 m de los clips medidos (Lya va al 90 % en la exploración: grupo_3d.gd, ESCALA).
func _escala_mundo() -> float:
	return maxf(global_transform.basis.get_scale().y, 0.01)


# ---------------------------------------------------------------- esperas de exploración (personalidad, 09/11)

# Enciende (o apaga) las esperas: si se queda quieto en su reposo unos segundos, hace una de las suyas (esperas_3d.gd).
# Solo la exploración la llama (vista3d.gd y grupo_3d.gd); en combate no hay esperas.
func activar_esperas(si := true) -> bool:
	if not si:
		if esperas != null:
			esperas.cortar()
			esperas.queue_free()
			esperas = null
		return false
	if esperas != null:
		return true
	if anim == null or not ResourceLoader.exists("res://esperas_3d.gd"):
		return false
	var e: Node = load("res://esperas_3d.gd").new()
	if not e.preparar(self, clave_esperas):
		e.free()
		return false
	esperas = e
	add_child(e)
	return true


# Al empezar una espera, el cetro pasa a ir con la mano (la espera lo inclina o lo cruza delante); al acabar, vuelve a
# ir siempre derecho. Empieza y acaba en la pose de reposo, donde las dos maneras coinciden.
func espera_empieza() -> void:
	if vara == null:
		return
	_vara_calibrar = true
	_fundir_vara(1.0, 0.05)


func espera_termina(fundido: float) -> void:
	if vara != null:
		_fundir_vara(0.0, maxf(fundido, 0.05))


func _fundir_vara(meta: float, t: float) -> void:
	if _tw_vara != null and _tw_vara.is_valid():
		_tw_vara.kill()
	_tw_vara = create_tween()
	_tw_vara.tween_property(self, "vara_mano", meta, t)


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
	# (18/11) a 0,3 m (antes 0,1): con 0,1 el lado izquierdo quedaba 0,21-0,26 m bajo el suelo (DERROTA_SUELO_18_11.md)
	_tw_caida.tween_property(caida, "position", Vector3(-0.88, 0.3, 0.0), 0.55)


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
