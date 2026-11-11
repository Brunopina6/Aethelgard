extends RefCounted
# Los juegos de la Taberna del Cuervo Oxidado (V11, hito E; taberna_parejas.gd). Sin apuestas: no se pone dinero.
# Premio controlado, sin poder repetirlo para sacar monedas: la primera victoria da el premio entero; después, solo batir
# el récord (menos intentos) da RECORD_ORO. Se guarda en la partida (progreso.gd CLAVES «taberna»):
# {"parejas": {"record": n, "ganadas": n}}. Las partidas antiguas no lo traen y empiezan sin récord.

const RECORD_ORO := 10


static func _d() -> Dictionary:
	if not Engine.has_meta("taberna"):
		Engine.set_meta("taberna", {})
	return Engine.get_meta("taberna")


static func record(juego: String) -> int:
	return int(_d().get(juego, {}).get("record", 0))


static func ganadas(juego: String) -> int:
	return int(_d().get(juego, {}).get("ganadas", 0))


# Una victoria con «intentos» (menos es mejor). Da el premio y devuelve el texto para el jugador.
static func ganar(juego: String, intentos: int, premio: Dictionary) -> String:
	var d := _d()
	if not d.has(juego):
		d[juego] = {"record": 0, "ganadas": 0}
	var j: Dictionary = d[juego]
	var Inv = load("res://inventario.gd")
	var primera: bool = int(j["ganadas"]) == 0
	var mejora: bool = int(j["record"]) == 0 or intentos < int(j["record"])
	j["ganadas"] = int(j["ganadas"]) + 1
	if mejora:
		j["record"] = intentos
	if primera:
		Inv.ganar_oro(int(premio.get("oro", 0)))
		var partes: Array = ["%d monedas" % int(premio.get("oro", 0))]
		for o in premio.get("objetos", {}):
			Inv.agregar_objeto(o, int(premio["objetos"][o]))
			partes.append("%d %s" % [int(premio["objetos"][o]), o])
		return "¡Todas las parejas en %d intentos! La posadera te invita: %s." % [intentos, ", ".join(partes)]
	if mejora:
		Inv.ganar_oro(RECORD_ORO)
		return "¡Récord nuevo: %d intentos! La mesa del fondo aplaude. +%d monedas." % [intentos, RECORD_ORO]
	return "¡Todas las parejas en %d intentos! Tu récord sigue en %d." % [intentos, int(j["record"])]
