extends "res://prototipos/vista3d.gd"
# Oakhaven en 3D (T-103, D-076): la ciudad de la Oakhaven 2D (ciudad_oakhaven.gd, ciudades/oakhaven.gd), recorrible en
# la exploración 3D, con su mismo trazado (una casilla es un metro) y su mismo progreso. Primer tramo jugable:
#   la Puerta del Sur (Aldric, con su diálogo de siempre) → la Calle Mayor → la Plaza del Tapiz → la Calle del Cuervo →
#   la Taberna del Cuervo Oxidado, que se recorre por dentro, con la posadera y sus servicios (dormir, comer, rumores:
#   ciudades/oakhaven_posada.gd) → y vuelta a la calle y al mapa.
# V12 (12/11), Oakhaven 3D COMPLETA y por defecto con la exploración 3D (la 2D, elegible en Ajustes u «oakhaven2d»;
# modo3d.gd, POR_DEFECTO_2D_ELEGIBLE): la geografía que faltaba (oakhaven/barrios.gd: muralla, Torre de la Campana y
# ronda en alto, la colina con el crematorio y el jardín de urnas, el callejón con la grieta y el Patio de las Velas) y
# todos los sistemas de la 2D con sus mismos datos y claves (oakhaven/vida3d.gd: los vecinos con su diálogo y su rutina,
# las cuatro misiones, los encargos, los 4 cofres, los secretos y las vistas, las piezas, las 5 notas, los detalles de
# canon, los hallazgos, el gremio, la tienda, las parejas y el brazalete). Sin ellos (Engine «oakhaven_sin_vida»), el
# primer tramo de antes.
# Contrato de región (como la Garganta 3D): guardado automático al entrar, al pausar o cerrar la app (guardar_posicion),
# Dialogic, grupo detrás de Kael, salida al mapa y partidas antiguas (posicion_desde_2d, modo3d.escena_equivalente).

const Oak := preload("res://ciudades/oakhaven.gd")
const Posada := preload("res://ciudades/oakhaven_posada.gd")
const Vida := preload("res://ciudades/oakhaven_vida.gd")
const Ciudad := preload("res://zonas3d/oakhaven/ciudad.gd")
const Sala := preload("res://zonas3d/oakhaven/posada3d.gd")
const Distrito := preload("res://zonas3d/oakhaven/distrito.gd")   # V10: el distrito de los oficios, junto a la plaza
# V12, Oakhaven 3D completo (migración región a región): la geografía que faltaba (muralla, torre y ronda en alto, colina,
# crematorio, callejón y Patio de las Velas…) y los sistemas de la 2D (vecinos con rutina, misiones, cofres, piezas,
# notas, gremio, tienda, parejas). Sin ellos (Engine «oakhaven_sin_vida»), el tramo de antes, con el Aldric de primitivas.
const Barrios := preload("res://zonas3d/oakhaven/barrios.gd")
const Vida3D := preload("res://zonas3d/oakhaven/vida3d.gd")
# V12, mundo vivo (interruptor «mundo_vivo_v12», APAGADO): vecinos secundarios chibi con rutinas (oakhaven/mundo_vivo.gd).
const MundoVivo := preload("res://zonas3d/oakhaven/mundo_vivo.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const Progreso := preload("res://progreso.gd")
# AM-8 (19/11): lo que dicen los héroes al explorar (dialogos/comentarios.gd), como en la Oakhaven 2D: al llegar y al
# quedarse quietos; ahí salen también, una sola vez, los que recuerdan una decisión [P]. Abajo a la derecha; no a la vez
# que un aviso (comparten altura) y las voces callan mientras se ve uno.
const Comentarios := preload("res://dialogos/comentarios.gd")
const LLEGADA_COMENTARIO := 2.5           # s tras entrar
const QUIETO_COMENTARIO := 14.0          # s sin moverse (como en la 2D y en Pastos Verdes 3D)
const PAUSA_COMENTARIOS := 45.0          # s de pausa tras un comentario por estar quietos

const INDICE := 0                          # lugar del mapa (mapa.gd; modo3d.OAKHAVEN)
const INICIO := Vector3(40.0, 0.0, 53.2)   # ciudades/oakhaven.gd, INICIO (40, 53.5)
const SALIDA := Vector3(40.0, 0.0, 55.6)   # «Mapa del mundo»: el borde sur de la Puerta del Sur
const RADIO_SALIDA := 1.3
const ARMAR_SALIDA := 2.5
const ALDRIC := Vector3(38.3, 0.0, 49.5)   # 2D (40, 49.5): a un lado del arco, para no tapar la puerta
const PUERTA_TABERNA := Vector3(16.0, 0.0, 25.9)   # en la Calle del Cuervo, ante la puerta (fachada sur de la taberna)
const RADIO_ACCION := 1.8
const BARKS_DIST := 7.0                    # a menos de esto, la taberna «se oye» (oakhaven_vida.gd, VOCES)
# Zonas de cámara: [x0, x1, z0, z1, inclinación, distancia mínima, distancia máxima]
const CAMARA_CIUDAD := [52.0, 12.0, 19.0]       # más desde arriba: las casas del sur no tapan la calle
const CAMARA_POSADA := [52.0, 9.0, 12.0]
const CAMARA_RONDA := [62.0, 9.0, 11.0]          # V12: en el adarve de la ronda (en alto)

var brillo_sin_sombras := 1.17              # V12: vista3d.gd, el perfil bajo sin sombras (medido alto/bajo ×1,18)
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var mat: Materiales
var ciudad                                 # zonas3d/oakhaven/ciudad.gd
var sala                                   # zonas3d/oakhaven/posada3d.gd
var distrito                               # zonas3d/oakhaven/distrito.gd (null sin él)
var barrios                                # V12: zonas3d/oakhaven/barrios.gd (null sin él)
var vida                                   # V12: zonas3d/oakhaven/vida3d.gd (null sin él)
var vivo                                   # V12: zonas3d/oakhaven/mundo_vivo.gd (null con el interruptor apagado)
var _veces_posadera := 0
var grupo: Node3D
var capa_ui: CanvasLayer
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var panel_servicios: PanelContainer
var cerca := ""
var en_posada := false
var saliendo := false
var cambiando := false                    # un fundido en marcha (entrar o salir de la posada, dormir)
var franja := "anochecer"                  # oakhaven_vida.gd: la hora azul; tras dormir, «manana»
var voz_dichos := {}
var _t_voz := 0.0
var _veces_aldric := 0
var _bloqueo := 0.0
var salida := {"armada": false}
var _dist_jugador := 18.0
var _dist_puesta := 18.0
var dialogo_actual := ""
var _llegada_t := LLEGADA_COMENTARIO      # AM-8: > 0, lo que falta para el comentario de llegada
var _quieto_t := 0.0
var _pos_quieto := Vector3.INF


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	mat = Materiales.new(perfil)
	super()
	info.visible = false
	_crear_interfaz()
	if Engine.has_meta("oakhaven_sin_vida"):
		_crear_aldric()                                        # el tramo de antes (T-103)
	else:
		vida = Vida3D.crear(self, barrios, mat)
		if MundoVivo.activado():
			vivo = MundoVivo.crear(self)
	_lugar_oakhaven()
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and Engine.get_meta("pos_3d_lugar", -1) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	_colocar_kael(Engine.get_meta("pos_3d") if vuelve else INICIO)
	en_posada = Sala.en_sala(kael.global_position)
	_crear_grupo()
	salida["armada"] = _dist_plana(kael.global_position, SALIDA) > ARMAR_SALIDA
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
	Engine.set_meta("zona", "ciudad")
	_sonido_3d()
	if vida != null:                                           # V12: lo que suena en la ciudad 2D, en su sitio
		Sonido.fuente_3d(self, "plaza_murmullo", Vector3(Oak.PLAZA.x, 1.0, Oak.PLAZA.y))
		Sonido.fuente_3d(self, "fuente_plaza", Vector3(Oak.PLAZA.x, 0.8, Oak.PLAZA.y))
		Sonido.fuente_3d(self, "mercado_murmullo", Vector3(54.0, 1.0, 29.5))
		Sonido.efecto("campana", {"retraso": 1.5})
	_titulo_zona("Oakhaven")
	if not en_banco():
		Progreso.guardar(scene_file_path)                      # guardado automático al entrar (como zona.gd)


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


# V12: la tienda y lo demás que mira el lugar (tienda.gd, Engine «lugar») saben que esto es Oakhaven aunque se entre sin
# pasar por el mapa (una partida, una prueba).
func _lugar_oakhaven() -> void:
	var l = Engine.get_meta("lugar", {})
	if l is Dictionary and int(l.get("indice", -1)) == INDICE:
		return
	var m: Dictionary = load("res://mapa.gd").LUGARES[INDICE]
	Engine.set_meta("lugar", {"indice": INDICE, "nombre": m["nombre"], "tipo": m["tipo"], "zona": "ciudad", "texto": m["texto"]})


# ================================================================= mundo

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR                 # la cámara de juego no ve el cielo: la hora azul, índigo
	env.background_color = Color(0.21, 0.19, 0.33)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.54, 0.70)          # el AMBIENTE de la 2D, algo más cálido (los faroles y las ventanas)
	env.ambient_light_energy = 0.68
	env.fog_enabled = true
	env.fog_light_color = Color(0.30, 0.33, 0.50)
	env.fog_density = 0.008
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.14
	env.adjustment_contrast = 1.08
	env.tonemap_exposure = perfil.get("exposicion", 0.9 if perfil.get("sombras", false) else 1.0)
	if perfil.get("brillo_bloom", nombre_perfil == "alto"):   # el resplandor de los faroles (perfil alto)
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_strength = 0.9
		env.glow_bloom = 0.03
		env.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var luz := DirectionalLight3D.new()                        # el último resto de luz, fría, desde el oeste-suroeste
	luz.rotation_degrees = Vector3(-38.0, -112.0, 0.0)
	luz.light_color = Color(0.72, 0.76, 1.0)
	luz.light_energy = perfil.get("luz_sol", 1.0) * 0.7
	luz.shadow_enabled = perfil.get("sombras", false)
	luz.directional_shadow_max_distance = perfil.get("dist_sombras", 40.0)
	luz.shadow_blur = 1.5
	luz.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(luz)


func _crear_escenario() -> void:
	ciudad = Ciudad.new(self, mat, perfil, nombre_perfil)
	ciudad.construir()
	distrito = Distrito.crear(self, ciudad, mat, perfil, nombre_perfil)
	if not Engine.has_meta("oakhaven_sin_vida"):
		barrios = Barrios.crear(self, ciudad, mat, perfil, nombre_perfil)
	sala = Sala.new(self, mat, perfil)
	sala.construir()


# Por dónde se anda: en la ciudad, dentro del trazado y fuera de los edificios; en la posada, dentro de la sala y fuera
# de los muebles.
func _prohibido(p: Vector3) -> bool:
	if en_posada:
		if not Sala.en_sala(p):
			return true
		var l := p - Sala.ORIGEN
		for r in sala.bloqueos:
			if (r as Rect2).grow(0.3).has_point(Vector2(l.x, l.z)):
				return true
		return false
	if p.x < 0.8 or p.x > Oak.TAM.x - 0.8 or p.z < 0.8 or p.z > Oak.TAM.y - 0.1:
		return true
	if barrios != null:                                        # V12: en alto, solo el adarve de la ronda
		if barrios.prohibido(p):
			return true
		if vivo != null and vivo.ocupa(p):                     # V12, mundo vivo: no se atraviesa a nadie
			return true
		if Barrios.en_alto(p):
			return false
	return ciudad.bloqueado(p.x, p.z, 0.3)


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Una posición de la Oakhaven 2D (en píxeles, «pos_zona») → su sitio en la 3D: la misma casilla (una casilla es un metro)
# o, si cae dentro de un edificio, la plaza. Lo usa modo3d.escena_equivalente para las partidas guardadas en la 2D.
static func posicion_desde_2d(px: Vector2) -> Vector3:
	var c := px / 64.0                                          # zona.gd: T = 64 píxeles por casilla
	var p := Vector3(clampf(c.x, 1.0, Oak.TAM.x - 1.0), 0.0, clampf(c.y, 1.0, Oak.TAM.y - 0.5))
	var en_ronda: bool = Barrios.RONDA_ALTA.has_point(Vector2(p.x, p.z))
	if Ciudad.lugar_en(p.x, p.z) == "" and not en_ronda:
		return Vector3(Oak.PLAZA.x, 0.0, Oak.PLAZA.y + 3.0)       # no es una calle (un edificio, un jardín): la plaza
	if en_ronda:                                              # V12: la ronda va en alto (y su adarve, algo más adentro)
		return Vector3(clampf(p.x, Barrios.ADARVE.position.x + 0.4, Barrios.ADARVE.end.x - 0.4), Barrios.ALTO_RONDA,
			clampf(p.z, Barrios.ADARVE.position.y + 0.4, Barrios.ADARVE.end.y - 0.4))
	p.y = Barrios.altura(p.x, p.z)                            # V12: el altozano de la colina y su subida
	return p


# V12 (al revés): una posición de la 3D → su casilla en la Oakhaven 2D (en píxeles, «pos_zona»). Lo usa
# modo3d.escena_equivalente para una partida guardada en la 3D con la 2D elegida: el mismo trazado, la misma casilla (si
# allí no se puede estar en la 2D, la 2D pone a Kael en la Puerta del Sur).
static func posicion_a_2d(p: Vector3) -> Vector2:
	if Sala.en_sala(p):
		p = PUERTA_TABERNA + Vector3(0, 0, 0.5)
	return Vector2(clampf(p.x, 1.0, Oak.TAM.x - 1.0), clampf(p.z, 1.0, Oak.TAM.y - 0.5)) * 64.0


# ================================================================= Kael, cámara y grupo

func _colocar_kael(p: Vector3) -> void:
	if barrios != null and not Sala.en_sala(p) and not Barrios.en_alto(p):
		p.y = Barrios.altura(p.x, p.z)                         # V12: en la colina, sobre el altozano (no debajo)
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	var z: Array = CAMARA_POSADA if Sala.en_sala(p) else _zona_camara(p)
	inclinacion = z[0]
	distancia = clampf(_dist_jugador, z[1], z[2])
	_dist_puesta = distancia
	_colocar_camara(1.0)


# V12: en la ronda, más cerca y desde más arriba (a 52° y 12-19 m la cámara quedaba dentro de la Torre de la Campana).
func _zona_camara(p: Vector3) -> Array:
	if barrios != null and Barrios.en_alto(p):
		return CAMARA_RONDA
	return distrito.camara(p, CAMARA_CIUDAD) if distrito != null else CAMARA_CIUDAD


func _camara_zona(delta: float) -> void:
	if absf(distancia - _dist_puesta) > 0.0001:
		_dist_jugador = clampf(_dist_jugador + distancia - _dist_puesta, DIST_MIN, DIST_MAX)
	var z: Array = CAMARA_POSADA if en_posada else _zona_camara(kael.global_position)
	var k := 1.0 - exp(-2.2 * delta)
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
		kael.reposo()


func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return cambiando or (panel_servicios != null and panel_servicios.visible) or (dg != null and dg.current_timeline != null) \
		or (distrito != null and distrito.ocupado()) or (vida != null and vida.ocupado())


# El panel del prototipo trae bancos de medida de Pastos Verdes: aquí solo CAL y RND.
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
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if ciudad != null:
		ciudad.animar(delta)
	if kael == null:
		return
	if en_banco():
		super(delta)
		return
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_quitar_comentarios()                         # AM-8: un diálogo o un panel lo quita
		_quieto_t = 0.0
		_colocar_camara(1.0 - exp(-suavizado * delta))
		_oclusion()
		return
	_camara_zona(delta)
	super(delta)
	if saliendo:
		return
	var p := kael.global_position
	if not en_posada:
		var ds := _dist_plana(p, SALIDA)
		if not salida["armada"]:
			salida["armada"] = ds > ARMAR_SALIDA
		elif ds < RADIO_SALIDA:
			_salir()
			return
		_voces(delta)
	_comentarios(delta)
	_comprobar_cerca()


# Las voces de la ciudad (oakhaven_vida.gd): cerca de la taberna se oye a la clientela, una frase cada pocos segundos.
func _voces(delta: float) -> void:
	_t_voz -= delta
	if _t_voz > 0.0 or _hay_comentario():      # AM-8: no encima de un comentario
		return
	for v in Vida.VOCES:
		var c: Vector2 = v["casilla"]
		if _dist_plana(kael.global_position, Vector3(c.x, 0, c.y)) < BARKS_DIST:
			var texto: String = Vida.frase(v["id"], franja, voz_dichos)
			if texto != "":
				voz_dichos[texto] = true
				_mostrar_aviso("%s: «%s»" % [v["nombre"], texto], Vida.duracion(texto))
				_t_voz = Vida.duracion(texto) + 4.0
				return
	# V12: los vecinos también dicen algo al pasar cerca (oakhaven_vida.gd, como en la 2D), uno cada vez y con su pausa
	if vida != null and (vida.avisos.is_empty()):
		for e in vida.vecinos_cerca(kael.global_position, Vida.RADIO):
			var texto: String = Vida.frase(e[0], franja, voz_dichos)
			vida.callar(e[0], Vida.PAUSA_QUIEN)
			if texto != "":
				voz_dichos[texto] = true
				_mostrar_aviso("%s: «%s»" % [Oak.npc(e[0]).get("corto", e[0]), texto], Vida.duracion(texto))
				_t_voz = Vida.duracion(texto) + Vida.PAUSA
				return
	_t_voz = 1.0


# AM-8 (19/11): los comentarios de los héroes (dialogos/comentarios.gd). La llegada, una vez a los 2,5 s, solo fuera de
# la posada y si Kael ya ha salido de Oakhaven (cond:kael_salio; revisión 19/11); quieto, tras 14 s sin moverse fuera de
# la posada (moverse reinicia la cuenta) y luego una pausa.
func _comentarios(delta: float) -> void:
	if _llegada_t > 0.0:
		_llegada_t -= delta
		if _llegada_t <= 0.0:
			if en_posada or not Oak.cumple("cond:kael_salio"):
				pass                                 # revisión 19/11: dentro de la posada, o al empezar a jugar (Kael aún
				                                     # no ha salido de Oakhaven, pv_02), no hay «llegada»: no se pide
			elif _hay_hueco():
				_comentar("llegar:oakhaven")          # (si no toca nada, no se insiste)
			else:
				_llegada_t = 0.5                     # sin hueco (un aviso en pantalla): se intenta enseguida
	var p := kael.global_position
	var movido := _pos_quieto == Vector3.INF or Vector2(p.x - _pos_quieto.x, p.z - _pos_quieto.z).length() > 0.002
	_pos_quieto = p
	if _quieto_t < 0.0:                              # pausa tras un comentario por estar quietos
		_quieto_t = minf(_quieto_t + delta, 0.0)
		return
	if movido or destino != null or movimiento != "" or en_posada:
		_quieto_t = 0.0
		return
	_quieto_t += delta
	if _quieto_t >= QUIETO_COMENTARIO:
		if not _hay_hueco():                         # un aviso en pantalla: se vuelve a mirar en 1 s
			_quieto_t = QUIETO_COMENTARIO - 1.0
		else:
			_quieto_t = -PAUSA_COMENTARIOS if _comentar("quieto") else 0.0


# Enseña un comentario si toca y hay hueco (nada abierto, ningún otro comentario ni aviso). Devuelve si salió.
func _comentar(momento: String) -> bool:
	if not _hay_hueco():
		return false
	var c := Comentarios.elegir(momento)
	if c.is_empty():
		return false
	Comentarios.mostrar(capa_ui, c)
	return true


func _hay_hueco() -> bool:
	if capa_ui == null or ocupado() or saliendo or cambiando or _hay_comentario():
		return false
	return aviso.modulate.a <= 0.05


func _hay_comentario() -> bool:
	if capa_ui == null:
		return false
	for n in capa_ui.get_children():
		if n.name.begins_with("comentario") and not n.is_queued_for_deletion():
			return true
	return false


func _quitar_comentarios() -> void:
	if capa_ui == null:
		return
	for n in capa_ui.get_children():
		if n.name.begins_with("comentario"):
			n.queue_free()


func _piezas_al_alcance() -> Array:
	if en_posada:
		return [["posadera", Sala.ORIGEN + Sala.MOSTRADOR, 1.6, "Hablar con la posadera"],
			["salir_posada", Sala.ORIGEN + Sala.PUERTA - Vector3(0, 0, 0.6), 1.3, "Salir a la calle"]]
	var r: Array = [["posada", PUERTA_TABERNA, RADIO_ACCION, "Entrar en la posada"]]
	if vida == null:
		r.append(["aldric", ALDRIC, 2.2, "Hablar con Aldric"])
	else:
		r.append_array(vida.piezas())                          # V12: vecinos, cofres, piezas, notas, detalles…
		if vivo != null:
			r.append_array(vivo.piezas())                      # V12, mundo vivo: los vecinos secundarios
	return r + (distrito.piezas() if distrito != null else [])


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	for pz in _piezas_al_alcance():
		var d := _dist_plana(kael.global_position, pz[1])
		if absf(kael.global_position.y - (pz[1] as Vector3).y) > Vida3D.ALTO_ALCANCE:
			continue                                           # V12: lo de la ronda no se usa desde abajo (ni al revés)
		if d < pz[2] and d < mejor:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != ""


func _unhandled_input(ev: InputEvent) -> void:
	if ocupado():
		if panel_servicios != null and panel_servicios.visible and ev.is_action_pressed("ui_cancel"):
			_cerrar_servicios()
			get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado():
		return
	_bloqueo = 0.4
	match cerca:
		"aldric" when vida == null:
			_hablar_aldric()
		"posada":
			_entrar_posada()
		"salir_posada":
			_salir_posada()
		"posadera":
			_abrir_servicios()
		_:
			if vivo != null and vivo.atiende(cerca):
				vivo.accion(cerca)
			elif vida != null and vida.atiende(cerca):
				vida.accion(cerca)                         # V12: lo de la ciudad 2D (vida3d.gd)
			elif distrito != null:
				distrito.accion(cerca)                     # los oficios y el pozo del distrito


# ================================================================= Aldric (su diálogo de siempre)

func _crear_aldric() -> void:
	var raiz := Node3D.new()
	raiz.name = "Aldric"
	raiz.position = ALDRIC
	add_child(raiz)
	var armadura := mat.liso(Color(0.62, 0.64, 0.68), 0.45, 0.6)
	for d in [[CapsuleMesh.new(), Vector3(0, 0.75, 0), armadura], [SphereMesh.new(), Vector3(0, 1.55, 0), mat.liso(Color(0.92, 0.78, 0.66), 0.9)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = d[0]
		if mi.mesh is CapsuleMesh:
			(mi.mesh as CapsuleMesh).radius = 0.3
			(mi.mesh as CapsuleMesh).height = 1.45
		else:
			(mi.mesh as SphereMesh).radius = 0.18
			(mi.mesh as SphereMesh).height = 0.36
		mi.material_override = d[2]
		mi.position = d[1]
		raiz.add_child(mi)
	var capa := BoxMesh.new()                                     # la capa azul de la guardia
	capa.size = Vector3(0.62, 1.1, 0.06)
	var mc := MeshInstance3D.new()
	mc.mesh = capa
	mc.material_override = mat.liso(Color(0.20, 0.28, 0.52), 1.0)
	mc.position = Vector3(0, 0.95, -0.3)
	raiz.add_child(mc)
	var lanza := CylinderMesh.new()
	lanza.top_radius = 0.02
	lanza.bottom_radius = 0.025
	lanza.height = 2.4
	var ml := MeshInstance3D.new()
	ml.mesh = lanza
	ml.material_override = mat.liso(Color(0.40, 0.30, 0.20), 0.9)
	ml.position = Vector3(0.38, 1.2, 0.05)
	raiz.add_child(ml)
	var cuerpo := StaticBody3D.new()
	raiz.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.4
	cil.height = 1.8
	col.shape = cil
	col.position.y = 0.9
	cuerpo.add_child(col)


func _hablar_aldric() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	var ruta: String = Oak.dialogo_de("aldric", _veces_aldric)
	if dg == null or ruta == "" or dg.current_timeline != null:
		_mostrar_aviso("Aldric: «%s»" % Vida.frase("aldric", franja, voz_dichos))
		return
	_veces_aldric += 1
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = ruta
	dg.start(ruta)


func _al_terminar_dialogo() -> void:
	dialogo_actual = ""
	_bloqueo = 0.4


# ================================================================= la posada

func _entrar_posada() -> void:
	await _fundir(func():
		en_posada = true
		_colocar_kael(Sala.ORIGEN + Sala.ENTRADA)
		if grupo != null:
			grupo.colocar(Vector3.BACK))
	Sonido.efecto("puerta_abre")
	guardar_posicion()


func _salir_posada() -> void:
	await _fundir(func():
		en_posada = false
		_colocar_kael(PUERTA_TABERNA + Vector3(0, 0, 0.5))
		if grupo != null:
			grupo.colocar(Vector3.BACK))
	guardar_posicion()


# Fundido a negro, el cambio, y vuelta.
func _fundir(cambio: Callable, espera := 0.15) -> void:
	cambiando = true
	_parar_kael()
	boton_accion.visible = false
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.35)
	await t.finished
	cambio.call()
	await get_tree().create_timer(espera).timeout
	var t2 := create_tween()
	t2.tween_property(fundido, "color:a", 0.0, 0.35)
	await t2.finished
	cambiando = false


func _abrir_servicios() -> void:
	_parar_kael()
	boton_accion.visible = false
	for n in panel_servicios.get_child(0).get_children():
		n.queue_free()
	var caja: VBoxContainer = panel_servicios.get_child(0)
	var titulo := Label.new()
	titulo.text = "La posadera"
	titulo.add_theme_font_size_override("font_size", 28)
	caja.add_child(titulo)
	var primero: Button = null
	if vida != null:                                         # V12: hablar con ella (sus favores, como en la 2D)
		var bh := Button.new()
		bh.text = "Hablar"
		bh.add_theme_font_size_override("font_size", 24)
		bh.custom_minimum_size = Vector2(420, 56)
		bh.set_meta("servicio", "hablar")
		bh.pressed.connect(_hablar_posadera)
		caja.add_child(bh)
		primero = bh
	for s in Posada.servicios():
		var b := Button.new()
		var precio: int = int(s.get("precio", 0))
		b.text = "%s%s" % [s.get("nombre", s["id"]), (" (%d)" % precio) if precio > 0 else ""]
		b.add_theme_font_size_override("font_size", 24)
		b.custom_minimum_size = Vector2(420, 56)
		b.set_meta("servicio", s["id"])
		b.pressed.connect(_servicio.bind(s["id"]))
		caja.add_child(b)
		if primero == null:
			primero = b
	var adios := Button.new()
	adios.text = "Adiós"
	adios.add_theme_font_size_override("font_size", 24)
	adios.custom_minimum_size = Vector2(420, 56)
	adios.set_meta("servicio", "adios")
	adios.pressed.connect(_cerrar_servicios)
	caja.add_child(adios)
	panel_servicios.visible = true
	if primero != null:
		primero.grab_focus()


func _cerrar_servicios() -> void:
	panel_servicios.visible = false
	_bloqueo = 0.4


# V12: «Hablar» con la posadera (ciudades/oakhaven.gd: lo de «Tres favores para el Cuervo» primero; si no, se turnan).
func _hablar_posadera() -> String:
	_cerrar_servicios()
	var r: String = vida.hablar_posadera(_veces_posadera) if vida != null else ""
	_veces_posadera += 1
	return r


# Un servicio de la posadera (ciudades/oakhaven_posada.gd): dormir, comer o un rumor. Devuelve lo que pasó (las pruebas).
func _servicio(id: String) -> Dictionary:
	var r: Dictionary = {}
	match id:
		"dormir":
			r = Posada.dormir()
			if r.get("ok", false):
				_cerrar_servicios()
				await _fundir(func():
					franja = "manana"                 # ha amanecido: los vecinos lo notan (oakhaven_vida.gd)
					if vida != null:                  # V12: y van a su sitio de la mañana (la misma hora que la 2D)
						vida.franja_t = 0.0
						vida.poner_franja("manana", true)
					voz_dichos.clear(), 1.0)
				_mostrar_aviso(r["texto"], 3.0)
				var dg = get_node_or_null("/root/Dialogic")
				var escena: String = r.get("escena", "")
				if dg != null and escena != "" and ResourceLoader.exists(escena):
					dialogo_actual = escena
					dg.start(escena)
			else:
				_mostrar_aviso(r["texto"], 2.6)
		"comer":
			r = Posada.comer()
			_mostrar_aviso(r["texto"], 2.6)
		"rumores":
			r = Posada.rumor()
			_mostrar_aviso("La posadera: «%s»" % r["texto"], Vida.duracion(r["texto"]) + 1.0)
		_:
			return {}
	if not en_banco():
		guardar_posicion()
		Progreso.guardar(scene_file_path)
	return r


# ================================================================= guardado y salida

# Recursos la llama al pausar o cerrar la app (y antes de guardar). Dentro de la posada se guarda la puerta de la calle:
# al volver, se aparece fuera, ante la taberna.
func guardar_posicion() -> void:
	var p: Vector3 = (PUERTA_TABERNA + Vector3(0, 0, 0.5)) if en_posada else kael.global_position
	Engine.set_meta("pos_3d", p)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_3d_ok", false)                        # la próxima vez se entra por la Puerta del Sur
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena(load("res://modo3d.gd").salida_al_mapa(INDICE))   # V12, mapamundi 3D: apagado, el mapa de siempre


func _sonido_3d() -> void:
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, suelo_de_pasos)


func suelo_de_pasos(p: Vector3) -> String:
	if Sala.en_sala(p):
		return "madera"
	if Barrios.en_alto(p):
		return "piedra"                                       # V12: el adarve de la ronda
	var l := Ciudad.lugar_en(p.x, p.z)
	return "piedra" if l != "" and not l in ["colina", "raices", "jardin_urnas"] else "hierba"


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
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	aviso.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.18, 0.9))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	panel_servicios = PanelContainer.new()
	panel_servicios.position = Vector2(40, 130)           # a la izquierda: la posadera, en el centro, se ve
	panel_servicios.visible = false
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	panel_servicios.add_child(caja)
	capa_ui.add_child(panel_servicios)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


var _tween_aviso: Tween


func _mostrar_aviso(texto: String, segundos := 1.8) -> void:
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
	l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	l.add_theme_color_override("font_outline_color", Color(0.10, 0.08, 0.16, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	l.modulate.a = 0.0
	capa_ui.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.6)
	t.tween_interval(1.6)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.tween_callback(l.queue_free)
