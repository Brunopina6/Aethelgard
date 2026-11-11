extends SceneTree
# Brillo de las regiones 3D en cada perfil de calidad (V12, 11/11): el hallazgo de gráficos (en Compatibility, con la
# sombra del sol, la luz ambiente y la bruma suman más que sin ella) hacía que el perfil bajo se viera más oscuro.
# Carga cada región en bajo, medio y alto, espera a que se asiente, guarda una captura y mide la luminancia media
# (Rec. 709, 0-1) de la imagen del 3D y la de sus partes iluminadas por el sol y en sombra (por cuartiles).
# 12/11 (gráficos, perfil bajo lavado en el Redmi): también el punto negro (percentil 5 de la luminancia: si sube, la
# imagen se ve velada) y la saturación media (HSV: si baja, lavada), y varias posiciones en una pasada
# (pos=x,z/x,z/...; solo el Mar de Cristal).
# Anota también las llamadas de dibujo y las primitivas del fotograma (medida del PC: no vale para el Redmi).
# Con «sin_compensar» desactiva la compensación de vista3d.gd (Engine «luz_sin_compensar») para medir el antes.
# Necesita ventana. Uso (con datos aislados):
#   Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/medir_luz_perfiles.gd -- salida=<carpeta> [sin_compensar] [regiones=a,b] [pos=x,z/x,z]

const REGIONES := {"mar_cristal": "res://zonas3d/mar_cristal_3d.tscn", "pastos": "res://zonas3d/pastos_verdes_3d.tscn",
	"garganta": "res://zonas3d/garganta_3d.tscn", "oakhaven": "res://zonas3d/oakhaven_3d.tscn"}
const PERFILES := ["bajo", "medio", "alto"]
const ESPERA := 7000                       # ms reales tras cargar (la primera escena compila sombreadores)

var salida := ""
var lista: Array = []
var i := 0
var t0 := 0
var cargando := false
var filas: Array = []
var perfiles: Array = PERFILES.duplicate()
var posiciones: Array = [Vector3.INF]
var variantes: Array = [{}]


func _initialize() -> void:
	var regiones: Array = REGIONES.keys()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a == "sin_compensar":
			Engine.set_meta("luz_sin_compensar", true)
		elif a == "luz_antes":                            # el Mar de Cristal con la luz sin sombras de antes del 12/11
			Engine.set_meta("mc_luz_antes", true)
		elif a.begins_with("extra="):                      # extra=escala_3d:1.0,sombras:false (calidad_extra)
			var ex := {}
			for par in a.substr(6).split(","):
				var kv := par.split(":")
				ex[kv[0]] = (kv[1] == "true") if kv[1] in ["true", "false"] else float(kv[1])
			Engine.set_meta("calidad_extra", ex)
		elif a.begins_with("pos="):                        # pos=x,z[/x,z...]: dónde poner a Kael (solo el Mar de Cristal, lugar 4)
			posiciones = []
			for par in a.substr(4).split("/"):
				var xz := par.split(",")
				posiciones.append(Vector3(float(xz[0]), 0.0, float(xz[1])))
		elif a.begins_with("luz="):                        # luz=sol:2,brillo:1+niebla:0.003: variantes de la luz sin sombras del Mar de Cristal (Engine «mc_luz_prueba»)
			variantes = []
			for txt in a.substr(4).split("+"):
				var ex := {}
				for par in txt.split(","):
					var kv := par.split(":")
					ex[kv[0]] = float(kv[1])
				variantes.append(ex)
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("regiones="):
			regiones = Array(a.substr(9).split(","))
	if salida == "":
		salida = OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(salida)
	for r in regiones:
		for pk in posiciones:
			for p in perfiles:
				for k in variantes.size():
					lista.append([r, p, pk, variantes[k], "" if variantes.size() == 1 and variantes[k].is_empty() else "_v%d" % k])
	var P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("incienso", 100000)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)


var _gpu: Array = []
var _cpu: Array = []


func _process(_d: float) -> bool:
	if i >= lista.size():
		_escribir()
		quit(0)
		return true
	var pos_kael: Vector3 = lista[i][2]
	if not cargando:
		Engine.set_meta("calidad_proto", lista[i][1])
		if lista[i][3].is_empty():
			if Engine.has_meta("mc_luz_prueba"):
				Engine.remove_meta("mc_luz_prueba")
		else:
			Engine.set_meta("mc_luz_prueba", lista[i][3])
		Engine.set_meta("pos_3d_ok", pos_kael != Vector3.INF)
		if pos_kael != Vector3.INF:
			Engine.set_meta("pos_3d", pos_kael)
			Engine.set_meta("pos_3d_lugar", 4)
		change_scene_to_file(REGIONES[lista[i][0]])
		cargando = true
		t0 = Time.get_ticks_msec()
		return false
	if Time.get_ticks_msec() - t0 < ESPERA:
		if Time.get_ticks_msec() - t0 > ESPERA - 1500:            # el último segundo y medio: tiempo de GPU y de CPU del dibujo
			_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
			_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		return false
	var gpu := _media(_gpu)
	var cpu := _media(_cpu)
	_gpu.clear()
	_cpu.clear()
	var img := root.get_texture().get_image()
	var nombre := "%s_%s%s%s%s.png" % [lista[i][0], lista[i][1], lista[i][4], "_antes" if Engine.has_meta("luz_sin_compensar") else "", "" if pos_kael == Vector3.INF else "_%d_%d" % [pos_kael.x, pos_kael.z]]
	img.save_png(salida.path_join(nombre))
	var m := _medir(img)
	var llamadas := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var sitio: String = ("inicio" if pos_kael == Vector3.INF else "%d,%d" % [pos_kael.x, pos_kael.z]) + lista[i][4]
	filas.append([lista[i][0], lista[i][1], sitio, m[0], m[1], m[2], m[3], m[4], llamadas, prims, gpu, cpu])
	print("%-12s %-6s %-7s media %.3f · luz %.3f · sombra %.3f · negro %.3f · saturación %.3f · %d llamadas · %d primitivas · GPU %.2f ms · CPU %.2f ms" % [lista[i][0], lista[i][1], sitio, m[0], m[1], m[2], m[3], m[4], llamadas, prims, gpu, cpu])
	cargando = false
	i += 1
	return false


# Media, cuartil alto (lo iluminado), cuartil bajo (la sombra), percentil 5 (punto negro) de la luminancia y saturación
# media (HSV), en una rejilla de 1 de cada 4 píxeles sin la franja de arriba (títulos e interfaz).
func _medir(img: Image) -> Array:
	var v: Array = []
	var sat := 0.0
	for y in range(int(img.get_height() * 0.18), img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			v.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
			sat += c.s
	v.sort()
	var n := v.size()
	var suma := 0.0
	for k in v:
		suma += k
	var alto := 0.0
	for k in range(int(n * 0.75), n):
		alto += v[k]
	var bajo := 0.0
	for k in range(0, int(n * 0.25)):
		bajo += v[k]
	return [suma / n, alto / (n - int(n * 0.75)), bajo / int(n * 0.25), v[int(n * 0.05)], sat / n]


func _escribir() -> void:
	var f := FileAccess.open(salida.path_join("luz_perfiles%s.csv" % ("_antes" if Engine.has_meta("luz_sin_compensar") else "")), FileAccess.WRITE)
	f.store_line("region;perfil;sitio;media;luz;sombra;negro;saturacion;llamadas;primitivas;gpu_ms;cpu_ms")
	for r in filas:
		f.store_line("%s;%s;%s;%.4f;%.4f;%.4f;%.4f;%.4f;%d;%d;%.2f;%.2f" % r)
	f.close()


func _media(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for x in a:
		s += float(x)
	return s / a.size()
