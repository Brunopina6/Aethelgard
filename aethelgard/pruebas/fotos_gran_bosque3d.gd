extends SceneTree
# Capturas y medidas del Gran Bosque Verde 3D (V12, migración, 12/11), CON ventana y datos aislados:
#   Godot --path aethelgard --script res://pruebas/fotos_gran_bosque3d.gd -- <carpeta> 3d sin_prologo [perfiles=bajo,medio,alto]
#         [sitios=entrada,puente,...] [res=1280x720]
# En cada perfil (la escena se recarga) y en cada sitio: Kael allí, 45 fotogramas para asentarse, una captura
# (<carpeta>/<perfil>_<sitio>.png) y la media de 40 fotogramas sin tope de FPS (tiempo de CPU del fotograma, llamadas de
# dibujo, primitivas). Escribe <carpeta>/medidas_<fecha>.json y .txt. Las cifras del PC NO valen para el Redmi.

const REGION := "res://zonas3d/gran_bosque_3d.tscn"
const SITIOS := {
	"entrada": Vector2(40.0, 52.0),
	"puente": Vector2(41.6, 33.4),
	"ruinas_armadura": Vector2(47.6, 47.6),
	"campamento": Vector2(20.0, 39.0),
	"claro": Vector2(25.5, 28.6),
	"altar": Vector2(38.2, 8.2),
	"mirador": Vector2(49.4, 15.6),
	"bosque_cerrado": Vector2(33.0, 41.0),
	"armadura": Vector2(46.3, 46.8),
	"hoguera": Vector2(18.8, 39.3),
}

var salida := ""
var perfiles: Array = ["bajo", "medio", "alto"]
var sitios: Array = SITIOS.keys()
var R
var T
var resultados: Array = []
var cerca := false                       # «cerca»: la cámara a 10 m (primeros planos, sin medir)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("sitios="):
			sitios = Array(a.substr(7).split(","))
		elif a == "cerca":
			cerca = true
		elif a.begins_with("res="):
			var wh := a.substr(4).split("x")
			DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
	DirAccess.make_dir_recursive_absolute(salida)
	R = root.get_node("Recursos")
	T = load("res://zonas3d/gran_bosque/trazado.gd")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_gran_bosque3d.save")
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	for pf in perfiles:
		Engine.set_meta("calidad_proto", pf)
		Engine.set_meta("pos_3d_ok", false)
		var t0 := Time.get_ticks_msec()
		change_scene_to_file(REGION)
		var limite := Time.get_ticks_msec() + 120000
		while Time.get_ticks_msec() < limite and (current_scene == null or current_scene.scene_file_path != REGION or current_scene.get("kael") == null or R.cambiando):
			await process_frame
		var carga := Time.get_ticks_msec() - t0
		var v = current_scene
		print("carga %s: %d ms; escenario: %s" % [pf, carga, v.escenario.tiempos])
		print("conteo %s: %s" % [pf, _conteo(v)])
		await _esperar(20)
		v.pasos = -100000
		for s in sitios:
			v.pasos = -100000
			var p: Vector3 = T.en_mundo(SITIOS[s])
			v._colocar_kael(v._sitio_libre(p))
			v._ultima = v.kael.global_position
			if s == "mirador":
				v.inclinacion = v.CAMARA_MIRADOR[0]
				v.distancia = v.CAMARA_MIRADOR[1]
			if cerca:
				v._dist_jugador = 9.0
				v.distancia = 9.0
			v.perfil_fps = 0
			Engine.max_fps = 0
			await _esperar(45)
			var ms: Array = []
			var llamadas := 0.0
			var prim := 0.0
			var u := Time.get_ticks_usec()
			for i in 40:
				await process_frame
				var ahora := Time.get_ticks_usec()
				ms.append((ahora - u) / 1000.0)
				u = ahora
				llamadas += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			ms.sort()
			var img := root.get_viewport().get_texture().get_image()
			img.save_png(salida.path_join("%s_%s.png" % [pf, s]))
			var fila := {"perfil": pf, "sitio": s, "carga_ms": carga, "ms_mediana": ms[ms.size() / 2], "ms_p95": ms[int(ms.size() * 0.95)],
				"llamadas": roundi(llamadas / 40.0), "primitivas": roundi(prim / 40.0),
				"video_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)}
			resultados.append(fila)
			print(fila)
	var f := FileAccess.open(salida.path_join("medidas_%s.json" % Time.get_datetime_string_from_system().replace(":", "")), FileAccess.WRITE)
	f.store_string(JSON.stringify(resultados, "\t"))
	f.close()
	if FileAccess.file_exists("user://fotos_gran_bosque3d.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://fotos_gran_bosque3d.save"))
	quit()


# Triángulos por tipo de MultiMesh y de malla (lo que hay en la escena, no lo que se dibuja).
func _conteo(v) -> Dictionary:
	var c := {}
	for n in v.find_children("*", "GeometryInstance3D", true, false):
		var tris := 0
		var nombre := String(n.name).get_slice("@", 0).rstrip("0123456789")
		if n is MultiMeshInstance3D and n.multimesh != null and n.multimesh.mesh != null:
			tris = n.multimesh.mesh.get_faces().size() / 3 * n.multimesh.instance_count
			nombre += "(%s)" % ("sombra" if n.cast_shadow == 3 else ("con sombra" if n.cast_shadow == 1 else ""))
		elif n is MeshInstance3D and n.mesh != null:
			tris = n.mesh.get_faces().size() / 3
		c[nombre] = int(c.get(nombre, 0)) + tris
	return c
