extends SceneTree
# Tienda de Oakhaven tras el Guardián del Bosque (fase 3; tienda.gd, objetos_de): sin resolver, lo de siempre;
# purificado, también Hierba lunar (15) y Savia clara (30); derrotado, solo Hierba lunar; en otro lugar, nada nuevo.
# Ninguna se compra más barata de lo que paga la tienda por ella (sin dinero gratis). Sin escenas.

var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _initialize() -> void:
	var T = load("res://tienda.gd")
	var P = load("res://progreso.gd")
	var Extra = load("res://equipo_extra.gd")
	Engine.set_meta("hitos", {})
	if T.objetos_de(0) != T.OBJETOS:
		_fallo("sin resolver, la tienda cambia: %s" % [T.objetos_de(0)])
	P.poner_hito("bq_purificado")
	var o: Dictionary = T.objetos_de(0)
	if o.get("Hierba lunar", 0) != 15 or o.get("Savia clara", 0) != 30:
		_fallo("purificado: %s" % [o])
	if T.objetos_de(5) != T.OBJETOS:
		_fallo("las hierbas salen fuera de Oakhaven")
	Engine.set_meta("hitos", {"bq_derrotado": true})
	o = T.objetos_de(0)
	if o.get("Hierba lunar", 0) != 15 or o.has("Savia clara"):
		_fallo("derrotado: %s" % [o])
	var mats: Dictionary = Extra.materiales()
	for d in T.OBJETOS_BOSQUE:
		for m in T.OBJETOS_BOSQUE[d]:
			if int(T.OBJETOS_BOSQUE[d][m]) <= int(mats[m]["venta"]):
				_fallo("%s se compra por %d y se vende por %d" % [m, T.OBJETOS_BOSQUE[d][m], mats[m]["venta"]])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
