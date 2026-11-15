extends RefCounted
# V12, mapamundi 3D (15/11/2026): piezas de maqueta hechas por código (cajas, tejados, cilindros, conos, bolas de pocas
# caras) con su color en el vértice y caras planas, todas en UNA malla: cada maqueta (Oakhaven, Pastos, el campamento...)
# es una sola llamada de dibujo. En Godot la cara delantera va en el sentido de las agujas del reloj: tri() la orienta
# sola con la normal hacia fuera que se le da.

var st := SurfaceTool.new()
var caras := 0


func _init() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


func tri(a: Vector3, b: Vector3, c: Vector3, fuera: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	if n.dot(fuera) > 0.0:                    # delante = horario visto desde fuera: (b − a) × (c − a) apunta hacia dentro
		var t := b
		b = c
		c = t
	var nn := -(b - a).cross(c - a).normalized()
	st.set_color(col.srgb_to_linear())       # (Compatibility no convierte el color del vértice: se pasa ya a lineal)
	st.set_normal(nn)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	caras += 1


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, fuera: Vector3, col: Color) -> void:
	tri(a, b, c, fuera, col)
	tri(a, c, d, fuera, col)


# Caja con su centro en la BASE («pie»), girada «giro» radianes alrededor de Y.
func caja(pie: Vector3, tam: Vector3, col: Color, giro := 0.0, col_arriba = null) -> void:
	var b := Basis(Vector3.UP, giro)
	var h := Vector3(tam.x * 0.5, 0, tam.z * 0.5)
	var v := []
	for y in [0.0, tam.y]:
		for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			v.append(pie + b * Vector3(h.x * s.x, y, h.z * s.y))
	var c_arr: Color = col_arriba if col_arriba != null else col.lightened(0.08)
	quad(v[4], v[5], v[6], v[7], Vector3.UP, c_arr)
	quad(v[0], v[1], v[2], v[3], Vector3.DOWN, col.darkened(0.3))
	for k in 4:
		var k2 := (k + 1) % 4
		var centro: Vector3 = (v[k] + v[k2]) * 0.5 - pie
		centro.y = 0.0
		quad(v[k], v[k2], v[k2 + 4], v[k + 4], centro, col.darkened(0.06 * (k % 2)))


# Caja centrada en el origen de «xf» (girada como se quiera: las piezas del arco del portal).
func caja_t(xf: Transform3D, tam: Vector3, col: Color) -> void:
	var h := tam * 0.5
	var v := []
	for s in [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1),
			Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]:
		v.append(xf * (h * s))
	var c := xf.origin
	for cara in [[4, 5, 6, 7], [0, 1, 2, 3], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]:
		var m: Vector3 = (v[cara[0]] + v[cara[1]] + v[cara[2]] + v[cara[3]]) * 0.25
		var fuera: Vector3 = m - c
		quad(v[cara[0]], v[cara[1]], v[cara[2]], v[cara[3]], fuera, col.darkened(0.12 * (0.5 - 0.5 * fuera.normalized().y)))


# Tejado a dos aguas sobre una caja de «ancho» × «fondo» cuya parte de arriba está en «pie».
func tejado(pie: Vector3, ancho: float, fondo: float, alto: float, col: Color, giro := 0.0, vuelo := 0.12) -> void:
	var b := Basis(Vector3.UP, giro)
	var hx := ancho * 0.5 + vuelo
	var hz := fondo * 0.5 + vuelo
	var p := func(x: float, y: float, z: float) -> Vector3: return pie + b * Vector3(x, y, z)
	var a1: Vector3 = p.call(-hx, 0, -hz)
	var a2: Vector3 = p.call(hx, 0, -hz)
	var a3: Vector3 = p.call(hx, 0, hz)
	var a4: Vector3 = p.call(-hx, 0, hz)
	var c1: Vector3 = p.call(-hx, alto, 0)
	var c2: Vector3 = p.call(hx, alto, 0)
	quad(a1, a2, c2, c1, b * Vector3(0, 1, -1), col)
	quad(a4, a3, c2, c1, b * Vector3(0, 1, 1), col.darkened(0.12))
	tri(a1, a4, c1, b * Vector3(-1, 0, 0), col.darkened(0.25))
	tri(a2, a3, c2, b * Vector3(1, 0, 0), col.darkened(0.25))
	quad(a1, a2, a3, a4, Vector3.DOWN, col.darkened(0.4))


func cilindro(pie: Vector3, r_abajo: float, r_arriba: float, alto: float, lados: int, col: Color, tapa := true) -> void:
	for k in lados:
		var a0 := TAU * k / lados
		var a1 := TAU * (k + 1) / lados
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var fuera := (d0 + d1).normalized()
		var tono := col.darkened(0.12 * (0.5 - 0.5 * fuera.dot(Vector3(-0.6, 0, -0.8).normalized())))
		quad(pie + d0 * r_abajo, pie + d1 * r_abajo, pie + d1 * r_arriba + Vector3.UP * alto, pie + d0 * r_arriba + Vector3.UP * alto, fuera, tono)
		if tapa and r_arriba > 0.001:
			tri(pie + Vector3.UP * alto, pie + d0 * r_arriba + Vector3.UP * alto, pie + d1 * r_arriba + Vector3.UP * alto, Vector3.UP, col.lightened(0.06))


func cono(pie: Vector3, radio: float, alto: float, lados: int, col: Color) -> void:
	for k in lados:
		var a0 := TAU * k / lados
		var a1 := TAU * (k + 1) / lados
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var fuera := (d0 + d1).normalized() + Vector3.UP * (radio / maxf(alto, 0.01))
		var tono := col.darkened(0.14 * (0.5 - 0.5 * (d0 + d1).normalized().dot(Vector3(-0.6, 0, -0.8).normalized())))
		tri(pie + d0 * radio, pie + d1 * radio, pie + Vector3.UP * alto, fuera, tono)


# Bola de pocas caras (latitudes × longitudes), aplastada en y si se quiere.
func bola(centro: Vector3, radio: float, col: Color, aplastar := 1.0, lat := 4, lon := 7, giro := 0.0) -> void:
	var pts := []
	for i in lat + 1:
		var fi := PI * i / lat
		var fila := []
		for j in lon:
			var th := TAU * j / lon + giro + (0.5 * TAU / lon if i % 2 == 1 else 0.0)
			fila.append(centro + Vector3(sin(fi) * cos(th) * radio, cos(fi) * radio * aplastar, sin(fi) * sin(th) * radio))
		pts.append(fila)
	for i in lat:
		for j in lon:
			var j2 := (j + 1) % lon
			var a: Vector3 = pts[i][j]
			var b: Vector3 = pts[i][j2]
			var c: Vector3 = pts[i + 1][j2]
			var d: Vector3 = pts[i + 1][j]
			var m := (a + b + c + d) * 0.25 - centro
			var luz := clampf(m.normalized().dot(Vector3(-0.45, 0.8, -0.4).normalized()) * 0.5 + 0.5, 0.0, 1.0)
			var tono := col.darkened(0.22 * (1.0 - luz))
			if i > 0:
				tri(a, b, c, m, tono)
			if i < lat - 1:
				tri(a, c, d, m, tono)


func malla() -> ArrayMesh:
	return st.commit()


func instancia(padre: Node3D, nombre: String, mat: Material, sombra := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = malla()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi
