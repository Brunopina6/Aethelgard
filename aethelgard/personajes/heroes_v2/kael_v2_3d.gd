extends "res://kael_3d.gd"
# Kael v2 (fase B, V12; detrás del interruptor de heroes_v2.gd, APAGADO por defecto).
#
# Hereda TODO de kael_3d.gd (el combate y la exploración le llaman igual) y solo cambia:
#   - el modelo: personajes/heroes_v2/kael/kael_v2.glb (la misma malla y texturas de Meshy, sin tocar, más la cara
#     expresiva «cara_v2», el hueso «arma_d» y los clips de la biblioteca común: biblioteca_clips.py);
#   - los movimientos que antes eran poses por código: guardia, ataque (salto con corte, impacto a 0,64 s como
#     T_AGACHAR + T_SALTO + T_CORTE), magia (lanzamiento a 0,85 s, como antes), golpe recibido, derribo y KO,
#     levantarse, victoria; y en la exploración: reposo, hablar, asentir, interactuar, saltar y girar;
#   - el sable va en el hueso «arma_d» (en cada clip está donde se diseñó: nada de calibrar al empezar);
#   - expresiones de la cara (heroe_v2_ayudante.gd) y materiales mejorados.
# Si falta el GLB, carga el FBX original y se comporta exactamente como kael_3d.gd.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const Ayudante := preload("res://personajes/heroes_v2/heroe_v2_ayudante.gd")
# Instantes del contrato (kael_v2_clips.json)
const IMPACTO_ATAQUE := 0.64          # = T_AGACHAR + T_SALTO + T_CORTE de kael_3d.gd (el combate mueve el salto con ellos)
const LANZA_MAGIA := 0.85             # el mismo instante que esperaba kael_3d.gd

var v2: Node = null                   # heroe_v2_ayudante.gd (si se cargó el GLB nuevo)
var es_v2 := false
var _i_arma := -1
var _exploracion := false


func _cargar_modelo() -> void:
	var glb: String = HeroesV2.GLB["Kael"]
	if ResourceLoader.exists(glb) and (ruta_modelo in HeroesV2.ORIGINALES["Kael"] or ruta_modelo == ""):
		ruta_modelo = glb
	rutas_extra = HeroesV2.ORIGINALES["Kael"]          # respaldo: el modelo original
	super._cargar_modelo()


func _ready() -> void:
	super._ready()
	if skel == null or not es_v2:
		return
	for i in skel.get_bone_count():
		if skel.get_bone_name(i) == "arma_d":
			_i_arma = i
	v2 = Ayudante.new()
	v2.name = "HeroeV2"
	add_child(v2)
	v2.preparar(self, "Kael")


func _mapear_animaciones() -> void:
	es_v2 = anim.has_animation("guardia") and anim.has_animation("ataque")
	if not es_v2:
		super._mapear_animaciones()
		return
	nombres = {"Idle": "reposo" if _exploracion else "guardia", "Walking": "andar", "Andar_normal": "andar",
		"Running": "correr", "Hit": "recibir_golpe", "Death": "derribo", "Casting": "magia_lanzar"}
	for k in ["reposo", "guardia", "andar", "correr", "andar_pesado", "derrota", "reposo_original"]:
		if anim.has_animation(k):
			anim.get_animation(k).loop_mode = Animation.LOOP_LINEAR
	for k in ["andar", "correr", "andar_pesado"]:
		if anim.has_animation(k):
			_quitar_avance(k)


# En la exploración su reposo es el de siempre (sable al hombro); en combate, la guardia.
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


# ---------------------------------------------------------------- sable en el hueso arma_d
func _calibrar() -> void:
	if not es_v2:
		super._calibrar()
		return
	# «k_hombro» (andar y correr con el sable al hombro): la postura del brazo en el primer instante del reposo
	var antes := String(anim.current_animation)
	var pos := anim.current_animation_position
	anim.play("reposo")
	anim.seek(0.0, true)
	var g = gestos
	var brazo := {}
	for par in [["brazo_d", "antebrazo_d"], ["antebrazo_d", "mano_d"], ["mano_d", "dedo_d"]]:
		var a := skel.get_bone_global_pose(g.idx[par[0]]).origin
		var c := skel.get_bone_global_pose(g.idx[par[1]]).origin
		brazo[par[0]] = [g.comp((c - a).normalized()), 180]
	g.registrar("k_hombro", brazo)
	if antes != "":
		anim.play(antes)
		anim.seek(pos, true)


func _actualizar_sable(sk: Skeleton3D) -> void:
	if not es_v2 or _i_arma < 0:
		super._actualizar_sable(sk)
		return
	if sable != null:
		sable.global_transform = sk.global_transform * sk.get_bone_global_pose(_i_arma)


# ---------------------------------------------------------------- combate
func reposo() -> void:
	super.reposo()
	if v2 != null and not _muerta:
		v2.poner_expresion("normal" if _exploracion else "decidido")   # 13/11: en combate, mirada firme


func herida() -> void:
	if not es_v2:
		await super.herida()
		return
	if _muerta:
		return
	gestos.quitar_todos(0.1, ["k_cansado"])
	var d: float = v2.reproducir("recibir_golpe", 0.06)
	v2.poner_expresion("dolor", 0.65)
	await get_tree().create_timer(d).timeout
	if not _muerta and anim.assigned_animation == "recibir_golpe":
		reposo()


func lanzar_magia() -> void:
	if not es_v2:
		await super.lanzar_magia()
		return
	gestos.quitar_todos(0.15)
	v2.reproducir("magia_lanzar", 0.15)
	v2.poner_expresion("entrecerrados", 0.7)
	await get_tree().create_timer(LANZA_MAGIA).timeout
	v2.poner_expresion("grito", 0.5)


func ataque_salto(impacto: Callable) -> void:
	if not es_v2:
		await super.ataque_salto(impacto)
		return
	if _muerta:
		return
	gestos.quitar_todos(0.1)
	v2.reproducir("ataque", 0.12)
	v2.poner_expresion("grito", 1.0)
	await get_tree().create_timer(IMPACTO_ATAQUE).timeout
	if impacto.is_valid():
		impacto.call()
	await get_tree().create_timer(0.6).timeout
	if not _muerta:
		reposo()


func victoria() -> void:
	if not es_v2:
		super.victoria()
		return
	if _muerta:
		return
	cansada(false)
	gestos.quitar_todos(0.2)
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)          # se gira hacia la cámara
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
	var d: float = v2.reproducir("levantarse", 0.2)
	v2.poner_expresion("entrecerrados", d)
	await get_tree().create_timer(d).timeout
	if not _muerta and anim.assigned_animation == "levantarse":
		reposo()


# ---------------------------------------------------------------- exploración y conversación (API nueva)
# Un gesto de conversación (o ninguno), con la expresión del ánimo de la frase: alegre, broma, sorpresa, enfado,
# decidido, dolor, triste o cansado. Devuelve el clip elegido.
func hablar(animo := "") -> String:
	return v2.hablar(animo) if v2 != null else ""


func expresion(nombre: String, dur := 0.0) -> void:
	if v2 != null:
		v2.poner_expresion(nombre, dur)


# Un clip suelto del contrato (saltar, interactuar, girar, asentir…) y vuelta al reposo. Devuelve su duración.
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
