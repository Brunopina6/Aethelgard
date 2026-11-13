extends "res://garon_3d.gd"
# Garon v2 (fase B, V12; detrás del interruptor de heroes_v2.gd, APAGADO por defecto).
#
# Hereda TODO de garon_3d.gd (Juicio y Giro de captura, la Guardia que cubre, Embuir, la capa, los pasos de doble
# espada) y cambia el modelo (personajes/heroes_v2/garon/garon_v2.glb: la misma malla y texturas, más los huesos
# «arma_d» y «arma_i» y los clips de la biblioteca común) y lo que antes eran gestos por código: reposo de veterano
# (plantado, hombros atrás), guardia protectora con las espadas cruzadas, golpe recibido (apenas se mueve: armadura con
# peso), derribo y KO, levantarse y victoria (cruza las espadas, las baja y asiente). Garon no usa magia (D-037).
# Sin cara expresiva: su yelmo es cerrado (su expresión es el cuerpo). Las espadas van en arma_d y arma_i.
# Si falta el GLB, carga el FBX original y se comporta exactamente como garon_3d.gd.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const Ayudante := preload("res://personajes/heroes_v2/heroe_v2_ayudante.gd")

var v2: Node = null
var es_v2 := false
var _i_arma := {"Right": -1, "Left": -1}
var _exploracion := false


func _cargar_modelo() -> void:
	var glb: String = HeroesV2.GLB["Garon"]
	if ResourceLoader.exists(glb) and (ruta_modelo in HeroesV2.ORIGINALES["Garon"] or ruta_modelo == ""):
		ruta_modelo = glb
	rutas_extra = HeroesV2.ORIGINALES["Garon"]
	super._cargar_modelo()


func _ready() -> void:
	super._ready()
	if skel == null or not es_v2:
		return
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		if n == "arma_d":
			_i_arma["Right"] = i
		elif n == "arma_i":
			_i_arma["Left"] = i
	v2 = Ayudante.new()
	v2.name = "HeroeV2"
	add_child(v2)
	v2.preparar(self, "Garon")


func _mapear_animaciones() -> void:
	es_v2 = anim.has_animation("guardia") and anim.has_animation("juicio")
	if not es_v2:
		super._mapear_animaciones()
		return
	var lib: AnimationLibrary = anim.get_animation_library("")
	if ResourceLoader.exists(RUTA_ESPADAS):                 # pasos de doble espada (el combate los usa al acercarse)
		var extra: AnimationLibrary = load(RUTA_ESPADAS)
		for n in extra.get_animation_list():
			if not lib.has_animation(n):
				lib.add_animation(n, extra.get_animation(n))
	var quieto := "reposo" if _exploracion else "guardia"
	nombres = {"Guardia": "guardia", "Reposo": quieto, "Idle": quieto, "Walking": "andar", "Running": "correr",
		"Andar": "andar", "Correr": "correr", "Juicio": "juicio", "Giro": "giro", "Morir": "derribo", "Paseo": "paseo"}
	for n in ["AvanzarDoble", "RetrocederDoble"]:
		if lib.has_animation(n):
			nombres[n] = n
			lib.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in ["reposo", "guardia", "andar", "correr", "paseo", "derrota"]:
		if lib.has_animation(n):
			lib.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in ["andar", "correr", "juicio", "giro", "paseo"]:
		if lib.has_animation(n):
			_quitar_avance(n)


func activar_esperas(si := true) -> bool:
	_exploracion = si
	if es_v2:
		nombres["Idle"] = "reposo" if si else "guardia"
		nombres["Reposo"] = nombres["Idle"]
		if not _muerta and marcha_actual() == "":
			reposo()
	if es_v2 and si:   # (Redmi, 13/11) las esperas de exploración (animaciones/esperas/*.res) son del esqueleto de los
		# originales: en el v2 (y el v3, que hereda de aquí) tumbaban al héroe a los pocos segundos de quedarse quieto
		return false
	return super.activar_esperas(si)


# Las espadas en sus huesos (en cada clip, donde se diseñaron)
func _colocar_espada(sk: Skeleton3D, nodo: Node3D, lado: String) -> void:
	if not es_v2 or nodo == null or _i_arma[lado] < 0:
		super._colocar_espada(sk, nodo, lado)
		return
	nodo.global_transform = sk.global_transform * sk.get_bone_global_pose(_i_arma[lado])


# ---------------------------------------------------------------- combate
func reposo() -> void:
	super.reposo()
	if es_v2:
		gestos.respirar = 0.0                # el clip ya respira


func herida() -> void:
	if not es_v2:
		await super.herida()
		return
	if _muerta:
		return
	var d: float = v2.reproducir("recibir_golpe", 0.06)
	await get_tree().create_timer(d).timeout
	if not _muerta and anim.assigned_animation == "recibir_golpe":
		reposo()


func victoria() -> void:
	if not es_v2:
		super.victoria()
		return
	if _muerta:
		return
	cansada(false)
	cubriendo = false
	gestos.quitar_todos(0.2)
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)
	v2.reproducir("victoria", 0.25)
	_viento(0.6)


func morir() -> void:
	if not es_v2:
		super.morir()
		return
	if _muerta:
		return
	_muerta = true
	cubriendo = false
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3)
	var d: float = v2.reproducir("derribo", 0.12)
	_viento(0.3)
	await get_tree().create_timer(d).timeout
	if _muerta and anim.assigned_animation == "derribo":
		anim.play("derrota", 0.3)


func revivir() -> void:
	if not es_v2:
		super.revivir()
		return
	if not _muerta:
		return
	_muerta = false
	var d: float = v2.reproducir("levantarse", 0.2)
	await get_tree().create_timer(d).timeout
	if not _muerta and anim.assigned_animation == "levantarse":
		reposo()


# ---------------------------------------------------------------- exploración y conversación (API nueva)
func hablar(animo := "") -> String:
	return v2.hablar(animo) if v2 != null else ""


func expresion(_nombre: String, _dur := 0.0) -> void:
	pass                                     # yelmo cerrado: sin cara


func gesto(clip: String) -> float:
	if v2 == null or _muerta:
		return 0.0
	var d: float = v2.reproducir(clip, 0.15)
	if d > 0.0:
		get_tree().create_timer(d).timeout.connect(func():
			if is_instance_valid(self) and anim.assigned_animation == clip and not _muerta:
				reposo(), CONNECT_ONE_SHOT)
	return d


func saltar() -> float:
	return gesto("saltar")


func interactuar() -> float:
	return gesto("interactuar")
