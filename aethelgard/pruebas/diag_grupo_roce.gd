extends "res://pruebas/recorrido_ciudad.gd"
# DIAGNÓSTICO (18/11, rama area-ciudad-recorrido-18), NO prueba de la lista: el MISMO recorrido que recorrido_ciudad.gd
# (mismos clics, mismo tiempo fijo; solo mira, no cambia nada) y, cuando alguien del grupo queda fuera de lo andable
# (con la tolerancia de 0,12 m del recorrido), vuelca los últimos fotogramas: dónde estaban Kael, Lya y Garon, cuántos
# puntos llevaba cada uno en su rastro y los primeros, si se apartaba, su velocidad, y cuánto se metía en lo no andable
# (la distancia a lo andable más cercano, en pasos de 1 cm). También la separación entre puntos seguidos del rastro.
# Con «marcas=T:F[@x;z],…» hace lo mismo en el fotograma F del tramo T (el tiempo del juego es fijo: los mismos
# fotogramas antes y después de un arreglo; el plano, centrado en (x, z) o en Lya), y en cada roce o marca guarda la captura (marca_T_F.jpg) y un PLANO visto desde arriba
# (plano_T_F.png: 5 × 5 m, 80 px/m; claro lo andable, oscuro lo que no; Kael azul, Lya verde, Garon rojo, los últimos
# 1,5 s, el último punto más grande). Con «antes=<carpeta>», si allí está la misma captura o plano, compone las dos lado
# a lado en antes_y_despues/ (izquierda antes, derecha después).
# Uso: como recorrido_ciudad.gd (con ventana); escribe <salida>/grupo_roce.txt.

const HIST := 45
const PX := 80.0
const LADO := 5.0

var _hist: Array = []                 # los últimos fotogramas
var _roce: PackedStringArray = []
var _en_roce := {}                    # nombre → true mientras sigue fuera (una entrada por roce)
var _sep_max := {}                    # nombre → separación máxima entre puntos seguidos de su rastro
var _sep_suma := {}
var _sep_n := {}
var _hondo_max := 0.0
var _n_roces := 0
var _marcas := {}
var _antes := ""
var _f_tramo := 0                     # fotogramas desde que empezó el tramo en curso


func _empezar_tramo() -> void:
	super._empezar_tramo()
	_f_tramo = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("marcas="):
			for x in a.trim_prefix("marcas=").split(","):
				var c := x.get_slice("@", 1)
				var centro = Vector3(float(c.get_slice(";", 0)), 0.0, float(c.get_slice(";", 1))) if x.contains("@") else null
				_marcas[x.get_slice("@", 0)] = centro
		elif a.begins_with("antes="):
			_antes = a.trim_prefix("antes=")
	super._initialize()


func _cada_cuadro() -> void:
	super._cada_cuadro()
	if v == null or not is_instance_valid(v) or v.get("grupo") == null or v.grupo == null or _t.is_empty():
		return
	_f_tramo += 1
	var f_actual := "%d_%d" % [tramos + 1, _f_tramo]
	var foto := {"f": f_actual, "k": v.kael.global_position, "m": []}
	for m in v.grupo.miembros:
		var cola: Array = m["cola"]
		for j in range(1, cola.size()):
			var d := _plana(cola[j], cola[j - 1])
			var nm: String = m["nombre"]
			_sep_max[nm] = maxf(float(_sep_max.get(nm, 0.0)), d)
			_sep_suma[nm] = float(_sep_suma.get(nm, 0.0)) + d
			_sep_n[nm] = int(_sep_n.get(nm, 0)) + 1
		foto["m"].append({"n": m["nombre"], "p": (m["nodo"] as Node3D).global_position, "cola": cola.size(),
			"c": cola.slice(0, 4), "apartar": m["apartar"], "v": m["v"]})
	_hist.append(foto)
	if _hist.size() > HIST:
		_hist.pop_front()
	if _marcas.has(f_actual.replace("_", ":")):
		var centro = _marcas[f_actual.replace("_", ":")]
		if centro == null:
			centro = foto["m"][0]["p"] if not foto["m"].is_empty() else foto["k"]
		_volcar("== MARCA %s (Kael %s)" % [f_actual.replace("_", ":"), _txt(foto["k"])], f_actual, centro)
	for e in foto["m"]:
		var g: Vector3 = e["p"]
		if _andable_grupo(g):
			_en_roce.erase(e["n"])
			continue
		if _en_roce.has(e["n"]):
			continue
		_en_roce[e["n"]] = true
		var h := _hondo(g)
		_hondo_max = maxf(_hondo_max, h)
		_n_roces += 1
		_volcar("== ROCE %s en %s, %.2f m dentro (%s) · marca %s" % [e["n"], _txt(g), h, _que_hay(g),
			f_actual.replace("_", ":")], f_actual, g)


func _volcar(cabeza: String, f_actual: String, centro: Vector3) -> void:
	_roce.append(cabeza)
	for fo in _hist.slice(maxi(0, _hist.size() - 12)):
		var l := "  %s Kael %s" % [fo["f"], _txt(fo["k"])]
		for mm in fo["m"]:
			l += " | %s %s v %.1f cola %d %s%s" % [mm["n"], _txt(mm["p"]), mm["v"], mm["cola"],
				str(mm["c"].map(func(q): return _txt(q))), " apartar" if mm["apartar"] != null else ""]
		_roce.append(l)
	if not con_fotos:
		return
	var img := root.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_jpg(salida.path_join("marca_%s.jpg" % f_actual), 0.9)
		_componer("marca_%s.jpg" % f_actual)
	_plano(centro).save_png(salida.path_join("plano_%s.png" % f_actual))
	_componer("plano_%s.png" % f_actual)


# El plano desde arriba alrededor de «centro»: lo andable claro, lo que no oscuro, y los últimos fotogramas.
func _plano(centro: Vector3) -> Image:
	var n := int(LADO * PX)
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var x0 := centro.x - LADO / 2.0
	var z0 := centro.z - LADO / 2.0
	for i in n:
		for j in n:
			var x := x0 + (i + 0.5) / PX
			var z := z0 + (j + 0.5) / PX
			var c := Color(0.86, 0.84, 0.78) if P.andable(x, z) else Color(0.25, 0.22, 0.2)
			if absf(fposmod(x, 1.0)) < 1.0 / PX or absf(fposmod(z, 1.0)) < 1.0 / PX:
				c = c.darkened(0.15)                    # cuadrícula de 1 m
			img.set_pixel(i, j, c)
	var colores := {"Kael": Color(0.15, 0.35, 0.95), "Lya": Color(0.1, 0.65, 0.2), "Garon": Color(0.85, 0.1, 0.1)}
	for k in _hist.size():
		var fo: Dictionary = _hist[k]
		var ultimo := k == _hist.size() - 1
		var pts := [["Kael", fo["k"]]]
		for mm in fo["m"]:
			pts.append([mm["n"], mm["p"]])
		for pt in pts:
			var q: Vector3 = pt[1]
			var px := int((q.x - x0) * PX)
			var pz := int((q.z - z0) * PX)
			var r := 4 if ultimo else 1
			for a in range(-r, r + 1):
				for b in range(-r, r + 1):
					if px + a >= 0 and px + a < n and pz + b >= 0 and pz + b < n:
						img.set_pixel(px + a, pz + b, colores.get(pt[0], Color.BLACK))
	img.resize(n, n, Image.INTERPOLATE_NEAREST)
	return img


func _componer(nombre: String) -> void:
	if _antes == "" or not FileAccess.file_exists(_antes.path_join(nombre)):
		return
	var a := Image.load_from_file(_antes.path_join(nombre))
	var d := Image.load_from_file(salida.path_join(nombre))
	if a == null or d == null:
		return
	a.convert(Image.FORMAT_RGB8)
	d.convert(Image.FORMAT_RGB8)
	if d.get_size() != a.get_size():
		d.resize(a.get_width(), a.get_height())
	var l := Image.create(a.get_width() * 2 + 8, a.get_height(), false, Image.FORMAT_RGB8)
	l.fill(Color.WHITE)
	l.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
	l.blit_rect(d, Rect2i(Vector2i.ZERO, d.get_size()), Vector2i(a.get_width() + 8, 0))
	DirAccess.make_dir_recursive_absolute(salida.path_join("antes_y_despues"))
	var ruta := salida.path_join("antes_y_despues").path_join(nombre.get_basename() + ".jpg")
	l.save_jpg(ruta, 0.9)


# Cuánto se mete en lo no andable: la distancia a lo andable más cercano (16 direcciones, pasos de 1 cm).
func _hondo(g: Vector3) -> float:
	for r in range(1, 100):
		for i in 16:
			var a := TAU * i / 16.0
			if P.andable(g.x + cos(a) * r * 0.01, g.z + sin(a) * r * 0.01):
				return r * 0.01
	return 1.0


func _terminar() -> void:
	var l: PackedStringArray = ["GRUPO_ROCE: %d roces (fuera de lo andable con 0,12 m de tolerancia), el más hondo %.2f m" % [
		_n_roces, _hondo_max]]
	for nm in _sep_max:
		l.append("rastro de %s: separación media %.3f m, máxima %.3f m entre puntos seguidos" % [nm,
			float(_sep_suma[nm]) / maxi(1, int(_sep_n[nm])), _sep_max[nm]])
	for x in l:
		print(x)
	l.append_array(_roce)
	var f := FileAccess.open(salida.path_join("grupo_roce.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(l) + "\n")
		f.close()
	super._terminar()
