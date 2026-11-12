extends Control
# Firmamento de los Ecos (V12, 12/11): el tablero de Orbes Cristalinos de cada protagonista. PROTOTIPO APAGADO
# (interruptor «orbes_v12», firmamento/orbes.gd). Se crea por código, como menus.gd:
#   var f = load("res://firmamento/firmamento.gd").new(); f.heroe = "Kael"; padre.add_child(f)   → emite «cerrado»
# Lo abre la ficha del Grupo (menus.gd, botón «Firmamento») cuando el interruptor está encendido.
#
# Tres CONCEPTOS visuales para que el usuario elija (ninguno aprobado): astrolabio, constelacion y vidriera. Comparten
# datos (firmamento_datos.gd), lógica (orbes.gd), entrada y panel; cambian el fondo (firmamento/shaders/) y el dibujo
# (firmamento_lienzo.gd). Se cambia con el botón «Concepto» del panel (se recuerda en user://ajustes.cfg).
#
# Entrada:
#   dedo   tocar un nodo lo elige; arrastrar desplaza; pellizcar acerca y aleja
#   ratón  clic elige; arrastrar desplaza; rueda acerca y aleja (también los gestos del panel táctil)
#   teclado / mando  flechas o cruceta eligen el nodo más cercano en esa dirección; Intro / A despierta (dos veces:
#          elegir y confirmar); Esc / B cancela o cierra; Q / E (L1 / R1) cambian de héroe; + / - acercan y alejan
# Comprar pide confirmación (el botón cambia a «Confirmar» y aparece «Cancelar»): nunca se gasta con un toque suelto.

signal cerrado

const Orbes := preload("res://firmamento/orbes.gd")
const Datos := preload("res://firmamento/firmamento_datos.gd")
const Lienzo := preload("res://firmamento/firmamento_lienzo.gd")
const Estilo := preload("res://estilo.gd")

const ESTILOS := ["astrolabio", "constelacion", "vidriera"]
const NOMBRE_ESTILO := {"astrolabio": "Astrolabio", "constelacion": "Constelación",
	"vidriera": "Vidriera de geoda"}
const SHADER := {"astrolabio": "res://firmamento/shaders/fondo_astrolabio.gdshader",
	"constelacion": "res://firmamento/shaders/fondo_constelacion.gdshader",
	"vidriera": "res://firmamento/shaders/fondo_vidriera.gdshader"}
const T_VIAJE := 0.55                             # la energía recorre los enlaces
const T_TOTAL := 1.35                             # y el nodo estalla
const T_TEMBLOR := 0.4
const ANCHO_TABLERO := 860.0                      # el panel ocupa el resto (420 px)
const ZOOM_MAX := 2.0
var fps_reposo := 30.0                           # sin animación de desbloqueo ni arrastre, se redibuja a 30

var heroe := "Kael"
var estilo := "astrolabio"

# estado que lee el lienzo
var nodos: Array = []
var pos := {}
var enlaces: Array = []
var estados := {}
var seleccion := ""
var t := 0.0
var anim := {}
var error_anim := {}
var color_heroe := Color.WHITE
var fuente: Font

var zoom := 1.0
var zoom_min := 0.5
var centro := Vector2(430, 380)
var confirmando := false
var mensaje := ""

var _fondo: ColorRect
var _zona: Control
var _camara: Node2D
var _fija: Node2D                                 # capas del lienzo (firmamento_lienzo.gd)
var _giro: Node2D
var _viva: Node2D
var _luz: Node2D
var _sucio := true                                # la capa fija hay que redibujarla
var _zoom_dibujado := -1.0
var _tabs: HBoxContainer
var _panel: Panel
var _retrato: TextureRect
var _l_nombre: Label
var _l_clase: Label
var _l_orbes: Label
var _l_invertidos: Label
var _l_nodo: Label
var _l_rango: Label
var _l_estado: Label
var _l_bonos: Label
var _l_texto: Label
var _previa: VBoxContainer
var _b_accion: Button
var _b_cancelar: Button
var _l_mensaje: Label
var _b_estilo: Button
var _b_dev: Button
var _icono_estado: Control
var _icono_rango: Control
var _icono_orbe: Control
var _leyenda: Control

var _toques := {}
var _arrastre_ini := Vector2.ZERO
var _movido := false
var _raton := false
var _pellizco_d := 0.0
var _pellizco_m := Vector2.ZERO
var _acumulado := 0.0
var _retratos := {}
var _3d_antes := false


func _ready() -> void:
	add_to_group("menu_quieto")
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	fuente = Estilo.normal()
	estilo = _estilo_guardado()
	var lista := Orbes.heroes()
	if not heroe in lista:
		heroe = lista[0] if not lista.is_empty() else "Kael"
	_construir()
	_poner_heroe(heroe)
	Sonido.efecto("ui_abrir")
	# El tablero tapa toda la pantalla: mientras está abierto, el mundo 3D de debajo no se dibuja (en el Redmi es lo
	# que más cuesta, y el tablero se anima: sin esto, la región entera se volvería a dibujar 30 veces por segundo).
	# Se devuelve como estaba al cerrar (_exit_tree).
	var vp := get_viewport()
	if vp != null:
		_3d_antes = vp.disable_3d
		vp.disable_3d = true


func _exit_tree() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.disable_3d = _3d_antes


# ================================================================= construir

func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.size = Vector2(ANCHO_TABLERO, size.y)   # solo detrás del tablero: el panel es opaco (un tercio menos de píxeles)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	_zona = Control.new()
	_zona.size = Vector2(ANCHO_TABLERO, 720)
	_zona.clip_contents = true
	_zona.mouse_filter = Control.MOUSE_FILTER_STOP
	_zona.gui_input.connect(_entrada_tablero)
	add_child(_zona)
	_camara = Node2D.new()
	_zona.add_child(_camara)
	for capa in ["fija", "giro", "viva", "luz"]:
		var l: Node2D = Lienzo.new()
		l.tab = self
		l.capa = capa
		_camara.add_child(l)
		set("_" + capa, l)

	# franjas oscuras degradadas detrás de las pestañas y de la leyenda: se leen aunque pase un nodo por debajo
	for arriba in [true, false]:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(0, 0, 0, 0.62), Color(0, 0, 0, 0)] if arriba else [Color(0, 0, 0, 0), Color(0, 0, 0, 0.62)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 4
		gt.height = 32
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		var franja := TextureRect.new()
		franja.texture = gt
		franja.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		franja.stretch_mode = TextureRect.STRETCH_SCALE
		franja.size = Vector2(ANCHO_TABLERO, 96)
		franja.position = Vector2(0, 0 if arriba else 720 - 96)
		franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(franja)

	# héroes (pestañas grandes para el dedo)
	_tabs = HBoxContainer.new()
	_tabs.position = Vector2(16, 14)
	_tabs.add_theme_constant_override("separation", 10)
	add_child(_tabs)

	# acercar, alejar y centrar (para quien no conoce el pellizco)
	var zoom_fila := HBoxContainer.new()
	zoom_fila.position = Vector2(ANCHO_TABLERO - 16 - 3 * 64 - 2 * 8, 720 - 16 - 60)
	zoom_fila.add_theme_constant_override("separation", 8)
	add_child(zoom_fila)
	for d in [["-", -1], ["+", 1], ["Centrar", 0]]:
		var b := _boton(d[0], Vector2(64 if d[1] != 0 else 96, 60), 24 if d[1] != 0 else 18)
		var paso: int = d[1]
		b.pressed.connect(func():
			if paso == 0:
				_encuadrar()
			else:
				_zoom_en(_zona.size * 0.5, zoom * (1.25 if paso > 0 else 0.8))
			Sonido.efecto("ui_tic"))
		zoom_fila.add_child(b)
	zoom_fila.position.x = ANCHO_TABLERO - 16 - 64 - 64 - 96 - 16

	_leyenda = Leyenda.new()
	_leyenda.tab = self
	_leyenda.position = Vector2(16, 720 - 16 - 52)
	_leyenda.size = Vector2(500, 52)
	_leyenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_leyenda)

	# panel de la derecha
	_panel = Panel.new()
	_panel.position = Vector2(ANCHO_TABLERO, 0)
	_panel.size = Vector2(1280 - ANCHO_TABLERO, 720)
	add_child(_panel)
	var x0 := 18.0
	var w := _panel.size.x - 2 * x0
	var arriba := _etiqueta("FIRMAMENTO DE LOS ECOS", 16, Color(1, 1, 1, 0.6))
	arriba.position = Vector2(x0, 20)
	_panel.add_child(arriba)
	var cerrar := _boton("Cerrar", Vector2(118, 52), 20)
	cerrar.position = Vector2(_panel.size.x - 118 - 14, 10)
	cerrar.pressed.connect(_cerrar)
	_panel.add_child(cerrar)

	_retrato = TextureRect.new()
	_retrato.position = Vector2(x0, 70)
	_retrato.size = Vector2(118, 150)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_retrato.clip_contents = true
	_panel.add_child(_retrato)
	_l_nombre = _etiqueta("", 40, Color.WHITE, true)
	_l_nombre.position = Vector2(x0 + 132, 64)
	_panel.add_child(_l_nombre)
	_l_clase = _etiqueta("", 17, Color(1, 1, 1, 0.7))
	_l_clase.position = Vector2(x0 + 134, 116)
	_panel.add_child(_l_clase)
	_icono_orbe = Icono.new()
	_icono_orbe.tab = self
	_icono_orbe.tipo = "orbe"
	_icono_orbe.position = Vector2(x0 + 134, 150)
	_icono_orbe.size = Vector2(34, 34)
	_panel.add_child(_icono_orbe)
	_l_orbes = _etiqueta("", 28, Color.WHITE)
	_l_orbes.position = Vector2(x0 + 174, 146)
	_panel.add_child(_l_orbes)
	_l_invertidos = _etiqueta("", 15, Color(1, 1, 1, 0.6))
	_l_invertidos.position = Vector2(x0 + 134, 190)
	_l_invertidos.size = Vector2(w - 134, 20)
	_panel.add_child(_l_invertidos)

	var linea := ColorRect.new()
	linea.position = Vector2(x0, 232)
	linea.size = Vector2(w, 1)
	linea.color = Color(1, 1, 1, 0.18)
	_panel.add_child(linea)

	_icono_rango = Icono.new()
	_icono_rango.tab = self
	_icono_rango.position = Vector2(x0, 246)
	_icono_rango.size = Vector2(44, 44)
	_panel.add_child(_icono_rango)
	_l_nodo = _etiqueta("", 30, Color.WHITE, true)
	_l_nodo.position = Vector2(x0 + 54, 240)
	_l_nodo.size = Vector2(w - 54, 36)
	_l_nodo.clip_text = true
	_panel.add_child(_l_nodo)
	_l_rango = _etiqueta("", 17, Color(1, 1, 1, 0.7))
	_l_rango.position = Vector2(x0 + 56, 278)
	_panel.add_child(_l_rango)
	_icono_estado = Icono.new()
	_icono_estado.tab = self
	_icono_estado.position = Vector2(x0 + 2, 308)
	_icono_estado.size = Vector2(26, 26)
	_panel.add_child(_icono_estado)
	_l_estado = _etiqueta("", 18, Color.WHITE)
	_l_estado.position = Vector2(x0 + 36, 306)
	_l_estado.size = Vector2(w - 36, 48)
	_l_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_l_estado)
	_l_bonos = _etiqueta("", 21, Color.WHITE)
	_l_bonos.position = Vector2(x0, 356)
	_l_bonos.size = Vector2(w, 54)
	_l_bonos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_l_bonos)
	_l_texto = _etiqueta("", 16, Color(1, 1, 1, 0.62), true)
	_l_texto.position = Vector2(x0, 410)
	_l_texto.size = Vector2(w, 40)
	_l_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_l_texto)
	_previa = VBoxContainer.new()
	_previa.position = Vector2(x0, 452)
	_previa.size = Vector2(w, 96)
	_previa.add_theme_constant_override("separation", 0)
	_panel.add_child(_previa)

	_b_accion = _boton("", Vector2(w, 64), 22)
	_b_accion.position = Vector2(x0, 556)
	_b_accion.pressed.connect(_accion)
	_panel.add_child(_b_accion)
	_b_cancelar = _boton("Cancelar", Vector2(120, 64), 20)
	_b_cancelar.position = Vector2(x0 + w - 120, 556)
	_b_cancelar.pressed.connect(_cancelar)
	_panel.add_child(_b_cancelar)
	_l_mensaje = _etiqueta("", 16, Color.WHITE)
	_l_mensaje.position = Vector2(x0, 622)
	_l_mensaje.size = Vector2(w, 22)
	_l_mensaje.clip_text = true
	_panel.add_child(_l_mensaje)

	_b_estilo = _boton("", Vector2(w if not Orbes.herramienta_dev() else w - 128, 52), 17)
	_b_estilo.position = Vector2(x0, 652)
	_b_estilo.pressed.connect(_siguiente_estilo)
	_panel.add_child(_b_estilo)
	if Orbes.herramienta_dev():                     # SOLO Auditoría / editor: orbes temporales para probar compras
		_b_dev = _boton("+10 (prueba)", Vector2(120, 52), 16)
		_b_dev.position = Vector2(x0 + w - 120, 652)
		_b_dev.pressed.connect(func():
			if Orbes.conceder_prueba(10):
				mensaje = "Auditoría: +10 orbes de prueba."
				Sonido.efecto("ui_mejora")
				_refrescar())
		_panel.add_child(_b_dev)


func _etiqueta(txt: String, tam: int, col: Color, cursiva := false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_y", 1)
	if cursiva:
		l.add_theme_font_override("font", Estilo.cursiva())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _boton(txt: String, tam: Vector2, letra: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = tam
	b.size = tam
	b.focus_mode = Control.FOCUS_NONE               # teclado y mando van por _unhandled_input (no hay foco que robe Intro)
	b.add_theme_font_size_override("font_size", letra)
	return b


# Estilo de los botones y del panel según el concepto (no los de Godot por defecto).
func _vestir() -> void:
	var h := color_heroe
	var fondo_panel: Color
	var borde: Color
	match estilo:
		"astrolabio":
			fondo_panel = Color("120E0B")
			borde = Color("C9A25A")
		"constelacion":
			fondo_panel = Color("070B1E")
			borde = Color("8FA8E8", 0.7)
		_:
			fondo_panel = Color("120C18")
			borde = Color("6B4F8A")
	var sp := StyleBoxFlat.new()
	sp.bg_color = fondo_panel
	sp.border_color = borde
	sp.border_width_left = 2
	_panel.add_theme_stylebox_override("panel", sp)
	for b in _todos_botones(self):
		var principal: bool = b == _b_accion
		for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
			var s := StyleBoxFlat.new()
			s.bg_color = Color(fondo_panel.darkened(0.2), 0.85)
			s.border_color = Color(borde, 0.8)
			s.set_border_width_all(1)
			s.set_corner_radius_all(4 if estilo != "vidriera" else 2)
			s.content_margin_left = 10
			s.content_margin_right = 10
			if principal:
				s.border_color = h
				s.set_border_width_all(2)
				s.bg_color = Color(h.darkened(0.75), 0.92)
			if estado == "hover":
				s.bg_color = s.bg_color.lightened(0.08)
			elif estado == "pressed":
				s.bg_color = Color(h.darkened(0.4), 0.95)
			elif estado == "disabled":
				s.border_color = Color(s.border_color, 0.3)
			elif estado == "focus":
				s.draw_center = false
			b.add_theme_stylebox_override(estado, s)
		b.add_theme_color_override("font_color", Color.WHITE if principal else Color(1, 1, 1, 0.9))
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))


func _todos_botones(n: Node) -> Array:
	var r: Array = []
	for c in n.get_children():
		if c is Button:
			r.append(c)
		r.append_array(_todos_botones(c))
	return r


# ================================================================= héroe y concepto

func _poner_heroe(n: String) -> void:
	heroe = n
	color_heroe = Datos.COLOR.get(n, Color.WHITE)
	nodos = Orbes.tablero(n)
	pos.clear()
	for nd in nodos:
		var a := deg_to_rad(float(nd["pos"][0]))
		pos[nd["id"]] = Vector2(sin(a), -cos(a)) * float(nd["pos"][1])
	enlaces.clear()
	var i := 0
	for nd in nodos:
		var req: Array = nd.get("req", [])
		if req.is_empty():
			enlaces.append({"de": "centro", "a": nd["id"], "fase": 0.0})
		for r in req:
			i += 1
			enlaces.append({"de": r, "a": nd["id"], "fase": fmod(i * 0.37, 1.0)})
	seleccion = ""
	confirmando = false
	anim = {}
	mensaje = ""
	_recalcular()
	for nd in nodos:                                 # empieza en algo útil: lo primero que se puede despertar
		if estados[nd["id"]] in ["disponible", "caro"]:
			seleccion = nd["id"]
			break
	if seleccion == "" and not nodos.is_empty():
		seleccion = nodos[0]["id"]
	_pintar_tabs()
	_aplicar_estilo()
	_encuadrar()
	_refrescar()


func _pintar_tabs() -> void:
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	for n in Orbes.heroes():
		var b := _boton(n, Vector2(132, 56), 22)
		var nn: String = n
		b.pressed.connect(func():
			if nn != heroe:
				Sonido.efecto("ui_tic")
				_poner_heroe(nn))
		b.set_meta("heroe", n)
		_tabs.add_child(b)


func _aplicar_estilo() -> void:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER[estilo])
	_fondo.material = m
	_actualizar_fondo()
	_vestir()
	for b in _tabs.get_children():                  # la pestaña del héroe elegido, con su color y subrayada
		var sel: bool = b.get_meta("heroe") == heroe
		var s: StyleBoxFlat = (b.get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
		if sel:
			s.border_color = color_heroe
			s.border_width_bottom = 4
			s.bg_color = Color(color_heroe.darkened(0.7), 0.9)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_color_override("font_color", color_heroe.lightened(0.3) if sel else Color(1, 1, 1, 0.75))
	_b_estilo.text = "Concepto %d/3: %s" % [ESTILOS.find(estilo) + 1, NOMBRE_ESTILO[estilo]]


func _siguiente_estilo() -> void:
	estilo = ESTILOS[(ESTILOS.find(estilo) + 1) % ESTILOS.size()]
	_guardar_estilo()
	Sonido.efecto("ui_tic")
	_aplicar_estilo()
	_refrescar()


func poner_estilo(e: String) -> void:               # pruebas y capturas
	if e in ESTILOS:
		estilo = e
		_aplicar_estilo()
		_refrescar()


func _estilo_guardado() -> String:
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") == OK:
		var e := String(c.get_value("firmamento", "estilo", ESTILOS[0]))
		if e in ESTILOS:
			return e
	return ESTILOS[0]


func _guardar_estilo() -> void:
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg") and c.load("user://ajustes.cfg") != OK:
		return
	c.set_value("firmamento", "estilo", estilo)
	c.save("user://ajustes.cfg")


func _actualizar_fondo() -> void:
	var m := _fondo.material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("color_heroe", Color(color_heroe.r, color_heroe.g, color_heroe.b))
	m.set_shader_parameter("tam", _fondo.size)
	m.set_shader_parameter("centro", centro)
	m.set_shader_parameter("desplazamiento", centro)
	m.set_shader_parameter("zoom", zoom)
	var pulso := 0.0
	if not anim.is_empty():
		var dt := t - float(anim["t0"])
		if dt > T_VIAJE:
			pulso = maxf(0.0, 1.0 - (dt - T_VIAJE) / (T_TOTAL - T_VIAJE))
	m.set_shader_parameter("pulso", pulso)


# ================================================================= estado (lo lee el lienzo)

func _recalcular() -> void:
	estados.clear()
	for nd in nodos:
		estados[nd["id"]] = Orbes.estado(heroe, nd["id"])


func nodo_por_id(id: String) -> Dictionary:
	for nd in nodos:
		if nd["id"] == id:
			return nd
	return {}


func pos_de(id: String) -> Vector2:
	return Vector2.ZERO if id == "centro" else pos.get(id, Vector2.ZERO)


func radio_de(id: String) -> float:
	if id == "centro":
		return 64.0
	return float(Lienzo.R_NODO.get(nodo_por_id(id).get("rango", "basica"), 20.0))


func estado_visible(id: String) -> String:
	if not anim.is_empty() and anim["id"] == id and t - float(anim["t0"]) < T_VIAJE:
		return "disponible"
	return estados.get(id, "bloqueado")


func brillo_nodo(id: String) -> float:
	if not anim.is_empty() and anim["id"] == id:
		return clampf((t - float(anim["t0"]) - T_VIAJE) / 0.3, 0.0, 1.0)
	return 1.0


func _despierto_visible(id: String) -> bool:
	return id == "centro" or estado_visible(id) == "desbloqueado"


func estado_enlace(e: Dictionary) -> String:
	if not _despierto_visible(e["de"]):
		return "cerrado"
	var b := estado_visible(e["a"])
	if b == "desbloqueado":
		return "luz"
	if b == "disponible" or b == "caro":
		return "abierto"
	return "cerrado"


func progreso_enlace(e: Dictionary) -> float:
	if anim.is_empty() or e["a"] != anim["id"] or not e["de"] in anim["desde"]:
		return 0.0
	var dt := t - float(anim["t0"])
	return ease(clampf(dt / T_VIAJE, 0.0, 1.0), 0.6) if dt < T_VIAJE else 0.0


func temblor(id: String) -> Vector2:
	if error_anim.is_empty() or error_anim["id"] != id:
		return Vector2.ZERO
	var dt := t - float(error_anim["t0"])
	if dt > T_TEMBLOR:
		return Vector2.ZERO
	return Vector2(sin(dt * 55.0) * 7.0 * (1.0 - dt / T_TEMBLOR), 0)


# ================================================================= panel

func _refrescar() -> void:
	_recalcular()
	_sucio = true
	_giro.queue_redraw()
	_leyenda.queue_redraw()                         # la muestra de «Despertado» va con el color del héroe
	var G = load("res://grupo.gd")
	_l_nombre.text = heroe
	_l_nombre.add_theme_color_override("font_color", color_heroe.lightened(0.25))
	_l_clase.text = "%s · %s" % [G.HEROES[heroe]["clase"], "provisional" if G.HEROES[heroe].get("provisional", false) else "Nivel %d" % int(G.datos()[heroe]["nivel"])]
	_l_orbes.text = "%d orbes" % Orbes.saldo()
	_l_invertidos.text = Orbes.resumen(heroe)
	_retrato.texture = _retrato_de(heroe)
	_icono_orbe.queue_redraw()
	var nd := nodo_por_id(seleccion)
	for c in _previa.get_children():
		_previa.remove_child(c)
		c.queue_free()
	if nd.is_empty():
		_l_nodo.text = "Elige una estrella"
		_l_rango.text = ""
		_l_estado.text = ""
		_l_bonos.text = ""
		_l_texto.text = ""
		_b_accion.text = "Elige un nodo"
		_b_accion.disabled = true
		_b_cancelar.visible = false
		_l_mensaje.text = mensaje
		return
	var est: String = estados[seleccion]
	_l_nodo.text = nd["nombre"]
	_l_rango.text = "%s · %d %s" % [Datos.NOMBRE_RANGO[nd["rango"]], Orbes.precio(nd), "orbe" if Orbes.precio(nd) == 1 else "orbes"]
	_icono_rango.tipo = "rango"
	_icono_rango.nodo_icono = nd
	_icono_rango.estado_icono = est
	_icono_rango.queue_redraw()
	_icono_estado.tipo = "estado"
	_icono_estado.estado_icono = est
	_icono_estado.queue_redraw()
	match est:
		"desbloqueado":
			_l_estado.text = "Despertado. Ya suma a sus estadísticas."
		"disponible":
			_l_estado.text = "Disponible: puedes despertarlo."
		"caro":
			_l_estado.text = "Disponible, pero %s." % Orbes.texto_faltan(Orbes.precio(nd) - Orbes.saldo())
		"dormido":
			_l_estado.text = "Dormido: aún no hay nada en el juego que lo use."
		_:
			_l_estado.text = "Bloqueado. Requiere %s." % Orbes.texto_requisitos(heroe, nd)
	_l_bonos.text = Orbes.texto_bonos(nd)
	_l_bonos.add_theme_color_override("font_color", color_heroe.lightened(0.35) if est != "dormido" else Color(0.7, 0.62, 0.9))
	_l_texto.text = nd.get("texto", "")
	if est != "desbloqueado" and est != "dormido" and Orbes.activo():
		var lineas: Array = Orbes.lineas_previa(heroe, seleccion)
		if not lineas.is_empty():
			_previa.add_child(_etiqueta("Al despertarlo:", 15, Color(1, 1, 1, 0.55)))
		for l in lineas.slice(0, 3):
			_previa.add_child(_fila_previa(l))
	match est:
		"disponible":
			_b_accion.disabled = false
			if confirmando:
				_b_accion.text = "Confirmar: gastar %d" % Orbes.precio(nd)
				_ancho_accion(_panel.size.x - 36 - 130)
			else:
				_b_accion.text = "Despertar · %d %s" % [Orbes.precio(nd), "orbe" if Orbes.precio(nd) == 1 else "orbes"]
				_ancho_accion(_panel.size.x - 36)
		"desbloqueado":
			_b_accion.disabled = true
			_b_accion.text = "Despertado"
			_ancho_accion(_panel.size.x - 36)
		_:
			_b_accion.disabled = false             # se puede pulsar: explica por qué no (y el nodo tiembla)
			_b_accion.text = {"caro": "Faltan orbes", "dormido": "Dormido", "bloqueado": "Bloqueado"}.get(est, "")
			_ancho_accion(_panel.size.x - 36)
	_b_cancelar.visible = confirmando and est == "disponible"
	if Orbes.saldo() == 0 and mensaje == "":
		_l_mensaje.text = "Aún no hay forma de ganar orbes (pendiente de decidir)."
		_l_mensaje.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	else:
		_l_mensaje.text = mensaje
		_l_mensaje.add_theme_color_override("font_color", color_heroe.lightened(0.4))


func _ancho_accion(w: float) -> void:
	_b_accion.custom_minimum_size.x = w
	_b_accion.size.x = w


func _fila_previa(l: Array) -> Control:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 8)
	var n := _etiqueta(l[0], 18, Color(1, 1, 1, 0.8))
	n.custom_minimum_size = Vector2(170, 0)
	f.add_child(n)
	var a := _etiqueta(l[1], 18, Color(1, 1, 1, 0.65))
	a.custom_minimum_size = Vector2(70, 0)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	f.add_child(a)
	var flecha := Icono.new()
	flecha.tab = self
	flecha.tipo = "flecha"
	flecha.custom_minimum_size = Vector2(26, 26)
	f.add_child(flecha)
	f.add_child(_etiqueta(l[2], 19, Estilo.CURA))
	return f


func _retrato_de(n: String) -> Texture2D:
	if _retratos.has(n):
		return _retratos[n]
	var ruta: String = Datos.RETRATO.get(n, "")
	var tex: Texture2D = null
	if ruta != "" and ResourceLoader.exists(ruta):
		var base: Texture2D = load(ruta)
		var at := AtlasTexture.new()                # solo el busto: la mitad de arriba
		at.atlas = base
		at.region = Rect2(0, 0, base.get_width(), base.get_height() * 0.42)
		tex = at
	_retratos[n] = tex
	return tex


# ================================================================= acciones

func elegir(id: String) -> void:
	if id == seleccion or nodo_por_id(id).is_empty():
		return
	seleccion = id
	confirmando = false
	mensaje = ""
	Sonido.efecto("ui_tic")
	_refrescar()


func _accion() -> void:
	if seleccion == "" or not anim.is_empty() and t - float(anim["t0"]) < T_VIAJE:
		return
	var est: String = Orbes.estado(heroe, seleccion)
	if est == "disponible":
		if not confirmando:
			confirmando = true
			Sonido.efecto("ui_tic")
			_refrescar()
			return
		_comprar()
		return
	if est == "desbloqueado":
		return
	error_anim = {"id": seleccion, "t0": t}
	mensaje = Orbes.motivo(heroe, seleccion)
	confirmando = false
	Sonido.efecto("ui_error")
	_refrescar()


func _cancelar() -> void:
	if confirmando:
		confirmando = false
		Sonido.efecto("ui_atras")
		_refrescar()


func _comprar() -> void:
	var nd := nodo_por_id(seleccion)
	var desde: Array = []
	for r in nd.get("req", []):
		if Orbes.desbloqueado(heroe, r):
			desde.append(r)
	if nd.get("req", []).is_empty():
		desde = ["centro"]
	var err := Orbes.desbloquear(heroe, seleccion)
	confirmando = false
	if err != "":
		mensaje = err
		error_anim = {"id": seleccion, "t0": t}
		Sonido.efecto("ui_error")
		_refrescar()
		return
	anim = {"id": seleccion, "t0": t, "desde": desde}
	mensaje = "«%s» despierta." % nd["nombre"]
	Sonido.efecto("ui_confirmar")
	Sonido.efecto("orbe_vision", {"retraso": T_VIAJE})
	_refrescar()


# Lo que haría un toque en el botón principal (pruebas): elegir + confirmar.
func despertar(id: String) -> String:
	elegir(id)
	if Orbes.estado(heroe, id) != "disponible":
		var m := Orbes.motivo(heroe, id)
		_accion()
		return m
	_accion()
	_accion()
	return ""


func _cerrar() -> void:
	if is_queued_for_deletion():
		return
	Sonido.efecto("ui_cerrar")
	cerrado.emit()
	queue_free()


# ================================================================= cámara: encuadre, zoom y desplazamiento

func _encuadrar() -> void:
	var r := Rect2(Vector2.ZERO, Vector2.ZERO)
	for id in pos:
		r = r.expand(pos[id])
	r = r.grow(95.0)                                 # y los precios, que van por fuera
	var alto_util := 720.0 - 70.0 - 70.0             # pestañas arriba, leyenda y zoom abajo
	zoom = clampf(minf(ANCHO_TABLERO / r.size.x, alto_util / r.size.y), 0.45, 1.3)
	zoom_min = zoom * 0.85
	centro = Vector2(ANCHO_TABLERO * 0.5, 70.0 + alto_util * 0.5) - r.get_center() * zoom
	_aplicar_camara()


func _zoom_en(punto: Vector2, z: float) -> void:
	z = clampf(z, zoom_min, ZOOM_MAX)
	var tablero := (punto - centro) / zoom
	zoom = z
	centro = punto - tablero * zoom
	_aplicar_camara()


func _aplicar_camara() -> void:
	var lim := 560.0 * zoom                          # el borde del tablero no se va del todo de la pantalla
	centro.x = clampf(centro.x, ANCHO_TABLERO * 0.5 - lim, ANCHO_TABLERO * 0.5 + lim)
	centro.y = clampf(centro.y, 360.0 - lim, 360.0 + lim)
	_camara.position = centro
	_camara.scale = Vector2(zoom, zoom)
	_actualizar_fondo()


func a_tablero(p: Vector2) -> Vector2:
	return (p - centro) / zoom


func en_pantalla(id: String) -> Vector2:          # pruebas: dónde tocar para elegir este nodo
	return centro + pos_de(id) * zoom


func nodo_en(p: Vector2) -> String:
	var q := a_tablero(p)
	var mejor := ""
	var mejor_d := INF
	for nd in nodos:
		var d: float = q.distance_to(pos[nd["id"]])
		var alcance := maxf(Lienzo.R_NODO[nd["rango"]] + 14.0, 44.0 / zoom)   # al menos 88 px de diámetro en pantalla
		if d < alcance and d < mejor_d:
			mejor = nd["id"]
			mejor_d = d
	return mejor


func _tocar(p: Vector2) -> void:
	var id := nodo_en(p)
	if id != "":
		elegir(id)


func _entrada_tablero(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_toques[ev.index] = ev.position
			if _toques.size() == 1:
				_arrastre_ini = ev.position
				_movido = false
			elif _toques.size() == 2:
				var v: Array = _toques.values()
				_pellizco_d = v[0].distance_to(v[1])
				_pellizco_m = (v[0] + v[1]) * 0.5
		else:
			if _toques.size() == 1 and not _movido:
				_tocar(ev.position)
			_toques.erase(ev.index)
			_pellizco_d = 0.0
		accept_event()
	elif ev is InputEventScreenDrag:
		_toques[ev.index] = ev.position
		if _toques.size() == 1:
			if not _movido and ev.position.distance_to(_arrastre_ini) > 14.0:
				_movido = true
			if _movido:
				centro += ev.relative
				_aplicar_camara()
		elif _toques.size() >= 2:
			_movido = true
			var v: Array = _toques.values()
			var d: float = v[0].distance_to(v[1])
			var m: Vector2 = (v[0] + v[1]) * 0.5
			if _pellizco_d > 1.0:
				_zoom_en(m, zoom * d / _pellizco_d)
				centro += m - _pellizco_m
				_aplicar_camara()
			_pellizco_d = d
			_pellizco_m = m
		accept_event()
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			_zoom_en(ev.position, zoom * 1.12)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			_zoom_en(ev.position, zoom / 1.12)
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_raton = true
				_movido = false
				_arrastre_ini = ev.position
			else:
				if _raton and not _movido:
					_tocar(ev.position)
				_raton = false
		accept_event()
	elif ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION and _raton:
		if not _movido and ev.position.distance_to(_arrastre_ini) > 8.0:
			_movido = true
		if _movido:
			centro += ev.relative
			_aplicar_camara()
		accept_event()
	elif ev is InputEventMagnifyGesture:
		_zoom_en(ev.position, zoom * ev.factor)
		accept_event()
	elif ev is InputEventPanGesture:
		centro -= ev.delta * 12.0
		_aplicar_camara()
		accept_event()


func _unhandled_input(ev: InputEvent) -> void:
	var dir := Vector2.ZERO
	if ev.is_action_pressed("ui_cancel"):
		if confirmando:
			_cancelar()
		else:
			_cerrar()
	elif ev.is_action_pressed("ui_accept"):
		_accion()
	elif ev.is_action_pressed("pestana_anterior") or ev.is_action_pressed("pestana_siguiente"):
		var lista := Orbes.heroes()
		var paso := -1 if ev.is_action_pressed("pestana_anterior") else 1
		Sonido.efecto("ui_tic")
		_poner_heroe(lista[posmod(lista.find(heroe) + paso, lista.size())])
	elif ev.is_action_pressed("camara_acercar"):
		_zoom_en(_zona.size * 0.5, zoom * 1.2)
	elif ev.is_action_pressed("camara_alejar"):
		_zoom_en(_zona.size * 0.5, zoom / 1.2)
	elif ev.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
	elif ev.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
	elif ev.is_action_pressed("ui_up"):
		dir = Vector2.UP
	elif ev.is_action_pressed("ui_down"):
		dir = Vector2.DOWN
	else:
		return
	if dir != Vector2.ZERO:
		_mover_seleccion(dir)
	get_viewport().set_input_as_handled()


# Teclado y mando: el nodo más cercano en esa dirección (dentro de un cono de unos 60°); la cámara lo sigue.
func _mover_seleccion(dir: Vector2) -> void:
	var desde: Vector2 = pos.get(seleccion, Vector2.ZERO)
	var mejor := ""
	var mejor_p := INF
	for nd in nodos:
		var d: Vector2 = pos[nd["id"]] - desde
		if d.length() < 1.0:
			continue
		var c := d.normalized().dot(dir)
		if c < 0.5:
			continue
		var puntos := d.length() * (2.0 - c)
		if puntos < mejor_p:
			mejor_p = puntos
			mejor = nd["id"]
	if mejor != "":
		elegir(mejor)
		var p := en_pantalla(mejor)
		if p.x < 60 or p.x > ANCHO_TABLERO - 60 or p.y < 90 or p.y > 640:
			centro += Vector2(ANCHO_TABLERO * 0.5, 380) - p
			_aplicar_camara()


# ================================================================= tiempo

func _process(delta: float) -> void:
	t += delta
	if not anim.is_empty() and t - float(anim["t0"]) > T_TOTAL:
		anim = {}
		_sucio = true
	if not error_anim.is_empty() and t - float(error_anim["t0"]) > T_TEMBLOR:
		error_anim = {}
		_sucio = true
	var vivo := not anim.is_empty() or not error_anim.is_empty() or _movido and (_raton or not _toques.is_empty())
	_acumulado += delta
	if vivo or _acumulado >= 1.0 / fps_reposo:
		_acumulado = 0.0
		_viva.queue_redraw()
		_luz.queue_redraw()
		_actualizar_fondo()
	if _sucio or not anim.is_empty() or not error_anim.is_empty() or not is_equal_approx(_zoom_dibujado, zoom):
		_sucio = false
		_zoom_dibujado = zoom
		_fija.queue_redraw()
	_giro.rotation = t * (0.05 if estilo == "astrolabio" else 0.02)


# ================================================================= piezas dibujadas (leyenda e iconos del panel)

class Leyenda extends Control:
	var tab

	func _draw() -> void:
		var x := 0.0
		for e in [["bloqueado", "Bloqueado"], ["disponible", "Disponible"], ["desbloqueado", "Despertado"],
				["dormido", "Dormido"]]:
			Icono.dibujar_estado(self, tab, Vector2(x + 16, 26), e[0], 13.0)
			draw_string(tab.fuente, Vector2(x + 40, 33), e[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.75))
			x += 122.0


class Icono extends Control:
	var tab
	var tipo := "orbe"
	var nodo_icono := {}
	var estado_icono := "bloqueado"

	func _draw() -> void:
		var c := size * 0.5
		match tipo:
			"orbe":
				Lienzo.orbe(self, c, size.x * 0.42, tab.color_heroe)
			"flecha":
				var col := Color(1, 1, 1, 0.7)
				draw_line(c + Vector2(-9, 0), c + Vector2(8, 0), col, 2.0, true)
				draw_polyline(PackedVector2Array([c + Vector2(2, -6), c + Vector2(9, 0), c + Vector2(2, 6)]), col, 2.0, true)
			"rango":
				var p: PackedVector2Array = tab._fija.forma(nodo_icono.get("rango", "basica"), c, size.x * 0.42, tab.estilo)
				draw_colored_polygon(p, Color(tab.color_heroe, 0.85) if estado_icono == "desbloqueado" else Color(0, 0, 0, 0.5))
				var q := p.duplicate()
				q.append(p[0])
				draw_polyline(q, tab.color_heroe.lightened(0.3), 2.0, true)
				Lienzo.glifo(self, "luna" if estado_icono == "dormido" else String(nodo_icono.get("glifo", "estrella")), c,
					size.x * 0.2, Color.WHITE if estado_icono != "desbloqueado" else Color("1A1420"), 1.8)
			"estado":
				dibujar_estado(self, tab, c, estado_icono, size.x * 0.4)

	# Muestra de cada estado (leyenda y panel): forma y trazo distintos, no solo el color.
	static func dibujar_estado(ci: CanvasItem, tb, c: Vector2, est: String, r: float) -> void:
		var h: Color = tb.color_heroe
		var p := Lienzo.poligono(c, r, 12)
		match est:
			"desbloqueado":
				ci.draw_colored_polygon(p, h)
				ci.draw_arc(c, r, 0, TAU, 24, Color.WHITE, 1.6, true)
				Lienzo.glifo(ci, "estrella", c, r * 0.6, Color("1A1420"), 1.6)
			"disponible", "caro":
				ci.draw_colored_polygon(p, Color(0, 0, 0, 0.6))
				ci.draw_arc(c, r, 0, TAU, 24, h.lightened(0.25) if est == "disponible" else Color(h, 0.5), 2.4, true)
				ci.draw_arc(c, r + 5.0, 0, TAU, 24, Color(h, 0.5 if est == "disponible" else 0.0), 1.2, true)
			"dormido":
				for i in 12:
					if i % 2 == 0:
						ci.draw_line(p[i], p[(i + 1) % 12], Color(0.7, 0.6, 0.9, 0.85), 1.6, true)
				Lienzo.glifo(ci, "luna", c, r * 0.6, Color(0.7, 0.6, 0.9, 0.9), 1.5)
			_:
				for i in 12:
					if i % 2 == 0:
						ci.draw_line(p[i], p[(i + 1) % 12], Color(0.6, 0.6, 0.65, 0.7), 1.4, true)
