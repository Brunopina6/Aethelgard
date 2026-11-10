extends SceneTree
# Recorrido real del final de la misión de Pastos Verdes 3D, con el combate del centinela jugado de verdad (sin
# victoria simulada). Con «-- 3d sin_prologo auto»: en el combate, cada héroe ataca solo en su turno (combate.gd).
# El guardado automático escribe en el archivo propio de la prueba (user://prueba_centinela.save).
#   1. Tras hablar con Tilo (PV-05), Kael llega andando al mirador: PV-06 y el combate fijo «pastos_centinela».
#   2. El combate se juega entero con el grupo inicial. Se gana, se reparten experiencia y monedas, se guarda y se
#      vuelve al mirador.
#   3. Allí empieza la cinemática y después PV-07. El objetivo pasa a «Vuelve a hablar con Tilo».
#   4. Tilo: PV-14 y la mecha. El objetivo pasa al de la aventura del bosque (fase 3: «Habla con Tilo…»).
#   5. Salir al mapa y volver a entrar, y cargar la partida guardada: todo sigue igual y nada se repite.
# Alcance: un combate con ataques automáticos (sin magias ni objetos); no prueba la estrategia de un jugador.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ARCHIVO := "user://prueba_centinela.save"
const ESPERA_MAX_MS := 120000

var frames := 0
var paso := 0
var t_paso := 0
var f_paso := 0
var f_combate := 0
var R
var P
var D
var gr
var inv
var exp_antes := 0
var oro_antes := 0
var abierto_en := -1
# Tras PV-14 empieza «El bosque que no recuerda» (fase 3, zonas3d/bosque_pastos.gd): el objetivo lleva a Tilo.
const TRAS_PV14 := "Habla con Tilo: algo le pasa al árbol de su puesto."

var fallos: Array = []


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	P = load("res://progreso.gd")
	gr = load("res://grupo.gd")
	inv = load("res://inventario.gd")
	if not load("res://modo3d.gd").activo() or not "auto" in OS.get_cmdline_user_args():
		_fallo("faltan «-- 3d» o «auto»")
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})
	Engine.set_meta("combates_ganados", {})
	for n in gr.datos():
		exp_antes += int(gr.datos()[n]["exp"]) + 1000 * int(gr.datos()[n]["nivel"])
	oro_antes = inv.oro()
	change_scene_to_file(REGION)
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


func _en(escena: String, n := 10) -> bool:
	return _escena() == escena and not R.cambiando and frames - f_paso >= n


func _cerrar(id: String) -> bool:
	if D.current_timeline == null or _escena() != REGION or current_scene.dialogo_actual != id:
		abierto_en = -1
		return false
	if abierto_en < 0:
		abierto_en = frames
	if frames - abierto_en < 10:
		return false
	D.end_timeline()
	abierto_en = -1
	print("OK diálogo %s" % id)
	return true


func _listo() -> bool:
	return _en(REGION, 5) and D.current_timeline == null and current_scene._bloqueo_accion <= 0.0 and not current_scene.cinematica


func _objetivo(r) -> String:
	return r.objetivo.text.trim_prefix("Objetivo: ")


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo("el paso %d no terminó en %d s (escena %s)" % [paso, ESPERA_MAX_MS / 1000, _escena()])
		return false
	var r = current_scene
	match paso:
		1:
			if _en(REGION):
				print("objetivo al entrar: «%s»" % _objetivo(r))
				var desde := Vector3(1.5, 0, -3.5)
				var hasta := Vector3(1.5, 0, -7.8)
				r._colocar_kael(Vector3(desde.x, r.altura(desde.x, desde.z), desde.z))
				r.destino = r._ajustar_destino(Vector3(hasta.x, r.altura(hasta.x, hasta.z), hasta.z))
				_siguiente()
		2:                                          # 1. PV-06 y al combate
			if _cerrar("pv_06"):
				_siguiente()
			elif frames - f_paso > 900:
				_fallo("al llegar al mirador no empezó PV-06")
		3:
			if _en("res://combate.tscn", 5):
				if r.combate_fijo != "pastos_centinela":
					_fallo("el combate no es el del centinela («%s»)" % r.combate_fijo)
					return false
				print("OK 1: combate fijo del centinela con %s contra %s" % [r.heroes.map(func(h): return h["nombre"]),
					r.enemigos.map(func(e): return e["nombre"])])
				f_combate = frames
				_siguiente()
		4:                                          # 2. el combate, entero
			if _en(REGION, 2):
				_tras_combate(r)
				_siguiente()
		5:                                          # 3. la cinemática
			if r.cinematica and frames - f_paso >= 2:
				print("OK 3: al volver al mirador empieza la cinemática")
				_siguiente()
			elif frames - f_paso > 120:
				_fallo("al volver del combate no empezó la cinemática")
		6:
			if _cerrar("pv_07"):
				_siguiente()
		7:
			if _listo():
				if _objetivo(r) != "Vuelve a hablar con Tilo." or r.marcador == null or not r.marcador.visible:
					fallos.append("3: tras PV-07, el objetivo es «%s»" % _objetivo(r))
				var q: Vector3 = r.tilo.global_position + Vector3(1.0, 0, 0.6)
				r._colocar_kael(Vector3(q.x, r.altura(q.x, q.z), q.z))
				_siguiente()
		8:                                          # 4. Tilo
			if _listo() and frames - f_paso >= 3:
				r._accion()
				_siguiente()
		9:
			if _cerrar("pv_14"):
				_siguiente()
		10:
			if _listo():
				if not P.hito("mecha_tilo") or _objetivo(r) != TRAS_PV14:
					fallos.append("4: tras PV-14, mecha=%s y objetivo «%s»" % [P.hito("mecha_tilo"), _objetivo(r)])
				else:
					print("OK 4: PV-14, la mecha y el objetivo «%s»" % _objetivo(r))
				r._salir()
				_siguiente()
		11:                                         # 5. al mapa y de vuelta
			if _en("res://mapa.tscn", 5):
				change_scene_to_file(REGION)
				_siguiente()
		12:
			if _listo() and frames - f_paso >= 30:
				_comprobar_estado(r, "al volver a entrar")
				for k in P.CLAVES:
					if Engine.has_meta(k):
						Engine.remove_meta(k)
				Engine.remove_meta("partida_lista")
				if P.cargar() == "":
					_fallo("no se pudo cargar la partida guardada")
					return false
				change_scene_to_file(REGION)
				_siguiente()
		13:
			if _listo() and frames - f_paso >= 30:
				_comprobar_estado(r, "al cargar la partida")
				return _terminar()
	return false


func _tras_combate(r) -> void:
	var segundos := (frames - f_combate) / 30.0
	var exp_despues := 0
	for n in gr.datos():
		exp_despues += int(gr.datos()[n]["exp"]) + 1000 * int(gr.datos()[n]["nivel"])
	var guardada = P.leer(ARCHIVO)
	if not P.ganado("pastos_centinela"):
		_fallo("2: el grupo inicial NO gana el combate del centinela con ataques automáticos (%.0f s de juego)" % segundos)
		return
	if exp_despues <= exp_antes or inv.oro() <= oro_antes:
		fallos.append("2: tras ganar no sube la experiencia (%d → %d) o el oro (%d → %d)" % [exp_antes, exp_despues, oro_antes, inv.oro()])
	if guardada == null or not guardada.get("combates_ganados", {}).has("pastos_centinela"):
		fallos.append("2: la partida guardada tras el combate no lo lleva ganado")
	print("OK 2: combate ganado en %.0f s de juego; oro %d → %d; la partida guardada lo lleva" % [segundos, oro_antes, inv.oro()])
	if _escena() == REGION and Vector2(r.kael.global_position.x - r.CENTINELA.x, r.kael.global_position.z - r.CENTINELA.z).length() > r.RADIO_CENTINELA:
		fallos.append("2: tras el combate, Kael no vuelve al mirador")


func _comprobar_estado(r, cuando: String) -> void:
	var ok: bool = P.hito("pv_07") and P.hito("pv_14") and P.ganado("pastos_centinela") and not r.cinematica \
		and r.cinematicas_vistas == 0 and _objetivo(r) == TRAS_PV14 \
		and (r.marcador == null or not r.marcador.visible) and r.grupo.nodos().size() == 2
	if ok:
		print("OK 5 (%s): misión terminada, sin cinemática ni marcador, con Lya y Garon" % cuando)
	else:
		fallos.append("5 (%s): el estado no se conserva (objetivo «%s», cinemática %s, grupo %d)" % [cuando, _objetivo(r),
			r.cinematica, r.grupo.nodos().size()])


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
