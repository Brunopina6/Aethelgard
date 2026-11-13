extends SceneTree
# Pruebas de rendimiento del Gran Bosque desde Ajustes (13/11, para el Redmi): calidad_proto.gd EXTRA_PRUEBAS y el
# bloque «Gran Bosque: pruebas de rendimiento» de Ajustes (solo Auditoría o editor). Comprueba que van apagadas, que al
# elegirlas se guardan en user://ajustes.cfg [calidad_pruebas] y llegan al perfil en uso (datos()), que al apagarlas
# desaparecen y que los demás ajustes del archivo se conservan. Sin ventana. Imprime «FALLOS: n».

const CP := preload("res://prototipos/calidad_proto.gd")

var fallos := 0


func _ok(cond: bool, texto: String) -> void:
	if cond:
		print("  ok  ", texto)
	else:
		fallos += 1
		print("  FALLO ", texto)


func _initialize() -> void:
	_principal.call_deferred()


func _principal() -> void:
	_ok(CP.pruebas_permitidas(), "en el editor (y en Auditoría) se permiten")
	var previo := ConfigFile.new()
	previo.set_value("heroes", "v2", false)                  # otro ajuste que no debe perderse
	previo.save("user://ajustes.cfg")
	CP._extra_cache = null
	var d: Dictionary = CP.datos()
	_ok(not d.get("gb_matas_casco", false) and not d.get("gb_hojas_mipmaps", false), "apagadas por defecto")
	_ok(CP.elegir_extra("gb_matas_casco", true) == OK, "elegir matas recortadas")
	d = CP.datos()
	_ok(d.get("gb_matas_casco", false) == true, "datos(): gb_matas_casco = true")
	_ok(not d.get("gb_hojas_mipmaps", false), "las hojas siguen apagadas")
	CP.elegir_extra("gb_hojas_mipmaps", true)
	d = CP.datos()
	_ok(d.get("gb_hojas_mipmaps", false) == true and float(d.get("gb_hojas_mip_sesgo", 0.0)) == -1.0,
		"datos(): mipmaps con sesgo −1")
	var c := ConfigFile.new()
	_ok(c.load("user://ajustes.cfg") == OK and bool(c.get_value("calidad_pruebas", "gb_matas_casco", false))
		and c.has_section_key("heroes", "v2"), "se guarda en [calidad_pruebas] sin perder los demás ajustes")
	CP._extra_cache = null                                     # como al abrir otra vez el juego
	_ok(CP.datos().get("gb_matas_casco", false) == true, "al volver a abrir, lo guardado manda")
	CP.elegir_extra("gb_matas_casco", false)
	CP.elegir_extra("gb_hojas_mipmaps", false)
	d = CP.datos()
	_ok(not d.get("gb_matas_casco", false) and not d.get("gb_hojas_mipmaps", false), "apagadas otra vez")
	_ok(CP.elegir_extra("otra_cosa", true) == ERR_UNAUTHORIZED, "una clave desconocida no se acepta")
	# el bloque de Ajustes
	var M = load("res://menus.gd")
	var m: Node = M.new()
	m.set("pestana", "Ajustes")
	root.add_child(m)
	await process_frame
	for i in 4:
		await process_frame
	var hay := _buscar_boton(m, "gb:gb_matas_casco:si")
	_ok(hay, "Ajustes: el bloque del Gran Bosque sale (Auditoría o editor)")
	m.queue_free()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _buscar_boton(n: Node, nombre: String) -> bool:
	if n.name == nombre or (n.has_meta("clave") and str(n.get_meta("clave")) == nombre):
		return true
	for h in n.get_children():
		if _buscar_boton(h, nombre):
			return true
	return false
