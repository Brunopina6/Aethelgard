extends "res://maga_3d.gd"
# Grimfang, el goblin (modelo de Meshy con esqueleto Mixamo). Sustituye al Hombre de Hollín (orco).
#
# Meshy le puso a las animaciones sus nombres en inglés. Al cargar el modelo se RENOMBRAN dentro
# de Godot (en su AnimationLibrary), así el resto del juego las pide siempre por el mismo nombre:
#   Walking              -> Andar
#   Running              -> Correr
#   Left_Slash           -> Atacar         doble tajo con la mano derecha (golpes a 0,78 s y 1,40 s)
#   Heavy_Hammer_Swing   -> Golpe_fuerte   golpe a dos manos por encima de la cabeza (golpe a 1,55 s)
#   Face_Punch_Reaction  -> Herido
#   Reposo               -> se crea aquí: la guardia del primer fotograma de "Atacar"
# No trae animación de muerte: cae de espaldas por código.
#
# El hacha es la que llevaba el Hombre de Hollín. Pon su archivo en RUTA_HACHA. Si lo dejas vacío,
# se busca en todo el proyecto un modelo con "hacha" o "axe" en el nombre. Si no hay ninguno, se
# dibuja un hacha provisional por código.
# Convención del modelo del hacha: el mango a lo largo de +Y (empuñadura abajo), el filo hacia +X.
# Si el tuyo viene girado, corrige GIRO_HACHA (grados) hasta que quede bien en la mano.

const RUTA_HACHA := "res://hacha.obj"          # el hacha del Hombre de Hollín (Abyssal Eclipse Reaver, reducida a 4.800 triángulos)
const LARGO_HACHA := 0.75                      # largo del hacha en metros (el goblin mide 1,7)
const AGARRE := 0.3                            # dónde la agarra: 0 = punta del mango, 1 = cabeza
const GIRO_HACHA := Vector3.ZERO               # corrección de giro del modelo del hacha, en grados
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6) # los enemigos miran a la derecha (hacia los héroes)

const RENOMBRAR := {
	"walking": "Andar",
	"running": "Correr",
	"left_slash": "Atacar",
	"heavy_hammer": "Golpe_fuerte",
	"face_punch": "Herido",
}
const GOLPES_ATACAR := [0.78, 1.40]            # segundos en los que el hacha toca al héroe
const FIN_ATACAR := 1.8                         # después de esto vuelve a la guardia
const GOLPE_FUERTE := 1.55
const FIN_GOLPE_FUERTE := 1.8

var hacha: Node3D
var _i_mano := -1
var _i_indice := -1
var _i_menique := -1
var _i_medio := -1


func _init() -> void:
	ruta_modelo = "res://goblin.fbx"
	rutas_extra = ["res://Meshy_AI_Grimfang_Goblin_20261103_animated_mixamo_All_animation.fbx", "res://goblin.glb"]
	usa_vara = false        # lleva su hacha, no el cetro de maga_3d.gd (si no, se queda colgando)


func _ready() -> void:
	super._ready()
	if skel == null:
		return
	mirar(FRENTE_ENEMIGO, 0.0)
	_crear_hacha()


func mirar_frente(dur := 0.25) -> void:
	mirar(FRENTE_ENEMIGO, dur)


# ---------------------------------------------------------------- animaciones

func _mapear_animaciones() -> void:
	var lib: AnimationLibrary = anim.get_animation_library("")
	if lib == null:
		return
	for n in lib.get_animation_list():
		var b := String(n).to_lower()
		for clave in RENOMBRAR:
			if clave in b and not lib.has_animation(RENOMBRAR[clave]):
				lib.rename_animation(n, RENOMBRAR[clave])
				break
	for n in ["Andar", "Correr", "Atacar", "Golpe_fuerte", "Herido"]:
		if lib.has_animation(n):
			nombres[n] = n
			_quitar_avance(n)
	if lib.has_animation("Atacar") and not lib.has_animation("Reposo"):
		lib.add_animation("Reposo", _pose_de("Atacar", 0.0))
	if lib.has_animation("Reposo"):
		nombres["Idle"] = "Reposo"
		nombres["Reposo"] = "Reposo"
	if nombres.has("Andar"):
		nombres["Walking"] = "Andar"
	if nombres.has("Correr"):
		nombres["Running"] = "Correr"
	for n in ["Reposo", "Andar", "Correr"]:
		if lib.has_animation(n):
			lib.get_animation(n).loop_mode = Animation.LOOP_LINEAR


# Una animación quieta de 1 segundo con la pose de "origen" en el instante "t".
func _pose_de(origen: String, t: float) -> Animation:
	var a := anim.get_animation(origen)
	var p := Animation.new()
	p.length = 1.0
	for i in a.get_track_count():
		var tipo := a.track_get_type(i)
		if tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_SCALE_3D:
			continue
		var j := p.add_track(tipo)
		p.track_set_path(j, a.track_get_path(i))
		var v
		match tipo:
			Animation.TYPE_POSITION_3D:
				v = a.position_track_interpolate(i, t)
			Animation.TYPE_ROTATION_3D:
				v = a.rotation_track_interpolate(i, t)
			_:
				v = a.scale_track_interpolate(i, t)
		p.track_insert_key(j, 0.0, v)
	return p


# Deja la animación en el sitio: la cadera no avanza (solo sube y baja). El combate mueve al goblin.
func _quitar_avance(nombre_real: String) -> void:
	var a := anim.get_animation(nombre_real)
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(a.track_get_path(t)).ends_with("Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n == 0:
			continue
		var p0: Vector3 = a.track_get_key_value(t, 0)
		for k in n:
			var p: Vector3 = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, Vector3(p0.x, p.y, p0.z))


# ---------------------------------------------------------------- hacha

func _hueso(fin: String) -> int:
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		if n.ends_with("_" + fin) or n.ends_with(":" + fin) or n == fin:
			return i
	return -1


func _crear_hacha() -> void:
	_i_mano = _hueso("RightHand")
	_i_indice = _hueso("RightHandIndex1")
	_i_menique = _hueso("RightHandPinky1")
	_i_medio = _hueso("RightHandMiddle1")
	if _i_mano < 0 or _i_indice < 0 or _i_menique < 0 or _i_medio < 0:
		push_warning("goblin_3d: no encuentro los huesos de la mano derecha")
		return
	hacha = Node3D.new()
	hacha.name = "Hacha"
	skel.add_child(hacha)
	var largo: float = LARGO_HACHA * gestos.escala
	var modelo := Node3D.new()
	modelo.rotation_degrees = GIRO_HACHA
	modelo.position = Vector3(0, -AGARRE * largo, 0)       # la mano queda en el punto de agarre
	hacha.add_child(modelo)
	var ruta := RUTA_HACHA if RUTA_HACHA != "" else _buscar_hacha("res://")
	if ruta != "" and ResourceLoader.exists(ruta):
		_cargar_hacha(modelo, ruta, largo)
	else:
		_hacha_provisional(modelo, largo)
	gestos.al_terminar = _actualizar_hacha


# Busca un modelo con "hacha" o "axe" en el nombre (también funciona en el juego exportado).
func _buscar_hacha(carpeta: String) -> String:
	for f in ResourceLoader.list_directory(carpeta):
		if f.ends_with("/"):
			if f.begins_with(".") or f == "addons/":
				continue
			var r := _buscar_hacha(carpeta + f)
			if r != "":
				return r
			continue
		var b := f.to_lower()
		if ("hacha" in b or "axe" in b) and b.get_extension() in ["obj", "glb", "gltf", "fbx", "tscn", "res", "mesh"]:
			return carpeta + f
	return ""


# Carga el hacha (malla .obj/.mesh o escena .glb/.fbx/.tscn) y la escala a LARGO_HACHA.
func _cargar_hacha(modelo: Node3D, ruta: String, largo: float) -> void:
	var r = load(ruta)
	var nodo: Node3D
	if r is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = r
		nodo = mi
		var base := ruta.get_basename()                    # texturas con el mismo nombre, si las hay
		var mat := StandardMaterial3D.new()
		for ext in ["_color.jpg", "_color.png"]:
			if ResourceLoader.exists(base + ext):
				mat.albedo_texture = load(base + ext)
		if ResourceLoader.exists(base + "_normal.png"):
			mat.normal_enabled = true
			mat.normal_texture = load(base + "_normal.png")
		if ResourceLoader.exists(base + "_metal.png"):
			mat.metallic = 1.0
			mat.metallic_texture = load(base + "_metal.png")
		if ResourceLoader.exists(base + "_rugosidad.png"):
			mat.roughness = 1.0
			mat.roughness_texture = load(base + "_rugosidad.png")
		if mat.albedo_texture != null:
			mi.material_override = mat
	elif r is PackedScene:
		nodo = r.instantiate()
	else:
		_hacha_provisional(modelo, largo)
		return
	modelo.add_child(nodo)
	# tamaño: el lado más largo del modelo pasa a medir "largo"
	var caja := _caja(nodo)
	var lado := maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
	if lado > 0.0001:
		nodo.scale = Vector3.ONE * (largo / lado)
		nodo.position = -Vector3(caja.get_center().x, caja.position.y, caja.get_center().z) * (largo / lado)


func _caja(n: Node) -> AABB:
	var caja := AABB()
	var hay := false
	for m in [n] + n.find_children("*", "VisualInstance3D", true, false):
		if m is VisualInstance3D:
			var tr: Transform3D = Transform3D.IDENTITY if m == n else (n as Node3D).global_transform.affine_inverse() * m.global_transform
			var c: AABB = tr * m.get_aabb()
			caja = c if not hay else caja.merge(c)
			hay = true
	return caja


# Hacha provisional: mango de madera a lo largo de +Y y cabeza de hierro con el filo hacia +X.
func _hacha_provisional(modelo: Node3D, largo: float) -> void:
	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.36, 0.22, 0.12)
	madera.roughness = 0.9
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.42, 0.42, 0.45)
	hierro.metallic = 0.8
	hierro.roughness = 0.4
	var mango := CylinderMesh.new()
	mango.top_radius = 0.022 * largo
	mango.bottom_radius = 0.028 * largo
	mango.height = largo
	var mm := MeshInstance3D.new()
	mm.mesh = mango
	mm.material_override = madera
	mm.position = Vector3(0, largo * 0.5, 0)
	modelo.add_child(mm)
	var cabeza := PrismMesh.new()                         # cuña: estrecha junto al mango, ancha en el filo
	cabeza.size = Vector3(0.36, 0.3, 0.05) * largo
	var mc := MeshInstance3D.new()
	mc.mesh = cabeza
	mc.material_override = hierro
	mc.rotation_degrees = Vector3(0, 0, -90)
	mc.position = Vector3(0.17 * largo, largo * 0.86, 0)
	modelo.add_child(mc)
	var filo := BoxMesh.new()
	filo.size = Vector3(0.025, 0.32, 0.055) * largo
	var mf := MeshInstance3D.new()
	mf.mesh = filo
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color(0.82, 0.84, 0.88)
	brillo.metallic = 1.0
	brillo.roughness = 0.2
	mf.material_override = brillo
	mf.position = Vector3(0.33 * largo, largo * 0.86, 0)
	modelo.add_child(mf)


# Pone el hacha en el puño cada fotograma: el mango sigue la línea de los nudillos (del meñique
# al índice) y el filo mira hacia donde apuntan los nudillos, como al empuñar un martillo.
func _actualizar_hacha(sk: Skeleton3D) -> void:
	if hacha == null:
		return
	var mano := sk.get_bone_global_pose(_i_mano).origin
	var indice := sk.get_bone_global_pose(_i_indice).origin
	var menique := sk.get_bone_global_pose(_i_menique).origin
	var medio := sk.get_bone_global_pose(_i_medio).origin
	var mango := (indice - menique).normalized()
	var filo := medio - mano
	filo = (filo - mango * filo.dot(mango)).normalized()
	var puno := mano.lerp(medio, 0.75)
	hacha.global_transform = sk.global_transform * Transform3D(Basis(filo, mango, filo.cross(mango)), puno)


# ---------------------------------------------------------------- movimientos para el combate

func reposo() -> void:
	play("Idle", 0.25)
	gestos.respirar = 1.0
	gestos.quitar_todos(0.3, ["cansada"])
	cansada(_cansada)


func andar() -> void:
	_base_movimiento()
	play("Andar")


func correr() -> void:
	_base_movimiento()
	play("Correr")


func herida() -> void:
	if _muerta:
		return
	if not nombres.has("Herido"):
		super.herida()
		return
	anim.speed_scale = 1.6
	play("Herido", 0.08)
	await get_tree().create_timer(1.1).timeout
	if not _muerta and anim.current_animation == "Herido":
		anim.speed_scale = 1.0
		reposo()


# Ataque normal: doble tajo. "impacto" se llama en cada golpe (2 veces); si solo quieres un
# número de daño, haz el daño en la primera llamada y un temblor pequeño en la segunda.
func atacar_hacha(impacto: Callable) -> void:
	await _ataque("Atacar", GOLPES_ATACAR, FIN_ATACAR, impacto)


# Ataque fuerte a dos manos (para cuando el enemigo tiene rabia o carga un turno).
func golpe_fuerte(impacto: Callable) -> void:
	await _ataque("Golpe_fuerte", [GOLPE_FUERTE], FIN_GOLPE_FUERTE, impacto)


func _ataque(nombre: String, golpes: Array, fin: float, impacto: Callable) -> void:
	if _muerta or not nombres.has(nombre):
		return
	gestos.respirar = 0.0
	gestos.quitar_todos(0.1)
	anim.speed_scale = 1.0
	play(nombre, 0.12)
	var antes := 0.0
	for t in golpes:
		await get_tree().create_timer(t - antes).timeout
		antes = t
		if impacto.is_valid():
			impacto.call()
	await get_tree().create_timer(fin - antes).timeout
	if not _muerta:
		reposo()


# Cae de espaldas (hacia la izquierda de la pantalla, alejándose de los héroes).
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
	_tw_caida.tween_property(caida, "rotation_degrees:z", 84.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw_caida.tween_property(caida, "position", Vector3(0.88, 0.1, 0.0), 0.55)
