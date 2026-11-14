extends SceneTree
# V12 (14/11, fase 7): las misiones de Oakhaven y «La caravana perdida» en el Diario (encargos.gd, diario.gd y
# gremio.gd), con datos aislados y su propia partida. Sin escenas de región.
#   1. Registro: «La caravana perdida» (datos/encargos_desierto.gd) entra en el registro; ids únicos; cada condición
#      de empieza, fin, pasos y pistas es de un tipo conocido; tipos válidos; las pistas son textos cortos.
#   2. Nada se adelanta: en cada encargo y en cada punto del recorrido (los pasos hechos uno a uno), pasos_conocidos da
#      solo los hechos y el actual; en el Diario no aparece el texto de ningún paso posterior al actual.
#   3. Pistas: las páginas de Mirta salen una a una al recogerlas (señales de verdad); el pilar con y sin Garon; la
#      decisión del hierro se recuerda tras acabar (y solo la tomada); Rosa y su lavanda; la caravana (sello, llave,
#      mural), cada una solo tras su hito.
#   4. Secretos: «Un secreto por una moneda» no sale (ni el Patio de las Velas) hasta pagar a Pip; después, rotulado
#      «Secreto».
#   5. Gremio: un contrato aceptado sale en el Diario con su progreso y «listo» al cumplirse; los no aceptados, no.
#   6. Guardar y cargar (disco aislado): pasos y pistas iguales tras cargar; una partida antigua sin nada de esto pinta
#      el Diario sin errores (mensaje de «Aún no tienes encargos»).
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_diario_misiones.save"
const TIPOS_COND := ["hito", "decision", "grupo", "oro", "ganado", "material", "investigacion", "hecha", "estado_de",
	"estado", "cond", "modo"]
var E
var P
var Oak
var Gr
var Inv
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	E = load("res://encargos.gd")
	P = load("res://progreso.gd")
	Oak = load("res://ciudades/oakhaven.gd")
	Gr = load("res://gremio.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await process_frame
	_limpiar()
	_registro()
	await _sin_adelantar()
	_limpiar()
	await _pistas()
	_limpiar()
	await _secreto()
	_limpiar()
	await _gremio()
	await _guardar()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# El texto de la pestaña Encargos del Diario, de verdad (diario.gd).
func _diario() -> String:
	var d = load("res://diario.gd").new()
	d.pestana = "Encargos"
	root.add_child(d)
	await process_frame
	var textos := ""
	for n in d.find_children("*", "Label", true, false):
		textos += (n as Label).text + "\n"
	d.queue_free()
	await process_frame
	return textos


func _conds(c) -> Array:
	var r: Array = []
	for parte in (c if c is Array else [c]):
		var s := str(parte).trim_prefix("!")
		if s != "":
			r.append(s)
	return r


# 1
func _registro() -> void:
	var ids := {}
	var caravana := false
	for e in E.todos():
		var m: Dictionary = e["m"]
		_ok(not ids.has(m["id"]), "1: id repetido «%s»" % m["id"])
		ids[m["id"]] = true
		caravana = caravana or (m["id"] == "mc_caravana_perdida" and e["lugar"] == "Mar de Cristal")
		_ok(str(m.get("tipo", "secundaria")) in E.TIPOS, "1: «%s» tiene un tipo desconocido" % m["id"])
		var todas: Array = _conds(m.get("empieza", "")) + _conds(m.get("fin", ""))
		for p in m.get("pasos", []):
			todas += _conds(p.get("hecho", ""))
		for p in m.get("pistas", []):
			todas += _conds(p.get("si", ""))
			_ok(str(p.get("texto", "")).length() > 0 and str(p["texto"]).length() <= 120,
				"1: pista de «%s» vacía o larga (%d)" % [m["id"], str(p.get("texto", "")).length()])
			for prohibida in ["Érebo", "corazon", "corazón", "recuerdos que guarda"]:
				_ok(not str(p["texto"]).contains(prohibida), "1: pista de «%s» con «%s»" % [m["id"], prohibida])
		for s in todas:
			_ok(s.get_slice(":", 0) in TIPOS_COND, "1: «%s» con condición desconocida «%s»" % [m["id"], s])
	_ok(caravana, "1: «La caravana perdida» no está en el registro (o no en el Mar de Cristal)")
	_ok(ids.has("oak_favores") and ids.has("enc_formula") and ids.has("enc_herrero"), "1: faltan las misiones de Oakhaven")


# Cumple la condición «hecho» de un paso, de la forma más directa (hito, estado o decisión).
func _cumplir(c) -> void:
	for x in _conds(c):
		var s := str(x)
		var tipo := s.get_slice(":", 0)
		var v := s.substr(tipo.length() + 1)
		match tipo:
			"hito":
				P.poner_hito(v)
			"estado":
				P.poner_estado(Oak.NOMBRE, v)
			"estado_de":
				P.poner_estado(v.get_slice("/", 0), v.get_slice("/", 1))
			"decision":
				var d: Dictionary = Engine.get_meta("decisiones", {})
				d[v.get_slice("=", 0)] = v.get_slice("=", 1)
				Engine.set_meta("decisiones", d)


# 2. Paso a paso, en todos los encargos con pasos: solo los hechos y el actual; nada posterior en el Diario.
func _sin_adelantar() -> void:
	for e in E.todos():
		var m: Dictionary = e["m"]
		var pasos: Array = m.get("pasos", [])
		if pasos.size() < 2 or m.has("coste"):
			continue
		_limpiar()
		_cumplir(m["empieza"])
		if E.estado(e) != "activo":
			continue                                     # (se empieza con algo que esta prueba no simula)
		for i in pasos.size() - 1:
			var conocidos: Array = E.pasos_conocidos(e)
			_ok(conocidos.size() == i + 1 and not conocidos[i]["hecho"] and conocidos[i]["id"] == pasos[i]["id"],
				"2: «%s» en el paso %d enseña %d pasos" % [m["id"], i, conocidos.size()])
			if i < 2:                                     # (el Diario de verdad en los dos primeros puntos)
				var texto: String = await _diario()
				_ok(texto.contains("Ahora: " + str(pasos[i]["texto"])), "2: el Diario no dice el paso actual de «%s»" % m["id"])
				for j in range(i + 1, pasos.size()):
					_ok(not texto.contains(str(pasos[j]["texto"])),
						"2: el Diario adelanta el paso «%s» de «%s»" % [pasos[j]["id"], m["id"]])
			_cumplir(pasos[i]["hecho"])


# 3. Las pistas, con las señales y los hitos de verdad.
func _pistas() -> void:
	# las páginas de Mirta
	Oak.aplicar_senal("oak:formula_pedido")
	var formula: Dictionary = E.de("enc_formula")
	_ok(E.pistas_conocidas(formula).is_empty(), "3: hay pistas de Mirta antes de recoger páginas")
	Oak.aplicar_senal("oak:formula_pip")
	Oak.aplicar_senal("oak:pagina_2")
	var p: Array = E.pistas_conocidas(formula)
	_ok(p.size() == 1 and p[0].contains("la savia, clara"), "3: tras la página 2, las pistas son %s" % [p])
	var t: String = await _diario()
	_ok(t.contains("la savia, clara") and not t.contains("dos de hierba lunar"), "3: el Diario no enseña solo la página recogida")
	_ok(t.contains("✔ Pregunta por la ciudad"), "3: el Diario no recuerda el objetivo cumplido (Pip)")
	Oak.aplicar_senal("oak:pagina_1")
	Oak.aplicar_senal("oak:pagina_3")
	_ok(E.pistas_conocidas(formula).size() == 3, "3: con las tres páginas no hay tres pistas")
	# el pilar del herrero, con y sin Garon, y la decisión
	var herrero: Dictionary = E.de("enc_herrero")
	Oak.aplicar_senal("oak:herrero_pedido")
	P.poner_hito("enc_herrero_pista")
	Engine.set_meta("grupo_activo", ["Kael"])
	p = E.pistas_conocidas(herrero)
	_ok(p.size() == 1 and p[0].contains("vetas oscuras"), "3: sin Garon, la pista del pilar es %s" % [p])
	P.poner_hito("enc_herrero_veta")
	Inv.agregar_objeto("Hierro de la Falla", 1)
	_ok(Oak.aplicar_senal("oak:hierro_kael") != "", "3: no se puede decidir quedarse el hierro")
	_ok(E.estado(herrero) == "hecho", "3: tras decidir, el encargo del herrero no está hecho")
	p = E.pistas_conocidas(herrero)
	_ok(p.any(func(x): return x.contains("Kael se quedó el hierro")) and not p.any(func(x): return x.contains("entregarle")),
		"3: el Diario no recuerda la decisión tomada (o recuerda la otra): %s" % [p])
	t = await _diario()
	_ok(t.contains("Kael se quedó el hierro"), "3: la decisión no sale en el Diario")
	# Rosa
	var lavanda: Dictionary = E.de("oak_lavanda")
	_ok(E.pistas_conocidas(lavanda).is_empty(), "3: la pista de Rosa sale antes de pedírsela")
	Oak.aplicar_senal("oak:lavanda_pedida")
	_ok(E.pistas_conocidas(lavanda).size() == 1, "3: lo que dijo Rosa no sale al pedir la lavanda")
	# la caravana, pista a pista
	var car: Dictionary = E.de("mc_caravana_perdida")
	_ok(E.estado(car) == "oculto", "3: la caravana sale antes de hablar con Ismena")
	P.poner_hito("mc_inicio")
	_ok(E.estado(car) == "activo" and E.pistas_conocidas(car).is_empty(), "3: la caravana empieza mal o con pistas")
	for h in ["mc_caravana", "mc_sello"]:
		P.poner_hito(h)
	p = E.pistas_conocidas(car)
	_ok(p.size() == 1 and p[0].contains("sello"), "3: tras el sello, las pistas de la caravana son %s" % [p])
	t = await _diario()
	_ok(t.contains("La caravana perdida · Mar de Cristal") and not t.contains("Espejismos") and not t.contains("trampilla"),
		"3: el Diario de la caravana adelanta el mural o la trampilla")
	for h in ["mc_tormenta", "mc_ruinas", "mc_llave", "mc_superviviente", "mc_fin"]:
		P.poner_hito(h)
	_ok(E.estado(car) == "hecho" and E.pistas_conocidas(car).size() == 3, "3: la caravana acabada no recuerda sus tres pistas")


# 4. El secreto de Pip.
func _secreto() -> void:
	var t: String = await _diario()
	_ok(not t.contains("Un secreto por una moneda") and not t.contains("Patio de las Velas"), "4: el secreto sale sin pagar")
	Inv.ganar_oro(5)
	_ok(Oak.aplicar_senal("oak:pip_pagar") != "", "4: no se puede pagar a Pip")
	t = await _diario()
	_ok(t.contains("Un secreto por una moneda · Oakhaven · Secreto"), "4: tras pagar, el secreto no sale rotulado")


# 5. Los contratos del gremio.
func _gremio() -> void:
	_ok(Gr.para_diario().is_empty() and not Engine.has_meta("gremio"), "5: sin gremio hay contratos (o se crea la partida)")
	Gr.aceptar("gr_limos")
	var t: String = await _diario()
	_ok(t.contains("Contratos del gremio · Rango Bronce") and t.contains("Plaga de limos · 0 de 3"),
		"5: el contrato aceptado no sale con su progreso")
	_ok(not t.contains("Musgo para la botica"), "5: sale un contrato no aceptado")
	Gr.contar_derrotas(["slime", "slime", "slime"])
	t = await _diario()
	_ok(t.contains("Plaga de limos · listo"), "5: el contrato cumplido no dice que está listo")
	Gr.cobrar("gr_limos")
	_ok(Gr.para_diario().is_empty(), "5: el contrato cobrado sigue en el Diario")


# 6. Guardar y cargar, y una partida antigua.
func _guardar() -> void:
	_limpiar()
	Oak.aplicar_senal("oak:formula_pedido")
	Oak.aplicar_senal("oak:formula_pip")
	Oak.aplicar_senal("oak:pagina_3")
	P.poner_hito("mc_inicio")
	P.poner_hito("mc_caravana")
	Gr.aceptar("gr_musgo")
	var antes: String = await _diario()
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(P.escribir(d, ARCHIVO), "6: no se pudo escribir la partida")
	_limpiar()
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "6: no se pudo leer la partida")
	if leida is Dictionary:
		P.restaurar(leida)
	var despues: String = await _diario()
	_ok(antes == despues and despues.contains("acuna") and despues.contains("Musgo para la botica"),
		"6: tras cargar, el Diario no es el mismo")
	var vieja: Dictionary = (leida as Dictionary).duplicate(true) if leida is Dictionary else {}
	for k in ["hitos", "mazmorras", "decisiones", "gremio"]:
		vieja.erase(k)
	_limpiar()
	P.restaurar(vieja)
	var v: String = await _diario()
	_ok(v.contains("Aún no tienes encargos"), "6: una partida antigua sin encargos no pinta el Diario vacío")
