extends SceneTree
# V12 (12/11/2026): Humbaba en combates de verdad (combate_humbaba.gd y sus ganchos de combate.gd), sin ventana, con
# semilla y datos aislados (la partida apunta a su propio archivo; los combates no guardan).
#   U. Sin escena: el interruptor «humbaba_v12» apagado por defecto (activo() false, el santuario da -1) y encendido
#      con Engine.set_meta; GRUPOS[17] existe y no está en los encuentros al azar; daño recibido (corteza ×0,8, fuego
#      ×1,4, núcleo ×1,4, vulnerable ×1,6; otro enemigo, igual); las fases por vida (70 % y 35 %); cada ataque de
#      ATAQUES tiene nombre, clip con su evento de impacto en humbaba_clips.json, fases y contrarresto.
#   A. Controlado (grupo 17, semilla 7, los tres a nivel 12): se fuerza cada ataque en su fase y se mira que el daño
#      llega UNA vez por impacto, en el fotograma del evento del clip (±2), a quien debe (Puño: la zona; Ojo: uno;
#      Raíces, Guadaña, Aliento: todos), con su estado (raíces: pierde el turno, y Defender lo evita; corrupción: la
#      cura la limpia), sus efectos y su sonido; la ventana del núcleo tras el Puño; la Llamada respeta el tope; el
#      Abrazo devuelve a la presa a su sitio; el Réquiem se avisa un turno antes sin daño y luego golpea a todos y le
#      deja vulnerable, y se recupera al turno siguiente; las transformaciones (fase 2: núcleo verde y grietas; fase 3:
#      armadura rota) no hacen daño.
#   B. Combate entero con una estrategia de jugador (defender el Réquiem, Lya cura y quema, el resto golpea): termina;
#      pasa por las tres fases; al acabar no quedan nodos suyos ni estados en los héroes; los condenados caen con él.
#   C. Derrota (dos héroes a nivel 1): acaba sin bloquearse.

const ARCHIVO := "user://prueba_humbaba_combate.save"
var H
var C
var P
var G
var c = null
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []
var impactos: Array = []                    # [ataque, fotograma, posición del clip]


func _initialize() -> void:
	H = load("res://combate_humbaba.gd")
	C = load("res://combate.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
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
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", H.INTERRUPTOR]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	_u()
	await _v()
	await _a()
	await _b()
	await _c()
	_limpiar()
	for h in hechos:
		print("  · ", h)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= U

func _u() -> void:
	_limpiar()
	_ok(not H.activo(), "U: el interruptor no está apagado por defecto")
	_ok(H.grupo_santuario() == -1, "U: apagado, el santuario da un grupo")
	Engine.set_meta(H.INTERRUPTOR, true)
	_ok(H.activo() and H.grupo_santuario() == H.GRUPO, "U: encendido no da su grupo")
	Engine.remove_meta(H.INTERRUPTOR)
	_ok(C.GRUPOS.size() > H.GRUPO and C.GRUPOS[H.GRUPO][0][0] == "humbaba", "U: GRUPOS[17] no es Humbaba")
	_ok(H.GRUPO >= C.GRUPOS_AL_AZAR, "U: su grupo sale al azar")
	for k in C.AL_AZAR_POR_TAMANO:
		_ok(not (H.GRUPO in C.AL_AZAR_POR_TAMANO[k]), "U: su grupo está en los encuentros de %d" % k)
	var hb := {"clave": "humbaba", "hp": 1000, "hp_max": 1000, "hb_fase": 1}
	var otro := {"clave": "slime", "hp": 50, "hp_max": 50}
	_ok(H.dano_recibido(100, "", {}, hb) == 80, "U: la corteza no frena a ×0,8")
	_ok(H.dano_recibido(100, "Fuego", {}, hb) == 140, "U: el fuego no hace ×1,4")
	_ok(H.dano_recibido(100, "Agua", {}, hb) == 100, "U: el agua cambia")
	hb["hb_nucleo"] = true
	_ok(H.dano_recibido(100, "", {}, hb) == 140, "U: el núcleo al alcance no hace ×1,4")
	hb.erase("hb_nucleo")
	hb["hb_vulnerable"] = true
	_ok(H.dano_recibido(100, "", {}, hb) == 160 and H.dano_recibido(100, "Fuego", {}, hb) == 224, "U: vulnerable no hace ×1,6")
	hb.erase("hb_vulnerable")
	hb["hb_fase"] = 3
	_ok(H.dano_recibido(100, "", {}, hb) == 100, "U: en la fase 3 la corteza sigue frenando")
	_ok(H.dano_recibido(100, "", {}, otro) == 100 and H.dano_recibido(100, "Fuego", {}, otro) == 100, "U: cambia el daño a otro enemigo")
	for v in [[1000, 1], [701, 1], [700, 2], [351, 2], [350, 3], [1, 3]]:
		hb["hp"] = v[0]
		_ok(H.fase_por_vida(hb) == v[1], "U: con %d PV la fase no es %d" % v)
	var datos: Dictionary = load("res://enemigos/humbaba/humbaba_3d.gd").leer_json()
	for id in H.ATAQUES:
		var a: Dictionary = H.ATAQUES[id]
		var clip: String = a["clip"]
		var evs: Dictionary = datos.get("clips", {}).get(clip, {}).get("eventos", {})
		var imp: Array = ["apretar_1", "apretar_2"] if id == "abrazo" else ["impacto"]
		for e in imp:
			_ok(evs.has(e), "U: %s (%s) sin el evento «%s»" % [id, clip, e])
		_ok(a.get("nombre", "") != "" and not a.get("fases", []).is_empty() and a.get("contra", "") != "", "U: a %s le falta su ficha" % id)
	hechos.append("U: interruptor apagado; daño recibido; fases; %d ataques con su evento" % H.ATAQUES.size())


# ================================================================= combates

func _combate(activos: Dictionary, semilla: int) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "bosque")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", H.GRUPO)
	seed(semilla)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)
	await _esperar(2)
	var hb := _hb()
	var p = c._p3d(hb)
	_ok(p != null and p.has_method("atacar"), "no tiene su modelo 3D")
	if p != null:
		p.impacto.connect(func(a): impactos.append([a, Engine.get_process_frames(), p.anim.current_animation_position, String(p.anim.current_animation)]))


func _hb() -> Dictionary:
	for e in c.enemigos:
		if H.es(e):
			return e
	return {}


func _hp() -> Dictionary:
	var r := {}
	for h in c.heroes:
		r[h["nombre"]] = int(h["hp"])
	return r


func _parar() -> void:                                   # el combate quieto: nadie más actúa mientras se fuerza
	c.estado = "accion"
	for f in c.heroes + c.enemigos:
		f["atb"] = 0.0
	c.cola.clear()


func _curar_todos() -> void:
	for h in c.heroes:
		h["hp"] = h["hp_max"]
		h["defendiendo"] = false
		h.erase("hb_raices")
		h.erase("hb_corrupcion")


# Fuerza el ataque «que» en la fase «fase» y devuelve {antes, despues, impactos, sonidos}.
func _forzar(que: String, fase: int) -> Dictionary:
	var hb := _hb()
	_parar()
	_curar_todos()
	hb["hb_fase"] = fase
	if not hb.has("hb_paso"):
		hb["hb_paso"] = {1: 0, 2: 0, 3: 0}
	var ciclo: Array = H.CICLOS[fase]
	hb["hb_paso"][fase] = ciclo.find(que)
	hb["hp"] = int(hb["hp_max"] * ([1.0, 0.6, 0.3][fase - 1]))
	var p = c._p3d(hb)
	if p != null and p.fase != fase:
		p._cambio_ahora(fase)
	var antes := _hp()
	var i0 := impactos.size()
	var s0 := sonidos.size()
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	await H.turno(c, hb, vivos, 1.0)
	await _esperar(3)
	return {"antes": antes, "despues": _hp(), "impactos": impactos.slice(i0), "sonidos": sonidos.slice(s0).map(func(x): return x[0])}


func _danados(r: Dictionary) -> Array:
	var d: Array = []
	for n in r["antes"]:
		if r["despues"][n] < r["antes"][n]:
			d.append(n)
	return d


func _a_tiempo(r: Dictionary, clip: String, ev: String) -> void:
	var p = c._p3d(_hb())
	var t: float = p.tiempo(clip, ev)
	for i in r["impactos"]:
		if i[3] == clip and absf(float(i[2]) - t) > 2.5 / 30.0 and absf(float(i[2]) - t) < 5.0:
			_ok(false, "A: %s: el impacto llegó a %.3f s y el evento «%s» es %.3f s" % [clip, i[2], ev, t])
			return


func _a() -> void:
	await _combate({"Kael": 12, "Lya": 12, "Garon": 12}, 7)
	var hb := _hb()
	_ok(not hb.is_empty() and hb["nombre"] == "Humbaba", "A: el grupo 17 no es Humbaba")
	await _esperar(60)
	var p = c._p3d(hb)
	# Puño: la zona (uno o dos), un impacto a su tiempo, el núcleo al alcance
	var r := await _forzar("puno", 1)
	_ok(r["impactos"].size() == 1, "A: Puño con %d impactos" % r["impactos"].size())
	_a_tiempo(r, "atk_puno", "impacto")
	var d := _danados(r)
	_ok(d.size() >= 1 and d.size() <= 2, "A: el Puño alcanzó a %s (la zona es uno o dos)" % str(d))
	_ok(hb.get("hb_nucleo", false) and hb.get("puntos_nodo", null) != null, "A: tras el Puño el núcleo no queda al alcance")
	_ok("guardian_bosque_golpe" in r["sonidos"], "A: el Puño no suena")
	_ok(H.dano_recibido(100, "", {}, hb) == 140, "A: el núcleo al alcance no recibe ×1,4")
	hechos.append("A Puño: %s, impacto a %.2f s" % [str(d), r["impactos"][0][2] if r["impactos"].size() > 0 else -1.0])
	# Raíces: a todos; quien no defiende pierde su turno; quien defiende, no
	r = await _forzar("raices", 1)
	_ok(r["impactos"].size() == 1, "A: Raíces con %d impactos" % r["impactos"].size())
	_a_tiempo(r, "atk_raices", "impacto")
	_ok(_danados(r).size() == c.heroes.size(), "A: las Raíces no alcanzaron a todos (%s)" % str(_danados(r)))
	var atrapados: Array = c.heroes.filter(func(h): return int(h.get("hb_raices", 0)) > 0)
	_ok(atrapados.size() == c.heroes.size(), "A: las raíces no atrapan a quien no defiende (%d)" % atrapados.size())
	var h0: Dictionary = atrapados[0] if not atrapados.is_empty() else c.heroes[0]
	_ok(H.tic_heroe(c, h0) and int(h0.get("hb_raices", 0)) == 0 and h0.get("hb_raiz_nodo", null) == null,
		"A: el atrapado no pierde su turno o su raíz no se va")
	_ok(not H.tic_heroe(c, h0), "A: pierde dos turnos")
	H.al_acabar(c)
	# Raíces con Defender: no atrapa
	_parar()
	_curar_todos()
	for h in c.heroes:
		h["defendiendo"] = true
	hb["hb_paso"][1] = H.CICLOS[1].find("raices")
	var ant := _hp()
	await H.turno(c, hb, c.heroes.filter(func(h): return h["hp"] > 0), 1.0)
	await _esperar(3)
	_ok(c.heroes.all(func(h): return int(h.get("hb_raices", 0)) == 0), "A: Defender no evita las raíces")
	for h in c.heroes:
		h["defendiendo"] = false
	# Guadaña: a todos, un impacto; la hoja crece y se recoge
	r = await _forzar("guadana", 1)
	_ok(r["impactos"].size() == 1 and _danados(r).size() == c.heroes.size(), "A: la Guadaña (%d impactos, %s)" % [r["impactos"].size(), str(_danados(r))])
	_a_tiempo(r, "atk_guadana", "impacto")
	# Aliento (fase 2): a todos con corrupción; la cura la limpia; las esporas se van
	r = await _forzar("aliento", 2)
	_ok(r["impactos"].size() == 1 and _danados(r).size() == c.heroes.size(), "A: el Aliento (%d impactos)" % r["impactos"].size())
	_a_tiempo(r, "atk_aliento", "impacto")
	_ok(c.heroes.all(func(h): return int(h.get("hb_corrupcion", 0)) == H.CORRUPCION_TURNOS), "A: el Aliento no corrompe")
	var hp_c: int = c.heroes[1]["hp"]
	H.tic_heroe(c, c.heroes[1])
	_ok(c.heroes[1]["hp"] < hp_c, "A: la corrupción no quita vida")
	H.al_curar(c.heroes[1])
	_ok(not c.heroes[1].has("hb_corrupcion"), "A: curar no limpia la corrupción")
	# Ojo del Juicio: a uno, a su tiempo; el rayo se va
	r = await _forzar("ojo", 2)
	_ok(r["impactos"].size() == 1 and _danados(r).size() == 1, "A: el Ojo (%d impactos, %s)" % [r["impactos"].size(), str(_danados(r))])
	_a_tiempo(r, "atk_ojo", "impacto")
	_ok(p.fase == 2, "A: el modelo no está en la fase 2")
	# Llamada: invoca hasta el tope
	var n0: int = c.enemigos.size()
	r = await _forzar("llamada", 2)
	var inv: int = H._invocados_vivos(c)
	_ok(inv >= 1 and inv <= H.TOPE_INVOCADOS and c.enemigos.size() == n0 + inv, "A: la Llamada invocó %d" % inv)
	r = await _forzar("llamada", 2)
	_ok(H._invocados_vivos(c) <= H.TOPE_INVOCADOS, "A: la Llamada pasa el tope (%d)" % H._invocados_vivos(c))
	_ok(not ("llamada" in str(r["impactos"])) or H._invocados_vivos(c) <= H.TOPE_INVOCADOS, "A: tope")
	hechos.append("A Llamada: %d condenados (tope %d); con el tope lleno usa el Ojo" % [H._invocados_vivos(c), H.TOPE_INVOCADOS])
	# Abrazo (fase 3): uno; uno o dos aprietos; la presa vuelve a su sitio
	var bases := {}
	for h in c.heroes:
		bases[h["nombre"]] = h["rig"].position
	r = await _forzar("abrazo", 3)
	await _esperar(30)
	var dd := _danados(r)
	_ok(dd.size() == 1, "A: el Abrazo alcanzó a %s" % str(dd))
	_ok(r["impactos"].size() >= 1 and r["impactos"].size() <= 2, "A: el Abrazo con %d aprietos" % r["impactos"].size())
	for h in c.heroes:
		_ok(h["rig"].position.distance_to(bases[h["nombre"]]) < 2.0 and not h.get("hb_agarrado", false),
			"A: %s no vuelve a su sitio tras el Abrazo (%s)" % [h["nombre"], str(h["rig"].position)])
	_ok(p.armadura_rota(), "A: en la fase 3 la armadura no está rota")
	hechos.append("A Abrazo: %s, %d aprietos" % [str(dd), r["impactos"].size()])
	# Réquiem: aviso sin daño; descarga a todos; vulnerable; se recupera
	r = await _forzar("requiem", 3)
	_ok(r["impactos"].is_empty() and _danados(r).is_empty(), "A: el aviso del Réquiem hace daño")
	_ok(hb.get("hb_requiem", false) and H.aviso_turno(c.enemigos) != "" and hb.get("aviso_nodo", null) != null,
		"A: el Réquiem no se avisa (cartel, señal)")
	_ok("Réquiem" in "".join(H.estados(hb)), "A: «⚠ Réquiem» no se lee sobre su vida")
	_ok(p.cargando and p.clip_actual() == "requiem_carga", "A: no queda cargando (%s)" % p.clip_actual())
	var antes2 := _hp()
	var i0 := impactos.size()
	await H.turno(c, hb, c.heroes.filter(func(h): return h["hp"] > 0), 1.0)
	await _esperar(3)
	var desp2 := _hp()
	var golpeados := 0
	for n in antes2:
		if desp2[n] < antes2[n]:
			golpeados += 1
	_ok(impactos.size() - i0 == 1 and golpeados == c.heroes.size(), "A: el Réquiem (%d impactos, %d golpeados)" % [impactos.size() - i0, golpeados])
	_ok(hb.get("hb_vulnerable", false) and p.vulnerable and H.dano_recibido(100, "", {}, hb) == 160, "A: tras el Réquiem no queda vulnerable")
	await H.turno(c, hb, c.heroes.filter(func(h): return h["hp"] > 0), 1.0)
	await _esperar(3)
	_ok(not hb.get("hb_vulnerable", false) and not p.vulnerable, "A: no se recupera al turno siguiente")
	# transformaciones: sin daño, con su material
	_parar()
	_curar_todos()
	hb["hb_fase"] = 1
	p._cambio_ahora(1)
	hb["hp"] = int(hb["hp_max"] * 0.69)
	antes2 = _hp()
	await H.turno(c, hb, c.heroes, 1.0)
	_ok(H.fase_de(hb) == 2 and p.fase == 2 and _hp() == antes2, "A: la fase 2 no llega o hace daño")
	hb["hp"] = int(hb["hp_max"] * 0.34)
	await H.turno(c, hb, c.heroes, 1.0)
	_ok(H.fase_de(hb) == 3 and p.armadura_rota() and _hp() == antes2, "A: la fase 3 no llega, no rompe la armadura o hace daño")
	hechos.append("A: Réquiem avisado y vulnerable; fases 2 y 3 sin daño; sonidos: %d" % sonidos.size())
	await _cerrar()


func _cerrar() -> void:
	if c != null:
		H.al_acabar(c)
		await _esperar(60)
		_ok(H.nodos_vivos(c).is_empty(), "al acabar quedan nodos suyos: %s" % str(H.nodos_vivos(c)))
		c.queue_free()
		c = null
	await _esperar(5)


# ================================================================= B: combate entero

func _decidir() -> void:
	var a: Dictionary = c.actor
	var alc: Array = c._alcanzables()
	var hb := _hb()
	if hb.get("hb_requiem", false):
		c._defender()
		return
	if alc.is_empty():
		c._defender()
		return
	var obj: Dictionary = hb if hb["hp"] > 0 else alc[0]
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and (float(h["hp"]) / h["hp_max"] < 0.5 or h.has("hb_corrupcion")))
		if not heridos.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Cura"][0]["coste"]):
			c._elegir_hechizo("Cura", 1, true)
			return
		if c._puede_pagar(c.NIVELES_MAGIA["Fuego"][0]["coste"]):
			c._elegir_hechizo("Fuego", 1)
			c._confirmar_objetivo(obj)
			return
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(obj)


func _jugar(max_fotogramas: int) -> Dictionary:
	var decidido := -1
	var f_fin := -1
	var fases := {}
	for fr in max_fotogramas:
		await _esperar(1)
		var hb := _hb()
		fases[H.fase_de(hb)] = true
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_decidir()
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 120:
			break
	return {"fin": c.estado == "fin", "gana": c.enemigos.all(func(e): return e["hp"] <= 0), "fases": fases.keys()}


func _b() -> void:
	await _combate({"Kael": 22, "Lya": 22, "Garon": 22}, 11)
	var r := await _jugar(60000)
	_ok(r["fin"], "B: el combate no termina")
	_ok(r["gana"], "B: tres héroes a nivel 22 con estrategia no ganan")
	_ok(r["fases"].size() == 3, "B: no pasa por las tres fases (%s)" % str(r["fases"]))
	_ok(c.enemigos.all(func(e): return e["hp"] <= 0), "B: quedan condenados vivos")
	await _esperar(30)
	_ok(c.heroes.all(func(h): return not h.has("hb_raices") and not h.has("hb_corrupcion") and not h.get("hb_agarrado", false)),
		"B: quedan estados de Humbaba en los héroes")
	hechos.append("B: gana=%s fases=%s contador=%s" % [r["gana"], str(r["fases"]), str(_hb().get("hb_contador", {}))])
	await _cerrar()


func _c() -> void:
	await _combate({"Kael": 1, "Lya": 1}, 13)
	var r := await _jugar(30000)
	_ok(r["fin"] and not r["gana"], "C: la derrota no acaba (fin=%s gana=%s)" % [r["fin"], r["gana"]])
	hechos.append("C: derrota a nivel 1: fin=%s" % r["fin"])
	await _cerrar()


# ================================================================= V: el Gran Bosque con el interruptor apagado y encendido

func _v() -> void:
	_limpiar()
	for encendido in [false, true]:
		if encendido:
			Engine.set_meta(H.INTERRUPTOR, true)
		change_scene_to_file("res://zonas3d/gran_bosque_3d.tscn")
		await _esperar(20)
		var z = current_scene
		_ok(z != null and z.has_method("piezas_al_alcance"), "V: no abre el Gran Bosque 3D")
		if z == null:
			continue
		var tiene: bool = z.get("humbaba") != null
		var pieza: bool = z.piezas_al_alcance().any(func(p): return p[0] == "humbaba")
		var nodo: bool = z.find_child("Humbaba", false, false) != null
		if encendido:
			_ok(tiene and pieza and nodo, "V: con el interruptor no está en el santuario (%s %s %s)" % [tiene, pieza, nodo])
		else:
			_ok(not tiene and not pieza and not nodo, "V: apagado, el santuario cambia (%s %s %s)" % [tiene, pieza, nodo])
		hechos.append("V: Gran Bosque con el interruptor %s: Humbaba %s" % ["encendido" if encendido else "apagado", "sí" if tiene else "no"])
	Engine.remove_meta(H.INTERRUPTOR)
	if current_scene != null:
		current_scene.queue_free()
	await _esperar(5)
