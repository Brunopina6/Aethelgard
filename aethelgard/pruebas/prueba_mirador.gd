extends SceneTree
# Prueba de la cinemática del mirador (PV-07, zonas3d/pastos_verdes_3d.gd), con la exploración 3D activa («-- 3d»).
# El guardado automático escribe en el archivo propio de la prueba (user://prueba_mirador.save), nunca en la partida.
#   1. Primera vez: tras vencer al centinela, Kael llega andando al mirador y empieza la cinemática. El hito pv_07
#      ya está puesto y guardado antes de que acabe la animación.
#   2. Durante la cinemática: sin control (un toque no mueve a Kael), sin los botones del panel, con «Saltar»; la
#      cámara se mueve y Kael, Lya y Garon se quedan quietos en sitios válidos.
#   3. Al terminar: la cámara de juego, el panel y el control vuelven, y se abre la conversación PV-07.
#   4. Visita posterior: en el mirador no vuelve a empezar.
#   5. Saltarla (con Escape): termina al momento, deja la cámara de juego y la conversación, y no suena nada más.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ARCHIVO := "user://prueba_mirador.save"
const ESPERA_MAX_MS := 40000

var frames := 0
var paso := 0
var t_paso := 0
var f_paso := 0
var R
var P
var D
var r
var pos_kael := Vector3.ZERO
var notas_al_saltar := 0
var abierto_en := -1
var fallos: Array = []


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	P = load("res://progreso.gd")
	if not load("res://modo3d.gd").activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true, "pv_06": true})
	Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	_cargar()


func _cargar() -> void:
	change_scene_to_file(REGION)
	r = null
	_siguiente()


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	_borrar()
	quit(1)


func _siguiente() -> void:
	paso += 1
	t_paso = Time.get_ticks_msec()
	f_paso = frames


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _region_lista(n: int) -> bool:
	if _escena() == REGION and not R.cambiando and frames - f_paso >= n:
		r = current_scene
		return true
	return false


# Kael, junto al camino al sur del mirador, anda hacia el centinela.
func _ir_al_mirador(teletransporte := false) -> void:
	var c: Vector3 = r.CENTINELA
	var desde := Vector3(1.5, 0, -3.5)
	var hasta := Vector3(1.5, 0, -7.8)
	if teletransporte:
		r._colocar_kael(Vector3(hasta.x, r.altura(hasta.x, hasta.z), hasta.z))
	else:
		r._colocar_kael(Vector3(desde.x, r.altura(desde.x, desde.z), desde.z))
		r.destino = r._ajustar_destino(Vector3(hasta.x, r.altura(hasta.x, hasta.z), hasta.z))
	if _plana(hasta, c) > r.RADIO_CENTINELA:
		fallos.append("el punto de llegada no está en el mirador")


func _cerrar_dialogo() -> bool:
	if D.current_timeline == null or r.dialogo_actual != "pv_07":
		return false
	if abierto_en < 0:
		abierto_en = frames
	if frames - abierto_en < 10:
		return false
	D.end_timeline()
	abierto_en = -1
	return true


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo("el paso %d no terminó en %d s" % [paso, ESPERA_MAX_MS / 1000])
		return false
	match paso:
		1:
			if _region_lista(10):
				_ir_al_mirador()
				_siguiente()
		2:                                          # 1. llega andando y empieza
			if r.cinematica:
				_al_empezar()
			elif frames - f_paso > 600:
				_fallo("la cinemática no empezó al llegar al mirador (Kael en %s)" % r.kael.global_position)
		3:                                          # 2. a mitad
			if frames - f_paso == 150:
				_a_mitad()
		4:                                          # 3. al terminar
			if not r.cinematica:
				_al_terminar()
			elif frames - f_paso > 600:
				_fallo("la cinemática no terminó")
		5:
			if _cerrar_dialogo():
				_siguiente()
		6:                                          # el control vuelve
			if D.current_timeline == null and r._bloqueo_accion <= 0.0 and frames - f_paso >= 5:
				pos_kael = r.kael.global_position
				r.destino = r._ajustar_destino(pos_kael + Vector3(0, 0, 3.0))
				_siguiente()
		7:
			if frames - f_paso == 30:
				if _plana(r.kael.global_position, pos_kael) < 0.5:
					fallos.append("3: tras la cinemática, Kael no se puede mover")
				else:
					print("OK 3: tras la conversación, Kael vuelve a andar")
				_cargar()                           # 4. visita posterior
		8:
			if _region_lista(10):
				_ir_al_mirador(true)
				_siguiente()
		9:
			if frames - f_paso == 45:
				if r.cinematica or r.cinematicas_vistas != 0 or D.current_timeline != null:
					fallos.append("4: en una visita posterior la cinemática o la conversación vuelven a empezar")
				else:
					print("OK 4: en una visita posterior no vuelve a empezar")
				var h: Dictionary = Engine.get_meta("hitos")
				h.erase("pv_07")                    # 5. otra vez desde el principio, para saltarla
				Engine.set_meta("hitos", h)
				_cargar()
		10:
			if _region_lista(10):
				_ir_al_mirador(true)
				_siguiente()
		11:
			if r.cinematica and frames - f_paso >= 40:
				_saltar()
			elif frames - f_paso > 300:
				_fallo("5: la cinemática no empezó en la segunda pasada")
		12:
			if frames - f_paso == 5 and (D.current_timeline == null or r.dialogo_actual != "pv_07"):
				fallos.append("5: tras saltarla no se abre la conversación PV-07")
			if frames - f_paso == 90:
				if r._cine_notas != notas_al_saltar:
					fallos.append("5: tras saltarla siguen sonando campanas (%d → %d)" % [notas_al_saltar, r._cine_notas])
				else:
					print("OK 5: tras saltarla no suena nada más")
				_siguiente()
		13:
			if _cerrar_dialogo():
				return _terminar()
	return false


func _al_empezar() -> void:
	var guardada = P.leer(ARCHIVO)
	if not P.hito("pv_07") or guardada == null or not guardada.get("hitos", {}).has("pv_07"):
		fallos.append("1: el hito pv_07 no está puesto y guardado al empezar la cinemática")
	if r.cinematicas_vistas != 1 or r.destino != null:
		fallos.append("1: la cinemática empezó %d veces o Kael sigue andando" % r.cinematicas_vistas)
	if r.info.get_parent().visible or not r._cine_capa.visible or not r._cine_saltar.visible:
		fallos.append("2: se ven los botones del panel o no se ve «Saltar»")
	pos_kael = r.kael.global_position
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = Vector2(640, 400)
	r._unhandled_input(toque)
	if r.destino != null:
		fallos.append("2: durante la cinemática, un toque mueve a Kael")
	print("OK 1: empieza al llegar andando (Kael en %s); pv_07 ya guardado; sin control" % pos_kael.snapped(Vector3.ONE * 0.1))
	_siguiente()


func _a_mitad() -> void:
	var juego: Transform3D = r._camara_juego()
	var lejos: float = r.cam.global_position.distance_to(juego.origin)
	if lejos < 3.0:
		fallos.append("2: la cámara no se ha movido (%.1f m de la de juego)" % lejos)
	if _plana(r.kael.global_position, pos_kael) > 0.05:
		fallos.append("2: Kael se ha movido durante la cinemática")
	var delante: Vector3 = r.kael.global_position         # cada uno, cerca del de delante (Lya de Kael, Garon de Lya)
	var dists: Array = []
	for n in r.grupo.nodos():
		var d := _plana(n.global_position, delante)
		dists.append("%s %.2f m" % [n.name, d])
		if d > 2.4 or r._prohibido(n.global_position):
			fallos.append("2: %s está a %.2f m del de delante o en una zona prohibida" % [n.name, d])
		delante = n.global_position
	print("OK 2: a mitad, la cámara está a %.1f m de la de juego; Kael y el grupo, quietos (%s)" % [lejos, ", ".join(dists)])
	_siguiente()


func _al_terminar() -> void:
	var juego: Transform3D = r._camara_juego()
	if r.cam.global_position.distance_to(juego.origin) > 0.2:
		fallos.append("3: la cámara no vuelve a la de juego (a %.2f m)" % r.cam.global_position.distance_to(juego.origin))
	if not r.info.get_parent().visible or r._cine_capa.visible:
		fallos.append("3: no vuelve el panel o sigue la interfaz de la cinemática")
	if D.current_timeline == null or r.dialogo_actual != "pv_07":
		fallos.append("3: al terminar no empieza la conversación PV-07")
	print("OK 3: termina con la cámara de juego y la conversación PV-07 (%d campanas)" % r._cine_notas)
	_siguiente()


func _saltar() -> void:
	notas_al_saltar = r._cine_notas
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	r._unhandled_input(escape)
	var juego: Transform3D = r._camara_juego()
	if r.cinematica or r.cam.global_position.distance_to(juego.origin) > 0.2:
		fallos.append("5: al saltarla no termina al momento con la cámara de juego")
	if r.dialogo_actual != "pv_07":                  # Dialogic abre el diálogo un fotograma después (paso 12)
		fallos.append("5: al saltarla no se pide la conversación PV-07")
	if r.cinematicas_vistas != 1 or not P.hito("pv_07"):
		fallos.append("5: al saltarla, la cinemática empezó %d veces o falta el hito" % r.cinematicas_vistas)
	print("OK 5: se salta con Escape tras %.1f s; conversación PV-07 abierta" % r._cine_t)
	_siguiente()


func _terminar() -> bool:
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
