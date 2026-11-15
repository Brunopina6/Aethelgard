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
var cambiando := false
# El aviso de carga sobre el negro (V12, 12/11): un rombo dorado que gira, sin cifra (no hay progreso real que contar), y
# qué se prepara. Sustituye a la línea dorada de avance: solo medía la lectura de la escena, que ya estaba en memoria, y se
# quedaba llena mientras el combate se montaba y compilaba sus sombreadores.
var aviso_carga: Control
var rombo: Control
var lbl_carga: Label
var texto_carga := ""                    # lo que dice ahora (lo leen las pruebas)
var _giro := 0.0
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
	_crear_aviso_carga()
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
var boton_banco: Button                          # V12 (14/11): «Volver al banco» del banco de pruebas de Auditoría


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
	lbl_prueba.position = Vector2(16, 4)             # (14/11: arriba a la izquierda; en el centro pisaba el contador de FPS)
	lbl_prueba.size = Vector2(600, 24)
	lbl_prueba.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_prueba.add_theme_font_size_override("font_size", 16)
	lbl_prueba.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 0.85))
	lbl_prueba.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl_prueba.add_theme_constant_override("outline_size", 4)
	lbl_prueba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(lbl_prueba)


# V12 (14/11): dentro del banco de pruebas de Auditoría (banco_pruebas.gd), en una exploración, un botón para volver a
# él (las regiones 3D no tienen menú del grupo). No sale en el banco ni en el combate, ni fuera del banco.
func _poner_boton_banco() -> void:
	var esc := get_tree().current_scene
	var ruta: String = esc.scene_file_path if esc != null else ""
	var BP = load("res://banco_pruebas.gd")
	var ver: bool = capa != null and BP.en_banco() and ruta != BP.ESCENA and ruta != ESCENA_COMBATE and ruta != ""
	if not ver:
		if boton_banco != null:
			boton_banco.visible = false
		return
	if boton_banco == null:
		boton_banco = Button.new()
		boton_banco.text = "Volver al banco"
		boton_banco.position = Vector2(16, 96)       # (arriba a la izquierda: a la derecha tapaba CAL y RND)
		boton_banco.custom_minimum_size = Vector2(210, 48)
		boton_banco.add_theme_font_size_override("font_size", 19)
		boton_banco.focus_mode = Control.FOCUS_NONE     # (no roba el foco del mando a la escena)
		boton_banco.pressed.connect(func():
			if not cambiando:
				cambiar_escena(load("res://banco_pruebas.gd").ESCENA))
		capa.add_child(boton_banco)
	boton_banco.visible = true


# V12 (14/11): al salir del banco de pruebas de Auditoría (banco_pruebas.gd), la etiqueta se quita: lo siguiente es la
# partida de siempre.
func desmarcar_partida_prueba() -> void:
	if lbl_prueba != null:
		lbl_prueba.queue_free()
		lbl_prueba = null
	if boton_banco != null:
		boton_banco.visible = false


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


# Pide en segundo plano lo que se va a usar pronto (V12, 12/11, cargas; p. ej. el combate de Bramavidrio cuando suena su
# aviso, zonas3d/mar_cristal/gusano.gd). No bloquea nada: si ya está en memoria o ya se pidió, no hace nada; lo que llega
# se guarda en «grupo» (por defecto «zona»: se libera al volver al mapa del mundo). _process recoge lo terminado.
var _en_hilo := {}


func precargar(rutas: Array, grupo := "zona") -> void:
	for r in rutas:
		var ruta := str(r)
		if ruta == "" or esta(ruta) or _en_hilo.has(ruta) or not ResourceLoader.exists(ruta):
			continue
		if ResourceLoader.load_threaded_request(ruta) == OK:
			_en_hilo[ruta] = grupo


func _recoger_precargas() -> void:
	for ruta in _en_hilo.keys():
		match ResourceLoader.load_threaded_get_status(ruta):
			ResourceLoader.THREAD_LOAD_LOADED:
				var r := ResourceLoader.load_threaded_get(ruta)
				if r != null:
					guardar(ruta, r, _en_hilo[ruta])
				_en_hilo.erase(ruta)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_en_hilo.erase(ruta)


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
	if carpeta == "res://":
		for g in GUIONES_RESIDENTES:
			if ResourceLoader.exists(g):
				r.append(g)
		for c in CARPETAS_GUIONES_RESIDENTES:
			for n in ResourceLoader.list_directory(c):
				if n.ends_with(".gd"):
					r.append(c.path_join(n))
	return r


# Guiones que el juego carga con load() en mitad de la partida (rend2, 12/11; pruebas/herramientas/sonda_guiones.gd):
# la primera vez se leen y compilan ahí mismo. En el PC, tras la carga común: el menú 112 ms al abrirlo desde el mapa,
# la tienda 65, la alquimia 65, el Diario 37, el gremio 36, la botica 26 y las parejas de la taberna 32 (en el móvil,
# varias veces más). Con ellos se precargan en segundo plano en la pantalla de carga y se quedan en memoria (son
# pequeños). También los de los personajes de las regiones y el grupo (Kael 22, Garon 33, Lya y gestos 13, el grupo 25):
# se compilaban al entrar en la primera región.
const GUIONES_RESIDENTES := ["res://menus.gd", "res://diario.gd", "res://tienda.gd", "res://alquimia_menu.gd",
	"res://gremio_menu.gd", "res://servicios_botica.gd", "res://taberna_parejas.gd", "res://investigacion.gd",
	"res://inventario.gd", "res://kael_3d.gd", "res://maga_3d.gd", "res://garon_3d.gd", "res://gestos_3d.gd",
	"res://esperas_3d.gd", "res://zonas3d/grupo_3d.gd"]
# Y todos los de estas carpetas (segunda pasada, 12/11; pruebas/herramientas/sonda_retrato.gd): el primer «join» de un
# diálogo hace que Dialogic lea y compile sus 16 animaciones de retrato (4-5 ms cada una en el PC). Era el tirón de
# 102-162 ms del primer diálogo de la sesión (el de pv_02 al volver del primer combate en Pastos Verdes).
const CARPETAS_GUIONES_RESIDENTES := ["res://addons/dialogic/Modules/Character/DefaultAnimations/"]


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


# V12 (12/11, rendimiento de cargas; pruebas/herramientas/listar_precarga.gd y medir_cargas.gd): lo que hoy NO se usa no
# se precarga al arrancar (se quedaba en la memoria toda la partida: en el Redmi, la memoria pasó de 745-948 MB a 1,0-1,1 GB
# y la carga del título de 15,5 a 18,5-21 s). Se carga cuando haga falta, con la pantalla tapada, como cualquier otro recurso.
#   - Lo que va detrás de un interruptor APAGADO (carpeta → interruptor; se mira con su propia función, así que al encenderlo
#     en las pruebas o en Ajustes se vuelve a precargar). Naira también sale con su hito de la partida, que al arrancar aún
#     no se ha leído: entonces se carga al entrar en el combate o la región.
#   - Los prototipos que no engancha nadie (Cencerrante, Vidracrán y Tolvanera).
#   - De Bramavidrio, solo la versión en uso (bramavidrio_version.gd) y, de ella, solo el modelo y la piel del perfil
#     gráfico (alto: sin sufijo; medio: _medio; bajo: _bajo), igual que elige bramavidrio*_3d.gd.
const APAGADOS := {
	"res://personajes/heroes_v2/": "heroes_v2",
	"res://personajes/naira/": "naira_v12",
	"res://personajes/desierto/": "npc_desierto_v12",
	"res://enemigos/guardian_piedra/": "enemigos_v12",
	"res://enemigos/golem_ambar/": "enemigos_v12",
	"res://enemigos/gorthor/": "enemigos_v12",
	"res://enemigos/v12_comun/": "enemigos_v12",
	# V12 (13/11): el bestiario (Peón de Linde y Velador de Corteza) y los sonidos propios de los enemigos v12, que solo
	# suenan con «enemigos_v12»: fuera de la precarga mientras va apagado (prueba_audio_memoria mide lo que se carga)
	"res://enemigos/peon_linde/": "enemigos_v12",
	"res://enemigos/velador_corteza/": "enemigos_v12",
	"res://enemigos/bestiario_comun/": "enemigos_v12",
	# V12, Custodio (14/11, piloto): meshy_e01, el Custodio de Porcelana (combate_meshy_e01.gd), solo con su interruptor
	"res://enemigos/meshy_e01/": "meshy_e01",
	"res://audio/efectos/centinela/": "enemigos_v12",
	"res://audio/efectos/golem/": "enemigos_v12",
	"res://audio/efectos/gorthor/": "enemigos_v12",
	"res://audio/efectos/peon/": "enemigos_v12",
	"res://audio/efectos/velador/": "enemigos_v12",
	"res://enemigos/cencerrante/": "",
	"res://enemigos/vidracran/": "",
	"res://enemigos/tolvanera/": "",
	# rend2 (12/11): Humbaba (APAGADO, combate_humbaba.gd activo()) y «Pastoral Pulse» (solo si se eligió en Ajustes,
	# musica.gd): unos 12 MB y 3 MB que se precargaban sin usarse (pruebas/herramientas/listar_precarga.gd)
	"res://enemigos/humbaba/": "humbaba_v12",
	"res://audio/musica/pastos/pastoral_pulse.ogg": "musica_pastos",
}
const BRAMAVIDRIO := "res://enemigos/bramavidrio/"
var _encendidos := {}


func _encendido(interruptor: String) -> bool:
	if interruptor == "":
		return false
	if not _encendidos.has(interruptor):
		var si := false
		match interruptor:
			"heroes_v2":
				si = ResourceLoader.exists("res://personajes/heroes_v2/heroes_v2.gd") \
					and load("res://personajes/heroes_v2/heroes_v2.gd").activado()
			"naira_v12":
				si = ResourceLoader.exists("res://grupo.gd") and load("res://grupo.gd").naira_v12()
			"npc_desierto_v12":
				si = ResourceLoader.exists("res://personajes/desierto/npc_desierto_3d.gd") \
					and load("res://personajes/desierto/npc_desierto_3d.gd").activado()
			"humbaba_v12":
				si = ResourceLoader.exists("res://combate_humbaba.gd") and load("res://combate_humbaba.gd").activo()
			"musica_pastos":
				si = load("res://musica.gd").musica_pastos_elegida()
			_:                                       # enemigos_v12 (combate.gd _enemigos_v12)
				si = bool(Engine.get_meta(interruptor, false)) or interruptor in OS.get_cmdline_user_args()
		_encendidos[interruptor] = si
	return _encendidos[interruptor]


func _sin_uso_hoy(ruta: String) -> bool:
	for carpeta in APAGADOS:
		if ruta.begins_with(carpeta):
			return not _encendido(APAGADOS[carpeta])
	if not ruta.begins_with(BRAMAVIDRIO) or not ruta.get_extension() in ["glb", "webp"]:
		return false
	var V = load(BRAMAVIDRIO + "bramavidrio_version.gd")
	var carpeta_en_uso: String = V.modelo().get_base_dir() + "/"
	if ruta.get_base_dir() + "/" != carpeta_en_uso:
		return true
	var perfil := "alto"
	if ResourceLoader.exists("res://prototipos/calidad_proto.gd"):
		perfil = str(load("res://prototipos/calidad_proto.gd").actual())
	var base := ruta.get_basename()
	var de := "alto"
	if base.ends_with("_medio"):
		de = "medio"
	elif base.ends_with("_bajo"):
		de = "bajo"
	return de != perfil and not (perfil not in ["alto", "medio", "bajo"] and de == "alto")


func _de_otro_perfil(ruta: String) -> bool:
	if _textura_sin_uso(ruta) or _sin_uso_hoy(ruta):
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
# V12 (12/11, cargas; pruebas/herramientas/medir_cargas.gd):
#   - nada de negro mudo: sale el aviso de carga (qué se prepara y un rombo que gira, sin cifra) y se deja ver un fotograma
#     ANTES de montar la escena nueva. En el móvil, montar el combate y compilar sus sombreadores puede congelar la imagen
#     unos segundos: así lo que se queda en pantalla dice qué pasa;
#   - mientras dura, la ventana no recibe toques, teclas ni botones (ni los acumulados durante una congelación): ni dobles
#     pulsaciones ni órdenes que caigan en la escena nueva antes de verse;
#   - al ir al combate, la música de la exploración empieza a fundirse ya (Musica, contexto «combate», recuerda por dónde
#     iba), no cuando la escena nueva ya está montada.
func cambiar_escena(ruta: String) -> void:
	if cambiando:
		return
	cambiando = true
	var esc := get_tree().current_scene
	var desde: String = esc.scene_file_path if esc != null else ""
	negro.color.a = 1.0
	negro.visible = true
	get_tree().root.gui_disable_input = true
	_mostrar_aviso_carga(_texto_de(ruta))
	var musica = get_node_or_null("/root/Musica")
	if ruta == ESCENA_COMBATE and musica != null and musica.has_method("pedir"):
		musica.pedir("combate")
	await get_tree().process_frame                 # el aviso se ve antes de cualquier trabajo largo
	var escena: PackedScene = null
	if ResourceLoader.load_threaded_request(ruta) == OK:
		while ResourceLoader.load_threaded_get_status(ruta) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		escena = ResourceLoader.load_threaded_get(ruta) as PackedScene
	if ruta == "res://mapa.tscn" and desde != ESCENA_COMBATE and desde != ruta:   # se sale de una zona o mazmorra
		liberar_grupo("zona")
	var err := OK
	if escena != null:
		err = get_tree().change_scene_to_packed(escena)
	else:
		push_warning("No se pudo cargar en segundo plano: " + ruta)
		err = get_tree().change_scene_to_file(ruta)
	# V12, mapamundi 3D: si no se pudo cambiar, la escena que lo pidió y sabe recuperarse (carga_fallida) vuelve a dar
	# el control; el negro se quita igual (abajo). Las demás escenas, como siempre.
	if err != OK and is_instance_valid(esc) and esc.has_method("carga_fallida"):
		esc.carga_fallida(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	_poner_fps()
	_poner_boton_banco()
	get_tree().root.gui_disable_input = false       # la escena nueva ya está montada y dibujada
	var t := create_tween()
	t.tween_property(negro, "color:a", 0.0, 0.3)
	await t.finished
	negro.visible = false
	aviso_carga.visible = false
	texto_carga = ""
	cambiando = false


# Qué se dice mientras se prepara cada escena (sin prometer tiempos ni cifras).
func _texto_de(ruta: String) -> String:
	if ruta == ESCENA_COMBATE:
		return "Preparando el combate"
	if ruta == "res://mapa.tscn":
		return "Volviendo al mapa"
	return "Cargando"


func _crear_aviso_carga() -> void:
	aviso_carga = Control.new()
	aviso_carga.position = Vector2(440, 330)
	aviso_carga.size = Vector2(400, 90)
	aviso_carga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso_carga.visible = false
	negro.add_child(aviso_carga)
	rombo = Control.new()                            # un rombo dorado con un brillo que gira (como las chispas de la carga)
	rombo.position = Vector2(200, 18)
	rombo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rombo.draw.connect(func():
		var r := 11.0
		var pts := PackedVector2Array()
		for i in 4:
			var a := _giro + i * PI * 0.5
			pts.append(Vector2(cos(a), sin(a) * 0.62) * r)
		rombo.draw_colored_polygon(pts, Color(ORO, 0.85))
		pts.append(pts[0])
		rombo.draw_polyline(pts, Color(1.0, 0.95, 0.8, 0.9), 1.5)
		for i in 3:                                  # tres chispas que lo rodean
			var a := -_giro * 1.6 + i * TAU / 3.0
			rombo.draw_circle(Vector2(cos(a), sin(a) * 0.5) * 24.0, 2.2, Color(ORO, 0.55)))
	aviso_carga.add_child(rombo)
	lbl_carga = Label.new()
	lbl_carga.position = Vector2(0, 46)
	lbl_carga.size = Vector2(400, 34)
	lbl_carga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_carga.add_theme_font_size_override("font_size", 22)
	lbl_carga.add_theme_color_override("font_color", Color(1.0, 0.93, 0.8, 0.85))
	lbl_carga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso_carga.add_child(lbl_carga)


func _mostrar_aviso_carga(texto: String) -> void:
	texto_carga = texto
	lbl_carga.text = texto + "…"
	aviso_carga.visible = true
	rombo.queue_redraw()


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
	if not _en_hilo.is_empty():
		_recoger_precargas()
	if aviso_carga != null and aviso_carga.visible:   # el rombo gira mientras se prepara la escena (sin cifra)
		_giro = fmod(_giro + _d * 2.4, TAU)
		rombo.queue_redraw()
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
