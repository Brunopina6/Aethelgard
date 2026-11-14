extends Node3D
# V12 (14/11), EXPERIMENTAL y APAGADO por defecto: el efecto nativo del orbe de Érebo, traído del laboratorio
# (D:\REBELUM_laboratorio_plugins\laboratorio\proto_a_pixelpart\proyecto\efecto_nativo.gd, partículas propias, sin
# complementos). En el instante en que Érebo AGARRA el orbe (su evento de animación «orbe_fuera», que emiten las dos
# invocaciones, la de siempre y la nueva), la energía violeta, negra y plateada gira en espiral y se absorbe en el orbe;
# al llegar, el orbe responde con una onda mágica y una ráfaga plateada. Dura ≈1,1 s y se borra solo.
#
# - Solo se ve con la opción «Érebo: orbe experimental» (Ajustes, SOLO en la APK de Auditoría o en el editor; clave
#   [calidad_pruebas] erebo_orbe_v12 de user://ajustes.cfg) o, en pruebas, con el argumento «erebo_orbe».
#   Con «erebo_orbe_no», o sin la opción, la invocación es exactamente la de siempre.
# - No toca daño, costes, dados ni tiempos: solo presentación. No cambia el material del orbe.
# - Limpieza: se quita al estallar el orbe, al cancelar/saltar (erebo_3d.limpiar), si el orbe deja de verse y al salir
#   del árbol (morir, cambiar de escena); cada invocación quita el anterior antes de crear uno (nunca se acumulan).
# - Presupuesto (como en el laboratorio): 96 partículas en «alta», la mitad en «movil», UN quad para la onda.
#   Con «reducir destellos» no hay onda ni ráfaga, solo la espiral.

const CLAVE := "erebo_orbe_v12"
const DURACION := 1.1        # la espiral sigue emitiendo este tiempo tras el agarre
const T_ONDA := 0.5          # la onda cuando el orbe ya ha crecido (erebo_3d: _radio en 0,5 s)
const F := 0.37              # escala del laboratorio (anillo de 0,95 m) a la mano de Érebo

const VIOLETA := Color(0.62, 0.25, 0.95)
const VIOLETA_CLARO := Color(0.85, 0.6, 1.0)
const NEGRO := Color(0.05, 0.02, 0.08)
const PLATA := Color(0.88, 0.9, 1.0)

const SHADER_ONDA := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float avance = 0.0;
uniform vec4 color : source_color = vec4(0.7, 0.4, 1.0, 1.0);
uniform vec4 color_borde : source_color = vec4(0.9, 0.92, 1.0, 1.0);
void vertex() {
	mat4 m = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	m = m * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float radio = mix(0.15, 0.92, sqrt(avance));
	float ondula = 0.012 * sin(ang * 5.0 + avance * 9.0) + 0.006 * sin(ang * 13.0 - avance * 17.0);
	float d = abs(r - radio - ondula);
	float grosor = mix(0.12, 0.025, avance);
	float aro = 1.0 - smoothstep(0.0, grosor, d);
	float filo = 1.0 - smoothstep(0.0, grosor * 0.3, d);
	float interior = (1.0 - smoothstep(0.0, radio, r)) * 0.25 * (1.0 - avance);
	float apaga = 1.0 - smoothstep(0.55, 1.0, avance);
	ALBEDO = (color.rgb * (aro + interior) + color_borde.rgb * filo * 0.8) * apaga;
	ALPHA = 1.0;
	if (r > 1.0) { discard; }
}
"""

var calidad := "alta"
var reducir_destellos := false
var orbe: Node3D                     # el orbe de la mano de Érebo (erebo_3d.orbe)
var emisores: Array[CPUParticles3D] = []
var _espirales: Array[CPUParticles3D] = []
var _rafaga: CPUParticles3D
var _onda: MeshInstance3D
var _mat_onda: ShaderMaterial
var _t := 0.0
var _onda_hecha := false
var _apagando := false
var _vida_max := 0.0


# ---------------------------------------------------------------- opción (Auditoría / editor / pruebas)

static func permitido() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor")


static func activo() -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "erebo_orbe":
			return true
		if a == "erebo_orbe_no":
			return false
	if not permitido():
		return false
	var c := ConfigFile.new()
	return c.load("user://ajustes.cfg") == OK and bool(c.get_value("calidad_pruebas", CLAVE, false))


static func elegir(si: bool) -> Error:
	if not permitido():
		return ERR_UNAUTHORIZED
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("calidad_pruebas", CLAVE, si)
	return c.save("user://ajustes.cfg")


# ---------------------------------------------------------------- el efecto

func _cant(n: int) -> int:
	return n if calidad == "alta" else maxi(4, n / 2)


func _ready() -> void:
	var brillo := _textura_radial([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)], [0.0, 0.35, 1.0])
	var estrella := _textura_estrella(64)
	var violeta := _espiral(_cant(40), 1.5 * 0.6, brillo, 0.11 * F, true)
	violeta.color_ramp = _rampa([Color(VIOLETA, 0.0), Color(VIOLETA, 0.9), Color(VIOLETA_CLARO, 1.0), Color(VIOLETA_CLARO, 0.0)], [0.0, 0.25, 0.85, 1.0])
	var negra := _espiral(_cant(16), 1.8 * 0.6, brillo, 0.32 * F, false)
	negra.color_ramp = _rampa([Color(NEGRO, 0.0), Color(NEGRO, 0.95), Color(NEGRO, 0.8), Color(NEGRO, 0.0)], [0.0, 0.3, 0.8, 1.0])
	negra.tangential_accel_min = 2.0 * F / 0.6
	negra.tangential_accel_max = 3.0 * F / 0.6
	var plata := _espiral(_cant(28), 1.1 * 0.6, estrella, 0.09 * F, true)
	plata.color_ramp = _rampa([Color(PLATA, 0.0), Color(PLATA, 1.0), Color(PLATA, 1.0), Color(PLATA, 0.0)], [0.0, 0.15, 0.8, 1.0])
	plata.tangential_accel_min = 5.0 * F / 0.6
	plata.tangential_accel_max = 7.0 * F / 0.6
	plata.radial_accel_min = -5.0 * F / 0.36
	plata.radial_accel_max = -3.5 * F / 0.36
	if not reducir_destellos:
		_rafaga = _particulas(_cant(12), 0.6, estrella, 0.1 * F, true)
		_rafaga.one_shot = true
		_rafaga.explosiveness = 1.0
		_rafaga.preprocess = 0.0
		_rafaga.emitting = false
		_rafaga.direction = Vector3.UP
		_rafaga.spread = 180.0
		_rafaga.initial_velocity_min = 1.2 * F
		_rafaga.initial_velocity_max = 2.4 * F
		_rafaga.damping_min = 2.5 * F
		_rafaga.damping_max = 3.5 * F
		_rafaga.gravity = Vector3.ZERO
		_rafaga.color_ramp = _rampa([PLATA, VIOLETA_CLARO, Color(VIOLETA, 0.0)], [0.0, 0.5, 1.0])
		add_child(_rafaga)
		emisores.append(_rafaga)
		_onda = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE * 1.8 * F
		_onda.mesh = q
		_mat_onda = ShaderMaterial.new()
		_mat_onda.shader = Shader.new()
		_mat_onda.shader.code = SHADER_ONDA
		_mat_onda.set_shader_parameter("color", Color(0.55, 0.25, 0.95))
		_mat_onda.set_shader_parameter("color_borde", PLATA)
		_mat_onda.set_shader_parameter("avance", 1.0)
		_onda.material_override = _mat_onda
		_onda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_onda.visible = false
		add_child(_onda)
	for e in emisores:
		_vida_max = maxf(_vida_max, e.lifetime)
	_seguir_orbe()


func numero_particulas() -> int:
	var n := 0
	for e in emisores:
		n += e.amount
	return n


func onda_lanzada() -> bool:
	return _onda_hecha


func _seguir_orbe() -> void:
	if orbe != null and is_instance_valid(orbe):
		global_position = orbe.global_position


func _process(delta: float) -> void:
	_t += delta
	if orbe == null or not is_instance_valid(orbe) or not orbe.is_visible_in_tree():
		apagar()                                  # el orbe ya no está (estalló, se canceló): sin rastro
	else:
		_seguir_orbe()
	if not _onda_hecha and _t >= T_ONDA and not _apagando:
		_onda_hecha = true
		_lanzar_onda()
	if not _apagando and _t >= DURACION:
		apagar()
	if _apagando and _t >= DURACION + _vida_max + 0.1:
		queue_free()


func _lanzar_onda() -> void:
	if _onda == null:
		return
	_onda.visible = true
	_mat_onda.set_shader_parameter("avance", 0.0)
	var t := create_tween()
	t.tween_method(func(v): _mat_onda.set_shader_parameter("avance", v), 0.0, 1.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func(): _onda.visible = false)
	_rafaga.restart()


# Deja de emitir (lo que ya vuela se apaga solo) y se borra al acabar.
func apagar() -> void:
	if _apagando:
		return
	_apagando = true
	_t = maxf(_t, DURACION)
	for e in _espirales:
		e.emitting = false


# Quita el efecto YA (cancelar, saltar, estallar): nada se queda en pantalla ni retenido.
func quitar() -> void:
	for e in emisores:
		e.emitting = false
		e.visible = false
	if _onda != null:
		_onda.visible = false
	queue_free()


func _espiral(cantidad: int, vida: float, tex: Texture2D, tam: float, aditivo: bool) -> CPUParticles3D:
	var p := _particulas(cantidad, vida, tex, tam, aditivo)
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.95 * F
	p.emission_ring_inner_radius = 0.6 * F
	p.emission_ring_height = 0.7 * F
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.1 * F
	p.initial_velocity_max = 0.35 * F
	p.gravity = Vector3.ZERO
	p.radial_accel_min = -3.2 * F / 0.36          # vidas al 60 %: aceleraciones mayores para cerrarse a tiempo
	p.radial_accel_max = -2.2 * F / 0.36
	p.tangential_accel_min = 3.5 * F / 0.6
	p.tangential_accel_max = 5.0 * F / 0.6
	p.damping_min = 0.8 * F
	p.damping_max = 1.4 * F
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.4))
	c.add_point(Vector2(0.3, 1.0))
	c.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = c
	p.emitting = true
	add_child(p)
	emisores.append(p)
	_espirales.append(p)
	return p


func _particulas(cantidad: int, vida: float, tex: Texture2D, tam: float, aditivo: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = cantidad
	p.lifetime = vida
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if aditivo else BaseMaterial3D.BLEND_MODE_MIX
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE * tam                  # el tamaño va en la malla (escalar no es fiable en Compatibility)
	q.material = m
	p.mesh = q
	p.preprocess = vida                         # en Compatibility las no nacidas se pintan en el centro
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


func _rampa(colores: Array, offsets: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colores)
	return g


func _textura_radial(colores: Array, offsets: Array) -> GradientTexture2D:
	var t := GradientTexture2D.new()
	t.gradient = _rampa(colores, offsets)
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _textura_estrella(n: int) -> ImageTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var nucleo := clampf(1.0 - r / 0.35, 0.0, 1.0)
			var rayos := maxf(clampf(1.0 - absf(u) * 9.0, 0.0, 1.0) * clampf(1.0 - absf(v), 0.0, 1.0),
				clampf(1.0 - absf(v) * 9.0, 0.0, 1.0) * clampf(1.0 - absf(u), 0.0, 1.0))
			var a := clampf(nucleo * nucleo + rayos * rayos, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
