extends SceneTree
# Prueba (rend2, 12/11): las matas recortadas del Gran Bosque (zonas3d/gran_bosque/escenario.gd, MATAS_CASCO y
# _casco_matas) no pierden nada de lo que se ve.
#   1. Cada píxel opaco (alfa >= 0,5) de cada celda del atlas modelos/hojas/matas.png, y su vecino del filtrado
#      bilineal, queda dentro del octógono de su celda (si alguien repinta el atlas, esto avisa).
#   2. (Con el interruptor «gb_matas_casco», apagado por defecto.) Un cuadro de mata con atributos conocidos, recortado: cada vértice nuevo tiene la posición, la UV, el color y el
#      centro que le tocan en el cuadro original (la misma interpolación), con el mismo sentido de giro, y el área en la
#      celda es la del octógono. Sin ventana.

const E := preload("res://zonas3d/gran_bosque/escenario.gd")
var fallos: Array = []


func _initialize() -> void:
	_atlas()
	_malla()
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _dentro(poli: Array, p: Vector2, margen: float) -> bool:
	for i in poli.size():
		var a: Vector2 = poli[i]
		var b: Vector2 = poli[(i + 1) % poli.size()]
		var n := Vector2(b.y - a.y, a.x - b.x).normalized()       # normal hacia fuera si el polígono gira como el atlas
		var centro := Vector2.ZERO
		for q in poli:
			centro += q
		centro /= poli.size()
		if n.dot(centro - a) > 0.0:
			n = -n
		if n.dot(p - a) > -margen:
			return false
	return true


func _atlas() -> void:
	var img: Image = (load("res://modelos/hojas/matas.png") as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width() / 2
	var h := img.get_height() / 2
	for c in 4:
		var poli: Array = E.MATAS_CASCO[c]
		var fuera := 0
		var opacos := 0
		for y in h:
			for x in w:
				if img.get_pixel((c % 2) * w + x, (c / 2) * h + y).a < 0.5:
					continue
				opacos += 1
				# el centro del texel, con un texel y medio de margen (el filtrado bilineal lee el de al lado)
				if not _dentro(poli, Vector2((x + 0.5) / w, (y + 0.5) / h), 1.5 / w):
					fuera += 1
		print("celda %d: %d texels opacos, %d fuera del octógono" % [c, opacos, fuera])
		if opacos == 0 or fuera > 0:
			fallos.append("celda %d: %d texels opacos fuera de su octógono (de %d)" % [c, fuera, opacos])


func _malla() -> void:
	var esc = E.new(Node3D.new(), {"gb_matas_casco": true}, "medio")
	# un cuadro de la celda 1 (u de 0,5 a 1, v de 0 a 0,5), como los de prototipos/arbol_estilizado.gd
	var p0 := Vector3(0.2, 3.0, -0.4)
	var lado := Vector3(1.1, 0.2, 0.3)
	var arriba := Vector3(-0.1, 0.9, 0.4)
	var esq := [[-1, 1, 0, 0], [1, 1, 1, 0], [1, -1, 1, 1], [-1, -1, 0, 1]]
	var pos: Array = []
	var uv: Array = []
	var col: Array = []
	for e in esq:
		pos.append(p0 + lado * e[0] * 0.5 + arriba * e[1] * 0.5)
		uv.append(Vector2(0.5, 0.0) + Vector2(e[2], e[3]) * 0.5)
		col.append(Color(0.2 + 0.2 * e[2], 0.5, 0.3 + 0.4 * e[3], 1.0))
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	var vs := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cs := PackedColorArray()
	var ns := PackedVector3Array()
	var cus := PackedFloat32Array()
	for i in [0, 1, 2, 0, 2, 3]:
		vs.append(pos[i])
		uvs.append(uv[i])
		cs.append(col[i])
		ns.append(lado.cross(arriba).normalized())
		cus.append_array(PackedFloat32Array([p0.x, p0.y, p0.z, 0.0]))
	a[Mesh.ARRAY_VERTEX] = vs
	a[Mesh.ARRAY_TEX_UV] = uvs
	a[Mesh.ARRAY_COLOR] = cs
	a[Mesh.ARRAY_NORMAL] = ns
	a[Mesh.ARRAY_CUSTOM0] = cus
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	var r: ArrayMesh = esc._casco_matas(m)
	var b: Array = r.surface_get_arrays(0)
	var rv: PackedVector3Array = b[Mesh.ARRAY_VERTEX]
	var ruv: PackedVector2Array = b[Mesh.ARRAY_TEX_UV]
	var rc: PackedColorArray = b[Mesh.ARRAY_COLOR]
	var rcu: PackedFloat32Array = b[Mesh.ARRAY_CUSTOM0]
	if rv.size() % 3 != 0 or rv.size() <= 6:
		fallos.append("la malla recortada tiene %d vértices" % rv.size())
		return
	var area := 0.0
	var malos := 0
	for i in rv.size():
		var l: Vector2 = (ruv[i] - Vector2(0.5, 0.0)) * 2.0           # (u, v) en la celda
		var esperada: Vector3 = pos[0] + (pos[1] - pos[0]) * l.x + (pos[3] - pos[0]) * l.y
		var color_esp: Color = col[0].lerp(col[1], l.x).lerp(col[3].lerp(col[2], l.x), l.y)
		# (el color de vértice se guarda en 8 bits: 1/255 de margen)
		if rv[i].distance_to(esperada) > 0.0005 or absf(rc[i].r - color_esp.r) > 0.006 or absf(rc[i].b - color_esp.b) > 0.006 \
				or Vector3(rcu[i * 4], rcu[i * 4 + 1], rcu[i * 4 + 2]).distance_to(p0) > 0.0001:
			if malos == 0:
				print("primer vértice fuera de sitio: ", rv[i], " (esperado ", esperada, "), color ", rc[i], " (", color_esp,
					"), centro ", Vector3(rcu[i * 4], rcu[i * 4 + 1], rcu[i * 4 + 2]))
			malos += 1
	for t in range(0, rv.size(), 3):
		var u0: Vector2 = (ruv[t] - Vector2(0.5, 0.0)) * 2.0
		var u1: Vector2 = (ruv[t + 1] - Vector2(0.5, 0.0)) * 2.0
		var u2: Vector2 = (ruv[t + 2] - Vector2(0.5, 0.0)) * 2.0
		var s := (u1 - u0).cross(u2 - u0)
		if s < 0.0:
			fallos.append("un triángulo recortado gira al revés que el cuadro (cambiaría FRONT_FACING)")
			break
		area += s * 0.5
	var area_poli := 0.0
	var poli: Array = E.MATAS_CASCO[1]
	for i in poli.size():
		area_poli += poli[i].cross(poli[(i + 1) % poli.size()]) * 0.5
	print("cuadro recortado: %d vértices, área en la celda %.4f (octógono %.4f), %d vértices fuera de sitio" % [rv.size(), area, absf(area_poli), malos])
	if malos > 0:
		fallos.append("%d vértices recortados no caen donde les toca en el cuadro original" % malos)
	if absf(area - absf(area_poli)) > 0.001:
		fallos.append("el área recortada (%.4f) no es la del octógono (%.4f)" % [area, absf(area_poli)])
	# sin «gb_matas_casco» (apagado por defecto), la malla tal cual
	var esc2 = E.new(Node3D.new(), {}, "medio")
	if esc2._casco_matas(m) != m:
		fallos.append("sin gb_matas_casco la malla debería quedar igual (va apagado por defecto)")
