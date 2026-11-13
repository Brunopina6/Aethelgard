extends "res://personajes/heroes_v2/heroe_v2_ayudante.gd"
# Nix (V12, PROTOTIPO APAGADO): su ayudante. Hereda del de los héroes v2 (reproducir, hablar con gestos distintos o
# ninguno, parpadeo, materiales con heroe_v2.gdshader sobre su atlas horneado y reflejo del ambiente en el cobre) y
# cambia la cara: «cara_nix» (atlas propio) con ojos y boca INDEPENDIENTES (el parpadeo solo cambia los ojos) y cejas
# por formas clave que se mueven con suavidad, como los v3 (heroe_v3_ayudante.gd), con la luz de la piel de los v2
# (nix_cara.gdshader). Las ocho expresiones del contrato: normal, cerrados, sonrisa, dolor, grito, sorpresa,
# entrecerrados y decidido.

const SHADER_CARA_NIX := "res://personajes/nix/nix_cara.gdshader"
# expresión -> pesos de las cejas (arriba, enfado, triste)
const CEJAS := {
	"normal": Vector3(0.0, 0.0, 0.0), "cerrados": Vector3(0.0, 0.0, 0.15), "sonrisa": Vector3(0.35, 0.0, 0.0),
	"dolor": Vector3(0.0, 0.35, 0.8), "grito": Vector3(0.0, 1.0, 0.0), "sorpresa": Vector3(1.0, 0.0, 0.0),
	"entrecerrados": Vector3(0.0, 0.0, 0.45), "decidido": Vector3(0.0, 0.6, 0.0),
}
# serena: parpadea despacio y a menudo no repite
const RITMO_NIX := {"cada": Vector2(3.0, 6.2), "doble": 0.06, "duracion": 1.25}

var mat_cara_nix: ShaderMaterial
var _cejas := Vector3.ZERO
var _cejas_meta := Vector3.ZERO
var _i_cejas := PackedInt32Array([-1, -1, -1])
var ojos_tile := 0
var boca_tile := 0


func preparar(h: Node3D, nombre: String) -> void:
	heroe = h
	nombre_heroe = nombre
	anim = h.get("anim")
	_azar.randomize()
	_ritmo = RITMO_NIX
	_t_parpadeo = _azar.randf_range(1.0, _ritmo["cada"].x + 1.0)
	var c = h.find_child("cara_nix", true, false)
	if c is MeshInstance3D:
		cara = c
		_preparar_cara()
	if mejorar_materiales:
		_materiales(h)
		_leer_entorno.call_deferred()


func _preparar_cara() -> void:
	var tex: Texture2D = null
	var m := cara.get_active_material(0)
	if m is BaseMaterial3D:
		tex = m.albedo_texture
	mat_cara_nix = ShaderMaterial.new()
	mat_cara_nix.shader = load(SHADER_CARA_NIX)
	mat_cara_nix.set_shader_parameter("atlas", tex)
	cara.material_override = mat_cara_nix
	cara.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3:
		_i_cejas[i] = cara.find_blend_shape_by_name(["ceja_arriba", "ceja_enfado", "ceja_triste"][i])
	_aplicar("normal")


func tiene_cara() -> bool:
	return cara != null


func _aplicar(nombre: String) -> void:
	var i := EXPRESIONES.find(nombre)
	if i < 0:
		i = 0
	if _parpadeo >= 0.0:
		ojos_tile = i
		if mat_cara_nix != null:
			mat_cara_nix.set_shader_parameter("ojos", i)
		return
	expresion = nombre
	ojos_tile = i
	boca_tile = i
	_cejas_meta = CEJAS.get(nombre, Vector3.ZERO)
	if mat_cara_nix != null:
		mat_cara_nix.set_shader_parameter("ojos", i)
		mat_cara_nix.set_shader_parameter("boca", i)


func _process(delta: float) -> void:
	super._process(delta)
	if cara == null:
		return
	if not _cejas.is_equal_approx(_cejas_meta):
		_cejas = _cejas.lerp(_cejas_meta, clampf(delta * 14.0, 0.0, 1.0))
		if _cejas.distance_to(_cejas_meta) < 0.01:
			_cejas = _cejas_meta
		for k in 3:
			if _i_cejas[k] >= 0:
				cara.set_blend_shape_value(_i_cejas[k], _cejas[k])


func cejas_actuales() -> Vector3:
	return _cejas
