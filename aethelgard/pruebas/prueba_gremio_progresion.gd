extends SceneTree
# V12 (14/11, fase 7): la progresión ENTERA del Gremio de aventureros (gremio.gd), con datos aislados y su propia partida.
# Antes, Oro pedía 15 de reputación y antes de Oro solo había 13 (el bloqueo del encargo del coordinador).
#   1. Invariante de datos: cada rango se alcanza con la reputación de los contratos de los rangos anteriores (si alguien
#      añade un rango o cambia un premio y vuelve el bloqueo, falla aquí).
#   2. Bronce → Plata → Oro jugando como un jugador: cada contrato con su condición real (limos y Grimfang caídos con
#      contar_derrotas, el musgo y el mineral en el inventario, el hito de Mirta y el nido de la Garganta ganado), sin
#      tocar la reputación a mano; Oro llega justo con el último contrato de Plata y abre «El encargo del maestro».
#   3. El encargo de Oro se cobra (gasta el Mineral rúnico) y la reputación final es la suma de todos los premios.
#   4. Guardar y cargar en Oro (disco aislado); una partida de ANTES del ajuste con 13 de reputación (atascada en Plata)
#      carga en Oro sin perder nada; una partida antigua sin gremio sigue empezando en Bronce.
#   5. La ventana del tablón en Oro: cabecera «Rango Oro» sin «faltan», y el encargo del maestro se puede aceptar.
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_gremio_progresion.save"
var Gr
var P
var Inv
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Gr = load("res://gremio.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(3)
	_limpiar()
	_invariante()
	_jugar()
	_guardar()
	await _ventana()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# 1. Cada rango r se alcanza con los contratos de rango < r (la reputación solo sube al cobrar).
func _invariante() -> void:
	for r in range(1, Gr.RANGOS.size()):
		var accesible := 0
		for c in Gr.CONTRATOS:
			if int(c["rango"]) < r:
				accesible += int(c["premio"].get("rep", 0))
		var pide := int(Gr.RANGOS[r]["rep"])
		print("Rango %s: pide %d, accesibles antes %d" % [Gr.RANGOS[r]["nombre"], pide, accesible])
		_ok(accesible >= pide, "1: %s pide %d y antes solo hay %d de reputación" % [Gr.RANGOS[r]["nombre"], pide, accesible])
	var hay_de_cada := {}
	for c in Gr.CONTRATOS:
		hay_de_cada[int(c["rango"])] = true
	_ok(hay_de_cada.size() == Gr.RANGOS.size(), "1: algún rango no tiene contratos (%s)" % [hay_de_cada.keys()])


func _hacer(id: String) -> String:
	_ok(Gr.estado(id) == "disponible", "2: «%s» no está disponible (%s, rango %s)" % [id, Gr.estado(id), Gr.nombre_rango()])
	_ok(Gr.aceptar(id), "2: no se acepta «%s»" % id)
	var c: Dictionary = Gr.contrato(id)
	match c["tipo"]:
		"derrotar":
			var caidos: Array = []
			for i in int(c["n"]):
				caidos.append(c["que"])
			Gr.contar_derrotas(caidos + ["otro_enemigo"])
		"entregar":
			Inv.agregar_objeto(c["que"], int(c["n"]))
		"cumplir":
			var q: String = c["que"]
			if q.begins_with("hito:"):
				P.poner_hito(q.trim_prefix("hito:"))
			elif q.begins_with("ganado:"):
				var g: Dictionary = Engine.get_meta("combates_ganados", {})
				g[q.trim_prefix("ganado:")] = true
				Engine.set_meta("combates_ganados", g)
	_ok(Gr.estado(id) == "listo", "2: «%s» cumplido no está listo (%s)" % [id, Gr.estado(id)])
	var t: String = Gr.cobrar(id)
	_ok(t != "" and Gr.estado(id) == "hecho", "2: «%s» no se cobra" % id)
	_ok(Gr.cobrar(id) == "", "2: «%s» se cobra dos veces" % id)
	return t


# 2 y 3. Toda la progresión, en el orden del tablón.
func _jugar() -> void:
	_ok(Gr.nombre_rango() == "Bronce" and Gr.reputacion() == 0, "2: no empieza en Bronce con 0")
	var t := ""
	for id in ["gr_limos", "gr_musgo", "gr_formula"]:
		_ok(Gr.nombre_rango() == "Bronce", "2: antes de «%s» ya no es Bronce" % id)
		t = _hacer(id)
	_ok(Gr.nombre_rango() == "Plata" and t.contains("¡Rango Plata"), "2: el último de Bronce no sube a Plata («%s»)" % t)
	_ok(Gr.estado("gr_ambar") == "bloqueado", "2: en Plata el encargo de Oro no está bloqueado")
	t = _hacer("gr_hachas")
	_ok(Gr.nombre_rango() == "Plata" and Gr.falta_rango() > 0, "2: tras las hachas ya es Oro (%d)" % Gr.reputacion())
	t = _hacer("gr_garganta")
	_ok(Gr.nombre_rango() == "Oro" and t.contains("¡Rango Oro"),
		"2: con todos los contratos de Bronce y Plata no se llega a Oro (reputación %d, «%s»)" % [Gr.reputacion(), t])
	_ok(Gr.falta_rango() == 0, "2: en Oro aún falta reputación (%d)" % Gr.falta_rango())
	# 3. El encargo de Oro: gasta el mineral; la reputación final es la suma de todos los premios.
	var oro0: int = Inv.oro()
	Inv.agregar_objeto("Mineral rúnico", 1)
	var minerales: int = Inv.cantidad("Mineral rúnico")
	_ok(Gr.estado("gr_ambar") == "disponible" and Gr.aceptar("gr_ambar"), "3: en Oro no se acepta el encargo del maestro")
	_ok(Gr.estado("gr_ambar") == "listo", "3: con el mineral el encargo del maestro no está listo")
	t = Gr.cobrar("gr_ambar")
	var suma := 0
	for c in Gr.CONTRATOS:
		suma += int(c["premio"].get("rep", 0))
	_ok(t.contains("150 monedas") and Inv.oro() == oro0 + 150 and Inv.cantidad("Mineral rúnico") == minerales - 1,
		"3: el encargo del maestro no paga 150 o no gasta el mineral («%s»)" % t)
	_ok(Gr.reputacion() == suma and Gr.nombre_rango() == "Oro", "3: reputación final %d (esperada %d)" % [Gr.reputacion(), suma])
	for c in Gr.CONTRATOS:
		_ok(Gr.estado(c["id"]) == "hecho", "3: «%s» no está hecho al final" % c["id"])


# 4. Guardar y cargar en Oro, y la partida de antes del ajuste (13 de reputación, atascada en Plata).
func _guardar() -> void:
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(P.escribir(d, ARCHIVO), "4: no se pudo escribir la partida de prueba")
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary and int(leida.get("gremio", {}).get("rep", -1)) == Gr.reputacion(), "4: el gremio no llega al disco")
	var copia: Dictionary = str_to_var(var_to_str(d))
	Engine.remove_meta("gremio")
	P.restaurar(copia)
	_ok(Gr.nombre_rango() == "Oro" and Gr.estado("gr_ambar") == "hecho", "4: tras cargar ya no es Oro")
	# La partida de antes del ajuste: los cinco contratos de Bronce y Plata cobrados, 13 de reputación, en Plata.
	var antes: Dictionary = copia.duplicate(true)
	antes["gremio"] = {"rep": 13, "aceptados": {}, "hechos": ["gr_limos", "gr_musgo", "gr_formula", "gr_hachas", "gr_garganta"],
		"proyectos": ["pr_braseros"]}
	P.restaurar(antes)
	_ok(Gr.reputacion() == 13 and Gr.nombre_rango() == "Oro", "4: la partida atascada en 13 no carga en Oro (%s)" % Gr.nombre_rango())
	_ok(Gr.estado("gr_ambar") == "disponible" and Gr.proyecto_hecho("pr_braseros") and Gr.estado("gr_hachas") == "hecho",
		"4: la partida antigua pierde progreso o no abre el encargo de Oro")
	# Una partida aún más antigua, sin gremio: Bronce.
	var vieja: Dictionary = copia.duplicate(true)
	vieja.erase("gremio")
	P.restaurar(vieja)
	_ok(Gr.nombre_rango() == "Bronce" and Gr.reputacion() == 0, "4: una partida sin gremio no empieza en Bronce")
	P.restaurar(antes)


# 5. El tablón en Oro.
func _ventana() -> void:
	var m = load("res://gremio_menu.gd").new()
	root.add_child(m)
	await _esperar(3)
	_ok(m.cabecera.text.begins_with("Rango Oro") and not m.cabecera.text.contains("faltan"),
		"5: la cabecera no dice Oro sin «faltan» («%s»)" % m.cabecera.text)
	var b: Button = m.botones["gr_ambar"]
	_ok(not b.disabled and not b.text.begins_with("Rango"), "5: el encargo del maestro sigue cerrado en la ventana («%s»)" % b.text)
	b.pressed.emit()
	await _esperar(2)
	_ok(Gr.estado("gr_ambar") in ["aceptado", "listo"], "5: Aceptar en la ventana no acepta el encargo de Oro")
	m.cerrar_menu()
	await _esperar(2)
