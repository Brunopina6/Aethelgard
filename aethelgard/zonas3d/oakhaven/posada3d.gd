extends RefCounted
# Oakhaven 3D (T-103): el interior de la Taberna del Cuervo Oxidado, la posada. Una sala de 12 × 8 m que se recorre
# (lejos de la ciudad, en ORIGEN: se entra con un fundido por la puerta de la taberna): suelo de tablas, muros de
# piedra abajo y revoque arriba, la barra con la posadera, el hogar encendido, mesas con velas y parroquianos, barriles
# y la escalera a las habitaciones. La pared del sur es baja (como una casa de muñecas): la cámara, que mira al norte,
# ve dentro. Los servicios (dormir, comer, rumores) son los de ciudades/oakhaven_posada.gd.

const Roca := preload("res://zonas3d/garganta/roca.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")

const ORIGEN := Vector3(200.0, 0.0, 200.0)       # esquina noroeste de la sala
const ANCHO := 12.0                              # x
const FONDO := 8.0                               # z
const ALTO := 3.4
const ENTRADA := Vector3(6.0, 0.0, 7.2)          # (relativas a ORIGEN) donde aparece Kael al entrar
const PUERTA := Vector3(6.0, 0.0, 7.9)           # la puerta de salida, en la pared del sur
const POSADERA := Vector3(3.0, 0.0, 1.4)         # detrás de la barra
const MOSTRADOR := Vector3(3.4, 0.0, 3.05)       # donde se para Kael para hablar con ella (ante la barra)
const HOGAR := Vector3(10.6, 0.0, 1.0)

var region: Node3D
var mat: Materiales
var perfil: Dictionary
var lotes: Roca.Lotes
var bloqueos: Array = []                         # Rect2 relativos a ORIGEN (x, z) que no se pisan
var posadera: Node3D


func _init(r: Node3D, m: Materiales, p: Dictionary) -> void:
	region = r
	mat = m
	perfil = p
	lotes = Roca.Lotes.new()


static func en_sala(p: Vector3) -> bool:
	var l := p - ORIGEN
	return l.x > 0.6 and l.x < ANCHO - 0.6 and l.z > 0.7 and l.z < FONDO - 0.35 and absf(l.y) < 3.0


func construir() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2525
	var madera := mat.madera_color()
	var sillar := mat.sillar()
	# suelo de tablas (cada una con su tono) y su colisión
	var z := 0.0
	while z < FONDO:
		var ancho := rng.randf_range(0.26, 0.34)
		var tabla := BoxMesh.new()
		tabla.size = Vector3(ANCHO, 0.06, ancho - 0.015)
		lotes.poner_color(tabla, Transform3D(Basis(), ORIGEN + Vector3(ANCHO * 0.5, -0.03, z + ancho * 0.5)), madera,
			Materiales.tono_madera(rng))
		z += ancho
	_choque(Vector3(ANCHO * 0.5, -0.1, FONDO * 0.5), Vector3(ANCHO + 2.0, 0.2, FONDO + 2.0))
	# muros: piedra abajo (sillares) y revoque cálido arriba con vigas; al sur, un murete con el hueco de la puerta
	var revoque := mat.liso(Color(0.80, 0.70, 0.55), 1.0)
	for muro in [[Vector3(ANCHO * 0.5, 0, -0.15), Vector3(ANCHO + 0.6, 0, 0.3)], [Vector3(-0.15, 0, FONDO * 0.5), Vector3(0.3, 0, FONDO)],
			[Vector3(ANCHO + 0.15, 0, FONDO * 0.5), Vector3(0.3, 0, FONDO)]]:
		var c: Vector3 = muro[0]
		var t: Vector3 = muro[1]
		var bajo := BoxMesh.new()
		bajo.size = Vector3(t.x, 1.1, t.z)
		lotes.poner_color(bajo, Transform3D(Basis(), ORIGEN + c + Vector3(0, 0.55, 0)), sillar, Materiales.tono_piedra(Color(0.5, 0.47, 0.44), rng))
		var alto := BoxMesh.new()
		alto.size = Vector3(t.x * 0.98 if t.x > 1.0 else t.x * 0.9, ALTO - 1.1, t.z * 0.98 if t.z > 1.0 else t.z * 0.9)
		lotes.poner(alto, Transform3D(Basis(), ORIGEN + c + Vector3(0, 1.1 + (ALTO - 1.1) * 0.5, 0)), revoque)
		_choque(c + Vector3(0, ALTO * 0.5, 0), Vector3(t.x, ALTO, t.z))
	for x in [1.5, 4.5, 7.5, 10.5]:                       # vigas del muro del fondo
		var viga := BoxMesh.new()
		viga.size = Vector3(0.22, ALTO - 1.1, 0.12)
		lotes.poner_color(viga, Transform3D(Basis(), ORIGEN + Vector3(x, 1.1 + (ALTO - 1.1) * 0.5, 0.08)), madera, Color(0.30, 0.22, 0.16))
	for lado in [-1.0, 1.0]:                              # murete del sur, a los lados de la puerta
		var largo := ANCHO * 0.5 - 0.9
		var cx: float = ANCHO * 0.5 + lado * (0.9 + largo * 0.5)
		var m := BoxMesh.new()
		m.size = Vector3(largo, 0.7, 0.3)
		lotes.poner_color(m, Transform3D(Basis(), ORIGEN + Vector3(cx, 0.35, FONDO + 0.15)), sillar, Materiales.tono_piedra(Color(0.5, 0.47, 0.44), rng))
		_choque(Vector3(cx, 0.6, FONDO + 0.15), Vector3(largo, 1.2, 0.3))
	# la barra, con su tablero, botellas y jarras; la posadera detrás
	_mueble(Vector3(3.0, 0.55, 2.0), Vector3(4.4, 1.1, 0.7), Color(0.36, 0.24, 0.16), madera, true)
	_mueble(Vector3(3.0, 1.12, 2.0), Vector3(4.6, 0.06, 0.85), Color(0.46, 0.32, 0.2), madera, false)
	var vidrio := [Color(0.25, 0.45, 0.30), Color(0.50, 0.25, 0.20), Color(0.70, 0.55, 0.25), Color(0.30, 0.30, 0.45)]
	for i in 14:                                          # el estante del fondo, con botellas
		var b := CylinderMesh.new()
		b.top_radius = 0.035
		b.bottom_radius = 0.06
		b.height = rng.randf_range(0.22, 0.32)
		b.radial_segments = 6
		lotes.poner_color(b, Transform3D(Basis(), ORIGEN + Vector3(1.2 + i * 0.26, 1.75 + b.height * 0.5 + (0.6 if i % 2 else 0.0), 0.32)),
			madera, vidrio[i % vidrio.size()])
	for y in [1.75, 2.35]:
		_mueble(Vector3(3.0, y - 0.03, 0.32), Vector3(4.0, 0.05, 0.35), Color(0.34, 0.24, 0.16), madera, false)
	posadera = _figura(POSADERA, Color(0.48, 0.16, 0.18), Color(0.92, 0.88, 0.80), Color(0.55, 0.32, 0.18), "Posadera")
	# el hogar: piedra, fuego, su halo y luz cálida en la sala
	_mueble(HOGAR + Vector3(0, 1.1, -0.25), Vector3(1.8, 2.2, 0.5), Color(0.42, 0.40, 0.38), sillar, true)
	_mueble(HOGAR + Vector3(0, 0.25, 0.2), Vector3(1.6, 0.5, 0.6), Color(0.30, 0.29, 0.28), sillar, true)
	var brasas := BoxMesh.new()
	brasas.size = Vector3(0.9, 0.08, 0.35)
	lotes.poner(brasas, Transform3D(Basis(), ORIGEN + HOGAR + Vector3(0, 0.55, 0.2)), mat.brillo(Color(1.0, 0.45, 0.15), 1.4))
	_llama(HOGAR + Vector3(-0.2, 0.85, 0.25), 0.6, 1.0)
	_llama(HOGAR + Vector3(0.22, 0.8, 0.25), 0.5, 2.3)
	_halo(HOGAR + Vector3(0, 0, 1.4), HOGAR + Vector3(0, 0.9, 0.4), 6.0, 2.0)
	if perfil.get("luces_faroles", false):
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.66, 0.38)
		o.light_energy = 1.6
		o.omni_range = 9.0
		o.position = ORIGEN + HOGAR + Vector3(0, 1.2, 1.0)
		o.name = "LuzHogar"
		region.add_child(o)
	# mesas con velas, bancos y parroquianos
	for d in [[Vector3(7.6, 0, 3.0), true], [Vector3(9.2, 0, 5.7), true], [Vector3(2.6, 0, 6.2), false]]:   # (paso libre de la puerta a la barra)
		var c: Vector3 = d[0]
		_mueble(c + Vector3(0, 0.74, 0), Vector3(1.6, 0.07, 0.9), Color(0.44, 0.31, 0.2), madera, false)
		for pata in [Vector3(-0.65, 0, -0.32), Vector3(0.65, 0, -0.32), Vector3(-0.65, 0, 0.32), Vector3(0.65, 0, 0.32)]:
			_mueble(c + pata + Vector3(0, 0.36, 0), Vector3(0.08, 0.72, 0.08), Color(0.3, 0.21, 0.14), madera, false)
		for lado in [-1.0, 1.0]:
			_mueble(c + Vector3(0, 0.42, lado * 0.75), Vector3(1.5, 0.06, 0.32), Color(0.38, 0.27, 0.18), madera, false)
		_choque(c + Vector3(0, 0.5, 0), Vector3(1.7, 1.0, 1.9))
		bloqueos.append(Rect2(c.x - 0.85, c.z - 0.95, 1.7, 1.9))
		_llama(c + Vector3(0.2, 0.92, 0.0), 0.14, c.x)
		var vela := CylinderMesh.new()
		vela.top_radius = 0.03
		vela.bottom_radius = 0.03
		vela.height = 0.12
		lotes.poner_color(vela, Transform3D(Basis(), ORIGEN + c + Vector3(0.2, 0.84, 0)), madera, Color(0.95, 0.92, 0.82))
		_halo(c, c + Vector3(0.2, 0.95, 0), 2.4, 0.6)
		if d[1]:
			_figura(c + Vector3(-0.3, 0, -0.78), Color(0.30, 0.36, 0.48), Color(0.80, 0.70, 0.55), Color(0.25, 0.18, 0.12), "Parroquiano", 0.85)
	# barriles junto a la barra y la escalera a las habitaciones (decorado)
	for i in 3:
		var b := CylinderMesh.new()
		b.top_radius = 0.32
		b.bottom_radius = 0.32
		b.height = 0.85
		b.radial_segments = 10
		lotes.poner_color(b, Transform3D(Basis(), ORIGEN + Vector3(0.6 + i * 0.7, 0.43, 3.6 + (i % 2) * 0.2)), madera, Materiales.tono_madera(rng))
	_choque(Vector3(1.3, 0.5, 3.7), Vector3(2.2, 1.0, 0.9))
	bloqueos.append(Rect2(0.2, 3.2, 2.3, 1.0))
	for k in 8:
		_mueble(Vector3(11.2, 0.2 + k * 0.38, 7.0 - k * 0.55), Vector3(1.2, 0.12, 0.5), Color(0.38, 0.27, 0.18), madera, false)
	_choque(Vector3(11.2, 1.5, 5.0), Vector3(1.3, 3.0, 4.4))
	bloqueos.append(Rect2(10.5, 2.6, 1.6, 4.8))
	bloqueos.append(Rect2(0.6, 1.5, 4.9, 1.0))               # la barra
	bloqueos.append(Rect2(9.6, 0.4, 2.0, 1.2))               # el hogar
	_choque(Vector3(3.0, 0.6, 2.0), Vector3(4.6, 1.2, 0.85))
	_choque(HOGAR + Vector3(0, 1.0, 0), Vector3(1.9, 2.0, 1.1))
	lotes.cerrar(region)


func _mueble(c: Vector3, tam: Vector3, color: Color, m: Material, sombra: bool) -> void:
	var bm := BoxMesh.new()
	bm.size = tam
	lotes.poner_color(bm, Transform3D(Basis(), ORIGEN + c), m, color)


func _choque(c: Vector3, tam: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = ORIGEN + c
	region.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tam
	col.shape = caja
	cuerpo.add_child(col)


# Una figura sencilla (como Tilo en Pastos Verdes): cuerpo, delantal o capa, cabeza y pelo; respira despacio.
func _figura(p: Vector3, ropa: Color, piel_clara: Color, pelo: Color, nombre: String, escala := 1.0) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = nombre
	raiz.position = ORIGEN + p
	raiz.scale = Vector3.ONE * escala
	region.add_child(raiz)
	var cuerpo := CapsuleMesh.new()
	cuerpo.radius = 0.28
	cuerpo.height = 1.3
	_pieza(raiz, cuerpo, ropa, Vector3(0, 0.66, 0))
	var delantal := BoxMesh.new()
	delantal.size = Vector3(0.42, 0.7, 0.05)
	_pieza(raiz, delantal, Color(0.9, 0.87, 0.78), Vector3(0, 0.55, 0.27))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.17
	cabeza.height = 0.34
	_pieza(raiz, cabeza, Color(0.95, 0.80, 0.68), Vector3(0, 1.45, 0))
	var mono := SphereMesh.new()
	mono.radius = 0.15
	mono.height = 0.24
	_pieza(raiz, mono, pelo, Vector3(0, 1.56, -0.06))
	var t := raiz.create_tween().set_loops()
	t.tween_property(raiz, "position:y", raiz.position.y + 0.02, 1.7).set_trans(Tween.TRANS_SINE)
	t.tween_property(raiz, "position:y", raiz.position.y, 1.7).set_trans(Tween.TRANS_SINE)
	return raiz


func _pieza(padre: Node3D, malla: Mesh, color: Color, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat.liso(color, 0.9)
	mi.position = pos
	padre.add_child(mi)


func _llama(p: Vector3, alto: float, fase: float) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(alto * 0.62, alto)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat.llama(fase, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = ORIGEN + p
	region.add_child(mi)


func _halo(suelo: Vector3, aire: Vector3, ancho: float, tam_aire: float) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(ancho, ancho)
	lotes.poner(pm, Transform3D(Basis(), ORIGEN + suelo + Vector3(0, 0.02, 0)), mat.halo_suelo(Materiales.FUEGO))
	var q := QuadMesh.new()
	q.size = Vector2(tam_aire, tam_aire)
	var brillo := MeshInstance3D.new()
	brillo.mesh = q
	brillo.material_override = mat.halo_aire(Materiales.FUEGO)
	brillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	brillo.position = ORIGEN + aire
	region.add_child(brillo)
