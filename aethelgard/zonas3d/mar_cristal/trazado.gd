extends RefCounted
# El trazado del primer sector del Mar de Cristal, «La Orilla de Vidrio» (V12; docs/v12/DISENO_V12.md): sitios, la
# altura de las dunas, por dónde se anda y cuántos encuentros hay. Sin escena: lo usan la región (mar_cristal_3d.gd),
# el terreno (terreno.gd) y las pruebas. Metros; X de oeste a este, Z de norte (0) a sur (TAM.y). La cámara mira al
# norte y no gira.

const TAM := Vector2(90.0, 110.0)
const ENTRADA := Vector3(45.0, 0.0, 101.5)       # al entrar desde el mapa
const SALIDA := Vector3(45.0, 0.0, 106.5)        # el camino de vuelta al mapa
const CAMPAMENTO := Vector2(36.0, 92.0)
const CARTOGRAFA := Vector2(37.5, 96.5)
const FOGATA := Vector2(35.0, 94.5)
const TIENDAS := [Vector2(30.0, 89.0), Vector2(41.0, 88.0)]
const CARAVANA := Vector2(50.0, 60.0)
const OASIS := Vector2(74.0, 72.0)
const RADIO_OASIS := 9.0
const RADIO_ESTANQUE := 4.6                      # el agua: no se pisa
const RUINAS := Vector2(45.0, 18.0)
const TRAMPILLA := Vector2(45.0, 23.0)
const COBIJO := Vector2(14.0, 48.0)              # bajo la roca saliente: refugio de la tormenta
const RADIO_COBIJO := 3.2
const ESPEJISMO := Vector2(82.0, 30.0)
const ESQUELETO := Vector2(9.0, 30.0)
const TEMBLOR := Rect2(60.0, 20.0, 28.0, 30.0)   # la arena que tiembla (el gusano)
# El camino de la caravana (de la entrada al campamento, a los restos y a las ruinas): llano y más firme.
const CAMINO := [Vector2(45.0, 108.0), Vector2(44.0, 97.0), Vector2(46.0, 80.0), Vector2(50.0, 62.0), Vector2(47.0, 40.0),
	Vector2(45.0, 24.0)]
const ANCHO_CAMINO := 2.6
# Las rocas del cañón del oeste (centro x, z, radio, alto): no se atraviesan. La saliente del cobijo va aparte.
const ROCAS := [[6.0, 24.0, 5.5, 7.0], [10.0, 36.0, 4.0, 6.0], [5.0, 44.0, 4.5, 8.0], [9.0, 58.0, 5.0, 6.5],
	[5.0, 70.0, 5.5, 7.5], [12.0, 80.0, 3.5, 5.0], [16.0, 41.0, 2.4, 4.0], [18.0, 54.0, 2.2, 3.5], [70.0, 98.0, 3.0, 3.0],
	[84.0, 86.0, 4.0, 4.5], [26.0, 30.0, 2.0, 2.4]]
const SALIENTE := [12.6, 48.0, 3.8, 3.4]         # la roca del cobijo: techo a 3,4 m, se pasa por debajo


# La altura de la arena en (x, z): dunas suaves que crecen hacia el este y el norte, aplanadas en el camino, el
# campamento, los restos y las ruinas; el oasis, una hondonada. Siempre la misma (sin azar): pruebas y móvil iguales.
static func altura(x: float, z: float) -> float:
	var d := 1.25 * sin(0.085 * x + 0.9 * sin(0.045 * z)) + 0.85 * sin(0.12 * z + 0.05 * x + 1.3) \
		+ 0.35 * sin(0.31 * x - 0.22 * z)
	d = d + 1.1                                                 # que no baje del llano
	var crece := clampf((x - 20.0) / 50.0, 0.25, 1.0) * clampf((112.0 - z) / 40.0, 0.4, 1.0)
	var h := d * crece
	var llano := maxf(maxf(_cerca(Vector2(x, z), CAMPAMENTO, 9.0), _cerca(Vector2(x, z), CARAVANA, 6.5)),
		maxf(_cerca(Vector2(x, z), RUINAS, 11.0), _cerca(Vector2(x, z), COBIJO, 5.0)))
	llano = maxf(llano, _cerca_camino(Vector2(x, z)))
	h = lerpf(h, 0.0, llano)
	var o := _cerca(Vector2(x, z), OASIS, RADIO_OASIS)        # la hondonada del oasis
	if o > 0.0:
		h = lerpf(h, -0.9, o)
	return h


# 1 dentro del radio r1 = r × 0,55, 0 fuera de r; suave entre medias.
static func _cerca(p: Vector2, c: Vector2, r: float) -> float:
	var d := p.distance_to(c)
	return 1.0 - smoothstep(r * 0.55, r, d)


static func _cerca_camino(p: Vector2) -> float:
	var dmin := INF
	for i in CAMINO.size() - 1:
		dmin = minf(dmin, _dist_segmento(p, CAMINO[i], CAMINO[i + 1]))
	return 1.0 - smoothstep(ANCHO_CAMINO * 0.5, ANCHO_CAMINO * 1.6, dmin)


static func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func en_camino(x: float, z: float) -> bool:
	return _cerca_camino(Vector2(x, z)) > 0.5


static func en_temblor(x: float, z: float) -> bool:
	return TEMBLOR.has_point(Vector2(x, z))


static func en_cobijo(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(COBIJO) < RADIO_COBIJO


# Por dónde no se anda: fuera del sector, el agua del estanque, dentro de las rocas.
static func prohibido(x: float, z: float) -> bool:
	if x < 2.0 or x > TAM.x - 2.0 or z < 2.0 or z > TAM.y - 1.0:
		return true
	if Vector2(x, z).distance_to(OASIS) < RADIO_ESTANQUE:
		return true
	for r in ROCAS:
		if Vector2(x, z).distance_to(Vector2(r[0], r[1])) < float(r[2]) * 0.82:
			return true
	return false


# Cuántos encuentros: ninguno en el campamento, las ruinas, el cobijo ni el oasis; normal en las dunas; algo más en la
# arena que tiembla. (El ritmo lo pone progreso.gd, como en las demás regiones.)
static func ritmo(x: float, z: float) -> float:
	var p := Vector2(x, z)
	if p.distance_to(CAMPAMENTO) < 14.0 or p.distance_to(RUINAS) < 12.0 or en_cobijo(x, z) or p.distance_to(OASIS) < 11.0:
		return 0.0
	if en_temblor(x, z):
		return 1.3
	return 0.6 if en_camino(x, z) else 1.0
