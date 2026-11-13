extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# Gólem de ámbar, «el Guardián del Nido» (V12, fase C): terrones de resina fósil con insectos dentro, atados con ramas
# petrificadas y con el nido a la espalda. Modelo, textura, esqueleto y clips de
# enemigos/golem_ambar/fuente/crear_golem_ambar.py (Blender 5.2.3, obra propia). Interfaz: enemigo_v12_3d.gd.
# Personalidad «bruto»: «levanta los puños» es cargar() y el Pisotón a todos es golpe_fuerte(); si se interrumpe la
# carga (V11), aturdido(). Clips (30 fps; bucle: reposo, caminar, correr, carga_espera, aturdido): reposo 2,4 s,
# caminar 1,4, correr 0,9, entrada 2,0, ataque 1,3 (IMPACTO 0,7), carga 0,9, carga_espera 1,4, golpe_fuerte 1,6
# (IMPACTO 0,75; desde la carga 0,45; la onda de polvo se abre ahí), recibir_golpe 0,6, aturdido 1,6, victoria 1,8 y
# derrota 2,2. Los instantes son los de golem_ambar_clips.json (la prueba lo mira).
#
# V2 (12/11, especialista de enemigos y combate; combate_golem.gd): golem_ambar_v2.glb lleva la misma malla y los
# mismos clips, y dos nuevos del mismo guion con «v2» (golem_ambar_v2_clips.json): lanzar 1,5 s (agarra el terrón del
# nido 0,3; lo SUELTA en 0,75: su «impacto», cuando sale el terrón; el daño cae al llegar) y recibir_golpe_fuerte 1,0.
# Si el v2 no está, carga el de siempre (lanzar cae en el ataque). Ganchos nuevos: lanzar(cb), punto_mano(),
# golpe_pesado (lo pone el combate antes de herida()).

const RUTA_MODELO := "res://enemigos/golem_ambar/golem_ambar.glb"
const RUTA_MODELO_V2 := "res://enemigos/golem_ambar/golem_ambar_v2.glb"
const ALTURA := 2.24                       # con el nido (Érebo lo lee)
const CENTRO := Vector3(0.0, 1.25, 0.0)
const COLOR_BRILLO := Color(1.0, 0.72, 0.22)
const EVENTOS := {
	"entrada": {"despierta": 0.5, "golpe_suelo": 1.5},
	"ataque": {"impacto": 0.7},
	"carga": {"arriba": 0.9},
	"golpe_fuerte": {"impacto": 0.75, "carga": 0.45},
	"recibir_golpe": {"golpe": 0.0},
	"victoria": {"pecho": 0.5, "pecho2": 0.9, "aterriza": 1.45},
	"derrota": {"sentado": 0.8, "suelo": 1.5},
	# V2
	"lanzar": {"agarra": 0.3, "impacto": 0.75},
	"recibir_golpe_fuerte": {"golpe": 0.0},
}

var golpe_pesado := false


func _configurar() -> void:
	ruta_glb = RUTA_MODELO_V2 if ResourceLoader.exists(RUTA_MODELO_V2) else RUTA_MODELO
	texturas = {"alto": "res://enemigos/golem_ambar/golem_ambar.webp",
		"bajo": "res://enemigos/golem_ambar/golem_ambar_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.8
	eventos_clip = EVENTOS
	ambar_superficie = true


func es_v2() -> bool:
	return tiene("lanzar")


func _clip_de(ataque: String) -> String:
	if ataque == "lanzar":
		return "lanzar" if tiene("lanzar") else "ataque"
	return super._clip_de(ataque)


# El Terrón de ámbar: «al_soltar» se llama una vez, cuando el terrón sale de la mano (el combate lo vuela).
func lanzar(al_soltar := Callable()) -> void:
	await atacar("lanzar", al_soltar)


func punto_mano() -> Vector3:
	return hueso_mundo("mano.R", Vector3(0, 0.25, 0))


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
	elif _aturdido and tiene("aturdido"):
		_reproducir("aturdido", 0.2)
	else:
		reposo()
