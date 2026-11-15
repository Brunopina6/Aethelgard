extends SceneTree
# V12 (14/11/2026): el BANCO DE PRUEBAS de Auditoría (banco_pruebas.gd). Sin ventana, con datos aislados.
#   A. Al entrar: la partida va a su archivo propio, se rehace desde BASE (Kael, Lya y Garon en Oakhaven) y la pantalla
#      tiene sus 9 selectores (15/11: + «Calidad 3D» y «Muestra: precalentar») (V12, Érebo híbrida: «Érebo: invocación») y sus 10 casos (7 combates y 3
#      exploraciones; 15/11: + «Grupo de cuatro»).
#   B. Combates: cada caso fija su grupo y sus enemigos; Érebo con la Armonía llena (y solo Lya puede invocar); vida de
#      los enemigos multiplicada; el Custodio aparece con su interruptor de sesión; Nix entra solo en su caso.
#      15/11: «Grupo de cuatro» pone a Kael, Lya, Garon y Nix en el combate con el permiso de sesión «banco_grupo4»
#      (grupo.gd, max_activos); sin él, o fuera del banco, los mismos cuatro nombres dejan TRES (MAX_ACTIVOS sigue en 3), y
#      los demás casos no lo heredan.
#   C. Nada permanente: lo ganado en un combate (oro, experiencia, objetos, contratos) desaparece al volver al banco.
#   D. Guardar dentro del banco escribe SOLO en su archivo; los de las partidas de siempre no cambian (ni existen si no
#      existían).
#   E. Salir del banco: sin partida en memoria, sin interruptores de sesión, sin su archivo y sin la etiqueta.
#   F. Fuera del banco: el gancho del combate no hace nada; en Ajustes no sale «Volver al banco de pruebas» (dentro, sí).
#   G. Los selectores escriben en Ajustes lo mismo que la pestaña Ajustes (y la misión del cantero se enciende con él).
#   I. (15/11) La CALIDAD es de la sesión: dentro del banco, lo que el regulador o Ajustes guardan en [calidad] y lo que
#      se registra NO llega a user://ajustes.cfg ni a user://calidad.log (calidad_auto.gd, aislada()), pero sí se aplica
#      (el escalón baja la escala 3D); cada caso empieza con los ajustes reales; el selector «Calidad 3D» fija el perfil
#      (bajo: 3D ×0,75) o lo deja al regulador; al salir no queda ninguna meta de calidad ni CSV de medida del banco.

const BP_RUTA := "res://banco_pruebas.gd"
var BP
var P
var G
var fallos: Array = []
var hechos: Array = []
var ajustes_antes = null


func _initialize() -> void:
	BP = load(BP_RUTA)
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _huella(ruta: String) -> String:
	return FileAccess.get_sha256(ruta) if FileAccess.file_exists(ruta) else "(no existe)"


func _probar() -> void:
	await _esperar(5)
	if FileAccess.file_exists("user://ajustes.cfg"):
		ajustes_antes = FileAccess.get_file_as_bytes("user://ajustes.cfg")
	var reales := {}
	for r in [P.GUARDADO, P.GUARDADO_EXP, P.GUARDADO + ".bak", P.GUARDADO_EXP + ".bak"]:
		reales[r] = _huella(r)
	_ok(BP.permitido(), "A: el banco no está permitido en el editor")
	await _a()
	await _b()
	_c()
	_d()
	await _f()
	_g()
	await _h()
	await _i()
	await _e()
	for r in reales:
		_ok(_huella(r) == reales[r], "D: la partida de siempre %s cambió" % r)
	hechos.append("D: las partidas de siempre (%d archivos) no cambian" % reales.size())
	if ajustes_antes != null:                        # deja Ajustes como estaba
		var f := FileAccess.open("user://ajustes.cfg", FileAccess.WRITE)
		f.store_buffer(ajustes_antes)
		f.close()
	elif FileAccess.file_exists("user://ajustes.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ajustes.cfg"))
	print("OK: ", "\n    ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= A
func _a() -> void:
	var b = load(BP.ESCENA).instantiate()
	root.add_child(b)
	await _esperar(3)
	_ok(P.archivo() == BP.ARCHIVO, "A: dentro del banco la partida va a %s" % P.archivo())
	_ok(BP.en_banco(), "A: en_banco() no es cierto dentro")
	_ok(G.activos() == ["Kael", "Lya", "Garon"], "A: grupo de partida %s" % str(G.activos()))
	var esperada: String = "res://zonas3d/oakhaven_3d.tscn" if load("res://modo3d.gd").activo() else P.MAPA   # (sin 3D, el mapa)
	_ok(b.escena_base == esperada, "A: la exploración lleva a %s y no a %s" % [b.escena_base, esperada])
	var casos := 0
	var selectores := {}
	for x in _botones(b):
		var k: String = x.get_meta("clave", "")
		if k.begins_with("caso:"):
			casos += 1
		elif ":" in k:
			selectores[k.get_slice(":", 0)] = true
	_ok(casos == BP.COMBATES.size() + BP.EXPLORAR.size() and casos == 11, "A: %d casos en pantalla" % casos)   # (15/11: + la muestra de la calle)
	_ok(selectores.size() == 9, "A: %d selectores (%s)" % [selectores.size(), str(selectores.keys())])
	b.queue_free()
	await _esperar(2)
	hechos.append("A: archivo propio, grupo de partida, 7 selectores y %d casos" % casos)


func _botones(n: Node) -> Array:
	var r: Array = []
	for c in n.get_children():
		if c is Button:
			r.append(c)
		r.append_array(_botones(c))
	return r


# ================================================================= B
func _combate(caso: String) -> Node:
	BP.preparar_partida()
	var d: Dictionary = BP.COMBATES[caso]
	BP.poner_grupo(d["activos"], BP.NIVEL_COMBATE)
	Engine.set_meta("banco_caso", caso)
	if d.get("custodio", false):
		Engine.set_meta("meshy_e01", true)
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", int(d["grupo"]))
	seed(14112026)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(4)
	return c


func _cerrar(c: Node) -> void:
	c.queue_free()
	await _esperar(4)


func _b() -> void:
	# vida «normal» de un grupo para comparar el multiplicador
	BP.preparar_partida()
	Engine.set_meta(BP.META, false)
	BP.poner_grupo(["Kael", "Lya", "Garon"], BP.NIVEL_COMBATE)
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	Engine.set_meta("banco_caso", "erebo")
	seed(14112026)
	var c0 = load("res://combate.tscn").instantiate()
	root.add_child(c0)
	await _esperar(4)
	var vida0: Array = c0.enemigos.map(func(e): return e["hp_max"])
	_ok(c0.armonia < 1.0, "F: fuera del banco el gancho llenó la Armonía")
	await _cerrar(c0)
	hechos.append("F: fuera del banco, el gancho del combate no cambia nada")

	var c = await _combate("erebo")
	var vida1: Array = c.enemigos.map(func(e): return e["hp_max"])
	_ok(vida1.size() == vida0.size() and vida1.size() > 0, "B: el grupo 1 cambió de tamaño")
	for i in mini(vida0.size(), vida1.size()):
		_ok(vida1[i] == int(round(vida0[i] * 6.0)), "B: vida %d en vez de %d×6" % [vida1[i], vida0[i]])
	_ok(c.armonia >= 1.0 and c._estado_invocacion()["lista"], "B: Érebo no está lista con la Armonía llena")
	var kael = c.heroes.filter(func(h): return h["nombre"] == "Kael")
	_ok(not kael.is_empty() and not c._puede_invocar(kael[0]), "B: Kael puede invocar")
	_ok(G.datos()["Lya"]["nivel"] == BP.NIVEL_COMBATE, "B: Lya no está al nivel %d" % BP.NIVEL_COMBATE)
	_ok(G.nivel_magia("Lya", "Agua") == 3, "B: Lya no tiene Maremoto (Agua nivel %d)" % G.nivel_magia("Lya", "Agua"))
	await _cerrar(c)

	# (14/11, visto en el Redmi) a nivel 12 en la llanura es «zona limpia»: fuera del banco los débiles huyen; dentro, no
	c = await _combate("garon")
	_ok(load("res://progreso.gd").zona_limpia("llanura"), "B: la llanura no es zona limpia a nivel %d" % BP.NIVEL_COMBATE)
	var huidos := 0
	for vuelta in 6:
		for e in c.enemigos:
			if e["hp"] > 0 and not e.get("huido", false):
				seed(1000 + vuelta)
				await c._turno_enemigo(e)
				if e.get("huido", false):
					huidos += 1
	_ok(huidos == 0, "B: en el banco han huido %d enemigos" % huidos)
	await _cerrar(c)

	c = await _combate("custodio")
	var hay: bool = c.enemigos.any(func(e): return e["clave"] == "meshy_e01" and load("res://combate_meshy_e01.gd").es(e))
	_ok(hay, "B: el combate del Custodio no lo trae con su personalidad")
	var vida_cus1: int = 0
	for e in c.enemigos:
		if e["clave"] == "meshy_e01":
			vida_cus1 = int(e["hp_max"])
	await _cerrar(c)
	# 15/11: el caso de la rotación es el mismo combate con la vida ×8; el normal, con la de siempre (equilibrio)
	c = await _combate("custodio_rotacion")
	var vida_cus8: int = 0
	for e in c.enemigos:
		if e["clave"] == "meshy_e01":
			vida_cus8 = int(e["hp_max"])
	_ok(vida_cus1 > 0 and vida_cus8 == int(round(vida_cus1 * 8.0)), "B: la vida del Custodio normal %d y la de la rotación %d (esperado ×8)" % [vida_cus1, vida_cus8])
	await _cerrar(c)

	c = await _combate("nix")
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	_ok("Nix" in nombres and not "Lya" in nombres, "B: el combate de Nix tiene %s" % str(nombres))
	await _cerrar(c)
	# 15/11: el grupo de cuatro, solo con el permiso de sesión del banco
	_ok(G.MAX_ACTIVOS == 3, "B: MAX_ACTIVOS del juego es %d (3)" % G.MAX_ACTIVOS)
	c = await _combate("grupo4")
	nombres = c.heroes.map(func(h): return h["nombre"])
	_ok(nombres == ["Kael", "Lya", "Garon", "Nix"] and G.activos().size() == 4 and Engine.get_meta(G.META_GRUPO4, false),
		"B: el grupo de cuatro tiene %s (activos %s)" % [nombres, G.activos()])
	var sitios := {}
	for h in c.heroes:
		sitios[str(c._suelo_de(h).round())] = true
	_ok(sitios.size() == 4 and c.menu.grupo.size() == 4, "B: cuatro héroes en %d sitios y %d filas del grupo" % [sitios.size(), c.menu.grupo.size()])
	# la victoria con cuatro: los cuatro reparten la experiencia como siempre (Nix, como Kael; _repartir_exp espera 1 s)
	var exp0 := {}
	for n in ["Kael", "Nix"]:
		exp0[n] = [int(G.datos()[n]["exp"]), int(G.datos()[n]["nivel"])]
	for e in c.enemigos:
		e["hp"] = 0
	_ok(c._comprobar_fin() and c.estado == "fin", "B: con cuatro, la victoria no llega (%s)" % c.estado)
	await _esperar(90)
	var exp1 := {}
	for n in ["Kael", "Nix"]:
		exp1[n] = [int(G.datos()[n]["exp"]), int(G.datos()[n]["nivel"])]
	print("EXP con cuatro: antes %s, después %s" % [exp0, exp1])
	_ok(exp1["Kael"] != exp0["Kael"] and exp1["Nix"] != exp0["Nix"],
		"B: con cuatro, la experiencia no llega a todos (antes %s, después %s)" % [exp0, exp1])
	await _cerrar(c)
	Engine.remove_meta(G.META_GRUPO4)                 # sin el permiso: los mismos cuatro nombres, tres
	_ok(G.activos() == ["Kael", "Lya", "Garon"] and G.max_activos() == 3, "B: sin el permiso, activos %s" % [G.activos()])
	Engine.set_meta(G.META_GRUPO4, true)
	Engine.set_meta(BP.META, false)                   # fuera del banco, aunque quede la meta: tres
	_ok(G.activos().size() == 3 and G.max_activos() == 3, "B: fuera del banco, activos %s" % [G.activos()])
	seed(14112026)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(4)
	nombres = c.heroes.map(func(h): return h["nombre"])
	_ok(nombres.size() == 3 and not "Nix" in nombres, "B: fuera del banco el combate tiene %s" % [nombres])
	await _cerrar(c)
	Engine.set_meta(BP.META, true)
	c = await _combate("nix")                         # el caso siguiente no hereda el permiso
	_ok(not Engine.has_meta(G.META_GRUPO4) and c.heroes.size() == 3, "B: el caso de Nix hereda el grupo de cuatro")
	await _cerrar(c)
	BP.preparar_partida()
	_ok(not Engine.has_meta("meshy_e01") and not Engine.has_meta("nix_v12") and not Engine.has_meta(G.META_GRUPO4),
		"B: los interruptores de un caso pasan al siguiente")
	_ok(not "Nix" in G.miembros(), "B: Nix sigue en el grupo al volver al banco")
	hechos.append("B: Érebo lista (×6 la vida, solo Lya invoca, Maremoto), el Custodio con su personalidad, Nix solo en su caso; grupo de cuatro solo con el permiso de sesión (sin él o fuera del banco, tres)")


# ================================================================= C
func _c() -> void:
	BP.preparar_partida()
	var Inv = load("res://inventario.gd")
	var oro0: int = Engine.get_meta("inventario")["oro"]
	Inv.ganar_oro(500)
	Inv.agregar_objeto("Éter")
	G.ganar_exp("Kael", 5000)
	Engine.set_meta("combates_ganados", {"prueba": true})
	Engine.set_meta("gremio", {"puntos": 99})
	BP.preparar_partida()
	_ok(Engine.get_meta("inventario")["oro"] == oro0, "C: el oro ganado sigue (%d)" % Engine.get_meta("inventario")["oro"])
	_ok(Engine.get_meta("inventario")["objetos"]["Éter"] == 3, "C: el objeto ganado sigue")
	_ok(G.datos()["Kael"]["nivel"] == 2 and G.datos()["Kael"]["exp"] == 18, "C: la experiencia ganada sigue")
	_ok(not Engine.has_meta("combates_ganados") and not Engine.has_meta("gremio"), "C: combates o gremio siguen")
	hechos.append("C: oro, objetos, experiencia, combates y gremio vuelven a la BASE al volver al banco")


# ================================================================= D
func _d() -> void:
	BP.preparar_partida()
	_ok(P.guardar(BP.ESCENA), "D: no se pudo guardar dentro del banco")
	_ok(FileAccess.file_exists(BP.ARCHIVO), "D: guardar no escribió el archivo del banco")
	var d = P.leer(BP.ARCHIVO)
	_ok(d is Dictionary and d.get("escena_guardada", "") == BP.ESCENA, "D: el archivo del banco no es la partida del banco")
	hechos.append("D: guardar dentro del banco escribe solo %s" % BP.ARCHIVO)


# ================================================================= F (Ajustes)
func _hay_volver(dentro: bool) -> bool:
	Engine.set_meta(BP.META, dentro)
	var m = load("res://menus.gd").new()
	m.pestana = "Ajustes"
	root.add_child(m)
	await _esperar(2)
	var hay: bool = _botones(m).any(func(x): return x.get_meta("clave", "") == "volver_banco")
	m.queue_free()
	await _esperar(2)
	return hay


func _f() -> void:
	BP.preparar_partida()
	_ok(await _hay_volver(true), "F: dentro del banco no sale «Volver al banco de pruebas»")
	_ok(not await _hay_volver(false), "F: fuera del banco sale «Volver al banco de pruebas»")
	Engine.set_meta(BP.META, true)
	hechos.append("F: «Volver al banco de pruebas» solo dentro del banco")


# ================================================================= G
func _g() -> void:
	var b = load(BP.ESCENA).instantiate()
	root.add_child(b)
	b._elegir_capa(true)
	b._elegir_nix_fbx(true)
	Engine.set_meta("oakhaven_propuestas_v12", true)  # (el selector del cantero del banco: solo de sesión)
	var c := ConfigFile.new()
	c.load("user://ajustes.cfg")
	_ok(c.get_value("garon", "capa", "") == "articulada", "G: la capa no se guardó como en Ajustes")
	_ok(c.get_value("calidad_pruebas", "nix_fbx", false) == true, "G: Nix FBX no se guardó como en Ajustes")
	_ok(load("res://garon_3d.gd").capa_articulada(), "G: la capa articulada no se lee")
	_ok(load("res://ciudades/oakhaven_propuestas.gd").activado(), "G: la misión del cantero no se enciende")
	b._elegir_capa(false)
	_ok(not load("res://garon_3d.gd").capa_articulada(), "G: la capa original no vuelve")
	b.queue_free()
	if Engine.has_meta("nix_fbx"):
		Engine.remove_meta("nix_fbx")
	BP.preparar_partida()
	_ok(load("res://ciudades/oakhaven_propuestas.gd").activado(), "G: el cantero se apaga al cambiar de caso")
	hechos.append("G: los selectores escriben lo mismo que Ajustes (capa y Nix FBX); el cantero, solo en la sesión del banco")


# ================================================================= E
func _e() -> void:
	BP.preparar_partida()
	P.guardar(BP.ESCENA)
	Engine.set_meta("meshy_e01", true)
	Engine.set_meta(G.META_GRUPO4, true)
	BP.salir()
	_ok(not BP.en_banco() and P.archivo() != BP.ARCHIVO, "E: al salir, la partida sigue yendo al banco")
	_ok(not FileAccess.file_exists(BP.ARCHIVO), "E: al salir queda el archivo del banco")
	for k in ["meshy_e01", "banco_caso", "nix_v12", "oakhaven_propuestas_v12", "oak_franja", "grupo", "inventario", "partida_lista", "archivo_partida_prueba", G.META_GRUPO4,
			"calidad_sesion", "calidad_proto", "calidad_extra", "banco_proto"]:
		_ok(not Engine.has_meta(k), "E: al salir queda «%s» en la sesión" % k)
	hechos.append("E: salir deja la sesión sin partida, sin interruptores y sin el archivo del banco")
	await _esperar(1)


# ================================================================= I (la calidad, de la sesión: 15/11)
func _i() -> void:
	var Auto = load("res://prototipos/calidad_auto.gd")
	var Cal = load("res://prototipos/calidad_proto.gd")
	var h_aj := _huella(Auto.AJUSTES)
	var h_log := _huella(Auto.REGISTRO)
	BP.preparar_partida()
	_ok(Auto.aislada(), "I: dentro del banco, la calidad no está aislada")
	Auto.guardar({"auto": true, "perfil": "bajo", "perfil_auto": "bajo", "calibrado": true, "nivel": 1, "nivel_de": "bajo"})
	Auto.registrar("prueba del banco (no debe llegar a calidad.log)")
	_ok(int(Auto.estado()["nivel"]) == 1, "I: el escalón guardado en la sesión no se lee (%s)" % str(Auto.estado()["nivel"]))
	_ok(is_equal_approx(float(Cal.datos()["escala_3d"]), 0.70), "I: con el escalón 1, la escala 3D no es 0,70 (%s)" % str(Cal.datos()["escala_3d"]))
	_ok(_huella(Auto.AJUSTES) == h_aj, "I: guardar [calidad] dentro del banco cambió user://ajustes.cfg")
	_ok(_huella(Auto.REGISTRO) == h_log, "I: registrar dentro del banco cambió user://calidad.log")
	BP.preparar_partida()                          # el caso siguiente empieza con los ajustes reales
	_ok(int(Auto.estado()["nivel"]) == int(Auto.estado_de(Auto._cargar(Auto.AJUSTES))["nivel"]), "I: el escalón de un caso pasa al siguiente")
	var b = load(BP.ESCENA).instantiate()          # (al abrirse, el banco rehace la sesión: el escalón se pone después)
	root.add_child(b)
	await _esperar(2)
	Auto.guardar({"auto": true, "perfil": "bajo", "perfil_auto": "bajo", "calibrado": true, "nivel": 1, "nivel_de": "bajo"})
	b._elegir_calidad_fija(true)
	_ok(str(Engine.get_meta("calidad_proto", "")) == "bajo" and is_equal_approx(float(Cal.datos()["escala_3d"]), 0.75),
		"I: «Fija» no deja el perfil tal cual (meta %s, escala %s)" % [str(Engine.get_meta("calidad_proto", "")), str(Cal.datos()["escala_3d"])])
	b._elegir_calidad_fija(false)
	_ok(not Engine.has_meta("calidad_proto") and is_equal_approx(float(Cal.datos()["escala_3d"]), 0.70),
		"I: «Regulador normal» no vuelve al escalón de la sesión (escala %s)" % str(Cal.datos()["escala_3d"]))
	b.queue_free()
	await _esperar(1)
	Engine.set_meta("calidad_proto", "medio")
	Engine.set_meta("calidad_extra", {})
	Engine.set_meta("banco_proto", {})
	var csv := FileAccess.open("user://banco_pruebas_rendimiento_x.csv", FileAccess.WRITE)
	csv.store_line("x")
	csv.close()
	Engine.set_meta("muestra_precalentar", true)
	BP.salir()
	for k in ["calidad_sesion", "calidad_proto", "calidad_extra", "banco_proto", "muestra_precalentar"]:
		_ok(not Engine.has_meta(k), "I: al salir queda «%s»" % k)
	_ok(not FileAccess.file_exists("user://banco_pruebas_rendimiento_x.csv"), "I: al salir queda el CSV de medida del banco")
	_ok(not Auto.aislada(), "I: fuera del banco la calidad sigue aislada")
	_ok(_huella(Auto.AJUSTES) == h_aj and _huella(Auto.REGISTRO) == h_log, "I: al salir, ajustes.cfg o calidad.log cambiaron")
	hechos.append("I: la calidad es de la sesión: el escalón se aplica sin tocar ajustes.cfg ni calidad.log, cada caso empieza limpio, «Calidad 3D» fija bajo ×0,75 o deja al regulador, y salir no deja nada")


# ================================================================= H (botón «Volver al banco» y portada alternativa)
func _h() -> void:
	BP.preparar_partida()
	var falsa := Node3D.new()
	falsa.scene_file_path = "res://zonas3d/oakhaven_3d.tscn"
	root.add_child(falsa)
	var antes := current_scene
	current_scene = falsa
	root.get_node("Recursos")._poner_boton_banco()
	var bb: Button = root.get_node("Recursos").boton_banco
	_ok(bb != null and bb.visible, "H: en una exploración del banco no sale «Volver al banco»")
	falsa.scene_file_path = BP.ESCENA
	root.get_node("Recursos")._poner_boton_banco()
	_ok(bb == null or not bb.visible, "H: en el propio banco sale «Volver al banco»")
	falsa.scene_file_path = "res://combate.tscn"
	root.get_node("Recursos")._poner_boton_banco()
	_ok(bb == null or not bb.visible, "H: en el combate sale «Volver al banco»")
	falsa.scene_file_path = "res://zonas3d/oakhaven_3d.tscn"
	Engine.set_meta(BP.META, false)
	root.get_node("Recursos")._poner_boton_banco()
	_ok(bb == null or not bb.visible, "H: fuera del banco sale «Volver al banco»")
	Engine.set_meta(BP.META, true)
	current_scene = antes
	falsa.queue_free()
	var por = load("res://portada/inicio_alternativo.tscn").instantiate()
	root.add_child(por)
	for i in 1800:                                   # hasta que termine su carga en segundo plano (si se libera a
		if por.listo:                                # medias, Dialogic se queda leyendo y da errores de lectura)
			break
		await process_frame
	_ok(por.listo, "H: la portada alternativa no termina de cargar")
	_ok(por.boton_banco != null, "H: la portada alternativa no tiene el botón del banco")
	por.queue_free()
	await _esperar(3)
	BP.preparar_partida()
	var G3 = load("res://zonas3d/grupo_3d.gd")
	_ok(not "Nix" in G3.reclutas_activos(["Lya", "Garon"]), "H: Nix sale en la exploración sin su caso")
	BP.poner_grupo(BP.EXPLORAR["oakhaven_nix"]["activos"])
	_ok("Nix" in G3.reclutas_activos(["Garon"]), "H: en «Oakhaven con Nix» la fila de la exploración no la lleva")
	BP.preparar_partida()
	hechos.append("H: «Volver al banco» solo en las exploraciones del banco; la portada alternativa tiene su acceso; Nix en la fila solo en su caso")
