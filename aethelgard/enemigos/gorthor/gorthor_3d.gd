extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# Gorthor el Devorador (V12, fase C): el caudillo del clan de los Grimfang crecido hasta monstruo, con vetas de brasa
# (resiste el Fuego, débil al Hielo) y la mandíbula prognata del Devorador. Modelo, textura, esqueleto y clips de
# enemigos/gorthor/fuente/crear_gorthor.py (Blender 5.2.3, obra propia). Interfaz: enemigo_v12_3d.gd, con todos sus
# ganchos: cargar(), golpe_fuerte(), fase2() (la Furia del Abismo: ruge y las vetas se encienden; el brillo sigue
# ×2,2 el resto del combate), devorar(cb) (impacto al cerrar las fauces), rendirse() (cae de rodillas; «rendido» en
# bucle), retirarse() (perdonado: se arrastra a gatas arrastrando la cuchilla) y, si le acaban, derrota_rendido.
# Clips (30 fps; bucle: reposo, caminar, correr, carga_espera, rendido, arrastrarse): reposo 2,6 s, caminar 1,4,
# correr 0,8, entrada 2,4 (ruge a 1,4), ataque 1,4 (IMPACTO 0,75), carga 1,0, carga_espera 1,4, golpe_fuerte 1,8
# (IMPACTO 0,95; desde la carga 0,5), devorar 1,9 (abre 0,6, IMPACTO 0,9, traga 1,5), fase2 2,2 (ruge 0,9),
# recibir_golpe 0,7, rendirse 1,5 (rodillas 0,8), rendido 2,4, arrastrarse 1,2, victoria 2,0, derrota 2,2 y
# derrota_rendido 1,6. Los instantes son los de gorthor_clips.json (la prueba lo mira).
#
# V2 (12/11, especialista de enemigos y combate; combate_gorthor.gd): gorthor_v2.glb lleva la misma malla y los mismos
# clips, y cinco nuevos del mismo guion con «v2» (gorthor_v2_clips.json): hoguera_carga 1,2 s (clava 0,8) +
# hoguera_espera 1,6 (bucle), hoguera 1,4 (IMPACTO 0,6, rugido 0,65), recibir_golpe_fuerte 1,1 y aturdido 1,6 (bucle).
# Si el v2 no está, carga el de siempre. Ganchos nuevos: preparar_hoguera(), hoguera(cb), golpe_pesado.

const RUTA_MODELO := "res://enemigos/gorthor/gorthor.glb"
const RUTA_MODELO_V2 := "res://enemigos/gorthor/gorthor_v2.glb"
const ALTURA := 2.74                       # a lo alto de la cabeza, sin los cuernos (Érebo lo lee)
const CENTRO := Vector3(0.0, 1.55, 0.0)
const COLOR_BRILLO := Color(1.0, 0.42, 0.10)
const EVENTOS := {
	"entrada": {"pecho": 0.9, "pecho2": 1.15, "rugido": 1.4},
	"ataque": {"impacto": 0.75},
	"carga": {"en_alto": 1.0},
	"golpe_fuerte": {"impacto": 0.95, "carga": 0.5},
	"devorar": {"abre": 0.6, "impacto": 0.9, "trago": 1.5},
	"fase2": {"pisoton": 0.5, "rugido": 0.9},
	"recibir_golpe": {"golpe": 0.0},
	"rendirse": {"suelta_arma": 0.55, "rodillas": 0.8},
	"rendido": {"mira": 1.2},
	"victoria": {"risa": 0.4},
	"derrota": {"suelo": 1.3},
	"derrota_rendido": {"suelo": 0.9},
	# V2
	"hoguera_carga": {"clava": 0.8},
	"hoguera": {"impacto": 0.6, "rugido": 0.65},
	"recibir_golpe_fuerte": {"golpe": 0.0},
}

var golpe_pesado := false
var _hoguera := false


func _configurar() -> void:
	ruta_glb = RUTA_MODELO_V2 if ResourceLoader.exists(RUTA_MODELO_V2) else RUTA_MODELO
	texturas = {"alto": "res://enemigos/gorthor/gorthor.webp", "bajo": "res://enemigos/gorthor/gorthor_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.3
	eventos_clip = EVENTOS


# Dónde muerde (efectos del mordisco) y el centro de la boca.
func boca() -> Vector3:
	return hueso_mundo("mandibula", Vector3(0, 0.5, 0))


func punto_magia() -> Vector3:
	return boca()


func _ready() -> void:
	super._ready()
	if anim != null and anim.has_animation("hoguera_espera"):
		anim.get_animation("hoguera_espera").loop_mode = Animation.LOOP_LINEAR


func es_v2() -> bool:
	return tiene("hoguera")


# El aviso de la Hoguera: clava la cuchilla al rojo y se queda apoyado en ella (bucle) hasta hoguera() o aturdido().
func preparar_hoguera() -> void:
	if _muerta or _rendido or anim == null or _atacando:
		return
	_hoguera = true
	if not _reproducir("hoguera_carga", 0.2):
		_hoguera = false
		cargar()
		return
	await _esperar_clip("hoguera_carga")
	if _hoguera and not _muerta and _clip == "hoguera_carga":
		_reproducir("hoguera_espera", 0.1)


# La Hoguera: arranca la cuchilla (IMPACTO: «al_estallar», una vez). Sin el clip, el golpe fuerte de siempre.
func hoguera(al_estallar := Callable()) -> void:
	_hoguera = false
	if not tiene("hoguera"):
		await golpe_fuerte(al_estallar)
		return
	await atacar("hoguera", al_estallar)


func aturdido() -> void:
	_hoguera = false
	super.aturdido()


func reposo() -> void:
	_hoguera = false
	super.reposo()


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
	if _hoguera and tiene("hoguera_espera"):
		_reproducir("hoguera_espera", 0.2)
	elif _cargando:
		_reproducir("carga_espera", 0.2)
	elif _aturdido and tiene("aturdido"):
		_reproducir("aturdido", 0.2)
	else:
		reposo()
