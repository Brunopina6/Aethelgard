extends Node
# Héroes v2 (fase B, V12): lo común a Kael, Lya y Garon v2. Va como hijo del héroe (kael_v2_3d.gd, lya_v2_3d.gd y
# garon_v2_3d.gd lo crean en su _ready).
#   - Cara expresiva (malla «cara_v2» del GLB, atlas de 4 × 2 losetas: cara_expresiva.py). Con «normal» la malla se
#     oculta y la cara es la original. 13/11: las losetas solo cubren ojos y boca (transparencia), así que los mechones
#     del flequillo ya no quedan tapados; y la cara nueva se ilumina como la piel (mismo modelo de luz y brillo).
#   - Parpadeo con el ritmo de cada uno (13/11): Kael, más frecuente y rápido; Lya, más espaciado y lento. No parpadea
#     con los ojos cerrados, entrecerrados, en la sonrisa, el dolor ni en el KO.
#   - Materiales mejorados (heroe_v2.gdshader): mismas texturas del modelo; piel, tela y cuero mates; metal con reflejo
#     del ambiente de la región (13/11: los colores y la energía se toman del WorldEnvironment de la escena); borde de
#     luz con las luces de la escena. La identidad (colores y forma) no cambia.
#   - Conversación: hablar(animo) elige un gesto distinto cada vez, y a veces ninguno (nada de un gesto en cada frase).

const COLS := 4
const FILAS := 2
# 13/11: la octava loseta (antes «normal2», repetida) es «decidido»: mirada firme, la boca de siempre.
const EXPRESIONES := ["normal", "cerrados", "sonrisa", "dolor", "grito", "sorpresa", "entrecerrados", "decidido"]
const SIN_PARPADEO := ["cerrados", "sonrisa", "dolor", "entrecerrados"]
const SHADER := "res://personajes/heroes_v2/heroe_v2.gdshader"
# Ajustes del material por héroe: borde de luz (RIM) y reflejo del metal
const MATERIAL := {
	"Kael": {"borde": 0.25, "reflejo": 0.55, "relieve": 1.15},
	"Lya": {"borde": 0.3, "reflejo": 0.45, "relieve": 1.0},
	"Garon": {"borde": 0.2, "reflejo": 0.85, "relieve": 1.3},
}
# Lo que la cara nueva copia del material de la piel (heroe_v2.gdshader) para que no se note dónde empieza
const PIEL := {"rugosidad": 0.72, "especular": 0.28, "tinte_borde": 0.4}
# Parpadeo de cada uno: cada cuánto (s), probabilidad de un doble parpadeo y duración relativa
const PARPADEO := {
	"Kael": {"cada": Vector2(2.0, 4.6), "doble": 0.22, "duracion": 0.85},    # inquieto, vivo
	"Lya": {"cada": Vector2(3.4, 6.8), "doble": 0.08, "duracion": 1.35},     # serena, párpados lentos
}
# Ánimo de una frase -> expresión mientras habla (el resto del tiempo, la de base)
const ANIMOS := {"alegre": "sonrisa", "broma": "sonrisa", "sorpresa": "sorpresa", "enfado": "grito",
	"decidido": "decidido", "dolor": "dolor", "triste": "entrecerrados", "cansado": "entrecerrados"}

var heroe: Node3D
var nombre_heroe := ""
var anim: AnimationPlayer
var cara: MeshInstance3D
var mat_cara: StandardMaterial3D
var expresion := "normal"
var mejorar_materiales := true
var materiales: Array[ShaderMaterial] = []
var _base := "normal"            # la expresión a la que se vuelve
var _hasta := 0.0                # si > 0, la expresión actual dura hasta entonces
var _t_parpadeo := 3.0
var _parpadeo := -1.0            # tiempo dentro de un parpadeo (< 0: no parpadea)
var _ritmo := {"cada": Vector2(2.5, 6.0), "doble": 0.15, "duracion": 1.0}
var _azar := RandomNumberGenerator.new()
var _ultimo_gesto := ""
var _tiempo := 0.0
var _t_entorno := 0.0
var _entorno_visto: Environment = null


func preparar(h: Node3D, nombre: String) -> void:
	heroe = h
	nombre_heroe = nombre
	anim = h.get("anim")
	_azar.randomize()
	_ritmo = PARPADEO.get(nombre, _ritmo)
	_t_parpadeo = _azar.randf_range(1.0, _ritmo["cada"].x + 1.0)
	var c = h.find_child("cara_v2", true, false)
	if c is MeshInstance3D:
		cara = c
		_preparar_cara()
	if mejorar_materiales:
		_materiales(h)
		_leer_entorno.call_deferred()


# ---------------------------------------------------------------- cara
func _preparar_cara() -> void:
	var tex: Texture2D = null
	var m := cara.get_active_material(0)
	if m is BaseMaterial3D:
		tex = m.albedo_texture
	mat_cara = StandardMaterial3D.new()
	mat_cara.albedo_texture = tex
	# solo ojos y boca (la loseta es transparente en lo demás); se dibuja tras lo opaco, así el pelo la tapa bien
	mat_cara.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cara.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	# la misma luz que la piel (heroe_v2.gdshader): mate, envolvente y con el mismo borde
	mat_cara.roughness = PIEL["rugosidad"]
	mat_cara.metallic_specular = PIEL["especular"]
	mat_cara.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	mat_cara.rim_enabled = true
	mat_cara.rim = MATERIAL.get(nombre_heroe, {}).get("borde", 0.2)
	mat_cara.rim_tint = PIEL["tinte_borde"]
	mat_cara.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cara.material_override = mat_cara
	cara.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aplicar("normal")


func tiene_cara() -> bool:
	return cara != null


# Pone una expresión. dur > 0: vuelve a la base al acabar; dur = 0: queda como base.
func poner_expresion(nombre: String, dur := 0.0) -> void:
	if not nombre in EXPRESIONES:
		nombre = "normal"
	if dur > 0.0:
		_hasta = _tiempo + dur
	else:
		_base = nombre
		_hasta = 0.0
	_parpadeo = -1.0
	_aplicar(nombre)


func _aplicar(nombre: String) -> void:
	expresion = nombre
	if cara == null:
		return
	var i := EXPRESIONES.find(nombre)
	cara.visible = nombre != "normal"
	mat_cara.uv1_offset = Vector3(float(i % COLS) / COLS, float(i / COLS) / FILAS, 0.0)


func _process(delta: float) -> void:
	_tiempo += delta
	_t_entorno -= delta
	if _t_entorno <= 0.0 and not materiales.is_empty():
		_leer_entorno()
	if cara == null:
		return
	if _hasta > 0.0 and _tiempo >= _hasta:
		_hasta = 0.0
		_aplicar(_base)
	# parpadeo: entrecerrados, cerrados, entrecerrados (0,04 · 0,07 · 0,04 s por la duración de cada uno)
	if _parpadeo >= 0.0:
		_parpadeo += delta
		var k: float = _ritmo["duracion"]
		if _parpadeo < 0.04 * k:
			_aplicar("entrecerrados")
		elif _parpadeo < 0.11 * k:
			_aplicar("cerrados")
		elif _parpadeo < 0.15 * k:
			_aplicar("entrecerrados")
		else:
			_parpadeo = -1.0
			_aplicar(_base if _hasta <= 0.0 else expresion)
		return
	if expresion in SIN_PARPADEO or heroe.get("_muerta"):
		return
	_t_parpadeo -= delta
	if _t_parpadeo <= 0.0:
		_t_parpadeo = _azar.randf_range(_ritmo["cada"].x, _ritmo["cada"].y)
		if _azar.randf() < _ritmo["doble"]:
			_t_parpadeo = 0.22 * _ritmo["duracion"]       # a veces, doble parpadeo
		_parpadeo = 0.0


# Siguiente parpadeo (para las pruebas): segundos que faltan y ritmo de este héroe.
func ritmo_parpadeo() -> Dictionary:
	return _ritmo


# ---------------------------------------------------------------- clips
# Reproduce un clip del contrato (con fundido) y devuelve su duración (0 si no existe).
func reproducir(clip: String, fundido := 0.15, velocidad := 1.0) -> float:
	if anim == null or not anim.has_animation(clip):
		return 0.0
	if heroe.get("esperas") != null:
		heroe.esperas.cortar()
	anim.play(clip, fundido)
	anim.speed_scale = velocidad
	anim.seek(0.0, true)
	return anim.get_animation(clip).length / maxf(velocidad, 0.01)


# Conversación: un gesto distinto del anterior, o ninguno (1 de cada 3). Devuelve el clip elegido («» si ninguno).
func hablar(animo := "") -> String:
	var opciones := ["hablar", "hablar_b", "asentir", ""]
	opciones.erase(_ultimo_gesto)
	var clip: String = opciones[_azar.randi() % opciones.size()]
	_ultimo_gesto = clip
	var expr: String = ANIMOS.get(animo, "")
	if clip != "" and heroe.marcha_actual() == "":
		var d := reproducir(clip, 0.25)
		if d > 0.0:
			get_tree().create_timer(d).timeout.connect(_volver_reposo.bind(clip), CONNECT_ONE_SHOT)
	if expr != "":
		poner_expresion(expr, 2.2)
	return clip


func _volver_reposo(clip: String) -> void:
	if is_instance_valid(heroe) and anim.assigned_animation == clip and not heroe.get("_muerta"):
		heroe.reposo()


# ---------------------------------------------------------------- materiales
func _materiales(n: Node) -> void:
	if not ResourceLoader.exists(SHADER):
		return
	var sh: Shader = load(SHADER)
	var ajuste: Dictionary = MATERIAL.get(nombre_heroe, {})
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi == cara or not mi.get_parent() is Skeleton3D:
			continue
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(s)
			if not m is BaseMaterial3D:
				continue
			var sm := ShaderMaterial.new()
			sm.shader = sh
			sm.set_shader_parameter("albedo_tex", m.albedo_texture)
			sm.set_shader_parameter("color", m.albedo_color)
			if m.normal_enabled and m.normal_texture != null:
				sm.set_shader_parameter("normal_tex", m.normal_texture)
				sm.set_shader_parameter("tiene_normal", true)
				sm.set_shader_parameter("relieve", m.normal_scale * float(ajuste.get("relieve", 1.0)))
			if m.roughness_texture != null:
				sm.set_shader_parameter("rugosidad_tex", m.roughness_texture)
				sm.set_shader_parameter("canal_rugosidad", _canal(m.roughness_texture_channel))
				sm.set_shader_parameter("tiene_rugosidad", true)
			if m.metallic_texture != null:
				sm.set_shader_parameter("metal_tex", m.metallic_texture)
				sm.set_shader_parameter("canal_metal", _canal(m.metallic_texture_channel))
				sm.set_shader_parameter("tiene_metal", true)
			sm.set_shader_parameter("rugosidad", m.roughness)
			sm.set_shader_parameter("metal", m.metallic)
			sm.set_shader_parameter("borde", ajuste.get("borde", 0.2))
			sm.set_shader_parameter("tinte_borde", PIEL["tinte_borde"])
			sm.set_shader_parameter("rugosidad_mate", PIEL["rugosidad"])
			sm.set_shader_parameter("especular_mate", PIEL["especular"])
			sm.set_shader_parameter("reflejo", ajuste.get("reflejo", 0.5))
			mi.set_surface_override_material(s, sm)
			materiales.append(sm)


# El reflejo del metal sigue al ambiente de la región: el color del relleno (ambient_light) hace de cielo, una versión
# oscura y cálida de suelo, y su energía escala el reflejo (en una cueva oscura el metal no brilla solo). Se mira al
# entrar y cada 3 s (por si la escena cambia de ambiente); solo se escribe si cambia.
func _leer_entorno() -> void:
	_t_entorno = 3.0
	if heroe == null or not heroe.is_inside_tree():
		return
	var w := heroe.get_world_3d()
	var env: Environment = w.environment if w != null else null
	if env == null:
		var cam := heroe.get_viewport().get_camera_3d()
		if cam != null and cam.environment != null:
			env = cam.environment
	if env == null and w != null:
		env = w.fallback_environment
	if env == null or env == _entorno_visto:
		return
	_entorno_visto = env
	var amb: Color = env.ambient_light_color
	var e: float = env.ambient_light_energy
	if env.ambient_light_source == Environment.AMBIENT_SOURCE_DISABLED:
		e = 0.0
	var cielo := amb.lerp(Color(1, 1, 1), 0.35)
	var suelo := Color(amb.r * 0.45 + 0.08, amb.g * 0.4 + 0.06, amb.b * 0.35 + 0.04)
	var energia := clampf(0.45 + e * 1.6, 0.45, 1.25)
	for sm in materiales:
		sm.set_shader_parameter("cielo", cielo)
		sm.set_shader_parameter("suelo", suelo)
		sm.set_shader_parameter("energia_entorno", energia)


func _canal(c: int) -> Vector4:
	match c:
		BaseMaterial3D.TEXTURE_CHANNEL_RED: return Vector4(1, 0, 0, 0)
		BaseMaterial3D.TEXTURE_CHANNEL_GREEN: return Vector4(0, 1, 0, 0)
		BaseMaterial3D.TEXTURE_CHANNEL_BLUE: return Vector4(0, 0, 1, 0)
		BaseMaterial3D.TEXTURE_CHANNEL_ALPHA: return Vector4(0, 0, 0, 1)
	return Vector4(1, 1, 1, 0) / 3.0
