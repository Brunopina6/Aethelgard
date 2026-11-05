extends SceneTree
# Batería de recorrido de Pastos Verdes (Skill aet-fisica-recorrido): río, canal, barranco, puente y bordes.
# Cada caso termina en LLEGA, PARADO EN SITIO SEGURO o ATASCADO (fallo).
# Uso: --path aethelgard --script res://pruebas/prueba_rio.gd --fixed-fps 20|30|60

var v: Node
var n := 0
var i := -1
var inicio := 0
var fallos := 0
# [nombre, desde, destino tocado, ¿debe llegar?, colocar a mano (sin comprobar el sitio)]
const CASOS := [
	["tocar el río desde el lateral", Vector3(4.5, 0, 4), Vector3(9.0, 0, 4), false, false],
	["tocar el río desde la otra orilla", Vector3(13.5, 0, 6), Vector3(9.0, 0, 6), false, false],
	["tocar el canal de la cascada", Vector3(5.0, 0, -20), Vector3(9.0, 0, -20), false, false],
	["tocar el fondo del barranco junto al puente", Vector3(5.0, 0, -4), Vector3(9.0, 0, -5), false, false],
	["cruzar el puente", Vector3(5.3, 0, -2), Vector3(12.7, 0, -2), true, false],
	["salir del puente hacia el pretil", Vector3(9.0, 0, -2), Vector3(9.0, 0, 2), false, false],
	["ir al borde del mapa", Vector3(-15, 0, 0), Vector3(-40, 0, 0), false, false],
	["aparecer dentro del canal", Vector3(9.0, 0, -20), Vector3(9.0, 0, -21), false, true],
	["aparecer en el fondo del barranco", Vector3(9.0, 0, 4), Vector3(4.0, 0, 4), false, true],
]


func _initialize() -> void:
	v = load("res://prototipos/sendero_puente.tscn").instantiate()
	root.add_child(v)


func _resultado() -> void:
	var c: Array = CASOS[i]
	var p: Vector3 = v.kael.global_position
	var meta: Vector3 = c[2]
	var llega := Vector2(p.x - meta.x, p.z - meta.z).length() < 0.6
	var seguro: bool = not v._prohibido(p) and v.destino == null
	var r := "LLEGA" if llega else ("PARADO EN SITIO SEGURO" if seguro else "ATASCADO")
	if r == "ATASCADO" or (c[3] and not llega):
		fallos += 1
		r += "  <-- FALLO"
	print("  ", c[0], ": ", r, "  (", p.snapped(Vector3.ONE * 0.1), ")")


func _suelo(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 20, p.z), Vector3(p.x, -20, p.z))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	return r["position"].y if not r.is_empty() else 0.0


func _process(_d: float) -> bool:
	n += 1
	if n < 10:
		return false
	if i == -1 or v.destino == null or n - inicio > 300:
		if i >= 0:
			_resultado()
		i += 1
		if i >= CASOS.size():
			print("FALLOS: ", fallos, " de ", CASOS.size())
			return true
		var c: Array = CASOS[i]
		var a: Vector3 = c[1]
		var y := _suelo(a)                               # lo primero que hay debajo (el puente, si está encima)
		if c[4]:                                        # colocado a mano en un sitio prohibido
			var s := Vector3(4.0, 0, a.z)
			v.seguro = Vector3(s.x, _suelo(s), s.z)
		else:
			v.seguro = Vector3(a.x, y, a.z)
		v.kael.global_position = Vector3(a.x, y, a.z)
		v.destino = v._ajustar_destino(c[2]) if not c[4] else c[2]
		inicio = n
	return false
