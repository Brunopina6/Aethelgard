extends SceneTree
# Prueba de las protecciones del guardado (progreso.gd; TASKS.md, T-076 y T-077), con partidas sintéticas en un archivo
# propio (user://prueba_partida.save): nunca toca la partida de verdad. Con la exploración 3D activa («-- 3d»).
#   1. Una sesión que no cargó la partida (una escena abierta directamente) no la pisa con datos a medias.
#   2. Guardar y cargar conserva el grupo, el inventario, el cofre abierto, la misión avanzada y la posición tras un
#      combate; al guardar encima, la anterior queda en «.bak».
#   3. Una partida antigua, sin las claves nuevas ni la lista de objetos, carga con los valores por defecto, y el
#      premio de un cofre se puede dar.
#   4. Si la partida está dañada, se recupera la última buena («.bak») y la dañada se aparta («.danada»).
#   5. Si no se puede escribir, la partida anterior queda intacta y el jugador recibe un aviso.
#   6. Un corte al guardar: un «.tmp» a medias no estropea la carga, y uno completo sin la partida se recupera.
#   7. La partida y su copia «.bak», las dos dañadas: se apartan las dos («.danada» y «.bak.danada»), el jugador recibe
#      un aviso y empieza una partida nueva (en la versión experimental, con Kael solo).
#   8. Partida nueva (sin ningún archivo): carga sin avisos y el primer guardado crea la partida.
# Lo comprobado reduce el riesgo de perder la partida; no lo elimina (p. ej., un fallo del disco en el peor momento).

const ARCHIVO := "user://prueba_partida.save"
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const COFRE := "pastos3d_arbol_magico"

var P
var inv
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	inv = load("res://inventario.gd")
	if not load("res://modo3d.gd").activo():
		print("FALLO: la exploración 3D no está activa (falta «-- 3d»)")
		quit(1)
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	if P.archivo() != ARCHIVO:
		print("FALLO: la prueba no usa su propio archivo, sino %s" % P.archivo())
		quit(1)
		return
	_borrar_archivos()
	_sesion_sin_cargar()
	_guardar_y_cargar()
	_partida_antigua()
	_partida_danada()
	_escritura_fallida()
	_corte_al_guardar()
	_ambas_danadas()
	_partida_nueva()
	_borrar_archivos()
	_limpiar_metas()
	Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# Una partida avanzada: grupo a nivel 7, oro y objetos, el cofre de Pastos Verdes abierto, la misión hasta PV-07, el
# centinela vencido y Kael en el mirador al volver del combate.
func _partida_completa() -> Dictionary:
	_limpiar_metas()
	var g: Dictionary = load("res://grupo.gd").datos()
	for n in g:
		g[n]["nivel"] = 7
		g[n]["exp"] = 123
	var d: Dictionary = inv.datos()
	d["oro"] = 1234
	d["objetos"] = {"Poción": 9, "Éter": 4}
	Engine.set_meta("cofres_abiertos", {COFRE: true, "1_640_320": true})
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true, "pv_06": true, "pv_07": true})
	Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	Engine.set_meta("pos_3d", Vector3(3.1, 0.2, -9.8))
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", 10)
	Engine.set_meta("prologo_visto", true)
	return P.volcar(REGION).duplicate(true)


func _sesion_sin_cargar() -> void:
	var completa := _partida_completa()
	if not P.escribir(completa, ARCHIVO):
		fallos.append("1: no se pudo escribir la partida de partida")
		return
	var antes := FileAccess.get_file_as_string(ARCHIVO)
	_limpiar_metas()                                  # una escena abierta directamente: sin cargar la partida
	load("res://grupo.gd").datos()                    # el grupo por defecto, a nivel 1
	inv.ganar_oro(5)
	if P.guardar(REGION):
		fallos.append("1: una sesión que no cargó la partida la ha sustituido")
	if FileAccess.get_file_as_string(ARCHIVO) != antes:
		fallos.append("1: la partida completa ha cambiado")
	if FileAccess.file_exists(ARCHIVO + ".bak"):
		fallos.append("1: se ha creado una copia «.bak» sin guardar")
	print("1. Sesión sin cargar: no guarda y la partida completa sigue igual")


func _guardar_y_cargar() -> void:
	var completa := _partida_completa()
	_borrar_archivos()
	P.escribir(completa, ARCHIVO)
	_limpiar_metas()
	var escena: String = P.cargar()
	if escena != REGION:
		fallos.append("2: al cargar se vuelve a «%s» y no a la región" % escena)
	for k in completa:
		if var_to_str(Engine.get_meta(k, null)) != var_to_str(completa[k]):
			fallos.append("2: «%s» no se recupera igual" % k)
	if not Engine.get_meta("cofres_abiertos", {}).has(COFRE) or not P.hito("pv_07") or not P.ganado("pastos_centinela"):
		fallos.append("2: el cofre, la misión o el centinela no se recuperan")
	inv.ganar_oro(5)
	if not P.guardar(REGION):
		fallos.append("2: tras cargar, guardar() no escribe")
	if P.leer(ARCHIVO + ".bak") == null or var_to_str(P.leer(ARCHIVO + ".bak")) != var_to_str(completa):
		fallos.append("2: la partida anterior no queda en «.bak»")
	var nueva = P.leer(ARCHIVO)
	if nueva == null or nueva["inventario"]["oro"] != 1239:
		fallos.append("2: la partida nueva no tiene el oro nuevo")
	print("2. Guardar y cargar: grupo, inventario, cofre, misión y posición tras el combate; la anterior en «.bak»")


func _partida_antigua() -> void:
	_borrar_archivos()
	_limpiar_metas()
	var antigua := {"grupo": {"Kael": {"nivel": 3, "exp": 10, "puntos": 0, "atributos": {"fuerza": 18, "magia": 4,
		"defensa": 6, "velocidad": 22, "vitalidad": 10, "espiritu": 4}, "pv": -1, "pm": -1}},
		"inventario": {"oro": 50}, "escena_guardada": "res://mapa.tscn"}
	P.escribir(antigua, ARCHIVO)
	var escena: String = P.cargar()
	if escena != "res://mapa.tscn":
		fallos.append("3: una partida antigua vuelve a «%s» y no al mapa" % escena)
	if P.hito("pv_02") or Engine.get_meta("cofres_abiertos", {}).has(COFRE) or Engine.get_meta("pos_3d_ok", false):
		fallos.append("3: una partida antigua trae hitos, cofres o posición 3D que no tenía")
	inv.agregar_objeto("Poción", 2)                   # el premio de un cofre, sin lista de objetos en la partida
	if inv.cantidad("Poción") != 7 or inv.oro() != 50:
		fallos.append("3: con la partida antigua, el inventario da %d Pociones y %d de oro" % [inv.cantidad("Poción"), inv.oro()])
	if load("res://grupo.gd").miembros().size() != 3:
		fallos.append("3: el grupo de una partida antigua no se completa con Lya y Garon")
	if not P.guardar("res://mapa.tscn") or P.leer(ARCHIVO) == null:
		fallos.append("3: la partida antigua no se puede volver a guardar")
	print("3. Partida antigua: valores por defecto, inventario completado y guardado")


func _partida_danada() -> void:
	_borrar_archivos()
	var completa := _partida_completa()
	P.escribir(completa, ARCHIVO)
	var segunda := completa.duplicate(true)
	segunda["inventario"]["oro"] = 2000
	P.escribir(segunda, ARCHIVO)                      # ahora «.bak» es la completa
	var f := FileAccess.open(ARCHIVO, FileAccess.WRITE)
	f.store_string(var_to_str(segunda).substr(0, 120))   # cortada: no se puede leer
	f.close()
	_limpiar_metas()
	var escena: String = P.cargar()
	if escena != REGION or inv.oro() != 1234:
		fallos.append("4: con la partida dañada no se recupera la copia buena (escena «%s», oro %d)" % [escena, inv.oro()])
	if not FileAccess.file_exists(ARCHIVO + ".danada"):
		fallos.append("4: la partida dañada no se aparta en «.danada»")
	if not Engine.get_meta("ultimo_aviso_partida", "").begins_with("La partida guardada estaba dañada"):
		fallos.append("4: el jugador no recibe aviso de la copia recuperada («%s»)" % Engine.get_meta("ultimo_aviso_partida", ""))
	if not P.guardar(REGION) or P.leer(ARCHIVO) == null:
		fallos.append("4: tras recuperar la copia, no se puede guardar")
	if var_to_str(P.leer(ARCHIVO + ".bak")) != var_to_str(completa):
		fallos.append("4: al guardar se ha perdido la copia buena de «.bak»")
	print("4. Partida dañada: se recupera «.bak» y la dañada queda en «.danada»")


func _escritura_fallida() -> void:
	_borrar_archivos()
	var completa := _partida_completa()
	P.escribir(completa, ARCHIVO)
	var antes := FileAccess.get_file_as_string(ARCHIVO)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(ARCHIVO + ".tmp"))   # «.tmp» no se puede abrir
	Engine.set_meta("partida_lista", true)
	inv.ganar_oro(1)
	if Engine.has_meta("ultimo_aviso_partida"):
		Engine.remove_meta("ultimo_aviso_partida")
	if P.guardar(REGION):
		fallos.append("5: guardar() dice que ha guardado sin poder escribir")
	if FileAccess.get_file_as_string(ARCHIVO) != antes:
		fallos.append("5: tras fallar la escritura, la partida ha cambiado")
	if Engine.get_meta("ultimo_aviso_partida", "") != P.AVISO_NO_GUARDA:
		fallos.append("5: el jugador no recibe aviso de que no se pudo guardar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + ".tmp"))
	print("5. Escritura fallida: la partida anterior queda intacta")


func _corte_al_guardar() -> void:
	_borrar_archivos()
	var completa := _partida_completa()
	P.escribir(completa, ARCHIVO)
	var f := FileAccess.open(ARCHIVO + ".tmp", FileAccess.WRITE)
	f.store_string("{\n\"grupo\": {")              # corte mientras se escribía el «.tmp»
	f.close()
	_limpiar_metas()
	if P.cargar() != REGION or inv.oro() != 1234:
		fallos.append("6: un «.tmp» a medias estropea la carga")
	_borrar_archivos()
	var g := FileAccess.open(ARCHIVO + ".tmp", FileAccess.WRITE)
	g.store_string(var_to_str(completa))             # corte entre quitar la partida y renombrar el «.tmp»
	g.close()
	_limpiar_metas()
	if P.cargar() != REGION or inv.oro() != 1234:
		fallos.append("6: un «.tmp» completo sin la partida no se recupera")
	print("6. Corte al guardar: «.tmp» a medias ignorado y «.tmp» completo recuperado")


func _ambas_danadas() -> void:
	_borrar_archivos()
	var completa := _partida_completa()
	P.escribir(completa, ARCHIVO)
	P.escribir(completa, ARCHIVO)                     # ya hay «.bak»
	for extra in ["", ".bak"]:
		var f := FileAccess.open(ARCHIVO + extra, FileAccess.WRITE)
		f.store_string("{\n\"grupo\": {\"Kael\"")    # las dos, cortadas
		f.close()
	_limpiar_metas()
	if P.cargar() != "":
		fallos.append("7: con las dos copias dañadas no empieza una partida nueva")
	for extra in [".danada", ".bak.danada"]:
		if not FileAccess.file_exists(ARCHIVO + extra):
			fallos.append("7: no se aparta la copia dañada «%s»" % extra)
	if not Engine.get_meta("ultimo_aviso_partida", "").begins_with("No se pudo leer la partida"):
		fallos.append("7: el jugador no recibe aviso de que empieza una partida nueva")
	if load("res://grupo.gd").activos() != ["Kael"]:
		fallos.append("7: la partida nueva de la versión experimental no empieza con Kael solo")
	print("7. Las dos dañadas: se apartan las dos, aviso y partida nueva con Kael solo")


func _partida_nueva() -> void:
	_borrar_archivos()
	_limpiar_metas()
	if Engine.has_meta("ultimo_aviso_partida"):
		Engine.remove_meta("ultimo_aviso_partida")
	if P.cargar() != "" or Engine.has_meta("ultimo_aviso_partida"):
		fallos.append("8: sin archivos, la carga da una escena o un aviso")
	if not P.guardar("res://mapa.tscn") or P.leer(ARCHIVO) == null:
		fallos.append("8: el primer guardado de una partida nueva no crea la partida")
	elif P.leer(ARCHIVO).get("grupo_activo", []) != ["Kael"]:
		fallos.append("8: la partida nueva no guarda el grupo de Kael solo")
	print("8. Partida nueva: sin avisos, y el primer guardado crea la partida con Kael solo")


func _limpiar_metas() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if Engine.has_meta("partida_lista"):
		Engine.remove_meta("partida_lista")


func _borrar_archivos() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		var r := ProjectSettings.globalize_path(ARCHIVO + extra)
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(r)
		elif DirAccess.dir_exists_absolute(r):
			DirAccess.remove_absolute(r)
