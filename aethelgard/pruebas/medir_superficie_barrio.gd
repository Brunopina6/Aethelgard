extends SceneTree
# MEDIDA (16/11), no prueba: la superficie del barrio experimental de Oakhaven (zonas3d/barrio/trazado.gd), para fijar
# la escala de la ciudad completa (encargo: ≈ 10 veces la superficie EXPLORABLE del barrio). Recorre una rejilla de
# 0,25 m sobre la caja de todos los sectores y cuenta: lo andable (T.andable), lo andable ALCANZABLE desde el inicio
# (BFS), la caja de los sectores, los desniveles (cotas) y la longitud del bucle (grafo). Imprime y sale.
# Uso: --headless --path aethelgard --script res://pruebas/medir_superficie_barrio.gd

const T := preload("res://zonas3d/barrio/trazado.gd")
const PASO := 0.25


func _initialize() -> void:
	var caja := Rect2()
	var primero := true
	for s in T.SECTORES:
		var r: Rect2 = T.SECTORES[s]
		caja = r if primero else caja.merge(r)
		primero = false
	var nx := int(caja.size.x / PASO) + 1
	var nz := int(caja.size.y / PASO) + 1
	var andable := {}
	var por_sector := {}
	var hmin := INF
	var hmax := -INF
	for i in nx:
		for j in nz:
			var x := caja.position.x + i * PASO
			var z := caja.position.y + j * PASO
			if T.andable(x, z):
				andable[Vector2i(i, j)] = true
				var s: String = T.sector_de(x, z)
				por_sector[s] = int(por_sector.get(s, 0)) + 1
				var h: float = T.altura(x, z)
				hmin = minf(hmin, h)
				hmax = maxf(hmax, h)
	var ini: Vector3 = T.ancla("inicio")
	var arranque := Vector2i(int((ini.x - caja.position.x) / PASO), int((ini.z - caja.position.y) / PASO))
	var vistos := {arranque: true}
	var cola := [arranque]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if andable.has(n) and not vistos.has(n):
				vistos[n] = true
				cola.append(n)
	var largo := 0.0
	var aristas := {}
	for a in T.GRAFO:
		for b in T.GRAFO[a]:
			var k := [a, b] if a < b else [b, a]
			if not aristas.has(str(k)):
				aristas[str(k)] = true
				largo += Vector2(T.ancla(a).x - T.ancla(b).x, T.ancla(a).z - T.ancla(b).z).length()
	var m2 := PASO * PASO
	print("[superficie] caja de los sectores: %.1f × %.1f m = %.0f m²" % [caja.size.x, caja.size.y, caja.get_area()])
	print("[superficie] andable: %.0f m² · alcanzable desde el inicio: %.0f m² · cotas %.2f..%.2f m" % [
		andable.size() * m2, vistos.size() * m2, hmin, hmax])
	for s in por_sector:
		print("[superficie]   sector %s: %.0f m² andables" % [s, int(por_sector[s]) * m2])
	print("[superficie] grafo: %d nodos · %.0f m de aristas (sin repetir)" % [T.GRAFO.size(), largo])
	quit(0)
