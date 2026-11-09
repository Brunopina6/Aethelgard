extends SceneTree
# Generador SIN CONEXIÓN del mapamundi pintado (T-085). No se ejecuta en el juego: produce imágenes que el juego
# solo carga. Necesita ventana (pinta con la GPU en un SubViewport) y no toca user:// ni la partida.
#   Godot --path aethelgard --script res://mapa_arte/generar_mapa.gd -- [cache=<carpeta>] [salida=<carpeta>]
# Por defecto escribe en res://mapa_arte/:
#   mapa_mundo.webp    el mapa pintado (2400×1350, 1 px = 1 px del mundo): agua, costa, relieve, biomas, ríos,
#                      caminos y árboles. Sin rótulos ni iconos de lugares (se dibujan en vivo, encima).
#   agua_datos.png     datos para el sombreado animado del agua (1200×675): R = hondura, G = cercanía a la costa.
#   costa_datos.png    el campo continuo de tierra en 8 bits (1200×675) para la prueba de coincidencia.
# Todo sale de los datos de mapa.gd (datos_mapa.gd): misma tierra, mismas zonas, mismos lugares y rutas.

const DATOS := "res://mapa_arte/datos_mapa.gd"
const SOMBREADO := "res://mapa_arte/hornear_mapa.gdshader"
const PASO := 2
const LUZ := Vector3(-1.0, -1.15, 1.25)

var D
var W := 0
var H := 0
var v := PackedFloat32Array()
var zona := PackedByteArray()
var sdf := PackedFloat32Array()
var altura := PackedFloat32Array()
var cavidad := PackedFloat32Array()
var pesos: Array = []                 # 7 PackedFloat32Array, en el orden de datos_mapa.ZONAS_ORDEN
var caminos: Array = []               # PackedVector2Array por ruta (RUTAS de mapa.gd), en px del mundo
var rios: Array = []                  # PackedVector2Array por río
var arboles: Array = []               # [pos, tipo, escala, color]
var garganta: PackedVector2Array      # eje del desfiladero
var montes := {}                      # texturas de los picos: {"monte": [...], "monte_nevado": [...]}
var salida := "res://mapa_arte/"
var cache := ""
var t0 := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("cache="):
			cache = a.substr(6)
		elif a.begins_with("salida="):
			salida = a.substr(7)
	if not salida.ends_with("/"):
		salida += "/"
	DisplayServer.window_set_size(Vector2i(640, 360))
	_generar.call_deferred()


func _log(t: String) -> void:
	print("INFO [%5.1f s] %s" % [(Time.get_ticks_msec() - t0) / 1000.0, t])


func _generar() -> void:
	t0 = Time.get_ticks_msec()
	D = load(DATOS).new()
	_mascara_juego()
	_campos()
	_distancias()
	_lagos()
	_pesos_zonas()
	_trazar_garganta()
	_alturas()
	_trazar_caminos()
	_trazar_rios()
	_plantar()
	await _hornear()
	_log("hecho")
	quit(0)


# ------------------------------------------------------------------ campos (con caché opcional)

# La máscara de tierra y zonas del juego, tal cual la genera mapa.gd (_generar_terreno), en un PNG sin pérdida:
# con ella el mapa nuevo no tendría que generarla al cargar (la prueba comprueba que es idéntica, píxel a píxel).
func _mascara_juego() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(salida))
	var m = D.MAPA.new()
	m._generar_terreno()
	var img: Image = m.zonas_img
	img.save_png(salida + "mapa_zonas.png")
	m.free()
	_log("máscara del juego guardada (mapa_zonas.png, %dx%d, sin pérdida)" % [img.get_width(), img.get_height()])


func _firma() -> String:
	return str(D.lugares) + str(D.rutas) + str(D.islas) + str(D.zona_lugar) + str(D.ancho) + str(PASO) + str(D.desfase()) + "v3"


func _campos() -> void:
	var ruta := cache.path_join("campos_mapa.bin") if cache != "" else ""
	if ruta != "" and FileAccess.file_exists(ruta):
		var f := FileAccess.open(ruta, FileAccess.READ)
		var d: Dictionary = f.get_var()
		if d.get("firma", "") == _firma():
			W = d["w"]
			H = d["h"]
			v = d["v"]
			zona = d["zona"]
			_log("campos de la caché (%dx%d)" % [W, H])
			return
	var c: Dictionary = D.calcular(PASO)
	W = c["w"]
	H = c["h"]
	v = c["v"]
	zona = c["zona"]
	_log("campos calculados (%dx%d)" % [W, H])
	if ruta != "":
		DirAccess.make_dir_recursive_absolute(cache)
		var f := FileAccess.open(ruta, FileAccess.WRITE)
		f.store_var({"firma": _firma(), "w": W, "h": H, "v": v, "zona": zona})


func _distancias() -> void:
	var tierra := PackedByteArray()
	var mar := PackedByteArray()
	tierra.resize(W * H)
	mar.resize(W * H)
	for i in W * H:
		var t := v[i] >= 0.0
		tierra[i] = 1 if t else 0
		mar[i] = 0 if t else 1
	var a_mar: PackedFloat32Array = D.distancia(mar, W, H)
	var a_tierra: PackedFloat32Array = D.distancia(tierra, W, H)
	sdf.resize(W * H)
	for i in W * H:
		sdf[i] = (a_mar[i] - 0.5) * PASO if tierra[i] == 1 else -(a_tierra[i] - 0.5) * PASO
	_log("distancias a la costa")


# Lagos: el agua que no está unida al océano (relleno desde el borde del mapa). En la ceniza son de lava.
var lago := PackedFloat32Array()


func _lagos() -> void:
	var oceano := PackedByteArray()
	oceano.resize(W * H)
	var cola := PackedInt32Array()
	for x in W:
		for y in [0, H - 1]:
			var i: int = y * W + x
			if v[i] < 0.0 and oceano[i] == 0:
				oceano[i] = 1
				cola.append(i)
	for y in H:
		for x in [0, W - 1]:
			var i: int = y * W + x
			if v[i] < 0.0 and oceano[i] == 0:
				oceano[i] = 1
				cola.append(i)
	var k := 0
	while k < cola.size():
		var i := cola[k]
		k += 1
		var x := i % W
		var y := i / W
		for vec in [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]:
			var nx: int = vec[0]
			var ny: int = vec[1]
			if nx < 0 or ny < 0 or nx >= W or ny >= H:
				continue
			var j := ny * W + nx
			if oceano[j] == 0 and v[j] < 0.0:
				oceano[j] = 1
				cola.append(j)
	lago.resize(W * H)
	var n := 0
	for i in W * H:
		lago[i] = 1.0 if (v[i] < 0.0 and oceano[i] == 0) else 0.0
		if lago[i] > 0.0:
			n += 1
	lago = D.desenfocar(lago, W, H, 2, 1)
	_log("lagos interiores: %d celdas de 2 px" % n)


func _pesos_zonas() -> void:
	pesos.clear()
	for z in D.ZONAS_ORDEN.size():
		var a := PackedFloat32Array()
		a.resize(W * H)
		for i in W * H:
			a[i] = 1.0 if zona[i] == z else 0.0
		pesos.append(D.desenfocar(a, W, H, 3, 2))
	_log("pesos de las zonas (transiciones suaves de ~26 px centradas en el borde del juego)")


func _celda(p: Vector2) -> int:
	var x := clampi(int(p.x / PASO), 0, W - 1)
	var y := clampi(int(p.y / PASO), 0, H - 1)
	return y * W + x


func _peso(z: String, p: Vector2) -> float:
	return pesos[D.ZONAS_ORDEN.find(z)][_celda(p)]


func _v(p: Vector2) -> float:
	return v[_celda(p)]


func _sdf(p: Vector2) -> float:
	return sdf[_celda(p)]


static func _dist_polilinea(p: Vector2, l: PackedVector2Array) -> float:
	var d := 1e9
	for i in l.size() - 1:
		d = minf(d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, l[i], l[i + 1])))
	return d


# Distancia (px del mundo) de cada celda a la línea más cercana de `lineas` (transformada exacta: rápida).
func _campo_distancia(lineas: Array) -> PackedFloat32Array:
	var marca := PackedByteArray()
	marca.resize(W * H)
	for l in lineas:
		for i in l.size() - 1:
			var a: Vector2 = l[i]
			var b: Vector2 = l[i + 1]
			var n := int(ceil(a.distance_to(b))) + 1
			for k in n + 1:
				marca[_celda(a.lerp(b, float(k) / n))] = 1
	var d: PackedFloat32Array = D.distancia(marca, W, H)
	for i in W * H:
		d[i] *= PASO
	return d


# ------------------------------------------------------------------ relieve

# El desfiladero de la Garganta del Diablo: un tajo sinuoso de oeste a este que cruza el lugar (los puentes
# colgantes van en su icono).
func _trazar_garganta() -> void:
	var c: Vector2 = D.lugares[2]["pos"]
	garganta = PackedVector2Array()
	var n := FastNoiseLite.new()
	n.seed = 55
	n.frequency = 0.02
	for i in 41:
		var t := -1.0 + 2.0 * i / 40.0
		var p := c + Vector2(t * 190.0, t * 38.0 + 18.0 * sin(t * 4.2))
		p.y += n.get_noise_1d(t * 50.0) * 10.0 * absf(t)
		garganta.append(p)


func _alturas() -> void:
	var n_col := FastNoiseLite.new()
	n_col.seed = 101
	n_col.frequency = 0.011
	n_col.fractal_octaves = 4
	var n_cre := FastNoiseLite.new()
	n_cre.seed = 202
	n_cre.frequency = 0.0042
	n_cre.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n_cre.fractal_octaves = 4
	var n_dun := FastNoiseLite.new()
	n_dun.seed = 303
	n_dun.frequency = 0.004
	n_dun.fractal_octaves = 2
	var n_mes := FastNoiseLite.new()
	n_mes.seed = 404
	n_mes.frequency = 0.009
	n_mes.fractal_octaves = 3
	var cumbres: Vector2 = D.lugares[3]["pos"]
	var abismo: Vector2 = D.lugares[8]["pos"]
	var gar: Vector2 = D.lugares[2]["pos"]
	var dir_duna := Vector2(1.0, 0.35).normalized()
	var dist_tajo := _campo_distancia([garganta])
	altura.resize(W * H)
	var iz: Dictionary = {}
	for k in D.ZONAS_ORDEN:
		iz[k] = D.ZONAS_ORDEN.find(k)
	# para el relieve, transiciones más largas entre zonas (~80 px): sin escalones ni sombras rectas en los bordes
	var ph: Array = []
	for z in pesos.size():
		ph.append(D.desenfocar(pesos[z], W, H, 9, 2))
	for y in H:
		for x in W:
			var i := y * W + x
			var s := sdf[i]
			if s <= 0.0:
				altura[i] = 0.0
				continue
			var p := Vector2(x * PASO + 1, y * PASO + 1)
			var sube := smoothstep(0.0, 90.0, s)
			var bajo := smoothstep(0.0, 26.0, s)
			var col := n_col.get_noise_2d(p.x, p.y) * 0.5 + 0.5
			var r := clampf(n_cre.get_noise_2d(p.x, p.y) * 0.5 + 0.5, 0.0, 1.0)
			r = pow(r, 2.0)
			var wb: float = ph[iz["bosque"]][i]
			var wl: float = ph[iz["llanura"]][i]
			var wm: float = ph[iz["montana"]][i]
			var wn: float = ph[iz["nieve"]][i]
			var wd: float = ph[iz["desierto"]][i]
			var wy: float = ph[iz["yermo"]][i]
			var wc: float = ph[iz["ceniza"]][i]
			var h := 0.0
			h += wl * (0.06 + 0.10 * col)
			h += wb * (0.08 + 0.14 * col)
			if wm > 0.001:
				h += wm * (0.12 + 0.95 * pow(r, 1.25) * sube + 0.06 * col)
			if wn > 0.001:
				var macizo := exp(-p.distance_squared_to(cumbres) / (2.0 * 190.0 * 190.0))
				h += wn * (0.16 + 0.70 * r * sube + 0.34 * macizo * sube)
			if wd > 0.001:
				# dunas en media luna: ladera suave al viento y cara empinada a sotavento
				var giro := n_dun.get_noise_2d(p.x, p.y) * 0.9 + n_col.get_noise_2d(p.x * 2.0, p.y * 2.0) * 0.25
				var s_duna := fposmod(p.dot(dir_duna) / 34.0 + giro, 1.0)
				var duna := s_duna / 0.78 if s_duna < 0.78 else (1.0 - s_duna) / 0.22
				h += wd * (0.05 + 0.04 * col + 0.028 * duna * smoothstep(0.3, 0.6, col + 0.25))
			if wy > 0.001:
				var t := (n_mes.get_noise_2d(p.x, p.y) * 0.5 + 0.5) * 3.0
				var terraza: float = (floor(t) + smoothstep(0.15, 0.85, fposmod(t, 1.0))) / 3.0
				h += wy * (0.08 + 0.07 * terraza + 0.06 * col)
			if wc > 0.001:
				var dc := p.distance_to(abismo)
				var caldera := exp(-pow((dc - 62.0) / 30.0, 2.0)) * 0.30
				h += wc * (0.10 + 0.22 * r * sube + caldera)
			# el tajo de la Garganta
			var dg := p.distance_to(gar)
			if dg < 260.0:
				var dl := dist_tajo[i]
				h -= 0.55 * exp(-pow(dl / 11.0, 2.0)) * (1.0 - smoothstep(150.0, 230.0, dg))
				h += 0.12 * exp(-pow(dl / 34.0, 2.0)) * (1.0 - smoothstep(150.0, 230.0, dg))   # bordes altos
			altura[i] = h * bajo
	var suave: PackedFloat32Array = D.desenfocar(altura, W, H, 6, 2)
	cavidad.resize(W * H)
	for i in W * H:
		cavidad[i] = altura[i] - suave[i]
	_log("alturas (colinas, cordilleras, macizo de Ciclópea, dunas, mesetas, caldera y el tajo de la Garganta)")


# ------------------------------------------------------------------ caminos y ríos

# Cada ruta de mapa.gd (RUTAS) es un camino que serpentea un poco entre sus dos lugares, siempre por tierra.
func _trazar_caminos() -> void:
	var n := FastNoiseLite.new()
	n.seed = 77
	n.frequency = 0.012
	n.fractal_octaves = 2
	caminos.clear()
	var k := 0
	for r in D.rutas:
		var a: Vector2 = D.lugares[r[0]]["pos"]
		var b: Vector2 = D.lugares[r[1]]["pos"]
		var largo := a.distance_to(b)
		var normal := (b - a).normalized().orthogonal()
		var amp := 24.0
		var l := PackedVector2Array()
		for intento in 6:
			l = PackedVector2Array()
			var ok := true
			var pasos := int(largo / 5.0)
			for i in pasos + 1:
				var t := float(i) / pasos
				var p := a.lerp(b, t) + normal * n.get_noise_1d(t * largo + k * 1000.0) * amp * sin(PI * t)
				if t > 0.08 and t < 0.92 and _v(p) < 0.12:
					ok = false
				l.append(p)
			if ok:
				break
			amp *= 0.6
		caminos.append(l)
		k += 1
	_log("caminos: %d (uno por ruta de mapa.gd)" % caminos.size())


# Ríos: bajan desde las montañas hacia la costa más cercana (siguiendo la distancia a la costa) y serpentean.
func _trazar_rios() -> void:
	var fuentes := [Vector2(1180, 330), Vector2(1395, 300), Vector2(905, 600), Vector2(1110, 470)]
	var n := FastNoiseLite.new()
	n.seed = 91
	n.frequency = 0.03
	rios.clear()
	for f in fuentes:
		if _sdf(f) < 40.0:
			continue
		var l := PackedVector2Array([f])
		var p: Vector2 = f
		var dir := Vector2.ZERO
		for i in 400:
			var e := 4.0
			var g := Vector2(_sdf(p + Vector2(e, 0)) - _sdf(p - Vector2(e, 0)), _sdf(p + Vector2(0, e)) - _sdf(p - Vector2(0, e)))
			if g.length() < 0.001:
				break
			var baja := -g.normalized()
			dir = (dir * 0.7 + baja * 0.3).normalized() if dir != Vector2.ZERO else baja
			var giro := n.get_noise_2d(p.x, p.y + i) * 0.9
			p += dir.rotated(giro) * 3.0
			l.append(p)
			if _sdf(p) < -2.0:
				break
		var cerca_lugar := false
		for lg in D.lugares + [D.MAPA.LUGAR_PASTOS]:
			if _dist_polilinea(lg["pos"], l) < 48.0:
				cerca_lugar = true
		if not cerca_lugar and l.size() > 10:
			rios.append(l)
	_log("ríos: %d" % rios.size())


# ------------------------------------------------------------------ árboles y adornos

func _plantar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var n := FastNoiseLite.new()
	n.seed = 12
	n.frequency = 0.02
	arboles.clear()
	var d_camino := _campo_distancia(caminos)
	var d_rio := _campo_distancia(rios)
	var d_tajo := _campo_distancia([garganta])
	var lugares_todos: Array = D.lugares + [D.MAPA.LUGAR_PASTOS]
	var celda := 8.0
	for gy in int(D.tam.y / celda):
		for gx in int(D.tam.x / celda):
			var p := Vector2((gx + rng.randf()) * celda, (gy + rng.randf()) * celda)
			var s := _sdf(p)
			if s < 7.0:
				continue
			var lejos := true
			for lg in lugares_todos:
				var r_libre := 40.0 if lg["tipo"] == "lugar" else 58.0
				if p.distance_to(lg["pos"]) < r_libre:
					lejos = false
					break
			if not lejos:
				continue
			var i := _celda(p)
			if d_camino[i] < 10.0 or d_rio[i] < 7.0 or d_tajo[i] < 18.0:
				continue
			var h := altura[i]
			var grupo := n.get_noise_2d(p.x, p.y) * 0.5 + 0.5
			var wb: float = _peso("bosque", p)
			var wl: float = _peso("llanura", p)
			var wm: float = _peso("montana", p)
			var wn: float = _peso("nieve", p)
			var wd: float = _peso("desierto", p)
			var wy: float = _peso("yermo", p)
			var wc: float = _peso("ceniza", p)
			var tir := rng.randf()
			if wb > 0.45 and tir < 0.92 * smoothstep(0.45, 0.7, wb):
				var tono := Color(0.24, 0.58, 0.27).lerp(Color(0.36, 0.68, 0.30), rng.randf()).lerp(Color(0.18, 0.47, 0.30), grupo * 0.5)
				arboles.append([p, "copa", rng.randf_range(0.9, 1.25), tono])
			elif wl > 0.5 and tir < 0.16 * smoothstep(0.62, 0.85, grupo):
				var tono := Color(0.34, 0.64, 0.28).lerp(Color(0.46, 0.72, 0.30), rng.randf())
				arboles.append([p, "copa", rng.randf_range(0.75, 1.0), tono])
			elif wm > 0.5 and h < 0.42 and tir < 0.18 * (1.0 - smoothstep(0.25, 0.42, h)) * smoothstep(0.35, 0.65, grupo):
				arboles.append([p, "pino", rng.randf_range(0.8, 1.05), Color(0.20, 0.45, 0.33).lerp(Color(0.26, 0.52, 0.36), rng.randf())])
			elif wn > 0.5 and h < 0.5 and tir < 0.16 * (1.0 - smoothstep(0.35, 0.5, h)) * smoothstep(0.4, 0.7, grupo):
				arboles.append([p, "pino_nevado", rng.randf_range(0.8, 1.0), Color(0.22, 0.42, 0.40)])
			elif wy > 0.6 and tir < 0.025:
				arboles.append([p, "cristal", rng.randf_range(0.8, 1.2), Color(0.80, 0.70, 1.0)])
			elif wc > 0.6 and tir < 0.05:
				arboles.append([p, "seco", rng.randf_range(0.8, 1.1), Color(0.16, 0.13, 0.15)])
			elif wd > 0.7 and tir < 0.004:
				arboles.append([p, "roca", rng.randf_range(0.8, 1.3), Color(0.80, 0.62, 0.42)])
	# los espejos de agua del Valle de los Ecos (decorado: charcas pequeñas que reflejan estrellas)
	var valle: Vector2 = D.lugares[6]["pos"]
	var puestos := 0
	for intento in 400:
		if puestos >= 9:
			break
		var a := rng.randf() * TAU
		var p := valle + Vector2(cos(a), sin(a) * 0.8) * rng.randf_range(70.0, 175.0)
		var i := _celda(p)
		if _sdf(p) < 16.0 or d_camino[i] < 14.0 or _peso("yermo", p) < 0.7:
			continue
		var libre := true
		for o in arboles:
			if o[1] == "espejo" and o[0].distance_to(p) < 38.0:
				libre = false
				break
		if libre:
			arboles.append([p, "espejo", rng.randf_range(0.7, 1.1), Color(1, 1, 1), rng.randf() * TAU])
			puestos += 1
	_cumbres(lugares_todos, d_camino, d_rio, d_tajo)
	arboles.sort_custom(func(a, b): return a[0].y < b[0].y)
	_log("árboles y adornos: %d" % arboles.size())


# Picos dibujados (2,5D) en las cimas del relieve de montaña y nieve: el máximo de cada casilla de 28 px, sin
# picos a menos de 26 px de otro más alto, lejos de lugares, caminos, ríos y del tajo de la Garganta.
func _cumbres(lugares_todos: Array, d_camino: PackedFloat32Array, d_rio: PackedFloat32Array, d_tajo: PackedFloat32Array) -> void:
	var cand := []
	var lado := 14                                   # casilla de 14 celdas = 28 px
	for cy in range(0, H, lado):
		for cx in range(0, W, lado):
			var mejor := -1
			var hm := 0.0
			for y in range(cy, mini(cy + lado, H)):
				for x in range(cx, mini(cx + lado, W)):
					var i := y * W + x
					if altura[i] > hm:
						hm = altura[i]
						mejor = i
			if mejor < 0 or hm < 0.40:
				continue
			var p := Vector2((mejor % W) * PASO + 1, (mejor / W) * PASO + 1)
			if _peso("montana", p) + _peso("nieve", p) < 0.6 or sdf[mejor] < 22.0:
				continue
			var lejos := true
			for lg in lugares_todos:
				if p.distance_to(lg["pos"]) < 70.0:
					lejos = false
					break
			if lejos:
				cand.append([p, hm])
	cand.sort_custom(func(a, b): return a[1] > b[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var puestos := []
	for c in cand:
		var libre := true
		for q in puestos:
			if c[0].distance_to(q[0]) < 38.0:
				libre = false
				break
		if not libre:
			continue
		# la silueta del pico (no solo su cima) no tapa caminos, ríos, el tajo ni la costa
		var esc := clampf(0.55 + (c[1] - 0.4) * 1.0 + rng.randf_range(-0.08, 0.08), 0.55, 1.1)
		var base: Vector2 = c[0] + Vector2(0, 14) * esc
		var ok := true
		for f in [Vector2(-0.42, 0.0), Vector2(0.0, 0.0), Vector2(0.42, 0.0), Vector2(-0.22, -0.4), Vector2(0.22, -0.4), Vector2(0.0, -0.8)]:
			var q: Vector2 = base + Vector2(f.x * 96.0, f.y * 80.0) * esc
			var i := _celda(q)
			if d_camino[i] < 9.0 or d_rio[i] < 7.0 or d_tajo[i] < 22.0 or sdf[i] < 10.0:
				ok = false
				break
		if ok:
			puestos.append([c[0], c[1], esc, base])
	for c in puestos:
		var p: Vector2 = c[0]
		var tipo := "monte"
		if _peso("nieve", p) > 0.5:
			tipo = "monte_helado"
		elif c[1] > 0.74:
			tipo = "monte_nevado"
		arboles.append([c[3], tipo, c[2], Color(1, 1, 1)])
	_log("picos: %d" % puestos.size())


# Texturas de los adornos, dibujadas por código (gris con alfa; el color va en modulate). Lado 64 px.
func _tex_copa(semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var bultos := []
	for k in rng.randi_range(3, 5):
		var a := rng.randf() * TAU
		var dd := rng.randf_range(0.0, 7.0)
		bultos.append([Vector2(32, 32) + Vector2(cos(a), sin(a)) * dd, rng.randf_range(13.0, 17.0)])
	bultos.append([Vector2(32, 32), 18.0])
	var L := LUZ.normalized()
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var q := Vector2(x + 0.5, y + 0.5)
			var mejor := -1e9
			var nrm := Vector3(0, 0, 1)
			var cob := 0.0
			for b in bultos:
				var d: float = q.distance_to(b[0])
				var r: float = b[1]
				cob = maxf(cob, clampf(r - d + 0.5, 0.0, 1.0))
				if d < r:
					var z := sqrt(r * r - d * d)
					if z + r * 0.3 > mejor:
						mejor = z + r * 0.3
						nrm = Vector3((q.x - b[0].x) / r, (q.y - b[0].y) / r, z / r).normalized()
			if cob <= 0.0:
				continue
			var lam := clampf(nrm.dot(L), 0.0, 1.0)
			var g := 0.50 + 0.55 * lam
			var borde := smoothstep(0.0, 0.35, nrm.z)
			g *= 0.78 + 0.22 * borde
			img.set_pixel(x, y, Color(g, g, g * 0.97, cob))
	return ImageTexture.create_from_image(img)


func _tex_pino(nevado: bool) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var L := LUZ.normalized()
	for y in 64:
		for x in 64:
			var q := Vector2(x + 0.5, y + 0.5) - Vector2(32, 32)
			var a := q.angle()
			var r := q.length()
			var borde := 13.0 + 3.5 * cos(a * 9.0)
			var cob := clampf(borde - r + 0.5, 0.0, 1.0)
			if cob <= 0.0:
				continue
			var z := 1.0 - r / borde
			var nrm := Vector3(q.x / borde, q.y / borde, 0.6 + z).normalized()
			var lam := clampf(nrm.dot(L), 0.0, 1.0)
			var g := 0.45 + 0.6 * lam
			var c := Color(g, g, g, cob)
			if nevado and lam > 0.55:
				c = Color(1.6, 1.65, 1.75, cob)          # nieve en las caras al sol (×modulate oscuro = blanco azulado)
			img.set_pixel(x, y, c.clamp())
	return ImageTexture.create_from_image(img)


func _tex_sombra() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var q := (Vector2(x + 0.5, y + 0.5) - Vector2(32, 32)) / Vector2(19, 15)
			var a := 1.0 - smoothstep(0.55, 1.0, q.length())
			img.set_pixel(x, y, Color(0.08, 0.12, 0.25, a * 0.55))
	return ImageTexture.create_from_image(img)


func _tex_cristal() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var picos := [[Vector2(32, 40), -90.0, 22.0], [Vector2(26, 42), -115.0, 14.0], [Vector2(38, 42), -65.0, 15.0]]
	for y in 64:
		for x in 64:
			var q := Vector2(x + 0.5, y + 0.5)
			for pk in picos:
				var dir := Vector2.from_angle(deg_to_rad(pk[1]))
				var rel: Vector2 = q - pk[0]
				var t := rel.dot(dir)
				var lado := absf(rel.dot(dir.orthogonal()))
				var ancho: float = 4.0 * (1.0 - t / pk[2])
				if t > 0.0 and t < pk[2] and lado < ancho:
					var g := 0.75 + 0.35 * signf(rel.dot(dir.orthogonal()))
					img.set_pixel(x, y, Color(g, g, g, clampf(ancho - lado, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _tex_seco() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var ramas := [[Vector2(32, 44), Vector2(32, 18)], [Vector2(32, 30), Vector2(22, 20)], [Vector2(32, 26), Vector2(41, 17)],
		[Vector2(32, 36), Vector2(42, 30)]]
	for y in 64:
		for x in 64:
			var q := Vector2(x + 0.5, y + 0.5)
			var cob := 0.0
			for r in ramas:
				var d := q.distance_to(Geometry2D.get_closest_point_to_segment(q, r[0], r[1]))
				cob = maxf(cob, clampf(1.6 - d, 0.0, 1.0))
			if cob > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, cob))
	return ImageTexture.create_from_image(img)


func _tex_roca() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var L := LUZ.normalized()
	for y in 64:
		for x in 64:
			var q := (Vector2(x + 0.5, y + 0.5) - Vector2(32, 34)) / Vector2(12, 8)
			var r := q.length()
			if r > 1.05:
				continue
			var nrm := Vector3(q.x, q.y, sqrt(maxf(0.0, 1.0 - minf(r * r, 1.0)))).normalized()
			var g := 0.55 + 0.5 * clampf(nrm.dot(L), 0.0, 1.0)
			img.set_pixel(x, y, Color(g, g, g, clampf((1.05 - r) * 10.0, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ dibujos fuera de pantalla (picos e iconos)

# Dibuja con `dibujo(nodo)` (coordenadas de 1×) en un SubViewport transparente a 4×, lo reduce a `tam` con
# promedios de 2×2 (dos veces) y quita el premultiplicado del alfa. Bordes limpios sin depender del suavizado.
func render_dibujo(tam: Vector2i, dibujo: Callable) -> Image:
	const ESC := 4
	var vp := SubViewport.new()
	vp.size = tam * ESC
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var n := Node2D.new()
	n.draw.connect(func():
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2(ESC, ESC))
		dibujo.call(n))
	vp.add_child(n)
	root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(tam.x * 2, tam.y * 2, Image.INTERPOLATE_BILINEAR)
	img.resize(tam.x, tam.y, Image.INTERPOLATE_BILINEAR)
	for y in tam.y:
		for x in tam.x:
			var c := img.get_pixel(x, y)
			if c.a > 0.003:
				img.set_pixel(x, y, Color(minf(c.r / c.a, 1.0), minf(c.g / c.a, 1.0), minf(c.b / c.a, 1.0), c.a))
	return img


static func _quebrar(a: Vector2, b: Vector2, rng: RandomNumberGenerator, n: int, amp: float) -> PackedVector2Array:
	var l := PackedVector2Array([a])
	var nrm := (b - a).orthogonal().normalized()
	for i in range(1, n):
		var t := float(i) / n
		l.append(a.lerp(b, t) + nrm * rng.randf_range(-amp, amp))
	l.append(b)
	return l


# Polígono con un color por vértice; si no se puede triangular (algún pico raro), usa su envolvente convexa.
static func _poligono(c: CanvasItem, pts: PackedVector2Array, colores: PackedColorArray) -> void:
	if Geometry2D.triangulate_polygon(pts).size() == 0:
		var env := Geometry2D.convex_hull(pts)
		env.remove_at(env.size() - 1)
		var cols := PackedColorArray()
		for q in env:
			cols.append(colores[0])
		c.draw_polygon(env, cols)
		return
	c.draw_polygon(pts, colores)


static func _degradado(pts: PackedVector2Array, arriba: Color, abajo: Color, y0: float, y1: float) -> PackedColorArray:
	var cols := PackedColorArray()
	for q in pts:
		cols.append(arriba.lerp(abajo, clampf((q.y - y0) / (y1 - y0), 0.0, 1.0)))
	return cols


# Un pico de 96×80 (base en y = 75): cara al sol cálida, cara en sombra azulada, arista central, cárcavas,
# degradado de la cima al pie y línea de tinta fina. tipo: "roca", "nevado" (cima blanca) o "helado" (todo nieve).
static func dibujar_monte(c: CanvasItem, semilla: int, tipo: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var nevado := tipo != "roca"
	var tinta := Color(0.20, 0.17, 0.23)
	var cima := Vector2(48 + rng.randf_range(-8, 8), 8 + rng.randf_range(0, 12))
	var izq := Vector2(4 + rng.randf_range(0, 9), 75)
	var der := Vector2(92 - rng.randf_range(0, 9), 75)
	var pie := Vector2(cima.x + rng.randf_range(5, 15), 75)
	var bi := _quebrar(izq, cima, rng, 6, 3.4)
	var bd := _quebrar(cima, der, rng, 6, 3.4)
	# hombro: a veces una cima menor a un lado
	if rng.randf() < 0.55:
		var k := 2 if rng.randf() < 0.5 else 3
		if rng.randf() < 0.5:
			bi[k] += Vector2(-3, -9)
		else:
			bd[bd.size() - 1 - k] += Vector2(3, -9)
	var ar := _quebrar(cima, pie, rng, 5, 2.6)
	var luz_a := Color(0.88, 0.82, 0.71)
	var luz_b := Color(0.60, 0.62, 0.47)
	var sombra_a := Color(0.58, 0.57, 0.71)
	var sombra_b := Color(0.38, 0.41, 0.46)
	if tipo == "helado":
		luz_a = Color(0.99, 0.99, 1.0)
		luz_b = Color(0.84, 0.88, 0.96)
		sombra_a = Color(0.78, 0.85, 0.98)
		sombra_b = Color(0.60, 0.67, 0.86)
	# sombra del pico en el suelo, hacia abajo a la derecha
	c.draw_colored_polygon(PackedVector2Array([pie + Vector2(-20, 0), der + Vector2(6, 0), der + Vector2(12, 4), pie + Vector2(-12, 5)]),
		Color(0.10, 0.12, 0.28, 0.20))
	var cara_i := PackedVector2Array(bi)
	for i in range(1, ar.size()):
		cara_i.append(ar[i])
	_poligono(c, cara_i, _degradado(cara_i, luz_a, luz_b, cima.y, 75.0))
	var cara_d := PackedVector2Array(bd)
	for i in range(ar.size() - 1, 0, -1):
		cara_d.append(ar[i])
	_poligono(c, cara_d, _degradado(cara_d, sombra_a, sombra_b, cima.y, 75.0))
	# cárcavas: trazos que bajan de la arista
	for k in 5:
		var a := ar[0].lerp(pie, rng.randf_range(0.25, 0.85))
		c.draw_line(a, a + Vector2(-rng.randf_range(8, 18), rng.randf_range(8, 16)), Color(luz_a.darkened(0.22), 0.7), 1.0)
		var b := ar[0].lerp(pie, rng.randf_range(0.25, 0.85))
		c.draw_line(b, b + Vector2(rng.randf_range(8, 18), rng.randf_range(8, 16)), Color(sombra_a.darkened(0.2), 0.7), 1.0)
	if tipo == "nevado":
		var f := rng.randf_range(0.38, 0.5)
		var pi_ := cima.lerp(izq, f)
		var pd := cima.lerp(der, f * 0.9)
		var pa := cima.lerp(pie, f * 0.8)
		var nieve_i := PackedVector2Array([cima])
		for i in range(bi.size() - 1, -1, -1):
			if bi[i].y <= pi_.y and i < bi.size() - 1:
				nieve_i.append(bi[i])
		nieve_i.append(pi_)
		nieve_i.append(pi_.lerp(pa, 0.33) + Vector2(0, 7))
		nieve_i.append(pi_.lerp(pa, 0.66) + Vector2(0, -2))
		nieve_i.append(pa)
		_poligono(c, nieve_i, _degradado(nieve_i, Color(1, 1, 1), Color(0.90, 0.93, 0.98), cima.y, pi_.y))
		var nieve_d := PackedVector2Array([cima, pa, pa.lerp(pd, 0.4) + Vector2(0, 6), pa.lerp(pd, 0.75) + Vector2(0, -1), pd])
		for i in range(bd.size() - 1, 0, -1):
			if bd[i].y < pd.y:
				nieve_d.append(bd[i])
		_poligono(c, nieve_d, _degradado(nieve_d, Color(0.80, 0.86, 0.98), Color(0.70, 0.78, 0.94), cima.y, pd.y))
	elif tipo == "helado":
		for k in 4:                                     # roca que asoma en la nieve
			var a := ar[0].lerp(pie, rng.randf_range(0.45, 0.9)) + Vector2(rng.randf_range(4, 12), 0)
			c.draw_line(a, a + Vector2(rng.randf_range(3, 8), rng.randf_range(5, 10)), Color(0.45, 0.45, 0.55, 0.65), 1.4)
	var contorno := PackedVector2Array(bi)
	for i in range(1, bd.size()):
		contorno.append(bd[i])
	c.draw_polyline(contorno, tinta, 1.4, true)
	c.draw_polyline(ar, Color(tinta, 0.45), 0.9, true)


# ------------------------------------------------------------------ horneado en la GPU

func _imagen_campos() -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBAH)
	for y in H:
		for x in W:
			var i := y * W + x
			img.set_pixel(x, y, Color(sdf[i], altura[i], v[i], cavidad[i]))
	return img


func _imagen_zonas(a: int, b: int, c: int, d: int) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var i := y * W + x
			img.set_pixel(x, y, Color(pesos[a][i] if a >= 0 else 0.0, pesos[b][i] if b >= 0 else 0.0,
				pesos[c][i] if c >= 0 else 0.0, pesos[d][i] if d >= 0 else lago[i]))
	return img


func _hornear() -> void:
	montes = {"monte": [], "monte_nevado": [], "monte_helado": []}
	var tipos := {"monte": "roca", "monte_nevado": "nevado", "monte_helado": "helado"}
	var hoja := Image.create(96 * 6, 240, false, Image.FORMAT_RGBA8)
	var fila := 0
	for clave in tipos:
		for s in 6:
			var img: Image = await render_dibujo(Vector2i(96, 80), func(c): dibujar_monte(c, 100 * (fila + 1) + s, tipos[clave]))
			montes[clave].append(ImageTexture.create_from_image(img))
			hoja.blit_rect(img, Rect2i(0, 0, 96, 80), Vector2i(96 * s, 80 * fila))
		fila += 1
	if cache != "":
		hoja.save_png(cache.path_join("picos.png"))
	_log("picos dibujados: 3 tipos × 6 variantes")

	var vp := SubViewport.new()
	vp.size = Vector2i(int(D.tam.x), int(D.tam.y))
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var mat := ShaderMaterial.new()
	mat.shader = load(SOMBREADO)
	mat.set_shader_parameter("campos", ImageTexture.create_from_image(_imagen_campos()))
	mat.set_shader_parameter("zonas_a", ImageTexture.create_from_image(_imagen_zonas(0, 1, 2, 3)))
	mat.set_shader_parameter("zonas_b", ImageTexture.create_from_image(_imagen_zonas(4, 5, 6, -1)))
	mat.set_shader_parameter("tam_mundo", D.tam)
	mat.set_shader_parameter("paso", float(PASO))
	mat.set_shader_parameter("abismo", D.lugares[8]["pos"])
	var fondo := ColorRect.new()
	fondo.size = D.tam
	fondo.material = mat
	vp.add_child(fondo)
	_log("texturas de datos listas")

	var tex := {"copa": [_tex_copa(1), _tex_copa(2), _tex_copa(3), _tex_copa(4)], "pino": [_tex_pino(false)],
		"pino_nevado": [_tex_pino(true)], "cristal": [_tex_cristal()], "seco": [_tex_seco()], "roca": [_tex_roca()]}
	var sombra := _tex_sombra()
	var capa := Node2D.new()
	capa.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	capa.draw.connect(func(): _dibujar_capa(capa, tex, sombra))
	vp.add_child(capa)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(salida))
	if cache != "":
		img.save_png(cache.path_join("mapa_mundo_sin_perdida.png"))     # para comparar con el webp
	img.save_webp(salida + "mapa_mundo.webp", true, 0.92)
	_log("mapa pintado guardado: %s (%dx%d)" % [salida + "mapa_mundo.webp", img.get_width(), img.get_height()])
	vp.queue_free()
	_guardar_datos_agua()
	await _iconos()


# Iconos de los lugares (iconos_mapa.gd): uno por lugar, 112×104, y una hoja con todos para revisarlos.
func _iconos() -> void:
	var I = load("res://mapa_arte/iconos_mapa.gd")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(salida + "iconos"))
	var n: int = D.lugares.size() + 1
	var hoja := Image.create(I.TAM.x * 6, I.TAM.y * 2, false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.55, 0.72, 0.40))
	for k in n:
		var img: Image = await render_dibujo(I.TAM, func(c): I.dibujar(c, k))
		img.save_png(salida + "iconos/%d.png" % k)
		hoja.blend_rect(img, Rect2i(Vector2i.ZERO, I.TAM), Vector2i((k % 6) * I.TAM.x, (k / 6) * I.TAM.y))
	if cache != "":
		hoja.save_png(cache.path_join("iconos.png"))
	_log("iconos de los lugares: %d" % n)


func _dibujar_capa(c: Node2D, tex: Dictionary, sombra: Texture2D) -> void:
	# ríos: borde oscuro, agua y brillo central, más anchos río abajo
	for l in rios:
		var n: int = l.size()
		for i in n - 1:
			var t := float(i) / n
			var ancho := lerpf(2.2, 6.5, t)
			c.draw_line(l[i], l[i + 1], Color(0.16, 0.36, 0.48, 0.55), ancho + 2.4, true)
		for i in n - 1:
			var t := float(i) / n
			var ancho := lerpf(2.2, 6.5, t)
			c.draw_line(l[i], l[i + 1], Color(0.40, 0.76, 0.86), ancho, true)
		for i in n - 1:
			var t := float(i) / n
			c.draw_line(l[i], l[i + 1], Color(0.78, 0.95, 0.98, 0.6), lerpf(0.6, 1.8, t), true)
	# caminos: borde de tierra oscura y firme claro
	for l in caminos:
		c.draw_polyline(l, Color(0.40, 0.29, 0.17, 0.42), 7.0, true)
	for l in caminos:
		c.draw_polyline(l, Color(0.93, 0.84, 0.62), 4.0, true)
	for l in caminos:
		c.draw_polyline(l, Color(1.0, 0.96, 0.82, 0.35), 1.2, true)
	# sombras de los árboles (todas antes que las copas, para que no las tapen)
	for a in arboles:
		if a[1] in ["copa", "pino", "pino_nevado"]:
			var tam: float = 22.0 * a[2]
			c.draw_texture_rect(sombra, Rect2(a[0] + Vector2(3.5, 4.5) * a[2] - Vector2(tam, tam) * 0.5, Vector2(tam, tam)), false)
	# copas y adornos, de arriba abajo
	var k := 0
	for a in arboles:
		if a[1] == "espejo":                          # charca: refleja un cielo de anochecer y una estrella
			var e: float = a[2]
			c.draw_set_transform(a[0], a[4] * 0.2, Vector2(1.0, 0.6))
			c.draw_circle(Vector2.ZERO, 10.0 * e + 1.4, Color(0.80, 0.74, 0.95, 0.55))
			c.draw_circle(Vector2(3.0, 1.0) * e, 6.0 * e + 1.4, Color(0.80, 0.74, 0.95, 0.55))
			c.draw_circle(Vector2.ZERO, 10.0 * e, Color(0.22, 0.24, 0.52))
			c.draw_circle(Vector2(3.0, 1.0) * e, 6.0 * e, Color(0.22, 0.24, 0.52))
			c.draw_circle(Vector2(-2.0, -1.5) * e, 6.0 * e, Color(0.34, 0.38, 0.70))
			c.draw_set_transform(Vector2.ZERO)
			_estrella(c, a[0] + Vector2(2.5, -0.5) * e, 2.8 * e, Color(1.0, 0.97, 0.86, 0.95))
			continue
		if a[1] in ["monte", "monte_nevado", "monte_helado"]:
			var t: Texture2D = montes[a[1]][k % montes[a[1]].size()]
			var tam: Vector2 = Vector2(96, 80) * a[2]
			c.draw_texture_rect(t, Rect2(a[0] - Vector2(tam.x * 0.5, tam.y * 0.93), tam), false)
			k += 1
			continue
		var lista: Array = tex[a[1]]
		var t: Texture2D = lista[k % lista.size()]
		var tam: float = (20.0 if a[1] == "copa" else 18.0) * a[2]
		if a[1] in ["cristal", "seco", "roca"]:
			tam = 22.0 * a[2]
		c.draw_texture_rect(t, Rect2(a[0] - Vector2(tam, tam) * 0.5, Vector2(tam, tam)), false, a[3])
		k += 1


# Estrella de cuatro puntas (el motivo de la marca, docs/marca_rebelum.md).
static func _estrella(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := k * PI / 4.0 - PI / 2.0
		pts.append(p + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.28))
	c.draw_colored_polygon(pts, col)


# Datos para el agua animada del juego: hondura y cercanía a la costa (8 bits, rejilla de 2 px).
func _guardar_datos_agua() -> void:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var costa := Image.create(W, H, false, Image.FORMAT_L8)
	for y in H:
		for x in W:
			var i := y * W + x
			var s := sdf[i]
			var hondura := clampf(-s / 255.0, 0.0, 1.0)
			var orilla := 1.0 - clampf(absf(s) / 32.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(hondura, orilla, 1.0 if s > 0.0 else 0.0, 1.0))
			costa.set_pixel(x, y, Color(clampf(0.5 + v[i] * 2.0, 0.0, 1.0), 0, 0))
	img.save_png(salida + "agua_datos.png")
	costa.save_png(salida + "costa_datos.png")
	_log("datos del agua y de la costa guardados")
