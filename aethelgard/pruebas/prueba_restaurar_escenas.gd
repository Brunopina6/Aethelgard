extends SceneTree
# Prueba de progreso.restaurar() con escenas que ya tienen versión nueva (T-089 y T-095), con partidas sintéticas
# (no se lee ni se escribe ningún archivo). Se lanza con «-- 3d garganta3d» (lista_pruebas.txt).
#   1. Una partida guardada en la Oakhaven generada (zona.tscn con el lugar 0) abre la ciudad hecha a mano, por su
#      entrada (pos_zona_ok = false).
#   2. Una partida guardada en Sunken City (zona.tscn con el lugar 5) sigue abriendo zona.tscn, en el mismo sitio.
#   3. Con la Garganta 3D en uso, una partida guardada en la Garganta 2D abre la 3D.
#   4. Una partida en el mapa sigue en el mapa.

var fallos: Array = []


func _initialize() -> void:
	var P = load("res://progreso.gd")
	var r: String = P.restaurar({"escena_guardada": "res://zona.tscn", "lugar": {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad", "zona": "ciudad", "texto": "x"}})
	if r != "res://ciudad_oakhaven.tscn" or Engine.get_meta("pos_zona_ok", true):
		fallos.append("1: la Oakhaven generada no abre la ciudad hecha a mano por su entrada (%s)" % r)
	r = P.restaurar({"escena_guardada": "res://zona.tscn", "lugar": {"indice": 5, "nombre": "Sunken City", "tipo": "ciudad", "zona": "ciudad", "texto": "x"}})
	if r != "res://zona.tscn" or not Engine.get_meta("pos_zona_ok", false):
		fallos.append("2: Sunken City ya no abre su zona en el mismo sitio (%s)" % r)
	if load("res://modo3d.gd").region_activa(2):
		r = P.restaurar({"escena_guardada": "res://garganta.tscn", "lugar": {"indice": 2, "nombre": "Garganta del Diablo", "tipo": "mazmorra", "zona": "garganta", "texto": "x"}})
		if r != "res://zonas3d/garganta_3d.tscn":
			fallos.append("3: con la Garganta 3D en uso, la partida de la 2D no abre la 3D (%s)" % r)
	else:
		fallos.append("3: la Garganta 3D no está en uso (falta «-- 3d garganta3d»)")
	r = P.restaurar({"escena_guardada": "res://mapa.tscn"})
	if r != "res://mapa.tscn":
		fallos.append("4: una partida en el mapa no sigue en el mapa (%s)" % r)
	print("OK restaurar: Oakhaven nueva, Sunken City igual, Garganta 3D y mapa")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
