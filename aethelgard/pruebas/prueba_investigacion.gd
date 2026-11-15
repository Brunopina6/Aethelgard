extends SceneTree
# Investigaciones y talleres (fase 2, 10/11; investigacion.gd y talleres.gd) con los datos de ejemplo de
# pruebas/datos_prueba/validos (los reales aún no existen: llegan en la fase 3).
#   1. Requisitos: material (tener, sin gastarlo al empezar), nivel de un héroe, hito de la historia y otra
#      investigación; estados bloqueada → disponible → en curso → completada; no se empieza dos veces ni se pasa de
#      sus pasos.
#   2. Recetas: los borradores no salen ni se fabrican sin pedirlo; sin investigar no se puede; fabricar gasta los
#      materiales y da el resultado (objeto o equipable), y sin materiales no hace nada.
#   3. Guardado: el avance va en la partida («investigaciones»), se escribe y se lee igual; una partida antigua sin
#      la clave carga y empieza de cero; un id que ya no existe se conserva.
# Partida en memoria y archivo propio en user://, con datos aislados.

const ARCHIVO := "user://prueba_investigacion.save"

var C
var I
var T
var P
var Inv
var fallos := 0


func _initialize() -> void:
	C = load("res://datos/catalogo.gd")
	I = load("res://investigacion.gd")
	T = load("res://talleres.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	C.usar_raiz("res://pruebas/datos_prueba/validos/")
	for k in ["inventario", "grupo", "hitos", "investigaciones"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	_requisitos()
	_recetas()
	_guardado()
	C.usar_raiz("res://datos/")
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _ver(id: String, esperado: String, paso: String) -> void:
	if I.estado(id) != esperado:
		_fallo("%s: «%s» está %s y debía estar %s (faltan: %s)" % [paso, id, I.estado(id), esperado, I.faltan(id)])


func _requisitos() -> void:
	_ver("alq_pociones", "bloqueada", "1 sin hierba")
	if I.empezar("alq_pociones") == "":
		_fallo("1: se empezó sin los materiales")
	Inv.agregar_objeto("Hierba lunar", 2)
	_ver("alq_pociones", "disponible", "1 con hierba")
	if I.empezar("alq_pociones") != "":
		_fallo("1: no se pudo empezar con todo lo necesario")
	_ver("alq_pociones", "en_curso", "1 empezada")
	if Inv.cantidad("Hierba lunar") != 2:
		_fallo("1: empezar gastó materiales (quedan %d)" % Inv.cantidad("Hierba lunar"))
	if I.empezar("alq_pociones") == "":
		_fallo("1: se pudo empezar dos veces")
	if I.avanzar("alq_pociones", 1):
		_fallo("1: se completó con 1 de 3 pasos")
	if not I.avanzar("alq_pociones", 9):
		_fallo("1: no se completó al llegar a sus pasos")
	_ver("alq_pociones", "completada", "1 completada")
	if int(Engine.get_meta("investigaciones")["alq_pociones"]["progreso"]) != 3:
		_fallo("1: el avance pasó de sus pasos")
	if I.avanzar("alq_pociones", 1):
		_fallo("1: se avanzó una completada")
	_ver("forja_filo", "bloqueada", "1 Kael a nivel 1")
	load("res://grupo.gd").datos()["Kael"]["nivel"] = 2
	_ver("forja_filo", "disponible", "1 Kael a nivel 2")
	_ver("arm_runas", "bloqueada", "1 sin hito ni forja")
	P.poner_hito("prueba_runas")
	_ver("arm_runas", "bloqueada", "1 con hito y sin forja")
	I.empezar("forja_filo")
	I.avanzar("forja_filo")
	_ver("arm_runas", "disponible", "1 con hito y forja")
	if I.estado("no_existe") != "" or I.empezar("no_existe") == "":
		_fallo("1: una investigación que no existe tiene estado o se empieza")
	if I.completadas().size() != 2:
		_fallo("1: completadas() da %s" % [I.completadas()])


func _recetas() -> void:
	if not I.recetas_de("alquimia").is_empty():
		_fallo("2: salen recetas en borrador sin pedirlas")
	if I.recetas_de("alquimia", true) != ["pocion_menor"]:
		_fallo("2: recetas de alquimia: %s" % [I.recetas_de("alquimia", true)])
	if not I.recetas_de("armaduras", true).is_empty():
		_fallo("2: sale una receta sin su investigación completada")
	if T.puede("pocion_menor") == "" or T.fabricar("pocion_menor"):
		_fallo("2: se fabrica un borrador sin pedirlo")
	var pociones: int = Inv.cantidad("Poción")
	if not T.fabricar("pocion_menor", true):
		_fallo("2: no se fabricó con todo lo necesario (%s)" % T.puede("pocion_menor", true))
	if Inv.cantidad("Hierba lunar") != 0 or Inv.cantidad("Poción") != pociones + 1:
		_fallo("2: fabricar no gastó o no dio lo debido (hierba %d, pociones %d)" % [Inv.cantidad("Hierba lunar"), Inv.cantidad("Poción")])
	if T.fabricar("pocion_menor", true):
		_fallo("2: se fabricó sin materiales")
	if Inv.cantidad("Hierba lunar") != 0 or Inv.cantidad("Poción") != pociones + 1:
		_fallo("2: un intento fallido cambió el inventario")
	Inv.agregar_objeto("Mineral de hierro", 3)
	Inv.datos()["equipables"].erase("cota_malla")    # (la partida nueva ya la trae: antes esto pasaba sin dar nada)
	if not T.fabricar("filo_reforzado", true) or not "cota_malla" in Inv.datos()["equipables"] 			or Inv.cantidad("Mineral de hierro") != 0:
		_fallo("2: un equipable fabricado no llega a los equipables o no gasta")
	if T.puede("runa_defensa", true) == "":
		_fallo("2: se puede fabricar sin investigar")
	if T.puede("no_existe", true) == "":
		_fallo("2: se puede fabricar una receta que no existe")
	_recetas_invalidas()


# 2b (15/11, auditoría externa): una receta mal escrita (resultado, destino, atributo, efecto, cifras o materiales) no
# se puede fabricar, no gasta nada y no se marca como hecha. Un equipable que ya se tiene tampoco gasta nada.
func _recetas_invalidas() -> void:
	var Receta = load("res://datos/tipos/receta.gd")
	var malas := {
		"mal_sin_cifra": ["mejora:Kael:fuerza", 1, {"Hierba lunar": 1}],
		"mal_heroe": ["mejora:Nadie:fuerza:3", 1, {"Hierba lunar": 1}],
		"mal_atributo": ["mejora:Kael:suerte:3", 1, {"Hierba lunar": 1}],
		"mal_cifra": ["mejora:Kael:fuerza:tres", 1, {"Hierba lunar": 1}],
		"mal_cero": ["mejora:Kael:fuerza:0", 1, {"Hierba lunar": 1}],
		"mal_efecto": ["tecnica:Kael:volar:0.1", 1, {"Hierba lunar": 1}],
		"mal_efecto_max": ["tecnica:Kael:critico:5", 1, {"Hierba lunar": 1}],
		"mal_pieza": ["pieza:espada_fantasma:ataque:2", 1, {"Hierba lunar": 1}],
		"mal_prefijo": ["magia:Kael:Fuego:1", 1, {"Hierba lunar": 1}],
		"mal_objeto": ["Piedra filosofal", 1, {"Hierba lunar": 1}],
		"mal_cantidad": ["Poción", 0, {"Hierba lunar": 1}],
		"mal_equipable_2": ["cota_malla", 2, {"Hierba lunar": 1}],
		"mal_material": ["Poción", 1, {"Polvo de estrellas": 1}],
		"mal_material_0": ["Poción", 1, {"Hierba lunar": 0}],
		"mal_sin_material": ["Poción", 1, {}],
	}
	var lista: Dictionary = C.todos("recetas")
	for id in malas:
		var r = Receta.new()
		r.id = id
		r.taller = "alquimia"
		r.nombre = id
		r.resultado = malas[id][0]
		r.cantidad = malas[id][1]
		r.materiales = malas[id][2]
		r.borrador = false
		lista[id] = r
		Inv.agregar_objeto("Hierba lunar", 2)
		var antes: Dictionary = Inv.datos().duplicate(true)
		var motivo: String = T.puede(id, true)
		if motivo == "" or not motivo.begins_with("Esta receta no es válida"):
			_fallo("2b: la receta «%s» (%s) pasa la validación («%s»)" % [id, r.resultado, motivo])
		if T.fabricar(id, true):
			_fallo("2b: la receta «%s» (%s) se fabrica" % [id, r.resultado])
		if Inv.datos() != antes:
			_fallo("2b: la receta «%s» cambió el inventario o lo hecho" % id)
		lista.erase(id)
	# un equipable que ya se tiene: «Ya lo tienes», sin gastar
	Inv.agregar_objeto("Mineral de hierro", 3)
	var antes2: Dictionary = Inv.datos().duplicate(true)
	if not "cota_malla" in Inv.datos()["equipables"] or T.puede("filo_reforzado", true) != "Ya lo tienes." \
			or T.fabricar("filo_reforzado", true) or Inv.datos() != antes2:
		_fallo("2b: un equipable repetido se fabrica o gasta («%s»)" % T.puede("filo_reforzado", true))
	# y una buena sigue funcionando: la mejora se aplica de verdad
	var buena = Receta.new()
	buena.id = "buena_mejora"
	buena.taller = "forja"
	buena.resultado = "mejora:Kael:fuerza:2"
	buena.materiales = {"Hierba lunar": 1}
	buena.borrador = false
	lista["buena_mejora"] = buena
	var fuerza0: int = int(Inv.datos()["mejoras"].get("Kael", {}).get("fuerza", 0))
	Inv.agregar_objeto("Hierba lunar", 1)
	var hierba: int = Inv.cantidad("Hierba lunar")
	if not T.fabricar("buena_mejora", true) or int(Inv.datos()["mejoras"].get("Kael", {}).get("fuerza", 0)) != fuerza0 + 2 \
			or Inv.cantidad("Hierba lunar") != hierba - 1 or not "buena_mejora" in Inv.datos()["hechas"]:
		_fallo("2b: una mejora válida no se aplica, no gasta o no queda hecha")
	if T.fabricar("buena_mejora", true):
		_fallo("2b: una mejora se hace dos veces")
	lista.erase("buena_mejora")


func _guardado() -> void:
	Engine.get_meta("investigaciones")["vieja_que_ya_no_existe"] = {"progreso": 1, "completada": false}
	var d: Dictionary = P.volcar("res://mapa.tscn")
	if not d.has("investigaciones"):
		_fallo("3: la partida no guarda las investigaciones")
		return
	if not P.escribir(d, ARCHIVO):
		_fallo("3: no se pudo escribir la partida de prueba")
		return
	var leida = P.leer(ARCHIVO)
	Engine.remove_meta("investigaciones")
	P.restaurar(leida)
	_ver("alq_pociones", "completada", "3 tras leer")
	_ver("forja_filo", "completada", "3 tras leer")
	if not Engine.get_meta("investigaciones", {}).has("vieja_que_ya_no_existe"):
		_fallo("3: se perdió el avance de una investigación que ya no existe")
	var antigua := {"escena_guardada": "res://mapa.tscn", "pos_mapa": Vector2(520, 330), "pos_mapa_ok": true}
	P.restaurar(antigua)
	if Engine.has_meta("investigaciones") and not Engine.get_meta("investigaciones").is_empty():
		_fallo("3: una partida antigua trae investigaciones de la sesión anterior")
	_ver("alq_pociones", "bloqueada", "3 partida antigua")
	if I.completadas().size() != 0:
		_fallo("3: una partida antigua empieza con investigaciones completadas")
