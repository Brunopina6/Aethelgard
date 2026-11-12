extends SceneTree
# V12, encuentro del desierto (12/11/2026): Vidracrán en combates de verdad (combate_vidracran.gd y sus ganchos de
# combate.gd, sonido.gd y zonas3d/mar_cristal_3d.gd), sin ventana y con datos aislados. La partida apunta a su propio
# archivo y los combates no guardan (sin «desde_mapa»).
#   U. Sin escena: el interruptor «encuentro_desierto_v12» apagado por defecto; apagado, el Mar de Cristal no cambia
#      (grupo -1 y sin tirar dados) y ningún encuentro de siempre trae a Vidracrán; encendido, solo sus grupos; el
#      caparazón (×0,5), la ventana (×1,5), la magia entera y nada bajo la arena; textos; sus 10 claves de sonido
#      cargan (OGG mono, sin bucle, ni mudas ni saturadas) y su voz es la suya; el material está en el catálogo y el
#      botín de siempre no cambia; lo que se guarda no tiene claves nuevas.
#   A. Kael, Lya y Garon a nivel 10 contra uno (grupo 14) con una estrategia de jugador (defender el aguijón marcado,
#      golpear en la ventana, magia contra el caparazón, curar): en cada turno suyo se mira qué hizo y que lo hizo bien:
#        Pinzas: un impacto, un héroe alcanzado, su sonido una vez en el fotograma del impacto.
#        Enterrarse: ningún daño, bajo la arena (no se le puede apuntar), la marca sobre el héroe, su sonido y el del
#          aviso una vez cada uno, sin impactos.
#        Aguijón: el turno siguiente a enterrarse y con un turno de héroe entre medias; un impacto, un héroe, el
#          sonido del aguijón una vez en ese fotograma, la arena que brota una vez; quien defendía, a la mitad o menos;
#          luego expuesto (puntos débiles) y su sonido una vez; la marca, fuera.
#        Recompone: al empezar su turno siguiente la ventana se cierra.
#      Atacar sin nadie a tiro no deja apuntar, lo dice y no gasta el turno. Gana; experiencia, monedas y una Esquirla.
#   B. Controlado (el combate parado): golpe con caparazón y en la ventana; el aguijón contra quien defiende y contra
#      quien no; la Guardia de Garon se lo lleva él; Fuego (magia) entero; un golpe bajo la arena no llega.
#   C. Dos (grupo 15) y con Grimfang (grupo 16), con ataques automáticos (quien no tiene a quién, defiende): terminan
#      sin bloquearse. Ganar así no prueba la estrategia de un jugador.
#   D. Kael solo a nivel 10 contra uno: termina sin bloquearse.
#   E. Derrota (Kael y Lya a nivel 1): acaba, sin premio. Huida: sale del combate.
#   En todos: al acabar no quedan marcas, puntos ni sonidos suyos, y no crecen los nodos huérfanos.
# Con «fotos=<carpeta>» (y ventana) saca capturas: anticipación, aguijón, ventana, contraataque y derrota.

const ARCHIVO := "user://prueba_encuentro_desierto.save"
const MAX_FOTOGRAMAS := 16000
var V                                   # combate_vidracran.gd
var C                                   # combate.gd (sus constantes)
var P
var G
var Inv
var c = null
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []                 # [nombre, fotograma]
var impactos: Array = []                # [enemigo, ataque, fotograma]
var fotos := ""
var fotos_hechas := {}
var huerfanos0 := -1
var sin_objetivo_probado := false
# 12/11, 13:50: cada vez que se abre una ventana (sube el contador «expuesto» de combate_vidracran.gd) se apunta, en ese
# mismo fotograma, si está expuesto y si sus puntos débiles están en la escena: enemigo → [{expuesto, puntos, fotograma}]
var ventanas := {}


func _initialize() -> void:
	V = load("res://combate_vidracran.gd")
	C = load("res://combate.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
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
			V.INTERRUPTOR]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(10)
	huerfanos0 = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_u()
	var solo := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			solo = a.substr(5)
	for p in ["A", "B", "C", "D", "E"]:
		if solo == "" or solo.contains(p):
			await call("_" + p.to_lower())
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= U: sin escena

func _u() -> void:
	_limpiar()
	_ok(not V.ACTIVO_POR_DEFECTO and not V.activo(), "U: el interruptor no está apagado por defecto")
	seed(77)
	var a := randf()
	seed(77)
	var g: int = V.grupo_mar_cristal()
	var b := randf()
	_ok(g == -1, "U: apagado, el Mar de Cristal pide el grupo %d" % g)
	_ok(a == b, "U: apagado, grupo_mar_cristal() tira dados (cambia el azar de siempre)")
	for i in C.GRUPOS.size():                             # los encuentros de siempre no lo traen
		var con: bool = C.GRUPOS[i].any(func(x): return x[0] == V.CLAVE)
		_ok(con == (i in [V.GRUPO_UNO, V.GRUPO_DOS, V.GRUPO_MIXTO]), "U: GRUPOS[%d] %s a Vidracrán" % [i, "trae" if con else "no trae"])
	for n in [1, 2, 3]:
		for s in 300:
			seed(s)
			var i: int = C.grupo_al_azar(n)
			if C.GRUPOS[i].any(func(x): return x[0] == V.CLAVE):
				_ok(false, "U: un encuentro al azar normal (%d héroes, semilla %d) trae a Vidracrán" % [n, s])
				break
	Engine.set_meta(V.INTERRUPTOR, true)
	var vistos := {}
	for s in 200:
		seed(1000 + s)
		var kg: int = V.grupo_mar_cristal()
		vistos[kg] = true
		_ok(kg == -1 or kg in [V.GRUPO_UNO, V.GRUPO_DOS, V.GRUPO_MIXTO], "U: encendido pide el grupo %d" % kg)
	_ok(vistos.has(-1) and vistos.size() >= 2, "U: encendido no mezcla los de siempre con los suyos: %s" % str(vistos.keys()))
	Engine.remove_meta(V.INTERRUPTOR)
	hechos.append("U interruptor: apagado igual (sin dados), encendido %s" % str(vistos.keys()))
	# daño
	var z := {"clave": V.CLAVE, "hp": 100}
	var o := {"clave": "grimfang", "hp": 100}
	var k := {"nombre": "Kael", "hero": true}
	_ok(V.dano_recibido(40, "", k, z) == 20, "U: el caparazón no deja los golpes a la mitad")
	_ok(V.dano_recibido(40, "Fuego", k, z) == 40, "U: la magia no entra entera")
	z["vc_expuesto"] = true
	_ok(V.dano_recibido(40, "", k, z) == 60, "U: la ventana no hace ×1,5")
	z["vc_expuesto"] = false
	z["vc_enterrado"] = true
	_ok(V.dano_recibido(40, "", k, z) == 0 and V.dano_recibido(40, "Rayo", k, z) == 0, "U: bajo la arena le llega daño")
	_ok(not V.apuntable(z) and V.apuntable(o) and V.dano_recibido(40, "", k, o) == 40, "U: los demás enemigos cambian")
	_ok("Bajo la arena" in V.estados(z), "U: no se lee «Bajo la arena»")
	# sonido
	var Son = load("res://sonido.gd")
	_ok(Son.EFECTOS_VIDRACRAN.size() == 10, "U: %d claves de sonido (eran 10)" % Son.EFECTOS_VIDRACRAN.size())
	for clave in Son.EFECTOS_VIDRACRAN:
		var d: Dictionary = Son.EFECTOS_VIDRACRAN[clave]
		_ok(not Son.EFECTOS.has(clave) and Son.definicion(clave) == d, "U: «%s» no se encuentra" % clave)
		for i in (int(d["n"]) if d.has("n") else 1):
			var ruta: String = Son.ruta_archivo(d, i if d.has("n") else -1)
			var st = load(ruta)
			_ok(st is AudioStreamOggVorbis, "U: %s no es un OGG que cargue" % ruta)
			if st is AudioStreamOggVorbis:
				_ok(not st.loop and st.get_length() > 0.1 and st.get_length() < 2.5, "U: %s dura %.2f s o da la vuelta" % [ruta, st.get_length()])
				var pico := _pico(st)
				_ok(pico > 0.2 and pico < 0.999, "U: %s muda o saturada (pico %.3f)" % [ruta, pico])
	_ok(Son.familia({"hero": false, "clave": V.CLAVE}) == "vidracran" and Son._hay_voz("vidracran_herido")
		and Son._hay_voz("vidracran_caida"), "U: su voz no es la suya")
	for n in ["pinzas", "emerger", "aviso_emerger", "entrada", "derrumbe"]:   # los que pide combate.gd por la clave
		_ok(Son.EFECTOS_VIDRACRAN.has("vidracran_" + n), "U: falta vidracran_%s" % n)
	for n in V.SONIDOS.values():
		_ok(Son.EFECTOS_VIDRACRAN.has(n), "U: combate_vidracran.gd pide «%s», que no existe" % n)
	# material y botín
	var Extra = load("res://equipo_extra.gd")
	_ok(Extra.materiales().has(V.PREMIO), "U: «%s» no está en el catálogo" % V.PREMIO)
	_ok(Extra.botin() == {"zarzalin": "Corteza espinosa"}, "U: el botín de siempre cambió: %s" % [Extra.botin()])
	_ok(V.botin_de([{"clave": V.CLAVE, "hp": 0}, {"clave": V.CLAVE, "hp": 0, "huido": true}, {"clave": V.CLAVE, "hp": 3},
		{"clave": "slime", "hp": 0}]) == [V.PREMIO], "U: el botín de Vidracrán no es uno por cada vencido")
	_ok(not V.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	hechos.append("U daño, textos, 10 sonidos, material y partida")


# Pico de un OGG decodificado (como prueba_audio_desierto: mix_audio a 48 kHz).
func _pico(st: AudioStream) -> float:
	var pb = st.instantiate_playback()
	pb.start(0.0)
	var pico := 0.0
	for i in int(st.get_length() * 48000.0 / 1024.0) + 1:
		var buf: PackedVector2Array = pb.mix_audio(1.0, 1024)
		for v in buf:
			pico = maxf(pico, maxf(absf(v.x), absf(v.y)))
	pb.stop()
	return pico


# ================================================================= un combate

func _combate(activos: Dictionary, grupo: int, semilla: int) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	seed(semilla)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)
	for e in c.enemigos:
		var p = c._p3d(e)
		if V.es(e):
			_ok(p != null and p.has_method("enterrarse"), "%s: no tiene su modelo 3D" % e["nombre"])
		if p != null and p.has_signal("impacto"):
			var nombre: String = e["nombre"]
			p.impacto.connect(func(a): impactos.append([nombre, a, Engine.get_process_frames()]))


func _cerrar() -> void:
	if c != null:
		for i in 120:                                      # los efectos de la derrota acaban
			if V.nodos_vivos(c.enemigos).is_empty():
				break
			await process_frame
		_ok(V.nodos_vivos(c.enemigos).is_empty(), "al acabar quedan nodos suyos: %s" % str(V.nodos_vivos(c.enemigos)))
		c.queue_free()
		c = null
	var t0 := Time.get_ticks_msec()                     # (con --fixed-fps los fotogramas corren más que el reloj: el
	while Time.get_ticks_msec() - t0 < 2500:           # audio va en tiempo real; ninguno suyo dura más de 2 s)
		await process_frame
	_ok(not _suena_suyo(), "al cerrar el combate sigue sonando algo de Vidracrán")
	await _esperar(5)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(h <= huerfanos0, "al cerrar el combate hay %d nodos huérfanos (antes %d)" % [h, huerfanos0])


func _suena_suyo() -> bool:
	var S = root.get_node_or_null("Sonido")
	if S == null:
		return false
	for p in S._todas():
		if p.playing and str(p.get_meta("efecto", "")).begins_with("vidracran_") and not p.get_meta("apagando", false):
			return true
	return false


func _vidracranes() -> Array:
	return c.enemigos.filter(func(e): return V.es(e))


func _cont(e: Dictionary) -> Dictionary:
	return (e.get("vc_contador", {}) as Dictionary).duplicate()


func _foto_estado() -> Dictionary:
	var hp := {}
	var defiende := {}
	var cubre := {}
	for h in c.heroes:
		hp[h["nombre"]] = h["hp"]
		defiende[h["nombre"]] = h.get("defendiendo", false)
		cubre[h["nombre"]] = str(h.get("guardia_de", ""))
	var conts := {}
	var obj := {}
	for e in _vidracranes():
		conts[e["nombre"]] = _cont(e)
		var o = e.get("vc_objetivo", null)
		obj[e["nombre"]] = str(o["nombre"]) if o is Dictionary else ""
	return {"hp": hp, "defiende": defiende, "cubre": cubre, "conts": conts, "obj": obj, "sonidos": sonidos.size(),
		"impactos": impactos.size(), "turnos_heroe": c.turnos_heroe}


# Juega hasta el final. «estrategia»: «jugador» o «auto».
func _jugar(estrategia: String, comprobar := true) -> Dictionary:
	var r := {"acciones": [], "gana": false, "fin": false, "turnos_heroe": 0, "defendidos": 0, "ventana_golpes": 0}
	var quien = null                                       # el enemigo cuyo turno se está mirando
	var ant := {}
	var previo := _foto_estado()
	var f_fin := -1
	var decidido := -1
	var ultimo := {}                                       # enemigo → [acción, turnos_heroe]
	ventanas.clear()
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		_vigilar_ventanas()                                # (antes de cerrar un turno: lo de este fotograma)
		# 12/11, 13:50: el turno de un enemigo se sigue por c.atacante_actual (lo pone _turno_enemigo al empezar y lo quita
		# _fin_turno_enemigo antes de su espera de 0,3 s y de _comprobar_fin), no por c.estado: dos turnos enemigos
		# seguidos pueden encadenarse en un mismo fotograma sin que se vea «esperando», y el fin del combate llega después.
		var actual = c.atacante_actual
		var cerrado := false
		if quien != null and not is_same(actual, quien):
			if V.es(quien):
				var que := _que_hizo(quien, ant)
				r["acciones"].append(que)
				if comprobar:
					_comprobar_turno(quien, que, ant, ultimo, r)
				ultimo[quien["nombre"]] = [que, c.turnos_heroe]
			quien = null
			cerrado = true
		if actual != null and quien == null:
			quien = actual
			ant = _foto_estado() if cerrado else previo       # (otro turno enemigo justo detrás: desde como quedó)
		if fotos != "":
			_fotos_bucle()
		if c.atacante_actual == null:
			previo = _foto_estado()
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_decidir(estrategia, r)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 150:
			break
	r["fin"] = c.estado == "fin"
	r["gana"] = c.enemigos.all(func(e): return e["hp"] <= 0) and c.heroes.any(func(h): return h["hp"] > 0)
	r["turnos_heroe"] = c.turnos_heroe
	return r


func _vigilar_ventanas() -> void:
	for e in _vidracranes():
		var lista: Array = ventanas.get(e["nombre"], [])
		if int(_cont(e).get("expuesto", 0)) > lista.size():
			var n = e.get("puntos_nodo", null)
			lista.append({"expuesto": e.get("vc_expuesto", false), "fotograma": Engine.get_process_frames(),
				"puntos": n != null and is_instance_valid(n) and not n.is_queued_for_deletion()})
			ventanas[e["nombre"]] = lista


func _que_hizo(e: Dictionary, ant: Dictionary) -> String:
	var antes: Dictionary = ant["conts"].get(e["nombre"], {})
	var ahora := _cont(e)
	var r := ""
	for k in ["aguijon", "enterrarse", "pinzas"]:
		if int(ahora.get(k, 0)) > int(antes.get(k, 0)):
			r = k
			break
	if r == "":
		r = "otro"
	if int(ahora.get("recompone", 0)) > int(antes.get("recompone", 0)):
		r += "+recompone"
	return r


func _comprobar_turno(e: Dictionary, que: String, ant: Dictionary, ultimo: Dictionary, r: Dictionary) -> void:
	var golpeados: Array = []
	var dano := {}
	for h in c.heroes:
		var d: int = int(ant["hp"][h["nombre"]]) - int(h["hp"])
		if d > 0:
			golpeados.append(h["nombre"])
			dano[h["nombre"]] = d
	var imp: Array = impactos.slice(ant["impactos"]).filter(func(x): return x[0] == e["nombre"])
	var son: Array = sonidos.slice(ant["sonidos"])
	var cuenta := func(n: String) -> Array: return son.filter(func(s): return s[0] == n)
	var n := "%s (%s)" % [e["nombre"], que]
	if que.ends_with("+recompone"):
		_ok(not e.get("vc_expuesto", false) and not e.has("puntos_nodo") or e["hp"] <= 0, "%s: la ventana no se cierra" % n)
		if que.begins_with("aguijon"):
			_ok(false, "%s: se recompone y pica en el mismo turno" % n)
	if que.begins_with("pinzas"):
		_ok(imp.size() == 1 and imp[0][1] == "pinzas", "%s: impactos %s" % [n, str(imp)])
		_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
		var s: Array = cuenta.call("vidracran_pinzas")
		_ok(s.size() == 1, "%s: su sonido suena %d veces" % [n, s.size()])
		if s.size() == 1 and imp.size() == 1:
			_ok(absi(int(s[0][1]) - int(imp[0][2])) <= 1, "%s: el sonido no cae en el impacto" % n)
	elif que.begins_with("enterrarse"):
		_ok(golpeados.is_empty(), "%s: hace daño al enterrarse: %s" % [n, str(dano)])
		_ok(imp.is_empty(), "%s: impactos al enterrarse" % n)
		if e["hp"] > 0:
			_ok(e.get("vc_enterrado", false), "%s: no queda bajo la arena" % n)
			_ok(not c._alcanzables().has(e), "%s: bajo la arena se le puede apuntar" % n)
			_ok(e.get("vc_marca", null) != null and is_instance_valid(e["vc_marca"]) or
				int((e.get("vc_objetivo", {}) as Dictionary).get("hp", 0)) <= 0, "%s: sin marca sobre el héroe" % n)
			_ok(cuenta.call("vidracran_enterrarse").size() == 1, "%s: el sonido de enterrarse no suena una vez" % n)
			_ok(cuenta.call("vidracran_aviso_emerger").size() == 1, "%s: el aviso del bulbo suena %d veces" % [n,
				cuenta.call("vidracran_aviso_emerger").size()])
			_ok(not e.get("animando", false), "%s: se queda animando" % n)
	elif que.begins_with("aguijon"):
		var antes = ultimo.get(e["nombre"], [])
		_ok(antes.size() == 2 and antes[0].begins_with("enterrarse"), "%s: pica sin haberse enterrado antes (%s)" % [n, str(antes)])
		if antes.size() == 2:
			_ok(int(ant["turnos_heroe"]) > int(antes[1]), "%s: pica sin un turno de héroe entre el aviso y el golpe" % n)
		_ok(imp.size() == 1 and imp[0][1] == "emerger_aguijon", "%s: impactos %s" % [n, str(imp)])
		_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
		var s: Array = cuenta.call("vidracran_emerger")
		_ok(s.size() == 1, "%s: el sonido del aguijón suena %d veces" % [n, s.size()])
		if s.size() == 1 and imp.size() == 1:
			_ok(absi(int(s[0][1]) - int(imp[0][2])) <= 1, "%s: el sonido no cae en el impacto" % n)
		_ok(cuenta.call("vidracran_brota").size() == 1, "%s: la arena que brota no suena una vez" % n)
		for h in golpeados:
			var objetivo: String = ant["obj"].get(e["nombre"], "")
			if ant["defiende"][h]:
				r["defendidos"] += 1
				var furia: float = 1.5 if e.get("furia", false) else 1.0   # (un golpe enemigo también puede ser crítico)
				var tope: float = (int(e["atk"] * V.MULT_AGUIJON * furia) + 3) * C.MULT_CRITICO * 0.5 + 1.0
				_ok(dano[h] <= tope, "%s: %s defendía y recibe %d (tope %.0f)" % [n, h, dano[h], tope])
			if objetivo != "" and h != objetivo and int(ant["hp"].get(objetivo, 0)) > 0:   # (si el marcado cayó, otro)
				_ok(ant["cubre"].get(objetivo, "") == h, "%s: iba a por %s y alcanza a %s sin que le cubra" % [n, objetivo, h])
		_ok(e.get("vc_marca", null) == null, "%s: la marca sigue tras picar" % n)
		# la ventana, en el fotograma en que se abre (no después: el combate puede acabar con ese aguijón y entonces
		# _comprobar_fin quita los puntos, como debe)
		var abiertas: int = int(_cont(e).get("expuesto", 0)) - int(ant["conts"].get(e["nombre"], {}).get("expuesto", 0))
		var lista: Array = ventanas.get(e["nombre"], [])
		if e["hp"] > 0:
			_ok(abiertas == 1, "%s: se abren %d ventanas (una)" % [n, abiertas])
			if abiertas == 1 and not lista.is_empty():
				var v: Dictionary = lista[lista.size() - 1]
				_ok(v["expuesto"] and v["puntos"], "%s: al abrirse la ventana no queda expuesto (%s)" % [n, str(v)])
			_ok(c.estado == "fin" or (e.get("vc_expuesto", false) and e.has("puntos_nodo")),
				"%s: la ventana se cierra antes de su turno siguiente" % n)
			_ok(cuenta.call("vidracran_expuesto").size() == 1, "%s: el sonido de la ventana no suena una vez" % n)
			_ok(not e.get("vc_enterrado", false) and e["rig"].position.distance_to(e["rig_base"]) < 1.0,
				"%s: no vuelve a su sitio fuera de la arena" % n)
	else:
		_ok(que.begins_with("otro") and e["hp"] <= 0 or e.get("huido", false), "%s: hizo algo desconocido" % n)


func _decidir(estrategia: String, r: Dictionary) -> void:
	var a: Dictionary = c.actor
	var alc: Array = c._alcanzables()
	if estrategia == "auto":
		if alc.is_empty():
			c._defender()
		else:
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(alc[0])
		return
	var marcado := false
	var marcado_otro = null
	for e in _vidracranes():
		if e["hp"] > 0 and e.get("vc_enterrado", false) and e.get("vc_objetivo", null) is Dictionary:
			if is_same(e["vc_objetivo"], a):
				marcado = true
			else:
				marcado_otro = e["vc_objetivo"]
	if marcado:                                          # el aguijón va a por mí: defender
		c._defender()
		return
	if a["nombre"] == "Garon" and marcado_otro != null and marcado_otro["hp"] > 0 \
			and a["mp"] >= c.GUARDIA["coste"] and str(marcado_otro.get("guardia_de", "")) == "":
		c._guardia(marcado_otro)                          # le cubre (el aguijón irá a Garon, que se defiende)
		return
	if alc.is_empty():                                    # nadie a tiro: atacar no deja apuntar
		if not sin_objetivo_probado:
			sin_objetivo_probado = true
			var mp: int = a["mp"]
			c._menu_objetivo("atacar", "")
			_ok(c.estado == "menu" and c.objetivos_posibles.is_empty() and c.registro.text == V.SIN_OBJETIVO
				and a["mp"] == mp and is_same(c.actor, a), "A: atacar sin nadie a tiro no vuelve al menú con su aviso (%s, «%s»)" %
				[c.estado, c.registro.text])
			hechos.append("A atacar bajo la arena: «%s»" % c.registro.text)
		c._defender()
		return
	var expuesto: Array = alc.filter(func(e): return e.get("vc_expuesto", false))
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.5)
		if not heridos.is_empty() and a["mp"] >= 6:
			c._elegir_hechizo("Cura", 1, true)
			return
		if expuesto.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Fuego"][0]["coste"]):
			c._elegir_hechizo("Fuego", 1)                  # la magia atraviesa el caparazón
			c._confirmar_objetivo(alc[0])
			return
	var t: Dictionary = expuesto[0] if not expuesto.is_empty() else alc[0]
	if not expuesto.is_empty():
		r["ventana_golpes"] += 1
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(t)


# ================================================================= A: estrategia de jugador

func _a() -> void:
	var esq0: int = Inv.cantidad(V.PREMIO)
	var oro0: int = Inv.oro()
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, V.GRUPO_UNO, 5)
	var z: Dictionary = c.enemigos[0]
	_ok(V.es(z) and z["nombre"] == "Vidracrán", "A: el grupo 14 no es Vidracrán solo")
	_ok(not c.enemigos.any(func(e): return e.get("elite", false)), "A: sale de élite")
	var exp0 := {}
	for n in ["Kael", "Lya", "Garon"]:
		exp0[n] = int(G.datos()[n]["exp"])
	var r := await _jugar("jugador")
	_ok(r["fin"] and r["gana"], "A: no gana con estrategia (fin %s, acciones %s)" % [r["fin"], str(r["acciones"])])
	_ok(r["acciones"].any(func(x): return x.begins_with("aguijon")) and r["acciones"].any(func(x): return x.begins_with("pinzas")),
		"A: no se ve el ciclo entero: %s" % str(r["acciones"]))
	_ok(r["defendidos"] >= 1 or c.cubiertos >= 1, "A: nadie se defendió del aguijón ni le cubrió")
	_ok(r["ventana_golpes"] >= 1, "A: ningún golpe en la ventana")
	_ok(sin_objetivo_probado, "A: no se probó atacar con él bajo la arena")
	await _esperar(200)                                    # el reparto de experiencia y monedas
	_ok(Inv.cantidad(V.PREMIO) == esq0 + 1, "A: la Esquirla no llega una vez (%d → %d)" % [esq0, Inv.cantidad(V.PREMIO)])
	_ok(Inv.oro() >= oro0 + int(z["oro"]), "A: las monedas no llegan (%d → %d)" % [oro0, Inv.oro()])
	_ok(["Kael", "Lya", "Garon"].any(func(n): return int(G.datos()[n]["exp"]) > int(exp0[n]) or int(G.datos()[n]["nivel"]) > 10),
		"A: nadie gana experiencia")
	var s_der: Array = sonidos.filter(func(s): return s[0] == "vidracran_derrumbe")
	_ok(s_der.size() == 1, "A: su derrumbe suena %d veces" % s_der.size())
	var guardado := JSON.stringify(P.volcar())
	_ok(not guardado.contains("vc_") and not guardado.contains(V.INTERRUPTOR), "A: la partida guardaría claves suyas")
	hechos.append("A jugador gana: %s; defendidos %d, cubiertos %d, golpes en la ventana %d, turnos de héroe %d" % [
		",".join(r["acciones"]), r["defendidos"], c.cubiertos, r["ventana_golpes"], r["turnos_heroe"]])
	await _cerrar()


# ================================================================= B: controlado

func _b() -> void:
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, V.GRUPO_UNO, 9)
	await _esperar(30)
	c.estado = "fin"                                       # parado: sin ATB ni turnos
	var z: Dictionary = c.enemigos[0]
	z["hp_max"] = 5000
	z["hp"] = 5000
	var kael: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var lya: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	var garon: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Garon")[0]
	# caparazón y ventana (un crítico, ×1,6, también vale)
	var hp0: int = z["hp"]
	await c._animar_golpe(kael, z, 40, "")
	_ok(hp0 - z["hp"] in [20, 32], "B: con el caparazón un golpe de 40 quita %d" % (hp0 - z["hp"]))
	z["vc_expuesto"] = true
	hp0 = z["hp"]
	await c._animar_golpe(kael, z, 40, "")
	_ok(hp0 - z["hp"] in [60, 96], "B: en la ventana un golpe de 40 quita %d" % (hp0 - z["hp"]))
	z["vc_expuesto"] = false
	hp0 = z["hp"]
	await c._animar_golpe(lya, z, 40, "Fuego")
	_ok(hp0 - z["hp"] == 40, "B: Fuego de 40 quita %d" % (hp0 - z["hp"]))
	await _esperar(30)
	# el aguijón: sin defender, defendiendo y con la Guardia de Garon
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var danos := {}
	for caso in ["sin", "defiende", "guardia"]:
		for h in c.heroes:
			h["hp"] = h["hp_max"]
			h["defendiendo"] = false
			h.erase("guardia_de")
		z["vc_fase"] = 1
		z.erase("vc_expuesto")
		z["vc_contador"] = {}
		seed(31)
		await V.turno(c, z, vivos, 1.0)                   # se entierra
		_ok(z.get("vc_enterrado", false) and not c._alcanzables().has(z), "B %s: no queda bajo la arena" % caso)
		var hp_z: int = z["hp"]
		await c._animar_golpe(kael, z, 40, "")            # un golpe que lo buscara: no le llega
		_ok(z["hp"] == hp_z, "B %s: bajo la arena le llega un golpe" % caso)
		var obj: Dictionary = z["vc_objetivo"]
		if caso == "defiende":
			obj["defendiendo"] = true
		if caso == "guardia":
			if is_same(obj, garon):                        # (que la Guardia sea para otro)
				z["vc_objetivo"] = lya
				obj = lya
			obj["guardia_de"] = "Garon"
			garon["defendiendo"] = true
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		seed(32)
		await V.turno(c, z, vivos, 1.0)                   # emerge y pica
		var d := {}
		for h in c.heroes:
			if antes[h["nombre"]] > h["hp"]:
				d[h["nombre"]] = antes[h["nombre"]] - h["hp"]
		danos[caso] = d
		_ok(d.size() == 1, "B %s: el aguijón alcanza a %s" % [caso, str(d)])
		if caso == "guardia":
			_ok(d.has("Garon"), "B guardia: no se lo lleva Garon (%s)" % str(d))
		else:
			_ok(d.has(obj["nombre"]), "B %s: no va a por el marcado (%s, %s)" % [caso, obj["nombre"], str(d)])
		_ok(z.get("vc_expuesto", false), "B %s: no queda expuesto" % caso)
		await _esperar(20)
	var sin: int = danos["sin"].values()[0] if danos["sin"].size() == 1 else 0
	var def: int = danos["defiende"].values()[0] if danos["defiende"].size() == 1 else 999
	var gua: int = danos["guardia"].values()[0] if danos["guardia"].size() == 1 else 999
	_ok(def * 1.0 <= sin * 0.6 + 1, "B: defender no lo deja a la mitad (%d frente a %d)" % [def, sin])
	_ok(gua * 1.0 <= sin * 0.6 + 1, "B: con la Guardia, Garon no recibe la mitad (%d frente a %d)" % [gua, sin])
	hechos.append("B caparazón ×0,5, ventana ×1,5, Fuego entero, bajo la arena 0; aguijón %d, defendido %d, Guardia %d" % [sin, def, gua])
	c.estado = "esperando"
	z["hp"] = 1
	c._quitar_pv(z, 1)
	c._golpe_visual(z, 1, "")
	await _esperar(60)
	await _cerrar()


# ================================================================= C y D: automáticos

func _c() -> void:
	for g in [V.GRUPO_DOS, V.GRUPO_MIXTO]:
		await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, g, 11 + g)
		var r := await _jugar("auto")
		_ok(r["fin"], "C grupo %d: el combate automático no termina (%s)" % [g, str(r["acciones"])])
		hechos.append("C grupo %d automático: %s, %s" % [g, "gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
		await _cerrar()


func _d() -> void:
	await _combate({"Kael": 10}, V.GRUPO_UNO, 21)
	var r := await _jugar("auto")
	_ok(r["fin"], "D Kael solo: no termina (%s)" % str(r["acciones"]))
	hechos.append("D Kael solo automático: %s, %s" % ["gana" if r["gana"] else "pierde", ",".join(r["acciones"])])
	await _cerrar()


# ================================================================= E: derrota y huida

func _e() -> void:
	var esq0: int = Inv.cantidad(V.PREMIO)
	await _combate({"Kael": 1, "Lya": 1}, V.GRUPO_DOS, 3)
	var r := await _jugar("auto", false)
	_ok(r["fin"] and not r["gana"], "E: con nivel 1 no pierde o no acaba (%s)" % str(r["acciones"]))
	await _esperar(120)
	_ok(Inv.cantidad(V.PREMIO) == esq0, "E: perdiendo da Esquirlas")
	hechos.append("E derrota: %s" % ",".join(r["acciones"]))
	await _cerrar()
	await _combate({"Kael": 10, "Lya": 10}, V.GRUPO_UNO, 4)
	for fr in 3000:
		await _esperar(1)
		if c.estado == "menu" and c.actor is Dictionary:
			c._escapar()
			break
	for fr in 400:
		await _esperar(1)
		if c.estado == "fin":
			break
	_ok(c.estado == "fin", "E: huir no acaba el combate (%s)" % c.estado)
	hechos.append("E huida")
	await _cerrar()


# ================================================================= capturas (con ventana)

func _fotos_bucle() -> void:
	for e in _vidracranes():
		if e["hp"] > 0 and e.get("vc_enterrado", false) and sonidos.any(func(s): return s[0] == "vidracran_aviso_emerger") \
				and not fotos_hechas.has("01_anticipacion"):
			var f_av: int = sonidos.filter(func(s): return s[0] == "vidracran_aviso_emerger")[0][1]
			if Engine.get_process_frames() >= f_av + 3:
				_foto("01_anticipacion")
		if e["hp"] > 0 and e.get("vc_expuesto", false) and not fotos_hechas.has("03_ventana"):
			_foto("03_ventana")
		if e["hp"] <= 0 and not fotos_hechas.has("05_derrota"):
			fotos_hechas["05_derrota_t"] = int(fotos_hechas.get("05_derrota_t", 0)) + 1
			if fotos_hechas["05_derrota_t"] == 24:
				_foto("05_derrota")
	for i in impactos:
		if i[1] == "emerger_aguijon" and Engine.get_process_frames() == int(i[2]) + 2 and not fotos_hechas.has("02_aguijon"):
			_foto("02_aguijon")
		if i[1] == "pinzas" and Engine.get_process_frames() == int(i[2]) + 1 and not fotos_hechas.has("00_pinzas"):
			_foto("00_pinzas")
	var z = c.enemigos[0]
	if z.get("vc_expuesto", false) and c.estado == "accion" and c.actor is Dictionary and fotos_hechas.has("03_ventana") \
			and not fotos_hechas.has("04_contraataque"):
		fotos_hechas["04_t"] = int(fotos_hechas.get("04_t", 0)) + 1
		if fotos_hechas["04_t"] == 18:
			_foto("04_contraataque")


func _foto(nombre: String) -> void:
	fotos_hechas[nombre] = true
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(fotos.path_join(nombre + ".png"))
		hechos.append("foto " + nombre)
