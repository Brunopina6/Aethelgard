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
# No tienen colisión: no estorban a Kael ni a los toques en el suelo. Las comprobaciones del suelo son las de Kael
# (prototipos/vista3d.gd): escalón máximo, pendiente máxima, nada a la altura de las rodillas y las zonas prohibidas
# de la escena (_prohibido).
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
const CORRE_SI := 6.0            # pasa a correr por encima de esta velocidad...
const ANDA_SI := 5.2             # ...y vuelve a andar por debajo de esta (así no parpadea entre las dos)
const SUBE_MAX := 0.5            # escalón máximo, como Kael
const PENDIENTE_MAX := 40.0      # grados, como Kael
const RODILLAS := 0.6            # altura de la comprobación de obstáculos, como Kael (SUBE_MAX + 0,1)
const RUTAS := {"Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}
const ESCALA := {"Lya": 0.6 / 0.67, "Garon": 1.0}

var escena: Node3D               # la región: _prohibido(p) y el mundo físico
var kael: Node3D
var miembros: Array = []         # uno por acompañante, en orden: el primero sigue a Kael y cada uno al anterior
var _previa := {}                # posición de cada uno (Kael incluido) en el fotograma anterior
var _vel := {}                   # velocidad de cada uno en el suelo (m/s)


# Crea a los acompañantes que estén en el grupo y tengan modelo 3D. Después hay que llamar a colocar().
func preparar(region: Node3D, lider: Node3D, nombres: Array) -> void:
	escena = region
	kael = lider
	for n in nombres:
		_anadir(n)


# Se une alguien en mitad de la escena (la misión): aparece en un sitio libre cerca de «desde», va el último de la fila
# y anda hasta su sitio detrás del de delante.
func unir(n: String, desde: Vector3) -> void:
	for m in miembros:
		if m["nombre"] == n:
			return
	if not _anadir(n):
		return
	var m: Dictionary = miembros[miembros.size() - 1]
	var p := _sitio_libre(desde, Vector3.BACK, 0.9, _ocupados(m["nodo"]))
	_reiniciar(m, p, m["lider"].global_position - p)
	_previa.erase(m["nodo"])


func _anadir(n: String) -> bool:
	if not RUTAS.has(n) or not ResourceLoader.exists(RUTAS[n]):
		return false
	var delante: Node3D = miembros[miembros.size() - 1]["nodo"] if not miembros.is_empty() else kael
	var nodo = load(RUTAS[n]).new()
	nodo.name = n
	add_child(nodo)
	if nodo.get("anim") == null or nodo.get("skel") == null:   # sin modelo no sale (como en el combate)
		nodo.queue_free()
		return false
	nodo.scale = Vector3.ONE * ESCALA.get(n, 1.0)
	var m := {"nombre": n, "nodo": nodo, "lider": delante, "cola": [], "ultimo": delante.global_position,
		"estado": "", "apartar": null, "t_apartar": 0.0, "dir": Vector3.ZERO, "t_quieto": 0.0, "mira": false,
		"reposo": ""}
	# Garon, quieto, se queda en guardia de combate con las dos espadas apuntando adelante (a Lya). Al explorar
	# usa la guardia tranquila de garon_3d.gd (el principio de «Juicio», con las espadas bajas).
	if nodo.has_method("_guardia_viva") and nodo.anim.has_animation("Juicio"):
		var lib: AnimationLibrary = nodo.anim.get_animation_library("")
		if not lib.has_animation("Calma"):
			lib.add_animation("Calma", nodo._guardia_viva("Juicio"))
		m["reposo"] = "Calma"
	miembros.append(m)
	return true


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
	if kael == null or not is_instance_valid(kael) or miembros.is_empty():
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
		var vel := clampf(v_lider + ALCANCE * (d - SEPARACION), VEL_ANDAR * 0.6, VEL_MAX)
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
	m["t_quieto"] = 0.0
	m["mira"] = false
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
			m["nodo"].reposo()
			if m["reposo"] != "":
				m["nodo"].play(m["reposo"], 0.3)


func _reiniciar(m: Dictionary, p: Vector3, mirada: Vector3) -> void:
	var nodo = m["nodo"]
	nodo.global_position = p
	m["cola"].clear()
	m["ultimo"] = m["lider"].global_position
	m["apartar"] = null
	m["t_quieto"] = 0.0
	m["mira"] = false
	_poner_estado(m, "")
	mirada.y = 0.0
	if mirada.length() > 0.01:
		nodo.mirar(mirada, 0.0)
		m["dir"] = mirada.normalized()


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
	for n in nodos():
		if n != menos:
			r.append(n.global_position)
	return r


# Un sitio a «dist» de «desde» hacia «dir» (o girando poco a poco a los lados) donde se pueda estar: suelo andable,
# nada en medio y sin pisar a nadie. Si no hay ninguno, el mismo «desde».
func _sitio_libre(desde: Vector3, dir: Vector3, dist: float, ocupados: Array) -> Vector3:
	for giro in [0.0, 25.0, -25.0, 50.0, -50.0, 80.0, -80.0, 115.0, -115.0, 150.0, -150.0, 180.0]:
		for f in [1.0, 0.7, 1.3]:
			var q: Vector3 = desde + dir.rotated(Vector3.UP, deg_to_rad(giro)) * dist * f
			var y := _suelo(q, desde.y)
			if is_nan(y):
				continue
			q.y = y
			if not _despejado(desde, q):
				continue
			var libre := true
			for o in ocupados:
				if _plana(o, q) < 0.75:
					libre = false
					break
			if libre:
				return q
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
