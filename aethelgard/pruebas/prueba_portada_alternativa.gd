extends SceneTree
# Prueba de la pantalla de inicio ALTERNATIVA (portada/, encargo del 11/11) y de que la original no cambia sin ella.
# Teclas y toques simulados (Input.parse_input_event; no es hardware real). Dos pasadas en lista_pruebas.txt:
#   «3d sin_prologo» (versión experimental): se elige en Ajustes ([portada] de user://ajustes.cfg, carpeta aislada)
#     0. eleccion.gd: argumentos, Ajustes y versión; elegir() no borra lo demás del archivo.
#     1. Sin elegirla, carga.tscn es la de siempre: se queda en su escena, termina y enseña sus botones de prueba (↓).
#     2. Elegida: carga.tscn lleva a la alternativa, que hace la misma carga, con el mismo logo en el mismo sitio, y al
#        terminar quita la línea y pide «toca/pulsa para empezar».
#     3. Intro abre el menú: Continuar (hay partida), Nueva partida, Opciones y Créditos; ↑ ↓ con vuelta; ← → a los
#        accesos de pruebas (que se ven, sin taparse con el menú) y ↑ vuelve.
#     4. Opciones (teclado): los Ajustes de siempre, solo su pestaña, con la opción «Pantalla de inicio»; Esc vuelve.
#     5. Créditos (toque simulado): se abre y Esc vuelve.
#     6. Continuar: la partida guardada, en su escena, con sus hitos.
#     7. Nueva partida con partida: pregunta (el foco en «Volver», que no cambia nada) y, al confirmar, copia de
#        seguridad idéntica y partida nueva (Kael solo, sin hitos) en el mapa.
#   «portada_alternativa sin_prologo» (versión de siempre): el argumento la elige; sin los accesos de pruebas, sin
#     Continuar (no hay partida) y Nueva partida lleva al mapa con una partida nueva.

const CARGA := "res://carga.tscn"
const MAPA := "res://mapa.tscn"

var E
var P
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _tecla(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _esperar(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _esperar(4)


# Un toque en un punto del lienzo (1280×720). El evento llega en coordenadas de la ventana, así que se pasa por la
# transformación del estiramiento (sin ventana, la ventana no mide lo mismo que el lienzo).
func _tocar(pos: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.position = root.get_final_transform() * pos
	print("Toque en %s del lienzo → %s de la ventana (ventana %s)" % [pos, t.position, DisplayServer.window_get_size()])
	t.pressed = true
	Input.parse_input_event(t)
	await _esperar(2)
	t = t.duplicate()
	t.pressed = false
	Input.parse_input_event(t)
	await _esperar(4)


func _foco() -> String:
	var f := root.get_viewport().gui_get_focus_owner()
	return root.get_node("Entrada").clave(f) if f != null else ""


var antes := {}                                  # archivos de la carpeta aislada que esta prueba cambia (para dejarlos)


func _probar() -> void:
	E = load("res://portada/eleccion.gd")
	P = load("res://progreso.gd")
	for a in [P.GUARDADO_EXP, P.GUARDADO_EXP + ".bak", E.AJUSTES]:
		antes[a] = FileAccess.get_file_as_string(a) if FileAccess.file_exists(a) else null
	var experimental: bool = load("res://modo3d.gd").activo()
	if experimental:
		await _pasada_experimental()
	else:
		await _pasada_estable()
	_dejar_como_estaba()
	_terminar()


# La carpeta aislada es la misma para toda la pasada: se deja como estaba (sin la portada elegida, que llevaría a las
# demás pruebas a la alternativa, ni la partida y las copias de esta prueba).
func _dejar_como_estaba() -> void:
	for a in antes:
		if antes[a] == null:
			if FileAccess.file_exists(a):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(a))
		else:
			var f := FileAccess.open(a, FileAccess.WRITE)
			f.store_string(antes[a])
			f.close()
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("partida_exp.save.antes_de_nueva_") or f.begins_with("partida.save.antes_de_nueva_"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + f))
	var cfg_fin := ConfigFile.new()
	if cfg_fin.load(E.AJUSTES) == OK and cfg_fin.has_section_key(E.SECCION, E.CLAVE) and antes.get(E.AJUSTES) == null:
		_fallo("no se pudo dejar la portada sin elegir")


# ---------------------------------------------------------------- versión experimental

func _pasada_experimental() -> void:
	# 0. La elección
	# desde el 11/11 por la noche la nueva es la de por defecto (lo eligió el usuario); la original, con
	# «portada_original» o eligiéndola en Ajustes
	var casos := [[[], true, true], [[], false, false], [["portada_original"], true, false],
		[["portada_alternativa"], false, true]]
	for c in casos:
		if E.usar_con(PackedStringArray(c[0]), c[1]) != c[2]:
			_fallo("0: usar_con(%s, ajustes=%s) debería ser %s" % c)
	if not E.elegida() or not E.usar_alternativa():
		_fallo("0: sin tocar nada, la nueva no es la de por defecto")
	var cfg := ConfigFile.new()
	cfg.load(E.AJUSTES)                            # (puede no existir: la carpeta aislada es de toda la pasada)
	cfg.set_value("prueba_portada", "marca", 55)
	cfg.save(E.AJUSTES)
	hechos.append("elección")

	# 1. Con «Original» elegida en Ajustes, la de siempre (y queda intacta)
	if E.elegir(false) != OK or E.elegida():
		_fallo("1: no se pudo elegir la original")
	change_scene_to_file(CARGA)
	await _esperar(5)
	if _escena() != CARGA or current_scene.get_script().resource_path != "res://carga.gd":
		_fallo("1: con la original elegida, carga.tscn no se queda en la pantalla de siempre (%s)" % _escena())
	elif not await _hasta(func(): return current_scene.listo and current_scene.boton_prueba != null \
			and current_scene.boton_prueba.visible, 240.0):
		_fallo("1: la pantalla de siempre no termina o no enseña sus botones de prueba")
	else:
		await _esperar(4)
		await _tecla(KEY_DOWN)
		if not current_scene.boton_prueba.has_focus():
			_fallo("1: en la de siempre, ↓ ya no elige «Probar la misión desde el principio»")
		if current_scene.toca.text == "":
			_fallo("1: en la de siempre falta «empezar»")
		hechos.append("la original sin cambios")

	# Una partida experimental «de verdad» en la carpeta aislada
	var siempre := {"grupo": load("res://grupo.gd").datos().duplicate(true), "hitos": {"pv_02": true, "pv_03": true},
		"grupo_activo": ["Kael", "Lya"], "escena_guardada": MAPA, "prologo_visto": true}
	P.escribir(siempre, P.GUARDADO_EXP)

	# 2. Elegida en Ajustes
	if E.elegir(true) != OK or not E.elegida():
		_fallo("2: no se pudo elegir la alternativa")
	cfg = ConfigFile.new()
	if cfg.load(E.AJUSTES) != OK or int(cfg.get_value("prueba_portada", "marca", -1)) != 55:
		_fallo("2: elegir la portada ha borrado otros ajustes")
	var c = await _abrir_alternativa()
	if c == null:
		return
	if not c.logo.texture.resource_path.ends_with("marca/logo_rebelum.webp") or c.logo.position != Vector2(370, 14) \
			or c.logo.size != Vector2(540, 381) or not (c.logo.material is CanvasItemMaterial):
		_fallo("2: el logo no es el de siempre o no está en el mismo sitio")
	if c.linea_alt.modulate.a > 0.05 or c.cifra.modulate.a > 0.05:
		_fallo("2: al terminar la carga, la línea o la cifra siguen a la vista")
	if c.boton_prueba == null or c.boton_prueba.visible:
		_fallo("2: los accesos de pruebas faltan o salen antes del menú")
	hechos.append("alternativa: carga, logo y «empezar»")

	# 3. El menú con el teclado
	await _tecla(KEY_ENTER)
	await _esperar(20)
	var nombres: Array = c.botones_menu.map(func(b): return b.text)
	if c.estado != "menu" or nombres != ["CONTINUAR", "NUEVA PARTIDA", "OPCIONES", "CRÉDITOS"]:
		_fallo("3: Intro no abre el menú esperado (%s, %s)" % [c.estado, nombres])
		return
	if _foco() != "portada:continuar":
		_fallo("3: el foco no empieza en Continuar (%s)" % _foco())
	await _tecla(KEY_DOWN)
	if _foco() != "portada:nueva":
		_fallo("3: ↓ no baja a Nueva partida (%s)" % _foco())
	await _tecla(KEY_UP)
	await _tecla(KEY_UP)
	if _foco() != "portada:creditos":
		_fallo("3: ↑ desde arriba no da la vuelta a Créditos (%s)" % _foco())
	await _tecla(KEY_LEFT)
	if not c.boton_prologo.has_focus():
		_fallo("3: ← no lleva a «Probar el prólogo»")
	await _tecla(KEY_RIGHT)
	if not c.boton_prueba.has_focus():
		_fallo("3: → no pasa a «Probar la misión»")
	await _tecla(KEY_UP)
	if _foco() != "portada:continuar":
		_fallo("3: ↑ desde los accesos de pruebas no vuelve al menú (%s)" % _foco())
	var caja_menu := Rect2()
	for b in c.botones_menu:
		caja_menu = b.get_global_rect() if caja_menu.size == Vector2.ZERO else caja_menu.merge(b.get_global_rect())
	for b in [c.boton_prologo, c.boton_prueba]:
		if not b.visible or b.get_global_rect().intersects(caja_menu):
			_fallo("3: un acceso de pruebas no se ve o tapa el menú")
	if c.boton_prologo.get_global_rect().intersects(c.boton_prueba.get_global_rect()):
		_fallo("3: los dos accesos de pruebas se tapan")
	if c.botones_menu[3].get_global_rect().end.y > 700:
		_fallo("3: el menú se sale por abajo")
	hechos.append("menú con teclado")

	# 4. Opciones con el teclado
	await _tecla(KEY_DOWN)
	await _tecla(KEY_DOWN)
	await _tecla(KEY_ENTER)
	await _esperar(10)
	if c.estado != "opciones" or c.ventana == null or c.ventana.pestanas != ["Ajustes"]:
		_fallo("4: Opciones no abre los Ajustes solos (%s)" % c.estado)
	else:
		var m = c.ventana
		if root.get_node("Entrada").buscar(m, "portada:alternativa") == null:
			_fallo("4: en los Ajustes falta «Pantalla de inicio»")
		await _tecla(KEY_ESCAPE)
		await _esperar(10)
		if is_instance_valid(m) and m.is_inside_tree():
			_fallo("4: Esc no cierra los Ajustes")
		if c.estado != "menu" or _foco() != "portada:opciones":
			_fallo("4: al cerrar los Ajustes no se vuelve a Opciones (%s, %s)" % [c.estado, _foco()])
		hechos.append("Opciones con teclado")

	# 5. Créditos con el dedo
	var cred: Button = c.botones_menu[3]
	await _tocar(cred.get_global_rect().get_center())
	await _esperar(10)
	if c.estado != "creditos" or c.ventana == null:
		_fallo("5: un toque en Créditos no los abre (%s)" % c.estado)
	else:
		await _tecla(KEY_ESCAPE)
		await _esperar(10)
		if c.estado != "menu":
			_fallo("5: Esc no cierra los Créditos")
		hechos.append("Créditos con toque")

	# 6. Continuar
	var huella := FileAccess.get_file_as_string(P.GUARDADO_EXP)
	var cont: Button = c.botones_menu[0]
	await _tocar(cont.get_global_rect().get_center())
	if not await _hasta(func(): return _escena() == MAPA and current_scene.get("jugador") != null, 90.0):
		_fallo("6: Continuar no lleva a la partida guardada (%s)" % _escena())
	elif not P.hito("pv_02") or load("res://grupo.gd").activos() != ["Kael", "Lya"]:
		_fallo("6: Continuar no carga la partida guardada")
	else:
		hechos.append("Continuar con toque")
	await _esperar(10)

	# 7. Nueva partida con una partida guardada
	c = await _abrir_alternativa()
	if c == null:
		return
	await _tecla(KEY_ENTER)
	await _esperar(20)
	await _tecla(KEY_DOWN)
	huella = FileAccess.get_file_as_string(P.GUARDADO_EXP)
	await _tecla(KEY_ENTER)
	await _esperar(10)
	if c.estado != "confirmar" or _foco() != "portada:volver":
		_fallo("7: Nueva partida con partida no pregunta, o el foco no está en «Volver» (%s, %s)" % [c.estado, _foco()])
		return
	await _tecla(KEY_ENTER)
	await _esperar(10)
	if c.estado != "menu" or FileAccess.get_file_as_string(P.GUARDADO_EXP) != huella or _copias().size() > 0:
		_fallo("7: «Volver» no deja todo como estaba")
	await _tecla(KEY_ENTER)
	await _esperar(10)
	await _tecla(KEY_RIGHT)
	if _foco() != "portada:nueva_si":
		_fallo("7: → no lleva a «Empezar de nuevo» (%s)" % _foco())
	await _tecla(KEY_ENTER)
	if not await _hasta(func(): return _escena() == MAPA, 90.0):
		_fallo("7: confirmar no lleva al mapa (%s)" % _escena())
		return
	var copias := _copias()
	if copias.size() != 1 or FileAccess.get_file_as_string("user://" + copias[0]) != huella:
		_fallo("7: la copia de seguridad falta o no es idéntica (%s)" % [copias])
	if P.hito("pv_02") or load("res://grupo.gd").activos() != ["Kael"]:
		_fallo("7: la partida nueva no es nueva (grupo %s)" % [load("res://grupo.gd").activos()])
	hechos.append("Nueva partida con confirmación y copia")


func _copias() -> Array:
	var r := []
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("partida_exp.save.antes_de_nueva_") and not f.ends_with(".bak") and not f.ends_with(".tmp"):
			r.append(f)
	return r


# carga.tscn → (elegida) la alternativa, hasta «toca para empezar».
func _abrir_alternativa():
	change_scene_to_file(CARGA)
	if not await _hasta(func(): return _escena() == E.ESCENA, 20.0):
		_fallo("carga.tscn no lleva a la alternativa elegida (%s)" % _escena())
		return null
	var c = current_scene
	if not await _hasta(func(): return is_instance_valid(c) and c.get("listo") == true and c.get("estado") == "toca", 240.0):
		_fallo("la alternativa no termina la carga o no llega a «empezar» (%s)" % c.estado)
		return null
	await _esperar(30)
	print("Alternativa lista en %.1f s (sin ventana)" % c.t_listo)
	return c


# ---------------------------------------------------------------- versión de siempre, con el argumento

func _pasada_estable() -> void:
	if not E.usar_alternativa():
		_fallo("A: «-- portada_alternativa» no la elige")
		return
	var c = await _abrir_alternativa()
	if c == null:
		return
	if c.boton_prueba != null or c.boton_prologo != null:
		_fallo("A: en la versión de siempre salen los accesos de pruebas")
	await _tocar(Vector2(640, 470))
	await _esperar(20)
	var nombres: Array = c.botones_menu.map(func(b): return b.text)
	if c.estado != "menu" or nombres != ["NUEVA PARTIDA", "OPCIONES", "CRÉDITOS"]:
		_fallo("A: un toque no abre el menú sin Continuar (%s, %s)" % [c.estado, nombres])
		return
	if c.saliendo or _escena() != E.ESCENA:
		_fallo("A: el toque que abre el menú ha pulsado también lo que sale debajo (Nueva partida)")
		return
	hechos.append("menú sin partida ni accesos de pruebas")
	await _tecla(KEY_ENTER)
	if not await _hasta(func(): return _escena() == MAPA, 90.0):
		_fallo("A: Nueva partida no lleva al mapa (%s)" % _escena())
		return
	if P.hay_partida():
		_fallo("A: Nueva partida ha escrito una partida al empezar")
	hechos.append("Nueva partida sin partida")


func _terminar() -> void:
	print("OK portada alternativa: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
