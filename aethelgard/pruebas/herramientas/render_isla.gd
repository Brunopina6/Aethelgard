extends SceneTree
# Renderiza un modelo grande (la isla flotante) como fondo pintado, en trozos, con cámara ortográfica
# en tres cuartos. Tres pasadas:
#   color        la imagen con luz dorada desde arriba a la izquierda y relleno azul (Biblia de arte)
#   mascara      blanco = se anda (suelo plano a la altura de las calles, sin agua), negro = no
#   profundidad  lo que se alza sobre el suelo: cuánto de cerca está de la cámara (0 = suelo / nada)
# Uso: --script render_isla.gd -- <res://modelo.fbx> <carpeta> <ancho px> <trozos x> <trozos y> <inclinación°> <pasada>
# Guarda <pasada>_<i>_<j>.png y datos.json (medidas para el juego).

var a: PackedStringArray
var modelo: Node3D
var malla: MeshInstance3D
var vp: SubViewport
var cam: Camera3D
var frames := 0
var tareas: Array = []
var datos := {}
var ancho := 0
var alto := 0
var nx := 1
var ny := 1
var incl := 38.0
var pasada := "color"
var caja: AABB
var suelo := 0.0
var ws := 0.0
var hs := 0.0
var centro := Vector3.ZERO
const SUELO_MIN := -0.205   # se anda entre estas alturas: la plaza, la orilla y la terraza del templo
const SUELO_MAX := 0.095    # (por encima, copas de árbol y tejados)

const SHADER_MASCARA := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D color_tex : source_color, filter_linear;
uniform float suelo_min;
uniform float suelo_max;
varying vec3 mundo;
varying vec3 normal_mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 c = texture(color_tex, UV).rgb;
	bool plano = normal_mundo.y > 0.75;
	bool a_ras = mundo.y > suelo_min && mundo.y < suelo_max;
	bool agua = c.b > c.r + 0.12 && c.b > c.g - 0.02;
	ALBEDO = (plano && a_ras && !agua) ? vec3(1.0) : vec3(0.0);
}
"""
const SHADER_PROFUNDIDAD := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D color_tex : source_color, filter_linear;
uniform float suelo_min;
uniform float suelo_max;
uniform float z_min;
uniform float z_max;
varying vec3 mundo;
varying vec3 normal_mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 c = texture(color_tex, UV).rgb;
	bool agua = c.b > c.r + 0.12 && c.b > c.g - 0.02;
	bool se_anda = normal_mundo.y > 0.75 && mundo.y > suelo_min && mundo.y < suelo_max && !agua;
	// lo que se alza (casas, árboles, muros de las terrazas): cuánto de cerca está; el suelo y lo de abajo, 0
	float z = clamp((mundo.z - z_min) / (z_max - z_min), 0.004, 1.0);
	float d = (!se_anda && mundo.y > suelo_min + 0.02) ? z : 0.0;
	ALBEDO = vec3(d, se_anda ? z : 0.0, 0.0);    // rojo: lo que se alza; verde: el suelo por el que se anda
}
"""


func _initialize() -> void:
	a = OS.get_cmdline_user_args()
	ancho = int(a[2])
	nx = int(a[3])
	ny = int(a[4])
	incl = float(a[5])
	pasada = a[6]
	modelo = load(a[0]).instantiate()
	root.add_child(modelo)


func _preparar() -> void:
	malla = modelo.find_children("*", "MeshInstance3D", true, false)[0]
	caja = malla.global_transform * malla.mesh.get_aabb()
	centro = caja.get_center()
	suelo = -0.127                                       # la plaza (histograma de alturas)
	var r := deg_to_rad(incl)
	ws = caja.size.x * 1.04
	hs = (caja.size.z * sin(r) + caja.size.y * cos(r)) * 1.04
	alto = int(round(ancho * hs / ws / ny)) * ny
	vp = SubViewport.new()
	vp.size = Vector2i(ancho / nx, alto / ny)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X if pasada == "color" else Viewport.MSAA_DISABLED
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("FFE2B0").lerp(Color.WHITE, 0.4)
	env.environment.ambient_light_energy = 0.55
	vp.add_child(env)
	var luz := DirectionalLight3D.new()                 # dorada, desde arriba a la izquierda
	luz.light_color = Color("FFE2B0")
	luz.light_energy = 1.25
	luz.rotation_degrees = Vector3(-50, -35, 0)
	luz.shadow_enabled = pasada == "color"
	luz.directional_shadow_max_distance = caja.size.length() * 3.0
	vp.add_child(luz)
	var relleno := DirectionalLight3D.new()             # relleno azul al 30 % desde la derecha
	relleno.light_color = Color("7FA0D8")
	relleno.light_energy = 0.3
	relleno.rotation_degrees = Vector3(-20, 120, 0)
	vp.add_child(relleno)
	modelo.get_parent().remove_child(modelo)
	vp.add_child(modelo)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = hs / ny
	cam.near = 0.01
	cam.far = caja.size.length() * 10.0
	vp.add_child(cam)
	var dir := Vector3(0, sin(r), cos(r))
	cam.look_at_from_position(centro + dir * caja.size.length() * 3.0, centro)
	cam.current = true
	var z_min := caja.position.z
	var z_max := caja.end.z
	if pasada != "color":
		var tex: Texture2D = null
		var m0 = malla.get_active_material(0)
		if m0 is StandardMaterial3D:
			tex = m0.albedo_texture
		var sm := ShaderMaterial.new()
		sm.shader = Shader.new()
		if pasada == "mascara":
			sm.shader.code = SHADER_MASCARA
			sm.set_shader_parameter("color_tex", tex)
			sm.set_shader_parameter("suelo_min", SUELO_MIN)
			sm.set_shader_parameter("suelo_max", SUELO_MAX)
		else:
			sm.shader.code = SHADER_PROFUNDIDAD
			sm.set_shader_parameter("color_tex", tex)
			sm.set_shader_parameter("suelo_min", SUELO_MIN)
			sm.set_shader_parameter("suelo_max", SUELO_MAX)
			sm.set_shader_parameter("z_min", z_min)
			sm.set_shader_parameter("z_max", z_max)
		malla.material_override = sm
	for j in ny:
		for i in nx:
			tareas.append([i, j])
	# en el juego, un punto del suelo en la fila de píxeles «py» está a esta profundidad (0..1):
	#   z = suelo*cos/sin - (arriba de la imagen - py/alto*hs)/sin  (cámara ortográfica inclinada)
	var arriba_img := (centro.y * cos(r) - centro.z * sin(r)) + hs * 0.5    # coordenada «vertical de pantalla» de la fila 0
	datos = {"ancho": ancho, "alto": alto, "trozos_x": nx, "trozos_y": ny, "inclinacion": incl,
		"metros_ancho": ws, "metros_alto": hs, "suelo": suelo, "z_min": z_min, "z_max": z_max,
		"arriba_img": arriba_img, "sen": sin(r), "cos": cos(r), "triangulos": _triangulos()}
	print("isla: ", caja, "  suelo ", suelo, "  imagen ", ancho, "x", alto)


func _triangulos() -> int:
	var t := 0
	for s in malla.mesh.get_surface_count():
		t += malla.mesh.surface_get_array_index_len(s) / 3
	return t


# Altura de las calles: la altura más repetida entre los triángulos que miran hacia arriba.
func _altura_suelo() -> float:
	var arr := malla.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var tr := malla.global_transform
	var cubos := {}
	var paso := caja.size.y / 200.0
	var k := 0
	while k + 2 < idx.size():
		var p0 := tr * v[idx[k]]
		var p1 := tr * v[idx[k + 1]]
		var p2 := tr * v[idx[k + 2]]
		var n := (p1 - p0).cross(p2 - p0)
		var area := n.length()
		if area > 0.0 and absf(n.y / area) > 0.9:
			var c := int(((p0.y + p1.y + p2.y) / 3.0 - caja.position.y) / paso)
			cubos[c] = cubos.get(c, 0.0) + area
		k += 3 * 7                                        # uno de cada 7 basta
	var mejor := 0
	for c in cubos:
		if cubos[c] > cubos.get(mejor, 0.0):
			mejor = c
	return caja.position.y + (mejor + 0.5) * paso


func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		_preparar()
		return false
	if frames < 3:
		return false
	var k := (frames - 3) / 4
	var fase := (frames - 3) % 4
	if k >= tareas.size():
		var f := FileAccess.open(a[1] + "/datos.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(datos, "\t"))
		return true
	var i: int = tareas[k][0]
	var j: int = tareas[k][1]
	if fase == 0:
		cam.h_offset = -ws * 0.5 + (i + 0.5) * ws / nx
		cam.v_offset = hs * 0.5 - (j + 0.5) * hs / ny
	elif fase == 3:
		vp.get_texture().get_image().save_png("%s/%s_%d_%d.png" % [a[1], pasada, i, j])
	return false
