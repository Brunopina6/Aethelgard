extends Control
# Tienda de las ciudades (Godot 4.x): objetos, equipo (escudos...) y libros de magia, con monedas.
# Se crea por código desde la zona:  var t = load("res://tienda.gd").new(); ui.add_child(t)
# Al cerrarse emite "cerrado" y se borra sola.
# Con teclado o mando (entrada.gd): el foco empieza en la pestaña activa y vuelve al mismo botón tras comprar; Esc / B
# vuelven atrás (de «¿Quién aprende la magia?» a la lista) o cierran; Q / E (L1 / R1) cambian de pestaña.

signal cerrado

# Precios. Los objetos se pueden comprar sin límite; el equipo una sola vez.
const OBJETOS := {"Poción": 20, "Éter": 45, "Incienso de Ceniza": 80}
const EQUIPO := {"escudo_madera": 60, "orbe_proteccion": 140, "escudo_hierro": 150, "escudo_runico": 320,
	"cinta_cuero": 30, "botas_cuero": 40, "anillo_fuerza": 180, "anillo_rubi": 200, "amuleto_vida": 220,
	"averno": 900, "diamante_azul": 1400}
# Libros de magia: [magia, nivel, precio]. Enseñan ese nivel de la magia a un héroe que la use.
const LIBROS := [["Fuego", 2, 250], ["Agua", 2, 250], ["Rayo", 2, 250], ["Cura", 2, 300],
	["Fuego", 3, 700], ["Agua", 3, 700], ["Rayo", 3, 700], ["Cura", 3, 800]]

# Colores y estilo común (estilo.gd): los títulos van en cursiva dorada.
const Estilo := preload("res://estilo.gd")
const COLOR_TITULO := Estilo.ORO
const COLOR_TEXTO := Estilo.LUZ_CLARA
const COLOR_SUAVE := Estilo.GRIS
const COLOR_BIEN := Estilo.CURA
const COLOR_MAL := Estilo.BRASA

const PESTANAS := ["Objetos", "Equipo", "Magias"]

var pestana := "Objetos"
var Inv
var Grupo
var cuerpo: VBoxContainer
var lbl_oro: Label
var lbl_aviso: Label
var botones: Array = []
var eligiendo := false                             # «¿Quién aprende la magia?» en pantalla


func _ready() -> void:
	add_to_group("menu_quieto")                  # Recursos activa el modo ahorro mientras está abierta
	Inv = load("res://inventario.gd")
	Grupo = load("res://grupo.gd")
	size = Vector2(1280, 720)
	var oscuro := ColorRect.new()
	oscuro.color = Color(Estilo.SOMBRA, 0.55)
	oscuro.size = size
	add_child(oscuro)
	var panel := PanelContainer.new()
	panel.position = Vector2(90, 40)
	panel.custom_minimum_size = Vector2(1100, 610)
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.88))
	add_child(panel)
	var todo := VBoxContainer.new()
	todo.add_theme_constant_override("separation", 10)
	panel.add_child(todo)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 10)
	todo.add_child(arriba)
	arriba.add_child(_texto("Tienda", 28, COLOR_TITULO))
	for p in PESTANAS:
		var b := _boton(p, 22, Vector2(150, 44), "pestana:" + p)
		b.set_meta("p", p)
		b.pressed.connect(_ir_a_pestana.bind(p))
		arriba.add_child(b)
		botones.append(b)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	lbl_oro = _texto("", 24, COLOR_TITULO)
	arriba.add_child(lbl_oro)
	var cerrar := _boton("Salir", 22, Vector2(130, 44), "cerrar")
	cerrar.pressed.connect(_cerrar)
	arriba.add_child(cerrar)
	lbl_aviso = _texto("", 20, COLOR_BIEN)
	todo.add_child(lbl_aviso)
	var marco := ScrollContainer.new()
	marco.custom_minimum_size = Vector2(1080, 490)
	marco.follow_focus = true                      # con teclado o mando, la lista sigue al botón con el foco
	todo.add_child(marco)
	cuerpo = VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 8)
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_child(cuerpo)
	_pintar()
	Entrada.enfocar(botones[PESTANAS.find(pestana)])


func _ir_a_pestana(p: String) -> void:
	pestana = p
	_pintar()


func _cerrar() -> void:
	if is_queued_for_deletion():
		return
	cerrado.emit()
	queue_free()


# Teclado y mando (lo que los botones con el foco no usan): atrás o cerrar, y cambiar de pestaña.
func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		if eligiendo:
			_pintar()
		else:
			_cerrar()
	elif ev.is_action_pressed("pestana_anterior") or ev.is_action_pressed("pestana_siguiente"):
		var paso := -1 if ev.is_action_pressed("pestana_anterior") else 1
		var p: String = PESTANAS[posmod(PESTANAS.find(pestana) + paso, PESTANAS.size())]
		_ir_a_pestana(p)
		botones[PESTANAS.find(p)].grab_focus(not Entrada.con_foco())
	else:
		return
	get_viewport().set_input_as_handled()


# Saca del árbol (y borra) lo que hay en el cuerpo, y devuelve la clave del botón con el foco, si estaba aquí.
func _vaciar() -> String:
	var clave := Entrada.clave_enfocada(self)
	for c in cuerpo.get_children():
		cuerpo.remove_child(c)
		c.queue_free()
	return clave


func _devolver_foco(clave: String) -> void:
	var defecto := Entrada.primero(cuerpo)
	if defecto == null:
		defecto = botones[PESTANAS.find(pestana)]
	Entrada.restaurar(self, clave, defecto)


func _pintar() -> void:
	var clave := _vaciar()
	eligiendo = false
	for b in botones:
		b.add_theme_color_override("font_color", COLOR_TITULO if b.get_meta("p") == pestana else COLOR_TEXTO)
	lbl_oro.text = "%d monedas" % Inv.oro()
	match pestana:
		"Objetos":
			for o in OBJETOS:
				var usos: Dictionary = load("res://combate.gd").OBJETOS_COMBATE.get(o, {})
				var desc := "Recupera %d %s" % [usos["cura"], usos["que"]] if not usos.is_empty() else ""
				if o == "Incienso de Ceniza":
					desc = "Sin encuentros durante %d pasos" % load("res://progreso.gd").PASOS_INCIENSO
				_fila(o, desc, "Tienes %d" % Inv.cantidad(o), OBJETOS[o], func(): _comprar_objeto(o))
		"Equipo":
			for id in EQUIPO:
				var ob: Dictionary = Inv.objeto(id)
				if ob.is_empty():
					continue
				var tiene: bool = id in Inv.datos()["equipables"]
				var para := {"todos": "Todos", "espada": "Espadachines", "cetro": "Magos"}
				_fila(ob["nombre"], Inv.resumen(id), "Ya lo tienes" if tiene else para[ob["para"]],
					EQUIPO[id], func(): _comprar_equipo(id), tiene)
		"Magias":
			var romano := ["", "I", "II", "III"]
			for l in LIBROS:
				var nombre: String = load("res://combate.gd").NIVELES_MAGIA[l[0]][l[1] - 1]["nombre"]
				var quienes := PackedStringArray()
				var la_usan := 0                          # los que están ahora en el grupo y usan esa magia
				for h in Grupo.activos():
					if l[0] in Grupo.HEROES[h]["magias"]:
						la_usan += 1
						if Grupo.nivel_magia(h, l[0]) < l[1]:
							quienes.append(h)
				var info := "Para: " + ", ".join(quienes)
				if quienes.is_empty():
					info = "Ya la sabe todo el grupo" if la_usan > 0 else "Nadie del grupo usa esta magia"
				_fila("Libro de %s (%s %s)" % [nombre, l[0], romano[l[1]]], info, "", l[2],
					func(): _comprar_libro(l), quienes.is_empty())
	_devolver_foco(clave)


func _fila(nombre: String, desc: String, nota: String, precio: int, al_comprar: Callable, agotado := false) -> void:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 14)
	var n := _texto(nombre, 21, COLOR_TEXTO)
	n.custom_minimum_size = Vector2(330, 0)
	f.add_child(n)
	var d := _texto(desc, 18, COLOR_BIEN)
	d.custom_minimum_size = Vector2(300, 0)
	f.add_child(d)
	var no := _texto(nota, 18, COLOR_SUAVE)
	no.custom_minimum_size = Vector2(170, 0)
	f.add_child(no)
	var p := _texto("%d" % precio, 21, COLOR_TITULO if Inv.oro() >= precio else COLOR_MAL)
	p.custom_minimum_size = Vector2(70, 0)
	f.add_child(p)
	var b := _boton("Comprar", 18, Vector2(120, 36), "comprar:" + nombre)
	b.disabled = agotado or Inv.oro() < precio
	b.pressed.connect(al_comprar)
	f.add_child(b)
	cuerpo.add_child(f)


func _comprar_objeto(o: String) -> void:
	if Inv.gastar_oro(OBJETOS[o]):
		Inv.agregar_objeto(o)
		_avisar("Has comprado %s." % o)
	_pintar()


func _comprar_equipo(id: String) -> void:
	if Inv.gastar_oro(EQUIPO[id]):
		Inv.agregar(id)
		_avisar("Has comprado %s. Equípalo en el menú Grupo." % Inv.objeto(id)["nombre"])
	_pintar()


# El libro se lo queda el primer héroe que pueda aprenderlo (si hay varios, se elige).
func _comprar_libro(l: Array) -> void:
	var quienes: Array = []
	for h in Grupo.activos():
		if l[0] in Grupo.HEROES[h]["magias"] and Grupo.nivel_magia(h, l[0]) < l[1]:
			quienes.append(h)
	if quienes.size() == 1:
		_dar_libro(l, quienes[0])
		return
	var clave := _vaciar()                           # elegir quién lo aprende
	eligiendo = true
	cuerpo.add_child(_texto("¿Quién aprende la magia?", 24, COLOR_TITULO))
	for h in quienes:
		var b := _boton(h, 22, Vector2(200, 46), "libro:" + h)
		var heroe: String = h
		b.pressed.connect(func(): _dar_libro(l, heroe))
		cuerpo.add_child(b)
	var atras := _boton("Atrás", 20, Vector2(200, 40), "atras")
	atras.pressed.connect(_pintar)
	cuerpo.add_child(atras)
	_devolver_foco(clave)


func _dar_libro(l: Array, heroe: String) -> void:
	if Inv.gastar_oro(l[2]):
		Grupo.aprender(heroe, l[0], l[1])
		var nombre: String = load("res://combate.gd").NIVELES_MAGIA[l[0]][l[1] - 1]["nombre"]
		_avisar("%s aprende %s." % [heroe, nombre])
	_pintar()


func _avisar(t: String) -> void:
	lbl_aviso.text = t


func _texto(t: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	if color == COLOR_TITULO and tam >= 24 and not t.is_valid_int():   # títulos en cursiva (precios no)
		l.add_theme_font_override("font", Estilo.cursiva())
		tam += 8
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


func _boton(t: String, tam: int, minimo: Vector2, clave := "") -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = minimo
	b.add_theme_font_size_override("font_size", tam)
	if clave != "":
		b.set_meta("clave", clave)                  # para devolverle el foco tras repintar (entrada.gd)
	return b
