extends Node3D
# La sombra de Lya que se desprende y viaja por el suelo hasta el enemigo (y vuelve).
# Es un plano pegado al suelo con un shader: empieza con la silueta de una persona (cabeza y cuerpo)
# y se va deformando en una mancha ondulante mientras avanza, dejando un rastro de humo morado.
# No toca la geometría del suelo ni las sombras de los demás.
#
# Uso:
#   var s = load("res://sombra_invocacion.gd").new(); add_child(s)
#   await s.viajar(pies_de_lya, delante_del_enemigo, 1.6)    # ida (se deforma)
#   await s.viajar(delante_del_enemigo, pies_de_lya, 1.2, true)  # vuelta (recupera la silueta)

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float deforma = 0.0;   // 0 = silueta de persona, 1 = mancha
uniform float opacidad = 0.85;
uniform vec4 color : source_color = vec4(0.04, 0.02, 0.07, 1.0);
uniform vec4 borde : source_color = vec4(0.42, 0.29, 0.55, 1.0);
float capsula(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;        // y: de los pies (-1) a la cabeza (+1)
	// silueta tumbada en el suelo: cuerpo, cabeza y brazos
	float cuerpo = capsula(p, vec2(0.0, -0.75), vec2(0.0, 0.25), 0.2);
	float cabeza = length(p - vec2(0.0, 0.55)) - 0.2;
	float brazos = capsula(p, vec2(-0.38, -0.05), vec2(0.38, -0.05), 0.08);
	float persona = min(min(cuerpo, cabeza), brazos);
	// mancha que ondula
	float ang = atan(p.y, p.x);
	float mancha = length(p * vec2(1.0, 0.75)) - 0.55 - 0.08 * sin(ang * 5.0 + TIME * 5.0) - 0.05 * sin(ang * 11.0 - TIME * 7.0);
	// bordes líquidos: ruido que fluye, más fuerte cuanto más deformada
	vec2 fl = p * 4.0 + vec2(TIME * 0.7, -TIME * 1.1);
	float liquido = (ruido(fl) - 0.5) * 0.16 + (ruido(fl * 2.3 - TIME) - 0.5) * 0.08;
	float d = mix(persona, mancha, deforma) + liquido * (0.35 + 0.65 * deforma);
	float a = 1.0 - smoothstep(-0.05, 0.05, d);
	// distorsión sutil dentro: vetas que ondulan
	float vetas = 0.5 + 0.5 * sin((p.y + liquido * 2.0) * 18.0 - TIME * 6.0);
	float aro = (1.0 - smoothstep(0.0, 0.07, abs(d + 0.035))) * (0.4 + 0.6 * deforma);
	ALBEDO = mix(color.rgb + borde.rgb * vetas * 0.12 * deforma, borde.rgb, aro);
	ALPHA = a * opacidad * (0.85 + 0.15 * vetas);
}
"""

var plano: MeshInstance3D
var mat: ShaderMaterial
var rastro: CPUParticles3D
var largo := 1.5


func _ready() -> void:
	plano = MeshInstance3D.new()
	var m := PlaneMesh.new()
	m.size = Vector2(1.0, 1.0)
	plano.mesh = m
	mat = ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER
	plano.material_override = mat
	plano.position.y = 0.012
	add_child(plano)
	rastro = CPUParticles3D.new()
	rastro.amount = 36
	rastro.lifetime = 1.0
	rastro.preprocess = 1.0
	rastro.local_coords = false
	rastro.emitting = false
	rastro.direction = Vector3.UP
	rastro.spread = 30.0
	rastro.initial_velocity_min = 0.1
	rastro.initial_velocity_max = 0.35
	rastro.gravity = Vector3(0, 0.3, 0)
	rastro.scale_amount_min = 0.2
	rastro.scale_amount_max = 0.45
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0.42, 0.29, 0.55, 0.5), Color(0.23, 0.14, 0.27, 0.0)])
	rastro.color_ramp = g
	var q := QuadMesh.new()
	var qm := StandardMaterial3D.new()
	var gt := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	gt.gradient = gg
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	qm.albedo_texture = gt
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	rastro.mesh = q
	add_child(rastro)
	visible = false


# Se coloca tumbada en "desde" con la cabeza hacia "hasta" y viaja hasta allí.
# vuelta = true: hace el camino al revés (de mancha a silueta).
func viajar(desde: Vector3, hasta: Vector3, dur: float, vuelta := false) -> void:
	visible = true
	var dir := (hasta - desde)
	dir.y = 0.0
	var ang := atan2(dir.x, dir.z)
	plano.rotation = Vector3(0, ang, 0)
	plano.scale = Vector3(largo * 0.55, 1, largo)
	global_position = desde
	rastro.visible = true
	rastro.emitting = true
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "global_position", hasta, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if vuelta:
		t.tween_method(func(v): mat.set_shader_parameter("deforma", v), 1.0, 0.0, dur)
	else:
		t.tween_method(func(v): mat.set_shader_parameter("deforma", v), 0.0, 1.0, dur * 0.6)
		t.tween_property(plano, "scale", Vector3(largo * 0.7, 1, largo * 0.8), dur)
	await t.finished
	rastro.emitting = false
	get_tree().create_timer(1.0).timeout.connect(func(): rastro.visible = false)


func limpiar() -> void:
	rastro.emitting = false
	rastro.visible = false
	mat.set_shader_parameter("opacidad", 0.85)
	mat.set_shader_parameter("deforma", 0.0)
	visible = false


func ocultar(dur := 0.25) -> void:
	var t := create_tween()
	t.tween_method(func(v): mat.set_shader_parameter("opacidad", v), 0.85, 0.0, dur)
	await t.finished
	visible = false
	mat.set_shader_parameter("opacidad", 0.85)
