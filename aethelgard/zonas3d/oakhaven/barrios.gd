extends Node3D
# Oakhaven 3D completo (V12, fase 2, migración región a región): la geografía de la ciudad 2D que faltaba en la 3D. El
# mismo trazado (ciudades/oakhaven.gd, LUGARES: una casilla es un metro) con su arquitectura, hecha en Blender con las
# funciones del distrito de los oficios (fuente/crear_barrios.py → modelos/barrios.glb y, para medio y bajo,
# barrios_ligero.glb):
#   - la muralla: norte, oeste y este, y los dos tramos del sur a los lados de la Puerta del Sur (se vuelven
#     transparentes si tapan a Kael);
#   - la Torre de la Campana y la ronda de la muralla este, EN ALTO (ALTO_RONDA): se sube y se baja por la torre
#     (piezas oak_torre y oak_ronda_bajar, con un fundido, como en la 2D); sus tres faroles se encienden de verdad;
#   - la Colina del Crematorio: un altozano (ALTO_COLINA) con su muro de contención y la subida empedrada desde la Calle
#     del Mercado; el crematorio de piedra hueso con su chimenea de humo blanco y la puerta sellada; el jardín de urnas;
#   - el muro del callejón con la grieta (se ve la luz de las velas; no se cruza andando: la pieza oak_grieta la pasa) y
#     el Patio de las Velas, cerrado, con su altar;
#   - la raíz cortada junto al Árbol, el tablón del gremio en la plaza y la mesa de juego del Patio del Cuervo;
#   - plantillas (el cofre y el brasero de los proyectos) y las figuras de los vecinos que faltaban (vida3d.gd las pone).
#
#   Barrios.crear(region, ciudad, mat, perfil, nombre_perfil) -> Node3D (null con Engine «oakhaven_sin_barrios»)
#
# Por dónde se anda (oakhaven_3d.gd, _prohibido): a ras de suelo, como siempre (ciudad.bloqueos, donde van también las
# cajas de aquí); en el altozano, igual (Kael queda a ALTO_COLINA: los choques de las cajas y la rampa lo llevan); en alto
# (más de EN_ALTO), solo el adarve de la ronda. altura(x, z) dice la altura del suelo en cada sitio (para colocar a Kael,
# a los vecinos y las cosas, y para las partidas que vienen de la 2D).

const Oak := preload("res://ciudades/oakhaven.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const KIT := "res://zonas3d/oakhaven/modelos/barrios.glb"
const KIT_LIGERO := "res://zonas3d/oakhaven/modelos/barrios_ligero.glb"
const ALTO_COLINA := 1.2                  # (las mismas medidas que crear_barrios.py)
const ALTO_RONDA := 4.0
const EN_ALTO := 2.5                      # por encima, Kael está en la ronda
const COLINA := Rect2(56.0, 0.8, 23.2, 18.2)
const RAMPA := Rect2(64.0, 19.0, 2.0, 6.0)        # de ALTO_COLINA (z = 19) a 0 (z = 25)
const RONDA := Rect2(75.0, 28.0, 4.2, 14.0)       # el bloque de la ronda (a ras de suelo no se pisa)
const ADARVE := Rect2(76.0, 28.4, 2.6, 13.3)      # lo que se pisa arriba
const RONDA_ALTA := Rect2(76.0, 28.0, 2.0, 14.0)  # la casilla «ronda» de la 2D (Oak.LUGARES), para las partidas
# A ras de suelo tampoco se pisan los torreones de la Puerta del Sur ni la franja al sur de la muralla.
# Y lo que traen los modelos de gráficos sin choque: los barriles y cajas del Patio del Cuervo, el tablón del bando de la
# plaza y el puesto de flores de Rosa.
const BLOQUEOS_EXTRA := [Rect2(34.6, 52.0, 2.9, 2.9), Rect2(43.6, 52.0, 2.9, 2.9), Rect2(0.0, 54.4, 37.2, 2.0),
	Rect2(43.8, 54.4, 37.0, 2.0), Rect2(10.4, 27.5, 3.8, 1.2), Rect2(11.8, 28.6, 0.8, 0.9), Rect2(12.9, 29.5, 1.4, 1.0),
	Rect2(35.2, 28.6, 1.6, 0.4), Rect2(43.2, 27.6, 1.8, 0.7)]

var region: Node3D
var ciudad                                 # zonas3d/oakhaven/ciudad.gd (sus bloqueos)
var mat: Materiales
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var ligero := false
var anclas := {}                           # nombre → Vector3 (los vacíos «ancla_» del GLB)
var bloqueos: Array = []                   # Rect2 a ras de suelo (también en ciudad.bloqueos)
var bajo_ronda: Array = []                 # Rect2 que a ras de suelo no se pisan pero arriba sí (la ronda)
var plantillas := {}                       # nombre → Mesh (plantilla_cofre_base, plantilla_cofre_tapa, plantilla_brasero)
var figuras := {}                          # vecino → Mesh (pnj_<id>)
var faroles := {}                          # «farol_1»… → Node3D con su fuego (encender)
var triangulos := 0
var mallas := 0
var choques := 0
var limpiadas := 0
var ms_montar := 0.0
var humo: CPUParticles3D
var _mat_brillo: StandardMaterial3D
var _mat_figura: StandardMaterial3D


static func crear(region_: Node3D, ciudad_, mat_: Materiales, perfil_: Dictionary, nombre_: String) -> Node3D:
	if Engine.has_meta("oakhaven_sin_barrios"):
		return null
	var b = load("res://zonas3d/oakhaven/barrios.gd").new()
	b.name = "Barrios"
	b.region = region_
	b.ciudad = ciudad_
	b.mat = mat_ if mat_ != null else Materiales.new(perfil_)
	b.perfil = perfil_
	b.nombre_perfil = nombre_ if nombre_ in ["bajo", "medio", "alto"] else "alto"
	region_.add_child(b)
	b._montar()
	return b


func resumen() -> Dictionary:
	return {"kit": KIT_LIGERO if ligero else KIT, "triangulos": triangulos, "mallas": mallas, "choques": choques,
		"bloqueos": bloqueos.size(), "limpiadas": limpiadas, "figuras": figuras.size(), "ms": snappedf(ms_montar, 0.1)}


# ================================================================= alturas y paso (los usa oakhaven_3d.gd)

# La altura del suelo a ras de la ciudad (sin la ronda): el altozano de la colina, la rampa o 0.
static func altura(x: float, z: float) -> float:
	if COLINA.has_point(Vector2(x, z)):
		return ALTO_COLINA
	if RAMPA.has_point(Vector2(x, z)):
		return ALTO_COLINA * clampf((RAMPA.end.y - z) / RAMPA.size.y, 0.0, 1.0)
	return 0.0


# La altura de una casilla de la 2D: la ronda va en alto (Oak.LUGARES, «en_alto»); lo demás, altura().
static func altura_2d(x: float, z: float) -> float:
	if RONDA_ALTA.has_point(Vector2(x, z)):
		return ALTO_RONDA
	return altura(x, z)


static func en_alto(p: Vector3) -> bool:
	return p.y > EN_ALTO


# ¿No se puede estar en p? Arriba, fuera del adarve; abajo, dentro del bloque de la ronda. (El resto de bloqueos de suelo
# los mira la ciudad: ciudad.bloqueado.)
func prohibido(p: Vector3) -> bool:
	if en_alto(p):
		return not ADARVE.has_point(Vector2(p.x, p.z))
	for r in bajo_ronda:
		if (r as Rect2).grow(0.3).has_point(Vector2(p.x, p.z)):
			return true
	return false


# ================================================================= montar

func _montar() -> void:
	var t0 := Time.get_ticks_usec()
	ligero = perfil.get("modelos_ligeros", nombre_perfil != "alto") and ResourceLoader.exists(KIT_LIGERO)
	var ruta := KIT_LIGERO if ligero else KIT
	if not ResourceLoader.exists(ruta):
		push_warning("Oakhaven 3D: faltan los barrios «%s»" % ruta)
		return
	_mat_brillo = StandardMaterial3D.new()
	_mat_brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_brillo.vertex_color_use_as_albedo = true
	_mat_figura = StandardMaterial3D.new()
	_mat_figura.vertex_color_use_as_albedo = true
	_mat_figura.roughness = 0.85
	var raiz: Node3D = (load(ruta) as PackedScene).instantiate()
	add_child(raiz)                                         # (en el árbol, para leer las transformaciones)
	for n in raiz.find_children("ancla_*", "Node3D", true, false):
		anclas[String(n.name).trim_prefix("ancla_")] = to_local((n as Node3D).global_position)
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var nombre := String(mi.name)
		if nombre.begins_with("pnj_"):
			figuras[nombre.trim_prefix("pnj_")] = (mi as MeshInstance3D).mesh
			continue
		if nombre.begins_with("plantilla_"):
			plantillas[nombre] = (mi as MeshInstance3D).mesh
			continue
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Choque_" + nombre
		add_child(cuerpo)
		_cajas(mi, cuerpo, nombre)
		var lotes := _por_material(mi as MeshInstance3D)
		for clave in lotes:
			var edif := nombre.begins_with("edif_")
			var m := _malla(lotes[clave], mat.sillar() if clave == "base" else _mat_brillo, "%s_%s" % [nombre, clave],
				cuerpo if edif else self)
			if edif and clave == "base":
				m.add_to_group("ocluye")                     # si tapa a Kael, medio transparente (vista3d.gd)
			if clave == "brillo" or nombre.begins_with("suelo_") or nombre == "muro_velas_suelo":
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.queue_free()
	_rampa()
	for r in BLOQUEOS_EXTRA:
		_bloquear(r)
	_limpiar_vegetacion()
	_humo()
	_velas()
	_faroles()
	ms_montar = (Time.get_ticks_usec() - t0) / 1000.0


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
	padre.add_child(mi)
	if padre != self:
		mi.position = -(padre as Node3D).position
	_contar(am)
	mallas += 1
	return mi


func _contar(m: Mesh) -> void:
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		triangulos += (idx.size() if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


# Los choques de caja de un objeto (sus vacíos «caja_<i>_<ancho>_<fondo>_<alto>», en cm). Los de «suelo_» se pisan por
# encima: el altozano no bloquea nada en el plano (sus bordes los paran los choques); la ronda, solo a ras de suelo.
func _cajas(mi: Node3D, cuerpo: StaticBody3D, nombre: String) -> void:
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
		var r := Rect2(base.x - tam.x * 0.5, base.z - tam.z * 0.5, tam.x, tam.z)
		if nombre == "suelo_colina":
			continue
		if nombre == "suelo_ronda":
			bajo_ronda.append(r)
			continue
		_bloquear(r)


func _bloquear(r: Rect2) -> void:
	bloqueos.append(r)
	if ciudad != null and ciudad.get("bloqueos") is Array:
		ciudad.bloqueos.append(r)


# La subida de la colina: una caja inclinada (de ALTO_COLINA en z = 19 a 0 en z = 25) sobre la que se anda.
func _rampa() -> void:
	var ang := atan2(ALTO_COLINA, RAMPA.size.y)
	var normal := Vector3(0, cos(ang), sin(ang))
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Choque_rampa"
	add_child(cuerpo)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(RAMPA.size.x, 0.3, RAMPA.size.y / cos(ang) + 0.4)
	col.shape = caja
	col.transform = Transform3D(Basis(Vector3.RIGHT, ang), Vector3(RAMPA.get_center().x, ALTO_COLINA * 0.5, RAMPA.get_center().y) - normal * 0.15)
	cuerpo.add_child(col)
	choques += 1


# Las matas, flores, arbustos y arbolitos de la ciudad que quedaban debajo del altozano, de la ronda o de los muros nuevos.
func _limpiar_vegetacion() -> void:
	if region == null:
		return
	var zonas: Array = [COLINA.grow(0.2), RONDA.grow(0.2)]
	for r in bloqueos:
		zonas.append((r as Rect2).grow(0.2))
	var cero := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	for n in region.get_children():
		if not n is MultiMeshInstance3D:
			continue
		var nombre := String(n.name)
		if not (nombre.begins_with("Matas") or nombre.begins_with("Flores") or nombre.begins_with("Arbustos") or nombre.begins_with("Arbolitos")):
			continue
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		var o: Vector3 = (n as Node3D).position
		for i in mm.instance_count:
			var p := o + mm.get_instance_transform(i).origin
			for r in zonas:
				if (r as Rect2).has_point(Vector2(p.x, p.z)):
					mm.set_instance_transform(i, cero)
					limpiadas += 1
					break


# ================================================================= fuego, humo y luz

# El humo blanco de la chimenea del crematorio (pocas partículas grandes y blandas, como el de la fragua).
func _humo() -> void:
	if not anclas.has("humo_crematorio"):
		return
	humo = _particulas("HumoCrematorio", 8 if ligero else 14, 6.0, Color(0.92, 0.93, 0.96, 0.5), 1.0)
	humo.position = anclas["humo_crematorio"]
	humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	humo.emission_sphere_radius = 0.25
	humo.direction = Vector3.UP
	humo.spread = 10.0
	humo.initial_velocity_min = 0.5
	humo.initial_velocity_max = 0.8
	humo.gravity = Vector3(0.12, 0.1, 0.05)
	humo.preprocess = 6.0
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.6))
	curva.add_point(Vector2(1.0, 3.0))
	humo.scale_amount_curve = curva


# Las velas del altar del Patio de las Velas: llamitas, el resplandor en el suelo y, en el alto, luz de verdad.
func _velas() -> void:
	var hay := false
	for k in anclas:
		if String(k).begins_with("vela_"):
			hay = true
			_llama(anclas[k], 0.12, float(String(k).trim_prefix("vela_")) * 1.3)
	if not hay or not anclas.has("altar_velas"):
		return
	var a: Vector3 = anclas["altar_velas"]
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.4, 3.4)
	var halo := MeshInstance3D.new()
	halo.mesh = pm
	halo.material_override = mat.halo_suelo(Materiales.FUEGO)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = a + Vector3(0, 0.04, 0.5)
	halo.name = "ResplandorVelas"
	add_child(halo)
	mallas += 1
	if perfil.get("luces_faroles", false):
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.72, 0.40)
		o.light_energy = 1.1
		o.omni_range = 4.5
		o.position = a + Vector3(0, 1.2, 0.3)
		o.name = "LuzVelas"
		add_child(o)


# Los tres faroles de la ronda: su fuego, que se enciende con la misión de Bastián (encender()).
func _faroles() -> void:
	for i in [1, 2, 3]:
		var k := "farol_%d" % i
		if not anclas.has(k):
			continue
		var n := Node3D.new()
		n.name = "FuegoFarol%d" % i
		n.position = anclas[k]
		add_child(n)
		var q := QuadMesh.new()
		q.size = Vector2(0.14, 0.24)
		var ll := MeshInstance3D.new()
		ll.mesh = q
		ll.material_override = mat.llama(float(i) * 2.1, 1.0)
		ll.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(ll)
		if nombre_perfil == "alto":
			var qa := QuadMesh.new()
			qa.size = Vector2(1.3, 1.3)
			var brillo := MeshInstance3D.new()
			brillo.mesh = qa
			brillo.material_override = mat.halo_aire(Materiales.FUEGO)
			brillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(brillo)
		n.visible = false
		faroles[k] = n


func encender(k: String, si: bool) -> void:
	if faroles.has(k):
		(faroles[k] as Node3D).visible = si


func _llama(p: Vector3, alto: float, fase: float) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(alto * 0.62, alto)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat.llama(fase, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	mi.name = "Llama"
	add_child(mi)
	mallas += 1


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


# ================================================================= plantillas y figuras (las pone vida3d.gd)

# Una figura de vecino (PROVISIONAL: malla de Blender sin esqueleto, del estilo de Ferro, Hilda y Mirta), o null.
func figura(id: String) -> MeshInstance3D:
	if not figuras.has(id):
		return null
	var mi := MeshInstance3D.new()
	mi.name = "Figura"
	mi.mesh = figuras[id]
	_materiales(mi, _mat_figura)
	_contar(mi.mesh)
	mallas += 1
	return mi


func plantilla(nombre: String) -> MeshInstance3D:
	if not plantillas.has(nombre):
		return null
	var mi := MeshInstance3D.new()
	mi.name = nombre.trim_prefix("plantilla_")
	mi.mesh = plantillas[nombre]
	_materiales(mi, mat.sillar())
	return mi


# El material de cada superficie: lo que tiene luz propia («brillo»: las brasas, la gema de Selene, el farol de Albar),
# sin sombreado; lo demás, «base». Con una sola superficie, como material_override (así se puede volver transparente).
func _materiales(mi: MeshInstance3D, base: Material) -> void:
	var m: Mesh = mi.mesh
	if m.get_surface_count() == 1 and not _es_brillo(m, 0):
		mi.material_override = base
		return
	for s in m.get_surface_count():
		mi.set_surface_override_material(s, _mat_brillo if _es_brillo(m, s) else base)


static func _es_brillo(m: Mesh, s: int) -> bool:
	var sm := m.surface_get_material(s)
	return sm != null and sm.resource_name.begins_with("brillo")
