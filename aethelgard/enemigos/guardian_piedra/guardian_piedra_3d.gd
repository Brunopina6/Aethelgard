extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# Guardián de piedra, «el Centinela del Anillo» (V12, fase C): la estatua de templo que despierta. Modelo, textura,
# esqueleto y clips de enemigos/guardian_piedra/fuente/crear_guardian_piedra.py (Blender 5.2.3, obra propia). La
# interfaz con el combate está en enemigos/v12_comun/enemigo_v12_3d.gd. Personalidad «jefe»: el golpe devastador
# avisado es cargar() (el mandoble en alto) y golpe_fuerte() (lo clava delante con las lascas).
# Clips (30 fps; bucle: reposo, caminar, correr, carga_espera): reposo 3 s, caminar 1,2, correr 0,8, entrada 2,2,
# ataque 1,5 (IMPACTO 0,8), carga 1,0, carga_espera 1,6, golpe_fuerte 1,9 (IMPACTO 0,92; desde la carga 0,5),
# recibir_golpe 0,7, victoria 2,0 y derrota 2,4. Los instantes son los de guardian_piedra_clips.json (la prueba lo mira).
#
# V2 (12/11, especialista de enemigos y combate; combate_centinela.gd): guardian_piedra_v2.glb lleva los mismos clips
# (la misma malla y los mismos instantes) y cinco nuevos, del mismo guion con «v2» (guardian_piedra_v2_clips.json):
#   barrido 1,8 (preparación 0-0,6 con «tension» 0,35; IMPACTO 0,85), guardia 0,9 («escudo» 0,55) + guardia_espera
#   2,0 (bucle), aturdido 1,6 (bucle) y recibir_golpe_fuerte 1,1.
# Si el v2 no está, carga el de siempre y los ganchos nuevos caen en lo que hay (ataque, recibir_golpe).
# Ganchos nuevos: barrido(cb), guardia(), fin_guardia(), golpe_pesado (lo pone el combate antes de herida()).

const RUTA_MODELO := "res://enemigos/guardian_piedra/guardian_piedra.glb"
const RUTA_MODELO_V2 := "res://enemigos/guardian_piedra/guardian_piedra_v2.glb"
const ALTURA := 2.34                       # del suelo a lo alto del yelmo (Érebo lo lee: invocacion_erebo.gd)
const CENTRO := Vector3(0.0, 1.35, 0.0)    # el pecho (efectos y números de daño)
const COLOR_BRILLO := Color(0.30, 0.95, 0.85)
const EVENTOS := {
	"entrada": {"despierta": 0.6, "golpe_suelo": 1.75},
	"ataque": {"impacto": 0.8},
	"carga": {"en_alto": 1.0},
	"golpe_fuerte": {"impacto": 0.92, "carga": 0.5},
	"recibir_golpe": {"golpe": 0.0},
	"victoria": {"clavar": 0.8},
	"derrota": {"rodilla": 0.7, "suelo": 2.2},
	# V2
	"barrido": {"tension": 0.35, "impacto": 0.85},
	"guardia": {"escudo": 0.55},
	"recibir_golpe_fuerte": {"golpe": 0.0},
}

var golpe_pesado := false                  # el combate lo pone si el golpe que llega es grande (combate_centinela.gd)
var _en_guardia := false


func _configurar() -> void:
	ruta_glb = RUTA_MODELO_V2 if ResourceLoader.exists(RUTA_MODELO_V2) else RUTA_MODELO
	texturas = {"alto": "res://enemigos/guardian_piedra/guardian_piedra.webp",
		"bajo": "res://enemigos/guardian_piedra/guardian_piedra_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.5
	eventos_clip = EVENTOS


func _ready() -> void:
	super._ready()
	if anim != null and anim.has_animation("guardia_espera"):
		anim.get_animation("guardia_espera").loop_mode = Animation.LOOP_LINEAR


func punto_magia() -> Vector3:
	return hueso_mundo("arma", Vector3(0, 1.45, 0))      # la punta del mandoble


# El anillo (para los efectos del escudo y del aviso): su centro en el mundo.
func punto_anillo() -> Vector3:
	return hueso_mundo("aureola", Vector3.ZERO)


func es_v2() -> bool:
	return tiene("barrido")


func _clip_de(ataque: String) -> String:
	if ataque == "barrido":
		return "barrido" if tiene("barrido") else "ataque"
	return super._clip_de(ataque)


func barrido(al_golpear := Callable()) -> void:
	_en_guardia = false
	await atacar("barrido", al_golpear)


# El anillo baja delante del pecho (su escudo) y se queda (bucle) hasta fin_guardia() o un ataque.
func guardia() -> void:
	if _muerta or anim == null or _rendido:
		return
	_en_guardia = true
	_cargando = false
	if not _reproducir("guardia", 0.15):
		return
	await _esperar_clip("guardia")
	if _en_guardia and not _muerta and _clip == "guardia":
		_reproducir("guardia_espera", 0.1)


func fin_guardia() -> void:
	if not _en_guardia:
		return
	_en_guardia = false
	if not _muerta and (_clip == "guardia" or _clip == "guardia_espera"):
		reposo()


func en_guardia() -> bool:
	return _en_guardia


func reposo() -> void:
	_en_guardia = false
	super.reposo()


func aturdido() -> void:
	_en_guardia = false
	super.aturdido()


func recibir_golpe() -> void:
	var fuerte := golpe_pesado and tiene("recibir_golpe_fuerte")
	golpe_pesado = false
	if _muerta or anim == null or _atacando or _entrando or _rendido or _en_fase:
		return
	var clip := "recibir_golpe_fuerte" if fuerte else "recibir_golpe"
	_reproducir(clip, MEZCLA_GOLPE)
	await _esperar_clip(clip)
	if _muerta or _clip != clip:
		return
	if _cargando:
		_reproducir("carga_espera", 0.2)
	elif _en_guardia and tiene("guardia_espera"):
		_reproducir("guardia_espera", 0.2)
	elif _aturdido and tiene("aturdido"):
		_reproducir("aturdido", 0.2)
	else:
		reposo()
