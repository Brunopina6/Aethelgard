extends Control
# Menú de combate minimalista de Aethelgard (Godot 4.x). Lo crea combate.gd.
# Sin ventanas: texto sobre un degradado oscuro y transparente que sale del borde derecho (el 40 %
# derecho de la pantalla), así el combate se sigue viendo detrás.
#   Arriba: nombre del héroe en cursiva grande con una línea fina de su color.
#   Debajo: las órdenes en mayúsculas espaciadas (la elegida, blanca, más grande y con un guion).
#   Abajo: el grupo, en columnas con su etiqueta encima (T-099): nombre, estados, PV, PM (cifra y barra azul) y la
#   barra ATB fina que brilla al llenarse. A la izquierda, la Armonía y si se puede invocar (o por qué no).
# Los submenús (magias y objetos) salen en el mismo sitio que las órdenes; tocar «‹ Kael» vuelve.
# Se maneja con el dedo (tocar; deslizar sobre ATACAR para girar a DEFENDER), con el ratón o con
# teclado / mando (flechas + Intro). Las filas apagadas también se eligen (con ↑ ↓ o tocándolas): dicen por qué están
# apagadas (T-100) y Intro / A o soltar el dedo sobre ellas solo suena a error.

signal atras

const Artes := preload("res://artes.gd")       # iconos de las familias nuevas y de los estados (T-091)

# Paleta de la Biblia de arte
const SOMBRA := Color("0B1220")
const ORO := Color("E8C46A")
const LUZ_CLARA := Color("F4EAD2")
const BRASA := Color("FF7A3C")
const GRIS := Color(0.62, 0.64, 0.7)
const GRIS_APAGADO := Color(0.4, 0.42, 0.48)
const COLOR_HEROE := {"Kael": Color("8FD3FF"), "Lya": Color("E8C46A"), "Garon": Color("9E2B2B"), "Nyx": Color("8E5BD8")}
const COLOR_ELEMENTO := {"Fuego": Color("FF7A3C"), "Agua": Color("3B8FD8"), "Rayo": Color("F2E36B"),
	"Cura": Color("8FF0B0"), "Hielo": Color("8FD3FF")}
# PM (T-099): azul, distinto del celeste de Kael (que es el de su barra ATB llena). Los mismos que estilo.gd (PM y
# PM_CLARO); aquí van copiados como el resto de la paleta, porque estilo.gd precarga este archivo.
const PM_AZUL := Color("4D8EF0")
const PM_CLARO := Color("A4C6FF")

# Tamaños sobre la pantalla del juego (1280×720). En un móvil apaisado 1 px ≈ 0,57 dp: las filas
# que se tocan miden 72 px (≈ 41 dp) o 64 px en los submenús.
const X_MENU := 768.0
const X_TEXTO := 820.0
const X_DERECHA := 1240.0
const Y_NOMBRE := 52.0
const Y_FILAS := 160.0
const FILA := 72.0
const FILA_SUB := 64.0
const TAM_NOMBRE := 60
const TAM_ELEGIDA := 45
const TAM_ORDEN := 38
const TAM_SUB := 36
const TAM_SUB_MIN := 26          # un nombre largo (Cólera del Cielo, Lumbre de Retorno) no baja de aquí
const HUECO_COSTE := 14.0        # entre el nombre y el coste de la derecha
const TAM_DESC := 24
const TAM_GRUPO := 28
const TAM_ARMONIA := 22
const MARGEN_TOQUE := 30.0
const Y_GRUPO := 596.0
const FILA_GRUPO := 46.0         # de un héroe al siguiente en el bloque del grupo
const DESLIZ_CARTA := 40.0       # px que hay que deslizar el dedo para girar ATACAR / DEFENDER
# Columnas del grupo (T-099), de izquierda a derecha: nombre (X_TEXTO), estados (detrás del nombre), PV (cifra alineada
# a la derecha en X_PV), PM (cifra alineada en X_PM y, debajo, su barra azul de ANCHO_PM) y ATB (de X_ATB a X_DERECHA).
# Caben «Garon» con tres estados, «222/222» y «120/134» (medido con estas fuentes el 09/11).
const X_PV := 1040.0
const X_PM := 1126.0
const ANCHO_PM := 72.0
const X_ATB := 1144.0
const TAM_PM := 24
const TAM_ETIQUETA := 19         # PV · PM · ATB encima de las columnas, y el estado de la Armonía
const TAM_MOTIVO := 23           # por qué una orden está apagada (a la derecha de su fila)
const PASO_ESTADO := 20.0        # de un icono de estado al siguiente (el Aliento, más: lleva sus turnos)

const FUENTE_NOMBRE := "res://fuentes/Cormorant-Italic.ttf"
const FUENTE_ORDEN := "res://fuentes/SairaCondensed-Light.ttf"
const FUENTE_ORDEN_FUERTE := "res://fuentes/SairaCondensed-Medium.ttf"

var f_nombre: Font
var f_orden: Font
var f_fuerte: Font
var f_orden_junta: Font          # las mismas con menos espacio entre letras: nombres largos de los submenús
var f_fuerte_junta: Font
var f_numero: Font               # condensada sin espacio extra (PV, números flotantes)
var f_etiqueta: Font             # condensada con algo de espacio: etiquetas PV · PM · ATB y el estado de la Armonía
var glow_tex: GradientTexture2D
var mat_aditivo: CanvasItemMaterial

var bloque: Control              # cabecera + filas + descripción (lo que entra deslizándose)
var cab: Control
var lbl_nombre: Label
var lbl_pm: Label
var linea: ColorRect
var capa_filas: Control
var desc: Label
var filas: Array = []            # [{nodo, lbl, item, ...}]
var sel := -1
var submenu_abierto := false
var activo := false
var heroe_actual: Dictionary = {}
var carta_lado := {}             # última opción de cada héroe: "a" (ATACAR) o "b" (DEFENDER)
var grupo: Array = []            # [{heroe, nombre, pv, pm, pm_relleno, pm_rastro, fondo, relleno, brillo...}]
var etiquetas_grupo: Array = []  # PV · PM · ATB encima de las columnas
var armonia_lbl: Label
var armonia_relleno: ColorRect
var armonia_brillo: TextureRect
var armonia_valor := 0.0
var armonia_estado: Label        # junto a «ARMONÍA»: «45 %», «INVOCACIÓN LISTA» o por qué no se puede (T-101)
var invocacion_lista := false
var sonidos := {}
var reproductores: Array = []
var _rep := 0
var _pulsado := -1
var _desde := Vector2.ZERO


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	f_nombre = fuente(FUENTE_NOMBRE, 0, 600)
	f_orden = fuente(FUENTE_ORDEN, 6, 0)
	f_fuerte = fuente(FUENTE_ORDEN_FUERTE, 6, 0)
	f_orden_junta = fuente(FUENTE_ORDEN, 2, 0)
	f_fuerte_junta = fuente(FUENTE_ORDEN_FUERTE, 2, 0)
	f_numero = fuente(FUENTE_ORDEN_FUERTE, 1, 0)
	f_etiqueta = fuente(FUENTE_ORDEN_FUERTE, 3, 0)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	glow_tex = GradientTexture2D.new()
	glow_tex.gradient = g
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	mat_aditivo = CanvasItemMaterial.new()
	mat_aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# degradado oscuro desde el borde derecho
	var gd := Gradient.new()
	gd.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	var s := SOMBRA
	gd.colors = PackedColorArray([Color(s, 0.0), Color(s, 0.55), Color(s, 0.86)])
	var tex := GradientTexture2D.new()
	tex.gradient = gd
	tex.width = 256
	tex.height = 4
	var fondo := TextureRect.new()
	fondo.texture = tex
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.position = Vector2(600, 0)
	fondo.size = Vector2(680, 720)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var zona := Control.new()                       # los toques en huecos del menú no hacen nada
	zona.position = Vector2(X_MENU, 0)
	zona.size = Vector2(1280 - X_MENU, 720)
	zona.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(zona)

	bloque = Control.new()
	bloque.size = size
	bloque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bloque)
	cab = Control.new()                             # nombre del héroe («‹ Kael» en los submenús)
	cab.position = Vector2(X_TEXTO - MARGEN_TOQUE, Y_NOMBRE - 10)
	cab.size = Vector2(X_DERECHA - X_TEXTO + MARGEN_TOQUE, 96)
	cab.gui_input.connect(_toque_cabecera)
	bloque.add_child(cab)
	lbl_nombre = _etiqueta("", f_nombre, TAM_NOMBRE, LUZ_CLARA)
	lbl_nombre.position = Vector2(MARGEN_TOQUE, 0)
	cab.add_child(lbl_nombre)
	lbl_pm = _etiqueta("", f_orden, 24, GRIS)
	lbl_pm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_pm.size = Vector2(200, 40)
	lbl_pm.position = Vector2(cab.size.x - 200, 34)
	cab.add_child(lbl_pm)
	linea = ColorRect.new()
	linea.position = Vector2(MARGEN_TOQUE, 82)
	linea.size = Vector2(260, 2)
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cab.add_child(linea)
	capa_filas = Control.new()
	capa_filas.size = size
	capa_filas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloque.add_child(capa_filas)
	desc = _etiqueta("", f_nombre, TAM_DESC + 4, GRIS)
	desc.position = Vector2(X_TEXTO, 0)
	desc.size = Vector2(X_DERECHA - X_TEXTO, 64)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bloque.add_child(desc)
	bloque.visible = false

	# Armonía de Lya (abajo a la izquierda)
	var sombra_izq := _brillo(SOMBRA, Vector2(520, 200))   # oscurece un poco la esquina para que se lea
	sombra_izq.material = null
	sombra_izq.modulate = Color(SOMBRA, 0.55)
	sombra_izq.position = Vector2(-160, 600)
	add_child(sombra_izq)
	armonia_lbl = _etiqueta("ARMONÍA", f_fuerte, TAM_ARMONIA, ORO)
	armonia_lbl.position = Vector2(40, 652)
	add_child(armonia_lbl)
	var af := ColorRect.new()
	af.color = Color(LUZ_CLARA, 0.3)
	af.position = Vector2(40, 690)
	af.size = Vector2(260, 3)
	af.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(af)
	armonia_brillo = _brillo(ORO, Vector2(300, 28))
	armonia_brillo.position = Vector2(20, 677)
	armonia_brillo.visible = false
	add_child(armonia_brillo)
	armonia_relleno = ColorRect.new()
	armonia_relleno.color = ORO
	armonia_relleno.position = af.position
	armonia_relleno.size = Vector2(0, 3)
	armonia_relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(armonia_relleno)
	# Érebo en el HUD (T-101): detrás de «ARMONÍA», cuánto falta o si ya se puede invocar (y si no, por qué). Solo lo
	# explica: las reglas de la Armonía y de la invocación siguen en combate.gd.
	armonia_estado = _etiqueta("", f_etiqueta, TAM_ETIQUETA + 1, GRIS)
	armonia_estado.position = Vector2(40.0 + f_fuerte.get_string_size("ARMONÍA", HORIZONTAL_ALIGNMENT_LEFT, -1,
		TAM_ARMONIA).x + 14.0, 655)
	add_child(armonia_estado)

	_crear_sonidos()


# ================================================================= construir

# Fuente con espacio extra entre letras y peso (las variables, como Cormorant). También la usa carga.gd.
static func fuente(ruta: String, espacio: int, peso: int) -> Font:
	var base: Font = ThemeDB.fallback_font
	if ResourceLoader.exists(ruta):
		base = load(ruta)
	var v := FontVariation.new()
	v.base_font = base
	v.spacing_glyph = espacio
	if peso > 0:
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): peso}
	return v


func _etiqueta(texto: String, fuente: Font, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(SOMBRA, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _brillo(color: Color, tam: Vector2) -> TextureRect:
	var b := TextureRect.new()
	b.texture = glow_tex
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_SCALE
	b.size = tam
	b.material = mat_aditivo
	b.modulate = Color(color, 0.7)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


# Grupo de abajo (T-099), una fila por héroe presente: nombre, estados, PV, PM con su barra azul y la barra ATB fina.
# Encima de las columnas, sus etiquetas (PV · PM · ATB), para leerlas de un vistazo en el móvil. Se ve todo el combate:
# también con el turno de un enemigo y con el menú cerrado.
func preparar(heroes: Array) -> void:
	var y0 := minf(Y_GRUPO, 700.0 - heroes.size() * FILA_GRUPO)   # con tres héroes, el grupo sube un poco
	_etiquetas_columnas(y0 - 25.0)
	for i in heroes.size():
		var h: Dictionary = heroes[i]
		var y := y0 + i * FILA_GRUPO
		var c: Color = COLOR_HEROE.get(h["nombre"], LUZ_CLARA)
		var n := _etiqueta(h["nombre"], f_nombre, TAM_GRUPO + 4, LUZ_CLARA)
		n.position = Vector2(X_TEXTO, y - 4)
		n.pivot_offset = Vector2(0, 24)
		add_child(n)
		var est := Control.new()                    # iconos de estado (artes.gd): coraza, Aliento y Brasa
		var ancho_nombre := f_nombre.get_string_size(h["nombre"], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_GRUPO + 4).x
		est.position = Vector2(X_TEXTO + ancho_nombre + 8.0, y + 6)   # detrás del nombre, antes de los PV
		est.size = Vector2(maxf(18.0, X_PV - 86.0 - est.position.x), 18)
		est.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var quien: Dictionary = h
		est.draw.connect(_dibujar_estados.bind(est, quien))
		add_child(est)
		var pv := _etiqueta("", f_numero, TAM_GRUPO, LUZ_CLARA)
		pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pv.size = Vector2(150, 40)
		pv.position = Vector2(X_PV - 150, y)
		add_child(pv)
		# PM: la cifra y, debajo, la barra azul (con un rastro claro de lo que se acaba de gastar)
		var pm := _etiqueta("", f_numero, TAM_PM, PM_CLARO)
		pm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pm.size = Vector2(110, 32)
		pm.position = Vector2(X_PM - 110, y - 1)
		add_child(pm)
		var pm_fondo := _rect(Vector2(X_PM - ANCHO_PM, y + 33), Vector2(ANCHO_PM, 5), Color(PM_AZUL, 0.24))
		var pm_rastro := _rect(pm_fondo.position, Vector2(0, 5), Color(PM_CLARO, 0.8))
		var pm_relleno := _rect(pm_fondo.position, Vector2(0, 5), PM_AZUL)
		# ATB
		var fondo := _rect(Vector2(X_ATB, y + 22), Vector2(X_DERECHA - X_ATB, 3), Color(LUZ_CLARA, 0.16))
		var brillo := _brillo(c, Vector2(fondo.size.x + 40, 26))
		brillo.position = fondo.position + Vector2(-20, -11)
		brillo.visible = false
		add_child(brillo)
		var relleno := _rect(fondo.position, Vector2(0, 3), Color(LUZ_CLARA, 0.55))
		var destello := _brillo(c, Vector2(X_DERECHA - X_TEXTO + 60, 54))   # destacar_heroe (la Lumbre: quién vuelve)
		destello.position = Vector2(X_TEXTO - 40, y - 8)
		destello.modulate.a = 0.0
		destello.visible = false
		add_child(destello)
		move_child(destello, n.get_index())          # detrás del nombre
		var pm_ini := _fraccion_pm(h)
		grupo.append({"heroe": h, "nombre": n, "pv": pv, "fondo": fondo, "relleno": relleno, "brillo": brillo, "color": c,
			"estados": est, "firma": "", "pm": pm, "pm_fondo": pm_fondo, "pm_relleno": pm_relleno, "pm_rastro": pm_rastro,
			"pm_meta": pm_ini, "pm_ver": pm_ini, "pm_rastro_v": pm_ini, "pm_espera": 0.0, "destello": destello,
			"colores": {}})
		pm_relleno.size.x = ANCHO_PM * pm_ini
	actualizar_grupo(null)


func _rect(pos: Vector2, tam: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = tam
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


# Las etiquetas de las columnas, una vez, encima del primer héroe: PV y PM alineadas con sus cifras (a la derecha) y
# ATB al principio de su barra. Cada una del color de lo que nombra.
func _etiquetas_columnas(y: float) -> void:
	for d in [["PV", X_PV, Color(LUZ_CLARA, 0.72), true], ["PM", X_PM, PM_CLARO, true], ["ATB", X_ATB, Color(LUZ_CLARA, 0.72), false]]:
		var l := _etiqueta(d[0], f_etiqueta, TAM_ETIQUETA, d[2])
		l.size = Vector2(80, 24)
		if d[3]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.position = Vector2(float(d[1]) - 80.0 + 3.0, y)   # +3: el espacio que la fuente deja detrás de la última letra
		else:
			l.position = Vector2(float(d[1]), y)
		add_child(l)
		etiquetas_grupo.append(l)


# Los iconos de estado de un héroe (artes.gd) y, junto a la hoja del Aliento, los turnos que le quedan (T-100).
func _dibujar_estados(est: Control, quien: Dictionary) -> void:
	var x := 0.0
	for e in Artes.estados_de(quien):
		est.draw_set_transform(Vector2(x, 0))
		Artes.dibujar_estado(est, e, Vector2(18, 18))
		x += PASO_ESTADO
		var texto := Artes.texto_estado(quien, e)
		if texto != "":
			est.draw_set_transform(Vector2.ZERO)
			est.draw_string_outline(f_numero, Vector2(x - 3.0, 18), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color(SOMBRA, 0.9))
			est.draw_string(f_numero, Vector2(x - 3.0, 18), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Artes.COLOR_ESTADO.get(e, LUZ_CLARA))
			x += f_numero.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 2.0
	est.draw_set_transform(Vector2.ZERO)


static func _fraccion_pm(h: Dictionary) -> float:
	var maximo := int(h.get("mp_max", 0))
	return 0.0 if maximo <= 0 else clampf(float(h.get("mp", 0)) / maximo, 0.0, 1.0)


# Cambia un color de tema solo si es otro (se llama en cada fotograma).
func _color(g: Dictionary, clave: String, l: Label, c: Color) -> void:
	if g["colores"].get(clave, Color(0, 0, 0, 0)) != c:
		g["colores"][clave] = c
		l.add_theme_color_override("font_color", c)


# Con los valores de verdad de cada héroe (combate.gd lo llama en cada fotograma): PV, PM (también si cambia el máximo:
# al subir de nivel), ATB y estados. La cifra cambia al momento; la barra de PM baja de golpe dejando un rastro claro que
# se va, o sube en un momento (Éter, la Gota).
func actualizar_grupo(actor) -> void:
	for g in grupo:
		var h: Dictionary = g["heroe"]
		var vivo: bool = h["hp"] > 0
		g["pv"].text = "%d/%d" % [h["hp"], h["hp_max"]]
		var cpv := LUZ_CLARA
		if not vivo:
			cpv = GRIS_APAGADO
		elif h["hp"] < h["hp_max"] * 0.3:
			cpv = BRASA
		_color(g, "pv", g["pv"], cpv)
		_color(g, "nombre", g["nombre"], g["color"] if actor != null and h == actor else (LUZ_CLARA if vivo else GRIS_APAGADO))
		# PM
		g["pm"].text = "%d/%d" % [int(h.get("mp", 0)), int(h.get("mp_max", 0))]
		var cpm := PM_CLARO
		if not vivo:
			cpm = GRIS_APAGADO
		elif int(h.get("mp", 0)) <= 0:
			cpm = Color(PM_CLARO, 0.5)                # sin PM: la cifra se apaga un poco (la barra, vacía)
		_color(g, "pm", g["pm"], cpm)
		var meta := _fraccion_pm(h)
		if meta < g["pm_meta"] - 0.0001:             # gasta: la barra baja ya y deja el rastro de lo gastado
			g["pm_rastro_v"] = maxf(g["pm_rastro_v"], g["pm_ver"])
			g["pm_ver"] = meta
			g["pm_espera"] = 0.25
		g["pm_meta"] = meta
		g["pm_relleno"].color = PM_AZUL if vivo else Color(GRIS_APAGADO, 0.7)
		# ATB (un caído no avanza: su barra se ve apagada)
		var lleno: bool = vivo and h["atb"] >= 100.0
		g["relleno"].size.x = g["fondo"].size.x * clampf(h["atb"] / 100.0, 0.0, 1.0)
		g["relleno"].color = g["color"] if lleno else (Color(LUZ_CLARA, 0.55) if vivo else Color(GRIS_APAGADO, 0.35))
		g["brillo"].visible = lleno
		var firma := str(Artes.estados_de(h)) + str(h.get("aliento", 0))   # los iconos, solo si cambian (o si cae)
		if g["firma"] != firma:
			g["firma"] = firma
			g["estados"].queue_redraw()
	if not heroe_actual.is_empty():
		lbl_pm.text = "PM %d/%d" % [heroe_actual["mp"], heroe_actual["mp_max"]]


# La barra de PM sigue a su valor: sube en 0,3 s; al bajar, el rastro espera un momento y se recoge.
func _mover_pm(g: Dictionary, delta: float) -> void:
	var meta: float = g["pm_meta"]
	if g["pm_ver"] < meta:
		g["pm_ver"] = minf(meta, g["pm_ver"] + delta * 3.0)
	if g["pm_espera"] > 0.0:
		g["pm_espera"] -= delta
	else:
		g["pm_rastro_v"] = move_toward(g["pm_rastro_v"], g["pm_ver"], delta * 2.4)
	g["pm_rastro_v"] = maxf(g["pm_rastro_v"], g["pm_ver"])
	g["pm_relleno"].size.x = ANCHO_PM * g["pm_ver"]
	g["pm_rastro"].size.x = ANCHO_PM * g["pm_rastro_v"]


# Ilumina la fila de un héroe (por ejemplo, quien vuelve con la Lumbre de Retorno): un brillo detrás de su nombre, que
# además crece un momento.
func destacar_heroe(h: Dictionary, color: Color) -> void:
	for g in grupo:
		if not is_same(g["heroe"], h):
			continue
		var d: TextureRect = g["destello"]
		d.modulate = Color(color, 0.0)
		d.visible = true
		var t := create_tween()
		t.tween_property(d, "modulate:a", 0.85, 0.25)
		t.tween_property(d, "modulate:a", 0.0, 1.3).set_delay(0.5)
		t.tween_callback(func(): d.visible = false)
		var n: Label = g["nombre"]
		var tn := create_tween()
		tn.tween_property(n, "scale", Vector2(1.18, 1.18), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tn.tween_property(n, "scale", Vector2.ONE, 0.5).set_delay(0.6)


# v de 0 a 1. Llena: la barra brilla.
func poner_armonia(v: float) -> void:
	armonia_valor = clampf(v, 0.0, 1.0)
	create_tween().tween_property(armonia_relleno, "size:x", 260.0 * armonia_valor, 0.35)
	armonia_brillo.visible = armonia_valor >= 1.0


# Érebo en el HUD (T-101): lo calcula combate.gd (_estado_invocacion) con sus reglas de siempre. «lista»: se puede
# invocar ya; «hud»: lo que se lee junto a «ARMONÍA» («45 %», «INVOCACIÓN LISTA», «LYA HA CAÍDO»).
func poner_invocacion(e: Dictionary) -> void:
	invocacion_lista = bool(e.get("lista", false))
	var texto := str(e.get("hud", ""))
	if armonia_estado.text != texto:
		armonia_estado.text = texto
	if not invocacion_lista:                         # (lista, el color late en _process)
		var c: Color = Color(BRASA, 0.85) if e.get("caida", false) else GRIS
		if armonia_estado.get_theme_color("font_color") != c:
			armonia_estado.add_theme_color_override("font_color", c)


# ================================================================= abrir / cerrar

# Órdenes del héroe. Cada item: {"texto", "accion": Callable, "apagado": bool}
#   tipo "carta": dos caras, {"texto", "accion"} y {"texto_b", "accion_b"} (ATACAR ⇄ DEFENDER)
#   tipo "invocacion": apagada hasta que la Armonía se llena; llena, late en dorado.
func abrir(heroe: Dictionary, items: Array) -> void:
	var entra := not bloque.visible or heroe_actual != heroe
	heroe_actual = heroe
	submenu_abierto = false
	_cabecera(heroe["nombre"])
	_construir(items, FILA)
	desc.visible = false
	activo = true
	bloque.visible = true
	if entra:
		_entrar()
	else:
		_fundido()


# Submenú en el sitio de las órdenes. Items: {"texto", "accion", "apagado", "icono" (elemento o
# Texture2D), "derecha" (coste o cantidad), "desc"}. Pestañas opcionales arriba: [{"texto", "accion"}].
func submenu(items: Array, pestanas: Array = [], pestana := 0) -> void:
	submenu_abierto = true
	_cabecera("‹ " + heroe_actual["nombre"])
	_construir(items, FILA_SUB, pestanas, pestana)
	desc.visible = true
	activo = true
	bloque.visible = true
	_fundido()


# Mientras se elige objetivo: cabecera «‹ Kael» y un aviso en gris.
func aviso(texto: String) -> void:
	submenu_abierto = true
	_cabecera("‹ " + heroe_actual["nombre"])
	_construir([{"texto": texto, "aviso": true, "apagado": true}], FILA_SUB)
	desc.visible = false
	activo = false
	bloque.visible = true


func cerrar() -> void:
	activo = false
	if not bloque.visible:
		return
	var t := create_tween()
	t.tween_property(bloque, "modulate:a", 0.0, 0.15)
	t.tween_callback(func():
		bloque.visible = false
		bloque.modulate.a = 1.0)
	heroe_actual = {}


func _cabecera(texto: String) -> void:
	lbl_nombre.text = texto
	var c: Color = COLOR_HEROE.get(heroe_actual.get("nombre", ""), LUZ_CLARA)
	linea.color = Color(c, 0.85)
	lbl_pm.text = "PM %d/%d" % [heroe_actual["mp"], heroe_actual["mp_max"]] if heroe_actual.has("mp") else ""


func _construir(items: Array, alto: float, pestanas: Array = [], pestana := 0) -> void:
	for f in filas:
		f["nodo"].queue_free()
	for hijo in capa_filas.get_children():
		hijo.queue_free()
	filas.clear()
	sel = -1
	_pestanas = pestanas
	_pestana = pestana
	var y := Y_FILAS
	if not pestanas.is_empty():                     # pestañas I · II · III de las magias
		var x := X_TEXTO - 12.0                     # I · II · III miden 96 px; las de familia (artes.gd), 64 y su icono
		for i in pestanas.size():
			var p: Dictionary = pestanas[i]
			var ancho := float(p.get("ancho", 96.0))
			var nodo := Control.new()
			nodo.position = Vector2(x, y)            # sin artes, las mismas x de siempre (808, 908 y 1008)
			nodo.size = Vector2(ancho, FILA_SUB)
			nodo.gui_input.connect(_toque_pestana.bind(p))
			capa_filas.add_child(nodo)
			x += ancho + 4.0
			var l := _etiqueta(p["texto"], f_fuerte if i == pestana else f_orden, TAM_SUB, LUZ_CLARA if i == pestana else GRIS)
			l.size = nodo.size
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nodo.add_child(l)
			if p.has("icono"):                      # pestaña de una familia nueva: su icono, más vivo si está elegida
				var ic := Control.new()
				ic.position = (nodo.size - Vector2(34, 34)) * 0.5
				ic.size = Vector2(34, 34)
				ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ic.modulate = Color(1, 1, 1, 1.0 if i == pestana else 0.55)
				ic.draw.connect(_dibujar_icono.bind(ic, p["icono"]))
				nodo.add_child(ic)
			if i == pestana:
				var raya := ColorRect.new()
				raya.color = Color(ORO, 0.9)
				raya.position = Vector2((nodo.size.x - 36.0) * 0.5, FILA_SUB - 10)   # centrada (con 96 px, x = 30)
				raya.size = Vector2(36, 2)
				raya.mouse_filter = Control.MOUSE_FILTER_IGNORE
				nodo.add_child(raya)
		y += FILA_SUB
	for i in items.size():
		var it: Dictionary = items[i]
		var nodo := Control.new()
		nodo.position = Vector2(X_TEXTO - MARGEN_TOQUE, y)
		nodo.size = Vector2(X_DERECHA - X_TEXTO + MARGEN_TOQUE * 2.0, alto)
		nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE if it.get("aviso", false) else Control.MOUSE_FILTER_STOP
		nodo.gui_input.connect(_toque_fila.bind(i))
		nodo.mouse_entered.connect(func(): if _pulsado < 0 and DisplayServer.mouse_get_button_state() == 0: _elegir(i, true))
		capa_filas.add_child(nodo)
		var f := {"nodo": nodo, "item": it, "alto": alto}
		var x_texto := MARGEN_TOQUE
		if it.has("icono"):
			var ic := Control.new()
			ic.position = Vector2(MARGEN_TOQUE, (alto - 34) * 0.5)
			ic.size = Vector2(34, 34)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic.draw.connect(_dibujar_icono.bind(ic, it["icono"]))
			nodo.add_child(ic)
			f["icono"] = ic
			x_texto += 52.0
		var l := _etiqueta("", f_orden, TAM_ORDEN, GRIS)
		l.position = Vector2(x_texto, 0)
		l.size = Vector2(nodo.size.x - x_texto, alto)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.pivot_offset = Vector2(60, alto * 0.5)
		nodo.add_child(l)
		f["lbl"] = l
		if it.has("derecha"):
			var r := _etiqueta(str(it["derecha"]), f_orden, TAM_SUB - 6, GRIS)
			r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			r.size = Vector2(160, alto)
			r.position = Vector2(nodo.size.x - MARGEN_TOQUE - 160, 0)
			nodo.add_child(r)
			f["der"] = r
		if alto != FILA and not it.get("aviso", false):
			_ajustar_nombre(f, str(it["texto"]), x_texto, str(it.get("derecha", "")))
		if alto == FILA and it.get("apagado", false) and str(it.get("motivo", "")) != "":
			# orden apagada: por qué, a la derecha de su fila y siempre a la vista (sin elegirla, sin ratón) (T-100)
			var mo := _etiqueta(str(it["motivo"]), f_nombre, TAM_MOTIVO, GRIS)
			mo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			mo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mo.size = Vector2(300, alto)
			mo.position = Vector2(nodo.size.x - MARGEN_TOQUE - 300, 3)
			nodo.add_child(mo)
			f["motivo"] = mo
		if it.get("tipo", "") == "carta":            # flechas ◂ ▸ con zona de toque grande
			var lado: String = carta_lado.get(heroe_actual.get("nombre", ""), "a")
			f["lado"] = lado
			for k in 2:
				var fl := Control.new()
				fl.size = Vector2(44 + MARGEN_TOQUE, alto)
				fl.position = Vector2(nodo.size.x - MARGEN_TOQUE - (2 - k) * 62.0 - 10, 0)
				fl.gui_input.connect(_toque_flecha)
				nodo.add_child(fl)
				var lf := _etiqueta("◂" if k == 0 else "▸", f_orden, 34, GRIS)
				lf.size = fl.size
				lf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lf.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				fl.add_child(lf)
		filas.append(f)
		y += alto
	desc.position.y = y + 8
	var primera := -1
	for i in filas.size():
		if not filas[i]["item"].get("apagado", false):
			primera = i
			break
	if primera < 0:                                  # todas apagadas: la primera, para que se lea su motivo
		for i in filas.size():
			if not filas[i]["item"].get("aviso", false):
				primera = i
				break
	if primera >= 0:
		_elegir(primera, false)
	else:
		desc.text = ""
		_pintar()


# Que el nombre de una fila de submenú no pise su coste («Cólera del Cielo» y «32 PM», o las artes: «Lumbre de Retorno»
# y «14 PM»). Si no cabe con el estilo de siempre, primero se juntan las letras (2 px en vez de 6) y, si aún no cabe, se
# baja el tamaño hasta TAM_SUB_MIN. Los nombres que caben (casi todos) no cambian. Se mide con la fuente de la elegida,
# que es la más ancha.
func _ajustar_nombre(f: Dictionary, texto: String, x_texto: float, derecha: String) -> void:
	var libre: float = f["nodo"].size.x - MARGEN_TOQUE - x_texto
	if derecha != "":
		libre -= f_orden.get_string_size(derecha, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_SUB - 6).x + HUECO_COSTE
	if f_fuerte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_SUB).x <= libre:
		return
	f["junta"] = true
	var tam := TAM_SUB
	while tam > TAM_SUB_MIN and f_fuerte_junta.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > libre:
		tam -= 1
	f["tam"] = tam


# Entrada: las líneas aparecen deslizándose una detrás de otra (menos de medio segundo).
func _entrar() -> void:
	var nodos: Array = [cab]
	for f in filas:
		nodos.append(f["nodo"])
	for i in nodos.size():
		var n: Control = nodos[i]
		var x: float = n.position.x
		n.position.x = x + 60.0
		n.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(n, "position:x", x, 0.22).set_delay(i * 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(n, "modulate:a", 1.0, 0.2).set_delay(i * 0.05)


func _fundido() -> void:
	capa_filas.modulate.a = 0.0
	create_tween().tween_property(capa_filas, "modulate:a", 1.0, 0.12)


# ================================================================= pintar

func _pintar() -> void:
	for i in filas.size():
		var f: Dictionary = filas[i]
		var it: Dictionary = f["item"]
		var elegida := i == sel
		var apagado: bool = it.get("apagado", false)
		var l: Label = f["lbl"]
		var texto: String = it["texto"]
		var color := GRIS
		if it.get("tipo", "") == "carta" and f["lado"] == "b":
			texto = it["texto_b"]
			color = Color(ORO, 0.75)
		if apagado:                                  # apagada; elegida (con ↑ ↓ o el dedo), algo más clara
			color = GRIS_APAGADO.lerp(GRIS, 0.55) if elegida else GRIS_APAGADO
		elif elegida:
			color = ORO if it.get("tipo", "") == "carta" and f["lado"] == "b" else Color.WHITE
		if f.has("motivo"):
			f["motivo"].add_theme_color_override("font_color", Color(LUZ_CLARA, 0.92) if elegida else GRIS)
		if f["alto"] == FILA:                        # órdenes (la apagada elegida lleva el guion, pero no crece)
			l.text = ("— " if elegida else "") + texto
			l.add_theme_font_size_override("font_size", TAM_ELEGIDA if elegida and not apagado else TAM_ORDEN)
			l.add_theme_font_override("font", f_fuerte if elegida and not apagado else f_orden)
		else:                                        # submenús: mismo tamaño, la elegida en blanco (apagada: gris, en
			l.text = texto                           # la letra gruesa de la elegida, para que se vea dónde está)
			l.add_theme_font_size_override("font_size", f.get("tam", TAM_SUB))
			if f.get("junta", false):                # nombre largo: letras más juntas (_ajustar_nombre)
				l.add_theme_font_override("font", f_fuerte_junta if elegida else f_orden_junta)
			else:
				l.add_theme_font_override("font", f_fuerte if elegida else f_orden)
		l.add_theme_color_override("font_color", color)
		if f.has("der"):
			var cder := GRIS_APAGADO if apagado else (LUZ_CLARA if elegida else GRIS)
			if it.get("falta_pm", false):              # no le llegan los PM: el coste, en color de aviso
				cder = Color(BRASA, 0.95 if elegida else 0.75)
			f["der"].add_theme_color_override("font_color", cder)
		if f.has("icono"):
			f["icono"].modulate = Color(1, 1, 1, 0.4 if apagado else (1.0 if elegida else 0.75))
	if sel >= 0 and sel < filas.size():
		desc.text = filas[sel]["item"].get("desc", "")


func _process(d: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in filas.size():                           # la invocación lista late en dorado
		var f: Dictionary = filas[i]
		if f["item"].get("tipo", "") == "invocacion" and not f["item"].get("apagado", false):
			var k := 0.5 + 0.5 * sin(t * 4.0)
			f["lbl"].add_theme_color_override("font_color", ORO.lerp(Color.WHITE, k * 0.6) if i == sel else ORO.lerp(GRIS, 0.3 + 0.3 * k))
			f["lbl"].scale = Vector2.ONE * (1.0 + 0.03 * k)
	for g in grupo:
		if g["brillo"].visible:
			g["brillo"].modulate.a = 0.45 + 0.3 * sin(t * 5.0)
		_mover_pm(g, d)
	if armonia_brillo.visible:
		armonia_brillo.modulate.a = 0.4 + 0.3 * sin(t * 4.0)
		armonia_lbl.add_theme_color_override("font_color", ORO.lerp(Color.WHITE, 0.3 + 0.3 * sin(t * 4.0)))
	else:
		armonia_lbl.add_theme_color_override("font_color", ORO)
	if invocacion_lista:                             # «INVOCACIÓN LISTA» late con la barra
		armonia_estado.add_theme_color_override("font_color", ORO.lerp(Color.WHITE, 0.25 + 0.3 * sin(t * 4.0)))


func _dibujar_icono(c: Control, icono) -> void:
	if icono is Texture2D:
		c.draw_texture_rect(icono, Rect2(Vector2.ZERO, c.size), false)
		return
	if Artes.dibujar_icono(c, str(icono), c.size):  # Alba, Escarcha y Lumbre (artes.gd)
		return
	var col: Color = COLOR_ELEMENTO.get(icono, LUZ_CLARA)
	var m := c.size * 0.5
	match icono:
		"Fuego":                                     # llama
			var pts := PackedVector2Array()
			for i in 25:
				var a := TAU * i / 24.0
				var r := 11.0 * (1.0 + 0.55 * maxf(0.0, -sin(a)) ** 3)
				pts.append(m + Vector2(cos(a) * r * (0.75 + 0.25 * sin(a)), sin(a) * r * 1.15 + 3))
			c.draw_colored_polygon(pts, col)
			c.draw_circle(m + Vector2(0, 6), 4.5, Color(1.0, 0.9, 0.55))
		"Agua":                                      # gota
			var pts := PackedVector2Array([m + Vector2(0, -15)])
			for i in 17:
				var a := PI * i / 16.0
				pts.append(m + Vector2(cos(a) * 10.0, 4.0 + sin(a) * 10.0))
			c.draw_colored_polygon(pts, col)
		"Rayo":                                      # rayo en zigzag
			c.draw_colored_polygon(PackedVector2Array([m + Vector2(3, -16), m + Vector2(-9, 2), m + Vector2(-1, 2),
				m + Vector2(-4, 16), m + Vector2(9, -3), m + Vector2(1, -3)]), col)
		"Cura":                                      # cruz
			c.draw_rect(Rect2(m + Vector2(-4, -13), Vector2(8, 26)), col)
			c.draw_rect(Rect2(m + Vector2(-13, -4), Vector2(26, 8)), col)
		_:
			c.draw_circle(m, 8.0, col)


# ================================================================= manejo

func _elegir(i: int, sonido: bool) -> void:
	if i < 0 or i >= filas.size() or filas[i]["item"].get("aviso", false):
		return
	if i != sel and sonido:
		sonar("tic")
	sel = i
	_pintar()


func _ejecutar(i: int) -> void:
	if i < 0 or i >= filas.size():
		return
	var f: Dictionary = filas[i]
	var it: Dictionary = f["item"]
	if it.get("apagado", false) or not activo:
		if activo and not it.get("aviso", false):
			Sonido.efecto("ui_error")                # una opción apagada: no se puede (sonido.gd)
		return
	sonar("confirmar")
	var accion: Callable = it["accion"]
	if it.get("tipo", "") == "carta" and f["lado"] == "b":
		accion = it["accion_b"]
	accion.call()


# ATACAR ⇄ DEFENDER: la palabra gira como una carta y cambia.
func girar() -> void:
	for i in filas.size():
		var f: Dictionary = filas[i]
		if f["item"].get("tipo", "") != "carta":
			continue
		f["lado"] = "b" if f["lado"] == "a" else "a"
		carta_lado[heroe_actual.get("nombre", "")] = f["lado"]
		sel = i
		sonar("clac")
		vibrar(18)
		var l: Label = f["lbl"]
		var t := create_tween()
		t.tween_property(l, "scale:x", 0.0, 0.08).set_ease(Tween.EASE_IN)
		t.tween_callback(_pintar)
		t.tween_property(l, "scale:x", 1.0, 0.1).set_ease(Tween.EASE_OUT)
		return


func _toque_fila(ev: InputEvent, i: int) -> void:
	if not (ev is InputEventMouseButton) or ev.button_index != MOUSE_BUTTON_LEFT:
		return
	if ev.pressed:
		_pulsado = i
		_desde = ev.global_position
		_elegir(i, true)
	elif _pulsado == i:
		_pulsado = -1
		var dx: float = ev.global_position.x - _desde.x
		if filas[i]["item"].get("tipo", "") == "carta" and absf(dx) > DESLIZ_CARTA:
			girar()
		elif Rect2(Vector2.ZERO, filas[i]["nodo"].size).has_point(ev.position):
			_ejecutar(i)


func _toque_flecha(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		get_viewport().set_input_as_handled()
		girar()


func _toque_pestana(ev: InputEvent, p: Dictionary) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		sonar("tic")
		p["accion"].call()


func _toque_cabecera(ev: InputEvent) -> void:
	if submenu_abierto and ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		sonar("tic")
		atras.emit()


# Pestañas del submenú (I · II · III de las magias): las del último _construir y la activa. Con teclado o mando se
# cambian con Q / E, RePág / AvPág o L1 / R1 (antes solo tocándolas).
var _pestanas: Array = []
var _pestana := 0


func _unhandled_input(ev: InputEvent) -> void:
	if not activo or not bloque.visible or filas.is_empty():
		return
	if (ev.is_action_pressed("pestana_anterior") or ev.is_action_pressed("pestana_siguiente")) and _pestanas.size() > 1:
		var paso := -1 if ev.is_action_pressed("pestana_anterior") else 1
		get_viewport().set_input_as_handled()
		sonar("tic")
		_pestanas[posmod(_pestana + paso, _pestanas.size())]["accion"].call()
		return
	if ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up"):
		var paso := 1 if ev.is_action_pressed("ui_down") else -1
		var i := sel
		for n in filas.size():                       # también las apagadas: así se lee su motivo sin ratón (T-100)
			i = wrapi(i + paso, 0, filas.size())
			if not filas[i]["item"].get("aviso", false):
				break
		_elegir(i, true)
		get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("ui_left") or ev.is_action_pressed("ui_right"):
		if sel >= 0 and filas[sel]["item"].get("tipo", "") == "carta":
			girar()
			get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("ui_accept"):
		_ejecutar(sel)
		get_viewport().set_input_as_handled()


# ================================================================= sonido y vibración

func sonar(nombre: String) -> void:
	if not sonidos.has(nombre):
		return
	var r: AudioStreamPlayer = reproductores[_rep]
	_rep = (_rep + 1) % reproductores.size()
	r.stream = sonidos[nombre]
	r.play()


func vibrar(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _crear_sonidos() -> void:
	sonidos = sonidos_ui()
	for i in 3:
		var r := AudioStreamPlayer.new()
		r.volume_db = -6.0
		r.bus = &"Interfaz"                          # buses y volúmenes: sonido.gd
		add_child(r)
		reproductores.append(r)


# Sonidos hechos por código (no ocupan archivos): «tic» cristalino, tono suave al confirmar y «clac».
static func sonidos_ui() -> Dictionary:
	var hz := 22050
	var tic := PackedFloat32Array()
	for i in int(hz * 0.06):
		var t := float(i) / hz
		tic.append((sin(TAU * 2600.0 * t) + 0.5 * sin(TAU * 3900.0 * t)) * exp(-t * 85.0) * 0.22)
	var ok := PackedFloat32Array()
	for i in int(hz * 0.26):
		var t := float(i) / hz
		var nota := 784.0 if t < 0.09 else 1175.0
		var t0 := t if t < 0.09 else t - 0.09
		var env := minf(1.0, t0 * 120.0) * exp(-t0 * 13.0)
		ok.append((sin(TAU * nota * t) + 0.25 * sin(TAU * nota * 2.0 * t)) * env * 0.2)
	var clac := PackedFloat32Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in int(hz * 0.06):
		var t := float(i) / hz
		clac.append(rng.randf_range(-1.0, 1.0) * exp(-t * 140.0) * 0.35 + sin(TAU * 170.0 * t) * exp(-t * 55.0) * 0.35)
	return {"tic": _wav(tic, hz), "confirmar": _wav(ok, hz), "clac": _wav(clac, hz)}


static func _wav(m: PackedFloat32Array, hz: int) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(m.size() * 2)
	for i in m.size():
		b.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = hz
	w.stereo = false
	w.data = b
	return w
