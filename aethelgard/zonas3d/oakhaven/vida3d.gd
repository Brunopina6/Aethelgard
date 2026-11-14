extends Node3D
# Oakhaven 3D completo (V12, fase 2, migración región a región): los sistemas de la ciudad 2D (ciudad_oakhaven.gd) en la
# 3D, con los MISMOS datos (ciudades/oakhaven.gd: vecinos, misiones, cofres, secretos, piezas y notas) y la misma forma de
# guardarse (hitos, «mazmorras»["oakhaven"], «cofres_abiertos», «lore_visto», decisiones, inventario, gremio): una partida
# vale igual en la 2D y en la 3D.
#   - Vecinos: Aldric, Selene, Pip, Rosa, Albar, Bastián y Doña Encina, con sus diálogos de siempre (Oak.dialogo_de: lo de
#     una misión en curso primero; los demás se turnan) y su rutina por franja (oakhaven_vida.gd: mañana, tarde y
#     anochecer; la tarde, su sitio de siempre; los que pasean, de verdad). La posadera atiende dentro de la posada
#     (oakhaven_3d.gd: «Hablar» en su panel); Ferro, Hilda y Mirta, en el distrito de los oficios (distrito.gd).
#     Figuras PROVISIONALES (barrios.gd: mallas de Blender sin esqueleto, del estilo de Ferro, Hilda y Mirta).
#   - Las señales «oak:» de todos los diálogos de la ciudad (favores, faroles, el secreto de Pip, la lavanda, los
#     encargos…) con Oak.aplicar_senal, y sus avisos en cola al acabar el diálogo; se guarda.
#   - Los 4 cofres (mismos ids; el de los requisados espera a que Kael haya salido) con sus destellos, las piezas (el
#     barril, la torre y la ronda, los tres faroles, la grieta, las tres páginas de Mirta, el tablón del gremio y la mesa
#     de las parejas), las 5 notas (examinables_3d.gd), los dos detalles de canon (oak_sello, oak_tapiz), las dos vistas,
#     los hallazgos (la Rama Milenaria al pie del Árbol y las Gemelas de la Muralla tras el barril, hallazgos.gd), la
#     tienda (en el mercado), el gremio (gremio_menu.gd) con sus braseros, las parejas (taberna_parejas.gd) y el brillo
#     del brazalete cerca de la grieta y de los detalles sin ver.
# La región (oakhaven_3d.gd) pregunta piezas() (los puntos que ofrecen el botón), atiende(id) y accion(id), y ocupado().

const Oak := preload("res://ciudades/oakhaven.gd")
const Vida := preload("res://ciudades/oakhaven_vida.gd")
const Progreso := preload("res://progreso.gd")
const Hallazgos := preload("res://hallazgos.gd")
const Examinables := preload("res://zonas3d/examinables_3d.gd")
const Barrios := preload("res://zonas3d/oakhaven/barrios.gd")
const MundoVivo := preload("res://zonas3d/oakhaven/mundo_vivo.gd")   # V12, interruptor «mundo_vivo_v12» (APAGADO)
const Propuestas := preload("res://ciudades/oakhaven_propuestas.gd")  # V12, PROPUESTA apagada (el cantero)
const Cantero3D := preload("res://zonas3d/oakhaven/cantero3d.gd")
const NpcChibi := preload("res://personajes/npc_v12/npc_chibi.gd")
const VECINOS := ["aldric", "selene", "pip", "rosa", "albar", "bastian", "encina"]
# Sitios de la 3D que no son los de la 2D: Aldric, a un lado del arco (no tapa la Puerta del Sur), y Albar, por la mañana,
# entre las urnas (en la 2D, encima de una).
# Selene, a la puerta de la botica pero al lado del tenderete de Mirta del distrito (que en la 3D ocupa su casilla).
# Bastián, a un lado de la Calle Mayor (2 m de ancho): en medio, con su choque, cerraba el paso a quien anda recto.
const RUTINA_3D := {"aldric": {"tarde": Vector2(38.3, 49.5)}, "albar": {"manana": Vector2(60.4, 12.25)},
	"selene": {"manana": Vector2(37.6, 41.6), "tarde": Vector2(37.6, 41.6)},
	"bastian": {"tarde": Vector2(39.3, 43.0), "anochecer": Vector2(39.3, 34.0), "anochecer_hasta": Vector2(39.3, 47.0)}}
const SITIO_3D := {"oak_tapiz": Vector2(45.4, 21.9)}       # el tapiz del modelo del Concejo (en la 2D, 47, 22)
const ARBOL := Vector2(40.0, 9.6)                           # el pie del Árbol Milenario (el «altar» de la 2D)
const TIENDA := Vector2(54.0, 30.3)                         # delante de los puestos del mercado
const RADIO_NPC := 1.9
const RADIO_PIEZA := 1.5
const RADIO_COFRE := 1.4
const RADIO_BRAZALETE := 4.0
const ALTO_ALCANCE := 1.6                                   # diferencia de altura con la que aún se alcanza algo
const RAICES := Rect2(30, 2, 20, 11)

var region: Node3D                          # zonas3d/oakhaven_3d.gd
var barrios                                 # zonas3d/oakhaven/barrios.gd (o null)
var mat
var vecinos := {}                           # id → {"nodo", "veces", "paseo"}
var cofres := {}                            # id → {"nodo", "tapa", "abierto", "brillo"}
var notas: Array = []                       # [{"datos", "pos", "brillo"}] (examinables_3d.gd)
var paginas := {}                           # id de pieza → Node3D (la hoja, mientras toca recogerla)
var obras := {}                             # proyecto del gremio → nodos puestos
var avisos: Array = []                      # [texto, efecto, segundos] que esperan su turno
var franja := Vida.FRANJA_AL_LLEGAR
var franja_t := 0.0
var abierto: Node = null                    # el gremio, las parejas o la tienda abiertos
var cambios := false
var dialogo := ""                           # el diálogo de vecino abierto («» si ninguno)
var brillados := {}
var ultimo_aviso := ""                      # (para las pruebas)
var vista_raices_dada := false
var _t_voz := {}                            # vecino → s hasta que pueda volver a decir algo al pasar
var _mat_destello: StandardMaterial3D


static func crear(region_: Node3D, barrios_, mat_) -> Node3D:
	var v = load("res://zonas3d/oakhaven/vida3d.gd").new()
	v.name = "Vida"
	v.region = region_
	v.barrios = barrios_
	v.mat = mat_
	region_.add_child(v)
	v._montar()
	return v


func _montar() -> void:
	Oak.registrar_dialogic()                    # los personajes nuevos de Dialogic, por su ruta
	franja = str(Engine.get_meta("oak_franja", Vida.FRANJA_AL_LLEGAR))
	if not franja in Vida.FRANJAS:
		franja = Vida.FRANJA_AL_LLEGAR
	franja_t = float(Engine.get_meta("oak_franja_t", 0.0))
	for id in VECINOS:
		_crear_vecino(id)
	for d in Propuestas.npcs():                 # V12, PROPUESTA del cantero (apagada: ninguno)
		_crear_vecino(d["id"])
	_poner_cofres()
	_poner_arcon()
	_poner_notas()
	_poner_paginas()
	_poner_proyectos()
	_poner_cantero()
	actualizar()
	poner_franja(franja, false)
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.signal_event.connect(_al_senal)
		dg.timeline_ended.connect(_al_acabar_dialogo)
	vista_raices_dada = Progreso.estado(Oak.NOMBRE, "vista_raices")


func _exit_tree() -> void:
	Engine.set_meta("oak_franja_t", franja_t)
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		if dg.signal_event.is_connected(_al_senal):
			dg.signal_event.disconnect(_al_senal)
		if dg.timeline_ended.is_connected(_al_acabar_dialogo):
			dg.timeline_ended.disconnect(_al_acabar_dialogo)


# Una casilla de la 2D en la 3D, a la altura de su suelo («en_alto»: en la ronda).
static func sitio(c: Vector2, en_alto := false) -> Vector3:
	return Vector3(c.x, Barrios.ALTO_RONDA if en_alto else Barrios.altura(c.x, c.y), c.y)


static func _en_ronda(c: Vector2) -> bool:
	return Barrios.RONDA_ALTA.has_point(c)


# ================================================================= vecinos y rutinas

func _crear_vecino(id: String) -> void:
	var d := Oak.npc(id)
	var n := Node3D.new()
	n.name = "Vecino_" + id
	add_child(n)
	# V12, mundo vivo (interruptor «mundo_vivo_v12», APAGADO): la figura de la familia chibi, con su esqueleto y sus
	# clips, en vez de la provisional; el mismo sitio, diálogo y rutina. La anima mundo_vivo.gd.
	var chibi: Node3D = MundoVivo.figura_vecino(id)
	var propio := false
	if chibi == null and d.has("chibi") and NpcChibi.existe(d["chibi"][0]):   # (el aprendiz del cantero: siempre la suya)
		chibi = NpcChibi.crear(d["chibi"][0], d["chibi"][1])
		if not chibi.listo:
			chibi.free()
			chibi = null
		propio = chibi != null
	if chibi != null:
		n.add_child(chibi)
	else:
		var fig: MeshInstance3D = barrios.figura(id) if barrios != null else null
		if fig == null:
			fig = _figura_provisional(d)
		n.add_child(fig)
		var t := fig.create_tween().set_loops()                        # respira
		t.tween_property(fig, "position:y", 0.018, 1.5 + 0.13 * vecinos.size()).set_trans(Tween.TRANS_SINE)
		t.tween_property(fig, "position:y", 0.0, 1.5 + 0.13 * vecinos.size()).set_trans(Tween.TRANS_SINE)
	var cuerpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.32
	cil.height = 1.7
	col.shape = cil
	col.position.y = 0.85
	cuerpo.add_child(col)
	n.add_child(cuerpo)
	vecinos[id] = {"nodo": n, "veces": 0, "paseo": null, "datos": d, "chibi": chibi, "propio": propio}


# Sin el modelo: una cápsula con su color (como Aldric antes de V12).
func _figura_provisional(d: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.28
	c.height = 1.6
	mi.mesh = c
	mi.position.y = 0.8
	var m := StandardMaterial3D.new()
	m.albedo_color = d.get("tinte", Color(0.7, 0.7, 0.75))
	mi.material_override = m
	return mi


# La franja: cada vecino a su sitio de esa hora (y su paseo, si le toca), lo que suena y se recuerda en la sesión (la misma
# clave que la ciudad 2D, «oak_franja»).
func poner_franja(f: String, _animar: bool) -> void:
	if not f in Vida.FRANJAS:
		f = Vida.FRANJA_AL_LLEGAR
	franja = f
	Engine.set_meta("oak_franja", f)
	var son = get_node_or_null("/root/Sonido")
	if son != null and region != null:
		son.fijar_momento(region, Vida.MOMENTO_SONIDO[f])
	if region != null:
		region.set("franja", f)
	for id in vecinos:
		_a_su_sitio(id)


func rutina_3d(id: String, f: String) -> Dictionary:
	var r: Dictionary = Vida.rutina(id, f).duplicate()
	if r.is_empty():
		var d := Oak.npc(id)
		return {"casilla": d.get("casilla", Vector2(40, 30)), "hace": d.get("hace", "quieto")}
	var otro: Dictionary = RUTINA_3D.get(id, {})
	if otro.has(f):
		r["casilla"] = otro[f]
	if otro.has(f + "_hasta"):
		r["hasta"] = otro[f + "_hasta"]
	return r


func _a_su_sitio(id: String) -> void:
	var v: Dictionary = vecinos[id]
	var n: Node3D = v["nodo"]
	if v["paseo"] != null and (v["paseo"] as Tween).is_valid():
		(v["paseo"] as Tween).kill()
	v["paseo"] = null
	var r := rutina_3d(id, franja)
	n.position = sitio(r["casilla"])
	n.rotation.y = 0.0
	var chibi = v.get("chibi")                                    # V12, mundo vivo: la figura con clips (o null)
	if chibi != null:
		chibi.clip("tarea" if r.get("hace", "") == "trabaja" else "reposo")
	if r.get("hace", "") == "pasea" and r.has("hasta"):
		var a := n.position
		var b := sitio(r["hasta"])
		var dur := a.distance_to(b) / 1.1
		var t := n.create_tween().set_loops()
		t.tween_callback(func(): n.rotation.y = atan2(b.x - a.x, b.z - a.z))
		if chibi != null:                                         # anda de verdad (y vuelve a andar tras un diálogo)
			t.tween_method(func(k: float): n.position = a.lerp(b, k); chibi.andar(1.1), 0.0, 1.0, dur)
			t.tween_callback(func(): chibi.clip("reposo"))
		else:
			t.tween_property(n, "position", b, dur).set_trans(Tween.TRANS_SINE)
		t.tween_interval(2.0)
		t.tween_callback(func(): n.rotation.y = atan2(a.x - b.x, a.z - b.z))
		if chibi != null:
			t.tween_method(func(k: float): n.position = b.lerp(a, k); chibi.andar(1.1), 0.0, 1.0, dur)
			t.tween_callback(func(): chibi.clip("reposo"))
		else:
			t.tween_property(n, "position", a, dur).set_trans(Tween.TRANS_SINE)
		t.tween_interval(2.0)
		v["paseo"] = t


# Los vecinos cerca de «p» que pueden decir algo al pasar (para las voces de la región): [id, posición].
func vecinos_cerca(p: Vector3, radio: float) -> Array:
	var r: Array = []
	for id in vecinos:
		var q: Vector3 = (vecinos[id]["nodo"] as Node3D).global_position
		if Vector2(p.x - q.x, p.z - q.z).length() < radio and absf(p.y - q.y) < 2.0 and _t_voz.get(id, 0.0) <= 0.0:
			r.append([id, q])
	return r


func callar(id: String, segundos: float) -> void:
	_t_voz[id] = segundos


# ================================================================= cofres

func _poner_cofres() -> void:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	for c in Oak.COFRES:
		var id: String = c["id"]
		var hecho := _nodo_cofre(c["casilla"], "Cofre_" + id)
		var n: Node3D = hecho[0]
		var tapa: Node3D = hecho[1]
		var abierto_ya := abiertos.has(id)
		if abierto_ya:
			tapa.rotation.x = -1.9
		var brillo: Node3D = null
		var tipo: String = _secreto(c.get("secreto", "")).get("tipo", "")
		if not abierto_ya and tipo in ["cofre escondido", "cofre a la vista"]:
			brillo = _destello(n, Vector3(0, 0.75, 0), 1.6 if c.has("brilla_desde") else 1.0)
		cofres[id] = {"nodo": n, "tapa": tapa, "abierto": abierto_ya, "brillo": brillo, "pos": n.position}


# Un cofre con su tapa (la plantilla de los barrios o, sin ella, una caja), su choque y su bloqueo: [nodo, tapa].
func _nodo_cofre(cas: Vector2, nombre: String) -> Array:
	var alto := _en_ronda(cas)
	var n := Node3D.new()
	n.name = nombre
	n.position = sitio(cas, alto)
	add_child(n)
	var base: MeshInstance3D = barrios.plantilla("plantilla_cofre_base") if barrios != null else null
	var tapa := Node3D.new()
	tapa.name = "Tapa"
	tapa.position = Vector3(0, 0.36, -0.24)
	n.add_child(tapa)
	if base != null:
		n.add_child(base)
		var mt: MeshInstance3D = barrios.plantilla("plantilla_cofre_tapa")
		if mt != null:
			tapa.add_child(mt)
	else:
		var bm := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.76, 0.5, 0.48)
		bm.mesh = caja
		bm.position.y = 0.25
		n.add_child(bm)
	var cuerpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.8, 0.6, 0.52)
	col.shape = forma
	col.position.y = 0.3
	cuerpo.add_child(col)
	n.add_child(cuerpo)
	if not alto and barrios != null and barrios.ciudad != null:
		barrios.ciudad.bloqueos.append(Rect2(cas.x - 0.4, cas.y - 0.26, 0.8, 0.52))
	return [n, tapa]


# V12, fase 7: el arcón del Concejo (Oak.CERRADURA): un cofre como los demás con un aro de runas dorado en la tapa. Su
# botón es el de la pieza oak_cerradura_runica («Girar los anillos»; abierta, «Examinar»).
var arcon := {}                             # {"nodo", "tapa"} (o vacío si no hay pieza)
func _poner_arcon() -> void:
	var p := Oak.pieza(Oak.CERRADURA["id"])
	if p.is_empty():
		return
	var hecho := _nodo_cofre(p["casilla"], "Arcon_cerradura")
	arcon = {"nodo": hecho[0], "tapa": hecho[1]}
	var aro := MeshInstance3D.new()
	aro.name = "Aro_runas"
	var toro := TorusMesh.new()
	toro.inner_radius = 0.13
	toro.outer_radius = 0.19
	toro.rings = 16
	toro.ring_segments = 6
	aro.mesh = toro
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("E8C46A")
	m.metallic = 0.7
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = Color("E8C46A")
	m.emission_energy_multiplier = 0.35
	aro.material_override = m
	aro.rotation.x = PI / 2.0                               # de cara, en el frente del arcón
	aro.position = Vector3(0, 0.3, 0.27)
	(hecho[0] as Node3D).add_child(aro)
	if Oak.cerradura_abierta():
		(hecho[1] as Node3D).rotation.x = -1.9
	# V12 (PROPUESTA apagada, ciudades/oakhaven_propuestas.gd): la losa del cantero, plana en el suelo, con su aro.
	var losa := Oak.pieza("oak_losa_cantero")
	if not losa.is_empty():
		var n := Node3D.new()
		n.name = "Losa_cantero"
		n.position = sitio(losa["casilla"])
		add_child(n)
		var piedra := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(1.1, 0.08, 1.1)
		piedra.mesh = caja
		piedra.position.y = 0.04
		var mp := StandardMaterial3D.new()
		mp.albedo_color = Color(0.55, 0.53, 0.5)
		mp.roughness = 0.95
		piedra.material_override = mp
		n.add_child(piedra)
		var aro2 := aro.duplicate() as MeshInstance3D
		aro2.rotation = Vector3.ZERO
		aro2.position = Vector3(0, 0.09, 0)
		aro2.scale = Vector3.ONE * 1.8
		piedra.add_child(aro2)
		aro2.position = Vector3(0, 0.05, 0)
		piedra.name = "Piedra"
		var hueco := MeshInstance3D.new()                       # lo que deja al apartarse: un hueco oscuro
		hueco.name = "Hueco"
		var hq := QuadMesh.new()
		hq.size = Vector2(0.9, 0.9)
		hq.orientation = PlaneMesh.FACE_Y
		hueco.mesh = hq
		hueco.position.y = 0.012
		var mh := StandardMaterial3D.new()
		mh.albedo_color = Color(0.05, 0.045, 0.04)
		mh.roughness = 1.0
		hueco.material_override = mh
		n.add_child(hueco)
		arcon["losa"] = n
		arcon["losa_piedra"] = piedra
		if Oak.cerradura_abierta("oak_losa_cantero"):
			_losa_apartada(false)


# La losa del cantero, abierta: la piedra se aparta a un lado y deja ver el hueco («animar»: con un tween).
func _losa_apartada(animar: bool) -> void:
	var piedra: Node3D = arcon.get("losa_piedra")
	if piedra == null or not is_instance_valid(piedra):
		return
	var fin := Vector3(0.78, 0.0, 0.22)
	if not animar:
		piedra.position = fin
		piedra.rotation.y = 0.35
		return
	_sonido("puerta_abre")
	var t := piedra.create_tween().set_parallel()
	t.tween_property(piedra, "position", fin, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(piedra, "rotation:y", 0.35, 0.9).set_trans(Tween.TRANS_SINE)


# V12, PROPUESTA del cantero (apagada: nada): las tres marcas con su placa y el sillar delante del aprendiz.
var marcas_cantero := {}                    # id de pieza → Node3D
func _poner_cantero() -> void:
	var mp: Material = mat.sillar() if mat != null and mat.has_method("sillar") else null
	for p in Propuestas.piezas():
		var n := Cantero3D.poner_marca(self, p["id"], func(x: float, z: float): return Barrios.altura(x, z), mp)
		if n != null:
			marcas_cantero[p["id"]] = n
	if vecinos.has("cantero"):
		var s := Cantero3D.sillar(mp)
		var c: Vector2 = Oak.npc("cantero")["casilla"]
		s.position = sitio(c + Vector2(0.15, 0.62))
		add_child(s)


func abrir_cerradura(id: String = Oak.CERRADURA["id"]) -> void:
	if ocupado() or Oak.config_cerradura(id).is_empty() or Oak.cerradura_abierta(id):
		return
	_sonido("examinar")
	Oak.ver_cerradura(id)
	var m = load("res://cerradura_runica.gd").new()
	m.config = Oak.config_cerradura(id)
	m.al_resolver = Oak.abrir_cerradura.bind(id)
	abierto = m
	m.resuelta.connect(func():
		if id == Oak.CERRADURA["id"] and not arcon.is_empty() and is_instance_valid(arcon["tapa"]):
			var t := (arcon["tapa"] as Node3D).create_tween()
			t.tween_property(arcon["tapa"], "rotation:x", -1.9, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif id == "oak_losa_cantero":
			_losa_apartada(true))
	m.cerrado.connect(func():
		abierto = null
		guardar())
	region.add_child(m)


func _abrir_cofre(id: String) -> void:
	var c: Dictionary = cofres[id]
	var r := Oak.abrir_cofre(id)
	if r.has("bloqueado"):
		_sonido("cerrada")
		avisar(r["bloqueado"], "", true)
		return
	c["abierto"] = true
	var t := (c["tapa"] as Node3D).create_tween()
	t.tween_property(c["tapa"], "rotation:x", -1.9, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if c["brillo"] != null and is_instance_valid(c["brillo"]):
		(c["brillo"] as Node).queue_free()
	c["brillo"] = null
	if r.is_empty():
		return
	_sonido("cofre")
	_sonido("tesoro", {"retraso": 0.3})
	avisar(r["texto"], "", true)
	if r.get("nota", "") != "":
		avisar("Nueva nota en el Diario: «%s»" % Oak.nota(r["nota"])["nombre"], "pagina")
	guardar()


# ================================================================= notas, páginas y proyectos del gremio

func _poner_notas() -> void:
	var leidas: Dictionary = Engine.get_meta("lore_visto", {}) if Engine.get_meta("lore_visto", {}) is Dictionary else {}
	for nd in Oak.NOTAS:
		if not nd.has("casilla"):                          # (la de los requisados sale del cofre)
			continue
		var p := sitio(nd["casilla"])
		var e := {"datos": nd, "pos": p, "brillo": null}
		if not Progreso.visto(nd["id"]) and not leidas.has(nd["id"]):
			e["brillo"] = _destello(self, p + Vector3(0, 1.3, 0), 0.55)
		notas.append(e)


func _poner_paginas() -> void:
	for p in Oak.PIEZAS:
		if not String(p["id"]).begins_with("oak_pagina_"):
			continue
		var n := Node3D.new()
		n.name = "Pagina_" + p["id"]
		n.position = sitio(p["casilla"]) + Vector3(0, 0.03, 0)
		add_child(n)
		var q := QuadMesh.new()
		q.size = Vector2(0.24, 0.32)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.rotation = Vector3(-PI * 0.5, randf() * TAU, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.93, 0.89, 0.78)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		_destello(n, Vector3(0, 0.45, 0), 0.5)
		paginas[p["id"]] = n


# Los proyectos de reconstrucción pagados en el tablón (gremio.gd): hoy, los dos braseros de la plaza.
func _poner_proyectos() -> void:
	var Gremio = load("res://gremio.gd")
	for p in Gremio.PROYECTOS:
		if obras.has(p["id"]) or not Gremio.proyecto_hecho(p["id"]):
			continue
		var nodos: Array = []
		if p["id"] == "pr_braseros":
			for c in p["casillas"]:
				var n := Node3D.new()
				n.name = "Brasero"
				n.position = sitio(c)
				add_child(n)
				var b: MeshInstance3D = barrios.plantilla("plantilla_brasero") if barrios != null else null
				if b != null:
					n.add_child(b)
				var q := QuadMesh.new()
				q.size = Vector2(0.4, 0.6)
				var ll := MeshInstance3D.new()
				ll.mesh = q
				ll.material_override = mat.llama(c.x, 1.0) if mat != null else null
				ll.position = Vector3(0, 1.1, 0)
				ll.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				n.add_child(ll)
				nodos.append(n)
		obras[p["id"]] = nodos


# Lo que cambia con la partida: los faroles de la ronda, las páginas que hay que recoger.
func actualizar() -> void:
	if barrios != null:
		for i in [1, 2, 3]:
			barrios.encender("farol_%d" % i, Progreso.estado(Oak.NOMBRE, "farol_%d" % i))
	for id in paginas:
		var p := Oak.pieza(id)
		(paginas[id] as Node3D).visible = Oak.cumple(p["si"])


# ================================================================= lo que ofrece el botón

# [id, posición, radio, texto] (el formato de oakhaven_3d.gd, _piezas_al_alcance).
func piezas() -> Array:
	var r: Array = []
	for id in vecinos:
		var d: Dictionary = vecinos[id]["datos"]
		r.append([id, (vecinos[id]["nodo"] as Node3D).position, RADIO_NPC, "Hablar con " + d.get("corto", id)])
	for id in cofres:
		if not cofres[id]["abierto"]:
			r.append(["cofre:" + id, cofres[id]["pos"], RADIO_COFRE, "Abrir cofre"])
	for p in Oak.piezas_activas():                         # (V12: con la propuesta encendida, también sus piezas)
		var id: String = p["id"]
		if id.begins_with("oak_farol_") and Progreso.estado(Oak.NOMBRE, id.trim_prefix("oak_")):
			continue                                        # (encendido: ya no se usa, como en la 2D)
		if id.begins_with("oak_pagina_") and not Oak.cumple(p["si"]):
			continue                                        # (la hoja solo está mientras toca recogerla)
		var cas: Vector2 = p["casilla"]
		var texto: String = p["accion"] if Oak.cumple(p["si"]) else "Examinar"
		r.append(["pieza:" + id, sitio(cas, _en_ronda(cas)), RADIO_PIEZA, texto])
	for n in notas:
		r.append(["nota:" + n["datos"]["id"], n["pos"], RADIO_PIEZA, "Examinar"])
	for d in Progreso.detalles_de(Oak.INDICE):
		var c: Vector2 = SITIO_3D.get(d["id"], Oak.SITIOS_DETALLE.get(d["id"], Oak.PLAZA + Vector2(3, -2)))
		r.append(["detalle:" + d["id"], sitio(c), RADIO_PIEZA, "Examinar"])
	r.append(["arbol", sitio(ARBOL), 1.8, "Examinar el Árbol"])
	r.append(["tienda", sitio(TIENDA), 1.8, "Comprar en el mercado"])
	return r


func atiende(id: String) -> bool:
	return vecinos.has(id) or id in ["arbol", "tienda"] or id.begins_with("cofre:") or id.begins_with("pieza:") \
		or id.begins_with("nota:") or id.begins_with("detalle:")


func ocupado() -> bool:
	return abierto != null and is_instance_valid(abierto)


func accion(id: String) -> void:
	if vecinos.has(id):
		hablar(id)
	elif id.begins_with("cofre:"):
		_abrir_cofre(id.trim_prefix("cofre:"))
	elif id.begins_with("pieza:"):
		usar_pieza(id.trim_prefix("pieza:"))
	elif id.begins_with("nota:"):
		for n in notas:
			if n["datos"]["id"] == id.trim_prefix("nota:"):
				Examinables.leer_nota(region, n)
				ultimo_aviso = n["datos"]["texto"]
	elif id.begins_with("detalle:"):
		_examinar_detalle(id.trim_prefix("detalle:"))
	elif id == "arbol":
		_sonido("examinar")
		avisar(Oak.TEXTO_ARBOL, "", true)
		Examinables.hallazgo_al_examinar(region, Oak.INDICE, "altar", 3.6)   # la Rama Milenaria (hallazgos.gd)
	elif id == "tienda":
		abrir_tienda()


# ================================================================= hablar

# El diálogo que toca con este vecino (Oak.dialogo_de, como la 2D: lo de una misión en curso primero; si no, se turnan).
func hablar(id: String) -> String:
	var v: Dictionary = vecinos[id]
	var dg = get_node_or_null("/root/Dialogic")
	var ruta := Oak.dialogo_de(id, int(v["veces"]))
	var n: Node3D = v["nodo"]
	var k: Node3D = region.get("kael")
	if k != null:
		n.rotation.y = atan2(k.global_position.x - n.global_position.x, k.global_position.z - n.global_position.z)
	if v.get("chibi") != null:                                    # V12, mundo vivo: su gesto al hablar
		v["chibi"].clip("hablar", "reposo")
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		var frases: Array = v["datos"].get("frases", [""])
		avisar("%s: «%s»" % [v["datos"].get("corto", id), frases[int(v["veces"]) % frases.size()]], "", true)
		v["veces"] = int(v["veces"]) + 1
		return ""
	v["veces"] = int(v["veces"]) + 1
	if region.has_method("_parar_kael"):
		region._parar_kael()
	if v["paseo"] != null:
		(v["paseo"] as Tween).pause()
	dialogo = ruta
	region.set("dialogo_actual", ruta)
	dg.start(ruta)
	return ruta


# La posadera (dentro de la posada, «Hablar» en su panel: oakhaven_3d.gd).
func hablar_posadera(veces: int) -> String:
	var dg = get_node_or_null("/root/Dialogic")
	var ruta := Oak.dialogo_de("posadera", veces)
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		return ""
	dialogo = ruta
	region.set("dialogo_actual", ruta)
	dg.start(ruta)
	return ruta


# Las señales «oak:» de los diálogos de la ciudad (como ciudad_oakhaven.gd, _al_senal). Las de los oficios del distrito
# las atiende distrito.gd mientras su encargado habla (no se aplican dos veces).
func _al_senal(arg) -> void:
	var s := str(arg)
	if not s.begins_with("oak:"):
		return
	var dist = region.get("distrito")
	if dist != null and str(dist.get("_atendiendo")) != "":
		return
	if s.begins_with("oak:servicio_") or s in ["oak:rumor", "oak:dormir"]:
		return
	cambios = true
	var t := Oak.aplicar_senal(s)
	actualizar()
	if t != "":
		avisar(t, _efecto_de(s))


func _al_acabar_dialogo() -> void:
	dialogo = ""
	for id in vecinos:
		var p = vecinos[id]["paseo"]
		if p != null and (p as Tween).is_valid():
			(p as Tween).play()
	if cambios:
		cambios = false
		guardar()


static func _efecto_de(s: String) -> String:
	if s in ["oak:pip_pagar", "oak:sopa"]:
		return "monedas"
	if s.begins_with("oak:farol_"):
		return "farol"
	if s.ends_with("_aceptados") or s == "oak:lavanda_pedida":
		return "pagina"
	if s.ends_with("_hechos") or s == "oak:lavanda_entregada":
		return "tesoro"
	return "ui_confirmar"


# ================================================================= piezas

func usar_pieza(id: String) -> void:
	var p := Oak.pieza(id)
	if p.is_empty():
		return
	if id == "oak_tablon_gremio":
		abrir_gremio()
		return
	if id == "oak_mesa_parejas":
		abrir_parejas()
		return
	if not Oak.config_cerradura(id).is_empty() and Oak.cumple(p["si"]):   # V12, fase 7: una cerradura rúnica
		abrir_cerradura(id)
		return
	if not Oak.cumple(p["si"]):
		if str(p["texto_sin"]) != "":
			avisar(p["texto_sin"], "examinar", true)
		var libre := 3.6 if str(p["texto_sin"]) != "" else 0.0
		Examinables.hallazgo_al_examinar(region, Oak.INDICE, "pieza:" + id, libre)   # (las Gemelas, tras el barril)
		return
	var primera_vista: bool = id == "oak_torre" and not Progreso.estado(Oak.NOMBRE, "vista_torre")
	var aviso_senal := Oak.aplicar_senal(p["senal"]) if str(p["senal"]) != "" else ""
	var texto: String = p["texto"]
	if p.has("lleva_a"):
		var a: Vector2 = p["lleva_a"]
		var k: Node3D = region.get("kael")
		if id == "oak_grieta" and k != null and k.global_position.z > (p["casilla"] as Vector2).y:
			a = (p["casilla"] as Vector2) * 2.0 - p["lleva_a"]    # la grieta se pasa en los dos sentidos
			texto = ""
		var destino := sitio(a, _en_ronda(a))
		if id == "oak_torre" or id == "oak_ronda_bajar":
			_sonido("puerta_abre")
		viajar(destino)
	if texto != "" and aviso_senal != "" and texto.length() + aviso_senal.length() < 90:
		texto += " " + aviso_senal
		aviso_senal = ""
	avisar(texto, "" if p.has("lleva_a") else "examinar", true)
	if primera_vista:
		avisar(_texto_vista("oak_vista_torre"))
		_sonido("campana", {"retraso": 0.8})
	avisar(aviso_senal, _efecto_de(p["senal"]))
	if id.begins_with("oak_pagina_") and paginas.has(id):
		(paginas[id] as Node3D).visible = false
	actualizar()
	if aviso_senal != "" or primera_vista or str(p["senal"]) != "":
		guardar()


# Con un fundido, como el ascensor de la Garganta: subir a la ronda, bajar o pasar la grieta. El grupo, detrás.
func viajar(destino: Vector3) -> void:
	if region.has_method("_fundir"):
		await region._fundir(func():
			region._colocar_kael(destino)
			var g = region.get("grupo")
			if g != null:
				g.colocar(Vector3.BACK))
	else:
		region._colocar_kael(destino)


func _texto_vista(id: String) -> String:
	var s := _secreto(id)
	if s.has("texto_pv07") and Progreso.hito("pv_07"):
		return s["texto_pv07"]
	return s.get("texto", "")


static func _secreto(id: String) -> Dictionary:
	for s in Oak.SECRETOS:
		if s["id"] == id:
			return s
	return {}


# Los detalles de canon de la ciudad (progreso.gd): el texto, la página del Diario si toca y el hallazgo si lo hay.
func _examinar_detalle(id: String) -> void:
	for d in Progreso.detalles_de(Oak.INDICE):
		if d["id"] != id:
			continue
		avisar(d["texto"], "examinar", true)
		var acto: Dictionary = Progreso.ver_detalle(id)
		var libre := 3.6
		if not acto.is_empty():
			libre = 8.2
			get_tree().create_timer(4.0).timeout.connect(_pagina_nueva.bind(str(acto["escena"])))
		Examinables.hallazgo_al_examinar(region, Oak.INDICE, "detalle:" + id, libre)
		guardar()


# (Un método, no una lambda: si se sale de la escena antes, la conexión se va con el nodo.)
func _pagina_nueva(escena: String) -> void:
	_sonido("pagina")
	_sonido("misterio", {"retraso": 0.2})
	region._mostrar_aviso("Nueva página en el Diario: «%s»" % escena, 3.0)


# ================================================================= el gremio, las parejas y la tienda

func abrir_gremio() -> void:
	if ocupado():
		return
	_sonido("examinar")
	var m = load("res://gremio_menu.gd").new()
	abierto = m
	m.proyecto_hecho.connect(func(_id): _poner_proyectos())
	m.cerrado.connect(func():
		abierto = null
		guardar())
	region.add_child(m)


func abrir_parejas() -> void:
	if ocupado():
		return
	var m = load("res://taberna_parejas.gd").new()
	abierto = m
	m.cerrado.connect(func():
		abierto = null
		guardar())
	region.add_child(m)


func abrir_tienda() -> void:
	if ocupado():
		return
	var capa := CanvasLayer.new()
	capa.layer = 60
	region.add_child(capa)
	var t = load("res://tienda.gd").new()
	t.pestana = "Objetos"
	abierto = capa
	t.cerrado.connect(func():
		abierto = null
		capa.queue_free()
		guardar())
	capa.add_child(t)


# ================================================================= avisos, brazalete, vistas y la hora

# Los avisos de la ciudad, de uno en uno: «ya» lo enseña ahora; si no, espera al de antes y a que acabe el diálogo.
func avisar(texto: String, efecto := "", ya := false, segundos := 2.8) -> void:
	if texto == "":
		return
	ultimo_aviso = texto
	if ya:
		if efecto != "":
			_sonido(efecto)
		region._mostrar_aviso(texto, segundos)
	else:
		avisos.append([texto, efecto, segundos])


func _process(delta: float) -> void:
	if region != null and region.get("vivo") == null:            # (con el mundo vivo, los anima él: mundo_vivo.gd)
		for id in vecinos:
			if vecinos[id].get("propio", false):
				vecinos[id]["chibi"].avanzar(delta)
	for k in _t_voz.keys():
		_t_voz[k] -= delta
	var dg = get_node_or_null("/root/Dialogic")
	var en_dialogo: bool = dg != null and dg.current_timeline != null
	if not avisos.is_empty() and not en_dialogo:
		var tw = region.get("_tween_aviso")
		if tw == null or not (tw as Tween).is_valid() or not (tw as Tween).is_running():
			var a: Array = avisos.pop_front()
			avisar(a[0], a[1], true, a[2])
	var k: Node3D = region.get("kael")
	if k == null or region.get("en_posada") or en_dialogo or region.get("cambiando"):
		return
	_brazalete(k.global_position)
	if not vista_raices_dada and RAICES.has_point(Vector2(k.global_position.x, k.global_position.z)):
		vista_raices_dada = true
		if not Progreso.estado(Oak.NOMBRE, "vista_raices"):
			Oak.aplicar_senal("oak:vista_raices")             # la primera vez que se llega a las raíces
			avisar(_texto_vista("oak_vista_raices"), "", true, 3.4)
			guardar()
	if region.call("ocupado"):
		return
	franja_t += delta
	var siguiente := Vida.franja_siguiente(franja)
	if franja_t >= Vida.DURACION_FRANJA and siguiente != franja:
		franja_t = 0.0
		poner_franja(siguiente, true)


# El brillo del brazalete (zona.gd, _brazalete): cerca de un detalle sin ver, o de la grieta mientras no se ha pasado.
func _brazalete(p: Vector3) -> void:
	var cosas: Array = []
	for d in Progreso.detalles_de(Oak.INDICE):
		if not Progreso.visto(d["id"]):
			cosas.append([d["id"], sitio(SITIO_3D.get(d["id"], Oak.SITIOS_DETALLE.get(d["id"], Oak.PLAZA)))])
	if not Progreso.estado(Oak.NOMBRE, "grieta"):
		cosas.append(["grieta", sitio(_secreto("oak_secreto_velas")["casilla"])])
	if Propuestas.cumple("cond:cantero_empieza"):              # V12, PROPUESTA: las marcas del cantero que faltan
		for pz in Propuestas.piezas():
			var sen := str(pz["senal"]).trim_prefix("oak:")
			if sen.begins_with("cantero_marca_") and not Progreso.estado(Oak.NOMBRE, sen):
				cosas.append([pz["id"], sitio(pz["casilla"])])
	for c in cosas:
		var q: Vector3 = c[1]
		var dist := Vector2(p.x - q.x, p.z - q.z).length()
		if dist > RADIO_BRAZALETE * 1.6 or absf(p.y - q.y) > 2.5:
			brillados.erase(c[0])
		elif dist < RADIO_BRAZALETE and not brillados.has(c[0]):
			brillados[c[0]] = true
			_brillo_brazalete()


func _brillo_brazalete() -> void:
	_sonido("brazalete")
	var k: Node3D = region.get("kael")
	if k == null or mat == null:
		return
	var b := _destello(k, Vector3(-0.28, 1.0, 0.12), 0.05)
	b.name = "BrilloBrazalete"
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector3.ONE * 0.35, 0.25)
	t.tween_property(b, "scale", Vector3.ONE * 0.02, 0.6)
	t.tween_callback(b.queue_free)


# Un destello que mira a la cámara y late (cofres escondidos, notas sin leer, las páginas).
func _destello(padre: Node3D, pos: Vector3, tam: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.name = "Destello"
	if mat != null:
		if _mat_destello == null:                              # (uno para todos: no abre un lote por destello)
			_mat_destello = (mat.halo_aire(Color(1.0, 0.85, 0.45)) as StandardMaterial3D).duplicate()
			_mat_destello.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mi.material_override = _mat_destello
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	padre.add_child(mi)
	var t := mi.create_tween().set_loops()
	t.tween_property(mi, "scale", Vector3.ONE * 0.7, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(mi, "scale", Vector3.ONE, 1.1).set_trans(Tween.TRANS_SINE)
	return mi


func guardar() -> void:
	if Engine.has_meta("banco_proto") or region == null:
		return
	region.guardar_posicion()
	Progreso.guardar(region.scene_file_path)


func _sonido(clave: String, opciones := {}) -> void:
	var s = get_node_or_null("/root/Sonido")
	if s != null:
		s.efecto(clave, opciones)
