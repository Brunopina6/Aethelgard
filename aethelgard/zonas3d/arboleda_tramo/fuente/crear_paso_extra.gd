extends SceneTree
# Arboleda Mítica, tramo «La escalera de la Hospedería» (EXPERIMENTAL): genera tramo/paso_extra.png, la máscara de paso
# EXTRA que une lo alto de la escalera de piedra (a la derecha del cristal) con la escalera de madera de la casa de la
# cúpula verde. isla_paso.png NO se toca: arboleda_tramo.gd consulta las dos (una u otra).
#   rojo  = se anda (además de lo de isla_paso)
#   verde = profundidad del suelo en esas celdas (isla_suelo tiene 0 donde la máscara original estaba cerrada: aquí se
#           interpola por filas entre los bordes con suelo, para que _poner_z no se quede con un valor viejo)
# Mismo tamaño que isla_paso (1/4 de la isla: 768 × 837). Determinista: sin azar.
# Uso: godot --headless --path aethelgard --script res://zonas3d/arboleda_tramo/fuente/crear_paso_extra.gd

const SALIDA := "res://zonas3d/arboleda_tramo/tramo/paso_extra.png"
# Celdas (a 1/4) que se abren. Comprobado en la rejilla (16/11): en las filas 531-539 la parte alcanzable llega hasta
# x 562 y la terraza empieza en x 572-578; entre medias, el pie del pilar de la escalera de madera (suelo con valor,
# máscara cerrada por preparar_isla). Isla: x 2216-2316, y 2096-2160. (2.ª pasada: más alto hacia arriba, filas 524-530,
# para que con teclas en diagonal ↗ desde la escalera de piedra no se tope con la esquina: prueba_arboleda_tramo, C.)
const PUENTES := [Rect2i(554, 524, 25, 16)]


func _initialize() -> void:
	var paso: Image = (load("res://isla/isla_paso.png") as Texture2D).get_image()
	var suelo: Image = (load("res://isla/isla_suelo.png") as Texture2D).get_image()
	var w := paso.get_width()
	var h := paso.get_height()
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var abiertas := 0
	for r in PUENTES:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var z := suelo.get_pixel(x, y).r
				if z <= 0.0:
					z = _interpolar(suelo, x, y)
				img.set_pixel(x, y, Color(1.0, z, 0.0))
				abiertas += 1
	img.save_png(ProjectSettings.globalize_path(SALIDA))
	print("paso_extra: %d celdas abiertas en %s" % [abiertas, SALIDA])
	quit()


# El suelo más cercano con valor a izquierda y derecha de la fila, mezclado por distancia.
func _interpolar(suelo: Image, x: int, y: int) -> float:
	var zi := 0.0
	var di := 0
	var zd := 0.0
	var dd := 0
	for k in range(1, 40):
		if zi == 0.0 and x - k >= 0 and suelo.get_pixel(x - k, y).r > 0.0:
			zi = suelo.get_pixel(x - k, y).r
			di = k
		if zd == 0.0 and x + k < suelo.get_width() and suelo.get_pixel(x + k, y).r > 0.0:
			zd = suelo.get_pixel(x + k, y).r
			dd = k
	if zi > 0.0 and zd > 0.0:
		return lerpf(zi, zd, float(di) / float(di + dd))
	return maxf(zi, zd)
