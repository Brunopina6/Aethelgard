extends "res://maga_3d.gd"
# Lya v2 (fase B, V12; detrás del interruptor de heroes_v2.gd, APAGADO por defecto).
#
# Hereda TODO de maga_3d.gd y solo cambia el modelo (personajes/heroes_v2/lya/lya_v2.glb: la misma malla y texturas,
# más «cara_v2», el hueso «arma_d» y los clips de la biblioteca común) y los movimientos que antes eran gestos por
# código: reposo propio (sin los brazos abiertos del clip de Meshy), guardia, golpe con el cetro, magia (lanzamiento a
# 0,5 s, el mismo instante que esperaba maga_3d.gd), concentración y magia poderosa (nuevas, para cuando el combate
# las use), golpe recibido, derribo, levantarse y victoria. El cetro va en el hueso «arma_d».
# Si falta el GLB, carga el FBX original y se comporta exactamente como maga_3d.gd.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const Ayudante := preload("res://personajes/heroes_v2/heroe_v2_ayudante.gd")
const LANZA_MAGIA := 0.5               # magia_lanzar: «lanzamiento»
const LANZA_PODEROSA := 1.5            # magia_poderosa: «lanzamiento»
const PREPARA_GOLPE := 0.3             # ataque: fin de la preparación (13/11: el cetro atrás del todo, «prep»)
const IMPACTO_GOLPE := 0.45            # ataque: «impacto»

var v2: Node = null
var es_v2 := false
var _i_arma := -1
var _exploracion := false


func _cargar_modelo() -> void:
	var glb: String = HeroesV2.GLB["Lya"]
	if ResourceLoader.exists(glb) and (ruta_modelo in HeroesV2.ORIGINALES["Lya"] or ruta_modelo == ""):
		ruta_modelo = glb
	rutas_extra = HeroesV2.ORIGINALES["Lya"]
	super._cargar_modelo()


func _ready() -> void:
	clave_esperas = "Lya"                    # el script ya no es maga_3d.gd tal cual: sus esperas, a mano
	super._ready()
	if skel == null or not es_v2:
		return
	for i in skel.get_bone_count():
		if skel.get_bone_name(i) == "arma_d":
			_i_arma = i
	v2 = Ayudante.new()
	v2.name = "HeroeV2"
	add_child(v2)
	v2.preparar(self, "Lya")
	reposo()


func _mapear_animaciones() -> void:
	es_v2 = anim.has_animation("guardia") and anim.has_animation("magia_lanzar")
	if not es_v2:
		super._mapear_animaciones()
		return
	nombres = {"Idle": "reposo" if _exploracion else "guardia", "Walking": "andar", "Running": "correr",
		"Casting": "magia_lanzar"}
	for k in ["reposo", "guardia", "andar", "correr", "derrota", "magia_concentrar", "reposo_original"]:
		if anim.has_animation(k):
			anim.get_animation(k).loop_mode = Animation.LOOP_LINEAR


func activar_esperas(si := true) -> bool:
	_exploracion = si
	if es_v2:
		nombres["Idle"] = "reposo" if si else "guardia"
		if not _muerta and marcha_actual() == "":
			reposo()
	if es_v2 and si:   # (Redmi, 13/11) las esperas de exploración (animaciones/esperas/*.res) son del esqueleto de los
		# originales: en el v2 (y el v3, que hereda de aquí) tumbaban al héroe a los pocos segundos de quedarse quieto
		return false
	return super.activar_esperas(si)


# El cetro va en el hueso arma_d (en cada clip, donde se diseñó)
func _actualizar_vara(sk: Skeleton3D) -> void:
	if not es_v2 or _i_arma < 0:
		super._actualizar_vara(sk)
		return
	vara.global_transform = sk.global_transform * sk.get_bone_global_pose(_i_arma)


# ---------------------------------------------------------------- combate
func reposo() -> void:
	if not es_v2:
		super.reposo()
		return
	play("Idle", 0.25)
	gestos.respirar = 0.0                    # el clip ya respira
	gestos.quitar_todos(0.3, ["cansada"])
	cansada(_cansada)
	if v2 != null and not _muerta:
		v2.poner_expresion("normal")


func lanzar_magia() -> void:
	if not es_v2:
		await super.lanzar_magia()
		return
	gestos.quitar_todos(0.15)
	v2.reproducir("magia_lanzar", 0.15)
	v2.poner_expresion("decidido", 0.35)          # 13/11: concentrada y firme (no entrecerrada)
	await get_tree().create_timer(LANZA_MAGIA).timeout
	v2.poner_expresion("grito", 0.5)


func fin_magia() -> void:
	if not es_v2:
		super.fin_magia()
		return
	reposo()


# Nuevo: concentrarse (bucle) y la magia poderosa. Espera con «await» al instante en que sale el hechizo.
func concentrar() -> void:
	if es_v2 and not _muerta:
		v2.reproducir("magia_concentrar", 0.25)
		v2.poner_expresion("entrecerrados")


func magia_poderosa() -> void:
	if not es_v2:
		await lanzar_magia()
		return
	gestos.quitar_todos(0.15)
	v2.reproducir("magia_poderosa", 0.2)
	v2.poner_expresion("entrecerrados")
	await get_tree().create_timer(LANZA_PODEROSA).timeout
	v2.poner_expresion("grito", 0.8)


func preparar_golpe() -> void:
	if not es_v2:
		super.preparar_golpe()
		return
	v2.reproducir("ataque", 0.15)
	v2.poner_expresion("grito", 1.0)
	get_tree().create_timer(PREPARA_GOLPE).timeout.connect(func():
		if is_instance_valid(self) and anim.assigned_animation == "ataque" and anim.current_animation_position < 0.36:
			anim.speed_scale = 0.0, CONNECT_ONE_SHOT)       # espera en la preparación a que el combate diga «golpea»


func golpear() -> void:
	if not es_v2:
		super.golpear()
		return
	anim.speed_scale = 1.0
	if anim.assigned_animation == "ataque":
		anim.seek(IMPACTO_GOLPE - 0.08, true)


func fin_golpe() -> void:
	if not es_v2:
		super.fin_golpe()
		return
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(self) and not _muerta and anim.assigned_animation == "ataque":
			reposo(), CONNECT_ONE_SHOT)


func herida() -> void:
	if not es_v2:
		await super.herida()
		return
	if _muerta:
		return
	var d: float = v2.reproducir("recibir_golpe", 0.06)
	v2.poner_expresion("dolor", 0.65)
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
	gestos.quitar_todos(0.2)
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)
	v2.reproducir("victoria", 0.2)
	v2.poner_expresion("sonrisa")


func morir() -> void:
	if not es_v2:
		super.morir()
		return
	if _muerta:
		return
	_muerta = true
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3)
	var d: float = v2.reproducir("derribo", 0.12)
	v2.poner_expresion("dolor")
	await get_tree().create_timer(d).timeout
	if _muerta and anim.assigned_animation == "derribo":
		anim.play("derrota", 0.3)
		v2.poner_expresion("cerrados")


func revivir() -> void:
	if not es_v2:
		super.revivir()
		return
	if not _muerta:
		return
	_muerta = false
	anim.speed_scale = 1.0
	var d: float = v2.reproducir("levantarse", 0.2)
	v2.poner_expresion("entrecerrados", d)
	await get_tree().create_timer(d).timeout
	if not _muerta and anim.assigned_animation == "levantarse":
		reposo()


# ---------------------------------------------------------------- exploración y conversación (API nueva)
func hablar(animo := "") -> String:
	return v2.hablar(animo) if v2 != null else ""


func expresion(nombre: String, dur := 0.0) -> void:
	if v2 != null:
		v2.poner_expresion(nombre, dur)


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
