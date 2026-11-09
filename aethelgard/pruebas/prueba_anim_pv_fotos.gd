extends SceneTree
# Diálogos 3D de Pastos Verdes (T-084): capturas de cada frase de PV-02 (Kael solo), PV-03 (llega Lya) y PV-05
# (Garon y Tilo), y de lo que pasa justo después (Lya llega corriendo; Garon aparece y se une), para revisar a ojo
# poses, miradas, pies, armas y transiciones. Con ventana y datos aislados, como «Probar la misión desde el principio»
# (misión desde cero y Kael solo):
#   Godot --path aethelgard --script res://pruebas/prueba_anim_pv_fotos.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo [etiqueta=antes]
# En cada frase imprime qué hace cada personaje 3D («ESTADO»): su animación, hacia dónde mira respecto a quien habla
# (grados; 0 = le mira) y si se ha movido durante la frase. FALLO si un diálogo no sale o no termina, o si alguien con
# cuerpo en la región (Kael, Lya, Garon o Tilo) habla sin estar en la escena 3D (T-084, tanda 2: Lya llega antes de
# PV-03 y Garon espera junto a Tilo antes de PV-05). Con «sin_fotos» no guarda capturas (se puede pasar sin ventana).

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"

const CON_CUERPO := ["Kael", "Lya", "Garon", "Tilo"]

var salida := ""
var etiqueta := "antes"
var fotos := true
var D
var P
var fallos: Array = []


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
	fotos = not "sin_fotos" in OS.get_cmdline_user_args()
	if fotos:
		DisplayServer.window_set_size(Vector2i(1280, 720))
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _esperar(int(round(s * 30.0)))


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


func _pulsar(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _esperar(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _esperar(2)


func _texto() -> String:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.get_parsed_text()
	return ""


func _revelado() -> bool:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.visible_characters < 0 or n.visible_ratio >= 0.999
	return false


func _foto(nombre: String) -> void:
	if not fotos:
		await process_frame
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_%s.png" % [salida, etiqueta, nombre])


func _probar() -> void:
	D = root.get_node("Dialogic")
	P = load("res://progreso.gd")
	root.get_node("Recursos").precalentar_dialogos()
	Engine.set_meta("hitos", {})
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("lore_visto", {})
	Engine.set_meta("pos_3d_ok", false)
	if Engine.has_meta("grupo_activo"):
		Engine.remove_meta("grupo_activo")         # la misión empieza con Kael solo (como la ranura de prueba)
	await _esperar(3)
	change_scene_to_file(REGION)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION, 60.0):
		_fallo("no se llega a Pastos Verdes")
		return _fin()
	var r = current_scene
	await _foto("00_entrada")
	# PV-02: sale solo al entrar
	await _dialogo(r, "pv_02")
	await _segundos(1.0)
	await _foto("pv02_despues")
	await _primer_plano(r, "pv02_cerca")
	# Garon ya espera junto a Tilo desde que se entra (T-084, tanda 2), sin ir con el grupo
	var esperan: Array = r.grupo.esperando.keys() if r.grupo != null else []
	print("ESPERAN al entrar: ", esperan, " · grupo: ", (r.grupo.nodos().map(func(x): return String(x.name)) if r.grupo != null else []))
	if not "Garon" in esperan:
		_fallo("Garon no espera junto a Tilo al entrar")
	# PV-03: en el camino. Lya llega corriendo por detrás ANTES de hablar (T-084, tanda 2)
	var q: Vector3 = r.SENDERO[2]
	r._colocar_kael(Vector3(q.x, r.altura(q.x, q.z), q.z))
	if not await _hasta(func(): return r._escena_pendiente == "pv_03" or D.current_timeline != null, 10.0):
		_fallo("PV-03 no empieza en el camino")
	await _llegada(r, "pv03_llegada", 1.4)
	await _dialogo(r, "pv_03")
	await _segundos(1.0)
	await _foto("pv03_despues")
	await _primer_plano(r, "pv03_cerca")
	# PV-05: junto a Tilo (Garon ya está a su lado); después, Garon se pone en la fila
	var t: Vector3 = r.tilo.global_position + Vector3(1.0, 0, 0.6)
	r._colocar_kael(Vector3(t.x, r.altura(t.x, t.z), t.z))
	await _segundos(2.5)                           # Lya llega a su sitio detrás de Kael
	await _foto("pv05_antes")
	await _primer_plano(r, "pv05_antes_cerca")
	if not await _hasta(func(): return r.boton_accion.visible and r.boton_accion.text == "Hablar con Tilo", 10.0):
		_fallo("junto a Tilo no aparece «Hablar con Tilo»")
		return _fin()
	r._accion()
	await _dialogo(r, "pv_05")
	await _llegada(r, "pv05_union", 3.0)
	if r.grupo == null or r.grupo.nodos().map(func(x): return String(x.name)) != ["Lya", "Garon"] or not r.grupo.esperando.is_empty():
		_fallo("tras PV-05, el grupo no es Lya y Garon (o alguien sigue esperando)")
	await _primer_plano(r, "pv05_cerca")
	_fin()


# Primer plano de diagnóstico (más cerca de lo que deja el zoom del juego, 9 m): manos, cuello, pies y armas en reposo.
# Luego, la cámara vuelve a su distancia.
func _primer_plano(r, nombre: String) -> void:
	var d0: float = r.distancia
	r.distancia = 5.5
	await _segundos(1.5)
	await _foto(nombre)
	r.distancia = d0
	await _segundos(1.0)


# Recorre un diálogo como una persona: cada frase, entera y medio segundo a la vista, se fotografía y se pasa.
func _dialogo(r, id: String) -> void:
	if not await _hasta(func(): return D.current_timeline != null and r.dialogo_actual == id, 20.0):
		_fallo("no sale el diálogo %s" % id)
		return
	var n := 0
	var pos0 := _posiciones(r)
	while D.current_timeline != null and n < 30:
		if not await _hasta(func(): return D.current_timeline == null or (D.current_state == D.States.IDLE and _texto() != "" and _revelado()), 20.0):
			break
		if D.current_timeline == null:
			break
		n += 1
		await _segundos(0.5)
		var sp = D.Text.get_current_speaker()
		var quien: String = sp.display_name if sp != null else "?"
		await _foto("%s_frase_%02d" % [id.replace("_", ""), n])
		_estado(r, id, n, quien, pos0)
		await _pulsar(KEY_ENTER)
		await _esperar(4)
	if not await _hasta(func(): return D.current_timeline == null, 10.0):
		_fallo("el diálogo %s no termina" % id)
	print("DIÁLOGO %s: %d frases" % [id, n])


# Lo que pasa justo después de un diálogo (alguien llega o se une): una foto cada 0,2 s.
func _llegada(r, nombre: String, segundos: float) -> void:
	var k := 0
	for i in int(segundos / 0.2):
		await _segundos(0.2)
		k += 1
		await _foto("%s_%02d" % [nombre, k])
	for m in (r.grupo.miembros + r.grupo.esperando.values() if r.grupo != null else []):
		var nodo = m["nodo"]
		print("LLEGADA %s · %s%s: estado «%s», animación %s, a %.1f m de Kael" % [nombre, m["nombre"],
			" (espera)" if r.grupo.esperando.has(m["nombre"]) else "", m["estado"],
			nodo.anim.current_animation, _plana(nodo.global_position, r.kael.global_position)])


func _actores(r) -> Dictionary:
	var a := {"Kael": r.kael, "Tilo": r.tilo}
	if r.grupo != null:
		for m in r.grupo.miembros + r.grupo.esperando.values():
			a[m["nombre"]] = m["nodo"]
	return a


func _posiciones(r) -> Dictionary:
	var p := {}
	var a := _actores(r)
	for k in a:
		p[k] = a[k].global_position
	return p


func _adelante(n: Node3D) -> Vector3:
	if n.has_method("_adelante_mundo"):
		return n._adelante_mundo()
	var v: Vector3 = n.global_transform.basis.z
	v.y = 0.0
	return v.normalized()


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Qué hace cada personaje 3D en esta frase.
func _estado(r, id: String, n: int, quien: String, pos0: Dictionary) -> void:
	var a := _actores(r)
	var habla: Node3D = a.get(quien)
	var partes: Array = []
	for k in a:
		var nodo: Node3D = a[k]
		var anim := ""
		if nodo.get("anim") != null:
			anim = String(nodo.anim.current_animation)
		var mira := "-"
		if habla != null and habla != nodo:
			var hacia := habla.global_position - nodo.global_position
			hacia.y = 0.0
			if hacia.length() > 0.05:
				mira = "%d°" % int(round(rad_to_deg(_adelante(nodo).angle_to(hacia.normalized()))))
		var movido := _plana(nodo.global_position, pos0.get(k, nodo.global_position))
		partes.append("%s[%s, mira a quien habla %s, movido %.2f m]" % [k, anim, mira, movido])
	print("ESTADO %s frase %02d (habla %s%s): %s" % [id, n, quien, "" if habla != null else ", que no está en la escena", " · ".join(partes)])
	if habla == null and quien in CON_CUERPO:
		_fallo("%s frase %d: habla %s y no está en la escena 3D" % [id, n, quien])


func _fin() -> void:
	print("CAPTURAS hechas en ", salida)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
