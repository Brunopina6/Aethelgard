extends "res://prototipos/vista3d.gd"
# Las Cumbres de Ciclópea en 3D, primer sector (lugar 3 del mapa; V12, especialista de mundo, 13/11).
# EN PRUEBAS, APAGADO: solo con el argumento «ciclopea3d» o elegido en Ajustes («Cumbres de Ciclópea: 3D (en pruebas)»,
# [regiones] ciclopea3d en user://ajustes.cfg; modo3d.gd, EN_PRUEBAS). Sin eso, el mapa lleva a la zona 2D de siempre
# (zona.tscn con el lugar 3), que no se toca.
# Es el MISMO trazado que la 2D (zona.gd, lugar 3, estilo «nieve»; zonas3d/ciclopea/disposicion_2d.gd, volcado de zona.gd)
# a 1,25 m por casilla, con relieve de subida de montaña (trazado.gd: el camino sube 7,5 m del sur al altar y el suelo de
# alrededor baja a su altura, sin trincheras) y escenario propio de cumbre fría (escenario.gd). Lo de la 2D, con sus ids:
#   - encuentros al azar por pasos (progreso.gd, zona «nieve»; la tabla y el fondo de combate.gd);
#   - los tres cofres de los rincones (ruinas, campamento, claro) con su id «3_x_y» y su premio (zona.gd, _abrir_cofre);
#   - el detalle «ciclopea_estatua» (Acto II): la estatua sin brazo izquierdo que mira al pico; al examinarla, su texto,
#     la página del Diario si toca y el hallazgo «Guardiana de Ámbar» (hallazgos.gd, examinables_3d.gd);
#   - los cofres de los hallazgos «Pluma de Arpía» (junto a las ruinas) y «Tomo de Escarcha» («mirada»: donde la 2D lo
#     pone, 4 casillas al norte de las ruinas, adonde mira la estatua; zona.gd, _sitio_hallazgo);
#   - el altar del fondo (su texto y su hallazgo si lo hubiera); el brillo del brazalete cerca del detalle sin ver; los
#     comentarios del grupo al llegar y tras un cofre; el Incienso de Ceniza; el ambiente «viento» (el de la 2D); el
#     guardado al entrar, tras cofres y hallazgos, tras cada combate y al pausar; la salida al mapa por el sur.
# Partidas: una de la 2D abre esta en la misma casilla (posicion_desde_2d) si la 3D está en uso; una de esta abre la 2D
# en la misma casilla (posicion_a_2d) si se apaga.

const T := preload("res://zonas3d/ciclopea/trazado.gd")
const D := preload("res://zonas3d/ciclopea/disposicion_2d.gd")
const Escenario := preload("res://zonas3d/ciclopea/escenario.gd")
const Ex := preload("res://zonas3d/examinables_3d.gd")
const Hallazgos := preload("res://hallazgos.gd")
const Progreso := preload("res://progreso.gd")
const Comentarios := preload("res://dialogos/comentarios.gd")

const INDICE := 3                          # lugar del mapa (mapa.gd, LUGARES[3]; modo3d.CICLOPEA)
const ZONA := "nieve"                      # mapa.gd, ZONA_LUGAR[3]: progreso.gd (nivel) y combate.gd (fondo)
const CLAVE := "ciclopea3d"                # modo3d.gd, EN_PRUEBAS: el argumento y la clave de Ajustes
const ID_DETALLE := "ciclopea_estatua"     # progreso.gd, DETALLES[3]
const LONG_PASO := 0.3125 * 1.25           # zona.gd: un paso cada 20 px, a 1,25 m por casilla
const PASOS_MIN := 40
const PROB_ENCUENTRO := 0.012
const RADIO_SALIDA := 1.6
const ARMAR_SALIDA := 2.6
const RADIO_COFRE := 1.9
const RADIO_DETALLE := 2.4
const RADIO_ALTAR := 2.6
const RADIO_BRAZALETE := 5.0
const LLEGADA_COMENTARIO := 2.8
const CAMARA := [50.0, 13.0, 22.0]         # [inclinación, distancia mínima, máxima]

var perfil: Dictionary = {}
var nombre_perfil := "alto"
var escenario
var sol: DirectionalLight3D
var grupo: Node3D
var capa_ui: CanvasLayer
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var cerca := ""
var saliendo := false
var pasos := 0
var _recorrido := 0.0
var _ultima := Vector3.ZERO
var _bloqueo := 0.0
var _t := 0.0
var salida := {"armada": false}
var _dist_jugador := 17.0
var _dist_puesta := 17.0
var brillados := {}
var _llegada_t := LLEGADA_COMENTARIO
var _comentario := ""
var _comentario_t := 0.0
var brillo_sin_sombras := 1.12              # vista3d.gd: el bajo sin sombras (la nieve ya es clara; a ojo en el PC)


static func activa() -> bool:
	return load("res://modo3d.gd").region_activa(INDICE)


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	_lugar_en_engine()
	super()
	info.visible = false
	_crear_interfaz()
	_crear_cofres()
	_marca_salida()
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	_colocar_kael(_sitio_libre(Engine.get_meta("pos_3d")) if vuelve else T.en_mundo(T.ENTRADA_2D))
	_ultima = kael.global_position
	_crear_grupo()
	_crear_fauna()
	salida["armada"] = _dist_plana(kael.global_position, _salida()) > ARMAR_SALIDA
	Engine.set_meta("zona", ZONA)
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, suelo_de_pasos)
	if escenario.fuego_pos != Vector3.ZERO:
		Sonido.fuente_3d(self, "fogata_bucle", escenario.fuego_pos + Vector3(0, 0.4, 0))
	_musica()
	_titulo_zona("Cumbres de Ciclópea")
	if not en_banco():
		Progreso.guardar(scene_file_path)


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


func _lugar_en_engine() -> void:
	var l: Dictionary = Engine.get_meta("lugar", {})
	if int(l.get("indice", -1)) == INDICE and l.get("zona", "") == ZONA:
		return
	var m: Dictionary = load("res://mapa.gd").LUGARES[INDICE]
	Engine.set_meta("lugar", {"indice": INDICE, "nombre": m["nombre"], "tipo": m["tipo"], "zona": ZONA, "texto": m["texto"]})


# musica.gd no conoce esta escena: se pide el ambiente de la 2D de este lugar («viento», musica.gd, zona.tscn).
func _musica() -> void:
	var mus = get_node_or_null("/root/Musica")
	if mus != null and mus.contexto != "viento" and get_tree().current_scene == self and mus.contexto_de(self) == "silencio":
		mus.pedir("viento")


# Ajustes (menus.gd, una línea en el bloque de las regiones en pruebas): «Cumbres de Ciclópea: 2D / 3D (en pruebas)».
static func opcion_ajustes(m: Object, cuerpo: Control) -> void:
	var m3d = load("res://modo3d.gd")
	var si_ahora: bool = m3d.elegida(CLAVE)
	cuerpo.add_child(m._texto("Cumbres de Ciclópea", 26, m.COLOR_TITULO))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	for op in [[false, "2D (la de siempre)"], [true, "3D (en pruebas)"]]:
		var en_3d: bool = op[0]
		var b: Button = m._boton(("● " if en_3d == si_ahora else "○ ") + op[1], 18, Vector2(300, 34),
			"ciclopea:%s" % ("3d" if en_3d else "2d"))
		b.pressed.connect(func():
			m3d.elegir(CLAVE, en_3d)
			var son = m.get_node_or_null("/root/Sonido")
			if son != null:
				son.efecto("ui_tic")
			m._pintar_de_nuevo())
		fila.add_child(b)
	cuerpo.add_child(fila)
	cuerpo.add_child(m._texto("Se nota la próxima vez que se entra en las Cumbres.", 16, m.COLOR_SUAVE))


# ================================================================= mundo: luz fría de cumbre

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR                  # cielo de altura, pálido y frío
	env.background_color = Color(0.70, 0.78, 0.90)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.66, 0.74, 0.90)           # la nieve rebota luz azulada
	env.ambient_light_energy = 0.46
	env.fog_enabled = true                                      # bruma fría: las cumbres se pierden a lo lejos
	env.fog_light_color = Color(0.76, 0.83, 0.94)
	env.fog_density = 0.0085
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.94
	env.adjustment_contrast = 1.1
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.86 if not perfil.get("sombras", false) else 0.76
	if nombre_perfil == "alto":
		env.glow_enabled = true                                 # el brillo de la nieve al sol y el orbe
		env.glow_intensity = 0.25
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	we.name = "Ambiente"
	add_child(we)
	sol = DirectionalLight3D.new()                              # sol bajo de montaña, blanco frío
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-34.0, -142.0, 0.0)
	sol.light_color = Color(0.94, 0.96, 1.0)
	sol.light_energy = float(perfil.get("luz_sol", 1.0)) * 0.88
	sol.shadow_enabled = perfil.get("sombras", false)
	sol.directional_shadow_max_distance = perfil.get("dist_sombras", 30.0)
	sol.shadow_blur = 1.2
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
	escenario = Escenario.new(self, perfil, nombre_perfil)
	escenario.construir()


func _prohibido(p: Vector3) -> bool:
	return T.prohibido(p.x, p.z) or (escenario != null and escenario.bloqueado(p.x, p.z))


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func suelo_de_pasos(p: Vector3) -> String:
	return T.suelo(p)


func _salida() -> Vector3:
	return T.en_mundo(T.SALIDA_2D)


func _sitio_libre(p: Vector3) -> Vector3:
	if not _prohibido(p):
		p.y = T.altura(p.x, p.z)
		return p
	for radio in [0.6, 1.2, 1.8, 2.6, 3.4]:
		for k in 12:
			var q: Vector3 = p + Vector3(cos(k * TAU / 12.0), 0, sin(k * TAU / 12.0)) * radio
			if not _prohibido(q):
				q.y = T.altura(q.x, q.z)
				return q
	return T.en_mundo(T.punto_en_camino(T.casilla(p.x, p.z)))


static func posicion_desde_2d(px: Vector2) -> Vector3:
	return T.desde_2d(px)


static func posicion_a_2d(p: Vector3) -> Vector2:
	return T.a_2d(p)


# ================================================================= Kael, cámara y grupo

func _colocar_kael(p: Vector3) -> void:
	p.y = T.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	inclinacion = CAMARA[0]
	distancia = clampf(_dist_jugador, CAMARA[1], CAMARA[2])
	_dist_puesta = distancia
	_colocar_camara(1.0)


func _camara_zona(delta: float) -> void:
	if absf(distancia - _dist_puesta) > 0.0001:
		_dist_jugador = clampf(_dist_jugador + distancia - _dist_puesta, DIST_MIN, DIST_MAX)
	var k := 1.0 - exp(-2.2 * delta)
	inclinacion = lerpf(inclinacion, CAMARA[0], k)
	distancia = lerpf(distancia, clampf(_dist_jugador, CAMARA[1], CAMARA[2]), k)
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


# Fauna de cumbre: dos aves de presa que planean alto en círculos (no hay conejos en la nieve).
func _crear_fauna() -> void:
	if en_banco():
		return
	var fauna := load("res://prototipos/fauna_simple.gd")
	for d in [[T.lugar("claro"), 11.0, 9.0], [D.META + Vector2(-6, 8), 13.0, 11.0]]:
		var ave = fauna.new()
		ave.tipo = "pajaro"
		ave.radio = d[2]
		ave.position = T.en_mundo(d[0]) + Vector3(0, d[1], 0)
		add_child(ave)


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
	return dg != null and dg.current_timeline != null


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	_t += delta
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if kael == null or escenario == null:
		return
	escenario.animar(_t, kael.global_position)
	if _t < 2.0 or int(_t * 2.0) % 4 == 0:
		_musica()
	if en_banco():
		super(delta)
		return
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		_oclusion()
		_quitar_comentarios()
		return
	_camara_zona(delta)
	super(delta)
	if saliendo:
		return
	var p := kael.global_position
	var d := _dist_plana(p, _ultima)
	_ultima = p
	if d < 2.0:
		_recorrido += d
		while _recorrido >= LONG_PASO and not saliendo:
			_recorrido -= LONG_PASO
			_paso()
	if saliendo:
		return
	var ds := _dist_plana(p, _salida())
	if not salida["armada"]:
		salida["armada"] = ds > ARMAR_SALIDA
	elif ds < RADIO_SALIDA or T.casilla(p.x, p.z).y > D.ALTO - 0.06:
		_salir()
		return
	_comprobar_cerca()
	_comentarios(delta)


# ================================================================= encuentros (zona.gd)

func _paso() -> void:
	pasos += 1
	_brazalete()
	if Progreso.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	if randf() < Progreso.prob_encuentro(PROB_ENCUENTRO, pasos, PASOS_MIN, ZONA):
		encuentro()


func encuentro(fijo := "", grupo_combate := -1, tipo := "normal", texto := "¡Emboscada!") -> void:
	if saliendo:
		return
	saliendo = true
	guardar_posicion()
	Engine.set_meta("zona", ZONA)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("escena_retorno", scene_file_path)
	if fijo != "":
		Engine.set_meta("grupo_combate", grupo_combate)
		Engine.set_meta("combate_fijo", fijo)
	Sonido.efecto("emboscada")
	_mostrar_aviso(texto)
	_parar_kael()
	boton_accion.visible = false
	fundido.color = Color(1, 1, 1, 0)
	var t := create_tween()
	for i in 3:
		t.tween_property(fundido, "color:a", 0.85, 0.07)
		t.tween_property(fundido, "color:a", 0.0, 0.07)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


# ================================================================= cofres

func _crear_cofres() -> void:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	var hacia_camino := func(c: Vector2) -> Vector3:
		var q := T.mundo(T.punto_en_camino(c)) - T.mundo(c)
		return q.normalized() if q.length() > 0.1 else Vector3.BACK
	for cf in D.COFRES:
		escenario.crear_cofre(cf[0], cf[1], abiertos.has(cf[0]), hacia_camino.call(cf[1]))
	for h in Hallazgos.cofres_de(INDICE):                # solo los que ya se pueden dar (como en la 2D)
		var c := sitio_hallazgo(h[0])
		escenario.crear_cofre(h[0], c, Hallazgos.encontrado(h[0]), hacia_camino.call(c))


# Donde la 2D pone el cofre de un hallazgo (zona.gd, _sitio_hallazgo; volcado en disposicion_2d.gd).
static func sitio_hallazgo(id: String) -> Vector2:
	for h in D.HALLAZGOS:
		if h[0] == id:
			return h[2]
	return D.META + Vector2(3.0, 2.0)


func _abrir_cofre(id: String) -> void:
	var cf: Dictionary = escenario.cofres.get(id, {})
	if cf.is_empty() or cf["abierto"]:
		return
	escenario.abrir_cofre(id)
	Sonido.efecto("cofre")
	if Hallazgos.es_hallazgo(id):
		var textos: Array = Hallazgos.encontrar(id)
		Ex.avisos(self, textos, 0.0)
		Sonido.efecto("tesoro", {"retraso": 0.3})
		_comentar_luego("cofre", 1.2 + 3.6 * textos.size())
		_guardar()
		return
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[id] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	Sonido.efecto("tesoro", {"retraso": 0.3})
	_mostrar_aviso("¡Has encontrado %s!" % premio_cofre(id), 2.4)
	_comentar_luego("cofre", 1.2)
	_guardar()


# El premio de un cofre generado (zona.gd, _abrir_cofre, con la semilla de su id): el mismo que en la 2D.
static func premio_cofre(id: String) -> String:
	var inv = load("res://inventario.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	match rng.randi() % 4:
		0, 1:
			var oro := rng.randi_range(40, 120)
			inv.ganar_oro(oro)
			return "%d monedas" % oro
		2:
			inv.agregar_objeto("Poción", 2)
			return "2 Pociones"
		_:
			inv.agregar_objeto("Éter", 1)
			return "1 Éter"


func _guardar() -> void:
	if en_banco():
		return
	guardar_posicion()
	Progreso.guardar(scene_file_path)


# ================================================================= el detalle, el altar y el brazalete

func _sitio_detalle() -> Vector3:
	var c: Vector2 = D.DETALLES[0][1] if not D.DETALLES.is_empty() else D.META + Vector2(2.5, 1.5)
	return T.en_mundo(c)


func _sitio_altar() -> Vector3:
	return T.en_mundo(D.META)


func _examinar_detalle() -> void:
	var d: Dictionary = Progreso.detalles_de(INDICE)[0]
	_mostrar_aviso(d["texto"], 3.2)
	Sonido.efecto("examinar")
	var nuevo := not Progreso.visto(d["id"])
	var acto: Dictionary = Progreso.ver_detalle(d["id"])
	var desde := 3.6 if acto.is_empty() else 8.2
	if not acto.is_empty():
		get_tree().create_timer(4.0).timeout.connect(_pagina_diario.bind(String(acto["escena"])))
	var libre: float = Ex.hallazgo_al_examinar(self, INDICE, "detalle:" + d["id"], desde)
	if nuevo or libre > desde:
		_guardar()


func _pagina_diario(escena: String) -> void:
	Sonido.efecto("pagina")
	Sonido.efecto("misterio", {"retraso": 0.2})
	_mostrar_aviso("Nueva página en el Diario: «%s»" % escena, 3.0)


func _examinar_altar() -> void:
	Sonido.efecto("examinar")
	_mostrar_aviso(String(Engine.get_meta("lugar", {}).get("texto", load("res://mapa.gd").LUGARES[INDICE]["texto"])), 3.2)
	Ex.hallazgo_al_examinar(self, INDICE, "altar", 3.6)


func _brazalete() -> void:
	var dist := _dist_plana(kael.global_position, _sitio_detalle())
	if dist > RADIO_BRAZALETE * 1.6:
		brillados.erase(ID_DETALLE)
	elif dist < RADIO_BRAZALETE and not brillados.has(ID_DETALLE) and not Progreso.visto(ID_DETALLE):
		brillados[ID_DETALLE] = true
		_brillo_brazalete()


func _brillo_brazalete() -> void:
	Sonido.efecto("brazalete")
	var b := MeshInstance3D.new()
	b.name = "BrilloBrazalete"
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	b.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = escenario._tex_brillo()
	m.albedo_color = Color(1.0, 0.86, 0.42)
	b.material_override = m
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.position = Vector3(-0.28, 1.0, 0.12)
	b.scale = Vector3.ONE * 0.1
	kael.add_child(b)
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector3.ONE * 1.0, 0.25)
	t.tween_property(b, "scale", Vector3.ONE * 0.05, 0.6)
	t.tween_callback(b.queue_free)


# ================================================================= lo que se usa

func piezas_al_alcance() -> Array:
	var r: Array = []
	for id in escenario.cofres:
		var cf: Dictionary = escenario.cofres[id]
		if not cf["abierto"]:
			r.append(["cofre:" + id, cf["pos"], RADIO_COFRE, "Abrir cofre"])
	r.append(["detalle", _sitio_detalle(), RADIO_DETALLE, "Examinar"])
	r.append(["altar", _sitio_altar(), RADIO_ALTAR, "Examinar"])
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	var p := kael.global_position
	for pz in piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := _dist_plana(p, q)
		if d < pz[2] and d < mejor and absf(p.y - q.y) < 2.0:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != "" and _bloqueo <= 0.0


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
	if cerca.begins_with("cofre:"):
		_abrir_cofre(cerca.substr(6))
	elif cerca == "detalle":
		_examinar_detalle()
	elif cerca == "altar":
		_examinar_altar()
	_comprobar_cerca()


# ================================================================= comentarios del grupo (zona.gd)

func _momento_llegada() -> String:
	var clave := "@lugar:%d" % INDICE
	if Comentarios.dichos().has(clave):
		return ""
	var d: Dictionary = Comentarios.dichos().duplicate(true)
	d[clave] = true
	Engine.set_meta(Comentarios.META, d)
	return "llegar:lugar_nuevo"


func _comentar_luego(momento: String, segundos: float) -> void:
	_comentario = momento
	_comentario_t = segundos


func _comentarios(delta: float) -> void:
	if _llegada_t >= 0.0:
		_llegada_t -= delta
		if _llegada_t < 0.0:
			var m := _momento_llegada()
			if m != "":
				_comentar_luego(m, 0.0)
	if _comentario != "":
		_comentario_t -= delta
		if _comentario_t <= 0.0 and _comentar(_comentario):
			_comentario = ""
		elif _comentario_t < -10.0:
			_comentario = ""


func _comentar(momento: String) -> bool:
	if capa_ui == null or ocupado() or saliendo:
		return false
	for n in capa_ui.get_children():
		if n.name.begins_with("comentario"):
			return false
	var c := Comentarios.elegir(momento)
	if c.is_empty():
		return false
	Comentarios.mostrar(capa_ui, c)
	return true


func _quitar_comentarios() -> void:
	if capa_ui == null:
		return
	for n in capa_ui.get_children():
		if n.name.begins_with("comentario"):
			n.queue_free()


# ================================================================= guardado y salida

# La salida al mapa, señalada como en las otras regiones: un disco que brilla al pie del camino, el letrero «Mapa del
# mundo» y dos postes con nieve.
func _marca_salida() -> void:
	var p := _salida()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.92, 0.6, 0.34)
	var disco := CylinderMesh.new()
	disco.top_radius = RADIO_SALIDA
	disco.bottom_radius = RADIO_SALIDA
	disco.height = 0.02
	disco.radial_segments = 32
	var mi := MeshInstance3D.new()
	mi.name = "MarcaSalida"
	mi.mesh = disco
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p + Vector3(0, 0.08, 0)
	add_child(mi)
	var letrero := Label3D.new()
	letrero.name = "LetreroSalida"
	letrero.text = "Mapa del mundo"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 48
	letrero.outline_size = 12
	letrero.modulate = Color(1.0, 0.98, 0.92)
	letrero.outline_modulate = Color(0.10, 0.14, 0.24, 0.85)
	letrero.pixel_size = 0.01
	letrero.position = p + Vector3(0, 2.4, 0)
	add_child(letrero)
	var madera: StandardMaterial3D = escenario.mat_detalle(Color(0.42, 0.30, 0.20), 1.4, false, 1.0)
	for lado in [-1.0, 1.0]:
		var poste := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.07
		c.bottom_radius = 0.09
		c.height = 2.2
		c.radial_segments = 6
		poste.mesh = c
		poste.material_override = madera
		poste.position = p + Vector3(lado * (RADIO_SALIDA + 0.5), 1.1, 0)
		add_child(poste)


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
	Engine.set_meta("pos_3d_ok", false)
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena(Progreso.MAPA)


# ================================================================= interfaz

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
	aviso.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94))
	aviso.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.18, 0.9))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


var _tween_aviso: Tween


func _mostrar_aviso(texto: String, segundos := 1.8) -> void:
	if aviso == null:
		return
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
	l.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.20, 0.9))
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
