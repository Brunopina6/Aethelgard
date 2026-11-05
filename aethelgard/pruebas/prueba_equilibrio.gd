extends SceneTree
# Mide el daño medio de Kael y Lya (golpe y magia Fuego I) y prueba la Congelación y el modo pruebas.

var c: Node
var frames := 0


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


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
	print("golpe Kael / Lya = %.2f   magia Lya / Kael = %.2f" % [res["Kael"][0] / res["Lya"][0], res["Lya"][1] / res["Kael"][1]])
	var kael: Dictionary = c.heroes[0]
	var antes: int = kael["mp"]
	c._gastar_pm(kael, 8)
	print("modo pruebas: PM antes ", antes, " después ", kael["mp"])
	var e: Dictionary = c.enemigos[0]
	print("frostfang equipada: ", c._lleva_frostfang(kael), "  enemigo ", e["nombre"], " PV máx ", e["hp_max"])
	c._congelar(e)
	print("congelado: PV máx ", e["hp_max"], " rondas ", e["congelado"], " estado '", e["lbl_estado"].text, "'")
	c._tic_congelacion(e)
	c._tic_congelacion(e)
	print("tras 2 rondas: PV máx ", e["hp_max"], " rondas ", e["congelado"])
	return true
