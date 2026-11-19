extends Control
# Menús del grupo (Godot 4.x): Grupo (nivel, atributos y equipo), Objetos, Habilidades y Ajustes (volumen, sonido.gd).
# Se crea por código desde el mapa:  var m = load("res://menus.gd").new(); m.pestana = "Grupo"; ui.add_child(m)
# Al cerrarse emite "cerrado" y se borra solo.
# Con teclado o mando (entrada.gd): el foco empieza en la pestaña activa y vuelve al mismo botón tras cada cambio;
# Esc / B cierran, Q / E (L1 / R1) cambian de pestaña y la lista se desplaza siguiendo el foco (o con ↑ ↓ si solo hay
# texto). Con el dedo, todo sigue igual.

signal cerrado

# Colores y estilo común (estilo.gd): los títulos van en cursiva dorada.
const Estilo := preload("res://estilo.gd")
const COLOR_TITULO := Estilo.ORO
const COLOR_TEXTO := Estilo.LUZ_CLARA
const COLOR_SUAVE := Estilo.GRIS
const COLOR_BIEN := Estilo.CURA

const PESTANAS := ["Grupo", "Objetos", "Habilidades", "Ajustes"]

var pestana := "Grupo"
# Solo la pestaña de Ajustes: la pantalla de inicio alternativa (portada/inicio_alternativo.gd) abre así sus Opciones,
# porque allí aún no hay partida cargada. Por defecto, false: el menú de siempre.
var solo_ajustes := false
var pestanas: Array = PESTANAS
var heroe := ""
var Grupo
var Inv
var cuerpo: VBoxContainer
var marco: ScrollContainer
var botones_pestana: Array = []
var vista_formacion := false                     # V12: en la pestaña Grupo, la Formación en vez de la ficha
var aviso_formacion := ""                        # por qué no se pudo el último cambio de la Formación


func _ready() -> void:
	add_to_group("menu_quieto")                  # Recursos activa el modo ahorro mientras está abierto
	Grupo = load("res://grupo.gd")
	Inv = load("res://inventario.gd")
	heroe = Grupo.activos()[0]
	if solo_ajustes:
		pestanas = ["Ajustes"]
		pestana = "Ajustes"
	size = Vector2(1280, 720)
	var oscuro := ColorRect.new()
	oscuro.color = Color(Estilo.SOMBRA, 0.55)
	oscuro.size = size
	add_child(oscuro)
	var panel := PanelContainer.new()
	panel.position = Vector2(90, 40)
	panel.custom_minimum_size = Vector2(1100, 640)    # 40 px de margen arriba y abajo (antes, 600: 72 abajo)
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.88))
	add_child(panel)
	var todo := VBoxContainer.new()
	todo.add_theme_constant_override("separation", 12)
	panel.add_child(todo)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 10)
	todo.add_child(arriba)
	for p in pestanas:
		var b := _boton(p, 22, Vector2(170, 44), "pestana:" + p)
		b.set_meta("nombre", p)
		botones_pestana.append(b)
		b.pressed.connect(_ir_a_pestana.bind(p))
		arriba.add_child(b)
	_colorear_pestanas()
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	var cerrar := _boton("Cerrar", 22, Vector2(150, 44), "cerrar")
	cerrar.pressed.connect(_cerrar)
	arriba.add_child(cerrar)
	marco = ScrollContainer.new()
	marco.custom_minimum_size = Vector2(1080, 560)    # con la ranura Accesorio (T-092), su efecto se ve sin desplazar
	marco.follow_focus = true                      # con teclado o mando, la lista sigue al botón con el foco
	todo.add_child(marco)
	cuerpo = VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 8)
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_child(cuerpo)
	_pintar()
	Entrada.enfocar(botones_pestana[pestanas.find(pestana)])
	Sonido.efecto("ui_abrir")                      # sonido.gd (T-083)


func _colorear_pestanas() -> void:
	for x in botones_pestana:
		x.add_theme_color_override("font_color", COLOR_TITULO if x.get_meta("nombre") == pestana else COLOR_TEXTO)


func _ir_a_pestana(p: String) -> void:
	pestana = p
	Sonido.efecto("ui_tic")
	_colorear_pestanas()
	marco.scroll_vertical = 0
	_pintar_de_nuevo()


func _cerrar() -> void:
	if is_queued_for_deletion():
		return
	Sonido.efecto("ui_cerrar")
	cerrado.emit()
	queue_free()


# Teclado y mando (lo que los botones con el foco no usan): cerrar, cambiar de pestaña y, si no hay botones más abajo,
# desplazar el texto.
func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") and vista_formacion and pestana == "Grupo":   # V12: de la Formación, a la ficha
		_salir_formacion()
	elif ev.is_action_pressed("ui_cancel"):
		_cerrar()
	elif ev.is_action_pressed("pestana_anterior") or ev.is_action_pressed("pestana_siguiente"):
		var paso := -1 if ev.is_action_pressed("pestana_anterior") else 1
		var p: String = pestanas[posmod(pestanas.find(pestana) + paso, pestanas.size())]
		_ir_a_pestana(p)
		botones_pestana[pestanas.find(p)].grab_focus(not Entrada.con_foco())
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up"):
		marco.scroll_vertical += 80 if ev.is_action_pressed("ui_down") else -80
	else:
		return
	get_viewport().set_input_as_handled()


# Rehace el cuerpo. Los botones viejos salen del árbol al momento (y se borran después) y el foco, si estaba en esta
# ventana, vuelve al botón de la misma clave.
func _pintar_de_nuevo() -> void:
	var clave := Entrada.clave_enfocada(self)
	for c in cuerpo.get_children():
		cuerpo.remove_child(c)
		c.queue_free()
	_pintar()
	var defecto := Entrada.primero(cuerpo)          # si ese botón ya no sirve (p. ej. sin puntos), el más cercano
	if defecto == null:
		defecto = botones_pestana[pestanas.find(pestana)]
	Entrada.restaurar(self, clave, defecto)


func _pintar() -> void:
	match pestana:
		"Grupo":
			_pintar_grupo()
		"Objetos":
			_pintar_objetos()
		"Habilidades":
			_pintar_habilidades()
		"Ajustes":
			_pintar_ajustes()


# ---------------------------------------------------------------- Grupo

func _pintar_grupo() -> void:
	if vista_formacion and Grupo.hay_formacion():  # V12: la Formación (activos y reserva)
		_pintar_formacion()
		return
	vista_formacion = false
	var fila_heroes := HBoxContainer.new()
	fila_heroes.add_theme_constant_override("separation", 8)
	cuerpo.add_child(fila_heroes)
	var reserva: Array = Grupo.reserva()             # V12: la reserva también tiene ficha (sin reserva, como siempre)
	if not heroe in Grupo.en_el_grupo():
		heroe = Grupo.activos()[0]
	for n in Grupo.activos() + reserva:
		if not reserva.is_empty() and n == reserva[0]:
			fila_heroes.add_child(_texto("  Reserva:", 18, COLOR_SUAVE))
		var b := _boton(n, 22, Vector2(140, 40), "heroe:" + n)
		if n == heroe:
			b.add_theme_color_override("font_color", COLOR_TITULO)
		elif n in reserva:
			b.add_theme_color_override("font_color", COLOR_SUAVE)
		b.pressed.connect(func():
			heroe = n
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fila_heroes.add_child(b)
	if Grupo.hay_formacion():                        # V12: solo cuando hay a quién cambiar
		var hueco := Control.new()
		hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_heroes.add_child(hueco)
		var f := _boton("Formación", 22, Vector2(180, 40), "formacion")
		f.add_theme_color_override("font_color", COLOR_TITULO)
		f.pressed.connect(func():
			vista_formacion = true
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fila_heroes.add_child(f)
	var Orbes = load("res://firmamento/orbes.gd")   # V12: Firmamento de los Ecos (interruptor «orbes_v12», APAGADO)
	if Orbes.activo() and heroe in Orbes.heroes():
		if not Grupo.hay_formacion():
			var hueco_o := Control.new()
			hueco_o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_heroes.add_child(hueco_o)
		var fo := _boton("Firmamento · %d orbes" % Orbes.saldo(), 22, Vector2(260, 40), "firmamento")
		fo.add_theme_color_override("font_color", COLOR_TITULO)
		fo.pressed.connect(_abrir_firmamento)
		fila_heroes.add_child(fo)

	var h: Dictionary = Grupo.datos()[heroe]
	var e: Dictionary = Grupo.estadisticas(heroe)
	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 40)
	cuerpo.add_child(columnas)

	# izquierda: nivel y atributos
	var izq := VBoxContainer.new()
	izq.custom_minimum_size = Vector2(520, 0)
	izq.add_theme_constant_override("separation", 6)
	columnas.add_child(izq)
	var cabecera := "%s — %s" % [heroe, Grupo.HEROES[heroe]["clase"]]
	if heroe in reserva:
		cabecera += "  (reserva)"
	izq.add_child(_texto(cabecera, 26, COLOR_TITULO))
	if Grupo.HEROES[heroe].get("provisional", false):   # V12: Naira es una propuesta (NAIRA.md), no canon
		izq.add_child(_texto("Personaje provisional, en pruebas.", 16, COLOR_SUAVE))
	if Grupo.CRECIMIENTO.has(heroe) and int(h["puntos"]) > 0:   # V12: su reparto recomendado (los puntos, a mano igual)
		var rep := _boton("Repartir como recomienda", 18, Vector2(300, 36), "repartir:" + heroe)
		rep.pressed.connect(func():
			if Grupo.repartir_recomendado(heroe) > 0:
				Sonido.efecto("ui_mejora")
				_pintar_de_nuevo())
		izq.add_child(rep)
	izq.add_child(_texto("Nivel %d     EXP %d / %d" % [h["nivel"], h["exp"], Grupo.exp_para(h["nivel"])], 20, COLOR_TEXTO))
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(420, 3)
	barra.show_percentage = false
	barra.max_value = Grupo.exp_para(h["nivel"])
	barra.value = h["exp"]
	izq.add_child(barra)
	izq.add_child(_texto("PV %d / %d     PM %d / %d     Ataque %d     Defensa %d" % [e["pv"], e["pv_max"], e["pm"], e["pm_max"],
		e["ataque"], e["defensa"]], 18, COLOR_SUAVE))
	izq.add_child(_texto("Puntos para mejorar: %d" % h["puntos"], 22, COLOR_BIEN if h["puntos"] > 0 else COLOR_SUAVE))
	for k in Grupo.ATRIBUTOS:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 10)
		var base: int = h["atributos"][k]
		var total: int = e["atributos"][k]
		var nombre := _texto(Grupo.NOMBRES[k], 20, COLOR_TEXTO)
		nombre.custom_minimum_size = Vector2(120, 0)
		f.add_child(nombre)
		var valor := _texto("%d" % total + ("  (%+d)" % (total - base) if total != base else ""), 20, COLOR_TEXTO)
		valor.custom_minimum_size = Vector2(90, 0)
		f.add_child(valor)
		var mas := _boton("+", 20, Vector2(40, 34), "mas:" + k)
		mas.disabled = h["puntos"] <= 0
		var atr: String = k
		mas.pressed.connect(func():
			if Grupo.subir_atributo(heroe, atr):
				Sonido.efecto("ui_mejora")
				_pintar_de_nuevo())
		f.add_child(mas)
		f.add_child(_texto(Grupo.AYUDA[k], 16, COLOR_SUAVE))
		izq.add_child(f)

	# derecha: equipo
	var der := VBoxContainer.new()
	der.add_theme_constant_override("separation", 3)   # 3 y no 6: con la octava ranura (Accesorio, T-092) y el equipo de
	columnas.add_child(der)                             # siempre, se ve entera sin desplazar la lista
	var titulo := HBoxContainer.new()                 # «Equipo» y, a su lado, qué armas lleva (antes iba debajo de todo y,
	titulo.add_theme_constant_override("separation", 18)   # con la octava ranura, se salía de la lista)
	titulo.add_child(_texto("Equipo", 26, COLOR_TITULO))
	var tipo: String = Grupo.tipo_arma(heroe)
	var pista := _texto("Arma: solo %s." % ("espadas" if tipo == "espada" else "cetros"), 16, COLOR_SUAVE)
	pista.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titulo.add_child(pista)
	der.add_child(titulo)
	var lleva: Dictionary = Inv.equipo_de(heroe)
	for r in Inv.RANURAS:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		var nr := _texto(Inv.NOMBRES_RANURA[r], 20, COLOR_SUAVE)
		nr.custom_minimum_size = Vector2(90, 0)
		f.add_child(nr)
		var ranura: String = r
		var atras := _boton("◀", 18, Vector2(36, 34), "ranura:%s:-1" % r)
		atras.pressed.connect(func(): _cambiar(ranura, -1))
		f.add_child(atras)
		var id: String = lleva.get(r, "")
		var nombre := _texto(Inv.objeto(id).get("nombre", "—") if id != "" else "—", 20, COLOR_TEXTO)   # un id desconocido: «—»
		nombre.custom_minimum_size = Vector2(220, 0)
		var icono: Control = load("res://icono_equipo.gd").para(id) if id != "" else null   # V12, accesorios: rareza
		if icono != null:                             # (icono y color; sin rareza, como siempre)
			nombre.add_theme_color_override("font_color", load("res://equipo_extra.gd").rareza(id)["color"])
			nombre.custom_minimum_size = Vector2(220 - icono.custom_minimum_size.x - 8, 0)
			f.add_child(icono)
		f.add_child(nombre)
		var adelante := _boton("▶", 18, Vector2(36, 34), "ranura:%s:1" % r)
		adelante.pressed.connect(func(): _cambiar(ranura, 1))
		f.add_child(adelante)
		der.add_child(f)
		if id != "" and Inv.resumen(id) != "":
			der.add_child(_texto("      " + Inv.resumen(id), 16, COLOR_BIEN))


# V12: abre el Firmamento de los Ecos del héroe de la ficha, encima del menú; al cerrarlo, la ficha se repinta (las
# bonificaciones nuevas ya salen en sus estadísticas). Mientras está abierto, este menú no atiende al teclado.
func _abrir_firmamento() -> void:
	var fi = load("res://firmamento/firmamento.gd").new()
	fi.heroe = heroe
	set_process_unhandled_input(false)
	fi.cerrado.connect(func():
		set_process_unhandled_input(true)
		_pintar_de_nuevo())
	add_child(fi)


# ---------------------------------------------------------------- V12: Formación (activos y reserva)
# Solo sale si hay reserva o más miembros que sitios (grupo.gd hay_formacion): con los tres de siempre, nunca. Una
# tarjeta por miembro (retrato, nivel, PV y PM) con su botón «Al grupo» / «A la reserva». Kael va siempre en el grupo
# (grupo.gd KAEL_SIEMPRE_ACTIVO, pendiente del usuario). Botones grandes para el dedo; con teclado o mando, el foco
# pasa de botón en botón y Esc / B vuelve a la ficha.
const RETRATOS := {"Kael": "res://dialogos/retratos/kael_reposo.png", "Lya": "res://dialogos/retratos/lya_reposo.png",
	"Garon": "res://dialogos/retratos/garon_reposo.png",
	"Naira": "res://personajes/naira/naira_retrato_provisional.png",   # el de Naira, PROVISIONAL (de su modelo)
	"Nix": "res://personajes/nix/nix_retrato.png"}   # V12: el de Nix, PROTOTIPO (render de su modelo)


func _pintar_formacion() -> void:
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 18)
	cuerpo.add_child(arriba)
	arriba.add_child(_texto("Formación", 26, COLOR_TITULO))
	var activos: Array = Grupo.activos()
	var cuenta := _texto("En el grupo: %d de %d" % [activos.size(), Grupo.MAX_ACTIVOS], 20, COLOR_TEXTO)
	cuenta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arriba.add_child(cuenta)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	var volver := _boton("Volver", 20, Vector2(150, 40), "formacion_volver")
	volver.pressed.connect(_salir_formacion)
	arriba.add_child(volver)
	var ayuda := "Combaten los del grupo; la reserva viaja con vosotros, descansa y gana la mitad de la experiencia."
	if Grupo.KAEL_SIEMPRE_ACTIVO:
		ayuda += " Kael va siempre."
	cuerpo.add_child(_texto(ayuda, 16, COLOR_SUAVE))
	if aviso_formacion != "":
		cuerpo.add_child(_texto(aviso_formacion, 18, Estilo.ORO))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	cuerpo.add_child(fila)
	for n in Grupo.en_el_grupo():
		fila.add_child(_tarjeta_formacion(n, n in activos))


func _tarjeta_formacion(n: String, activo: bool) -> Control:
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(236, 0)          # 4 × 236 + 3 × 14 caben en la lista (1080 px con su barra)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(Estilo.SOMBRA, 0.75 if activo else 0.45)
	fondo.border_color = Color(Estilo.ORO, 0.8 if activo else 0.25)
	fondo.set_border_width_all(2 if activo else 1)
	fondo.set_corner_radius_all(8)
	fondo.set_content_margin_all(10)
	caja.add_theme_stylebox_override("panel", fondo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	caja.add_child(v)
	var ret := TextureRect.new()
	ret.custom_minimum_size = Vector2(212, 215)
	ret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if RETRATOS.has(n) and ResourceLoader.exists(RETRATOS[n]):
		ret.texture = load(RETRATOS[n])
	if not activo:
		ret.modulate = Color(0.6, 0.6, 0.65)
	v.add_child(ret)
	var d: Dictionary = Grupo.datos()[n]
	var e: Dictionary = Grupo.estadisticas(n)
	v.add_child(_texto(n, 24, COLOR_TITULO if activo else COLOR_TEXTO))
	v.add_child(_texto("%s · nivel %d" % [Grupo.HEROES[n]["clase"], int(d["nivel"])], 17, COLOR_SUAVE))
	v.add_child(_texto("PV %d/%d   PM %d/%d" % [e["pv"], e["pv_max"], e["pm"], e["pm_max"]], 17, COLOR_SUAVE))
	v.add_child(_texto("En el grupo" if activo else "En la reserva", 19, COLOR_BIEN if activo else COLOR_SUAVE))
	var quiere: Array = Grupo.activos()
	if activo:
		quiere.erase(n)
	else:
		quiere.append(n)
	var motivo: String = Grupo.motivo_formacion(quiere)
	var b := _boton("A la reserva" if activo else "Al grupo", 20, Vector2(212, 48), "formacion:" + n)
	b.disabled = motivo != ""
	b.tooltip_text = motivo
	b.pressed.connect(func():
		aviso_formacion = Grupo.alternar(n)
		Sonido.efecto("ui_confirmar" if aviso_formacion == "" else "ui_tic")
		_pintar_de_nuevo())
	v.add_child(b)
	if motivo != "":
		var nota := _texto(_motivo_corto(motivo), 15, COLOR_SUAVE)
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # en dos líneas: la tarjeta no se ensancha
		nota.custom_minimum_size = Vector2(212, 0)
		v.add_child(nota)
	return caja


func _motivo_corto(motivo: String) -> String:
	if motivo.begins_with("Solo caben"):
		return "Grupo lleno: pasa antes a alguien a la reserva."
	return motivo + "."


func _salir_formacion() -> void:
	vista_formacion = false
	aviso_formacion = ""
	Sonido.efecto("ui_tic")
	_pintar_de_nuevo()


# Pasa al objeto anterior o siguiente que puede llevar en esa ranura (o a ninguno).
func _cambiar(ranura: String, paso: int) -> void:
	var lista: Array = [""] + Inv.opciones(heroe, ranura)
	if ranura == "arma":
		lista.erase("")                            # siempre lleva un arma
	var actual: String = Inv.equipo_de(heroe).get(ranura, "")
	var i := lista.find(actual)
	var nuevo: String = lista[posmod(i + paso, lista.size())]
	Inv.equipar(heroe, ranura, nuevo)
	Sonido.efecto("ui_equipar_arma" if ranura == "arma" else "ui_equipar")
	_pintar_de_nuevo()


# ---------------------------------------------------------------- Objetos

func _pintar_objetos() -> void:
	cuerpo.add_child(_texto("Objetos", 26, COLOR_TITULO))
	cuerpo.add_child(_texto("Monedas: %d" % Inv.oro(), 22, COLOR_TITULO))
	# Talleres (fase 3 y V9): la alquimia de Lya al descubrirla; la forja de Kael, las armaduras de Garon y el taller
	# conjunto tras resolver lo del Guardián del Bosque. Cada uno, con su héroe (o los tres) en el grupo.
	var P = load("res://progreso.gd")
	var activos: Array = load("res://grupo.gd").activos()
	var talleres := HBoxContainer.new()
	talleres.add_theme_constant_override("separation", 8)
	for t in [["alquimia", "Alquimia de Lya", P.hito("bq_alquimia") and activos.has("Lya")],
			["forja", "Forja de Kael", P.hito("bq_resuelto") and activos.has("Kael")],
			["armaduras", "Runas de Garon", P.hito("bq_resuelto") and activos.has("Garon")],
			["conjunto", "Taller conjunto", P.hito("bq_resuelto") and activos.has("Kael") and activos.has("Lya") and activos.has("Garon")]]:
		if not t[2]:
			continue
		var cual: String = t[0]
		var b := _boton(t[1], 18, Vector2(200, 40), cual)
		b.pressed.connect(func():
			Sonido.efecto("ui_tic")
			var a = load("res://alquimia_menu.gd").new()
			a.taller = cual
			a.cerrado.connect(_pintar_de_nuevo)
			get_tree().root.add_child(a))
		talleres.add_child(b)
	if talleres.get_child_count() > 0:
		cuerpo.add_child(talleres)
	else:
		talleres.free()                            # (rend3, 13/11: sin talleres quedaba huérfana, una por repintado)
	var usos: Dictionary = load("res://combate.gd").OBJETOS_COMBATE
	for o in Inv.datos()["objetos"]:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 12)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(40, 48)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if usos.has(o) and ResourceLoader.exists(usos[o]["imagen"]):
			ic.texture = load(usos[o]["imagen"])
		f.add_child(ic)
		var nombre := _texto("%s   x%d" % [o, Inv.cantidad(o)], 20, COLOR_TEXTO)
		nombre.custom_minimum_size = Vector2(200, 0)
		f.add_child(nombre)
		var Progreso = load("res://progreso.gd")
		if o == Progreso.INCIENSO:                   # quita los encuentros un rato
			f.add_child(_texto("Sin encuentros durante %d pasos" % Progreso.PASOS_INCIENSO, 18, COLOR_BIEN))
			var usar := _boton("Usar", 16, Vector2(110, 32), "usar:" + o)
			usar.disabled = Inv.cantidad(o) <= 0 or Progreso.incienso_activo()
			if Progreso.incienso_activo():
				usar.text = "Encendido"
			usar.pressed.connect(func():
				if Inv.cantidad(Progreso.INCIENSO) > 0:
					Inv.gastar(Progreso.INCIENSO)
					Progreso.usar_incienso()
					Sonido.efecto("ui_confirmar")
					_pintar_de_nuevo())
			f.add_child(usar)
		if usos.has(o):
			f.add_child(_texto("Recupera %d %s" % [usos[o]["cura"], usos[o]["que"]], 18, COLOR_BIEN))
			var objeto: String = o
			for n in Grupo.activos():               # usarlo fuera del combate
				var b := _boton("Dar a %s" % n, 16, Vector2(110, 32), "dar:%s:%s" % [o, n])
				var heroe_n: String = n
				b.disabled = Inv.cantidad(o) <= 0
				b.pressed.connect(func(): _usar_fuera(objeto, heroe_n))
				f.add_child(b)
		cuerpo.add_child(f)
	cuerpo.add_child(_texto("Equipo", 26, COLOR_TITULO))
	for r in Inv.RANURAS:
		for id in Inv.datos()["equipables"]:
			var o: Dictionary = Inv.objeto(id)
			if o.get("ranura", "") != r:               # (un id desconocido, de una versión más nueva, no sale)
				continue
			var f := HBoxContainer.new()
			f.add_theme_constant_override("separation", 14)
			var n := _texto(o["nombre"], 20, COLOR_TEXTO)
			n.custom_minimum_size = Vector2(260, 0)
			var icono: Control = load("res://icono_equipo.gd").para(id)   # V12, accesorios: rareza (icono y color)
			if icono != null:
				n.add_theme_color_override("font_color", load("res://equipo_extra.gd").rareza(id)["color"])
				n.custom_minimum_size = Vector2(260 - icono.custom_minimum_size.x - 14, 0)
				f.add_child(icono)
			f.add_child(n)
			var t := _texto(Inv.NOMBRES_RANURA[r], 18, COLOR_SUAVE)
			t.custom_minimum_size = Vector2(100, 0)
			f.add_child(t)
			var res := _texto(Inv.resumen(id), 18, COLOR_BIEN)
			res.custom_minimum_size = Vector2(300, 0)
			f.add_child(res)
			var quien: String = Inv.quien_lleva(id)
			var para := {"todos": "Todos", "espada": "Espadachines", "cetro": "Magos"}
			var de_quien: String = ("Solo " + o["solo"]) if o.has("solo") else para.get(o["para"], "")   # armas especiales
			f.add_child(_texto(("Lo lleva %s" % quien) if quien != "" else de_quien, 18, COLOR_SUAVE))
			cuerpo.add_child(f)


# Usar una poción o un éter desde el menú (sin combate).
func _usar_fuera(objeto: String, heroe_n: String) -> void:
	var u: Dictionary = load("res://combate.gd").OBJETOS_COMBATE[objeto]
	var e: Dictionary = Grupo.estadisticas(heroe_n)
	var pv: int = e["pv"]
	var pm: int = e["pm"]
	if u["que"] == "PV":
		if pv >= e["pv_max"]:
			return
		pv = mini(e["pv_max"], pv + u["cura"])
	else:
		if pm >= e["pm_max"]:
			return
		pm = mini(e["pm_max"], pm + u["cura"])
	Inv.gastar(objeto)
	Grupo.guardar_vida(heroe_n, pv, pm)
	Sonido.efecto("pocion", {"tono": 1.0 if u["que"] == "PV" else 1.12})
	_pintar_de_nuevo()


# ---------------------------------------------------------------- Habilidades

func _pintar_habilidades() -> void:
	var niveles: Dictionary = load("res://combate.gd").NIVELES_MAGIA
	var Artes = load("res://artes.gd")              # artes (T-091): solo los niveles que ya están en el juego
	var romano := ["I", "II", "III"]
	var MN = load("res://magia_negra.gd")           # V12: la magia negra de Naira (sin ella, nadie la sabe)
	var reserva: Array = Grupo.reserva()
	for n in Grupo.en_el_grupo():                   # (la reserva también: sin reserva, los activos de siempre)
		cuerpo.add_child(_texto("%s (nivel %d)%s" % [n, Grupo.datos()[n]["nivel"], "  · reserva" if n in reserva else ""],
			24, COLOR_TITULO))
		var familias_negra: Array = MN.familias_de(n)
		if Grupo.HEROES[n]["magias"].is_empty() and familias_negra.is_empty():
			cuerpo.add_child(_texto("   No usa magia.", 18, COLOR_SUAVE))
		for fam in familias_negra:                  # V12: escuela por escuela, con lo que sabe y cuándo aprende el resto
			var sabe_n: int = MN.nivel(n, fam)
			for i in MN.cuantos(fam):
				var d: Dictionary = MN.datos(fam, i + 1)
				var texto := "   %s — %s, %d PM, %s%s" % [MN.NOMBRE_ESCUELA[fam], d["nombre"], int(d["coste"]),
					"a todos" if d["a"] == "enemigos" else "a uno", ", se prepara" if float(d.get("prep", 0.0)) > 0.0 else ""]
				if i < sabe_n:
					cuerpo.add_child(_texto(texto + "   ✔", 18, COLOR_BIEN))
				elif d.has("investigacion") and int(Grupo.datos()[n]["nivel"]) >= int(d["umbral"]):
					cuerpo.add_child(_texto(texto + "   (falta su investigación)", 18, COLOR_SUAVE))
				else:
					cuerpo.add_child(_texto(texto + "   (se aprende al nivel %d)" % int(d["umbral"]), 18, COLOR_SUAVE))
		for m in Grupo.HEROES[n]["magias"]:
			var tiene: int = Grupo.nivel_magia(n, m)
			for i in 3:
				var d: Dictionary = niveles[m][i]
				var texto := "   %s %s — %s, %d PM, %s" % [m, romano[i], d["nombre"], d["coste"], "a todos" if d["todos"] else "a uno"]
				if i < tiene:
					cuerpo.add_child(_texto(texto + "   ✔", 18, COLOR_BIEN))
				else:
					cuerpo.add_child(_texto(texto + "   (se aprende al nivel %d)" % Grupo.NIVEL_MAGIA[i], 18, COLOR_SUAVE))
		for fam in Artes.familias_de(n):
			var sabe: int = Artes.nivel(n, fam)
			for i in int(Artes.ACTIVOS.get(fam, 0)):
				var d: Dictionary = Artes.datos(fam, i + 1)
				var texto := "   %s %s — %s, %d PM, %s" % [fam, romano[i], d["nombre"], d["coste"], "a todos" if d["todos"] else "a uno"]
				if i < sabe:
					cuerpo.add_child(_texto(texto + "   ✔", 18, COLOR_BIEN))
				else:
					cuerpo.add_child(_texto(texto + "   (se aprende al nivel %d)" % Artes.UMBRALES[fam][i], 18, COLOR_SUAVE))


# ---------------------------------------------------------------- Ajustes

# AJUSTES_19_11: en Ajustes, una pulsación ya no repinta la pestaña entera (≈75-90 ms por pulsación en el PC, medido;
# en el Redmi, más: un parón visible), solo lo suyo: la fila de volumen tocada (_volumen_en_su_fila) o las marcas de
# su selector (_remarcar; en «Calidad gráfica», el bloque entero, porque el perfil cambia los FPS y la nota). Los
# botones son los mismos, así que el foco (teclado, mando o dedo) no se mueve y la lista no salta arriba. Nada de lo
# demás de la pestaña depende de lo que se toca (cada selector lee lo suyo); prueba_ajustes_parcial lo comprueba
# botón a botón contra un repintado entero. _pintar_de_nuevo sigue rehaciendo todo (al cambiar de pestaña, etc.).
var _filas_volumen := {}                         # bus → [cifra (Label), barra (Control)] de su fila


# Un selector de Ajustes: «● » delante de la opción en uso y «○ » delante de las demás. «leer» devuelve la opción en
# uso (se lee una vez al pintar y otra al pulsar). Sus botones se crean con _opcion y, al pulsarlos, _remarcar(sel).
func _selector(leer: Callable) -> Dictionary:
	return {"leer": leer, "en_uso": leer.call(), "botones": []}


func _opcion(sel: Dictionary, valor, texto: String, tam: int, minimo: Vector2, clave: String) -> Button:
	var b := _boton(("● " if valor == sel["en_uso"] else "○ ") + texto, tam, minimo, clave)
	sel["botones"].append([b, valor, texto])
	return b


# Vuelve a leer la opción en uso y cambia solo el texto de sus botones (lo mismo que saldría al repintar).
func _remarcar(sel: Dictionary) -> void:
	var en_uso = sel["leer"].call()
	sel["en_uso"] = en_uso
	for o in sel["botones"]:
		if is_instance_valid(o[0]):
			o[0].text = ("● " if o[1] == en_uso else "○ ") + o[2]
	_sin_resalte()


# Con el dedo o el ratón, el botón que queda bajo el puntero se ve sin resalte (la línea brillante de «hover»), como
# cuando la pestaña se repintaba entera: el botón era nuevo y no se resaltaba hasta mover el puntero. Así un toque en
# el móvil deja ◀ ▶ y las opciones como antes (capturas del 19/11). Con el ratón vuelve a resaltarse al salir y entrar.
func _sin_resalte() -> void:
	var v := get_viewport()
	var h = v.gui_get_hovered_control() if v != null and v.has_method("gui_get_hovered_control") else null
	if h is BaseButton and cuerpo.is_ancestor_of(h):
		h.notification(NOTIFICATION_MOUSE_EXIT)


# El volumen de cada parte del sonido (sonido.gd): ◀ ▶ lo bajan o suben un 10 % y suena una muestra. Se guarda en
# este aparato, aparte de la partida.
func _pintar_ajustes() -> void:
	_filas_volumen = {}
	cuerpo.add_child(_texto("Sonido", 26, COLOR_TITULO))
	for bus in Sonido.VISIBLES:
		var b: String = bus
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		var nombre := _texto(Sonido.NOMBRES[b], 20, COLOR_TEXTO)
		nombre.custom_minimum_size = Vector2(130, 0)
		f.add_child(nombre)
		var menos := _boton("◀", 18, Vector2(36, 34), "volumen:%s:-1" % b)
		menos.pressed.connect(func(): _cambiar_volumen(b, -1))
		f.add_child(menos)
		var v: int = Sonido.volumen(b)
		var cifra := _texto(("%d %%" % v) if v > 0 else "Sin sonido", 20, COLOR_TEXTO if v > 0 else COLOR_SUAVE)
		cifra.custom_minimum_size = Vector2(130, 0)
		cifra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		f.add_child(cifra)
		var mas := _boton("▶", 18, Vector2(36, 34), "volumen:%s:1" % b)
		mas.pressed.connect(func(): _cambiar_volumen(b, 1))
		f.add_child(mas)
		var barra := _barra(v)
		f.add_child(barra)
		f.add_child(_texto("   " + Sonido.AYUDA[b], 16, COLOR_SUAVE))
		cuerpo.add_child(f)
		_filas_volumen[b] = [cifra, barra]
	cuerpo.add_child(_texto("Se guarda en este aparato, aparte de la partida.", 16, COLOR_SUAVE))
	# El mapa del mundo pintado o el de siempre (T-085), solo en la versión experimental: para comparar en el móvil.
	# Se guarda en el mismo archivo de ajustes (mapa_arte.gd, sección [mapa]) y se nota al volver a abrir el mapa.
	if load("res://modo3d.gd").activo():
		var arte = load("res://mapa_arte/mapa_arte.gd")
		var sel_mapa := _selector(func(): return arte.clasico_elegido())
		cuerpo.add_child(_texto("Mapa del mundo", 26, COLOR_TITULO))
		var fm := HBoxContainer.new()
		fm.add_theme_constant_override("separation", 8)
		for op in [[false, "Pintado"], [true, "De siempre"]]:
			var es_clasico: bool = op[0]
			var b := _opcion(sel_mapa, es_clasico, op[1], 18, Vector2(200, 34),
				"mapa:%s" % ("clasico" if es_clasico else "pintado"))
			b.pressed.connect(func():
				arte.elegir("clasico", es_clasico)
				Sonido.efecto("ui_tic")
				_remarcar(sel_mapa))
			fm.add_child(b)
		cuerpo.add_child(fm)
		cuerpo.add_child(_texto("Se nota la próxima vez que se abre el mapa.", 16, COLOR_SUAVE))
		# La Garganta del Diablo (T-095). V12, migración de la Garganta (12/11): la 3D va por defecto y la 2D de siempre
		# se puede elegir (modo3d.gd, POR_DEFECTO_2D_ELEGIBLE). Solo cambian el botón marcado (la versión en uso) y el
		# texto y orden de las dos opciones.
		var m3d = load("res://modo3d.gd")
		var sel_g := _selector(func(): return m3d.region_activa(m3d.GARGANTA))
		cuerpo.add_child(_texto("Garganta del Diablo", 26, COLOR_TITULO))
		var fg := HBoxContainer.new()
		fg.add_theme_constant_override("separation", 8)
		for op in [[true, "3D"], [false, "2D (la de siempre)"]]:
			var en_3d: bool = op[0]
			var bg := _opcion(sel_g, en_3d, op[1], 18, Vector2(240, 34),
				"garganta:%s" % ("3d" if en_3d else "2d"))
			bg.pressed.connect(func():
				m3d.elegir("garganta3d", en_3d)
				Sonido.efecto("ui_tic")
				_remarcar(sel_g))
			fg.add_child(bg)
		cuerpo.add_child(fg)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en la Garganta.", 16, COLOR_SUAVE))
		_pintar_calidad()
		# La invocación de Érebo (T-101): la de siempre o la nueva, en pruebas (invocacion_erebo_nueva.gd).
		var ere = load("res://invocacion_erebo_nueva.gd")
		var sel_e := _selector(func(): return ere.elegida())
		cuerpo.add_child(_texto("Invocación de Érebo", 26, COLOR_TITULO))
		var fe := HBoxContainer.new()
		fe.add_theme_constant_override("separation", 8)
		for op in [[false, "La de siempre"], [true, "Nueva (en pruebas)"]]:
			var es_nueva: bool = op[0]
			var be := _opcion(sel_e, es_nueva, op[1], 18, Vector2(240, 34),
				"erebo:%s" % ("nueva" if es_nueva else "actual"))
			be.pressed.connect(func():
				ere.elegir(es_nueva)
				Sonido.efecto("ui_tic")
				_remarcar(sel_e))
			fe.add_child(be)
		cuerpo.add_child(fe)
		cuerpo.add_child(_texto("Se nota la próxima vez que Lya invoca a Érebo.", 16, COLOR_SUAVE))
		# Oakhaven en 3D (T-103). V12, migración de Oakhaven (12/11): la 3D completa va por defecto y la 2D de siempre se
		# puede elegir (modo3d.gd, POR_DEFECTO_2D_ELEGIBLE), como la Garganta: solo cambian el botón marcado (la versión en
		# uso) y el texto y orden de las dos opciones.
		var sel_o := _selector(func(): return m3d.region_activa(m3d.OAKHAVEN))
		cuerpo.add_child(_texto("Oakhaven", 26, COLOR_TITULO))
		var fo := HBoxContainer.new()
		fo.add_theme_constant_override("separation", 8)
		for op in [[true, "3D"], [false, "2D (la de siempre)"]]:
			var en_3d: bool = op[0]
			var bo := _opcion(sel_o, en_3d, op[1], 18, Vector2(240, 34),
				"oakhaven:%s" % ("3d" if en_3d else "2d"))
			bo.pressed.connect(func():
				m3d.elegir("oakhaven3d", en_3d)
				Sonido.efecto("ui_tic")
				_remarcar(sel_o))
			fo.add_child(bo)
		cuerpo.add_child(fo)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en Oakhaven.", 16, COLOR_SUAVE))
		# --- V12, migración del Gran Bosque Verde (12/11) --- el bosque 3D va por defecto y la 2D de siempre se puede
		# elegir (modo3d.gd, POR_DEFECTO_2D_ELEGIBLE), como la Garganta y Oakhaven.
		var sel_b := _selector(func(): return m3d.region_activa(m3d.GRAN_BOSQUE))
		cuerpo.add_child(_texto("Gran Bosque Verde", 26, COLOR_TITULO))
		var fb := HBoxContainer.new()
		fb.add_theme_constant_override("separation", 8)
		for op in [[true, "3D"], [false, "2D (la de siempre)"]]:
			var en_3d: bool = op[0]
			var bb := _opcion(sel_b, en_3d, op[1], 18, Vector2(240, 34),
				"granbosque:%s" % ("3d" if en_3d else "2d"))
			bb.pressed.connect(func():
				m3d.elegir("granbosque3d", en_3d)
				Sonido.efecto("ui_tic")
				_remarcar(sel_b))
			fb.add_child(bb)
		cuerpo.add_child(fb)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en el Gran Bosque.", 16, COLOR_SUAVE))
		# --- fin del bloque del Gran Bosque Verde ---
		# El Mar de Cristal (V12), en pruebas: el primer sector del Mar de Arena de Calid en 3D.
		var sel_mc := _selector(func(): return m3d.elegida("mardecristal"))
		cuerpo.add_child(_texto("Mar de Arena de Calid", 26, COLOR_TITULO))
		var fm3 := HBoxContainer.new()
		fm3.add_theme_constant_override("separation", 8)
		for op in [[false, "2D (la de siempre)"], [true, "Mar de Cristal 3D (en pruebas)"]]:
			var en_3d: bool = op[0]
			var bm := _opcion(sel_mc, en_3d, op[1], 18, Vector2(300, 34),
				"mardecristal:%s" % ("3d" if en_3d else "2d"))
			bm.pressed.connect(func():
				m3d.elegir("mardecristal", en_3d)
				Sonido.efecto("ui_tic")
				_remarcar(sel_mc))
			fm3.add_child(bm)
		cuerpo.add_child(fm3)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en el Mar de Arena.", 16, COLOR_SUAVE))
		load("res://zonas3d/ciclopea_3d.gd").opcion_ajustes(self, cuerpo)   # V12 (13/11): Cumbres de Ciclópea 3D, en pruebas
		load("res://zonas3d/sunken_3d.gd").opcion_ajustes(self, cuerpo)   # V12 (15/11): Sunken City 3D, en pruebas (solo Auditoría/editor)
		load("res://zonas3d/mapamundi_3d.gd").opcion_ajustes(self, cuerpo)   # V12, mapamundi 3D: en pruebas, apagado (solo Auditoría/editor)
	# La pantalla de inicio (11/11): desde el 11/11 por la noche, el usuario eligió la nueva como la de siempre; la original
	# sigue entera y se puede volver a ella aquí, en cualquier versión (portada/eleccion.gd, [portada]).
	var por = load("res://portada/eleccion.gd")
	var sel_p := _selector(func(): return por.elegida())
	cuerpo.add_child(_texto("Pantalla de inicio", 26, COLOR_TITULO))
	var fp := HBoxContainer.new()
	fp.add_theme_constant_override("separation", 8)
	for op in [[true, "Nueva"], [false, "Original"]]:
		var es_alt: bool = op[0]
		var bp := _opcion(sel_p, es_alt, op[1], 18, Vector2(260, 34),
			"portada:%s" % ("alternativa" if es_alt else "original"))
		bp.pressed.connect(func():
			por.elegir(es_alt)
			Sonido.efecto("ui_tic")
			_remarcar(sel_p))
		fp.add_child(bp)
	cuerpo.add_child(fp)
	cuerpo.add_child(_texto("Se nota la próxima vez que se abre el juego.", 16, COLOR_SUAVE))
	# La música de Pastos Verdes (11/11): «Pastoral Pulse», la elegida por el usuario, o solo el ambiente de siempre
	# (musica.gd, MUSICA_PASTOS). Solo si el archivo está en esta versión (es privado: pruebas).
	var Mu = load("res://musica.gd")
	if ResourceLoader.exists(Mu.CONTEXTOS["pradera_musica"]["musica"]):
		var sel_mu := _selector(func(): return Mu.musica_pastos_elegida())
		cuerpo.add_child(_texto("Música de Pastos Verdes", 26, COLOR_TITULO))
		var fmp := HBoxContainer.new()
		fmp.add_theme_constant_override("separation", 8)
		for op in [[true, "Pastoral Pulse"], [false, "Solo ambiente"]]:
			var nueva: bool = op[0]
			var bmp := _opcion(sel_mu, nueva, op[1], 18, Vector2(260, 34),
				"musica_pastos:%s" % ("nueva" if nueva else "ambiente"))
			bmp.pressed.connect(func():
				Mu.elegir_musica_pastos(nueva)
				Sonido.efecto("ui_tic")
				_remarcar(sel_mu))
			fmp.add_child(bmp)
		cuerpo.add_child(fmp)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en Pastos Verdes.", 16, COLOR_SUAVE))
	# Bramavidrio (11/11): la versión nueva («la Sierpe de la Vela») o la anterior (el gusano de anillos), para que el
	# usuario las compare antes de decidir (enemigos/bramavidrio/bramavidrio_version.gd, [bramavidrio] version).
	# 12/11: y la prueba de la versión 3 («el Excavador», boca articulada); la de por defecto sigue siendo la 2.
	# 12/11: y la prueba de la versión 4 («el Ancestral», el gusano de la lámina del usuario, boca circular).
	# 12/11, noche: y la prueba de la versión 5 («la v4 resuelta»: mandíbulas, colmillos y movimientos). Con cinco
	# opciones la fila no cabe en el ancho de Ajustes (1080): van en un HFlowContainer, que las pasa a otra fila.
	var BV = load("res://enemigos/bramavidrio/bramavidrio_version.gd")
	var sel_bv := _selector(func(): return BV.en_ajustes())
	cuerpo.add_child(_texto("Bramavidrio", 26, COLOR_TITULO))
	var fbv := HFlowContainer.new()
	fbv.add_theme_constant_override("h_separation", 8)
	fbv.add_theme_constant_override("v_separation", 8)
	for op in [[2, "Nuevo (la Sierpe)"], [3, "Prueba v3: el Excavador"], [4, "Prueba v4: el Ancestral"],
			[5, "Prueba v5: la v4 resuelta"], [1, "Anterior"]]:
		var v: int = op[0]
		var bbv := _opcion(sel_bv, v, op[1], 18, Vector2(300 if v in [3, 4, 5] else 260, 34), "bramavidrio:%d" % v)
		bbv.pressed.connect(func():
			BV.elegir_en_ajustes(v)
			Sonido.efecto("ui_tic")
			_remarcar(sel_bv))
		fbv.add_child(bbv)
	cuerpo.add_child(fbv)
	cuerpo.add_child(_texto("Se nota en el próximo encuentro con Bramavidrio.", 16, COLOR_SUAVE))
	# Protagonistas (13/11): los modelos de siempre, los «héroes v2» o (V12) los «héroes v3» en prueba
	# (personajes/heroes_v2/heroes_v2.gd, [heroes] version), para que el usuario los compare en el móvil. Por defecto,
	# los originales.
	var HV = load("res://personajes/heroes_v2/heroes_v2.gd")
	var sel_hv := _selector(func(): return HV.version())
	cuerpo.add_child(_texto("Protagonistas", 26, COLOR_TITULO))
	var fhv := HBoxContainer.new()
	fhv.add_theme_constant_override("separation", 8)
	for op in [["originales", "Originales"], ["v2", "v2 (prueba)"], ["v3", "v3 (prueba)"]]:
		var vh: String = op[0]
		var bhv := _opcion(sel_hv, vh, op[1], 18, Vector2(220, 34), "heroes:%s" % vh)
		bhv.pressed.connect(func():
			HV.elegir_version(vh)
			Sonido.efecto("ui_tic")
			_remarcar(sel_hv))
		fhv.add_child(bhv)
	cuerpo.add_child(fhv)
	cuerpo.add_child(_texto("Se nota en el próximo combate o al entrar en una región.", 16, COLOR_SUAVE))
	# V12: Firmamento de los Ecos (firmamento/orbes.gd, [firmamento] activo). Solo en Auditoría o en el editor, para
	# compararlo en el móvil; en las versiones normales no sale (y el interruptor no lee Ajustes).
	var Orb = load("res://firmamento/orbes.gd")
	if Orb.herramienta_dev():
		var sel_orb := _selector(func(): return Orb.activo())
		cuerpo.add_child(_texto("Firmamento de los Ecos (prueba)", 26, COLOR_TITULO))
		var fob := HBoxContainer.new()
		fob.add_theme_constant_override("separation", 8)
		for op in [[false, "Apagado"], [true, "Encendido"]]:
			var so: bool = op[0]
			var bo := _opcion(sel_orb, so, op[1], 18, Vector2(260, 34), "orbes:%s" % ("si" if so else "no"))
			bo.pressed.connect(func():
				Orb.elegir_en_ajustes(so)
				Sonido.efecto("ui_tic")
				_remarcar(sel_orb))
			fob.add_child(bo)
		cuerpo.add_child(fob)
		cuerpo.add_child(_texto("Solo Auditoría: tablero de Orbes Cristalinos en la ficha del Grupo.", 16, COLOR_SUAVE))
	# V12 (13/11, pruebas en el Redmi): las mejoras del Gran Bosque que van APAGADAS (prototipos/calidad_proto.gd,
	# EXTRA_PRUEBAS; [calidad_pruebas] de user://ajustes.cfg). Solo en Auditoría o en el editor.
	var CP = load("res://prototipos/calidad_proto.gd")
	if CP.pruebas_permitidas():
		cuerpo.add_child(_texto("Gran Bosque: pruebas de rendimiento", 26, COLOR_TITULO))
		for clave in CP.EXTRA_PRUEBAS:
			var k: String = clave
			var sel_gb := _selector(func(): return CP.extra_activo(k))
			var fgb := HBoxContainer.new()
			fgb.add_theme_constant_override("separation", 8)
			fgb.add_child(_texto(CP.EXTRA_PRUEBAS[k]["nombre"], 18, COLOR_SUAVE))
			for op in [[false, "No"], [true, "Sí"]]:
				var so: bool = op[0]
				var bg := _opcion(sel_gb, so, op[1], 18, Vector2(120, 34), "gb:%s:%s" % [k, "si" if so else "no"])
				bg.pressed.connect(func():
					CP.elegir_extra(k, so)
					Sonido.efecto("ui_tic")
					_remarcar(sel_gb))
				fgb.add_child(bg)
			cuerpo.add_child(fgb)
		cuerpo.add_child(_texto("Solo Auditoría. Se nota al volver a entrar en el Gran Bosque.", 16, COLOR_SUAVE))
		# V12 (14/11): el orbe experimental de Érebo (erebo_orbe_v12.gd), APAGADO por defecto. Solo Auditoría o editor.
		var EO = load("res://erebo_orbe_v12.gd")
		var sel_eo := _selector(func(): return EO.activo())
		var feo := HBoxContainer.new()
		feo.add_theme_constant_override("separation", 8)
		feo.add_child(_texto("Érebo: orbe experimental", 18, COLOR_SUAVE))
		for op in [[false, "No"], [true, "Sí"]]:
			var so: bool = op[0]
			var be := _opcion(sel_eo, so, op[1], 18, Vector2(120, 34), "erebo_orbe:%s" % ("si" if so else "no"))
			be.pressed.connect(func():
				EO.elegir(so)
				Sonido.efecto("ui_tic")
				_remarcar(sel_eo))
			feo.add_child(be)
		cuerpo.add_child(feo)
		cuerpo.add_child(_texto("Solo Auditoría: espiral violeta, negra y plateada al agarrar el orbe. No cambia el daño.", 16, COLOR_SUAVE))
		# V12 (14/11): la invocación cinematográfica en vídeo (invocacion_erebo_video.gd), APAGADA por defecto.
		var EV = load("res://invocacion_erebo_video.gd")
		var EH = load("res://invocacion_erebo_hibrida.gd")   # V12, Érebo híbrida (15/11): su valor, en el mismo selector
		var sel_ev := _selector(func(): return EH.valor_selector())
		var fev := HBoxContainer.new()
		fev.add_theme_constant_override("separation", 6)
		cuerpo.add_child(_texto("Érebo: invocación cinematográfica", 18, COLOR_SUAVE))
		var fhb := HBoxContainer.new()                          # (V12, Érebo híbrida: sus dos valores, en otra línea)
		fhb.add_theme_constant_override("separation", 6)
		for op in [["no", "No"], ["abreviada", "Abreviada"], ["completa", "Completa"], ["primera", "1.ª completa"],
				["hibrida", "Híbrida"], ["hibrida_breve", "Híbrida abreviada"]]:
			var mo: String = op[0]
			var bv := _opcion(sel_ev, mo, op[1], 18, Vector2(140, 34), "erebo_cine:%s" % mo)
			bv.pressed.connect(func():
				EH.elegir_modo(mo)                            # (los del vídeo los guarda el vídeo)
				Sonido.efecto("ui_tic")
				_remarcar(sel_ev))
			(fhb if mo.begins_with("hibrida") else fev).add_child(bv)
		cuerpo.add_child(fev)
		cuerpo.add_child(fhb)
		cuerpo.add_child(_texto("Solo Auditoría: vídeo prerenderizado (≈20 s o ≈7 s). «1.ª completa»: la primera vez entera, luego la abreviada. «Híbrida»: Érebo va hasta el enemigo elegido, le saca un corazón espectral y sigue el ritual del vídeo (≈24 s; «Híbrida abreviada», con el ritual corto, ≈16 s). Tocar la pantalla la salta. No cambia el daño.", 16, COLOR_SUAVE))
		# V12 (14/11), fase 3C: la magia Agua mejorada (vfx/agua_v12.gd), APAGADA por defecto. Solo Auditoría o editor.
		var AGV = load("res://vfx/agua_v12.gd")
		var sel_ag := _selector(func(): return AGV.activo())
		var fag := HBoxContainer.new()
		fag.add_theme_constant_override("separation", 8)
		fag.add_child(_texto("Magia Agua v12", 18, COLOR_SUAVE))
		for op in [[false, "No"], [true, "Sí"]]:
			var so: bool = op[0]
			var ba := _opcion(sel_ag, so, op[1], 18, Vector2(120, 34), "agua_v12:%s" % ("si" if so else "no"))
			ba.pressed.connect(func():
				AGV.elegir(so)
				Sonido.efecto("ui_tic")
				_remarcar(sel_ag))
			fag.add_child(ba)
		cuerpo.add_child(fag)
		cuerpo.add_child(_texto("Solo Auditoría: Agua, Torrente y Maremoto con anticipación, orbe, impacto y ola nuevos. No cambia el daño.", 16, COLOR_SUAVE))
		# V12 (14/11): pilotos de la noche para probar en el Redmi, APAGADOS por defecto (solo Auditoría o editor):
		# Nix (nix_v12, cuarta heroína), su modelo desde el FBX (nix_fbx, sin ropa todavía) y la capa articulada de
		# Garon ([garon] capa, capa_garon.gd). Las tres se leen de user://ajustes.cfg; se notan al entrar en una zona o
		# combate nuevo.
		for op_p in [["Nix (cuarta heroína)", "calidad_pruebas", "nix_v12", true],
				["Nix: modelo FBX (piloto con vestuario)", "calidad_pruebas", "nix_fbx", true],
				["Capa de Garon articulada", "garon", "capa", "articulada"],
				["Oakhaven: misión del cantero (propuesta)", "mundo", "propuestas_v12", true]]:   # 14/11: autorizada en Auditoría
			var sec_p: String = op_p[1]
			var clave_p: String = op_p[2]
			var valor_si = op_p[3]
			var sel_pi := _selector(func():
				var cfg_p := ConfigFile.new()
				return cfg_p.load("user://ajustes.cfg") == OK and str(cfg_p.get_value(sec_p, clave_p, "")) == str(valor_si))
			var f_piloto := HBoxContainer.new()
			f_piloto.add_theme_constant_override("separation", 8)
			f_piloto.add_child(_texto(op_p[0], 18, COLOR_SUAVE))
			for op in [[false, "No"], [true, "Sí"]]:
				var so: bool = op[0]
				var bp := _opcion(sel_pi, so, op[1], 18, Vector2(120, 34), "piloto:%s:%s" % [clave_p, "si" if so else "no"])
				bp.pressed.connect(func():
					var c := ConfigFile.new()
					if FileAccess.file_exists("user://ajustes.cfg"):
						c.load("user://ajustes.cfg")
					c.set_value(sec_p, clave_p, valor_si if so else (false if valor_si is bool else "rigida"))
					c.save("user://ajustes.cfg")
					if clave_p in ["nix_v12", "nix_fbx"]:
						Engine.set_meta(clave_p, so)          # (nix_v12/nix_fbx: la meta manda sobre el archivo)
					Sonido.efecto("ui_tic")
					_remarcar(sel_pi))
				f_piloto.add_child(bp)
			cuerpo.add_child(f_piloto)
		cuerpo.add_child(_texto("Solo Auditoría: pilotos de Nix, de la capa de Garon y la misión propuesta del cantero. Se notan en la siguiente zona o combate.", 16, COLOR_SUAVE))
		# V12 (14/11): desde una exploración del banco de pruebas (banco_pruebas.gd), la vuelta a él. Fuera del banco, no sale.
		var BP = load("res://banco_pruebas.gd")
		if BP.en_banco():
			var bbp := _boton("Volver al banco de pruebas", 20, Vector2(360, 44), "volver_banco")
			bbp.pressed.connect(func():
				_cerrar()
				Recursos.cambiar_escena(BP.ESCENA))
			cuerpo.add_child(bbp)
	load("res://zonas3d/oakhaven/mundo_vivo.gd").opcion_ajustes(self, cuerpo)   # V12, «Oakhaven: mundo vivo» (mundo_vivo_v12)
	# Combate (12/11): la animación de combate v12 de los protagonistas v2 (combate_anim_v12.gd, [combate] anim_v12), sus
	# cámaras ([combate] camaras) y el ATB quieto mientras actúa un héroe ([combate] pausa_atb; 13/11). Por defecto, la de siempre.
	var AV = load("res://combate_anim_v12.gd")
	cuerpo.add_child(_texto("Combate", 26, COLOR_TITULO))
	var fav := HBoxContainer.new()
	fav.add_theme_constant_override("separation", 8)
	var fav2 := HBoxContainer.new()
	fav2.add_theme_constant_override("separation", 8)
	var fav3 := HBoxContainer.new()                     # 13/11: la línea de turnos (combate_turnos_v12.gd; vale con cualquier protagonista)
	fav3.add_theme_constant_override("separation", 8)
	var TV = load("res://combate_turnos_v12.gd")
	var fav4 := HBoxContainer.new()                     # 13/11 noche: esgrima de Garon y magia blanca de Lya (combate_acciones_v12.gd)
	fav4.add_theme_constant_override("separation", 8)
	var fav5 := HBoxContainer.new()
	fav5.add_theme_constant_override("separation", 8)
	var AC = load("res://combate_acciones_v12.gd")
	var sels_av := {}
	for op in [["anim_v12", false, "Animación de siempre"], ["anim_v12", true, "Animación v12 (prueba)"],
			["camaras", true, "Cámaras: sí"], ["camaras", false, "Cámaras: no"],
			["pausa_atb", true, "ATB quieto al actuar: sí"], ["pausa_atb", false, "ATB quieto al actuar: no"],
			["turnos", true, "Línea de turnos: sí"], ["turnos", false, "Línea de turnos: no"],
			["esgrima", true, "Esgrima v12 de Garon: sí"], ["esgrima", false, "Esgrima v12 de Garon: no"],
			["blanca", true, "Magia blanca v12 de Lya: sí"], ["blanca", false, "Magia blanca v12 de Lya: no"]]:
		var cl: String = op[0]
		var si: bool = op[1]
		if not sels_av.has(cl):                         # un selector por ajuste (sus dos botones)
			sels_av[cl] = _selector(func(): return AV.activado() if cl == "anim_v12" else (AV.camaras() if cl == "camaras" else
				(AV.pausa_atb() if cl == "pausa_atb" else (TV.activado() if cl == "turnos" else
				(AC.esgrima_activa() if cl == "esgrima" else AC.blanca_activa())))))
		var sel_av: Dictionary = sels_av[cl]
		var ancho := 300 if cl != "camaras" else 180
		var bav := _opcion(sel_av, si, op[2], 18, Vector2(ancho, 34),
			"combate:%s:%s" % [cl, "si" if si else "no"])
		bav.pressed.connect(func():
			if cl == "turnos":
				TV.elegir_en_ajustes(si)
			elif cl in ["esgrima", "blanca"]:
				AC.elegir_en_ajustes(cl, si)
			else:
				AV.elegir_en_ajustes(cl, si)
			Sonido.efecto("ui_tic")
			_remarcar(sel_av))
		(fav if cl in ["anim_v12", "camaras"] else (fav2 if cl == "pausa_atb" else (fav3 if cl == "turnos" else
			(fav4 if cl == "esgrima" else fav5)))).add_child(bav)
	cuerpo.add_child(fav)
	cuerpo.add_child(fav2)
	cuerpo.add_child(fav3)
	cuerpo.add_child(fav4)
	cuerpo.add_child(fav5)
	cuerpo.add_child(_texto("Animación v12: con los protagonistas v2. «ATB quieto»: las barras esperan mientras actúa un héroe. La línea de turnos vale con cualquiera. Esgrima y magia blanca v12: acciones nuevas de prueba de Garon (Compás) y de Lya. Se nota en el próximo combate.", 16, COLOR_SUAVE))


# Calidad de las regiones 3D (encargo del 09/11; prototipos/calidad_auto.gd, sección [calidad] de user://ajustes.cfg):
# «Automática» deja que el juego elija y ajuste según el aparato; Baja, Media o Alta fijan el perfil y entonces el
# juego no cambia nada solo (lo manual manda). El límite de FPS lo elige el jugador; sin elegir, 30 (60 solo con Alta
# y si el aparato lo aguanta, medido).
const CALIDADES := [["auto", "Automática"], ["bajo", "Baja"], ["medio", "Media"], ["alto", "Alta"]]


func _pintar_calidad() -> void:
	var auto = load("res://prototipos/calidad_auto.gd")
	var cal = load("res://prototipos/calidad_proto.gd")
	var e: Dictionary = auto.estado()
	# (AJUSTES_19_11) el perfil cambia los FPS en uso y la nota: cualquier botón del bloque lo pone al día entero
	var sel_cal := _selector(func(): return _calidad_elegida(auto.estado()))
	var sel_fps := _selector(func(): return _fps_en_uso(auto, cal, auto.estado()))
	var nota := _texto(_nota_calidad(auto, e), 16, COLOR_SUAVE)
	var al_dia := func():
		_remarcar(sel_cal)
		_remarcar(sel_fps)
		nota.text = _nota_calidad(auto, auto.estado())
	cuerpo.add_child(_texto("Calidad gráfica", 26, COLOR_TITULO))
	var fc := HBoxContainer.new()
	fc.add_theme_constant_override("separation", 8)
	for op in CALIDADES:
		var clave: String = op[0]
		var b := _opcion(sel_cal, clave, op[1], 18, Vector2(170, 34), "calidad:" + clave)
		b.pressed.connect(func():
			_elegir_calidad(clave)
			Sonido.efecto("ui_tic")
			al_dia.call())
		fc.add_child(b)
	cuerpo.add_child(fc)
	var ff := HBoxContainer.new()
	ff.add_theme_constant_override("separation", 8)
	var nombre_fps := _texto("Límite de FPS", 20, COLOR_TEXTO)
	nombre_fps.custom_minimum_size = Vector2(170, 0)
	ff.add_child(nombre_fps)
	for n in auto.FPS_VALIDOS:
		var cifra: int = n
		var b := _opcion(sel_fps, cifra, str(cifra), 18, Vector2(110, 34), "fps:%d" % cifra)
		b.pressed.connect(func():
			auto.guardar({"fps": cifra})
			Sonido.efecto("ui_tic")
			al_dia.call())
		ff.add_child(b)
	cuerpo.add_child(ff)
	cuerpo.add_child(nota)


func _calidad_elegida(e: Dictionary) -> String:
	return "auto" if e["auto"] or e["perfil"] == "" else e["perfil"]


func _fps_en_uso(auto, cal, e: Dictionary) -> int:
	return auto.fps_de(cal.actual(), e, int(cal.PERFILES[cal.actual()]["fps"]))


func _nota_calidad(auto, e: Dictionary) -> String:
	var elegida := _calidad_elegida(e)
	var nota := "Se aplica la próxima vez que se entra en una región 3D."
	if elegida == "auto":
		var p: String = auto.perfil_de(e)
		if p != "":
			nota = "Ahora: %s%s. " % [_nombre_calidad(p), ", ya comprobada al jugar" if e["calibrado"] else ""] + nota
	elif e["aviso"] == elegida:
		nota = "En este aparato, %s no llega a sus FPS de forma estable. " % _nombre_calidad(elegida) + nota
	if auto.aislada():                             # (15/11) desde el banco de pruebas de Auditoría
		nota = "Banco de pruebas: vale solo para este caso del banco (no cambia tus ajustes). " + nota
	return nota


func _nombre_calidad(p: String) -> String:
	for op in CALIDADES:
		if op[0] == p:
			return op[1]
	return p


# «auto»: el sistema decide (lo que ya midió se conserva). Otro: el perfil fijado por el jugador.
func _elegir_calidad(clave: String) -> void:
	var auto = load("res://prototipos/calidad_auto.gd")
	if clave == "auto":
		var e: Dictionary = auto.estado()
		auto.guardar({"auto": true, "perfil": e["perfil_auto"] if e["perfil_auto"] != "" else null})
	else:
		auto.guardar({"auto": false, "perfil": clave})


func _cambiar_volumen(bus: String, paso: int) -> void:
	Sonido.fijar(bus, Sonido.volumen(bus) + paso * Sonido.PASO)
	Sonido.probar(bus)
	_volumen_en_su_fila(bus)


# (AJUSTES_19_11) Solo la fila de ese bus: su cifra y su barra, como las pinta _pintar_ajustes. Sin su fila (no es la
# pestaña de Ajustes), la pestaña entera, como antes.
func _volumen_en_su_fila(bus: String) -> void:
	var fila: Array = _filas_volumen.get(bus, [])
	if fila.is_empty() or not is_instance_valid(fila[0]) or not fila[0].is_inside_tree():
		_pintar_de_nuevo()
		return
	var v: int = Sonido.volumen(bus)
	var cifra: Label = fila[0]
	cifra.text = ("%d %%" % v) if v > 0 else "Sin sonido"
	cifra.add_theme_color_override("font_color", COLOR_TEXTO if v > 0 else COLOR_SUAVE)
	var barra := _barra(v)                          # la barra, nueva en el mismo sitio (dos paneles: no cuesta nada)
	fila[1].add_sibling(barra)
	fila[1].get_parent().remove_child(fila[1])
	fila[1].queue_free()
	fila[1] = barra
	_sin_resalte()


# Barra dorada fina con el volumen. Solo se mira: los toques van a ◀ ▶.
func _barra(v: int) -> Control:
	var pista := Panel.new()
	pista.custom_minimum_size = Vector2(220, 12)
	pista.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(Estilo.SOMBRA, 0.9)
	fondo.border_color = Color(Estilo.ORO, 0.4)
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(5)
	pista.add_theme_stylebox_override("panel", fondo)
	if v > 0:
		var lleno := Panel.new()
		lleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lleno.position = Vector2(2, 2)
		lleno.size = Vector2(maxf(8.0, 216.0 * v / 100.0), 8)
		var oro := StyleBoxFlat.new()
		oro.bg_color = Estilo.ORO
		oro.set_corner_radius_all(4)
		lleno.add_theme_stylebox_override("panel", oro)
		pista.add_child(lleno)
	return pista


# ---------------------------------------------------------------- piezas

# Los títulos (dorados y grandes) van en cursiva, como el nombre del héroe en el menú de combate.
func _texto(t: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	if color == COLOR_TITULO and tam >= 24:
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
