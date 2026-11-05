extends SceneTree
# Reduce un modelo importado usando los LOD que genera Godot y lo guarda como .obj (+ texturas a 1024).
# Uso: --script reducir_modelo.gd -- <res://modelo.fbx> <triangulos_max> <salida sin extensión> <textura_base> [espada voltear agarre]
# textura_base: ruta (res://) de la textura de color sin ".png"; se buscan _normal, _metallic, _roughness.
# "espada": deja el modelo como las armas del juego: hoja hacia +Y, largo 1, empuñadura en el origen
#   (voltear = 1 si la punta mira hacia abajo; agarre = dónde la coge la mano, desde el pomo, 0..1).

var args: PackedStringArray
var escena: Node


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	escena = load(args[0]).instantiate()
	root.add_child(escena)


func _process(_d: float) -> bool:
	_reducir()
	return true


func _reducir() -> void:
	var maximo := int(args[1])
	var salida: String = args[2]
	var tex_base: String = args[3]
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var t := PackedVector2Array()
	var caras := PackedInt32Array()
	var total_orig := 0
	for mi in escena.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		var tr: Transform3D = mi.global_transform
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			total_orig += idx.size() / 3
			var sup: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(), s)
			var elegido := idx
			if idx.size() / 3 > maximo:
				for l in sup.get("lods", []):                # del más detallado al más simple
					var datos: PackedByteArray = l["index_data"]
					if datos.size() == 0:
						continue
					var ix := PackedInt32Array()
					if (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 65535:
						ix = datos.to_int32_array()
					else:
						for k in datos.size() / 2:
							ix.append(datos.decode_u16(k * 2))
					elegido = ix
					if ix.size() / 3 <= maximo:
						break
			var mapa := {}
			var pv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var pn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var pt: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			for i in elegido:
				if not mapa.has(i):
					mapa[i] = v.size()
					v.append(tr * pv[i])
					n.append((tr.basis * pn[i]).normalized())
					t.append(pt[i] if pt.size() > 0 else Vector2.ZERO)
				caras.append(mapa[i])
	var caja := AABB(v[0], Vector3.ZERO)
	for p in v:
		caja = caja.expand(p)
	if args.size() > 4 and args[4] == "espada":
		var voltear := args[5] == "1"
		var agarre := float(args[6])
		var largo := caja.size.y
		var c := caja.get_center()
		for i in v.size():
			var p := v[i] - c
			var q := n[i]
			if voltear:                                        # media vuelta (punta hacia arriba)
				p = Vector3(-p.x, -p.y, p.z)
				q = Vector3(-q.x, -q.y, q.z)
			p = p / largo                                      # largo 1, centrada en 0
			p.y += 0.5 - agarre                                # el pomo en -agarre, la punta en 1 - agarre
			v[i] = p
			n[i] = q
		caja = AABB(v[0], Vector3.ZERO)
		for p in v:
			caja = caja.expand(p)
	print("original: ", total_orig, " triángulos  ->  reducido: ", caras.size() / 3, " (", v.size(), " vértices)")
	print("tamaño: ", caja.size, "  de ", caja.position, " a ", caja.end)
	var f := FileAccess.open(salida + ".obj", FileAccess.WRITE)
	f.store_line("# reducido desde %s" % args[0])
	for p in v:
		f.store_line("v %f %f %f" % [p.x, p.y, p.z])
	for p in t:
		f.store_line("vt %f %f" % [p.x, 1.0 - p.y])
	for p in n:
		f.store_line("vn %f %f %f" % [p.x, p.y, p.z])
	for k in caras.size() / 3:
		var i0 := caras[k * 3] + 1
		var i1 := caras[k * 3 + 1] + 1
		var i2 := caras[k * 3 + 2] + 1
		f.store_line("f %d/%d/%d %d/%d/%d %d/%d/%d" % [i0, i0, i0, i2, i2, i2, i1, i1, i1])
	f.close()
	for par in [["", "_color.jpg"], ["_normal", "_normal.png"], ["_metallic", "_metal.png"], ["_roughness", "_rugosidad.png"],
			["_emission", "_brillo.png"], ["_emit", "_brillo.png"]]:
		var origen := ProjectSettings.globalize_path(tex_base + par[0] + ".png")
		if not FileAccess.file_exists(origen):
			continue
		var img := Image.load_from_file(origen)
		if img == null or img.is_empty():
			continue
		img.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
		if par[1].ends_with(".jpg"):
			img.save_jpg(salida + par[1], 0.9)
		else:
			img.save_png(salida + par[1])
