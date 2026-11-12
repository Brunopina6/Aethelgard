extends RefCounted
# El trazado del Gran Bosque Verde 3D (V12, migración región a región, 12/11): el MISMO bosque que la 2D (zona.gd, lugar 1),
# leído de disposicion_2d.gd (lo que genera zona.gd: caminos, rincones, río con sus puentes, charcas, muros del borde y
# cada árbol en su casilla), a K metros por casilla. Encima, lo propio de la 3D: el relieve (lomas entre los caminos, el
# borde que sube, el cauce y las charcas hundidas), un mirador en alto junto al camino y el suelo de cada sitio.
# Ejes: x = (casilla.x − 40) · K (este), z = (casilla.y − 28) · K (sur). La entrada, como en la 2D, al sur.
# Todo es estático (lo usan la escena, el escenario, las pruebas y modo3d.gd para las partidas).

const D := preload("res://zonas3d/gran_bosque/disposicion_2d.gd")

const K := 1.25                                  # metros por casilla de la 2D (64 px)
const T2D := 64.0                                # píxeles por casilla (zona.gd, T)
const CENTRO := Vector2(40.0, 28.0)              # la casilla que va al origen
const AGUA_Y := -0.42                            # altura del agua (cauce y charcas)
const FONDO_AGUA := -1.15
# Sitios de la 2D (casillas) y su versión 3D
const ENTRADA_2D := Vector2(40.0, 53.5)          # zona.gd: el jugador empieza en (salida_x, ALTO − 2,5)
const SALIDA_2D := Vector2(40.0, 56.1)           # zona.gd: se sale al pasar de ALTO · T − 4 (al pie del camino)
const DETALLE_DESDE_RUINAS := Vector2(1.4, 0.9)  # zona.gd, _sitio_detalle («ruinas»)
const GRIMFANG_DESDE_CAMPAMENTO := Vector2(-2.3, 1.7)   # zona.gd pone el cofre del hallazgo en el rincón, (−1,4; 1,0)
                                                 # y lo aparta de lo demás; aquí, algo más fuera: en (−1,4; 1,0) cae
                                                 # sobre uno de los troncos para sentarse
# El mirador (solo 3D): una loma de roca al este del camino, entre el puente y el altar, con una rampa desde el camino.
const MIRADOR_2D := Vector2(49.6, 15.4)
const MIRADOR_ALTO := 2.6
const MIRADOR_RADIO := 2.6                       # casillas: la meseta de arriba
const MIRADOR_FALDA := 4.6                       # casillas: hasta donde llega la loma
const RAMPA_2D := Vector2(44.2, 16.6)            # pie de la rampa (junto al camino)


# ================================================================= casillas ↔ mundo

static func mundo(c: Vector2) -> Vector3:
	return Vector3((c.x - CENTRO.x) * K, 0.0, (c.y - CENTRO.y) * K)


static func casilla(x: float, z: float) -> Vector2:
	return Vector2(x / K + CENTRO.x, z / K + CENTRO.y)


static func en_mundo(c: Vector2) -> Vector3:          # con la altura del suelo
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


# zona.gd, _peso: el valor de una máscara por vértices, interpolado en la casilla c.
static func peso(v: PackedByteArray, c: Vector2) -> float:
	var vw := D.ANCHO + 1
	var x := clampi(int(c.x), 0, D.ANCHO - 1)
	var y := clampi(int(c.y), 0, D.ALTO - 1)
	var u := clampf(c.x - x, 0.0, 1.0)
	var w := clampf(c.y - y, 0.0, 1.0)
	var arriba := lerpf(v[y * vw + x], v[y * vw + x + 1], u)
	var abajo := lerpf(v[(y + 1) * vw + x], v[(y + 1) * vw + x + 1], u)
	return lerpf(arriba, abajo, w)


static func agua(c: Vector2) -> float:
	_mascaras()
	return peso(_agua, c)


static func en_camino_2d(c: Vector2) -> bool:
	_mascaras()
	return peso(_camino, c) > 0.5


# zona.gd, _en_puente (en casillas)
static func en_puente(c: Vector2, margen := 0.0) -> bool:
	for pu in D.PUENTES:
		var d: Vector2 = c - pu[0]
		var dir: Vector2 = pu[1]
		if absf(d.dot(dir)) < pu[2] * 0.5 + margen and absf(d.dot(dir.orthogonal())) < 1.1 + margen:
			return true
	return false


# En la 3D los puentes son algo más largos que en la 2D (PUENTE_EXTRA casillas por cada lado): en la 2D, el agua de la
# orilla llega a tocar el camino junto a los dos puentes (se pasa por el borde, _peso ≤ 0,55); aquí el puente la cubre.
const PUENTE_EXTRA := 1.5


static func en_puente_3d(c: Vector2, margen := 0.0) -> bool:
	for pu in puentes_3d():
		var d: Vector2 = c - pu[0]
		var dir: Vector2 = pu[1]
		if absf(d.dot(dir)) < pu[2] * 0.5 + margen and absf(d.dot(dir.orthogonal())) < 1.1 + margen:
			return true
	return false


# Los puentes de la 3D: [centro, dirección, largo total, largo sobre el agua] en casillas. Los dos de la 2D (algo más
# largos) y, donde el camino de la 2D aún pisa agua (la rama del claro, antes del segundo puente: en la 2D hay que dar la
# vuelta por el bosque), una pasarela más con la dirección del camino.
static var _puentes := []


static func puentes_3d() -> Array:
	if not _puentes.is_empty():
		return _puentes
	var lista: Array = []
	for pu in D.PUENTES:
		lista.append([pu[0], pu[1], pu[2] + 2.0 * PUENTE_EXTRA, pu[2]])
	_puentes = lista                                       # (en_puente_3d ya mira los de la 2D al buscar los tramos)
	for cam in D.CAMINOS:
		for i in cam.size() - 1:
			var a: Vector2 = cam[i]
			var b: Vector2 = cam[i + 1]
			var n := int(a.distance_to(b) / 0.25)
			var desde := -1
			for s in n + 2:
				var mojado := false
				if s <= n:
					var c: Vector2 = a.lerp(b, float(s) / n)
					mojado = agua(c) > 0.5 and not en_puente_3d(c)
				if mojado and desde < 0:
					desde = s
				elif not mojado and desde >= 0:
					var c0: Vector2 = a.lerp(b, float(desde) / n)
					var c1: Vector2 = a.lerp(b, float(s - 1) / n)
					var largo := c0.distance_to(c1)
					lista.append([(c0 + c1) * 0.5, (b - a).normalized(), largo + 2.0 * PUENTE_EXTRA, maxf(largo, 1.0)])
					desde = -1
	_puentes = lista
	return _puentes


# zona.gd, _en_agua: no se puede andar (salvo por los puentes)
static func en_agua(c: Vector2) -> bool:
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


# Distancia (en casillas) al camino más cercano (zona.gd, _dist_caminos).
static func dist_caminos(c: Vector2) -> float:
	var mejor := 999.0
	for cam in D.CAMINOS:
		for i in cam.size() - 1:
			mejor = minf(mejor, _dist_seg(c, cam[i], cam[i + 1]))
	return mejor


# El punto de un camino más cercano a c (casillas), sin pasar del borde sur (por donde se sale).
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


# Medio ancho del choque de cada objeto en la 2D, en casillas (zona.gd, DECORADO y OBJETOS: «choque» / 64 px).
const CHOQUE_2D := {"arce": 0.53, "abedul": 0.38, "glicinia": 0.53, "q_arbol": 0.47, "q_pino": 0.47, "q_otono": 0.5,
	"q_arbusto": 0.38, "arbusto": 0.41, "helecho": 0.25, "flor_azul": 0.19, "q_roca": 0.44, "columna": 0.31,
	"muro_ruina": 0.53, "brasero": 0.25}


# ¿Puede estar el jugador 2D en c sin quedar dentro del choque de un objeto (ni de un cofre ni del altar)?
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

# La rejilla de alturas (la malla del suelo se hace con ella y el choque es esa malla): se calcula una vez por proceso
# (vuelve a valer al volver de un combate) y altura() la interpola. Fuera de la rejilla, la cuenta directa.
const REJILLA_PASO := 0.8
const REJILLA_MIN := Vector2(-62.0, -48.0)
const REJILLA_N := Vector2i(156, 121)            # vértices en x y en z (124,8 × 96 m)
static var _alturas := PackedFloat32Array()
static var _dist_rejilla := PackedFloat32Array()  # distancia al camino (casillas) en cada vértice (el color del suelo)


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


# Altura del suelo en (x, z), la misma que la malla: dentro de cada cuadro de la rejilla, sus dos triángulos (diagonal
# de (i+1, j) a (i, j+1), como la malla de escenario.gd).
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


# Lomas suaves entre los caminos, que se aplanan en los caminos, los rincones y el altar; el borde (los muros de la 2D)
# sube como una ladera cerrada de bosque; el cauce y las charcas, hundidos bajo el agua; el camino, algo gastado; y el
# mirador, una loma con su rampa.
static func altura_calculada(x: float, z: float) -> float:
	var c := casilla(x, z)
	return _altura_con(x, z, c, dist_caminos(c))


static func _altura_con(x: float, z: float, c: Vector2, dc: float) -> float:
	var dr := dist_rincones(c)
	var base := 0.22 * sin(x * 0.21 + 0.7) * cos(z * 0.17 - 0.3) + 0.14 * sin(x * 0.47 + z * 0.31) + 0.07 * sin(x * 1.1 - z * 0.9)
	var lomas := 1.5 * maxf(0.0, sin(x * 0.085 + 1.3) * cos(z * 0.105 + 0.4)) + 0.9 * maxf(0.0, sin(x * 0.05 - z * 0.07 + 2.0)) \
		+ 0.35 * sin(x * 0.19 + z * 0.13)
	var llano := smoothstep(1.4, 5.0, dc) * smoothstep(3.6, 7.0, dr)
	var h := base * (0.35 + 0.65 * llano) + maxf(lomas, -0.2) * llano
	var borde := minf(minf(c.x, c.y), minf(D.ANCHO - c.x, D.ALTO + 2.0 - c.y))
	h += (smoothstep(5.0, 0.0, borde) * 3.2 + maxf(-borde, 0.0) * 0.45) * smoothstep(1.0, 3.0, dc)
	h -= 0.07 * (1.0 - smoothstep(0.3, 1.3, dc))        # el camino, algo hundido por el paso
	h += _mirador(c)
	var w := agua(c)
	if w > 0.05:
		var hondo := smoothstep(0.36, 0.62, w)
		h = lerpf(h * (1.0 - smoothstep(0.05, 0.3, w) * 0.7), FONDO_AGUA, hondo)
	return h


# La loma del mirador: meseta arriba, falda suave y una rampa desde el camino (pendiente que se puede andar).
static func _mirador(c: Vector2) -> float:
	var d := c.distance_to(MIRADOR_2D)
	var h := MIRADOR_ALTO * (1.0 - smoothstep(MIRADOR_RADIO, MIRADOR_FALDA, d))
	var a := RAMPA_2D
	var b := MIRADOR_2D + (RAMPA_2D - MIRADOR_2D).normalized() * MIRADOR_RADIO * 0.6
	var ab := b - a
	var t := clampf((c - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var lado := c.distance_to(a + ab * t)
	var en_rampa := (1.0 - smoothstep(0.9, 1.7, lado)) * smoothstep(-0.05, 0.05, (c - a).dot(ab))
	return lerpf(h, MIRADOR_ALTO * t, en_rampa)        # la rampa corta la ladera: pendiente que se puede andar


static func en_mirador(p: Vector3) -> bool:
	return casilla(p.x, p.z).distance_to(MIRADOR_2D) < MIRADOR_RADIO and p.y > MIRADOR_ALTO - 0.6


# ================================================================= lo que no se pisa

# Fuera del bosque (los muros de la 2D, salvo el camino de la salida), el agua (salvo los puentes) y la cara empinada de
# la loma del mirador. Los troncos, rocas y piezas los añade la escena (escenario.gd).
static func prohibido(x: float, z: float) -> bool:
	var c := casilla(x, z)
	if c.x < 0.8 or c.x > D.ANCHO - 0.8 or c.y < 0.8 or c.y > D.ALTO + 1.2:
		return true
	if muro(c) and not (dist_caminos(c) < 1.3 and c.y > D.ALTO - 5.0):
		return true
	if agua(c) > 0.5 and not en_puente_3d(c, 0.15):
		return true
	return false


# El suelo que pisa quien está en p (sonido.gd, pasos): como la 2D (sonido.gd, suelo_zona): madera en los puentes, grava
# en la tierra del camino, hojas en el suelo del bosque; y hierba en el claro, y piedra en la roca del mirador.
static func suelo(p: Vector3) -> String:
	var c := casilla(p.x, p.z)
	if en_puente_3d(c) and agua(c) > 0.05:
		return "madera"
	if en_camino_2d(c):
		return "grava"
	if c.distance_to(MIRADOR_2D) < MIRADOR_RADIO + 0.4 and p.y > 1.0:
		return "piedra"
	if c.distance_to(lugar("claro")) < 4.0:
		return "hierba"
	return "hojas"


# ================================================================= partidas (2D ↔ 3D)

# Una posición de la 2D (píxeles de zona.gd) en la 3D: la misma casilla. Si allí no se puede estar (agua, borde), el
# camino más cercano. Nunca encima de la salida (se saldría al llegar).
static func desde_2d(px: Vector2) -> Vector3:
	var c := px / T2D
	c.y = minf(c.y, ENTRADA_2D.y)
	var p := mundo(c)
	var dm := c.distance_to(MIRADOR_2D)                 # la ladera del mirador es empinada: ahí no (sí arriba)
	if prohibido(p.x, p.z) or (dm > MIRADOR_RADIO - 0.3 and dm < MIRADOR_FALDA + 0.3):
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


# Al revés: una posición de la 3D en píxeles de la 2D, siempre en un sitio donde la 2D deja estar (zona.gd no lo
# comprueba al cargar): en el camino o en un rincón; si no, en el punto más cercano del camino.
static func a_2d(p: Vector3) -> Vector2:
	var c := casilla(p.x, p.z)
	c = Vector2(clampf(c.x, 1.5, D.ANCHO - 1.5), clampf(c.y, 1.5, ENTRADA_2D.y))
	if not vale_2d(c):
		c = punto_en_camino(c)
		if not vale_2d(c):                               # en el camino, un objeto o el agua de la orilla: al lado
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


# ¿Se puede estar en c en la 2D? En la tierra del camino o de un rincón, sin agua, sin muro y fuera de los choques.
static func vale_2d(c: Vector2) -> bool:
	return (en_camino_2d(c) or dist_rincones(c) < 2.4) and not en_agua(c) and not muro(c) and libre_2d(c)
