extends RefCounted
# CIUDAD DE OAKHAVEN (V12, 16/11, M0; EXPERIMENTAL): la geometría del BLOCKOUT (cajas con el color en los vértices),
# común al sector montado (sector.gd) y a la maqueta lejana (cargador.gd). Sale SOLO de los trazados: si cambia una cota,
# cambia todo a la vez. Los colores son los del barrio.

const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")

const COLOR_SUELO := {"puerta_sur": Color(0.62, 0.55, 0.42), "plaza_tapiz": Color(0.72, 0.68, 0.60),
	"oficios": Color(0.60, 0.54, 0.46), "terrazas": Color(0.64, 0.60, 0.52), "pasajes": Color(0.56, 0.54, 0.50),
	"cuervo": Color(0.66, 0.62, 0.56), "barrio_alto": Color(0.62, 0.64, 0.52), "ribera": Color(0.58, 0.56, 0.50)}
const COLOR_TIPO := {"casa": Color(0.86, 0.80, 0.68), "muro": Color(0.62, 0.60, 0.56), "bajo": Color(0.55, 0.45, 0.32),
	"puerta": Color(0.86, 0.52, 0.18), "decor": Color(0.78, 0.66, 0.36), "terreno": Color(0.50, 0.52, 0.38),
	"arbol": Color(0.42, 0.30, 0.20), "cubierta": Color(0.66, 0.40, 0.30), "copa": Color(0.36, 0.52, 0.30)}
const COLOR_TEJADO := Color(0.58, 0.30, 0.24)
const COLOR_FONDO := Color(0.50, 0.50, 0.40)
const FONDO_SUELO := -3.0                  # los suelos se dibujan como prismas hasta esta cota (sin huecos debajo)
const SOLAPE_SUELO := 0.05                 # (del barrio) las losas se solapan con las vecinas en el choque

static var _mat_opaco: StandardMaterial3D
static var _mat_claro: StandardMaterial3D


# Los materiales compartidos: el del blockout y su copia medio transparente (para lo que tapa a Kael).
static func material(claro := false) -> StandardMaterial3D:
	if _mat_opaco == null:
		_mat_opaco = StandardMaterial3D.new()
		_mat_opaco.vertex_color_use_as_albedo = true
		_mat_opaco.roughness = 1.0
		_mat_claro = _mat_opaco.duplicate()
		_mat_claro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_claro.albedo_color = Color(1, 1, 1, 0.28)
	return _mat_claro if claro else _mat_opaco


static func soltar() -> void:
	_mat_opaco = null
	_mat_claro = null


static func nueva() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


# Un cuadrilátero plano a-b-c-d con su normal hacia «fuera» (la del producto vectorial, girada hacia «fuera»). Godot dibuja
# de frente los triángulos en el sentido de las agujas del reloj vistos desde fuera: se ordenan aquí, sea cual sea el
# orden en que lleguen las esquinas.
static func _cara(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, fuera: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	var orden := [a, c, b, a, d, c]                 # (a-b-c en sentido contrario al reloj visto desde fuera)
	if n.dot(fuera) < 0.0:
		n = -n
		orden = [a, b, c, a, c, d]
	for v in orden:
		st.set_color(color)
		st.set_normal(n)
		st.add_vertex(v)


# Una caja alineada con los ejes.
static func caja(st: SurfaceTool, c: AABB, color: Color) -> void:
	var p := c.position
	var e := c.end
	var v := [Vector3(p.x, p.y, p.z), Vector3(e.x, p.y, p.z), Vector3(e.x, p.y, e.z), Vector3(p.x, p.y, e.z),
		Vector3(p.x, e.y, p.z), Vector3(e.x, e.y, p.z), Vector3(e.x, e.y, e.z), Vector3(p.x, e.y, e.z)]
	_cara(st, v[4], v[5], v[6], v[7], color, Vector3.UP)
	_cara(st, v[3], v[2], v[1], v[0], color, Vector3.DOWN)
	_cara(st, v[0], v[1], v[5], v[4], color, Vector3.FORWARD)      # norte (z mínima)
	_cara(st, v[2], v[3], v[7], v[6], color, Vector3.BACK)         # sur
	_cara(st, v[3], v[0], v[4], v[7], color, Vector3.LEFT)         # oeste
	_cara(st, v[1], v[2], v[6], v[5], color, Vector3.RIGHT)        # este


# Las 8 esquinas del prisma de un suelo: la tapa a la cota exacta (rampas incluidas) y el fondo en FONDO_SUELO.
# «crece»: metros de más por cada lado (la tapa sigue la misma pendiente).
static func esquinas_suelo(s: Array, crece := 0.0) -> Array:
	var r: Rect2 = (s[1] as Rect2).grow(crece)
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	var y := func(x: float, z: float) -> float:
		var ro: Rect2 = s[1]
		match String(s[2]):
			"x":
				return lerpf(s[3], s[4], (x - ro.position.x) / ro.size.x)
			"z":
				return lerpf(s[3], s[4], (z - ro.position.y) / ro.size.y)
		return float(s[3])
	var fondo := minf(FONDO_SUELO, minf(float(s[3]), float(s[4])) - 1.0)
	return [Vector3(x0, y.call(x0, z0), z0), Vector3(x1, y.call(x1, z0), z0), Vector3(x1, y.call(x1, z1), z1),
		Vector3(x0, y.call(x0, z1), z1), Vector3(x0, fondo, z0), Vector3(x1, fondo, z0), Vector3(x1, fondo, z1),
		Vector3(x0, fondo, z1)]


static func suelo(st: SurfaceTool, s: Array, color: Color) -> void:
	var v := esquinas_suelo(s)
	_cara(st, v[0], v[1], v[2], v[3], color, Vector3.UP)           # tapa
	var lado := color.darkened(0.25)
	_cara(st, v[4], v[5], v[1], v[0], lado, Vector3.FORWARD)       # norte
	_cara(st, v[6], v[7], v[3], v[2], lado, Vector3.BACK)          # sur
	_cara(st, v[7], v[4], v[0], v[3], lado, Vector3.LEFT)          # oeste
	_cara(st, v[5], v[6], v[2], v[1], lado, Vector3.RIGHT)         # este


# Un bloque: su cuerpo y, si es casa, el tejado de otro color (cajas de trazado_comun.cajas_bloque).
static func bloque(st: SurfaceTool, b: Array) -> void:
	var cajas := Comun.cajas_bloque(b)
	caja(st, cajas[0], COLOR_TIPO.get(String(b[5]), COLOR_FONDO))
	if cajas.size() > 1:
		caja(st, cajas[1], COLOR_TEJADO)


static func malla(st: SurfaceTool, nombre: String, claro := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = st.commit()
	mi.material_override = material(claro)
	return mi
