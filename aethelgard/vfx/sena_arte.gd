extends Node2D
# Señas de las artes (T-100): la silueta de cada una, dibujada con líneas y polígonos, sin partículas ni luces 2D, para
# que se lea igual en el perfil bajo del móvil (allí las partículas bajan al 40 % y las luces se apagan). La crea
# combate.gd (_sena_arte) en su capa «escena», sobre el luchador (este nodo va en su centro), y se borra sola al acabar.
# No toca reglas ni tira del generador aleatorio global: es solo dibujo.
#   alba:    un anillo con cuatro marcas, como la esfera de un reloj, que gira sobre el aliado y marca el ritmo: cada
#            tiempo se enciende una marca y el anillo late; al final se cierra y sube (el turno llega antes).
#   ocaso:   el mismo anillo, violeta, gira al revés y baja aplastando al enemigo; sus marcas se apagan (pierde tiempo).
#   lumbre:  una brasa sale de Lya y vuela hasta el caído; al llegar (cuando vuelve), una columna de luz cálida y la
#            llama del farol suben sobre él.
#   aliento: una hoja por cada turno de Aliento sube en espiral alrededor del aliado.
#   hoja:    una hoja sola que sube (el Aliento cura al empezar un turno).

const SOMBRA := Color(0.04, 0.07, 0.13)

var tipo := "alba"
var color := Color.WHITE
var dur := 1.5
var alto := 230.0                 # alto del luchador (px de la escena): dónde va el anillo y hasta dónde sube la luz
var desde := Vector2.ZERO         # lumbre: de dónde sale la brasa (relativo a este nodo)
var viaje := 0.45                 # lumbre: lo que tarda la brasa en llegar (combate.gd aplica el arte entonces)
var hojas := 3                    # aliento: una por turno
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t >= dur:
		queue_free()


func _draw() -> void:
	match tipo:
		"alba":
			_anillo(1.0)
		"ocaso":
			_anillo(-1.0)
		"lumbre":
			_lumbre()
		"aliento":
			_aliento()
		"hoja":
			_hoja_sola()
		"escarcha":
			_escarcha()
		"escarcha_golpe":
			_escarcha_golpe()
		"escarcha_rota":
			_escarcha_rota()
		"guardia":
			_guardia()
		"brasa":
			_brasa()


# ---------------------------------------------------------------- anillo del Alba (y del Ocaso, al revés)
func _anillo(sentido: float) -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var aparece := smoothstep(0.0, 0.14, k)
	var cierra := smoothstep(0.78, 1.0, k)
	var alfa := aparece * (1.0 - cierra * 0.85)
	var y := -alto * 0.18
	if sentido < 0.0:                               # el Ocaso baja de encima de la cabeza hasta los pies
		y = lerpf(-alto * 0.62, alto * 0.38, smoothstep(0.08, 0.92, k))
	else:                                           # el Alba sube un poco al cerrarse
		y -= cierra * alto * 0.25
	var r := 108.0 * lerpf(0.65, 1.0, aparece) * lerpf(1.0, 0.35 if sentido > 0.0 else 1.15, cierra)
	var tiempos := 4
	var ritmo := clampf((k - 0.16) / 0.6, 0.0, 0.999) * tiempos      # 0..4: en qué tiempo va
	var tiempo := int(ritmo)
	var golpe := 1.0 - fmod(ritmo, 1.0)                               # 1 al empezar cada tiempo, baja hasta el siguiente
	if k < 0.16 or k > 0.78:
		golpe = 0.0
	r *= 1.0 + 0.07 * golpe * golpe                  # late en cada tiempo
	var giro := sentido * k * TAU * 0.9
	var c := Vector2(0, y)
	var esc := Vector2(1.0, 0.34)                   # tumbado: se ve como un aro alrededor del cuerpo
	draw_set_transform(c, 0.0, esc)
	draw_arc(Vector2.ZERO, r, 0, TAU, 72, Color(SOMBRA, 0.5 * alfa), 13.0)     # contorno oscuro: se lee en fondos claros
	draw_arc(Vector2.ZERO, r, PI, TAU, 40, Color(color, 0.6 * alfa), 5.0)       # mitad de atrás, más tenue
	draw_arc(Vector2.ZERO, r, 0, PI, 40, Color(color, alfa), 7.0)               # mitad de delante
	draw_arc(Vector2.ZERO, r * 0.8, 0, TAU, 60, Color(color, 0.45 * alfa), 3.0)
	# la aguja: un arco brillante que da la vuelta en cada tiempo
	var aguja := sentido * ritmo * TAU + giro
	draw_arc(Vector2.ZERO, r, aguja - 0.55, aguja, 12, Color(Color.WHITE.lerp(color, 0.25), alfa), 10.0)
	# las cuatro marcas (rayos del alba): la del tiempo en curso se enciende; en el Ocaso se van apagando
	for i in tiempos:
		var a := giro + TAU * i / tiempos
		var d := Vector2(cos(a), sin(a))
		var luz := 0.55
		if sentido > 0.0:
			luz = 1.0 if i == tiempo % tiempos and golpe > 0.0 else (0.8 if i < tiempo else 0.45)
		else:
			luz = 0.15 if i < tiempo else (1.0 if i == tiempo and golpe > 0.0 else 0.7)
		var largo := 28.0 + 14.0 * (golpe if i == tiempo % tiempos else 0.0)
		draw_line(d * (r - 6.0), d * (r + largo), Color(SOMBRA, 0.45 * alfa), 12.0)
		draw_line(d * (r - 6.0), d * (r + largo), Color(color.lerp(Color.WHITE, 0.35 * luz), alfa * luz), 7.0)
		draw_circle(d * (r + largo + 7.0), 8.5, Color(SOMBRA, 0.4 * alfa))
		draw_circle(d * (r + largo + 7.0), 7.0, Color(color.lerp(Color.WHITE, 0.5), alfa * luz))
	draw_set_transform(Vector2.ZERO)
	if sentido > 0.0 and cierra > 0.0:              # al cerrarse, un destello que sube: el turno llega antes
		var yy := y - cierra * 60.0
		draw_circle(Vector2(0, yy), 26.0 * (1.0 - cierra) + 4.0, Color(Color.WHITE.lerp(color, 0.4), (1.0 - cierra) * 0.9))


# ---------------------------------------------------------------- Lumbre de Retorno
func _lumbre() -> void:
	var llegada := Vector2(0, -alto * 0.22)
	if t < viaje:                                   # la brasa vuela de Lya al caído, en arco, dejando una estela
		var k := t / viaje
		var arriba := (desde + llegada) * 0.5 + Vector2(0, -alto * 0.75)
		var puntos := PackedVector2Array()
		var colores := PackedColorArray()
		for i in 10:
			var kk := clampf(k - i * 0.035, 0.0, 1.0)
			puntos.append(_bezier(desde, arriba, llegada, kk))
			colores.append(Color(color, 0.85 * (1.0 - i / 10.0)))
		draw_polyline_colors(puntos, colores, 6.0)
		_llama(_bezier(desde, arriba, llegada, k), 1.25, 1.0)
		return
	var k2 := clampf((t - viaje) / maxf(0.01, dur - viaje), 0.0, 1.0)
	var alfa := smoothstep(0.0, 0.12, k2) * (1.0 - smoothstep(0.55, 1.0, k2))
	# columna de luz cálida desde el suelo
	var suelo := alto * 0.45
	var techo := -alto * (0.9 + 0.35 * k2)
	var ancho := lerpf(60.0, 104.0, smoothstep(0.0, 0.3, k2))
	var abajo := Color(color, 0.65 * alfa)
	var arriba2 := Color(color, 0.0)
	draw_polygon(PackedVector2Array([Vector2(-ancho * 0.5, suelo), Vector2(ancho * 0.5, suelo), Vector2(ancho * 0.3, techo),
		Vector2(-ancho * 0.3, techo)]), PackedColorArray([abajo, abajo, arriba2, arriba2]))
	draw_polygon(PackedVector2Array([Vector2(-ancho * 0.16, suelo), Vector2(ancho * 0.16, suelo), Vector2(ancho * 0.08, techo),
		Vector2(-ancho * 0.08, techo)]), PackedColorArray([Color(Color.WHITE, 0.5 * alfa), Color(Color.WHITE, 0.5 * alfa),
		Color(Color.WHITE, 0.0), Color(Color.WHITE, 0.0)]))
	# dos aros que se abren en el suelo
	draw_set_transform(Vector2(0, suelo), 0.0, Vector2(1.0, 0.32))
	for i in 2:
		var kk := clampf(k2 * 1.3 - i * 0.25, 0.0, 1.0)
		if kk > 0.0:
			draw_arc(Vector2.ZERO, lerpf(30.0, 150.0, kk), 0, TAU, 56, Color(color, (1.0 - kk) * 0.9), 6.0 * (1.0 - kk) + 1.0)
	draw_set_transform(Vector2.ZERO)
	# la llama del farol sobre la cabeza: quién vuelve
	var y_llama := -alto * 0.98 - 50.0 * k2           # por encima de «¡Kael vuelve!» y de sus PV
	_farol(Vector2(0, y_llama), 3.4, alfa)


static func _bezier(a: Vector2, b: Vector2, c: Vector2, k: float) -> Vector2:
	return a.lerp(b, k).lerp(b.lerp(c, k), k)


# Una llama (la de la brasa y la del farol): borde naranja y corazón claro.
func _llama(p: Vector2, esc: float, alfa: float) -> void:
	var borde := PackedVector2Array([p + Vector2(0, -16) * esc, p + Vector2(8, -2) * esc, p + Vector2(7, 8) * esc,
		p + Vector2(0, 13) * esc, p + Vector2(-7, 8) * esc, p + Vector2(-8, -2) * esc])
	draw_colored_polygon(borde, Color(1.0, 0.55, 0.2, 0.9 * alfa))
	var dentro := PackedVector2Array()
	for q in borde:
		dentro.append(p + (q - p) * 0.55 + Vector2(0, 3) * esc)
	draw_colored_polygon(dentro, Color(color.lerp(Color.WHITE, 0.5), alfa))


# El farol de la Lumbre (como su icono de artes.gd, en grande): marco, asa y la llama dentro.
func _farol(p: Vector2, esc: float, alfa: float) -> void:
	if alfa <= 0.01:
		return
	var marco := Rect2(p + Vector2(-9, -11) * esc, Vector2(18, 23) * esc)
	draw_rect(marco, Color(color, 0.18 * alfa))                       # el cristal, encendido
	draw_rect(marco.grow(1.5), Color(SOMBRA, 0.5 * alfa), false, 6.0)
	draw_rect(marco, Color(color, alfa), false, 3.5)
	draw_line(p + Vector2(-5, -15) * esc, p + Vector2(5, -15) * esc, Color(color, alfa), 3.5)
	draw_line(p + Vector2(0, -15) * esc, p + Vector2(0, -11) * esc, Color(color, alfa), 3.5)
	_llama(p + Vector2(0, 2) * esc, esc * 0.45, alfa)


# ---------------------------------------------------------------- Segundo Aliento (y la hoja de cada turno)
func _aliento() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var alfa := smoothstep(0.0, 0.12, k) * (1.0 - smoothstep(0.75, 1.0, k))
	# un soplo verde en el suelo
	draw_set_transform(Vector2(0, alto * 0.42), 0.0, Vector2(1.0, 0.3))
	draw_arc(Vector2.ZERO, lerpf(40.0, 120.0, smoothstep(0.0, 0.6, k)), 0, TAU, 56, Color(color, 0.7 * alfa), 4.0)
	draw_set_transform(Vector2.ZERO)
	for i in maxi(1, hojas):                        # una hoja por turno: lo que dura se cuenta
		var fase := float(i) / maxi(1, hojas)
		var a := k * TAU * 1.4 + fase * TAU
		var subida := clampf(k * 1.15 - fase * 0.15, 0.0, 1.0)
		var p := Vector2(cos(a) * 78.0, alto * 0.3 - subida * alto * 0.95 + sin(a) * 20.0)
		var delante := sin(a) > 0.0                 # las de detrás, más tenues
		_hoja(p, a * 0.6 + 0.6, 1.5, alfa * (1.0 if delante else 0.55))


func _hoja_sola() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var alfa := smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.6, 1.0, k))
	_hoja(Vector2(sin(k * 6.0) * 18.0, -alto * 0.2 - k * 90.0), sin(k * 5.0) * 0.6, 1.3, alfa)


# Una hoja como la del icono del Aliento (artes.gd), con su nervio.
func _hoja(p: Vector2, ang: float, esc: float, alfa: float) -> void:
	if alfa <= 0.01:
		return
	var r := 12.0 * esc
	var pts := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		pts.append(Vector2(sin(u * PI) * r * 0.6, lerpf(-r, r, u)))
	for i in range(11, 0, -1):
		var u := float(i) / 12.0
		pts.append(Vector2(-sin(u * PI) * r * 0.6, lerpf(-r, r, u)))
	var giradas := PackedVector2Array()
	var sombra := PackedVector2Array()
	for q in pts:
		giradas.append(p + q.rotated(ang))
		sombra.append(p + (q * 1.18).rotated(ang))
	draw_colored_polygon(sombra, Color(SOMBRA, 0.3 * alfa))
	draw_colored_polygon(giradas, Color(color, alfa))
	draw_line(p + Vector2(0, -r * 0.8).rotated(ang), p + Vector2(0, r).rotated(ang), Color(0.1, 0.2, 0.05, 0.8 * alfa), 1.5)


# ---------------------------------------------------------------- Escarcha (M3): la coraza
# El contorno de la coraza: un cristal hexagonal alargado alrededor del cuerpo (en el sitio del luchador).
func _cristal(esc: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0 - PI / 2.0
		pts.append(Vector2(cos(a) * 78.0, sin(a) * alto * 0.56) * esc + Vector2(0, -alto * 0.08))
	return pts


func _contorno(pts: PackedVector2Array, col: Color, ancho: float) -> void:
	var cerrado := pts.duplicate()
	cerrado.append(pts[0])
	draw_polyline(cerrado, Color(SOMBRA, 0.45 * col.a), ancho + 5.0)
	draw_polyline(cerrado, col, ancho)


# Se forma: las caras de hielo crecen desde el suelo, brillan y se quedan tenues hasta desvanecerse.
func _escarcha() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var crece := smoothstep(0.0, 0.35, k)
	var alfa := 1.0 - smoothstep(0.7, 1.0, k)
	var pts := _cristal(1.0)
	var suelo := alto * 0.48
	var hechos := PackedVector2Array()                # aplastado hacia el suelo mientras crece
	for p in pts:
		hechos.append(Vector2(p.x, lerpf(suelo, p.y, crece)))
	draw_colored_polygon(hechos, Color(color, 0.22 * alfa))
	_contorno(hechos, Color(color, alfa), 4.0)
	var centro := Vector2(0, lerpf(suelo, -alto * 0.08, crece))
	for i in 6:                                     # facetas: del centro a cada vértice
		draw_line(centro, hechos[i], Color(color.lerp(Color.WHITE, 0.4), 0.5 * alfa), 2.0)
	if crece >= 1.0:                                # un destello recorre el cristal
		var b := clampf((k - 0.35) / 0.3, 0.0, 1.0)
		var y := lerpf(suelo, -alto * 0.64, b)
		draw_line(Vector2(-60, y), Vector2(60, y - 20), Color(Color.WHITE, 0.7 * (1.0 - b) * alfa), 4.0)


# Absorbe un golpe: el cristal aparece un instante y tiembla.
func _escarcha_golpe() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var pts := _cristal(1.0 + 0.06 * (1.0 - k))
	draw_colored_polygon(pts, Color(color, 0.25 * (1.0 - k)))
	_contorno(pts, Color(color.lerp(Color.WHITE, 0.4), 1.0 - k), 4.0)


# Se rompe: el cristal salta en esquirlas que vuelan hacia fuera y caen (una por cara, sin azar).
func _escarcha_rota() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var alfa := 1.0 - smoothstep(0.5, 1.0, k)
	var pts := _cristal(1.0)
	var centro := Vector2(0, -alto * 0.08)
	if k < 0.15:
		_contorno(pts, Color(Color.WHITE, 1.0 - k / 0.15), 6.0)
	for i in 6:
		var a := pts[i]
		var b := pts[(i + 1) % 6]
		var medio := (a + b) / 3.0 + centro / 3.0
		var sale := (medio - centro).normalized()
		var mov := sale * (40.0 + 160.0 * k) + Vector2(0, 260.0 * k * k)
		var giro := (i % 2 * 2 - 1) * k * 3.0
		var esq := PackedVector2Array()
		for q in [a, b, centro.lerp(medio, 0.4)]:
			esq.append(medio + (q - medio).rotated(giro) * 0.55 + mov)
		draw_colored_polygon(esq, Color(color, 0.75 * alfa))
		var cerrada := esq.duplicate()
		cerrada.append(esq[0])
		draw_polyline(cerrada, Color(Color.WHITE, alfa), 2.0)


# ---------------------------------------------------------------- la Guardia de Garon (T-100)
# Un escudo sobre el aliado cubierto y una línea que lo une con Garon (desde).
func _guardia() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var alfa := smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.6, 1.0, k))
	var p := Vector2(0, -alto * 0.62 - 20.0 * k)
	var lleva := smoothstep(0.0, 0.3, k)             # la línea sale de Garon y llega al escudo
	draw_line(desde, desde.lerp(p, lleva), Color(SOMBRA, 0.35 * alfa), 8.0)
	draw_line(desde, desde.lerp(p, lleva), Color(color, 0.8 * alfa), 4.0)
	var e := 2.6
	var pts := PackedVector2Array([p + Vector2(-14, -16) * e, p + Vector2(14, -16) * e, p + Vector2(13, 0) * e,
		p + Vector2(0, 18) * e, p + Vector2(-13, 0) * e])
	draw_colored_polygon(pts, Color(color, 0.35 * alfa))
	_contorno(pts, Color(color, alfa), 4.0)
	draw_line(p + Vector2(0, -11) * e, p + Vector2(0, 13) * e, Color(0.62, 0.17, 0.17, alfa), 5.0)


# ---------------------------------------------------------------- Última Brasa (M4)
# Una llama grande baja sobre el pecho del aliado y se queda latiendo dentro de un aro de ascuas (la Brasa espera).
func _brasa() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var alfa := smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.7, 1.0, k))
	var y := lerpf(-alto * 0.95, -alto * 0.2, smoothstep(0.0, 0.45, k))
	var late := 1.0 + 0.12 * sin(k * TAU * 3.0)
	draw_set_transform(Vector2(0, alto * 0.45), 0.0, Vector2(1.0, 0.32))
	draw_arc(Vector2.ZERO, 95.0, 0, TAU, 56, Color(SOMBRA, 0.35 * alfa), 10.0)
	draw_arc(Vector2.ZERO, 95.0, 0, TAU, 56, Color(color, 0.85 * alfa), 5.0)
	for i in 8:                                       # ascuas en el aro
		var a := TAU * i / 8.0 + k * 2.0
		draw_circle(Vector2(cos(a), sin(a)) * 95.0, 7.0, Color(color.lerp(Color.WHITE, 0.4), alfa))
	draw_set_transform(Vector2.ZERO)
	_llama(Vector2(0, y), 2.6 * late, alfa)
