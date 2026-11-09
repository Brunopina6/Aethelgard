extends SceneTree
# Prueba de la región 3D de Pastos Verdes (zonas3d/pastos_verdes_3d.tscn) con la exploración 3D activa («-- 3d»).
# Recorre el contrato de una zona:
#   1. se entra por el principio del camino, sin los botones de los bancos y con los 40 pasos seguros;
#   2. encuentro → combate (combate.tscn de verdad) → vuelta al mismo sitio (±0,5 m);
#   3. salida al mapa por el principio del camino; el mapa muestra Pastos Verdes (lugar 10);
#   4. lo que se guardaría (en partida_exp.save) vuelve a la región.
# No escribe archivos: progreso.gd no guarda durante las pruebas. Espera cada cambio de escena en tiempo real
# (como prueba_escenas) y termina con quit(1) y «FALLO» si algo no se cumple.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ESPERA_MAX_MS := 40000
const TOLERANCIA := 0.5

var frames := 0
var paso := 0
var t_paso := 0
var f_paso := 0
var R
var prog
var pos_combate := Vector3.ZERO


func _initialize() -> void:
	R = root.get_node("Recursos")
	prog = load("res://progreso.gd")
	var m3 = load("res://modo3d.gd")
	if not m3.activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		return
	if m3.escena_de(10) != REGION:
		_fallo("el lugar 10 no lleva a la región 3D (lleva a «%s»)" % m3.escena_de(10))
		return
	if prog.archivo() != prog.GUARDADO_EXP:
		_fallo("con la exploración 3D, la partida no va a partida_exp.save")
		return
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})   # sin las escenas de la misión (prueba_ruta_alpha)
	change_scene_to_file(REGION)
	_siguiente()


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	quit(1)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _siguiente() -> void:
	paso += 1
	t_paso = Time.get_ticks_msec()
	f_paso = frames


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo("el paso %d no terminó en %d s (escena=%s)" % [paso, ESPERA_MAX_MS / 1000, _escena()])
		return false
	match paso:
		1:
			if _escena() == REGION and not R.cambiando and frames - f_paso >= 10:
				return _comprobar_entrada()
		2:
			if _escena() == "res://combate.tscn" and not R.cambiando and frames - f_paso >= 5:
				print("combate cargado; vuelta a la región")
				current_scene._volver_al_mapa()
				_siguiente()
		3:
			if _escena() == REGION and not R.cambiando and frames - f_paso >= 5:
				return _comprobar_vuelta()
		4:
			if _escena() == "res://mapa.tscn" and not R.cambiando and frames - f_paso >= 5:
				return _comprobar_mapa()
	return false


func _comprobar_entrada() -> bool:
	var r = current_scene
	var inicio: Vector3 = r.SENDERO[0]
	if _plana(r.kael.global_position, inicio) > 1.0:
		_fallo("Kael no entra por el principio del camino (%s)" % r.kael.global_position)
		return false
	for b in r.find_children("*", "Button", true, false):
		if b.text in r.BOTONES_BANCO and b.is_visible_in_tree():   # DIAG y MEDIO existen, ocultos hasta abrir RND (09/11)
			_fallo("se ve el botón de banco «%s»" % b.text)
			return false
	if r.info.visible:
		_fallo("se ve la ayuda de teclas del prototipo")
		return false
	if Engine.get_meta("zona", "") != "llanura":
		_fallo("la zona de los encuentros no es «llanura»")
		return false
	if r.salidas.size() != 2 or not r.salidas[0]["armada"]:
		_fallo("las salidas no están listas (%s)" % [r.salidas])
		return false
	for i in r.PASOS_MIN - 1:
		r._paso()
	if r.saliendo:
		_fallo("hubo un encuentro en los pasos seguros")
		return false
	print("OK entrada: Kael en el principio del camino, 2 salidas, %d pasos seguros sin encuentro" % (r.PASOS_MIN - 1))
	var p := Vector3(-9.0, r.altura(-9.0, 9.0), 9.0)          # un punto del camino, lejos de las salidas
	r._colocar_kael(p)
	pos_combate = r.kael.global_position
	r._encuentro()
	if Engine.get_meta("escena_retorno", "") != REGION or not Engine.get_meta("desde_mapa", false):
		_fallo("el combate no volverá a la región")
		return false
	if not Engine.get_meta("pos_3d_ok", false) or Engine.get_meta("pos_3d_lugar", -1) != 10:
		_fallo("no se apuntó la posición de la región")
		return false
	if _plana(Engine.get_meta("pos_3d"), pos_combate) > 0.01:
		_fallo("la posición apuntada no es la de Kael")
		return false
	print("OK encuentro: escena_retorno, desde_mapa y pos_3d apuntados")
	_siguiente()
	return false


func _comprobar_vuelta() -> bool:
	var r = current_scene
	var dist := _plana(r.kael.global_position, pos_combate)
	if dist > TOLERANCIA:
		_fallo("tras el combate, Kael aparece a %.2f m de donde estaba" % dist)
		return false
	if Engine.get_meta("desde_mapa", false):
		_fallo("desde_mapa sigue activo tras el combate")
		return false
	print("OK vuelta del combate: Kael a %.2f m de donde empezó el encuentro" % dist)
	var salida: Vector3 = r.salidas[0]["pos"]
	if not r.salidas[0]["armada"]:
		_fallo("la salida del principio no está armada")
		return false
	r.kael.global_position = salida + Vector3(0.3, 0.0, 0.0)  # Kael llega a la salida del principio
	_siguiente()
	return false


func _comprobar_mapa() -> bool:
	if Engine.get_meta("pos_3d_ok", true):
		_fallo("al salir al mapa no se borró la posición de la región")
		return false
	var m = current_scene
	if m.lugares.size() != m.LUGARES.size() + 1 or m.lugares[10]["nombre"] != "Pastos Verdes":
		_fallo("el mapa no muestra Pastos Verdes como lugar 10")
		return false
	print("OK salida: de vuelta en el mapa, que muestra Pastos Verdes (lugar 10)")
	Engine.set_meta("pos_3d", Vector3(1, 2, 3))
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", 10)
	var d: Dictionary = prog.volcar(REGION)
	for k in ["pos_3d", "pos_3d_ok", "pos_3d_lugar", "escena_guardada"]:
		if not d.has(k):
			_fallo("la partida no guardaría «%s»" % k)
			return false
	if prog.restaurar(d) != REGION:
		_fallo("una partida guardada en la región no vuelve a ella")
		return false
	print("OK guardado: la partida guardaría la región y volvería a ella")
	print("OK región 3D de Pastos Verdes")
	return true
