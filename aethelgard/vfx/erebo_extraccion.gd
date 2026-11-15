extends Node3D
# V12, Érebo híbrida (15/11): el CORAZÓN ESPECTRAL que Érebo extrae del pecho (o del núcleo) del enemigo en la
# invocación híbrida (invocacion_erebo_hibrida.gd; docs/v12/EREBO_HIBRIDA_V12.md). EXPERIMENTAL, solo presentación.
# · Extracción mágica, sin sangre ni vísceras: un corazón de luz (carmesí por dentro, violeta en el borde y plata en el
#   filo), un resplandor que se ve A TRAVÉS del cuerpo mientras está dentro, un hilo de esencia que lo ata al pecho y
#   motas violetas, negras y plateadas.
# · Azar PROPIO (RandomNumberGenerator con su semilla): no gasta el azar global del combate. No usa CPUParticles3D
#   (en Godot 4.7 gasta el generador global aunque tenga semilla fija): las motas son un MultiMesh que mueve este script.
# · No toca al enemigo: todo son nodos propios (no cambia sus mallas ni sus materiales).
# Uso (invocacion_erebo_hibrida.gd): preparar() → brillar_dentro() → nacer() → (sigue = mano) → romper_hilo() /
# volver() (fallo) / partir() (jefe) → condensar() → quitar().

const COLOR_NUCLEO := Color(1.0, 0.16, 0.36)      # el carmesí de Érebo
const COLOR_VIOLETA := Color(0.54, 0.24, 1.0)     # #8a3cff, el violeta del orbe
const COLOR_PLATA := Color(0.81, 0.84, 1.0)       # #cfd6ff, plata fría
const COLOR_NEGRO := Color(0.16, 0.05, 0.23)      # humo oscuro (se dibuja sumando: apenas aclara)
const MAX_MOTAS := 72

const SHADER_CORAZON := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec3 c_nucleo = vec3(1.0, 0.16, 0.36);
uniform vec3 c_borde = vec3(0.54, 0.24, 1.0);
uniform vec3 c_plata = vec3(0.81, 0.84, 1.0);
uniform float energia = 1.0;
uniform float latido = 0.0;
uniform float disolver = 0.0;
varying vec3 lp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float ruido(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y);
	float b = mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y);
	return mix(a, b, f.z);
}
void vertex() { lp = VERTEX; }
void fragment() {
	float fr = 1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float borde = pow(fr, 1.8);
	float n = ruido(lp * 9.0 + vec3(0.0, TIME * 0.9, 0.0));
	float vetas = smoothstep(0.62, 0.8, ruido(lp * 16.0 - vec3(0.0, TIME * 1.6, 0.0)));
	vec3 col = mix(c_nucleo * (0.55 + 0.6 * latido), c_borde, borde) + c_plata * pow(fr, 5.0) * 1.3;
	col += c_plata * vetas * 0.35 + c_nucleo * vetas * 0.3;
	float a = (0.42 + 0.58 * borde + 0.3 * latido) * energia;
	if (disolver > 0.0) {
		float d = disolver * 1.1;
		a *= step(d, n);
		col += c_plata * (1.0 - smoothstep(d, d + 0.12, n)) * 2.0;
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
"""

const SHADER_HILO := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 c_a = vec3(0.54, 0.24, 1.0);
uniform vec3 c_b = vec3(0.81, 0.84, 1.0);
uniform float energia = 1.0;
uniform float tension = 0.0;
void fragment() {
	float flujo = 0.5 + 0.5 * sin(UV.y * 40.0 - TIME * 14.0);
	float puntas = smoothstep(0.0, 0.12, UV.y) * smoothstep(1.0, 0.85, UV.y);
	float fr = 1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	vec3 col = mix(c_a, c_b, flujo * (0.4 + 0.6 * tension));
	ALBEDO = col;
	ALPHA = clamp((0.35 + 0.65 * flujo) * puntas * (1.0 - fr * 0.7) * energia, 0.0, 1.0);
}
"""

var tam := 0.16                    # alto del corazón, en metros
var rng := RandomNumberGenerator.new()
var corazon: MeshInstance3D
var fragmento: MeshInstance3D      # (jefe) el trozo de esencia que se queda en la mano
var resplandor: Sprite3D           # la luz del corazón vista a través del cuerpo (sin prueba de profundidad)
var hilo: MeshInstance3D
var motas: MultiMeshInstance3D
var origen := Vector3.ZERO         # el punto del pecho (o del núcleo)
var sigue := Callable()            # devuelve la posición de la mano (el corazón la sigue) o nada
var sigue_fragmento := Callable()
var esc_c := 0.0                   # escala (alto) del corazón y del trozo: la orientación la aplica cada fotograma
var esc_f := 0.0
var tension := 0.0                 # 0-1: lo que tira el hilo (tiembla el corazón)
var _mat: ShaderMaterial
var _mat_frag: ShaderMaterial
var _mat_hilo: ShaderMaterial
var _motas: Array = []             # {p, v, edad, vida, color, tam, atrae}
var _t := 0.0
var _tw: Array = []
var _brillo_tex: GradientTexture2D


func preparar(alto: float, semilla: int) -> void:
	tam = alto
	rng.seed = semilla
	_brillo_tex = GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	_brillo_tex.gradient = g
	_brillo_tex.fill = GradientTexture2D.FILL_RADIAL
	_brillo_tex.fill_from = Vector2(0.5, 0.5)
	_brillo_tex.fill_to = Vector2(0.5, 0.0)
	_brillo_tex.width = 64
	_brillo_tex.height = 64
	var sh := Shader.new()
	sh.code = SHADER_CORAZON
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	corazon = MeshInstance3D.new()
	corazon.mesh = malla_corazon(1.0)
	corazon.material_override = _mat
	corazon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corazon.visible = false
	add_child(corazon)
	_mat_frag = _mat.duplicate()
	_mat_frag.set_shader_parameter("c_nucleo", Vector3(0.75, 0.3, 1.0))   # el trozo, más violeta y plata
	fragmento = MeshInstance3D.new()
	fragmento.mesh = malla_corazon(1.0, 0.55)
	fragmento.material_override = _mat_frag
	fragmento.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fragmento.visible = false
	add_child(fragmento)
	resplandor = Sprite3D.new()
	resplandor.texture = _brillo_tex
	resplandor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	resplandor.shaded = false
	resplandor.no_depth_test = true
	resplandor.render_priority = 10
	resplandor.modulate = Color(COLOR_NUCLEO, 0.0)
	resplandor.pixel_size = tam * 2.6 / 64.0
	add_child(resplandor)
	var shh := Shader.new()
	shh.code = SHADER_HILO
	_mat_hilo = ShaderMaterial.new()
	_mat_hilo.shader = shh
	hilo = MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 1.0
	cil.bottom_radius = 1.0
	cil.height = 1.0
	cil.radial_segments = 8
	cil.rings = 1
	hilo.mesh = cil
	hilo.material_override = _mat_hilo
	hilo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hilo.visible = false
	add_child(hilo)
	# motas: un MultiMesh de cuadros que miran a la cámara, con el color por instancia
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mq := StandardMaterial3D.new()
	mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mq.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mq.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mq.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mq.billboard_keep_scale = true
	mq.vertex_color_use_as_albedo = true
	mq.albedo_texture = _brillo_tex
	mq.no_depth_test = false
	mq.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = mq
	mm.mesh = q
	mm.instance_count = MAX_MOTAS
	mm.visible_instance_count = 0
	motas = MultiMeshInstance3D.new()
	motas.multimesh = mm
	motas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	motas.extra_cull_margin = 100.0
	add_child(motas)


# ---------------------------------------------------------------- la malla: un corazón «de almohada» (sin anatomía)

# Contorno clásico del corazón (x = 16 sen³ t, y = 13 cos t − 5 cos 2t − 2 cos 3t − cos 4t), hinchado en Z como un
# cojín. alto = 1 m; «ancho_z» relativo. Centro aproximado en el origen; la punta abajo.
static func malla_corazon(alto: float, grueso := 0.42) -> ArrayMesh:
	var n_ang := 40
	var n_ani := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k := alto / 30.0
	var c := Vector2(0.0, -2.5)
	var pts: Array = []           # [anillo][ángulo] para la cara de delante (z > 0); detrás, z negativa
	for cara in [1.0, -1.0]:
		var rejilla: Array = []
		for i in n_ani + 1:
			var r := float(i) / n_ani
			var fila: Array = []
			for j in n_ang:
				var t := TAU * j / n_ang
				var x := 16.0 * pow(sin(t), 3.0)
				var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				var p := c + (Vector2(x, y) - c) * r
				var z: float = cara * grueso * 15.0 * sqrt(maxf(0.0, 1.0 - r * r)) * (0.75 + 0.25 * (1.0 - absf(sin(t))))
				fila.append(Vector3(p.x, p.y - c.y, z) * k)
			rejilla.append(fila)
		pts.append(rejilla)
	for cara in 2:
		var rj: Array = pts[cara]
		for i in n_ani:
			for j in n_ang:
				var j2 := (j + 1) % n_ang
				var a: Vector3 = rj[i][j]
				var b: Vector3 = rj[i + 1][j]
				var cc: Vector3 = rj[i + 1][j2]
				var d: Vector3 = rj[i][j2]
				if cara == 0:
					st.add_vertex(a); st.add_vertex(cc); st.add_vertex(b)
					st.add_vertex(a); st.add_vertex(d); st.add_vertex(cc)
				else:
					st.add_vertex(a); st.add_vertex(b); st.add_vertex(cc)
					st.add_vertex(a); st.add_vertex(cc); st.add_vertex(d)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------- momentos

# La luz del corazón dentro del pecho, vista a través del cuerpo: crece en «dur».
func brillar_dentro(pos: Vector3, dur: float, fuerza := 0.85) -> void:
	origen = pos
	resplandor.global_position = pos
	var t := _nuevo_tw()
	t.tween_property(resplandor, "modulate:a", fuerza, dur).set_trans(Tween.TRANS_SINE)


# El corazón aparece en «pos» (dentro del pecho, en la mano que lo agarra) y el hilo lo ata al origen.
func nacer(pos: Vector3) -> void:
	corazon.global_position = pos
	esc_c = tam * 0.55
	corazon.visible = true
	_mat.set_shader_parameter("disolver", 0.0)
	_mat.set_shader_parameter("energia", 1.0)
	hilo.visible = true
	_mat_hilo.set_shader_parameter("energia", 1.0)
	var t := _nuevo_tw()
	t.tween_property(self, "esc_c", tam, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rafaga(pos, COLOR_PLATA, 10, 0.5 * tam / 0.16)


# El hilo se rompe (sale del todo): estallido de plata en el punto de rotura; el resplandor del pecho se apaga.
func romper_hilo() -> void:
	if not hilo.visible:
		return
	var a := origen
	var b := corazon.global_position
	hilo.visible = false
	rafaga(a.lerp(b, 0.45), COLOR_PLATA, 14, 0.9 * tam / 0.16)
	rafaga(a.lerp(b, 0.45), COLOR_VIOLETA, 10, 0.6 * tam / 0.16)
	var t := _nuevo_tw()
	t.tween_property(resplandor, "modulate:a", 0.0, 0.5)


# Fallo: el corazón se le escapa de los dedos y vuelve al pecho; el hilo lo recoge y el pecho lo vuelve a cerrar.
func volver(dur := 0.45) -> void:
	sigue = Callable()
	var t := _nuevo_tw().set_parallel(true)
	t.tween_property(corazon, "global_position", origen, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(self, "esc_c", tam * 0.5, dur)
	t.tween_property(resplandor, "modulate:a", 1.0, dur * 0.6)
	t.chain().tween_callback(func():
		corazon.visible = false
		hilo.visible = false
		rafaga(origen, COLOR_PLATA, 12, 0.7 * tam / 0.16)
		var t2 := _nuevo_tw()
		t2.tween_property(resplandor, "modulate:a", 0.0, 0.6))


# Jefe: el corazón se resiste y vuelve, pero la mano arranca un TROZO de su esencia (el que se queda).
func partir(mano: Callable) -> void:
	var donde := corazon.global_position
	fragmento.global_position = donde
	esc_f = tam * 0.4
	fragmento.visible = true
	sigue_fragmento = mano
	var t := _nuevo_tw()
	t.tween_property(self, "esc_f", tam * 0.78, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rafaga(donde, COLOR_PLATA, 16, 0.9 * tam / 0.16)
	volver(0.4)


# El sello violeta en el suelo, bajo el enemigo elegido (se cierra sobre él y se apaga solo).
func marcar(pos: Vector3, radio: float) -> void:
	var tex := GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 0.62, 0.8, 0.88, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.12),
		Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = tex
	m.albedo_color = Color(COLOR_VIOLETA, 0.0)
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var sello := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	sello.mesh = pm
	sello.material_override = m
	sello.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sello)
	sello.global_position = pos
	sello.scale = Vector3.ONE * radio * 1.5
	var t := _nuevo_tw()
	t.set_parallel(true)
	t.tween_property(sello, "scale", Vector3.ONE * radio, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(m, "albedo_color:a", 0.9, 0.4)
	t.tween_property(sello, "rotation:y", 0.8, 2.6)
	t.chain().tween_property(m, "albedo_color:a", 0.0, 0.8).set_delay(1.0)
	t.chain().tween_callback(sello.queue_free)
	for i in 14:
		var a := TAU * i / 14.0
		var p := pos + Vector3(cos(a), 0.02, sin(a)) * radio * 0.9
		_mota(p, Vector3(0, rng.randf_range(0.3, 0.7), 0), rng.randf_range(0.8, 1.4), COLOR_VIOLETA if i % 3 else COLOR_PLATA,
			tam * rng.randf_range(0.3, 0.5), Vector3.INF)


# Lo que tiene en la mano deja de seguirla y sube hasta «pos» en «dur» segundos.
func soltar(pos: Vector3, dur: float) -> void:
	var quien := fragmento if fragmento.visible else corazon
	sigue = Callable()
	sigue_fragmento = Callable()
	var t := _nuevo_tw()
	t.tween_property(quien, "global_position", pos, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Lo que tiene en la mano (el corazón o, con un jefe, el trozo) se deshace en energía que se recoge en espiral hacia
# su centro (de ahí nace el orbe del ritual). Devuelve tras «dur».
func condensar(dur := 0.7) -> void:
	var quien := fragmento if fragmento.visible else corazon
	var m: ShaderMaterial = _mat_frag if quien == fragmento else _mat
	var centro := quien.global_position
	for i in 26:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-1, 1)).normalized()
		var col: Color = [COLOR_VIOLETA, COLOR_PLATA, COLOR_NEGRO, COLOR_NUCLEO][i % 4]
		_mota(centro + dir * tam * rng.randf_range(1.2, 2.2), -dir * 0.1, rng.randf_range(0.5, dur + 0.1), col,
			tam * rng.randf_range(0.18, 0.35), centro)
	var t := _nuevo_tw().set_parallel(true)
	t.tween_method(func(v): m.set_shader_parameter("disolver", v), 0.0, 1.0, dur)
	t.tween_property(self, "esc_f" if quien == fragmento else "esc_c", tam * 0.3, dur).set_ease(Tween.EASE_IN)
	await t.finished
	if is_instance_valid(quien):
		quien.visible = false


# Estallido de motas desde «pos» (con dirección: hacia fuera).
func rafaga(pos: Vector3, color: Color, n: int, fuerza: float) -> void:
	for i in n:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)).normalized()
		_mota(pos, dir * fuerza * rng.randf_range(0.4, 1.0), rng.randf_range(0.35, 0.8), color,
			tam * rng.randf_range(0.12, 0.28), Vector3.INF)


func quitar() -> void:
	for t in _tw:
		if t != null and t.is_valid():
			t.kill()
	_tw.clear()
	queue_free()


# ---------------------------------------------------------------- cada fotograma

func _process(delta: float) -> void:
	if _mat == null:                                           # (aún sin preparar)
		return
	_t += delta
	var lat := pow(maxf(0.0, sin(_t * 7.5)), 6.0)              # latido doble y rápido
	var lat2 := pow(maxf(0.0, sin(_t * 7.5 - 0.9)), 8.0) * 0.6
	var l := maxf(lat, lat2)
	_mat.set_shader_parameter("latido", l)
	_mat_frag.set_shader_parameter("latido", l)
	var cam := get_viewport().get_camera_3d()
	if corazon.visible:
		if sigue.is_valid():
			var p = sigue.call()
			if p is Vector3:
				corazon.global_position = p
		var temb := Vector3.ZERO                                # (solo mientras sigue a la mano: si no, se iría sumando)
		if sigue.is_valid():
			temb = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * tam * 0.06 * tension
		_orientar(corazon, cam, (1.0 + 0.12 * l) * esc_c, temb)
	if fragmento.visible:
		if sigue_fragmento.is_valid():
			var p2 = sigue_fragmento.call()
			if p2 is Vector3:
				fragmento.global_position = p2
		_orientar(fragmento, cam, (1.0 + 0.12 * l) * esc_f, Vector3.ZERO)
	resplandor.pixel_size = tam * (2.4 + 0.8 * l) / 64.0
	if hilo.visible and corazon.visible:
		_poner_hilo(origen, corazon.global_position)
		if rng.randf() < 0.5:                                   # motas que corren por el hilo hacia la mano
			var a := origen.lerp(corazon.global_position, rng.randf())
			_mota(a, (corazon.global_position - origen).normalized() * 0.4, 0.35, COLOR_PLATA if rng.randf() < 0.5 else COLOR_VIOLETA,
				tam * 0.14, Vector3.INF)
	elif corazon.visible and rng.randf() < 0.35:                # en la mano: humo violeta y negro que sube
		var p3 := corazon.global_position + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * tam * 0.4
		_mota(p3, Vector3(0, 0.25, 0), 0.6, COLOR_VIOLETA if rng.randf() < 0.6 else COLOR_NEGRO, tam * 0.3, Vector3.INF)
	_mover_motas(delta)


func _orientar(n: Node3D, cam: Camera3D, esc: float, temb: Vector3) -> void:
	var basis := Basis.IDENTITY
	if cam != null:
		var z := cam.global_position - n.global_position
		z.y *= 0.3
		if z.length() > 0.001:
			z = z.normalized()
			var x := Vector3.UP.cross(z).normalized()
			if x.length() > 0.001:
				basis = Basis(x, z.cross(x), z)
	n.global_basis = basis.scaled(Vector3.ONE * maxf(esc, 0.0001))
	n.global_position += temb


func _poner_hilo(a: Vector3, b: Vector3) -> void:
	var d := b - a
	var largo := d.length()
	if largo < 0.001:
		hilo.visible = false
		return
	var y := d / largo
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	var r := tam * (0.05 + 0.04 * tension)
	hilo.global_transform = Transform3D(Basis(x * r, y * largo, z * r), (a + b) * 0.5)
	_mat_hilo.set_shader_parameter("tension", tension)


func _mota(p: Vector3, v: Vector3, vida: float, color: Color, t: float, atrae: Vector3) -> void:
	if _motas.size() >= MAX_MOTAS:
		_motas.pop_front()
	_motas.append({"p": p, "v": v, "edad": 0.0, "vida": vida, "c": color, "t": t, "atrae": atrae})


func _mover_motas(delta: float) -> void:
	var vivas: Array = []
	for m in _motas:
		m["edad"] += delta
		if m["edad"] >= m["vida"]:
			continue
		if m["atrae"] != Vector3.INF:                           # en espiral hacia su centro
			var hacia: Vector3 = m["atrae"] - m["p"]
			var giro := hacia.cross(Vector3.UP) * 2.5
			m["v"] = (m["v"] as Vector3).lerp(hacia * 3.5 + giro, minf(1.0, delta * 6.0))
		else:
			m["v"] = (m["v"] as Vector3) * maxf(0.0, 1.0 - delta * 2.0)
		m["p"] += m["v"] * delta
		vivas.append(m)
	_motas = vivas
	var mm := motas.multimesh
	mm.visible_instance_count = _motas.size()
	for i in _motas.size():
		var m: Dictionary = _motas[i]
		var vida: float = m["edad"] / m["vida"]
		var a := sin(vida * PI)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * m["t"]), m["p"]))
		var c: Color = m["c"]
		mm.set_instance_color(i, Color(c.r, c.g, c.b, a))


func _nuevo_tw() -> Tween:
	var t := create_tween()
	_tw.append(t)
	return t
