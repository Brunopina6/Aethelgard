extends RefCounted
# Trazado de la Garganta del Diablo 3D (zonas3d/garganta_3d.gd): niveles, cornisas, piezas, zonas de cámara y
# equivalencias con la mazmorra 2D (garganta.gd). Solo datos y cuentas: no crea nada.
#
# La garganta corre de sur (z+) a norte (z−), por donde mira la cámara, que nunca gira (prototipos/vista3d.gd). Así los
# muros quedan a los lados de la pantalla y nunca entre la cámara y Kael, y el abismo se ve siempre por delante.
#   - Camino de arriba (P1 → P4), en la cornisa del oeste, a ALTO: entrada, puentes colgantes, puerta sellada y arena.
#   - Camino de abajo (P5 → P8), en la cornisa del este, a BAJO: escalera, ascensor, nido (debajo, a NIDO), palanca y
#     grieta oculta.
#   - Lo que cruza el abismo se ve de perfil: la escalera de la presa, el ascensor y el puente levadizo.
# Escala: una casilla de la 2D es un metro. Las piezas conservan su orden: z = 40 − x (x en casillas de la 2D).

# ---------------------------------------------------------------- niveles y paredes (metros)
const ALTO := 0.0                 # cornisa del oeste (camino de arriba)
const BAJO := -8.0                # cornisa del este (camino de abajo)
const NIDO := -14.0               # repisa del nido, en el abismo, bajo P6
const HONDO := -50.0              # el fondo que brilla
const TOPE := 30.0                # altura de los muros (la cámara nunca llega a verla)
const X_MURO_O := -16.0           # pie del muro del oeste
const X_BORDE_O := -8.0           # borde de la cornisa alta sobre el abismo
const X_BORDE_E := 7.0            # borde de la cornisa baja
const X_MURO_E := 15.0            # pie del muro del este
const Z_SUR := 72.0               # los muros siguen hasta aquí (detrás de la cámara: nunca se ve el final)
const Z_FIN_CAMINO := 46.0        # más al sur no se anda (la salida está antes)
const Z_PRESA_N := 27.0           # cara norte de la presa: al norte empieza el abismo
const Z_PRESA_S := 33.0           # cara sur de la presa
const Z_CORNISA_E := 35.0         # la cornisa baja empieza aquí (al sur, la hondonada de la boca)
const Y_BOCA := -11.0             # hondonada entre la presa y la boca
const Z_NORTE := -42.0            # muro del norte (fin de la garganta)

# ---------------------------------------------------------------- camino de arriba (cornisa del oeste)
const X_CAMINO_O := -12.0         # por el centro de la cornisa (y de los puentes colgantes)
const INICIO := Vector3(-12.0, ALTO, 37.0)          # 2D (3, 10.8)
const SALIDA := Vector3(-12.0, ALTO, 42.5)          # «Mapa del mundo» (2D: el borde oeste, x < 0,6)
const GUARDADO_1 := Vector3(-14.4, ALTO, 35.0)      # 2D (5, 8.6)
const GUARDADO_2 := Vector3(-14.4, ALTO, -8.0)      # 2D (48, 8.6)
# Escalera de la presa: de la cornisa alta (oeste) a la baja (este), a lo largo de x. 2D: x 9..12 → z 28..31.
const ESCALERA_Z := [28.0, 31.0]
const ESCALONES := 20                               # 20 × 0,4 m = 8 m; huella de 0,75 m
# Huecos de los puentes (P2): la cornisa se hundió. 2D: x 22..28 y 31..38.
const HUECOS := [[12.0, 18.0], [2.0, 9.0]]          # [z norte, z sur]
const PUENTES := [[19.0, 11.0], [10.0, 1.0]]        # puentes colgantes: [z sur, z norte] (2D: 8 y 9 casillas)
const ANCHO_PUENTE := 2.2
const ISLOTE := [9.0, 12.0]                         # entre los dos huecos: los pilares del anillo partido
const DETALLE_PUENTES := Vector3(-14.3, ALTO, 10.5) # 2D «p2» (29.5, 9.0): los pilares
# Puente levadizo (P7 → P3): bisagra en la cornisa alta; al bajar, apoya en la baja. 2D: x = 52.
const LEVADIZO_Z := -12.0
const LEVADIZO_ANCHO := 2.6
const BISAGRA := Vector3(X_BORDE_O + 0.4, ALTO, LEVADIZO_Z)
const APOYO := Vector3(X_BORDE_E + 1.6, BAJO, LEVADIZO_Z)   # donde descansa la punta, ya en la cornisa baja
# Paso estrecho y puerta sellada (P3 → P4). 2D: x 58..62, puerta en x = 60.
const PASO_PUERTA := [-22.0, -18.0]
const PUERTA := Vector3(-12.0, ALTO, -20.0)
const PUERTA_ANCHO := 4.0
# Arena de Gorthor (P4), sobre un pilar de roca que sube del abismo. 2D: x 62..78.
const ARENA := Vector3(-8.5, ALTO, -31.0)
const ARENA_RADIO := 9.5
const ARENA_ALTO := 0.12          # el enlosado de la arena, algo más alto que la cornisa
const Z_GORTHOR := -26.0          # 2D: x > 66 → el combate del jefe
const VUELTA_GORTHOR := Vector3(-12.0, ALTO, -23.2) # 2D (63, 10.8): tras perder, aquí (fuera del disparo)
const GORTHOR := Vector3(-8.5, ALTO, -35.5)         # espera ante su trono, mirando al sur
# Ascensor (P5 ↔ P1): una cesta colgada de un cable que cruza el abismo. 2D: x = 19.
const ASCENSOR_Z := 22.0
const ASCENSOR_ARRIBA := Vector3(-9.6, ALTO, ASCENSOR_Z)   # donde se para Kael para usarlo
const ASCENSOR_ABAJO := Vector3(8.6, BAJO, ASCENSOR_Z)

# ---------------------------------------------------------------- camino de abajo (cornisa del este)
const X_CAMINO_E := 11.0
const PALANCA := Vector3(13.0, BAJO, -7.0)          # 2D (47, 33.2)
const PASO_BAJO := [-25.0, -20.0]                   # 2D: x 60..65, entre el muro y una aguja de roca
const GRIETA := [-38.5, -25.0]                      # 2D: x 65..77 (la grieta oculta)
const PILAR_PEREGRINO := Vector3(12.6, BAJO, -32.0) # 2D «p8» (72, 34.2)
# Bajada al nido: escalera tallada en el acantilado, hacia el norte. 2D: x 29..32.
const BAJADA_X := [4.5, 6.5]
const BAJADA_Z := [11.0, 19.0]                      # [abajo, arriba]
const BAJADA_RELLANO := [19.0, 20.6]                # rellano de arriba (z), de x 4,5 a la cornisa
const BAJADA_PELDANOS := 16                         # 16 × 0,375 m = 6 m
# El nido, en una repisa del abismo. 2D: nido x 22..40, cofre en (31, 50.6).
const NIDO_CENTRO := Vector3(1.5, NIDO, 7.0)        # la escalera baja hasta su borde (z ≈ 11)
const NIDO_RADIOS := Vector2(5.6, 6.6)              # semiejes de la repisa (x, z)
const COFRE_NIDO := Vector3(1.1, NIDO, 6.6)
const RADIO_NIDO := 4.2                             # 2D: y > 47,4 → al pisar el nido, el combate
const VUELTA_NIDO := Vector3(5.5, NIDO, 10.5)       # 2D (30.8, 44.0): al pie de la bajada
const GOLEM := Vector3(-0.6, NIDO, 3.4)             # el gólem de ámbar, dormido en el borde norte del nido

# ---------------------------------------------------------------- equivalencias con la 2D
# Para una partida guardada dentro de la Garganta 2D: cada sitio de la 2D (en casillas) y su sitio en la 3D. Se usa el
# más cercano (modo3d.escena_equivalente → garganta_3d.posicion_desde_2d).
const ANCLAS := [
	[Vector2(3, 10.8), INICIO], [Vector2(5, 8.6), Vector3(-12.5, ALTO, 35.0)],
	[Vector2(10.5, 11), Vector3(-10.5, ALTO, 29.5)], [Vector2(19, 12.6), Vector3(-10.4, ALTO, 22.0)],
	[Vector2(25, 10.8), Vector3(-12.0, ALTO, 20.0)], [Vector2(29.5, 10.8), Vector3(-12.0, ALTO, 10.5)],
	[Vector2(34.5, 10.8), Vector3(-12.0, ALTO, 0.0)], [Vector2(42, 10.8), Vector3(-12.0, ALTO, -3.0)],
	[Vector2(48, 9.5), Vector3(-12.6, ALTO, -8.0)], [Vector2(52, 11.5), Vector3(-11.0, ALTO, -12.0)],
	[Vector2(57, 10.8), Vector3(-12.0, ALTO, -16.5)], [Vector2(63, 10.8), VUELTA_GORTHOR],
	[Vector2(70, 9.5), VUELTA_GORTHOR],
	[Vector2(10.5, 30), Vector3(9.0, BAJO, 29.5)], [Vector2(5, 35), Vector3(11.0, BAJO, 32.0)],
	[Vector2(19, 32.6), Vector3(9.6, BAJO, 22.0)], [Vector2(25, 35), Vector3(11.0, BAJO, 15.0)],
	[Vector2(30.5, 36), Vector3(10.5, BAJO, 19.5)], [Vector2(30.8, 44), VUELTA_NIDO],
	[Vector2(31, 50), VUELTA_NIDO], [Vector2(38, 35), Vector3(11.0, BAJO, 2.0)],
	[Vector2(47, 34.2), Vector3(11.4, BAJO, -7.0)], [Vector2(52, 33), Vector3(10.8, BAJO, -12.0)],
	[Vector2(58, 35), Vector3(11.5, BAJO, -18.0)], [Vector2(62.5, 35), Vector3(12.2, BAJO, -22.5)],
	[Vector2(70, 35), Vector3(11.0, BAJO, -30.0)],
]

# ---------------------------------------------------------------- ritmo de encuentros (como garganta.gd, _ritmo)
# Muchos en los puentes (P2), pocos en las cornisas de abajo (P5 y P6), ninguno en el resto.
static func ritmo(p: Vector3) -> float:
	if p.x < X_BORDE_O + 1.0 and p.y > ALTO - 3.0 and p.z > 0.0 and p.z <= 20.0:
		return 2.0
	if p.x > X_BORDE_E - 0.5 and p.y < BAJO + 3.0 and p.y > BAJO - 3.0 and p.z > 0.0 and p.z < Z_CORNISA_E:
		return 0.5
	return 0.0


# ---------------------------------------------------------------- zonas de cámara
# [x0, x1, z0, z1, inclinación, distancia mínima, distancia máxima]. La primera que contiene a Kael manda; fuera de
# todas, la cámara de siempre (45°, la distancia que elija el jugador). Pensadas para los tramos estrechos y para
# asomarse: en los puentes se inclina más y se ve el fondo del abismo (el nido brilla abajo); en los pasos estrechos
# se acerca y mira más desde arriba; en la arena se aleja para que quepan el jefe y la cascada.
const CAMARA := [
	[-30.0, X_BORDE_O + 1.0, 33.0, 80.0, 40.0, 16.0, 26.0],      # entrada: más horizontal, se ve la garganta delante
	[-30.0, X_BORDE_O + 1.0, 0.0, 21.0, 53.0, 16.0, 24.0],       # puentes colgantes: asomarse al abismo
	[-30.0, X_BORDE_O + 1.0, -23.0, -16.0, 50.0, 12.0, 18.0],    # paso estrecho de la puerta
	[-30.0, 4.0, -60.0, -23.0, 42.0, 18.0, 28.0],                # arena: el jefe, el trono y la cascada
	[-8.0, 7.0, -2.0, 21.0, 52.0, 12.0, 18.0],                   # bajada y nido (dentro del abismo)
	[7.0, 30.0, -60.0, -19.0, 54.0, 11.0, 16.0],                 # paso bajo y grieta oculta
]
const INCLINACION := 45.0


# Inclinación y distancias de la zona en la que está «p» ([incl, dmin, dmax]); fuera de las zonas, la de siempre.
static func camara_en(p: Vector3, dmin: float, dmax: float) -> Array:
	for z in CAMARA:
		if p.x >= z[0] and p.x <= z[1] and p.z >= z[2] and p.z <= z[3]:
			return [z[4], z[5], z[6]]
	return [INCLINACION, dmin, dmax]


# ---------------------------------------------------------------- bordes de las cornisas (con ruido)
static var _ruido: FastNoiseLite


static func ruido() -> FastNoiseLite:
	if _ruido == null:
		_ruido = FastNoiseLite.new()
		_ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_ruido.seed = 4471
		_ruido.frequency = 0.07
		_ruido.fractal_octaves = 3
	return _ruido


static func _n(a: float, b: float) -> float:
	return ruido().get_noise_2d(a, b)


# Cuánto se abre el ruido de los bordes junto a la escalera, el ascensor y el levadizo (ahí el borde es recto).
static func _calma(z: float) -> float:
	var k := 1.0
	for c in [[(ESCALERA_Z[0] + ESCALERA_Z[1]) * 0.5, 3.5], [ASCENSOR_Z, 2.5], [LEVADIZO_Z, 3.0]]:
		k = minf(k, smoothstep(0.0, 2.0, absf(z - c[0]) - c[1] * 0.5))
	return k


# Borde de la cornisa alta (x) a la altura z.
static func borde_oeste(z: float) -> float:
	var x := X_BORDE_O + 0.8 * _n(z * 1.3, 11.0) * _calma(z)
	# donde va la bisagra del levadizo, la cornisa sale un poco: el tablero apoya en roca (sin ella quedaba un hueco de
	# 17 cm entre el suelo y el puente bajado, y Kael no podía pasar; prueba_garganta3d del 09/11)
	x += 0.7 * (1.0 - smoothstep(1.4, 2.4, absf(z - LEVADIZO_Z)))
	if z > PASO_PUERTA[0] - 1.0 and z < PASO_PUERTA[1] + 1.0:          # el paso de la puerta se estrecha
		x = lerpf(x, -10.2, smoothstep(PASO_PUERTA[1] + 1.0, PASO_PUERTA[1] - 0.5, z) * smoothstep(PASO_PUERTA[0] - 1.0, PASO_PUERTA[0] + 0.5, z))
	return x


# Pie del muro del oeste (x) a la altura z (la roca empieza aquí; la cornisa se anda hasta MARGEN_MURO de él).
static func muro_oeste(z: float) -> float:
	var x := X_MURO_O + 0.5 * _n(z * 0.9, 37.0)
	if z > PASO_PUERTA[0] - 1.5 and z < PASO_PUERTA[1] + 1.5:          # el muro se abomba en el paso
		x = lerpf(x, -14.2, smoothstep(PASO_PUERTA[1] + 1.5, PASO_PUERTA[1] - 0.5, z) * smoothstep(PASO_PUERTA[0] - 1.5, PASO_PUERTA[0] + 0.5, z))
	return x


static func borde_este(z: float) -> float:
	var x := X_BORDE_E + 0.8 * _n(z * 1.3, 71.0) * _calma(z)
	if z < PASO_BAJO[1] + 1.0 and z > PASO_BAJO[0] - 1.0:              # el paso bajo, entre el muro y la aguja
		x = lerpf(x, 11.0, smoothstep(PASO_BAJO[1] + 1.0, PASO_BAJO[1] - 0.5, z) * smoothstep(PASO_BAJO[0] - 1.0, PASO_BAJO[0] + 0.5, z))
	return x


static func muro_este(z: float) -> float:
	var x := X_MURO_E - 0.5 * _n(z * 0.9, 97.0)
	if z < PASO_BAJO[1] + 1.5 and z > PASO_BAJO[0] - 1.5:
		x = lerpf(x, 13.8, smoothstep(PASO_BAJO[1] + 1.5, PASO_BAJO[1] - 0.5, z) * smoothstep(PASO_BAJO[0] - 1.5, PASO_BAJO[0] + 0.5, z))
	if z < GRIETA[1]:                                                   # la grieta se mete algo en el muro
		x += 1.2 * smoothstep(GRIETA[1], GRIETA[1] - 3.0, z) * smoothstep(GRIETA[0], GRIETA[0] + 3.0, z)
	return x


# Borde roto de un hueco de los puentes: la z donde acaba la cornisa en x, metida hacia dentro («dentro»: +1 hacia el
# sur, −1 hacia el norte) hasta 0,6 m. Lo usan el suelo, que acaba ahí, y la cara del hueco que se ve (escenario.gd).
static func borde_hueco(x: float, z_borde: float, dentro: float) -> float:
	return z_borde + dentro * 0.6 * (0.5 + 0.5 * _n(x * 9.0, z_borde * 3.0))


# ¿Hay hueco (sin cornisa) en la cornisa alta a la altura z?
static func en_hueco(z: float) -> bool:
	for h in HUECOS:
		if z > h[0] and z < h[1]:
			return true
	return false


# Altura del suelo de las cornisas (sin las piezas: puentes, escaleras, arena, nido). Pequeñas ondulaciones.
static func altura(x: float, z: float) -> float:
	if x < X_BORDE_O + 2.0:                                              # cornisa alta
		var y := ALTO + 0.07 * _n(x * 2.0, z * 2.0)
		if z > Z_FIN_CAMINO - 6.0:                                       # el camino de entrada baja un poco
			y -= 0.05 * (z - (Z_FIN_CAMINO - 6.0))
		return y
	return BAJO + 0.07 * _n(x * 2.0 + 50.0, z * 2.0)                     # cornisa baja


# ---------------------------------------------------------------- por dónde se anda
const MARGEN_MURO := 1.3          # la cámara nunca se mete en la roca: Kael no pega la espalda al muro
const MARGEN_BORDE := 0.25


# ¿Se puede pisar el punto (x, z)? Los niveles no se solapan en planta: lo de arriba (oeste), lo de abajo (este), la
# escalera de la presa, la bajada y el nido, el levadizo (bajado) y la arena están en sitios distintos del plano.
static func andable(p: Vector3, levadizo_bajado: bool) -> bool:
	var x := p.x
	var z := p.z
	if z > Z_FIN_CAMINO or z < Z_NORTE + 1.5:
		return false
	# arena (sobre su pilar)
	var da := Vector2(x - ARENA.x, z - ARENA.z).length()
	if da < ARENA_RADIO - 0.6:
		return true
	# escalera de la presa
	if z > ESCALERA_Z[0] + 0.15 and z < ESCALERA_Z[1] - 0.15 and x >= X_BORDE_O - 0.5 and x <= X_BORDE_E + 0.5:
		return true
	# puente levadizo, si está bajado
	if levadizo_bajado and absf(z - LEVADIZO_Z) < LEVADIZO_ANCHO * 0.5 - 0.35 and x > X_BORDE_O - 0.5 and x < APOYO.x + 0.5:
		return true
	# bajada al nido y repisa del nido
	if x > BAJADA_X[0] + 0.2 and x < X_BORDE_E + 1.0 and z > BAJADA_RELLANO[0] and z < BAJADA_RELLANO[1] - 0.15:
		return true
	if x > BAJADA_X[0] + 0.2 and x < BAJADA_X[1] - 0.2 and z >= BAJADA_Z[0] - 1.0 and z <= BAJADA_RELLANO[0] + 0.1:
		return true                                                       # (hasta pisar ya la repisa del nido)
	var dn := Vector2((x - NIDO_CENTRO.x) / (NIDO_RADIOS.x - 0.7), (z - NIDO_CENTRO.z) / (NIDO_RADIOS.y - 0.7)).length()
	if dn < 1.0:
		return true
	# cornisa alta (oeste)
	if x < X_BORDE_O + 1.5:
		if x < muro_oeste(z) + MARGEN_MURO or x > borde_oeste(z) - MARGEN_BORDE:
			return false
		if z < PASO_PUERTA[0] - 1.5:
			return false                                                  # más al norte, solo la arena (se solapan)
		for i in HUECOS.size():                                           # en los huecos, solo sobre el puente
			var h: Array = HUECOS[i]
			if z > h[0] - 0.7 and z < h[1] + 0.7:
				return absf(x - X_CAMINO_O) < ANCHO_PUENTE * 0.5 - 0.3
		return true
	# cornisa baja (este)
	if x > X_BORDE_E - 1.5:
		if z > Z_CORNISA_E - 0.5 or z < GRIETA[0]:
			return false
		return x > borde_este(z) + MARGEN_BORDE and x < muro_este(z) - MARGEN_MURO
	return false
