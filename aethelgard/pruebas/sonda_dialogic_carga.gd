extends SceneTree
# Sonda (no es una prueba): cuánto de preparar la interfaz de Dialogic es leer archivos y cuánto es crearla.
# Mide en el mismo proceso: 1) cargar el estilo y las escenas de sus capas, 2) Styles.load_style() ya con todo cargado,
# 3) el fotograma siguiente (se añade al árbol y hace su _ready).

var D
var frames := 0
var t := 0


func _initialize() -> void:
	D = root.get_node("Dialogic")


func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		var t0 := Time.get_ticks_usec()
		var estilo = DialogicStylesUtil.get_style("")
		print("LEER solo el estilo (.tres): %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		var rutas: Array = []
		var base: Dictionary = estilo.get_layer_inherited_info("")
		rutas.append(base.path if not base.path.is_empty() else "(base por defecto)")
		var guardados: Array = [estilo, DialogicStylesUtil.get_default_layout_base()]
		for id in estilo.get_layer_inherited_list():
			var capa: Dictionary = estilo.get_layer_inherited_info(id)
			rutas.append(capa.path)
			if ResourceLoader.exists(capa.path):
				guardados.append(load(capa.path))
		var t1 := Time.get_ticks_usec()
		var interfaz = D.Styles.load_style()
		interfaz.hide()
		var t2 := Time.get_ticks_usec()
		print("ESTILO: ", estilo.resource_path)
		print("CAPAS: ", rutas)
		print("LEER estilo y capas: %.1f ms" % ((t1 - t0) / 1000.0))
		print("CREAR (load_style con todo leído): %.1f ms" % ((t2 - t1) / 1000.0))
		set_meta("guardados", guardados)
		t = Time.get_ticks_usec()
	elif frames == 4:
		print("FOTOGRAMA SIGUIENTE (añadir al árbol y _ready): %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	return frames > 6
