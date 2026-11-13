extends RefCounted
# Oakhaven 3D (T-103): el decorado de la ciudad. El mismo trazado que la Oakhaven 2D (ciudades/oakhaven.gd: una casilla
# es un metro; x hacia el este, z hacia el sur, como las filas del mapa), con los modelos que hizo gráficos en Blender
# para la ciudad (T-089; modelos/*.glb, ya en su sitio de la ciudad o, los sueltos, desde su esquina) y el relleno de
# casas y faroles que propuso (ciudades/oakhaven_piezas.gd, RELLENO).
# La hora azul de la ciudad: cielo índigo, luz fría del oeste y el fuego de los faroles guiando por la Calle Mayor.
# Lo que se usa (la posadera, Aldric, la puerta de la taberna) está en zonas3d/oakhaven_3d.gd.

const Oak := preload("res://ciudades/oakhaven.gd")
const Piezas2D := preload("res://ciudades/oakhaven_piezas.gd")
const Roca := preload("res://zonas3d/garganta/roca.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const MODELOS := "res://zonas3d/oakhaven/modelos/"
# Piezas con su sitio dentro del modelo (se ponen en el origen) y piezas sueltas (desde la esquina de su casilla).
const UNICAS := ["puerta_sur", "plaza", "taberna", "concejo", "botica", "guardia", "mercado", "patio_cuervo", "arbol"]
const ALTO_EDIFICIO := 7.0
# Cantidades por perfil (bajo, medio, alto): densidad de adoquines, matas de hierba y flores.
const ADOQUINES := {"bajo": 0.55, "medio": 0.8, "alto": 1.0}
const MATAS := {"bajo": 260, "medio": 520, "alto": 900}
const FLORES := {"bajo": 120, "medio": 260, "alto": 420}
const ARBUSTOS := {"bajo": 50, "medio": 90, "alto": 150}
const ARBOLITOS := {"bajo": 10, "medio": 16, "alto": 26}

var region: Node3D
var mat: Materiales
var perfil: Dictionary
var nombre_perfil := "alto"
var lotes: Roca.Lotes
var bloqueos: Array = []          # Rect2 (en casillas) que no se pisan: edificios y casas
var faroles: Array = []           # posición de la llama de cada farol (las luces reales, el sonido)
var luces: Array = []             # OmniLight3D de los faroles (perfil alto): tiemblan
var _t := 0.0
var tiempos := {}


func _init(r: Node3D, m: Materiales, p: Dictionary, nombre: String) -> void:
	region = r
	mat = m
	perfil = p
	nombre_perfil = nombre if ADOQUINES.has(nombre) else "alto"
	lotes = Roca.Lotes.new()


func construir() -> void:
	seed(4711)
	_desde_cache = usar_cache and FileAccess.file_exists(_indice_cache())
	for paso in [_suelo, _modelos, _relleno, _adoquines, _vegetacion, _faroles]:
		var t0 := Time.get_ticks_usec()
		paso.call()
		tiempos[String(paso.get_method())] = (Time.get_ticks_usec() - t0) / 1000.0
	if _desde_cache and not _edificios_de_cache():      # la caché no se pudo leer: se juntan como siempre
		_desde_cache = false
		_fundir_unicas()
		_fundir_relleno()
	if not _desde_cache:
		_cerrar_fundidos()
	lotes.cerrar(region)


# ¿Es pisable la casilla (x, z) según el trazado? (calles, plaza, patios y jardines; no los edificios ni las casas)
func bloqueado(x: float, z: float, margen := 0.25) -> bool:
	for r in bloqueos:
		var g: Rect2 = (r as Rect2).grow(margen)
		if g.has_point(Vector2(x, z)):
			return true
	return false


static func lugar_en(x: float, z: float, pisables := true) -> String:
	for l in Oak.LUGARES:
		if bool(l.get("pisable", false)) == pisables and not l.get("en_alto", false) and (l["rect"] as Rect2).has_point(Vector2(x, z)):
			return l["id"]
	return ""


# ================================================================= suelo

# Una malla de 1 m con el color de cada sitio: empedrado gris en calles y plaza, hierba en jardines y huertos, tierra
# pisada a la orilla de las calles. Con su colisión (una caja delgada: el suelo es llano).
func _suelo() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tam: Vector2i = Oak.TAM
	var colorea := func(x: float, z: float) -> Color:
		var id := lugar_en(x, z)
		var n := Roca.n2(x * 0.21, z * 0.21)
		if id in ["calle_mayor", "plaza", "calle_cuervo", "calle_mercado", "calle_arbol", "puerta_sur", "concejo_portico",
				"plazuela_botica", "soportal_guardia", "pie_torre", "calle_torre", "mercado"]:
			return Color(0.40, 0.38, 0.37).lerp(Color(0.46, 0.42, 0.36), 0.5 + 0.5 * n)
		var borde := 9.0
		for l in Oak.LUGARES:
			if l.get("pisable", false) and not l.get("en_alto", false):
				var r: Rect2 = (l["rect"] as Rect2).grow(1.2)
				if r.has_point(Vector2(x, z)):
					borde = 0.0
		var hierba := Color(0.24, 0.36, 0.17).lerp(Color(0.33, 0.45, 0.20), 0.5 + 0.5 * n)
		return hierba.lerp(Color(0.38, 0.33, 0.25), 0.55) if borde < 1.0 else hierba
	var colores := []                                   # un color por vértice de la rejilla (se calcula una vez)
	for z in tam.y + 1:
		for x in tam.x + 1:
			colores.append(colorea.call(float(x), float(z)))
	for z in tam.y:
		for x in tam.x:
			var p := [Vector3(x, 0, z), Vector3(x + 1, 0, z), Vector3(x, 0, z + 1), Vector3(x + 1, 0, z + 1)]
			for i in [0, 1, 2, 2, 1, 3]:
				var v: Vector3 = p[i]
				st.set_color(colores[int(v.z) * (tam.x + 1) + int(v.x)])
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat.sillar()
	mi.name = "Suelo"
	region.add_child(mi)
	# fuera de la muralla: prado oscuro hasta donde alcanza la vista y el camino que sale de la Puerta del Sur
	var prado := PlaneMesh.new()
	prado.size = Vector2(tam.x + 120.0, tam.y + 110.0)
	var mp := MeshInstance3D.new()
	mp.mesh = prado
	# V12 (13/11, propuesta del especialista de rendimiento): el prado se dibuja DESPUÉS de los edificios
	# (render_priority 2): la imagen es la misma (opaco, con prueba de profundidad), pero no se pinta el suelo que luego
	# tapan las casas. Una copia del material: el de «detalle» se comparte (caché de materiales.gd).
	var mprado: StandardMaterial3D = mat.detalle(Color(0.20, 0.30, 0.15), 0.4, 0.5).duplicate()
	mprado.render_priority = 2
	mp.material_override = mprado
	mp.position = Vector3(tam.x * 0.5, -0.03, tam.y * 0.5 + 25.0)
	mp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mp.name = "Prado"
	region.add_child(mp)
	var camino := PlaneMesh.new()
	camino.size = Vector2(4.0, 40.0)
	var mc := MeshInstance3D.new()
	mc.mesh = camino
	mc.material_override = mat.detalle(Color(0.40, 0.34, 0.26), 0.8, 0.5)
	mc.position = Vector3(Oak.SALIDA_X, -0.01, tam.y + 20.0)
	mc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mc.name = "Camino"
	region.add_child(mc)
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "SueloChoque"
	region.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(tam.x + 40.0, 0.2, tam.y + 40.0)
	col.shape = caja
	col.position = Vector3(tam.x * 0.5, -0.1, tam.y * 0.5)
	cuerpo.add_child(col)


# ================================================================= edificios (los modelos de Blender)

func _modelo(id: String) -> Node3D:
	var ruta := MODELOS + id + ".glb"
	# medio y bajo: la versión ligera (fuente/aligerar.py, Blender: 40-70 % de las caras) si la hay; el alto, la de gráficos
	var ligera := MODELOS + id + "_ligero.glb"
	if perfil.get("modelos_ligeros", nombre_perfil != "alto") and ResourceLoader.exists(ligera):
		ruta = ligera
	if not ResourceLoader.exists(ruta):
		push_warning("Oakhaven 3D: falta el modelo «%s»" % ruta)
		return null
	var n: Node3D = (load(ruta) as PackedScene).instantiate()
	n.name = id
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if perfil.get("sombras", false) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


func _modelos() -> void:
	if not _desde_cache:
		_fundir_unicas()
	# los edificios no se pisan: una caja de choque por cada uno (la huella del trazado) y su bloqueo
	for l in Oak.LUGARES:
		if l.get("pisable", false):
			continue
		var r: Rect2 = l["rect"]
		bloqueos.append(r)
		var cuerpo := _caja_choque(r, ALTO_EDIFICIO)
		if l["id"] in TAPAN:
			_cuerpos[l["id"]] = cuerpo
	# la fuente de la plaza (en el modelo de la plaza): no se atraviesa
	var cuerpo := StaticBody3D.new()
	cuerpo.position = Vector3(Oak.PLAZA.x, 0, Oak.PLAZA.y)
	region.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 1.6
	cil.height = 2.0
	col.shape = cil
	col.position.y = 1.0
	cuerpo.add_child(col)
	bloqueos.append(Rect2(Oak.PLAZA.x - 1.5, Oak.PLAZA.y - 1.5, 3.0, 3.0))


func _caja_choque(r: Rect2, alto: float) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = Vector3(r.position.x + r.size.x * 0.5, alto * 0.5, r.position.y + r.size.y * 0.5)
	region.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(r.size.x, alto, r.size.y)
	col.shape = caja
	cuerpo.add_child(col)
	return cuerpo


# Las casas, los faroles y la ropa tendida del relleno de gráficos: cada uno desde la esquina de su casilla.
func _relleno() -> void:
	for d in Piezas2D.RELLENO:
		var id: String = d["id"]
		if id == "farol":
			continue                                        # los pone _faroles, con su fuego
		var r: Rect2i = d["rect"]
		if not _desde_cache:
			var n := _modelo(id)
			if n != null:
				n.position = Vector3(r.position.x, 0, r.position.y)
				_fundir(n)
		if not d.get("suelto", false):
			bloqueos.append(Rect2(r))
			_caja_choque(Rect2(r), ALTO_EDIFICIO)


# ================================================================= empedrado, hierba y flores

# Adoquines irregulares por las calles y la plaza (como la Vía del Peregrino de la Garganta), más ralos en el perfil
# bajo, en MultiMesh por tramos de 12 m.
func _adoquines() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var m := mat.detalle(Color.WHITE, 1.3, 1.0).duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	var forma := _adoquin(rng, 7 if nombre_perfil == "bajo" else 9)
	forma.surface_set_material(0, m)
	var densidad: float = ADOQUINES[nombre_perfil]
	var piezas: Array = []
	for l in Oak.LUGARES:
		if not l["id"] in ["calle_mayor", "plaza", "calle_cuervo", "puerta_sur", "calle_arbol", "calle_mercado", "concejo_portico"]:
			continue
		var r: Rect2 = l["rect"]
		var z := r.position.y + 0.2
		var fila := 0
		while z < r.end.y:
			var x := r.position.x + (0.22 if fila % 2 == 0 else 0.0) + 0.2
			while x < r.end.x:
				if rng.randf() < densidad and not bloqueado(x, z, 0.1):
					var e := rng.randf_range(0.9, 1.15)
					var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, rng.randf_range(0.8, 1.1), e)),
						Vector3(x + rng.randf_range(-0.06, 0.06), -0.015, z + rng.randf_range(-0.06, 0.06)))
					var g := rng.randf_range(0.52, 0.68)
					var c := Color(g, g * 0.97, g * 0.92)
					if rng.randf() < 0.15:
						c = c.lerp(Color(0.42, 0.48, 0.32), rng.randf_range(0.25, 0.5))
					piezas.append([t, c])
				x += 0.44
			z += 0.44
			fila += 1
	_por_tramos("Adoquines", forma, piezas)


func _adoquin(rng: RandomNumberGenerator, lados: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radios: Array = []
	for i in lados:
		radios.append(0.2 * rng.randf_range(0.8, 1.1))
	var arriba := 0.045
	var canto := 0.03
	var cima := Vector3(0, arriba + 0.02, 0)
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var r0: float = radios[i]
		var r1: float = radios[(i + 1) % lados]
		var in0 := d0 * (r0 - canto) + Vector3(0, arriba, 0)
		var in1 := d1 * (r1 - canto) + Vector3(0, arriba, 0)
		var out0 := d0 * r0 + Vector3(0, arriba - canto, 0)
		var out1 := d1 * r1 + Vector3(0, arriba - canto, 0)
		var pie0 := d0 * r0 * 1.04 + Vector3(0, -0.06, 0)
		var pie1 := d1 * r1 * 1.04 + Vector3(0, -0.06, 0)
		for v in [cima, in0, in1, in0, out1, in1, in0, out0, out1, out0, pie1, out1, out0, pie0, pie1]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# Matas de hierba y flores en jardines y huertos (no en las calles ni dentro de las casas), con el viento de la hierba.
func _vegetacion() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	var hoja := _mata()
	hoja.surface_set_material(0, mat.hierba_verde())
	var flor := SphereMesh.new()
	flor.radius = 0.06
	flor.height = 0.1
	flor.radial_segments = 5
	flor.rings = 2
	var mflor := StandardMaterial3D.new()
	mflor.vertex_color_use_as_albedo = true
	mflor.roughness = 1.0
	flor.material = mflor
	var matas: Array = []
	var flores: Array = []
	var colores := [Color(0.72, 0.56, 0.86), Color(0.95, 0.92, 0.82), Color(0.96, 0.62, 0.70), Color(0.98, 0.84, 0.36),
		Color(0.52, 0.62, 0.95)]
	var intentos := 0
	while (matas.size() < MATAS[nombre_perfil] or flores.size() < FLORES[nombre_perfil]) and intentos < 20000:
		intentos += 1
		var x := rng.randf_range(1.0, Oak.TAM.x - 1.0)
		var z := rng.randf_range(1.0, Oak.TAM.y - 1.0)
		if lugar_en(x, z) != "" or bloqueado(x, z, 0.4):
			continue
		var p := Vector3(x, 0, z)
		if matas.size() < MATAS[nombre_perfil]:
			var e := rng.randf_range(0.6, 1.2)
			var tono := rng.randf_range(0.8, 1.1)
			matas.append([Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, e, e)), p), Color(tono, tono, tono * 0.9)])
		if flores.size() < FLORES[nombre_perfil] and rng.randf() < 0.6:
			var c: Color = colores[rng.randi() % colores.size()]
			for k in rng.randi_range(2, 5):
				flores.append([Transform3D(Basis(), p + Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.18, 0.32), rng.randf_range(-0.3, 0.3))), c])
	_por_tramos("Matas", hoja, matas)
	_por_tramos("Flores", flor, flores)
	_jardines(rng)


func _mata() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 5:
		var a := k * TAU / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-d.z, 0, d.x) * 0.05
		var punta := d * 0.18 + Vector3(0, 0.4, 0)
		for v in [-lado, lado, punta]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


func _por_tramos(nombre: String, malla: Mesh, piezas: Array, tramo := 24.0) -> void:
	var grupos := {}
	for pz in piezas:
		var o: Vector3 = (pz[0] as Transform3D).origin
		var k := Vector2i(floori(o.x / tramo), floori(o.z / tramo))
		if not grupos.has(k):
			grupos[k] = []
		grupos[k].append(pz)
	for k in grupos:
		var lista: Array = grupos[k]
		var centro := Vector3.ZERO
		for pz in lista:
			centro += (pz[0] as Transform3D).origin
		centro /= lista.size()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = malla
		mm.instance_count = lista.size()
		for i in lista.size():
			var t: Transform3D = lista[i][0]
			mm.set_instance_transform(i, Transform3D(t.basis, t.origin - centro))
			mm.set_instance_color(i, lista[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.name = "%s_%d_%d" % [nombre, k.x, k.y]
		region.add_child(mmi)


# ================================================================= faroles

# Los faroles del relleno (uno cada 5 m por la Calle Mayor): el modelo, su llama, el halo pintado en el suelo y, en el
# perfil alto, luz de verdad en los más cercanos al camino de la entrada (hasta 4).
func _faroles() -> void:
	var cerca_del_camino := func(p: Vector3) -> bool: return absf(p.x - 40.0) < 6.0 and p.z > 20.0
	for d in Piezas2D.RELLENO:
		if d["id"] != "farol":
			continue
		var r: Rect2i = d["rect"]
		var n: Node3D = null if _desde_cache else _modelo("farol")   # (con la caché, el farol ya va en los edificios)
		if n != null:
			n.position = Vector3(r.position.x, 0, r.position.y)
			_fundir(n)
		var llama := Vector3(r.position.x + 0.5, 3.0, r.position.y + 0.5)
		faroles.append(llama)
		_llama(llama, 0.32, llama.x + llama.z)
		_halo(Vector3(llama.x, 0.0, llama.z), llama, 5.0, 1.4)
		bloqueos.append(Rect2(r.position.x + 0.3, r.position.y + 0.3, 0.4, 0.4))
		if perfil.get("luces_faroles", false) and luces.size() < 4 and cerca_del_camino.call(llama):
			var o := OmniLight3D.new()
			o.light_color = Color(1.0, 0.72, 0.42)
			o.light_energy = 1.4
			o.omni_range = 7.0
			o.position = llama
			region.add_child(o)
			luces.append(o)


func _llama(p: Vector3, alto: float, fase: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(alto * 0.62, alto)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat.llama(fase, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	mi.name = "Llama"
	region.add_child(mi)
	return mi


func _halo(suelo: Vector3, aire: Vector3, ancho: float, tam_aire: float) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(ancho, ancho)
	lotes.poner(pm, Transform3D(Basis(), suelo + Vector3(0, 0.03, 0)), mat.halo_suelo(Materiales.FUEGO))
	if nombre_perfil != "alto":                  # el resplandor en el aire, solo en el alto (una llamada de dibujo por farol)
		return
	var q := QuadMesh.new()
	q.size = Vector2(tam_aire, tam_aire)
	var brillo := MeshInstance3D.new()
	brillo.mesh = q
	brillo.material_override = mat.halo_aire(Materiales.FUEGO)
	brillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	brillo.position = aire
	region.add_child(brillo)


func animar(delta: float) -> void:
	_t += delta
	for i in luces.size():
		(luces[i] as OmniLight3D).light_energy = 1.4 * (0.88 + 0.08 * sin(_t * 9.0 + i * 1.7) + 0.04 * sin(_t * 23.0 + i))


# ================================================================= los modelos, juntos (pocas llamadas de dibujo)

# Los glb de gráficos traen cada pieza aparte (la taberna, 400 mallas): dibujados tal cual eran miles de llamadas de
# dibujo. Aquí se juntan por trozos de ciudad (TROZO m) y por material. Los materiales de color plano (casi todos) pasan
# su color a los vértices y comparten uno solo, con el grano de la piedra (materiales.gd, sillar): así una calle entera
# es una o dos llamadas. Los que tienen imagen, brillo propio o transparencia conservan su material.
const TROZO := 12.0
# Los edificios al sur de la plaza y de la Calle Mayor, que pueden quedar entre la cámara y Kael: van aparte, colgados
# de su choque, y se vuelven medio transparentes si lo tapan (como los marcos de la Garganta).
const TAPAN := ["botica", "guardia"]
var _cuerpos := {}
var _fundidos := {}               # clave «trozo|material» → [SurfaceTool, Material, con_color]


func _fundir(n: Node3D, propio := "") -> void:
	region.add_child(n)                                         # (en el árbol, para leer la transformación de cada pieza)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		var t: Transform3D = region.global_transform.affine_inverse() * m3.global_transform
		var trozo := Vector2i(floori(t.origin.x / TROZO), floori(t.origin.z / TROZO))
		for s in m3.mesh.get_surface_count():
			var mat_s: Material = m3.get_active_material(s)
			var plano := mat_s is BaseMaterial3D and (mat_s as BaseMaterial3D).albedo_texture == null \
				and not (mat_s as BaseMaterial3D).emission_enabled \
				and (mat_s as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
			var destino: Material = mat.sillar() if plano else mat_s
			var clave := ("propio:" + propio if propio != "" else "%d_%d" % [trozo.x, trozo.y]) + "|%d" % destino.get_instance_id()
			if not _fundidos.has(clave):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				_fundidos[clave] = [st, destino, plano]
			var st: SurfaceTool = _fundidos[clave][0]
			var arr: Array = m3.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var uv = arr[Mesh.ARRAY_TEX_UV]
			var idx = arr[Mesh.ARRAY_INDEX]
			var color: Color = (mat_s as BaseMaterial3D).albedo_color if plano else Color.WHITE
			var nb := t.basis.inverse().transposed()
			var orden: PackedInt32Array = idx if idx != null else PackedInt32Array(range(v.size()))
			for i in orden:
				st.set_color(color)
				if nr.size() > i:
					st.set_normal((nb * nr[i]).normalized())
				if not plano and uv != null and (uv as PackedVector2Array).size() > i:   # (los de color plano no usan UV)
					st.set_uv(uv[i])
				st.add_vertex(t * v[i])
	n.queue_free()


func _cerrar_fundidos() -> void:
	var guardadas: Array = []
	for clave in _fundidos:
		var d: Array = _fundidos[clave]
		var malla := _con_lod(d[0] as SurfaceTool, d[1])
		malla.surface_set_material(0, d[1])                      # la malla lleva su material: así se puede guardar
		var sitio := String(clave).get_slice("|", 0)
		_poner_edificio(malla, sitio)
		guardadas.append([malla, sitio])
	_fundidos.clear()
	if usar_cache and not guardadas.is_empty():
		DirAccess.make_dir_recursive_absolute(DIR_CACHE)
		var lista := []
		for i in guardadas.size():
			var ruta := "%s/%s_%s_%03d.res" % [DIR_CACHE, VERSION_CACHE, nombre_perfil, i]
			ResourceSaver.save(guardadas[i][0], ruta, ResourceSaver.FLAG_COMPRESS)
			lista.append([ruta, guardadas[i][1]])
		var f := FileAccess.open(_indice_cache(), FileAccess.WRITE)
		if f != null:
			f.store_var(lista)


func _poner_edificio(malla: ArrayMesh, sitio: String) -> void:
	# (las sombras de los edificios, solo donde el perfil lo pida: en el medio dibujarlas dos veces no cabe en el Mali)
	var con_sombra: bool = perfil.get("sombras_edificios", nombre_perfil == "alto")
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if con_sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "Edificios_" + sitio
	if sitio.begins_with("propio:") and _cuerpos.has(sitio.substr(7)):
		mi.material_override = malla.surface_get_material(0)   # (la transparencia de vista3d.gd cambia el material_override)
		_cuerpos[sitio.substr(7)].add_child(mi)              # su choque lo encuentra: se vuelve medio transparente
		mi.add_to_group("ocluye")                               # si tapa a Kael (vista3d.gd, _oclusion)
		mi.position = -(_cuerpos[sitio.substr(7)] as Node3D).position
	else:
		region.add_child(mi)


# Las mallas juntadas, guardadas (como la roca de la Garganta): la primera vez por perfil se juntan y se guardan en
# user://cache_oakhaven/; las siguientes se leen y no se carga ni se junta ningún glb. Si falta algo, se juntan como
# siempre. SUBE VERSION_CACHE si cambian los modelos, el relleno o cómo se juntan.
const VERSION_CACHE := "t103a"
const DIR_CACHE := "user://cache_oakhaven"
var usar_cache := not Engine.has_meta("oakhaven_sin_cache")
var leidas_de_cache := 0


func _indice_cache() -> String:
	return "%s/%s_%s.indice" % [DIR_CACHE, VERSION_CACHE, nombre_perfil]


# true si ha puesto los edificios desde la caché (entonces no hace falta cargar ni juntar los glb).
func _edificios_de_cache() -> bool:
	if not usar_cache or not FileAccess.file_exists(_indice_cache()):
		return false
	var f := FileAccess.open(_indice_cache(), FileAccess.READ)
	var lista = f.get_var() if f != null else null
	if not lista is Array:
		return false
	var mallas: Array = []
	for e in lista:
		var m := ResourceLoader.load(e[0], "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		if m == null:
			return false
		mallas.append([m, e[1]])
	for e in mallas:
		_poner_edificio(e[0], e[1])
	leidas_de_cache = mallas.size()
	return true


# La malla juntada con sus niveles de detalle (LOD): Godot dibuja una versión con menos triángulos cuando el trozo se ve
# pequeño (lejos). Los genera el mismo simplificador que usa la importación de modelos. Si la versión de Godot no lo
# ofrece, la malla sin LOD.
var lods_hechos := 0
var simplificados := 0
const SIMPLIFICAR := {"bajo": 0.4, "medio": 0.6}   # parte de los triángulos que se quedan (el alto, todos)
const ERROR_LOD := 0.02                           # error máximo de la simplificación (fracción del tamaño del trozo)


func _con_lod(st: SurfaceTool, m: Material) -> ArrayMesh:
	st.index()                                       # vértices compartidos: el simplificador los necesita
	var arrays := st.commit_to_arrays()
	# perfiles medio y bajo: la malla ya simplificada (meshoptimizer, el de la importación). El alto, entera.
	var reduccion: float = SIMPLIFICAR.get(nombre_perfil, 1.0)
	if reduccion < 1.0:
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var nuevo: PackedInt32Array = st.generate_lod(ERROR_LOD, maxi(3, int(idx.size() * reduccion) / 3 * 3))
		if nuevo.size() >= 3 and nuevo.size() < idx.size():
			arrays[Mesh.ARRAY_INDEX] = nuevo
			simplificados += 1
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, m)
	var args := -1
	for d in ClassDB.class_get_method_list("ImporterMesh"):
		if d["name"] == "generate_lods":
			args = (d["args"] as Array).size()
	if args == 3:
		im.call("generate_lods", 25.0, 60.0, [])
		lods_hechos += 1
	elif args == 2:
		im.call("generate_lods", 25.0, [])
		lods_hechos += 1
	return im.get_mesh()


# ================================================================= jardines (la referencia: una ciudad verde y florida)

# Arbustos redondos (algunos en flor) al pie de las casas y en los huertos, y arbolitos de copa redonda en los jardines.
# Formas sencillas en MultiMesh (una llamada de dibujo por tramo), sin choque (no están en las calles).
func _jardines(rng: RandomNumberGenerator) -> void:
	var m := mat.detalle(Color.WHITE, 0.9, 0.6).duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	var arbusto := SphereMesh.new()
	arbusto.radius = 0.55
	arbusto.height = 0.8
	arbusto.radial_segments = 7
	arbusto.rings = 4
	arbusto.material = m
	var arbol := _arbolito()
	arbol.surface_set_material(0, m)
	var verdes := [Color(0.20, 0.36, 0.16), Color(0.26, 0.42, 0.18), Color(0.17, 0.30, 0.15), Color(0.30, 0.44, 0.20)]
	var flores := [Color(0.80, 0.45, 0.60), Color(0.90, 0.85, 0.70), Color(0.62, 0.48, 0.80)]
	var arbustos: Array = []
	var arboles: Array = []
	var intentos := 0
	while (arbustos.size() < ARBUSTOS[nombre_perfil] or arboles.size() < ARBOLITOS[nombre_perfil]) and intentos < 8000:
		intentos += 1
		var x := rng.randf_range(1.5, Oak.TAM.x - 1.5)
		var z := rng.randf_range(1.5, Oak.TAM.y - 1.5)
		if lugar_en(x, z) != "" or bloqueado(x, z, 0.8) or _cerca_de_calle(x, z, 1.0):
			continue
		var junto_casa := bloqueado(x, z, 2.2)                   # al pie de una casa: arbustos; en el huerto: árboles
		if junto_casa and arbustos.size() < ARBUSTOS[nombre_perfil]:
			var e := rng.randf_range(0.7, 1.3)
			var c: Color = verdes[rng.randi() % verdes.size()]
			if rng.randf() < 0.3:
				c = c.lerp(flores[rng.randi() % flores.size()], 0.35)
			arbustos.append([Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, e * rng.randf_range(0.8, 1.1), e)),
				Vector3(x, 0.25 * e, z)), c])
		elif not junto_casa and arboles.size() < ARBOLITOS[nombre_perfil] and not _cerca_de_calle(x, z, 2.5):
			var e := rng.randf_range(0.8, 1.25)
			arboles.append([Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * e), Vector3(x, 0, z)),
				Color.WHITE * rng.randf_range(0.85, 1.1)])
	_por_tramos("Arbustos", arbusto, arbustos)
	_por_tramos("Arbolitos", arbol, arboles)


func _cerca_de_calle(x: float, z: float, margen: float) -> bool:
	for l in Oak.LUGARES:
		if l.get("pisable", false) and (l["rect"] as Rect2).grow(margen).has_point(Vector2(x, z)):
			return true
	return false


# Un arbolito: tronco y tres copas redondas, con su color en los vértices (el tronco pardo, las copas verdes).
func _arbolito() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.1
	tronco.bottom_radius = 0.16
	tronco.height = 2.0
	tronco.radial_segments = 6
	tronco.rings = 1
	var partes := [[tronco, Transform3D(Basis(), Vector3(0, 1.0, 0)), Color(0.36, 0.26, 0.18)]]
	for c in [[Vector3(0, 2.4, 0), 1.0, Color(0.22, 0.38, 0.17)], [Vector3(0.5, 2.0, 0.2), 0.7, Color(0.27, 0.43, 0.19)],
			[Vector3(-0.4, 2.1, -0.3), 0.75, Color(0.19, 0.33, 0.15)]]:
		var s := SphereMesh.new()
		s.radius = c[1]
		s.height = c[1] * 1.7
		s.radial_segments = 8
		s.rings = 5
		partes.append([s, Transform3D(Basis(), c[0]), c[2]])
	for p in partes:
		var arr: Array = (p[0] as Mesh).surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var t: Transform3D = p[1]
		for i in arr[Mesh.ARRAY_INDEX]:
			st.set_color(p[2])
			st.set_normal(n[i])
			st.add_vertex(t * v[i])
	return st.commit()


var _desde_cache := false


func _fundir_unicas() -> void:
	for id in UNICAS:
		var n := _modelo(id)
		if n != null:
			_fundir(n, id if id in TAPAN else "")


func _fundir_relleno() -> void:                       # (con los faroles: los de _faroles no se juntaron)
	for d in Piezas2D.RELLENO:
		var r: Rect2i = d["rect"]
		var n := _modelo(d["id"])
		if n != null:
			n.position = Vector3(r.position.x, 0, r.position.y)
			_fundir(n)
