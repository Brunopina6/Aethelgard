extends SceneTree
# Capturas del rincón del Mar de Cristal (V12, 12/11, zonas3d/mar_cristal/rincones.gd): el hito del cobijo en los
# perfiles bajo y alto, para revisarlo a ojo. Con ventana.
#   1. desde la boca del cañón, al sureste (a unos 8 m) (cómo se ve de lejos: el trapo azul junto al cobijo);
#   2. el destello del vidrio al sonar, desde unos 6 m;
#   3. junto al hito, con su botón;
#   4. el diálogo con el grupo (la segunda frase);
#   5. el aviso del premio;
#   6. con tormenta, desde la boca del cañón (el vidrio que destella cuando el trapo casi no se ve).
# Uso: --path aethelgard --script res://pruebas/fotos_mc_rincon.gd --fixed-fps 30 -- <carpeta> 3d mardecristal sin_prologo
# Guarda (si guarda) solo en su propio archivo de prueba, que borra al acabar.

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const ARCHIVO := "user://fotos_mc_rincon.save"
const RC := preload("res://zonas3d/mar_cristal/rincones.gd")
const PERFILES := ["bajo", "alto"]

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


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


# (19/11, PC-10) por RELOJ, para montar la región: con ventana el ritmo lo pone la pantalla (a 144 Hz, «120 s» contados
# en fotogramas eran 25 s) y la carga va en tiempo real. El resto espera en tiempo de JUEGO a propósito.
func _hasta_reloj(cond: Callable, segundos := 60.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(segundos * 1000.0):
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _foto(nombre: String) -> void:
	var ruta := "%s/%s_%s.png" % [salida, perfil, nombre]
	root.get_viewport().get_texture().get_image().save_png(ruta)
	print("FOTO ", ruta)


func _todo() -> void:
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
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


func _poner(r, x: float, z: float) -> void:
	r._colocar_kael(Vector3(x, 0, z))
	r._ultima = r.kael.global_position


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
	if not await _hasta_reloj(func(): return current_scene != null and current_scene.scene_file_path == REGION \
			and current_scene.get("kael") != null and not R.cambiando, 120.0):
		print("FALLO: no se abre la región en 120 s (R.cambiando=%s)" % R.cambiando)
		fallos += 1
		return
	var r = current_scene
	r.clima.sistemicas = false
	await _esperar(40)
	# 1. de lejos, desde la boca del cañón
	_poner(r, RC.HITO.x + 5.5, RC.HITO.y + 6.5)
	r._dist_jugador = 20.0
	await _esperar(60)
	_foto("1_desde_canon")
	_poner(r, RC.HITO.x + 9.0, RC.HITO.y + 2.0)        # 1b. desde el este, a unos 9 m (lo que se ve al venir de los restos)
	await _esperar(60)
	_foto("1b_desde_este")
	# 2. el destello, a unos 9 m
	_poner(r, RC.HITO.x + 3.5, RC.HITO.y + 4.5)
	r._dist_jugador = 14.0
	await _esperar(60)
	r.rincones._t_son = 0.0
	await _esperar(3)
	_foto("2_destello")
	# 3. junto al hito, con su botón
	_poner(r, RC.HITO.x + 1.4, RC.HITO.y + 1.0)
	await _esperar(45)
	r._bloqueo = 0.0
	r._comprobar_cerca()
	await _esperar(2)
	_foto("3_boton")
	# 4. el diálogo (segunda frase) y 5. el premio
	r._accion()
	if D != null:
		await _hasta(func(): return D.current_timeline != null, 5.0)
	if D != null and D.current_timeline != null:
		await _esperar(50)
		D.Inputs.handle_input()                    # termina de escribir la primera
		await _esperar(6)
		D.Inputs.handle_input()                    # la segunda
		await _esperar(60)
		_foto("4_dialogo")
		D.end_timeline(true)
	await _esperar(25)
	_foto("5_premio")
	# 6. con tormenta, desde la boca del cañón
	await _esperar(90)
	_poner(r, RC.HITO.x + 5.5, RC.HITO.y + 6.5)
	r._dist_jugador = 20.0
	r.clima.empezar_tormenta(false)
	await _esperar(30 * 7)
	await _hasta(func(): return r.rincones.destello.visible, 6.0)
	await _esperar(2)
	_foto("6_tormenta")
	r.clima._amainar()
	await _esperar(10)
