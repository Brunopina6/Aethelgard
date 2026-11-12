extends SceneTree
# Medida de las cargas de REBELUM (V12, 12/11, encargo «eliminar las esperas sin información»). Mide, en una sola
# pasada y de forma repetible, lo que tarda cada espera y cuánta memoria deja:
#   1. arranque     de la escena principal (carga.tscn → la portada) a «TOCA PARA EMPEZAR», por fases de carga.gd
#                   (archivos, shaders, diálogos, zonas);
#   2. continuar    «Continuar» (portada._empezar) con una partida guardada en el Mar de Cristal, hasta ver la región;
#   3. brama_1      del aviso de Bramavidrio (la arena tiembla) al primer fotograma del combate, LA PRIMERA VEZ;
#   4. vuelta       ganar el combate (enemigos a 0 PV y _comprobar_fin, como al ganar) y volver a la región;
#   5. brama_2      el mismo combate otra vez (se olvida que se ganó), para ver la segunda entrada;
#   6. normal_k     k combates al azar desde la región (encuentro) y su vuelta.
# En cada espera: cuándo se pone negro (Recursos.cambiando), cuándo entra la escena nueva en el árbol, cuánto tarda su
# _ready (y, en el combate, cada parte: combate.gd «tiempos_carga»), el primer fotograma, cuándo deja de verse negro y los
# fotogramas largos de los 3 s siguientes (sombreadores que se compilan al dibujarse por primera vez). Memoria al acabar
# cada caso: estática, de vídeo, texturas, objetos, recursos, nodos huérfanos y el conjunto de trabajo del proceso.
#
# CON VENTANA (sin ella no se compila ningún sombreador de verdad) y SIEMPRE CON DATOS AISLADOS: se niega a empezar si
# user:// es la carpeta real del juego. La partida que usa es «user://medir_cargas.save» (archivo_partida_prueba).
# Uso (PowerShell, con APPDATA, LOCALAPPDATA, TEMP y TMP desviados a una carpeta temporal):
#   Godot_console.exe --path aethelgard --resolution 1280x720 -s res://pruebas/herramientas/medir_cargas.gd
#       -- 3d mardecristal [perfil=medio] [bramavidrio_version=2] [combates=3] [salida=D:/ruta/medidas.json] [etiqueta=x]
# perfil: la calidad (prototipos/calidad_proto.gd), «medio» por defecto (el del Redmi en combate).

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const COMBATE := "res://combate.tscn"
const PARTIDA := "user://medir_cargas.save"
const ASENTAR := 3.0                     # s que se miden los fotogramas tras ver la escena nueva
const LARGO_MS := 50.0                   # un fotograma «largo» (a 30 FPS dura 33 ms)

var R                                    # Recursos
var P                                    # progreso.gd
var args := PackedStringArray()
var resultados: Array = []
var med: Dictionary = {}                 # la medida en curso
var fase := ""
var t_fase := 0
var t_prev := 0
var t_inicio := 0
var v: Node                              # la región
var c: Node                              # el combate
var combates := 3
var normales := 0
var fallos := 0
var _fase_carga := ""


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if not _aislado():
		printerr("medir_cargas: user:// es la carpeta REAL del juego (%s). Desvía APPDATA antes de medir." % OS.get_user_data_dir())
		quit(255)
		return
	R = root.get_node("Recursos")
	P = load("res://progreso.gd")
	var perfil := "medio"
	for a in args:
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("combates="):
			combates = int(a.substr(9))
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("archivo_partida_prueba", PARTIDA)
	# La partida: en el Mar de Cristal, en la entrada, sin encuentros al azar (el incienso) para que el paseo no dependa
	# de la suerte. Se escribe en la carpeta aislada.
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("incienso", 100000)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("prologo_visto", true)
	P.escribir(P.volcar(REGION), PARTIDA)
	for k in P.CLAVES:                     # «Continuar» la lee de nuevo, como al abrir el juego
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	root.child_entered_tree.connect(_al_entrar)
	RenderingServer.frame_post_draw.connect(_al_dibujar)
	t_inicio = Time.get_ticks_usec()
	t_prev = t_inicio
	print("medir_cargas: motor listo a los %d ms; perfil %s; user:// = %s" % [Time.get_ticks_msec(), perfil, OS.get_user_data_dir()])
	_nueva("arranque")
	med["motor_ms"] = Time.get_ticks_msec()
	change_scene_to_file("res://carga.tscn")
	_fase("arranque")


func _aislado() -> bool:
	var real := OS.get_environment("USERPROFILE").replace("\\", "/").path_join("AppData/Roaming/Godot/app_userdata")
	var usr := OS.get_user_data_dir().replace("\\", "/")
	return OS.get_environment("USERPROFILE") != "" and not usr.to_lower().begins_with(real.to_lower())


func _ms() -> float:
	return (Time.get_ticks_usec() - int(med.get("_t0", t_inicio))) / 1000.0


func _nueva(nombre: String) -> void:
	med = {"caso": nombre, "_t0": Time.get_ticks_usec(), "fotogramas": [], "_negro": [], "_cache0": _cache()}


func _cerrar() -> void:
	var f: Array = med.get("fotogramas", [])
	var largos := f.filter(func(x): return x > LARGO_MS)
	med["max_ms"] = f.max() if not f.is_empty() else 0.0
	med["n_largos"] = largos.size()
	med["exceso_ms"] = largos.reduce(func(s, x): return s + x - 33.3, 0.0)
	var fn: Array = med.get("_negro", [])
	med["max_negro_ms"] = fn.max() if not fn.is_empty() else 0.0   # el fotograma más largo con la pantalla tapada
	var c1 := _cache()
	med["sombreadores_nuevos"] = c1[0] - med["_cache0"][0]          # programas compilados por primera vez (caché de Godot)
	med["sombreadores_mb"] = snappedf((c1[1] - med["_cache0"][1]) / 1048576.0, 0.1)
	med.erase("_cache0")
	med.erase("_negro")
	med.erase("_foto")
	med.erase("fotogramas")
	med.erase("_t0")
	med["memoria"] = _memoria()
	resultados.append(med)
	print("  %s" % _resumen(med))


func _fase(n: String) -> void:
	fase = n
	t_fase = Time.get_ticks_usec()


func _en(s: float) -> bool:
	return (Time.get_ticks_usec() - t_fase) / 1e6 >= s


func _al_entrar(n: Node) -> void:
	if n.scene_file_path == "" or med.is_empty() or med.has("entra_ms"):
		return
	med["entra_ms"] = _ms()
	med["escena"] = n.scene_file_path
	n.ready.connect(func(): med["ready_ms"] = _ms(), CONNECT_ONE_SHOT)


func _al_dibujar() -> void:
	if med.has("ready_ms") and not med.has("dibujo_ms"):
		med["dibujo_ms"] = _ms()


func _process(_d: float) -> bool:
	var ahora := Time.get_ticks_usec()
	var dt := (ahora - t_prev) / 1000.0
	t_prev = ahora
	if med.has("visible_ms") and med.has("fotogramas"):
		med["fotogramas"].append(dt)
	if med.has("negro_ms") and not med.has("visible_ms") and med.has("_negro"):
		med["_negro"].append(dt)
		if not med.has("_foto") and med.has("entra_ms"):   # «fotos=<carpeta>»: lo que se ve mientras se monta la escena
			med["_foto"] = true
			for a in args:
				if a.begins_with("fotos="):
					DirAccess.make_dir_recursive_absolute(a.substr(6))
					root.get_texture().get_image().save_png(a.substr(6).path_join("%s.png" % med["caso"]))
	if R.cambiando and not med.has("negro_ms") and not med.is_empty():
		med["negro_ms"] = _ms()
	if med.has("ready_ms") and not med.has("aclara_ms") and R.negro.visible and R.negro.color.a < 0.99:
		med["aclara_ms"] = _ms()                        # empieza a verse la escena nueva (Recursos funde de negro)
	if med.has("ready_ms") and not med.has("visible_ms") and not R.cambiando:
		med["visible_ms"] = _ms()
	if (Time.get_ticks_usec() - t_inicio) / 1e6 > 600.0:
		printerr("medir_cargas: más de 10 minutos; se corta en la fase «%s»" % fase)
		return _terminar()
	match fase:
		"arranque":
			var e := current_scene
			if e == null or not "fase" in e:
				return false
			if e.fase != _fase_carga:
				med["fase_" + e.fase + "_ms"] = _ms()
				_fase_carga = e.fase
			if e.listo:
				med["listo_ms"] = _ms()
				med["archivos"] = e.hechos
				med["fallos_archivo"] = e.fallos
				med["escena"] = e.scene_file_path
				med["carga_s"] = e.tiempo
				med["visible_ms"] = _ms()
				_fase("arranque2")
		"arranque2":
			if _en(ASENTAR):
				_cerrar()
				if "solo=arranque" in args:
					return _terminar()
				_nueva("continuar")
				current_scene._empezar()                # «Continuar» / «toca para empezar»: la partida guardada
				_fase("continuar")
		"continuar", "vuelta":
			if med.has("visible_ms") and current_scene != null and current_scene.scene_file_path == REGION \
					and (Time.get_ticks_usec() - int(med["_t0"])) / 1000.0 - float(med["visible_ms"]) >= ASENTAR * 1000.0:
				_cerrar()
				v = current_scene
				_siguiente_combate()
		"brama":
			if v.gusano.estado == "aviso" and not med.has("aviso_ms"):
				med["_t0"] = Time.get_ticks_usec()          # el tiempo cuenta desde el aviso
				med["aviso_ms"] = 0.0
			if v.gusano.estado == "aparicion" and not med.has("aparicion_ms"):
				med["aparicion_ms"] = _ms()
			if v.saliendo and not med.has("encuentro_ms"):
				med["encuentro_ms"] = _ms()
				med["sombreadores_antes_del_combate"] = _cache()[0] - med["_cache0"][0]   # los de la aparición
			if med.has("encuentro_ms"):
				_fase("combate")
			elif _en(40.0):
				printerr("medir_cargas: Bramavidrio no llega a pedir su combate (estado %s)" % v.gusano.estado)
				fallos += 1
				return _terminar()
		"combate":
			if med.has("visible_ms") and current_scene != null and current_scene.scene_file_path == COMBATE \
					and _ms() - float(med["visible_ms"]) >= ASENTAR * 1000.0:
				c = current_scene
				med["partes_ready"] = c.tiempos_carga.duplicate()
				med["enemigos"] = c.enemigos.map(func(x): return str(x["nombre"]))
				_cerrar()
				_fase("ganar")
			elif _en(60.0):
				printerr("medir_cargas: el combate no llega en 60 s")
				fallos += 1
				return _terminar()
		"ganar":
			if c.estado in ["esperando", "menu", "objetivo"] or _en(15.0):
				for e in c.enemigos:
					e["hp"] = 0
				_nueva("vuelta")
				c._comprobar_fin()
				_fase("vuelta")
	return false


# Bramavidrio dos veces (la primera y la repetición) y después «combates» combates al azar.
func _siguiente_combate() -> void:
	var n_brama := resultados.filter(func(x): return str(x["caso"]).begins_with("brama")).size()
	if n_brama < 2:
		var g: Dictionary = Engine.get_meta("combates_ganados", {})
		g.erase("mc_bramavidrio")                       # se olvida que se ganó: vuelve a salir
		Engine.set_meta("combates_ganados", g)
		v.clima.sistemicas = false
		v.gusano.activo = true
		v.gusano._cambiar("calma")
		v._colocar_kael(Vector3(80.0, 0.0, 40.0))       # la arena que tiembla (prueba_mar_cristal.gd)
		v._ultima = v.kael.global_position
		_nueva("brama_%d" % (n_brama + 1))
		_fase("brama")
		return
	if normales < combates:
		normales += 1
		v.gusano.activo = false
		_nueva("normal_%d" % normales)
		v.encuentro()
		_fase("combate")
		return
	_terminar()


func _memoria() -> Dictionary:
	var m := {
		"estatica_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"video_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"texturas_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"recursos": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"en_recursos": R.grupos["comun"].size() + R.grupos["zona"].size(),
	}
	var salida := []
	if OS.get_name() == "Windows" and OS.execute("powershell", ["-NoProfile", "-Command",
			"$p = Get-Process -Id %d; '{0} {1}' -f $p.WorkingSet64, $p.PrivateMemorySize64" % OS.get_process_id()], salida) == 0:
		var partes: PackedStringArray = str(salida[0]).strip_edges().split(" ")
		if partes.size() == 2:
			m["trabajo_mb"] = snappedf(int(partes[0]) / 1048576.0, 1.0)
			m["privada_mb"] = snappedf(int(partes[1]) / 1048576.0, 1.0)
	return m


func _resumen(r: Dictionary) -> String:
	var t := "%-10s" % r["caso"]
	for k in ["fase_shaders_ms", "fase_dialogos_ms", "fase_zonas_ms", "listo_ms", "aparicion_ms", "encuentro_ms",
			"negro_ms", "entra_ms", "ready_ms", "dibujo_ms", "aclara_ms", "visible_ms", "max_negro_ms", "max_ms", "n_largos",
			"sombreadores_antes_del_combate", "sombreadores_nuevos"]:
		if r.has(k):
			t += "  %s=%s" % [k.trim_suffix("_ms"), str(snappedf(float(r[k]), 1.0))]
	var m: Dictionary = r.get("memoria", {})
	t += "  | estática %s MB, vídeo %s MB, trabajo %s MB, privada %s MB, objetos %s, huérfanos %s" % [m.get("estatica_mb"),
		m.get("video_mb"), m.get("trabajo_mb", "?"), m.get("privada_mb", "?"), m.get("objetos"), m.get("huerfanos")]
	if r.has("partes_ready"):
		var p: Dictionary = r["partes_ready"]
		var s := PackedStringArray()
		for k in p:
			s.append("%s %.0f" % [k, p[k]])
		t += "\n             ready: " + ", ".join(s)
	return t


func _terminar() -> bool:
	var salida := ""
	var etiqueta := ""
	for a in args:
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
	var datos := {"etiqueta": etiqueta, "fecha": Time.get_datetime_string_from_system(), "args": Array(args),
		"perfil": Engine.get_meta("calidad_proto", ""), "resultados": resultados, "fallos": fallos}
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida.get_base_dir())
		var f := FileAccess.open(salida, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(datos, "  "))
			f.close()
			print("medir_cargas: medidas en ", salida)
	print("MEDIR_CARGAS: %d casos, %d fallos" % [resultados.size(), fallos])
	for k in P.CLAVES:                                   # nada de la partida queda en Engine al cerrar
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(1 if fallos > 0 else 0)
	return true


# [archivos, bytes] de la caché de sombreadores de Godot (user://shader_cache): cada archivo nuevo es un programa que se
# ha compilado por primera vez. En el PC compilar cuesta milisegundos; en el Mali-G57, mucho más: es la mejor pista de lo
# que se paga allí (y que con la caché llena, la segunda vez, ya no se paga).
func _cache(dir := "user://shader_cache") -> Array:
	var r := [0, 0]
	var d := DirAccess.open(dir)
	if d == null:
		return r
	for f in d.get_files():
		r[0] += 1
		var fa := FileAccess.open(dir.path_join(f), FileAccess.READ)
		if fa != null:
			r[1] += fa.get_length()
	for s in d.get_directories():
		var sub := _cache(dir.path_join(s))
		r[0] += sub[0]
		r[1] += sub[1]
	return r
