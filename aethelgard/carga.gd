extends Node2D
# Pantalla de carga al abrir el juego (Godot 4.x). Es la escena principal (carga.tscn).
#   1) Archivos (70 % de la línea): carga en segundo plano lo común de res:// y lo guarda en Recursos.
#   2) Shaders (20 %): dibuja una vez, fuera de la vista, a Kael y Lya en 3D, cada efecto de vfx/,
#      la hierba y el agua de las zonas. En Android, la primera vez que se dibuja algo se compila su
#      shader y da un tirón: así ese tirón pasa aquí y no en mitad de un combate.
#   3) Diálogos (un fotograma): prepara, oculta, la interfaz de los diálogos (Recursos.precalentar_dialogos).
#   4) Texturas de las zonas (10 %): genera las que zona.gd guarda en caché (atlas de cada estilo,
#      objetos dibujados, matas), para que entrar en una zona sea instantáneo.
# Al llegar al 100 %: «TOCA PARA EMPEZAR». La pantalla se ve al menos 2 segundos.
# Si un archivo falla, lo apunta en la Salida de Godot y sigue con el resto.

const SIGUIENTE := "res://mapa.tscn"
const MINIMO := 2.0               # segundos mínimos en pantalla
const A_LA_VEZ := 6               # archivos cargándose a la vez en segundo plano
# Sin ventana (pruebas), de uno en uno: el renderizador falso de Godot sin ventana no aguanta crear mallas desde varios
# hilos a la vez (cierres en prueba_boton_prologo, 10/11). En el móvil y en el PC con ventana, como siempre.
var a_la_vez := _a_la_vez()
const FRAMES_SHADERS := 24        # fotogramas dibujando los modelos y efectos fuera de la vista
const FRASES := [
	"La niebla no perdona a nadie… salvo a uno.",
	"Hace tres mil años, la Alta Sacerdotisa defendió la naturaleza.",
	"Lo que el fuego se llevó, la lluvia lo devuelve en flor.",
	"La sangre no te hace nombre; te lo dan los pasos que das.",
]
const M := preload("res://menu_combate.gd")

var fase := "archivos"
var tiempo := 0.0
var pendientes: PackedStringArray
var en_curso: Array = []
var total := 0
var hechos := 0
var fallos := 0
var progreso := 0.0               # 0..1 en toda la carga
var frames_shader := 0
var vista_3d: Node                   # agrupa los estudios del precalentado (combate.gd estudio_3d y estudio_vfx)
var vista_2d: SubViewport
var tareas_zona: Array = []
var tareas_total := 1
var zona_tmp: Node
var frase_i := 0
var listo := false
var saliendo := false

var linea: ColorRect
var linea_fondo: ColorRect
var brillo: TextureRect
var porcentaje: Label
var frase: Label
var toca: Label
var boton_prueba: Button                 # solo en la versión experimental: la misión desde el principio, en otra ranura
var boton_prologo: Button                # solo en la versión experimental: una partida nueva con el prólogo, en esa ranura
var boton_banco: Button                  # V12 (14/11): solo en Auditoría o en el editor, el banco de pruebas (banco_pruebas.gd)
var sonidos := {}
var reproductor: AudioStreamPlayer


func _ready() -> void:
	# Pantalla de inicio alternativa, EN PRUEBAS (11/11): solo si se eligió en Ajustes (versión experimental) o con
	# «-- portada_alternativa» (portada/eleccion.gd). Ella hace esta misma carga (hereda de este guion). Sin elegirla,
	# esta pantalla sigue exactamente igual.
	if load("res://portada/eleccion.gd").usar_alternativa():
		set_process(false)
		set_process_input(false)
		get_tree().change_scene_to_file.call_deferred(load("res://portada/eleccion.gd").ESCENA)
		return
	Engine.max_fps = 60
	_crear_pantalla()
	pendientes = Recursos.listar()
	var estilo: String = Recursos.ruta_estilo_dialogos()
	if estilo != "" and ResourceLoader.exists(estilo):
		pendientes.append(estilo)                   # la interfaz de los diálogos, en segundo plano (ver _paso_dialogos)
	total = maxi(1, pendientes.size())
	print("Carga: %d archivos comunes" % pendientes.size())


# ================================================================= aspecto

func _crear_pantalla() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = M.SOMBRA
	fondo.size = Vector2(1280, 720)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(fondo)

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var glow := GradientTexture2D.new()
	glow.gradient = g
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.width = 64
	glow.height = 64
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# cenizas brillantes que suben despacio
	var cenizas := CPUParticles2D.new()
	cenizas.texture = glow
	cenizas.material = aditivo
	cenizas.amount = 46
	cenizas.lifetime = 9.0
	cenizas.preprocess = 9.0
	cenizas.position = Vector2(640, 740)
	cenizas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	cenizas.emission_rect_extents = Vector2(680, 10)
	cenizas.direction = Vector2(0, -1)
	cenizas.spread = 18.0
	cenizas.gravity = Vector2(0, -4)
	cenizas.initial_velocity_min = 22.0
	cenizas.initial_velocity_max = 55.0
	cenizas.scale_amount_min = 0.05
	cenizas.scale_amount_max = 0.16
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	rampa.colors = PackedColorArray([Color(M.ORO, 0.0), Color(M.ORO, 0.8), Color(M.BRASA, 0.5), Color(M.BRASA, 0.0)])
	cenizas.color_ramp = rampa
	capa.add_child(cenizas)

	# El logotipo de REBELUM (T-098). Va en modo aditivo: su cielo está restado y sus bordes funden a negro,
	# así que solo suman la luz de las letras, el cristal y el ala, sin dejar un recuadro.
	var logo := TextureRect.new()
	logo.texture = load("res://marca/logo_rebelum.webp")
	logo.material = aditivo
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(370, 14)
	logo.size = Vector2(540, 381)
	capa.add_child(logo)
	var sub := _etiqueta("CÓNCLAVE DE LAS CENIZAS", M.fuente(M.FUENTE_ORDEN, 9, 0), 22, Color(M.ORO, 0.9))
	sub.position = Vector2(0, 372)
	capa.add_child(sub)

	linea_fondo = ColorRect.new()
	linea_fondo.color = Color(M.ORO, 0.16)
	linea_fondo.position = Vector2(440, 420)
	linea_fondo.size = Vector2(400, 2)
	capa.add_child(linea_fondo)
	brillo = TextureRect.new()
	brillo.texture = glow
	brillo.material = aditivo
	brillo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	brillo.position = Vector2(400, 402)
	brillo.size = Vector2(480, 38)
	brillo.modulate = Color(M.ORO, 0.0)
	capa.add_child(brillo)
	linea = ColorRect.new()
	linea.color = M.ORO
	linea.position = linea_fondo.position
	linea.size = Vector2(0, 2)
	capa.add_child(linea)
	porcentaje = _etiqueta("0 %", M.fuente(M.FUENTE_ORDEN, 2, 0), 18, M.GRIS)
	porcentaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	porcentaje.position = Vector2(856, 406)
	porcentaje.size = Vector2(100, 30)
	capa.add_child(porcentaje)
	toca = _etiqueta("TOCA PARA EMPEZAR", M.fuente(M.FUENTE_ORDEN, 8, 0), 24, M.LUZ_CLARA)
	toca.position = Vector2(0, 470)
	toca.modulate.a = 0.0
	capa.add_child(toca)
	frase = _etiqueta(FRASES[0], M.fuente(M.FUENTE_NOMBRE, 0, 500), 28, Color(M.LUZ_CLARA, 0.75))
	frase.position = Vector2(0, 630)
	capa.add_child(frase)
	# Opción de desarrollo, solo en la versión experimental: jugar la misión de Pastos Verdes desde el principio en otra
	# ranura (progreso.gd, GUARDADO_EXP_PRUEBA), sin tocar la partida de siempre.
	if load("res://modo3d.gd").activo():
		boton_prueba = Button.new()
		boton_prueba.text = "Probar la misión desde el principio"
		boton_prueba.position = Vector2(860, 652)
		boton_prueba.custom_minimum_size = Vector2(400, 56)
		boton_prueba.add_theme_font_size_override("font_size", 20)
		boton_prueba.focus_mode = Control.FOCUS_ALL      # con teclado o mando: ↓ lo elige, Intro / A lo pulsa, ↑ / Esc vuelve
		boton_prueba.visible = false
		boton_prueba.pressed.connect(func(): _empezar(true))
		capa.add_child(boton_prueba)
		# La otra opción de desarrollo: una partida nueva en la misma ranura de prueba, que empieza en el mapa con el
		# prólogo (T-081). Así se ve el diálogo inicial sin tocar la partida de siempre. Abajo a la izquierda, simétrica
		# a la de la derecha y sin tapar la frase de abajo (que empieza hacia x = 384).
		boton_prologo = Button.new()
		boton_prologo.text = "Probar el prólogo (partida nueva)"
		boton_prologo.position = Vector2(20, 652)
		boton_prologo.custom_minimum_size = Vector2(350, 56)
		boton_prologo.add_theme_font_size_override("font_size", 20)
		boton_prologo.focus_mode = Control.FOCUS_ALL     # ← lo elige; → vuelve al de la derecha; ↑ / Esc suelta el foco
		boton_prologo.visible = false
		boton_prologo.pressed.connect(func(): _empezar(true, true))
		capa.add_child(boton_prologo)
	# V12 (14/11): el banco de pruebas de Auditoría (banco_pruebas.gd), arriba a la derecha. Su partida es aparte: la de
	# siempre no se toca. En las versiones normales no existe.
	if load("res://banco_pruebas.gd").permitido():
		boton_banco = Button.new()
		boton_banco.text = "Banco de pruebas (Auditoría)"
		boton_banco.position = Vector2(900, 16)
		boton_banco.custom_minimum_size = Vector2(360, 56)
		boton_banco.add_theme_font_size_override("font_size", 20)
		boton_banco.focus_mode = Control.FOCUS_ALL
		boton_banco.visible = false
		boton_banco.pressed.connect(_abrir_banco)
		capa.add_child(boton_banco)
	_texto_empezar(Entrada.modo)
	Entrada.modo_cambiado.connect(_texto_empezar)

	sonidos = M.sonidos_ui()
	reproductor = AudioStreamPlayer.new()
	reproductor.volume_db = -4.0
	reproductor.bus = &"Interfaz"                    # buses y volúmenes: sonido.gd
	add_child(reproductor)


func _etiqueta(texto: String, fuente: Font, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.size = Vector2(1280, tam * 1.5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ================================================================= carga por partes

func _process(delta: float) -> void:
	tiempo += delta
	var t := tiempo
	match fase:
		"archivos":
			_paso_archivos()
			progreso = 0.7 * float(hechos) / total
		"shaders":
			_paso_shaders()
			progreso = 0.7 + 0.2 * float(frames_shader) / FRAMES_SHADERS
		"dialogos":
			_paso_dialogos()
			progreso = 0.9
		"zonas":
			_paso_zonas()
			progreso = 0.9 + 0.1 * (1.0 - float(tareas_zona.size()) / tareas_total)
	linea.size.x = lerpf(linea.size.x, 400.0 * progreso, minf(1.0, delta * 10.0))
	porcentaje.text = "%d %%" % int(round(progreso * 100.0))
	if int(t / 4.0) != frase_i:                      # la frase cambia cada 4 segundos con un fundido
		frase_i = int(t / 4.0)
		var tw := create_tween()
		tw.tween_property(frase, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): frase.text = FRASES[frase_i % FRASES.size()])
		tw.tween_property(frase, "modulate:a", 1.0, 0.5)
	if fase == "fin" and tiempo >= MINIMO and not listo:
		listo = true
		linea.size.x = 400.0
		porcentaje.text = "100 %"
		create_tween().tween_property(brillo, "modulate:a", 0.8, 0.4)
		print("Carga terminada en %.1f s (%d archivos, %d fallos)" % [tiempo, hechos, fallos])
		_medir_y_salir()
		if "auto" in OS.get_cmdline_user_args():     # pruebas: entra solo
			_empezar.call_deferred()
	if listo:
		toca.modulate.a = 0.55 + 0.45 * sin(t * 3.0)  # late suavemente
		brillo.modulate.a = 0.6 + 0.25 * sin(t * 3.0)
		if boton_prueba != null and not saliendo:
			boton_prueba.visible = true
		if boton_prologo != null and not saliendo:
			boton_prologo.visible = true
		if boton_banco != null and not saliendo:
			boton_banco.visible = true


# V12 (12/11, cargas): en cada fotograma se recoge lo terminado y se piden más durante PRESUPUESTO_MS como mucho (antes,
# una sola vuelta: un archivo que acababa esperaba al fotograma siguiente para dejar sitio al próximo, y con 930 archivos
# la carga iba al ritmo de los fotogramas). La pantalla sigue moviéndose: nunca se pasa del presupuesto.
const PRESUPUESTO_MS := 8.0


func _paso_archivos() -> void:
	var hasta := Time.get_ticks_usec() + int(PRESUPUESTO_MS * 1000.0)
	while true:
		_vuelta_archivos()
		if (pendientes.is_empty() and en_curso.is_empty()) or Time.get_ticks_usec() >= hasta:
			break
		OS.delay_usec(300)                        # deja trabajar a los hilos de carga
	if pendientes.is_empty() and en_curso.is_empty():
		fase = "shaders"
		_preparar_shaders()


func _vuelta_archivos() -> void:
	while en_curso.size() < a_la_vez and not pendientes.is_empty():
		var ruta: String = pendientes[pendientes.size() - 1]
		pendientes.remove_at(pendientes.size() - 1)
		if Recursos.esta(ruta):
			hechos += 1
		elif ResourceLoader.load_threaded_request(ruta) == OK:
			en_curso.append(ruta)
		else:
			_fallo(ruta)
	for ruta in en_curso.duplicate():
		match ResourceLoader.load_threaded_get_status(ruta):
			ResourceLoader.THREAD_LOAD_LOADED:
				var r := ResourceLoader.load_threaded_get(ruta)
				if r != null:
					Recursos.guardar(ruta, r)
				hechos += 1
				en_curso.erase(ruta)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fallo(ruta)
				en_curso.erase(ruta)


# Cuántos archivos a la vez: A_LA_VEZ; sin ventana, 1 (ver arriba). «-- a_la_vez=N» lo cambia para medir
# (pruebas/herramientas/medir_cargas.gd).
static func _a_la_vez() -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("a_la_vez="):
			return maxi(1, int(a.substr(9)))
	return 1 if DisplayServer.get_name() == "headless" else A_LA_VEZ


# V12 (19/11, PRECARGA_19_11): si la pantalla se va con archivos aún cargándose en hilo (se cierra el juego a mitad de la
# carga, o una prueba cambia de escena o sale antes de que acabe), se espera a que terminen (como mucho «a_la_vez»
# archivos, y con tope de tiempo: Recursos.esperar_en_hilo) y se guardan en Recursos. Sin esto, al cerrar con una escena a
# medias el motor corta la carga de su guion y escribe «Parse Error: Failed. [Resource file res://ciudad_oakhaven.tscn:6]»
# (pruebas/prueba_salir_en_precarga.gd y pruebas/herramientas/salir_en_precarga.gd lo reproducen). Es el mismo error que
# dejó prueba_musica_titulo en la batería 2026-11-19_063148 y lo más probable es que fuera esto, pero no está comprobado:
# esa prueba sola sale hacia el archivo ~430 de 1018 y ciudad_oakhaven.tscn es el 650. Para cerrarlo, al salir con la
# carga a medias se apunta por dónde iba (la línea «Carga: se sale con la precarga a medias», en el .log de la prueba).
# En el juego normal la escena solo se va con la carga acabada (en_curso vacío): esto no hace nada.
func _exit_tree() -> void:
	if fase == "archivos" and total > 0:
		print("Carga: se sale con la precarga a medias (%d de %d archivos hechos, en curso %s, a los %.1f s)"
			% [hechos, total, en_curso, tiempo])
	if en_curso.is_empty():
		return
	var listos: Dictionary = Recursos.esperar_en_hilo(en_curso)
	for ruta in listos:
		Recursos.guardar(ruta, listos[ruta])
	en_curso.clear()


func _fallo(ruta: String) -> void:
	push_warning("Carga: no se pudo cargar %s (se sigue con el resto)" % ruta)
	fallos += 1
	hechos += 1


# Kael y Lya en 3D y cada efecto de vfx/ en una ventana 3D que no se ve; la hierba y el agua de las
# zonas en una ventana 2D que tampoco se ve.
# V12 (12/11, cargas): los personajes y los efectos se dibujan en LOS MISMOS estudios que usa el combate
# (combate.gd estudio_3d y estudio_vfx: ventana transparente con su entorno, luz dorada y relleno). Antes iban todos en una
# ventana con una sola luz y sin entorno: los sombreadores salían con otras variantes y el primer combate los volvía a
# compilar (en el PC, 9 programas nuevos al entrar en el de Bramavidrio; en el Mali-G57, cada uno es un parón).
# Pequeños (la cuarta parte): el tamaño no cambia lo que se compila.
func _preparar_shaders() -> void:
	vista_3d = Node.new()
	add_child(vista_3d)
	var C = load("res://combate.gd")
	var combate_c: Dictionary = C.get_script_constant_map()
	var movil: bool = OS.has_feature("mobile") or "movil" in OS.get_cmdline_user_args()
	for k in ["kael3d", "nyx3d", "garon3d", "grimfang"]:
		var m: Dictionary = combate_c["MODELOS"][k]
		if C._ruta_3d(m) == "":
			continue
		var est: Dictionary = C.estudio_3d(vista_3d, m, 0.25, Color(1.0, 0.8, 0.6))
		est["vp"].render_target_update_mode = SubViewport.UPDATE_ALWAYS
		est["vp"].add_child(C.modelo_3d(m))
	for ruta in Recursos.listar("res://vfx/"):
		if ruta.get_extension() == "tscn":
			var est: Dictionary = C.estudio_vfx(vista_3d, 0.25, true)
			var ef: Node = load(ruta).instantiate()
			C.brillo_vfx(est["env"], ef, movil)
			est["vp"].add_child(ef)

	# V12 (15/11): la muestra gráfica de la calle (solo Auditoría/editor, la escena del banco): sus programas se compilan
	# aquí y no al entrar (zonas3d/muestra_calle/muestra_calle.gd, precalentar_en).
	_u_shaders = Time.get_ticks_usec()
	if load("res://banco_pruebas.gd").permitido() and ResourceLoader.exists("res://zonas3d/muestra_calle/muestra_calle.gd") 			and not "sin_precalentar_muestra" in OS.get_cmdline_user_args():   # (medida A/B: sin él)
		var u0 := Time.get_ticks_usec()
		var vp_muestra = load("res://zonas3d/muestra_calle/muestra_calle.gd").precalentar_en(vista_3d)
		if vp_muestra != null:
			print("[carga] muestra de la calle a precalentar (montada en %.0f ms)" % ((Time.get_ticks_usec() - u0) / 1000.0))
			# V12 (16/11): el barrio experimental de Oakhaven (también solo en el banco) usa los programas de la muestra; lo
			# que añade (los vecinos y Avena) se monta en el mismo SubViewport (zonas3d/barrio/barrio.gd, precalentar_en).
			if ResourceLoader.exists("res://zonas3d/barrio/barrio.gd") and not "sin_precalentar_barrio" in OS.get_cmdline_user_args():
				var u1 := Time.get_ticks_usec()
				var piezas_barrio: int = load("res://zonas3d/barrio/barrio.gd").precalentar_en(vp_muestra)
				print("[carga] barrio de Oakhaven a precalentar: %d modelos (montados en %.0f ms)" % [piezas_barrio,
					(Time.get_ticks_usec() - u1) / 1000.0])

	vista_2d = SubViewport.new()
	vista_2d.size = Vector2i(256, 256)
	vista_2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vista_2d)
	zona_tmp = load("res://zona.gd").new()
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(120, 120)
	var mm := MultiMesh.new()                       # igual que la hierba de zona.gd
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = zona_tmp.malla_hierba()
	mm.instance_count = 1
	mm.set_instance_transform_2d(0, Transform2D.IDENTITY)
	mm.set_instance_color(0, Color.WHITE)
	mm.set_instance_custom_data(0, Color(0, 0, 0, 0))
	var hierba := MultiMeshInstance2D.new()
	hierba.multimesh = mm
	hierba.material = zona_tmp.material_hierba()
	hierba.texture = zona_tmp.matas_tex
	hierba.position = Vector2(60, 200)
	vista_2d.add_child(hierba)
	var agua := MeshInstance2D.new()
	agua.mesh = cuadro
	var ma := ShaderMaterial.new()
	ma.shader = Shader.new()
	ma.shader.code = zona_tmp.SHADER_AGUA
	agua.material = ma
	agua.position = Vector2(190, 120)
	vista_2d.add_child(agua)
	var viento := Sprite2D.new()
	viento.texture = PlaceholderTexture2D.new()
	var mv := ShaderMaterial.new()
	mv.shader = Shader.new()
	mv.shader.code = zona_tmp.SHADER_VIENTO
	viento.material = mv
	viento.position = Vector2(60, 60)
	vista_2d.add_child(viento)


var _u_shaders := 0


# Medida (15/11, «-- medir_carga»): la memoria al acabar la carga y salir (pruebas del precalentado). Sin el argumento, nada.
func _medir_y_salir() -> void:
	if not "medir_carga" in OS.get_cmdline_user_args():
		return
	print("[carga] memoria: estática %.1f MB · vídeo %.1f MB · texturas %.1f MB" % [
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])
	get_tree().quit.call_deferred()


func _paso_shaders() -> void:
	frames_shader += 1
	if frames_shader < FRAMES_SHADERS:
		return
	print("[carga] fase de sombreadores: %.0f ms" % ((Time.get_ticks_usec() - _u_shaders) / 1000.0))
	vista_3d.queue_free()
	vista_2d.queue_free()
	fase = "dialogos"
	# una tarea por fotograma: atlas de cada estilo, objetos dibujados y matas. V12 (12/11, cargas): solo las que faltan en
	# user://cache_zonas. Antes se leían también las que ya estaban, para nada (zona.gd las lee al entrar en cada zona):
	# 0,6 s en el PC en cada arranque.
	for s in zona_tmp.ESTILOS:
		tareas_zona.append(_cache_atlas.bind(s))
	for tipo in zona_tmp.OBJETOS:
		if _falta_cache("obj_" + tipo):
			tareas_zona.append(func(): zona_tmp._cargar_cache("obj_" + tipo, zona_tmp._dibujar_objeto.bind(tipo)))
	if not ResourceLoader.exists(zona_tmp.TEXTURA_HIERBA) and _falta_cache("matas"):
		tareas_zona.append(func(): zona_tmp._cargar_cache("matas", zona_tmp._dibujar_matas))
	tareas_total = maxi(1, tareas_zona.size())


# Sin esto, en el PC abrir el primer diálogo tardaba unos 185 ms y cada uno de los siguientes unos 55 ms, porque Dialogic
# rehacía su interfaz en cada diálogo (pruebas/medir_primeras_veces.gd, 2026-11-08). Ahora se hace aquí una vez y, al
# acabar cada diálogo, se oculta en vez de borrarse («dialogic/layout/end_behaviour» = 1 en project.godot).
func _paso_dialogos() -> void:
	var us: int = Recursos.precalentar_dialogos()
	print("Carga: interfaz de los diálogos preparada en %.1f ms" % (us / 1000.0))
	BotonDialogo.estilar.call_deferred()           # tras añadirse la interfaz al árbol (también diferido)
	fase = "zonas"


func _cache_atlas(s: String) -> void:
	zona_tmp.nombre_estilo = s
	zona_tmp.estilo = zona_tmp.ESTILOS[s]
	zona_tmp.es_ciudad = s == "ciudad"
	var nombre: String = "atlas_" + s + zona_tmp._firma_texturas()
	if _falta_cache(nombre):
		zona_tmp._cargar_cache(nombre, zona_tmp._crear_atlas)


# La misma ruta que zona.gd _cargar_cache.
func _falta_cache(nombre: String) -> bool:
	return not FileAccess.file_exists("user://cache_zonas/%s_v%d.png" % [nombre, zona_tmp.VERSION_CACHE])


func _paso_zonas() -> void:
	if not tareas_zona.is_empty():
		var tarea: Callable = tareas_zona.pop_front()
		tarea.call()
		return
	zona_tmp.free()
	zona_tmp = null
	fase = "fin"
	progreso = 1.0


# ================================================================= empezar

# Qué se pulsa para empezar, según con qué se juega ahora (entrada.gd).
func _texto_empezar(modo: String) -> void:
	toca.text = {"teclado": "PULSA INTRO PARA EMPEZAR", "mando": "PULSA A PARA EMPEZAR"}.get(modo, "TOCA PARA EMPEZAR")


func _input(ev: InputEvent) -> void:
	if not listo or saliendo:
		return
	var botones: Array = [boton_prueba, boton_prologo, boton_banco].filter(func(b): return b != null and b.visible)
	if not botones.is_empty() and (ev is InputEventMouseButton or ev is InputEventScreenTouch):
		for b in botones:
			if b.get_global_rect().has_point(ev.position):
				return                               # el toque es para ese botón de prueba
	if not botones.is_empty() and not (ev is InputEventMouse or ev is InputEventScreenTouch):
		for b in botones:
			if not b.has_focus():
				continue                             # teclado o mando con el foco en un botón de prueba:
			if ev.is_action_pressed("ui_right") and b == boton_prueba and boton_banco in botones:
				boton_banco.grab_focus()                 # V12 (14/11): → desde «Probar la misión» lleva al banco de pruebas
				get_viewport().set_input_as_handled()
			elif (ev.is_action_pressed("ui_left") or ev.is_action_pressed("ui_down")) and b == boton_banco 					and boton_prueba in botones:
				boton_prueba.grab_focus()                # ← o ↓ desde el banco vuelven (↑ sigue soltando el foco)
				get_viewport().set_input_as_handled()
			elif ev.is_action_pressed("ui_up") or ev.is_action_pressed("ui_cancel"):
				b.release_focus()
				get_viewport().set_input_as_handled()
			elif ev.is_action_pressed("ui_left") and b == boton_prueba and boton_prologo in botones:
				boton_prologo.grab_focus()
				get_viewport().set_input_as_handled()
			elif ev.is_action_pressed("ui_right") and b == boton_prologo and boton_prueba in botones:
				boton_prueba.grab_focus()
				get_viewport().set_input_as_handled()
			return                                   # Intro / A los recibe el botón (una sola acción)
		# sin foco: ↓ y → eligen el de la derecha (como siempre); ← el de la izquierda
		var elegido: Button = null
		if ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_right"):
			elegido = boton_prueba if boton_prueba in botones else botones[0]
		elif ev.is_action_pressed("ui_left"):
			elegido = boton_prologo if boton_prologo in botones else botones[0]
		if elegido != null:
			elegido.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed) \
			or ev.is_action_pressed("ui_accept"):
		_empezar()


# «prueba»: las opciones de desarrollo, con la partida en su propia ranura. Sin «prologo», la misión empieza desde
# cero y se entra directamente en Pastos Verdes 3D, sin el prólogo 2D del mapa. Con «prologo», es una partida nueva
# que empieza en el mapa con el prólogo, como la de verdad (T-081).
func _empezar(prueba := false, prologo := false) -> void:
	if saliendo:
		return
	saliendo = true
	for b in [boton_prueba, boton_prologo, boton_banco]:
		if b != null:
			b.visible = false
	if prueba:
		var P = load("res://progreso.gd")
		P.empezar_ranura_prueba()
		P.cargar()                                   # ranura vacía: partida nueva (Kael solo)
		if not prologo:
			Engine.set_meta("prologo_visto", true)
		Recursos.marcar_partida_prueba()
	reproductor.stream = sonidos["confirmar"]
	reproductor.play()
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0)
	negro.size = Vector2(1280, 720)
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	capa.add_child(negro)
	var t := create_tween()
	t.tween_property(negro, "color:a", 1.0, 0.6)
	await t.finished
	if prueba:
		Recursos.cambiar_escena(SIGUIENTE if prologo else load("res://modo3d.gd").escena_de(10))
		return
	var guardada: String = load("res://progreso.gd").cargar()   # si hay partida, se vuelve donde estabas
	Recursos.cambiar_escena(guardada if guardada != "" else SIGUIENTE)


# V12 (14/11): entra en el banco de pruebas de Auditoría. No carga la partida de siempre: el banco usa la suya.
func _abrir_banco() -> void:
	if saliendo:
		return
	saliendo = true
	for b in [boton_prueba, boton_prologo, boton_banco]:
		if b != null:
			b.visible = false
	reproductor.stream = sonidos["confirmar"]
	reproductor.play()
	Recursos.cambiar_escena("res://banco_pruebas.tscn")
