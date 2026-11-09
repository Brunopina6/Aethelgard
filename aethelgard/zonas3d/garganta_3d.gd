extends "res://prototipos/vista3d.gd"
# La Garganta del Diablo en 3D (capítulo 4): la mazmorra de la Garganta 2D (garganta.gd), con su misma estructura y su
# mismo progreso, en la exploración 3D. Diseño completo: docs/diseno/garganta_3d.md.
#
# Solo se llega con la exploración 3D activa y con el argumento «garganta3d» (modo3d.gd, EN_PRUEBAS): sin él, el mapa
# sigue llevando a la Garganta 2D, que se queda como alternativa.
#
# La garganta corre de sur a norte, por donde mira la cámara (que nunca gira): los muros quedan a los lados y el abismo
# delante. El trazado (zonas3d/garganta/trazado.gd) conserva las piezas de la 2D en el mismo orden:
#   arriba (cornisa del oeste): P1 entrada y guardado → P2 puentes colgantes (muchos encuentros) → P3 guardado, puente
#     levadizo (levantado) y puerta sellada → P4 la arena de Gorthor (combate fijo «garganta_gorthor»);
#   abajo (cornisa del este): P5 escalera de la presa y ascensor → P6 bajada al nido (combate fijo «garganta_nido» y el
#     cofre raro, que se ve brillar desde los puentes) → P7 la palanca → P8 la grieta oculta (pilar del peregrino).
# La palanca abre la puerta, baja el levadizo de P7 a P3 y enciende el ascensor de P5 a la entrada (como en la 2D).
# Contrato de zona (zona.gd y Pastos Verdes 3D): encuentros por pasos con progreso.gd y el ritmo de la 2D, combate con
# vuelta, guardado automático al entrar, puntos de guardado, al pausar o cerrar la app (guardar_posicion) y salida al
# mapa. El progreso usa los mismos identificadores que la 2D: mazmorras["garganta"]["palanca"], el cofre «2_1984_3238»,
# los combates «garganta_nido» y «garganta_gorthor» y los detalles «garganta_puentes» y «garganta_pilar»: una partida
# con la Garganta 2D avanzada sigue valiendo aquí (y al revés).
# Sonido: suenan los mismos efectos que en la 2D (palanca, puente, ascensor, cofre, puerta, guardado…); el puente que
# baja y la puerta que se abre, desde donde están. El sonido 3D (_sonido_3d, T-083 tanda 3): se escucha desde Kael, los
# pasos según el suelo (también los de Lya y Garon), la cascada y el viento del abismo en el espacio, las gotas en la
# roca y el eco de la garganta.

const T := preload("res://zonas3d/garganta/trazado.gd")
const Escenario := preload("res://zonas3d/garganta/escenario.gd")
const Piezas := preload("res://zonas3d/garganta/piezas.gd")
const Materiales := preload("res://zonas3d/garganta/materiales.gd")
const Progreso := preload("res://progreso.gd")

const INDICE := 2                        # lugar del mapa (mapa.gd, INDICE_GARGANTA; modo3d.GARGANTA)
const NOMBRE := "garganta"               # progreso.gd: mazmorras["garganta"], nivel de la zona y encuentros
const ZONA := "garganta"                 # combate: fondo y nivel (como garganta.gd)
const LONG_PASO := 0.5                   # metros por «paso» (como Pastos Verdes 3D)
const PASOS_MIN := 40
const PROB_ENCUENTRO := 0.012
const RADIO_SALIDA := 1.3
const ARMAR_SALIDA := 2.5
const RADIO_PIEZA := 2.0                 # metros para usar una pieza o examinar
# El cofre raro del nido, con el identificador de la 2D: zona.gd, _id_cofre(COFRE_NIDO * T) con COFRE_NIDO = (31, 50.6)
# casillas y T = 64 px → «2_1984_3238». Así el que se abrió en la 2D sigue abierto aquí.
const ID_COFRE_NIDO := "2_1984_3238"
const ID_NIDO := "garganta_nido"
const ID_GORTHOR := "garganta_gorthor"
const GRUPO_NIDO := 6                    # combate.gd, GRUPOS[6]: el gólem de ámbar y un Grimfang
const GRUPO_GORTHOR := 5                 # combate.gd, GRUPOS[5]: Gorthor el Devorador
const ID_PUENTES := "garganta_puentes"   # progreso.gd, DETALLES[2]
const ID_PILAR := "garganta_pilar"
const BOTONES_BANCO := ["PRUEBA", "DIAG", "TOPE", "ARB"]   # sus recorridos son los de Pastos Verdes: aquí no sirven
const CAIDA_LEVADIZO := 2.6              # segundos que tarda en bajar

var perfil: Dictionary = {}
var nombre_perfil := "alto"
var mat: Materiales
var esc                                  # zonas3d/garganta/escenario.gd
var piezas                               # zonas3d/garganta/piezas.gd
var grupo: Node3D                        # zonas3d/grupo_3d.gd (null si no sale nadie)
var pasos := 0
var saliendo := false
var salida := {"pos": T.SALIDA, "armada": false}
var fundido: ColorRect
var aviso: Label
var boton_accion: Button
var cerca := ""                          # la pieza al alcance: "guardado_1", "palanca", "cofre", "detalle_p2"…
var levadizo := {}
var puerta := {}
var ascensor := {}
var palanca := {}
var cofre := {}
var guardados: Array = []                # los altares (para el destello al guardar)
var golem: Node3D
var gorthor: Node3D
var viajando := false                    # el ascensor (fundido a negro)
var tirando := false                     # la palanca: el puente baja y la cámara lo mira
var _recorrido := 0.0
var _ultima := Vector3.ZERO
var _bloqueo := 0.0                      # tras una acción, la misma pulsación no hace otra
var _armado_nido := true
var _armado_gorthor := true
var _vuelta = null                       # combate fijo en marcha: al volver, aquí (un poco antes del disparo)
var _dist_jugador := 20.0                # la distancia que eligió el jugador (rueda, pellizco, + y −)
var _dist_puesta := 20.0
var _desvio := Vector3.ZERO              # la cámara mira un momento hacia otro sitio (el puente que baja)
var _silencio_dicho := false             # «La arena guarda silencio…», una vez por visita


func _ready() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	mat = Materiales.new(perfil)
	super()                              # ambiente, escenario, Kael (en el origen), cámara y panel de vista3d.gd
	info.visible = false                 # la ayuda de teclas del prototipo no es para el juego
	_crear_interfaz()
	_crear_piezas()
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and Engine.get_meta("pos_3d_lugar", -1) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	_colocar_kael(Engine.get_meta("pos_3d") if vuelve else T.INICIO)
	_crear_grupo()
	_ultima = kael.global_position
	salida["armada"] = _dist_plana(kael.global_position, T.SALIDA) > ARMAR_SALIDA
	_armado_nido = not _en_nido(kael.global_position)        # al volver de perder, no se repite hasta salir y entrar
	_armado_gorthor = not _en_arena(kael.global_position)
	Engine.set_meta("zona", ZONA)
	_sonido_3d()
	_titulo_zona("Garganta del Diablo")
	if not en_banco():
		Progreso.guardar(scene_file_path)                      # guardado automático al entrar (como zona.gd)


func en_banco() -> bool:
	return Engine.has_meta("banco_proto")


# ================================================================= mundo

func _crear_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR                # la cámara de juego no ve el cielo (biblia §7.1)
	env.background_color = Color(0.16, 0.16, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.56, 0.76)          # relleno frío: lo que no toca la luz del cielo, azulado
	env.ambient_light_energy = 0.5
	# Bruma ligera por distancia. La del abismo (más honda, más azul y, al fondo, de ámbar) la pinta el sombreado de la
	# roca y las capas de niebla: la niebla de altura de Godot apagaba el resplandor del fondo (capturas del 09/11).
	env.fog_enabled = true
	env.fog_light_color = Color(0.34, 0.35, 0.47)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.12
	env.tonemap_exposure = perfil.get("exposicion", 0.8 if perfil.get("sombras", false) else 1.0)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED if not perfil.get("reflejo_cielo", true) \
		else Environment.REFLECTION_SOURCE_BG
	if perfil.get("brillo_bloom", nombre_perfil == "alto"):      # el resplandor del ámbar y del fuego (perfil alto)
		env.glow_enabled = true
		env.glow_intensity = 0.55
		env.glow_strength = 0.9
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()                        # la luz del cielo entra por la rendija desde el este
	sol.rotation_degrees = Escenario.SOL_GIRO
	sol.light_color = Color(1.0, 0.96, 0.9)
	sol.light_energy = perfil.get("luz_sol", 1.25)
	sol.shadow_enabled = perfil.get("sombras", false)
	sol.directional_shadow_max_distance = perfil.get("dist_sombras", 40.0)
	sol.shadow_blur = 1.5
	match int(perfil.get("sombra_tramos", 2)):
		1:
			sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		2:
			sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		_:
			sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if sol.shadow_enabled:
		RenderingServer.directional_shadow_atlas_set_size(int(perfil.get("sombra_res", 4096)), true)
	add_child(sol)


func _crear_escenario() -> void:
	esc = Escenario.new(self, mat, perfil, nombre_perfil)
	esc.construir()


func _crear_piezas() -> void:
	piezas = Piezas.new(self, mat, esc, perfil)
	var tirada := palanca_bajada()
	# P2: los dos puentes colgantes; sus pilares llevan el anillo, más gastado cuanto más lejos
	piezas.puente_colgante(T.PUENTES[0][0], T.PUENTES[0][1], 0.0, 0.3)
	piezas.puente_colgante(T.PUENTES[1][0], T.PUENTES[1][1], 0.5, 0.8, 1.7)   # se mece a destiempo del primero
	# guardados, palanca, ascensor, levadizo y puerta
	guardados = [piezas.guardado(T.GUARDADO_1), piezas.guardado(T.GUARDADO_2)]
	palanca = piezas.palanca(T.PALANCA, tirada)
	ascensor = piezas.ascensor(tirada)
	if tirada:                                         # la cesta espera en la estación más cercana a Kael
		ascensor["cesta"].position = Piezas.posicion_cesta(ascensor["cable"], 0.0)
	levadizo = piezas.levadizo(tirada)
	if tirada:
		piezas.soltar_cadenas(levadizo)
	puerta = piezas.puerta(tirada)
	# el nido: el cofre raro y, mientras no se gane el combate, el gólem dormido
	piezas.nido(T.NIDO_CENTRO)
	cofre = piezas.cofre(T.COFRE_NIDO, cofre_abierto())
	if not Progreso.ganado(ID_NIDO):
		golem = piezas.golem(T.GOLEM)
	# la arena: Gorthor espera ante su trono (después, la arena guarda silencio y los braseros están fríos)
	var vivo := not Progreso.ganado(ID_GORTHOR)
	piezas.arena_de_gorthor(vivo)
	if vivo:
		gorthor = piezas.gorthor(T.GORTHOR)
	# la grieta oculta y la salida
	piezas.pilar_peregrino(T.PILAR_PEREGRINO)
	piezas.marca_salida(T.SALIDA)
	piezas.cerrar()


func palanca_bajada() -> bool:
	return Progreso.estado(NOMBRE, "palanca")


func cofre_abierto() -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(ID_COFRE_NIDO)


# Por dónde se anda (trazado.gd): las cornisas, los puentes, las escaleras, la arena y el nido; el levadizo, solo bajado.
func _prohibido(p: Vector3) -> bool:
	return not T.andable(p, palanca_bajada() and not tirando)


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _en_nido(p: Vector3) -> bool:
	return p.y < T.NIDO + 1.5 and _dist_plana(p, T.COFRE_NIDO) < T.RADIO_NIDO


func _en_arena(p: Vector3) -> bool:
	return p.y > T.ALTO - 2.0 and p.z < T.Z_GORTHOR and _dist_plana(p, T.ARENA) < T.ARENA_RADIO + 0.5


# Una posición de la Garganta 2D (en píxeles, «pos_zona») → el sitio equivalente de la 3D (el ancla más cercana del
# trazado). Lo usa modo3d.escena_equivalente para las partidas guardadas dentro de la 2D.
static func posicion_desde_2d(px: Vector2) -> Vector3:
	var c := px / 64.0                                          # zona.gd: T = 64 píxeles por casilla
	var mejor: Vector3 = T.INICIO
	var dist := INF
	for a in T.ANCLAS:
		var d: float = (a[0] as Vector2).distance_to(c)
		if d < dist:
			dist = d
			mejor = a[1]
	return mejor


# ================================================================= Kael, cámara y grupo

func _colocar_kael(p: Vector3) -> void:
	kael.global_position = p
	seguro = p
	foco = p
	destino = null
	var z: Array = T.camara_en(p, DIST_MIN, DIST_MAX)
	inclinacion = z[0]
	distancia = clampf(_dist_jugador, z[1], z[2])
	_dist_puesta = distancia
	_colocar_camara(1.0)


# La cámara de vista3d.gd (45°, sin girar nunca) con zonas: en los tramos estrechos se acerca y mira más desde arriba,
# en los puentes se inclina para asomarse al abismo, en la arena se aleja (trazado.gd, CAMARA). La distancia que elige
# el jugador se respeta dentro de lo que permite cada zona. Los cambios son suaves.
func _camara_zona(delta: float) -> void:
	if absf(distancia - _dist_puesta) > 0.0001:                # el jugador ha acercado o alejado
		_dist_jugador = clampf(_dist_jugador + distancia - _dist_puesta, DIST_MIN, DIST_MAX)
	var z: Array = T.camara_en(kael.global_position, DIST_MIN, DIST_MAX)
	var k := 1.0 - exp(-2.2 * delta)
	inclinacion = lerpf(inclinacion, z[0], k)
	distancia = lerpf(distancia, clampf(_dist_jugador, z[1], z[2]), k)
	_dist_puesta = distancia


# Como la de vista3d.gd, más un desvío para mirar un momento hacia otro sitio (el puente levadizo al bajar).
func _colocar_camara(peso: float) -> void:
	var meta := kael.global_position + _hacia() * adelanto + _desvio
	foco = foco.lerp(meta, peso)
	var ang := deg_to_rad(inclinacion)
	var atras := Vector3(sin(deg_to_rad(GIRO)), 0, cos(deg_to_rad(GIRO)))
	var ojo := foco + Vector3(0, 0.9, 0)
	cam.global_position = ojo + atras * cos(ang) * distancia + Vector3.UP * sin(ang) * distancia
	cam.look_at(ojo, Vector3.UP)
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		cam.size = 2.0 * distancia * tan(deg_to_rad(campo_vision) * 0.5)
	else:
		cam.fov = campo_vision


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
	grupo.pasos_superficie = suelo_de_pasos                    # sus pasos, con el suelo de Kael (sonido.gd, T-083)
	grupo.preparar(self, kael, nombres)
	grupo.colocar(Vector3.BACK)                                # detrás de Kael, hacia el sur (de donde se viene)


func _parar_kael() -> void:
	destino = null
	if movimiento != "":
		movimiento = ""
		kael.reposo()


func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return viajando or tirando or (dg != null and dg.current_timeline != null)


# El panel del prototipo trae bancos de medida con los recorridos de Pastos Verdes: aquí solo quedan CAL (perfil) y
# RND (rendimiento). La medida de la Garganta tiene su propio guion: pruebas/medir_garganta3d.gd.
func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in BOTONES_BANCO:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if esc != null:
		esc.animar(delta)                                      # el fuego de los faroles tiembla (T-102)
	if kael == null:
		return
	if en_banco():
		super(delta)
		return
	if ocupado():                                              # ascensor, palanca o diálogo: Kael quieto
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		_oclusion()
		_seguir_polvo()
		return
	_camara_zona(delta)
	super(delta)
	if saliendo:
		return
	_seguir_polvo()
	var p := kael.global_position
	var d := _dist_plana(p, _ultima)
	_ultima = p
	if d < 2.0:                                                # un salto (ascensor, recolocación) no es andar
		_recorrido += d
		while _recorrido >= LONG_PASO and not saliendo:
			_recorrido -= LONG_PASO
			_paso()
	if saliendo:
		return
	var ds := _dist_plana(p, T.SALIDA)
	if not salida["armada"]:
		salida["armada"] = ds > ARMAR_SALIDA
	elif ds < RADIO_SALIDA and absf(p.y - T.SALIDA.y) < 2.0:
		_salir()
		return
	if _comprobar_fijos():
		return
	_comprobar_cerca()


func _seguir_polvo() -> void:
	if esc != null and esc.polvo != null:
		esc.polvo.global_position = kael.global_position + Vector3(0, 1.6, 0)


func _unhandled_input(ev: InputEvent) -> void:
	if ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


# ================================================================= encuentros y combates fijos

func _paso() -> void:
	pasos += 1
	if Progreso.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	var k := T.ritmo(kael.global_position)               # muchos en los puentes, pocos en las cornisas de abajo
	if k > 0.0 and randf() < Progreso.prob_encuentro(PROB_ENCUENTRO * k, pasos, PASOS_MIN, NOMBRE):
		_encuentro()


# Combate al azar o fijo (nido, jefe). En los fijos, al volver se aparece un poco antes del disparo (como en la 2D):
# si se pierde, no se repite nada más volver; al ganarlo, combate.gd lo apunta en «combates_ganados» y no sale más.
func _encuentro(fijo := "", grupo_combate := -1, tipo := "normal", vuelta = null, texto := "¡Emboscada!") -> void:
	if saliendo:
		return
	saliendo = true
	_vuelta = vuelta
	guardar_posicion()
	Engine.set_meta("zona", ZONA)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("escena_retorno", scene_file_path)
	if fijo != "":
		Engine.set_meta("grupo_combate", grupo_combate)
		Engine.set_meta("combate_fijo", fijo)
	Sonido.efecto("emboscada")                         # sonido.gd (como garganta.gd)
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


func _comprobar_fijos() -> bool:
	var p := kael.global_position
	if not Progreso.ganado(ID_NIDO):
		var dentro := _en_nido(p)
		if dentro and _armado_nido:
			_encuentro(ID_NIDO, GRUPO_NIDO, "normal", T.VUELTA_NIDO, "¡Algo se mueve en el nido!")
			return true
		if not dentro:
			_armado_nido = true
	var en_arena := _en_arena(p)
	if not Progreso.ganado(ID_GORTHOR):
		if en_arena and _armado_gorthor:
			_encuentro(ID_GORTHOR, GRUPO_GORTHOR, "jefe", T.VUELTA_GORTHOR, "¡Gorthor el Devorador!")
			return true
		if not en_arena:
			_armado_gorthor = true
	elif en_arena and not _silencio_dicho:                     # garganta.gd: el texto del lugar tras vencerle
		_silencio_dicho = true
		_mostrar_aviso("La arena guarda silencio. Gorthor ya no espera a nadie.", 3.0)
	return false


# ================================================================= piezas al alcance

func _piezas_al_alcance() -> Array:
	var tirada := palanca_bajada()
	var lista: Array = [
		["guardado_1", T.GUARDADO_1, "Guardar partida"], ["guardado_2", T.GUARDADO_2, "Guardar partida"],
		["palanca", T.PALANCA, "Palanca bajada" if tirada else "Tirar de la palanca"],
		["ascensor_arriba", T.ASCENSOR_ARRIBA, "Bajar en el ascensor"], ["ascensor_abajo", T.ASCENSOR_ABAJO, "Subir a la entrada"],
		["detalle_p2", T.DETALLE_PUENTES, "Examinar"], ["detalle_p8", T.PILAR_PEREGRINO, "Examinar"],
	]
	if not tirada:
		lista.append(["puerta", T.PUERTA + Vector3(0, 0, 1.2), "Examinar la puerta"])
	if not cofre_abierto() and Progreso.ganado(ID_NIDO):
		lista.append(["cofre", T.COFRE_NIDO, "Abrir cofre"])
	return lista


func _comprobar_cerca() -> void:
	var p := kael.global_position
	cerca = ""
	var mejor := RADIO_PIEZA
	for pz in _piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := _dist_plana(p, q)
		if d < mejor and absf(p.y - q.y) < 2.5:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[2]
	boton_accion.visible = cerca != ""


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado() or saliendo or cerca == "":
		return
	_bloqueo = 0.35
	match cerca:
		"guardado_1", "guardado_2":
			guardar_posicion()
			Progreso.guardar(scene_file_path)
			Sonido.efecto("guardado")                  # sonido.gd (T-083)
			var altar: Node3D = guardados[0 if cerca == "guardado_1" else 1]
			piezas.destello(altar, Vector3(0, 1.5, 0), 0.4, Color(0.55, 1.0, 0.65))
			_apagar_destello(altar)
			_mostrar_aviso("Partida guardada.")
		"palanca":
			if not palanca_bajada():
				_tirar_palanca()
		"ascensor_arriba", "ascensor_abajo":
			if palanca_bajada():
				_viajar(cerca == "ascensor_arriba")
			else:
				Sonido.efecto("atascado")
				_mostrar_aviso("El ascensor no se mueve. Algo, más abajo, debería darle fuerza.")
		"puerta":
			Sonido.efecto("cerrada")
			_mostrar_aviso("Una puerta sellada con el anillo partido. No cede.")
		"cofre":
			_abrir_cofre()
		"detalle_p2", "detalle_p8":
			_examinar(0 if cerca == "detalle_p2" else 1)


func _apagar_destello(altar: Node3D) -> void:
	var d: Node3D = altar.get_child(altar.get_child_count() - 1)
	var t := d.create_tween()
	t.tween_property(d, "scale", Vector3.ONE * 2.2, 0.35)
	t.tween_callback(d.queue_free)


# Los detalles de lore de la Garganta (progreso.gd, DETALLES[2]): el mismo texto y la misma página del Diario que en
# la 2D. El pilar del peregrino completa, con los de Oakhaven y el Bosque, «El primer portador» (Acto I).
func _examinar(i: int) -> void:
	var d: Dictionary = Progreso.detalles_de(INDICE)[i]
	_mostrar_aviso(d["texto"], 4.0)
	Sonido.efecto("examinar")                          # sonido.gd
	var acto: Dictionary = Progreso.ver_detalle(d["id"])
	if not acto.is_empty():
		get_tree().create_timer(4.6).timeout.connect(func():
			if is_instance_valid(self):
				Sonido.efecto("pagina")
				Sonido.efecto("misterio", {"retraso": 0.2})
				_mostrar_aviso("Nueva página en el Diario: «%s»" % acto["escena"]))


# ================================================================= la palanca

# Abre la puerta sellada, baja el puente levadizo de P7 a P3 y enciende el ascensor (como garganta.gd). El estado se
# apunta y se guarda primero; la animación solo enseña (la cámara mira un momento hacia el puente que cae).
func _tirar_palanca() -> void:
	Progreso.poner_estado(NOMBRE, "palanca")
	tirando = true
	_parar_kael()
	boton_accion.visible = false
	Sonido.efecto("palanca")                           # y, desde donde están, el puente que baja y la puerta que se abre
	Sonido.efecto("puente_baja", {"retraso": 0.5, "pos": (T.BISAGRA + T.APOYO) * 0.5})                       # (sonido.gd)
	Sonido.efecto("puerta_abre", {"retraso": 1.3, "pos": T.PUERTA + Vector3(0, 1.5, 0)})
	var eje: Node3D = palanca["eje"]
	var tp := eje.create_tween()
	tp.tween_property(eje, "rotation:x", deg_to_rad(55.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# la cámara se vuelve hacia el puente mientras baja, y luego regresa a Kael
	var centro := (T.BISAGRA + T.APOYO) * 0.5 + Vector3(0, 1.5, 0)
	var hacia := (centro - kael.global_position) * Vector3(0.75, 0.55, 0.75)
	var tc := create_tween()
	tc.tween_property(self, "_desvio", hacia, 0.9).set_trans(Tween.TRANS_SINE)
	tc.tween_interval(CAIDA_LEVADIZO + 0.4)
	tc.tween_property(self, "_desvio", Vector3.ZERO, 1.0).set_trans(Tween.TRANS_SINE)
	tc.tween_callback(func(): tirando = false)
	var tb := create_tween()
	tb.tween_interval(0.5)
	tb.tween_method(func(g: float): piezas.poner_levadizo(levadizo, g), Piezas.LEVADIZO_ARRIBA, Piezas.angulo_bajado(),
		CAIDA_LEVADIZO).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tb.tween_callback(func():
		piezas.choque_levadizo(levadizo)
		piezas.soltar_cadenas(levadizo)
		_temblor_camara())
	# la puerta sellada se hunde en el suelo
	var losa: Node3D = puerta["losa"]
	var td := losa.create_tween()
	td.tween_interval(0.8)
	td.tween_property(losa, "position:y", T.PUERTA.y - 5.3, 2.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	td.tween_callback(func(): losa.visible = false)
	if puerta.get("choque") != null:
		puerta["choque"].queue_free()
		puerta["choque"] = null
	# el ascensor recibe fuerza: los faroles del cable se encienden y la cesta baja a la estación de abajo
	piezas.encender_ascensor(ascensor, true)
	var cesta: Node3D = ascensor["cesta"]
	var ta := cesta.create_tween()
	ta.tween_interval(0.6)
	ta.tween_method(func(t: float): cesta.position = Piezas.posicion_cesta(ascensor["cable"], t), 0.5, 1.0, 2.5) \
		.set_trans(Tween.TRANS_SINE)
	_mostrar_aviso("Algo cruje a lo lejos. Un puente baja sobre el abismo.", 2.4)
	guardar_posicion()
	Progreso.guardar(scene_file_path)


func _temblor_camara() -> void:
	var base := cam.position
	var t := create_tween()
	for i in 8:
		t.tween_property(cam, "position", base + Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), 0), 0.05)


# ================================================================= el ascensor

# Como garganta.gd (_viajar): fundido a negro y Kael aparece en la otra estación; el grupo se coloca detrás de él solo
# (grupo_3d.gd ve que ha aparecido en otro sitio). La cesta llega con él.
func _viajar(bajar: bool) -> void:
	viajando = true
	_parar_kael()
	boton_accion.visible = false
	Sonido.efecto("ascensor")                          # sonido.gd
	var destino_3d: Vector3 = T.ASCENSOR_ABAJO if bajar else T.ASCENSOR_ARRIBA
	var t := create_tween()
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.35)
	t.tween_callback(func():
		ascensor["cesta"].position = Piezas.posicion_cesta(ascensor["cable"], 1.0 if bajar else 0.0)
		_colocar_kael(destino_3d)
		_ultima = kael.global_position
		guardar_posicion())
	t.tween_interval(0.25)
	t.tween_property(fundido, "color:a", 0.0, 0.4)
	t.tween_callback(func(): viajando = false)


# ================================================================= el cofre raro del nido

# Primero se apunta como abierto, luego se da el premio (el de la 2D: 300 monedas, 2 Éter y un Incienso de Ceniza) y se
# guarda: el premio sale una sola vez aunque se pulse dos veces.
func _abrir_cofre() -> void:
	if cofre.is_empty() or cofre_abierto():
		return
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[ID_COFRE_NIDO] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	var inv = load("res://inventario.gd")
	inv.ganar_oro(300)
	inv.agregar_objeto("Éter", 2)
	inv.agregar_objeto(Progreso.INCIENSO, 1)
	_parar_kael()
	var hacia: Vector3 = cofre["cuerpo"].global_position - kael.global_position
	hacia.y = 0.0
	if hacia.length() > 0.05:
		kael.mirar(hacia, 0.2)
	boton_accion.visible = false
	cerca = ""
	var brillo = cofre.get("brillo")
	if brillo != null and is_instance_valid(brillo):
		brillo.queue_free()
		cofre["brillo"] = null
	var tapa: Node3D = cofre["tapa"]
	var t := tapa.create_tween()
	t.tween_property(tapa, "rotation:x", deg_to_rad(Piezas.COFRE_ABIERTA), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var luz: MeshInstance3D = piezas.destello(cofre["cuerpo"], Vector3(0, Piezas.COFRE_ALTO + 0.3, 0), 0.35)
	var t2 := luz.create_tween()
	t2.tween_property(luz, "scale", Vector3.ONE * 2.4, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(luz.material_override, "albedo_color:a", 0.0, 0.8)
	t2.tween_callback(luz.queue_free)
	Sonido.efecto("cofre")                             # sonido.gd (como garganta.gd)
	Sonido.efecto("tesoro", {"retraso": 0.3})
	_mostrar_aviso("¡Cofre raro! 300 monedas, 2 Éter y un Incienso de Ceniza.", 2.4)
	guardar_posicion()
	Progreso.guardar(scene_file_path)


# ================================================================= guardado y salida

# Recursos la llama al pausar o cerrar la app (y antes de guardar), para volver justo aquí. Con un combate fijo en
# marcha, se vuelve al sitio de antes del disparo.
func guardar_posicion() -> void:
	Engine.set_meta("pos_3d", _vuelta if _vuelta != null else kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_3d_ok", false)                        # la próxima vez se entra por el principio
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena(Progreso.MAPA)


# Sonido 3D (sonido.gd, T-083 tanda 3): se escucha desde Kael, mirando como la cámara; sus pasos según el suelo (los de
# Lya y Garon, igual: _crear_grupo); la cascada a lo largo de su caída (suena desde el punto a la altura de quien
# escucha) y el viento del abismo a lo largo de su eje, más un poco bajo los puentes colgantes (ahí se está encima del
# vacío); las gotas de la mazmorra en la roca más cercana y el eco de la garganta (se quita solo al salir).
func _sonido_3d() -> void:
	Sonido.oyente_3d(kael, cam)
	Sonido.pasos_3d(kael, suelo_de_pasos)
	Sonido.fuente_linea(self, "cascada_grande", Vector3(3.6, T.TOPE - 4.0, T.Z_NORTE + 0.8), Vector3(3.6, T.HONDO + 10.0, T.Z_NORTE + 2.8))
	var x_eje := (T.X_BORDE_O + T.X_BORDE_E) * 0.5
	Sonido.fuente_linea(self, "viento_abismo", Vector3(x_eje, T.BAJO + 3.0, T.Z_PRESA_N), Vector3(x_eje, T.BAJO + 3.0, T.Z_NORTE + 2.0))
	Sonido.fuente_linea(self, "viento_abismo", Vector3(T.X_CAMINO_O, T.ALTO - 2.5, T.PUENTES[0][0]),
		Vector3(T.X_CAMINO_O, T.ALTO - 2.5, T.PUENTES[1][1]), -6.0)
	Sonido.detalles_3d(self, _punto_gota)
	Sonido.eco(self, "garganta")


# El suelo que pisa quien está en «p» (sus pasos, sonido.gd): tablas en los puentes colgantes, el levadizo y las
# estaciones del ascensor; roca en lo demás (cornisas, escaleras talladas, la arena y el nido).
func suelo_de_pasos(p: Vector3) -> String:
	if p.y > T.ALTO - 1.5 and absf(p.x - T.X_CAMINO_O) < T.ANCHO_PUENTE * 0.5 + 0.3:
		for b in T.PUENTES:
			if p.z <= b[0] and p.z >= b[1]:
				return "madera"
	if absf(p.z - T.LEVADIZO_Z) < T.LEVADIZO_ANCHO * 0.5 and p.x > T.BISAGRA.x - 0.2 and p.x < T.APOYO.x + 0.3:
		return "madera"
	for e in [T.ASCENSOR_ARRIBA, T.ASCENSOR_ABAJO]:
		if _dist_plana(p, e) < 1.6 and absf(p.y - e.y) < 1.0:
			return "madera"
	return "piedra"


# Dónde cae una gota (los detalles de la mazmorra, sonido.gd): en la pared de roca más cercana a quien escucha («o»),
# algo por delante o por detrás (u) y por encima (v); u y v, números al azar de 0 a 1 que da sonido.gd. En el nido,
# del acantilado de la cornisa baja.
func _punto_gota(o: Vector3, u: float, v: float) -> Vector3:
	var z := clampf(o.z + (u - 0.5) * 14.0, T.Z_NORTE + 2.0, T.Z_FIN_CAMINO)
	var x: float
	if o.y < T.BAJO - 2.0:
		x = T.borde_este(z) - 0.3
	elif o.x < (T.X_BORDE_O + T.X_BORDE_E) * 0.5:
		x = T.muro_oeste(z) + 0.3
	else:
		x = T.muro_este(z) - 0.3
	return Vector3(x, o.y + 0.5 + v * 3.0, z)


# ================================================================= pantalla

func _crear_interfaz() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 50
	add_child(capa)
	boton_accion = Button.new()
	boton_accion.position = Vector2(980, 600)
	boton_accion.custom_minimum_size = Vector2(270, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa.add_child(boton_accion)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 100)
	aviso.position = Vector2(140, 500)
	aviso.add_theme_font_size_override("font_size", 30)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	aviso.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.08, 0.85))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.modulate.a = 0.0
	capa.add_child(aviso)
	fundido = ColorRect.new()                                  # el último: tapa también el botón y el aviso
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(fundido)


var _tw_aviso: Tween


func _mostrar_aviso(texto: String, segundos := 1.6) -> void:
	aviso.text = texto
	if _tw_aviso != null and _tw_aviso.is_valid():
		_tw_aviso.kill()
	_tw_aviso = create_tween()
	_tw_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tw_aviso.tween_interval(segundos)
	_tw_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


# Nombre de la zona al entrar, como en Pastos Verdes (prototipos/sendero_puente.gd).
func _titulo_zona(nombre: String) -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	var l := Label.new()
	l.text = nombre
	l.add_theme_font_size_override("font_size", 52)
	l.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.08, 0.8))
	l.add_theme_constant_override("outline_size", 10)
	if ResourceLoader.exists("res://menu_combate.gd"):
		var mc = load("res://menu_combate.gd")
		var f = mc.fuente(mc.FUENTE_NOMBRE, 0, 600)
		if f != null:
			l.add_theme_font_override("font", f)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 80)
	l.position = Vector2(0, 120)
	l.modulate.a = 0.0
	l.name = "Titulo"
	capa.add_child(l)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_property(l, "modulate:a", 1.0, 0.8)
	t.tween_interval(2.0)
	t.tween_property(l, "modulate:a", 0.0, 1.0)
