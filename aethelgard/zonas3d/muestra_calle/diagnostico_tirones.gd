extends Node
# Diagnóstico de los TIRONES de la muestra de la calle (15/11, encargo del usuario tras el Redmi: «investiga sus causas
# antes de atribuirlos a sombreados o texturas»). SOLO MIDE: no cambia nada de lo que se ve. Escribe en la consola
# (logcat «godot», líneas «[tirones]»):
#   - en cada entrada: cuánto tarda cada fase del _ready (marcas) y los 4 primeros fotogramas dibujados;
#   - después, cada fotograma de más de UMBRAL ms con su reparto, medido EN ESE fotograma con marcas propias (los
#     monitores TIME_PROCESS/TIME_PHYSICS del motor solo se publican una vez por segundo y no sirven para un tirón):
#       espera  = del final del dibujo anterior al primer paso del fotograma (límite de FPS, sincronía, el sistema),
#       física  = de SceneTree.physics_frame a process_frame (si hubo paso de física),
#       proceso = de process_frame a frame_pre_draw (GDScript, animaciones, sonido, lo que no es dibujar),
#       dibujo  = de frame_pre_draw a frame_post_draw (RenderingServer: compilar/enlazar programas, subir datos, dibujar);
#     y qué pasaba: Kael (sitio, animación, espera), la luz, memoria de vídeo/texturas/búferes, escala 3D y regulador;
#   - el número de archivos de user://shader_cache al entrar, tras los primeros fotogramas y al salir: si crece, el
#     driver compiló programas nuevos (primera vez tras instalar) en ese tramo.
# Se quita con la meta «muestra_sin_diagnostico». Umbral en el PC: argumento «umbral_tirones=<ms>».

static var entradas := 0                        # 1 = la primera entrada a la muestra tras abrir la app
var umbral := 50.0
var m                                           # muestra_calle.gd
var u_init := 0
var marcas: PackedStringArray = []
var _u_marca := 0
var _u_pre := 0
var _u_post := 0
var _n := 0
var _cache := -1
var _u_fis := 0                                 # el primer physics_frame tras el dibujo anterior (0 = no hubo)
var _u_proc := 0
var _ms_cache_entrada := 0.0


func empezar(muestra: Node, u0: int) -> void:
	m = muestra
	u_init = u0
	_u_marca = u0
	entradas += 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("umbral_tirones="):
			umbral = float(a.trim_prefix("umbral_tirones="))
	RenderingServer.frame_pre_draw.connect(_pre)
	RenderingServer.frame_post_draw.connect(_post)
	get_tree().physics_frame.connect(_fis)
	get_tree().process_frame.connect(_proc)
	marca("instanciar→_ready")
	var uc := Time.get_ticks_usec()
	_contar_cache("entrada %d, antes del primer dibujo" % entradas)
	_ms_cache_entrada = (Time.get_ticks_usec() - uc) / 1000.0
	marca("contar caché (instrumentación)")


func marca(n: String) -> void:
	var u := Time.get_ticks_usec()
	marcas.append("%s %.1f" % [n, (u - _u_marca) / 1000.0])
	_u_marca = u


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_pre):
		RenderingServer.frame_pre_draw.disconnect(_pre)
	if RenderingServer.frame_post_draw.is_connected(_post):
		RenderingServer.frame_post_draw.disconnect(_post)
	# (las de SceneTree se desconectan solas al liberarse el nodo)
	_contar_cache("al salir (entrada %d)" % entradas)


func _fis() -> void:
	if _u_fis == 0:
		_u_fis = Time.get_ticks_usec()


func _proc() -> void:
	_u_proc = Time.get_ticks_usec()


func _pre() -> void:
	_u_pre = Time.get_ticks_usec()


func _post() -> void:
	var u := Time.get_ticks_usec()
	var antes := _u_post if _u_post > 0 else u_init
	var cuadro := (u - antes) / 1000.0
	var dibujo := (u - _u_pre) / 1000.0 if _u_pre > antes else -1.0
	var inicio := mini(_u_fis, _u_proc) if _u_fis > antes else _u_proc
	var espera := (inicio - antes) / 1000.0 if inicio > antes else 0.0
	var fis := (_u_proc - _u_fis) / 1000.0 if _u_fis > antes and _u_proc > _u_fis else 0.0
	var proc := (_u_pre - _u_proc) / 1000.0 if _u_proc > antes and _u_pre > _u_proc else 0.0
	_u_post = u
	_u_fis = 0
	_n += 1
	if _n == 1:
		print("[tirones] entrada %d · instanciar→1.er dibujo %.1f ms (%.1f sin el recuento de la caché; dibujo %.1f) · fases ms: %s" % [
			entradas, cuadro, cuadro - _ms_cache_entrada, dibujo, " · ".join(marcas)])
	elif _n <= 4:
		print("[tirones] entrada %d · dibujo %d: %.1f ms (espera %.1f · física %.1f · proceso %.1f · dibujo %.1f)" % [
			entradas, _n, cuadro, espera, fis, proc, dibujo])
	if _n == 4:
		_contar_cache("entrada %d, tras los primeros dibujos" % entradas)
		_u_post = Time.get_ticks_usec()             # (el recuento no cuenta como tirón del fotograma siguiente)
	if _n <= 4 or cuadro < umbral or m == null or not is_instance_valid(m):
		return
	var k: Node3D = m.kael
	var p := k.global_position if k != null else Vector3.ZERO
	var ap: AnimationPlayer = k.get("anim") if k != null else null
	var esp = k.get("esperas") if k != null else null
	var reg = m.get("regulador")
	print("[tirones] e%d t=%.2f s · %.0f ms: espera %.1f · física %.1f · proceso %.1f · dibujo %.1f · Kael (%.1f, %.2f, %.1f) «%s» ×%.2f espera «%s» · sol %.2f · %d obj · %d llamadas · %dk prim · vídeo %.1f tex %.1f búfer %.1f MB · nodos %d · escala3D %.2f · regulador %s" % [
		entradas, (u - u_init) / 1e6, cuadro, espera, fis, proc, dibujo, p.x, p.y, p.z,
		String(ap.current_animation) if ap != null else "", ap.speed_scale if ap != null else 0.0,
		str(esp.get("actual")) if esp != null else "", float(m.get("_sol_k")),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), get_viewport().scaling_3d_scale,
		("escalón %d" % reg.nivel) if reg != null else "-"])


# Archivos de user://shader_cache: si crece, el driver compiló programas nuevos. Se cuenta en el hilo principal: al
# entrar (tapado; su tiempo sale aparte), tras el 4.º dibujo (con el fundido de Recursos aún a medias; el reloj del
# fotograma siguiente se reinicia para no contarlo como tirón) y al salir.
func _contar_cache(cuando: String) -> void:
	var n := _archivos("user://shader_cache")
	print("[tirones] caché de sombreadores %s: %d archivos%s" % [cuando, n, (" (+%d)" % (n - _cache)) if _cache >= 0 else ""])
	_cache = n


static func _archivos(dir: String) -> int:
	var d := DirAccess.open(dir)
	if d == null:
		return 0
	var n := d.get_files().size()
	for s in d.get_directories():
		n += _archivos(dir.path_join(s))
	return n
