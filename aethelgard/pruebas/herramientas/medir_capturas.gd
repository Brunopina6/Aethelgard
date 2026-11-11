extends SceneTree
# Mide capturas ya hechas (del Redmi o del PC) con las mismas cuentas que medir_luz_perfiles.gd: luminancia media,
# cuartil iluminado, cuartil en sombra, punto negro (percentil 5) y saturación media (HSV), sin la franja de arriba
# (interfaz) y sin las bandas negras laterales de las capturas del teléfono (columnas casi negras en toda su altura).
# Sirve para comparar el «lavado» del perfil bajo del teléfono con el del PC (12/11, gráficos). No abre ninguna escena.
# Uso: Godot --headless --path aethelgard --script res://pruebas/herramientas/medir_capturas.gd -- <png> [<png> ...]


func _initialize() -> void:
	print("captura;media;luz;sombra;negro;saturacion")
	for ruta in OS.get_cmdline_user_args():
		var img := Image.load_from_file(ruta)
		if img == null or img.is_empty():
			print("%s;no se pudo leer" % ruta)
			continue
		var m := _medir(img)
		print("%s;%.4f;%.4f;%.4f;%.4f;%.4f" % [ruta.get_file(), m[0], m[1], m[2], m[3], m[4]])
	quit(0)


func _medir(img: Image) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var x0 := 0
	var x1 := w
	while x0 < w / 3 and _columna_negra(img, x0):
		x0 += 1
	while x1 > w * 2 / 3 and _columna_negra(img, x1 - 1):
		x1 -= 1
	var v: Array = []
	var sat := 0.0
	for y in range(int(h * 0.18), h, 4):
		for x in range(x0, x1, 4):
			var c := img.get_pixel(x, y)
			v.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
			sat += c.s
	v.sort()
	var n := v.size()
	var suma := 0.0
	for k in v:
		suma += k
	var alto := 0.0
	for k in range(int(n * 0.75), n):
		alto += v[k]
	var bajo := 0.0
	for k in range(0, int(n * 0.25)):
		bajo += v[k]
	return [suma / n, alto / (n - int(n * 0.75)), bajo / int(n * 0.25), v[int(n * 0.05)], sat / n]


func _columna_negra(img: Image, x: int) -> bool:
	for y in range(0, img.get_height(), 24):
		if img.get_pixel(x, y).v > 0.03:
			return false
	return true
