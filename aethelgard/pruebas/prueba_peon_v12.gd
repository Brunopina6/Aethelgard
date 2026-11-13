extends SceneTree
# V12, bestiario (13/11/2026): e01 · el Peón de Linde en combates de verdad (combate_peon.gd, sus ganchos de combate.gd y
# sonido.gd y enemigos/peon_linde/peon_linde.glb). Sin ventana, con datos aislados; la partida apunta a su propio archivo.
#   U. Sin escena: interruptor «enemigos_v12» apagado por defecto y fuera de la partida; apagado, preparar() no cambia
#      nada y grupo_al_azar() nunca da sus grupos (ni tira dados); encendido, solo en la llanura y en el grupo de su
#      tamaño; sus 8 claves de sonido (QOA mono 48 kHz, < 2,5 s, con su fila de procedencia); el modelo: 20 clips (los 18
#      del documento por su equivalencia y los 2 del ATB), duraciones del documento ±1/30 s, instantes iguales en el JSON
#      y en el guion de Godot, presupuesto de triángulos y huesos (22 deformantes base + estacas ≤ 32).
#   S. Apagado, un grupo forzado (22) trae al Peón sin su personalidad; encendido, con la suya y su modelo 3D.
#   A. Kael 4, Lya 2 y Garon 1 (niveles reales de PV-06; vida ×3 solo aquí, para ver muchos turnos) contra tres Peones,
#      con estrategia de jugador (defender la Zancada, golpear al que la prepara, Garon cubre a Lya, curar). En cada turno
#      suyo: Piquete y Zancada, un impacto y todo el daño en ese fotograma (±1), el golpe de siempre una vez y su sonido
#      propio una vez en el impacto; la Zancada, al marcado y al de detrás a la vez, tras su aviso y un turno de héroe; la
#      Estaca, el sonido al soltar y el daño AL LLEGAR (entre 6 y 14 fotogramas después) con su sonido de llegada; el
#      aviso y el repliegue sin daño; nunca tres ataques seguidos sin repliegue, aviso o recuperación.
#   B. Controlado: Zancada sin defender / defendiendo / con la Guardia de Garon, el de detrás y el Retroceso del ATB (no a
#      quien defiende ni a quien tiene el turno en la cola); cortada por daño y por Quiebra (aturdido, pierde el turno, la
#      rotura suena una vez, no la vuelve a preparar en su turno siguiente); Estaca sin defender / defendiendo / con la
#      Guardia; repliegue tras dos ataques y flanco; herida fuerte y ligera; derrota con su derrumbe una vez.
#   C. 1, 2 y 3 héroes con los niveles reales de incorporación (Kael solo 1 y 3; Kael 3 y Lya 1; Kael 4, Lya 2 y Garon 1),
#      automáticos: terminan (y cuántos ganan).
#   D. Encendido, un encuentro al azar de la llanura (sin grupo forzado) que sale con Peones.
#   E. Derrota (sin premio) y huida; al cerrar, sin nodos ni sonidos suyos colgando.
#   Q. Equilibrio frente a los encuentros de siempre de su tamaño (Zarzalín; Grimfang y Slime; Slime, Grimfang y Slime),
#      6 semillas, solo ataques automáticos (caso pesimista: no prueba la estrategia de un jugador).
# Con «fotos=<carpeta>» (y ventana) guarda fotogramas (JPG, uno de cada dos) del A y del B para los vídeos (indice.txt).

const ARCHIVO := "user://prueba_peon_v12.save"
const MAX_FOTOGRAMAS := 16000
const CLAVES_SONIDO := ["peon_linde_entrada", "peon_linde_ataque", "peon_linde_lanzar", "peon_estaca",
	"peon_linde_zancada", "peon_carga", "peon_rota", "peon_derrumbe"]
const PDF := {"spawn": 1.0, "idle": 2.0, "alert": 0.6, "walk_fwd": 1.0, "run_fwd": 0.7, "strafe_l": 1.0, "strafe_r": 1.0,
	"turn_l": 0.5, "turn_r": 0.5, "hit_front": 0.35, "hit_back": 0.35, "stagger": 0.8, "death": 1.4, "despawn": 0.6,
	"attack_01": 1.25, "attack_02": 1.70, "attack_03": 1.90, "retreat_step": 0.65}
var PE
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
	PE = load("res://combate_peon.gd")
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
	process_frame.connect(_vigilar)                       # (también mientras se espera un turno directamente)
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
			PE.INTERRUPTOR]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(10)
	S = root.get_node_or_null("Sonido")
	huerfanos0 = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_u()
	_u_v2()
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
	_ok(not PE.ACTIVO_POR_DEFECTO and not PE.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not PE.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "peon_linde", "personalidad": "agresivo"}
	PE.preparar(e)
	_ok(e["personalidad"] == "agresivo" and not PE.es(e), "U: apagado, preparar() cambia al Peón")
	var suyos: Array = PE.GRUPOS_POR_TAMANO.values()
	for i in suyos:
		_ok(C.GRUPOS[i].all(func(g): return g[0] == PE.CLAVE), "U: GRUPOS[%d] no son Peones" % i)
	for n in [1, 2, 3]:
		Engine.set_meta("zona", "llanura")
		for s in 300:
			seed(s)
			var i: int = C.grupo_al_azar(n)
			var r1 := randi()
			seed(s)
			var esperado: Array = C.AL_AZAR_POR_TAMANO.get(n, [])
			var j: int = esperado[randi() % esperado.size()] if not esperado.is_empty() else randi() % C.GRUPOS_AL_AZAR
			var r2 := randi()
			_ok(not i in suyos and i == j and r1 == r2, "U: apagado, el azar de los encuentros cambia (%d héroes, semilla %d)" % [n, s])
	Engine.set_meta(PE.INTERRUPTOR, true)
	PE.preparar(e)
	var g := {"clave": "grimfang", "personalidad": "agresivo"}
	PE.preparar(g)
	_ok(PE.es(e) and not PE.es(g), "U: encendido, preparar() no pone «peon_linde» solo al Peón")
	for n in [1, 2, 3]:
		var vistos := 0
		Engine.set_meta("zona", "llanura")
		for s in 200:
			seed(s)
			var i: int = C.grupo_al_azar(n)
			if i in suyos:
				vistos += 1
				_ok(i == PE.GRUPOS_POR_TAMANO[n], "U: con %d héroes sale el grupo %d" % [n, i])
		_ok(vistos > 20 and vistos < 90, "U: encendido, con %d héroes salen %d de 200 (≈ 25 %%)" % [n, vistos])
		Engine.set_meta("zona", "bosque")
		for s in 100:
			seed(s)
			_ok(not C.grupo_al_azar(n) in suyos, "U: encendido, sale fuera de la llanura")
	Engine.remove_meta(PE.INTERRUPTOR)
	Engine.remove_meta("zona")
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
	for k in PE.SONIDOS.values():
		_ok(Son.EFECTOS.has(k), "U: combate_peon.gd pide «%s», que no existe" % k)
	_ok(Son.familia({"hero": false, "clave": "peon_linde"}) == "piedra", "U: su voz no es la de piedra")
	# el modelo
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/peon_linde/peon_linde_clips.json"))
	_ok(j["clips"].size() == 20, "U: el JSON tiene %d clips (18 del documento + 2 del ATB)" % j["clips"].size())
	var tri := int(j["triangulos"])
	_ok(tri >= 3000 and tri <= 6000, "U: %d triángulos (presupuesto LOD0 3000-6000)" % tri)
	_ok(int(j["deformantes"]) >= 22 and int(j["deformantes"]) <= 32, "U: %d huesos deformantes" % int(j["deformantes"]))
	for k in PDF:
		var clip := str(j["mapa_pdf"].get(k, ""))
		_ok(j["clips"].has(clip), "U: el clip del documento «%s» (%s) no está" % [k, clip])
		if j["clips"].has(clip):
			_ok(absf(float(j["clips"][clip]["duracion"]) - PDF[k]) <= 1.0 / 30.0 + 0.001,
				"U: «%s» dura %.3f y el documento pide %.2f" % [clip, float(j["clips"][clip]["duracion"]), PDF[k]])
	var p = load("res://enemigos/peon_linde/peon_linde_3d.gd").new()
	root.add_child(p)
	_ok(p.anim != null and p.anim.get_animation_list().size() == 20, "U: el GLB no trae 20 clips")
	for clip in j["clips"]:
		_ok(p.tiene(clip), "U: el GLB no tiene «%s»" % clip)
		if not p.tiene(clip):
			continue
		_ok(absf(p.duracion(clip) - float(j["clips"][clip]["duracion"])) < 0.04, "U: «%s» dura %.2f en Godot" % [clip, p.duracion(clip)])
		var bucle: bool = p.anim.get_animation(clip).loop_mode != Animation.LOOP_NONE
		_ok(bucle == bool(j["clips"][clip]["bucle"]), "U: «%s» bucle %s" % [clip, bucle])
		for k in j["clips"][clip]["eventos"]:
			_ok(absf(p.instante(clip, k) - float(j["clips"][clip]["eventos"][k])) < 0.002, "U: «%s» sin su instante %s" % [clip, k])
	_ok(p.skel != null and p.skel.find_bone("arma.R") >= 0 and p.skel.find_bone("dedos.L") >= 0, "U: faltan huesos del rig base")
	p.queue_free()
	hechos.append("U interruptor y azar (apagado igual), grupos 22-24, 8 sonidos con procedencia, modelo (%d triángulos, %d deformantes, 20 clips con duraciones e instantes)" % [
		tri, int(j["deformantes"])])



# V2 (13/11, segunda pasada de arte): al lado de la v1, mismos huesos, clips, duraciones e instantes; dentro del
# presupuesto; el juego carga la v2 (con su mapa de normales salvo en calidad baja) y, con «bestiario_v1», la v1.
func _u_v2() -> void:
	var j1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/peon_linde/peon_linde_clips.json"))
	var j2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/peon_linde/peon_linde_v2_clips.json"))
	_ok(int(j2["triangulos"]) <= 6000, "U v2: %d triángulos (tope 6000)" % int(j2["triangulos"]))
	_ok(int(j2["deformantes"]) == int(j1["deformantes"]) and int(j2["huesos"]) == int(j1["huesos"]), "U v2: cambia el esqueleto")
	_ok(j2["clips"].keys() == j1["clips"].keys(), "U v2: no tiene los mismos clips")
	for c in j1["clips"]:
		if j2["clips"].has(c):
			_ok(j2["clips"][c]["duracion"] == j1["clips"][c]["duracion"] and j2["clips"][c]["eventos"] == j1["clips"][c]["eventos"],
				"U v2: «%s» cambia de duración o de instantes" % c)
	_ok(float(j2["alto_m"]) < float(j1.get("alto_m", 9.0)) or float(j1.get("alto_m", 9.0)) <= 0.0, "U v2: no es más compacto")
	for v in [2, 1]:
		Engine.set_meta("bestiario_v1", v == 1)
		var p = load("res://enemigos/peon_linde/peon_linde_3d.gd").new()
		root.add_child(p)
		_ok(p.version == v and p.anim != null and p.anim.get_animation_list().size() == 20, "U v2: no carga la v%d entera" % v)
		var con_normales := false
		for mi in p.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var mat := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
				if mat != null and mat.normal_enabled and mat.normal_texture != null:
					con_normales = true
		_ok(con_normales == (v == 2 and p.calidad_usada != "bajo"), "U v2: normales en la v%d (%s, calidad %s)" % [v, con_normales, p.calidad_usada])
		p.queue_free()
	Engine.remove_meta("bestiario_v1")
	hechos.append("U v2 (%d triángulos, %.2f m frente a %.2f m de la v1, mismos clips e instantes, normales) y v1 elegible" % [
		int(j2["triangulos"]), float(j2["alto_m"]), float(j1.get("alto_m", 0.0))])

# ================================================================= un combate

func _combate(activos: Dictionary, grupo: int, semilla: int, encendido := true, zona := "llanura") -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", "normal")
	if grupo >= 0:
		Engine.set_meta("grupo_combate", grupo)
	if encendido:
		Engine.set_meta(PE.INTERRUPTOR, true)
	seed(semilla)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)
	for e in c.enemigos:
		var p = c._p3d(e)
		if PE.es(e):
			_ok(p != null and p.has_method("zancada"), "%s: no tiene su modelo" % e["nombre"])
			if p != null:
				p.impacto.connect(func(a): impactos.append([a, Engine.get_process_frames(), e["nombre"]]))
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
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2500:
		await process_frame
	_ok(not _suena_suyo(), "al cerrar el combate sigue sonando algo del Peón")
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


func _peones() -> Array:
	return c.enemigos.filter(func(e): return PE.es(e))


func _cont(e: Dictionary) -> Dictionary:
	return (e.get("pl_contador", {}) as Dictionary).duplicate()


func _golpes_sonados() -> int:
	if S == null:
		return 0
	return int(S.contador.get("golpe", 0)) + int(S.contador.get("golpe_defendido", 0)) + int(S.contador.get("golpe_critico", 0))


func _foto_estado(e) -> Dictionary:
	var hp := {}
	for h in c.heroes:
		hp[h["nombre"]] = h["hp"]
	return {"hp": hp, "cont": _cont(e) if e is Dictionary else {}, "sonidos": sonidos.size(), "impactos": impactos.size(),
		"danos": danos.size(), "golpes": _golpes_sonados(), "turnos_heroe": c.turnos_heroe,
		"rig": e["rig"].position if e is Dictionary and e.has("rig") else Vector2.ZERO, "esquivas": c.ultimo_esquivado}


func _jugar(estrategia: String, comprobar := true) -> Dictionary:
	var r := {"acciones": [], "gana": false, "fin": false, "cortados": 0, "por_peon": {}}
	var quien = null
	var ant := {}
	var previo := {}
	var f_fin := -1
	var decidido := -1
	var ultimos := {}
	var rig_max := 0.0
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		var actual = c.atacante_actual
		if quien != null and PE.es(quien) and quien.has("rig"):
			rig_max = maxf(rig_max, quien["rig"].position.distance_to(ant.get("rig", quien["rig"].position)))
		if quien != null and not is_same(actual, quien):
			if PE.es(quien):
				var que := _que_hizo(quien, ant)
				r["acciones"].append(que)
				var lista: Array = r["por_peon"].get(quien["nombre"], [])
				lista.append(que)
				r["por_peon"][quien["nombre"]] = lista
				if comprobar:
					_comprobar_turno(quien, que, ant, ultimos.get(quien["nombre"], []), rig_max)
				ultimos[quien["nombre"]] = [que, c.turnos_heroe]
			quien = null
		if actual != null and quien == null:
			quien = actual
			ant = _foto_estado(actual) if previo.is_empty() else previo["base"].duplicate()
			if not previo.is_empty():
				ant["cont"] = previo["conts"].get(actual["nombre"], {})
				ant["rig"] = previo["rigs"].get(actual["nombre"], Vector2.ZERO)
			rig_max = 0.0
		if c.atacante_actual == null:                     # lo de antes de que empiece el turno siguiente
			var conts := {}
			var rigs := {}
			for e in c.enemigos:
				conts[e["nombre"]] = _cont(e)
				rigs[e["nombre"]] = e["rig"].position if e.has("rig") else Vector2.ZERO
			previo = {"base": _foto_estado(null), "conts": conts, "rigs": rigs}
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
	for e in _peones():
		r["cortados"] += int(_cont(e).get("zancada_cortada", 0))
	if comprobar:
		for nombre in r["por_peon"]:
			var seguidos := 0
			for a in r["por_peon"][nombre]:
				seguidos = seguidos + 1 if a in ["piquete", "estaca", "zancada"] else 0
				_ok(seguidos <= PE.RACHA_MAX, "%s: %d ataques seguidos sin pausa (%s)" % [nombre, seguidos, str(r["por_peon"][nombre])])
	return r


func _que_hizo(e: Dictionary, ant: Dictionary) -> String:
	var antes: Dictionary = ant["cont"]
	var ahora := _cont(e)
	for k in ["recupera", "repliegue", "zancada", "aviso_zancada", "estaca", "piquete"]:
		if int(ahora.get(k, 0)) > int(antes.get(k, 0)):
			return k
	if e.get("huido", false):
		return "huye"
	return "otro"


func _comprobar_turno(e: Dictionary, que: String, ant: Dictionary, ultimo: Array, movido: float) -> void:
	var dn: Array = danos.slice(ant["danos"])
	var golpeados := {}
	for d in dn:
		golpeados[d[0]] = int(golpeados.get(d[0], 0)) + int(d[2])
	var imp: Array = impactos.slice(ant["impactos"]).filter(func(i): return i[2] == e["nombre"])
	var son: Array = sonidos.slice(ant["sonidos"])
	var cuenta := func(n: String) -> Array: return son.filter(func(s): return s[0] == n)
	var golpes: int = _golpes_sonados() - int(ant["golpes"])
	var n := "%s (%s)" % [e["nombre"], que]
	var esquivo: bool = c.ultimo_esquivado
	match que:
		"piquete", "zancada":
			var clip: String = {"piquete": "ataque", "zancada": "zancada"}[que]
			var clave: String = {"piquete": "peon_linde_ataque", "zancada": "peon_linde_zancada"}[que]
			_ok(imp.size() == 1 and imp[0][0] == clip, "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1 or esquivo, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			var s: Array = cuenta.call(clave)
			_ok(s.size() == 1 and imp.size() == 1 and absi(int(s[0][1]) - int(imp[0][1])) <= 1, "%s: su sonido no suena una vez en el impacto (%s)" % [n, str(s)])
			if imp.size() == 1:
				for d in dn:
					_ok(absi(int(d[1]) - int(imp[0][1])) <= 1, "%s: %s recibe daño en el %d y el impacto es en el %d" % [n, d[0], d[1], imp[0][1]])
			if que == "piquete":
				_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
			else:
				_ok(golpeados.size() <= 2, "%s: alcanza a más de dos (%s)" % [n, str(golpeados)])
				_ok(ultimo.size() == 2 and ultimo[0] == "aviso_zancada", "%s: sin aviso (%s)" % [n, str(ultimo)])
				if ultimo.size() == 2:
					_ok(int(ant["turnos_heroe"]) > int(ultimo[1]), "%s: sin un turno de héroe entre el aviso y el golpe" % n)
		"estaca":
			_ok(imp.size() == 1 and imp[0][0] == "lanzar", "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1 or esquivo, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
			_ok(movido < 2.0, "%s: se mueve %.1f px (lanza desde su sitio)" % [n, movido])
			var sl: Array = cuenta.call("peon_linde_lanzar")
			var st: Array = cuenta.call("peon_estaca")
			_ok(sl.size() == 1 and imp.size() == 1 and absi(int(sl[0][1]) - int(imp[0][1])) <= 1, "%s: el lanzamiento no suena al soltar (%s)" % [n, str(sl)])
			_ok(st.size() == 1, "%s: la llegada suena %d veces" % [n, st.size()])
			if imp.size() == 1 and not dn.is_empty():
				var vuelo: int = int(dn[0][1]) - int(imp[0][1])
				_ok(vuelo >= 6 and vuelo <= 14, "%s: el daño cae %d fotogramas después de soltar (debe ser el vuelo)" % [n, vuelo])
				if st.size() == 1:
					_ok(absi(int(st[0][1]) - int(dn[0][1])) <= 1, "%s: la llegada no suena con el daño" % n)
		"aviso_zancada":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño al avisar" % n)
			_ok(cuenta.call("peon_carga").size() == 1, "%s: el aviso no suena una vez" % n)
			if e["hp"] > 0 and e.get("cargando", false):
				_ok(e.has("aviso_nodo") and e.has("pl_marca"), "%s: sin la señal de aviso o la marca" % n)
		"recupera", "repliegue":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño sin atacar" % n)
		"huye":
			pass
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
	var cargando: Array = _peones().filter(func(e): return e["hp"] > 0 and e.get("cargando", false))
	var t: Dictionary = cargando[0] if not cargando.is_empty() else alc[0]
	var marcado := false
	for e in cargando:
		var o = e.get("pl_objetivo", null)
		if o is Dictionary and (is_same(o, a) or is_same(PE.vecino(c, o), a)):
			marcado = true
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.45)
		if not heridos.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Cura"][0]["coste"]):
			c._elegir_hechizo("Cura", 1, true)
			return
		if marcado:
			c._defender()
			return
	if a["nombre"] == "Garon" and cargando.is_empty() and a["mp"] >= c.GUARDIA["coste"]:
		var lya = c.heroes.filter(func(h): return h["nombre"] == "Lya" and h["hp"] > 0)
		if not lya.is_empty() and str(lya[0].get("guardia_de", "")) == "":
			c._guardia(lya[0])                               # la Estaca va a la retaguardia: Garon cubre a Lya
			return
	if marcado and cargando.is_empty() == false and a["nombre"] != "Kael":
		c._defender()
		return
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(t)


# ================================================================= S

func _s() -> void:
	await _combate({"Kael": 3}, 22, 3, false)
	var z: Dictionary = c.enemigos[0]
	_ok(z["clave"] == "peon_linde" and not PE.es(z) and z["personalidad"] == "agresivo",
		"S: apagado, el grupo forzado no trae al Peón sin su personalidad")
	c.estado = "fin"
	await _cerrar()
	await _combate({"Kael": 3}, 22, 3, true)
	z = c.enemigos[0]
	_ok(PE.es(z) and z["modelo"] == "peon_linde" and c._p3d(z) != null, "S: encendido, no es el suyo con su modelo")
	hechos.append("S apagado: «agresivo» (solo si se fuerza su grupo); encendido: «peon_linde» (vida %d, ataque %d en la llanura)" % [
		z["hp_max"], z["atk"]])
	c.estado = "fin"
	await _cerrar()


# ================================================================= A

func _a() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 4, "Lya": 2, "Garon": 1}, 24, 5)
	_ok(_peones().size() == 3, "A: el grupo 24 no son tres Peones")
	for z in _peones():
		z["hp_max"] *= 3
		z["hp"] = z["hp_max"]
	_marca_video("A_inicio")
	grabando = fotos != ""
	var r := await _jugar("jugador")
	grabando = false
	_ok(r["fin"], "A: no termina (%s)" % str(r["acciones"]))
	_ok(r["acciones"].size() >= 6, "A: el combate es demasiado corto: %s" % str(r["acciones"]))
	for k in ["piquete"]:                                  # (Estaca y Zancada, a la fuerza en el B: el A depende del azar)
		_ok(k in r["acciones"], "A: no se vio «%s» (%s)" % [k, str(r["acciones"])])
	await _esperar(200)
	if r["gana"]:
		_ok(Inv.oro() >= oro0 + 14, "A: las monedas no llegan (%d → %d)" % [oro0, Inv.oro()])
		var der: Array = sonidos.filter(func(s): return s[0] == "peon_derrumbe")
		_ok(der.size() == 3, "A: el derrumbe suena %d veces (tres Peones)" % der.size())
	var guardado := JSON.stringify(P.volcar())
	_ok(not guardado.contains("pl_") and not guardado.contains(PE.INTERRUPTOR), "A: la partida guardaría claves suyas")
	hechos.append("A jugador (Kael 4, Lya 2, Garon 1; tres Peones ×3 de vida) %s: %s; Zancadas cortadas %d, cubiertos %d, turnos de héroe %d" % [
		"gana" if r["gana"] else "pierde", ",".join(r["acciones"]), r["cortados"], c.cubiertos, c.turnos_heroe])
	await _cerrar()


# ================================================================= B

func _b() -> void:
	await _combate({"Kael": 4, "Lya": 2, "Garon": 1}, 22, 9)
	await _esperar(80)
	c.estado = "fin"
	grabando = fotos != ""
	var z: Dictionary = _peones()[0]
	z["hp_max"] = 2000
	z["hp"] = 2000
	var p = c._p3d(z)
	var kael: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var lya: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	var garon: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Garon")[0]
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var cura := func():
		for h in c.heroes:
			h["hp_max"] = maxi(h["hp_max"], 400)
			h["hp"] = h["hp_max"]
			h["defendiendo"] = false
			h["atb"] = 50.0
			h.erase("guardia_de")
			h.erase("curo")
		c.cola.clear()
		z["recupera"] = false
		z["pl_aturdido"] = false
		z["pl_racha"] = 0
		z["pl_replegado"] = false
	# Piquete
	cura.call()
	_marca_video("B_piquete")
	var n_imp := impactos.size()
	await PE._piquete(c, z, vivos, 1.0)
	_ok(impactos.size() == n_imp + 1, "B: el Piquete no tiene un impacto")
	await _esperar(20)
	# Estaca: sin defender, defendiendo y con la Guardia de Garon
	var d := {}
	for caso in ["sin", "defiende", "guardia"]:
		cura.call()
		_marca_video("B_estaca_" + caso)
		lya["curo"] = true
		if caso == "defiende":
			lya["defendiendo"] = true
		if caso == "guardia":
			lya["guardia_de"] = "Garon"
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		seed(60)
		await PE._estaca(c, z, vivos, 1.0)
		var quien := "Garon" if caso == "guardia" else "Lya"
		d[caso] = antes[quien] - (garon if caso == "guardia" else lya)["hp"]
		var otros: Array = c.heroes.filter(func(h): return h["nombre"] != quien and antes[h["nombre"]] != h["hp"])
		_ok(otros.is_empty(), "B estaca %s: alcanza a otros" % caso)
		await _esperar(20)
	_ok(d["sin"] > 0 and d["defiende"] <= d["sin"] * 0.6 + 1, "B: defender no deja la Estaca a la mitad (%d frente a %d)" % [d["defiende"], d["sin"]])
	_ok(d["guardia"] > 0, "B: con la Guardia, Garon no se lleva la Estaca")
	cura.call()
	z["pl_ultimo"] = "estaca"
	for s in 40:
		seed(s)
		_ok(PE._elegir(z) != "estaca", "B: dos Estacas seguidas (semilla %d)" % s)
	# Zancada: aviso, el marcado y el de detrás, Retroceso; sin defender, defendiendo, con Guardia
	var dz := {}
	for caso in ["sin", "defiende", "guardia"]:
		cura.call()
		_marca_video("B_zancada_" + caso)
		await PE._avisar(c, z, vivos)
		_ok(z.get("cargando", false) and p.clip_actual() in ["carga", "carga_espera"], "B: el aviso no deja la carga (%s)" % p.clip_actual())
		z["pl_objetivo"] = kael                             # Kael marcado: el de detrás es Lya
		var detras: Dictionary = PE.vecino(c, kael)
		_ok(is_same(detras, lya), "B: el de detrás de Kael no es Lya (%s)" % detras.get("nombre", "nadie"))
		if caso == "defiende":
			kael["defendiendo"] = true
			lya["defendiendo"] = true
		if caso == "guardia":
			kael["guardia_de"] = "Garon"
		var antes := {}
		var atb0 := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
			atb0[h["nombre"]] = h["atb"]
		var n0 := danos.size()
		n_imp = impactos.size()
		seed(70)
		await PE.turno(c, z, vivos, 1.0)
		_ok(impactos.size() == n_imp + 1, "B zancada %s: impactos %d" % [caso, impactos.size() - n_imp])
		var principal := "Garon" if caso == "guardia" else "Kael"
		var tocados: Array = c.heroes.filter(func(h): return antes[h["nombre"]] > h["hp"]).map(func(h): return h["nombre"])
		_ok(principal in tocados and "Lya" in tocados, "B zancada %s: no alcanza al marcado y al de detrás (%s)" % [caso, str(tocados)])
		var fr: Array = danos.slice(n0).map(func(x): return x[1])
		_ok(not fr.is_empty() and fr.max() - fr.min() <= 1, "B zancada %s: no caen en el mismo fotograma (%s)" % [caso, str(fr)])
		dz[caso] = antes[principal] - (garon if caso == "guardia" else kael)["hp"]
		dz[caso + "_detras"] = antes["Lya"] - lya["hp"]
		if caso == "defiende":
			_ok(kael["atb"] == atb0["Kael"] and lya["atb"] == atb0["Lya"], "B: defendiendo, la Zancada empuja la barra ATB")
		else:
			_ok(c.heroes.filter(func(h): return h["nombre"] in tocados).all(func(h): return h["atb"] < atb0[h["nombre"]]),
				"B zancada %s: sin Retroceso en la barra ATB" % caso)
		await _esperar(30)
	_ok(dz["defiende"] <= dz["sin"] * 0.6 + 1 and dz["defiende_detras"] <= dz["sin_detras"] * 0.6 + 1,
		"B: defender no deja la Zancada a la mitad (%s)" % str(dz))
	_ok(dz["sin_detras"] < dz["sin"], "B: el de detrás recibe tanto como el marcado (%s)" % str(dz))
	# Retroceso: nunca a quien ya tiene el turno en la cola
	cura.call()
	kael["atb"] = c.ATB_MAX
	c.cola.append(kael)
	_ok(not PE.retroceso(c, kael), "B: el Retroceso toca a quien tiene el turno en la cola")
	c.cola.clear()
	# cortada por daño y por Quiebra
	cura.call()
	_marca_video("B_zancada_cortada")
	await PE._avisar(c, z, vivos)
	await c._animar_golpe(kael, z, int(ceil(z["hp_max"] * C.UMBRAL_INTERRUPCION)) + 5, "")
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: un cuarto de su vida no corta la Zancada")
	await _esperar(40)
	_ok(p.clip_actual() == "aturdido", "B: cortada no se tambalea (%s)" % p.clip_actual())
	var hp0 := {}
	for h in c.heroes:
		hp0[h["nombre"]] = h["hp"]
	await PE.turno(c, z, vivos, 1.0)
	_ok(c.heroes.all(func(h): return h["hp"] == hp0[h["nombre"]]) and not z.get("recupera", false), "B: aturdido no pierde el turno")
	_ok(sonidos.filter(func(s): return s[0] == "peon_rota").size() == 1, "B: la rotura no suena una vez")
	for s in 40:
		seed(s)
		_ok(PE._elegir(z) != "zancada", "B: vuelve a preparar la Zancada justo después de cortársela (semilla %d)" % s)
	cura.call()
	await PE._avisar(c, z, vivos)
	c.golpe_ruptura = true
	await c._animar_golpe(kael, z, 10, "")
	c.golpe_ruptura = false
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: Quiebra no corta la Zancada")
	await PE.turno(c, z, vivos, 1.0)
	# repliegue tras dos ataques y flanco
	cura.call()
	_marca_video("B_repliegue")
	z["pl_racha"] = PE.RACHA_MAX
	var cont0 := _cont(z)
	for h in c.heroes:
		hp0[h["nombre"]] = h["hp"]
	await PE.turno(c, z, vivos, 1.0)
	_ok(int(_cont(z).get("repliegue", 0)) == int(cont0.get("repliegue", 0)) + 1 and z.get("pl_replegado", false),
		"B: tras dos ataques no se repliega")
	_ok(c.heroes.all(func(h): return h["hp"] == hp0[h["nombre"]]), "B: el repliegue hace daño")
	lya["curo"] = true
	_ok(is_same(PE._objetivo(c, z, vivos), lya), "B: tras replegarse no busca el flanco (la curandera)")
	lya.erase("curo")
	# herida fuerte y ligera
	await _esperar(40)
	c._golpe_visual(z, c._quitar_pv(z, int(z["hp_max"] * 0.2)), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe" and p.anim.speed_scale < 1.0, "B: un golpe grande no alarga la herida (%s, %.2f)" % [p.clip_actual(), p.anim.speed_scale])
	await _esperar(60)
	c._golpe_visual(z, c._quitar_pv(z, 5), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe" and p.anim.speed_scale == 1.0, "B: un golpe pequeño no pone la herida de siempre")
	hechos.append("B Estaca %d, defendida %d, con Guardia (a Garon) %d; Zancada al marcado %d y al de detrás %d, defendiendo %d y %d, con Guardia %d; Retroceso; cortada por daño y por Quiebra; repliegue y flanco; heridas" % [
		d["sin"], d["defiende"], d["guardia"], dz["sin"], dz["sin_detras"], dz["defiende"], dz["defiende_detras"], dz["guardia"]])
	await _esperar(40)
	_marca_video("B_derrota")
	c.estado = "esperando"
	z["hp"] = 1
	c._quitar_pv(z, 1)
	c._golpe_visual(z, 1, "")
	await _esperar(150)
	_ok(sonidos.filter(func(s): return s[0] == "peon_derrumbe").size() == 1, "B: el derrumbe no suena una vez")
	grabando = false
	await _cerrar()


# ================================================================= C, D, E

func _c() -> void:
	for caso in [[{"Kael": 1}, 22, 21], [{"Kael": 3}, 22, 22], [{"Kael": 3, "Lya": 1}, 23, 13],
			[{"Kael": 4, "Lya": 2, "Garon": 1}, 24, 31]]:
		await _combate(caso[0], caso[1], caso[2])
		var r := await _jugar("auto")
		_ok(r["fin"], "C %s: no termina (%s)" % [str(caso[0]), str(r["acciones"])])
		hechos.append("C %s contra GRUPOS[%d], automático: %s, %s" % [str(caso[0]), caso[1], "gana" if r["gana"] else "pierde",
			",".join(r["acciones"])])
		await _cerrar()


func _d() -> void:
	# Encuentros al azar de verdad (sin grupo forzado): con el interruptor, en la llanura, alguno de los primeros 24 arranques
	# trae su grupo (uno de cada cuatro); los demás, los de siempre. (No se predice la semilla desde fuera: el arranque
	# del combate gasta azar antes de elegir el grupo.)
	var vistos := 0
	var semilla := -1
	var otros := 0
	for s in 24:
		await _combate({"Kael": 4, "Lya": 2, "Garon": 1}, -1, 900 + s, true, "llanura")
		var n := _peones().size()
		if n > 0:
			_ok(n == 3, "D: su encuentro trae %d de los suyos" % n)
			vistos += 1
			if semilla < 0:
				semilla = 900 + s
				var r := await _jugar("auto")
				_ok(r["fin"], "D: no termina")
		else:
			otros += 1
		c.estado = "fin"
		await _cerrar()
	_ok(vistos >= 1 and otros >= 1, "D: en 24 encuentros al azar de la llanura, %d con Peones y %d de siempre" % [vistos, otros])
	hechos.append("D encuentros al azar de la llanura con el interruptor: %d de 24 con Peones (el primero, semilla %d, jugado)" % [vistos, semilla])


func _e() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 1, "Lya": 1}, 23, 3)
	for z in _peones():
		z["atk"] = 120
		z["hp_max"] = 4000
		z["hp"] = 4000
	var r := await _jugar("auto", false)
	_ok(r["fin"] and not r["gana"], "E: con nivel 1 no pierde o no acaba (%s)" % str(r["acciones"]))
	await _esperar(120)
	_ok(Inv.oro() <= oro0, "E: perdiendo da monedas")
	hechos.append("E derrota: %s" % ",".join(r["acciones"]))
	await _cerrar()
	await _combate({"Kael": 4, "Lya": 2, "Garon": 1}, 24, 4)
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
	_ok(_peones().all(func(e): return not e.has("pl_marca")), "E: queda una marca tras huir")
	hechos.append("E huida")
	await _cerrar()


# ================================================================= Q

func _q() -> void:
	for caso in [[{"Kael": 2}, 10, 22], [{"Kael": 3, "Lya": 1}, 3, 23], [{"Kael": 4, "Lya": 2, "Garon": 1}, 2, 24]]:
		var res := {}
		for encendido in [false, true]:
			var gana := 0
			var perdidos := 0
			var turnos := 0
			for s in 6:
				await _combate(caso[0], caso[2] if encendido else caso[1], 700 + s, encendido)
				var pv0 := 0
				for h in c.heroes:
					pv0 += int(h["hp_max"])
				var r := await _jugar("auto", false)
				gana += 1 if r["gana"] else 0
				perdidos += pv0 - int(r.get("pv_fin", 0))
				turnos += c.turnos_heroe
				await _cerrar()
			res[encendido] = [gana, perdidos / 6, turnos / 6]
			hechos.append("Q %s GRUPOS[%d]: gana %d/6, PV perdidos de media %d, turnos de héroe %d" % [
				str(caso[0].values()), caso[2] if encendido else caso[1], gana, perdidos / 6, turnos / 6])
		var a: Array = res[false]
		var n: Array = res[true]
		_ok(n[0] >= a[0] - 1, "Q %s: con Peones gana %d/6 y con lo de siempre %d/6" % [str(caso[0]), n[0], a[0]])
		_ok(n[1] <= a[1] * 1.6 + 25, "Q %s: con Peones se pierden %d PV de media y con lo de siempre %d" % [str(caso[0]), n[1], a[1]])


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
