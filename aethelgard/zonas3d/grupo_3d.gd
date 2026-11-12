extends Node3D
# Grupo que acompaña a Kael en la exploración 3D (T-022): Lya y Garon le siguen por la región.
#
# Cómo siguen:
#   - Cada uno va detrás del de delante: Lya sigue a Kael y Garon a Lya. El de delante deja un rastro de puntos al
#     andar y el de detrás lo recorre, así que pasa por donde pasó él: el puente, la orilla y los rodeos a los
#     árboles. Nunca pisa el río ni el barranco, porque por ahí no pasó nadie.
#   - Solo anda si se ha quedado a más de SEPARACION del de delante. Va a su paso, algo más deprisa si se queda
#     atrás, y anda o corre según su velocidad. Cuando está cerca, se para y al rato se vuelve hacia él.
#   - Si el de delante viene hacia él (al dar media vuelta), se aparta a un lado para dejarle pasar.
#   - Si el de delante aparece en otro sitio, o se queda muy lejos (más de PERDIDO), se coloca detrás de él.
#   - Andan o corren según su velocidad real, con el ritmo que deja el pie apoyado quieto en el suelo (marcha() de
#     maga_3d.gd, T-084 tanda 2): se acercan andando los últimos pasos (VEL_ACERCARSE) y corren a la marcha normal.
# No tienen colisión: no estorban a Kael ni a los toques en el suelo. Las comprobaciones del suelo son las de Kael
# (prototipos/vista3d.gd): escalón máximo, pendiente máxima, nada a la altura de las rodillas y las zonas prohibidas
# de la escena (_prohibido).
# Quien todavía no va con el grupo puede esperar en un sitio de la región (esperar(), p. ej. Garon junto a Tilo antes de
# PV-05): está en la escena, en su reposo, mira a quien habla y no lo cuenta nodos(); mientras espera, Kael no lo
# atraviesa. seguir() (o unir()) lo pone en la fila desde donde está.
# Pasos: si la región da «pasos_superficie» (posición → «piedra», «hierba»…) antes de crearlos, cada uno lleva los suyos
# (Sonido.pasos_3d, como Kael).
# API (la usan pastos_verdes_3d.gd y otras regiones 3D): preparar, colocar, unir, esperar, seguir, nodos, miembros y
# pasos_superficie. Lo que la región ofrece: _prohibido(p) (si lo tiene), su mundo físico y, para las miradas, sus
# personajes como propiedades con el nombre en minúsculas (p. ej. «tilo»).
# Tamaños: los del combate (combate.gd, MODELOS: Lya a 0,6 y Kael y Garon a 0,67).
# Su coste se mide con el banco GRUPO de la región (zonas3d/pastos_verdes_3d.gd).

const SEPARACION := 1.8          # metros hasta el de delante en los que se queda quieto (con 1,5 el sable de Kael
                                 # casi rozaba a Lya: capturas de prueba_grupo3d_fotos)
const ESPACIO := 0.9             # si el de delante viene hacia él y está más cerca, se aparta
const PASO_RASTRO := 0.2         # cada cuántos metros deja un punto el de delante
const SALTO := 3.0               # si el de delante se mueve más que esto de golpe, ha aparecido en otro sitio
const PERDIDO := 8.0             # más lejos que esto, se coloca detrás del de delante
const VEL_ANDAR := 4.2           # las de Kael (prototipos/vista3d.gd: VELOCIDAD y, al correr, ×1,8)
const VEL_CORRER := 7.56
const VEL_MAX := 8.7
const ALCANCE := 2.0             # m/s de más por cada metro que se queda atrás
const VEL_ACERCARSE := 1.3       # lo más despacio que se acerca (antes, 2,52: llegaba corriendo y se paraba en seco);
                                 # a esta velocidad, andando con el pie quieto en el suelo (T-084, tanda 2)
const CORRE_SI := 6.0            # sin marcha() (otro modelo): pasa a correr por encima de esta velocidad...
const ANDA_SI := 5.2             # ...y vuelve a andar por debajo de esta (así no parpadea entre las dos)
const SUBE_MAX := 0.5            # escalón máximo, como Kael
const PENDIENTE_MAX := 40.0      # grados, como Kael
const RODILLAS := 0.6            # altura de la comprobación de obstáculos, como Kael (SUBE_MAX + 0,1)
# V12: Naira (PROPUESTA, NO CANON; modelo PROVISIONAL). Solo sale si va activa (grupo.gd: su hito o el interruptor
# «naira_v12», APAGADO). 1,55 m: entre Lya (1,52) y Kael (1,7).
const RUTAS := {"Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd", "Naira": "res://personajes/naira/naira_3d.gd"}
const ESCALA := {"Lya": 0.6 / 0.67, "Garon": 1.0, "Naira": 1.55 / 1.7}
const UNIR_HOLGURA := 1.3        # al unirse alguien, metros libres a su alrededor (T-084)

var escena: Node3D               # la región: _prohibido(p) y el mundo físico
var kael: Node3D
var miembros: Array = []         # uno por acompañante, en orden: el primero sigue a Kael y cada uno al anterior
var esperando := {}              # nombre → los mismos datos que en «miembros»: está en la región, sin seguir a nadie
var pasos_superficie := Callable()   # posición → suelo («piedra», «hierba»…): si la región la da, llevan pasos
var _previa := {}                # posición de cada uno (Kael incluido) en el fotograma anterior
var _vel := {}                   # velocidad de cada uno en el suelo (m/s)


# Crea a los acompañantes que estén en el grupo y tengan modelo 3D. Después hay que llamar a colocar().
func preparar(region: Node3D, lider: Node3D, nombres: Array) -> void:
	escena = region
	kael = lider
	for n in nombres:
		_anadir(n)
	for n in reclutas_activos(nombres):              # V12: los reclutas activos, detrás de los de siempre
		_anadir(n)


# V12, grupo con reserva: las regiones eligen a los acompañantes de entre los tres de siempre (grupo.gd EN_EL_GRUPO);
# los reclutas activos (Naira) se añaden aquí, al final de la fila, sin tocar las regiones. Nunca más acompañantes
# que los que caben en el grupo activo (MAX_ACTIVOS menos Kael). Sin reclutas activos, nada (la fila de siempre).
static func reclutas_activos(nombres: Array) -> Array:
	var G = load("res://grupo.gd")
	var r: Array = []
	var sitio: int = G.MAX_ACTIVOS - 1 - nombres.size()
	for n in G.activos():
		if n in G.RECLUTAS and not n in nombres and RUTAS.has(n) and r.size() < sitio:
			r.append(n)
	return r


# Se une alguien en mitad de la escena (la misión): aparece en un sitio libre cerca de «desde», va el último de la fila
# y anda hasta su sitio detrás del de delante. Con «exacto», aparece en el mismo «desde» si ahí se puede estar (Lya
# llegando por el camino en PV-03). Si estaba esperando en la región (esperar()), no aparece: sigue desde donde está.
func unir(n: String, desde: Vector3, exacto := false) -> void:
	if esperando.has(n):
		seguir(n)
		return
	for m in miembros:
		if m["nombre"] == n:
			return
	if not _anadir(n):
		return
	var m: Dictionary = miembros[miembros.size() - 1]
	var ocupados := _ocupados(m["nodo"])
	var p := Vector3.INF
	if exacto:
		var y := _suelo(desde, desde.y)
		if not is_nan(y) and _libre(Vector3(desde.x, y, desde.z), ocupados, UNIR_HOLGURA):
			p = Vector3(desde.x, y, desde.z)
	# Aparece con algo de holgura: ni encima de quien estaba en «desde» (Tilo, al unirse Garon) ni pegado a Kael o al
	# resto (con 0,75 m, Garon salía a 1 m de Kael con una espada cruzada a la altura de sus piernas; T-084).
	if p == Vector3.INF:
		p = _sitio_libre(desde, Vector3.BACK, 1.4, ocupados + [desde], UNIR_HOLGURA)
	_reiniciar(m, p, m["lider"].global_position - p)
	_previa.erase(m["nodo"])


# Alguien de la región que aún no va con el grupo espera en «sitio», mirando hacia «mirada» (T-084, tanda 2). Está en la
# escena con su reposo de exploración y mira a quien habla en los diálogos, pero no sigue a nadie ni cuenta en nodos().
# Mientras espera tiene un cilindro de choque, como Tilo: Kael no lo atraviesa. Devuelve su nodo (o null sin modelo).
func esperar(n: String, sitio: Vector3, mirada := Vector3.ZERO) -> Node3D:
	if esperando.has(n):
		return esperando[n]["nodo"]
	for m in miembros:
		if m["nombre"] == n:
			return m["nodo"]                         # ya va con el grupo
	var m := _crear(n)
	if m.is_empty():
		return null
	m["lider"] = null
	esperando[n] = m
	var y := _suelo(sitio, sitio.y)
	_reiniciar(m, Vector3(sitio.x, sitio.y if is_nan(y) else y, sitio.z), mirada)
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Choque"
	var forma := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.35
	cil.height = 1.7
	forma.shape = cil
	forma.position.y = 0.85
	cuerpo.add_child(forma)
	m["nodo"].add_child(cuerpo)
	return m["nodo"]


# Quien esperaba se une a la fila (el último) desde donde está, sin aparecer en otro sitio. False si no esperaba.
func seguir(n: String) -> bool:
	if not esperando.has(n):
		return false
	var m: Dictionary = esperando[n]
	esperando.erase(n)
	var choque: Node = m["nodo"].get_node_or_null("Choque")
	if choque != null:
		choque.get_parent().remove_child(choque)     # fuera ya del mundo físico: no estorba a sus propios pasos
		choque.queue_free()
	m["lider"] = miembros[miembros.size() - 1]["nodo"] if not miembros.is_empty() else kael
	m["ultimo"] = m["lider"].global_position
	m["cola"].clear()
	m["t_quieto"] = 0.0
	m["mira"] = false
	miembros.append(m)
	_previa.erase(m["nodo"])
	return true


func _anadir(n: String) -> bool:
	var m := _crear(n)
	if m.is_empty():
		return false
	var delante: Node3D = miembros[miembros.size() - 1]["nodo"] if not miembros.is_empty() else kael
	m["lider"] = delante
	m["ultimo"] = delante.global_position
	miembros.append(m)
	return true


# El personaje con su modelo, sus datos de seguimiento y su reposo de exploración; {} si no hay modelo.
func _crear(n: String) -> Dictionary:
	if not RUTAS.has(n) or not ResourceLoader.exists(RUTAS[n]):
		return {}
	var nodo = load(RUTAS[n]).new()
	nodo.name = n
	add_child(nodo)
	if nodo.get("anim") == null or nodo.get("skel") == null:   # sin modelo no sale (como en el combate)
		nodo.queue_free()
		return {}
	nodo.scale = Vector3.ONE * ESCALA.get(n, 1.0)
	if nodo.has_method("activar_esperas"):
		nodo.activar_esperas()                     # quieto un rato, hace una de sus esperas (esperas_3d.gd)
	# «estado» empieza en «?» (ninguno) para que el primer _poner_estado(m, "") ponga de verdad el reposo de
	# exploración: con «» de partida no hacía nada y Garon se quedaba con la guardia de combate de garon_3d.gd (las
	# dos espadas hacia delante) al aparecer y al empezar la región, hasta que andaba por primera vez (T-084).
	var m := {"nombre": n, "nodo": nodo, "lider": null, "cola": [], "ultimo": nodo.global_position,
		"estado": "?", "apartar": null, "t_apartar": 0.0, "dir": Vector3.ZERO, "t_quieto": 0.0, "mira": false,
		"reposo": "", "v": 0.0}
	# Sus pasos, con el mismo suelo que los de Kael (la región dice cuál). Uno por personaje: solo se crean aquí.
	var son = get_node_or_null("/root/Sonido")
	if son != null and pasos_superficie.is_valid() and son.has_method("pasos_3d"):
		son.pasos_3d(nodo, pasos_superficie)
	# Garon, quieto, se queda en guardia de combate con las dos espadas apuntando adelante (a Lya). Al explorar
	# usa la guardia tranquila de garon_3d.gd (el principio de «Juicio», con las espadas bajas).
	if nodo.has_method("_guardia_viva") and nodo.anim.has_animation("Juicio"):
		var lib: AnimationLibrary = nodo.anim.get_animation_library("")
		if not lib.has_animation("Calma"):
			var calma: Animation = nodo._guardia_viva("Juicio")
			calma.loop_mode = Animation.LOOP_LINEAR   # en bucle, como su guardia de combate (si no, a los 3,2 s se
			lib.add_animation("Calma", calma)         # quedaba parado del todo: sin el vaivén del peso) (T-084)
		m["reposo"] = "Calma"
	return m


func nodos() -> Array:
	return miembros.map(func(m): return m["nodo"])


# Coloca a todos junto a Kael, en V detrás de él (hacia «atras»), en sitios por los que se puede andar.
func colocar(atras: Vector3) -> void:
	atras.y = 0.0
	atras = atras.normalized() if atras.length() > 0.01 else Vector3.BACK
	var k := kael.global_position
	var puestos: Array = [k]
	for i in miembros.size():
		var lado := 1.0 if i % 2 == 0 else -1.0
		var p := _sitio_libre(k, atras.rotated(Vector3.UP, deg_to_rad(35.0) * lado), 1.7, puestos)
		_reiniciar(miembros[i], p, -atras)
		puestos.append(p)
	_previa.clear()
	_vel.clear()


func _process(delta: float) -> void:
	if kael == null or not is_instance_valid(kael):
		return
	_mirar_al_que_habla()
	if miembros.is_empty():
		return
	delta = maxf(delta, 0.0001)
	for n in [kael] + nodos():
		var p: Vector3 = n.global_position
		var antes: Vector3 = _previa.get(n, p)
		var v := Vector3(p.x - antes.x, 0.0, p.z - antes.z)
		_vel[n] = v / delta if v.length() < SALTO else Vector3.ZERO    # aparecer en otro sitio no es andar
		_previa[n] = p
	for i in miembros.size():
		_seguir(miembros[i], i, delta)


func _seguir(m: Dictionary, i: int, delta: float) -> void:
	var nodo: Node3D = m["nodo"]
	var lider: Node3D = m["lider"]
	var pos := nodo.global_position
	var lp := lider.global_position
	var movido := _plana(lp, m["ultimo"])
	var d := _plana(pos, lp)
	if movido > SALTO or d > PERDIDO:                 # el de delante está en otro sitio: se coloca detrás de él
		_reiniciar(m, _sitio_libre(lp, _atras_de(lider, pos), SEPARACION, _ocupados(nodo)), lp - pos)
		return
	if movido >= PASO_RASTRO:                         # el rastro del de delante
		m["ultimo"] = lp
		m["cola"].append(lp)
	m["t_apartar"] = maxf(0.0, m["t_apartar"] - delta)
	if m["apartar"] == null and m["t_apartar"] <= 0.0:
		var quien = _quien_viene(i, pos)
		if quien != null:
			m["apartar"] = _sitio_apartado(pos, quien)
			m["t_apartar"] = 0.4                      # si no hay sitio, no lo vuelve a buscar enseguida
	if m["apartar"] != null:
		if _andar_recto(m, m["apartar"], VEL_ANDAR, delta):
			m["apartar"] = null
		return
	if d > SEPARACION:
		var v_lider: float = _vel.get(lider, Vector3.ZERO).length()
		var vel := clampf(v_lider + ALCANCE * (d - SEPARACION), VEL_ACERCARSE, VEL_MAX)
		if _por_el_rastro(m, vel, delta, lp):
			return
	_quieto(m, delta, lp)


# Avanza por el rastro del de delante. Sin rastro (el de delante apenas se ha movido), va recto hacia él si no hay
# nada en medio. Devuelve false si no ha podido moverse.
func _por_el_rastro(m: Dictionary, vel: float, delta: float, lp: Vector3) -> bool:
	var nodo: Node3D = m["nodo"]
	var inicio := nodo.global_position
	var pos := inicio
	var resto := vel * delta
	var cola: Array = m["cola"]
	while resto > 0.0001 and not cola.is_empty():
		var meta: Vector3 = cola[0]
		var falta := Vector2(meta.x - pos.x, meta.z - pos.z)
		var l := falta.length()
		if l <= resto:
			pos = meta
			resto -= l
			cola.pop_front()
		else:
			var t := resto / l
			pos = Vector3(pos.x + falta.x * t, lerpf(pos.y, meta.y, t), pos.z + falta.y * t)
			resto = 0.0
	if cola.is_empty() and resto > 0.0001 and _despejado(pos, lp):
		var falta := Vector2(lp.x - pos.x, lp.z - pos.z)
		var paso := minf(resto, falta.length() - SEPARACION)
		if paso > 0.0:
			var q := pos + Vector3(falta.x, 0.0, falta.y).normalized() * paso
			var y := _suelo(q, pos.y)
			if not is_nan(y):
				pos = Vector3(q.x, y, q.z)
	if _plana(pos, inicio) < 0.0001:
		return false
	_mover(m, inicio, pos, delta)
	return true


# Un paso recto hacia «meta» (para apartarse). Devuelve true al llegar o si ya no puede seguir.
func _andar_recto(m: Dictionary, meta: Vector3, vel: float, delta: float) -> bool:
	var nodo: Node3D = m["nodo"]
	var pos := nodo.global_position
	var falta := Vector3(meta.x - pos.x, 0.0, meta.z - pos.z)
	var l := falta.length()
	var paso := vel * delta
	if l <= paso:
		_mover(m, pos, meta, delta)
		return true
	var q := pos + falta / l * paso
	var y := _suelo(q, pos.y)
	if is_nan(y):
		return true
	_mover(m, pos, Vector3(q.x, y, q.z), delta)
	return false


# (Los acompañantes van sin tipo: andar(), mirar() y «anim» son de maga_3d.gd, no de Node3D.)
func _mover(m: Dictionary, inicio: Vector3, pos: Vector3, delta: float) -> void:
	var nodo = m["nodo"]
	nodo.global_position = pos
	var paso := Vector3(pos.x - inicio.x, 0.0, pos.z - inicio.z)
	var v := paso.length() / delta
	m["v"] = v
	m["t_quieto"] = 0.0
	m["mira"] = false
	if nodo.has_method("marcha"):
		# Andar o correr y su ritmo, por la velocidad real: el pie apoyado se queda quieto en el suelo (T-084, tanda 2).
		# Antes: andar hasta 6 m/s con el ritmo entre ×0,75 y ×1,25 de un clip de 1,1-1,5 m/s (patinaba ×3).
		var clip: String = nodo.marcha(v)
		if clip == "":
			_poner_estado(m, "")                          # tan despacio que no da un paso: su reposo
		else:
			m["estado"] = clip
	else:
		var estado := "andar"
		if v > (ANDA_SI if m["estado"] == "correr" else CORRE_SI):
			estado = "correr"
		_poner_estado(m, estado)
		nodo.anim.speed_scale = clampf(v / (VEL_CORRER if estado == "correr" else VEL_ANDAR), 0.75, 1.25)
	if paso.length() > 0.001:
		var dir := paso.normalized()
		if m["dir"] == Vector3.ZERO or m["dir"].angle_to(dir) > deg_to_rad(12.0):
			nodo.mirar(dir, 0.12)
			m["dir"] = dir


func _quieto(m: Dictionary, delta: float, lp: Vector3) -> void:
	var nodo = m["nodo"]
	var pos: Vector3 = nodo.global_position
	m["v"] = 0.0
	_poner_estado(m, "")
	m["t_quieto"] += delta
	if not m["cola"].is_empty() and _despejado(pos, lp):   # cerca y sin nada en medio: el rastro antiguo sobra
		m["cola"].clear()
	if m["t_quieto"] > 0.6 and not m["mira"]:               # al rato, se vuelve hacia el de delante
		var hacia := Vector3(lp.x - pos.x, 0.0, lp.z - pos.z)
		if hacia.length() > 0.3:
			nodo.mirar(hacia, 0.5)
			m["dir"] = hacia.normalized()
		m["mira"] = true


func _poner_estado(m: Dictionary, estado: String) -> void:
	if m["estado"] == estado:
		return
	m["estado"] = estado
	match estado:
		"andar":
			m["nodo"].andar()
		"correr":
			m["nodo"].correr()
		_:
			if m["nodo"].has_method("parar_marcha"):
				m["nodo"].parar_marcha()             # sin un paso de más al pararse (maga_3d.gd)
			else:
				m["nodo"].reposo()
			if m["reposo"] != "":
				m["nodo"].play(m["reposo"], 0.3)


func _reiniciar(m: Dictionary, p: Vector3, mirada: Vector3) -> void:
	var nodo = m["nodo"]
	nodo.global_position = p
	m["cola"].clear()
	m["ultimo"] = m["lider"].global_position if m["lider"] != null else p   # (quien espera no sigue a nadie)
	m["v"] = 0.0
	m["apartar"] = null
	m["t_quieto"] = 0.0
	m["mira"] = false
	_poner_estado(m, "")
	mirada.y = 0.0
	if mirada.length() > 0.01:
		nodo.mirar(mirada, 0.0)
		m["dir"] = mirada.normalized()


# ---------------------------------------------------------------- miradas en los diálogos (T-084)

const MIRAR_HASTA := 12.0        # metros: más lejos, no se vuelve (no es una conversación con él)
const MIRAR_ESPERA := 6.0        # quien espera en la región solo se vuelve si la conversación es a su lado (Garon junto
                                 # a Tilo no sigue PV-03 desde 10 m: mira el camino)
const GIRO_MIRADA := 0.45        # segundos que tarda en volverse
var _hablante := ""              # quien hablaba la última vez que se miró (una vez por cambio de interlocutor)


# Mientras dura un diálogo, quien escucha (Kael y los acompañantes que estén quietos) se vuelve hacia quien habla, si
# está en la escena y cerca: una vez por cambio de interlocutor, despacio, y se queda así (nada de moverse todo el
# rato). Quien habla no se mueve. Al acabar, cada uno sigue mirando a donde estaba hasta que vuelve a andar.
func _mirar_al_que_habla() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or dg.current_timeline == null:
		_hablante = ""
		return
	var sp = dg.Text.get_current_speaker()
	var quien: String = sp.display_name if sp != null else ""
	if quien == _hablante:
		return
	_hablante = quien
	var habla: Node3D = _nodo_de(quien)
	if habla == null:
		return
	var esperan: Array = esperando.values()
	for n in [kael] + nodos() + esperan.map(func(e): return e["nodo"]):
		if n == habla:
			continue
		var m = null
		for mm in miembros + esperan:
			if mm["nodo"] == n:
				m = mm
		if m != null and m["estado"] != "":
			continue                                  # andando: mira por dónde va
		var hacia: Vector3 = habla.global_position - n.global_position
		hacia.y = 0.0
		var hasta := MIRAR_ESPERA if m != null and m["lider"] == null else MIRAR_HASTA
		if hacia.length() < 0.3 or hacia.length() > hasta:
			continue
		n.mirar(hacia, GIRO_MIRADA)
		if m != null:
			m["dir"] = hacia.normalized()
			m["mira"] = true


# El personaje 3D de la escena que corresponde a un nombre de Dialogic: Kael, un acompañante o alguien de la región
# (p. ej. «Tilo» → escena.tilo). Null si no está.
func _nodo_de(quien: String) -> Node3D:
	if quien == "":
		return null
	if quien == "Kael":
		return kael
	for m in miembros:
		if m["nombre"] == quien:
			return m["nodo"]
	if esperando.has(quien):
		return esperando[quien]["nodo"]
	var otro = escena.get(quien.to_lower()) if escena != null else null
	if otro is Node3D and is_instance_valid(otro):
		return otro
	return null


# ---------------------------------------------------------------- dejar paso

# El de delante (Kael o un acompañante anterior) que viene andando hacia él y ya está muy cerca, o null.
func _quien_viene(i: int, pos: Vector3):
	var delante: Array = [kael]
	for j in i:
		delante.append(miembros[j]["nodo"])
	for o in delante:
		var op: Vector3 = o.global_position
		var hacia_mi := Vector3(pos.x - op.x, 0.0, pos.z - op.z)
		if hacia_mi.length() > ESPACIO:
			continue
		var v: Vector3 = _vel.get(o, Vector3.ZERO)
		if v.length() < 0.5:
			continue
		if hacia_mi.length() < 0.05 or v.normalized().dot(hacia_mi.normalized()) > 0.2:
			return o
	return null


# Un paso a un lado de la marcha del que viene (hacia el lado en el que ya está), si ahí se puede estar.
func _sitio_apartado(pos: Vector3, quien: Node3D):
	var marcha: Vector3 = _vel.get(quien, Vector3.ZERO).normalized()
	var lado := marcha.cross(Vector3.UP).normalized()
	var qp := quien.global_position
	var s := signf(lado.dot(Vector3(pos.x - qp.x, 0.0, pos.z - qp.z)))
	if s == 0.0:
		s = 1.0
	for signo in [s, -s]:
		for dist in [1.0, 0.7]:
			var q: Vector3 = pos + lado * signo * dist + marcha * 0.3
			var y := _suelo(q, pos.y)
			if is_nan(y):
				continue
			q.y = y
			if _despejado(pos, q):
				return q
	return null


# ---------------------------------------------------------------- sitios y suelo

func _atras_de(lider: Node3D, pos: Vector3) -> Vector3:
	var v: Vector3 = _vel.get(lider, Vector3.ZERO)
	if v.length() > 0.5:
		return -v.normalized()
	var d := pos - lider.global_position
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.BACK


func _ocupados(menos: Node3D) -> Array:
	var r: Array = [kael.global_position]
	for n in nodos() + esperando.values().map(func(e): return e["nodo"]):
		if n != menos:
			r.append(n.global_position)
	return r


func _libre(q: Vector3, ocupados: Array, holgura: float) -> bool:
	for o in ocupados:
		if _plana(o, q) < holgura:
			return false
	return true


# Un sitio a «dist» de «desde» hacia «dir» (o girando poco a poco a los lados) donde se pueda estar: suelo andable,
# nada en medio y sin pisar a nadie. Si no hay ninguno, el mismo «desde».
func _sitio_libre(desde: Vector3, dir: Vector3, dist: float, ocupados: Array, holgura := 0.75) -> Vector3:
	for giro in [0.0, 25.0, -25.0, 50.0, -50.0, 80.0, -80.0, 115.0, -115.0, 150.0, -150.0, 180.0]:
		for f in [1.0, 0.7, 1.3]:
			var q: Vector3 = desde + dir.rotated(Vector3.UP, deg_to_rad(giro)) * dist * f
			var y := _suelo(q, desde.y)
			if is_nan(y):
				continue
			q.y = y
			if not _despejado(desde, q):
				continue
			if _libre(q, ocupados, holgura):
				return q
	if holgura > 0.75:                                # sin sitio con tanta holgura: como antes
		return _sitio_libre(desde, dir, dist, ocupados, 0.75)
	return desde


# Altura del suelo en «p» viniendo desde la altura «y_ref», o NAN si ahí no se puede estar.
func _suelo(p: Vector3, y_ref: float) -> float:
	if escena.has_method("_prohibido") and escena._prohibido(p):
		return NAN
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, y_ref + SUBE_MAX + 0.05, p.z), Vector3(p.x, y_ref - 4.0, p.z))
	var r := escena.get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return NAN
	var y: float = r["position"].y
	if absf(y - y_ref) > SUBE_MAX:
		return NAN
	if r["normal"].y < cos(deg_to_rad(PENDIENTE_MAX)) and absf(y - y_ref) > 0.02:
		return NAN
	return y


# Nada a la altura de las rodillas entre «a» y «b»: pared, pretil, tronco o estatua.
func _despejado(a: Vector3, b: Vector3) -> bool:
	var h := maxf(a.y, b.y) + RODILLAS
	var desde := Vector3(a.x, h, a.z)
	var hasta := Vector3(b.x, h, b.z)
	if desde.distance_to(hasta) < 0.01:
		return true
	return escena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(desde, hasta)).is_empty()


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
