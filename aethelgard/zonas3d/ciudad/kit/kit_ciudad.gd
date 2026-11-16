extends RefCounted
# Biblioteca modular de la ciudad completa de Oakhaven (V12, 16/11; EN PRUEBAS, PROPUESTA [P]): lo que necesita Godot
# para usar un módulo del kit (zonas3d/ciudad/kit/modelos/<módulo>.glb) tal cual, sin hornear el sector:
#   var nodo := KitCiudad.instanciar("vivienda_terrazas", padre, Vector3(x, y, z), giro_grados)
# Viste sus mallas con los 4 sombreados de la muestra: lo fijo («<módulo>_fijo») con el ATLAS de luz del kit
# (kit_luz_2048.png, uno para todos los módulos; 1024 en el perfil bajo), las piezas y la vegetación con la luz en los
# vértices. Crea un StaticBody3D por cada vacío «choque_*» y devuelve el nodo; KitCiudad.anclas(nodo) da sus anclas.
# La luz de cada módulo está horneada SUELTO (sin las sombras de sus vecinos). Para el ACABADO de un sector, el sector
# se monta en Blender con la API del kit (kit_ciudad.colocar) y se hornea entero: ver docs/v12/CIUDAD_KIT.md.
# Pivote y giro: los de kit_ciudad.py (las fachadas miran a +z, al sur; giro 90 = al este, −90 = al oeste).

const RAIZ := "res://zonas3d/ciudad/kit/modelos/"
const RAIZ_MUESTRA := "res://zonas3d/muestra_calle/"
const SH_VERTICE := preload("res://zonas3d/muestra_calle/calle_vertice.gdshader")
const SH_HOJA := preload("res://zonas3d/muestra_calle/calle_hoja.gdshader")
const SH_BRILLO := preload("res://zonas3d/muestra_calle/calle_brillo.gdshader")
const SH_ESTATICO := preload("res://zonas3d/muestra_calle/calle_estatico.gdshader")
const ESCALA_LUZ := 2.229212239845512   # la de la muestra y el barrio (kit_ciudad.json, «escala_luz»)
const TEXTURA_DE := {"piedra": "piedra", "tierra": "tierra", "revoque": "revoque", "madera": "madera", "tejas": "tejas",
	"sillar": "sillar", "hierro": "piedra", "tela": "tela", "barro": "revoque", "hoja": "hoja"}

static var _mats := {}                  # clave → ShaderMaterial (compartidos por todos los módulos)
static var res_luz := 2048              # el atlas de luz que se usa: 2048 (medio y alto) o 1024 (bajo)


static func modulos() -> Dictionary:
	var f := FileAccess.open(RAIZ + "kit_ciudad.json", FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d.get("modulos", {}) if d is Dictionary else {}


static func material(nombre: String, viento := true, fijo := false) -> Material:
	var clave := ("f:" if fijo and nombre != "brillo" else "") + nombre + ("" if viento else ":quieto")
	if _mats.has(clave):
		return _mats[clave]
	var m := ShaderMaterial.new()
	if fijo and nombre != "brillo":
		m.shader = SH_ESTATICO
		var ruta_t: String = RAIZ_MUESTRA + "texturas/" + String(TEXTURA_DE.get(nombre, "revoque")) + ".png"
		if ResourceLoader.exists(ruta_t):
			m.set_shader_parameter("textura", load(ruta_t))
		var ruta_l := RAIZ + "kit_luz_%d.png" % res_luz
		if ResourceLoader.exists(ruta_l):
			m.set_shader_parameter("luz", load(ruta_l))
		m.set_shader_parameter("luz_escala", ESCALA_LUZ)
	elif nombre == "brillo":
		m.shader = SH_BRILLO
		m.set_shader_parameter("energia", 1.2)
		m.set_shader_parameter("usar_color_fijo", false)
	else:
		m.shader = SH_HOJA if nombre == "hoja" else SH_VERTICE
		var ruta: String = RAIZ_MUESTRA + "texturas/" + String(TEXTURA_DE.get(nombre, "revoque")) + ".png"
		if ResourceLoader.exists(ruta):
			m.set_shader_parameter("textura", load(ruta))
		m.set_shader_parameter("luz_escala", ESCALA_LUZ)
		if nombre == "hoja":
			m.set_shader_parameter("viento", 1.0 if viento else 0.0)
	_mats[clave] = m
	return m


static func soltar_caches() -> void:
	_mats.clear()


static func vestir(nodo: Node, viento := true) -> int:
	# Cambia los materiales del GLB por los de la muestra. Devuelve los triángulos que dibuja el módulo.
	var tris := 0
	for mi in nodo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var fijo := String(m.name).ends_with("_fijo")
		for i in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(i)
			var nombre := (orig.resource_name if orig != null else "").get_slice(".", 0)
			m.set_surface_override_material(i, material(nombre, viento, fijo))
			var arr := m.mesh.surface_get_arrays(i)
			var idx = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return tris


static func choques(nodo: Node3D, destino: Node = null) -> int:
	# Un StaticBody3D con su caja por cada vacío «choque_*» (escala = medio tamaño, como el barrio).
	var n := 0
	for c in nodo.find_children("choque_*", "", true, false):
		var t := (c as Node3D).transform
		var p: Node = c.get_parent()
		while p != nodo and p is Node3D:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var tam := t.basis.get_scale() * 2.0
		var cuerpo := StaticBody3D.new()
		cuerpo.name = String(c.name).replace("choque_", "Choque_")
		cuerpo.transform = Transform3D(t.basis.orthonormalized(), t.origin)
		var col := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = Vector3(absf(tam.x), absf(tam.y), absf(tam.z))
		col.shape = caja
		cuerpo.add_child(col)
		(destino if destino != null else nodo).add_child(cuerpo)
		n += 1
	return n


static func anclas(nodo: Node3D) -> Dictionary:
	# ancla_<módulo>_<nombre> → posición en el mundo (el nodo ya en el árbol) o local (fuera del árbol).
	var out := {}
	for a in nodo.find_children("ancla_*", "", true, false):
		var n3 := a as Node3D
		var clave := String(n3.name).trim_prefix("ancla_").trim_prefix(String(nodo.name) + "_")
		out[clave] = n3.global_position if n3.is_inside_tree() else n3.position
	return out


static func instanciar(nombre: String, padre: Node, pos: Vector3, giro_grados := 0.0) -> Node3D:
	var ruta := RAIZ + nombre + ".glb"
	if not ResourceLoader.exists(ruta):
		push_warning("[kit_ciudad] no existe el módulo %s" % nombre)
		return null
	var nodo: Node3D = (load(ruta) as PackedScene).instantiate()
	nodo.name = nombre
	nodo.position = pos
	nodo.rotation.y = deg_to_rad(giro_grados)
	padre.add_child(nodo)
	vestir(nodo)
	choques(nodo)
	return nodo
