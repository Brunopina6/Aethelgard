extends "res://prototipos/vista3d.gd"
# Sunken City en 3D, primer sector jugable «Popa Rota → Cubierta Mayor» (lugar 5 del mapa; V12, 15/11).
# EN PRUEBAS, APAGADO: solo con el argumento «sunken3d» o elegido en Ajustes («Sunken City: 3D (en pruebas)», solo en
# Auditoría o en el editor; [regiones] sunken3d en user://ajustes.cfg; modo3d.gd, EN_PRUEBAS). Sin eso, el mapa lleva a
# la zona 2D de siempre (zona.tscn con el lugar 5), que no se toca.
# «La ciudad en las costillas» (docs/diseno/ciudades_y_lugares.md §2.2, PROPUESTA): una ciudad dentro del esqueleto de un
# barco de guerra varado en una laguna salada, a la hora fija de la tarde dorada. El sector:
#   - el muelle de llegada (y la salida al mapa) → la brecha del espejo de popa (el nombre del barco, raspado) → la
#     cubierta de popa → la Quilla, una pasarela bajo tres costillas en arco con sus faroles (menos uno) y casas colgadas
#     a los lados → la rampa → la Cubierta Mayor: el tocón del palo mayor con la bandera del Águila, la capitana Brea, el
#     puesto del mercado (la tienda del lugar 5, con la Moneda del Águila), la escotilla atrancada y, al norte, la proa en
#     obras y el mascarón del águila dorada;
#   - dos desvíos: el Archivo del Águila (la contramaestre Ulla y el detalle «sunken_contratos») y el balcón de estribor,
#     que mira al dique de la lona.
# La misión, el secreto, los vecinos y los comentarios: ciudades/sunken.gd (todo PROPUESTA). El trazado (por dónde se anda,
# alturas, cámara): zonas3d/sunken/trazado.gd. El escenario de Blender, la laguna y los faroles: zonas3d/sunken/casco.gd.
# Contrato de región (como Oakhaven y Ciclópea 3D): guardado al entrar, tras cada cosa que cambia la partida y al pausar
# (guardar_posicion), Dialogic, grupo detrás de Kael, salida al mapa, sin encuentros (es una ciudad: Engine «zona» =
# «ciudad») y partidas antiguas (posicion_desde_2d, modo3d.escena_equivalente: la 2D no se corresponde con este trazado,
# así que una partida de la 2D entra por el muelle y una de aquí, con la región apagada, por la entrada de la 2D).

const T := preload("res://zonas3d/sunken/trazado.gd")
const Casco := preload("res://zonas3d/sunken/casco.gd")
const Sunk := preload("res://ciudades/sunken.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const Ex := preload("res://zonas3d/examinables_3d.gd")
const Progreso := preload("res://progreso.gd")
const Comentarios := preload("res://dialogos/comentarios.gd")
const NpcChibi := preload("res://personajes/npc_v12/npc_chibi.gd")

const INDICE := 5                          # lugar del mapa (mapa.gd, LUGARES[5]; modo3d.SUNKEN)
const CLAVE := "sunken3d"                  # modo3d.gd, EN_PRUEBAS: el argumento y la clave de Ajustes
const ZONA := "ciudad"                     # mapa.gd, ZONA_LUGAR[5] (y sin encuentros: NIVEL_ZONA["ciudad"] = 0)
const INICIO := Vector3(40.0, 0.0, 57.8)   # trazado.gd, INICIO
const RADIO_BRAZALETE := 4.0
const LLEGADA_Z := 52.6                    # al cruzar la brecha de la popa: el comentario de la llegada

var brillo_sin_sombras := 1.15              # vista3d.gd: el bajo sin sombras (a ojo en el PC, como Oakhaven)
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var mat: Materiales
var casco                                  # zonas3d/sunken/casco.gd
var sol: DirectionalLight3D
var grupo: Node3D
var capa_ui: CanvasLayer
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var cerca := ""
var saliendo := false
var _bloqueo := 0.0
var _t := 0.0
var _t_brazalete := 0.0
var salida := {"armada": false}
var _dist_jugador := 15.0
var _dist_puesta := 15.0
var vecinos := {}                          # id → {"nodo", "chibi", "veces"}
var abierto: Node = null                   # la tienda abierta
var dialogo_actual := ""
var cambios := false                       # una señal del diálogo cambió la partida: se guarda al acabar
var avisos_cola: Array = []                # [texto, segundos] que esperan a que acabe el diálogo
var ultimo_aviso := ""                     # (para las pruebas)
var brillados := {}
var _comentario := ""
var _comentario_t := 0.0
var llegada_dicha := false


static func activa() -> bool:
	return load("res://modo3d.gd").region_activa(INDICE)


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	mat = Materiales.new(perfil)
	_lugar_en_engine()
	super()
	info.visible = false
	_crear_interfaz()
	Sunk.registrar_dialogic()
	for id in Sunk.NPCS:
		_crear_vecino(id)
	_marca_salida()
	_rotulos()
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	_colocar_kael(_sitio_libre(Engine.get_meta("pos_3d")) if vuelve else T.en_mundo(T.INICIO))
	llegada_dicha = kael.global_position.z < LLEGADA_Z
	_crear_grupo()
	salida["armada"] = _dist_plana(kael.global_position, _salida()) > T.ARMAR_SALIDA
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
		dg.signal_event.connect(_al_senal)
	Engine.set_meta("zona", ZONA)
	_sonido_3d()
	_titulo_zona("Sunken City")
	if not en_banco():
		Progreso.guardar(scene_file_path)                       # guardado automático al entrar (como zona.gd)


func _exit_tree() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		if dg.timeline_ended.is_connected(_al_terminar_dialogo):
			dg.timeline_ended.disconnect(_al_terminar_dialogo)
		if dg.signal_event.is_connected(_al_senal):
			dg.signal_event.disconnect(_al_senal)
	super()


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


# La tienda (tienda.gd, Engine «lugar») y lo demás que mira el lugar saben que esto es Sunken City aunque se entre sin
# pasar por el mapa (una partida, una prueba).
func _lugar_en_engine() -> void:
	var l = Engine.get_meta("lugar", {})
	if l is Dictionary and int(l.get("indice", -1)) == INDICE:
		return
	var m: Dictionary = load("res://mapa.gd").LUGARES[INDICE]
	Engine.set_meta("lugar", {"indice": INDICE, "nombre": m["nombre"], "tipo": m["tipo"], "zona": ZONA, "texto": m["texto"]})


# Ajustes (menus.gd, en el bloque de las regiones en pruebas): «Sunken City: 2D / 3D (en pruebas)». Solo en Auditoría o
# en el editor (calidad_proto.pruebas_permitidas): fuera de ahí no sale la fila (y sin la fila, nadie la enciende).
static func opcion_ajustes(m: Object, cuerpo: Control) -> void:
	if not load("res://prototipos/calidad_proto.gd").pruebas_permitidas():
		return
	var m3d = load("res://modo3d.gd")
	var si_ahora: bool = m3d.elegida(CLAVE)
	cuerpo.add_child(m._texto("Sunken City", 26, m.COLOR_TITULO))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	for op in [[false, "2D (la de siempre)"], [true, "3D (en pruebas)"]]:
		var en_3d: bool = op[0]
		var b: Button = m._boton(("● " if en_3d == si_ahora else "○ ") + op[1], 18, Vector2(300, 34),
			"sunken:%s" % ("3d" if en_3d else "2d"))
		b.pressed.connect(func():
			m3d.elegir(CLAVE, en_3d)
			var son = m.get_node_or_null("/root/Sonido")
			if son != null:
				son.efecto("ui_tic")
			m._pintar_de_nuevo())
		fila.add_child(b)
	cuerpo.add_child(fila)
	cuerpo.add_child(m._texto("Se nota la próxima vez que se entra en Sunken City. Primer sector, PROPUESTA.", 16, m.COLOR_SUAVE))


# ================================================================= mundo: la tarde dorada

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR                  # el cielo de la tarde sobre la laguna (casi no se ve)
	env.background_color = Color(0.94, 0.78, 0.60)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# la sombra, fría (el reflejo verde azulado de la laguna, #24484F aclarado): con el sol dorado, el contraste de la
	# tarde (15/11, segunda pasada: con un ambiente cálido todo salía naranja)
	env.ambient_light_color = Color(0.50, 0.62, 0.68)
	env.ambient_light_energy = 0.72
	env.fog_enabled = true                                       # bruma dorada de la costa, lejos
	env.fog_light_color = Color(0.92, 0.78, 0.62)
	env.fog_density = 0.0045
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.08
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = perfil.get("exposicion", 0.92 if perfil.get("sombras", false) else 0.98)
	if nombre_perfil == "alto":
		env.glow_enabled = true                                  # el brillo del oro del mascarón y de los faroles
		env.glow_intensity = 0.32
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = env
	add_child(we)
	sol = DirectionalLight3D.new()                              # sol bajo del oeste-suroeste: sombras largas hacia el este
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-32.0, -68.0, 0.0)
	sol.light_color = Color(1.0, 0.84, 0.64)
	sol.light_energy = float(perfil.get("luz_sol", 1.0)) * 1.05
	sol.shadow_enabled = perfil.get("sombras", false)
	sol.directional_shadow_max_distance = perfil.get("dist_sombras", 30.0)
	sol.shadow_blur = 1.3
	match int(perfil.get("sombra_tramos", 2)):
		1:
			sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		2:
			sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		_:
			sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if perfil.get("sombras", false):
		RenderingServer.directional_shadow_atlas_set_size(int(perfil.get("sombra_res", 2048)), true)
	add_child(sol)


func _crear_escenario() -> void:
	casco = Casco.crear(self, mat, perfil, nombre_perfil)


# Por dónde se anda: las tablas del trazado, fuera de lo que estorba y sin atravesar a los vecinos.
func _prohibido(p: Vector3) -> bool:
	if T.prohibido(p.x, p.z):
		return true
	for id in vecinos:
		var q: Vector3 = vecinos[id]["nodo"].global_position
		if Vector2(p.x - q.x, p.z - q.z).length() < 0.5:
			return true
	return false


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func suelo_de_pasos(_p: Vector3) -> String:
	return "madera"                                             # todo son tablas: muelle, cubiertas y pasarelas


func _salida() -> Vector3:
	return T.en_mundo(T.SALIDA)


func _sitio_libre(p: Vector3) -> Vector3:
	if not _prohibido(p):
		p.y = T.altura(p.x, p.z)
		return p
	for radio in [0.5, 1.0, 1.6, 2.4]:
		for k in 12:
			var q: Vector3 = p + Vector3(cos(k * TAU / 12.0), 0, sin(k * TAU / 12.0)) * radio
			if not _prohibido(q):
				q.y = T.altura(q.x, q.z)
				return q
	return T.en_mundo(T.INICIO)


# Una partida guardada en la Sunken City 2D (zona.tscn con el lugar 5): su trazado no es este, así que se entra por el
# muelle (modo3d.escena_equivalente). (No hay posicion_a_2d: con la región apagada, una partida de aquí entra en la 2D por
# su entrada, como las demás regiones que no comparten trazado.)
static func posicion_desde_2d(_px: Vector2) -> Vector3:
	return T.en_mundo(T.INICIO)


# ================================================================= Kael, cámara y grupo

func _colocar_kael(p: Vector3) -> void:
	p.y = T.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	var z: Array = T.camara(p.x, p.z)
	inclinacion = z[0]
	distancia = clampf(_dist_jugador, z[1], z[2])
	_dist_puesta = distancia
	_colocar_camara(1.0)


func _camara_zona(delta: float) -> void:
	if absf(distancia - _dist_puesta) > 0.0001:
		_dist_jugador = clampf(_dist_jugador + distancia - _dist_puesta, DIST_MIN, DIST_MAX)
	var z: Array = T.camara(kael.global_position.x, kael.global_position.z)
	var k := 1.0 - exp(-1.8 * delta)
	inclinacion = lerpf(inclinacion, z[0], k)
	distancia = lerpf(distancia, clampf(_dist_jugador, z[1], z[2]), k)
	_dist_puesta = distancia


func _crear_grupo() -> void:
	if not perfil.get("grupo", true):
		return
	var G = load("res://grupo.gd")
	var activos: Array = G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	grupo = load("res://zonas3d/grupo_3d.gd").new()
	grupo.name = "Grupo"
	add_child(grupo)
	grupo.pasos_superficie = suelo_de_pasos
	grupo.preparar(self, kael, nombres)
	grupo.colocar(Vector3.BACK)


func _parar_kael() -> void:
	destino = null
	if movimiento != "":
		movimiento = ""
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()


func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return (dg != null and dg.current_timeline != null) or (abierto != null and is_instance_valid(abierto))


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


# ================================================================= los vecinos (PROPUESTA)

func _crear_vecino(id: String) -> void:
	var d: Dictionary = Sunk.NPCS[id]
	var n := Node3D.new()
	n.name = "Vecino_" + id
	add_child(n)
	var sitio: Vector2 = T.ULLA if id == "ulla" else T.BREA
	n.global_position = T.en_mundo(sitio)
	n.rotation.y = 0.0 if id == "ulla" else deg_to_rad(25.0)    # Ulla mira a la puerta; Brea, a quien sube de la Quilla
	var chibi: Node3D = null
	if NpcChibi.existe(d["chibi"][0]):
		chibi = NpcChibi.crear(d["chibi"][0], d["chibi"][1])
		if not chibi.listo:
			chibi.free()
			chibi = null
	if chibi != null:
		n.add_child(chibi)
		chibi.sombra(perfil.get("sombras", false))
	else:                                                       # sin el modelo: una cápsula de su color
		var mi := MeshInstance3D.new()
		var c := CapsuleMesh.new()
		c.radius = 0.28
		c.height = 1.6
		mi.mesh = c
		mi.position.y = 0.8
		mi.material_override = mat.liso(d["tinte"], 0.9)
		n.add_child(mi)
	var cuerpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.32
	cil.height = 1.7
	col.shape = cil
	col.position.y = 0.85
	cuerpo.add_child(col)
	n.add_child(cuerpo)
	vecinos[id] = {"nodo": n, "chibi": chibi, "veces": 0}


func hablar(id: String) -> String:
	var v: Dictionary = vecinos[id]
	var n: Node3D = v["nodo"]
	n.rotation.y = atan2(kael.global_position.x - n.global_position.x, kael.global_position.z - n.global_position.z)
	if v["chibi"] != null:
		v["chibi"].clip("hablar", "reposo")
	var dg = get_node_or_null("/root/Dialogic")
	var ruta := Sunk.dialogo_de(id)
	v["veces"] = int(v["veces"]) + 1
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		_avisar("%s: «%s»" % [Sunk.NPCS[id]["corto"], Sunk.frase(id, int(v["veces"]))], "", 3.2)
		return ""
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = ruta
	dg.start(ruta)
	return ruta


func _al_senal(arg) -> void:
	var s := str(arg)
	if not s.begins_with("sunk:"):
		return
	var t := Sunk.aplicar_senal(s)
	if t != "":
		cambios = true
		avisos_cola.append([t, 3.4])
		var son = get_node_or_null("/root/Sonido")
		if son != null:
			son.efecto("tesoro" if s == "sunk:sello_fin" else "pagina", {"retraso": 0.2})


func _al_terminar_dialogo() -> void:
	dialogo_actual = ""
	_bloqueo = 0.4
	if cambios:
		cambios = false
		_guardar()


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	_t += delta
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if kael == null or casco == null:
		return
	casco.animar(_t)
	if casco.quilla != null:                                    # (V12, 16/11: la Quilla horneada, EXPERIMENTAL)
		casco.quilla.cada_fotograma(delta, self)
	for id in vecinos:
		if vecinos[id]["chibi"] != null:
			vecinos[id]["chibi"].avanzar(delta)
	if en_banco():
		super(delta)
		return
	casco.apartar(kael.global_position.z, cam.global_position.z, self)
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		_oclusion()
		_quitar_comentarios()
		return
	_avisos_pendientes()
	_camara_zona(delta)
	super(delta)
	if saliendo:
		return
	var p := kael.global_position
	var ds := _dist_plana(p, _salida())
	if not salida["armada"]:
		salida["armada"] = ds > T.ARMAR_SALIDA
	elif ds < T.RADIO_SALIDA:
		_salir()
		return
	_comprobar_cerca()
	_t_brazalete -= delta
	if _t_brazalete <= 0.0:
		_t_brazalete = 0.25
		_brazalete()
	if not llegada_dicha and p.z < LLEGADA_Z:
		llegada_dicha = true
		_comentar_luego("llegar", 0.8)
	_comentarios(delta)


func _avisos_pendientes() -> void:
	if avisos_cola.is_empty():
		return
	if _tween_aviso != null and _tween_aviso.is_valid() and _tween_aviso.is_running():
		return
	var a: Array = avisos_cola.pop_front()
	_mostrar_aviso(a[0], a[1])


# ================================================================= lo que se usa

func piezas_al_alcance() -> Array:
	var r: Array = []
	for id in vecinos:
		r.append([id, vecinos[id]["nodo"].global_position, T.RADIO_NPC, Sunk.NPCS[id]["boton"]])
	for id in T.PIEZAS:
		var d: Array = T.PIEZAS[id]
		var texto: String = d[3]
		if id == "tabla" and Sunk.paga_encontrada():
			texto = "Examinar la tabla"
		r.append([id, T.pieza(id), d[2], texto])
	if casco != null and casco.quilla != null:                  # (la cuadrilla de la Quilla horneada, PROPUESTA)
		r.append_array(casco.quilla.piezas())
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	var p := kael.global_position
	for pz in piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := _dist_plana(p, q)
		if d < pz[2] and d < mejor and absf(p.y - q.y) < 1.6:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != "" and _bloqueo <= 0.0


# Tocar el suelo (vista3d.gd): aquí las costillas, los tejados y la bandera pasan por encima de lo que se pisa, y el
# rayo del toque chocaba con ellos (Kael iba hacia donde estaba la costilla, no adonde se tocó). Lo que queda por encima
# de lo andable (más de 1 m sobre la Cubierta Mayor) no cuenta: el rayo sigue hasta las tablas.
func _punto_suelo(pantalla: Vector2):
	var desde := cam.project_ray_origin(pantalla)
	var hasta := desde + cam.project_ray_normal(pantalla) * 500.0
	var excluir: Array[RID] = []
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(desde, hasta)
		q.exclude = excluir
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			return null
		if (r["position"] as Vector3).y < T.ALTO_CUBIERTA + 1.0:
			return r["position"]
		excluir.append(r["rid"])
	return null


func _unhandled_input(ev: InputEvent) -> void:
	if ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado() or saliendo:
		return
	_bloqueo = 0.5
	match cerca:
		"ulla", "brea":
			hablar(cerca)
		"popa":
			_avisar(Sunk.TEXTO_POPA, "examinar", 3.2)
		"grabado":
			var nuevo := Sunk.leer_grabado()
			_avisar(Sunk.TEXTO_GRABADO, "examinar", 4.0)
			if nuevo:
				_guardar()
		"tabla":
			_mirar_tabla()
		"contratos":
			_examinar_detalle()
		"palo":
			var r: Array = Sunk.examinar_palo()
			_avisar(r[0], "tesoro" if r[1] else "examinar", 3.6)
			if r[1]:
				avisos_cola.append(["Diario: el sello de la capitana. Hay que llevárselo a Ulla, al Archivo.", 3.0])
				_guardar()
		"tienda":
			abrir_tienda()
		"escotilla":
			_avisar(Sunk.TEXTO_ESCOTILLA, "examinar", 3.4)
		"lona":
			_avisar(Sunk.TEXTO_LONA, "examinar", 3.4)
			_comentar_luego("lona", 3.8)
		"proa":
			_avisar(Sunk.TEXTO_PROA, "examinar", 3.4)
		_:
			if casco.quilla != null and casco.quilla.es_obrero(cerca):
				_avisar(casco.quilla.hablar(cerca, kael.global_position), "", 3.6)
	_comprobar_cerca()


func _mirar_tabla() -> void:
	var r: Array = Sunk.abrir_tabla()
	if r[1] == "":
		_avisar(r[0], "examinar", 2.6)
		return
	_avisar(r[0], "cofre", 3.6)
	avisos_cola.append(["¡Has encontrado %s!" % r[1], 2.6])
	var son = get_node_or_null("/root/Sonido")
	if son != null:
		son.efecto("tesoro", {"retraso": 0.4})
	_comentar_luego("secreto", 7.0)
	_guardar()


# El detalle de canon (progreso.gd, DETALLES[5]: «sunken_contratos», el mismo id que la zona 2D): su texto, la página del
# Diario si completa el acto y el hallazgo si lo hubiera.
func _examinar_detalle() -> void:
	var lista := Progreso.detalles_de(INDICE)
	if lista.is_empty():
		return
	var d: Dictionary = lista[0]
	_avisar(d["texto"], "examinar", 3.2)
	var nuevo := not Progreso.visto(d["id"])
	var acto: Dictionary = Progreso.ver_detalle(d["id"])
	var desde := 3.6 if acto.is_empty() else 8.2
	if not acto.is_empty():
		get_tree().create_timer(4.0).timeout.connect(_pagina_diario.bind(String(acto["escena"])))
	var libre: float = Ex.hallazgo_al_examinar(self, INDICE, "detalle:" + d["id"], desde)
	if nuevo or libre > desde:
		_guardar()


func _pagina_diario(escena: String) -> void:
	var son = get_node_or_null("/root/Sonido")
	if son != null:
		son.efecto("pagina")
		son.efecto("misterio", {"retraso": 0.2})
	_mostrar_aviso("Nueva página en el Diario: «%s»" % escena, 3.0)


# El brillo del brazalete cerca del detalle sin ver (como zona.gd y las otras regiones).
func _brazalete() -> void:
	var q: Vector3 = T.pieza("contratos")
	var dist := _dist_plana(kael.global_position, q)
	if dist > RADIO_BRAZALETE * 1.6:
		brillados.erase(Sunk.ID_DETALLE)
	elif dist < RADIO_BRAZALETE and not brillados.has(Sunk.ID_DETALLE) and not Progreso.visto(Sunk.ID_DETALLE):
		brillados[Sunk.ID_DETALLE] = true
		var son = get_node_or_null("/root/Sonido")
		if son != null:
			son.efecto("brazalete")
		var b := MeshInstance3D.new()
		b.name = "BrilloBrazalete"
		var qm := QuadMesh.new()
		qm.size = Vector2(0.4, 0.4)
		b.mesh = qm
		b.material_override = mat.halo_aire(Color(1.0, 0.86, 0.42), 1.0)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.position = Vector3(-0.28, 1.0, 0.12)
		b.scale = Vector3.ONE * 0.1
		kael.add_child(b)
		var t := b.create_tween()
		t.tween_property(b, "scale", Vector3.ONE, 0.25)
		t.tween_property(b, "scale", Vector3.ONE * 0.05, 0.6)
		t.tween_callback(b.queue_free)


func abrir_tienda() -> void:
	if ocupado():
		return
	_parar_kael()
	boton_accion.visible = false
	var capa := CanvasLayer.new()
	capa.layer = 60
	add_child(capa)
	var t = load("res://tienda.gd").new()
	t.pestana = "Objetos"
	abierto = capa
	t.cerrado.connect(func():
		abierto = null
		capa.queue_free()
		_bloqueo = 0.4
		_guardar())
	capa.add_child(t)


# ================================================================= comentarios del grupo (PROPUESTA: ciudades/sunken.gd)

func _comentar_luego(momento: String, segundos: float) -> void:
	_comentario = momento
	_comentario_t = segundos


func _comentarios(delta: float) -> void:
	if _comentario == "":
		return
	_comentario_t -= delta
	if _comentario_t > 0.0:
		return
	if capa_ui == null or saliendo:
		_comentario = ""
		return
	for n in capa_ui.get_children():
		if n.name.begins_with("comentario"):
			return                                              # espera a que acabe el que hay
	var c := Sunk.comentario(_comentario)
	_comentario = ""
	if not c.is_empty():
		Comentarios.mostrar(capa_ui, c)


func _quitar_comentarios() -> void:
	if capa_ui == null:
		return
	for n in capa_ui.get_children():
		if n.name.begins_with("comentario"):
			n.queue_free()


# ================================================================= guardado y salida

func _guardar() -> void:
	if en_banco():
		return
	guardar_posicion()
	Progreso.guardar(scene_file_path)


func guardar_posicion() -> void:
	if kael == null:
		return
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_3d_ok", false)                         # la próxima vez se entra por el muelle
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena(Progreso.MAPA)


func _sonido_3d() -> void:
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, suelo_de_pasos)
	# (no hay olas ni gaviotas en audio/: el agua que lame el casco es el bucle del río, bajo; pendiente de sonido)
	Sonido.fuente_linea(self, "rio", Vector3(29.6, -0.6, 52.0), Vector3(29.6, -0.6, 16.0), -15.0)
	Sonido.fuente_linea(self, "rio", Vector3(50.4, -0.6, 52.0), Vector3(50.4, -0.6, 16.0), -15.0)
	Sonido.fuente_linea(self, "puente_cruje", Vector3(40.0, 0.5, 44.0), Vector3(40.0, 0.5, 30.0))
	Sonido.fuente_linea(self, "viento_cuerdas", Vector3(31.0, 8.0, 23.2), Vector3(49.0, 8.0, 23.2))
	Sonido.fuente_3d(self, "mercado_murmullo", Vector3(32.4, 2.2, 20.4), -5.0)


# ================================================================= interfaz

# La salida al mapa, señalada como en las otras regiones: un disco que brilla al final del muelle y el letrero.
func _marca_salida() -> void:
	var p := _salida()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.92, 0.6, 0.34)
	var disco := CylinderMesh.new()
	disco.top_radius = T.RADIO_SALIDA
	disco.bottom_radius = T.RADIO_SALIDA
	disco.height = 0.02
	disco.radial_segments = 32
	var mi := MeshInstance3D.new()
	mi.name = "MarcaSalida"
	mi.mesh = disco
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p + Vector3(0, 0.04, 0)
	add_child(mi)
	var letrero := Label3D.new()
	letrero.name = "LetreroSalida"
	letrero.text = "Mapa del mundo"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 48
	letrero.outline_size = 12
	letrero.modulate = Color(1.0, 0.98, 0.92)
	letrero.outline_modulate = Color(0.24, 0.12, 0.08, 0.85)
	letrero.pixel_size = 0.01
	letrero.position = p + Vector3(2.4, 1.4, 0.0)               # (a un lado: no tapa al grupo, que llega por el muelle)
	add_child(letrero)


# Rótulos pequeños de los sitios con nombre (se leen desde la cámara del juego).
func _rotulos() -> void:
	for d in [["Archivo del Águila", Vector3(48.6, 3.6, 45.6)], ["Cubierta Mayor", Vector3(36.0, 4.0, 28.6)]]:
		var l := Label3D.new()
		l.text = d[0]
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.font_size = 40
		l.outline_size = 10
		l.modulate = Color(1.0, 0.94, 0.78)
		l.outline_modulate = Color(0.30, 0.14, 0.08, 0.85)
		l.pixel_size = 0.01
		l.position = d[1]
		l.no_depth_test = true                                  # (que no lo corte una costilla)
		add_child(l)


func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	boton_accion = Button.new()
	boton_accion.position = Vector2(960, 600)
	boton_accion.custom_minimum_size = Vector2(290, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa_ui.add_child(boton_accion)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 120)
	aviso.position = Vector2(140, 470)
	aviso.add_theme_font_size_override("font_size", 28)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	aviso.add_theme_color_override("font_outline_color", Color(0.16, 0.10, 0.08, 0.9))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


var _tween_aviso: Tween


# Un aviso ahora (con su efecto de sonido).
func _avisar(texto: String, efecto := "", segundos := 2.8) -> void:
	ultimo_aviso = texto
	if efecto != "":
		var son = get_node_or_null("/root/Sonido")
		if son != null:
			son.efecto(efecto)
	_mostrar_aviso(texto, segundos)


func _mostrar_aviso(texto: String, segundos := 1.8) -> void:
	if aviso == null:
		return
	ultimo_aviso = texto
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(segundos)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


func _titulo_zona(nombre: String) -> void:
	var l := Label.new()
	l.text = nombre
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 80)
	l.position = Vector2(0, 110)
	l.add_theme_font_size_override("font_size", 52)
	l.add_theme_color_override("font_color", Color(1.0, 0.93, 0.76))
	l.add_theme_color_override("font_outline_color", Color(0.24, 0.10, 0.06, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	if ResourceLoader.exists("res://menu_combate.gd"):
		var mc = load("res://menu_combate.gd")
		var f = mc.fuente(mc.FUENTE_NOMBRE, 0, 600)
		if f != null:
			l.add_theme_font_override("font", f)
	l.modulate.a = 0.0
	capa_ui.add_child(l)
	var t := l.create_tween()
	t.tween_interval(0.4)
	t.tween_property(l, "modulate:a", 1.0, 0.7)
	t.tween_interval(1.8)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	t.tween_callback(l.queue_free)
