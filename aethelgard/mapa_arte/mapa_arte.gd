extends "res://mapa.gd"
# Mapamundi pintado (T-085): es el script de mapa.tscn. Hereda TODO mapa.gd (movimiento, choques con la costa,
# zonas, encuentros, «Entrar», portal, menús, sonido, guardado y prólogo) y solo cambia cómo se dibuja:
#   - fondo: mapa_mundo.webp, horneado sin conexión por generar_mapa.gd a partir de los mismos datos de mapa.gd,
#     con el agua animada (agua_mapa.gdshader);
#   - la máscara de tierra y zonas sale de mapa_zonas.png (idéntica a la que genera mapa.gd, comprobado en
#     prueba_mapamundi.gd) en vez de generarla al cargar;
#   - iconos ilustrados (iconos/<índice>.png) con su base en la posición del lugar, el anillo del radio real de
#     «Entrar» cuando Kael está cerca, rótulos legibles en el móvil (por encima de Kael) y brújula de la marca.
# El mapa de siempre (el que dibuja mapa.gd) sigue disponible:
#   - con «-- mapa_clasico» (PC, editor y pruebas);
#   - sin argumentos, solo en la versión experimental (modo3d.gd: la app «Aethelgard Exp» o «-- 3d»), con
#     [mapa] clasico=true en user://ajustes.cfg, por si el móvil va peor (elegir() lo escribe y lo quita);
#   - y él solo, si faltan los archivos de mapa_arte/.
# El agua animada se apaga igual: «-- agua_quieta» o, en la versión experimental, [mapa] agua_quieta=true.
# Se decide una vez, al abrir el mapa: el cambio vale para la próxima vez que se abra.

const ARTE := "res://mapa_arte/"
const ICONO := "res://mapa_arte/iconos/%d.png"
const ICONO_ANCLA := Vector2(56, 92)          # iconos_mapa.gd (ANCLA)
const ICONO_BAJO := 14.0                       # la base del icono queda 14 px por debajo del lugar
const ESCALA_CIUDAD := 1.2                     # las ciudades, un poco mayores: se leen aunque Kael esté delante
const ROTULO_TAM := Vector2(300, 34)           # caja de cada rótulo (el texto va centrado en ella)
const ROTULO_LETRA := 22                       # tamaño de la letra (las ciudades, ROTULO_LETRA_CIUDAD)
const ROTULO_LETRA_CIUDAD := 25
const ROTULO_BORDE := 8                        # grosor del contorno de la letra
# Dónde va el rótulo de cada lugar. Por defecto, encima de su icono y centrado. El grupo de Oakhaven, el Portal del
# Vacío, Pastos Verdes y el Gran Bosque Verde está apretado: estos van donde no pisan otro icono ni otro rótulo
# (prueba_mapamundi.gd lo comprueba, con la exploración 3D y sin ella). [sitio, desplazamiento]:
#   "arriba" encima del icono · "abajo" debajo del icono · "izquierda" / "derecha" a un lado, a media altura.
const ROTULO_SITIO := {
	"Portal del Vacío": ["arriba", Vector2(34, 0)],     # centrado, pegaba con el castillo de Oakhaven
	"Pastos Verdes": ["izquierda", Vector2(-2, 0)],
	"Gran Bosque Verde": ["derecha", Vector2(-10, -28)],  # debajo tocaba el botón «Entrar» al abrir el mapa
	"Cumbres de Ciclópea": ["izquierda", Vector2(-2, -6)],  # encima quedaba bajo la brújula al abrir el mapa
}
# Iconos que no van centrados en su lugar o con otro tamaño, para no pisar a sus vecinos: [desplazamiento, escala].
# El icono sigue conteniendo la posición del lugar y el anillo de «Entrar» sigue centrado en ella.
const ICONO_AJUSTE := {
	"Pastos Verdes": [Vector2(-30, -6), 0.85],          # entre el Portal (arriba) y el Gran Bosque (abajo a la derecha)
}
# Solo el dibujo: el rótulo del océano, un poco a la derecha para no pisar la costa con la letra más grande.
const DESPLAZA_REGION := {"OCÉANO DE BRUMA": Vector2(70, 0)}
const MARFIL := Color(1.0, 0.96, 0.89)
const ORO_CLARO := Color(1.0, 0.88, 0.58)
const TINTA := Color(0.05, 0.06, 0.13)
const AJUSTES := "user://ajustes.cfg"         # el de sonido.gd: aquí se lee; elegir() solo toca la sección [mapa]
const SECCION := "mapa"

var arte := false                              # el mapa pintado está activo (se decide al abrir el mapa)
var agua_viva := false                         # el agua animada está activa
var iconos := {}
var marcas_arte: Node2D                        # anillo de «Entrar» e iconos, en el suelo (Kael pasa por delante)
var rotulos: Node2D                            # nombres de los lugares y de las regiones, por encima de Kael


func _ready() -> void:
	arte = _elegir_arte()
	agua_viva = arte and not agua_quieta_elegida() and ResourceLoader.exists(ARTE + "agua_datos.png")
	super._ready()


func arte_activo() -> bool:
	return arte


func _elegir_arte() -> bool:
	if clasico_elegido():
		return false
	return ResourceLoader.exists(ARTE + "mapa_mundo.webp") and ResourceLoader.exists(ARTE + "mapa_zonas.png")


# ---------------------------------------------------------------- elegir el mapa clásico

# ¿Se ha elegido el mapa clásico? «-- mapa_clasico» o, solo en la versión experimental, [mapa] clasico=true.
static func clasico_elegido() -> bool:
	return "mapa_clasico" in OS.get_cmdline_user_args() or opcion("clasico")


# ¿Se ha pedido el agua quieta? «-- agua_quieta» o, solo en la versión experimental, [mapa] agua_quieta=true.
static func agua_quieta_elegida() -> bool:
	return "agua_quieta" in OS.get_cmdline_user_args() or opcion("agua_quieta")


# [mapa] <clave> de user://ajustes.cfg, solo en la versión experimental (modo3d.gd). Sin archivo o sin la clave, no.
# Solo lee: abrir el mapa no escribe nada.
static func opcion(clave: String) -> bool:
	if not load("res://modo3d.gd").activo() or not FileAccess.file_exists(AJUSTES):
		return false
	var c := ConfigFile.new()
	if c.load(AJUSTES) != OK:
		return false
	var v = c.get_value(SECCION, clave, false)
	return v is bool and v


# Pone (o quita) [mapa] <clave> = true en user://ajustes.cfg sin tocar lo demás (el volumen de sonido.gd). Para un
# botón de ajustes de la versión experimental o para las pruebas: el juego no lo llama solo. Un archivo que no se
# entiende no se pisa (devuelve su error).
static func elegir(clave: String, si: bool) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		var err := c.load(AJUSTES)
		if err != OK:
			return err
	if si:
		c.set_value(SECCION, clave, true)
	elif c.has_section_key(SECCION, clave):
		c.erase_section_key(SECCION, clave)
	else:
		return OK                                  # nada que cambiar: no se escribe
	return c.save(AJUSTES)


# ---------------------------------------------------------------- dibujo

# La máscara del juego, ya hecha (mapa_zonas.png); si falta, la de siempre (y con ella el dibujo antiguo).
func _generar_terreno() -> void:
	if arte_activo():
		var r = load(ARTE + "mapa_zonas.png")            # importada como Image (datos, sin pasar por la GPU)
		var img: Image = r if r is Image else (r.get_image() if r is Texture2D else null)
		if img != null and img.get_size() == Vector2i(int(MAPA_TAM.x / 2), int(MAPA_TAM.y / 2)):
			img = img.duplicate()
			img.convert(Image.FORMAT_RGBA8)
			zonas_img = img
			return
		arte = false                                     # sin máscara válida, todo el mapa de siempre
	super._generar_terreno()


func _crear_mapa() -> void:
	if not arte_activo():
		super._crear_mapa()
		return
	var fondo := Sprite2D.new()
	fondo.texture = load(ARTE + "mapa_mundo.webp")
	fondo.centered = false
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if agua_viva:
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

	rotulos = Node2D.new()
	rotulos.z_index = 1                               # por encima de Kael (y por debajo del prólogo y la interfaz)
	add_child(rotulos)
	rotulos.draw.connect(func(): _dibujar_estrellas(rotulos))
	var Estilo = load("res://estilo.gd")
	for i in lugares.size():
		var l: Dictionary = lugares[i]
		var ciudad: bool = l["tipo"] == "ciudad"
		var et := Label.new()
		et.text = l["nombre"]
		et.size = ROTULO_TAM
		et.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		et.add_theme_font_override("font", Estilo.normal())
		et.add_theme_font_size_override("font_size", ROTULO_LETRA_CIUDAD if ciudad else ROTULO_LETRA)
		et.add_theme_color_override("font_color", ORO_CLARO if ciudad else MARFIL)
		et.add_theme_color_override("font_outline_color", Color(TINTA, 0.92))
		et.add_theme_constant_override("outline_size", ROTULO_BORDE)
		et.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		et.add_theme_constant_override("shadow_offset_x", 0)
		et.add_theme_constant_override("shadow_offset_y", 3)
		et.add_theme_constant_override("shadow_outline_size", 8)
		et.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sitio: Array = ROTULO_SITIO.get(l["nombre"], ["arriba", Vector2.ZERO])
		et.horizontal_alignment = {"izquierda": HORIZONTAL_ALIGNMENT_RIGHT,
			"derecha": HORIZONTAL_ALIGNMENT_LEFT}.get(sitio[0], HORIZONTAL_ALIGNMENT_CENTER)
		et.position = _caja_rotulo(i, sitio[0]) + sitio[1]
		et.set_meta("lugar", i)
		rotulos.add_child(et)

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
		rotulos.add_child(rl)


# Esquina de arriba a la izquierda de la caja del rótulo del lugar i (sin el desplazamiento de ROTULO_SITIO): encima
# del icono, debajo de la imagen del icono o a un lado (pegado al borde de la imagen, a media altura del dibujo).
func _caja_rotulo(i: int, sitio: String) -> Vector2:
	var r := rect_icono(i)
	var cx := r.get_center().x
	var medio := r.position.y + r.size.y * 0.58 - ROTULO_TAM.y * 0.5
	match sitio:
		"abajo":
			return Vector2(cx - ROTULO_TAM.x * 0.5, r.end.y + 2.0)
		"izquierda":
			return Vector2(r.position.x - ROTULO_TAM.x, medio)
		"derecha":
			return Vector2(r.end.x, medio)
	return Vector2(cx - ROTULO_TAM.x * 0.5, r.position.y - 30.0)


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
			n.draw_texture_rect(iconos[i], rect_icono(i), false)


# Las dos estrellas de la marca a los lados del nombre de cada ciudad.
func _dibujar_estrellas(n: Node2D) -> void:
	for et in n.get_children():
		if not et.has_meta("lugar") or lugares[et.get_meta("lugar")]["tipo"] != "ciudad":
			continue
		var r := rect_rotulo(et)                         # con el contorno: 4 px más a cada lado que la letra
		var yr := r.get_center().y
		for x in [r.position.x - 10.0, r.end.x + 10.0]:
			_estrella(n, Vector2(x, yr), 7.0, Color(TINTA, 0.8))
			_estrella(n, Vector2(x, yr), 5.5, ORO_CLARO)


# Rectángulo del icono del lugar i en el mundo (la imagen entera, márgenes transparentes incluidos): la base del
# dibujo, ICONO_BAJO px por debajo del lugar (con el ajuste de ICONO_AJUSTE, si lo tiene).
func rect_icono(i: int) -> Rect2:
	var l: Dictionary = lugares[i]
	var e := _escala(l)
	var tam: Vector2 = Vector2(iconos[i].get_size()) * e if iconos.has(i) else Vector2(112, 104) * e
	var desplaza: Vector2 = ICONO_AJUSTE[l["nombre"]][0] if ICONO_AJUSTE.has(l["nombre"]) else Vector2.ZERO
	return Rect2(l["pos"] + desplaza + Vector2(0, ICONO_BAJO) - ICONO_ANCLA * e, tam)


# Rectángulo que ocupa de verdad el texto de un rótulo (con su contorno), en el mundo. Lo usan las estrellas de las
# ciudades y la prueba de que ningún rótulo pisa a otro ni a un icono.
func rect_rotulo(et: Label) -> Rect2:
	var f: Font = et.get_theme_font("font")
	var tam: int = et.get_theme_font_size("font_size")
	var w := f.get_string_size(et.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var h := f.get_height(tam)
	var x := et.position.x + (et.size.x - w) * 0.5
	if et.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = et.position.x + et.size.x - w
	elif et.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT:
		x = et.position.x
	var b := ROTULO_BORDE * 0.5
	return Rect2(x - b, et.position.y + (et.size.y - h) * 0.5 - b, w + 2.0 * b, h + 2.0 * b)


static func _escala(l: Dictionary) -> float:
	if ICONO_AJUSTE.has(l["nombre"]):
		return ICONO_AJUSTE[l["nombre"]][1]
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
