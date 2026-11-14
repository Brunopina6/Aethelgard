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
# El combate pide los clips por los nombres del juego (reposo, caminar, correr, ataque): aquí se añaden como ALIAS del
# mismo recurso Animation (no son clips nuevos ni copias).
# Materiales: los del GLB (color, normal y metálico-rugosidad de Meshy a 1024 px), sin el atlas ni el brillo de la
# base: este modelo no tiene superficie «_brillo» (los ojos rojos están pintados en la textura).

const RUTA_MODELO := "res://enemigos/meshy_e01/meshy_e01.glb"
const RUTA_CLIPS := "res://enemigos/meshy_e01/meshy_e01_clips.json"
const ALTURA := 1.85
const CENTRO := Vector3(0.0, 1.05, 0.0)
const ALIAS := {"reposo": "e01__idle", "caminar": "e01__walk", "correr": "e01__walk", "ataque": "e01__attack_prensa",
	"prensa": "e01__attack_prensa", "porton": "e01__attack_porton", "recibir_golpe": "e01__hit", "derrota": "e01__death"}
const EVENTOS := {
	"ataque": {"aviso": 0.0, "fija_direccion": 0.65, "impacto": 0.90, "fin_activo": 1.10},
	"e01__attack_prensa": {"aviso": 0.0, "fija_direccion": 0.65, "impacto": 0.90, "fin_activo": 1.10},
	"porton": {"aviso": 0.0, "fija_direccion": 0.75, "carrera": 1.0, "impacto": 1.30, "fin_activo": 1.45},
	"e01__attack_porton": {"aviso": 0.0, "fija_direccion": 0.75, "carrera": 1.0, "impacto": 1.30, "fin_activo": 1.45},
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


# Los materiales del GLB se quedan (la base pondría el atlas WebP de los enemigos hechos a mano).
func _materiales() -> void:
	calidad_usada = calidad_en_uso()


func _clip_de(ataque: String) -> String:
	match ataque:
		"prensa", "atacar_hacha", "preparar_golpe", "golpe_fuerte":
			return "ataque"
		"porton":
			return "porton"
	return super._clip_de(ataque)


# e01_a1 · Prensa del Umbral: el clip con su impacto (al_golpear UNA vez, en 0,90 s); muerto a medias, no golpea.
func prensa(al_golpear := Callable()) -> void:
	await atacar("ataque", al_golpear)


func golpe_fuerte(al_golpear := Callable()) -> void:
	await prensa(al_golpear)


# e01_a2 · Avance del Portón: el clip con su impacto (al_golpear UNA vez, en 1,30 s); el combate lo desplaza en la carrera.
func porton(al_golpear := Callable()) -> void:
	await atacar("porton", al_golpear)


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
