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
#   9. (fase A, 16/11) Los tramos horneados: su GLB sin blockout, un choque por cada caja sólida del trazado, el mapa de
#      luz de 1024 en el bajo, solo los 4 sombreados de la muestra (sin programas nuevos), sondas con sol y con sombra,
#      la luz de Kael siguiendo a la sonda y el sector de Kael siempre dibujado (visibilidad por sector).
#  10. (pulido de la región, 16/11) rótulos «(en obras)» solo sin interior; el botón según el estado (Barrio.boton); el
#      aviso se oculta al empezar un diálogo; dentro, Kael no pisa a los vecinos; la luz de Kael, una sola autoridad y sin
#      saltos visibles al entrar y salir; tocar el suelo rodea a un vecino en la recta (sin atravesarlo) y se queda delante
#      si se toca encima; NINGUNA casilla andable da NAN en _altura_suelo (las costuras de los suelos).
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
		await _pulido()
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
		var nodo: Node3D = v.sectores.get(s)
		if nodo != null and (nodo.get_node_or_null("Blockout") != null or nodo.get_node_or_null("Modelo") != null):
			n_sectores += 1
	_ok(n_sectores == 6, "6: los 6 sectores, horneados (%s) o en blockout (%d)" % [str(v.acabados), n_sectores])
	var solidos: int = T.BLOQUES.filter(func(b): return b[6]).size()
	_ok(v.choques == solidos + T.SUELOS.size() + 1, "6: un cuerpo por caja: %d choques (%d sólidos + %d suelos + el fondo; más %d de piezas sueltas)" % [
		v.choques, solidos, T.SUELOS.size(), v.choques_piezas])
	_ok(v.interior == "" and v.has_signal("interior_cambiado"), "6: fuera (interior \"\") y con la señal interior_cambiado")
	for f in ["avisar", "guardar", "ocupado", "sonda", "iniciar_dialogo", "ancla", "guardar_posicion"]:
		_ok(v.has_method(f), "6: la región tiene %s()" % f)
	if "plaza" in v.acabados:
		var sp: Vector2 = v.sonda(T.ancla("n_plaza"))
		_ok(sp.x > 0.5 and sp.y > 0.2 and sp.x <= 1.0 and sp.y <= 1.0, "6: sonda horneada en la plaza (sol %.2f, cielo %.2f)" % [sp.x, sp.y])
	else:
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
	await _horneado()


# ================================================================= 9 (fase A): los tramos horneados

func _horneado() -> void:
	if v.acabados.is_empty():
		print("(9: ningún tramo horneado: no se comprueba)")
		return
	var muestra := ["res://zonas3d/muestra_calle/calle_estatico.gdshader", "res://zonas3d/muestra_calle/calle_vertice.gdshader",
		"res://zonas3d/muestra_calle/calle_hoja.gdshader", "res://zonas3d/muestra_calle/calle_brillo.gdshader"]
	var ajenos := {}
	var sin_material := 0
	for s in v.acabados:
		var nodo: Node3D = v.sectores[s]
		var modelo: Node3D = nodo.get_node_or_null("Modelo")
		_ok(modelo != null and nodo.get_node_or_null("Blockout") == null, "9: %s está horneado (su GLB, sin blockout)" % s)
		if modelo == null:
			continue
		for mi in modelo.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m = (mi as MeshInstance3D).get_surface_override_material(i)
				if not m is ShaderMaterial:
					sin_material += 1
				elif not (m as ShaderMaterial).shader.resource_path in muestra:
					ajenos[(m as ShaderMaterial).shader.resource_path] = true
		var faltan: Array = []
		for b in T.BLOQUES:
			if b[1] == s and b[6] and nodo.get_node_or_null("Choque_" + String(b[0])) == null:
				faltan.append(b[0])
		_ok(faltan.is_empty(), "9: %s: un choque por cada caja sólida del trazado (faltan %s)" % [s, str(faltan)])
		var lm: String = v.tex_luz_usadas.get(s, "")
		_ok(lm.ends_with("_1024.png"), "9: %s con el mapa de luz de 1024 en el perfil bajo (%s)" % [s, lm])
		# la sonda: algo de sombra y algo de sol en lo que se pisa del sector
		var hay_sol := false
		var hay_sombra := false
		for suelo in T.SUELOS:
			if suelo[0] != s:
				continue
			var r: Rect2 = suelo[1]
			for i in 12:
				for j in 8:
					var x := r.position.x + r.size.x * (i + 0.5) / 12.0
					var z := r.position.y + r.size.y * (j + 0.5) / 8.0
					if T.andable(x, z):
						var so: Vector2 = v.sonda(Vector3(x, T.altura(x, z), z))
						hay_sol = hay_sol or so.x > 0.8
						hay_sombra = hay_sombra or so.x < 0.3
		_ok(hay_sol, "9: %s: la sonda ve sol en lo que se pisa" % s)
		if s != "plaza":
			_ok(hay_sombra, "9: %s: la sonda ve sombra en lo que se pisa" % s)
	_ok(sin_material == 0 and ajenos.is_empty(), "9: solo los 4 sombreados de la muestra, sin programas nuevos (sin material %d, otros %s)" % [
		sin_material, str(ajenos.keys())])
	# la luz de Kael sigue a la sonda: menos sol en la sombra que al sol
	var s0: String = v.acabados[0]
	var sol_mas := -1.0
	var sol_menos := 99.0
	for suelo in T.SUELOS:
		if suelo[0] != s0:
			continue
		var r: Rect2 = suelo[1]
		for i in 10:
			for j in 6:
				var p := Vector3(r.position.x + r.size.x * (i + 0.5) / 10.0, 0.0, r.position.y + r.size.y * (j + 0.5) / 6.0)
				if not T.andable(p.x, p.z):
					continue
				v._colocar_kael(p)
				sol_mas = maxf(sol_mas, v.sol.light_energy)
				sol_menos = minf(sol_menos, v.sol.light_energy)
	_ok(sol_mas > sol_menos + 0.3, "9: la luz de Kael sigue a la sonda en %s (sol de %.2f a %.2f)" % [s0, sol_menos, sol_mas])
	# visibilidad por sector: el sector de Kael se dibuja siempre
	for s in v.acabados:
		var a: Vector3 = T.ancla({"caravanas": "n_carav", "comercial": "n_horno", "plaza": "n_plaza", "talleres": "n_patio_n",
			"residencial": "n_res_c", "atajo": "n_atajo_n"}[s])
		v._colocar_kael(a)
		_ok(v.visibles.get(s, false) and (v.sectores[s] as Node3D).visible, "9: con Kael en %s, %s se dibuja (%s)" % [
			s, s, str(v.visibles.keys().filter(func(q): return v.visibles[q]))])
	v._colocar_kael(T.ancla("inicio"))
	await _frames(2)


func _fundido() -> void:
	for i in 240:
		await process_frame
		if not v.cambiando:
			break
	await _frames(3)


# ================================================================= 10 (pulido de la región)

func _pulido() -> void:
	var I = load("res://zonas3d/barrio/interiores.gd")
	var Barrio = load("res://ciudades/oakhaven_barrio.gd")
	var P = load("res://progreso.gd")
	# rótulos
	for id in T.PUERTAS:
		var hay: bool = v.find_child("Rotulo_" + id, true, false) != null
		_ok(hay == not I.ORIGEN.has(id), "10: rótulo «(en obras)» de %s solo si no tiene interior (rótulo %s, interior %s)" % [
			id, hay, I.ORIGEN.has(id)])
	# el botón según el estado
	v._colocar_kael(T.ancla("carro_horno"))
	await _frames(2)
	v._bloqueo = 0.0
	v._comprobar_cerca()
	var t0: String = v.boton_accion.text
	P.poner_estado(Barrio.NOMBRE, "enf_galga", true)
	v._comprobar_cerca()
	var t1: String = v.boton_accion.text
	P.poner_estado(Barrio.NOMBRE, "enf_galga", false)
	_ok(v.cerca == "carro_horno" and t0 == "Examinar el carro" and t1 == "Medir el eje con la galga",
		"10: el botón del carro sigue a Barrio.boton (antes «%s», con la galga «%s»)" % [t0, t1])
	# el aviso se oculta al empezar un diálogo
	v.avisar("Prueba del aviso")
	await create_timer(0.4).timeout
	var a0: float = v.aviso.modulate.a
	var D = root.get_node_or_null("Dialogic")
	var empezo: bool = v.iniciar_dialogo(Barrio.ruta_dialogo("bar_brena_caminos"))
	await _frames(2)
	_ok(a0 > 0.5 and empezo and v.aviso.modulate.a < 0.01, "10: el aviso (%.2f) se oculta al empezar un diálogo (%.2f; empezó %s)" % [
		a0, v.aviso.modulate.a, empezo])
	if D != null and D.current_timeline != null:
		D.end_timeline(true)
	await _frames(10)
	v._bloqueo = 0.0
	await _luz_y_dentro()
	await _rodeo()
	_sin_nan()


# Entrar y salir del horno mirando cada fotograma (con el fundido) el sol de Kael: con la pantalla visible (fundido < 0,98)
# el color del sol es SIEMPRE el de donde está Kael (sin un fotograma con la luz del otro lado).
func _luz_y_dentro() -> void:
	var I = load("res://zonas3d/barrio/interiores.gd")
	if not I.ORIGEN.has("horno"):
		print("(10: sin el interior del horno: no se comprueba la luz de dentro)")
		return
	var fuera_color: Color = v._luz_fija["sol_color"]
	var dentro_color: Color = I.LUZ_KAEL["horno"]["sol_color"]
	var saltos: Array = []
	v._colocar_kael(T.PUERTAS["horno"]["fuera"])
	await _frames(2)
	v._bloqueo = 0.0
	v._comprobar_cerca()
	v._accion()
	for i in 240:
		await process_frame
		_mirar_luz(fuera_color, dentro_color, saltos)
		if not v.cambiando and v.interior == "horno":
			break
	_ok(v.interior == "horno", "10: se entra en el horno")
	if v.interior != "horno":
		return
	_ok(v.ambiente.background_color.is_equal_approx(I.FONDO_DENTRO) and not v.ambiente.fog_enabled,
		"10: dentro, fondo oscuro y sin bruma (los pone la región)")
	var s0: Vector2 = v.interiores.sonda(v.kael.global_position)
	var esperado: float = float(I.LUZ_KAEL["horno"]["sol"]) * (1.0 + v.SOL_MANCHA * clampf(s0.x, 0.0, 1.0))
	_ok(absf(v.sol.light_energy - esperado) < 0.05, "10: dentro, el sol de Kael sale de interiores.sonda (%.2f, esperado %.2f)" % [
		v.sol.light_energy, esperado])
	# dentro, Kael no pisa a los vecinos: un vecino de prueba en lo andable delante de Kael
	var k: Vector3 = v.kael.global_position
	var q := k + Vector3(0.0, 0.0, -1.0)
	if v.interiores.andable(q):
		v.obstaculos_extra = [[Vector2(q.x, q.z), Vector2(q.x, q.z), 0.42]]
		_ok(v._prohibido(q) and not v._prohibido_suelo(q), "10: dentro, _prohibido respeta a los vecinos (además del interior)")
		v.obstaculos_extra = []
	if v.vivo != null:
		for id in v.vivo.vecinos:
			var w: Dictionary = v.vivo.vecinos[id]
			if w["visible"] and w["lugar"] == "horno":
				var p: Vector3 = w["pos"]
				_ok(v._prohibido(p), "10: dentro del horno, Kael no pisa a %s (%s)" % [id, str(p)])
	v._colocar_kael(v.interiores.salida("horno"))
	await _frames(2)
	v._bloqueo = 0.0
	v._comprobar_cerca()
	v._accion()
	for i in 240:
		await process_frame
		_mirar_luz(fuera_color, dentro_color, saltos)
		if not v.cambiando and v.interior == "":
			break
	await _frames(3)
	_mirar_luz(fuera_color, dentro_color, saltos)
	_ok(v.interior == "" and v.sol.light_color.is_equal_approx(fuera_color) and not v.ambiente.background_color.is_equal_approx(I.FONDO_DENTRO),
		"10: al salir, el sol y el fondo de fuera")
	_ok(saltos.is_empty(), "10: con la pantalla visible, la luz de Kael siempre es la de su lado (saltos: %s)" % str(saltos))


func _mirar_luz(fuera_color: Color, dentro_color: Color, saltos: Array) -> void:
	if v.fundido.color.a >= 0.98:
		return
	var esperado: Color = dentro_color if v.interior != "" else fuera_color
	if not v.sol.light_color.is_equal_approx(esperado):
		saltos.append("interior «%s», fundido %.2f, sol %s" % [v.interior, v.fundido.color.a, str(v.sol.light_color)])


# Tocar el suelo con un vecino en medio de la recta (en la plaza, llana y abierta): Kael lo rodea y llega, sin entrar en su
# círculo; tocar encima de él deja a Kael delante.
func _rodeo() -> void:
	var a := Vector3(-6.0, 0.4, -1.0)
	var b := Vector3(0.0, 0.4, -1.0)
	var c := Vector2(-3.0, -1.0)
	var radio := 0.42
	v._colocar_kael(a)
	await _frames(2)
	v.obstaculos_extra = [[c, c, radio]]
	v.destino = v._ajustar_destino(b)
	var cerca_min := INF
	var rodeo := false
	for i in 400:
		await process_frame
		var k: Vector3 = v.kael.global_position
		cerca_min = minf(cerca_min, Vector2(k.x, k.z).distance_to(c))
		rodeo = rodeo or v._rodeando
		if v.destino == null and v._meta_final == null:
			break
	var k2: Vector3 = v.kael.global_position
	var falta := Vector2(k2.x - b.x, k2.z - b.z).length()
	_ok(falta < 0.3 and cerca_min >= radio and rodeo, "10: con un vecino en la recta, Kael lo rodea y llega (a %.2f m; lo más cerca, %.2f m del centro; rodeó %s)" % [
		falta, cerca_min, rodeo])
	v._colocar_kael(a)
	await _frames(2)
	v.destino = v._ajustar_destino(Vector3(c.x, 0.4, c.y))
	for i in 300:
		await process_frame
		if v.destino == null and v._meta_final == null:
			break
	k2 = v.kael.global_position
	var d := Vector2(k2.x, k2.z).distance_to(c)
	_ok(d >= radio and d < radio + 0.5, "10: tocar encima del vecino deja a Kael delante (a %.2f m del centro)" % d)
	v.obstaculos_extra = []
	v._colocar_kael(T.ancla("inicio"))
	await _frames(2)


# Ninguna casilla andable da NAN en _altura_suelo (con Kael encima, sin vecinos): en las esquinas de la rejilla de 0,25 m
# (ahí caen las costuras de los suelos, todas en metros enteros) y en sus centros.
func _sin_nan() -> void:
	var vivo = v.vivo
	v.vivo = null
	var ext: Array = v.obstaculos_extra
	v.obstaculos_extra = []
	var guardado: Vector3 = v.kael.global_position
	var malos: Array = []
	var n := 0
	for s in T.SUELOS:
		var r: Rect2 = s[1]
		for i in range(floori(r.position.x / PASO), ceili(r.end.x / PASO) + 1):
			for j in range(floori(r.position.y / PASO), ceili(r.end.y / PASO) + 1):
				for o in [0.0, 0.5]:
					var x: float = (i + o) * PASO
					var z: float = (j + o) * PASO
					if T.suelo_en(x, z) < 0 or not T.andable(x, z) or _en_cara_de_bloque(x, z):
						continue
					var y := T.altura(x, z)
					var p := Vector3(x, y, z)
					v.kael.global_position = p
					n += 1
					var h: float = v._altura_suelo(p, y)
					if is_nan(h) or absf(h - y) > 0.03:
						malos.append("(%.2f, %.2f) → %s" % [x, z, str(h)])
	v.kael.global_position = guardado
	v.vivo = vivo
	v.obstaculos_extra = ext
	_ok(malos.is_empty(), "10: ninguna casilla andable da NAN ni otra altura en _altura_suelo (%d puntos; %d mal: %s)" % [
		n, malos.size(), str(malos.slice(0, 12))])


# Un punto en la misma cara de un bloque sólido (Rect2 es semiabierto: el borde final del bloque «es andable», pero ahí el
# rayo toca la arista del bloque). No es una casilla: se deja fuera.
func _en_cara_de_bloque(x: float, z: float) -> bool:
	for b in T.BLOQUES:
		if b[6] and (b[2] as Rect2).grow(0.01).has_point(Vector2(x, z)):
			return true
	return false


# ================================================================= 7

func _bucle() -> void:
	v._colocar_kael(T.ancla("inicio"))
	await _frames(5)
	var sectores_vistos := {}
	var peor_y := 0.0
	var giro := 0.0
	for i in range(1, T.BUCLE.size()):
		var meta := T.ancla(T.BUCLE[i])
		v.destino = v._ajustar_destino(meta)              # (como un toque: rodea a quien se cruce)
		var traza: Array = []                             # (los últimos fotogramas, para el diagnóstico si no llega)
		for f in 900:
			await process_frame
			var k: Vector3 = v.kael.global_position
			traza.append("k=(%.2f,%.2f) destino %s rodeando %s meta %s" % [k.x, k.z, str(v.destino), v._rodeando, str(v._meta_final)])
			if traza.size() > 40:
				traza.pop_front()
			sectores_vistos[T.sector_de(k.x, k.z)] = true
			peor_y = maxf(peor_y, absf(k.y - T.altura(k.x, k.z)))
			giro = maxf(giro, absf(v.cam.global_rotation_degrees.y))
			if v.destino == null and v._meta_final == null:
				break
		var k2: Vector3 = v.kael.global_position
		var falta := Vector2(k2.x - meta.x, k2.z - meta.z).length()
		var por_que := ""
		if falta >= 0.6:                                  # (para el diagnóstico: el paso siguiente y quién estorba)
			var sig: Vector3 = k2 + Vector3(meta.x - k2.x, 0.0, meta.z - k2.z).normalized() * 0.15
			por_que = " en %s; paso siguiente: prohibido %s, suelo %s, altura %s; rodeo: %s %.2f s, sin avance %.2f s, meta %s" % [
				str(k2), v._prohibido(sig), v._prohibido_suelo(sig), str(v._altura_suelo(sig, k2.y)), v._rodeando, v._t_rodeo,
				v._t_sin_avance, str(v._meta_final)]
			if v.vivo != null:
				for id in v.vivo.vecinos:
					var q: Vector3 = v.vivo.vecinos[id]["pos"]
					if Vector2(q.x - sig.x, q.z - sig.z).length() < 1.0:
						por_que += "; %s en %s" % [id, str(q)]
		_ok(falta < 0.6, "7: Kael llega a %s (a %.2f m)%s" % [T.BUCLE[i], falta, por_que])
		if falta >= 0.6:
			print("   (últimos fotogramas)
   " + "
   ".join(PackedStringArray(traza)))
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
		if v.destino == null and v._meta_final == null:
			break
	_ok(v.kael.global_position.z > -1.05, "7: no entra en el horno por la fachada (z = %.2f)" % v.kael.global_position.z)
	v._colocar_kael(T.ancla("n_res_c"))
	v.destino = Vector3(-25.0, 1.4, -21.0)                 # a los huertos, al sur de la calle
	for i in 200:
		await process_frame
		if v.destino == null and v._meta_final == null:
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
