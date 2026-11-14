extends Node3D
# Oakhaven 3D (V10, hitos 2 y 10): el distrito de los oficios, junto a la plaza. Al sureste de la Plaza del Tapiz, entre
# la Calle Mayor y la Calle de la Torre, la Calle de los Oficios: a un lado, la herrería de Maese Ferro, el taller de
# armaduras de Hilda, dos puestos de mercado y dos casas con su patio; al otro, los jardines cerrados de la fila de casas
# de la ciudad (sus tejados taparían a Kael: no se pisan). Al otro lado de la Calle Mayor, el tenderete de Mirta delante
# de la botica; y, escondido entre dos casas, el rincón del pozo viejo.
#
#   Distrito.crear(region, ciudad, mat, perfil, nombre_perfil) -> Node3D (null con Engine «oakhaven_sin_distrito»)
#
# Lo usa zonas3d/oakhaven_3d.gd: piezas() da los puntos que ofrecen el botón (como Aldric y la posadera), accion(id) lo
# atiende y ocupado() dice si hay un servicio abierto. Cada establecimiento tiene su encargado de pie: al pulsar «Hablar
# con …» se abre su diálogo de Dialogic si existe (Oak.dialogo_de o dialogos/oakhaven/oak_<pnj>.dtl) y, al acabar, el
# servicio (load("res://servicios.gd").abrir(region, "forja" | "armaduras" | "botica")) si el diálogo lo pidió con su
# señal «oak:servicio_…» o si no hay diálogo; si servicios.gd no existe, el aviso «Servicio en preparación». Las demás
# señales «oak:» del diálogo (los encargos) se aplican con Oak.aplicar_senal, como en la ciudad 2D.
#
# Los modelos son de Blender (zonas3d/oakhaven/fuente/crear_distrito.py → modelos/distrito.glb y, para los perfiles
# medio y bajo, distrito_ligero.glb), ya montados en su sitio. Aquí se juntan: una malla por edificio y material (los
# edificios cuelgan de su choque y se vuelven medio transparentes si tapan a Kael, como la botica y la guardia), una para
# todo lo bajo por material, una por encargado, el suelo; y se ponen el fuego, el humo, las chispas del yunque y las
# luciérnagas del pozo. Los choques son cajas (las del GLB) y sus huellas pasan a ciudad.bloqueos (por donde se anda).
# Ninguna toca un lugar pisable de la ciudad salvo el mostrador de Mirta en la plazuela de la botica.

const Oak := preload("res://ciudades/oakhaven.gd")
const Roca := preload("res://zonas3d/garganta/roca.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const Ciudad := preload("res://zonas3d/oakhaven/ciudad.gd")
const KIT := "res://zonas3d/oakhaven/modelos/distrito.glb"
const KIT_LIGERO := "res://zonas3d/oakhaven/modelos/distrito_ligero.glb"
const SERVICIOS_GD := "res://servicios.gd"
const PRESUPUESTO := 20000            # triángulos de todo el distrito (alto); el ligero, la mitad
# Los establecimientos: quién atiende (su ancla en el GLB), su diálogo y el texto del botón.
const OFICIOS := {
	"forja": {"pnj": "ferro", "dialogo": "oak_ferro", "texto": "Hablar con Maese Ferro"},
	"armaduras": {"pnj": "hilda", "dialogo": "oak_hilda", "texto": "Hablar con Hilda"},
	"botica": {"pnj": "mirta", "dialogo": "oak_mirta", "texto": "Hablar con Mirta"},
}
# En la Calle de los Oficios la cámara mira algo más desde arriba (60° en vez de 52°): al sur están los tejados de 8 m de
# la fila de casas de la ciudad y, a 52°, tapan a Kael delante de los puestos y las casas. [inclinación, dist. mín., máx.]
const CAMARA := [60.0, 12.0, 19.0]
const ZONA_CAMARA := Rect2(41.0, 31.5, 27.0, 5.7)
const RADIO_SERVICIO := 1.6
const RADIO_POZO := 1.3
const AVISO_SIN_SERVICIO := "Servicio en preparación"
# El pozo viejo: lo que se ve al examinarlo (propuesta de gráficos, pendiente de narrativa; sin canon).
const TEXTOS_POZO := [
	"Un pozo viejo, olvidado entre dos casas. Al asomarte, una nube de luciérnagas sube del fondo y se pierde sobre los tejados.",
	"En el brocal, alguien grabó un roble pequeño y tres iniciales. El musgo casi las ha borrado.",
	"Muy abajo, el agua devuelve la luz de las luciérnagas. Huele a piedra mojada y a menta.",
]
# Suelo propio (tierra pisada con losas) y sin la hierba ni los arbustos de la ciudad: [x0, z0, x1, z1] en casillas.
const SUELO := [
	[41.0, 31.0, 46.0, 37.0], [46.0, 32.0, 68.0, 37.0],     # la Calle de los Oficios (sin pisar el mercado ni la plaza)
	[46.2, 37.0, 49.8, 44.65],                                # el paso entre los jardines y el rincón del pozo
]
const LIMPIAR := [[41.0, 31.0, 68.0, 37.0], [46.2, 37.0, 49.8, 44.65], [32.9, 40.0, 36.3, 41.9]]
const ESCALA_SUELO := {"alto": 0.5, "medio": 0.75, "bajo": 1.0}
const LOSAS := {"alto": 170, "medio": 110, "bajo": 70}

var region: Node3D
var ciudad                                   # zonas3d/oakhaven/ciudad.gd (sus bloqueos)
var mat: Materiales
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var ligero := false
var anclas := {}                             # nombre → Vector3 (los vacíos «ancla_» del GLB)
var bloqueos: Array = []                     # Rect2 en casillas (también en ciudad.bloqueos)
var triangulos := 0
var mallas := 0
var choques := 0
var limpiadas := 0                           # matas, flores y arbustos de la ciudad quitados de debajo del distrito
var ms_montar := 0.0                         # lo que tardó en montarse (cargar el GLB, juntar, suelo, partículas)
var pnj := {}                                # nombre → Node3D (el encargado)
var brazo: Node3D                            # el brazo del martillo de Ferro
var chispas: CPUParticles3D
var humo: CPUParticles3D
var motas_pozo: CPUParticles3D
var rafaga_pozo: CPUParticles3D
var luz_fragua: OmniLight3D
var pozo_visto := 0
var ultimo_aviso := ""                       # (para las pruebas)
var servicio_abierto := ""                   # (para las pruebas) el último servicio pedido a servicios.gd
var _ui = null                               # lo que devolvió servicios.gd al abrir (si es un nodo)
var _atendiendo := ""
var _senales: Array = []
var _veces := {}
var _t := 0.0
var _ciclo := 0.0
var _golpes := 0
var _mat_figura: StandardMaterial3D
var _mat_brillo: StandardMaterial3D


static func crear(region_: Node3D, ciudad_, mat_: Materiales, perfil_: Dictionary, nombre_: String) -> Node3D:
	if Engine.has_meta("oakhaven_sin_distrito"):
		return null
	var d = load("res://zonas3d/oakhaven/distrito.gd").new()
	d.name = "Distrito"
	d.region = region_
	d.ciudad = ciudad_
	d.mat = mat_ if mat_ != null else Materiales.new(perfil_)
	d.perfil = perfil_
	d.nombre_perfil = nombre_ if ESCALA_SUELO.has(nombre_) else "alto"
	region_.add_child(d)
	d._montar()
	return d


func resumen() -> Dictionary:
	return {"kit": KIT_LIGERO if ligero else KIT, "triangulos": triangulos, "mallas": mallas, "choques": choques,
		"bloqueos": bloqueos.size(), "limpiadas": limpiadas, "perfil": nombre_perfil, "ms": snappedf(ms_montar, 0.1)}


# ================================================================= montar

func _montar() -> void:
	var t0 := Time.get_ticks_usec()
	ligero = perfil.get("modelos_ligeros", nombre_perfil != "alto") and ResourceLoader.exists(KIT_LIGERO)
	var ruta := KIT_LIGERO if ligero else KIT
	if not ResourceLoader.exists(ruta):
		push_warning("Oakhaven 3D: falta el distrito «%s»" % ruta)
		return
	_mat_figura = StandardMaterial3D.new()
	_mat_figura.vertex_color_use_as_albedo = true
	_mat_figura.roughness = 0.85
	_mat_brillo = StandardMaterial3D.new()
	_mat_brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_brillo.vertex_color_use_as_albedo = true
	var raiz: Node3D = (load(ruta) as PackedScene).instantiate()
	add_child(raiz)                                         # (en el árbol, para leer las transformaciones)
	for n in raiz.find_children("ancla_*", "Node3D", true, false):
		anclas[String(n.name).trim_prefix("ancla_")] = to_local((n as Node3D).global_position)
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var nombre := String(mi.name)
		if nombre.begins_with("pnj_"):
			continue
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Choque_" + nombre
		add_child(cuerpo)
		_cajas(mi, cuerpo)
		var lotes := _por_material(mi as MeshInstance3D)
		for clave in lotes:
			var padre: Node = cuerpo if nombre.begins_with("edif_") else self
			var m := _malla(lotes[clave], mat.sillar() if clave == "base" else _mat_brillo, "%s_%s" % [nombre, clave], padre)
			if nombre.begins_with("edif_"):
				m.add_to_group("ocluye")                     # si tapa a Kael, medio transparente (vista3d.gd)
			if clave == "brillo":
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_encargados(raiz)
	raiz.queue_free()
	_suelo()
	_limpiar_vegetacion()
	_fuego()
	_pozo()
	set_process(true)
	ms_montar = (Time.get_ticks_usec() - t0) / 1000.0


# Las superficies de una malla del GLB, por material («base» o «brillo»), en coordenadas del distrito.
func _por_material(mi: MeshInstance3D) -> Dictionary:
	var r := {}
	var t := global_transform.affine_inverse() * mi.global_transform
	for s in mi.mesh.get_surface_count():
		var m := mi.get_active_material(s)
		var clave := "brillo" if m != null and m.resource_name.begins_with("brillo") else "base"
		if not r.has(clave):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			r[clave] = st
		(r[clave] as SurfaceTool).append_from(mi.mesh, s, t)
	return r


func _malla(st: SurfaceTool, m: Material, nombre: String, padre: Node) -> MeshInstance3D:
	var am := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = am
	mi.material_override = m
	var con_sombra: bool = perfil.get("sombras_edificios", nombre_perfil == "alto") and perfil.get("sombras", false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if con_sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)                                         # (los cuerpos están en el origen del distrito)
	for s in am.get_surface_count():
		var arr := am.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		triangulos += (idx.size() if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	mallas += 1
	return mi


# Los choques de caja de un objeto (sus vacíos «caja_<i>_<ancho>_<fondo>_<alto>», en cm): al cuerpo y a los bloqueos.
func _cajas(mi: Node3D, cuerpo: StaticBody3D) -> void:
	for e in mi.get_children():
		var nombre := String(e.name)
		if not nombre.begins_with("caja_") or not e is Node3D:
			continue
		var p := nombre.split("_")
		if p.size() < 5:
			continue
		var tam := Vector3(float(p[2]), float(p[4]), float(p[3])) / 100.0
		var base := to_local((e as Node3D).global_position)
		_caja(cuerpo, base, tam)


func _caja(cuerpo: StaticBody3D, base: Vector3, tam: Vector3) -> void:
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tam
	col.shape = caja
	col.position = base + Vector3(0, tam.y * 0.5, 0)
	cuerpo.add_child(col)
	choques += 1
	var r := Rect2(base.x - tam.x * 0.5, base.z - tam.z * 0.5, tam.x, tam.z)
	bloqueos.append(r)
	if ciudad != null and ciudad.get("bloqueos") is Array:
		ciudad.bloqueos.append(r)


# ================================================================= los encargados

func _encargados(raiz: Node3D) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Choque_encargados"
	add_child(cuerpo)
	for o in OFICIOS.values():
		var nombre: String = o["pnj"]
		var fuente := raiz.find_child("pnj_" + nombre, true, false) as MeshInstance3D
		if fuente == null or not anclas.has(nombre):
			push_warning("Oakhaven 3D: falta el encargado «%s» en el distrito" % nombre)
			continue
		var n := Node3D.new()
		n.name = nombre.capitalize()
		n.position = anclas[nombre]
		add_child(n)
		var mi := MeshInstance3D.new()
		mi.name = "Figura"
		mi.mesh = fuente.mesh
		mi.material_override = _mat_figura
		n.add_child(mi)
		_contar(mi.mesh)
		mallas += 1
		pnj[nombre] = n
		_caja(cuerpo, n.position, Vector3(0.6, 1.8, 0.6))
		var t := mi.create_tween().set_loops()                  # respira despacio (como la posadera)
		t.tween_property(mi, "position:y", 0.018, 1.6 + 0.2 * pnj.size()).set_trans(Tween.TRANS_SINE)
		t.tween_property(mi, "position:y", 0.0, 1.6 + 0.2 * pnj.size()).set_trans(Tween.TRANS_SINE)
	var fb := raiz.find_child("pnj_ferro_brazo", true, false) as MeshInstance3D
	if fb != null and pnj.has("ferro"):
		brazo = Node3D.new()
		brazo.name = "Brazo"
		brazo.position = anclas.get("hombro_ferro", Vector3(-0.39, 1.38, 0.0))
		pnj["ferro"].add_child(brazo)
		var mi := MeshInstance3D.new()
		mi.mesh = fb.mesh
		mi.material_override = _mat_figura
		brazo.add_child(mi)
		_contar(mi.mesh)
		mallas += 1


func _contar(m: Mesh) -> void:
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		triangulos += (idx.size() if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


# ================================================================= suelo

# Tierra pisada con losas sueltas (más en el camino del medio y delante de cada oficio), que se funde con el suelo de la
# ciudad en el borde: allí toma el mismo color que la ciudad (ciudad.gd, _suelo), y 1,5 cm por encima (no se cruzan).
func _suelo() -> void:
	var paso: float = ESCALA_SUELO[nombre_perfil]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in SUELO:
		var x0: float = z[0]
		var z0: float = z[1]
		var nx := int(ceil((z[2] - x0) / paso))
		var nz := int(ceil((z[3] - z0) / paso))
		var colores := {}
		for i in nz + 1:
			for j in nx + 1:
				var x := minf(x0 + j * paso, z[2])
				var zz := minf(z0 + i * paso, z[3])
				colores[Vector2i(j, i)] = [Vector3(x, 0.015, zz), _color_suelo(x, zz, z)]
		for i in nz:
			for j in nx:
				for k in [Vector2i(j, i), Vector2i(j + 1, i), Vector2i(j, i + 1), Vector2i(j, i + 1), Vector2i(j + 1, i), Vector2i(j + 1, i + 1)]:
					st.set_color(colores[k][1])
					st.set_normal(Vector3.UP)
					st.add_vertex(colores[k][0])
	_losas(st)
	var mi := _malla(st, mat.sillar(), "Suelo", self)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _color_suelo(x: float, z: float, zona: Array) -> Color:
	var n := Roca.n2(x * 0.37, z * 0.37)
	var tierra := Color(0.40, 0.33, 0.25).lerp(Color(0.49, 0.41, 0.30), 0.5 + 0.5 * n)
	if x > 60.0 and z < 35.3 and zona[0] > 45.0:              # los patios: tierra con hierba
		tierra = tierra.lerp(Color(0.30, 0.40, 0.20), 0.45 + 0.25 * Roca.n2(x * 1.3, z * 1.3))
	if z > 39.6:                                                 # el rincón: más oscuro y con musgo
		tierra = tierra.lerp(Color(0.26, 0.32, 0.20), 0.45 + 0.2 * n)
	if Vector2(x - 43.1, z - 34.6).length() < 2.2:             # hollín delante de la fragua
		tierra = tierra.lerp(Color(0.20, 0.17, 0.15), 0.5 * (1.0 - Vector2(x - 43.1, z - 34.6).length() / 2.2))
	var borde := minf(minf(x - zona[0], zona[2] - x), minf(z - zona[1], zona[3] - z))
	# por dentro del distrito no hay borde: solo donde da a la ciudad
	for otra in SUELO:
		if otra != zona and Rect2(otra[0], otra[1], otra[2] - otra[0], otra[3] - otra[1]).grow(0.01).has_point(Vector2(x, z)):
			borde = 9.0
	var w := smoothstep(0.0, 0.9, borde)
	return _color_ciudad(x, z).lerp(tierra, w)


# El color del suelo de la ciudad en (x, z), como ciudad.gd (_suelo).
func _color_ciudad(x: float, z: float) -> Color:
	var id: String = Ciudad.lugar_en(x, z)
	var n := Roca.n2(x * 0.21, z * 0.21)
	if id != "":
		return Color(0.40, 0.38, 0.37).lerp(Color(0.46, 0.42, 0.36), 0.5 + 0.5 * n)
	var hierba := Color(0.24, 0.36, 0.17).lerp(Color(0.33, 0.45, 0.20), 0.5 + 0.5 * n)
	for l in Oak.LUGARES:
		if l.get("pisable", false) and not l.get("en_alto", false) and (l["rect"] as Rect2).grow(1.2).has_point(Vector2(x, z)):
			return hierba.lerp(Color(0.38, 0.33, 0.25), 0.55)
	return hierba


# Losas sueltas: un camino de este a oeste por el medio de la plaza, delante de cada oficio y en el rincón del pozo.
func _losas(st: SurfaceTool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var n: int = LOSAS[nombre_perfil]
	var hechas := 0
	var intentos := 0
	var puestas: Array = []
	while hechas < n and intentos < n * 30:
		intentos += 1
		var p: Vector2
		var r := rng.randf()
		if r < 0.55:
			p = Vector2(rng.randf_range(41.2, 67.6), 35.9 + rng.randfn(0.0, 0.42))         # el camino
		elif r < 0.85:
			var frentes := [Vector2(46.4, 35.2), Vector2(50.6, 35.4), Vector2(57.3, 35.3), Vector2(43.1, 34.7)]
			p = frentes[rng.randi() % frentes.size()] + Vector2(rng.randfn(0.0, 1.0), rng.randfn(0.0, 0.45))
		else:
			p = Vector2(rng.randf_range(46.6, 49.4), rng.randf_range(39.8, 44.3))         # el rincón
		var dentro := false
		for z in SUELO:
			if Rect2(z[0] + 0.3, z[1] + 0.3, z[2] - z[0] - 0.6, z[3] - z[1] - 0.6).has_point(p):
				dentro = true
		if not dentro:
			continue
		var cerca := false
		for q in puestas:
			if (q as Vector2).distance_to(p) < 0.42:
				cerca = true
				break
		if cerca:
			continue
		puestas.append(p)
		hechas += 1
		var lados := 6 if nombre_perfil == "bajo" else 7
		var radio := rng.randf_range(0.2, 0.3)
		var g := rng.randf_range(0.56, 0.72)
		var c := Color(g, g * 0.96, g * 0.9)
		if p.y > 39.6 or rng.randf() < 0.2:
			c = c.lerp(Color(0.34, 0.42, 0.24), rng.randf_range(0.2, 0.5))
		var giro := rng.randf() * TAU
		var centro := Vector3(p.x, 0.035, p.y)
		var borde: Array = []
		for k in lados:
			var a := giro + TAU * k / lados
			var rr := radio * rng.randf_range(0.82, 1.1)
			borde.append(Vector3(p.x + cos(a) * rr * 1.2, 0.03, p.y + sin(a) * rr))
		for k in lados:
			for v in [centro, borde[(k + 1) % lados], borde[k]]:
				st.set_color(c)
				st.set_normal(Vector3.UP)
				st.add_vertex(v)


# Las matas, flores, arbustos y arbolitos que la ciudad sembró donde ahora está el distrito: se quitan (escala cero).
func _limpiar_vegetacion() -> void:
	if region == null:
		return
	var zonas: Array = []
	for z in LIMPIAR:
		zonas.append(Rect2(z[0], z[1], z[2] - z[0], z[3] - z[1]).grow(0.3))
	for n in region.get_children():
		if not n is MultiMeshInstance3D:
			continue
		var nombre := String(n.name)
		if not (nombre.begins_with("Matas") or nombre.begins_with("Flores") or nombre.begins_with("Arbustos") or nombre.begins_with("Arbolitos")):
			continue
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		var o: Vector3 = (n as Node3D).position
		var cero := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
		for i in mm.instance_count:
			var p := o + mm.get_instance_transform(i).origin
			for r in zonas:
				if (r as Rect2).has_point(Vector2(p.x, p.z)):
					mm.set_instance_transform(i, cero)
					limpiadas += 1
					break


# ================================================================= fuego, humo, chispas y luciérnagas

func _fuego() -> void:
	if not anclas.has("fragua"):
		return
	var f: Vector3 = anclas["fragua"]
	for k in 3:                                             # llamas sobre las brasas
		var q := QuadMesh.new()
		q.size = Vector2(0.34, 0.55) * (1.0 - 0.15 * k)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = mat.llama(float(k) * 1.7, 1.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = f + Vector3(-0.35 + 0.35 * k, 0.28 - 0.04 * k, 0.1 * (k % 2))
		mi.name = "Llama"
		add_child(mi)
		mallas += 1
		if ligero and k == 1:
			break
	var pm := PlaneMesh.new()                               # el resplandor en el suelo (todos los perfiles)
	pm.size = Vector2(4.6, 4.6)
	var halo := MeshInstance3D.new()
	halo.mesh = pm
	halo.material_override = mat.halo_suelo(Materiales.FUEGO)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(f.x + 0.6, 0.05, f.z + 1.0)
	halo.name = "Resplandor"
	add_child(halo)
	mallas += 1
	if perfil.get("luces_faroles", false):                  # luz de verdad, solo en el perfil alto
		luz_fragua = OmniLight3D.new()
		luz_fragua.light_color = Color(1.0, 0.56, 0.26)
		luz_fragua.light_energy = 1.7
		luz_fragua.omni_range = 6.5
		luz_fragua.position = f + Vector3(0.8, 0.9, 0.9)
		add_child(luz_fragua)
	if anclas.has("humo"):                                  # humo barato: pocas partículas grandes y blandas
		humo = _particulas("Humo", 8 if ligero else 14, 4.5, Color(0.46, 0.44, 0.52, 0.42), 0.8)
		humo.position = anclas["humo"]
		humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		humo.emission_sphere_radius = 0.2
		humo.direction = Vector3.UP
		humo.spread = 12.0
		humo.initial_velocity_min = 0.45
		humo.initial_velocity_max = 0.7
		humo.gravity = Vector3(0.18, 0.12, 0.05)
		humo.preprocess = 4.0
		var curva := Curve.new()
		curva.add_point(Vector2(0.0, 0.5))
		curva.add_point(Vector2(1.0, 2.6))
		humo.scale_amount_curve = curva
	if anclas.has("yunque"):
		chispas = _particulas("Chispas", 6 if ligero else 12, 0.55, Color(1.0, 0.72, 0.30, 1.0), 0.05)
		chispas.position = anclas["yunque"]
		chispas.one_shot = true
		chispas.emitting = false
		chispas.explosiveness = 1.0
		chispas.direction = Vector3(0.2, 1.0, 0.4)
		chispas.spread = 65.0
		chispas.initial_velocity_min = 1.4
		chispas.initial_velocity_max = 2.8
		chispas.gravity = Vector3(0, -7.0, 0)


func _pozo() -> void:
	if not anclas.has("pozo"):
		return
	var p: Vector3 = anclas["pozo"]
	motas_pozo = _particulas("Luciernagas", 5 if ligero else 9, 5.0, Color(0.82, 1.0, 0.55, 0.9), 0.07)
	motas_pozo.position = p + Vector3(0, 0.9, 0.2)
	motas_pozo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motas_pozo.emission_box_extents = Vector3(1.3, 0.7, 1.9)
	motas_pozo.direction = Vector3.UP
	motas_pozo.spread = 180.0
	motas_pozo.initial_velocity_min = 0.04
	motas_pozo.initial_velocity_max = 0.15
	motas_pozo.gravity = Vector3(0, 0.03, 0)
	motas_pozo.preprocess = 5.0
	rafaga_pozo = _particulas("Rafaga", 14 if ligero else 26, 3.2, Color(0.86, 1.0, 0.6, 1.0), 0.08)
	rafaga_pozo.position = p
	rafaga_pozo.one_shot = true
	rafaga_pozo.emitting = false
	rafaga_pozo.explosiveness = 0.75
	rafaga_pozo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	rafaga_pozo.emission_sphere_radius = 0.4
	rafaga_pozo.direction = Vector3.UP
	rafaga_pozo.spread = 28.0
	rafaga_pozo.initial_velocity_min = 0.8
	rafaga_pozo.initial_velocity_max = 1.6
	rafaga_pozo.gravity = Vector3(0.1, 0.15, 0)
	rafaga_pozo.damping_min = 0.3
	rafaga_pozo.damping_max = 0.6


func _particulas(nombre: String, cantidad: int, vida: float, color: Color, tam: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = nombre
	p.amount = cantidad
	p.lifetime = vida
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	if tam > 0.3:
		m.albedo_texture = mat.textura_halo(Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.7))
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(color, 0.0), color, Color(color, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	mallas += 1
	return p


# ================================================================= vida (el martillo, el fuego, las miradas)

func _process(delta: float) -> void:
	_t += delta
	var kael: Node3D = region.get("kael") if region != null else null
	var cerca := kael != null and Vector2(kael.global_position.x - 50.0, kael.global_position.z - 37.0).length() < 30.0
	if luz_fragua != null:
		luz_fragua.light_energy = 1.7 * (0.85 + 0.1 * sin(_t * 11.0) + 0.05 * sin(_t * 27.0))
	if not cerca:
		return
	_martillo(delta)
	for nombre in ["hilda", "mirta"]:                        # miran a Kael si se acerca
		if pnj.has(nombre):
			_mirar(pnj[nombre], kael, delta)
	if pnj.has("ferro") and _atendiendo == "forja":
		_mirar(pnj["ferro"], kael, delta)
	elif pnj.has("ferro"):
		var f: Node3D = pnj["ferro"]
		f.rotation.y = lerp_angle(f.rotation.y, 0.0, 1.0 - exp(-4.0 * delta))


# Ferro golpea el yunque: alza el martillo, lo deja caer, saltan chispas; cada tres golpes, se para a mirar la pieza.
func _martillo(delta: float) -> void:
	if brazo == null:
		return
	if _atendiendo == "forja":
		brazo.rotation.x = lerpf(brazo.rotation.x, 0.25, 1.0 - exp(-6.0 * delta))
		return
	var dur := 1.15 if _golpes % 3 != 2 else 2.6
	_ciclo += delta
	var a := 0.0
	if _ciclo < 0.5:
		a = -1.45 * ease(_ciclo / 0.5, 0.5)                      # alza
	elif _ciclo < 0.66:
		a = -1.45
	elif _ciclo < 0.78:
		a = lerpf(-1.45, 0.06, ease((_ciclo - 0.66) / 0.12, 2.4))   # golpe
	else:
		a = lerpf(0.06, 0.0, minf(1.0, (_ciclo - 0.78) / 0.15))
	if _ciclo >= 0.78 and _ciclo - delta < 0.78 and chispas != null:
		chispas.restart()
	brazo.rotation.x = a
	if _ciclo >= dur:
		_ciclo = 0.0
		_golpes += 1


func _mirar(n: Node3D, kael: Node3D, delta: float) -> void:
	var d := kael.global_position - n.global_position
	var objetivo := 0.0
	if Vector2(d.x, d.z).length() < 4.5:
		objetivo = clampf(atan2(d.x, d.z), -0.9, 0.9)
	n.rotation.y = lerp_angle(n.rotation.y, objetivo, 1.0 - exp(-4.0 * delta))


# ================================================================= interacción (la usa oakhaven_3d.gd)

# Los puntos que ofrecen el botón: [id, posición, radio, texto] (el formato de oakhaven_3d.gd, _piezas_al_alcance).
func piezas() -> Array:
	var r: Array = []
	for id in OFICIOS:
		var k := "punto_" + String(id)
		if anclas.has(k):
			r.append([id, to_global(anclas[k]), RADIO_SERVICIO, OFICIOS[id]["texto"]])
	if anclas.has("punto_pozo"):
		r.append(["pozo", to_global(anclas["punto_pozo"]), RADIO_POZO, "Examinar el pozo viejo"])
	return r


# La zona de cámara de oakhaven_3d.gd ([inclinación, distancia mínima, máxima]) en p: la del distrito o la de siempre.
func camara(p: Vector3, por_defecto: Array) -> Array:
	return CAMARA if ZONA_CAMARA.has_point(Vector2(p.x, p.z)) else por_defecto


func ocupado() -> bool:
	if _atendiendo != "":
		return true
	return _ui != null and is_instance_valid(_ui) and (_ui as Node).is_inside_tree() and _ui.get("visible") != false


func accion(id: String) -> void:
	if id == "pozo":
		_examinar_pozo()
	elif OFICIOS.has(id):
		await _atender(id)


func _atender(id: String) -> void:
	var o: Dictionary = OFICIOS[id]
	_atendiendo = id
	if region.has_method("_parar_kael"):
		region._parar_kael()
	if region.get("boton_accion") != null:
		region.boton_accion.visible = false
	var dg = get_node_or_null("/root/Dialogic")
	var ruta := _ruta_dialogo(o)
	var abrir := true
	if dg != null and ruta != "" and dg.current_timeline == null:
		Oak.registrar_dialogic()                             # los personajes nuevos, por su ruta, antes del diálogo
		_senales.clear()
		if not dg.signal_event.is_connected(_al_senal):
			dg.signal_event.connect(_al_senal)
		_veces[o["pnj"]] = int(_veces.get(o["pnj"], 0)) + 1   # (14/11: por vecino, como lo lee _ruta_dialogo)
		region.set("dialogo_actual", ruta)
		dg.start(ruta)
		await dg.timeline_ended
		if is_instance_valid(dg) and dg.signal_event.is_connected(_al_senal):
			dg.signal_event.disconnect(_al_senal)
		abrir = ("oak:servicio_" + id) in _senales
		var vida = region.get("vida")                       # (14/11: lo que dio el diálogo, guardado como en vida3d)
		if vida != null and _senales.any(func(x): return not str(x).begins_with("oak:servicio_")):
			vida.guardar()
	if abrir and is_inside_tree():
		_abrir_servicio(id)
	_atendiendo = ""


# El diálogo de un encargado: el que diga ciudades/oakhaven.gd si ya está en sus vecinos; si no, oak_<pnj>.dtl si existe.
func _ruta_dialogo(o: Dictionary) -> String:
	var r: String = Oak.dialogo_de(o["pnj"], int(_veces.get(o["pnj"], 0)))
	if r == "" or not ResourceLoader.exists(r):
		r = Oak.ruta_dialogo(o["dialogo"])
	return r if ResourceLoader.exists(r) else ""


func _al_senal(arg) -> void:
	var s := str(arg)
	_senales.append(s)
	if s.begins_with("oak:servicio_"):
		return
	var texto: String = Oak.aplicar_senal(s)
	if texto == "":
		return
	var vida = region.get("vida")                           # (14/11: en cola hasta que acabe el diálogo, como vida3d)
	if vida != null and vida.has_method("avisar"):
		vida.avisar(texto, "tesoro")
	else:
		_aviso(texto, 2.6)


# El servicio del establecimiento (servicios.gd, del coordinador). Si aún no existe, un aviso.
func _abrir_servicio(id: String) -> void:
	servicio_abierto = id
	if ResourceLoader.exists(SERVICIOS_GD):
		var S = load(SERVICIOS_GD)
		if S is Script:
			for m in (S as Script).get_script_method_list():
				if m["name"] == "abrir" and int(m.get("flags", 0)) & METHOD_FLAG_STATIC:
					var r = S.abrir(region, id)
					_ui = r if r is Node else null
					return
		push_warning("Oakhaven 3D: servicios.gd no tiene «static func abrir(padre, servicio)»")
	_aviso(AVISO_SIN_SERVICIO, 2.2)


func _examinar_pozo() -> void:
	if region.has_method("_parar_kael"):
		region._parar_kael()
	var texto: String = TEXTOS_POZO[mini(pozo_visto, TEXTOS_POZO.size() - 1)]
	pozo_visto += 1
	if rafaga_pozo != null and pozo_visto == 1:
		rafaga_pozo.restart()
	elif rafaga_pozo != null:
		rafaga_pozo.amount = maxi(6, rafaga_pozo.amount / 2)
		rafaga_pozo.restart()
	_aviso(texto, 4.2)


func _aviso(texto: String, segundos: float) -> void:
	ultimo_aviso = texto
	if region != null and region.has_method("_mostrar_aviso"):
		region._mostrar_aviso(texto, segundos)
