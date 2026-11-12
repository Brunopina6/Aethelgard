extends "res://enemigos/v12_comun/enemigo_v12_3d.gd"
# Guardián de piedra, «el Centinela del Anillo» (V12, fase C): la estatua de templo que despierta. Modelo, textura,
# esqueleto y clips de enemigos/guardian_piedra/fuente/crear_guardian_piedra.py (Blender 5.2.3, obra propia). La
# interfaz con el combate está en enemigos/v12_comun/enemigo_v12_3d.gd. Personalidad «jefe»: el golpe devastador
# avisado es cargar() (el mandoble en alto) y golpe_fuerte() (lo clava delante con las lascas).
# Clips (30 fps; bucle: reposo, caminar, correr, carga_espera): reposo 3 s, caminar 1,2, correr 0,8, entrada 2,2,
# ataque 1,5 (IMPACTO 0,8), carga 1,0, carga_espera 1,6, golpe_fuerte 1,9 (IMPACTO 0,92; desde la carga 0,5),
# recibir_golpe 0,7, victoria 2,0 y derrota 2,4. Los instantes son los de guardian_piedra_clips.json (la prueba lo mira).

const RUTA_MODELO := "res://enemigos/guardian_piedra/guardian_piedra.glb"
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
}


func _configurar() -> void:
	ruta_glb = RUTA_MODELO
	texturas = {"alto": "res://enemigos/guardian_piedra/guardian_piedra.webp",
		"bajo": "res://enemigos/guardian_piedra/guardian_piedra_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.5
	eventos_clip = EVENTOS


func punto_magia() -> Vector3:
	return hueso_mundo("arma", Vector3(0, 1.45, 0))      # la punta del mandoble
