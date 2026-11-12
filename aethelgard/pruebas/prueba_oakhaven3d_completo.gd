extends SceneTree
# V12, migración de Oakhaven (12/11): Oakhaven 3D completa, cada sistema de la ciudad 2D reintegrado en la 3D, como un
# jugador (Kael anda, se le ofrece el botón, lo pulsa) y con la partida que usa la 2D (mismas claves).
#   0. modo3d: la 3D por defecto con la exploración 3D; la 2D con «oakhaven2d» o elegida en Ajustes; partidas de la 2D en
#      la 3D (la ronda en alto, la colina sobre el altozano) y de la 3D en la 2D elegida, en la misma casilla.
#   1. La ciudad entera: 7 vecinos aquí + la posadera + Ferro, Hilda y Mirta (11), 4 cofres, 5 notas, las piezas, los
#      detalles, los barrios; todo lo que se usa se alcanza andando; ninguna rutina cae en un bloqueo.
#   2. Cada vecino abre su diálogo de siempre (Oak.dialogo_de).
#   3. «Tres favores para el Cuervo»: la posadera (Hablar en su panel), el barril, Rosa y Pip, y la recompensa una vez.
#   4. «Los faroles de la ronda»: Bastián, la torre (sube en alto, la vista), el adarve andando, los tres faroles (se
#      encienden), el cofre de la ronda, bajar y volver con Bastián. De la ronda no se cae.
#   5. «Un secreto por una moneda» y el Patio de las Velas: Pip cobra, la grieta (el muro no se cruza andando), el cofre y
#      la nota del altar, y salir por la grieta.
#   6. Las raíces (la vista), el Árbol (la Rama Milenaria), su cofre y la raíz cortada.
#   7. La colina: se sube andando por la rampa, Albar, el sello del crematorio (detalle de canon) y el borde del altozano.
#   8. Los requisados: cerrado hasta que Kael ha salido (pv_02); después, su premio y su nota.
#   9. Las notas que quedan, el tapiz, el gremio (y los braseros), las parejas, la tienda, el barril (las Gemelas), las
#      páginas de Mirta y la lavanda de Rosa.
#  10. La hora: el anochecer mueve a los que pasean; dormir trae la mañana y cada uno a su sitio.
#  11. Guardar y volver en la ronda; y la misma partida abierta en la ciudad 2D: cofres abiertos, faroles y casilla.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_oakhaven3d_completo.gd --fixed-fps 30 -- 3d sin_prologo
# No toca ninguna partida: progreso.gd no guarda durante las pruebas; Ajustes, en user:// aislado (y se deja como estaba).

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const CIUDAD := "res://ciudad_oakhaven.tscn"
var M = load("res://modo3d.gd")
var P = load("res://progreso.gd")
var I = load("res://inventario.gd")
var Oak = load("res://ciudades/oakhaven.gd")
var Vida = load("res://ciudades/oakhaven_vida.gd")
var B = load("res://zonas3d/oakhaven/barrios.gd")
var H = load("res://hallazgos.gd")
var S = load("res://zonas3d/oakhaven/posada3d.gd")
var v
var dg
var fallos := 0


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(t: String) -> void:
	print("OK " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto", "hitos", "decisiones", "gremio",
			"oak_franja", "oak_franja_t", "pos_3d", "pos_zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)


func _cargar() -> void:
	change_scene_to_file(REGION)
	await _frames(25)
	v = current_scene
	dg = root.get_node_or_null("Dialogic")


# Kael en p (con el grupo detrás), sin andar.
func _kael(p: Vector3) -> void:
	v.en_posada = false
	v._colocar_kael(p)
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)
	await _frames(3)


# Kael anda hasta p (destino tocado). true si llega.
func _andar(p: Vector3, maximo := 400) -> bool:
	v.destino = v._ajustar_destino(p)
	for i in maximo:
		await process_frame
		if Vector2(v.kael.global_position.x - p.x, v.kael.global_position.z - p.z).length() < 0.4:
			return true
		if v.destino == null:
			v.destino = v._ajustar_destino(p)
			if i > 40 and Vector2(v.kael.global_position.x - p.x, v.kael.global_position.z - p.z).length() >= 0.4:
				return false
	return false


# Se ofrece «id» donde está Kael, y se pulsa.
func _usar(id: String, que: String) -> bool:
	v._bloqueo = 0.0
	v._comprobar_cerca()
	if v.cerca != id:
		_mal("%s: no se ofrece «%s» (cerca = «%s», Kael en %s)" % [que, id, v.cerca, str(v.kael.global_position.snapped(Vector3.ONE * 0.01))])
		return false
	v._accion()
	await _frames(2)
	return true


func _fin_dialogo() -> void:
	if dg != null and dg.current_timeline != null:
		dg.end_timeline()
	for i in 150:                                         # (Dialogic tarda unos fotogramas en cerrar)
		if dg == null or dg.current_timeline == null:
			break
		await process_frame
	await _frames(4)


func _senal(s: String) -> void:
	dg.signal_event.emit(s)
	await _frames(1)


func _estado(k: String) -> bool:
	return P.estado(Oak.NOMBRE, k)


func _abierto(id: String) -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(id)


func _correr() -> void:
	await _frames(2)
	_parte0()
	_limpiar()
	await _cargar()
	await _parte1()
	await _parte2()
	await _parte3()
	await _parte4()
	await _parte5()
	await _parte6()
	await _parte7()
	await _parte8()
	await _parte9()
	await _parte10()
	await _parte11()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= 0

func _parte0() -> void:
	if not M.region_activa_con(0, PackedStringArray(["3d"]), false):
		_mal("0: Oakhaven 3D no va por defecto con la exploración 3D")
	if M.region_activa_con(0, PackedStringArray(["3d", "oakhaven2d"]), false):
		_mal("0: con «oakhaven2d» sigue la 3D")
	if not M.region_activa_con(0, PackedStringArray(["3d", "oakhaven3d", "oakhaven2d"]), false):
		_mal("0: «oakhaven3d» no manda sobre «oakhaven2d»")
	if M.region_activa_con(0, PackedStringArray([]), false):
		_mal("0: Oakhaven 3D sin la exploración 3D")
	var habia := FileAccess.file_exists(M.AJUSTES)
	var antes = M.eleccion("oakhaven3d")
	M.elegir("oakhaven3d", false)
	if M.region_activa(0):
		_mal("0: con la 2D elegida en Ajustes sigue la 3D")
	# una partida guardada en la 3D (en la colina) con la 2D elegida: la 2D, en la misma casilla
	Engine.set_meta("pos_3d", Vector3(63.0, 1.2, 17.0))
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", 0)
	var e: String = M.escena_equivalente(REGION)
	var pz = Engine.get_meta("pos_zona", null)
	if e != CIUDAD or not Engine.get_meta("pos_zona_ok", false) or not pz is Vector2 or (pz as Vector2).distance_to(Vector2(63, 17) * 64.0) > 1.0:
		_mal("0: la partida de la 3D no abre la 2D en la misma casilla (%s, %s)" % [e, str(pz)])
	else:
		_ok("0a: con la 2D elegida, una partida de la colina 3D abre la 2D en la casilla %s" % str((pz as Vector2) / 64.0))
	M.elegir("oakhaven3d", true)
	if not M.region_activa(0):
		_mal("0: con la 3D elegida no se usa la 3D")
	# partidas de la 2D en la 3D: la ronda (en alto), la colina (sobre el altozano), la plaza
	for caso in [[Vector2(76.5, 35.0), B.ALTO_RONDA], [Vector2(63.0, 17.0), B.ALTO_COLINA], [Vector2(40.0, 29.0), 0.0]]:
		Engine.set_meta("pos_zona", caso[0] * 64.0)
		Engine.set_meta("pos_zona_ok", true)
		Engine.set_meta("pos_zona_lugar", 0)
		var r: String = M.escena_equivalente(CIUDAD)
		var p = Engine.get_meta("pos_3d", null)
		if r != REGION or not p is Vector3 or absf((p as Vector3).y - caso[1]) > 0.01 or Vector2(p.x, p.z).distance_to(caso[0]) > 0.6:
			_mal("0: la partida de la 2D en %s no lleva al sitio equivalente de la 3D (%s, %s)" % [str(caso[0]), r, str(p)])
	_ok("0b: partidas de la 2D en la 3D: la ronda en alto, la colina sobre el altozano y la plaza")
	# Ajustes como estaban
	if not habia:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(M.AJUSTES))
	elif antes == null:
		var c := ConfigFile.new()
		c.load(M.AJUSTES)
		c.erase_section_key("regiones", "oakhaven3d")
		c.save(M.AJUSTES)
	else:
		M.elegir("oakhaven3d", antes)
	_ok("0: 3D por defecto, 2D elegible (argumento y Ajustes)")


# ================================================================= 1

func _parte1() -> void:
	if v == null or v.scene_file_path != REGION or v.vida == null or v.barrios == null:
		_mal("1: no carga Oakhaven 3D completa")
		return
	var vecinos: Array = v.vida.vecinos.keys()
	var oficios: Array = v.distrito.pnj.keys() if v.distrito != null else []
	var todos := vecinos + oficios + (["posadera"] if v.sala.posadera != null else [])
	for n in Oak.NPCS:
		if not n["id"] in todos:
			_mal("1: falta el vecino «%s»" % n["id"])
	if v.vida.cofres.size() != Oak.COFRES.size() or v.vida.notas.size() != 5:
		_mal("1: cofres %d (de %d) y notas %d (de 5)" % [v.vida.cofres.size(), Oak.COFRES.size(), v.vida.notas.size()])
	if v.barrios.figuras.size() < 7 or not v.barrios.plantillas.has("plantilla_cofre_base"):
		_mal("1: faltan figuras o plantillas en los barrios (%s)" % str(v.barrios.resumen()))
	# todo lo que se usa se alcanza (a su altura, desde algún sitio donde se puede estar)
	var sin := []
	for pz in v._piezas_al_alcance():
		var p: Vector3 = pz[1]
		if p.x > 150.0:
			continue
		var ok := false
		for k in 24:
			var q: Vector3 = p + Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * (0.5 + 0.35 * (k / 8))
			q.y = p.y
			if not v._prohibido(q) and Vector2(q.x - p.x, q.z - p.z).length() < pz[2]:
				ok = true
				break
		if not ok:
			sin.append(pz[0])
	if not sin.is_empty():
		_mal("1: no se alcanza: %s" % str(sin))
	# las rutinas (cada franja, su sitio y el final de su paseo) no caen en un bloqueo
	for id in vecinos:
		for f in Vida.FRANJAS:
			var r: Dictionary = v.vida.rutina_3d(id, f)
			for c in [r["casilla"], r.get("hasta", r["casilla"])]:
				if v._prohibido(v.vida.sitio(c)):
					_mal("1: la rutina de %s (%s) cae en un sitio prohibido %s" % [id, f, str(c)])
	var piezas_oak := 0
	for pz in v._piezas_al_alcance():
		if String(pz[0]).begins_with("pieza:"):
			piezas_oak += 1
	_ok("1: %d vecinos en la ciudad (%s), %d cofres, %d notas, %d piezas a mano, barrios %s" % [todos.size(), str(todos),
		v.vida.cofres.size(), v.vida.notas.size(), piezas_oak, str(v.barrios.resumen())])


# ================================================================= 2

func _parte2() -> void:
	var abiertos := 0
	for id in v.vida.vecinos:
		var n: Node3D = v.vida.vecinos[id]["nodo"]
		await _kael(n.position + Vector3(0, 0, 1.2))
		var esperado: String = Oak.dialogo_de(id, int(v.vida.vecinos[id]["veces"]))
		if not await _usar(id, "2 " + id):
			continue
		if dg == null or dg.current_timeline == null or v.dialogo_actual != esperado:
			_mal("2: %s no abre su diálogo (%s, se esperaba %s)" % [id, v.dialogo_actual, esperado])
		else:
			abiertos += 1
		await _fin_dialogo()
	_ok("2: %d de 7 vecinos abren su diálogo de siempre" % abiertos)


# ================================================================= 3

func _parte3() -> void:
	# la posadera, dentro: «Hablar» en su panel
	await _kael(S.ORIGEN + S.MOSTRADOR)
	v.en_posada = true
	await _frames(2)
	if not await _usar("posadera", "3 posadera"):
		return
	var hablar: Button = null
	for b in v.panel_servicios.get_child(0).get_children():
		if b is Button and b.get_meta("servicio", "") == "hablar":
			hablar = b
	if hablar == null:
		_mal("3: el panel de la posadera no tiene «Hablar»")
		return
	hablar.pressed.emit()
	await _frames(2)
	if dg.current_timeline == null:
		_mal("3: «Hablar» no abre el diálogo de la posadera")
	await _senal("oak:favores_aceptados")
	await _fin_dialogo()
	if not _estado("favores"):
		_mal("3: aceptar los favores no los empieza")
	v._salir_posada()
	await _frames(40)
	# el barril del Patio del Cuervo
	await _kael(Vector3(12.0, 0, 29.9))
	await _usar("pieza:oak_barril", "3 barril")
	# Rosa y Pip (sus diálogos de la misión, primero)
	for d in [["rosa", "oak_rosa_flores", "oak:favor_flores"], ["pip", "oak_pip_cucharon", "oak:favor_cucharon"]]:
		var n: Node3D = v.vida.vecinos[d[0]]["nodo"]
		await _kael(n.position + Vector3(0, 0, 1.2))
		await _usar(d[0], "3 " + d[0])
		if not String(v.dialogo_actual).ends_with(d[1] + ".dtl"):
			_mal("3: %s no abre «%s» (abre %s)" % [d[0], d[1], v.dialogo_actual])
		await _senal(d[2])
		await _fin_dialogo()
	if not (_estado("favor_barril") and _estado("favor_flores") and _estado("favor_cucharon")):
		_mal("3: faltan favores (barril %s, flores %s, cucharón %s)" % [_estado("favor_barril"), _estado("favor_flores"), _estado("favor_cucharon")])
	# vuelta con la posadera: la recompensa, una vez
	var pociones: int = I.cantidad("Poción")
	await _kael(S.ORIGEN + S.MOSTRADOR)
	v.en_posada = true
	await _frames(2)
	if String(v._hablar_posadera()).ends_with("oak_posadera_favores_fin.dtl"):
		await _senal("oak:favores_hechos")
		await _senal("oak:favores_hechos")                         # (dos veces: un solo premio)
	else:
		_mal("3: la posadera no cierra la misión (%s)" % v.dialogo_actual)
	await _fin_dialogo()
	if not P.hito("oak_favores") or not _estado("noche_gratis") or I.cantidad("Poción") != pociones + 2:
		_mal("3: la recompensa de los favores no llega una vez (hito %s, noche %s, pociones %d → %d)" % [P.hito("oak_favores"), _estado("noche_gratis"), pociones, I.cantidad("Poción")])
	else:
		_ok("3: «Tres favores para el Cuervo» en la 3D: barril, flores, cucharón, noche gratis y 2 Pociones (una vez)")
	v._salir_posada()
	await _frames(40)


# ================================================================= 4

func _parte4() -> void:
	var bas: Node3D = v.vida.vecinos["bastian"]["nodo"]
	for i in 3:                                             # sus diálogos se turnan hasta el de la ronda
		await _kael(bas.position + Vector3(0, 0, 1.2))
		await _usar("bastian", "4 bastián")
		var es_ronda := String(v.dialogo_actual).ends_with("oak_bastian_ronda.dtl")
		if es_ronda:
			await _senal("oak:faroles_aceptados")
		await _fin_dialogo()
		if es_ronda:
			break
	if not _estado("faroles"):
		_mal("4: Bastián no encarga los faroles")
		return
	await _kael(Vector3(73.5, 0, 43.4))
	await _usar("pieza:oak_torre", "4 torre")
	await _frames(45)
	if v.kael.global_position.y < B.EN_ALTO or not _estado("vista_torre"):
		_mal("4: subir a la torre no lleva a la ronda (Kael en %s)" % str(v.kael.global_position))
		return
	_ok("4a: la torre sube a la ronda (Kael en %s) y se ve la vista" % str(v.kael.global_position.snapped(Vector3.ONE * 0.1)))
	if not v._prohibido(Vector3(75.4, 4.0, 35.0)) or not v._prohibido(Vector3(79.0, 4.0, 35.0)):
		_mal("4: desde el adarve se puede salir por el pretil o las almenas")
	for i in [1, 2, 3]:
		var c: Vector2 = Oak.pieza("oak_farol_%d" % i)["casilla"]
		if not await _andar(Vector3(c.x, B.ALTO_RONDA, c.y + 0.6)):
			_mal("4: no llega andando al farol %d por el adarve (Kael en %s)" % [i, str(v.kael.global_position)])
		await _usar("pieza:oak_farol_%d" % i, "4 farol %d" % i)
		if not _estado("farol_%d" % i) or not v.barrios.faroles["farol_%d" % i].visible:
			_mal("4: el farol %d no se enciende" % i)
		if v.kael.global_position.y < B.EN_ALTO:
			_mal("4: Kael se cae de la ronda")
	var eter: int = I.cantidad("Éter")
	await _andar(Vector3(76.6, B.ALTO_RONDA, 29.4))
	await _usar("cofre:oak_cofre_ronda", "4 cofre de la ronda")
	if not _abierto("oak_cofre_ronda") or I.cantidad("Éter") != eter + 2:
		_mal("4: el cofre de la ronda no da 2 Éter")
	await _andar(Vector3(76.5, B.ALTO_RONDA, 41.0))
	await _usar("pieza:oak_ronda_bajar", "4 bajar")
	await _frames(45)
	if v.kael.global_position.y > 0.5 or v.kael.global_position.distance_to(Vector3(73.5, 0, 43.5)) > 1.0:
		_mal("4: bajar no deja a Kael al pie de la torre (%s)" % str(v.kael.global_position))
	await _kael(bas.position + Vector3(0, 0, 1.2))
	await _usar("bastian", "4 bastián, fin")
	await _senal("oak:faroles_hechos")
	await _fin_dialogo()
	if not P.hito("oak_faroles"):
		_mal("4: la misión de los faroles no se cierra")
	else:
		_ok("4: «Los faroles de la ronda»: torre, adarve andando, tres faroles encendidos, cofre (2 Éter), bajar y Bastián")


# ================================================================= 5

func _parte5() -> void:
	I.ganar_oro(50)
	var pip: Node3D = v.vida.vecinos["pip"]["nodo"]
	for i in 4:
		await _kael(pip.position + Vector3(0, 0, 1.2))
		await _usar("pip", "5 pip")
		var es := String(v.dialogo_actual).ends_with("oak_pip_secreto.dtl")
		var oro: int = I.oro()
		if es:
			await _senal("oak:pip_pagar")
			if I.oro() != oro - 1:
				_mal("5: Pip no cobra una moneda")
		await _fin_dialogo()
		if es:
			break
	if str(Engine.get_meta("decisiones", {}).get("pip_oak", "")) != "pagado":
		_mal("5: el secreto de Pip no queda pagado")
	# el muro del callejón no se cruza andando
	await _kael(Vector3(23.5, 0, 33.8))
	await _andar(Vector3(23.5, 0, 37.5), 120)
	if v.kael.global_position.z > 35.2:
		_mal("5: el muro del callejón se cruza andando (Kael en %s)" % str(v.kael.global_position))
	await _kael(Vector3(23.5, 0, 34.5))
	await _usar("pieza:oak_grieta", "5 grieta")
	await _frames(45)
	if v.kael.global_position.z < 36.0 or not _estado("grieta"):
		_mal("5: la grieta no pasa al Patio de las Velas (%s)" % str(v.kael.global_position))
	await _andar(Vector3(21.2, 0, 38.4))
	await _usar("cofre:oak_cofre_velas", "5 cofre de las velas")
	if not _abierto("oak_cofre_velas"):
		_mal("5: el cofre de las velas no se abre")
	await _andar(Vector3(25.5, 0, 39.3))
	await _usar("nota:nota_oak_velas", "5 altar")
	if not P.visto("nota_oak_velas"):
		_mal("5: la nota del altar no va al Diario")
	await _andar(Vector3(23.0, 0, 39.3))                    # (rodeando el altar)
	await _andar(Vector3(23.5, 0, 36.6))
	await _usar("pieza:oak_grieta", "5 grieta de vuelta")
	await _frames(45)
	if v.kael.global_position.z > 35.0:
		_mal("5: la grieta no devuelve al callejón (%s)" % str(v.kael.global_position))
	else:
		_ok("5: Pip cobra su secreto; el muro no se cruza; la grieta, el cofre, la nota del altar y vuelta")


# ================================================================= 6

func _parte6() -> void:
	await _kael(Vector3(40.0, 0, 19.0))
	if not await _andar(Vector3(40.0, 0, 10.0)):
		_mal("6: no se llega andando a las raíces")
	await _frames(3)
	if not _estado("vista_raices"):
		_mal("6: llegar a las raíces no da su vista")
	await _usar("arbol", "6 Árbol")
	var rama = H.hallazgo("hall_rama_milenaria")
	if not rama.is_empty() and H.disponible(rama) and not _abierto("hall_rama_milenaria"):
		_mal("6: el Árbol no da la Rama Milenaria")
	await _kael(Vector3(43.0, 0, 4.4))
	await _usar("cofre:oak_cofre_raices", "6 cofre de las raíces")
	if not _abierto("oak_cofre_raices"):
		_mal("6: el cofre de las raíces no se abre")
	await _kael(Vector3(45.0, 0, 11.0))
	await _usar("nota:nota_oak_anillos", "6 raíz cortada")
	if not P.visto("nota_oak_anillos"):
		_mal("6: la raíz cortada no va al Diario")
	else:
		_ok("6: raíces (vista), Árbol (Rama Milenaria: %s), cofre y raíz cortada" % _abierto("hall_rama_milenaria"))


# ================================================================= 7

func _parte7() -> void:
	await _kael(Vector3(65.0, 0, 26.2))
	if not await _andar(Vector3(65.0, 0, 17.6), 500) or absf(v.kael.global_position.y - B.ALTO_COLINA) > 0.1:
		_mal("7: no se sube andando a la colina (Kael en %s)" % str(v.kael.global_position))
		return
	_ok("7a: subida andando hasta el altozano (Kael en %s)" % str(v.kael.global_position.snapped(Vector3.ONE * 0.01)))
	var albar: Node3D = v.vida.vecinos["albar"]["nodo"]
	if absf(albar.position.y - B.ALTO_COLINA) > 0.05:
		_mal("7: Albar no está sobre el altozano (%s)" % str(albar.position))
	await _andar(albar.position + Vector3(0.8, 0, 1.0))
	await _usar("albar", "7 albar")
	await _fin_dialogo()
	await _andar(Vector3(67.0, B.ALTO_COLINA, 17.0))
	await _usar("detalle:oak_sello", "7 sello")
	if not P.visto("oak_sello"):
		_mal("7: el sello del crematorio no se apunta")
	await _andar(Vector3(60.0, B.ALTO_COLINA, 18.0))
	await _andar(Vector3(60.0, 0, 21.5), 120)
	if v.kael.global_position.z > 19.1 or v.kael.global_position.y < 1.0:
		_mal("7: se cae del altozano por el muro (Kael en %s)" % str(v.kael.global_position))
	await _kael(Vector3(65.0, 0, 18.5))
	if absf(v.kael.global_position.y - B.ALTO_COLINA) > 0.05:
		_mal("7: colocar a Kael en la colina no lo pone sobre el altozano (%s)" % str(v.kael.global_position))
	_ok("7: Albar, el sello y el borde del altozano")


# ================================================================= 8

func _parte8() -> void:
	await _kael(Vector3(47.0, 0, 52.0))
	await _usar("cofre:oak_cofre_requisados", "8 requisados")
	if _abierto("oak_cofre_requisados"):
		_mal("8: los requisados se abren antes de que Kael haya salido")
	P.poner_hito("pv_02")
	await _usar("cofre:oak_cofre_requisados", "8 requisados (tras salir)")
	if not _abierto("oak_cofre_requisados") or not P.visto("nota_oak_requisados"):
		_mal("8: los requisados no dan su premio y su nota")
	else:
		_ok("8: los requisados, cerrados mientras Aldric vigila; después, premio y nota")


# ================================================================= 9

func _parte9() -> void:
	for d in [["nota_oak_bando", Vector3(36.0, 0, 29.6)], ["nota_oak_cuervo", Vector3(13.0, 0, 26.2)],
			["nota_oak_guardia", Vector3(42.5, 0, 47.2)]]:
		await _kael(d[1])
		await _usar("nota:" + d[0], "9 " + d[0])
		if not P.visto(d[0]):
			_mal("9: la nota %s no va al Diario" % d[0])
	await _kael(Vector3(45.4, 0, 22.4))
	await _usar("detalle:oak_tapiz", "9 tapiz")
	if not P.visto("oak_tapiz"):
		_mal("9: el tapiz no se apunta")
	# el gremio y sus braseros
	await _kael(Vector3(37.0, 0, 23.6))
	await _usar("pieza:oak_tablon_gremio", "9 gremio")
	var g = v.vida.abierto
	if g == null or g.get_script() == null or not String(g.get_script().resource_path).ends_with("gremio_menu.gd") or not v.ocupado():
		_mal("9: el tablón no abre el gremio")
	elif g != null:
		g.cerrado.emit()
		g.queue_free()
	var gd: Dictionary = Engine.get_meta("gremio", {})
	if gd.is_empty():
		load("res://gremio.gd")._d()
		gd = Engine.get_meta("gremio", {})
	gd["proyectos"].append("pr_braseros")
	v.vida._poner_proyectos()
	if v.vida.obras.get("pr_braseros", []).size() != 2:
		_mal("9: el proyecto de los braseros no pone dos braseros")
	# las parejas
	await _kael(Vector3(14.4, 0, 31.6))
	await _usar("pieza:oak_mesa_parejas", "9 parejas")
	var j = v.vida.abierto
	if j == null or not String(j.get_script().resource_path).ends_with("taberna_parejas.gd"):
		_mal("9: la mesa no abre las parejas")
	elif j != null:
		j.cerrado.emit()
		j.queue_free()
	# la tienda del mercado
	await _kael(Vector3(54.0, 0, 31.0))
	await _usar("tienda", "9 tienda")
	var t = v.vida.abierto
	if t == null or t.get_child_count() == 0 or not String(t.get_child(0).get_script().resource_path).ends_with("tienda.gd"):
		_mal("9: el mercado no abre la tienda")
	elif t != null:
		t.get_child(0).cerrado.emit()
	await _frames(2)
	if v.vida.ocupado():
		_mal("9: cerrar la tienda no deja libre a Kael")
	# el barril, ya sin favor: las Gemelas de la Muralla
	await _kael(Vector3(12.0, 0, 29.9))
	await _usar("pieza:oak_barril", "9 barril")
	var gem = H.hallazgo("hall_gemelas_muralla")
	if not gem.is_empty() and H.disponible(gem) and not _abierto("hall_gemelas_muralla"):
		_mal("9: tras el barril no están las Gemelas de la Muralla")
	# las páginas de Mirta (tras hablar con Pip)
	P.poner_hito("enc_formula_pedido")
	P.poner_hito("enc_formula_pip")
	v.vida.actualizar()
	var pag: Vector2 = Oak.pieza("oak_pagina_2")["casilla"]
	await _kael(Vector3(pag.x + 0.8, 0, pag.y + 0.6))
	await _usar("pieza:oak_pagina_2", "9 página")
	if not _estado("pagina_2") or v.vida.paginas["oak_pagina_2"].visible:
		_mal("9: la página no se recoge")
	# la lavanda de Rosa
	P.poner_estado(Oak.NOMBRE, "lavanda")
	P.poner_estado(Oak.NOMBRE, "lavanda_cogida")
	var rosa: Node3D = v.vida.vecinos["rosa"]["nodo"]
	await _kael(rosa.position + Vector3(0, 0, 1.2))
	await _usar("rosa", "9 rosa lavanda")
	if String(v.dialogo_actual).ends_with("oak_rosa_lavanda_entrega.dtl"):
		await _senal("oak:lavanda_entregada")
	await _fin_dialogo()
	if not P.hito("oak_lavanda"):
		_mal("9: la lavanda no se entrega a Rosa (%s)" % v.dialogo_actual)
	_ok("9: notas, tapiz, gremio (y braseros), parejas, tienda, barril (Gemelas: %s), página y lavanda" % _abierto("hall_gemelas_muralla"))


# ================================================================= 10

func _parte10() -> void:
	v.vida.poner_franja("anochecer", true)
	var bas: Node3D = v.vida.vecinos["bastian"]["nodo"]
	var antes := bas.position
	await _frames(60)
	if bas.position.distance_to(antes) < 0.3:
		_mal("10: al anochecer Bastián no pasea")
	await _kael(S.ORIGEN + S.MOSTRADOR)
	v.en_posada = true
	I.ganar_oro(100)
	v._servicio("dormir")
	await _frames(70)
	await _fin_dialogo()
	var aldric: Node3D = v.vida.vecinos["aldric"]["nodo"]
	var r: Dictionary = Vida.rutina("aldric", "manana")
	if v.vida.franja != "manana" or Engine.get_meta("oak_franja", "") != "manana" or Vector2(aldric.position.x, aldric.position.z).distance_to(r["casilla"]) > 0.3:
		_mal("10: dormir no trae la mañana con cada uno a su sitio (franja %s, Aldric %s)" % [v.vida.franja, str(aldric.position)])
	else:
		_ok("10: el anochecer mueve a los que pasean; dormir trae la mañana (Aldric en %s)" % str(r["casilla"]))
	v._salir_posada()
	await _frames(40)


# ================================================================= 11

func _parte11() -> void:
	await _kael(Vector3(76.8, B.ALTO_RONDA, 33.0))
	v.guardar_posicion()
	var p: Vector3 = Engine.get_meta("pos_3d")
	await _cargar()
	if v.kael.global_position.distance_to(p) > 0.3:
		_mal("11: al volver, Kael no está en la ronda (%s ≠ %s)" % [str(v.kael.global_position), str(p)])
	else:
		_ok("11a: guardar en la ronda y volver deja a Kael en lo alto")
	if not v.barrios.faroles["farol_1"].visible or not v.vida.cofres["oak_cofre_ronda"]["abierto"]:
		_mal("11: al volver, los faroles o el cofre de la ronda no siguen como estaban")
	# la misma partida, en la ciudad 2D (la casilla de la plaza)
	Engine.set_meta("pos_zona", v.posicion_a_2d(Vector3(40.0, 0, 29.0)))
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file(CIUDAD)
	await _frames(30)
	var c = current_scene
	if c == null or c.scene_file_path != CIUDAD:
		_mal("11: no abre la ciudad 2D")
		return
	if c.jugador.position.distance_to(Vector2(40.0, 29.0) * 64.0) > 2.0:
		_mal("11: en la 2D, Kael no está en la casilla de la 3D (%s)" % str(c.jugador.position / 64.0))
	var abiertos := 0
	for e in c.cofres:
		if Oak.cofre(e[1]).is_empty():
			continue
		if e[2]:
			abiertos += 1
	if abiertos != 4:
		_mal("11: en la 2D solo %d de 4 cofres de la 3D salen abiertos" % abiertos)
	if not P.hito("oak_favores") or not P.hito("oak_faroles") or not P.estado(Oak.NOMBRE, "farol_3"):
		_mal("11: en la 2D no siguen las misiones hechas en la 3D")
	_ok("11: la misma partida en la ciudad 2D: casilla de la plaza, %d cofres abiertos, misiones y faroles" % abiertos)
