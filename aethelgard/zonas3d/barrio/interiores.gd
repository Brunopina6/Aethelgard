extends Node3D
# DUEÑO: agente B. LOS TRES INTERIORES del barrio experimental de Oakhaven (EN PRUEBAS: solo desde el banco de Auditoría;
# la región, zonas3d/barrio/barrio.gd, solo existe allí). Plan: docs/v12/BARRIO_OAKHAVEN_PLAN.md §3, §8, §9 y §11 (B);
# lo hecho: docs/v12/BARRIO_OAKHAVEN.md, sección B.
#
# Los tres van en la MISMA escena que el barrio, cada uno en su ORIGEN lejano, ocultos y con PROCESS_MODE_DISABLED
# cuando no se usan (sus choques salen del mundo físico). Cada uno es distinto en planta, muebles y actividad:
#   - HORNO de Maela (10 × 7, en L): el obrador (la boca del horno de bóveda con las brasas, la artesa con la masa, los
#     estantes de enfriar llenos, los sacos) y la tienda con el mostrador a la calle; tras la CORTINA (paso interno
#     «cortina_horno», siempre abierto), la zona de Maela: hogar pequeño, alacena, mesa con su vela y la escalera.
#   - TALLER de Damián (nave alta 9 × 7 + trastienda 4 × 7 al oeste): el potro con la rueda a medio hacer, el torno de
#     pértiga, el banco de las gubias y la pared de las herramientas con sus siluetas pintadas: la de la GALGA está vacía
#     (el clavo vacío: la pista). La TRASTIENDA (paso «trastienda») está CERRADA hasta «estado:enf_taller»: su puerta se
#     ve cerrada y, al acercarse, el aviso dice por qué.
#   - VIVIENDA de Odila y Nela (8 × 8, en profundidad): la cocina con el hogar y la GALGA sobre la repisa (la pista), la
#     mesa de la familia, el cántaro y la silla de Odila junto a la ventana; dos escalones arriba (+0,35, paso «alcoba»)
#     la alcoba: la cama grande, el arcón, la cama de Nela y su rincón con la rueda de juguete.
#
# La geometría y la luz salen de Blender (fuente/crear_interiores.py → modelos/int_<id>.glb, int_<id>_luz_1024.png e
# interiores/<id>.json con el suelo, los bloqueos, los pasos, las alturas, los choques, las anclas «int_<id>_*», los
# objetos y las sondas). Materiales: los sombreados de la muestra de la calle SIN CAMBIOS (calle_estatico con el mapa de
# luz, calle_vertice para las piezas, calle_brillo para el fuego): no hay programas nuevos que precalentar.
#
# CONTRATO con la región (docs/v12/BARRIO_OAKHAVEN.md §2.3): ORIGEN (id → Vector3; un id que falta = «en obras»),
# construir(region), preparar(id), mostrar(id) («» = todos ocultos), entrada(id), mira_entrada(id), salida(id) (el botón
# «Salir» de dentro), andable(p), altura(p), abrir_paso(nombre, abierto), ancla(nombre), camara(id, k) ([posición,
# rotación en grados, campo]), sonda(p), interior_de(p) y soltar_caches(). Añadidos (para C y las pruebas): datos(id),
# objetos(id), paso_abierto(nombre), sitio(nombre) y poner_sitio(nombre, visible).
#
# Objetos (interiores/<id>.json, «objetos»): cada ancla de algo que se puede mirar lleva su CLASE:
#   «examinable» = se mira (no se coge); «ofrecido» = su dueño lo da (en su diálogo), no se toma; «privado» = es de
#   alguien: tocarlo provoca su reacción o un aviso. Los TEXTOS son de C (Barrio.PIEZAS con estas anclas).

const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const Progreso := preload("res://progreso.gd")
# Los sombreados y las texturas de la muestra de la calle, SIN CAMBIOS (plan §8): se cargan al construir (no con preload:
# una exportación sin la muestra no rompe la compilación de este archivo).
const MUESTRA := "res://zonas3d/muestra_calle/"
const SH_ESTATICO := MUESTRA + "calle_estatico.gdshader"
const SH_VERTICE := MUESTRA + "calle_vertice.gdshader"
const SH_BRILLO := MUESTRA + "calle_brillo.gdshader"
const RAIZ := "res://zonas3d/barrio/"
const TEXTURAS := MUESTRA + "texturas/"
const TEXTURA_DE := {"piedra": "piedra", "tierra": "tierra", "revoque": "revoque", "madera": "madera", "sillar": "sillar",
	"tela": "tela", "barro": "revoque", "hierro": "piedra"}
const UTENSILIOS := RAIZ + "modelos/utensilios.glb"

const IDS := ["horno", "taller", "vivienda"]
const ORIGEN := {"horno": Vector3(-300, 0, 200), "taller": Vector3(-300, 0, 240), "vivienda": Vector3(-300, 0, 280)}
const TAM := {"horno": Vector2(10, 7), "taller": Vector2(13, 7), "vivienda": Vector2(8, 8)}
# Hacia dónde mira Kael al entrar (rotation.y: 0 = norte, PI/2 = oeste): al fondo de la sala; en el taller, que se entra
# por el portón del este, hacia el oeste.
const MIRA := {"horno": 0.0, "taller": PI / 2.0, "vivienda": 0.0}
const PASO_DE := {"cortina_horno": "horno", "trastienda": "taller", "alcoba": "vivienda"}
const SONDA_NEUTRA := Vector2(1.0, 0.7)

# La cámara de interior (= fuente/crear_interiores.py): más cerca que la de fuera (9,5 m frente a 17,8 m), más
# inclinada, sin girar nunca. Sigue a Kael dentro de los límites de cada sala (interiores/<id>.json, «camara»).
const CAM_ALTO := 6.2
const CAM_SUR := 7.2
const CAM_INCL := 40.73                    # atan2(6,2; 7,2)
const CAM_CAMPO := 44.0
const CAM_SUAVE := 6.0

# Ajuste fino de la luz horneada por sala (multiplica la «escala» del json; 1 = la exposición de Blender).
const BRILLO := {"horno": 1.0, "taller": 1.0, "vivienda": 1.0}
# La luz de Kael (y de los vecinos con sombreado normal) dentro: el sol de la región, más débil y cálido (lo que entra
# por las ventanas), y un ambiente cálido de fuego y paredes. Se ponen en mostrar(id) y se devuelven en mostrar("").
const LUZ_KAEL := {
	"horno": {"sol": 0.42, "sol_color": Color(1.0, 0.80, 0.60), "amb": 0.72, "amb_color": Color(1.0, 0.78, 0.58)},
	"taller": {"sol": 0.5, "sol_color": Color(1.0, 0.84, 0.66), "amb": 0.66, "amb_color": Color(0.92, 0.84, 0.74)},
	"vivienda": {"sol": 0.38, "sol_color": Color(1.0, 0.82, 0.62), "amb": 0.66, "amb_color": Color(1.0, 0.80, 0.62)},
}
const FONDO_DENTRO := Color(0.075, 0.058, 0.048)

# El aviso de la trastienda cerrada (plan §3). Sale al acercarse a su puerta, una vez por acercamiento.
const AVISO_TRASTIENDA := "Damián guarda ahí la madera buena."
const DIST_AVISO := 0.95
const DIST_REARMAR := 1.9
const T_PUERTA := 0.6

var region = null
var actual := ""                           # el interior que se enseña («» = ninguno)
var _nodos := {}                           # id → Node3D (en su ORIGEN)
var _hechos := {}                          # id → true: ya construido
var _pedidos := {}                         # id → true: carga en hilo pedida
var _mats_sombra := {}                     # id → [ShaderMaterial] (kael_pos cada fotograma)
var _hojas := {}                           # paso → Node3D (la hoja que gira)
var _sitios := {}                          # nombre → Node3D (utensilios de sitio: la galga de la repisa)
var _forzado := {}                         # paso → bool (abrir_paso)
var _estado_paso := {}                     # paso → bool (lo último que se enseñó)
var _t_pasos := 0.0
var _avisado := false
var _cam_id := ""
var _cam_pos := Vector3.ZERO
var _cam_ms := 0
var _luz_fuera := {}                       # lo que había en la región antes de entrar (para devolverlo)
var choques := 0                           # cuerpos de choque creados (para las pruebas)

static var _datos := {}                    # id → Dictionary (interiores/<id>.json), una vez por proceso
static var _mats := {}                     # clave → Material, entre entradas (soltar_caches)


# ================================================================= datos (estáticos: no hace falta el árbol)

static func datos(id: String) -> Dictionary:
	if not _datos.has(id):
		var ruta := RAIZ + "interiores/%s.json" % id
		var d = null
		if FileAccess.file_exists(ruta):
			d = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		_datos[id] = d if d is Dictionary else {}
	return _datos[id]


static func ruta_modelo(id: String) -> String:
	return RAIZ + "modelos/int_%s.glb" % id


# El interior en el que cae p ("" = fuera). Lo usa la región para no restaurar a Kael dentro de un ORIGEN.
static func interior_de(p: Vector3) -> String:
	for id in ORIGEN:
		var l: Vector3 = p - ORIGEN[id]
		var t: Vector2 = TAM[id]
		if l.x > -1.5 and l.x < t.x + 1.5 and l.z > -1.5 and l.z < t.y + 1.5 and absf(l.y) < 6.0:
			return id
	return ""


static func _local(p: Vector3) -> Array:
	var id := interior_de(p)
	return [id, p - ORIGEN[id] if id != "" else Vector3.ZERO]


static func _en(r: Array, x: float, z: float) -> bool:
	return x >= float(r[0]) and x <= float(r[0]) + float(r[2]) and z >= float(r[1]) and z <= float(r[1]) + float(r[3])


# Cachés estáticas (materiales con su mapa de luz y los json): las suelta banco_pruebas.salir() (y la región al salir).
static func soltar_caches() -> void:
	_mats = {}
	_datos = {}


# ================================================================= la vida del nodo

func construir(r) -> void:
	region = r
	for id in IDS:
		var n := Node3D.new()
		n.name = "Int_" + id
		n.position = ORIGEN[id]
		n.visible = false
		n.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(n)
		_nodos[id] = n


# Carga en diferido (la región lo llama a menos de 8 m de la puerta): el GLB en un hilo y los datos.
func preparar(id: String) -> void:
	if not ORIGEN.has(id) or _hechos.has(id) or _pedidos.has(id):
		return
	datos(id)
	var ruta := ruta_modelo(id)
	if ResourceLoader.exists(ruta) and ResourceLoader.load_threaded_request(ruta) == OK:
		_pedidos[id] = true


func mostrar(id: String) -> void:
	if id != "" and ORIGEN.has(id) and not _hechos.has(id):
		_construir_interior(id)
	for k in _nodos:
		var n: Node3D = _nodos[k]
		n.visible = k == id
		n.process_mode = Node.PROCESS_MODE_INHERIT if k == id else Node.PROCESS_MODE_DISABLED
	if id != "" and actual == "":
		_luz_dentro(id)
	elif id == "" and actual != "":
		_luz_fuera_otra_vez()
	elif id != "" and id != actual:
		_luz_dentro(id)
	actual = id
	_cam_id = ""
	_avisado = false
	if id != "":
		_actualizar_pasos(id, false)


func entrada(id: String) -> Vector3:
	return ancla("int_%s_entrada" % id)


func mira_entrada(id: String) -> float:
	return float(MIRA.get(id, 0.0))


func salida(id: String) -> Vector3:
	return ancla("int_%s_salida" % id)


# ================================================================= suelo, pasos y anclas

func andable(p: Vector3) -> bool:
	var lp := _local(p)
	var id: String = lp[0]
	if id == "":
		return false
	var l: Vector3 = lp[1]
	var d := datos(id)
	var dentro := false
	for r in d.get("suelo", []):
		if _en(r, l.x, l.z):
			dentro = true
			break
	if not dentro:
		return false
	for r in d.get("bloqueos", []):
		if _en(r, l.x, l.z):
			return false
	var pasos: Dictionary = d.get("pasos", {})
	for nombre in pasos:
		if not paso_abierto(nombre) and _en(pasos[nombre]["rect"], l.x, l.z):
			return false
	return true


func altura(p: Vector3) -> float:
	var lp := _local(p)
	var id: String = lp[0]
	if id == "":
		return 0.0
	var l: Vector3 = lp[1]
	var y := 0.0
	for nv in datos(id).get("niveles", []):
		if _en(nv, l.x, l.z):
			y = maxf(y, float(nv[4]))
	return ORIGEN[id].y + y


# ¿Está abierto ese paso interno? abrir_paso() manda; si no, los «siempre» abiertos (cortina, alcoba) lo están, y la
# trastienda, cuando C lo diga (Barrio.paso_interno) o con «estado:enf_taller» (la regla del plan §3).
func paso_abierto(nombre: String) -> bool:
	if _forzado.has(nombre):
		return bool(_forzado[nombre])
	var id: String = PASO_DE.get(nombre, "")
	var info: Dictionary = datos(id).get("pasos", {}).get(nombre, {}) if id != "" else {}
	if bool(info.get("siempre", false)):
		return true
	if Barrio.paso_interno(nombre):
		return true
	return nombre == "trastienda" and Progreso.estado(Barrio.NOMBRE, "enf_taller")


func abrir_paso(nombre: String, abierto: bool) -> void:
	_forzado[nombre] = abierto
	var id: String = PASO_DE.get(nombre, "")
	if id != "" and _hechos.has(id):
		_actualizar_pasos(id, id == actual)


# Las anclas «int_<id>_<nombre>» en coordenadas del mundo (la «y» es la del suelo).
func ancla(nombre: String) -> Vector3:
	var partes := nombre.split("_")
	var id := partes[1] if partes.size() > 2 and partes[0] == "int" else ""
	if not ORIGEN.has(id):
		push_warning("Interiores: ancla desconocida «%s»" % nombre)
		return Vector3.ZERO
	var a = datos(id).get("anclas", {}).get(nombre, null)
	if not a is Array or (a as Array).size() < 3:
		if not nombre.ends_with("_entrada"):
			push_warning("Interiores: ancla desconocida «%s»" % nombre)
			return entrada(id)
		return ORIGEN[id] + Vector3(TAM[id].x * 0.5, 0.0, TAM[id].y - 1.0)
	return ORIGEN[id] + Vector3(float(a[0]), float(a[1]), float(a[2]))


# [{ancla, clase («examinable» | «ofrecido» | «privado»), que, pos}] de un interior (para C y las pruebas).
func objetos(id: String) -> Array:
	var r: Array = []
	for o in datos(id).get("objetos", []):
		var c: Dictionary = (o as Dictionary).duplicate()
		c["pos"] = ancla(str(o["ancla"]))
		r.append(c)
	return r


# Los utensilios «de sitio» que pone el interior (hoy: «galga», en la repisa de la vivienda). C puede ocultarlos cuando
# el objeto cambie de sitio (plan §4: una sola ubicación lógica por objeto).
func sitio(nombre: String) -> Node3D:
	return _sitios.get(nombre, null)


func poner_sitio(nombre: String, visible_: bool) -> void:
	var n := sitio(nombre)
	if n != null:
		n.visible = visible_


# ================================================================= cámara y luz

func camara(id: String, k: Vector3) -> Array:
	if not ORIGEN.has(id):
		return []
	var c: Dictionary = datos(id).get("camara", {"x": [TAM[id].x * 0.5, TAM[id].x * 0.5], "z": [TAM[id].y * 0.5, TAM[id].y * 0.5]})
	var l: Vector3 = k - ORIGEN[id]
	var fx := clampf(l.x, float(c["x"][0]), float(c["x"][1]))
	var fz := clampf(l.z, float(c["z"][0]), float(c["z"][1]))
	var meta: Vector3 = ORIGEN[id] + Vector3(fx, CAM_ALTO + l.y * 0.6, fz + CAM_SUR)
	var ahora := Time.get_ticks_msec()
	if _cam_id != id or ahora - _cam_ms > 300:
		_cam_pos = meta                                        # (al entrar, sin barrido)
	else:
		var dt := (ahora - _cam_ms) / 1000.0
		_cam_pos = _cam_pos.lerp(meta, 1.0 - exp(-CAM_SUAVE * dt))
	_cam_id = id
	_cam_ms = ahora
	return [_cam_pos, Vector3(-CAM_INCL, 0.0, 0.0), CAM_CAMPO]


# Cuánto sol directo (por las ventanas) y cuánta luz de relleno (el cielo por los huecos y el resplandor de los fuegos)
# hay a 1 m del suelo en p (rejilla de 0,5 m del json, interpolada).
func sonda(p: Vector3) -> Vector2:
	var lp := _local(p)
	var id: String = lp[0]
	if id == "":
		return SONDA_NEUTRA
	var s: Dictionary = datos(id).get("sondas", {})
	if s.is_empty():
		return SONDA_NEUTRA
	var l: Vector3 = lp[1]
	var paso: float = s["paso"]
	var nx: int = s["nx"]
	var nz: int = s["nz"]
	var fx := clampf(l.x / paso, 0.0, nx - 1.001)
	var fz := clampf(l.z / paso, 0.0, nz - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var r := Vector2.ZERO
	for par in [["sol", 0], ["cielo", 1]]:
		var a: Array = s[par[0]]
		var v00: float = a[iz * nx + ix]
		var v10: float = a[iz * nx + ix + 1]
		var v01: float = a[(iz + 1) * nx + ix]
		var v11: float = a[(iz + 1) * nx + ix + 1]
		r[par[1]] = lerpf(lerpf(v00, v10, tx), lerpf(v01, v11, tx), tz)
	return r


# Dentro: el sol de la región, más débil y cálido; el ambiente, de fuego y paredes; el fondo, oscuro (lo que hay más allá
# de la casa de muñecas). Se guarda lo de fuera para devolverlo al salir.
func _luz_dentro(id: String) -> void:
	if region == null:
		return
	var amb = region.get("ambiente")
	var sol = region.get("sol")
	if _luz_fuera.is_empty() and amb is Environment and sol is DirectionalLight3D:
		_luz_fuera = {"fondo": amb.background_color, "amb_color": amb.ambient_light_color,
			"amb": amb.ambient_light_energy, "bruma": amb.fog_enabled, "sol": sol.light_energy, "sol_color": sol.light_color}
	var l: Dictionary = LUZ_KAEL.get(id, {})
	if amb is Environment and not l.is_empty():
		amb.background_color = FONDO_DENTRO
		amb.ambient_light_color = l["amb_color"]
		amb.ambient_light_energy = l["amb"]
		amb.fog_enabled = false
	if sol is DirectionalLight3D and not l.is_empty():
		sol.light_energy = l["sol"]
		sol.light_color = l["sol_color"]


func _luz_fuera_otra_vez() -> void:
	if region == null or _luz_fuera.is_empty():
		return
	var amb = region.get("ambiente")
	var sol = region.get("sol")
	if amb is Environment:
		amb.background_color = _luz_fuera["fondo"]
		amb.ambient_light_color = _luz_fuera["amb_color"]
		amb.ambient_light_energy = _luz_fuera["amb"]
		amb.fog_enabled = _luz_fuera["bruma"]
	if sol is DirectionalLight3D:
		sol.light_energy = _luz_fuera["sol"]
		sol.light_color = _luz_fuera["sol_color"]
	_luz_fuera = {}


# ================================================================= cada fotograma (solo dentro)

func _process(delta: float) -> void:
	if region == null or actual == "" or region.get("kael") == null:
		return
	var k: Vector3 = region.kael.global_position
	for m in _mats_sombra.get(actual, []):
		(m as ShaderMaterial).set_shader_parameter("kael_pos", k)
	_t_pasos -= delta
	if _t_pasos <= 0.0:
		_t_pasos = 0.25
		_actualizar_pasos(actual, true)
	if actual == "taller" and not paso_abierto("trastienda"):
		var d := Vector2(k.x, k.z).distance_to(_plano(ancla("int_taller_paso_trastienda")))
		if d < DIST_AVISO and not _avisado and not region.ocupado():
			_avisado = true
			region.avisar(AVISO_TRASTIENDA, "", 2.8)
		elif d > DIST_REARMAR:
			_avisado = false


static func _plano(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


# Cada paso del interior con hoja (la puerta de la trastienda): cerrada o abierta según paso_abierto().
func _actualizar_pasos(id: String, animado: bool) -> void:
	var pasos: Dictionary = datos(id).get("pasos", {})
	for nombre in pasos:
		var abierto := paso_abierto(nombre)
		if _estado_paso.get(nombre, null) == abierto:
			continue
		_estado_paso[nombre] = abierto
		var hoja: Node3D = _hojas.get(nombre, null)
		if hoja == null:
			continue
		var grados := float(pasos[nombre].get("abierta_grados", -90.0)) if abierto else 0.0
		if animado and is_inside_tree():
			var t := create_tween()
			t.tween_property(hoja, "rotation:y", deg_to_rad(grados), T_PUERTA).set_trans(Tween.TRANS_SINE)
			var son := get_node_or_null("/root/Sonido")     # (sin nombrar el autoload: la prueba carga esto sin él)
			if son != null:
				son.efecto("puerta_abre")
		else:
			hoja.rotation.y = deg_to_rad(grados)


# ================================================================= construir un interior (la primera vez que se entra)

func _construir_interior(id: String) -> void:
	_hechos[id] = true
	var raiz: Node3D = _nodos[id]
	var d := datos(id)
	var ruta := ruta_modelo(id)
	var escena: PackedScene = null
	if _pedidos.has(id):
		escena = ResourceLoader.load_threaded_get(ruta) as PackedScene
	elif ResourceLoader.exists(ruta):
		escena = load(ruta) as PackedScene
	_mats_sombra[id] = []
	if escena != null:
		var inst := escena.instantiate()
		inst.name = "Modelo"
		raiz.add_child(inst)
		_materiales(id, inst, d)
		for nombre in d.get("pasos", {}):
			var h := str(d["pasos"][nombre].get("hoja", ""))
			if h != "":
				var nodo := inst.find_child(h, true, false) as Node3D
				if nodo != null:
					_hojas[nombre] = nodo
	else:
		push_warning("Interiores: falta %s (fuente/crear_interiores.py): bloques provisionales" % ruta)
		_bloques(id, raiz, d)
	for c in d.get("choques", []):
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Choque"
		cuerpo.position = Vector3(float(c[0]), float(c[1]), float(c[2]))
		var col := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = Vector3(float(c[3]), float(c[4]), float(c[5]))
		col.shape = caja
		cuerpo.add_child(col)
		raiz.add_child(cuerpo)
		choques += 1
	_poner_sitios(id, raiz, d)


func _materiales(id: String, inst: Node, d: Dictionary) -> void:
	var ruta_luz := RAIZ + "modelos/int_%s_luz_1024.png" % id
	var tex_luz: Texture2D = load(ruta_luz) if ResourceLoader.exists(ruta_luz) and bool(d.get("horneado", false)) else null
	var escala := float(d.get("escala", 1.0)) * float(BRILLO.get(id, 1.0))
	var escala_v := float(d.get("escala_vertice", 1.0)) * float(BRILLO.get(id, 1.0))
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var vertice := String(m.name) != "fijo"
		for s in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(s)
			var nombre := orig.resource_name if orig != null else ""
			var clave := "%s|%s|%s|%s" % [id, nombre, vertice, tex_luz != null]
			if not _mats.has(clave):
				_mats[clave] = _material(nombre, vertice, tex_luz, escala_v if vertice else escala)
			var mat: Material = _mats[clave]
			m.set_surface_override_material(s, mat)
			if mat is ShaderMaterial and nombre != "brillo" and not (_mats_sombra[id] as Array).has(mat):
				(_mats_sombra[id] as Array).append(mat)


func _material(nombre: String, vertice: bool, tex_luz: Texture2D, escala: float) -> Material:
	var tex: Texture2D = null
	if TEXTURA_DE.has(nombre):
		var ruta: String = TEXTURAS + TEXTURA_DE[nombre] + ".png"
		if ResourceLoader.exists(ruta):
			tex = load(ruta)
	if nombre == "brillo":
		var b := ShaderMaterial.new()
		b.shader = load(SH_BRILLO)
		b.set_shader_parameter("energia", 1.35)
		b.set_shader_parameter("temblor", 0.16)
		return b
	if tex_luz == null and not vertice:                         # (sin hornear: luz en tiempo real, para ver la forma)
		var s := StandardMaterial3D.new()
		s.vertex_color_use_as_albedo = true
		s.albedo_texture = tex
		s.roughness = 1.0
		s.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		return s
	var m := ShaderMaterial.new()
	m.shader = load(SH_VERTICE if vertice else SH_ESTATICO)
	m.set_shader_parameter("textura", tex)
	m.set_shader_parameter("luz_escala", escala)
	if not vertice:
		m.set_shader_parameter("luz", tex_luz)
	# la sombra de Kael dentro: solo la mancha de contacto (aquí no hay sol que eche una sombra larga)
	m.set_shader_parameter("sombra_fuerza", 0.0)
	m.set_shader_parameter("contacto_fuerza", 0.72)
	m.set_shader_parameter("sol_kael", 0.0)
	m.set_shader_parameter("sombra_largo", 0.8)
	return m


# Los utensilios de sitio: la galga en la repisa de la vivienda (de utensilios.glb; si falta, una regla de madera).
func _poner_sitios(id: String, raiz: Node3D, d: Dictionary) -> void:
	var sitios: Dictionary = d.get("sitios", {})
	if sitios.is_empty():
		return
	var u: Node = null
	if ResourceLoader.exists(UTENSILIOS):
		u = (load(UTENSILIOS) as PackedScene).instantiate()
	for nombre in sitios:
		var s: Dictionary = sitios[nombre]
		var nodo: Node3D = null
		if u != null:
			var orig := u.find_child(nombre, true, false) as Node3D
			if orig != null:
				nodo = orig.duplicate() as Node3D
		if nodo == null:
			var mi := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.36, 0.02, 0.09)
			mi.mesh = b
			nodo = mi
		nodo.name = "sitio_" + nombre
		var p: Array = s["pos"]
		nodo.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(float(s.get("cabeceo", 0.0))),
			deg_to_rad(float(s.get("yaw", 0.0))), deg_to_rad(float(s.get("giro", 0.0))))),
			Vector3(float(p[0]), float(p[1]), float(p[2])))
		var luz := float(s.get("luz", 0.9))
		for mi in ([nodo] + nodo.find_children("*", "MeshInstance3D", true, false)):
			if mi is MeshInstance3D:
				var m := ShaderMaterial.new()
				m.shader = load(SH_VERTICE)
				var ruta_atlas := RAIZ + "modelos/utensilios_atlas.png"
				m.set_shader_parameter("textura", load(ruta_atlas) if ResourceLoader.exists(ruta_atlas) else null)
				m.set_shader_parameter("luz_escala", luz)
				m.set_shader_parameter("sombra_fuerza", 0.0)
				m.set_shader_parameter("contacto_fuerza", 0.0)
				(mi as MeshInstance3D).material_override = m
				(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(nodo)
		_sitios[nombre] = nodo
	if u != null:
		u.free()


# Si falta el GLB: el suelo y los bloqueos como cajas (para no quedarse a oscuras en una copia sin los modelos).
func _bloques(_id: String, raiz: Node3D, d: Dictionary) -> void:
	var t: Array = d.get("tam", [8, 8])
	var cajas: Array = [[0.0, -0.1, 0.0, float(t[0]), 0.1, float(t[1]), Color(0.55, 0.45, 0.35)]]
	for r in d.get("bloqueos", []):
		cajas.append([float(r[0]) + 0.25, 0.0, float(r[1]) + 0.25, float(r[2]) - 0.5, 0.9, float(r[3]) - 0.5,
			Color(0.7, 0.6, 0.45)])
	for c in cajas:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(maxf(0.05, c[3]), c[4] - c[1], maxf(0.05, c[5]))
		mi.mesh = b
		mi.position = Vector3(c[0] + c[3] * 0.5, (c[1] + c[4]) * 0.5, c[2] + c[5] * 0.5)
		var m := StandardMaterial3D.new()
		m.albedo_color = c[6]
		mi.material_override = m
		raiz.add_child(mi)
