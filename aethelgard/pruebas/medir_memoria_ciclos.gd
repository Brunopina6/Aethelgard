extends SceneTree
# V12 (15/11): memoria tras varios recorridos (PC). Cinco vueltas mapa → Oakhaven 3D → Sunken City 3D → Pastos Verdes 3D
# → mapa, con unos segundos en cada sitio; tras cada vuelta, memoria estática, memoria de vídeo, objetos, nodos y
# recursos. Si algo crece vuelta a vuelta, es una fuga. Resultado de PC: no certifica Android (en el Redmi se mide con
# dumpsys meminfo). Uso: lista_pruebas.txt (medir_memoria_ciclos, ventana): «3d sunken3d sin_prologo salida={salida}».

const ARCHIVO := "user://medir_memoria_ciclos.save"
const SITIOS := ["res://mapa.tscn", "res://zonas3d/oakhaven_3d.tscn", "res://zonas3d/sunken_3d.tscn",
	"res://zonas3d/pastos_verdes_3d.tscn"]
const VUELTAS := 5
var salida := ""
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	root.size = Vector2i(1280, 720)
	_medir.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _foto(vuelta: int) -> Dictionary:
	return {"vuelta": vuelta,
		"estatica_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"video_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"recursos": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))}


func _medir() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("partida_lista", true)
	var fotos: Array = []
	for v in VUELTAS:
		for s in SITIOS:
			for k in ["pos_3d", "pos_3d_ok", "pos_3d_lugar"]:
				if Engine.has_meta(k):
					Engine.remove_meta(k)
			change_scene_to_file(s)
			await _frames(150)                         # ~5 s a 30 FPS
		var f := _foto(v + 1)
		fotos.append(f)
		lineas.append(JSON.stringify(f))
		print(JSON.stringify(f))
	var a: Dictionary = fotos[1]                         # (la primera vuelta llena cachés: se compara desde la segunda)
	var b: Dictionary = fotos[VUELTAS - 1]
	var r := "de la vuelta 2 a la %d: estática %+.1f MB, vídeo %+.1f MB, objetos %+d, nodos %+d, recursos %+d" % [VUELTAS,
		b["estatica_mb"] - a["estatica_mb"], b["video_mb"] - a["video_mb"], b["objetos"] - a["objetos"],
		b["nodos"] - a["nodos"], b["recursos"] - a["recursos"]]
	print(r)
	lineas.append(r)
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var fa := FileAccess.open(salida.path_join("memoria_ciclos.txt"), FileAccess.WRITE)
		fa.store_string("\n".join(lineas) + "\n")
		fa.close()
	quit(0)
