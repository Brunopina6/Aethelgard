extends SceneTree
# Prueba de Bramavidrio (V12): el modelo hecho con Blender (fuente/crear_bramavidrio.py) en sus tres versiones, sus
# clips, su presupuesto móvil y su guion (enemigos/bramavidrio/bramavidrio_3d.gd), creado con .new() como en combate.gd.
#   sin ventana:  --headless --script res://pruebas/prueba_bramavidrio_modelo.gd --fixed-fps 30
# Comprueba (y acaba con «FALLOS: n»):
#  - los tres GLB (alto, medio y bajo): un AnimationPlayer y un esqueleto con los 43 huesos (raiz, col_01…col_18, cabeza,
#    mandibula, mandibula_izq, mandibula_der, placa_02…placa_17, brillo, garganta, chorro, monticulo); los 10 clips con su
#    duración (la del JSON); cada clip gira todos los huesos; las superficies piel, vidrio, garganta, arena y chorro; el
#    alfa del color de vértice de la piel (la máscara del basalto, pasada 2)
#  - las mandíbulas laterales se abren al rugir (pasada 2)
#  - presupuesto: triángulos ≤ 25 000 / 12 000 / 6 000 y texturas de 2048 / 1024 / 512, comprimidas para la GPU
#  - bramavidrio_clips.json: los mismos clips, duraciones y triángulos, y los instantes que usa el guion (INSTANTES)
#  - los bucles (reposo, subterraneo) cierran sin salto; aviso acaba como subterraneo; emerger, rugido, los tres ataques
#    y herida acaban en la pose del reposo; derrota no
#  - el chorro solo sale en ataque_aliento (entre descarga y fin_descarga); el montículo, escondido bajo la arena
#  - el guion: escala automática (combate 0,32; exploración 1), reposo al empezar; cada ataque da un impacto UNA vez y
#    en su ancla; avisar() avisa una vez, espera y el ataque sigue desde ahí; el aliento emite succión, descarga y fin;
#    herida vuelve al reposo; derrota emite caida y se queda; exploración: subterraneo, vibrar, emerger (rompe_arena)
#    y rugir; la luz sigue a sus huesos
#  - el encuadre propuesto para MODELOS de combate.gd (la cámara de _crear_rig_3d): qué clips caben en la ventana 3D

# V12 (12/11): hay TRES versiones; la 3 («el Excavador», enemigos/bramavidrio/v3/) se comprueba como la 2 y además su
# boca fotograma a fotograma (_comprobar_boca: cerrada en reposo, nunca «de más», abierta con fuerza al rugir y en el
# Aliento, cerrada en el mordisco) y que sus garras no patinan en el reposo. «version=3» para solo esa.
# V12 (11/11, rediseño): hay DOS versiones del modelo y la prueba comprueba las dos (o la que diga «version=1» / «version=2»
# después de «--»). La 1 (el gusano de anillos) con sus límites de siempre; la 2 («la Sierpe de la Vela»,
# enemigos/bramavidrio/v2/, fuente/crear_bramavidrio2.py) con el presupuesto de la 1 como techo (19 359 / 8 823 / 3 124
# triángulos), 52 huesos (los 43 de la 1 más aleta_izq, aleta_der, succion y losa_1…losa_6), la superficie «polvo»,
# los mismos clips e instantes de la 1 más los nuevos, las placas del suelo solo en la Fractura y la arena que aspira
# solo en el Aliento, y las señales nuevas (placas_suelo, fin_succion). Y el interruptor (bramavidrio_version.gd).
const DATOS_VERSION := {
	1: {"carpeta": "res://enemigos/bramavidrio/", "guion": "bramavidrio_3d.gd", "json": "bramavidrio_clips.json",
		"glb": ["bramavidrio.glb", "bramavidrio_medio.glb", "bramavidrio_bajo.glb"],
		"tex": ["bramavidrio_piel.webp", "bramavidrio_piel_medio.webp", "bramavidrio_piel_bajo.webp"],
		"tris": [25000, 12000, 6000], "extra": [], "superficies": ["piel", "vidrio", "garganta", "arena", "chorro"]},
	2: {"carpeta": "res://enemigos/bramavidrio/v2/", "guion": "bramavidrio2_3d.gd", "json": "bramavidrio2_clips.json",
		"glb": ["bramavidrio2.glb", "bramavidrio2_medio.glb", "bramavidrio2_bajo.glb"],
		"tex": ["bramavidrio2_piel.webp", "bramavidrio2_piel_medio.webp", "bramavidrio2_piel_bajo.webp"],
		"tris": [19359, 8823, 3124], "extra": ["aleta_izq", "aleta_der", "succion", "losa_1", "losa_2", "losa_3", "losa_4",
		"losa_5", "losa_6"], "superficies": ["piel", "vidrio", "garganta", "arena", "chorro", "polvo"]},
	# V12 (12/11): la 3, «el Excavador» (enemigos/bramavidrio/v3/, fuente/crear_bramavidrio3.py), con el presupuesto de
	# la 2 como techo; sin los abanicos de las mejillas (mandibula_izq/der) y con cejas y brazos
	3: {"carpeta": "res://enemigos/bramavidrio/v3/", "guion": "bramavidrio3_3d.gd", "json": "bramavidrio3_clips.json",
		"glb": ["bramavidrio3.glb", "bramavidrio3_medio.glb", "bramavidrio3_bajo.glb"],
		"tex": ["bramavidrio3_piel.webp", "bramavidrio3_piel_medio.webp", "bramavidrio3_piel_bajo.webp"],
		"tris": [15197, 5528, 2430], "sin": ["mandibula_izq", "mandibula_der"],
		"extra": ["ceja_izq", "ceja_der", "succion", "losa_1", "losa_2", "losa_3", "losa_4", "losa_5", "losa_6",
			"hombro_izq", "codo_izq", "mano_izq", "hombro_der", "codo_der", "mano_der"],
		"superficies": ["piel", "vidrio", "garganta", "arena", "chorro", "polvo"]},
}
var VER := 1
var CARPETA := ""
var GUION := ""
var JSON_CLIPS := ""
var VERSIONES := {}
var SUPERFICIES: Array = []
const CLIPS := ["reposo", "subterraneo", "aviso", "emerger", "rugido", "ataque", "ataque_sismico", "ataque_aliento",
	"herida", "derrota"]
const BUCLES := ["reposo", "subterraneo"]


func _usar_version(v: int) -> void:
	var d: Dictionary = DATOS_VERSION[v]
	VER = v
	CARPETA = d["carpeta"]
	GUION = CARPETA + d["guion"]
	JSON_CLIPS = CARPETA + d["json"]
	SUPERFICIES = d["superficies"]
	VERSIONES = {}
	var lados := [2048, 1024, 512]
	var i := 0
	for nivel in ["alto", "medio", "bajo"]:
		VERSIONES[nivel] = {"glb": CARPETA + d["glb"][i], "tex": CARPETA + d["tex"][i], "tris": d["tris"][i], "lado": lados[i]}
		i += 1
const DT := 1.0 / 30.0
# Encuadre propuesto (MODELOS["bramavidrio"] en combate.gd)
const VP := Vector2i(1920, 1000)
const ALTO_VISTA := 5.1
const CENTRO_Y := 1.45
const ESC := 1.07

var fallos := 0
var registro := {}


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + texto)
	if not cond:
		fallos += 1


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	var lista := [1, 2, 3]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("version="):
			lista = [int(a.get_slice("=", 1))]
	for ver in lista:
		_usar_version(ver)
		print("== Bramavidrio, VERSIÓN %d: modelo, clips y guion (%s)" % [ver, GUION])
		var datos := _leer_json()
		for v in VERSIONES:
			await _comprobar_glb(v, datos)
		_comprobar_json(datos)
		await _comprobar_guion()
		await _encuadre()
	_comprobar_interruptor()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# El interruptor (enemigos/bramavidrio/bramavidrio_version.gd): por defecto la 2; con la meta, la 1; elegir() solo
# cambia el guion de Bramavidrio.
func _comprobar_interruptor() -> void:
	print("-- interruptor de versión")
	var V = load("res://enemigos/bramavidrio/bramavidrio_version.gd")
	var antes = Engine.get_meta("bramavidrio_version") if Engine.has_meta("bramavidrio_version") else null
	if Engine.has_meta("bramavidrio_version"):
		Engine.remove_meta("bramavidrio_version")
	var por_linea := false
	for a in OS.get_cmdline_user_args():
		por_linea = por_linea or a.begins_with("bramavidrio_version=")
	if not por_linea:
		_ok(V.version() == V.VERSION_DEFECTO and V.VERSION_DEFECTO == 2, "por defecto, la versión %d (constante %d)" % [V.version(), V.VERSION_DEFECTO])
		Engine.set_meta("bramavidrio_version", 1)
		_ok(V.version() == 1 and V.guion() == DATOS_VERSION[1]["carpeta"] + DATOS_VERSION[1]["guion"], "con la meta a 1: %s" % V.guion())
		Engine.set_meta("bramavidrio_version", 2)
		_ok(V.version() == 2 and V.modelo().ends_with("bramavidrio2.glb"), "con la meta a 2: %s" % V.modelo())
		Engine.set_meta("bramavidrio_version", 3)
		_ok(V.version() == 3 and V.modelo().ends_with("bramavidrio3.glb") and V.guion().ends_with("bramavidrio3_3d.gd"),
			"con la meta a 3: %s" % V.guion())
		Engine.set_meta("bramavidrio_version", 9)
		_ok(V.version() == V.VERSION_DEFECTO, "una versión que no existe usa la de por defecto (%d)" % V.version())
		_ok(V.elegir("res://enemigos/bramavidrio/bramavidrio_3d.gd") == V.guion() and V.elegir("res://zarzalin_3d.gd") == "res://zarzalin_3d.gd",
			"elegir() cambia solo el guion de Bramavidrio")
		# Ajustes → «Bramavidrio» (datos aislados de la prueba): la elección se guarda y manda sin meta; la meta, sobre ella
		Engine.remove_meta("bramavidrio_version")
		var cfg_antes := FileAccess.get_file_as_string("user://ajustes.cfg") if FileAccess.file_exists("user://ajustes.cfg") else ""
		_ok(V.elegir_en_ajustes(1) == OK and V.en_ajustes() == 1 and V.version() == 1, "Ajustes a «Anterior»: versión %d" % V.version())
		Engine.set_meta("bramavidrio_version", 2)
		_ok(V.version() == 2, "la meta manda sobre Ajustes")
		Engine.remove_meta("bramavidrio_version")
		_ok(V.elegir_en_ajustes(3) == OK and V.en_ajustes() == 3 and V.version() == 3, "Ajustes a «Prueba v3»: versión %d" % V.version())
		_ok(V.elegir_en_ajustes(2) == OK and V.version() == 2, "Ajustes a «Nuevo»: versión %d" % V.version())
		if cfg_antes == "":
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ajustes.cfg"))
		else:
			var f := FileAccess.open("user://ajustes.cfg", FileAccess.WRITE)
			f.store_string(cfg_antes)
			f.close()
	Engine.remove_meta("bramavidrio_version")
	if antes != null:
		Engine.set_meta("bramavidrio_version", antes)


func _leer_json() -> Dictionary:
	var f := FileAccess.open(JSON_CLIPS, FileAccess.READ)
	_ok(f != null, "existe " + JSON_CLIPS)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	_ok(d is Dictionary and d.has("clips"), "el JSON se lee")
	return d if d is Dictionary else {}


# ---------------------------------------------------------------- cada GLB tal cual se importa

func _comprobar_glb(v: String, datos: Dictionary) -> void:
	var info: Dictionary = VERSIONES[v]
	print("-- versión ", v)
	var ps: PackedScene = load(info["glb"])
	_ok(ps != null, "[%s] el GLB se carga" % v)
	if ps == null:
		return
	var n: Node = ps.instantiate()
	root.add_child(n)
	var aps := n.find_children("*", "AnimationPlayer", true, false)
	var sks := n.find_children("*", "Skeleton3D", true, false)
	_ok(aps.size() == 1 and sks.size() == 1, "[%s] un AnimationPlayer y un esqueleto" % v)
	if aps.is_empty() or sks.is_empty():
		return
	var ap: AnimationPlayer = aps[0]
	var sk: Skeleton3D = sks[0]
	var esperados := ["raiz", "cabeza", "mandibula", "mandibula_izq", "mandibula_der", "brillo", "garganta", "chorro",
		"monticulo"]
	for k in range(1, 19):
		esperados.append("col_%02d" % k)
	for k in range(2, 18):
		esperados.append("placa_%02d" % k)
	esperados.append_array(DATOS_VERSION[VER]["extra"])
	esperados = esperados.filter(func(h): return not (h in DATOS_VERSION[VER].get("sin", [])))
	var faltan := esperados.filter(func(h): return sk.find_bone(h) < 0)
	_ok(faltan.is_empty() and sk.get_bone_count() == esperados.size(),
		"[%s] %d huesos (faltan: %s)" % [v, sk.get_bone_count(), faltan])
	var lista := Array(ap.get_animation_list()).map(func(x): return String(x))
	for c in CLIPS:
		_ok(c in lista, "[%s] existe el clip %s" % [v, c])
	_ok(lista.size() == CLIPS.size(), "[%s] solo esos 10 clips (%d)" % [v, lista.size()])
	var dj: Dictionary = datos.get("clips", {})
	var quietos := ["raiz", "brillo", "garganta", "chorro", "monticulo"]   # no giran nunca: el importador quita su pista
	var de_datos := ["brillo", "garganta", "chorro", "monticulo"]
	if VER >= 2:                                                  # v2 y v3: la succión y las placas del suelo (escala)
		quietos.append_array(["succion", "losa_1", "losa_2", "losa_3", "losa_4", "losa_5", "losa_6"])
		de_datos.append_array(["succion", "losa_1", "losa_6"])
	for c in lista:
		var a := ap.get_animation(c)
		var giran := {}
		var escalan := {}
		for k in a.get_track_count():
			var p := String(a.track_get_path(k))
			if ":" in p and a.track_get_type(k) == Animation.TYPE_ROTATION_3D:
				giran[p.get_slice(":", 1)] = true
			if ":" in p and a.track_get_type(k) == Animation.TYPE_SCALE_3D:
				escalan[p.get_slice(":", 1)] = true
		var sin_giro := esperados.filter(func(h): return not (h in quietos) and not giran.has(h))
		var sin_escala := de_datos.filter(func(h): return not escalan.has(h))
		_ok(sin_giro.is_empty() and sin_escala.is_empty(), "[%s] %s anima los %d huesos que se mueven y la escala de los %d de datos (faltan %s %s)" %
			[v, c, esperados.size() - quietos.size(), de_datos.size(), sin_giro, sin_escala])
		if dj.has(c):
			_ok(absf(a.length - float(dj[c]["duracion"])) < DT * 0.6, "[%s] %s dura %.3f s (JSON %.3f)" % [v, c, a.length, float(dj[c]["duracion"])])
	# malla, superficies y textura
	var tris := 0
	var nombres := {}
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		if m == null:
			continue
		tris += m.get_faces().size() / 3
		for i in m.get_surface_count():
			var mat := m.surface_get_material(i)
			nombres[mat.resource_name if mat != null else "?"] = true
	_ok(tris > 2000 and tris <= int(info["tris"]), "[%s] triángulos: %d (máximo %d)" % [v, tris, info["tris"]])
	var minerales := [0, 0]                                     # alfa del color de vértice de la piel: basalto (1) y carne (0)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		for i in m.get_surface_count():
			var mat := m.surface_get_material(i)
			if mat == null or mat.resource_name != "piel":
				continue
			var cols: PackedColorArray = m.surface_get_arrays(i)[Mesh.ARRAY_COLOR]
			for c in cols:
				if c.a > 0.9:
					minerales[0] += 1
				elif c.a < 0.1:
					minerales[1] += 1
	_ok(minerales[0] > 200 and minerales[1] > 200, "[%s] la piel distingue basalto y carne por el alfa del color (%d / %d vértices)" %
		[v, minerales[0], minerales[1]])
	if datos.get("triangulos", {}).has(v):
		var tj := int(datos["triangulos"][v])
		_ok(absi(tris - tj) <= maxi(40, tj / 100), "[%s] los triángulos del JSON (%d; Godot quita los degenerados: %d)" % [v, tj, tj - tris])
	for s in SUPERFICIES:
		_ok(nombres.has(s), "[%s] superficie %s" % [v, s])
	var tex: Texture2D = load(info["tex"])
	_ok(tex != null and tex.get_width() == int(info["lado"]) and tex.get_height() == int(info["lado"]),
		"[%s] textura %s de %d px" % [v, info["tex"].get_file(), tex.get_width() if tex != null else 0])
	if tex != null:
		var img := tex.get_image()
		_ok(img != null and img.is_compressed() and img.has_mipmaps(), "[%s] textura comprimida para la GPU y con mipmaps (%s)" %
			[v, img.get_format() if img != null else -1])
	if v == "alto":
		_comprobar_clips(ap, sk)
	n.queue_free()
	await _esperar(2)


# Bucles sin salto, finales en el reposo, chorro y montículo (en el alto; las tres versiones llevan los mismos clips).
func _comprobar_clips(ap: AnimationPlayer, sk: Skeleton3D) -> void:
	for c in BUCLES:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, c, 0.0)
		_ok(d.x < 0.5 and d.y < 0.005, "%s cierra el bucle sin salto (%.2f°, %.4f m)" % [c, d.x, d.y])
	for c in ["emerger", "rugido", "ataque", "ataque_sismico", "ataque_aliento", "herida"]:
		var d := _diferencia_pose(ap, sk, c, ap.get_animation(c).length, "reposo", 0.0)
		_ok(d.x < 1.0 and d.y < 0.01, "%s acaba en la pose del reposo (%.2f°, %.4f m)" % [c, d.x, d.y])
		var e := _diferencia_pose(ap, sk, c, 0.0, "reposo", 0.0)
		if c != "emerger":
			_ok(e.x < 1.0 and e.y < 0.01, "%s empieza en la pose del reposo (%.2f°, %.4f m)" % [c, e.x, e.y])
	var da := _diferencia_pose(ap, sk, "aviso", ap.get_animation("aviso").length, "subterraneo", 0.0)
	_ok(da.x < 1.0 and da.y < 0.01, "aviso acaba como subterraneo (%.2f°, %.4f m)" % [da.x, da.y])
	var dd := _diferencia_pose(ap, sk, "derrota", ap.get_animation("derrota").length, "reposo", 0.0)
	_ok(dd.y > 1.0, "derrota acaba derribado (%.2f m del reposo)" % dd.y)
	for c in CLIPS:
		var a := ap.get_animation(c)
		var ch := _escala_max(a, "chorro")
		_ok((ch > 0.9) == (c == "ataque_aliento"), "%s: chorro %s (escala máx. %.2f)" % [c, "sale" if ch > 0.9 else "escondido", ch])
	var al := ap.get_animation("ataque_aliento")
	var i := _pista(al, "chorro", Animation.TYPE_SCALE_3D)
	_ok(al.scale_track_interpolate(i, 1.80).x < 0.05 and al.scale_track_interpolate(i, 2.2).x > 0.9 and
		al.scale_track_interpolate(i, 2.75).x < 0.05, "el chorro sale entre la descarga (1,85) y su fin (2,6)")
	for c in ["subterraneo", "aviso"]:
		_ok(_escala_max(ap.get_animation(c), "monticulo") < 0.05, "%s: sin montículo (está bajo la arena)" % c)
	var ru := ap.get_animation("rugido")
	var k_lat := _pista(ru, "mandibula_izq" if VER < 3 else "mandibula", Animation.TYPE_ROTATION_3D)
	var giro_lat := 0.0
	if k_lat >= 0:
		giro_lat = rad_to_deg(ru.rotation_track_interpolate(k_lat, 0.0).angle_to(ru.rotation_track_interpolate(k_lat, 1.2)))
	_ok(giro_lat > (25.0 if VER < 3 else 40.0), "rugido: %s se abre (%.1f°)" % ["las mandíbulas laterales" if VER < 3 else "la boca", giro_lat])
	var g := _escala_max(ap.get_animation("ataque_aliento"), "garganta")
	_ok(g > 2.0, "ataque_aliento: la garganta se enciende (escala máx. %.2f)" % g)
	if VER >= 2:
		for c in CLIPS:                                      # v2/v3: placas del suelo solo en la Fractura; arena, solo en el Aliento
			var a := ap.get_animation(c)
			var lo := _escala_max(a, "losa_1")
			var su := _escala_max(a, "succion")
			_ok((lo > 0.9) == (c == "ataque_sismico") and (su > 0.9) == (c == "ataque_aliento"),
				"%s: placas del suelo %.2f, arena aspirada %.2f" % [c, lo, su])
		var sis := ap.get_animation("ataque_sismico")
		var k := _pista(sis, "losa_1", Animation.TYPE_SCALE_3D)
		_ok(k >= 0 and sis.scale_track_interpolate(k, 2.50).x < 0.05 and sis.scale_track_interpolate(k, 2.70).x > 0.9 and
			sis.scale_track_interpolate(k, sis.length).x < 0.05, "Fractura: las placas salen en el impacto (2,53) y se hunden al final")
		var al2 := ap.get_animation("ataque_aliento")
		k = _pista(al2, "succion", Animation.TYPE_SCALE_3D)
		_ok(k >= 0 and al2.scale_track_interpolate(k, 0.40).x < 0.05 and al2.scale_track_interpolate(k, 1.2).x > 0.9 and
			al2.scale_track_interpolate(k, 1.85).x < 0.05, "Aliento: aspira entre 0,45 y 1,7 (la arena se ve)")
		if VER == 2:
			var ap_lat := _pista(ap.get_animation("rugido"), "aleta_izq", Animation.TYPE_ROTATION_3D)
			var giro_al := 0.0
			if ap_lat >= 0:
				var ru2 := ap.get_animation("rugido")
				giro_al = rad_to_deg(ru2.rotation_track_interpolate(ap_lat, 0.55).angle_to(ru2.rotation_track_interpolate(ap_lat, 1.0)))
			_ok(giro_al > 30.0, "rugido: las aletas del cuello se abren (%.1f°)" % giro_al)
		else:                                                # v3: el ceño se frunce al atacar
			var at := ap.get_animation("ataque")
			var kc := _pista(at, "ceja_izq", Animation.TYPE_ROTATION_3D)
			var ceno := 0.0 if kc < 0 else rad_to_deg(at.rotation_track_interpolate(kc, 0.0).angle_to(at.rotation_track_interpolate(kc, 0.7)))
			_ok(ceno > 5.0, "v3, embestida: el ceño se frunce (%.1f°)" % ceno)


func _pista(a: Animation, hueso: String, tipo: int) -> int:
	for k in a.get_track_count():
		if a.track_get_type(k) == tipo and String(a.track_get_path(k)).ends_with(":" + hueso):
			return k
	return -1


func _escala_max(a: Animation, hueso: String) -> float:
	var k := _pista(a, hueso, Animation.TYPE_SCALE_3D)
	if k < 0:
		return 1.0
	var mx := 0.0
	var t := 0.0
	while t <= a.length + 0.001:
		mx = maxf(mx, a.scale_track_interpolate(k, t).x)
		t += DT
	return mx


func _diferencia_pose(ap: AnimationPlayer, sk: Skeleton3D, c1: String, t1: float, c2: String, t2: float) -> Vector2:
	var a1 := ap.get_animation(c1)
	var a2 := ap.get_animation(c2)
	var giro := 0.0
	var mov := 0.0
	for i in sk.get_bone_count():
		var suf := ":" + sk.get_bone_name(i)
		var r1: Quaternion = _valor(a1, suf, Animation.TYPE_ROTATION_3D, t1, sk.get_bone_rest(i).basis.get_rotation_quaternion())
		var r2: Quaternion = _valor(a2, suf, Animation.TYPE_ROTATION_3D, t2, sk.get_bone_rest(i).basis.get_rotation_quaternion())
		giro = maxf(giro, rad_to_deg(r1.angle_to(r2)))
		var p1: Vector3 = _valor(a1, suf, Animation.TYPE_POSITION_3D, t1, sk.get_bone_rest(i).origin)
		var p2: Vector3 = _valor(a2, suf, Animation.TYPE_POSITION_3D, t2, sk.get_bone_rest(i).origin)
		mov = maxf(mov, p1.distance_to(p2))
	return Vector2(giro, mov)


func _valor(a: Animation, sufijo: String, tipo: int, t: float, defecto: Variant) -> Variant:
	for k in a.get_track_count():
		if a.track_get_type(k) == tipo and String(a.track_get_path(k)).ends_with(sufijo):
			return a.rotation_track_interpolate(k, t) if tipo == Animation.TYPE_ROTATION_3D else a.position_track_interpolate(k, t)
	return defecto


func _comprobar_json(datos: Dictionary) -> void:
	print("-- instantes")
	var dj: Dictionary = datos.get("clips", {})
	for c in CLIPS:
		_ok(dj.has(c), "el JSON trae %s" % c)
	_ok(dj.get("reposo", {}).get("bucle", false) and dj.get("subterraneo", {}).get("bucle", false), "en bucle: reposo y subterraneo")
	var G = load(GUION)
	var ins: Dictionary = G.INSTANTES
	for c in ins:
		var j: Dictionary = dj.get(c, {}).get("instantes", {})
		for k in ins[c]:
			_ok(j.has(k) and absf(float(j[k]) - float(ins[c][k])) < 0.002,
				"%s.%s: guion %.4f, JSON %s" % [c, k, ins[c][k], str(j.get(k, "—"))])
	for a in G.ATAQUES:
		var clip: String = G.ATAQUES[a]["clip"]
		var marca := "descarga" if a == "aliento" else "impacto"
		_ok(absf(float(G.ATAQUES[a]["impacto"]) - float(ins[clip][marca])) < 0.002, "%s: el impacto es %s de %s" % [a, marca, clip])
		_ok(absf(float(G.ALCANCES[a]) - float(dj.get(clip, {}).get("alcance", -99))) < 0.1, "%s: alcance %.2f m (JSON %s)" %
			[a, G.ALCANCES[a], str(dj.get(clip, {}).get("alcance", "—"))])


# ---------------------------------------------------------------- el guion, creado como en combate.gd

func _nuevo(exploracion := false) -> Node3D:
	var g: Node3D = load(GUION).new()
	g.ruta_modelo = VERSIONES["alto"]["glb"]
	g.calidad = "medio"
	if exploracion:
		g.en_exploracion = true
		g.recortar_suelo = false
	root.add_child(g)
	for s in ["aviso", "impacto", "ataque_terminado", "clip_terminado"]:
		g.connect(s, func(a): _anotar(g, s, a))
	for s in ["succion", "descarga", "fin_descarga", "rompe_arena", "rugido_pico", "caida", "placas_suelo", "fin_succion"]:
		if g.has_signal(s):
			g.connect(s, func(): _anotar(g, s, null))
	return g


func _anotar(g: Node3D, s: String, a) -> void:
	if not registro.has(s):
		registro[s] = []
	registro[s].append([Engine.get_process_frames(), g.anim.current_animation_position, a, String(g.anim.current_animation)])


func _veces(s: String) -> int:
	return registro.get(s, []).size()


func _clip(g: Node3D) -> String:
	return String(g.anim.current_animation)


func _comprobar_guion() -> void:
	print("-- guion")
	var g := _nuevo()
	await _esperar(3)
	_ok(g.anim != null and g.skel != null, "el guion encuentra el modelo")
	if g.anim == null:
		return
	_ok(absf(g.escala - 0.32) < 0.001, "escala automática del combate: %.2f" % g.escala)
	_ok(g.calidad_usada == "medio", "usa la versión pedida (%s)" % g.calidad_usada)
	_ok(_clip(g) == "reposo", "empieza en reposo (%s)" % _clip(g))
	_ok(g.anim.get_animation("reposo").loop_mode == Animation.LOOP_LINEAR and
		g.anim.get_animation("ataque").loop_mode == Animation.LOOP_NONE, "en bucle el reposo; los ataques no")
	_ok(absf(g.alcance("embestida") - float(g.ALCANCES["embestida"]) * 0.32) < 0.01 and g.alcance("embestida") > 3.5,
		"alcance de la embestida con la escala: %.2f m" % g.alcance("embestida"))
	_ok(g.nombre_ataque("embestida_espinosa") == "embestida" and g.nombre_ataque("golpe_fuerte") == "sismico" and
		g.nombre_ataque("chorro") == "aliento", "alias del combate (embestida_espinosa, golpe_fuerte, chorro)")
	for a in ["embestida", "sismico", "aliento"]:
		await _ataque(g, a, float(g.ATAQUES[a]["impacto"]), a)
	# el aliento: succión, descarga y fin, una vez cada uno, y el chorro encendido entre medias
	registro.clear()
	var visto := [0.0]
	var mirar := func():
		visto[0] = maxf(visto[0], float(g._mats["chorro"][0].get_shader_parameter("fuerza")) if not g._mats["chorro"].is_empty() else 0.0)
	g.descarga.connect(func(): mirar.call_deferred(), CONNECT_ONE_SHOT)
	var pinta := [true]
	var vigila := func():
		while pinta[0]:
			mirar.call()
			await process_frame
	vigila.call()
	await g.atacar("aliento")
	pinta[0] = false
	_ok(_veces("succion") == 1 and _veces("descarga") == 1 and _veces("fin_descarga") == 1,
		"aliento: succión %d, descarga %d, fin %d" % [_veces("succion"), _veces("descarga"), _veces("fin_descarga")])
	if VER >= 2:
		_ok(_veces("fin_succion") == 1 and registro["fin_succion"][0][0] < registro["descarga"][0][0],
			"v%d, aliento: fin_succion una vez y antes de la descarga (%d)" % [VER, _veces("fin_succion")])
		registro.clear()
		await g.atacar("sismico")
		_ok(_veces("placas_suelo") == 1 and _veces("impacto") == 1 and registro["placas_suelo"][0][0] == registro["impacto"][0][0],
			"v%d, Fractura: placas_suelo una vez y en el fotograma del impacto (%d)" % [VER, _veces("placas_suelo")])
		await _esperar(12)
	if VER == 3:
		await _comprobar_boca(g)
	# en el combate el chorro 3D se esconde (salía hacia la cámara; lo dibuja combate_bramavidrio.gd); en la
	# exploración, sí se ve (coordinador, 11/11)
	if g.en_exploracion:
		_ok(visto[0] > 0.8, "aliento: en la exploración el chorro no se ve (fuerza máx. %.2f)" % visto[0])
	else:
		_ok(visto[0] < 0.01, "aliento: en el combate se ve el chorro 3D, que sale hacia la cámara (fuerza máx. %.2f)" % visto[0])
	await _esperar(12)
	# avisar y atacar desde el aviso
	for a in ["embestida", "sismico", "aliento"]:
		registro.clear()
		var llamadas := [0]
		await g.avisar(a)
		_ok(_veces("aviso") == 1, "%s: avisar() avisa una vez (%d)" % [a, _veces("aviso")])
		await _esperar(40)
		_ok(_clip(g) == g.ATAQUES[a]["clip"] and _veces("impacto") == 0, "%s: espera avisando sin golpear (%s)" % [a, _clip(g)])
		var pos: float = g.anim.current_animation_position
		var esp: Array = g.ATAQUES[a]["espera"]
		_ok(pos >= float(esp[0]) - 0.05 and pos <= float(esp[1]) + 0.05, "%s: en su tramo de espera (%.2f s)" % [a, pos])
		await g.atacar(a, func(): llamadas[0] += 1)
		_ok(_veces("impacto") == 1 and llamadas[0] == 1 and _veces("aviso") == 1, "%s desde el aviso: un impacto (%d), una llamada (%d), sin repetir el aviso" %
			[a, _veces("impacto"), llamadas[0]])
		await _esperar(12)
	# herida
	registro.clear()
	g.herida()
	await _esperar(3)
	_ok(_clip(g) == "herida", "herida: reacciona (%s)" % _clip(g))
	await _esperar(45)
	_ok(_clip(g) == "reposo", "herida: vuelve al reposo (%s)" % _clip(g))
	# la luz sigue a sus huesos: en reposo, las aletas brillan con la escala de «brillo»
	var e: Dictionary = g.energia()
	_ok(e["brillo"] > 0.7 and e["chorro"] < 0.05, "en reposo: brillo %.2f, chorro %.2f" % [e["brillo"], e["chorro"]])
	# derrota
	registro.clear()
	g.morir()
	await _esperar(int(3.6 * 30))
	_ok(_veces("caida") == 1, "derrota: cae una vez (%d)" % _veces("caida"))
	_ok(_veces("clip_terminado") >= 1 and registro["clip_terminado"][0][2] == "derrota", "derrota: clip_terminado")
	_ok(g.energia()["brillo"] < 0.2, "derrota: la luz se apaga (%.2f)" % g.energia()["brillo"])
	registro.clear()
	await g.atacar("embestida")
	_ok(_veces("impacto") == 0, "derrotado ya no ataca")
	g.queue_free()
	await _esperar(2)
	# la exploración: escala 1, bajo la arena, vibra, emerge y ruge
	registro.clear()
	var x := _nuevo(true)
	await _esperar(3)
	_ok(absf(x.escala - 1.0) < 0.001 and _clip(x) == "subterraneo", "exploración: escala %.2f y bajo la arena (%s)" % [x.escala, _clip(x)])
	await x.vibrar()
	await _esperar(2)
	_ok(_clip(x) == "subterraneo", "vibrar vuelve a subterraneo (%s)" % _clip(x))
	await x.emerger()
	_ok(_veces("rompe_arena") == 1, "emerger: rompe la arena una vez (%d)" % _veces("rompe_arena"))
	if _veces("rompe_arena") == 1:
		_ok(absf(float(registro["rompe_arena"][0][1]) - 0.2333) <= DT + 0.002, "emerger: a %.3f s" % registro["rompe_arena"][0][1])
	await _esperar(3)
	_ok(_clip(x) == "reposo", "emerger acaba en reposo (%s)" % _clip(x))
	await x.rugir()
	_ok(_veces("rugido_pico") == 1, "rugir: un pico (%d)" % _veces("rugido_pico"))
	var h: Vector3 = x.cabeza() - x.global_position
	_ok(h.y > 4.0 and Vector2(h.x, h.z).length() > 7.0, "en reposo el hocico está alto y por delante del agujero (%s)" % h)
	x.queue_free()
	await _esperar(2)


# v3 (12/11): la boca, medida en cada fotograma de cada clip con el modelo de verdad (el guion creado como en combate):
#  - reposo: CERRADA en todo el bucle (labio y borde de la mandíbula a menos de 1 cm, giro < 0,5°)
#  - ningún clip cierra «de más» (el borde de la mandíbula nunca sube por encima del labio: no se mete en el cráneo)
#  - se abre con fuerza al rugir y en el Aliento (> 40°) y está cerrada en el mordisco (impacto de la embestida)
#  - las garras no patinan en el reposo (la muñeca quieta en el suelo)
func _comprobar_boca(g: Node3D) -> void:
	print("-- v3: la boca y las garras, fotograma a fotograma")
	g._eventos = []
	g._espera = []
	var max_abierta := {}
	var peor_cierre := {}
	var peor_borde := {}
	for c in CLIPS:
		g._clip = c
		g.anim.play(c, 0.0)
		g.anim.speed_scale = 0.0
		var largo: float = g.anim.get_animation(c).length
		var t := 0.0
		max_abierta[c] = 0.0
		peor_borde[c] = -INF
		peor_cierre[c] = 0.0
		var manos: Array = []
		while t <= largo + 0.001:
			g.anim.seek(t, true)
			g.anim.advance(0.0)
			var ang: float = g.angulo_boca()
			max_abierta[c] = maxf(max_abierta[c], ang)
			peor_cierre[c] = maxf(peor_cierre[c], g.cierre_boca())
			peor_borde[c] = maxf(peor_borde[c], g.borde_sobre_labio())
			if c == "reposo":
				var i: int = g.skel.find_bone("mano_izq")
				if i >= 0:
					manos.append(g.skel.global_transform * g.skel.get_bone_global_pose(i).origin / g.escala)
			if c == "ataque" and absf(t - 1.0) < 0.001:
				_ok(g.cierre_boca() < 0.02, "embestida: en el mordisco (1,0 s) la boca está cerrada (%.3f m)" % g.cierre_boca())
			t += DT
		if c == "reposo":
			_ok(peor_cierre[c] < 0.01 and max_abierta[c] < 0.5, "reposo: la boca CERRADA en todo el bucle (labio-mandíbula %.4f m, giro máx. %.2f°)" %
				[peor_cierre[c], max_abierta[c]])
			var desliz := 0.0
			for m in manos:
				desliz = maxf(desliz, (m as Vector3).distance_to(manos[0]))
			_ok(not manos.is_empty() and desliz < 0.05, "reposo: la garra no patina (%.3f m)" % desliz)
		_ok(peor_borde[c] < 0.01, "%s: la mandíbula nunca cierra de más (borde sobre el labio, máx. %.4f m)" % [c, peor_borde[c]])
	print("   apertura máxima por clip (°): %s" % str(max_abierta))
	_ok(max_abierta["rugido"] > 40.0 and max_abierta["ataque_aliento"] > 40.0,
		"la boca se abre con fuerza al rugir (%.1f°) y en el Aliento (%.1f°)" % [max_abierta["rugido"], max_abierta["ataque_aliento"]])
	g.anim.speed_scale = 1.0
	g.reposo()
	await _esperar(3)


func _ataque(g: Node3D, a: String, ancla: float, texto: String) -> void:
	registro.clear()
	var llamadas := [0]
	var f0 := Engine.get_process_frames()
	await g.atacar(a, func(): llamadas[0] += 1)
	var dur := (Engine.get_process_frames() - f0) * DT
	_ok(_veces("impacto") == 1 and llamadas[0] == 1, "%s: un impacto (%d) y una llamada (%d)" % [texto, _veces("impacto"), llamadas[0]])
	if _veces("impacto") == 1:
		var pos: float = registro["impacto"][0][1]
		_ok(absf(pos - ancla) <= DT + 0.002, "%s: impacto a %.3f s (ancla %.3f)" % [texto, pos, ancla])
	_ok(_veces("ataque_terminado") == 1, "%s: ataque_terminado (%.2f s)" % [texto, dur])
	await _esperar(12)
	_ok(_clip(g) == "reposo", "%s: vuelve al reposo (%s)" % [texto, _clip(g)])


# ---------------------------------------------------------------- encuadre para MODELOS de combate.gd

# La misma cámara que _crear_rig_3d (ortográfica, 12° desde arriba, a 6 m). Cada clip, cada 0,1 s, mirando a los
# héroes: la cabeza, la boca, el cuello y la cola que asoma; qué cae dentro de la ventana 3D y qué no.
func _encuadre() -> void:
	print("-- encuadre propuesto")
	var vp := SubViewport.new()
	vp.size = VP
	vp.own_world_3d = true
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ALTO_VISTA
	vp.add_child(cam)
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, CENTRO_Y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, CENTRO_Y, 0))
	var g: Node3D = load(GUION).new()
	g.calidad = "bajo"
	vp.add_child(g)
	await _esperar(3)
	var sk: Skeleton3D = g.skel
	var detras := 0
	var por_lados := 0
	var fuera := {}
	for c in CLIPS:
		if c in ["subterraneo", "aviso"]:
			continue
		g._clip = c
		g._eventos = []
		g._espera = []
		g.anim.play(c, 0.0)
		g.anim.speed_scale = 0.0
		var largo: float = g.anim.get_animation(c).length
		var t := 0.0
		while t <= largo + 0.001:
			g.anim.seek(t, true)
			g.anim.advance(0.0)
			var pts: Array[Vector3] = [g.cabeza(), g.boca(), g.centro()]
			for hueso in ["col_01", "col_03", "col_06", "col_09"]:
				pts.append(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(hueso)).origin)
			for w in pts:
				if w.y < -0.1:
					continue
				var local := cam.global_transform.affine_inverse() * w
				if local.z > -0.05:
					detras += 1
				var s := cam.unproject_position(w)
				if s.x < 0 or s.y < 0 or s.x > VP.x or s.y > VP.y:
					fuera[c] = fuera.get(c, 0) + 1
				if s.x < 0 or s.x > VP.x or s.y > VP.y:
					por_lados += 1
					print("    fuera por un lado o por abajo: %s %.1f s en %s" % [c, t, s])
			t += 0.1
	var pies := cam.unproject_position(Vector3.ZERO)
	var alto := cam.unproject_position(Vector3(0, 9.0 * g.escala, 0))
	var px_m := VP.y / ALTO_VISTA * ESC
	print("  vp %s, alto_vista %.1f, centro_y %.1f, esc %.2f: %.0f px por metro (a escala %.2f: %.0f px por metro del gusano)" %
		[VP, ALTO_VISTA, CENTRO_Y, ESC, px_m, g.escala, px_m * g.escala])
	print("  pies en la ventana y=%.0f; lo alto del reposo y=%.0f → %.0f px de alto en la escena" % [pies.y, alto.y, (pies.y - alto.y) * ESC])
	print("  puntos fuera de la ventana por clip: %s" % str(fuera))
	_ok(detras == 0, "nada queda detrás de la cámara del combate (%d puntos)" % detras)
	for c in ["reposo", "rugido", "ataque", "ataque_aliento", "herida", "derrota"]:
		_ok(not fuera.has(c), "%s cabe en la ventana 3D (%d puntos fuera)" % [c, fuera.get(c, 0)])
	_ok(por_lados == 0, "ningún clip se sale por los lados ni por abajo (%d puntos)" % por_lados)
	print("  (emerger y ataque_sismico se alzan por encima de la ventana a propósito: %d y %d puntos; en el combate ese borde"
		% [fuera.get("emerger", 0), fuera.get("ataque_sismico", 0)] + " queda por encima de la pantalla: fotos_bramavidrio_combate.gd)")
	vp.queue_free()
	await _esperar(2)
