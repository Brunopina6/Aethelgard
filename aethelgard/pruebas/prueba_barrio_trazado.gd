extends SceneTree
# V12 (16/11): BARRIO EXPERIMENTAL de Oakhaven, fase 0 (zonas3d/barrio/; docs/v12/BARRIO_OAKHAVEN.md). Sin ventana.
#   1. El contrato (trazado.gd): están todas las anclas exteriores, los umbrales, las puertas (fuera, mira, radio, texto)
#      y los sectores; cada ancla está en lo andable, a la altura del suelo y fuera de los umbrales (salvo las
#      «puerta_*», que son el umbral); el grafo es simétrico y cada arista es un tramo recto que se anda entero.
#   2. Lo andable está conectado: BFS en rejilla de 0,25 m desde el inicio llega a TODO lo andable (y así a las puertas,
#      los nodos y las anclas).
#   3. La altura es continua (sin saltos de más de 0,3 m entre casillas vecinas) y hay desniveles de verdad (0 → 1,4 m).
#   4. La cámara: todo lo andable tiene alguna zona con peso; el foco no salta al recorrer cada arista del grafo; los
#      números son los de la muestra de la calle (altura, distancia, inclinación, campo) y no gira.
#   5. Lado sur bajo en los tramos de este a oeste (≤ 1,6 m sobre la calle a menos de 4 m del paso).
#   6. La región: carga en el banco, se activa (barrio_v12), construye el blockout (6 sectores, choques), tiene la API
#      del contrato, las puertas entran y salen si su interior existe (si no, «en obras»; sin el prólogo, la guardia),
#      guarda en el lugar 102.
#   7. Kael recorre el bucle completo con «destino» (caravanas → comercial → plaza → talleres → casas → atajo →
#      caravanas), sobre el suelo y sin girar la cámara, y no entra en las casas.
#   8. Fuera del banco la región no se construye (vuelve a la carga) y el barrio no está activado; al salir del banco no
#      quedan sus metas.
# Partida propia del banco (user://banco_pruebas.save, en la carpeta aislada de la pasada). Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
const PASO := 0.25
var fallos := 0
var v


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if cond:
		print("OK " + t)
	else:
		fallos += 1
		print("FALLO: " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	_contrato()
	_conectado()
	_alturas()
	_camara()
	_lado_sur()
	await _region()
	if v != null:
		await _bucle()
		await _no_entra()
	await _fuera_del_banco()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= 1

func _contrato() -> void:
	var faltan: Array = T.ANCLAS_CONTRATO.filter(func(a): return not T.ANCLAS.has(a))
	_ok(faltan.is_empty(), "1: están las %d anclas del contrato (faltan %s)" % [T.ANCLAS_CONTRATO.size(), str(faltan)])
	for p in ["paso_horno", "paso_taller", "paso_vivienda", "paso_atajo"]:
		_ok(T.PASOS.has(p), "1: umbral «%s»" % p)
	for id in ["horno", "taller", "vivienda"]:
		var d: Dictionary = T.PUERTAS.get(id, {})
		_ok(d.get("fuera") is Vector3 and d.get("mira") is float and float(d.get("radio", 0.0)) > 0.5
			and str(d.get("texto", "")) != "", "1: puerta «%s» con fuera, mira, radio y texto" % id)
		if d.has("fuera"):
			var f: Vector3 = d["fuera"]
			_ok(T.andable(f.x, f.z) and absf(f.y - T.altura(f.x, f.z)) < 0.02, "1: «fuera» de %s en el suelo (%s)" % [id, str(f)])
	_ok(T.SECTORES.size() == 6 and T.ORDEN.size() == 6 and T.COTAS.size() == 6, "1: 6 sectores con su Rect2 y sus cotas")
	var mal: Array = []
	for id in T.ANCLAS:
		var a: Vector3 = T.ANCLAS[id]
		if not T.andable(a.x, a.z):
			mal.append("%s fuera de lo andable" % id)
		if absf(a.y - T.altura(a.x, a.z)) > 0.02:
			mal.append("%s a %.3f y el suelo a %.3f" % [id, a.y, T.altura(a.x, a.z)])
		if not String(id).begins_with("puerta_") and T.en_paso(a.x, a.z) != "":
			mal.append("%s en el umbral %s" % [id, T.en_paso(a.x, a.z)])
		if T.sector_de(a.x, a.z) == "":
			mal.append("%s sin sector" % id)
	_ok(mal.is_empty(), "1: anclas andables, a la altura del suelo, fuera de los umbrales y con sector %s" % str(mal))
	for e in [["inicio", "caravanas"], ["puerta_horno", "comercial"], ["n_plaza", "plaza"], ["puerta_taller", "talleres"],
			["puerta_vivienda", "residencial"], ["n_atajo_n", "atajo"]]:
		var a: Vector3 = T.ancla(e[0])
		_ok(T.sector_de(a.x, a.z) == e[1], "1: %s está en el sector %s (%s)" % [e[0], e[1], T.sector_de(a.x, a.z)])
	var grafo_mal: Array = []
	for n in T.GRAFO:
		if not T.ANCLAS.has(n):
			grafo_mal.append("%s no es un ancla" % n)
			continue
		for m in T.GRAFO[n]:
			if not T.GRAFO.has(m) or not n in T.GRAFO[m]:
				grafo_mal.append("%s→%s sin vuelta" % [n, m])
			elif not _recto_andable(T.ancla(n), T.ancla(m)):
				grafo_mal.append("%s→%s no se anda en línea recta" % [n, m])
	_ok(grafo_mal.is_empty(), "1: grafo simétrico de %d nodos con aristas rectas andables %s" % [T.GRAFO.size(), str(grafo_mal)])
	for n in T.GRAFO:
		_ok(String(n).begins_with("n_"), "1: el nodo %s se llama n_*" % n)


func _recto_andable(a: Vector3, b: Vector3) -> bool:
	var n := int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 0.1))
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxf(n, 1))
		if not T.andable(p.x, p.z):
			return false
	return true


# ================================================================= 2 y 3

var _celdas := {}             # Vector2i → true (lo andable en la rejilla)


func _rejilla() -> void:
	if not _celdas.is_empty():
		return
	for s in T.SUELOS:
		var r: Rect2 = s[1]
		for i in range(floori(r.position.x / PASO), ceili(r.end.x / PASO) + 1):
			for j in range(floori(r.position.y / PASO), ceili(r.end.y / PASO) + 1):
				var x := (i + 0.5) * PASO
				var z := (j + 0.5) * PASO
				if T.andable(x, z):
					_celdas[Vector2i(i, j)] = true


func _celda(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / PASO), floori(p.z / PASO))


func _conectado() -> void:
	_rejilla()
	var inicio := _celda(T.ancla("inicio"))
	_ok(_celdas.has(inicio), "2: el inicio está en lo andable")
	var visto := {inicio: true}
	var cola: Array = [inicio]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = c + d
			if _celdas.has(q) and not visto.has(q):
				visto[q] = true
				cola.append(q)
	_ok(visto.size() == _celdas.size(), "2: el BFS desde el inicio llega a toda la rejilla andable (%d de %d casillas de %.2f m)" % [
		visto.size(), _celdas.size(), PASO])
	var no: Array = []
	for id in T.ANCLAS:
		if not visto.has(_celda(T.ancla(id))):
			no.append(id)
	for id in T.PUERTAS:
		if not visto.has(_celda(T.PUERTAS[id]["fuera"])):
			no.append("puerta " + id)
	_ok(no.is_empty(), "2: se llega a todas las puertas, nodos y anclas %s" % str(no))


func _alturas() -> void:
	_rejilla()
	var salto := 0.0
	var donde := ""
	var ymin := INF
	var ymax := -INF
	for c in _celdas:
		var x: float = (c.x + 0.5) * PASO
		var z: float = (c.y + 0.5) * PASO
		var y := T.altura(x, z)
		ymin = minf(ymin, y)
		ymax = maxf(ymax, y)
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var q: Vector2i = c + d
			if _celdas.has(q):
				var dy := absf(T.altura((q.x + 0.5) * PASO, (q.y + 0.5) * PASO) - y)
				if dy > salto:
					salto = dy
					donde = "(%.2f, %.2f)" % [x, z]
	_ok(salto <= 0.3, "3: la altura es continua: el mayor salto entre casillas vecinas es %.3f m en %s" % [salto, donde])
	_ok(ymin <= 0.01 and ymax >= 1.39, "3: hay desniveles de verdad (de %.2f a %.2f m)" % [ymin, ymax])
	for e in [["n_plaza", 0.4], ["n_res_c", 1.4], ["n_carav", 0.0], ["n_patio_s", 0.55]]:
		_ok(absf(T.ancla(e[0]).y - e[1]) < 0.01, "3: cota de %s = %.2f" % [e[0], T.ancla(e[0]).y])


# ================================================================= 4 y 5

func _camara() -> void:
	_rejilla()
	var sin_peso := 0
	for c in _celdas:
		if T.peso_total((c.x + 0.5) * PASO, (c.y + 0.5) * PASO) <= 0.0:
			sin_peso += 1
	_ok(sin_peso == 0, "4: toda casilla andable tiene alguna zona de cámara con peso (%d sin peso)" % sin_peso)
	var peor := 0.0
	var donde := ""
	for n in T.GRAFO:
		for m in T.GRAFO[n]:
			var a := T.ancla(n)
			var b := T.ancla(m)
			var k := int(ceil(a.distance_to(b) / 0.1))
			var f0 := T.foco_camara(a)
			for i in range(1, k + 1):
				var f1 := T.foco_camara(a.lerp(b, float(i) / k))
				if f1.distance_to(f0) > peor:
					peor = f1.distance_to(f0)
					donde = "%s→%s" % [n, m]
				f0 = f1
	_ok(peor < 0.5, "4: el foco de la cámara no salta al recorrer el grafo (el mayor paso: %.3f m por 0,1 m de Kael, en %s)" % [peor, donde])
	var M = load("res://zonas3d/muestra_calle/muestra_calle.gd")
	_ok(M.OFFSET_CAMARA == T.OFFSET_CAMARA and is_equal_approx(M.INCLINACION, T.INCLINACION) and is_equal_approx(M.CAMPO, T.CAMPO),
		"4: misma altura, distancia, inclinación y campo que la muestra de la calle")
	var c1 := Camera3D.new()
	var c2 := Camera3D.new()
	root.add_child(c1)
	root.add_child(c2)
	var k := T.ancla("n_com_o")
	T.poner_camara(c1, k)
	M.camara_muestra(c2, k)
	_ok(c1.global_transform.is_equal_approx(c2.global_transform) and is_equal_approx(c1.fov, c2.fov),
		"4: la cámara del barrio y la de la muestra, puestas en el mismo foco, son la misma")
	_ok(absf(c1.global_rotation_degrees.y) < 0.001 and absf(c1.global_rotation_degrees.z) < 0.001, "4: la cámara no gira")
	c1.free()
	c2.free()


func _lado_sur() -> void:
	var mal: Array = []
	for s in T.SUELOS:
		if not s[0] in T.TRAMOS_EO:
			continue
		var r: Rect2 = s[1]
		for b in T.BLOQUES:
			var br: Rect2 = b[2]
			if not b[6] or br.position.y < r.end.y - 0.01 or br.position.y >= r.end.y + 4.0:
				continue
			if br.end.x <= r.position.x or br.position.x >= r.end.x:
				continue
			var x := clampf(br.get_center().x, r.position.x, r.end.x - 0.01)
			var sobre: float = float(b[3]) + float(b[4]) - T.altura(x, r.end.y - 0.01)
			if sobre > 1.6:
				mal.append("%s (%.2f m sobre la calle %s)" % [b[0], sobre, s[0]])
	_ok(mal.is_empty(), "5: lado sur ≤ 1,6 m a menos de 4 m del paso en los tramos de este a oeste %s" % str(mal))


# ================================================================= 6

func _region() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()                                 # la partida del banco (prólogo visto y pv_02)
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	_ok(BP.EXPLORAR.has("barrio") and BP.EXPLORAR["barrio"]["escena"] == ESCENA, "6: el banco tiene el caso «barrio»")
	_ok(BP.EXPLORAR["barrio"]["activos"] == ["Kael", "Lya", "Garon"], "6: con Kael, Lya y Garon")
	for m in ["barrio_v12", "barrio_interior", "barrio_reloj"]:
		_ok(m in BP.METAS_SESION, "6: «%s» es meta de sesión del banco" % m)
	Engine.set_meta("calidad_proto", "bajo")
	change_scene_to_file(ESCENA)
	v = null
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			break
	await _frames(10)
	_ok(v != null, "6: la región carga en el banco")
	if v == null:
		return
	var Barrio = load("res://ciudades/oakhaven_barrio.gd")
	_ok(Engine.get_meta("barrio_v12", false) and Barrio.activado(), "6: dentro del banco se activa (barrio_v12)")
	_ok(Barrio.NOMBRE == "oak_barrio", "6: la mazmorra se llama oak_barrio")
	var n_sectores := 0
	for s in T.ORDEN:
		if v.sectores.has(s) and (v.sectores[s] as Node3D).get_node_or_null("Blockout") != null:
			n_sectores += 1
	_ok(n_sectores == 6, "6: blockout de los 6 sectores (%d)" % n_sectores)
	var solidos: int = T.BLOQUES.filter(func(b): return b[6]).size()
	_ok(v.choques == solidos + T.SUELOS.size() + 1, "6: un cuerpo por caja: %d choques (%d sólidos + %d suelos + el fondo)" % [
		v.choques, solidos, T.SUELOS.size()])
	_ok(v.interior == "" and v.has_signal("interior_cambiado"), "6: fuera (interior \"\") y con la señal interior_cambiado")
	for f in ["avisar", "guardar", "ocupado", "sonda", "iniciar_dialogo", "ancla", "guardar_posicion"]:
		_ok(v.has_method(f), "6: la región tiene %s()" % f)
	_ok(v.sonda(T.ancla("n_plaza")) == Vector2(1.0, 0.7), "6: sonda provisional (sol 1, cielo 0,7)")
	var I = load("res://zonas3d/barrio/interiores.gd")
	_ok(v.ancla("n_plaza") == T.ancla("n_plaza") and (v.ancla("int_horno_boca") != Vector3.ZERO) == I.ORIGEN.has("horno"),
		"6: ancla() exterior y de interior (con el interior construido, su ancla real)")
	_ok(v.kael.global_position.distance_to(T.ancla("inicio")) < 0.3, "6: Kael empieza en el inicio (%s)" % str(v.kael.global_position))
	_ok(not v.ocupado(), "6: no está ocupado")
	_ok(not v.iniciar_dialogo("res://no_existe.dtl"), "6: iniciar_dialogo con una ruta que no existe devuelve false")
	# las puertas: en obras; sin el prólogo, la guardia
	for id in T.PUERTAS:
		v._colocar_kael(T.PUERTAS[id]["fuera"])
		await _frames(2)
		v._bloqueo = 0.0
		v._comprobar_cerca()
		_ok(v.cerca == "entrar_" + id and v.boton_accion.visible and v.boton_accion.text == T.PUERTAS[id]["texto"],
			"6: junto a la puerta de %s, el botón «%s» (%s)" % [id, T.PUERTAS[id]["texto"], v.cerca])
		# (integración 16/11) con su interior construido (B) se entra y se sale de verdad; la vivienda pide llamar la
		# primera vez (C); sin interior, «en obras»
		Engine.set_meta("prologo_visto", false)
		v._bloqueo = 0.0
		v._accion()
		_ok(v.ultimo_aviso == Barrio.TEXTO_PROLOGO and v.interior == "", "6: %s sin el prólogo: guardia («%s»)" % [id, v.ultimo_aviso])
		Engine.set_meta("prologo_visto", true)
		v._bloqueo = 0.0
		v._accion()
		if I.ORIGEN.has(id):
			for i in 3:                                 # (la vivienda: «Llamar a la puerta» y luego se entra)
				await _fundido()
				if v.interior == id:
					break
				v._bloqueo = 0.0
				v._colocar_kael(T.PUERTAS[id]["fuera"])
				await _frames(2)
				v._comprobar_cerca()
				v._accion()
			_ok(v.interior == id, "6: %s: se entra (interior «%s», aviso «%s»)" % [id, v.interior, v.ultimo_aviso])
			if v.interior == id:
				v._colocar_kael(v.interiores.salida(id))
				await _frames(2)
				v._bloqueo = 0.0
				v._comprobar_cerca()
				v._accion()
				await _fundido()
			_ok(v.interior == "" and v.kael.global_position.distance_to(T.PUERTAS[id]["fuera"]) < 2.0,
				"6: %s: se sale junto a la puerta (%s)" % [id, str(v.kael.global_position)])
		else:
			_ok(v.ultimo_aviso == v.TEXTO_OBRAS and v.interior == "", "6: %s: «%s»" % [id, v.ultimo_aviso])
		continue
		Engine.set_meta("prologo_visto", false)
		v._bloqueo = 0.0
		v._accion()
		_ok(v.ultimo_aviso == Barrio.TEXTO_PROLOGO, "6: %s sin el prólogo: «%s»" % [id, v.ultimo_aviso])
		Engine.set_meta("prologo_visto", true)
	v.guardar()
	_ok(int(Engine.get_meta("pos_3d_lugar", -1)) == 102 and Engine.get_meta("pos_3d_ok", false), "6: guardar pone el lugar 102")
	_ok(FileAccess.file_exists(BP.ARCHIVO), "6: guardar escribe el archivo del banco")
	_ok(absf(v.cam.global_rotation_degrees.y) < 0.001, "6: la cámara de la región no gira")


func _fundido() -> void:
	for i in 240:
		await process_frame
		if not v.cambiando:
			break
	await _frames(3)


# ================================================================= 7

func _bucle() -> void:
	v._colocar_kael(T.ancla("inicio"))
	await _frames(5)
	var sectores_vistos := {}
	var peor_y := 0.0
	var giro := 0.0
	for i in range(1, T.BUCLE.size()):
		var meta := T.ancla(T.BUCLE[i])
		v.destino = meta
		for f in 900:
			await process_frame
			var k: Vector3 = v.kael.global_position
			sectores_vistos[T.sector_de(k.x, k.z)] = true
			peor_y = maxf(peor_y, absf(k.y - T.altura(k.x, k.z)))
			giro = maxf(giro, absf(v.cam.global_rotation_degrees.y))
			if v.destino == null:
				break
		var k2: Vector3 = v.kael.global_position
		var falta := Vector2(k2.x - meta.x, k2.z - meta.z).length()
		_ok(falta < 0.6, "7: Kael llega a %s (a %.2f m)" % [T.BUCLE[i], falta])
		if falta >= 0.6:
			v._colocar_kael(meta)                         # (para seguir comprobando el resto del bucle)
	_ok(sectores_vistos.size() >= 6, "7: el bucle pasa por los 6 sectores (%s)" % str(sectores_vistos.keys()))
	_ok(peor_y < 0.12, "7: Kael va sobre el suelo del trazado (diferencia máxima %.3f m)" % peor_y)
	_ok(giro < 0.001, "7: la cámara no gira en todo el bucle")


func _no_entra() -> void:
	v._colocar_kael(T.ancla("n_horno"))
	v.destino = Vector3(-24.0, 0.2, -6.0)                  # dentro del horno
	for i in 200:
		await process_frame
		if v.destino == null:
			break
	_ok(v.kael.global_position.z > -1.05, "7: no entra en el horno por la fachada (z = %.2f)" % v.kael.global_position.z)
	v._colocar_kael(T.ancla("n_res_c"))
	v.destino = Vector3(-25.0, 1.4, -21.0)                 # a los huertos, al sur de la calle
	for i in 200:
		await process_frame
		if v.destino == null:
			break
	_ok(v.kael.global_position.z < -25.9, "7: no baja a los huertos (z = %.2f)" % v.kael.global_position.z)


# ================================================================= 8

func _fuera_del_banco() -> void:
	var BP = load("res://banco_pruebas.gd")
	if current_scene != null:
		current_scene.queue_free()
		await _frames(3)
	BP.salir()
	for m in ["barrio_v12", "barrio_interior", "barrio_reloj", "banco_pruebas"]:
		_ok(not Engine.has_meta(m), "8: al salir del banco no queda «%s»" % m)
	var Barrio = load("res://ciudades/oakhaven_barrio.gd")
	Engine.set_meta("barrio_v12", true)                   # (aunque alguien la deje puesta: fuera del banco no cuenta)
	_ok(not Barrio.activado(), "8: fuera del banco el barrio no está activado")
	Engine.remove_meta("barrio_v12")
	var r = load(ESCENA).instantiate()
	root.add_child(r)
	_ok(r.fuera_del_banco and r.kael == null and r.get_node_or_null("Exterior") == null,
		"8: fuera del banco la región no se construye (vuelve a la carga)")
	_ok(not Engine.has_meta("barrio_v12"), "8: y no se activa")
	r.free()                                              # (antes de que su llamada diferida cambie de escena)
