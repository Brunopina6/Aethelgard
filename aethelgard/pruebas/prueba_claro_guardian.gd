extends SceneTree
# Prueba del Claro del Guardián (V9, sector 3D y arena de jefe: zonas3d/bosque/claro_guardian.gd y su kit de Blender).
#   sin ventana:  --headless --script res://pruebas/prueba_claro_guardian.gd --fixed-fps 30
# Comprueba (y acaba con «FALLOS: n»):
#  - los dos GLB del kit (alto y ligero) cargan y traen todas las piezas, cada una con su superficie «base»; las que
#    deben chocar (menhires, tocón, arcos de raíz, mojón, raíz seca) traen sus cilindros
#  - el ligero tiene menos triángulos que el alto
#  - en los tres estados (dormido, purificado, derrotado) y con los dos kits (perfil alto y bajo), en llano y en el
#    terreno real de Pastos Verdes (sendero_puente.gd, en el sitio del claro de bosque_pastos.gd): se monta sin errores,
#    todo el sector cabe en el presupuesto (≤ 15 000 triángulos) y en pocas mallas (≤ 6), hay colisiones (≥ 9),
#    el centro queda libre (radio LIBRE), la entrada desde el sendero también (pasillo de Kael a 25°, 40° y 55°), y
#    ninguna colisión cae en el sendero ni en la zona prohibida
#  - cada estado es distinto: purificado con agua y motas, dormido con motas, derrotado sin motas ni agua y con las
#    runas apagadas

const CLARO := "res://zonas3d/bosque/claro_guardian.gd"
const TERRENO := "res://prototipos/sendero_puente.gd"
const SITIO := Vector3(17.0, 0, -18.5)          # bosque_pastos.gd, SITIO_CLARO
const PIEZAS := ["menhir_alto", "menhir_ancho", "menhir_puerta", "raiz_arco_grande", "raiz_arco", "raiz_baja", "tocon",
	"lecho", "musgo", "setas", "mojon", "ofrenda", "brote", "flores", "manantial", "raiz_seca"]
const CHOCAN := ["menhir_alto", "menhir_ancho", "menhir_puerta", "raiz_arco_grande", "raiz_arco", "tocon", "mojon", "raiz_seca"]
const KAEL := 0.4                                # radio con el que se mira el paso (la cápsula de Kael, con margen)
var fallos := 0
var C


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(texto: String) -> void:
	fallos += 1
	print("FALLO: ", texto)


func _bien(cond: bool, texto: String) -> void:
	if not cond:
		_fallo(texto)


func _probar() -> void:
	C = load(CLARO)
	_bien(C != null, "no carga " + CLARO)
	if C == null:
		_terminar()
		return
	# ---- el kit
	var tri := {}
	for ruta in [C.KIT, C.KIT_LIGERO]:
		_bien(ResourceLoader.exists(ruta), "falta " + ruta)
		var kit: Dictionary = C.piezas(ruta)
		var total := 0
		for p in PIEZAS:
			if not kit.has(p):
				_fallo("%s: falta la pieza %s" % [ruta.get_file(), p])
				continue
			var malla: Mesh = kit[p]["malla"]
			var con_base := false
			for s in malla.get_surface_count():
				var m := malla.surface_get_material(s)
				if m != null and m.resource_name.begins_with("base"):
					con_base = true
				var a := malla.surface_get_arrays(s)
				total += (a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size()) / 3
				_bien(a[Mesh.ARRAY_COLOR] != null and a[Mesh.ARRAY_COLOR].size() == a[Mesh.ARRAY_VERTEX].size(),
					"%s: %s sin colores de vértice" % [ruta.get_file(), p])
			_bien(con_base, "%s: %s sin superficie «base»" % [ruta.get_file(), p])
			if p in CHOCAN:
				_bien(kit[p]["choques"].size() > 0, "%s: %s sin cilindros de choque" % [ruta.get_file(), p])
		tri[ruta] = total
		print("kit %s: %d piezas, %d triángulos (una de cada)" % [ruta.get_file(), kit.size(), total])
	_bien(tri.get(C.KIT_LIGERO, 0) < tri.get(C.KIT, 0), "el kit ligero no tiene menos triángulos que el alto")
	# ---- el sector montado
	var mundo := Node3D.new()
	mundo.name = "Mundo"
	root.add_child(mundo)
	var region = load(TERRENO).new() if ResourceLoader.exists(TERRENO) else null   # sin añadir: solo sus funciones
	for perfil in ["alto", "bajo"]:
		Engine.set_meta("calidad_proto", perfil)
		_bien(C.ruta_kit() == (C.KIT if perfil == "alto" else C.KIT_LIGERO), "perfil %s: kit equivocado %s" % [perfil, C.ruta_kit()])
		for estado in C.ESTADOS:
			await _caso(mundo, null, Vector3(0, 0, 0), estado, perfil + " llano")
			if region != null:
				var centro := Vector3(SITIO.x, region.altura(SITIO.x, SITIO.z), SITIO.z)
				await _caso(mundo, region, centro, estado, perfil + " Pastos Verdes")
	Engine.remove_meta("calidad_proto")
	if region != null:
		region.free()
	mundo.free()
	_terminar()


func _caso(mundo: Node3D, region, centro: Vector3, estado: String, nombre: String) -> void:
	var etiqueta := "%s, %s" % [nombre, estado]
	var t0 := Time.get_ticks_usec()
	var s: Node3D = C.crear(region, centro, estado, mundo)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	await physics_frame
	await physics_frame
	var tri: int = s.get_meta("triangulos", -1)
	var mallas := s.find_children("*", "MeshInstance3D", true, false)
	var formas := s.find_children("*", "CollisionShape3D", true, false)
	print("%s: %d triángulos, %d mallas, %d colisiones, %.1f ms" % [etiqueta, tri, mallas.size(), formas.size(), ms])
	_bien(s.get_meta("estado", "") == estado, etiqueta + ": estado mal guardado")
	_bien(tri > 0 and tri <= C.PRESUPUESTO, "%s: %d triángulos (presupuesto %d)" % [etiqueta, tri, C.PRESUPUESTO])
	_bien(mallas.size() <= 6, "%s: %d mallas (se esperan ≤ 6: una por material)" % [etiqueta, mallas.size()])
	_bien(formas.size() >= 9, "%s: solo %d colisiones" % [etiqueta, formas.size()])
	var espacio := s.get_world_3d().direct_space_state
	# el centro, libre
	var cil := CylinderShape3D.new()
	cil.radius = C.LIBRE - 0.1
	cil.height = 1.6
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cil
	q.transform = Transform3D(Basis(), centro + Vector3(0, 1.0, 0))
	_bien(espacio.intersect_shape(q).is_empty(), etiqueta + ": hay una colisión en el centro del claro")
	# la entrada desde el sendero, libre (pasillo de Kael)
	var bola := SphereShape3D.new()
	bola.radius = KAEL
	for ang in [C.ENTRADA - 15.0, C.ENTRADA, C.ENTRADA + 15.0]:
		var dir := Vector3(cos(deg_to_rad(ang)), 0, sin(deg_to_rad(ang)))
		var d := 6.5
		while d > C.LIBRE - 0.2:
			var p := centro + dir * d
			var y: float = region.altura(p.x, p.z) if region != null else centro.y
			var qb := PhysicsShapeQueryParameters3D.new()
			qb.shape = bola
			qb.transform = Transform3D(Basis(), Vector3(p.x, y + 0.9, p.z))
			if not espacio.intersect_shape(qb).is_empty():
				_fallo("%s: la entrada a %d° está cerrada a %.1f m del centro" % [etiqueta, int(ang), d])
				break
			d -= 0.4
	# ninguna colisión en el sendero ni en lo prohibido
	if region != null:
		for f in formas:
			var w: Vector3 = (f as Node3D).global_position
			var r: float = (f.shape as CylinderShape3D).radius
			if region._dist_sendero(w) < r + C.MARGEN_SENDERO - 0.01:
				_fallo("%s: una colisión (radio %.2f) a %.2f m del sendero" % [etiqueta, r, region._dist_sendero(w)])
			# (fuera de LIMITE no se anda: ahí puede haber decorado; dentro, lo prohibido es el río y el canal)
			if region._prohibido(w) and load(TERRENO).LIMITE.has_point(Vector2(w.x, w.z)):
				_fallo("%s: una colisión en el río o el canal (%.1f, %.1f)" % [etiqueta, w.x, w.z])
	# cada estado, el suyo
	var agua := s.get_node_or_null("Agua") != null
	var motas := s.get_node_or_null("Motas") != null
	var runas := s.get_node_or_null("Runas") as MeshInstance3D
	_bien(runas != null, etiqueta + ": sin runas")
	match estado:
		"purificado":
			_bien(agua and motas, etiqueta + ": falta el manantial o las motas")
		"dormido":
			_bien(motas and not agua, etiqueta + ": el dormido lleva motas y no lleva agua")
		"derrotado":
			_bien(not motas and not agua, etiqueta + ": el derrotado no lleva motas ni agua")
			if runas != null:
				var c: Color = (runas.material_override as StandardMaterial3D).albedo_color
				_bien(c.get_luminance() < 0.3, etiqueta + ": las runas siguen encendidas")
	s.free()
	await physics_frame


func _terminar() -> void:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
