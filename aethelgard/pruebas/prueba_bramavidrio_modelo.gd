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

const CARPETA := "res://enemigos/bramavidrio/"
const GUION := CARPETA + "bramavidrio_3d.gd"
const JSON_CLIPS := CARPETA + "bramavidrio_clips.json"
const VERSIONES := {
	"alto": {"glb": CARPETA + "bramavidrio.glb", "tex": CARPETA + "bramavidrio_piel.webp", "tris": 25000, "lado": 2048},
	"medio": {"glb": CARPETA + "bramavidrio_medio.glb", "tex": CARPETA + "bramavidrio_piel_medio.webp", "tris": 12000, "lado": 1024},
	"bajo": {"glb": CARPETA + "bramavidrio_bajo.glb", "tex": CARPETA + "bramavidrio_piel_bajo.webp", "tris": 6000, "lado": 512},
}
const CLIPS := ["reposo", "subterraneo", "aviso", "emerger", "rugido", "ataque", "ataque_sismico", "ataque_aliento",
	"herida", "derrota"]
const BUCLES := ["reposo", "subterraneo"]
const SUPERFICIES := ["piel", "vidrio", "garganta", "arena", "chorro"]
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
	print("== Bramavidrio: modelo, clips y guion")
	var datos := _leer_json()
	for v in VERSIONES:
		await _comprobar_glb(v, datos)
	_comprobar_json(datos)
	await _comprobar_guion()
	await _encuadre()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


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
	var faltan := esperados.filter(func(h): return sk.find_bone(h) < 0)
	_ok(faltan.is_empty() and sk.get_bone_count() == esperados.size(),
		"[%s] %d huesos (faltan: %s)" % [v, sk.get_bone_count(), faltan])
	var lista := Array(ap.get_animation_list()).map(func(x): return String(x))
	for c in CLIPS:
		_ok(c in lista, "[%s] existe el clip %s" % [v, c])
	_ok(lista.size() == CLIPS.size(), "[%s] solo esos 10 clips (%d)" % [v, lista.size()])
	var dj: Dictionary = datos.get("clips", {})
	var quietos := ["raiz", "brillo", "garganta", "chorro", "monticulo"]   # no giran nunca: el importador quita su pista
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
		var sin_escala := ["brillo", "garganta", "chorro", "monticulo"].filter(func(h): return not escalan.has(h))
		_ok(sin_giro.is_empty() and sin_escala.is_empty(), "[%s] %s anima los %d huesos que se mueven y la escala de los 4 de datos (faltan %s %s)" %
			[v, c, esperados.size() - quietos.size(), sin_giro, sin_escala])
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
	var k_lat := _pista(ru, "mandibula_izq", Animation.TYPE_ROTATION_3D)
	var giro_lat := 0.0
	if k_lat >= 0:
		giro_lat = rad_to_deg(ru.rotation_track_interpolate(k_lat, 0.0).angle_to(ru.rotation_track_interpolate(k_lat, 1.2)))
	_ok(giro_lat > 25.0, "rugido: las mandíbulas laterales se abren (%.1f°)" % giro_lat)
	var g := _escala_max(ap.get_animation("ataque_aliento"), "garganta")
	_ok(g > 2.0, "ataque_aliento: la garganta se enciende (escala máx. %.2f)" % g)


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
	g.ruta_modelo = CARPETA + "bramavidrio.glb"
	g.calidad = "medio"
	if exploracion:
		g.en_exploracion = true
		g.recortar_suelo = false
	root.add_child(g)
	for s in ["aviso", "impacto", "ataque_terminado", "clip_terminado"]:
		g.connect(s, func(a): _anotar(g, s, a))
	for s in ["succion", "descarga", "fin_descarga", "rompe_arena", "rugido_pico", "caida"]:
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
	_ok(absf(g.alcance("embestida") - 11.52 * 0.32) < 0.01, "alcance de la embestida con la escala: %.2f m" % g.alcance("embestida"))
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
