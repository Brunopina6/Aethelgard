extends SceneTree
# V11, hito B (docs/v11/MEJORAS_COMBATE.md), en un combate de verdad, sin ventana y con datos aislados:
#   1. Panel de objetivos a la derecha: al pedir objetivo sale con una fila por enemigo (nombres distintos, también
#      los repetidos con A, B…), el apuntado con «▶», los derrotados apagados y con «Derrotado»; tocar una fila (pulsar y
#      soltar, como un dedo) elige a ese enemigo; con aliados, la lista de aliados; al confirmar, se quita.
#   2. Área: con una orden que alcanza a todos (el menú la marca), la lista marca a todos los vivos con «◆»; con otra, se
#      quita.
#   3. Interrupción: mientras Grimfang (agresivo) prepara su golpe, quitarle de una vez o en varias el 25 % de su vida
#      máxima lo corta (sin golpe, aturdido el turno siguiente, que pasa «recuperando el aliento»); menos, no. Al Slime
#      encogido (cobarde), la magia le rompe la guardia; el golpe físico pequeño, no. Un jefe que carga no se interrumpe.
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_v11_combate.save"
var P
var G
var c = null
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _combate(activos: Dictionary, grupo: int) -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(20261111)
	await _esperar(30)
	c.set_process(false)                             # el ATB quieto: aquí se mira la interfaz, no el reloj
	c.actor = c.heroes[0]                            # como en su turno: el menú lleva su nombre
	c.menu.heroe_actual = c.heroes[0]


func _clic(pos: Vector2, pulsado: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pulsado
	var w: Vector2 = root.get_final_transform() * pos
	ev.position = w
	ev.global_position = w
	root.push_input(ev)


func _probar() -> void:
	await _esperar(10)
	await _combate({"Kael": 5, "Lya": 5, "Garon": 5}, 2)
	await _panel()
	await _area()
	await _interrupcion()
	await _invocaciones()
	await _filo_arcano()
	await _quiebra_y_barrera()
	c.queue_free()
	await _esperar(5)
	await _elites()
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _textos_filas() -> Array:
	return c.filas_obj.map(func(r): return (r["nodo"].get_node("nombre") as Label).text)


func _panel() -> void:
	var vivos: Array = c.enemigos.filter(func(e): return e["hp"] > 0)
	_ok(vivos.size() >= 2, "1: el grupo 2 debería tener al menos dos enemigos (%d)" % vivos.size())
	var nombres := {}
	for e in c.enemigos:
		nombres[e["nombre"]] = true
	_ok(nombres.size() == c.enemigos.size(), "1: hay enemigos con el mismo nombre: %s" % str(c.enemigos.map(func(e): return e["nombre"])))
	var elegido := [null]
	c._pedir_objetivo(vivos, func(f): elegido[0] = f, func(): pass, "TOCA UN ENEMIGO")
	await _esperar(2)
	_ok(c.panel_obj.visible, "1: al pedir objetivo no sale el panel")
	_ok(c.filas_obj.size() == c.enemigos.size(), "1: el panel tiene %d filas y hay %d enemigos" % [c.filas_obj.size(), c.enemigos.size()])
	var t: Array = _textos_filas()
	_ok(t.filter(func(x): return x.begins_with("▶ ")).size() == 1, "1: no hay un solo apuntado con «▶»: %s" % str(t))
	# tocar la segunda fila: la elige
	var fila: Control = c.filas_obj[1]["nodo"]
	var esperado: Dictionary = c.filas_obj[1]["f"]
	var centro := fila.get_global_rect().get_center()
	_clic(centro, true)
	await _esperar(3)
	_ok(c.objetivo_apuntado != null and is_same(c.objetivo_apuntado, esperado), "1: pulsar la fila no apunta a ese enemigo")
	_clic(centro, false)
	await _esperar(3)
	_ok(elegido[0] != null and is_same(elegido[0], esperado), "1: tocar la segunda fila no elige a %s" % esperado["nombre"])
	_ok(not c.panel_obj.visible, "1: tras elegir, el panel sigue a la vista")
	# un derrotado: apagado y con «Derrotado»
	var caido: Dictionary = c.enemigos[0]
	var pv0: int = caido["hp"]
	caido["hp"] = 0
	c._pedir_objetivo(c.enemigos.filter(func(e): return e["hp"] > 0), func(f): pass, func(): pass, "TOCA UN ENEMIGO")
	await _esperar(2)
	var r0: Dictionary = c.filas_obj[0]
	_ok(not r0["ok"] and r0["nodo"].modulate.a < 0.5 and c._info_objetivo(caido, false) == "Derrotado",
		"1: el derrotado no sale apagado con «Derrotado»")
	_ok(r0["nodo"].mouse_filter == Control.MOUSE_FILTER_IGNORE, "1: la fila del derrotado se puede tocar")
	c._limpiar_objetivo()
	caido["hp"] = pv0
	# aliados: la lista de aliados
	var aliados: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	c._pedir_objetivo(aliados, func(f): pass, func(): pass, "TOCA A UN ALIADO")
	await _esperar(2)
	_ok(c.filas_obj.size() == aliados.size() and c.filas_obj.all(func(r): return r["f"].get("hero", false)),
		"1: al elegir aliado, el panel no lista a los aliados")
	c._limpiar_objetivo()
	_ok(not c.panel_obj.visible, "1: tras limpiar, el panel sigue a la vista")


func _area() -> void:
	c.estado = "menu"
	c.menu.marcado.emit({"area_enemigos": true})
	await _esperar(2)
	var vivos: int = c.enemigos.filter(func(e): return e["hp"] > 0).size()
	_ok(c.flechas_area.size() == c.enemigos.filter(func(e): return e["hp"] > 0).size(), "2: con una orden de área no sale una flecha sobre cada vivo (%d)" % c.flechas_area.size())
	c._mostrar_panel(c.enemigos.filter(func(e): return e["hp"] > 0), "area")   # mientras se lanza: la lista
	_ok(_textos_filas().filter(func(x): return x.begins_with("◆ ")).size() == vivos, "2: la lista no marca a los %d vivos: %s" % [vivos, str(_textos_filas())])
	c._ocultar_panel()
	c.menu.marcado.emit({"area_enemigos": true})
	c.menu.marcado.emit({"texto": "ATACAR"})
	await _esperar(2)
	_ok(c.flechas_area.is_empty() and not c.panel_obj.visible, "2: con una orden a uno, las flechas de área siguen")


func _interrupcion() -> void:
	var e: Dictionary = c.enemigos[0]
	e["personalidad"] = "agresivo"
	e["hp_max"] = 200
	e["hp"] = 200
	e["cargando"] = true
	e["carga_recibido"] = 0
	c._quitar_pv(e, 20)
	c._quitar_pv(e, 20)
	_ok(e.get("cargando", false), "3: 40 de 200 (el 20 %) ya interrumpe")
	c._quitar_pv(e, 15)
	_ok(not e.get("cargando", false) and e.get("recupera", false) and e.get("aturdido", false),
		"3: 55 de 200 en varios golpes no interrumpe")
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var pv := vivos.map(func(h): return h["hp"])
	var hecho: bool = await c._turno_patron(e, vivos, 1.0, c.PATRONES["agresivo"])
	_ok(hecho and c.registro.text.contains("aturdido") and c.registro.text.contains("recupera") and not e.get("recupera", false),
		"3: el turno siguiente no lo pasa aturdido: «%s»" % c.registro.text)
	_ok(vivos.map(func(h): return h["hp"]) == pv, "3: aturdido, golpea igual")
	# el Slime encogido: la magia le rompe la guardia
	var s: Dictionary = c.enemigos[1]
	s["personalidad"] = "cobarde"
	s["hp_max"] = 200
	s["hp"] = 200
	s["cargando"] = true
	s["defendiendo"] = true
	s["carga_recibido"] = 0
	c._quitar_pv(s, 5)
	_ok(s.get("cargando", false) and s.get("defendiendo", false), "3: un golpe físico pequeño rompe la guardia del Slime")
	c.golpe_magico = true
	c._quitar_pv(s, 5)
	c.golpe_magico = false
	_ok(not s.get("cargando", false) and not s.get("defendiendo", false) and s.get("aturdido", false),
		"3: la magia no rompe la guardia del Slime encogido")
	# un jefe que carga no se interrumpe
	var j: Dictionary = c.enemigos[0]
	j["personalidad"] = "jefe"
	j["hp"] = 200
	j["cargando"] = true
	c._quitar_pv(j, 150)
	_ok(j.get("cargando", false), "3: un jefe que carga se interrumpe")
	j["cargando"] = false


func _invocaciones() -> void:
	c.armonia = 1.0
	c._invocar()
	await _esperar(2)
	var filas: Array = c.menu.filas
	_ok(c.estado == "invocacion" and filas.size() == 1, "4: INVOCACIÓN no abre la lista (estado %s, %d filas)" % [c.estado, filas.size()])
	if filas.size() == 1:
		var it: Dictionary = filas[0]["item"]
		_ok(it["texto"] == "Érebo" and it.get("icono", "") == "Erebo" and it.get("derecha", "") == "100 %" \
			and not it.get("apagado", true) and str(it.get("desc", "")).contains(c.INVOCACION["nombre"]),
			"4: la fila de Érebo no lleva nombre, emblema, coste y descripción: %s" % str(it))
	c._atras()
	await _esperar(2)
	_ok(c.estado == "menu", "4: atrás desde la lista no vuelve al menú (%s)" % c.estado)
	c.armonia = 0.5
	c._invocar()
	await _esperar(2)
	if c.menu.filas.size() == 1:
		var it2: Dictionary = c.menu.filas[0]["item"]
		_ok(it2.get("apagado", false) and str(it2.get("motivo", "")).begins_with("Armonía al "),
			"4: sin la Armonía llena, Érebo no sale apagado con su motivo: %s" % str(it2))
	c._atras()
	c.armonia = 1.0
	c._invocar()
	await _esperar(2)
	c._invocar_objetivo()
	await _esperar(2)
	_ok(c.estado == "objetivo" and c.panel_obj.visible, "4: al elegir a Érebo no se pide el objetivo con el panel")
	c._atras()
	await _esperar(2)
	_ok(c.estado == "invocacion", "4: atrás desde el objetivo no vuelve a la lista de invocaciones (%s)" % c.estado)
	c._atras()


func _filo_arcano() -> void:
	var kael: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var lya: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	c.actor = kael
	c.menu.heroe_actual = kael
	lya["mp"] = 20
	lya["atb"] = c.ATB_MAX * 0.3
	var d: Array = c._duos_de(kael)
	_ok(d.size() == 2 and d[0]["texto"] == "Filo Arcano" and d[0]["apagado"] and str(d[0]["motivo"]).contains("no está lista"),
		"5: con Lya al 30 %% de ATB, Filo Arcano no sale apagado con su motivo: %s" % str(d))
	_ok(c._duos_de(lya).map(func(x): return x["texto"]) == ["Barrera Rúnica"], "5: Lya no tiene solo Barrera Rúnica en DÚO: %s" % str(c._duos_de(lya).map(func(x): return x["texto"])))
	lya["atb"] = c.ATB_MAX * 0.6
	d = c._duos_de(kael)
	_ok(d.size() == 2 and not d[0]["apagado"], "5: con Lya lista, Filo Arcano sale apagado: %s" % str(d))
	c._menu_magia(c.PESTANA_DUO)
	await _esperar(2)
	_ok(c.estado == "magia" and c.menu.filas.map(func(f): return f["item"]["texto"]) == ["Filo Arcano", "Quiebra"],
		"5: la pestaña DÚO no lista Filo Arcano (%s)" % str(c.menu.filas.map(func(f): return f["item"].get("texto", ""))))
	c._ocultar_menu()
	# el golpe: al Slime encogido le rompe la guardia, gasta 8 PM y el turno de Lya
	var s: Dictionary = c.enemigos[2]
	s["personalidad"] = "cobarde"
	s["hp_max"] = 400
	s["hp"] = 400
	s["cargando"] = true
	s["defendiendo"] = true
	s["carga_recibido"] = 0
	c.cola.append(lya)
	await c._filo_arcano(s)
	await _esperar(5)
	_ok(lya["mp"] == 12 or c.MODO_PRUEBAS, "5: Filo Arcano no gasta 8 PM de Lya (le quedan %d)" % lya["mp"])
	_ok(lya["atb"] < c.ATB_MAX * 0.2 and not c.cola.any(func(x): return is_same(x, lya)), "5: Lya no pierde su turno")
	_ok(s["hp"] < 400, "5: Filo Arcano no hace daño")
	_ok(not s.get("cargando", false) and s.get("aturdido", false), "5: Filo Arcano no rompe la guardia del Slime encogido")
	_ok(not kael.has("filo_arcano") and not kael.has("embuir"), "5: Kael se queda con el fuego de Filo Arcano")
	# sin crítico: 40 Filos seguidos (con el 12 % de crítico, sin el arreglo saldría alguno casi siempre: 0,6 % de fallarlo) no pasan nunca del máximo sin crítico (11/11: con crítico tumbaba al Slime de élite)
	var fis_max: int = int(kael["atk"] * kael.get("mult_fisico", 1.0)) + 3
	var mag_max: int = int((c.NIVELES_MAGIA["Fuego"][0]["dano"] * lya.get("magia_mult", 1.0) + lya.get("magia_extra", 0)) * lya.get("mult_magia", 1.0)) + 3
	var tope: int = int((fis_max + int(mag_max * c.FILO_ARCANO["parte_magia"])) * (1.0 + c.EMBUIR["extra"]))
	var maximo := 0
	for i in 40:
		s["hp_max"] = 100000
		s["hp"] = 100000
		s["cargando"] = false
		s["defendiendo"] = false
		lya["mp"] = 40
		lya["atb"] = c.ATB_MAX
		c.actor = kael
		await c._filo_arcano(s)
		maximo = maxi(maximo, 100000 - int(s["hp"]))
	_ok(maximo > 0 and maximo <= tope, "5: Filo Arcano hace %d, más que su máximo sin crítico (%d)" % [maximo, tope])


func _quiebra_y_barrera() -> void:
	var kael: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var lya: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	var garon: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Garon")[0]
	# Quiebra: Garon presta su turno; corta siempre el golpe preparado (aunque sea poco daño) y gasta 6 PM de Kael
	c.actor = kael
	kael["mp"] = 20
	garon["atb"] = c.ATB_MAX * 0.2
	var q: Dictionary = c._duos_de(kael).filter(func(x): return x["texto"] == "Quiebra")[0]
	_ok(q["apagado"] and str(q["motivo"]).contains("Garon aún no está listo"), "6: Quiebra sin Garon listo no sale apagada: %s" % str(q))
	garon["atb"] = c.ATB_MAX * 0.7
	var g: Dictionary = c.enemigos[0]
	g["personalidad"] = "agresivo"
	g["hp_max"] = 5000
	g["hp"] = 5000
	g["cargando"] = true
	g["carga_recibido"] = 0
	c.cola.append(garon)
	await c._quiebra(g)
	await _esperar(5)
	_ok(not g.get("cargando", false) and g.get("aturdido", false), "6: Quiebra no corta el golpe preparado de un enemigo con mucha vida")
	_ok(kael["mp"] == 14 or c.MODO_PRUEBAS, "6: Quiebra no gasta 6 PM de Kael (%d)" % kael["mp"])
	_ok(garon["atb"] < c.ATB_MAX * 0.2 and not c.cola.any(func(x): return is_same(x, garon)), "6: Garon no pierde su turno")
	_ok(not c.golpe_ruptura, "6: la ruptura se queda puesta tras el golpe")
	# Barrera Rúnica: coraza del 25 % a todo el grupo en pie; gasta 10 PM de Lya y el turno de Garon
	c.actor = lya
	lya["mp"] = 30
	garon["atb"] = c.ATB_MAX * 0.6
	for h in c.heroes:
		h["barrera"] = 0
	await c._barrera_runica()
	await _esperar(5)
	_ok(c.heroes.filter(func(h): return h["hp"] > 0).all(func(h): return int(h.get("barrera", 0)) == maxi(1, int(h["hp_max"] * 0.25))),
		"6: Barrera Rúnica no da el 25 %% a todos: %s" % str(c.heroes.map(func(h): return [h["nombre"], h.get("barrera", 0), h["hp_max"]])))
	_ok(lya["mp"] == 20 or c.MODO_PRUEBAS, "6: Barrera Rúnica no gasta 10 PM de Lya (%d)" % lya["mp"])
	_ok(garon["atb"] < c.ATB_MAX * 0.2, "6: Barrera Rúnica no gasta el turno de Garon")
	# la coraza para un golpe: el Pisotón a todos le quita a la coraza antes que a los PV
	var k_pv: int = kael["hp"]
	var b0: int = int(kael["barrera"])
	c._quitar_pv(kael, 3)
	_ok(kael["hp"] == k_pv and int(kael["barrera"]) == b0 - 3, "6: la coraza de la Barrera Rúnica no para el golpe")


# 7. Élites: con dos o más héroes, el encuentro al azar número 6 (12, 18…) trae uno; los demás y Kael solo, no.
func _elites() -> void:
	for caso in [[5, ["Kael", "Lya", "Garon"], true], [6, ["Kael", "Lya", "Garon"], false], [5, ["Kael"], false]]:
		for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate"]:
			if Engine.has_meta(k):
				Engine.remove_meta(k)
		G.datos()
		Engine.set_meta("grupo_activo", caso[1])
		Engine.set_meta("zona", "ceniza")
		Engine.set_meta("encuentros_azar", caso[0])
		var cc = null
		for intento in 8:                             # un grupo con jefe (el Guardián) no cuenta: se repite
			cc = load("res://combate.tscn").instantiate()
			root.add_child(cc)
			await _esperar(20)
			cc.set_process(false)
			if not cc.enemigos.any(func(e): return e.get("personalidad", "") in ["jefe", "bosque", "coloso"]):
				break
			_ok(int(Engine.get_meta("encuentros_azar", 0)) == caso[0], "7: un grupo con jefe cuenta para el élite")
			cc.queue_free()
			await _esperar(5)
		var elites: Array = cc.enemigos.filter(func(e): return e.get("elite", false))
		if caso[2]:
			_ok(elites.size() == 1 and str(elites[0]["nombre"]).begins_with("★ ") and cc.registro.text.contains("élite")
				and int(Engine.get_meta("encuentros_azar", 0)) == 6,
				"7: el sexto encuentro al azar no trae un élite (%d, «%s»)" % [elites.size(), cc.registro.text])
			if elites.size() == 1:
				var mas_vida: bool = cc.enemigos.all(func(e): return e["hp_max"] <= elites[0]["hp_max"])
				_ok(mas_vida and cc._info_objetivo(elites[0], true).contains("Élite"), "7: el élite no es el de más vida o no se ve en la lista")
		else:
			_ok(elites.is_empty(), "7: hay élite donde no toca (%d encuentros, %d héroes)" % [caso[0], caso[1].size()])
		cc.queue_free()
		await _esperar(5)
