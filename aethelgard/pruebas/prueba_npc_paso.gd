extends SceneTree
# NPC que bloqueaban puertas y caminos en Oakhaven (13/11, visto en el Redmi v688: la vendedora se quedaba en la Puerta
# del Sur y Kael, detrás, no podía pasar; los dos se esperaban). Con el mundo vivo encendido comprueba:
#   1. nadie que anda empieza su rutina en una zona de paso (la Puerta del Sur), con muchas semillas;
#   2. en la puerta nadie hace pausas: cruza y sigue con su ruta;
#   3. ceder el paso: quien anda y tiene a Kael delante se aparta a un sitio libre, espera y, cuando Kael se aleja,
#      llega a su destino (la rutina sigue);
#   4. los choques se conservan: Kael no atraviesa a nadie al momento; solo si lleva más de PASO_LIBRE_TRAS empujando
#      contra el mismo, pasa (nunca se queda atrapado); al separarse, vuelve a chocar;
#   5. los que trabajan siguen en su sitio con su tarea.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_npc_paso.gd --fixed-fps 30 -- 3d sin_prologo

const REGION := "res://zonas3d/oakhaven_3d.tscn"
var MV = load("res://zonas3d/oakhaven/mundo_vivo.gd")
var v
var fallos := 0


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


func _cargar() -> void:
	for k in ["mazmorras", "cofres_abiertos", "lore_visto", "hitos", "decisiones", "oak_franja", "oak_franja_t", "pos_3d"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("mundo_vivo_v12", true)
	change_scene_to_file(REGION)
	await _frames(25)
	v = current_scene


func _g(id: String) -> Dictionary:
	for g in v.vivo.gente:
		if g["d"]["id"] == id:
			return g
	return {}


func _correr() -> void:
	await _frames(2)
	await _cargar()
	if v == null or v.vivo == null:
		_mal("no hay mundo vivo en Oakhaven")
		_fin()
		return
	var vivo = v.vivo
	# ---------------------------------------------------------------- 1. nadie empieza en la puerta
	var en_puerta := 0
	for semilla in 40:
		seed(1000 + semilla)
		for g in vivo.gente:
			if g["d"]["rutina"] in ["ruta", "barrer"]:
				vivo._colocar_inicio(g)
				var n: Node3D = g["nodo"]
				if MV.en_paso(Vector2(n.position.x, n.position.z)):
					en_puerta += 1
	if en_puerta == 0:
		_ok("1: en 40 semillas, nadie que anda empieza en la Puerta del Sur")
	else:
		_mal("1: %d comienzos dentro de la Puerta del Sur" % en_puerta)
	var dentro_inicio: bool = MV.en_paso(Vector2(40, 53.5))
	if dentro_inicio:
		_ok("1: el sitio donde aparece Kael (40, 53.5) es zona de paso")
	else:
		_mal("1: la zona de paso no cubre la llegada de Kael")
	# ---------------------------------------------------------------- 2. sin pausas en la puerta
	var vend := _g("vendedora_fruta")
	if vend.is_empty():
		_mal("2: falta la vendedora")
	else:
		var pts: Array = vend["d"]["puntos"]
		var i_puerta := -1
		for i in pts.size():
			if MV.en_paso(pts[i]):
				i_puerta = i
				break
		var n: Node3D = vend["nodo"]
		vend["i"] = i_puerta
		vend["pausa"] = 0.0
		var p: Vector2 = pts[i_puerta]
		n.position = Vector3(p.x, 0.0, p.y)
		vivo._pensar(vend, 1.0 / 30.0, Vector3(5, 0, 5))         # Kael lejos: llega al punto de la puerta
		if float(vend["pausa"]) <= 0.0 and vend["i"] != i_puerta:
			_ok("2: en el punto de la puerta (%s) no se para: sigue al siguiente" % str(p))
		else:
			_mal("2: se para %.1f s en la puerta" % float(vend["pausa"]))
	# ---------------------------------------------------------------- 3. ceder el paso
	var nodo: Node3D = vend["nodo"]
	var origen := Vector2(40.6, 38.0)                            # Calle Mayor, camino de la plaza
	var meta := Vector2(40.6, 31.0)
	nodo.position = Vector3(origen.x, MV.alto_en(origen), origen.y)
	var g := {"d": vend["d"], "nodo": nodo}
	var kael := Vector3(40.6, 0.0, 37.3)                         # Kael justo delante, en su camino
	var apartado := false
	for f in 30:                                                 # 1 s con Kael delante
		vivo._andar_hacia(nodo, meta, 1.0, 1.0 / 30.0, kael, "", g)
		if g.has("apartado"):
			apartado = true
	var pn := Vector2(nodo.position.x, nodo.position.z)
	if apartado and pn.distance_to(origen) > 0.3 and pn.distance_to(Vector2(kael.x, kael.z)) > MV.DIST_PARAR:
		_ok("3: con Kael delante se aparta a un lado (%.2f m) y deja el paso libre" % pn.distance_to(origen))
	else:
		_mal("3: no se aparta (apartado=%s, movido %.2f m)" % [apartado, pn.distance_to(origen)])
	var ap = g.get("apartado")
	if ap != null and vivo._libre(ap):
		_ok("3: el sitio donde se aparta se puede pisar (no es un muro ni un edificio)")
	elif ap != null:
		_mal("3: se aparta a un sitio bloqueado %s" % str(ap))
	kael = Vector3(60, 0, 60)                                    # Kael se va
	var llega := false
	for f in 30 * 15:
		if vivo._andar_hacia(nodo, meta, 1.0, 1.0 / 30.0, kael, "", g):
			llega = true
			break
	if llega and not g.has("apartado"):
		_ok("3: cuando Kael se aleja, vuelve a su camino y llega a su destino")
	else:
		_mal("3: no vuelve a su camino (llega=%s)" % llega)
	# ---------------------------------------------------------------- 4. choques conservados y sin atrapar a Kael
	var otro := _g("herrero_aprendiz")             # quieto en su trabajo (el de ronda se movería)
	var on: Node3D = otro["nodo"]
	var q := on.global_position
	if vivo.ocupa(q):
		_ok("4: Kael no atraviesa a nadie al momento")
	else:
		_mal("4: Kael atraviesa a alguien sin más")
	var t0 := Time.get_ticks_msec()
	var paso := false
	while Time.get_ticks_msec() - t0 < 1500:
		q = on.global_position
		if not vivo.ocupa(q):
			paso = true
			break
		await process_frame
	var tarda := (Time.get_ticks_msec() - t0) / 1000.0
	if paso and tarda >= MV.PASO_LIBRE_TRAS * 0.9:
		_ok("4: tras %.2f s empujando contra el mismo, Kael pasa (nunca se queda atrapado)" % tarda)
	else:
		_mal("4: Kael sigue atrapado o pasa demasiado pronto (paso=%s, %.2f s)" % [paso, tarda])
	await _frames(15)                                            # se separa (0,5 s sin tocarle)
	OS.delay_msec(400)
	if vivo.ocupa(q):
		_ok("4: al separarse, el choque vuelve")
	else:
		_mal("4: tras separarse, sigue sin chocar")
	# ---------------------------------------------------------------- 5. los que trabajan, en su sitio
	var bien := 0
	var total := 0
	for gg in vivo.gente:
		if gg["d"]["rutina"] == "trabajo":
			total += 1
			var nn: Node3D = gg["nodo"]
			if Vector2(nn.position.x, nn.position.z).distance_to(gg["d"]["puntos"][0]) < 0.05:
				bien += 1
	if total > 0 and bien == total:
		_ok("5: los %d que trabajan siguen en su sitio" % total)
	else:
		_mal("5: %d de %d que trabajan fuera de su sitio" % [total - bien, total])
	_fin()


func _fin() -> void:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
