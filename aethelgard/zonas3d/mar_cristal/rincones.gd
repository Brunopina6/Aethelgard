extends RefCounted
# Rincones del Mar de Cristal (V12, 12/11/2026, narrativa y exploración; docs/memory/agents/narrativa_v12_mc_rincon.md).
# Una interacción opcional, fuera de «La caravana perdida» (mision.gd), sobre un sitio que ya estaba construido:
#
#   El hito del cobijo (paisaje.gd, _hito: cinco lajas, un palo y un trapo azul, junto al cobijo del cañón). Aquí se le
#   cuelgan tres vidrios del palo que tintinean con el viento y destellan al sonar: se encuentra por el oído y por el
#   brillo, sin marcador. Con tormenta suenan más a menudo y se oyen más lejos (es para lo que los colgaron las
#   caravanas: cuando el trapo no se ve, el vidrio se oye). «Mirar el hito»: bajo la laja de arriba hay una bolsa de
#   cuero encerado con un paño de signos (azul, cobijo; rojo, camino de vuelta, como los postes de la salida) y dos
#   Pociones que dejaron otros viajeros. Diálogo según el grupo (mc_rin_hito, _lya, _solo) y la recompensa una vez
#   (hito «mc_rin_hito», progreso.gd): primero el hito, luego las Pociones, y se guarda.
#
# No toca la misión, el buscador, el gusano ni a Naira: ni pone ni quita sus hitos. Partidas antiguas: sin el hito,
# todo está por descubrir. La región (mar_cristal_3d.gd) llama a: construir, piezas, accion, actualizar y
# dialogo_terminado.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const RUTA_ARTE := "res://zonas3d/mar_cristal/materiales_arte.gd"
const HITO_ID := "mc_rin_hito"
# El sitio del hito, el mismo que pone paisaje.gd (_matorrales: COBIJO + (5,6, −1,4)); el palo, en su centro.
const HITO := Vector2(T.COBIJO.x + 5.6, T.COBIJO.y - 1.4)
const ALTO_LAJAS := 1.012                   # paisaje.gd: cinco lajas de 0,22 × 0,92
const RADIO := 2.0                          # metros para el botón (lejos del cobijo: 5,8 m)
const POCIONES := 2
# El vidrio que suena: clave existente de sonido.gd (copa de cristal frotada; más aguda, parece vidrio pequeño).
const SONIDO := "orbe_cierra"
const SONIDO_3D := {"unidad": 6.0, "max": 45.0, "filtro": -6.0}
const OIR := 24.0                           # metros: en calma se oye a esta distancia o menos...
const OIR_TORMENTA := 42.0                  # ...y con tormenta, más lejos
const CADA := [6.0, 10.0]                   # segundos entre tintineos, en calma
const CADA_TORMENTA := [2.6, 4.2]
const DIALOGO := "mc_rin_hito"              # dialogos/mar_cristal/mc_rin_hito(_lya|_solo).dtl
const BOTON := "Mirar el hito"
const TEXTOS := {
	"premio": "Coges dos Pociones de la bolsa. El paño de los signos vuelve a su sitio.",
	"visto": "El hito del cobijo: trapo azul, nudo prieto y vidrio que suena.",
}

var region: Node3D
var raiz: Node3D
var vidrios: Array = []                     # los tres colgantes (pivote en el palo)
var destello: MeshInstance3D
var tintineos := 0                          # veces que ha sonado (las pruebas lo miran)
var _rng := RandomNumberGenerator.new()
var _t_son := 1.5
var _t := 0.0
var _brillo := 0.0


static func P():
	return load("res://progreso.gd")


static func visto() -> bool:
	return P().hito(HITO_ID)


static func pos_hito() -> Vector3:
	return Vector3(HITO.x, T.altura(HITO.x, HITO.y), HITO.y)


func construir(r: Node3D) -> void:
	region = r
	_rng.seed = 1211
	raiz = Node3D.new()
	raiz.name = "RinconHito"
	r.add_child(raiz)
	var base := pos_hito()
	var arte = load(RUTA_ARTE) if ResourceLoader.exists(RUTA_ARTE) else null
	# Tres vidrios del tamaño de una mano, colgados de un cordel en el lado del palo opuesto al trapo.
	for i in 3:
		var pivote := Node3D.new()
		pivote.name = "Vidrio%d" % i
		pivote.position = base + Vector3(-0.08 - 0.13 * i, ALTO_LAJAS + 1.32 - 0.05 * i, 0.04 * (i - 1))
		raiz.add_child(pivote)
		var cordel := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.008
		c.bottom_radius = 0.008
		c.height = 0.14 + 0.06 * i
		c.radial_segments = 4
		cordel.mesh = c
		cordel.position.y = -c.height * 0.5
		var mc := StandardMaterial3D.new()
		mc.albedo_color = Color(0.36, 0.28, 0.20)
		cordel.material_override = mc
		cordel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivote.add_child(cordel)
		var cristal := MeshInstance3D.new()
		cristal.mesh = _prisma(0.055 + 0.01 * i, 0.30 - 0.04 * i, [Color(0.66, 0.92, 0.95), Color(0.72, 0.86, 0.98), Color(0.70, 0.94, 0.86)][i])
		cristal.position.y = -c.height - 0.02
		cristal.rotation.y = 0.7 * i
		if arte != null:
			cristal.material_override = arte.mat_vidrio()
		else:
			var mv := StandardMaterial3D.new()
			mv.vertex_color_use_as_albedo = true
			cristal.material_override = mv
		cristal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivote.add_child(cristal)
		vidrios.append(pivote)
	# El destello: el sol en el vidrio al sonar (se ve de lejos un instante; nada se queda encendido).
	destello = MeshInstance3D.new()
	destello.name = "DestelloHito"
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	destello.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = _bola()
	m.albedo_color = Color(0.85, 0.97, 1.0, 0.0)
	m.no_depth_test = false
	destello.material_override = m
	destello.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	destello.position = base + Vector3(-0.22, ALTO_LAJAS + 1.05, 0.15)
	destello.visible = false
	raiz.add_child(destello)


# ================================================================= lo que pregunta la región

# [id, sitio, radio, texto del botón], como mision.piezas().
func piezas() -> Array:
	return [["rin_hito", Vector3(HITO.x, 0, HITO.y), RADIO, BOTON]]


# true si el id era de aquí (la región no sigue buscando).
func accion(r: Node, id: String) -> bool:
	if id != "rin_hito":
		return false
	if visto():
		r._mostrar_aviso(TEXTOS["visto"], 2.4)
		return true
	_sonar(r, true)
	if not r.dialogo(load("res://zonas3d/mar_cristal/mision.gd").dialogo_mc(DIALOGO)):
		premio(r)                               # sin Dialogic (o ocupado): el efecto igual, para no atascar a nadie
	return true


func dialogo_terminado(r: Node, nombre: String) -> bool:
	if not nombre.begins_with(DIALOGO):
		return false
	premio(r)
	return true


# Una sola vez en la partida: primero el hito, luego las Pociones, y se guarda.
func premio(r: Node) -> void:
	if visto():
		return
	P().poner_hito(HITO_ID)
	load("res://inventario.gd").agregar_objeto("Poción", POCIONES)
	r._mostrar_aviso(TEXTOS["premio"], 2.8)
	var s = _sonido()
	if s != null and not s.definicion("tesoro").is_empty():
		s.efecto("tesoro")
	if r.has_method("en_banco") and r.en_banco():
		return
	r.guardar_posicion()
	P().guardar(r.scene_file_path)


# ================================================================= cada fotograma

# Los vidrios se mecen con el viento y, de vez en cuando, suenan y destellan si Kael está a tiro de oído.
func actualizar(delta: float, pos: Vector3, clima = null) -> void:
	_t += delta
	var viento: float = clima.viento() if clima != null else 0.25
	for i in vidrios.size():
		var v: Node3D = vidrios[i]
		v.rotation.z = (0.10 + 0.5 * viento) * sin(_t * (2.1 + 0.37 * i) + i * 1.3)
		v.rotation.x = 0.06 * sin(_t * (1.7 + 0.23 * i) + i)
	if _brillo > 0.0:
		_brillo = maxf(0.0, _brillo - delta * 2.2)
		var m := destello.material_override as StandardMaterial3D
		m.albedo_color.a = _brillo * 0.85
		destello.visible = _brillo > 0.0
	_t_son -= delta
	if _t_son > 0.0:
		return
	var tormenta: bool = clima != null and clima.en_tormenta()
	var d := Vector2(pos.x - HITO.x, pos.z - HITO.y).length()
	if d > (OIR_TORMENTA if tormenta else OIR):
		_t_son = 1.0
		return
	_sonar(region, tormenta)
	var cada: Array = CADA_TORMENTA if tormenta else CADA
	_t_son = _rng.randf_range(cada[0], cada[1])


func _sonar(_r: Node, fuerte: bool) -> void:
	tintineos += 1
	_brillo = 1.0
	var s = _sonido()
	if s != null and not s.definicion(SONIDO).is_empty():
		var p := pos_hito() + Vector3(0, ALTO_LAJAS + 1.1, 0)
		s.efecto(SONIDO, {"pos": p, "en_3d": SONIDO_3D, "tono": _rng.randf_range(1.18, 1.42),
			"db": 3.0 if fuerte else 0.0, "clave": "rin_hito_vidrio"})


# El autoload de sonido por su nodo (así el módulo compila también en las pruebas que lo cargan antes que los autoloads).
func _sonido():
	if region == null or not region.is_inside_tree():
		return null
	return region.get_node_or_null("/root/Sonido")


# ================================================================= formas

# Un prisma hexagonal con punta abajo (un trozo de vidrio colgando), en una malla pequeña.
static func _prisma(radio: float, alto: float, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(col)
	var arriba: Array = []
	var abajo: Array = []
	for i in 6:
		var a := TAU * i / 6.0
		arriba.append(Vector3(cos(a) * radio * 0.7, 0.0, sin(a) * radio * 0.7))
		abajo.append(Vector3(cos(a) * radio, -alto * 0.72, sin(a) * radio))
	var punta := Vector3(0, -alto, 0)
	var tapa := Vector3.ZERO
	for i in 6:
		var j := (i + 1) % 6
		_tri(st, tapa, arriba[j], arriba[i])
		_tri(st, arriba[i], arriba[j], abajo[j])
		_tri(st, arriba[i], abajo[j], abajo[i])
		_tri(st, abajo[i], abajo[j], punta)
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _bola() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 32
	t.height = 32
	return t
