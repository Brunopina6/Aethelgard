extends SceneTree
# MEDIDA (15/11), no prueba: N entradas seguidas a la muestra de la calle en un mismo proceso (como volver del banco y
# entrar otra vez) y la mediana de cada fase del _ready (diagnostico_tirones.gd, marcas), para comparar variantes:
#   choques=uno|separados   (un cuerpo con 41 cajas, o un cuerpo por caja como antes)
# La 1.ª entrada se descarta (primera vez del proceso). Uso: --path aethelgard --resolution 1600x720 --script
#   res://pruebas/medir_entradas_muestra.gd -- 3d sin_prologo perfil=bajo choques=uno|separados n=12
const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
var n := 12
var fases := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			Engine.set_meta("calidad_proto", a.trim_prefix("perfil="))
		elif a == "choques=separados":
			Engine.set_meta("muestra_choques_separados", true)
		elif a.begins_with("n="):
			n = int(a.trim_prefix("n="))
	Engine.set_meta("archivo_partida_prueba", "user://medir_entradas_muestra.save")
	_medir.call_deferred()


func _medir() -> void:
	load("res://progreso.gd").cargar()
	Engine.set_meta("partida_lista", true)
	var vacia := Node.new()
	for i in n:
		change_scene_to_file(MUESTRA)
		for f in 20:
			await process_frame
		var v = current_scene
		if i > 0 and v != null and v.get("diag") != null:
			for m in v.diag.marcas:
				var partes: PackedStringArray = String(m).rsplit(" ", true, 1)
				if not fases.has(partes[0]):
					fases[partes[0]] = []
				fases[partes[0]].append(float(partes[1]))
		change_scene_to_file("res://pruebas/escena_vacia.tscn") if ResourceLoader.exists("res://pruebas/escena_vacia.tscn") else current_scene.queue_free()
		for f in 5:
			await process_frame
	var lineas: PackedStringArray = []
	for k in fases:
		var a: Array = fases[k]
		a.sort()
		lineas.append("%s %.2f" % [k, a[a.size() / 2]])
	print("[medida] choques=%s · %d entradas (sin la 1.ª) · medianas ms: %s" % [
		"separados" if Engine.has_meta("muestra_choques_separados") else "uno", n - 1, " · ".join(lineas)])
	vacia.free()
	quit(0)
