extends SceneTree
# Brillo de las regiones 3D en cada perfil de calidad (V12, 11/11): el hallazgo de gráficos (en Compatibility, con la
# sombra del sol, la luz ambiente y la bruma suman más que sin ella) hacía que el perfil bajo se viera más oscuro.
# Carga cada región en bajo, medio y alto, espera a que se asiente, guarda una captura y mide la luminancia media
# (Rec. 709, 0-1) de la imagen del 3D y la de sus partes iluminadas por el sol y en sombra (por cuartiles).
# Anota también las llamadas de dibujo y las primitivas del fotograma (medida del PC: no vale para el Redmi).
# Con «sin_compensar» desactiva la compensación de vista3d.gd (Engine «luz_sin_compensar») para medir el antes.
# Necesita ventana. Uso (con datos aislados):
#   Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/medir_luz_perfiles.gd -- salida=<carpeta> [sin_compensar] [regiones=a,b]

const REGIONES := {"mar_cristal": "res://zonas3d/mar_cristal_3d.tscn", "pastos": "res://zonas3d/pastos_verdes_3d.tscn",
	"garganta": "res://zonas3d/garganta_3d.tscn", "oakhaven": "res://zonas3d/oakhaven_3d.tscn"}
const PERFILES := ["bajo", "medio", "alto"]
const ESPERA := 2500                       # ms reales tras cargar

var salida := ""
var lista: Array = []
var i := 0
var t0 := 0
var cargando := false
var filas: Array = []


func _initialize() -> void:
	var regiones: Array = REGIONES.keys()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a == "sin_compensar":
			Engine.set_meta("luz_sin_compensar", true)
		elif a.begins_with("regiones="):
			regiones = Array(a.substr(9).split(","))
	if salida == "":
		salida = OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(salida)
	for r in regiones:
		for p in PERFILES:
			lista.append([r, p])
	var P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("incienso", 100000)


func _process(_d: float) -> bool:
	if i >= lista.size():
		_escribir()
		quit(0)
		return true
	if not cargando:
		Engine.set_meta("calidad_proto", lista[i][1])
		Engine.set_meta("pos_3d_ok", false)
		change_scene_to_file(REGIONES[lista[i][0]])
		cargando = true
		t0 = Time.get_ticks_msec()
		return false
	if Time.get_ticks_msec() - t0 < ESPERA:
		return false
	var img := root.get_texture().get_image()
	var nombre := "%s_%s%s.png" % [lista[i][0], lista[i][1], "_antes" if Engine.has_meta("luz_sin_compensar") else ""]
	img.save_png(salida.path_join(nombre))
	var m := _medir(img)
	var llamadas := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	filas.append([lista[i][0], lista[i][1], m[0], m[1], m[2], llamadas, prims])
	print("%-12s %-6s media %.3f · luz %.3f · sombra %.3f · %d llamadas · %d primitivas" % [lista[i][0], lista[i][1], m[0], m[1], m[2], llamadas, prims])
	cargando = false
	i += 1
	return false


# Media, cuartil alto (lo iluminado) y cuartil bajo (la sombra) de la luminancia, en una rejilla de 1 de cada 4 píxeles
# sin la franja de arriba (títulos e interfaz).
func _medir(img: Image) -> Array:
	var v: Array = []
	for y in range(int(img.get_height() * 0.18), img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			v.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
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
	return [suma / n, alto / (n - int(n * 0.75)), bajo / int(n * 0.25)]


func _escribir() -> void:
	var f := FileAccess.open(salida.path_join("luz_perfiles%s.csv" % ("_antes" if Engine.has_meta("luz_sin_compensar") else "")), FileAccess.WRITE)
	f.store_line("region;perfil;media;luz;sombra;llamadas;primitivas")
	for r in filas:
		f.store_line("%s;%s;%.4f;%.4f;%.4f;%d;%d" % r)
	f.close()
