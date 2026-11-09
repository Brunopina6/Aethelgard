extends "res://maga_3d.gd"
# Érebo, invocación de Lya: el personaje y sus efectos propios (versión cinematográfica).
# La coreografía completa (sombra, cámara, sonido, reglas, saltar) la dirige invocacion_erebo.gd.
#
# Animaciones de Mixamo (cada una en su FBX) que se juntan al cargar:
#   erebo_idle.fbx    Thriller Idle            -> Reposo
#   erebo_salir.fbx   Getting Up               -> Emerger     (tramo 1,5-6,0 s)
#   erebo_mano_2.fbx  Zombie Jab               -> Penetrar    (la mano entra a 0,72 s)
#   erebo_coger.fbx   Picking Up Object        -> Extraer     (agarra 1,05 s, retira hasta 2,4 s)
#   erebo_conjuro.fbx Sword And Shield Casting -> Alzar       (alza 0,3-1,25 s; se agacha 1,4-2,4 s)
#   erebo_mano.fbx    Pick Up Fruit            -> Recoger     (de reserva)
#
# Sujetar y aplastar el orbe con LAS DOS MANOS: la animación se congela en la pose de «Alzar» y,
# encima, una IK de dos huesos por brazo lleva cada muñeca a un lado del orbe. Las palmas se colocan
# en la superficie del orbe (nunca lo atraviesan) y se van cerrando a medida que se comprime.
#
# Eventos (señal «evento»): "emerge", "asoma", "penetra", "agarra", "orbe_fuera", "sostiene",
# "pulso", "tension", "cierra", "estalla", "vacia", "se_hunde", "desaparece".

signal evento(nombre: String)

const ANIMS := {
	"Reposo": "res://erebo_idle.fbx",
	"Emerger": "res://erebo_salir.fbx",
	"Penetrar": "res://erebo_mano_2.fbx",
	"Extraer": "res://erebo_coger.fbx",
	"Alzar": "res://erebo_conjuro.fbx",
	"Recoger": "res://erebo_mano.fbx",
}
const TEXTURA := "res://erebo_color.png"

const COLOR_HUMO := Color(0.23, 0.14, 0.27)       # #3A2346
const COLOR_HUMO_CLARO := Color(0.42, 0.29, 0.55) # #6B4A8C
const COLOR_DESTELLO := Color(1.0, 0.18, 0.33)    # #FF2D55
const COLOR_NUCLEO := Color(1.0, 0.09, 0.27)      # #FF1744
const COLOR_BORDE := Color(0.16, 0.05, 0.23)      # #2A0E3A

# Cuerpo con disolución: ruido que se come la malla dejando un borde violeta encendido.
const SHADER_CUERPO := """
shader_type spatial;
uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform float disolver = 0.0;            // 0 = entero, 1 = desaparecido
uniform vec4 borde : source_color = vec4(0.62, 0.25, 0.85, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void fragment() {
	vec4 c = texture(textura, UV);
	float n = ruido(UV * 18.0) * 0.6 + ruido(UV * 47.0) * 0.4;
	float corte = n - disolver * 1.15 + 0.075;
	if (corte < 0.0) { discard; }
	float b = 1.0 - smoothstep(0.0, 0.07, corte);
	ALBEDO = mix(c.rgb, borde.rgb, b * step(0.001, disolver));
	EMISSION = borde.rgb * b * 2.0 * step(0.001, disolver);
	ROUGHNESS = 0.8;
}
"""

const SHADER_CHARCO := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float abierto = 1.0;
uniform vec4 color : source_color = vec4(0.05, 0.02, 0.08, 1.0);
uniform vec4 borde : source_color = vec4(0.45, 0.1, 0.5, 1.0);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float ang = atan(p.y, p.x);
	float r = length(p) / max(abierto, 0.001);
	r += 0.08 * sin(ang * 7.0 + TIME * 2.0) + 0.05 * sin(ang * 13.0 - TIME * 3.0);
	float a = 1.0 - smoothstep(0.75, 1.0, r);
	float anillo = smoothstep(0.6, 0.85, r) * (1.0 - smoothstep(0.85, 1.0, r));
	ALBEDO = mix(color.rgb, borde.rgb, anillo * (0.6 + 0.4 * sin(TIME * 4.0)));
	ALPHA = a * color.a;
}
"""

# Orbe: negro violáceo con núcleo carmesí, grietas que se encienden, late y se deforma.
const SHADER_ORBE := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform float grietas = 0.0;      // 0 = liso, 1 = a punto de romperse
uniform float pulso = 0.0;        // 0..1, latido
uniform float temblor = 0.0;      // deformación irregular de la superficie
uniform vec4 borde : source_color = vec4(0.16, 0.05, 0.23, 1.0);
uniform vec4 nucleo : source_color = vec4(1.0, 0.09, 0.27, 1.0);
varying vec3 pos;
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void vertex() {
	pos = VERTEX;
	vec3 n = normalize(VERTEX);
	float w = sin(n.x * 9.0 + TIME * 13.0) * sin(n.y * 7.0 - TIME * 11.0) * sin(n.z * 8.0 + TIME * 9.0);
	VERTEX += NORMAL * (w * temblor * 0.12 + pulso * 0.06) * length(VERTEX);
}
void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.6);
	float centro = 1.0 - fres;
	vec3 c = mix(borde.rgb, nucleo.rgb * (1.4 + pulso), pow(centro, 3.0));
	vec3 q = normalize(pos) * 6.0;
	vec3 iq = floor(q);
	float d1 = 9.0, d2 = 9.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 o = vec3(float(x), float(y), float(z));
		vec3 pt = iq + o + vec3(hash(iq + o), hash(iq + o + 3.1), hash(iq + o + 7.7));
		float d = length(q - pt);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	float linea = 1.0 - smoothstep(0.0, 0.05 + 0.1 * grietas, d2 - d1);
	c = mix(c, nucleo.rgb * (2.2 + pulso * 1.5), linea * grietas);
	c += vec3(0.5, 0.1, 0.6) * fres * 0.7;
	ALBEDO = c;
}
"""

var calidad := "alta"            # "alta" (PC) o "movil": menos partículas
var reducir_destellos := false

var orbe: MeshInstance3D
var _mat_orbe: ShaderMaterial
var _halo: Sprite3D
var charco: MeshInstance3D
var _mat_charco: ShaderMaterial
var _mat_cuerpo: ShaderMaterial
var humo: CPUParticles3D
var volutas: CPUParticles3D
var destellos: CPUParticles3D
var gema: Sprite3D
var aura_mano: Sprite3D
var _brillo_tex: GradientTexture2D
var _aro_tex: GradientTexture2D
var _i := {}
var _y_base := 0.0
var _orbe_en := ""             # "mano" (derecha) | "centro" (sujeto con las dos) | ""
var _centro := Vector3.ZERO    # centro del orbe cuando se sujeta (espacio del esqueleto)
var _radio := 0.1              # radio actual del orbe (metros del mundo)
var _aplasta := 0.0            # 0 = esfera, 1 = aplastado entre las palmas
var _ik := 0.0                 # peso de la IK de las dos manos
var _largos := {}
# Invocación nueva (T-101, invocacion_erebo_nueva.gd): la punta de la mano derecha llega a un punto del mundo (el pecho
# del enemigo) con una IK de dos huesos encima del clip. Peso 0 = solo el clip (la invocación de siempre no la usa).
var ik_mano := 0.0
var mano_objetivo := Vector3.ZERO


func _init() -> void:
	ruta_modelo = "res://erebo_idle.fbx"
	rutas_extra = ["res://erebo.fbx", "res://erebo.glb"]
	usa_vara = false        # sin el cetro de maga_3d.gd (si no, se le queda colgando)


func _ready() -> void:
	super._ready()
	if skel == null:
		return
	_poner_material()
	for n in ["Hips", "Spine2", "Head", "HeadTop_End", "RightShoulder", "LeftShoulder", "RightArm", "RightForeArm", "RightHand", "RightHandMiddle1",
			"RightHandThumb1", "LeftArm", "LeftForeArm", "LeftHand", "LeftHandMiddle1", "LeftHandThumb1"]:
		_i[n] = _hueso(n)
	for lado in ["Right", "Left"]:
		_largos[lado] = [_largo_rest(lado + "Arm", lado + "ForeArm"), _largo_rest(lado + "ForeArm", lado + "Hand")]
	_crear_efectos()
	gestos.al_terminar = _post_pose
	reposo()
	await _ajustar_suelo()


func _hueso(fin: String) -> int:
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		if n.ends_with("_" + fin) or n.ends_with(":" + fin) or n == fin:
			return i
	return -1


func _largo_rest(a: String, b: String) -> float:
	var ia: int = _i.get(a, -1)
	var ib: int = _i.get(b, -1)
	if ia < 0 or ib < 0:
		return 0.1
	return skel.get_bone_global_rest(ia).origin.distance_to(skel.get_bone_global_rest(ib).origin)


# Las animaciones de Mixamo tienen la cadera más alta que la pose del modelo: se apoyan los pies.
func _ajustar_suelo() -> void:
	anim.play(nombres.get("Idle", "Reposo"))
	anim.seek(0.0, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var bajo := INF
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		if "Foot" in n or "Toe" in n:
			bajo = minf(bajo, to_local(skel.global_transform * skel.get_bone_global_pose(i).origin).y)
	if bajo != INF:
		ajuste.position.y -= bajo - 0.02 * ALTURA
	_y_base = ajuste.position.y


# La malla de Mixamo llega sin color: textura de Meshy + disolución.
func _poner_material() -> void:
	_mat_cuerpo = ShaderMaterial.new()
	_mat_cuerpo.shader = Shader.new()
	_mat_cuerpo.shader.code = SHADER_CUERPO
	if ResourceLoader.exists(TEXTURA):
		_mat_cuerpo.set_shader_parameter("textura", load(TEXTURA))
	for mi in find_children("*", "MeshInstance3D", true, false):
		mi.material_override = _mat_cuerpo


func disolver(desde: float, hasta: float, dur: float) -> void:
	var t := create_tween()
	t.tween_method(func(v): _mat_cuerpo.set_shader_parameter("disolver", v), desde, hasta, dur)
	await t.finished


# ---------------------------------------------------------------- animaciones

func _mapear_animaciones() -> void:
	var lib: AnimationLibrary = anim.get_animation_library("")
	if lib == null:
		return
	for n in lib.get_animation_list():
		if not lib.has_animation("Reposo"):
			lib.rename_animation(n, "Reposo")
	for nombre in ANIMS:
		if lib.has_animation(nombre) or not ResourceLoader.exists(ANIMS[nombre]):
			continue
		var escena = load(ANIMS[nombre])
		if not (escena is PackedScene):
			continue
		var tmp: Node = escena.instantiate()
		var ap: AnimationPlayer = tmp.find_child("AnimationPlayer", true, false)
		if ap != null and ap.get_animation_list().size() > 0:
			lib.add_animation(nombre, ap.get_animation(ap.get_animation_list()[0]).duplicate(true))
		tmp.free()
	for nombre in lib.get_animation_list():
		nombres[nombre] = nombre
		_quitar_avance(nombre)
	nombres["Idle"] = "Reposo"
	if lib.has_animation("Reposo"):
		lib.get_animation("Reposo").loop_mode = Animation.LOOP_LINEAR


func _quitar_avance(nombre_real: String) -> void:
	var a := anim.get_animation(nombre_real)
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D or not String(a.track_get_path(t)).ends_with("Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n == 0:
			continue
		var p0: Vector3 = a.track_get_key_value(t, 0)
		for k in n:
			var p: Vector3 = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, Vector3(p0.x, p.y, p0.z))


func _tramo(nombre: String, desde: float, hasta: float, velocidad := 1.0, mezcla := 0.15) -> void:
	if not nombres.has(nombre):
		await _espera((hasta - desde) / velocidad)
		return
	anim.play(nombre, mezcla, velocidad)
	anim.seek(desde, true)
	await _espera((hasta - desde) / velocidad)


func _espera(s: float) -> void:
	await get_tree().create_timer(s).timeout


func reposo() -> void:
	play("Idle", 0.3)
	anim.speed_scale = 1.0
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3)


# ---------------------------------------------------------------- efectos

func _cant(n: int) -> int:
	return n if calidad == "alta" else maxi(4, n / 2)


func _crear_efectos() -> void:
	var e: float = ALTURA
	_brillo_tex = _textura_radial([Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0)], [0.0, 0.4, 1.0])
	_aro_tex = _textura_radial([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)], [0.0, 0.72, 0.86, 1.0])

	charco = MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(1.6, 1.6) * e * 0.6
	charco.mesh = plano
	_mat_charco = ShaderMaterial.new()
	_mat_charco.shader = Shader.new()
	_mat_charco.shader.code = SHADER_CHARCO
	_mat_charco.set_shader_parameter("abierto", 0.0)
	charco.material_override = _mat_charco
	charco.position = Vector3(0, 0.01, 0)
	add_child(charco)

	humo = _particulas(_cant(26), 1.4, _brillo_tex, 0.22 * e)
	humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	humo.emission_box_extents = Vector3(0.22, 0.3, 0.18) * e
	humo.position = Vector3(0, 0.35 * e, 0)
	humo.direction = Vector3.UP
	humo.spread = 35.0
	humo.gravity = Vector3(0, 0.35, 0)
	humo.initial_velocity_min = 0.05
	humo.initial_velocity_max = 0.25
	humo.scale_amount_min = 0.45
	humo.color_ramp = _rampa([Color(COLOR_HUMO_CLARO, 0.0), COLOR_HUMO_CLARO, Color(COLOR_HUMO, 0.0)], [0.0, 0.25, 1.0], 0.4)
	add_child(humo)

	volutas = _particulas(_cant(12), 1.2, _brillo_tex, 0.13 * e)
	volutas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	volutas.emission_sphere_radius = 0.35 * e
	volutas.position = Vector3(0, 0.85 * e, 0)
	volutas.gravity = Vector3(0, 0.1, 0)
	volutas.scale_amount_min = 0.45
	volutas.color_ramp = _rampa([Color(COLOR_HUMO_CLARO, 0.0), COLOR_HUMO_CLARO, Color(COLOR_HUMO, 0.0)], [0.0, 0.3, 1.0], 0.5)
	add_child(volutas)

	destellos = _particulas(_cant(14), 0.8, _brillo_tex, 0.05 * e)
	destellos.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	destellos.emission_box_extents = Vector3(0.3, 0.45, 0.25) * e
	destellos.position = Vector3(0, 0.5 * e, 0)
	destellos.scale_amount_min = 0.4
	destellos.color_ramp = _rampa([Color(COLOR_DESTELLO, 0.0), COLOR_DESTELLO, Color(COLOR_DESTELLO, 0.0)], [0.0, 0.2, 1.0], 1.0)
	add_child(destellos)

	gema = _sprite(_brillo_tex, COLOR_DESTELLO, 0.0016 * e)
	var t := create_tween().set_loops()
	t.tween_property(gema, "modulate:a", 0.45, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(gema, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	aura_mano = _sprite(_brillo_tex, Color(0.35, 0.1, 0.5, 0.9), 0.003 * e)
	aura_mano.visible = false

	orbe = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 32
	esfera.rings = 16
	orbe.mesh = esfera
	_mat_orbe = ShaderMaterial.new()
	_mat_orbe.shader = Shader.new()
	_mat_orbe.shader.code = SHADER_ORBE
	_mat_orbe.set_shader_parameter("borde", COLOR_BORDE)
	_mat_orbe.set_shader_parameter("nucleo", COLOR_NUCLEO)
	orbe.material_override = _mat_orbe
	orbe.visible = false
	add_child(orbe)
	_halo = _sprite(_brillo_tex, Color(COLOR_NUCLEO, 0.55), 0.004 * e)
	_halo.visible = false
	_efectos(false)


func _textura_radial(colores: Array, offsets: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colores)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _sprite(tex: Texture2D, color: Color, px: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.modulate = color
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	add_child(s)
	return s


func _particulas(cantidad: int, vida: float, tex: Texture2D, tam := 1.0, malla: Mesh = null) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = cantidad
	p.lifetime = vida
	p.local_coords = false
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	if malla == null:
		var q := QuadMesh.new()
		q.size = Vector2.ONE * tam      # el tamaño va en la malla (escalar partículas no es fiable en Compatibility)
		m.albedo_texture = tex
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		q.material = m
		p.mesh = q
	else:
		p.mesh = malla
		p.material_override = m
	# En Compatibility las partículas aún no nacidas se dibujan en el centro: se precalcula una vida.
	p.preprocess = vida
	p.emitting = false
	return p


func _rampa(colores: Array, offsets: Array, alfa: float) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	var c := PackedColorArray()
	for col in colores:
		c.append(Color(col.r, col.g, col.b, col.a * alfa))
	g.colors = c
	return g


func _efectos(si: bool) -> void:
	for p in [humo, volutas, destellos]:
		p.emitting = si
		p.visible = si
	gema.visible = si


func _rafaga(pos: Vector3, color: Color, cantidad: int, fuerza: float, tam: float, malla: Mesh = null) -> void:
	var p := _particulas(_cant(cantidad), 0.8, _brillo_tex, tam, malla)
	p.one_shot = true
	p.preprocess = 0.0
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = fuerza * 0.5
	p.initial_velocity_max = fuerza
	p.gravity = Vector3(0, -1.2 if malla != null else -0.6, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	if malla != null:
		p.angular_velocity_min = -360.0
		p.angular_velocity_max = 360.0
		p.particle_flag_rotate_y = true
	p.color_ramp = _rampa([color, color, Color(color, 0.0)], [0.0, 0.5, 1.0], 1.0)
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(0.85).timeout.connect(func(): if is_instance_valid(p): p.visible = false; p.queue_free())


# Fogonazo (crece y se apaga) o, si encoge = true, una onda que se cierra hacia dentro (implosión).
func fogonazo(pos: Vector3, color: Color, tam: float, dur := 0.3, encoge := false, aro := false) -> void:
	if reducir_destellos:
		color.a *= 0.35
	var f := _sprite(_aro_tex if aro else _brillo_tex, color, 0.0)
	f.global_position = pos
	var a: float = (tam / 64.0) if encoge else (tam / 64.0) * 0.25
	var b: float = 0.0 if encoge else tam / 64.0
	f.pixel_size = a
	var t := create_tween().set_parallel(true)
	t.tween_property(f, "pixel_size", b, dur).set_ease(Tween.EASE_IN if encoge else Tween.EASE_OUT)
	if not encoge:
		t.tween_property(f, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(f.queue_free)


# ---------------------------------------------------------------- pose: gema, orbe e IK de las dos manos

func _post_pose(sk: Skeleton3D) -> void:
	var g := sk.global_transform
	if _ik > 0.001:
		_ik_brazo(sk, "Right", 1.0)
		_ik_brazo(sk, "Left", -1.0)
	elif ik_mano > 0.001:
		_ik_alcance(sk)
		_ik_alcance(sk)                 # (dos pasadas: la punta depende del giro de la mano)
	if _i["Spine2"] >= 0:
		gema.global_position = g * sk.get_bone_global_pose(_i["Spine2"]).origin + _adelante() * 0.11 * ALTURA
	if orbe.visible:
		if _orbe_en == "mano" and _i["RightHand"] >= 0:
			orbe.global_position = g * sk.get_bone_global_pose(_i["RightHand"]).origin.lerp(sk.get_bone_global_pose(_i["RightHandMiddle1"]).origin, 0.9)
		elif _orbe_en == "centro":
			orbe.global_position = g * _centro
		var lado := _derecha_mundo()
		var arriba := Vector3.UP
		var fwd := lado.cross(arriba).normalized()
		var esc := Vector3(_radio * (1.0 - 0.45 * _aplasta), _radio * (1.0 + 0.2 * _aplasta), _radio * (1.0 + 0.15 * _aplasta))
		orbe.global_basis = Basis(lado * esc.x, arriba * esc.y, fwd * esc.z)
		_halo.global_position = orbe.global_position
		_halo.pixel_size = _radio * 6.0 / 64.0
	if aura_mano.visible and _i["RightHandMiddle1"] >= 0:
		aura_mano.global_position = g * sk.get_bone_global_pose(_i["RightHandMiddle1"]).origin


func _derecha_mundo() -> Vector3:
	var v: Vector3 = skel.global_transform.basis * gestos.derecha
	v.y = 0.0
	return v.normalized()


func _adelante() -> Vector3:
	var v: Vector3 = skel.global_transform.basis * gestos.adelante
	v.y = 0.0
	return v.normalized()


# IK analítica de dos huesos: la muñeca va a un lado del orbe, con la palma mirándolo.
# signo: +1 brazo derecho (a la derecha del orbe), -1 izquierdo.
func _ik_brazo(sk: Skeleton3D, lado: String, signo: float) -> void:
	var ia: int = _i[lado + "Arm"]
	var ie: int = _i[lado + "ForeArm"]
	var ih: int = _i[lado + "Hand"]
	var im: int = _i[lado + "HandMiddle1"]
	if ia < 0 or ie < 0 or ih < 0:
		return
	var esc: float = sk.global_transform.basis.get_scale().x
	var r_sk: float = (_radio * (1.0 - 0.45 * _aplasta)) / esc          # radio en unidades del esqueleto
	var palma: float = (sk.get_bone_global_pose(ih).origin.distance_to(sk.get_bone_global_pose(im).origin) if im >= 0 else r_sk * 0.5)
	var ejes := _ejes_torso(sk)
	var der: Vector3 = ejes[0]
	var fwd: Vector3 = ejes[1]
	var up: Vector3 = ejes[2]
	# brazos chibi cortos: el hombro (clavícula) se adelanta hacia el orbe para ganar alcance
	var isd: int = _i.get(lado + "Shoulder", -1)
	if isd >= 0:
		var sh := sk.get_bone_global_pose(isd)
		var brazo0 := sk.get_bone_global_pose(ia).origin
		var hacia_c := (_centro - sh.origin)
		var qs := Quaternion.IDENTITY.slerp(_quat_entre(brazo0 - sh.origin, hacia_c), 0.35 * _ik)
		sk.set_bone_global_pose(isd, Transform3D(Basis(qs) * sh.basis, sh.origin))
	# la palma toca la superficie: la muñeca queda un poco atrás y hacia fuera
	var objetivo: Vector3 = _centro + der * signo * (r_sk + palma * 0.25) - fwd * palma * 0.55
	var la: float = _largos[lado][0]
	var lb: float = _largos[lado][1]
	var s: Vector3 = sk.get_bone_global_pose(ia).origin
	var a_pose := sk.get_bone_global_pose(ia)
	var e_pose := sk.get_bone_global_pose(ie)
	var h_pose := sk.get_bone_global_pose(ih)
	var to_t := objetivo - s
	var d := clampf(to_t.length(), 0.001, (la + lb) * 0.999)
	var dir := to_t.normalized()
	var polo: Vector3 = (-up * 0.7 + der * signo * 0.6 - fwd * 0.2).normalized()   # codo abajo y hacia fuera
	polo = (polo - dir * polo.dot(dir)).normalized()
	var cos_a := clampf((la * la + d * d - lb * lb) / (2.0 * la * d), -1.0, 1.0)
	var codo: Vector3 = s + dir * (la * cos_a) + polo * (la * sqrt(1.0 - cos_a * cos_a))
	var mano: Vector3 = s + dir * d
	# brazo
	var q1 := Quaternion.IDENTITY.slerp(_quat_entre(e_pose.origin - s, codo - s), _ik)
	var nuevo_a := Transform3D(Basis(q1) * a_pose.basis, a_pose.origin)
	sk.set_bone_global_pose(ia, nuevo_a)
	# antebrazo (su origen se ha movido con el brazo)
	var e_nuevo := sk.get_bone_global_pose(ie)
	var h_actual := sk.get_bone_global_pose(ih).origin
	var q2 := Quaternion.IDENTITY.slerp(_quat_entre(h_actual - e_nuevo.origin, mano - e_nuevo.origin), _ik)
	sk.set_bone_global_pose(ie, Transform3D(Basis(q2) * e_nuevo.basis, e_nuevo.origin))
	# mano: dedos hacia delante y un poco hacia el centro, pulgar arriba
	if im >= 0:
		var h_n := sk.get_bone_global_pose(ih)
		var dedos_act := (sk.get_bone_global_pose(im).origin - h_n.origin).normalized()
		var dedos_obj := (fwd * 0.85 - der * signo * 0.35 + up * 0.15).normalized()
		var q3 := Quaternion.IDENTITY.slerp(_quat_entre(dedos_act, dedos_obj), _ik)
		var b3: Basis = Basis(q3) * h_n.basis
		var it: int = _i.get(lado + "HandThumb1", -1)
		if it >= 0:
			var pulgar := (Basis(q3) * (sk.get_bone_global_pose(it).origin - h_n.origin)).normalized()
			var pulgar_obj := up
			pulgar = (pulgar - dedos_obj * pulgar.dot(dedos_obj)).normalized()
			pulgar_obj = (pulgar_obj - dedos_obj * pulgar_obj.dot(dedos_obj)).normalized()
			var giro := Quaternion.IDENTITY.slerp(_quat_entre(pulgar, pulgar_obj), _ik)
			b3 = Basis(giro) * b3
		sk.set_bone_global_pose(ih, Transform3D(b3, h_n.origin))


# IK de alcance (T-101): lleva la punta de la mano derecha (el dedo corazón) a mano_objetivo, con el codo hacia abajo
# y afuera. Corrige lo que quede tras colocar a Érebo por la mano (unos centímetros) sin cambiar el gesto del clip.
func _ik_alcance(sk: Skeleton3D) -> void:
	var ia: int = _i["RightArm"]
	var ie: int = _i["RightForeArm"]
	var ih: int = _i["RightHand"]
	var im: int = _i["RightHandMiddle1"]
	if ia < 0 or ie < 0 or ih < 0 or im < 0:
		return
	var obj_sk: Vector3 = sk.global_transform.affine_inverse() * mano_objetivo
	var punta_rel: Vector3 = sk.get_bone_global_pose(im).origin - sk.get_bone_global_pose(ih).origin
	var objetivo: Vector3 = obj_sk - punta_rel                       # la muñeca, para que la punta caiga en el sitio
	var la: float = _largos["Right"][0]
	var lb: float = _largos["Right"][1]
	var a_pose := sk.get_bone_global_pose(ia)
	var s: Vector3 = a_pose.origin
	var e_pose := sk.get_bone_global_pose(ie)
	var to_t := objetivo - s
	var d := clampf(to_t.length(), 0.001, (la + lb) * 0.999)
	var dir := to_t.normalized()
	var ejes := _ejes_torso(sk)
	var polo: Vector3 = (-ejes[2] * 0.7 + ejes[0] * 0.6).normalized()
	polo = (polo - dir * polo.dot(dir)).normalized()
	var cos_a := clampf((la * la + d * d - lb * lb) / (2.0 * la * d), -1.0, 1.0)
	var codo: Vector3 = s + dir * (la * cos_a) + polo * (la * sqrt(1.0 - cos_a * cos_a))
	var q1 := Quaternion.IDENTITY.slerp(_quat_entre(e_pose.origin - s, codo - s), ik_mano)
	sk.set_bone_global_pose(ia, Transform3D(Basis(q1) * a_pose.basis, a_pose.origin))
	var e_n := sk.get_bone_global_pose(ie)
	var h_act := sk.get_bone_global_pose(ih).origin
	var q2 := Quaternion.IDENTITY.slerp(_quat_entre(h_act - e_n.origin, (s + dir * d) - e_n.origin), ik_mano)
	sk.set_bone_global_pose(ie, Transform3D(Basis(q2) * e_n.basis, e_n.origin))


# Dónde queda la punta de la mano derecha en el instante «t» del clip «clip», respecto a los pies de Érebo y en sus
# ejes (adelante, arriba, derecha), en metros del mundo (con su escala). Para colocarlo por la mano (T-101).
func punta_en(clip: String, t: float) -> Vector3:
	if anim == null or not anim.has_animation(clip) or _i.get("RightHandMiddle1", -1) < 0:
		return Vector3(0.37, 0.88, 0.0)                    # lo medido en la Fase 1 con «Extraer» a 0,80 s
	var antes := String(anim.current_animation)
	var pos_antes := anim.current_animation_position
	anim.play(clip, 0.0)
	anim.seek(t, true)
	var p: Vector3 = skel.global_transform * skel.get_bone_global_pose(_i["RightHandMiddle1"]).origin - global_position
	if antes != "":
		anim.play(antes, 0.0)
		anim.seek(pos_antes, true)
	var fwd := _adelante()
	var der := fwd.cross(Vector3.UP).normalized()
	return Vector3(p.dot(fwd), p.y, p.dot(der))


# Surge con la pose quieta (D7): sin el clip de levantarse, la cabeza baja, despacio al principio y posándose al
# final, y se queda levitando «levita» metros (D8). Dura «dur» segundos.
func emerger_quieto(dur := 1.9, levita := 0.05) -> void:
	_efectos(false)
	_mat_cuerpo.set_shader_parameter("disolver", 1.0)
	ajuste.position.y = _y_base - ALTURA * 1.05
	visible = true
	anim.play(nombres.get("Idle", "Reposo"), 0.0)
	anim.seek(0.0, true)
	anim.speed_scale = 0.0
	gestos.poner("cansada", 0.6, 0.01)                      # cabeza baja y brazos algo caídos mientras sube
	var t := _tw()
	t.tween_method(func(v): _mat_charco.set_shader_parameter("abierto", v), 0.0, 1.0, 0.4).set_ease(Tween.EASE_OUT)
	await t.finished
	if cancelado: return
	evento.emit("emerge")
	_rafaga(global_position + Vector3(0, 0.1, 0), COLOR_HUMO_CLARO, 12, 0.8, 0.14 * ALTURA)
	humo.visible = true
	humo.emitting = true
	var sube := _tw().set_parallel(true)
	var s := dur - 0.4
	sube.tween_property(ajuste, "position:y", _y_base + levita / maxf(scale.y, 0.01), s).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sube.tween_method(func(v): _mat_cuerpo.set_shader_parameter("disolver", v), 1.0, 0.0, s * 1.05)
	await _espera(s - 0.6)
	if cancelado: return
	gestos.quitar("cansada", 0.6)                           # en los últimos 0,6 s levanta la máscara
	await _espera(0.6)
	if cancelado: return
	_efectos(true)
	evento.emit("asoma")
	fogonazo(gema.global_position, COLOR_DESTELLO, 0.25 * ALTURA, 0.3)
	anim.speed_scale = 1.0
	reposo()


# Se acerca flotando hasta «hasta» (D6), con aceleración y frenada suaves.
func deslizar(hasta: Vector3, dur := 0.8) -> void:
	var t := _tw()
	t.tween_property(self, "global_position", hasta, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished


# Mete la mano abierta en el pecho y saca el orbe con un solo clip, «Extraer» (Fase 2, plan final §1.2): la estocada
# 0,15 → 0,80 s (el contacto) en «llegada» segundos, y después agarra y tira hasta 2,4 s. La IK de alcance lleva la
# punta al pecho (mano_objetivo) durante la llegada y el agarre. al_contacto se llama en el fotograma del contacto.
func extraer_abierto(saca: bool, llegada: float, al_contacto: Callable) -> void:
	gestos.quitar_todos(0.1)
	aura_mano.visible = true
	anim.play(nombres.get("Extraer", "Extraer"), 0.2, (0.80 - 0.15) / maxf(llegada, 0.05))
	anim.seek(0.15, true)
	var ik := _tw()
	ik.tween_property(self, "ik_mano", 1.0, llegada * 0.45).set_delay(llegada * 0.4).set_trans(Tween.TRANS_SINE)
	await _espera(llegada)
	if cancelado: return
	anim.speed_scale = 1.0
	anim.seek(0.80, true)
	evento.emit("penetra")
	if al_contacto.is_valid():
		await al_contacto.call()
	if cancelado: return
	await _espera(0.25)                                    # los dedos se cierran dentro (0,80 → 1,05)
	if cancelado: return
	evento.emit("agarra")
	var suelta := _tw()
	suelta.tween_property(self, "ik_mano", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	if saca:
		_radio = 0.02 * ALTURA
		_orbe_en = "mano"
		orbe.visible = true
		_halo.visible = true
		_tw().tween_property(self, "_radio", 0.034 * ALTURA, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		evento.emit("orbe_fuera")
	await _espera(1.35 if saca else 0.9)                   # tira hasta 2,4 s (vacía, la retira antes)
	if cancelado: return
	aura_mano.visible = false
	if not saca:
		_rafaga(_punta_mano(), COLOR_HUMO_CLARO, 10, 0.4, 0.08 * ALTURA)
		evento.emit("vacia")


func _quat_entre(a: Vector3, b: Vector3) -> Quaternion:
	if a.length() < 1e-6 or b.length() < 1e-6:
		return Quaternion.IDENTITY
	return Quaternion(a.normalized(), b.normalized())


# Centro del orbe sujeto: delante de la máscara, a la altura de la barbilla, al alcance de los brazos.
# Ejes del torso (derecha, delante, arriba) a partir de la línea de hombros: siguen el giro del cuerpo.
func _ejes_torso(sk: Skeleton3D) -> Array:
	var up: Vector3 = gestos.arriba.normalized()
	var linea := sk.get_bone_global_pose(_i["LeftArm"]).origin - sk.get_bone_global_pose(_i["RightArm"]).origin
	linea = (linea - up * linea.dot(up)).normalized()
	var fwd := linea.cross(up).normalized()
	if fwd.dot(gestos.adelante) < 0.0:
		fwd = -fwd
	return [-linea, fwd, up]


# Brazos chibi: el orbe se sujeta delante del pecho, justo bajo la máscara, donde las manos llegan.
func _centro_sostener() -> Vector3:
	var ejes := _ejes_torso(skel)
	var hombros := (skel.get_bone_global_pose(_i["RightArm"]).origin + skel.get_bone_global_pose(_i["LeftArm"]).origin) * 0.5
	var alcance: float = (_largos["Right"][0] + _largos["Right"][1])
	return hombros + ejes[1] * alcance * 0.55 - ejes[2] * alcance * 0.3


# ---------------------------------------------------------------- tiempos de la coreografía

# Todas las animaciones de la coreografía se registran para poder cortarlas al saltar.
var cancelado := false
var _tweens: Array = []

func _tw() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t

# Sube desde el charco a la vez que se «des-disuelve» entre humo.
func emerger(rapido := false) -> void:
	_efectos(false)
	_mat_cuerpo.set_shader_parameter("disolver", 1.0)
	ajuste.position.y = _y_base - ALTURA * 1.05
	visible = true
	var t := _tw()
	t.tween_method(func(v): _mat_charco.set_shader_parameter("abierto", v), 0.0, 1.0, 0.45 if rapido else 0.7).set_ease(Tween.EASE_OUT)
	await t.finished
	if cancelado: return
	evento.emit("emerge")
	_rafaga(global_position + Vector3(0, 0.1, 0), COLOR_HUMO_CLARO, 14, 0.9, 0.14 * ALTURA)
	humo.visible = true
	humo.emitting = true
	var dur := 1.2 if rapido else 1.7
	var sube := _tw().set_parallel(true)
	sube.tween_property(ajuste, "position:y", _y_base, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sube.tween_method(func(v): _mat_cuerpo.set_shader_parameter("disolver", v), 1.0, 0.0, dur * 1.1)
	await _tramo("Emerger", 1.5, 6.0, 4.5 / dur, 0.0)
	if cancelado: return
	_efectos(true)
	evento.emit("asoma")
	fogonazo(gema.global_position, COLOR_DESTELLO, 0.25 * ALTURA, 0.3)
	reposo()
	await _espera(0.25 if rapido else 0.45)
	if cancelado: return


# La mano entra en el pecho (sin herida): aura oscura en la mano y onda en el pecho.
func penetrar() -> void:
	gestos.quitar_todos(0.1)
	aura_mano.visible = true
	await _tramo("Penetrar", 0.15, 0.6, 1.0)
	if cancelado: return
	await _tramo("Penetrar", 0.6, 0.72, 0.6, 0.0)
	if cancelado: return
	evento.emit("penetra")


# Agarra la esencia y retira la mano. saca = false: sale vacía con una nubecita de humo.
func extraer(saca: bool) -> void:
	await _tramo("Extraer", 1.05, 1.45, 0.8)
	if cancelado: return
	evento.emit("agarra")
	if saca:
		_radio = 0.02 * ALTURA
		_orbe_en = "mano"
		orbe.visible = true
		_halo.visible = true
		_tw().tween_property(self, "_radio", 0.034 * ALTURA, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		evento.emit("orbe_fuera")
	await _tramo("Extraer", 1.45, 2.4, 1.0)
	if cancelado: return
	aura_mano.visible = false
	if not saca:
		_rafaga(_punta_mano(), COLOR_HUMO_CLARO, 10, 0.4, 0.08 * ALTURA)
		evento.emit("vacia")
		await _espera(0.6)
		if cancelado: return
		reposo()


# Lo alza, lo lleva delante de la máscara, lo rodea con las dos manos y lo comprime hasta romperlo.
# al_estallar se llama en el instante en que las palmas se cierran.
func aplastar(al_estallar: Callable, pulsos: Array = [], silencio := 0.25, rapido := false) -> void:
	# rapido (T-101): sin el clip de alzarlo; las manos van al orbe en 0,4 s y se sueltan antes
	# alzar con la derecha y mirarlo
	if not rapido:
		await _tramo("Alzar", 0.3, 1.0, 1.0)
	if cancelado: return
	# pasar a sujetarlo con las dos manos delante de la máscara
	# cuerpo erguido (reposo casi congelado, solo un leve balanceo) y la IK lleva las manos al orbe
	anim.play(nombres.get("Idle", "Reposo"), 0.3, 0.25)
	var desde_mano := skel.global_transform.affine_inverse() * orbe.global_position
	_centro = desde_mano
	_orbe_en = "centro"
	var t0 := _tw().set_parallel(true)
	var r := 0.5 if rapido else 1.0         # (con rapido, los tiempos de las manos a la mitad)
	t0.tween_property(self, "_ik", 0.35, 0.3 * r)
	await t0.finished
	if cancelado: return
	var hacia := _centro_sostener()
	var t := _tw().set_parallel(true)
	t.tween_property(self, "_centro", hacia, 0.55 * r).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "_ik", 1.0, 0.45 * r).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "_radio", 0.034 * ALTURA, 0.55 * r)
	await t.finished
	if cancelado: return
	evento.emit("sostiene")
	await _espera(0.35 * r)
	if cancelado: return
	# compresión: late cada vez más rápido, se agrieta y se deforma
	if pulsos.is_empty():                  # los de siempre; la invocación nueva (T-101) pide tres latidos
		pulsos = [0.55, 0.45, 0.36, 0.28, 0.22, 0.17]
	for k in pulsos.size():
		var avance := float(k + 1) / pulsos.size()
		evento.emit("pulso")
		var p := _tw().set_parallel(true)
		p.tween_method(func(v): _mat_orbe.set_shader_parameter("pulso", v), 1.0, 0.0, pulsos[k])
		p.tween_method(func(v): _mat_orbe.set_shader_parameter("grietas", v), avance - 1.0 / pulsos.size(), avance, pulsos[k])
		p.tween_method(func(v): _mat_orbe.set_shader_parameter("temblor", v), avance * 0.6, avance, pulsos[k])
		p.tween_property(self, "_aplasta", avance * 0.75, pulsos[k])
		p.tween_property(self, "_radio", 0.034 * ALTURA * (1.0 - 0.35 * avance), pulsos[k])
		await p.finished
		if cancelado: return
	evento.emit("tension")                 # silencio previo al impacto
	await _espera(silencio)
	if cancelado: return
	# las palmas se cierran de golpe
	var cierra := _tw().set_parallel(true)
	cierra.tween_property(self, "_radio", 0.012 * ALTURA, 0.09).set_ease(Tween.EASE_IN)
	cierra.tween_property(self, "_aplasta", 1.0, 0.09)
	await cierra.finished
	if cancelado: return
	var donde := orbe.global_position
	orbe.visible = false
	_halo.visible = false
	_orbe_en = ""
	_estallido(donde)
	evento.emit("estalla")
	if al_estallar.is_valid():
		al_estallar.call()
	_mat_orbe.set_shader_parameter("grietas", 0.0)
	_mat_orbe.set_shader_parameter("temblor", 0.0)
	_aplasta = 0.0
	await _espera(0.45 * r)
	if cancelado: return
	var suelta := _tw()
	suelta.tween_property(self, "_ik", 0.0, 0.5 * r).set_trans(Tween.TRANS_SINE)
	await suelta.finished
	if cancelado: return
	reposo()


# Rotura del orbe: fragmentos de cristal, chispas carmesí, destello breve y onda espiritual
# que primero se cierra hacia las manos (implosión) y luego se expande.
func _estallido(pos: Vector3) -> void:
	var cristal := PrismMesh.new()
	cristal.size = Vector3(0.035, 0.07, 0.02) * ALTURA
	_rafaga(pos, Color(0.25, 0.05, 0.3), 14, 2.2, 0.0, cristal)
	_rafaga(pos, COLOR_NUCLEO, 24, 2.6, 0.035 * ALTURA)
	_rafaga(pos, COLOR_HUMO_CLARO, 10, 0.8, 0.12 * ALTURA)
	fogonazo(pos, Color(1, 0.75, 0.8), 0.55 * ALTURA, 0.18)
	fogonazo(pos, COLOR_NUCLEO, 0.9 * ALTURA, 0.22, true, true)    # implosión: el aro se cierra
	get_tree().create_timer(0.2).timeout.connect(func():
		if is_instance_valid(self):
			fogonazo(pos, Color(0.7, 0.3, 1.0, 0.8), 1.6 * ALTURA, 0.55, false, true))  # onda que se expande


func _punta_mano() -> Vector3:
	if _i["RightHandMiddle1"] < 0:
		return global_position + Vector3(0, ALTURA * 0.5, 0)
	return skel.global_transform * skel.get_bone_global_pose(_i["RightHandMiddle1"]).origin


# Se agacha, se disuelve en humo y se hunde; el charco se cierra.
func hundirse(rapido := false) -> void:
	gestos.quitar_todos(0.2)
	evento.emit("se_hunde")
	destellos.visible = false
	volutas.visible = false
	var dur := 0.7 if rapido else 1.0
	var baja := _tw().set_parallel(true)
	baja.tween_property(ajuste, "position:y", _y_base - ALTURA * 1.05, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.3)
	baja.tween_method(func(v): _mat_cuerpo.set_shader_parameter("disolver", v), 0.0, 1.0, dur + 0.2).set_delay(0.15)
	_rafaga(global_position + Vector3(0, ALTURA * 0.4, 0), COLOR_HUMO_CLARO, 16, 0.7, 0.14 * ALTURA)
	await _tramo("Alzar", 1.4, 2.4, 1.0)
	if cancelado: return
	await baja.finished
	if cancelado: return
	_efectos(false)
	var t := _tw()
	t.tween_method(func(v): _mat_charco.set_shader_parameter("abierto", v), 1.0, 0.0, 0.4).set_ease(Tween.EASE_IN)
	await t.finished
	if cancelado: return
	evento.emit("desaparece")
	limpiar()


# Deja a Érebo como al principio (también al saltar la cinemática).
func limpiar() -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()
	anim.speed_scale = 1.0
	orbe.visible = false
	_halo.visible = false
	aura_mano.visible = false
	_orbe_en = ""
	_ik = 0.0
	ik_mano = 0.0
	_aplasta = 0.0
	_efectos(false)
	_mat_charco.set_shader_parameter("abierto", 0.0)
	_mat_cuerpo.set_shader_parameter("disolver", 0.0)
	_mat_orbe.set_shader_parameter("grietas", 0.0)
	_mat_orbe.set_shader_parameter("temblor", 0.0)
	ajuste.position.y = _y_base
	visible = false
	reposo()
