extends SceneTree
# V12, fase 9 (14/11/2026, PILOTO): meshy_e01 · el Custodio de Porcelana (combate_meshy_e01.gd, sus ganchos «V12,
# Custodio» de combate.gd y recursos.gd, y enemigos/meshy_e01/meshy_e01.glb). Sin ventana, con datos aislados.
#   U. Interruptor propio apagado por defecto y fuera de la partida; apagado o encendido, el azar de los encuentros no
#      cambia y nunca da sus grupos (28 y 29); su carpeta fuera de la precarga mientras va apagado.
#   M. El modelo en Godot: 3 clips propios (nombres, duraciones, bucles), los alias del juego son el MISMO recurso,
#      24 huesos (21 con piel), 10 541 triángulos, ≤ 4 influencias, 1,85 m, mira a +Z; en la Prensa: manos delante y a ras
#      de suelo en el impacto, pies quietos y cadera que baja ≤ 15 % de la altura; instantes iguales en el JSON y el guion.
#   S. Apagado, un grupo forzado (28) lo trae sin su personalidad; encendido, con la suya y su modelo.
#   A. Encendido, Kael, Lya y Garon (sin ATB propio: solo actúa él) contra él: Prensa (aviso → fija a 0,65 → impacto a
#      0,90 en el reloj del clip; marca fija que no persigue; daño al elegido y al de detrás UNA vez cada uno, en el
#      fotograma del impacto; Retroceso del 15 % sin defender; deduplicación attack_instance_id + target_id), dos turnos
#      de guardia (recarga de 2 turnos propios, golpes a la mitad) y otra Prensa contra un elegido que defiende.
#   B. Muerte durante el aviso: no golpea, la marca se va y el combate acaba con victoria y sin nodos suyos.
#   C. Velocidad de animación ×2 a media Prensa: el impacto sigue al reloj del clip (llega antes) y golpea una vez.
#   D. Cerrar el combate en mitad de la Prensa (cambio de escena): sin errores ni nodos huérfanos.

const ARCHIVO := "user://prueba_meshy_e01.save"
const MAX_FOTOGRAMAS := 2400
var PE
var C
var P
var G
var c = null
var fallos: Array = []
var hechos: Array = []
var impactos: Array = []
var danos: Array = []
var hp_prev := {}
var marca_frames: Array = []
var huerfanos0 := -1
var custodio: Dictionary = {}


func _initialize() -> void:
	PE = load("res://combate_meshy_e01.gd")
	C = load("res://combate.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	process_frame.connect(_vigilar)
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
			PE.INTERRUPTOR, "enemigos_v12"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(10)
	huerfanos0 = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_u()
	await _m()
	await _s()
	await _a()
	await _b()
	await _c()
	await _d()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
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
	var e := {"clave": "meshy_e01", "personalidad": "agresivo"}
	PE.preparar(e)
	_ok(e["personalidad"] == "agresivo" and not PE.es(e), "U: apagado, preparar() cambia al Custodio")
	for i in PE.GRUPOS_PRUEBA:
		_ok(C.GRUPOS[i][0][0] == PE.CLAVE, "U: GRUPOS[%d] no empieza por el Custodio" % i)
	_ok(C.GRUPOS.size() == 30, "U: GRUPOS tiene %d entradas (28 de antes y las 2 suyas)" % C.GRUPOS.size())
	var apagados: Dictionary = load("res://recursos.gd").APAGADOS
	_ok(apagados.get("res://enemigos/meshy_e01/", "") == PE.INTERRUPTOR, "U: su carpeta se precargaría apagado")
	for encendido in [false, true]:
		if encendido:
			Engine.set_meta(PE.INTERRUPTOR, true)
		for zona in ["llanura", "bosque", "desierto"]:
			Engine.set_meta("zona", zona)
			for n in [1, 2, 3]:
				for s in 120:
					seed(s)
					var i: int = C.grupo_al_azar(n)
					var r1 := randi()
					seed(s)
					var esperado: Array = C.AL_AZAR_POR_TAMANO.get(n, [])
					var j: int = esperado[randi() % esperado.size()] if not esperado.is_empty() else randi() % C.GRUPOS_AL_AZAR
					var r2 := randi()
					_ok(not i in PE.GRUPOS_PRUEBA and i == j and r1 == r2,
						"U: %s, el azar de los encuentros cambia (%s, %d héroes, semilla %d)" % [
						"encendido" if encendido else "apagado", zona, n, s])
	_limpiar()
	hechos.append("U: apagado por defecto, fuera de la partida y de la precarga; el azar no cambia (apagado y encendido, 1 080 tiradas)")


# ================================================================= M

func _m() -> void:
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://enemigos/meshy_e01/meshy_e01_clips.json"))
	var p = load("res://enemigos/meshy_e01/meshy_e01_3d.gd").new()
	root.add_child(p)
	await _esperar(2)
	_ok(p.anim != null and p.skel != null, "M: sin AnimationPlayer o esqueleto")
	if p.anim == null or p.skel == null:
		p.queue_free()
		return
	var propios: PackedStringArray = p.clips_propios()
	propios.sort()
	_ok(propios == PackedStringArray(["e01__attack_prensa", "e01__idle", "e01__walk"]), "M: clips %s" % [propios])
	for n in j["clips"]:
		var a: Animation = p.anim.get_animation(n)
		_ok(a != null and absf(a.length - float(j["clips"][n]["duracion"])) <= 1.0 / 30.0 + 0.001,
			"M: «%s» dura %.3f (JSON %.3f)" % [n, a.length if a != null else -1.0, float(j["clips"][n]["duracion"])])
	for alias in p.ALIAS:
		_ok(p.anim.get_animation(alias) == p.anim.get_animation(p.ALIAS[alias]), "M: el alias «%s» no es el mismo clip" % alias)
	_ok(p.anim.get_animation("reposo").loop_mode == Animation.LOOP_LINEAR and p.anim.get_animation("caminar").loop_mode == Animation.LOOP_LINEAR,
		"M: reposo y caminar no van en bucle")
	_ok(p.anim.get_animation("ataque").loop_mode == Animation.LOOP_NONE, "M: la Prensa va en bucle")
	_ok(p.skel.get_bone_count() == int(j["huesos"]), "M: %d huesos (JSON %d)" % [p.skel.get_bone_count(), int(j["huesos"])])
	var tris := 0
	var piel := 0
	var max_inf := 0
	var usados := {}                                     # huesos de la piel con algún peso (los deformantes)
	var aabb := AABB()
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.skin != null:
			piel = m3.skin.get_bind_count()
		for s in m3.mesh.get_surface_count():
			var arr: Array = m3.mesh.surface_get_arrays(s)
			tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
			var w: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			var bi: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var por := w.size() / maxi(1, (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
			for v in range(0, w.size(), por):
				var k := 0
				for q in por:
					if w[v + q] > 0.0001:
						k += 1
						usados[bi[v + q]] = true
				max_inf = maxi(max_inf, k)
		aabb = m3.get_aabb() if aabb.size == Vector3.ZERO else aabb.merge(m3.get_aabb())
	_ok(tris == int(j["triangulos"]), "M: %d triángulos (JSON %d)" % [tris, int(j["triangulos"])])
	# (el exportador glTF mete en la piel todas las articulaciones, también raíz y clavículas, que no tienen pesos)
	_ok(piel == int(j["huesos"]) and usados.size() == int(j["deformantes"]), "M: piel de %d, %d con pesos (JSON %d)" % [
		piel, usados.size(), int(j["deformantes"])])
	_ok(max_inf >= 1 and max_inf <= 4, "M: %d influencias por vértice" % max_inf)
	_ok(absf(aabb.size.y - 1.85) < 0.05, "M: mide %.3f m (1,85)" % aabb.size.y)
	for clip in ["ataque", "e01__attack_prensa"]:
		_ok(_mismos(p.EVENTOS[clip], j["clips"]["e01__attack_prensa"]["eventos"]), "M: instantes de %s distintos del JSON" % clip)
	_ok(absf(p.instante("ataque", "impacto") - PE.T_IMPACTO) < 0.001 and absf(p.instante("ataque", "fija_direccion") - PE.T_FIJA) < 0.001,
		"M: el guion del modelo y el del combate no tienen los mismos instantes")
	# poses horneadas, en el espacio del esqueleto (Godot: Y arriba, delante +Z)
	var b_mano: int = p.skel.find_bone("mano.L")
	var b_pie: int = p.skel.find_bone("pie.L")
	var b_cad: int = p.skel.find_bone("cadera")
	p.anim.play("reposo")
	p.anim.seek(0.0, true)
	var pie0: Vector3 = p.skel.get_bone_global_pose(b_pie).origin
	var cad0: float = p.skel.get_bone_global_pose(b_cad).origin.y
	var pie_mov := 0.0
	var cad_baja := 0.0
	for t in [0.6, 1.2, 1.8]:
		p.anim.seek(t, true)
		pie_mov = maxf(pie_mov, p.skel.get_bone_global_pose(b_pie).origin.distance_to(pie0))
	p.anim.play("ataque")
	for k in 25:
		var t := 2.4 * k / 24.0
		p.anim.seek(t, true)
		pie_mov = maxf(pie_mov, p.skel.get_bone_global_pose(b_pie).origin.distance_to(pie0))
		cad_baja = maxf(cad_baja, cad0 - p.skel.get_bone_global_pose(b_cad).origin.y)
	p.anim.seek(PE.T_IMPACTO, true)
	var mano: Vector3 = p.skel.get_bone_global_pose(b_mano).origin
	p.anim.seek(0.65, true)
	var mano_alta: Vector3 = p.skel.get_bone_global_pose(b_mano).origin
	_ok(pie_mov < 0.01, "M: el pie se mueve %.3f m en el reposo y la Prensa" % pie_mov)
	_ok(cad_baja > 0.1 and cad_baja <= 0.15 * 1.85 + 0.001, "M: la cadera baja %.3f m (máx. %.3f)" % [cad_baja, 0.15 * 1.85])
	_ok(mano.z > 0.3 and mano.y < 0.45, "M: en el impacto la muñeca está en %s (delante y abajo)" % [mano])
	_ok(mano_alta.y > 1.6, "M: a 0,65 s la muñeca está a %.2f m (puños por encima de los hombros)" % mano_alta.y)
	hechos.append("M: 3 clips (%s), alias = mismo recurso, %d huesos (%d con pesos), %d triángulos, %d influencias, %.2f m; Prensa: pie quieto (%.4f m), cadera −%.3f m (%.1f %%), muñeca en el impacto %s, a 0,65 s a %.2f m" % [
		", ".join(propios), p.skel.get_bone_count(), usados.size(), tris, max_inf, aabb.size.y, pie_mov, cad_baja, 100.0 * cad_baja / 1.85,
		mano, mano_alta.y])
	p.queue_free()
	await _esperar(2)


func _mismos(a: Dictionary, b: Dictionary) -> bool:
	for k in a:
		if not b.has(k) or absf(float(a[k]) - float(b[k])) > 0.001:
			return false
	return true


# ================================================================= un combate

func _combate(encendido: bool, grupo := 28) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 4
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	if encendido:
		Engine.set_meta(PE.INTERRUPTOR, true)
	seed(14112026)
	c = load("res://combate.tscn").instantiate()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	marca_frames.clear()
	root.add_child(c)
	custodio = {}
	for e in c.enemigos:
		if e["clave"] == "meshy_e01":
			custodio = e
	for h in c.heroes:                                   # nadie más actúa: solo él (las pruebas mandan sus turnos)
		h["vel"] = 0.0
		h["atb"] = 0.0
		h["hp_max"] = h["hp_max"] * 3
		h["hp"] = h["hp_max"]
	for e in c.enemigos:
		e["vel"] = 0.0
		e["atb"] = 0.0
	if custodio.is_empty():
		return
	var p = c._p3d(custodio)
	if p != null and p.has_signal("impacto"):
		p.impacto.connect(func(a): impactos.append([a, Engine.get_process_frames()]))
	for h in c.heroes:
		hp_prev[h["nombre"]] = h["hp"]
	await _esperar(20)


func _vigilar() -> void:
	if c == null or not is_instance_valid(c):
		return
	for h in c.heroes:
		var antes: int = hp_prev.get(h["nombre"], h["hp"])
		if h["hp"] < antes:
			danos.append([h["nombre"], Engine.get_process_frames(), antes - h["hp"]])
		hp_prev[h["nombre"]] = h["hp"]
	if not custodio.is_empty() and not PE.nodos_vivos(c.enemigos).is_empty():
		marca_frames.append(Engine.get_process_frames())


# Le da un turno (ATB al tope) y espera a que acabe. Devuelve el turno («prensa» o «guardia») y lo que pasó.
func _turno(antes_de_empezar := Callable(), durante := Callable()) -> Dictionary:
	var cont0: Dictionary = (custodio.get("e01_contador", {}) as Dictionary).duplicate()
	var imp0 := impactos.size()
	var dan0 := danos.size()
	custodio["vel"] = 10.0
	custodio["atb"] = c.ATB_MAX - 0.01
	if antes_de_empezar.is_valid():
		antes_de_empezar.call()
	var empezado := false
	var r := {"marca_pos": []}
	for fr in MAX_FOTOGRAMAS:
		await process_frame
		if not is_instance_valid(c):
			break
		if is_same(c.atacante_actual, custodio):
			empezado = true
			custodio["vel"] = 0.0
		var m = custodio.get("e01_marca", null)
		if m != null and is_instance_valid(m):
			var pos: Array = []
			for k in m.get_children():
				pos.append(k.position)
			r["marca_pos"].append(pos)
		if durante.is_valid():
			durante.call()
		if empezado and c.atacante_actual == null:
			break
		if c.estado == "fin":
			break
	await _esperar(5)
	var cont1: Dictionary = custodio.get("e01_contador", {})
	r["que"] = "prensa" if int(cont1.get("prensa", 0)) > int(cont0.get("prensa", 0)) else (
		"guardia" if int(cont1.get("guardia", 0)) > int(cont0.get("guardia", 0)) else "nada")
	r["impactos"] = impactos.slice(imp0)
	r["danos"] = danos.slice(dan0)
	return r


func _cerrar() -> void:
	if c != null and is_instance_valid(c):
		await _esperar(30)
		c.queue_free()
	c = null
	custodio = {}
	await _esperar(30)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(h <= huerfanos0, "al cerrar el combate hay %d nodos huérfanos (antes %d)" % [h, huerfanos0])
	_limpiar()


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


# ================================================================= S

func _s() -> void:
	await _combate(false)
	_ok(not custodio.is_empty() and not PE.es(custodio) and custodio["personalidad"] == "agresivo",
		"S: apagado, el grupo 28 lo trae con otra personalidad")
	await _cerrar()
	await _combate(true)
	var p = c._p3d(custodio) if not custodio.is_empty() else null
	_ok(PE.es(custodio) and p != null and p.has_method("prensa") and p.tiene("ataque"), "S: encendido, sin su personalidad o su modelo")
	await _cerrar()
	hechos.append("S: apagado, sin personalidad; encendido, con la suya y su modelo 3D")


# ================================================================= A

func _a() -> void:
	await _combate(true)
	if custodio.is_empty():
		return
	var kael := _heroe("Kael"); var lya := _heroe("Lya"); var garon := _heroe("Garon")
	# el elegido es el que menos vida tiene (Lya) y el de detrás en la formación, Garon
	kael["hp"] = kael["hp_max"]; lya["hp"] = int(lya["hp_max"] * 0.6); garon["hp"] = garon["hp_max"]
	for h in c.heroes:
		h["atb"] = 50.0
		hp_prev[h["nombre"]] = h["hp"]
	var r := await _turno()
	var at: Dictionary = custodio.get("e01_ultimo", {})
	_ok(r["que"] == "prensa", "A1: su primer turno no es la Prensa (%s)" % r["que"])
	_ok(r["impactos"].size() == 1, "A1: %d impactos (uno)" % r["impactos"].size())
	var por := {}
	for d in r["danos"]:
		por[d[0]] = por.get(d[0], []) + [d]
	_ok(por.has("Lya") and por["Lya"].size() == 1, "A1: Lya recibe %s golpes (uno)" % [por.get("Lya", []).size()])
	_ok(por.has("Garon") and por["Garon"].size() == 1, "A1: Garon (el de detrás) recibe %s golpes (uno)" % [por.get("Garon", []).size()])
	_ok(not por.has("Kael"), "A1: Kael, fuera de la fila, recibe daño")
	if r["impactos"].size() == 1 and por.has("Lya") and por.has("Garon"):
		var fi: int = r["impactos"][0][1]
		_ok(absi(por["Lya"][0][1] - fi) <= 1 and absi(por["Garon"][0][1] - fi) <= 1,
			"A1: el daño (%d, %d) no cae en el fotograma del impacto (%d)" % [por["Lya"][0][1], por["Garon"][0][1], fi])
		_ok(int(por["Garon"][0][2]) < int(por["Lya"][0][2]), "A1: el de detrás no recibe menos (%d frente a %d)" % [
			por["Garon"][0][2], por["Lya"][0][2]])
	_ok(at.get("golpeados", {}).size() == 2 and int(custodio["e01_contador"].get("duplicado_evitado", 0)) == 0,
		"A1: golpeados %s" % [at.get("golpeados", {})])
	_ok(int(at.get("t_aviso", -1)) > 0 and int(at.get("t_fija", -1)) > int(at["t_aviso"]) and int(at["t_impacto"]) > int(at["t_fija"]),
		"A1: orden aviso → fija → impacto: %s" % [at])
	var d_fija: int = int(at.get("t_fija", 0)) - int(at.get("t_aviso", 0))
	var d_imp: int = int(at.get("t_impacto", 0)) - int(at.get("t_aviso", 0))
	_ok(absi(d_fija - 20) <= 2 and absi(d_imp - 27) <= 2, "A1: fija a %d y golpea a %d fotogramas del aviso (20 y 27 a 30 fps)" % [d_fija, d_imp])
	var quietas := true
	for pos in r["marca_pos"]:
		if pos != r["marca_pos"][0]:
			quietas = false
	_ok(r["marca_pos"].size() >= d_imp - 3 and r["marca_pos"][0].size() == 2 and quietas,
		"A1: la marca (%d fotogramas, %d rectángulos) no está fija o no dura hasta el impacto" % [r["marca_pos"].size(),
		r["marca_pos"][0].size() if not r["marca_pos"].is_empty() else 0])
	_ok(PE.nodos_vivos(c.enemigos).is_empty(), "A1: la marca sigue tras el impacto")
	_ok(absf(lya["atb"] - 35.0) < 0.01 and absf(garon["atb"] - 35.0) < 0.01 and absf(kael["atb"] - 50.0) < 0.01,
		"A1: Retroceso (ATB Lya %.1f, Garon %.1f, Kael %.1f)" % [lya["atb"], garon["atb"], kael["atb"]])
	_ok(int(custodio["e01_cd"]) == PE.CD_TURNOS, "A1: recarga %d (2)" % int(custodio["e01_cd"]))
	var dano_lya_1: int = int(por["Lya"][0][2]) if por.has("Lya") else 0
	# dos turnos de guardia
	for k in 2:
		var g := await _turno()
		_ok(g["que"] == "guardia" and g["danos"].is_empty() and g["impactos"].is_empty(), "A%d: no es un turno de guardia sin daño (%s)" % [k + 2, g["que"]])
		_ok(custodio.get("defendiendo", false) and custodio.get("e01_guardia", false), "A%d: no queda en guardia" % [k + 2])
		_ok(int(custodio["e01_cd"]) == 1 - k, "A%d: recarga %d" % [k + 2, int(custodio["e01_cd"])])
	# otra Prensa contra Lya defendiendo: la mitad y sin Retroceso
	lya["defendiendo"] = true
	lya["atb"] = 50.0
	garon["atb"] = 50.0
	var r2 := await _turno()
	_ok(r2["que"] == "prensa" and not custodio.get("e01_guardia", false), "A5: tras dos guardias no vuelve la Prensa (%s)" % r2["que"])
	var por2 := {}
	for d in r2["danos"]:
		por2[d[0]] = por2.get(d[0], []) + [d]
	_ok(por2.get("Lya", []).size() == 1 and por2.get("Garon", []).size() == 1 and not por2.has("Kael"), "A5: golpes %s" % [por2])
	if por2.has("Lya"):
		_ok(int(por2["Lya"][0][2]) * 2 <= dano_lya_1 + 4, "A5: defendiendo, Lya recibe %d (antes %d)" % [por2["Lya"][0][2], dano_lya_1])
	_ok(absf(lya["atb"] - 50.0) < 0.01 and absf(garon["atb"] - 35.0) < 0.01, "A5: Retroceso con defensa (Lya %.1f, Garon %.1f)" % [lya["atb"], garon["atb"]])
	_ok(custodio["e01_ultimo"]["id"] != at.get("id", -1), "A5: la segunda Prensa reutiliza el attack_instance_id")
	hechos.append("A: Prensa (aviso → fija %d f → impacto %d f; marca fija %d f; Lya −%d y Garon −%d una vez en el impacto; Retroceso 15 %%), 2 guardias (recarga 2 → 0), Prensa contra Lya defendiendo (−%d, sin Retroceso)" % [
		d_fija, d_imp, r["marca_pos"].size(), dano_lya_1, int(por.get("Garon", [[0, 0, 0]])[0][2]),
		int(por2.get("Lya", [[0, 0, 0]])[0][2])])
	await _cerrar()


# ================================================================= B: muerte durante el aviso

func _b() -> void:
	await _combate(true)
	if custodio.is_empty():
		return
	var muerto := [false]
	var tras_muerte: Array = []
	var r := await _turno(Callable(), func():
		if not muerto[0] and custodio.has("e01_marca"):
			muerto[0] = true
			custodio["hp"] = 0
			PE.vigilar(c, custodio, 1)                    # (lo que hace _quitar_pv → _vigilar_carga al caer)
			c._restablecer_color(custodio)                 # su derrota (morir) como tras cualquier golpe
			c._actualizar()
			tras_muerte.append(Engine.get_process_frames()))
	_ok(muerto[0], "B: no llegó a verse la marca")
	_ok(r["impactos"].is_empty() and r["danos"].is_empty(), "B: muerto en el aviso, golpea (%s, %s)" % [r["impactos"], r["danos"]])
	_ok(PE.nodos_vivos(c.enemigos).is_empty(), "B: la marca sigue tras morir")
	for k in 120:
		await process_frame
		if c.estado == "fin":
			break
	_ok(c.estado == "fin" and c.enemigos.all(func(e): return e["hp"] <= 0), "B: el combate no acaba con victoria (%s)" % c.estado)
	hechos.append("B: muerte durante el aviso: sin impacto ni daño, marca fuera, victoria")
	await _cerrar()


# ================================================================= C: velocidad de animación ×2

func _c() -> void:
	await _combate(true)
	if custodio.is_empty():
		return
	var p = c._p3d(custodio)
	var puesto := [false]
	var r := await _turno(Callable(), func():
		if not puesto[0] and custodio.has("e01_marca") and p.anim.current_animation == "ataque":
			puesto[0] = true
			p.anim.speed_scale = 2.0)
	var at: Dictionary = custodio.get("e01_ultimo", {})
	var d_imp: int = int(at.get("t_impacto", 0)) - int(at.get("t_aviso", 0))
	_ok(puesto[0] and r["impactos"].size() == 1 and r["danos"].size() == 2, "C: a ×2, %d impactos y %d golpes" % [r["impactos"].size(), r["danos"].size()])
	_ok(d_imp >= 12 and d_imp <= 16, "C: a ×2 el impacto llega a %d fotogramas del aviso (≈14)" % d_imp)
	hechos.append("C: a ×2 el impacto sigue al clip (%d fotogramas) y golpea una vez a cada uno" % d_imp)
	await _cerrar()


# ================================================================= D: cerrar a media Prensa

func _d() -> void:
	await _combate(true)
	if custodio.is_empty():
		return
	var cerrado := [false]
	custodio["vel"] = 10.0
	custodio["atb"] = c.ATB_MAX - 0.01
	for fr in 600:
		await process_frame
		if custodio.has("e01_marca") and not cerrado[0]:
			cerrado[0] = true
			c.queue_free()
			break
	_ok(cerrado[0], "D: no llegó a verse la marca")
	c = null
	custodio = {}
	await _esperar(90)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(h <= huerfanos0, "D: al cerrar a media Prensa quedan %d nodos huérfanos (antes %d)" % [h, huerfanos0])
	_limpiar()
	hechos.append("D: cerrar el combate a media Prensa no deja nodos huérfanos")
