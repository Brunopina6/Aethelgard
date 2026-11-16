extends SceneTree
# COMPROBACIÓN (herramienta, no prueba de la batería) de la biblioteca modular de la ciudad (zonas3d/ciudad/kit/):
# cada módulo de kit_ciudad.json se carga desde su GLB importado, se viste con los sombreados de la muestra
# (kit_ciudad.gd) y se comprueba: que carga, que sus triángulos son los del json, que solo usa los 11 materiales del
# kit, que tiene sus choques y sus anclas, que su caja es la del json y que las puertas y pasos tienen ≥ 2,2 m libres
# encima del ancla (ningún triángulo entre 0,2 y 2,2 m sobre el ancla en un radio de 0,3 m). Imprime una tabla y sale
# con el número de fallos.
# Uso: godot --headless --path aethelgard --script res://zonas3d/ciudad/kit/herramientas/comprobar_kit.gd

const Kit := preload("res://zonas3d/ciudad/kit/kit_ciudad.gd")
const MATERIALES := ["piedra", "tierra", "revoque", "madera", "tejas", "sillar", "tela", "hoja", "brillo"]

var fallos := 0


func falla(t: String) -> void:
	fallos += 1
	print("  FALLO: ", t)


func relativa(n: Node3D, raiz: Node) -> Transform3D:
	# (en _initialize el árbol aún no procesa: global_transform no vale)
	var t := n.transform
	var p := n.get_parent()
	while p != raiz and p is Node3D:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t


func _initialize() -> void:
	var mods := Kit.modulos()
	if mods.is_empty():
		falla("no se lee kit_ciudad.json")
	var total := 0
	var nombres := mods.keys()
	nombres.sort()
	print("módulo                          tri GLB  tri Godot  choques  anclas  caja (m)")
	for nombre in nombres:
		var d: Dictionary = mods[nombre]
		var ruta: String = Kit.RAIZ + nombre + ".glb"
		if not ResourceLoader.exists(ruta):
			falla("%s: no hay GLB importado" % nombre)
			continue
		var nodo: Node3D = (load(ruta) as PackedScene).instantiate()
		var tris := Kit.vestir(nodo)
		total += tris
		var esperado := int(d["triangulos"]["total"])
		# (el json cuenta las caras del generador; al soldar vértices Blender quita las repetidas o degeneradas: ≤ 5 %)
		if tris > esperado or esperado - tris > maxi(4, esperado * 6 / 100):
			falla("%s: %d triángulos en Godot y %d en el json" % [nombre, tris, esperado])
		var mal := []
		var caja := AABB()
		var primera := true
		var verts := []
		for mi in nodo.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			for i in m.mesh.get_surface_count():
				var orig := m.mesh.surface_get_material(i)
				var mn := (orig.resource_name if orig != null else "?").get_slice(".", 0)
				if not mn in MATERIALES:
					mal.append(mn)
				var arr := m.mesh.surface_get_arrays(i)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx = arr[Mesh.ARRAY_INDEX]
				var tf := relativa(m, nodo)
				var n := (idx as PackedInt32Array).size() if idx != null else vs.size()
				for k in range(0, n, 3):
					var tri := []
					for j in 3:
						var q: Vector3 = tf * vs[idx[k + j] if idx != null else k + j]
						tri.append(q)
						if primera:
							caja = AABB(q, Vector3.ZERO)
							primera = false
						else:
							caja = caja.expand(q)
					verts.append(tri)
		if not mal.is_empty():
			falla("%s: materiales ajenos al kit %s" % [nombre, str(mal)])
		var nch := Kit.choques(nodo)
		if nch != int(d["choques"]):
			falla("%s: %d choques en el GLB y %d en el json" % [nombre, nch, int(d["choques"])])
		var an := Kit.anclas(nodo)
		if an.size() != (d["anclas"] as Dictionary).size():
			falla("%s: %d anclas en el GLB y %d en el json" % [nombre, an.size(), (d["anclas"] as Dictionary).size()])
		var env: Array = d["envolvente"]
		var e0 := Vector3(env[0][0], env[0][1], env[0][2])
		var e1 := Vector3(env[1][0], env[1][1], env[1][2])
		if caja.position.distance_to(e0) > 0.15 or caja.end.distance_to(e1) > 0.15:
			falla("%s: caja %s - %s frente al json %s - %s" % [nombre, caja.position, caja.end, e0, e1])
		for k in (d["anclas"] as Dictionary):
			if not (String(k).begins_with("puerta") or String(k).begins_with("paso") or k == "pie"):
				continue
			var a: Array = d["anclas"][k]
			var p := Vector3(a[0], a[1], a[2])
			for tri in verts:
				var c: Vector3 = (tri[0] + tri[1] + tri[2]) / 3.0
				if Vector2(c.x - p.x, c.z - p.z).length() < 0.3 and c.y > p.y + 0.2 and c.y < p.y + 2.2:
					falla("%s: algo a %.2f m sobre el ancla «%s»" % [nombre, c.y - p.y, k])
					break
		print("%-30s %8d %10d %8d %7d  %.1f × %.1f × %.1f" % [nombre, esperado, tris, nch, an.size(), caja.size.x,
			caja.size.z, caja.size.y])
		nodo.free()
	print("TOTAL: %d módulos, %d triángulos en Godot. FALLOS: %d" % [nombres.size(), total, fallos])
	quit(fallos)
