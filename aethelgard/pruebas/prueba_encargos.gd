extends SceneTree
# Encargos (V9; encargos.gd, datos/encargos_pastos.gd y las MISIONES de Oakhaven), sin escenas de región:
#   1. El registro reúne los de Oakhaven y los de Pastos Verdes, con ids únicos y todas sus condiciones bien escritas
#      (cada tipo lo entiende encargos.gd o el módulo de su región).
#   2. «Canela se ha perdido»: oculto hasta que Pip lo pide (señal oak:pip_perro); el paso actual avanza con las huellas
#      y al encontrarla; devolvérsela (oak:pip_perro_fin) lo termina y da 40 monedas y 2 Pociones UNA sola vez.
#   3. «El bosque que no recuerda» y «Noticias para Encina» siguen los hitos de la aventura y el estado de Oakhaven.
#   4. El Diario pinta la pestaña «Encargos» sin errores.

var fallos := 0
var E
var P
var Oak
var Inv


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _initialize() -> void:
	E = load("res://encargos.gd")
	P = load("res://progreso.gd")
	Oak = load("res://ciudades/oakhaven.gd")
	Inv = load("res://inventario.gd")
	for k in ["hitos", "inventario", "mazmorras", "decisiones"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	_probar.call_deferred()


func _conds(e: Dictionary) -> Array:
	var r: Array = [e["m"].get("empieza", ""), e["m"].get("fin", "")]
	for p in e["m"].get("pasos", []):
		r.append(p.get("hecho", ""))
	return r


func _probar() -> void:
	# 1
	var todos: Array = E.todos()
	var ids := {}
	var de_pastos := 0
	for e in todos:
		var id: String = e["m"]["id"]
		if ids.has(id):
			_fallo("1: id repetido «%s»" % id)
		ids[id] = true
		if e["fuente"].ends_with("encargos_pastos.gd"):
			de_pastos += 1
		for c in _conds(e):
			for parte in (c if c is Array else [c]):
				var s := str(parte).trim_prefix("!")
				if s == "":
					continue
				var tipo := s.get_slice(":", 0)
				if not tipo in ["hito", "decision", "grupo", "oro", "ganado", "material", "investigacion", "hecha",
						"estado_de", "estado", "cond", "modo"]:
					_fallo("1: «%s» (%s) tiene una condición de tipo desconocido: %s" % [id, e["fuente"], s])
	if de_pastos != 4 or not ids.has("oak_favores") or not ids.has("oak_lavanda"):
		_fallo("1: el registro no reúne los encargos de las dos regiones (%s)" % [ids.keys()])
	# 2
	var perro: Dictionary = E.de("enc_perro")
	if E.estado(perro) != "oculto":
		_fallo("2: «Canela» se ve antes de que Pip lo pida")
	if Oak.aplicar_senal("oak:pip_perro") == "" or E.estado(perro) != "activo":
		_fallo("2: la señal de Pip no empieza el encargo")
	if E.paso_actual(perro).get("id", "") != "huellas":
		_fallo("2: el primer paso no es el de las huellas")
	P.poner_hito("enc_perro_huellas")
	if E.paso_actual(perro).get("id", "") != "encontrar":
		_fallo("2: tras las huellas, el paso no es encontrarla")
	if Oak.aplicar_senal("oak:pip_perro_fin") != "":
		_fallo("2: se puede devolver a Canela sin haberla encontrado")
	P.poner_hito("enc_perro_encontrado")
	var oro: int = Inv.oro()
	var pociones: int = Inv.cantidad("Poción")
	var texto: String = Oak.aplicar_senal("oak:pip_perro_fin")
	if texto == "" or E.estado(perro) != "hecho":
		_fallo("2: devolver a Canela no termina el encargo")
	if Inv.oro() != oro + 40 or Inv.cantidad("Poción") != pociones + 2:
		_fallo("2: la recompensa no es 40 monedas y 2 Pociones (%s)" % texto)
	Oak.aplicar_senal("oak:pip_perro_fin")
	if Inv.oro() != oro + 40:
		_fallo("2: la recompensa se cobra dos veces")
	# 3
	var bosque: Dictionary = E.de("bq_bosque")
	if E.estado(bosque) != "oculto":
		_fallo("3: el bosque se ve antes de empezar")
	P.poner_hito("bq_inicio")
	P.poner_hito("bq_arbol")
	if E.estado(bosque) != "activo" or E.paso_actual(bosque).get("id", "") != "pistas":
		_fallo("3: el bosque no sigue sus hitos")
	P.poner_hito("bq_resuelto")
	var encina: Dictionary = E.de("bq_encina")
	if E.estado(bosque) != "hecho" or E.estado(encina) != "activo":
		_fallo("3: al resolverlo, el bosque no termina o Encina no empieza")
	P.poner_estado(Oak.NOMBRE, "encina_bosque")
	if E.estado(encina) != "hecho":
		_fallo("3: hablar con Encina no termina su encargo")
	# 4
	var d = load("res://diario.gd").new()
	d.pestana = "Encargos"
	root.add_child(d)
	await process_frame
	d._pintar()
	await process_frame
	var textos := ""
	for n in d.find_children("*", "Label", true, false):
		textos += (n as Label).text + "\n"
	if not textos.contains("Canela se ha perdido") or not textos.contains("El bosque que no recuerda"):
		_fallo("4: la pestaña Encargos no muestra los encargos")
	d.queue_free()
	await process_frame
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
