extends SceneTree
# Capturas de la orilla del oasis del Mar de Cristal (V12, 19/11, C-2 / PC-14: en la orilla oeste se pisaba el agua).
# Kael llega andando hacia el centro del estanque desde el oeste y desde el sur (con el grupo detrás) y se le fotografía
# donde se para, en los perfiles bajo y alto, de lejos y de cerca. Con ventana; una persona revisa las capturas.
# Imprime «ORILLA <perfil> <toma>: Kael a d m del centro, suelo y, agua y» para el informe.
# Uso: --path aethelgard --script res://pruebas/fotos_mc_oasis.gd --fixed-fps 30 -- <carpeta> 3d mardecristal sin_prologo

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const ARCHIVO := "user://fotos_mc_oasis.save"
const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const PERFILES := ["bajo", "alto"]
# [toma, desde (x, z), distancia de la cámara]
const TOMAS := [["1_oeste", Vector2(63.0, 72.0), 14.0], ["2_oeste_cerca", Vector2(63.0, 72.0), 7.0],
	["3_suroeste", Vector2(66.0, 79.0), 12.0], ["4_sur", Vector2(74.0, 82.0), 12.0]]

var salida := ""
var perfil := ""
var R
var fallos := 0


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	_todo.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


func _foto(nombre: String) -> void:
	var ruta := "%s/%s_%s.png" % [salida, perfil, nombre]
	root.get_viewport().get_texture().get_image().save_png(ruta)
	print("FOTO ", ruta)


func _todo() -> void:
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for p in PERFILES:
		perfil = p
		await _perfil()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	Engine.remove_meta("calidad_proto")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _suelo_y(r, x: float, z: float, desde := 0.4) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, desde, z), Vector3(x, -5.0, z))
	var res: Dictionary = r.get_world_3d().direct_space_state.intersect_ray(q)
	return NAN if res.is_empty() else float(res["position"].y)


func _perfil() -> void:
	var P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("incienso", 100000)
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(REGION)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION \
			and current_scene.get("kael") != null and not R.cambiando, 120.0):
		print("FALLO: no se abre la región")
		fallos += 1
		return
	var r = current_scene
	r.clima.sistemicas = false
	await _esperar(40)
	var est: Node3D = r.terreno.raiz.get_node("Estanque")
	var agua_y: float = est.global_position.y + 0.025
	for t in TOMAS:
		var desde: Vector2 = t[1]
		r._colocar_kael(Vector3(desde.x, 0, desde.y))
		r._ultima = r.kael.global_position
		r._dist_jugador = float(t[2])
		await _esperar(20)
		r.destino = r._ajustar_destino(Vector3(T.OASIS.x, 0, T.OASIS.y))
		await _hasta(func(): return r.destino == null, 12.0)
		await _esperar(75)                                  # que el grupo llegue y la cámara se asiente
		var k: Vector3 = r.kael.global_position
		print("ORILLA %s %s: Kael a %.2f m del centro, suelo %.3f, agua %.3f" % [perfil, t[0],
			Vector2(k.x, k.z).distance_to(T.OASIS), _suelo_y(r, k.x, k.z, k.y + 0.5), agua_y])
		_foto(t[0])
