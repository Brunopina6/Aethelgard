extends SceneTree
# V10, «Oakhaven, el corazón vivo del reino», sin escenas de región (datos, inventario, talleres, tienda y señales):
#   1. Forja de Kael: «Acero de la Falla» bloqueado sin Hierro de la Falla; con él, se estudia. «Frostfang templada»:
#      sin materiales no se puede; con ellos gasta exactamente lo suyo, +4 al ataque de Kael con Frostfang equipada (y
#      no con otra arma), una sola vez, el nombre lleva «+» y sobrevive a guardar y cargar.
#   2. Armaduras de Garon: «Malla rúnica» pide el bosque resuelto; la cota reforzada da +3 de defensa con la cota puesta;
#      la runa da la coraza al empezar (barrera_inicio) con la cota puesta y nada sin ella.
#   3. Botica: Mirta vende ingredientes; comprar descuenta las monedas y da el objeto; sin dinero, nada; el bálsamo solo
#      tras «La fórmula desaparecida».
#   4. Encargo A, «El pedido de Maese Ferro»: empieza, pasos, las dos decisiones (en partidas distintas) con su efecto,
#      premio una vez; con «entregado», la tienda de Oakhaven vende el hierro (más caro de lo que se paga por él).
#   5. Encargo B, «La fórmula desaparecida»: Pip, las tres páginas (una vez cada una), el final con su premio una vez,
#      la investigación de Lya y el Bálsamo en combate (cura a todo el grupo).
#   6. Servicios: forja, armaduras y botica se abren sin errores y se cierran.

const ARCHIVO := "user://prueba_oakhaven_v10.save"
var fallos := 0
var P
var Inv
var I
var T
var G
var X
var Oak
var E


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _limpiar() -> void:
	for k in ["hitos", "inventario", "investigaciones", "grupo", "decisiones", "mazmorras"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.unir("Lya")
	G.unir("Garon")


func _initialize() -> void:
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	I = load("res://investigacion.gd")
	T = load("res://talleres.gd")
	G = load("res://grupo.gd")
	X = load("res://equipo_extra.gd")
	Oak = load("res://ciudades/oakhaven.gd")
	E = load("res://encargos.gd")
	_probar.call_deferred()


func _probar() -> void:
	_forja()
	_armaduras()
	await _botica()
	_encargo_a()
	_encargo_b()
	await _servicios()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _forja() -> void:
	_limpiar()
	var ataque0: int = G.estadisticas("Kael")["ataque"]
	if I.estado("kael_forja_falla") != "bloqueada":
		_fallo("1: «Acero de la Falla» se abre sin el hierro")
	Inv.agregar_objeto("Hierro de la Falla", 1)
	I.empezar("kael_forja_falla")
	I.avanzar("kael_forja_falla", 1)
	if I.estado("kael_forja_falla") != "completada":
		_fallo("1: con el hierro no se estudia «Acero de la Falla»")
	if T.puede("frostfang_falla") == "":
		_fallo("1: se puede templar Frostfang sin musgo")
	Inv.agregar_objeto("Musgo de piedra", 3)
	if not T.fabricar("frostfang_falla"):
		_fallo("1: no se templa Frostfang con todo (%s)" % T.puede("frostfang_falla"))
	if Inv.cantidad("Hierro de la Falla") != 0 or Inv.cantidad("Musgo de piedra") != 2:
		_fallo("1: el consumo no es exacto (hierro %d, musgo %d)" % [Inv.cantidad("Hierro de la Falla"), Inv.cantidad("Musgo de piedra")])
	if G.estadisticas("Kael")["ataque"] != ataque0 + 4:
		_fallo("1: el ataque de Kael es %d y debía ser %d" % [G.estadisticas("Kael")["ataque"], ataque0 + 4])
	if not str(Inv.objeto("frostfang")["nombre"]).ends_with("+"):
		_fallo("1: Frostfang mejorada no se distingue en el menú")
	Inv.agregar_objeto("Hierro de la Falla", 1)
	if T.fabricar("frostfang_falla"):
		_fallo("1: se templa Frostfang dos veces")
	Inv.equipar("Kael", "arma", "colmillo_nocturno")
	var con_otra: int = G.estadisticas("Kael")["ataque"]
	Inv.equipar("Kael", "arma", "frostfang")
	if con_otra == G.estadisticas("Kael")["ataque"] and ataque0 + 4 == G.estadisticas("Kael")["ataque"] \
			and Inv.objeto("colmillo_nocturno").has("mejorado"):
		_fallo("1: la mejora se aplica también a otra arma")
	var d: Dictionary = P.volcar("res://mapa.tscn")
	P.escribir(d, ARCHIVO)
	var leida = P.leer(ARCHIVO)
	Engine.remove_meta("inventario")
	P.restaurar(leida)
	if G.estadisticas("Kael")["ataque"] != ataque0 + 4:
		_fallo("1: la mejora de Frostfang no sobrevive a guardar y cargar")


func _armaduras() -> void:
	_limpiar()
	if not Inv.equipar("Garon", "cuerpo", "cota_malla"):
		_fallo("2: Garon no puede ponerse la cota de malla")
	var def0: int = G.estadisticas("Garon")["defensa"]
	Inv.agregar_objeto("Musgo de piedra", 5)
	Inv.agregar_objeto("Hierro de la Falla", 1)
	Inv.agregar_objeto("Savia clara", 1)
	Inv.agregar_objeto("Mineral rúnico", 1)
	if I.estado("garon_cota_runica") != "bloqueada":
		_fallo("2: «Malla rúnica» se abre sin resolver lo del bosque")
	P.poner_hito("bq_resuelto")
	I.empezar("garon_cota_runica")
	I.avanzar("garon_cota_runica", 1)
	if not T.fabricar("cota_reforzada") or G.estadisticas("Garon")["defensa"] != def0 + 3:
		_fallo("2: la cota reforzada no suma +3 de defensa (%d → %d)" % [def0, G.estadisticas("Garon")["defensa"]])
	if not T.fabricar("cota_runica"):
		_fallo("2: no se graba la runa (%s)" % T.puede("cota_runica"))
	if not is_equal_approx(float(X.efectos_de("Garon").get("barrera_inicio", 0.0)), 0.1):
		_fallo("2: la runa no da la coraza al empezar con la cota puesta")
	Inv.equipar("Garon", "cuerpo", "ropa_viaje")
	if float(X.efectos_de("Garon").get("barrera_inicio", 0.0)) > 0.0:
		_fallo("2: la runa sigue sin llevar la cota")


func _botica() -> void:
	_limpiar()
	var tienda = load("res://tienda.gd").new()
	tienda.solo_botica = true
	root.add_child(tienda)
	await process_frame
	if tienda.pestanas != ["Botica"]:
		_fallo("3: la botica muestra más pestañas: %s" % [tienda.pestanas])
	var oro: int = Inv.oro()
	tienda._comprar_botica("Hierba lunar")
	if Inv.oro() != oro - 15 or Inv.cantidad("Hierba lunar") != 1:
		_fallo("3: comprar Hierba lunar no descuenta 15 o no la da")
	Inv.gastar_oro(Inv.oro())
	tienda._comprar_botica("Savia clara")
	if Inv.cantidad("Savia clara") != 0 or Inv.oro() != 0:
		_fallo("3: se compra sin dinero")
	if tienda.botica_objetos().has("Bálsamo de Mirta"):
		_fallo("3: el bálsamo se vende antes de recuperar la fórmula")
	tienda.queue_free()
	await process_frame


func _encargo_a() -> void:
	for decision in ["kael", "entregado"]:
		_limpiar()
		var e: Dictionary = E.de("enc_herrero")
		if e.is_empty() or E.estado(e) != "oculto":
			_fallo("4: el encargo del herrero no existe o se ve antes de tiempo")
			return
		if Oak.aplicar_senal("oak:herrero_pedido") == "" or E.estado(e) != "activo":
			_fallo("4: Ferro no empieza su encargo")
		if Oak.aplicar_senal("oak:hierro_kael") != "":
			_fallo("4: se decide sin tener el hierro")
		P.poner_hito("enc_herrero_pista")
		P.poner_hito("enc_herrero_veta")
		Inv.agregar_objeto("Hierro de la Falla", 1)
		if E.paso_actual(e).get("id", "") != "decidir":
			_fallo("4: tras la veta, el paso no es decidir")
		# 14/11: mientras Ferro lo espera, el hierro no se vende ni se gasta en el taller (si no, su escena se repetía)
		if not load("res://talleres.gd").reservado("Hierro de la Falla"):
			_fallo("4: con el encargo pendiente, el hierro se puede vender o gastar")
		var oro: int = Inv.oro()
		Oak.aplicar_senal("oak:hierro_entregar" if decision == "entregado" else "oak:hierro_kael")
		if load("res://talleres.gd").reservado("Hierro de la Falla"):
			_fallo("4: decidido el encargo, el hierro sigue reservado")
		if E.estado(e) != "hecho" or str(Engine.get_meta("decisiones", {}).get("hierro_ferro", "")) != decision:
			_fallo("4: la decisión «%s» no termina el encargo" % decision)
		if decision == "entregado":
			if Inv.oro() != oro + 80 or Inv.cantidad("Hierro de la Falla") != 0:
				_fallo("4: entregar no paga 80 ni se lleva el hierro")
			var venta: Dictionary = load("res://tienda.gd").objetos_de(0)
			if venta.get("Hierro de la Falla", 0) <= int(X.materiales()["Hierro de la Falla"]["venta"]):
				_fallo("4: el hierro no se vende en Oakhaven o se vende demasiado barato")
		elif Inv.cantidad("Hierro de la Falla") != 1:
			_fallo("4: quedárselo no deja el hierro a Kael")
		Oak.aplicar_senal("oak:hierro_entregar")
		if Inv.oro() > oro + 80:
			_fallo("4: el premio se cobra dos veces")
	# 15/11 (auditoría): partida antigua que ya perdió el hierro: Ferro lo nota, el Diario lo explica, nada se cierra solo
	_limpiar()
	var e2: Dictionary = E.de("enc_herrero")
	for h in ["enc_herrero_pedido", "enc_herrero_pista", "enc_herrero_veta"]:
		P.poner_hito(h)
	if not Oak.hierro_perdido():
		_fallo("4b: veta picada, pedido pendiente y sin hierro no se reconoce como hierro perdido")
	if Oak.dialogo_de("ferro", 0).get_file().get_basename() != "oak_ferro_sin_hierro":
		_fallo("4b: sin el hierro, Ferro dice «%s»" % Oak.dialogo_de("ferro", 0).get_file())
	if not E.pistas_conocidas(e2).any(func(x): return "aún queda" in x):
		_fallo("4b: el Diario no dice dónde recuperar el hierro")
	if Oak.aplicar_senal("oak:hierro_entregar") != "" or P.hito("enc_herrero_fin"):
		_fallo("4b: sin el hierro, el encargo se cierra")
	Inv.agregar_objeto("Hierro de la Falla", 1)
	if Oak.hierro_perdido() or Oak.dialogo_de("ferro", 0).get_file().get_basename() != "oak_ferro_veta":
		_fallo("4b: con el hierro recuperado, Ferro no vuelve a su escena de decidir")
	if E.pistas_conocidas(e2).any(func(x): return "aún queda" in x):
		_fallo("4b: con el hierro, el Diario sigue mandando a la veta")


func _encargo_b() -> void:
	_limpiar()
	var e: Dictionary = E.de("enc_formula")
	Oak.aplicar_senal("oak:formula_pedido")
	if E.estado(e) != "activo":
		_fallo("5: Mirta no empieza su encargo")
	if Oak.aplicar_senal("oak:pagina_1") != "":
		_fallo("5: se recoge una página antes de hablar con Pip")
	Oak.aplicar_senal("oak:formula_pip")
	for i in [1, 2, 3]:
		Oak.aplicar_senal("oak:pagina_%d" % i)
	if Oak.aplicar_senal("oak:pagina_2") != "":
		_fallo("5: una página se recoge dos veces")
	if not P.hito("enc_formula_paginas") or E.paso_actual(e).get("id", "") != "volver":
		_fallo("5: las tres páginas no completan su paso")
	if I.estado("lya_formula_mirta") == "bloqueada":
		_fallo("5: con las páginas, Lya no puede investigar la fórmula")
	var oro: int = Inv.oro()
	Oak.aplicar_senal("oak:formula_fin")
	if E.estado(e) != "hecho" or Inv.oro() != oro + 40 or Inv.cantidad("Bálsamo de Mirta") != 2:
		_fallo("5: el final no da 40 monedas y 2 Bálsamos")
	Oak.aplicar_senal("oak:formula_fin")
	if Inv.cantidad("Bálsamo de Mirta") != 2:
		_fallo("5: el premio se cobra dos veces")
	if not load("res://tienda.gd").botica_objetos().has("Bálsamo de Mirta"):
		_fallo("5: la botica no vende el bálsamo tras el encargo")
	var o: Dictionary = load("res://combate.gd").OBJETOS_COMBATE.get("Bálsamo de Mirta", {})
	if o.get("que", "") != "PV_TODOS" or int(o.get("cura", 0)) != 45:
		_fallo("5: el Bálsamo no cura a todo el grupo en combate")


func _servicios() -> void:
	_limpiar()
	P.poner_hito("bq_alquimia")
	var S = load("res://servicios.gd")
	for s in ["forja", "armaduras", "botica"]:
		var capa := CanvasLayer.new()
		root.add_child(capa)
		var n = S.abrir(capa, s)
		await process_frame
		if n == null or not n.has_signal("cerrado"):
			_fallo("6: el servicio «%s» no se abre" % s)
		elif s == "botica":
			var b: Array = n.find_children("*", "Button", true, false).map(func(x): return x.text)
			if not "Comprar ingredientes" in b or not "Alquimia de Lya" in b:
				_fallo("6: la botica no ofrece comprar y la alquimia de Lya (%s)" % [b])
		capa.queue_free()
		await process_frame
