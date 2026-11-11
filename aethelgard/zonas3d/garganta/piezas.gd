extends RefCounted
# Piezas de la Garganta del Diablo 3D: lo que se usa o se mueve (puentes colgantes, palanca, ascensor, puente levadizo,
# puerta sellada, puntos de guardado, cofre del nido) y lo que cuenta la historia (pilares del anillo partido, el nido,
# el gólem de ámbar dormido, Gorthor ante su trono). Formas sencillas hechas por código; los únicos modelos son los que
# ya usa el juego (el guardián de piedra de Pastos Verdes y el goblin del combate).
# La lógica (cuándo se abre, se baja o se guarda) está en zonas3d/garganta_3d.gd.

const T := preload("res://zonas3d/garganta/trazado.gd")
const Roca := preload("res://zonas3d/garganta/roca.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")

var region: Node3D
var mat: Materiales
var esc                           # escenario.gd (halos y faroles)
var lotes: Roca.Lotes
var perfil: Dictionary
var luces_reales := 0


func _init(r: Node3D, m: Materiales, e, p: Dictionary) -> void:
	region = r
	mat = m
	esc = e
	perfil = p
	lotes = Roca.Lotes.new()


func cerrar() -> void:
	lotes.cerrar(region)


# ================================================================= anillo partido (el símbolo de los peregrinos)

# Arco de toro con un hueco (el anillo partido del brazalete de Kael): plano XY, mirando a +Z.
static func anillo_partido(radio: float, grosor: float, hueco_grados := 38.0, segmentos := 24, lados := 7) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a0 := deg_to_rad(90.0 + hueco_grados * 0.5)                 # el hueco, arriba
	var a1 := a0 + TAU - deg_to_rad(hueco_grados)
	var anillos: Array = []
	for i in segmentos + 1:
		var a := lerpf(a0, a1, float(i) / segmentos)
		var c := Vector3(cos(a), sin(a), 0.0) * radio
		var fuera := Vector3(cos(a), sin(a), 0.0)
		var pts: Array = []
		for k in lados:
			var b := TAU * k / lados
			var n := fuera * cos(b) + Vector3.BACK * sin(b)
			pts.append([c + n * grosor, n])
		anillos.append(pts)
	for i in segmentos:
		for k in lados:
			var k2 := (k + 1) % lados
			var p00: Array = anillos[i][k]
			var p01: Array = anillos[i][k2]
			var p10: Array = anillos[i + 1][k]
			var p11: Array = anillos[i + 1][k2]
			for v in [p00, p11, p10, p00, p01, p11]:
				st.set_normal(v[1])
				st.add_vertex(v[0])
	return st.commit()


# ================================================================= puentes colgantes (P2)

# Puente de tablas y cuerda entre dos pares de pilares de piedra con el anillo partido (más gastado cuanto más lejos).
# La tablazón cuelga un poco (catenaria sencilla). Kael anda por encima: colisión en tramos que siguen la curva.
# T-102: el puente se mece (sombreado del puente, materiales.gd): la madera y las cuerdas van y vienen unos centímetros
# en el centro y nada en los extremos. La colisión NO se mueve (los mismos tramos de siempre): ni atascos ni caídas.
# Cada tabla con su ancho, su grosor, su giro y su tono (algunas, de un arreglo reciente; otras, partidas); travesaños
# debajo; pasamanos gruesos con su cuerda baja y los tirantes anudados; vientos de cuerda a estacas en los extremos de
# fuera y, en la entrada del primero, dos faroles colgados que guían.
const ESTRIBO_FAROLES := 19.0     # el primer puente (z_sur) lleva faroles en su entrada

var puentes: Array = []           # [{z_sur, z_norte, materiales}] (las pruebas leen el vaivén)


func puente_colgante(z_sur: float, z_norte: float, desgaste_sur: float, desgaste_norte: float, fase := 0.0) -> void:
	var x := T.X_CAMINO_O
	var largo := z_sur - z_norte
	var flecha := 0.42 + 0.02 * largo
	var y_de := func(t: float) -> float: return T.ALTO + 0.04 - flecha * 4.0 * t * (1.0 - t)
	var bajo: bool = not perfil.get("relieve", true)                   # perfil bajo: menos piezas pequeñas
	var lp := Roca.Lotes.new()                                         # lo que se mece va aparte
	var m_tabla := mat.puente(z_sur, z_norte, fase, Color.WHITE)
	var m_cuerda := mat.puente(z_sur, z_norte, fase, Color(0.70, 0.60, 0.44), Vector2(2.5, 2.5), 1.0)
	var m_tela := mat.puente(z_sur, z_norte, fase, Color.WHITE, Vector2(1.0, 1.0), 1.0, true)
	var tonos := [Color(0.48, 0.41, 0.34), Color(0.53, 0.40, 0.29), Color(0.38, 0.30, 0.24), Color(0.45, 0.40, 0.36)]
	var arreglo := Color(0.64, 0.52, 0.38)                             # tablas nuevas de un arreglo
	var oscuro := Color(0.27, 0.21, 0.16)
	# tablas: de sur a norte, cada una con su ancho y su hueco
	var z := z_sur - 0.05
	while z > z_norte + 0.12:
		var ancho := randf_range(0.2, 0.3)
		var zc := z - ancho * 0.5
		var t := (z_sur - zc) / largo
		var y: float = y_de.call(t)
		var pend: float = (y_de.call(t + 0.01) - y_de.call(t - 0.01)) / (largo * 0.02)
		var grueso := randf_range(0.055, 0.08)
		var tono: Color = arreglo if randf() < 0.06 else tonos[randi() % tonos.size()]
		tono = tono * randf_range(0.9, 1.06)
		var b := Basis.from_euler(Vector3(atan(pend), randf_range(-0.05, 0.05), randf_range(-0.025, 0.025)))
		var dx := randf_range(-0.07, 0.07)
		var largo_tabla := T.ANCHO_PUENTE - randf_range(0.0, 0.26)
		if randf() < 0.08:                                             # tabla partida en dos
			for mitad in [-1.0, 1.0]:
				var bm := BoxMesh.new()
				bm.size = Vector3(largo_tabla * 0.5 - 0.03, grueso, ancho)
				lp.poner_color(bm, Transform3D(b.rotated(Vector3.UP, randf_range(-0.04, 0.04)), Vector3(x + dx + mitad * largo_tabla * 0.25,
					y - grueso * 0.5, zc)), m_tabla, tono * randf_range(0.9, 1.05))
		else:
			var bm := BoxMesh.new()
			bm.size = Vector3(largo_tabla, grueso, ancho)
			lp.poner_color(bm, Transform3D(b, Vector3(x + dx, y - grueso * 0.5, zc)), m_tabla, tono)
			if not bajo and randf() < 0.5:                             # clavos en los extremos (sobre los largueros)
				for lado in [-0.85, 0.85]:
					var cl := BoxMesh.new()
					cl.size = Vector3(0.035, 0.012, 0.035)
					lp.poner_color(cl, Transform3D(b, Vector3(x + lado, y + 0.004, zc)), m_tabla, Color(0.16, 0.15, 0.15))
		z -= ancho + randf_range(0.025, 0.06)
	# largueros bajo las tablas, travesaños y colisión por tramos (la colisión, igual que siempre)
	var tramos := 14
	for k in tramos:
		var ta := float(k) / tramos
		var tb := float(k + 1) / tramos
		var pa := Vector3(x, y_de.call(ta), lerpf(z_sur, z_norte, ta))
		var pb := Vector3(x, y_de.call(tb), lerpf(z_sur, z_norte, tb))
		var c := (pa + pb) * 0.5
		var giro := Vector3(atan2(pb.y - pa.y, pa.z - pb.z), 0, 0)
		for lado in [-0.85, 0.85]:
			var larguero := BoxMesh.new()
			larguero.size = Vector3(0.12, 0.12, pa.distance_to(pb) + 0.02)
			lp.poner_color(larguero, Transform3D(Basis.from_euler(giro), c + Vector3(lado, -0.13, 0)), m_tabla, oscuro)
		if k % 2 == 0:
			var trav := BoxMesh.new()
			trav.size = Vector3(T.ANCHO_PUENTE + 0.25, 0.08, 0.1)
			lp.poner_color(trav, Transform3D(Basis.from_euler(giro), pa + Vector3(0, -0.22, 0)), m_tabla, oscuro * 1.2)
		var cuerpo := StaticBody3D.new()
		cuerpo.position = c + Vector3(0, -0.1, 0)
		cuerpo.rotation = giro
		region.add_child(cuerpo)
		var col := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = Vector3(T.ANCHO_PUENTE, 0.2, pa.distance_to(pb) + 0.04)
		col.shape = caja
		cuerpo.add_child(col)
	# pasamanos de cuerda (cuelgan más que las tablas), cuerda baja, tirantes anudados y cintas de los peregrinos
	var y_mano := func(t: float) -> float: return T.ALTO + 1.25 - (flecha + 0.3) * 4.0 * t * (1.0 - t)
	var cuerda_c := Color.WHITE
	var colores := [Color(0.66, 0.22, 0.2), Color(0.82, 0.64, 0.30), Color(0.30, 0.42, 0.66), Color(0.90, 0.88, 0.80)]
	for lado in [-1.0, 1.0]:
		var xl: float = x + lado * (T.ANCHO_PUENTE * 0.5 + 0.12)
		var segs := 12 if bajo else 18
		for k in segs:
			var ta := float(k) / segs
			var tb := float(k + 1) / segs
			_cuerda(lp, Vector3(xl, y_mano.call(ta), lerpf(z_sur, z_norte, ta)), Vector3(xl, y_mano.call(tb), lerpf(z_sur, z_norte, tb)),
				0.045, m_cuerda, cuerda_c, 5 if bajo else 7)
			if not bajo:                                               # cuerda baja, a media altura
				_cuerda(lp, Vector3(xl - lado * 0.04, y_de.call(ta) + 0.55, lerpf(z_sur, z_norte, ta)),
					Vector3(xl - lado * 0.04, y_de.call(tb) + 0.55, lerpf(z_sur, z_norte, tb)), 0.026, m_cuerda, cuerda_c, 5)
		var n_tir := int(largo / 0.55)
		for k in range(1, n_tir):
			var t := float(k) / n_tir
			var zt := lerpf(z_sur, z_norte, t)
			var arriba := Vector3(xl, y_mano.call(t), zt)
			_cuerda(lp, arriba, Vector3(xl - lado * 0.1, y_de.call(t) - 0.08, zt), 0.018, m_cuerda, cuerda_c, 4)
			if not bajo:                                               # nudo en el pasamanos
				var nudo := SphereMesh.new()
				nudo.radius = 0.06
				nudo.height = 0.1
				nudo.radial_segments = 6
				nudo.rings = 3
				lp.poner_color(nudo, Transform3D(Basis(), arriba), m_cuerda, Color(0.85, 0.85, 0.85))
		for k in int(largo * (0.9 if bajo else 1.4)):
			var t := randf_range(0.08, 0.92)
			var q := QuadMesh.new()
			q.size = Vector2(0.075, randf_range(0.28, 0.55))
			var p := Vector3(xl + lado * 0.03, y_mano.call(t) - q.size.y * 0.5, lerpf(z_sur, z_norte, t))
			lp.poner_color(q, Transform3D(Basis(Vector3.UP, randf_range(-0.5, 0.5)).rotated(Vector3.RIGHT, randf_range(-0.15, 0.15)), p),
				m_tela, colores[randi() % colores.size()])
	var hechas: Array = lp.cerrar(region)
	for mi in hechas:
		mi.extra_cull_margin = 0.3                                     # lo que se mece no se recorta antes de tiempo
		mi.name = "PuenteColgante_%d" % int(z_sur)
	puentes.append({"z_sur": z_sur, "z_norte": z_norte, "fase": fase, "materiales": [m_tabla, m_cuerda, m_tela], "mallas": hechas})
	# pilares con el anillo partido en los dos extremos, con la cuerda atada en lo alto
	for extremo in [[z_sur + 0.35, desgaste_sur, 1.0], [z_norte - 0.35, desgaste_norte, -1.0]]:
		for lado in [-1.0, 1.0]:
			var pp := Vector3(x + lado * (T.ANCHO_PUENTE * 0.5 + 0.4), T.ALTO, extremo[0])
			pilar_anillo(pp, extremo[1], 1.55)
			for k in 2:                                                # vueltas de cuerda en lo alto del pilar
				var anilla := CylinderMesh.new()
				anilla.top_radius = 0.3
				anilla.bottom_radius = 0.3
				anilla.height = 0.055
				anilla.radial_segments = 8
				anilla.rings = 1
				lotes.poner(anilla, Transform3D(Basis(Vector3.UP, k * 0.4), pp + Vector3(0, 1.18 + k * 0.08, 0)), mat.cuerda())
	# vientos: de lo alto de los pilares de fuera a una estaca clavada en la cornisa (solo donde hay cornisa detrás)
	for extremo in [[z_sur, 1.0], [z_norte, -1.0]]:
		var zc: float = extremo[0]
		if T.en_hueco(zc + extremo[1] * 1.8) or (zc + extremo[1] * 1.8 > T.ISLOTE[0] and zc + extremo[1] * 1.8 < T.ISLOTE[1]):
			continue
		for lado in [-1.0, 1.0]:
			var pp := Vector3(x + lado * (T.ANCHO_PUENTE * 0.5 + 0.4), T.ALTO, zc + extremo[1] * 0.35)
			var estaca := Vector3(x + lado * 1.95, T.altura(x + lado * 1.95, zc + extremo[1] * 1.9), zc + extremo[1] * 1.9)
			Roca.caja(lotes, region, estaca + Vector3(0, 0.22, 0), Vector3(0.14, 0.44, 0.14), mat.madera_vieja(),
				Vector3(extremo[1] * 0.25, 0, 0))
			_cilindro(pp + Vector3(0, 1.2, 0), estaca + Vector3(0, 0.38, 0), 0.03, mat.cuerda(), 6)
	if absf(z_sur - ESTRIBO_FAROLES) < 0.01:
		for lado in [-1.0, 1.0]:
			farol_colgado(Vector3(x + lado * 2.2, T.ALTO, z_sur + 0.35), fase + lado)


# El vaivén de los puentes colgantes: la región lo llama cada fotograma con su reloj. Pone ese tiempo en el sombreado
# de cada puente (madera, cuerda y telas) y así quien está encima se mece con las tablas (vaiven_en).
const VAIVEN := 0.05              # los mismos que materiales.gd, puente()
const REBOTE := 0.022


func mecer(t: float) -> void:
	for pu in puentes:
		for m in pu["materiales"]:
			(m as ShaderMaterial).set_shader_parameter("tiempo", t)


# Cuánto se ha movido el tablero bajo «p» en el instante «t» (cero fuera de los puentes). Misma cuenta que el sombreado.
func vaiven_en(p: Vector3, t: float) -> Vector3:
	if p.y < T.ALTO - 1.5 or absf(p.x - T.X_CAMINO_O) > T.ANCHO_PUENTE * 0.5 + 0.2:
		return Vector3.ZERO
	for pu in puentes:
		var zs: float = pu["z_sur"]
		var zn: float = pu["z_norte"]
		if p.z > zs or p.z < zn:
			continue
		var fase: float = pu["fase"]
		var u := clampf((zs - p.z) / (zs - zn), 0.0, 1.0)
		var k := 4.0 * u * (1.0 - u)
		var lado := sin(t * 1.9 + fase) * 0.8 + sin(t * 3.3 + fase * 1.7) * 0.2
		var arriba := sin(t * 2.6 + fase * 1.3 + u * 2.5)
		return Vector3(lado * VAIVEN * k, arriba * REBOTE * k, 0.0)
	return Vector3.ZERO
# Un tramo de cuerda de «a» a «b» con color en los vértices, en el lote «l» (lo que se mece).
func _cuerda(l: Roca.Lotes, a: Vector3, b: Vector3, r: float, m: Material, color: Color, lados := 5) -> void:
	var largo := a.distance_to(b)
	if largo < 0.001:
		return
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = largo + r                                              # los tramos se solapan: la cuerda no se corta
	cm.radial_segments = lados
	cm.rings = 1
	var y := (b - a) / largo
	var xe := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
	l.poner_color(cm, Transform3D(Basis(xe, y, xe.cross(y)), (a + b) * 0.5), m, color)


# Farol de los peregrinos colgado de un poste con brazo, a la entrada de un puente: madera, hierro, cristal que brilla,
# su llama y su halo. Tiñe la roca cercana (materiales.gd, poner_fuego). El poste choca.
func farol_colgado(p: Vector3, fase: float) -> void:
	var madera := mat.madera_vieja()
	var alto := 2.35
	Roca.caja(lotes, region, p + Vector3(0, alto * 0.5, 0), Vector3(0.16, alto, 0.16), madera)
	var brazo := p + Vector3(0, alto - 0.12, -0.3)                   # el brazo apunta al puente (al norte)
	Roca.caja(lotes, region, brazo, Vector3(0.09, 0.09, 0.7), madera, Vector3.ZERO, false)
	var gancho := brazo + Vector3(0, -0.05, -0.26)
	_cilindro(gancho, gancho + Vector3(0, -0.32, 0), 0.012, mat.hierro(), 4)
	var c := gancho + Vector3(0, -0.52, 0)                            # centro del farol
	var hierro := mat.hierro()
	for dy in [-0.17, 0.17]:                                           # tapa y base
		var bm := BoxMesh.new()
		bm.size = Vector3(0.26, 0.04, 0.26)
		lotes.poner(bm, Transform3D(Basis(), c + Vector3(0, dy, 0)), hierro)
	for e in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:   # varillas
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 0.34, 0.025)
		lotes.poner(bm, Transform3D(Basis(), c + Vector3(e.x * 0.11, 0, e.y * 0.11)), hierro)
	var vidrio := BoxMesh.new()
	vidrio.size = Vector3(0.19, 0.28, 0.19)
	lotes.poner(vidrio, Transform3D(Basis(), c), mat.brillo(Color(1.0, 0.66, 0.32), 1.15))
	llama_en(c + Vector3(0, 0.02, 0), 0.34, fase)
	esc.halo(Vector3(c.x, T.altura(c.x, c.z), c.z), c, Materiales.FUEGO, 4.0, 1.5, lotes)
	mat.poner_fuego(c, 5.0)


# Una llama que mira a la cámara (escenario.gd, llama_en).
func llama_en(p: Vector3, alto: float, fase := 0.0, fuerza := 1.0) -> MeshInstance3D:
	return esc.llama_en(p, alto, fase, fuerza)


# Un cilindro de «a» a «b» (cuerdas, cadenas, tirantes), en el lote de su material.
func _cilindro(a: Vector3, b: Vector3, r: float, m: Material, lados := 5) -> void:
	var largo := a.distance_to(b)
	if largo < 0.001:
		return
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = largo
	cm.radial_segments = lados
	cm.rings = 1
	var y := (b - a) / largo
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
	lotes.poner(cm, Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5), m)


# Pilar de piedra con el anillo partido tallado en la cara que mira al sur (al camino). «desgaste» de 0 a 1: el anillo
# más fino, más hundido y más roto. Choca; se dibuja en los lotes (son bajos: no tapan a Kael).
func pilar_anillo(p: Vector3, desgaste: float, alto: float, ancho := 0.42) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p
	region.add_child(cuerpo)
	var piedra := mat.piedra_tallada()
	var bm := BoxMesh.new()
	bm.size = Vector3(ancho, alto, ancho)
	lotes.poner(bm, Transform3D(Basis(), p + Vector3(0, alto * 0.5, 0)), piedra)
	var cm := BoxMesh.new()
	cm.size = Vector3(ancho + 0.14, 0.16, ancho + 0.14)
	lotes.poner(cm, Transform3D(Basis(), p + Vector3(0, alto + 0.06, 0)), piedra)
	var anillo := anillo_partido(ancho * 0.3, lerpf(0.035, 0.016, desgaste), lerpf(34.0, 80.0, desgaste), 18, 6)
	var m_anillo := mat.liso(Color(0.80, 0.62, 0.34).lerp(Color(0.46, 0.42, 0.40), desgaste), lerpf(0.4, 0.9, desgaste),
		lerpf(0.6, 0.1, desgaste))
	lotes.poner(anillo, Transform3D(Basis(), p + Vector3(0, alto * 0.7, ancho * 0.5 + 0.005 - 0.01 * desgaste)), m_anillo)
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(ancho + 0.1, alto, ancho + 0.1)
	col.shape = forma
	col.position.y = alto * 0.5
	cuerpo.add_child(col)
	return cuerpo


# ================================================================= puntos de guardado

# Altar de los peregrinos con un cristal que flota (verde y blanco, como el brillo del guardado de la 2D).
func guardado(p: Vector3) -> Node3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p
	region.add_child(cuerpo)
	var piedra := mat.piedra_tallada()
	for datos in [[Vector3(1.0, 0.3, 0.8), 0.15], [Vector3(0.7, 0.5, 0.55), 0.55], [Vector3(0.82, 0.12, 0.66), 0.86]]:
		var bm := BoxMesh.new()
		bm.size = datos[0]
		lotes.poner(bm, Transform3D(Basis(), p + Vector3(0, datos[1], 0)), piedra)
	lotes.poner(anillo_partido(0.17, 0.025, 36.0), Transform3D(Basis(), p + Vector3(0, 0.58, 0.28)), mat.bronce())
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.0, 1.0, 0.8)
	col.shape = forma
	col.position.y = 0.5
	cuerpo.add_child(col)
	var cristal := MeshInstance3D.new()
	var rombo := SphereMesh.new()
	rombo.radius = 0.2
	rombo.height = 0.62
	rombo.radial_segments = 4
	rombo.rings = 2
	cristal.mesh = rombo
	cristal.material_override = mat.brillo(Color(0.62, 1.0, 0.74), 1.15)
	cristal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cristal.position.y = 1.45
	cuerpo.add_child(cristal)
	var giro := cristal.create_tween().set_loops()
	giro.tween_property(cristal, "rotation:y", TAU, 3.2).from(0.0)
	var sube := cristal.create_tween().set_loops()
	sube.tween_property(cristal, "position:y", 1.6, 1.4).set_trans(Tween.TRANS_SINE)
	sube.tween_property(cristal, "position:y", 1.45, 1.4).set_trans(Tween.TRANS_SINE)
	esc.halo(p, p + Vector3(0, 1.5, 0), Color(0.55, 1.0, 0.65), 3.4, 1.5, lotes)
	cuerpo.set_meta("cristal", cristal)
	return cuerpo


# ================================================================= palanca (P7)

func palanca(p: Vector3, bajada: bool) -> Dictionary:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p
	region.add_child(cuerpo)
	var base := MeshInstance3D.new()                 # T-102: el pedestal, en sillares con su tono
	var rng := RandomNumberGenerator.new()
	rng.seed = 7171
	base.mesh = _sillares(Vector3(1.2, 0.7, 0.9), rng)
	base.material_override = mat.sillar()
	base.position.y = 0.35
	cuerpo.add_child(base)
	var eje := Node3D.new()                          # el brazo gira alrededor de x
	eje.position = Vector3(0, 0.85, 0)
	cuerpo.add_child(eje)
	var hierro := mat.hierro()
	var brazo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.07
	cm.height = 1.5
	cm.radial_segments = 8
	brazo.mesh = cm
	brazo.material_override = hierro
	brazo.position.y = 0.72
	eje.add_child(brazo)
	var puno := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	sm.radial_segments = 12                          # V12: la de Godot por defecto (64 × 32) daba 4 224 triángulos
	sm.rings = 6                                     # para un pomo de 24 cm; así, 144 (a la vista, igual)
	puno.mesh = sm
	puno.material_override = mat.liso(Color(0.55, 0.24, 0.18), 0.6)
	puno.position.y = 1.5
	eje.add_child(puno)
	var rueda := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.3
	tm.outer_radius = 0.42
	tm.rings = 16
	tm.ring_segments = 6
	rueda.mesh = tm
	rueda.material_override = hierro
	rueda.position = Vector3(0.66, 0.85, 0)
	rueda.rotation = Vector3(0, 0, PI * 0.5)
	cuerpo.add_child(rueda)
	eje.rotation.x = deg_to_rad(55.0 if bajada else -40.0)
	# la cadena sube por el muro hacia la polea que sostiene el puente levadizo
	var cadena_a := p + Vector3(0.66, 1.3, 0)
	var cadena_b := Vector3(T.muro_este(p.z) - 0.4, T.BAJO + 9.0, p.z - 1.5)
	_cilindro(cadena_a, cadena_b, 0.03, hierro, 4)
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.3, 1.2, 1.0)
	col.shape = forma
	col.position.y = 0.6
	cuerpo.add_child(col)
	return {"nodo": cuerpo, "eje": eje}


# ================================================================= ascensor (P5 ↔ P1)

# Una cesta de madera que cuelga de un cable sobre el abismo, entre una estación en cada cornisa. Sin la palanca, la
# cesta está parada a medio camino y los faroles del cable, apagados.
func ascensor(encendido: bool) -> Dictionary:
	var z := T.ASCENSOR_Z
	var madera := mat.madera()
	var vieja := mat.madera_vieja()
	var hierro := mat.hierro()
	var arriba := Vector3(T.X_BORDE_O - 0.5, T.ALTO + 4.4, z)
	var abajo := Vector3(T.X_BORDE_E + 0.8, T.BAJO + 4.4, z)
	for est in [[Vector3(T.X_BORDE_O - 0.6, T.ALTO, z), 1.0], [Vector3(T.X_BORDE_E + 0.9, T.BAJO, z), -1.0]]:
		var b: Vector3 = est[0]
		var dirx: float = est[1]                       # hacia el abismo
		Roca.caja(lotes, region, b + Vector3(dirx * 0.6, -0.12, 0), Vector3(2.6, 0.24, 2.4), vieja, Vector3.ZERO, false)
		for lz in [-1.05, 1.05]:
			Roca.caja(lotes, region, b + Vector3(-dirx * 0.3, 2.25, lz), Vector3(0.24, 4.5, 0.24), madera)
		Roca.caja(lotes, region, b + Vector3(-dirx * 0.3, 4.45, 0), Vector3(0.3, 0.3, 2.6), madera, Vector3.ZERO, false)
		var rueda := TorusMesh.new()
		rueda.inner_radius = 0.42
		rueda.outer_radius = 0.56
		rueda.rings = 18
		rueda.ring_segments = 6
		lotes.poner(rueda, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), b + Vector3(-dirx * 0.3, 4.0, 0)), hierro)
	# el cable, con algo de comba
	var segs := 12
	var cable: Array = []
	for k in segs + 1:
		var t := float(k) / segs
		cable.append(arriba.lerp(abajo, t) - Vector3(0, 0.7 * 4.0 * t * (1.0 - t), 0))
	for k in segs:
		_cilindro(cable[k], cable[k + 1], 0.055, hierro, 6)
	# faroles colgados del cable
	var faroles: Array = []
	for k in [2, 4, 6, 8, 10]:
		var c: Vector3 = cable[k] - Vector3(0, 0.45, 0)
		_cilindro(cable[k], c + Vector3(0, 0.12, 0), 0.012, hierro, 4)
		var f := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.13
		sm.height = 0.3
		sm.radial_segments = 8
		sm.rings = 4
		f.mesh = sm
		f.position = c
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(f)
		var h := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.3, 1.3)
		h.mesh = q
		h.material_override = mat.halo_aire(Materiales.AMBAR, 0.8)
		h.position = c
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(h)
		f.set_meta("halo", h)
		faroles.append(f)
	# la cesta (se mueve: un nodo propio)
	var cesta := Node3D.new()
	cesta.name = "Cesta"
	region.add_child(cesta)
	var piezas_cesta := Roca.Lotes.new()                 # la cesta entera: una malla por material (se mueve junta)
	for datos in [[Vector3(1.9, 0.12, 1.7), Vector3(0, 0.06, 0)], [Vector3(1.9, 0.8, 0.08), Vector3(0, 0.46, 0.81)],
			[Vector3(1.9, 0.8, 0.08), Vector3(0, 0.46, -0.81)], [Vector3(0.08, 0.8, 1.7), Vector3(0.91, 0.46, 0)],
			[Vector3(0.08, 0.8, 1.7), Vector3(-0.91, 0.46, 0)]]:
		_caja_lote(piezas_cesta, datos[0], datos[1], vieja)
	var cuerda := mat.cuerda()
	for e in [Vector3(0.85, 0.85, 0.75), Vector3(-0.85, 0.85, 0.75), Vector3(0.85, 0.85, -0.75), Vector3(-0.85, 0.85, -0.75)]:
		var cm := CylinderMesh.new()
		var largo: float = e.distance_to(Vector3(0, 2.6, 0))
		cm.top_radius = 0.015
		cm.bottom_radius = 0.015
		cm.height = largo
		cm.radial_segments = 4
		var y: Vector3 = (Vector3(0, 2.6, 0) - e).normalized()
		var x: Vector3 = y.cross(Vector3.FORWARD).normalized()
		piezas_cesta.poner(cm, Transform3D(Basis(x, y, x.cross(y)), (e + Vector3(0, 2.6, 0)) * 0.5), cuerda)
	var pm := CylinderMesh.new()
	pm.top_radius = 0.2
	pm.bottom_radius = 0.2
	pm.height = 0.18
	piezas_cesta.poner(pm, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(0, 2.7, 0)), hierro)
	piezas_cesta.cerrar(cesta)
	var datos := {"cesta": cesta, "faroles": faroles, "cable": cable}
	encender_ascensor(datos, encendido, false)
	cesta.position = posicion_cesta(cable, 0.5)
	return datos


# Dónde cuelga la cesta a la fracción «t» del cable (0 arriba, 1 abajo): la polea en el cable.
static func posicion_cesta(cable: Array, t: float) -> Vector3:
	var k := clampf(t, 0.0, 1.0) * (cable.size() - 1)
	var i := mini(int(k), cable.size() - 2)
	var p: Vector3 = (cable[i] as Vector3).lerp(cable[i + 1], k - i)
	return p - Vector3(0, 2.7, 0)


func encender_ascensor(datos: Dictionary, si: bool, poco_a_poco := true) -> void:
	var apagado := mat.liso(Color(0.18, 0.16, 0.15), 0.8)
	var encendido := mat.brillo(Materiales.AMBAR, 1.3)
	var i := 0
	for f in datos["faroles"]:
		var h: MeshInstance3D = f.get_meta("halo")
		if not si:
			f.material_override = apagado
			h.visible = false
			continue
		if poco_a_poco:                              # se encienden uno tras otro, de arriba abajo
			var t: Tween = f.create_tween()
			t.tween_interval(0.25 * i)
			t.tween_callback(func():
				f.material_override = encendido
				h.visible = true)
		else:
			f.material_override = encendido
			h.visible = true
		i += 1


# ================================================================= puente levadizo (P7 → P3)

# Gira sobre una bisagra en el borde de la cornisa alta. Levantado, queda casi de pie (se ve desde toda la garganta);
# bajado, su punta descansa en un estribo de la cornisa baja. Dos cadenas van de la punta a las poleas del muro.
const LEVADIZO_ARRIBA := 82.0     # grados (levantado)


static func angulo_bajado() -> float:
	var d := T.APOYO - T.BISAGRA
	return rad_to_deg(atan2(d.y, d.x))


static func largo_levadizo() -> float:
	var d := T.APOYO - T.BISAGRA
	return Vector2(d.x, d.y).length()


func levadizo(bajado: bool) -> Dictionary:
	var pivote := Node3D.new()
	pivote.name = "Levadizo"
	pivote.position = T.BISAGRA
	region.add_child(pivote)
	var largo := largo_levadizo()
	var ancho := T.LEVADIZO_ANCHO
	var madera := mat.madera()
	var vieja := mat.madera_vieja()
	var hierro := mat.hierro()
	var piezas := Roca.Lotes.new()
	var n := int(largo / 0.36)
	var rng := RandomNumberGenerator.new()                # T-102: cada tabla con su tono (como los puentes colgantes)
	rng.seed = 6611
	var m_tabla := mat.madera_color()
	for k in n:
		var tabla := BoxMesh.new()
		tabla.size = Vector3(0.32 - rng.randf_range(0.0, 0.04), 0.12, ancho - rng.randf_range(0.0, 0.12))
		piezas.poner_color(tabla, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.02, 0.02)),
			Vector3((k + 0.5) * largo / n, 0.0, rng.randf_range(-0.03, 0.03))), m_tabla, Materiales.tono_madera(rng))
	for lz in [-ancho * 0.5 + 0.1, ancho * 0.5 - 0.1]:
		var viga := BoxMesh.new()
		viga.size = Vector3(largo, 0.22, 0.2)
		piezas.poner(viga, Transform3D(Basis(), Vector3(largo * 0.5, -0.15, lz)), vieja)
		var pretil := BoxMesh.new()
		pretil.size = Vector3(largo - 0.4, 0.1, 0.1)
		piezas.poner(pretil, Transform3D(Basis(), Vector3(largo * 0.5, 0.75, lz)), madera)
	for k in range(1, 9):
		var x := k * largo / 9.0
		var banda := BoxMesh.new()
		banda.size = Vector3(0.1, 0.05, ancho + 0.02)
		piezas.poner(banda, Transform3D(Basis(), Vector3(x, 0.07, 0)), hierro)
		for lz in [-ancho * 0.5 + 0.1, ancho * 0.5 - 0.1]:
			var poste := BoxMesh.new()
			poste.size = Vector3(0.1, 0.8, 0.1)
			piezas.poner(poste, Transform3D(Basis(), Vector3(x, 0.38, lz)), madera)
	var tablero := Node3D.new()
	tablero.name = "Tablero"
	pivote.add_child(tablero)
	piezas.cerrar(tablero)                               # (no se vuelve transparente: es el suelo por el que se anda)
	# estribo de piedra en la cornisa baja, donde apoya la punta, y bisagra de hierro
	var ls := Roca.Lotes.new()                            # T-102: el estribo, en sillares con su tono
	for i in 3:
		var bm := BoxMesh.new()
		bm.size = Vector3(2.2, 0.7, (ancho + 0.6) / 3.0 - 0.03)
		ls.poner_color(bm, Transform3D(Basis(), T.APOYO + Vector3(0.6, -0.35, (i - 1) * (ancho + 0.6) / 3.0)), mat.sillar(),
			Materiales.tono_piedra(Color(0.52, 0.50, 0.48), rng))
	ls.cerrar(region)
	Roca.caja(lotes, region, T.BISAGRA + Vector3(-0.3, -0.25, 0), Vector3(0.6, 0.5, ancho + 0.4), hierro, Vector3.ZERO, false)
	# cadenas: de la punta a dos poleas en lo alto del muro del oeste
	var cadenas: Array = []
	for lz in [-ancho * 0.5 + 0.15, ancho * 0.5 - 0.15]:
		var c := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.04
		cm.height = 1.0
		cm.radial_segments = 5
		c.mesh = cm
		c.material_override = hierro
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(c)
		c.set_meta("polea", Vector3(T.muro_oeste(T.LEVADIZO_Z) + 1.0, T.ALTO + 14.0, T.LEVADIZO_Z + lz))
		c.set_meta("lz", lz)
		cadenas.append(c)
		var polea := TorusMesh.new()
		polea.inner_radius = 0.18
		polea.outer_radius = 0.28
		lotes.poner(polea, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), c.get_meta("polea")), hierro)
	var datos := {"pivote": pivote, "tablero": tablero, "cadenas": cadenas, "choque": null}
	poner_levadizo(datos, angulo_bajado() if bajado else LEVADIZO_ARRIBA)
	if bajado:
		choque_levadizo(datos)
	return datos


# Las cadenas sostienen el puente levantado; al soltarlas (la palanca), se descuelgan y ya no cruzan la garganta (si no,
# con el puente bajado cruzarían por delante de la cámara de la arena).
func soltar_cadenas(datos: Dictionary) -> void:
	for c in datos["cadenas"]:
		c.visible = false


func poner_levadizo(datos: Dictionary, grados: float) -> void:
	var pivote: Node3D = datos["pivote"]
	pivote.rotation = Vector3(0, 0, deg_to_rad(grados))
	var largo := largo_levadizo()
	for c in datos["cadenas"]:
		var punta := pivote.global_transform * Vector3(largo - 0.2, 0.2, c.get_meta("lz"))
		var polea: Vector3 = c.get_meta("polea")
		var y := (polea - punta)
		var l := y.length()
		y /= maxf(l, 0.001)
		var x := y.cross(Vector3.FORWARD).normalized()
		c.transform = Transform3D(Basis(x, y * l, x.cross(y)), (polea + punta) * 0.5)


# Colisión del puente bajado: una caja inclinada a lo largo del tablero (la pisan Kael y el grupo).
func choque_levadizo(datos: Dictionary) -> void:
	if datos["choque"] != null:
		return
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "ChoqueLevadizo"
	datos["pivote"].add_child(cuerpo)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	var largo := largo_levadizo()
	caja.size = Vector3(largo - 0.6, 0.25, T.LEVADIZO_ANCHO - 0.1)
	col.shape = caja
	col.position = Vector3(largo * 0.5, -0.06, 0)
	cuerpo.add_child(col)
	datos["choque"] = cuerpo
	# Umbrales planos en los dos extremos. La caja inclinada empieza 0,3 m dentro del tablero: su cara del final, junto a
	# la bisagra, quedaba casi a ras del suelo y el rayo hacia abajo la tomaba por una pendiente imposible (Kael se paraba
	# en la bisagra; prueba_garganta3d del 09/11). El umbral de arriba la tapa por encima.
	for u in [[Vector3(T.BISAGRA.x - 0.25, T.ALTO - 0.13, T.LEVADIZO_Z), 1.3], [Vector3(T.APOYO.x + 0.35, T.BAJO - 0.13, T.LEVADIZO_Z), 1.3]]:
		var umbral := StaticBody3D.new()
		umbral.position = u[0]
		region.add_child(umbral)
		var cu := CollisionShape3D.new()
		var bu := BoxShape3D.new()
		bu.size = Vector3(u[1], 0.3, T.LEVADIZO_ANCHO - 0.1)
		cu.shape = bu
		umbral.add_child(cu)
		datos["choque_umbrales"] = datos.get("choque_umbrales", []) + [umbral]


# ================================================================= puerta sellada (P3 → P4)

func puerta(abierta: bool) -> Dictionary:
	var p := T.PUERTA
	var rng := RandomNumberGenerator.new()
	rng.seed = 2020
	var media := T.PUERTA_ANCHO * 0.5
	var marco: Array = []
	for datos in [[Vector3(-media - 0.55, 2.7, 0), Vector3(1.1, 5.4, 1.3)], [Vector3(media + 0.55, 2.7, 0), Vector3(1.1, 5.4, 1.3)],
			[Vector3(0, 5.75, 0), Vector3(T.PUERTA_ANCHO + 2.6, 1.0, 1.5)]]:
		var cuerpo := StaticBody3D.new()
		cuerpo.position = p + datos[0]
		region.add_child(cuerpo)
		var mi := MeshInstance3D.new()
		mi.mesh = _sillares(datos[1], rng)                 # T-102: sillares con su tono (antes, una caja lisa)
		mi.material_override = mat.sillar()
		cuerpo.add_child(mi)
		mi.add_to_group("ocluye")
		var col := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = datos[1]
		col.shape = forma
		cuerpo.add_child(col)
		marco.append(cuerpo)
	# dos braseros a los lados, contra los pilares (fuera de donde se anda): el fuego guía hasta la puerta
	for lado in [-1.0, 1.0]:
		brasero(p + Vector3(lado * (media + 0.45), 0, 0.95), lado * 1.3)
	# el anillo partido grande, sobre el dintel
	var sello := MeshInstance3D.new()
	sello.mesh = anillo_partido(0.55, 0.07, 40.0, 28, 8)
	sello.material_override = mat.bronce()
	sello.position = p + Vector3(0, 5.75, 0.78)
	region.add_child(sello)
	# la losa: se hunde en el suelo al tirar de la palanca
	var losa := Node3D.new()
	losa.name = "Puerta"
	losa.position = p
	region.add_child(losa)
	var hoja := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(T.PUERTA_ANCHO, 5.2, 0.6)
	hoja.mesh = hb
	hoja.material_override = mat.detalle(Color(0.44, 0.42, 0.43), 0.5, 0.45)
	hoja.position.y = 2.6
	losa.add_child(hoja)
	var anillo := MeshInstance3D.new()
	anillo.mesh = anillo_partido(1.05, 0.11, 40.0, 30, 8)
	anillo.material_override = mat.bronce()
	anillo.position = Vector3(0, 2.75, 0.33)
	losa.add_child(anillo)
	var grieta := MeshInstance3D.new()                   # la raya del medio (dos hojas selladas)
	var gb := BoxMesh.new()
	gb.size = Vector3(0.05, 5.0, 0.04)
	grieta.mesh = gb
	grieta.material_override = mat.liso(Color(0.12, 0.10, 0.10))
	grieta.position = Vector3(0, 2.55, 0.31)
	losa.add_child(grieta)
	var datos := {"losa": losa, "choque": null}
	if abierta:
		losa.position.y = p.y - 5.3
		losa.visible = false
	else:
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "ChoquePuerta"
		cuerpo.position = p + Vector3(0, 2.6, 0)
		region.add_child(cuerpo)
		var col := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(T.PUERTA_ANCHO + 0.4, 5.2, 0.8)
		col.shape = forma
		cuerpo.add_child(col)
		datos["choque"] = cuerpo
	return datos


# ================================================================= cofre del nido (el cofre raro)

const COFRE_ANCHO := 1.05
const COFRE_FONDO := 0.66
const COFRE_ALTO := 0.48
const COFRE_ABIERTA := -108.0


func cofre(p: Vector3, abierto: bool) -> Dictionary:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Cofre"
	cuerpo.position = p
	region.add_child(cuerpo)
	var madera := mat.detalle(Color(0.30, 0.17, 0.12), 0.9, 0.8)
	var oro := mat.liso(Color(0.95, 0.74, 0.30), 0.32, 0.65)
	var r := COFRE_FONDO * 0.5
	var fijo := Roca.Lotes.new()                       # la caja, los herrajes y las monedas: una malla por material
	_caja_lote(fijo, Vector3(COFRE_ANCHO, COFRE_ALTO, COFRE_FONDO), Vector3(0, COFRE_ALTO * 0.5, 0), madera)
	_caja_lote(fijo, Vector3(COFRE_ANCHO + 0.04, 0.06, COFRE_FONDO + 0.04), Vector3(0, 0.03, 0), oro)
	for x in [-COFRE_ANCHO * 0.5 + 0.12, 0.0, COFRE_ANCHO * 0.5 - 0.12]:
		_caja_lote(fijo, Vector3(0.07, COFRE_ALTO + 0.01, COFRE_FONDO + 0.02), Vector3(x, COFRE_ALTO * 0.5, 0), oro)
	_caja_lote(fijo, Vector3(0.16, 0.18, 0.02), Vector3(0, COFRE_ALTO - 0.08, r + 0.01), oro)
	var gema := MeshInstance3D.new()                   # una gema de ámbar en la cerradura
	var gm := SphereMesh.new()
	gm.radius = 0.05
	gm.height = 0.1
	gm.radial_segments = 6
	gm.rings = 3
	gema.mesh = gm
	gema.material_override = mat.cristal_ambar()
	gema.position = Vector3(0, COFRE_ALTO - 0.08, r + 0.03)
	cuerpo.add_child(gema)
	# el fondo con monedas (se ve al abrir)
	var monedas := mat.brillo(Color(1.0, 0.8, 0.35), 0.95)
	_caja_lote(fijo, Vector3(COFRE_ANCHO - 0.1, 0.02, COFRE_FONDO - 0.1), Vector3(0, COFRE_ALTO + 0.005, 0), mat.liso(Color(0.15, 0.08, 0.05)))
	for k in 10:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045
		cm.bottom_radius = 0.045
		cm.height = 0.014
		cm.radial_segments = 10
		fijo.poner(cm, Transform3D(Basis.from_euler(Vector3(0.25 * sin(k * 1.7), 0, 0.25 * cos(k * 1.3))),
			Vector3(-0.36 + 0.08 * k, COFRE_ALTO + 0.02 + 0.006 * (k % 3), 0.12 * sin(k * 2.3))), monedas)
	fijo.cerrar(cuerpo)
	var tapa := Node3D.new()
	tapa.name = "Tapa"
	tapa.position = Vector3(0, COFRE_ALTO, -r)
	cuerpo.add_child(tapa)
	var tm := MeshInstance3D.new()
	tm.mesh = _malla_tapa(COFRE_ANCHO, r)
	tm.material_override = madera
	tm.position = Vector3(0, 0, r)
	tapa.add_child(tm)
	for x in [-COFRE_ANCHO * 0.5 + 0.12, 0.0, COFRE_ANCHO * 0.5 - 0.12]:
		var b := MeshInstance3D.new()
		b.mesh = _malla_tapa(0.07, r + 0.014)
		b.material_override = oro
		b.position = Vector3(x, 0, r)
		tapa.add_child(b)
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(COFRE_ANCHO, COFRE_ALTO + r, COFRE_FONDO)
	col.shape = forma
	col.position.y = (COFRE_ALTO + r) * 0.5
	cuerpo.add_child(col)
	var brillo: MeshInstance3D = null
	if abierto:
		tapa.rotation.x = deg_to_rad(COFRE_ABIERTA)
	else:
		brillo = destello(cuerpo, Vector3(0, COFRE_ALTO + 0.1, r + 0.05), 0.4)
		var t := brillo.create_tween().set_loops()
		t.tween_property(brillo, "scale", Vector3.ONE * 0.7, 0.6).set_trans(Tween.TRANS_SINE)
		t.tween_property(brillo, "scale", Vector3.ONE * 0.25, 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_interval(0.9)
	return {"cuerpo": cuerpo, "tapa": tapa, "brillo": brillo}


func _caja_lote(l: Roca.Lotes, tam: Vector3, pos: Vector3, m: Material) -> void:
	var bm := BoxMesh.new()
	bm.size = tam
	l.poner(bm, Transform3D(Basis(), pos), m)


# Medio cilindro tumbado (la tapa curva del cofre): eje en y = 0, de z = −radio a z = +radio.
static func _malla_tapa(ancho: float, radio: float, lados := 14) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -ancho * 0.5
	var x1 := ancho * 0.5
	for i in lados:
		var a0 := PI * i / lados
		var a1 := PI * (i + 1) / lados
		var n0 := Vector3(0, sin(a0), cos(a0))
		var n1 := Vector3(0, sin(a1), cos(a1))
		var a := Vector3(x0, n0.y * radio, n0.z * radio)
		var b := Vector3(x1, n0.y * radio, n0.z * radio)
		var c := Vector3(x1, n1.y * radio, n1.z * radio)
		var d := Vector3(x0, n1.y * radio, n1.z * radio)
		for v in [[a, n0], [d, n1], [c, n1], [a, n0], [c, n1], [b, n0]]:
			st.set_normal(v[1])
			st.add_vertex(v[0])
		for lado in [-1.0, 1.0]:
			var x: float = x1 if lado > 0.0 else x0
			var centro := Vector3(x, 0, 0)
			var q0 := Vector3(x, n0.y * radio, n0.z * radio)
			var q1 := Vector3(x, n1.y * radio, n1.z * radio)
			var orden: Array = [centro, q0, q1] if lado > 0.0 else [centro, q1, q0]
			for v in orden:
				st.set_normal(Vector3(lado, 0, 0))
				st.add_vertex(v)
	for v in [Vector3(x1, 0, radio), Vector3(x1, 0, -radio), Vector3(x0, 0, -radio),
			Vector3(x1, 0, radio), Vector3(x0, 0, -radio), Vector3(x0, 0, radio)]:
		st.set_normal(Vector3.DOWN)
		st.add_vertex(v)
	return st.commit()


# Destello dorado que mira a la cámara (mezcla aditiva).
func destello(padre: Node3D, pos: Vector3, tam: float, color := Color(1.0, 0.82, 0.4)) -> MeshInstance3D:
	var m := mat.halo_aire(color, 1.0).duplicate() as StandardMaterial3D
	var q := QuadMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = Vector3.ONE * tam
	padre.add_child(mi)
	return mi


# ================================================================= el nido y su gólem

# Un nido enorme de ramas secas trenzadas en anillo, con un lecho de paja, huesos y cristales de ámbar, en la repisa del
# abismo. Las ramas van tangentes al anillo, en capas que se cruzan (así se lee «nido» y no «montón de palos»).
func nido(c: Vector3) -> void:
	var rama := mat.madera_vieja()
	var seca := mat.detalle(Color(0.47, 0.38, 0.27), 1.2, 0.6)
	var clara := mat.detalle(Color(0.53, 0.46, 0.34), 1.2, 0.5)
	var capas := 5
	for capa in capas:
		var y := 0.08 + 0.17 * capa
		var r_capa := 2.45 + 0.12 * sin(capa * 1.7) - 0.08 * capa
		var n := 26
		for k in n:
			var a := TAU * (k + 0.5 * (capa % 2)) / n + randf_range(-0.08, 0.08)
			var r := r_capa + randf_range(-0.2, 0.2)
			var p := c + Vector3(cos(a) * r, y + randf_range(-0.04, 0.04), sin(a) * r * 1.08)
			var cm := CylinderMesh.new()
			cm.top_radius = randf_range(0.025, 0.045)
			cm.bottom_radius = randf_range(0.05, 0.08)
			cm.height = randf_range(1.1, 1.8)
			cm.radial_segments = 5
			cm.rings = 1
			var tangente := Vector3(-sin(a), 0, cos(a))
			var eje := tangente.rotated(Vector3.UP, randf_range(-0.35, 0.35) + (0.3 if capa % 2 else -0.3))
			eje = (eje + Vector3(0, randf_range(-0.25, 0.25), 0)).normalized()
			var x := eje.cross(Vector3.UP).normalized()
			var b := Basis(x, eje, x.cross(eje).normalized())
			lotes.poner(cm, Transform3D(b, p), [rama, seca, clara][(k + capa) % 3])
	# lecho de paja y ramitas dentro
	var lecho := CylinderMesh.new()
	lecho.top_radius = 2.25
	lecho.bottom_radius = 2.0
	lecho.height = 0.22
	lecho.radial_segments = 18
	lotes.poner(lecho, Transform3D(Basis().scaled(Vector3(1, 1, 1.08)), c + Vector3(0, 0.06, 0)), mat.detalle(Color(0.49, 0.41, 0.27), 1.6, 0.6))
	for k in 30:
		var a := randf() * TAU
		var r := randf_range(0.3, 2.0)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.015
		cm.bottom_radius = 0.025
		cm.height = randf_range(0.5, 0.9)
		cm.radial_segments = 4
		cm.rings = 1
		lotes.poner(cm, Transform3D(Basis.from_euler(Vector3(PI * 0.5, randf() * TAU, randf_range(-0.2, 0.2))),
			c + Vector3(cos(a) * r, 0.2, sin(a) * r)), seca if k % 2 else clara)
	var hueso := mat.hueso()
	for k in 14:
		var a := randf() * TAU
		var r := randf_range(0.6, 3.6)
		var cap := CapsuleMesh.new()
		cap.radius = randf_range(0.04, 0.07)
		cap.height = randf_range(0.4, 0.8)
		cap.radial_segments = 6
		cap.rings = 2
		lotes.poner(cap, Transform3D(Basis.from_euler(Vector3(PI * 0.5, randf() * TAU, randf_range(-0.3, 0.3))),
			c + Vector3(cos(a) * r, 0.06, sin(a) * r)), hueso)
	for k in 3:                                      # cráneos de bestia
		var a := randf() * TAU
		var sm := SphereMesh.new()
		sm.radius = 0.2
		sm.height = 0.3
		sm.radial_segments = 8
		sm.rings = 5
		lotes.poner(sm, Transform3D(Basis(), c + Vector3(cos(a) * 3.1, 0.15, sin(a) * 3.2)), hueso)


# El gólem de ámbar, dormido en el borde del nido: el guardián de piedra (el modelo de la estatua de Pastos Verdes, que el
# combate ya usa para el gólem) teñido de ámbar y medio hundido entre las ramas; brilla despacio, como si respirara.
func golem(p: Vector3) -> Node3D:
	var ruta := "res://modelos/guardian/guardian.res"
	if not ResourceLoader.exists(ruta):
		return null
	var malla: Mesh = load(ruta)
	var nodo := Node3D.new()
	nodo.name = "Golem"
	nodo.position = p + Vector3(0, -0.55, 0)
	nodo.rotation = Vector3(deg_to_rad(14.0), deg_to_rad(200.0), 0)
	region.add_child(nodo)
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists("res://modelos/guardian/guardian_color.png"):
		m.albedo_texture = load("res://modelos/guardian/guardian_color.png")
	if perfil.get("relieve", true) and ResourceLoader.exists("res://modelos/guardian/guardian_normal.png"):
		m.normal_enabled = true
		m.normal_texture = load("res://modelos/guardian/guardian_normal.png")
	m.albedo_color = Color(0.80, 0.63, 0.47)                # piedra teñida de ámbar, no un muñeco naranja
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = Materiales.AMBAR
	m.emission_energy_multiplier = 0.1
	mi.material_override = m
	nodo.add_child(mi)
	var aabb := malla.get_aabb()
	var alto := maxf(aabb.size.y, 0.01)
	nodo.scale = Vector3.ONE * (2.6 / alto)
	var t := mi.create_tween().set_loops()                 # respira: el ámbar se aviva y se apaga despacio
	t.tween_property(m, "emission_energy_multiplier", 0.3, 2.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(m, "emission_energy_multiplier", 0.08, 2.4).set_trans(Tween.TRANS_SINE)
	esc.halo(p, p + Vector3(0, 1.4, 0), Materiales.AMBAR, 4.0, 2.2, lotes)
	return nodo


# ================================================================= la arena de Gorthor

# Gorthor el Devorador: el goblin del combate (goblin_3d.gd), el doble de grande que Kael y teñido de rojo (como en
# combate.gd, «gorthor3d»), esperando ante su trono. Null si falta el modelo.
func gorthor(p: Vector3) -> Node3D:
	if not ResourceLoader.exists("res://goblin_3d.gd") or not ResourceLoader.exists("res://goblin.fbx"):
		return null
	var g = load("res://goblin_3d.gd").new()
	g.name = "Gorthor"
	region.add_child(g)
	if g.get("anim") == null or g.get("skel") == null:
		g.queue_free()
		return null
	g.position = p
	g.scale = Vector3.ONE * 1.8
	var tinte := Color(1.0, 0.62, 0.56)
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var orig := m3.get_active_material(i)
			if orig is BaseMaterial3D:
				var copia := orig.duplicate() as BaseMaterial3D
				copia.albedo_color = copia.albedo_color * tinte
				m3.set_surface_override_material(i, copia)
	g.reposo()
	g.mirar(Vector3.BACK, 0.0)
	return g


# El trono de rocas y huesos, los braseros, los tótems y los estandartes rojos del clan.
func arena_de_gorthor(con_vida: bool) -> void:
	var c := T.ARENA
	var piedra := mat.detalle(Color(0.39, 0.37, 0.40), 0.8, 1.0)
	var hueso := mat.hueso()
	var trono := Vector3(T.GORTHOR.x, T.ALTO + T.ARENA_ALTO, T.GORTHOR.z - 3.0)
	Roca.caja(lotes, region, trono + Vector3(0, 0.6, 0), Vector3(3.2, 1.2, 1.8), piedra)
	Roca.caja(lotes, region, trono + Vector3(0, 2.0, -0.6), Vector3(2.8, 2.8, 0.7), piedra, Vector3(0.12, 0, 0))
	for lado in [-1.0, 1.0]:
		Roca.caja(lotes, region, trono + Vector3(lado * 1.6, 1.35, 0.1), Vector3(0.6, 0.5, 1.6), piedra, Vector3.ZERO, false)
		for k in 3:                                 # cuernos de hueso en el respaldo
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 0.12
			cm.height = 1.1 - 0.2 * k
			cm.radial_segments = 6
			lotes.poner(cm, Transform3D(Basis.from_euler(Vector3(0, 0, -lado * (0.35 + 0.25 * k))),
				trono + Vector3(lado * (0.6 + 0.35 * k), 3.6 - 0.25 * k, -0.6)), hueso)
	var craneo := SphereMesh.new()
	craneo.radius = 0.32
	craneo.height = 0.5
	lotes.poner(craneo, Transform3D(Basis(), trono + Vector3(0, 3.55, -0.45)), hueso)
	# tótems con calaveras y estandartes rojos del clan, alrededor del borde
	var palo := mat.madera_vieja()
	var rojo := mat.tela(Color(0.62, 0.14, 0.12))
	for i in 6:
		var a := lerpf(-2.6, 0.9, float(i) / 5.0)
		var p := c + Vector3(cos(a), 0, sin(a)) * (T.ARENA_RADIO - 1.3)
		p.y = T.ALTO + T.ARENA_ALTO
		if absf(p.x - T.X_CAMINO_O) < 2.0 and p.z > c.z:
			continue                                 # no en la entrada
		var alto := randf_range(2.6, 3.4)
		Roca.caja(lotes, region, p + Vector3(0, alto * 0.5, 0), Vector3(0.18, alto, 0.18), palo)
		if i % 2 == 0:
			var q := QuadMesh.new()
			q.size = Vector2(0.9, 1.6)
			lotes.poner(q, Transform3D(Basis(Vector3.UP, -a + PI * 0.5), p + Vector3(0, alto - 1.0, 0.1)), rojo)
		else:
			var sm := SphereMesh.new()
			sm.radius = 0.2
			sm.height = 0.3
			lotes.poner(sm, Transform3D(Basis(), p + Vector3(0, alto + 0.12, 0)), hueso)
	# braseros: encendidos mientras Gorthor espera; fríos después
	for lado in [-1.0, 1.0]:
		var p := trono + Vector3(lado * 3.4, 0, 1.6)
		Roca.caja(lotes, region, p + Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 0.7), piedra)
		var cuenco := CylinderMesh.new()
		cuenco.top_radius = 0.6
		cuenco.bottom_radius = 0.35
		cuenco.height = 0.35
		cuenco.radial_segments = 10
		lotes.poner(cuenco, Transform3D(Basis(), p + Vector3(0, 1.05, 0)), mat.hierro())
		if not con_vida:
			continue
		var fuego := MeshInstance3D.new()
		var cono := CylinderMesh.new()
		cono.top_radius = 0.0
		cono.bottom_radius = 0.45
		cono.height = 0.9
		cono.radial_segments = 7
		fuego.mesh = cono
		fuego.material_override = mat.brillo(Materiales.FUEGO, 1.35)
		fuego.position = p + Vector3(0, 1.6, 0)
		fuego.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(fuego)
		var t := fuego.create_tween().set_loops()
		t.tween_property(fuego, "scale", Vector3(1.1, 1.25, 1.1), 0.18 + 0.05 * lado)
		t.tween_property(fuego, "scale", Vector3(0.9, 0.85, 0.9), 0.22)
		esc.halo(p, p + Vector3(0, 1.7, 0), Materiales.FUEGO, 5.5, 2.4, lotes)
		if perfil.get("luces_faroles", false):
			var o := OmniLight3D.new()
			o.light_color = Color(1.0, 0.55, 0.3)
			o.light_energy = 1.6
			o.omni_range = 8.0
			o.position = p + Vector3(0, 2.0, 0)
			region.add_child(o)
	# huesos por el suelo
	for k in 18:
		var a := randf() * TAU
		var r := randf_range(2.0, T.ARENA_RADIO - 1.5)
		var p := c + Vector3(cos(a) * r, T.ARENA_ALTO + 0.05, sin(a) * r)
		if absf(p.x - T.X_CAMINO_O) < 1.2 and p.z > c.z + 2.0:
			continue
		var cap := CapsuleMesh.new()
		cap.radius = 0.05
		cap.height = randf_range(0.4, 0.7)
		cap.radial_segments = 6
		cap.rings = 2
		lotes.poner(cap, Transform3D(Basis.from_euler(Vector3(PI * 0.5, randf() * TAU, 0)), p), hueso)


# ================================================================= la grieta oculta (P8)

# El pilar del peregrino: un obelisco con el anillo partido grande, gastado por miles de manos (brilla un poco), velas a
# sus pies y un hilo de luz que baja por la grieta.
func pilar_peregrino(p: Vector3) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p
	cuerpo.rotation.y = deg_to_rad(-20.0)                 # mira hacia la entrada de la grieta (al sur)
	region.add_child(cuerpo)
	var piedra := mat.piedra_tallada()
	var basa := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.3, 0.35, 1.3)
	basa.mesh = bb
	basa.material_override = piedra
	basa.position.y = 0.17
	cuerpo.add_child(basa)
	var fuste := MeshInstance3D.new()
	var fm := CylinderMesh.new()                           # prisma de 4 caras que se estrecha
	fm.top_radius = 0.36
	fm.bottom_radius = 0.56
	fm.height = 2.9
	fm.radial_segments = 4
	fm.rings = 1
	fuste.mesh = fm
	fuste.material_override = piedra
	fuste.position.y = 0.35 + 1.45
	fuste.rotation.y = PI * 0.25
	cuerpo.add_child(fuste)
	fuste.add_to_group("ocluye")
	var punta := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.0
	pm.bottom_radius = 0.4
	pm.height = 0.45
	pm.radial_segments = 4
	punta.mesh = pm
	punta.material_override = piedra
	punta.position.y = 0.35 + 2.9 + 0.22
	punta.rotation.y = PI * 0.25
	cuerpo.add_child(punta)
	var anillo := MeshInstance3D.new()
	anillo.mesh = anillo_partido(0.3, 0.05, 52.0, 26, 7)
	var oro_gastado := mat.liso(Color(0.86, 0.70, 0.42), 0.35, 0.55).duplicate() as StandardMaterial3D
	oro_gastado.emission_enabled = true
	oro_gastado.emission = Color(1.0, 0.78, 0.4)
	oro_gastado.emission_energy_multiplier = 0.35
	anillo.material_override = oro_gastado
	anillo.position = Vector3(0, 1.75, 0.36)                # sobre la cara (a esa altura, a 0,33 m del eje)
	anillo.rotation.x = -0.07                              # sigue la cara del obelisco, que se estrecha
	cuerpo.add_child(anillo)
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.2, 3.4, 1.2)
	col.shape = forma
	col.position.y = 1.7
	cuerpo.add_child(col)
	var vela := mat.liso(Color(0.92, 0.88, 0.76), 0.9)
	var llama := mat.brillo(Materiales.FUEGO, 1.3)
	for k in 7:
		var a := lerpf(-1.4, 1.4, float(k) / 6.0) + PI * 0.5
		var q := p + Vector3(cos(a) * 0.95, 0, sin(a) * 0.95)
		var alto := randf_range(0.12, 0.3)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.045
		cm.height = alto
		cm.radial_segments = 6
		lotes.poner(cm, Transform3D(Basis(), q + Vector3(0, alto * 0.5, 0)), vela)
		var sm := SphereMesh.new()
		sm.radius = 0.025
		sm.height = 0.07
		sm.radial_segments = 5
		sm.rings = 3
		lotes.poner(sm, Transform3D(Basis(), q + Vector3(0, alto + 0.04, 0)), llama)
	esc.halo(p, p + Vector3(0, 0.5, 0.6), Materiales.FUEGO, 3.4, 1.2, lotes)
	# hilo de luz que baja por la grieta
	var q := QuadMesh.new()
	q.size = Vector2(1.4, 22.0)
	var haz := MeshInstance3D.new()
	haz.mesh = q
	haz.material_override = mat.haz(Color(0.85, 0.9, 1.0, 0.18))
	haz.position = p + Vector3(-0.3, 11.0, 0.4)
	haz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	region.add_child(haz)
	return cuerpo


# ================================================================= V12: el Báculo del Peregrino y las notas

# El Báculo del Peregrino (hallazgos.gd, «hall_baculo_peregrino»): «al pie del pilar, apoyado en la piedra, un báculo
# gastado por muchas manos». Madera clara y pulida, el puño envuelto en cuero, el anillo partido de los peregrinos en
# la punta y una cinta roja; apoyado en la cara oeste del pilar (la que ve la cámara al llegar por la grieta), lejos
# de las velas (al sur) y de la veta de Ferro (al este). Un destello pequeño mientras está. Es un nodo aparte (no va en
# los lotes) para poder quitarlo al cogerlo. Sin choque: no estorba.
const BACULO_PIE := Vector3(-1.15, 0.0, 0.35)      # en los ejes del pilar (girado como él)
const BACULO_PUNTA := Vector3(-0.37, 1.2, 0.25)    # toca la cara oeste del fuste (a 1,2 m, x = −0,35), bajo su anillo


func baculo(pilar: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "BaculoPeregrino"
	n.position = pilar
	n.rotation.y = deg_to_rad(-20.0)                      # como el pilar (pilar_peregrino)
	region.add_child(n)
	var eje := BACULO_PUNTA - BACULO_PIE
	var giro := Basis(Quaternion(Vector3.UP, eje.normalized()))
	var largo := eje.length()
	var vara := CylinderMesh.new()
	vara.top_radius = 0.032
	vara.bottom_radius = 0.038
	vara.height = largo + 0.12
	vara.radial_segments = 7
	vara.rings = 1
	var lb := Roca.Lotes.new()                            # vara, puño y cinta: una sola malla (color en los vértices)
	lb.poner_color(vara, Transform3D(giro, BACULO_PIE + eje * 0.5), mat.madera_color(), Color(0.74, 0.58, 0.4))
	var cuero := CylinderMesh.new()                       # el puño, envuelto en cuero oscuro
	cuero.top_radius = 0.046
	cuero.bottom_radius = 0.046
	cuero.height = 0.22
	cuero.radial_segments = 7
	cuero.rings = 1
	lb.poner_color(cuero, Transform3D(giro, BACULO_PIE + eje * 0.68), mat.madera_color(), Color(0.27, 0.17, 0.11))
	var anillo := MeshInstance3D.new()                   # el anillo partido en la punta
	anillo.mesh = anillo_partido(0.09, 0.02, 52.0, 18, 5)
	anillo.material_override = mat.bronce()
	anillo.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(70.0)), BACULO_PUNTA + Vector3(-0.05, 0.13, 0.0))   # derecho, sin tocar el pilar
	n.add_child(anillo)
	var cinta := BoxMesh.new()                            # una cinta que cuelga bajo el anillo
	cinta.size = Vector3(0.035, 0.34, 0.006)
	lb.poner_color(cinta, Transform3D(Basis(Vector3.FORWARD, 0.12), BACULO_PUNTA + Vector3(-0.05, -0.17, 0.05)), mat.madera_color(),
		Color(0.66, 0.16, 0.14))
	lb.cerrar(n)
	destello(n, BACULO_PUNTA + Vector3(0, 0.1, 0.1), 0.38)
	return n


# Las notas para encontrar (dialogos/notas/garganta.gd): cada una con su objeto, como dice su texto. Lo que no se mueve
# va en los lotes; el destello (mientras no se ha leído) es aparte, para apagarlo. Devuelve {datos, pos (donde se
# examina), brillo}. «forma»: tabla, papel, escamas o cintas.
func nota(d: Dictionary, forma: String, leida: bool) -> Dictionary:
	var p: Vector3 = d["pos"]
	var donde := p                                   # donde se examina (y se apunta el botón)
	var sitio := Vector3(p.x, T.altura(p.x, p.z), p.z) if p.y > T.NIDO + 1.0 else p
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d["id"])
	var alto_destello := 1.1
	match forma:
		"tabla":                                     # la tabla de los puenteros: un poste con su tabla, junto al muro
			sitio.x -= 0.45
			var madera := mat.madera_vieja()
			var poste := CylinderMesh.new()
			poste.top_radius = 0.05
			poste.bottom_radius = 0.065
			poste.height = 1.25
			poste.radial_segments = 6
			poste.rings = 1
			lotes.poner(poste, Transform3D(Basis(), sitio + Vector3(0, 0.62, 0)), madera)
			var giro := Basis(Vector3.UP, deg_to_rad(55.0)) * Basis(Vector3.RIGHT, deg_to_rad(-8.0))
			var tabla := BoxMesh.new()
			tabla.size = Vector3(0.74, 0.46, 0.05)
			lotes.poner_color(tabla, Transform3D(giro, sitio + Vector3(0.04, 1.0, 0.03)), mat.madera_color(), Color(0.58, 0.46, 0.32))
			for k in 3:                              # las muescas de los puenteros, en tres renglones
				var bm := BoxMesh.new()
				bm.size = Vector3(0.5 - k * 0.1, 0.022, 0.012)
				lotes.poner_color(bm, Transform3D(giro, sitio + Vector3(0.04, 1.12 - k * 0.1, 0.03) + giro * Vector3(0, 0, 0.032)),
					mat.madera_color(), Color(0.2, 0.14, 0.1))
			# un rollo de cuerda nueva al pie
			var rollo := TorusMesh.new()
			rollo.inner_radius = 0.14
			rollo.outer_radius = 0.24
			rollo.rings = 12
			rollo.ring_segments = 5
			lotes.poner(rollo, Transform3D(Basis(), sitio + Vector3(0.32, 0.06, 0.12)), mat.cuerda())
			alto_destello = 1.45
		"papel":                                     # el aviso del ascensor: un papel clavado en un poste bajo
			sitio.x -= 0.4
			var poste := BoxMesh.new()
			poste.size = Vector3(0.12, 1.5, 0.12)
			lotes.poner(poste, Transform3D(Basis(), sitio + Vector3(0, 0.75, 0)), mat.madera_vieja())
			var giro := Basis(Vector3.UP, deg_to_rad(60.0)) * Basis(Vector3.FORWARD, deg_to_rad(4.0))
			var hoja := BoxMesh.new()
			hoja.size = Vector3(0.3, 0.38, 0.008)
			lotes.poner_color(hoja, Transform3D(giro, sitio + Vector3(0.0, 1.1, 0.0) + giro * Vector3(0, 0, 0.068)),
				mat.madera_color(), Color(0.86, 0.81, 0.68))
			var clavo := BoxMesh.new()
			clavo.size = Vector3(0.025, 0.025, 0.03)
			lotes.poner(clavo, Transform3D(giro, sitio + Vector3(0.0, 1.26, 0.0) + giro * Vector3(0, 0, 0.08)), mat.hierro())
			alto_destello = 1.6
		"escamas":                                   # escamas de ámbar del nido, grandes como platos, en el suelo
			sitio = p                                # en la repisa del nido (dialogos/notas/garganta.gd)
			for k in 5:
				var c := CylinderMesh.new()
				var r := rng.randf_range(0.13, 0.22)
				c.top_radius = r
				c.bottom_radius = r * 0.92
				c.height = 0.025
				c.radial_segments = 9
				c.rings = 1
				var a := TAU * k / 5.0 + rng.randf_range(-0.4, 0.4)
				var q := sitio + Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.2, 0.6) + Vector3(0, 0.03, 0)
				var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.25, 0.25))
				lotes.poner(c, Transform3D(b, q), mat.cristal_ambar())
			alto_destello = 0.5
		"cintas":                                    # cintas de colores atadas a una piedra, al pie del pilar
			sitio.x -= 0.6
			var piedra := SphereMesh.new()
			piedra.radius = 0.3
			piedra.height = 0.42
			piedra.radial_segments = 8
			piedra.rings = 4
			lotes.poner(piedra, Transform3D(Basis(Vector3.UP, 0.4), sitio + Vector3(0, 0.15, 0)), mat.piedra_tallada())
			var estaca := CylinderMesh.new()             # una estaca clavada en la piedra, con las cintas atadas arriba
			estaca.top_radius = 0.022
			estaca.bottom_radius = 0.03
			estaca.height = 0.75
			estaca.radial_segments = 5
			estaca.rings = 1
			lotes.poner(estaca, Transform3D(Basis(), sitio + Vector3(0, 0.4, 0)), mat.madera_vieja())
			var colores := [Color(0.72, 0.18, 0.16), Color(0.86, 0.66, 0.2), Color(0.2, 0.42, 0.66), Color(0.3, 0.55, 0.3),
				Color(0.86, 0.84, 0.78), Color(0.55, 0.3, 0.6)]
			for k in colores.size():
				var a := TAU * k / colores.size() + rng.randf_range(-0.2, 0.2)
				var cinta := BoxMesh.new()
				cinta.size = Vector3(0.07, rng.randf_range(0.42, 0.6), 0.008)
				var arriba := sitio + Vector3(cos(a) * 0.03, 0.74, sin(a) * 0.03)
				var caida := Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, rng.randf_range(0.2, 0.5))
				lotes.poner_color(cinta, Transform3D(caida, arriba + caida * Vector3(0, -cinta.size.y * 0.5, 0)),
					mat.tela_color(), colores[k])
			alto_destello = 1.0
	var brillo: MeshInstance3D = null
	if not leida:
		var ancla := Node3D.new()
		ancla.name = d["id"]
		ancla.position = sitio
		region.add_child(ancla)
		brillo = destello(ancla, Vector3(0, alto_destello, 0), 0.32)
	return {"datos": d, "pos": donde, "sitio": sitio, "brillo": brillo}


# ================================================================= salida

func marca_salida(p: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.88, 0.5, 0.35)
	var disco := CylinderMesh.new()
	disco.top_radius = 1.3
	disco.bottom_radius = 1.3
	disco.height = 0.02
	disco.radial_segments = 32
	var mi := MeshInstance3D.new()
	mi.mesh = disco
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p + Vector3(0, 0.06, 0)
	region.add_child(mi)
	var letrero := Label3D.new()
	letrero.text = "Mapa del mundo"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 48
	letrero.outline_size = 12
	letrero.modulate = Color(1.0, 0.96, 0.85)
	letrero.outline_modulate = Color(0.2, 0.15, 0.08, 0.8)
	letrero.pixel_size = 0.01
	letrero.position = p + Vector3(0, 2.2, 0)
	region.add_child(letrero)


# ================================================================= T-102: el resto del recorrido

# Una caja de «tam» hecha de sillares: hiladas de unos 0,55 m, juntas alternas y cada piedra con su tono (en los
# vértices; material sillar()). Para piezas que se vuelven medio transparentes al tapar a Kael: es una sola malla.
static func _sillares(tam: Vector3, rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hiladas := maxi(1, roundi(tam.y / 0.55))
	var alto := tam.y / hiladas
	var largo := maxf(tam.x, tam.z)
	var en_x := tam.x >= tam.z
	var junta := 0.025
	for h in hiladas:
		var piezas_h := maxi(1, roundi(largo / 0.95))
		var paso := largo / piezas_h
		var desfase := paso * 0.5 if h % 2 == 1 and piezas_h > 1 else 0.0
		var cortes: Array = [0.0]
		var c := desfase
		while c < largo - 0.05:
			if c > 0.05:
				cortes.append(c)
			c += paso
		cortes.append(largo)
		for i in cortes.size() - 1:
			var a: float = cortes[i]
			var b: float = cortes[i + 1]
			var bm := BoxMesh.new()
			var l := b - a - junta
			var centro := -largo * 0.5 + (a + b) * 0.5
			var y := -tam.y * 0.5 + alto * (h + 0.5)
			var hondo := rng.randf_range(-0.02, 0.0)                 # unas piedras salen algo más que otras
			if en_x:
				bm.size = Vector3(l, alto - junta, tam.z + hondo * 2.0)
			else:
				bm.size = Vector3(tam.x + hondo * 2.0, alto - junta, l)
			var pos := Vector3(centro, y, 0) if en_x else Vector3(0, y, centro)
			var color := Materiales.tono_piedra(Color(0.54, 0.51, 0.49), rng)
			var arr: Array = bm.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for k in arr[Mesh.ARRAY_INDEX]:
				st.set_color(color)
				st.set_normal(n[k])
				st.add_vertex(v[k] + pos)
	# el relleno de las juntas (oscuro), para que no se vea a través
	var fondo := BoxMesh.new()
	fondo.size = tam - Vector3(0.06, 0.02, 0.06)
	var fa: Array = fondo.surface_get_arrays(0)
	var fv: PackedVector3Array = fa[Mesh.ARRAY_VERTEX]
	var fn: PackedVector3Array = fa[Mesh.ARRAY_NORMAL]
	for k in fa[Mesh.ARRAY_INDEX]:
		st.set_color(Color(0.2, 0.19, 0.19))
		st.set_normal(fn[k])
		st.add_vertex(fv[k])
	return st.commit()


# Brasero de piedra con su fuego: cuenco de hierro sobre un pie, brasas, llama, halo y su calor en la roca.
func brasero(p: Vector3, fase: float) -> void:
	p.y = T.altura(p.x, p.z) if p.y == T.ALTO else p.y
	var pie := CylinderMesh.new()
	pie.top_radius = 0.16
	pie.bottom_radius = 0.24
	pie.height = 0.9
	pie.radial_segments = 8
	lotes.poner(pie, Transform3D(Basis(), p + Vector3(0, 0.45, 0)), mat.piedra_tallada())
	var cuenco := CylinderMesh.new()
	cuenco.top_radius = 0.34
	cuenco.bottom_radius = 0.18
	cuenco.height = 0.22
	cuenco.radial_segments = 10
	lotes.poner(cuenco, Transform3D(Basis(), p + Vector3(0, 1.0, 0)), mat.hierro())
	var brasas := CylinderMesh.new()
	brasas.top_radius = 0.29
	brasas.bottom_radius = 0.29
	brasas.height = 0.04
	brasas.radial_segments = 10
	lotes.poner(brasas, Transform3D(Basis(), p + Vector3(0, 1.1, 0)), mat.brillo(Color(1.0, 0.45, 0.16), 1.3))
	llama_en(p + Vector3(0, 1.42, 0), 0.62, fase, 1.1)
	esc.halo(p, p + Vector3(0, 1.3, 0), Materiales.FUEGO, 4.4, 1.7, lotes)
	mat.poner_fuego(p + Vector3(0, 1.3, 0), 5.0)
