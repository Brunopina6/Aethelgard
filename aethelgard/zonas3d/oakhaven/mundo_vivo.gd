extends Node3D
# Oakhaven vivo (V12, especialista de mundo 3D y NPC, 12/11/2026): vecinos secundarios de la familia chibi
# (personajes/npc_v12/npc_chibi.gd) con rutinas sencillas y baratas: trabajar en su sitio (la forja, el mercado, la
# botica, el huerto), andar entre puntos (un viajero que busca la posada, una vendedora que llega de los Pastos), guardias
# que patrullan y vigilan, niños que juegan a pillar alrededor de la fuente, una barrendera, abuelos en la plaza.
#
# INTERRUPTOR «mundo_vivo_v12», APAGADO por defecto (con él apagado, Oakhaven queda exactamente igual):
#   - Engine.set_meta("mundo_vivo_v12", true)        (antes de entrar en Oakhaven)
#   - el argumento de usuario «mundo_vivo_v12»       (godot ... -- 3d mundo_vivo_v12)
#   - user://ajustes.cfg, [mundo] vivo_v12 = true     (para el móvil, donde no llegan los argumentos)
#   - ACTIVO_POR_DEFECTO = true                       (cuando el usuario lo apruebe)
# Con él, además, los vecinos con nombre (Aldric, Rosa, Albar, Bastián, Doña Encina) cambian su figura provisional por
# la de la familia, con su MISMO diálogo, sitio y rutina (vida3d.gd). Engine «mundo_vivo_sin_vecinos» lo evita (comparar).
#
# COSTE (lo que hace barato esto en el Mali-G57):
#   - Cada NPC es UNA malla con esqueleto (2,3-3,5 k triángulos, LOD automático de la importación), UN material por
#     persona (atlas de 512) y sus clips; nada se simula fuera de la vista.
#   - La animación no corre sola (npc_chibi.gd, modo manual): de cerca (< CERCA) cada fotograma; a media distancia, a
#     ANIM_MEDIA Hz; fuera de la cámara o lejos (> LEJOS), quieta. Más allá de OCULTO, ni se dibuja.
#   - La rutina (andar, girarse, cambiar de tarea) se piensa a LOGICA_LEJOS Hz fuera de la vista: se simplifica, no se
#     detiene del todo, para que al volver no estén todos en el mismo sitio.
#   - Sin físicas: los que andan se paran si Kael está delante (no le empujan nunca) y Kael no los atraviesa (ocupa()).
#   - La hora (oakhaven_vida.gd, «oak_franja»): cada uno sale en sus franjas (los niños se van a casa al anochecer, el
#     mercado cierra) y el cambio se hace solo con la persona lejos de Kael.

const NPC := preload("res://personajes/npc_v12/npc_chibi.gd")
const Palomas := preload("res://zonas3d/oakhaven/palomas.gd")
const PALOMAS := Vector2(37.7, 24.0)      # el grano de la abuela, delante de ella
const Barrios := preload("res://zonas3d/oakhaven/barrios.gd")
const ACTIVO_POR_DEFECTO := false

const CERCA := 12.0             # m: animación cada fotograma
const LEJOS := 28.0             # m: más allá, animación quieta
const OCULTO := 34.0            # m: más allá, ni se dibuja
const ANIM_MEDIA := 15.0        # Hz de animación entre CERCA y LEJOS (y de los que pasan de MAX_CERCA)
const MAX_CERCA := 6            # como mucho, tantos animados cada fotograma (los más cercanos)
const LOGICA_LEJOS := 4.0       # Hz de la rutina fuera de la vista o lejos
const RADIO_HABLAR := 2.0
const RADIO_OCUPA := 0.42       # Kael no entra en este círculo
const DIST_PARAR := 0.95        # quien anda se para si Kael está más cerca que esto delante
const RADIO_SALUDO := 4.2
const PAUSA_SALUDO := 45.0
const TODAS := ["manana", "tarde", "anochecer"]

# Las personas. «rutina»: trabajo (en su sitio, su tarea), ruta (anda por «puntos»; «ida_vuelta» o en vuelta; «pausa»
# en cada punto con «hace»), corro (alrededor de «centro» a «radio»; juega a ratos) o barrer (barre avanzando).
# «mira»: hacia dónde mira quieto (un punto). «franjas»: cuándo está (oakhaven_vida.gd). Casillas = metros (x, z).
const PERSONAS := [
	{"id": "guardia_puerta", "oficio": "guardia", "nombre": "Guardia de la puerta", "corto": "la guardia",
		"rutina": "trabajo", "puntos": [Vector2(42.1, 50.3)], "mira": Vector2(41.0, 46.0), "franjas": TODAS,
		"frases": ["Puerta del Sur. De noche no sale nadie.", "Si ves niebla en el camino, avisa.",
			"Faroles encendidos, ojos abiertos."]},
	{"id": "guardia_ronda", "oficio": "guardia", "nombre": "Guardia de ronda", "corto": "el guardia",
		"rutina": "ruta", "ida_vuelta": true, "pausa": 5.0, "hace": "tarea", "franjas": TODAS,
		"puntos": [Vector2(40.55, 47.0), Vector2(40.55, 38.0), Vector2(40.6, 31.6), Vector2(46.4, 29.2),
			Vector2(46.4, 22.6), Vector2(41.5, 21.8)],
		"frases": ["Calle Mayor, plaza y vuelta. Toda la tarde.", "Esa campana se oye hasta en los Pastos.",
			"Todo en orden. De momento."]},
	{"id": "herrero_aprendiz", "oficio": "herrero", "nombre": "Aprendiz de la forja", "corto": "el aprendiz",
		"rutina": "trabajo", "puntos": [Vector2(43.1, 34.85)], "mira": Vector2(43.1, 33.6), "franjas": ["manana", "tarde"],
		"frases": ["Maese Ferro dice que aún golpeo torcido.", "Fuelle, carbón y paciencia. Eso dice él."]},
	{"id": "mercader_manzanas", "oficio": "mercader", "nombre": "Frutero", "corto": "el frutero",
		"rutina": "trabajo", "puntos": [Vector2(50.6, 28.9)], "mira": Vector2(50.6, 31.0), "franjas": ["manana", "tarde"],
		"frases": ["¡Manzanas de los Pastos! ¡Dulces de verdad!", "Hoy se fía. Mañana, ya veremos."], "saluda": true},
	{"id": "vendedora_fruta", "oficio": "campesina", "nombre": "Vendedora de ciruelas", "corto": "la vendedora",
		"rutina": "ruta", "ida_vuelta": false, "pausa": 9.0, "hace": "tarea", "franjas": ["manana", "tarde"],
		"puntos": [Vector2(40.4, 53.0), Vector2(40.6, 45.5), Vector2(40.6, 31.0), Vector2(46.4, 29.2),
			Vector2(57.6, 28.9), Vector2(46.4, 29.5), Vector2(40.4, 30.8), Vector2(40.4, 45.5)],
		"frases": ["Vengo de los Pastos con la cesta llena.", "Ciruelas buenas, al mercado. Feas, a casa."],
		"saluda": true},
	{"id": "alquimista_aprendiz", "oficio": "alquimista", "nombre": "Aprendiz de la botica", "corto": "la aprendiz",
		"rutina": "trabajo", "puntos": [Vector2(34.3, 41.3)], "mira": Vector2(35.5, 43.5), "franjas": ["manana", "tarde"],
		"frases": ["No toques ese frasco. Ni ese. Ni ese.", "Remover sin prisa, dice la maestra. Remuevo."]},
	{"id": "campesino_huerto", "oficio": "campesino", "nombre": "Hortelano", "corto": "el hortelano",
		"rutina": "trabajo", "puntos": [Vector2(51.4, 37.85)], "mira": Vector2(51.4, 39.6), "franjas": ["manana", "tarde"],
		"frases": ["Este huerto da coles como cabezas.", "Buena tierra la de aquí. Pide manos."]},
	{"id": "abuela_palomas", "oficio": "anciana", "nombre": "Abuela de las palomas", "corto": "la abuela",
		"rutina": "trabajo", "puntos": [Vector2(36.6, 23.0)], "mira": Vector2(38.0, 24.4), "franjas": ["manana", "tarde"],
		"frases": ["Las palomas vienen a mi hora. Puntuales.", "Antes había menos prisa en esta plaza."]},
	{"id": "abuelo_fuente", "oficio": "anciano", "nombre": "Abuelo paseante", "corto": "el abuelo",
		"rutina": "ruta", "ida_vuelta": true, "pausa": 7.0, "hace": "tarea", "velocidad": 0.55,
		"franjas": ["tarde", "anochecer"],
		"puntos": [Vector2(41.6, 30.2), Vector2(43.0, 22.0), Vector2(40.1, 21.0), Vector2(40.1, 15.0)],
		"frases": ["Tres vueltas a la plaza cada tarde.", "El Árbol ya era viejo cuando yo era niño."]},
	{"id": "nino_plaza", "oficio": "nino", "nombre": "Niño", "corto": "el niño", "rutina": "corro", "fase": 0.0,
		"franjas": ["manana", "tarde"], "frases": ["¡Te pillé! ¡La llevas!", "¡De mayor seré guardia!"], "saluda": true},
	{"id": "nina_plaza", "oficio": "nina", "nombre": "Niña", "corto": "la niña", "rutina": "corro", "fase": 2.1,
		"franjas": ["manana", "tarde"], "frases": ["¡Por dentro de la fuente no vale!", "¿Juegas? ¡La llevas tú!"]},
	{"id": "nina_lazo", "oficio": "nina", "nombre": "Niña del lazo", "corto": "la niña", "rutina": "corro", "fase": 4.2,
		"franjas": ["manana", "tarde"], "frases": ["¡Me sé todas las calles de memoria!", "¡Shh! Me escondo de mi hermano."],
		"saluda": true},
	{"id": "viajero_camino", "oficio": "viajero", "nombre": "Viajero", "corto": "el viajero",
		"rutina": "ruta", "ida_vuelta": true, "pausa": 12.0, "hace": "tarea", "franjas": ["tarde", "anochecer"],
		"puntos": [Vector2(39.6, 52.6), Vector2(39.6, 45.0), Vector2(39.5, 31.8), Vector2(36.0, 26.0),
			Vector2(25.0, 26.0), Vector2(17.4, 26.4)],
		"frases": ["La Taberna del Cuervo, ¿queda por aquí?", "Una cama, una sopa y mañana, camino."]},
	{"id": "barrendera", "oficio": "barrendero", "nombre": "Barrendera", "corto": "la barrendera",
		"rutina": "barrer", "puntos": [Vector2(47.0, 26.0), Vector2(62.0, 26.0)], "franjas": ["manana", "tarde"],
		"frases": ["Hojas del Árbol. No se acaban nunca.", "Barro la calle y llueve. Siempre igual."]},
]
# El corro de los niños: alrededor de la fuente de la plaza (ciudades/oakhaven.gd, PLAZA).
const CORRO_CENTRO := Vector2(40.0, 26.0)
const CORRO_RADIO := 3.0
const CORRO_VELOCIDAD := 1.15          # m/s
# Los vecinos con nombre que cambian de figura (vida3d.gd): id → [oficio, persona]. Ferro y Mirta (el distrito) y la
# posadera (dentro de la posada) no cambian: tienen piezas propias (el brazo del martillo de Ferro) que no son de aquí.
const VECINOS := {"aldric": ["guardia", "aldric"], "rosa": ["campesina", "rosa"], "albar": ["anciano", "albar"],
	"bastian": ["nino", "bastian"], "encina": ["anciana", "encina"]}

var region: Node3D
var gente: Array = []              # [{datos, nodo, estado…}]
var franja := "tarde"
var _t_franja := 0.0
var _frames := 0
var dichas := {}                   # id → índice de la siguiente frase
var hablando := ""                 # id del que habla con Kael ahora («» si nadie)
var _t_hablar := 0.0
var palomas: MultiMeshInstance3D   # zonas3d/oakhaven/palomas.gd (con la abuela)
var _abuela = null
var us_proceso := 0.0              # lo que cuesta cada fotograma la rutina y la animación (µs, media móvil)
var ms_montar := 0.0              # lo que tarda en crear a todos (medida)
var cuenta := {"cerca": 0, "media": 0, "quietos": 0, "ocultos": 0}   # el último reparto (para las pruebas y la medida)


static func activado() -> bool:
	if Engine.has_meta("mundo_vivo_v12"):
		return bool(Engine.get_meta("mundo_vivo_v12"))
	if "mundo_vivo_v12" in OS.get_cmdline_user_args():
		return true
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return ACTIVO_POR_DEFECTO
	return bool(c.get_value("mundo", "vivo_v12", ACTIVO_POR_DEFECTO))


# Ajustes (para el móvil): lo guarda y lo pone ya en Engine (vale desde la próxima entrada en Oakhaven).
static func elegir_en_ajustes(si: bool) -> Error:
	Engine.set_meta("mundo_vivo_v12", si)
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("mundo", "vivo_v12", si)
	return c.save("user://ajustes.cfg")


# Ajustes (menus.gd, una línea, junto a «Protagonistas»): «Oakhaven: de siempre / mundo vivo (prueba)».
static func opcion_ajustes(m: Object, cuerpo: Control) -> void:
	var si_ahora := activado()
	cuerpo.add_child(m._texto("Oakhaven", 26, m.COLOR_TITULO))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	for op in [[false, "De siempre"], [true, "Mundo vivo (prueba)"]]:
		var si: bool = op[0]
		var b: Button = m._boton(("● " if si == si_ahora else "○ ") + op[1], 18, Vector2(300, 34),
			"mundo_vivo:%s" % ("si" if si else "no"))
		b.pressed.connect(func():
			elegir_en_ajustes(si)
			var son = m.get_node_or_null("/root/Sonido")
			if son != null:
				son.efecto("ui_tic")
			m._pintar_de_nuevo())
		fila.add_child(b)
	cuerpo.add_child(fila)
	cuerpo.add_child(m._texto("Vecinos con oficio y rutinas. Se nota al entrar en Oakhaven.", 16, m.COLOR_SUAVE))


# Para vida3d.gd: la figura de la familia de un vecino con nombre, o null (interruptor apagado, sin modelo, o excluido).
static func figura_vecino(id: String) -> Node3D:
	if not activado() or Engine.has_meta("mundo_vivo_sin_vecinos") or not VECINOS.has(id):
		return null
	var v: Array = VECINOS[id]
	if not NPC.existe(v[0]):
		return null
	var n: Node3D = NPC.crear(v[0], v[1])
	if not n.listo:
		n.free()
		return null
	return n


static func crear(region_: Node3D) -> Node3D:
	var v: Node3D = load("res://zonas3d/oakhaven/mundo_vivo.gd").new()
	v.name = "MundoVivo"
	v.region = region_
	region_.add_child(v)
	v._montar()
	return v


func _montar() -> void:
	var t0 := Time.get_ticks_usec()
	franja = str(region.get("franja")) if region != null and region.get("franja") != null else "tarde"
	for d in PERSONAS:
		if not NPC.existe(d["oficio"]):
			continue
		var n: Node3D = NPC.crear(d["oficio"], d["id"])
		if not n.listo:
			n.free()
			continue
		add_child(n)
		var g := {"d": d, "nodo": n, "i": 0, "sentido": 1, "pausa": 0.0, "t": 0.0, "angulo": float(d.get("fase", 0.0)),
			"juego": randf_range(8.0, 14.0), "saludo": 0.0, "visto": true, "logica": 0.0, "anim": 0.0,
			"accion_t": randf_range(10.0, 18.0), "estado": ""}
		gente.append(g)
		_colocar_inicio(g)
		_presencia(g, true)
	# los vecinos con nombre que lleven figura de la familia (vida3d.gd) también se animan desde aquí
	_registrar_vecinos()
	# las palomas de la abuela (una llamada de dibujo): están cuando está ella
	for g in gente:
		if g["d"]["id"] == "abuela_palomas":
			palomas = Palomas.crear(PALOMAS, alto_en(PALOMAS))
			add_child(palomas)
			_abuela = g
	ms_montar = (Time.get_ticks_usec() - t0) / 1000.0


func _registrar_vecinos() -> void:
	var vida = region.get("vida") if region != null else null
	if vida == null:
		return
	for id in vida.vecinos:
		var fig = vida.vecinos[id].get("chibi")
		if fig != null:
			gente.append({"d": {"id": id, "rutina": "vecino"}, "nodo": fig, "vecino": vida.vecinos[id]["nodo"],
				"visto": true, "logica": 0.0, "anim": 0.0, "saludo": 0.0})


static func alto_en(p: Vector2) -> float:
	return Barrios.altura(p.x, p.y)


func _a3(p: Vector2) -> Vector3:
	return Vector3(p.x, alto_en(p), p.y)


func _colocar_inicio(g: Dictionary) -> void:
	var d: Dictionary = g["d"]
	var n: Node3D = g["nodo"]
	match d["rutina"]:
		"corro":
			n.position = _a3(CORRO_CENTRO + Vector2(cos(g["angulo"]), sin(g["angulo"])) * CORRO_RADIO)
		"ruta", "barrer":
			var pts: Array = d["puntos"]
			g["i"] = randi() % pts.size() if d["rutina"] == "ruta" else 0
			n.position = _a3(pts[g["i"]])
			g["i"] = (g["i"] + 1) % pts.size()
		_:
			n.position = _a3(d["puntos"][0])
			if d.has("mira"):
				_mirar(n, _a3(d["mira"]), 1.0)
			n.clip("tarea")


# ================================================================== cada fotograma

func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_proceso(delta)
	us_proceso = lerpf(us_proceso, float(Time.get_ticks_usec() - t0), 0.05)


func _proceso(delta: float) -> void:
	_frames += 1
	var kael: Node3D = region.get("kael") if region != null else null
	if kael == null:
		return
	var kp := kael.global_position
	var cam := get_viewport().get_camera_3d()
	_t_franja -= delta
	if _t_franja <= 0.0:
		_t_franja = 1.0
		var f = region.get("franja")
		if f != null:
			franja = str(f)
	if _t_hablar > 0.0:
		_t_hablar -= delta
		if _t_hablar <= 0.0:
			hablando = ""
	var c := {"cerca": 0, "media": 0, "quietos": 0, "ocultos": 0}
	# los MAX_CERCA más cercanos que se ven (y a menos de CERCA) se animan cada fotograma; los demás, a ANIM_MEDIA Hz
	var cercanos: Array = []
	for g in gente:
		var q: Vector3 = (g["nodo"] as Node3D).global_position
		g["_dist"] = Vector2(q.x - kp.x, q.z - kp.z).length()
		g["_cerca"] = false
		if g["_dist"] < CERCA and g.get("presente", true):
			cercanos.append(g)
	if cercanos.size() > MAX_CERCA:
		cercanos.sort_custom(func(a, b): return a["_dist"] < b["_dist"])
		cercanos.resize(MAX_CERCA)
	for g in cercanos:
		g["_cerca"] = true
	for g in gente:
		var n: Node3D = g["nodo"]
		var vecino: bool = g["d"]["rutina"] == "vecino"
		if not vecino and _t_franja == 1.0:
			_presencia(g, false, kp)
		if not vecino and not g.get("presente", true):
			c["ocultos"] += 1
			continue
		var p := n.global_position
		var dist: float = g["_dist"]
		var en_vista := dist < OCULTO and (cam == null or cam.is_position_in_frustum(p + Vector3(0, 0.8, 0)))
		n.visible = dist < OCULTO                         # (los vecinos con nombre, solo su figura)
		# la rutina: cada fotograma en la vista y cerca; si no, a LOGICA_LEJOS Hz (con el tiempo acumulado)
		g["logica"] += delta
		if not vecino and (en_vista and dist < LEJOS or g["logica"] >= 1.0 / LOGICA_LEJOS):
			_pensar(g, g["logica"], kp)
			g["logica"] = 0.0
		# la animación: cada fotograma de cerca; a ANIM_MEDIA Hz a media distancia; nada fuera de la vista o lejos
		g["anim"] += delta
		if en_vista and g["_cerca"]:
			n.avanzar(g["anim"])
			g["anim"] = 0.0
			c["cerca"] += 1
		elif en_vista and dist < LEJOS:
			if g["anim"] >= 1.0 / ANIM_MEDIA:
				n.avanzar(g["anim"])
				g["anim"] = 0.0
			c["media"] += 1
		else:
			g["anim"] = minf(g["anim"], 2.0)
			c["quietos"] += 1 if n.visible else 0
			c["ocultos"] += 0 if n.visible else 1
		# un saludo al ver a Kael de cerca (los que saludan; los vecinos con nombre, también)
		g["saludo"] = maxf(0.0, g["saludo"] - delta)
		if en_vista and dist < RADIO_SALUDO and dist > 1.4 and g["saludo"] <= 0.0 and hablando != g["d"]["id"] \
				and (vecino or g["d"].get("saluda", false)) and n.actual in ["reposo", "tarea"]:
			g["saludo"] = PAUSA_SALUDO
			_mirar(n, kp, 0.35)
			n.clip("saludar", n.actual)
	cuenta = c
	# las palomas: con la abuela; se mueven solo si se ven y Kael está cerca
	if palomas != null and _abuela != null:
		var hay: bool = _abuela.get("presente", true)
		if not hay:
			palomas.visible = false
		else:
			if palomas.fuera <= 0.0 and palomas.volando <= 0.0:
				palomas.visible = true
			var pp := palomas.global_position
			var dp := Vector2(pp.x - kp.x, pp.z - kp.z).length()
			if dp < CERCA and (cam == null or cam.is_position_in_frustum(pp)) or palomas.volando > 0.0 or palomas.fuera > 0.0:
				palomas.animar(delta, kp)


# Sale o se va según la franja; el cambio, solo con la persona lejos de Kael (que no aparezca nadie de golpe).
func _presencia(g: Dictionary, forzar: bool, kp := Vector3.ZERO) -> void:
	var quiere: bool = franja in g["d"].get("franjas", TODAS)
	if quiere == g.get("presente", not quiere) and not forzar:
		return
	var n: Node3D = g["nodo"]
	if not forzar and Vector2(n.global_position.x - kp.x, n.global_position.z - kp.z).length() < 18.0:
		return
	g["presente"] = quiere
	n.visible = quiere
	if quiere and not forzar:
		_colocar_inicio(g)


func _pensar(g: Dictionary, dt: float, kp: Vector3) -> void:
	var d: Dictionary = g["d"]
	var n: Node3D = g["nodo"]
	if hablando == d["id"]:
		return
	match d["rutina"]:
		"trabajo":
			# su tarea; de vez en cuando un rato en reposo (no todos los martillazos seguidos)
			g["accion_t"] -= dt
			if g["accion_t"] <= 0.0:
				var descansa: bool = n.actual == "tarea"
				n.clip("reposo" if descansa else "tarea")
				g["accion_t"] = randf_range(3.0, 5.0) if descansa else randf_range(10.0, 18.0)
		"ruta":
			if g["pausa"] > 0.0:
				g["pausa"] -= dt
				if g["pausa"] <= 0.0:
					n.clip("reposo")
				return
			var pts: Array = d["puntos"]
			var meta: Vector2 = pts[g["i"]]
			if _andar_hacia(n, meta, float(d.get("velocidad", n.velocidad_natural())), dt, kp):
				n.clip(d.get("hace", "reposo"))
				g["pausa"] = float(d.get("pausa", 3.0)) * randf_range(0.7, 1.3)
				_siguiente(g, pts.size(), d.get("ida_vuelta", false))
		"barrer":
			var pts: Array = d["puntos"]
			if _andar_hacia(n, pts[g["i"]], 0.22, dt, kp, "tarea"):
				_siguiente(g, pts.size(), true)
		"corro":
			_corro(g, dt, kp)


func _siguiente(g: Dictionary, total: int, ida_vuelta: bool) -> void:
	if not ida_vuelta:
		g["i"] = (g["i"] + 1) % total
		return
	var i: int = g["i"] + g["sentido"]
	if i < 0 or i >= total:
		g["sentido"] = -g["sentido"]
		i = g["i"] + g["sentido"]
	g["i"] = i


# Un paso hacia «meta». true si ya ha llegado. Se para (y espera en reposo) si Kael está delante a menos de DIST_PARAR.
func _andar_hacia(n: Node3D, meta: Vector2, vel: float, dt: float, kp: Vector3, clip_andar := "") -> bool:
	var p := Vector2(n.position.x, n.position.z)
	var falta := meta - p
	var largo := falta.length()
	if largo < 0.06:
		return true
	var dir := falta / largo
	var paso := minf(largo, vel * dt)
	var sig := p + dir * paso
	if sig.distance_to(Vector2(kp.x, kp.z)) < DIST_PARAR:
		n.clip("reposo")
		return false
	n.position = Vector3(sig.x, alto_en(sig), sig.y)
	_girar(n, atan2(dir.x, dir.y), dt)
	if clip_andar != "":
		n.clip(clip_andar)
	else:
		n.andar(vel)
	return paso >= largo


func _corro(g: Dictionary, dt: float, kp: Vector3) -> void:
	var n: Node3D = g["nodo"]
	g["juego"] -= dt
	if g["juego"] <= 0.0:                       # a ratos se paran a saltar (todos a la vez: es el mismo juego)
		if g["estado"] == "juega":
			g["estado"] = ""
			g["juego"] = randf_range(9.0, 14.0)
		else:
			g["estado"] = "juega"
			g["juego"] = randf_range(3.0, 4.5)
			n.clip("tarea")
	if g["estado"] == "juega":
		return
	var a: float = g["angulo"] + CORRO_VELOCIDAD / CORRO_RADIO * dt
	var sig := CORRO_CENTRO + Vector2(cos(a), sin(a)) * CORRO_RADIO
	if sig.distance_to(Vector2(kp.x, kp.z)) < DIST_PARAR:
		n.clip("reposo")
		return
	g["angulo"] = fmod(a, TAU)
	var antes := Vector2(n.position.x, n.position.z)
	n.position = Vector3(sig.x, alto_en(sig), sig.y)
	var dir := sig - antes
	if dir.length() > 0.0001:
		_girar(n, atan2(dir.x, dir.y), dt)
	n.andar(CORRO_VELOCIDAD)


func _girar(n: Node3D, meta: float, dt: float) -> void:
	n.rotation.y = n.rotation.y + wrapf(meta - n.rotation.y, -PI, PI) * minf(1.0, 8.0 * dt)


func _mirar(n: Node3D, punto: Vector3, k: float) -> void:
	var d := punto - n.global_position
	if Vector2(d.x, d.z).length() < 0.05:
		return
	var meta := atan2(d.x, d.z)
	n.rotation.y = n.rotation.y + wrapf(meta - n.rotation.y, -PI, PI) * clampf(k, 0.0, 1.0)


# ================================================================== lo que pide la región (oakhaven_3d.gd)

# Los que se pueden hablar ahora: [id, posición, radio, texto del botón] (como vida3d.gd).
func piezas() -> Array:
	var r: Array = []
	for g in gente:
		if g["d"]["rutina"] == "vecino" or not g.get("presente", true) or not (g["nodo"] as Node3D).visible:
			continue
		var d: Dictionary = g["d"]
		r.append(["vivo:" + d["id"], (g["nodo"] as Node3D).global_position, RADIO_HABLAR, "Hablar con " + d["corto"]])
	return r


func atiende(id: String) -> bool:
	return id.begins_with("vivo:")


# Hablar: se para, mira a Kael, hace su gesto y dice su frase siguiente (una línea, sin abrir un diálogo).
func accion(id: String) -> void:
	var pid := id.trim_prefix("vivo:")
	for g in gente:
		if g["d"]["id"] != pid:
			continue
		var d: Dictionary = g["d"]
		var n: Node3D = g["nodo"]
		var kael: Node3D = region.get("kael")
		if kael != null:
			_mirar(n, kael.global_position, 1.0)
		var vuelta: String = "tarea" if d["rutina"] in ["trabajo", "barrer"] else "reposo"
		n.clip("hablar", vuelta)
		var i: int = dichas.get(pid, 0)
		var frases: Array = d["frases"]
		var texto: String = frases[i % frases.size()]
		dichas[pid] = i + 1
		hablando = pid
		_t_hablar = 3.2
		if region.has_method("_mostrar_aviso"):
			region._mostrar_aviso("%s: «%s»" % [d["nombre"], texto], 3.2 + texto.length() * 0.03)
		return


# Kael no atraviesa a nadie (oakhaven_3d.gd, _prohibido).
func ocupa(p: Vector3) -> bool:
	for g in gente:
		if g["d"]["rutina"] == "vecino" or not g.get("presente", true):
			continue
		var q: Vector3 = (g["nodo"] as Node3D).global_position
		if absf(p.x - q.x) < RADIO_OCUPA and absf(p.z - q.z) < RADIO_OCUPA and absf(p.y - q.y) < 1.5 \
				and Vector2(p.x - q.x, p.z - q.z).length() < RADIO_OCUPA:
			return true
	return false
