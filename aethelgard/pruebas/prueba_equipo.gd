extends SceneTree
# C1 preparado (T-092): prueba de equipo_extra.gd sin el combate ni el inventario enganchados
# (docs/diseno/combate_ampliaciones.md, §4). Comprueba:
#   1. los datos: 10 accesorios (2 de la fase 3) y 6 armas especiales (dos por héroe), ids nuevos, textos del menú de 32 caracteres como
#      mucho, efectos del catálogo, mallas y texturas que existen y el ataque del diseño;
#   2. objeto(), la ranura al final y «solo» (las especiales de Garon no las lleva Kael, aunque sean espadas);
#   3. la suma de efectos: el equipo de hoy no da nada, los ids desconocidos tampoco, y los topes;
#   4. los ganchos: ATB inicial, crítico con la misma tirada, esquiva que solo tira con pluma, monedas una vez, PM al
#      acabar el turno, robo de vida, ataque por recuerdos, réplica en guardia y cubrir;
#   5. lo disponible por incremento (tiendas por lugar) y conseguir un objeto una sola vez;
#   6. guardar y cargar: la ranura nueva va dentro del inventario (ida y vuelta, en memoria y en un archivo propio de
#      user://), una partida antigua sin ella carga igual y un accesorio no cambia las estadísticas;
#   7. nada de esto tira del generador global (salvo la esquiva con pluma, una tirada).
# No toca la partida de verdad: su archivo es user://prueba_equipo.save (aislado por ejecutar_pruebas.ps1) y lo borra.

const ARCHIVO := "user://prueba_equipo.save"

var X
var I
var G
var P
var fallos: Array = []


func _initialize() -> void:
	X = load("res://equipo_extra.gd")
	I = load("res://inventario.gd")
	G = load("res://grupo.gd")
	P = load("res://progreso.gd")
	_limpiar()
	_datos()
	_objeto_y_solo()
	_suma()
	_ganchos()
	_disponible()
	_guardado()
	_generador()
	_limpiar()
	_borrar()
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


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


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


# ---------------------------------------------------------------- 1. datos
func _datos() -> void:
	_ok(X.ACCESORIOS.size() == 10 and X.ARMAS.size() == 6,   # +2 de la fase 3 (Brote y Corteza del Guardián)
		 "1: hay %d accesorios y %d armas" % [X.ACCESORIOS.size(), X.ARMAS.size()])
	var nombres := {}
	for id in X.ACCESORIOS.keys() + X.ARMAS.keys():
		var o: Dictionary = X.objeto(id)
		_ok(not I.ARMAS.has(id) and not I.PROTECCIONES.has(id), "1: el id %s ya existe en inventario.gd" % id)
		_ok(not nombres.has(o["nombre"]), "1: nombre repetido: %s" % o["nombre"])
		nombres[o["nombre"]] = true
		for k in ["nombre", "efecto", "texto", "donde"]:
			_ok(String(o.get(k, "")) != "", "1: a %s le falta «%s»" % [id, k])
		_ok(String(o["efecto"]).length() <= X.LARGO_EFECTO, "1: el texto de %s pasa de %d caracteres: «%s» (%d)" % [id,
			X.LARGO_EFECTO, o["efecto"], String(o["efecto"]).length()])
		_ok(not o["efectos"].is_empty(), "1: %s no tiene efecto" % id)
		for k in o["efectos"]:
			_ok(X.EFECTOS.has(k), "1: %s usa un efecto que no está en el catálogo: %s" % [id, k])
		_ok(not o.has("bonus"), "1: %s suma atributos (los accesorios y las especiales solo tienen su efecto)" % id)
	var por_heroe := {}
	for id in X.ARMAS:
		var w: Dictionary = X.ARMAS[id]
		por_heroe[w["solo"]] = por_heroe.get(w["solo"], 0) + 1
		_ok(G.HEROES.has(w["solo"]) and G.tipo_arma(w["solo"]) == w["tipo"], "1: %s es %s y su dueño usa otra cosa" % [id, w["tipo"]])
		for k in ["modelo", "color", "normal", "metal", "rugosidad", "brillo"]:
			_ok(w.has(k), "1: a %s le falta «%s» (inventario.gd arma_de lo lee)" % [id, k])
			if String(w.get(k, "")) != "":
				_ok(ResourceLoader.exists(w[k]), "1: %s: no existe %s" % [id, w[k]])
		_ok(w.has("largo") and w.has("punta") and w.has("tinte") and w.has("color_brillo"), "1: a %s le falta forma o tinte" % id)
	_ok(por_heroe == {"Kael": 2, "Lya": 2, "Garon": 2}, "1: no son dos especiales por héroe: %s" % [por_heroe])
	var ataques := {"hoja_sin_nombre": [8, 0], "guardiana_ambar": [12, 0], "baculo_peregrino": [2, 10],
		"rama_milenaria": [2, 12], "fauces_gorthor": [30, 0], "gemelas_muralla": [28, 0]}
	for id in ataques:
		_ok(int(X.ARMAS[id]["ataque"]) == ataques[id][0] and int(X.ARMAS[id].get("magia", 0)) == ataques[id][1],
			"1: %s no tiene el ataque y la magia del diseño" % id)
	_ok(X.ARMAS["fauces_gorthor"]["ataque"] < I.ARMAS["hoja_infernal"]["ataque"] and
		X.ARMAS["gemelas_muralla"]["ataque"] < I.ARMAS["hoja_infernal"]["ataque"], "1: las de Garon quitan más que sus Hojas")
	for id in X.ACCESORIOS:
		_ok(not X.ACCESORIOS[id].has("ataque") and not X.ACCESORIOS[id].has("magia"), "1: el accesorio %s da ataque o magia" % id)
	_hecho("1: 10 accesorios y 6 armas especiales, con datos completos")


# ---------------------------------------------------------------- 2. objeto, ranura y «solo»
func _objeto_y_solo() -> void:
	var a: Dictionary = X.objeto("farol_peregrino")
	_ok(a["ranura"] == "accesorio" and a["para"] == "todos", "2: el farol no va en la ranura Accesorio: %s" % [a])
	var w: Dictionary = X.objeto("fauces_gorthor")
	_ok(w["ranura"] == "arma" and w["para"] == "espada" and w["solo"] == "Garon", "2: las Fauces: %s" % [w])
	_ok(X.objeto("no_existe").is_empty() and X.objeto("frostfang").is_empty(), "2: objeto() da algo de un id ajeno")
	a["nombre"] = "cambiado"
	_ok(X.ACCESORIOS["farol_peregrino"]["nombre"] == "Farol de peregrino", "2: objeto() devuelve los datos sin copiar")
	var r: Array = X.ranuras(I.RANURAS)
	_ok(r.slice(0, I.RANURAS.size()) == I.RANURAS and r.back() == "accesorio" and X.ranuras(r) == r,
		"2: la ranura nueva no va al final, o se repite: %s" % [r])
	_ok(X.NOMBRE_RANURA == "Accesorio", "2: la ranura no se llama «Accesorio»")
	var casos := [["Kael", "hoja_sin_nombre", true], ["Garon", "hoja_sin_nombre", false], ["Lya", "hoja_sin_nombre", false],
		["Kael", "guardiana_ambar", true], ["Garon", "fauces_gorthor", true], ["Kael", "fauces_gorthor", false],
		["Kael", "gemelas_muralla", false], ["Lya", "baculo_peregrino", true], ["Kael", "baculo_peregrino", false],
		["Lya", "rama_milenaria", true], ["Garon", "rama_milenaria", false]]
	for id in X.ACCESORIOS:
		for h in G.EN_EL_GRUPO:
			casos.append([h, id, true])
	casos.append(["Kael", "no_existe", false])
	for cs in casos:
		_ok(X.puede_llevar(cs[0], cs[1], G.tipo_arma(cs[0])) == cs[2], "2: %s %s llevar %s" % [cs[0], "no puede" if cs[2] else "puede", cs[1]])
	_hecho("2: objeto(), la ranura Accesorio al final y «solo»")


# ---------------------------------------------------------------- 3. suma de efectos
func _suma() -> void:
	for h in I.INICIAL["equipo"]:
		_ok(X.efectos_de_equipo(I.INICIAL["equipo"][h]).is_empty(), "3: el equipo inicial de %s da efectos" % h)
	for id in I.ARMAS.keys() + I.PROTECCIONES.keys():
		_ok(X.efectos_de_equipo({"x": id}).is_empty(), "3: %s (de hoy) da efectos" % id)
	_ok(X.efectos_de_equipo({}).is_empty() and X.efectos_de_equipo({"accesorio": "de_una_version_nueva"}).is_empty(),
		"3: un equipo vacío o un id desconocido dan efectos")
	var ef: Dictionary = X.efectos_de_equipo({"arma": "fauces_gorthor", "accesorio": "pluma_arpia", "cuerpo": "cota_malla"})
	_ok(ef.size() == 2 and is_equal_approx(ef["robo_vida"], 0.15) and is_equal_approx(ef["esquiva"], 0.12), "3: Garon con Fauces y pluma: %s" % [ef])
	var doble: Dictionary = X.efectos_de_equipo({"accesorio": "farol_peregrino", "otra": "farol_peregrino"})
	_ok(is_equal_approx(doble["atb_inicio"], 60.0), "3: el tope de atb_inicio no funciona: %s" % [doble])
	var brasa: Dictionary = X.efectos_de_equipo({"accesorio": "brasa_frasco"})
	_ok(brasa.get("brasa", false) == true, "3: la Brasa en frasco no da «brasa»: %s" % [brasa])
	_limpiar()
	I.datos()
	_ok(X.efectos_de("Kael").is_empty() and X.efectos_de("Garon").is_empty(), "3: el inventario de hoy da efectos")
	_hecho("3: suma de efectos (el equipo de hoy no da nada)")


# ---------------------------------------------------------------- 4. ganchos
func _ganchos() -> void:
	_ok(X.atb_inicial({}) == 0.0 and X.atb_inicial({"atb_inicio": 35.0}) == 35.0
		and is_equal_approx(X.atb_inicial({"atb_inicio": 500.0}), 99.9), "4: ATB inicial mal")
	_ok(X.prob_critico(0.12, {}) == 0.12 and is_equal_approx(X.prob_critico(0.12, {"critico": 0.08}), 0.20), "4: crítico mal")
	_ok(X.oro_con_extra(100, []) == 100 and X.oro_con_extra(100, [{}, {"oro_pct": 25.0}]) == 125
		and X.oro_con_extra(100, [{"oro_pct": 25.0}, {"oro_pct": 25.0}]) == 125 and X.oro_con_extra(0, [{"oro_pct": 25.0}]) == 0,
		"4: las monedas extra no son una sola vez")
	var f := {"hero": true, "hp": 50, "hp_max": 100, "mp": 9, "mp_max": 10, "atk": 30, "efectos": {"pm_turno": 2.0}}
	_ok(X.pm_al_terminar(f) == 1 and f["mp"] == 10 and X.pm_al_terminar(f) == 0, "4: PM al acabar el turno mal")
	_ok(X.pm_al_terminar({"hp": 50, "mp": 0, "mp_max": 10}) == 0, "4: PM sin el accesorio")
	f["hp"] = 0
	f["mp"] = 0
	_ok(X.pm_al_terminar(f) == 0, "4: un caído recupera PM")
	var g := {"hero": true, "hp": 90, "hp_max": 100, "atk": 50, "efectos": {"robo_vida": 0.15}}
	_ok(X.robo_vida(g, 60) == 9 and g["hp"] == 99 and X.robo_vida(g, 60) == 1 and X.robo_vida(g, 60) == 0,
		"4: robo de vida mal (%d)" % g["hp"])
	_ok(X.robo_vida({"hp": 10, "hp_max": 100}, 60) == 0, "4: robo de vida sin las Fauces")
	var lore := {}
	for i in 5:
		lore["d%d" % i] = true
	_ok(X.ataque_recuerdo({"ataque_recuerdo": 12.0}, lore) == 5 and X.ataque_recuerdo({}, lore) == 0, "4: ataque por recuerdos mal")
	for i in 20:
		lore["e%d" % i] = true
	_ok(X.ataque_recuerdo({"ataque_recuerdo": 12.0}, lore) == 12, "4: el ataque por recuerdos pasa de 12")
	var k := {"hero": true, "hp": 100, "hp_max": 100, "atk": 30, "efectos": {"contra_defendiendo": 0.6}}
	_ok(X.replica(k, true) == 18 and X.replica(k, false) == 0 and X.replica({"hp": 1, "atk": 30}, true) == 0, "4: réplica mal")
	var garon := {"nombre": "Garon", "hero": true, "hp": 150, "hp_max": 200, "efectos": {"cubrir": 0.30}}
	var lya := {"nombre": "Lya", "hero": true, "hp": 20, "hp_max": 80}
	var kael := {"nombre": "Kael", "hero": true, "hp": 100, "hp_max": 120}
	var heroes := [kael, lya, garon]
	_ok(is_same(X.quien_cubre(lya, heroes), garon), "4: Garon no cubre a Lya con 20/80")
	_ok(is_same(X.quien_cubre(kael, heroes), kael), "4: Garon cubre a Kael con la vida alta")
	_ok(is_same(X.quien_cubre(garon, heroes), garon), "4: Garon se cubre a sí mismo con otro")
	garon["hp"] = 0
	_ok(is_same(X.quien_cubre(lya, heroes), lya), "4: Garon caído cubre")
	var enemigo := {"nombre": "Slime", "hero": false, "hp": 1, "hp_max": 50}
	_ok(is_same(X.quien_cubre(enemigo, heroes), enemigo), "4: alguien cubre a un enemigo")
	_ok(X.regen({"regen": 0.05}) == 0.05 and X.regen({}) == 0.0, "4: regeneración mal")
	_hecho("4: ganchos (ATB, crítico, monedas, PM, robo de vida, recuerdos, réplica, cubrir)")


# ---------------------------------------------------------------- 5. disponible, tiendas y conseguir
func _disponible() -> void:
	for id in X.ACCESORIOS.keys() + X.ARMAS.keys():
		_ok(not X.disponible(id, []), "5: %s está disponible sin ningún gancho" % id)
	var c1 := ["C1"]
	var en_c1: Array = (X.ACCESORIOS.keys() + X.ARMAS.keys()).filter(func(id): return X.disponible(id, c1))
	en_c1.sort()
	var esperado := ["brote_guardian", "cinta_lumi", "diente_grimfang", "farol_peregrino", "gota_cascada", "moneda_aguila",
		"pluma_arpia"]                               # brote_guardian: fase 3 (regen y PM, C1); la Corteza va con M3
	_ok(en_c1 == esperado, "5: con C1 están disponibles %s (el diseño: los 6 accesorios menos Lágrima y Brasa)" % [en_c1])
	_ok(X.disponible("lagrima_ambar", ["C1", "M3"]) and X.disponible("brasa_frasco", ["C1", "M4"])
		and X.disponible("fauces_gorthor", ["C2"]), "5: Lágrima (M3), Brasa (M4) o Fauces (C2) no se activan con su gancho")
	_ok(X.en_tienda(0, c1) == {"farol_peregrino": 220} and X.en_tienda(5, c1) == {"moneda_aguila": 450}
		and X.en_tienda(1, c1).is_empty() and X.en_tienda(0, []).is_empty(), "5: las tiendas por lugar")
	for lugar in X.EN_TIENDA:
		for id in X.EN_TIENDA[lugar]:
			_ok(X.es_extra(id) and int(X.EN_TIENDA[lugar][id]) > 0, "5: la tienda %d vende %s sin precio o que no existe" % [lugar, id])
	_limpiar()
	I.datos()
	var antes: int = I.datos()["equipables"].size()
	_ok(X.conseguir("cinta_lumi") == "Has conseguido Cinta de Lumi." and "cinta_lumi" in I.datos()["equipables"], "5: conseguir no lo apunta")
	_ok(X.conseguir("cinta_lumi") == "" and I.datos()["equipables"].size() == antes + 1, "5: conseguir lo apunta dos veces")
	_ok(X.conseguir("frostfang") == "" and X.conseguir("no_existe") == "", "5: conseguir apunta algo que no es de aquí")
	_hecho("5: lo disponible por incremento, las tiendas por lugar y conseguir una vez")


# ---------------------------------------------------------------- 6. guardar y cargar
func _guardado() -> void:
	_limpiar()
	I.datos()
	G.datos()
	var antes: Dictionary = G.estadisticas("Kael")
	I.datos()["equipables"].append("farol_peregrino")
	I.equipo_de("Kael")[X.RANURA] = "farol_peregrino"
	var despues: Dictionary = G.estadisticas("Kael")
	_ok(var_to_str(antes) == var_to_str(despues), "6: un accesorio cambia las estadísticas de Kael")
	_ok(X.efectos_de("Kael") == {"atb_inicio": 35.0}, "6: el farol puesto no da su efecto: %s" % [X.efectos_de("Kael")])
	# ida y vuelta en memoria (como guardar y cargar, sin archivo)
	var d: Dictionary = P.volcar("res://mapa.tscn").duplicate(true)
	_limpiar()
	P.restaurar(d)
	_ok(I.equipo_de("Kael").get(X.RANURA, "") == "farol_peregrino" and "farol_peregrino" in I.datos()["equipables"],
		"6: el accesorio no vuelve al cargar (memoria)")
	# ida y vuelta por un archivo propio (user:// aislado)
	_borrar()
	_ok(P.escribir(P.volcar("res://mapa.tscn"), ARCHIVO), "6: no se pudo escribir %s" % ARCHIVO)
	_limpiar()
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "6: no se pudo leer %s" % ARCHIVO)
	if leida is Dictionary:
		P.restaurar(leida)
		_ok(I.equipo_de("Kael").get(X.RANURA, "") == "farol_peregrino", "6: el accesorio no vuelve al cargar (archivo)")
		_ok(X.efectos_de("Kael") == {"atb_inicio": 35.0}, "6: tras cargar, el farol no da su efecto")
	# partida antigua: sin la ranura ni los ids nuevos
	_limpiar()
	var antigua := {"inventario": {"oro": 80, "objetos": {"Poción": 2}, "equipables": ["frostfang", "cetro_loto"],
		"equipo": {"Kael": {"arma": "frostfang"}, "Lya": {"arma": "cetro_loto"}}}, "escena_guardada": "res://mapa.tscn"}
	P.restaurar(antigua)
	_ok(I.equipo_de("Kael").get(X.RANURA, "") == "" and X.efectos_de("Kael").is_empty() and X.efectos_de("Garon").is_empty(),
		"6: una partida antigua tiene accesorio o efectos")
	_ok(I.equipo_de("Garon").get("arma", "") == "hoja_infernal", "6: la partida antigua no completa a Garon como antes")
	# un id que esta versión no conoce (de una partida más nueva): sin error y sin efecto
	I.equipo_de("Lya")[X.RANURA] = "de_una_version_nueva"
	_ok(X.efectos_de("Lya").is_empty() and X.objeto("de_una_version_nueva").is_empty(), "6: un id desconocido da efectos")
	_limpiar()
	_borrar()
	_hecho("6: guardar y cargar con la ranura nueva; partidas antiguas e ids desconocidos")


# ---------------------------------------------------------------- 7. el generador global
func _generador() -> void:
	seed(777)
	var primero := randi()
	var segundo := randi()
	seed(777)
	var ef_sin: Dictionary = X.efectos_de_equipo({"accesorio": "farol_peregrino", "arma": "hoja_sin_nombre"})
	X.atb_inicial(ef_sin)
	X.prob_critico(0.12, ef_sin)
	_ok(X.esquiva({}) == false and X.esquiva(ef_sin) == false, "7: esquiva sin pluma")
	X.oro_con_extra(50, [ef_sin])
	X.quien_cubre({"hero": true, "hp": 1, "hp_max": 10}, [])
	X.en_tienda(0, ["C1"])
	_ok(randi() == primero, "7: sin pluma, equipo_extra.gd tira del generador global (cambiaría la huella del combate)")
	seed(777)
	X.esquiva({"esquiva": 0.12})
	_ok(randi() == segundo, "7: la esquiva con pluma no tira exactamente un dado")
	_hecho("7: sin pluma no se toca el generador global; con ella, una tirada")
