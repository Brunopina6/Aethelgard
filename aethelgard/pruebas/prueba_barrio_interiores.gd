extends SceneTree
# V12 (16/11): BARRIO EXPERIMENTAL de Oakhaven, LOS INTERIORES (agente B; zonas3d/barrio/interiores.gd, plan §3 y §10 B,
# docs/v12/BARRIO_OAKHAVEN.md sección B). Sin ventana.
#   1. Los datos de cada interior (interiores/<id>.json, int_<id>.glb, su mapa de luz de 1024): las anclas del contrato,
#      todas en lo andable y a la altura del suelo; los objetos con su clase (examinable / ofrecido / privado) a ≥ 2,5 m;
#      lo andable conectado desde la entrada (BFS de 0,1 m) y sin saltos de altura; los pasos internos; el presupuesto
#      (≤ 14 superficies, ≤ 35 000 triángulos); interior_de() en cada ORIGEN y fuera; tres plantas DISTINTAS.
#   2. utensilios.glb: los 9 utensilios, cada uno ≤ 300 triángulos y con un solo material.
#   3. En el banco: entrar y salir de los tres por su puerta (fundido, exterior oculto, solo ese interior visible y los
#      demás desactivados, la cámara propia sin girar, Kael en la entrada y luego en la puerta de fuera), guardar_posicion
#      dentro guarda la PUERTA de fuera, lo examinado y lo hablado no cambia al entrar y salir, doble pulsación.
#   4. La trastienda: cerrada (no se pisa, el aviso al acercarse, la hoja cerrada) y abierta con estado:enf_taller (la
#      hoja gira y se llega al banco de cortar). La alcoba (dos escalones, +0,35) y la cortina del horno se andan.
#   5. CAL (recarga) dentro vuelve dentro; restaurar una posición en un ORIGEN deja a Kael en el inicio; «Guardar y
#      recargar» dentro sale a la puerta de fuera con lo examinado guardado; salir a mitad de un fundido no deja metas.
# Partida propia del banco (user://banco_pruebas.save, en la carpeta aislada de la pasada). Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
const I := preload("res://zonas3d/barrio/interiores.gd")
const P := preload("res://progreso.gd")
const CONTRATO := {
	"horno": ["entrada", "salida", "boca", "artesa", "estante", "mesa", "maela"],
	"taller": ["entrada", "salida", "clavo", "potro", "banco_corte", "paso_trastienda", "damian"],
	"vivienda": ["entrada", "salida", "repisa", "mesa", "rincon", "odila", "nela"],
}
const UTENSILIOS := ["bandeja", "cesta_pan", "caja", "saco_harina", "cepillo", "cubo", "galga", "pasador", "pasador_roto"]
const CLASES := ["examinable", "ofrecido", "privado"]
const PASO := 0.1
var fallos := 0
var v
var interiores                                         # una instancia suelta (para los datos, sin la región)


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
	interiores = I.new()
	_datos()
	_conectado()
	_utensilios()
	interiores.free()
	await _region()
	if v != null:
		await _entrar_y_salir()
		await _trastienda()
		await _alcoba_y_cortina()
		await _cal()
		await _restaurar_en_origen()
		await _guardar_y_recargar()
		await _fundido_cortado()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= 1. datos

func _datos() -> void:
	_ok(I.ORIGEN.size() == 3, "1: los tres interiores tienen ORIGEN (ya no están «en obras»)")
	var firmas := {}
	for id in I.IDS:
		var d := I.datos(id)
		_ok(not d.is_empty(), "1: %s: interiores/%s.json" % [id, id])
		_ok(ResourceLoader.exists(I.ruta_modelo(id)), "1: %s: %s" % [id, I.ruta_modelo(id)])
		_ok(ResourceLoader.exists("res://zonas3d/barrio/modelos/int_%s_luz_1024.png" % id) and d.get("horneado", false),
			"1: %s: luz horneada de 1024" % id)
		_ok(Vector2(d.get("tam", [0, 0])[0], d.get("tam", [0, 0])[1]) == I.TAM[id], "1: %s: tamaño %s" % [id, str(I.TAM[id])])
		# anclas del contrato
		for n in CONTRATO[id]:
			var nombre := "int_%s_%s" % [id, n]
			_ok(d.get("anclas", {}).has(nombre), "1: %s: ancla %s" % [id, nombre])
		interiores.abrir_paso("trastienda", true)
		for nombre in d.get("anclas", {}):
			var p: Vector3 = interiores.ancla(nombre)
			_ok(I.interior_de(p) == id, "1: %s está en el interior %s" % [nombre, id])
			_ok(interiores.andable(p), "1: %s se pisa (%s)" % [nombre, str(p - I.ORIGEN[id])])
			_ok(absf(p.y - interiores.altura(p)) < 0.01, "1: %s está a la altura del suelo (%.3f / %.3f)" % [nombre, p.y,
				interiores.altura(p)])
		interiores.abrir_paso("trastienda", false)
		# objetos con clase, a ≥ 2,5 m entre sí, y al menos uno de cada clase en el barrio
		var objs: Array = interiores.objetos(id)
		_ok(objs.size() >= 4, "1: %s: %d objetos que mirar" % [id, objs.size()])
		for o in objs:
			_ok(str(o["clase"]) in CLASES and d["anclas"].has(str(o["ancla"])), "1: %s: %s es %s" % [id, o["ancla"], o["clase"]])
			firmas[str(o["clase"])] = true
		var peor := INF
		for a in objs.size():
			for b in range(a + 1, objs.size()):
				var pa: Vector3 = objs[a]["pos"]
				var pb: Vector3 = objs[b]["pos"]
				peor = minf(peor, Vector2(pa.x - pb.x, pa.z - pb.z).length())
		_ok(peor >= 2.5, "1: %s: los objetos están a ≥ 2,5 m entre sí (el menor, %.2f m)" % [id, peor])
		# presupuesto (plan §9): superficies (= llamadas de lo fijo del interior) y triángulos
		var tris: Dictionary = d.get("tris", {})
		var total := int(tris.get("fijo", 0)) + int(tris.get("piezas", 0)) + int(tris.get("extra", 0))
		var sup := _superficies(id)
		_ok(total > 1500 and total <= 35000, "1: %s: %d triángulos a la vista (≤ 35 000)" % [id, total])
		_ok(sup > 3 and sup + d.get("sitios", {}).size() <= 14, "1: %s: %d superficies + %d utensilios de sitio (≤ 14 llamadas)" % [
			id, sup, d.get("sitios", {}).size()])
		# dentro / fuera
		_ok(I.interior_de(I.ORIGEN[id] + Vector3(I.TAM[id].x * 0.5, 0.0, I.TAM[id].y * 0.5)) == id, "1: interior_de(centro de %s)" % id)
		firmas[id] = "%d bloqueos, %d anclas, %s" % [d.get("bloqueos", []).size(), d.get("anclas", {}).size(), str(I.TAM[id])]
	_ok(I.interior_de(T.ancla("inicio")) == "" and I.interior_de(T.PUERTAS["horno"]["fuera"]) == "",
		"1: interior_de() de un sitio de fuera es «»")
	for c in CLASES:
		_ok(firmas.has(c), "1: hay objetos «%s» en el barrio" % c)
	_ok(firmas["horno"] != firmas["taller"] and firmas["taller"] != firmas["vivienda"] and firmas["horno"] != firmas["vivienda"],
		"1: tres plantas distintas (%s · %s · %s)" % [firmas["horno"], firmas["taller"], firmas["vivienda"]])
	_ok(I.datos("taller")["pasos"].has("trastienda") and not bool(I.datos("taller")["pasos"]["trastienda"]["siempre"]),
		"1: la trastienda es un paso con condición")
	_ok(I.datos("horno")["pasos"].has("cortina_horno") and I.datos("vivienda")["pasos"].has("alcoba"),
		"1: los pasos internos cortina_horno y alcoba")


func _superficies(id: String) -> int:
	var esc = load(I.ruta_modelo(id))
	if not esc is PackedScene:
		return 0
	var n := 0
	var inst: Node = esc.instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		n += (mi as MeshInstance3D).mesh.get_surface_count()
	inst.free()
	return n


# BFS en rejilla de 0,1 m desde la entrada: llega a todas las anclas (con los pasos abiertos), sin saltos de > 0,2 m; con
# la trastienda cerrada no se llega al banco de cortar pero sí a la puerta.
func _conectado() -> void:
	for id in I.IDS:
		for abierta in [true, false]:
			if not abierta and id != "taller":
				continue
			interiores.abrir_paso("trastienda", abierta)
			var o: Vector3 = I.ORIGEN[id]
			var t: Vector2 = I.TAM[id]
			var nx := int(t.x / PASO) + 1
			var nz := int(t.y / PASO) + 1
			var inicio := _celda(id, interiores.entrada(id))
			var visto := {inicio: true}
			var cola: Array = [inicio]
			var salto := 0.0
			while not cola.is_empty():
				var c: Vector2i = cola.pop_back()
				var pc := o + Vector3(c.x * PASO, 0, c.y * PASO)
				for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = c + dd
					if n.x < 0 or n.y < 0 or n.x >= nx or n.y >= nz or visto.has(n):
						continue
					var pn := o + Vector3(n.x * PASO, 0, n.y * PASO)
					if not interiores.andable(pn):
						continue
					salto = maxf(salto, absf(interiores.altura(pn) - interiores.altura(pc)))
					visto[n] = true
					cola.append(n)
			var faltan: Array = []
			for nombre in I.datos(id)["anclas"]:
				var a: Vector3 = interiores.ancla(nombre)
				if not interiores.andable(a):
					continue
				if not visto.has(_celda(id, a)):
					faltan.append(nombre)
			if abierta:
				_ok(faltan.is_empty(), "1: %s: desde la entrada se llega a todas las anclas (%d casillas) %s" % [id, visto.size(),
					str(faltan)])
				_ok(salto <= 0.2, "1: %s: sin saltos de altura de más de 0,2 m (el mayor, %.3f m)" % [id, salto])
			else:
				var bc := _celda(id, interiores.ancla("int_taller_banco_corte"))
				_ok(not visto.has(bc) and visto.has(_celda(id, interiores.ancla("int_taller_paso_trastienda"))),
					"1: con la trastienda cerrada no se llega al banco de cortar (sí a su puerta)")
	interiores.abrir_paso("trastienda", false)
	interiores._forzado.clear()


static func _plano(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


func _celda(id: String, p: Vector3) -> Vector2i:
	var l: Vector3 = p - I.ORIGEN[id]
	return Vector2i(roundi(l.x / PASO), roundi(l.z / PASO))


# ================================================================= 2. utensilios

func _utensilios() -> void:
	var ruta := "res://zonas3d/barrio/modelos/utensilios.glb"
	_ok(ResourceLoader.exists(ruta), "2: " + ruta)
	var esc = load(ruta)
	if not esc is PackedScene:
		return
	var inst: Node = esc.instantiate()
	for n in UTENSILIOS:
		var mi := inst.find_child(n, true, false) as MeshInstance3D
		_ok(mi != null, "2: utensilio «%s»" % n)
		if mi == null:
			continue
		var tris := 0
		for s in mi.mesh.get_surface_count():
			var a := mi.mesh.surface_get_arrays(s)
			var idx = a[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null and idx.size() > 0 else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		_ok(tris > 0 and tris <= 300 and mi.mesh.get_surface_count() == 1, "2: %s: %d triángulos, %d material" % [n, tris,
			mi.mesh.get_surface_count()])
	inst.free()


# ================================================================= 3. en el banco: entrar y salir

# (19/11, PC-10) por RELOJ (antes, 400 fotogramas, y al agotarse se seguía con v nulo): al agotarse, FALLO, «FALLOS: n»
# y salida 1; esta corrutina se queda esperando un temporizador que no llega, para que quien llama no siga.
func _cargar() -> void:
	v = null
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null \
				and current_scene.get("interiores") != null:
			v = current_scene
			break
	if v == null:
		print("FALLO: el barrio no se monta en 60 s (escena %s)" % (current_scene.scene_file_path if current_scene != null else "(ninguna)"))
		fallos += 1
		print("FALLOS: %d" % fallos)
		quit(1)
		await create_timer(3600.0).timeout             # no llega: quit() cierra al acabar este fotograma
		return
	await _frames(8)


func _region() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", "bajo")
	change_scene_to_file(ESCENA)
	await _cargar()
	_ok(v != null, "3: la región carga en el banco")
	if v == null:
		return
	_ok(v.interiores.get_child_count() == 3, "3: los tres interiores están colgados (ocultos)")
	for id in I.IDS:
		var n: Node3D = v.interiores._nodos[id]
		_ok(not n.visible and n.process_mode == Node.PROCESS_MODE_DISABLED, "3: %s oculto y desactivado fuera" % id)
		_ok(not v.interiores._hechos.has(id), "3: %s aún sin construir (se hace al acercarse o entrar)" % id)


func _esperar_fundido() -> void:
	for i in 240:
		await process_frame
		if not v.cambiando:
			break
	await _frames(3)


func _pulsar(id_pieza: String) -> void:
	v._bloqueo = 0.0
	v._comprobar_cerca()
	_ok(v.cerca == id_pieza, "3: junto a «%s» el botón es «%s» (%s)" % [id_pieza, v.boton_accion.text, v.cerca])
	v._accion()


func _entrar(id: String) -> void:
	v._colocar_kael(T.PUERTAS[id]["fuera"])
	await _frames(3)
	_pulsar("entrar_" + id)
	await _esperar_fundido()
	if v.interior != id:                              # (integración con C: la vivienda, la primera vez, se llama)
		_pulsar("entrar_" + id)
		await _esperar_fundido()


func _salir(id: String) -> void:
	v._colocar_kael(v.interiores.salida(id))
	await _frames(3)
	_pulsar("salir_" + id)
	await _esperar_fundido()


func _entrar_y_salir() -> void:
	P.poner_estado("oak_barrio", "j_prueba_b", true)          # algo «examinado» y algo «hablado» antes de entrar
	P.ver_detalle("bar_prueba_b")
	for id in I.IDS:
		# preparar al acercarse (a < 8 m)
		v._colocar_kael(T.PUERTAS[id]["fuera"] + Vector3(0, 0, 0.5))
		await _frames(20)
		_ok(v.interiores._pedidos.has(id) or v.interiores._hechos.has(id), "3: %s: se prepara al acercarse a su puerta" % id)
		await _entrar(id)
		_ok(v.interior == id, "3: %s: dentro (interior «%s»)" % [id, v.interior])
		_ok(not v.exterior.visible, "3: %s: el exterior, oculto" % id)
		for k in I.IDS:
			var n: Node3D = v.interiores._nodos[k]
			if k == id:
				_ok(n.visible and n.process_mode == Node.PROCESS_MODE_INHERIT, "3: %s: visible y activo" % k)
			else:
				_ok(not n.visible and n.process_mode == Node.PROCESS_MODE_DISABLED, "3: %s: %s sigue oculto" % [id, k])
		_ok(v.kael.global_position.distance_to(v.interiores.entrada(id)) < 0.3, "3: %s: Kael en la entrada" % id)
		_ok(absf(v.cam.global_rotation_degrees.y) < 0.001 and v.cam.global_position.distance_to(I.ORIGEN[id]) < 25.0,
			"3: %s: la cámara de dentro (sin girar, %.1f m del ORIGEN)" % [id, v.cam.global_position.distance_to(I.ORIGEN[id])])
		_ok(v.cam.fov == I.CAM_CAMPO and absf(v.cam.global_rotation_degrees.x + I.CAM_INCL) < 0.01, "3: %s: campo e inclinación" % id)
		_ok(v.interiores.choques > 0 and v.interiores._hechos.has(id), "3: %s: construido, con suelo de choque" % id)
		var fijo := v.interiores._nodos[id].find_child("fijo", true, false) as MeshInstance3D
		_ok(fijo != null and fijo.get_surface_override_material(0) is ShaderMaterial, "3: %s: luz horneada (calle_estatico)" % id)
		_ok(v.ancla("int_%s_entrada" % id) == v.interiores.entrada(id), "3: %s: region.ancla(int_*) va a los interiores" % id)
		v.guardar_posicion()
		_ok(Engine.get_meta("pos_3d") == T.PUERTAS[id]["fuera"] and int(Engine.get_meta("pos_3d_lugar")) == 102,
			"3: %s: guardar_posicion dentro guarda la PUERTA de fuera" % id)
		_ok(v.ambiente.background_color == I.FONDO_DENTRO, "3: %s: la luz de dentro (fondo oscuro, ambiente cálido)" % id)
		# andar un poco (con puntos de paso, como haría quien juega): sobre el suelo, la cámara sigue sin girar
		var meta: Vector3 = v.interiores.ancla(_meta_de(id))
		await _andar(id, RUTAS[id] + [meta])
		var k: Vector3 = v.kael.global_position
		_ok(Vector2(k.x - meta.x, k.z - meta.z).length() < 0.6, "3: %s: Kael anda hasta %s (a %.2f m)" % [id, _meta_de(id),
			Vector2(k.x - meta.x, k.z - meta.z).length()])
		_ok(absf(k.y - v.interiores.altura(k)) < 0.08 and absf(v.cam.global_rotation_degrees.y) < 0.001,
			"3: %s: sobre el suelo y sin girar la cámara" % id)
		await _salir(id)
		_ok(v.interior == "", "3: %s: fuera otra vez" % id)
		_ok(v.exterior.visible and not v.interiores._nodos[id].visible, "3: %s: el exterior se ve y el interior no" % id)
		var f: Vector3 = T.PUERTAS[id]["fuera"]
		_ok(Vector2(v.kael.global_position.x - f.x, v.kael.global_position.z - f.z).length() < 0.3,
			"3: %s: Kael sale a la puerta de fuera" % id)
		_ok(v.ambiente.background_color != I.FONDO_DENTRO, "3: %s: fuera, la luz de fuera otra vez" % id)
		_ok(P.estado("oak_barrio", "j_prueba_b") and Engine.get_meta("lore_visto", {}).has("bar_prueba_b"),
			"3: %s: lo examinado y lo hablado siguen igual" % id)
	# doble pulsación: el segundo toque, durante el fundido, no hace nada
	v._colocar_kael(T.PUERTAS["horno"]["fuera"])
	await _frames(3)
	_pulsar("entrar_horno")
	await _frames(4)
	v._bloqueo = 0.0
	v._accion()
	_ok(v.cambiando, "3: doble pulsación: sigue el mismo fundido")
	await _esperar_fundido()
	_ok(v.interior == "horno" and not v.cambiando, "3: doble pulsación: dentro una sola vez")
	await _salir("horno")


# Puntos de paso (locales) hasta la meta: Kael anda en línea recta y los muebles cortan el camino directo.
const RUTAS := {"horno": [], "taller": [Vector3(10.0, 0, 4.85)], "vivienda": [Vector3(4.3, 0, 7.25)]}


func _andar(id: String, puntos: Array) -> void:
	for q in puntos:
		var meta: Vector3 = q if q is Vector3 and (q as Vector3).length() > 50.0 else I.ORIGEN[id] + q
		meta.y = v.interiores.altura(meta)
		v.destino = meta
		for f in 600:
			await process_frame
			if v.destino == null:
				break


func _meta_de(id: String) -> String:
	return {"horno": "int_horno_estante", "taller": "int_taller_potro", "vivienda": "int_vivienda_mesa"}[id]


# ================================================================= 4. pasos internos

func _trastienda() -> void:
	P.poner_estado("oak_barrio", "enf_taller", false)
	v.interiores._forzado.clear()
	await _entrar("taller")
	var it = v.interiores
	_ok(not it.paso_abierto("trastienda"), "4: sin enf_taller, la trastienda está cerrada")
	_ok(not it.andable(it.ancla("int_taller_banco_corte")), "4: cerrada: el banco de cortar no se pisa")
	var hoja: Node3D = it._hojas.get("trastienda", null)
	_ok(hoja != null and absf(hoja.rotation.y) < 0.01, "4: cerrada: su hoja, cerrada")
	v.ultimo_aviso = ""
	v._colocar_kael(it.ancla("int_taller_paso_trastienda") + Vector3(0.6, 0, 0))
	await _frames(3)
	v.destino = it.ancla("int_taller_paso_trastienda")
	for f in 200:
		await process_frame
		if v.ultimo_aviso != "":
			break
	_ok(v.ultimo_aviso == I.AVISO_TRASTIENDA, "4: al acercarse, el aviso: «%s»" % v.ultimo_aviso)
	v.destino = it.ancla("int_taller_banco_corte")
	for f in 240:
		await process_frame
		if v.destino == null:
			break
	_ok((v.kael.global_position - I.ORIGEN["taller"]).x > 4.35, "4: cerrada: Kael no entra en la trastienda (x local %.2f)" %
		(v.kael.global_position - I.ORIGEN["taller"]).x)
	P.poner_estado("oak_barrio", "enf_taller", true)
	await _frames(60)
	_ok(it.paso_abierto("trastienda") and it.andable(it.ancla("int_taller_banco_corte")), "4: con enf_taller, abierta y se pisa")
	_ok(hoja != null and absf(rad_to_deg(hoja.rotation.y) + 90.0) < 2.0, "4: abierta: la hoja ha girado (%.0f°)" %
		(rad_to_deg(hoja.rotation.y) if hoja != null else 0.0))
	var meta: Vector3 = it.ancla("int_taller_banco_corte")
	v._colocar_kael(it.ancla("int_taller_paso_trastienda"))
	await _frames(2)
	await _andar("taller", [Vector3(3.2, 0, 4.9), meta])
	_ok(Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length() < 0.6,
		"4: abierta: Kael llega al banco de cortar")
	await _salir("taller")
	P.poner_estado("oak_barrio", "enf_taller", false)


func _alcoba_y_cortina() -> void:
	await _entrar("vivienda")
	var it = v.interiores
	var meta: Vector3 = it.ancla("int_vivienda_rincon")
	await _andar("vivienda", [Vector3(4.0, 0, 3.7), Vector3(4.0, 0, 2.4), meta])
	var k: Vector3 = v.kael.global_position
	_ok(Vector2(k.x - meta.x, k.z - meta.z).length() < 0.6 and absf(k.y - (I.ORIGEN["vivienda"].y + 0.35)) < 0.06,
		"4: vivienda: sube los dos escalones a la alcoba (y %.2f) y llega al rincón de Nela" % (k.y - I.ORIGEN["vivienda"].y))
	var galga: Node3D = it.sitio("galga")
	_ok(galga != null and galga.visible and _plano(galga.global_position).distance_to(_plano(it.ancla("int_vivienda_repisa"))) < 1.5
		and galga.global_position.y - it.ancla("int_vivienda_repisa").y > 1.3,
		"4: vivienda: la galga está sobre la repisa")
	await _salir("vivienda")
	await _entrar("horno")
	meta = it.ancla("int_horno_mesa")
	await _andar("horno", [Vector3(5.2, 0, 2.45), it.ancla("int_horno_cortina"), meta])
	k = v.kael.global_position
	_ok(Vector2(k.x - meta.x, k.z - meta.z).length() < 0.6, "4: horno: pasa la cortina y llega a la mesa de Maela")
	await _salir("horno")


# ================================================================= 5. CAL, restaurar, guardar y recargar, fundido cortado

func _cal() -> void:
	await _entrar("taller")
	var p: Vector3 = v.interiores.ancla("int_taller_potro")
	v._colocar_kael(p)
	await _frames(2)
	v._cambiar_perfil()
	await _cargar()
	_ok(v != null, "5: CAL: la región vuelve a cargar")
	if v == null:
		return
	_ok(v.interior == "taller" and not v.exterior.visible, "5: CAL dentro vuelve dentro (interior «%s»)" % v.interior)
	_ok(v.kael.global_position.distance_to(p) < 0.3, "5: CAL: en el mismo sitio de dentro")
	_ok(not Engine.has_meta("barrio_interior"), "5: CAL: la meta de sesión «barrio_interior» se consume")
	_ok(Engine.get_meta("pos_3d") == T.PUERTAS["taller"]["fuera"], "5: CAL: la partida guarda la puerta de fuera")
	await _salir("taller")


func _restaurar_en_origen() -> void:
	Engine.set_meta("pos_3d", I.ORIGEN["horno"] + Vector3(4.0, 0.0, 4.5))
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", 102)
	change_scene_to_file(ESCENA)
	await _cargar()
	_ok(v != null and v.interior == "" and v.kael.global_position.distance_to(T.ancla("inicio")) < 0.3,
		"5: una posición guardada dentro de un ORIGEN no se restaura: Kael en el inicio")


func _guardar_y_recargar() -> void:
	if v == null:
		return
	await _entrar("vivienda")
	v._colocar_kael(v.interiores.ancla("int_vivienda_repisa"))
	await _frames(2)
	var viejo = v
	v.guardar_y_recargar()
	# (18/11) la recarga va por Recursos.cambiar_escena (carga en hilo, tiempo real) a la MISMA escena: _cargar() se
	# conformaba con la región vieja, aún montada, si la carga tardaba más de un par de fotogramas (con 5 s de retraso:
	# «vuelve fuera» y Kael lejos de la puerta). Se espera por RELOJ a la región NUEVA y al final del cambio; si no
	# llega en 60 s, falla y no sigue (docs/v12/PRUEBAS_CARRERAS_18_11.md).
	var R = root.get_node("Recursos")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000 and (R.cambiando or current_scene == null or current_scene == viejo):
		await process_frame
	if R.cambiando or current_scene == null or current_scene == viejo:
		_ok(false, "5: «Guardar y recargar»: la recarga no termina en 60 s (R.cambiando=%s)" % R.cambiando)
		v = null
		return
	await _cargar()
	_ok(v != null and v.interior == "", "5: «Guardar y recargar» dentro: vuelve fuera")
	if v == null:
		return
	var f: Vector3 = T.PUERTAS["vivienda"]["fuera"]
	_ok(Vector2(v.kael.global_position.x - f.x, v.kael.global_position.z - f.z).length() < 0.3,
		"5: «Guardar y recargar»: Kael en la puerta de fuera de la vivienda")
	_ok(P.estado("oak_barrio", "j_prueba_b") and Engine.get_meta("lore_visto", {}).has("bar_prueba_b"),
		"5: «Guardar y recargar»: lo examinado y lo hablado siguen")


func _fundido_cortado() -> void:
	if v == null:
		return
	v._colocar_kael(T.PUERTAS["taller"]["fuera"])
	await _frames(3)
	_pulsar("entrar_taller")
	await _frames(6)                                       # a mitad del fundido: «Volver al banco» (sale de la escena)
	var vacia := PackedScene.new()
	var n := Node.new()
	vacia.pack(n)
	n.free()
	change_scene_to_packed(vacia)
	await _frames(40)
	_ok(not Engine.has_meta("barrio_interior"), "5: salir a mitad de un fundido no deja la meta «barrio_interior»")
	var BP = load("res://banco_pruebas.gd")
	BP.salir()
	_ok(not Engine.has_meta("barrio_v12") and I._mats.is_empty() and I._datos.is_empty(),
		"5: al salir del banco no quedan metas ni las cachés de los interiores")
