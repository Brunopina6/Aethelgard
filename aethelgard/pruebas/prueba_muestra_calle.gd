extends SceneTree
# V12 (15/11): MUESTRA GRÁFICA de una calle de Oakhaven (zonas3d/muestra_calle/, EN PRUEBAS; solo desde el banco de
# pruebas de Auditoría). Prueba ligera:
#   1. La entrada del banco existe (banco_pruebas.gd, EXPLORAR «muestra_calle») y lleva a la escena, que existe.
#   2. Fuera del banco la escena no se usa: ningún guion ni escena del juego la nombra (salvo el banco y la propia
#      carpeta) y la versión estable no lleva zonas3d/ ni la experimental la muestra (export_presets.cfg).
#   3. La escena carga: la calle (GLB), sus materiales sustituidos (con el mapa de luz que toca al perfil), los choques,
#      las sondas de luz y Kael.
#   4. Kael anda: con un destino a 4 m (de x −2 a 2), se mueve, con el clip de andar/correr, sobre el suelo, y la cámara le sigue.
#   5. No atraviesa las casas ni sale de lo andable; la sonda da menos sol y menos cielo en el callejón que en la calle.
#   6. Con el perfil bajo, el mapa de luz pequeño (1024).
# Partida propia (Engine «archivo_partida_prueba»): nunca la de verdad. Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
var fallos := 0
var v


func _initialize() -> void:
	Engine.set_meta("archivo_partida_prueba", "user://prueba_muestra_calle.save")
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if cond:
		print("OK " + t)
	else:
		fallos += 1
		print("FALLO: " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	_entrada_del_banco()
	_sin_usos_fuera()
	await _cargar("medio")
	if v != null:
		_escena_cargada("medio")
		await _anda()
		await _no_atraviesa()
	await _cargar("bajo")
	if v != null:
		_ok(v.tex_luz_usada.ends_with("calle_luz_1024.png"), "6: con el perfil bajo, el mapa de luz de 1024 (%s)" % v.tex_luz_usada)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= 1 y 2

func _entrada_del_banco() -> void:
	var BP = load("res://banco_pruebas.gd")
	_ok(BP.EXPLORAR.has("muestra_calle"), "1: el banco tiene la entrada «muestra_calle»")
	if BP.EXPLORAR.has("muestra_calle"):
		var d: Dictionary = BP.EXPLORAR["muestra_calle"]
		_ok(str(d.get("escena", "")) == ESCENA, "1: la entrada lleva a %s" % str(d.get("escena", "")))
		_ok(String(d["titulo"]).begins_with("Muestra gráfica") and "en pruebas" in String(d["titulo"]),
			"1: título «%s»" % d["titulo"])
		_ok(d["activos"] == ["Kael"], "1: solo Kael (%s)" % str(d["activos"]))
	_ok(ResourceLoader.exists(ESCENA), "1: la escena existe")
	# (15/11, revisión) antes era una tautología (no podía fallar): ahora se lee la condición de verdad del banco.
	var fuente_bp: String = FileAccess.get_file_as_string("res://banco_pruebas.gd")
	var i_perm := fuente_bp.find("static func permitido()")
	var cuerpo_perm: String = fuente_bp.substr(i_perm, 160).get_slice("
", 1) if i_perm >= 0 else ""
	_ok(cuerpo_perm.strip_edges().begins_with('return OS.has_feature("auditoria") or OS.has_feature("editor")'),
		"1: el banco solo se permite en Auditoría o en el editor («%s»)" % cuerpo_perm.strip_edges())


func _sin_usos_fuera() -> void:
	var usos: Array = []
	_buscar("res://", usos)
	_ok(usos == ["res://banco_pruebas.gd"], "2: fuera del banco nadie nombra la muestra (%s)" % str(usos))
	var cfg := ConfigFile.new()
	_ok(cfg.load("res://export_presets.cfg") == OK, "2: se lee export_presets.cfg")
	for sec in cfg.get_sections():
		if not sec.ends_with(".options") and cfg.has_section_key(sec, "name"):
			var nombre: String = cfg.get_value(sec, "name")
			var excl: String = cfg.get_value(sec, "exclude_filter", "")
			var feats: String = cfg.get_value(sec, "custom_features", "")
			if "auditoria" in feats:
				_ok(not "muestra_calle" in excl and not excl.contains("zonas3d/*"), "2: «%s» lleva la muestra" % nombre)
			else:
				_ok(excl.contains("zonas3d/*") or excl.contains("zonas3d/muestra_calle/*"),
					"2: «%s» (sin el banco) no lleva la muestra" % nombre)


func _buscar(dir: String, usos: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		var ruta := dir.path_join(f)
		if not (f.ends_with(".gd") or f.ends_with(".tscn") or f.ends_with(".tres")):
			continue
		if ruta.begins_with("res://pruebas/") or ruta.begins_with("res://zonas3d/muestra_calle/"):
			continue
		if FileAccess.get_file_as_string(ruta).contains("muestra_calle"):
			usos.append(ruta)
	for s in d.get_directories():
		if s.begins_with(".") or s == "addons":
			continue
		_buscar(dir.path_join(s), usos)


# ================================================================= 3 a 5

func _cargar(perfil: String) -> void:
	Engine.set_meta("calidad_proto", perfil)
	if current_scene != null:
		current_scene.queue_free()
		await _frames(3)
	v = null
	change_scene_to_file(ESCENA)
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			break
	await _frames(10)
	_ok(v != null, "3: la escena carga con el perfil %s" % perfil)


func _escena_cargada(perfil: String) -> void:
	_ok(v.calle != null and v.calle.find_child("calle", true, false) != null, "3: la calle (GLB) está")
	for m in ["tierra", "revoque", "madera", "tejas", "sillar", "hoja", "brillo", "v:piedra"]:
		_ok(m in v.materiales_usados, "3: material «%s» sustituido" % m)
	_ok(v.tex_luz_usada.ends_with("calle_luz_2048.png"), "3: con el perfil %s, el mapa de luz de 2048 (%s)" % [perfil,
		v.tex_luz_usada])
	var choques := 0
	for n in v.get_children():
		if n is StaticBody3D:
			choques += 1
	_ok(choques >= 30, "3: %d choques" % choques)
	_ok(not (v.luz.get("sondas", {}) as Dictionary).is_empty(), "3: las sondas de luz están")
	# (15/11, revisión) los cristales de los faroles de pie (malla «piezas») llevan su color fijo: el horneado los dejó a 0
	var cristales_fijos := 0
	for mi in v.calle.find_children("piezas", "MeshInstance3D", true, false):
		for si in (mi as MeshInstance3D).mesh.get_surface_count():
			var mt := (mi as MeshInstance3D).get_surface_override_material(si) as ShaderMaterial
			if mt != null and mt.shader == v.SH_BRILLO:
				cristales_fijos += 1 if bool(mt.get_shader_parameter("usar_color_fijo")) else 0
	_ok(cristales_fijos >= 1, "3: los cristales de los faroles de pie llevan su color fijo (si no, saldrían negros)")
	_ok(v.kael != null and v.kael.is_inside_tree(), "3: Kael está")
	_ok(absf(v.kael.global_position.x - v.INICIO.x) < 0.2 and absf(v.kael.global_position.z - v.INICIO.z) < 0.2,
		"3: Kael empieza en el inicio (%s)" % str(v.kael.global_position))


func _anda() -> void:
	v._colocar_kael(Vector3(-2.0, 0.0, 1.0))           # (en medio: la cámara sigue a Kael entre x −3,5 y 3,5)
	await _frames(5)
	var p0: Vector3 = v.kael.global_position
	var cam0: Vector3 = v.cam.global_position
	v.destino = p0 + Vector3(4.0, 0.0, 0.0)
	var vio_marcha := false
	for i in 150:
		await process_frame
		if v.movimiento != "" and (not v.kael.has_method("marcha_actual") or v.kael.marcha_actual() != ""):
			vio_marcha = true
		if v.destino == null:
			break
	await _frames(20)
	var p1: Vector3 = v.kael.global_position
	_ok(Vector2(p1.x - p0.x, p1.z - p0.z).length() > 3.5, "4: Kael anda (de %s a %s)" % [str(p0), str(p1)])
	_ok(vio_marcha, "4: con el clip de andar o correr")
	_ok(p1.y > -0.05 and p1.y < 0.3, "4: sobre el suelo (y = %.2f)" % p1.y)
	_ok(v.cam.global_position.x > cam0.x + 2.0, "4: la cámara le sigue (x %.1f → %.1f)" % [cam0.x, v.cam.global_position.x])
	_ok(absf(v.cam.global_rotation_degrees.y) < 0.01, "4: la cámara no gira")


func _no_atraviesa() -> void:
	v._colocar_kael(Vector3(-6.6, 0.0, 1.0))
	v.destino = Vector3(-8.5, 0.0, -6.0)             # dentro de la casa de la puerta
	for i in 150:
		await process_frame
		if v.destino == null:
			break
	var p: Vector3 = v.kael.global_position
	_ok(p.z > -2.75, "5: no entra en la casa (z = %.2f)" % p.z)
	v._colocar_kael(Vector3(-4.0, 0.0, 1.0))
	v.destino = Vector3(-4.0, 0.0, 9.0)              # fuera de lo andable, al sur
	for i in 150:
		await process_frame
		if v.destino == null:
			break
	_ok(v.kael.global_position.z < 3.4, "5: no sale de la calle por el sur (z = %.2f)" % v.kael.global_position.z)
	var calle: Vector2 = v.sonda(Vector3(-4.0, 0.0, 1.0))
	var callejon: Vector2 = v.sonda(Vector3(0.0, 0.85, -6.5))
	_ok(calle.x > 0.8 and callejon.x < calle.x - 0.3 and callejon.y < calle.y, "5: sondas: sol %.2f / cielo %.2f en la calle; sol %.2f / cielo %.2f en el callejón" % [
		calle.x, calle.y, callejon.x, callejon.y])
