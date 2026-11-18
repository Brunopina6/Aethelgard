extends SceneTree
# «El bosque que no recuerda» jugado en la región de verdad (Pastos Verdes 3D, «-- 3d sin_prologo»), con la misión del
# corte alfa ya hecha (hasta pv_14) y el grupo de tres. Kael se coloca junto a cada cosa y se pulsa el botón de acción,
# como haría el jugador; los diálogos se cierran con Dialogic.end_timeline (su final de siempre).
#   1. Inicio: el objetivo pide hablar con Tilo; Tilo abre bq_tilo_1 → bq_inicio.
#   2. El árbol marcado → bq_arbol y la alquimia abierta (botón ALQUIMIA con Lya en el grupo).
#   3. Las tres pistas en sitios distintos (lirios, surcos e inscripción); las ramas no se abren sin la pista del rastro;
#      con ella Garon abre la senda (aparecen las ruinas, el manantial, el cofre y más materiales); con las tres, la
#      conclusión de Lya (bq_pistas). El objetivo cuenta las pistas.
#   4. Materiales: los nueve puntos, cada uno una vez (4 Hierba lunar, 3 Musgo, 2 Savia).
#   5. Manantial: cura y, la primera vez, +1 Hierba lunar; la segunda, nada más. El cofre de la senda, una vez.
#   6. Alquimia en su pantalla: estudiar «Concentración arcana», fabricar Esencia y Poción (gastan lo suyo), investigar
#      «La savia que recuerda» (dos combates ganados la completan) y fabricar el Elixir.
#   7. El Guardián: al llegar al claro, su diálogo y el combate fijo (pastos_guardian, grupo 11).
#   8. Persistencia: lo hecho va en lo que se guarda; con el desenlace «purificado» y la región recargada, el claro
#      está en flor, sale el diálogo del desenlace y Tilo y el objetivo cambian.
# Datos aislados; la partida en memoria.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const B := preload("res://combate_bosque.gd")

var fallos := 0
var D
var R
var Inv
var P


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	Inv = load("res://inventario.gd")
	P = load("res://progreso.gd")
	var h := {}
	for id in ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo"]:
		h[id] = true
	h["enc_perro_pedido"] = true                       # V9: el encargo de Pip, ya pedido
	Engine.set_meta("hitos", h)
	Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	Engine.set_meta("cofres_abiertos", {})
	for k in ["inventario", "investigaciones", "decisiones", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	load("res://grupo.gd").unir("Lya")
	load("res://grupo.gd").unir("Garon")
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


# (15/11) espera por RELOJ, solo para las cargas en segundo plano (Recursos.cambiar_escena): con --fixed-fps los
# fotogramas vuelan y la carga tarda en tiempo real; contando fotogramas, en una batería cargada fallaba «8: la región
# no vuelve a cargarse». (El resto de la prueba espera en tiempo de JUEGO a propósito: diálogos y combate.)
func _hasta_reloj(cond: Callable, segundos := 60.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(segundos * 1000.0):
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _region_lista() -> bool:
	return current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando


# Coloca a Kael junto al punto y pulsa el botón de acción si ofrece «esperado». Cierra el diálogo que se abra.
func _usar(r, id: String, esperado: String) -> bool:
	var nodo: Node3D = null
	for p in r.bosque.puntos:
		if p["id"] == id and is_instance_valid(p["nodo"]):
			nodo = p["nodo"]
	if nodo == null and id == "tilo":
		nodo = r.tilo
	if nodo == null:
		_fallo("no está «%s»" % id)
		return false
	r._colocar_kael(nodo.global_position + Vector3(0.9, 0, 0.0))
	await _esperar(3)
	r._bloqueo_accion = 0.0
	r._comprobar_cerca()
	if r.cerca != esperado:
		_fallo("junto a «%s» el botón es «%s» y se esperaba «%s»" % [id, r.cerca, esperado])
		return false
	r._accion()
	await _esperar(3)
	await _cerrar_dialogos()
	return true


func _cerrar_dialogos() -> void:
	for vez in 4:                                        # un diálogo puede encadenar otro (bq_pistas)
		if await _hasta(func(): return D.current_timeline != null, 1.0):
			await _esperar(5)
			D.end_timeline()
			await _hasta(func(): return D.current_timeline == null, 5.0)
			await _esperar(5)


func _probar() -> void:
	if not await _hasta(_region_lista, 90.0):
		_fallo("no se llega a la región")
		quit(1)
		return
	await _esperar(20)
	await _cerrar_dialogos()
	var r = current_scene
	if r.bosque == null:
		_fallo("la región no tiene la aventura")
		quit(1)
		return
	await _hasta(func(): return r.bosque.puntos.size() > 0, 5.0)
	# 1. inicio
	if not r.texto_objetivo().contains("Tilo"):
		_fallo("1: el objetivo no lleva a Tilo («%s»)" % r.texto_objetivo())
	await _usar(r, "tilo", "tilo")
	if not P.hito("bq_inicio"):
		_fallo("1: hablar con Tilo no empieza la aventura")
	# 2. el árbol
	await _usar(r, "arbol", "bq:arbol")
	if not P.hito("bq_arbol") or not P.hito("bq_alquimia"):
		_fallo("2: examinar el árbol no pone bq_arbol y bq_alquimia")
	if not r.bosque.puede_alquimia():
		_fallo("2: la alquimia no se abre con Lya en el grupo")
	if r.texto_objetivo() != "Busca más señales del olvido (0/3).":
		_fallo("2: objetivo «%s»" % r.texto_objetivo())
	# 3. pistas y senda
	await _usar(r, "ramas", "bq:ramas")
	if P.hito("bq_senda"):
		_fallo("3: la senda se abre sin la pista del rastro")
	await _usar(r, "lirios", "bq:lirios")
	await _usar(r, "surcos", "bq:surcos")
	if not P.hito("bq_pista_planta") or not P.hito("bq_pista_rastro"):
		_fallo("3: faltan las pistas de los lirios o de los surcos")
	if not r.texto_objetivo().contains("(2/3)"):
		_fallo("3: el objetivo no cuenta 2 pistas («%s»)" % r.texto_objetivo())
	var lirios: Vector3 = _pos(r, "lirios")
	var surcos: Vector3 = _pos(r, "surcos")
	await _usar(r, "ramas", "bq:ramas")
	if not P.hito("bq_senda"):
		_fallo("3: con la pista del rastro y Garon, las ramas no se apartan")
	for id in ["inscripcion", "manantial", "cofre_senda", "orbe", "rec:bq_rec_hierba_4", "rec:bq_rec_musgo_3", "rec:bq_rec_savia_2"]:
		if _pos(r, id) == Vector3.INF:
			_fallo("3: tras abrir la senda no aparece «%s»" % id)
	var insc: Vector3 = _pos(r, "inscripcion")
	await _usar(r, "inscripcion", "bq:inscripcion")
	if not P.hito("bq_pista_inscripcion") or not P.hito("bq_pistas"):
		_fallo("3: la inscripción no completa las pistas (bq_pistas)")
	if lirios.distance_to(surcos) < 8.0 or surcos.distance_to(insc) < 8.0 or lirios.distance_to(insc) < 8.0:
		_fallo("3: las pistas están demasiado juntas (%s, %s, %s)" % [lirios, surcos, insc])
	# 3c. el encargo de Pip (V9): huellas y Canela en las ruinas, tras la senda
	await _usar(r, "huellas_0", "bq:huellas_0")
	if not P.hito("enc_perro_huellas"):
		_fallo("3c: las huellas no se apuntan")
	await _usar(r, "perro", "bq:perro")
	if not P.hito("enc_perro_encontrado") or r.bosque.canela == null:
		_fallo("3c: encontrar a Canela no la apunta o no os sigue")
	# 3b. el orbe del altar (V9): dos visiones, una tras otra; con las dos, bq_futuros
	await _usar(r, "orbe", "bq:orbe")
	if not P.hito("bq_orbe_a") or P.hito("bq_orbe_b"):
		_fallo("3b: la primera mirada al orbe no muestra solo el primer futuro")
	await _usar(r, "orbe", "bq:orbe")
	if not P.hito("bq_orbe_b") or not P.hito("bq_futuros"):
		_fallo("3b: la segunda mirada no muestra el segundo futuro (bq_futuros)")
	if r.bosque._velo != null:
		_fallo("3b: el velo de la visión no se quita al terminar")
	# 4. materiales
	for rec in r.bosque.RECOLECCION:
		await _usar(r, "rec:" + rec[0], "bq:rec:" + rec[0])
	for par in [["Hierba lunar", 4], ["Musgo de piedra", 3], ["Savia clara", 2]]:
		if Inv.cantidad(par[0]) != par[1]:
			_fallo("4: %s: %d y se esperaban %d" % [par[0], Inv.cantidad(par[0]), par[1]])
	if _pos(r, "rec:bq_rec_hierba_1") != Vector3.INF:
		_fallo("4: un punto recogido sigue ahí")
	# 5. manantial y cofre
	await _usar(r, "manantial", "bq:manantial")
	await _usar(r, "manantial", "bq:manantial")
	if Inv.cantidad("Hierba lunar") != 5:
		_fallo("5: el manantial da %d Hierba lunar en total (debía dar 1, una vez)" % (Inv.cantidad("Hierba lunar") - 4))
	var oro: int = Inv.oro()
	await _usar(r, "cofre_senda", "bq:cofre_senda")
	if Inv.cantidad(B.ESENCIA) != 1 or Inv.oro() != oro + 60 or _pos(r, "cofre_senda") != Vector3.INF:
		_fallo("5: el cofre de la senda no da una Esencia y 60 monedas una vez")
	# 6. alquimia
	r.bosque.abrir_alquimia()
	await _esperar(3)
	var a = r.bosque.alquimia
	if a == null or not a.is_inside_tree():
		_fallo("6: la pantalla de alquimia no se abre")
	else:
		if not r.ocupado():
			_fallo("6: con la alquimia abierta Kael no se queda quieto (ocupado)")
		a._fabricar("esencia_enfoque")
		if Inv.cantidad(B.ESENCIA) != 1:
			_fallo("6: se fabricó la Esencia sin investigarla")
		a._investigar("lya_enfoque")
		a._fabricar("esencia_enfoque")
		if Inv.cantidad(B.ESENCIA) != 2 or Inv.cantidad("Musgo de piedra") != 2 or Inv.cantidad("Hierba lunar") != 4:
			_fallo("6: la Esencia no gasta o no da lo suyo")
		var pociones: int = Inv.cantidad("Poción")
		a._fabricar("pocion_restauradora")
		if Inv.cantidad("Poción") != pociones + 1 or Inv.cantidad("Hierba lunar") != 2:
			_fallo("6: la Poción no gasta o no da lo suyo")
		a._investigar("lya_savia")
		var pv: int = int(Engine.get_meta("investigaciones", {}).get("lya_savia", {}).get("progreso", 0))
		if pv != 1:
			_fallo("6: lo visto en el orbe no adelanta un paso (progreso %d)" % pv)
		if load("res://investigacion.gd").estado("lya_savia") != "en_curso":
			_fallo("6: «La savia que recuerda» no empieza")
		load("res://investigacion.gd").avanzar_en_curso()     # dos combates ganados (combate.gd, _fin_combate)
		load("res://investigacion.gd").avanzar_en_curso()
		a._fabricar("elixir_savia")
		if Inv.cantidad(B.ELIXIR) != 1 or Inv.cantidad("Savia clara") != 1:
			_fallo("6: el Elixir no se fabrica con la investigación completada")
		for p in ["Recetas", "Investigar", "Materiales"]:  # las tres pestañas se pintan sin errores
			a.pestana = p
			a._pintar()
			await _esperar(2)
		a.cerrar_menu()
		await _esperar(3)
		if r.bosque.alquimia != null:
			_fallo("6: la alquimia no se cierra")
	# 8 (antes de irse al combate). lo que se guarda
	var d: Dictionary = P.volcar(REGION)
	for h in ["bq_inicio", "bq_arbol", "bq_senda", "bq_pistas", "bq_rec_savia_2", "bq_cofre_senda"]:
		if not d.get("hitos", {}).get(h, false):
			_fallo("8: no se guarda el hito %s" % h)
	if not d.get("investigaciones", {}).get("lya_savia", {}).get("completada", false):
		_fallo("8: no se guarda la investigación completada")
	# 7. el Guardián
	var claro: Vector3 = r.bosque.guardian.global_position if r.bosque.guardian != null else Vector3.INF
	if claro == Vector3.INF:
		_fallo("7: no está el Guardián dormido")
	else:
		r._colocar_kael(claro + Vector3(8.0, 0, 0))
		await _esperar(5)
		r._colocar_kael(claro + Vector3(1.5, 0, 0))
		var hubo := await _hasta(func(): return D.current_timeline != null, 3.0)
		if not hubo:
			_fallo("7: al llegar al claro no empieza bq_guardian")
		await _cerrar_dialogos()
		await _esperar(3)
		if Engine.get_meta("combate_fijo", "") != B.COMBATE or Engine.get_meta("grupo_combate", -1) != 11:
			_fallo("7: tras su diálogo no empieza el combate fijo del Guardián")
		if not P.hito("bq_guardian_visto"):
			_fallo("7: falta bq_guardian_visto")
	# 8. el desenlace, al volver (la región recargada, como tras el combate)
	_t0_8 = Time.get_ticks_msec()
	_f0_8 = Engine.get_process_frames()
	# (no capturar «r»: se libera al recargar y la condición daría «Lambda capture… was freed»). El id se toma AQUÍ, con
	# la región viva: tras el combate «r» ya está liberada y get_instance_id() daba 0 (la comprobación no comparaba nada).
	var id_vieja := r.get_instance_id()
	await _hasta(func(): return R.cambiando, 3.0)
	# (18/11) el combate se monta en segundo plano: se espera por RELOJ a que acabe. Contando fotogramas (30 s de juego =
	# 900 fotogramas, que con --fixed-fps pasan en unos 2 s reales), en un PC cargado se pedía la región con el cambio
	# al combate aún en curso; Recursos.cambiar_escena ignora lo que se le pide mientras cambia, el combate se montaba
	# después y la región no llegaba nunca: «8: la región no vuelve a cargarse» (docs/v12/BOSQUE_RECARGA_18_11.md).
	await _hasta_reloj(func(): return not R.cambiando, 60.0)
	B.apuntar("purificado")
	P.poner_hito("bq_resuelto")
	P.poner_hito("bq_purificado")
	Engine.set_meta("pos_3d_ok", false)
	var al_pedir := _estado_8("al pedir la región", id_vieja)
	if R.cambiando:
		_fallo("8: el cambio al combate sigue en curso tras 60 s: la región se pediría y se ignoraría")
		print(al_pedir)
	R.cambiar_escena(REGION)
	if not await _hasta_reloj(func(): return _region_lista() and current_scene.get_instance_id() != id_vieja and current_scene.has_method("texto_objetivo"), 60.0):
		_fallo("8: la región no vuelve a cargarse")
		print(al_pedir)
		print(_estado_8("tras la espera", id_vieja))
	else:
		r = current_scene
		await _hasta(func(): return r.bosque.puntos.size() > 0, 5.0)
		var final := await _hasta(func(): return D.current_timeline != null, 5.0)
		if not final:
			_fallo("8: no sale el diálogo del desenlace al volver")
		await _cerrar_dialogos()
		if not P.hito("bq_final_visto"):
			_fallo("8: el diálogo del desenlace no queda visto")
		if r.bosque.get_node_or_null("bq_claro_purificado") == null:
			_fallo("8: el claro no está en flor tras purificarlo")
		if r.bosque.dialogo_tilo() != "bq_tilo_purificado":
			_fallo("8: Tilo no cambia tras purificarlo (%s)" % r.bosque.dialogo_tilo())
		if not r.texto_objetivo().contains("Encina"):
			_fallo("8: el objetivo no lleva a Oakhaven («%s»)" % r.texto_objetivo())
		if _pos(r, "lirios") != Vector3.INF:
			_fallo("8: las pistas siguen tras resolverlo")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# (18/11) Volcado del paso 8, para que un fallo de la recarga se explique solo (docs/v12/BOSQUE_RECARGA_18_11.md): el
# cambio de escena en curso, la escena actual (ruta e id), lo que cuelga de root, las cargas en hilo y el tiempo real y
# los fotogramas desde que empieza el combate del Guardián.
var _t0_8 := 0
var _f0_8 := 0


func _estado_8(momento: String, id_vieja: int) -> String:
	var esc := current_scene
	var hilo := []
	for ruta in R._en_hilo.keys():
		hilo.append("%s=%d" % [ruta, ResourceLoader.load_threaded_get_status(ruta)])
	var escenas := []
	for n in root.get_children():
		if n.scene_file_path != "":
			escenas.append("%s#%d" % [n.scene_file_path, n.get_instance_id()])
	return ("VOLCADO 8 (%s): %d ms reales y %d fotogramas desde el combate del Guardián · R.cambiando=%s · " \
		+ "texto_carga=«%s» · negro=%s · escena=%s#%d (vieja #%d, texto_objetivo=%s) · en root: %s · " \
		+ "hilo (0 nada, 1 cargando, 2 fallo, 3 cargado): región=%d combate=%d · precargas: %s · combate_fijo=%s") % [
		momento, Time.get_ticks_msec() - _t0_8, Engine.get_process_frames() - _f0_8, R.cambiando, R.texto_carga,
		R.negro.visible, esc.scene_file_path if esc != null else "(ninguna)",
		esc.get_instance_id() if esc != null else 0, id_vieja,
		esc != null and esc.has_method("texto_objetivo"), escenas,
		ResourceLoader.load_threaded_get_status(REGION), ResourceLoader.load_threaded_get_status(R.ESCENA_COMBATE),
		hilo, Engine.get_meta("combate_fijo", "")]


func _pos(r, id: String) -> Vector3:
	for p in r.bosque.puntos:
		if p["id"] == id and is_instance_valid(p["nodo"]):
			return p["nodo"].global_position
	return Vector3.INF
