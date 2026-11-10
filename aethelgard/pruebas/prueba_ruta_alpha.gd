extends SceneTree
# Prueba de la misión del corte alfa en la región 3D de Pastos Verdes (PV-02 → PV-14), con «-- 3d sin_prologo»:
#   PV-02 al entrar → PV-03 en el camino → Tilo (PV-05 y su recordatorio) → la estela (detalle de lore) →
#   el centinela (PV-06 y combate fijo «pastos_centinela», con combate.tscn de verdad) → vuelta tras ganarlo
#   (la victoria se simula en combates_ganados) → PV-07 → Tilo (PV-14 y la mecha) → Tilo (despedida) →
#   los hitos se guardarían y se recuperan.
# Cada diálogo se abre de verdad con Dialogic y se cierra por código (Dialogic.end_timeline, que avisa al terminar,
# quizá un fotograma después). No escribe archivos.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ESPERA_MAX_MS := 60000
const PAUSA := 20                        # fotogramas entre acciones (pasa el bloqueo de 0,35 s tras un diálogo)

var frames := 0
var paso := 0
var t_paso := 0
var f_paso := 0
var R
var D
var P


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	P = load("res://progreso.gd")
	if D == null:
		_fallo("no está Dialogic")
		return
	if not load("res://modo3d.gd").activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		return
	Engine.set_meta("hitos", {})
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("lore_visto", {})
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	_siguiente()


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	quit(1)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _siguiente() -> void:
	paso += 1
	t_paso = Time.get_ticks_msec()
	f_paso = frames


# La escena es la esperada, ya no se está cambiando de escena, han pasado «espera» fotogramas desde el paso anterior y
# no queda ningún diálogo abierto (Dialogic termina de cerrarse uno o dos fotogramas después de end_timeline).
func _listo(escena: String, espera := PAUSA) -> bool:
	if _escena() != escena or R.cambiando or frames - f_paso < espera or D.current_timeline != null:
		return false
	# tras cerrar un diálogo, la región ignora la acción 0,35 s (la misma pulsación no abre otro)
	return not ("_bloqueo_accion" in current_scene) or current_scene._bloqueo_accion <= 0.0


func _dialogo() -> String:
	if D.current_timeline == null or _escena() != REGION:
		return ""
	return current_scene.dialogo_actual


# Cierra el diálogo abierto si es el esperado, comprobando que puso su hito. Lo deja abierto 10 fotogramas antes:
# cerrarlo en el mismo instante en que empieza deja a Dialogic a medio arrancar (no pasa jugando: nadie cierra un
# diálogo antes de que aparezca).
var abierto_en := -1


func _cerrar(id: String, hito := "") -> bool:
	if _dialogo() != id:
		abierto_en = -1
		return false
	if abierto_en < 0:
		abierto_en = frames
	if frames - abierto_en < 10:
		return false
	if hito != "" and not P.hito(hito):
		_fallo("el diálogo %s no puso el hito %s" % [id, hito])
		return false
	D.end_timeline()
	abierto_en = -1
	print("OK %s" % id)
	_siguiente()
	return true


# El objetivo que se ve arriba a la izquierda y si hay rombo dorado sobre Tilo o el centinela.
func _objetivo_es(r, texto: String, con_marcador: bool) -> bool:
	if not r.objetivo.visible or r.objetivo.text != "Objetivo: " + texto:
		_fallo("el objetivo es «%s» (visible=%s) y no «%s»" % [r.objetivo.text, r.objetivo.visible, texto])
		return false
	var hay: bool = r.marcador != null and r.marcador.visible
	if hay != con_marcador:
		_fallo("con el objetivo «%s», marcador=%s y se esperaba %s" % [texto, hay, con_marcador])
		return false
	print("OK objetivo: «%s»%s" % [texto, " con marcador" if hay else ""])
	return true


# Quién acompaña a Kael en este momento de la misión, y que esté en un sitio válido no muy lejos de él.
func _grupo_es(r, esperado: Array) -> bool:
	var nodos: Array = r.grupo.nodos() if r.grupo != null else []
	var nombres: Array = nodos.map(func(n): return String(n.name))
	if nombres != esperado:
		_fallo("el grupo es %s y no %s" % [nombres, esperado])
		return false
	for n in nodos:
		var d := Vector2(n.global_position.x - r.kael.global_position.x, n.global_position.z - r.kael.global_position.z).length()
		if r._prohibido(n.global_position) or d > 8.0:
			_fallo("%s está a %.1f m de Kael o en una zona prohibida (%s)" % [n.name, d, n.global_position])
			return false
	print("OK grupo: %s" % (str(nombres) if not nombres.is_empty() else "Kael solo"))
	return true


func _junto_a(p: Vector3, desvio := Vector3(1.0, 0, 0.6)) -> void:
	var r = current_scene
	var q: Vector3 = p + desvio
	r._colocar_kael(Vector3(q.x, r.altura(q.x, q.z), q.z))


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo("el paso %d no terminó en %d s (escena=%s, diálogo=%s)" % [paso, ESPERA_MAX_MS / 1000, _escena(), _dialogo()])
		return false
	var r = current_scene
	match paso:
		1:                               # PV-02 sale solo al entrar
			_cerrar("pv_02", "pv_02")
		2:                               # PV-03 en el camino
			if _listo(REGION):
				if not _grupo_es(r, []):           # Kael llega solo: Lya se une en PV-03 y Garon en PV-05
					return false
				if not _objetivo_es(r, "Sigue el camino.", false):
					return false
				_junto_a(r.SENDERO[2], Vector3.ZERO)
				_siguiente()
		3:
			_cerrar("pv_03", "pv_03")
		4:                               # Tilo: PV-05
			if _listo(REGION):
				if not _grupo_es(r, ["Lya"]):
					return false
				if not _objetivo_es(r, "Sigue el camino hasta el puente.", true):
					return false
				_junto_a(r.tilo.global_position)
				_siguiente()
		5:
			if _listo(REGION, 3):
				if not r.boton_accion.visible or r.boton_accion.text != "Hablar con Tilo":
					_fallo("junto a Tilo no aparece «Hablar con Tilo» («%s»; ocupado=%s, timeline=%s, kael=%s, tilo=%s, cerca=«%s», saliendo=%s)" % [
						r.boton_accion.text, r.ocupado(), "%s estado=%s actual=«%s»" % [D.current_timeline.resource_path if D.current_timeline else "-", D.current_state, r.dialogo_actual], r.kael.global_position, r.tilo.global_position,
						r.cerca, r.saliendo])
					return false
				r._accion()
				_siguiente()
		6:
			_cerrar("pv_05", "pv_05")
		7:                               # Tilo otra vez: el recordatorio, sin hito
			if _listo(REGION):
				if not _grupo_es(r, ["Lya", "Garon"]):
					return false
				if not _objetivo_es(r, "Saluda al centinela del mirador.", true):
					return false
				r._accion()
				_siguiente()
		8:
			_cerrar("pv_tilo")
		9:                               # la estela
			if _listo(REGION):
				_junto_a(r.estela.global_position)
				_siguiente()
		10:
			if _listo(REGION, 3):
				if not r.boton_accion.visible or r.boton_accion.text != "Examinar":
					_fallo("junto a la estela no aparece «Examinar»")
					return false
				r._accion()
				if not P.visto(r.ID_ESTELA):
					_fallo("la estela no apuntó su detalle de lore")
					return false
				print("OK estela (detalle de lore apuntado)")
				_siguiente()
		11:                              # el centinela: PV-06
			if _listo(REGION):
				_junto_a(r.CENTINELA, Vector3(-2.0, 0, 0.5))
				_siguiente()
		12:
			_cerrar("pv_06", "pv_06")
		13:                              # al cerrarse PV-06 se prepara el combate fijo
			if _escena() == REGION and Engine.get_meta("combate_fijo", "") == r.COMBATE_CENTINELA:
				if Engine.get_meta("grupo_combate", -1) != r.GRUPO_CENTINELA:
					_fallo("el combate del centinela no usa el grupo %d" % r.GRUPO_CENTINELA)
					return false
				print("OK combate fijo %s (grupo %d)" % [r.COMBATE_CENTINELA, r.GRUPO_CENTINELA])
				_siguiente()
		14:
			if _listo("res://combate.tscn", 5):
				if r.combate_fijo != "pastos_centinela":
					_fallo("el combate no es el fijo del centinela («%s»)" % r.combate_fijo)
					return false
				var g: Dictionary = Engine.get_meta("combates_ganados", {})
				g["pastos_centinela"] = true     # victoria simulada
				Engine.set_meta("combates_ganados", g)
				r._volver_al_mapa()
				_siguiente()
		15:                              # vuelta junto al centinela: PV-07
			_cerrar("pv_07", "pv_07")
		16:                              # Tilo: PV-14 y la mecha
			if _listo(REGION):
				if not _objetivo_es(r, "Vuelve a hablar con Tilo.", true):
					return false
				_junto_a(r.tilo.global_position)
				_siguiente()
		17:
			if _listo(REGION, 3):
				r._accion()
				_siguiente()
		18:
			_cerrar("pv_14", "pv_14")
		19:                              # Tilo: despedida
			if _listo(REGION):
				if not P.hito("mecha_tilo"):
					_fallo("tras PV-14 no se apuntó la mecha de Tilo")
					return false
				r._accion()
				_siguiente()
		20:
			_cerrar("bq_tilo_1")                 # fase 3: tras PV-14, Tilo abre «El bosque que no recuerda»
		21:
			if _listo(REGION, 5):
				if not _objetivo_es(r, "Examina el árbol marcado.", false):   # (fase 3)
					return false
				return _comprobar_guardado()
	return false


func _comprobar_guardado() -> bool:
	var d: Dictionary = P.volcar(REGION)
	var h: Dictionary = d.get("hitos", {})
	for k in ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo"]:
		if not h.get(k, false):
			_fallo("la partida no guardaría el hito %s" % k)
			return false
	if not d.get("combates_ganados", {}).has("pastos_centinela") or not d.get("lore_visto", {}).has("pastos_estela"):
		_fallo("la partida no guardaría el centinela o la estela")
		return false
	Engine.set_meta("hitos", {})
	P.restaurar(d)
	if not P.hito("pv_14"):
		_fallo("los hitos no vuelven al cargar")
		return false
	print("OK guardado: los hitos, el combate ganado y la estela se guardarían y vuelven al cargar")
	print("OK misión del corte alfa de Pastos Verdes")
	return true
