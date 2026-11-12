extends SceneTree
# V12 (12/11/2026): el modelo de Humbaba (enemigos/humbaba/, fuente/crear_humbaba.py) y su guion humbaba_3d.gd, sin
# ventana. Lo que se mira está en la nota de lista_pruebas.txt; aquí, por orden: estático (GLB, huesos, triángulos,
# texturas), rig (huesos de control fuera, puntos del cuerpo), animaciones (clips, duraciones, bucles, pies quietos,
# luz) y mecánicas del guion (impactos en su evento, Réquiem, fases, giro, derrota).

const H3 := preload("res://enemigos/humbaba/humbaba_3d.gd")
const PRESUPUESTO := {"alto": 36000, "medio": 20000, "bajo": 13000}
const CLIPS := ["idle", "idle_angry", "walk", "turn_left", "turn_right", "roar", "hit_light", "hit_heavy", "stagger",
	"phase_transition", "death", "atk_puno", "atk_raices", "atk_aliento", "atk_guadana", "atk_ojo", "atk_llamada",
	"atk_abrazo", "requiem_inicio", "requiem_carga", "requiem_golpe", "vulnerable", "vulnerable_fin"]
var fallos: Array = []
var hechos: Array = []


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _initialize() -> void:
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	var datos: Dictionary = H3.leer_json()
	_ok(not datos.is_empty(), "no se lee humbaba_clips.json")
	for perfil in ["alto", "medio", "bajo"]:
		_estatico(perfil, datos)
	await _guion(datos)
	for h in hechos:
		print("  · ", h)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _esqueleto(c)
		if s:
			return s
	return null


func _estatico(perfil: String, datos: Dictionary) -> void:
	var ruta: String = H3.RUTAS[perfil]
	_ok(ResourceLoader.exists(ruta), "%s: falta %s" % [perfil, ruta])
	if not ResourceLoader.exists(ruta):
		return
	var m: Node3D = (load(ruta) as PackedScene).instantiate()
	var sk := _esqueleto(m)
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_ok(sk != null and ap != null, "%s: sin esqueleto o sin animaciones" % perfil)
	if sk == null or ap == null:
		m.free()
		return
	var n := sk.get_bone_count()
	_ok(n >= 60 and n <= 90 and n == int(datos.get("huesos_deformantes", -1)), "%s: %d huesos (60-90, JSON %s)" % [perfil, n, str(datos.get("huesos_deformantes"))])
	for i in n:
		var b := sk.get_bone_name(i)
		_ok(not b.begins_with("ctrl_") and not b.begins_with("polo_"), "%s: se exportó el control %s" % [perfil, b])
	for b in ["raiz", "pelvis", "cabeza", "mandibula", "ojo", "nucleo", "luz", "baston", "guadana", "palma_i", "palma_d",
			"tobillo_i", "tobillo_d", "corona_c2", "colgante5_c"]:
		_ok(sk.find_bone(b) >= 0, "%s: falta el hueso %s" % [perfil, b])
	_ok(sk.get_bone_parent(sk.find_bone("baston")) == sk.find_bone("palma_d"), "%s: el bastón no cuelga de la palma derecha" % perfil)
	for clip in CLIPS:
		_ok(ap.has_animation(clip), "%s: falta el clip %s" % [perfil, clip])
		if ap.has_animation(clip) and datos.get("clips", {}).has(clip):
			var dj: float = float(datos["clips"][clip]["duracion"])
			_ok(absf(ap.get_animation(clip).length - dj) < 1.5 / 30.0, "%s: %s dura %.3f y el JSON %.3f" % [perfil, clip, ap.get_animation(clip).length, dj])
	var tris := 0
	var mallas := 0
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var me: Mesh = (mi as MeshInstance3D).mesh
		mallas += 1
		for s in me.get_surface_count():
			var arr := me.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() / 3) if idx != null else (arr[Mesh.ARRAY_VERTEX].size() / 3)
	_ok(tris <= PRESUPUESTO[perfil], "%s: %d triángulos (máx. %d)" % [perfil, tris, PRESUPUESTO[perfil]])
	_ok(abs(tris - int(datos.get("triangulos", {}).get(perfil, -1))) < 50, "%s: %d triángulos y el JSON dice %s" % [perfil, tris, str(datos.get("triangulos", {}).get(perfil))])
	_ok(mallas == 3, "%s: %d mallas (cuerpo, armadura y bastón)" % [perfil, mallas])
	var tex = load(H3.TEXTURAS[perfil])
	_ok(tex is CompressedTexture2D and (tex as Texture2D).get_image().is_compressed(), "%s: la textura no está comprimida en VRAM" % perfil)
	hechos.append("%s: %d huesos, %d clips, %d triángulos, textura %dx%d" % [perfil, n, ap.get_animation_list().size(), tris,
		tex.get_width() if tex else 0, tex.get_height() if tex else 0])
	m.free()


func _guion(datos: Dictionary) -> void:
	var h = H3.new()
	h.calidad = "bajo"
	root.add_child(h)
	await _esperar(3)
	_ok(h.anim != null and h.skel != null and h.calidad_usada == "bajo", "el guion no carga el perfil bajo")
	_ok(is_equal_approx(h.modelo.scale.x, 0.4) and h.recortar, "escala del combate o recorte")
	for clip in ["idle", "idle_angry", "walk", "requiem_carga", "vulnerable"]:
		_ok(h.anim.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, "%s no está en bucle" % clip)
	# los puntos del cuerpo, en su sitio (reposo, combate: ×0,4)
	h.anim.play("idle")
	h.anim.seek(0.0, true)
	await _esperar(2)
	var ojo: Vector3 = h.punto("ojo")
	var nucleo: Vector3 = h.punto("nucleo")
	var punta: Vector3 = h.punto("baston_punta")
	_ok(ojo.y > nucleo.y and ojo.y > 4.0 and ojo.y < 5.0, "el ojo no está a su altura (%.2f)" % ojo.y)
	_ok(nucleo.y > 3.0 and nucleo.y < 3.9, "el núcleo no está a su altura (%.2f)" % nucleo.y)
	_ok(absf(punta.y) < 0.12, "la punta del bastón no está en el suelo (%.3f)" % punta.y)
	# pies quietos en el reposo, el rugido y los golpes (no en andar ni en girar)
	for clip in ["idle", "roar", "atk_ojo", "atk_aliento", "hit_light"]:
		var mx := await _mueve_pies(h, clip)
		_ok(mx < 0.02, "%s: los pies se mueven %.3f m" % [clip, mx])
	hechos.append("puntos: ojo %.2f, núcleo %.2f, punta del bastón %.3f; pies quietos" % [ojo.y, nucleo.y, punta.y])
	# cada ataque: sus impactos una vez, en el fotograma de su evento
	for a in ["puno", "raices", "aliento", "guadana", "ojo", "llamada", "abrazo"]:
		var clip: String = h.ATAQUES[a]
		var golpes: Array = []
		var eventos: Array = []
		var cb := func(): golpes.append(h.anim.current_animation_position)
		var ce := func(n: String): eventos.append(n)
		await h.atacar(a, cb, ce)
		var esperados: Array = h.IMPACTOS.get(clip, ["impacto"])
		_ok(golpes.size() == esperados.size(), "%s: %d impactos (deben ser %d)" % [a, golpes.size(), esperados.size()])
		for i in mini(golpes.size(), esperados.size()):
			var t: float = h.tiempo(clip, esperados[i])
			_ok(absf(golpes[i] - t) <= 2.5 / 30.0, "%s: impacto a %.3f s y su evento a %.3f s" % [a, golpes[i], t])
		var evs: Dictionary = h.eventos_de(clip)
		_ok(eventos.size() == evs.size(), "%s: %d eventos de %d" % [a, eventos.size(), evs.size()])
		_ok(h.clip_actual() == "idle", "%s: no vuelve al reposo (%s)" % [a, h.clip_actual()])
	hechos.append("ataques: impactos en su evento (±2 fotogramas), eventos completos, vuelta al reposo")
	# luz: sigue al hueso «luz» (el Ojo la sube)
	h.anim.play("atk_ojo")
	h.anim.seek(2.2, true)
	await _esperar(2)
	var e: float = h._mat_madera.get_shader_parameter("energia")
	_ok(e > 2.5, "la luz no sube con el Ojo del Juicio (%.2f)" % e)
	# Réquiem en dos tiempos
	await h.requiem_preparar()
	_ok(h.cargando and h.clip_actual() == "requiem_carga", "el Réquiem no queda cargando")
	var n_imp := [0]
	await h.requiem_descargar(func(): n_imp[0] += 1)
	_ok(n_imp[0] == 1 and h.vulnerable and h.clip_actual() == "vulnerable", "el Réquiem: %d impactos, vulnerable %s" % [n_imp[0], h.vulnerable])
	await h.recuperarse()
	_ok(not h.vulnerable and h.clip_actual() == "idle", "no se recupera")
	# fases
	await h.cambiar_fase(2)
	_ok(h.fase == 2 and h.clip_actual() == "idle_angry" and not h.armadura_rota(), "la fase 2")
	_ok((h._mat_brillo.get_shader_parameter("grietas") as float) > 0.5, "el núcleo no se agrieta en la fase 2")
	await h.cambiar_fase(3)
	_ok(h.fase == 3 and h.armadura_rota(), "la fase 3 no rompe la armadura")
	# giro de 45°: pasa al pivote al acabar
	var r0: float = h.pivote.rotation.y
	await h.girar(true)
	_ok(absf(wrapf(h.pivote.rotation.y - r0 - deg_to_rad(45.0), -PI, PI)) < 0.01, "el giro no pasa al pivote")
	# derrota
	await h.derrota()
	_ok(h.muerta() and (h._mat_madera.get_shader_parameter("apagar") as float) < 0.5, "la derrota no apaga")
	hechos.append("Réquiem en dos tiempos, fases 2 y 3, giro de 45°, derrota")
	h.queue_free()
	await _esperar(2)


func _mueve_pies(h, clip: String) -> float:
	var i: int = h.skel.find_bone("tobillo_i")
	var j: int = h.skel.find_bone("tobillo_d")
	h.anim.play(clip, 0.0)
	h.anim.seek(0.0, true)
	await _esperar(1)
	var a0: Vector3 = h.skel.get_bone_global_pose(i).origin
	var b0: Vector3 = h.skel.get_bone_global_pose(j).origin
	var mx := 0.0
	var dur: float = h.anim.get_animation(clip).length
	var t := 0.0
	while t < dur:
		h.anim.seek(t, true)
		mx = maxf(mx, maxf(h.skel.get_bone_global_pose(i).origin.distance_to(a0), h.skel.get_bone_global_pose(j).origin.distance_to(b0)))
		t += 2.0 / 30.0
	return mx * h.escala
