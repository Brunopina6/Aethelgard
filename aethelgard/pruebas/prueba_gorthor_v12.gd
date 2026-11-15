extends SceneTree
# V12, enemigos (12/11/2026): Gorthor el Devorador con «enemigos_v12» (combate_gorthor.gd y sus ganchos de combate.gd y
# sonido.gd; enemigos/gorthor/gorthor_v2.glb) en combates de verdad. Sin ventana, con datos aislados; la partida apunta
# a su propio archivo y los combates no guardan.
#   U. Sin escena: el interruptor apagado por defecto y fuera de la partida; apagado, Gorthor.es() es falso; sus 6
#      claves de sonido (QOA mono 48 kHz, < 2,5 s, con su fila de procedencia); el v2 con los clips de antes iguales y
#      los cinco nuevos con sus instantes.
#   S. Apagado, en escena: el de siempre (gorthor3d, sin nada nuevo); encendido, gorthor_v12 con lo nuevo.
#   A. El combate fijo de la Garganta (GRUPOS[5], «garganta_gorthor», jefe) con Kael, Lya y Garon a nivel 9 y una
#      estrategia de jugador (contra la Hoguera: Lya la apaga con Agua; si no puede, se defienden; curar; al final,
#      «Acabar»). Gorthor lleva vida ×1,5 solo aquí, para ver la fase 2 entera. En cada turno suyo con la
#      Hoguera: el aviso sin daño, con sus brasas, su señal y su sonido al clavar; la Hoguera un turno de héroe después,
#      un impacto, todos los alcanzados en ese fotograma (±1), su sonido una vez en él y el golpe de siempre una vez;
#      aturdido, sin daño. Lo de siempre sigue: fase 2 con su rugido, Devorar con su trago, rodillas con su sonido,
#      la decisión de Kael y su premio (las Fauces de Gorthor, una vez).
#   B. Controlado: la Hoguera apagada con Agua (y no con Fuego), cortada por Quiebra y por un cuarto de su vida
#      (aturdido, pierde el turno, «apagada» suena una vez); entera sin defender, defendiendo (a la mitad) y con la
#      Guardia de Garon; herida fuerte y ligera; sin fase 2 no la prepara nunca.
#   C. Dos héroes y Kael solo (automáticos; en la decisión, perdonar): terminan.
#   E. Derrota (sin premio).
#   Q. Equilibrio frente al Gorthor de siempre (GRUPOS[5], 6 semillas, solo ataques automáticos, perdonar).
# Con «fotos=<carpeta>» (y ventana) guarda fotogramas del B para los vídeos (indice.txt).
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que la semilla se pone DESPUÉS de
# root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos con ella (como prueba_combate_huella.gd). Antes se
# sembraba antes de add_child y A, C, E y Q eran combates al azar (A falló una vez en batería el 14/11). Cada combate
# imprime «SEMILLA» y una línea «TRAZA» por turno (quién, qué hizo y los PV); «semilla_A=N» (o _C, _E, _Q) cambia la
# semilla de ese caso para reproducir uno concreto.

const ARCHIVO := "user://prueba_gorthor_v12.save"
const MAX_FOTOGRAMAS := 20000
const CLAVES_SONIDO := ["gorthor_rugido", "gorthor_trago", "gorthor_rodillas", "gorthor_hoguera_carga", "gorthor_hoguera",
	"gorthor_apagada"]
var GT
var C
var P
var G
var Inv
var S
var c = null
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []
var impactos: Array = []
var danos: Array = []
var hp_prev := {}
var fotos := ""
var grabando := false
var n_foto := 0
var indice: Array = []
var huerfanos0 := -1


func _initialize() -> void:
	GT = load("res://combate_gorthor.gd")
	C = load("res://combate.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	if fotos != "":
		process_frame.connect(func():
			if grabando:
				_grabar())
	process_frame.connect(_vigilar)                   # (cada fotograma, también mientras se espera a un turno)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		_vigilar()


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			GT.INTERRUPTOR]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(10)
	S = root.get_node_or_null("Sonido")
	huerfanos0 = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_u()
	var solo := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			solo = a.substr(5)
	for p in ["S", "A", "B", "C", "E", "Q"]:
		if solo == "" or solo.contains(p):
			await call("_" + p.to_lower())
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	if fotos != "":
		var f := FileAccess.open(fotos.path_join("indice.txt"), FileAccess.WRITE)
		f.store_string("\n".join(indice) + "\n")
	print("OK: ", "\n    ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= U

func _u() -> void:
	_limpiar()
	_ok(not GT.ACTIVO_POR_DEFECTO and not GT.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not GT.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	_ok(not GT.es({"clave": "gorthor", "hero": false}), "U: apagado, Gorthor.es() es cierto")
	Engine.set_meta(GT.INTERRUPTOR, true)
	_ok(GT.es({"clave": "gorthor", "hero": false}) and not GT.es({"clave": "golem_ambar", "hero": false}),
		"U: encendido, Gorthor.es() no reconoce solo a Gorthor")
	Engine.remove_meta(GT.INTERRUPTOR)
	var Son = load("res://sonido.gd")
	var csv := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../docs/audio/efectos_procedencia.csv"))
	for k in CLAVES_SONIDO:
		var d: Dictionary = Son.EFECTOS.get(k, {})
		_ok(not d.is_empty(), "U: falta la clave «%s»" % k)
		if d.is_empty():
			continue
		var ruta: String = Son.ruta_archivo(d)
		var st = load(ruta)
		_ok(st is AudioStreamWAV and st.format == AudioStreamWAV.FORMAT_QOA and not st.stereo and st.mix_rate == 48000,
			"U: %s no es QOA mono a 48 kHz" % ruta)
		if st is AudioStream:
			_ok(st.get_length() > 0.3 and st.get_length() < 2.5, "U: %s dura %.2f s" % [ruta, st.get_length()])
		_ok(csv.contains(String(d["a"]) + ".wav;S"), "U: %s no tiene su fila de procedencia" % ruta)
	for k in GT.SONIDOS.values():
		_ok(Son.EFECTOS.has(k), "U: combate_gorthor.gd pide «%s», que no existe" % k)
	var v1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/gorthor/gorthor_clips.json"))
	var v2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/gorthor/gorthor_v2_clips.json"))
	_ok(int(v1["triangulos"]) == int(v2["triangulos"]) and int(v1["huesos"]) == int(v2["huesos"]), "U: el v2 cambia la malla")
	for clip in v1["clips"]:
		_ok(v2["clips"].has(clip) and v2["clips"][clip] == v1["clips"][clip], "U: el clip «%s» cambia en el v2" % clip)
	var p = load("res://enemigos/gorthor/gorthor_3d.gd").new()
	root.add_child(p)
	_ok(p.ruta_glb.ends_with("_v2.glb") and p.es_v2(), "U: el guion no carga el v2")
	for clip in ["hoguera_carga", "hoguera_espera", "hoguera", "recibir_golpe_fuerte", "aturdido"]:
		_ok(p.tiene(clip), "U: el v2 no tiene «%s»" % clip)
		if p.tiene(clip):
			_ok(absf(p.duracion(clip) - float(v2["clips"][clip]["duracion"])) < 0.04, "U: «%s» dura %.2f" % [clip, p.duracion(clip)])
			_ok((p.anim.get_animation(clip).loop_mode == Animation.LOOP_LINEAR) == bool(v2["clips"][clip]["bucle"]),
				"U: «%s» con el bucle cambiado" % clip)
			for k in v2["clips"][clip]["eventos"]:
				_ok(absf(p.instante(clip, k) - float(v2["clips"][clip]["eventos"][k])) < 0.002, "U: «%s» sin su instante %s" % [clip, k])
	p.queue_free()
	hechos.append("U interruptor, 6 sonidos con procedencia, modelo v2 (clips de antes iguales y 5 nuevos)")


# ================================================================= un combate

func _combate(activos: Dictionary, semilla: int, encendido := true, fijo := "garganta_gorthor") -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "garganta")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", 5)
	if fijo != "":
		Engine.set_meta("combate_fijo", fijo)
	if encendido:
		Engine.set_meta(GT.INTERRUPTOR, true)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)                                     # (aquí su _ready hace randomize())
	seed(semilla)                                         # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                         # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA %d · %s · %s · %s" % [semilla, str(activos), "encendido" if encendido else "apagado", fijo])
	var g := _gorthor()
	var p = c._p3d(g) if not g.is_empty() else null
	if encendido:
		_ok(p != null and p.has_method("hoguera") and p.es_v2(), "Gorthor: no tiene su modelo v2")
	if p != null and p.has_signal("impacto"):
		p.impacto.connect(func(a): impactos.append([a, Engine.get_process_frames()]))
	for h in c.heroes:
		hp_prev[h["nombre"]] = h["hp"]


func _vigilar() -> void:
	if c == null or not is_instance_valid(c):
		return
	for h in c.heroes:
		var antes: int = hp_prev.get(h["nombre"], h["hp"])
		if h["hp"] < antes:
			danos.append([h["nombre"], Engine.get_process_frames(), antes - h["hp"]])
		hp_prev[h["nombre"]] = h["hp"]


func _cerrar() -> void:
	if c != null:
		await _esperar(60)
		_ok(GT.nodos_vivos(c.enemigos).is_empty(), "al acabar quedan sus brasas: %s" % str(GT.nodos_vivos(c.enemigos)))
		c.queue_free()
		c = null
	await _esperar(75)                                    # 2,5 s de juego a 30 fotogramas por segundo
	# (el audio sin ventana avanza con el reloj real, no con los fotogramas: si aún suena algo suyo, se le dan hasta 5 s
	# reales para acabar; los sonidos duran < 2,5 s. Antes se esperaban siempre 2,5 s reales.)
	var t0 := Time.get_ticks_msec()
	while _suena_suyo() and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	_ok(not _suena_suyo(), "al cerrar el combate sigue sonando algo de Gorthor")
	await _esperar(5)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(h <= huerfanos0, "al cerrar el combate hay %d nodos huérfanos (antes %d)" % [h, huerfanos0])
	_limpiar()


func _suena_suyo() -> bool:
	if S == null:
		return false
	for p in S._todas():
		if p.playing and str(p.get_meta("efecto", "")) in CLAVES_SONIDO and not p.get_meta("apagando", false):
			return true
	return false


func _gorthor() -> Dictionary:
	for e in c.enemigos:
		if str(e.get("clave", "")) == "gorthor":
			return e
	return {}


func _cont(e: Dictionary) -> Dictionary:
	return (e.get("gt_contador", {}) as Dictionary).duplicate()


func _golpes_sonados() -> int:
	if S == null:
		return 0
	return int(S.contador.get("golpe", 0)) + int(S.contador.get("golpe_defendido", 0)) + int(S.contador.get("golpe_critico", 0))


func _foto_estado() -> Dictionary:
	var hp := {}
	for h in c.heroes:
		hp[h["nombre"]] = h["hp"]
	return {"hp": hp, "cont": _cont(_gorthor()), "sonidos": sonidos.size(), "impactos": impactos.size(),
		"danos": danos.size(), "golpes": _golpes_sonados(), "turnos_heroe": c.turnos_heroe}


# «decision»: «acabar» o «perdonar» (en la decisión de Kael).
func _jugar(estrategia: String, decision: String, comprobar := true) -> Dictionary:
	var r := {"acciones": [], "gana": false, "fin": false, "decidido": ""}
	var quien = null
	var ant := {}
	var previo := _foto_estado()
	var f_fin := -1
	var decidido := -1
	var ultimo := []
	var en_decision := 0
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		var actual = c.atacante_actual
		var cerrado := false
		if quien != null and not is_same(actual, quien):
			if str(quien.get("clave", "")) == "gorthor":
				var que := _que_hizo(quien, ant)
				r["acciones"].append(que)
				_traza("Gorthor: %s" % que)
				if comprobar:
					_comprobar_turno(quien, que, ant, ultimo)
				ultimo = [que, c.turnos_heroe]
			quien = null
			cerrado = true
		if actual != null and quien == null:
			quien = actual
			ant = _foto_estado() if cerrado else previo
		if c.atacante_actual == null:
			previo = _foto_estado()
		if c.estado == "decision" and r["decidido"] == "":
			en_decision += 1
		if en_decision > 60 and r["decidido"] == "":           # (como un jugador: tras caer de rodillas y abrirse el menú)
			r["decidido"] = decision
			_traza("decisión: %s" % decision)
			var g := _gorthor()
			if decision == "acabar":
				c._acabar(g)
			else:
				c._perdonar(g)
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_traza("%s: %s" % [c.actor["nombre"], _decidir(estrategia)])
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
			r["pv_fin"] = 0
			for h in c.heroes:
				r["pv_fin"] += maxi(0, int(h["hp"]))
		if f_fin >= 0 and fr - f_fin > 150:
			break
	r["fin"] = c.estado == "fin"
	r["gana"] = r["fin"] and c.heroes.any(func(h): return h["hp"] > 0)   # (acaba: gana, perdona o pierde)
	_traza("fin %s · gana %s" % [r["fin"], r["gana"]])
	return r


# Una línea por turno: fotograma, quién y qué, y los PV de todos (para reproducir una semilla concreta).
func _traza(que: String) -> void:
	var pv := []
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA %05d T%d %s · %s" % [Engine.get_process_frames(), c.turnos_heroe, que, ", ".join(pv)])


# «semilla_A=N» (o _C, _E, _Q) en la línea de órdenes cambia la semilla de ese caso.
func _semilla(caso: String, defecto: int) -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla_%s=" % caso):
			return int(a.get_slice("=", 1))
	return defecto


func _que_hizo(e: Dictionary, ant: Dictionary) -> String:
	var antes: Dictionary = ant["cont"]
	var ahora := _cont(e)
	for k in ["recupera", "hoguera", "aviso_hoguera"]:
		if int(ahora.get(k, 0)) > int(antes.get(k, 0)):
			return k
	return "de_siempre"


func _comprobar_turno(e: Dictionary, que: String, ant: Dictionary, ultimo: Array) -> void:
	var dn: Array = danos.slice(ant["danos"])
	var golpeados := {}
	for d in dn:
		golpeados[d[0]] = true
	var imp: Array = impactos.slice(ant["impactos"])
	var son: Array = sonidos.slice(ant["sonidos"])
	var cuenta := func(n: String) -> Array: return son.filter(func(s): return s[0] == n)
	var golpes: int = _golpes_sonados() - int(ant["golpes"])
	var n := "Gorthor (%s)" % que
	var vivos_antes: Array = ant["hp"].keys().filter(func(k): return int(ant["hp"][k]) > 0)
	match que:
		"aviso_hoguera":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño al avisar" % n)
			_ok(cuenta.call("gorthor_hoguera_carga").size() == 1, "%s: el aviso no suena una vez (%d)" % [n, cuenta.call("gorthor_hoguera_carga").size()])
			if e["hp"] > 0 and e.get("gt_hoguera", false):
				_ok(e.has("aviso_nodo") and e.get("gt_marcas", null) != null and is_instance_valid(e["gt_marcas"]),
					"%s: sin su señal o sin las brasas bajo el grupo" % n)
		"hoguera":
			_ok(imp.size() == 1 and imp[0][0] == "hoguera", "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			_ok(golpeados.size() == vivos_antes.size() or c.cubiertos > 0, "%s: alcanza a %s de %s" % [n, str(golpeados.keys()), str(vivos_antes)])
			if imp.size() == 1:
				for d in dn:
					_ok(absi(int(d[1]) - int(imp[0][1])) <= 1, "%s: %s recibe daño en el %d y el impacto es en el %d" % [n, d[0], d[1], imp[0][1]])
				var s: Array = cuenta.call("gorthor_hoguera")
				_ok(s.size() == 1 and absi(int(s[0][1]) - int(imp[0][1])) <= 1, "%s: la Hoguera no suena una vez en el impacto (%s)" % [n, str(s)])
			_ok(ultimo.size() == 2 and ultimo[0] == "aviso_hoguera", "%s: sin aviso (%s)" % [n, str(ultimo)])
			if ultimo.size() == 2:
				_ok(int(ant["turnos_heroe"]) > int(ultimo[1]), "%s: sin un turno de héroe entre el aviso y la Hoguera" % n)
			_ok(e.get("gt_marcas", null) == null, "%s: las brasas siguen tras estallar" % n)
		"recupera":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: aturdido y hace daño" % n)


func _decidir(estrategia: String) -> String:
	var a: Dictionary = c.actor
	var alc: Array = c._alcanzables()
	if alc.is_empty():
		c._defender()
		return "defender (sin objetivo)"
	if estrategia == "auto":
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(alc[0])
		return "atacar a %s" % alc[0]["nombre"]
	var g := _gorthor()
	var t: Dictionary = g if not g.is_empty() and g["hp"] > 0 else alc[0]
	if g.get("gt_hoguera", false):
		if a["nombre"] == "Lya" and c._puede_pagar(c.NIVELES_MAGIA["Agua"][0]["coste"]):
			c._elegir_hechizo("Agua", 1)                    # el agua apaga las brasas
			c._confirmar_objetivo(t)
			return "Agua a %s" % t["nombre"]
		c._defender()
		return "defender (Hoguera)"
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.45)
		if not heridos.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Cura"][0]["coste"]):
			c._elegir_hechizo("Cura", 1, true)
			return "Cura"
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(t)
	return "atacar a %s" % t["nombre"]


# ================================================================= S

func _s() -> void:
	await _combate({"Kael": 7, "Lya": 7, "Garon": 7}, 3, false)
	var g := _gorthor()
	_ok(g["modelo"] == "gorthor3d" and not GT.es(g), "S: apagado, no es el Gorthor de siempre (%s)" % g["modelo"])
	c.estado = "fin"
	await _cerrar()
	await _combate({"Kael": 7, "Lya": 7, "Garon": 7}, 3, true)
	g = _gorthor()
	_ok(g["modelo"] == "gorthor_v12" and GT.es(g) and g["personalidad"] == "jefe" and g.get("fases", false)
		and g.get("ultimo_aliento", false), "S: encendido, no es gorthor_v12 con todo lo suyo")
	hechos.append("S apagado: gorthor3d de siempre; encendido: gorthor_v12, «jefe», fases y último aliento (vida %d, ataque %d)" % [
		g["hp_max"], g["atk"]])
	c.estado = "fin"
	await _cerrar()


# ================================================================= A

func _a() -> void:
	var Extra = load("res://equipo_extra.gd")
	var lista: Array = Inv.datos()["equipables"]
	lista.erase("fauces_gorthor")
	await _combate({"Kael": 9, "Lya": 9, "Garon": 9}, _semilla("A", 5), true)
	var g := _gorthor()
	g["hp_max"] = int(g["hp_max"] * 1.5)
	g["hp"] = g["hp_max"]
	grabando = fotos != ""                                  # (con fotos: el combate entero, para su vídeo)
	_marca_video("A_combate")
	var r := await _jugar("jugador", "acabar")
	grabando = false
	_ok(r["fin"] and r["gana"], "A: no gana con estrategia (fin %s, acciones %s)" % [r["fin"], str(r["acciones"])])
	await _esperar(200)
	var cont := _cont(g)
	_ok(int(cont.get("son_rugido", 0)) >= 2, "A: el rugido no suena en la entrada y en la Furia (%d)" % int(cont.get("son_rugido", 0)))
	_ok(int(cont.get("son_rodillas", 0)) == 1, "A: las rodillas no suenan una vez (%d)" % int(cont.get("son_rodillas", 0)))
	_ok(sonidos.filter(func(s): return s[0] == "gorthor_rodillas").size() == 1, "A: «gorthor_rodillas» no suena una vez")
	var devora: int = sonidos.filter(func(s): return s[0] == "gorthor_trago").size()
	_ok(devora == int(cont.get("son_trago", 0)), "A: el trago no suena con cada Devorar")
	_ok(Inv.datos()["equipables"].count("fauces_gorthor") == 1, "A: las Fauces de Gorthor no llegan una vez")
	hechos.append("A jugador (nivel 9, vida ×1,5) gana con «Acabar»: %s; Hogueras apagadas %d, cortadas %d; Devorar %d; rugidos %d" % [
		",".join(r["acciones"]), int(cont.get("apagada", 0)), int(cont.get("cortada", 0)), devora, int(cont.get("son_rugido", 0))])
	await _cerrar()


# ================================================================= B

func _b() -> void:
	await _combate({"Kael": 7, "Lya": 7, "Garon": 7}, 9, true)
	await _esperar(90)
	c.estado = "fin"
	grabando = fotos != ""
	var g := _gorthor()
	g["hp_max"] = 4000
	g["hp"] = 4000
	g["ultimo_aliento"] = false
	var p = c._p3d(g)
	var kael: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var lya: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	var garon: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Garon")[0]
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var cura := func():
		for h in c.heroes:
			h["hp"] = h["hp_max"]
			h["defendiendo"] = false
			h.erase("guardia_de")
		g["gt_aturdido"] = false
	# sin fase 2, nunca la prepara
	var n_av := 0
	for s in 30:
		seed(100 + s)
		g["gt_turno"] = 100 + s * 10
		if await _turno_sin_atacar(g, vivos):
			n_av += 1
	_ok(n_av == 0, "B: sin la fase 2 prepara la Hoguera %d veces" % n_av)
	g["fase2"] = true
	n_av = 0
	for s in 30:                                          # (en la fase 2, alguna vez: un 30 % por turno)
		seed(200 + s)
		g["gt_turno"] = 1000 + s * 10
		if await _turno_sin_atacar(g, vivos):
			n_av += 1
	_ok(n_av >= 3 and n_av <= 20, "B: en la fase 2 prepara la Hoguera %d veces de 30" % n_av)
	hechos.append("B en la fase 2 prepara la Hoguera %d de 30 turnos (sin ella, 0)" % n_av)
	# apagada con Agua (no con Fuego)
	cura.call()
	_marca_video("B_hoguera_apagada")
	await GT._avisar(c, g, vivos)
	await _esperar(20)
	_ok(p.clip_actual() in ["hoguera_carga", "hoguera_espera"], "B: el aviso no clava la cuchilla (%s)" % p.clip_actual())
	c.magia_sel = "Fuego"
	await c._animar_golpe(lya, g, 20, "Fuego")
	_ok(g.get("gt_hoguera", false), "B: el Fuego apaga la Hoguera")
	c.magia_sel = "Agua"
	await c._animar_golpe(lya, g, 20, "Agua")
	_ok(not g.get("gt_hoguera", false) and g.get("gt_aturdido", false), "B: el Agua no apaga la Hoguera")
	await _esperar(40)
	_ok(p.clip_actual() == "aturdido", "B: apagada no se tambalea (%s)" % p.clip_actual())
	_ok(sonidos.filter(func(s): return s[0] == "gorthor_apagada").size() == 1, "B: «apagada» no suena una vez")
	var hp0 := {}
	for h in c.heroes:
		hp0[h["nombre"]] = h["hp"]
	var suyo: bool = await GT.turno(c, g, vivos, 1.0)
	_ok(suyo and c.heroes.all(func(h): return h["hp"] == hp0[h["nombre"]]) and not g.get("gt_aturdido", false),
		"B: aturdido no pierde el turno")
	# cortada por Quiebra y por daño
	_marca_video("B_hoguera_cortada")
	await GT._avisar(c, g, vivos)
	c.golpe_ruptura = true
	await c._animar_golpe(kael, g, 10, "")
	c.golpe_ruptura = false
	_ok(g.get("gt_aturdido", false), "B: Quiebra no corta la Hoguera")
	await GT.turno(c, g, vivos, 1.0)
	await GT._avisar(c, g, vivos)
	await c._animar_golpe(kael, g, int(ceil(g["hp_max"] * C.UMBRAL_INTERRUPCION)) + 5, "")
	_ok(g.get("gt_aturdido", false), "B: un cuarto de su vida no corta la Hoguera")
	await GT.turno(c, g, vivos, 1.0)
	# entera: sin defender, defendiendo y con la Guardia de Garon
	var tot := {}
	for caso in ["sin", "defiende", "guardia"]:
		cura.call()
		_marca_video("B_hoguera_" + caso)
		await GT._avisar(c, g, vivos)
		if caso == "defiende":
			for h in c.heroes:
				h["defendiendo"] = true
		if caso == "guardia":
			lya["guardia_de"] = "Garon"
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		var n_imp := impactos.size()
		var n_dn := danos.size()
		seed(80)
		await GT.turno(c, g, vivos, 1.0)
		_ok(impactos.size() == n_imp + 1, "B hoguera %s: impactos %d" % [caso, impactos.size() - n_imp])
		var fr := {}
		for d in danos.slice(n_dn):
			fr[d[1]] = true
		_ok(fr.size() == 1, "B hoguera %s: el daño cae en fotogramas distintos %s" % [caso, str(fr.keys())])
		var q := {}
		var suma := 0
		for h in c.heroes:
			q[h["nombre"]] = antes[h["nombre"]] - h["hp"]
			suma += q[h["nombre"]]
		tot[caso] = q
		if caso == "guardia":
			_ok(q["Lya"] == 0 and q["Garon"] > 0, "B hoguera con Guardia: Lya %d, Garon %d" % [q["Lya"], q["Garon"]])
		else:
			_ok(c.heroes.all(func(h): return q[h["nombre"]] > 0), "B hoguera %s: no alcanza a todos (%s)" % [caso, str(q)])
		await _esperar(30)
	_ok(tot["defiende"]["Kael"] <= tot["sin"]["Kael"] * 0.6 + 1, "B: defender no deja la Hoguera a la mitad (%s / %s)" % [str(tot["defiende"]), str(tot["sin"])])
	# herida fuerte y ligera
	await _esperar(40)
	c._golpe_visual(g, c._quitar_pv(g, int(g["hp_max"] * 0.2)), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe_fuerte", "B: un golpe grande no pone la herida fuerte (%s)" % p.clip_actual())
	await _esperar(60)
	c._golpe_visual(g, c._quitar_pv(g, 5), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe", "B: un golpe pequeño no pone la herida de siempre (%s)" % p.clip_actual())
	hechos.append("B Hoguera sin defender %s, defendiendo %s, con Guardia %s; apagada con Agua (no con Fuego), cortada por Quiebra y por daño; herida fuerte" % [
		str(tot["sin"]), str(tot["defiende"]), str(tot["guardia"])])
	await _esperar(40)
	grabando = false
	c.estado = "fin"
	await _cerrar()


# El turno suyo sin ejecutar lo de siempre: true si preparó la Hoguera.
func _turno_sin_atacar(g: Dictionary, vivos: Array) -> bool:
	g["gt_hoguera"] = false
	var suyo: bool = await GT.turno(c, g, vivos, 1.0)
	var r: bool = suyo and g.get("gt_hoguera", false)
	g["gt_hoguera"] = false
	GT.repasar(g)
	c._marcar_aviso(g, false)
	return r


# ================================================================= C, E

func _c() -> void:
	await _combate({"Kael": 8, "Lya": 8}, _semilla("C", 13), true)
	var r := await _jugar("auto", "perdonar")
	_ok(r["fin"], "C dos héroes: no termina (%s)" % str(r["acciones"]))
	hechos.append("C Kael y Lya (nivel 8), automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()
	await _combate({"Kael": 9}, _semilla("C", 13) + 8, true)
	r = await _jugar("auto", "perdonar")
	_ok(r["fin"], "C Kael solo: no termina (%s)" % str(r["acciones"]))
	hechos.append("C Kael solo (nivel 9), automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()


func _e() -> void:
	var lista: Array = Inv.datos()["equipables"]
	lista.erase("fauces_gorthor")
	await _combate({"Kael": 1, "Lya": 1}, _semilla("E", 3), true)
	var g := _gorthor()
	g["atk"] = 120
	var r := await _jugar("auto", "perdonar", false)
	_ok(r["fin"] and not r["gana"], "E: con nivel 1 no pierde o no acaba (%s)" % str(r["acciones"]))
	await _esperar(120)
	_ok(not Inv.datos()["equipables"].has("fauces_gorthor"), "E: perdiendo da las Fauces")
	hechos.append("E derrota: %s" % ",".join(r["acciones"]))
	await _cerrar()


# ================================================================= Q

func _q() -> void:
	var res := {}
	for niveles in [{"Kael": 7, "Lya": 7, "Garon": 7}, {"Kael": 9, "Lya": 9, "Garon": 9}]:
		for encendido in [false, true]:
			var gana := 0
			var perdidos := 0
			var turnos := 0
			var hogueras := 0
			for s in 6:
				await _combate(niveles, _semilla("Q", 800) + s, encendido, "")
				var pv0 := 0
				for h in c.heroes:
					pv0 += int(h["hp_max"])
				var r := await _jugar("auto", "perdonar", false)
				gana += 1 if r["gana"] else 0
				perdidos += pv0 - int(r.get("pv_fin", 0))
				turnos += c.turnos_heroe
				hogueras += r["acciones"].count("hoguera")
				await _cerrar()
			var k := "%s %s" % ["nuevo" if encendido else "antes", str(niveles.values())]
			res[k] = [gana, perdidos / 6, turnos / 6]
			hechos.append("Q %s: gana %d/6, PV perdidos de media %d, turnos de héroe %d, Hogueras %d" % [k, gana, perdidos / 6, turnos / 6, hogueras])
	for niv in ["[7, 7, 7]", "[9, 9, 9]"]:
		var a: Array = res["antes " + niv]
		var n: Array = res["nuevo " + niv]
		_ok(n[0] >= a[0] - 1, "Q %s: el nuevo gana %d/6 y el de siempre %d/6" % [niv, n[0], a[0]])
		_ok(n[1] <= a[1] * 1.35 + 30, "Q %s: con el nuevo se pierden %d PV de media y con el de siempre %d" % [niv, n[1], a[1]])


# ================================================================= vídeo

func _marca_video(nombre: String) -> void:
	if fotos != "":
		indice.append("%s %d" % [nombre, n_foto])


func _grabar() -> void:
	if Engine.get_process_frames() % 2 != 0:
		return
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		return
	img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	img.save_jpg(fotos.path_join("f_%05d.jpg" % n_foto), 0.85)
	n_foto += 1
