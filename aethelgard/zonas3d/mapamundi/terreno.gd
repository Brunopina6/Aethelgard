extends RefCounted
# V12, mapamundi 3D (15/11/2026): el relieve de la región «Tierras de Oakhaven» como una maqueta.
#
# Sale de la MISMA máscara que el mapa 2D (mapa_arte/mapa_zonas.png, la que usa mapa.gd para la tierra y las zonas): la
# costa, el mar, las praderas («llanura») y los bosques («bosque») están donde los pinta el mapa 2D. Encima, el relieve
# es PROPUESTA: playas claras, lomas suaves en las praderas, una sierra al oeste (donde se abre la cueva) y unos cerros
# sobre la costa del nordeste. El camino, la senda de la cueva y los sitios (Oakhaven, Pastos, el campamento...) se
# allanan para que se lean y se anden.
#
# Una rejilla de 1 m (145 × 129 puntos): la malla se parte en 4 × 4 trozos (Godot descarta los que no ve la cámara) y el
# suelo de la física es un HeightMapShape3D con las mismas alturas. Se calcula una vez por sesión (_cache): volver al
# mapamundi no lo repite.

const D := preload("res://zonas3d/mapamundi/datos.gd")
const MASCARA := "res://mapa_arte/mapa_zonas.png"
const X0 := -72.0
const Z0 := -64.0
const ANCHO := 145                       # puntos en x (de −72 a 72 m)
const FONDO := 129                       # puntos en z (de −64 a 64 m)
const TROZOS := Vector2i(4, 4)
const COLOR_BOSQUE := Color8(40, 160, 60)  # mapa.gd ZONAS["bosque"]
const COLOR_LLANURA := Color8(150, 190, 90)

# Sierras y cerros (PROPUESTA): [centro (x, z), radio, altura]
const MONTES := [[Vector2(-47.0, -31.0), 13.0, 12.5], [Vector2(-38.5, -12.5), 10.5, 10.0], [Vector2(-50.0, -3.0), 9.0, 7.0],
	[Vector2(-34.0, -27.0), 7.0, 6.5], [Vector2(19.0, -27.5), 8.5, 7.5], [Vector2(28.5, -21.0), 6.0, 5.0]]

# Colores de la maqueta
const ARENA := Color(0.90, 0.82, 0.60)
const PRADERA := Color(0.50, 0.71, 0.30)
const PRADERA_ALTA := Color(0.64, 0.77, 0.37)
const PRADERA_OSCURA := Color(0.38, 0.60, 0.25)
const PRADERA_SECA := Color(0.70, 0.74, 0.40)
const SUELO_BOSQUE := Color(0.34, 0.55, 0.26)
const ROCA := Color(0.55, 0.51, 0.46)
const ROCA_CLARA := Color(0.78, 0.75, 0.70)
const TIERRA := Color(0.56, 0.45, 0.33)
const FONDO_MAR := Color(0.36, 0.52, 0.48)
const CAMINO_CENTRO := Color(0.86, 0.76, 0.56)
const CAMINO_BORDE := Color(0.70, 0.59, 0.42)

static var _cache := {}


static func indice(ix: int, iz: int) -> int:
	return iz * ANCHO + ix


static func punto(ix: int, iz: int) -> Vector2:
	return Vector2(X0 + ix, Z0 + iz)


# Los datos de la rejilla: alturas, tierra (1/0), zona (1 = bosque), distancia a la costa (con signo: + en tierra),
# distancia al camino y lo que «allana» cada punto. Una vez por sesión.
static func datos() -> Dictionary:
	if _cache.is_empty():
		_cache = _calcular()
	return _cache


static func _calcular() -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var n := ANCHO * FONDO
	var img: Image = null
	if ResourceLoader.exists(MASCARA):
		var r = load(MASCARA)                     # importada como Image (como la lee mapa_arte.gd)
		img = r if r is Image else (r.get_image() if r is Texture2D else null)
		if img != null:
			img = img.duplicate()
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
	var tierra := PackedByteArray()
	tierra.resize(n)
	var bosque := PackedByteArray()
	bosque.resize(n)
	for iz in FONDO:
		for ix in ANCHO:
			var p2 := D.a_2d(punto(ix, iz))
			var suma := 0.0
			var verde := 0
			for oy in [-1, 0, 1]:                   # 3 × 3 píxeles de la máscara (medio metro cada uno): costa más suave
				for ox in [-1, 0, 1]:
					var c := _pixel(img, int(p2.x * 0.5) + ox, int(p2.y * 0.5) + oy)
					suma += c.a
					if c.a > 0.5 and _es_bosque(c):
						verde += 1
			var i := indice(ix, iz)
			tierra[i] = 1 if suma / 9.0 > 0.5 else 0
			bosque[i] = 1 if verde >= 5 else 0
	var d_mar := _distancias(tierra, 0)          # en tierra: metros hasta el mar
	var d_tierra := _distancias(tierra, 1)       # en el mar: metros hasta la tierra
	var costa := PackedFloat32Array()
	costa.resize(n)
	for i in n:
		costa[i] = d_mar[i] - 0.5 if tierra[i] == 1 else -(d_tierra[i] - 0.5)
	# camino y sitios: cuánto se allana cada punto (0 nada, 1 del todo) y a qué distancia queda del camino
	var d_camino := PackedFloat32Array()
	d_camino.resize(n)
	d_camino.fill(99.0)
	for linea in [D.CAMINO, D.SENDA_CUEVA]:
		for k in linea.size() - 1:
			_distancia_segmento(d_camino, linea[k], linea[k + 1], 9.0)
	var d_senda := PackedFloat32Array()            # la senda del secreto, aparte: se allana menos y casi no se ve
	d_senda.resize(n)
	d_senda.fill(99.0)
	for k in D.SENDA_SECRETA.size() - 1:
		_distancia_segmento(d_senda, D.SENDA_SECRETA[k], D.SENDA_SECRETA[k + 1], 6.0)
	var llano := PackedFloat32Array()
	llano.resize(n)
	for i in n:
		llano[i] = maxf(1.0 - smoothstep(2.0, 7.0, d_camino[i]), (1.0 - smoothstep(1.0, 4.0, d_senda[i])) * 0.7)
	var almohadillas := [["oakhaven", 9.5, 14.0], ["pastos", 6.0, 9.5], ["campamento", 4.5, 7.5], ["portal", 2.5, 5.5],
		["secreto", 3.5, 6.0], ["gran_bosque", 3.0, 6.0]]
	for a in almohadillas:
		var c: Vector2 = D.SITIOS[a[0]]["centro"]
		_allanar_circulo(llano, c, a[1], a[2])
	_allanar_circulo(llano, D.SITIOS["cueva"]["entrada"], 3.0, 5.5)
	# relieve
	var lomas := FastNoiseLite.new()
	lomas.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	lomas.seed = 1511
	lomas.frequency = 0.045
	lomas.fractal_octaves = 3
	var cresta := FastNoiseLite.new()
	cresta.seed = 1512
	cresta.frequency = 0.09
	var forma := FastNoiseLite.new()
	forma.seed = 1513
	forma.frequency = 0.06
	var alturas := PackedFloat32Array()
	alturas.resize(n)
	var monte := PackedFloat32Array()
	monte.resize(n)
	for iz in FONDO:
		for ix in ANCHO:
			var i := indice(ix, iz)
			var p := punto(ix, iz)
			var d: float = costa[i]
			if d <= 0.0:
				alturas[i] = -0.25 - minf(-d, 14.0) * 0.28
				continue
			var base := lerpf(0.16, 0.85, smoothstep(0.0, 7.0, d))
			var l := lomas.get_noise_2dv(p) * 0.5 + 0.5
			var colinas := pow(l, 1.6) * 2.7 * smoothstep(3.0, 14.0, d)
			var m := 0.0
			var deforma := forma.get_noise_2dv(p) * 0.22
			for mo in MONTES:
				var t: float = p.distance_to(mo[0]) / (float(mo[1]) * (1.0 + deforma))
				if t < 1.0:
					var g := pow(smoothstep(0.0, 1.0, 1.0 - t), 1.25)
					var r := 1.0 - absf(cresta.get_noise_2dv(p))
					m = maxf(m, float(mo[2]) * g * (0.62 + 0.38 * r * r))
			m *= smoothstep(1.0, 5.0, d)                 # al llegar al mar, la sierra cae en acantilado
			monte[i] = m
			var ll: float = llano[i]
			alturas[i] = base + colinas * (1.0 - ll) + m * (1.0 - ll * 0.85)
	# el borde de la maqueta baja hacia el mar (fuera de lo andable: solo se ve de lejos)
	for iz in FONDO:
		for ix in ANCHO:
			var b := float(mini(mini(ix, ANCHO - 1 - ix), mini(iz, FONDO - 1 - iz)))
			if b < 4.0:
				var i := indice(ix, iz)
				alturas[i] = minf(alturas[i], lerpf(-2.0, alturas[i], b / 4.0))
	var r := {"alturas": alturas, "tierra": tierra, "bosque": bosque, "costa": costa, "camino": d_camino,
		"senda": d_senda, "llano": llano, "monte": monte}
	r["ms"] = Time.get_ticks_msec() - t0
	return r


static func _pixel(img: Image, x: int, y: int) -> Color:
	if img == null or x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)


static func _es_bosque(c: Color) -> bool:
	var v := Vector3(c.r, c.g, c.b)
	return v.distance_squared_to(Vector3(COLOR_BOSQUE.r, COLOR_BOSQUE.g, COLOR_BOSQUE.b)) \
		< v.distance_squared_to(Vector3(COLOR_LLANURA.r, COLOR_LLANURA.g, COLOR_LLANURA.b))


# Distancia (chaflán 1 / 1,41, dos pasadas) de cada punto con tierra != «origen» al punto más cercano con tierra == «origen».
static func _distancias(tierra: PackedByteArray, origen: int) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(tierra.size())
	for i in tierra.size():
		d[i] = 0.0 if tierra[i] == origen else 1e6
	var r2 := 1.41421
	for iz in FONDO:
		for ix in ANCHO:
			var i := indice(ix, iz)
			var v := d[i]
			if ix > 0: v = minf(v, d[i - 1] + 1.0)
			if iz > 0:
				v = minf(v, d[i - ANCHO] + 1.0)
				if ix > 0: v = minf(v, d[i - ANCHO - 1] + r2)
				if ix < ANCHO - 1: v = minf(v, d[i - ANCHO + 1] + r2)
			d[i] = v
	for iz in range(FONDO - 1, -1, -1):
		for ix in range(ANCHO - 1, -1, -1):
			var i := indice(ix, iz)
			var v := d[i]
			if ix < ANCHO - 1: v = minf(v, d[i + 1] + 1.0)
			if iz < FONDO - 1:
				v = minf(v, d[i + ANCHO] + 1.0)
				if ix < ANCHO - 1: v = minf(v, d[i + ANCHO + 1] + r2)
				if ix > 0: v = minf(v, d[i + ANCHO - 1] + r2)
			d[i] = v
	return d


static func _rango(c: float, r: float, origen: float, cuantos: int) -> Vector2i:
	return Vector2i(clampi(int(floor(c - r - origen)), 0, cuantos - 1), clampi(int(ceil(c + r - origen)), 0, cuantos - 1))


static func _distancia_segmento(d: PackedFloat32Array, a: Vector2, b: Vector2, margen: float) -> void:
	var rx := _rango((a.x + b.x) * 0.5, absf(a.x - b.x) * 0.5 + margen, X0, ANCHO)
	var rz := _rango((a.y + b.y) * 0.5, absf(a.y - b.y) * 0.5 + margen, Z0, FONDO)
	for iz in range(rz.x, rz.y + 1):
		for ix in range(rx.x, rx.y + 1):
			var p := punto(ix, iz)
			var dd := p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
			var i := indice(ix, iz)
			if dd < d[i]:
				d[i] = dd


static func _allanar_circulo(llano: PackedFloat32Array, c: Vector2, dentro: float, fuera: float) -> void:
	var rx := _rango(c.x, fuera, X0, ANCHO)
	var rz := _rango(c.y, fuera, Z0, FONDO)
	for iz in range(rz.x, rz.y + 1):
		for ix in range(rx.x, rx.y + 1):
			var i := indice(ix, iz)
			llano[i] = maxf(llano[i], 1.0 - smoothstep(dentro, fuera, punto(ix, iz).distance_to(c)))


# ================================================================= consultas

# Interpolación bilineal de un campo de la rejilla en (x, z).
static func campo(nombre: String, x: float, z: float) -> float:
	var a: PackedFloat32Array = datos()[nombre]
	var fx := clampf(x - X0, 0.0, ANCHO - 1.001)
	var fz := clampf(z - Z0, 0.0, FONDO - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var i := indice(ix, iz)
	return lerpf(lerpf(a[i], a[i + 1], tx), lerpf(a[i + ANCHO], a[i + ANCHO + 1], tx), tz)


static func altura(x: float, z: float) -> float:
	return campo("alturas", x, z)


static func es_bosque(x: float, z: float) -> bool:
	var ix := clampi(int(round(x - X0)), 0, ANCHO - 1)
	var iz := clampi(int(round(z - Z0)), 0, FONDO - 1)
	return datos()["bosque"][indice(ix, iz)] == 1


# La zona de la máscara (para los encuentros y el fondo del combate, como en el mapa 2D).
static func zona(x: float, z: float) -> String:
	return "bosque" if es_bosque(x, z) else "llanura"


# ================================================================= mallas

static func _normal(alt: PackedFloat32Array, ix: int, iz: int) -> Vector3:
	var l := alt[indice(maxi(ix - 1, 0), iz)]
	var r := alt[indice(mini(ix + 1, ANCHO - 1), iz)]
	var u := alt[indice(ix, maxi(iz - 1, 0))]
	var dn := alt[indice(ix, mini(iz + 1, FONDO - 1))]
	return Vector3(l - r, 2.0, u - dn).normalized()


static func _color(dd: Dictionary, ix: int, iz: int, nrm: Vector3, ruido: float, mancha := 0.0) -> Color:
	var i := indice(ix, iz)
	var h: float = dd["alturas"][i]
	var d: float = dd["costa"][i]
	if d <= 0.0:
		return ARENA.lerp(FONDO_MAR, smoothstep(0.0, 4.0, -d))
	var c := PRADERA.lerp(PRADERA_ALTA, smoothstep(1.2, 3.4, h) * 0.8)
	c = c.lerp(PRADERA_OSCURA, smoothstep(0.1, 0.6, mancha) * 0.55)     # praderas en manchas (se lee el relieve)
	c = c.lerp(PRADERA_SECA, smoothstep(0.2, 0.7, -mancha) * 0.35)
	var fb := 0.0                                     # cuánto bosque hay alrededor (5 × 5 m): el borde, difuminado
	for oz in range(-2, 3):
		for ox in range(-2, 3):
			fb += dd["bosque"][indice(clampi(ix + ox, 0, ANCHO - 1), clampi(iz + oz, 0, FONDO - 1))]
	c = c.lerp(SUELO_BOSQUE, smoothstep(0.0, 1.0, fb / 25.0) * 0.85)
	c = c.lightened(ruido * 0.05) if ruido > 0.0 else c.darkened(-ruido * 0.06)
	var m: float = dd["monte"][i]
	if m > 0.6:
		var roca := ROCA.lerp(ROCA_CLARA, smoothstep(6.0, 11.0, h))
		c = c.lerp(roca, smoothstep(0.6, 3.5, m))
	if nrm.y < 0.82:                                  # ladera empinada o acantilado: tierra y roca
		c = c.lerp(TIERRA if h < 3.0 else ROCA, smoothstep(0.82, 0.62, nrm.y))
	c = c.lerp(ARENA, 1.0 - smoothstep(0.6, 2.2, d))  # la playa
	return c


# Malla del suelo en TROZOS (cada uno, un MeshInstance3D con su caja: Godot no dibuja los que no ve).
static func crear_suelo(padre: Node3D, mat: Material) -> Array:
	if _mallas_suelo.is_empty():                    # se construyen una vez por sesión (medido: ~180 ms en el PC cada vez)
		_mallas_suelo = _construir_suelo()
	var lista: Array = []
	for k in _mallas_suelo.size():
		var mi := MeshInstance3D.new()
		mi.name = "Suelo_%d_%d" % [k % TROZOS.x, k / TROZOS.x]
		mi.mesh = _mallas_suelo[k]
		mi.material_override = mat
		padre.add_child(mi)
		lista.append(mi)
	return lista


static var _mallas_suelo: Array = []


static func _construir_suelo() -> Array:
	var dd := datos()
	var alt: PackedFloat32Array = dd["alturas"]
	var grano := FastNoiseLite.new()
	grano.seed = 1514
	grano.frequency = 0.18
	var manchas := FastNoiseLite.new()
	manchas.seed = 1515
	manchas.frequency = 0.035
	var lista: Array = []
	var cx := (ANCHO - 1) / TROZOS.x
	var cz := (FONDO - 1) / TROZOS.y
	for tz in TROZOS.y:
		for tx in TROZOS.x:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var x0 := tx * cx
			var z0 := tz * cz
			var x1 := ANCHO - 1 if tx == TROZOS.x - 1 else x0 + cx
			var z1 := FONDO - 1 if tz == TROZOS.y - 1 else z0 + cz
			var w := x1 - x0 + 1
			for iz in range(z0, z1 + 1):
				for ix in range(x0, x1 + 1):
					var nrm := _normal(alt, ix, iz)
					var p := punto(ix, iz)
					st.set_color(_color(dd, ix, iz, nrm, grano.get_noise_2dv(p), manchas.get_noise_2dv(p)).srgb_to_linear())
					st.set_normal(nrm)
					st.add_vertex(Vector3(p.x, alt[indice(ix, iz)], p.y))
			for iz in z1 - z0:
				for ix in x1 - x0:
					var a := iz * w + ix
					st.add_index(a)
					st.add_index(a + 1)
					st.add_index(a + w)
					st.add_index(a + 1)
					st.add_index(a + w + 1)
					st.add_index(a + w)
			lista.append(st.commit())
	return lista


# El suelo de la física: las mismas alturas.
static func crear_fisica(padre: Node3D) -> StaticBody3D:
	var dd := datos()
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "SueloFisico"
	var forma := HeightMapShape3D.new()
	forma.map_width = ANCHO
	forma.map_depth = FONDO
	forma.map_data = dd["alturas"]
	var col := CollisionShape3D.new()
	col.shape = forma
	cuerpo.position = Vector3(X0 + (ANCHO - 1) * 0.5, 0.0, Z0 + (FONDO - 1) * 0.5)
	cuerpo.add_child(col)
	padre.add_child(cuerpo)
	return cuerpo


# El agua: una rejilla de 2 m sobre la región (el color del vértice dice lo cerca que está la costa: el sombreado pinta
# el bajío claro, el azul hondo y las olas que llegan a la orilla) y un plano grande alrededor, hondo.
static func crear_agua(padre: Node3D, mat: Material) -> Array:
	var dd := datos()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paso := 2
	var nx := (ANCHO - 1) / paso + 1
	var nz := (FONDO - 1) / paso + 1
	for jz in nz:
		for jx in nx:
			var ix := mini(jx * paso, ANCHO - 1)
			var iz := mini(jz * paso, FONDO - 1)
			var d: float = dd["costa"][indice(ix, iz)]
			var somero := 1.0 - clampf(-d / 14.0, 0.0, 1.0)
			if d > 0.0:
				somero = 1.0
			var borde := minf(minf(jx, nx - 1 - jx), minf(jz, nz - 1 - jz))
			somero *= clampf(borde / 3.0, 0.0, 1.0)      # el borde de la rejilla, hondo como el plano de fuera
			st.set_color(Color(somero, 0, 0))
			st.set_normal(Vector3.UP)
			var p := punto(ix, iz)
			st.add_vertex(Vector3(p.x, 0.0, p.y))
	for jz in nz - 1:
		for jx in nx - 1:
			var a := jz * nx + jx
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	var mi := MeshInstance3D.new()
	mi.name = "Agua"
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	# fuera de la región: un marco de mar hondo (4 tiras) hasta donde llega la bruma
	var lejos := SurfaceTool.new()
	lejos.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a0 := Vector2(X0, Z0)
	var a1 := Vector2(X0 + ANCHO - 1, Z0 + FONDO - 1)
	var m := 220.0
	var b0 := a0 - Vector2(m, m)
	var b1 := a1 + Vector2(m, m)
	for r in [[Vector2(b0.x, b0.y), Vector2(b1.x, a0.y)], [Vector2(b0.x, a1.y), Vector2(b1.x, b1.y)],
			[Vector2(b0.x, a0.y), Vector2(a0.x, a1.y)], [Vector2(a1.x, a0.y), Vector2(b1.x, a1.y)]]:
		var q0: Vector2 = r[0]
		var q1: Vector2 = r[1]
		for v in [Vector2(q0.x, q0.y), Vector2(q1.x, q0.y), Vector2(q0.x, q1.y), Vector2(q1.x, q0.y), Vector2(q1.x, q1.y), Vector2(q0.x, q1.y)]:
			lejos.set_color(Color(0, 0, 0))
			lejos.set_normal(Vector3.UP)
			lejos.add_vertex(Vector3(v.x, 0.0, v.y))
	var ml := MeshInstance3D.new()
	ml.name = "MarLejano"
	ml.mesh = lejos.commit()
	ml.material_override = mat
	ml.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(ml)
	return [mi, ml]


# Una línea suave (Catmull-Rom) que pasa por los puntos, cada «paso» metros.
static func suavizar(puntos: Array, paso := 0.6) -> Array:
	var r: Array = []
	for k in puntos.size() - 1:
		var p0: Vector2 = puntos[maxi(k - 1, 0)]
		var p1: Vector2 = puntos[k]
		var p2: Vector2 = puntos[k + 1]
		var p3: Vector2 = puntos[mini(k + 2, puntos.size() - 1)]
		var n := maxi(1, int(p1.distance_to(p2) / paso))
		for j in n:
			var t := float(j) / n
			var t2 := t * t
			var t3 := t2 * t
			r.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	r.append(puntos[puntos.size() - 1])
	return r


# El camino: una cinta sobre el suelo con el centro claro y los bordes más oscuros (se lee bien desde arriba).
static func cinta_camino(st: SurfaceTool, puntos: Array, ancho: float) -> void:
	var lin := suavizar(puntos)
	for k in lin.size() - 1:
		var a: Vector2 = lin[k]
		var b: Vector2 = lin[k + 1]
		var dir := (b - a).normalized()
		var dir_a: Vector2 = (a - lin[k - 1]).normalized() if k > 0 else dir
		var na := Vector2(-(dir + dir_a).y, (dir + dir_a).x).normalized() * ancho * 0.5
		var dir_b: Vector2 = (lin[k + 2] - b).normalized() if k + 2 < lin.size() else dir
		var nb := Vector2(-(dir + dir_b).y, (dir + dir_b).x).normalized() * ancho * 0.5
		var fila_a := [a - na, a, a + na]
		var fila_b := [b - nb, b, b + nb]
		for s in 2:
			var c0 := CAMINO_BORDE if s == 0 else CAMINO_CENTRO
			var c1 := CAMINO_CENTRO if s == 0 else CAMINO_BORDE
			var v := [[fila_a[s], c0], [fila_b[s], c0], [fila_a[s + 1], c1], [fila_a[s + 1], c1], [fila_b[s], c0], [fila_b[s + 1], c1]]
			for e in v:
				var q: Vector2 = e[0]
				st.set_color((e[1] as Color).srgb_to_linear())
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(q.x, altura(q.x, q.y) + 0.07 + (0.008 if ancho > 1.0 else 0.0), q.y))
