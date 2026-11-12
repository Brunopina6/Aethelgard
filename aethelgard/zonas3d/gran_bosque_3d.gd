extends "res://prototipos/vista3d.gd"
# El Gran Bosque Verde en 3D (lugar 1 del mapa; V12, segunda fase, migración región a región, 12/11).
# Es el MISMO bosque que la 2D (zona.gd con el lugar 1, estilo «bosque»): mismos caminos, rincones, río con sus dos
# puentes, charcas, árboles en sus casillas y cofres con sus ids (zonas3d/gran_bosque/disposicion_2d.gd, volcado de
# zona.gd), a 1,25 m por casilla; con relieve, luz filtrada, sotobosque, árboles viejos y un mirador (escenario.gd).
# Lo que la 2D tiene, aquí también, con los mismos ids y la misma forma de guardarse:
#   - encuentros al azar por pasos (progreso.gd, zona «bosque»: nivel 4, la misma tabla de combate.gd y su fondo);
#   - los tres cofres de los rincones (ruinas, campamento, claro) con su id «1_x_y» y su premio (zona.gd, _abrir_cofre);
#   - el detalle «bosque_armadura» (Acto I) en las ruinas: el árbol que abraza la armadura; al examinarlo, su texto, la
#     página del Diario si toca y el hallazgo «Hoja sin Nombre» (hallazgos.gd, con zonas3d/examinables_3d.gd);
#   - el cofre del hallazgo «Diente de Grimfang» junto al campamento;
#   - el altar del fondo: al examinarlo, el texto del lugar (el del mapa) y su hallazgo si lo hubiera;
#   - el brillo del brazalete cerca del detalle sin ver; los comentarios del grupo al llegar y tras un cofre; el
#     Incienso de Ceniza; el ambiente «bosque»; el guardado al entrar, tras cofres y hallazgos, tras cada combate y al
#     pausar; la salida al mapa por el sur.
# Por defecto con la exploración 3D; la 2D se elige en Ajustes («granbosque3d» = false) o con «granbosque2d» (modo3d.gd).
# Partidas: una de la 2D abre esta en la misma casilla (posicion_desde_2d) y una de esta, con la 2D elegida, abre la 2D en
# la misma casilla (posicion_a_2d).

const T := preload("res://zonas3d/gran_bosque/trazado.gd")
const D := preload("res://zonas3d/gran_bosque/disposicion_2d.gd")
const Escenario := preload("res://zonas3d/gran_bosque/escenario.gd")
const Ex := preload("res://zonas3d/examinables_3d.gd")
const Hallazgos := preload("res://hallazgos.gd")
const Progreso := preload("res://progreso.gd")
const Comentarios := preload("res://dialogos/comentarios.gd")

const INDICE := 1                          # lugar del mapa (mapa.gd, LUGARES[1]; modo3d.GRAN_BOSQUE)
const ZONA := "bosque"                     # progreso.gd (nivel, zona limpia) y combate.gd (fondo, nivel, escalado)
const ID_DETALLE := "bosque_armadura"      # progreso.gd, DETALLES[1]
const LONG_PASO := 0.3125 * 1.25           # zona.gd: un paso cada 20 px (0,3125 casillas), a 1,25 m por casilla
const PASOS_MIN := 40                      # zona.gd
const PROB_ENCUENTRO := 0.012              # zona.gd
const RADIO_SALIDA := 1.6
const ARMAR_SALIDA := 2.6
const RADIO_COFRE := 1.9                   # zona.gd: 85 px (1,33 casillas) → algo más en 3D, con la cámara lejos
const RADIO_DETALLE := 2.2
const RADIO_ALTAR := 2.6
const RADIO_BRAZALETE := 5.0               # zona.gd: 260 px ≈ 4 casillas (5 m); se rearma al alejarse ×1,6
const LLEGADA_COMENTARIO := 2.8            # zona.gd
const CAMARA := [50.0, 13.0, 22.0]         # [inclinación, distancia mínima, máxima]
const CAMARA_MIRADOR := [36.0, 27.0]       # en lo alto del mirador: más baja y más lejos (se ve el bosque)
const HUECO_RADIO := 3.3

var perfil: Dictionary = {}
var nombre_perfil := "alto"
var escenario
var sol: DirectionalLight3D
var grupo: Node3D
var capa_ui: CanvasLayer
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var cerca := ""                            # «cofre:<id>», «detalle», «altar» o ""
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
var brillo_sin_sombras := 1.18              # vista3d.gd: el perfil bajo, sin sombras (a ojo en el PC; sin medir con medir_luz_perfiles ni en el Redmi)


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	_lugar_en_engine()
	super()                                 # ambiente, escenario, Kael, cámara y panel de vista3d.gd
	info.visible = false
	_crear_interfaz()
	_crear_cofres()
	escenario.poner_hoja(Ex.hallazgo_pendiente(INDICE, "detalle:" + ID_DETALLE))
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
	for pu in D.PUENTES:                              # el arroyo suena en los puentes (como el río de Pastos)
		Sonido.fuente_3d(self, "rio", T.mundo(pu[0]) + Vector3(0, T.AGUA_Y + 0.3, 0))
	if escenario.fuego_pos != Vector3.ZERO:
		Sonido.fuente_3d(self, "fogata_bucle", escenario.fuego_pos + Vector3(0, 0.4, 0))
	_musica()
	_titulo_zona("Gran Bosque Verde")
	if not en_banco():
		Progreso.guardar(scene_file_path)                     # guardado automático al entrar (como zona.gd)


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


# El lugar en Engine, como lo deja el mapa al entrar (mapa.gd, _entrar): así, si se elige la 2D, la partida guardada
# aquí abre zona.tscn con el lugar 1 (y el combate, el Diario y la música saben dónde se está).
func _lugar_en_engine() -> void:
	var l: Dictionary = Engine.get_meta("lugar", {})
	if int(l.get("indice", -1)) == INDICE and l.get("zona", "") == ZONA:
		return
	var m: Dictionary = load("res://mapa.gd").LUGARES[INDICE]
	Engine.set_meta("lugar", {"indice": INDICE, "nombre": m["nombre"], "tipo": m["tipo"], "zona": ZONA, "texto": m["texto"]})


# La música y el ambiente: musica.gd aún no conoce esta escena (su contexto_de; ver el informe): se pide el del bosque,
# el mismo que la 2D («bosque»).
func _musica() -> void:
	var mus = get_node_or_null("/root/Musica")
	if mus != null and mus.contexto != "bosque" and get_tree().current_scene == self and mus.contexto_de(self) == "silencio":
		mus.pedir("bosque")


# ================================================================= mundo

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR                  # bajo las copas apenas se ve el cielo
	env.background_color = Color(0.40, 0.50, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.56, 0.68, 0.58)           # luz verdosa que rebota en las hojas
	env.ambient_light_energy = 0.42
	env.fog_enabled = true                                      # bruma de bosque: da fondo a lo lejano
	env.fog_light_color = Color(0.44, 0.54, 0.44)
	env.fog_density = 0.011
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.08
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0 if not perfil.get("sombras", false) else 0.86
	if nombre_perfil == "alto":
		env.glow_enabled = true                                 # los haces de luz y el orbe del altar
		env.glow_intensity = 0.3
		env.glow_bloom = 0.03
		env.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	we.name = "Ambiente"
	add_child(we)
	sol = DirectionalLight3D.new()                              # sol de media tarde que se cuela entre las copas
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-54.0, -38.0, 0.0)
	sol.light_color = Color(1.0, 0.93, 0.78)
	sol.light_energy = float(perfil.get("luz_sol", 1.0)) * 1.05
	sol.shadow_enabled = perfil.get("sombras", false)
	sol.directional_shadow_max_distance = perfil.get("dist_sombras", 30.0)
	sol.shadow_blur = 1.4
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
	escenario.construir(-sol.global_transform.basis.z if sol.is_inside_tree() else Basis.from_euler(sol.rotation) * Vector3.FORWARD)


func _prohibido(p: Vector3) -> bool:
	return T.prohibido(p.x, p.z) or (escenario != null and escenario.bloqueado(p.x, p.z))


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func suelo_de_pasos(p: Vector3) -> String:
	return T.suelo(p)


func _salida() -> Vector3:
	return T.en_mundo(T.SALIDA_2D)


# Lo que no es 3D en la 2D (la posición de una partida, de la 2D o de antes de una pieza nueva) puede caer en un tronco o
# una roca que la 2D no tenía: el sitio libre más cercano (en espiral), o el camino.
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


# Partidas de la 2D (zona.tscn, lugar 1): la misma casilla en la 3D (modo3d.gd, escena_equivalente).
static func posicion_desde_2d(px: Vector2) -> Vector3:
	return T.desde_2d(px)


# Al revés (con la 2D elegida en Ajustes): la casilla de la 2D donde se puede estar (modo3d.gd, escena_equivalente).
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
	if absf(distancia - _dist_puesta) > 0.0001:                 # la rueda o el pellizco del jugador
		_dist_jugador = clampf(_dist_jugador + distancia - _dist_puesta, DIST_MIN, DIST_MAX)
	var en_alto := T.en_mirador(kael.global_position)
	var incl: float = CAMARA_MIRADOR[0] if en_alto else CAMARA[0]
	var dist: float = CAMARA_MIRADOR[1] if en_alto else clampf(_dist_jugador, CAMARA[1], CAMARA[2])
	var k := 1.0 - exp(-(1.4 if en_alto else 2.2) * delta)
	inclinacion = lerpf(inclinacion, incl, k)
	distancia = lerpf(distancia, dist, k)
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


func _crear_fauna() -> void:
	if en_banco():
		return
	var fauna := load("res://prototipos/fauna_simple.gd")
	for c in [T.lugar("claro") + Vector2(2.5, 1.5), T.lugar("campamento") + Vector2(-2.0, -3.0), Vector2(43.5, 47.0), Vector2(31.0, 13.0)]:
		var conejo = fauna.new()
		conejo.tipo = "conejo"
		conejo.kael = kael
		conejo.radio = 2.5
		conejo.position = T.en_mundo(c)
		add_child(conejo)
	for d in [[T.lugar("claro"), 7.0, 6.0], [D.PUENTES[0][0], 6.5, 7.5], [D.META + Vector2(0, 4), 7.5, 5.5]]:
		var pajaro = fauna.new()
		pajaro.tipo = "pajaro"
		pajaro.radio = d[2]
		pajaro.position = T.en_mundo(d[0]) + Vector3(0, d[1], 0)
		add_child(pajaro)


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
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:   # sus recorridos son los de Pastos Verdes
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
	escenario.poner_hueco(cam.global_position, kael.global_position, HUECO_RADIO)
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
	if d < 2.0:                                                 # un salto (recolocar) no cuenta como andar
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


# ================================================================= encuentros (zona.gd, _paso y _encuentro)

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
	guardar_posicion()                                          # el combate vuelve aquí, al mismo sitio
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

# Los tres cofres de los rincones, con el id que les da la 2D (zona.gd, _id_cofre), y el cofre del hallazgo junto al
# campamento (hallazgos.gd, «cofre»; solo si ya se puede dar, como en la 2D).
func _crear_cofres() -> void:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	var hacia_camino := func(c: Vector2) -> Vector3:
		var q := T.mundo(T.punto_en_camino(c)) - T.mundo(c)
		return q.normalized() if q.length() > 0.1 else Vector3.BACK
	for cf in D.COFRES:
		escenario.crear_cofre(cf[0], cf[1], abiertos.has(cf[0]), hacia_camino.call(cf[1]))
	for h in Hallazgos.cofres_de(INDICE):
		var c := sitio_hallazgo(h[1])
		escenario.crear_cofre(h[0], c, Hallazgos.encontrado(h[0]), hacia_camino.call(c))


static func sitio_hallazgo(cerca_de: String) -> Vector2:
	if cerca_de == "campamento":
		return T.lugar("campamento") + T.GRIMFANG_DESDE_CAMPAMENTO
	return T.lugar(cerca_de) + Vector2(-1.4, 1.0)              # zona.gd, _rincon


func _abrir_cofre(id: String) -> void:
	var cf: Dictionary = escenario.cofres.get(id, {})
	if cf.is_empty() or cf["abierto"]:
		return
	escenario.abrir_cofre(id)
	Sonido.efecto("cofre")
	if Hallazgos.es_hallazgo(id):                               # zona.gd, _abrir_hallazgo
		var textos: Array = Hallazgos.encontrar(id)
		Ex.avisos(self, textos, 0.0)
		Sonido.efecto("tesoro", {"retraso": 0.3})
		_comentar_luego("cofre", 1.2 + 3.6 * textos.size())
		_guardar()
		return
	# zona.gd, _abrir_cofre: monedas, pociones o éter, según el id (el mismo premio que en la 2D); una vez en la partida
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[id] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	Sonido.efecto("tesoro", {"retraso": 0.3})
	_mostrar_aviso("¡Has encontrado %s!" % premio_cofre(id), 2.4)
	_comentar_luego("cofre", 1.2)
	_guardar()


# El premio de un cofre generado (zona.gd, _abrir_cofre, con la semilla de su id): lo da y devuelve su texto.
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
	return T.en_mundo(T.lugar("ruinas") + T.DETALLE_DESDE_RUINAS)


func _sitio_altar() -> Vector3:
	return T.en_mundo(D.META)


# zona.gd, _accion (detalle): su frase; con todos los del Acto I, página nueva en el Diario; y el hallazgo (la Hoja sin
# Nombre), que Kael recoge de entre las raíces.
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
	if libre > desde:
		_coger_hoja(desde)
	elif nuevo:
		_guardar()


func _pagina_diario(escena: String) -> void:
	Sonido.efecto("pagina")
	Sonido.efecto("misterio", {"retraso": 0.2})
	_mostrar_aviso("Nueva página en el Diario: «%s»" % escena, 3.0)


func _coger_hoja(cuando: float) -> void:
	var h: Node3D = escenario.hoja
	if h == null:
		return
	escenario.hoja = null
	var t := h.create_tween()
	t.tween_interval(maxf(cuando, 0.0))
	t.tween_property(h, "position:y", h.position.y + 0.4, 0.35).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(h, "scale", Vector3.ONE * 0.05, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(h.queue_free)


func _examinar_altar() -> void:
	Sonido.efecto("examinar")
	_mostrar_aviso(String(Engine.get_meta("lugar", {}).get("texto", load("res://mapa.gd").LUGARES[INDICE]["texto"])), 3.2)
	Ex.hallazgo_al_examinar(self, INDICE, "altar", 3.6)


func _brazalete() -> void:
	var p := kael.global_position
	var q := _sitio_detalle()
	var dist := _dist_plana(p, q)
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

# [id, sitio, radio, texto del botón]
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

# Al llegar por primera vez en la sesión (la misma clave que la 2D: «@lugar:1») y tras abrir un cofre.
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
# mundo» y dos postes con un farolillo apagado.
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
	letrero.modulate = Color(1.0, 0.96, 0.85)
	letrero.outline_modulate = Color(0.12, 0.16, 0.08, 0.85)
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
	aviso.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	aviso.add_theme_color_override("font_outline_color", Color(0.08, 0.12, 0.06, 0.9))
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
	l.add_theme_color_override("font_color", Color(0.95, 1.0, 0.86))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.14, 0.06, 0.9))
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
