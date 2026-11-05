extends Node
# Recursos (autoload, Godot 4.x): guarda en memoria lo que se ha cargado para que no haya tirones.
#   Grupo "comun": lo carga la pantalla de carga (carga.gd) y no se libera nunca.
#   Grupo "zona": lo que usa la zona en la que estás; se libera al volver al mapa del mundo.
# Mientras un recurso esté guardado aquí, cualquier load() de esa ruta en otro script es instantáneo
# (Godot devuelve el mismo recurso ya cargado). Los scripts pueden pedirlo con Recursos.obtener(ruta).
# También cambia de escena (cambiar_escena): pantalla negra, carga en segundo plano (con una línea
# dorada pequeña si tarda más de medio segundo), FPS según la escena y modo ahorro de batería.

# Qué se carga al abrir el juego: estos tipos de archivo de todo res://, menos las carpetas de EXCLUIR
# (decorado/ y texturas/ son de las zonas: se cargan al entrar en cada una).
const EXTENSIONES := ["png", "jpg", "jpeg", "webp", "svg", "fbx", "glb", "gltf", "obj", "tscn", "scn",
	"mp3", "ogg", "wav", "gdshader", "tres", "res", "ttf", "otf"]
const EXCLUIR := ["res://addons/", "res://para_meshy/", "res://.godot/", "res://decorado/", "res://texturas/",
	"res://isla/", "res://carga.tscn"]
# FPS: 60 solo en combate; 30 en el mapa, las zonas y los menús (menos calor y batería).
const FPS_COMBATE := 60
const FPS_NORMAL := 30
const ESCENA_COMBATE := "res://combate.tscn"
const ORO := Color("E8C46A")
# Contador de FPS pequeño arriba en el centro, para medir en el móvil. Ponlo en false para el juego final.
const MOSTRAR_FPS := true

var grupos := {"comun": {}, "zona": {}}
var capa: CanvasLayer
var negro: ColorRect
var linea_fondo: ColorRect
var linea: ColorRect
var cambiando := false
var lbl_fps: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# estilo común de toda la interfaz: se mezcla con el tema por defecto de Godot, que llega a todos los
	# controles (el tema de la ventana no pasa a lo que está dentro de un CanvasLayer)
	var defecto := ThemeDB.get_default_theme()
	defecto.merge_with(load("res://estilo.gd").tema())
	defecto.default_font = load("res://estilo.gd").normal()
	capa = CanvasLayer.new()
	capa.layer = 120
	add_child(capa)
	negro = ColorRect.new()
	negro.color = Color(0, 0, 0, 1)
	negro.size = Vector2(1280, 720)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	negro.visible = false
	capa.add_child(negro)
	linea_fondo = ColorRect.new()                    # la misma línea dorada fina de la carga, en pequeño
	linea_fondo.color = Color(ORO, 0.2)
	linea_fondo.position = Vector2(540, 400)
	linea_fondo.size = Vector2(200, 1)
	negro.add_child(linea_fondo)
	linea = ColorRect.new()
	linea.color = ORO
	linea.position = linea_fondo.position
	linea.size = Vector2(0, 1)
	negro.add_child(linea)
	if MOSTRAR_FPS:
		lbl_fps = Label.new()
		lbl_fps.position = Vector2(600, 2)
		lbl_fps.size = Vector2(80, 20)
		lbl_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_fps.add_theme_font_size_override("font_size", 14)
		lbl_fps.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		lbl_fps.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		lbl_fps.add_theme_constant_override("outline_size", 3)
		lbl_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa.add_child(lbl_fps)
	_poner_fps.call_deferred()


# ================================================================= guardar y pedir

func obtener(ruta: String, grupo := "comun") -> Resource:
	for g in grupos:
		if grupos[g].has(ruta):
			return grupos[g][ruta]
	if not ResourceLoader.exists(ruta):
		return null
	var r := load(ruta)
	if r != null:
		guardar(ruta, r, grupo)
	return r


func guardar(ruta: String, recurso: Resource, grupo := "comun") -> void:
	if not grupos.has(grupo):
		grupos[grupo] = {}
	grupos[grupo][ruta] = recurso


func esta(ruta: String) -> bool:
	for g in grupos:
		if grupos[g].has(ruta):
			return true
	return false


func liberar_grupo(grupo: String) -> void:
	if grupo != "comun":
		grupos[grupo] = {}


# Archivos que se cargan al abrir el juego. Usa ResourceLoader.list_directory (Godot 4.4+), que también
# funciona en el APK, donde solo están los archivos importados.
func listar(carpeta := "res://") -> PackedStringArray:
	var r := PackedStringArray()
	for nombre in ResourceLoader.list_directory(carpeta):
		var ruta := carpeta.path_join(nombre)
		if _excluida(ruta):
			continue
		if nombre.ends_with("/"):
			r.append_array(listar(ruta))
		elif nombre.get_extension().to_lower() in EXTENSIONES:
			r.append(ruta)
	return r


func _excluida(ruta: String) -> bool:
	for e in EXCLUIR:
		if ruta.begins_with(e) or ruta + "/" == e:
			return true
	return false


# ================================================================= cambiar de escena

# Quien llama ya ha fundido su pantalla a negro. Aquí sigue en negro mientras se carga la escena nueva.
# Al volver de una zona al mapa del mundo se libera lo que solo usaba la zona.
func cambiar_escena(ruta: String) -> void:
	if cambiando:
		return
	cambiando = true
	var esc := get_tree().current_scene
	var desde: String = esc.scene_file_path if esc != null else ""
	negro.color.a = 1.0
	negro.visible = true
	linea.size.x = 0.0
	linea.visible = false
	linea_fondo.visible = false
	var escena: PackedScene = null
	if ResourceLoader.load_threaded_request(ruta) == OK:
		var t0 := Time.get_ticks_msec()
		var avance := []
		while ResourceLoader.load_threaded_get_status(ruta, avance) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if Time.get_ticks_msec() - t0 > 500:
				linea.visible = true
				linea_fondo.visible = true
				linea.size.x = 200.0 * float(avance[0])
			await get_tree().process_frame
		escena = ResourceLoader.load_threaded_get(ruta) as PackedScene
	if ruta == "res://mapa.tscn" and desde != ESCENA_COMBATE and desde != ruta:   # se sale de una zona o mazmorra
		liberar_grupo("zona")
	if escena != null:
		get_tree().change_scene_to_packed(escena)
	else:
		push_warning("No se pudo cargar en segundo plano: " + ruta)
		get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	_poner_fps()
	linea.visible = false
	linea_fondo.visible = false
	var t := create_tween()
	t.tween_property(negro, "color:a", 0.0, 0.3)
	await t.finished
	negro.visible = false
	cambiando = false


# Al cerrar o dejar la app en segundo plano se guarda la partida justo donde estás (mapa o zona).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		var esc := get_tree().current_scene
		if esc != null and esc.has_method("guardar_posicion") and not cambiando:
			esc.guardar_posicion()
			load("res://progreso.gd").guardar(esc.scene_file_path)


func _poner_fps() -> void:
	var esc := get_tree().current_scene
	var combate: bool = esc != null and esc.scene_file_path == ESCENA_COMBATE
	Engine.max_fps = FPS_COMBATE if combate else FPS_NORMAL


# Modo ahorro: con un menú abierto (grupo "menu_quieto") o un diálogo esperando a que toques,
# el juego solo redibuja cuando algo cambia. En combate y al caminar, no.
func _process(_d: float) -> void:
	if lbl_fps != null:
		var t := "%d FPS" % Engine.get_frames_per_second()
		if lbl_fps.text != t:                        # solo cambia una vez por segundo (no despierta el modo ahorro)
			lbl_fps.text = t
	var quieto := false
	var esc := get_tree().current_scene
	if esc != null and esc.scene_file_path != ESCENA_COMBATE and not cambiando:
		if not get_tree().get_nodes_in_group("menu_quieto").is_empty():
			quieto = true
		var d = get_node_or_null("/root/Dialogic")
		if d != null and d.current_timeline != null and "current_state" in d and d.current_state == d.States.IDLE:
			quieto = true
	if OS.low_processor_usage_mode != quieto:
		OS.low_processor_usage_mode = quieto
