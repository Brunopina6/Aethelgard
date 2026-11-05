extends SceneTree
# Prepara para el juego las pasadas renderizadas de la isla (render_isla.gd):
#   isla_paso.png   máscara de paso a 1/4 (blanco = se anda), limpia: escalones cerrados, sin motas
#   isla_suelo.png  profundidad del suelo donde se anda, a 1/4 (para saber qué tapa a Kael)
#   isla_tapa.png   profundidad de lo que se alza (casas, árboles), a 1/2 (0 = nada)
# Uso: --script preparar_isla.gd -- <carpeta de las pasadas> <carpeta de salida>

const CIERRE := 2          # píxeles (a 1/4) para cerrar huecos finos: los escalones de las escaleras
const MOTA_MIN := 120      # zonas de paso más pequeñas que esto (píxeles a 1/4) se quitan
const MARGEN := 1          # se encoge el borde para no pisar el filo


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var ent: String = a[0]
	var sal: String = a[1]
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ent + "/datos.json"))
	var nx := int(datos["trozos_x"])
	var ny := int(datos["trozos_y"])
	var w := int(datos["ancho"])
	var h := int(datos["alto"])
	var masc := _unir(ent, "mascara", nx, ny, w, h)
	var prof := _unir(ent, "profundidad", nx, ny, w, h)
	# --- máscara a 1/4
	var w4 := w / 4
	var h4 := h / 4
	var paso := PackedByteArray()
	paso.resize(w4 * h4)
	var suelo := PackedByteArray()
	suelo.resize(w4 * h4)
	for y in h4:
		for x in w4:
			var blancos := 0
			var zs := 0.0
			var nz := 0
			for oy in 4:
				for ox in 4:
					var c := masc.get_pixel(x * 4 + ox, y * 4 + oy)
					if c.a > 0.5 and c.r > 0.5:
						blancos += 1
					var p := prof.get_pixel(x * 4 + ox, y * 4 + oy)
					if p.a > 0.5 and p.g > 0.002:
						zs += p.g
						nz += 1
			paso[y * w4 + x] = 1 if blancos >= 6 else 0
			suelo[y * w4 + x] = int(round(zs / nz * 255.0)) if nz > 0 else 0
	paso = _erosionar(_dilatar(paso, w4, h4, CIERRE), w4, h4, CIERRE)     # cierre: une los escalones
	paso = _quitar_motas(paso, w4, h4, MOTA_MIN)
	paso = _erosionar(paso, w4, h4, MARGEN)
	suelo = _rellenar(suelo, paso, w4, h4)
	var img_paso := Image.create(w4, h4, false, Image.FORMAT_L8)
	var img_suelo := Image.create(w4, h4, false, Image.FORMAT_L8)
	var cuenta := 0
	for i in paso.size():
		img_paso.set_pixel(i % w4, i / w4, Color.WHITE if paso[i] else Color.BLACK)
		img_suelo.set_pixel(i % w4, i / w4, Color(suelo[i] / 255.0, 0, 0))
		cuenta += paso[i]
	img_paso.save_png(sal + "/isla_paso.png")
	img_suelo.save_png(sal + "/isla_suelo.png")
	# --- lo que tapa, a 1/2
	var tapa := Image.create(w / 2, h / 2, false, Image.FORMAT_L8)
	for y in h / 2:
		for x in w / 2:
			var m := 0.0
			for oy in 2:
				for ox in 2:
					var p := prof.get_pixel(x * 2 + ox, y * 2 + oy)
					if p.a > 0.5:
						m = maxf(m, p.r)
			tapa.set_pixel(x, y, Color(m, 0, 0))
	tapa.save_png(sal + "/isla_tapa.png")
	print("paso: %d píxeles de %d (%.0f %%)" % [cuenta, w4 * h4, 100.0 * cuenta / (w4 * h4)])
	quit()


func _unir(carpeta: String, pasada: String, nx: int, ny: int, w: int, h: int) -> Image:
	var todo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for j in ny:
		for i in nx:
			var t := Image.load_from_file("%s/%s_%d_%d.png" % [carpeta, pasada, i, j])
			t.convert(Image.FORMAT_RGBA8)
			todo.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(i * w / nx, j * h / ny))
	return todo


func _dilatar(m: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	var o := m.duplicate()
	for y in h:
		for x in w:
			if m[y * w + x]:
				continue
			var hay := false
			for oy in range(-r, r + 1):
				for ox in range(-r, r + 1):
					var xx := x + ox
					var yy := y + oy
					if xx >= 0 and yy >= 0 and xx < w and yy < h and m[yy * w + xx]:
						hay = true
						break
				if hay:
					break
			o[y * w + x] = 1 if hay else 0
	return o


func _erosionar(m: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	var o := m.duplicate()
	for y in h:
		for x in w:
			if not m[y * w + x]:
				continue
			var falta := false
			for oy in range(-r, r + 1):
				for ox in range(-r, r + 1):
					var xx := x + ox
					var yy := y + oy
					if xx < 0 or yy < 0 or xx >= w or yy >= h or not m[yy * w + xx]:
						falta = true
						break
				if falta:
					break
			o[y * w + x] = 0 if falta else 1
	return o


func _quitar_motas(m: PackedByteArray, w: int, h: int, minimo: int) -> PackedByteArray:
	var o := m.duplicate()
	var visto := PackedByteArray()
	visto.resize(w * h)
	for i in m.size():
		if not m[i] or visto[i]:
			continue
		var cola := [i]
		var zona := []
		visto[i] = 1
		while not cola.is_empty():
			var k: int = cola.pop_back()
			zona.append(k)
			for d in [-1, 1, -w, w]:
				var n: int = k + d
				if n < 0 or n >= w * h or (absi(d) == 1 and n / w != k / w):
					continue
				if m[n] and not visto[n]:
					visto[n] = 1
					cola.append(n)
		if zona.size() < minimo:
			for k in zona:
				o[k] = 0
	return o


# El suelo cerrado entre escalones no tenía profundidad: se copia la de al lado.
func _rellenar(z: PackedByteArray, m: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var o := z.duplicate()
	for vuelta in 6:
		var cambio := false
		for y in h:
			for x in w:
				var i := y * w + x
				if not m[i] or o[i] > 0:
					continue
				for d in [-1, 1, -w, w]:
					var n: int = i + d
					if n >= 0 and n < w * h and o[n] > 0:
						o[i] = o[n]
						cambio = true
						break
		if not cambio:
			break
	return o
