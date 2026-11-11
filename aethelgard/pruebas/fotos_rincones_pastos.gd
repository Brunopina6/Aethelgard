extends SceneTree
# Capturas de los rincones de Pastos Verdes 3D (12/11, zonas3d/pastos_rincones.gd) para revisarlos a ojo, en los
# perfiles alto y bajo: el montón de los peregrinos (desde el camino, de cerca y con la piedra puesta), el nido de la
# urraca (su brillo desde el camino, el botón, el diálogo con Garon y el premio), una bandada posada y volando, y el
# centro del puente al asomarse. Con ventana.
# Uso: --path aethelgard --script res://pruebas/fotos_rincones_pastos.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo
# Los encuentros se quitan aquí (pasos = 0); la región jugable los conserva. No guarda ninguna partida.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const PERFILES := ["alto", "bajo"]
const MISION := ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo"]

var salida := ""
var perfil := ""
var R
var D
var fallos := 0


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	_todo.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if current_scene != null and current_scene.get("pasos") != null:
			current_scene.pasos = 0


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await _esperar(1)
	return false


func _foto(nombre: String) -> void:
	var ruta := "%s/%s_%s.png" % [salida, perfil, nombre]
	root.get_viewport().get_texture().get_image().save_png(ruta)
	print("FOTO ", ruta)


func _todo() -> void:
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	for p in PERFILES:
		perfil = p
		Engine.set_meta("calidad_proto", p)
		await _solo()
		await _grupo()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _entrar(hitos: Array, grupo: Array) -> Object:
	var h := {}
	for x in hitos:
		h[x] = true
	Engine.set_meta("hitos", h)
	Engine.set_meta("combates_ganados", {"pastos_centinela": true} if "pv_06" in hitos else {})
	Engine.set_meta("grupo_activo", grupo)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("comentarios_dichos", {})
	change_scene_to_file(REGION)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION \
			and current_scene.get("kael") != null and not R.cambiando, 120.0):
		print("FALLO: no se abre la región")
		fallos += 1
		return null
	var r = current_scene
	await _hasta(func(): return r.rincones != null and r.rincones.puntos.size() == 3, 10.0)
	await _esperar(20)
	return r


func _ir(r, p: Vector3, distancia := 20.0) -> void:
	r.distancia = distancia
	r._colocar_kael(_suelo(r, p))
	r._ultima = r.kael.global_position
	await _esperar(40)
	r._comprobar_cerca()


func _solo() -> void:
	var r = await _entrar(["pv_02"], ["Kael"])
	if r == null:
		return
	var rc = r.rincones
	var m: Vector3 = rc.monton.global_position
	await _ir(r, m + Vector3(2.4, 0, 2.6))
	_foto("monton_1_desde_el_camino")
	await _ir(r, m + Vector3(1.15, 0, 0.55), 9.0)
	_foto("monton_2_cerca_boton")
	r._accion()
	await _esperar(85)
	_foto("monton_3_piedra_y_comentario")
	await _ir(r, Vector3(15.6, 0, 1.6))                # junto al cofre del árbol mágico: el nido brilla a ratos
	await _hasta(func(): return rc.brillo_nido != null and rc.brillo_nido.scale.x > 0.4, 6.0)
	_foto("nido_1_brillo_desde_lejos")
	await _ir(r, rc.puntos[1]["nodo"].global_position + Vector3(0, 0, 0.3), 9.0)
	await _hasta(func(): return rc.brillo_nido != null and rc.brillo_nido.scale.x > 0.4, 6.0)
	_foto("nido_2_cerca_boton")
	r._accion()
	await _esperar(90)
	_foto("nido_3_sin_garon")
	await _ir(r, rc.PUENTE + Vector3(0.3, 0, 0.2), 12.0)
	_foto("puente_1_boton")
	r._accion()
	await _esperar(45)
	_foto("puente_2_solo")


func _grupo() -> void:
	var r = await _entrar(MISION, ["Kael", "Lya", "Garon"])
	if r == null:
		return
	var rc = r.rincones
	for i in rc.bandadas.size():                          # cada bandada, posada y al salir volando
		var b: Dictionary = rc.bandadas[i]
		var lado := Vector3(-5.5, 0, 0.6) if i == 1 else Vector3(5.5, 0, 0.6)   # la 1 tiene el barranco al este
		await _ir(r, b["centro"] + lado, 12.0)
		_foto("pajaros_%d_posados" % i)
		r.destino = b["centro"] + lado * 0.25              # Kael se acerca andando
		await _hasta(func(): return b["estado"] == "vuelo", 8.0)
		await _esperar(24)
		_foto("pajaros_%d_vuelan" % i)
	await _ir(r, rc.puntos[1]["nodo"].global_position + Vector3(0, 0, 0.3), 9.0)
	r._accion()
	if D != null and await _hasta(func(): return D.current_timeline != null, 5.0):
		await _esperar(45)
		_foto("nido_4_dialogo_garon")
		var ultimo := 0
		var limite := Time.get_ticks_msec() + 20000
		while D.current_timeline != null and Time.get_ticks_msec() < limite:
			await _esperar(1)
			var fr := Engine.get_process_frames()
			if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and fr - ultimo >= 20:
				D.Inputs.handle_input()
				ultimo = fr
	await _esperar(20)
	_foto("nido_5_subiendo")
	await _hasta(func(): return not rc.ocupado(), 5.0)
	await _esperar(100)
	_foto("nido_6_premio_comentario_lya")
	await _ir(r, rc.PUENTE + Vector3(0.3, 0, 0.2), 12.0)
	r._accion()
	await _esperar(45)
	_foto("puente_3_grupo")


# El suelo bajo «p»: en el puente, su tablero; fuera, el terreno (como en prueba_rincones_pastos.gd).
func _suelo(r, p: Vector3) -> Vector3:
	if absf(p.x - r.RIO_X) > 4.5:
		return Vector3(p.x, r.altura(p.x, p.z), p.z)
	var e: PhysicsDirectSpaceState3D = r.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 30.0, p.z), Vector3(p.x, -30.0, p.z))
	if r.kael is CollisionObject3D:
		q.exclude = [r.kael.get_rid()]
	var h := e.intersect_ray(q)
	return h["position"] if not h.is_empty() else Vector3(p.x, r.altura(p.x, p.z), p.z)
