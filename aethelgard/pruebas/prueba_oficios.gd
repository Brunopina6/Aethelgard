extends SceneTree
# Oficios de Kael y Garon y el taller conjunto (V9; talleres.gd, investigacion.gd, datos/), sin escenas:
#   1. Antes de resolver lo del Guardián, sus investigaciones están bloqueadas; después, con el musgo, se estudian.
#   2. Kael: «Filo de savia» suma +3 al ataque de verdad (grupo.gd, estadisticas) y «Corte certero» +0,08 de crítico
#      (equipo_extra.gd, efectos_de); cada una se hace una sola vez y gasta lo suyo.
#   3. Garon: «Refuerzo de corteza» +3 de defensa y «Runa de raíz» la coraza al empezar (barrera_inicio).
#   4. Conjunto: no se puede sin las tres investigaciones (Lya, Kael y Garon); con ellas, el Amuleto del claro llega
#      a los equipables.
#   5. Se guarda: escrito y leído, las mejoras, técnicas y recetas hechas siguen; una partida antigua sin ellas carga
#      con todo a cero y las estadísticas de siempre.
# La pantalla de los talleres se pinta con cada taller sin errores.

const ARCHIVO := "user://prueba_oficios.save"
var fallos := 0
var P
var Inv
var I
var T
var G
var X


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _initialize() -> void:
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	I = load("res://investigacion.gd")
	T = load("res://talleres.gd")
	G = load("res://grupo.gd")
	X = load("res://equipo_extra.gd")
	for k in ["hitos", "inventario", "investigaciones", "grupo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.unir("Lya")
	G.unir("Garon")
	_probar.call_deferred()


func _probar() -> void:
	var ataque0: int = G.estadisticas("Kael")["ataque"]
	var defensa0: int = G.estadisticas("Garon")["defensa"]
	var critico0: float = float(X.efectos_de("Kael").get("critico", 0.0))
	# 1
	Inv.agregar_objeto("Musgo de piedra", 6)
	Inv.agregar_objeto("Savia clara", 3)
	Inv.agregar_objeto("Hierba lunar", 6)
	if I.estado("kael_afilado") != "bloqueada" or I.estado("garon_runas") != "bloqueada":
		_fallo("1: los oficios se abren antes de resolver lo del Guardián")
	P.poner_hito("bq_resuelto")
	for id in ["kael_afilado", "garon_runas"]:
		if I.empezar(id) != "":
			_fallo("1: no se puede empezar %s" % id)
		I.avanzar(id, 1)
		if I.estado(id) != "completada":
			_fallo("1: %s no se completa al estudiar" % id)
	if Inv.cantidad("Musgo de piedra") != 6:
		_fallo("1: estudiar gastó musgo")
	# 2
	if not T.fabricar("kael_filo_savia"):
		_fallo("2: no se fabrica el Filo de savia (%s)" % T.puede("kael_filo_savia"))
	if G.estadisticas("Kael")["ataque"] != ataque0 + 3:
		_fallo("2: el ataque de Kael es %d y debía ser %d" % [G.estadisticas("Kael")["ataque"], ataque0 + 3])
	if T.fabricar("kael_filo_savia") or G.estadisticas("Kael")["ataque"] != ataque0 + 3:
		_fallo("2: el Filo de savia se hace dos veces")
	if Inv.cantidad("Musgo de piedra") != 5 or Inv.cantidad("Savia clara") != 2:
		_fallo("2: el Filo de savia no gasta lo suyo")
	T.fabricar("kael_corte_certero")
	if not is_equal_approx(float(X.efectos_de("Kael").get("critico", 0.0)), critico0 + 0.08):
		_fallo("2: el crítico de Kael es %s" % X.efectos_de("Kael").get("critico", 0.0))
	# 3
	T.fabricar("garon_refuerzo_corteza")
	if G.estadisticas("Garon")["defensa"] != defensa0 + 3:
		_fallo("3: la defensa de Garon es %d y debía ser %d" % [G.estadisticas("Garon")["defensa"], defensa0 + 3])
	T.fabricar("garon_runa_raiz")
	if not is_equal_approx(float(X.efectos_de("Garon").get("barrera_inicio", 0.0)), 0.1):
		_fallo("3: la Runa de raíz no da la coraza al empezar")
	# 4
	if T.puede("amuleto_claro") == "":
		_fallo("4: el amuleto se puede hacer sin la investigación de Lya")
	Engine.get_meta("investigaciones")["lya_savia"] = {"progreso": 2, "completada": true}
	I.empezar("conjunto_bosque")
	I.avanzar("conjunto_bosque", 1)
	if not T.fabricar("amuleto_claro") or not "amuleto_claro" in Inv.datos()["equipables"]:
		_fallo("4: el Amuleto del claro no llega (%s)" % T.puede("amuleto_claro"))
	# 5
	var d: Dictionary = P.volcar("res://mapa.tscn")
	P.escribir(d, ARCHIVO)
	var leida = P.leer(ARCHIVO)
	Engine.remove_meta("inventario")
	P.restaurar(leida)
	if G.estadisticas("Kael")["ataque"] != ataque0 + 3 or G.estadisticas("Garon")["defensa"] != defensa0 + 3:
		_fallo("5: las mejoras no sobreviven a guardar y cargar")
	if not "kael_filo_savia" in Inv.datos()["hechas"]:
		_fallo("5: no se guarda qué recetas están hechas")
	P.restaurar({"escena_guardada": "res://mapa.tscn"})            # partida antigua
	if not Inv.datos().get("mejoras", null) is Dictionary or not Inv.datos()["mejoras"].is_empty():
		_fallo("5: una partida antigua no empieza sin mejoras")
	if G.estadisticas("Kael")["ataque"] != ataque0:
		_fallo("5: con una partida antigua el ataque de Kael cambia")
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	# pantallas
	for t in ["alquimia", "forja", "armaduras", "conjunto"]:
		var a = load("res://alquimia_menu.gd").new()
		a.taller = t
		root.add_child(a)
		for p in ["Recetas", "Investigar", "Materiales"]:
			a.pestana = p
			a._pintar()
			await process_frame
		a.queue_free()
		await process_frame
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
