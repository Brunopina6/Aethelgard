extends SceneTree
# V12, mapamundi 3D (15/11/2026): el mapamundi 3D APAGADO (por defecto: «-- 3d sin_prologo», sin «mapamundi3d»).
#   1. mapamundi_activo() es falso; Oakhaven y Pastos salen al mapa de siempre y no queda ninguna llegada apuntada;
#   2. Oakhaven 3D → su salida de verdad → mapa.tscn (el mapa de siempre, con Pastos Verdes como lugar 10);
#   3. una partida guardada en el mapamundi o en la cueva vuelve al mapa de siempre, en el sitio equivalente (pos_mapa)
#      y sin tocar sus descubrimientos (por si se vuelve a encender);
#   4. elegirlo en Ajustes ([regiones] mapamundi3d) lo enciende y quitarlo lo apaga (la carpeta de datos es la aislada).
# Partida propia. Espera las cargas por RELOJ. Imprime «FALLOS: n».

const MM := "res://zonas3d/mapamundi_3d.tscn"
const CUEVA := "res://zonas3d/cueva_provisional_3d.tscn"
const OAK := "res://zonas3d/oakhaven_3d.tscn"
const MAPA := "res://mapa.tscn"
var M = load("res://modo3d.gd")
var P = load("res://progreso.gd")
var D = load("res://zonas3d/mapamundi/datos.gd")
var R
var fallos := 0


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _hasta(cond: Callable, max_ms := 30000) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < max_ms:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _correr() -> void:
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", "user://prueba_mapamundi3d_apagado.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	# 1
	if M.mapamundi_activo():
		_mal("el mapamundi 3D está encendido sin elegirlo")
	if M.salida_al_mapa(0) != MAPA or M.salida_al_mapa(10) != MAPA or Engine.has_meta(D.LLEGADA):
		_mal("apagado, Oakhaven o Pastos no salen al mapa de siempre")
	else:
		print("OK 1 apagado por defecto: Oakhaven y Pastos salen al mapa de siempre")
	# 2
	change_scene_to_file(OAK)
	await _hasta(func(): return _escena() == OAK and current_scene.get("kael") != null)
	for i in 10:
		await process_frame
	current_scene._salir()
	await _hasta(func(): return _escena() == MAPA and not R.cambiando)
	for i in 5:
		await process_frame
	if _escena() != MAPA:
		_mal("la salida de Oakhaven 3D no lleva al mapa de siempre («%s»)" % _escena())
	elif current_scene.lugares.size() != current_scene.LUGARES.size() + 1:
		_mal("el mapa de siempre no muestra Pastos Verdes como lugar 10")
	else:
		print("OK 2 Oakhaven 3D → mapa de siempre (%d lugares, con Pastos Verdes)" % current_scene.lugares.size())
	# 3
	for escena in [MM, CUEVA]:
		var d := {"escena_guardada": escena, "prologo_visto": true, "pos_mapa": Vector2(600.0, 440.0), "pos_mapa_ok": true,
			"pos_3d": Vector3(8.75, 1.0, 10.0), "pos_3d_ok": true, "pos_3d_lugar": D.INDICE,
			"mazmorras": {"mapamundi": {"oakhaven": true, "campamento": true}}}
		var vuelve: String = P.restaurar(d)
		if vuelve != MAPA:
			_mal("una partida guardada en «%s» no vuelve al mapa de siempre («%s»)" % [escena, vuelve])
		if D.destinos_conocidos() != ["oakhaven", "campamento"]:
			_mal("al cargar con el mapamundi apagado se pierden sus descubrimientos")
	change_scene_to_file(MAPA)
	await _hasta(func(): return _escena() == MAPA and current_scene.get("jugador") != null)
	for i in 5:
		await process_frame
	if current_scene.jugador.position.distance_to(Vector2(600, 440)) > 1.0:
		_mal("en el mapa de siempre, Kael no aparece en el sitio equivalente (%s)" % current_scene.jugador.position)
	else:
		print("OK 3 partidas del mapamundi y de la cueva → mapa de siempre en el sitio equivalente; descubrimientos intactos")
	# 4
	M.elegir("mapamundi3d", true)
	var con: bool = M.mapamundi_activo()
	M.elegir("mapamundi3d", false)
	if not con or M.mapamundi_activo():
		_mal("la opción de Ajustes no enciende y apaga el mapamundi")
	else:
		print("OK 4 la opción de Ajustes lo enciende y lo apaga")
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
