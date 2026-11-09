extends SkeletonModifier3D
# Gestos hechos por código encima de las animaciones del modelo 3D (Godot 4.3 o superior).
# Va como hijo del Skeleton3D. Cada gesto orienta algunos huesos hacia direcciones
# del propio personaje (adelante, arriba, derecha), así funciona aunque el modelo
# se haya importado con otros ejes.

# Nombres de hueso que se buscan (esqueleto Mixamo, con o sin el prefijo "mixamorig").
const HUESOS := {
	"cadera": ["Hips"], "columna": ["Spine"], "columna1": ["Spine1"], "pecho": ["Spine2"],
	"cuello": ["Neck"], "cabeza": ["Head"], "cabeza_fin": ["HeadTop_End"],
	"brazo_i": ["LeftArm", "LeftUpperArm"], "antebrazo_i": ["LeftForeArm", "LeftLowerArm"],
	"mano_i": ["LeftHand"], "dedo_i": ["LeftHandMiddle1"],
	"brazo_d": ["RightArm", "RightUpperArm"], "antebrazo_d": ["RightForeArm", "RightLowerArm"],
	"mano_d": ["RightHand"], "dedo_d": ["RightHandMiddle1"],
	"muslo_i": ["LeftUpLeg"], "rodilla_i": ["LeftLeg"], "pie_i": ["LeftFoot"], "dedos_i": ["LeftToeBase"],
	"muslo_d": ["RightUpLeg"], "rodilla_d": ["RightLeg"], "pie_d": ["RightFoot"], "dedos_d": ["RightToeBase"],
}

# Orden en que se tocan los huesos: siempre del padre al hijo.
const ORDEN := ["cadera", "muslo_i", "rodilla_i", "pie_i", "muslo_d", "rodilla_d", "pie_d",
	"columna", "columna1", "pecho", "cuello", "cabeza",
	"brazo_i", "antebrazo_i", "mano_i", "brazo_d", "antebrazo_d", "mano_d"]

# Hueso que marca hacia dónde apunta cada hueso.
const HIJO := {"columna": "columna1", "columna1": "pecho", "pecho": "cuello", "cuello": "cabeza",
	"cabeza": "cabeza_fin", "brazo_i": "antebrazo_i", "antebrazo_i": "mano_i", "mano_i": "dedo_i",
	"brazo_d": "antebrazo_d", "antebrazo_d": "mano_d", "mano_d": "dedo_d",
	"muslo_i": "rodilla_i", "rodilla_i": "pie_i", "pie_i": "dedos_i",
	"muslo_d": "rodilla_d", "rodilla_d": "pie_d", "pie_d": "dedos_d"}

# Cada gesto: hueso -> [dirección (adelante, arriba, derecha), ángulo máximo en grados].
# La izquierda del personaje es derecha negativa.
# "_cadera" mueve la cadera (en metros, para un personaje de 1,7 m): sirve para agacharse.
# "+hueso": [eje (adelante, arriba, derecha), grados] SUMA ese giro al del clip en vez de orientar el hueso (sirve
#   para el porte al andar: maga_3d.gd, ESTILOS); con [eje, grados, ciclos por segundo, fase] va y viene.
#   Inclinarse hacia delante es girar alrededor de la izquierda: Vector3(0, 0, -1).
# Los gestos que empiezan por "k_" son de Kael (sable).
const GESTOS := {
	# brazos relajados a los lados (el modelo trae los brazos abiertos en A)
	"reposo": {
		"brazo_i": [Vector3(0.12, -1, -0.2), 80], "antebrazo_i": [Vector3(0.45, -1, 0.05), 80],
		"brazo_d": [Vector3(0.12, -1, 0.2), 80], "antebrazo_d": [Vector3(0.45, -1, -0.05), 80],
	},
	# cansancio: espalda y cabeza caídas, brazos colgando
	"cansada": {
		"columna": [Vector3(0.4, 1, 0), 14], "pecho": [Vector3(0.3, 1, 0), 8], "cabeza": [Vector3(0.5, 1, 0), 15],
		"brazo_i": [Vector3(0.15, -1, -0.05), 90], "antebrazo_i": [Vector3(0.35, -1, 0.1), 60],
		"brazo_d": [Vector3(0.15, -1, 0.05), 90], "antebrazo_d": [Vector3(0.35, -1, -0.1), 60],
	},
	# conjuro: las dos manos alzadas por delante, mirada hacia arriba
	"conjuro": {
		"pecho": [Vector3(-0.15, 1, 0), 10], "cabeza": [Vector3(-0.25, 1, 0), 20],
		"brazo_i": [Vector3(0.95, 0.05, -0.3), 170], "antebrazo_i": [Vector3(0.85, 0.45, 0.4), 170], "mano_i": [Vector3(0.3, 1, 0.1), 60],
		"brazo_d": [Vector3(0.95, 0.05, 0.3), 170], "antebrazo_d": [Vector3(0.85, 0.45, -0.4), 170], "mano_d": [Vector3(0.3, 1, -0.1), 60],
	},
	# preparar el golpe: brazo derecho atrás y arriba
	"golpe_prep": {
		"columna": [Vector3(-0.15, 1, 0.15), 10],
		"brazo_d": [Vector3(-0.25, 0.85, 0.35), 170], "antebrazo_d": [Vector3(-0.55, 0.55, 0.2), 170],
		"brazo_i": [Vector3(0.5, -0.6, -0.3), 90],
	},
	# golpe con la palma hacia delante
	"golpe": {
		"columna": [Vector3(0.35, 1, 0), 18],
		"brazo_d": [Vector3(1, -0.2, -0.1), 170], "antebrazo_d": [Vector3(1, -0.1, -0.1), 170], "mano_d": [Vector3(1, 0.4, 0), 60],
		"brazo_i": [Vector3(-0.4, -0.9, -0.3), 90],
	},
	# recibe un golpe: se echa hacia atrás y se cubre
	"herida": {
		"columna": [Vector3(-0.35, 1, 0.1), 14], "columna1": [Vector3(-0.5, 1, 0), 18], "cabeza": [Vector3(-0.45, 1, 0.35), 25],
		"brazo_i": [Vector3(0.7, 0.05, -0.45), 120], "antebrazo_i": [Vector3(0.2, 1, 0.55), 150], "mano_i": [Vector3(-0.2, 1, 0.3), 50],
		"brazo_d": [Vector3(0.1, -0.9, 0.55), 90], "antebrazo_d": [Vector3(0.3, -0.8, 0.3), 70],
	},
	# victoria: brazo derecho en alto y la otra mano en la cadera
	"victoria": {
		"pecho": [Vector3(-0.12, 1, 0), 8], "cabeza": [Vector3(-0.15, 1, 0.25), 15],
		"brazo_d": [Vector3(0.15, 1, 0.15), 175], "antebrazo_d": [Vector3(0.05, 1, -0.05), 175], "mano_d": [Vector3(0, 1, 0), 60],
		"brazo_i": [Vector3(-0.15, -0.75, -0.6), 120], "antebrazo_i": [Vector3(0.25, 0.35, 0.9), 150],
	},
	# --- Kael ---
	# brazo derecho con el sable al hombro: kael_3d.gd lo copia de su reposo al empezar
	"k_hombro": {},
	# solo mueve el sable (vertical delante de la cara) mientras lanza magia
	"k_magia": {},
	# coger impulso: se agacha con el sable al hombro
	"k_agachar": {
		"_cadera": Vector3(0.03, -0.13, 0.0),
		"muslo_i": [Vector3(0.55, -0.8, -0.05), 80], "rodilla_i": [Vector3(-0.35, -1, 0), 80],
		"muslo_d": [Vector3(0.45, -0.85, 0.05), 80], "rodilla_d": [Vector3(-0.4, -1, 0), 80],
		"columna": [Vector3(0.35, 1, 0), 18], "cabeza": [Vector3(0.2, 1, 0), 15],
	},
	# en el aire: sable en alto con las dos manos, rodillas recogidas
	"k_alto": {
		"_cadera": Vector3(0.0, 0.02, 0.0),
		"muslo_i": [Vector3(0.8, -0.45, -0.05), 100], "rodilla_i": [Vector3(-0.2, -1, 0), 100],
		"muslo_d": [Vector3(0.55, -0.65, 0.05), 100], "rodilla_d": [Vector3(-0.55, -1, 0), 100],
		"pecho": [Vector3(-0.3, 1, 0), 15],
		"brazo_i": [Vector3(0.15, 1, -0.15), 175], "antebrazo_i": [Vector3(-0.6, 0.7, 0.25), 175],
		"brazo_d": [Vector3(0.15, 1, 0.15), 175], "antebrazo_d": [Vector3(-0.7, 0.6, -0.05), 175],
	},
	# cae cortando: sable abajo por delante, piernas en zancada
	"k_corte": {
		"_cadera": Vector3(0.1, -0.16, 0.0),
		"muslo_d": [Vector3(0.7, -0.7, 0.08), 90], "rodilla_d": [Vector3(0.1, -1, 0), 90],
		"muslo_i": [Vector3(-0.3, -1, -0.05), 60], "rodilla_i": [Vector3(-0.6, -0.8, 0), 90],
		"columna": [Vector3(0.6, 1, 0), 30], "pecho": [Vector3(0.4, 1, 0), 15], "cabeza": [Vector3(0.5, 1, 0), 20],
		"brazo_i": [Vector3(1, -0.3, -0.05), 175], "antebrazo_i": [Vector3(0.8, -0.7, 0.15), 175],
		"brazo_d": [Vector3(1, -0.25, 0.05), 175], "antebrazo_d": [Vector3(0.8, -0.7, 0), 175],
	},
	# poca vida: encorvado y con las rodillas flojas (el sable sigue al hombro)
	"k_cansado": {
		"_cadera": Vector3(0.0, -0.04, 0.0),
		"muslo_i": [Vector3(0.2, -1, -0.05), 20], "rodilla_i": [Vector3(-0.15, -1, 0), 20],
		"muslo_d": [Vector3(0.2, -1, 0.05), 20], "rodilla_d": [Vector3(-0.15, -1, 0), 20],
		"columna": [Vector3(0.4, 1, 0), 14], "pecho": [Vector3(0.3, 1, 0), 8], "cabeza": [Vector3(0.5, 1, 0), 15],
	},
	# victoria: sable en alto
	"k_victoria": {
		"pecho": [Vector3(-0.12, 1, 0), 8], "cabeza": [Vector3(-0.15, 1, 0), 12],
		"brazo_d": [Vector3(0.1, 1, 0.2), 175], "antebrazo_d": [Vector3(0.05, 1, 0), 175],
	},
	# derrotada en el suelo: cuerpo flojo y brazos abiertos
	"caida": {
		"columna1": [Vector3(-0.2, 1, 0), 10], "cabeza": [Vector3(-0.3, 1, 0.3), 20],
		"brazo_i": [Vector3(0.3, -1, -0.35), 120], "antebrazo_i": [Vector3(0.4, -1, -0.1), 60],
		"brazo_d": [Vector3(0.3, -1, 0.35), 120], "antebrazo_d": [Vector3(0.4, -1, 0.1), 60],
	},
}

var idx := {}
var gestos_def := {}   # GESTOS más los que se registran en ejecución
var al_terminar := Callable()   # se llama con el esqueleto cuando ya están puestos todos los gestos
var adelante := Vector3.BACK
var arriba := Vector3.UP
var derecha := Vector3.LEFT
var peso := {}         # peso actual de cada gesto (0 a 1)
var objetivo := {}     # peso hacia el que va
var rapidez := {}      # cuánto cambia por segundo
var respirar := 1.0    # 0 = sin respiración
var escala := 1.0      # altura del esqueleto / 1,7 m
var tiempo := 0.0
var listo := false


func _ready() -> void:
	preparar()


func preparar() -> void:
	var sk := get_skeleton()
	if sk == null or listo:
		return
	for k in HUESOS:
		idx[k] = _buscar(sk, HUESOS[k])
	if idx["cadera"] >= 0 and idx["cabeza"] >= 0 and idx["brazo_i"] >= 0 and idx["brazo_d"] >= 0:
		var cad := sk.get_bone_global_rest(idx["cadera"]).origin
		var cab := sk.get_bone_global_rest(idx["cabeza"]).origin
		var bi := sk.get_bone_global_rest(idx["brazo_i"]).origin
		var bd := sk.get_bone_global_rest(idx["brazo_d"]).origin
		arriba = (cab - cad).normalized()
		if arriba.dot(Vector3.UP) > 0.8:   # el esqueleto de Godot tiene Y hacia arriba: se endereza
			arriba = Vector3.UP
		adelante = arriba.cross((bd - bi).normalized()).normalized()
		derecha = adelante.cross(arriba).normalized()
		if idx["cabeza_fin"] >= 0 and idx["dedos_i"] >= 0:
			var alto := sk.get_bone_global_rest(idx["cabeza_fin"]).origin.distance_to(sk.get_bone_global_rest(idx["dedos_i"]).origin)
			escala = maxf(alto / 1.65, 0.01)
	else:
		push_warning("gestos_3d: no encuentro los huesos del esqueleto Mixamo")
	gestos_def = GESTOS.duplicate(true)
	for g in gestos_def:
		peso[g] = 0.0
		objetivo[g] = 0.0
		rapidez[g] = 4.0
	listo = true


# Añade (o sustituye) un gesto mientras el juego está en marcha.
func registrar(nombre: String, datos: Dictionary) -> void:
	if not listo:
		preparar()
	gestos_def[nombre] = datos
	if not peso.has(nombre):
		peso[nombre] = 0.0
		objetivo[nombre] = 0.0
		rapidez[nombre] = 4.0


# Convierte (adelante, arriba, derecha) del personaje a dirección del esqueleto, y al revés.
func dir(v: Vector3) -> Vector3:
	return (adelante * v.x + arriba * v.y + derecha * v.z).normalized()


func comp(d: Vector3) -> Vector3:
	return Vector3(d.dot(adelante), d.dot(arriba), d.dot(derecha))


func _buscar(sk: Skeleton3D, nombres: Array) -> int:
	for i in sk.get_bone_count():
		var n: String = sk.get_bone_name(i)
		for s in nombres:
			if n == s or n.ends_with(":" + s) or n.ends_with("_" + s):
				return i
	return -1


# Activa un gesto (peso 1) o lo quita (peso 0) con una transición en segundos.
func poner(gesto: String, p := 1.0, transicion := 0.25) -> void:
	if not listo:
		preparar()
	if not gestos_def.has(gesto):
		return
	objetivo[gesto] = clampf(p, 0.0, 1.0)
	rapidez[gesto] = 1.0 / maxf(transicion, 0.01)


func quitar(gesto: String, transicion := 0.25) -> void:
	poner(gesto, 0.0, transicion)


func quitar_todos(transicion := 0.25, menos: Array = []) -> void:
	for g in gestos_def:
		if not (g in menos):
			quitar(g, transicion)


func _process(delta: float) -> void:
	tiempo += delta
	for g in objetivo:
		peso[g] = move_toward(peso[g], objetivo[g], rapidez[g] * delta)


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if not listo:
		preparar()
	for hueso in ORDEN:
		if hueso == "cadera":
			_mover_cadera(sk)
			continue
		if hueso == "pecho" and respirar > 0.0:
			_girar(sk, "pecho", derecha, sin(tiempo * 1.9) * deg_to_rad(1.6) * respirar)
		for g in gestos_def:
			var w: float = peso.get(g, 0.0)
			if w <= 0.001:
				continue
			if gestos_def[g].has(hueso):
				var dato: Array = gestos_def[g][hueso]
				_apuntar(sk, hueso, dato[0], deg_to_rad(dato[1]) * w)
			if gestos_def[g].has("+" + hueso):          # giro que se SUMA al del clip (no lo sustituye)
				var mas: Array = gestos_def[g]["+" + hueso]
				var ang: float = deg_to_rad(mas[1]) * w
				if mas.size() > 2:                        # [eje, grados, ciclos por segundo, fase]: va y viene
					ang *= sin(tiempo * TAU * mas[2] + (mas[3] if mas.size() > 3 else 0.0))
				_girar(sk, hueso, dir(mas[0]), ang)
		if hueso == "cabeza" and respirar > 0.0:
			_girar(sk, "cabeza", derecha, -sin(tiempo * 1.9) * deg_to_rad(1.0) * respirar)
	if al_terminar.is_valid():
		al_terminar.call(sk)


# Baja o adelanta la cadera según los gestos activos (para agacharse o caer en zancada).
func _mover_cadera(sk: Skeleton3D) -> void:
	var i: int = idx.get("cadera", -1)
	if i < 0:
		return
	var desp := Vector3.ZERO
	for g in gestos_def:
		var w: float = peso.get(g, 0.0)
		if w > 0.001 and gestos_def[g].has("_cadera"):
			desp += gestos_def[g]["_cadera"] * w
	if desp == Vector3.ZERO:
		return
	var pose := sk.get_bone_global_pose(i)
	pose.origin += (adelante * desp.x + arriba * desp.y + derecha * desp.z) * escala
	sk.set_bone_global_pose(i, pose)


# Gira un hueso para que su dirección se acerque a "d" como mucho "max_ang" radianes.
func _apuntar(sk: Skeleton3D, hueso: String, d: Vector3, max_ang: float) -> void:
	var i: int = idx.get(hueso, -1)
	var j: int = idx.get(HIJO.get(hueso, ""), -1)
	if i < 0 or j < 0:
		return
	var pose := sk.get_bone_global_pose(i)
	var dir := sk.get_bone_global_pose(j).origin - pose.origin
	if dir.length() < 0.00001:
		return
	dir = dir.normalized()
	var meta := (adelante * d.x + arriba * d.y + derecha * d.z).normalized()
	var ang := minf(dir.angle_to(meta), max_ang)
	var eje := dir.cross(meta)
	if ang < 0.0005 or eje.length() < 0.00001:
		return
	pose.basis = Basis(eje.normalized(), ang) * pose.basis
	sk.set_bone_global_pose(i, pose)


func _girar(sk: Skeleton3D, hueso: String, eje: Vector3, ang: float) -> void:
	var i: int = idx.get(hueso, -1)
	if i < 0:
		return
	var pose := sk.get_bone_global_pose(i)
	pose.basis = Basis(eje.normalized(), ang) * pose.basis
	sk.set_bone_global_pose(i, pose)
