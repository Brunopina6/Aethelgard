extends SceneTree
# Capturas del foco con teclado (marco dorado de estilo.gd) para revisarlas a ojo, y una con el dedo (sin marco).
#   Godot --path aethelgard --script res://pruebas/prueba_foco_fotos.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo
# Teclas simuladas. Escribe en <carpeta>: 1_carga_boton_prueba, 2_mapa_barra, 3_menu_grupo, 4_menu_mas,
# 5_ciudad_tienda, 6_tienda_comprar y 7_menu_con_el_dedo (.png).

const CARGA := "res://carga.tscn"
const MAPA := "res://mapa.tscn"
const ZONA := "res://zona.tscn"

var salida := ""
var R
var Ent


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_capturar.call_deferred()


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


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
	await _esperar(6)


func _foto(nombre: String) -> void:
	await _esperar(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [salida, nombre])
	print("CAPTURA ", nombre, " · foco en «", Ent.clave(root.get_viewport().gui_get_focus_owner()), "»")


func _capturar() -> void:
	R = root.get_node("Recursos")
	Ent = root.get_node("Entrada")
	await _esperar(3)
	change_scene_to_file(CARGA)
	await _hasta(func(): return _escena() == CARGA and current_scene.listo, 180.0)
	await _pulsar(KEY_DOWN)
	await _foto("1_carga_boton_prueba")
	change_scene_to_file(MAPA)
	await _hasta(func(): return _escena() == MAPA and current_scene.jugador != null, 60.0)
	await _esperar(20)
	var m = current_scene
	await _pulsar(KEY_TAB)
	await _foto("2_mapa_barra")
	await _pulsar(KEY_ENTER)
	await _foto("3_menu_grupo")
	load("res://grupo.gd").datos()["Kael"]["puntos"] = 1
	m.menu_abierto._pintar_de_nuevo()
	var mas = Ent.buscar(m.menu_abierto, "mas:fuerza")
	if mas != null:
		mas.grab_focus()
	await _foto("4_menu_mas")
	await _pulsar(KEY_ESCAPE)
	await _pulsar(KEY_ESCAPE)
	load("res://inventario.gd").ganar_oro(100)
	m.jugador.position = m.lugares[0]["pos"] + Vector2(20, 0)
	await _esperar(4)
	await _pulsar(KEY_ENTER)
	await _hasta(func(): return _escena() == ZONA and not R.cambiando and current_scene.jugador != null, 60.0)
	await _esperar(20)
	var z = current_scene
	await _pulsar(KEY_TAB)
	for i in 6:
		if Ent.clave(root.get_viewport().gui_get_focus_owner()) == "TIENDA":
			break
		await _pulsar(KEY_LEFT)
	await _foto("5_ciudad_tienda")
	await _pulsar(KEY_ENTER)
	for i in 8:
		if Ent.clave(root.get_viewport().gui_get_focus_owner()) == "comprar:Poción":
			break
		await _pulsar(KEY_DOWN)
	await _foto("6_tienda_comprar")
	await _pulsar(KEY_ESCAPE)
	await _pulsar(KEY_ESCAPE)
	var toque := InputEventScreenTouch.new()        # con el dedo: el mismo menú, sin marco
	toque.position = Vector2(640, 360)
	toque.pressed = true
	Input.parse_input_event(toque)
	await _esperar(1)
	toque = toque.duplicate()
	toque.pressed = false
	Input.parse_input_event(toque)
	await _esperar(2)
	z.tiene_destino = false
	var menu = load("res://menus.gd").new()
	z.ui.add_child(menu)
	await _foto("7_menu_con_el_dedo")
	print("CAPTURAS hechas en ", salida)
	quit(0)
