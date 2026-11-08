extends RefCounted
# Datos del mapamundi para el arte nuevo (T-085). Reproduce EXACTAMENTE el campo con el que mapa.gd decide la tierra
# y las zonas (_generar_terreno: mismas semillas, mismos ruidos y mismas constantes, leídas de mapa.gd), pero se
# puede evaluar en cualquier punto y con más resolución. Así el dibujo nuevo sale de los mismos datos que el juego.
#
# Alineación con el juego (comprobada con la prueba prueba_mapamundi.gd):
#   mapa.gd evalúa el campo en la esquina de cada bloque de 4×4 px (x*4, y*4) y estira la máscara de 600×337 a
#   1200×675 con Image.resize(NEAREST), que muestrea por centros: las filas van de dos en dos y la 168 sale tres
#   veces. Para un punto q del mundo, el juego mira la muestra (4·⌊q.x/4⌋, 4·fila_juego(q.y)) (exacto, abajo).
#   Así, en la mitad de arriba la máscara coincide con el dibujo antiguo (textura de 600×337 a escala 4) y en la
#   de abajo va 2 px más abajo que él. El campo continuo equivalente es v(q − desfase(q.y)).

var MAPA = load("res://mapa.gd")   # load y no preload: mapa.gd podrá usar este archivo sin ciclos
# Orden de las zonas: el del diccionario ZONAS de mapa.gd.
const ZONAS_ORDEN := ["bosque", "llanura", "montana", "nieve", "desierto", "yermo", "ceniza"]

var ruido: FastNoiseLite
var ruido_zona: FastNoiseLite
var tam: Vector2
var lugares: Array
var rutas: Array
var islas: Array
var zona_lugar: Array
var ancho: float


func _init() -> void:
	# los mismos ruidos que mapa.gd (_generar_terreno)
	ruido = FastNoiseLite.new()
	ruido.seed = 7
	ruido.frequency = 0.004
	ruido.fractal_octaves = 4
	ruido_zona = FastNoiseLite.new()
	ruido_zona.seed = 21
	ruido_zona.frequency = 0.006
	tam = MAPA.MAPA_TAM
	lugares = MAPA.LUGARES
	rutas = MAPA.RUTAS
	islas = MAPA.ISLAS
	zona_lugar = MAPA.ZONA_LUGAR
	ancho = MAPA.ANCHO_CAMINO


# Campo de tierra de mapa.gd en un punto p (sin desfase): tierra si v >= 0.
func campo_v(p: Vector2) -> float:
	var n := ruido.get_noise_2d(p.x, p.y)
	var d := 1e9
	for r in rutas:
		d = minf(d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, lugares[r[0]]["pos"], lugares[r[1]]["pos"])))
	var d_isla := 1e9
	for i in islas:
		d_isla = minf(d_isla, p.distance_to(lugares[i]["pos"]) * 1.4)
	return 1.0 - minf(d, d_isla) / ancho + n * 0.9


# Índice (en ZONAS_ORDEN) de la zona de mapa.gd en un punto p (sin desfase): la del lugar más cercano al punto
# desplazado por el ruido de zona.
func zona_en(p: Vector2) -> int:
	var pz := p + Vector2(ruido_zona.get_noise_2d(p.x, p.y), ruido_zona.get_noise_2d(p.x + 911.0, p.y)) * 260.0
	var mejor := 0
	var dmin := 1e9
	for i in lugares.size():
		var dd: float = pz.distance_to(lugares[i]["pos"])
		if dd < dmin:
			dmin = dd
			mejor = i
	return ZONAS_ORDEN.find(zona_lugar[mejor])


# Fila de la muestra de 4 px que usa el juego (_es_tierra y _zona_en) para la coordenada y del mundo: la máscara de
# 1200×675 sale de la de 600×337 con resize NEAREST por centros, fila = ⌊(⌊y/2⌋ + 0,5) · 337 / 675⌋.
static func fila_juego(y: float) -> int:
	var Y := int(y * 0.5)
	return int(floor((Y + 0.5) * 337.0 / 675.0))


# ¿Es tierra para el juego el punto q? Igual que mapa.gd (_es_tierra), sin necesitar su imagen.
func tierra_juego(q: Vector2) -> bool:
	if q.x < 0.0 or q.y < 0.0 or q.x >= tam.x or q.y >= tam.y:
		return false
	return campo_v(Vector2(4.0 * floor(q.x / 4.0), 4.0 * fila_juego(q.y))) >= 0.0


# Desfase del campo continuo que imita la máscara del juego: el bloque de 4 px se evalúa en su esquina (−2 px en x
# y en y respecto a su centro) y, pasada la fila 168 (y ≈ 676), la máscara baja 2 px más. Se suaviza el salto.
static func desfase(y: float) -> Vector2:
	return Vector2(2.0, 2.0 + 2.0 * smoothstep(660.0, 692.0, y))


# Campos en una rejilla de `paso` px del mundo, ya alineados con el juego: la celda (i, j) cubre
# [paso·i, paso·(i+1)) y se evalúa en su centro menos desfase().
# Devuelve {"w", "h", "paso", "v": PackedFloat32Array, "zona": PackedByteArray}.
func calcular(paso: int) -> Dictionary:
	var w := int(ceil(tam.x / paso))
	var h := int(ceil(tam.y / paso))
	var v := PackedFloat32Array()
	v.resize(w * h)
	var z := PackedByteArray()
	z.resize(w * h)
	for y in h:
		for x in w:
			var c := Vector2(x * paso, y * paso) + Vector2(paso, paso) * 0.5
			var p := c - desfase(c.y)
			v[y * w + x] = campo_v(p)
			z[y * w + x] = zona_en(p)
	return {"w": w, "h": h, "paso": paso, "v": v, "zona": z}


# ------------------------------------------------------------------ distancias (transformada exacta)

# Distancia euclídea (en celdas) de cada celda a la celda «objetivo» más cercana (Felzenszwalb y Huttenlocher).
static func distancia(objetivo: PackedByteArray, w: int, h: int) -> PackedFloat32Array:
	const INF := 1e20
	var g := PackedFloat32Array()
	g.resize(w * h)
	var n := maxi(w, h)
	var f := PackedFloat32Array()
	f.resize(n)
	var d := PackedFloat32Array()
	d.resize(n)
	var vv := PackedInt32Array()
	vv.resize(n)
	var zz := PackedFloat32Array()
	zz.resize(n + 1)
	for x in w:                                     # columnas
		for y in h:
			f[y] = 0.0 if objetivo[y * w + x] != 0 else INF
		_dt1d(f, h, d, vv, zz)
		for y in h:
			g[y * w + x] = d[y]
	for y in h:                                     # filas
		for x in w:
			f[x] = g[y * w + x]
		_dt1d(f, w, d, vv, zz)
		for x in w:
			g[y * w + x] = sqrt(d[x])
	return g


static func _dt1d(f: PackedFloat32Array, n: int, d: PackedFloat32Array, v: PackedInt32Array, z: PackedFloat32Array) -> void:
	var k := 0
	v[0] = 0
	z[0] = -1e30
	z[1] = 1e30
	for q in range(1, n):
		var s := ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / float(2 * q - 2 * v[k])
		while s <= z[k]:
			k -= 1
			s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / float(2 * q - 2 * v[k])
		k += 1
		v[k] = q
		z[k] = s
		z[k + 1] = 1e30
	k = 0
	for q in n:
		while z[k + 1] < q:
			k += 1
		d[q] = (q - v[k]) * (q - v[k]) + f[v[k]]


# Desenfoque de caja separable (radio r celdas), repetido `pasadas` veces (≈ gaussiano).
static func desenfocar(a: PackedFloat32Array, w: int, h: int, r: int, pasadas := 2) -> PackedFloat32Array:
	var src := a.duplicate()
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var k := 1.0 / float(2 * r + 1)
	for i in pasadas:
		for y in h:
			var fila := y * w
			var acc := 0.0
			for x in range(-r, r + 1):
				acc += src[fila + clampi(x, 0, w - 1)]
			for x in w:
				tmp[fila + x] = acc * k
				acc += src[fila + mini(x + r + 1, w - 1)] - src[fila + maxi(x - r, 0)]
		for x in w:
			var acc := 0.0
			for y in range(-r, r + 1):
				acc += tmp[clampi(y, 0, h - 1) * w + x]
			for y in h:
				src[y * w + x] = acc * k
				acc += tmp[mini(y + r + 1, h - 1) * w + x] - tmp[maxi(y - r, 0) * w + x]
	return src
