extends SceneTree
# V12 (14/11): RECORRIDO JUGADO de «Las tres marcas del cantero» (PROPUESTA, ciudades/oakhaven_propuestas.gd) en Oakhaven
# 3D, con los controles normales y sin cumplir ningún hito a mano:
#   - andar: clics de ratón en el suelo, donde está el sitio en la pantalla (lo mismo que un toque: vista3d.gd
#     _unhandled_input → destino), por calles, tramo a tramo;
#   - hablar, examinar y abrir: Intro cuando el botón de acción ofrece lo esperado (ui_accept);
#   - diálogos: Intro hasta que acaban (dialogic_default_action);
#   - cerraduras: flechas (↑ ↓ eligen anillo, ← → giran) y Esc para abandonar a medias.
# Lo único que no se hace con el dedo: abrir el Diario y el taller, que en el juego se abren desde el mapa o la botica;
# aquí se crean como lo hace el mapa (mapa.gd _abrir_menu) y dentro se pulsan sus botones con clics.
# Comprueba por el camino: el premio una sola vez (oro y objetos antes y después), abandonar sin perder nada, guardar y
# cargar con la partida de verdad del juego (Progreso.cargar, como «Continuar») a mitad de misión y al final, y que
# Kael vuelve a andar tras cada ventana. Capturas en «salida=<carpeta>» y un resumen (recorrido.txt).
# Uso: lista_pruebas.txt (fotos_cantero_recorrido, ventana): «3d sin_prologo salida={salida}». Partida propia
# (Engine «archivo_partida_prueba»): nunca toca la de verdad. Imprime «FALLOS: n».

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const ARCHIVO := "user://recorrido_cantero.save"
const INTERRUPTOR := "oakhaven_propuestas_v12"
const Barrios := preload("res://zonas3d/oakhaven/barrios.gd")
const MAX_TRAMO := 9.0                       # s para llegar a un punto

# Rutas por las calles (casillas: x, y de la 2D = x, z de la 3D).
# (entre la fuente y el puesto de flores de Rosa hay un paso de un metro: x 41,9-42,8)
const A_PLAZA := [Vector2(40, 48.5), Vector2(40, 43), Vector2(40.4, 37), Vector2(40.4, 31.6), Vector2(42.35, 29.4),
	Vector2(42.35, 26.9)]
const A_APRENDIZ := [Vector2(43.6, 24.9)]
const A_ARCON := [Vector2(45.4, 23.9), Vector2(48.0, 23.2), Vector2(50.2, 23.2)]
const A_FUENTE := [Vector2(48.0, 23.4), Vector2(45.0, 24.6), Vector2(42.6, 26.4), Vector2(42.4, 28.5)]
const A_TORRE := [Vector2(42.5, 26.6), Vector2(46.8, 26.0), Vector2(52, 26), Vector2(58, 26), Vector2(64, 26), Vector2(69, 26.6),
	Vector2(69, 32), Vector2(69, 37.5), Vector2(69.3, 43.4), Vector2(70.4, 44.3)]
const DE_TORRE_A_PLAZA := [Vector2(69.3, 43.4), Vector2(69, 37.5), Vector2(69, 32), Vector2(69, 26.6), Vector2(64, 26), Vector2(58, 26),
	Vector2(52, 26), Vector2(46.8, 26.0)]
# (rodeando al aprendiz por el norte y a Doña Encina, en 35, 10, por el este y el sur)
const A_RAIZ := [Vector2(45.6, 22.4), Vector2(41.6, 21.6), Vector2(40.4, 17), Vector2(40.2, 13.6), Vector2(40.3, 12.7)]
# (y al farol que hay junto a la losa, en 33,3; 11,2)
const A_LOSA := [Vector2(37.0, 12.5), Vector2(33.6, 12.3), Vector2(32.2, 12.1), Vector2(31.8, 10.7)]
const DE_LOSA_A_APRENDIZ := [Vector2(32.2, 12.1), Vector2(33.6, 12.3), Vector2(36.5, 12.5), Vector2(39.6, 13.4), Vector2(40.2, 17),
	Vector2(40.6, 21.4), Vector2(42.4, 22.4), Vector2(42.6, 25.0), Vector2(43.6, 24.9)]

var v                                        # la región (oakhaven_3d.gd)
var salida := ""
var fallos := 0
var n_foto := 0
var registro: PackedStringArray = []
var Oak
var Prop
var P
var Inv
var C


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)
		registro.append("FALLO: " + t)


func _nota(t: String) -> void:
	print(t)
	registro.append(t)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("recorrido_cantero")
	DirAccess.make_dir_recursive_absolute(salida)
	Oak = load("res://ciudades/oakhaven.gd")
	Prop = load("res://ciudades/oakhaven_propuestas.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	C = load("res://cerradura_runica.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta(INTERRUPTOR, true)
	root.size = Vector2i(1280, 720)
	_jugar.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(s * 1000.0):
		await process_frame


func _foto(nombre: String) -> void:
	await _frames(3)
	n_foto += 1
	var ruta := salida.path_join("%02d_%s.png" % [n_foto, nombre])
	root.get_texture().get_image().save_png(ruta)
	_nota("foto %s" % ruta.get_file())


# ---------------------------------------------------------------- controles

func _tecla(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var s := InputEventKey.new()
	s.keycode = codigo
	s.physical_keycode = codigo
	s.pressed = false
	Input.parse_input_event(s)
	await _frames(3)


func _clic(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.global_position = pos
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var s := InputEventMouseButton.new()
	s.button_index = MOUSE_BUTTON_LEFT
	s.position = pos
	s.global_position = pos
	s.pressed = false
	Input.parse_input_event(s)
	await _frames(2)


func _clic_boton(b: Control) -> void:
	await _clic(b.get_global_rect().get_center())


static func _mundo(c: Vector2) -> Vector3:
	return Vector3(c.x, Barrios.altura(c.x, c.y), c.y)


func _kael_en() -> Vector2:
	var p: Vector3 = v.kael.global_position
	return Vector2(p.x, p.z)


# Un tramo andando: clic en el suelo donde se ve el punto (si no se ve, en uno intermedio de la recta) hasta llegar.
func _andar_a(c: Vector2) -> bool:
	var t0 := Time.get_ticks_msec()
	var reintentos := 0
	while Time.get_ticks_msec() - t0 < int(MAX_TRAMO * 1000.0):
		if _kael_en().distance_to(c) < 0.7:
			return true
		if v.get("destino") == null:
			if reintentos > 4:
				break
			reintentos += 1
			var objetivo := c
			var cam: Camera3D = v.cam
			for k in 6:
				var w := _mundo(objetivo)
				var pp := cam.unproject_position(w)
				if not cam.is_position_behind(w) and Rect2(40, 90, 1200, 520).has_point(pp):
					await _clic(pp)
					break
				objetivo = _kael_en().lerp(objetivo, 0.5)
		await _frames(2)
	_ok(_kael_en().distance_to(c) < 1.2, "no llega a %s (se queda en %s)" % [c, _kael_en()])
	return _kael_en().distance_to(c) < 1.2


func _ruta(puntos: Array, nombre: String) -> void:
	var t0 := Time.get_ticks_msec()
	for c in puntos:
		if not await _andar_a(c):
			_nota("ruta %s: atasco antes de %s" % [nombre, c])
			return
	_nota("ruta %s: %.1f s" % [nombre, (Time.get_ticks_msec() - t0) / 1000.0])


# Espera a que el botón ofrezca «texto» y pulsa Intro.
func _accion(texto: String) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2500:
		if v.boton_accion.visible and v.boton_accion.text == texto:
			await _tecla(KEY_ENTER)
			return true
		await _frames(2)
	_ok(false, "el botón no ofrece «%s» (ofrece «%s», visible %s)" % [texto, v.boton_accion.text, v.boton_accion.visible])
	return false


# Un diálogo entero con Intro; foto en su primera frase. Devuelve el diálogo que salió.
func _dialogo(foto: String) -> String:
	var dg = root.get_node_or_null("Dialogic")
	if dg == null:
		_ok(false, "sin Dialogic")
		return ""
	var t0 := Time.get_ticks_msec()
	while dg.current_timeline == null and Time.get_ticks_msec() - t0 < 2000:
		await _frames(2)
	if dg.current_timeline == null:
		_ok(false, "no empieza ningún diálogo")
		return ""
	var ruta: String = dg.current_timeline.resource_path
	await _segundos(1.4)
	if foto != "":
		await _foto(foto)
	var veces := 0
	while dg.current_timeline != null and veces < 40:
		await _tecla(KEY_ENTER)
		await _segundos(0.45)
		veces += 1
	_ok(dg.current_timeline == null, "el diálogo %s no acaba con Intro" % ruta.get_file())
	await _segundos(0.6)
	return ruta


func _cerradura() -> Node:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2000:
		var m = v.vida.abierto
		if m != null and is_instance_valid(m) and m.get("config") != null:
			return m
		await _frames(2)
	_ok(false, "no se abre la ventana de la cerradura")
	return null


# Resuelve con las flechas: ↑ ↓ para elegir el anillo y → ← para girarlo.
func _resolver(m) -> void:
	for paso in C.solucion(m.config, m.giros):
		var i: int = paso[0]
		var veces := 0
		while m.sel != i and veces < 6:
			await _tecla(KEY_DOWN if i > m.sel else KEY_UP)
			veces += 1
		await _tecla(KEY_RIGHT if int(paso[1]) > 0 else KEY_LEFT)
		await _segundos(0.12)


func _sigue_andando(donde: String) -> void:
	var a := _kael_en()
	var objetivo := a + Vector2(0, 1.4)
	var cam: Camera3D = v.cam
	await _clic(cam.unproject_position(_mundo(objetivo)))
	await _segundos(1.2)
	_ok(_kael_en().distance_to(a) > 0.3, "%s: Kael no vuelve a andar" % donde)
	await _andar_a(a)


func _aviso() -> String:
	return str(v.vida.ultimo_aviso)


func _cargar_region() -> void:
	change_scene_to_file(REGION)
	await _frames(30)
	v = current_scene
	var t0 := Time.get_ticks_msec()
	while (v == null or v.get("vida") == null or v.get("kael") == null) and Time.get_ticks_msec() - t0 < 8000:
		await _frames(5)
		v = current_scene
	await _segundos(1.5)


# «Continuar»: la partida que guardó el juego, por Progreso.cargar(), y su escena.
func _continuar(donde: String) -> void:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var escena: String = P.cargar()
	_ok(escena == REGION, "%s: la partida guardada no vuelve a Oakhaven 3D («%s»)" % [donde, escena])
	await _cargar_region()
	_nota("%s: cargada; Kael en %s" % [donde, _kael_en()])


# ---------------------------------------------------------------- el recorrido

func _preparar() -> void:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok", "oak_franja", "oak_franja_t"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	P.cargar()                                   # partida nueva (no hay archivo)
	for h in ["pv_02", "pv_03", "pv_05", "bq_alquimia"]:   # a mitad de los Pastos: Kael ya salió y Lya prepara remedios
		P.poner_hito(h)
	Engine.set_meta("oak_franja", "tarde")
	Engine.set_meta("partida_lista", true)


func _jugar() -> void:
	await _frames(3)
	_preparar()
	await _cargar_region()
	if v == null or v.get("vida") == null:
		_ok(false, "no se cargó Oakhaven 3D")
		_terminar()
		return
	var mis: Dictionary = load("res://encargos.gd").de("prop_cantero")
	var E = load("res://encargos.gd")
	_nota("Kael aparece en %s" % _kael_en())
	await _foto("entrada_puerta_sur")

	# 1. el aprendiz encarga la misión
	await _ruta(A_PLAZA + A_APRENDIZ, "puerta → aprendiz")
	await _foto("aprendiz_y_sillar")
	if await _accion("Hablar con el aprendiz"):
		var r: String = await _dialogo("aprendiz_encargo")
		_ok(r.ends_with("prop_cantero_pedido.dtl"), "1: el aprendiz no empieza por su encargo (%s)" % r.get_file())
	await _segundos(0.5)
	await _foto("aviso_mision")
	_ok(P.estado("oakhaven", "cantero_pedido") and E.estado(mis) == "activo", "1: hablar con el aprendiz no empieza la misión")
	await _diario("diario_inicio")
	await _sigue_andando("tras el encargo")

	# 2. el arcón del Concejo: abandonar a medias y luego abrirlo
	await _ruta(A_ARCON, "aprendiz → arcón")
	var oro0: int = Inv.oro()
	if await _accion("Girar los anillos"):
		var m = await _cerradura()
		if m != null:
			await _foto("arcon_cerradura")
			await _tecla(KEY_RIGHT)
			await _tecla(KEY_DOWN)
			await _tecla(KEY_LEFT)
			await _tecla(KEY_ESCAPE)
			await _segundos(0.4)
			_ok(v.vida.abierto == null and not Oak.cerradura_abierta() and Inv.oro() == oro0,
				"2: abandonar el arcón no lo deja como estaba")
	await _sigue_andando("tras abandonar el arcón")
	await _andar_a(A_ARCON[-1])
	if await _accion("Girar los anillos"):
		var m = await _cerradura()
		if m != null:
			await _resolver(m)
			await _segundos(0.6)
			await _foto("arcon_abierto_nota")
			_ok(Oak.cerradura_abierta() and m.mensaje.text.contains("cantero"), "2: el arcón no da la nota del cantero")
			await _tecla(KEY_ENTER)
			await _segundos(0.5)
	_ok(E.paso_actual(mis).get("id", "") == "marcas", "2: tras el arcón no toca buscar las marcas")
	await _sigue_andando("tras abrir el arcón")

	# 3. la marca de la fuente (dos muescas)
	await _ruta(A_FUENTE, "arcón → fuente")
	await _foto("marca_fuente")
	if await _accion("Examinar la marca"):
		await _segundos(0.8)
		await _foto("marca_fuente_apuntada")
		_ok(P.estado("oakhaven", "cantero_marca_2"), "3: la marca de la fuente no se apunta")

	# 4. guardar y cargar a mitad de misión (lo guardó el juego al apuntar la marca)
	await _continuar("a mitad de misión")
	_ok(P.estado("oakhaven", "cantero_marca_2") and not P.estado("oakhaven", "cantero_marca_1")
		and Oak.cerradura_abierta() and Inv.oro() == oro0 + 60, "4: tras cargar a mitad, cambia algo")
	if _kael_en().distance_to(Vector2(42.4, 28.5)) > 3.0:
		await _ruta(A_PLAZA + [Vector2(45.0, 26.0)], "tras cargar → plaza")

	# 5. la marca de la torre (una muesca)
	await _ruta(A_TORRE, "fuente → torre")
	await _foto("marca_torre")
	if await _accion("Examinar la marca"):
		await _segundos(0.8)
		_ok(P.estado("oakhaven", "cantero_marca_1"), "5: la marca de la torre no se apunta")
	await _ruta(DE_TORRE_A_PLAZA, "torre → plaza")

	# 6. la marca de la raíz (tres muescas)
	await _ruta(A_RAIZ, "plaza → raíz")
	await _foto("marca_raiz")
	if await _accion("Examinar la marca"):
		await _segundos(0.8)
		await _foto("marca_raiz_apuntada")
		_ok(P.estado("oakhaven", "cantero_marcas"), "6: con las tres marcas no se da por hecho el paso")
	_ok(E.paso_actual(mis).get("id", "") == "losa", "6: con las tres marcas no toca la losa")

	# 7. la losa: abandonar a medias, guardar y cargar con ella vista, y abrirla
	await _ruta(A_LOSA, "raíz → losa")
	await _foto("losa_cerrada")
	var oro1: int = Inv.oro()
	var incienso1: int = Inv.cantidad("Incienso de Ceniza")
	if await _accion("Girar los anillos"):
		var m = await _cerradura()
		if m != null:
			await _foto("losa_cerradura")
			await _tecla(KEY_RIGHT)
			await _tecla(KEY_RIGHT)
			await _tecla(KEY_ESCAPE)
			await _segundos(0.4)
			_ok(v.vida.abierto == null and not Oak.cerradura_abierta("oak_losa_cantero") and Inv.oro() == oro1,
				"7: abandonar la losa no la deja como estaba")
	v.vida.guardar()                              # (lo que haría el juego al cerrar la ventana: cerrado → guardar)
	await _continuar("con la losa vista y sin abrir")
	_ok(not Oak.cerradura_abierta("oak_losa_cantero") and P.estado("oakhaven", "cerradura_cantero_vista"),
		"7: tras cargar, la losa no sigue cerrada y vista")
	await _andar_a(A_LOSA[-1])
	if await _accion("Girar los anillos"):
		var m = await _cerradura()
		if m != null:
			await _resolver(m)
			await _segundos(0.6)
			await _foto("losa_resuelta")
			await _tecla(KEY_ENTER)
			await _segundos(1.4)
	await _foto("losa_apartada")
	_ok(Oak.cerradura_abierta("oak_losa_cantero") and Inv.oro() == oro1 + 80
		and Inv.cantidad("Incienso de Ceniza") == incienso1 + 1, "7: la losa no da su premio")
	_ok(E.paso_actual(mis).get("id", "") == "volver", "7: abierta la losa, no toca volver con el aprendiz")
	if await _accion("Examinar"):
		await _segundos(0.5)
		_ok(_aviso().contains("abierta"), "7: la losa abierta no dice que está abierta («%s»)" % _aviso())
		_ok(Inv.oro() == oro1 + 80, "7: examinar la losa abierta da algo")

	# 8. volver con el aprendiz
	await _ruta(DE_LOSA_A_APRENDIZ, "losa → aprendiz")
	if await _accion("Hablar con el aprendiz"):
		var r: String = await _dialogo("aprendiz_final")
		_ok(r.ends_with("prop_cantero_fin.dtl"), "8: el aprendiz no reacciona al cincel (%s)" % r.get_file())
	await _segundos(0.4)
	await _foto("aviso_polvo")
	_ok(Inv.cantidad("Polvo de cantera") == 3 and E.estado(mis) == "hecho", "8: no da el polvo o no acaba la misión")
	if await _accion("Hablar con el aprendiz"):
		var r: String = await _dialogo("aprendiz_despues")
		_ok(r.ends_with("prop_cantero_despues.dtl"), "8: después, el aprendiz no dice lo nuevo (%s)" % r.get_file())
	_ok(Inv.cantidad("Polvo de cantera") == 3, "8: hablar otra vez da más polvo")
	await _diario("diario_final")

	# 9. al final: guardar, cargar y que nada se repita
	v.vida.guardar()
	var oro2: int = Inv.oro()
	await _continuar("al final")
	_ok(Inv.oro() == oro2 and Inv.cantidad("Polvo de cantera") == 3 and E.estado(mis) == "hecho"
		and Oak.cerradura_abierta("oak_losa_cantero"), "9: tras cargar al final, cambia algo")
	_ok(v.vida.arcon.get("losa_piedra") != null and (v.vida.arcon["losa_piedra"] as Node3D).position.x > 0.6,
		"9: tras cargar, la losa no sigue apartada")

	# 10. el taller de Lya (como desde la botica o el menú): investigar con el polvo y preparar Éter
	await _taller()
	_terminar()


func _diario(foto: String) -> void:
	var capa := CanvasLayer.new()                  # (encima del HUD de la región, como en el mapa)
	capa.layer = 90
	v.add_child(capa)
	var d = load("res://diario.gd").new()
	capa.add_child(d)
	await _segundos(0.6)
	var b: Control = _buscar_boton(d, "Encargos")
	if b != null:
		await _clic_boton(b)
		await _segundos(0.5)
	await _foto(foto)
	await _tecla(KEY_ESCAPE)
	await _segundos(0.3)
	if is_instance_valid(d) and d.is_inside_tree():
		d.queue_free()
	capa.queue_free()
	await _frames(2)


func _buscar_boton(n: Node, texto: String) -> Control:
	for c in n.find_children("*", "Button", true, false):
		if (c as Button).text.to_lower().contains(texto.to_lower()) and (c as Button).is_visible_in_tree():
			return c
	return null


func _taller() -> void:
	var a = load("res://alquimia_menu.gd").new()
	a.taller = "alquimia"
	v.add_child(a)
	await _segundos(0.5)
	var b := _buscar_boton(a, "INVESTIGAR")
	if b != null:
		await _clic_boton(b)
		await _segundos(0.4)
	await _foto("taller_investigar")
	var estudiar := _buscar_boton(a, "ESTUDIAR")
	_ok(estudiar != null, "10: el taller no ofrece estudiar «La piedra que asienta»")
	if estudiar != null:
		await _clic_boton(estudiar)
		await _segundos(0.4)
	_ok(load("res://investigacion.gd").estado("lya_cantera") == "completada", "10: la investigación no se completa")
	b = _buscar_boton(a, "RECETAS")
	if b != null:
		await _clic_boton(b)
		await _segundos(0.4)
	var eter0: int = Inv.cantidad("Éter")
	Inv.agregar_objeto("Hierba lunar", 1)          # (un ingrediente de la botica; el polvo es el de la misión)
	a._pintar()
	await _segundos(0.3)
	# el botón FABRICAR de «Éter asentado»: el de la fila con ese nombre
	var fab: Button = null
	for f in a.lista.get_children():
		var txt := ""
		for l in f.find_children("*", "Label", true, false):
			txt += (l as Label).text + " "
		if txt.contains("Éter asentado"):
			for x in f.find_children("*", "Button", true, false):
				fab = x
	_ok(fab != null and not fab.disabled, "10: no se puede fabricar el Éter asentado")
	if fab != null:
		var scroll: ScrollContainer = a.lista.get_parent()
		var veces := 0                             # (con la rueda, si no se ve)
		while not scroll.get_global_rect().encloses(fab.get_global_rect()) and veces < 12:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_WHEEL_DOWN
			e.position = scroll.get_global_rect().get_center()
			e.global_position = e.position
			e.pressed = true
			Input.parse_input_event(e)
			await _frames(3)
			veces += 1
		await _clic_boton(fab)
		await _segundos(0.4)
	await _foto("taller_eter")
	_ok(Inv.cantidad("Éter") == eter0 + 1 and Inv.cantidad("Polvo de cantera") == 2, "10: fabricar no da Éter o no gasta el polvo")
	await _tecla(KEY_ESCAPE)
	await _segundos(0.3)


func _terminar() -> void:
	_nota("FALLOS: %d" % fallos)
	var f := FileAccess.open(salida.path_join("recorrido.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(registro) + "\n")
		f.close()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
