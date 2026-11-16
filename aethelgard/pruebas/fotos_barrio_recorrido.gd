extends SceneTree
# V12 (16/11): RECORRIDO JUGADO del BARRIO EXPERIMENTAL de Oakhaven (agente C; zonas3d/barrio/, PROPUESTA, solo desde el
# banco de Auditoría) con los CONTROLES NORMALES y sin poner ningún estado de la misión a mano, CON LOS INTERIORES de B:
#   - andar: clics de ratón en el suelo donde se ve el sitio (como un toque: vista3d.gd → destino), tramo a tramo por el
#     grafo del trazado fuera y, dentro, por tramos rectos entre los muebles (barrio_vivo._ruta_dentro);
#   - los clics funcionan a CUALQUIER tamaño de ventana: el proyecto conserva 16:9 (franjas negras a 1600×720, como el
#     Redmi) y la posición que se calcula en el viewport (1280×720) se pasa a la ventana con root.get_final_transform()
#     antes de Input.parse_input_event (si no, a 1600×720 cada clic caía 160 px a la izquierda);
#   - entrar y salir de VERDAD: el botón de la puerta (en la vivienda, la primera vez se llama y Odila abre) y, dentro,
#     andar hasta el botón «Salir»;
#   - hablar y examinar: Intro cuando el botón de acción ofrece lo esperado (_accion); diálogos: Intro hasta que acaban
#     (_dialogo); «Guardar y recargar»: clic en su botón (guarda, lee, restaura y vuelve a cargar la escena).
#   - Para encontrar a un vecino se mira dónde está (barrio_vivo.estado_de): si está dentro de su casa, se entra; si
#     está fuera y Kael dentro, se sale; y se va hacia él andando.
# «Antes de que se enfríe» entera, DOS veces:
#   A. orden normal: el carro, el horno (por dentro), Maela, el taller (la trastienda cerrada y su aviso, lo privado de
#      Damián, el clavo vacío, Damián dentro, la trastienda abierta), la vivienda (llamar, Odila y Nela dentro, el arcón,
#      la rueda, coger la galga de la repisa y que la repisa quede vacía), «Guardar y recargar» DENTRO (reaparece en la
#      puerta de fuera, como está diseñado, y la misión sigue en su paso), medir, el pasador (la galga vuelve a su clavo),
#      poner el pasador, la cesta de Maela, la entrega a Odila dentro y la vuelta a Maela (Éter ×2 una vez y nada al
#      repetir), el atajo y Avena;
#   B. la galga PRIMERO: en casa de Odila, cogerla sin preguntar no vale (Odila llama la atención); preguntada, se coge y
#      la misión NO empieza; medir (empieza), «Guardar y recargar» fuera, el pasador, reparar, la cesta, la entrega y el
#      premio (Éter ×2 una vez).
# Uso: lista_pruebas.txt (fotos_barrio_recorrido, ventana): «3d sin_prologo salida={salida}»; mejor con --fixed-fps 30
# (el tiempo del juego va a 30 por segundo, igual que con el Movie Maker) y, para ver la franja negra, --resolution
# 1600x720 (o «tam=1600x720»). «solo=normal», solo la misión A (para grabarla: --write-movie x.avi --fixed-fps 30);
# «modo=rutinas», una visita a cada rutina (vídeo). Partida del banco (user://banco_pruebas.save, carpeta aislada).
# Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const Interiores := preload("res://zonas3d/barrio/interiores.gd")
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
	var tam := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		if a.begins_with("modo="):
			modo = a.trim_prefix("modo=")
		if a.begins_with("tam="):
			tam = a.trim_prefix("tam=")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("recorrido_barrio")
	DirAccess.make_dir_recursive_absolute(salida)
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	E = load("res://encargos.gd")
	BP = load("res://banco_pruebas.gd")
	if tam.contains("x"):
		root.size = Vector2i(int(tam.get_slice("x", 0)), int(tam.get_slice("x", 1)))
	_jugar.call_deferred()


# Tiempo del JUEGO (fotogramas a 30 por segundo: igual con el Movie Maker o --fixed-fps 30 que sin ellos).
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


# Un clic en «pos», en coordenadas del VIEWPORT (las de la cámara y de los botones: 1280×720). Input.parse_input_event
# las quiere en las de la VENTANA: se pasan por la transformación final de la raíz (el estiramiento y la franja negra de
# 16:9). Así vale a 1280×720, a 1600×720 (el Redmi) o a cualquier otro tamaño.
func _clic(pos: Vector2) -> void:
	var w: Vector2 = root.get_final_transform() * pos
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = w
	e.global_position = w
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var s := InputEventMouseButton.new()
	s.button_index = MOUSE_BUTTON_LEFT
	s.position = w
	s.global_position = w
	s.pressed = false
	Input.parse_input_event(s)
	await _frames(2)


func _clic_boton(b: Control) -> void:
	await _clic(b.get_global_rect().get_center())


func _kael() -> Vector3:
	return v.kael.global_position


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Lo que se pisa y su altura, fuera o dentro.
func _andable(q: Vector3) -> bool:
	if v.interior != "":
		return v.interiores.andable(q)
	return T.andable(q.x, q.z) and not v.vivo.ocupa(q)


func _suelo(q: Vector3) -> Vector3:
	if v.interior != "":
		return Vector3(q.x, v.interiores.altura(q), q.z)
	return Vector3(q.x, T.altura(q.x, q.z), q.z)


# Un tramo andando: clic en el suelo donde se ve el punto (si no se ve, en uno intermedio de la recta) hasta llegar.
func _andar_a(c: Vector3, cerca := 0.6, avisar := true) -> bool:
	var f := 0
	var reintentos := 0
	while f < int(MAX_TRAMO * FPS):
		if _plana(_kael(), c) < cerca:
			return true
		if v.get("destino") == null:
			if reintentos > 10:
				break
			if reintentos > 0:
				await _frames(12)                        # (un vecino en medio: le da tiempo a apartarse)
				f += 12
			reintentos += 1
			var objetivo := c
			if reintentos % 2 == 0 and v.interior == "":  # (fuera, un vecino en medio: probar por un lado)
				var d := Vector3(c.x - _kael().x, 0, c.z - _kael().z).normalized()
				objetivo = _kael() + d * 0.8 + Vector3(-d.z, 0, d.x) * (1.0 if reintentos % 4 == 0 else -1.0)
			elif reintentos > 1 and v.interior != "":     # (dentro, el toque cae en alguien del grupo: un punto más cerca)
				objetivo = _kael().lerp(c, [0.5, 0.75, 0.3][reintentos % 3])
			var cam: Camera3D = v.cam
			for k in 6:
				var w := _suelo(objetivo)
				var pp := cam.unproject_position(w)
				if not cam.is_position_behind(w) and _se_puede_tocar(pp):
					await _clic(pp)
					break
				objetivo = _kael().lerp(objetivo, 0.5)
		await _frames(2)
		f += 2
	var llega := _plana(_kael(), c) < cerca + 0.8
	if not llega:
		var dg = root.get_node_or_null("Dialogic")
		var bajo = root.gui_get_hovered_control() if root.has_method("gui_get_hovered_control") else null
		_nota("  (no llega a %s desde %s: ocupado %s, cambiando %s, diálogo %s, bloqueo %.2f, destino %s, control bajo el ratón %s, aviso «%s»)" % [
			c, _kael(), v.ocupado(), v.cambiando, dg.current_timeline if dg != null else null, v._bloqueo, v.destino,
			bajo.get_path() if bajo != null else null, _aviso()])
	if avisar:
		_ok(llega, "no llega a %s (se queda en %s, dentro de «%s»)" % [c, _kael(), v.interior])
	return llega


# ¿Se puede tocar ahí? (en pantalla, sin los botones de la interfaz)
func _se_puede_tocar(pp: Vector2) -> bool:
	if not Rect2(20, 100, 1240, 610).has_point(pp):
		return false
	for b in [v.boton_accion, v.boton_recargar]:
		if b != null and b.visible and b.get_global_rect().grow(8).has_point(pp):
			return false
	return true


# Ir andando a un punto de la zona de Kael: fuera, por los caminos (la recta o el grafo); dentro, por tramos rectos
# entre los muebles.
# Si un toque se desvía (cae en un tejado o en alguien del grupo) y Kael se queda fuera de la ruta, se vuelve a calcular
# desde donde esté (como haría quien juega: tocar otra vez), hasta tres veces.
func _ir(destino: Vector3, nombre: String, cerca := 0.6) -> void:
	var f0 := Engine.get_process_frames()
	for intento in 3:
		var pts: Array = []
		if v.interior != "":                          # (con holgura: Kael anda a pasos de 15 cm y para a 15 cm del punto)
			for m in [v.vivo.HOLGURA_KAEL, 0.08, 0.0]:
				pts = v.vivo._ruta_dentro(_kael(), destino, v.interior, "recorrido", m)
				if not pts.is_empty():
					break
		else:
			pts = v.vivo._ruta(_kael(), destino, "", "recorrido")
		var bien := true
		for i in range(1, pts.size()):
			var ultimo := i == pts.size() - 1
			# (dentro, cada punto intermedio se pisa de verdad: la recta siguiente sale de él y pasa a centímetros de
			# los muebles; Kael se para a < 15 cm de donde se toca)
			var tramo := cerca if ultimo else (0.2 if v.interior != "" else 0.5)
			if not await _andar_a(pts[i], tramo, intento == 2):
				_nota("ruta a %s: atasco antes de %s (intento %d)" % [nombre, pts[i], intento + 1])
				bien = false
				break
		if bien:
			_nota("a %s: %.1f s" % [nombre, (Engine.get_process_frames() - f0) / FPS])
			return


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
	_nota("diálogo %s%s" % [ruta.get_file(), " (dentro de %s)" % v.interior if v.interior != "" else ""])
	return ruta


# ---------------------------------------------------------------- puertas

# Entrar por la puerta de «id»: el botón de la puerta (en la vivienda, la primera vez se llama: Odila abre y hay que
# pulsar otra vez) y esperar al fundido.
func _entrar(id: String) -> bool:
	if v.interior == id:
		return true
	if v.interior != "":
		await _salir()
	var d: Dictionary = T.PUERTAS[id]
	await _ir(d["fuera"], "la puerta de " + id, 0.5)
	for intento in 2:
		if not await _accion(d["texto"]):
			return false
		await _segundos(0.3)
		if _aviso() == Barrio.LLAMAR and v.interior == "":
			_nota("llama a la puerta de %s: «%s»" % [id, _aviso()])
			await _segundos(0.6)
			continue
		break
	var f := 0
	while v.interior != id and f < 90:
		await _frames(3)
		f += 3
	await _segundos(1.0)
	_ok(v.interior == id and Interiores.interior_de(_kael()) == id, "no se entra en %s (dentro de «%s», aviso «%s»)" % [
		id, v.interior, _aviso()])
	if v.interior == id:
		_nota("dentro de %s" % id)
	return v.interior == id


# Salir de verdad: andar hasta el botón «Salir» de dentro y pulsarlo. Kael aparece en la puerta de fuera.
func _salir() -> void:
	var id: String = v.interior
	if id == "":
		return
	await _ir(v.interiores.salida(id), "la salida de " + id, 0.4)
	await _accion("Salir")
	var f := 0
	while v.interior != "" and f < 90:
		await _frames(3)
		f += 3
	await _segundos(0.9)
	_ok(v.interior == "" and _plana(_kael(), T.PUERTAS[id]["fuera"]) < 0.3, "al salir de %s no aparece en su puerta (%s, «%s»)" % [
		id, _kael(), v.interior])
	_nota("fuera de %s" % id)


# Ir a la zona «lugar» ("" = fuera).
func _a_la_zona(lugar: String) -> void:
	if v.interior == lugar:
		return
	if lugar == "":
		await _salir()
	else:
		await _entrar(lugar)


# ---------------------------------------------------------------- vecinos y piezas

# Ir a hablar con un vecino: se mira dónde está (dentro o fuera) y se va hacia él hasta que el botón lo ofrece.
func _hablar_con(id: String, foto: String) -> String:
	var boton: String = Barrio.NPCS[id]["boton"]
	var f := 0
	while f < int(180 * FPS):
		var e: Dictionary = v.vivo.estado_de(id)
		if e["lugar"] != v.interior:                     # (dentro de su casa: se entra; fuera y Kael dentro: se sale)
			var f0 := Engine.get_process_frames()
			await _a_la_zona(e["lugar"])
			f += maxi(30, Engine.get_process_frames() - f0)
			continue
		if v.boton_accion.visible and v.boton_accion.text == boton:
			await _tecla(KEY_ENTER)
			var r := await _dialogo(foto)
			await _apartarse(v.vivo.estado_de(id)["pos"])
			return r
		var p: Vector3 = e["pos"]
		var junto := _junto_a(p)
		if _plana(_kael(), junto) > 4.0 and v.interior == "":
			var pts: Array = v.vivo._ruta(_kael(), junto, "", "recorrido")
			var siguiente: Vector3 = junto
			for q in pts.slice(1):                       # (el primer punto del camino que no sea donde ya está)
				if _plana(_kael(), q) > 1.0:
					siguiente = q
					break
			var f0 := Engine.get_process_frames()
			await _andar_a(siguiente, 1.0)
			f += maxi(30, Engine.get_process_frames() - f0)
		elif v.interior != "":
			var f0 := Engine.get_process_frames()
			await _ir(junto, id, 0.4)
			await _frames(6)
			f += maxi(30, Engine.get_process_frames() - f0)
		else:
			await _andar_a(junto, 0.5)
			await _frames(6)
			f += 20
	_ok(false, "no se llega a hablar con %s" % id)
	return ""


# Junto a Avena (a 1,4 m de su ancla), lo más lejos posible de Brena.
func _junto_a_avena() -> Vector3:
	var c := T.ancla("establo_caballo")
	var brena: Vector3 = v.vivo.vecinos["brena"]["pos"]
	var mejor := c + Vector3(1.4, 0, 0)
	var nota := -INF
	for i in 16:
		var a := TAU * i / 16.0
		var q := c + Vector3(sin(a), 0, cos(a)) * 1.4
		if not T.andable(q.x, q.z) or v.vivo.ocupa(q) or not v.vivo.recta_libre(_kael(), q):
			continue                                     # (se llega en línea recta: sin rodear a Avena)
		if _plana(q, brena) > nota:
			nota = _plana(q, brena)
			mejor = q
	return mejor


# Tras hablar, un paso atrás (lejos del vecino) para no quedarse pegado a él.
func _apartarse(p: Vector3) -> void:
	var d := Vector3(_kael().x - p.x, 0, _kael().z - p.z)
	if d.length() < 0.05:
		d = Vector3(0, 0, 1)
	for giro in [0.0, 0.8, -0.8, 1.6, -1.6]:
		var q := p + d.normalized().rotated(Vector3.UP, giro) * (1.8 if v.interior == "" else 1.5)
		if _andable(q) and (v.interior != "" or v.vivo.recta_libre(_kael(), q)):
			await _andar_a(_suelo(q), 0.5, false)
			return


# Los botones que hay en la zona de Kael (puertas o «Salir», piezas): para no ponerse a hablar encima de otro.
func _otros_botones() -> Array:
	var otros: Array = []
	if v.interior == "":
		for id in T.PUERTAS:
			otros.append(T.PUERTAS[id]["fuera"])
	else:
		otros.append(v.interiores.salida(v.interior))
	for pid in Barrio.PIEZAS:
		var a := str(Barrio.PIEZAS[pid]["ancla"])
		if (v.interior == "" and not a.begins_with("int_")) or (v.interior != "" and a.begins_with("int_%s_" % v.interior)):
			otros.append(v.ancla(a))
	return otros


# Un sitio andable cerca de un vecino (a 1,2 m fuera, a 0,9-1,2 m dentro), lo más lejos posible de los otros botones
# y cerca de Kael.
func _junto_a(p: Vector3) -> Vector3:
	var otros := _otros_botones()
	var mejor := p + Vector3(0, 0, 1.2)
	var nota := -INF
	for radio in ([1.2] if v.interior == "" else [1.0, 1.3, 0.8]):
		for i in 16:
			var a := TAU * i / 16.0
			var q := _suelo(p + Vector3(sin(a), 0, cos(a)) * radio)
			if not _andable(q):
				continue
			var lejos := INF
			for o in otros:
				lejos = minf(lejos, _plana(q, o))
			var n := minf(lejos, 2.5) * 2.0 - _plana(q, _kael()) * 0.1
			if n > nota:
				nota = n
				mejor = q
	return mejor


# Usar una pieza (examinar, pedir, tocar, coger): ir a su ancla en su zona y pulsar su botón. Devuelve el aviso.
func _pieza(pid: String, foto := "") -> String:
	var a := str(Barrio.PIEZAS[pid]["ancla"])
	var lugar := ""
	if a.begins_with("int_"):
		lugar = a.get_slice("_", 1)
	await _a_la_zona(lugar)
	await _ir(v.ancla(a), "la pieza " + pid, 0.35)
	await _segundos(0.3)
	var antes := _aviso()
	v.ultimo_aviso = ""
	if not await _accion(Barrio.PIEZAS[pid]["boton"]):
		v.ultimo_aviso = antes
		return ""
	await _segundos(0.9)
	if foto != "":
		await _foto(foto)
	_nota("%s: «%s»" % [pid, _aviso()])
	return _aviso()


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


# «Guardar y recargar» (el botón de la región). Fuera, Kael vuelve a aparecer donde estaba; DENTRO de un interior, en
# la puerta de fuera (guardar_posicion guarda siempre la puerta: lo diseñado). La misión sigue igual.
func _guardar_y_recargar(donde: String) -> void:
	var antes: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}).duplicate()
	var dentro: String = v.interior
	var k: Vector3 = _kael() if dentro == "" else T.PUERTAS[dentro]["fuera"]
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
	_ok(_plana(_kael(), k) < 1.0 and v.interior == "", "%s: Kael no vuelve a aparecer %s (%s → %s, dentro de «%s»)" % [
		donde, "en la puerta de fuera de " + dentro if dentro != "" else "donde estaba", k, _kael(), v.interior])
	_nota("%s: guardado y recargado%s; Kael en %s" % [donde, " DENTRO de " + dentro if dentro != "" else "", _kael()])


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
	await _a_la_zona("")
	await _ir(JUNTO_CARRO, "el carro del horno", 0.4)
	await _segundos(0.4)
	v.ultimo_aviso = ""
	if await _accion(texto):
		await _segundos(0.8)
		await _foto(foto)
	return _aviso()


# ---------------------------------------------------------------- el recorrido

func _preparar() -> void:
	BP.preparar_partida()                          # la partida del banco: prólogo visto, pv_02, sin el barrio
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", "bajo")
	if Engine.has_meta("barrio_reloj"):
		Engine.remove_meta("barrio_reloj")


func _jugar() -> void:
	await _frames(3)
	_nota("ventana %s, viewport %s, transformación ventana←viewport %s" % [root.size, root.get_visible_rect().size,
		root.get_final_transform()])
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
	# 2. el horno por dentro y Maela (dentro o fuera, donde esté)
	if await _entrar("horno"):
		await _foto("A02_horno_dentro")
		a = await _pieza("boca_horno", "A02b_boca_del_horno")
		_ok(a == Barrio.PIEZAS["boca_horno"]["texto"], "A2: la boca del horno no se examina («%s»)" % a)
	var r := await _hablar_con("maela", "A03_maela")
	_ok(r.ends_with("bar_maela_pendiente.dtl"), "A2: Maela no dice lo del pasador (%s)" % r.get_file())
	await _a_la_zona("")
	await _diario("A04_diario_inicio")
	# 3. el taller: la trastienda cerrada, lo de Damián, el clavo vacío y Damián dentro
	await _ir(T.ancla("n_plaza"), "la plaza")
	await _foto("t3_plaza")
	await _ir(T.ancla("n_patio_s"), "el patio de talleres")
	await _foto("t4_talleres")
	if await _entrar("taller"):
		await _foto("A05_taller_dentro")
		await _trastienda_cerrada()
		a = await _pieza("clavo_galga", "A06_clavo_vacio")
		_ok(Barrio.estado("j_visto_clavo"), "A3: el clavo vacío no se apunta («%s»)" % a)
		a = await _pieza("cantaro_taller")
		_ok(a == Barrio.PIEZAS["cantaro_taller"]["texto"], "A3: pedir agua a Damián: «%s»" % a)
	r = await _hablar_con("damian", "A07_damian_encargo")
	_ok(r.ends_with("bar_damian_encargo.dtl") and Barrio.estado("enf_taller") and v.interior == "taller",
		"A3: Damián no da el encargo dentro del taller (%s, «%s»)" % [r.get_file(), v.interior])
	await _trastienda_abierta()
	# 4. la galga, en casa de Odila (dentro)
	await _a_la_zona("")
	await _ir(T.ancla("n_res_e"), "la calle de las casas")
	await _foto("t5_residencial")
	if await _entrar("vivienda"):
		_ok(Barrio.estado("viv_llamado"), "A4: no se ha llamado a la puerta de la vivienda")
		await _foto("A08_vivienda_dentro")
	r = await _hablar_con("odila", "A09_odila_galga")
	_ok(r.ends_with("bar_odila_galga.dtl") and v.interior == "vivienda", "A4: Odila no habla de la galga dentro (%s)" % r.get_file())
	r = await _hablar_con("nela", "A10_nela")
	_ok(r.ends_with("bar_nela.dtl") and v.interior == "vivienda", "A4: Nela no habla dentro (%s)" % r.get_file())
	a = await _pieza("rueda_nela", "A11_rueda_de_nela")
	_ok(a == Barrio.PIEZAS["rueda_nela"]["texto"], "A4: la rueda de juguete no se examina («%s»)" % a)
	var mz: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}).duplicate()
	a = await _pieza("arcon")
	_ok(a == Barrio.PIEZAS["arcon"]["texto"] and Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}) == mz,
		"A4: el arcón de Odila: no reacciona o cambia algo («%s»)" % a)
	var repisa: Node3D = v.interiores.sitio("galga")
	_ok(repisa != null and repisa.visible, "A4: la galga no está en la repisa")
	a = await _pieza("galga", "A12_galga_cogida")
	await _segundos(0.4)
	_ok(Barrio.estado("enf_galga") and repisa != null and not repisa.visible, "A4: no se coge la galga o la repisa la sigue enseñando («%s»)" % a)
	# «Guardar y recargar» DENTRO: reaparece en la puerta de fuera y la misión sigue en su paso
	await _guardar_y_recargar("A dentro de la vivienda")
	_ok(Barrio.estado("enf_galga") and E.paso_actual(mis).get("id", "") == "medir", "A: tras recargar dentro, la misión no sigue en «medir» (%s)" % E.paso_actual(mis).get("id", ""))
	await _foto("A13_tras_recargar_en_la_puerta")
	# 5. medir el eje
	a = await _al_carro("Examinar el carro", "A14_medir")
	_ok(Barrio.estado("enf_medida") and a.begins_with(Barrio.CARRO["medir"]), "A5: no se mide el eje («%s»)" % a)
	# 6. el pasador (Damián, dentro del taller); la galga vuelve a su clavo
	r = await _hablar_con("damian", "A15_damian_pasador")
	_ok(r.ends_with("bar_damian_pasador.dtl") and Barrio.estado("enf_pasador"), "A6: Damián no corta el pasador (%s)" % r.get_file())
	await _segundos(0.5)
	_ok(v.vivo.galga_clavo != null and v.vivo.galga_clavo.visible, "A6: la galga no vuelve a su clavo")
	a = await _pieza("clavo_galga", "A16_galga_en_su_clavo")
	_ok(a == Barrio.PIEZAS["clavo_galga"]["texto_sin"], "A6: el clavo no dice que la galga ha vuelto («%s»)" % a)
	# 7. reparar
	a = await _al_carro("Examinar el carro", "A17_reparado")
	_ok(Barrio.estado("enf_reparado"), "A7: el carro no se arregla («%s»)" % a)
	await _segundos(3.0)
	await _foto("A18_reparto")
	# 8. la cesta
	r = await _hablar_con("maela", "A19_maela_cesta")
	_ok(r.ends_with("bar_maela_cesta.dtl") and Barrio.estado("enf_cesta"), "A8: Maela no da la cesta (%s)" % r.get_file())
	# 9. la entrega (dentro de la vivienda)
	r = await _hablar_con("odila", "A20_odila_entrega")
	_ok(r.ends_with("bar_odila_entrega.dtl") and Barrio.estado("enf_entrega") and v.interior == "vivienda",
		"A9: Odila no recibe la cesta dentro (%s)" % r.get_file())
	# 10. vuelta a Maela: el premio, una vez
	var eter0: int = Inv.cantidad("Éter")
	r = await _hablar_con("maela", "A21_maela_fin")
	_ok(r.ends_with("bar_maela_fin.dtl") and Inv.cantidad("Éter") == eter0 + 2, "A10: el premio no es Éter ×2 (%d → %d)" % [eter0, Inv.cantidad("Éter")])
	await _segundos(2.0)
	await _foto("A22_premio")
	r = await _hablar_con("maela", "")
	_ok(r.ends_with("bar_maela_despues.dtl") and Inv.cantidad("Éter") == eter0 + 2, "A10: el premio se repite (%s)" % r.get_file())
	_ok(E.estado(mis) == "hecho", "A: la misión no acaba")
	await _a_la_zona("")
	await _diario("A23_diario_final")
	# el bucle se cierra por el atajo
	await _ir(T.ancla("n_res_o"), "el final de la calle")
	await _ir(T.ancla("n_atajo_n"), "el atajo")
	await _ir(Vector3(-42.0, 0.7, -16.0), "el arco del atajo")
	await _foto("t6_atajo")
	await _ir(T.ancla("n_establo"), "el establo")
	await _foto("A24_establo_avena")
	await _andar_a(_junto_a_avena(), 0.3)                  # (del lado contrario a Brena, para que el botón sea el de Avena)
	await _segundos(0.4)
	await _accion("Examinar a Avena")
	await _segundos(1.0)
	_ok(Barrio.estado("j_sabe_no_culpa_caballo"), "A: examinar a Avena no apunta nada")


# La trastienda cerrada: no se pisa, sale el aviso de B al acercarse y, si se intenta abrir, Damián contesta (no cambia
# nada).
func _trastienda_cerrada() -> void:
	var I = v.interiores
	var corte: Vector3 = v.ancla("int_taller_banco_corte")
	_ok(not I.paso_abierto("trastienda") and not I.andable(corte), "A3: la trastienda está abierta antes de hablar con Damián")
	v.ultimo_aviso = ""
	await _ir(v.ancla("int_taller_paso_trastienda") + Vector3(0.5, 0, 0), "la puerta de la trastienda", 0.3)
	await _segundos(0.6)
	_ok(_aviso() == I.AVISO_TRASTIENDA, "A3: junto a la trastienda cerrada no sale su aviso («%s»)" % _aviso())
	var aviso := _aviso()
	var pp: Vector2 = v.cam.unproject_position(corte)          # (un clic dentro: Kael se para en la puerta)
	if _se_puede_tocar(pp):
		await _clic(pp)
	await _segundos(1.5)
	var local: Vector3 = _kael() - I.ORIGEN["taller"]
	_ok(local.x > 4.3, "A3: Kael entra en la trastienda cerrada (x local %.2f)" % local.x)
	_nota("trastienda cerrada: Kael se para en x local %.2f; aviso «%s»" % [local.x, aviso])
	await _foto("A05b_trastienda_cerrada")
	var mz: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}).duplicate()
	var a := await _pieza("trastienda")
	_ok(a == Barrio.PIEZAS["trastienda"]["texto"] and Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}) == mz,
		"A3: abrir la trastienda cerrada: Damián no contesta o cambia algo («%s»)" % a)


# La trastienda abierta tras hablar con Damián: se entra, se ven los pasadores y no se cogen (Damián contesta).
func _trastienda_abierta() -> void:
	var I = v.interiores
	await _segundos(1.0)
	_ok(I.paso_abierto("trastienda"), "A3: tras el encargo, la trastienda sigue cerrada")
	var mz: Dictionary = Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}).duplicate()
	var a := await _pieza("banco_corte", "A07b_trastienda_abierta")
	var local: Vector3 = _kael() - I.ORIGEN["taller"]
	_ok(local.x < 4.4, "A3: Kael no entra en la trastienda abierta (x local %.2f)" % local.x)
	_ok(a == Barrio.PIEZAS["banco_corte"]["texto"] and Engine.get_meta("mazmorras", {}).get(Barrio.NOMBRE, {}) == mz,
		"A3: los pasadores en bruto se tocan sin que Damián diga nada, o cambia algo («%s»)" % a)


func _mision_galga_primero() -> void:
	_nota("B. LA GALGA PRIMERO")
	_preparar()
	change_scene_to_file(ESCENA)
	await _cargar_region()
	var mis: Dictionary = E.de(ESTADO_MISION)
	await _ir(T.ancla("n_com_o"), "la calle comercial")
	await _ir(T.ancla("n_plaza"), "la plaza")
	await _ir(T.ancla("n_patio_n"), "el patio de talleres")
	await _ir(T.ancla("n_res_e"), "la calle de las casas")
	await _entrar("vivienda")
	# sin preguntar, la galga no se coge: Odila llama la atención
	var a := await _pieza("galga", "B01_galga_sin_preguntar")
	_ok(not Barrio.estado("enf_galga") and a == Barrio.PIEZAS["galga"]["texto_ajeno"],
		"B1: la galga se coge sin preguntar («%s»)" % a)
	var r := await _hablar_con("odila", "B02_odila_galga")
	_ok(r.ends_with("bar_odila_galga.dtl"), "B1: Odila no dice dónde está la galga (%s)" % r.get_file())
	a = await _pieza("galga", "B03_galga_cogida")
	_ok(Barrio.estado("enf_galga") and E.estado(mis) == "oculto", "B1: la galga suelta empieza la misión o no se consigue (%s, «%s»)" % [E.estado(mis), a])
	a = await _al_carro("Examinar el carro", "B04_medir_empieza")
	_ok(a.contains("Misión") and Barrio.estado("enf_medida") and E.estado(mis) == "activo", "B2: medir con la galga no empieza la misión («%s»)" % a)
	await _guardar_y_recargar("B tras medir")
	r = await _hablar_con("damian", "B05_damian_pasador")
	_ok(r.ends_with("bar_damian_pasador.dtl") and Barrio.estado("enf_pasador"), "B3: Damián no corta el pasador (%s)" % r.get_file())
	a = await _al_carro("Examinar el carro", "B06_reparado")
	_ok(Barrio.estado("enf_reparado"), "B4: no se arregla el carro")
	r = await _hablar_con("maela", "B07_maela_cesta")
	_ok(Barrio.estado("enf_cesta"), "B5: Maela no da la cesta (%s)" % r.get_file())
	r = await _hablar_con("odila", "B08_odila_entrega")
	_ok(Barrio.estado("enf_entrega"), "B6: Odila no recibe la cesta (%s)" % r.get_file())
	var eter0: int = Inv.cantidad("Éter")
	r = await _hablar_con("maela", "B09_maela_fin")
	_ok(E.estado(mis) == "hecho" and Inv.cantidad("Éter") == eter0 + 2, "B: la galga primero no acaba con Éter ×2")
	r = await _hablar_con("maela", "")
	_ok(r.ends_with("bar_maela_despues.dtl") and Inv.cantidad("Éter") == eter0 + 2, "B: el premio se repite (%s)" % r.get_file())
	await _a_la_zona("")
	await _diario("B10_diario_final")


# Una visita a cada rutina (para el vídeo): Kael se pone cerca y la sigue un rato.
func _rutinas() -> void:
	await _foto("R00_entrada")
	for paso in [["brena", "cepillar", 22.0], ["brena", "verter", 16.0], ["tobias", "coger", 26.0], ["maela", "dejar", 18.0],
			["maela", "coger", 20.0]]:
		var id: String = paso[0]
		var w: Dictionary = v.vivo.vecinos[id]
		var objetivo := -INF
		for s in w["segs"]:
			if s["lugar"] == "" and s["clip"] == paso[1]:
				objetivo = fposmod(float(s["t0"]) - 4.0, float(w["ciclo"]))
				break
		if objetivo == -INF:
			_nota("rutina %s: sin «%s» fuera" % [id, paso[1]])
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
