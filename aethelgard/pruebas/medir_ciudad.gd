extends SceneTree
# MEDIDA (16/11, agente de medidas en PC), NO prueba (no va en lista_pruebas.txt): la CIUDAD COMPLETA de Oakhaven (maqueta
# EXPERIMENTAL, zonas3d/ciudad/, solo desde el banco de pruebas de Auditoría) en el PC con la ventana de verdad (la
# pantalla del Redmi: --resolution 1600x720; el proyecto conserva 16:9, el dibujo va a 1280×720 con franjas de 160 px).
# Resultado de PC: NO certifica Android (el Redmi está SIN MEDIR). Documento: docs/v12/ciudad_sectores/MEDIDAS_PC.md.
#
# MARCAS POR FOTOGRAMA (no Performance.TIME_PROCESS, que se publica una vez por segundo): dos nodos en la raíz, uno que
# procesa el PRIMERO (prioridad −10⁶) y otro el ÚLTIMO (+10⁶). Por fotograma: «real» (de un final de proceso al siguiente:
# el fotograma entero), «proceso» (del primero al último: los _process del juego, con el cargador y la oclusión), «herr»
# (lo que gasta esta herramienta: rutas y clics, para no achacárselo al juego), dibujo CPU y GPU que mide el motor
# (viewport_get_measured_render_time_*; la GPU llega con unos fotogramas de retraso) y llamadas y primitivas del último
# fotograma dibujado (RenderingServer.get_rendering_info, las mismas que Performance.RENDER_TOTAL_*: comparables con las
# del barrio) con el reparto visible / sombras / 2D.
#
# Fases (con el perfil fijado: Engine.set_meta("calidad_proto"); así el regulador de calidad NO actúa y la escala 3D es la
# del perfil, FIJA: bajo 0,75, medio 0,8, alto 1,0 con MSAA 2×; «escala=1.0» la cambia con calidad_extra para medir el bajo
# a resolución completa):
#   1. ENTRADA como una persona (clic en el caso del banco): la primera del proceso (en frío) y, tras «Volver al banco»
#      (clic), otra (en caliente): ms hasta el control, peor fotograma durante la carga y en los 2 s siguientes, memoria.
#   2. RECORRIDO andando con CLICS en el suelo (como recorrido_ciudad.gd: ruta A* por lo andable del plano, toques donde el
#      toque cae de verdad) por 10 de las 12 conexiones, con el TOPE de FPS del perfil (como se juega): cada montaje y
#      desmontaje del cargador con su fotograma (real y proceso), cada cruce de sector con el peor fotograma ±0,5 s, las
#      esperas del cargador (carga en hilo sin terminar) y lo máximo de llamadas, primitivas y sectores montados.
#   3. BARRIDO: Kael colocado cada «paso» metros por todo lo andable (sin tope): llamadas y primitivas de cada vista.
#   4. PUNTOS: la referencia de cada sector y las 4 vistas más cargadas del barrido (separadas ≥ 20 m), 3 s con el tope del
#      perfil y 3 s SIN tope ni sincronía vertical (con Kael, Lya y Garon).
#   5. Lo que cuesta cada sector (fuera del árbol: construir(), mallas, superficies, triángulos, rótulos y choques) y la
#      maqueta lejana; memoria al final.
# Uso (APPDATA y LOCALAPPDATA en una carpeta aislada; la partida es la del banco, en user://):
#   Godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_ciudad.gd -- perfil=bajo|medio|alto
#     salida=<carpeta fuera del proyecto> [escala=1.0] [recorrido=0] [paso=8] [experimento=1] [solo_recorrido=1]
# «experimento=1» (con recorrido=0): tras el barrido, solo las vistas más cargadas, y en cada una lo que pesan los rótulos,
# los ocultables, la maqueta lejana, el grupo y la interfaz 2D (se ocultan un momento; el juego no cambia).

const BANCO := "res://banco_pruebas.tscn"
const ESCENA := "res://zonas3d/ciudad/ciudad.tscn"
const P := preload("res://zonas3d/ciudad/plano.gd")
const C := 0.25
const X0 := -100.0
const Z0 := -92.0
const W := 840
const H := 748
const MAX_RECTA := 9.0
const LLEGA := 0.6
const VEL := 4.2
const RUTA := ["s_puerta_sur", "c_calle_mayor", "s_plaza_tapiz", "c_calle_mercado", "s_oficios", "c_escalera_molino",
	"s_ribera", "c_rampa_carros", "s_puerta_sur", "c_arco_pasajes", "s_pasajes", "c_pasaje_velas", "s_cuervo",
	"c_escaleras_terrazas", "s_terrazas", "c_terrazas_altas", "s_barrio_alto", "c_calle_arbol", "s_plaza_tapiz",
	"c_paso_botica", "s_pasajes"]


class Marca extends Node:
	var t := 0

	func _process(_d: float) -> void:
		t = Time.get_ticks_usec()


class Muestreo extends Node:
	var inicio: Marca
	var grabando := false
	var muestras: Array = []
	var vp: RID
	var ultimo := 0
	var herr := 0.0
	var escena = null

	func _process(_d: float) -> void:
		var ahora := Time.get_ticks_usec()
		var coste := _coste()
		if grabando and ultimo > 0:
			var RS := RenderingServer
			var m := {"real": (ahora - ultimo) / 1000.0, "proc": (ahora - inicio.t) / 1000.0, "herr": herr,
				"cpu": RS.viewport_get_measured_render_time_cpu(vp) + RS.get_frame_setup_time_cpu(),
				"gpu": RS.viewport_get_measured_render_time_gpu(vp),
				"ll": RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
				"pr": RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
				"llv": RS.viewport_get_render_info(vp, RS.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RS.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
				"lls": RS.viewport_get_render_info(vp, RS.VIEWPORT_RENDER_INFO_TYPE_SHADOW, RS.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
				"llc": RS.viewport_get_render_info(vp, RS.VIEWPORT_RENDER_INFO_TYPE_CANVAS, RS.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
				"t": ahora, "fd": Engine.get_frames_drawn()}
			if escena != null and is_instance_valid(escena) and escena.get("cargador") != null:
				m["sec"] = escena.cargador.actual
				m["mont"] = escena.cargador.montados.size()
				m["pos"] = escena.kael.global_position
			m.merge(coste)
			muestras.append(m)
		herr = 0.0
		ultimo = ahora

	# (18/11, coste de los arreglos del Redmi) Si la escena o su grupo llevan la INSTRUMENTACIÓN temporal
	# (pruebas/instrumentar_coste_ciudad.py: «_coste_x» = {función: [µs, llamadas]} de este fotograma), se recoge y se vacía.
	# Sin instrumentar no hay nada que recoger y la medida es la de siempre.
	func _coste() -> Dictionary:
		var r := {}
		if escena == null or not is_instance_valid(escena):
			return r
		var fuentes: Array = [escena.get("_coste_x")]
		var g = escena.get("grupo")
		if g != null and is_instance_valid(g):
			fuentes.append(g.get("_coste_x"))
		for cx in fuentes:
			if cx is Dictionary:
				for k in cx:
					r["us_" + k] = float(cx[k][0])
					r["n_" + k] = float(cx[k][1])
				cx.clear()
		return r


var perfil := "bajo"
var salida := ""
var escala := -1.0
var con_recorrido := true
var paso := 8.0
var experimento := false                       # «experimento=1»: solo las vistas cargadas, quitando cosas para ver cuánto pesan
var solo_recorrido := false                    # «solo_recorrido=1» (18/11): entrada y recorrido andando, sin barrido ni puntos
var lineas: PackedStringArray = []
var v = null
var mu: Muestreo
var ini: Marca
var astar: AStarGrid2D
var anda := PackedByteArray()
var rodillas := {}
var eventos: Array = []                        # [índice de muestra, texto]


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a.begins_with("escala="):
			escala = float(a.trim_prefix("escala="))
		elif a == "recorrido=0":
			con_recorrido = false
		elif a.begins_with("paso="):
			paso = float(a.trim_prefix("paso="))
		elif a == "experimento=1":
			experimento = true
		elif a == "solo_recorrido=1":
			solo_recorrido = true
	Engine.set_meta("calidad_proto", perfil)
	if escala > 0.0:
		Engine.set_meta("calidad_extra", {"escala_3d": escala})
	_medir.call_deferred()


# ================================================================= utilidades

func _nota(t: String) -> void:
	print(t)
	lineas.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _esperar(seg: float) -> void:
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < int(seg * 1000000.0):
		await process_frame


func _mem() -> String:
	return "estática %.1f MB (máx %.1f) · vídeo %.1f MB · texturas %.1f MB · búferes %.1f MB · objetos %d · nodos %d" % [
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]


# (16/11, optimización) Si la ventana no dibuja (minimizada u oculta: pasó dos veces en el PC), las llamadas y primitivas
# son las del último fotograma dibujado y los ms no valen: se avisa en la línea de la medida.
func _sin_dibujar(ms: Array) -> String:
	if ms.size() < 2:
		return ""
	var dib: int = int(ms[-1].get("fd", 0)) - int(ms[0].get("fd", 0))
	if dib < (ms.size() - 1) * 0.9:
		return " · AVISO: la ventana dibujó %d de %d fotogramas (modo de ventana %d): esta medida NO VALE" % [dib, ms.size() - 1,
			DisplayServer.window_get_mode()]
	return ""


# Antes de cada medida: si la ventana de la medida está minimizada (Godot no dibuja), se restaura y se anota.
func _ventana() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		_nota("[%s] (la ventana de la medida estaba minimizada: se restaura)" % perfil)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		await _frames(10)


func _valores(ms: Array, clave: String, positivos := false) -> Array:
	var r: Array = []
	for m in ms:
		var x: float = float(m.get(clave, 0.0))
		if positivos and x <= 0.0:
			continue
		r.append(x)
	r.sort()
	return r


func _est(ms: Array, clave: String, positivos := false) -> Dictionary:
	var o := _valores(ms, clave, positivos)
	if o.is_empty():
		return {"med": -1.0, "p95": -1.0, "max": -1.0, "n": 0}
	return {"med": o[o.size() / 2], "p95": o[mini(o.size() - 1, int(o.size() * 0.95))], "max": o[-1], "n": o.size()}


func _txt_est(ms: Array, clave: String, positivos := false, dec := 1) -> String:
	var e := _est(ms, clave, positivos)
	var f := "%." + str(dec) + "f"
	return ("mediana " + f + " · p95 " + f + " · máx " + f) % [e["med"], e["p95"], e["max"]]


func _txt(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


func _kael() -> Vector3:
	return v.kael.global_position


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _suelo(p: Vector3) -> Vector3:
	return Vector3(p.x, P.altura(p.x, p.z), p.z)


func _vivo() -> bool:
	return v != null and is_instance_valid(v) and v.is_inside_tree()


func _sin_tope(si: bool) -> void:
	if si:
		v.perfil_fps = 0
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		v.perfil_fps = int(v.perfil.get("fps", 30))
		Engine.max_fps = v.perfil_fps
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


# El ancla con nombre más cercana (global o de un trazado), para decir dónde está una vista.
func _donde(p: Vector3) -> String:
	var mejor := ""
	var dmin := INF
	for k in P.ANCLAS:
		var d := _plana(P.ANCLAS[k], p)
		if d < dmin:
			dmin = d
			mejor = k
	var s := P.sector_de(p.x, p.z)
	var t = P.trazado(s) if s != "" else null
	if t != null:
		for k in t.ANCLAS:
			var q = t.ANCLAS[k]
			if q is Vector3 or q is Vector2:
				var w := Vector3(q.x, 0.0, q.y) if q is Vector2 else (q as Vector3)
				var d := _plana(w, p)
				if d < dmin:
					dmin = d
					mejor = "%s/%s" % [s, k]
	return "%s, %.0f m de «%s»" % [P.SECTORES[s]["nombre"] if s != "" else "fuera", dmin, mejor]


# ================================================================= controles (como recorrido_ciudad.gd)

func _clic(pos: Vector2) -> void:
	await _ventana()                           # (minimizada, el clic caía en otro sitio: en el botón de calidad)
	var w: Vector2 = root.get_final_transform() * pos
	var m := InputEventMouseMotion.new()
	m.position = w
	m.global_position = w
	Input.parse_input_event(m)
	await _frames(1)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = w
	e.global_position = w
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var s := InputEventMouseButton.new()
	s.button_index = MOUSE_BUTTON_LEFT
	s.position = w
	s.global_position = w
	s.pressed = false
	Input.parse_input_event(s)
	await _frames(2)


func _pulsar(b: Control, hecho: Callable, seg: float) -> bool:
	for intento in 3:
		if b == null or not is_instance_valid(b) or not b.is_visible_in_tree():
			return hecho.call()
		await _clic(b.get_global_rect().get_center())
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < seg * 1000.0:
			if hecho.call():
				return true
			await process_frame
	return hecho.call()


func _boton_banco() -> Button:
	var r = root.get_node_or_null("Recursos")
	return r.boton_banco if r != null else null


func _se_puede_tocar(pp: Vector2) -> bool:
	if not Rect2(20, 100, 1240, 610).has_point(pp):
		return false
	for b in [v.boton_accion, v.boton_recargar, _boton_banco()]:
		if b != null and b.is_visible_in_tree() and (b as Control).get_global_rect().grow(10).has_point(pp):
			return false
	return true


# ================================================================= rejilla y ruta (las de recorrido_ciudad.gd)

func _rango(r: Rect2) -> Array:
	var i0 := clampi(int(ceil((r.position.x - X0) / C - 0.5)), 0, W)
	var i1 := clampi(int(ceil((r.end.x - X0) / C - 0.5)) - 1, -1, W - 1)
	var j0 := clampi(int(ceil((r.position.y - Z0) / C - 0.5)), 0, H)
	var j1 := clampi(int(ceil((r.end.y - Z0) / C - 0.5)) - 1, -1, H - 1)
	return [i0, i1, j0, j1]


func _centro(i: int, j: int) -> Vector2:
	return Vector2(X0 + (i + 0.5) * C, Z0 + (j + 0.5) * C)


func _celda(x: float, z: float) -> Vector2i:
	return Vector2i(clampi(int(floor((x - X0) / C)), 0, W - 1), clampi(int(floor((z - Z0) / C)), 0, H - 1))


func _preparar_rejilla() -> void:
	var t0 := Time.get_ticks_msec()
	anda.resize(W * H)
	anda.fill(0)
	for s in P.ORDEN:
		var caja: Rect2 = P.SECTORES[s]["caja"]
		var t = P.trazado(s)
		for su in t.SUELOS:
			var g: Array = _rango(su[1])
			for j in range(g[2], g[3] + 1):
				for i in range(g[0], g[1] + 1):
					if caja.has_point(_centro(i, j)):
						anda[j * W + i] = 1
		for b in t.BLOQUES:
			if not b[6]:
				continue
			var g: Array = _rango(b[2])
			for j in range(g[2], g[3] + 1):
				for i in range(g[0], g[1] + 1):
					if caja.has_point(_centro(i, j)):
						anda[j * W + i] = 0
	# (18/11) el CUERPO de Kael (desde 17/11, ciudad._altura_suelo y plano.holgura): la franja de RADIO_CUERPO junto a
	# paredes, pilares gruesos y jardineras altas no se pisa, como en recorrido_ciudad.gd. Con las constantes copiadas aquí
	# (no las de trazado_comun.gd) para que la MISMA ruta sirva también con el código de antes (70b5f82) y se comparen ms.
	for s3 in P.ORDEN:
		for b in P.trazado(s3).BLOQUES:
			if not b[6] or _fino(b):
				continue
			var g: Array = _rango((b[2] as Rect2).grow(RADIO_CUERPO))
			for j in range(g[2], g[3] + 1):
				for i in range(g[0], g[1] + 1):
					if anda[j * W + i] == 1:
						var q := _centro(i, j)
						if _dist_planta(b[2], q) < RADIO_CUERPO and float(b[3]) + float(b[4]) > P.altura(q.x, q.y) + ALTO_PARED:
							anda[j * W + i] = 0
	for s2 in P.ORDEN:
		for b in P.trazado(s2).BLOQUES:
			if b[6] and float(b[4]) > 0.6:
				var r: Rect2 = (b[2] as Rect2).grow(0.05)
				for cz in range(int(floor(r.position.y / 4.0)), int(floor(r.end.y / 4.0)) + 1):
					for cx in range(int(floor(r.position.x / 4.0)), int(floor(r.end.x / 4.0)) + 1):
						var clave := Vector2i(cx, cz)
						if not rodillas.has(clave):
							rodillas[clave] = []
						rodillas[clave].append(r)
	var cerca1 := PackedByteArray()
	cerca1.resize(W * H)
	for j in H:
		for i in W:
			var k := j * W + i
			if anda[k] == 1 and ((i == 0 or anda[k - 1] == 0) or (i == W - 1 or anda[k + 1] == 0) or (j == 0 or anda[k - W] == 0) or (j == H - 1 or anda[k + W] == 0)):
				cerca1[k] = 1
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, W, H)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.update()
	var n := 0
	for j in H:
		for i in W:
			var k := j * W + i
			if anda[k] == 0:
				astar.set_point_solid(Vector2i(i, j), true)
			else:
				n += 1
				if cerca1[k] == 1:
					astar.set_point_weight_scale(Vector2i(i, j), 4.0)
	_nota("rejilla: %d casillas andables (%.0f m²) en %.1f s" % [n, n * C * C, (Time.get_ticks_msec() - t0) / 1000.0])


func _anda_rejilla(x: float, z: float) -> bool:
	var c := _celda(x, z)
	return anda[c.y * W + c.x] == 1


func _rodilla(x: float, z: float) -> bool:
	var q := Vector2(x, z)
	for r in rodillas.get(Vector2i(int(floor(x / 4.0)), int(floor(z / 4.0))), []):
		if (r as Rect2).has_point(q):
			return true
	return false


func _celda_libre(p: Vector3) -> Vector2i:
	var c := _celda(p.x, p.z)
	if anda[c.y * W + c.x] == 1:
		return c
	var mejor := c
	var dmin := INF
	for r in range(1, 9):
		for j in range(c.y - r, c.y + r + 1):
			for i in range(c.x - r, c.x + r + 1):
				if i < 0 or j < 0 or i >= W or j >= H or anda[j * W + i] == 0:
					continue
				var d := _centro(i, j).distance_to(Vector2(p.x, p.z))
				if d < dmin:
					dmin = d
					mejor = Vector2i(i, j)
		if dmin < INF:
			return mejor
	return c


func _ruta(a: Vector3, b: Vector3) -> PackedVector2Array:
	var ids := astar.get_id_path(_celda_libre(a), _celda_libre(b))
	var r := PackedVector2Array()
	r.append(Vector2(a.x, a.z))
	for i in range(1, ids.size()):
		r.append(_centro(ids[i].x, ids[i].y))
	if ids.size() > 0:
		r[r.size() - 1] = Vector2(b.x, b.z)
	return r


# (18/11) Copias de trazado_comun.gd (17/11: RADIO_CUERPO, ALTO_PARED, fino, distancia_planta, holgura) para la ruta.
const RADIO_CUERPO := 0.3
const ALTO_PARED := 1.0


func _fino(b: Array) -> bool:
	var r: Rect2 = b[2]
	return r.size.x <= 0.6 + 0.001 and r.size.y <= 0.6 + 0.001


func _dist_planta(r: Rect2, p: Vector2) -> float:
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)).distance_to(p)


func _holgura(x: float, z: float) -> float:
	if not P.andable(x, z):
		return 0.0
	var y := P.altura(x, z)
	var p := Vector2(x, z)
	var h := RADIO_CUERPO
	for s in P.ORDEN:
		if not (P.SECTORES[s]["caja"] as Rect2).grow(RADIO_CUERPO + 0.5).has_point(p):
			continue
		for b in P.trazado(s).BLOQUES:
			if b[6] and float(b[3]) + float(b[4]) > y + ALTO_PARED and not _fino(b):
				h = minf(h, _dist_planta(b[2], p))
	return h


func _recta_libre(a: Vector3, b: Vector3, exacta := true) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var l := d.length()
	if l < 0.05:
		return true
	var dir := d / l
	var n := int(ceil(l / 0.1))
	var y_ant := P.altura(a.x, a.z) if exacta else 0.0
	var h_ant := _holgura(a.x, a.z) if exacta else 0.0
	for i in range(1, n + 1):
		var q := Vector2(a.x, a.z) + d * (float(i) / n)
		if exacta:
			if not P.andable(q.x, q.y):
				return false
			var y := P.altura(q.x, q.y)
			if absf(y - y_ant) > 0.3:
				return false
			y_ant = y
			var h := _holgura(q.x, q.y)                 # (18/11) en la franja del cuerpo no se entra
			if h < RADIO_CUERPO - 0.001 and h < h_ant - 0.001:
				return false
			h_ant = h
		elif not _anda_rejilla(q.x, q.y):
			return false
		if l * float(i) / n < l - 0.15:
			for adelante in [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45]:
				var r: Vector2 = q + dir * adelante
				if _rodilla(r.x, r.y):
					return false
	return true


func _probar_toque(k: Vector3, w: Vector3) -> Variant:
	var cam: Camera3D = v.cam
	for alto in [0.0, 0.3]:
		var q := w + Vector3(0.0, alto, 0.0)
		if cam.is_position_behind(q):
			continue
		var pp := cam.unproject_position(q)
		if not _se_puede_tocar(pp):
			continue
		var d = v._ajustar_destino(v._punto_suelo(pp))
		if d == null or _plana(d, w) > 0.5 or not _recta_libre(k, d):
			continue
		return [d, pp]
	return null


# El siguiente toque por la ruta ya calculada (sin rehacer el A* cada vez: su coste caería en el fotograma).
func _siguiente_toque(ruta: PackedVector2Array) -> Variant:
	var k := _kael()
	var i0 := 0
	var dmin := INF
	for i in ruta.size():
		var d := ruta[i].distance_to(Vector2(k.x, k.z))
		if d < dmin:
			dmin = d
			i0 = i
	var cand: Array = []
	var acum := 0.0
	for j in range(i0 + 1, ruta.size()):
		acum += ruta[j].distance_to(ruta[j - 1])
		if acum > MAX_RECTA * 1.4:
			break
		cand.append(j)
	cand.reverse()
	for lado in [[0.0], [0.7, -0.7, 1.4, -1.4]]:
		for j in cand:
			var w0 := _suelo(Vector3(ruta[j].x, 0.0, ruta[j].y))
			var n := Vector3(-(w0.z - k.z), 0.0, w0.x - k.x).normalized()
			for off in lado:
				var w := _suelo(w0 + n * off)
				if _plana(k, w) > MAX_RECTA or _plana(k, w) < 0.2:
					continue
				if not _recta_libre(k, w, false):
					continue
				var r: Variant = _probar_toque(k, w)
				if r != null:
					return r
	return null


# Andar hasta «meta» con clics (tiempo REAL: sin --fixed-fps). Devuelve [llega, segundos, clics].
func _andar_a(meta: Vector3) -> Array:
	var t0 := Time.get_ticks_usec()
	var th := Time.get_ticks_usec()
	var ruta := _ruta(_kael(), meta)
	mu.herr += (Time.get_ticks_usec() - th) / 1000.0
	var largo := 0.0
	for i in range(1, ruta.size()):
		largo += ruta[i].distance_to(ruta[i - 1])
	var limite := (largo / VEL) * 1.8 + 8.0
	var clics := 0
	var objetivo = null
	var rehechas := 0
	while (Time.get_ticks_usec() - t0) / 1000000.0 < limite:
		if not _vivo():
			break
		var k := _kael()
		if _plana(k, meta) < LLEGA:
			break
		var parado: bool = v.destino == null
		var cerca_obj: bool = objetivo != null and _plana(k, objetivo) < 1.2 and _plana(objetivo, meta) > 0.1
		if parado or cerca_obj:
			th = Time.get_ticks_usec()
			var s: Variant = _siguiente_toque(ruta)
			if s == null and parado and rehechas < 4:
				rehechas += 1
				ruta = _ruta(k, meta)
				s = _siguiente_toque(ruta)
			mu.herr += (Time.get_ticks_usec() - th) / 1000.0
			if s != null and (parado or _plana(s[0], meta) < _plana(objetivo, meta) - 0.5):
				objetivo = s[0]
				await _clic(s[1])
				clics += 1
				continue
			if s == null and parado:
				break
		await process_frame
	return [_plana(_kael(), meta) < LLEGA + 0.3, (Time.get_ticks_usec() - t0) / 1000000.0, clics]


# ================================================================= banco y entrada

func _esperar_banco() -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == BANCO and current_scene.get("marco") != null:
			var R = root.get_node_or_null("Recursos")
			if R == null or not R.cambiando:
				break
	await _esperar(1.0)


func _ciudad_lista() -> bool:
	var R = root.get_node_or_null("Recursos")
	var c = current_scene
	return c != null and c.scene_file_path == ESCENA and c.get("kael") != null and c.get("cargador") != null \
		and (R == null or not R.cambiando)


# Clic en el caso del banco; mide hasta el control (la escena lista y sin fundido) y los 2 s siguientes.
func _entrar(etiqueta: String) -> bool:
	var BP = load("res://banco_pruebas.gd")
	var titulo: String = BP.EXPLORAR["ciudad"]["titulo"]
	var b: Button = null
	for x in current_scene.find_children("*", "Button", true, false):
		if (x as Button).text == titulo:
			b = x
	if b == null:
		_nota("FALLO: el banco no tiene el caso «%s»" % titulo)
		return false
	current_scene.marco.ensure_control_visible(b)
	await _frames(6)
	var mem0 := _mem()
	mu.escena = null
	mu.muestras.clear()
	mu.grabando = true
	var t0 := Time.get_ticks_usec()
	var R0 = root.get_node_or_null("Recursos")
	await _pulsar(b, func(): return R0.cambiando or (current_scene != null and current_scene.scene_file_path == ESCENA), 3.0)
	while not _ciudad_lista() and Time.get_ticks_usec() - t0 < 60000000:
		await process_frame
	var carga := (Time.get_ticks_usec() - t0) / 1000.0
	var n_carga := mu.muestras.size()
	if not _ciudad_lista():
		_nota("FALLO: el caso de la ciudad no la abre")
		return false
	v = current_scene
	mu.escena = v
	await _esperar(2.0)
	mu.grabando = false
	var durante := mu.muestras.slice(0, n_carga)
	var despues := mu.muestras.slice(n_carga)
	_nota("[%s] ENTRADA %s (clic en el caso del banco → control): %.0f ms · peor fotograma durante la carga %.0f ms (%d fotogramas) · los 2 s siguientes: real %s ms, proceso máx %.1f ms · %d de 8 sectores montados %s · Kael en %s" % [
		perfil, etiqueta, carga, _est(durante, "real")["max"], durante.size(), _txt_est(despues, "real"),
		_est(despues, "proc")["max"], v.cargador.montados.size(), str(v.cargador.ids_montados()), _txt(_kael())])
	_nota("[%s]   memoria antes (banco): %s" % [perfil, mem0])
	_nota("[%s]   memoria en la ciudad: %s" % [perfil, _mem()])
	return true


func _volver_al_banco() -> bool:
	var b := _boton_banco()
	if b == null or not b.is_visible_in_tree():
		_nota("FALLO: no se ve «Volver al banco»")
		return false
	await _pulsar(b, func(): return current_scene == null or current_scene.scene_file_path != ESCENA, 3.0)
	v = null
	mu.escena = null
	await _esperar_banco()
	return current_scene != null and current_scene.scene_file_path == BANCO


# ================================================================= recorrido

func _al_montar(id: String) -> void:
	eventos.append([mu.muestras.size(), "monta " + id])


func _al_desmontar(id: String) -> void:
	eventos.append([mu.muestras.size(), "desmonta " + id])


func _recorrido() -> void:
	await _ventana()
	v.cargador.sector_montado.connect(_al_montar)
	v.cargador.sector_desmontado.connect(_al_desmontar)
	_sin_tope(false)
	var esperas0: int = v.cargador.esperas
	eventos.clear()
	mu.muestras.clear()
	mu.grabando = true
	var t0 := Time.get_ticks_usec()
	var tramos_mal: Array = []
	for n in RUTA:
		var meta: Vector3 = P.nodo(n)
		var r: Array = await _andar_a(meta)
		if not r[0]:
			tramos_mal.append("%s (se queda en %s)" % [n, _txt(_kael())])
			var i := mu.muestras.size()
			v._colocar_kael(meta)                   # (atasco: se coloca y se sigue; el evento se marca)
			if v.grupo != null:
				v.grupo.colocar(Vector3.BACK)
			eventos.append([i, "COLOCADO en " + n + " (atasco)"])
	mu.grabando = false
	var seg := (Time.get_ticks_usec() - t0) / 1000000.0
	v.cargador.sector_montado.disconnect(_al_montar)
	v.cargador.sector_desmontado.disconnect(_al_desmontar)
	var ms: Array = mu.muestras
	var presupuesto := 1000.0 / maxf(1.0, float(v.perfil.get("fps", 30)))
	_nota("[%s] RECORRIDO andando con clics (tope %d FPS, presupuesto %.1f ms): %.0f s, %d fotogramas · real %s ms · proceso %s ms · herramienta máx %.1f ms · dibujo CPU %s ms · GPU %s ms" % [
		perfil, int(v.perfil.get("fps", 30)), presupuesto, seg, ms.size(), _txt_est(ms, "real"), _txt_est(ms, "proc", false, 2),
		_est(ms, "herr")["max"], _txt_est(ms, "cpu", false, 2), _txt_est(ms, "gpu", true, 2)])
	_nota("[%s]   llamadas %s · primitivas %s · sectores montados máx %d · esperas del cargador (carga en hilo sin terminar al montar) %d · tramos sin llegar %s%s" % [
		perfil, _txt_est(ms, "ll", false, 0), _txt_est(ms, "pr", false, 0), int(_est(ms, "mont")["max"]),
		v.cargador.esperas - esperas0, str(tramos_mal), _sin_dibujar(ms)])
	_coste_funciones(ms)
	var sobre := ms.filter(func(m): return float(m["real"]) - float(m["herr"]) > presupuesto * 1.5)
	_nota("[%s]   fotogramas de más de %.0f ms (1,5 × presupuesto, sin lo de la herramienta): %d" % [perfil, presupuesto * 1.5, sobre.size()])
	# el peor fotograma por la vista: dónde
	var peor_ll := {}
	var peor_pr := {}
	for m in ms:
		if peor_ll.is_empty() or int(m["ll"]) > int(peor_ll["ll"]):
			peor_ll = m
		if peor_pr.is_empty() or int(m["pr"]) > int(peor_pr["pr"]):
			peor_pr = m
	if not peor_ll.is_empty():
		_nota("[%s]   más llamadas andando: %d (%d primitivas) en %s · %s · %d montados" % [perfil, peor_ll["ll"], peor_ll["pr"],
			_txt(peor_ll.get("pos", Vector3.ZERO)), _donde(peor_ll.get("pos", Vector3.ZERO)), peor_ll.get("mont", 0)])
		_nota("[%s]   más primitivas andando: %d (%d llamadas) en %s · %s · %d montados" % [perfil, peor_pr["pr"], peor_pr["ll"],
			_txt(peor_pr.get("pos", Vector3.ZERO)), _donde(peor_pr.get("pos", Vector3.ZERO)), peor_pr.get("mont", 0)])
	# cada montaje y desmontaje: su fotograma (la señal sale dentro del proceso de ese fotograma)
	var por_mont: Array = []
	for e in eventos:
		var i: int = e[0]
		if i < ms.size():
			var m: Dictionary = ms[i]
			por_mont.append(float(m["proc"]))
			var sig := 0.0                       # (16/11) los 5 fotogramas siguientes (los choques repartidos: sector.gd)
			for j in range(i + 1, mini(ms.size(), i + 6)):
				sig = maxf(sig, float(ms[j]["proc"]))
			_nota("[%s]   %s: fotograma real %.1f ms (herramienta %.1f) · proceso %.1f ms · dibujo CPU %.2f · en %s · los 5 siguientes: proceso máx %.1f ms" % [
				perfil, e[1], m["real"], m["herr"], m["proc"], m["cpu"], _txt(m.get("pos", Vector3.ZERO)), sig])
	# cada cruce de sector: el peor fotograma ±0,5 s
	var cruces := 0
	var peor_cruce := 0.0
	var peor_cruce_proc := 0.0
	for i in range(1, ms.size()):
		if ms[i].get("sec", "") != ms[i - 1].get("sec", "") and ms[i].get("sec", "") != "":
			cruces += 1
			var t: int = ms[i]["t"]
			var peor := 0.0
			var peor_p := 0.0
			for j in range(maxi(0, i - 60), mini(ms.size(), i + 60)):
				if absi(int(ms[j]["t"]) - t) <= 500000:
					peor = maxf(peor, float(ms[j]["real"]) - float(ms[j]["herr"]))
					peor_p = maxf(peor_p, float(ms[j]["proc"]))
			peor_cruce = maxf(peor_cruce, peor)
			peor_cruce_proc = maxf(peor_cruce_proc, peor_p)
			_nota("[%s]   cruce %s → %s: peor fotograma ±0,5 s %.1f ms (sin herramienta) · proceso máx %.1f ms · montados %d" % [
				perfil, ms[i - 1].get("sec", ""), ms[i]["sec"], peor, peor_p, ms[i].get("mont", 0)])
	_nota("[%s]   RESUMEN cargador: %d montajes/desmontajes, proceso en su fotograma máx %.1f ms; %d cruces, peor fotograma ±0,5 s %.1f ms, proceso máx %.1f ms" % [
		perfil, eventos.size(), por_mont.max() if not por_mont.is_empty() else -1.0, cruces, peor_cruce, peor_cruce_proc])
	_nota("[%s]   memoria tras el recorrido: %s" % [perfil, _mem()])


# (18/11) Con la instrumentación temporal: por función, µs por fotograma (todos los fotogramas del recorrido, 0 si no se
# llamó) y llamadas por fotograma, y µs por llamada. Las anidadas se cuentan en las dos (el rodeo llama a _altura_suelo).
func _coste_funciones(ms: Array) -> void:
	var claves: Array = []
	for m in ms:
		for k in m:
			if String(k).begins_with("us_") and not (String(k) in claves):
				claves.append(String(k))
	claves.sort()
	for k in claves:
		var nombre: String = k.trim_prefix("us_")
		var tot := 0.0
		var llam := 0.0
		for m in ms:
			tot += float(m.get(k, 0.0))
			llam += float(m.get("n_" + nombre, 0.0))
		_nota("[%s]   COSTE %s: µs por fotograma %s · llamadas por fotograma %s · %.2f µs por llamada · %.0f llamadas en %d fotogramas" % [
			perfil, nombre, _txt_est(ms, k, false, 0), _txt_est(ms, "n_" + nombre, false, 0), tot / maxf(1.0, llam), llam, ms.size()])


# ================================================================= barrido y puntos

func _colocar(p: Vector3) -> void:
	v.destino = null
	v._colocar_kael(_suelo(p))
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _asentar(max_seg := 2.0) -> void:
	var t0 := Time.get_ticks_usec()
	await _frames(2)
	while Time.get_ticks_usec() - t0 < int(max_seg * 1000000.0):
		var cargando := false
		for id in P.ORDEN:
			if v.cargador.estado.get(id, "") == "cargando":
				cargando = true
		if not cargando:
			break
		await process_frame
	await _frames(4)


func _barrido() -> Array:
	await _ventana()
	_sin_tope(true)
	var puntos: Array = []
	var cada := int(round(paso / C))
	for j in range(cada / 2, H, cada):
		for i in range(cada / 2, W, cada):
			if anda[j * W + i] == 1:
				var c := _centro(i, j)
				if P.andable(c.x, c.y):
					puntos.append(Vector3(c.x, P.altura(c.x, c.y), c.y))
	var t0 := Time.get_ticks_msec()
	var r: Array = []
	var sin_dibujar := 0                     # (16/11) vistas tomadas con la ventana sin dibujar: se repiten
	for p in puntos:
		await _ventana()
		_colocar(p)
		var fd := Engine.get_frames_drawn()
		await _asentar()
		if Engine.get_frames_drawn() - fd < 3:
			sin_dibujar += 1
			await _ventana()
			await _asentar()
		var ll := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var pr := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		r.append({"p": p, "ll": ll, "pr": pr, "mont": v.cargador.montados.size(), "sec": v.cargador.actual,
			"ids": v.cargador.ids_montados()})
	var por_sec := {}
	for x in r:
		var s: String = x["sec"]
		if not por_sec.has(s):
			por_sec[s] = [0, 0, 0, 1 << 30, 0]
		por_sec[s][0] += 1
		por_sec[s][1] = maxi(por_sec[s][1], x["ll"])
		por_sec[s][2] = maxi(por_sec[s][2], x["pr"])
		por_sec[s][3] = mini(por_sec[s][3], x["ll"])
		por_sec[s][4] = maxi(por_sec[s][4], x["mont"])
	_nota("[%s] BARRIDO (sin tope, Kael colocado cada %.0f m de lo andable, con Lya y Garon): %d vistas en %.0f s%s" % [
		perfil, paso, r.size(), (Time.get_ticks_msec() - t0) / 1000.0,
		(" · %d vistas repetidas porque la ventana no dibujaba" % sin_dibujar) if sin_dibujar > 0 else ""])
	for s in P.ORDEN:
		if por_sec.has(s):
			var q: Array = por_sec[s]
			_nota("[%s]   %s: %d vistas · llamadas %d-%d · primitivas máx %d · montados máx %d" % [perfil, s, q[0], q[3], q[1], q[2], q[4]])
	var sobre_ll := r.filter(func(x): return int(x["ll"]) > 65)
	var sobre_pr := r.filter(func(x): return int(x["pr"]) > 160000)
	_nota("[%s]   vistas por encima del presupuesto del bajo: %d de %d con más de 65 llamadas · %d con más de 160 mil primitivas" % [
		perfil, sobre_ll.size(), r.size(), sobre_pr.size()])
	_sin_tope(false)
	return r


# Las 4 vistas con más llamadas separadas ≥ 20 m, y la de más primitivas si no está entre ellas.
func _mas_cargadas(r: Array) -> Array:
	var orden := r.duplicate()
	orden.sort_custom(func(a, b): return int(a["ll"]) > int(b["ll"]) or (int(a["ll"]) == int(b["ll"]) and int(a["pr"]) > int(b["pr"])))
	var elegidas: Array = []
	for x in orden:
		if elegidas.size() >= 4:
			break
		if elegidas.all(func(e): return _plana(e["p"], x["p"]) >= 20.0):
			elegidas.append(x)
	var por_pr := r.duplicate()
	por_pr.sort_custom(func(a, b): return int(a["pr"]) > int(b["pr"]))
	if not por_pr.is_empty() and elegidas.all(func(e): return _plana(e["p"], por_pr[0]["p"]) >= 20.0):
		elegidas.append(por_pr[0])
	return elegidas


func _medir_punto(nombre: String, p: Vector3) -> void:
	await _ventana()
	_colocar(p)
	await _asentar(3.0)
	await _esperar(1.0)
	mu.muestras.clear()
	mu.grabando = true
	await _esperar(3.0)
	mu.grabando = false
	var con: Array = mu.muestras.duplicate()
	_sin_tope(true)
	await _frames(20)
	mu.muestras.clear()
	mu.grabando = true
	await _esperar(3.0)
	mu.grabando = false
	var sin: Array = mu.muestras.duplicate()
	_sin_tope(false)
	_nota("[%s] %s · %s · %s · %d montados %s · aclarados %d" % [perfil, nombre, _txt(_kael()), _donde(_kael()),
		v.cargador.montados.size(), str(v.cargador.ids_montados()), v.aclarados])
	_nota("[%s]   con tope (%d FPS): real %s ms · SIN tope ni vsync: real %s ms · proceso %s ms · dibujo CPU mediana %.2f ms · GPU %s ms" % [
		perfil, int(v.perfil.get("fps", 30)), _txt_est(con, "real"), _txt_est(sin, "real", false, 2), _txt_est(sin, "proc", false, 2),
		_est(sin, "cpu")["med"], _txt_est(sin, "gpu", true, 2)])
	_nota("[%s]   llamadas %d (máx %d; visibles %d, sombras %d, 2D %d) · primitivas %d (máx %d)%s" % [perfil, _est(sin, "ll")["med"],
		_est(sin, "ll")["max"], _est(sin, "llv")["med"], _est(sin, "lls")["med"], _est(sin, "llc")["med"], _est(sin, "pr")["med"],
		_est(sin, "pr")["max"], _sin_dibujar(con) + _sin_dibujar(sin)])


# EXPERIMENTO (solo medida; el juego no cambia): en una vista, las llamadas y primitivas de lo que hay, y sin cada cosa
# (ocultando nodos un momento): los rótulos (Label3D), las mallas de los sectores montados (desde la optimización del
# 16/11, «Blockout» con los ocultables fundidos y «Aclarados»; antes, una malla por ocultable), la maqueta lejana, el grupo
# (Lya y Garon) y la interfaz 2D.
func _llamadas() -> Array:
	await _frames(4)
	return [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)]


func _experimento(nombre: String, p: Vector3) -> void:
	_colocar(p)
	await _asentar(3.0)
	await _esperar(0.5)
	var base: Array = await _llamadas()
	var partes := {"rótulos": [], "mallas de los sectores": [], "lejana": [], "grupo": [], "interfaz 2D": []}
	for id in v.cargador.montados:
		var s: Node = v.cargador.montados[id]
		partes["rótulos"].append_array(s.find_children("*", "Label3D", true, false))
		partes["mallas de los sectores"].append_array(s.find_children("*", "MeshInstance3D", false, false))
	for id in v.cargador.lejanas:
		if (v.cargador.lejanas[id] as Node3D).visible:
			partes["lejana"].append(v.cargador.lejanas[id])
	if v.grupo != null:
		partes["grupo"].append(v.grupo)
	partes["interfaz 2D"].append(v.capa_ui)
	var txt: PackedStringArray = []
	for k in partes:
		var nodos: Array = partes[k]
		var antes: Array = nodos.map(func(n): return n.visible)
		for n in nodos:
			n.visible = false
		var r: Array = await _llamadas()
		for i in nodos.size():
			nodos[i].visible = antes[i]
		txt.append("sin %s (%d nodos): %d llamadas (−%d), %d primitivas (−%d)" % [k, nodos.size(), r[0], base[0] - r[0], r[1], base[1] - r[1]])
	_nota("[%s] EXPERIMENTO %s · %s · %d montados %s · %d llamadas, %d primitivas · %s" % [perfil, nombre, _txt(_kael()),
		v.cargador.montados.size(), str(v.cargador.ids_montados()), base[0], base[1], " · ".join(txt)])


# ================================================================= coste de cada sector

func _coste_sectores() -> void:
	var tot_ll := 0
	for id in P.ORDEN:
		var ps: PackedScene = load("res://zonas3d/ciudad/sectores/%s/sector.tscn" % id)
		var t0 := Time.get_ticks_usec()
		var s: Node3D = ps.instantiate()
		s.construir()
		var t1 := (Time.get_ticks_usec() - t0) / 1000.0
		var t_datos := -1.0                         # (16/11, optimización) lo que el cargador hace en un hilo…
		var t_nodos := -1.0                         # … y lo que queda en el fotograma del montaje (fuera del árbol)
		if s.has_method("preparar_datos"):
			var ta := Time.get_ticks_usec()
			var d: Dictionary = s.preparar_datos(id)
			t_datos = (Time.get_ticks_usec() - ta) / 1000.0
			var s2: Node3D = ps.instantiate()
			s2.datos = d
			ta = Time.get_ticks_usec()
			s2.construir()
			t_nodos = (Time.get_ticks_usec() - ta) / 1000.0
			s2.free()
		var mallas := 0
		var sup := 0
		var tri := 0
		for mi in s.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).mesh
			mallas += 1
			sup += m.get_surface_count()
			for i in m.get_surface_count():
				var n: int = m.surface_get_array_index_len(i)
				tri += (n if n > 0 else m.surface_get_array_len(i)) / 3
		var rot := s.find_children("*", "Label3D", true, false).size()
		_nota("[%s] sector %s: construir() fuera del árbol %.1f ms (preparar_datos, en hilo en el juego: %.1f ms · solo los nodos: %.1f ms) · %d mallas (%d ocultables) · %d superficies · %d triángulos · %d rótulos · %d choques" % [
			perfil, id, t1, t_datos, t_nodos, mallas, s.ocultables.size(), sup, tri, rot, s.choques])
		tot_ll += sup + rot
		s.free()
	var tri_l := 0
	for id in v.cargador.lejanas:
		var m: Mesh = (v.cargador.lejanas[id] as MeshInstance3D).mesh
		for i in m.get_surface_count():
			var n: int = m.surface_get_array_index_len(i)
			tri_l += (n if n > 0 else m.surface_get_array_len(i)) / 3
	_nota("[%s] maqueta lejana: %d mallas, %d triángulos en total · superficies + rótulos de los 8 sectores montados a la vez: %d" % [
		perfil, v.cargador.lejanas.size(), tri_l, tot_ll])


# ================================================================= todo

func _medir() -> void:
	ini = Marca.new()
	ini.name = "MedirInicio"
	ini.process_priority = -1000000
	ini.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(ini)
	mu = Muestreo.new()
	mu.name = "MedirFin"
	mu.process_priority = 1000000
	mu.process_mode = Node.PROCESS_MODE_ALWAYS
	mu.inicio = ini
	mu.vp = root.get_viewport_rid()
	root.add_child(mu)
	RenderingServer.viewport_set_measure_render_time(mu.vp, true)
	await _frames(3)
	var pf: Dictionary = load("res://prototipos/calidad_proto.gd").datos()
	var dib := root.get_visible_rect().size
	_nota("PC: %s · %s · %s · %d hilos · ventana %s · zona de dibujo %s (16:9, franjas a los lados) · renderizador %s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), OS.get_processor_name(),
		OS.get_processor_count(), str(DisplayServer.window_get_size()), str(dib), ProjectSettings.get_setting("rendering/renderer/rendering_method")])
	_nota("PERFIL %s · escala 3D %.2f FIJA (perfil fijado con calidad_proto: el regulador NO actúa) → 3D a %d×%d · MSAA %s · sombras %s (%.0f m) · tope %d FPS · fecha %s" % [
		perfil, float(pf["escala_3d"]), int(dib.x * float(pf["escala_3d"])), int(dib.y * float(pf["escala_3d"])),
		"2×" if int(pf["msaa"]) == 2 else "no", "sí" if pf["sombras"] else "no", float(pf["dist_sombras"]), int(pf["fps"]),
		Time.get_datetime_string_from_system()])
	_preparar_rejilla()
	change_scene_to_file(BANCO)
	await _esperar_banco()
	if not await _entrar("en frío (la primera del proceso)"):
		_terminar()
		return
	if await _volver_al_banco():
		if not await _entrar("en caliente (tras «Volver al banco»)"):
			_terminar()
			return
	_nota("[%s] escala real del viewport: %.2f · MSAA %d · tope %d FPS" % [perfil, root.scaling_3d_scale, root.msaa_3d, v.perfil_fps])
	if con_recorrido:
		await _recorrido()
	if solo_recorrido:
		_terminar()
		return
	var r: Array = await _barrido()
	var mas: Array = _mas_cargadas(r)
	if experimento:
		var k := 0
		for x in mas:
			k += 1
			await _experimento("VISTA CARGADA %d" % k, x["p"])
		_terminar()
		return
	for id in P.ORDEN:
		await _medir_punto("REFERENCIA %s" % id, P.ancla(P.SECTORES[id]["ref"]))
	var n := 0
	for x in mas:
		n += 1
		await _medir_punto("VISTA CARGADA %d (barrido: %d llamadas, %d primitivas)" % [n, x["ll"], x["pr"]], x["p"])
	_coste_sectores()
	_nota("[%s] al final: %s" % [perfil, _mem()])
	_terminar()


func _terminar() -> void:
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var nombre := "medidas_ciudad_%s%s.txt" % [perfil, ("_escala%d" % int(round(escala * 100))) if escala > 0.0 else ""]
		var f := FileAccess.open(salida.path_join(nombre), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
