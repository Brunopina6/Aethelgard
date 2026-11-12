extends RefCounted
# Pincel del Firmamento (V12, 12/11): junta en UNA lista de triángulos (colores por vértice) todo lo que se dibuja en
# una capa, y la entrega al servidor de una vez (RenderingServer.canvas_item_add_triangle_array): una llamada de
# dibujo en lugar de cientos. Medido en el PC el 12/11: con draw_line/draw_arc/draw_colored_polygon sueltos, el tablero
# hacía 520-650 llamadas por fotograma (cada polígono y cada línea suavizada es una llamada en Compatibility).
#
# Imita los nombres de CanvasItem (draw_line, draw_polyline, draw_arc, draw_circle, draw_colored_polygon, draw_rect)
# para que los mismos dibujos (glifos, símbolos, orbe) valgan para el pincel y para un Control del panel.
# Suavizado: cada línea lleva dos franjas de «pluma» que se desvanecen (como el suavizado de Godot). «pluma» se mide
# en unidades del tablero: 1 px de pantalla = 1 / zoom.

var pts := PackedVector2Array()
var cols := PackedColorArray()
var pluma := 1.0

static var _indices := PackedInt32Array()


func limpiar() -> void:
	pts.clear()
	cols.clear()


func _tri(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
	pts.append(a)
	pts.append(b)
	pts.append(c)
	cols.append(ca)
	cols.append(cb)
	cols.append(cc)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	_tri(a, b, c, ca, cb, cc)
	_tri(a, c, d, ca, cc, cd)


func draw_line(a: Vector2, b: Vector2, col: Color, ancho := 1.0, suave := false) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.0001:
		return
	var n := Vector2(-d.y, d.x) / l
	var w := maxf(ancho, 0.6) * 0.5
	var nw := n * w
	_quad(a + nw, b + nw, b - nw, a - nw, col, col, col, col)
	if suave:
		var t := Color(col, 0.0)
		var np := n * (w + pluma)
		_quad(a + np, b + np, b + nw, a + nw, t, t, col, col)
		_quad(a - nw, b - nw, b - np, a - np, col, col, t, t)


func draw_polyline(p: PackedVector2Array, col: Color, ancho := 1.0, suave := false) -> void:
	for i in p.size() - 1:
		draw_line(p[i], p[i + 1], col, ancho, suave)


# Como CanvasItem.draw_arc: ángulos estándar (0 = +x, crecen hacia +y).
func draw_arc(c: Vector2, r: float, a0: float, a1: float, n: int, col: Color, ancho := 1.0, suave := false) -> void:
	var prev := c + Vector2(cos(a0), sin(a0)) * r
	for i in range(1, n + 1):
		var a := lerpf(a0, a1, float(i) / n)
		var p := c + Vector2(cos(a), sin(a)) * r
		draw_line(prev, p, col, ancho, suave)
		prev = p


# Abanico desde el centroide: vale para los convexos y para las estrellas (todas se ven enteras desde su centro).
func draw_colored_polygon(p: PackedVector2Array, col: Color) -> void:
	if p.size() < 3:
		return
	var c := Vector2.ZERO
	for v in p:
		c += v
	c /= p.size()
	for i in p.size():
		_tri(c, p[i], p[(i + 1) % p.size()], col, col, col)
	var t := Color(col, 0.0)                            # borde suavizado
	for i in p.size():
		var a := p[i]
		var b := p[(i + 1) % p.size()]
		var na := (a - c).normalized() * pluma
		var nb := (b - c).normalized() * pluma
		_quad(a, b, b + nb, a + na, col, col, t, t)


func draw_circle(c: Vector2, r: float, col: Color) -> void:
	var lados := clampi(int(r * 0.8), 8, 32)
	var p := PackedVector2Array()
	for i in lados:
		var a := i * TAU / lados
		p.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(p, col)


func draw_rect(r: Rect2, col: Color, lleno := true, ancho := 1.0) -> void:
	var a := r.position
	var b := r.position + Vector2(r.size.x, 0)
	var c := r.end
	var d := r.position + Vector2(0, r.size.y)
	if lleno:
		_quad(a, b, c, d, col, col, col, col)
	else:
		for s in [[a, b], [b, c], [c, d], [d, a]]:
			draw_line(s[0], s[1], col, ancho, false)


# Entrega todo a ese CanvasItem (llamar dentro de su _draw) y vacía el pincel.
func emitir(ci: CanvasItem) -> void:
	var n := pts.size()
	if n == 0:
		return
	if _indices.size() < n:
		var viejo := _indices.size()
		_indices.resize(maxi(n, viejo * 2))
		for i in range(viejo, _indices.size()):
			_indices[i] = i
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _indices.slice(0, n), pts, cols)
	limpiar()
