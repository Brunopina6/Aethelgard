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
	"res://isla/", "res://carga.tscn",
	"res://vegetacion_prueba/", "res://pruebas/"]   # estas dos nunca van en la APK: solo alargaban el arranque del PC
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
	if _aviso_pendiente != "":
		avisar.call_deferred(_aviso_pendiente)
		_aviso_pendiente = ""
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_acabar_dialogo)


# Con «dialogic/layout/end_behaviour» = 1 la interfaz de los diálogos se oculta al acabar en vez de borrarse, pero
# Dialogic no limpia entonces el texto, el nombre ni los retratos (clear(TIMELINE_INFO_ONLY)): antes lo hacía la interfaz
# nueva de cada diálogo al estar lista (clear(KEEP_VARIABLES)). Se limpia aquí, ya oculta, para que el diálogo siguiente
# no enseñe nada del anterior. Recursos se conecta antes que las escenas: si una abre otro diálogo al acabar este, lo
# abre ya limpio.
func _al_acabar_dialogo() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null and dg.current_timeline == null:
		dg.clear(DialogicGameHandler.ClearFlags.KEEP_VARIABLES)


# Aviso al jugador de algo que debe saber, como que no se pudo guardar la partida (progreso.gd). Sale abajo, encima de
# todo (también del fundido entre escenas) y se va solo.
var lbl_aviso: Label


var _aviso_pendiente := ""
var lbl_prueba: Label


# Prepara la interfaz de los diálogos de Dialogic durante la pantalla de carga (carga.gd), oculta. Sin esto, en el PC
# abrir el primer diálogo tardaba unos 185 ms y cada uno de los siguientes unos 55 ms, porque Dialogic la rehacía en
# cada diálogo (pruebas/medir_primeras_veces.gd, 2026-11-08). Con «dialogic/layout/end_behaviour» = 1 (project.godot),
# al acabar un diálogo la interfaz se oculta en vez de borrarse. Devuelve los microsegundos que ha costado.
func precalentar_dialogos() -> int:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or not dg.has_subsystem("Styles") or dg.Styles.has_active_layout_node():
		return 0
	var t := Time.get_ticks_usec()
	var interfaz = dg.Styles.load_style()
	if interfaz != null:
		interfaz.hide()
	return Time.get_ticks_usec() - t


# El estilo de los diálogos arrastra todas las escenas de su interfaz: leerlo era casi todo el coste de prepararla
# (unos 145 de 173 ms en el PC, pruebas/sonda_dialogic_carga.gd). carga.gd lo lee en segundo plano con lo común, y
# así precalentar_dialogos() solo tiene que crearla.
func ruta_estilo_dialogos() -> String:
	if get_node_or_null("/root/Dialogic") == null:
		return ""
	return DialogicStylesUtil.get_style_path("")


# Partida de prueba (opción de desarrollo de carga.gd): una etiqueta fija arriba, para no confundirla con la de verdad.
func marcar_partida_prueba() -> void:
	if lbl_prueba != null or capa == null:
		return
	lbl_prueba = Label.new()
	lbl_prueba.text = "PARTIDA DE PRUEBA · tu partida de siempre no cambia"
	lbl_prueba.position = Vector2(340, 4)
	lbl_prueba.size = Vector2(600, 24)
	lbl_prueba.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_prueba.add_theme_font_size_override("font_size", 16)
	lbl_prueba.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 0.85))
	lbl_prueba.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl_prueba.add_theme_constant_override("outline_size", 4)
	lbl_prueba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(lbl_prueba)


func avisar(texto: String, segundos := 5.0) -> void:
	print("AVISO AL JUGADOR: ", texto)
	if capa == null:                                 # aún no está lista (muy al principio): sale en cuanto lo esté
		_aviso_pendiente = texto
		return
	if lbl_aviso == null:
		lbl_aviso = Label.new()
		lbl_aviso.position = Vector2(140, 600)
		lbl_aviso.size = Vector2(1000, 90)
		lbl_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_aviso.add_theme_font_size_override("font_size", 24)
		lbl_aviso.add_theme_color_override("font_color", Color(1.0, 0.9, 0.75))
		lbl_aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl_aviso.add_theme_constant_override("outline_size", 8)
		lbl_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa.add_child(lbl_aviso)
	lbl_aviso.text = texto
	lbl_aviso.modulate.a = 1.0
	var t := lbl_aviso.create_tween()
	t.tween_interval(segundos)
	t.tween_property(lbl_aviso, "modulate:a", 0.0, 0.8)


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
		elif nombre.get_extension().to_lower() in EXTENSIONES and not _de_otro_perfil(ruta):
			r.append(ruta)
	return r


# Modelos con versión ligera (X.glb y X_ligero.glb, como los edificios de Oakhaven 3D): se precarga solo la que usa el
# perfil gráfico de este aparato, con la misma regla que zonas3d/oakhaven/ciudad.gd (_modelo). Antes se precargaban
# las dos y una no se usaba nunca (fase 2, 10/11). Si el jugador cambia de perfil en Ajustes, la otra se carga al
# entrar en la región, con la pantalla en negro.
var _ligeros = null

# Texturas que no usa nadie (fase 2, 10/11; medido con pruebas/medir_texturas_modelos.gd):
#   1. Las <modelo>_<n>.png que Godot sacó de un FBX y que ese modelo no usa (sus dependencias dicen cuáles sí): Kael,
#      Garon y Grimfang solo usan _0 y _1; Érebo, ninguna; la de Lya (Meshy), solo _0. Si un modelo empieza a usar
#      otra, sale en sus dependencias y se vuelve a precargar sola.
#   2. Las de dos FBX de Meshy que ya no están (Garon y Grimfang antiguos): nadie las carga.
# Antes se precargaban al arrancar y se quedaban en la memoria de vídeo toda la partida. prueba_precarga lo vigila.
const SIN_USO := ["res://Meshy_AI_Crimson_Helm_Guardian_20261103_animated_mixamo_All_animation",
	"res://Meshy_AI_Grimfang_Goblin_20261103_animated_mixamo_All_animation"]
var _deps_fbx := {}


func _textura_sin_uso(ruta: String) -> bool:
	if not ruta.ends_with(".png") or ruta.get_base_dir() != "res://":
		return false
	for s in SIN_USO:
		if ruta.begins_with(s) and not ResourceLoader.exists(s + ".fbx"):
			return true
	var base := ruta.get_basename()
	var guion := base.rfind("_")
	if guion < 0 or not base.substr(guion + 1).is_valid_int():
		return false
	var fbx := base.substr(0, guion) + ".fbx"
	if not ResourceLoader.exists(fbx):
		return false
	if not _deps_fbx.has(fbx):
		var d := {}
		for dep in ResourceLoader.get_dependencies(fbx):
			var p: String = dep.substr(maxi(0, dep.find("res://")))   # «uid://…::::res://…» o «res://…::Tipo» → la ruta
			if p.find("::") >= 0:
				p = p.substr(0, p.find("::"))
			d[p] = true
		_deps_fbx[fbx] = d
	return not _deps_fbx[fbx].has(ruta)


func _de_otro_perfil(ruta: String) -> bool:
	if _textura_sin_uso(ruta):
		return true
	if not ruta.ends_with(".glb"):
		return false
	if _ligeros == null:
		_ligeros = false
		if ResourceLoader.exists("res://prototipos/calidad_proto.gd"):   # no está en la app estable
			var cal = load("res://prototipos/calidad_proto.gd")
			_ligeros = cal.datos().get("modelos_ligeros", cal.actual() != "alto")
	if ruta.ends_with("_ligero.glb"):
		return not _ligeros and ResourceLoader.exists(ruta.trim_suffix("_ligero.glb") + ".glb")
	return _ligeros and ResourceLoader.exists(ruta.get_basename() + "_ligero.glb")


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
		if get_tree().has_group("menu_quieto"):                 # sin crear una lista cada fotograma
			quieto = true
		var d = get_node_or_null("/root/Dialogic")
		if d != null and d.current_timeline != null and "current_state" in d and d.current_state == d.States.IDLE:
			quieto = true
	if OS.low_processor_usage_mode != quieto:
		OS.low_processor_usage_mode = quieto
