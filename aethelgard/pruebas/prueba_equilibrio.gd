extends SceneTree
# Equilibrio del combate (10/11: antes solo imprimía y nunca fallaba). Con semilla fija. Comprueba lo aprobado:
#   1. D-H07: el golpe de Kael vale unas 5 veces el de Lya, y la magia (Fuego I) de Lya unas 3 veces la de Kael
#      (margen ±10 %, por el azar del golpe).
#   2. Sin «pm_infinitos», gastar 8 PM quita 8 PM (los PM infinitos solo con su argumento).
#   3. Kael empieza con Frostfang.
#   4. Congelación: baja los PV máximos del enemigo mientras dura (2 rondas) y los devuelve al acabar.
# Sigue imprimiendo los valores, como antes.

var c: Node
var frames := 0
var fallos := 0


func _initialize() -> void:
	seed(7)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _entre(v: float, objetivo: float, margen: float) -> bool:
	return absf(v - objetivo) <= objetivo * margen


func _process(_d: float) -> bool:
	frames += 1
	if frames < 5:
		return false
	var d: Dictionary = c.NIVELES_MAGIA["Fuego"][0]
	var res := {}
	for h in c.heroes:
		var fis := 0.0
		var mag := 0.0
		for i in 400:
			fis += maxi(1, int(h["atk"] * h.get("mult_fisico", 1.0))) + randi_range(-2, 3)
			mag += c._dano_magia(h, d)
		res[h["nombre"]] = [fis / 400.0, mag / 400.0]
		print("%s  golpe medio %.1f   Fuego medio %.1f   PM %d/%d" % [h["nombre"], fis / 400.0, mag / 400.0, h["mp"], h["mp_max"]])
	if not (res.has("Kael") and res.has("Lya")):
		_fallo("faltan Kael o Lya en el combate de prueba (%s)" % [res.keys()])
	else:
		var golpe: float = res["Kael"][0] / res["Lya"][0]
		var magia: float = res["Lya"][1] / res["Kael"][1]
		print("golpe Kael / Lya = %.2f   magia Lya / Kael = %.2f" % [golpe, magia])
		if not _entre(golpe, 5.0, 0.10):
			_fallo("D-H07: el golpe de Kael vale %.2f veces el de Lya (aprobado: unas 5)" % golpe)
		if not _entre(magia, 3.0, 0.10):
			_fallo("D-H07: la magia de Lya vale %.2f veces la de Kael (aprobado: unas 3)" % magia)
	var kael: Dictionary = c.heroes[0]
	var antes: int = kael["mp"]
	c._gastar_pm(kael, 8)
	print("modo pruebas: PM antes ", antes, " después ", kael["mp"])
	if not "pm_infinitos" in OS.get_cmdline_user_args() and int(kael["mp"]) != antes - 8:
		_fallo("gastar 8 PM deja %d (de %d)" % [kael["mp"], antes])
	var e: Dictionary = c.enemigos[0]
	print("frostfang equipada: ", c._lleva_frostfang(kael), "  enemigo ", e["nombre"], " PV máx ", e["hp_max"])
	if not c._lleva_frostfang(kael):
		_fallo("Kael no empieza con Frostfang")
	var max0: int = e["hp_max"]
	c._congelar(e)
	print("congelado: PV máx ", e["hp_max"], " rondas ", e["congelado"], " estado '", e["lbl_estado"].text, "'")
	if int(e["congelado"]) != 2 or int(e["hp_max"]) >= max0 or not "Congelado" in String(e["lbl_estado"].text):
		_fallo("la Congelación no se aplica: PV máx %d (antes %d), rondas %d, estado «%s»" % [e["hp_max"], max0, e["congelado"], e["lbl_estado"].text])
	c._tic_congelacion(e)
	c._tic_congelacion(e)
	print("tras 2 rondas: PV máx ", e["hp_max"], " rondas ", e["congelado"])
	if int(e["congelado"]) != 0 or int(e["hp_max"]) != max0:
		_fallo("tras 2 rondas, la Congelación no se va: PV máx %d (antes %d), rondas %d" % [e["hp_max"], max0, e["congelado"]])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
