extends RefCounted
# Invocación cinematográfica de Érebo: vídeo prerenderizado (V12, 14/11/2026). Documentación en
# docs/v12/EREBO_CINEMATICA_V12.md.
# · EXPERIMENTAL y APAGADA por defecto. Solo en la APK de Auditoría o en el editor: Ajustes → «Érebo: invocación
#   cinematográfica» (No / Abreviada / Completa / Completa la primera vez). Se guarda en [calidad_pruebas] erebo_cine
#   de user://ajustes.cfg. No toca la partida.
# · La invocación de siempre (invocacion_erebo.gd / _nueva.gd con _teatro_erebo) queda intacta: es la predeterminada y,
#   si el vídeo falta o no se puede reproducir, se usa ella.
# · Este archivo solo REPRODUCE el vídeo. El dado, el daño y el turno los pone combate.gd, una sola vez, como siempre.
# · Pruebas: argumentos «erebo_cine=no|abreviada|completa|primera» (mandan sobre el ajuste).

const CLAVE := "erebo_cine"
const CLAVE_VISTA := "erebo_cine_vista"
const MODOS := ["no", "abreviada", "completa", "primera"]
const COMPLETA := "res://videos/erebo_invocacion_completa.ogv"
const ABREVIADA := "res://videos/erebo_invocacion_abreviada.ogv"
const BUS := "Efectos"            # la invocación suena en Efectos («pasos, golpes, cofres e invocaciones»)
const BAJA_MUSICA_DB := -18.0     # la música del combate se aparta mientras suena el vídeo (y vuelve igual)
const FUNDIDO_ENTRADA := 0.25
const FUNDIDO_SALIDA := 0.4       # el vídeo acaba en un destello blanco violáceo; el combate aparece desde él
const COLOR_DESTELLO := Color(0.93, 0.88, 1.0)
# Segundos de ATB que da la invocación de siempre (tiempo de juego desde que se elige el enemigo hasta el final, menos
# los 0,7 s finales que el vídeo también tiene), medidos el 14/11 con pruebas/medir_erebo_teatro.gd (--fixed-fps 30):
# de siempre 19,69 / 14,35 s y «Ladrón de Corazones» 15,11 / 12,45 s (éxito / fallo).
const ATB_TEATRO := {"siempre": {"exito": 18.99, "fallo": 13.65}, "nueva": {"exito": 14.41, "fallo": 11.75}}


static func atb_teatro(nueva: bool, exito: bool) -> float:
	return float(ATB_TEATRO["nueva" if nueva else "siempre"]["exito" if exito else "fallo"])


static func permitido() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor")


static func modo() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("erebo_cine="):
			var m := a.substr(11)
			return m if m in MODOS else "no"
	if not permitido():
		return "no"
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return "no"
	var m := str(c.get_value("calidad_pruebas", CLAVE, "no"))
	return m if m in MODOS else "no"


static func elegir(m: String) -> Error:
	if not permitido() or not m in MODOS:
		return ERR_UNAUTHORIZED
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("calidad_pruebas", CLAVE, m)
	return c.save("user://ajustes.cfg")


static func vista() -> bool:
	var c := ConfigFile.new()
	return c.load("user://ajustes.cfg") == OK and bool(c.get_value("calidad_pruebas", CLAVE_VISTA, false))


static func _marcar_vista() -> void:
	if not permitido():
		return
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg") and c.load("user://ajustes.cfg") != OK:
		return
	c.set_value("calidad_pruebas", CLAVE_VISTA, true)
	c.save("user://ajustes.cfg")


# La ruta del vídeo que toca ahora, o "" si se usa la invocación de siempre.
static func ruta_para_ahora() -> String:
	var ruta := ""
	match modo():
		"abreviada":
			ruta = ABREVIADA
		"completa":
			ruta = COMPLETA
		"primera":
			ruta = ABREVIADA if vista() else COMPLETA
	if ruta == "" or not ResourceLoader.exists(ruta):
		return ""
	return ruta


# Reproduce el vídeo a pantalla completa por encima del combate. «saltar» es un Callable que devuelve true cuando el
# jugador toca para saltar. Devuelve false si no se pudo reproducir (entonces combate.gd usa el teatro de siempre).
# Nada de lo que hace aquí cambia reglas, daño, turnos ni el ATB.
static func reproducir(padre: Node, ruta: String, saltar: Callable) -> bool:
	var stream = load(ruta)
	if not (stream is VideoStream):
		push_warning("Érebo (vídeo): no se pudo cargar %s; se usa la invocación de siempre" % ruta)
		return false
	var arbol := padre.get_tree()
	var capa := CanvasLayer.new()
	capa.layer = 60
	capa.name = "EreboCinematica"
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	negro.modulate.a = 0.0
	var vp := VideoStreamPlayer.new()
	vp.stream = stream
	vp.expand = true
	vp.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.bus = BUS
	vp.visible = false
	var destello := ColorRect.new()
	destello.color = COLOR_DESTELLO
	destello.set_anchors_preset(Control.PRESET_FULL_RECT)
	destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destello.modulate.a = 0.0
	capa.add_child(negro)
	capa.add_child(vp)
	capa.add_child(destello)
	padre.add_child(capa)
	# la música del combate se aparta (y vuelve a su volumen exacto pase lo que pase)
	var i_mus := AudioServer.get_bus_index("Musica")
	var db_mus := AudioServer.get_bus_volume_db(i_mus) if i_mus >= 0 else 0.0
	if i_mus >= 0:
		AudioServer.set_bus_volume_db(i_mus, db_mus + BAJA_MUSICA_DB)
	var restaurar := func():
		if i_mus >= 0:
			AudioServer.set_bus_volume_db(i_mus, db_mus)
	capa.tree_exiting.connect(restaurar)

	var tw := padre.create_tween()
	tw.tween_property(negro, "modulate:a", 1.0, FUNDIDO_ENTRADA)
	await tw.finished
	# saltar durante el fundido de entrada cuenta como saltar el vídeo (no como fallo: no hay teatro detrás)
	var saltado_pronto: bool = saltar.call()
	if not saltado_pronto and is_instance_valid(vp):
		vp.visible = true
		vp.play()
	var largo: float = vp.get_stream_length() if is_instance_valid(vp) else 0.0
	var t := 0.0
	var arranco := false
	while not saltado_pronto and is_instance_valid(vp) and not saltar.call():
		await arbol.process_frame
		if not is_instance_valid(vp):
			break
		t += arbol.root.get_process_delta_time() if arbol.root != null else 1.0 / 60.0
		if vp.is_playing():
			arranco = true
		elif arranco or t > 1.5:
			break                                    # terminó (o nunca arrancó)
		if largo > 0.0 and t > largo + 2.0:
			break                                    # (salvaguarda: nunca se queda colgado)
	var ok := arranco or saltado_pronto
	if is_instance_valid(vp):
		vp.stop()
	if arranco and modo() == "primera":
		_marcar_vista()
	# salida: desde el destello (fin natural) o desde negro (saltar o fallo); el combate aparece debajo
	if is_instance_valid(capa):
		destello.modulate.a = 1.0 if arranco and not saltar.call() else 0.0
		vp.visible = false
		var tw2 := padre.create_tween()
		tw2.tween_property(destello, "modulate:a", 0.0, FUNDIDO_SALIDA)
		tw2.parallel().tween_property(negro, "modulate:a", 0.0, FUNDIDO_SALIDA)
		await tw2.finished
		restaurar.call()
		if is_instance_valid(capa):
			capa.queue_free()
	if not ok:
		push_warning("Érebo (vídeo): %s no llegó a reproducirse; se usa la invocación de siempre" % ruta)
	return ok
