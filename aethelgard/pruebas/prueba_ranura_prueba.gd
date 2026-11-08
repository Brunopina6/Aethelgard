extends SceneTree
# Prueba de la opción de desarrollo «Probar la misión desde el principio» (carga.gd y progreso.gd), con la exploración
# 3D activa («-- 3d»). Con una partida experimental «de verdad» ya guardada (en la carpeta aislada de la pasada):
#   1. la ranura de prueba usa su propio archivo (partida_exp_prueba.save);
#   2. empieza desde cero: partida nueva con Kael solo, aunque la ranura tuviera una partida anterior;
#   3. guardar en la ranura de prueba no toca la partida experimental de siempre;
#   4. sin la opción, todo vuelve a la partida de siempre.
# La pantalla de carga y su botón se comprueban a mano en el móvil (el botón solo sale en la versión experimental).

var P
var fallos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	if not load("res://modo3d.gd").activo():
		print("FALLO: la exploración 3D no está activa (falta «-- 3d»)")
		quit(1)
		return
	for k in ["archivo_partida_prueba", "ranura_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	# la partida experimental «de verdad» (en la carpeta aislada): misión avanzada y grupo completo
	var siempre := {"grupo": load("res://grupo.gd").datos().duplicate(true), "hitos": {"pv_02": true, "pv_03": true, "pv_05": true},
		"grupo_activo": ["Kael", "Lya", "Garon"], "escena_guardada": "res://mapa.tscn"}
	P.escribir(siempre, P.GUARDADO_EXP)
	var huella := FileAccess.get_file_as_string(P.GUARDADO_EXP)
	# una partida de prueba anterior en la ranura, que tiene que desaparecer
	P.escribir({"hitos": {"pv_02": true}, "escena_guardada": "res://mapa.tscn"}, P.GUARDADO_EXP_PRUEBA)
	P.empezar_ranura_prueba()
	if P.archivo() != P.GUARDADO_EXP_PRUEBA:
		fallos.append("1: la ranura de prueba no usa su archivo (%s)" % P.archivo())
	if FileAccess.file_exists(P.GUARDADO_EXP_PRUEBA):
		fallos.append("2: la ranura de prueba no empieza desde cero")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if P.cargar() != "" or load("res://grupo.gd").activos() != ["Kael"] or P.hito("pv_02"):
		fallos.append("2: la ranura de prueba no es una partida nueva con Kael solo")
	Engine.set_meta("prologo_visto", true)
	if not P.escribir(P.volcar("res://zonas3d/pastos_verdes_3d.tscn"), P.archivo()):
		fallos.append("3: no se pudo guardar en la ranura de prueba")
	if FileAccess.get_file_as_string(P.GUARDADO_EXP) != huella:
		fallos.append("3: guardar en la ranura de prueba ha cambiado la partida de siempre")
	Engine.remove_meta("ranura_prueba")
	if P.archivo() != P.GUARDADO_EXP:
		fallos.append("4: sin la opción no se vuelve a la partida de siempre")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if P.cargar() != "res://mapa.tscn" or load("res://grupo.gd").activos() != ["Kael", "Lya", "Garon"]:
		fallos.append("4: la partida de siempre no se carga como estaba")
	print("OK ranura de prueba: archivo propio, desde cero con Kael solo, y la partida de siempre intacta")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
