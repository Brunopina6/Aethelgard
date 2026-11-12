extends SceneTree
# V12 (12/11): Naira en combate (PROPUESTA, NO CANON; modelo PROVISIONAL). Con el interruptor «naira_v12» encendido SOLO
# en esta prueba (Engine). Combates de verdad, con el guion de la prueba en cada menú (sin «auto»), contra enemigos de
# 400 PV casi quietos (para que el guion mande):
#   A. Kael, Naira y Garon (Lya en la reserva): Naira en el sitio de Lya y en su puesto; su modelo (naira_3d.gd) con sus
#      clips; sus datos de grupo.gd y su Astrolabio (+6 de daño mágico); su menú de magia abre las escuelas con el
#      Eclipse; el Eclipse se prepara (estado «conjuro», 30 PM, clip de concentrarse), se suelta solo en su turno
#      siguiente a todos con daño, «Penumbra» y un solo sonido; con Penumbra, el golpe de Kael hace más; Ascua quema;
#      un Eclipse que recibe un golpe fuerte se rompe (PM perdidos, sin daño); Contrapeso (Kael + Naira) en la pestaña
#      DÚO de Kael: gasta 8 PM y el turno de Naira, rompe la guardia y gasta la lentitud; al ganar, Naira gana su
#      experiencia y Lya (reserva) la mitad.
#   B. Kael, Lya y Naira (Garon en la reserva): Equinoccio en la pestaña DÚO de Lya: 10 PM de Lya, turno de Naira, daño y
#      cura del grupo con su tope; la INVOCACIÓN sigue siendo de Lya.
#   C. Sin interruptor: aunque la partida traiga a Naira, el combate es el de siempre y ningún DÚO la nombra.
# No toca la partida de verdad.

const MAX_FOTOGRAMAS := 9000

var P
var G
var MN
var c = null
var frames := 0
var f_inicio := 0
var escenario := ""
var pendientes := ["A", "B", "C"]
var fallos: Array = []
var hechos: Array = []
var paso := 0
var sonidos: Array = []
var datos := {}


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append("%s: %s" % [escenario, texto])


func _limpiar() -> void:
	for k in P.CLAVES + ["naira_v12", "partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	MN = load("res://magia_negra.gd")
	if "auto" in OS.get_cmdline_user_args():
		print("FALLO: esta prueba lleva su guion: sin «-- auto»")
		quit(1)


func _empezar(e: String) -> void:
	escenario = e
	paso = 0
	datos.clear()
	sonidos.clear()
	_limpiar()
	G.datos()
	if e != "C":
		Engine.set_meta("naira_v12", true)
	else:
		Engine.set_meta("naira_v12", true)         # la partida la une con el interruptor...
	G.unir("Naira")
	match e:
		"A":
			G.formar(["Kael", "Garon", "Naira"])
		"B":
			G.formar(["Kael", "Lya", "Naira"])
		"C":
			Engine.remove_meta("naira_v12")          # ...y se juega sin él (la versión de hoy)
	for n in G.datos():
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	datos["antes"] = G.datos().duplicate(true)
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	c.MODO_PRUEBAS = false
	c.sonido_pedido.connect(func(n): sonidos.append(n))
	for en in c.enemigos:
		en["atb"] = 0.0
		en["vel"] = 0.2                                # casi quietos: manda el guion
		en["hp_max"] = 400
		en["hp"] = 400
	f_inicio = frames
	_al_empezar()


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _vivos() -> Array:
	return c.enemigos.filter(func(x): return x["hp"] > 0)


func _filas() -> Array:
	return c.menu.filas.map(func(f): return f["item"])


func _pestanas() -> Array:
	return c.menu._pestanas


func _lanzar(fam: String, nv: int, objetivo = null) -> void:
	c._menu_magia(c.PESTANA_NEGRA)
	c._menu_escuela(fam)
	c._elegir_negra(fam, nv)
	if objetivo != null:
		_ok(c.estado == "objetivo", "%s %d no pide objetivo" % [fam, nv])
		c._confirmar_objetivo(objetivo)


func _al_empezar() -> void:
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	match escenario:
		"A":
			_ok(nombres == ["Kael", "Naira", "Garon"], "en el combate: %s" % [nombres])
			var naira := _heroe("Naira")
			_ok(not naira.is_empty() and naira["pos"] == Vector2(548, 95), "Naira no está en el sitio de Lya")
			var p = c._p3d(naira) if not naira.is_empty() else null
			_ok(p != null and p.get_script().resource_path == "res://personajes/naira/naira_3d.gd" and p.anim != null
				and p.anim.has_animation("lanzar_hechizo"), "Naira sin su modelo o sus clips")
			var e: Dictionary = G.estadisticas("Naira")
			_ok(naira.get("hp_max", 0) == e["pv_max"] and naira.get("mp_max", 0) == e["pm_max"] and naira.get("magia_extra", 0) == 6
				and naira.get("def", -1) == e["defensa"], "Naira sin sus datos o su Astrolabio")
			_ok(naira.get("def", 99) < _heroe("Kael").get("def", 0) and naira.get("def", 99) < _heroe("Garon").get("def", 0),
				"Naira no es la de menos defensa")
			_ok(c._duos_de(_heroe("Kael")).any(func(r): return r["texto"] == "Contrapeso"), "Kael sin Contrapeso")
			_ok(not c._duos_de(_heroe("Kael")).any(func(r): return r["texto"] == "Filo Arcano"), "Filo Arcano sin Lya")
		"B":
			_ok(nombres == ["Kael", "Lya", "Naira"], "en el combate: %s" % [nombres])
			_ok(_heroe("Naira").get("pos") == Vector2(270, 100), "Naira no está en el sitio de Garon")
			_ok(c._duos_de(_heroe("Lya")).any(func(r): return r["texto"] == "Equinoccio"), "Lya sin Equinoccio")
			_ok(not c._duos_de(_heroe("Lya")).any(func(r): return r["texto"] == "Barrera Rúnica"), "Barrera Rúnica sin Garon")
		"C":
			_ok(nombres == ["Kael", "Lya", "Garon"], "sin interruptor, en el combate: %s" % [nombres])
			for h in c.heroes:
				_ok(not c._duos_de(h).any(func(r): return r["texto"] in ["Contrapeso", "Equinoccio"]), "un DÚO de Naira sin ella")
			_ok(MN.hechizos("Naira").is_empty(), "sin interruptor, Naira sabe magia negra")
			datos["fin_guion"] = true


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:
		return false
	if c == null:
		if pendientes.is_empty():
			_terminar()
			return true
		_empezar(pendientes.pop_front())
		return false
	if datos.has("apagar"):
		if frames - int(datos["apagar"]) > 200:
			_al_acabar()
			c.queue_free()
			c = null
			_limpiar()
		return false
	if datos.has("fin_guion") and not datos.has("ganado"):
		datos["ganado"] = frames
		for e in c.enemigos:
			e["hp"] = 0
		c._comprobar_fin()
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		var quien: Dictionary = c.actor
		quien["mp"] = quien["mp_max"] if quien["nombre"] != "Naira" or paso == 0 else quien["mp"]
		match escenario:
			"A":
				_turno_a(quien)
			"B":
				_turno_b(quien)
			_:
				c._defender()
	if datos.has("ganado") and c.estado == "fin" and frames - int(datos["ganado"]) > 30 and not datos.has("apagar"):
		datos["apagar"] = frames
	elif frames - f_inicio > MAX_FOTOGRAMAS and not datos.has("apagar"):
		_ok(false, "no llegó al final (paso %d, estado %s)" % [paso, c.estado])
		c.set_process(false)
		datos["apagar"] = frames
	return false


# ---------------------------------------------------------------- A
func _turno_a(quien: Dictionary) -> void:
	var naira := _heroe("Naira")
	var kael := _heroe("Kael")
	var vivos := _vivos()
	if quien["nombre"] == "Garon":
		c._defender()
		return
	if quien["nombre"] == "Kael":
		if paso == 2 and not datos.has("kael_penumbra"):        # con Penumbra, su golpe hace más (×1,2)
			datos["kael_penumbra"] = true
			_ok(MN.turnos(vivos[0], "penumbra") > 0, "el enemigo no sigue en Penumbra en el turno de Kael")
			_ok(is_equal_approx(MN.mult_fisico_recibido(vivos[0]), 1.2), "Penumbra no sube los golpes")
		if paso == 4 and not datos.has("contrapeso"):
			datos["contrapeso"] = true
			naira["atb"] = c.ATB_MAX * 0.7
			naira["mp"] = 30
			var obj: Dictionary = vivos[0]
			MN.aplicar_estado(obj, "lento", 2)
			datos["hp_obj"] = obj["hp"]
			c._menu_magia(c.PESTANA_DUO)
			var fila: Array = _filas().filter(func(i): return i["texto"] == "Contrapeso")
			_ok(fila.size() == 1 and not fila[0].get("apagado", false), "Contrapeso no está en la pestaña DÚO de Kael")
			c._elegir_contrapeso()
			c._confirmar_objetivo(obj)
			datos["obj"] = obj
			paso = 5
			return
		if paso == 5 and datos.has("obj"):
			var obj: Dictionary = datos["obj"]
			_ok(int(datos["hp_obj"]) - obj["hp"] > 0, "Contrapeso no hace daño")
			_ok(naira["mp"] == 22, "Contrapeso no gasta 8 PM de Naira (%d)" % naira["mp"])
			_ok(MN.turnos(obj, "lento") == 0, "Contrapeso no gasta la lentitud")
			datos.erase("obj")
			datos["fin_guion"] = true
			hechos.append("A: Contrapeso (8 PM de Naira, su turno, daño, gasta el Lastre)")
			return
		c._defender()
		return
	# Naira
	match paso:
		0:
			c._menu_magia()
			var escuelas: Array = _filas().filter(func(i): return i.has("escuela")).map(func(i): return i["escuela"])
			_ok(not escuelas.is_empty() and escuelas[0] == "naira_eclipse", "el Eclipse no abre la primera página: %s" % [escuelas])
			for pg in [1, 2]:                                # (siete escuelas: tres páginas de 4 filas)
				c._pagina_escuelas(pg)
				escuelas.append_array(_filas().filter(func(i): return i.has("escuela")).map(func(i): return i["escuela"]))
			c._pagina_escuelas(0)
			_ok(escuelas == MN.TODAS, "las escuelas de Naira: %s" % [escuelas])
			c._menu_escuela("naira_eclipse")
			_ok(_pestanas().size() == 7 and _filas().size() == 1 and _filas()[0]["texto"] == "Eclipse"
				and _filas()[0]["derecha"].begins_with("◷"), "la página del Eclipse")
			var ancho := 4.0 * (_pestanas().size() - 1)
			for t in _pestanas():
				ancho += float(t["ancho"])
			_ok(ancho <= c.ANCHO_PESTANAS, "las 7 pestañas de escuela no caben: %d px" % ancho)
			datos["pv"] = vivos.map(func(e): return e["hp"])
			datos["pm"] = quien["mp"]
			datos["son"] = sonidos.size()
			_lanzar("naira_eclipse", 1)
			_ok(quien.has("conjuro") and quien["mp"] == int(datos["pm"]) - 30, "el Eclipse no se prepara o no gasta 30 PM")
			var p = c._p3d(quien)
			_ok(p != null and String(p.anim.current_animation) == "concentracion", "Naira no se concentra mientras prepara")
			paso = 1
		1:
			# su turno siguiente: el Eclipse ya salió solo
			_ok(not quien.has("conjuro"), "el Eclipse sigue preparándose")
			var bajan: Array = []
			for i in vivos.size():
				bajan.append(int(datos["pv"][i]) - vivos[i]["hp"])
			_ok(bajan.all(func(x): return x > 0), "el Eclipse no daña a todos: %s" % [bajan])
			_ok(vivos.all(func(e): return MN.turnos(e, "penumbra") > 0), "el Eclipse no deja Penumbra")
			var nuevos: Array = sonidos.slice(int(datos["son"]))
			_ok(nuevos.count("naira_eclipse") + nuevos.count("arte_ocaso") == 1, "el Eclipse suena %s" % [nuevos])
			_ok(MN.textos_estado(vivos[0]).any(func(t): return t.begins_with("Penumbra")), "Penumbra no se lee sobre el enemigo")
			hechos.append("A: Eclipse preparado, suelto, daño a todos, Penumbra y un sonido")
			# Ascua (quema) a uno
			datos["hp1"] = vivos[0]["hp"]
			_lanzar("negra_fuego", 1, vivos[0])
			paso = 2
		2:
			_ok(vivos[0]["hp"] < int(datos["hp1"]), "Ascua no hace daño")
			# un Eclipse que se rompe: se prepara y recibe un golpe fuerte
			quien["mp"] = quien["mp_max"]
			datos["pm"] = quien["mp"]
			datos["pv"] = vivos.map(func(e): return e["hp"])
			datos["son"] = sonidos.size()
			_lanzar("naira_eclipse", 1)
			_ok(quien.has("conjuro"), "el segundo Eclipse no se prepara")
			c._quitar_pv(quien, int(quien["hp_max"] * 0.3))
			_ok(not quien.has("conjuro") and quien["mp"] == int(datos["pm"]) - 30, "el Eclipse no se rompe con un golpe fuerte")
			_ok(sonidos.slice(int(datos["son"])).count("barrera_rota") + sonidos.slice(int(datos["son"])).count("negra_conjuro_roto") == 1,
				"la rotura no suena una vez")
			paso = 3
		3:
			var iguales := true
			for i in vivos.size():
				iguales = iguales and vivos[i]["hp"] == int(datos["pv"][i])
			_ok(iguales, "un Eclipse roto hace daño")
			hechos.append("A: Ascua; Eclipse roto por un golpe fuerte (PM perdidos, sin daño, un sonido)")
			paso = 4
			c._defender()
		_:
			c._defender()


# ---------------------------------------------------------------- B
func _turno_b(quien: Dictionary) -> void:
	var naira := _heroe("Naira")
	var vivos := _vivos()
	if quien["nombre"] != "Lya" or paso > 1:
		c._defender()
		return
	if paso == 0:
		_ok(c._estado_invocacion()["motivo"] != "Nadie puede invocar", "sin Lya invocando")
		naira["atb"] = c.ATB_MAX * 0.7
		var kael := _heroe("Kael")
		kael["hp"] = int(kael["hp_max"] * 0.4)
		datos["kael_hp"] = kael["hp"]
		datos["hp_obj"] = vivos[0]["hp"]
		datos["lya_pm"] = quien["mp"]
		datos["naira_pm"] = naira["mp"]
		c._menu_magia(c.PESTANA_DUO)
		var fila: Array = _filas().filter(func(i): return i["texto"] == "Equinoccio")
		_ok(fila.size() == 1 and not fila[0].get("apagado", false), "Equinoccio no está en la pestaña DÚO de Lya")
		c._elegir_equinoccio()
		c._confirmar_objetivo(vivos[0])
		_ok(quien["mp"] == int(datos["lya_pm"]) - 10, "Equinoccio no gasta 10 PM de Lya")
		datos["obj"] = vivos[0]
		paso = 1
	elif paso == 1:
		var obj: Dictionary = datos["obj"]
		var kael := _heroe("Kael")
		var hecho: int = int(datos["hp_obj"]) - obj["hp"]
		_ok(hecho > 0, "Equinoccio no hace daño")
		var cura: int = kael["hp"] - int(datos["kael_hp"])
		_ok(cura > 0 and cura <= int(kael["hp_max"] * 0.2) + 1 and cura <= hecho / 2 + 1, "la cura de Equinoccio: %d (daño %d)" % [cura, hecho])
		_ok(naira["mp"] == int(datos["naira_pm"]), "Equinoccio gasta PM de Naira")
		_ok(naira["atb"] < c.ATB_MAX * 0.7, "Equinoccio no gasta el turno de Naira")
		hechos.append("B: Equinoccio (10 PM de Lya, turno de Naira, daño y cura con tope); Lya invoca")
		paso = 2
		datos["fin_guion"] = true


func _al_acabar() -> void:
	match escenario:
		"A":
			var ganada: int = _exp(G.datos()["Naira"]) - _exp(datos["antes"]["Naira"])
			var lya: int = _exp(G.datos()["Lya"]) - _exp(datos["antes"]["Lya"])
			_ok(ganada > 0, "Naira no gana experiencia")
			_ok(lya > 0 and abs(lya - ganada / 2) <= 1, "Lya (reserva) gana %d y Naira %d" % [lya, ganada])
			_ok(datos.has("kael_penumbra") and datos.has("contrapeso"), "el guion de A no llegó a Kael")
			hechos.append("A: Naira en el sitio de Lya, su modelo, sus datos y su equipo; la reserva gana la mitad")
		"C":
			hechos.append("C: sin interruptor, el combate de siempre")


func _exp(d: Dictionary) -> int:
	var t := int(d["exp"])
	for i in range(1, int(d["nivel"])):
		t += G.exp_para(i)
	return t


func _terminar() -> void:
	_limpiar()
	for h in hechos:
		print("OK ", h)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
