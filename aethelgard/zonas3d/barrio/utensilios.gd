extends RefCounted
# DUEÑO: agente C. Los OBJETOS que se llevan en el barrio experimental (V12, 16/11): de qué hueso cuelgan y su malla.
# La malla es la de B: zonas3d/barrio/modelos/utensilios.glb (un nodo por utensilio con su PIVOTE en el punto de agarre:
# +Y arriba, −Z hacia delante; al pecho, el borde que toca el cuerpo; a una mano, el asa, la correa, el agujero de
# colgar o el medio) y su caja en utensilios.json. El GLB trae un material gris sin textura: aquí se le pone el suyo
# (el color de los vértices × utensilios_atlas.png, con luz en tiempo real como los vecinos chibi; un material para
# todos, compartido). Si falta el GLB (o un nodo), una CAJA DE RESERVA opaca de su color y tamaño, para que la rutina se
# vea y se pruebe igual. Las cachés las suelta soltar_caches().
#
#   U.crear(obj)          una copia con el pivote en el origen
#   U.en_mano(obj)        dónde va el pivote respecto al punto de agarre del hueso ([Basis, desplazamiento])
#   U.sobre_base(obj)     lo que hay que sumar a la posición de un sitio para que el objeto quede APOYADO y centrado

const RUTA := "res://zonas3d/barrio/modelos/utensilios.glb"
const RUTA_CAJAS := "res://zonas3d/barrio/modelos/utensilios.json"
const RUTA_ATLAS := "res://zonas3d/barrio/modelos/utensilios_atlas.png"
const NOMBRES := ["bandeja", "cesta_pan", "caja", "saco_harina", "cepillo", "cubo", "galga", "pasador", "pasador_roto"]
# Lo que se lleva con las dos manos va al pecho; lo demás, a la mano derecha.
const AGARRE := {"bandeja": "pecho", "cesta_pan": "pecho", "caja": "pecho", "saco_harina": "pecho", "cepillo": "mano.R",
	"cubo": "mano.R", "galga": "mano.R", "pasador": "mano.R", "pasador_roto": "mano.R"}
# La cesta se lleva al pecho por el asa (cuelga debajo del agarre): en el GLB su pivote es el asa.
# Reserva: [tamaño (m), color, alto del pivote sobre la base]. Opacos (nada transparente en bajo y medio).
const RESERVA := {
	"bandeja": [Vector3(0.50, 0.06, 0.34), Color(0.62, 0.42, 0.22)],
	"cesta_pan": [Vector3(0.40, 0.22, 0.30), Color(0.78, 0.58, 0.30)],
	"caja": [Vector3(0.46, 0.34, 0.36), Color(0.56, 0.40, 0.24)],
	"saco_harina": [Vector3(0.36, 0.46, 0.26), Color(0.90, 0.86, 0.76)],
	"cepillo": [Vector3(0.08, 0.06, 0.20), Color(0.40, 0.26, 0.16)],
	"cubo": [Vector3(0.24, 0.26, 0.24), Color(0.46, 0.44, 0.42)],
	"galga": [Vector3(0.04, 0.02, 0.22), Color(0.80, 0.66, 0.42)],
	"pasador": [Vector3(0.05, 0.05, 0.24), Color(0.86, 0.74, 0.52)],
	"pasador_roto": [Vector3(0.05, 0.05, 0.12), Color(0.46, 0.36, 0.26)],
}
# Lo que asoma de dentro (panes en la bandeja y la cesta, agua en el cubo): una segunda caja, también opaca.
const ENCIMA := {"bandeja": [Vector3(0.40, 0.08, 0.24), Color(0.90, 0.66, 0.34)],
	"cesta_pan": [Vector3(0.32, 0.08, 0.22), Color(0.92, 0.70, 0.38)],
	"cubo": [Vector3(0.20, 0.02, 0.20), Color(0.30, 0.48, 0.62)]}

static var _escena: PackedScene = null
static var _probada := false
static var _cajas_glb := {}                    # obj → [min, max] (utensilios.json)
static var _material_glb: StandardMaterial3D = null
static var _materiales := {}
static var _cajas := {}


static func agarre(obj: String) -> String:
	return AGARRE.get(obj, "mano.R")


# ¿Viene del GLB de B? (si no, es la caja de reserva)
static func del_modelo(obj: String) -> bool:
	var n := _nodo_glb(obj)
	if n == null:
		return false
	n.free()
	return true


static func _cargar() -> void:
	if _probada:
		return
	_probada = true
	if ResourceLoader.exists(RUTA):
		_escena = load(RUTA)
	if FileAccess.file_exists(RUTA_CAJAS):
		var d = JSON.parse_string(FileAccess.get_file_as_string(RUTA_CAJAS))
		if d is Dictionary:
			for o in d:
				var a: Array = d[o].get("min", [])
				var b: Array = d[o].get("max", [])
				if a.size() == 3 and b.size() == 3:
					_cajas_glb[o] = [Vector3(a[0], a[1], a[2]), Vector3(b[0], b[1], b[2])]


static func _nodo_glb(obj: String) -> Node3D:
	_cargar()
	if _escena == null:
		return null
	var raiz := _escena.instantiate()
	var n := raiz.find_child(obj, true, false) as Node3D
	if n == null:
		raiz.free()
		return null
	n.get_parent().remove_child(n)
	n.owner = null
	raiz.free()
	n.transform = Transform3D.IDENTITY
	return n


# El material de los utensilios del GLB: color del vértice × atlas, con luz en tiempo real (como los vecinos).
static func material_glb() -> StandardMaterial3D:
	if _material_glb == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = load(RUTA_ATLAS) if ResourceLoader.exists(RUTA_ATLAS) else null
		m.roughness = 0.85
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_material_glb = m
	return _material_glb


# Una copia del utensilio (su pivote en el origen). Del GLB, con su material; si no, la caja de reserva (base en y = 0).
static func crear(obj: String) -> Node3D:
	var g := _nodo_glb(obj)
	if g != null:
		g.name = "U_" + obj
		for mi in ([g] + g.find_children("*", "MeshInstance3D", true, false)):
			if mi is MeshInstance3D:
				(mi as MeshInstance3D).material_override = material_glb()
				(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return g
	var raiz := Node3D.new()
	raiz.name = "U_" + obj
	var r: Array = RESERVA.get(obj, [Vector3(0.2, 0.2, 0.2), Color(0.6, 0.6, 0.6)])
	raiz.add_child(_caja(obj, r[0], r[1], 0.0))
	if ENCIMA.has(obj):
		var e: Array = ENCIMA[obj]
		raiz.add_child(_caja(obj + "_encima", e[0], e[1], (r[0] as Vector3).y - (e[0] as Vector3).y * 0.5))
	return raiz


# La caja del utensilio del GLB respecto a su pivote ([min, max]); [] si es de reserva.
static func caja(obj: String) -> Array:
	_cargar()
	if _escena == null:
		return []
	return _cajas_glb.get(obj, [])


# Para dejarlo en un sitio: lo que se suma a la posición del sitio (la superficie) para que la base del objeto quede
# apoyada en ella y centrada (el pivote del GLB es el agarre, no el centro de la base). La reserva ya está así.
static func sobre_base(obj: String) -> Vector3:
	var c := caja(obj)
	if c.is_empty() or not del_modelo_cache(obj):
		return Vector3.ZERO
	var a: Vector3 = c[0]
	var b: Vector3 = c[1]
	return Vector3(-(a.x + b.x) * 0.5, -a.y, -(a.z + b.z) * 0.5)


# En la mano o al pecho: [giro, desplazamiento desde el punto de agarre del hueso]. El GLB mira a −Z y el vecino a +Z:
# se gira media vuelta para que lo de delante del utensilio quede delante del vecino. Al pecho, el borde del cuerpo
# en el agarre; la reserva, centrada delante.
static func en_mano(obj: String) -> Array:
	if del_modelo_cache(obj):
		return [Basis(Vector3.UP, PI), Vector3.ZERO]
	var r: Array = RESERVA.get(obj, [Vector3(0.2, 0.2, 0.2)])
	if agarre(obj) == "pecho":
		return [Basis.IDENTITY, Vector3(0, -(r[0] as Vector3).y * 0.5, (r[0] as Vector3).z * 0.5)]
	return [Basis.IDENTITY, Vector3(0, -(r[0] as Vector3).y, 0)]


static var _del_modelo := {}


static func del_modelo_cache(obj: String) -> bool:
	if not _del_modelo.has(obj):
		_del_modelo[obj] = del_modelo(obj)
	return _del_modelo[obj]


static func _caja(clave: String, tam: Vector3, color: Color, base: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if not _cajas.has(clave):
		var b := BoxMesh.new()
		b.size = tam
		_cajas[clave] = b
	mi.mesh = _cajas[clave]
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_materiales[clave] = m
	mi.material_override = _materiales[clave]
	mi.position.y = base + tam.y * 0.5
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func soltar_caches() -> void:
	_escena = null
	_probada = false
	_cajas_glb.clear()
	_material_glb = null
	_del_modelo.clear()
	_materiales.clear()
	_cajas.clear()
