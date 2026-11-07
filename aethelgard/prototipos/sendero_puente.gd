extends "res://prototipos/vista3d.gd"
# PROTOTIPO AISLADO — Pastos Verdes (escena de muestra de la nueva dirección gráfica).
# Camino de losas entre colinas verdes, puente medieval de piedra sobre el barranco del río, cascada,
# árboles, arbustos, hierba y flores con viento, rocas, faroles, conejos, pájaro y mariposas.
# Kael original con la cámara de 45° de vista3d.gd.
# No lo usa ninguna escena del juego ni entra en el APK del juego (sí en el APK «Android prueba 3D»).
# Abrir: prototipos/sendero_puente.tscn (F6). Controles: los de vista3d.gd.
#
# Todo se genera por código y sin addons: texturas de detalle con ruido de Godot (NoiseTexture2D),
# mallas propias y MultiMesh para lo que se repite (hierba, flores, losas, arbustos).
# Calidad: en el móvil (o con «-- movil») hay menos hierba y sin sombras.

const TAM := 110.0                # lado del terreno (m): mucho más que lo que ve la cámara
const PASO := 0.6                 # separación de los vértices del terreno (m)
const RIO_X := 9.0                # centro del barranco
const RIO_ANCHO := 2.6            # media anchura del fondo del barranco
const BORDE := 1.1                # anchura de la pared (de arriba al fondo)
const FONDO := -6.0               # profundidad del barranco
const CASCADA_Z := -16.0          # río arriba de aquí, el agua va por un canal a nivel del suelo
const AGUA_RIO := FONDO + 0.35    # altura del agua del río (sin olas)
const AGUA_CANAL := -0.45         # altura del agua del canal de arriba
const CANAL_SOLAPE := 0.3         # el canal sobresale del borde y tapa el arranque de la cascada
const OLAS := 0.3                 # altura de las olas (el sombreado traía 1,5 m: el canal rebosaba)
const LIMITE := Rect2(-21, -23, 48, 44)   # zona por la que puede andar Kael (x, z): el borde nunca se ve
const SENDERO := [Vector3(-16, 0, 16), Vector3(-9, 0, 9), Vector3(-3, 0, 5), Vector3(2, 0, -0.5),
	Vector3(RIO_X - RIO_ANCHO - BORDE - 0.6, 0, -2), Vector3(RIO_X + RIO_ANCHO + BORDE + 0.6, 0, -2),
	Vector3(16, 0, -6), Vector3(20, 0, -14), Vector3(22, 0, -22)]

var movil := false
var perfil: Dictionary = {}       # perfil de calidad (prototipos/calidad_proto.gd)
var hierba_n := 6000
var flores_n := 600
const TROZO_HIERBA := 12.0
# Árboles del mapa: "mezcla" (pradera + abedul + mágico en lugares especiales, elegido por el autor),
# "pradera", "abedul", "magico" o "arce" (los arces de Meshy anteriores, para volver atrás).
const ARBOLES_MAPA := "mezcla"
const SITIOS_MAGICOS := [Vector3(4, 0, -16), Vector3(16, 0, 2)]   # junto a la estatua y a la salida del puente
var arboles_mapa := true         # false: sin los árboles del mapa (lo usa prototipos/arboles_prueba.gd)
const ARBOLES_3D := true         # Fase 2.1: árboles 3D (tronco real + copa de matas del arce de Meshy)
const ARBOLES_TARJETA := false    # tarjeta plana (descartada: «parece una hoja de papel»); se queda como reserva
# Medido: en Compatibility, activar las sombras de la luz principal aclara toda la imagen (brillo medio
# 0,66 frente a 0,48 en la misma vista). Con sombras se baja la exposición para igualar los perfiles.
const EXPO_CON_SOMBRAS := 0.58
var tex_detalle: Texture2D       # grano para hierba, tierra y piedra (gris claro, se multiplica por el color)
var tex_relieve: Texture2D        # mapa de normales del mismo ruido

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
# Copas y arbustos: se mecen más cuanto más arriba; el color se multiplica por el de cada instancia.
const SHADER_COPA := """
shader_type spatial;
uniform vec3 color : source_color = vec3(0.3, 0.55, 0.22);
uniform vec3 luz : source_color = vec3(0.55, 0.75, 0.3);
uniform float vaiven = 0.08;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.3 + w.x * 0.2 + w.z * 0.17);
	VERTEX.x += s * vaiven * max(VERTEX.y + 0.5, 0.0);
	VERTEX.z += sin(TIME * 1.1 + w.z * 0.3) * vaiven * 0.6 * max(VERTEX.y + 0.5, 0.0);
}
void fragment() {
	ALBEDO = mix(color, luz, clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0) * 0.6) * COLOR.rgb;
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
	vec3 c = mix(vec3(0.45, 0.78, 0.9), vec3(0.97, 0.99, 1.0), smoothstep(0.5, 1.0, raya));
	float borde = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x);
	ALBEDO = c;
	ALPHA = (0.9 - 0.25 * smoothstep(0.85, 1.0, UV.y)) * borde;
}
"""


func _ready() -> void:
	perfil = load("res://prototipos/calidad_proto.gd").datos()
	movil = load("res://prototipos/calidad_proto.gd").actual() == "bajo"
	hierba_n = perfil["hierba"]
	flores_n = perfil["flores"]
	_crear_texturas()
	super._ready()
	var inicio: Vector3 = SENDERO[0] + Vector3(0, altura(SENDERO[0].x, SENDERO[0].z), 0)
	kael.global_position = inicio
	seguro = inicio
	foco = inicio
	_colocar_camara(1.0)
	_crear_fauna()
	_titulo_zona("Pastos Verdes")


# ---------------------------------------------------------------- texturas (ruido de Godot, sin archivos)

func _crear_texturas() -> void:
	var ruido := FastNoiseLite.new()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.frequency = 0.045
	ruido.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = ruido
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(0.74, 0.74, 0.74), Color(1.06, 1.06, 1.06)])
	nt.color_ramp = rampa
	nt.generate_mipmaps = true
	tex_detalle = nt
	var nn := NoiseTexture2D.new()
	nn.width = 256
	nn.height = 256
	nn.seamless = true
	nn.noise = ruido
	nn.as_normal_map = true
	nn.bump_strength = 6.0
	nn.generate_mipmaps = true
	tex_relieve = nn


# Material con grano y relieve, proyectado desde los tres ejes (las paredes de roca no se estiran).
func _mat_detalle(color := Color.WHITE, escala := 0.5, por_vertice := false, relieve := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = tex_detalle
	m.vertex_color_use_as_albedo = por_vertice
	m.normal_enabled = perfil.get("relieve", true)      # perfil bajo: sin mapas de relieve (3 lecturas menos por píxel)
	m.normal_texture = tex_relieve
	m.normal_scale = relieve
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * escala
	m.roughness = 0.92
	return m


# ---------------------------------------------------------------- terreno

static func _dist_sendero_xz(x: float, z: float) -> float:
	var mejor := 999.0
	for k in SENDERO.size() - 1:
		var a: Vector3 = SENDERO[k]
		var b: Vector3 = SENDERO[k + 1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var ap := Vector2(x - a.x, z - a.z)
		var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		mejor = minf(mejor, (ap - ab * t).length())
	return mejor


func _dist_sendero(p: Vector3) -> float:
	return _dist_sendero_xz(p.x, p.z)


# Altura del terreno en (x, z): colinas suaves que se aplanan junto al camino, el barranco del río,
# el canal río arriba de la cascada y lomas altas en los bordes que cierran el encuadre.
static func altura(x: float, z: float) -> float:
	var h := 0.18 * sin(x * 0.31) * cos(z * 0.27) + 0.12 * sin(x * 0.7 + z * 0.5)
	var colinas := 1.6 * (0.5 + 0.5 * sin(x * 0.13 + 1.0) * cos(z * 0.11 - 0.6)) + 0.8 * maxf(0.0, sin(x * 0.07 - z * 0.09 + 2.0))
	var junto_camino := smoothstep(2.0, 7.0, _dist_sendero_xz(x, z))
	var junto_rio := smoothstep(RIO_ANCHO + BORDE + 1.0, RIO_ANCHO + BORDE + 6.0, absf(x - RIO_X))
	h += colinas * junto_camino * junto_rio
	var lejos := maxf(absf(x - 3.0) - 25.0, 0.0) + maxf(-z - 26.0, 0.0) + maxf(z - 23.0, 0.0)
	h += lejos * 0.32 + 0.006 * lejos * lejos                 # lomas verdes en los bordes (suaves: sin paredes)
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
	var hierba := Color(0.4, 0.6, 0.24).lerp(Color(0.52, 0.66, 0.27), 0.5 + 0.5 * sin(x * 0.4 + z * 0.3))
	hierba = hierba.lerp(Color(0.36, 0.55, 0.26), clampf(y * 0.25, 0.0, 0.5))   # cumbres algo más frescas
	var tierra := Color(0.58, 0.46, 0.32)
	var roca := Color(0.56, 0.54, 0.52).lerp(Color(0.42, 0.4, 0.39), 0.5 + 0.5 * sin(y * 2.3 + z))
	var ds := _dist_sendero_xz(x, z)
	if ds < 1.9:
		hierba = hierba.lerp(tierra, 0.8 * (1.0 - smoothstep(1.2, 1.9, ds)))   # tierra pisada junto a las losas
	if y < -0.5 and pendiente < 0.3:
		return Color(0.4, 0.44, 0.34)                          # fondo del barranco, húmedo
	return hierba.lerp(roca, smoothstep(0.5, 0.85, pendiente))   # roca solo en las paredes de verdad


func _crear_terreno() -> void:
	var n := int(TAM / PASO)
	var x0 := -TAM * 0.5 + 3.0
	var z0 := -TAM * 0.5
	var alturas := []
	for i in n + 1:
		var fila := PackedFloat32Array()
		fila.resize(n + 1)
		for j in n + 1:
			fila[j] = altura(x0 + j * PASO, z0 + i * PASO)
		alturas.append(fila)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n + 1:
		for j in n + 1:
			var x := x0 + j * PASO
			var z := z0 + i * PASO
			var y: float = alturas[i][j]
			var dx: float = alturas[i][mini(j + 1, n)] - alturas[i][maxi(j - 1, 0)]
			var dz: float = alturas[mini(i + 1, n)][j] - alturas[maxi(i - 1, 0)][j]
			var pendiente := clampf(sqrt(dx * dx + dz * dz) / (2.0 * PASO), 0.0, 1.0)
			st.set_color(_color_terreno(x, z, y, pendiente))
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
	mi.material_override = _mat_detalle(Color.WHITE, 0.45, true, 0.5)
	var cuerpo := StaticBody3D.new()
	add_child(cuerpo)
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	col.shape = malla.create_trimesh_shape()
	cuerpo.add_child(col)


# Zonas que no se pisan (Skill aet-fisica-recorrido): fuera de la zona jugable (así la cámara nunca
# enseña el borde del terreno), el barranco del río salvo sobre el puente, y el canal de la cascada.
func _prohibido(p: Vector3) -> bool:
	if not LIMITE.has_point(Vector2(p.x, p.z)):
		return true
	var d := absf(p.x - RIO_X)
	if p.z > CASCADA_Z - 0.5:
		if d < RIO_ANCHO + BORDE + 0.25:
			var sobre_puente := absf(p.z - (-2.0)) < 1.05 and p.x > SENDERO[4].x - 0.6 and p.x < SENDERO[5].x + 0.6
			return not sobre_puente
	elif d < 2.4:
		return true                                     # canal que alimenta la cascada
	return false


# ---------------------------------------------------------------- sendero, puente, agua

func _crear_sendero() -> void:
	var puntos: Array = []
	for k in SENDERO.size() - 1:
		if k == 4:
			continue                                 # el tramo del puente no lleva losas
		var a: Vector3 = SENDERO[k]
		var b: Vector3 = SENDERO[k + 1]
		var largo := Vector2(b.x - a.x, b.z - a.z).length()
		var lado := Vector3(-(b.z - a.z), 0, b.x - a.x).normalized()
		var pasos := int(largo / 0.75)
		for s in pasos:
			var c := a.lerp(b, (s + 0.5) / pasos)
			for fila in [-0.75, 0.0, 0.75]:
				if randf() < 0.06:
					continue                         # alguna losa que falta: más natural
				var p: Vector3 = c + lado * (fila + randf_range(-0.18, 0.18)) + Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
				puntos.append(p)
	var losa := CylinderMesh.new()
	losa.top_radius = 0.34
	losa.bottom_radius = 0.38
	losa.height = 0.12
	losa.radial_segments = 7
	losa.rings = 1
	losa.material = _mat_detalle(Color.WHITE, 1.4, true, 1.0)
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
		var g := randf_range(0.5, 0.66)                       # piedra gris cálida, sin quemarse a blanco
		mm.set_instance_color(k, Color(g, g * 0.95, g * 0.86))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # las losas reciben sombra, no la dan (casi invisible y cara)
	add_child(mmi)


# ---------------------------------------------------------------- agrupación de geometría
# Las piezas pequeñas que no se mueven y comparten material (puente, rocas, montañas) se juntan en
# una sola malla por material: una llamada de dibujo en vez de decenas. Las colisiones siguen siendo
# piezas separadas. No se agrupa lo que conviene recortar por separado (árboles, hierba en trozos).
var _lotes := {}                                    # Material -> SurfaceTool


func _al_lote(malla: Mesh, t: Transform3D, mat: Material) -> void:
	if not _lotes.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_lotes[mat] = st
	_lotes[mat].append_from(malla, 0, t)


func _cerrar_lotes() -> void:
	for mat in _lotes:
		var mi := MeshInstance3D.new()
		mi.mesh = _lotes[mat].commit()
		mi.material_override = mat
		add_child(mi)
	_lotes.clear()


func _bloque(pos: Vector3, tam: Vector3, mat: Material, giro := Vector3.ZERO, choca := true) -> void:
	var bm := BoxMesh.new()
	bm.size = tam
	_al_lote(bm, Transform3D(Basis.from_euler(giro), pos), mat)
	if choca:
		var cuerpo := StaticBody3D.new()
		cuerpo.position = pos
		cuerpo.rotation = giro
		add_child(cuerpo)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = tam
		col.shape = bs
		cuerpo.add_child(col)


# Puente medieval de piedra: un arco rebajado de dovelas entre las dos paredes del barranco, relleno
# de piedra hasta el tablero, tablero algo abombado y pretiles a los lados (Kael no puede caerse).
func _crear_puente() -> void:
	var x0: float = SENDERO[4].x - 0.4
	var x1: float = SENDERO[5].x + 0.4
	var z: float = -2.0
	var ancho := 2.6
	var piedra := _mat_detalle(Color(0.7, 0.66, 0.6), 0.9, false, 1.0)
	var piedra_oscura := _mat_detalle(Color(0.58, 0.55, 0.5), 0.9, false, 1.0)
	var musgo := _mat_detalle(Color(0.45, 0.55, 0.32), 0.9, false, 0.8)
	var cx := (x0 + x1) * 0.5
	var medio := (x1 - x0) * 0.5
	var flecha := 0.3                                       # cuánto sube el tablero en el centro
	var tablero := func(x: float) -> float: return flecha * (1.0 - pow((x - cx) / medio, 2.0))
	# tablero en tramos que siguen la curva
	var tramos := 12
	for k in tramos:
		var xa := lerpf(x0, x1, float(k) / tramos)
		var xb := lerpf(x0, x1, float(k + 1) / tramos)
		var ya: float = tablero.call(xa)
		var yb: float = tablero.call(xb)
		var giro := Vector3(0, 0, atan2(yb - ya, xb - xa))
		var c := Vector3((xa + xb) * 0.5, (ya + yb) * 0.5 - 0.2, z)
		_bloque(c, Vector3(xb - xa + 0.04, 0.4, ancho), piedra, giro)
		if k == 0 or k == tramos - 1:
			continue                                          # extremos abiertos: se entra y sale en diagonal
		for lado in [-1.0, 1.0]:                            # pretiles
			_bloque(c + Vector3(0, 0.55, lado * (ancho * 0.5 - 0.15)), Vector3(xb - xa + 0.04, 0.75, 0.3),
				piedra_oscura if k % 2 == 0 else piedra, giro)
			_bloque(c + Vector3(0, 0.97, lado * (ancho * 0.5 - 0.15)), Vector3(xb - xa + 0.06, 0.1, 0.38), piedra, giro, false)
	# arco de dovelas
	var mitad_luz := RIO_ANCHO + 0.7
	var subida := 2.0
	var arranque := -2.6
	var r := (mitad_luz * mitad_luz + subida * subida) / (2.0 * subida)
	var centro := Vector2(RIO_X, arranque + subida - r)
	var a0 := atan2(arranque - centro.y, -mitad_luz)
	var a1 := atan2(arranque - centro.y, mitad_luz)
	var dovelas := 15
	for k in dovelas:
		var a := lerpf(a0, a1, (k + 0.5) / dovelas)
		var p := centro + Vector2(cos(a), sin(a)) * (r + 0.28)
		var largo := r * absf(a1 - a0) / dovelas + 0.04
		_bloque(Vector3(p.x, p.y, z), Vector3(largo, 0.56, ancho - 0.1), piedra_oscura if k % 2 else piedra, Vector3(0, 0, a - PI * 0.5), false)
	# relleno (enjutas) entre el arco y el tablero
	var columnas := 14
	for k in columnas:
		var x := lerpf(RIO_X - mitad_luz - 0.4, RIO_X + mitad_luz + 0.4, (k + 0.5) / columnas)
		var dx := clampf(x - centro.x, -r, r)
		var y_arco := centro.y + sqrt(maxf(r * r - dx * dx, 0.0)) + 0.56
		var y_tab: float = tablero.call(clampf(x, x0, x1)) - 0.4
		if y_tab - y_arco > 0.05:
			var ancho_col := (2.0 * mitad_luz + 0.8) / columnas + 0.03
			_bloque(Vector3(x, (y_tab + y_arco) * 0.5, z), Vector3(ancho_col, y_tab - y_arco, ancho - 0.3), piedra, Vector3.ZERO, false)
	# estribos en cada orilla y musgo en la base
	for x in [x0 - 0.2, x1 + 0.2]:
		_bloque(Vector3(x, -1.25, z), Vector3(1.4, 2.4, ancho + 0.4), piedra_oscura, Vector3.ZERO, false)
		_bloque(Vector3(x, -0.05, z + (ancho * 0.5 + 0.1)), Vector3(1.0, 0.25, 0.3), musgo, Vector3.ZERO, false)


func _poste(pos: Vector3, alto: float, farol := false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, alto, 0.16)
	mi.mesh = bm
	mi.material_override = _mat_detalle(Color(0.5, 0.36, 0.24), 1.5, false, 1.0)
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
		if perfil["luces_faroles"]:                     # en Compatibility cada luz redibuja lo que toca
			var luz := OmniLight3D.new()
			luz.light_color = Color(1.0, 0.75, 0.4)
			luz.light_energy = 1.2
			luz.omni_range = 4.0
			luz.position = f.position
			add_child(luz)
		else:
			_halo_falso(pos, f.position)


# Halo falso de un farol (perfiles sin luces reales). Medido en el Redmi: las dos luces de los faroles
# costaban ~7 ms por fotograma. En su lugar: un disco de luz cálida pintado en el suelo (sumando color,
# sin escribir profundidad) y un resplandor suave alrededor de la caja del farol. Casi gratis.
func _halo_falso(suelo: Vector3, farol: Vector3) -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.72, 0.38, 0.28), Color(1.0, 0.66, 0.3, 0.09), Color(1.0, 0.6, 0.25, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = false
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = tex
	var disco := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.0, 5.0)
	disco.mesh = pm
	disco.material_override = m
	disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disco.position = suelo + Vector3(0, 0.12, 0)          # algo por encima del suelo y de las losas: sin parpadeos
	add_child(disco)
	var brillo := Sprite3D.new()                          # resplandor alrededor de la caja del farol
	brillo.texture = tex
	brillo.pixel_size = 1.4 / 64.0
	brillo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	brillo.shaded = false
	brillo.transparent = true
	brillo.modulate = Color(1, 1, 1, 0.9)
	brillo.position = farol
	brillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(brillo)


func _mat_agua() -> Material:
	if not ResourceLoader.exists("res://shaders/water.gdshader"):
		return _mat(Color(0.2, 0.55, 0.75), 0.1)
	var sm := ShaderMaterial.new()
	# perfil alto: el agua original con refracción; bajo y medio: la variante sin textura de pantalla
	# (con ella Godot copia la pantalla entera cada fotograma aunque la refracción esté apagada)
	if perfil["refraccion"]:
		sm.shader = load("res://shaders/water.gdshader")
	else:
		sm.shader = load("res://prototipos/agua_sin_refraccion.gdshader")
	# el shader necesita sus texturas de olas y normales (sin ellas el agua sale plana)
	var olas := FastNoiseLite.new()
	olas.frequency = 0.02
	var t_olas := NoiseTexture2D.new()
	t_olas.seamless = true
	t_olas.noise = olas
	var n1 := NoiseTexture2D.new()
	n1.seamless = true
	n1.as_normal_map = true
	n1.bump_strength = 3.0
	var r1 := FastNoiseLite.new()
	r1.frequency = 0.04
	n1.noise = r1
	var n2 := NoiseTexture2D.new()
	n2.seamless = true
	n2.as_normal_map = true
	n2.bump_strength = 2.0
	var r2 := FastNoiseLite.new()
	r2.frequency = 0.07
	r2.seed = 7
	n2.noise = r2
	sm.set_shader_parameter("wave_noise", t_olas)
	sm.set_shader_parameter("normal_1", n1)
	sm.set_shader_parameter("normal_2", n2)
	sm.set_shader_parameter("albedo_1", Color(0.06, 0.36, 0.42))
	sm.set_shader_parameter("albedo_2", Color(0.32, 0.74, 0.76))
	sm.set_shader_parameter("wave_speed", 0.04)
	sm.set_shader_parameter("wave_size", OLAS)
	return sm


func _crear_agua() -> void:
	var mat_agua := _mat_agua()
	# río en el fondo del barranco (hasta lejos, fuera de la vista) y canal de arriba. El canal llega
	# CANAL_SOLAPE metros más allá del borde para tapar la parte de arriba de la cascada (sin hueco).
	for datos in [[Vector3(RIO_X, AGUA_RIO, (CASCADA_Z + 56.0) * 0.5), Vector2(RIO_ANCHO * 2.0 + 0.6, 56.0 - CASCADA_Z)],
			[Vector3(RIO_X, AGUA_CANAL, (CASCADA_Z + CANAL_SOLAPE - 56.0) * 0.5), Vector2(3.4, 56.0 + CASCADA_Z + CANAL_SOLAPE)]]:
		var agua := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = datos[1]
		pm.subdivide_depth = 8
		agua.mesh = pm
		agua.position = datos[0]
		agua.material_override = mat_agua
		agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(agua)
	# La cascada: dos cortinas con rayas que caen. Antes eran rectángulos verticales metidos en la pendiente
	# de la pared (de z = CASCADA_Z a CASCADA_Z + 0,6): la mitad de abajo quedaba detrás de la roca.
	# Ahora cada cortina va inclinada, siempre por delante de la pared (sin superficies casi coplanares),
	# es más ancha abajo (no se ve como un rectángulo), empieza bajo el agua del canal y termina por
	# debajo del agua del río: no queda ningún hueco. La espuma tapa el contacto con el río.
	var cm := ShaderMaterial.new()
	cm.shader = Shader.new()
	cm.shader.code = SHADER_CASCADA
	for capa in [[3.0, 3.9, 0.12, 0.95], [2.2, 3.0, 0.3, 1.15]]:   # ancho arriba, ancho abajo, z arriba, z abajo
		var arriba := Vector3(RIO_X, AGUA_CANAL + 0.05, CASCADA_Z + capa[2])
		var abajo := Vector3(RIO_X, AGUA_RIO - 0.35, CASCADA_Z + capa[3])
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var esquinas := [[arriba - Vector3(capa[0] * 0.5, 0, 0), Vector2(0, 0)], [arriba + Vector3(capa[0] * 0.5, 0, 0), Vector2(1, 0)],
			[abajo - Vector3(capa[1] * 0.5, 0, 0), Vector2(0, 1)], [abajo + Vector3(capa[1] * 0.5, 0, 0), Vector2(1, 1)]]
		for k in [0, 1, 2, 1, 3, 2]:
			st.set_uv(esquinas[k][1])
			st.add_vertex(esquinas[k][0])
		st.generate_normals()
		var cortina := MeshInstance3D.new()
		cortina.mesh = st.commit()
		cortina.material_override = cm
		cortina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cortina)
	var espuma := CPUParticles3D.new()
	espuma.amount = perfil["espuma"]
	espuma.lifetime = 1.4
	espuma.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	espuma.emission_box_extents = Vector3(2.0, 0.1, 0.4)
	espuma.direction = Vector3(0, 1, 1)
	espuma.spread = 35.0
	espuma.initial_velocity_min = 0.8
	espuma.initial_velocity_max = 1.8
	espuma.gravity = Vector3(0, -0.6, 0)
	espuma.scale_amount_min = 0.5
	espuma.scale_amount_max = 1.5
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
	espuma.color_ramp = g
	var bola := SphereMesh.new()
	bola.radius = 0.2
	bola.height = 0.4
	bola.radial_segments = 6
	bola.rings = 3
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.vertex_color_use_as_albedo = true
	bola.material = bm
	espuma.mesh = bola
	espuma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	espuma.position = Vector3(RIO_X, AGUA_RIO + 0.1, CASCADA_Z + 1.1)   # justo donde la cortina entra en el río
	add_child(espuma)
	# rocas mojadas a los lados de la caída, arriba y abajo
	var roca := _mat_detalle(Color(0.45, 0.45, 0.46), 0.8, false, 1.0)
	for p in [Vector3(RIO_X - 2.1, -0.3, CASCADA_Z - 0.4), Vector3(RIO_X + 2.2, -0.2, CASCADA_Z - 0.2),
			Vector3(RIO_X - 2.0, FONDO + 0.4, CASCADA_Z + 1.2), Vector3(RIO_X + 1.9, FONDO + 0.3, CASCADA_Z + 1.5)]:
		_roca(p, randf_range(0.6, 0.9), roca)


func _roca(p: Vector3, r: float, mat: Material) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 1.3
	sm.radial_segments = 8
	sm.rings = 5
	var b := Basis.from_euler(Vector3(randf(), randf() * TAU, randf()) * 0.4).scaled(
		Vector3(randf_range(0.9, 1.3), randf_range(0.7, 1.0), randf_range(0.9, 1.2)))
	_al_lote(sm, Transform3D(b, p), mat)                # todas las rocas: una malla por material


# ---------------------------------------------------------------- vegetación

func _mat_copa(color: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_COPA
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("luz", color.lightened(0.35))
	return mat


func _arbol_viento(pos: Vector3, alto: float, color: Color) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	add_child(cuerpo)
	var tronco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18
	cm.bottom_radius = 0.4
	cm.height = alto * 0.6
	cm.radial_segments = 8
	tronco.mesh = cm
	tronco.position.y = alto * 0.3
	tronco.material_override = _mat_detalle(Color(0.45, 0.32, 0.22), 1.2, false, 1.2)
	cuerpo.add_child(tronco)
	# copa hecha de varias bolas (silueta natural) juntadas en UNA malla: 1 llamada de dibujo por copa
	# en vez de 5. Cada árbol sigue siendo una pieza aparte (se recorta y se vuelve transparente solo).
	var centro_copa := alto * 0.78
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 5:
		var sm := SphereMesh.new()
		var r := alto * randf_range(0.2, 0.27)
		sm.radius = r
		sm.height = r * 1.7
		sm.radial_segments = 12
		sm.rings = 7
		var a := k * TAU / 4.0 + randf() * 0.5
		var p := Vector3(cos(a) * alto * 0.14, alto * randf_range(0.66, 0.8), sin(a) * alto * 0.14) if k > 0 else Vector3(0, alto * 0.9, 0)
		st.append_from(sm, 0, Transform3D(Basis(), p - Vector3(0, centro_copa, 0)))
	var copa := MeshInstance3D.new()
	copa.mesh = st.commit()
	copa.material_override = _mat_copa(color)
	copa.position.y = centro_copa                       # el vaivén se calcula desde el centro de la copa
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
	return cuerpo


# Árbol de tarjeta (Fase 2.1): la imagen del árbol de Meshy renderizada desde el ángulo de la cámara
# (pruebas/herramientas/tarjeta_arbol.gd) en un plano que siempre la mira (2 triángulos en vez de 102 000).
# Debajo va el árbol sencillo de siempre, pero INVISIBLE: solo da la sombra y la colisión.
# Como la tarjeta es vertical y la cámara mira a 45°, se adelanta hacia la cámara y se sube lo mismo que
# sobresalen las raíces por delante de la base: así nada queda enterrado y la base se ve en su sitio.
var _tarjetas := {}                                    # nombre -> [material, datos]


func _arbol_tarjeta(pos: Vector3, nombre: String, escala: float, espejo: bool) -> void:
	if not _tarjetas.has(nombre):
		var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modelos/%s/%s_tarjeta.json" % [nombre, nombre]))
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://modelos/%s/%s_tarjeta.png" % [nombre, nombre])
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED    # la luz ya va en la imagen (misma que la escena)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR  # recortado: sin mezcla (barato en móvil)
		m.alpha_scissor_threshold = 0.45
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.billboard_keep_scale = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_tarjetas[nombre] = [m, datos]
	var mat: StandardMaterial3D = _tarjetas[nombre][0]
	var d: Dictionary = _tarjetas[nombre][1]
	var alto: float = 6.5 * escala                        # la tarjeta se hizo para un árbol de 6,5 m
	var cuerpo := _arbol_viento(pos, alto, Color(0.3, 0.5, 0.2))
	for mi in cuerpo.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY   # solo sombra
		mi.remove_from_group("ocluye")
	var q := QuadMesh.new()
	q.size = Vector2(d["ancho"], d["alto"]) * escala
	q.center_offset = Vector3(-d["base_x"] * escala, (d["alto"] * 0.5 - d["base_y"]) * escala, 0)
	var tarjeta := MeshInstance3D.new()
	tarjeta.mesh = q
	tarjeta.material_override = mat.duplicate()          # cada árbol el suyo (se vuelve transparente solo)
	tarjeta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var t: float = d["base_y"] * escala * sin(deg_to_rad(d["inclinacion"]))
	tarjeta.position = Vector3(0, t, t)                  # hacia la cámara (+z) y hacia arriba lo mismo
	if espejo:
		tarjeta.scale.x = -1.0                           # variedad: la misma imagen, reflejada
	cuerpo.add_child(tarjeta)
	tarjeta.add_to_group("ocluye")


# Árbol 3D (Fase 2.1, sustituye a la tarjeta plana): tronco real del arce de Meshy reducido (~1 600 triángulos)
# y copa de 36 matas de hojas del propio arce repartidas en forma de bola, con normales de esfera: la luz de la
# escena las ilumina como un volumen (arriba claro, abajo en sombra) y da sombra propia. Se ve 3D desde
# cualquier ángulo. Hecho con pruebas/herramientas/arbol_3d_meshy.gd.
var _arbol3d := {}                                     # nombre -> [malla tronco, malla copa, mat tronco, mat copa, datos]


func _arbol_3d(pos: Vector3, nombre: String, escala: float, giro: float) -> void:
	if not _arbol3d.has(nombre):
		var base := "res://modelos/%s/%s" % [nombre, nombre]
		var mt := _mat_detalle(Color.WHITE, 1.0, false, 0.0)
		mt.albedo_texture = load(base + "_tronco_color.png")
		mt.normal_enabled = false
		mt.uv1_triplanar = false
		var mc := StandardMaterial3D.new()
		mc.albedo_texture = load(base + "_matas.png")
		mc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR   # recortado: sin mezcla (barato en móvil)
		mc.alpha_scissor_threshold = 0.5
		mc.cull_mode = BaseMaterial3D.CULL_DISABLED
		mc.roughness = 1.0
		mc.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mc.backlight_enabled = true                       # algo de luz atravesando las hojas
		mc.backlight = Color(0.25, 0.22, 0.1)
		var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "_3d.json"))
		_arbol3d[nombre] = [load(base + "_tronco.res"), load(base + "_copa.res"), mt, mc, datos]
	var a: Array = _arbol3d[nombre]
	var d: Dictionary = a[4]
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	cuerpo.rotation.y = giro
	cuerpo.scale = Vector3.ONE * escala
	add_child(cuerpo)
	var tronco := MeshInstance3D.new()
	tronco.mesh = a[0]
	tronco.material_override = a[2].duplicate()
	cuerpo.add_child(tronco)
	var copa := MeshInstance3D.new()
	copa.mesh = a[1]
	copa.material_override = a[3].duplicate()          # cada árbol el suyo: se vuelve transparente solo
	cuerpo.add_child(copa)
	for mi in [tronco, copa]:
		mi.add_to_group("ocluye")
	var centro := Vector3(d["copa_centro"][0], d["copa_centro"][1], d["copa_centro"][2])
	var radio: float = minf(d["copa_radios"][0], d["copa_radios"][2])
	var col := CollisionShape3D.new()                  # copa (para la oclusión) y tronco (Kael no lo atraviesa)
	var cs := SphereShape3D.new()
	cs.radius = radio
	col.shape = cs
	col.position = centro
	cuerpo.add_child(col)
	var col2 := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.35
	cil.height = centro.y
	col2.shape = cil
	col2.position.y = centro.y * 0.5
	cuerpo.add_child(col2)


func _opciones_arbol() -> Dictionary:
	return {"matas": perfil.get("arbol_matas", 1.0), "sombra_simple": perfil.get("arbol_sombra_simple", false)}


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
			var atlas = mi.get_meta("mat_original").get_shader_parameter("atlas")
			if atlas != null:                              # copas con textura de hojas: se ven las hojas, no un cuadrado
				m.albedo_texture = atlas
				m.vertex_color_use_as_albedo = true
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	var lista: Array = []
	var intentos := 0
	while lista.size() < hierba_n and intentos < hierba_n * 4:
		intentos += 1
		var p := Vector3(randf_range(-26, 32), 0, randf_range(-28, 26))
		if _libre(p, 1.2):
			lista.append(p)
	# la hierba va en trozos de TROZO_HIERBA metros: lo que queda fuera de la cámara no se dibuja, y más
	# allá de la distancia del perfil («dist_hierba») tampoco (el suelo ya tiene el color de la hierba)
	var trozos := {}
	for p in lista:
		var clave := Vector2i(floori(p.x / TROZO_HIERBA), floori(p.z / TROZO_HIERBA))
		if not trozos.has(clave):
			trozos[clave] = []
		trozos[clave].append(p)
	for clave in trozos:
		var centro := Vector3((clave.x + 0.5) * TROZO_HIERBA, 0, (clave.y + 0.5) * TROZO_HIERBA)
		centro.y = altura(centro.x, centro.z)
		var puntos: Array = trozos[clave]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = hoja
		mm.instance_count = puntos.size()
		for k in puntos.size():
			var p: Vector3 = puntos[k]
			var e := randf_range(0.6, 1.4)
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(e, e * randf_range(0.8, 1.3), e)),
				Vector3(p.x, altura(p.x, p.z), p.z) - centro))
			var tono := randf_range(0.85, 1.1)
			mm.set_instance_color(k, Color(tono, tono, tono * randf_range(0.9, 1.0)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = perfil["dist_hierba"]
		add_child(mmi)
	# flores: bolitas de color en matas (lavanda, rosa, blanco y amarillo, como la referencia)
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
	var intentos_f := 0
	while flores.size() < flores_n and intentos_f < 2000:
		intentos_f += 1
		var centro := Vector3(randf_range(-22, 28), 0, randf_range(-24, 22))
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


# Arbustos: matas redondas de tres o cuatro bolas, con el mismo vaivén que las copas (MultiMesh).
func _arbustos() -> void:
	var bola := SphereMesh.new()
	bola.radius = 0.5
	bola.height = 0.8
	bola.radial_segments = 10
	bola.rings = 6
	var mat := _mat_copa(Color(0.27, 0.48, 0.2))
	mat.set_shader_parameter("vaiven", 0.05)
	bola.material = mat
	var piezas: Array = []
	var intentos := 0
	while piezas.size() < 140 and intentos < 600:
		intentos += 1
		var c := Vector3(randf_range(-22, 28), 0, randf_range(-24, 22))
		if not _libre(c, 1.8) or _dist_sendero(c) > 6.0:
			continue                                 # bordean el camino, como en la referencia
		var tinte := Color(randf_range(0.85, 1.1), randf_range(0.9, 1.1), randf_range(0.8, 1.0))
		for k in randi_range(3, 4):
			var p := c + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
			var e := randf_range(0.6, 1.0)
			piezas.append([Transform3D(Basis().scaled(Vector3(e, e * 0.85, e)), Vector3(p.x, altura(p.x, p.z) + 0.2 * e, p.z)), tinte])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = bola
	mm.instance_count = piezas.size()
	for k in piezas.size():
		mm.set_instance_transform(k, piezas[k][0])
		mm.set_instance_color(k, piezas[k][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # matas bajas: reciben sombra, no la dan
	add_child(mmi)


# Mariposas: motas de color que revolotean despacio sobre las flores (partículas, casi gratis).
func _mariposas() -> void:
	for c in [Vector3(-6, 1.0, 9), Vector3(1, 1.0, 2), Vector3(18, 1.0, -9)]:
		var p := CPUParticles3D.new()
		p.amount = 6
		p.lifetime = 6.0
		p.preprocess = 6.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(3, 0.6, 3)
		p.direction = Vector3(1, 0.3, 0)
		p.spread = 180.0
		p.initial_velocity_min = 0.2
		p.initial_velocity_max = 0.5
		p.gravity = Vector3.ZERO
		p.angular_velocity_min = -90.0
		p.angular_velocity_max = 90.0
		var q := QuadMesh.new()
		q.size = Vector2(0.14, 0.1)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		q.material = m
		p.mesh = q
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 0.95, 0.6, 0.0), Color(1, 0.95, 0.6, 1), Color(1, 0.8, 0.9, 1), Color(1, 0.8, 0.9, 0.0)])
		g.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
		p.color_ramp = g
		p.position = c + Vector3(0, altura(c.x, c.z), 0)
		add_child(p)


# ---------------------------------------------------------------- composición

func _crear_ambiente() -> void:
	super._crear_ambiente()
	for n in get_children():                         # luz más cálida y cielo más intenso, como la referencia
		if n is DirectionalLight3D:
			n.light_color = Color(1.0, 0.9, 0.72)
			# (la luminosidad de los perfiles se iguala con la exposición: ver EXPO_CON_SOMBRAS)
			n.light_energy = perfil.get("luz_sol", 1.05)
			n.shadow_enabled = perfil["sombras"]
			n.directional_shadow_max_distance = perfil["dist_sombras"]
			n.shadow_blur = 1.5
			# Sombras más baratas sin cambiar su aspecto: Godot divide por defecto la sombra del sol en 4 tramos
			# y vuelve a pintar todo lo que da sombra en cada uno. Con la cámara elevada casi todo está a la
			# misma distancia, así que bastan 2 (o 1). La resolución del mapa de sombras va según el perfil.
			match int(perfil.get("sombra_tramos", 4)):
				1:
					n.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
				2:
					n.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				_:
					n.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			if perfil["sombras"]:
				RenderingServer.directional_shadow_atlas_set_size(int(perfil.get("sombra_res", 4096)), true)
		elif n is WorldEnvironment:
			var e: Environment = n.environment
			var cielo: ProceduralSkyMaterial = e.sky.sky_material
			cielo.sky_top_color = Color(0.25, 0.5, 0.92)
			cielo.sky_horizon_color = Color(0.72, 0.84, 0.95)
			e.fog_light_color = Color(0.78, 0.86, 0.95)
			e.fog_density = 0.0045
			e.ambient_light_color = Color(0.62, 0.7, 0.88)
			e.ambient_light_energy = 0.38
			# misma luminosidad en todos los perfiles: con sombras se baja la exposición (no el sol, que
			# dejaría la escena gris); medido con el brillo medio de la misma vista
			e.tonemap_exposure = perfil.get("exposicion", EXPO_CON_SOMBRAS if perfil["sombras"] else 1.0)
			e.adjustment_enabled = true                     # colores más vivos, como la ilustración de referencia
			e.adjustment_saturation = 1.3
			e.adjustment_contrast = 1.1
			# Reflejo del cielo («reflejo_cielo» del perfil): bajo y medio sin él, alto con él. Mali Offline Compiler: es
			# el coste evitable más alto de cada píxel iluminado (−13 a −26 % de cálculo); en el Redmi, −3,3 ms a 20 m y
			# −8 ms a 34 m, con −0,7 % de brillo (docs/vegetacion_rendimiento.md, ronda 8). Para recuperarlo: poner
			# "reflejo_cielo": true en prototipos/calidad_proto.gd (o {"reflejo_cielo": true} en «calidad_extra»).
			e.reflected_light_source = Environment.REFLECTION_SOURCE_BG if perfil.get("reflejo_cielo", true) \
				else Environment.REFLECTION_SOURCE_DISABLED


func _crear_escenario() -> void:
	seed(1234)                                           # la escena sale siempre igual: comparaciones justas
	_crear_terreno()
	_crear_sendero()
	_crear_puente()
	_crear_agua()
	# árboles enmarcando el camino (grandes en primer plano y más a los lados, como la referencia)
	var verdes := [Color(0.3, 0.54, 0.2), Color(0.38, 0.6, 0.22), Color(0.26, 0.47, 0.22)]
	var sitios := [Vector3(-13, 0, 6), Vector3(-6, 0, 12), Vector3(-19, 0, 12), Vector3(-1, 0, 10), Vector3(-8, 0, -4),
		Vector3(-14, 0, -6), Vector3(-2, 0, -9), Vector3(16, 0, 2), Vector3(22, 0, -4), Vector3(14, 0, -14),
		Vector3(-20, 0, -14), Vector3(4, 0, -16), Vector3(24, 0, 8), Vector3(-24, 0, 2), Vector3(26, 0, -18),
		Vector3(-12, 0, 18), Vector3(6, 0, 14), Vector3(-17, 0, -20)]
	var con_3d := ARBOLES_3D and ResourceLoader.exists("res://modelos/arce/arce_copa.res")
	var con_tarjetas := ARBOLES_TARJETA and ResourceLoader.exists("res://modelos/arce/arce_tarjeta.png")
	for p in sitios:
		var alto := randf_range(5.0, 7.5)
		var color: Color = verdes[randi() % verdes.size()]
		if not arboles_mapa:
			continue                                       # escena de comparación de árboles: el claro vacío
		# árboles estilizados (elegidos por el autor: los tres mezclados). El banco «ARB» puede forzar otro tipo.
		var tipo_est: String = perfil.get("arboles_tipo", ARBOLES_MAPA)
		if tipo_est != "arce":
			var tipo: String = tipo_est
			if tipo_est == "mezcla":
				tipo = "magico" if p in SITIOS_MAGICOS else ["pradera", "pradera", "abedul"][sitios.find(p) % 3]
			load("res://prototipos/arbol_estilizado.gd").crear(self, Vector3(p.x, altura(p.x, p.z), p.z), tipo, alto / 6.5, randf() * TAU, tex_detalle, _opciones_arbol())
			continue
		if con_3d:
			_arbol_3d(Vector3(p.x, altura(p.x, p.z), p.z), "arce", alto / 6.5, randf() * TAU)
		elif con_tarjetas:
			_arbol_tarjeta(Vector3(p.x, altura(p.x, p.z), p.z), "arce", alto / 6.5, randf() < 0.5)
		else:
			_arbol_viento(Vector3(p.x, altura(p.x, p.z), p.z), alto, color)
	if arboles_mapa:
		if perfil.get("arboles_tipo", ARBOLES_MAPA) != "arce":
			# los dos «cerezos» pasan a ser árboles mágicos: lugares especiales (tras el puente y junto a las ruinas)
			var est := load("res://prototipos/arbol_estilizado.gd")
			est.crear(self, Vector3(17, altura(17, -9), -9), "magico", 0.9, 0.8, tex_detalle, _opciones_arbol())
			est.crear(self, Vector3(-4, altura(-4, -14), -14), "magico", 0.85, 2.4, tex_detalle, _opciones_arbol())
		else:
			_arbol_viento(Vector3(17, altura(17, -9), -9), 5.5, Color(0.92, 0.6, 0.72))      # cerezo rosa tras el puente
			_arbol_viento(Vector3(-4, altura(-4, -14), -14), 5.0, Color(0.9, 0.62, 0.74))
	# rocas
	var roca := _mat_detalle(Color(0.6, 0.58, 0.55), 0.8, false, 1.0)
	seed(4242)                                           # misma escena siempre: comparaciones justas
	for k in 26:
		var p := Vector3(randf_range(-22, 28), 0, randf_range(-24, 22))
		if not _libre(p, 1.6):
			continue
		var r := randf_range(0.35, 1.0)
		_roca(Vector3(p.x, altura(p.x, p.z) + r * 0.15, p.z), r, roca)
	# faroles junto a las entradas del puente
	_poste(Vector3(SENDERO[4].x - 1.0, altura(SENDERO[4].x - 1.0, -3.8), -3.8), 1.8, true)
	_poste(Vector3(SENDERO[5].x + 1.0, altura(SENDERO[5].x + 1.0, -0.2), -0.2), 1.8, true)
	_estatua_guardian(Vector3(2.6, 0, -10.5), 15.0)            # Fase 2.1: primer modelo real de Meshy (mirador de la cascada)
	_arbustos()
	_hierba_y_flores()
	_mariposas()
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
	var mat_monte := _mat_detalle(Color(0.5, 0.58, 0.72), 0.05, false, 0.3)
	for k in 7:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = randf_range(18, 30)
		cm.height = randf_range(22, 40)
		cm.radial_segments = 9
		_al_lote(cm, Transform3D(Basis(), Vector3(-70 + k * 26, cm.height * 0.5 - 8, -120 - randf() * 30)), mat_monte)
	_cerrar_lotes()                                      # puente, rocas y montañas: una malla por material


# ---------------------------------------------------------------- modelos reales (Fase 2.1)

# Monta el material de un modelo preparado con pruebas/herramientas/preparar_meshy.gd (las texturas van como PNG
# comprimidos por Godot; la malla solo anota si el color lleva transparencia recortada).
func _mat_modelo(carpeta: String, nombre: String, malla: Mesh) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var base := "res://modelos/%s/%s" % [carpeta, nombre]
	if ResourceLoader.exists(base + "_color.png"):
		m.albedo_texture = load(base + "_color.png")
	if perfil.get("relieve", true) and ResourceLoader.exists(base + "_normal.png"):
		m.normal_enabled = true
		m.normal_texture = load(base + "_normal.png")
	if ResourceLoader.exists(base + "_rugosidad.png"):
		m.roughness_texture = load(base + "_rugosidad.png")
	m.roughness = 1.0
	if malla.has_meta("alfa_recortado") and malla.get_meta("alfa_recortado"):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# Estatua del guardián de piedra (Meshy, reducida a ~5 700 triángulos). Marca un sitio para pararse junto al
# camino (Skill aet-diseno-exploracion). Si falta el archivo, la escena sigue igual sin ella.
func _estatua_guardian(p: Vector3, giro_grados: float) -> void:
	var ruta := "res://modelos/guardian/guardian.res"
	if not ResourceLoader.exists(ruta):
		return
	var malla: Mesh = load(ruta)
	var cuerpo := StaticBody3D.new()
	cuerpo.position = Vector3(p.x, altura(p.x, p.z) - 0.05, p.z)
	cuerpo.rotation_degrees.y = giro_grados
	add_child(cuerpo)
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = _mat_modelo("guardian", "guardian", malla)
	cuerpo.add_child(mi)
	mi.add_to_group("ocluye")
	var col := CollisionShape3D.new()                  # Kael no la atraviesa
	var cil := CylinderShape3D.new()
	cil.radius = 1.0
	cil.height = 3.0
	col.shape = cil
	col.position.y = 1.5
	cuerpo.add_child(col)
	var pedestal := _mat_detalle(Color(0.62, 0.6, 0.56), 0.9, false, 1.0)   # losa a sus pies
	_bloque(Vector3(p.x, altura(p.x, p.z) + 0.02, p.z), Vector3(3.2, 0.12, 2.6), pedestal, Vector3(0, deg_to_rad(giro_grados), 0), false)


func _crear_fauna() -> void:
	var fauna := load("res://prototipos/fauna_simple.gd")
	for p in [Vector3(-5, 0, 2), Vector3(17, 0, -3), Vector3(-15, 0, 8)]:
		var c = fauna.new()
		c.tipo = "conejo"
		c.kael = kael
		c.radio = 3.0
		c.position = Vector3(p.x, altura(p.x, p.z), p.z)    # antes de entrar: ahí queda su «casa»
		add_child(c)
	for datos in [[Vector3(RIO_X, 5.5, -6), 6.0], [Vector3(-8, 7.0, 2), 9.0]]:
		var pajaro = fauna.new()
		pajaro.tipo = "pajaro"
		pajaro.radio = datos[1]
		pajaro.position = datos[0]
		add_child(pajaro)


# Nombre de la zona al entrar, como en los JRPG: aparece, se queda un momento y se va.
func _titulo_zona(nombre: String) -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	var l := Label.new()
	l.text = nombre
	l.add_theme_font_size_override("font_size", 52)
	l.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.08, 0.8))
	l.add_theme_constant_override("outline_size", 10)
	if ResourceLoader.exists("res://menu_combate.gd"):
		var mc = load("res://menu_combate.gd")
		var f = mc.fuente(mc.FUENTE_NOMBRE, 0, 600)
		if f != null:
			l.add_theme_font_override("font", f)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 80)
	l.position = Vector2(0, 120)
	l.modulate.a = 0.0
	capa.add_child(l)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_property(l, "modulate:a", 1.0, 0.8)
	t.tween_interval(2.0)
	t.tween_property(l, "modulate:a", 0.0, 1.0)
