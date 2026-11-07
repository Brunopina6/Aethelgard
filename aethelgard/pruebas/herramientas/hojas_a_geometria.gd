extends SceneTree
# Convierte las tarjetas de hojas recortadas (transparencia) de los modelos de Quaternius en geometría OPACA con la
# forma de cada hoja. Motivo (medido en el Redmi, Mali-G57): el recorte de transparencia impide a la GPU descartar lo
# tapado y cada capa de la copa se pinta; con hojas opacas los árboles cuestan ~8 veces menos.
# Cómo: el contorno de las hojas de la textura se calcula una vez (BitMap.opaque_to_polygons) y cada tarjeta se
# sustituye por esos polígonos, colocados con su misma posición (la tarjeta es plana: se usa su mapeo UV -> posición).
# Uso (sin --headless no hace falta): godot --headless --path aethelgard --script res://pruebas/herramientas/hojas_a_geometria.gd
# Escribe vegetacion_prueba/quaternius/recortadas/<modelo>.res (el original no se toca).

const Q := "res://vegetacion_prueba/quaternius/"
const SALIDA := "res://vegetacion_prueba/quaternius/recortadas/"
const MODELOS := ["CommonTree_1", "CommonTree_2", "Bush_Common", "Bush_Common_Flowers"]
const LADO := 128          # resolución a la que se calcula el contorno
const DETALLE := 3.0       # simplificación del contorno (px de LADO): más alto = menos triángulos

var _cache := {}           # ruta de textura -> PackedVector2Array de triángulos en UV (de 3 en 3)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))
	for n in MODELOS:
		var sc: Node = load(Q + n + ".gltf").instantiate()
		var mi: MeshInstance3D = sc.find_children("*", "MeshInstance3D", true, false)[0]
		var malla: Mesh = mi.mesh
		var nueva := ArrayMesh.new()
		for s in malla.get_surface_count():
			var mat := malla.surface_get_material(s)
			var arr := malla.surface_get_arrays(s)
			if mat != null and mat.resource_name.begins_with("Leaves"):
				var antes: int = arr[Mesh.ARRAY_INDEX].size() / 3
				arr = _recortar(arr, mat.albedo_texture, 0.55 if n.begins_with("Bush") else 0.42)
				print("%s/%s: %d -> %d triángulos" % [n, mat.resource_name, antes, arr[Mesh.ARRAY_VERTEX].size() / 3])
			nueva.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			nueva.surface_set_material(s, mat)
		_guardar(nueva, SALIDA + n)
		# --- LOD (experimento Fase 2): el LOD0 es la malla de arriba, sin cambios
		_guardar_lod(malla, n, 1)
		_guardar_lod(malla, n, 2)
		sc.free()
	quit()


# LOD1: las hojas del interior fuera, ~40 % de las de fuera (más las del borde) y algo más grandes: misma silueta,
#       volumen y color con ~1/3 de los triángulos.
# LOD2: la copa como 12-16 «racimos» opacos de pocos triángulos (esferas bajas colocadas donde se agrupan las hojas);
#       el tronco se conserva. Para lejos: la forma general y el color, sin hojas sueltas.
func _guardar_lod(malla: Mesh, n: String, nivel: int) -> void:
	var arbusto := n.begins_with("Bush")
	var nueva := ArrayMesh.new()
	for s in malla.get_surface_count():
		var mat := malla.surface_get_material(s)
		var arr := malla.surface_get_arrays(s)
		if mat != null and mat.resource_name.begins_with("Leaves"):
			var antes: int = arr[Mesh.ARRAY_INDEX].size() / 3
			var tex: Texture2D = mat.albedo_texture
			var todas := _recortar(arr, tex, 0.55 if arbusto else 0.42)
			if nivel == 1:
				# ~la mitad de las hojas de fuera, algo más grandes, y dentro un núcleo de racimos que tapa los huecos
				# (sin él, por los claros se veía el interior oscuro de la copa)
				arr = _unir(_recortar(arr, tex, 0.55, 0.5, 1.4), _racimos(todas, _forma(tex), 10 if arbusto else 16, 1.3))
			else:
				# racimos con la forma de la copa y una «piel» de hojas grandes que rompe la silueta (no un globo liso)
				arr = _unir(_racimos(todas, _forma(tex), 14 if arbusto else 22, 1.7), _recortar(arr, tex, 0.7, 0.14, 2.0))
			print("%s LOD%d/%s: %d -> %d triángulos" % [n, nivel, mat.resource_name, antes, arr[Mesh.ARRAY_VERTEX].size() / 3])
		nueva.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		nueva.surface_set_material(s, mat)
	_guardar(nueva, SALIDA + "%s_lod%d" % [n, nivel])


# Agrupa las hojas (k-medias sobre sus centros) y pone en cada grupo una esfera baja (icosaedro subdividido una vez,
# 80 triángulos) con la forma del grupo. La UV de todos los vértices apunta al centro de una hoja de la textura
# (el color de hoja), y las normales son las de la esfera (el sombreado del follaje las mezcla con la de la copa).
func _racimos(hojas: Array, forma: PackedVector2Array, k: int, tam := 1.9) -> Array:
	var vs: PackedVector3Array = hojas[Mesh.ARRAY_VERTEX]
	var puntos := PackedVector3Array()
	for i in range(0, vs.size(), 12):
		puntos.append((vs[i] + vs[mini(i + 6, vs.size() - 1)]) * 0.5)
	var centros := PackedVector3Array()
	var r := RandomNumberGenerator.new()
	r.seed = 7
	for i in k:
		centros.append(puntos[r.randi_range(0, puntos.size() - 1)])
	var grupo := PackedInt32Array()
	grupo.resize(puntos.size())
	for it in 12:
		for i in puntos.size():
			var mejor := 0
			for j in k:
				if puntos[i].distance_squared_to(centros[j]) < puntos[i].distance_squared_to(centros[mejor]):
					mejor = j
			grupo[i] = mejor
		var suma := []
		var cuenta := []
		for j in k:
			suma.append(Vector3.ZERO)
			cuenta.append(0)
		for i in puntos.size():
			suma[grupo[i]] += puntos[i]
			cuenta[grupo[i]] += 1
		for j in k:
			if cuenta[j] > 0:
				centros[j] = suma[j] / cuenta[j]
	var uv_hoja := (forma[0] + forma[1] + forma[2]) / 3.0
	var esfera := _icosfera()
	var nv := PackedVector3Array()
	var nn := PackedVector3Array()
	var nuv := PackedVector2Array()
	for j in k:
		var ext := Vector3.ZERO
		var n := 0
		for i in puntos.size():
			if grupo[i] == j:
				var d := (puntos[i] - centros[j]).abs()
				ext += d * d
				n += 1
		if n < 3:
			continue
		var rad := Vector3(sqrt(ext.x / n), sqrt(ext.y / n), sqrt(ext.z / n)) * tam + Vector3.ONE * 0.08
		for v in esfera:
			nv.append(centros[j] + v * rad)
			nn.append((v / rad).normalized())
			nuv.append(uv_hoja)
	var res := []
	res.resize(Mesh.ARRAY_MAX)
	res[Mesh.ARRAY_VERTEX] = nv
	res[Mesh.ARRAY_NORMAL] = nn
	res[Mesh.ARRAY_TEX_UV] = nuv
	return res


func _icosfera() -> PackedVector3Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var p := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
		Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var caras := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
		[7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var tri := PackedVector3Array()
	for c in caras:
		var a: Vector3 = p[c[0]].normalized()
		var b: Vector3 = p[c[1]].normalized()
		var d: Vector3 = p[c[2]].normalized()
		var ab := ((a + b) * 0.5).normalized()
		var bd := ((b + d) * 0.5).normalized()
		var da := ((d + a) * 0.5).normalized()
		for q in [a, ab, da, ab, b, bd, da, bd, d, ab, bd, da]:
			tri.append(q)
	# el orden de los vértices de los triángulos se invierte (la cara visible hacia fuera en Godot)
	for i in range(0, tri.size(), 3):
		var tmp := tri[i + 1]
		tri[i + 1] = tri[i + 2]
		tri[i + 2] = tmp
	return tri


# Triángulos (en UV 0..1) que cubren las partes opacas de la textura.
func _forma(tex: Texture2D) -> PackedVector2Array:
	if _cache.has(tex.resource_path):
		return _cache[tex.resource_path]
	var img: Image = tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.resize(LADO, LADO, Image.INTERPOLATE_BILINEAR)
	var bm := BitMap.new()
	bm.create_from_image_alpha(img, 0.5)
	var tris := PackedVector2Array()
	for poli in bm.opaque_to_polygons(Rect2i(0, 0, LADO, LADO), DETALLE):
		# cada hoja (un óvalo en estas texturas) se sustituye por un hexágono con su orientación y proporciones:
		# 4 triángulos por hoja en vez de los 5-8 del contorno exacto
		var hx := _hexagono(poli)
		for i in [0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5]:
			tris.append(hx[i] / float(LADO))
	print("  forma de %s: %d triángulos por tarjeta" % [tex.resource_path.get_file(), tris.size() / 3])
	_cache[tex.resource_path] = tris
	return tris


# «interior»: las tarjetas cuyo centro está más cerca del centro de la copa que esa fracción de su tamaño se quitan
# (no se ven desde fuera y solo sumarían triángulos).
#  «quedan» (LOD): fracción de hojas que se conservan (las del borde, más); «escala»: cuánto crecen las que quedan.
func _recortar(arr: Array, tex: Texture2D, interior: float, quedan := 1.0, escala := 1.0) -> Array:
	var forma := _forma(tex)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nv := PackedVector3Array()
	var nn := PackedVector3Array()
	var nuv := PackedVector2Array()
	var caja := AABB(vs[0], Vector3.ZERO)
	for v in vs:
		caja = caja.expand(v)
	var centro := caja.get_center()
	var mitad := caja.size * 0.5
	for t in range(0, idx.size(), 3):
		var a := idx[t]
		var b := idx[t + 1]
		var c := idx[t + 2]
		var g := (vs[a] + vs[b] + vs[c]) / 3.0
		var radial := ((g - centro) / mitad).length()
		if radial < interior:
			continue
		var tarjeta := t / 6
		# cada trozo de hoja va con el triángulo de la tarjeta que contiene su centro; la tarjeta es plana, así que
		# el mapeo UV -> posición de ese triángulo vale también fuera de él (la otra mitad de la tarjeta)
		for k in range(0, forma.size(), 3):
			var cen := (forma[k] + forma[k + 1] + forma[k + 2]) / 3.0
			var bc := _bari(cen, uvs[a], uvs[b], uvs[c])
			if bc.x < -1e-4 or bc.y < -1e-4 or bc.z < -1e-4:
				continue
			var hoja := k / 12                                  # 4 triángulos (12 vértices) por hoja
			if quedan < 1.0:
				var azar := fposmod(sin(tarjeta * 12.9898 + hoja * 78.233) * 43758.5453, 1.0)
				if azar > quedan * lerpf(0.75, 1.35, smoothstep(interior, 1.0, radial)):
					continue
			var c_hoja := Vector2.ZERO
			for q in 12:
				c_hoja += forma[hoja * 12 + q]
			c_hoja /= 12.0
			for j in 3:
				var w := _bari(c_hoja + (forma[k + j] - c_hoja) * escala, uvs[a], uvs[b], uvs[c])
				nv.append(vs[a] * w.x + vs[b] * w.y + vs[c] * w.z)
				nn.append((ns[a] * w.x + ns[b] * w.y + ns[c] * w.z).normalized())
				nuv.append(forma[k + j])
	var r := []
	r.resize(Mesh.ARRAY_MAX)
	r[Mesh.ARRAY_VERTEX] = nv
	r[Mesh.ARRAY_NORMAL] = nn
	r[Mesh.ARRAY_TEX_UV] = nuv
	return r


func _bari(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Vector3:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d := v0.x * v1.y - v1.x * v0.y
	if absf(d) < 1e-12:
		return Vector3(-1, -1, -1)
	var v := (v2.x * v1.y - v1.x * v2.y) / d
	var w := (v0.x * v2.y - v2.x * v0.y) / d
	return Vector3(1.0 - v - w, v, w)


# Hexágono que se ajusta a un contorno: centro, ejes principales (covarianza) y medida máxima en cada eje.
func _hexagono(poli: PackedVector2Array) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poli:
		c += p
	c /= poli.size()
	var sxx := 0.0
	var syy := 0.0
	var sxy := 0.0
	for p in poli:
		var d := p - c
		sxx += d.x * d.x
		syy += d.y * d.y
		sxy += d.x * d.y
	var ang := 0.5 * atan2(2.0 * sxy, sxx - syy)
	var e1 := Vector2(cos(ang), sin(ang))
	var e2 := Vector2(-e1.y, e1.x)
	var a := 0.0
	var b := 0.0
	for p in poli:
		a = maxf(a, absf((p - c).dot(e1)))
		b = maxf(b, absf((p - c).dot(e2)))
	var hx := PackedVector2Array()
	for k in 6:
		var t := TAU * k / 6.0
		# radio 0,95: el hexágono queda algo por dentro del óvalo (no se ven puntas fuera de la hoja)
		hx.append(c + e1 * cos(t) * a * 0.95 + e2 * sin(t) * b * 1.02)
	return hx


func _unir(a: Array, b: Array) -> Array:
	var r := []
	r.resize(Mesh.ARRAY_MAX)
	for tipo in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV]:
		var x = a[tipo].duplicate()
		x.append_array(b[tipo])
		r[tipo] = x
	return r


# Guarda la malla tal cual y, además, una copia INDEXADA («_idx», experimento veg_indexada): los vértices con TODOS sus
# atributos idénticos (posición, normal, UV, color...) se comparten entre triángulos (SurfaceTool.index() solo une
# vértices exactamente iguales). Mismos triángulos y mismos datos por vértice: la imagen no cambia.
func _guardar(malla: ArrayMesh, base: String) -> void:
	ResourceSaver.save(malla, base + ".res")
	var idx := ArrayMesh.new()
	var antes := 0
	var despues := 0
	var indices := 0
	var tris := 0
	for s in malla.get_surface_count():
		var st := SurfaceTool.new()
		st.create_from(malla, s)
		var a0 := malla.surface_get_arrays(s)
		antes += a0[Mesh.ARRAY_VERTEX].size()
		var t0: int = a0[Mesh.ARRAY_INDEX].size() / 3 if a0[Mesh.ARRAY_INDEX] != null else a0[Mesh.ARRAY_VERTEX].size() / 3
		st.index()
		var a1 := st.commit_to_arrays()
		despues += a1[Mesh.ARRAY_VERTEX].size()
		indices += a1[Mesh.ARRAY_INDEX].size()
		var t1: int = a1[Mesh.ARRAY_INDEX].size() / 3
		if t0 != t1:
			push_error("%s: cambian los triángulos (%d -> %d)" % [base, t0, t1])
		tris += t1
		idx.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a1)
		idx.surface_set_material(s, malla.surface_get_material(s))
	ResourceSaver.save(idx, base + "_idx.res")
	print("INDEXADA %s: vértices %d -> %d (%.0f %%), %d índices, %d triángulos" % [base.get_file(), antes, despues,
		100.0 * despues / maxf(1.0, antes), indices, tris])
