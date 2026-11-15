extends SkeletonModifier3D
# V12, Érebo híbrida (15/11): la CABEZA FIRME de Érebo en la invocación híbrida (invocacion_erebo_hibrida.gd).
# Petición del usuario: «Érebo mueve la cabeza de forma rara… tiene que estar de una forma imponente y segura de lo que
# hace». Lo raro venía del clip de reposo de Érebo («Thriller Idle» de Mixamo, erebo_idle.fbx: la cabeza de zombi se
# mece y cae a los lados) y del clip de agarrar («Picking Up Object»: baja la cabeza a mirar el suelo), que se ven
# mientras se acerca, mete la mano y enseña el corazón.
# Este modificador va DESPUÉS de los gestos de Érebo (gestos_3d.gd y su IK de los brazos) y, con «peso», lleva:
#   · el cuello a su pose de descanso respecto al pecho (erguido, sin mecerse);
#   · la cabeza a mirar a «mirar_a» (el pecho del enemigo, luego el corazón, luego el orbe), con la barbilla alta,
#     con un giro máximo y suavizado (velocidad angular limitada: sin tirones ni temblores).
# Es un nodo PROPIO que solo añade la híbrida al Érebo que ella crea: erebo_3d.gd y las otras invocaciones no cambian.

var peso := 0.0                    # 0 = la cabeza del clip; 1 = firme (lo anima la híbrida)
var mirar_a := Vector3.INF         # punto del mundo al que mira; INF = al frente
var sigue := Callable()            # si vale, devuelve el punto a mirar en cada fotograma (el corazón, el orbe...)
var barbilla := 7.0                # grados de barbilla alta
var giro_max := 45.0               # grados que puede girar respecto al frente del cuerpo
var vel_max := 140.0               # grados por segundo como mucho
var suavizado := 6.0               # 1/s
var _cuello := -1
var _cabeza := -1
var _adelante := Vector3.BACK      # el frente del personaje y su arriba, en el espacio del esqueleto (gestos_3d)
var _arriba := Vector3.UP
var _fwd_cabeza := Vector3.BACK    # el frente de la cara en el espacio del hueso de la cabeza
var _dir := Vector3.ZERO           # hacia dónde mira ahora (espacio del esqueleto), suavizado
var _rest_g := Basis.IDENTITY      # la cabeza en reposo, en el espacio del esqueleto
var listo := false
# medidas (diagnóstico y pruebas), del pose FINAL (después de los gestos y de esto), desde que «medir» es true:
var medir := false
var ladeo := 0.0                   # grados que se ladea la cara ahora (su eje derecha respecto al horizonte)
var ladeo_max := 0.0
var vel_max_medida := 0.0          # grados por segundo que gira la cara, como mucho
var _derecha := Vector3.LEFT
var _fwd_prev := Vector3.ZERO


func preparar(gestos) -> void:
	var sk := get_skeleton()
	if sk == null or gestos == null:
		return
	_cuello = int(gestos.idx.get("cuello", -1))
	_cabeza = int(gestos.idx.get("cabeza", -1))
	_adelante = gestos.adelante
	_arriba = gestos.arriba
	_derecha = gestos.derecha
	if _cabeza < 0:
		return
	var rest_g: Basis = sk.get_bone_global_rest(_cabeza).basis.orthonormalized()
	_fwd_cabeza = (rest_g.inverse() * _adelante).normalized()
	_rest_g = rest_g
	listo = true


func _process_modification() -> void:
	var sk := get_skeleton()
	if not listo or sk == null:
		return
	var dt := get_process_delta_time()
	if peso > 0.001:
		_firme(sk, dt)
	if medir:
		_medir(sk, dt)


func _medir(sk: Skeleton3D, dt: float) -> void:
	var b: Basis = sk.get_bone_global_pose(_cabeza).basis.orthonormalized()
	var der := (b * (_rest_g.inverse() * _derecha)).normalized()
	ladeo = rad_to_deg(asin(clampf(der.dot(_arriba), -1.0, 1.0)))
	ladeo_max = maxf(ladeo_max, absf(ladeo))
	var fwd := (b * _fwd_cabeza).normalized()
	if _fwd_prev != Vector3.ZERO and dt > 0.0:
		vel_max_medida = maxf(vel_max_medida, rad_to_deg(_fwd_prev.angle_to(fwd)) / dt)
	_fwd_prev = fwd


func _firme(sk: Skeleton3D, dt: float) -> void:
	# el cuello, erguido respecto al pecho (su pose de descanso)
	if _cuello >= 0:
		var anim_q := sk.get_bone_pose_rotation(_cuello)
		var rest_q := sk.get_bone_rest(_cuello).basis.get_rotation_quaternion()
		sk.set_bone_pose_rotation(_cuello, anim_q.slerp(rest_q, peso))
	# la cabeza: erguida respecto al cuello y mirando al punto, con la barbilla alta
	var padre := sk.get_bone_parent(_cabeza)
	var padre_g: Basis = sk.get_bone_global_pose(padre).basis.orthonormalized() if padre >= 0 else Basis.IDENTITY
	var rest_l: Basis = sk.get_bone_rest(_cabeza).basis.orthonormalized()
	var erguida := padre_g * rest_l
	var f0 := (erguida * _fwd_cabeza).normalized()
	var objetivo := _adelante
	if sigue.is_valid():
		var p = sigue.call()
		if p is Vector3:
			mirar_a = p
	if mirar_a != Vector3.INF:
		var pos_cab: Vector3 = sk.get_bone_global_pose(_cabeza).origin
		var hacia: Vector3 = sk.global_transform.affine_inverse() * mirar_a - pos_cab
		if hacia.length() > 0.001:
			objetivo = hacia.normalized()
	objetivo = _limitar(objetivo)
	if _dir == Vector3.ZERO:
		_dir = f0
	var ang := _dir.angle_to(objetivo)
	if ang > 0.0001:
		var paso := minf(ang * (1.0 - exp(-suavizado * dt)), deg_to_rad(vel_max) * dt)
		_dir = _dir.slerp(objetivo, paso / ang).normalized()
	# la cabeza NIVELADA: mira a «_dir» con su arriba hacia el arriba del personaje (sin ladearse aunque el pecho se
	# ladee con el clip); después, la barbilla alta
	var der := _arriba.cross(_dir)
	if der.length() < 0.001:
		der = _arriba.cross(_adelante)
	der = der.normalized()
	var arr := _dir.cross(der).normalized()
	var marco1 := Basis(der, arr, _dir)
	var der0 := _arriba.cross(_adelante).normalized()
	var marco0 := Basis(der0, _adelante.cross(der0).normalized(), _adelante)
	var giro := marco1 * marco0.inverse()
	var eje := _dir.cross(_arriba)
	var q_barb := Quaternion(eje.normalized(), deg_to_rad(barbilla)) if eje.length() > 0.001 else Quaternion.IDENTITY
	var deseada := Basis(q_barb) * giro * _rest_g
	var local_q := (padre_g.inverse() * deseada).orthonormalized().get_rotation_quaternion()
	var anim_c := sk.get_bone_pose_rotation(_cabeza)
	sk.set_bone_pose_rotation(_cabeza, anim_c.slerp(local_q, peso))


# Que no se tuerza: como mucho «giro_max» respecto al frente del cuerpo y ±25° arriba o abajo.
func _limitar(d: Vector3) -> Vector3:
	var horiz := d - _arriba * d.dot(_arriba)
	var alto := clampf(d.dot(_arriba), -0.42, 0.42)
	if horiz.length() < 0.001:
		horiz = _adelante
	horiz = horiz.normalized()
	var a := _adelante.signed_angle_to(horiz, _arriba)
	a = clampf(a, -deg_to_rad(giro_max), deg_to_rad(giro_max))
	horiz = _adelante.rotated(_arriba, a)
	return (horiz * sqrt(1.0 - alto * alto) + _arriba * alto).normalized()
