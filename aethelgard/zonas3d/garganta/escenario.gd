extends RefCounted
# Escenario de la Garganta del Diablo 3D: la roca (muros, cornisas, acantilados, presa, arena, nido), el abismo (niebla,
# fondo de ámbar, haces de luz, cascada) y el decorado (losas de la Vía del Peregrino, hierba seca, pinos, raíces,
# faroles, cristales de ámbar, piedras, aves). Lo que se usa (palanca, ascensor, puentes, puerta, cofre…) está en
# piezas.gd. Todo se genera por código y sale igual cada vez (semillas fijas).
#
# Presupuesto (perfil bajo, Redmi A7 Pro): una sola malla de roca por trozo y un solo material de roca; lo pequeño que
# se repite, en lotes y MultiMesh; transparencias pocas y estrechas (una capa de niebla en bajo); luces reales solo en
# el perfil alto. Lo que cambia con el perfil son cantidades y resolución, nunca la paleta ni la composición.

const T := preload("res://zonas3d/garganta/trazado.gd")
const Roca := preload("res://zonas3d/garganta/roca.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")

var region: Node3D
var mat: Materiales
var perfil: Dictionary
var nombre_perfil := "alto"
var lotes: Roca.Lotes
var du := 1.0                    # paso de las rejillas de roca a lo largo (m)
var dy := 1.0                    # paso en altura (m)
var dz_suelo := 0.75             # paso de los suelos
var polvo: CPUParticles3D        # motas que siguen a Kael (la región lo mueve)
var mallas_roca := 0             # para el informe y las pruebas
var triangulos := 0

# Cantidades por perfil (bajo, medio, alto)
const RESOLUCION := {"bajo": [1.15, 1.2, 0.8], "medio": [0.9, 0.95, 0.6], "alto": [0.65, 0.7, 0.5]}
const NIEBLAS := {"bajo": [[-33.0, 0.48]], "medio": [[-19.0, 0.26], [-33.0, 0.4]],
	"alto": [[-17.5, 0.24], [-27.0, 0.3], [-38.0, 0.42]]}
const HACES := {"bajo": 3, "medio": 5, "alto": 7}
const HIERBA := {"bajo": 520, "medio": 950, "alto": 1600}
const POLVO := {"bajo": 22, "medio": 40, "alto": 70}
const BRASAS := {"bajo": 14, "medio": 30, "alto": 60}
const AVES := {"bajo": 3, "medio": 4, "alto": 5}
# La luz del cielo: entra por la rendija desde el este y algo del sur, muy alta. Ilumina la pared del oeste (el fondo del
# camino de arriba) y deja en sombra la del este (la del camino de abajo, más misterioso).
const SOL_GIRO := Vector3(-58.0, 72.0, 0.0)


func _init(r: Node3D, m: Materiales, p: Dictionary, nombre: String) -> void:
	region = r
	mat = m
	perfil = p
	nombre_perfil = nombre if RESOLUCION.has(nombre) else "alto"
	var res: Array = RESOLUCION[nombre_perfil]
	du = res[0]
	dy = res[1]
	dz_suelo = res[2]
	lotes = Roca.Lotes.new()


func construir() -> void:
	seed(9133)                                        # la escena sale siempre igual: comparaciones justas
	for paso in [_muros, _cornisas, _huecos, _presa_y_boca, _arena, _aguja_paso_bajo, _repisa_nido, _muro_norte, _abismo,
			_cascada, _caida_del_puente, _entrada, _losas, _helechos, _senda_baja, _helechos_bajos, _piedras_sueltas,
			_hierba_seca, _pinos, _raices, _faroles_peregrino, _cristales, _mojones, _campamento]:
		_medido(paso)
	_medido(func(): lotes.cerrar(region))
	for paso in [_haces, _particulas, _aves]:
		_medido(paso)


# Cuánto tarda cada paso de la construcción, en ms (pruebas/medir_garganta3d.gd lo apunta con «conteo»).
var tiempos := {}


func _medido(paso: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	paso.call()
	var nombre := String(paso.get_method())
	if nombre == "" or nombre.begins_with("<"):
		nombre = "lotes_cerrar"
	tiempos[nombre] = float(tiempos.get(nombre, 0.0)) + (Time.get_ticks_usec() - t0) / 1000.0


# ================================================================= roca

func _roca(malla: ArrayMesh, suelo := false, brillo := 1.0, forma: Shape3D = null) -> MeshInstance3D:
	if malla == null:
		return null
	mallas_roca += 1
	triangulos += malla.surface_get_array_index_len(0) / 3 if malla.get_surface_count() > 0 else 0
	var m: Material = mat.roca(brillo)
	if suelo:
		return Roca.con_suelo(region, malla, m, forma)
	return Roca.dibujar(region, malla, m)


# Roca guardada (T-102, optimización de la carga): la primera vez que se entra en la Garganta con un perfil, cada malla
# de roca (y la colisión de los suelos) se genera y se guarda en user://cache_garganta/; las siguientes veces se lee de
# ahí, sin generarla ni calcular la colisión. Es solo una copia: si falta o no se puede leer, se genera como siempre.
# SUBE VERSION_CACHE si cambia la forma o el color de la roca (trazado.gd, roca.gd o las llamadas de este archivo).
const VERSION_CACHE := "t102c"
const DIR_CACHE := "user://cache_garganta"
var usar_cache := not Engine.has_meta("garganta_sin_cache")   # la medida de antes y después puede apagarla
var _n_roca := 0                  # cuántas mallas de roca van (la clave de cada una en la caché)
var leidas_de_cache := 0          # cuántas se leyeron de la caché (pruebas y medida)


func _roca_c(generar: Callable, suelo := false, brillo := 1.0) -> MeshInstance3D:
	var base := "%s/%s_%s_%02d" % [DIR_CACHE, VERSION_CACHE, nombre_perfil, _n_roca]
	_n_roca += 1
	var malla: ArrayMesh = null
	var forma: Shape3D = null
	if usar_cache and ResourceLoader.exists(base + ".res") and (not suelo or ResourceLoader.exists(base + "_choque.res")):
		malla = ResourceLoader.load(base + ".res", "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		if suelo and malla != null:
			forma = ResourceLoader.load(base + "_choque.res", "", ResourceLoader.CACHE_MODE_IGNORE) as Shape3D
			if forma == null:
				malla = null
	if malla != null:
		leidas_de_cache += 1
		return _roca(malla, suelo, brillo, forma)
	malla = generar.call()
	if malla == null:
		return null
	if suelo:
		forma = malla.create_trimesh_shape()
		(forma as ConcavePolygonShape3D).backface_collision = true
	if usar_cache:
		DirAccess.make_dir_recursive_absolute(DIR_CACHE)
		ResourceSaver.save(malla, base + ".res", ResourceSaver.FLAG_COMPRESS)
		if suelo:
			ResourceSaver.save(forma, base + "_choque.res", ResourceSaver.FLAG_COMPRESS)
	return _roca(malla, suelo, brillo, forma)


func _color_muro(base_y: float, musgo := 0.25) -> Callable:
	return func(p: Vector3, n: Vector3) -> Color: return Roca.color_roca(p, n, musgo, base_y)


# Cuánto se hunde un acantilado bajo el borde de su cornisa: nada en el labio (se junta con el suelo), y luego se mete.
static func _hundir_acantilado(u: float, y: float, arriba: float, semilla: float) -> float:
	var k := smoothstep(arriba + 0.05, arriba - 1.4, y)
	return k * (0.6 + Roca.hundido(u, y, semilla, 0.85))


func _muros() -> void:
	var tope := T.TOPE
	# muro del oeste: el fondo del camino de arriba, de punta a punta
	_roca_c(func(): return Roca.cortina(func(u): return Vector3(T.muro_oeste(u), 0, u), func(_u): return Vector3.RIGHT,
		T.Z_NORTE - 3.0, T.Z_SUR, du, T.ALTO - 0.6, tope, dy,
		func(u, y): return Roca.hundido(u, y, 13.0), _color_muro(T.ALTO)))
	# muro del este: el fondo del camino de abajo (al sur de la cornisa baja, baja hasta la hondonada de la boca)
	_roca_c(func(): return Roca.cortina(func(u): return Vector3(T.muro_este(u), 0, u), func(_u): return Vector3.LEFT,
		T.Z_NORTE - 3.0, T.Z_CORNISA_E + 0.5, du, T.BAJO - 0.6, tope, dy,
		func(u, y): return Roca.hundido(u, y, 29.0), _color_muro(T.BAJO)))
	_roca_c(func(): return Roca.cortina(func(u): return Vector3(T.muro_este(u), 0, u), func(_u): return Vector3.LEFT,
		T.Z_CORNISA_E - 0.5, T.Z_SUR, du, T.Y_BOCA - 1.5, tope, dy,
		func(u, y): return Roca.hundido(u, y, 29.0), _color_muro(T.Y_BOCA)))


func _cornisas() -> void:
	# cornisa alta, a trozos (los huecos de los puentes no tienen suelo)
	var columnas := 10 if nombre_perfil == "bajo" else 13
	var alto := func(x: float, z: float) -> float: return T.altura(x, z)
	var color_o := func(p: Vector3, _n: Vector3) -> Color: return Roca.color_suelo(p, T.muro_oeste(p.z), T.borde_oeste(p.z), T.X_CAMINO_O, 1.4)
	# (el último tramo sigue bajo la arena, que va algo más alta: así no queda ningún agujero entre las dos). Junto a los
	# huecos de los puentes, el borde está roto (trazado.gd, borde_hueco).
	var h0: Array = T.HUECOS[0]
	var h1: Array = T.HUECOS[1]
	var sur_h0 := func(x: float) -> float: return T.borde_hueco(x, h0[1], 1.0)
	var norte_h0 := func(x: float) -> float: return T.borde_hueco(x, h0[0], -1.0)
	var sur_h1 := func(x: float) -> float: return T.borde_hueco(x, h1[1], 1.0)
	var norte_h1 := func(x: float) -> float: return T.borde_hueco(x, h1[0], -1.0)
	for tramo in [[56.0, h0[1], Callable(), sur_h0], [h0[0], h1[1], norte_h0, sur_h1], [h1[0], -28.0, norte_h1, Callable()]]:
		_roca_c(func(): return Roca.franja(func(z): return T.muro_oeste(z) - 1.0, func(z): return T.borde_oeste(z), tramo[0], tramo[1],
			dz_suelo, columnas, alto, color_o, tramo[2], tramo[3]), true)
	# acantilados bajo la cornisa alta (hacia el abismo, o hacia la hondonada de la boca)
	for tramo in [[56.0, T.Z_PRESA_S, T.Y_BOCA - 1.5], [T.Z_PRESA_N + 0.3, T.HUECOS[0][1], T.HONDO],
			[T.HUECOS[0][0], T.HUECOS[1][1], T.HONDO], [T.HUECOS[1][0], T.PASO_PUERTA[0] - 1.5, T.HONDO]]:
		_roca_c(func(): return Roca.cortina(func(u): return Vector3(T.borde_oeste(u), 0, u), func(_u): return Vector3.RIGHT,
			tramo[1], tramo[0], du, tramo[2], T.ALTO + 0.06, dy,
			func(u, y): return _hundir_acantilado(u, y, T.ALTO + 0.06, 41.0), _color_muro(-1000.0, 0.45)))
	# cornisa baja
	var color_e := func(p: Vector3, _n: Vector3) -> Color: return Roca.color_suelo(p, T.muro_este(p.z), T.borde_este(p.z), T.X_CAMINO_E, 1.2)
	_roca_c(func(): return Roca.franja(func(z): return T.borde_este(z), func(z): return T.muro_este(z) + 1.0, T.Z_CORNISA_E, T.GRIETA[0] - 0.5,
		dz_suelo, columnas, alto, color_e), true)
	for tramo in [[T.Z_CORNISA_E + 0.4, T.Z_PRESA_S, T.Y_BOCA - 1.5], [T.Z_PRESA_N + 0.3, T.GRIETA[0] - 0.5, T.HONDO]]:
		_roca_c(func(): return Roca.cortina(func(u): return Vector3(T.borde_este(u), 0, u), func(_u): return Vector3.LEFT,
			tramo[1], tramo[0], du, tramo[2], T.BAJO + 0.06, dy,
			func(u, y): return _hundir_acantilado(u, y, T.BAJO + 0.06, 67.0), _color_muro(-1000.0, 0.45)))
	# cara sur del final de la cornisa baja (se ve desde la entrada)
	_roca_c(func(): return Roca.cortina(func(u): return Vector3(u, 0, T.Z_CORNISA_E), func(_u): return Vector3.BACK,
		T.borde_este(T.Z_CORNISA_E) - 0.4, T.muro_este(T.Z_CORNISA_E) + 0.5, du, T.Y_BOCA - 1.5, T.BAJO + 0.06, dy,
		func(u, y): return _hundir_acantilado(u, y, T.BAJO + 0.06, 3.0), _color_muro(-1000.0, 0.3)))


# Los huecos de los puentes colgantes: el muro del oeste baja hasta el fondo y se ve la cara sur del borde de enfrente.
func _huecos() -> void:
	for h in T.HUECOS:
		_roca_c(func(): return Roca.cortina(func(u): return Vector3(T.muro_oeste(u), 0, u), func(_u): return Vector3.RIGHT,
			h[0] - 0.8, h[1] + 0.8, du, T.HONDO, T.ALTO - 0.4, dy,
			func(u, y): return Roca.hundido(u, y, 13.0), _color_muro(-1000.0, 0.2)))
		var zn: float = h[0]
		_roca_c(func(): return Roca.cortina(func(u): return Vector3(u, 0, T.borde_hueco(u, zn, -1.0)), func(_u): return Vector3.BACK,
			T.muro_oeste(zn) - 1.2, T.borde_oeste(zn) + 0.6, du * 0.8, T.HONDO, T.ALTO + 0.06, dy,
			func(u, y): return _hundir_acantilado(u, y, T.ALTO + 0.06, zn), _color_muro(-1000.0, 0.45)))


# La presa del sur: cierra el abismo y lleva la escalera tallada de la cornisa alta a la baja. Al sur, la hondonada de
# la boca de la garganta, con piedras sueltas, que se pierde en la niebla.
func _presa_y_boca() -> void:
	var x0 := T.X_BORDE_O
	var huella := (T.X_BORDE_E - T.X_BORDE_O) / T.ESCALONES
	var z0: float = T.ESCALERA_Z[0]
	var z1: float = T.ESCALERA_Z[1]
	# T-102: sillares con su tono (cada escalón y cada bloque del pretil, distinto; musgo en lo alto del pretil del abismo)
	# en vez de una piedra lisa y lila. Mismas cajas y misma colisión que antes.
	var ls := Roca.Lotes.new()
	var sillar := mat.detalle(Color.WHITE, 0.9, 0.8).duplicate() as StandardMaterial3D
	sillar.vertex_color_use_as_albedo = true
	var tono := func(base: Color) -> Color:
		var c := base * randf_range(0.86, 1.08)
		return c.lerp(Color(0.60, 0.50, 0.38), randf_range(0.0, 0.35))
	for k in T.ESCALONES:
		var arriba := T.ALTO - 0.4 * (k + 1)
		var x := x0 + huella * (k + 0.5)
		var g := randf_range(-0.02, 0.02)
		_sillar(ls, sillar, Vector3(x, arriba - 0.6, (z0 + z1) * 0.5), Vector3(huella + 0.04, 1.2, z1 - z0), Vector3(0, g, 0),
			tono.call(Color(0.56, 0.53, 0.49)))
		# pretiles: al norte (el abismo) y al sur (la presa); en el del abismo, una albardilla con musgo
		_sillar(ls, sillar, Vector3(x, arriba + 0.1, z0 - 0.45), Vector3(huella + 0.05, 1.4 + 0.5, 0.9), Vector3.ZERO,
			tono.call(Color(0.47, 0.45, 0.46)))
		var albardilla := BoxMesh.new()
		albardilla.size = Vector3(huella + 0.07, 0.08, 0.96)
		ls.poner_color(albardilla, Transform3D(Basis(), Vector3(x, arriba + 1.09, z0 - 0.45)), sillar,
			Color(0.47, 0.45, 0.46).lerp(Materiales.MUSGO * 1.15, randf_range(0.15, 0.45)))
		_sillar(ls, sillar, Vector3(x, arriba - 0.2, z1 + 1.0), Vector3(huella + 0.05, 1.4 + 0.2, 2.0), Vector3.ZERO,
			tono.call(Color(0.47, 0.45, 0.46)))
	for mi in ls.cerrar(region):
		mi.name = "EscaleraDeLaPresa"
	# cara sur de la presa: de la hondonada a la altura de cada escalón
	var filas: Array = []
	var nx := ceili((T.X_BORDE_E - T.X_BORDE_O + 1.0) / du)
	for i in nx + 1:
		var x := lerpf(T.X_BORDE_O - 0.5, T.X_BORDE_E + 0.5, float(i) / nx)
		var k := clampi(int((x - x0) / huella), 0, T.ESCALONES - 1)
		var tope := T.ALTO - 0.4 * (k + 1) - 0.25
		var f := PackedVector3Array()
		var ny := 10
		for j in ny + 1:
			var y := lerpf(T.Y_BOCA - 1.5, tope, float(j) / ny)
			f.append(Vector3(x, y, T.Z_PRESA_S + 0.05 - Roca.hundido(x, y, 7.0, 0.5) * smoothstep(tope, tope - 1.2, y)))
		filas.append(f)
	_roca_c(func(): return Roca.rejilla(filas, _color_muro(T.Y_BOCA, 0.2), Vector3.BACK))
	# la hondonada de la boca (no se pisa): piedras sueltas que bajan hacia el sur
	var alto_boca := func(x: float, z: float) -> float:
		return T.Y_BOCA - 0.06 * (z - T.Z_PRESA_S) + 0.7 * Roca.n2(x * 0.15, z * 0.15) + 0.25 * Roca.n2(x * 0.6, z * 0.6)
	_roca_c(func(): return Roca.franja(func(z): return T.borde_oeste(z) + 0.2, func(z): return T.muro_este(z) + 1.0, T.Z_SUR, T.Z_PRESA_S - 0.4,
		1.2, 14, alto_boca, func(p: Vector3, n: Vector3) -> Color: return Roca.color_roca(p, n, 0.6)))
	var suelta := mat.detalle(Color(0.42, 0.40, 0.43), 0.8, 0.9)
	for k in 26:
		var p := Vector3(randf_range(T.X_BORDE_O + 1.0, T.X_BORDE_E + 6.0), 0, randf_range(T.Z_PRESA_S + 1.5, 60.0))
		p.y = alto_boca.call(p.x, p.z)
		_piedra(p, randf_range(0.3, 1.1), suelta)


func _arena() -> void:
	var c := T.ARENA
	var rr := func(a: float) -> Vector2:
		var r := T.ARENA_RADIO * (1.0 + 0.035 * Roca.n2(cos(a) * 3.0, sin(a) * 3.0))
		return Vector2(r, r)
	var alto := func(x: float, z: float) -> float:
		var d := Vector2(x - c.x, z - c.z).length() / T.ARENA_RADIO
		return T.ALTO + T.ARENA_ALTO - 0.06 * d * d + 0.03 * Roca.n2(x * 1.3, z * 1.3)
	var colorea := func(p: Vector3, _n: Vector3) -> Color:          # la tierra entre las losas: oscura
		var d := Vector2(p.x - c.x, p.z - c.z).length() / T.ARENA_RADIO
		var col := Color(0.34, 0.31, 0.30).lerp(Color(0.40, 0.35, 0.31), 0.5 + 0.5 * Roca.n2(p.x * 0.4, p.z * 0.4))
		col = col.lerp(Color(0.36, 0.18, 0.15), 0.4 * smoothstep(0.4, 0.0, d))     # manchas oscuras junto al trono
		return Color(col.r, col.g, col.b, 0.3)
	var lados := 40 if nombre_perfil == "bajo" else 64
	_roca_c(func(): return Roca.disco(c, rr, 9, lados, alto, colorea), true)
	# el enlosado de la vieja arena de los peregrinos (T-102): dovelas en anillos, como un gran círculo de piedra, algunas
	# rotas o arrancadas y teñidas de rojo junto al trono; en el centro, el anillo partido de bronce embutido en el suelo.
	# Antes, losas hexagonales sueltas. En cuatro cuartos (lo que la cámara no ve no se dibuja), sin colisión (el suelo
	# es la roca).
	var rng := RandomNumberGenerator.new()
	rng.seed = 3131
	var cuartos: Array = []
	for q in 4:
		var sq := SurfaceTool.new()
		sq.begin(Mesh.PRIMITIVE_TRIANGLES)
		cuartos.append(sq)
	var tramos_arco := 2 if nombre_perfil == "bajo" else 3
	var anillo := 1.25
	var ancho_anillo := 0.92
	while anillo < T.ARENA_RADIO - 0.75:
		var n := maxi(6, roundi(TAU * anillo / 1.0))
		var giro := rng.randf() * TAU
		for k in n:
			if rng.randf() < 0.06:
				continue
			var a0 := giro + TAU * k / n + 0.025 / anillo * 1.5
			var a1 := giro + TAU * (k + 1) / n - 0.025 / anillo * 1.5
			var r0 := anillo - ancho_anillo * 0.5 + 0.03
			var r1 := anillo + ancho_anillo * 0.5 - 0.03
			var g := rng.randf_range(0.46, 0.58)
			var rojo := 0.2 * smoothstep(4.0, 0.0, anillo) * rng.randf()
			var col := Color(g + rojo, g * 0.95 - rojo * 0.3, g * 0.89 - rojo * 0.4)
			if rng.randf() < 0.15:
				col = col.lerp(Materiales.MUSGO * 1.2, rng.randf_range(0.2, 0.4))
			var sube := rng.randf_range(0.0, 0.025)
			var cuarto := clampi(floori(wrapf((a0 + a1) * 0.5, 0.0, TAU) / (PI * 0.5)), 0, 3)
			_dovela(cuartos[cuarto], c, alto, a0, a1, r0, r1, tramos_arco, 0.05 + sube, col)
		anillo += ancho_anillo
	for q in 4:
		var sq: SurfaceTool = cuartos[q]
		sq.generate_normals()
		var mi := MeshInstance3D.new()
		mi.mesh = sq.commit()
		mi.material_override = mat.sillar()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.name = "EnlosadoDeLaArena%d" % q
		region.add_child(mi)
	var sello: ArrayMesh = load("res://zonas3d/garganta/piezas.gd").anillo_partido(0.62, 0.07, 40.0, 30, 6)
	lotes.poner(sello, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(c.x, alto.call(c.x, c.z) + 0.03, c.z)), mat.bronce())
	# el pilar de roca que la sostiene sobre el abismo
	var radio := func(y: float, a: float) -> Vector2:
		var k := smoothstep(T.HONDO, T.ALTO, y)
		var r := T.ARENA_RADIO * lerpf(0.62, 0.99, k) * (1.0 + 0.05 * Roca.n2(a * 2.0, y * 0.1))
		return Vector2(r, r)
	_roca_c(func(): return Roca.columna(c, radio, T.HONDO, T.ALTO + T.ARENA_ALTO - 0.04, dy * 1.3, lados, 5.0, _color_muro(-1000.0, 0.4)))
	# bordillo de piedra en la mitad que da al abismo (T-102: cada piedra con su tono, algunas con musgo)
	var lb := Roca.Lotes.new()
	for i in 22:
		var a := lerpf(-1.25, 1.35, float(i) / 21.0)       # del sur al norte por el este
		var p := c + Vector3(cos(a), 0, sin(a)) * (T.ARENA_RADIO - 0.35)
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 0.36 + rng.randf_range(-0.04, 0.05), 1.18)
		lb.poner_color(bm, Transform3D(Basis.from_euler(Vector3(0, -a, 0)), Vector3(p.x, T.ALTO + T.ARENA_ALTO + 0.12, p.z)),
			mat.sillar(), Materiales.tono_piedra(Color(0.50, 0.48, 0.47), rng))
	for m in lb.cerrar(region):
		m.name = "BordilloDeLaArena"


# La aguja de roca junto al paso bajo: esconde la entrada de la grieta.
func _aguja_paso_bajo() -> void:
	var centro := Vector3(7.7, 0, (T.PASO_BAJO[0] + T.PASO_BAJO[1]) * 0.5 + 0.5)
	var radio := func(y: float, a: float) -> Vector2:
		var k := smoothstep(5.0, -14.0, y)
		return Vector2(lerpf(0.55, 1.6, k), lerpf(0.8, 2.3, k)) * (1.0 + 0.1 * Roca.n2(a * 3.0, y * 0.2))
	_roca_c(func(): return Roca.columna(centro, radio, T.HONDO, 5.4, dy, 16, 23.0, _color_muro(-1000.0, 0.3)))


# La repisa del nido, en el abismo bajo P6, sobre una peña; y la escalera tallada que baja hasta ella.
func _repisa_nido() -> void:
	var c := T.NIDO_CENTRO
	var rr := func(a: float) -> Vector2:
		return T.NIDO_RADIOS * (1.0 + 0.07 * Roca.n2(cos(a) * 2.0 + 40.0, sin(a) * 2.0))
	var alto := func(x: float, z: float) -> float:
		var d := Vector2((x - c.x) / T.NIDO_RADIOS.x, (z - c.z) / T.NIDO_RADIOS.y).length()
		return T.NIDO + 0.1 * Roca.n2(x * 0.8, z * 0.8) - 0.25 * smoothstep(0.85, 1.0, d)
	_roca_c(func(): return Roca.disco(c, rr, 7, 36, alto, func(p: Vector3, n: Vector3) -> Color: return Roca.color_roca(p, n, 0.5)), true, 1.0)
	var radio := func(y: float, a: float) -> Vector2:
		var k := smoothstep(-34.0, T.NIDO, y)
		return T.NIDO_RADIOS * lerpf(0.25, 0.97, k * k)
	_roca_c(func(): return Roca.columna(c, radio, -34.0, T.NIDO - 0.08, dy, 28, 61.0, _color_muro(-1000.0, 0.3)))
	# piedras en el borde de la repisa (fuera de donde se anda y lejos de la llegada de la escalera)
	var gris := mat.detalle(Color(0.40, 0.38, 0.40), 0.8, 0.9)
	var llegada := atan2(T.VUELTA_NIDO.z - c.z, T.VUELTA_NIDO.x - c.x)
	for k in 10:
		var a := TAU * k / 10.0 + 0.2
		if absf(wrapf(a - llegada, -PI, PI)) < 0.7:
			continue
		var p := c + Vector3(cos(a) * T.NIDO_RADIOS.x * 0.93, 0, sin(a) * T.NIDO_RADIOS.y * 0.93)
		p.y = T.NIDO - 0.1
		_piedra(p, randf_range(0.35, 0.8), gris)
	# escalera: el rellano de arriba (al nivel de la cornisa baja) y 16 peldaños hacia el norte (T-102: sillares con su
	# tono, como la escalera de la presa; misma colisión)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4040
	var ls := Roca.Lotes.new()
	var sillar := mat.sillar()
	var x0: float = T.BAJADA_X[0]
	var x1: float = T.BAJADA_X[1]
	_sillar(ls, sillar, Vector3((x0 + T.X_BORDE_E + 1.0) * 0.5, T.BAJO - 2.0, (T.BAJADA_RELLANO[0] + T.BAJADA_RELLANO[1]) * 0.5),
		Vector3(T.X_BORDE_E + 1.0 - x0, 4.0, T.BAJADA_RELLANO[1] - T.BAJADA_RELLANO[0]), Vector3.ZERO,
		Materiales.tono_piedra(Color(0.54, 0.51, 0.48), rng))
	var z_arriba: float = T.BAJADA_Z[1]
	var z_abajo: float = T.BAJADA_Z[0]
	var huella := (z_arriba - z_abajo) / T.BAJADA_PELDANOS
	var subida := (T.BAJO - T.NIDO) / T.BAJADA_PELDANOS
	for k in T.BAJADA_PELDANOS:
		var arriba := T.BAJO - subida * (k + 1)
		var z := z_arriba - huella * (k + 0.5)
		var fondo := T.NIDO - 2.5
		_sillar(ls, sillar, Vector3((x0 + x1) * 0.5, (arriba + fondo) * 0.5, z), Vector3(x1 - x0, arriba - fondo, huella + 0.03), Vector3.ZERO,
			Materiales.tono_piedra(Color(0.54, 0.51, 0.48), rng))
	# pretil del lado del abismo, inclinado como la escalera (el eje z local, hacia el sur y hacia arriba)
	for k in 8:
		var z := z_arriba - (z_arriba - z_abajo) * (k + 0.5) / 8.0
		var arriba := T.BAJO - (T.BAJO - T.NIDO) * (k + 0.5) / 8.0
		var pb := BoxMesh.new()
		pb.size = Vector3(0.36, 0.9, (z_arriba - z_abajo) / 8.0 + 0.04)
		ls.poner_color(pb, Transform3D(Basis.from_euler(Vector3(-atan2(T.BAJO - T.NIDO, z_arriba - z_abajo), 0, 0)),
			Vector3(x0 - 0.18, arriba + 0.3, z)), sillar, Materiales.tono_piedra(Color(0.47, 0.45, 0.46), rng))
	for m in ls.cerrar(region):
		m.name = "BajadaAlNido"


func _muro_norte() -> void:
	_roca_c(func(): return Roca.cortina(func(u): return Vector3(u, 0, T.Z_NORTE), func(_u): return Vector3.BACK,
		-22.0, 22.0, du, T.HONDO, T.TOPE, dy, func(u, y): return Roca.hundido(u, y, 51.0, 1.2), _color_muro(-1000.0, 0.15)))


# ================================================================= el abismo

func _abismo() -> void:
	# el fondo: un mar de ámbar muy abajo
	var pm := PlaneMesh.new()
	pm.size = Vector2(34.0, 80.0)
	var fondo := MeshInstance3D.new()
	fondo.mesh = pm
	fondo.material_override = mat.fondo()
	fondo.position = Vector3(0.0, T.HONDO + 0.6, -6.0)
	fondo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	region.add_child(fondo)
	# capas de niebla (la de más arriba, fría; las de abajo, teñidas por el ámbar)
	var capas: Array = NIEBLAS[nombre_perfil]
	for i in capas.size():
		var y: float = capas[i][0]
		var a: float = capas[i][1]
		# arriba, niebla fría y azulada; abajo, encendida por el ámbar del fondo (la profundidad se lee por el color)
		var tibia := smoothstep(-18.0, -38.0, y)
		var color := Color(0.50, 0.54, 0.68).lerp(Color(0.98, 0.58, 0.26), tibia)
		var nm := MeshInstance3D.new()
		var q := PlaneMesh.new()                                 # también bajo los huecos de los puentes (x < −8)
		q.size = Vector2(T.X_BORDE_E - T.X_MURO_O + 4.0, T.Z_PRESA_N - T.Z_NORTE + 4.0)
		nm.mesh = q
		nm.material_override = mat.niebla(Color(color, a))
		nm.position = Vector3((T.X_MURO_O + T.X_BORDE_E) * 0.5, y, (T.Z_PRESA_N + T.Z_NORTE) * 0.5)
		nm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nm.name = "Niebla%d" % i
		region.add_child(nm)


# Haces de luz que caen de la rendija del cielo en la dirección del sol.
func _haces() -> void:
	var dir := Basis.from_euler(SOL_GIRO * PI / 180.0) * Vector3.FORWARD     # hacia donde va la luz
	var arriba := -dir.normalized()
	var x_eje := arriba.cross(Vector3.BACK).normalized()
	var z_eje := x_eje.cross(arriba).normalized()
	var base := Basis(x_eje, arriba, z_eje)
	var sitios := [[24.0, 2.8, 0.09], [6.0, 3.6, 0.08], [-9.0, 2.4, 0.1], [14.0, 2.0, 0.07], [-24.0, 3.2, 0.08],
		[-34.0, 2.4, 0.09], [32.0, 2.4, 0.07]]
	for i in mini(HACES[nombre_perfil], sitios.size()):
		var s: Array = sitios[i]
		var largo := 52.0
		var q := QuadMesh.new()
		q.size = Vector2(s[1], largo)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = mat.haz(Color(Materiales.LUZ_CIELO, s[2]))
		var cima := Vector3(T.X_MURO_E - 2.0, T.TOPE, s[0])           # entra por el borde del este
		mi.transform = Transform3D(base, cima - arriba * largo * 0.5)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(mi)


# La cascada del fondo: cae del borde del muro del norte al abismo, junto a la arena.
func _cascada() -> void:
	var m := mat.cascada()
	var capas := [[3.4, 6.0, 0.6, 3.2]] if nombre_perfil == "bajo" else [[3.4, 6.0, 0.6, 3.2], [2.2, 4.2, 1.0, 3.8]]
	for capa in capas:
		var arriba := Vector3(3.6, T.TOPE - 1.0, T.Z_NORTE + capa[2])
		var abajo := Vector3(3.6, -44.0, T.Z_NORTE + capa[3])
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tramos := 8
		for k in tramos:
			for e in [[0, 0], [1, 0], [0, 1], [1, 0], [1, 1], [0, 1]]:
				var t := float(k + e[1]) / tramos
				var ancho: float = lerpf(capa[0], capa[1], t)
				var p := arriba.lerp(abajo, t) + Vector3((e[0] - 0.5) * ancho, 0, 0)
				p.z += sin(t * PI) * 0.6                               # se separa un poco de la pared al caer
				st.set_uv(Vector2(e[0], t))
				st.add_vertex(p)
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(mi)
	# espuma donde el agua sale del borde
	var espuma := mat.brillo(Color(0.86, 0.92, 1.0), 0.95)
	for k in 5:
		var s := SphereMesh.new()
		s.radius = randf_range(0.5, 0.9)
		s.height = s.radius * 1.2
		s.radial_segments = 8
		s.rings = 4
		lotes.poner(s, Transform3D(Basis(), Vector3(3.6 + randf_range(-1.6, 1.6), T.TOPE - 1.2, T.Z_NORTE + 0.8)), espuma)


# ================================================================= decorado

# Un campamento Grimfang en la cornisa de abajo (los goblins de los encuentros al azar): hoguera con rescoldos, troncos
# para sentarse, un cobertizo de pieles contra el muro y huesos.
func _campamento() -> void:
	var c := Vector3(12.7, 0, 4.2)
	c.y = T.altura(c.x, c.z)
	var piedra := mat.detalle(Color(0.35, 0.33, 0.35), 0.9, 0.9)
	for k in 9:
		var a := TAU * k / 9.0
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.14, 0.2)
		sm.height = sm.radius * 1.4
		sm.radial_segments = 7
		sm.rings = 4
		lotes.poner(sm, Transform3D(Basis(), c + Vector3(cos(a) * 0.62, 0.08, sin(a) * 0.62)), piedra)
	var ceniza := CylinderMesh.new()
	ceniza.top_radius = 0.5
	ceniza.bottom_radius = 0.52
	ceniza.height = 0.04
	ceniza.radial_segments = 12
	lotes.poner(ceniza, Transform3D(Basis(), c + Vector3(0, 0.02, 0)), mat.liso(Color(0.12, 0.11, 0.11), 1.0))
	var quemado := mat.liso(Color(0.14, 0.10, 0.08), 1.0)
	for k in 3:
		var t := CylinderMesh.new()
		t.top_radius = 0.06
		t.bottom_radius = 0.07
		t.height = 0.8
		t.radial_segments = 6
		lotes.poner(t, Transform3D(Basis.from_euler(Vector3(PI * 0.5, TAU * k / 3.0, 0.15)), c + Vector3(0, 0.1, 0)), quemado)
	var rescoldo := mat.brillo(Color(1.0, 0.42, 0.14), 1.2)
	for k in 6:
		var sm := SphereMesh.new()
		sm.radius = 0.035
		sm.height = 0.06
		sm.radial_segments = 5
		sm.rings = 3
		lotes.poner(sm, Transform3D(Basis(), c + Vector3(randf_range(-0.25, 0.25), 0.07, randf_range(-0.25, 0.25))), rescoldo)
	halo(c, c + Vector3(0, 0.3, 0), Color(1.0, 0.45, 0.18), 2.2, 0.8)
	var tronco := mat.madera_vieja()
	for datos in [[Vector3(-0.2, 0.17, 1.25), 0.3], [Vector3(0.9, 0.17, -0.95), 1.1]]:
		var t := CylinderMesh.new()
		t.top_radius = 0.17
		t.bottom_radius = 0.18
		t.height = 1.2
		t.radial_segments = 8
		lotes.poner(t, Transform3D(Basis.from_euler(Vector3(0, datos[1], PI * 0.5)), c + datos[0]), tronco)
	# cobertizo de pieles contra el muro
	var x_muro := T.muro_este(c.z) - 0.6
	for dz in [-0.9, 0.9]:
		var palo := CylinderMesh.new()
		palo.top_radius = 0.04
		palo.bottom_radius = 0.05
		palo.height = 2.3
		palo.radial_segments = 5
		lotes.poner(palo, Transform3D(Basis(Vector3.BACK, 0.55), Vector3(x_muro - 0.55, c.y + 0.95, c.z + 2.4 + dz)), tronco)
	var piel := QuadMesh.new()
	piel.size = Vector2(2.0, 2.0)
	lotes.poner(piel, Transform3D(Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, -0.55), Vector3(x_muro - 0.5, c.y + 1.0, c.z + 2.4)),
		mat.tela(Color(0.40, 0.28, 0.20)))
	var hueso := mat.hueso()
	for k in 5:
		var cap := CapsuleMesh.new()
		cap.radius = 0.04
		cap.height = randf_range(0.3, 0.55)
		cap.radial_segments = 6
		cap.rings = 2
		lotes.poner(cap, Transform3D(Basis.from_euler(Vector3(PI * 0.5, randf() * TAU, 0)), c + Vector3(randf_range(-1.6, 1.0), 0.05, randf_range(-1.8, 1.6))), hueso)


# La Vía del Peregrino por el camino de arriba (T-102): adoquines irregulares y gastados, bien juntos por el centro y
# sueltos en los bordes (faltan algunos: los arrancaron), con tierra y musgo entre ellos. Cuatro formas de piedra en
# MultiMesh (una llamada de dibujo por forma). Antes eran losas hexagonales sueltas (09/11, fase 1).
func _losas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	var formas: Array = []
	var mlosa := mat.detalle(Color.WHITE, 1.3, 1.0).duplicate() as StandardMaterial3D
	mlosa.vertex_color_use_as_albedo = true
	for k in 4:
		var malla := _adoquin(rng, 7 if nombre_perfil == "bajo" else 9)
		malla.surface_set_material(0, mlosa)
		formas.append(malla)
	var puestos: Array = [[], [], [], []]
	var z := 45.0
	var fila := 0
	while z > T.PASO_PUERTA[0] + 0.5:
		var en_puente := z <= T.PUENTES[0][0] + 0.3 and z >= T.PUENTES[1][1] - 0.3 and not (z < T.ISLOTE[1] - 0.6 and z > T.ISLOTE[0] + 0.6)
		if not T.en_hueco(z) and not en_puente:
			var centro: float = T.X_CAMINO_O + 0.4 * sin(z * 0.11)
			var desfase := 0.22 if fila % 2 == 0 else 0.0
			var x := -1.15 + desfase
			while x < 1.15:
				var borde := absf(x) / 1.15                            # 0 en el centro, 1 en el borde
				if rng.randf() > 0.06 + 0.5 * pow(borde, 3.0):
					var p := Vector3(centro + x + rng.randf_range(-0.05, 0.05), 0, z + rng.randf_range(-0.05, 0.05))
					puestos[rng.randi() % 4].append([p, rng.randf_range(0.82, 1.12), borde])
				x += 0.44
		z -= 0.42
		fila += 1
	for k in 4:
		var lista: Array = puestos[k]
		var piezas: Array = []
		for i in lista.size():
			var p: Vector3 = lista[i][0]
			var e: float = lista[i][1]
			var hundido: float = lista[i][2] * 0.03                     # en los bordes, más hundidos en la tierra
			var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, rng.randf_range(0.85, 1.2), e * rng.randf_range(0.9, 1.1))),
				Vector3(p.x, T.altura(p.x, p.z) - hundido, p.z))
			var g := rng.randf_range(0.5, 0.66)                         # piedra clara y gastada: la senda se lee desde lejos
			var c := Color(g, g * 0.96, g * 0.89)
			if rng.randf() < 0.18:                                      # algunas, verdosas de musgo
				c = c.lerp(Color(0.40, 0.46, 0.30), rng.randf_range(0.3, 0.6))
			elif rng.randf() < 0.15:                                    # otras, más ocres
				c = c.lerp(Color(0.62, 0.52, 0.40), 0.5)
			piezas.append([t, c])
		_por_tramos("Adoquines%d" % k, formas[k], piezas)


# Un adoquín: polígono irregular de «lados» lados (unos 0,4 m), con la cara de arriba algo abombada y el canto biselado.
func _adoquin(rng: RandomNumberGenerator, lados: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radios: Array = []
	for i in lados:
		radios.append(0.2 * rng.randf_range(0.78, 1.12))
	var arriba := 0.045
	var canto := 0.03
	var cima := Vector3(rng.randf_range(-0.02, 0.02), arriba + 0.02, rng.randf_range(-0.02, 0.02))
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var r0: float = radios[i]
		var r1: float = radios[(i + 1) % lados]
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var in0 := d0 * (r0 - canto) + Vector3(0, arriba, 0)       # borde de la cara de arriba
		var in1 := d1 * (r1 - canto) + Vector3(0, arriba, 0)
		var out0 := d0 * r0 + Vector3(0, arriba - canto, 0)         # bisel
		var out1 := d1 * r1 + Vector3(0, arriba - canto, 0)
		var pie0 := d0 * r0 * 1.04 + Vector3(0, -0.06, 0)          # metido en la tierra
		var pie1 := d1 * r1 * 1.04 + Vector3(0, -0.06, 0)
		for v in [cima, in0, in1, in0, out1, in1, in0, out0, out1, out0, pie1, out1, out0, pie0, pie1]:   # caras delanteras en sentido horario (Godot)
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# Peña de la cornisa: roca facetada (ruido sobre una esfera, con la base plana) con el sombreado de la roca, así que
# lleva sus vetas y el musgo encima (canal alfa del color). Antes eran esferas grises. Se hacen 6 formas una vez y cada
# peña es una de ellas, girada y escalada (antes se hacía cada una desde cero: 50-100 ms de la carga).
const FORMAS_PENA := 6
var _formas_pena: Array = []


func _piedra(p: Vector3, r: float, _m: Material) -> void:
	if _formas_pena.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 6060
		for i in FORMAS_PENA:
			_formas_pena.append(_forma_pena(rng))
	var forma: ArrayMesh = _formas_pena[randi() % FORMAS_PENA]
	var escala := Vector3(randf_range(1.0, 1.4), randf_range(0.6, 0.9), randf_range(0.9, 1.25)) * r
	var b := (Basis(Vector3.UP, randf() * TAU) * Basis.from_euler(Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.12, 0.12)))).scaled(escala)
	lotes.poner(forma, Transform3D(b, p + Vector3(0, r * 0.12, 0)), mat.roca())


# Una forma de peña de radio 1, con caras planas, su tono de roca (algo ocre, violeta u oscura) y musgo arriba.
func _forma_pena(rng: RandomNumberGenerator) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 9 if nombre_perfil == "bajo" else 12
	sm.rings = 5 if nombre_perfil == "bajo" else 7
	var a: Array = sm.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var semilla := rng.randf() * 100.0
	var base := Roca.color_roca(Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(-8.0, 2.0), rng.randf_range(-30.0, 40.0)),
		Vector3.UP, 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var puntos := PackedVector3Array()
	puntos.resize(v.size())
	for i in v.size():
		var q: Vector3 = v[i]
		var k := 1.0 + 0.22 * Roca.n3(q.x * 1.6 + semilla, q.y * 1.6, q.z * 1.6) + 0.08 * Roca.n3(q.x * 4.0, q.y * 4.0 + semilla, q.z * 4.0)
		q *= k
		q.y = maxf(q.y, -0.25)                                     # base plana: asienta en el suelo
		puntos[i] = q
	for i in idx:                                                  # sin compartir vértices: caras planas (roca tallada)
		var w: Vector3 = puntos[i]
		var arriba := clampf(w.y + 0.12, 0.0, 1.0)
		var c := base.darkened(0.12 * clampf(-w.y, 0.0, 1.0))
		st.set_color(Color(c.r, c.g, c.b, clampf(0.25 + 0.75 * arriba, 0.0, 1.0)))
		st.add_vertex(w)
	st.generate_normals()
	return st.commit()


# Piedras en las cornisas, lejos de la senda (junto al muro y al borde).
func _piedras_sueltas() -> void:
	var gris := mat.detalle(Color(0.44, 0.42, 0.46), 0.8, 0.9)
	var hecho := 0
	var intentos := 0
	while hecho < 34 and intentos < 400:
		intentos += 1
		var arriba := randf() < 0.55
		var z := randf_range(-20.0, 44.0) if arriba else randf_range(-37.0, 34.0)
		var x: float
		if arriba:
			if T.en_hueco(z) or absf(z - T.ASCENSOR_Z) < 2.5 or (z > 27.0 and z < 32.0):
				continue
			x = lerpf(T.muro_oeste(z) + 0.5, T.borde_oeste(z), [0.08, 0.15, 0.85, 0.92][randi() % 4])
		else:
			if absf(z - T.ASCENSOR_Z) < 2.5 or absf(z - T.PALANCA.z) < 2.5 or absf(z - T.LEVADIZO_Z) < 2.5 or (z > 17.0 and z < 22.0):
				continue
			x = lerpf(T.borde_este(z), T.muro_este(z) - 0.4, [0.08, 0.86, 0.93][randi() % 3])
		_piedra(Vector3(x, T.altura(x, z), z), randf_range(0.25, 0.75), gris)
		hecho += 1


# Hierba seca en matas, al pie de los muros y junto a los bordes (en trozos: lo que no ve la cámara no se dibuja).
func _hierba_seca() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := k * PI / 3.0
		var d := Vector3(cos(a), 0, sin(a)) * 0.06
		st.set_normal(Vector3.UP)
		st.add_vertex(-d)
		st.add_vertex(d)
		st.add_vertex(Vector3(0, 0.45, 0) + d * 0.2)
	var hoja := st.commit()
	hoja.surface_set_material(0, mat.hierba())
	var hoja_verde := hoja.duplicate() as ArrayMesh            # T-102: matas verdes donde hay humedad
	hoja_verde.surface_set_material(0, mat.hierba_verde())
	var trozos := {}
	var n: int = HIERBA[nombre_perfil]
	var intentos := 0
	var puestos := 0
	while puestos < n and intentos < n * 5:
		intentos += 1
		var arriba := randf() < 0.6
		var z := randf_range(-21.0, 50.0) if arriba else randf_range(-37.5, 34.5)
		var a := T.muro_oeste(z) + 0.4 if arriba else T.borde_este(z)
		var b := T.borde_oeste(z) if arriba else T.muro_este(z) - 0.3
		if arriba and T.en_hueco(z):
			continue
		var t := randf()
		t = t * t * 0.32 if randf() < 0.6 else 1.0 - t * t * 0.22          # pegada al muro o al borde
		if not arriba:
			t = 1.0 - t
		var x := lerpf(a, b, t)
		var centro := Vector3(x, 0, z)
		var verde := arriba and z > 6.0 and (absf(z - CAIDA_Z) < 8.0 or (t < 0.32 and randf() < 0.45))
		var clave := Vector3i(floori(z / 14.0), 1 if arriba else 0, 1 if verde else 0)
		if not trozos.has(clave):
			trozos[clave] = []
		for m in randi_range(3, 7):
			var p := centro + Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))
			p.y = T.altura(p.x, p.z)
			trozos[clave].append(p)
			puestos += 1
	for clave in trozos:
		var puntos: Array = trozos[clave]
		var c: Vector3 = puntos[0]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = hoja_verde if clave.z == 1 else hoja
		mm.instance_count = puntos.size()
		for k in puntos.size():
			var p: Vector3 = puntos[k]
			var e := randf_range(0.6, 1.3)
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(e, e * randf_range(0.8, 1.4), e)), p - c))
			var tono := randf_range(0.8, 1.1)
			mm.set_instance_color(k, Color(tono, tono * randf_range(0.92, 1.0), tono * 0.9))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = c
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 46.0
		region.add_child(mmi)


# Pinos que se agarran a las cornisas (algunos secos), como los de la Garganta 2D.
func _pinos() -> void:
	var tronco := mat.madera_vieja()
	var hojas := mat.detalle(Color(0.17, 0.27, 0.22), 0.7, 0.5)
	var hojas_claras := mat.detalle(Color(0.24, 0.35, 0.26), 0.7, 0.5)
	# junto a los muros (nunca delante de la cámara de la entrada); los secos, con ramas peladas
	var sitios := [[-14.5, 24.5, false], [-14.6, 33.0, true], [-14.5, -3.5, false], [-14.4, -15.4, true], [14.0, 32.6, false],
		[13.5, 9.0, true], [13.4, -1.0, false], [13.6, -15.8, false], [9.6, -35.0, true]]
	for s in sitios:
		var p := Vector3(s[0], 0, s[1])
		p.y = T.altura(p.x, p.z)
		var alto := randf_range(3.6, 5.4)
		# se inclinan hacia el abismo, buscando la luz
		var hacia_luz := 1.0 if p.x < 0.0 else -1.0
		var b := Basis.from_euler(Vector3(randf_range(-0.08, 0.08), randf() * TAU, 0.0))
		b = Basis(Vector3.BACK, -hacia_luz * randf_range(0.08, 0.18)) * b
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.2
		cm.height = alto
		cm.radial_segments = 7
		lotes.poner(cm, Transform3D(b, p + b * Vector3(0, alto * 0.5, 0)), tronco)
		if s[2]:                                     # seco: unas ramas peladas
			for k in 6:
				var r := CylinderMesh.new()
				r.top_radius = 0.015
				r.bottom_radius = 0.045
				r.height = randf_range(0.7, 1.3) * (1.0 - k * 0.1)
				r.radial_segments = 5
				var a := randf() * TAU
				var rb := b * Basis.from_euler(Vector3(cos(a) * 1.15, 0, sin(a) * 1.15))
				lotes.poner(r, Transform3D(rb, p + b * Vector3(0, alto * lerpf(0.4, 0.9, k / 5.0), 0) + rb * Vector3(0, r.height * 0.5, 0)), tronco)
			continue
		var pisos := 5
		for k in pisos:
			var t := float(k) / (pisos - 1)
			var cono := CylinderMesh.new()
			cono.top_radius = 0.0
			cono.bottom_radius = lerpf(1.35, 0.45, t) * randf_range(0.9, 1.1)
			cono.height = lerpf(1.25, 0.9, t)
			cono.radial_segments = 9
			cono.rings = 1
			var gb := b * Basis(Vector3.UP, randf() * TAU) * Basis.from_euler(Vector3(randf_range(-0.08, 0.08), 0, randf_range(-0.08, 0.08)))
			lotes.poner(cono, Transform3D(gb, p + b * Vector3(0, alto * lerpf(0.36, 0.92, t) + 0.25, 0)), hojas_claras if k % 2 else hojas)


# Raíces y lianas secas colgando de los muros, cerca de los caminos.
func _raices() -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.035
	cm.bottom_radius = 0.012
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	cm.material = mat.liso(Color(0.24, 0.20, 0.16), 1.0)
	var lista: Array = []
	for k in 46:
		var este := k % 2 == 1
		var z := randf_range(-36.0, 36.0)
		var base_y := (T.BAJO if este else T.ALTO) + randf_range(2.5, 9.0)
		# justo delante de la cara del muro (la roca se hunde hacia dentro: Roca.hundido, como en _muros)
		var x := (T.muro_este(z) + Roca.hundido(z, base_y, 29.0) - 0.2) if este else (T.muro_oeste(z) - Roca.hundido(z, base_y, 13.0) + 0.2)
		var largo := randf_range(1.6, 5.0)
		var b := Basis.from_euler(Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.12, 0.12))).scaled(Vector3(1, largo, 1))
		lista.append(Transform3D(b, Vector3(x, base_y - largo * 0.5, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = lista.size()
	for k in lista.size():
		mm.set_instance_transform(k, lista[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	region.add_child(mmi)


# Faroles de piedra de los peregrinos en el camino de arriba: la luz cálida guía (halo pintado; luz real en el alto).
var luces_reales := 0


func _faroles_peregrino() -> void:
	var sitios := [Vector3(-14.7, 0, 39.5), Vector3(-14.7, 0, 29.0), Vector3(-14.6, 0, 0.6),
		Vector3(-14.8, 0, -11.0), Vector3(-13.9, 0, -17.0), Vector3(14.0, 0, 26.0), Vector3(14.1, 0, 4.0),
		Vector3(14.0, 0, -12.5)]
	for p in sitios:
		var abajo: bool = p.x > 0.0
		p.y = T.altura(p.x, p.z)
		farol(p, abajo)


func farol(p: Vector3, tosco := false) -> void:
	var piedra := mat.piedra_tallada() if not tosco else mat.piedra()
	Roca.caja(lotes, region, p + Vector3(0, 0.55, 0), Vector3(0.34, 1.1, 0.34), piedra)
	Roca.caja(lotes, region, p + Vector3(0, 1.32, 0), Vector3(0.5, 0.14, 0.5), piedra, Vector3.ZERO, false)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.24, 0.26, 0.24)
	lotes.poner(bm, Transform3D(Basis(), p + Vector3(0, 1.15, 0)), mat.brillo(Materiales.FUEGO, 1.25))
	halo(p, p + Vector3(0, 1.15, 0), Materiales.FUEGO, 4.2, 1.3)
	llama_en(p + Vector3(0, 1.55, 0), 0.36, p.z)                 # T-102: la llama, viva, sobre la caperuza
	if p.x < 0.0 and p.z > 15.0:                                 # los del primer tramo tiñen la roca de al lado
		mat.poner_fuego(p + Vector3(0, 1.3, 0), 4.5)
	if perfil.get("luces_faroles", false) and luces_reales < 4:
		luces_reales += 1
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.7, 0.4)
		o.light_energy = 1.1
		o.omni_range = 5.0
		o.position = p + Vector3(0, 1.3, 0)
		region.add_child(o)
		luces.append(o)


# Halo falso (como los faroles de Pastos Verdes): disco de luz en el suelo y resplandor en el aire. Los discos van en el
# lote de su color (una llamada de dibujo para todos; suman color, así que el orden no importa). «en» = el lote que
# toca (el de piezas.gd, si lo pide una pieza).
func halo(suelo: Vector3, aire: Vector3, color: Color, ancho := 4.0, tam_aire := 1.2, en: Roca.Lotes = null) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(ancho, ancho)
	(en if en != null else lotes).poner(pm, Transform3D(Basis(), suelo + Vector3(0, 0.1, 0)), mat.halo_suelo(color))
	var q := QuadMesh.new()
	q.size = Vector2(tam_aire, tam_aire)
	var brillo := MeshInstance3D.new()
	brillo.mesh = q
	brillo.material_override = mat.halo_aire(color)
	brillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	brillo.position = aire
	region.add_child(brillo)


# Cristales de ámbar: brotan de la roca junto al abismo y en los acantilados (lo que brilla en el fondo sube hasta aquí).
func _cristales() -> void:
	var m := mat.cristal_ambar()
	var sitios := [Vector3(7.6, T.BAJO, 25.2), Vector3(8.0, T.BAJO, 6.2), Vector3(7.8, T.BAJO, -16.5), Vector3(13.9, T.BAJO, -27.0),
		Vector3(-7.0, -18.0, 16.0), Vector3(-6.4, -26.0, -2.0), Vector3(6.0, -22.0, -8.0), Vector3(5.8, -30.0, 20.0),
		Vector3(-6.0, -33.0, -18.0), Vector3(5.5, -15.5, -28.0), Vector3(-3.4, T.NIDO, 9.4), Vector3(5.6, T.NIDO, 3.6)]
	for i in sitios.size():
		var c: Vector3 = sitios[i]
		var hacia := Vector3.UP                          # en el suelo crecen hacia arriba; en la pared, hacia el abismo
		if i < 4 or i >= 10:
			c.y = T.altura(c.x, c.z) if i < 4 else T.NIDO
		elif c.x < 0.0:                                  # acantilado bajo la cornisa alta (mira al este)
			c.x = T.borde_oeste(c.z) - _hundir_acantilado(c.z, c.y, T.ALTO + 0.06, 41.0) + 0.1
			hacia = Vector3(1.0, 0.5, 0.15).normalized()
		else:                                            # acantilado bajo la cornisa baja (mira al oeste)
			c.x = T.borde_este(c.z) + _hundir_acantilado(c.z, c.y, T.BAJO + 0.06, 67.0) - 0.1
			hacia = Vector3(-1.0, 0.5, 0.15).normalized()
		var lado := hacia.cross(Vector3.FORWARD if absf(hacia.z) < 0.9 else Vector3.RIGHT).normalized()
		for k in randi_range(3, 5):
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = randf_range(0.1, 0.24)
			cm.height = randf_range(0.5, 1.4)
			cm.radial_segments = 5
			cm.rings = 1
			var eje := hacia.rotated(lado, randf_range(-0.6, 0.6)).rotated(hacia, randf() * TAU).normalized()
			var x_eje := eje.cross(Vector3.FORWARD if absf(eje.z) < 0.9 else Vector3.RIGHT).normalized()
			var b := Basis(x_eje, eje, x_eje.cross(eje).normalized())
			lotes.poner(cm, Transform3D(b, c + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), randf_range(-0.3, 0.3)) + eje * cm.height * 0.42), m)
		if i < 4 or i >= 10:
			halo(c, c + Vector3(0, 0.6, 0), Materiales.AMBAR, 3.0, 1.6)


# Mojones de piedras apiladas que dejaban los peregrinos.
func _mojones() -> void:
	var m := mat.detalle(Color(0.52, 0.50, 0.50), 0.9, 0.8)
	for s in [Vector3(-9.6, 0, 36.0), Vector3(-9.2, 0, 24.5), Vector3(-9.8, 0, 11.0), Vector3(-9.5, 0, -6.0), Vector3(-10.4, 0, -16.6)]:
		var p := Vector3(s.x, T.altura(s.x, s.z), s.z)
		var r := 0.32
		for k in randi_range(3, 5):
			var sm := SphereMesh.new()
			sm.radius = r
			sm.height = r * 0.9
			sm.radial_segments = 7
			sm.rings = 4
			lotes.poner(sm, Transform3D(Basis(Vector3.UP, randf() * TAU), p + Vector3(randf_range(-0.04, 0.04), r * 0.4, 0)), m)
			p.y += r * 0.8
			r *= 0.78


# ================================================================= vida

func _particulas() -> void:
	polvo = CPUParticles3D.new()
	polvo.amount = POLVO[nombre_perfil]
	polvo.lifetime = 7.0
	polvo.preprocess = 7.0
	polvo.local_coords = false
	polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	polvo.emission_box_extents = Vector3(9.0, 3.0, 9.0)
	polvo.direction = Vector3(0.3, 0.2, -0.2)
	polvo.spread = 180.0
	polvo.initial_velocity_min = 0.05
	polvo.initial_velocity_max = 0.25
	polvo.gravity = Vector3(0, -0.02, 0)
	polvo.scale_amount_min = 0.5
	polvo.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = mat.mota(Color(1.0, 0.92, 0.75))
	polvo.mesh = q
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	polvo.color_ramp = g
	polvo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	polvo.name = "Polvo"
	region.add_child(polvo)
	# brasas de ámbar que suben del fondo del abismo
	var brasas := CPUParticles3D.new()
	brasas.amount = BRASAS[nombre_perfil]
	brasas.lifetime = 11.0
	brasas.preprocess = 11.0
	brasas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	brasas.emission_box_extents = Vector3(6.5, 2.0, 30.0)
	brasas.direction = Vector3(0, 1, 0)
	brasas.spread = 18.0
	brasas.initial_velocity_min = 1.4
	brasas.initial_velocity_max = 2.6
	brasas.gravity = Vector3(0.05, 0.0, 0.0)
	brasas.scale_amount_min = 0.6
	brasas.scale_amount_max = 1.4
	var qb := QuadMesh.new()
	qb.size = Vector2(0.14, 0.14)
	qb.material = mat.mota(Color(1.0, 0.62, 0.25))
	brasas.mesh = qb
	var gb := Gradient.new()
	gb.colors = PackedColorArray([Color(1, 0.8, 0.5, 0.0), Color(1, 0.7, 0.35, 1.0), Color(1, 0.5, 0.2, 0.0)])
	gb.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	brasas.color_ramp = gb
	brasas.position = Vector3(-0.5, -32.0, -6.0)
	brasas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	brasas.visibility_aabb = AABB(Vector3(-9, -4, -32), Vector3(18, 34, 64))
	region.add_child(brasas)


# Cuervos que planean en círculos sobre el abismo (el pájaro de prototipos/fauna_simple.gd, en negro).
func _aves() -> void:
	var fauna := load("res://prototipos/fauna_simple.gd")
	if fauna == null:
		return
	var negro := mat.liso(Color(0.08, 0.08, 0.1), 1.0)
	var negro_alas := mat.tela(Color(0.12, 0.12, 0.14))
	var sitios := [[Vector3(-0.5, -6.0, 12.0), 6.5], [Vector3(0.5, -11.0, -6.0), 5.0], [Vector3(-1.0, -3.0, -20.0), 7.0],
		[Vector3(0.0, -15.0, 22.0), 4.0], [Vector3(1.0, -9.0, -30.0), 5.5]]
	for i in AVES[nombre_perfil]:
		var ave = fauna.new()
		ave.tipo = "pajaro"
		ave.radio = sitios[i][1]
		ave.position = sitios[i][0]
		ave.scale = Vector3.ONE * 1.6
		region.add_child(ave)
		for mi in ave.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = negro_alas if mi.mesh is QuadMesh else negro
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ================================================================= T-102: el primer tramo (entrada, cornisa y puente)

var luces: Array = []             # luces reales de los faroles (perfil alto): tiemblan como el fuego
var _t_luz := 0.0
var bruma: CPUParticles3D         # la bruma de la caída (las pruebas la cuentan)
# La caída de agua del primer puente: brota de una grieta del muro del oeste y cae al abismo junto al puente, en el
# primer hueco. Su roca, mojada y con su luz fría (materiales.gd, «caida»).
const CAIDA_Z := 15.2
const CAIDA_ARRIBA := 4.5                # brota algo por encima de la cornisa (desde arriba no cruza la pantalla)
const BRUMAS := {"bajo": 4, "medio": 7, "alto": 11}
const ROCIO := {"bajo": 0, "medio": 14, "alto": 28}
const HELECHOS := {"bajo": 14, "medio": 26, "alto": 40}


func _caida_del_puente() -> void:
	var x_muro := T.muro_oeste(CAIDA_Z)
	var arriba := Vector3(x_muro + 0.35, CAIDA_ARRIBA, CAIDA_Z)
	var abajo := Vector3(x_muro + 1.4, -42.0, CAIDA_Z + 0.4)
	var capas := [[1.8, 3.4, 0.0]] if nombre_perfil == "bajo" else [[1.8, 3.4, 0.0], [1.0, 2.2, 0.22]]
	for capa in capas:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tramos := 10
		for k in tramos:
			for e in [[0, 0], [1, 0], [0, 1], [1, 0], [1, 1], [0, 1]]:
				var t := float(k + e[1]) / tramos
				var ancho: float = lerpf(capa[0], capa[1], t)
				var p := arriba.lerp(abajo, t) + Vector3(capa[2], 0, (e[0] - 0.5) * ancho)
				p.x += (1.0 - pow(1.0 - t, 4.0)) * 1.1 - t * 0.6           # sale del muro en arco y luego cae a plomo
				st.set_uv(Vector2(e[0], t))
				st.add_vertex(p)
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		var m := mat.cascada()
		m.set_shader_parameter("largo", 46.0)
		m.set_shader_parameter("brillo", 0.82)              # en la sombra del hueco: menos blanca que la del fondo
		m.set_shader_parameter("opacidad", 0.7)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.name = "CaidaDelPuente"
		region.add_child(mi)
	# la grieta de donde brota (roca oscura) y la espuma del chorro
	var hueco := mat.liso(Color(0.08, 0.08, 0.1), 1.0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 1.2, 1.8)
	lotes.poner(bm, Transform3D(Basis(), arriba + Vector3(-0.2, 0.55, 0)), hueco)
	var espuma := mat.brillo(Color(0.80, 0.88, 0.96), 0.8)
	for k in 5:
		var s := SphereMesh.new()
		s.radius = randf_range(0.12, 0.22)
		s.height = s.radius * 1.3
		s.radial_segments = 8
		s.rings = 4
		lotes.poner(s, Transform3D(Basis(), arriba + Vector3(0.15 + randf_range(0.0, 0.2), randf_range(-0.6, 0.1), randf_range(-0.6, 0.6))), espuma)
	# su luz fría: un resplandor azulado a la altura del puente (suma color) y la bruma que sube del abismo
	var q := QuadMesh.new()
	q.size = Vector2(9.0, 9.0)
	var resplandor := MeshInstance3D.new()
	resplandor.mesh = q
	resplandor.material_override = mat.halo_aire(Materiales.LUZ_CAIDA, 0.32)
	resplandor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	resplandor.position = Vector3(x_muro + 1.6, -4.0, CAIDA_Z)
	resplandor.name = "LuzDeLaCaida"
	region.add_child(resplandor)
	bruma = CPUParticles3D.new()
	bruma.name = "BrumaDeLaCaida"
	bruma.amount = BRUMAS[nombre_perfil]
	bruma.lifetime = 9.0
	bruma.preprocess = 9.0
	bruma.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bruma.emission_box_extents = Vector3(1.6, 3.5, 2.6)
	bruma.direction = Vector3(0.4, 1.0, 0.0)
	bruma.spread = 25.0
	bruma.initial_velocity_min = 0.25
	bruma.initial_velocity_max = 0.6
	bruma.gravity = Vector3.ZERO
	bruma.scale_amount_min = 0.7
	bruma.scale_amount_max = 1.3
	var qb := QuadMesh.new()
	qb.size = Vector2(4.2, 4.2)
	qb.material = mat.bruma()
	bruma.mesh = qb
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	bruma.color_ramp = g
	bruma.position = Vector3(x_muro + 2.6, -5.0, CAIDA_Z)
	bruma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bruma.visibility_aabb = AABB(Vector3(-6, -6, -6), Vector3(12, 16, 12))
	region.add_child(bruma)
	if ROCIO[nombre_perfil] > 0:                                    # gotitas de rocío que el viento sube hasta el puente
		var rocio := CPUParticles3D.new()
		rocio.name = "Rocio"
		rocio.amount = ROCIO[nombre_perfil]
		rocio.lifetime = 4.0
		rocio.preprocess = 4.0
		rocio.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rocio.emission_box_extents = Vector3(1.2, 1.5, 2.2)
		rocio.direction = Vector3(1.0, 0.8, 0.0)
		rocio.spread = 30.0
		rocio.initial_velocity_min = 0.6
		rocio.initial_velocity_max = 1.4
		rocio.gravity = Vector3(0, -0.15, 0)
		var qr := QuadMesh.new()
		qr.size = Vector2(0.06, 0.06)
		qr.material = mat.mota(Color(0.82, 0.92, 1.0))
		rocio.mesh = qr
		var gr := Gradient.new()
		gr.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.0)])
		rocio.color_ramp = gr
		rocio.position = Vector3(x_muro + 1.5, -1.5, CAIDA_Z)
		rocio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(rocio)
	# un colchón de niebla fría bajo el primer puente (medio y alto): el abismo se hunde en ella y se lee la altura
	if nombre_perfil != "bajo":
		var capa := MeshInstance3D.new()
		var pl := PlaneMesh.new()
		pl.size = Vector2(9.0, 7.5)
		capa.mesh = pl
		capa.material_override = mat.niebla(Color(0.62, 0.70, 0.86, 0.24))
		capa.position = Vector3(-11.6, -6.5, (T.HUECOS[0][0] + T.HUECOS[0][1]) * 0.5)
		capa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		capa.name = "NieblaBajoElPuente"
		region.add_child(capa)


# La entrada de la garganta: dos piedras hincadas de los peregrinos con el anillo partido, una cuerda de cintas de
# oración entre ellas y una antorcha en cada una. Es el umbral: Kael llega del mapa (al sur) y entra por aquí.
const UMBRAL_Z := 33.6


func _entrada() -> void:
	var piedra := mat.piedra_tallada()
	var cimas: Array = []
	for lado in [-1.0, 1.0]:
		var x: float = T.X_CAMINO_O + lado * 2.45
		var p := Vector3(x, T.altura(x, UMBRAL_Z), UMBRAL_Z)
		var alto := 2.9 if lado < 0.0 else 2.6
		var giro := Vector3(randf_range(-0.04, 0.04), lado * 0.15, -lado * 0.05)
		var b := Basis.from_euler(giro)
		# la piedra: un bloque algo más estrecho arriba (dos cajas) y la base hundida
		Roca.caja(lotes, region, p + b * Vector3(0, alto * 0.38, 0), Vector3(0.62, alto * 0.76, 0.5), piedra, giro)
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, alto * 0.3, 0.42)
		lotes.poner(bm, Transform3D(b, p + b * Vector3(0, alto * 0.86, 0)), piedra)
		var base := BoxMesh.new()
		base.size = Vector3(0.9, 0.22, 0.75)
		lotes.poner(base, Transform3D(Basis(Vector3.UP, 0.3 * lado), p + Vector3(0, 0.05, 0)), mat.piedra())
		# el anillo partido tallado en la cara que mira al sur (a quien llega)
		var anillo: ArrayMesh = load("res://zonas3d/garganta/piezas.gd").anillo_partido(0.17, 0.028, 40.0, 18, 6)
		lotes.poner(anillo, Transform3D(b, p + b * Vector3(0, alto * 0.62, 0.26)), mat.bronce())
		cimas.append(p + b * Vector3(-lado * 0.05, alto * 0.95, 0))
		# la antorcha, en la cara de dentro (hacia el camino)
		var soporte := p + b * Vector3(-lado * 0.36, 1.75, 0.05)
		var palo := CylinderMesh.new()
		palo.top_radius = 0.05
		palo.bottom_radius = 0.035
		palo.height = 0.55
		palo.radial_segments = 6
		lotes.poner(palo, Transform3D(Basis(Vector3.BACK, lado * 0.35), soporte), mat.madera_vieja())
		var abrazadera := BoxMesh.new()
		abrazadera.size = Vector3(0.14, 0.06, 0.14)
		lotes.poner(abrazadera, Transform3D(Basis(), soporte + Vector3(lado * 0.04, -0.08, 0)), mat.hierro())
		var fuego := soporte + Vector3(-lado * 0.1, 0.42, 0)
		var brasa := SphereMesh.new()
		brasa.radius = 0.08
		brasa.height = 0.12
		brasa.radial_segments = 6
		brasa.rings = 3
		lotes.poner(brasa, Transform3D(Basis(), fuego + Vector3(0, -0.12, 0)), mat.brillo(Color(1.0, 0.5, 0.18), 1.3))
		llama_en(fuego, 0.5, lado * 2.0, 1.15)
		halo(Vector3(p.x - lado * 0.6, p.y, p.z), fuego, Materiales.FUEGO, 4.6, 1.7)
		mat.poner_fuego(fuego, 5.5)
	# la cuerda con las cintas de oración, combada entre las dos cimas
	var lt := Roca.Lotes.new()
	var m_tela := StandardMaterial3D.new()
	m_tela.vertex_color_use_as_albedo = true
	m_tela.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_tela.roughness = 1.0
	var a: Vector3 = cimas[0]
	var b2: Vector3 = cimas[1]
	var colores := [Color(0.70, 0.22, 0.20), Color(0.86, 0.66, 0.30), Color(0.30, 0.44, 0.70), Color(0.92, 0.90, 0.82),
		Color(0.36, 0.56, 0.34)]
	var cuelga := func(t: float) -> Vector3: return a.lerp(b2, t) - Vector3(0, 0.45 * 4.0 * t * (1.0 - t), 0)
	var segs := 10
	for k in segs:
		var pa: Vector3 = cuelga.call(float(k) / segs)
		var pb: Vector3 = cuelga.call(float(k + 1) / segs)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.018
		cm.bottom_radius = 0.018
		cm.height = pa.distance_to(pb) + 0.02
		cm.radial_segments = 5
		cm.rings = 1
		var y := (pb - pa).normalized()
		var xe := y.cross(Vector3.FORWARD).normalized()
		lt.poner_color(cm, Transform3D(Basis(xe, y, xe.cross(y)), (pa + pb) * 0.5), m_tela, Color(0.62, 0.53, 0.40))
	var n_cintas := 13
	for k in n_cintas:
		var t := (k + 0.5) / n_cintas
		var q := QuadMesh.new()
		q.size = Vector2(0.24, 0.32)
		var p: Vector3 = cuelga.call(t) - Vector3(0, 0.17, 0)
		lt.poner_color(q, Transform3D(Basis(Vector3.RIGHT, randf_range(-0.2, 0.2)).rotated(Vector3.UP, randf_range(-0.15, 0.15)), p),
			m_tela, colores[k % colores.size()] * randf_range(0.85, 1.05))
	for mi in lt.cerrar(region, false):
		mi.name = "CintasDeLaEntrada"


# Helechos y matas verdes donde hay humedad: al pie del muro del oeste en el primer tramo y junto a la caída.
func _helechos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var hoja := _malla_helecho()
	hoja.surface_set_material(0, mat.hierba_verde())
	var lista: Array = []
	var intentos := 0
	while lista.size() < HELECHOS[nombre_perfil] and intentos < 600:
		intentos += 1
		var z := rng.randf_range(8.0, 44.0) if rng.randf() < 0.8 else rng.randf_range(-6.0, 8.0)
		if T.en_hueco(z) or absf(z - UMBRAL_Z) < 0.8 or (z > 27.0 and z < 32.0):
			continue
		var cerca_caida := absf(z - CAIDA_Z) < 6.0
		var x: float
		if rng.randf() < 0.75 or cerca_caida:                          # al pie del muro (húmedo y en sombra)
			x = T.muro_oeste(z) + rng.randf_range(0.5, 1.4)
		else:                                                          # o asomados al borde
			x = T.borde_oeste(z) - rng.randf_range(0.15, 0.5)
		var p := Vector3(x, T.altura(x, z), z)
		var e := rng.randf_range(0.7, 1.25) * (1.15 if cerca_caida else 1.0)
		lista.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, e * rng.randf_range(0.8, 1.15), e)), p))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = hoja
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
		var tono := rng.randf_range(0.8, 1.15)
		mm.set_instance_color(i, Color(tono, tono, tono * 0.9))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.name = "Helechos"
	region.add_child(mmi)


# Un helecho: seis frondes que salen del centro y se arquean hacia fuera (tiras de 4 tramos que se estrechan). El
# sombreado de la hierba lo mece y le da el degradado de verde.
func _malla_helecho() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frondes := 6
	for f in frondes:
		var a := TAU * f / frondes + 0.3 * sin(f * 2.1)
		var dir := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-dir.z, 0, dir.x)
		var largo := 0.55 + 0.12 * sin(f * 1.7)
		var puntos: Array = []
		for k in 5:
			var t := k / 4.0
			var p := dir * largo * t + Vector3(0, 0.42 * sin(t * PI * 0.8), 0)   # sube y se dobla
			var ancho := 0.11 * sin(PI * minf(t * 1.2 + 0.08, 1.0))
			puntos.append([p - lado * ancho, p + lado * ancho])
		for k in 4:
			var p0: Array = puntos[k]
			var p1: Array = puntos[k + 1]
			for v in [p0[0], p1[0], p0[1], p0[1], p1[0], p1[1]]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	return st.commit()


# Una llama que mira a la cámara en «p» (centro de la llama), de «alto» metros.
func llama_en(p: Vector3, alto: float, fase := 0.0, fuerza := 1.0) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(alto * 0.62, alto)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat.llama(fase, fuerza)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	mi.name = "Llama"
	region.add_child(mi)
	return mi


# El fuego tiembla: las luces reales de los faroles (perfil alto) suben y bajan un poco. La región lo llama cada
# fotograma.
func animar(delta: float) -> void:
	_t_luz += delta
	for i in luces.size():
		var o: OmniLight3D = luces[i]
		o.light_energy = 1.1 * (0.88 + 0.08 * sin(_t_luz * 9.0 + i * 1.7) + 0.04 * sin(_t_luz * 23.0 + i))


# Un sillar: caja que choca (cuerpo estático) y se dibuja con su color en el lote «l» (escalera de la presa, T-102).
func _sillar(l: Roca.Lotes, m: Material, pos: Vector3, tam: Vector3, giro: Vector3, color: Color) -> void:
	var bm := BoxMesh.new()
	bm.size = tam
	l.poner_color(bm, Transform3D(Basis.from_euler(giro), pos), m, color)
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	cuerpo.rotation = giro
	region.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = tam
	col.shape = bs
	cuerpo.add_child(col)


# ================================================================= T-102: el resto del recorrido

# Una dovela del enlosado de la arena: sector de corona entre los ángulos a0..a1 y los radios r0..r1, «grueso» sobre el
# suelo (alto(x, z)), con «tramos» divisiones del arco. Caras de arriba y cantos de fuera (los de dentro no se ven).
func _dovela(st: SurfaceTool, c: Vector3, alto: Callable, a0: float, a1: float, r0: float, r1: float, tramos: int,
		grueso: float, col: Color) -> void:
	var punto := func(a: float, r: float, arriba: bool) -> Vector3:
		var x := c.x + cos(a) * r
		var z := c.z + sin(a) * r
		return Vector3(x, float(alto.call(x, z)) + (grueso if arriba else -0.04), z)
	for i in tramos:
		var aa := lerpf(a0, a1, float(i) / tramos)
		var ab := lerpf(a0, a1, float(i + 1) / tramos)
		var p00: Vector3 = punto.call(aa, r0, true)
		var p01: Vector3 = punto.call(ab, r0, true)
		var p10: Vector3 = punto.call(aa, r1, true)
		var p11: Vector3 = punto.call(ab, r1, true)
		var q10: Vector3 = punto.call(aa, r1, false)
		var q11: Vector3 = punto.call(ab, r1, false)
		var q00: Vector3 = punto.call(aa, r0, false)
		var q01: Vector3 = punto.call(ab, r0, false)
		# (sentido horario visto desde fuera de cada cara: el de Godot)
		for v in [p00, p10, p01, p10, p11, p01, p10, q11, p11, p10, q10, q11, p00, p01, q01, p00, q01, q00]:
			st.set_color(col)
			st.add_vertex(v)
	for e in [[a0, -1.0], [a1, 1.0]]:                             # los dos cantos de los lados
		var a: float = e[0]
		var p0: Vector3 = punto.call(a, r0, true)
		var p1: Vector3 = punto.call(a, r1, true)
		var q0: Vector3 = punto.call(a, r0, false)
		var q1: Vector3 = punto.call(a, r1, false)
		var orden := [p0, p1, q0, q0, p1, q1] if e[1] > 0.0 else [p0, q0, p1, p1, q0, q1]
		for v in orden:
			st.set_color(col)
			st.add_vertex(v)


# Senda de la cornisa baja: adoquines sueltos y gastados por donde pasan los Grimfang y los peregrinos (más ralos que
# la Vía del Peregrino de arriba). Sin colisión. Las mismas formas que _losas.
func _senda_baja() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7307
	var m := mat.detalle(Color.WHITE, 1.3, 1.0).duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	var forma := _adoquin(rng, 7 if nombre_perfil == "bajo" else 9)
	forma.surface_set_material(0, m)
	var lista: Array = []
	var z := T.Z_CORNISA_E - 1.0
	var fila := 0
	while z > T.GRIETA[0] + 1.0:
		var lejos_de_piezas := absf(z - T.ASCENSOR_Z) > 2.2 and absf(z - T.PALANCA.z) > 1.6 and absf(z - T.LEVADIZO_Z) > 2.0 \
			and not (z > T.BAJADA_RELLANO[0] - 0.5 and z < T.BAJADA_RELLANO[1] + 0.5)
		if lejos_de_piezas:
			var centro := T.X_CAMINO_E + 0.35 * sin(z * 0.13)
			if z < T.PASO_BAJO[1] + 1.0 and z > T.PASO_BAJO[0] - 1.0:
				centro = 12.4                                        # el paso bajo, entre el muro y la aguja
			var x := -0.95 + (0.22 if fila % 2 == 0 else 0.0)
			while x < 0.95:
				var borde := absf(x) / 0.95
				if rng.randf() > 0.15 + 0.5 * pow(borde, 2.0):
					var p := Vector3(centro + x + rng.randf_range(-0.07, 0.07), 0, z + rng.randf_range(-0.07, 0.07))
					var e := rng.randf_range(0.95, 1.2)
					var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, rng.randf_range(0.8, 1.1), e)),
						Vector3(p.x, T.altura(p.x, p.z) - 0.02 - 0.02 * borde, p.z))
					var g := rng.randf_range(0.5, 0.62)
					lista.append([t, Color(g, g * 0.95, g * 0.9).lerp(Color(0.40, 0.44, 0.30), rng.randf_range(0.0, 0.3))])
				x += 0.44
		z -= 0.44
		fila += 1
	_por_tramos("SendaBaja", forma, lista)


# Reparte piezas repetidas ([Transform3D, Color] cada una) en MultiMesh de TRAMO_MM metros a lo largo de z: lo que la
# cámara no ve no se dibuja (antes, una MultiMesh de 70 m se dibujaba entera desde cualquier sitio). Cada tramo lleva
# sus piezas relativas a su centro, así su caja es solo la suya.
const TRAMO_MM := 12.0


func _por_tramos(nombre: String, malla: Mesh, piezas: Array) -> void:
	var grupos := {}
	for pz in piezas:
		var k := floori((pz[0] as Transform3D).origin.z / TRAMO_MM)
		if not grupos.has(k):
			grupos[k] = []
		grupos[k].append(pz)
	for k in grupos:
		var lista: Array = grupos[k]
		var centro := Vector3.ZERO
		for pz in lista:
			centro += (pz[0] as Transform3D).origin
		centro /= lista.size()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = malla
		mm.instance_count = lista.size()
		for i in lista.size():
			var t: Transform3D = lista[i][0]
			mm.set_instance_transform(i, Transform3D(t.basis, t.origin - centro))
			mm.set_instance_color(i, lista[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.name = "%s_%d" % [nombre, k]
		region.add_child(mmi)


# Helechos al pie del muro del este (la cornisa baja, en sombra y húmeda) y en la grieta, junto a la cascada del fondo.
func _helechos_bajos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8821
	var hoja := _malla_helecho()
	hoja.surface_set_material(0, mat.hierba_verde())
	var lista: Array = []
	var cuantos: int = HELECHOS[nombre_perfil]
	var intentos := 0
	while lista.size() < cuantos and intentos < 600:
		intentos += 1
		var z := rng.randf_range(T.GRIETA[0] + 0.5, T.Z_CORNISA_E - 1.0)
		if absf(z - T.ASCENSOR_Z) < 2.5 or absf(z - T.PALANCA.z) < 2.0 or (z > 17.0 and z < 22.0):
			continue
		var en_grieta := z < T.GRIETA[1]
		if not en_grieta and rng.randf() < 0.45:                      # más en la grieta, junto al agua
			continue
		var x := T.muro_este(z) - rng.randf_range(0.5, 1.3)
		var p := Vector3(x, T.altura(x, z), z)
		var e := rng.randf_range(0.75, 1.3)
		lista.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, e * rng.randf_range(0.8, 1.15), e)), p))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = hoja
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
		var tono := rng.randf_range(0.75, 1.1)
		mm.set_instance_color(i, Color(tono, tono, tono * 0.9))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.name = "HelechosBajos"
	region.add_child(mmi)
