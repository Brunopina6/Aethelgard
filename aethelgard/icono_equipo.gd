extends Control
# V12, accesorios (12/11; docs/v12/ACCESORIOS_V12.md): icono de un accesorio dibujado por código, sin texturas. La
# forma dice la categoría (anillo, colgante, talismán, brazalete, broche, reliquia, mágico o personal) y el color, la
# rareza (equipo_extra.gd RAREZAS). Lo usan la tienda y el menú Grupo; los objetos sin rareza (todo lo de antes de la
# V12) no llevan icono y se ven como siempre.
# Uso:  var ic = load("res://icono_equipo.gd").para("anillo_alba")   # null si el objeto no tiene rareza

const LADO := 22.0

var categoria := ""
var color := Color.WHITE


static func para(id: String, lado := LADO) -> Control:
	var X = load("res://equipo_extra.gd")
	var r: Dictionary = X.rareza(id)
	if r.is_empty():
		return null
	var ic = load("res://icono_equipo.gd").new()
	ic.categoria = str(X.objeto(id).get("categoria", ""))
	ic.color = r["color"]
	ic.custom_minimum_size = Vector2(lado, lado)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


func _draw() -> void:
	var l := minf(size.x, size.y)
	var c := size / 2.0
	var r := l * 0.42
	var oscuro := color.darkened(0.55)
	var grosor := maxf(2.0, l * 0.11)
	match categoria:
		"anillo":                                    # aro con una piedra arriba
			draw_arc(c + Vector2(0, l * 0.08), r * 0.72, 0.0, TAU, 28, color, grosor, true)
			draw_circle(c + Vector2(0, -r * 0.62), r * 0.32, color)
			draw_circle(c + Vector2(0, -r * 0.62), r * 0.14, oscuro)
		"colgante":                                  # cordón en V y una gota
			draw_polyline(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(0, r * 0.1), c + Vector2(r, -r)]), color,
				grosor * 0.6, true)
			draw_circle(c + Vector2(0, r * 0.5), r * 0.42, color)
			draw_circle(c + Vector2(0, r * 0.5), r * 0.18, oscuro)
		"talisman":                                  # hexágono con su marca
			var pts := PackedVector2Array()
			for i in 7:
				pts.append(c + Vector2.from_angle(TAU * i / 6.0 - PI / 2.0) * r)
			draw_colored_polygon(pts.slice(0, 6), oscuro)
			draw_polyline(pts, color, grosor * 0.8, true)
			draw_circle(c, r * 0.25, color)
		"brazalete":                                 # banda vista de lado
			var rect := Rect2(c - Vector2(r, r * 0.55), Vector2(r * 2.0, r * 1.1))
			draw_rect(rect, oscuro, true)
			draw_rect(rect, color, false, grosor * 0.8)
			draw_line(c + Vector2(-r * 0.35, -r * 0.55), c + Vector2(-r * 0.35, r * 0.55), color, grosor * 0.6)
			draw_line(c + Vector2(r * 0.35, -r * 0.55), c + Vector2(r * 0.35, r * 0.55), color, grosor * 0.6)
		"broche":                                    # escudo pequeño
			var esc := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8),
				c + Vector2(r * 0.8, 0.0), c + Vector2(0.0, r), c + Vector2(-r * 0.8, 0.0)])
			draw_colored_polygon(esc, color)
			draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.6), oscuro, grosor * 0.6)
		"reliquia", "personal":                      # estrella (reliquias y los de un solo héroe)
			var est := PackedVector2Array()
			for i in 10:
				est.append(c + Vector2.from_angle(TAU * i / 10.0 - PI / 2.0) * (r if i % 2 == 0 else r * 0.45))
			draw_colored_polygon(est, color)
		_:                                           # mágico (y cualquier otro): orbe con brillo
			draw_circle(c, r * 0.8, oscuro)
			draw_arc(c, r * 0.8, 0.0, TAU, 28, color, grosor * 0.8, true)
			draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.22, color)
