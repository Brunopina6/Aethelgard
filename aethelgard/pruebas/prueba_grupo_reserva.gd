extends SceneTree
# V12 (12/11): grupo con reserva (grupo.gd) y Formación (menus.gd). Sin escena salvo los combates y los menús.
#   1. Compatibilidad: partida nueva, partidas de antes (sin «grupo_activo», con la misión a medias), una partida que trae
#      datos de Naira sin su hito ni su interruptor (no sale) y que sin reserva no se guarda «grupo_miembros»;
#      Naira no nace en datos() ni en ninguna partida que no la ha unido; sin interruptor, unir("Naira") no hace nada.
#   2. Unirse (con el interruptor naira_v12, solo en esta prueba): al grupo si cabe, a la reserva si no; datos de nivel 1
#      con su plantilla y su Astrolabio puesto; dos veces no repite; Garon que llega con el grupo lleno va a la reserva.
#   3. Formación: formar, alternar y cambiar; Kael fijo; máximo 3 (también con una partida tocada a mano); ausentes no.
#   4. Guardado y carga (archivo propio): activos y reserva iguales; sin reserva, sin la clave; en una versión que no
#      conoce la clave (se borra), los activos siguen.
#   5. Derrota y vuelta: tras perder, activos y reserva con la vida llena; al ganar, la reserva gana su parte
#      (PARTE_EXP_RESERVA) y los ausentes nada; huir no da nada (combates de verdad, con «-- auto»).
#   6. Cambio de región: los acompañantes de la exploración (zonas3d/grupo_3d.gd, como los crean las regiones) siguen la
#      formación, también tras guardar y cargar; sin reclutas, la fila de siempre.
#   7. Menú: sin reserva, ni Formación ni reserva (como siempre); con reserva, Formación con una tarjeta por miembro,
#      Kael sin botón, y los botones cambian el grupo; Habilidades enseña la magia negra de Naira.
# No toca la partida de verdad.

const ARCHIVO := "user://prueba_grupo_reserva.save"
const MAX_FOTOGRAMAS := 6000

var P
var G
var I
var MN
var fallos: Array = []
var hechos: Array = []
var frames := 0
var c = null
var casos: Array = []
var caso := {}
var f_caso := 0
var f_fin := -1
var antes := {}


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)


func _limpiar() -> void:
	for k in P.CLAVES + ["naira_v12", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	MN = load("res://magia_negra.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	_compatibilidad()
	_unirse()
	_formacion()
	_guardado()


# ---------------------------------------------------------------- 1
func _compatibilidad() -> void:
	_limpiar()
	_ok(not G.NAIRA_POR_DEFECTO and not G.naira_v12(), "1: el interruptor naira_v12 está encendido por defecto")
	_ok(G.activos() == ["Kael", "Lya", "Garon"] and G.en_el_grupo() == G.activos() and G.reserva().is_empty(),
		"1: partida nueva: %s / %s" % [G.activos(), G.reserva()])
	_ok(not G.datos().has("Naira") and G.miembros() == ["Kael", "Lya", "Garon"], "1: Naira nace en datos()")
	_ok(G.unir("Naira") == "" and not G.datos().has("Naira") and not I.datos()["equipo"].has("Naira"),
		"1: sin interruptor, unir(«Naira») hace algo")
	_ok(MN.familias_de("Naira").is_empty() and MN.DE_HEROE.is_empty(), "1: Naira sabe magia negra sin interruptor")
	_ok(not P.volcar("res://mapa.tscn").has("grupo_miembros"), "1: sin reserva se guarda «grupo_miembros»")
	# las partidas de antes (las mismas que prueba_grupos_combate) y una con datos de Naira pero sin su hito
	var antiguas := [[{}, ["Kael", "Lya", "Garon"]], [{"pv_02": true}, ["Kael"]],
		[{"pv_02": true, "pv_03": true}, ["Kael", "Lya"]], [{"pv_02": true, "pv_03": true, "pv_05": true}, ["Kael", "Lya", "Garon"]]]
	for a in antiguas:
		for con_naira in [false, true]:
			_limpiar()
			G.datos()
			var gr: Dictionary = G.datos().duplicate(true)
			if con_naira:
				gr["Naira"] = {"nivel": 9, "exp": 0, "puntos": 0, "atributos": G.HEROES["Naira"]["atributos"].duplicate(), "pv": -1, "pm": -1}
			var d := {"grupo": gr, "hitos": a[0], "escena_guardada": "res://mapa.tscn"}
			if con_naira:
				d["grupo_activo"] = ["Kael", "Naira"]  # (tocada a mano: sin hito, Naira no cuenta)
				d["grupo_miembros"] = ["Kael", "Lya", "Garon", "Naira"]
			_limpiar()
			P.restaurar(d)
			var esperado: Array = a[1] if not con_naira else ["Kael"]
			_ok(G.activos() == esperado, "1: partida de antes %s (Naira: %s) da %s y no %s" % [a[0].keys(), con_naira, G.activos(), esperado])
			_ok(not "Naira" in G.en_el_grupo() and not "Naira" in G.miembros(), "1: Naira sale sin su hito en %s" % [a[0].keys()])
			if con_naira:
				_ok(G.datos().has("Naira") and int(G.datos()["Naira"]["nivel"]) == 9, "1: los datos ocultos de Naira se pierden")
	# con su hito (lo pondrá su misión), sí existe
	_limpiar()
	P.poner_hito("nr_union")
	_ok(G.disponible("Naira") and G.unir("Naira") == "reserva", "1: con «nr_union», Naira no se puede unir")
	_limpiar()
	hechos.append("1: compatibilidad (nueva, 4 de antes con y sin datos de Naira, sin interruptor nada, con su hito sí)")


# ---------------------------------------------------------------- 2
func _unirse() -> void:
	_limpiar()
	Engine.set_meta("naira_v12", true)
	G.datos()["Kael"]["nivel"] = 7
	var lya_antes: Dictionary = G.datos()["Lya"].duplicate(true)
	_ok(G.unir("Naira") == "reserva", "2: con el grupo lleno, Naira no va a la reserva")
	_ok(G.activos() == ["Kael", "Lya", "Garon"] and G.reserva() == ["Naira"] and G.en_el_grupo().size() == 4,
		"2: tras unirse: %s / %s" % [G.activos(), G.reserva()])
	var d: Dictionary = G.datos()["Naira"]
	_ok(int(d["nivel"]) == G.NIVEL_AL_UNIRSE and int(d["puntos"]) == 0 and d["atributos"] == G.HEROES["Naira"]["atributos"],
		"2: Naira no llega con su plantilla de nivel 1: %s" % [d])
	_ok(I.equipo_de("Naira").get("arma", "") == "astrolabio_bronce" and "astrolabio_bronce" in I.datos()["equipables"],
		"2: Naira sin su Astrolabio")
	_ok(not I.puede_llevar("Lya", "astrolabio_bronce") and I.puede_llevar("Naira", "cetro_loto"), "2: el Astrolabio es de otros")
	_ok(G.datos()["Lya"] == lya_antes, "2: unirse cambia a Lya")
	var e: Dictionary = G.estadisticas("Naira")
	_ok(e["defensa"] < G.estadisticas("Lya")["defensa"] and e["atributos"]["magia"] > G.estadisticas("Lya")["atributos"]["magia"],
		"2: Naira no es la de menos defensa y más magia")
	_ok(e["magia_extra"] == 6 and is_equal_approx(e["mult_fisico"], 0.3), "2: el Astrolabio o su golpe físico no cuentan")
	_ok(G.unir("Naira") == "" and G.en_el_grupo().count("Naira") == 1, "2: unirse dos veces la repite")
	# en la misión, con sitio: al grupo; y quien llega después con el grupo lleno, a la reserva
	_limpiar()
	Engine.set_meta("naira_v12", true)
	G.empezar_solo()
	G.unir("Lya")
	_ok(G.unir("Naira") == "activo" and G.activos() == ["Kael", "Lya", "Naira"], "2: con sitio, Naira no entra al grupo")
	_ok(G.unir("Garon") == "reserva" and G.reserva() == ["Garon"], "2: Garon con el grupo lleno no va a la reserva")
	# crecimiento recomendado: 3 puntos por nivel
	G.datos()["Naira"]["puntos"] = 6
	var a0: Dictionary = G.datos()["Naira"]["atributos"].duplicate()
	_ok(G.repartir_recomendado("Naira") == 6 and int(G.datos()["Naira"]["puntos"]) == 0, "2: el reparto no gasta los puntos")
	var a1: Dictionary = G.datos()["Naira"]["atributos"]
	_ok(a1["magia"] - a0["magia"] == 2 and a1["espiritu"] - a0["espiritu"] == 2 and a1["defensa"] == a0["defensa"]
		and a1["velocidad"] - a0["velocidad"] == 1 and a1["vitalidad"] - a0["vitalidad"] == 1, "2: reparto recomendado: %s → %s" % [a0, a1])
	_ok(G.repartir_recomendado("Kael") == 0, "2: Kael tiene reparto recomendado")
	_limpiar()
	hechos.append("2: unirse (reserva si está lleno, grupo si cabe, plantilla y Astrolabio, una sola vez, crecimiento)")


# ---------------------------------------------------------------- 3
func _formacion() -> void:
	_limpiar()
	Engine.set_meta("naira_v12", true)
	G.unir("Naira")
	_ok(G.hay_formacion(), "3: con reserva no hay Formación")
	_ok(G.formar(["Kael", "Garon", "Naira"]) == "" and G.activos() == ["Kael", "Garon", "Naira"] and G.reserva() == ["Lya"],
		"3: formar no pone a Naira por Lya: %s / %s" % [G.activos(), G.reserva()])
	_ok(G.formar(["Lya", "Garon", "Naira"]) != "" and G.activos() == ["Kael", "Garon", "Naira"], "3: Kael sale del grupo")
	_ok(G.formar(["Kael", "Lya", "Garon", "Naira"]) != "", "3: caben cuatro")
	_ok(G.formar([]) != "", "3: un grupo vacío")
	_ok(G.alternar("Kael") != "", "3: Kael pasa a la reserva")
	_ok(G.alternar("Lya") != "" and G.reserva() == ["Lya"], "3: Lya entra en un grupo lleno")
	_ok(G.alternar("Garon") == "" and G.activos() == ["Kael", "Naira"] and G.reserva() == ["Lya", "Garon"], "3: alternar Garon")
	_ok(G.alternar("Lya") == "" and G.activos() == ["Kael", "Lya", "Naira"], "3: alternar Lya")
	_ok(G.cambiar("Naira", "Garon") == "" and G.activos() == ["Kael", "Lya", "Garon"] and G.reserva() == ["Naira"], "3: cambiar")
	_ok(G.cambiar("Naira", "Lya") != "", "3: cambiar a quien no está")
	# máximo 3 aunque la partida diga otra cosa; ausentes, nunca
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon", "Naira"])
	_ok(G.activos().size() == 3 and G.activos()[0] == "Kael", "3: más de 3 activos: %s" % [G.activos()])
	_limpiar()
	Engine.set_meta("naira_v12", true)
	G.empezar_solo()
	G.unir("Lya")
	_ok(G.formar(["Kael", "Garon"]) != "" and not G.hay_formacion(), "3: un ausente (Garon antes de PV-05) entra por la Formación")
	_limpiar()
	hechos.append("3: Formación (formar, alternar, cambiar, Kael fijo, máximo 3, ausentes no)")


# ---------------------------------------------------------------- 4
func _guardado() -> void:
	_limpiar()
	Engine.set_meta("naira_v12", true)
	Engine.set_meta("partida_lista", true)
	G.unir("Naira")
	G.formar(["Kael", "Garon", "Naira"])
	G.datos()["Naira"]["nivel"] = 4
	_ok(P.guardar("res://mapa.tscn"), "4: no se guarda")
	var d = P.leer(ARCHIVO)
	_ok(d is Dictionary and d.get("grupo_miembros", []) == ["Kael", "Lya", "Garon", "Naira"] and int(d.get("formato", 0)) == P.FORMATO,
		"4: lo guardado no trae la reserva o el formato: %s" % [d.get("grupo_miembros") if d is Dictionary else d])
	_limpiar()
	Engine.set_meta("naira_v12", true)
	P.cargar()
	_ok(G.activos() == ["Kael", "Garon", "Naira"] and G.reserva() == ["Lya"] and int(G.datos()["Naira"]["nivel"]) == 4
		and I.equipo_de("Naira").get("arma", "") == "astrolabio_bronce", "4: tras cargar: %s / %s" % [G.activos(), G.reserva()])
	# una versión que no conoce «grupo_miembros» la pierde al guardar: los activos siguen, sin reserva
	var sin: Dictionary = P.volcar("res://mapa.tscn")
	sin.erase("grupo_miembros")
	_limpiar()
	Engine.set_meta("naira_v12", true)
	P.restaurar(sin)
	_ok(G.activos() == ["Kael", "Garon", "Naira"] and G.reserva().is_empty(), "4: sin la clave, los activos cambian: %s" % [G.activos()])
	# la misma partida sin el interruptor (la versión de hoy): Naira no sale y el grupo sigue con lo que queda
	var d2: Dictionary = P.leer(ARCHIVO)
	_limpiar()
	P.restaurar(d2)
	_ok(G.activos() == ["Kael", "Garon"] and G.reserva() == ["Lya"] and not "Naira" in G.en_el_grupo(),
		"4: sin interruptor, una partida con Naira da %s / %s" % [G.activos(), G.reserva()])
	_limpiar()
	_borrar()
	hechos.append("4: guardar y cargar con reserva; sin la clave; sin interruptor")


# ---------------------------------------------------------------- 6 (exploración)
func _acompanantes() -> Array:
	# como lo hacen las regiones (garganta_3d.gd, mar_cristal_3d.gd, oakhaven_3d.gd, pastos_verdes_3d.gd)
	var activos: Array = G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	var region := Node3D.new()
	root.add_child(region)
	var kael := Node3D.new()
	region.add_child(kael)
	var grupo = load("res://zonas3d/grupo_3d.gd").new()
	region.add_child(grupo)
	grupo.preparar(region, kael, nombres)
	var r: Array = grupo.miembros.map(func(m): return m["nombre"])
	region.free()
	return r


# (necesita el árbol: se hace en el primer fotograma)
func _region_en_arbol() -> void:
	_limpiar()
	_ok(_acompanantes() == ["Lya", "Garon"], "6: la fila de siempre ha cambiado")
	Engine.set_meta("naira_v12", true)
	G.unir("Naira")
	_ok(_acompanantes() == ["Lya", "Garon"], "6: Naira en la reserva sale en la exploración")
	G.formar(["Kael", "Garon", "Naira"])
	var fila := _acompanantes()
	_ok(fila == ["Garon", "Naira"], "6: con Naira por Lya, la fila es %s" % [fila])
	var d: Dictionary = P.volcar("res://zonas3d/garganta_3d.tscn")   # otra región: guardar, salir y entrar
	_limpiar()
	Engine.set_meta("naira_v12", true)
	P.restaurar(d)
	_ok(_acompanantes() == ["Garon", "Naira"], "6: tras cambiar de región la fila es otra")
	G.formar(["Kael", "Naira"])
	_ok(_acompanantes() == ["Naira"], "6: con Kael y Naira la fila es otra")
	_limpiar()
	hechos.append("6: acompañantes de la exploración según la formación, también tras cambiar de región")


# ---------------------------------------------------------------- 7 (menú)
func _botones(m) -> Array:
	return m.find_children("*", "Button", true, false)


func _menu() -> void:
	_limpiar()
	var m = load("res://menus.gd").new()
	root.add_child(m)
	var textos: Array = _botones(m).map(func(b): return b.text)
	_ok(not "Formación" in textos and textos.filter(func(t): return t in G.ORDEN) == ["Kael", "Lya", "Garon"],
		"7: sin reserva, el menú cambia: %s" % [textos])
	m.free()
	Engine.set_meta("naira_v12", true)
	G.unir("Naira")
	m = load("res://menus.gd").new()
	root.add_child(m)
	textos = _botones(m).map(func(b): return b.text)
	_ok("Formación" in textos and textos.filter(func(t): return t in G.ORDEN) == ["Kael", "Lya", "Garon", "Naira"],
		"7: con reserva, sin Formación o sin la ficha de Naira: %s" % [textos])
	m.vista_formacion = true
	m._pintar_de_nuevo()
	var b_lya: Button = null
	var b_naira: Button = null
	var b_kael: Button = null
	for b in _botones(m):
		match b.get_meta("clave", ""):
			"formacion:Lya":
				b_lya = b
			"formacion:Naira":
				b_naira = b
			"formacion:Kael":
				b_kael = b
	_ok(b_lya != null and b_naira != null and b_kael != null, "7: faltan tarjetas en la Formación")
	if b_lya != null and b_naira != null and b_kael != null:
		_ok(b_kael.disabled and b_naira.disabled and not b_lya.disabled, "7: botones de la Formación (Kael fijo, grupo lleno)")
		b_lya.pressed.emit()
		_ok(G.activos() == ["Kael", "Garon"] and G.reserva() == ["Lya", "Naira"], "7: «A la reserva» no pasa a Lya")
		for b in _botones(m):
			if b.get_meta("clave", "") == "formacion:Naira":
				b.pressed.emit()
		_ok(G.activos() == ["Kael", "Garon", "Naira"], "7: «Al grupo» no pone a Naira: %s" % [G.activos()])
	m._salir_formacion()
	m._ir_a_pestana("Habilidades")
	var etiquetas: Array = m.find_children("*", "Label", true, false).map(func(l): return l.text)
	_ok(etiquetas.any(func(t): return t.contains("Eclipse") and t.contains("✔")), "7: Habilidades no enseña el Eclipse de Naira")
	_ok(etiquetas.any(func(t): return t.begins_with("Lya") and t.contains("reserva")), "7: Habilidades no marca la reserva")
	m.free()
	_limpiar()
	hechos.append("7: menú (sin reserva como siempre; Formación con tarjetas que cambian el grupo; Habilidades de Naira)")


# ---------------------------------------------------------------- 5 (combates de verdad)
func _preparar_casos() -> void:
	for modo in ["perder", "ganar", "huir"]:
		casos.append({"modo": modo, "grupo": 1})


func _siguiente_caso() -> void:
	if casos.is_empty():
		_terminar()
		return
	caso = casos.pop_front()
	_limpiar()
	Engine.set_meta("naira_v12", true)
	G.unir("Naira")                                   # a la reserva: los tres de siempre luchan
	G.datos()["Naira"]["pv"] = 5                      # herida: al perder, también se cura
	G.datos()["Naira"]["pm"] = 1
	G.datos()["Lya"]["pv"] = 30
	Engine.set_meta("grupo_combate", caso["grupo"])
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("zona", "llanura")
	antes = G.datos().duplicate(true)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	f_caso = frames
	f_fin = -1


func _exp_total(d: Dictionary) -> int:
	var t := int(d["exp"])
	for i in range(1, int(d["nivel"])):
		t += G.exp_para(i)
	return t


func _comprobar_caso() -> void:
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	_ok(nombres == ["Kael", "Lya", "Garon"], "5: con Naira en la reserva luchan %s" % [nombres])
	var naira_g := _exp_total(G.datos()["Naira"]) - _exp_total(antes["Naira"])
	match caso["modo"]:
		"perder":
			for n in ["Kael", "Lya", "Garon", "Naira"]:
				var e: Dictionary = G.estadisticas(n)
				_ok(e["pv"] == e["pv_max"] and e["pm"] == e["pm_max"], "5: tras perder, %s no vuelve con todo (%d/%d)" % [n, e["pv"], e["pv_max"]])
			_ok(naira_g == 0, "5: perder da experiencia a la reserva")
		"ganar":
			var total := 0
			for e in c.enemigos:
				if not e.get("huido", false):
					total += int(e.get("exp", 0))
			var mult: float = P.mult_exp("llanura", "normal", int(antes["Naira"]["nivel"]))
			var esperada := int(int(round(total * mult)) * G.PARTE_EXP_RESERVA)
			_ok(c.enemigos.all(func(e): return e["hp"] <= 0 or e.get("huido", false)), "5: no se gana el combate")
			_ok(naira_g == esperada and esperada > 0, "5: la reserva gana %d y tocaban %d" % [naira_g, esperada])
		"huir":
			_ok(naira_g == 0 and int(G.datos()["Naira"]["pv"]) == 5, "5: huir cambia a la reserva")
	hechos.append("5: %s con Naira en la reserva" % caso["modo"])


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		_region_en_arbol()
		_menu()
		_preparar_casos()
		_siguiente_caso()
		return false
	if c == null:
		return false
	if frames - f_caso == 5:
		if caso["modo"] == "huir":
			c._escapar()
		elif caso["modo"] == "perder":
			for h in c.heroes:
				h["hp"] = 0
			c._comprobar_fin()
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	if f_fin >= 0 and frames - f_fin >= 150:
		_comprobar_caso()
		c.queue_free()
		c = null
		_siguiente_caso()
	elif frames - f_caso > MAX_FOTOGRAMAS:
		fallos.append("5: el combate (%s) no terminó" % caso["modo"])
		c.queue_free()
		c = null
		_siguiente_caso()
	return false


func _terminar() -> void:
	_limpiar()
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for h in hechos:
		print("OK ", h)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
