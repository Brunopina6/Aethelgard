extends SceneTree
# Los «Parameter "material" is null» de la carga (17/11; docs/v12/MATERIAL_NULL_17_11.md). CON VENTANA: sin ella el
# renderizador es ficticio y el error del motor no sale nunca. Cuenta los errores con un Logger propio (Godot 4.5+).
#   A. El motor: comprueba que el contador los ve. Una malla que sobrevive al nodo, con material_override Y un material
#      por superficie propios, liberada tras dibujarse, da 4 errores (godotengine/godot#85817, sigue en 4.7.2). Si no
#      salen, la prueba no sirve en esta máquina (sin ventana o con otro renderizador): FALLO.
#   B. Cada héroe v3 (Kael, Lya, Garon) en su estudio de combate (combate.gd estudio_3d, como la carga): ninguna malla
#      con material_override Y material por superficie a la vez; dibujado y liberado sin errores.
#   C. La carga entera (la escena principal, como en el Redmi) con «Protagonistas: v3» (meta heroes_version, no toca
#      Ajustes): el precalentado se monta (muestra y barrio, si están), ninguna malla de vista_3d con los dos a la vez
#      y 0 errores desde la fase de sombreadores hasta 10 fotogramas después de liberar vista_3d.
# Uso: --path aethelgard --script res://pruebas/prueba_material_null.gd -- movil   (sin --headless)
# No carga partidas. Imprime «FALLOS: n» al final.

class Contador extends Logger:
	var n := 0
	var funciones: Array = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool,
			error_type: int, script_backtraces: Array) -> void:
		if code.contains("\"material\" is null") or rationale.contains("\"material\" is null"):
			n += 1
			if not function in funciones:
				funciones.append(function)
	func _log_message(message: String, error: bool) -> void:
		pass

const HEROES := {"kael3d": "Kael", "nyx3d": "Lya", "garon3d": "Garon"}

var cont := Contador.new()
var fallos := 0
var comprobaciones := 0


func _ok(cond: bool, texto: String) -> void:
	comprobaciones += 1
	if cond:
		print("  ok  ", texto)
	else:
		fallos += 1
		print("  FALLO ", texto)


func _initialize() -> void:
	OS.add_logger(cont)
	_principal.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# Mallas con material_override y algún material por superficie a la vez (el caso que el motor no apunta).
static func con_los_dos(raiz: Node) -> Array:
	var r: Array = []
	for g in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.material_override == null:
			continue
		for s in mi.get_surface_override_material_count():
			if mi.get_surface_override_material(s) != null:
				r.append(str(raiz.get_path_to(mi)))
				break
	return r


func _principal() -> void:
	if DisplayServer.get_name() == "headless":
		_ok(false, "esta prueba necesita ventana (sin ella el renderizador es ficticio y el error no sale)")
		_fin()
		return
	await _motor()
	await _heroes()
	await _carga()
	_fin()


func _fin() -> void:
	print("COMPROBACIONES: %d · FALLOS: %d" % [comprobaciones, fallos])
	quit(1 if fallos > 0 else 0)


func _motor() -> void:
	print("A. el motor (se provocan a propósito 4 errores «material is null» para ver que se cuentan)")
	var malla := BoxMesh.new()                      # (la retiene la prueba: sobrevive al nodo)
	var cam := Camera3D.new()
	root.add_child(cam)
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	mi.material_override = StandardMaterial3D.new()
	root.add_child(mi)
	await _frames(3)
	var n0 := cont.n
	mi.queue_free()
	await _frames(3)
	cam.queue_free()
	await _frames(1)
	_ok(cont.n - n0 == 4, "override + superficie, dibujado y liberado: %d errores (esperados 4: el contador funciona)"
		% (cont.n - n0))


func _heroes() -> void:
	print("B. héroes v3 en su estudio de combate")
	Engine.set_meta("heroes_version", "v3")
	var C = load("res://combate.gd")
	var modelos: Dictionary = C.get_script_constant_map()["MODELOS"]
	for k in HEROES:
		if not modelos.has(k) or C._ruta_3d(modelos[k]) == "":
			print("  (sin %s)" % k)
			continue
		var caja := Node.new()
		root.add_child(caja)
		var est: Dictionary = C.estudio_3d(caja, modelos[k], 0.25, Color(1.0, 0.8, 0.6))
		est["vp"].render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var h: Node3D = C.modelo_3d(modelos[k])
		est["vp"].add_child(h)
		await _frames(4)
		_ok(h.get("es_v3") == true, "%s: es el v3" % HEROES[k])
		var cara = h.get("v2").get("cara") if h.get("v2") != null else null
		_ok(cara is MeshInstance3D and cara.material_override is ShaderMaterial,
			"%s: la cara v3 sigue con su material (material_override)" % HEROES[k])
		var dobles := con_los_dos(h)
		_ok(dobles.is_empty(), "%s: ninguna malla con override y material por superficie a la vez %s" % [HEROES[k], dobles])
		var n0 := cont.n
		caja.queue_free()
		await _frames(4)
		_ok(cont.n - n0 == 0, "%s: liberado sin errores «material is null» (%d)" % [HEROES[k], cont.n - n0])


func _carga() -> void:
	print("C. la carga entera con «Protagonistas: v3»")
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	var t0 := Time.get_ticks_msec()
	var visto := false
	var montaje: Array = []
	var n0 := -1
	while Time.get_ticks_msec() - t0 < 180000:
		await process_frame
		var c := current_scene
		if c == null or not "fase" in c:
			continue
		if c.fase == "shaders":
			if not visto:
				visto = true
				n0 = cont.n
				cont.funciones = []
			if c.frames_shader == c.FRAMES_SHADERS - 1 and c.vista_3d != null:
				montaje = [c.vista_3d.find_child("PrecalentadoBarrio", true, false) != null,
					c.vista_3d.find_children("cara_v3", "MeshInstance3D", true, false).size(), con_los_dos(c.vista_3d)]
		elif visto:
			break
	_ok(visto, "la carga llega a la fase de sombreadores")
	if not visto:
		return
	await _frames(10)
	_ok(montaje.size() == 3, "se vio el último fotograma del precalentado")
	if montaje.size() == 3:
		var hay_barrio: bool = ResourceLoader.exists("res://zonas3d/barrio/barrio.gd") \
			and load("res://banco_pruebas.gd").permitido()
		_ok(montaje[0] == hay_barrio, "el precalentado del barrio se monta (%s)" % montaje[0])
		_ok(montaje[1] == HEROES.size(), "las %d caras v3 están en el precalentado (%d)" % [HEROES.size(), montaje[1]])
		_ok((montaje[2] as Array).is_empty(), "ninguna malla del precalentado con override y material por superficie %s"
			% [montaje[2]])
	_ok(cont.n - n0 == 0, "0 errores «material is null» al liberar el precalentado (%d %s)" % [cont.n - n0,
		cont.funciones])
	Engine.remove_meta("heroes_version")
