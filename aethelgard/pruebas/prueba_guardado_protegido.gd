extends SceneTree
# Una partida guardada en Oakhaven vuelve a la ciudad: la generada (zona.tscn) o, desde T-089, la hecha a mano.
const OAKHAVEN := ["res://zona.tscn", "res://ciudad_oakhaven.tscn"]
# Prueba de la protección del guardado traída a la copia habitual (rebelum-3d; progreso.gd e inventario.gd, de
# rebelum-alpha 86a58af; TASKS.md, T-076 y T-077). Partidas sintéticas en un archivo propio
# (user://prueba_guardado_protegido.save) y datos aislados (ejecutar_pruebas.ps1): nunca toca la partida de verdad.
#   1. Sin cargar la partida (una escena abierta directamente, como F6 en el editor), guardar no la pisa.
#   2. Después de cargarla, guardar escribe, conserva lo cargado y deja la anterior en «.bak»; no queda «.tmp».
#   3. Una partida como la del PC (sin «grupo» ni «inventario») carga, y un inventario antiguo sin lista de objetos se
#      completa con los valores iniciales.
#   4. Partida dañada: se recupera la última buena («.bak») y la dañada se aparta en «.danada».
#   5. Corte al guardar: un «.tmp» a medias no estropea la carga; uno completo sin la partida se recupera.
#   6. Si no se puede escribir, la partida anterior queda intacta.
#   7. Partida nueva (sin archivo): cargar() deja guardar.
#   8. Sin archivo propio, una prueba nunca guarda (tampoco en user://partida.save).
#   9. (15/11, auditoría) Partida legible pero con la estructura mal («grupo» como texto, listas que no son listas,
#      posiciones que no son posiciones…): no se acepta; se recupera la copia buena y la mala se aparta en «.danada»;
#      guardar después no copia la mala sobre la buena. Una clave desconocida (versión más nueva) sí se acepta, y la
#      partida del PC (caso 3) sigue cargando.

const ARCHIVO := "user://prueba_guardado_protegido.save"

var P
var inv
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	inv = load("res://inventario.gd")
	_sin_archivo_propio()
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	if P.archivo() != ARCHIVO:
		print("FALLO: no se usa el archivo de la prueba (%s)" % P.archivo())
		quit(1)
		return
	_limpiar()
	_sin_cargar()
	_cargar_y_guardar()
	_limpiar()
	_partida_del_pc()
	_limpiar()
	_danada()
	_limpiar()
	_cortes()
	_limpiar()
	_escritura_fallida()
	_limpiar()
	_partida_nueva()
	_limpiar()
	_estructura()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK guardado protegido: ", ", ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _limpiar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada"]:
		var r: String = ProjectSettings.globalize_path(ARCHIVO + extra)
		if DirAccess.dir_exists_absolute(r):
			DirAccess.remove_absolute(r)
		elif FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(r)
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if Engine.has_meta("partida_lista"):
		Engine.remove_meta("partida_lista")


func _texto(ruta: String) -> String:
	return FileAccess.get_file_as_string(ruta) if FileAccess.file_exists(ruta) else ""


func _poner(ruta: String, texto: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _partida_completa() -> Dictionary:
	return {"escena_guardada": "res://zona.tscn", "prologo_visto": true,
		"lugar": {"indice": 0, "nombre": "Oakhaven", "texto": "x", "tipo": "ciudad", "zona": "ciudad"},
		"grupo": {"Kael": {"nivel": 4, "exp": 12}}, "inventario": {"oro": 321, "objetos": {"Poción": 3}},
		"cofres_abiertos": {"zona_cofre_1": true}, "pos_zona": Vector2(100, 200), "pos_zona_lugar": 0}


# 8. Sin archivo propio, una prueba no guarda.
func _sin_archivo_propio() -> void:
	var antes := _texto(P.GUARDADO)
	var habia := FileAccess.file_exists(P.GUARDADO)
	Engine.set_meta("partida_lista", true)
	if P.guardar("res://mapa.tscn"):
		fallos.append("8: una prueba sin archivo propio ha guardado")
	if FileAccess.file_exists(P.GUARDADO) != habia or _texto(P.GUARDADO) != antes:
		fallos.append("8: una prueba sin archivo propio ha tocado %s" % P.GUARDADO)
	Engine.remove_meta("partida_lista")
	hechos.append("8 sin archivo propio no guarda")


# 9. Estructura mal (15/11).
func _estructura() -> void:
	var buena := var_to_str(_partida_completa())
	var malas := {
		"grupo como texto": {"grupo": "Kael, Lya y Garon"},
		"héroe como número": {"grupo": {"Kael": 5}},
		"grupo_activo como texto": {"grupo_activo": "Kael"},
		"grupo_activo con un número": {"grupo_activo": ["Kael", 3]},
		"inventario como lista": {"inventario": ["Poción"]},
		"objetos como lista": {"inventario": {"oro": 5, "objetos": ["Poción"]}},
		"cantidad como texto": {"inventario": {"objetos": {"Poción": "tres"}}},
		"oro como texto": {"inventario": {"oro": "mucho"}},
		"hitos como lista": {"hitos": ["pv_01"]},
		"mazmorra como texto": {"mazmorras": {"oakhaven": "abierta"}},
		"pos_mapa como texto": {"pos_mapa": "300,400"},
		"pos_3d como 2D": {"pos_3d": Vector2(1, 2)},
		"prologo como texto": {"prologo_visto": "sí"},
		"escena como número": {"escena_guardada": 7},
	}
	for caso in malas:
		_limpiar()
		var mala := _partida_completa()
		for k in malas[caso]:
			mala[k] = malas[caso][k]
		if P.errores_estructura(mala).is_empty():
			fallos.append("9: «%s» pasa la validación" % caso)
		_poner(ARCHIVO + ".bak", buena)
		_poner(ARCHIVO, var_to_str(mala))
		if P.leer(ARCHIVO) != null:
			fallos.append("9: leer() acepta «%s»" % caso)
		var escena: String = P.cargar()
		if not escena in OAKHAVEN or Engine.get_meta("inventario", {}).get("oro", 0) != 321:
			fallos.append("9: con «%s» no se recupera la copia buena (escena «%s»)" % [caso, escena])
		if not FileAccess.file_exists(ARCHIVO + ".danada"):
			fallos.append("9: con «%s» la mala no se aparta en «.danada»" % caso)
	# guardar sobre una principal mala no la copia en «.bak»
	_limpiar()
	_poner(ARCHIVO, var_to_str({"grupo": "texto"}))
	_poner(ARCHIVO + ".bak", buena)
	if not P.escribir(_partida_completa(), ARCHIVO) or P.leer(ARCHIVO + ".bak") == null:
		fallos.append("9: guardar sobre una principal mala estropea la copia «.bak»")
	# una clave desconocida (versión más nueva) y valores enteros/decimales intercambiados se aceptan
	_limpiar()
	var nueva := _partida_completa()
	nueva["clave_del_futuro"] = ["lo que sea"]
	nueva["pos_zona_lugar"] = 0.0
	nueva["grupo_activo"] = ["Kael", "Lya"]
	nueva["mazmorras"] = {"oakhaven": {"cerradura_vista": true}}
	if not P.errores_estructura(nueva).is_empty():
		fallos.append("9: una partida válida da errores: %s" % [P.errores_estructura(nueva)])
	_poner(ARCHIVO, var_to_str(nueva))
	if P.leer(ARCHIVO) == null:
		fallos.append("9: una clave desconocida hace rechazar la partida")
	hechos.append("9 estructura mal → copia buena y «.danada»")


# 1. Una sesión que no cargó la partida no la pisa.
func _sin_cargar() -> void:
	var completa := var_to_str(_partida_completa())
	_poner(ARCHIVO, completa)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "texto": "x", "tipo": "ciudad", "zona": "ciudad"})
	Engine.set_meta("pos_zona", Vector2(5, 5))           # lo poco que tiene una escena abierta con F6
	if P.guardar("res://zona.tscn"):
		fallos.append("1: sin cargar la partida, guardar() dice que ha guardado")
	if _texto(ARCHIVO) != completa:
		fallos.append("1: sin cargar la partida, la partida ha cambiado")
	if FileAccess.file_exists(ARCHIVO + ".tmp") or FileAccess.file_exists(ARCHIVO + ".bak"):
		fallos.append("1: sin cargar la partida, han aparecido «.tmp» o «.bak»")
	hechos.append("1 sin cargar no pisa")


# 2. Cargar y guardar.
func _cargar_y_guardar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var completa := var_to_str(_partida_completa())
	var escena: String = P.cargar()
	if not escena in OAKHAVEN or not Engine.get_meta("partida_lista", false):
		fallos.append("2: cargar() devuelve «%s» o no deja la partida lista" % escena)
	if Engine.get_meta("grupo", {}).get("Kael", {}).get("nivel", 0) != 4:
		fallos.append("2: cargar() no pone el grupo de la partida")
	inv.ganar_oro(5)
	if not P.guardar("res://mapa.tscn"):
		fallos.append("2: después de cargar, guardar() no guarda")
	var d = P.leer(ARCHIVO)
	if d == null or d.get("escena_guardada") != "res://mapa.tscn" or d.get("inventario", {}).get("oro", 0) != 326:
		fallos.append("2: lo guardado no es lo esperado (%s)" % [d])
	elif not d.has("grupo") or not d.has("cofres_abiertos") or d.has("partida_lista"):
		fallos.append("2: lo guardado pierde claves cargadas o guarda «partida_lista»")
	if _texto(ARCHIVO + ".bak") != completa:
		fallos.append("2: la partida anterior no queda en «.bak»")
	if FileAccess.file_exists(ARCHIVO + ".tmp"):
		fallos.append("2: queda un «.tmp» después de guardar")
	hechos.append("2 cargar y guardar con «.bak»")


# 3. Una partida como la del PC (claves que tiene hoy, sin grupo ni inventario) y un inventario antiguo.
func _partida_del_pc() -> void:
	var pc := {"escena_guardada": "res://zona.tscn", "prologo_visto": true, "pos_mapa": Vector2(300, 400),
		"pos_mapa_ok": true, "pos_zona": Vector2(640, 500), "pos_zona_lugar": 0, "pos_zona_ok": true,
		"lugar": {"indice": 0, "nombre": "Oakhaven", "texto": "x", "tipo": "ciudad", "zona": "ciudad"}}
	_poner(ARCHIVO, var_to_str(pc))
	var escena: String = P.cargar()
	if not escena in OAKHAVEN or Engine.has_meta("grupo") or Engine.has_meta("inventario"):
		fallos.append("3: la partida como la del PC no carga igual (escena «%s»)" % escena)
	var d: Dictionary = inv.datos()
	if not d.has("objetos") or not d.has("equipables") or not d.has("equipo"):
		fallos.append("3: sin inventario guardado, no sale el inicial (%s)" % [d.keys()])
	Engine.set_meta("inventario", {"oro": 50})                  # inventario antiguo, sin lista de objetos
	d = inv.datos()
	if d.get("oro", 0) != 50 or not d.has("objetos") or not d.has("equipables"):
		fallos.append("3: un inventario antiguo no se completa (%s)" % [d])
	else:
		inv.agregar_objeto("Poción", 2)
		if inv.cantidad("Poción") < 2:
			fallos.append("3: con un inventario antiguo no se pueden añadir objetos")
	hechos.append("3 partida como la del PC e inventario antiguo")


# 4. Partida dañada: se recupera la última buena y la dañada se aparta.
func _danada() -> void:
	var buena := var_to_str(_partida_completa())
	_poner(ARCHIVO + ".bak", buena)
	_poner(ARCHIVO, buena.substr(0, 120))                     # cortada: no se puede leer
	var escena: String = P.cargar()
	if not escena in OAKHAVEN or Engine.get_meta("inventario", {}).get("oro", 0) != 321:
		fallos.append("4: con la partida dañada no se recupera la copia buena (escena «%s»)" % escena)
	if _texto(ARCHIVO + ".danada") != buena.substr(0, 120):
		fallos.append("4: la partida dañada no se aparta en «.danada»")
	hechos.append("4 dañada → «.bak» y «.danada»")


# 5. Cortes al guardar.
func _cortes() -> void:
	var buena := var_to_str(_partida_completa())
	_poner(ARCHIVO, buena)
	_poner(ARCHIVO + ".tmp", "{\n\"grupo\": {")                # corte mientras se escribía el «.tmp»
	var escena: String = P.cargar()
	if not escena in OAKHAVEN or Engine.get_meta("inventario", {}).get("oro", 0) != 321:
		fallos.append("5: un «.tmp» a medias estropea la carga")
	_limpiar()
	_poner(ARCHIVO + ".tmp", buena)                           # corte entre quitar la partida y renombrar el «.tmp»
	if not P.hay_partida():
		fallos.append("5: con solo un «.tmp» completo, hay_partida() dice que no hay")
	escena = P.cargar()
	if not escena in OAKHAVEN:
		fallos.append("5: un «.tmp» completo sin la partida no se recupera")
	hechos.append("5 cortes al guardar")


# 6. Escritura fallida: la anterior queda intacta.
func _escritura_fallida() -> void:
	var buena := var_to_str(_partida_completa())
	_poner(ARCHIVO, buena)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(ARCHIVO + ".tmp"))   # no se puede crear el «.tmp»
	var otra := _partida_completa()
	otra["inventario"] = {"oro": 1}
	if P.escribir(otra, ARCHIVO):
		fallos.append("6: escribir() dice que ha guardado sin poder crear el «.tmp»")
	if _texto(ARCHIVO) != buena:
		fallos.append("6: con la escritura fallida, la partida anterior ha cambiado")
	hechos.append("6 escritura fallida")


# 7. Partida nueva: sin archivo, cargar() deja guardar.
func _partida_nueva() -> void:
	if P.hay_partida():
		fallos.append("7: quedan archivos de antes")
	var escena: String = P.cargar()
	if escena != "" or not Engine.get_meta("partida_lista", false):
		fallos.append("7: sin partida, cargar() devuelve «%s» o no deja guardar" % escena)
	Engine.set_meta("prologo_visto", true)
	if not P.guardar("res://mapa.tscn") or P.leer(ARCHIVO) == null:
		fallos.append("7: una partida nueva no se guarda")
	hechos.append("7 partida nueva")
