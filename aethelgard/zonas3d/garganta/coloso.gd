extends RefCounted
# El Coloso de la Falla en la Garganta del Diablo 3D (V9, jefe 2; combate_coloso.gd): la figura que duerme al fondo de la
# grieta oculta, o lo que queda de él tras vencerle. Solo crea nodos; cuándo despierta lo decide zonas3d/garganta_3d.gd.
#   - Dormido: con su modelo 3D si ya existe y está activado (combate_coloso.modelo_3d_listo; enemigos/coloso_falla/,
#     de animaciones); si no, el guardián de piedra de Pastos Verdes (el mismo modelo que el gólem del nido), mucho más
#     grande, medio hundido en la roca contra la pared de la falla, gris, con las runas de ámbar latiendo despacio.
#   - Vencido: unas placas de piedra caídas junto a la pared, con las runas casi apagadas (sin colisión: no estorban).
# Sin luces reales: el brillo es emisión y un halo pintado (escenario.gd), como el gólem y el pilar del peregrino.

const K := preload("res://combate_coloso.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const MALLA := "res://modelos/guardian/guardian.res"
const ALTO := 4.4                 # metros: casi el doble que el gólem del nido (2,6 m)
const GIRO_Y := 196.0             # de cara al sur, por donde llega Kael (como el gólem, que mira al centro del nido)


# Dormido. Devuelve su nodo (null si no hay ni modelo 3D ni la malla del guardián).
static func dormido(region: Node3D, esc, lotes, perfil: Dictionary, p: Vector3) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = "ColosoFalla"
	nodo.position = p
	if K.modelo_3d_listo():
		var g = load(K.GUION_3D).new()
		if "dormido_al_empezar" in g:
			g.dormido_al_empezar = true
		nodo.add_child(g)
		nodo.rotation.y = deg_to_rad(GIRO_Y)
		region.add_child(nodo)
		esc.halo(p, p + Vector3(0, 2.4, 0), Materiales.AMBAR, 5.0, 2.6, lotes)
		return nodo
	if not ResourceLoader.exists(MALLA):
		nodo.free()
		return null
	var malla: Mesh = load(MALLA)
	nodo.position = p + Vector3(0, -0.7, 0)          # medio hundido en la roca de la falla, algo inclinado
	nodo.rotation = Vector3(deg_to_rad(9.0), deg_to_rad(GIRO_Y), 0)
	region.add_child(nodo)
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists("res://modelos/guardian/guardian_color.png"):
		m.albedo_texture = load("res://modelos/guardian/guardian_color.png")
	if perfil.get("relieve", true) and ResourceLoader.exists("res://modelos/guardian/guardian_normal.png"):
		m.normal_enabled = true
		m.normal_texture = load("res://modelos/guardian/guardian_normal.png")
	m.albedo_color = Color(0.56, 0.57, 0.6)           # piedra gris (la textura es parda); el ámbar, en las runas
	m.roughness = 0.75
	m.emission_enabled = true
	m.emission = Materiales.AMBAR
	m.emission_energy_multiplier = 0.04
	mi.material_override = m
	nodo.add_child(mi)
	mi.add_to_group("ocluye")                          # si tapa a Kael, la cámara lo aclara (vista3d.gd)
	var alto := maxf(malla.get_aabb().size.y, 0.01)
	nodo.scale = Vector3.ONE * (ALTO / alto)
	var t := mi.create_tween().set_loops()            # las runas laten, muy despacio: duerme
	t.tween_property(m, "emission_energy_multiplier", 0.2, 3.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(m, "emission_energy_multiplier", 0.03, 3.2).set_trans(Tween.TRANS_SINE)
	nodo.set_meta("material", m)
	esc.halo(p, p + Vector3(0, 2.4, 0), Materiales.AMBAR, 5.0, 2.6, lotes)
	return nodo


# Las runas se encienden de golpe: va a despertar (garganta_3d.gd, antes del combate).
static func despertar(nodo: Node3D) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	if nodo.has_meta("material"):
		var m: StandardMaterial3D = nodo.get_meta("material")
		var t := nodo.create_tween()
		t.tween_property(m, "emission_energy_multiplier", 1.6, 0.6).set_trans(Tween.TRANS_QUAD)
	for h in nodo.get_children():
		if h.has_method("despertar"):                 # su modelo 3D (la interfaz de guardian_bosque_3d.gd)
			h.despertar()


# Vencido: placas caídas junto a la pared (en lotes: se juntan con la roca al cerrar las piezas).
static func ruinas(lotes, mat: Materiales, p: Vector3) -> void:
	var piedra := mat.liso(Color(0.5, 0.48, 0.45), 0.9)
	var runa := mat.brillo(Materiales.AMBAR, 0.25)
	var placas := [[Vector3(0.3, 0.25, -0.2), Vector3(1.4, 0.5, 0.9), 12.0], [Vector3(-0.9, 0.18, 0.5), Vector3(1.0, 0.36, 0.8), -25.0],
		[Vector3(0.9, 0.3, 0.9), Vector3(0.8, 0.6, 0.7), 40.0], [Vector3(-0.2, 0.55, -0.6), Vector3(1.1, 0.4, 0.8), 70.0]]
	for i in placas.size():
		var x: Array = placas[i]
		var b := BoxMesh.new()
		b.size = x[1]
		var base := Basis(Vector3.UP, deg_to_rad(x[2])) * Basis(Vector3.RIGHT, deg_to_rad(8.0 * (i - 1.5)))
		lotes.poner(b, Transform3D(base, p + x[0]), piedra)
		var r := BoxMesh.new()                         # una runa en la cara de arriba, casi apagada
		r.size = Vector3(0.28, 0.02, 0.06)
		lotes.poner(r, Transform3D(base, p + x[0] + base * Vector3(0, x[1].y * 0.5 + 0.01, 0)), runa)
