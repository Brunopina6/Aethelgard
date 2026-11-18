extends SceneTree
# (18/11) Regresión del arreglo de grupo_3d._despejado (commit «el grupo no corta esquinas por lo bajo o lo prohibido»).
# Antes solo lanzaba un rayo a la altura de las rodillas (0,6 m): no veía lo prohibido bajo y sin choque (una jardinera de
# 0,6 m, el borde de un suelo sin choque), el seguidor tiraba su rastro y cortaba la esquina (4 roces por pasada en la
# ciudad, hasta 0,19 m). Ninguna prueba fallaba sin el arreglo (lo señaló el revisor del recorrido); esta sí:
#   1. camino libre (ni prohibido ni pared) → despejado;
#   2. camino que cruza una franja PROHIBIDA y sin choque → NO despejado (sin el arreglo daba «despejado»);
#   3. si se sale de dentro de la franja a menos de 0,1 m de su borde (el punto de partida no cuenta) → despejado;
#   4. camino que cruza una PARED física a la altura de las rodillas → NO despejado (el rayo sigue igual).
# Escena mínima sin archivos: un Node3D con _prohibido(p) y una caja estática. No escribe nada.

const FRANJA := 0.3              # lo prohibido: |x| < 0,3 y |z| < 1 (como una jardinera baja, sin choque)

var frames := 0
var fallos: Array = []
var escena: Node3D
var grupo: Node3D


func _initialize() -> void:
	escena = Node3D.new()
	var s := GDScript.new()
	s.source_code = "extends Node3D\nfunc _prohibido(p: Vector3) -> bool:\n\treturn absf(p.x) < %s and absf(p.z) < 1.0\n" % FRANJA
	s.reload()
	escena.set_script(s)
	root.add_child(escena)
	var pared := StaticBody3D.new()   # pared física en z = 5, de x = -0,2 a 0,2 y 2 m de alto
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(0.4, 2.0, 1.0)
	forma.shape = caja
	pared.add_child(forma)
	pared.position = Vector3(0, 1.0, 5)
	escena.add_child(pared)
	grupo = load("res://zonas3d/grupo_3d.gd").new()   # sin Kael ni miembros: _process no hace nada
	grupo.escena = escena
	escena.add_child(grupo)


func _process(_dt: float) -> bool:
	frames += 1
	if frames < 4:   # que la pared entre en el espacio físico
		return false
	_ver("1: camino libre", grupo._despejado(Vector3(-2, 0, 2), Vector3(2, 0, 2)), true)
	_ver("2: cruza lo prohibido y sin choque", grupo._despejado(Vector3(-2, 0, 0), Vector3(2, 0, 0)), false)
	_ver("2b: lo mismo en diagonal", grupo._despejado(Vector3(-1, 0, -0.5), Vector3(1, 0, 0.5)), false)
	_ver("3: sale de dentro a < 0,1 m del borde", grupo._despejado(Vector3(FRANJA - 0.05, 0, 0), Vector3(2, 0, 0)), true)
	_ver("4: cruza una pared física", grupo._despejado(Vector3(-2, 0, 5), Vector3(2, 0, 5)), false)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true


func _ver(que: String, dio: bool, quiere: bool) -> void:
	if dio == quiere:
		print("OK %s (%s)" % [que, dio])
	else:
		fallos.append("%s: _despejado dio %s y debía dar %s" % [que, dio, quiere])
