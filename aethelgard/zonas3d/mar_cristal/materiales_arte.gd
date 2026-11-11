extends RefCounted
# Arte del Mar de Cristal (V12, gráficos): modelos, materiales y efectos del primer sector, para que la región
# (zonas3d/mar_cristal_3d.gd, del coordinador) los ponga en su sitio. Todo con funciones estáticas: no hace falta
# instanciar nada.
#
#   const Arte := preload("res://zonas3d/mar_cristal/materiales_arte.gd")
#   var perfil := Arte.perfil()                            # prototipos/calidad_proto.gd → datos()
#   var arco := Arte.modelo("ruinas_arco", perfil)          # Node3D con los materiales ya puestos (alto o ligero)
#   region.add_child(arco); arco.position = Vector3(45, 0, 18)
#   region.add_child(Arte.choques(arco))                    # (opcional) StaticBody3D con las cajas del GLB, ya colocado
#   suelo.material_override = Arte.mat_arena(perfil)        # el suelo con el mismo sombreado que la arena de las piezas
#   var arrastre := Arte.arena_arrastrada(perfil)           # cintas de arena + granos; moverlo con Kael (x, z)
#   Arte.intensidad_viento(region, 1.0)                     # tormenta (0,25 = calma); también oculta/enseña el arrastre
#   Arte.liberar()                                          # al salir de la región (suelta la caché de materiales)
#
# Modelos (res://modelos/desierto/<id>.glb, de fuente/crear_desierto.py): en metros, el origen en la base, mirando al
# sur. Lo que queda por debajo de y = 0 está enterrado (sirve para hundir la pieza). La versión «_ligero» (medio y bajo)
# solo existe cuando ahorra; si no, se usa la misma. Ver PIEZAS (y el informe docs/memory/agents/graficos_v12_desierto.md).
# Dentro de cada GLB: los nodos «caja_<i>_<ancho>_<fondo>_<alto>» (cm) son choques de caja con la base en su posición
# y los «ancla_<nombre>» son posiciones con nombre (anclas()).
#
# Materiales por nombre de superficie (los pone aplicar_materiales()):
#   base    colores de vértice con grano (StandardMaterial3D: vista3d.gd sabe volverlo medio transparente si tapa a Kael)
#   brillo  luz propia (brasas, farolillo)
#   vidrio  el vidrio del Mar de Cristal (shaders/desierto/vidrio.gdshader)
#   arena   montones de arena pegados a las piezas: el material del suelo (shaders/desierto/arena.gdshader)
#   tela    telas al viento (shaders/desierto/tela.gdshader)
#   hojas   palmas y juncos (shaders/desierto/planta.gdshader)
#
# Perfiles: el «alto» (el único con «refraccion») lleva los destellos de vidrio de la arena y puede llevar ondas de
# calor (calor()); el medio y el bajo usan los modelos ligeros y menos cintas y granos; el bajo, sin relieve en la
# piedra. El perfil alto no se rebaja para que quepan los otros.

const CARPETA := "res://modelos/desierto/"
const SH_ARENA := "res://shaders/desierto/arena.gdshader"
const SH_TELA := "res://shaders/desierto/tela.gdshader"
const SH_PLANTA := "res://shaders/desierto/planta.gdshader"
const SH_ARRASTRE := "res://shaders/desierto/arena_arrastrada.gdshader"
const SH_CALOR := "res://shaders/desierto/calor.gdshader"
const SH_VIDRIO := "res://shaders/desierto/vidrio.gdshader"

# id → qué es (para la región y las pruebas)
const PIEZAS := {
	"ruinas_arco": "arco medio enterrado (5,4 m de ancho, 6,3 de alto; enterrado hasta -2,4 m); arena aparte en «ruinas_arco_arena»",
	"ruinas_columna_a": "columna entera con capitel (4,8 m)",
	"ruinas_columna_b": "columna rota a media altura y un tambor caído al este",
	"ruinas_columna_c": "columna caída en el suelo (de oeste a este, 5 m)",
	"ruinas_columna_d": "tocón vitrificado del que brotan cristales",
	"ruinas_muro": "tramo de muro derruido (5 m)",
	"trampilla": "trampilla sellada con la estrella de vidrio; «trampilla_tapa» gira en x (bisagra al norte) para abrirla",
	"caravana_carro": "carro volcado medio enterrado, con la lona rota",
	"caravana_cajas": "cajas (una abierta), saco y ánforas",
	"caravana_barril": "barril volcado",
	"caravana_tela": "estandarte roto clavado en la arena",
	"tienda_a": "jaima grande de rayas (4,2 × 3,2 m), entrada al sur",
	"tienda_b": "tienda cónica añil con banderín",
	"fogata": "fogata con trébede y olla; el fuego, en «ancla_fuego»",
	"palmera_a": "palmera alta (7,5 m)",
	"palmera_b": "palmera inclinada con hojas secas (6 m)",
	"juncos": "mata de juncos y espadañas",
	"roca_canon_a": "peñón de estratos (9 m)",
	"roca_canon_b": "paño de pared del cañón (12 m de norte a sur, 7 de alto)",
	"roca_canon_c": "bloque caído y pedregal (3 m)",
	"roca_canon_d": "chimenea de hada (6 m)",
	"roca_cobijo": "roca saliente: el origen es el sitio del cobijo; la masa, al oeste; el saliente en «roca_cobijo_techo»",
	"huesos_costillas": "costillar colosal (16 m de oeste a este) con el cráneo al este",
	"esqueleto": "esqueleto sentado; la espalda al norte (la pared del nicho en z = -0,35); la nota en «ancla_nota»",
}

const VIENTO_CALMA := 0.25
const DIR_VIENTO := Vector2(1.0, -0.25)   # hacia el este, algo al norte (las colas de arena de las piezas, igual)

static var _cache := {}
static var _viento := VIENTO_CALMA


# ---------------------------------------------------------------- perfil

static func perfil() -> Dictionary:
	return load("res://prototipos/calidad_proto.gd").datos()


# ¿Detalle máximo? El perfil «alto» es el único con refracción (y no tiene recortes dinámicos). Para pruebas A/B,
# Engine.set_meta("calidad_extra", {"desierto_alto": false}) lo cambia sin tocar lo demás.
static func detalle_alto(p: Dictionary) -> bool:
	return bool(p.get("desierto_alto", p.get("refraccion", false)))


# ---------------------------------------------------------------- modelos

static func ruta(id: String, p: Dictionary) -> String:
	var alto := CARPETA + id + ".glb"
	if detalle_alto(p):
		return alto
	var ligero := CARPETA + id + "_ligero.glb"
	return ligero if ResourceLoader.exists(ligero) else alto


# La pieza lista para añadir a la escena. Con «espejismo», todas sus superficies son el material del espejismo
# (mat_espejismo(): ondula y se transparenta; su parámetro «espejismo» va de 1 a 0).
static func modelo(id: String, p: Dictionary, espejismo := false) -> Node3D:
	var r := ruta(id, p)
	var escena := load(r) as PackedScene
	if escena == null:
		push_warning("Mar de Cristal: no se pudo cargar %s" % r)
		return Node3D.new()
	var n := escena.instantiate() as Node3D
	n.name = id
	aplicar_materiales(n, p, espejismo)
	return n


static func aplicar_materiales(raiz: Node, p: Dictionary, espejismo := false) -> void:
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var malla: Mesh = (mi as MeshInstance3D).mesh
		if malla == null:
			continue
		for i in malla.get_surface_count():
			var m: Material = mat_espejismo() if espejismo else _por_nombre(malla.surface_get_material(i), p)
			if m != null:
				(mi as MeshInstance3D).set_surface_override_material(i, m)


static func _por_nombre(m: Material, p: Dictionary) -> Material:
	var nombre := m.resource_name if m != null else "base"
	match nombre:
		"brillo":
			return mat_brillo()
		"vidrio":
			return mat_vidrio()
		"arena":
			return mat_arena(p)
		"tela":
			return mat_tela()
		"hojas":
			return mat_planta()
	return mat_base(p)


# Choques de caja de la pieza (nodos «caja_…» del GLB), en un StaticBody3D colocado donde está la pieza: añadirlo al
# mismo padre DESPUÉS de colocarla (copia su transformación).
static func choques(n: Node3D) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = String(n.name) + "_choque"
	cuerpo.transform = n.transform
	for c in n.find_children("caja_*", "Node3D", true, false):
		var partes := String(c.name).split("_")
		if partes.size() < 5:
			continue
		var tam := Vector3(float(partes[2]), float(partes[4]), float(partes[3])) / 100.0
		var forma := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = tam
		forma.shape = caja
		forma.position = _pos_relativa(n, c as Node3D) + Vector3(0, tam.y * 0.5, 0)
		cuerpo.add_child(forma)
	return cuerpo


static func _pos_relativa(raiz: Node3D, n: Node3D) -> Vector3:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != raiz:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t.origin


# Posiciones con nombre de la pieza (nodos «ancla_…»), en sus coordenadas locales: {"fuego": Vector3(…), …}
static func anclas(n: Node3D) -> Dictionary:
	var d := {}
	for c in n.find_children("ancla_*", "Node3D", true, false):
		d[String(c.name).substr(6)] = _pos_relativa(n, c as Node3D)
	return d


# ---------------------------------------------------------------- texturas (generadas: nada de imágenes)

static func ruido() -> NoiseTexture2D:
	if _cache.has("ruido"):
		return _cache["ruido"]
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.035
	n.fractal_octaves = 3
	n.seed = 1712
	var t := NoiseTexture2D.new()
	t.width = 128
	t.height = 128
	t.seamless = true
	t.normalize = true
	t.generate_mipmaps = true
	t.noise = n
	_cache["ruido"] = t
	return t


static func _grano(relieve: bool) -> NoiseTexture2D:
	var clave := "grano_n" if relieve else "grano"
	if _cache.has(clave):
		return _cache[clave]
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.05
	n.fractal_octaves = 4
	n.seed = 1211
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.generate_mipmaps = true
	t.noise = n
	if relieve:
		t.as_normal_map = true
		t.bump_strength = 6.0
	else:
		var rampa := Gradient.new()
		rampa.colors = PackedColorArray([Color(0.78, 0.78, 0.78), Color(1.05, 1.05, 1.05)])
		t.color_ramp = rampa
	_cache[clave] = t
	return t


static func _shader(ruta_sh: String, defines: Array = []) -> Shader:
	var clave := "sh_%s_%s" % [ruta_sh, str(defines)]
	if _cache.has(clave):
		return _cache[clave]
	var s: Shader = load(ruta_sh)
	if not defines.is_empty():
		var codigo := s.code
		var pre := ""
		for d in defines:
			pre += "#define %s\n" % d
		var i := codigo.find("\n", codigo.find("shader_type"))
		var nuevo := Shader.new()
		nuevo.code = codigo.substr(0, i + 1) + pre + codigo.substr(i + 1)
		s = nuevo
	_cache[clave] = s
	return s


# ---------------------------------------------------------------- materiales (compartidos: uno de cada)

# Piedra, madera, hueso, cuero…: el color de los vértices con un grano fino (y relieve en medio y alto).
static func mat_base(p: Dictionary) -> StandardMaterial3D:
	var relieve := bool(p.get("relieve", true))
	var clave := "base_%s" % relieve
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true            # los colores de vértice van en sRGB (fuente/crear_desierto.py)
	m.albedo_texture = _grano(false)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.9
	m.roughness = 0.92
	m.metallic_specular = 0.2                 # piedra y madera secas: poco reflejo del cielo
	if relieve:
		m.normal_enabled = true
		m.normal_texture = _grano(true)
		m.normal_scale = 0.7
	_cache[clave] = m
	return m


static func mat_brillo() -> StandardMaterial3D:
	if _cache.has("brillo"):
		return _cache["brillo"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true            # los colores de vértice van en sRGB (fuente/crear_desierto.py)
	_cache["brillo"] = m
	return m


static func mat_vidrio() -> ShaderMaterial:
	if _cache.has("vidrio"):
		return _cache["vidrio"]
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_VIDRIO)
	_cache["vidrio"] = m
	return m


# La arena: para el suelo de la región y para los montones de las piezas (el mismo material: se funden).
static func mat_arena(p: Dictionary) -> ShaderMaterial:
	var alto := detalle_alto(p)
	var clave := "arena_%s" % alto
	if _cache.has(clave):
		return _cache[clave]
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_ARENA, ["BRILLOS"] if alto else [])
	m.set_shader_parameter("ruido", ruido())
	m.set_shader_parameter("dir_viento", DIR_VIENTO)
	m.set_shader_parameter("viento", _viento)
	_cache[clave] = m
	return m


static func mat_tela() -> ShaderMaterial:
	if _cache.has("tela"):
		return _cache["tela"]
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_TELA)
	m.set_shader_parameter("dir_viento", DIR_VIENTO)
	m.set_shader_parameter("viento", _viento)
	_cache["tela"] = m
	return m


static func mat_planta() -> ShaderMaterial:
	if _cache.has("planta"):
		return _cache["planta"]
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_PLANTA)
	m.set_shader_parameter("dir_viento", DIR_VIENTO)
	m.set_shader_parameter("viento", _viento)
	_cache["planta"] = m
	return m


# El espejismo (la palmera que tiembla y no está): modelo("palmera_a", perfil, true). Para revelarlo, bajar
# «espejismo» de 1 a 0 (por ejemplo con un Tween sobre este material) y ocultar la pieza al llegar a 0.
static func mat_espejismo() -> ShaderMaterial:
	if _cache.has("espejismo"):
		return _cache["espejismo"]
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_PLANTA, ["ESPEJISMO"])
	m.set_shader_parameter("dir_viento", DIR_VIENTO)
	m.set_shader_parameter("viento", _viento)
	_cache["espejismo"] = m
	return m


static func mat_arena_arrastrada() -> ShaderMaterial:
	if _cache.has("arrastre"):
		return _cache["arrastre"]
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_ARRASTRE)
	m.set_shader_parameter("ruido", ruido())
	m.set_shader_parameter("dir_viento", DIR_VIENTO)
	m.set_shader_parameter("intensidad", _viento)
	_cache["arrastre"] = m
	return m


# ---------------------------------------------------------------- efectos

# Arena arrastrada: un Node3D con las cintas (una malla, una llamada) y, si el perfil lo permite, los granos (CPU).
# Las cintas cubren un cuadrado de «lado» metros alrededor del nodo: moverlo con Kael (x, z; la y a la del suelo).
# Bajo: 5 cintas y 40 granos; medio: 8 y 80; alto: 12 y 130 (los granos siguen a «espuma» con sus recortes).
static func arena_arrastrada(p: Dictionary, lado := 34.0) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "ArenaArrastrada"
	var alto := detalle_alto(p)
	var n_cintas := 12 if alto else (8 if bool(p.get("sombras", false)) else 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var d := Vector3(DIR_VIENTO.x, 0, DIR_VIENTO.y).normalized()
	var lat := Vector3(-d.z, 0, d.x)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n_cintas:
		var c := Vector3(rng.randf_range(-0.5, 0.5) * lado, 0.0, rng.randf_range(-0.5, 0.5) * lado)
		var largo := rng.randf_range(14.0, 26.0)
		var ancho := rng.randf_range(0.9, 2.6)
		var y: float = [0.06, 0.18, 0.4, 0.75][i % 4] + rng.randf_range(0.0, 0.08)
		var a := rng.randf_range(0.6, 1.0)
		var pts := [c - d * largo * 0.5 - lat * ancho * 0.5, c + d * largo * 0.5 - lat * ancho * 0.5,
			c + d * largo * 0.5 + lat * ancho * 0.5, c - d * largo * 0.5 + lat * ancho * 0.5]
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(Color(1, 1, 1, a))
			st.set_uv(uvs[k])
			st.set_normal(Vector3.UP)
			st.add_vertex(pts[k] + Vector3(0, y, 0))
	var cintas := MeshInstance3D.new()
	cintas.name = "Cintas"
	cintas.mesh = st.commit()
	cintas.material_override = mat_arena_arrastrada()
	cintas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cintas.extra_cull_margin = 2.0
	raiz.add_child(cintas)
	var n_granos := int(round(float(p.get("espuma", 30)) * (1.45 if alto else 1.35)))
	if n_granos > 0:
		var g := CPUParticles3D.new()
		g.name = "Granos"
		g.amount = n_granos
		g.lifetime = 1.6
		g.local_coords = false
		g.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		g.emission_box_extents = Vector3(lado * 0.4, 0.6, lado * 0.4)
		g.position = Vector3(0, 0.7, 0) - d * 4.0
		g.direction = Vector3(d.x, 0.08, d.z)
		g.spread = 7.0
		g.initial_velocity_min = 5.0
		g.initial_velocity_max = 9.0
		g.gravity = Vector3(0, -1.2, 0)
		g.scale_amount_min = 0.6
		g.scale_amount_max = 1.2
		var q := QuadMesh.new()
		q.size = Vector2(0.05, 0.05)
		var mg := StandardMaterial3D.new()
		mg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mg.albedo_color = Color(0.98, 0.86, 0.64, 0.75)
		q.material = mg
		g.mesh = q
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(g)
	_poner_arrastre(raiz, _viento)
	return raiz


# Ondas de calor sobre un rectángulo de arena (tam en metros), a ras de suelo. Solo en el perfil alto: en los otros
# devuelve null (lee la pantalla: caro en el Mali-G57). La región lo coloca y lo quita.
static func calor(p: Dictionary, tam := Vector2(16, 12)) -> MeshInstance3D:
	if not detalle_alto(p):
		return null
	var m := ShaderMaterial.new()
	m.shader = _shader(SH_CALOR)
	m.set_shader_parameter("ruido", ruido())
	var pl := PlaneMesh.new()
	pl.size = tam
	var mi := MeshInstance3D.new()
	mi.name = "Calor"
	mi.mesh = pl
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.35
	return mi


# El viento de la región: 0,25 en calma, 1 en la tormenta (y lo que haya entre medias). Cambia todos los materiales de
# viento compartidos (arena, telas, plantas, espejismo, arrastre), los ShaderMaterial con «viento» o «intensidad» que
# cuelguen de «nodo» (por si la región usa copias propias) y la arena arrastrada (se oculta en calma total).
static func intensidad_viento(nodo: Node, v: float) -> void:
	_viento = clampf(v, 0.0, 1.0)
	for k in _cache:
		var m = _cache[k]
		if m is ShaderMaterial:
			_poner_viento(m as ShaderMaterial)
	if nodo == null:
		return
	for mi in nodo.find_children("*", "GeometryInstance3D", true, false):
		var g := mi as GeometryInstance3D
		if g.material_override is ShaderMaterial:
			_poner_viento(g.material_override as ShaderMaterial)
		if g is MeshInstance3D:
			var m3 := g as MeshInstance3D
			for i in m3.get_surface_override_material_count():
				var s := m3.get_surface_override_material(i)
				if s is ShaderMaterial:
					_poner_viento(s as ShaderMaterial)
	for a in nodo.find_children("ArenaArrastrada", "Node3D", true, false):
		_poner_arrastre(a as Node3D, _viento)


static func _poner_viento(m: ShaderMaterial) -> void:
	if m.shader == null:
		return
	for u in m.shader.get_shader_uniform_list():
		if u["name"] == "viento":
			m.set_shader_parameter("viento", _viento)
		elif u["name"] == "intensidad":
			m.set_shader_parameter("intensidad", _viento)


static func _poner_arrastre(raiz: Node3D, v: float) -> void:
	raiz.visible = v > 0.03
	var g := raiz.get_node_or_null("Granos") as CPUParticles3D
	if g != null:
		g.emitting = v > 0.15
		g.speed_scale = 0.6 + v * 0.8
		if "amount_ratio" in g:
			g.set("amount_ratio", clampf(v * 1.1, 0.1, 1.0))


static func viento_actual() -> float:
	return _viento


# Al salir de la región: suelta los materiales y texturas en caché (se vuelven a crear al volver).
static func liberar() -> void:
	_cache.clear()
	_viento = VIENTO_CALMA
