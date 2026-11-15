extends SceneTree
# Revisión de personajes (15/11): mide, sin ventana, dónde quedan los PIES de los protagonistas y las PUNTAS de las dos
# espadas de Garon respecto al suelo (y = 0, el sitio del personaje) en las tres variantes (original, v2 y v3), de pie:
#   - «guardia»: recién creado, como en el combate;
#   - «reposo»: reposo de exploración (activar_esperas, sin esperas al azar), como en fotos_heroes_v3.gd «cerca».
# Pies: la altura del hueso más bajo de cada pie (ToeBase, Toe_End o Foot) en el mundo. Espadas: el punto más bajo de la
# caja de cada malla de la espada (EspadaIzq / Espada) en el mundo. Solo mide e imprime; no toca partidas.
# Con «-- exigir» declara FALLO si una espada baja más de 3 cm del suelo o un pie queda a más de 15 cm.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}

var fallos := 0
var exigir := false


func _initialize() -> void:
	exigir = "exigir" in OS.get_cmdline_user_args()
	_probar.call_deferred()


func _esperar(t: float) -> void:
	await create_timer(t).timeout


func _probar() -> void:
	for h in ["Kael", "Lya", "Garon"]:
		var scripts := [ORIGINAL[h][0], HeroesV2.SCRIPTS[ORIGINAL[h][0]], HeroesV3.SCRIPTS[ORIGINAL[h][0]]]
		var nombres := ["original", "v2", "v3"]
		for i in 3:
			for modo in ["guardia", "reposo"]:
				var mundo := Node3D.new()
				root.add_child(mundo)
				var n: Node3D = load(scripts[i]).new()
				n.ruta_modelo = ORIGINAL[h][1]
				mundo.add_child(n)
				for k in 6:
					await process_frame
				if modo == "reposo" and n.has_method("activar_esperas"):
					n.activar_esperas(true)
					if n.get("esperas") != null:
						n.esperas.set_process(false)
				var minimo := {"pie_i": INF, "pie_d": INF, "espada": INF, "espada_izq": INF}
				# 2 s de muestras (60 fotogramas a 30 fps): lo más bajo de cada parte
				for k in 60:
					await process_frame
					_medir(n, minimo)
				var linea := "%-6s %-8s %-8s pie_i %+.3f  pie_d %+.3f" % [h, nombres[i], modo, minimo["pie_i"], minimo["pie_d"]]
				if h == "Garon":
					linea += "  punta_espada %+.3f  punta_espada_izq %+.3f" % [minimo["espada"], minimo["espada_izq"]]
					for e in ["espada", "espada_izq"]:
						if minimo[e] == INF:
							linea += "  (FALTA %s)" % e
							if exigir:
								fallos += 1
						elif minimo[e] < -0.03 and exigir:
							fallos += 1
							linea += "  FALLO: %s bajo el suelo" % e
				for p in ["pie_i", "pie_d"]:
					if exigir and (minimo[p] == INF or absf(minimo[p]) > 0.15):
						fallos += 1
						linea += "  FALLO: %s lejos del suelo" % p
				print(linea)
				mundo.queue_free()
				await process_frame
	print("FALLOS: %d" % fallos)
	quit(0 if fallos == 0 else 1)


func _medir(n: Node3D, minimo: Dictionary) -> void:
	var skel: Skeleton3D = n.get("skel")
	if skel == null:
		return
	for b in skel.get_bone_count():
		var bn := skel.get_bone_name(b)
		var lado := ""
		if bn.contains("Left") and (bn.contains("ToeBase") or bn.contains("Toe_End") or bn.ends_with("Foot")):
			lado = "pie_i"
		elif bn.contains("Right") and (bn.contains("ToeBase") or bn.contains("Toe_End") or bn.ends_with("Foot")):
			lado = "pie_d"
		if lado == "":
			continue
		var y: float = (skel.global_transform * skel.get_bone_global_pose(b).origin).y
		minimo[lado] = minf(minimo[lado], y)
	for par in [["espada", "espada"], ["espada_izq", "espada_izq"]]:
		var e = n.get(par[0])
		if not (e is Node3D) or not e.visible:
			continue
		for mi in e.find_children("*", "MeshInstance3D", true, false):
			var m: Mesh = (mi as MeshInstance3D).mesh
			if m == null:
				continue
			var t: Transform3D = (mi as MeshInstance3D).global_transform
			for s in m.get_surface_count():
				var v: PackedVector3Array = m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
				for k in range(0, v.size(), 2):        # 1 de cada 2 vértices (la punta tiene varios)
					minimo[par[1]] = minf(minimo[par[1]], (t * v[k]).y)
