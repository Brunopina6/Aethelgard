extends RefCounted
# Arte FALSO de Oakhaven, solo para prueba_oakhaven (apartado 11). Imita la forma de ciudades/oakhaven_piezas.gd (de
# gráficos): crear_pieza(id, rect_casillas, tam_casilla) -> Node2D, o null si no hay arte para ese id. Devuelve nodos
# vacíos que apuntan lo que la ciudad les pide (encender, estados). Así se prueba el camino del arte de
# ciudad_oakhaven.gd sin depender del arte de verdad, que se hace aparte. No entra en el juego (pruebas/ no se exporta).

const AMBIENTE := Color(0.5, 0.52, 0.7)
const IDS := ["taberna", "crematorio", "ronda", "arbol", "oak_farol_1", "oak_torre", "nota_oak_cuervo", "oak_sello",
	"farol", "casa_4x4"]


class Falsa extends Node2D:
	var id := ""
	var rect := Rect2i()
	var encendida := false
	var estados := {}

	func encender(si: bool) -> void:
		encendida = si

	func poner_estado(nombre: String, si: bool) -> bool:
		estados[nombre] = si
		return true

	func tiene_estado(nombre: String) -> bool:
		return id == "ronda" and nombre == "oak_cofre_ronda"     # el destello de su cofre lo pinta la ronda


static func crear_pieza(id: String, rect_casillas: Rect2i, _tam_casilla: int) -> Node2D:
	if not id in IDS:
		return null
	var n := Falsa.new()
	n.name = "falsa_" + id
	n.id = id
	n.rect = rect_casillas
	return n
