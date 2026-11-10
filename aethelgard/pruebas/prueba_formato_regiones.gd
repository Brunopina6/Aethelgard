extends SceneTree
# Preparación modular (10/11): versión del formato de la partida e identificadores estables de las regiones.
#   1. Lo que se guarda lleva «formato» = progreso.FORMATO; una partida sin la clave es el formato 1 y carga igual;
#      escrita y leída, conserva la versión.
#   2. regiones.gd: cada lugar del mapa (LUGARES + LUGAR_PASTOS, el índice que guardan las partidas) tiene un id único
#      que coincide con su nombre, va y vuelve (id ↔ índice), y los índices de modo3d.gd son los suyos.
# Sin escenas; archivo propio en user:// con datos aislados.

const ARCHIVO := "user://prueba_formato_regiones.save"

var P
var fallos := 0


func _initialize() -> void:
	P = load("res://progreso.gd")
	_formato()
	_regiones()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _formato() -> void:
	var d: Dictionary = P.volcar("res://mapa.tscn")
	if int(d.get("formato", -1)) != P.FORMATO:
		_fallo("1: lo que se guarda no lleva formato %d (lleva %s)" % [P.FORMATO, d.get("formato")])
	if P.formato_de({}) != 1:
		_fallo("1: una partida sin «formato» no cuenta como formato 1")
	var antigua := {"escena_guardada": "res://mapa.tscn", "pos_mapa": Vector2(520, 330), "pos_mapa_ok": true}
	if Engine.has_meta("formato"):
		Engine.remove_meta("formato")
	P.restaurar(antigua)                            # una partida antigua (sin «formato») carga sin error
	if int(P.volcar("res://mapa.tscn").get("formato", -1)) != P.FORMATO:
		_fallo("1: tras cargar una partida antigua, lo que se guarda no lleva la versión actual")
	if not P.escribir(P.volcar("res://mapa.tscn"), ARCHIVO):
		_fallo("1: no se pudo escribir la partida de prueba")
	else:
		var leida = P.leer(ARCHIVO)
		if not leida is Dictionary or P.formato_de(leida) != P.FORMATO:
			_fallo("1: escrita y leída, la partida no conserva el formato")
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _id_de_nombre(nombre: String) -> String:
	var s := nombre.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"], [" ", "_"]]:
		s = s.replace(par[0], par[1])
	return s


func _regiones() -> void:
	var R = load("res://regiones.gd")
	var M = load("res://mapa.gd")
	var lugares: Array = M.LUGARES + [M.LUGAR_PASTOS]
	var vistos := {}
	for i in lugares.size():
		var id: String = R.id_de(i)
		if id == "":
			_fallo("2: el lugar %d (%s) no tiene id" % [i, lugares[i]["nombre"]])
			continue
		if vistos.has(id):
			_fallo("2: el id «%s» se repite" % id)
		vistos[id] = true
		if id != _id_de_nombre(lugares[i]["nombre"]):
			_fallo("2: el lugar %d se llama «%s» y su id es «%s»" % [i, lugares[i]["nombre"], id])
		if R.indice_de(id) != i:
			_fallo("2: el id «%s» no vuelve a su índice %d" % [id, i])
	if R.IDS.size() != lugares.size():
		_fallo("2: hay %d ids para %d lugares" % [R.IDS.size(), lugares.size()])
	var m3d = load("res://modo3d.gd")
	for par in [[m3d.PASTOS_VERDES, "pastos_verdes"], [m3d.GARGANTA, "garganta_del_diablo"], [m3d.OAKHAVEN, "oakhaven"]]:
		if R.id_de(par[0]) != par[1]:
			_fallo("2: modo3d usa el índice %d para «%s» y su id es «%s»" % [par[0], par[1], R.id_de(par[0])])
