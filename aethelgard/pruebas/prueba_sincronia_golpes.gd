extends SceneTree
# V12, sincronía (12/11/2026): el golpe a todos de los enemigos de siempre cae en el instante del impacto. Sin ventana,
# datos aislados, interruptores apagados (el juego de siempre). Para cada caso se fuerza la descarga y se apunta en qué
# fotograma pierde vida cada héroe:
#   - el golpe devastador de un «jefe» (Gorthor, GRUPOS[5]; el Guardián de piedra de siempre, GRUPOS[4]);
#   - el Pisotón del Gólem de ámbar (patrón «bruto», GRUPOS[6]).
# Todos los héroes alcanzados pierden vida en el MISMO fotograma (antes, el principal en el impacto y los demás al
# acabar la animación, 0,6-1 s después); el golpe se oye en ese fotograma (Sonido.golpe sube en él) y el daño a los
# demás es el de la regla de siempre (máx(1, golpe − DEF/2), a la mitad si defienden). También: si el principal
# esquiva, los demás reciben igual (una vez).

const ARCHIVO := "user://prueba_sincronia_golpes.save"
var C
var G
var P
var c = null
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	C = load("res://combate.gd")
	G = load("res://grupo.gd")
	P = load("res://progreso.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			"enemigos_v12"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(10)
	await _caso(5, "gorthor", "garganta", "jefe", 12)
	await _caso(4, "guardian", "llanura", "normal", 12)
	await _caso(6, "golem_ambar", "garganta", "normal", 3)   # (nivel bajo: en una zona «limpia» huiría)
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "\n    ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _caso(grupo: int, clave: String, zona: String, tipo: String, nivel: int) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = nivel
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("grupo_combate", grupo)
	seed(11)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(90)
	c.estado = "fin"                                   # parado: solo lo que se fuerza
	var f: Dictionary = c.enemigos.filter(func(e): return e["clave"] == clave)[0]
	for e in c.enemigos:
		if not is_same(e, f):
			e["hp"] = 0                                  # (que no actúe nadie más)
	f["hp_max"] = 5000
	f["hp"] = 5000
	var S = root.get_node_or_null("Sonido")
	for defiende in [false, true]:
		for h in c.heroes:
			h["hp"] = h["hp_max"]
			h["defendiendo"] = defiende and h["nombre"] == "Garon"
		f["cargando"] = true
		f["recupera"] = false
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		var cuando := {}
		var golpes_en := []
		var g0: int = _golpes(S)
		var hecho := [false]
		var corre := func():
			await c._turno_enemigo(f)
			hecho[0] = true
		corre.call()
		for fr in 900:
			await process_frame
			for h in c.heroes:
				if h["hp"] < antes[h["nombre"]] and not cuando.has(h["nombre"]):
					cuando[h["nombre"]] = Engine.get_process_frames()
			var g1: int = _golpes(S)
			if g1 > g0:
				golpes_en.append(Engine.get_process_frames())
				g0 = g1
			if hecho[0]:
				break
		c.estado = "fin"
		var fr_set := {}
		for k in cuando:
			fr_set[cuando[k]] = true
		var n := "%s%s" % [f["nombre"], " (Garon defiende)" if defiende else ""]
		_ok(cuando.size() == 3, "%s: alcanza a %s (los tres)" % [n, str(cuando.keys())])
		_ok(fr_set.size() == 1, "%s: los héroes pierden vida en fotogramas distintos: %s" % [n, str(cuando)])
		if fr_set.size() == 1 and not golpes_en.is_empty():
			_ok(golpes_en[0] == fr_set.keys()[0], "%s: el golpe suena en el %d y el daño cae en el %d" % [n, golpes_en[0], fr_set.keys()[0]])
		var quita := {}
		for h in c.heroes:
			quita[h["nombre"]] = antes[h["nombre"]] - h["hp"]
		hechos.append("%s: daño %s en el fotograma %s; golpes oídos en %s; cartel «%s»" % [n, str(quita), str(fr_set.keys()), str(golpes_en), c.registro.text])
		await _esperar(30)
	c.queue_free()
	c = null
	await _esperar(10)


func _golpes(S) -> int:
	if S == null:
		return 0
	return int(S.contador.get("golpe", 0)) + int(S.contador.get("golpe_defendido", 0)) + int(S.contador.get("golpe_critico", 0))
