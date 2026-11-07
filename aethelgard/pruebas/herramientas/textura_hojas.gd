extends SceneTree
# Atlas de matas de hojas PINTADAS (estilo de fantasía luminosa; referencias del autor: copas de hojitas con
# formas claras y degradado de verde sombra a amarillo luz). Sustituye a las matas recortadas de un render
# fotográfico, que se veían como ruido. 4 celdas de 512 x 512 (atlas 1024):
#   0 pradera (frondosa)   1 abedul (ligera, hojas pequeñas)   2 mágica (flores lila y rosa)   3 interior (sombra)
# Cada hoja es una forma de hoja con punta, orientada hacia fuera de la mata; las de atrás más oscuras y las de
# arriba y delante más claras; borde algo más oscuro para que se lean. Alfa duro (0/1) para recorte en móvil.
# Uso: Godot --headless --path aethelgard --script res://pruebas/herramientas/textura_hojas.gd -- <salida.png>

const CELDA := 512
var img: Image
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var salida: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://modelos/hojas/matas.png"
	img = Image.create(CELDA * 2, CELDA * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	rng.seed = 2026
	# celda, hojas, largo, ancho, sombra (abajo/atrás), luz (arriba/delante), flores
	_mata(Vector2i(0, 0), 190, Vector2(54, 74), Vector2(20, 30), Color(0.16, 0.36, 0.1), Color(0.78, 0.9, 0.3), 0)
	_mata(Vector2i(1, 0), 210, Vector2(34, 48), Vector2(14, 20), Color(0.22, 0.46, 0.16), Color(0.82, 0.95, 0.46), 0)
	_mata(Vector2i(0, 1), 150, Vector2(44, 60), Vector2(18, 26), Color(0.2, 0.38, 0.18), Color(0.6, 0.82, 0.36), 110)
	_mata(Vector2i(1, 1), 190, Vector2(54, 74), Vector2(20, 30), Color(0.1, 0.25, 0.08), Color(0.45, 0.66, 0.2), 0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(salida.get_base_dir()))
	img.save_png(ProjectSettings.globalize_path(salida))
	print("atlas de matas -> ", salida)
	quit()


func _mata(celda: Vector2i, n: int, largo: Vector2, ancho: Vector2, sombra: Color, luz: Color, flores: int) -> void:
	var o := Vector2(celda) * CELDA
	var c := Vector2(CELDA, CELDA) * 0.5
	var hojas: Array = []
	for i in n:
		var r := sqrt(rng.randf()) * 200.0
		var a := rng.randf() * TAU
		var p := c + Vector2(cos(a), sin(a) * 0.92) * r
		# claridad: arriba y delante más luz; el borde exterior algo más claro (le da el sol)
		var t := clampf(0.55 - (p.y - c.y) / 420.0 + rng.randf_range(-0.18, 0.18) + (r / 200.0) * 0.12, 0.0, 1.0)
		hojas.append([t, p, a + rng.randf_range(-0.6, 0.6), rng.randf_range(largo.x, largo.y), rng.randf_range(ancho.x, ancho.y), false])
	for i in flores:
		var r := sqrt(rng.randf()) * 190.0
		var a := rng.randf() * TAU
		hojas.append([1.1 + rng.randf() * 0.1, c + Vector2(cos(a), sin(a) * 0.92) * r, rng.randf() * TAU, rng.randf_range(16, 24), 0.0, true])
	hojas.sort_custom(func(x, y): return x[0] < y[0])          # primero las oscuras (detrás)
	for h in hojas:
		if h[5]:
			_flor(o + h[1], h[3])
		else:
			var col: Color = sombra.lerp(luz, h[0])
			col = Color.from_hsv(col.h + rng.randf_range(-0.015, 0.015), col.s, col.v)
			_hoja(o + h[1], h[2], h[3], h[4], col)


# Hoja con punta: dentro si |v| < ancho·(1−u²)^0,7 (u a lo largo, de −1 a 1). Borde y nervio algo más oscuros.
func _hoja(p: Vector2, ang: float, largo: float, ancho: float, col: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nor := Vector2(-dir.y, dir.x)
	var caja := int(largo * 0.6) + 2
	for y in range(int(p.y) - caja, int(p.y) + caja):
		for x in range(int(p.x) - caja, int(p.x) + caja):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(x, y) - p
			var u := d.dot(dir) / (largo * 0.5)
			if absf(u) >= 1.0:
				continue
			var v := d.dot(nor)
			var lim := ancho * 0.5 * pow(1.0 - u * u, 0.7)
			if absf(v) >= lim:
				continue
			var borde := absf(v) / maxf(lim, 0.001)
			var k := 1.0 + 0.12 * (u * 0.5 + 0.5) - 0.22 * smoothstep(0.75, 1.0, borde) - 0.12 * (1.0 - smoothstep(0.0, 0.08, absf(v) / ancho))
			img.set_pixel(x, y, Color(col.r * k, col.g * k, col.b * k, 1.0))


# Flor de cinco pétalos lila/rosa con centro dorado (árbol mágico).
func _flor(p: Vector2, tam: float) -> void:
	var base := Color(0.86, 0.62, 0.96) if rng.randf() < 0.6 else Color(0.98, 0.7, 0.86)
	for k in 5:
		var a := k * TAU / 5.0 + rng.randf() * 0.3
		_hoja(p + Vector2(cos(a), sin(a)) * tam * 0.35, a, tam * 0.8, tam * 0.55, base)
	_hoja(p, 0.0, tam * 0.35, tam * 0.35, Color(1.0, 0.86, 0.45))
