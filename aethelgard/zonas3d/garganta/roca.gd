extends RefCounted
# Mallas de roca de la Garganta 3D, hechas por código: rejillas (filas de puntos) con normales suaves y color por
# vértice. Las usan escenario.gd y piezas.gd. Sin SurfaceTool vértice a vértice: arrays empaquetados (más rápido al
# cargar en el móvil).
#
# Convención de Godot: una cara se ve por delante si sus vértices van en el sentido de las agujas del reloj vistos desde
# delante, o sea, si cross(p1 − p0, p2 − p0) apunta hacia DETRÁS. Cada rejilla recibe hacia dónde debe mirar («hacia») y
# orienta sus triángulos y normales para que se vean desde ese lado.

const Materiales := preload("res://zonas3d/garganta/materiales.gd")


# Malla de una rejilla: «filas» es un Array de PackedVector3Array, todas del mismo tamaño. «colorear» recibe
# (posición, normal) y devuelve el color del vértice (alfa = musgo). «hacia»: lado visible (aproximado).
static func rejilla(filas: Array, colorear: Callable, hacia: Vector3) -> ArrayMesh:
	var nf := filas.size()
	if nf < 2:
		return null
	var nc: int = (filas[0] as PackedVector3Array).size()
	var pos := PackedVector3Array()
	pos.resize(nf * nc)
	for i in nf:
		var f: PackedVector3Array = filas[i]
		for j in nc:
			pos[i * nc + j] = f[j]
	# orientación, con el primer cuadro que no esté degenerado: n = dv × du. Si n mira hacia «hacia», la cara de delante
	# es (a, d, c) y la normal, dv × du; si no, (a, b, c) y du × dv.
	var signo := 1.0
	var hallado := false
	for i in nf - 1:
		for j in nc - 1:
			var a := pos[i * nc + j]
			var n := (pos[i * nc + j + 1] - a).cross(pos[(i + 1) * nc + j] - a)
			if n.length_squared() > 0.000001:
				signo = -1.0 if n.dot(hacia) > 0.0 else 1.0
				hallado = true
				break
		if hallado:
			break
	var nor := PackedVector3Array()
	nor.resize(nf * nc)
	for i in nf:
		for j in nc:
			var du := pos[mini(i + 1, nf - 1) * nc + j] - pos[maxi(i - 1, 0) * nc + j]
			var dv := pos[i * nc + mini(j + 1, nc - 1)] - pos[i * nc + maxi(j - 1, 0)]
			var n := du.cross(dv) * signo
			nor[i * nc + j] = n.normalized() if n.length_squared() > 0.0000001 else hacia.normalized()
	var col := PackedColorArray()
	col.resize(nf * nc)
	for k in nf * nc:
		col[k] = colorear.call(pos[k], nor[k])
	var idx := PackedInt32Array()
	idx.resize((nf - 1) * (nc - 1) * 6)
	var w := 0
	for i in nf - 1:
		for j in nc - 1:
			var a := i * nc + j
			var b := i * nc + j + 1
			var c := (i + 1) * nc + j + 1
			var d := (i + 1) * nc + j
			if signo < 0.0:                                  # (a, d, c) y (a, c, b)
				idx[w] = a; idx[w + 1] = d; idx[w + 2] = c
				idx[w + 3] = a; idx[w + 4] = c; idx[w + 5] = b
			else:                                            # (a, b, c) y (a, c, d)
				idx[w] = a; idx[w + 1] = b; idx[w + 2] = c
				idx[w + 3] = a; idx[w + 4] = c; idx[w + 5] = d
			w += 6
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


# ---------------------------------------------------------------- ruido

static var _r: FastNoiseLite


static func r() -> FastNoiseLite:
	if _r == null:
		_r = FastNoiseLite.new()
		_r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_r.seed = 9001
		_r.frequency = 1.0
		_r.fractal_octaves = 1
	return _r


static func n2(a: float, b: float) -> float:
	return r().get_noise_2d(a, b)


static func n3(a: float, b: float, c: float) -> float:
	return r().get_noise_3d(a, b, c)


# Cuánto se mete la roca hacia dentro en (u, y): bultos grandes, estratos (escalones cada 2,5-4 m) y grano. Siempre ≥ 0:
# la roca nunca sale hacia el aire más allá de su línea base (así nunca se mete en el camino ni en la cámara).
static func hundido(u: float, y: float, semilla: float, fuerza := 1.0) -> float:
	var bulto := 1.4 * (0.5 + 0.5 * n2(u * 0.045 + semilla, y * 0.05)) + 0.5 * (0.5 + 0.5 * n2(u * 0.16, y * 0.18 + semilla))
	# estratos: cada capa sale abajo y se mete arriba (una cornisita y una ranura cada 2,5-4 m)
	var capa := y / (2.6 + 0.9 * (0.5 + 0.5 * n2(semilla, u * 0.01))) + 0.35 * n2(u * 0.03, semilla)
	var f := capa - floorf(capa)
	var estrato := (pow(f, 2.2) * 0.85 + 0.35 * smoothstep(0.9, 1.0, f)) * (0.7 + 0.3 * n2(u * 0.08, y * 0.02 + semilla))
	# grietas verticales (diaclasas): un surco estrecho de vez en cuando
	var junta := 0.45 * smoothstep(0.82, 0.97, absf(n2(u * 0.22 + semilla * 3.0, y * 0.012)))
	var grano := 0.12 * (0.5 + 0.5 * n2(u * 0.7, y * 0.7 + semilla))
	return (bulto + estrato + junta + grano) * fuerza


# ---------------------------------------------------------------- color de la roca

# Color de un vértice de roca según dónde está: estratos de ocre y violeta, manchas grandes, más oscura al pie de los
# muros (oclusión) y, más abajo, el shader la tiñe de niebla y la enciende de ámbar. Alfa = musgo (solo en lo que mira
# hacia arriba, lo decide el shader).
static func color_roca(p: Vector3, n: Vector3, musgo := 0.35, base_y := -1000.0) -> Color:
	var c: Color = Materiales.ROCA
	# estratos: capas de 2-4 m con tonos distintos (ocre, gris, oscura), algo onduladas
	var b := n2(p.y * 0.31 + 0.3 * n2(p.x * 0.04, p.z * 0.04), 7.0)
	c = c.lerp(Materiales.ROCA_OCRE, smoothstep(0.15, 0.7, b) * 0.7)
	c = c.lerp(Materiales.ROCA_OSCURA, smoothstep(-0.2, -0.75, b) * 0.55)
	c = c.lerp(Materiales.ROCA_VIOLETA, smoothstep(0.35, 0.9, n2(p.y * 0.12, 31.0)) * 0.35)
	# chorreones verticales (agua que ha bajado por la pared) y manchas grandes
	var veta := n2((p.x + p.z) * 0.32, p.y * 0.022)
	c = c.darkened(0.2 * smoothstep(0.25, 0.8, veta))
	var mancha := n2(p.x * 0.05 + 3.0, p.z * 0.05 - p.y * 0.03)
	c = c.darkened(0.1 * maxf(mancha, 0.0)).lightened(0.06 * maxf(-mancha, 0.0))
	if base_y > -999.0:                                     # al pie del muro, más oscura (oclusión)
		c = c.darkened(0.38 * (1.0 - smoothstep(0.0, 2.2, p.y - base_y)))
	var m := musgo * clampf(0.55 + 0.6 * n2(p.x * 0.11, p.z * 0.11), 0.0, 1.0)
	return Color(c.r, c.g, c.b, m)


# Suelo de una cornisa: roca y gravilla, la senda pisada más clara y oscuro junto al muro y al borde.
static func color_suelo(p: Vector3, x_muro: float, x_borde: float, x_senda: float, senda: float) -> Color:
	var c := Color(0.45, 0.425, 0.41).lerp(Color(0.50, 0.45, 0.39), 0.5 + 0.5 * n2(p.x * 0.3, p.z * 0.3))
	c = c.darkened(0.12 * maxf(0.0, n2(p.x * 0.9, p.z * 0.9)))
	var ds := absf(p.x - x_senda)
	c = c.lerp(Color(0.58, 0.54, 0.48), (1.0 - smoothstep(senda * 0.4, senda, ds)) * 0.5)
	var dm := absf(p.x - x_muro)
	c = c.darkened(0.4 * (1.0 - smoothstep(0.0, 2.4, dm)))
	var db := absf(p.x - x_borde)
	c = c.darkened(0.15 * (1.0 - smoothstep(0.0, 1.0, db)))
	var musgo := clampf(0.1 + 0.9 * n2(p.x * 0.17 + 9.0, p.z * 0.17), 0.0, 1.0) * smoothstep(senda * 0.6, senda * 1.6, ds)
	return Color(c.r, c.g, c.b, musgo * 0.7)


# ---------------------------------------------------------------- piezas genéricas

# Cortina vertical de roca a lo largo de una línea (pared, acantilado, cara de un hueco). «base(u)» → punto del pie
# (x, z; la y no cuenta), «normal(u)» → dirección horizontal hacia el aire. De y0 a y1. «hundir(u, y)» → metros hacia
# dentro (≥ 0). «colorear(p, n)».
static func cortina(base: Callable, normal: Callable, u0: float, u1: float, du: float, y0: float, y1: float, dy: float,
		hundir: Callable, colorear: Callable, sombra_hueco := 0.16) -> ArrayMesh:
	var filas: Array = []
	var hondos := {}                                         # posición → cuánto se hunde (oscurece los huecos)
	var nu := maxi(1, ceili((u1 - u0) / du))
	var ny := maxi(1, ceili((y1 - y0) / dy))
	var hacia := Vector3.ZERO
	for i in nu + 1:
		var u := lerpf(u0, u1, float(i) / nu)
		var b: Vector3 = base.call(u)
		var nh: Vector3 = normal.call(u)
		nh.y = 0.0
		nh = nh.normalized()
		hacia += nh
		var f := PackedVector3Array()
		f.resize(ny + 1)
		for j in ny + 1:
			var y := lerpf(y0, y1, float(j) / ny)
			var d: float = hundir.call(u, y)
			f[j] = Vector3(b.x, y, b.z) - nh * d
			hondos[f[j]] = d
		filas.append(f)
	# lo que se mete más hacia dentro, más oscuro: la roca se lee en volumen aunque no haya sombras (perfil bajo)
	var con_hueco := func(p: Vector3, n: Vector3) -> Color:
		var c: Color = colorear.call(p, n)
		var d: float = hondos.get(p, 0.0)
		var k := clampf((d - 0.6) * sombra_hueco, 0.0, 0.42)
		return Color(c.r * (1.0 - k), c.g * (1.0 - k), c.b * (1.0 - k), c.a)
	return rejilla(filas, con_hueco, hacia)


# Suelo de una franja a lo largo de z: de x_a(z) a x_b(z), altura «alto(x, z)». «fin_ini(x)» y «fin_fin(x)» (opcionales)
# dan la z real de cada extremo en x (bordes rotos); las filas de dentro se reparten entre los dos.
static func franja(x_a: Callable, x_b: Callable, z0: float, z1: float, dz: float, columnas: int, alto: Callable,
		colorear: Callable, fin_ini := Callable(), fin_fin := Callable()) -> ArrayMesh:
	var filas: Array = []
	var nz := maxi(1, ceili(absf(z1 - z0) / dz))
	for i in nz + 1:
		var t := float(i) / nz
		var z := lerpf(z0, z1, t)
		var xa: float = x_a.call(z)
		var xb: float = x_b.call(z)
		var f := PackedVector3Array()
		f.resize(columnas + 1)
		for j in columnas + 1:
			var x := lerpf(xa, xb, float(j) / columnas)
			var zz := z
			if fin_ini.is_valid():
				zz += (1.0 - t) * (float(fin_ini.call(x)) - z0)
			if fin_fin.is_valid():
				zz += t * (float(fin_fin.call(x)) - z1)
			f[j] = Vector3(x, alto.call(x, zz), zz)
		filas.append(f)
	return rejilla(filas, colorear, Vector3.UP)


# Disco (o elipse) de suelo con el borde irregular: anillos desde el centro. «radio(a)» → radio en el ángulo a.
static func disco(centro: Vector3, radio: Callable, anillos: int, lados: int, alto: Callable, colorear: Callable) -> ArrayMesh:
	var filas: Array = []
	for i in lados + 1:
		var a := TAU * float(i) / lados
		var rr: Vector2 = radio.call(a)
		var f := PackedVector3Array()
		f.resize(anillos + 1)
		for j in anillos + 1:
			var k := float(j) / anillos
			var x := centro.x + cos(a) * rr.x * k
			var z := centro.z + sin(a) * rr.y * k
			f[j] = Vector3(x, alto.call(x, z), z)
		filas.append(f)
	return rejilla(filas, colorear, Vector3.UP)


# Columna de roca (el pilar de la arena, la aguja del paso bajo, la peña del nido): anillos de y0 a y1, con el radio
# de cada altura y hundida con ruido.
static func columna(centro: Vector3, radio: Callable, y0: float, y1: float, dy: float, lados: int, semilla: float,
		colorear: Callable) -> ArrayMesh:
	var filas: Array = []
	var ny := maxi(1, ceili((y1 - y0) / dy))
	for i in lados + 1:
		var a := TAU * float(i) / lados
		var dir := Vector3(cos(a), 0.0, sin(a))
		var f := PackedVector3Array()
		f.resize(ny + 1)
		for j in ny + 1:
			var y := lerpf(y0, y1, float(j) / ny)
			var rr: Vector2 = radio.call(y, a)
			var d := hundido(a * 6.0, y, semilla, 0.55)
			f[j] = Vector3(centro.x + dir.x * maxf(0.3, rr.x - d), y, centro.z + dir.z * maxf(0.3, rr.y - d))
		filas.append(f)
	# «hacia» no sirve para una columna (mira a todos lados): se orienta con el primer cuadro, que mira hacia +x
	return rejilla(filas, colorear, Vector3(1, 0, 0))


# ---------------------------------------------------------------- lotes (una malla por material)

# Junta piezas que no se mueven y comparten material en una sola malla (una llamada de dibujo).
class Lotes:
	var _st := {}

	func poner(malla: Mesh, t: Transform3D, mat: Material) -> void:
		if not _st.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_st[mat] = st
		_st[mat].append_from(malla, 0, t)

	# Como poner(), con un color en todos los vértices (cada tabla de un puente, su tono). Un lote lleva siempre color
	# en todos sus vértices o en ninguno: los materiales que se usan aquí no se mezclan con poner().
	func poner_color(malla: Mesh, t: Transform3D, mat: Material, color: Color) -> void:
		if not _st.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_st[mat] = st
		var st: SurfaceTool = _st[mat]
		var a: Array = malla.surface_get_arrays(0)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var nb := t.basis.inverse().transposed()
		var orden: PackedInt32Array = idx
		if orden.is_empty():
			orden.resize(v.size())
			for i in v.size():
				orden[i] = i
		for i in orden:
			st.set_color(color)
			st.set_normal((nb * n[i]).normalized())
			st.add_vertex(t * v[i])

	func cerrar(padre: Node3D, sombra := true) -> Array:
		var hechas: Array = []
		for mat in _st:
			var mi := MeshInstance3D.new()
			mi.mesh = _st[mat].commit()
			mi.material_override = mat
			var transparente: bool = mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
			if not sombra or transparente:                   # los halos y lo que brilla no dan sombra
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			padre.add_child(mi)
			hechas.append(mi)
		_st.clear()
		return hechas


# Una caja que choca (cuerpo estático con su forma) y se dibuja en un lote.
static func caja(lotes: Lotes, padre: Node3D, pos: Vector3, tam: Vector3, mat: Material, giro := Vector3.ZERO, choca := true) -> void:
	var bm := BoxMesh.new()
	bm.size = tam
	lotes.poner(bm, Transform3D(Basis.from_euler(giro), pos), mat)
	if choca:
		var cuerpo := StaticBody3D.new()
		cuerpo.position = pos
		cuerpo.rotation = giro
		padre.add_child(cuerpo)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = tam
		col.shape = bs
		cuerpo.add_child(col)


# Malla con su colisión (suelos que se pisan). «forma»: la colisión ya hecha (escenario.gd la lee de su caché); si no
# viene, se calcula aquí.
static func con_suelo(padre: Node3D, malla: ArrayMesh, mat: Material, forma: Shape3D = null) -> MeshInstance3D:
	var cuerpo := StaticBody3D.new()
	padre.add_child(cuerpo)
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	if forma == null:
		forma = malla.create_trimesh_shape()
		(forma as ConcavePolygonShape3D).backface_collision = true
	col.shape = forma
	cuerpo.add_child(col)
	return mi


static func dibujar(padre: Node3D, malla: Mesh, mat: Material, sombra := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	if not sombra:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi
