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

const RUTA_MODELO := "res://enemigos/gorthor/gorthor.glb"
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
}


func _configurar() -> void:
	ruta_glb = RUTA_MODELO
	texturas = {"alto": "res://enemigos/gorthor/gorthor.webp", "bajo": "res://enemigos/gorthor/gorthor_bajo.webp"}
	color_brillo = COLOR_BRILLO
	energia_brillo = 1.3
	eventos_clip = EVENTOS


# Dónde muerde (efectos del mordisco) y el centro de la boca.
func boca() -> Vector3:
	return hueso_mundo("mandibula", Vector3(0, 0.5, 0))


func punto_magia() -> Vector3:
	return boca()
