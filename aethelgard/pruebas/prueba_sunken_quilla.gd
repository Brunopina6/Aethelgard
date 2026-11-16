extends SceneTree
# V12 (16/11): Sunken City 3D con la Quilla horneada (zonas3d/sunken/quilla/, EXPERIMENTAL; docs/v12/SUNKEN_QUILLA.md).
# Con «3d sunken3d» (lista_pruebas.txt, prueba_sunken_quilla). Sin ventana, con la partida propia de la prueba.
#   A. APAGADA por defecto: sin el interruptor, Sunken monta el GLB de siempre y no se carga NADA de la carpeta de la
#      Quilla; el interruptor solo vale en Auditoría o en el editor (quilla.gd mira banco_pruebas.permitido()).
#   B. Encendida (Engine «sunken_quilla_v12», como el selector del banco): el GLB nuevo, sus materiales (los sombreados
#      de la muestra, por su ruta), el mapa de luz del perfil y las sondas.
#   C. Las anclas coinciden con el trazado: faroles en las costillas 44 y 32, ninguno en la 38; la tabla en su sitio; las
#      coronas de las tres costillas. La luz directa de los faroles en las tablas: nada bajo la 38 (quilla_luz.json).
#   D. La corona de la costilla 44 se OCULTA con Kael en z 40 (la cámara al sur) y vuelve a verse cuando Kael pasa al
#      sur de ella. Ningún material de la Quilla es transparente en bajo ni en medio y no hay luces omni.
#   E. La cuadrilla: nadie pisa lo andable ni pasa a menos de 1,2 m de las rutas de prueba_sunken3d; los trabajos avanzan
#      con sus objetos (el fardo apilado, la pieza de la carpintera); hablar los para y luego siguen; frases ≤ 110 letras
#      y sin los términos vetados (prueba_ciudad_datos.gd); el botón ofrece hablar desde la Quilla.
#   F. Lo andable no cambia: suelo a su altura (muestra), los puntos prohibidos de siempre siguen prohibidos.
# Imprime «FALLOS: n».

const REGION := "res://zonas3d/sunken_3d.tscn"
const ARCHIVO := "user://prueba_sunken_quilla.save"
const RAIZ := "res://zonas3d/sunken/quilla/"
const META := "sunken_quilla_v12"
const PROHIBIDO := ["erebo", "ladron de corazones", "corazones", "olvido", "rocio", "cripta", "trampilla", "conclave",
	"crio", "hermano", "diecisiete", "alcantarilla", "ceniza de los nombres", "corazon", "recuerd", "record", "memoria",
	"brazalete", "astraea", "dique"]
# las rutas de prueba_sunken3d (tramos en x, z) por las que no debe pasar nadie de la cuadrilla
const RUTAS := [[Vector2(40.0, 57.8), Vector2(40.0, 27.6)], [Vector2(40.0, 44.0), Vector2(38.8, 40.0)],
	[Vector2(38.8, 40.0), Vector2(38.8, 38.2)], [Vector2(40.0, 27.6), Vector2(40.0, 24.8)],
	[Vector2(40.0, 27.6), Vector2(47.4, 27.6)], [Vector2(36.0, 27.6), Vector2(40.0, 27.6)]]

var P = load("res://progreso.gd")
var T
var v
var fallos := 0


func _initialize() -> void:
	_correr.call_deferred()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(c: bool, t: String) -> void:
	if c:
		print("OK " + t)
	else:
		_mal(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _cargar() -> void:
	change_scene_to_file(REGION)
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null:
			break
	await _frames(10)
	v = current_scene


func _preparar() -> void:
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok", "comentarios_dichos"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	P.cargar()
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("partida_lista", true)


static func _sin_tildes(s: String) -> String:
	var r := s.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		r = r.replace(par[0], par[1])
	return r


static func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _correr() -> void:
	await _frames(2)
	_preparar()
	T = load("res://zonas3d/sunken/trazado.gd")
	# ---------------------------------------------------------------- A. apagada
	if Engine.has_meta(META):
		Engine.remove_meta(META)
	Engine.set_meta("calidad_proto", "medio")
	await _cargar()
	_ok(v != null and v.casco != null and v.casco.quilla == null, "A: sin el interruptor, Sunken monta su GLB de siempre")
	var cargados: Array = []
	for r in [RAIZ + "quilla.gd", RAIZ + "obreros.gd", RAIZ + "modelos/quilla.glb", RAIZ + "luz/quilla_luz_1024.png",
			RAIZ + "luz/quilla_luz_2048.png", RAIZ + "texturas/tablazon.png"]:
		if ResourceLoader.has_cached(r):
			cargados.append(r)
	_ok(cargados.is_empty(), "A: apagada, no hay en memoria nada de la Quilla %s" % [cargados])
	var fuente := FileAccess.get_file_as_string("res://zonas3d/sunken/quilla/quilla.gd")
	_ok(fuente.contains("banco_pruebas.gd\").permitido()"), "A: el interruptor solo vale en Auditoría o en el editor")
	_ok(load("res://recursos.gd").APAGADOS.get("res://zonas3d/sunken/quilla/", "") == META,
		"A: la carpeta de la Quilla no se precarga con el interruptor apagado (recursos.gd, APAGADOS)")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_ok(presets.count("zonas3d/sunken/quilla/*") >= 2, "A: las APK de prueba 3D y experimental no llevan la Quilla")

	# ---------------------------------------------------------------- B. encendida
	Engine.set_meta(META, true)
	await _cargar()
	var q = v.casco.quilla
	if q == null:
		_mal("B: con el interruptor, no se monta la Quilla")
		_fin()
		return
	_ok(q.horneado and q.tex_luz_usada.ends_with("_2048.png"), "B: horneada, con el mapa de luz de 2048 en medio (%s)" % q.tex_luz_usada)
	var sh_ok := true
	for k in q.materiales:
		var m: Material = q.materiales[k]
		if m is ShaderMaterial and not (m as ShaderMaterial).shader.resource_path.begins_with("res://zonas3d/muestra_calle/calle_"):
			sh_ok = false
	_ok(sh_ok and q.materiales.size() >= 5, "B: los sombreados son los de la muestra, por su ruta (%d materiales)" % q.materiales.size())
	_ok(not (q.luz.get("sondas", {}) as Dictionary).is_empty(), "B: hay sondas de luz")

	# ---------------------------------------------------------------- C. anclas y faroles
	var an: Dictionary = v.casco.anclas
	_ok(an.has("farol_44") and an.has("farol_32") and not an.has("farol_38"), "C: faroles en 44 y 32, ninguno en 38")
	_ok(absf(an.get("farol_44", Vector3.ZERO).z - 44.0) < 0.05 and absf(an.get("farol_32", Vector3.ZERO).z - 32.0) < 0.05,
		"C: los faroles cuelgan de sus costillas")
	var tabla: Vector3 = an.get("tabla", Vector3.ZERO)
	_ok(Vector2(tabla.x, tabla.z).distance_to(Vector2(T.PIEZAS["tabla"][0], T.PIEZAS["tabla"][1])) < 0.05,
		"C: la tabla suelta, en su sitio (%s)" % tabla)
	var zs: Array = []
	for c in q.coronas:
		zs.append(c["z"])
	_ok(zs.has(44.0) and zs.has(38.0) and zs.has(32.0), "C: coronas de las costillas de la Quilla %s" % [zs])
	_ok(not v.casco.faroles.any(func(p): return absf(p.z - T.COSTILLA_OSCURA) < 0.2), "C: la costilla 38 no tiene farol encendido")
	var fs: Dictionary = q.luz.get("faroles_suelo", {})
	_ok(fs.size() == 3 and float(fs["38"]) < 0.25 * minf(float(fs["44"]), float(fs["32"])),
		"C: la luz de los faroles en las tablas: casi nada bajo la 38 (%s)" % [fs])

	# ---------------------------------------------------------------- D. coronas, transparencias y luces
	v._colocar_kael(T.en_mundo(Vector2(40.0, 40.0)))
	await _frames(20)
	var c44: Dictionary = {}
	for c in q.coronas:
		if c["z"] == 44.0:
			c44 = c
	_ok(not c44.is_empty() and not (c44["nodo"] as Node3D).visible, "D: con Kael en z 40, la corona de la 44 se oculta")
	v._colocar_kael(T.en_mundo(Vector2(40.0, 47.0)))
	await _frames(20)
	_ok(not c44.is_empty() and (c44["nodo"] as Node3D).visible, "D: con Kael al sur de la 44, se vuelve a ver")
	var trans := 0
	for k in q.materiales:
		var m: Material = q.materiales[k]
		if m is StandardMaterial3D and (m as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			trans += 1
	_ok(trans == 0, "D: ningún material de la Quilla es transparente (%d)" % trans)
	var omni: int = v.find_children("*", "OmniLight3D", true, false).size()
	_ok(omni == 0, "D: sin luces omni en medio (%d)" % omni)

	# ---------------------------------------------------------------- E. la cuadrilla
	var ob = q.obreros
	_ok(ob != null and ob.lista.size() == 4, "E: cuatro obreros")
	if ob != null:
		v._colocar_kael(T.en_mundo(T.INICIO))
		var peor := INF
		var pisado := ""
		for f in 1500:                                       # ~50 s a 30 FPS: varias vueltas de cada trabajo
			await process_frame
			if f % 5 != 0:
				continue
			for o in ob.lista:
				var p: Vector3 = o["nodo"].global_position
				var p2 := Vector2(p.x, p.z)
				if T.andable(p.x, p.z) and pisado == "":
					pisado = "%s en %s" % [o["persona"], p2]
				for r in RUTAS:
					peor = minf(peor, _dist_segmento(p2, r[0], r[1]))
		_ok(pisado == "", "E: nadie de la cuadrilla pisa lo andable (%s)" % pisado)
		_ok(peor >= 1.2, "E: nadie pasa a menos de 1,2 m de las rutas (mínimo %.2f m)" % peor)
		_ok(int(ob.montones["fardo_apilado"]["n"]) >= 1 and int(ob.montones["pieza_hecha"]["n"]) >= 1,
			"E: los trabajos avanzan con sus objetos (fardos apilados %d, piezas hechas %d)" % [
			ob.montones["fardo_apilado"]["n"], ob.montones["pieza_hecha"]["n"]])
		# hablar los para y luego siguen
		var cal: Dictionary = ob.grupos["calafate"][0]
		var antes: Vector3 = cal["nodo"].global_position
		var texto: String = ob.hablar("calafate", Vector3(41.5, 0, 41.0))
		await _frames(60)
		var quieto: bool = cal["nodo"].global_position.distance_to(antes) < 0.01 and float(cal["pausa"]) > 0.0
		await _frames(150)
		_ok(texto.begins_with("Calafate: «") and quieto and float(cal["pausa"]) <= 0.0,
			"E: hablar para al calafate y luego sigue («%s»)" % texto)
		var largas: Array = []
		for id in ob.FRASES:
			var todas: Array = (ob.FRASES[id] as Array).duplicate()
			if ob.FRASES_TRAS_PAGA.has(id):
				todas.append(ob.FRASES_TRAS_PAGA[id])
			for fr in todas:
				var l: String = _sin_tildes(fr)
				if fr.length() > 110 or PROHIBIDO.any(func(w): return l.contains(w)):
					largas.append(fr)
		_ok(largas.is_empty(), "E: frases ≤ 110 letras y sin términos vetados %s" % [largas])
		# el botón, desde la Quilla, junto a la carpintera y junto al calafate
		var ofrece := {}
		for sitio in [Vector2(38.5, 32.4), Vector2(41.5, 40.6)]:
			v._colocar_kael(T.en_mundo(sitio))
			await _frames(4)
			v._comprobar_cerca()
			ofrece[sitio] = v.cerca
		_ok(ofrece.values().has("carpintera") or ofrece.values().has("calafate"),
			"E: desde la pasarela se puede hablar con la cuadrilla %s" % [ofrece])

	# ---------------------------------------------------------------- F. lo andable no cambia
	var malos := 0
	for x in [38.6, 40.0, 41.4]:
		for z in [31.4, 34.0, 38.0, 42.0, 44.2]:
			var y: float = T.altura(x, z)
			var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(Vector3(x, y + 2.0, z), Vector3(x, y - 4.0, z)))
			if r.is_empty() or absf(r["position"].y - y) > 0.12:
				malos += 1
	_ok(malos == 0, "F: la pasarela de la Quilla tiene suelo a su altura (%d puntos mal)" % malos)
	var prohibidos_ok := true
	for p in [Vector2(28.0, 40.0), Vector2(43.0, 36.0), Vector2(44.5, 25.6), Vector2(37.5, 32.2), Vector2(42.9, 31.9)]:
		if not v._prohibido(T.en_mundo(p)):
			prohibidos_ok = false
	_ok(prohibidos_ok, "F: las casas, el banco, la repisa y la escotilla siguen sin pisarse")
	_fin()


func _fin() -> void:
	if Engine.has_meta(META):
		Engine.remove_meta(META)
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
