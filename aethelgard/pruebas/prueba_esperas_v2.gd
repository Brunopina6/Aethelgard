extends SceneTree
# Esperas de exploración y héroes v2/v3 (13/11, hallado en el Redmi con la v688): las esperas (animaciones/esperas/*.res)
# se hicieron con el esqueleto de los protagonistas originales; puestas en un v2 o un v3, tumbaban al héroe a los pocos
# segundos de quedarse quieto en la exploración. Comprueba que los originales siguen teniendo sus esperas y que los v2 y
# los v3 no las activan (hasta que tengan esperas hechas para su esqueleto). Sin ventana. Imprime «FALLOS: n».

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const ORIGINALES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}

var fallos := 0


func _ok(cond: bool, texto: String) -> void:
	if cond:
		print("  ok  ", texto)
	else:
		fallos += 1
		print("  FALLO ", texto)


func _initialize() -> void:
	_principal.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# Crea el héroe con ese script, enciende las esperas como la exploración y dice si las tiene.
func _probar(ruta: String) -> Array:
	var n: Node3D = load(ruta).new()
	root.add_child(n)
	await _frames(8)
	var si: bool = n.activar_esperas(true)
	var tiene: bool = n.get("esperas") != null
	await _frames(2)
	n.queue_free()
	await _frames(2)
	return [si, tiene]


func _principal() -> void:
	await _frames(3)
	print("== originales: con sus esperas")
	for h in ORIGINALES:
		var r: Array = await _probar(ORIGINALES[h])
		_ok(r[0] and r[1], "%s original: esperas activas" % h)
	print("== v2: sin las esperas de los originales")
	Engine.set_meta("heroes_v2", true)
	for h in ORIGINALES:
		if not ResourceLoader.exists(HeroesV2.GLB[h]):
			continue
		var r: Array = await _probar(HeroesV2.SCRIPTS[ORIGINALES[h]])
		_ok(not r[0] and not r[1], "%s v2: no activa las esperas de los originales" % h)
	print("== v3 (heredan del v2)")
	Engine.set_meta("heroes_version", "v3")
	for h in ORIGINALES:
		var ruta: String = HeroesV3.SCRIPTS.get(ORIGINALES[h], "")
		if ruta == "" or not ResourceLoader.exists(ruta):
			continue
		var r: Array = await _probar(ruta)
		_ok(not r[0] and not r[1], "%s v3: no activa las esperas de los originales" % h)
	Engine.remove_meta("heroes_version")
	Engine.remove_meta("heroes_v2")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
