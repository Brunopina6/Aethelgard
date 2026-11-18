extends "res://pruebas/prueba_grupo3d_rutas.gd"
# MEDIDA (18/11), NO prueba (no va en lista_pruebas.txt): lo que cuesta en el hilo principal el GRUPO (zonas3d/grupo_3d.gd)
# fuera de la ciudad, en Pastos Verdes 3D, con los mismos destinos que prueba_grupo3d_rutas.gd (semillas fijas). Sirve para
# comparar grupo_3d.gd antes y después de _despejado con _prohibido (18/11, 4e0acbb): docs/v12/ciudad_sectores/MEDIDAS_PC.md §7.
# Por fotograma de las rutas: «proceso» (del primer _process al último, como medir_ciudad.gd) y, si grupo_3d.gd lleva la
# instrumentación temporal (pruebas/instrumentar_coste_ciudad.py), µs y llamadas de _despejado y del _process del grupo.
# Resultado de PC: no dice nada del Redmi.
# Uso: Godot --path aethelgard --resolution 1600x720 --fixed-fps 30 --script res://pruebas/medir_coste_grupo.gd -- 3d
#   [salida=<archivo .txt fuera del proyecto>]

class Marca extends Node:
	var t := 0

	func _process(_d: float) -> void:
		t = Time.get_ticks_usec()


class Muestreo extends Node:
	var inicio: Marca
	var arbol = null
	var muestras: Array = []

	func _process(_d: float) -> void:
		var ahora := Time.get_ticks_usec()
		var m := {"proc": (ahora - inicio.t) / 1000.0}
		var v = arbol.v
		if v != null and is_instance_valid(v) and v.get("grupo") != null:
			var cx = v.grupo.get("_coste_x")
			if cx is Dictionary:
				for k in cx:
					m["us_" + k] = float(cx[k][0])
					m["n_" + k] = float(cx[k][1])
				cx.clear()
		if arbol.fase == 3:
			muestras.append(m)


var mu: Muestreo
var salida_txt := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida_txt = a.trim_prefix("salida=")
	Engine.set_meta("calidad_proto", "bajo")
	var ini := Marca.new()
	ini.process_priority = -1000000
	root.add_child(ini)
	mu = Muestreo.new()
	mu.process_priority = 1000000
	mu.inicio = ini
	mu.arbol = self
	root.add_child(mu)
	super()


func _est(clave: String) -> String:
	var o: Array = []
	for m in mu.muestras:
		o.append(float(m.get(clave, 0.0)))
	o.sort()
	if o.is_empty():
		return "-"
	return "mediana %.3f · p95 %.3f · máx %.3f" % [o[o.size() / 2], o[mini(o.size() - 1, int(o.size() * 0.95))], o[-1]]


func _terminar() -> bool:
	var lineas: PackedStringArray = []
	lineas.append("Pastos Verdes 3D, grupo: %d fotogramas de rutas · %s · perfil bajo (calidad_proto) · %s" % [
		mu.muestras.size(), RenderingServer.get_video_adapter_name(), Time.get_datetime_string_from_system()])
	lineas.append("proceso ms por fotograma: " + _est("proc"))
	var claves: Array = []
	for m in mu.muestras:
		for k in m:
			if String(k).begins_with("us_") and not (String(k) in claves):
				claves.append(String(k))
	claves.sort()
	for k in claves:
		var nombre: String = k.trim_prefix("us_")
		var tot := 0.0
		var llam := 0.0
		for m in mu.muestras:
			tot += float(m.get(k, 0.0))
			llam += float(m.get("n_" + nombre, 0.0))
		lineas.append("COSTE %s: µs por fotograma %s · llamadas por fotograma %s · %.2f µs por llamada · %.0f llamadas" % [
			nombre, _est(k), _est("n_" + nombre), tot / maxf(1.0, llam), llam])
	for l in lineas:
		print(l)
	if salida_txt != "":
		var f := FileAccess.open(salida_txt, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lineas) + "\n")
			f.close()
	return super()
