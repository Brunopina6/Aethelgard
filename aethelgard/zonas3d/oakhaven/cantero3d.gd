extends RefCounted
# V12, PROPUESTA apagada «Las tres marcas del cantero» (ciudades/oakhaven_propuestas.gd): lo que se ve en Oakhaven 3D.
#   - Las tres marcas: una placa de piedra con la runa tallada (hundida y oscura, con un hilo de luz cálida en el surco
#     para que se lea a la hora azul) y sus muescas debajo. La cámara mira siempre desde el sur y desde arriba, así que
#     las caras miran hacia ella: la de la fuente, en la cara sureste del pilón; la de la raíz, tumbada encima de la raíz
#     que baja a la Calle del Árbol (sin estorbar el paso); la de la torre, en una estela baja inclinada hacia atrás.
#     La textura se pinta por código (Image), una vez por marca: sin archivos nuevos.
#   - El sillar del aprendiz: el bloque que labra, delante de él.
# Sin choque en las placas (no estorban); la estela y el sillar sí chocan (como un cofre).
# Lo usa zonas3d/oakhaven/vida3d.gd (_poner_cantero). Las posiciones se comprobaron con capturas (docs/v12/CANTERO_V12.md).

const Propuestas := preload("res://ciudades/oakhaven_propuestas.gd")
const TAM := 128

# Dónde va cada placa en la 3D: «en»: x, z; «alto»: altura del centro sobre el suelo («sobre»: altura absoluta, la de
# encima de la raíz); «giro»: hacia dónde mira la cara (radianes en Y; 0 = +Z, al sur; PI/4, al sureste); «estela»: sobre
# una piedra propia (con choque); «inclina»: cuánto se echa hacia atrás (radianes); «tumbada»: boca arriba, con esa
# inclinación hacia el sur (radianes). Medidas (14/11, sonda de vértices): el borde del pilón, de 1,5 a 1,75 m del centro
# (40, 26) y 0,64 m de alto; la raíz de la Calle del Árbol, de 0,45 a 0,34 m de alto entre z 11,2 y 11,8 en x 39,8.
const SITIOS := {
	"oak_marca_fuente": {"en": Vector2(40.0 + 1.79 * 0.7071, 26.0 + 1.79 * 0.7071), "alto": 0.34, "giro": PI / 4.0,
		"tam": 0.34},
	"oak_marca_torre": {"en": Vector2(70.9, 43.2), "alto": 0.5, "giro": 0.0, "estela": true, "inclina": 0.32, "tam": 0.38},
	"oak_marca_raiz": {"en": Vector2(39.8, 11.5), "sobre": 0.425, "giro": 0.0, "tumbada": 0.3, "tam": 0.3},
}

static var _texturas := {}


# La textura de una marca: piedra con la runa hundida y «muescas» cortes debajo. [albedo, emisión].
static func texturas(simbolo: String, muescas: int) -> Array:
	var clave := "%s_%d" % [simbolo, muescas]
	if _texturas.has(clave):
		return _texturas[clave]
	var alb := Image.create(TAM, TAM, false, Image.FORMAT_RGBA8)
	var emi := Image.create(TAM, TAM, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(clave)
	var m := Vector2(64, 52)
	var e := 0.86
	for y in TAM:
		for x in TAM:
			var p := Vector2(x + 0.5, y + 0.5)
			var g := 0.5 + 0.06 * rng.randf() + 0.03 * sin(x * 0.21 + y * 0.07)
			var piedra := Color(g, g * 0.98, g * 0.93)
			var hondo := _dentro(simbolo, p, m, e) or _en_muesca(p, muescas)
			var borde := not hondo and (_dentro(simbolo, p + Vector2(1.5, 1.5), m, e)
				or _en_muesca(p + Vector2(1.5, 1.5), muescas))
			var c := piedra
			if hondo:
				c = piedra.darkened(0.62)
			elif borde:
				c = piedra.lightened(0.28)                 # la arista iluminada del corte
			var marco := minf(minf(x, y), minf(TAM - 1 - x, TAM - 1 - y))
			if marco < 4:
				c = c.darkened(0.25 * (1.0 - marco / 4.0))
			alb.set_pixel(x, y, c)
			emi.set_pixel(x, y, Color(1.0, 0.72, 0.36) * (0.55 if hondo else 0.0))
	alb.generate_mipmaps()
	emi.generate_mipmaps()
	var r := [ImageTexture.create_from_image(alb), ImageTexture.create_from_image(emi)]
	_texturas[clave] = r
	return r


# Las mismas formas que taberna_parejas.gd (dibujar_simbolo), en un píxel.
static func _dentro(simbolo: String, p: Vector2, m: Vector2, e: float) -> bool:
	match simbolo:
		"Agua":
			return (p - (m + Vector2(0, 10) * e)).length() < 28 * e or Geometry2D.is_point_in_polygon(p,
				PackedVector2Array([m + Vector2(0, -42) * e, m + Vector2(22, 0) * e, m + Vector2(-22, 0) * e]))
		"Rayo":
			return Geometry2D.is_point_in_polygon(p, PackedVector2Array([m + Vector2(8, -44) * e,
				m + Vector2(-20, 6) * e, m + Vector2(-2, 6) * e, m + Vector2(-10, 44) * e, m + Vector2(22, -8) * e,
				m + Vector2(4, -8) * e]))
		"Luna":
			return (p - m).length() < 34 * e and (p - (m + Vector2(14, -8) * e)).length() >= 30 * e
	return false


static func _en_muesca(p: Vector2, n: int) -> bool:
	if p.y < 104 or p.y > 120:
		return false
	var ancho := 6.0
	var paso := 16.0
	var x0 := 64.0 - (n - 1) * paso * 0.5
	for i in n:
		if absf(p.x - (x0 + i * paso)) < ancho * 0.5:
			return true
	return false


# La placa de una marca (QuadMesh con su textura), o null si no es una marca.
static func placa(id: String) -> MeshInstance3D:
	if not Propuestas.MARCAS.has(id):
		return null
	var dat: Array = Propuestas.MARCAS[id]
	var tex := texturas(dat[0], dat[1])
	var mi := MeshInstance3D.new()
	mi.name = "Placa_" + id
	var q := QuadMesh.new()
	q.size = Vector2(0.36, 0.36)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex[0]
	m.emission_enabled = true
	m.emission_texture = tex[1]
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = 0.9
	m.roughness = 0.95
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# La marca entera en su sitio (la placa y, si toca, su estela), colgada de «padre». «altura»: el suelo en (x, z).
static func poner_marca(padre: Node3D, id: String, altura: Callable, mat_piedra: Material) -> Node3D:
	var s: Dictionary = SITIOS.get(id, {})
	var pl := placa(id)
	if s.is_empty() or pl == null:
		return null
	var en: Vector2 = s["en"]
	var n := Node3D.new()
	n.name = "Marca_" + id
	n.position = Vector3(en.x, float(s["sobre"]) if s.has("sobre") else float(altura.call(en.x, en.y)), en.y)
	n.rotation.y = float(s["giro"])
	padre.add_child(n)
	var tam := float(s.get("tam", 0.36))
	(pl.mesh as QuadMesh).size = Vector2(tam, tam)
	if s.has("tumbada"):                                 # boca arriba, algo inclinada hacia el sur (hacia la cámara)
		pl.rotation.x = -PI / 2.0 + float(s["tumbada"])
		pl.position.y = 0.01
		n.add_child(pl)
		return n
	var alto := float(s["alto"])
	var pivote := Node3D.new()                           # la estela y su placa se echan hacia atrás juntas, desde el pie
	pivote.rotation.x = -float(s.get("inclina", 0.0))
	n.add_child(pivote)
	if s.get("estela", false):
		var est := MeshInstance3D.new()
		est.name = "Estela"
		var caja := BoxMesh.new()
		caja.size = Vector3(tam + 0.12, alto + tam * 0.5 + 0.08, 0.2)
		est.mesh = caja
		est.position = Vector3(0, caja.size.y * 0.5, -0.1)
		if mat_piedra != null:
			est.material_override = mat_piedra
		pivote.add_child(est)
		var cuerpo := StaticBody3D.new()                 # (el choque, derecho: basta con el pie)
		var col := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(caja.size.x, 0.6, 0.3)
		col.shape = forma
		col.position = Vector3(0, 0.3, -0.1)
		cuerpo.add_child(col)
		n.add_child(cuerpo)
	pl.position = Vector3(0, alto, 0.006)
	pivote.add_child(pl)
	return n


# El sillar que labra el aprendiz: un bloque desbastado delante de él, con choque.
static func sillar(mat_piedra: Material) -> Node3D:
	var n := Node3D.new()
	n.name = "Sillar_cantero"
	var mi := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.62, 0.42, 0.42)
	mi.mesh = caja
	mi.position.y = 0.21
	mi.rotation.y = 0.18
	if mat_piedra != null:
		mi.material_override = mat_piedra
	n.add_child(mi)
	var cuerpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.62, 0.42, 0.42)
	col.shape = forma
	col.position.y = 0.21
	col.rotation.y = 0.18
	cuerpo.add_child(col)
	n.add_child(cuerpo)
	return n
