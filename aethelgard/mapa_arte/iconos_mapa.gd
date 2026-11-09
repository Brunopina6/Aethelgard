extends RefCounted
# Iconos de los lugares del mapamundi (T-085), dibujados por código: un hito ilustrado por destino, con la misma
# luz que el mapa (de arriba a la izquierda), tinta fina y los acentos de la marca (oro, lavanda, estrella de cuatro
# puntas). generar_mapa.gd los pinta a 4× y los reduce (iconos/<índice>.png, 112×104). En el juego se dibujan en
# vivo sobre el mapa, con su base en la posición funcional del lugar (ANCLA), así lo dibujado y la zona de
# «Entrar» (RADIO_LUGAR de mapa.gd) salen del mismo dato.
# Índices: los de LUGARES de mapa.gd (0-9) y 10 = Pastos Verdes (LUGAR_PASTOS).

const TAM := Vector2i(112, 104)
const ANCLA := Vector2(56, 92)        # punto del icono que va sobre la posición del lugar

const TINTA := Color(0.13, 0.10, 0.17)
const PIEDRA := Color(0.88, 0.82, 0.72)
const PIEDRA_S := Color(0.58, 0.56, 0.66)
const TEJA := Color(0.80, 0.36, 0.24)
const TEJA_S := Color(0.55, 0.22, 0.22)
const ORO := Color(0.96, 0.79, 0.42)
const ORO_S := Color(0.70, 0.50, 0.22)
const VIOLETA := Color(0.43, 0.29, 0.85)
const LAVANDA := Color(0.73, 0.65, 0.96)
const VERDE := Color(0.33, 0.66, 0.30)
const VERDE_S := Color(0.15, 0.40, 0.25)
const AGUA := Color(0.38, 0.78, 0.86)
const NIEVE := Color(0.98, 0.99, 1.0)
const NIEVE_S := Color(0.72, 0.80, 0.96)
const ARENA := Color(0.95, 0.83, 0.58)
const BRASA := Color(1.0, 0.48, 0.24)
const MARFIL := Color(1.0, 0.96, 0.89)


static func dibujar(c: CanvasItem, indice: int) -> void:
	match indice:
		0: _oakhaven(c)
		1: _bosque(c)
		2: _garganta(c)
		3: _cumbres(c)
		4: _mar_arena(c)
		5: _sunken(c)
		6: _valle(c)
		7: _templo(c)
		8: _abismo(c)
		9: _portal(c)
		10: _pastos(c)


# ------------------------------------------------------------------ piezas

static func _poli(c: CanvasItem, pts: PackedVector2Array, col: Color, tinta := true, ancho := 1.5) -> void:
	c.draw_colored_polygon(pts, col)
	if tinta:
		var l := PackedVector2Array(pts)
		l.append(pts[0])
		c.draw_polyline(l, TINTA, ancho, true)


static func _elipse(cen: Vector2, rx: float, ry: float, n := 28, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var l := PackedVector2Array()
	for i in n:
		var a := a0 + (a1 - a0) * i / float(n - (0 if is_equal_approx(a1 - a0, TAU) else 1))
		l.append(cen + Vector2(cos(a) * rx, sin(a) * ry))
	return l


static func _sombra(c: CanvasItem, cen: Vector2, rx: float, ry: float) -> void:
	for k in 4:
		var f := 1.0 - k * 0.18
		c.draw_colored_polygon(_elipse(cen + Vector2(3, 1), rx * f, ry * f), Color(0.06, 0.08, 0.20, 0.12))


static func estrella(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := k * PI / 4.0 - PI / 2.0
		pts.append(p + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.3))
	c.draw_colored_polygon(pts, col)


static func _halo(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	for k in 6:
		var f := 1.0 - k * 0.15
		c.draw_colored_polygon(_elipse(p, r * f, r * f, 24), Color(col, col.a * 0.16))


# Torre redonda: cuerpo con lado al sol y lado en sombra, almenas o tejado cónico.
static func _torre(c: CanvasItem, x: float, base: float, w: float, h: float, tejado := true) -> void:
	var cuerpo := PackedVector2Array([Vector2(x - w / 2, base), Vector2(x - w / 2, base - h), Vector2(x + w / 2, base - h), Vector2(x + w / 2, base)])
	_poli(c, cuerpo, PIEDRA)
	c.draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.1, base - 0.5), Vector2(x + w * 0.1, base - h + 0.8), Vector2(x + w / 2 - 0.8, base - h + 0.8), Vector2(x + w / 2 - 0.8, base - 0.5)]), PIEDRA_S)
	c.draw_rect(Rect2(x - 1.5, base - h * 0.6, 3, 4), TINTA)
	if tejado:
		var t := PackedVector2Array([Vector2(x - w / 2 - 2.5, base - h), Vector2(x, base - h - w * 1.15), Vector2(x + w / 2 + 2.5, base - h)])
		_poli(c, t, TEJA)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, base - h - w * 1.15 + 1.5), Vector2(x + w / 2 + 1.0, base - h - 0.7), Vector2(x + 1.0, base - h - 0.7)]), TEJA_S)
	else:
		for k in 3:
			c.draw_rect(Rect2(x - w / 2 + k * w / 2.5, base - h - 3, w / 5, 3), PIEDRA)


static func _casa(c: CanvasItem, x: float, base: float, w: float, h: float) -> void:
	_poli(c, PackedVector2Array([Vector2(x - w / 2, base), Vector2(x - w / 2, base - h), Vector2(x + w / 2, base - h), Vector2(x + w / 2, base)]), PIEDRA, true, 1.2)
	_poli(c, PackedVector2Array([Vector2(x - w / 2 - 2, base - h), Vector2(x, base - h - w * 0.55), Vector2(x + w / 2 + 2, base - h)]), TEJA, true, 1.2)
	c.draw_colored_polygon(PackedVector2Array([Vector2(x, base - h - w * 0.55 + 1), Vector2(x + w / 2 + 1, base - h - 0.6), Vector2(x, base - h - 0.6)]), TEJA_S)
	c.draw_rect(Rect2(x - 1.2, base - h * 0.55, 2.4, h * 0.55 - 0.5), Color(0.30, 0.20, 0.16))


static func _copa(c: CanvasItem, p: Vector2, r: float, col: Color, tinta := true) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var rr := r * (1.0 + 0.07 * sin(a * 5.0 + r))
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	_poli(c, pts, col, tinta, 1.3)
	c.draw_colored_polygon(_elipse(p + Vector2(r * 0.22, r * 0.25), r * 0.72, r * 0.62), Color(col.darkened(0.32), 0.85))
	c.draw_colored_polygon(_elipse(p + Vector2(-r * 0.3, -r * 0.32), r * 0.42, r * 0.34), Color(col.lightened(0.28), 0.9))


# ------------------------------------------------------------------ iconos

# Oakhaven: ciudadela amurallada con torres de tejado rojo y el Árbol Milenario en el centro (halo dorado).
static func _oakhaven(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 46, 11)
	# muralla del fondo
	_poli(c, PackedVector2Array([Vector2(14, 78), Vector2(20, 62), Vector2(92, 62), Vector2(98, 78)]), PIEDRA_S)
	# Árbol Milenario
	_halo(c, Vector2(56, 34), 30, Color(1.0, 0.86, 0.45, 0.9))
	c.draw_colored_polygon(PackedVector2Array([Vector2(52, 66), Vector2(54, 40), Vector2(58, 40), Vector2(61, 66)]), Color(0.45, 0.30, 0.20))
	_copa(c, Vector2(44, 38), 13, Color(0.40, 0.70, 0.30))
	_copa(c, Vector2(68, 38), 13, Color(0.38, 0.68, 0.30))
	_copa(c, Vector2(56, 27), 16, Color(0.46, 0.76, 0.32))
	estrella(c, Vector2(57, 22), 4.5, Color(1.0, 0.95, 0.70))
	# casas dentro de la muralla
	_casa(c, 30, 74, 13, 9)
	_casa(c, 82, 74, 13, 9)
	_casa(c, 44, 79, 12, 9)
	_casa(c, 69, 79, 12, 9)
	# muralla delantera con puerta
	var frente := PackedVector2Array([Vector2(10, 92), Vector2(10, 80), Vector2(102, 80), Vector2(102, 92)])
	_poli(c, frente, PIEDRA)
	c.draw_colored_polygon(PackedVector2Array([Vector2(60, 91), Vector2(60, 81), Vector2(101, 81), Vector2(101, 91)]), Color(PIEDRA_S, 0.55))
	for k in 12:
		c.draw_rect(Rect2(11 + k * 7.6, 77, 4, 3), PIEDRA if k < 7 else PIEDRA_S)
	_poli(c, PackedVector2Array([Vector2(50, 92), Vector2(50, 85), Vector2(53, 82), Vector2(59, 82), Vector2(62, 85), Vector2(62, 92)]), Color(0.32, 0.20, 0.14), true, 1.2)
	_torre(c, 12, 93, 11, 26)
	_torre(c, 100, 93, 11, 26)
	_torre(c, 40, 91, 9, 16, false)
	_torre(c, 72, 91, 9, 16, false)
	# estandarte dorado
	c.draw_line(Vector2(12, 56), Vector2(12, 44), TINTA, 1.2)
	c.draw_colored_polygon(PackedVector2Array([Vector2(12, 44), Vector2(21, 46), Vector2(12, 49)]), ORO)


# Gran Bosque Verde: el árbol santuario con el Núcleo de la Naturaleza brillando a sus pies y dos piedras
# (una rota: el santuario está profanado).
static func _bosque(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 40, 10)
	c.draw_colored_polygon(PackedVector2Array([Vector2(48, 88), Vector2(51, 50), Vector2(61, 50), Vector2(65, 88)]), Color(0.42, 0.28, 0.18))
	c.draw_colored_polygon(PackedVector2Array([Vector2(57, 88), Vector2(58, 52), Vector2(61, 52), Vector2(65, 88)]), Color(0.30, 0.19, 0.13))
	c.draw_polyline(PackedVector2Array([Vector2(48, 88), Vector2(51, 50)]), TINTA, 1.2, true)
	c.draw_polyline(PackedVector2Array([Vector2(65, 88), Vector2(61, 50)]), TINTA, 1.2, true)
	_copa(c, Vector2(32, 46), 16, Color(0.20, 0.52, 0.26))
	_copa(c, Vector2(80, 46), 16, Color(0.20, 0.50, 0.27))
	_copa(c, Vector2(42, 28), 18, Color(0.27, 0.60, 0.28))
	_copa(c, Vector2(72, 28), 18, Color(0.25, 0.58, 0.28))
	_copa(c, Vector2(57, 18), 19, Color(0.32, 0.67, 0.30))
	# el Núcleo
	_halo(c, Vector2(56, 78), 20, Color(0.55, 1.0, 0.55, 0.9))
	c.draw_colored_polygon(_elipse(Vector2(56, 78), 6, 6, 20), Color(0.75, 1.0, 0.70))
	estrella(c, Vector2(56, 78), 9, Color(0.95, 1.0, 0.85))
	# piedras del santuario
	_poli(c, PackedVector2Array([Vector2(24, 92), Vector2(25, 70), Vector2(31, 67), Vector2(34, 92)]), PIEDRA)
	_poli(c, PackedVector2Array([Vector2(80, 92), Vector2(81, 80), Vector2(85, 74), Vector2(88, 79), Vector2(90, 92)]), PIEDRA_S)


# Garganta del Diablo: dos paredes de roca, el abismo oscuro con un brillo rojo al fondo y un puente colgante.
static func _garganta(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 46, 10)
	_poli(c, PackedVector2Array([Vector2(8, 92), Vector2(12, 50), Vector2(24, 36), Vector2(38, 42), Vector2(46, 60), Vector2(44, 92)]), Color(0.70, 0.62, 0.52))
	c.draw_colored_polygon(PackedVector2Array([Vector2(30, 90), Vector2(38, 46), Vector2(45, 61), Vector2(43, 90)]), Color(0.52, 0.48, 0.52))
	_poli(c, PackedVector2Array([Vector2(68, 92), Vector2(66, 58), Vector2(74, 40), Vector2(90, 34), Vector2(100, 52), Vector2(104, 92)]), Color(0.60, 0.55, 0.58))
	c.draw_colored_polygon(PackedVector2Array([Vector2(86, 90), Vector2(91, 37), Vector2(99, 53), Vector2(103, 90)]), Color(0.44, 0.42, 0.52))
	# el abismo
	c.draw_colored_polygon(PackedVector2Array([Vector2(45, 92), Vector2(46, 62), Vector2(66, 60), Vector2(67, 92)]), Color(0.10, 0.07, 0.12))
	_halo(c, Vector2(56, 90), 12, Color(1.0, 0.30, 0.15, 0.9))
	# puente colgante
	var tabla := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		tabla.append(Vector2(lerpf(38, 74, t), 52 + sin(PI * t) * 7.0))
	c.draw_polyline(tabla, Color(0.45, 0.30, 0.18), 3.2, true)
	for i in range(0, 13, 2):
		c.draw_line(tabla[i] + Vector2(0, -1.5), tabla[i] + Vector2(0, 1.5), Color(0.30, 0.18, 0.10), 1.2)
	var cuerda := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		cuerda.append(Vector2(lerpf(38, 74, t), 45 + sin(PI * t) * 6.0))
	c.draw_polyline(cuerda, Color(0.30, 0.20, 0.12), 1.1, true)
	for i in range(1, 12, 2):
		c.draw_line(cuerda[i], tabla[i], Color(0.30, 0.20, 0.12, 0.8), 0.8)
	c.draw_line(Vector2(38, 44), Vector2(38, 54), TINTA, 1.6)
	c.draw_line(Vector2(74, 44), Vector2(74, 54), TINTA, 1.6)


# Cumbres de Ciclópea: un pico helado más alto que los del mapa, con un destello de hielo en la cima.
static func _cumbres(c: CanvasItem) -> void:
	_sombra(c, Vector2(58, 90), 46, 10)
	_poli(c, PackedVector2Array([Vector2(60, 92), Vector2(78, 48), Vector2(86, 40), Vector2(108, 92)]), NIEVE_S)
	c.draw_colored_polygon(PackedVector2Array([Vector2(86, 41), Vector2(91, 60), Vector2(84, 66), Vector2(79, 50)]), NIEVE)
	var izq := PackedVector2Array([Vector2(6, 92), Vector2(24, 60), Vector2(34, 52), Vector2(44, 30), Vector2(54, 8), Vector2(60, 40), Vector2(55, 92)])
	_poli(c, izq, NIEVE)
	var der := PackedVector2Array([Vector2(54, 8), Vector2(66, 30), Vector2(76, 52), Vector2(90, 92), Vector2(55, 92), Vector2(60, 40)])
	_poli(c, der, NIEVE_S)
	for k in 5:
		c.draw_line(Vector2(56 + k * 5, 50 + k * 6), Vector2(62 + k * 5, 60 + k * 6), Color(0.55, 0.62, 0.82, 0.8), 1.2)
		c.draw_line(Vector2(48 - k * 5, 46 + k * 7), Vector2(40 - k * 5, 56 + k * 7), Color(0.78, 0.84, 0.95, 0.9), 1.1)
	_halo(c, Vector2(54, 10), 14, Color(0.70, 0.90, 1.0, 0.9))
	estrella(c, Vector2(54, 10), 8, Color(0.92, 0.98, 1.0))


# Mar de Arena de Calid: dunas, un arco roto y columnas medio enterradas; el disco del Lente del Sol encima.
static func _mar_arena(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 48, 9)
	_halo(c, Vector2(78, 26), 16, Color(1.0, 0.85, 0.40, 0.9))
	c.draw_colored_polygon(_elipse(Vector2(78, 26), 7, 7, 24), Color(1.0, 0.88, 0.50))
	for k in 8:
		var a := TAU * k / 8.0
		c.draw_line(Vector2(78, 26) + Vector2(cos(a), sin(a)) * 9.5, Vector2(78, 26) + Vector2(cos(a), sin(a)) * 13.5, ORO, 1.6)
	# arco roto (arenisca más oscura que la arena, para que se lea sobre el desierto)
	var piedra := Color(0.86, 0.66, 0.44)
	var piedra_s := Color(0.62, 0.44, 0.34)
	_poli(c, PackedVector2Array([Vector2(26, 86), Vector2(26, 50), Vector2(33, 50), Vector2(33, 86)]), piedra)
	c.draw_colored_polygon(PackedVector2Array([Vector2(30, 85), Vector2(30, 51), Vector2(32.3, 51), Vector2(32.3, 85)]), piedra_s)
	_poli(c, PackedVector2Array([Vector2(52, 86), Vector2(52, 58), Vector2(59, 55), Vector2(59, 86)]), piedra_s)
	var arco := PackedVector2Array([Vector2(24, 52), Vector2(30, 40), Vector2(42, 36), Vector2(50, 40), Vector2(48, 46), Vector2(40, 43), Vector2(33, 47), Vector2(35, 52)])
	_poli(c, arco, piedra)
	# columna tumbada y otra en pie
	_poli(c, PackedVector2Array([Vector2(66, 86), Vector2(66, 62), Vector2(72, 62), Vector2(72, 86)]), piedra)
	c.draw_colored_polygon(PackedVector2Array([Vector2(69.5, 85), Vector2(69.5, 63), Vector2(71.3, 63), Vector2(71.3, 85)]), piedra_s)
	c.draw_rect(Rect2(64.5, 59, 9, 3.5), piedra)
	_poli(c, PackedVector2Array([Vector2(76, 88), Vector2(98, 82), Vector2(100, 87), Vector2(78, 93)]), piedra_s)
	# dunas delante
	var duna := PackedVector2Array([Vector2(4, 94)])
	for i in 21:
		var x := 4.0 + i * 5.2
		duna.append(Vector2(x, 86 - 6.0 * sin(i * 0.55) - 2.0 * sin(i * 1.7)))
	duna.append(Vector2(108, 94))
	_poli(c, duna, Color(0.95, 0.80, 0.52))


# Sunken City: la ciudad dentro del esqueleto de un barco de guerra antiguo, junto al agua.
static func _sunken(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 91), 50, 10)
	c.draw_colored_polygon(_elipse(Vector2(56, 92), 52, 9, 32), Color(AGUA, 0.85))
	# quilla y costillas de hueso
	var quilla := PackedVector2Array([Vector2(8, 84), Vector2(30, 90), Vector2(82, 90), Vector2(106, 80), Vector2(100, 86), Vector2(82, 94), Vector2(30, 94), Vector2(10, 88)])
	_poli(c, quilla, MARFIL.darkened(0.12))
	for k in 7:
		var x := 20.0 + k * 12.0
		var alto := 46.0 + 8.0 * sin(PI * (k + 0.5) / 7.0)
		var costilla := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			costilla.append(Vector2(x - 9.0 * sin(t * 1.4) + 4.0, 90.0 - alto * t))
		c.draw_polyline(costilla, TINTA, 4.2, true)
		c.draw_polyline(costilla, MARFIL, 2.6, true)
	# casas dentro
	_casa(c, 34, 86, 13, 11)
	_casa(c, 52, 84, 15, 13)
	_casa(c, 72, 86, 13, 10)
	# mástil con farol
	c.draw_line(Vector2(88, 88), Vector2(88, 30), TINTA, 2.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(88, 32), Vector2(102, 36), Vector2(88, 42)]), Color(0.25, 0.55, 0.75))
	_halo(c, Vector2(84, 52), 8, Color(1.0, 0.85, 0.45, 0.9))
	c.draw_colored_polygon(_elipse(Vector2(84, 52), 2.4, 2.4, 12), Color(1.0, 0.92, 0.6))


# Valle de los Ecos: espejos de agua que reflejan un cielo estrellado, entre piedras de pie.
static func _valle(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 44, 10)
	for e in [[Vector2(36, 80), 20.0, 8.0], [Vector2(72, 84), 18.0, 7.0], [Vector2(58, 68), 14.0, 5.5]]:
		var cen: Vector2 = e[0]
		c.draw_colored_polygon(_elipse(cen, e[1] + 1.6, e[2] + 1.6, 28), Color(0.85, 0.80, 1.0))
		c.draw_colored_polygon(_elipse(cen, e[1], e[2], 28), Color(0.16, 0.18, 0.44))
		c.draw_colored_polygon(_elipse(cen + Vector2(-3, -1.5), e[1] * 0.6, e[2] * 0.5, 20), Color(0.30, 0.32, 0.66))
		estrella(c, cen + Vector2(e[1] * 0.3, -1), 3.0, MARFIL)
	# piedras de pie
	_poli(c, PackedVector2Array([Vector2(14, 90), Vector2(15, 52), Vector2(21, 46), Vector2(26, 52), Vector2(25, 90)]), Color(0.64, 0.58, 0.74))
	c.draw_colored_polygon(PackedVector2Array([Vector2(21, 89), Vector2(21, 48), Vector2(25.5, 53), Vector2(24.5, 89)]), Color(0.45, 0.40, 0.58))
	_poli(c, PackedVector2Array([Vector2(88, 92), Vector2(89, 60), Vector2(94, 55), Vector2(99, 61), Vector2(98, 92)]), Color(0.64, 0.58, 0.74))
	c.draw_colored_polygon(PackedVector2Array([Vector2(94, 91), Vector2(94, 57), Vector2(98.5, 62), Vector2(97.5, 91)]), Color(0.45, 0.40, 0.58))
	# estrellas en el cielo del valle
	for s in [[Vector2(40, 30), 5.0], [Vector2(62, 18), 7.0], [Vector2(80, 36), 4.0], [Vector2(28, 14), 3.0]]:
		_halo(c, s[0], s[1] * 1.8, Color(LAVANDA, 0.8))
		estrella(c, s[0], s[1], MARFIL)


# Templo Sumergido de Atlantis: templo de cúpula turquesa con columnas, medio dentro del agua.
static func _templo(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 46, 10)
	_halo(c, Vector2(56, 40), 30, Color(0.50, 0.95, 0.95, 0.8))
	_poli(c, PackedVector2Array([Vector2(22, 56), Vector2(56, 44), Vector2(90, 56)]), PIEDRA)
	var cupula := _elipse(Vector2(56, 44), 22, 22, 26, PI, TAU)
	_poli(c, cupula, Color(0.34, 0.76, 0.76))
	c.draw_colored_polygon(_elipse(Vector2(48, 34), 7, 6, 16), Color(0.62, 0.92, 0.88, 0.85))
	estrella(c, Vector2(56, 20), 5, MARFIL)
	c.draw_line(Vector2(56, 22), Vector2(56, 14), TINTA, 1.2)
	_poli(c, PackedVector2Array([Vector2(20, 60), Vector2(20, 55), Vector2(92, 55), Vector2(92, 60)]), PIEDRA)
	for k in 6:
		var x := 26.0 + k * 12.0
		_poli(c, PackedVector2Array([Vector2(x - 3, 88), Vector2(x - 3, 60), Vector2(x + 3, 60), Vector2(x + 3, 88)]), PIEDRA if k < 3 else PIEDRA_S, true, 1.1)
	# el agua tapa la base
	var agua := _elipse(Vector2(56, 88), 54, 11, 32)
	c.draw_colored_polygon(agua, Color(0.30, 0.70, 0.82, 0.92))
	for k in 4:
		c.draw_line(Vector2(18 + k * 22, 84 + (k % 2) * 4), Vector2(30 + k * 22, 84 + (k % 2) * 4), Color(0.85, 0.97, 1.0, 0.9), 1.3)


# Abismo de Ceniza: la fortaleza de agujas negras, con ventanas encendidas y brasas al pie.
static func _abismo(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 46, 10)
	_halo(c, Vector2(56, 86), 30, Color(1.0, 0.40, 0.15, 0.9))
	var roca := PackedVector2Array([Vector2(6, 94), Vector2(16, 80), Vector2(30, 82), Vector2(40, 74), Vector2(72, 74), Vector2(84, 80), Vector2(98, 78), Vector2(106, 94)])
	_poli(c, roca, Color(0.24, 0.20, 0.25))
	var negro := Color(0.17, 0.14, 0.20)
	var gris := Color(0.30, 0.26, 0.33)
	for t in [[56.0, 12.0, 74.0, 13.0], [36.0, 32.0, 76.0, 10.0], [76.0, 28.0, 76.0, 10.0], [22.0, 50.0, 82.0, 8.0], [90.0, 48.0, 80.0, 8.0]]:
		var x: float = t[0]
		var cima: float = t[1]
		var base: float = t[2]
		var w: float = t[3]
		_poli(c, PackedVector2Array([Vector2(x - w / 2, base), Vector2(x - w / 2, cima + w * 1.4), Vector2(x, cima), Vector2(x + w / 2, cima + w * 1.4), Vector2(x + w / 2, base)]), gris)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, cima + 1.5), Vector2(x + w / 2 - 0.8, cima + w * 1.4), Vector2(x + w / 2 - 0.8, base - 0.5), Vector2(x, base - 0.5)]), negro)
		c.draw_rect(Rect2(x - 1.3, cima + w * 2.0, 2.6, 4.0), BRASA)
	for k in 3:
		c.draw_rect(Rect2(46 + k * 8, 62, 3, 5), Color(1.0, 0.70, 0.30))
	# humo
	for k in 3:
		c.draw_colored_polygon(_elipse(Vector2(40 + k * 14, 16 - k * 3), 8 - k, 5 - k * 0.8, 16), Color(0.35, 0.30, 0.38, 0.35))


# Portal del Vacío: el arco de oro con su remolino morado (como el portal de la ciudad flotante).
static func _portal(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 34, 9)
	_halo(c, Vector2(56, 52), 30, Color(VIOLETA, 0.9))
	var hueco := _elipse(Vector2(56, 50), 17, 26, 32)
	c.draw_colored_polygon(hueco, Color(0.28, 0.14, 0.52))
	for k in 3:                                         # remolino
		var esp := PackedVector2Array()
		for i in 30:
			var t := i / 29.0
			var a := t * TAU * 1.4 + k * TAU / 3.0
			esp.append(Vector2(56, 50) + Vector2(cos(a) * 15.0 * t, sin(a) * 23.0 * t))
		c.draw_polyline(esp, Color(LAVANDA, 0.9), 2.0, true)
	estrella(c, Vector2(56, 50), 6, MARFIL)
	# arco dorado
	var arco_ext := _elipse(Vector2(56, 50), 25, 34, 30, PI, TAU)
	var arco_int := _elipse(Vector2(56, 50), 17, 26, 30, PI, TAU)
	var arco := PackedVector2Array(arco_ext)
	for i in range(arco_int.size() - 1, -1, -1):
		arco.append(arco_int[i])
	_poli(c, arco, ORO)
	_poli(c, PackedVector2Array([Vector2(31, 92), Vector2(31, 50), Vector2(39, 50), Vector2(39, 92)]), ORO)
	_poli(c, PackedVector2Array([Vector2(73, 92), Vector2(73, 50), Vector2(81, 50), Vector2(81, 92)]), ORO_S)
	estrella(c, Vector2(56, 14), 5, ORO)


# Pastos Verdes: colinas verdes, un puente de piedra con arco sobre el arroyo, la cascada y los faroles de Tilo.
static func _pastos(c: CanvasItem) -> void:
	_sombra(c, Vector2(56, 90), 46, 9)
	_poli(c, PackedVector2Array([Vector2(60, 92), Vector2(70, 48), Vector2(84, 38), Vector2(100, 46), Vector2(108, 92)]), Color(0.42, 0.70, 0.32))
	# cascada
	c.draw_colored_polygon(PackedVector2Array([Vector2(80, 44), Vector2(88, 44), Vector2(90, 80), Vector2(78, 80)]), Color(0.70, 0.92, 0.98))
	for k in 3:
		c.draw_line(Vector2(81 + k * 3, 46), Vector2(80 + k * 4, 78), Color(1, 1, 1, 0.8), 1.0)
	var colina := PackedVector2Array([Vector2(4, 92), Vector2(10, 70), Vector2(26, 58), Vector2(42, 62), Vector2(54, 74), Vector2(60, 92)])
	_poli(c, colina, Color(0.55, 0.80, 0.36))
	# arroyo y puente
	c.draw_colored_polygon(_elipse(Vector2(60, 90), 34, 5, 24), Color(AGUA, 0.9))
	var puente := PackedVector2Array([Vector2(36, 90), Vector2(38, 80), Vector2(84, 80), Vector2(86, 90), Vector2(74, 90)])
	var ojo := _elipse(Vector2(61, 90), 12, 8, 14, PI, TAU)
	for i in range(ojo.size() - 1, -1, -1):
		puente.append(ojo[i])
	puente.append(Vector2(48, 90))
	_poli(c, puente, PIEDRA)
	c.draw_line(Vector2(38, 80), Vector2(84, 80), PIEDRA_S, 1.5)
	# faroles
	for x in [42.0, 80.0]:
		c.draw_line(Vector2(x, 80), Vector2(x, 66), TINTA, 1.5)
		_halo(c, Vector2(x, 64), 8, Color(1.0, 0.85, 0.40, 0.9))
		c.draw_colored_polygon(_elipse(Vector2(x, 64), 2.6, 3.2, 12), Color(1.0, 0.90, 0.55))
