extends SceneTree
# M1 y M2 preparados (T-091): prueba de artes.gd sin el combate enganchado (docs/diseno/combate_ampliaciones.md, §3).
# Comprueba, con diccionarios de luchador como los de combate.gd:
#   1. lo protegido (D-048, D-037): las 12 magias, Esgrima, Embuir, Érebo, la Armonía y el ATB de combate.gd y grupo.gd
#      siguen como hoy, y ningún nombre nuevo choca con ellos; Garon no aprende ninguna arte;
#   2. el aprendizaje: umbrales por familia, ninguna en el nivel 1, libros y tomos, lo que ya está enganchado (ACTIVOS)
#      y el aviso al subir de nivel;
#   3. el ATB (Alba): +50 sin pasar de 99,9, una sola entrada en la cola, nada a quien ya espera, el retraso saca de
#      la cola (los jefes, la mitad) y Hora Dorada sin turnos dobles, con el mismo bucle que combate.gd _process;
#   4. a quién va cada arte y por qué se apaga (Compás con Kael solo, nadie caído, ya esperan);
#   5. Lumbre: revive con el 25 % y la barra a 0, fuera de la cola; el Aliento cura en sus turnos, dura 3 y no se suma;
#      la Brasa levanta una vez; Escarcha: la coraza no se suma, absorbe, se rompe y congela al atacante (III);
#   6. el menú: pestañas I · II · III y de familia, que caben hasta x = 1240, y sus filas con motivo y coste;
#   7. los iconos se dibujan (si el modo sin ventana dibuja) y nada de esto tira del generador global;
#   8. guardar y cargar: los libros de las artes se guardan como los de siempre; las partidas de antes, por nivel.
# No toca la partida de verdad: no guarda en disco (volcar y restaurar, en memoria).

var A
var G
var P
var C
var fallos: Array = []
var frames := 0
var iconos := {}                                  # lo que devolvió cada dibujo
var lienzo: Control


func _initialize() -> void:
	A = load("res://artes.gd")
	G = load("res://grupo.gd")
	P = load("res://progreso.gd")
	C = load("res://combate.gd")
	_limpiar()
	_protegido()
	_aprendizaje()
	_atb()
	_objetivos()
	_lumbre_y_escarcha()
	_aplicar_todas()
	_menu()
	_generador()
	_guardado()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)


var _contados := 0                                # fallos ya contados al cerrar el apartado anterior


# Cierra un apartado: «OK» solo si no ha añadido fallos (los fallos se listan al final).
func _hecho(texto: String) -> void:
	print(("OK " if fallos.size() == _contados else "CON PROBLEMAS ") + texto)
	_contados = fallos.size()


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _heroe(n: String, hp: int, hp_max: int, mp := 40, atb := 0.0) -> Dictionary:
	return {"nombre": n, "hero": true, "hp": hp, "hp_max": hp_max, "mp": mp, "mp_max": 60, "atb": atb, "vel": 22.0}


func _enemigo(n: String, hp: int, atb := 0.0, personalidad := "agresivo") -> Dictionary:
	return {"nombre": n, "hero": false, "hp": hp, "hp_max": 100, "atb": atb, "vel": 13.0, "personalidad": personalidad}


# El mismo llenado de combate.gd _process (líneas «for f in heroes + enemigos: ... cola.append(f)»).
func _simular(luchadores: Array, cola: Array, fotogramas: int) -> void:
	for i in fotogramas:
		for f in luchadores:
			if f["hp"] > 0 and f["atb"] < 100.0:
				f["atb"] = min(100.0, f["atb"] + f["vel"] / 30.0)
				if f["atb"] >= 100.0:
					cola.append(f)


func _veces(cola: Array, f: Dictionary) -> int:
	return cola.filter(func(x): return is_same(x, f)).size()


# ---------------------------------------------------------------- 1. lo protegido
func _protegido() -> void:
	var magias := {"Agua": [6, 35, "3b8fd8"], "Fuego": [8, 50, "ff7a3c"], "Rayo": [7, 45, "f2e36b"], "Cura": [6, 45, "8ff0b0"]}
	_ok(C.MAGIAS.size() == 4, "1: combate.gd MAGIAS tiene %d entradas y no 4" % C.MAGIAS.size())
	for m in magias:
		var d: Dictionary = C.MAGIAS.get(m, {})
		_ok(int(d.get("coste", -1)) == magias[m][0] and int(d.get("dano", -1)) == magias[m][1]
			and d.get("color", Color.BLACK).to_html(false) == magias[m][2], "1: cambió la magia %s: %s" % [m, d])
	_ok(C.MAGIAS["Fuego"].get("quemadura", false) and C.MAGIAS["Cura"].get("cura", false), "1: Fuego o Cura cambiaron")
	var niveles := {
		"Fuego": [["Fuego", 8, 50, false], ["Llamarada", 18, 70, true], ["Infierno", 34, 140, true]],
		"Agua": [["Agua", 6, 35, false], ["Torrente", 15, 55, true], ["Maremoto", 30, 115, true]],
		"Rayo": [["Rayo", 7, 45, false], ["Tormenta", 17, 65, true], ["Cólera del Cielo", 32, 130, true]],
		"Cura": [["Cura", 6, 45, false], ["Bendición", 16, 45, true], ["Gracia Divina", 30, 100, true]]}
	_ok(C.NIVELES_MAGIA.size() == 4, "1: NIVELES_MAGIA tiene %d familias y no 4" % C.NIVELES_MAGIA.size())
	var nombres_12: Array = []
	for f in niveles:
		for i in 3:
			var d: Dictionary = C.NIVELES_MAGIA[f][i]
			var e: Array = niveles[f][i]
			nombres_12.append(e[0])
			_ok(d["nombre"] == e[0] and int(d["coste"]) == e[1] and int(d["dano"]) == e[2] and d["todos"] == e[3],
				"1: cambió %s %d: %s" % [f, i + 1, d])
	_ok(G.NIVEL_MAGIA == [1, 5, 10], "1: grupo.gd NIVEL_MAGIA cambió: %s" % [G.NIVEL_MAGIA])
	_ok(G.HEROES["Kael"]["magias"] == ["Fuego", "Rayo"] and G.HEROES["Lya"]["magias"] == ["Cura", "Agua", "Fuego", "Rayo"]
		and G.HEROES["Garon"]["magias"].is_empty(), "1: cambiaron las magias de los héroes en grupo.gd")
	_ok(C.ARMONIA_POR_ACCION == 0.15 and C.ATB_MAX == 100.0, "1: cambió la Armonía o el ATB")
	_ok(C.INVOCACION["prob_muerte"] == 0.2 and C.INVOCACION["dano_jefe"] == 0.2, "1: cambió Érebo: %s" % [C.INVOCACION])
	_ok(C.EMBUIR["coste"] == 5 and C.EMBUIR["turnos"] == 3 and C.EMBUIR["extra"] == 0.2, "1: cambió Embuir")
	_ok(C.TECNICAS_GARON["Juicio"]["mult"] == 1.8 and C.TECNICAS_GARON["Juicio"]["coste"] == 6
		and C.TECNICAS_GARON["Giro"]["mult"] == 0.9 and C.TECNICAS_GARON["Giro"]["coste"] == 10
		and C.TECNICAS_GARON["Giro"]["golpes"] == 2, "1: cambió la Esgrima de Garon")
	# lo nuevo no se mezcla con lo de siempre
	for fam in A.FAMILIAS:
		_ok(not C.MAGIAS.has(fam) and not C.NIVELES_MAGIA.has(fam), "1: %s ya está en combate.gd (¿enganchado sin prueba?)" % fam)
		_ok(A.NIVELES[fam].size() == 3, "2: %s no tiene tres niveles" % fam)
		for d in A.NIVELES[fam]:
			_ok(not d["nombre"] in nombres_12, "1: %s se llama como una de las 12" % d["nombre"])
			_ok(int(d["dano"]) == 0, "1: %s hace daño" % d["nombre"])
			_ok(A.DESCRIPCION.has(d["nombre"]) and A.DESCRIPCION[d["nombre"]].length() <= 70,
				"6: la descripción de %s falta o pasa de dos líneas" % d["nombre"])
	_ok(A.familias_de("Garon").is_empty() and A.familias_de("Nyx").is_empty(), "1: Garon o Nyx usan artes (D-037)")
	var garon := {"nivel": 50, "libros": {"Alba": 3, "Lumbre": 3}}
	for fam in A.FAMILIAS:
		_ok(A.nivel_de("Garon", fam, garon) == 0, "1: Garon sabe %s (D-037)" % fam)
	var costes := []
	for fam in A.FAMILIAS:
		for d in A.NIVELES[fam]:
			costes.append(d["coste"])
	_ok(costes == [6, 15, 30, 7, 18, 32, 14, 16, 34], "2: los PM no son los del diseño: %s" % [costes])
	_hecho("1: lo protegido sigue igual y lo nuevo no se mezcla")


# ---------------------------------------------------------------- 2. aprendizaje
func _aprendizaje() -> void:
	var casos := [["Kael", "Alba", [[1, 0], [2, 0], [3, 1], [8, 1], [9, 2], [15, 2], [16, 3], [50, 3]]],
		["Kael", "Escarcha", [[5, 0], [6, 1], [12, 2], [20, 3]]],
		["Kael", "Lumbre", [[50, 0]]],
		["Lya", "Lumbre", [[1, 0], [3, 0], [4, 1], [10, 2], [18, 3]]],
		["Lya", "Alba", [[50, 0]]], ["Lya", "Escarcha", [[50, 0]]]]
	for cs in casos:
		for par in cs[2]:
			var n: int = A.nivel_de(cs[0], cs[1], {"nivel": par[0]})
			_ok(n == par[1], "2: %s a nivel %d sabe %s %d y no %d" % [cs[0], par[0], cs[1], n, par[1]])
	for h in ["Kael", "Lya"]:                     # ninguna en el nivel 1: las pruebas de nivel 1 ven el menú de hoy
		_ok(A.hechizos_de(h, {"nivel": 1}).is_empty(), "2: %s sabe artes en el nivel 1" % h)
	# libros y tomos: como los de siempre (adelantan; el más alto manda)
	var d := {"nivel": 1}
	_ok(A.aprender_en("Kael", "Alba", 2, d) and A.nivel_de("Kael", "Alba", d) == 2, "2: el libro de Alba II no enseña")
	_ok(not A.aprender_en("Kael", "Alba", 2, d), "2: el mismo libro enseña dos veces")
	_ok(not A.aprender_en("Kael", "Alba", 1, d), "2: un libro de nivel menor cuenta")
	_ok(not A.aprender_en("Lya", "Alba", 2, {"nivel": 1}), "2: Lya aprende Alba")
	_ok(not A.aprender_en("Garon", "Lumbre", 1, {"nivel": 1}), "2: Garon aprende Lumbre")
	var t := {"nivel": 4}
	_ok(A.aprender_en("Lya", "Lumbre", 3, t) and A.nivel_de("Lya", "Lumbre", t) == 3, "2: el tomo de la Lumbre no enseña el III")
	_ok(A.TOMOS.size() == 3 and A.LIBROS.size() == 3, "2: faltan tomos o libros")
	# lo que se puede usar: lo que sabe, hasta lo enganchado
	for fam in A.FAMILIAS:
		var u: int = A.nivel_usable("Kael" if fam != "Lumbre" else "Lya", fam, {"nivel": 50})
		_ok(u == A.ACTIVOS[fam], "2: a nivel 50 se puede usar %s %d y no %d (ACTIVOS)" % [fam, u, A.ACTIVOS[fam]])
	var lista: Array = A.hechizos_de("Kael", {"nivel": 50})
	_ok(lista.all(func(x): return x.size() == 3 and A.NIVELES[x[0]][x[1] - 1] == x[2] and x[2].has("todos")),
		"2: hechizos_de no tiene la forma de combate.gd _hechizos")
	# aviso al subir: solo lo que da el nivel y está enganchado
	var nuevas: Array = A.nuevas_al_subir("Kael", {"nivel": 3}, 2, 3)
	_ok(nuevas == [["Alba", 1]], "2: al subir de 2 a 3, Kael aprende %s" % [nuevas])
	_ok(A.nuevas_al_subir("Kael", {"nivel": 4}, 3, 4).is_empty(), "2: al subir de 3 a 4, Kael aprende algo")
	var esc: Array = A.nuevas_al_subir("Kael", {"nivel": 6}, 5, 6)
	_ok(esc == ([["Escarcha", 1]] if A.ACTIVOS["Escarcha"] >= 1 else []), "2: al subir a 6, el aviso de Escarcha: %s" % [esc])
	var venta: Array = A.libros_en_venta()
	_ok(venta.all(func(l): return l[1] <= A.ACTIVOS[l[0]]), "2: se vende un libro sin enganchar")
	var fichas: Array = A.fichas_activas()
	_ok(fichas.all(func(f): return f.size() == 2 and String(f[1]).length() <= 75), "2: una ficha del Diario no tiene su forma")
	var titulos: Array = fichas.map(func(f): return f[0])
	_ok(("Ritmo" in titulos) == (A.ACTIVOS["Alba"] >= 1) and ("Barrera" in titulos) == (A.ACTIVOS["Escarcha"] >= 1)
		and ("Brasa" in titulos) == (A.ACTIVOS["Lumbre"] >= 3), "2: el Diario explica algo que no está en el juego: %s" % [titulos])
	_hecho("2: umbrales, libros, tomos, lo enganchado y el aviso al subir")


# ---------------------------------------------------------------- 3. ATB
func _atb() -> void:
	var kael := _heroe("Kael", 100, 100)
	var lya := _heroe("Lya", 80, 80, 40, 70.0)
	var cola: Array = []
	var cambio: float = A.sumar_atb(lya, 50.0, cola)
	_ok(is_equal_approx(lya["atb"], 99.9) and is_equal_approx(cambio, 29.9), "3: +50 desde 70 deja %.2f" % lya["atb"])
	_ok(cola.is_empty(), "3: el Compás mete a mano en la cola")
	_simular([kael, lya], cola, 30)
	_ok(_veces(cola, lya) == 1, "3: Lya entra %d veces en la cola tras el Compás" % _veces(cola, lya))
	_ok(A.sumar_atb(lya, 50.0, cola) == 0.0 and _veces(cola, lya) == 1, "3: quien ya espera recibe más barra")
	var garon := _heroe("Garon", 150, 150, 4, 100.0)
	_ok(A.sumar_atb(garon, 50.0, []) == 0.0, "3: con la barra llena y fuera de la cola, recibe más")
	var baja := _heroe("Garon", 150, 150, 4, 10.0)
	A.sumar_atb(baja, 50.0, [])
	_ok(is_equal_approx(baja["atb"], 60.0), "3: +50 desde 10 deja %.2f" % baja["atb"])
	# retraso
	var e := _enemigo("Grimfang", 100, 100.0)
	var jefe := _enemigo("Gorthor", 400, 100.0, "jefe")
	var cola2: Array = [e, jefe]
	var r: Array = A.aplicar("Alba", 2, [e, jefe], cola2)
	_ok(cola2.is_empty(), "3: el Peso del Ocaso no saca de la cola")
	_ok(is_equal_approx(e["atb"], 60.0) and is_equal_approx(jefe["atb"], 80.0),
		"3: el retraso deja %.1f y %.1f (esperado 60 y 80, los jefes la mitad)" % [e["atb"], jefe["atb"]])
	_ok(is_equal_approx(r[0]["atb"], -40.0) and is_equal_approx(r[1]["atb"], -20.0), "3: el cambio devuelto no es el real")
	_simular([e, jefe], cola2, 200)
	_ok(_veces(cola2, e) == 1 and _veces(cola2, jefe) == 1, "3: tras el retraso no vuelven una vez a la cola")
	var flojo := _enemigo("Slime", 50, 10.0)
	A.sumar_atb(flojo, -40.0, [])
	_ok(flojo["atb"] == 0.0, "3: el retraso deja la barra por debajo de 0")
	# Hora Dorada: los que no esperan, a 99,9; los que esperan, igual; quien lanza, nada
	var k2 := _heroe("Kael", 100, 100, 40, 100.0)
	var l2 := _heroe("Lya", 80, 80, 40, 20.0)
	var g2 := _heroe("Garon", 150, 150, 4, 100.0)
	var cola3: Array = [g2]
	var objs: Array = A.objetivos("Alba", 3, k2, [k2, l2, g2], [], cola3)
	_ok(objs.size() == 1 and is_same(objs[0], l2), "3: Hora Dorada va a %s" % [objs.map(func(x): return x["nombre"])])
	A.aplicar("Alba", 3, objs, cola3)
	_ok(is_equal_approx(l2["atb"], 99.9) and g2["atb"] == 100.0, "3: Hora Dorada deja %.1f y %.1f" % [l2["atb"], g2["atb"]])
	_simular([l2, g2], cola3, 5)
	_ok(_veces(cola3, l2) == 1 and _veces(cola3, g2) == 1, "3: Hora Dorada da turnos dobles")
	_hecho("3: ATB del Alba sin turnos dobles ni perdidos (Compás, Ocaso y Hora Dorada)")


# ---------------------------------------------------------------- 4. objetivos y motivos
func _objetivos() -> void:
	var kael := _heroe("Kael", 100, 100)
	var solo: Array = A.objetivos("Alba", 1, kael, [kael], [], [])
	_ok(solo.is_empty(), "4: el Compás se lanza sobre Kael solo")
	_ok(A.motivo_apagado("Alba", 1, kael, [kael], [], []) == A.MOTIVO["sin_otro"], "4: sin motivo con Kael solo")
	var lya := _heroe("Lya", 80, 80, 40, 30.0)
	_ok(A.objetivos("Alba", 1, kael, [kael, lya], [], []) == [lya], "4: el Compás no va a Lya")
	_ok(A.motivo_apagado("Alba", 1, kael, [kael, lya], [], [lya]) == A.MOTIVO["esperan"], "4: sin motivo si Lya ya espera")
	lya["hp"] = 0
	_ok(A.objetivos("Alba", 1, kael, [kael, lya], [], []).is_empty(), "4: el Compás va a una caída")
	_ok(A.objetivos("Lumbre", 1, kael, [kael, lya], [], []) == [lya], "4: Lumbre de Retorno no va a la caída")
	lya["hp"] = 50
	_ok(A.motivo_apagado("Lumbre", 1, lya, [kael, lya], [], []) == A.MOTIVO["sin_caidos"], "4: sin motivo si nadie ha caído")
	var e1 := _enemigo("Slime A", 30)
	var e2 := _enemigo("Slime B", 0)
	var e3 := _enemigo("Slime C", 30)
	e3["huido"] = true
	_ok(A.objetivos("Alba", 2, kael, [kael], [e1, e2, e3], []) == [e1], "4: el Ocaso va a caídos o huidos")
	_ok(A.objetivos("Escarcha", 1, kael, [kael, lya], [], []).size() == 2, "4: la Coraza no va a uno mismo")
	_hecho("4: a quién va cada arte y por qué se apaga")


# ---------------------------------------------------------------- 5. Lumbre y Escarcha
func _lumbre_y_escarcha() -> void:
	var lya := _heroe("Lya", 0, 81, 10, 100.0)
	lya["defendiendo"] = true
	lya["aliento"] = 2
	lya["barrera"] = 12
	var cola: Array = [lya]
	var pv: int = A.revivir(lya, 0.25, cola)
	_ok(pv == 20 and lya["hp"] == 20, "5: revive con %d PV (25 %% de 81 = 20)" % lya["hp"])
	_ok(lya["atb"] == 0.0 and cola.is_empty() and not lya["defendiendo"], "5: al revivir conserva barra, cola o guardia")
	_ok(lya["aliento"] == 0 and lya["barrera"] == 0, "5: al revivir conserva estados de antes de caer")
	var minimo := _heroe("Kael", 0, 3)
	_ok(A.revivir(minimo, 0.25, []) == 1, "5: con pocos PV máximos revive con 0")
	# Aliento
	var g := _heroe("Garon", 100, 200)
	A.dar_aliento(g, 3, 0.08)
	A.dar_aliento(g, 3, 0.08)
	_ok(g["aliento"] == 3, "5: el Aliento se suma (%d turnos)" % g["aliento"])
	var curas: Array = []
	for i in 4:
		curas.append(A.curar_al_empezar_turno(g))
	_ok(curas == [16, 16, 16, 0] and g["hp"] == 148 and g["aliento"] == 0, "5: el Aliento cura %s y deja %d PV" % [curas, g["hp"]])
	var lleno := _heroe("Kael", 99, 100)
	A.dar_aliento(lleno, 3, 0.08)
	_ok(A.curar_al_empezar_turno(lleno) == 1 and lleno["hp"] == 100, "5: el Aliento pasa de los PV máximos")
	var caido := _heroe("Kael", 0, 100)
	A.dar_aliento(caido, 3, 0.08)
	_ok(A.curar_al_empezar_turno(caido) == 0 and caido["hp"] == 0, "5: el Aliento cura a un caído")
	var cinta := _heroe("Lya", 50, 100)
	_ok(A.curar_al_empezar_turno(cinta, 0.05) == 5 and A.curar_al_empezar_turno(cinta) == 0, "5: la regeneración del equipo")
	_ok(A.curar_al_empezar_turno(_heroe("Kael", 50, 100)) == 0, "5: sin Aliento ni equipo, cura")
	# Brasa
	var b := _heroe("Garon", 0, 150)
	A.poner_brasa(b, 0.30)
	_ok(A.al_llegar_a_cero(b) and b["hp"] == 45 and b["brasa"] == 0.0, "5: la Brasa no levanta con el 30 %% (%d)" % b["hp"])
	b["hp"] = 0
	_ok(not A.al_llegar_a_cero(b) and b["hp"] == 0, "5: la Brasa levanta dos veces")
	var enemigo := _enemigo("Slime", 0)
	enemigo["brasa"] = 0.3
	_ok(not A.al_llegar_a_cero(enemigo), "5: un enemigo usa la Brasa")
	# Escarcha: coraza que no se suma, absorbe, se rompe y congela con el III
	var k := _heroe("Kael", 120, 120)
	_ok(A.poner_barrera(k, 0.30) == 36, "5: la Coraza no es el 30 %% (%d)" % k.get("barrera", 0))
	_ok(A.poner_barrera(k, 0.20) == 36, "5: una coraza menor sustituye a la mayor")
	var r: Dictionary = A.absorber(k, 10)
	_ok(r["resto"] == 0 and r["absorbido"] == 10 and k["barrera"] == 26 and not r["rota"], "5: absorber 10: %s" % [r])
	r = A.absorber(k, 40)
	_ok(r["resto"] == 14 and r["absorbido"] == 26 and r["rota"] and not r["congela"] and k["barrera"] == 0,
		"5: romper la coraza: %s" % [r])
	_ok(A.absorber(k, 9)["resto"] == 9, "5: sin coraza, absorbe")
	A.poner_barrera(k, 0.30, true)
	r = A.absorber(k, 100)
	_ok(r["rota"] and r["congela"] and r["resto"] == 64, "5: el Invierno Guardián no congela al romperse: %s" % [r])
	var cae := _heroe("Lya", 0, 80)
	cae["barrera"] = 10
	cae["aliento"] = 2
	_ok(not A.al_llegar_a_cero(cae) and cae["barrera"] == 0 and cae["aliento"] == 0, "5: al caer conserva la coraza o el Aliento")
	_ok(A.estados_de({"barrera": 3, "aliento": 1, "brasa": 0.3}) == ["barrera", "aliento", "brasa"] and A.estados_de({}).is_empty(),
		"5: los estados que se dibujan")
	_hecho("5: Lumbre (revivir, Aliento, Brasa) y Escarcha (coraza)")


# ---------------------------------------------------------------- las nueve artes con aplicar()
func _aplicar_todas() -> void:
	for fam in A.FAMILIAS:
		for n in [1, 2, 3]:
			var kael := _heroe("Kael", 100, 100)
			var lya := _heroe("Lya", 0 if fam == "Lumbre" and n == 1 else 60, 80, 40, 20.0)
			var e := _enemigo("Grimfang", 100, 50.0)
			var cola: Array = []
			var objs: Array = A.objetivos(fam, n, kael, [kael, lya], [e], cola)
			if not A.datos(fam, n)["todos"]:
				objs = objs.slice(0, 1)
			var r: Array = A.aplicar(fam, n, objs, cola, 100.0, 1 if fam == "Lumbre" and n == 2 else 0)
			_ok(r.size() == objs.size() and not objs.is_empty(), "aplicar %s %d: %d objetivos" % [fam, n, objs.size()])
			_ok(kael["mp"] == 40 and kael["atb"] == 0.0 or fam == "Escarcha", "aplicar %s %d toca a quien lanza" % [fam, n])
			var bien := false                         # los valores del diseño (§3.2 a §3.4), en luchadores de verdad
			match fam + str(n):
				"Alba1":
					bien = is_equal_approx(lya["atb"], 70.0) and e["atb"] == 50.0
				"Alba2":
					bien = is_equal_approx(e["atb"], 10.0) and lya["atb"] == 20.0
				"Alba3":
					bien = is_equal_approx(lya["atb"], 99.9) and kael["atb"] == 0.0
				"Escarcha1":
					bien = kael["barrera"] == 30 and not lya.has("barrera") and not kael["barrera_escarcha"]
				"Escarcha2":
					bien = kael["barrera"] == 20 and lya["barrera"] == 16 and not lya["barrera_escarcha"]
				"Escarcha3":
					bien = kael["barrera"] == 30 and lya["barrera"] == 24 and kael["barrera_escarcha"] and lya["barrera_escarcha"]
				"Lumbre1":
					bien = lya["hp"] == 20 and lya["atb"] == 0.0 and kael["hp"] == 100
				"Lumbre2":                          # con el Báculo del Peregrino (turnos_extra 1): 4 turnos
					bien = lya["aliento"] == 4 and kael["aliento"] == 4 and is_equal_approx(lya["aliento_regen"], 0.08)
				"Lumbre3":
					bien = is_equal_approx(lya["brasa"], 0.30) and is_equal_approx(kael["brasa"], 0.30)
			_ok(bien, "aplicar %s %d no da lo del diseño: Kael %s · Lya %s · enemigo %s" % [fam, n, kael, lya, e])
	_hecho("aplicar: las nueve artes, con los valores del diseño")


# ---------------------------------------------------------------- 6. menú
func _menu() -> void:
	var lya1: Dictionary = A.pestanas_magia([true, false, false], [], 1)
	_ok(lya1["pestanas"].is_empty(), "6: con un solo nivel y sin familias salen pestañas")
	var lya4: Dictionary = A.pestanas_magia([true, false, false], ["Lumbre"], 1)
	_ok(lya4["pestanas"].map(func(p): return p.get("icono", p["texto"])) == ["I", "Lumbre"], "6: Lya con Lumbre: %s" % [lya4])
	var k16: Dictionary = A.pestanas_magia([true, true, true], ["Alba", "Escarcha"], 5)
	_ok(k16["activa"] == 4 and k16["valor"] == 5, "6: la pestaña de Escarcha no es la activa: %s" % [k16])
	var xs: Array = A.posiciones_pestanas(k16["pestanas"])
	_ok(xs == [808.0, 908.0, 1008.0, 1108.0, 1176.0], "6: las pestañas no están donde el diseño: %s" % [xs])
	_ok(xs[4] + 64.0 <= 1240.0, "6: la última pestaña se sale del menú (acaba en %.0f)" % (xs[4] + 64.0))
	var mal: Dictionary = A.pestanas_magia([true, true, false], ["Lumbre"], 5)
	_ok(mal["valor"] == 1 and mal["activa"] == 0, "6: una pestaña que ya no existe no vuelve a la I: %s" % [mal])
	var sin_i: Dictionary = A.pestanas_magia([false, false, false], ["Alba"], 1)
	_ok(sin_i["valor"] == 4 and sin_i["pestanas"].is_empty(), "6: sin magias de siempre, la familia no queda elegida")
	# filas
	var kael := _heroe("Kael", 100, 100, 10)
	var lya := _heroe("Lya", 80, 80)
	var filas: Array = A.filas_familia("Alba", 2, kael, [kael, lya], [_enemigo("Slime", 50)], [])
	_ok(filas.size() == 2 and filas[0]["texto"] == "Compás del Alba" and filas[0]["derecha"] == "6 PM"
		and not filas[0]["apagado"] and filas[0]["desc"] == A.DESCRIPCION["Compás del Alba"], "6: la fila del Compás: %s" % [filas])
	_ok(filas[1]["apagado"] and filas[1]["derecha"] == "15 PM", "6: el Ocaso se puede pagar con 10 PM")
	var solo: Array = A.filas_familia("Alba", 1, kael, [kael], [], [])
	_ok(solo[0]["apagado"] and solo[0]["desc"] == A.MOTIVO["sin_otro"], "6: el Compás de Kael solo no dice por qué")
	var pruebas: Array = A.filas_familia("Lumbre", 1, lya, [kael, lya], [], [], true)
	_ok(pruebas[0]["derecha"] == "PM ∞" and pruebas[0]["apagado"], "6: con PM infinitos o sin caídos: %s" % [pruebas])
	# iconos: se dibujan en el draw de un Control (si el modo sin ventana dibuja)
	lienzo = Control.new()
	lienzo.size = Vector2(200, 40)
	lienzo.draw.connect(func():
		for fam in A.FAMILIAS + ["Fuego"]:
			iconos[fam] = A.dibujar_icono(lienzo, fam, Vector2(34, 34))
		for est in A.ESTADOS + ["nada"]:
			iconos[est] = A.dibujar_estado(lienzo, est, Vector2(18, 18)))
	_hecho("6: pestañas y filas del menú de magia")


# ---------------------------------------------------------------- 7. el generador global
func _generador() -> void:
	seed(4242)
	var esperado := randi()
	seed(4242)
	var kael := _heroe("Kael", 100, 100)
	var lya := _heroe("Lya", 0, 80)
	var e := _enemigo("Gorthor", 400, 90.0, "jefe")
	var cola: Array = [e]
	for fam in A.FAMILIAS:
		for n in [1, 2, 3]:
			A.objetivos(fam, n, kael, [kael, lya], [e], cola)
			A.motivo_apagado(fam, n, kael, [kael, lya], [e], cola)
			A.filas_familia(fam, n, kael, [kael, lya], [e], cola)
	A.aplicar("Alba", 2, [e], cola)
	A.aplicar("Lumbre", 1, [lya], cola)
	A.aplicar("Escarcha", 3, [kael, lya], cola)
	A.absorber(kael, 50)
	A.curar_al_empezar_turno(lya, 0.05)
	A.pestanas_magia([true, true, true], ["Alba", "Escarcha"], 4)
	A.hechizos_de("Kael", {"nivel": 30})
	_ok(randi() == esperado, "7: artes.gd tira del generador global (cambiaría la huella del combate)")
	_hecho("7: nada de artes.gd tira del generador global")


# ---------------------------------------------------------------- 8. guardar y cargar
func _guardado() -> void:
	_limpiar()
	G.datos()["Kael"]["nivel"] = 4
	_ok(A.nivel("Kael", "Alba") == 1 and A.nivel("Kael", "Escarcha") == 0, "8: Kael de nivel 4 (partida de antes) no sabe Alba I")
	_ok(not G.aprender("Kael", "Alba", 2), "8: grupo.gd ya enseña artes (la tienda debe usar Artes.aprender)")
	_ok(A.aprender("Kael", "Alba", 2) and A.nivel("Kael", "Alba") == 2, "8: Artes.aprender no enseña el libro")
	_ok(G.nivel_magia("Kael", "Fuego") == 1 and G.nivel_magia("Kael", "Rayo") == 1, "8: un libro de arte cambia las de siempre")
	var d: Dictionary = P.volcar("res://mapa.tscn").duplicate(true)
	_limpiar()
	P.restaurar(d)
	_ok(A.nivel("Kael", "Alba") == 2 and G.datos()["Kael"]["libros"] == {"Alba": 2},
		"8: el libro de Alba no vuelve al cargar (%s)" % [G.datos()["Kael"].get("libros", {})])
	var antigua := {"grupo": {"Kael": {"nivel": 9, "exp": 0, "puntos": 0, "atributos": G.HEROES["Kael"]["atributos"].duplicate(),
		"pv": -1, "pm": -1}}, "escena_guardada": "res://mapa.tscn"}
	_limpiar()
	P.restaurar(antigua)
	_ok(A.nivel("Kael", "Alba") == 2 and A.nivel("Lya", "Lumbre") == 1,
		"8: una partida de antes (Kael 9; Lya llega al 9) no sabe por nivel: %d y %d" % [A.nivel("Kael", "Alba"), A.nivel("Lya", "Lumbre")])
	_limpiar()
	_hecho("8: guardar y cargar (libros) y partidas de antes")


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		root.add_child(lienzo)
		lienzo.queue_redraw()
	if frames < 8:
		return false
	if iconos.is_empty():
		print("AVISO: el modo sin ventana no dibujó el lienzo: los iconos no se comprueban aquí")
	else:
		for fam in A.FAMILIAS:
			_ok(iconos.get(fam, false), "7: no se dibuja el icono de %s" % fam)
		for est in A.ESTADOS:
			_ok(iconos.get(est, false), "7: no se dibuja el icono del estado %s" % est)
		_ok(not iconos.get("Fuego", true) and not iconos.get("nada", true), "7: dibuja iconos que no son suyos")
		_hecho("7: iconos de las familias y de los estados, dibujados por código")
	lienzo.queue_free()
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true
