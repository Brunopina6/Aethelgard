extends SceneTree
# Recompensas del combate (fase 2, 10/11; combate_recompensas.gd): las cuentas separadas de combate.gd dan lo mismo
# que el código de antes, copiado aquí tal cual, en 2000 casos al azar (semilla fija) y en los bordes (sin enemigos,
# todos huidos, sin experiencia, caídos con cantidades impares y multiplicadores que redondean a .5).

var R
var fallos := 0


func _initialize() -> void:
	R = load("res://combate_recompensas.gd")
	var azar := RandomNumberGenerator.new()
	azar.seed = 2026
	var casos: Array = [[], [{"exp": 10, "oro": 5, "huido": true}], [{"exp": 0, "oro": 0}], [{}]]
	for i in 2000:
		var lista: Array = []
		for j in azar.randi_range(0, 4):
			var e := {"exp": azar.randi_range(0, 400), "oro": azar.randi_range(0, 300)}
			if azar.randf() < 0.2:
				e["huido"] = true
			lista.append(e)
		casos.append(lista)
	for lista in casos:
		var antes := _antes_total(lista)
		var ahora: Dictionary = R.de_enemigos(lista)
		if ahora["exp"] != antes[0] or ahora["oro"] != antes[1]:
			_fallo("de_enemigos(%s) = %s y antes %s" % [lista, ahora, antes])
	for total in [0, 1, 7, 13, 99, 250, 1001]:
		for mult in [0.0, 0.1, 0.5, 1.0, 1.5, 2.5, 3.0, 0.25, 1.1]:
			for caido in [false, true]:
				var antes := _antes_heroe(total, mult, caido)
				var ahora: int = R.exp_de_heroe(total, mult, caido)
				if ahora != antes:
					_fallo("exp_de_heroe(%d, %s, %s) = %d y antes %d" % [total, mult, caido, ahora, antes])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	if fallos < 20:
		print("FALLO: ", t)


# combate.gd _repartir_exp antes de la fase 2 (2889213), sin cambios.
func _antes_total(enemigos: Array) -> Array:
	var total := 0
	var oro := 0
	for e in enemigos:
		if e.get("huido", false):
			continue
		total += int(e.get("exp", 0))
		oro += int(e.get("oro", 0))
	return [total, oro]


func _antes_heroe(total: int, mult: float, caido: bool) -> int:
	var cantidad := int(round(total * mult))
	if caido:
		return cantidad / 2
	return cantidad
