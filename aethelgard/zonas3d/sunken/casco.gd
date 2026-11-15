extends Node3D
# Sunken City 3D (V12, 15/11): el escenario del sector «Popa Rota → Cubierta Mayor». Monta el GLB de Blender
# (fuente/crear_sunken.py → modelos/sunken.glb en alto, sunken_ligero.glb en medio y bajo) como hace Oakhaven con sus
# barrios (zonas3d/oakhaven/barrios.gd): una malla por material, choques de sus cajas y lo que puede tapar a Kael en el
# grupo «ocluye». Añade lo que no viene del GLB:
#   - el suelo que se pisa: una caja fina por cada tramo de trazado.gd (ANDABLE) y las dos rampas, inclinadas;
#   - la laguna (prototipos/agua_sin_refraccion.gdshader en bajo y medio; shaders/water.gdshader con refracción en alto),
#     su fondo de fango, la orilla del sur con juncos y la línea de costa lejana;
#   - los faroles de las costillas (disco de luz en las tablas y resplandor; luz real solo en alto) y el destello del
#     mascarón; la bandera del Águila que se mece; gaviotas (fauna_simple.gd: pájaros que planean en círculo).
# Sin el GLB (no debería pasar), deja solo el suelo y el agua: la escena sigue siendo jugable.

const T := preload("res://zonas3d/sunken/trazado.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const KIT := "res://zonas3d/sunken/modelos/sunken.glb"
const KIT_LIGERO := "res://zonas3d/sunken/modelos/sunken_ligero.glb"
const LUZ_FAROL := Color(1.0, 0.74, 0.40)

var region: Node3D
var mat: Materiales
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var ligero := false
var anclas := {}                       # nombre → Vector3 (los vacíos «ancla_» del GLB)
var triangulos := 0
var mallas := 0
var choques := 0
var bandera: Node3D                    # el pivote de la bandera (la mece animar())
var faroles: Array = []                # Vector3 de los faroles encendidos (las pruebas los cuentan)
var agua: MeshInstance3D
var ms_montar := 0.0
var _mats := {}


static func crear(region_: Node3D, mat_: Materiales, perfil_: Dictionary, nombre_: String) -> Node3D:
	var c = load("res://zonas3d/sunken/casco.gd").new()
	c.name = "Casco"
	c.region = region_
	c.mat = mat_
	c.perfil = perfil_
	c.nombre_perfil = nombre_ if nombre_ in ["bajo", "medio", "alto"] else "alto"
	region_.add_child(c)
	c._montar()
	return c


func resumen() -> Dictionary:
	return {"kit": KIT_LIGERO if ligero else KIT, "triangulos": triangulos, "mallas": mallas, "choques": choques,
		"faroles": faroles.size(), "ms": snappedf(ms_montar, 0.1)}


func _montar() -> void:
	var t0 := Time.get_ticks_usec()
	_materiales()
	_suelos()
	_laguna()
	ligero = perfil.get("modelos_ligeros", nombre_perfil != "alto") and ResourceLoader.exists(KIT_LIGERO)
	var ruta := KIT_LIGERO if ligero else KIT
	if ResourceLoader.exists(ruta):
		_kit(ruta)
	else:
		push_warning("Sunken City 3D: falta el casco «%s»" % ruta)
	_faroles()
	_mascaron()
	_gaviotas()
	ms_montar = (Time.get_ticks_usec() - t0) / 1000.0


# ================================================================= materiales

func _materiales() -> void:
	_mats["base"] = mat.sillar()
	_mats["madera"] = mat.madera_color()
	_mats["tela"] = mat.tela_color()
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.vertex_color_use_as_albedo = true
	_mats["brillo"] = brillo


static func _clave_material(m: Material) -> String:
	if m == null:
		return "base"
	for k in ["brillo", "madera", "tela"]:
		if m.resource_name.begins_with(k):
			return k
	return "base"


# ================================================================= el GLB

func _kit(ruta: String) -> void:
	var raiz: Node3D = (load(ruta) as PackedScene).instantiate()
	add_child(raiz)
	for n in raiz.find_children("ancla_*", "Node3D", true, false):
		anclas[String(n.name).trim_prefix("ancla_")] = to_local((n as Node3D).global_position)
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var nombre := String(mi.name)
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Choque_" + nombre
		add_child(cuerpo)
		_cajas(mi, cuerpo)
		var lotes := _por_material(mi as MeshInstance3D)
		var tapa := nombre.begins_with("edif_")
		# lo que pasa por encima de la Quilla y de la plaza (las costillas y la bandera): se aparta a mano (apartar())
		var encima := nombre.begins_with("costilla_") or nombre == "bandera"
		var padre: Node3D = cuerpo if tapa else self
		if nombre == "bandera":
			padre = _pivote_bandera(cuerpo, mi as MeshInstance3D)
		var de_esta: Array = []
		for clave in lotes:
			var m := _malla(lotes[clave], _mats[clave], "%s_%s" % [nombre, clave], padre)
			if tapa and clave != "brillo":
				m.add_to_group("ocluye")                     # si tapa a Kael, medio transparente (vista3d.gd)
			if clave == "brillo" or nombre == "bajo_suelos" or nombre == "bajo_casco":
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if encima and clave != "brillo":
				de_esta.append(m)
		if encima:
			var z := float(nombre.trim_prefix("costilla_")) / 10.0 if nombre != "bandera" else T.PALO.y + 0.5
			encima_de.append({"nombre": nombre, "z": z, "mallas": de_esta, "apartada": false})
	raiz.queue_free()


# Las costillas que cruzan por encima y la bandera: medio transparentes mientras quedan entre la cámara y Kael (más al
# sur que él y más al norte que la cámara). Sin esto, la costilla más cercana cruzaba la pantalla como una pared.
var encima_de: Array = []              # [{"nombre", "z", "mallas", "apartada"}]


func apartar(z_kael: float, z_camara: float, region_: Node) -> void:
	for e in encima_de:
		var quiere: bool = e["z"] > z_kael + 0.35 and e["z"] < z_camara + 1.0
		if quiere == e["apartada"]:
			continue
		e["apartada"] = quiere
		for mi in e["mallas"]:
			if is_instance_valid(mi):
				region_._transparente(mi, quiere)


func _por_material(mi: MeshInstance3D) -> Dictionary:
	var r := {}
	var t := global_transform.affine_inverse() * mi.global_transform
	for s in mi.mesh.get_surface_count():
		var clave := _clave_material(mi.get_active_material(s))
		if not r.has(clave):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			r[clave] = st
		(r[clave] as SurfaceTool).append_from(mi.mesh, s, t)
	return r


func _malla(st: SurfaceTool, m: Material, nombre: String, padre: Node3D) -> MeshInstance3D:
	var am := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = am
	mi.material_override = m
	var con_sombra: bool = perfil.get("sombras", false) and (nombre_perfil == "alto" or not nombre.begins_with("bajo_"))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if con_sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	mi.global_transform = global_transform                      # (los vértices ya están en coordenadas de la escena)
	_contar(am)
	mallas += 1
	return mi


func _contar(m: Mesh) -> void:
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		triangulos += (idx.size() if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


# Los choques de caja de un objeto (sus vacíos «caja_<i>_<ancho>_<fondo>_<alto>_<y0>», en cm, con la base en el vacío).
# Solo sirven para que la cámara sepa qué tapa a Kael y para no atravesar paredes: por dónde se anda lo dice trazado.gd.
func _cajas(mi: Node3D, cuerpo: StaticBody3D) -> void:
	for e in mi.get_children():
		var n := String(e.name)
		if not n.begins_with("caja_") or not e is Node3D:
			continue
		var p := n.split("_")
		if p.size() < 5:
			continue
		var tam := Vector3(float(p[2]), float(p[4]), float(p[3])) / 100.0
		var base := to_local((e as Node3D).global_position)
		var col := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = tam
		col.shape = caja
		col.position = base + Vector3(0, tam.y * 0.5, 0)
		cuerpo.add_child(col)
		choques += 1


# La bandera cuelga de la verga, al oeste del palo: su pivote es el borde de arriba, junto al palo (animar() la mece).
func _pivote_bandera(cuerpo: Node3D, mi: MeshInstance3D) -> Node3D:
	var caja: AABB = mi.global_transform * mi.mesh.get_aabb()
	bandera = Node3D.new()
	bandera.name = "Bandera"
	cuerpo.add_child(bandera)
	bandera.position = Vector3(caja.end.x, caja.end.y, caja.get_center().z)
	return bandera


# ================================================================= el suelo que se pisa

func _suelos() -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Suelo"
	add_child(cuerpo)
	for r in T.ANDABLE:
		if r == T.RAMPA or r == T.PASO_ARCHIVO:
			continue
		var y := T.altura(r.get_center().x, r.get_center().y)
		_caja_suelo(cuerpo, Vector3(r.get_center().x, y - 0.15, r.get_center().y), Vector3(r.size.x, 0.3, r.size.y), Basis())
	# la rampa de la Quilla a la Cubierta Mayor (sube hacia el norte)
	var ang := atan2(T.ALTO_CUBIERTA, T.RAMPA.size.y)
	var largo := T.RAMPA.size.y / cos(ang)
	var normal := Vector3(0, cos(ang), sin(ang)).normalized()    # (la cara de arriba mira al sur, por donde baja)
	_caja_suelo(cuerpo, Vector3(T.RAMPA.get_center().x, T.ALTO_CUBIERTA * 0.5, T.RAMPA.get_center().y) - normal * 0.15,
		Vector3(T.RAMPA.size.x, 0.3, largo + 0.1), Basis(Vector3.RIGHT, ang))
	# el pasillo del Archivo: rampa de x 46,4 a 48,6 y llano hasta la puerta
	var x0 := T.RAMPA_ARCHIVO_X.x
	var x1 := T.RAMPA_ARCHIVO_X.y
	var ang2 := atan2(T.ALTO_ARCHIVO, x1 - x0)
	var n2 := Vector3(-sin(ang2), cos(ang2), 0)
	_caja_suelo(cuerpo, Vector3((x0 + x1) * 0.5, T.ALTO_ARCHIVO * 0.5, T.PASO_ARCHIVO.get_center().y) - n2 * 0.15,
		Vector3((x1 - x0) / cos(ang2) + 0.05, 0.3, T.PASO_ARCHIVO.size.y), Basis(Vector3.BACK, ang2))
	var llano := Rect2(x1, T.PASO_ARCHIVO.position.y, T.PASO_ARCHIVO.end.x - x1, T.PASO_ARCHIVO.size.y)
	_caja_suelo(cuerpo, Vector3(llano.get_center().x, T.ALTO_ARCHIVO - 0.15, llano.get_center().y),
		Vector3(llano.size.x, 0.3, llano.size.y), Basis())


func _caja_suelo(cuerpo: StaticBody3D, centro: Vector3, tam: Vector3, b: Basis) -> void:
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tam
	col.shape = caja
	col.transform = Transform3D(b, centro)
	cuerpo.add_child(col)
	choques += 1


# ================================================================= la laguna

func _laguna() -> void:
	agua = MeshInstance3D.new()
	agua.name = "Laguna"
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 220)
	if nombre_perfil == "alto":
		pm.subdivide_width = 60
		pm.subdivide_depth = 50
	agua.mesh = pm
	agua.position = Vector3(40.0, T.NIVEL_AGUA, 32.0)
	agua.material_override = _mat_agua()
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(agua)
	# el fondo de fango verde azulado (se ve a través del agua en alto, con refracción)
	var fondo := MeshInstance3D.new()
	fondo.name = "Fango"
	var pf := PlaneMesh.new()
	pf.size = Vector2(260, 220)
	fondo.mesh = pf
	fondo.position = Vector3(40.0, -2.3, 32.0)
	fondo.material_override = mat.detalle(Color(0.16, 0.30, 0.31), 0.25, 0.0, 1.0)
	fondo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fondo)
	# la orilla del sur (donde acaba el muelle) y la línea de costa lejana, al oeste
	var arena := mat.detalle(Color(0.86, 0.76, 0.58), 0.35, 0.3, 1.0)
	for d in [[Vector3(40.0, -0.55, 82.0), Vector3(260.0, 1.0, 30.0)], [Vector3(-40.0, -0.6, 30.0), Vector3(40.0, 1.0, 110.0)]]:
		var orilla := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = d[1]
		orilla.mesh = bm
		orilla.position = d[0]
		orilla.material_override = arena
		orilla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(orilla)
	var juncos := "res://modelos/desierto/juncos_ligero.glb" if nombre_perfil != "alto" else "res://modelos/desierto/juncos.glb"
	if ResourceLoader.exists(juncos):
		var esc: PackedScene = load(juncos)
		var rng := RandomNumberGenerator.new()
		rng.seed = 515
		for i in 9:
			var j: Node3D = esc.instantiate()
			j.position = Vector3(rng.randf_range(24.0, 56.0), -0.1, rng.randf_range(66.6, 69.0))
			if absf(j.position.x - 40.0) < 3.0:
				j.position.x += 5.0
			j.rotation.y = rng.randf() * TAU
			j.scale = Vector3.ONE * rng.randf_range(0.8, 1.2)
			add_child(j)


func _mat_agua() -> Material:
	var sm := ShaderMaterial.new()
	var alto: bool = perfil.get("refraccion", false) and ResourceLoader.exists("res://shaders/water.gdshader")
	sm.shader = load("res://shaders/water.gdshader" if alto else "res://prototipos/agua_sin_refraccion.gdshader")
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
	sm.set_shader_parameter("albedo_1", Color(0.04, 0.27, 0.32))     # fondo de la laguna (#1F6F78, más hondo)
	sm.set_shader_parameter("albedo_2", Color(0.16, 0.58, 0.60))     # turquesa (#3BB3B0, sin lavar con el sol)
	sm.set_shader_parameter("wave_speed", 0.025)
	sm.set_shader_parameter("wave_size", 0.12 if alto else 0.0)
	sm.set_shader_parameter("texture_scale", 0.05)
	if alto:
		sm.set_shader_parameter("transparency", 0.35)
	return sm


# ================================================================= faroles, mascarón y gaviotas

func _faroles() -> void:
	var reales := 0
	for k in anclas:
		var nombre := String(k)
		if not nombre.begins_with("farol"):
			continue
		var p: Vector3 = anclas[k]
		if nombre == "farol_%d" % int(T.COSTILLA_OSCURA):
			continue                                              # la costilla que no alumbra
		faroles.append(p)
		var halo := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.1, 1.1)
		halo.mesh = q
		halo.material_override = mat.halo_aire(LUZ_FAROL, 0.75)
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.position = p
		add_child(halo)
		var suelo_y := T.altura(p.x, p.z)
		if nombre != "farol_archivo":
			var disco := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(3.4, 3.4)
			disco.mesh = pm
			disco.material_override = mat.halo_suelo(LUZ_FAROL)
			disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			disco.position = Vector3(p.x - 0.3, suelo_y + 0.03, p.z)
			add_child(disco)
		if perfil.get("luces_faroles", false) and reales < 4 and nombre.begins_with("farol_") and nombre != "farol_archivo":
			var luz := OmniLight3D.new()
			luz.light_color = LUZ_FAROL
			luz.light_energy = 0.9
			luz.omni_range = 5.0
			luz.shadow_enabled = false
			luz.position = p + Vector3(0, -0.4, 0)
			add_child(luz)
			reales += 1


func _mascaron() -> void:
	if not anclas.has("mascaron"):
		return
	var halo := MeshInstance3D.new()
	halo.name = "BrilloMascaron"
	var q := QuadMesh.new()
	q.size = Vector2(4.2, 4.2)
	halo.mesh = q
	halo.material_override = mat.halo_aire(Color(1.0, 0.82, 0.46), 0.35)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = anclas["mascaron"] + Vector3(0, 0.6, -0.3)
	add_child(halo)


func _gaviotas() -> void:
	if Engine.has_meta("banco_proto"):
		return
	var fauna = load("res://prototipos/fauna_simple.gd")
	if fauna == null:
		return
	for d in [[Vector3(44.0, 13.0, 36.0), 9.0], [Vector3(30.0, 11.0, 22.0), 12.0], [Vector3(60.0, 14.0, 18.0), 10.0]]:
		var ave = fauna.new()
		ave.tipo = "pajaro"
		ave.radio = d[1]
		ave.position = d[0]
		add_child(ave)


# ================================================================= cada fotograma

func animar(t: float) -> void:
	if bandera != null:                                          # la bandera se mece con la brisa de la laguna
		bandera.rotation = Vector3(0.10 * sin(t * 1.3) + 0.04 * sin(t * 3.1), 0.08 * sin(t * 0.9 + 0.6), 0.0)
