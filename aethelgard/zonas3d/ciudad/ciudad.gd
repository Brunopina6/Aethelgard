extends "res://prototipos/vista3d.gd"
# CIUDAD COMPLETA de Oakhaven (V12, 16/11, M0): LA ESCENA. EXPERIMENTAL y APAGADA: solo se entra desde el banco de pruebas
# de Auditoría («Ciudad de Oakhaven (maqueta, en pruebas)», banco_pruebas.gd, EXPLORAR["ciudad"]). Ninguna escena del juego
# la enlaza; Oakhaven 3D, la 2D y el barrio no cambian. Fuera del banco, _ready vuelve a la pantalla de carga y no sigue.
# Plan: docs/v12/CIUDAD_OAKHAVEN_PLAN.md; contrato, cargador y pruebas: docs/v12/CIUDAD_OAKHAVEN.md.
#
# MAQUETA (M0): los 8 sectores en bloques sacados de sus trazados, montados por proximidad (cargador.gd) y, lo lejano, en
# maqueta lejana. Kael y el grupo con los controles normales (tocar/clic y teclas): lo que se pisa y a qué altura lo dicen
# los trazados (plano.andable / plano.altura: escaleras y rampas andables), y no se atraviesan los bloques (choques de los
# sectores montados). Cámara inclinada sin girar, la del barrio, con zonas por sector; lo que la escena puede ocultar
# (cubiertas, copas y las casas OCULTABLES de cada trazado) se aclara si se pone entre la cámara y Kael (cabeza, cintura,
# pies y lados) o el grupo cercano, y sigue aclarado un momento (sin parpadeo). Con teclas o mando, Kael se desliza a lo
# largo de una pared si va en diagonal contra ella; un toque en un sector sin montar (maqueta lejana, sin choques) cae
# en el plano. (Arreglos del recorrido, 16/11: docs/v12/ciudad_sectores/RECORRIDO.md §7.)
# (Arreglos tras el Redmi, 17/11, RECORRIDO.md §8: Kael con cuerpo, rodear obstáculos bajos o pequeños con toques, los
# lados del grupo y «Guardar y recargar» que para a Kael al tocarlo.)
# (19/11, PC-16, RECORRIDO.md §12: tocar sobre un edificio lleva a Kael al punto andable más cercano a lo tocado al que
# llega con un rodeo corto, sin atravesarlo: _ajustar_destino, _buscar_rodeo y _seguir_ruta.)
# Puertas solo previstas: «Aún no se puede entrar (en obras).». Nunca se cargan interiores.
#
# API de región (la del barrio): kael, cam, perfil · avisar(texto, efecto, seg) · guardar() · guardar_posicion() ·
# ocupado() · ancla(id) · sonda(p) (provisional) · iniciar_dialogo(ruta) · volver_al_banco().

const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
const Cargador := preload("res://zonas3d/ciudad/cargador.gd")
const Progreso := preload("res://progreso.gd")
const BP_RUTA := "res://banco_pruebas.gd"

const INDICE := 103                        # pos_3d_lugar de la ciudad (0-10 mapa, 99 banco, 100 mapamundi, 101 cueva, 102 barrio)
const META_ACTIVO := "ciudad_v12"          # meta de SESIÓN (banco_pruebas.gd, METAS_SESION; recursos.gd, APAGADOS)
const TEXTO_OBRAS := "Aún no se puede entrar (en obras)."
const TEXTO_SALIDA := "La Puerta del Sur sale al camino. En la maqueta no se sale: usa «Volver al banco»."
const SONDA_PROVISIONAL := Vector2(1.0, 0.7)
const RADIO_PUERTA_SUR := 1.8

var brillo_sin_sombras := 1.1               # vista3d.gd: el bajo sin sombras
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var cargador: Cargador
var exterior: Node3D
var sol: DirectionalLight3D
var ambiente: Environment
var grupo: Node3D
var capa_ui: CanvasLayer
var boton_accion: Button
var boton_recargar: Button
var aviso: Label
var titulo: Label
var cerca := ""
var ultimo_aviso := ""
var dialogo_actual := ""
var aclarados := 0                         # piezas aclaradas ahora (para las pruebas)
var fuera_del_banco := false
var _bloqueo := 0.0
var _t_titulo := 0.0
var _tween_aviso: Tween
static var _puertas: Array = []            # plano.puertas(), una vez


static func en_banco_pruebas() -> bool:
	return load(BP_RUTA).en_banco()


func _ready() -> void:
	if not en_banco_pruebas():
		fuera_del_banco = true                    # (una partida vieja, F6…): a la carga, sin construir nada
		set_process(false)
		set_process_unhandled_input(false)
		_volver_a_la_carga.call_deferred()
		return
	Engine.set_meta(META_ACTIVO, true)            # la escena se activa a sí misma (como el barrio)
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	super()
	info.visible = false
	_crear_interfaz()
	_colocar_kael(_sitio_de_entrada())
	_crear_grupo()
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
	if has_node("/root/Sonido"):
		Sonido.oyente_3d(kael, cam)
		Sonido.pasos_3d(kael, suelo_de_pasos)


func _volver_a_la_carga() -> void:
	while is_inside_tree() and has_node("/root/Recursos") and Recursos.cambiando:
		await get_tree().process_frame
	if is_inside_tree() and has_node("/root/Recursos"):
		Recursos.cambiar_escena(load(BP_RUTA).CARGA)


func _exit_tree() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null and dg.timeline_ended.is_connected(_al_terminar_dialogo):
		dg.timeline_ended.disconnect(_al_terminar_dialogo)
		if dialogo_actual != "" and dg.current_timeline != null:
			dialogo_actual = ""
			dg.end_timeline(true)
	super()
	Blockout.soltar()                              # (los materiales compartidos no llegan vivos al apagado del motor)


# ================================================================= mundo

func _crear_ambiente() -> void:
	ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.86, 0.80, 0.70)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.62, 0.68, 0.80)
	ambiente.ambient_light_energy = 0.55
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color(0.86, 0.76, 0.62)
	ambiente.fog_density = 0.0025
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.tonemap_exposure = 0.95
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = ambiente
	add_child(we)
	sol = DirectionalLight3D.new()                 # el sol bajo del oeste-suroeste del barrio (provisional)
	sol.name = "Sol"
	var h := Vector3(-0.73, 0.45, 0.51).normalized()
	sol.look_at_from_position(Vector3.ZERO, -h, Vector3.UP)
	sol.light_color = Color(1.0, 0.84, 0.64)
	sol.light_energy = 1.05
	sol.shadow_enabled = bool(perfil.get("sombras", false))
	sol.directional_shadow_max_distance = float(perfil.get("dist_sombras", 40.0))
	add_child(sol)


func _crear_escenario() -> void:
	exterior = Node3D.new()
	exterior.name = "Exterior"
	add_child(exterior)
	var st := Blockout.nueva()                     # el campo bajo y alrededor de la ciudad (sin choque: no se pisa)
	var r := P.CAJA_CIUDAD.grow(80.0)
	Blockout.caja(st, AABB(Vector3(r.position.x, -4.0, r.position.y), Vector3(r.size.x, 0.8, r.size.y)), Blockout.COLOR_FONDO)
	var fondo := Blockout.malla(st, "Fondo")
	fondo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	exterior.add_child(fondo)
	cargador = Cargador.new()
	cargador.name = "Cargador"
	exterior.add_child(cargador)
	cargador.preparar(nombre_perfil)


# ================================================================= Kael, cámara y grupo

func _sitio_de_entrada() -> Vector3:
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	if vuelve:
		var p: Vector3 = Engine.get_meta("pos_3d")
		if P.andable(p.x, p.z):
			return Vector3(p.x, P.altura(p.x, p.z), p.z)
	return P.ancla("inicio")


func _colocar_kael(p: Vector3) -> void:
	p.y = P.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	destino = null
	_borrar_ruta()
	if cargador != null:
		cargador.actualizar(p, true)
		cargador.olvidar_aclarados()                  # (lo aclarado donde estaba no sigue aclarado: sector.gd, SOSTEN)
	foco = P.foco_camara(p)
	_colocar_camara(1.0)


func _colocar_camara(peso: float) -> void:
	if cam == null or kael == null:
		return
	foco = foco.lerp(P.foco_camara(kael.global_position), peso)
	P.poner_camara(cam, foco)


# Lo que tapa a Kael se aclara (en vista3d, lo del grupo «ocluye»; aquí, lo ocultable de los sectores montados). No solo
# la cabeza: con solo ella, una hoja de puerta, una lona o un arco dejaban a Kael asomando la cabeza (o nada) justo donde
# se pulsa «Entrar», medio Kael quedaba tapado de lado pegado a una esquina (la cámara no gira: su ancho va en x) y el
# grupo se quedaba detrás de lo que nadie aclaraba (recorrido y verificación, 16/11). Ahora, rayos de la cámara a la
# cabeza, la cintura, los pies y los dos lados de Kael, y a la cabeza, la cintura y los pies de quien del grupo esté a
# menos de GRUPO_CERCA (a los pies: al entrar, la hoja de la Puerta del Sur cortaba las piernas de Lya y Garon).
# (17/11, Redmi) Y los dos lados del grupo cercano (a 0,8 y 1,4 m): junto al pórtico de las Raíces un pilar tapaba media
# Lya sin aclararse (antes_recarga.png).
const PUNTOS_KAEL := [Vector3(0.0, Comun.ALTO_CABEZA, 0.0), Vector3(0.0, 0.8, 0.0), Vector3(0.0, 0.25, 0.0),
	Vector3(-0.25, 0.8, 0.0), Vector3(0.25, 0.8, 0.0), Vector3(-0.25, 1.4, 0.0), Vector3(0.25, 1.4, 0.0)]
const PUNTOS_GRUPO := [Vector3(0.0, 1.4, 0.0), Vector3(0.0, 0.8, 0.0), Vector3(0.0, 0.25, 0.0),
	Vector3(-0.25, 0.8, 0.0), Vector3(0.25, 0.8, 0.0), Vector3(-0.25, 1.4, 0.0), Vector3(0.25, 1.4, 0.0)]
const GRUPO_CERCA := 8.0
var _t_juego := 0.0                        # segundos de juego (el sostén de los aclarados, sector.gd)


func _oclusion() -> void:
	if cam == null or kael == null or cargador == null:
		return
	var k := kael.global_position
	var puntos: Array = []
	for d in PUNTOS_KAEL:
		puntos.append(k + d)
	if grupo != null:
		for n in grupo.nodos():
			var g: Vector3 = (n as Node3D).global_position
			if Vector2(g.x - k.x, g.z - k.z).length() < GRUPO_CERCA:
				for d in PUNTOS_GRUPO:
					puntos.append(g + d)
	aclarados = cargador.aclarar(cam.global_position, puntos, _t_juego)


func _prohibido(p: Vector3) -> bool:
	return not P.andable(p.x, p.z)


# Lo que se pisa y su cota salen del PLANO (no de los choques): funciona igual con el sector de al lado aún sin montar. Los
# choques montados siguen parando a Kael ante lo sólido (el rayo a la altura de las rodillas de vista3d).
# (17/11, Redmi) Y Kael tiene CUERPO: no se mete en la franja de Comun.RADIO_CUERPO junto a una pared, un pilar o una
# jardinera alta (plano.holgura): pegado a ellas, media figura quedaba dentro del bloque y tapada de lado desde la cámara
# (Rampa de las Raíces, pórtico). Si ya está dentro (colocado o cargado ahí), puede salir y andar a lo largo, no meterse más.
func _altura_suelo(p: Vector3, y_actual: float) -> float:
	if _prohibido(p):
		return NAN
	var h := P.altura(p.x, p.z)
	if absf(h - y_actual) > SUBE_MAX:
		return NAN
	var holgura := P.holgura(p.x, p.z)
	if holgura < Comun.RADIO_CUERPO - 0.001 and holgura < P.holgura(kael.global_position.x, kael.global_position.z) - 0.001:
		return NAN
	# (17/11) y el tramo entero, cada 5 cm: al doblar la esquina de algo bajo (un banco de 0,45 m, que no corta el rayo de
	# las rodillas) un tramo de 0,15 m podía cortar su esquina (recorrido: el banco del mirador del pretil)
	var k := kael.global_position
	var n := int(ceil(Vector2(p.x - k.x, p.z - k.z).length() / 0.05))
	for i in range(1, n):
		if _prohibido(k.lerp(p, float(i) / n)):
			return NAN
	var desde := Vector3(kael.global_position.x, y_actual + SUBE_MAX + 0.1, kael.global_position.z)
	var hacia := Vector3(p.x, y_actual + SUBE_MAX + 0.1, p.z)
	if hacia.distance_to(desde) > 0.001:
		hacia += (hacia - desde).normalized() * 0.3
		if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(desde, hacia)).is_empty():
			return NAN
	return h


# Si se toca un sitio que no se pisa, Kael va al último punto andable de la recta.
# (17/11, Redmi) Salvo que lo que corta la recta sea un obstáculo BAJO o PEQUEÑO (_rodeable: el pilón de la fuente, un
# puesto, un banco, un pilar) con suelo detrás a la misma cota: entonces el destino es el punto tocado detrás de él y
# Kael lo rodea al llegar (_bordear). Con toques, la fuente cortaba el camino de la Calle Mayor a la escalinata y Kael se
# quedaba pegado al pilón. Y el destino no queda en la franja del cuerpo junto a una pared (plano.holgura): se acerca al
# último punto de la recta donde Kael cabe.
const ALTO_RODEABLE := 1.5                 # un obstáculo más bajo que esto (y no más largo que LARGO_RODEABLE) se rodea…
const LARGO_RODEABLE := 8.0
const ANCHO_RODEABLE := 2.0                # … y uno más estrecho que esto por los dos lados, aunque sea alto (un pilar)


func _ajustar_recto(p):
	if p == null or kael == null:
		return null
	var desde := kael.global_position
	var hacia: Vector3 = p
	var n := int(Vector2(hacia.x - desde.x, hacia.z - desde.z).length() / 0.1)
	var ultimo = null
	var ultimo_holgado = null
	var y_ant := desde.y
	var cruzando := false
	var esquina_hasta := -1
	for i in n + 1:
		var q := desde.lerp(hacia, float(i) / maxf(n, 1))
		if _prohibido(q):
			if i > 0 and (i <= esquina_hasta or not _bloque_rodeable(q).is_empty()):
				cruzando = true
				continue
			if i > 0 and ultimo != null:                # (también tras algo rodeable: el banco y el pretil del atrio)
				esquina_hasta = _esquina_cortada(ultimo, desde, hacia, i, n)
				if esquina_hasta >= i:
					cruzando = true
					continue
			break
		var y := P.altura(q.x, q.z)
		if cruzando and absf(y - y_ant) > SUBE_MAX:  # (detrás de él, otro nivel: no se llega rodeándolo)
			break
		cruzando = false
		y_ant = y
		ultimo = Vector3(q.x, y, q.z)
		if P.holgado(q.x, q.z):
			ultimo_holgado = ultimo
	if cruzando:                                   # (la recta acaba dentro del obstáculo)
		return ultimo_holgado if ultimo_holgado != null else ultimo
	if ultimo != null and ultimo_holgado != null and not P.holgado(ultimo.x, ultimo.z):
		return ultimo_holgado
	return ultimo


# (19/11, Redmi: REDMI_18_11.md problema 2; PC-16; RECORRIDO.md §12) TOCAR SOBRE UN EDIFICIO. Antes, el rayo del toque
# atravesaba la casa (lo alto no cuenta como suelo) y caía en el suelo de detrás, a veces a 30-40 m; la recta hasta él
# se cortaba en la pared y Kael se quedaba pegado a ella, aunque lo tocado estuviera junto a otra fachada.
# Ahora (solo en la ciudad; vista3d.gd y las demás regiones no cambian; la búsqueda de caminos general es PD-4):
#   - si lo primero que se ve en el píxel tocado es una casa o un muro sin aclarar (_punto_suelo, _edificio_tocado), la
#     META es el punto tocado del edificio (en su planta); si no, la meta es el suelo tocado, como siempre;
#   - si la recta llega a la meta (o la deja ante algo rodeable o una esquina: _ajustar_recto), nada cambia;
#   - si no, y lo que la corta es una casa o un muro (o se tocó el edificio), Kael va al punto ANDABLE MÁS CERCANO A LA
#     META al que se llega SIN ATRAVESAR NADA con un RODEO CORTO: un camino por lo andable y holgado (rejilla de
#     REJILLA m, escalones ≤ SUBE_MAX) que no sea más de RODEO_EXTRA m más largo que la recta hasta ese punto
#     (_buscar_rodeo). Tocar al otro lado de una casa: si se rodea en poco, Kael la rodea y llega; si no, va al punto
#     más cercano a lo tocado al que llega con ese rodeo: de su lado (no donde la recta da en la pared) o doblando la
#     esquina hasta donde da el rodeo corto. Tocar la casa: va a la fachada más cercana a lo tocado a la que se llegue
#     así (la de su lado si la otra queda lejos). Nunca la atraviesa ni busca caminos largos (eso es PD-4);
#   - solo si ese punto queda RODEO_MEJORA m más cerca de la meta que lo de la recta; si no, la recta como antes.
# Kael sigue el camino por puntos de paso (_ruta, _seguir_ruta) en tramos rectos comprobados en el plano.
const REJILLA := 0.5
const RODEO_EXTRA := 8.0                   # «rodeo corto»: como mucho esto más que la recta
const RODEO_NODOS := 5000                  # casillas que se exploran como mucho (lo que cuesta cada toque)
const RODEO_MEJORA := 0.5
const META_CERCA := 12.0                   # el punto libre más cercano a la meta, como mucho a esto
var _toque_edificio = null                 # [suelo que dio _punto_suelo, punto tocado del edificio] (o null)
var _ruta: Array = []                      # los puntos de paso que quedan tras «destino»
var _paso = null                           # el punto de paso que es ahora «destino» (o null)
var _arrastre := false                     # el toque que se ajusta es un arrastre (dedo o ratón moviéndose)
var _rodeo_ms := -100000                   # cuándo se buscó el último rodeo (Time.get_ticks_msec)
var _rodeo_meta = null                     # la casilla de su meta
var ultimo_rodeo := {}                     # (para las pruebas) {meta, edificio, ms, nodos, puntos}
var _celdas := {}                          # (durante una búsqueda) casilla → cota si es libre, NAN si no


func _ajustar_destino(p):
	var toque = _toque_edificio
	_toque_edificio = null
	if kael == null:
		return null
	var meta = p
	var edificio := false
	if toque != null and toque[0] == p and toque[1] != null:
		meta = toque[1]
		edificio = true
	if meta == null:
		_borrar_ruta()
		return null
	var celda := _casilla(Vector2(meta.x, meta.z))
	# (arrastre: llega un ajuste por cada movimiento del dedo) con un rodeo en curso hacia la misma casilla, o buscado hace
	# menos de 0,3 s, se sigue con él; sin rodeo en curso, como mucho una búsqueda cada 0,3 s (si no, la recta)
	var reciente := Time.get_ticks_msec() - _rodeo_ms < 300
	if _arrastre and _paso != null and (_rodeo_meta == celda or reciente):
		return destino
	_borrar_ruta()
	var recto = _ajustar_recto(meta)
	if recto == null:
		return null
	var falta := Vector2(meta.x - recto.x, meta.z - recto.z).length()
	if falta < 0.2:
		return recto
	if not edificio and not (P.andable(meta.x, meta.z) and _corta_un_edificio(recto, meta)):
		return recto
	if _arrastre and reciente:
		return recto
	_rodeo_ms = Time.get_ticks_msec()
	_rodeo_meta = celda
	var puntos := _buscar_rodeo(meta)
	ultimo_rodeo["edificio"] = edificio
	if puntos.is_empty():
		return recto
	var fin: Vector3 = puntos[-1]
	if Vector2(meta.x - fin.x, meta.z - fin.z).length() > falta - RODEO_MEJORA:
		ultimo_rodeo["puntos"] = []
		return recto
	_paso = puntos[0]
	_ruta = puntos.slice(1)
	return _paso


func _borrar_ruta() -> void:
	_ruta.clear()
	_paso = null


func _casilla(q: Vector2) -> Vector2i:
	return Vector2i(floori(q.x / REJILLA), floori(q.y / REJILLA))


func _centro(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * REJILLA, (c.y + 0.5) * REJILLA)


# La cota de la casilla si su centro es andable y holgado (cabe el cuerpo de Kael), o NAN.
func _libre(c: Vector2i) -> float:
	var h = _celdas.get(c)
	if h == null:
		var q := _centro(c)
		h = P.altura(q.x, q.y) if P.holgado(q.x, q.y) else NAN
		_celdas[c] = h
	return h


# ¿Lo que corta la recta de «recto» a «meta» (lo primero no andable, a menos de 1,5 m) es una casa o un muro?
func _corta_un_edificio(recto: Vector3, meta: Vector3) -> bool:
	var a := Vector2(recto.x, recto.z)
	var b := Vector2(meta.x, meta.z)
	var n := mini(15, int(ceil(a.distance_to(b) / 0.1)))
	for i in range(1, n + 1):
		var q := a.move_toward(b, 0.1 * i)
		if not P.andable(q.x, q.y):
			var s := P.sector_en_caja(q.x, q.y)
			var id: String = P.trazado(s).bloque_en(q.x, q.y) if s != "" else ""
			if id == "":
				return false
			for bl in P.trazado(s).BLOQUES:
				if bl[0] == id:
					return _bloque_alto(bl)
			return false
	return false


# El camino del rodeo corto hacia «meta»: los puntos de paso (el último, el punto libre más cercano a la meta al que se
# llega), o [] si no hay casillas libres cerca. A* por casillas libres (8 vecinas; en diagonal, solo si las dos de los
# lados son libres; el punto medio de cada paso andable y sin escalón de más de SUBE_MAX), con h = distancia a la meta;
# cada casilla, como mucho RODEO_EXTRA m más lejos por el camino que en recta desde Kael; se para al llegar a la casilla
# libre más cercana a la meta o tras RODEO_NODOS. Junto a una pared el paso cuesta un 25 % más (camino algo apartado).
# Después, los tramos rectos más largos que pasan por lo holgado (_recta_libre).
func _buscar_rodeo(meta: Vector3) -> Array:
	var t0 := Time.get_ticks_usec()
	_celdas.clear()
	var k := kael.global_position
	var ini := Vector2(k.x, k.z)
	var m := Vector2(meta.x, meta.z)
	ultimo_rodeo = {"meta": meta, "nodos": 0, "puntos": []}
	# la casilla libre más cercana a la meta (por anillos)
	var cm := _casilla(m)
	var r0 := INF
	var anillo := 0
	while anillo * REJILLA <= META_CERCA and (anillo - 1) * REJILLA <= r0:
		for j in range(-anillo, anillo + 1):
			for i in range(-anillo, anillo + 1):
				if maxi(absi(i), absi(j)) != anillo:
					continue
				var c := cm + Vector2i(i, j)
				if not is_nan(_libre(c)):
					r0 = minf(r0, _centro(c).distance_to(m))
		anillo += 1
	if r0 == INF:
		ultimo_rodeo["ms"] = (Time.get_ticks_usec() - t0) / 1000.0
		return []
	var recta := ini.distance_to(m)
	var g := {}
	var largo := {}
	var padre := {}
	var cerrado := {}
	var monton: Array = []                         # montículo binario de [f, casilla]
	var ck := _casilla(ini)
	for j in range(-2, 3):                         # las casillas libres de alrededor a las que se llega en recta
		for i in range(-2, 3):
			var c := ck + Vector2i(i, j)
			var q := _centro(c)
			if is_nan(_libre(c)) or q.distance_to(ini) > 1.0 or not _tramo_andable(ini, q, k.y):
				continue
			g[c] = q.distance_to(ini)
			largo[c] = g[c]
			_meter(monton, [g[c] + q.distance_to(m), c])
	var mejor = null
	var mejor_d := INF
	var nodos := 0
	while not monton.is_empty() and nodos < RODEO_NODOS:
		var e := _sacar(monton)
		var c: Vector2i = e[1]
		if cerrado.has(c):
			continue
		cerrado[c] = true
		var q := _centro(c)
		var d := q.distance_to(m)
		# (una casilla útil, más cerca de la meta que la mejor, y lo que lleva a ella, están a largo + d ≤ recta +
		# 2·mejor_d + RODEO_EXTRA, con largo ≤ su recta + RODEO_EXTRA: lo de más allá ya no mejora nada)
		if float(largo[c]) + d > recta + 2.0 * mejor_d + RODEO_EXTRA:
			continue
		nodos += 1
		if d < mejor_d - 0.001:
			mejor_d = d
			mejor = c
		if d <= r0 + 0.001:
			break
		var hc: float = _celdas[c]
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1),
				Vector2i(-1, 1), Vector2i(-1, -1)]:
			var n: Vector2i = c + v
			if cerrado.has(n):
				continue
			var hn := _libre(n)
			if is_nan(hn):
				continue
			if v.x != 0 and v.y != 0 and (is_nan(_libre(c + Vector2i(v.x, 0))) or is_nan(_libre(c + Vector2i(0, v.y)))):
				continue
			var qn := _centro(n)
			var medio := (q + qn) * 0.5
			if not P.andable(medio.x, medio.y):
				continue
			var hm := P.altura(medio.x, medio.y)
			if absf(hm - hc) > SUBE_MAX or absf(hn - hm) > SUBE_MAX:
				continue
			var paso := q.distance_to(qn)
			var l: float = largo[c] + paso
			if l - qn.distance_to(ini) > RODEO_EXTRA or l + qn.distance_to(m) > recta + 2.0 * mejor_d + RODEO_EXTRA:
				continue
			var junto := false
			for w in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if is_nan(_libre(n + w)):
					junto = true
					break
			var ng: float = g[c] + paso * (1.25 if junto else 1.0)
			if ng < g.get(n, INF):
				g[n] = ng
				largo[n] = l
				padre[n] = c
				_meter(monton, [ng + qn.distance_to(m), n])
	ultimo_rodeo["nodos"] = nodos
	if mejor == null:
		ultimo_rodeo["ms"] = (Time.get_ticks_usec() - t0) / 1000.0
		return []
	var camino: Array = []
	var cc = mejor
	while cc != null:
		var qc := _centro(cc)
		camino.push_front(Vector3(qc.x, _celdas[cc], qc.y))
		cc = padre.get(cc)
	camino.push_front(k)
	# tramos rectos: desde cada punto, el más lejano del camino al que se va en recta por lo holgado (búsqueda binaria)
	var puntos: Array = []
	var a := 0
	while a < camino.size() - 1:
		var lo := a + 1
		var hi := camino.size()
		while hi - lo > 1:
			var mitad := (lo + hi) / 2
			if _recta_libre(camino[a], camino[mitad]):
				lo = mitad
			else:
				hi = mitad
		puntos.append(camino[lo])
		a = lo
	ultimo_rodeo["puntos"] = puntos
	ultimo_rodeo["ms"] = (Time.get_ticks_usec() - t0) / 1000.0
	return puntos


func _meter(monton: Array, e: Array) -> void:
	monton.append(e)
	var i := monton.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if monton[p][0] <= e[0]:
			break
		monton[i] = monton[p]
		i = p
	monton[i] = e


func _sacar(monton: Array) -> Array:
	var cima: Array = monton[0]
	var e: Array = monton.pop_back()
	if monton.is_empty():
		return cima
	var i := 0
	var n := monton.size()
	while true:
		var h := 2 * i + 1
		if h >= n:
			break
		if h + 1 < n and monton[h + 1][0] < monton[h][0]:
			h += 1
		if monton[h][0] >= e[0]:
			break
		monton[i] = monton[h]
		i = h
	monton[i] = e
	return cima


# ¿Se va de a a b en recta por lo andable y holgado, cada 0,1 m, sin escalones de más de SUBE_MAX? (Saliendo de la franja
# del cuerpo, como _altura_suelo: sin meterse más en ella que en «a».)
func _recta_libre(a: Vector3, b: Vector3) -> bool:
	var n := maxi(1, int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 0.1)))
	var minimo := minf(Comun.RADIO_CUERPO, P.holgura(a.x, a.z)) - 0.001
	var y := a.y
	for i in range(1, n + 1):
		var q := a.lerp(b, float(i) / n)
		if P.holgura(q.x, q.z) < minimo:
			return false
		var h := P.altura(q.x, q.z)
		if absf(h - y) > SUBE_MAX:
			return false
		y = h
	return true


# Cada fotograma (tras moverse): al llegar a un punto de paso, el siguiente. Si Kael se para lejos de él (atasco, teclas,
# un toque nuevo), el camino se olvida. Al acercarse, si ya se va en recta al siguiente, se pasa a él sin pararse.
func _seguir_ruta(delta: float) -> void:
	if _paso == null:
		return
	if direccion_teclas.length() > 0.1 or ocupado():
		_borrar_ruta()
		return
	var k := kael.global_position
	if destino != null and not (destino as Vector3).is_equal_approx(_paso):
		_borrar_ruta()                                 # (otro destino: un toque sin rodeo)
		return
	var falta := Vector2(_paso.x - k.x, _paso.z - k.z).length()
	if _ruta.is_empty():
		if destino == null:
			_paso = null
		return
	var siguiente: Vector3 = _ruta[0]
	if (destino == null and falta < 0.6) or (destino != null and falta < VELOCIDAD * 1.8 * delta + 0.2
			and _recta_libre(k, siguiente)):
		_paso = _ruta.pop_front()
		destino = _paso
	elif destino == null:
		_borrar_ruta()


# (18/11, Redmi: REDMI_18_11.md, RECORRIDO.md §5 problema 2) Con TOQUES en DIAGONAL junto a una casa, la recta corta su
# ESQUINA: lo que no se pisa es una casa (no rodeable) y el destino se quedaba ante la esquina, Kael se paraba contra ella
# (Barrio Alto, «t02_diag»; prueba_ciudad_esquinas: 14 de 14 esquinas paradas a 3 m del toque). Si la recta sale de lo
# no andable a menos de ESQUINA_MAX y a la misma cota, y se puede ir de un lado al otro por FUERA de la esquina (en L:
# primero en z y luego en x, o al revés, todo andable), el destino es el punto tocado y Kael la rodea al llegar
# (_bordear, a lo largo de la cara). Cruzar una casa de cara a cara opuesta no es una esquina (la L la atraviesa): la
# recta se para ante ella como antes (y, desde el 19/11, _ajustar_destino busca el rodeo corto). Devuelve el último
# índice de la recta dentro de lo no andable, o -1 si no es una esquina.
const ESQUINA_MAX := 3.0


func _esquina_cortada(a: Vector3, desde: Vector3, hacia: Vector3, i: int, n: int) -> int:
	var paso := Vector2(hacia.x - desde.x, hacia.z - desde.z).length() / maxf(n, 1)
	var j := i
	while j <= n and _prohibido(desde.lerp(hacia, float(j) / maxf(n, 1))):
		j += 1
		if (j - i) * paso > ESQUINA_MAX:
			return -1
	if j > n:
		return -1                                    # (la recta acaba dentro de lo no andable)
	var b := desde.lerp(hacia, float(j) / maxf(n, 1))
	if absf(P.altura(b.x, b.z) - a.y) > SUBE_MAX:
		return -1
	var dentro := desde.lerp(hacia, (float(i) + float(j - 1)) * 0.5 / maxf(n, 1))   # lo cortado de la esquina
	for codo in [Vector2(a.x, b.z), Vector2(b.x, a.z)]:
		# (revisión, 18/11) por fuera de la esquina tiene que caber el cuerpo de Kael: holgado un punto RADIO_CUERPO más
		# allá del codo, alejándose de lo cortado (el codo mismo sale de «a», pegado a la cara, y nunca es holgado). En
		# un pasillo más estrecho que el cuerpo ese punto cae en la otra pared y no se rodea: se para limpio, como antes
		# (si no, _bordear lo haría andar de lado hasta BORDEO_MAX).
		var fuera: Vector2 = codo + (codo - Vector2(dentro.x, dentro.z)).normalized() * Comun.RADIO_CUERPO
		if not P.holgado(fuera.x, fuera.y):
			continue
		if _tramo_andable(Vector2(a.x, a.z), codo, a.y) and _tramo_andable(codo, Vector2(b.x, b.z), a.y):
			return j - 1
	return -1


# Lo andable de a a b cada 0,1 m, sin escalones de más de SUBE_MAX desde la cota y0.
func _tramo_andable(a: Vector2, b: Vector2, y0: float) -> bool:
	var n := maxi(1, int(ceil(a.distance_to(b) / 0.1)))
	var y := y0
	for k in n + 1:
		var q := a.lerp(b, float(k) / n)
		if not P.andable(q.x, q.y):
			return false
		var h := P.altura(q.x, q.y)
		if absf(h - y) > SUBE_MAX:
			return false
		y = h
	return true


# El bloque sólido que se puede rodear en q (lo bajo o pequeño, ver arriba), o [].
func _bloque_rodeable(q: Vector3) -> Array:
	var s := P.sector_en_caja(q.x, q.z)
	if s == "":
		return []
	var id: String = P.trazado(s).bloque_en(q.x, q.z)
	if id == "":
		return []
	for b in P.trazado(s).BLOQUES:
		if b[0] == id:
			var r: Rect2 = b[2]
			if (float(b[4]) <= ALTO_RODEABLE and maxf(r.size.x, r.size.y) <= LARGO_RODEABLE) \
					or (r.size.x <= ANCHO_RODEABLE and r.size.y <= ANCHO_RODEABLE):
				return b
			return []
	return []


# Tocar el suelo: lo que queda más de 1 m por encima de lo que se pisa (tejados, cubiertas) no cuenta. (Recorrido, 16/11)
# Lo alto de un bloque bajo que no se pisa (un pretil de 0,9 m, un banco) tampoco, si detrás se ve suelo: en el Paseo del
# Concejo el pretil del sur se quedaba los toques del metro de paseo que tapa (Kael iba hacia el pretil); si detrás no hay
# suelo, vale como antes (Kael va hacia él).
func _punto_suelo(pantalla: Vector2):
	var desde := cam.project_ray_origin(pantalla)
	var dir := cam.project_ray_normal(pantalla)
	var hasta := desde + dir * 500.0
	var excluir: Array[RID] = []
	var reserva = null
	var primero := true                        # (19/11) aún no ha dado en nada que se vea (lo aclarado no cuenta)
	var edificio = null
	var p = null
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(desde, hasta)
		q.exclude = excluir
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			break
		p = r["position"]
		if primero:
			var e := _edificio_tocado(r)
			if not e.is_empty():                       # ([] aclarado: se ve a través y no cuenta)
				primero = false
				edificio = e[1]
		if p.y < P.altura(p.x, p.z) + 1.0:
			if P.andable(p.x, p.z) or not String((r["collider"] as Node).name).begins_with("Choque_"):
				_toque_edificio = [p, edificio] if edificio != null else null
				return p
			if reserva == null:
				reserva = p
		excluir.append(r["rid"])
	p = reserva if reserva != null else _punto_plano(desde, dir)
	_toque_edificio = [p, edificio] if edificio != null else null
	return p


# (19/11, PC-16) Lo primero que da el rayo del toque: [] si es una pieza ACLARADA ahora (se ve a través: el toque sigue
# hacia lo de detrás, como antes); [punto, null] si es otra cosa (suelo, algo bajo o pequeño, una cubierta…); y
# [punto, punto tocado del EDIFICIO] si es un bloque sólido, alto y que no se rodea (una casa, un muro) sin aclarar: lo
# que se ve en ese píxel es el edificio. El punto tocado del edificio es el del rayo, dentro de su planta, en el suelo.
func _edificio_tocado(r: Dictionary) -> Array:
	var cuerpo := r["collider"] as Node
	var p: Vector3 = r["position"]
	if cuerpo == null or not String(cuerpo.name).begins_with("Choque_"):
		return [p, null]
	var sector := cuerpo.get_parent()
	var s := String(sector.get("id")) if sector != null else ""
	var id := String(cuerpo.name).trim_prefix("Choque_")
	if P.trazado(s) == null:
		return [p, null]
	if sector.has_method("aclarado") and sector.aclarado(id):
		return []
	for b in P.trazado(s).BLOQUES:
		if b[0] == id:
			if not _bloque_alto(b):
				return [p, null]
			var rect: Rect2 = b[2]
			var x := clampf(p.x, rect.position.x + 0.01, rect.end.x - 0.01)
			var z := clampf(p.z, rect.position.y + 0.01, rect.end.y - 0.01)
			return [p, Vector3(x, P.altura(x, z), z)]
	return [p, null]


# Un bloque sólido, alto y que no se rodea (_bloque_rodeable): una casa o un muro. No las cubiertas, copas ni puertas.
func _bloque_alto(b: Array) -> bool:
	var r: Rect2 = b[2]
	if not b[6] or String(b[5]) in Comun.TIPOS_ARRIBA or float(b[4]) <= ALTO_RODEABLE or Comun.fino(b):
		return false
	return not (maxf(r.size.x, r.size.y) <= LARGO_RODEABLE and float(b[4]) <= ALTO_RODEABLE) \
		and not (r.size.x <= ANCHO_RODEABLE and r.size.y <= ANCHO_RODEABLE)


# Si los choques no dan suelo, el mismo rayo contra el PLANO: el primer punto andable con el rayo a su cota o por debajo.
# Lo que se ve de un sector sin montar es su maqueta lejana, sin choques: a la entrada del Paso Cubierto de la Botica,
# en el bajo (3 sectores), el suelo de los Pasajes se veía a 4 m y el toque se perdía (verificación, 16/11). El plano
# ya manda en lo que se pisa, y _ajustar_destino corta el camino en lo no andable.
const RAYO_PLANO := 120.0


func _punto_plano(desde: Vector3, dir: Vector3):
	var paso := 0.25
	var anterior := 0.0
	var t := 0.0
	while t <= RAYO_PLANO:
		var q := desde + dir * t
		if P.sector_en_caja(q.x, q.z) != "" and q.y <= P.altura(q.x, q.z) + 0.02 and P.andable(q.x, q.z):
			var u := anterior                      # (afinado: el primero a 2,5 cm)
			while u < t:
				var w := desde + dir * u
				if w.y <= P.altura(w.x, w.z) + 0.02 and P.andable(w.x, w.z):
					return Vector3(w.x, P.altura(w.x, w.z), w.z)
				u += 0.025
			return Vector3(q.x, P.altura(q.x, q.z), q.z)
		anterior = t
		t += paso
	return null


func suelo_de_pasos(p: Vector3) -> String:
	return "grava" if P.sector_de(p.x, p.z) in ["puerta_sur", "ribera"] else "piedra"


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
	_borrar_ruta()
	if movimiento != "":
		movimiento = ""
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


# ================================================================= API de región

func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return dg != null and dg.current_timeline != null


func avisar(texto: String, efecto := "", seg := 2.8) -> void:
	ultimo_aviso = texto
	if efecto != "" and has_node("/root/Sonido"):
		Sonido.efecto(efecto)
	if aviso == null:
		return
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(seg)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


# Guarda la partida (solo en el banco: va a su archivo, user://banco_pruebas.save).
func guardar() -> void:
	if not en_banco_pruebas():
		return
	guardar_posicion()
	Progreso.guardar(scene_file_path)


func guardar_posicion() -> void:
	if kael == null:
		return
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func ancla(id: String) -> Vector3:
	return P.ancla(id)


# Cuánto sol y cuánto cielo llega a p: en la maqueta, la provisional (sin luz horneada).
func sonda(_p: Vector3) -> Vector2:
	return SONDA_PROVISIONAL


func iniciar_dialogo(ruta: String) -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		return false
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = ruta
	dg.start(ruta)
	return true


func _al_terminar_dialogo() -> void:
	if dialogo_actual == "":
		return
	dialogo_actual = ""
	_bloqueo = 0.4
	guardar()


func volver_al_banco() -> void:
	if has_node("/root/Recursos") and not Recursos.cambiando:
		Recursos.cambiar_escena(load(BP_RUTA).ESCENA)


# «Guardar y recargar»: guarda, lee el archivo del banco, lo restaura y vuelve a ESTA escena.
# (17/11) Kael se para al TOCAR el botón (button_down: _parar_kael) y ya no se mueve hasta que la escena se va
# (_recargando): antes seguía andando hacia su destino entre el toque y la suelta del botón y, ya guardado, bajo el negro
# de la carga, y reaparecía donde estaba al soltar, no al tocar (hasta 1 m más allá andando, y al otro lado de la linde
# del Paso de la Botica o de la Calle del Cuervo: diag_ciudad_romper, 3 fallos desde 2afc6ed).
var _recargando := false


func guardar_y_recargar() -> void:
	if ocupado() or not en_banco_pruebas() or not has_node("/root/Recursos") or Recursos.cambiando:
		return
	_parar_kael()
	_recargando = true
	guardar()
	var d = Progreso.leer(Progreso.archivo())
	if d is Dictionary:
		Progreso.restaurar(d)
	Recursos.cambiar_escena(scene_file_path)


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	if kael == null or fuera_del_banco or _recargando:
		return
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		return
	_t_juego += delta
	var k0 := kael.global_position
	var d0 = destino
	super(delta)
	_deslizar(delta, k0)
	_bordear(delta, k0, d0)
	_seguir_ruta(delta)
	cargador.actualizar(kael.global_position)
	_comprobar_cerca()
	_t_titulo -= delta
	if _t_titulo <= 0.0:
		_t_titulo = 0.5
		_poner_titulo()


# Con teclas o mando, en DIAGONAL contra una pared: si el paso entero no pasa (vista3d.gd lo descarta), Kael se desliza a
# lo largo de ella con la parte del paso que sí pasa (solo en x o solo en z), con las mismas reglas (_altura_suelo:
# escalón, rodillas y lo que no se pisa). Pegado a la pared norte del Paso de la Botica, ↑+→ avanzaba 0,10 m en 1,5 s
# (verificación, 16/11). Solo en la ciudad: vista3d.gd es de todas las regiones 3D y no cambia. Con clics, la esquina la
# rodea _bordear (y _ajustar_destino ya no corta el destino ante ella: _esquina_cortada, 18/11).
var _deslizando := false


func _deslizar(delta: float, k0: Vector3) -> void:
	var dir := direccion_teclas
	var desliza := false
	if dir.length() > 0.1 and absf(dir.x) > 0.05 and absf(dir.y) > 0.05 and kael.global_position.is_equal_approx(k0) \
			and not ocupado():
		var paso := Vector3(dir.x, 0.0, dir.y).normalized()
		var total := VELOCIDAD * clampf(dir.length(), STICK_MIN, 1.0) * delta
		var partes := [Vector3(paso.x, 0.0, 0.0), Vector3(0.0, 0.0, paso.z)]
		if absf(paso.z) > absf(paso.x):
			partes.reverse()
		for parte in partes:
			var largo := total * (parte as Vector3).length()
			var hacia := (parte as Vector3).normalized()
			var tramos := maxi(1, ceili(largo / TRAMO_MAX))
			var andado := 0.0
			for t in tramos:
				var siguiente: Vector3 = kael.global_position + hacia * (largo / tramos)
				var y := _altura_suelo(siguiente, kael.global_position.y)
				if is_nan(y):
					break
				kael.global_position = Vector3(siguiente.x, y, siguiente.z)
				andado += largo / tramos
			if andado > 0.0:
				desliza = true
				kael.mirar(paso, 0.12)
				if kael.has_method("marcha"):
					kael.marcha(andado / maxf(delta, 0.0001))   # (movimiento sigue en "": vista3d no la para)
				elif not _deslizando:
					kael.andar()
				break
	if _deslizando and not desliza and movimiento == "":
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()
	_deslizando = desliza


# (17/11, Redmi) Con TOQUES, rodear lo que corta el paso: si vista3d no avanza hacia el destino (el rayo de las rodillas
# da en algo, o el paso entraría en la franja del cuerpo junto a una pared: _altura_suelo) y lo que frena es un BLOQUE (no
# el borde del suelo), Kael anda a lo largo de su cara, hacia la esquina por la que se llega antes al destino, y el
# destino se mantiene; en cuanto la recta queda libre, vista3d sigue derecho. Así se rodea el pilón de la fuente al tocar
# detrás de él (Redmi, 16/11: Kael se quedaba pegado), un puesto o un pilar, y una esquina rozada no para a Kael. Como
# mucho BORDEO_MAX segundos por destino (no busca caminos: tras una pared larga se para como antes).
const BORDEO_MAX := 4.0
const HOLGURA_RODEO := 0.5
var _bordeo_destino = null                 # el destino que se está rodeando
var _bordeo_t := 0.0
var _bordeo_signo := {}                    # id del bloque → +1/−1 (el lado elegido, para no cambiar a medio rodeo)
var _bordeando := false


func _bordear(delta: float, k0: Vector3, d0) -> void:
	var bordea := false
	if d0 != null and destino == null and direccion_teclas.length() <= 0.1 and kael.global_position.is_equal_approx(k0) \
			and not ocupado() and Vector2(d0.x - k0.x, d0.z - k0.z).length() >= 0.15:
		if _bordeo_destino == null or not (d0 as Vector3).is_equal_approx(_bordeo_destino):
			_bordeo_destino = d0
			_bordeo_t = 0.0
			_bordeo_signo.clear()
		_bordeo_t += delta
		if _bordeo_t <= BORDEO_MAX:
			bordea = _rodear(delta, d0)
			if bordea:
				destino = d0                         # (vista3d lo soltó al no avanzar)
	if _bordeando and not bordea and movimiento == "" and destino == null:
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()
	_bordeando = bordea


# Un paso a lo largo de la cara del bloque que frena a Kael yendo hacia «meta». true si avanza.
func _rodear(delta: float, meta: Vector3) -> bool:
	var k := kael.global_position
	var falta := Vector2(meta.x - k.x, meta.z - k.z)
	var dir := falta.normalized()
	var sonda := Vector2(k.x, k.z) + dir * 0.35
	var b := _bloque_que_frena(sonda)
	if b.is_empty():
		return false                                 # (el borde del suelo o una cuesta: se para como antes)
	var r: Rect2 = b[2]
	var c := Vector2(clampf(k.x, r.position.x, r.end.x), clampf(k.z, r.position.y, r.end.y))
	var n := Vector2(k.x, k.z) - c
	if n.length() < 0.001:
		n = -dir
	var normal := Vector2(signf(n.x), 0.0) if absf(n.x) >= absf(n.y) else Vector2(0.0, signf(n.y))
	# (si el destino no está DETRÁS de esa cara, ya se ha llegado a lo más cerca: tocando junto al pilón, Kael se movía de
	# lado hasta 4 s; recorrido, 17/11)
	if (Vector2(meta.x, meta.z) - c).dot(normal) > -0.1:
		return false
	var t := Vector2(-normal.y, normal.x)
	var id := String(b[0])
	var signo: float = _bordeo_signo.get(id, 0.0)
	if signo == 0.0:
		var avance := t.dot(falta)
		if absf(avance) > 0.25 * falta.length():
			signo = signf(avance)
		else:                                        # de frente: por el lado que antes deja atrás el bloque
			var mas := -INF
			var menos := -INF
			for e in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
				mas = maxf(mas, t.dot(e - Vector2(k.x, k.z)))
				menos = maxf(menos, -t.dot(e - Vector2(k.x, k.z)))
			signo = 1.0 if mas <= menos else -1.0
		_bordeo_signo[id] = signo
	# a lo largo de la cara y, si está a menos de HOLGURA_RODEO de ella, apartándose un poco (rodeo más abierto: el grupo,
	# que sigue el rastro de Kael, no roza las esquinas); si apartarse no se puede, solo a lo largo
	var total := VELOCIDAD * (1.8 if falta.length() > CORRER_DESDE else 1.0) * delta
	var tramos := maxi(1, ceili(total / TRAMO_MAX))
	var andado := 0.0
	var paso := Vector3(t.x * signo, 0.0, t.y * signo)
	for intento in 2:
		if intento == 0:
			if Comun.distancia_planta(r, Vector2(k.x, k.z)) >= HOLGURA_RODEO:
				continue
			paso = Vector3(t.x * signo + normal.x * 0.6, 0.0, t.y * signo + normal.y * 0.6).normalized()
		else:
			paso = Vector3(t.x * signo, 0.0, t.y * signo)
		for i in tramos:
			var siguiente: Vector3 = kael.global_position + paso * (total / tramos)
			var y := _altura_suelo(siguiente, kael.global_position.y)
			if is_nan(y):
				break
			kael.global_position = Vector3(siguiente.x, y, siguiente.z)
			andado += total / tramos
		if andado > 0.0:
			break
	if andado <= 0.0:
		return false
	kael.mirar(paso, 0.12)
	if kael.has_method("marcha"):
		kael.marcha(andado / maxf(delta, 0.0001))
	elif not _bordeando:
		kael.andar()
	return true


# El bloque sólido que frena a Kael ante «sonda» (0,35 m por delante): el de ese punto o, si allí se pisa (lo frenó el
# rayo de las rodillas o la franja del cuerpo), el sólido más cercano a menos de 0,8 m. [] si es el borde del suelo.
func _bloque_que_frena(sonda: Vector2) -> Array:
	var mejor: Array = []
	var dmin := 0.8
	for s in P.ORDEN:
		if P.distancia_a_sector(s, sonda) > dmin:
			continue
		for b in P.trazado(s).BLOQUES:
			if not b[6]:
				continue
			var d := Comun.distancia_planta(b[2], sonda)
			if d < dmin:
				dmin = d
				mejor = b
	if mejor.is_empty() and not P.andable(sonda.x, sonda.y):
		return []
	return mejor


# [id, posición, radio, texto] de lo que se usa cerca: las puertas previstas y la Puerta del Sur.
func piezas_al_alcance() -> Array:
	if _puertas.is_empty():
		_puertas = P.puertas()
	var r: Array = [["puerta_sur", P.ancla("puerta_sur"), RADIO_PUERTA_SUR, "Salir por la Puerta del Sur"]]
	for pu in _puertas:
		var d: Dictionary = pu[2]
		r.append(["entrar_%s/%s" % [pu[0], pu[1]], d["fuera"], float(d["radio"]), d["texto"]])
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	var p := kael.global_position
	for pz in piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := Vector2(p.x - q.x, p.z - q.z).length()
		if d < float(pz[2]) and d < mejor and absf(p.y - q.y) < 1.6:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != "" and _bloqueo <= 0.0


func _unhandled_input(ev: InputEvent) -> void:
	if fuera_del_banco or kael == null or ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	_arrastre = ev is InputEventScreenDrag or ev is InputEventMouseMotion   # (_ajustar_destino: rodeos al arrastrar)
	super(ev)
	_arrastre = false


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado() or cerca == "":
		return
	_bloqueo = 0.5
	if cerca.begins_with("entrar_"):
		avisar(TEXTO_OBRAS, "", 2.4)               # (los interiores no existen ni se cargan: solo se prevén las puertas)
	elif cerca == "puerta_sur":
		avisar(TEXTO_SALIDA, "", 3.2)


# ================================================================= interfaz

func _poner_titulo() -> void:
	if titulo == null or cargador == null:
		return
	var s: String = cargador.actual
	titulo.text = "Ciudad de Oakhaven (maqueta, en pruebas) · %s · perfil %s · %d de 8 sectores montados" % [
		P.SECTORES[s]["nombre"] if P.SECTORES.has(s) else "—", nombre_perfil, cargador.montados.size()]


func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	titulo = Label.new()
	titulo.position = Vector2(250, 40)
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84))
	titulo.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.06, 0.85))
	titulo.add_theme_constant_override("outline_size", 6)
	capa_ui.add_child(titulo)
	boton_accion = Button.new()
	boton_accion.position = Vector2(960, 600)
	boton_accion.custom_minimum_size = Vector2(290, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa_ui.add_child(boton_accion)
	boton_recargar = Button.new()
	boton_recargar.text = "Guardar y recargar"
	boton_recargar.position = Vector2(16, 152)
	boton_recargar.custom_minimum_size = Vector2(210, 48)
	boton_recargar.add_theme_font_size_override("font_size", 19)
	boton_recargar.focus_mode = Control.FOCUS_NONE
	boton_recargar.button_down.connect(_parar_kael)
	boton_recargar.pressed.connect(guardar_y_recargar)
	capa_ui.add_child(boton_recargar)
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
	_poner_titulo()
