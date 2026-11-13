extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# e02 · Velador de Corteza (V12, bestiario de producción, 13/11/2026): defensor común del Gran Bosque Verde. Cuerpo
# leñoso con musgo turquesa, máscara oval de corcho, escudo de anillos (la rodaja de un tronco) en el antebrazo
# izquierdo, maza de poda con hoja de podadera y alero de corteza en el hombro. Modelo, atlas, esqueleto (rig base del
# bestiario, el del Peón de Linde a 1,95 m y más ancho) y clips de enemigos/velador_corteza/fuente/crear_velador_corteza.py
# (Blender 5.2.3, obra propia). Interfaz: enemigo_v12_3d.gd. Combate: combate_velador.gd (APAGADO tras «enemigos_v12»).
#
# Clips (30 fps; instantes de velador_corteza_clips.json): reposo 2,0 y guardia_espera 1,2 (bucles; la guardia es su
# reposo en el combate), alerta 0,6, entrada 1,0, caminar/correr/lateral_* (bucles), girar_*, recibir_golpe(_espalda)
# 0,33, aturdido 0,8 (bucle), derrota 1,4 (cae como un árbol talado: suelo 1,05), desaparecer 0,6, ataque = Mazazo de
# poda 1,8 (IMPACTO 0,95), empuje = Empuje de anillos 1,5 (IMPACTO 0,70), raiz = Raíz de umbral 2,2 (desde la carga 1,1;
# IMPACTO 1,15), carga 1,1 y carga_espera 1,2 (el turno de aviso de la Raíz).

const RUTA_MODELO := "res://enemigos/velador_corteza/velador_corteza.glb"
const ALTURA := 1.95
const CENTRO := Vector3(0.0, 1.2, 0.0)
const COLOR_BRILLO := Color(0.40, 0.95, 0.85)
const EVENTOS := {
	"entrada": {"despierta": 0.3, "golpe_suelo": 0.7},
	"alerta": {"alerta": 0.15},
	"ataque": {"aviso": 0.0, "impacto": 0.95},
	"empuje": {"aviso": 0.0, "impacto": 0.70, "pisada": 0.70},
	"raiz": {"aviso": 0.0, "clava": 0.5, "carga": 1.1, "impacto": 1.15},
	"carga": {"clava": 0.5, "arriba": 1.1},
	"recibir_golpe": {"golpe": 0.0},
	"recibir_golpe_espalda": {"golpe": 0.0},
	"derrota": {"cruje": 0.4, "suelo": 1.05},
	"desaparecer": {"hundido": 0.6},
}
const BUCLES_PROPIOS := ["lateral_izq", "lateral_der", "guardia_espera"]

# V2 (13/11, segunda pasada de arte; guion con «v2»): proporciones compactas, placas de corteza curvadas, tocón con la
# máscara de corcho grande, escudo con canto y bollón, maza nudosa; atlas de 1024 más detallado y mapa de normales.
# Mismos huesos, clips e instantes. Se usa la v2 si está; con Engine.set_meta("bestiario_v1", true), la v1.
const RUTA_MODELO_V2 := "res://enemigos/velador_corteza/velador_corteza_v2.glb"
const NORMALES_V2 := "res://enemigos/velador_corteza/velador_corteza_v2_normal.webp"
const FUERZA_NORMALES := 0.9

var golpe_pesado := false
var en_guardia := false                      # el combate la pone: su reposo es la guardia de anillos
var version := 1


func _configurar() -> void:
	if Engine.get_meta("bestiario_v1", false) or "bestiario_v1" in OS.get_cmdline_user_args():
		ruta_modelo = RUTA_MODELO
	elif ruta_modelo == "" and ResourceLoader.exists(RUTA_MODELO_V2):
		ruta_modelo = RUTA_MODELO_V2
	version = 2 if ruta_modelo.ends_with("_v2.glb") else 1
	ruta_glb = RUTA_MODELO
	var base := "res://enemigos/velador_corteza/velador_corteza" + ("_v2" if version == 2 else "")
	texturas = {"alto": base + ".webp", "bajo": base + "_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.4
	eventos_clip = EVENTOS


# La v2 añade el mapa de normales a los materiales del atlas (no en la calidad baja).
func _materiales() -> void:
	super._materiales()
	if version != 2 or calidad_usada == "bajo" or not ResourceLoader.exists(NORMALES_V2):
		return
	var nm: Texture2D = load(NORMALES_V2)
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var mat := m3.get_surface_override_material(i) as StandardMaterial3D
			if mat != null and mat.albedo_texture != null:
				mat.normal_enabled = true
				mat.normal_texture = nm
				mat.normal_scale = FUERZA_NORMALES


func _ready() -> void:
	super()
	if anim == null:
		return
	for n in BUCLES_PROPIOS:
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR


func reposo() -> void:
	if en_guardia and not _muerta and anim != null and not _rendido and tiene("guardia_espera"):
		_cargando = false
		_aturdido = false
		_reproducir("guardia_espera", MEZCLA_REPOSO)
		return
	super.reposo()


func guardia(si: bool) -> void:
	en_guardia = si
	if not _atacando and not _cargando and not _aturdido and not _muerta and _clip in ["reposo", "guardia_espera"]:
		reposo()


func _clip_de(ataque: String) -> String:
	match ataque:
		"mazazo", "atacar_hacha", "preparar_golpe":
			return "ataque"
		"raiz", "golpe_fuerte":
			return "raiz" if tiene("raiz") else "ataque"
		"empuje":
			return "empuje" if tiene("empuje") else "ataque"
	return super._clip_de(ataque)


func tiempo_impacto(ataque: String) -> float:
	var clip := _clip_de(ataque)
	var t := instante(clip, "impacto")
	if clip == "raiz" and _cargando:
		t -= maxf(instante(clip, "carga"), 0.0)
	return t


func mazazo(al_golpear := Callable()) -> void:
	await atacar("ataque", al_golpear)


func empuje(al_golpear := Callable()) -> void:
	await atacar("empuje", al_golpear)


# A3 · Raíz de umbral: si estaba en la carga (su turno de aviso), empieza desde la maza ya clavada.
func raiz(al_golpear := Callable()) -> void:
	var desde := maxf(instante("raiz", "carga"), 0.0) if _cargando else 0.0
	await atacar("raiz", al_golpear, desde)


func golpe_fuerte(al_golpear := Callable()) -> void:
	await raiz(al_golpear)


func punto_mano() -> Vector3:
	return hueso_mundo("mano.L", Vector3(0, 0.1, 0))


func recibir_golpe() -> void:
	var fuerte := golpe_pesado
	golpe_pesado = false
	if _muerta or anim == null or _atacando or _entrando or _rendido or _en_fase:
		return
	_reproducir("recibir_golpe", MEZCLA_GOLPE)
	if fuerte:
		anim.speed_scale = 0.8
	await _esperar_clip("recibir_golpe")
	if _muerta or _clip != "recibir_golpe":
		return
	if _cargando:
		_reproducir("carga_espera", 0.2)
	elif _aturdido and tiene("aturdido"):
		_reproducir("aturdido", 0.2)
	else:
		reposo()
