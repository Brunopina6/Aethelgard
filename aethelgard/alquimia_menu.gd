extends CanvasLayer
# Alquimia de Lya (fase 3, «El bosque que no recuerda»): consultar recetas, investigar, ver ingredientes y fabricar.
# Usa la base de la fase 2: datos/catalogo.gd (recetas, investigaciones y materiales), investigacion.gd y talleres.gd.
# Fabricar gasta los materiales y da el objeto de verdad (todo o nada); los objetos se usan en el combate (Poción,
# Esencia de enfoque, Elixir de savia purificada: combate.gd OBJETOS_COMBATE). Se abre desde Pastos Verdes 3D
# (botón ALQUIMIA, zonas3d/bosque_pastos.gd). Ratón, dedo (botones grandes) y teclado o mando (foco, Esc cierra).

signal cerrado

const Catalogo := preload("res://datos/catalogo.gd")
const Investigacion := preload("res://investigacion.gd")
const Talleres := preload("res://talleres.gd")
const TALLER := "alquimia"
const ORO := Color("E8C46A")
const SUAVE := Color(0.85, 0.82, 0.74)
const MAL := Color(1.0, 0.55, 0.45)
const BIEN := Color(0.6, 1.0, 0.55)
const QUE_HACE := {"Poción": "Recupera 60 PV en combate.", "Esencia de enfoque": "En combate: la magia hace ×1,3 durante 3 turnos.",
	"Elixir de savia purificada": "Purifica al Guardián del Bosque en su segunda fase."}

var pestana := "Recetas"
var lista: VBoxContainer
var mensaje: Label
var botones_pestana := {}


func _ready() -> void:
	layer = 70
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var panel := Panel.new()
	panel.position = Vector2(80, 36)
	panel.size = Vector2(1120, 648)
	add_child(panel)
	var titulo := _texto("Alquimia de Lya", 34, ORO)
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.position = Vector2(110, 52)
	add_child(titulo)
	var x := 110.0
	for p in ["Recetas", "Investigar", "Materiales"]:
		var b := _boton(p.to_upper(), Vector2(230, 60), 24)
		b.position = Vector2(x, 104)
		b.pressed.connect(func():
			pestana = p
			Sonido.efecto("ui_tic")
			_pintar())
		add_child(b)
		botones_pestana[p] = b
		x += 244.0
	var cerrar := _boton("CERRAR", Vector2(220, 60), 24)
	cerrar.position = Vector2(950, 104)
	cerrar.pressed.connect(cerrar_menu)
	add_child(cerrar)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(110, 180)
	scroll.size = Vector2(1060, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	lista = VBoxContainer.new()
	lista.custom_minimum_size = Vector2(1040, 0)
	lista.add_theme_constant_override("separation", 14)
	scroll.add_child(lista)
	mensaje = _texto("", 22, SUAVE)
	mensaje.position = Vector2(110, 622)
	mensaje.size = Vector2(1060, 40)
	add_child(mensaje)
	_pintar()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar_menu()


func cerrar_menu() -> void:
	Sonido.efecto("ui_tic")
	cerrado.emit()
	queue_free()


func _texto(t: String, tam: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _boton(t: String, tam: Vector2, letra: int) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = tam
	b.add_theme_font_size_override("font_size", letra)
	return b


func _pintar() -> void:
	for h in lista.get_children():
		h.queue_free()
	for p in botones_pestana:
		botones_pestana[p].modulate = Color(1.2, 1.1, 0.8) if p == pestana else Color(0.85, 0.85, 0.85)
	match pestana:
		"Recetas":
			_pintar_recetas()
		"Investigar":
			_pintar_investigaciones()
		"Materiales":
			_pintar_materiales()


func _fila(titulo: String, linea1: String, linea2: String, c2: Color, boton: String, apagado: bool, accion: Callable) -> Button:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(_texto(titulo, 26, ORO))
	if linea1 != "":
		textos.add_child(_texto(linea1, 20, SUAVE))
	if linea2 != "":
		textos.add_child(_texto(linea2, 20, c2))
	fila.add_child(textos)
	var b: Button = null
	if boton != "":
		b = _boton(boton, Vector2(220, 64), 22)
		b.disabled = apagado
		b.pressed.connect(accion)
		fila.add_child(b)
	lista.add_child(fila)
	return b


func _pintar_recetas() -> void:
	var Inv = load("res://inventario.gd")
	var todas: Dictionary = Catalogo.todos("recetas")
	var hay := false
	for id in todas:
		var rc: Resource = todas[id]
		if rc.taller != TALLER or rc.borrador:
			continue
		hay = true
		var partes: Array = []
		var falta := false
		for clave in rc.materiales:
			var tiene: int = Inv.cantidad(clave)
			var pide := int(rc.materiales[clave])
			partes.append("%s %d/%d" % [clave, tiene, pide])
			falta = falta or tiene < pide
		var motivo: String = Talleres.puede(id)
		var bloqueada: bool = rc.investigacion != "" and Investigacion.estado(rc.investigacion) != "completada"
		var linea2 := ""
		var c2 := BIEN
		if bloqueada:
			var inv := Catalogo.uno("investigaciones", rc.investigacion)
			linea2 = "Hay que investigar antes: «%s»." % (inv.nombre if inv != null else rc.investigacion)
			c2 = MAL
		elif motivo != "":
			linea2 = motivo
			c2 = MAL
		else:
			linea2 = "Lista para preparar. Tienes %d." % Inv.cantidad(rc.resultado)
		var desc: String = QUE_HACE.get(rc.resultado, "")
		_fila(rc.nombre if rc.nombre == rc.resultado else "%s → %s" % [rc.nombre, rc.resultado], "Ingredientes: " + ", ".join(partes) + ("   ·   " + desc if desc != "" else ""),
			linea2, c2, "FABRICAR", motivo != "", _fabricar.bind(id))
	if not hay:
		lista.add_child(_texto("Lya aún no conoce ninguna receta.", 24, SUAVE))
	_enfocar_primero()


func _fabricar(id: String) -> void:
	var rc := Catalogo.uno("recetas", id)
	if Talleres.fabricar(id):
		Sonido.efecto("tesoro")
		mensaje.text = "Lya prepara %s. (+%d)" % [rc.resultado, rc.cantidad]
		mensaje.add_theme_color_override("font_color", BIEN)
	else:
		Sonido.efecto("ui_error")
		mensaje.text = Talleres.puede(id)
		mensaje.add_theme_color_override("font_color", MAL)
	_pintar()


func _pintar_investigaciones() -> void:
	var todas: Dictionary = Catalogo.todos("investigaciones")
	for id in todas:
		var v: Resource = todas[id]
		if v.taller != TALLER or v.borrador:
			continue
		var e: String = Investigacion.estado(id)
		var linea2 := ""
		var c2 := SUAVE
		var boton := ""
		var apagado := true
		match e:
			"bloqueada":
				var f: Array = Investigacion.faltan(id)
				linea2 = f[0] if not f.is_empty() else "Aún no se puede."
				c2 = MAL
				boton = "INVESTIGAR"
			"disponible":
				linea2 = "Se puede empezar."
				c2 = BIEN
				boton = "ESTUDIAR" if v.pasos <= 1 else "INVESTIGAR"
				apagado = false
			"en_curso":
				var p: Dictionary = Engine.get_meta("investigaciones", {}).get(id, {})
				linea2 = "En curso: %d/%d. Avanza con cada combate ganado." % [int(p.get("progreso", 0)), v.pasos]
				boton = "EN CURSO"
			"completada":
				var nombres: Array = []
				for rid in v.desbloquea:
					var rc := Catalogo.uno("recetas", rid)
					nombres.append(rc.nombre if rc != null else rid)
				linea2 = "Completada. Desbloquea: %s." % ", ".join(nombres)
				c2 = BIEN
		_fila(v.nombre, v.desc, linea2, c2, boton, apagado, _investigar.bind(id))
	_enfocar_primero()


func _investigar(id: String) -> void:
	var motivo: String = Investigacion.empezar(id)
	if motivo != "":
		Sonido.efecto("ui_error")
		mensaje.text = motivo
		mensaje.add_theme_color_override("font_color", MAL)
		_pintar()
		return
	var ya_visto: bool = id == "lya_savia" and load("res://progreso.gd").hito("bq_futuros")
	var v := Catalogo.uno("investigaciones", id)
	if ya_visto and v.pasos > 1:                    # lo visto en el orbe (V9) adelanta un paso
		Investigacion.avanzar(id, 1)
	if v.pasos <= 1:                                 # un estudio corto: se completa al momento
		Investigacion.avanzar(id, v.pasos)
		mensaje.text = "Lya termina de estudiar «%s»." % v.nombre
	else:
		mensaje.text = "Lya empieza a investigar «%s»." % v.nombre
	Sonido.efecto("pagina")
	mensaje.add_theme_color_override("font_color", BIEN)
	_pintar()


func _pintar_materiales() -> void:
	var Inv = load("res://inventario.gd")
	var todos: Dictionary = Catalogo.todos("materiales")
	var hay := false
	for id in todos:
		var m: Resource = todos[id]
		var n: int = Inv.cantidad(m.clave_inventario)
		if n <= 0:
			continue
		hay = true
		_fila("%s ×%d" % [m.nombre, n], m.desc, "", SUAVE, "", true, func(): pass)
	for o in QUE_HACE:                               # lo ya preparado
		var n: int = Inv.cantidad(o)
		if n > 0:
			hay = true
			_fila("%s ×%d" % [o, n], QUE_HACE[o], "", SUAVE, "", true, func(): pass)
	if not hay:
		lista.add_child(_texto("No llevas ingredientes. Búscalos por Pastos Verdes: junto al agua, en las rocas y en los árboles sanos.", 24, SUAVE))


func _enfocar_primero() -> void:
	var E = get_node_or_null("/root/Entrada")
	if E == null or not E.con_foco():
		return
	for f in lista.get_children():
		for b in f.get_children():
			if b is Button and not b.disabled:
				E.enfocar(b)
				return
	E.enfocar(botones_pestana[pestana])
