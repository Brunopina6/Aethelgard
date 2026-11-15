extends SceneTree
# V12 (15/11): Kael CRUZA Oakhaven 3D entre los vecinos con los controles normales (clics en el suelo, como un toque:
# vista3d.gd _unhandled_input → destino), por la mañana y por la tarde, con el mundo vivo (zonas3d/oakhaven/mundo_vivo.gd,
# interruptor «mundo_vivo_v12») apagado y encendido. En el Redmi (14/11) solo se probó de noche, con pocos vecinos: la
# hora de más gente quedó sin probar. Aquí se mide cuánto tarda cada ruta y si se queda atascado (más de MAX_TRAMO s en
# un tramo), con una captura de la plaza en cada pasada. Resultado de PC: no certifica Android.
# Uso: lista_pruebas.txt (fotos_paso_vecinos, ventana): «3d sin_prologo salida={salida}». Partida propia. «FALLOS: n».

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const ARCHIVO := "user://paso_vecinos.save"
const Barrios := preload("res://zonas3d/oakhaven/barrios.gd")
const MAX_TRAMO := 12.0

# Rutas por calles (casillas x, y de la 2D = x, z de la 3D), las mismas que ya recorre fotos_cantero_recorrido.
const RUTAS := {
	"puerta_a_plaza": [Vector2(40, 48.5), Vector2(40, 43), Vector2(40.4, 37), Vector2(40.4, 31.6), Vector2(42.35, 29.4),
		Vector2(42.35, 26.9)],
	"plaza_a_torre": [Vector2(42.5, 26.6), Vector2(46.8, 26.0), Vector2(52, 26), Vector2(58, 26), Vector2(64, 26),
		Vector2(69, 26.6), Vector2(69, 32), Vector2(69, 37.5), Vector2(69.3, 43.4)],
	"torre_a_plaza": [Vector2(69, 37.5), Vector2(69, 32), Vector2(69, 26.6), Vector2(64, 26), Vector2(58, 26), Vector2(52, 26),
		Vector2(46.8, 26.0)],
	"plaza_al_arbol": [Vector2(45.6, 22.4), Vector2(41.6, 21.6), Vector2(40.4, 17), Vector2(40.2, 13.6)],
}

var v
var salida := ""
var fallos := 0
var registro: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("paso_vecinos")
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	root.size = Vector2i(1280, 720)
	_jugar.call_deferred()


func _ok(c: bool, t: String) -> void:
	if not c:
		fallos += 1
		print("FALLO: ", t)
		registro.append("FALLO: " + t)


func _nota(t: String) -> void:
	print(t)
	registro.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(s * 1000.0):
		await process_frame


func _clic(pos: Vector2) -> void:
	for apretar in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = pos
		e.global_position = pos
		e.pressed = apretar
		Input.parse_input_event(e)
		await _frames(2)


func _kael_en() -> Vector2:
	var p: Vector3 = v.kael.global_position
	return Vector2(p.x, p.z)


func _andar_a(c: Vector2) -> bool:
	var t0 := Time.get_ticks_msec()
	var reintentos := 0
	while Time.get_ticks_msec() - t0 < int(MAX_TRAMO * 1000.0):
		if _kael_en().distance_to(c) < 0.7:
			return true
		if v.get("destino") == null:
			if reintentos > 8:                 # (con gente que pasa, se vuelve a tocar como haría el jugador)
				break
			reintentos += 1
			var objetivo := c
			var cam: Camera3D = v.cam
			for k in 6:
				var w := Vector3(objetivo.x, Barrios.altura(objetivo.x, objetivo.y), objetivo.y)
				var pp := cam.unproject_position(w)
				if not cam.is_position_behind(w) and Rect2(40, 90, 1200, 520).has_point(pp):
					await _clic(pp)
					break
				objetivo = _kael_en().lerp(objetivo, 0.5)
		await _frames(2)
	return _kael_en().distance_to(c) < 1.2


func _ruta(nombre: String, pasada: String) -> void:
	var t0 := Time.get_ticks_msec()
	for c in RUTAS[nombre]:
		if not await _andar_a(c):
			_ok(false, "%s, %s: atasco antes de %s (Kael en %s)" % [pasada, nombre, c, _kael_en()])
			_diagnostico(c)
			return
	_nota("%s, %s: %.1f s" % [pasada, nombre, (Time.get_ticks_msec() - t0) / 1000.0])


# Qué hay alrededor de un atasco: vecinos a menos de 3 m, el destino pendiente y si los pasos siguientes están prohibidos.
func _diagnostico(c: Vector2) -> void:
	var k := _kael_en()
	var dir := (c - k).normalized()
	var pasos: Array = []
	for d in [0.3, 0.6, 1.0]:
		var q: Vector2 = k + dir * float(d)
		pasos.append("%.1f:%s" % [d, "prohibido" if v._prohibido(Vector3(q.x, v.kael.global_position.y, q.y)) else "libre"])
	_nota("   destino=%s pasos=%s" % [v.get("destino"), " ".join(pasos)])
	for id in v.vida.vecinos:
		var n = v.vida.vecinos[id].get("nodo")
		if n is Node3D and is_instance_valid(n):
			var q: Vector3 = n.global_position
			if Vector2(q.x, q.z).distance_to(k) < 3.0:
				_nota("   vecino %s en (%.2f, %.2f)" % [id, q.x, q.z])
	if v.get("vivo") != null:
		for g in v.vivo.gente:
			var q: Vector3 = (g["nodo"] as Node3D).global_position
			if Vector2(q.x, q.z).distance_to(k) < 3.0:
				_nota("   persona %s en (%.2f, %.2f)" % [g["d"]["id"], q.x, q.z])


func _pasada(franja: String, vivo: bool) -> void:
	for k in ["pos_3d", "pos_3d_ok", "pos_3d_lugar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("oak_franja", franja)
	Engine.set_meta("mundo_vivo_v12", vivo)
	change_scene_to_file(REGION)
	await _frames(30)
	v = current_scene
	var t0 := Time.get_ticks_msec()
	while (v == null or v.get("kael") == null) and Time.get_ticks_msec() - t0 < 8000:
		await _frames(5)
		v = current_scene
	await _segundos(2.0)
	var pasada := "%s, mundo vivo %s" % [franja, "sí" if vivo else "no"]
	var gente: int = v.vivo.gente.size() if v.get("vivo") != null else 0
	_nota("%s: %d vecinos con diálogo y %d personas del mundo vivo" % [pasada, v.vida.vecinos.size(), gente])
	for r in ["puerta_a_plaza", "plaza_a_torre", "torre_a_plaza", "plaza_al_arbol"]:
		await _ruta(r, pasada)
		if r == "puerta_a_plaza":
			await _frames(3)
			root.get_texture().get_image().save_png(salida.path_join("plaza_%s_%s.png" % [franja, "vivo" if vivo else "base"]))


func _jugar() -> void:
	await _frames(3)
	var P = load("res://progreso.gd")
	for k in P.CLAVES + ["partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	P.cargar()
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("partida_lista", true)
	var franjas := ["manana", "tarde", "anochecer"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("franjas="):
			franjas = a.trim_prefix("franjas=").split(",")
	for vivo in [false, true]:
		for franja in franjas:
			await _pasada(franja, vivo)
	Engine.remove_meta("mundo_vivo_v12")
	var f := FileAccess.open(salida.path_join("paso_vecinos.txt"), FileAccess.WRITE)
	f.store_string("\n".join(registro) + "\n")
	f.close()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
