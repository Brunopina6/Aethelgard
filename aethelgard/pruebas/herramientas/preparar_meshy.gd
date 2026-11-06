extends SceneTree
# Convierte un modelo de Meshy (FBX importado en un mini proyecto aparte) en una malla apta para móvil
# (Skill aet-meshy-blender):
#   1. elige el nivel de detalle (LOD) que Godot generó al importar que cabe en el presupuesto de triángulos;
#   2. quita los vértices que ese nivel no usa (los FBX de Meshy traen millones);
#   3. hornea la transformación, apoya el modelo en el suelo (origen en el centro de la base) y lo escala
#      a la altura pedida;
#   4. reduce las texturas (color, normales, rugosidad) al tamaño pedido y crea el material
#      (alfa recortado si la textura de color tiene transparencia: nada de mezcla en móvil).
# Uso (desde el mini proyecto donde está importado el FBX):
#   Godot --headless --path <mini> --script <ruta>/preparar_meshy.gd -- <fbx res://...> <salida (carpeta)> <nombre>
#        <presupuesto_triangulos> <altura_m> <tamaño_textura>
# Deja en <salida>: <nombre>.res (malla) y las texturas <nombre>_color/_normal/_rugosidad.png reducidas.

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 6:
		print("faltan argumentos")
		quit(1)
		return
	var ruta: String = a[0]
	var salida: String = a[1]
	var nombre: String = a[2]
	var presupuesto := int(a[3])
	var altura := float(a[4])
	var tam_tex := int(a[5])
	DirAccess.make_dir_recursive_absolute(salida)
	var raiz: Node = load(ruta).instantiate()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := 0
	var elegido := -1
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var t: Transform3D = _transformada(mi, raiz)
		var m: Mesh = mi.mesh
		for s in m.get_surface_count():
			var arr: Array = m.surface_get_arrays(s)
			var info: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), s)
			var nv: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			# el nivel más detallado que cabe en el presupuesto (los LOD van de más a menos detalle)
			var lods: Array = info.get("lods", [])
			var nivel := -1
			if indices.size() / 3 > presupuesto:
				for k in lods.size():
					var cand := _indices(lods[k]["index_data"], nv)
					nivel = k
					indices = cand
					if cand.size() / 3 <= presupuesto:
						break
			elegido = maxi(elegido, nivel)
			_anadir(st, arr, indices, t)
			total += indices.size() / 3
	st.generate_tangents()
	var malla := st.commit()
	# apoyar en el suelo y escalar a la altura pedida
	var caja := malla.get_aabb()
	var escala := altura / maxf(caja.size.y, 0.001)
	var ajuste := Transform3D(Basis().scaled(Vector3.ONE * escala), Vector3.ZERO) * Transform3D(Basis(), -Vector3(caja.get_center().x, caja.position.y, caja.get_center().z))
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	st2.append_from(malla, 0, ajuste)
	malla = st2.commit()
	# las texturas se guardan como PNG (Godot las comprime al importarlas en el juego); la malla solo anota si
	# el color tiene transparencia, y la escena monta el material (meter las texturas aquí engordaría el APK)
	var mat := _material(ruta, salida, nombre, tam_tex)
	malla.set_meta("alfa_recortado", mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
	var f := "%s/%s.res" % [salida, nombre]
	ResourceSaver.save(malla, f)
	print("%s: %d triángulos (nivel LOD %d), tamaño %s m -> %s" % [nombre, total, elegido + 1, malla.get_aabb().size.snapped(Vector3.ONE * 0.01), f])
	quit()


func _transformada(n: Node3D, raiz: Node) -> Transform3D:
	var t := Transform3D()
	var x: Node = n
	while x != null and x != raiz:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t


func _indices(datos: PackedByteArray, nv: int) -> PackedInt32Array:
	if nv > 65535:
		return datos.to_int32_array()
	var r := PackedInt32Array()
	r.resize(datos.size() / 2)
	for i in r.size():
		r[i] = datos.decode_u16(i * 2)
	return r


# Añade solo los vértices que usan los índices elegidos (con su transformación horneada).
func _anadir(st: SurfaceTool, arr: Array, indices: PackedInt32Array, t: Transform3D) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm = arr[Mesh.ARRAY_NORMAL]
	var uv = arr[Mesh.ARRAY_TEX_UV]
	var col = arr[Mesh.ARRAY_COLOR]
	var b := t.basis
	for i in indices:
		if nrm != null:
			st.set_normal((b * nrm[i]).normalized())
		if uv != null:
			st.set_uv(uv[i])
		if col != null:
			st.set_color(col[i])
		st.add_vertex(t * v[i])


func _material(ruta: String, salida: String, nombre: String, tam: int) -> StandardMaterial3D:
	var base := ruta.get_basename()
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	var color := _textura(base + ".png", salida, nombre + "_color.png", tam)
	if color != null:
		m.albedo_texture = color
		if color.get_image().detect_alpha() != Image.ALPHA_NONE:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR   # recortado: sin mezcla (barato en móvil)
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var normal := _textura(base + "_normal.png", salida, nombre + "_normal.png", tam)
	if normal != null:
		m.normal_enabled = true
		m.normal_texture = normal
	var rug := _textura(base + "_roughness.png", salida, nombre + "_rugosidad.png", tam / 2)
	if rug != null:
		m.roughness = 1.0
		m.roughness_texture = rug
	return m


func _textura(origen: String, salida: String, nombre: String, tam: int) -> Texture2D:
	var img := Image.load_from_file(ProjectSettings.globalize_path(origen))
	if img == null or img.is_empty():
		return null
	if maxi(img.get_width(), img.get_height()) > tam:
		img.resize(tam, tam, Image.INTERPOLATE_LANCZOS)
	img.save_png("%s/%s" % [salida, nombre])
	return ImageTexture.create_from_image(img)
