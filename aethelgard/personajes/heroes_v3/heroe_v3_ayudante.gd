extends "res://personajes/heroes_v2/heroe_v2_ayudante.gd"
# Héroes v3 (V12): lo común a Kael, Lya y Garon v3. Hereda la API del ayudante de los v2 (reproducir, hablar,
# poner_expresion, parpadeo con el ritmo de cada uno, reflejo del ambiente en el metal) y cambia:
#   - la cara: «cara_v3» (geometría y atlas propios, cara_v3.py) con ojos y boca INDEPENDIENTES (el parpadeo solo
#     cambia los ojos) y cejas por formas clave que se mueven con suavidad (no saltan de una pose a otra);
#   - los materiales: heroe_v3.gdshader (color por vértice y luz pintada) con contorno (heroe_v3_borde.gdshader).
# Expresiones (las mismas ocho del contrato v2): normal (neutro), decidido, sonrisa (alegre), dolor, sorpresa,
# entrecerrados (cansado), cerrados y grito.

const SHADER_V3 := "res://personajes/heroes_v3/heroe_v3.gdshader"
const SHADER_BORDE := "res://personajes/heroes_v3/heroe_v3_borde.gdshader"
const SHADER_CARA := "res://personajes/heroes_v3/heroe_v3_cara.gdshader"
const DETALLE := "res://personajes/heroes_v3/heroe_v3_detalle.png"
# expresión -> pesos de las cejas (arriba, enfado, triste)
const CEJAS := {
	"normal": Vector3(0.0, 0.0, 0.0), "cerrados": Vector3(0.0, 0.0, 0.15), "sonrisa": Vector3(0.45, 0.0, 0.0),
	"dolor": Vector3(0.0, 0.35, 0.8), "grito": Vector3(0.0, 1.0, 0.0), "sorpresa": Vector3(1.0, 0.0, 0.0),
	"entrecerrados": Vector3(0.0, 0.0, 0.55), "decidido": Vector3(0.0, 0.55, 0.0),
}
# Ajustes de luz y contorno por héroe (heroe_v3_luz.gdshaderinc)
const LUZ := {
	"Kael": {"borde_luz": 0.30, "brillo_pelo": 0.30, "color_brillo_pelo": Color(0.50, 0.65, 1.0), "reflejo": 0.55},
	"Lya": {"borde_luz": 0.32, "brillo_pelo": 0.40, "color_brillo_pelo": Color(1.0, 0.95, 0.75), "reflejo": 0.45},
	"Garon": {"borde_luz": 0.25, "brillo_pelo": 0.25, "color_brillo_pelo": Color(1.0, 0.6, 0.55), "reflejo": 0.85},
}

# Luz propia de los ojos: Garon los lleva en la sombra de la visera (dos brillos que cambian con la expresión)
const BRILLO_OJOS := {"Kael": 0.18, "Lya": 0.18, "Garon": 1.2}

var mat_cara_v3: ShaderMaterial
var borde: ShaderMaterial
var _cejas := Vector3.ZERO           # pesos actuales
var _cejas_meta := Vector3.ZERO      # pesos a los que van
var _i_cejas := PackedInt32Array([-1, -1, -1])
var ojos_tile := 0
var boca_tile := 0


func preparar(h: Node3D, nombre: String) -> void:
	heroe = h
	nombre_heroe = nombre
	anim = h.get("anim")
	_azar.randomize()
	_ritmo = PARPADEO.get(nombre, _ritmo)
	_t_parpadeo = _azar.randf_range(1.0, _ritmo["cada"].x + 1.0)
	var c = h.find_child("cara_v3", true, false)
	if c is MeshInstance3D:
		cara = c
		_preparar_cara()
	if mejorar_materiales:
		_materiales(h)
		_leer_entorno.call_deferred()


func _preparar_cara() -> void:
	var tex: Texture2D = null
	var m := cara.mesh.surface_get_material(0)
	if m is BaseMaterial3D:
		tex = m.albedo_texture
	mat_cara_v3 = ShaderMaterial.new()
	mat_cara_v3.shader = load(SHADER_CARA)
	mat_cara_v3.set_shader_parameter("atlas", tex)
	for k in LUZ.get(nombre_heroe, {}):
		if k != "reflejo":
			mat_cara_v3.set_shader_parameter(k, LUZ[nombre_heroe][k])
	mat_cara_v3.set_shader_parameter("brillo_ojos", BRILLO_OJOS.get(nombre_heroe, 0.18))
	cara.material_override = mat_cara_v3
	cara.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3:
		_i_cejas[i] = cara.find_blend_shape_by_name(["ceja_arriba", "ceja_enfado", "ceja_triste"][i])
	_aplicar("normal")


# Ojos y boca por separado: durante un parpadeo solo cambian los ojos (la boca y las cejas siguen con la expresión).
func _aplicar(nombre: String) -> void:
	var i := EXPRESIONES.find(nombre)
	if i < 0:
		i = 0
	if _parpadeo >= 0.0:
		ojos_tile = i
		if mat_cara_v3 != null:
			mat_cara_v3.set_shader_parameter("ojos", i)
		return
	expresion = nombre
	ojos_tile = i
	boca_tile = i
	_cejas_meta = CEJAS.get(nombre, Vector3.ZERO)
	if mat_cara_v3 != null:
		mat_cara_v3.set_shader_parameter("ojos", i)
		mat_cara_v3.set_shader_parameter("boca", i)


func _process(delta: float) -> void:
	super._process(delta)
	if cara == null:
		return
	# las cejas van a su sitio en ~0,12 s (sin saltos)
	if not _cejas.is_equal_approx(_cejas_meta):
		_cejas = _cejas.lerp(_cejas_meta, clampf(delta * 14.0, 0.0, 1.0))
		if _cejas.distance_to(_cejas_meta) < 0.01:
			_cejas = _cejas_meta
		for k in 3:
			if _i_cejas[k] >= 0:
				cara.set_blend_shape_value(_i_cejas[k], _cejas[k])


func cejas_actuales() -> Vector3:
	return _cejas


# ---------------------------------------------------------------- materiales
func _materiales(n: Node) -> void:
	var sh: Shader = load(SHADER_V3)
	var ajuste: Dictionary = LUZ.get(nombre_heroe, {})
	borde = ShaderMaterial.new()
	borde.shader = load(SHADER_BORDE)
	var det: Texture2D = load(DETALLE) if ResourceLoader.exists(DETALLE) else null
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi == cara or not mi.get_parent() is Skeleton3D:
			continue
		for s in mi.mesh.get_surface_count():
			var sm := ShaderMaterial.new()
			sm.shader = sh
			sm.set_shader_parameter("detalle", det)
			for k in ajuste:
				sm.set_shader_parameter(k, ajuste[k])
			sm.next_pass = borde
			mi.set_surface_override_material(s, sm)
			materiales.append(sm)
