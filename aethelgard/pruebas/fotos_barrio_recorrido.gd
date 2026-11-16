extends SceneTree
# V12 (16/11): RECORRIDO JUGADO del BARRIO EXPERIMENTAL de Oakhaven (agente C; zonas3d/barrio/, PROPUESTA, solo desde el
# banco de Auditoría) con los CONTROLES NORMALES y sin poner ningún estado de la misión a mano:
#   - andar: clics de ratón en el suelo donde se ve el sitio (como un toque: vista3d.gd → destino), tramo a tramo por el
#     grafo del trazado;
#   - hablar y examinar: Intro cuando el botón de acción ofrece lo esperado (_accion); diálogos: Intro hasta que acaban
#     (_dialogo); «Guardar y recargar»: clic en su botón (guarda, lee, restaura y vuelve a cargar la escena).
#   - Para encontrar a un vecino que anda se mira dónde está (barrio_vivo.estado_de) y se va hacia él andando; si está
#     dentro de su casa, se espera a que salga (con el reloj del juego más deprisa solo mientras se espera).
# «Antes de que se enfríe» entera, DOS veces:
#   A. orden normal: el carro, Maela, el taller (Damián), Odila y la galga, medir, el pasador, «Guardar y recargar» a
#      mitad, poner el pasador, la cesta de Maela, la entrega a Odila y la vuelta a Maela (Éter ×2 una vez);
#   B. la galga PRIMERO (sin misión), medir (empieza), el pasador, reparar, la cesta, la entrega y el premio.
# Además: una captura por tramo (6) y de cada rutina; las puertas de los interiores (hoy «en obras»: B aún no los ha
# hecho; cuando estén, este recorrido entra por la puerta del taller y de la vivienda: ver _interior()).
# Uso: lista_pruebas.txt (fotos_barrio_recorrido, ventana): «3d sin_prologo salida={salida}». Con «modo=rutinas», una
# visita a cada rutina para el vídeo (Movie Maker: --write-movie x.avi --fixed-fps 30); «solo=normal», solo la misión A
# (para grabarla). Partida del banco
# (user://banco_pruebas.save, carpeta aislada). Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const FPS := 30.0
const MAX_TRAMO := 14.0

var v                                        # la región (barrio.gd)
var salida := ""
var modo := "mision"
var fallos := 0
var n_foto := 0
var registro: PackedStringArray = []
var P
var Inv
var E
var BP


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
		if a.begins_with("modo="):
			modo = a.trim_prefix("modo=")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("recorrido_barrio")
	DirAccess.make_dir_recursive_absolute(salida)
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	E = load("res://encargos.gd")
	BP = load("res://banco_pruebas.gd")
	root.size = Vector2i(1280, 720)
	_jugar.call_deferred()


# Tiempo del JUEGO (fotogramas a 30 por segundo: igual con el Movie Maker que sin él).
func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _frames(maxi(1, int(s * FPS)))


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


func _kael() -> Vector3:
	return v.kael.global_position


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Un tramo andando: clic en el suelo donde se ve el punto (si no se ve, en uno intermedio de la recta) hasta llegar.
func _andar_a(c: Vector3, cerca := 0.6) -> bool:
	var f := 0
	var reintentos := 0
	while f < int(MAX_TRAMO * FPS):
		if _plana(_kael(), c) < cerca:
			return true
		if v.get("destino") == null:
			if reintentos > 6:
				break
			reintentos += 1
			var objetivo := c
			if reintentos % 2 == 0:                      # (algo en medio, un vecino: probar por un lado, como haría quien juega)
				var d := Vector3(c.x - _kael().x, 0, c.z - _kael().z).normalized()
				objetivo = _kael() + d * 0.8 + Vector3(-d.z, 0, d.x) * (1.0 if reintentos % 4 == 0 else -1.0)
			var cam: Camera3D = v.cam
			for k in 6:
				var w := Vector3(objetivo.x, T.altura(objetivo.x, objetivo.z), objetivo.z)
				var pp := cam.unproject_position(w)
				if not cam.is_position_behind(w) and _se_puede_tocar(pp):
					await _clic(pp)
					break
				objetivo = _kael().lerp(objetivo, 0.5)
		await _frames(2)
		f += 2
	_ok(_plana(_kael(), c) < cerca + 0.8, "no llega a %s (se queda en %s)" % [c, _kael()])
	return _plana(_kael(), c) < cerca + 0.8


# ¿Se puede tocar ahí? (en pantalla, sin los botones de la interfaz)
func _se_puede_tocar(pp: Vector2) -> bool:
	if not Rect2(20, 100, 1240, 610).has_point(pp):
		return false
	for b in [v.boton_accion, v.boton_recargar]:
		if b != null and b.visible and b.get_global_rect().grow(8).has_point(pp):
			return false
	return true


# Ir andando a un punto por los caminos (la recta si se puede; si no, por el grafo del trazado).
func _ir(destino: Vector3, nombre: String, cerca := 0.6) -> void:
	var pts: Array = v.vivo._ruta(_kael(), destino, "", "recorrido")
	var f0 := Engine.get_process_frames()
	for i in range(1, pts.size()):
		if not await _andar_a(pts[i], cerca if i == pts.size() - 1 else 0.9):
			_nota("ruta a %s: atasco antes de %s" % [nombre, pts[i]])
			return
	_nota("a %s: %.1f s" % [nombre, (Engine.get_process_frames() - f0) / FPS])


# Espera a que el botón ofrezca «texto» y pulsa Intro.
func _accion(texto: String, s := 3.0) -> bool:
	var f := 0
	while f < int(s * FPS):
		if v.boton_accion.visible and v.boton_accion.text == texto:
			await _tecla(KEY_ENTER)
			return true
		await _frames(2)
		f += 2
	_ok(false, "el botón no ofrece «%s» (ofrece «%s», visible %s)" % [texto, v.boton_accion.text, v.boton_accion.visible])
	return false


# Un diálogo entero con Intro; foto en su primera frase. Devuelve el diálogo que salió.
func _dialogo(foto: String) -> String:
	var dg = root.get_node_or_null("Dialogic")
	if dg == null:
		_ok(false, "sin Dialogic")
		return ""
	var f := 0
	while dg.current_timeline == null and f < 60:
		await _frames(2)
		f += 2
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
	_nota("diálogo %s" % ruta.get_file())
	return ruta


# Ir a hablar con un vecino que anda: se mira dónde está y se va hacia él hasta que el botón lo ofrece.
func _hablar_con(id: String, foto: String) -> String:
	var boton: String = Barrio.NPCS[id]["boton"]
	var f := 0
	while f < int(150 * FPS):
		var e: Dictionary = v.vivo.estado_de(id)
		if e["lugar"] != v.interior:                     # (dentro de su casa: se espera a que salga, más deprisa)
			Engine.time_scale = 6.0
			await _frames(10)
			f += 10
			continue
		Engine.time_scale = 1.0
		if v.boton_accion.visible and v.boton_accion.text == boton:
			await _tecla(KEY_ENTER)
			var r := await _dialogo(foto)
			await _apartarse(v.vivo.estado_de(id)["pos"])
			return r
		var p: Vector3 = e["pos"]
		var junto := _junto_a(p)
		if _plana(_kael(), junto) > 4.0:
			var pts: Array = v.vivo._ruta(_kael(), junto, "", "recorrido")
			await _andar_a(pts[1] if pts.size() > 2 else junto, 1.0)
			f += 30
		else:
			await _andar_a(junto, 0.5)
			await _frames(6)
			f += 20
	Engine.time_scale = 1.0
	_ok(false, "no se llega a hablar con %s" % id)
	return ""


# Tras hablar, un paso atrás (lejos del vecino) para no quedarse pegado a él.
func _apartarse(p: Vector3) -> void:
	var d := Vector3(_kael().x - p.x, 0, _kael().z - p.z)
	if d.length() < 0.05:
		d = Vector3(0, 0, 1)
	for giro in [0.0, 0.8, -0.8, 1.6, -1.6]:
		var q := p + d.normalized().rotated(Vector3.UP, giro) * 1.8
		if T.andable(q.x, q.z) and not v.vivo.ocupa(q):
			await _andar_a(Vector3(q.x, T.altura(q.x, q.z), q.z), 0.5)
			return


# Un sitio andable a 1,2 m de un vecino, lo más lejos posible de los otros botones (puertas y piezas) y cerca de Kael.
func _junto_a(p: Vector3) -> Vector3:
	var otros: Array = []
	for id in T.PUERTAS:
		otros.append(T.PUERTAS[id]["fuera"])
	for pid in Barrio.PIEZAS:
		if not str(Barrio.PIEZAS[pid]["ancla"]).begins_with("int_"):
			otros.append(T.ancla(Barrio.PIEZAS[pid]["ancla"]))
	var mejor := p + Vector3(0, 0, 1.2)
	var nota := -INF
	for i in 12:
		var a := TAU * i / 12.0
		var q := p + Vector3(sin(a), 0, cos(a)) * 1.2
		if not T.andable(q.x, q.z) or v.vivo.ocupa(q):
			continue
		var lejos := INF
		for o in otros:
			lejos = minf(lejos, _plana(q, o))
		var n := minf(lejos, 2.5) * 2.0 - _plana(q, _kael()) * 0.1
		if n > nota:
			nota = n
			mejor = q
	return mejor


func _aviso() -> String:
	return str(v.ultimo_aviso)


func _cargar_region() -> void:
	v = null
	for i in 600:
		await process_frame
		var c = current_scene
		if c != null and c.scene_file_path == ESCENA and c.get("kael") != null and c.get("vivo") != null:
			v = c
			break
	await _segundos(1.0)


func _guardar_y_recargar(donde: String) -> void:
	var antes: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}).duplicate()
	var k := _kael()
	var viejo = v
	await _clic_boton(v.boton_recargar)
	for i in 300:
		await process_frame
		if current_scene != viejo and current_scene != null and current_scene.scene_file_path == ESCENA:
			break
	await _cargar_region()
	_ok(v != null and v != viejo, "%s: «Guardar y recargar» no vuelve a cargar el barrio" % donde)
	if v == null:
		return
	var despues: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {})
	_ok(despues == antes, "%s: tras recargar, la misión no es la misma (%s → %s)" % [donde, antes, despues])
	_ok(_plana(_kael(), k) < 1.0, "%s: Kael no vuelve a aparecer donde estaba (%s → %s)" % [donde, k, _kael()])
	_nota("%s: guardado y recargado; Kael en %s" % [donde, _kael()])


func _diario(foto: String) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 90
	v.add_child(capa)
	var d = load("res://diario.gd").new()
	capa.add_child(d)
	await _segundos(0.6)
	for c in d.find_children("*", "Button", true, false):
		if (c as Button).text.to_lower().contains("encargos") and (c as Button).is_visible_in_tree():
			await _clic_boton(c)
			await _segundos(0.5)
			break
	await _foto(foto)
	await _tecla(KEY_ESCAPE)
	await _segundos(0.3)
	if is_instance_valid(d) and d.is_inside_tree():
		d.queue_free()
	capa.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- sitios

const JUNTO_CARRO := Vector3(-13.5, 0, 2.1)          # (examinar el carro del horno, del lado de la calle)
const ESTADO_MISION := "bar_enfria"


func _al_carro(texto: String, foto: String) -> String:
	await _ir(JUNTO_CARRO, "el carro del horno", 0.4)
	await _segundos(0.4)
	if await _accion(texto):
		await _segundos(0.8)
		await _foto(foto)
	return _aviso()


# Las puertas de los interiores: hoy «en obras» (B); con el interior hecho, se entra y se sale (y se hace la foto).
func _interior(id: String) -> void:
	var d: Dictionary = T.PUERTAS[id]
	await _ir(d["fuera"], "la puerta de " + id, 0.5)
	if not await _accion(d["texto"]):
		return
	await _segundos(1.2)
	if v.interior == id:
		await _foto("interior_" + id)
		_nota("dentro de %s" % id)
		await _accion("Salir")
		await _segundos(1.2)
	else:
		_nota("puerta de %s: «%s»" % [id, _aviso()])


# ---------------------------------------------------------------- el recorrido

func _preparar() -> void:
	BP.preparar_partida()                          # la partida del banco: prólogo visto, pv_02, sin el barrio
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", "bajo")
	if Engine.has_meta("barrio_reloj"):
		Engine.remove_meta("barrio_reloj")


func _jugar() -> void:
	await _frames(3)
	_preparar()
	change_scene_to_file(ESCENA)
	await _cargar_region()
	if v == null:
		_ok(false, "no se cargó el barrio")
		_terminar()
		return
	if modo == "rutinas":
		await _rutinas()
	else:
		await _mision_normal()
		if not "solo=normal" in OS.get_cmdline_user_args():
			await _mision_galga_primero()
	_terminar()


func _mision_normal() -> void:
	var mis: Dictionary = E.de(ESTADO_MISION)
	_nota("A. ORDEN NORMAL")
	await _foto("t1_caravanas")
	_ok(E.estado(mis) == "oculto", "A: la misión sale antes de empezar")
	# 1. el carro parado
	await _ir(T.ancla("n_com_o"), "la calle comercial")
	await _foto("t2_comercial")
	var a := await _al_carro("Examinar el carro", "A01_carro_examinado")
	_ok(a.contains("Misión: Antes de que se enfríe") and E.estado(mis) == "activo", "A1: examinar el carro no empieza la misión («%s»)" % a)
	# 2. Maela lo vio
	var r := await _hablar_con("maela", "A02_maela")
	_ok(r.ends_with("bar_maela_pendiente.dtl"), "A2: Maela no dice lo del pasador (%s)" % r.get_file())
	await _diario("A03_diario_inicio")
	# 3. el taller
	await _ir(T.ancla("n_plaza"), "la plaza")
	await _foto("t3_plaza")
	await _ir(T.ancla("n_patio_s"), "el patio de talleres")
	await _foto("t4_talleres")
	await _interior("taller")
	r = await _hablar_con("damian", "A04_damian_encargo")
	_ok(r.ends_with("bar_damian_encargo.dtl") and Barrio.estado("enf_taller"), "A3: Damián no da el encargo (%s)" % r.get_file())
	# 4. la galga, en casa de Odila
	await _ir(T.ancla("n_res_e"), "la calle de las casas")
	await _foto("t5_residencial")
	await _interior("vivienda")
	r = await _hablar_con("odila", "A05_odila_galga")
	_ok(Barrio.estado("enf_galga"), "A4: no se consigue la galga (%s)" % r.get_file())
	r = await _hablar_con("nela", "A06_nela")
	# 5. medir el eje
	a = await _al_carro("Examinar el carro", "A07_medir")
	_ok(Barrio.estado("enf_medida") and a.begins_with(Barrio.CARRO["medir"]), "A5: no se mide el eje («%s»)" % a)
	# 6. el pasador
	r = await _hablar_con("damian", "A08_damian_pasador")
	_ok(r.ends_with("bar_damian_pasador.dtl") and Barrio.estado("enf_pasador"), "A6: Damián no corta el pasador (%s)" % r.get_file())
	# guardar y recargar a mitad (el botón de la región)
	await _guardar_y_recargar("A a mitad")
	_ok(Barrio.estado("enf_pasador") and not Barrio.estado("enf_reparado"), "A: tras recargar, la misión no sigue en el pasador")
	# 7. reparar
	a = await _al_carro("Examinar el carro", "A09_reparado")
	_ok(Barrio.estado("enf_reparado"), "A7: el carro no se arregla («%s»)" % a)
	await _segundos(3.0)
	await _foto("A10_reparto")
	# 8. la cesta
	r = await _hablar_con("maela", "A11_maela_cesta")
	_ok(r.ends_with("bar_maela_cesta.dtl") and Barrio.estado("enf_cesta"), "A8: Maela no da la cesta (%s)" % r.get_file())
	# 9. la entrega
	r = await _hablar_con("odila", "A12_odila_entrega")
	_ok(r.ends_with("bar_odila_entrega.dtl") and Barrio.estado("enf_entrega"), "A9: Odila no recibe la cesta (%s)" % r.get_file())
	# 10. vuelta a Maela: el premio, una vez
	var eter0: int = Inv.cantidad("Éter")
	r = await _hablar_con("maela", "A13_maela_fin")
	_ok(r.ends_with("bar_maela_fin.dtl") and Inv.cantidad("Éter") == eter0 + 2, "A10: el premio no es Éter ×2 (%d → %d)" % [eter0, Inv.cantidad("Éter")])
	await _segundos(2.0)
	await _foto("A14_premio")
	r = await _hablar_con("maela", "")
	_ok(r.ends_with("bar_maela_despues.dtl") and Inv.cantidad("Éter") == eter0 + 2, "A10: el premio se repite (%s)" % r.get_file())
	_ok(E.estado(mis) == "hecho", "A: la misión no acaba")
	await _diario("A15_diario_final")
	# el bucle se cierra por el atajo
	await _ir(T.ancla("n_res_o"), "el final de la calle")
	await _ir(T.ancla("n_atajo_n"), "el atajo")
	await _ir(Vector3(-42.0, 0.7, -16.0), "el arco del atajo")
	await _foto("t6_atajo")
	await _ir(T.ancla("n_establo"), "el establo")
	await _foto("A16_establo_avena")
	await _accion("Examinar a Avena")
	await _segundos(1.0)
	_ok(Barrio.estado("j_sabe_no_culpa_caballo"), "A: examinar a Avena no apunta nada")


func _mision_galga_primero() -> void:
	_nota("B. LA GALGA PRIMERO")
	_preparar()
	change_scene_to_file(ESCENA)
	await _cargar_region()
	var mis: Dictionary = E.de(ESTADO_MISION)
	await _ir(T.ancla("n_com_o"), "la calle comercial")
	await _ir(T.ancla("n_plaza"), "la plaza")
	await _ir(T.ancla("n_patio_n"), "el patio de talleres")
	var r := await _hablar_con("odila", "B01_odila_galga")
	_ok(Barrio.estado("enf_galga") and E.estado(mis) == "oculto", "B1: la galga suelta empieza la misión o no se consigue (%s)" % E.estado(mis))
	var a := await _al_carro("Examinar el carro", "B02_medir_empieza")
	_ok(a.contains("Misión") and Barrio.estado("enf_medida") and E.estado(mis) == "activo", "B2: medir con la galga no empieza la misión («%s»)" % a)
	await _guardar_y_recargar("B tras medir")
	r = await _hablar_con("damian", "B03_damian_pasador")
	_ok(r.ends_with("bar_damian_pasador.dtl") and Barrio.estado("enf_pasador"), "B3: Damián no corta el pasador (%s)" % r.get_file())
	a = await _al_carro("Examinar el carro", "B04_reparado")
	_ok(Barrio.estado("enf_reparado"), "B4: no se arregla el carro")
	r = await _hablar_con("maela", "B05_maela_cesta")
	r = await _hablar_con("odila", "B06_odila_entrega")
	var eter0: int = Inv.cantidad("Éter")
	r = await _hablar_con("maela", "B07_maela_fin")
	_ok(E.estado(mis) == "hecho" and Inv.cantidad("Éter") == eter0 + 2, "B: la galga primero no acaba con Éter ×2")
	await _diario("B08_diario_final")


# Una visita a cada rutina (para el vídeo): Kael se pone cerca y la sigue un rato.
func _rutinas() -> void:
	await _foto("R00_entrada")
	for paso in [["brena", "cepillar", 22.0], ["brena", "verter", 16.0], ["tobias", "coger", 26.0], ["maela", "dejar", 18.0],
			["maela", "coger", 20.0]]:
		var id: String = paso[0]
		var w: Dictionary = v.vivo.vecinos[id]
		var objetivo := -1.0
		for s in w["segs"]:
			if s["lugar"] == "" and s["clip"] == paso[1]:
				objetivo = float(s["t0"]) - 4.0
				break
		if objetivo < 0.0:
			continue
		var tau: float = v.vivo.estado_de(id)["tau"]
		v.vivo.avanzar_reloj(fposmod(objetivo - tau, float(w["ciclo"])))   # (adelanta el reloj del barrio a ese momento)
		var e: Dictionary = v.vivo.estado_de(id)
		await _ir(e["pos"] + Vector3(1.6, 0, 1.6), id, 0.8)
		var f := 0
		while f < int(float(paso[2]) * FPS):
			var p: Vector3 = v.vivo.estado_de(id)["pos"]
			if _plana(_kael(), p) > 3.2:
				await _andar_a(p + Vector3(1.4, 0, 1.4), 1.0)
				f += 20
			else:
				await _frames(10)
				f += 10
			if f % 150 < 10:
				await _foto("R_%s_%s" % [id, paso[1]])


func _terminar() -> void:
	Engine.time_scale = 1.0
	var f := FileAccess.open(salida.path_join("recorrido.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(registro) + "\nFALLOS: %d\n" % fallos)
		f.close()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
