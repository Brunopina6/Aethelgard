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
	if ev.is_action_pressed("ui_cancel"):
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
	var fila_heroes := HBoxContainer.new()
	fila_heroes.add_theme_constant_override("separation", 8)
	cuerpo.add_child(fila_heroes)
	for n in Grupo.activos():
		var b := _boton(n, 22, Vector2(140, 40), "heroe:" + n)
		if n == heroe:
			b.add_theme_color_override("font_color", COLOR_TITULO)
		b.pressed.connect(func():
			heroe = n
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fila_heroes.add_child(b)

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
	izq.add_child(_texto("%s — %s" % [heroe, Grupo.HEROES[heroe]["clase"]], 26, COLOR_TITULO))
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
		f.add_child(nombre)
		var adelante := _boton("▶", 18, Vector2(36, 34), "ranura:%s:1" % r)
		adelante.pressed.connect(func(): _cambiar(ranura, 1))
		f.add_child(adelante)
		der.add_child(f)
		if id != "" and Inv.resumen(id) != "":
			der.add_child(_texto("      " + Inv.resumen(id), 16, COLOR_BIEN))


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
	for n in Grupo.activos():
		cuerpo.add_child(_texto("%s (nivel %d)" % [n, Grupo.datos()[n]["nivel"]], 24, COLOR_TITULO))
		if Grupo.HEROES[n]["magias"].is_empty():
			cuerpo.add_child(_texto("   No usa magia.", 18, COLOR_SUAVE))
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

# El volumen de cada parte del sonido (sonido.gd): ◀ ▶ lo bajan o suben un 10 % y suena una muestra. Se guarda en
# este aparato, aparte de la partida.
func _pintar_ajustes() -> void:
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
		f.add_child(_barra(v))
		f.add_child(_texto("   " + Sonido.AYUDA[b], 16, COLOR_SUAVE))
		cuerpo.add_child(f)
	cuerpo.add_child(_texto("Se guarda en este aparato, aparte de la partida.", 16, COLOR_SUAVE))
	# El mapa del mundo pintado o el de siempre (T-085), solo en la versión experimental: para comparar en el móvil.
	# Se guarda en el mismo archivo de ajustes (mapa_arte.gd, sección [mapa]) y se nota al volver a abrir el mapa.
	if load("res://modo3d.gd").activo():
		var arte = load("res://mapa_arte/mapa_arte.gd")
		var clasico: bool = arte.clasico_elegido()
		cuerpo.add_child(_texto("Mapa del mundo", 26, COLOR_TITULO))
		var fm := HBoxContainer.new()
		fm.add_theme_constant_override("separation", 8)
		for op in [[false, "Pintado"], [true, "De siempre"]]:
			var es_clasico: bool = op[0]
			var b := _boton(("● " if es_clasico == clasico else "○ ") + op[1], 18, Vector2(200, 34),
				"mapa:%s" % ("clasico" if es_clasico else "pintado"))
			b.pressed.connect(func():
				arte.elegir("clasico", es_clasico)
				Sonido.efecto("ui_tic")
				_pintar_de_nuevo())
			fm.add_child(b)
		cuerpo.add_child(fm)
		cuerpo.add_child(_texto("Se nota la próxima vez que se abre el mapa.", 16, COLOR_SUAVE))
		# La Garganta del Diablo en 3D (T-095), todavía en pruebas: aquí se elige para verla en el móvil.
		var m3d = load("res://modo3d.gd")
		var g3d: bool = m3d.elegida("garganta3d")
		cuerpo.add_child(_texto("Garganta del Diablo", 26, COLOR_TITULO))
		var fg := HBoxContainer.new()
		fg.add_theme_constant_override("separation", 8)
		for op in [[false, "2D (la de siempre)"], [true, "3D (en pruebas)"]]:
			var en_3d: bool = op[0]
			var bg := _boton(("● " if en_3d == g3d else "○ ") + op[1], 18, Vector2(240, 34),
				"garganta:%s" % ("3d" if en_3d else "2d"))
			bg.pressed.connect(func():
				m3d.elegir("garganta3d", en_3d)
				Sonido.efecto("ui_tic")
				_pintar_de_nuevo())
			fg.add_child(bg)
		cuerpo.add_child(fg)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en la Garganta.", 16, COLOR_SUAVE))
		_pintar_calidad()
		# La invocación de Érebo (T-101): la de siempre o la nueva, en pruebas (invocacion_erebo_nueva.gd).
		var ere = load("res://invocacion_erebo_nueva.gd")
		var nueva: bool = ere.elegida()
		cuerpo.add_child(_texto("Invocación de Érebo", 26, COLOR_TITULO))
		var fe := HBoxContainer.new()
		fe.add_theme_constant_override("separation", 8)
		for op in [[false, "La de siempre"], [true, "Nueva (en pruebas)"]]:
			var es_nueva: bool = op[0]
			var be := _boton(("● " if es_nueva == nueva else "○ ") + op[1], 18, Vector2(240, 34),
				"erebo:%s" % ("nueva" if es_nueva else "actual"))
			be.pressed.connect(func():
				ere.elegir(es_nueva)
				Sonido.efecto("ui_tic")
				_pintar_de_nuevo())
			fe.add_child(be)
		cuerpo.add_child(fe)
		cuerpo.add_child(_texto("Se nota la próxima vez que Lya invoca a Érebo.", 16, COLOR_SUAVE))
		# Oakhaven en 3D (T-103), también en pruebas: la Puerta del Sur, la plaza y la posada por dentro.
		var o3d: bool = m3d.elegida("oakhaven3d")
		cuerpo.add_child(_texto("Oakhaven", 26, COLOR_TITULO))
		var fo := HBoxContainer.new()
		fo.add_theme_constant_override("separation", 8)
		for op in [[false, "2D (la de siempre)"], [true, "3D (en pruebas)"]]:
			var en_3d: bool = op[0]
			var bo := _boton(("● " if en_3d == o3d else "○ ") + op[1], 18, Vector2(240, 34),
				"oakhaven:%s" % ("3d" if en_3d else "2d"))
			bo.pressed.connect(func():
				m3d.elegir("oakhaven3d", en_3d)
				Sonido.efecto("ui_tic")
				_pintar_de_nuevo())
			fo.add_child(bo)
		cuerpo.add_child(fo)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en Oakhaven.", 16, COLOR_SUAVE))
		# El Mar de Cristal (V12), en pruebas: el primer sector del Mar de Arena de Calid en 3D.
		var mc3d: bool = m3d.elegida("mardecristal")
		cuerpo.add_child(_texto("Mar de Arena de Calid", 26, COLOR_TITULO))
		var fm3 := HBoxContainer.new()
		fm3.add_theme_constant_override("separation", 8)
		for op in [[false, "2D (la de siempre)"], [true, "Mar de Cristal 3D (en pruebas)"]]:
			var en_3d: bool = op[0]
			var bm := _boton(("● " if en_3d == mc3d else "○ ") + op[1], 18, Vector2(300, 34),
				"mardecristal:%s" % ("3d" if en_3d else "2d"))
			bm.pressed.connect(func():
				m3d.elegir("mardecristal", en_3d)
				Sonido.efecto("ui_tic")
				_pintar_de_nuevo())
			fm3.add_child(bm)
		cuerpo.add_child(fm3)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en el Mar de Arena.", 16, COLOR_SUAVE))
	# La pantalla de inicio (11/11): desde el 11/11 por la noche, el usuario eligió la nueva como la de siempre; la original
	# sigue entera y se puede volver a ella aquí, en cualquier versión (portada/eleccion.gd, [portada]).
	var por = load("res://portada/eleccion.gd")
	var alt: bool = por.elegida()
	cuerpo.add_child(_texto("Pantalla de inicio", 26, COLOR_TITULO))
	var fp := HBoxContainer.new()
	fp.add_theme_constant_override("separation", 8)
	for op in [[true, "Nueva"], [false, "Original"]]:
		var es_alt: bool = op[0]
		var bp := _boton(("● " if es_alt == alt else "○ ") + op[1], 18, Vector2(260, 34),
			"portada:%s" % ("alternativa" if es_alt else "original"))
		bp.pressed.connect(func():
			por.elegir(es_alt)
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fp.add_child(bp)
	cuerpo.add_child(fp)
	cuerpo.add_child(_texto("Se nota la próxima vez que se abre el juego.", 16, COLOR_SUAVE))
	# La música de Pastos Verdes (11/11): «Pastoral Pulse», la elegida por el usuario, o solo el ambiente de siempre
	# (musica.gd, MUSICA_PASTOS). Solo si el archivo está en esta versión (es privado: pruebas).
	var Mu = load("res://musica.gd")
	if ResourceLoader.exists(Mu.CONTEXTOS["pradera_musica"]["musica"]):
		var con_musica: bool = Mu.musica_pastos_elegida()
		cuerpo.add_child(_texto("Música de Pastos Verdes", 26, COLOR_TITULO))
		var fmp := HBoxContainer.new()
		fmp.add_theme_constant_override("separation", 8)
		for op in [[true, "Pastoral Pulse"], [false, "Solo ambiente"]]:
			var nueva: bool = op[0]
			var bmp := _boton(("● " if nueva == con_musica else "○ ") + op[1], 18, Vector2(260, 34),
				"musica_pastos:%s" % ("nueva" if nueva else "ambiente"))
			bmp.pressed.connect(func():
				Mu.elegir_musica_pastos(nueva)
				Sonido.efecto("ui_tic")
				_pintar_de_nuevo())
			fmp.add_child(bmp)
		cuerpo.add_child(fmp)
		cuerpo.add_child(_texto("Se nota la próxima vez que se entra en Pastos Verdes.", 16, COLOR_SUAVE))
	# Bramavidrio (11/11): la versión nueva («la Sierpe de la Vela») o la anterior (el gusano de anillos), para que el
	# usuario las compare antes de decidir (enemigos/bramavidrio/bramavidrio_version.gd, [bramavidrio] version).
	# 12/11: y la prueba de la versión 3 («el Excavador», boca articulada); la de por defecto sigue siendo la 2.
	var BV = load("res://enemigos/bramavidrio/bramavidrio_version.gd")
	var vb: int = BV.en_ajustes()
	cuerpo.add_child(_texto("Bramavidrio", 26, COLOR_TITULO))
	var fbv := HBoxContainer.new()
	fbv.add_theme_constant_override("separation", 8)
	for op in [[2, "Nuevo (la Sierpe)"], [3, "Prueba v3: el Excavador"], [1, "Anterior"]]:
		var v: int = op[0]
		var bbv := _boton(("● " if v == vb else "○ ") + op[1], 18, Vector2(260 if v != 3 else 300, 34), "bramavidrio:%d" % v)
		bbv.pressed.connect(func():
			BV.elegir_en_ajustes(v)
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fbv.add_child(bbv)
	cuerpo.add_child(fbv)
	cuerpo.add_child(_texto("Se nota en el próximo encuentro con Bramavidrio.", 16, COLOR_SUAVE))


# Calidad de las regiones 3D (encargo del 09/11; prototipos/calidad_auto.gd, sección [calidad] de user://ajustes.cfg):
# «Automática» deja que el juego elija y ajuste según el aparato; Baja, Media o Alta fijan el perfil y entonces el
# juego no cambia nada solo (lo manual manda). El límite de FPS lo elige el jugador; sin elegir, 30 (60 solo con Alta
# y si el aparato lo aguanta, medido).
const CALIDADES := [["auto", "Automática"], ["bajo", "Baja"], ["medio", "Media"], ["alto", "Alta"]]


func _pintar_calidad() -> void:
	var auto = load("res://prototipos/calidad_auto.gd")
	var cal = load("res://prototipos/calidad_proto.gd")
	var e: Dictionary = auto.estado()
	var elegida: String = "auto" if e["auto"] or e["perfil"] == "" else e["perfil"]
	cuerpo.add_child(_texto("Calidad gráfica", 26, COLOR_TITULO))
	var fc := HBoxContainer.new()
	fc.add_theme_constant_override("separation", 8)
	for op in CALIDADES:
		var clave: String = op[0]
		var b := _boton(("● " if clave == elegida else "○ ") + op[1], 18, Vector2(170, 34), "calidad:" + clave)
		b.pressed.connect(func():
			_elegir_calidad(clave)
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fc.add_child(b)
	cuerpo.add_child(fc)
	var fps_en_uso: int = auto.fps_de(cal.actual(), e, int(cal.PERFILES[cal.actual()]["fps"]))
	var ff := HBoxContainer.new()
	ff.add_theme_constant_override("separation", 8)
	var nombre_fps := _texto("Límite de FPS", 20, COLOR_TEXTO)
	nombre_fps.custom_minimum_size = Vector2(170, 0)
	ff.add_child(nombre_fps)
	for n in auto.FPS_VALIDOS:
		var cifra: int = n
		var b := _boton(("● " if cifra == fps_en_uso else "○ ") + str(cifra), 18, Vector2(110, 34), "fps:%d" % cifra)
		b.pressed.connect(func():
			auto.guardar({"fps": cifra})
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		ff.add_child(b)
	cuerpo.add_child(ff)
	var nota := "Se aplica la próxima vez que se entra en una región 3D."
	if elegida == "auto":
		var p: String = auto.perfil_de(e)
		if p != "":
			nota = "Ahora: %s%s. " % [_nombre_calidad(p), ", ya comprobada al jugar" if e["calibrado"] else ""] + nota
	elif e["aviso"] == elegida:
		nota = "En este aparato, %s no llega a sus FPS de forma estable. " % _nombre_calidad(elegida) + nota
	cuerpo.add_child(_texto(nota, 16, COLOR_SUAVE))


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
	_pintar_de_nuevo()


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
