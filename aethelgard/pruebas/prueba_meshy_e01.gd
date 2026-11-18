extends SceneTree
# V12, fase 9 (14/11/2026, PILOTO): meshy_e01 · el Custodio de Porcelana (combate_meshy_e01.gd, sus ganchos «V12,
# Custodio» de combate.gd y recursos.gd, y enemigos/meshy_e01/meshy_e01.glb). Sin ventana, con datos aislados.
#   U. Interruptor propio apagado por defecto y fuera de la partida; apagado o encendido, el azar de los encuentros no
#      cambia y nunca da sus grupos (28 y 29); su carpeta fuera de la precarga mientras va apagado.
#   M. El modelo en Godot: 6 clips propios (14/11, noche: + Avance del Portón, golpe y derrota) (nombres, duraciones, bucles), los alias del juego son el MISMO recurso,
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
# 15/11: Sello de Clausura (e01_a3) y la rotación de los tres especiales:
#   M. 7 clips (+ e01__attack_sello) y el alias «sello»; instantes iguales en JSON, modelo y combate; en el Sello, pies y
#      cadera quietos (raíz quieta), manos a la llave del pecho a 0,45 y palmas delante a 1,30.
#   E. Sello: la marca aparece en el aviso (0,20) y dura hasta el impacto; el centro se fija a 0,80 y no se mueve aunque
#      el elegido se aparte; a 1,30 un impacto; golpea UNA vez a cada héroe dentro del círculo (1,3 m; calculado aquí
#      aparte) y a nadie de fuera; daño arcano 9-13 (defendiendo, la mitad); −15 % de velocidad a los golpeados hasta
#      su próximo turno (entonces la recuperan exacta); la marca, borrada; recarga 3. La Guardia de Garon cubre.
#   R. La rotación con la recarga de cada uno: Prensa, G, G, Avance, G, G, Sello, G, G, G, Prensa.
# 15/11, tarde (Redmi: «Sello en 3» y el Sello no llegaba): el contador cuenta turnos suyos y lo dice.
#   K. Los textos de cada recarga, y el caso del banco «custodio_rotacion» con el ATB de verdad y Kael congelándolo con
#      Frostfang: la rotación entera (los tres especiales) y, en cada turno, el contador que se veía antes (etiqueta y
#      panel) dice cuántos turnos suyos faltaban de verdad para el especial que llegó.
# 18/11: los cinco clips que faltaban (alert, guard, stagger, turn_l, turn_r) y sus ganchos (solo presentación):
#   N. 12 clips; los alias entrada/guardia/tambaleo/girar_izq/girar_der con su duración y bucle (solo la guardia);
#      alert como ENTRADA y vuelta al reposo; en Guardia el reposo es «guardia» hasta que se acaba; golpe fuerte o
#      ruptura -> «tambaleo» (y vuelve a la guardia si la tenía), golpe pequeño -> el de siempre; giros >= 60° quieto ->
#      girar_izq/der en dos pasos (andar lo corta; un reposo pedido espera al final), giros pequeños sin clip. En combate:
#      empieza con la alerta, su turno de guardia pone «guardia» y su turno siguiente la quita, vuelve de la Prensa con
#      un giro en pasos, y vigilar() marca el golpe fuerte y la Quiebra sin tocar vida, recarga, ATB ni guardia.
# Azar (15/11): la semilla, DESPUÉS de root.add_child (combate._ready hace randomize()).

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
	await _e()
	await _r()
	await _k()
	await _n()
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
	# (19/11: + GRUPOS[30], el de Velaria, combate_velaria.gd; los 28 de antes y los 2 suyos siguen en su sitio)
	_ok(C.GRUPOS.size() == 31 and C.GRUPOS[30][0][0] == "velaria", "U: GRUPOS tiene %d entradas (28 de antes, las 2 suyas y la de Velaria)" % C.GRUPOS.size())
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
	_ok(propios == PackedStringArray(["e01__alert", "e01__attack_porton", "e01__attack_prensa", "e01__attack_sello", "e01__death",
		"e01__guard", "e01__hit", "e01__idle", "e01__stagger", "e01__turn_l", "e01__turn_r", "e01__walk"]), "M: clips %s" % [propios])
	_ok(p.tiene("recibir_golpe") and p.tiene("derrota") and p.tiene("porton") and p.tiene("sello"),
		"M: faltan los alias del golpe, la derrota, el Avance o el Sello")
	for clip in ["sello", "e01__attack_sello"]:
		_ok(_mismos(p.EVENTOS[clip], j["clips"]["e01__attack_sello"]["eventos"]), "M: instantes de %s distintos del JSON" % clip)
	_ok(absf(p.instante("sello", "aviso") - PE.T_SELLO_MARCA) < 0.001 and absf(p.instante("sello", "fija_direccion") - PE.T_SELLO_FIJA) < 0.001
		and absf(p.instante("sello", "impacto") - PE.T_SELLO_IMPACTO) < 0.001, "M: el Sello no tiene los mismos instantes en el modelo y el combate")
	_ok(p.anim.get_animation("sello").loop_mode == Animation.LOOP_NONE and absf(p.duracion("sello") - 2.8) < 0.04, "M: el Sello no dura 2,8 s sin bucle")
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
	# Sello: raíz quieta (pies y cadera), manos a la llave del pecho a 0,45 y palmas extendidas delante a 1,30
	var b_mano_r: int = p.skel.find_bone("mano.R")
	p.anim.play("sello")
	p.anim.seek(0.0, true)
	var cad_s0: Vector3 = p.skel.get_bone_global_pose(b_cad).origin
	var pie_s0: Vector3 = p.skel.get_bone_global_pose(b_pie).origin
	var mano_s0: Vector3 = p.skel.get_bone_global_pose(b_mano).origin
	var pie_s := 0.0
	var cad_s := 0.0
	for k in 29:
		p.anim.seek(2.8 * k / 28.0, true)
		pie_s = maxf(pie_s, p.skel.get_bone_global_pose(b_pie).origin.distance_to(pie_s0))
		cad_s = maxf(cad_s, p.skel.get_bone_global_pose(b_cad).origin.distance_to(cad_s0))
	p.anim.seek(0.45, true)
	var llave_l: Vector3 = p.skel.get_bone_global_pose(b_mano).origin
	var llave_r: Vector3 = p.skel.get_bone_global_pose(b_mano_r).origin
	p.anim.seek(1.30, true)
	var palma_l: Vector3 = p.skel.get_bone_global_pose(b_mano).origin
	var palma_r: Vector3 = p.skel.get_bone_global_pose(b_mano_r).origin
	_ok(pie_s < 0.005 and cad_s < 0.005, "M: en el Sello se mueven los pies (%.4f m) o la cadera (%.4f m): raíz quieta" % [pie_s, cad_s])
	# (la muñeca, no los dedos: las manos son grandes y enmarcan la llave con las muñecas a ≈0,35 m del centro)
	_ok(absf(llave_l.x) < absf(mano_s0.x) - 0.05 and absf(llave_r.x + llave_l.x) < 0.01 and llave_l.y > mano_s0.y + 0.3
		and llave_l.z > 0.2, "M: a 0,45 las manos no se acercan a la llave del pecho (%s, %s; en reposo %s)" % [llave_l, llave_r, mano_s0])
	_ok(palma_l.z > llave_l.z + 0.1 and palma_r.z > llave_r.z + 0.1 and palma_l.y > 1.0,
		"M: a 1,30 las palmas no se extienden delante (%s, %s)" % [palma_l, palma_r])
	hechos.append("M: Sello: pies %.4f m, cadera %.4f m; manos a 0,45 en %s / %s; palmas a 1,30 en %s / %s" % [pie_s, cad_s,
		llave_l, llave_r, palma_l, palma_r])
	hechos.append("M: %d clips (%s), alias = mismo recurso, %d huesos (%d con pesos), %d triángulos, %d influencias, %.2f m; Prensa: pie quieto (%.4f m), cadera −%.3f m (%.1f %%), muñeca en el impacto %s, a 0,65 s a %.2f m" % [
		propios.size(), ", ".join(propios), p.skel.get_bone_count(), usados.size(), tris, max_inf, aabb.size.y, pie_mov, cad_baja, 100.0 * cad_baja / 1.85,
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
	c = load("res://combate.tscn").instantiate()
	impactos.clear()
	danos.clear()
	hp_prev.clear()
	marca_frames.clear()
	root.add_child(c)                                    # (aquí su _ready hace randomize())
	seed(14112026)                                       # 15/11: la semilla, después (antes no valía de nada)
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
	r["que"] = "nada"
	for k in ["prensa", "porton", "sello", "guardia"]:
		if int(cont1.get(k, 0)) > int(cont0.get(k, 0)):
			r["que"] = k
			break
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
	# 14/11, noche: tras dos guardias, el OTRO especial, el Avance del Portón, contra Lya defendiendo (la mitad y sin
	# Retroceso; a Garon, el de detrás, el Retroceso del 25 %)
	lya["defendiendo"] = true
	lya["atb"] = 50.0
	garon["atb"] = 50.0
	var r2 := await _turno()
	_ok(r2["que"] == "porton" and not custodio.get("e01_guardia", false), "A5: tras dos guardias no llega el Avance (%s)" % r2["que"])
	_ok(r2["impactos"].size() == 1, "A5: el Avance da %d impactos (uno)" % r2["impactos"].size())
	_ok(not r2["marca_pos"].is_empty() and r2["marca_pos"][0].size() == 1, "A5: el Avance no marca su franja")
	var por2 := {}
	for d in r2["danos"]:
		por2[d[0]] = por2.get(d[0], []) + [d]
	_ok(por2.get("Lya", []).size() == 1 and por2.get("Garon", []).size() == 1 and not por2.has("Kael"), "A5: golpes %s" % [por2])
	if por2.has("Lya"):
		_ok(int(por2["Lya"][0][2]) * 2 <= dano_lya_1 + 4, "A5: defendiendo, Lya recibe %d (antes %d)" % [por2["Lya"][0][2], dano_lya_1])
	_ok(absf(lya["atb"] - 50.0) < 0.01 and absf(garon["atb"] - 25.0) < 0.01, "A5: Retroceso con defensa (Lya %.1f, Garon %.1f)" % [lya["atb"], garon["atb"]])
	_ok(custodio["e01_ultimo"]["id"] != at.get("id", -1), "A5: el Avance reutiliza el attack_instance_id")
	_ok(custodio["e01_ultimo"].get("ataque", "") == PE.ATAQUE_ID_A2 and PE._siguiente(custodio) == "sello"
		and int(custodio["e01_cd"]) == PE.CD_TURNOS, "A5: tras el Avance no toca recargar y luego el Sello")
	_ok(PE.nodos_vivos(c.enemigos).is_empty(), "A5: la franja sigue tras el impacto")
	hechos.append("A: Prensa (aviso → fija %d f → impacto %d f; marca fija %d f; Lya −%d y Garon −%d una vez en el impacto; Retroceso 15 %%), 2 guardias (recarga 2 → 0), Avance del Portón contra Lya defendiendo (−%d, sin Retroceso; Garon −25 %% de ATB)" % [
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


# ================================================================= E: Sello de Clausura (15/11)

# La distancia en el suelo en metros, calculada AQUÍ aparte (no con la función del combate): 168 px por metro (su modelo:
# 840 px × 0,6 / 3,0 m) y la profundidad aplastada ×0,32 en la pantalla.
func _dist_m(a: Vector2, b: Vector2) -> float:
	var d := b - a
	return Vector2(d.x, d.y / 0.32).length() / (840.0 * 0.6 / 3.0)


func _geometria() -> String:
	var t := PackedStringArray()
	var pie: Vector2 = c._suelo_de(custodio)
	for h in c.heroes:
		t.append("%s a %.2f m" % [h["nombre"], _dist_m(pie, c._suelo_de(h))])
	for i in c.heroes.size():
		for j in range(i + 1, c.heroes.size()):
			t.append("%s-%s %.2f m" % [c.heroes[i]["nombre"], c.heroes[j]["nombre"],
				_dist_m(c._suelo_de(c.heroes[i]), c._suelo_de(c.heroes[j]))])
	return ", ".join(t)


# Un turno con el Sello (lo pone a tocar: tras el Avance y sin recarga) y lo que se ve de su centro cada fotograma.
func _turno_sello(durante := Callable()) -> Dictionary:
	custodio["e01_especial"] = "porton"
	custodio["e01_cd"] = 0
	custodio["e01_guardia"] = false
	custodio["defendiendo"] = false
	var centros: Array = []
	var r := await _turno(Callable(), func():
		var at: Dictionary = custodio.get("e01_ataque", {})
		if not at.is_empty():
			centros.append([Engine.get_process_frames(), at["centro"], at.get("centro_fijo", false)])
		if durante.is_valid():
			durante.call(at))
	r["centros"] = centros
	return r


# Comprueba un Sello: tiempos, marca, centro fijo, quién está dentro (calculado aquí), un golpe a cada uno, el daño, la
# lentitud y su fin. «cubre»: {cubierto: quien le cubre}. Devuelve los golpeados.
func _comprobar_sello(caso: String, r: Dictionary, vel0: Dictionary, cubre := {}) -> Array:
	var at: Dictionary = custodio.get("e01_ultimo", {})
	_ok(r["que"] == "sello" and at.get("ataque", "") == PE.ATAQUE_ID_A3, "%s: el turno no es el Sello (%s)" % [caso, r["que"]])
	_ok(r["impactos"].size() == 1 and r["impactos"][0][0] == "sello", "%s: impactos %s (uno, «sello»)" % [caso, r["impactos"]])
	var d_fija: int = int(at.get("t_fija", 0)) - int(at.get("t_aviso", 0))
	var d_imp: int = int(at.get("t_impacto", 0)) - int(at.get("t_aviso", 0))
	_ok(int(at.get("t_aviso", -1)) > 0 and absi(d_fija - 18) <= 2 and absi(d_imp - 33) <= 2,
		"%s: fija a %d y golpea a %d fotogramas del aviso (18 y 33: 0,20 → 0,80 → 1,30 a 30 fps)" % [caso, d_fija, d_imp])
	_ok(r["marca_pos"].size() >= d_imp - 3 and not r["marca_pos"].is_empty() and r["marca_pos"][0].size() == 1,
		"%s: la marca dura %d fotogramas (≥ %d) con %d discos" % [caso, r["marca_pos"].size(), d_imp - 3,
		r["marca_pos"][0].size() if not r["marca_pos"].is_empty() else 0])
	var fijo_ok := true
	for x in r["centros"]:
		if int(x[0]) > int(at.get("t_fija", 0)) and (x[1] as Vector2) != (at["centro"] as Vector2):
			fijo_ok = false
	_ok(fijo_ok, "%s: el centro se mueve después de fijarse" % caso)
	# quién estaba dentro en el impacto, calculado aquí (posiciones de ahora: nadie se ha movido desde el impacto)
	var esperados: Array = []
	for h in c.heroes:
		if h["hp"] > 0 and _dist_m(at["centro"], c._suelo_de(h)) <= 1.3:
			esperados.append(h["nombre"])
	esperados.sort()
	var dentro: Array = at.get("dentro", []).duplicate()
	dentro.sort()
	_ok(dentro == esperados and not esperados.is_empty(), "%s: dentro %s (calculado aquí %s)" % [caso, dentro, esperados])
	var blancos := {}
	for n in esperados:
		blancos[cubre.get(n, n)] = true
	var por := {}
	for d in r["danos"]:
		por[d[0]] = por.get(d[0], []) + [d]
	var golpeados: Array = []
	for h in c.heroes:
		var n: String = h["nombre"]
		if blancos.has(n):
			golpeados.append(h)
			var g: Array = por.get(n, [])
			_ok(g.size() == 1, "%s: %s recibe %d golpes (uno)" % [caso, n, g.size()])
			if g.size() == 1:
				var lo := 4 if h.get("defendiendo", false) else 9
				var hi := 6 if h.get("defendiendo", false) else 13
				_ok(int(g[0][2]) >= lo and int(g[0][2]) <= hi, "%s: %s pierde %d (%d-%d)" % [caso, n, g[0][2], lo, hi])
				_ok(absi(int(g[0][1]) - int(at["t_impacto"])) <= 1, "%s: el daño a %s no cae en el impacto" % [caso, n])
			_ok(absf(float(h["vel"]) - vel0[n] * 0.85) < 0.0001 and h.has("e01_lento"), "%s: %s no va a −15 %% (%.3f de %.3f)" % [
				caso, n, h["vel"], vel0[n]])
		else:
			_ok(not por.has(n), "%s: %s, fuera, recibe daño" % [caso, n])
			_ok(float(h["vel"]) == vel0[n] and not h.has("e01_lento"), "%s: %s, fuera, se frena" % [caso, n])
	_ok(PE.nodos_vivos(c.enemigos).is_empty(), "%s: la marca sigue tras el impacto" % caso)
	_ok(int(custodio["e01_cd"]) == PE.SELLO_CD_TURNOS and PE._siguiente(custodio) == "prensa", "%s: recarga %d (3) y luego %s" % [
		caso, int(custodio["e01_cd"]), PE._siguiente(custodio)])
	return golpeados


func _e() -> void:
	await _combate(true)
	if custodio.is_empty():
		return
	print("GEOMETRIA ", _geometria(), " · px/m del combate %.1f" % PE.px_por_m(c))
	var vel0 := {}
	for h in c.heroes:
		h["vel"] = 1.0                                       # (que se vea la lentitud sin que les llegue el turno)
		h["atb"] = 0.0
		vel0[h["nombre"]] = 1.0
		hp_prev[h["nombre"]] = h["hp"]
	# E1: sin defender
	var r := await _turno_sello()
	var at: Dictionary = custodio.get("e01_ultimo", {})
	var g1 := await _comprobar_sello("E1", r, vel0)
	var e1 := "E1: centro en %s (principal %s, %d aliados cerca), dentro %s, daños %s" % [at.get("centro"),
		at.get("principal", {}).get("nombre", "-"), int(at.get("aliados_cerca", -1)), at.get("dentro"), at.get("danos")]
	# su fin: al llegarles el turno (la barra llena), la velocidad de antes, exacta
	for h in g1:
		h["atb"] = c.ATB_MAX
	await _esperar(3)
	for h in g1:
		_ok(float(h["vel"]) == vel0[h["nombre"]] and not h.has("e01_lento"), "E1: %s no recupera su velocidad al llegarle el turno (%.4f)" % [
			h["nombre"], h["vel"]])
		h["atb"] = 0.0
	_ok(int(custodio["e01_contador"].get("lentitud_fin", 0)) == g1.size(), "E1: fines de la lentitud %d (de %d)" % [
		int(custodio["e01_contador"].get("lentitud_fin", 0)), g1.size()])
	# E2: el elegido se aparta 3 m tras fijarse el centro: el círculo no le sigue y no le golpea
	var apartado := [{}]
	var movido := [false]
	var rig0 := [Vector2.ZERO]
	r = await _turno_sello(func(a: Dictionary):
		if not movido[0] and a.get("centro_fijo", false) and not a.get("principal", {}).is_empty():
			movido[0] = true
			apartado[0] = a["principal"]
			rig0[0] = apartado[0]["rig"].position
			apartado[0]["rig"].position += Vector2(3.0 * 168.0, 0.0))
	_ok(movido[0], "E2: no hubo elegido que apartar")
	var principal: Dictionary = apartado[0]
	var g2 := await _comprobar_sello("E2", r, vel0)
	if not principal.is_empty():
		_ok(not g2.any(func(h): return is_same(h, principal)), "E2: el elegido, apartado, recibe el Sello")
		principal["rig"].position = rig0[0]
	for h in c.heroes:
		if h.has("e01_lento"):
			h["atb"] = c.ATB_MAX
	await _esperar(3)
	for h in c.heroes:
		h["atb"] = 0.0
	# E3: la Guardia de Garon cubre a Lya y Kael defiende
	var lya := _heroe("Lya")
	var kael := _heroe("Kael")
	lya["guardia_de"] = "Garon"
	kael["defendiendo"] = true
	r = await _turno_sello()
	var at3: Dictionary = custodio.get("e01_ultimo", {})
	var g3 := await _comprobar_sello("E3", r, vel0, {"Lya": "Garon"})
	_ok(not r["danos"].any(func(d): return d[0] == "Lya"), "E3: Lya, cubierta por Garon, recibe daño")
	lya.erase("guardia_de")
	kael["defendiendo"] = false
	hechos.append(e1)
	hechos.append("E2: apartado %s tras fijarse: golpeados %s; E3: Garon cubre a Lya, Kael defiende: dentro %s, daños %s" % [
		principal.get("nombre", "-"), g2.map(func(h): return h["nombre"]), at3.get("dentro"), at3.get("danos")])
	print("GEOMETRIA ", _geometria())
	await _cerrar()


# ================================================================= R: la rotación de los tres especiales

func _r() -> void:
	await _combate(true)
	if custodio.is_empty():
		return
	for h in c.heroes:
		h["vel"] = 0.0
		h["atb"] = 0.0
	var visto: Array = []
	for k in 11:
		for h in c.heroes:                                   # (que nadie caiga ni le llegue el turno en la prueba)
			h["hp"] = h["hp_max"]
			h["atb"] = 0.0
			h["defendiendo"] = false
		var r := await _turno()
		visto.append(r["que"])
	var esperado := ["prensa", "guardia", "guardia", "porton", "guardia", "guardia", "sello", "guardia", "guardia", "guardia", "prensa"]
	_ok(visto == esperado, "R: rotación %s (esperada %s)" % [visto, esperado])
	_ok(PE.nodos_vivos(c.enemigos).is_empty(), "R: quedan marcas")
	hechos.append("R: %s" % ", ".join(visto))
	await _cerrar()


# ================================================================= K: el contador, con un héroe que congela (15/11)

# El caso del banco «custodio_rotacion» (banco_pruebas.gd: partida BASE, nivel 12, Kael con Frostfang, vida ×8) con el
# ATB de verdad y los héroes atacando solos (no es la estrategia de un jugador): Kael lo deja Congelado a menudo.
# K1. Los textos en cada recarga: «X en N turnos suyos» si faltan N ≥ 2; «⚠ X: su próximo turno» si es el siguiente.
# K2. Once turnos suyos: la rotación entera (los tres especiales) aunque esté congelado, y en CADA turno el contador que
#     se veía justo antes (etiqueta y panel) dice cuántos turnos suyos faltaban DE VERDAD para el especial que llegó.
func _k() -> void:
	# K1: los textos, sin combate
	for sig in ["", "prensa", "porton"]:
		for cd in [0, 1, 2, 3]:
			for guardia in [false, true]:
				var e := {"e01_especial": sig, "e01_cd": cd, "e01_guardia": guardia}
				var toca: String = PE._siguiente(e)
				var est: String = "  ".join(PE.estados(e))
				var inf: String = " · ".join(PE.info(e))
				var corto: String = PE.nombre_corto(toca)
				var esperado := ("%s en %d turnos suyos" % [corto, cd + 1]) if cd > 0 else ("⚠ %s: su próximo turno" % corto)
				_ok(est.ends_with(esperado) and est.begins_with("Guardia") == guardia,
					"K1: recarga %d, toca %s, guardia %s: etiqueta «%s» (esperada «…%s»)" % [cd, toca, guardia, est, esperado])
				var en_panel := ("%s en %d turnos suyos" % [PE.nombre_largo(toca), cd + 1]) if cd > 0 \
					else ("⚠ Su próximo turno: %s" % PE.nombre_largo(toca))
				_ok(en_panel in inf and ("En guardia" in inf) == guardia, "K1: panel «%s» (sin «%s»)" % [inf, en_panel])
	# K2: el combate del banco
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	var d: Dictionary = BP.COMBATES["custodio_rotacion"]
	BP.poner_grupo(d["activos"], BP.NIVEL_COMBATE)
	Engine.set_meta("banco_caso", "custodio_rotacion")
	Engine.set_meta(PE.INTERRUPTOR, true)
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", int(d["grupo"]))
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(15112026)                                         # (tras add_child: su _ready hace randomize())
	custodio = {}
	for e in c.enemigos:
		if PE.es(e):
			custodio = e
	_ok(not custodio.is_empty() and custodio["hp_max"] > 1000, "K2: sin el Custodio del caso ×8")
	var kael := _heroe("Kael")
	_ok(c._lleva_frostfang(kael), "K2: Kael no lleva Frostfang en el caso del banco")
	if custodio.is_empty():
		BP.salir()
		return
	var turnos: Array = []                                 # [{que, etiqueta, panel, cd, congelado}]
	var antes := {}
	var cont0: Dictionary = {}
	var en_turno := false
	var decidido := -1
	for fr in 30 * 60 * 6:
		await process_frame
		if c.estado == "fin" or turnos.size() >= 11:
			break
		if not en_turno and not is_same(c.atacante_actual, custodio):
			# lo de justo antes de su turno (al empezar, su turno cuenta y reescribe la etiqueta)
			antes = {"etiqueta": custodio["lbl_estado"].text, "panel": " · ".join(PE.info(custodio)),
				"cd": int(custodio.get("e01_cd", 0)), "congelado": int(custodio.get("congelado", 0))}
			cont0 = (custodio.get("e01_contador", {}) as Dictionary).duplicate()
		elif not en_turno:
			en_turno = true
		elif c.atacante_actual == null:
			en_turno = false
			var cont1: Dictionary = custodio.get("e01_contador", {})
			var que := "nada"
			for q in ["prensa", "porton", "sello", "guardia"]:
				if int(cont1.get(q, 0)) > int(cont0.get(q, 0)):
					que = q
			antes["que"] = que
			turnos.append(antes.duplicate())
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			for h in c.heroes:                             # (que nadie caiga: lo que se mira es su rotación)
				h["hp"] = h["hp_max"]
			var alc: Array = c._alcanzables()
			if alc.is_empty():
				c._defender()
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(alc[0])
	var visto: Array = turnos.map(func(t): return t["que"])
	var esperado := ["prensa", "guardia", "guardia", "porton", "guardia", "guardia", "sello", "guardia", "guardia", "guardia", "prensa"]
	_ok(visto == esperado, "K2: rotación con Frostfang %s (esperada %s)" % [visto, esperado])
	_ok(turnos.filter(func(t): return int(t["congelado"]) > 0).size() >= 5, "K2: pocas veces congelado al empezar su turno (%s)" % [
		turnos.map(func(t): return t["congelado"])])
	_ok(int(custodio.get("e01_contador", {}).get("duplicado_evitado", 0)) == 0, "K2: golpes duplicados")
	# el contador de cada turno frente a lo que pasó de verdad: cuántos turnos suyos faltaban hasta el especial siguiente
	var lineas: Array = []
	for i in turnos.size():
		var j := i
		while j < turnos.size() and turnos[j]["que"] == "guardia":
			j += 1
		if j >= turnos.size():
			continue
		var faltan := j - i + 1
		var corto: String = PE.nombre_corto(turnos[j]["que"])
		var largo: String = PE.nombre_largo(turnos[j]["que"])
		var en_etiqueta := ("%s en %d turnos suyos" % [corto, faltan]) if faltan > 1 else ("⚠ %s: su próximo turno" % corto)
		var en_panel := ("%s en %d turnos suyos" % [largo, faltan]) if faltan > 1 else ("⚠ Su próximo turno: %s" % largo)
		_ok(en_etiqueta in str(turnos[i]["etiqueta"]), "K2: turno %d (%s): la etiqueta decía «%s» y faltaban %d para %s" % [i + 1,
			turnos[i]["que"], turnos[i]["etiqueta"], faltan, corto])
		_ok(en_panel in str(turnos[i]["panel"]), "K2: turno %d: el panel decía «%s» (faltaban %d para %s)" % [i + 1,
			turnos[i]["panel"], faltan, largo])
		lineas.append("%d %s «%s»" % [i + 1, turnos[i]["que"], turnos[i]["etiqueta"]])
	print("K2 TRAZA: ", " | ".join(lineas))
	hechos.append("K: textos de las %d combinaciones; el banco ×8 con Kael congelándolo (%d de %d turnos empezó congelado): %s, y el contador de cada turno acierta cuántos turnos suyos faltaban" % [
		3 * 4 * 2, turnos.filter(func(t): return int(t["congelado"]) > 0).size(), turnos.size(), ", ".join(visto)])
	await _esperar(30)
	c.queue_free()
	c = null
	custodio = {}
	await _esperar(30)
	BP.salir()
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)


# ================================================================= N (18/11): alert, guard, stagger y giros

func _esperar_s(seg: float) -> void:
	await create_timer(seg).timeout


func _n() -> void:
	var p = load("res://enemigos/meshy_e01/meshy_e01_3d.gd").new()
	root.add_child(p)
	await _esperar(2)
	if p.anim == null:
		_ok(false, "N: sin AnimationPlayer")
		p.queue_free()
		return
	var esperado := {"entrada": [1.6, false], "guardia": [2.0, true], "tambaleo": [1.2, false], "girar_izq": [1.0, false],
		"girar_der": [1.0, false]}
	var duraciones: Array = []
	for n in esperado:
		var a: Animation = p.anim.get_animation(n) if p.tiene(n) else null
		_ok(a != null and absf(a.length - float(esperado[n][0])) <= 1.0 / 30.0 + 0.001
			and (a.loop_mode == Animation.LOOP_LINEAR) == bool(esperado[n][1]),
			"N: «%s» dura %s o su bucle no es %s" % [n, a.length if a != null else -1.0, esperado[n][1]])
		if a != null:
			duraciones.append("%s %.2f s%s" % [n, a.length, " (bucle)" if a.loop_mode == Animation.LOOP_LINEAR else ""])
	# alert como entrada
	p.entrada()
	_ok(p.clip_actual() == "entrada", "N: la entrada no pone el clip de alerta (%s)" % p.clip_actual())
	await _esperar_s(1.9)
	_ok(p.clip_actual() == "reposo", "N: tras la alerta no vuelve al reposo (%s)" % p.clip_actual())
	# guardia
	p.guardia(true)
	_ok(p.clip_actual() == "guardia", "N: en guardia el clip es %s" % p.clip_actual())
	await _esperar(3)
	p.reposo()
	_ok(p.clip_actual() == "guardia", "N: en guardia, reposo() pone %s" % p.clip_actual())
	# tambaleo (fuerte) en guardia: vuelve a la guardia
	p.golpe_pesado = true
	p.recibir_golpe()
	_ok(p.clip_actual() == "tambaleo" and not p.golpe_pesado, "N: un golpe fuerte pone %s" % p.clip_actual())
	await _esperar_s(1.45)
	_ok(p.clip_actual() == "guardia", "N: tras el tambaleo en guardia queda %s" % p.clip_actual())
	p.guardia(false)
	_ok(p.clip_actual() == "reposo", "N: al acabar la guardia queda %s" % p.clip_actual())
	p.recibir_golpe()
	_ok(p.clip_actual() == "recibir_golpe", "N: un golpe pequeño pone %s (el de siempre)" % p.clip_actual())
	await _esperar_s(0.8)
	# giros
	p.mirar(Vector3(1, 0, 0.1), 0.25)                    # 31°: sin pasos
	_ok(p.clip_actual() == "reposo" and p.girando() == "", "N: un giro pequeño pone %s" % p.clip_actual())
	await _esperar_s(0.35)
	p.mirar(Vector3(-1, 0, -0.1), 0.3)                   # 180° (media vuelta, como al volver de la Prensa)
	_ok(p.clip_actual() in ["girar_izq", "girar_der"] and p.girando() == p.clip_actual(), "N: media vuelta pone %s" % p.clip_actual())
	p.andar()
	_ok(p.clip_actual() == "caminar" and p.girando() == "", "N: andar no corta el giro (%s)" % p.clip_actual())
	await _esperar_s(0.45)
	var yaw_atras: float = p.pivote.rotation.y
	p.mirar_frente(0.3)                                  # +149° (a su izquierda: +Y), al volver andando
	_ok(p.clip_actual() == "girar_izq", "N: volverse al frente pone %s" % p.clip_actual())
	p.reposo()
	_ok(p.clip_actual() == "girar_izq", "N: el reposo no espera al final del giro (%s)" % p.clip_actual())
	await _esperar_s(0.5)
	var yaw_medio: float = p.pivote.rotation.y
	await _esperar_s(0.75)
	var yaw_fin: float = p.pivote.rotation.y
	var meta: float = atan2(p.FRENTE_ENEMIGO.x, p.FRENTE_ENEMIGO.z) - p._yaw0
	_ok(p.clip_actual() == "reposo" and absf(wrapf(yaw_fin - meta, -PI, PI)) < 0.02, "N: tras el giro %s, yaw %.2f (meta %.2f)" % [
		p.clip_actual(), yaw_fin, meta])
	_ok(absf(wrapf(yaw_medio - yaw_atras, -PI, PI)) > 0.3 and absf(wrapf(yaw_fin - yaw_medio, -PI, PI)) > 0.3,
		"N: el nodo no gira DURANTE el clip (%.2f -> %.2f -> %.2f)" % [yaw_atras, yaw_medio, yaw_fin])
	p.queue_free()
	await _esperar(3)
	# en combate
	await _combate(true)
	if custodio.is_empty():
		return
	var q = c._p3d(custodio)
	_ok(q.clip_actual() == "entrada", "N: el combate no empieza con la alerta (%s)" % q.clip_actual())
	custodio["e01_cd"] = 1                               # su próximo turno: guardia
	var r := await _turno()
	_ok(r["que"] == "guardia" and q.en_guardia and q.clip_actual() == "guardia",
		"N: turno de guardia: %s, en_guardia %s, clip %s" % [r["que"], q.en_guardia, q.clip_actual()])
	var vistos := {}
	var r2 := await _turno(Callable(), func(): vistos[q.clip_actual()] = true)
	await _esperar_s(1.2)
	_ok(r2["que"] == "prensa" and not q.en_guardia and not custodio.get("e01_guardia", false),
		"N: tras la guardia, %s y en_guardia %s" % [r2["que"], q.en_guardia])
	_ok(vistos.has("girar_der") or vistos.has("girar_izq"), "N: al volver de la Prensa no gira en pasos (clips %s)" % [vistos.keys()])
	_ok(q.clip_actual() == "reposo", "N: tras volver queda %s" % q.clip_actual())
	var antes := [int(custodio["hp"]), int(custodio.get("e01_cd", 0)), float(custodio.get("atb", 0.0)), custodio.get("e01_guardia", false)]
	PE.vigilar(c, custodio, 1)
	_ok(not q.golpe_pesado, "N: un golpe de 1 marca golpe fuerte")
	PE.vigilar(c, custodio, ceili(custodio["hp_max"] * PE.GOLPE_PESADO))
	_ok(q.golpe_pesado, "N: un golpe del 12 % no marca golpe fuerte")
	q.herida()
	_ok(q.clip_actual() == "tambaleo", "N: en combate, el golpe fuerte pone %s" % q.clip_actual())
	await _esperar_s(1.4)
	c.golpe_ruptura = true
	PE.vigilar(c, custodio, 1)
	c.golpe_ruptura = false
	_ok(q.golpe_pesado, "N: la Quiebra (golpe_ruptura) no marca golpe fuerte")
	q.golpe_pesado = false
	var despues := [int(custodio["hp"]), int(custodio.get("e01_cd", 0)), float(custodio.get("atb", 0.0)), custodio.get("e01_guardia", false)]
	_ok(antes == despues, "N: vigilar() cambia vida, recarga, ATB o guardia (%s -> %s)" % [antes, despues])
	await _cerrar()
	hechos.append("N: 12 clips; %s; alerta -> reposo; guardia en lugar del reposo y fuera al acabar; tambaleo con golpe fuerte (>= 12 %%) o Quiebra y de vuelta a la guardia; giros >= 60° en pasos (girar_izq/der; el nodo gira durante el clip; andar lo corta); en combate: alerta al empezar, guardia en su turno de guardia y fuera en el siguiente, vuelta de la Prensa con %s; vigilar no toca vida, recarga, ATB ni guardia" % [
		", ".join(duraciones), "/".join(vistos.keys())])
