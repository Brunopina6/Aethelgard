extends SceneTree
# V12 (18/11/2026): el caso «Derrotas: los héroes empiezan casi sin vida» del BANCO DE PRUEBAS (banco_pruebas.gd), para
# ver en el Redmi las derrotas de los héroes (REDMI_18_11.md: en el caso del Custodio nadie caía). Sin ventana, con datos
# aislados, con el flujo de verdad: la pantalla del banco → su botón (_combate) → combate.tscn → vuelta al banco.
#   - Con «Protagonistas» Originales, v2 y v3 (el selector de arriba) y con el caso de Naira y Nix:
#     los héroes entran con 1 PV, nadie abre su menú, los enemigos golpean y CADA héroe llega a 0 PV y ejecuta su
#     morir() (_muerta en su modelo 3D); al caer todos, la derrota («Derrota...») y la vuelta sola al banco, que rehace
#     su partida (grupo de partida, sin Naira ni Nix ni sus interruptores).
#   - Nada fuera del banco: las partidas de siempre no cambian (ni existen si no existían); Ajustes se deja como estaba.
#   - Fuera del banco, el mismo caso no hace nada (el gancho preparar_combate no toca los PV).

const BP_RUTA := "res://banco_pruebas.gd"
const LIMITE_COMBATE := 60.0                       # segundos reales hasta la derrota
const LIMITE_ESCENA := 30.0                        # segundos reales para cada cambio de escena
var BP
var P
var G
var HV
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	BP = load(BP_RUTA)
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	HV = load("res://personajes/heroes_v2/heroes_v2.gd")
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _huella(ruta: String) -> String:
	return FileAccess.get_sha256(ruta) if FileAccess.file_exists(ruta) else "(no existe)"


# Espera a que la escena actual sea «ruta» (y haya terminado el cambio). Devuelve la escena o null.
func _esperar_escena(ruta: String, limite: float) -> Node:
	var t0 := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - t0) / 1000.0 < limite:
		await process_frame
		var esc := current_scene
		var rec = root.get_node_or_null("Recursos")  # (autoload: en un SceneTree de prueba no se nombra al compilar)
		if esc != null and esc.scene_file_path == ruta and (rec == null or not rec.cambiando) and esc.is_node_ready():
			return esc
	return null


func _probar() -> void:
	await _esperar(5)
	var ajustes_antes = FileAccess.get_file_as_bytes("user://ajustes.cfg") if FileAccess.file_exists("user://ajustes.cfg") else null
	var version_antes: String = HV.version()
	var reales := {}
	for r in [P.GUARDADO, P.GUARDADO_EXP, P.GUARDADO + ".bak", P.GUARDADO_EXP + ".bak"]:
		reales[r] = _huella(r)
	_ok(BP.COMBATES.has("derrotas") and BP.COMBATES.has("derrotas_reclutas"), "el banco no tiene los casos de derrotas")

	# Fuera del banco, el gancho no toca nada aunque quede el caso puesto
	await _fuera_del_banco()

	# La pantalla del banco, como escena actual (como al entrar desde la pantalla de carga)
	var b = load(BP.ESCENA).instantiate()
	root.add_child(b)
	current_scene = b
	await _esperar(3)
	_ok(_hay_boton(b, "caso:derrotas") and _hay_boton(b, "caso:derrotas_reclutas"), "los botones de los casos de derrotas no salen")
	for v in ["originales", "v2", "v3"]:
		HV.elegir_version(v)                         # (lo que hace el selector «Protagonistas»)
		await _caso("derrotas", ["Kael", "Lya", "Garon"], v)
	HV.elegir_version("originales")
	await _caso("derrotas_reclutas", ["Kael", "Naira", "Nix"], "originales")

	# Fin: se sale del banco y se deja todo como estaba
	BP.salir()
	if current_scene != null:
		current_scene.queue_free()
	await _esperar(4)
	HV.elegir_version(version_antes)
	Engine.remove_meta("heroes_version")
	if ajustes_antes != null:
		var f := FileAccess.open("user://ajustes.cfg", FileAccess.WRITE)
		f.store_buffer(ajustes_antes)
		f.close()
	elif FileAccess.file_exists("user://ajustes.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ajustes.cfg"))
	for r in reales:
		_ok(_huella(r) == reales[r], "la partida de siempre %s cambió" % r)
	hechos.append("las partidas de siempre (%d archivos) no cambian" % reales.size())
	print("OK: ", "\n    ".join(hechos))
	for x in fallos:
		print("FALLO: ", x)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _hay_boton(n: Node, clave: String) -> bool:
	for c in n.get_children():
		if c is Button and c.get_meta("clave", "") == clave:
			return true
		if _hay_boton(c, clave):
			return true
	return false


func _fuera_del_banco() -> void:
	BP.preparar_partida()
	BP.poner_grupo(["Kael", "Lya", "Garon"], BP.NIVEL_COMBATE)
	Engine.set_meta(BP.META, false)
	Engine.set_meta("banco_caso", "derrotas")
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	seed(18112026)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(4)
	_ok(c.heroes.all(func(h): return h["hp"] > 1), "fuera del banco, el caso de derrotas dejó a alguien con %s PV"
		% str(c.heroes.map(func(h): return h["hp"])))
	c.queue_free()
	await _esperar(4)
	for k in ["banco_caso", "zona", "tipo_combate", "grupo_combate"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	hechos.append("fuera del banco, el caso de derrotas no cambia los PV")


# Un caso entero con los controles del banco: botón → combate → derrota → vuelta al banco.
func _caso(clave: String, activos: Array, version: String) -> void:
	var et := "%s (%s)" % [clave, version]
	var b = current_scene
	if b == null or b.scene_file_path != BP.ESCENA:
		_ok(false, "%s: no se está en el banco" % et)
		return
	seed(18112026)
	b._combate(clave)
	var c = await _esperar_escena("res://combate.tscn", LIMITE_ESCENA)
	if c == null:
		_ok(false, "%s: el combate no se abre" % et)
		return
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	_ok(nombres == activos, "%s: los héroes son %s y no %s" % [et, nombres, activos])
	_ok(c.heroes.all(func(h): return h["hp"] <= 1 and h["hp_max"] > 1), "%s: los héroes no empiezan con 1 PV (%s)"
		% [et, str(c.heroes.map(func(h): return [h["hp"], h["hp_max"]]))])
	_ok(c.enemigos.any(func(e): return float(e["atb"]) >= 90.0) or c.estado != "esperando",
		"%s: los enemigos no empiezan con el turno casi lleno (%s)" % [et, str(c.enemigos.map(func(e): return e["atb"]))])
	var caidos := {}                                 # nombre → segundo de su caída
	var muertos := {}                                # nombre → morir() ejecutado (_muerta) y su animación
	var t0 := Time.get_ticks_msec()
	var menu_abierto := false
	var traza := ""                                  # lo que dice el registro y el estado del combate, al cambiar
	print("%s: al empezar PV %s, ATB héroes %s, ATB enemigos %s, estado %s" % [et, str(c.heroes.map(func(h): return h["hp"])),
		str(c.heroes.map(func(h): return snappedf(h["atb"], 0.1))), str(c.enemigos.map(func(e): return snappedf(e["atb"], 0.1))), c.estado])
	while (Time.get_ticks_msec() - t0) / 1000.0 < LIMITE_COMBATE:
		await process_frame
		if not is_instance_valid(c) or c != current_scene:
			break
		var ahora := "%s | %s" % [c.estado, str(c.registro.text)]
		if ahora != traza:
			traza = ahora
			print("  %.2f s  %s" % [(Time.get_ticks_msec() - t0) / 1000.0, ahora])
		for h in c.heroes:
			var n: String = h["nombre"]
			if h["hp"] <= 0 and not caidos.has(n):
				caidos[n] = (Time.get_ticks_msec() - t0) / 1000.0
			var p = c._p3d(h)
			if caidos.has(n) and not muertos.has(n) and p != null and bool(p.get("_muerta")):
				var a = p.get("anim")
				var clip := ""
				if a != null:
					clip = str(a.current_animation) if str(a.current_animation) != "" else str(a.assigned_animation)
				muertos[n] = clip
		if c.estado == "menu" or c.estado == "objetivo":
			menu_abierto = true
			break
		if c.estado == "fin" and muertos.size() == activos.size():
			break
	_ok(not menu_abierto, "%s: un héroe abrió su menú antes de caer (actor %s)" % [et, str(c.actor["nombre"]) if c.actor != null else "?"])
	_ok(caidos.size() == activos.size(), "%s: solo caen %s" % [et, str(caidos.keys())])
	_ok(muertos.size() == activos.size(), "%s: morir() solo en %s (sin modelo 3D: %s)" % [et, str(muertos.keys()),
		str(c.heroes.filter(func(h): return c._p3d(h) == null).map(func(h): return h["nombre"]))])
	if is_instance_valid(c):
		_ok(c.estado == "fin" and str(c.registro.text).begins_with("Derrota"), "%s: no llega la derrota (estado %s, «%s»)"
			% [et, c.estado, str(c.registro.text)])
	print("%s: caídas %s; morir() y animación %s" % [et, str(caidos), str(muertos)])
	var vuelta = await _esperar_escena(BP.ESCENA, LIMITE_ESCENA)
	_ok(vuelta != null, "%s: tras la derrota no se vuelve al banco (escena %s)" % [et,
		current_scene.scene_file_path if current_scene != null else "ninguna"])
	if vuelta == null:                               # (para que los casos siguientes se prueben igual)
		change_scene_to_file(BP.ESCENA)
		await _esperar_escena(BP.ESCENA, LIMITE_ESCENA)
		return
	await _esperar(3)
	_ok(BP.en_banco() and P.archivo() == BP.ARCHIVO, "%s: al volver, la partida no va al archivo del banco" % et)
	_ok(G.activos() == ["Kael", "Lya", "Garon"], "%s: al volver, el grupo es %s" % [et, str(G.activos())])
	_ok(not Engine.has_meta("naira_v12") and not Engine.has_meta("nix_v12") and not "Naira" in G.miembros()
		and not "Nix" in G.miembros(), "%s: al volver quedan Naira o Nix en la sesión" % et)
	_ok(int(G.datos()["Kael"]["pv"]) != 0, "%s: al volver, Kael sigue a 0 PV" % et)
	hechos.append("%s: %d héroes caen (morir() en todos: %s), derrota y vuelta al banco" % [et, muertos.size(), str(muertos)])
