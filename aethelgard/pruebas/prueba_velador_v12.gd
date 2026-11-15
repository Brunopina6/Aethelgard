extends SceneTree
# V12, bestiario (13/11/2026): e02 · el Velador de Corteza en combates de verdad (combate_velador.gd, sus ganchos de
# combate.gd y sonido.gd y enemigos/velador_corteza/velador_corteza.glb). Sin ventana, con datos aislados. Misma forma que
# prueba_peon_v12.gd (de la que se copian el combate, el registro de daño y el bucle de turnos).
#   U. Interruptor apagado por defecto y fuera de la partida; apagado, el azar de los encuentros no cambia; encendido,
#      solo en el bosque y en el grupo de su tamaño; 9 sonidos (QOA mono 48 kHz, con procedencia); el modelo: 20 clips
#      (los 18 del documento ±1/30 s y 2 del ATB), instantes iguales en el JSON y en Godot, presupuesto.
#   S. Apagado, un grupo forzado (25) lo trae sin su personalidad; encendido, con la suya, su modelo y EN GUARDIA.
#   A. Kael 5, Lya 4 y Garon 4 (nivel del bosque; vida ×3 solo aquí) contra él, Grimfang y un Slime, con estrategia de
#      jugador. En cada turno suyo: Mazazo y Empuje, un impacto, el daño y su sonido en ese fotograma (±1), el golpe de
#      siempre una vez; la Raíz tras su aviso y un turno de héroe, con el daño en el instante en que brotan las raíces;
#      el aviso sin daño.
#   B. Controlado: la guardia (dos golpes a la mitad; al segundo se abre con su sonido una vez; el tercero entra entero;
#      vuelve tras su turno siguiente); Mazazo y Empuje sin defender y defendiendo, el Retroceso del Empuje; la Raíz sin
#      defender / defendiendo / con la Guardia de Garon, cortada por daño y por Quiebra; herida fuerte; derrota.
#   C. 1, 2 y 3 héroes a nivel del bosque, automáticos.  D. Un encuentro al azar del bosque con el interruptor.
#   E. Derrota y huida.  Q. Equilibrio frente a los encuentros de siempre de su tamaño, en el bosque.
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que la semilla se pone DESPUÉS de
# root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos con ella (como prueba_combate_huella.gd). Antes se
# sembraba antes de add_child y A, C, E y Q eran combates al azar. Cada combate imprime «SEMILLA» y una línea «TRAZA» por
# turno; «semilla_A=N» (o _C, _D, _E, _Q) cambia la semilla de ese caso. D sigue eligiendo el grupo al azar (a propósito).

const ARCHIVO := "user://prueba_velador_v12.save"
const MAX_FOTOGRAMAS := 16000
const CLAVES_SONIDO := ["velador_corteza_entrada", "velador_corteza_ataque", "velador_corteza_empuje", "velador_corteza_raiz",
	"velador_bloqueo", "velador_abre", "velador_carga", "velador_rota", "velador_derrumbe"]
const PDF := {"spawn": 1.0, "idle": 2.0, "alert": 0.6, "walk_fwd": 1.0, "run_fwd": 0.7, "strafe_l": 1.0, "strafe_r": 1.0,
	"turn_l": 0.5, "turn_r": 0.5, "hit_front": 0.35, "hit_back": 0.35, "stagger": 0.8, "death": 1.4, "despawn": 0.6,
	"attack_01": 1.80, "attack_02": 1.50, "attack_03": 2.20, "guard_loop": 1.2}
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
	PE = load("res://combate_velador.gd")
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



# V2 (13/11, segunda pasada de arte): al lado de la v1, mismos huesos, clips, duraciones e instantes; dentro del
# presupuesto; el juego carga la v2 (con su mapa de normales salvo en calidad baja) y, con «bestiario_v1», la v1.
func _u_v2() -> void:
	var j1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/velador_corteza/velador_corteza_clips.json"))
	var j2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/velador_corteza/velador_corteza_v2_clips.json"))
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
		var p = load("res://enemigos/velador_corteza/velador_corteza_3d.gd").new()
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
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)                                     # (aquí su _ready hace randomize() y, sin grupo, lo elige)
	seed(semilla)                                         # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                         # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA %d · %s · grupo %d · %s · %s" % [semilla, str(activos), grupo, "encendido" if encendido else "apagado",
		",".join(c.enemigos.map(func(e): return e["nombre"]))])
	for e in c.enemigos:
		var p = c._p3d(e)
		if PE.es(e):
			_ok(p != null and p.has_method("raiz"), "%s: no tiene su modelo" % e["nombre"])
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
	await _esperar(75)                                    # 2,5 s de juego a 30 fotogramas por segundo
	# (el audio sin ventana avanza con el reloj real, no con los fotogramas: si aún suena algo suyo, se le dan hasta 5 s
	# reales para acabar. Antes se esperaban siempre 2,5 s reales.)
	var t0 := Time.get_ticks_msec()
	while _suena_suyo() and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	_ok(not _suena_suyo(), "al cerrar el combate sigue sonando algo del Velador")
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


func _peones() -> Array:                                   # (los Veladores del combate)
	return c.enemigos.filter(func(e): return PE.es(e))


func _cont(e: Dictionary) -> Dictionary:
	return (e.get("vl_contador", {}) as Dictionary).duplicate()


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
				_traza("%s: %s" % [quien["nombre"], que])
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
			_traza("%s: %s" % [c.actor["nombre"], _decidir(estrategia)])
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
		r["cortados"] += int(_cont(e).get("raiz_cortada", 0))
	_traza("fin %s · gana %s" % [r["fin"], r["gana"]])
	return r


# Una línea por turno: fotograma, quién y qué, y los PV de todos (para reproducir una semilla concreta).
func _traza(que: String) -> void:
	var pv := []
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA %05d T%d %s · %s" % [Engine.get_process_frames(), c.turnos_heroe, que, ", ".join(pv)])


# «semilla_A=N» (o _C, _D, _E, _Q) en la línea de órdenes cambia la semilla de ese caso.
func _semilla(caso: String, defecto: int) -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla_%s=" % caso):
			return int(a.get_slice("=", 1))
	return defecto



# ================================================================= U

func _u() -> void:
	_limpiar()
	_ok(not PE.ACTIVO_POR_DEFECTO and not PE.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not PE.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "velador_corteza", "personalidad": "agresivo"}
	PE.preparar(e)
	_ok(e["personalidad"] == "agresivo" and not PE.es(e) and not e.has("defendiendo"), "U: apagado, preparar() cambia al Velador")
	var suyos: Array = PE.GRUPOS_POR_TAMANO.values()
	for i in suyos:
		_ok(C.GRUPOS[i][0][0] == PE.CLAVE, "U: GRUPOS[%d] no empieza por el Velador" % i)
	for n in [1, 2, 3]:
		Engine.set_meta("zona", "bosque")
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
	_ok(PE.es(e) and e.get("defendiendo", false), "U: encendido, preparar() no lo pone en guardia")
	for n in [1, 2, 3]:
		var vistos := 0
		Engine.set_meta("zona", "bosque")
		for s in 200:
			seed(s)
			var i: int = C.grupo_al_azar(n)
			if i in suyos:
				vistos += 1
				_ok(i == PE.GRUPOS_POR_TAMANO[n], "U: con %d héroes sale el grupo %d" % [n, i])
		_ok(vistos > 20 and vistos < 90, "U: encendido, con %d héroes salen %d de 200" % [n, vistos])
		Engine.set_meta("zona", "llanura")
		for s in 100:
			seed(s)
			_ok(not C.grupo_al_azar(n) in suyos, "U: encendido, sale fuera del bosque")
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
		_ok(Son.EFECTOS.has(k), "U: combate_velador.gd pide «%s», que no existe" % k)
	_ok(Son.familia({"hero": false, "clave": "velador_corteza"}) == "corteza", "U: su voz no es la de corteza")
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/velador_corteza/velador_corteza_clips.json"))
	_ok(j["clips"].size() == 20, "U: el JSON tiene %d clips" % j["clips"].size())
	var tri := int(j["triangulos"])
	_ok(tri >= 2500 and tri <= 6000, "U: %d triángulos" % tri)
	_ok(int(j["deformantes"]) >= 22 and int(j["deformantes"]) <= 32, "U: %d huesos deformantes" % int(j["deformantes"]))
	for k in PDF:
		var clip := str(j["mapa_pdf"].get(k, ""))
		_ok(j["clips"].has(clip), "U: el clip del documento «%s» (%s) no está" % [k, clip])
		if j["clips"].has(clip):
			_ok(absf(float(j["clips"][clip]["duracion"]) - PDF[k]) <= 1.0 / 30.0 + 0.001,
				"U: «%s» dura %.3f y el documento pide %.2f" % [clip, float(j["clips"][clip]["duracion"]), PDF[k]])
	var p = load("res://enemigos/velador_corteza/velador_corteza_3d.gd").new()
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
	p.guardia(true)
	p.queue_free()
	hechos.append("U interruptor y azar (apagado igual), grupos 25-27, 9 sonidos con procedencia, modelo (%d triángulos, %d deformantes, 20 clips)" % [
		tri, int(j["deformantes"])])



func _que_hizo(e: Dictionary, ant: Dictionary) -> String:
	var antes: Dictionary = ant["cont"]
	var ahora := _cont(e)
	for k in ["recupera", "raiz", "aviso_raiz", "empuje", "mazazo"]:
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
		"mazazo", "empuje", "raiz":
			var clip: String = {"mazazo": "ataque", "empuje": "empuje", "raiz": "raiz"}[que]
			var clave: String = "velador_corteza_" + clip
			_ok(imp.size() == 1 and imp[0][0] == clip, "%s: impactos %s" % [n, str(imp)])
			_ok(golpes == 1 or esquivo, "%s: el golpe de siempre suena %d veces" % [n, golpes])
			var s: Array = cuenta.call(clave)
			_ok(s.size() == 1 and imp.size() == 1 and absi(int(s[0][1]) - int(imp[0][1])) <= 1, "%s: su sonido no suena una vez en el impacto (%s)" % [n, str(s)])
			if imp.size() == 1:
				for d in dn:
					_ok(absi(int(d[1]) - int(imp[0][1])) <= 1, "%s: %s recibe daño en el %d y el impacto es en el %d" % [n, d[0], d[1], imp[0][1]])
			_ok(golpeados.size() <= 1, "%s: alcanza a %s" % [n, str(golpeados)])
			if que == "raiz":
				_ok(movido < 2.0, "%s: se mueve %.1f px (las raíces brotan desde su sitio)" % [n, movido])
				_ok(ultimo.size() == 2 and ultimo[0] == "aviso_raiz", "%s: sin aviso (%s)" % [n, str(ultimo)])
				if ultimo.size() == 2:
					_ok(int(ant["turnos_heroe"]) > int(ultimo[1]), "%s: sin un turno de héroe entre el aviso y el golpe" % n)
		"aviso_raiz":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño al avisar" % n)
			_ok(cuenta.call("velador_carga").size() == 1, "%s: el aviso no suena una vez" % n)
			if e["hp"] > 0 and e.get("cargando", false):
				_ok(e.has("aviso_nodo") and e.has("vl_marca") and not e.get("defendiendo", false), "%s: sin señal, sin marca o en guardia" % n)
		"recupera":
			_ok(golpeados.is_empty() and imp.is_empty(), "%s: hace daño sin atacar" % n)
		"huye":
			pass
		_:
			_ok(e["hp"] <= 0, "%s: hizo algo desconocido" % n)
	if e["hp"] > 0 and que in ["mazazo", "empuje", "raiz"] and not e.get("cargando", false):
		_ok(e.get("defendiendo", false) or e.get("vl_abierta", false), "%s: tras su turno no vuelve a la guardia" % n)


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
	var vs: Array = _peones().filter(func(e): return e["hp"] > 0)
	var v: Dictionary = vs[0] if not vs.is_empty() else {}
	var otros: Array = alc.filter(func(e): return not PE.es(e))
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.45)
		if not heridos.is_empty() and c._puede_pagar(c.NIVELES_MAGIA["Cura"][0]["coste"]):
			c._elegir_hechizo("Cura", 1, true)
			return "Cura"
		var o = v.get("vl_objetivo", null)
		if v.get("cargando", false) and o is Dictionary and is_same(o, a):
			c._defender()
			return "defender (Raíz)"
	if a["nombre"] == "Garon" and not v.is_empty() and not v.get("cargando", false) and a["mp"] >= c.GUARDIA["coste"]:
		var lya = c.heroes.filter(func(h): return h["nombre"] == "Lya" and h["hp"] > 0)
		if not lya.is_empty() and str(lya[0].get("guardia_de", "")) == "":
			c._guardia(lya[0])
			return "Guardia a Lya"
	# contra la guardia: si está en guardia y hay otros enemigos, a ellos; si no, a él (dos golpes la abren)
	var t: Dictionary = alc[0]
	if not v.is_empty() and (v.get("vl_abierta", false) or v.get("cargando", false) or otros.is_empty()):
		t = v
	elif not otros.is_empty():
		t = otros[0]
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(t)
	return "atacar a %s" % t["nombre"]


# ================================================================= S

func _s() -> void:
	await _combate({"Kael": 5}, 25, 3, false, "bosque")
	var z: Dictionary = c.enemigos[0]
	_ok(z["clave"] == "velador_corteza" and not PE.es(z) and not z.get("defendiendo", false),
		"S: apagado, el grupo forzado no lo trae sin su personalidad")
	c.estado = "fin"
	await _cerrar()
	await _combate({"Kael": 5}, 25, 3, true, "bosque")
	z = c.enemigos[0]
	_ok(PE.es(z) and z["modelo"] == "velador_corteza" and c._p3d(z) != null and z.get("defendiendo", false),
		"S: encendido, no es el suyo con su modelo y en guardia")
	await _esperar(90)
	_ok(c._p3d(z).clip_actual() == "guardia_espera", "S: en guardia no tiene la pose de guardia (%s)" % c._p3d(z).clip_actual())
	hechos.append("S apagado: «agresivo» (solo si se fuerza su grupo); encendido: «velador_corteza» en guardia (vida %d, ataque %d en el bosque)" % [
		z["hp_max"], z["atk"]])
	c.estado = "fin"
	await _cerrar()


# ================================================================= A

func _a() -> void:
	await _combate({"Kael": 5, "Lya": 4, "Garon": 4}, 27, _semilla("A", 5), true, "bosque")
	var v: Dictionary = _peones()[0]
	v["hp_max"] *= 3
	v["hp"] = v["hp_max"]
	_marca_video("A_inicio")
	grabando = fotos != ""
	var r := await _jugar("jugador")
	grabando = false
	_ok(r["fin"], "A: no termina (%s)" % str(r["acciones"]))
	_ok(r["acciones"].size() >= 5, "A: el combate es demasiado corto: %s" % str(r["acciones"]))
	for k in ["mazazo"]:                                   # (Empuje y Raíz, a la fuerza en el B: el A depende del azar)
		_ok(k in r["acciones"], "A: no se vio «%s» (%s)" % [k, str(r["acciones"])])
	var cont := _cont(v)
	_ok(int(cont.get("bloqueo", 0)) > 0 and int(cont.get("guardia_abierta", 0)) > 0, "A: la guardia no paró golpes ni se abrió (%s)" % str(cont))
	await _esperar(200)
	var guardado := JSON.stringify(P.volcar())
	_ok(not guardado.contains("vl_") and not guardado.contains(PE.INTERRUPTOR), "A: la partida guardaría claves suyas")
	hechos.append("A jugador (Kael 5, Lya 4, Garon 4; él ×3 de vida, con Grimfang y un Slime) %s: %s; golpes parados %d, guardia abierta %d veces, Raíces cortadas %d" % [
		"gana" if r["gana"] else "pierde", ",".join(r["acciones"]), int(cont.get("bloqueo", 0)), int(cont.get("guardia_abierta", 0)),
		int(cont.get("raiz_cortada", 0))])
	await _cerrar()


# ================================================================= B

func _b() -> void:
	await _combate({"Kael": 5, "Lya": 4, "Garon": 4}, 25, 9, true, "bosque")
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
		z["vl_aturdido"] = false
	# la guardia: dos golpes a la mitad, el segundo la abre, el tercero entero; vuelve tras su turno
	cura.call()
	_marca_video("B_guardia")
	_ok(z.get("defendiendo", false), "B: no empieza en guardia")
	var golpes := []
	for i in 3:
		var hp0: int = z["hp"]
		seed(4)                                           # (la misma tirada de crítico en los tres)
		await c._animar_golpe(kael, z, 40, "")
		await _esperar(20)
		golpes.append(hp0 - z["hp"])
	_ok(golpes[0] <= golpes[2] * 0.6 + 1 and golpes[1] <= golpes[2] * 0.6 + 1, "B: la guardia no deja los dos primeros a la mitad (%s)" % str(golpes))
	_ok(z.get("vl_abierta", false) and not z.get("defendiendo", false), "B: tras dos golpes la guardia no se abre")
	_ok(sonidos.filter(func(s): return s[0] == "velador_abre").size() == 1, "B: la guardia abierta no suena una vez")
	_ok(sonidos.filter(func(s): return s[0] == "velador_bloqueo").size() == 1, "B: el primer golpe parado no suena una vez")
	_ok(p.clip_actual() != "guardia_espera" or not p.en_guardia, "B: abierta sigue con la pose de guardia")
	seed(5)
	z["vl_ultimo"] = "raiz"                               # (que no prepare la Raíz aquí)
	await PE.turno(c, z, vivos, 1.0)
	_ok(z.get("defendiendo", false) and not z.get("vl_abierta", false), "B: tras su turno no vuelve a la guardia")
	# Mazazo y Empuje, sin defender y defendiendo; el Retroceso del Empuje
	var d := {}
	for ataque in ["mazazo", "empuje"]:
		for caso in ["sin", "defiende"]:
			cura.call()
			_marca_video("B_%s_%s" % [ataque, caso])
			kael["curo"] = true
			if caso == "defiende":
				for h in c.heroes:
					h["defendiendo"] = true
			var antes := {}
			for h in c.heroes:
				antes[h["nombre"]] = [h["hp"], h["atb"]]
			var n0 := impactos.size()
			seed(80)
			if ataque == "mazazo":
				await PE._mazazo(c, z, vivos, 1.0)
			else:
				await PE._empuje(c, z, vivos, 1.0)
			_ok(impactos.size() == n0 + 1, "B %s %s: impactos %d" % [ataque, caso, impactos.size() - n0])
			var tocados: Array = c.heroes.filter(func(h): return h["hp"] < antes[h["nombre"]][0])
			_ok(tocados.size() == 1, "B %s %s: alcanza a %d" % [ataque, caso, tocados.size()])
			if tocados.size() == 1:
				var h: Dictionary = tocados[0]
				d[ataque + "_" + caso] = antes[h["nombre"]][0] - h["hp"]
				if ataque == "empuje":
					_ok((h["atb"] < antes[h["nombre"]][1]) == (caso == "sin"), "B empuje %s: Retroceso %s → %s" % [caso, antes[h["nombre"]][1], h["atb"]])
			await _esperar(20)
	for ataque in ["mazazo", "empuje"]:
		_ok(d.get(ataque + "_defiende", 99) <= d.get(ataque + "_sin", 0) * 0.6 + 1, "B: defender no deja el %s a la mitad (%s)" % [ataque, str(d)])
	# la Raíz: aviso sin guardia, sin defender / defendiendo / con la Guardia de Garon
	var dr := {}
	for caso in ["sin", "defiende", "guardia"]:
		cura.call()
		_marca_video("B_raiz_" + caso)
		z["vl_corte_turno"] = -10
		await PE._avisar(c, z, vivos)
		_ok(z.get("cargando", false) and not z.get("defendiendo", false) and p.clip_actual() in ["carga", "carga_espera"],
			"B: el aviso de la Raíz no deja la carga sin guardia (%s)" % p.clip_actual())
		z["vl_objetivo"] = lya
		if caso == "defiende":
			lya["defendiendo"] = true
		if caso == "guardia":
			lya["guardia_de"] = "Garon"
		var antes := {}
		for h in c.heroes:
			antes[h["nombre"]] = h["hp"]
		var rig0: Vector2 = z["rig"].position
		seed(90)
		await PE.turno(c, z, vivos, 1.0)
		var quien: Dictionary = garon if caso == "guardia" else lya
		dr[caso] = antes[quien["nombre"]] - quien["hp"]
		_ok(dr[caso] > 0 and c.heroes.filter(func(h): return h["hp"] < antes[h["nombre"]]).size() == 1, "B raíz %s: no alcanza solo a %s" % [caso, quien["nombre"]])
		_ok(z["rig"].position.distance_to(rig0) < 2.0, "B raíz %s: se mueve" % caso)
		await _esperar(30)
	_ok(dr["defiende"] <= dr["sin"] * 0.6 + 1, "B: defender no deja la Raíz a la mitad (%s)" % str(dr))
	# cortada por daño y por Quiebra
	cura.call()
	_marca_video("B_raiz_cortada")
	z["vl_corte_turno"] = -10
	await PE._avisar(c, z, vivos)
	await c._animar_golpe(kael, z, int(ceil(z["hp_max"] * C.UMBRAL_INTERRUPCION)) + 5, "")
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: un cuarto de su vida no corta la Raíz")
	await _esperar(40)
	_ok(p.clip_actual() == "aturdido", "B: cortada no se tambalea (%s)" % p.clip_actual())
	var hp1 := {}
	for h in c.heroes:
		hp1[h["nombre"]] = h["hp"]
	await PE.turno(c, z, vivos, 1.0)
	_ok(c.heroes.all(func(h): return h["hp"] == hp1[h["nombre"]]) and not z.get("recupera", false), "B: aturdido no pierde el turno")
	_ok(sonidos.filter(func(s): return s[0] == "velador_rota").size() == 1, "B: la rotura no suena una vez")
	cura.call()
	z["vl_corte_turno"] = -10
	await PE._avisar(c, z, vivos)
	c.golpe_ruptura = true
	await c._animar_golpe(kael, z, 10, "")
	c.golpe_ruptura = false
	_ok(not z.get("cargando", false) and z.get("recupera", false), "B: Quiebra no corta la Raíz")
	await PE.turno(c, z, vivos, 1.0)
	# herida fuerte
	await _esperar(40)
	z["defendiendo"] = false
	c._golpe_visual(z, c._quitar_pv(z, int(z["hp_max"] * 0.2)), "")
	await _esperar(2)
	_ok(p.clip_actual() == "recibir_golpe" and p.anim.speed_scale < 1.0, "B: un golpe grande no alarga la herida")
	hechos.append("B guardia %s (los dos primeros a la mitad, el tercero entero); Mazazo %d / defendido %d; Empuje %d / %d con Retroceso; Raíz %d / defendida %d / con Guardia %d; cortada por daño y por Quiebra" % [
		str(golpes), d.get("mazazo_sin", 0), d.get("mazazo_defiende", 0), d.get("empuje_sin", 0), d.get("empuje_defiende", 0),
		dr["sin"], dr["defiende"], dr["guardia"]])
	await _esperar(40)
	_marca_video("B_derrota")
	c.estado = "esperando"
	z["hp"] = 1
	c._quitar_pv(z, 1)
	c._golpe_visual(z, 1, "")
	await _esperar(150)
	_ok(sonidos.filter(func(s): return s[0] == "velador_derrumbe").size() == 1, "B: el derrumbe no suena una vez")
	grabando = false
	await _cerrar()


# ================================================================= C, D, E, Q

func _c() -> void:
	for caso in [[{"Kael": 4}, 25, 21], [{"Kael": 5, "Lya": 4}, 26, 13], [{"Kael": 5, "Lya": 4, "Garon": 4}, 27, 31]]:
		await _combate(caso[0], caso[1], caso[2] + _semilla("C", 0), true, "bosque")
		var r := await _jugar("auto")
		_ok(r["fin"], "C %s: no termina (%s)" % [str(caso[0]), str(r["acciones"])])
		hechos.append("C %s contra GRUPOS[%d], automático: %s, %s" % [str(caso[0]), caso[1], "gana" if r["gana"] else "pierde",
			",".join(r["acciones"])])
		await _cerrar()


func _d() -> void:
	# Encuentros al azar de verdad (sin grupo forzado): con el interruptor, en el bosque, alguno de los primeros 24 arranques
	# trae su grupo (uno de cada cuatro); los demás, los de siempre. (No se predice la semilla desde fuera: el arranque
	# del combate gasta azar antes de elegir el grupo.)
	# 15/11: el grupo lo elige combate._ready tras su randomize() (no se puede fijar sin «-- semilla=N», que fijaría
	# también los 24 arranques iguales): sale al azar. Para que no falle por mala suerte (0,75^24 ≈ 0,1 % sin ninguno),
	# si en 24 no se han visto los dos tipos se sigue hasta 48 (0,75^48 ≈ 1 en un millón). Lo demás de cada combate, con
	# su semilla (tras add_child).
	var vistos := 0
	var semilla := -1
	var otros := 0
	var hechos_d := 0
	for s in 48:
		if s >= 24 and vistos >= 1 and otros >= 1:
			break
		hechos_d += 1
		await _combate({"Kael": 5, "Lya": 4, "Garon": 4}, -1, _semilla("D", 900) + s, true, "bosque")
		var n := _peones().size()
		if n > 0:
			_ok(n == 1, "D: su encuentro trae %d de los suyos" % n)
			vistos += 1
			if semilla < 0:
				semilla = 900 + s
				var r := await _jugar("auto")
				_ok(r["fin"], "D: no termina")
		else:
			otros += 1
		c.estado = "fin"
		await _cerrar()
	_ok(vistos >= 1 and otros >= 1, "D: en %d encuentros al azar del bosque, %d con el Velador y %d de siempre" % [hechos_d, vistos, otros])
	hechos.append("D encuentros al azar del bosque con el interruptor: %d de %d con el Velador (el primero, semilla %d, jugado)" % [vistos, hechos_d, semilla])


func _e() -> void:
	var oro0: int = Inv.oro()
	await _combate({"Kael": 1, "Lya": 1}, 26, _semilla("E", 3), true, "bosque")
	for z in _peones():
		z["atk"] = 140
		z["hp_max"] = 4000
		z["hp"] = 4000
	var r := await _jugar("auto", false)
	_ok(r["fin"] and not r["gana"], "E: con nivel 1 no pierde o no acaba (%s)" % str(r["acciones"]))
	await _esperar(120)
	_ok(Inv.oro() <= oro0, "E: perdiendo da monedas")
	hechos.append("E derrota: %s" % ",".join(r["acciones"]))
	await _cerrar()
	await _combate({"Kael": 5, "Lya": 4, "Garon": 4}, 27, _semilla("E", 3) + 1, true, "bosque")
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


func _q() -> void:
	for caso in [[{"Kael": 4}, 9, 25], [{"Kael": 5, "Lya": 4}, 3, 26], [{"Kael": 5, "Lya": 4, "Garon": 4}, 2, 27]]:
		var res := {}
		for encendido in [false, true]:
			var gana := 0
			var perdidos := 0
			var turnos := 0
			for s in 6:
				await _combate(caso[0], caso[2] if encendido else caso[1], _semilla("Q", 700) + s, encendido, "bosque")
				var pv0 := 0
				for h in c.heroes:
					pv0 += int(h["hp_max"])
				var r := await _jugar("auto", false)
				gana += 1 if r["gana"] else 0
				perdidos += pv0 - int(r.get("pv_fin", 0))
				turnos += c.turnos_heroe
				await _cerrar()
			res[encendido] = [gana, perdidos / 6, turnos / 6]
			hechos.append("Q %s GRUPOS[%d] (bosque): gana %d/6, PV perdidos de media %d, turnos de héroe %d" % [
				str(caso[0].values()), caso[2] if encendido else caso[1], gana, perdidos / 6, turnos / 6])
		var a: Array = res[false]
		var n: Array = res[true]
		_ok(n[0] >= a[0] - 1, "Q %s: con el Velador gana %d/6 y con lo de siempre %d/6" % [str(caso[0]), n[0], a[0]])
		_ok(n[1] <= a[1] * 1.6 + 25, "Q %s: con el Velador se pierden %d PV de media y con lo de siempre %d" % [str(caso[0]), n[1], a[1]])


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
