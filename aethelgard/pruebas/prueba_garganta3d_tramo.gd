extends SceneTree
# Recorrido del primer tramo pulido de la Garganta del Diablo 3D (T-102): de la entrada al umbral de las piedras
# hincadas, la primera cornisa, el primer puente colgante (que se mece) y el islote, y vuelta, sin atascarse ni caer.
#   1. Andando con el dedo (destino), tramo a tramo: entrada → umbral → cornisa → cabeza del puente → mitad → islote,
#      y de vuelta al umbral. Cada tramo en menos de 12 s, sin bajar nunca de la cornisa y sin pisar lo prohibido.
#   2. Con la cruceta (ui_up mantenido): de la entrada al islote del tirón, y de vuelta con ui_down.
#   3. En mitad del puente, empujando hacia los lados (ui_left y ui_right): Kael no sale del tablero ni cae.
#   4. El puente se mece solo a la vista: dos puentes con su sombreado de vaivén, la colisión quieta.
#   5. La escena trae lo nuevo del tramo: la caída con su bruma, las llamas, las cintas de la entrada y los helechos.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_garganta3d_tramo.gd --fixed-fps 30 -- 3d garganta3d sin_prologo
# No toca ninguna partida: progreso.gd no guarda durante las pruebas. Los encuentros se quitan (v.pasos = 0).

const REGION := "res://zonas3d/garganta_3d.tscn"
const T := preload("res://zonas3d/garganta/trazado.gd")
const MAX_TRAMO := 360                      # fotogramas (12 s a 30 FPS)
const Y_MIN := T.ALTO - 0.8                 # más abajo, Kael se habría caído del tablero o de la cornisa

var v
var frames := 0
var fase := ""
var f_fase := 0
var fallos := 0
var y_min := INF
var tramos_dedo := [
	["entrada → umbral", Vector3(-12.0, 0, 33.0)],
	["umbral → cornisa", Vector3(-12.0, 0, 26.0)],
	["cornisa → cabeza del puente", Vector3(-12.0, 0, 20.4)],
	["cabeza → mitad del puente", Vector3(-12.0, 0, 15.0)],
	["mitad → islote", Vector3(-12.0, 0, 10.6)],
	["islote → cabeza (vuelta)", Vector3(-12.0, 0, 20.6)],
	["cabeza → umbral (vuelta)", Vector3(-12.0, 0, 34.5)],
]
var i_tramo := 0
var colision_inicial: Array = []


func _initialize() -> void:
	Engine.set_meta("pos_3d_ok", false)
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	change_scene_to_file(REGION)
	_fase("cargar")


func _fase(n: String) -> void:
	fase = n
	f_fase = frames


func _mal(texto: String) -> void:
	fallos += 1
	print("FALLO: " + texto)


func _vigilar() -> void:
	var p: Vector3 = v.kael.global_position
	y_min = minf(y_min, p.y)
	if p.y < Y_MIN:
		_mal("Kael cae (y = %.2f en %s, fase «%s»)" % [p.y, p.snapped(Vector3.ONE * 0.01), fase])
	if v._prohibido(p):
		_mal("Kael en sitio prohibido %s (fase «%s»)" % [p.snapped(Vector3.ONE * 0.01), fase])


func _soltar() -> void:
	for a in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		Input.action_release(a)


func _process(_d: float) -> bool:
	frames += 1
	if v != null and is_instance_valid(v):
		v.pasos = 0
		if fase != "cargar" and fase != "fin":
			_vigilar()
	match fase:
		"cargar":
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				_comprobar_escena()
				v._colocar_kael(T.INICIO)
				v._ultima = T.INICIO
				_fase("dedo")
				v.destino = v._ajustar_destino(tramos_dedo[0][1])
		"dedo":
			var meta: Vector3 = tramos_dedo[i_tramo][1]
			var falta := Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length()
			if falta < 0.35 and v.destino == null:
				print("OK dedo: %s en %d fotogramas (y = %.2f)" % [tramos_dedo[i_tramo][0], frames - f_fase, v.kael.global_position.y])
				_siguiente_tramo()
			elif v.destino == null and frames - f_fase > 5:
				_mal("dedo: «%s» se paró a %.2f m de la meta, en %s" % [tramos_dedo[i_tramo][0], falta, v.kael.global_position.snapped(Vector3.ONE * 0.01)])
				_siguiente_tramo()
			elif frames - f_fase > MAX_TRAMO:
				_mal("dedo: «%s» no llegó en %d fotogramas (atasco) en %s" % [tramos_dedo[i_tramo][0], MAX_TRAMO, v.kael.global_position.snapped(Vector3.ONE * 0.01)])
				_siguiente_tramo()
		"cruceta_norte":
			if v.kael.global_position.z < T.ISLOTE[1] - 0.6:
				_soltar()
				print("OK cruceta: de la entrada al islote en %d fotogramas" % (frames - f_fase))
				_fase("cruceta_sur")
				Input.action_press("ui_down")
			elif frames - f_fase > 2 * MAX_TRAMO:
				_soltar()
				_mal("cruceta: con ui_up no llegó al islote (se quedó en %s)" % v.kael.global_position.snapped(Vector3.ONE * 0.01))
				_fase("cruceta_sur")
				Input.action_press("ui_down")
		"cruceta_sur":
			if v.kael.global_position.z > 34.0:
				_soltar()
				print("OK cruceta: del islote a la entrada en %d fotogramas" % (frames - f_fase))
				_a_los_lados()
			elif frames - f_fase > 2 * MAX_TRAMO:
				_soltar()
				_mal("cruceta: con ui_down no volvió a la entrada (se quedó en %s)" % v.kael.global_position.snapped(Vector3.ONE * 0.01))
				_a_los_lados()
		"lados_izq":
			if frames - f_fase == 75:
				Input.action_release("ui_left")
				var x: float = v.kael.global_position.x
				if absf(x - T.X_CAMINO_O) > T.ANCHO_PUENTE * 0.5:
					_mal("a la izquierda, Kael salió del tablero (x = %.2f)" % x)
				else:
					print("OK lados: empujando a la izquierda se queda en el tablero (x = %.2f, y = %.2f)" % [x, v.kael.global_position.y])
				_fase("lados_der")
				Input.action_press("ui_right")
		"lados_der":
			if frames - f_fase == 75:
				Input.action_release("ui_right")
				var x: float = v.kael.global_position.x
				if absf(x - T.X_CAMINO_O) > T.ANCHO_PUENTE * 0.5:
					_mal("a la derecha, Kael salió del tablero (x = %.2f)" % x)
				else:
					print("OK lados: empujando a la derecha se queda en el tablero (x = %.2f, y = %.2f)" % [x, v.kael.global_position.y])
				_fase("vaiven")
		"vaiven":
			if frames - f_fase == 45:
				_comprobar_vaiven()
				_fase("fin")
				print("Altura mínima de Kael en todo el recorrido: %.2f m" % y_min)
				print("FALLOS: %d" % fallos)
				quit(1 if fallos > 0 else 0)
				return true
	if frames > 6000:
		_mal("la prueba no terminó (fase «%s»)" % fase)
		print("FALLOS: %d" % fallos)
		quit(1)
		return true
	return false


func _siguiente_tramo() -> void:
	i_tramo += 1
	if i_tramo < tramos_dedo.size():
		_fase("dedo")
		v.destino = v._ajustar_destino(tramos_dedo[i_tramo][1])
	else:
		v.destino = null
		v._colocar_kael(T.INICIO)
		v._ultima = T.INICIO
		_fase("cruceta_norte")
		Input.action_press("ui_up")


func _a_los_lados() -> void:
	var p := Vector3(T.X_CAMINO_O, 0, 15.0)
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 2, 0), p - Vector3(0, 4, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		p.y = r["position"].y
	v._colocar_kael(p)
	v._ultima = p
	_fase("lados_izq")
	Input.action_press("ui_left")


# Lo nuevo del tramo está en la escena (en cualquier perfil).
func _comprobar_escena() -> void:
	var nombres: Array = []
	for n in v.find_children("*", "", true, false):
		nombres.append(String(n.name))
	for clave in ["CaidaDelPuente", "BrumaDeLaCaida", "LuzDeLaCaida", "CintasDeLaEntrada", "Helechos", "Llama"]:
		if not nombres.any(func(s: String) -> bool: return s.contains(clave)):
			_mal("falta «%s» en la escena" % clave)
	if v.piezas.puentes.size() != 2:
		_mal("hay %d puentes colgantes con vaivén (se esperaban 2)" % v.piezas.puentes.size())
	for cuerpo in v.find_children("*", "StaticBody3D", true, false):
		colision_inicial.append([cuerpo, cuerpo.global_transform])
	print("OK escena: caída, bruma, luz fría, cintas, helechos, llamas y %d puentes que se mecen" % v.piezas.puentes.size())


# El vaivén es solo del dibujo: el sombreado de los puentes lo lleva y ningún cuerpo que choca se ha movido.
func _comprobar_vaiven() -> void:
	for pu in v.piezas.puentes:
		for m in pu["materiales"]:
			var sm := m as ShaderMaterial
			if sm == null or sm.shader.code.find("VERTEX.x += lado * vaiven") < 0:
				_mal("un material del puente no lleva el vaivén")
			elif float(sm.get_shader_parameter("vaiven")) > 0.08 or float(sm.get_shader_parameter("rebote")) > 0.04:
				_mal("el vaivén es demasiado grande para la colisión quieta")
	var movidos := 0
	for c in colision_inicial:
		if is_instance_valid(c[0]) and not (c[0] as Node3D).global_transform.is_equal_approx(c[1]):
			movidos += 1
	if movidos > 0:
		_mal("%d cuerpos de colisión se han movido" % movidos)
	else:
		print("OK vaivén: %d puentes se mecen en el dibujo; los %d cuerpos que chocan siguen quietos" % [v.piezas.puentes.size(), colision_inicial.size()])
