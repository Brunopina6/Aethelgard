extends SceneTree
# V12 (16/11): BARRIO EXPERIMENTAL de Oakhaven, agente C: la VIDA (zonas3d/barrio/barrio_vivo.gd, npc_barrio.gd,
# utensilios.gd; PROPUESTA, solo en el banco de Auditoría). Sin ventana.
#   1. La región en el banco monta la vida: los 6 vecinos y Avena, los programas compilan sin errores (nada se coge donde
#      no está, nada se deja sin llevarlo, cada programa acaba donde empieza).
#   2. Ciclos completos de cada programa (Maela, Tobías y Brena, con la misión y sin ella), muestreados cada 0,1 s: cada
#      objeto en UNA sola ubicación; coger y dejar solo junto a su sitio; lo que se pisa fuera es andable; nadie hace una
#      tarea, coge, deja ni se para en un umbral ni delante de una puerta; nadie pisa a Avena; lo que se ve en la escena
#      (la copia de cada objeto y su mano) es lo que dice su ubicación.
#   3. Hablar en CADA paso de cada rutina: si cruza un umbral, primero cruza; si coge o deja, termina; se para (su reloj
#      se congela) sin perder ni cambiar objetos, con «llevar_quieto» si lleva algo; al reanudar sigue donde estaba.
#      También con Dialogic de verdad (hablar desde el botón de la región, el diálogo empieza y al acabar se reanuda).
#   4. El salto fuera de la vista coincide con lo simulado (andar fotograma a fotograma o saltar el reloj da lo mismo) y
#      la misión cambia el programa (al momento si no se le ve).
#   5. Kael no pisa a los vecinos ni a Avena, y nunca queda atrapado; quien anda espera si Kael se le pone delante y, si
#      no se aparta, se hace a un lado y sigue (nadie espera al otro para siempre).
#   6. Avena no se mueve; bebe tras el agua y come tras el heno; el agua del abrevadero se ve.
#   7. Coste: µs de _process de la vida (PC).
#   8. DENTRO (los interiores de B): Damián, Odila y Nela en sus anclas, de cara a la cámara; Maela anda dentro del horno
#      en rectas que no cruzan muebles (cada 5 cm, lo andable de B) y nunca pisa un mueble en todo su ciclo; se le habla
#      dentro; la bandeja se ve en la solera del horno; se habla con Damián dentro del taller desde el botón (Dialogic);
#      tocar lo privado hace que su dueño se pare y mire a Kael; la galga de la repisa se oculta al cogerla y vuelve a su
#      clavo con el pasador; los utensilios son los del GLB de B (no cajas).
# Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const Vivo := preload("res://zonas3d/barrio/barrio_vivo.gd")
var fallos := 0
var r                                       # la región
var v                                       # la vida


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: " + t)


func _nota(t: String) -> void:
	print(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	await _cargar()
	if v != null:
		_montaje()
		_ciclos()
		await _hablar()
		await _dialogo_real()
		await _salto()
		await _ocupa()
		await _avena()
		await _coste()
		await _dentro()
	var BP = load("res://banco_pruebas.gd")
	if current_scene != null:
		current_scene.queue_free()
		await _frames(3)
	BP.salir()
	_ok(not Engine.has_meta("barrio_reloj"), "al salir del banco queda el reloj del barrio")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _cargar() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", "bajo")
	change_scene_to_file(ESCENA)
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			r = current_scene
			break
	await _frames(10)
	_ok(r != null and r.vivo != null and r.vivo.get_script() == Vivo, "1: la región no carga la vida")
	if r != null:
		v = r.vivo


# ================================================================= 1

func _montaje() -> void:
	_ok(v.errores.is_empty(), "1: errores al compilar: %s" % [v.errores])
	_ok(v.vecinos.size() == 6, "1: %d vecinos (6)" % v.vecinos.size())
	for id in ["maela", "tobias", "brena", "damian", "odila", "nela"]:
		_ok(v.vecinos.has(id), "1: falta %s" % id)
	_ok(v.avena != null and v.agua != null, "1: falta Avena o el agua del abrevadero")
	for id in v.PROGRAMAS:
		for prog in v.PROGRAMAS[id]:
			if not v.PROGRAMAS[id][prog] is Array:
				continue
			v.errores.clear()
			var c: Dictionary = v.compilar(id, prog)
			_ok(v.errores.is_empty(), "1: %s/%s: %s" % [id, prog, v.errores])
			_nota("ciclo %s/%s: %.1f s, %d tramos" % [id, prog, c["ciclo"], c["segs"].size()])
	for id in v.vecinos:
		var w: Dictionary = v.vecinos[id]
		_nota("%s: %s (%s)" % [id, "chibi " + str(Barrio.NPCS[id]["chibi"]) if w["chibi"] != null else "cápsula de reserva",
			w["programa"]])
	for o in v.objetos:
		_nota("objeto %s (%s): %s" % [o, "modelo" if load("res://zonas3d/barrio/utensilios.gd").del_modelo(o) else "caja de reserva",
			v.objetos[o]["sitios"].keys()])


# ================================================================= 2

func _sitio_pos(s: String) -> Vector3:
	var d: Dictionary = v.SITIOS[s]
	var p: Vector3 = d["pos"]
	return Vector3(p.x, T.altura(p.x, p.z), p.z)


func _en_puerta(p: Vector3) -> String:
	for id in T.PUERTAS:
		var f: Vector3 = T.PUERTAS[id]["fuera"]
		if Vector2(p.x - f.x, p.z - f.z).length() < 0.9:
			return id
	return ""


func _ciclos() -> void:
	for id in v.PROGRAMAS:
		for prog in v.PROGRAMAS[id]:
			if not v.PROGRAMAS[id][prog] is Array:
				continue
			var c: Dictionary = v.compilar(id, prog)
			var w := {"segs": c["segs"], "ciclo": c["ciclo"]}
			var donde := "%s/%s" % [id, prog]
			var malos := {}
			var tau := 0.0
			var antes := {}
			while tau < c["ciclo"]:
				var e: Dictionary = v.estado_en(w, tau)
				var p: Vector3 = e["pos"]
				var s: Dictionary = e["seg"]
				for obj in e["ubic"]:
					var u: String = e["ubic"][obj]
					if not (u == "mano" or (u.begins_with("sitio:") and v.SITIOS.has(u.trim_prefix("sitio:")))):
						malos["ubicación rara de %s: %s" % [obj, u]] = true
					if antes.has(obj) and antes[obj] != u and not s["tipo"] in ["coger", "dejar"]:
						malos["%s cambia de sitio sin coger ni dejar (%s → %s)" % [obj, antes[obj], u]] = true
				if s["tipo"] in ["coger", "dejar"]:
					var sitio: String = s["sitio"]
					if str(v.SITIOS[sitio]["lugar"]) == "":
						var q := _sitio_pos(sitio)
						if Vector2(p.x - q.x, p.z - q.z).length() > 1.7:
							malos["%s %s en %s desde lejos (%.1f m)" % [s["tipo"], s["obj"], sitio, Vector2(p.x - q.x, p.z - q.z).length()]] = true
				if e["lugar"] == "":
					var paso := T.en_paso(p.x, p.z)
					if not T.andable(p.x, p.z) and paso == "":
						malos["pisa lo que no es andable en %s" % p] = true
					if s["tipo"] != "ir" and (paso != "" or _en_puerta(p) != ""):
						malos["%s en un umbral o delante de una puerta (%s)" % [s["tipo"], p]] = true
					if v._dist_avena(p) < v.RADIO_AVENA:
						malos["pisa a Avena en %s" % p] = true
				antes = e["ubic"].duplicate()
				tau += 0.1
			for m in malos:
				_ok(false, "2: %s: %s" % [donde, m])
			# el final del ciclo: cada objeto vuelve a su sitio o se queda donde se dejó (el ciclo siguiente lo repone)
			for obj in c["final"]:
				_ok(str(c["final"][obj]).begins_with("sitio:"), "2: %s acaba con %s en la mano" % [donde, obj])
	# lo que se ve: con Kael junto a cada vecino, una sola copia visible por objeto y en su ubicación
	for id in ["maela", "tobias", "brena"]:
		var w: Dictionary = v.vecinos[id]
		for k in 12:
			v.avanzar_reloj(w["ciclo"] / 12.0)
			var e: Dictionary = v.estado_de(id)
			if e["lugar"] != "":
				continue
			r._colocar_kael(_libre_cerca(e["pos"]))
			v.avanzar_reloj(0.0)
			for obj in e["ubic"]:
				var o: Dictionary = v.objetos[obj]
				var n_vis := 0
				for s in o["sitios"]:
					if (o["sitios"][s] as Node3D).visible:
						n_vis += 1
						_ok(e["ubic"][obj] == "sitio:" + s, "2: %s: se ve %s en %s, pero está en %s" % [id, obj, s, e["ubic"][obj]])
				if (o["mano"] as Node3D).is_visible_in_tree():
					n_vis += 1
					_ok(e["ubic"][obj] == "mano", "2: %s: se ve %s en la mano, pero está en %s" % [id, obj, e["ubic"][obj]])
				var interior_sin_hacer: bool = e["ubic"][obj].begins_with("sitio:") and str(v.SITIOS[e["ubic"][obj].trim_prefix("sitio:")]["lugar"]) != ""
				_ok(n_vis == (0 if interior_sin_hacer else 1), "2: %s: %s se ve %d veces (%s)" % [id, obj, n_vis, e["ubic"][obj]])


func _libre_cerca(p: Vector3) -> Vector3:
	for d in [Vector3(1.6, 0, 0), Vector3(-1.6, 0, 0), Vector3(0, 0, 1.6), Vector3(0, 0, -1.6), Vector3(2.4, 0, 1.2)]:
		var q: Vector3 = p + d
		if T.andable(q.x, q.z):
			return Vector3(q.x, T.altura(q.x, q.z), q.z)
	return T.ancla("inicio")


# ================================================================= 3

func _hablar() -> void:
	Engine.set_meta("prologo_visto", false)                 # (sin diálogos: la frase suelta; la guardia lo permite)
	for id in ["maela", "tobias", "brena"]:
		var w: Dictionary = v.vecinos[id]
		var vistos := 0
		for s in w["segs"]:
			if s["tipo"] == "evento":
				continue
			var tau: float = float(s["t0"]) + float(s["dur"]) * 0.5
			w["retraso"] = v.t - tau
			w["vuelta"] = floori((v.t - w["retraso"]) / w["ciclo"])
			v.avanzar_reloj(0.0)
			var e0: Dictionary = v.estado_de(id)
			if e0["lugar"] != "":
				continue                                     # (dentro del horno: Kael no la ve, no se le puede hablar)
			r._colocar_kael(_libre_cerca(e0["pos"]))
			v.avanzar_reloj(0.0)
			v.hablar(id)
			var f := 0
			while w["charla"] == "pendiente" and f < 200:
				await process_frame
				f += 1
			var e1: Dictionary = v.estado_de(id)
			if w["charla"] != "hablando":
				_ok(e1["lugar"] != "" or e0["seg"]["tipo"] in ["coger", "dejar"], "3: %s en %s: no se para a hablar (%s)" % [id, s["tipo"], w["charla"]])
				v.reanudar_todos()
				continue
			vistos += 1
			_ok(T.en_paso(e1["pos"].x, e1["pos"].z) == "", "3: %s habla dentro de un umbral" % id)
			_ok(not e1["seg"]["tipo"] in ["coger", "dejar"] or e1["frac"] >= 1.0, "3: %s habla a mitad de %s" % [id, e1["seg"]["tipo"]])
			if e0["seg"]["tipo"] in ["coger", "dejar"]:
				_ok(e1["tau"] >= float(e0["seg"]["t0"]) + float(e0["seg"]["dur"]) - 0.01 or e1["tau"] < float(e0["seg"]["t0"]),
					"3: %s: hablar a mitad de %s no lo termina" % [id, e0["seg"]["tipo"]])
			var tau_parado: float = e1["tau"]
			await _frames(20)
			var e2: Dictionary = v.estado_de(id)
			_ok(absf(e2["tau"] - tau_parado) < 0.001 and e2["pos"].distance_to(e1["pos"]) < 0.001,
				"3: %s no se para al hablar (τ %.2f → %.2f)" % [id, tau_parado, e2["tau"]])
			_ok(e2["ubic"] == e1["ubic"], "3: %s pierde o cambia objetos al hablar" % id)
			var lleva: bool = e2["ubic"].values().has("mano")
			if w["chibi"] != null:
				_ok(w["clip"] == ("llevar_quieto" if lleva else "hablar"), "3: %s habla con «%s» (lleva algo: %s)" % [id, w["clip"], lleva])
			var n: Node3D = w["nodo"]
			var hacia: Vector3 = r.kael.global_position - n.global_position
			_ok(absf(angle_difference(n.rotation.y, atan2(hacia.x, hacia.z))) < 0.35, "3: %s no mira a Kael al hablar" % id)
			v.reanudar_todos()
			await _frames(10)
			var e3: Dictionary = v.estado_de(id)
			_ok(e3["tau"] >= tau_parado - 0.001 and e3["tau"] - tau_parado < 1.5, "3: %s no sigue donde estaba (τ %.2f → %.2f)" % [id, tau_parado, e3["tau"]])
			_ok(w["charla"] == "", "3: %s sigue hablando tras reanudar" % id)
		_ok(vistos >= 6, "3: con %s solo se ha podido hablar en %d pasos" % [id, vistos])
		_nota("hablar con %s: %d pasos de su rutina" % [id, vistos])
	# en un umbral: primero cruza (Maela saliendo del horno)
	var m: Dictionary = v.vecinos["maela"]
	for s in m["segs"]:
		if s["tipo"] == "ir" and s["lugar"] == "" and T.en_paso(s["pts"][0].x, s["pts"][0].z) != "":
			m["retraso"] = v.t - (float(s["t0"]) + 0.15)
			v.avanzar_reloj(0.0)
			var e: Dictionary = v.estado_de("maela")
			_ok(T.en_paso(e["pos"].x, e["pos"].z) != "", "3: la prueba no pone a Maela en el umbral (%s, τ %.2f, tramo %.2f, %s)" % [
				e["pos"], e["tau"], s["t0"], m["charla"]])
			r._colocar_kael(_libre_cerca(e["pos"] + Vector3(0, 0, 1.5)))
			v.hablar("maela")
			_ok(m["charla"] == "pendiente", "3: en el umbral, Maela se para en vez de cruzar")
			var f := 0
			while m["charla"] == "pendiente" and f < 200:
				await process_frame
				f += 1
			var e2: Dictionary = v.estado_de("maela")
			_ok(m["charla"] == "hablando" and T.en_paso(e2["pos"].x, e2["pos"].z) == "", "3: Maela no cruza el umbral antes de hablar")
			v.reanudar_todos()
			break
	Engine.set_meta("prologo_visto", true)
	await _frames(5)


# Con Dialogic: el botón de la región («Hablar con Brena») empieza su diálogo; al acabar, se reanuda.
func _dialogo_real() -> void:
	var D = root.get_node_or_null("Dialogic")
	var w: Dictionary = v.vecinos["brena"]
	for s in w["segs"]:
		if s["tipo"] == "tarea" and s["clip"] == "cepillar":
			w["retraso"] = v.t - (float(s["t0"]) + 5.0)
	v.avanzar_reloj(0.0)
	var e: Dictionary = v.estado_de("brena")
	r._colocar_kael(_libre_cerca(e["pos"]))
	await _frames(5)
	r._bloqueo = 0.0
	r._comprobar_cerca()
	_ok(r.cerca == "brena" and r.boton_accion.text == "Hablar con Brena", "3D: el botón no ofrece hablar con Brena (%s)" % r.cerca)
	r._accion()
	await _frames(5)
	_ok(D != null and D.current_timeline != null, "3D: hablar con Brena no empieza su diálogo")
	_ok(w["charla"] == "hablando" and (w["chibi"] == null or w["clip"] == "llevar_quieto"), "3D: Brena no se para con el cepillo (%s, %s)" % [w["charla"], w["clip"]])
	var tau: float = v.estado_de("brena")["tau"]
	await _frames(30)
	_ok(absf(v.estado_de("brena")["tau"] - tau) < 0.001, "3D: el reloj de Brena corre durante el diálogo")
	if D != null and D.current_timeline != null:
		D.end_timeline(true)
	await _frames(10)
	_ok(w["charla"] == "" and v.estado_de("brena")["ubic"]["cepillo"] == "mano", "3D: al acabar, Brena no sigue con el cepillo (%s, %s, %s)" % [
		w["charla"], v.estado_de("brena")["ubic"], D.current_timeline if D != null else null])


# ================================================================= 4

func _salto() -> void:
	r._colocar_kael(T.ancla("n_res_o"))                      # (lejos de todos: arriba, en la calle de las casas)
	await _frames(3)
	for id in ["maela", "tobias", "brena"]:
		var w: Dictionary = v.vecinos[id]
		var t0: float = v.t
		var tau0: float = v.estado_de(id)["tau"]
		await _frames(60)
		var dt: float = v.t - t0
		var esperado := fposmod(tau0 + dt, float(w["ciclo"]))
		_ok(absf(v.estado_de(id)["tau"] - esperado) < 0.01, "4: %s: andar fotograma a fotograma no coincide con el reloj (%.3f / %.3f; t %.3f → %.3f, τ0 %.3f, %s)" % [
			id, v.estado_de(id)["tau"], esperado, t0, v.t, tau0, w["charla"]])
		v.avanzar_reloj(1000.0)
		var e: Dictionary = v.estado_de(id)
		_ok(absf(e["tau"] - fposmod(esperado + 1000.0, float(w["ciclo"]))) < 0.01, "4: %s: el salto de 1000 s no cae donde toca" % id)
		if e["lugar"] == "":
			r._colocar_kael(_libre_cerca(e["pos"]))
			v.avanzar_reloj(0.0)
			_ok((w["nodo"] as Node3D).visible and (w["nodo"] as Node3D).global_position.distance_to(v.estado_de(id)["pos"]) < 0.01,
				"4: %s: al volver a verlo no está donde le toca" % id)
			r._colocar_kael(T.ancla("n_res_o"))
			v.avanzar_reloj(0.0)
	# la misión cambia el programa: sin que se le vea, al momento
	var P = load("res://progreso.gd")
	P.poner_estado(Barrio.NOMBRE, "enf_carro_visto")
	await _frames(20)
	_ok(v.vecinos["maela"]["programa"] == "carro_parado" and v.vecinos["tobias"]["programa"] == "carro_parado",
		"4: con la misión empezada, Maela y Tobías no esperan junto al carro (%s, %s)" % [v.vecinos["maela"]["programa"], v.vecinos["tobias"]["programa"]])
	P.poner_estado(Barrio.NOMBRE, "enf_reparado")
	await _frames(20)
	_ok(v.vecinos["maela"]["programa"] == "reparto" and v.vecinos["tobias"]["programa"] == "reparto", "4: con el carro arreglado, no hay reparto")
	var m: Dictionary = Engine.get_meta("mazmorras", {})
	m.erase(Barrio.NOMBRE)
	Engine.set_meta("mazmorras", m)
	await _frames(20)
	_ok(v.vecinos["maela"]["programa"] == "normal", "4: sin la misión, Maela no vuelve a lo normal")
	# el reloj sobrevive a la recarga (meta de sesión)
	v.guardar_reloj()
	var reloj: Dictionary = Engine.get_meta("barrio_reloj", {})
	_ok(reloj.has("t") and reloj["npc"].has("maela"), "4: el reloj del barrio no se guarda en la sesión")


# ================================================================= 5

func _ocupa() -> void:
	var w: Dictionary = v.vecinos["tobias"]
	for s in w["segs"]:
		if s["tipo"] == "tarea":
			w["retraso"] = v.t - (float(s["t0"]) + 0.5)
			break
	v.avanzar_reloj(0.0)
	var p: Vector3 = v.estado_de("tobias")["pos"]
	r._colocar_kael(p + Vector3(1.4, 0, 0))
	v.avanzar_reloj(0.0)
	_ok(v.ocupa(p) and r._prohibido(p), "5: Kael puede pisar a Tobías")
	r._colocar_kael(p + Vector3(0.2, 0, 0))                 # (Kael dentro de su círculo: puede salir)
	v.avanzar_reloj(0.0)
	_ok(not v.ocupa(p + Vector3(0.3, 0, 0)), "5: Kael queda atrapado junto a Tobías")
	var c: Vector3 = T.ancla("establo_caballo")
	r._colocar_kael(c + Vector3(2.0, 0, 0.6))
	v.avanzar_reloj(0.0)
	_ok(v.ocupa(c) and r._prohibido(c), "5: Kael puede pisar a Avena")
	# quien anda espera si Kael se le pone delante
	for s in w["segs"]:
		if s["tipo"] == "ir" and Vector2(s["pts"][0].x - s["pts"][1].x, s["pts"][0].z - s["pts"][1].z).length() > 6.0:
			w["retraso"] = v.t - (float(s["t0"]) + float(s["dur"]) * 0.4)
			break
	v.avanzar_reloj(0.0)
	var e: Dictionary = v.estado_de("tobias")
	var pts: Array = e["seg"]["pts"]
	var delante: Vector3 = e["pos"] + (v._por_la_ruta(pts, minf(1.0, e["frac"] + 0.05)) - e["pos"]).normalized() * 0.7
	r._colocar_kael(delante)
	await _frames(15)
	var e2: Dictionary = v.estado_de("tobias")
	_ok(e2["pos"].distance_to(e["pos"]) < 0.05 and w["parado"], "5: Tobías no espera con Kael delante (se mueve %.2f m)" % e2["pos"].distance_to(e["pos"]))
	await _frames(60)                                       # (Kael no se aparta: Tobías se hace a un lado y sigue)
	var e3: Dictionary = v.estado_de("tobias")
	_ok(e3["pos"].distance_to(e["pos"]) > 0.3 and (w["desvio"] as Vector3).length() > 0.3,
		"5: Tobías se queda esperando a Kael para siempre (se mueve %.2f m, desvío %.2f)" % [e3["pos"].distance_to(e["pos"]), (w["desvio"] as Vector3).length()])
	_ok(T.andable(w["pos"].x, w["pos"].z), "5: al apartarse, Tobías pisa lo que no es andable")
	r._colocar_kael(T.ancla("n_res_o"))
	await _frames(15)
	_ok(v.estado_de("tobias")["pos"].distance_to(e["pos"]) > 0.1, "5: Tobías no sigue cuando Kael se aparta")


# ================================================================= 6

func _avena() -> void:
	var c: Vector3 = v.avena.position
	var w: Dictionary = v.vecinos["brena"]
	var t_agua := -1.0
	for s in w["segs"]:
		if s["tipo"] == "evento" and s["evento"] == "agua":
			t_agua = s["t0"]
	_ok(t_agua > 0.0, "6: la rutina de Brena no vierte agua")
	w["retraso"] = v.t - (t_agua + 1.0)
	r._colocar_kael(T.ancla("n_establo") + Vector3(1.5, 0, 1.5))
	v.avanzar_reloj(0.0)
	await _frames(3)
	_ok(v.estado_avena()["clip"] == "beber" and v.agua.visible, "6: tras el agua, Avena no bebe o no se ve el agua")
	w["retraso"] = v.t - 2.0
	v.avanzar_reloj(0.0)
	await _frames(3)
	_ok(not v.agua.visible, "6: el abrevadero ya está lleno al empezar el ciclo")
	_ok(v.avena.position == c, "6: Avena se ha movido")
	_nota("Avena: %s" % ("prototipo de Blender" if v.avena_anim != null else "reserva de cajas"))


# ================================================================= 7

func _coste() -> void:
	r._colocar_kael(T.ancla("n_com_o"))
	await _frames(120)
	_nota("us_proceso de la vida: %.0f µs" % v.us_proceso)
	_ok(v.us_proceso < 1500.0, "7: la vida tarda %.0f µs por fotograma (> 1,5 ms)" % v.us_proceso)


# ================================================================= 8

func _recta_sin_muebles(a: Vector3, b: Vector3) -> bool:
	var n := maxi(1, ceili(Vector2(b.x - a.x, b.z - a.z).length() / 0.05))
	for i in range(0, n + 1):
		if not r.interiores.andable(a.lerp(b, float(i) / n)):
			return false
	return true


func _entrar(id: String) -> void:
	r._pasar_dentro(id)
	await _frames(5)


func _salir() -> void:
	r._pasar_fuera()
	await _frames(5)


func _dentro() -> void:
	var U = load("res://zonas3d/barrio/utensilios.gd")
	for o in U.NOMBRES:
		_ok(U.del_modelo(o), "8: el utensilio %s no sale del GLB de B (caja de reserva)" % o)
	var I = r.interiores
	# los de su puesto, dentro, en el ancla de B y de cara a la cámara (al sur)
	for par in [["damian", "taller", "int_taller_damian"], ["odila", "vivienda", "int_vivienda_odila"],
			["nela", "vivienda", "int_vivienda_nela"]]:
		var w: Dictionary = v.vecinos[par[0]]
		var e: Dictionary = v.estado_de(par[0])
		_ok(e["lugar"] == par[1] and e["pos"].distance_to(I.ancla(par[2])) < 0.01, "8: %s no está en %s (%s, %s)" % [
			par[0], par[2], e["lugar"], e["pos"]])
		_ok(I.andable(e["pos"]), "8: %s está sobre un mueble" % par[0])
		await _entrar(par[1])
		_ok((w["nodo"] as Node3D).visible and absf(angle_difference((w["nodo"] as Node3D).rotation.y, 0.0)) < 0.2,
			"8: %s no se ve dentro o no mira a la cámara (%.2f)" % [par[0], (w["nodo"] as Node3D).rotation.y])
		await _salir()
	# Maela dentro: tramos rectos sin muebles; en todo el ciclo, lo que pisa dentro es andable
	for prog in ["normal", "carro_parado", "reparto"]:
		v.errores.clear()
		var c: Dictionary = v.compilar("maela", prog)
		_ok(v.errores.is_empty(), "8: maela/%s: %s" % [prog, v.errores])
		var tramos := 0
		for s in c["segs"]:
			if s["tipo"] == "ir" and s["lugar"] == "horno":
				for i in range(1, s["pts"].size()):
					tramos += 1
					_ok(_recta_sin_muebles(s["pts"][i - 1], s["pts"][i]), "8: maela/%s: el tramo %s → %s cruza un mueble" % [
						prog, s["pts"][i - 1], s["pts"][i]])
		var w := {"segs": c["segs"], "ciclo": c["ciclo"]}
		var tau := 0.0
		var malos := 0
		while tau < c["ciclo"]:
			var e: Dictionary = v.estado_en(w, tau)
			if e["lugar"] == "horno" and not I.andable(e["pos"]):
				malos += 1
			tau += 0.1
		_ok(malos == 0 and tramos >= 3, "8: maela/%s: %d instantes dentro sobre un mueble (%d tramos rectos)" % [prog, malos, tramos])
		_nota("maela/%s: %d tramos rectos dentro del horno" % [prog, tramos])
	# hablar con Maela dentro del horno (en su artesa, en la boca) y ver la bandeja en la solera
	Engine.set_meta("prologo_visto", false)                 # (la frase suelta)
	await _entrar("horno")
	var m: Dictionary = v.vecinos["maela"]
	var hablados := 0
	for s in m["segs"]:
		if s["lugar"] != "horno" or s["tipo"] == "evento":
			continue
		m["retraso"] = v.t - (float(s["t0"]) + float(s["dur"]) * 0.5)
		v.avanzar_reloj(0.0)
		var e: Dictionary = v.estado_de("maela")
		if e["lugar"] != "horno":
			continue
		for d in [Vector3(0, 0, 1.2), Vector3(1.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(0, 0, -1.2), Vector3(0.9, 0, 0.9)]:
			if I.andable(e["pos"] + d):
				r._colocar_kael(e["pos"] + d)
				break
		v.avanzar_reloj(0.0)
		r._bloqueo = 0.0
		r._comprobar_cerca()
		if r.cerca != "maela":
			continue
		v.hablar("maela")
		var f := 0
		while m["charla"] == "pendiente" and f < 200:
			await process_frame
			f += 1
		if m["charla"] == "hablando":
			hablados += 1
			var n: Node3D = m["nodo"]
			var hacia: Vector3 = r.kael.global_position - n.global_position
			_ok(n.visible and absf(angle_difference(n.rotation.y, atan2(hacia.x, hacia.z))) < 0.35, "8: Maela no mira a Kael dentro")
		v.reanudar_todos()
		await _frames(3)
	_ok(hablados >= 3, "8: dentro del horno solo se ha podido hablar con Maela %d veces" % hablados)
	_nota("hablar con Maela dentro del horno: %d pasos" % hablados)
	for s in m["segs"]:                                      # (amasando: la bandeja está en la boca)
		if s["tipo"] == "tarea" and s["clip"] == "amasar":
			m["retraso"] = v.t - (float(s["t0"]) + 1.0)
	v.avanzar_reloj(0.0)
	var boca: Node3D = v.objetos["bandeja"]["sitios"]["boca"]
	_ok(boca.visible and boca.global_position.y > I.ORIGEN["horno"].y + 0.9, "8: la bandeja no se ve en la solera del horno (%s)" % boca.global_position)
	await _salir()
	Engine.set_meta("prologo_visto", true)
	# Damián dentro del taller, desde el botón de la región (Dialogic)
	var D = root.get_node_or_null("Dialogic")
	await _entrar("taller")
	r._colocar_kael(I.ancla("int_taller_damian") + Vector3(1.2, 0, 0.3))
	await _frames(5)
	r._bloqueo = 0.0
	r._comprobar_cerca()
	_ok(r.cerca == "damian" and r.boton_accion.text == "Hablar con Damián", "8: dentro del taller el botón no ofrece hablar con Damián (%s)" % r.cerca)
	r._accion()
	await _frames(5)
	_ok(D != null and D.current_timeline != null and v.vecinos["damian"]["charla"] == "hablando", "8: hablar con Damián dentro no empieza su diálogo")
	if D != null and D.current_timeline != null:
		D.end_timeline(true)
	await _frames(10)
	_ok(v.vecinos["damian"]["charla"] == "", "8: Damián sigue parado tras el diálogo")
	# lo privado: Damián contesta y mira a Kael (la trastienda, cerrada); no cambia nada
	var antes: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}).duplicate()
	r._colocar_kael(I.ancla("int_taller_paso_trastienda") + Vector3(0.3, 0, 0))
	await _frames(5)
	r._bloqueo = 0.0
	r._comprobar_cerca()
	_ok(r.cerca == "trastienda" or Barrio.paso_interno("trastienda"), "8: junto a la trastienda el botón no la ofrece (%s)" % r.cerca)
	_ok(Barrio.presentes.has("damian"), "8: Damián no cuenta como presente en el taller")
	r._accion_barrio("banco_corte")
	await _frames(3)
	var dm: Dictionary = v.vecinos["damian"]
	var hacia: Vector3 = r.kael.global_position - (dm["nodo"] as Node3D).global_position
	_ok(dm["charla"] == "hablando" and absf(angle_difference((dm["nodo"] as Node3D).rotation.y, atan2(hacia.x, hacia.z))) < 0.35,
		"8: tocar lo de Damián no le hace contestar ni mirar (%s)" % dm["charla"])
	_ok(r.ultimo_aviso.begins_with("Damián:"), "8: el aviso de lo privado no es de Damián («%s»)" % r.ultimo_aviso)
	_ok(Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}) == antes, "8: tocar lo privado cambia la partida")
	await _frames(int(v.PAUSA_FRASE * 60) + 20)
	_ok(dm["charla"] == "", "8: Damián no vuelve a lo suyo tras contestar")
	# hablarle MIENTRAS contesta (o dice una frase): se habla ya (antes el botón no hacía nada durante 3,2 s)
	r._accion_barrio("banco_corte")
	await _frames(3)
	v.hablar("damian")
	await _frames(3)
	_ok(dm["charla"] == "hablando" and dm["con_dialogo"] and D != null and D.current_timeline != null,
		"8: hablar con Damián mientras contesta no empieza su diálogo (%s, %s)" % [dm["charla"], dm["con_dialogo"]])
	if D != null and D.current_timeline != null:
		D.end_timeline(true)
	await _frames(10)
	await _salir()
	# la galga: en la repisa hasta cogerla; luego no; con el pasador, en su clavo del taller
	await _entrar("vivienda")
	var sitio: Node3D = I.sitio("galga")
	_ok(sitio != null and sitio.visible, "8: la galga no está en la repisa")
	var P = load("res://progreso.gd")
	P.poner_estado(Barrio.NOMBRE, "enf_galga")
	v.avanzar_reloj(0.0)
	_ok(sitio != null and not sitio.visible, "8: la repisa sigue enseñando la galga ya cogida")
	await _salir()
	P.poner_estado(Barrio.NOMBRE, "enf_medida")
	P.poner_estado(Barrio.NOMBRE, "enf_pasador")
	await _entrar("taller")
	_ok(v.galga_clavo != null and v.galga_clavo.visible and v.galga_clavo.global_position.distance_to(
		I.ORIGEN["taller"] + v.GALGA_CLAVO) < 0.01, "8: con el pasador, la galga no vuelve a su clavo")
	await _salir()
	_ok(v.galga_clavo == null or not v.galga_clavo.visible, "8: la galga del clavo se ve fuera del taller")
	var mz: Dictionary = Engine.get_meta("mazmorras", {})
	mz.erase(Barrio.NOMBRE)
	Engine.set_meta("mazmorras", mz)
