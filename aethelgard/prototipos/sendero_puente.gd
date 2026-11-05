extends "res://prototipos/vista3d.gd"
# PROTOTIPO AISLADO (Fase 2): escena de muestra de la nueva dirección gráfica.
# Sendero de losas, puente de cuerda sobre un barranco con río, cascada, árboles y hierba con viento,
# flores, faroles, un conejo y un pájaro; Kael original con la cámara de 45° de vista3d.gd.
# No lo usa ninguna escena del juego ni entra en el APK del juego.
# Abrir: prototipos/sendero_puente.tscn (F6). Los controles son los de vista3d.gd.
#
# Calidad: en el móvil (o con «-- movil») hay menos hierba y sin sombras.

const TAM := 64.0                 # lado del terreno (m)
const PASO := 0.5                 # separación de los vértices del terreno (m)
const RIO_X := 9.0                # centro del barranco
const RIO_ANCHO := 2.6            # media anchura del fondo del barranco
const BORDE := 1.1                # anchura de la pared (de arriba al fondo)
const FONDO := -6.0               # profundidad del barranco
const CASCADA_Z := -16.0          # río arriba de aquí, el agua va por un canal a nivel del suelo
const SENDERO := [Vector3(-16, 0, 16), Vector3(-9, 0, 9), Vector3(-3, 0, 5), Vector3(2, 0, -0.5),
	Vector3(RIO_X - RIO_ANCHO - BORDE - 0.6, 0, -2), Vector3(RIO_X + RIO_ANCHO + BORDE + 0.6, 0, -2),
	Vector3(16, 0, -6), Vector3(20, 0, -14), Vector3(22, 0, -22)]

var movil := false
var hierba_n := 5000
var flores_n := 500
const SHADER_HIERBA := """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec3 abajo : source_color = vec3(0.26, 0.48, 0.16);
uniform vec3 arriba : source_color = vec3(0.62, 0.84, 0.34);
uniform float fuerza = 0.22;
varying float alto;
void vertex() {
	alto = VERTEX.y;
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.7 + w.x * 0.32 + w.z * 0.21) * 0.7 + sin(TIME * 3.3 + w.x * 1.3) * 0.3;
	VERTEX.x += s * fuerza * alto * alto * 2.0;
	VERTEX.z += s * fuerza * alto * alto;
}
void fragment() {
	ALBEDO = mix(abajo, arriba, clamp(alto / 0.5, 0.0, 1.0)) * COLOR.rgb;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);   // las dos caras iluminadas como el suelo
}
"""
const SHADER_COPA := """
shader_type spatial;
uniform vec3 color : source_color = vec3(0.3, 0.55, 0.22);
uniform vec3 luz : source_color = vec3(0.55, 0.75, 0.3);
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.3 + w.x * 0.2 + w.z * 0.17);
	VERTEX.x += s * 0.08 * max(VERTEX.y + 0.5, 0.0);
	VERTEX.z += sin(TIME * 1.1 + w.z * 0.3) * 0.05 * max(VERTEX.y + 0.5, 0.0);
}
void fragment() {
	ALBEDO = mix(color, luz, clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0) * 0.6);
	ROUGHNESS = 0.95;
}
"""
const SHADER_CASCADA := """
shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
	float t = TIME * 1.4;
	float ruido = sin(UV.x * 37.0 + sin(UV.x * 11.0) * 3.0) * 0.5 + 0.5;
	float raya = fract(UV.y * 2.5 - t + ruido * 0.8);
	vec3 c = mix(vec3(0.45, 0.75, 0.92), vec3(0.97, 0.99, 1.0), smoothstep(0.55, 1.0, raya));
	ALBEDO = c;
	ALPHA = 0.88 - 0.2 * smoothstep(0.85, 1.0, UV.y);
}
"""


func _ready() -> void:
	movil = OS.has_feature("mobile") or "movil" in OS.get_cmdline_user_args()
	if movil:
		hierba_n = 2200
		flores_n = 250
	super._ready()
	var inicio: Vector3 = SENDERO[0] + Vector3(0, altura(SENDERO[0].x, SENDERO[0].z), 0)
	kael.global_position = inicio
	foco = inicio
	_colocar_camara(1.0)
	_crear_fauna()


# ---------------------------------------------------------------- terreno

# Altura del terreno en (x, z): mesetas con ondulaciones suaves, el barranco del río, el canal
# río arriba de la cascada y lomas en los bordes para cerrar el encuadre.
static func altura(x: float, z: float) -> float:
	var h := 0.18 * sin(x * 0.31) * cos(z * 0.27) + 0.12 * sin(x * 0.7 + z * 0.5)
	var lejos := maxf(absf(x - 2.0) - 22.0, 0.0) + maxf(-z - 24.0, 0.0) + maxf(z - 24.0, 0.0)
	h += lejos * 0.55                                          # lomas en los bordes
	var d := absf(x - RIO_X)
	if z > CASCADA_Z:
		if d < RIO_ANCHO:
			return FONDO + 0.15 * sin(z * 0.8)
		if d < RIO_ANCHO + BORDE:                               # pared casi vertical, algo irregular
			var k := (d - RIO_ANCHO) / BORDE
			k = clampf(k + 0.12 * sin(z * 1.7 + x), 0.0, 1.0)
			return lerpf(FONDO, h, smoothstep(0.0, 1.0, k))
	else:
		if d < 1.6:                                              # canal que alimenta la cascada
			return -0.7
		if d < 2.1:
			return lerpf(-0.7, h, (d - 1.6) / 0.5)
	return h


func _color_terreno(x: float, z: float, y: float, pendiente: float) -> Color:
	var hierba := Color(0.36, 0.56, 0.22).lerp(Color(0.48, 0.62, 0.25), 0.5 + 0.5 * sin(x * 0.4 + z * 0.3))
	var tierra := Color(0.55, 0.43, 0.3)
	var roca := Color(0.5, 0.48, 0.46).lerp(Color(0.38, 0.36, 0.35), 0.5 + 0.5 * sin(y * 2.3 + z))
	if _dist_sendero(Vector3(x, 0, z)) < 1.7:
		hierba = hierba.lerp(tierra, 0.75)                     # borde de tierra junto al sendero
	if y < -0.5 and pendiente < 0.3:
		return Color(0.35, 0.4, 0.3)                           # fondo del barranco, húmedo
	return hierba.lerp(roca, smoothstep(0.35, 0.7, pendiente))


func _crear_terreno() -> void:
	var n := int(TAM / PASO)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var alturas := []
	for i in n + 1:
		var fila := []
		for j in n + 1:
			fila.append(altura(-TAM * 0.5 + j * PASO + 2.0, -TAM * 0.5 + i * PASO))
		alturas.append(fila)
	for i in n + 1:
		for j in n + 1:
			var x := -TAM * 0.5 + j * PASO + 2.0
			var z := -TAM * 0.5 + i * PASO
			var y: float = alturas[i][j]
			var dx: float = alturas[i][mini(j + 1, n)] - alturas[i][maxi(j - 1, 0)]
			var dz: float = alturas[mini(i + 1, n)][j] - alturas[maxi(i - 1, 0)][j]
			var pendiente := clampf(sqrt(dx * dx + dz * dz) / (2.0 * PASO), 0.0, 1.0)
			st.set_color(_color_terreno(x, z, y, pendiente))
			st.set_uv(Vector2(x, z) * 0.25)
			st.add_vertex(Vector3(x, y, z))
	for i in n:
		for j in n:
			var a := i * (n + 1) + j
			st.add_index(a); st.add_index(a + 1); st.add_index(a + n + 1)
			st.add_index(a + 1); st.add_index(a + n + 2); st.add_index(a + n + 1)
	st.generate_normals()
	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	mi.material_override = m
	var cuerpo := StaticBody3D.new()
	add_child(cuerpo)
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	col.shape = malla.create_trimesh_shape()
	cuerpo.add_child(col)


# ---------------------------------------------------------------- sendero, puente, agua

func _dist_sendero(p: Vector3) -> float:
	var mejor := 999.0
	for k in SENDERO.size() - 1:
		var a: Vector3 = SENDERO[k]
		var b: Vector3 = SENDERO[k + 1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var ap := Vector2(p.x - a.x, p.z - a.z)
		var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		mejor = minf(mejor, (ap - ab * t).length())
	return mejor


func _crear_sendero() -> void:
	var puntos: Array = []
	for k in SENDERO.size() - 1:
		var a: Vector3 = SENDERO[k]
		var b: Vector3 = SENDERO[k + 1]
		if k == 4:
			continue                                 # el tramo del puente no lleva losas
		var largo := Vector2(b.x - a.x, b.z - a.z).length()
		var lado := Vector3(-(b.z - a.z), 0, b.x - a.x).normalized()
		var pasos := int(largo / 0.75)
		for s in pasos:
			var c := a.lerp(b, (s + 0.5) / pasos)
			for fila in [-0.75, 0.0, 0.75]:
				var p: Vector3 = c + lado * (fila + randf_range(-0.18, 0.18)) + Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
				puntos.append(p)
	var losa := CylinderMesh.new()
	losa.top_radius = 0.34
	losa.bottom_radius = 0.37
	losa.height = 0.1
	losa.radial_segments = 7
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	losa.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = losa
	mm.instance_count = puntos.size()
	for k in puntos.size():
		var p: Vector3 = puntos[k]
		var t := Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(randf_range(0.85, 1.2), 1, randf_range(0.8, 1.15))),
			Vector3(p.x, altura(p.x, p.z) + 0.02, p.z))
		mm.set_instance_transform(k, t)
		var g := randf_range(0.48, 0.62)                       # piedra gris cálida, sin quemarse a blanco
		mm.set_instance_color(k, Color(g, g * 0.95, g * 0.86))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _crear_puente() -> void:
	var x0: float = SENDERO[4].x
	var x1: float = SENDERO[5].x
	var z: float = -2.0
	var madera := _mat(Color(0.55, 0.38, 0.22))
	var tablas := int((x1 - x0) / 0.32)
	for k in tablas + 1:
		var t := float(k) / tablas
		var x := lerpf(x0, x1, t)
		var y := -0.05 - sin(t * PI) * 0.35                  # se comba un poco en el centro
		var cuerpo := StaticBody3D.new()
		cuerpo.position = Vector3(x, y - 0.05, z)
		cuerpo.rotation.z = cos(t * PI) * 0.12 * (1.0 if k < tablas / 2 else 1.0)
		add_child(cuerpo)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.26, 0.08, 2.0 + randf_range(-0.08, 0.08))
		mi.mesh = bm
		mi.material_override = madera
		cuerpo.add_child(mi)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.32, 0.08, 2.0)
		col.shape = bs
		cuerpo.add_child(col)
	# postes y cuerdas
	var cuerda := _mat(Color(0.75, 0.65, 0.45))
	for lado in [-1.0, 1.0]:
		for x in [x0, x1]:
			_poste(Vector3(x, altura(x, z + lado * 1.05), z + lado * 1.05), 1.3)
		var n := 14
		for k in n:
			var a := lerpf(x0, x1, float(k) / n)
			var b := lerpf(x0, x1, float(k + 1) / n)
			var ya := 1.1 - sin(float(k) / n * PI) * 0.4
			var yb := 1.1 - sin(float(k + 1) / n * PI) * 0.4
			var seg := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.025
			cm.bottom_radius = 0.025
			cm.radial_segments = 5
			var pa := Vector3(a, ya, z + lado * 1.05)
			var pb := Vector3(b, yb, z + lado * 1.05)
			cm.height = pa.distance_to(pb)
			seg.mesh = cm
			seg.material_override = cuerda
			add_child(seg)
			seg.global_position = (pa + pb) * 0.5
			seg.look_at(pb, Vector3.FORWARD)
			seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func _poste(pos: Vector3, alto: float, farol := false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, alto, 0.16)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.42, 0.29, 0.18))
	mi.position = pos + Vector3(0, alto * 0.5, 0)
	add_child(mi)
	if farol:
		var f := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(0.22, 0.3, 0.22)
		f.mesh = fb
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(1.0, 0.8, 0.45)
		fm.emission_enabled = true
		fm.emission = Color(1.0, 0.7, 0.3)
		fm.emission_energy_multiplier = 2.0
		f.material_override = fm
		f.position = pos + Vector3(0, alto + 0.15, 0)
		add_child(f)
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.75, 0.4)
		luz.light_energy = 1.2
		luz.omni_range = 4.0
		luz.position = f.position
		add_child(luz)


func _crear_agua() -> void:
	var mat_agua: Material = null
	if ResourceLoader.exists("res://shaders/water.gdshader"):
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/water.gdshader")
		mat_agua = sm
	else:
		mat_agua = _mat(Color(0.2, 0.55, 0.75), 0.1)
	# río en el fondo del barranco y canal de arriba
	for datos in [[Vector3(RIO_X, FONDO + 0.35, (CASCADA_Z + 32.0) * 0.5), Vector2(RIO_ANCHO * 2.0 + 0.6, 32.0 - CASCADA_Z)],
			[Vector3(RIO_X, -0.45, (CASCADA_Z - 32.0) * 0.5), Vector2(3.4, 32.0 + CASCADA_Z)]]:
		var agua := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = datos[1]
		agua.mesh = pm
		agua.position = datos[0]
		agua.material_override = mat_agua
		add_child(agua)
	# la cascada: una cortina con rayas que caen y espuma abajo
	var cortina := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(3.4, -0.45 - FONDO - 0.2)
	cortina.mesh = q
	cortina.position = Vector3(RIO_X, (-0.45 + FONDO + 0.35) * 0.5, CASCADA_Z + 0.15)
	var cm := ShaderMaterial.new()
	cm.shader = Shader.new()
	cm.shader.code = SHADER_CASCADA
	cortina.material_override = cm
	add_child(cortina)
	var espuma := CPUParticles3D.new()
	espuma.amount = 40 if movil else 90
	espuma.lifetime = 1.4
	espuma.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	espuma.emission_box_extents = Vector3(1.6, 0.1, 0.3)
	espuma.direction = Vector3(0, 1, 1)
	espuma.spread = 35.0
	espuma.initial_velocity_min = 0.8
	espuma.initial_velocity_max = 1.8
	espuma.gravity = Vector3(0, -0.6, 0)
	espuma.scale_amount_min = 0.5
	espuma.scale_amount_max = 1.4
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)])
	espuma.color_ramp = g
	var bola := SphereMesh.new()
	bola.radius = 0.18
	bola.height = 0.36
	bola.radial_segments = 6
	bola.rings = 3
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.vertex_color_use_as_albedo = true
	bola.material = bm
	espuma.mesh = bola
	espuma.position = Vector3(RIO_X, FONDO + 0.45, CASCADA_Z + 0.6)
	add_child(espuma)


# ---------------------------------------------------------------- vegetación

func _arbol_viento(pos: Vector3, alto: float, color: Color) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	add_child(cuerpo)
	var tronco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18
	cm.bottom_radius = 0.38
	cm.height = alto * 0.6
	cm.radial_segments = 7
	tronco.mesh = cm
	tronco.position.y = alto * 0.3
	tronco.material_override = _mat(Color(0.38, 0.27, 0.18))
	cuerpo.add_child(tronco)
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_COPA
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("luz", color.lightened(0.35))
	for k in 4:                                     # copa hecha de varias bolas: silueta más natural
		var copa := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := alto * randf_range(0.2, 0.28)
		sm.radius = r
		sm.height = r * 1.7
		sm.radial_segments = 10
		sm.rings = 6
		copa.mesh = sm
		copa.material_override = mat
		var a := k * TAU / 4.0 + randf() * 0.5
		copa.position = Vector3(cos(a) * alto * 0.13, alto * randf_range(0.68, 0.82), sin(a) * alto * 0.13) if k > 0 else Vector3(0, alto * 0.88, 0)
		cuerpo.add_child(copa)
		copa.add_to_group("ocluye")
	tronco.add_to_group("ocluye")
	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = alto * 0.3
	col.shape = cs
	col.position.y = alto * 0.78
	cuerpo.add_child(col)
	var col2 := CollisionShape3D.new()                 # el tronco no deja pasar a Kael
	var cil := CylinderShape3D.new()
	cil.radius = 0.35
	cil.height = alto * 0.6
	col2.shape = cil
	col2.position.y = alto * 0.3
	cuerpo.add_child(col2)


# Lo que tapa a Kael se vuelve medio transparente. Las copas usan un sombreado con viento, así que
# mientras tapan se cambian por un material transparente del mismo color.
func _transparente(mi: MeshInstance3D, si: bool) -> void:
	if mi.material_override is ShaderMaterial or mi.has_meta("mat_original"):
		if si:
			if not mi.has_meta("mat_original"):
				mi.set_meta("mat_original", mi.material_override)
			var col: Color = mi.get_meta("mat_original").get_shader_parameter("color")
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(col, 0.3)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mi.material_override = m
		elif mi.has_meta("mat_original"):
			mi.material_override = mi.get_meta("mat_original")
			mi.remove_meta("mat_original")
		return
	super._transparente(mi, si)


func _libre(p: Vector3, margen_sendero := 1.4) -> bool:
	var y := altura(p.x, p.z)
	if y < -0.3 or absf(p.x - RIO_X) < RIO_ANCHO + BORDE + 0.4:
		return false
	return _dist_sendero(p) > margen_sendero


func _hierba_y_flores() -> void:
	# hojas de hierba: tres láminas cruzadas, repetidas miles de veces con MultiMesh (una sola llamada de dibujo)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := k * PI / 3.0
		var d := Vector3(cos(a), 0, sin(a)) * 0.07
		st.set_normal(Vector3.UP)
		st.add_vertex(-d)
		st.add_vertex(d)
		st.add_vertex(Vector3(0, 0.5, 0) + d * 0.2)
	var hoja := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_HIERBA
	hoja.surface_set_material(0, mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = hoja
	var lista: Array = []
	var intentos := 0
	while lista.size() < hierba_n and intentos < hierba_n * 4:
		intentos += 1
		var p := Vector3(randf_range(-24, 28), 0, randf_range(-26, 24))
		if _libre(p, 1.2):
			lista.append(p)
	mm.instance_count = lista.size()
	for k in lista.size():
		var p: Vector3 = lista[k]
		var e := randf_range(0.6, 1.4)
		mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(e, e * randf_range(0.8, 1.3), e)),
			Vector3(p.x, altura(p.x, p.z), p.z)))
		var tono := randf_range(0.85, 1.1)
		mm.set_instance_color(k, Color(tono, tono, tono * randf_range(0.9, 1.0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# flores: bolitas de color en matas (lavanda, rosa y blanco, como la referencia)
	var flor := SphereMesh.new()
	flor.radius = 0.07
	flor.height = 0.14
	flor.radial_segments = 6
	flor.rings = 3
	var fm := StandardMaterial3D.new()
	fm.vertex_color_use_as_albedo = true
	fm.roughness = 0.8
	flor.material = fm
	var mf := MultiMesh.new()
	mf.transform_format = MultiMesh.TRANSFORM_3D
	mf.use_colors = true
	mf.mesh = flor
	var colores := [Color(0.62, 0.45, 0.9), Color(0.95, 0.55, 0.72), Color(0.97, 0.95, 0.88), Color(1.0, 0.85, 0.35)]
	var flores: Array = []
	while flores.size() < flores_n:
		var centro := Vector3(randf_range(-22, 26), 0, randf_range(-24, 22))
		if not _libre(centro, 1.0):
			continue
		var c: Color = colores[randi() % colores.size()]
		for k in 12:
			var p := centro + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
			flores.append([p, c])
	mf.instance_count = flores.size()
	for k in flores.size():
		var p: Vector3 = flores[k][0]
		mf.set_instance_transform(k, Transform3D(Basis(), Vector3(p.x, altura(p.x, p.z) + randf_range(0.25, 0.42), p.z)))
		mf.set_instance_color(k, flores[k][1])
	var mfi := MultiMeshInstance3D.new()
	mfi.multimesh = mf
	mfi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mfi)


# ---------------------------------------------------------------- composición

func _crear_ambiente() -> void:
	super._crear_ambiente()


func _crear_escenario() -> void:
	_crear_terreno()
	_crear_sendero()
	_crear_puente()
	_crear_agua()
	# árboles enmarcando el sendero (como la referencia: grandes en primer plano, más a los lados)
	var verdes := [Color(0.28, 0.52, 0.2), Color(0.35, 0.58, 0.22), Color(0.25, 0.45, 0.22)]
	var sitios := [Vector3(-13, 0, 6), Vector3(-6, 0, 12), Vector3(-19, 0, 12), Vector3(-1, 0, 10), Vector3(-8, 0, -4),
		Vector3(-14, 0, -6), Vector3(-2, 0, -9), Vector3(16, 0, 2), Vector3(22, 0, -4), Vector3(14, 0, -14),
		Vector3(-20, 0, -14), Vector3(4, 0, -16), Vector3(24, 0, 8)]
	for p in sitios:
		_arbol_viento(Vector3(p.x, altura(p.x, p.z), p.z), randf_range(5.0, 7.5), verdes[randi() % verdes.size()])
	# un cerezo rosa al otro lado del puente
	_arbol_viento(Vector3(17, altura(17, -9), -9), 5.5, Color(0.92, 0.6, 0.72))
	# rocas
	for k in 18:
		var p := Vector3(randf_range(-22, 26), 0, randf_range(-24, 22))
		if not _libre(p, 1.6):
			continue
		var r := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.4, 1.0)
		sm.height = sm.radius * 1.2
		sm.radial_segments = 7
		sm.rings = 4
		r.mesh = sm
		r.material_override = _mat(Color(0.52, 0.5, 0.48))
		r.position = Vector3(p.x, altura(p.x, p.z) + sm.radius * 0.2, p.z)
		r.rotation = Vector3(randf(), randf() * TAU, randf()) * 0.4
		add_child(r)
	# faroles junto a la entrada del puente
	_poste(Vector3(SENDERO[4].x - 1.0, 0, -3.6) + Vector3(0, altura(SENDERO[4].x - 1.0, -3.6), 0), 1.8, true)
	_poste(Vector3(SENDERO[5].x + 1.0, 0, -0.4) + Vector3(0, altura(SENDERO[5].x + 1.0, -0.4), 0), 1.8, true)
	_hierba_y_flores()
	# lejanía: la isla flotante y montañas azuladas en la bruma
	if ResourceLoader.exists("res://isla/isla_color_0_0.png"):
		var isla := Sprite3D.new()
		isla.texture = load("res://isla/isla_color_0_0.png")
		isla.pixel_size = 0.03
		isla.position = Vector3(10, 38, -130)
		isla.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		isla.shaded = false
		isla.modulate = Color(0.85, 0.9, 1.0, 0.9)
		add_child(isla)
	for k in 6:
		var monte := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = randf_range(18, 30)
		cm.height = randf_range(22, 40)
		cm.radial_segments = 8
		monte.mesh = cm
		monte.material_override = _mat(Color(0.45, 0.55, 0.7))
		monte.position = Vector3(-60 + k * 26, cm.height * 0.5 - 8, -110 - randf() * 30)
		add_child(monte)


func _crear_fauna() -> void:
	var fauna := load("res://prototipos/fauna_simple.gd")
	for p in [Vector3(-5, 0, 2), Vector3(17, 0, -3)]:
		var c = fauna.new()
		c.tipo = "conejo"
		c.kael = kael
		c.radio = 3.0
		c.position = Vector3(p.x, altura(p.x, p.z), p.z)    # antes de entrar: ahí queda su «casa»
		add_child(c)
	var pajaro = fauna.new()
	pajaro.tipo = "pajaro"
	pajaro.radio = 6.0
	pajaro.position = Vector3(RIO_X, 5.5, -6)
	add_child(pajaro)
