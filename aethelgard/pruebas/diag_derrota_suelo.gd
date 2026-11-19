extends SceneTree
# DIAGNÓSTICO (18/11), no prueba: ¿cuánto se hunde cada héroe bajo el suelo en el derribo y la derrota?
# (REVISION_PERSONAJES_15_11.md: «derrota de Garon v2/v3 hundida por el clip»; prueba_capa_garon lo ve: hasta -0,29 m en
# v2 y -0,56 m en v3). Para Kael, Lya y Garon en originales, v2 y v3: morir(), y durante unos 6 s, el punto más bajo del
# cuerpo (vértices con piel, como prueba_capa_garon._cuerpo) respecto al pie del nodo, y la altura de la cadera.
# Uso: Godot --headless --path aethelgard --fixed-fps 30 --script res://pruebas/diag_derrota_suelo.gd [-- solo=garon]
# 19/11 (C-5): además, POR PARTES (cabeza, manos, pies, cadera, arma) respecto al suelo (el origen del nodo, y = 0): lo más
# bajo en toda la caída y lo más bajo ya tumbado (de 2 s a 6 s, más de una vuelta del bucle «derrota» de Nix). El arma
# cuenta los vértices con piel de su hueso (Nix «arma_d», Naira «astrolabio») y las mallas sin piel colgadas del
# esqueleto (la vara de maga_3d.gd o el cetro por socket de la Nix del FBX). «nix fbx»: la Nix del FBX (nix_fbx.gd).
# Naira y Nix ejecutan su PROPIO morir() (naira_3d.gd: clip «derrota»; nix_3d.gd: «derribo» y «derrota» en bucle), no
# el desplome de maga_3d.gd (docs/v12/DERROTA_SUELO_18_11.md, «Naira y Nix medidas el 19/11»).
# (19/11, revisión) Las cifras son MUESTREADAS: cada 5 fotogramas (paso=N para otro, p. ej. paso=1 cada fotograma) y
# con un submuestreo de vértices (~6000 con piel y ~3000 sin piel por superficie; vertices=todos, sin submuestreo): el
# mínimo real puede ser algo más bajo. «En el último instante» es UNA muestra, la de 6 s tras morir() (antes juntaba las dos últimas).
# (19/11, KAEL_ESPERAS_19_11) get_bone_global_pose() desde _process da la pose del CLIP, sin los gestos de gestos_3d.gd
# (SkeletonModifier3D: Godot los aplica al actualizar el esqueleto, dibuja la piel y vuelve a dejar la pose del clip).
# pose=final mide la pose que se DIBUJA: guarda las poses en la señal skeleton_updated (ya con los gestos; la última
# actualización, como mucho un fotograma por detrás). Sin pose=final, las cifras salen como antes (solo el clip).

const SCRIPTS := {
	"kael": {"originales": "res://kael_3d.gd", "v2": "res://personajes/heroes_v2/kael_v2_3d.gd",
		"v3": "res://personajes/heroes_v3/kael_v3_3d.gd"},
	"lya": {"originales": "res://maga_3d.gd", "v2": "res://personajes/heroes_v2/lya_v2_3d.gd",
		"v3": "res://personajes/heroes_v3/lya_v3_3d.gd"},
	"garon": {"originales": "res://garon_3d.gd", "v2": "res://personajes/heroes_v2/garon_v2_3d.gd",
		"v3": "res://personajes/heroes_v3/garon_v3_3d.gd"},
	"naira": {"originales": "res://personajes/naira/naira_3d.gd"},     # (su propio morir(): no el desplome de maga_3d.gd)
	"nix": {"originales": "res://personajes/nix/nix_3d.gd", "fbx": "res://personajes/nix/nix_3d.gd"},
}
const VERSIONES := ["originales", "v2", "v3", "fbx"]
const ESPERA := 20           # fotogramas antes de morir()
const DURA := 180            # fotogramas tras morir() (6 s a 30)
const TUMBADO := 60          # fotogramas tras morir() desde los que cuenta «tumbado» en las partes (2 s)
var paso := 5                # fotogramas entre muestras (paso=N); ESPERA + DURA debe ser múltiplo
var todos := false           # vertices=todos: cada vértice, sin submuestreo
const PARTES := ["cabeza", "manos", "pies", "cadera", "arma", "resto"]

var casos: Array = []
var ci := -1
var g: Node3D
var f := 0
var bajo := INF
var bajo_t := 0.0
var cadera_min := INF
var final_bajo := INF
var de_pie := INF
var hueso_bajo := ""
var _hb := ""
var por_hueso := {}
var ultimo := false
var parte_de := {}           # nombre de hueso → parte (PARTES)
var partes := {}             # parte → [peor, a los s, peor tumbado, hueso del peor tumbado]
var medir_partes := false
var pose_final := false      # pose=final: la pose con los gestos (skeleton_updated)
var _poses := {}             # id del esqueleto → poses globales de la última actualización


func _initialize() -> void:
	var solo := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			solo = a.trim_prefix("solo=")
		elif a.begins_with("paso="):
			paso = maxi(1, int(a.trim_prefix("paso=")))
		elif a == "vertices=todos":
			todos = true
		elif a == "pose=final":
			pose_final = true
	for h in SCRIPTS:
		if solo != "" and h != solo:
			continue
		for v in VERSIONES:
			if SCRIPTS[h].has(v):
				casos.append([h, v])
	_siguiente()


func _siguiente() -> void:
	if g != null:
		print("%-6s %-10s de pie %+.3f m · cuerpo más bajo %+.3f m (a los %.2f s) · al final %+.3f m · hundido bajo los pies %.3f m · cadera más baja %+.3f m · lo más bajo, del hueso %s" % [
			casos[ci][0], casos[ci][1], de_pie, bajo, bajo_t, final_bajo, maxf(0.0, de_pie - final_bajo), cadera_min, hueso_bajo])
		var hs := por_hueso.keys()
		hs.sort_custom(func(a, b2): return float(por_hueso[a]) < float(por_hueso[b2]))
		var txt := []
		for h in hs.slice(0, 8):
			txt.append("%s %+.2f" % [h, float(por_hueso[h]) - de_pie])
		print("    bajo los pies, por hueso: ", ", ".join(txt))
		var tp := []
		for k in PARTES:
			if partes.has(k):
				var d: Array = partes[k]
				tp.append("%s %+.3f (a los %.2f s) · tumbado %+.3f (%s) · al final %d %% bajo el suelo, de %+.3f a %+.3f" % [
					k, d[0], d[1], d[2], d[3], roundi(100.0 * d[5] / maxf(1.0, d[4])), d[7], d[6]])
		print("    por partes, respecto al suelo (y = 0), peor en la caída · peor tumbado (2-6 s) · en el último instante: ",
			"; ".join(tp))
		g.queue_free()
		g = null
	ci += 1
	if ci >= casos.size():
		quit(0)
		return
	var v: String = casos[ci][1]
	var vh := "originales" if v == "fbx" else v      # (la Nix del FBX: su interruptor; los héroes, los de siempre)
	Engine.set_meta("heroes_version", vh)
	Engine.set_meta("heroes_v2", vh != "originales")
	Engine.set_meta("heroes_v3", vh == "v3")
	Engine.set_meta("nix_fbx", v == "fbx")
	parte_de = {}
	partes = {}
	medir_partes = false
	g = Node3D.new()
	g.set_script(load(SCRIPTS[casos[ci][0]][v]))
	root.add_child(g)
	f = 0
	bajo = INF
	cadera_min = INF
	final_bajo = INF
	de_pie = INF


func _process(_dt: float) -> bool:
	if g == null:
		return false
	f += 1
	if f == ESPERA - 1:
		var sk0: Skeleton3D = _esqueleto()
		if sk0 != null:
			de_pie = _bajo(sk0)
	if f == ESPERA:
		g.morir()
	elif f > ESPERA and f % paso == 0:
		var sk: Skeleton3D = _esqueleto()
		if sk != null:
			ultimo = f == ESPERA + DURA                  # (una sola muestra: la de 6 s)
			if ultimo:
				por_hueso = {}
			medir_partes = true
			var b := _bajo(sk)
			medir_partes = false
			if b < bajo:
				bajo = b
				bajo_t = (f - ESPERA) / 30.0
			if f > ESPERA + DURA - 30 and b < final_bajo:
				final_bajo = b
				hueso_bajo = _hb
			var hc := sk.find_bone("Hips")
			if hc < 0:
				hc = sk.find_bone("cadera")                  # (19/11) Naira: huesos con nombres propios
			if hc < 0:
				for i in sk.get_bone_count():
					if sk.get_bone_name(i).ends_with("Hips"):
						hc = i
						break
			if hc >= 0:
				cadera_min = minf(cadera_min, (sk.global_transform * _pose(sk, hc).origin).y - g.global_position.y)
	if f >= ESPERA + DURA:
		_siguiente()
	return false


func _esqueleto() -> Skeleton3D:
	var s = g.get("skel")
	if not (s is Skeleton3D):
		var l := g.find_children("*", "Skeleton3D", true, false)
		s = l[0] if not l.is_empty() else null
	if pose_final and s != null and not s.skeleton_updated.is_connected(_guardar_poses):
		s.skeleton_updated.connect(_guardar_poses.bind(s))
	return s


func _guardar_poses(sk: Skeleton3D) -> void:
	var a: Array = []
	for i in sk.get_bone_count():
		a.append(sk.get_bone_global_pose(i))
	_poses[sk.get_instance_id()] = a


func _pose(sk: Skeleton3D, i: int) -> Transform3D:
	if pose_final:
		var a: Array = _poses.get(sk.get_instance_id(), [])
		if i < a.size():
			return a[i]
	return sk.get_bone_global_pose(i)


# El punto más bajo de los vértices con piel colgados del esqueleto (una muestra de ~6000 por malla).
func _bajo(sk: Skeleton3D) -> float:
	var gsk := sk.global_transform
	var b := INF
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		if mi.skin == null or mi.mesh == null or not mi.visible or mi.get_parent() != sk:
			continue
		var skin: Skin = mi.skin
		var mats: Array = []
		for k in skin.get_bind_count():
			var bn := String(skin.get_bind_name(k))
			var bi := sk.find_bone(bn) if bn != "" else skin.get_bind_bone(k)
			mats.append(gsk * _pose(sk, bi) * skin.get_bind_pose(k) if bi >= 0 else gsk)
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var B = arr[Mesh.ARRAY_BONES]
			var W = arr[Mesh.ARRAY_WEIGHTS]
			if B == null or W == null or V.is_empty():
				continue
			var por: int = B.size() / V.size()
			var salto := 1 if todos else maxi(1, V.size() / 6000)
			for v in range(0, V.size(), salto):
				var p := Vector3.ZERO
				var wmax := 0.0
				var kmax := 0
				for j in por:
					var w: float = W[v * por + j]
					if w > 0.0:
						p += w * ((mats[int(B[v * por + j])] as Transform3D) * V[v])
						if w > wmax:
							wmax = w
							kmax = int(B[v * por + j])
				if ultimo:
					var nb := String(skin.get_bind_name(kmax)) if kmax < skin.get_bind_count() else "?"
					por_hueso[nb] = minf(float(por_hueso.get(nb, INF)), p.y - g.global_position.y)
				if medir_partes:
					var hn := String(skin.get_bind_name(kmax)) if kmax < skin.get_bind_count() else "?"
					if hn == "" and kmax < skin.get_bind_count() and skin.get_bind_bone(kmax) >= 0:
						hn = sk.get_bone_name(skin.get_bind_bone(kmax))
					_parte(_parte_de(sk, hn), p.y - g.global_position.y, hn)
				if p.y - g.global_position.y < b:
					b = p.y - g.global_position.y
					_hb = String(skin.get_bind_name(kmax)) if kmax < skin.get_bind_count() else "?"
	if medir_partes:                                 # (19/11) mallas sin piel colgadas del esqueleto: el arma
		for mi in sk.find_children("*", "MeshInstance3D", true, false):
			if mi.skin != null or mi.mesh == null or not mi.is_visible_in_tree():
				continue
			var gt: Transform3D = mi.global_transform
			for s in mi.mesh.get_surface_count():
				var V: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
				var salto := 1 if todos else maxi(1, V.size() / 3000)
				for v in range(0, V.size(), salto):
					_parte("arma", (gt * V[v]).y - g.global_position.y, "malla " + String(mi.name))
	return b


# La parte de un hueso: por su nombre o el de sus padres (el arma va antes que la mano: «arma_d» cuelga de la mano).
func _parte_de(sk: Skeleton3D, hn: String) -> String:
	if parte_de.has(hn):
		return parte_de[hn]
	var r := "resto"
	var i := sk.find_bone(hn)
	while i >= 0:
		var n := sk.get_bone_name(i).to_lower()
		if n.begins_with("arma") or n.begins_with("astrolabio"):
			r = "arma"
			break
		if n.ends_with("head") or n == "cabeza":
			r = "cabeza"
			break
		if n.ends_with("hand") or n.begins_with("mano"):
			r = "manos"
			break
		if n.ends_with("foot") or n.begins_with("pie."):
			r = "pies"
			break
		if n.ends_with("hips") or n == "cadera":
			r = "cadera" if i == sk.find_bone(hn) else "resto"
			break
		i = sk.get_bone_parent(i)
	parte_de[hn] = r
	return r


func _parte(k: String, y: float, hn: String) -> void:
	var t := (f - ESPERA) / 30.0
	var d: Array = partes.get(k, [INF, 0.0, INF, "", 0, 0, -INF, INF])
	if y < d[0]:
		d[0] = y
		d[1] = t
	if f >= ESPERA + TUMBADO and y < d[2]:
		d[2] = y
		d[3] = hn
	if ultimo:                                       # el último instante: cuántos vértices de la parte, bajo el suelo
		d[4] += 1
		if y < 0.0:
			d[5] += 1
		d[6] = maxf(d[6], y)
		d[7] = minf(d[7], y)
	partes[k] = d
