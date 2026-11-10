extends Control
# Tienda de las ciudades (Godot 4.x): objetos, equipo (escudos...) y libros de magia, con monedas.
# Se crea por código desde la zona:  var t = load("res://tienda.gd").new(); ui.add_child(t)
# Al cerrarse emite "cerrado" y se borra sola.
# Con teclado o mando (entrada.gd): el foco empieza en la pestaña activa y vuelve al mismo botón tras comprar; Esc / B
# vuelven atrás (de «¿Quién aprende la magia?» a la lista) o cierran; Q / E (L1 / R1) cambian de pestaña.

signal cerrado

# Precios. Los objetos se pueden comprar sin límite; el equipo una sola vez.
const OBJETOS := {"Poción": 20, "Éter": 45, "Incienso de Ceniza": 80}
# Fase 3, «El bosque que no recuerda»: tras el Guardián del Bosque, Doña Encina deja hierbas a la venta en Oakhaven
# (lugar 0). Purificado: Hierba lunar y Savia clara; derrotado: solo Hierba lunar. Más caras de lo que paga la tienda.
const OBJETOS_BOSQUE := {"purificado": {"Hierba lunar": 15, "Savia clara": 30}, "derrotado": {"Hierba lunar": 15}}


static func objetos_de(lugar: int) -> Dictionary:
	var r: Dictionary = OBJETOS.duplicate()
	if lugar == 0:
		var P = load("res://progreso.gd")
		for d in OBJETOS_BOSQUE:
			if P.hito("bq_" + d):
				r.merge(OBJETOS_BOSQUE[d])
	return r


func _objetos() -> Dictionary:
	return objetos_de(int(Engine.get_meta("lugar", {}).get("indice", -1)))
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
var Artes                                          # artes.gd (T-091): sus libros, detrás de los de siempre
var cuerpo: VBoxContainer
var lbl_oro: Label
var lbl_aviso: Label
var botones: Array = []
var eligiendo := false                             # «¿Quién aprende la magia?» en pantalla


func _ready() -> void:
	add_to_group("menu_quieto")                  # Recursos activa el modo ahorro mientras está abierta
	Inv = load("res://inventario.gd")
	Grupo = load("res://grupo.gd")
	Artes = load("res://artes.gd")
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
	Sonido.efecto("ui_abrir")                      # sonido.gd (T-083)


func _ir_a_pestana(p: String) -> void:
	pestana = p
	Sonido.efecto("ui_tic")
	_pintar()


func _cerrar() -> void:
	if is_queued_for_deletion():
		return
	Sonido.efecto("ui_cerrar")
	cerrado.emit()
	queue_free()


# Teclado y mando (lo que los botones con el foco no usan): atrás o cerrar, y cambiar de pestaña.
func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		if eligiendo:
			Sonido.efecto("ui_atras")
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
			var objs := _objetos()
			for o in objs:
				var usos: Dictionary = load("res://combate.gd").OBJETOS_COMBATE.get(o, {})
				var desc := "Recupera %d %s" % [usos["cura"], usos["que"]] if not usos.is_empty() else ""
				if desc == "" and load("res://equipo_extra.gd").materiales().has(o):   # hierbas de Encina (fase 3)
					desc = load("res://equipo_extra.gd").materiales()[o]["desc"]
				if o == "Incienso de Ceniza":
					desc = "Sin encuentros durante %d pasos" % load("res://progreso.gd").PASOS_INCIENSO
				_fila(o, desc, "Tienes %d" % Inv.cantidad(o), objs[o], func(): _comprar_objeto(o))
			var Extra = load("res://equipo_extra.gd")    # el botín de las bestias (T-097): se vende
			var mats: Dictionary = Extra.materiales()     # datos/materiales/ (fase 2)
			for m in mats:
				if Inv.cantidad(m) > 0:
					_fila(m, mats[m]["desc"], "Tienes %d" % Inv.cantidad(m), mats[m]["venta"],
						func(): _vender(m), false, true)
		"Equipo":
			var precios := _precios_equipo()
			for id in precios:
				var ob: Dictionary = Inv.objeto(id)
				if ob.is_empty():
					continue
				var tiene: bool = id in Inv.datos()["equipables"]
				var para := {"todos": "Todos", "espada": "Espadachines", "cetro": "Magos"}
				_fila(ob["nombre"], Inv.resumen(id), "Ya lo tienes" if tiene else para.get(ob["para"], ""),
					precios[id], func(): _comprar_equipo(id), tiene)
		"Magias":
			var romano := ["", "I", "II", "III"]
			for l in LIBROS + Artes.libros_en_venta():    # las de siempre y, detrás, las artes ya en el juego
				var nombre := _nombre_libro(l[0], l[1])
				var quienes := PackedStringArray()
				var la_usan := 0                          # los que están ahora en el grupo y usan esa magia
				for h in Grupo.activos():
					if _usa(h, l[0]):
						la_usan += 1
						if _sabe(h, l[0]) < l[1]:
							quienes.append(h)
				var info := "Para: " + ", ".join(quienes)
				if quienes.is_empty():
					info = "Ya la sabe todo el grupo" if la_usan > 0 else "Nadie del grupo usa esta magia"
				_fila("Libro de %s (%s %s)" % [nombre, l[0], romano[l[1]]], info, "", l[2],
					func(): _comprar_libro(l), quienes.is_empty())
	_devolver_foco(clave)


func _fila(nombre: String, desc: String, nota: String, precio: int, al_comprar: Callable, agotado := false, vender := false) -> void:
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
	var p := _texto(("+%d" if vender else "%d") % precio, 21, COLOR_TITULO if vender or Inv.oro() >= precio else COLOR_MAL)
	p.custom_minimum_size = Vector2(70, 0)
	f.add_child(p)
	var b := _boton("Vender" if vender else "Comprar", 18, Vector2(120, 36), ("vender:" if vender else "comprar:") + nombre)
	b.disabled = agotado or (not vender and Inv.oro() < precio)
	b.pressed.connect(al_comprar)
	f.add_child(b)
	cuerpo.add_child(f)


func _comprar_objeto(o: String) -> void:
	if _objetos().has(o) and Inv.gastar_oro(_objetos()[o]):
		Inv.agregar_objeto(o)
		Sonido.efecto("monedas")
		_avisar("Has comprado %s." % o)
	else:
		Sonido.efecto("ui_error")
	_pintar()


# Vende uno del botín de las bestias (datos/materiales/, por equipo_extra.materiales) por su precio de venta.
func _vender(m: String) -> void:
	if Inv.cantidad(m) > 0:
		Inv.gastar(m)
		Inv.ganar_oro(int(load("res://equipo_extra.gd").materiales()[m]["venta"]))
		Sonido.efecto("monedas")
		_avisar("Has vendido %s." % m)
	else:
		Sonido.efecto("ui_error")
	_pintar()


# Equipo de esta tienda: primero lo propio del lugar (índice de mapa.gd: los accesorios de equipo_extra.gd que ya están
# en el juego, T-092: el Farol en Oakhaven y la Moneda del Águila en Sunken City) y después la lista común.
func _precios_equipo() -> Dictionary:
	var r: Dictionary = load("res://equipo_extra.gd").en_tienda(int(Engine.get_meta("lugar", {}).get("indice", -1)))
	r.merge(EQUIPO)
	return r


func _comprar_equipo(id: String) -> void:
	if Inv.gastar_oro(_precios_equipo()[id]):
		Inv.agregar(id)
		Sonido.efecto("monedas")
		_avisar("Has comprado %s. Equípalo en el menú Grupo." % Inv.objeto(id)["nombre"])
	else:
		Sonido.efecto("ui_error")
	_pintar()


# El libro se lo queda el primer héroe que pueda aprenderlo (si hay varios, se elige).
func _comprar_libro(l: Array) -> void:
	var quienes: Array = []
	for h in Grupo.activos():
		if _usa(h, l[0]) and _sabe(h, l[0]) < l[1]:
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
	atras.pressed.connect(func():
		Sonido.efecto("ui_atras")
		_pintar())
	cuerpo.add_child(atras)
	_devolver_foco(clave)


func _dar_libro(l: Array, heroe: String) -> void:
	if Inv.gastar_oro(l[2]):
		_aprender(heroe, l[0], l[1])
		Sonido.efecto("monedas")
		_avisar("%s aprende %s." % [heroe, _nombre_libro(l[0], l[1])])
	else:
		Sonido.efecto("ui_error")
	_pintar()


# Libros: de las magias de siempre (grupo.gd) o de las artes (artes.gd, que se apuntan en los mismos «libros»).
func _usa(h: String, magia: String) -> bool:
	return magia in (Artes.familias_de(h) if Artes.es_arte(magia) else Grupo.HEROES[h]["magias"])


func _sabe(h: String, magia: String) -> int:
	return Artes.nivel(h, magia) if Artes.es_arte(magia) else Grupo.nivel_magia(h, magia)


func _nombre_libro(magia: String, n: int) -> String:
	if Artes.es_arte(magia):
		return Artes.datos(magia, n)["nombre"]
	return load("res://combate.gd").NIVELES_MAGIA[magia][n - 1]["nombre"]


func _aprender(h: String, magia: String, n: int) -> void:
	if Artes.es_arte(magia):
		Artes.aprender(h, magia, n)                 # grupo.gd aprender() no las conoce
	else:
		Grupo.aprender(h, magia, n)


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
