extends RefCounted
# El trazado de las Cumbres de Ciclópea 3D, primer sector (V12, especialista de mundo, 13/11): el MISMO trazado que la 2D
# (zona.gd con el lugar 3, estilo «nieve»), leído de disposicion_2d.gd, a K metros por casilla, con el relieve de una
# subida de montaña:
#   - el camino sube del sur (la entrada, 0 m) al altar del norte (ALTO_ALTAR) con una pendiente suave (≤ 14 %);
#   - el suelo de alrededor está a la altura del camino de su misma latitud en una franja de LLANO casillas a cada lado
#     (NO es una trinchera: las laderas bajan hasta el camino) y más allá sube en lomas de nieve;
#   - el borde (los muros de la 2D) son paredes de roca que crecen hacia el norte, hasta las cumbres;
#   - el agua de la 2D, lagos y un arroyo helados, hundidos (no se pisan, salvo el puente).
# Ejes: x = (casilla.x − 40) · K (este), z = (casilla.y − 28) · K (sur). Todo es estático.

const D := preload("res://zonas3d/ciclopea/disposicion_2d.gd")

const K := 1.25                                  # metros por casilla de la 2D (64 px), como el Gran Bosque
const T2D := 64.0
const CENTRO := Vector2(40.0, 28.0)
const ALTO_ALTAR := 7.5                          # m que sube el camino de la entrada al altar
const SUR := 56.0                                # casilla y de la entrada (0 m)
const LLANO := 2.6                               # casillas a cada lado del camino a su misma altura (las laderas bajan)
const HIELO_Y := -0.32                           # el hielo de los lagos, bajo el suelo de alrededor
const FONDO_HIELO := -0.55
const ENTRADA_2D := Vector2(40.0, 53.5)          # zona.gd: se empieza en (salida_x, ALTO − 2,5)
const SALIDA_2D := Vector2(40.0, 56.1)           # zona.gd: se sale por el pie del camino
const PUENTE_EXTRA := 1.5                        # el puente de la 3D, algo más largo que el de la 2D por cada lado


# ================================================================= casillas ↔ mundo

static func mundo(c: Vector2) -> Vector3:
	return Vector3((c.x - CENTRO.x) * K, 0.0, (c.y - CENTRO.y) * K)


static func casilla(x: float, z: float) -> Vector2:
	return Vector2(x / K + CENTRO.x, z / K + CENTRO.y)


static func en_mundo(c: Vector2) -> Vector3:
	var p := mundo(c)
	p.y = altura(p.x, p.z)
	return p


# ================================================================= máscaras de la 2D

static var _agua := PackedByteArray()
static var _camino := PackedByteArray()
static var _muros := PackedByteArray()


static func _mascaras() -> void:
	if not _agua.is_empty():
		return
	for par in [[D.AGUA, _agua], [D.CAMINO, _camino], [D.MUROS, _muros]]:
		var s: String = par[0]
		var v: PackedByteArray = par[1]
		v.resize(s.length())
		for i in s.length():
			v[i] = 1 if s.unicode_at(i) == 49 else 0


static func peso(v: PackedByteArray, c: Vector2) -> float:          # zona.gd, _peso
	var vw := D.ANCHO + 1
	var x := clampi(int(c.x), 0, D.ANCHO - 1)
	var y := clampi(int(c.y), 0, D.ALTO - 1)
	var u := clampf(c.x - x, 0.0, 1.0)
	var w := clampf(c.y - y, 0.0, 1.0)
	return lerpf(lerpf(v[y * vw + x], v[y * vw + x + 1], u), lerpf(v[(y + 1) * vw + x], v[(y + 1) * vw + x + 1], u), w)


static func agua(c: Vector2) -> float:
	_mascaras()
	return peso(_agua, c)


static func en_camino_2d(c: Vector2) -> bool:
	_mascaras()
	return peso(_camino, c) > 0.5


static func en_puente(c: Vector2, margen := 0.0) -> bool:            # zona.gd, _en_puente
	for pu in D.PUENTES:
		var d: Vector2 = c - pu[0]
		var dir: Vector2 = pu[1]
		if absf(d.dot(dir)) < pu[2] * 0.5 + margen and absf(d.dot(dir.orthogonal())) < 1.1 + margen:
			return true
	return false


static func en_puente_3d(c: Vector2, margen := 0.0) -> bool:
	for pu in D.PUENTES:
		var d: Vector2 = c - pu[0]
		var dir: Vector2 = pu[1]
		if absf(d.dot(dir)) < pu[2] * 0.5 + PUENTE_EXTRA + margen and absf(d.dot(dir.orthogonal())) < 1.1 + margen:
			return true
	return false


static func en_agua(c: Vector2) -> bool:                             # zona.gd, _en_agua
	return agua(c) > 0.55 and not en_puente(c)


static func muro(c: Vector2) -> bool:
	_mascaras()
	var x := floori(c.x)
	var y := floori(c.y)
	if x < 0 or y < 0 or x >= D.ANCHO or y >= D.ALTO:
		return true
	return _muros[y * D.ANCHO + x] != 0


static func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func dist_caminos(c: Vector2) -> float:
	var mejor := 999.0
	for cam in D.CAMINOS:
		for i in cam.size() - 1:
			mejor = minf(mejor, _dist_seg(c, cam[i], cam[i + 1]))
	return mejor


static func punto_en_camino(c: Vector2) -> Vector2:
	var mejor := Vector2(D.SALIDA_X, ENTRADA_2D.y)
	var dist := INF
	for cam in D.CAMINOS:
		for i in cam.size() - 1:
			var a: Vector2 = cam[i]
			var b: Vector2 = cam[i + 1]
			var ab := b - a
			var t := clampf((c - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			var q := a + ab * t
			q.y = minf(q.y, ENTRADA_2D.y)
			if q.distance_to(c) < dist:
				dist = q.distance_to(c)
				mejor = q
	return mejor


# Medio ancho del choque de cada objeto en la 2D, en casillas (zona.gd, OBJETOS: «choque» / 64 px).
const CHOQUE_2D := {"pino_nevado": 0.44, "roca_nevada": 0.41, "columna": 0.31, "muro_ruina": 0.53, "brasero": 0.25,
	"estela": 0.31}


static func libre_2d(c: Vector2) -> bool:
	for o in D.OBJETOS:
		var r: float = CHOQUE_2D.get(o[0], 0.0)
		if r > 0.0 and absf(c.x - o[1].x) < r + 0.3 and absf(c.y - o[1].y) < r * 0.55 + 0.4:
			return false
	for cf in D.COFRES:
		if c.distance_to(cf[1]) < 0.6:
			return false
	return c.distance_to(D.META) > 0.8


static func lugar(tipo: String) -> Vector2:
	for l in D.LUGARES:
		if l[0] == tipo:
			return l[1]
	return D.META


static func dist_rincones(c: Vector2) -> float:
	var mejor := c.distance_to(D.META)
	for l in D.LUGARES:
		mejor = minf(mejor, c.distance_to(l[1]))
	return mejor


# ================================================================= relieve

# La altura del camino a la latitud c.y: sube del sur al norte (mitad lineal, mitad suave: ≤ 14 % de pendiente).
static func altura_camino(cy: float) -> float:
	var t := clampf((SUR - cy) / (SUR - D.META.y), 0.0, 1.0)
	return ALTO_ALTAR * (0.5 * t + 0.5 * t * t * (3.0 - 2.0 * t))


const REJILLA_PASO := 0.8
const REJILLA_MIN := Vector2(-62.0, -48.0)
const REJILLA_N := Vector2i(156, 121)            # 124 × 96 m
static var _alturas := PackedFloat32Array()
static var _dist_rejilla := PackedFloat32Array()


static func preparar_alturas() -> void:
	if not _alturas.is_empty():
		return
	var a := PackedFloat32Array()
	var dd := PackedFloat32Array()
	a.resize(REJILLA_N.x * REJILLA_N.y)
	dd.resize(REJILLA_N.x * REJILLA_N.y)
	for j in REJILLA_N.y:
		for i in REJILLA_N.x:
			var x := REJILLA_MIN.x + i * REJILLA_PASO
			var z := REJILLA_MIN.y + j * REJILLA_PASO
			var c := casilla(x, z)
			var dc := dist_caminos(c)
			dd[j * REJILLA_N.x + i] = dc
			a[j * REJILLA_N.x + i] = _altura_con(x, z, c, dc)
	_dist_rejilla = dd
	_alturas = a


static func dist_rejilla(i: int, j: int) -> float:
	preparar_alturas()
	return _dist_rejilla[clampi(j, 0, REJILLA_N.y - 1) * REJILLA_N.x + clampi(i, 0, REJILLA_N.x - 1)]


static func altura_rejilla(i: int, j: int) -> float:
	preparar_alturas()
	return _alturas[clampi(j, 0, REJILLA_N.y - 1) * REJILLA_N.x + clampi(i, 0, REJILLA_N.x - 1)]


# La misma altura que la malla del suelo (sus dos triángulos por cuadro).
static func altura(x: float, z: float) -> float:
	preparar_alturas()
	var fx := (x - REJILLA_MIN.x) / REJILLA_PASO
	var fz := (z - REJILLA_MIN.y) / REJILLA_PASO
	if fx < 0.0 or fz < 0.0 or fx >= REJILLA_N.x - 1 or fz >= REJILLA_N.y - 1:
		return altura_calculada(x, z)
	var i := int(fx)
	var j := int(fz)
	var u := fx - i
	var v := fz - j
	var h00 := _alturas[j * REJILLA_N.x + i]
	var h10 := _alturas[j * REJILLA_N.x + i + 1]
	var h01 := _alturas[(j + 1) * REJILLA_N.x + i]
	var h11 := _alturas[(j + 1) * REJILLA_N.x + i + 1]
	if u + v <= 1.0:
		return h00 + (h10 - h00) * u + (h01 - h00) * v
	return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)


static func altura_calculada(x: float, z: float) -> float:
	var c := casilla(x, z)
	return _altura_con(x, z, c, dist_caminos(c))


static func _altura_con(x: float, z: float, c: Vector2, dc: float) -> float:
	var base := altura_camino(c.y)
	var dr := dist_rincones(c)
	# lomas de nieve, solo lejos del camino y de los rincones (cerca, el suelo está a la altura del camino)
	var lejos := smoothstep(LLANO, LLANO + 4.0, dc) * smoothstep(3.0, 6.0, dr)
	var lomas := 0.9 * maxf(0.0, sin(x * 0.11 + 0.8) * cos(z * 0.09 - 0.5)) + 0.5 * maxf(0.0, sin(x * 0.05 - z * 0.08 + 1.7)) \
		+ 0.18 * sin(x * 0.37 + z * 0.29)
	var h := base + maxf(lomas, -0.1) * lejos * (1.0 + 0.6 * smoothstep(SUR, D.META.y, c.y))
	h += 0.05 * sin(x * 0.9 - z * 0.7) * (1.0 - smoothstep(0.5, 1.5, dc))    # la nieve pisada, algo irregular
	# el borde: paredes de roca que suben hacia las cumbres (más altas al norte)
	var borde := minf(minf(c.x, c.y), minf(D.ANCHO - c.x, D.ALTO + 2.0 - c.y))
	var norte := smoothstep(SUR, 0.0, c.y)
	var pared := smoothstep(5.5, 0.0, borde) * (3.5 + 7.5 * norte) + maxf(-borde, 0.0) * (0.9 + 1.4 * norte)
	if c.y > D.ALTO - 5.0 and absf(c.x - D.SALIDA_X) < 4.0:   # el paso de la entrada, abierto hacia el sur
		pared *= smoothstep(1.5, 4.0, absf(c.x - D.SALIDA_X))
	h += pared * smoothstep(0.8, 2.4, dc)
	# lagos y arroyo helados, hundidos
	var w := agua(c)
	if w > 0.05:
		var hondo := smoothstep(0.36, 0.62, w)
		h = lerpf(h - smoothstep(0.05, 0.36, w) * 0.2, base + FONDO_HIELO, hondo)
	return h


# ================================================================= lo que no se pisa

static func prohibido(x: float, z: float) -> bool:
	var c := casilla(x, z)
	if c.x < 0.8 or c.x > D.ANCHO - 0.8 or c.y < 0.8 or c.y > D.ALTO + 1.2:
		return true
	if muro(c) and not (dist_caminos(c) < 1.3 and c.y > D.ALTO - 5.0):
		return true
	if agua(c) > 0.5 and not en_puente_3d(c, 0.15):
		return true
	return false


# El suelo que pisa quien está en p (sonido.gd, pasos): madera en el puente, nieve en el resto; la nieve pisada del
# camino suena a grava; piedra en las ruinas.
static func suelo(p: Vector3) -> String:
	var c := casilla(p.x, p.z)
	if en_puente_3d(c) and agua(c) > 0.05:
		return "madera"
	if c.distance_to(lugar("ruinas")) < 3.0:
		return "piedra"
	if en_camino_2d(c):
		return "grava"
	return "nieve"


# ================================================================= partidas (2D ↔ 3D)

static func desde_2d(px: Vector2) -> Vector3:
	var c := px / T2D
	c.y = minf(c.y, ENTRADA_2D.y)
	var p := mundo(c)
	if prohibido(p.x, p.z):
		p = mundo(punto_en_camino(c))
		if prohibido(p.x, p.z):
			for radio in [0.6, 1.2, 1.8, 2.5]:
				for k in 12:
					var q: Vector3 = p + Vector3(cos(k * TAU / 12.0), 0, sin(k * TAU / 12.0)) * radio
					if not prohibido(q.x, q.z):
						q.y = altura(q.x, q.z)
						return q
	p.y = altura(p.x, p.z)
	return p


static func a_2d(p: Vector3) -> Vector2:
	var c := casilla(p.x, p.z)
	c = Vector2(clampf(c.x, 1.5, D.ANCHO - 1.5), clampf(c.y, 1.5, ENTRADA_2D.y))
	if not vale_2d(c):
		c = punto_en_camino(c)
		if not vale_2d(c):
			var hallado := false
			for radio in [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0]:
				for k in 12:
					var q: Vector2 = c + Vector2.from_angle(k * TAU / 12.0) * radio
					if q.y <= ENTRADA_2D.y and vale_2d(q):
						c = q
						hallado = true
						break
				if hallado:
					break
			if not hallado:
				c = ENTRADA_2D
	return c * T2D


static func vale_2d(c: Vector2) -> bool:
	return (en_camino_2d(c) or dist_rincones(c) < 2.4) and not en_agua(c) and not muro(c) and libre_2d(c)
