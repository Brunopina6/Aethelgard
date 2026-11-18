extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# meshy_e01 · Custodio de Porcelana (nombre de diseño; V12, fase 9, PILOTO, 14/11/2026). Defensor pesado de armadura
# clara en placas, casco, manos grandes, ojos rojos y una llave en el pecho; sin arma. Malla y texturas: el FBX de Meshy
# del usuario (Meshy_AI_Original_fantasy_game_enemy_Custodio_de_20261108_texture_fbx.zip, sin rig), con esqueleto bípedo
# ligero, pesos rígidos por placas y clips hechos con Blender 5.2.3 por guion (enemigos/meshy_e01/fuente/p1_rig.py y
# p2_clips.py). Interfaz: enemigo_v12_3d.gd. Combate: combate_meshy_e01.gd (APAGADO; interruptor propio «meshy_e01»).
#
# Clips del GLB (30 fps, nombres ASCII del paquete de diseño; instantes en meshy_e01_clips.json):
#   e01__idle 2,4 s (bucle) · e01__walk 1,2 s (bucle, en el sitio, 0,867 m/s) · e01__attack_prensa 2,4 s: e01_a1
#   «Prensa del Umbral»: aviso 0,00 · fija la dirección 0,65 · IMPACTO 0,90 (ventana activa [0,90, 1,10)) · recupera
#   hasta 2,40 y termina en la pose del reposo.
#   (14/11, noche) e01__attack_porton 2,7 s: e01_a2 «Avance del Portón»: aviso 0,00 · fija 0,75 · carrera [1,00, 1,45)
#   (en el sitio: el combate desplaza el nodo) · IMPACTO 1,30 · frena 1,45 · guardia 1,90 · reposo 2,70.
#   e01__hit 0,6 s (recibir un golpe) · e01__death 1,9 s (de rodillas y vencido sobre las manos; en el suelo a 1,30).
#   (15/11) e01__attack_sello 2,8 s: e01_a3 «Sello de Clausura»: separa las manos 0,00 · marca de cerradura 0,20
#   («aviso») · las manos a la llave del pecho 0,45 · centro fijo 0,80 («fija_direccion») · pecho y cabeza al sello 0,95 ·
#   IMPACTO 1,30 con las palmas extendidas (activo [1,30, 1,50)) · recupera desde 1,50 hasta 2,80. Raíz y pies quietos.
#   (18/11) Los cinco que faltaban de la lista del paquete (enemigos/meshy_e01/fuente/p2_clips.py, mismo método):
#   e01__alert 1,6 s (se yergue 0,22 y se pone en guardia baja 0,60; vuelve al reposo): su ENTRADA al empezar el combate.
#   e01__guard 2,0 s (bucle; antebrazos alzados delante del pecho): en lugar del reposo mientras está en Guardia.
#   e01__stagger 1,2 s (sacudida, paso atrás con el pie derecho, se recompone): con un golpe fuerte o una ruptura.
#   e01__turn_l / e01__turn_r 1,0 s (giro en dos pasos, en el sitio): en los giros grandes estando quieto (mirar).
# El combate pide los clips por los nombres del juego (reposo, caminar, correr, ataque): aquí se añaden como ALIAS del
# mismo recurso Animation (no son clips nuevos ni copias).
# Materiales: los del GLB (color, normal y metálico-rugosidad de Meshy a 1024 px), sin el atlas ni el brillo de la
# base: este modelo no tiene superficie «_brillo» (los ojos rojos están pintados en la textura).

const RUTA_MODELO := "res://enemigos/meshy_e01/meshy_e01.glb"
const RUTA_CLIPS := "res://enemigos/meshy_e01/meshy_e01_clips.json"
const ALTURA := 1.85
const CENTRO := Vector3(0.0, 1.05, 0.0)
const ALIAS := {"reposo": "e01__idle", "caminar": "e01__walk", "correr": "e01__walk", "ataque": "e01__attack_prensa",
	"prensa": "e01__attack_prensa", "porton": "e01__attack_porton", "sello": "e01__attack_sello", "recibir_golpe": "e01__hit",
	"derrota": "e01__death", "entrada": "e01__alert", "guardia": "e01__guard", "tambaleo": "e01__stagger",
	"girar_izq": "e01__turn_l", "girar_der": "e01__turn_r"}
const GIRO_MIN_GRADOS := 60.0            # (18/11) giros menores: el de siempre, sin pasos
const QUIETO := ["reposo", "guardia", "caminar", "correr", ""]

var golpe_pesado := false                # (18/11) lo pone el combate (combate_meshy_e01.vigilar) antes de herida()
var en_guardia := false                  # (18/11) mientras dure su Guardia, el reposo es el clip «guardia»
var _girando := ""                       # (18/11) el clip de giro en curso («girar_izq»/«girar_der»)
var _tras_giro := false                  # un reposo pedido durante el giro (se pone al acabarlo)
const EVENTOS := {
	"ataque": {"aviso": 0.0, "fija_direccion": 0.65, "impacto": 0.90, "fin_activo": 1.10},
	"e01__attack_prensa": {"aviso": 0.0, "fija_direccion": 0.65, "impacto": 0.90, "fin_activo": 1.10},
	"porton": {"aviso": 0.0, "fija_direccion": 0.75, "carrera": 1.0, "impacto": 1.30, "fin_activo": 1.45},
	"e01__attack_porton": {"aviso": 0.0, "fija_direccion": 0.75, "carrera": 1.0, "impacto": 1.30, "fin_activo": 1.45},
	"sello": {"aviso": 0.20, "fija_direccion": 0.80, "impacto": 1.30, "fin_activo": 1.50},
	"e01__attack_sello": {"aviso": 0.20, "fija_direccion": 0.80, "impacto": 1.30, "fin_activo": 1.50},
	"entrada": {"alerta": 0.22, "listo": 0.60},                     # (18/11) e01__alert
	"tambaleo": {"sacudida": 0.10, "paso_atras": 0.36, "recompone": 0.70},   # (18/11) e01__stagger
}


func _configurar() -> void:
	ruta_glb = RUTA_MODELO
	if ruta_modelo == "":
		ruta_modelo = RUTA_MODELO
	texturas = {"alto": "", "bajo": ""}
	eventos_clip = EVENTOS


# Tras instanciar el GLB: los nombres del juego como alias de los clips (misma Animation, biblioteca propia de este
# AnimationPlayer para no tocar la del recurso importado, que comparten todas las instancias).
func _cargar_modelo() -> void:
	super._cargar_modelo()
	var ap := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null or not ap.has_animation_library(""):
		return
	var lib: AnimationLibrary = ap.get_animation_library("").duplicate()
	for alias in ALIAS:
		var real: String = ALIAS[alias]
		if lib.has_animation(real) and not lib.has_animation(alias):
			lib.add_animation(alias, lib.get_animation(real))
	ap.remove_animation_library("")
	ap.add_animation_library("", lib)
	if lib.has_animation("guardia"):     # (18/11) bucle en el sitio, como el reposo
		lib.get_animation("guardia").loop_mode = Animation.LOOP_LINEAR


# Los materiales del GLB se quedan (la base pondría el atlas WebP de los enemigos hechos a mano).
func _materiales() -> void:
	calidad_usada = calidad_en_uso()


func _clip_de(ataque: String) -> String:
	match ataque:
		"prensa", "atacar_hacha", "preparar_golpe", "golpe_fuerte":
			return "ataque"
		"porton":
			return "porton"
		"sello":
			return "sello"
	return super._clip_de(ataque)


# e01_a1 · Prensa del Umbral: el clip con su impacto (al_golpear UNA vez, en 0,90 s); muerto a medias, no golpea.
func prensa(al_golpear := Callable()) -> void:
	await atacar("ataque", al_golpear)


func golpe_fuerte(al_golpear := Callable()) -> void:
	await prensa(al_golpear)


# e01_a2 · Avance del Portón: el clip con su impacto (al_golpear UNA vez, en 1,30 s); el combate lo desplaza en la carrera.
func porton(al_golpear := Callable()) -> void:
	await atacar("porton", al_golpear)


# e01_a3 · Sello de Clausura: el clip en su sitio con su impacto (al_golpear UNA vez, en 1,30 s); muerto a medias, nada.
func sello(al_golpear := Callable()) -> void:
	await atacar("sello", al_golpear)


# Con e01__death (14/11, noche), la derrota de la base (el clip, y el combate lo desvanece tras su «caida»). Sin él
# (un GLB antiguo): se para en la pose en que está y el combate lo desvanece.
func derrota() -> void:
	if tiene("derrota"):
		await super.derrota()
		return
	if _muerta:
		return
	_muerta = true
	_cargando = false
	if anim != null:
		anim.stop(true)
	_clip = ""
	_eventos.clear()
	clip_terminado.emit("derrota")


func punto_impacto() -> Vector3:
	return (hueso_mundo("mano.L") + hueso_mundo("mano.R")) * 0.5


# Clips reales del GLB (sin los alias), para pruebas e informes.
func clips_propios() -> PackedStringArray:
	var r := PackedStringArray()
	if anim == null:
		return r
	for n in anim.get_animation_list():
		if String(n).begins_with("e01__"):
			r.append(n)
	return r


# ================================================================= 18/11: guardia, tambaleo y giros (solo presentación)

# Guardia (combate_meshy_e01._guardia y turno): mientras dure, el reposo es el clip «guardia» (el combate sigue
# poniendo su tinte y «defendiendo»; aquí solo cambia la pose). Sin el clip (un GLB antiguo), el reposo de siempre.
func guardia(si: bool) -> void:
	en_guardia = si
	if _muerta or anim == null or _atacando or _entrando or _rendido:
		return
	if si and _clip in ["reposo", "guardia"]:
		reposo()
	elif not si and _clip == "guardia":
		reposo()


func reposo() -> void:
	if _girando != "" and not _muerta and _clip == _girando:
		_tras_giro = true                 # se pone al acabar el giro
		return
	if en_guardia and tiene("guardia") and not _muerta and not _rendido and anim != null:
		_cargando = false
		_aturdido = false
		if _clip != "guardia" or String(anim.current_animation) != "guardia":   # (ya en guardia: sin saltar a 0)
			_reproducir("guardia", MEZCLA_REPOSO)
		return
	super.reposo()


# Un golpe fuerte (≥ combate_meshy_e01.GOLPE_PESADO de su vida) o una ruptura (Quiebra): el tambaleo; si no, el golpe de siempre. No corta un
# ataque, la entrada ni la derrota (como recibir_golpe de la base). NO cambia reglas: el combate decide igual.
func recibir_golpe() -> void:
	var fuerte := golpe_pesado and tiene("tambaleo")
	golpe_pesado = false
	if not fuerte:
		await super.recibir_golpe()
		return
	if _muerta or anim == null or _atacando or _entrando or _rendido:
		return
	_girando = ""
	_reproducir("tambaleo", MEZCLA_GOLPE)
	await _esperar_clip("tambaleo")
	if _muerta or _clip != "tambaleo":
		return
	reposo()


# Andar o correr cortan el giro en pasos (el nodo termina de girar a su ritmo de siempre).
func andar() -> void:
	_cortar_giro()
	super.andar()


func correr() -> void:
	_cortar_giro()
	super.correr()


func _cortar_giro() -> void:
	if _girando == "":
		return
	var dir: Vector3 = get_meta("e01_giro_dir", Vector3.ZERO)
	var dur: float = get_meta("e01_giro_dur", 0.2)
	_girando = ""
	_tras_giro = false
	if dir != Vector3.ZERO:
		super.mirar(dir, dur)


# Giros grandes (≥ GIRO_MIN_GRADOS) estando quieto o al llegar andando: «girar_izq»/«girar_der» (en dos pasos) y el
# nodo gira durante el clip (su duración en vez de la pedida). Los pequeños, el de siempre. Positivo = a su izquierda.
func mirar(dir: Vector3, dur := 0.2) -> void:
	if pivote == null or dur <= 0.0 or _muerta or anim == null or _atacando or _entrando or _rendido \
			or not _clip in QUIETO:
		super.mirar(dir, dur)
		return
	var delta := wrapf(atan2(dir.x, dir.z) - _yaw0 - pivote.rotation.y, -PI, PI)
	var clip := "girar_izq" if delta > 0.0 else "girar_der"
	if absf(rad_to_deg(delta)) < GIRO_MIN_GRADOS or not tiene(clip):
		super.mirar(dir, dur)
		return
	set_meta("e01_giro_dir", dir)
	set_meta("e01_giro_dur", dur)
	super.mirar(dir, duracion(clip))
	_girar(clip)


func _girar(clip: String) -> void:
	_girando = clip
	_tras_giro = false
	_reproducir(clip, 0.15)
	await _esperar_clip(clip)
	if _girando != clip:
		return
	_girando = ""
	if _muerta or _clip != clip:
		return
	_tras_giro = false
	reposo()


func girando() -> String:
	return _girando
