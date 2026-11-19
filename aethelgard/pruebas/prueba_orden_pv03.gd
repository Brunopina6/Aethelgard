extends SceneTree
# Prueba del orden de la misión (T-086; a partir de la sonda de narrativa): aunque Kael llegue hasta Tilo sin pisar
# el punto de PV-03, hablar con Tilo empieza PV-03 (llega Lya) y no PV-05. Misión desde cero, como prueba_ruta_alpha («-- 3d sin_prologo»).
#   1. Mapa de lo andable con las reglas de la región (_altura_suelo: paredes, pendientes, escalones y zonas
#      prohibidas), en una rejilla de 0,6 m, desde donde entra Kael y sin entrar en el círculo de PV-03 (+0,5 m).
#   2. Si llega a Tilo, Kael recorre ese camino de verdad (destino tocado: el mismo código que un toque en la pantalla)
#      y habla con él. Falla si empieza otro diálogo que no sea PV-03.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const PASO := 0.6
const MARGEN := 0.5

var fallos := 0
var D
var P
var R


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	P = load("res://progreso.gd")
	Engine.set_meta("hitos", {})
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("lore_visto", {})
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


# (19/11, PC-10) por RELOJ, solo para montar la región: con --fixed-fps los fotogramas vuelan y una carga va en tiempo
# real. El resto espera en tiempo de JUEGO a propósito (diálogos y Lya que llega corriendo).
func _hasta_reloj(cond: Callable, segundos := 60.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(segundos * 1000.0):
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _grupo(r) -> Array:
	return (r.grupo.nodos() if r.grupo != null else []).map(func(n): return String(n.name))


func _probar() -> void:
	if not await _hasta_reloj(func(): return current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando, 90.0):
		print("FALLO: no se llega a la región en 90 s (R.cambiando=%s)" % R.cambiando)
		print("FALLOS: 1")
		quit(1)
		return
	var r = current_scene
	if await _hasta(func(): return D.current_timeline != null and r.dialogo_actual == "pv_02", 30.0):
		await _esperar(10)
		D.end_timeline()
	await _hasta(func(): return D.current_timeline == null, 10.0)
	await _esperar(30)
	var centro: Vector3 = r.SENDERO[2]
	var inicio: Vector3 = r.kael.global_position
	var tilo: Vector3 = r.tilo.global_position
	print("INICIO: Kael en %s · Tilo en %s · hitos %s · grupo %s" % [inicio, tilo, Engine.get_meta("hitos", {}), _grupo(r)])
	# 1. rejilla de lo andable sin entrar en el círculo de PV-03
	var lim: Rect2 = r.LIMITE
	var nx := int(lim.size.x / PASO)
	var nz := int(lim.size.y / PASO)
	var celda := func(i: int, j: int) -> Vector3: return Vector3(lim.position.x + (i + 0.5) * PASO, 0, lim.position.y + (j + 0.5) * PASO)
	var i0 := int((inicio.x - lim.position.x) / PASO)
	var j0 := int((inicio.z - lim.position.y) / PASO)
	var alto := {}                                   # Vector2i → altura del suelo
	var de := {}                                     # Vector2i → Vector2i de donde viene
	var cola: Array = [Vector2i(i0, j0)]
	alto[Vector2i(i0, j0)] = inicio.y
	var meta = null
	var vecinos := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		var pc: Vector3 = celda.call(c.x, c.y)
		r.kael.global_position = Vector3(pc.x, alto[c], pc.z)
		if r._dist_plana(pc, tilo) < r.RADIO_ACCION - 0.4:
			meta = c
			break
		for v in vecinos:
			var n: Vector2i = c + v
			if alto.has(n) or n.x < 0 or n.y < 0 or n.x >= nx or n.y >= nz:
				continue
			var pn: Vector3 = celda.call(n.x, n.y)
			if r._dist_plana(pn, centro) < r.RADIO_PV03 + MARGEN:
				continue
			var y: float = r._altura_suelo(pn, alto[c])
			if is_nan(y):
				continue
			alto[n] = y
			de[n] = c
			cola.append(n)
	r.kael.global_position = inicio
	print("REJILLA: %d celdas andables alcanzadas sin entrar en el círculo de PV-03; Tilo %s" % [alto.size(), "ALCANZABLE" if meta != null else "no alcanzable"])
	if meta == null:
		print("NO SE LLEGA A TILO SIN PV-03")
		print("FALLOS: 0")
		quit(0)
		return
	var camino: Array = []
	var k = meta
	while de.has(k):
		camino.push_front(k)
		k = de[k]
	# puntos de paso: cada 4 celdas y el último
	var puntos: Array = []
	for idx in camino.size():
		if idx % 4 == 3 or idx == camino.size() - 1:
			var q: Vector3 = celda.call(camino[idx].x, camino[idx].y)
			puntos.append(Vector3(q.x, alto[camino[idx]], q.z))
	print("CAMINO: %d celdas, %d puntos de paso: %s" % [camino.size(), puntos.size(), puntos.map(func(p): return "(%.1f, %.1f)" % [p.x, p.z])])
	# 2. recorrerlo de verdad
	var minima := INF
	var parado := 0
	for p in puntos:
		r.destino = p
		var f := 0
		while f < 30 * 20:
			minima = minf(minima, r._dist_plana(r.kael.global_position, centro))
			if P.hito("pv_03") or D.current_timeline != null or r.destino == null:
				break
			f += 1
			await process_frame
		if r._dist_plana(r.kael.global_position, p) > 0.5:
			parado += 1
		if P.hito("pv_03") or D.current_timeline != null:
			break
	await _esperar(5)
	print("JUNTO A TILO: a %.1f m · cerca=«%s» · botón «%s» visible=%s · pv_03=%s · paradas lejos de un punto: %d · lo más cerca del punto de PV-03: %.1f m (radio %.1f)" % [
		r._dist_plana(r.kael.global_position, tilo), r.cerca, r.boton_accion.text, r.boton_accion.visible, P.hito("pv_03"), parado, minima, r.RADIO_PV03])
	if r.cerca == "tilo" and not P.hito("pv_03"):
		r._accion()
		await _hasta(func(): return r.dialogo_actual != "", 6.0)   # Lya llega corriendo: el diálogo empieza ~1,2 s después
		print("AL HABLAR CON TILO: diálogo «%s» · hitos %s · grupo %s · retratos en el diálogo: %s" % [
			r.dialogo_actual, Engine.get_meta("hitos", {}), _grupo(r), D.Portraits.get_joined_characters().map(func(c): return c.display_name)])
		if r.dialogo_actual != "pv_03" or P.hito("pv_05"):
			fallos += 1
			print("FALLO: hablar con Tilo antes de PV-03 empieza «%s» y no PV-03 (Lya hablaría sin estar)" % r.dialogo_actual)
		D.end_timeline()
		await _hasta(func(): return D.current_timeline == null, 10.0)
		await _esperar(20)
		print("DESPUÉS: hitos %s · grupo %s · objetivo «%s»" % [Engine.get_meta("hitos", {}), _grupo(r), r.texto_objetivo()])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
