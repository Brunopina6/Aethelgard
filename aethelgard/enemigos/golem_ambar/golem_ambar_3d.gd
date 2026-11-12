extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# Gólem de ámbar, «el Guardián del Nido» (V12, fase C): terrones de resina fósil con insectos dentro, atados con ramas
# petrificadas y con el nido a la espalda. Modelo, textura, esqueleto y clips de
# enemigos/golem_ambar/fuente/crear_golem_ambar.py (Blender 5.2.3, obra propia). Interfaz: enemigo_v12_3d.gd.
# Personalidad «bruto»: «levanta los puños» es cargar() y el Pisotón a todos es golpe_fuerte(); si se interrumpe la
# carga (V11), aturdido(). Clips (30 fps; bucle: reposo, caminar, correr, carga_espera, aturdido): reposo 2,4 s,
# caminar 1,4, correr 0,9, entrada 2,0, ataque 1,3 (IMPACTO 0,7), carga 0,9, carga_espera 1,4, golpe_fuerte 1,6
# (IMPACTO 0,75; desde la carga 0,45; la onda de polvo se abre ahí), recibir_golpe 0,6, aturdido 1,6, victoria 1,8 y
# derrota 2,2. Los instantes son los de golem_ambar_clips.json (la prueba lo mira).

const RUTA_MODELO := "res://enemigos/golem_ambar/golem_ambar.glb"
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
}


func _configurar() -> void:
	ruta_glb = RUTA_MODELO
	texturas = {"alto": "res://enemigos/golem_ambar/golem_ambar.webp",
		"bajo": "res://enemigos/golem_ambar/golem_ambar_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.8
	eventos_clip = EVENTOS
	ambar_superficie = true
