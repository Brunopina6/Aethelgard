extends SceneTree
# Catálogo de datos (fase 2, 10/11; datos/catalogo.gd):
#   1. Los datos reales del juego (res://datos/) no tienen errores, y el material migrado (Corteza espinosa) da lo
#      mismo que la tabla antigua de equipo_extra.gd: precio, texto, clave de inventario y quién lo deja.
#   2. Los datos de ejemplo válidos (pruebas/datos_prueba/validos) pasan la validación.
#   3. Los de ejemplo con errores a propósito (invalidos) los dan todos: id repetido, id mal escrito, clave de
#      inventario repetida, venta negativa, taller desconocido, material o investigación que no existen, receta sin
#      materiales, requisito desconocido, de nivel no válido, de material inexistente y la que se requiere a sí misma.
# Sin escenas.

var C
var fallos := 0


func _initialize() -> void:
	C = load("res://datos/catalogo.gd")
	_reales()
	_recetas_reales_validas()
	_validos()
	_invalidos()
	C.usar_raiz("res://datos/")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _recetas_reales_validas() -> void:   # 15/11: ninguna receta real tiene un resultado o material mal escrito
	var T = load("res://talleres.gd")
	for id in C.todos("recetas"):
		var e: String = T.error_receta(C.uno("recetas", id))
		if e != "":
			_fallo("receta real «%s» no válida: %s" % [id, e])


func _reales() -> void:
	C.usar_raiz("res://datos/")
	var e: Array = C.validar()
	if not e.is_empty():
		_fallo("1: los datos del juego tienen errores: %s" % [e])
	var Extra = load("res://equipo_extra.gd")
	var antes := {"Corteza espinosa": {"venta": 18, "desc": "Corteza de Zarzalín, llena de espinas. Se vende."}}
	var ahora: Dictionary = Extra.materiales()
	for clave in antes:
		if not ahora.has(clave):
			_fallo("1: falta el material «%s»" % clave)
			continue
		for campo in antes[clave]:
			if ahora[clave][campo] != antes[clave][campo]:
				_fallo("1: «%s».%s es %s y era %s" % [clave, campo, ahora[clave][campo], antes[clave][campo]])
	if Extra.botin() != {"zarzalin": "Corteza espinosa"}:
		_fallo("1: el botín cambió: %s" % [Extra.botin()])
	var caido := {"clave": "zarzalin", "hp": 0}
	var huido := {"clave": "zarzalin", "hp": 0, "huido": true}
	var vivo := {"clave": "zarzalin", "hp": 5}
	var otro := {"clave": "slime", "hp": 0}
	if Extra.botin_de([caido, huido, vivo, otro, caido]) != ["Corteza espinosa", "Corteza espinosa"]:
		_fallo("1: botin_de no da lo mismo que antes: %s" % [Extra.botin_de([caido, huido, vivo, otro, caido])])


func _validos() -> void:
	C.usar_raiz("res://pruebas/datos_prueba/validos/")
	var e: Array = C.validar()
	if not e.is_empty():
		_fallo("2: los datos válidos dan errores: %s" % [e])
	for par in [["materiales", 2], ["recetas", 3], ["investigaciones", 3]]:
		if C.todos(par[0]).size() != par[1]:
			_fallo("2: %s: %d y se esperaban %d" % [par[0], C.todos(par[0]).size(), par[1]])
	if C.uno("recetas", "pocion_menor") == null or C.uno("recetas", "no_existe") != null:
		_fallo("2: uno() no encuentra lo que hay o encuentra lo que no hay")


func _invalidos() -> void:
	C.usar_raiz("res://pruebas/datos_prueba/invalidos/")
	var texto := "\n".join(C.validar())
	for esperado in ["id «vacia» repetido", "id «Mal_Id» no válido", "clave de inventario «hierba» repetida",
			"venta negativa", "taller «cocina» desconocido", "el material «Fantasma» no existe",
			"la investigación «no_existe» no existe", "receta «vacia»: no gasta ningún material",
			"sin resultado", "requisito no válido", "requisito de nivel no válido", "requisito de material no válido",
			"requiere «circular», que no existe o es ella misma", "receta «receta_fantasma», que no existe",
			"pasos no positivos"]:
		if not texto.contains(esperado):
			_fallo("3: no se detecta «%s»" % esperado)
	print("Errores detectados en los datos con fallos a propósito:\n", texto)
