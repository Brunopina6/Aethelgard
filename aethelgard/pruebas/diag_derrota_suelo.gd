extends SceneTree
# DIAGNÓSTICO (18/11), no prueba: ¿cuánto se hunde cada héroe bajo el suelo en el derribo y la derrota?
# (REVISION_PERSONAJES_15_11.md: «derrota de Garon v2/v3 hundida por el clip»; prueba_capa_garon lo ve: hasta -0,29 m en
# v2 y -0,56 m en v3). Para Kael, Lya y Garon en originales, v2 y v3: morir(), y durante unos 6 s, el punto más bajo del
# cuerpo (vértices con piel, como prueba_capa_garon._cuerpo) respecto al pie del nodo, y la altura de la cadera.
# Uso: Godot --headless --path aethelgard --fixed-fps 30 --script res://pruebas/diag_derrota_suelo.gd [-- solo=garon]

const SCRIPTS := {
	"kael": {"originales": "res://kael_3d.gd", "v2": "res://personajes/heroes_v2/kael_v2_3d.gd",
		"v3": "res://personajes/heroes_v3/kael_v3_3d.gd"},
	"lya": {"originales": "res://maga_3d.gd", "v2": "res://personajes/heroes_v2/lya_v2_3d.gd",
		"v3": "res://personajes/heroes_v3/lya_v3_3d.gd"},
	"garon": {"originales": "res://garon_3d.gd", "v2": "res://personajes/heroes_v2/garon_v2_3d.gd",
		"v3": "res://personajes/heroes_v3/garon_v3_3d.gd"},
}
const ESPERA := 20           # fotogramas antes de morir()
const DURA := 180            # fotogramas tras morir() (6 s a 30)

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


func _initialize() -> void:
	var solo := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("solo="):
			solo = a.trim_prefix("solo=")
	for h in SCRIPTS:
		if solo != "" and h != solo:
			continue
		for v in ["originales", "v2", "v3"]:
			casos.append([h, v])
	_siguiente()


func _siguiente() -> void:
	if g != null:
		print("%-6s %-10s de pie %+.3f m · cuerpo más bajo %+.3f m (a los %.1f s) · al final %+.3f m · hundido bajo los pies %.3f m · cadera más baja %+.3f m · lo más bajo, del hueso %s" % [
			casos[ci][0], casos[ci][1], de_pie, bajo, bajo_t, final_bajo, maxf(0.0, de_pie - final_bajo), cadera_min, hueso_bajo])
		var hs := por_hueso.keys()
		hs.sort_custom(func(a, b2): return float(por_hueso[a]) < float(por_hueso[b2]))
		var txt := []
		for h in hs.slice(0, 8):
			txt.append("%s %+.2f" % [h, float(por_hueso[h]) - de_pie])
		print("    bajo los pies, por hueso: ", ", ".join(txt))
		g.queue_free()
		g = null
	ci += 1
	if ci >= casos.size():
		quit(0)
		return
	var v: String = casos[ci][1]
	Engine.set_meta("heroes_version", v)
	Engine.set_meta("heroes_v2", v != "originales")
	Engine.set_meta("heroes_v3", v == "v3")
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
	elif f > ESPERA and f % 5 == 0:
		var sk: Skeleton3D = _esqueleto()
		if sk != null:
			ultimo = f >= ESPERA + DURA - 5
			if ultimo:
				por_hueso = {}
			var b := _bajo(sk)
			if b < bajo:
				bajo = b
				bajo_t = (f - ESPERA) / 30.0
			if f > ESPERA + DURA - 30 and b < final_bajo:
				final_bajo = b
				hueso_bajo = _hb
			var hc := sk.find_bone("Hips")
			if hc < 0:
				for i in sk.get_bone_count():
					if sk.get_bone_name(i).ends_with("Hips"):
						hc = i
						break
			if hc >= 0:
				cadera_min = minf(cadera_min, (sk.global_transform * sk.get_bone_global_pose(hc).origin).y - g.global_position.y)
	if f >= ESPERA + DURA:
		_siguiente()
	return false


func _esqueleto() -> Skeleton3D:
	var s = g.get("skel")
	if s is Skeleton3D:
		return s
	var l := g.find_children("*", "Skeleton3D", true, false)
	return l[0] if not l.is_empty() else null


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
			mats.append(gsk * sk.get_bone_global_pose(bi) * skin.get_bind_pose(k) if bi >= 0 else gsk)
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var B = arr[Mesh.ARRAY_BONES]
			var W = arr[Mesh.ARRAY_WEIGHTS]
			if B == null or W == null or V.is_empty():
				continue
			var por: int = B.size() / V.size()
			var salto := maxi(1, V.size() / 6000)
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
				if p.y - g.global_position.y < b:
					b = p.y - g.global_position.y
					_hb = String(skin.get_bind_name(kmax)) if kmax < skin.get_bind_count() else "?"
	return b
