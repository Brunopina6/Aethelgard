extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# e01 · Peón de Linde (V12, bestiario de producción, 13/11/2026): hostigador común de Pastos Verdes y los caminos.
# Barro seco, máscara de mojón con la cruz de deslinde, chaqueta de fibras salvia y dos estacas de agrimensor. Modelo,
# atlas, esqueleto (rig base del bestiario: raiz + 22 deformantes, arma.R/arma.L, pecho_fx y luz) y clips de
# enemigos/peon_linde/fuente/crear_peon_linde.py (Blender 5.2.3, obra propia). Interfaz: enemigo_v12_3d.gd.
# Combate: combate_peon.gd (APAGADO tras «enemigos_v12»). Informe: docs/memory/agents/combate_v12_bestiario.md.
#
# Clips (30 fps; los instantes, los de peon_linde_clips.json, que la prueba compara): reposo 2,0 (bucle), alerta 0,6,
# entrada 1,0, caminar 1,0 · correr 0,7 · lateral_izq/der 1,0 (bucles), girar_izq/der 0,5, recibir_golpe 0,33,
# recibir_golpe_espalda 0,33, aturdido 0,8 (bucle), derrota 1,4 (rodillas 0,45, suelo 1,05), desaparecer 0,6,
# ataque = Piquete cruzado 1,27 (IMPACTO 0,62), lanzar = Estaca de aviso 1,7 (SUELTA 0,85: el combate vuela la estaca y
# el daño cae al llegar; «recoge» 1,25: saca otra de la espalda), zancada = Zancada de lindero 1,9 (desde la carga 0,9;
# IMPACTO 1,0), carga 0,9 y carga_espera 1,2 (bucle; el turno de aviso de la Zancada), retroceso 0,67 (paso 0,33).
# Ganchos nuevos: piquete(cb), lanzar(cb), zancada(cb), retroceder(), alerta(), lateral(dir), girar(dir),
# punto_mano(), golpe_pesado (lo pone el combate antes de herida()).

const RUTA_MODELO := "res://enemigos/peon_linde/peon_linde.glb"
const ALTURA := 1.65
const CENTRO := Vector3(0.0, 1.0, 0.0)
const COLOR_BRILLO := Color(1.0, 0.70, 0.32)
const EVENTOS := {
	"entrada": {"despierta": 0.3, "golpe_suelo": 0.6},
	"alerta": {"alerta": 0.12},
	"ataque": {"aviso": 0.0, "impacto": 0.62},
	"lanzar": {"aviso": 0.0, "impacto": 0.85, "recoge": 1.25},
	"zancada": {"aviso": 0.0, "carga": 0.9, "impacto": 1.0, "pisada": 1.0},
	"carga": {"arriba": 0.9},
	"retroceso": {"paso": 0.33},
	"recibir_golpe": {"golpe": 0.0},
	"recibir_golpe_espalda": {"golpe": 0.0},
	"derrota": {"rodillas": 0.45, "suelo": 1.05},
	"desaparecer": {"hundido": 0.6},
}
const BUCLES_PROPIOS := ["lateral_izq", "lateral_der"]
# V2 (13/11, segunda pasada de arte; guion con «v2»): proporciones compactas, formas redondeadas, atlas de 1024 con más
# detalle y mapa de normales del relieve pintado. Mismos huesos, clips e instantes que la v1, que se conserva al lado.
# Se usa la v2 si está; con Engine.set_meta("bestiario_v1", true) (comparar), la v1.
const RUTA_MODELO_V2 := "res://enemigos/peon_linde/peon_linde_v2.glb"
const NORMALES_V2 := "res://enemigos/peon_linde/peon_linde_v2_normal.webp"
const FUERZA_NORMALES := 0.8

var golpe_pesado := false
var version := 1


func _configurar() -> void:
	var v1_forzada: bool = Engine.get_meta("bestiario_v1", false) or "bestiario_v1" in OS.get_cmdline_user_args()
	if v1_forzada:
		ruta_modelo = RUTA_MODELO
	elif ruta_modelo == "" and ResourceLoader.exists(RUTA_MODELO_V2):
		ruta_modelo = RUTA_MODELO_V2
	version = 2 if ruta_modelo.ends_with("_v2.glb") else 1
	ruta_glb = RUTA_MODELO
	var base := "res://enemigos/peon_linde/peon_linde" + ("_v2" if version == 2 else "")
	texturas = {"alto": base + ".webp", "bajo": base + "_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.5
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


func _clip_de(ataque: String) -> String:
	match ataque:
		"piquete", "atacar_hacha", "preparar_golpe":
			return "ataque"
		"zancada", "golpe_fuerte":
			return "zancada" if tiene("zancada") else "ataque"
		"lanzar":
			return "lanzar" if tiene("lanzar") else "ataque"
	return super._clip_de(ataque)


func tiempo_impacto(ataque: String) -> float:
	var clip := _clip_de(ataque)
	var t := instante(clip, "impacto")
	if clip == "zancada" and _cargando:
		t -= maxf(instante(clip, "carga"), 0.0)
	return t


# A1 · Piquete cruzado: el impacto, una vez, al abrir las estacas.
func piquete(al_golpear := Callable()) -> void:
	await atacar("ataque", al_golpear)


# A2 · Estaca de aviso: «al_soltar» se llama una vez, cuando la estaca sale de la mano (el combate la vuela).
func lanzar(al_soltar := Callable()) -> void:
	await atacar("lanzar", al_soltar)


# A3 · Zancada de lindero: si estaba en la carga (su turno de aviso), empieza desde la rodilla alzada.
func zancada(al_golpear := Callable()) -> void:
	var desde := maxf(instante("zancada", "carga"), 0.0) if _cargando else 0.0
	await atacar("zancada", al_golpear, desde)


func golpe_fuerte(al_golpear := Callable()) -> void:
	await zancada(al_golpear)


func retroceder() -> void:
	if _muerta or anim == null:
		return
	_reproducir("retroceso", 0.1)
	await _esperar_clip("retroceso")
	if not _muerta and _clip == "retroceso":
		reposo()


func alerta() -> void:
	if _muerta or anim == null or _atacando or _cargando:
		return
	_reproducir("alerta", 0.1)
	await _esperar_clip("alerta")
	if not _muerta and _clip == "alerta":
		reposo()


# Paso lateral en bucle (dir < 0: a su izquierda). El combate mueve al actor.
func lateral(dir: float) -> void:
	if _muerta or anim == null:
		return
	_reproducir("lateral_izq" if dir < 0.0 else "lateral_der", 0.12)


func girar(dir: float) -> void:
	if _muerta or anim == null or _atacando:
		return
	_reproducir("girar_izq" if dir < 0.0 else "girar_der", 0.1)


func punto_mano() -> Vector3:
	return hueso_mundo("mano.R", Vector3(0, 0.06, 0))


func recibir_golpe() -> void:
	var fuerte := golpe_pesado
	golpe_pesado = false
	if _muerta or anim == null or _atacando or _entrando or _rendido or _en_fase:
		return
	_reproducir("recibir_golpe", MEZCLA_GOLPE)
	if fuerte and anim != null:
		anim.speed_scale = 0.8                    # un golpe grande: la sacudida dura algo más
	await _esperar_clip("recibir_golpe")
	if _muerta or _clip != "recibir_golpe":
		return
	if _cargando:
		_reproducir("carga_espera", 0.2)
	elif _aturdido and tiene("aturdido"):
		_reproducir("aturdido", 0.2)
	else:
		reposo()
