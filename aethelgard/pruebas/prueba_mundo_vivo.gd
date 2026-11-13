extends SceneTree
# V12, mundo vivo de Oakhaven (especialista de mundo 3D y NPC, 12/11): la familia de NPC chibi (personajes/npc_v12) y
# sus rutinas en Oakhaven 3D (zonas3d/oakhaven/mundo_vivo.gd), detrás del interruptor «mundo_vivo_v12» (APAGADO).
#   0. Familia: cada oficio carga, con los clips del contrato (reposo, caminar, hablar, saludar, tarea; correr los
#      niños), el esqueleto común, un solo material por persona y triángulos dentro del presupuesto; cada persona tiene
#      su atlas.
#   1. Apagado (sin nada): Oakhaven como siempre: sin «MundoVivo», los vecinos con su figura provisional.
#   2. Encendido: todas las personas, cada una en su sitio; los puntos de las rutas, el corro y el barrido en calle (no en
#      un bloqueo); los que trabajan, fuera del paso de Kael o junto a él.
#   3. Andan de verdad (las rutas avanzan, los niños dan vueltas) y nunca se meten encima de Kael; Kael no los atraviesa.
#   4. Hablar: el botón sale cerca, la frase en el aviso, el gesto «hablar» y se gira hacia Kael; las frases se turnan.
#   5. Barato: lejos o fuera de la vista no se anima; más lejos no se dibuja.
#   6. La hora: al anochecer los niños y el mercado se van (con Kael lejos) y el viajero sigue.
#   7. Los vecinos con nombre con figura de la familia conservan su diálogo de siempre (Oak.dialogo_de) y su sitio.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_mundo_vivo.gd --fixed-fps 30 -- 3d sin_prologo
# No guarda ninguna partida (progreso.gd no guarda en las pruebas); no toca user://ajustes.cfg.

const REGION := "res://zonas3d/oakhaven_3d.tscn"
var MV = load("res://zonas3d/oakhaven/mundo_vivo.gd")
var NPC = load("res://personajes/npc_v12/npc_chibi.gd")
var Oak = load("res://ciudades/oakhaven.gd")
var v
var fallos := 0
const CLIPS := ["reposo", "caminar", "hablar", "saludar", "tarea"]
const TRIS_MAX := 6000            # V2 (13/11): el presupuesto de crear_npc_chibi.py (PRESUPUESTO_TRIS)


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(t: String) -> void:
	print("OK " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in ["mazmorras", "cofres_abiertos", "lore_visto", "hitos", "decisiones", "oak_franja", "oak_franja_t", "pos_3d"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)


func _cargar(vivo: bool) -> void:
	_limpiar()
	Engine.set_meta("mundo_vivo_v12", vivo)
	change_scene_to_file(REGION)
	await _frames(25)
	v = current_scene


func _kael(p: Vector3) -> void:
	v.en_posada = false
	v._colocar_kael(p)
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)
	await _frames(2)


func _correr() -> void:
	await _frames(2)
	# ---------------------------------------------------------------- 0. la familia
	var oficios := {}
	for d in MV.PERSONAS:
		oficios[d["oficio"]] = true
	for v_ in MV.VECINOS.values():
		oficios[v_[0]] = true
	for o in oficios:
		if not NPC.existe(o):
			_mal("falta el GLB de " + o)
			continue
		var escena: PackedScene = load("res://personajes/npc_v12/%s/%s.glb" % [o, o])
		var m: Node3D = escena.instantiate()
		var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
		var sk: Skeleton3D = m.find_child("*", true, false) as Skeleton3D
		for c in m.find_children("*", "Skeleton3D", true, false):
			sk = c
		var mallas := m.find_children("*", "MeshInstance3D", true, false)
		var faltan := CLIPS.filter(func(c): return ap == null or not ap.has_animation(c))
		if o in ["nino", "nina"] and (ap == null or not ap.has_animation("correr")):
			faltan.append("correr")
		var tris := 0
		for mi in mallas:
			var mesh: Mesh = (mi as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arr[Mesh.ARRAY_INDEX] != null else 0
		if not faltan.is_empty():
			_mal("%s: faltan clips %s" % [o, faltan])
		elif sk == null or sk.get_bone_count() != 22 or sk.find_bone("mano.R") < 0 or sk.find_bone("parpado.L") < 0:
			_mal("%s: esqueleto distinto del común (%s huesos)" % [o, sk.get_bone_count() if sk else -1])
		elif mallas.size() != 1 or tris > TRIS_MAX or tris < 1000:
			_mal("%s: %d mallas, %d triángulos" % [o, mallas.size(), tris])
		else:
			_ok("%s: clips, esqueleto común (22), 1 malla, %d triángulos" % [o, tris])
		m.free()
	for d in MV.PERSONAS:
		if not ResourceLoader.exists("res://personajes/npc_v12/%s/%s.png" % [d["oficio"], d["id"]]):
			_mal("falta el atlas de " + d["id"])
	# las frases de ambiente: una línea legible en el móvil (como oakhaven_vida.gd), sin nombres que esperan decisión
	for d in MV.PERSONAS:
		for f in d["frases"]:
			if String(f).length() > 48:
				_mal("frase larga (%d) de %s: «%s»" % [String(f).length(), d["id"], f])
			for veto in ["Érebo", "Naira", "Orbe", "orbe", "Morgath"]:
				if String(f).contains(veto):
					_mal("frase de %s con «%s»: %s" % [d["id"], veto, f])
	var ids: Array = MV.PERSONAS.map(func(d): return d["id"])
	for id in ids:
		if ids.count(id) > 1:
			_mal("persona repetida: " + id)
	var a1 = NPC.material_de("guardia", "guardia_puerta")
	var a2 = NPC.material_de("guardia", "guardia_puerta")
	if a1 == null or a1 != a2:
		_mal("el material de una persona no se comparte")

	# ---------------------------------------------------------------- 1. apagado
	await _cargar(false)
	if v.vivo != null or v.get_node_or_null("MundoVivo") != null:
		_mal("con el interruptor apagado hay mundo vivo")
	elif v.vida.vecinos.values().any(func(x): return x.get("chibi") != null):
		_mal("con el interruptor apagado un vecino lleva figura nueva")
	else:
		_ok("apagado: Oakhaven como siempre (sin MundoVivo, figuras de siempre)")
	var dialogos_antes := {}
	for id in v.vida.vecinos:
		dialogos_antes[id] = Oak.dialogo_de(id, 0)

	# ---------------------------------------------------------------- 2. encendido: personas y sitios
	await _cargar(true)
	var vivo = v.vivo
	if vivo == null:
		_mal("con el interruptor encendido no hay mundo vivo")
		_fin()
		return
	var presentes: Array = vivo.gente.filter(func(g): return g["d"]["rutina"] != "vecino")
	if presentes.size() != MV.PERSONAS.size():
		_mal("personas: %d de %d" % [presentes.size(), MV.PERSONAS.size()])
	else:
		_ok("%d personas secundarias" % presentes.size())
	var malos := []
	for d in MV.PERSONAS:
		var pts: Array = []
		match d["rutina"]:
			"ruta", "barrer":
				var p0: Array = d["puntos"]
				var cerrada: bool = d["rutina"] == "ruta" and not d.get("ida_vuelta", false)
				for i in p0.size() - (0 if cerrada else 1):
					var a: Vector2 = p0[i]
					var b: Vector2 = p0[(i + 1) % p0.size()]
					var n := int(ceil(a.distance_to(b) / 0.25))
					for k in n + 1:
						pts.append(a.lerp(b, float(k) / maxf(n, 1)))
			"corro":
				for k in 48:
					pts.append(MV.CORRO_CENTRO + Vector2(cos(TAU * k / 48.0), sin(TAU * k / 48.0)) * MV.CORRO_RADIO)
		for p in pts:
			var p3 := Vector3(p.x, MV.alto_en(p), p.y)
			if v.barrios.prohibido(p3) or v.ciudad.bloqueado(p.x, p.y, 0.15):
				malos.append("%s en %s" % [d["id"], p])
				break
	if malos.is_empty():
		_ok("rutas, corro y barrido en calle (sin bloqueos)")
	else:
		_mal("en un bloqueo: %s" % [malos])
	# los que trabajan: a mano de Kael (algún sitio pisable a menos de RADIO_HABLAR)
	for d in MV.PERSONAS:
		if d["rutina"] != "trabajo":
			continue
		var p: Vector2 = d["puntos"][0]
		var alcanza := false
		for k in 16:
			var q: Vector2 = p + Vector2(cos(TAU * k / 16.0), sin(TAU * k / 16.0)) * (MV.RADIO_HABLAR - 0.3)
			var q3 := Vector3(q.x, MV.alto_en(q), q.y)
			if not v.barrios.prohibido(q3) and not v.ciudad.bloqueado(q.x, q.y, 0.3):
				alcanza = true
				break
		if not alcanza:
			_mal(d["id"] + ": no se le alcanza andando")

	# ---------------------------------------------------------------- 3. andan y no pisan a Kael
	await _kael(Vector3(40.0, 0.0, 30.4))
	var antes := {}
	for g in presentes:
		antes[g["d"]["id"]] = (g["nodo"] as Node3D).position
	var cerca_kael := 0
	for i in 300:
		await process_frame
		var kp: Vector3 = v.kael.global_position
		for g in presentes:
			var q: Vector3 = (g["nodo"] as Node3D).position
			if g.get("presente", true) and Vector2(q.x - kp.x, q.z - kp.z).length() < MV.RADIO_OCUPA:
				cerca_kael += 1
	var movidos := []
	for g in presentes:
		var d: Dictionary = g["d"]
		if d["rutina"] in ["ruta", "corro", "barrer"] and g.get("presente", true):
			if (g["nodo"] as Node3D).position.distance_to(antes[d["id"]]) > 0.5:
				movidos.append(d["id"])
			else:
				_mal(d["id"] + " no se ha movido en 10 s")
	_ok("se mueven: %s" % [movidos])
	if cerca_kael > 0:
		_mal("un NPC se ha metido encima de Kael (%d veces)" % cerca_kael)
	# Kael no atraviesa a nadie: el sitio de un NPC presente está prohibido
	var g0: Dictionary = presentes.filter(func(g): return g["d"]["id"] == "guardia_puerta")[0]
	if not v._prohibido((g0["nodo"] as Node3D).position):
		_mal("Kael puede pisar al guardia de la puerta")
	else:
		_ok("Kael no atraviesa a nadie")
	# las palomas de la abuela: una sola malla múltiple, en el suelo; salen volando si Kael se acerca y vuelven
	var pal = vivo.palomas
	if pal == null or not pal.visible or pal.multimesh.instance_count < 5:
		_mal("no están las palomas de la plaza")
	else:
		await _kael(Vector3(MV.PALOMAS.x - 2.0, 0.0, MV.PALOMAS.y + 3.4))
		await _frames(20)
		await _kael(Vector3(MV.PALOMAS.x - 0.6, 0.0, MV.PALOMAS.y + 1.4))
		await _frames(80)
		if pal.fuera <= 0.0 and pal.volando <= 0.0:
			_mal("las palomas no se espantan con Kael encima")
		else:
			await _kael(Vector3(40.0, 0.0, 40.0))
			await _frames(30 * 20)
			if not pal.visible or pal.fuera > 0.0:
				_mal("las palomas no vuelven")
			else:
				_ok("palomas: picotean, se espantan y vuelven")

	# ---------------------------------------------------------------- 4. hablar
	var fr: Dictionary = presentes.filter(func(g): return g["d"]["id"] == "mercader_manzanas")[0]
	var fp: Vector3 = (fr["nodo"] as Node3D).position
	await _kael(fp + Vector3(0, 0, 1.3))
	v._comprobar_cerca()
	if v.cerca != "vivo:mercader_manzanas" or not v.boton_accion.visible:
		_mal("cerca del frutero no sale «Hablar» (cerca = «%s»)" % v.cerca)
	else:
		v._bloqueo = 0.0
		v._accion()
		await _frames(3)
		var t1: String = v.aviso.text
		var n: Node3D = fr["nodo"]
		if not t1.contains(fr["d"]["frases"][0]) or n.actual != "hablar":
			_mal("hablar con el frutero: «%s», clip %s" % [t1, n.actual])
		else:
			var d: Vector3 = v.kael.global_position - n.global_position
			var giro := absf(wrapf(n.rotation.y - atan2(d.x, d.z), -PI, PI))
			if giro > 0.2:
				_mal("el frutero no mira a Kael al hablar (%.2f rad)" % giro)
			await _frames(110)
			v._bloqueo = 0.0
			v._comprobar_cerca()
			v._accion()
			await _frames(3)
			if not String(v.aviso.text).contains(fr["d"]["frases"][1]):
				_mal("la segunda vez, la segunda frase: «%s»" % v.aviso.text)
			else:
				_ok("hablar: botón, frase, gesto y giro; las frases se turnan")

	# ---------------------------------------------------------------- 5. barato: lejos y fuera de la vista
	await _kael(Vector3(72.0, 0.0, 43.5))               # al pie de la Torre de la Campana, lejos de la plaza
	await _frames(10)
	var ninos: Array = presentes.filter(func(g): return g["d"]["rutina"] == "corro")
	var n0: Node3D = ninos[0]["nodo"]
	var t_antes: float = n0.anim.current_animation_position if n0.anim else 0.0
	await _frames(30)
	var t_despues: float = n0.anim.current_animation_position if n0.anim else 0.0
	var dk := Vector2(n0.position.x - v.kael.global_position.x, n0.position.z - v.kael.global_position.z).length()
	if dk > MV.LEJOS and absf(t_despues - t_antes) > 0.0001:
		_mal("un niño a %.0f m se sigue animando" % dk)
	else:
		_ok("lejos (%.0f m): la animación quieta; reparto %s" % [dk, vivo.cuenta])
	if dk > MV.OCULTO and n0.visible:
		_mal("un niño a %.0f m se sigue dibujando" % dk)

	# ---------------------------------------------------------------- 6. la hora
	v.vida.poner_franja("anochecer", false)
	await _frames(70)
	var quedan: Array = presentes.filter(func(g): return g.get("presente", true)).map(func(g): return g["d"]["id"])
	if "nino_plaza" in quedan or "mercader_manzanas" in quedan:
		_mal("al anochecer siguen los niños o el frutero: %s" % [quedan])
	elif not "viajero_camino" in quedan or not "guardia_ronda" in quedan:
		_mal("al anochecer faltan el viajero o la ronda: %s" % [quedan])
	else:
		_ok("anochecer: se quedan %s" % [quedan])
	if vivo.palomas != null and vivo.palomas.visible:
		_mal("al anochecer siguen las palomas (la abuela se ha ido)")
	v.vida.poner_franja("tarde", false)

	# ---------------------------------------------------------------- 7. los vecinos con nombre
	var con_figura := []
	for id in MV.VECINOS:
		if not v.vida.vecinos.has(id):
			continue
		if v.vida.vecinos[id].get("chibi") == null:
			_mal("el vecino %s no lleva figura de la familia" % id)
		else:
			con_figura.append(id)
		if Oak.dialogo_de(id, 0) != dialogos_antes.get(id, ""):
			_mal("el diálogo de %s ha cambiado" % id)
	var ald = v.vida.vecinos["aldric"]
	if (ald["nodo"] as Node3D).position.distance_to(v.vida.sitio(v.vida.rutina_3d("aldric", "tarde")["casilla"])) > 0.05:
		_mal("Aldric no está en su sitio de siempre")
	_ok("vecinos con figura de la familia y su diálogo de siempre: %s" % [con_figura])
	Engine.set_meta("mundo_vivo_sin_vecinos", true)
	await _cargar(true)
	if v.vida.vecinos.values().any(func(x): return x.get("chibi") != null):
		_mal("con «mundo_vivo_sin_vecinos» un vecino lleva figura nueva")
	Engine.remove_meta("mundo_vivo_sin_vecinos")
	Engine.remove_meta("mundo_vivo_v12")
	_fin()


func _fin() -> void:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
