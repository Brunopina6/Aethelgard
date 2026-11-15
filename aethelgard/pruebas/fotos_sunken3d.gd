extends SceneTree
# V12 (15/11): RECORRIDO JUGADO y capturas de Sunken City 3D, sector «Popa Rota → Cubierta Mayor» (zonas3d/sunken_3d.gd,
# EN PRUEBAS; todo lo narrativo, PROPUESTA). Con los controles normales y sin poner estados a mano:
#   - andar: clics de ratón en el suelo, donde se ve el sitio en la pantalla (lo mismo que un toque: vista3d.gd
#     _unhandled_input → _punto_suelo → destino), tramo a tramo y en línea recta;
#   - hablar, examinar y abrir: Intro cuando el botón de acción ofrece lo esperado (ui_accept);
#   - diálogos: Intro hasta que acaban; la tienda y el taller: clics en sus botones y Esc.
# Lo único que no se hace con el dedo: abrir el Diario y el taller de Kael, que en el juego se abren desde el mapa o el
# menú; aquí se crean como lo hace el mapa y dentro se pulsan sus botones con clics.
# Comprueba por el camino: la misión entera, el secreto, la forja una vez, y guardar y cargar con la partida del juego
# (Progreso.cargar, como «Continuar») a mitad y al final. Después, «vistas»: Kael puesto en los sitios principales, con
# llamadas de dibujo, primitivas y tiempo de fotograma por vista (PC: no vale para el Redmi).
# Uso: lista_pruebas.txt (fotos_sunken3d, ventana): «3d sunken3d sin_prologo salida={salida}»; opcional «perfil=medio» o
# «perfil=bajo» y «modo=vistas» (solo las vistas). Partida propia (Engine «archivo_partida_prueba»). Imprime «FALLOS: n».

const REGION := "res://zonas3d/sunken_3d.tscn"
const ARCHIVO := "user://fotos_sunken.save"
const MAX_TRAMO := 9.0
const VISTAS := [
	["muelle_llegada", Vector2(40.0, 57.8)],
	["popa_brecha", Vector2(40.0, 52.0)],
	["popa_cubierta", Vector2(39.0, 47.5)],
	["quilla_sur", Vector2(40.0, 43.0)],
	["quilla_costilla_oscura", Vector2(39.6, 39.6)],
	["quilla_norte", Vector2(40.0, 33.0)],
	["rampa", Vector2(40.0, 30.2)],
	["cubierta_mayor", Vector2(40.0, 26.6)],
	["cubierta_brea", Vector2(37.6, 26.0)],
	["cubierta_tienda", Vector2(32.6, 22.6)],
	["proa_mascaron", Vector2(43.0, 19.8)],
	["balcon_lona", Vector2(53.0, 23.4)],
	["archivo_ulla", Vector2(52.6, 45.6)],
	["archivo_contratos", Vector2(53.8, 47.0)],
]
# Rutas por las tablas (x, z), en línea recta de punto a punto.
const A_POPA := [Vector2(40.0, 55.6), Vector2(40.0, 51.5)]
const A_GRABADO := [Vector2(37.6, 51.2), Vector2(37.5, 52.3)]
const DE_GRABADO_A_ULLA := [Vector2(37.6, 50.0), Vector2(40.0, 50.0), Vector2(40.0, 45.9), Vector2(47.0, 45.9),
	Vector2(52.6, 45.9), Vector2(52.6, 45.3)]
const A_CONTRATOS := [Vector2(53.4, 45.9), Vector2(53.6, 47.3)]
const DEL_ARCHIVO_A_LA_QUILLA := [Vector2(53.4, 45.9), Vector2(47.0, 45.9), Vector2(40.0, 45.9), Vector2(40.0, 44.0),
	Vector2(40.0, 39.6)]
const A_LA_CUBIERTA := [Vector2(40.0, 33.0), Vector2(40.0, 27.6)]
const A_PALO := [Vector2(40.0, 24.8)]
const A_BREA := [Vector2(37.4, 26.6)]
const DE_BREA_AL_PALO := [Vector2(40.0, 26.6), Vector2(40.0, 24.8)]
const DEL_PALO_A_LA_TIENDA := [Vector2(40.0, 27.6), Vector2(36.0, 27.6), Vector2(32.6, 22.4)]
const DE_LA_TIENDA_A_LA_PROA := [Vector2(36.0, 27.6), Vector2(42.0, 27.6), Vector2(42.0, 21.0), Vector2(43.0, 19.8)]
const DE_LA_PROA_AL_BALCON := [Vector2(42.0, 21.0), Vector2(47.4, 23.4), Vector2(53.6, 23.4)]
const DEL_BALCON_A_ULLA := [Vector2(47.4, 23.4), Vector2(47.4, 27.6), Vector2(40.0, 27.6), Vector2(40.0, 33.0),
	Vector2(40.0, 44.0), Vector2(40.0, 45.9), Vector2(47.0, 45.9), Vector2(52.6, 45.9), Vector2(52.6, 45.3)]
const DE_ULLA_A_LA_TABLA := [Vector2(52.6, 45.9), Vector2(47.0, 45.9), Vector2(40.0, 45.9), Vector2(40.0, 44.0),
	Vector2(38.8, 40.0), Vector2(38.8, 38.2)]

var v
var T
var Sunk
var P
var Inv
var E
var salida := ""
var perfil := "alto"
var modo := "todo"
var fallos := 0
var n_foto := 0
var registro: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		if a.begins_with("modo="):
			modo = a.trim_prefix("modo=")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_sunken")
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("calidad_proto", perfil)
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	E = load("res://encargos.gd")
	root.size = Vector2i(1280, 720)
	_jugar.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)
		registro.append("FALLO: " + t)


func _nota(t: String) -> void:
	print(t)
	registro.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(s * 1000.0):
		await process_frame


func _foto(nombre: String, medir := false) -> void:
	await _frames(3)
	n_foto += 1
	var ruta := salida.path_join("%s_%02d_%s.png" % [perfil, n_foto, nombre])
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png(ruta)
	if not medir:
		_nota("foto %s" % ruta.get_file())
		return
	var dibujos := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var t0 := Time.get_ticks_usec()
	await _frames(30)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / 30.0
	_nota("foto %s · %d dibujos · %d primitivas · %.1f ms/fotograma (PC)" % [ruta.get_file(), dibujos, prims, ms])


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


func _kael_en() -> Vector2:
	var p: Vector3 = v.kael.global_position
	return Vector2(p.x, p.z)


# Un tramo andando: clic en el suelo donde se ve el punto (si no se ve, en uno intermedio de la recta) hasta llegar.
func _andar_a(c: Vector2) -> bool:
	var t0 := Time.get_ticks_msec()
	var reintentos := 0
	var antes := _kael_en()
	while Time.get_ticks_msec() - t0 < int(MAX_TRAMO * 1000.0):
		if _kael_en().distance_to(c) < 0.5:
			return true
		if v.get("destino") == null:
			# (hacia la cámara, el punto queda fuera de la pantalla y se pulsa la mitad del tramo: solo cuentan los clics
			# que no mueven a Kael)
			if _kael_en().distance_to(antes) < 0.2:
				reintentos += 1
			antes = _kael_en()
			if reintentos > 4:
				break
			var objetivo := c
			var cam: Camera3D = v.cam
			for k in 6:
				var w: Vector3 = T.en_mundo(objetivo)
				var pp := cam.unproject_position(w)
				if not cam.is_position_behind(w) and Rect2(40, 90, 1200, 520).has_point(pp):
					await _clic(pp)
					break
				objetivo = _kael_en().lerp(objetivo, 0.5)
		await _frames(2)
	_ok(_kael_en().distance_to(c) < 1.0, "no llega a %s (se queda en %s)" % [c, _kael_en()])
	return _kael_en().distance_to(c) < 1.0


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
	while dg.current_timeline != null and veces < 30:
		await _tecla(KEY_ENTER)
		await _segundos(0.45)
		veces += 1
	_ok(dg.current_timeline == null, "el diálogo %s no acaba con Intro" % ruta.get_file())
	await _segundos(0.6)
	return ruta


func _sigue_andando(donde: String) -> void:
	var a := _kael_en()
	var objetivo := a + Vector2(0, 1.0)
	if T.prohibido(objetivo.x, objetivo.y):
		objetivo = a + Vector2(0, -1.0)
	var cam: Camera3D = v.cam
	await _clic(cam.unproject_position(T.en_mundo(objetivo)))
	await _segundos(1.0)
	_ok(_kael_en().distance_to(a) > 0.3, "%s: Kael no vuelve a andar" % donde)
	await _andar_a(a)


func _cargar_region() -> void:
	change_scene_to_file(REGION)
	await _frames(30)
	v = current_scene
	var t0 := Time.get_ticks_msec()
	while (v == null or v.get("kael") == null or v.get("casco") == null) and Time.get_ticks_msec() - t0 < 8000:
		await _frames(5)
		v = current_scene
	T = load("res://zonas3d/sunken/trazado.gd")
	Sunk = load("res://ciudades/sunken.gd")
	await _segundos(1.2)


# «Continuar»: la partida que guardó el juego, por Progreso.cargar(), y su escena.
func _continuar(donde: String) -> void:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var escena: String = P.cargar()
	_ok(escena == REGION, "%s: la partida guardada no vuelve a Sunken City 3D («%s»)" % [donde, escena])
	await _cargar_region()
	_nota("%s: cargada; Kael en %s" % [donde, _kael_en()])


func _buscar_boton(n: Node, texto: String, en_fila := "") -> Button:
	for c in n.find_children("*", "Button", true, false):
		if not ((c as Button).text.to_lower().contains(texto.to_lower()) and (c as Button).is_visible_in_tree()):
			continue
		if en_fila == "":
			return c
		var fila: Node = c.get_parent()
		for k in 3:
			var txt := ""
			for l in fila.find_children("*", "Label", true, false):
				txt += (l as Label).text + " "
			if txt.to_lower().contains(en_fila.to_lower()):
				return c
			fila = fila.get_parent()
	return null


# ---------------------------------------------------------------- el recorrido

func _preparar() -> void:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok", "comentarios_dichos"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	P.cargar()                                   # partida nueva (no hay archivo)
	for h in ["pv_02", "pv_03", "pv_05"]:        # Lya y Garon en el grupo (acto II: Sunken City)
		P.poner_hito(h)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("partida_lista", true)


func _jugar() -> void:
	await _frames(3)
	_preparar()
	await _cargar_region()
	if v == null or v.get("casco") == null:
		_ok(false, "no se cargó Sunken City 3D")
		_terminar()
		return
	_nota("perfil %s · casco %s" % [perfil, v.casco.resumen()])
	if modo != "vistas":
		await _recorrido()
	await _vistas()
	_terminar()


func _recorrido() -> void:
	var mis: Dictionary = E.de("sunk_sello")
	await _foto("llegada_muelle")
	# 1. el espejo de popa, el nombre raspado y la brecha
	await _ruta([A_POPA[0]], "muelle → popa")
	if await _accion("Examinar el espejo de popa"):
		await _segundos(0.6)
		await _foto("nombre_raspado")
	await _ruta([A_POPA[1]], "brecha")
	await _segundos(1.6)
	await _foto("popa_brecha_comentario")
	# 2. el grabado (la pista del secreto)
	await _ruta(A_GRABADO, "popa → grabado")
	if await _accion("Leer el grabado"):
		await _segundos(0.6)
		await _foto("grabado")
		_ok(Sunk.estado("grabado_visto"), "2: el grabado no se apunta")
	# 3. el Archivo del Águila: Ulla encarga la misión
	await _ruta(DE_GRABADO_A_ULLA, "grabado → Ulla")
	await _foto("archivo_ulla")
	if await _accion("Hablar con Ulla"):
		var r: String = await _dialogo("ulla_pedido")
		_ok(r.ends_with("sunk_ulla_pedido.dtl"), "3: Ulla no empieza por su encargo (%s)" % r.get_file())
	await _segundos(0.4)
	await _foto("aviso_mision")
	_ok(Sunk.estado("sello_pedido") and E.estado(mis) == "activo", "3: hablar con Ulla no empieza la misión")
	await _diario("diario_inicio")
	await _sigue_andando("tras el encargo")
	# 4. los contratos (el detalle de canon)
	await _ruta(A_CONTRATOS, "Ulla → contratos")
	if await _accion("Examinar los contratos"):
		await _segundos(0.8)
		await _foto("contratos")
		_ok(P.visto("sunken_contratos"), "4: los contratos no quedan vistos")
	# 5. la Quilla, bajo las costillas (la del medio no alumbra)
	await _ruta(DEL_ARCHIVO_A_LA_QUILLA, "Archivo → Quilla")
	await _foto("quilla_costilla_oscura")
	await _ruta(A_LA_CUBIERTA, "Quilla → Cubierta Mayor")
	await _foto("cubierta_mayor")
	# 6. el palo mayor sin la pista: solo la bandera
	await _ruta(A_PALO, "→ palo")
	if await _accion("Examinar el palo mayor"):
		await _segundos(0.6)
		await _foto("palo_bandera")
		_ok(not Sunk.estado("sello_hallado"), "6: sin la pista, el palo da el sello")
	# 7. Brea y su adivinanza
	await _ruta(A_BREA, "palo → Brea")
	if await _accion("Hablar con Brea"):
		var r: String = await _dialogo("brea_adivinanza")
		_ok(r.ends_with("sunk_brea_sello.dtl"), "7: Brea no da la pista (%s)" % r.get_file())
	_ok(E.paso_actual(mis).get("id", "") == "sello", "7: tras Brea no toca buscar el sello")
	# 8. guardar y cargar a mitad (lo guardó el juego al acabar el diálogo)
	var aqui := _kael_en()
	await _continuar("a mitad de misión")
	_ok(Sunk.estado("sello_pista") and not Sunk.estado("sello_hallado") and _kael_en().distance_to(aqui) < 1.0,
		"8: tras cargar a mitad, cambia algo (%s / %s)" % [_kael_en(), aqui])
	# 9. el sello, en la driza de la bandera
	await _ruta(DE_BREA_AL_PALO, "Brea → palo")
	if await _accion("Examinar el palo mayor"):
		await _segundos(0.6)
		await _foto("palo_sello")
		_ok(Sunk.estado("sello_hallado"), "9: el palo con la pista no da el sello")
	await _diario("diario_sello")
	# 10. la tienda del lugar 5
	await _ruta(DEL_PALO_A_LA_TIENDA, "palo → tienda")
	if await _accion("Ver el puesto"):
		await _segundos(0.8)
		await _foto("tienda")
		await _tecla(KEY_ESCAPE)
		await _segundos(0.4)
		if v.abierto != null and is_instance_valid(v.abierto):
			_nota("la tienda no se cerró con Esc: se cierra con su botón")
			var b := _buscar_boton(v.abierto, "cerrar")
			if b == null:
				b = _buscar_boton(v.abierto, "volver")
			if b != null:
				await _clic_boton(b)
				await _segundos(0.4)
		_ok(v.abierto == null or not is_instance_valid(v.abierto), "10: la tienda no se cierra")
	await _sigue_andando("tras la tienda")
	# 11. la proa en obras y el mascarón
	await _ruta(DE_LA_TIENDA_A_LA_PROA, "tienda → proa")
	await _segundos(1.2)
	await _foto("proa_mascaron")
	if await _accion("Examinar las cuerdas"):
		await _segundos(0.6)
		await _foto("proa_letrero")
	# 12. el balcón de estribor y la lona del dique
	await _ruta(DE_LA_PROA_AL_BALCON, "proa → balcón")
	if await _accion("Mirar la lona"):
		await _segundos(4.4)
		await _foto("lona_comentario")
	# 13. de vuelta con Ulla: el sello y el bronce
	await _ruta(DEL_BALCON_A_ULLA, "balcón → Ulla")
	var bronce0: int = Inv.cantidad(Sunk.MATERIAL)
	if await _accion("Hablar con Ulla"):
		var r: String = await _dialogo("ulla_fin")
		_ok(r.ends_with("sunk_ulla_fin.dtl"), "13: Ulla no reacciona al sello (%s)" % r.get_file())
	await _segundos(0.3)
	await _foto("aviso_bronce")
	_ok(Inv.cantidad(Sunk.MATERIAL) == bronce0 + 1 and E.estado(mis) == "hecho", "13: no da el bronce o no acaba la misión")
	if await _accion("Hablar con Ulla"):
		var r: String = await _dialogo("")
		_ok(r.ends_with("sunk_ulla_despues.dtl"), "13: después, Ulla no dice lo nuevo (%s)" % r.get_file())
	_ok(Inv.cantidad(Sunk.MATERIAL) == bronce0 + 1, "13: hablar otra vez da más bronce")
	await _diario("diario_final")
	# 14. el secreto: la tabla bajo la costilla que no alumbra
	await _ruta(DE_ULLA_A_LA_TABLA, "Ulla → tabla")
	var oro0: int = Inv.oro()
	if await _accion("Mirar bajo la tabla"):
		await _segundos(0.8)
		await _foto("tabla_paga")
		await _segundos(6.8)
		await _foto("tabla_comentario")
	_ok(Sunk.paga_encontrada() and Inv.oro() == oro0 + 80, "14: la tabla no da la paga")
	if await _accion("Examinar la tabla"):
		await _segundos(0.4)
		_ok(Inv.oro() == oro0 + 80, "14: la tabla da la paga dos veces")
	# 15. al final: guardar y cargar, y nada se repite
	v._guardar()
	var oro1: int = Inv.oro()
	await _continuar("al final")
	_ok(Inv.oro() == oro1 and Sunk.paga_encontrada() and E.estado(mis) == "hecho"
		and Inv.cantidad(Sunk.MATERIAL) == bronce0 + 1, "15: tras cargar al final, cambia algo")
	# 16. la forja de Kael: estudiar el bronce y forjar la Guarda del Águila
	await _forja()


func _diario(foto: String) -> void:
	var capa := CanvasLayer.new()
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


func _forja() -> void:
	var a = load("res://alquimia_menu.gd").new()
	a.taller = "forja"
	v.add_child(a)
	await _segundos(0.5)
	var b := _buscar_boton(a, "INVESTIGAR")
	if b != null:
		await _clic_boton(b)
		await _segundos(0.4)
	await _foto("forja_investigar")
	var estudiar := _buscar_boton(a, "ESTUDIAR", "bronce")
	_ok(estudiar != null, "16: la forja no ofrece estudiar «El bronce del casco»")
	if estudiar != null:
		await _clic_boton(estudiar)
		await _segundos(0.4)
	_ok(load("res://investigacion.gd").estado("kael_bronce_aguila") == "completada", "16: la investigación no se completa")
	b = _buscar_boton(a, "RECETAS")
	if b != null:
		await _clic_boton(b)
		await _segundos(0.4)
	var fab := _buscar_boton(a, "FABRICAR", "Guarda del")
	_ok(fab != null and not fab.disabled, "16: no se puede forjar la Guarda del Águila")
	var vit0: int = int(load("res://grupo.gd").estadisticas("Kael")["atributos"]["vitalidad"])
	if fab != null:
		var scroll = a.lista.get_parent() if a.get("lista") != null else null
		var veces := 0
		while scroll is ScrollContainer and not (scroll as ScrollContainer).get_global_rect().encloses(fab.get_global_rect()) and veces < 12:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_WHEEL_DOWN
			e.position = (scroll as ScrollContainer).get_global_rect().get_center()
			e.global_position = e.position
			e.pressed = true
			Input.parse_input_event(e)
			await _frames(3)
			veces += 1
		await _clic_boton(fab)
		await _segundos(0.4)
	await _foto("forja_guarda")
	_ok(int(load("res://grupo.gd").estadisticas("Kael")["atributos"]["vitalidad"]) == vit0 + 2
		and Inv.cantidad(Sunk.MATERIAL) == 0, "16: forjar no da +2 de vitalidad o no gasta el bronce")
	await _tecla(KEY_ESCAPE)
	await _segundos(0.3)
	if is_instance_valid(a):
		a.queue_free()
	await _frames(2)


func _vistas() -> void:
	for d in VISTAS:
		v._colocar_kael(T.en_mundo(d[1]))
		if v.grupo != null:
			v.grupo.colocar(Vector3.BACK)
		await _segundos(1.6)
		await _foto("vista_" + d[0], true)


func _terminar() -> void:
	_nota("FALLOS: %d" % fallos)
	var f := FileAccess.open(salida.path_join("recorrido_%s.txt" % perfil), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(registro) + "\n")
		f.close()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
