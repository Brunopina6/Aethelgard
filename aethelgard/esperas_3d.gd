extends Node
# Esperas de exploración: la personalidad de cada héroe cuando se queda quieto (09/11).
# Si el héroe lleva unos segundos en su reposo de exploración, hace una de sus esperas (clips hechos en Blender:
# animaciones/esperas/fuentes/esperas.py), nunca la misma dos veces seguidas, y vuelve a su reposo. Si se mueve, o
# empieza un diálogo, la espera se corta con un fundido corto.
#   Kael (impaciente y protector): vigila a los lados, comprueba la empuñadura del sable, mira el brazalete, golpea el
#     suelo con el pie.
#   Lya (curiosa y cálida): se agacha a mirar una flor, juega con el cetro, se recoloca el pelo.
#   Garon (sólido y veterano): rueda los hombros, estira la espalda, se apoya en las espadas.
# Cada clip empieza y acaba en la pose de reposo del juego (capturada con pruebas/herramientas/capturar_reposo.gd), así
# que el fundido de entrada y el de salida no saltan.
# La crea maga_3d.gd (activar_esperas) solo en la exploración: vista3d.gd para Kael y grupo_3d.gd para los
# acompañantes. El combate no la usa.

const RUTAS := {
	"Kael": "res://animaciones/esperas/kael.res",
	"Lya": "res://animaciones/esperas/lya.res",
	"Garon": "res://animaciones/esperas/garon.res",
}
const BIBLIOTECA := "esperas"
const PRIMERA := Vector2(6.0, 9.0)       # segundos quieto antes de la primera espera
const ENTRE := Vector2(10.0, 16.0)       # y entre una y la siguiente
const ENTRA := 0.45                      # fundido del reposo a la espera
const SALE := 0.5                        # y de la espera al reposo (empieza antes de que acabe el clip)
const CORTE := 0.2                       # si se mueve a mitad de una espera
const SEPARACION_GRUPO := 3.0            # segundos: dos héroes no empiezan una espera a la vez

const GRUPO := "esperas_heroes"           # todos los que tienen esperas: se avisan al empezar una

var heroe: Node3D                        # maga_3d.gd o una de sus hijas
var clips: Array = []                    # nombres de sus esperas (sin la biblioteca delante)
var actual := ""                         # la que está haciendo («» = ninguna)
var ultima := ""
var t_quieto := 0.0
var proxima := 0.0
var pausa := false                       # true: no empieza ninguna (p. ej. una escena que lo pide)
var _clip_antes := ""
var _gestos_antes := {}
var _azar := RandomNumberGenerator.new()
var _turno := 0.0                        # segundos que faltan para poder empezar (otro acaba de empezar la suya)


# Carga las esperas de «clave» (Kael, Lya o Garon) en el AnimationPlayer del héroe. false si no hay.
func preparar(h: Node3D, clave: String) -> bool:
	heroe = h
	name = "Esperas"
	_azar.randomize()
	add_to_group(GRUPO)
	if not RUTAS.has(clave) or not ResourceLoader.exists(RUTAS[clave]) or h.get("anim") == null:
		return false
	var ap: AnimationPlayer = h.anim
	if not ap.has_animation_library(BIBLIOTECA):
		var lib = load(RUTAS[clave])
		if not lib is AnimationLibrary:
			return false
		ap.add_animation_library(BIBLIOTECA, lib)
	clips = Array(ap.get_animation_library(BIBLIOTECA).get_animation_list()).map(func(n): return String(n))
	proxima = _azar.randf_range(PRIMERA.x, PRIMERA.y)
	return not clips.is_empty()


func _process(delta: float) -> void:
	if heroe == null or not is_instance_valid(heroe):
		return
	var ap: AnimationPlayer = heroe.anim
	_turno = maxf(0.0, _turno - delta)
	if actual != "":
		if String(ap.current_animation) != BIBLIOTECA + "/" + actual:
			_reponer(CORTE)                              # otro le ha puesto otra animación
		elif _en_dialogo():
			_terminar(CORTE)
		elif ap.current_animation_position >= ap.current_animation_length - SALE:
			_terminar(SALE)
		return
	if not _quieto():
		t_quieto = 0.0
		return
	t_quieto += delta
	if t_quieto >= proxima and _turno <= 0.0:
		_empezar()


# En su reposo de exploración, vivo, sin andar y fuera de los diálogos.
func _quieto() -> bool:
	if pausa or heroe.get("_muerta") or heroe.marcha_actual() != "" or _en_dialogo():
		return false
	var ap: AnimationPlayer = heroe.anim
	if ap.speed_scale <= 0.0:
		return false
	var c := String(ap.current_animation)
	return c != "" and (c == String(heroe.nombres.get("Idle", "")) or c == "Calma")


func _en_dialogo() -> bool:
	var dg = heroe.get_node_or_null("/root/Dialogic")
	return dg != null and dg.get("current_timeline") != null


func _empezar(nombre := "") -> void:
	if nombre == "":
		var opciones := clips.filter(func(c): return c != ultima)
		if opciones.is_empty():
			opciones = clips
		nombre = opciones[_azar.randi() % opciones.size()]
	var ap: AnimationPlayer = heroe.anim
	_clip_antes = String(ap.current_animation)
	# los gestos que estuvieran puestos (los brazos relajados de Lya): el clip ya los lleva y vuelven al acabar
	_gestos_antes.clear()
	var g = heroe.gestos
	for k in g.objetivo:
		if g.objetivo[k] > 0.001 and not k in ["cansada", "k_cansado"]:
			_gestos_antes[k] = g.objetivo[k]
			g.quitar(k, ENTRA)
	actual = nombre
	ap.play(BIBLIOTECA + "/" + nombre, ENTRA)
	ap.speed_scale = 1.0
	get_tree().call_group(GRUPO, "_otro_empieza", self)
	if heroe.has_method("espera_empieza"):
		heroe.espera_empieza()


# Vuelve a su reposo con un fundido de «fundido» segundos.
func _terminar(fundido: float) -> void:
	var ap: AnimationPlayer = heroe.anim
	var vuelta := _clip_antes if ap.has_animation(_clip_antes) else String(heroe.nombres.get("Idle", ""))
	_reponer(fundido)
	if vuelta != "":
		ap.play(vuelta, fundido)


# Se mueve (o le ponen otra animación): la espera se deja sin poner el reposo; quien la corta pone lo suyo.
func cortar() -> void:
	if actual != "":
		_reponer(CORTE)
	t_quieto = 0.0


func _reponer(fundido: float) -> void:
	for k in _gestos_antes:
		heroe.gestos.poner(k, _gestos_antes[k], fundido)
	_gestos_antes.clear()
	_olvidar()
	if heroe.has_method("espera_termina"):
		heroe.espera_termina(fundido)


func _olvidar() -> void:
	if actual != "":
		ultima = actual
	actual = ""
	t_quieto = 0.0
	proxima = _azar.randf_range(ENTRE.x, ENTRE.y)


# Para las pruebas y las capturas: hace ya esa espera (o una al azar).
func forzar(nombre := "") -> void:
	if actual != "":
		_terminar(0.0)
	_empezar(nombre)


# Para las pruebas: como si nadie del grupo hubiera hecho una espera hace poco.
func olvidar_turno() -> void:
	_turno = 0.0


func _otro_empieza(quien: Node) -> void:
	if quien != self:
		_turno = SEPARACION_GRUPO
