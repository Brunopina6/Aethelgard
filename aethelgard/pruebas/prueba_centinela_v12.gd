extends SceneTree
# V12, enemigos (12/11/2026): el Guardián de piedra, «el Centinela del Anillo», en combates de verdad
# (combate_centinela.gd, sus ganchos de combate.gd y sonido.gd y enemigos/guardian_piedra/guardian_piedra_v2.glb). Sin
# ventana, con datos aislados; la partida apunta a su propio archivo y los combates no guardan (sin «desde_mapa»).
#   U. Sin escena: el interruptor «enemigos_v12» apagado por defecto y fuera de la partida; apagado, preparar() no cambia
#      nada; sus grupos de prueba (18 y 19) no salen al azar con 1, 2 ni 3 héroes; sus 8 claves de sonido cargan (QOA
#      mono 48 kHz, ni mudas ni saturadas, menos de 2,5 s) y cada archivo tiene su fila de procedencia; lo que pide el
#      módulo existe; el modelo v2 tiene los clips de antes (mismas duraciones) y los nuevos, con sus instantes.
#   S. Apagado, en escena: el Guardián de GRUPOS[4] es el de siempre (dibujo 2D, «jefe»); encendido, el modelo propio
#      y «centinela».
#   A. Kael, Lya y Garon (nivel 6) contra él solo (grupo 18) con una estrategia de jugador (defender el Juicio marcado
#      o cubrir con Garon, magia contra el escudo, golpear fuerte mientras carga, curar). En cada turno suyo se mira qué
#      hizo y que lo hizo bien: un impacto por golpe y el daño en ESE fotograma (también a todos en el barrido y las
#      lascas del Juicio); el sonido propio una vez y en ese fotograma (±1); el golpe de siempre (Sonido.golpe) una vez;
#      el aviso del Juicio sin daño, con su marca, su sonido y un turno de héroe antes del golpe; el escudo sin daño.
#      Gana; experiencia y monedas; su derrumbe suena una vez.
#   B. Controlado (el combate parado): Juicio cortado por daño (un cuarto de su vida) y por Quiebra (aturdido, pierde
#      el turno siguiente); el escudo deja los golpes a la mitad y la magia lo rompe (aturdido); el Juicio contra quien
#      defiende (a la mitad) y con la Guardia de Garon (se lo lleva él); un golpe grande pone el clip de herida fuerte.
#   C. Dos héroes contra él y un Slime (grupo 19) y Kael solo contra él (grupo 18), con ataques automáticos: terminan.
#      Ganar así no prueba la estrategia de un jugador.
#   D. El encuentro de la región con el interruptor (GRUPOS[4], con Grimfang) y tres héroes, automático: termina.
#   E. Derrota (nivel 1): acaba, sin premio. Huida: sale del combate.
#   En todos: al acabar no quedan marcas suyas ni sonidos suyos y no crecen los nodos huérfanos.
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que la semilla se pone DESPUÉS de
# root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos con ella (como prueba_combate_huella.gd). Antes se
# sembraba antes de add_child y A, C, D, E y Q eran combates al azar (el Q, estadístico, podía fallar por suerte). Cada
# combate imprime «SEMILLA» y una línea «TRAZA» por turno (quién y los PV); «semilla_A=N» (o _C, _D, _E, _Q) suma N a
# las semillas de ese caso para reproducir o explorar otras.
# Con «fotos=<carpeta>» (y ventana) guarda un fotograma de cada dos en el combate A y en el B (JPG a media resolución,
# con su índice por ataque en indice.txt) para montar los vídeos con ffmpeg, y capturas sueltas.

const ARCHIVO := "user://prueba_centinela_v12.save"
const MAX_FOTOGRAMAS := 16000
const CLAVES_SONIDO := ["guardian_entrada", "guardian_barrido", "guardian_golpe", "centinela_tension", "centinela_carga",
	"centinela_escudo", "centinela_rota", "centinela_derrumbe"]
var CN                                  # combate_centinela.gd
var C                                   # combate.gd
var P
var G
var Inv
var S                                   # el nodo Sonido
var c = null
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []                 # [nombre, fotograma]
var impactos: Array = []                # [ataque, fotograma]
var danos: Array = []                   # [héroe, fotograma, daño]
var hp_prev := {}
var fotos := ""
var grabando := false
var n_foto := 0
var indice: Array = []
var huerfanos0 := -1
var caso_actual := ""


func _initialize() -> void:
	CN = load("res://combate_centinela.gd")
	C = load("res://combate.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	if fotos != "":                                    # (cada fotograma, también mientras la prueba espera a un ataque)
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
			CN.INTERRUPTOR]:
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
			caso_actual = p
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


# ================================================================= U: sin escena

func _u() -> void:
	_limpiar()
	_ok(not CN.ACTIVO_POR_DEFECTO and not CN.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not CN.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "guardian", "personalidad": "jefe"}
	CN.preparar(e)
	_ok(e["personalidad"] == "jefe" and not CN.es(e), "U: apagado, preparar() cambia al Guardián")
	Engine.set_meta(CN.INTERRUPTOR, true)
	CN.preparar(e)
	var g := {"clave": "grimfang", "personalidad": "agresivo"}
	CN.preparar(g)
	_ok(CN.es(e) and not CN.es(g), "U: encendido, preparar() no pone «centinela» solo al Guardián")
	Engine.remove_meta(CN.INTERRUPTOR)
	for i in [CN.GRUPO_SOLO, CN.GRUPO_CON_SLIME]:
		_ok(C.GRUPOS[i][0][0] == CN.CLAVE, "U: GRUPOS[%d] no empieza por el Guardián" % i)
	for n in [1, 2, 3]:
		for s in 300:
			seed(s)
			var i: int = C.grupo_al_azar(n)
			_ok(not i in [CN.GRUPO_SOLO, CN.GRUPO_CON_SLIME], "U: sus grupos de prueba salen al azar (%d héroes)" % n)
	# sonido
	var Son = load("res://sonido.gd")
	var csv := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../docs/audio/efectos_procedencia.csv"))
	_ok(csv.length() > 1000, "U: no se lee docs/audio/efectos_procedencia.csv")
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
	for k in CN.SONIDOS.values():
		_ok(Son.EFECTOS.has(k), "U: combate_centinela.gd pide «%s», que no existe" % k)
	_ok(Son.familia({"hero": false, "clave": "guardian"}) == "piedra", "U: su voz ya no es la de piedra")
	# el modelo v2: los clips de antes (mismas duraciones) y los nuevos
	var v1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/guardian_piedra/guardian_piedra_clips.json"))
	var v2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/guardian_piedra/guardian_piedra_v2_clips.json"))
	_ok(int(v1["triangulos"]) == int(v2["triangulos"]) and int(v1["huesos"]) == int(v2["huesos"]), "U: el v2 cambia la malla")
	for clip in v1["clips"]:
		_ok(v2["clips"].has(clip) and v2["clips"][clip] == v1["clips"][clip], "U: el clip «%s» cambia en el v2" % clip)
	var p = load("res://enemigos/guardian_piedra/guardian_piedra_3d.gd").new()
	root.add_child(p)
	_ok(p.ruta_glb.ends_with("_v2.glb") and p.es_v2(), "U: el guion no carga el v2")
	for clip in ["barrido", "guardia", "guardia_espera", "aturdido", "recibir_golpe_fuerte"]:
		_ok(p.tiene(clip), "U: el v2 no tiene «%s»" % clip)
		if p.tiene(clip):
			_ok(absf(p.duracion(clip) - float(v2["clips"][clip]["duracion"])) < 0.04, "U: «%s» dura %.2f" % [clip, p.duracion(clip)])
			_ok((p.anim.get_animation(clip).loop_mode == Animation.LOOP_LINEAR) == bool(v2["clips"][clip]["bucle"]),
				"U: «%s» con el bucle cambiado" % clip)
			for k in v2["clips"][clip]["eventos"]:
				_ok(absf(p.instante(clip, k) - float(v2["clips"][clip]["eventos"][k])) < 0.002, "U: «%s» sin su instante %s" % [clip, k])
	p.queue_free()
	hechos.append("U interruptor, grupos, 8 sonidos con procedencia, modelo v2 (clips de antes iguales y 5 nuevos)")


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
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	if encendido:
		Engine.set_meta(CN.INTERRUPTOR, true)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)                                     # (aquí su _ready hace randomize())
	semilla += _desfase(caso_actual)
	seed(semilla)                                         # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                         # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA %d · caso %s · %s · grupo %d · %s · %s" % [semilla, caso_actual, str(activos), grupo,
		"encendido" if encendido else "apagado", ",".join(c.enemigos.map(func(e): return e["nombre"]))])
	for e in c.enemigos:
		var p = c._p3d(e)
		if CN.es(e):
			_ok(p != null and p.has_method("barrido") and p.es_v2(), "%s: no tiene su modelo v2" % e["nombre"])
			if p != null:
				p.impacto.connect(func(a): impactos.append([a, Engine.get_process_frames()]))
	for h in c.heroes:
		hp_prev[h["nombre"]] = h["hp"]


# Una línea por turno: fotograma, quién y los PV de todos (para reproducir una semilla concreta).
func _traza(que: String) -> void:
	var pv := []
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA %05d T%d %s · %s" % [Engine.get_process_frames(), c.turnos_heroe, que, ", ".join(pv)])


# «semilla_A=N» (o _C, _D, _E, _Q) en la línea de órdenes: N se suma a las semillas de ese caso (0, las de siempre).
func _desfase(caso: String) -> int:
	for a in OS.get_cmdline_user_args():
		if caso != "" and a.begins_with("semilla_%s=" % caso):
			return int(a.get_slice("=", 1))
	return 0


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
		_ok(CN.nodos_vivos(c.enemigos).is_empty(), "al acabar quedan nodos suyos: %s" % str(CN.nodos_vivos(c.enemigos)))
		c.queue_free()
		c = null
	await _esperar(75)                                    # 2,5 s de juego a 30 fotogramas por segundo
	# (el audio sin ventana avanza con el reloj real: si aún suena algo suyo, hasta 5 s reales para acabar)
	var t0 := Time.get_ticks_msec()
	while _suena_suyo() and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	_ok(not _suena_suyo(), "al cerrar el combate sigue sonando algo del Centinela")
	await _esperar(5)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(h <= huerfanos0, "al cerrar el combate hay %d nodos huérfanos (antes %d)" % [h, huerfanos0])
	_limpiar()


func _suena_suyo() -> bool:
	if S == null:
		return false
	for p in S._todas():
		var n := str(p.get_meta("efecto", ""))
		if p.playing and (n in CLAVES_SONIDO) and not p.get_meta("apagando", false):
			return true
	return false


func _guardian() -> Dictionary:
	for e in c.enemigos:
		if CN.es(e):
			return e
	return {}


func _cont(e: Dictionary) -> Dictionary:
	return (e.get("cn_contador", {}) as Dictionary).duplicate()


func _golpes_sonados() -> int:
	if S == null:
		return 0
	return int(S.contador.get("golpe", 0)) + int(S.contador.get("golpe_defendido", 0)) + int(S.contador.get("golpe_critico", 0))


func _foto_estado() -> Dictionary:
	var hp := {}
	var defiende := {}
	var cubre := {}
	for h in c.heroes:
		hp[h["nombre"]] = h["hp"]
		defiende[h["nombre"]] = h.get("defendiendo", false)
		cubre[h["nombre"]] = str(h.get("guardia_de", ""))
	var z := _guardian()
	var o = z.get("cn_objetivo", null)
	return {"hp": hp, "defiende": defiende, "cubre": cubre, "cont": _cont(z), "obj": str(o["nombre"]) if o is Dictionary else "",
		"sonidos": sonidos.size(), "impactos": impactos.size(), "danos": danos.size(), "golpes": _golpes_sonados(),
		"turnos_heroe": c.turnos_heroe}


func _jugar(estrategia: String, comprobar := true) -> Dictionary:
	var r := {"acciones": [], "gana": false, "fin": false, "defendidos": 0, "rotos": 0, "cortados": 0}
	var quien = null
	var ant := {}
	var previo := _foto_estado()
	var f_fin := -1
	var decidido := -1
	var ultimo := []                                       # [acción, turnos_heroe] de su turno anterior
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		var actual = c.atacante_actual
		var cerrado := false
		if quien != null and not is_same(actual, quien):
			if CN.es(quien):
				var que := _que_hizo(quien, ant)
				_traza("%s: %s" % [quien["nombre"], que])
				r["acciones"].append(que)
				if comprobar:
					_comprobar_turno(quien, que, ant, ultimo, r)
				ultimo = [que, c.turnos_heroe]
			quien = null
			cerrado = true
		if actual != null and quien == null:
			quien = actual
			ant = _foto_estado() if cerrado else previo
		if c.atacante_actual == null:
			previo = _foto_estado()
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_traza("turno de %s" % c.actor["nombre"])
			_decidir(estrategia, r)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
			r["pv_fin"] = 0                                # (antes del reparto: subir de nivel cura)
			for h in c.heroes:
				r["pv_fin"] += maxi(0, int(h["hp"]))
		if f_fin >= 0 and fr - f_fin > 150:
			break
	var z := _guardian()
	r["fin"] = c.estado == "fin"
	r["gana"] = c.enemigos.all(func(e): return e["hp"] <= 0) and c.heroes.any(func(h): return h["hp"] > 0)
	_traza("fin %s · gana %s" % [r["fin"], r["gana"]])
	r["cortados"] = int(_cont(z).get("juicio_cortado", 0))
	r["rotos"] = int(_cont(z).get("escudo_roto", 0))
	return r


func _que_hizo(e: Dictionary, ant: Dictionary) -> String:
	var antes: Dictionary = ant["cont"]
	var ahora := _cont(e)
	for k in ["recupera", "juicio", "aviso_juicio", "escudo", "barrido", "tajo"]:
		if int(ahora.get(k, 0)) > int(antes.get(k, 0)):
			return k
	return "otro"


func _comprobar_turno(e: Dictionary, que: String, ant: Dictionary, ultimo: Array, r: Dictionary) -> void:
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
		"tajo", "barrido", "juicio":
			var clip: String = {"tajo": "ataque", "barrido": "barrido", "juicio": "golpe_fuerte"}[que]
			_ok(imp.size() == 1 and imp[0][0] == clip, "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			if imp.size() == 1:
				for d in dn:                                   # todo el daño, en el fotograma del impacto
					_ok(absi(int(d[1]) - int(imp[0][1])) <= 1, "%s: %s recibe daño en el fotograma %d y el impacto es en el %d" % [n, d[0], d[1], imp[0][1]])
			if que == "tajo":
				_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
			else:
				_ok(golpeados.size() == vivos_antes.size() or c.cubiertos > 0, "%s: alcanza a %s de %s" % [n, str(golpeados), str(vivos_antes)])
				var k := "guardian_barrido" if que == "barrido" else "guardian_golpe"
				var s: Array = cuenta.call(k)
				_ok(s.size() == 1, "%s: «%s» suena %d veces" % [n, k, s.size()])
				if s.size() == 1 and imp.size() == 1:
					_ok(absi(int(s[0][1]) - int(imp[0][1])) <= 1, "%s: «%s» no cae en el impacto (%d / %d)" % [n, k, s[0][1], imp[0][1]])
			if que == "barrido" and e.has("rig"):
				var t: Array = cuenta.call("centinela_tension")
				_ok(t.size() == 1 and imp.size() == 1 and int(t[0][1]) < int(imp[0][1]),
					"%s: la tensión no suena una vez antes del impacto (%s)" % [n, str(t)])
			if que == "juicio":
				_ok(ultimo.size() == 2 and ultimo[0] == "aviso_juicio", "%s: golpea sin aviso (%s)" % [n, str(ultimo)])
				if ultimo.size() == 2:
					_ok(int(ant["turnos_heroe"]) > int(ultimo[1]), "%s: sin un turno de héroe entre el aviso y el golpe" % n)
				var obj: String = ant["obj"]
				if obj != "" and golpeados.has(obj) and ant["defiende"].get(obj, false):
					r["defendidos"] += 1
				_ok(e.get("cn_marca", null) == null, "%s: la marca sigue tras el golpe" % n)
		"aviso_juicio":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño al avisar: %s" % [n, str(golpeados)])
			_ok(cuenta.call("centinela_carga").size() == 1, "%s: el aviso no suena una vez" % n)
			if e["hp"] > 0 and e.get("cargando", false):
				_ok(e.get("cn_marca", null) != null and is_instance_valid(e["cn_marca"]), "%s: sin marca sobre el héroe" % n)
				_ok(e.has("aviso_nodo"), "%s: sin la señal de aviso sobre él" % n)
		"escudo":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño al alzar el escudo" % n)
			_ok(cuenta.call("centinela_escudo").size() == 1, "%s: el escudo no suena una vez (%d)" % [n, cuenta.call("centinela_escudo").size()])
			_ok(e["hp"] <= 0 or e.get("defendiendo", false) and e.get("cn_escudo", false) or not e.get("cn_escudo", false),
				"%s: el escudo no deja los golpes a la mitad" % n)
		"recupera":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: aturdido y hace daño" % n)
			_ok(ultimo.size() == 2 and (int(_cont(e).get("juicio_cortado", 0)) + int(_cont(e).get("escudo_roto", 0)) > 0),
				"%s: recupera sin haber perdido nada" % n)
		_:
			_ok(e["hp"] <= 0, "%s: hizo algo desconocido" % n)


func _decidir(estrategia: String, r: Dictionary) -> void:
	var a: Dictionary = c.actor
	var alc: Array = c._alcanzables()
	if alc.is_empty():
		c._defender()
		return
	if estrategia == "auto":
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(alc[0])
		return
	var z := _guardian()
	var t: Dictionary = z if not z.is_empty() and z["hp"] > 0 else alc[0]
	var marcado = z.get("cn_objetivo", null) if z.get("cargando", false) else null
	if marcado is Dictionary and is_same(marcado, a):         # el Juicio va a por mí: defender
		c._defender()
		return
	if a["nombre"] == "Garon" and marcado is Dictionary and marcado["hp"] > 0 and a["mp"] >= c.GUARDIA["coste"] \
			and str(marcado.get("guardia_de", "")) == "":
		c._guardia(marcado)                                  # le cubre: el Juicio irá a Garon
		return
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.45)
		if not heridos.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Cura"][0]["coste"]):
			c._elegir_hechizo("Cura", 1, true)
			return
		if (z.get("cn_escudo", false) or z.get("cargando", false)) and c._puede_pagar(c.NIVELES_MAGIA["Fuego"][0]["coste"]):
			c._elegir_hechizo("Fuego", 1)                    # la magia rompe el escudo / ayuda a cortar el Juicio
			c._confirmar_objetivo(t)
			return
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(t)


# ================================================================= S: apagado y encendido en escena

func _s() -> void:
	await _combate({"Kael": 6, "Lya": 6, "Garon": 6}, 4, 3, false)
	var z: Dictionary = c.enemigos.filter(func(e): return e["clave"] == "guardian")[0]
	_ok(z["personalidad"] == "jefe" and z["modelo"] == "guardian" and not CN.es(z) and c._p3d(z) == null,
		"S: apagado, el Guardián de GRUPOS[4] no es el de siempre (%s, %s)" % [z["personalidad"], z["modelo"]])
	c.estado = "fin"
	await _cerrar()
	await _combate({"Kael": 6, "Lya": 6, "Garon": 6}, 4, 3, true)
	z = c.enemigos.filter(func(e): return e["clave"] == "guardian")[0]
	_ok(CN.es(z) and z["modelo"] == "guardian3d" and c._p3d(z) != null, "S: encendido, no es el Centinela con su modelo")
	hechos.append("S apagado: «jefe» con su dibujo; encendido: «centinela» con guardian3d (vida %d, ataque %d tras el escalado)" % [
		z["hp_max"], z["atk"]])
	c.estado = "fin"
	await _cerrar()


# ================================================================= A: estrategia de jugador

func _a() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 3, "Lya": 2, "Garon": 1}, CN.GRUPO_SOLO, 5)
	var z := _guardian()
	_ok(not z.is_empty() and c.enemigos.size() == 1, "A: el grupo 18 no es el Guardián solo")
	z["hp_max"] *= 3                                       # (más vida para ver muchos turnos suyos; el equilibrio, en Q)
	z["hp"] = z["hp_max"]
	var exp0 := {}
	for n in ["Kael", "Lya", "Garon"]:
		exp0[n] = int(G.datos()[n]["exp"])
	grabando = fotos != ""
	_marca_video("A_inicio")
	var r := await _jugar("jugador")
	grabando = false
	_ok(r["fin"] and r["gana"], "A: no gana con estrategia (fin %s, acciones %s)" % [r["fin"], str(r["acciones"])])
	_ok(r["acciones"].size() >= 4, "A: el combate es demasiado corto para mirar nada: %s" % str(r["acciones"]))
	await _esperar(200)
	_ok(Inv.oro() >= oro0 + int(z["oro"]), "A: las monedas no llegan (%d → %d)" % [oro0, Inv.oro()])
	_ok(["Kael", "Lya", "Garon"].any(func(n): return int(G.datos()[n]["exp"]) > int(exp0[n]) or int(G.datos()[n]["nivel"]) > 3),
		"A: nadie gana experiencia")
	var der: Array = sonidos.filter(func(s): return s[0] == "centinela_derrumbe")
	_ok(der.size() == 1, "A: su derrumbe suena %d veces" % der.size())
	var guardado := JSON.stringify(P.volcar())
	_ok(not guardado.contains("cn_") and not guardado.contains(CN.INTERRUPTOR), "A: la partida guardaría claves suyas")
	var hp_fin := {}
	for h in c.heroes:
		hp_fin[h["nombre"]] = "%d/%d" % [h["hp"], h["hp_max"]]
	hechos.append("A jugador (Kael 3, Lya 2, Garon 1) gana: %s; Juicios defendidos %d, cubiertos %d, cortados %d, escudos rotos %d, turnos de héroe %d; PV al final %s" % [
		",".join(r["acciones"]), r["defendidos"], c.cubiertos, r["cortados"], r["rotos"], c.turnos_heroe, str(hp_fin)])
	await _cerrar()


# ================================================================= B: controlado

func _b() -> void:
	await _combate({"Kael": 6, "Lya": 6, "Garon": 6}, CN.GRUPO_SOLO, 9)
	await _esperar(80)
	c.estado = "fin"                                       # parado: sin ATB ni turnos
	grabando = fotos != ""
	var z := _guardian()
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
	# cada ataque, para los vídeos
	for que in ["tajo", "barrido"]:
		cura.call()
		_marca_video("B_" + que)
		seed(40)
		if que == "tajo":
			await CN._tajo(c, z, vivos, 1.0)
		else:
			await CN._barrido(c, z, vivos, 1.0, false)
		await _esperar(30)
	# 1. Juicio cortado por daño
	cura.call()
	_marca_video("B_juicio_cortado")
	await CN._anunciar_juicio(c, z, vivos)
	_ok(z.get("cargando", false) and z.get("cn_marca", null) != null, "B: el aviso no deja la carga y la marca (cargando %s, marca %s, PV %d)" % [
		z.get("cargando", false), z.get("cn_marca", null), z["hp"]])
	_ok(p.clip_actual() in ["carga", "carga_espera"], "B: el aviso no pone la carga (%s)" % p.clip_actual())
	await c._animar_golpe(kael, z, int(ceil(z["hp_max"] * C.UMBRAL_INTERRUPCION)) + 5, "")
	_ok(not z.get("cargando", false) and z.get("recupera", false) and z.get("cn_marca", null) == null, "B: un cuarto de su vida no corta el Juicio")
	_ok(p.clip_actual() in ["aturdido", "recibir_golpe", "recibir_golpe_fuerte"], "B: cortado no se tambalea (%s)" % p.clip_actual())
	await _esperar(40)
	_ok(p.clip_actual() == "aturdido", "B: tras la herida no vuelve al aturdido (%s)" % p.clip_actual())
	var hp0 := {}
	for h in c.heroes:
		hp0[h["nombre"]] = h["hp"]
	await CN.turno(c, z, vivos, 1.0)
	_ok(c.heroes.all(func(h): return h["hp"] == hp0[h["nombre"]]) and not z.get("recupera", false), "B: aturdido no pierde el turno")
	var son_rota := sonidos.filter(func(s): return s[0] == "centinela_rota").size()
	_ok(son_rota == 1, "B: la rotura suena %d veces" % son_rota)
	# 2. Juicio cortado por Quiebra
	await _esperar(20)
	await CN._anunciar_juicio(c, z, vivos)
	c.golpe_ruptura = true
	await c._animar_golpe(kael, z, 10, "")
	c.golpe_ruptura = false
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: Quiebra no corta el Juicio")
	await CN.turno(c, z, vivos, 1.0)
	# 3. el Juicio: sin defender, defendiendo y con la Guardia de Garon
	var d := {}
	for caso in ["sin", "defiende", "guardia"]:
		cura.call()
		await _esperar(10)
		_marca_video("B_juicio_" + caso)
		seed(50)
		await CN._anunciar_juicio(c, z, vivos)
		var obj: Dictionary = z["cn_objetivo"]
		if caso == "guardia" and is_same(obj, garon):
			z["cn_objetivo"] = lya
			obj = lya
		if caso == "defiende":
			obj["defendiendo"] = true
		if caso == "guardia":
			obj["guardia_de"] = "Garon"
			garon["defendiendo"] = true
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		var n_imp := impactos.size()
		seed(51)
		await CN.turno(c, z, vivos, 1.0)
		var quita := {}
		for h in c.heroes:
			quita[h["nombre"]] = antes[h["nombre"]] - h["hp"]
		_ok(impactos.size() == n_imp + 1, "B %s: impactos %d" % [caso, impactos.size() - n_imp])
		var quien := "Garon" if caso == "guardia" else str(obj["nombre"])
		d[caso] = quita[quien]
		for h in c.heroes:                                   # las lascas a los demás
			if h["nombre"] != quien and not (caso == "guardia" and h["nombre"] == obj["nombre"]):
				_ok(quita[h["nombre"]] > 0 and quita[h["nombre"]] < d[caso], "B %s: las lascas a %s: %d" % [caso, h["nombre"], quita[h["nombre"]]])
		if caso == "guardia":
			_ok(quita[obj["nombre"]] == 0, "B guardia: %s recibe %d estando cubierto" % [obj["nombre"], quita[obj["nombre"]]])
		await _esperar(20)
	_ok(d["defiende"] <= d["sin"] * 0.6 + 1, "B: defender no deja el Juicio a la mitad (%d frente a %d)" % [d["defiende"], d["sin"]])
	_ok(d["guardia"] <= d["sin"] * 0.6 + 1, "B: con la Guardia, Garon no recibe la mitad (%d frente a %d)" % [d["guardia"], d["sin"]])
	# 4. el escudo: golpes a la mitad, la magia lo rompe
	cura.call()
	_marca_video("B_escudo")
	await CN._escudo(c, z)
	_ok(z.get("cn_escudo", false) and z.get("defendiendo", false), "B: el escudo no queda puesto")
	await _esperar(30)
	_ok(p.clip_actual() == "guardia_espera", "B: el escudo no se queda en su bucle (%s)" % p.clip_actual())
	var h0: int = z["hp"]
	c.ultimo_esquivado = false
	await c._animar_golpe(kael, z, 40, "")
	_ok(h0 - z["hp"] in [20, 32], "B: con el escudo un golpe de 40 quita %d" % (h0 - z["hp"]))
	_ok(z.get("cn_escudo", false), "B: un golpe físico rompe el escudo")
	_marca_video("B_escudo_roto")
	await c._animar_golpe(lya, z, 30, "Fuego")
	_ok(not z.get("cn_escudo", false) and not z.get("defendiendo", false) and z.get("recupera", false), "B: la magia no rompe el escudo")
	await _esperar(40)
	await CN.turno(c, z, vivos, 1.0)
	# 5. el escudo que nadie rompe: suelta el anillo con un barrido
	cura.call()
	_marca_video("B_escudo_barrido")
	await CN._escudo(c, z)
	var n_imp2 := impactos.size()
	await CN.turno(c, z, vivos, 1.0)
	_ok(impactos.size() == n_imp2 + 1 and impactos[impactos.size() - 1][0] == "barrido" and not z.get("defendiendo", false),
		"B: tras el escudo no barre (%s)" % str(impactos.slice(n_imp2)))
	# 6. golpe grande: herida fuerte; pequeño: la de siempre
	await _esperar(60)
	c._golpe_visual(z, c._quitar_pv(z, int(z["hp_max"] * 0.2)), "")   # (lo que hace un impacto)
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe_fuerte", "B: un golpe grande no pone la herida fuerte (%s)" % p.clip_actual())
	await _esperar(60)
	c._golpe_visual(z, c._quitar_pv(z, 5), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe", "B: un golpe pequeño no pone la herida de siempre (%s)" % p.clip_actual())
	hechos.append("B Juicio %d, defendido %d, Guardia %d; cortado por daño y por Quiebra; escudo ×0,5 y roto por la magia; herida fuerte" % [
		d["sin"], d["defiende"], d["guardia"]])
	# 7. la derrota con su peso
	await _esperar(40)
	_marca_video("B_derrota")
	c.estado = "esperando"
	z["hp"] = 1
	c._quitar_pv(z, 1)
	c._golpe_visual(z, 1, "")
	await _esperar(150)
	grabando = false
	await _cerrar()


# ================================================================= C y D: automáticos

func _c() -> void:
	await _combate({"Kael": 5, "Lya": 5}, CN.GRUPO_CON_SLIME, 13)
	var r := await _jugar("auto")
	_ok(r["fin"], "C dos héroes: no termina (%s)" % str(r["acciones"]))
	hechos.append("C Kael y Lya (nivel 5) contra él y un Slime, automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()
	await _combate({"Kael": 6}, CN.GRUPO_SOLO, 21)
	r = await _jugar("auto")
	_ok(r["fin"], "C Kael solo: no termina (%s)" % str(r["acciones"]))
	hechos.append("C Kael solo (nivel 6), automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()


func _d() -> void:
	await _combate({"Kael": 6, "Lya": 6, "Garon": 6}, 4, 31)
	_ok(c.enemigos.size() == 2 and CN.es(c.enemigos[0]), "D: GRUPOS[4] no trae al Centinela con Grimfang")
	var r := await _jugar("auto")
	_ok(r["fin"], "D: el encuentro de la región no termina (%s)" % str(r["acciones"]))
	hechos.append("D GRUPOS[4] (con Grimfang), tres héroes nivel 6, automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()


# ================================================================= E: derrota y huida

func _e() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 1, "Lya": 1}, CN.GRUPO_SOLO, 3)
	var fuerte := _guardian()
	fuerte["atk"] = 120                                    # (que pierdan seguro: aquí se mira el final, no el equilibrio)
	fuerte["hp_max"] = 4000
	fuerte["hp"] = 4000
	var r := await _jugar("auto", false)
	_ok(r["fin"] and not r["gana"], "E: con nivel 1 no pierde o no acaba (fin %s, gana %s, estado %s, PV %s / %s; %s)" % [r["fin"], r["gana"],
		c.estado, str(c.heroes.map(func(h): return h["hp"])), str(c.enemigos.map(func(e): return e["hp"])), str(r["acciones"])])
	await _esperar(120)
	_ok(Inv.oro() <= oro0, "E: perdiendo da monedas (%d → %d)" % [oro0, Inv.oro()])
	hechos.append("E derrota: %s" % ",".join(r["acciones"]))
	await _cerrar()
	await _combate({"Kael": 6, "Lya": 6, "Garon": 6}, CN.GRUPO_SOLO, 4)
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


# ================================================================= vídeo (con ventana y «fotos=»)

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


# ================================================================= Q: equilibrio frente al Guardián de siempre

# El encuentro de la región (GRUPOS[4], con Grimfang) con el Guardián de siempre (apagado, «jefe») y con el Centinela
# (encendido), mismas semillas, mismos niveles y solo ataques automáticos (el caso pesimista: sin defender, sin magia
# y sin cortar nada). Se mira que el nuevo no sea mucho más duro: victorias y PV perdidos por el grupo.
func _q() -> void:
	var res := {}
	for niveles in [{"Kael": 3, "Lya": 2, "Garon": 1}, {"Kael": 6, "Lya": 6, "Garon": 6}]:
		for encendido in [false, true]:
			var gana := 0
			var perdidos := 0
			var turnos := 0
			for s in 6:
				await _combate(niveles, 4, 600 + s, encendido)
				var pv0 := 0
				for h in c.heroes:
					pv0 += int(h["hp_max"])
				var r := await _jugar("auto", false)
				var pv1: int = int(r.get("pv_fin", 0))
				gana += 1 if r["gana"] else 0
				perdidos += pv0 - pv1
				turnos += c.turnos_heroe
				await _cerrar()
			var k := "%s %s" % ["nuevo" if encendido else "antes", str(niveles.values())]
			res[k] = [gana, perdidos / 6, turnos / 6]
			hechos.append("Q %s: gana %d/6, PV perdidos de media %d, turnos de héroe %d" % [k, gana, perdidos / 6, turnos / 6])
	for niv in ["[3, 2, 1]", "[6, 6, 6]"]:
		var a: Array = res["antes " + niv]
		var n: Array = res["nuevo " + niv]
		_ok(n[0] >= a[0] - 1, "Q %s: el nuevo gana %d/6 y el de siempre %d/6" % [niv, n[0], a[0]])
		_ok(n[1] <= a[1] * 1.35 + 20, "Q %s: con el nuevo se pierden %d PV de media y con el de siempre %d" % [niv, n[1], a[1]])
