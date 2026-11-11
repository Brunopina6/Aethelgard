extends RefCounted
# Sombras falsas del perfil sin sombras (el bajo) en el Mar de Cristal (12/11, gráficos;
# docs/memory/agents/graficos_v12_desierto2.md). En el Redmi el bajo se veía plano y lavado: sin la sombra del sol, nada
# ancla las rocas, las tiendas ni a los personajes a la arena. Aquí, sin coste al dibujar:
#   - sombras horneadas en la arena: cada pieza grande (rocas, paredes del cañón, cobijo, tiendas, carro, columnas,
#     costillar, palmeras) marca dónde caería su sombra (la dirección del sol de la región), con el borde suave y un poco
#     de oclusión al pie, en una rejilla de PASO metros que se calcula una vez al montar la escena (solo cerca de cada
#     pieza) y se pasa como textura al sombreado de la arena (shaders/desierto/arena.gdshader, SOMBRA_HORNEADA): suelo y
#     montones de las piezas a la vez, filtrada (suave) y sin coste de vértices;
#   - una mancha de sombra bajo Kael y su grupo (un cuadro por personaje, que sigue el suelo).
# El medio y el alto tienen sombras de verdad y no usan nada de esto.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const TINTE := Color(0.58, 0.55, 0.68)            # la sombra del desierto: fría, algo violeta (nunca gris)
const FUERZA := 0.75                              # 0 nada, 1 el tinte entero
const PASO := 1.0                                 # metros por celda de la rejilla
const LARGO_POR_ALTO := 1.375                     # sol a 36° sobre el horizonte (mar_cristal_3d.gd, Sol)
const SH_MANCHA := "res://shaders/desierto/mancha_sombra.gdshader"

var paso := PASO
var nx := 0
var nz := 0
var rejilla := PackedFloat32Array()              # 0 sin sombra, 1 sombra entera, por vértice de la arena
var dir_sombra := Vector2(0.743, 0.669)          # hacia dónde cae la sombra (x, z): al sureste
var largo_por_alto := LARGO_POR_ALTO
var manchas: Array = []                          # [nodo, cuadro]


func _init(sol: DirectionalLight3D) -> void:
	nx = int(T.TAM.x / paso) + 1
	nz = int(T.TAM.y / paso) + 1
	rejilla.resize(nx * nz)
	if sol != null:
		var d := -sol.global_transform.basis.z           # hacia dónde viaja la luz
		var h := Vector2(d.x, d.z)
		if h.length() > 0.01 and d.y < -0.05:
			dir_sombra = h.normalized()
			largo_por_alto = h.length() / -d.y


# Cuánta sombra hay en (x, z) (0-1), interpolada entre los vértices de la rejilla.
func en(x: float, z: float) -> float:
	var fx := x / paso
	var fz := z / paso
	var ix := int(floor(fx))
	var iz := int(floor(fz))
	if ix < 0 or iz < 0 or ix >= nx - 1 or iz >= nz - 1:
		return 0.0
	var tx := fx - ix
	var tz := fz - iz
	var a := lerpf(rejilla[iz * nx + ix], rejilla[iz * nx + ix + 1], tx)
	var b := lerpf(rejilla[(iz + 1) * nx + ix], rejilla[(iz + 1) * nx + ix + 1], tx)
	return lerpf(a, b, tz)


# La rejilla como textura para el sombreado de la arena, y sus parámetros (rect: x0, z0, 1/ancho, 1/fondo).
func aplicar(m: ShaderMaterial) -> void:
	if m == null:
		return
	var datos := PackedByteArray()
	datos.resize(nx * nz)
	for k in rejilla.size():
		datos[k] = int(clampf(rejilla[k], 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(nx, nz, false, Image.FORMAT_L8, datos)
	# cada texel es el centro de su celda: el rectángulo empieza medio paso antes
	m.set_shader_parameter("sombra_horneada", ImageTexture.create_from_image(img))
	m.set_shader_parameter("sombra_rect", Vector4(-paso * 0.5, -paso * 0.5, 1.0 / (nx * paso), 1.0 / (nz * paso)))
	m.set_shader_parameter("sombra_tinte", Vector3(TINTE.r, TINTE.g, TINTE.b))
	m.set_shader_parameter("sombra_fuerza", FUERZA)


# Al salir (o con sombras de verdad): la arena sin sombra horneada.
static func quitar(m: ShaderMaterial) -> void:
	if m != null:
		m.set_shader_parameter("sombra_fuerza", 0.0)


# Una pieza que da sombra: el segmento a-b de su planta (en metros, x z), su radio, su alto sobre la arena y cuánto se
# estrecha hacia arriba (0 nada, 0,6 una chimenea). La sombra es esa planta arrastrada en la dirección del sol.
func pieza(a: Vector2, b: Vector2, radio: float, alto: float, estrecha := 0.35) -> void:
	var largo := alto * largo_por_alto
	var fin_a := a + dir_sombra * largo
	var fin_b := b + dir_sombra * largo
	var minimo := Vector2(minf(minf(a.x, b.x), minf(fin_a.x, fin_b.x)), minf(minf(a.y, b.y), minf(fin_a.y, fin_b.y))) - Vector2.ONE * (radio * 1.3)
	var maximo := Vector2(maxf(maxf(a.x, b.x), maxf(fin_a.x, fin_b.x)), maxf(maxf(a.y, b.y), maxf(fin_a.y, fin_b.y))) + Vector2.ONE * (radio * 1.3)
	for iz in range(maxi(0, int(minimo.y / paso)), mini(nz, int(maximo.y / paso) + 2)):
		for ix in range(maxi(0, int(minimo.x / paso)), mini(nx, int(maximo.x / paso) + 2)):
			var p := Vector2(ix * paso, iz * paso)
			var s := _sombra_en(p, a, b, radio, largo, estrecha)
			var k := iz * nx + ix
			rejilla[k] = maxf(rejilla[k], s)


func _sombra_en(p: Vector2, a: Vector2, b: Vector2, radio: float, largo: float, estrecha: float) -> float:
	var mejor := 0.0
	var pasos := clampi(int(largo / maxf(radio * 0.6, 0.5)) + 1, 1, 10)
	for i in pasos + 1:
		var t := float(i) / pasos
		var off := dir_sombra * largo * t
		var r := radio * (1.0 - estrecha * t)
		var d := _dist_segmento(p - off, a, b)
		var s := 1.0 - smoothstep(r * 0.55, r * 1.2, d)
		s *= 1.0 - 0.35 * t * t                          # la punta de la sombra, algo más suave
		mejor = maxf(mejor, s)
	# oclusión al pie, también del lado del sol
	var pie := (1.0 - smoothstep(radio * 0.9, radio * 1.35, _dist_segmento(p, a, b))) * 0.55
	return maxf(mejor, pie)


static func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# Una pieza de gráficos ya colocada: su planta y su alto, de su caja (AABB) en el mundo. Las palmeras, aparte: el tronco
# es fino y la copa da su mancha lejos, donde cae.
func pieza_de_nodo(n: Node3D, id: String) -> void:
	var caja := _caja_mundo(n)
	if caja.size == Vector3.ZERO:
		return
	var suelo := T.altura(caja.get_center().x, caja.get_center().z)
	var alto := caja.end.y - suelo
	if alto < 0.5:
		return
	var c := Vector2(caja.get_center().x, caja.get_center().z)
	if id.begins_with("palmera"):
		var base := Vector2(n.global_position.x, n.global_position.z)
		pieza(base, base, 0.22, alto * 0.85, 0.0)                              # el tronco
		var copa := c + dir_sombra * (alto * 0.9) * largo_por_alto
		pieza(copa, copa, clampf(minf(caja.size.x, caja.size.z) * 0.38, 1.2, 2.6), 0.0, 0.0)
		return
	if id.begins_with("juncos"):
		pieza(c, c, 0.5, minf(alto, 1.2), 0.5)
		return
	var ancho := caja.size.x
	var fondo := caja.size.z
	var eje := Vector2(maxf(0.0, ancho - fondo) * 0.5, 0.0) if ancho >= fondo else Vector2(0.0, maxf(0.0, fondo - ancho) * 0.5)
	var radio := minf(ancho, fondo) * 0.5 * 0.85
	var estrecha := 0.45 if id.begins_with("roca") else (0.65 if id.begins_with("tienda_b") else 0.25)
	pieza(c - eje * 0.85, c + eje * 0.85, radio, alto, estrecha)


static func _caja_mundo(n: Node3D) -> AABB:
	var caja := AABB()
	var hay := false
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.visible:
			continue
		var b: AABB = m.global_transform * m.get_aabb()
		caja = b if not hay else caja.merge(b)
		hay = true
	return caja


# ---------------------------------------------------------------- manchas bajo los personajes

func mancha(padre: Node3D, tam := Vector2(1.0, 0.8)) -> void:
	if padre == null:
		return
	var q := QuadMesh.new()
	q.size = tam
	q.orientation = PlaneMesh.FACE_Y
	var mi := MeshInstance3D.new()
	mi.name = "ManchaSombra"
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = load(SH_MANCHA)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true                                   # la coloca actualizar(), pegada a la arena
	padre.add_child(mi)
	manchas.append([padre, mi])


# Cada fotograma: cada mancha bajo su personaje, algo corrida hacia donde cae la sombra y por encima de la arena.
func actualizar() -> void:
	for par in manchas:
		var n = par[0]
		var mi = par[1]
		if not is_instance_valid(n) or not is_instance_valid(mi):
			continue
		mi.visible = (n as Node3D).is_visible_in_tree()
		var p: Vector3 = (n as Node3D).global_position
		var c := Vector2(p.x, p.z) + dir_sombra * 0.22
		var y := maxf(T.altura(c.x, c.y), maxf(T.altura(c.x + 0.45, c.y), T.altura(c.x, c.y + 0.45)))
		y = maxf(y, T.altura(c.x - 0.45, c.y - 0.45))
		mi.global_position = Vector3(c.x, minf(y, p.y + 0.3) + 0.035, c.y)
