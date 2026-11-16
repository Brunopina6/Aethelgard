extends RefCounted
# DUEÑO: agente C. Los OBJETOS que se llevan en el barrio experimental (V12, 16/11): de qué hueso cuelgan y su malla.
# La malla buena la entrega B en zonas3d/barrio/modelos/utensilios.glb (un nodo por utensilio, con su pivote en el punto
# de agarre: plan §11). Mientras no exista (o le falte uno), una CAJA DE RESERVA opaca de su color y tamaño, para que
# la rutina se vea y se pruebe igual. Un material por utensilio, compartido (y soltado en soltar_caches()).

const RUTA := "res://zonas3d/barrio/modelos/utensilios.glb"
const NOMBRES := ["bandeja", "cesta_pan", "caja", "saco_harina", "cepillo", "cubo", "galga", "pasador", "pasador_roto"]
# Lo que se lleva con las dos manos va al pecho; lo demás, a la mano derecha.
const AGARRE := {"bandeja": "pecho", "cesta_pan": "pecho", "caja": "pecho", "saco_harina": "pecho", "cepillo": "mano.R",
	"cubo": "mano.R", "galga": "mano.R", "pasador": "mano.R", "pasador_roto": "mano.R"}
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
static var _materiales := {}
static var _cajas := {}


static func agarre(obj: String) -> String:
	return AGARRE.get(obj, "mano.R")


# ¿Viene del GLB de B? (si no, es la caja de reserva)
static func del_modelo(obj: String) -> bool:
	return _nodo_glb(obj) != null


static func _nodo_glb(obj: String) -> Node3D:
	if not _probada:
		_probada = true
		if ResourceLoader.exists(RUTA):
			_escena = load(RUTA)
	if _escena == null:
		return null
	var raiz := _escena.instantiate()
	var n := raiz.find_child(obj, true, false) as Node3D
	if n == null:
		raiz.free()
		return null
	n.get_parent().remove_child(n)
	raiz.free()
	n.transform = Transform3D.IDENTITY
	return n


# Una copia del utensilio (su pivote, el punto de agarre, en el origen; la base del objeto apoyada en y = 0).
static func crear(obj: String) -> Node3D:
	var g := _nodo_glb(obj)
	if g != null:
		g.name = "U_" + obj
		return g
	var raiz := Node3D.new()
	raiz.name = "U_" + obj
	var r: Array = RESERVA.get(obj, [Vector3(0.2, 0.2, 0.2), Color(0.6, 0.6, 0.6)])
	raiz.add_child(_caja(obj, r[0], r[1], 0.0))
	if ENCIMA.has(obj):
		var e: Array = ENCIMA[obj]
		raiz.add_child(_caja(obj + "_encima", e[0], e[1], (r[0] as Vector3).y - (e[0] as Vector3).y * 0.5))
	return raiz


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
	_materiales.clear()
	_cajas.clear()
