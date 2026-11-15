extends SceneTree
# V12, enemigos (12/11/2026): el Gólem de ámbar, «el Guardián del Nido», en combates de verdad (combate_golem.gd, sus
# ganchos de combate.gd y sonido.gd y enemigos/golem_ambar/golem_ambar_v2.glb). Sin ventana, con datos aislados; la
# partida apunta a su propio archivo y los combates no guardan.
#   U. Sin escena: interruptor «enemigos_v12» apagado por defecto y fuera de la partida; apagado, preparar() no cambia
#      nada; sus grupos de prueba (20 y 21) no salen al azar; sus 8 claves de sonido (QOA mono 48 kHz, < 2,5 s, con su
#      fila de procedencia); el modelo v2 con los clips de antes iguales y los dos nuevos con sus instantes.
#   S. Apagado, en escena: el Gólem del nido (GRUPOS[6]) es el de siempre («bruto», dibujo 2D); encendido, el suyo.
#   A. Kael, Lya y Garon (nivel 4; al Gólem se le triplica la vida solo aquí, para ver muchos turnos) contra él solo,
#      con estrategia de jugador (defender el Pisotón, golpear fuerte mientras carga, Garon cubre a Lya, curar). En
#      cada turno suyo: Puñetazo y Pisotón, un impacto y todo el daño en ese fotograma (±1) y el golpe de siempre una
#      vez; el Terrón, el sonido al soltar (su «impacto») y el daño AL LLEGAR (entre 6 y 16 fotogramas después), con
#      su sonido de llegada en ese fotograma y el golpe una vez, y sin moverse de su sitio; el aviso sin daño, con su
#      señal y su sonido; tras el Pisotón, un turno sin atacar. Gana; su derrumbe suena una vez.
#   B. Controlado: Pisotón cortado por daño y por Quiebra (aturdido, pierde el turno, la rotura suena una vez);
#      Defender deja el Pisotón y el Terrón a la mitad; la Guardia de Garon se lleva el Terrón; herida fuerte y ligera.
#   C. Kael y Lya contra él y un Slime; Kael solo contra él: automáticos, terminan.
#   D. El nido de la Garganta (GRUPOS[6], con Grimfang) con tres héroes, automático: termina.
#   E. Derrota (sin premio) y huida.
#   Q. Equilibrio frente al Gólem de siempre (GRUPOS[6], 6 semillas, solo ataques automáticos).
# Con «fotos=<carpeta>» (y ventana) guarda fotogramas (JPG, uno de cada dos) del B para los vídeos (indice.txt).

const ARCHIVO := "user://prueba_golem_v12.save"
const MAX_FOTOGRAMAS := 16000
const CLAVES_SONIDO := ["golem_ambar_entrada", "golem_ambar_lanzar", "golem_ambar_golpe", "golem_terron", "golem_agarra",
	"golem_carga", "golem_rota", "golem_derrumbe"]
var GO
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
	GO = load("res://combate_golem.gd")
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
			GO.INTERRUPTOR]:
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
	for p in ["S", "A", "B", "C", "D", "E", "Q"]:
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
	_ok(not GO.ACTIVO_POR_DEFECTO and not GO.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not GO.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "golem_ambar", "personalidad": "bruto"}
	GO.preparar(e)
	_ok(e["personalidad"] == "bruto" and not GO.es(e), "U: apagado, preparar() cambia al Gólem")
	Engine.set_meta(GO.INTERRUPTOR, true)
	GO.preparar(e)
	var g := {"clave": "guardian", "personalidad": "jefe"}
	GO.preparar(g)
	_ok(GO.es(e) and not GO.es(g), "U: encendido, preparar() no pone «golem_nido» solo al Gólem")
	Engine.remove_meta(GO.INTERRUPTOR)
	for i in [GO.GRUPO_SOLO, GO.GRUPO_CON_SLIME]:
		_ok(C.GRUPOS[i][0][0] == GO.CLAVE, "U: GRUPOS[%d] no empieza por el Gólem" % i)
	for n in [1, 2, 3]:
		for s in 300:
			seed(s)
			var i: int = C.grupo_al_azar(n)
			_ok(not i in [GO.GRUPO_SOLO, GO.GRUPO_CON_SLIME], "U: sus grupos de prueba salen al azar (%d héroes)" % n)
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
	for k in GO.SONIDOS.values():
		_ok(Son.EFECTOS.has(k), "U: combate_golem.gd pide «%s», que no existe" % k)
	_ok(Son.familia({"hero": false, "clave": "golem_ambar"}) == "ambar", "U: su voz ya no es la de ámbar")
	var v1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/golem_ambar/golem_ambar_clips.json"))
	var v2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/golem_ambar/golem_ambar_v2_clips.json"))
	_ok(int(v1["triangulos"]) == int(v2["triangulos"]) and int(v1["huesos"]) == int(v2["huesos"]), "U: el v2 cambia la malla")
	for clip in v1["clips"]:
		_ok(v2["clips"].has(clip) and v2["clips"][clip] == v1["clips"][clip], "U: el clip «%s» cambia en el v2" % clip)
	var p = load("res://enemigos/golem_ambar/golem_ambar_3d.gd").new()
	root.add_child(p)
	_ok(p.ruta_glb.ends_with("_v2.glb") and p.es_v2(), "U: el guion no carga el v2")
	for clip in ["lanzar", "recibir_golpe_fuerte"]:
		_ok(p.tiene(clip), "U: el v2 no tiene «%s»" % clip)
		if p.tiene(clip):
			_ok(absf(p.duracion(clip) - float(v2["clips"][clip]["duracion"])) < 0.04, "U: «%s» dura %.2f" % [clip, p.duracion(clip)])
			for k in v2["clips"][clip]["eventos"]:
				_ok(absf(p.instante(clip, k) - float(v2["clips"][clip]["eventos"][k])) < 0.002, "U: «%s» sin su instante %s" % [clip, k])
	p.queue_free()
	hechos.append("U interruptor, grupos, 8 sonidos con procedencia, modelo v2 (clips de antes iguales y 2 nuevos)")


# ================================================================= un combate

func _combate(activos: Dictionary, grupo: int, semilla: int, encendido := true) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "garganta")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	if encendido:
		Engine.set_meta(GO.INTERRUPTOR, true)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)                                     # (aquí su _ready hace randomize())
	# 15/11: la semilla, DESPUÉS de add_child (antes se ponía antes y combate._ready la deshacía con randomize(): A, C,
	# D, E y Q eran combates al azar; Q falló una vez el 14/11 por eso), y el ATB inicial de los enemigos otra vez con
	# ella, como prueba_combate_huella.gd.
	seed(semilla)
	for e in c.enemigos:
		e["atb"] = randf() * 30.0
	print("SEMILLA %d · %s · grupo %d · %s" % [semilla, str(activos), grupo, "encendido" if encendido else "apagado"])
	for e in c.enemigos:
		var p = c._p3d(e)
		if GO.es(e):
			_ok(p != null and p.has_method("lanzar") and p.es_v2(), "%s: no tiene su modelo v2" % e["nombre"])
			if p != null:
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
		c.queue_free()
		c = null
	await _esperar(75)                                    # 2,5 s de juego a 30 fotogramas por segundo
	# (el audio sin ventana avanza con el reloj real: si aún suena algo suyo, se le dan hasta 5 s reales para acabar)
	var t0 := Time.get_ticks_msec()
	while _suena_suyo() and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	_ok(not _suena_suyo(), "al cerrar el combate sigue sonando algo del Gólem")
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


func _golem() -> Dictionary:
	for e in c.enemigos:
		if GO.es(e):
			return e
	return {}


func _cont(e: Dictionary) -> Dictionary:
	return (e.get("gn_contador", {}) as Dictionary).duplicate()


func _golpes_sonados() -> int:
	if S == null:
		return 0
	return int(S.contador.get("golpe", 0)) + int(S.contador.get("golpe_defendido", 0)) + int(S.contador.get("golpe_critico", 0))


func _foto_estado() -> Dictionary:
	var hp := {}
	var defiende := {}
	for h in c.heroes:
		hp[h["nombre"]] = h["hp"]
		defiende[h["nombre"]] = h.get("defendiendo", false)
	var z := _golem()
	return {"hp": hp, "defiende": defiende, "cont": _cont(z), "sonidos": sonidos.size(), "impactos": impactos.size(),
		"danos": danos.size(), "golpes": _golpes_sonados(), "turnos_heroe": c.turnos_heroe,
		"rig": z["rig"].position if z.has("rig") else Vector2.ZERO}


func _jugar(estrategia: String, comprobar := true) -> Dictionary:
	var r := {"acciones": [], "gana": false, "fin": false, "cortados": 0}
	var quien = null
	var ant := {}
	var previo := _foto_estado()
	var f_fin := -1
	var decidido := -1
	var ultimo := []
	var rig_min := INF                                    # lo que se mueve su rig en el turno (el Terrón: nada)
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		var actual = c.atacante_actual
		var cerrado := false
		if quien != null and GO.es(quien) and quien.has("rig"):
			rig_min = minf(rig_min, -quien["rig"].position.distance_to(ant.get("rig", quien["rig"].position)))
		if quien != null and not is_same(actual, quien):
			if GO.es(quien):
				var que := _que_hizo(quien, ant)
				r["acciones"].append(que)
				if comprobar:
					_comprobar_turno(quien, que, ant, ultimo, -rig_min)
				ultimo = [que, c.turnos_heroe]
			quien = null
			cerrado = true
		if actual != null and quien == null:
			quien = actual
			ant = _foto_estado() if cerrado else previo
			rig_min = 0.0
		if c.atacante_actual == null:
			previo = _foto_estado()
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_decidir(estrategia)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
			r["pv_fin"] = 0
			for h in c.heroes:
				r["pv_fin"] += maxi(0, int(h["hp"]))
		if f_fin >= 0 and fr - f_fin > 150:
			break
	r["fin"] = c.estado == "fin"
	r["gana"] = c.enemigos.all(func(e): return e["hp"] <= 0) and c.heroes.any(func(h): return h["hp"] > 0)
	r["cortados"] = int(_cont(_golem()).get("pisoton_cortado", 0))
	return r


func _que_hizo(e: Dictionary, ant: Dictionary) -> String:
	var antes: Dictionary = ant["cont"]
	var ahora := _cont(e)
	for k in ["recupera", "pisoton", "aviso_pisoton", "terron", "puno"]:
		if int(ahora.get(k, 0)) > int(antes.get(k, 0)):
			return k
	return "otro"


func _comprobar_turno(e: Dictionary, que: String, ant: Dictionary, ultimo: Array, movido: float) -> void:
	var dn: Array = danos.slice(ant["danos"])
	var golpeados := {}
	for d in dn:
		golpeados[d[0]] = int(golpeados.get(d[0], 0)) + int(d[2])
	var imp: Array = impactos.slice(ant["impactos"])
	var son: Array = sonidos.slice(ant["sonidos"])
	var cuenta := func(n: String) -> Array: return son.filter(func(s): return s[0] == n)
	var golpes: int = _golpes_sonados() - int(ant["golpes"])
	var n := "%s (%s)" % [e["nombre"], que]
	var vivos_antes: Array = ant["hp"].keys().filter(func(k): return int(ant["hp"][k]) > 0)
	match que:
		"puno", "pisoton":
			var clip: String = {"puno": "ataque", "pisoton": "golpe_fuerte"}[que]
			_ok(imp.size() == 1 and imp[0][0] == clip, "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			if imp.size() == 1:
				for d in dn:
					_ok(absi(int(d[1]) - int(imp[0][1])) <= 1, "%s: %s recibe daño en el %d y el impacto es en el %d" % [n, d[0], d[1], imp[0][1]])
			if que == "puno":
				_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
			else:
				_ok(golpeados.size() == vivos_antes.size() or c.cubiertos > 0, "%s: alcanza a %s de %s" % [n, str(golpeados), str(vivos_antes)])
				var s: Array = cuenta.call("golem_ambar_golpe")
				_ok(s.size() == 1 and imp.size() == 1 and absi(int(s[0][1]) - int(imp[0][1])) <= 1, "%s: el Pisotón no suena una vez en el impacto (%s)" % [n, str(s)])
				_ok(ultimo.size() == 2 and ultimo[0] == "aviso_pisoton", "%s: pisa sin aviso (%s)" % [n, str(ultimo)])
				if ultimo.size() == 2:
					_ok(int(ant["turnos_heroe"]) > int(ultimo[1]), "%s: sin un turno de héroe entre el aviso y el golpe" % n)
				_ok(e["hp"] <= 0 or e.get("recupera", false), "%s: tras el Pisotón no queda sin aliento" % n)
		"terron":
			_ok(imp.size() == 1 and imp[0][0] == "lanzar", "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
			_ok(movido < 2.0, "%s: se mueve %.1f px (lanza desde su sitio)" % [n, movido])
			var sl: Array = cuenta.call("golem_ambar_lanzar")
			var st: Array = cuenta.call("golem_terron")
			_ok(sl.size() == 1 and imp.size() == 1 and absi(int(sl[0][1]) - int(imp[0][1])) <= 1, "%s: el lanzamiento no suena al soltar (%s)" % [n, str(sl)])
			_ok(cuenta.call("golem_agarra").size() == 1, "%s: el agarre no suena una vez" % n)
			_ok(st.size() == 1, "%s: la llegada suena %d veces" % [n, st.size()])
			if imp.size() == 1 and not dn.is_empty():
				var vuelo: int = int(dn[0][1]) - int(imp[0][1])
				_ok(vuelo >= 6 and vuelo <= 16, "%s: el daño cae %d fotogramas después de soltar (debe ser el vuelo)" % [n, vuelo])
				if st.size() == 1:
					_ok(absi(int(st[0][1]) - int(dn[0][1])) <= 1, "%s: la llegada no suena con el daño" % n)
		"aviso_pisoton":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño al avisar" % n)
			_ok(cuenta.call("golem_carga").size() == 1, "%s: el aviso no suena una vez" % n)
			if e["hp"] > 0 and e.get("cargando", false):
				_ok(e.has("aviso_nodo"), "%s: sin la señal de aviso sobre él" % n)
		"recupera":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: sin aliento y hace daño" % n)
		_:
			_ok(e["hp"] <= 0, "%s: hizo algo desconocido" % n)


func _decidir(estrategia: String) -> void:
	var a: Dictionary = c.actor
	var alc: Array = c._alcanzables()
	if alc.is_empty():
		c._defender()
		return
	if estrategia == "auto":
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(alc[0])
		return
	var z := _golem()
	var t: Dictionary = z if not z.is_empty() and z["hp"] > 0 else alc[0]
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.45)
		if not heridos.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Cura"][0]["coste"]):
			c._elegir_hechizo("Cura", 1, true)
			return
		if z.get("cargando", false) and c._puede_pagar(c.NIVELES_MAGIA["Agua"][0]["coste"]):
			c._elegir_hechizo("Agua", 1)                       # (el Rayo no le hace nada: inmune)
			c._confirmar_objetivo(t)
			return
		if z.get("cargando", false):
			c._defender()
			return
	if a["nombre"] == "Garon" and not z.get("cargando", false) and a["mp"] >= c.GUARDIA["coste"]:
		var lya = c.heroes.filter(func(h): return h["nombre"] == "Lya" and h["hp"] > 0)
		if not lya.is_empty() and str(lya[0].get("guardia_de", "")) == "":
			c._guardia(lya[0])                               # el Terrón va a la retaguardia: Garon cubre a Lya
			return
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(t)


# ================================================================= S

func _s() -> void:
	await _combate({"Kael": 4, "Lya": 4, "Garon": 4}, 6, 3, false)
	var z: Dictionary = c.enemigos.filter(func(e): return e["clave"] == "golem_ambar")[0]
	_ok(z["personalidad"] == "bruto" and z["modelo"] == "guardian" and not GO.es(z),
		"S: apagado, el Gólem del nido no es el de siempre (%s, %s)" % [z["personalidad"], z["modelo"]])
	c.estado = "fin"
	await _cerrar()
	await _combate({"Kael": 4, "Lya": 4, "Garon": 4}, 6, 3, true)
	z = c.enemigos.filter(func(e): return e["clave"] == "golem_ambar")[0]
	_ok(GO.es(z) and z["modelo"] == "golem_ambar3d" and c._p3d(z) != null, "S: encendido, no es el suyo con su modelo")
	hechos.append("S apagado: «bruto» con su dibujo; encendido: «golem_nido» con golem_ambar3d (vida %d, ataque %d tras el escalado)" % [
		z["hp_max"], z["atk"]])
	c.estado = "fin"
	await _cerrar()


# ================================================================= A

func _a() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 4, "Lya": 4, "Garon": 4}, GO.GRUPO_SOLO, 5)
	var z := _golem()
	_ok(not z.is_empty() and c.enemigos.size() == 1, "A: el grupo 20 no es el Gólem solo")
	z["hp_max"] *= 3
	z["hp"] = z["hp_max"]
	var r := await _jugar("jugador")
	_ok(r["fin"] and r["gana"], "A: no gana con estrategia (fin %s, acciones %s)" % [r["fin"], str(r["acciones"])])
	_ok(r["acciones"].size() >= 4, "A: el combate es demasiado corto: %s" % str(r["acciones"]))
	await _esperar(200)
	_ok(Inv.oro() >= oro0 + int(z["oro"]), "A: las monedas no llegan (%d → %d)" % [oro0, Inv.oro()])
	var der: Array = sonidos.filter(func(s): return s[0] == "golem_derrumbe")
	_ok(der.size() == 1, "A: su derrumbe suena %d veces" % der.size())
	var guardado := JSON.stringify(P.volcar())
	_ok(not guardado.contains("gn_") and not guardado.contains(GO.INTERRUPTOR), "A: la partida guardaría claves suyas")
	hechos.append("A jugador (nivel 4) gana: %s; Pisotones cortados %d, cubiertos %d, turnos de héroe %d" % [
		",".join(r["acciones"]), r["cortados"], c.cubiertos, c.turnos_heroe])
	await _cerrar()


# ================================================================= B

func _b() -> void:
	await _combate({"Kael": 4, "Lya": 4, "Garon": 4}, GO.GRUPO_SOLO, 9)
	await _esperar(80)
	c.estado = "fin"
	grabando = fotos != ""
	var z := _golem()
	z["hp_max"] = 2000
	z["hp"] = 2000
	var p = c._p3d(z)
	var kael: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var lya: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	var garon: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Garon")[0]
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var cura := func():
		for h in c.heroes:
			h["hp"] = h["hp_max"]
			h["defendiendo"] = false
			h.erase("guardia_de")
		z["recupera"] = false
		z["gn_aturdido"] = false
	_marca_video("B_puno")
	cura.call()
	await GO._puno(c, z, vivos, 1.0)
	await _esperar(20)
	# el Terrón: sin defender, defendiendo y con la Guardia de Garon
	var d := {}
	for caso in ["sin", "defiende", "guardia"]:
		cura.call()
		_marca_video("B_terron_" + caso)
		lya["curo"] = true                                  # (va a la curandera)
		if caso == "defiende":
			lya["defendiendo"] = true
		if caso == "guardia":
			lya["guardia_de"] = "Garon"
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		seed(60)
		await GO._terron(c, z, vivos, 1.0)
		var quien := "Garon" if caso == "guardia" else "Lya"
		d[caso] = antes[quien] - (garon if caso == "guardia" else lya)["hp"]
		var otros: Array = c.heroes.filter(func(h): return h["nombre"] != quien and antes[h["nombre"]] != h["hp"])
		_ok(otros.is_empty(), "B terrón %s: alcanza a otros" % caso)
		await _esperar(20)
	lya.erase("curo")
	_ok(d["defiende"] <= d["sin"] * 0.6 + 1, "B: defender no deja el Terrón a la mitad (%d frente a %d)" % [d["defiende"], d["sin"]])
	_ok(d["guardia"] > 0, "B: con la Guardia, Garon no se lleva el Terrón")
	# el Pisotón: aviso, cortado por daño y por Quiebra; y entero, sin defender y defendiendo
	cura.call()
	_marca_video("B_pisoton_cortado")
	await GO._avisar(c, z)
	_ok(z.get("cargando", false) and p.clip_actual() in ["carga", "carga_espera"], "B: el aviso no deja la carga (%s)" % p.clip_actual())
	await c._animar_golpe(kael, z, int(ceil(z["hp_max"] * C.UMBRAL_INTERRUPCION)) + 5, "")
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: un cuarto de su vida no corta el Pisotón")
	await _esperar(40)
	_ok(p.clip_actual() == "aturdido", "B: cortado no se tambalea (%s)" % p.clip_actual())
	var hp0 := {}
	for h in c.heroes:
		hp0[h["nombre"]] = h["hp"]
	await GO.turno(c, z, vivos, 1.0)
	_ok(c.heroes.all(func(h): return h["hp"] == hp0[h["nombre"]]) and not z.get("recupera", false), "B: aturdido no pierde el turno")
	_ok(sonidos.filter(func(s): return s[0] == "golem_rota").size() == 1, "B: la rotura no suena una vez")
	await GO._avisar(c, z)
	c.golpe_ruptura = true
	await c._animar_golpe(kael, z, 10, "")
	c.golpe_ruptura = false
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: Quiebra no corta el Pisotón")
	await GO.turno(c, z, vivos, 1.0)
	var dp := {}
	for caso in ["sin", "defiende"]:
		cura.call()
		_marca_video("B_pisoton_" + caso)
		await GO._avisar(c, z)
		if caso == "defiende":
			for h in c.heroes:
				h["defendiendo"] = true
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		var n_imp := impactos.size()
		seed(70)
		await GO.turno(c, z, vivos, 1.0)
		_ok(impactos.size() == n_imp + 1, "B pisotón %s: impactos %d" % [caso, impactos.size() - n_imp])
		var tot := 0
		for h in c.heroes:
			_ok(antes[h["nombre"]] > h["hp"], "B pisotón %s: no alcanza a %s" % [caso, h["nombre"]])
			tot += antes[h["nombre"]] - h["hp"]
		dp[caso] = tot
		_ok(z.get("recupera", false), "B pisotón %s: no queda sin aliento" % caso)
		await GO.turno(c, z, vivos, 1.0)                  # (recupera)
		await _esperar(20)
	_ok(dp["defiende"] <= dp["sin"] * 0.6 + 3, "B: defender no deja el Pisotón a la mitad (%d frente a %d)" % [dp["defiende"], dp["sin"]])
	# herida fuerte y ligera
	await _esperar(40)
	c._golpe_visual(z, c._quitar_pv(z, int(z["hp_max"] * 0.2)), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe_fuerte", "B: un golpe grande no pone la herida fuerte (%s)" % p.clip_actual())
	await _esperar(60)
	c._golpe_visual(z, c._quitar_pv(z, 5), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe", "B: un golpe pequeño no pone la herida de siempre (%s)" % p.clip_actual())
	hechos.append("B Terrón %d, defendido %d, con Guardia (a Garon) %d; Pisotón a todos %d, defendiendo %d; cortado por daño y por Quiebra; herida fuerte" % [
		d["sin"], d["defiende"], d["guardia"], dp["sin"], dp["defiende"]])
	await _esperar(40)
	_marca_video("B_derrota")
	c.estado = "esperando"
	z["hp"] = 1
	c._quitar_pv(z, 1)
	c._golpe_visual(z, 1, "")
	await _esperar(150)
	grabando = false
	await _cerrar()


# ================================================================= C, D, E

func _c() -> void:
	await _combate({"Kael": 5, "Lya": 5}, GO.GRUPO_CON_SLIME, 13)
	var r := await _jugar("auto")
	_ok(r["fin"], "C dos héroes: no termina (%s)" % str(r["acciones"]))
	hechos.append("C Kael y Lya (nivel 5) contra él y un Slime, automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()
	await _combate({"Kael": 6}, GO.GRUPO_SOLO, 21)
	r = await _jugar("auto")
	_ok(r["fin"], "C Kael solo: no termina (%s)" % str(r["acciones"]))
	hechos.append("C Kael solo (nivel 6), automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()


func _d() -> void:
	await _combate({"Kael": 5, "Lya": 5, "Garon": 5}, 6, 31)
	_ok(c.enemigos.size() == 2 and GO.es(c.enemigos[0]), "D: GRUPOS[6] no trae al Gólem con Grimfang")
	var r := await _jugar("auto")
	_ok(r["fin"], "D: el nido no termina (%s)" % str(r["acciones"]))
	hechos.append("D GRUPOS[6] (nido, con Grimfang), tres héroes nivel 5, automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()


func _e() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 1, "Lya": 1}, GO.GRUPO_SOLO, 3)
	var fuerte := _golem()
	fuerte["atk"] = 120                                    # (que pierdan seguro: aquí se mira el final, no el equilibrio)
	fuerte["hp_max"] = 4000
	fuerte["hp"] = 4000
	var r := await _jugar("auto", false)
	_ok(r["fin"] and not r["gana"], "E: con nivel 1 no pierde o no acaba (%s)" % str(r["acciones"]))
	await _esperar(120)
	_ok(Inv.oro() <= oro0, "E: perdiendo da monedas")
	hechos.append("E derrota: %s" % ",".join(r["acciones"]))
	await _cerrar()
	await _combate({"Kael": 4, "Lya": 4, "Garon": 4}, GO.GRUPO_SOLO, 4)
	for fr in 3000:
		await _esperar(1)
		if c.estado == "menu" and c.actor is Dictionary:
			c._escapar()
			break
	for fr in 600:
		await _esperar(1)
		if c.estado == "fin":
			break
	_ok(c.estado == "fin", "E: huir no acaba el combate (%s)" % c.estado)
	hechos.append("E huida")
	await _cerrar()


# ================================================================= Q

func _q() -> void:
	var res := {}
	for niveles in [{"Kael": 4, "Lya": 3, "Garon": 3}, {"Kael": 7, "Lya": 7, "Garon": 7}]:
		for encendido in [false, true]:
			var gana := 0
			var perdidos := 0
			var turnos := 0
			for s in 6:
				await _combate(niveles, 6, 700 + s, encendido)
				var pv0 := 0
				for h in c.heroes:
					pv0 += int(h["hp_max"])
				var r := await _jugar("auto", false)
				gana += 1 if r["gana"] else 0
				perdidos += pv0 - int(r.get("pv_fin", 0))
				turnos += c.turnos_heroe
				await _cerrar()
			var k := "%s %s" % ["nuevo" if encendido else "antes", str(niveles.values())]
			res[k] = [gana, perdidos / 6, turnos / 6]
			hechos.append("Q %s: gana %d/6, PV perdidos de media %d, turnos de héroe %d" % [k, gana, perdidos / 6, turnos / 6])
	for niv in ["[4, 3, 3]", "[7, 7, 7]"]:
		var a: Array = res["antes " + niv]
		var n: Array = res["nuevo " + niv]
		_ok(n[0] >= a[0] - 1, "Q %s: el nuevo gana %d/6 y el de siempre %d/6" % [niv, n[0], a[0]])
		_ok(n[1] <= a[1] * 1.35 + 20, "Q %s: con el nuevo se pierden %d PV de media y con el de siempre %d" % [niv, n[1], a[1]])


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
