extends SceneTree
# El buscador de metales (V11, hito D; buscador.gd), solo la lógica, sin escena y con datos aislados:
#   1. Reproducible: la misma región y semilla dan los mismos sitios; otra semilla, otros; el único, en su sitio fijo.
#   2. Señal: sube al acercarse, 0 fuera del alcance, distingue lo raro; el nivel 2 oye más lejos.
#   3. Cavar: lejos, nada; encima, el objeto una sola vez (al inventario); el único no se repite.
#   4. Falsas: dan «Chatarra» sin objeto; con el nivel 3 ya no pitan.
#   5. Guardado: lo desenterrado y el nivel van en la partida; una partida antigua empieza en el nivel 1 sin nada.
#   6. V12: tenerlo (dar), los únicos esperan su hito, ningún hallazgo cae en el estanque ni en las rocas, las
#      investigaciones de Kael (gastan y suben; sin materiales, no) y la Aguja de Resonancia oye más lejos.
# Imprime «FALLOS: n».

const R := "mar_de_cristal_1"
var B
var P
var Inv
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	B = load("res://buscador.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	_probar.call_deferred()


func _probar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var a: Array = B.hallazgos(R, 7)
	var b: Array = B.hallazgos(R, 7)
	var c: Array = B.hallazgos(R, 8)
	_ok(a.size() == 22 and a.map(func(h): return h["pos"]) == b.map(func(h): return h["pos"]), "1: la misma semilla no da lo mismo")
	_ok(a.map(func(h): return h["pos"]) != c.map(func(h): return h["pos"]), "1: otra semilla da lo mismo")
	var u: Dictionary = a.filter(func(h): return h["id"] == "llave_vidrio")[0]
	_ok(u["pos"] == Vector2(49.0, 21.0) and c.filter(func(h): return h["id"] == "llave_vidrio")[0]["pos"] == u["pos"], "1: el único no está en su sitio fijo")
	# 6a. V12: los únicos esperan su hito (la llave, mc_ruinas; el sello, mc_caravana): ni pitan ni salen antes
	_ok(not B.tiene(), "6: sin dárselo, Kael ya tiene el buscador")
	B.dar()
	_ok(B.tiene() and B.nivel() == 1, "6: dar() no le da el buscador de nivel 1")
	_ok(B.pendientes(R, 7).all(func(h): return h["id"] != "llave_vidrio" and h["id"] != "sello_caravana"), "6: un único pita antes de su hito")
	_ok(B.excavar(R, 7, u["pos"]).get("objeto", "") != "Llave de vidrio" and Inv.cantidad("Llave de vidrio") == 0, "6: la llave sale antes de mc_ruinas")
	for h in a:
		_ok(h["pos"].distance_to(Vector2(74, 72)) > 5.0 and h["pos"].distance_to(Vector2(26, 30)) > 2.0, "6: un hallazgo cae en el estanque o en una roca (%s)" % h)
	P.poner_hito("mc_ruinas")
	P.poner_hito("mc_caravana")
	_ok(B.pendientes(R, 7).any(func(h): return h["id"] == "llave_vidrio") and B.pendientes(R, 7).any(func(h): return h["id"] == "sello_caravana"),
		"6: con su hito, el único no aparece")
	# 2. señal
	var lejos: Dictionary = B.senal(R, 7, u["pos"] + Vector2(5.5, 0))
	var cerca: Dictionary = B.senal(R, 7, u["pos"] + Vector2(1.0, 0))
	_ok(cerca["intensidad"] > lejos["intensidad"] and cerca["raro"], "2: la señal no sube al acercarse al único o no es rara (%s / %s)" % [lejos, cerca])
	var nada: Dictionary = B.senal(R, 7, Vector2(-500, -500))
	_ok(nada["intensidad"] == 0.0, "2: muy lejos hay señal")
	var p8: Vector2 = u["pos"] + Vector2(0, 8.0)
	var s1: float = B.senal(R, 7, p8)["intensidad"]
	B.mejorar(2)
	var s2: float = B.senal(R, 7, p8)["intensidad"]
	_ok(s2 > s1, "2: el nivel 2 no oye más lejos (%s, %s)" % [s1, s2])
	B.mejorar(1)
	# 3. cavar
	_ok(B.excavar(R, 7, u["pos"] + Vector2(3.0, 0)).is_empty(), "3: a 3 m se desentierra")
	var x: Dictionary = B.excavar(R, 7, u["pos"] + Vector2(0.4, 0))
	_ok(x.get("objeto", "") == "Llave de vidrio" and x["raro"] and Inv.cantidad("Llave de vidrio") == 1, "3: encima no sale la llave (%s)" % x)
	_ok(B.excavar(R, 7, u["pos"]).get("objeto", "") != "Llave de vidrio" and Inv.cantidad("Llave de vidrio") == 1, "3: la llave sale dos veces")
	_ok(B.desenterrado(R, "llave_vidrio") and B.hallazgos(R, 99).filter(func(h): return h["id"] == "llave_vidrio").size() == 1,
		"3: con otra semilla hay dos llaves")
	# 4. falsas
	var f: Dictionary = a.filter(func(h): return h["falsa"])[0]
	var objs0: int = Inv.cantidad("Chatarra")
	var rf: Dictionary = B.excavar(R, 7, f["pos"])
	_ok(rf.get("falsa", false) and Inv.cantidad("Chatarra") == objs0, "4: la falsa no da chatarra sin objeto (%s)" % rf)
	var f2: Dictionary = a.filter(func(h): return h["falsa"])[1]
	B.mejorar(3)
	_ok(B.pendientes(R, 7).all(func(h): return not h["falsa"]), "4: con el nivel 3 pitan las falsas")
	_ok(B.excavar(R, 7, f2["pos"]).get("falsa", false) == false, "4: con el nivel 3 se cava una falsa")
	# 5. guardado
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(d.has("buscador") and int(d["buscador"]["nivel"]) == 3 and "llave_vidrio" in d["buscador"][R], "5: el buscador no va en la partida")
	var vieja: Dictionary = d.duplicate(true)
	vieja.erase("buscador")
	P.restaurar(vieja)
	_ok(B.nivel() == 1 and not B.desenterrado(R, "llave_vidrio") and not B.tiene(), "5: una partida antigua trae buscador")
	P.restaurar(d)
	_ok(B.nivel() == 3 and B.desenterrado(R, "llave_vidrio") and B.tiene(), "5: al cargar, el buscador no es el mismo")
	# 6b. investigaciones de Kael: sin materiales no sube ni gasta; con ellos, gasta lo justo y sube; en el 3, al máximo
	B.mejorar(1)
	var o: Dictionary = Inv.datos()["objetos"]
	for k in ["Fragmento de espada", "Mineral rúnico", "Reliquia de vidrio", "Moneda antigua"]:
		o.erase(k)
	_ok(not B.investigar().begins_with("Kael") and B.nivel() == 1, "6: sin materiales, la investigación sube el nivel")
	Inv.agregar_objeto("Fragmento de espada", 3)
	Inv.agregar_objeto("Mineral rúnico", 1)
	_ok(B.falta_mejora().is_empty() and B.investigar().begins_with("Kael") and B.nivel() == 2, "6: con materiales no sube al 2")
	_ok(Inv.cantidad("Fragmento de espada") == 1 and Inv.cantidad("Mineral rúnico") == 0, "6: el nivel 2 no gasta lo justo")
	Inv.agregar_objeto("Reliquia de vidrio", 2)
	Inv.agregar_objeto("Moneda antigua", 4)
	_ok(not B.falta_mejora().is_empty() and B.nivel() == 2, "6: con 4 monedas se puede subir al 3")
	Inv.agregar_objeto("Moneda antigua", 1)
	_ok(B.investigar().begins_with("Kael") and B.nivel() == 3 and Inv.cantidad("Moneda antigua") == 0, "6: no sube al 3")
	_ok(B.falta_mejora() == ["Ya está al máximo."] and B.nivel() == 3, "6: pasa del nivel 3")
	# 6c. la Aguja de Resonancia: oye 2 m más lejos
	var al0: float = B.alcance()
	load("res://equipo_extra.gd").conseguir("aguja_resonancia")
	_ok(is_equal_approx(B.alcance(), al0 + B.ALCANCE_AGUJA), "6: la Aguja no amplía el alcance (%s → %s)" % [al0, B.alcance()])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
