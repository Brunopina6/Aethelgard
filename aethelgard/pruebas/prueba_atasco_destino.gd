extends SceneTree
# 15/11 (hallazgo del agente de Sunken City): la vigilancia de atascos de vista3d.gd (_vigilar_atasco) comparaba la
# distancia al destino con la de la comprobación anterior aunque el destino hubiera CAMBIADO. Si mientras Kael anda se
# toca un punto más lejano (lo normal con el dedo), a la siguiente comprobación «no se acercaba» y se paraba solo.
# En Oakhaven 3D, por la Calle Mayor (recta y sin nadie en medio por la tarde):
#   1. destino a 9 m; casi llegando (tras una comprobación), uno nuevo 10 m más allá: sigue andando y llega;
#   2. un atasco de verdad (destino detrás de un muro) sigue parándose.
# Sin ventana. Imprime «FALLOS: n».

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const ARCHIVO := "user://prueba_atasco_destino.save"
const Barrios := preload("res://zonas3d/oakhaven/barrios.gd")
var fallos := 0
var v


func _ok(c: bool, t: String) -> void:
	if not c:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _punto(x: float, z: float) -> Vector3:
	return Vector3(x, Barrios.altura(x, z), z)


func _kael() -> Vector2:
	return Vector2(v.kael.global_position.x, v.kael.global_position.z)


func _probar() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("oak_franja", "tarde")
	Engine.set_meta("partida_lista", true)
	change_scene_to_file(REGION)
	await _frames(40)
	v = current_scene
	while v == null or v.get("kael") == null:
		await _frames(5)
		v = current_scene
	await _frames(20)
	# 1. destino cambiado a uno más lejano mientras anda
	v._colocar_kael(_punto(40.0, 48.5))
	await _frames(5)
	v.destino = _punto(40.0, 39.5)                     # 9 m (corre a 7,56 m/s): en la comprobación de 1 s falta poco
	await _frames(33)                                 # 1,1 s: casi ha llegado y se toca más allá
	var antes := _kael()
	v.destino = _punto(40.0, 29.5)                     # 10 m más allá, en la misma calle
	for i in 150:                                      # hasta 5 s
		await process_frame
		if v.destino == null:
			break
	_ok(_kael().distance_to(Vector2(40.0, 29.5)) < 0.6,
		"1: con un destino nuevo más lejano, Kael se para en %s (había andado desde %s)" % [_kael(), antes])
	# 2. un atasco de verdad se sigue parando: destino dentro de una casa (al este de la Calle Mayor)
	v._colocar_kael(_punto(40.0, 40.0))
	await _frames(5)
	var casa := Vector3.ZERO
	for x in range(42, 52):
		var q := _punto(float(x), 40.0)
		if v._prohibido(q):
			casa = _punto(float(x) + 2.0, 40.0)
			break
	_ok(casa != Vector3.ZERO, "2: no hay ninguna casa al este de la Calle Mayor en z 40")
	v.destino = casa
	var parado := false
	for i in 120:
		await process_frame
		if v.destino == null:
			parado = true
			break
	_ok(parado, "2: contra un muro, Kael no se para en 4 s")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
