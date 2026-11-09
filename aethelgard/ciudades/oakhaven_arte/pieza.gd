extends Node2D
# Una pieza de Oakhaven ya montada por oakhaven_piezas.gd (T-089). Lleva:
#   - las anclas de la pieza (puntos con nombre: la puerta, la boca de la chimenea, cada farol…), en píxeles locales
#     de la pieza (a 64 px por casilla; con otro tamaño de casilla, la pieza entera va escalada);
#   - los estados que se ven o no (los faroles de la ronda, el destello del cofre de las raíces…): poner_estado();
#   - la puesta al día de la variable global de sombreado «jugador_pos» (la usan los edificios para aclararse si Kael
#     pasa por detrás). zona.gd solo la actualiza si la zona tiene hierba alta; aquí se hace con UNA pieza por escena.
# Nada de partidas ni de lógica de juego: los estados los decide quien llama (ciudad_oakhaven.gd).

var id := ""
var huella := Rect2()          # la huella en píxeles locales (la casilla de arriba a la izquierda es (0, 0))
var anclas := {}               # nombre → Vector2 (píxeles locales)
var estados := {}              # nombre → {"si": [nodos que se ven con el estado], "no": [nodos que se ven sin él]}
var coste := {}                # "nodos", "texturas_px" (memoria estimada en el informe)

static var _guia: WeakRef = null
var _ultima := Vector2(-1e9, -1e9)


func _ready() -> void:
	if _guia == null or _guia.get_ref() == null:
		_guia = weakref(self)
	set_process(_guia.get_ref() == self)


func _exit_tree() -> void:
	if _guia != null and _guia.get_ref() == self:
		_guia = null


# Posición global de un ancla (para poner un PNJ, un cofre, un aviso…). Vector2.INF si no existe.
func ancla(nombre: String) -> Vector2:
	if not anclas.has(nombre):
		return Vector2.INF
	return to_global(anclas[nombre])


# Enciende o apaga un estado («farol_1», «destello»…). Devuelve false si la pieza no lo tiene.
func poner_estado(nombre: String, si: bool) -> bool:
	if not estados.has(nombre):
		return false
	for n in estados[nombre].get("si", []):
		if is_instance_valid(n):
			n.visible = si
	for n in estados[nombre].get("no", []):
		if is_instance_valid(n):
			n.visible = not si
	return true


func tiene_estado(nombre: String) -> bool:
	return estados.has(nombre)


func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var j = escena.get("jugador")
	if j is Node2D:
		var p: Vector2 = j.global_position
		if p.distance_squared_to(_ultima) > 0.25:
			_ultima = p
			RenderingServer.global_shader_parameter_set("jugador_pos", p)
