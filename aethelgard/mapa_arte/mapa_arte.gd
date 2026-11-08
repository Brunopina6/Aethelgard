extends "res://mapa.gd"
# PROTOTIPO del mapamundi pintado (T-085, fase 1). Hereda TODO mapa.gd (movimiento, choques con la costa, zonas,
# encuentros, «Entrar», portal, menús, guardado y prólogo) y solo cambia cómo se dibuja:
#   - fondo: mapa_mundo.webp, horneado sin conexión por generar_mapa.gd a partir de los mismos datos de mapa.gd,
#     con el agua animada (agua_mapa.gdshader; «-- agua_quieta» la apaga);
#   - la máscara de tierra y zonas sale de mapa_zonas.png (idéntica a la que genera mapa.gd, comprobado en
#     prueba_mapamundi.gd) en vez de generarla al cargar;
#   - iconos ilustrados (iconos/<índice>.png) con su base en la posición del lugar, rótulos legibles en el móvil,
#     brújula con la estrella de la marca y el anillo del radio de «Entrar» cuando Kael está cerca.
# Alternativa funcional: si faltan los archivos o se pasa «-- mapa_clasico», se dibuja el mapa de siempre.
# Escena de prueba: mapa_arte/prototipo_mapa.tscn. No sustituye a mapa.tscn (fase 2, con el coordinador).

const ARTE := "res://mapa_arte/"
const ICONO := "res://mapa_arte/iconos/%d.png"
const ICONO_ANCLA := Vector2(56, 92)          # iconos_mapa.gd (ANCLA)
const ICONO_BAJO := 14.0                       # la base del icono queda 14 px por debajo del lugar
const ROTULO_ABAJO := ["Pastos Verdes"]       # rótulo bajo el icono (el de arriba pisaría el Portal del Vacío)
const ESCALA_CIUDAD := 1.2                     # las ciudades, un poco mayores: se leen aunque Kael esté delante
# Solo el dibujo: el rótulo del océano, un poco a la derecha para no pisar la costa con la letra más grande.
const DESPLAZA_REGION := {"OCÉANO DE BRUMA": Vector2(70, 0)}
const MARFIL := Color(1.0, 0.96, 0.89)
const ORO_CLARO := Color(1.0, 0.88, 0.58)
const TINTA := Color(0.05, 0.06, 0.13)

var iconos := {}
var marcas_arte: Node2D


func arte_activo() -> bool:
	return ResourceLoader.exists(ARTE + "mapa_mundo.webp") and not "mapa_clasico" in OS.get_cmdline_user_args()


# La máscara del juego, ya hecha (mapa_zonas.png); si falta, la de siempre (y con ella el dibujo antiguo).
func _generar_terreno() -> void:
	if arte_activo() and ResourceLoader.exists(ARTE + "mapa_zonas.png"):
		var r = load(ARTE + "mapa_zonas.png")            # importada como Image (datos, sin pasar por la GPU)
		var img: Image = r if r is Image else (r.get_image() if r is Texture2D else null)
		if img != null and img.get_size() == Vector2i(int(MAPA_TAM.x / 2), int(MAPA_TAM.y / 2)):
			img = img.duplicate()
			img.convert(Image.FORMAT_RGBA8)
			zonas_img = img
			return
	super._generar_terreno()


func _crear_mapa() -> void:
	if not arte_activo():
		super._crear_mapa()
		return
	var fondo := Sprite2D.new()
	fondo.texture = load(ARTE + "mapa_mundo.webp")
	fondo.centered = false
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if not "agua_quieta" in OS.get_cmdline_user_args():
		var mat := ShaderMaterial.new()
		mat.shader = load(ARTE + "agua_mapa.gdshader")
		mat.set_shader_parameter("datos_agua", load(ARTE + "agua_datos.png"))
		var ruido := NoiseTexture2D.new()
		ruido.width = 128
		ruido.height = 128
		ruido.seamless = true
		ruido.noise = FastNoiseLite.new()
		ruido.noise.frequency = 0.05
		mat.set_shader_parameter("ruido", ruido)
		mat.set_shader_parameter("tam_mundo", MAPA_TAM)
		fondo.material = mat
	add_child(fondo)

	for i in lugares.size():
		var ruta := ICONO % i
		if ResourceLoader.exists(ruta):
			iconos[i] = load(ruta)
	marcas_arte = Node2D.new()
	marcas_arte.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(marcas_arte)
	marcas_arte.draw.connect(func(): _dibujar_marcas(marcas_arte))

	var Estilo = load("res://estilo.gd")
	for i in lugares.size():
		var l: Dictionary = lugares[i]
		var ciudad: bool = l["tipo"] == "ciudad"
		var et := Label.new()
		et.text = l["nombre"]
		et.size = Vector2(300, 34)
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		et.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		et.add_theme_font_override("font", Estilo.normal())
		et.add_theme_font_size_override("font_size", 25 if ciudad else 22)
		et.add_theme_color_override("font_color", ORO_CLARO if ciudad else MARFIL)
		et.add_theme_color_override("font_outline_color", Color(TINTA, 0.92))
		et.add_theme_constant_override("outline_size", 8)
		et.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		et.add_theme_constant_override("shadow_offset_x", 0)
		et.add_theme_constant_override("shadow_offset_y", 3)
		et.add_theme_constant_override("shadow_outline_size", 8)
		et.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var y: float = l["pos"].y + ICONO_BAJO - ICONO_ANCLA.y * _escala(l) - 30.0
		if l["nombre"] in ROTULO_ABAJO:
			y = l["pos"].y + ICONO_BAJO + 2.0
		et.position = Vector2(l["pos"].x - 150.0, y)
		marcas_arte.add_child(et)

	var cursiva: Font = load("res://menu_combate.gd").fuente("res://fuentes/Cormorant-Italic.ttf", 5, 600)
	for r in REGIONES:
		var rl := Label.new()
		rl.text = r["nombre"]
		rl.size = Vector2(700, 60)
		rl.position = r["pos"] + DESPLAZA_REGION.get(r["nombre"], Vector2.ZERO) - rl.size * 0.5
		rl.pivot_offset = rl.size * 0.5
		rl.rotation_degrees = r["rot"]
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.add_theme_font_override("font", cursiva)
		rl.add_theme_font_size_override("font_size", 42)
		rl.add_theme_color_override("font_color", Color(0.90, 0.88, 1.0, 0.80))
		rl.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.22, 0.55))
		rl.add_theme_constant_override("outline_size", 7)
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marcas_arte.add_child(rl)


func _dibujar_marcas(n: Node2D) -> void:
	if not arte_activo():
		super._dibujar_marcas(n)
		return
	for i in lugares.size():
		var l: Dictionary = lugares[i]
		var p: Vector2 = l["pos"]
		if cerca == l:                                   # el radio real de «Entrar» (RADIO_LUGAR), sobre el suelo
			n.draw_circle(p, RADIO_LUGAR, Color(1.0, 0.86, 0.45, 0.10))
			n.draw_arc(p, RADIO_LUGAR, 0.0, TAU, 64, Color(1.0, 0.88, 0.50, 0.75), 2.0, true)
		if iconos.has(i):
			var e := _escala(l)
			var tam := Vector2(iconos[i].get_size()) * e
			n.draw_texture_rect(iconos[i], Rect2(p + Vector2(0, ICONO_BAJO) - ICONO_ANCLA * e, tam), false)
		if l["tipo"] == "ciudad":                         # dos estrellas de la marca a los lados del nombre
			var fuente: Font = load("res://estilo.gd").normal()
			var ancho := fuente.get_string_size(l["nombre"], HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
			var yr: float = p.y + ICONO_BAJO - ICONO_ANCLA.y * _escala(l) - 13.0
			for s in [-1.0, 1.0]:
				_estrella(n, Vector2(p.x + s * (ancho * 0.5 + 14.0), yr), 7.0, Color(TINTA, 0.8))
				_estrella(n, Vector2(p.x + s * (ancho * 0.5 + 14.0), yr), 5.5, ORO_CLARO)


static func _escala(l: Dictionary) -> float:
	return ESCALA_CIUDAD if l["tipo"] == "ciudad" else 1.0


static func _estrella(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := k * PI / 4.0 - PI / 2.0
		pts.append(p + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.3))
	c.draw_colored_polygon(pts, col)


# El anillo de «Entrar» aparece y desaparece con el lugar cercano.
func _comprobar_cerca() -> void:
	var antes = cerca
	super._comprobar_cerca()
	if cerca != antes and marcas_arte != null:
		marcas_arte.queue_redraw()


# Brújula de la marca: disco añil, aro de oro y rosa de cuatro puntas (el norte en marfil).
func _dibujar_brujula(c: Control) -> void:
	if not arte_activo():
		super._dibujar_brujula(c)
		return
	var cen := Vector2(52, 52)
	c.draw_circle(cen, 49, Color(0.043, 0.047, 0.15, 0.82))
	c.draw_arc(cen, 49, 0, TAU, 64, Color(0.95, 0.78, 0.42, 0.95), 2.5, true)
	c.draw_arc(cen, 43, 0, TAU, 64, Color(0.95, 0.78, 0.42, 0.35), 1.0, true)
	for k in 4:                                          # rosa: puntas largas a los cuatro vientos
		var a := k * PI / 2.0 - PI / 2.0
		var punta := cen + Vector2(cos(a), sin(a)) * 36.0
		var i1 := cen + Vector2(cos(a - PI / 4.0), sin(a - PI / 4.0)) * 8.0
		var i2 := cen + Vector2(cos(a + PI / 4.0), sin(a + PI / 4.0)) * 8.0
		var col := MARFIL if k == 0 else Color(0.95, 0.78, 0.42)
		c.draw_colored_polygon(PackedVector2Array([cen, i1, punta]), col)
		c.draw_colored_polygon(PackedVector2Array([cen, punta, i2]), col.darkened(0.3))
	for k in 4:                                          # puntas cortas en diagonal
		var a := k * PI / 2.0 - PI / 4.0
		c.draw_colored_polygon(PackedVector2Array([cen + Vector2(cos(a - 0.5), sin(a - 0.5)) * 5.0,
			cen + Vector2(cos(a), sin(a)) * 20.0, cen + Vector2(cos(a + 0.5), sin(a + 0.5)) * 5.0]), Color(0.73, 0.65, 0.96, 0.9))
	c.draw_circle(cen, 3.0, Color(0.043, 0.047, 0.15))
	var f: Font = load("res://menu_combate.gd").fuente("res://fuentes/Cormorant-Italic.ttf", 0, 700)
	c.draw_string(f, Vector2(46, 15), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MARFIL)
