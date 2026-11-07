@tool
class_name PosadorIK
extends SkeletonModifier3D
# Posador de Aethelgard: IK de dos huesos para manos y pies, y control de la cadera.
# Va como hijo del Skeleton3D. Crea objetivos (Marker3D) que se arrastran en el editor:
#   - mano_i / mano_d / pie_i / pie_d: dónde tiene que llegar la mano o el pie (y su giro).
#   - codo_i / codo_d / rodilla_i / rodilla_d: hacia dónde se dobla la articulación.
#   - cadera: mueve y gira la cadera; los pies se quedan donde estén sus objetivos.
# Solo toca la cadera y los huesos de brazos y piernas; el resto del esqueleto se deja como esté.

# Nombres de hueso del esqueleto Mixamo (con o sin prefijo "mixamorig").
const HUESOS := {
	"cadera": "Hips",
	"brazo_i": "LeftArm", "antebrazo_i": "LeftForeArm", "mano_i": "LeftHand",
	"brazo_d": "RightArm", "antebrazo_d": "RightForeArm", "mano_d": "RightHand",
	"muslo_i": "LeftUpLeg", "pierna_i": "LeftLeg", "pie_i": "LeftFoot",
	"muslo_d": "RightUpLeg", "pierna_d": "RightLeg", "pie_d": "RightFoot",
}

# Cadena -> [hueso superior, hueso medio, hueso final, nombre del polo]
const CADENAS := {
	"mano_i": ["brazo_i", "antebrazo_i", "mano_i", "codo_i"],
	"mano_d": ["brazo_d", "antebrazo_d", "mano_d", "codo_d"],
	"pie_i": ["muslo_i", "pierna_i", "pie_i", "rodilla_i"],
	"pie_d": ["muslo_d", "pierna_d", "pie_d", "rodilla_d"],
}

# Hacia dónde se coloca el polo al crearlo (en ejes del personaje: x = izquierda, z = delante).
const POLO_INICIAL := {
	"codo_i": Vector3(0, 0, -0.35), "codo_d": Vector3(0, 0, -0.35),
	"rodilla_i": Vector3(0, 0, 0.45), "rodilla_d": Vector3(0, 0, 0.45),
}

@export var ik_mano_i := true
@export var ik_mano_d := true
@export var ik_pie_i := true
@export var ik_pie_d := true
@export var mover_cadera := true
## Copia el giro del objetivo en la mano o el pie (si no, se queda el giro que traiga).
@export var girar_extremos := true
@export_tool_button("Crear / recolocar objetivos", "Marker3D") var _boton_crear := crear_objetivos

var idx := {}                       # nombre -> índice de hueso
var ultima_pose: Array[Transform3D] = []   # pose local final de cada hueso (para grabar)
var error_cadena := {}              # cadena -> distancia (m) entre el extremo y su objetivo


func _ready() -> void:
	_buscar_huesos()
	if Engine.is_editor_hint() and get_child_count() == 0:
		crear_objetivos.call_deferred()


func _buscar_huesos() -> bool:
	var sk := get_skeleton()
	if sk == null:
		return false
	idx.clear()
	for k in HUESOS:
		idx[k] = -1
		var buscado: String = HUESOS[k]
		for i in sk.get_bone_count():
			var n := sk.get_bone_name(i)
			if n == buscado or n.ends_with(":" + buscado) or n.ends_with("_" + buscado):
				idx[k] = i
				break
	for k in idx:
		if idx[k] < 0:
			push_warning("PosadorIK: no encuentro el hueso '%s' (¿no es un esqueleto Mixamo?)" % HUESOS[k])
			return false
	return true


func objetivo(nombre: String) -> Marker3D:
	return get_node_or_null(nombre) as Marker3D


# Crea los objetivos en la pose actual (o los recoloca si ya existen).
func crear_objetivos() -> void:
	var sk := get_skeleton()
	if sk == null or not _buscar_huesos():
		return
	var duenio: Node = null
	if Engine.is_editor_hint() and is_inside_tree():
		duenio = get_tree().edited_scene_root
	var a_mundo := sk.global_transform
	var nombres: Array = ["cadera"]
	for c in CADENAS:
		nombres.append(c)
		nombres.append(CADENAS[c][3])
	for n in nombres:
		var m := objetivo(n)
		if m == null:
			m = Marker3D.new()
			m.name = n
			m.gizmo_extents = 0.08 if n in CADENAS or n == "cadera" else 0.04
			add_child(m)
			if duenio:
				m.owner = duenio
		var t: Transform3D
		if n == "cadera" or n in CADENAS:
			t = sk.get_bone_global_pose(idx[n])
		else:
			# polo: delante o detrás de la articulación media
			var cadena: String = _cadena_de_polo(n)
			var medio: Transform3D = sk.get_bone_global_pose(idx[CADENAS[cadena][1]])
			t = Transform3D(Basis(), medio.origin + POLO_INICIAL[n])
		m.global_transform = a_mundo * Transform3D(t.basis.orthonormalized(), t.origin)


func _cadena_de_polo(polo: String) -> String:
	for c in CADENAS:
		if CADENAS[c][3] == polo:
			return c
	return ""


func _activa(cadena: String) -> bool:
	match cadena:
		"mano_i": return ik_mano_i
		"mano_d": return ik_mano_d
		"pie_i": return ik_pie_i
		"pie_d": return ik_pie_d
	return false


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if idx.is_empty() and not _buscar_huesos():
		return
	var a_esqueleto := sk.global_transform.affine_inverse()

	# 1) cadera
	var mc := objetivo("cadera")
	if mover_cadera and mc:
		var t := a_esqueleto * mc.global_transform
		var actual := sk.get_bone_global_pose(idx["cadera"])
		var escala := actual.basis.get_scale()
		sk.set_bone_global_pose(idx["cadera"], Transform3D(t.basis.orthonormalized().scaled_local(escala), t.origin))

	# 2) brazos y piernas
	error_cadena.clear()
	for c in CADENAS:
		var m := objetivo(c)
		if m == null or not _activa(c):
			continue
		var polo := objetivo(CADENAS[c][3])
		var t := a_esqueleto * m.global_transform
		var p: Vector3 = (a_esqueleto * polo.global_position) if polo else Vector3.INF
		_resolver(sk, idx[CADENAS[c][0]], idx[CADENAS[c][1]], idx[CADENAS[c][2]], t, p)
		error_cadena[c] = sk.get_bone_global_pose(idx[CADENAS[c][2]]).origin.distance_to(t.origin)

	# 3) se guarda la pose final para poder grabarla
	ultima_pose.resize(sk.get_bone_count())
	for i in sk.get_bone_count():
		ultima_pose[i] = sk.get_bone_pose(i)


# IK analítico de dos huesos (ley del coseno) en espacio del esqueleto.
func _resolver(sk: Skeleton3D, i_sup: int, i_med: int, i_fin: int, objetivo_t: Transform3D, polo: Vector3) -> void:
	var sup := sk.get_bone_global_pose(i_sup)
	var med := sk.get_bone_global_pose(i_med)
	var fin := sk.get_bone_global_pose(i_fin)
	var a := sup.origin
	var b := med.origin
	var c := fin.origin
	var l1 := a.distance_to(b)
	var l2 := b.distance_to(c)
	if l1 < 1e-5 or l2 < 1e-5:
		return
	var hacia := objetivo_t.origin - a
	var d := clampf(hacia.length(), absf(l1 - l2) + 1e-4, l1 + l2 - 1e-4)
	var eje := hacia.normalized() if hacia.length() > 1e-6 else (c - a).normalized()

	# plano de doblado: hacia el polo; si no hay polo o está alineado, el doblado actual
	var lado := Vector3.ZERO
	if polo != Vector3.INF:
		lado = (polo - a) - eje * (polo - a).dot(eje)
	if lado.length() < 1e-5:
		lado = (b - a) - eje * (b - a).dot(eje)
	if lado.length() < 1e-5:
		lado = eje.cross(Vector3.UP)
		if lado.length() < 1e-5:
			lado = eje.cross(Vector3.FORWARD)
	lado = lado.normalized()

	var cos_a := clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0)
	var sin_a := sqrt(1.0 - cos_a * cos_a)
	var b_nuevo := a + eje * (cos_a * l1) + lado * (sin_a * l1)
	var c_nuevo := a + eje * d

	# hueso superior: gira para que el medio quede en b_nuevo
	var giro1 := _giro_entre(b - a, b_nuevo - a)
	sk.set_bone_global_pose(i_sup, Transform3D(Basis(giro1) * sup.basis, a))

	# hueso medio: gira para que el final quede en c_nuevo
	med = sk.get_bone_global_pose(i_med)
	fin = sk.get_bone_global_pose(i_fin)
	var giro2 := _giro_entre(fin.origin - med.origin, c_nuevo - med.origin)
	sk.set_bone_global_pose(i_med, Transform3D(Basis(giro2) * med.basis, med.origin))

	# extremo: copia el giro del objetivo, conservando su escala
	if girar_extremos:
		fin = sk.get_bone_global_pose(i_fin)
		var escala := fin.basis.get_scale()
		sk.set_bone_global_pose(i_fin, Transform3D(objetivo_t.basis.orthonormalized().scaled_local(escala), fin.origin))


static func _giro_entre(de: Vector3, a: Vector3) -> Quaternion:
	if de.length() < 1e-6 or a.length() < 1e-6:
		return Quaternion.IDENTITY
	var u := de.normalized()
	var v := a.normalized()
	if u.dot(v) > 0.999999:
		return Quaternion.IDENTITY
	if u.dot(v) < -0.999999:
		var perp := u.cross(Vector3.RIGHT)
		if perp.length() < 1e-5:
			perp = u.cross(Vector3.UP)
		return Quaternion(perp.normalized(), PI)
	return Quaternion(u, v)
