extends SceneTree
# V12 (14/11), fase 3B del encargo coordinador: SOLO Lya invoca. En un combate de verdad con Kael y Lya (datos
# aislados):
#   - el menú de Kael NO tiene la orden INVOCACIÓN (ni apagada), aunque la Armonía esté llena y Lya en pie;
#   - el de Lya sí la tiene, y abierta con la Armonía llena;
#   - aunque se llame a la acción a mano con Kael de actor (atajo, prueba antigua), no se invoca: no hay teatro de
#     Érebo, la Armonía no se gasta y vuelve el menú.
#   - el HUD de la Armonía («INVOCACIÓN LISTA») sigue igual: es de Lya.

const ARCHIVO := "user://prueba_solo_lya_invoca.save"

var P
var G
var c = null
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _tipos_menu() -> Array:
	var r := []
	for f in c.menu.filas:
		r.append(f["item"].get("tipo", f["item"].get("texto", "")))
	return r


func _hasta_turno_de(nombre: String) -> bool:
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == nombre:
				return true
			c._defender()
		await _esperar(1)
	return false


func _probar() -> void:
	await _esperar(10)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 9)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	c.armonia = 1.0

	_ok(await _hasta_turno_de("Kael"), "no llega el turno de Kael")
	c.armonia = 1.0
	c._mostrar_menu()
	await _esperar(2)
	_ok(not ("invocacion" in _tipos_menu()), "el menú de Kael tiene INVOCACIÓN: %s" % [_tipos_menu()])
	_ok(c._estado_invocacion()["lista"], "con la Armonía llena y Lya en pie, la invocación de Lya debería estar lista")
	# acceso directo con Kael de actor (atajos o preparaciones antiguas): no debe invocar
	c._invocar()
	await _esperar(3)
	_ok(c.estado == "menu", "_invocar con Kael abre algo (estado %s)" % c.estado)
	c._invocar_sobre(c.enemigos[0])
	await _esperar(10)
	_ok(c.inv_erebo == null, "_invocar_sobre con Kael de actor lanza a Érebo")
	_ok(is_equal_approx(c.armonia, 1.0), "con Kael de actor se gasta la Armonía (%s)" % c.armonia)
	hechos.append("Kael sin invocación")

	c._defender()
	_ok(await _hasta_turno_de("Lya"), "no llega el turno de Lya")
	c.armonia = 1.0
	c._mostrar_menu()
	await _esperar(2)
	_ok("invocacion" in _tipos_menu(), "el menú de Lya no tiene INVOCACIÓN: %s" % [_tipos_menu()])
	var abierta := false
	for f in c.menu.filas:
		if f["item"].get("tipo", "") == "invocacion":
			abierta = not f["item"].get("apagado", false)
	_ok(abierta, "la INVOCACIÓN de Lya está apagada con la Armonía llena")
	hechos.append("Lya con invocación")

	c.queue_free()
	c = null
	await _esperar(5)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
