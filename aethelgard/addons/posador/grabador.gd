@tool
class_name PosadorGrabador
extends RefCounted
# Graba la pose de un PosadorIK como fotogramas clave de una Animation y la guarda
# en una AnimationLibrary (.res). Graba el giro de todos los huesos y la posición de la cadera.


# Ruta de pistas del esqueleto vista desde el nodo raíz del AnimationPlayer
# (ej. "SmartRigArmature/Skeleton3D" en los modelos de Meshy).
static func ruta_esqueleto(ap: AnimationPlayer, sk: Skeleton3D) -> String:
	var raiz := ap.get_node_or_null(ap.root_node)
	if raiz == null:
		return ""
	return str(raiz.get_path_to(sk))


static func nueva_animacion(duracion := 1.0, en_bucle := false) -> Animation:
	var a := Animation.new()
	a.length = duracion
	a.loop_mode = Animation.LOOP_LINEAR if en_bucle else Animation.LOOP_NONE
	return a


# Añade (o sustituye) un fotograma con la pose final del posador en el tiempo dado.
# Devuelve cuántas claves se escribieron.
static func grabar_fotograma(anim: Animation, posador: PosadorIK, ruta: String, tiempo: float) -> int:
	var sk := posador.get_skeleton()
	if sk == null or posador.ultima_pose.size() != sk.get_bone_count():
		push_warning("PosadorGrabador: el posador aún no ha calculado ninguna pose")
		return 0
	var cadera: int = posador.idx.get("cadera", -1)
	var claves := 0
	for i in sk.get_bone_count():
		var pose: Transform3D = posador.ultima_pose[i]
		var base := "%s:%s" % [ruta, sk.get_bone_name(i)]
		var pr := _pista(anim, base, Animation.TYPE_ROTATION_3D)
		_poner_clave(anim, pr, tiempo, pose.basis.get_rotation_quaternion())
		claves += 1
		if i == cadera:
			var pp := _pista(anim, base, Animation.TYPE_POSITION_3D)
			_poner_clave(anim, pp, tiempo, pose.origin)
			claves += 1
	if tiempo > anim.length:
		anim.length = tiempo
	return claves


# Quita todas las claves que haya en ese tiempo.
static func borrar_fotograma(anim: Animation, tiempo: float) -> void:
	for t in anim.get_track_count():
		var k := anim.track_find_key(t, tiempo, Animation.FIND_MODE_APPROX)
		if k >= 0:
			anim.track_remove_key(t, k)


static func tiempos(anim: Animation) -> PackedFloat32Array:
	var r := PackedFloat32Array()
	if anim.get_track_count() == 0:
		return r
	for k in anim.track_get_key_count(0):
		r.append(anim.track_get_key_time(0, k))
	return r


# Guarda la animación en una AnimationLibrary (la crea si no existe; si ya existe, la amplía).
static func guardar(anim: Animation, nombre: String, ruta_libreria: String) -> Error:
	var lib: AnimationLibrary = null
	if ResourceLoader.exists(ruta_libreria):
		lib = ResourceLoader.load(ruta_libreria, "", ResourceLoader.CACHE_MODE_IGNORE) as AnimationLibrary
	if lib == null:
		lib = AnimationLibrary.new()
		DirAccess.make_dir_recursive_absolute(ruta_libreria.get_base_dir())
	if lib.has_animation(nombre):
		lib.remove_animation(nombre)
	lib.add_animation(nombre, anim.duplicate(true))
	return ResourceSaver.save(lib, ruta_libreria)


static func _pista(anim: Animation, ruta: String, tipo: int) -> int:
	var t := anim.find_track(NodePath(ruta), tipo)
	if t < 0:
		t = anim.add_track(tipo)
		anim.track_set_path(t, NodePath(ruta))
		anim.track_set_interpolation_type(t, Animation.INTERPOLATION_LINEAR)
	return t


static func _poner_clave(anim: Animation, pista: int, tiempo: float, valor: Variant) -> void:
	var k := anim.track_find_key(pista, tiempo, Animation.FIND_MODE_APPROX)
	if k >= 0:
		anim.track_remove_key(pista, k)
	if anim.track_get_type(pista) == Animation.TYPE_ROTATION_3D:
		anim.rotation_track_insert_key(pista, tiempo, valor)
	else:
		anim.position_track_insert_key(pista, tiempo, valor)
