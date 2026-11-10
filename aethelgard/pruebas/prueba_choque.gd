extends SceneTree
# Prueba: pone a Kael a la izquierda de cada tipo de árbol/planta y le hace caminar a la derecha.
# Dice si lo atraviesa. Uso: godot --path <proyecto> --script prueba_choque.gd -- estilo=bosque

var zona: Node
var frames := 0
var casos: Array = []
var caso := -1
var inicio := Vector2.ZERO
var objetivo: Node2D
var paso_frames := 0
var desvio := 0.0
var minimo := 9999.0
var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _terminar() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true




func _initialize() -> void:
	# Sin encuentros al azar (el Incienso de Ceniza: probabilidad 0). Kael anda bastante en esta prueba y, sin esto, a
	# veces salía un combate que se quedaba cargando al terminar («Parse Error» de combate.tscn, 08/11).
	Engine.set_meta("incienso", 1000000)
	zona = load("res://zona.tscn").instantiate()
	root.add_child(zona)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 5:
		var vistos := {}
		for s in zona.mundo_y.get_children():
			if not s is Sprite2D or s.texture == null:
				continue
			var nombre: String = s.texture.resource_path.get_file() if s.texture.resource_path != "" else "dibujado"
			if vistos.has(nombre):
				continue
			vistos[nombre] = true
			var tiene := false
			for c in s.get_children():
				if c is StaticBody2D:
					tiene = true
			casos.append([nombre + " (→)", s, tiene, Vector2(1, 0)])
			casos.append([nombre + " (↓)", s, tiene, Vector2(0, 1)])
		print("tipos: ", casos.size())
		_siguiente()
		return false
	if caso < 0 or caso >= casos.size():
		if frames <= 5:
			return false
		if casos.is_empty():
			_fallo("no hay ningún árbol ni planta que probar")
		return _terminar()
	paso_frames += 1
	var dd: Vector2 = casos[caso][3]
	var lado: float = absf((zona.jugador.position - objetivo.position).dot(dd.orthogonal()))
	desvio = maxf(desvio, lado)
	var cerca: float = (zona.jugador.position - objetivo.position).length()
	minimo = minf(minimo, cerca)
	if paso_frames > 90:
		var c = casos[caso]
		var dir: Vector2 = c[3]
		var paso: bool = (zona.jugador.position - objetivo.position).dot(dir) > 10
		var r := "se para"
		if paso:
			r = "lo rodea (se desvía %d px)" % desvio if desvio > 12 else "LO ATRAVIESA (pasa a %d px del centro)" % minimo
		print("%-22s choque=%s  -> %s" % [c[0], c[2], r])
		if c[2] and r.begins_with("LO ATRAVIESA"):   # (10/11) lo que tiene colisión nunca se atraviesa
			_fallo("%s tiene colisión y Kael lo atraviesa" % c[0])
		_siguiente()
	return _terminar() if caso >= casos.size() else false


func _siguiente() -> void:
	caso += 1
	paso_frames = 0
	desvio = 0.0
	minimo = 9999.0
	if caso >= casos.size():
		return
	objetivo = casos[caso][1]
	var dir: Vector2 = casos[caso][3]
	zona.jugador.position = objetivo.position - dir * 70
	zona.destino = objetivo.position + dir * 90
	zona.tiene_destino = true
