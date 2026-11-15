extends "res://prototipos/vista3d.gd"
# MUESTRA GRÁFICA EXPERIMENTAL: una calle de Oakhaven (V12, 15/11). EN PRUEBAS y APAGADA: solo se entra desde el banco
# de pruebas de Auditoría («Muestra gráfica: una calle de Oakhaven (en pruebas)», banco_pruebas.gd, EXPLORAR). Ninguna
# escena del juego la carga ni la enlaza; Oakhaven 3D no cambia. No guarda partida, no hay vecinos ni misiones: es una
# pieza para juzgar el salto de calidad gráfica (docs/v12/MUESTRA_CALLE_OAKHAVEN.md).
#
# Qué hay: dos fachadas con vuelos de entramado, aleros hondos, chimeneas, postigos y escalones; LA PUERTA (arco de
# dovelas, hoja verde de tablas, tejadillo, farol, macetas y banco) y LA ESQUINA (torreón en voladizo con tejado cónico de
# pizarra, guardacantón, hornacina con velas y farol en diagonal); el callejón con escalones, ropa tendida y un patio al
# sol al fondo; empedrado irregular de losas con juntas que se deshace en tierra; matas en las juntas, al pie de los muros
# y en los rincones; barriles, cajones, macetas, carretilla, faroles, letrero, leña. Y Kael andando por ella.
#
# Cómo se dibuja (barato a propósito, para el Redmi): la luz está HORNEADA en Blender (fuente/crear_calle.py: sol bajo de
# la tarde, cielo frío, rebotes y faroles) en un mapa de luz; los materiales no calculan luz (calle_estatico.gdshader).
# Kael sí se ilumina en tiempo real, con el MISMO sol y el mismo cielo del horneado (calle_luz.json) y apagando su sol
# cuando pisa la sombra de las casas (las «sondas»: una rejilla de cuánto sol y cuánto cielo llega a 1 m del suelo); su
# sombra es una mancha de contacto y una sombra larga hacia donde la echa el sol de la tarde.
#
# Cámara: elevada e inclinada, sin girar (como la exploración 3D), algo más baja que la de Oakhaven para que se vean
# las fachadas enteras: 10,8 m sobre Kael, 14,2 m al sur, 25° hacia abajo; sigue a Kael en x dentro de CAMARA_X.
#
# Modos (Engine «muestra_modo», solo para las capturas de cada pasada): «gris» (sin texturas, luz en tiempo real),
# «materiales» (texturas, luz en tiempo real) y «luz» (lo de verdad: texturas y luz horneada). Por defecto, «luz».

const RAIZ := "res://zonas3d/muestra_calle/"
const MODELO := RAIZ + "modelos/calle.glb"
const LUZ_JSON := RAIZ + "modelos/calle_luz.json"
const SH_ESTATICO := preload("res://zonas3d/muestra_calle/calle_estatico.gdshader")
const SH_HOJA := preload("res://zonas3d/muestra_calle/calle_hoja.gdshader")
const SH_BRILLO := preload("res://zonas3d/muestra_calle/calle_brillo.gdshader")
const SH_VERTICE := preload("res://zonas3d/muestra_calle/calle_vertice.gdshader")
const TEXTURA_DE := {"piedra": "piedra", "tierra": "tierra", "revoque": "revoque", "madera": "madera", "tejas": "tejas",
	"sillar": "sillar", "hierro": "piedra", "tela": "tela", "barro": "revoque", "hoja": "hoja"}

const INICIO := Vector3(-9.5, 0.0, 1.0)
const SITIO_FOTO := Vector3(-1.0, 0.0, 0.9)        # el de las capturas (antes/después: la misma cámara respecto a Kael)
const OFFSET_CAMARA := Vector3(0.0, 10.8, 14.2)
const INCLINACION := 25.0
const CAMPO := 38.0
const CAMARA_X := Vector2(-3.5, 3.5)
const ANDABLE := Rect2(-13.2, -7.3, 26.4, 10.5)   # x, z: la calle, la boca del callejón y su rellano
const CALLEJON_X := 1.55
# (15/11, corrección 1) En el callejón la cámara no se va con Kael hacia las paredes: el vuelo, el poste de esquina y el
# alero de la casa del oeste (y los de la del este) le tapaban un costado arriba. Se queda en el eje (x = 0), sin girar
# ni cambiar altura, inclinación o campo; entra de la boca (z −2,0: peso 0) al primer escalón (z −3,4: peso 1) y se
# apaga fuera del ancho del callejón (|x| 1,8 → 2,6). En la calle, igual que antes.
const CALLEJON_EJE_X := 0.0
const CALLEJON_ENTRA := Vector2(2.0, 3.4)     # −z: de la boca al primer escalón
const CALLEJON_LADO := Vector2(1.8, 2.6)      # |x|: dentro del callejón → en la calle
# (15/11, corrección 2) Tono (lineal, máximo 1) de la luz horneada en la sombra del callejón (calle_luz_1024.png: B/R
# 1,11-1,22). El «cielo_color» del json es el cielo puro de una placa sin suelo (B/R 1,79 lineal): sin los rebotes
# cálidos, Kael salía muy azul en la sombra. Se pesa por el SOL de la sonda: al sol (sol 1), Kael queda exactamente
# como antes; en sombra (sol 0), el tono de la sombra horneada con la MISMA luminancia (se conserva sol/sombra).
const TONO_SOMBRA := Color(0.862, 0.836, 1.0)
# Vistas fijas para las capturas: [nombre, posición, punto al que mira, campo] (iguales en fuente/crear_calle.py)
const VISTAS := [
	["vista_puerta", Vector3(-6.2, 3.4, 5.6), Vector3(-6.4, 1.6, -2.4), 38.0],
	["vista_esquina", Vector3(11.2, 4.6, 6.4), Vector3(8.6, 3.0, -2.0), 38.0],
	["vista_callejon", Vector3(0.4, 3.0, 6.0), Vector3(0.0, 1.6, -5.0), 38.0],
]
# Lo que cambia con el perfil (prototipos/calidad_proto.gd): el mapa de luz, el viento, el brillo y el ambiente.
const MAPA_LUZ := {"bajo": 1024, "medio": 2048, "alto": 2048}

var brillo_sin_sombras := 1.0               # vista3d.gd: aquí no hace falta (la luz no depende de las sombras)
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var modo := "luz"
var luz: Dictionary = {}
var sol: DirectionalLight3D
var ambiente: Environment
var _sol_base := 1.0
var _amb_base := 0.5
var _sol_k := 1.0
var _cielo_k := 1.0
var _tono_cielo := Color(1, 1, 1)                # (corrección 2) el color del ambiente de antes (sRGB, máximo 1)
var materiales_sombra: Array = []           # los ShaderMaterial que dibujan la sombra de Kael
var calle: Node3D
var anclas := {}
var titulo: Label
var materiales_usados: Array = []
var tex_luz_usada := ""                     # el mapa de luz cargado (para las pruebas)


static func camara_muestra(c: Camera3D, k: Vector3) -> void:
	c.projection = Camera3D.PROJECTION_PERSPECTIVE
	c.global_position = k + OFFSET_CAMARA
	c.global_rotation = Vector3(deg_to_rad(-INCLINACION), 0.0, 0.0)
	c.fov = CAMPO


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	modo = str(Engine.get_meta("muestra_modo", "luz"))
	luz = _leer_luz()
	super()
	info.visible = false
	_crear_interfaz()
	_colocar_kael(INICIO)
	_crear_sombra_kael()
	_sombras_kael()
	if has_node("/root/Sonido"):
		Sonido.oyente_3d(kael, cam)
		Sonido.pasos_3d(kael, func(_p): return "piedra")


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


func _leer_luz() -> Dictionary:
	if not FileAccess.file_exists(LUZ_JSON):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(LUZ_JSON))
	return d if d is Dictionary else {}


# ================================================================= la luz de la tarde (la misma que la del horneado)

func _crear_ambiente() -> void:
	ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.86, 0.80, 0.70)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var cielo: Array = luz.get("cielo_color", [0.30, 0.34, 0.45])
	var c_cielo := Color(cielo[0], cielo[1], cielo[2])
	_amb_base = maxf(c_cielo.r, maxf(c_cielo.g, c_cielo.b))
	_tono_cielo = Color(c_cielo.r / _amb_base, c_cielo.g / _amb_base, c_cielo.b / _amb_base)
	ambiente.ambient_light_color = _tono_cielo
	ambiente.ambient_light_energy = _amb_base
	ambiente.fog_enabled = true                                   # bruma cálida, lejos: profundidad
	ambiente.fog_light_color = Color(0.86, 0.76, 0.62)
	ambiente.fog_density = 0.0025
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.tonemap_exposure = 0.86
	ambiente.adjustment_enabled = true
	ambiente.adjustment_saturation = 1.12
	ambiente.adjustment_contrast = 1.12
	if nombre_perfil == "alto":
		ambiente.glow_enabled = true                              # el halo de los faroles y de las ventanas
		ambiente.glow_intensity = 0.35
		ambiente.glow_bloom = 0.02
		ambiente.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = ambiente
	add_child(we)
	sol = DirectionalLight3D.new()
	sol.name = "Sol"
	var hs: Array = luz.get("hacia_sol", [-0.73, 0.45, 0.51])
	var h := Vector3(hs[0], hs[1], hs[2]).normalized()
	sol.look_at_from_position(Vector3.ZERO, -h, Vector3.UP if absf(h.y) < 0.99 else Vector3.FORWARD)
	var sc: Array = luz.get("sol_color_medido", [1.0, 0.8, 0.6])
	var c := Color(sc[0], sc[1], sc[2])
	_sol_base = maxf(c.r, maxf(c.g, c.b))
	if _sol_base <= 0.0:
		_sol_base = 1.0
	sol.light_color = Color(c.r / _sol_base, c.g / _sol_base, c.b / _sol_base)
	sol.light_energy = _sol_base
	sol.shadow_enabled = modo != "luz" and bool(perfil.get("sombras", false))   # solo en las pasadas sin hornear
	sol.directional_shadow_max_distance = 40.0
	add_child(sol)


# ================================================================= la calle (el GLB de Blender) y sus materiales

func _crear_escenario() -> void:
	if not ResourceLoader.exists(MODELO):
		push_warning("Muestra de calle: falta %s (fuente/crear_calle.py)" % MODELO)
		return
	calle = (load(MODELO) as PackedScene).instantiate()
	calle.name = "Calle"
	add_child(calle)
	var tex_luz: Texture2D = null
	var res := int(MAPA_LUZ.get(nombre_perfil, 2048))
	var ruta_luz := RAIZ + "modelos/calle_luz_%d.png" % res
	if modo == "luz" and ResourceLoader.exists(ruta_luz):
		tex_luz = load(ruta_luz)
		tex_luz_usada = ruta_luz
	var cache := {}
	for mi in calle.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sol.shadow_enabled \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(s)
			var nombre := orig.resource_name if orig != null else ""
			var vertice := String(m.name) == "piezas"             # (luz en los vértices, no en el mapa)
			var clave := ("v:" if vertice else "") + nombre
			if not cache.has(clave):
				cache[clave] = _material(nombre, tex_luz, vertice)
				materiales_usados.append(clave)
			m.set_surface_override_material(s, cache[clave])
	for n in calle.find_children("*", "", true, false):
		var nodo := n as Node3D
		if nodo == null:
			continue
		if nodo.name.begins_with("choque_"):
			_choque(nodo)
		elif nodo.name.begins_with("ancla_"):
			anclas[String(nodo.name).trim_prefix("ancla_")] = nodo.global_position
	_suelo_choque()
	_atmosfera()


func _material(nombre: String, tex_luz: Texture2D, vertice := false) -> Material:
	var tex: Texture2D = null
	if TEXTURA_DE.has(nombre):
		var ruta: String = RAIZ + "texturas/" + TEXTURA_DE[nombre] + ".png"
		if ResourceLoader.exists(ruta):
			tex = load(ruta)
	if nombre == "brillo":
		var b := ShaderMaterial.new()
		b.shader = SH_BRILLO
		b.set_shader_parameter("energia", 1.45 if nombre_perfil == "alto" else 1.2)
		b.set_shader_parameter("usar_color_fijo", vertice)   # (15/11) los cristales de los faroles de pie («piezas»)
		return b
	if modo != "luz":                                              # pasadas sin hornear: luz en tiempo real
		var s := StandardMaterial3D.new()
		s.vertex_color_use_as_albedo = true
		if modo == "materiales" and tex != null:
			s.albedo_texture = tex
		s.roughness = 1.0
		s.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		if nombre == "hoja":
			s.cull_mode = BaseMaterial3D.CULL_DISABLED
		return s
	var e := float(luz.get("escala", 1.0))
	var m := ShaderMaterial.new()
	if nombre == "hoja" or vertice:
		m.shader = SH_HOJA if nombre == "hoja" else SH_VERTICE
		m.set_shader_parameter("textura", tex)
		m.set_shader_parameter("luz_escala", e)
		if nombre == "hoja":
			m.set_shader_parameter("viento", 1.0)
		materiales_sombra.append(m)
		return m
	m.shader = SH_ESTATICO
	m.set_shader_parameter("textura", tex)
	m.set_shader_parameter("luz", tex_luz)
	m.set_shader_parameter("luz_escala", e)
	m.set_shader_parameter("solo_luz", Engine.has_meta("muestra_solo_luz"))
	materiales_sombra.append(m)
	return m


func _choque(n: Node3D) -> void:
	var t := n.global_transform
	var tam := t.basis.get_scale() * 2.0
	var cuerpo := StaticBody3D.new()
	cuerpo.name = String(n.name).replace("choque_", "Choque")
	cuerpo.transform = Transform3D(t.basis.orthonormalized(), t.origin)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(absf(tam.x), absf(tam.y), absf(tam.z))
	col.shape = caja
	cuerpo.add_child(col)
	add_child(cuerpo)


# El suelo que se pisa: una caja con la cara de arriba a 6 cm (lo alto de las losas: los pies no se hunden).
func _suelo_choque() -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "SueloChoque"
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(60.0, 0.4, 30.0)
	col.shape = caja
	col.position = Vector3(0.0, 0.06 - 0.2, -3.0)
	cuerpo.add_child(col)
	add_child(cuerpo)


# Lo que hace el aire: humo de las chimeneas y motas de polvo al sol en el callejón. SOLO en el perfil alto: en bajo y
# medio (escala 3D < 1) las capas transparentes de esta escena no se veían bien en Compatibility (15/11; ver la sombra de
# Kael) y, además, son el único sobredibujo transparente de la calle: fuera del perfil del Redmi.
func _atmosfera() -> void:
	if modo != "luz" or nombre_perfil != "alto":
		return
	for k in anclas:
		if String(k).begins_with("humo_"):
			add_child(_humo(anclas[k]))
	add_child(_motas(Vector3(0.0, 2.2, -4.5), Vector3(1.4, 1.6, 2.0)))


func _humo(p: Vector3) -> CPUParticles3D:
	var h := CPUParticles3D.new()
	h.name = "Humo"
	h.position = p
	h.amount = 10
	h.lifetime = 4.0
	h.preprocess = 4.0
	h.direction = Vector3(0.35, 1.0, 0.1)
	h.spread = 12.0
	h.initial_velocity_min = 0.35
	h.initial_velocity_max = 0.55
	h.gravity = Vector3(0.12, 0.05, 0.0)
	h.scale_amount_min = 0.5
	h.scale_amount_max = 0.9
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.4))
	curva.add_point(Vector2(1.0, 1.6))
	h.scale_amount_curve = curva
	var q := QuadMesh.new()
	q.size = Vector2(0.6, 0.6)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _textura_redonda()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.albedo_color = Color(0.92, 0.88, 0.84, 0.28)
	q.material = m
	h.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.15, Color(1, 1, 1, 1))
	g.add_point(0.7, Color(1, 1, 1, 0.5))
	h.color_ramp = g
	return h


func _motas(c: Vector3, ext: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Motas"
	p.position = c
	p.amount = 24
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3(0.2, 0.3, 0.0)
	p.spread = 180.0
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.08
	p.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = _textura_redonda()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.albedo_color = Color(1.0, 0.86, 0.6, 0.7)
	q.material = m
	p.mesh = q
	return p


var _tex_redonda: ImageTexture


# Una mancha redonda blanca que se desvanece hacia el borde (alfa suave): sombra de Kael, humo y motas. Hecha a mano
# (una imagen de 64², sin mipmaps): quien la usa pone el filtro LINEAR. Con el filtro por defecto (con mipmaps) la textura
# queda «incompleta» en Compatibility y no se ve nada; con mipmaps generados, la pantalla salía en blanco (15/11, probado).
func _textura_redonda() -> ImageTexture:
	if _tex_redonda == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
				var a := clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
		_tex_redonda = ImageTexture.create_from_image(img)
	return _tex_redonda


# ================================================================= Kael en la calle

# Su sombra: una mancha de contacto bajo los pies y una sombra larga hacia donde la echa el sol horneado, DENTRO de los
# sombreados del suelo, las piezas y la vegetación (calle_*.gdshader, sombra_kael): aquí solo se les pasa dónde está
# Kael. La larga se apaga cuando pisa la sombra de las casas (las sondas). Sin sombras en tiempo real ni transparencias:
# igual en todos los perfiles.
func _crear_sombra_kael() -> void:
	var hs: Array = luz.get("hacia_sol", [-0.73, 0.45, 0.51])
	var lejos := -Vector2(hs[0], hs[2]).normalized()
	var elev := asin(clampf(float(hs[1]), -1.0, 1.0))
	var largo := clampf(1.45 / tan(maxf(elev, 0.2)), 1.2, 3.4)       # (lo que mide la sombra de 1,45 m de Kael, sin pelo)
	for m in materiales_sombra:
		m.set_shader_parameter("sombra_dir", lejos)
		m.set_shader_parameter("sombra_largo", largo)


func _colocar_kael(p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 4.0, 0))
	var r: Dictionary = get_world_3d().direct_space_state.intersect_ray(q) if is_inside_tree() else {}
	if not r.is_empty():
		p.y = r["position"].y
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	_colocar_camara(1.0)
	_luz_kael(1.0)
	_sombras_kael()


func _prohibido(p: Vector3) -> bool:
	if not ANDABLE.has_point(Vector2(p.x, p.z)):
		return true
	return p.z < -2.6 and absf(p.x) > CALLEJON_X                 # detrás de la línea de fachadas, solo el callejón


func _colocar_camara(peso: float) -> void:
	if cam == null or kael == null:
		return
	var k := kael.global_position
	var mx := lerpf(clampf(k.x, CAMARA_X.x, CAMARA_X.y), CALLEJON_EJE_X, peso_callejon(k))   # (corrección 1)
	var meta := Vector3(mx, 0.0, SITIO_FOTO.z + minf(0.0, k.z - SITIO_FOTO.z) * 0.55)
	meta.y = k.y * 0.6
	foco = foco.lerp(meta, peso)
	camara_muestra(cam, foco)


# (corrección 1) 0 en la calle, 1 dentro del callejón: la cámara va al eje del callejón.
func peso_callejon(k: Vector3) -> float:
	return smoothstep(CALLEJON_ENTRA.x, CALLEJON_ENTRA.y, -k.z) 		* (1.0 - smoothstep(CALLEJON_LADO.x, CALLEJON_LADO.y, absf(k.x)))


static func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


# Las sondas (calle_luz.json): cuánto sol y cuánto cielo hay a 1 m del suelo donde está Kael (interpolado).
func sonda(p: Vector3) -> Vector2:
	var s: Dictionary = luz.get("sondas", {})
	if s.is_empty():
		return Vector2.ONE
	var o: Array = s["origen"]
	var paso: float = s["paso"]
	var nx: int = s["nx"]
	var nz: int = s["nz"]
	var fx := clampf((p.x - float(o[0])) / paso, 0.0, nx - 1.001)
	var fz := clampf((p.z - float(o[1])) / paso, 0.0, nz - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var r := Vector2.ZERO
	for par in [["sol", 0], ["cielo", 1]]:
		var a: Array = s[par[0]]
		var v00: float = a[iz * nx + ix]
		var v10: float = a[iz * nx + ix + 1]
		var v01: float = a[(iz + 1) * nx + ix]
		var v11: float = a[(iz + 1) * nx + ix + 1]
		r[par[1]] = lerpf(lerpf(v00, v10, tx), lerpf(v01, v11, tx), tz)
	return r


func _luz_kael(peso: float) -> void:
	if kael == null or sol == null or modo != "luz":
		return
	var v := sonda(kael.global_position)
	_sol_k = lerpf(_sol_k, v.x, peso)
	_cielo_k = lerpf(_cielo_k, v.y, peso)
	sol.light_energy = _sol_base * _sol_k
	var energia := _amb_base * (0.55 + 0.45 * _cielo_k)          # (la de antes)
	var w := 1.0 - clampf(_sol_k, 0.0, 1.0)                       # (corrección 2) 0 al sol, 1 en sombra
	if w <= 0.001:
		ambiente.ambient_light_color = _tono_cielo
		ambiente.ambient_light_energy = energia
		return
	var antes := _tono_cielo.srgb_to_linear()                     # Godot pasa el color del ambiente a lineal
	var t := antes.lerp(TONO_SOMBRA, w)
	var m := maxf(t.r, maxf(t.g, t.b))
	t = Color(t.r / m, t.g / m, t.b / m)
	ambiente.ambient_light_color = t.linear_to_srgb()
	ambiente.ambient_light_energy = energia * _lum(antes) / _lum(t)   # misma luminancia que antes


func _sombras_kael() -> void:
	if kael == null:
		return
	var p := kael.global_position
	var s := clampf(_sol_k, 0.0, 1.0)
	var larga := 0.62 * s                       # (corrección 3) deja el suelo al tono de las sombras horneadas
	var contacto := lerpf(0.70, 0.78, s)        # al sol más marcado; en sombra sigue fuerte (la señal de apoyo)
	for m in materiales_sombra:
		m.set_shader_parameter("kael_pos", p)
		m.set_shader_parameter("sombra_fuerza", larga)
		m.set_shader_parameter("contacto_fuerza", contacto)
		m.set_shader_parameter("sol_kael", s)


func _process(delta: float) -> void:
	super(delta)
	_luz_kael(1.0 - exp(-6.0 * delta))
	_sombras_kael()


# El panel del prototipo trae bancos de medida de Pastos Verdes: aquí solo CAL y RND.
func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _crear_interfaz() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 40
	add_child(capa)
	titulo = Label.new()
	titulo.text = "Muestra gráfica · una calle de Oakhaven (en pruebas) · perfil %s" % nombre_perfil
	titulo.position = Vector2(250, 40)   # (15/11) debajo de «PARTIDA DE PRUEBA» y del contador de FPS (y 4-26)
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84))
	titulo.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.06, 0.85))
	titulo.add_theme_constant_override("outline_size", 6)
	capa.add_child(titulo)
	if Engine.has_meta("muestra_sin_titulo"):
		titulo.visible = false
