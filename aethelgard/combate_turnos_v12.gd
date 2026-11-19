extends Control
# Línea de turnos V12 (13/11/2026, propuesta A de docs/v12/COMBATE_TACTICO_V12.md). Ayuda de INTERFAZ: no cambia reglas,
# equilibrio ni azar (no llama a randf(), no toca a los luchadores ni a la cola; solo lee). APAGADA por defecto.
#
# Se enciende con: Ajustes → «Combate: Línea de turnos: sí» (user://ajustes.cfg, [combate] turnos), el argumento
# «turnos_v12» o Engine.set_meta("turnos_v12", true). Vale con cualquier versión de protagonistas (originales o v2) y
# con cualquier enemigo.
#
# Qué enseña, arriba a la derecha (debajo del cartel de lo que pasa, lejos de los luchadores y del menú):
#   - los próximos turnos según el ATB de ahora: primero quien actúa (marco grande, «AHORA»), luego la cola y después
#     quien llenará antes su barra (vel × los «Lento» de la magia negra), repitiendo a quien vuelva antes que otros;
#   - un retrato pequeño de cada uno: un recorte de su propia ventana 3D (la que ya se dibuja en el combate: no hay que
#     pintar nada más) o, en los de dibujo 2D, un disco con su inicial; marco del color del héroe o rojo en enemigos;
#   - «⚠» sobre el enemigo que prepara un ataque cargado (Hachazo, Pisotón, Rebote, Fractura, Aliento, Réquiem…: lo que
#     ya anuncia su rótulo de estado) y, debajo de la línea, el aviso («⚠ Fractura · Bramavidrio»); «❄» si está congelado.
#   - Tocar un retrato muestra su nombre un momento (táctil y ratón).
# Coste: el orden se calcula 10 veces por segundo (unas sumas) y la línea solo se vuelve a dibujar cuando cambia algo
# (el orden, el aviso, quién cae…); los retratos son la textura de cada ventana 3D, que ya existe y ya se actualiza.

const ACTIVO_POR_DEFECTO := false
const N := 6                          # turnos que se ven
const LADO := 46.0                    # retrato
const LADO_AHORA := 58.0              # el de quien actúa
const HUECO := 5.0
const BORDE_DER := 1268.0             # (medidas de la interfaz del combate, 1280 × 720)
const ARRIBA := 66.0
const CADA := 0.1                     # s entre cálculos del orden
const C_FONDO := Color(0.04, 0.06, 0.11, 0.62)
const C_ENEMIGO := Color(0.92, 0.36, 0.3)
const C_AVISO := Color(1.0, 0.72, 0.2)

var c: Node                           # combate.gd
var fuente: Font
var _t := 0.0
var _clave := ""                      # lo dibujado (si no cambia, no se vuelve a dibujar)
var _slots: Array = []                # [{f, rect, ahora}]
var _aviso := ""
var _regiones := {}                   # índice del luchador → Rect2 de su retrato en su ventana 3D
var _toque_nombre := ""
var _toque_hasta := 0.0
var _caja: StyleBoxFlat
var dibujos := 0                      # veces que se ha vuelto a dibujar (para la prueba)


static func activado() -> bool:
	if Engine.has_meta("turnos_v12"):
		return bool(Engine.get_meta("turnos_v12"))
	if "turnos_v12" in OS.get_cmdline_user_args():
		return true
	var cf := ConfigFile.new()
	if cf.load("user://ajustes.cfg") != OK:
		return ACTIVO_POR_DEFECTO
	return bool(cf.get_value("combate", "turnos", ACTIVO_POR_DEFECTO))


static func elegir_en_ajustes(si: bool) -> Error:
	Engine.set_meta("turnos_v12", si)
	var cf := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := cf.load("user://ajustes.cfg")
		if err != OK:
			return err
	cf.set_value("combate", "turnos", si)
	return cf.save("user://ajustes.cfg")


# combate.gd, al final de _crear_interfaz.
static func crear(combate: Node) -> Control:
	var t = load("res://combate_turnos_v12.gd").new()
	t.name = "LineaTurnosV12"
	t.c = combate
	combate.capa.add_child(t)
	return t


func _ready() -> void:
	var ancho := LADO_AHORA + (N - 1) * (LADO + HUECO) + 16.0
	size = Vector2(ancho, LADO_AHORA + 46.0)
	position = Vector2(BORDE_DER - ancho, ARRIBA)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	fuente = c.menu.f_numero if c.menu != null and c.menu.get("f_numero") != null else ThemeDB.fallback_font
	_caja = StyleBoxFlat.new()
	_caja.bg_color = C_FONDO
	_caja.set_corner_radius_all(10)
	gui_input.connect(_al_tocar)


func _process(delta: float) -> void:
	_t += delta
	if _toque_hasta > 0.0 and Time.get_ticks_msec() / 1000.0 > _toque_hasta:
		_toque_hasta = 0.0
		_toque_nombre = ""
		_clave = ""
	if _t < CADA:
		return
	_t = 0.0
	visible = c.estado != "fin"
	if not visible:
		return
	# el cartel grande de Bramavidrio (Fractura, Aliento: x 700-1260, y 72-172) ocupa este sitio: la línea baja debajo,
	# salvo con la lista de objetivos abierta (que empieza en y = 214), cuando se queda arriba encima del cartel
	var y := ARRIBA
	if c.brama != null and c.brama.get("cartel") != null and is_instance_valid(c.brama.cartel) and c.brama.cartel.visible and not (c.panel_obj != null and c.panel_obj.visible):
		y = 178.0
	if position.y != y:
		position.y = y
	var orden := prever()
	var aviso := _avisos()
	var clave := aviso + "|" + _toque_nombre
	for s in orden:
		clave += "|%s%d%s%s" % [s["f"]["nombre"], int(s["ahora"]), str(_marca(s["f"])), str(s["f"]["hp"] > 0)]
	if clave == _clave:
		return
	_clave = clave
	_aviso = aviso
	_colocar(orden)
	queue_redraw()


# Los próximos N turnos: [{f, ahora}]. Solo lee el estado del combate (mismo cálculo que el ATB de combate.gd).
func prever() -> Array:
	var r: Array = []
	var ya := {}
	var actuando = null
	if c.estado in ["menu", "objetivo", "accion"] and c.actor is Dictionary and c.actor.get("hp", 0) > 0:
		actuando = c.actor
	elif c.estado == "enemigo" and c.atacante_actual is Dictionary:
		actuando = c.atacante_actual
	if actuando != null:
		r.append({"f": actuando, "ahora": true, "t": -2.0})
	var i := 0
	for f in c.cola:                                 # ya llenos: en el orden de la cola
		if f["hp"] > 0 and not is_same(f, actuando):
			r.append({"f": f, "ahora": false, "t": -1.0 + i * 0.001})
			i += 1
	var futuros: Array = []
	for f in c.heroes + c.enemigos:
		if f["hp"] <= 0:
			continue
		var vel: float = float(f["vel"]) * (c.MN.mult_vel(f) if f.has("mn") else 1.0)
		if vel <= 0.0:
			continue
		var ciclo: float = c.ATB_MAX / vel
		var t0: float
		if is_same(f, actuando) or c.cola.has(f):
			t0 = ciclo                               # vuelve a empezar desde 0 tras actuar
		else:
			t0 = (c.ATB_MAX - float(f["atb"])) / vel
		for k in N:
			futuros.append({"f": f, "ahora": false, "t": t0 + k * ciclo})
	futuros.sort_custom(func(a, b): return a["t"] < b["t"])
	for x in futuros:
		if r.size() >= N:
			break
		r.append(x)
	return r.slice(0, N)


func _marca(f: Dictionary) -> String:
	if f.get("hero", false):
		return ""
	var txt: String = f["lbl_estado"].text if f.has("lbl_estado") and is_instance_valid(f["lbl_estado"]) else ""
	if "⚠" in txt:
		return "⚠"
	if int(f.get("congelado", 0)) > 0:
		return "❄"
	return ""


# El aviso de debajo: el primer ataque cargado anunciado («⚠ …» de su rótulo de estado) y de quién.
func _avisos() -> String:
	for e in c.enemigos:
		if e["hp"] <= 0 or not e.has("lbl_estado") or not is_instance_valid(e["lbl_estado"]):
			continue
		var txt: String = e["lbl_estado"].text
		var i := txt.find("⚠")
		if i >= 0:
			var trozo := txt.substr(i).replace("\n", "  ").split("  ")[0]   # (el rótulo puede ir en varias líneas)
			return "%s · %s" % [trozo, e["nombre"]]
	return ""


func _colocar(orden: Array) -> void:
	_slots.clear()                                   # de izquierda a derecha: primero quien actúa (o el siguiente)
	var x := 8.0
	for s in orden:
		var lado := LADO_AHORA if s["ahora"] else LADO
		_slots.append({"f": s["f"], "ahora": s["ahora"], "rect": Rect2(Vector2(x, 8.0 + (LADO_AHORA - lado)), Vector2(lado, lado))})
		x += lado + HUECO


func _draw() -> void:
	dibujos += 1
	if _slots.is_empty():
		return
	# Por capas (todos los fondos, luego los retratos, luego marcos y discos, y al final los textos) para que el
	# renderizador junte lo que comparte textura: medido, +25 dibujos por fotograma si se pinta retrato a retrato.
	var ancho: float = _slots[-1]["rect"].end.x + 8.0
	var alto := LADO_AHORA + 16.0 + (30.0 if _aviso != "" or _toque_nombre != "" else 0.0)   # (con aviso, la caja lo abarca)
	draw_style_box(_caja, Rect2(Vector2.ZERO, Vector2(ancho, alto)))
	for s in _slots:
		draw_rect(s["rect"], Color(0.1, 0.12, 0.18, 0.95))
	for s in _slots:
		var f: Dictionary = s["f"]
		var vp_tex = _textura(f)
		if vp_tex != null:
			draw_texture_rect_region(vp_tex, s["rect"].grow(-2), _region(f), Color(1, 1, 1, 1) if f["hp"] > 0 else Color(0.45, 0.45, 0.5))
	for s in _slots:
		var f: Dictionary = s["f"]
		var r: Rect2 = s["rect"]
		var col: Color = (c.menu.COLOR_HEROE.get(f["nombre"], Color(0.85, 0.9, 1.0)) if f.get("hero", false) else C_ENEMIGO)
		if _textura(f) == null:
			draw_circle(r.get_center(), r.size.x * 0.38, col.darkened(0.45))
		draw_rect(r, col, false, 3.0 if s["ahora"] else 2.0)
		var m := _marca(f)
		if m != "":
			draw_circle(r.position + Vector2(r.size.x - 9, 9), 10.0, C_AVISO if m == "⚠" else Color(0.55, 0.85, 1.0))
	for s in _slots:
		var f: Dictionary = s["f"]
		var r: Rect2 = s["rect"]
		if _textura(f) == null:
			draw_string(fuente, r.position + Vector2(0, r.size.y * 0.68), str(f["nombre"]).substr(0, 1),
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, Color.WHITE)
		var m := _marca(f)
		if m != "":
			var p := r.position + Vector2(r.size.x - 9, 9)
			draw_string(fuente, p + Vector2(-8, 6), "!" if m == "⚠" else "*", HORIZONTAL_ALIGNMENT_CENTER, 16, 18,
				Color(0.1, 0.05, 0.0))
		if s["ahora"]:
			draw_string(fuente, r.position + Vector2(0, r.size.y + 14), "AHORA", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15,
				Color(1, 0.95, 0.75))
	var y := LADO_AHORA + 38.0
	if _toque_nombre != "":
		draw_string(fuente, Vector2(10, y), _toque_nombre, HORIZONTAL_ALIGNMENT_LEFT, ancho - 16, 19, Color.WHITE)
	elif _aviso != "":
		draw_string(fuente, Vector2(10, y), _aviso, HORIZONTAL_ALIGNMENT_LEFT, ancho - 16, 19, C_AVISO)


func _textura(f: Dictionary):
	if not f.has("cam3d") or not f.has("partes") or not f["partes"].has("sprite"):
		return null
	var spr = f["partes"]["sprite"]
	return spr.texture if spr is Sprite2D else null


# El recorte de su ventana 3D donde está la cara (héroes) o la parte alta del cuerpo (enemigos). Se calcula una vez.
func _region(f: Dictionary) -> Rect2:
	var k := ("h%d" % c.heroes.find(f)) if f.get("hero", false) else ("e%d" % c.enemigos.find(f))
	if _regiones.has(k):
		return _regiones[k]
	var cam: Camera3D = f["cam3d"]
	var tex: Texture2D = _textura(f)
	var tam := Vector2(tex.get_width(), tex.get_height())
	var m: Dictionary = c.MODELOS.get(f["modelo"], {})
	var px_m: float = tam.y / maxf(cam.size, 0.01)
	var centro: Vector3
	var lado_m: float
	if f.get("hero", false):
		centro = Vector3(0, 1.42, 0)
		lado_m = 0.78
	else:
		var cv: Vector3 = m.get("centro_3d_v", Vector3(0, float(m.get("centro_3d", 0.85)), 0))
		centro = cv * Vector3(1, 1.3, 1)
		lado_m = maxf(0.6, cv.y * 1.1)
	var p := cam.unproject_position(centro)
	var lado := minf(lado_m * px_m, minf(tam.x, tam.y))
	var r := Rect2(p - Vector2(lado, lado) * 0.5, Vector2(lado, lado))
	r.position.x = clampf(r.position.x, 0.0, tam.x - lado)
	r.position.y = clampf(r.position.y, 0.0, tam.y - lado)
	_regiones[k] = r
	return r


func _al_tocar(ev: InputEvent) -> void:
	var pos := Vector2(-1, -1)
	if ev is InputEventScreenTouch and ev.pressed:
		pos = ev.position
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		pos = ev.position
	if pos.x < 0:
		return
	for s in _slots:
		if s["rect"].grow(4).has_point(pos):
			var f: Dictionary = s["f"]
			_toque_nombre = "%s%s" % [f["nombre"], ("  —  " + _aviso) if _marca(f) == "⚠" and _aviso != "" else ""]
			_toque_hasta = Time.get_ticks_msec() / 1000.0 + 1.6
			_clave = ""
			accept_event()
			return
