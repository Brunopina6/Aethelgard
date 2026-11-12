extends SceneTree
# V12, accesorios nuevos (12/11; equipo_extra.gd, tanda «v12»; docs/v12/ACCESORIOS_V12.md). Interruptor
# «accesorios_v12» APAGADO: esta prueba lo enciende solo para sí. Comprueba:
#   1. datos: nombre, texto, efecto, rareza, categoría, precio, «donde» de propuesta, ranuras que ya existen, efectos
#      del catálogo y dentro de sus topes, atributos moderados, ningún precio en Orbes, y que los textos caben en la
#      tienda (columna de 300 px a 18 px con la fuente del juego) y en el menú Grupo;
#   2. interruptor: apagado, nada nuevo disponible ni a la venta; encendido, todos en cualquier tienda (de prueba);
#   3. equipar y quitar: ranura correcta (Anillo, Amuleto, Accesorio), «solo», atributos que llegan a estadisticas() y
#      efectos a efectos_de(), varios a la vez, y al quitarlos, todo como antes;
#   4. funciones de los ganchos y su neutralidad: sin el accesorio, el mismo número y ningún dado de más;
#   5. combate de verdad A (grupo 9, un Grimfang; Kael, Lya y Garon): Anillo del Alba y Broche del Guardián en
#      _quitar_pv, Talismán de Ceniza en la corrupción de Humbaba, Velo de bruma en _animar_golpe, Colgante del Eco en
#      _dano_magia, Rosario del Loto y Colgante de savia en la Cura de Lya, savia en la Poción; Defender sin
#      Brazalete deja la barra a 0;
#   6. combate de verdad B: Fiador de empuñadura (Kael) y Brazal del último muro (Garon) en _animar_golpe, Brazalete
#      del centinela (Lya) al Defender;
#   7. guardar y cargar (memoria y archivo propio de user://), partida antigua sin ellos, partida con ellos cargada
#      con el interruptor apagado (lo que se tiene sigue puesto y funciona; la tienda no los vende) e id desconocido;
#   8. menús: la tienda de prueba (aviso, precio, icono y color de la rareza, comprar una vez) y el menú Grupo (icono
#      en la ficha y en Objetos); sin interruptor, la tienda de siempre.
# No toca la partida de verdad: user:// aislado por ejecutar_pruebas.ps1 y archivo propio, que borra.

const ARCHIVO := "user://prueba_accesorios_v12.save"
const MAX_FOTOGRAMAS := 5400

var X
var I
var G
var P
var c = null
var frames := 0
var f_inicio := 0
var f_fin := -1
var escenario := ""
var pendientes := ["A", "B"]
var fallos: Array = []
var datos := {}
var espera := 0
var _contados := 0


func _initialize() -> void:
	X = load("res://equipo_extra.gd")
	I = load("res://inventario.gd")
	G = load("res://grupo.gd")
	P = load("res://progreso.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	_datos()
	_interruptor()
	_equipar_y_quitar()
	_funciones()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)


func _hecho(texto: String) -> void:
	print(("OK " if fallos.size() == _contados else "CON PROBLEMAS ") + texto)
	_contados = fallos.size()


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "lugar",
			X.INTERRUPTOR_V12]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _nuevos() -> Array:
	return X.ACCESORIOS.keys().filter(func(id): return X.es_v12(id))


func _ancho(t: String, tam: int) -> float:
	return load("res://estilo.gd").normal().get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x


# ---------------------------------------------------------------- 1. datos
func _datos() -> void:
	var nuevos := _nuevos()
	_ok(nuevos.size() >= 8 and nuevos.size() <= 14, "1: la tanda tiene %d objetos (8-14)" % nuevos.size())
	var nombres := {}
	for id in I.ARMAS.keys() + I.PROTECCIONES.keys() + X.ARMAS.keys() + X.ACCESORIOS.keys():
		var nm: String = (I.ARMAS.get(id, I.PROTECCIONES.get(id, X.ARMAS.get(id, X.ACCESORIOS.get(id, {}))))).get("nombre", "")
		_ok(not nombres.has(nm), "1: nombre repetido: %s" % nm)
		nombres[nm] = true
	var por_ranura := {}
	for id in nuevos:
		var o: Dictionary = X.objeto(id)
		_ok(not I.ARMAS.has(id) and not I.PROTECCIONES.has(id) and not X.ARMAS.has(id), "1: el id %s ya existe" % id)
		for k in ["nombre", "texto", "donde", "rareza", "categoria"]:
			_ok(String(o.get(k, "")) != "", "1: a %s le falta «%s»" % [id, k])
		_ok(X.RAREZAS.has(o.get("rareza", "")), "1: %s: rareza desconocida «%s»" % [id, o.get("rareza", "")])
		_ok(String(o["donde"]).begins_with("Propuesta"), "1: %s: su «donde» no dice que es una propuesta" % id)
		_ok(String(o["texto"]).length() <= 95, "1: %s: texto de %d letras" % [id, String(o["texto"]).length()])
		_ok(int(o.get("precio", 0)) >= 100 and int(o.get("precio", 0)) <= 500, "1: %s: precio %s fuera de 100-500" % [id, o.get("precio")])
		for k in o.keys():
			_ok(not "orbe" in str(k).to_lower(), "1: %s tiene un campo de Orbes («%s»)" % [id, k])
		_ok(o["ranura"] in I.RANURAS and o["ranura"] in ["anillo", "amuleto", "accesorio"],
			"1: %s va en una ranura que no es de accesorio: %s" % [id, o["ranura"]])
		por_ranura[o["ranura"]] = por_ranura.get(o["ranura"], 0) + 1
		_ok(not o.has("ataque") and not o.has("magia"), "1: %s da ataque o daño mágico" % id)
		if o.has("solo"):
			_ok(G.HEROES.has(o["solo"]), "1: %s es de un héroe que no existe: %s" % [id, o["solo"]])
		var total := 0
		for k in o.get("bonus", {}):
			_ok(k in G.ATRIBUTOS, "1: %s suma un atributo desconocido: %s" % [id, k])
			total += absi(int(o["bonus"][k]))
		_ok(total <= G.PUNTOS_POR_NIVEL, "1: %s suma %d puntos de atributo (más que un nivel)" % [id, total])
		_ok(not o["efectos"].is_empty() or total > 0, "1: %s no hace nada" % id)
		for k in o["efectos"]:
			_ok(X.EFECTOS.has(k), "1: %s usa un efecto fuera del catálogo: %s" % [id, k])
			if X.EFECTOS.has(k) and X.EFECTOS[k]["tipo"] == "num":
				var v := float(o["efectos"][k])
				_ok(v > 0.0 and v <= float(X.EFECTOS[k]["max"]) * 0.7, "1: %s: %s = %s pasa del 70 %% de su tope" % [id, k, v])
			_ok(X.EFECTOS.get(k, {}).get("gancho", "") in X.HECHOS, "1: %s: el gancho de %s no está hecho" % [id, k])
		if o.has("efecto"):
			_ok(String(o["efecto"]).length() <= X.LARGO_EFECTO, "1: %s: «efecto» de %d letras" % [id, String(o["efecto"]).length()])
		var res: String = I.resumen(id)
		_ok(res != "", "1: %s sin resumen" % id)
		_ok(_ancho(res, 18) <= 300.0, "1: %s: «%s» mide %.0f px en la tienda (300)" % [id, res, _ancho(res, 18)])
		_ok(_ancho("      " + res, 16) <= 520.0, "1: %s: el resumen no cabe en la ficha" % id)
		_ok(_ancho(o["nombre"], 21) <= 330.0 - 30.0, "1: %s: el nombre no cabe con su icono" % id)
		_ok(_ancho(o["nombre"], 20) <= 190.0, "1: %s: el nombre no cabe en la ficha con su icono (%.0f px)" % [id, _ancho(o["nombre"], 20)])
		var nota := "%s · %s" % [X.RAREZAS[o["rareza"]]["nombre"], ("Solo " + o["solo"]) if o.has("solo") else "Todos"]
		_ok(_ancho(nota, 18) <= 170.0, "1: %s: la nota «%s» mide %.0f px (170)" % [id, nota, _ancho(nota, 18)])
	_ok(por_ranura.get("anillo", 0) >= 1 and por_ranura.get("amuleto", 0) >= 1 and por_ranura.get("accesorio", 0) >= 1,
		"1: no hay de las tres ranuras: %s" % [por_ranura])
	for ej in ["anillo_alba", "broche_guardian", "talisman_ceniza", "colgante_eco"]:
		_ok(X.es_v12(ej), "1: falta el ejemplo del usuario %s" % ej)
	_ok(not X.ACCESORIOS.has("reliquia_confino"), "1: la Reliquia del Confino está implementada (solo es propuesta)")
	_hecho("1: datos de la tanda (%d objetos)" % nuevos.size())


# ---------------------------------------------------------------- 2. interruptor
func _interruptor() -> void:
	_limpiar()
	_ok(not X.v12_activo(), "2: el interruptor está encendido por defecto")
	for id in _nuevos():
		_ok(not X.disponible(id), "2: %s está disponible sin interruptor" % id)
	for lugar in [-1, 0, 1, 5]:
		for id in X.en_tienda(lugar):
			_ok(not X.es_v12(id), "2: sin interruptor, la tienda %d vende %s" % [lugar, id])
	_ok(X.en_tienda(0) == {"farol_peregrino": 220} and X.en_tienda(5) == {"moneda_aguila": 450}, "2: las tiendas de siempre cambian")
	Engine.set_meta(X.INTERRUPTOR_V12, true)
	for id in _nuevos():
		_ok(X.disponible(id), "2: %s no está disponible con el interruptor" % id)
	for lugar in [-1, 0, 1, 5]:
		var t: Dictionary = X.en_tienda(lugar)
		for id in _nuevos():
			_ok(t.get(id, -1) == int(X.ACCESORIOS[id]["precio"]), "2: la tienda de prueba %d no vende %s a su precio" % [lugar, id])
	_ok(X.en_tienda(0).get("farol_peregrino", -1) == 220, "2: con el interruptor, el Farol deja de venderse")
	_limpiar()
	_hecho("2: interruptor apagado por defecto; encendido, tienda de prueba en cualquier lugar")


# ---------------------------------------------------------------- 3. equipar y quitar
func _equipar_y_quitar() -> void:
	_limpiar()
	Engine.set_meta(X.INTERRUPTOR_V12, true)
	G.datos()
	I.datos()
	for id in _nuevos():
		_ok(X.conseguir(id) != "", "3: conseguir %s no lo apunta" % id)
	var lya0: Dictionary = G.estadisticas("Lya")
	_ok(I.equipar("Lya", "anillo", "anillo_alba"), "3: Lya no puede ponerse el Anillo del Alba")
	_ok(not I.equipar("Lya", "accesorio", "anillo_alba") and not I.equipar("Lya", "amuleto", "anillo_alba"),
		"3: el Anillo del Alba entra en otra ranura")
	var lya1: Dictionary = G.estadisticas("Lya")
	_ok(lya1["pm_max"] == lya0["pm_max"] + 6 and lya1["pv_max"] == lya0["pv_max"], "3: +2 Espíritu no da 6 PM (%d → %d)" % [lya0["pm_max"], lya1["pm_max"]])
	_ok(X.efectos_de("Lya") == {"res_magica": 0.20}, "3: efectos de Lya con el Anillo: %s" % [X.efectos_de("Lya")])
	_ok(I.equipar("Kael", "anillo", "anillo_alba") and I.equipo_de("Lya").get("anillo", "") == "" and I.quien_lleva("anillo_alba") == "Kael",
		"3: pasar el anillo de Lya a Kael")
	_ok(var_to_str(G.estadisticas("Lya")) == var_to_str(lya0), "3: al quitárselo, Lya no vuelve a como estaba")
	_ok(not I.equipar("Lya", "accesorio", "fiador_empunadura") and not I.equipar("Garon", "accesorio", "fiador_empunadura")
		and I.equipar("Kael", "accesorio", "fiador_empunadura"), "3: el Fiador no es solo de Kael")
	_ok(not I.equipar("Kael", "accesorio", "rosario_loto") and I.equipar("Lya", "accesorio", "rosario_loto"), "3: el Rosario no es solo de Lya")
	_ok("rosario_loto" in I.opciones("Lya", "accesorio") and not "rosario_loto" in I.opciones("Kael", "accesorio")
		and "anillo_cuarzo" in I.opciones("Garon", "anillo") and not "anillo_cuarzo" in I.opciones("Garon", "accesorio")
		and "talisman_ceniza" in I.opciones("Garon", "amuleto"), "3: opciones() por ranura y «solo»")
	var garon0: Dictionary = G.estadisticas("Garon")
	_ok(I.equipar("Garon", "anillo", "anillo_cuarzo") and I.equipar("Garon", "amuleto", "talisman_ceniza")
		and I.equipar("Garon", "accesorio", "broche_guardian"), "3: Garon no se pone tres a la vez")
	var garon1: Dictionary = G.estadisticas("Garon")
	_ok(garon1["defensa"] == garon0["defensa"] + 2 and garon1["velocidad"] == garon0["velocidad"] + 1.0
		and garon1["pv_max"] == garon0["pv_max"] + 8, "3: cuarzo (+2 Def, +1 Vel) y talismán (+1 Vit) no llegan a Garon")
	var ef: Dictionary = X.efectos_de("Garon")
	_ok(ef == {"res_quemadura": 0.5, "guardia_def": 0.20}, "3: efectos de Garon con tres: %s" % [ef])
	_ok(I.resumen("anillo_cuarzo") == "+2 Defensa  +1 Velocidad", "3: resumen del cuarzo: %s" % I.resumen("anillo_cuarzo"))
	for r in ["anillo", "amuleto", "accesorio"]:
		I.equipar("Garon", r, "")
	_ok(var_to_str(G.estadisticas("Garon")) == var_to_str(garon0) and X.efectos_de("Garon").is_empty(), "3: al quitarlos, Garon no vuelve a como estaba")
	_limpiar()
	_hecho("3: equipar y quitar (ranuras, «solo», atributos y efectos)")


# ---------------------------------------------------------------- 4. funciones de los ganchos
func _funciones() -> void:
	var h := {"nombre": "Garon", "hero": true, "hp": 100, "hp_max": 200, "efectos": {"guardia_def": 0.2, "res_magica": 0.2}}
	var lya := {"nombre": "Lya", "hero": true, "hp": 50, "hp_max": 80}
	var heroes := [h, lya]
	_ok(X.dano_al_heroe(h, 50, heroes, false) == 50 and X.dano_al_heroe(h, 50, heroes, true) == 40, "4: Alba")
	lya["guardia_de"] = "Garon"
	_ok(X.protegiendo(h, heroes) and X.dano_al_heroe(h, 50, heroes, false) == 40 and X.dano_al_heroe(h, 50, heroes, true) == 32,
		"4: Broche (y con el Alba a la vez)")
	lya["hp"] = 0
	_ok(not X.protegiendo(h, heroes), "4: cubre a un caído")
	_ok(X.dano_al_heroe(h, 1, heroes, true) == 1 and X.dano_al_heroe(h, 0, heroes, true) == 0, "4: menos de 1 o daño 0")
	_ok(X.dano_al_heroe({"hp": 10, "hp_max": 10}, 37, heroes, true) == 37, "4: sin accesorio cambia el daño")
	_ok(X.dano_continuo({"efectos": {"res_quemadura": 0.5}}, 9) == 5 and X.dano_continuo({}, 9) == 9, "4: Talismán")
	var k := {"hero": true, "hp": 30, "hp_max": 120, "efectos": {"furia_baja": 0.2, "remate": 0.2}}
	var e_bajo := {"hp": 20, "hp_max": 100}
	var e_alto := {"hp": 90, "hp_max": 100}
	_ok(X.dano_fisico_heroe(k, e_bajo, 50) == 70 and X.dano_fisico_heroe(k, e_alto, 50) == 60, "4: furia y remate (vida baja)")
	k["hp"] = 120
	_ok(X.dano_fisico_heroe(k, e_alto, 50) == 50 and X.dano_fisico_heroe(k, e_bajo, 50) == 60, "4: furia y remate (vida alta)")
	_ok(X.dano_fisico_heroe({"hp": 1, "hp_max": 100}, e_bajo, 50) == 50, "4: sin accesorio cambia el golpe")
	var q := {"efectos": {"pot_agua": 0.1, "pot_rayo": 0.1, "pot_cura": 0.15}}
	_ok(X.potencia_magia(q, "Agua", 40) == 44 and X.potencia_magia(q, "Rayo", 50) == 55 and X.potencia_magia(q, "Fuego", 50) == 50
		and X.potencia_magia(q, "Cura", 60) == 69 and X.potencia_magia(q, "", 50) == 50 and X.potencia_magia({}, "Agua", 40) == 40,
		"4: Eco y Rosario")
	_ok(X.cura_recibida({"efectos": {"cura_recibida": 0.15}}, 60) == 69 and X.cura_recibida({}, 60) == 60, "4: savia")
	_ok(X.atb_al_defender({"atb_defender": 25.0}) == 25.0 and X.atb_al_defender({}) == 0.0
		and is_equal_approx(X.atb_al_defender({"atb_defender": 500.0}), 99.9), "4: centinela")
	var v := {"efectos": {"velo": true}}
	_ok(X.velo(v) and not X.velo(v) and not X.velo({}), "4: el Velo no es una vez")
	_ok(not X.rareza("anillo_alba").is_empty() and X.rareza("farol_peregrino").is_empty() and X.rareza("no_existe").is_empty(),
		"4: rareza()")
	var ic = load("res://icono_equipo.gd").para("anillo_alba")
	_ok(ic != null and ic.categoria == "anillo" and ic.color == X.RAREZAS["raro"]["color"], "4: icono del Anillo del Alba")
	_ok(load("res://icono_equipo.gd").para("farol_peregrino") == null, "4: un accesorio de antes tiene icono")
	if ic != null:
		ic.free()
	seed(4242)
	var a := randi()
	seed(4242)
	var vacio := {"hp": 10, "hp_max": 10}
	X.dano_al_heroe(vacio, 10, [vacio], true)
	X.dano_continuo(vacio, 5)
	X.dano_fisico_heroe(vacio, vacio, 10)
	X.potencia_magia(vacio, "Agua", 10)
	X.cura_recibida(vacio, 10)
	X.atb_al_defender({})
	X.velo(vacio)
	X.velo({"efectos": {"velo": true}})
	_ok(randi() == a, "4: los ganchos nuevos tiran del generador global")
	_hecho("4: funciones de los ganchos (y sin accesorio, lo mismo y sin dados)")


# ---------------------------------------------------------------- 5 y 6. combates de verdad
func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _empezar(e: String) -> void:
	escenario = e
	f_fin = -1
	datos.clear()
	_limpiar()
	Engine.set_meta(X.INTERRUPTOR_V12, true)
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	for id in _nuevos():
		X.conseguir(id)
	var lya0: Dictionary = G.estadisticas("Lya")
	match e:
		"A":
			_ok(I.equipar("Kael", "accesorio", "velo_bruma") and I.equipar("Kael", "anillo", "anillo_alba")
				and I.equipar("Kael", "amuleto", "talisman_ceniza") and I.equipar("Lya", "accesorio", "rosario_loto")
				and I.equipar("Lya", "amuleto", "colgante_eco") and I.equipar("Lya", "anillo", "anillo_cuarzo")
				and I.equipar("Garon", "accesorio", "broche_guardian") and I.equipar("Garon", "amuleto", "colgante_savia"),
				"no se pudo equipar la tanda A")
			datos["def_lya"] = int(lya0["defensa"]) + 2
		"B":
			I.agregar("colmillo_nocturno")
			_ok(I.equipar("Kael", "arma", "colmillo_nocturno") and I.equipar("Kael", "accesorio", "fiador_empunadura")
				and I.equipar("Garon", "accesorio", "brazal_ultimo_muro") and I.equipar("Lya", "accesorio", "brazalete_centinela"),
				"no se pudo equipar la tanda B")
	Engine.set_meta("zona", "desierto")          # sin «zona limpia»: el Grimfang no huye solo
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 9)          # un Grimfang
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	if not "estado" in c:                         # combate.gd no cargó (error de script): se acaba ya, con su fallo
		_ok(false, "%s: combate.gd no carga" % e)
		_terminar()
		return
	seed(20261112)
	for en in c.enemigos:
		en["atb"] = 0.0                           # que los héroes vayan antes
	f_inicio = frames
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	var garon := _heroe("Garon")
	_ok(not kael.is_empty() and not lya.is_empty() and not garon.is_empty(), "faltan héroes en el combate")
	match e:
		"A":
			_ok(kael["efectos"] == {"velo": true, "res_magica": 0.20, "res_quemadura": 0.5}, "efectos de Kael: %s" % [kael["efectos"]])
			_ok(lya["efectos"] == {"pot_cura": 0.15, "pot_agua": 0.10, "pot_rayo": 0.10}, "efectos de Lya: %s" % [lya["efectos"]])
			_ok(garon["efectos"] == {"guardia_def": 0.20, "cura_recibida": 0.15}, "efectos de Garon: %s" % [garon["efectos"]])
			_ok(int(lya["def"]) == datos["def_lya"], "el cuarzo no da +2 de defensa a Lya en el combate (%d)" % lya["def"])
			_ok(int(kael["mp_max"]) == int(G.estadisticas("Kael")["pm_max"]), "el Anillo del Alba no llega a los PM del combate")
		"B":
			_ok(kael["efectos"] == {"remate": 0.20} and garon["efectos"] == {"furia_baja": 0.20}
				and lya["efectos"] == {"atb_defender": 25.0}, "efectos de la tanda B: %s %s %s" % [kael["efectos"], garon["efectos"], lya["efectos"]])


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:
		return false
	if c == null:
		if espera > 0:
			espera -= 1
			return false
		if pendientes.is_empty():
			_guardado()
			_menus()
			_terminar()
			return true
		_empezar(pendientes.pop_front())
		return false
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		_turno(c.actor)
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	var acabado: bool = f_fin >= 0 and (c.menu.heroe_actual.get("nombre", "") == "Fin" or frames - f_fin > 900)
	if acabado or frames - f_inicio > MAX_FOTOGRAMAS:
		_cerrar()
	return false


func _turno(h: Dictionary) -> void:
	if datos.get("ocupado", false):
		return
	datos["ocupado"] = true
	if not datos.has("secuencia"):
		datos["secuencia"] = true
		if escenario == "A":
			_secuencia_a.call_deferred(h)
		else:
			_secuencia_b.call_deferred(h)
		return
	# con todo comprobado, se huye desde el menú (no tras una acción: su final volvería a poner el combate a esperar)
	if (escenario == "A" and datos.has("cura") and datos.has("pocion")) or (escenario == "B" and datos.has("centinela")):
		datos["turno"] = true
		c._escapar()
		return
	if escenario == "A":
		_accion_a.call_deferred(h)
	else:
		_accion_b.call_deferred(h)


# Golpes forzados con las funciones de verdad del combate (el menú del primer héroe espera mientras tanto).
func _secuencia_a(_h: Dictionary) -> void:
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	var garon := _heroe("Garon")
	var grim: Dictionary = c.enemigos[0]
	# Anillo del Alba: solo los ataques marcados como mágicos
	kael["hp"] = kael["hp_max"]
	c.dano_magico_entrante = true
	_ok(c._quitar_pv(kael, 50) == 40, "A: con el Alba, un ataque mágico de 50 no quita 40")
	c.dano_magico_entrante = false
	_ok(c._quitar_pv(kael, 50) == 50, "A: el Alba reduce un golpe físico")
	_ok(c._quitar_pv(lya, 50) == 50, "A: sin el Alba, Lya recibe menos")
	lya["hp"] = lya["hp_max"]
	# Broche del Guardián: mientras cubre con su Guardia
	garon["hp"] = garon["hp_max"]
	lya["guardia_de"] = "Garon"
	_ok(c._quitar_pv(garon, 50) == 40, "A: Garon cubriendo con el Broche no recibe 40 de 50")
	lya.erase("guardia_de")
	_ok(c._quitar_pv(garon, 50) == 50, "A: el Broche reduce sin cubrir")
	garon["hp"] = garon["hp_max"]
	# Talismán de Ceniza: la corrupción de Humbaba (combate_humbaba.gd tic_heroe) a la mitad
	kael["hp"] = kael["hp_max"]
	kael["hb_corrupcion"] = 2
	var Hb = load("res://combate_humbaba.gd")
	Hb.tic_heroe(c, kael)
	var base := maxi(1, int(kael["hp_max"] * Hb.CORRUPCION_PCT))
	_ok(kael["hp_max"] - kael["hp"] == int(round(base * 0.5)), "A: la corrupción con el Talismán quita %d y no %d" % [kael["hp_max"] - kael["hp"], int(round(base * 0.5))])
	lya["hp"] = lya["hp_max"]
	lya["hb_corrupcion"] = 2
	Hb.tic_heroe(c, lya)
	_ok(lya["hp_max"] - lya["hp"] == maxi(1, int(lya["hp_max"] * Hb.CORRUPCION_PCT)), "A: sin Talismán, la corrupción cambia")
	kael.erase("hb_corrupcion")
	lya.erase("hb_corrupcion")
	kael["hp"] = kael["hp_max"]
	lya["hp"] = lya["hp_max"]
	# Velo de bruma: el primer golpe físico del Grimfang no llega; el segundo, sí
	await c._animar_golpe(grim, kael, 30, "")
	_ok(kael["hp"] == kael["hp_max"] and kael.get("velo_usado", false) and c.ultimo_esquivado, "A: el Velo no esquiva el primer golpe")
	await c._animar_golpe(grim, kael, 30, "")
	_ok(kael["hp"] < kael["hp_max"] and not c.ultimo_esquivado, "A: el Velo esquiva también el segundo golpe")
	kael["hp"] = kael["hp_max"]
	# Colgante del Eco: Agua y Rayo +10 %, Fuego igual (misma tirada)
	var F = load("res://combate_formulas.gd")
	for fam in ["Agua", "Rayo", "Fuego"]:
		var d: Dictionary = c.NIVELES_MAGIA[fam][0]
		seed(77)
		var con: int = c._dano_magia(lya, d)
		seed(77)
		var sin: int = F.dano_magia(lya, d)
		var esperado: int = int(round(sin * 1.1)) if fam != "Fuego" else sin
		_ok(con == esperado, "A: %s de Lya con el Eco: %d y no %d" % [fam, con, esperado])
	datos.erase("ocupado")
	datos["listo"] = true


# Acciones de turno: Lya cura a Garon (Rosario y savia), Garon toma una Poción (savia), Kael defiende (sin Brazalete,
# la barra a 0). Con las dos curas comprobadas, huyen.
func _accion_a(h: Dictionary) -> void:
	var garon := _heroe("Garon")
	match h["nombre"]:
		"Lya":
			if not datos.has("cura"):
				garon["hp"] = int(garon["hp_max"] * 0.3)
				var antes: int = garon["hp"]
				c.magia_sel = "Cura"
				c.nivel_sel = 1
				var d: Dictionary = c.NIVELES_MAGIA["Cura"][0]
				var cantidad: int = int(d["dano"] * h.get("magia_mult", 1.0)) + int(h.get("magia_extra", 0))
				var con_rosario: int = int(round(cantidad * 1.15))
				await c._aplicar_cura([garon])
				var cura: int = garon["hp"] - antes
				var minimo: int = int(round((con_rosario - 3) * 1.15))
				var maximo: int = int(round((con_rosario + 3) * 1.15))
				_ok(cura >= minimo and cura <= maximo, "A: Cura de Lya (Rosario) a Garon (savia): %d, esperado %d-%d (sin nada, %d±3)" % [cura, minimo, maximo, cantidad])
				datos["cura"] = cura
			else:
				await c._defender()
		"Garon":
			if not datos.has("pocion"):
				garon["hp"] = int(garon["hp_max"] * 0.3)
				var antes_p: int = garon["hp"]
				await c._usar_objeto("Poción", garon)
				_ok(garon["hp"] - antes_p == int(round(60 * 1.15)), "A: la Poción con savia cura %d y no 69" % (garon["hp"] - antes_p))
				datos["pocion"] = true
			else:
				await c._defender()
		_:
			await c._defender()
			_ok(is_equal_approx(float(h["atb"]), 0.0) or float(h["atb"]) < 2.0, "A: sin Brazalete, Defender deja barra (%.1f)" % h["atb"])
			datos["defensa_kael"] = true
	datos.erase("ocupado")


func _secuencia_b(_h: Dictionary) -> void:
	var kael := _heroe("Kael")
	var garon := _heroe("Garon")
	var grim: Dictionary = c.enemigos[0]
	grim["hp_max"] = 1000
	var m: float = c.MULT_CRITICO
	# Fiador de empuñadura: +20 % a un enemigo por debajo del 30 %
	for caso in [[200, [24, int(24 * m)]], [900, [20, int(20 * m)]]]:
		grim["hp"] = caso[0]
		await c._animar_golpe(kael, grim, 20, "")
		var hecho: int = caso[0] - grim["hp"]
		_ok(hecho in caso[1], "B: Kael (Fiador) con el Grimfang a %d PV hace %d y no %s" % [caso[0], hecho, caso[1]])
	# Brazal del último muro: +20 % con un tercio de vida o menos
	for caso in [[int(garon["hp_max"] / 4), [24, int(24 * m)]], [garon["hp_max"], [20, int(20 * m)]]]:
		garon["hp"] = caso[0]
		grim["hp"] = 900
		await c._animar_golpe(garon, grim, 20, "")
		var hecho_g: int = 900 - grim["hp"]
		_ok(hecho_g in caso[1], "B: Garon (Brazal) con %d PV hace %d y no %s" % [caso[0], hecho_g, caso[1]])
	garon["hp"] = garon["hp_max"]
	grim["hp"] = 900
	datos.erase("ocupado")
	datos["listo"] = true


func _accion_b(h: Dictionary) -> void:
	await c._defender()
	if h["nombre"] == "Lya":
		_ok(is_equal_approx(float(h["atb"]), 25.0), "B: Lya con el Brazalete no empieza con 25 de barra tras Defender (%.2f)" % h["atb"])
		datos["centinela"] = true
	else:
		_ok(float(h["atb"]) < 2.0, "B: %s sin Brazalete empieza con barra tras Defender (%.2f)" % [h["nombre"], h["atb"]])
	datos.erase("ocupado")


func _cerrar() -> void:
	_ok(c.estado == "fin", "%s: el combate no terminó (estado %s)" % [escenario, c.estado])
	_ok(datos.get("listo", false), "%s: no se hicieron los golpes forzados" % escenario)
	_ok(datos.get("turno", false), "%s: no llegó a las acciones de turno" % escenario)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	espera = 3
	_hecho("%s: combate de verdad con la tanda %s" % ["5" if escenario == "A" else "6", escenario])


# ---------------------------------------------------------------- 7. guardar y cargar
func _guardado() -> void:
	_limpiar()
	_borrar()
	Engine.set_meta(X.INTERRUPTOR_V12, true)
	G.datos()
	I.datos()
	for id in ["anillo_alba", "broche_guardian", "colgante_eco"]:
		X.conseguir(id)
	I.equipar("Lya", "anillo", "anillo_alba")
	I.equipar("Lya", "amuleto", "colgante_eco")
	I.equipar("Garon", "accesorio", "broche_guardian")
	var lya_antes: Dictionary = G.estadisticas("Lya")
	var d: Dictionary = P.volcar("res://mapa.tscn").duplicate(true)
	_limpiar()
	P.restaurar(d)
	_ok(I.equipo_de("Lya").get("anillo", "") == "anillo_alba" and I.equipo_de("Lya").get("amuleto", "") == "colgante_eco"
		and I.equipo_de("Garon").get("accesorio", "") == "broche_guardian", "7: no vuelven al cargar (memoria)")
	_ok(P.escribir(P.volcar("res://mapa.tscn"), ARCHIVO), "7: no se pudo escribir %s" % ARCHIVO)
	_limpiar()                                    # y se carga con el interruptor APAGADO
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "7: no se pudo leer %s" % ARCHIVO)
	if leida is Dictionary:
		P.restaurar(leida)
		_ok(not X.v12_activo(), "7: el interruptor viaja en la partida")
		_ok(var_to_str(G.estadisticas("Lya")) == var_to_str(lya_antes), "7: tras cargar, Lya no tiene lo mismo")
		_ok(X.efectos_de("Lya") == {"res_magica": 0.20, "pot_agua": 0.10, "pot_rayo": 0.10}, "7: tras cargar, efectos de Lya: %s" % [X.efectos_de("Lya")])
		_ok(X.efectos_de("Garon") == {"guardia_def": 0.20}, "7: tras cargar, el Broche no da su efecto")
		for lugar in [0, 5]:
			for id in X.en_tienda(lugar):
				_ok(not X.es_v12(id), "7: sin interruptor, la tienda vende %s" % id)
	# partida antigua: sin nada nuevo
	_limpiar()
	var antigua := {"inventario": {"oro": 80, "objetos": {"Poción": 2}, "equipables": ["frostfang", "cetro_loto", "anillo_rubi"],
		"equipo": {"Kael": {"arma": "frostfang"}, "Lya": {"arma": "cetro_loto", "anillo": "anillo_rubi"}}}, "escena_guardada": "res://mapa.tscn"}
	P.restaurar(antigua)
	_ok(I.equipo_de("Lya").get("anillo", "") == "anillo_rubi" and X.efectos_de("Lya").is_empty() and X.efectos_de("Kael").is_empty(),
		"7: una partida antigua cambia")
	_ok(I.opciones("Lya", "amuleto").filter(func(id): return X.es_v12(id)).is_empty(), "7: una partida antigua tiene accesorios nuevos")
	# un id que esta versión no conoce, en una ranura de anillo: sin error ni efecto
	I.equipo_de("Lya")["anillo"] = "anillo_de_una_version_nueva"
	_ok(X.efectos_de("Lya").is_empty() and G.estadisticas("Lya").has("pv_max"), "7: un id desconocido rompe algo")
	_limpiar()
	_borrar()
	_hecho("7: guardar y cargar (memoria, archivo, sin interruptor, partida antigua, id desconocido)")


# ---------------------------------------------------------------- 8. menús
func _menus() -> void:
	_limpiar()
	G.datos()
	I.datos()
	I.ganar_oro(5000)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("lugar", {"indice": 0, "nombre": "x", "tipo": "ciudad", "zona": "llanura", "texto": "x"})
	# sin interruptor: la tienda de siempre
	var t = load("res://tienda.gd").new()
	t.pestana = "Equipo"
	root.add_child(t)
	var textos: Array = t.cuerpo.find_children("*", "Label", true, false).map(func(l): return l.text)
	_ok(not textos.any(func(x): return str(x).begins_with("Prueba V12")), "8: sin interruptor, la tienda dice «Prueba V12»")
	_ok(t.cuerpo.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == load("res://icono_equipo.gd")).is_empty(),
		"8: sin interruptor, la tienda tiene iconos nuevos")
	t.free()
	# con interruptor: la tienda de prueba
	Engine.set_meta(X.INTERRUPTOR_V12, true)
	t = load("res://tienda.gd").new()
	t.pestana = "Equipo"
	root.add_child(t)
	textos = t.cuerpo.find_children("*", "Label", true, false).map(func(l): return l.text)
	_ok(textos.any(func(x): return str(x).begins_with("Prueba V12")), "8: la tienda de prueba no lo dice")
	var iconos: Array = t.cuerpo.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == load("res://icono_equipo.gd"))
	_ok(iconos.size() == _nuevos().size(), "8: la tienda tiene %d iconos y no %d" % [iconos.size(), _nuevos().size()])
	var lbl_alba: Label = null
	for l in t.cuerpo.find_children("*", "Label", true, false):
		if l.text == "Anillo del Alba":
			lbl_alba = l
	_ok(lbl_alba != null and lbl_alba.get_theme_color("font_color") == X.RAREZAS["raro"]["color"], "8: el nombre del Anillo no va en el color de su rareza")
	_ok(textos.has("Raro · Todos") and textos.has("Raro · Solo Kael") and textos.has("Común · Todos"), "8: notas de rareza: %s" % [textos])
	var oro: int = I.oro()
	t._comprar_equipo("anillo_alba")
	_ok(I.oro() == oro - 380 and "anillo_alba" in I.datos()["equipables"], "8: comprar el Anillo del Alba no cuesta 380 o no lo da")
	var b = root.get_node("Entrada").buscar(t, "comprar:Anillo del Alba")
	_ok(b == null or b.disabled, "8: tras comprarlo, el Anillo se puede volver a comprar")
	t.free()
	# menú Grupo: la ficha (con el anillo puesto) y Objetos
	I.equipar("Kael", "anillo", "anillo_alba")
	var m = load("res://menus.gd").new()
	root.add_child(m)
	var en_ficha: Array = m.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == load("res://icono_equipo.gd"))
	_ok(en_ficha.size() == 1, "8: la ficha de Kael tiene %d iconos (1)" % en_ficha.size())
	m.pestana = "Objetos"
	m._pintar_de_nuevo()
	var en_obj: Array = m.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == load("res://icono_equipo.gd"))
	_ok(en_obj.size() == 1, "8: Objetos tiene %d iconos (1)" % en_obj.size())
	m.free()
	_limpiar()
	_hecho("8: menús (tienda de prueba, ficha y Objetos)")


func _terminar() -> void:
	_limpiar()
	_borrar()
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
