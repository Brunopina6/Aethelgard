extends Node2D
# Dibujo del Firmamento de los Ecos (V12, 12/11; PROTOTIPO APAGADO, interruptor «orbes_v12»). Geometría 2D por código:
# sin texturas grandes (solo un degradado radial de 64×64 para los halos). Tres conceptos que comparten datos,
# lógica y entrada (firmamento.gd) y cambian el dibujo:
#   astrolabio    latón y cristal: anillos graduados, una red que gira, nodos engastados en biseles de latón
#   constelacion  noche profunda: estrellas con destellos, líneas de constelación finas, runas que orbitan
#   vidriera      rosetón de vidrio emplomado: los paños se encienden con el color del héroe al despertar sus nodos
# Dos capas (dos instancias de este script): «base» con mezcla normal y «luz» con mezcla aditiva (halos, energía,
# ondas). Se redibujan cada fotograma solo mientras el tablero está abierto.
#
# Estados de un nodo (se distinguen por FORMA y TRAZO, no solo por color; ver la leyenda de firmamento.gd):
#   bloqueado     sin relleno, contorno discontinuo y apagado, glifo tenue
#   disponible    contorno entero y luminoso, anillo que respira, precio debajo
#   caro          contorno entero pero tenue, precio debajo con «faltan»
#   desbloqueado  relleno de luz del héroe, halo y una chispa en cada vértice
#   dormido       contorno punteado violeta y una luna en lugar del glifo

const Datos := preload("res://firmamento/firmamento_datos.gd")
const Pincel := preload("res://firmamento/pincel.gd")

var tab                                   # firmamento.gd (estado, posiciones, estilo, tiempo, animaciones)
var capa := "base"
var _glow: Texture2D
var _panos: Array = []                    # vidriera: [polígono, anillo, ángulo0, ángulo1, radio0, radio1, color]
var _panos_de := ""
var _runas: Array = []                    # constelación: trazos de las runas que orbitan
var _p := Pincel.new()                    # todo lo de las capas fija, giro y viva va en una sola lista de triángulos
var _textos: Array = []                   # los números de los precios, después de los triángulos

const R_NODO := {"basica": 24.0, "intermedia": 29.0, "avanzada": 34.0, "excepcional": 42.0}


func _ready() -> void:
	if capa == "luz":
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	_glow = textura_halo()
	_preparar_runas()


static func textura_halo() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _draw() -> void:
	if tab == null:
		return
	if capa == "luz":
		_luz()
		return
	_p.limpiar()
	_p.pluma = 1.2 / maxf(tab.zoom, 0.1)
	_textos.clear()
	match capa:
		"fija":
			_fija()
		"giro":
			_giro()
		_:
			_viva()
	_p.emitir(self)
	for t in _textos:
		draw_string(tab.fuente, t[0], t[1], HORIZONTAL_ALIGNMENT_LEFT, -1, t[2], t[3])


# ================================================================= paleta por concepto

func _c(nombre: String) -> Color:
	var h: Color = tab.color_heroe
	match tab.estilo:
		"astrolabio":
			match nombre:
				"linea": return Color("C9A25A")
				"linea_tenue": return Color("6E5530", 0.7)
				"fondo_nodo": return Color("120E0A", 0.92)
				"apagado": return Color("9A8660", 0.75)
				"dormido": return Color("9A88C8", 0.7)
				"texto": return Color("F4EAD2")
		"constelacion":
			match nombre:
				"linea": return Color("C8D8FF")
				"linea_tenue": return Color("6F82B8", 0.45)
				"fondo_nodo": return Color("060A1C", 0.85)
				"apagado": return Color("8D9DC8", 0.68)
				"dormido": return Color("A890E0", 0.7)
				"texto": return Color("E8EEFF")
		_:
			match nombre:
				"linea": return Color("1A1420")
				"linea_tenue": return Color("2A2232")
				"fondo_nodo": return Color("17101F", 0.95)
				"apagado": return Color("9C8FB0", 0.75)
				"dormido": return Color("B49CE0", 0.75)
				"texto": return Color("F6ECFF")
	return h


# ================================================================= capas
# «fija»: decorado, enlaces, disco del centro, nodos y precios. Solo se redibuja cuando cambia algo (estado, héroe,
#         concepto, zoom) o durante una animación de desbloqueo o de error: es lo más caro y casi nunca cambia.
# «giro»: la red del astrolabio y las runas de la constelación; se dibuja una vez y gira con «rotation» (sin redibujar).
# «viva»: lo que se mueve a cada fotograma (trazos que fluyen, anillo que respira, chispas, selección, el símbolo que
#         late). Poca cosa: unas decenas de primitivas.
# «luz»:  mezcla aditiva (halos y energía), primero todas las líneas y luego todos los halos para que se agrupen.

func _fija() -> void:
	match tab.estilo:
		"astrolabio":
			_decor_astrolabio()
		"constelacion":
			_decor_constelacion()
		_:
			_decor_vidriera()
	for e in tab.enlaces:
		_enlace(e, false)
	_disco_centro()
	for n in tab.nodos:
		_nodo(n, false)
	for n in tab.nodos:                              # precios al final: el texto va junto (una sola textura)
		var est: String = tab.estado_visible(n["id"])
		if est == "disponible" or est == "caro":
			var c: Vector2 = tab.pos[n["id"]] + tab.temblor(n["id"])
			var r: float = R_NODO[n["rango"]]
			var fuera := c.normalized() if c.length() > 1.0 else Vector2.DOWN   # del lado de fuera (no tapa el centro)
			_precio(c + fuera * (r + 24.0 / minf(tab.zoom, 1.0)), int(Datos.PRECIOS.get(n.get("rango", "basica"), 1)),
				est == "disponible")


func _giro() -> void:
	var laton := _c("linea")
	match tab.estilo:
		"astrolabio":
			for i in 12:
				var a := i * TAU / 12.0
				var d := Vector2(sin(a), -cos(a))
				var p := d * 505.0
				var lado := Vector2(-d.y, d.x)
				_p.draw_colored_polygon(PackedVector2Array([p + d * 16.0, p + lado * 7.0, p - d * 6.0, p - lado * 7.0]),
					Color(laton, 0.6))
		"constelacion":
			var tenue := _c("linea_tenue")
			for i in _runas.size():
				var a := i * TAU / _runas.size()
				var rot := Transform2D(a, Vector2(sin(a), -cos(a)) * 545.0)
				for trazo in _runas[i]:
					var pts := PackedVector2Array()
					for p in trazo:
						pts.append(rot * (p * 14.0))
					_p.draw_polyline(pts, Color(tenue, 0.75), 1.6, true)


func _viva() -> void:
	for e in tab.enlaces:
		_enlace(e, true)
	var h: Color = tab.color_heroe
	simbolo(_p, Datos.SIMBOLO.get(tab.heroe, "eclipse"), Vector2.ZERO, 58.0 * 0.78,
		Color(h.lightened(0.3), 0.85 + 0.15 * sin(tab.t * 1.3)), 3.0)
	for n in tab.nodos:
		_nodo(n, true)


# ---------------------------------------------------------------- decorado de cada concepto

func _decor_astrolabio() -> void:
	var laton := _c("linea")
	var tenue := _c("linea_tenue")
	# limbo graduado
	_p.draw_arc(Vector2.ZERO, 560.0, 0, TAU, 128, Color(laton, 0.85), 3.0, true)
	_p.draw_arc(Vector2.ZERO, 540.0, 0, TAU, 128, Color(laton, 0.5), 1.5, true)
	for i in 72:
		var a := i * TAU / 72.0
		var largo := 20.0 if i % 6 == 0 else 9.0
		var d := Vector2(sin(a), -cos(a))
		_p.draw_line(d * 540.0, d * (540.0 + largo), Color(laton, 0.75 if i % 6 == 0 else 0.4), 1.5 if i % 6 == 0 else 1.0)
	# órbitas y eclíptica excéntrica
	for r in [150.0, 345.0, 455.0]:
		_p.draw_arc(Vector2.ZERO, r, 0, TAU, 96, tenue, 1.2, true)
	_p.draw_arc(Vector2(0, -70), 300.0, 0, TAU, 96, Color(laton, 0.18), 1.0, true)
	# red (rete): el anillo; sus punteros giran en la capa «giro»
	_p.draw_arc(Vector2.ZERO, 505.0, 0, TAU, 128, Color(laton, 0.35), 6.0, true)
	# retícula
	for a in [0.0, PI * 0.5]:
		var d := Vector2(sin(a), -cos(a))
		_p.draw_line(d * 70.0, d * 535.0, Color(laton, 0.16), 1.0)
		_p.draw_line(-d * 70.0, -d * 535.0, Color(laton, 0.16), 1.0)


func _decor_constelacion() -> void:
	var tenue := _c("linea_tenue")
	for r in [150.0, 300.0, 450.0]:                 # anillos de puntos
		var n := int(r / 6.0)
		for i in n:
			var a := i * TAU / n
			_p.draw_rect(Rect2(Vector2(sin(a), -cos(a)) * r - Vector2(1, 1), Vector2(2, 2)), Color(tenue, 0.55))
	_p.draw_arc(Vector2.ZERO, 565.0, 0, TAU, 128, Color(tenue, 0.4), 1.0, true)
	_p.draw_arc(Vector2.ZERO, 525.0, 0, TAU, 128, Color(tenue, 0.25), 1.0, true)


func _preparar_runas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7741
	_runas.clear()
	for i in 18:
		var r: Array = []
		r.append([Vector2(0, -1), Vector2(0, 1)])
		for k in rng.randi_range(1, 2):
			var y := rng.randf_range(-0.8, 0.3)
			var lado := -1.0 if rng.randf() < 0.5 else 1.0
			r.append([Vector2(0, y), Vector2(0.6 * lado, y - rng.randf_range(-0.5, 0.5))])
		_runas.append(r)


func _preparar_panos() -> void:
	var clave: String = tab.heroe + tab.estilo
	if clave == _panos_de:
		return
	_panos_de = clave
	_panos.clear()
	var anillos := [[70.0, 170.0, 6], [170.0, 300.0, 12], [300.0, 440.0, 18], [440.0, 560.0, 24]]
	var paleta := [Color("6B3FA0"), Color("1F6F7A"), Color("B5782A"), Color("8A2F4F"), Color("2F4F9A")]
	for ia in anillos.size():
		var r0: float = anillos[ia][0]
		var r1: float = anillos[ia][1]
		var nseg: int = anillos[ia][2]
		var desfase := (PI / nseg) * (ia % 2)
		for j in nseg:
			var a0: float = desfase + j * TAU / nseg
			var a1: float = a0 + TAU / nseg
			var pts := PackedVector2Array()
			for k in 5:
				var a := lerpf(a0, a1, k / 4.0)
				pts.append(Vector2(sin(a), -cos(a)) * (r1 - 3.0))
			for k in 5:
				var a := lerpf(a1, a0, k / 4.0)
				pts.append(Vector2(sin(a), -cos(a)) * (r0 + 3.0))
			_panos.append([pts, ia, a0, a1, r0, r1, paleta[(j + ia * 2) % paleta.size()]])


func _pano_encendido(p: Array) -> float:
	var luz := 0.0
	for n in tab.nodos:
		var est: String = tab.estado_visible(n["id"])
		if est != "desbloqueado":
			continue
		var pos: Vector2 = tab.pos[n["id"]]
		var r := pos.length()
		var a := fposmod(atan2(pos.x, -pos.y), TAU)
		var a0 := fposmod(float(p[2]), TAU)
		var a1 := a0 + float(p[3]) - float(p[2])
		var dentro_a := (a >= a0 and a <= a1) or (a + TAU >= a0 and a + TAU <= a1)
		if dentro_a and r >= float(p[4]) - 25.0 and r <= float(p[5]) + 25.0:
			luz = maxf(luz, tab.brillo_nodo(n["id"]))
	return luz


func _decor_vidriera() -> void:
	_preparar_panos()
	var plomo := _c("linea")
	var h: Color = tab.color_heroe
	for p in _panos:
		var luz := _pano_encendido(p)
		var base: Color = p[6]
		var col := Color(base.darkened(0.55), 0.55).lerp(Color(h.lerp(base, 0.25), 0.85), luz)
		_p.draw_colored_polygon(p[0], col)
	for p in _panos:                                 # el plomo encima
		var cerrado: PackedVector2Array = p[0].duplicate()
		cerrado.append(p[0][0])
		_p.draw_polyline(cerrado, plomo, 5.0, true)
	_p.draw_arc(Vector2.ZERO, 566.0, 0, TAU, 128, plomo, 10.0, true)
	_p.draw_arc(Vector2.ZERO, 566.0, 0, TAU, 128, Color("4A3A5A", 0.8), 2.0, true)


# ---------------------------------------------------------------- enlaces

func _recortar(a: Vector2, b: Vector2, ra: float, rb: float) -> Array:
	var d := b - a
	var l := d.length()
	if l < 1.0:
		return [a, b]
	var u := d / l
	return [a + u * ra, b - u * rb]


func _enlace(e: Dictionary, viva: bool) -> void:
	var a: Vector2 = tab.pos_de(e["de"])
	var b: Vector2 = tab.pos_de(e["a"])
	var seg := _recortar(a, b, tab.radio_de(e["de"]) + 4.0, tab.radio_de(e["a"]) + 4.0)
	var p0: Vector2 = seg[0]
	var p1: Vector2 = seg[1]
	var est: String = tab.estado_enlace(e)
	var h: Color = tab.color_heroe
	if viva:                                         # lo que se mueve: la energía que fluye y la de un desbloqueo
		if est == "abierto":
			var ancho: float = {"astrolabio": 2.0, "constelacion": 1.8}.get(tab.estilo, 2.5)
			_trazos_que_fluyen(p0, p1, Color(h.lightened(0.3), 0.9), ancho)
		var frac: float = tab.progreso_enlace(e)
		if frac > 0.0 and frac < 1.0:                # el tramo ya recorrido por la energía y su cabeza
			var cabeza := p0.lerp(p1, frac)
			_p.draw_line(p0, cabeza, h.lightened(0.4), 4.0, true)
			_p.draw_circle(cabeza, 7.0, Color.WHITE)
		return
	match tab.estilo:
		"astrolabio":
			var lado := (p1 - p0).normalized().orthogonal() * 4.0
			var laton := _c("linea") if est != "cerrado" else _c("linea_tenue")
			_p.draw_line(p0 + lado, p1 + lado, laton, 1.6, true)
			_p.draw_line(p0 - lado, p1 - lado, laton, 1.6, true)
			if est == "luz":
				_p.draw_line(p0, p1, h.lightened(0.2), 3.0, true)
		"constelacion":
			if est == "luz":
				_p.draw_line(p0, p1, Color(h.lightened(0.35), 0.95), 2.2, true)
			elif est == "abierto":
				_p.draw_line(p0, p1, Color(h, 0.35), 1.4, true)
			else:
				_discontinua(p0, p1, _c("linea_tenue"), 1.2, 6.0, 8.0)
		_:
			_p.draw_line(p0, p1, _c("linea"), 8.0, true)    # plomo
			if est == "luz":
				_p.draw_line(p0, p1, h.lightened(0.25), 3.5, true)
			elif est == "abierto":
				_p.draw_line(p0, p1, Color(h, 0.3), 2.5, true)
			else:
				_p.draw_line(p0, p1, Color("3A3046"), 2.0, true)


func _discontinua(a: Vector2, b: Vector2, col: Color, ancho: float, trazo: float, hueco: float) -> void:
	var l := a.distance_to(b)
	var u := (b - a) / maxf(l, 0.001)
	var s := 0.0
	while s < l:
		_p.draw_line(a + u * s, a + u * minf(s + trazo, l), col, ancho)
		s += trazo + hueco


func _trazos_que_fluyen(a: Vector2, b: Vector2, col: Color, ancho: float) -> void:
	var l := a.distance_to(b)
	var u := (b - a) / maxf(l, 0.001)
	var paso := 26.0
	var s := fposmod(tab.t * 40.0, paso)
	while s < l:
		var e := minf(s + 9.0, l)
		_p.draw_line(a + u * s, a + u * e, col, ancho, true)
		s += paso


# ---------------------------------------------------------------- formas

static func poligono(c: Vector2, r: float, lados: int, rot := 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in lados:
		var a := rot + i * TAU / lados
		p.append(c + Vector2(sin(a), -cos(a)) * r)
	return p


static func estrella(c: Vector2, r1: float, r2: float, puntas: int, rot := 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in puntas * 2:
		var a := rot + i * PI / puntas
		p.append(c + Vector2(sin(a), -cos(a)) * (r1 if i % 2 == 0 else r2))
	return p


# Forma del nodo según su rango: círculo (básica), hexágono (intermedia), estrella de 8 (avanzada) y estrella grande
# con anillo (excepcional). La vidriera usa gemas talladas; la constelación, estrellas con más puntas cuanto más alto.
func forma(rango: String, c: Vector2, r: float, estilo: String) -> PackedVector2Array:
	if estilo == "constelacion":
		match rango:
			"basica": return estrella(c, r, r * 0.55, 4)
			"intermedia": return estrella(c, r, r * 0.6, 6)
			"avanzada": return estrella(c, r, r * 0.55, 8)
			_: return estrella(c, r, r * 0.5, 8, PI / 8.0)
	match rango:
		"basica": return poligono(c, r, 16) if estilo == "astrolabio" else poligono(c, r, 4)
		"intermedia": return poligono(c, r, 6)
		"avanzada": return estrella(c, r, r * 0.78, 8)
		_: return estrella(c, r, r * 0.62, 8, PI / 8.0)


func _cerrar(p: PackedVector2Array) -> PackedVector2Array:
	var q := p.duplicate()
	q.append(p[0])
	return q


func _contorno_discontinuo(p: PackedVector2Array, col: Color, ancho: float, cada := 2) -> void:
	for i in p.size():
		if i % cada == 0:
			_p.draw_line(p[i], p[(i + 1) % p.size()], col, ancho, true)


# ---------------------------------------------------------------- nodos

func _nodo(n: Dictionary, viva: bool) -> void:
	var id: String = n["id"]
	var c: Vector2 = tab.pos[id] + tab.temblor(id)
	var rango: String = n["rango"]
	var r: float = R_NODO[rango]
	var est: String = tab.estado_visible(id)
	var h: Color = tab.color_heroe
	var estilo: String = tab.estilo
	var brillo: float = tab.brillo_nodo(id)
	if viva:                                         # anillo que respira, chispas y selección
		if est == "disponible":
			var resp: float = 0.5 + 0.5 * sin(tab.t * 3.0)
			_p.draw_arc(c, r + 10.0 + resp * 4.0, 0, TAU, 40, Color(h, 0.35 + 0.35 * resp), 1.6, true)
		if est == "desbloqueado" and estilo != "vidriera":
			for i in 4:
				var a: float = tab.t * 0.6 + i * TAU / 4.0
				_p.draw_circle(c + Vector2(sin(a), -cos(a)) * (r + 3.0), 1.6, Color(1, 1, 1, 0.8 * brillo))
		if id == tab.seleccion:
			var a0: float = tab.t * 1.6
			var col := Color(_c("texto"), 0.95)
			_p.draw_arc(c, r + 16.0, a0, a0 + 1.9, 20, col, 3.0, true)
			_p.draw_arc(c, r + 16.0, a0 + PI, a0 + PI + 1.9, 20, col, 3.0, true)
		return
	var p := forma(rango, c, r, estilo)
	# relleno
	var fondo := _c("fondo_nodo")
	if est == "desbloqueado":
		var lleno := h.lerp(Color.WHITE, 0.15) if estilo != "vidriera" else h
		_p.draw_colored_polygon(p, fondo.lerp(Color(lleno, 0.95), brillo))
		if estilo == "vidriera":                     # facetas de la gema
			for v in p:
				_p.draw_line(c, v, Color(1, 1, 1, 0.35 * brillo), 1.0, true)
	else:
		_p.draw_colored_polygon(p, fondo)
	# bisel de latón del astrolabio (todos los nodos van engastados)
	if estilo == "astrolabio":
		_p.draw_arc(c, r + 6.0, 0, TAU, 32, Color(_c("linea"), 0.9 if est != "bloqueado" else 0.45), 2.0, true)
		if rango == "excepcional":
			_p.draw_arc(c, r + 12.0, 0, TAU, 40, Color(_c("linea"), 0.6), 1.2, true)
	elif rango == "excepcional":
		_p.draw_arc(c, r + 9.0, 0, TAU, 40, Color(h, 0.5 if est == "desbloqueado" else 0.25), 1.5, true)
	# contorno según el estado
	match est:
		"desbloqueado":
			_p.draw_polyline(_cerrar(p), Color.WHITE.lerp(h, 0.3), 2.2, true)
		"disponible":
			_p.draw_polyline(_cerrar(p), h.lightened(0.25), 3.0, true)
		"caro":
			_p.draw_polyline(_cerrar(p), Color(h, 0.55), 2.0, true)
		"dormido":
			_contorno_discontinuo(p if p.size() >= 8 else poligono(c, r, 16), _c("dormido"), 1.6, 2)
		_:
			_contorno_discontinuo(p if p.size() >= 8 else poligono(c, r, 16), _c("apagado"), 1.5, 2)
	# glifo
	var g: String = "luna" if est == "dormido" else String(n.get("glifo", "estrella"))
	var colg: Color
	match est:
		"desbloqueado": colg = Color("101426")
		"disponible": colg = h.lightened(0.45)
		"caro": colg = Color(h.lightened(0.3), 0.75)
		"dormido": colg = _c("dormido")
		_: colg = _c("apagado")
	glifo(_p, g, c, r * 0.5, colg, 2.0 if r < 26.0 else 2.4)


func _precio(c: Vector2, valor: int, alcanza: bool) -> void:
	var k := 1.0 / clampf(tab.zoom, 0.5, 1.0)        # se lee igual a cualquier zoom: unos 18 px en pantalla
	var f: Font = tab.fuente
	var txt := str(valor)
	var tam := int(18.0 * k)
	var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var w := ancho + 30.0 * k
	var rect := Rect2(c - Vector2(w * 0.5, 13.0 * k), Vector2(w, 26.0 * k))
	_p.draw_rect(rect, Color(0.02, 0.03, 0.07, 0.85))
	var h: Color = tab.color_heroe
	_p.draw_rect(rect, Color(h, 0.85 if alcanza else 0.4), false, 1.4 * k)
	orbe(_p, rect.position + Vector2(13, 13) * k, 7.0 * k, h if alcanza else Color(h, 0.5))
	_textos.append([rect.position + Vector2(23, 19.5) * k, txt, tam, Color.WHITE if alcanza else Color(1, 1, 1, 0.6)])


# El icono del orbe (una gema de ocho facetas): lo usan el precio, el contador y el panel.
static func orbe(ci, c: Vector2, r: float, col: Color) -> void:
	var p := poligono(c, r, 8, PI / 8.0)
	ci.draw_colored_polygon(p, Color(col.darkened(0.35), col.a))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.55, -r * 0.2), c + Vector2(0, -r * 0.8),
		c + Vector2(r * 0.55, -r * 0.2), c]), Color(col.lightened(0.45), col.a))
	var q := p.duplicate()
	q.append(p[0])
	ci.draw_polyline(q, Color(col.lightened(0.6), col.a), 1.2, true)


# ---------------------------------------------------------------- símbolo del centro

func _disco_centro() -> void:                         # el disco; el símbolo, que late, va en la capa «viva»
	var h: Color = tab.color_heroe
	var r := 58.0
	match tab.estilo:
		"astrolabio":
			_p.draw_circle(Vector2.ZERO, r + 8.0, Color("1A140D"))
			_p.draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 48, _c("linea"), 3.0, true)
			_p.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(_c("linea"), 0.5), 1.2, true)
		"constelacion":
			_p.draw_circle(Vector2.ZERO, r, Color(0.02, 0.03, 0.1, 0.8))
			_p.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(h, 0.5), 1.4, true)
		_:
			var p := poligono(Vector2.ZERO, r + 6.0, 12)
			_p.draw_colored_polygon(p, Color("120C18"))
			for v in p:
				_p.draw_line(Vector2.ZERO, v, Color(h, 0.25), 1.0, true)
			_p.draw_polyline(_cerrar(p), _c("linea"), 6.0, true)
			_p.draw_polyline(_cerrar(p), Color(h, 0.6), 1.5, true)


# ================================================================= capa de luz (aditiva)

func _halo(c: Vector2, r: float, col: Color) -> void:
	draw_texture_rect(_glow, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


func _luz() -> void:
	var h: Color = tab.color_heroe
	var fuerza := 0.8 if tab.estilo == "vidriera" else 1.0
	for e in tab.enlaces:                            # enlaces con luz: primero todos los brillos anchos (sin textura)
		if tab.estado_enlace(e) == "luz":
			draw_line(tab.pos_de(e["de"]), tab.pos_de(e["a"]), Color(h, 0.13 * fuerza), 12.0)
	_halo(Vector2.ZERO, 150.0, Color(h, (0.28 + 0.08 * sin(tab.t * 1.3)) * fuerza))
	for e in tab.enlaces:                            # y luego las chispas que viajan (todas con la misma textura)
		if tab.estado_enlace(e) == "luz":
			var f := fposmod(tab.t * 0.35 + float(e["fase"]), 1.0)
			_halo(tab.pos_de(e["de"]).lerp(tab.pos_de(e["a"]), f), 14.0, Color(h.lightened(0.4), 0.55 * fuerza))
	for n in tab.nodos:
		var id: String = n["id"]
		var est: String = tab.estado_visible(id)
		var r: float = R_NODO[n["rango"]]
		var c: Vector2 = tab.pos[id]
		if est == "desbloqueado":
			var b: float = tab.brillo_nodo(id)
			_halo(c, r * 3.2, Color(h, (0.45 + 0.1 * sin(tab.t * 2.0 + c.x)) * b * fuerza))
		elif est == "disponible":
			_halo(c, r * 2.4, Color(h, (0.12 + 0.1 * sin(tab.t * 3.0)) * fuerza))
	if tab.seleccion != "" and tab.pos.has(tab.seleccion):
		_halo(tab.pos[tab.seleccion], 70.0, Color(1, 1, 1, 0.1))
	_luz_animacion()


# Desbloqueo: una cuenta de energía recorre cada enlace desde lo ya despierto (0-0,55 s), luego el nodo estalla en una
# onda, un destello y doce chispas (0,55-1,3 s). Error (sin orbes o bloqueado): el nodo tiembla (temblor()).
func _luz_animacion() -> void:
	var an: Dictionary = tab.anim
	if an.is_empty():
		return
	var h: Color = tab.color_heroe
	var t: float = tab.t - float(an["t0"])
	var destino: Vector2 = tab.pos[an["id"]]
	if t < tab.T_VIAJE:
		var f: float = ease(t / tab.T_VIAJE, 0.6)
		for de in an["desde"]:
			var o: Vector2 = tab.pos_de(de)
			var p := o.lerp(destino, f)
			_halo(p, 48.0, Color(h.lightened(0.5), 0.95))
			_halo(p, 18.0, Color(1, 1, 1, 1.0))
			for k in 4:                               # estela
				_halo(o.lerp(destino, maxf(0.0, f - 0.05 * (k + 1))), 16.0 - k * 3.0, Color(h, 0.4 - k * 0.08))
	else:
		var u := clampf((t - tab.T_VIAJE) / (tab.T_TOTAL - tab.T_VIAJE), 0.0, 1.0)
		var r: float = R_NODO[tab.nodo_por_id(an["id"])["rango"]]
		_halo(destino, r * (2.0 + 4.0 * u), Color(1, 1, 1, 0.9 * (1.0 - u)))
		draw_arc(destino, r + 110.0 * ease(u, 0.4), 0, TAU, 48, Color(h.lightened(0.3), 1.0 - u), 4.0 * (1.0 - u) + 1.0, true)
		for k in 12:
			var a := k * TAU / 12.0 + 0.3
			var d := Vector2(sin(a), -cos(a))
			var p0 := destino + d * (r + 80.0 * ease(u, 0.5))
			draw_line(p0, p0 + d * 14.0 * (1.0 - u), Color(h.lightened(0.5), 1.0 - u), 2.0)


# ================================================================= glifos y símbolos (líneas en coordenadas -1..1)

static func _pl(ci, pts: Array, c: Vector2, s: float, col: Color, w: float) -> void:
	var q := PackedVector2Array()
	for p in pts:
		q.append(c + p * s)
	ci.draw_polyline(q, col, w, true)


# Arco (0 = arriba, sentido horario) en coordenadas -1..1.
static func _arco(centro: Vector2, r: float, a0: float, a1: float, n: int) -> Array:
	var q: Array = []
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		q.append(centro + Vector2(sin(a), -cos(a)) * r)
	return q


static func _corazon() -> Array:
	var q: Array = []
	for i in 29:
		var t := i * TAU / 28.0
		q.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) / 17.0)
	return q


static func _espiral() -> Array:
	var q: Array = []
	for i in 41:
		var t := i * 5.5 * PI / 40.0
		var r := 0.1 + 0.11 * t
		q.append(Vector2(cos(t), sin(t)) * r)
	return q


static func _almendra(signo: float) -> Array:
	var q: Array = []
	for i in 15:
		var u := i / 14.0
		q.append(Vector2(lerpf(-1, 1, u), signo * sin(u * PI) * 0.55))
	return q


static func glifo(ci, g: String, c: Vector2, s: float, col: Color, w: float) -> void:
	match g:
		"espada":
			_pl(ci, [Vector2(-0.14, 0.35), Vector2(-0.14, -0.7), Vector2(0, -1), Vector2(0.14, -0.7), Vector2(0.14, 0.35)], c, s, col, w)
			_pl(ci, [Vector2(-0.5, 0.38), Vector2(0.5, 0.38)], c, s, col, w)
			_pl(ci, [Vector2(0, 0.4), Vector2(0, 0.95)], c, s, col, w)
		"escudo":
			_pl(ci, [Vector2(-0.75, -0.8), Vector2(0.75, -0.8), Vector2(0.75, 0.05), Vector2(0, 0.95), Vector2(-0.75, 0.05), Vector2(-0.75, -0.8)], c, s, col, w)
		"ala":
			_pl(ci, [Vector2(-0.85, 0.6), Vector2(-0.2, -0.15), Vector2(0.85, -0.85)], c, s, col, w)
			_pl(ci, [Vector2(-0.85, 0.6), Vector2(0.1, 0.1), Vector2(0.85, -0.3)], c, s, col, w)
			_pl(ci, [Vector2(-0.85, 0.6), Vector2(0.3, 0.5), Vector2(0.8, 0.25)], c, s, col, w)
		"corazon":
			_pl(ci, _corazon(), c, s, col, w)
		"gota":
			_pl(ci, [Vector2(0, -1)] + _arco(Vector2(0, 0.3), 0.6, 0.65, TAU - 0.65, 18) +[Vector2(0, -1)], c, s, col, w)
		"espiral":
			_pl(ci, _espiral(), c, s, col, w)
		"ojo":
			_pl(ci, _almendra(-1.0), c, s, col, w)
			_pl(ci, _almendra(1.0), c, s, col, w)
			ci.draw_circle(c, s * 0.25, col)
		"estrella":
			var p := estrella(c, s, s * 0.3, 4)
			p.append(p[0])
			ci.draw_polyline(p, col, w, true)
		"runa":
			_pl(ci, [Vector2(-0.35, -0.95), Vector2(-0.35, 0.95)], c, s, col, w)
			_pl(ci, [Vector2(-0.35, -0.45), Vector2(0.5, -0.95)], c, s, col, w)
			_pl(ci, [Vector2(-0.35, 0.05), Vector2(0.5, -0.45)], c, s, col, w)
		"llama":
			_pl(ci, [Vector2(0, -1), Vector2(0.5, -0.15), Vector2(0.48, 0.45), Vector2(0, 0.92), Vector2(-0.48, 0.45), Vector2(-0.5, -0.15), Vector2(-0.12, -0.4), Vector2(0, -1)], c, s, col, w)
			_pl(ci, [Vector2(0, -0.1), Vector2(0.2, 0.35), Vector2(0, 0.6), Vector2(-0.2, 0.35), Vector2(0, -0.1)], c, s, col, w * 0.8)
		"raiz":
			_pl(ci, [Vector2(0, -0.95), Vector2(0, 0.15)], c, s, col, w)
			_pl(ci, [Vector2(-0.65, 0.95), Vector2(0, 0.15), Vector2(0.65, 0.95)], c, s, col, w)
			_pl(ci, [Vector2(0, 0.15), Vector2(0, 0.95)], c, s, col, w)
			_pl(ci, [Vector2(-0.45, -0.55), Vector2(0, -0.3), Vector2(0.45, -0.6)], c, s, col, w)
		"mano":
			_pl(ci, [Vector2(-0.65, -0.05), Vector2(-0.65, 0.45), Vector2(0, 0.9), Vector2(0.65, 0.45), Vector2(0.65, -0.05)], c, s, col, w)
			for x in [-0.32, 0.0, 0.32]:
				_pl(ci, [Vector2(x, 0.25), Vector2(x, -0.85 + absf(x) * 0.4)], c, s, col, w)
		"luna":
			_pl(ci, _arco(Vector2.ZERO, 0.9, PI * 0.9, PI * 2.1, 20) + _arco(Vector2(0.38, 0), 0.72, PI * 1.92, PI * 1.08, 16),
				c, s, col, w)
		_:
			ci.draw_circle(c, s * 0.35, col)


static func simbolo(ci, cual: String, c: Vector2, s: float, col: Color, w: float) -> void:
	match cual:
		"espada_estrella":
			var p := estrella(c, s * 1.0, s * 0.2, 4, PI / 4.0)
			p.append(p[0])
			ci.draw_polyline(p, Color(col, col.a * 0.55), w * 0.6, true)
			_pl(ci, [Vector2(-0.09, 0.42), Vector2(-0.09, -0.78), Vector2(0, -1), Vector2(0.09, -0.78), Vector2(0.09, 0.42)], c, s, col, w)
			_pl(ci, [Vector2(-0.4, 0.45), Vector2(0.4, 0.45)], c, s, col, w)
			_pl(ci, [Vector2(0, 0.47), Vector2(0, 0.85)], c, s, col, w)
			ci.draw_circle(c + Vector2(0, 0.92) * s, s * 0.07, col)
		"caliz_luna":
			_pl(ci, _arco(Vector2(0, -0.55), 0.38, PI - 2.3, PI + 2.3, 20), c, s, col, w)
			_pl(ci, _arco(Vector2(0, -0.66), 0.3, PI - 2.0, PI + 2.0, 16), c, s, col, w * 0.7)
			_pl(ci, [Vector2(-0.6, -0.08), Vector2(0.6, -0.08), Vector2(0.32, 0.38), Vector2(0.08, 0.48), Vector2(0.08, 0.78),
				Vector2(0.36, 0.95), Vector2(-0.36, 0.95), Vector2(-0.08, 0.78), Vector2(-0.08, 0.48), Vector2(-0.32, 0.38),
				Vector2(-0.6, -0.08)], c, s, col, w)
		"escudo_torre":
			_pl(ci, [Vector2(-0.8, -0.85), Vector2(0.8, -0.85), Vector2(0.8, 0.1), Vector2(0, 1.0), Vector2(-0.8, 0.1), Vector2(-0.8, -0.85)], c, s, col, w)
			_pl(ci, [Vector2(-0.35, 0.45), Vector2(-0.35, -0.35), Vector2(-0.35, -0.55), Vector2(-0.18, -0.55), Vector2(-0.18, -0.4),
				Vector2(0.0, -0.4), Vector2(0.0, -0.55), Vector2(0.18, -0.55), Vector2(0.18, -0.4), Vector2(0.35, -0.4),
				Vector2(0.35, -0.55), Vector2(0.35, 0.45)], c, s, col, w * 0.8)
			_pl(ci, [Vector2(-0.12, 0.45), Vector2(-0.12, 0.15), Vector2(0.12, 0.15), Vector2(0.12, 0.45)], c, s, col, w * 0.7)
		_:
			ci.draw_arc(c, s * 0.8, 0, TAU, 40, col, w, true)
			ci.draw_circle(c + Vector2(s * 0.3, -s * 0.15), s * 0.66, Color(0.02, 0.02, 0.06, 0.92))
