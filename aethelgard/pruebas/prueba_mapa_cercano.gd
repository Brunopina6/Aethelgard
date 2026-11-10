extends SceneTree
# El mapa ofrece el lugar MÁS CERCANO cuando los radios de dos lugares se solapan (10/11, auditoría de mapa.gd:
# _comprobar_cerca). Con las posiciones reales de Portal del Vacío (650, 405) y Pastos Verdes (660, 478), que están a
# unos 74 px con radios de 70, en la lista que usa la exploración 3D (LUGARES + LUGAR_PASTOS). Sin escenas ni datos.

var M
var fallos := 0


func _initialize() -> void:
	M = load("res://mapa.gd")
	_probar()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _nombre(l) -> String:
	return "nada" if l == null else String(l["nombre"])


# Lo de antes: el último de la lista dentro del radio (solo para demostrar que la prueba detecta el fallo).
func _antes(pos: Vector2, lista: Array, radio: float):
	var mejor = null
	for l in lista:
		if pos.distance_to(l["pos"]) < radio:
			mejor = l
	return mejor


func _probar() -> void:
	var lista: Array = M.LUGARES + [M.LUGAR_PASTOS]
	var r: float = M.RADIO_LUGAR
	var portal: Vector2 = Vector2.ZERO
	for l in lista:
		if l["nombre"] == "Portal del Vacío":
			portal = l["pos"]
	var pastos: Vector2 = M.LUGAR_PASTOS["pos"]
	if portal == Vector2.ZERO or portal.distance_to(pastos) >= 2.0 * r:
		_fallo("los datos ya no tienen dos lugares con radios solapados (portal %s, pastos %s)" % [portal, pastos])
		return
	var casos := [
		[portal, "Portal del Vacío"],
		[pastos, "Pastos Verdes"],
		[portal.lerp(pastos, 0.30), "Portal del Vacío"],   # dentro de los dos radios, más cerca del portal
		[portal.lerp(pastos, 0.70), "Pastos Verdes"],       # dentro de los dos radios, más cerca de Pastos
		[Vector2(40, 40), "nada"],                         # en el océano, fuera de todo radio
	]
	var detecta_lo_de_antes := false
	for c in casos:
		var pos: Vector2 = c[0]
		var hoy := _nombre(M.lugar_mas_cercano(pos, lista, r))
		if hoy != c[1]:
			_fallo("en %s ofrece «%s» y lo más cercano es «%s»" % [pos, hoy, c[1]])
		if _nombre(_antes(pos, lista, r)) != c[1]:
			detecta_lo_de_antes = true
	if not detecta_lo_de_antes:
		_fallo("ningún caso distingue el comportamiento anterior: la prueba no protegería de volver a él")
	# El orden de la lista no debe importar
	var al_reves := lista.duplicate()
	al_reves.reverse()
	if _nombre(M.lugar_mas_cercano(portal.lerp(pastos, 0.70), al_reves, r)) != "Pastos Verdes":
		_fallo("con la lista al revés cambia el lugar ofrecido")
