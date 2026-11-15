extends SceneTree
# V12, mapamundi 3D (15/11/2026): GRABACIONES para que el usuario vea el mapamundi 3D (en pruebas) dentro del juego, con
# sonido. No es una prueba: se lanza con el Movie Maker de Godot, que graba imagen y audio a ritmo fijo; las cargas se
# esperan por RELOJ (con --fixed-fps los fotogramas no son tiempo real). Datos aislados (partida de prueba).
#   modo=recorrido: Oakhaven 3D → la Puerta del Sur → mapamundi (junto a la entrada) → el camino, el campamento → Pastos
#                   Verdes 3D (con el grupo) → su salida → mapamundi junto a su entrada.
#   modo=viaje:     viaje rápido desde el botón (al campamento) y desde el mojón del campamento (a Oakhaven).
# Uso: godot --path aethelgard --write-movie <x.avi> --fixed-fps 30 --resolution 1280x720
#      --script res://pruebas/grabar_mapamundi3d.gd -- 3d mapamundi3d sin_prologo modo=recorrido|viaje

const MM := "res://zonas3d/mapamundi_3d.tscn"
const OAK := "res://zonas3d/oakhaven_3d.tscn"
const PASTOS := "res://zonas3d/pastos_verdes_3d.tscn"
var D = load("res://zonas3d/mapamundi/datos.gd")
var R
var v
var modo := "recorrido"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("modo="):
			modo = a.substr(5)
	root.size = Vector2i(1280, 720)
	_correr()


func _ms(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


# Segundos de JUEGO (a ritmo fijo, lo que dura en el vídeo).
func _seg(s: float) -> void:
	for i in int(s * 30.0):
		await process_frame


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _esperar(ruta: String) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		if _escena() == ruta and not R.cambiando and current_scene.get("kael") != null:
			break
		await process_frame
	v = current_scene


func _andar(ruta: Array) -> void:
	for c in ruta:
		if not is_instance_valid(v) or v.get("saliendo") == true:
			return
		v.destino = v._ajustar_destino(Vector3(c.x, v.kael.global_position.y, c.y))
		for i in 30 * 15:
			if not is_instance_valid(v) or v.destino == null or v.get("saliendo") == true:
				break
			await process_frame


func _correr() -> void:
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", "user://grabar_mapamundi3d.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("mm3d_sin_encuentros", true)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true, "pv_06": true, "pv_07": true})
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	if modo == "viaje":
		await _viaje()
	else:
		await _recorrido()
	await _seg(1.0)
	quit(0)


func _recorrido() -> void:
	change_scene_to_file(OAK)
	await _esperar(OAK)
	await _seg(1.5)
	var ini: Vector3 = v.kael.global_position
	await _andar([Vector2(ini.x, ini.z - 2.0)])
	await _seg(1.2)
	await _andar([Vector2(v.SALIDA.x, v.SALIDA.z)])          # la Puerta del Sur: sale al mapamundi
	await _esperar(MM)
	await _seg(2.0)
	var ruta: Array = []
	for p in D.CAMINO:
		if p.x > -9.0 and p.x < 22.5:
			ruta.append(p)
	await _andar(ruta)
	await _seg(0.6)
	await _andar([D.SITIOS["pastos"]["entrada"]])
	await _esperar(PASTOS)
	await _seg(3.0)
	var k: Vector3 = v.kael.global_position
	await _andar([Vector2(k.x + 2.5, k.z - 2.0)])
	await _seg(1.5)
	v._salir()
	await _esperar(MM)
	await _seg(2.0)
	await _andar([Vector2(19.0, 17.0)])
	await _seg(1.5)


func _viaje() -> void:
	for id in ["oakhaven", "campamento"]:
		D.descubrir(id)
	Engine.set_meta(D.LLEGADA, "oakhaven")
	change_scene_to_file(MM)
	await _esperar(MM)
	await _seg(1.5)
	v.abrir_viaje()
	await _seg(2.0)
	v.menu_abierto.botones[1].pressed.emit()                 # al campamento
	await _seg(3.0)
	await _andar([D.SITIOS["campamento"]["centro"] + Vector2(1.4, -1.6)])
	await _seg(1.0)
	v._pulsar_entrar()                                       # el mojón del campamento
	await _seg(2.0)
	v.menu_abierto.botones[0].pressed.emit()                 # a Oakhaven
	await _seg(3.0)
