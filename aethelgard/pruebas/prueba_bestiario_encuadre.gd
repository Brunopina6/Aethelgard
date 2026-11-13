extends SceneTree
# V12, bestiario (13/11/2026): el encuadre de la ventana 3D del Peón de Linde y del Velador de Corteza, v1 y v2.
# Cada enemigo 3D del combate se dibuja en su propia ventana (SubViewport) de MODELOS[...]["vp"] píxeles (combate.gd
# _crear_rig_3d), con la cámara centrada en sus pies. Esta prueba proyecta los huesos y las puntas de las armas en todos
# los clips (como prueba_enemigos_v12 _encuadre, a 277 px de ventana por metro, la nitidez de los demás enemigos v12)
# y dice qué ventana hace falta para que nada se corte; comprueba que la de MODELOS basta y cuánto ahorra frente a la
# de la v1 (píxeles de la ventana: memoria de vídeo y relleno en la GPU). Sin ventana, sin datos de partida.

const PX_VP := 277.0
const MARGEN := 0.18
const CASOS := {
	"peon_linde": {"script": "res://enemigos/peon_linde/peon_linde_3d.gd",
		"puntas": [["arma.R", Vector3(0, 0.74, 0)], ["arma.L", Vector3(0, 0.74, 0)], ["arma.R", Vector3(0, -0.22, 0)],
			["arma.L", Vector3(0, -0.22, 0)], ["cabeza", Vector3(0, 0.22, 0)]]},
	"velador_corteza": {"script": "res://enemigos/velador_corteza/velador_corteza_3d.gd",
		"puntas": [["arma.R", Vector3(0, 0.85, 0)], ["arma.R", Vector3(0, -0.14, 0)], ["arma.L", Vector3(0, 0.32, 0)],
			["arma.L", Vector3(0, -0.32, 0)], ["arma.L", Vector3(0, 0, 0.32)], ["arma.L", Vector3(0, 0, -0.32)],
			["cabeza", Vector3(0, 0.30, 0)]]},
}
var fallos: Array = []
var raiz: Node


func _initialize() -> void:
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _probar() -> void:
	raiz = Node.new()
	root.add_child(raiz)
	var C = load("res://combate.gd")
	for nombre in CASOS:
		var res := {}
		for v in [1, 2]:
			Engine.set_meta("bestiario_v1", v == 1)
			res[v] = await _encuadre(nombre, v)
		Engine.remove_meta("bestiario_v1")
		var m: Dictionary = C.MODELOS[nombre]
		var vp: Vector2i = m["vp"]
		var px_m: float = vp.y / float(m["alto_vista"])
		_ok(absf(px_m - PX_VP) < 8.0, "%s: MODELOS da %.0f px por metro (los v12, 277)" % [nombre, px_m])
		var n2: Vector2i = res[2]["vp"]
		_ok(vp.x >= n2.x and vp.y >= n2.y, "%s: la ventana de MODELOS %s no basta para la v2 (%s)" % [nombre, vp, n2])
		_ok(absf(float(m["alto_vista"]) - res[2]["alto_vista"]) < 0.15, "%s: alto_vista %.2f y la v2 pide %.2f" % [
			nombre, m["alto_vista"], res[2]["alto_vista"]])
		var a1: int = res[1]["vp"].x * res[1]["vp"].y
		var a2: int = vp.x * vp.y
		print("OK: %s: v1 necesita %s (%.2f m), la v2 %s (%.2f m); MODELOS usa %s: %.0f %% de los píxeles de la v1" % [
			nombre, res[1]["vp"], res[1]["alto_vista"], n2, res[2]["alto_vista"], vp, 100.0 * a2 / a1])
		print("    PROPUESTA v2: vp %s, alto_vista %.2f, centro_y %.2f" % [n2, res[2]["alto_vista"], res[2]["centro_y"]])
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _encuadre(nombre: String, version: int) -> Dictionary:
	var p = load(CASOS[nombre]["script"]).new()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	var vp := SubViewport.new()
	vp.size = Vector2i(1000, 1000)
	vp.own_world_3d = true
	raiz.add_child(vp)
	vp.add_child(cam)
	vp.add_child(p)
	await process_frame
	_ok(p.version == version, "%s: se cargó la v%d en vez de la v%d" % [nombre, p.version, version])
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, sin(ang) * 6.0, cos(ang) * 6.0), Vector3.ZERO)
	cam.current = true
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var por_clip := {}
	for c in p.anim.get_animation_list():
		if c in ["derrota", "desaparecer"]:                 # se caen o se hunden (no cuentan, como en los v12)
			continue
		var dur: float = p.anim.get_animation(c).length
		for k in 13:
			p.anim.play(c, 0.0)
			p.anim.seek(dur * k / 12.0, true)
			p.skel.force_update_all_bone_transforms()
			var pts := []
			for i in p.skel.get_bone_count():
				if p.skel.get_bone_name(i) in ["luz"]:
					continue
				pts.append(p.hueso_mundo(p.skel.get_bone_name(i), Vector3.ZERO))
			for pt in CASOS[nombre]["puntas"]:
				pts.append(p.hueso_mundo(pt[0], pt[1]))
			for q in pts:
				if q.y < -0.3:                             # (la estaca lanzada, escondida bajo el suelo: no se ve)
					continue
				var s: Vector2 = cam.unproject_position(q)
				lo = Vector2(minf(lo.x, s.x), minf(lo.y, s.y))
				hi = Vector2(maxf(hi.x, s.x), maxf(hi.y, s.y))
				por_clip[c] = maxf(float(por_clip.get(c, 0.0)), absf(s.x - 500.0) / 100.0)
	var m_lo := (lo - Vector2(500, 500)) / 100.0
	var m_hi := (hi - Vector2(500, 500)) / 100.0
	var alto_vista := snappedf((m_hi.y - m_lo.y) + 2 * MARGEN, 0.05)
	var centro_y := snappedf(-(m_lo.y + m_hi.y) / 2.0 / cos(ang), 0.05)
	var ancho := 2.0 * maxf(absf(m_lo.x), absf(m_hi.x)) + 2 * MARGEN
	var vpv := Vector2i(int(ceil(ancho * PX_VP / 10.0) * 10), int(ceil(alto_vista * PX_VP / 10.0) * 10))
	var orden := por_clip.keys()
	orden.sort_custom(func(a, b): return por_clip[a] > por_clip[b])
	print("    v%d, lo más ancho (m desde el centro): %s" % [version, ", ".join(orden.slice(0, 4).map(func(k): return "%s %.2f" % [k, por_clip[k]]))])
	p.queue_free()
	vp.queue_free()
	await process_frame
	return {"vp": vpv, "alto_vista": alto_vista, "centro_y": centro_y}
