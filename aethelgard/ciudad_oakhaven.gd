extends "res://zona.gd"
# Oakhaven, «la ciudadela de los faroles» (T-089, fase 2): la ciudad hecha a mano. Se entra desde el mapa (lugar 0).
# Los datos (trazado, vecinos, misiones, cofres, piezas, notas y secretos) están en ciudades/oakhaven.gd; esta escena los
# pone en el mundo con las casillas de zona.gd, como hace la Garganta (garganta.gd).
#
# Qué se juega: hablar con los ocho vecinos (sus diálogos se turnan, y lo de una misión en curso va primero); las
# misiones de la posadera, de Bastián y de Pip, y la de Rosa (la lavanda, solo con la exploración 3D); la posada, con su
# noche gratis y la escena del grupo al despertar; cuatro cofres con id escrito; las piezas (el barril, la torre y su
# ronda, los tres faroles y la grieta); cinco notas que van al Diario; los dos detalles de canon, en su sitio nuevo; y dos
# vistas (de momento, un aviso: las viñetas pintadas están pedidas).
#
# EL ARTE (gráficos): si existe ciudades/oakhaven_piezas.gd con
#     static func crear_pieza(id: String, rect_casillas: Rect2i, tam_casilla: int) -> Node2D
# se le pide un dibujo para cada lugar de LUGARES, cada pieza, cada nota con casilla, cada detalle de canon, cada casa
# del relleno («casa_<ancho>x<alto>», p. ej. «casa_4x4») y cada farola de las calles («farol»). Si no existe, o si
# devuelve null, se dibuja la versión provisional de aquí. Contrato:
#   - rect_casillas: el rectángulo del lugar o de la casa; para lo que es un punto (piezas, notas, detalles y farolas),
#     la casilla que lo contiene (1 × 1). tam_casilla: 64.
#   - El nodo se añade a «mundo_y» (ordenado por la y de su posición: conviene que su origen sea el pie del dibujo). Si
#     viene en (0, 0), se pone en la esquina de arriba a la izquierda del rectángulo; si trae otra posición, se respeta.
#   - Bajo el dibujo de un edificio o de una casa, sus casillas son un muro invisible (3, zona.gd): choca igual, pero
#     no se dibuja.
#   - Hablar, examinar y usar se miden desde las casillas de ciudades/oakhaven.gd, no desde el dibujo.
#   - Si el dibujo de un lugar ya incluye una pieza, nota o detalle (el letrero del cuervo en la taberna, los faroles
#     en la ronda, el sello en el crematorio…), crear_pieza de ese id debe devolver un Node2D vacío: así no se pinta
#     la provisional encima.
#   - Estados: a los dibujos de los lugares que tengan poner_estado(nombre, si) (pieza.gd de gráficos) se les pide
#     «farol_1», «farol_2» y «farol_3» (los faroles de la ronda encendidos) y, por cada cofre, su id (true mientras
#     está cerrado). Si alguno tiene tiene_estado(<id del cofre>), la ciudad no pone su destello provisional. A una
#     pieza con encender(si: bool) (un farol de la ronda) se le llama al cargar y al encenderlo.
#   - Si el módulo trae la constante AMBIENTE (Color), la ciudad la usa para su luz ambiente (el arte va horneado a la
#     hora azul), y sin hierba alta. Con LUZ_JUGADOR ({"energia", "escala"}), la luz de Kael es un farol de mano.
#   - Con RELLENO (las casas, farolas y tendederos que gráficos dibujó para no tapar ninguna calle con su tejado), las
#     casas y farolas son esas, no las que se reparten al azar; el resto es jardín (setos y flores; los árboles, en los
#     huecos de JARDINES si el módulo o la maqueta los traen).
#   - Con muneco_de(id, imagen), los vecinos que tienen muñeco propio lo llevan, sin «tinte».
#   - Lo que ya pinta el dibujo de un lugar (PINTADO_EN: el barril, el letrero, los faroles de la ronda, el sello…) no
#     lleva provisional: un punto vacío para usarlo. Los faroles de la ronda se emparejan con los del dibujo por su
#     sitio (de norte a sur), no por el número, y el destello del cofre de las raíces es el estado
#     «cofre_raices_abierto» del Árbol.
# Las pruebas pueden poner otro módulo con Engine «oakhaven_arte_prueba» (su ruta: prueba_oakhaven usa uno falso).
#
# Estado: solo claves que ya existen en la partida (ver ciudades/oakhaven.gd). Nada se guarda en Engine que sea un recurso:
# los personajes nuevos de Dialogic se dan a conocer por su ruta (Oak.registrar_dialogic()).

const Oak := preload("res://ciudades/oakhaven.gd")
const Progreso := preload("res://progreso.gd")
const PIEZAS_ARTE := "res://ciudades/oakhaven_piezas.gd"     # de gráficos (aún puede no existir)
const RADIO_PIEZA := 90.0                 # como los detalles (RADIO_DETALLE)
const VERSION_OAK := 1                    # súbelo si cambian los dibujos provisionales (caché de user://)
const LIBRE := 255                        # casilla de relleno aún sin decidir (al generar)
const JARDIN := 254                       # hueco de jardín entre casas (al generar)
const SIN_EMPEDRAR := ["colina", "jardin_urnas", "raices"]   # pisables con hierba
const DE_PIEDRA := ["torre", "crematorio"]                    # edificios de piedra; los demás, tejado
const SEPARACION_FAROLAS := 6.0           # casillas entre farolas en las calles
const IMAGEN_ARBOL := "res://decorado/arce.png"
const ESCALA_ARBOL := 1.4                 # el Árbol Milenario, provisional: un árbol enorme con las raíces a la vista
const DIBUJO_NOTA := {"nota_oak_bando": "oak_tablon", "nota_oak_cuervo": "oak_letrero", "nota_oak_anillos": "tronco",
	"nota_oak_guardia": "oak_atril", "nota_oak_velas": "oak_velas"}
# Dibujos provisionales (los de zona.gd siguen igual): tamaño, pie, sombra, choque y luz.
const OBJETOS_OAK := {
	"oak_barril": {"tam": Vector2i(56, 64), "origen": Vector2(28, 60), "sombra": 52.0, "choque": 14.0},
	"oak_tablon": {"tam": Vector2i(96, 112), "origen": Vector2(48, 106), "sombra": 84.0, "choque": 12.0},
	"oak_letrero": {"tam": Vector2i(80, 120), "origen": Vector2(21, 114), "sombra": 24.0, "choque": 6.0},
	"oak_atril": {"tam": Vector2i(64, 84), "origen": Vector2(32, 80), "sombra": 40.0, "choque": 10.0},
	"oak_velas": {"tam": Vector2i(80, 72), "origen": Vector2(40, 66), "sombra": 60.0, "choque": 18.0,
		"luz": Color(1.0, 0.72, 0.36), "luz_pos": Vector2(0, -44), "energia": 0.9, "fuego": true},
	"oak_grieta": {"tam": Vector2i(64, 96), "origen": Vector2(32, 92), "sombra": 0.0, "choque": 0.0},
	"oak_escalera": {"tam": Vector2i(64, 48), "origen": Vector2(32, 40), "sombra": 0.0, "choque": 0.0},
	"oak_puerta": {"tam": Vector2i(56, 88), "origen": Vector2(28, 84), "sombra": 0.0, "choque": 0.0},
}
# Piezas, notas y detalles que ya vienen pintados en el dibujo de un lugar: [lugar, ancla del dibujo que lo confirma].
const PINTADO_EN := {
	"oak_barril": ["patio_cuervo", "barril"], "oak_torre": ["torre", "puerta"], "oak_ronda_bajar": ["ronda", "subida"],
	"oak_grieta": ["grieta", "grieta"], "oak_farol_1": ["ronda", "farol_1"], "oak_farol_2": ["ronda", "farol_2"],
	"oak_farol_3": ["ronda", "farol_3"], "nota_oak_bando": ["plaza", "tablon"], "nota_oak_cuervo": ["taberna", "letrero"],
	"nota_oak_anillos": ["arbol", "anillos"], "nota_oak_guardia": ["guardia", "libro"],
	"nota_oak_velas": ["patio_velas", "velas"], "oak_sello": ["crematorio", "sello"], "oak_tapiz": ["concejo", "tapiz"],
}
const MAQUETA_ARTE := "res://ciudades/oakhaven_arte/maqueta_oakhaven.gd"   # JARDINES, si el módulo no los trae
const Vida := preload("res://ciudades/oakhaven_vida.gd")        # lo que dicen vecinos y gente al pasar (narrativa)
const Posada := preload("res://ciudades/oakhaven_posada.gd")    # los servicios de la posadera (también para el 3D)
const EstiloUI := preload("res://estilo.gd")
const QUIETO_COMENTARIO := 14.0          # s sin moverse (ni diálogo, ni menú) para que alguien diga algo
const PAUSA_COMENTARIOS := 45.0           # s entre dos comentarios por estar quietos
const ARBOLES := ["cerezo", "q_arbol", "q_otono", "q_pino"]

var arte = null                           # ciudades/oakhaven_piezas.gd, si existe
var nodos_lugar := {}                     # id de LUGARES → dibujo de gráficos (antes de entrar en mundo_y)
var nodos_casas: Array = []               # dibujos de gráficos de las casas del relleno (antes de entrar en mundo_y)
var farolas: Array = []                   # dónde van las farolas de las calles (casillas)
var con_relleno := false                  # las casas y farolas son las del RELLENO de gráficos
var vecinos: Array = []                   # Oak.NPCS con el muñeco propio de cada uno, si lo hay (_npcs)
var quieto_t := 0.0                       # tiempo sin moverse
var franja := Vida.FRANJA_AL_LLEGAR       # la hora: mañana, tarde o anochecer (ciudades/oakhaven_vida.gd, FRANJAS)
var franja_t := 0.0                       # s en esta franja (pasa a la siguiente a los DURACION_FRANJA)
var paseos := {}                          # id del vecino → su Tween de paseo (rutina «pasea»)
var voz_pausa := 4.0                      # s hasta que alguien pueda decir algo al pasar (la primera, tras la llegada)
var voz_quien := {}                       # id → s hasta que esa persona pueda volver a hablar
var voz_dichos := {}                      # frases dichas en esta visita (texto → true)
var voz_globo: Node2D                     # la frase en pantalla, sobre quien la dice
var musica_nodo = null                    # el autoload Musica (musica.gd)
var musica_conoce := true                 # musica.gd ya sabe qué suena en esta escena
var piezas: Array = []                    # [nodo, datos de Oak.PIEZAS, punto en píxeles]
var notas: Array = []                     # [nodo, datos de Oak.NOTAS, punto en píxeles]
var pieza_cerca = null
var nota_cerca = null
var destellos := {}                       # id de cofre → destello que llama la atención mientras está cerrado
var jardines: Array = []                  # casillas de jardín (Vector2i), entre las casas
var puntos_clave: Array = []              # casillas de lo que se usa: ahí no se pone decorado
var arbol: Node2D                         # el dibujo del Árbol Milenario (el «altar» es su pie, para examinarlo)
var arbol_provisional := false
var avisos: Array = []                    # [texto, efecto] que esperan su turno (o a que acabe el diálogo)
var viajando := false                     # fundido de la torre o la grieta: Kael quieto
var brillo_grieta := false
var cambios := false                      # una señal de un diálogo cambió la partida: se guarda al acabar
var noche_invitada := false
var rumor_pendiente := ""                 # el rumor que la posadera cuenta al acabar el diálogo de sus servicios
var dormir_pendiente := false             # «Dormir» en «¿Qué va a ser?»: se descansa al acabar el diálogo
var servicio_pendiente := ""              # V10: forja, armaduras o botica, que se abre al acabar el diálogo de quien atiende
var servicio_abierto: Node = null          # V10: el servicio abierto ahora (servicios.gd), o null
var gremio_abierto: Node = null            # V11: el tablón del gremio abierto (gremio_menu.gd), o null
var obras: Dictionary = {}                 # V11: id de proyecto → los nodos que puso (no se ponen dos veces)


# V11, hito C: lo que han cambiado los proyectos de reconstrucción pagados (gremio.gd PROYECTOS). Hoy, los braseros de
# la plaza: dos braseros con fuego y luz junto al tablón. Al entrar y al pagarlo en el tablón.
func _poner_proyectos() -> void:
	var Gremio = load("res://gremio.gd")
	for p in Gremio.PROYECTOS:
		if obras.has(p["id"]) or not Gremio.proyecto_hecho(p["id"]):
			continue
		var nodos: Array = []
		if p["id"] == "pr_braseros":
			for c in p["casillas"]:
				nodos.append(_poner_objeto("brasero", c * T))
		obras[p["id"]] = nodos


# V11, hito C: el tablón del Gremio de aventureros (gremio.gd). Mientras está abierto, Kael no anda (como la tienda);
# al cerrarlo se guarda (lo aceptado o cobrado) y se pinta el oro.
func _abrir_gremio() -> void:
	if tienda_abierta:
		return
	tienda_abierta = true
	tiene_destino = false
	Sonido.efecto("examinar")
	var m = load("res://gremio_menu.gd").new()
	gremio_abierto = m
	m.proyecto_hecho.connect(func(_id): _poner_proyectos())
	m.cerrado.connect(func():
		tienda_abierta = false
		gremio_abierto = null
		_poner_oro()
		_guardar())
	add_child(m)
var velo_patio: Polygon2D                 # el Patio de las Velas, a oscuras hasta pasar la grieta
var r_ronda: Rect2                        # rectángulos de LUGARES que se miran en cada fotograma
var r_raices: Rect2
var r_patio: Rect2


# ================================================================= construcción

func _ready() -> void:
	var ruta: String = Engine.get_meta("oakhaven_arte_prueba", PIEZAS_ARTE)
	if ResourceLoader.exists(ruta):
		var s = load(ruta)
		if s is Script and _tiene_funcion(s, "crear_pieza"):
			arte = s
	Oak.registrar_dialogic()                       # los personajes nuevos, por su ruta, antes del primer diálogo
	super._ready()
	var D = get_node_or_null("/root/Dialogic")
	if D != null:
		D.signal_event.connect(_al_senal)
		D.timeline_ended.connect(_al_acabar_dialogo)
	musica_nodo = get_node_or_null("/root/Musica")
	musica_conoce = musica_nodo == null or load("res://musica.gd").contexto_de(self) == "ciudad"
	_actualizar_posada()
	# Sonido de la ciudad (sonido.gd, tanda 3): el bullicio en la puerta de la taberna y el letrero del cuervo, que suenan
	# por cercanía, y la campana lejana al llegar.
	var rt := _rect("taberna")
	Sonido.fuente_2d(self, "taberna", Vector2(rt.get_center().x, rt.end.y) * T, jugador)
	Sonido.fuente_2d(self, "cuervo", Vector2(rt.position.x + 2.0, rt.end.y + 0.5) * T, jugador)
	Sonido.efecto("campana", {"retraso": 1.5})
	# Oakhaven vivo (sonido, tanda 6: docs/audio/inventario_sonidos.md): el murmullo de la plaza, su fuente y el
	# mercado, por cercanía; y la hora: la tarde (la hora azul del arte) y, tras dormir en la posada, el día.
	var pz := _rect("plaza")
	Sonido.fuente_2d(self, "plaza_murmullo", pz.get_center() * T, jugador)
	Sonido.fuente_2d(self, "fuente_plaza", _sitio_fuente(), jugador)
	Sonido.fuente_2d(self, "mercado_murmullo", _rect("mercado").get_center() * T, jugador)
	# la hora de la sesión (o la tarde, al llegar): sus rutinas y su sonido (oakhaven_vida.gd, sonido.gd fijar_momento)
	franja_t = float(Engine.get_meta("oak_franja_t", 0.0))
	_poner_franja(str(Engine.get_meta("oak_franja", Vida.FRANJA_AL_LLEGAR)), false)


func _exit_tree() -> void:
	Engine.set_meta("oak_franja_t", franja_t)      # (la franja ya está en Engine: _poner_franja)
	var D = get_node_or_null("/root/Dialogic")
	if D == null:
		return
	if D.signal_event.is_connected(_al_senal):
		D.signal_event.disconnect(_al_senal)
	if D.timeline_ended.is_connected(_al_acabar_dialogo):
		D.timeline_ended.disconnect(_al_acabar_dialogo)


# La luz de Kael: con el arte a la hora azul, un farol de mano (la de zona.gd alumbra como de día).
func _crear_iluminacion() -> void:
	super._crear_iluminacion()
	var l = _constante_arte("LUZ_JUGADOR")
	if luz_jugador != null and l is Dictionary and l.has("energia") and l.has("escala"):
		luz_jugador.energy = float(l["energia"])
		luz_jugador.texture_scale = float(l["escala"])


func _constante_arte(nombre: String) -> Variant:
	return arte.get_script_constant_map().get(nombre) if arte != null else null


static func _tiene_funcion(s: Script, nombre: String) -> bool:
	for m in s.get_script_method_list():
		if m["name"] == nombre:
			return true
	return false


func _leer_lugar() -> void:
	super._leer_lugar()
	if int(lugar["indice"]) != Oak.INDICE:          # probando la escena suelta
		var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
		lugar = {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]}
	lugar = lugar.duplicate()
	lugar["texto"] = Oak.TEXTO_ARBOL               # lo que se lee al examinar el Árbol (el altar de zona.gd)
	nombre_estilo = "ciudad"
	estilo = ESTILOS["ciudad"]
	if arte != null and arte.get_script_constant_map().get("AMBIENTE") is Color:   # la hora azul del arte de gráficos
		estilo = estilo.duplicate()
		estilo["ambiente"] = arte.get_script_constant_map()["AMBIENTE"]
		estilo["hierba_alta"] = 0.0               # el arte pinta su suelo; la hierba alta lo taparía
	es_ciudad = true
	semilla = 1000 + Oak.INDICE * 7919


# El trazado de ciudades/oakhaven.gd: calles y patios (0), edificios (tejado 2, piedra 1, o invisible 3 bajo el arte),
# la muralla (1, con la Puerta del Sur abierta), casas en el resto con jardines entre ellas (3) y el decorado.
func _generar_disposicion() -> void:
	plaza = Oak.PLAZA
	meta = Oak.ARBOL
	salida_x = Oak.SALIDA_X
	ancho_camino = 1.5
	r_ronda = _rect("ronda")
	r_raices = _rect("raices")
	r_patio = _rect("patio_velas")
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	_preparar_puntos()
	muros.resize(ANCHO * ALTO)
	muros.fill(LIBRE)
	var empedrado := PackedByteArray()
	empedrado.resize(ANCHO * ALTO)
	for l in Oak.LUGARES:                          # calles, plazas y patios
		if l["pisable"]:
			for c in _casillas(l["rect"]):
				muros[c.y * ANCHO + c.x] = 0
				empedrado[c.y * ANCHO + c.x] = 0 if l["id"] in SIN_EMPEDRAR else 1
	for l in Oak.LUGARES:                          # el arte de gráficos de cada lugar, si lo hay
		var n := _arte(l["id"], Rect2i(l["rect"]))
		if n != null:
			nodos_lugar[l["id"]] = n
	for l in Oak.LUGARES:                          # edificios (el tronco del Árbol está dentro de las raíces)
		if not l["pisable"]:
			var v := 3 if nodos_lugar.has(l["id"]) or l["id"] == "arbol" else (1 if l["id"] in DE_PIEDRA else 2)
			for c in _casillas(l["rect"]):
				muros[c.y * ANCHO + c.x] = v
				empedrado[c.y * ANCHO + c.x] = 0
	# la muralla: el borde (la del este, doble: la ronda va por encima), el muro de dentro de la ronda y el del callejón,
	# que separa el Patio de las Velas; la grieta es una casilla de ese muro que solo se pasa de lado (pieza oak_grieta)
	var grieta := _rect("grieta")
	for y in ALTO:
		for x in ANCHO:
			if muros[y * ANCHO + x] != LIBRE:
				continue
			var borde := x == 0 or y == 0 or x >= ANCHO - 2 or y == ALTO - 1
			var dentro_ronda := x == int(r_ronda.position.x) - 1 and y >= r_ronda.position.y and y < r_ronda.end.y
			var callejon := y == int(grieta.position.y) and x >= r_patio.position.x and x < r_patio.end.x
			if borde or dentro_ronda or callejon:
				muros[y * ANCHO + x] = 1
	var gi := int(grieta.position.y) * ANCHO + int(grieta.position.x)
	muros[gi] = 1
	empedrado[gi] = 0
	_poner_casas(rng)
	var jardin := PackedByteArray()
	jardin.resize(ANCHO * ALTO)
	for c in jardines:
		jardin[c.y * ANCHO + c.x] = 1
	# empedrado en las esquinas de las casillas empedradas, salvo junto a un jardín: ahí acaba en hierba, para que el
	# jardín (que no se pisa) no parezca calle
	var vw := ANCHO + 1
	camino_v.resize(vw * (ALTO + 1))
	agua_v.resize(vw * (ALTO + 1))
	camino_v.fill(0)
	agua_v.fill(0)
	for vy in ALTO + 1:
		for vx in vw:
			var empedrar := false
			var junto_jardin := false
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				var x: int = vx + d.x
				var y: int = vy + d.y
				if x < 0 or y < 0 or x >= ANCHO or y >= ALTO:
					continue
				empedrar = empedrar or empedrado[y * ANCHO + x] == 1
				junto_jardin = junto_jardin or jardin[y * ANCHO + x] == 1
			camino_v[vy * vw + vx] = 1 if empedrar and not junto_jardin else 0
	_decorar(rng)


# Casas de 3 a 6 casillas de ancho y 3 o 4 de alto en el relleno, con un hueco de jardín a la derecha y debajo (así no
# se tocan); lo que queda es jardín: muro invisible con plantas.
func _poner_casas(rng: RandomNumberGenerator) -> void:
	var relleno = _constante_arte("RELLENO")
	con_relleno = relleno is Array and not relleno.is_empty()
	if con_relleno:
		_poner_relleno(relleno)
	for y in range(1, ALTO - 1):
		if con_relleno:
			break
		for x in range(1, ANCHO - 1):
			if muros[y * ANCHO + x] != LIBRE:
				continue
			var tam := Vector2i.ZERO
			var w0 := rng.randi_range(3, 6)
			var h0 := rng.randi_range(3, 4)
			for h in [h0, 3]:
				for w in range(w0, 2, -1):
					if _libre(x, y, w, h):
						tam = Vector2i(w, h)
						break
				if tam != Vector2i.ZERO:
					break
			if tam == Vector2i.ZERO:
				continue
			var casa := _arte("casa_%dx%d" % [tam.x, tam.y], Rect2i(x, y, tam.x, tam.y))   # la de gráficos, si la hay
			if casa != null:
				nodos_casas.append(casa)
			for yy in tam.y:
				for xx in tam.x:
					muros[(y + yy) * ANCHO + x + xx] = 3 if casa != null else 2
			for yy in tam.y + 1:
				_jardin(x + tam.x, y + yy)
			for xx in tam.x:
				_jardin(x + xx, y + tam.y)
	for y in ALTO:
		for x in ANCHO:
			if muros[y * ANCHO + x] in [LIBRE, JARDIN]:
				muros[y * ANCHO + x] = 3
				jardines.append(Vector2i(x, y))


# Las casas, farolas y tendederos del RELLENO de gráficos (dibujados para no tapar calles, plaza ni nada que se use).
# Una casa que pisara algo de la ciudad no se pone (avisa); las farolas y los tendederos no son muro.
func _poner_relleno(relleno: Array) -> void:
	for c in relleno:
		var r: Rect2i = c.get("rect", Rect2i())
		if c.get("suelto", false):
			if c.get("id", "") == "farol":
				farolas.append(Vector2(r.position) + Vector2(0.5, 0.5))
			else:
				var n := _arte(c["id"], r)
				if n != null:
					nodos_casas.append(n)
			continue
		if not _libre(r.position.x, r.position.y, r.size.x, r.size.y):
			push_warning("Oakhaven: la casa del relleno %s pisa algo de la ciudad; no se pone" % r)
			continue
		var casa := _arte(c["id"], r)
		if casa == null:
			continue
		nodos_casas.append(casa)
		for yy in r.size.y:
			for xx in r.size.x:
				muros[(r.position.y + yy) * ANCHO + r.position.x + xx] = 3


func _libre(x: int, y: int, w: int, h: int) -> bool:
	if x + w > ANCHO - 1 or y + h > ALTO - 1:
		return false
	for yy in h:
		for xx in w:
			if muros[(y + yy) * ANCHO + x + xx] != LIBRE:
				return false
	return true


func _jardin(x: int, y: int) -> void:
	if x >= 0 and y >= 0 and x < ANCHO and y < ALTO and muros[y * ANCHO + x] == LIBRE:
		muros[y * ANCHO + x] = JARDIN


# Plantas en los jardines: junto a las calles, sobre todo setos (así se ve que no se pisan); dentro, de todo, y los
# árboles solo ahí (no tapan a nadie). Flores en la hierba de las raíces y de la colina. Farolas en las calles, en las
# esquinas de la plaza, en la Puerta del Sur, en el soportal de la guardia y a la puerta del crematorio.
func _decorar(rng: RandomNumberGenerator) -> void:
	var pesos: Dictionary = estilo["objetos"].duplicate()
	pesos.erase("arce")                            # el arce, solo el Árbol Milenario (provisional): que sea único
	for c in jardines:
		var junto := _junto_a_calle(c)
		if rng.randf() >= (0.6 if junto else 0.3) or _cerca_de_algo(Vector2(c) + Vector2(0.5, 0.5), 2.2):
			continue
		var tipo := _al_azar(pesos, rng)
		if junto or (con_relleno and tipo in ARBOLES):   # con el arte, los árboles solo en los huecos de JARDINES
			tipo = ["q_arbusto_flor", "q_arbusto", "q_arbusto_flor", "q_flores"][rng.randi() % 4]
		colocados.append({"tipo": tipo, "pos": (Vector2(c) + Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.3, 0.9))) * T})
	if con_relleno:
		_arboles_de_jardin()
	for zona_hierba in [["raices", 12], ["colina", 10]]:
		var r := _rect(zona_hierba[0])
		var puestas := 0
		for intento in 200:
			if puestas >= zona_hierba[1]:
				break
			var p := Vector2(rng.randf_range(r.position.x + 0.5, r.end.x - 0.5), rng.randf_range(r.position.y + 0.5, r.end.y - 0.5))
			if not _pisable(p) or _cerca_de_algo(p, 1.8) or _rect("arbol").grow(1.5).has_point(p) \
					or _rect("crematorio").grow(1.0).has_point(p):
				continue
			colocados.append({"tipo": "q_flores" if puestas % 2 == 0 else "q_flores_amarillas", "pos": p * T})
			puestas += 1
	if con_relleno:
		return                                     # las farolas son las del RELLENO (_poner_relleno)
	var candidatas: Array = []
	for l in Oak.LUGARES:
		if not l["id"].begins_with("calle_"):
			continue
		var r: Rect2 = l["rect"]
		var vertical := r.size.y > r.size.x
		var largo: float = r.size.y if vertical else r.size.x
		var n := maxi(1, int(largo / SEPARACION_FAROLAS))
		for j in n:
			var t := (j + 0.5) * largo / n
			if vertical:
				candidatas.append(Vector2(r.position.x + 0.28 if j % 2 == 0 else r.end.x - 0.28, r.position.y + t))
			else:
				candidatas.append(Vector2(r.position.x + t, r.position.y + 0.3 if j % 2 == 0 else r.end.y - 0.2))
	var pz := _rect("plaza")
	candidatas.append_array([pz.position + Vector2(0.4, 0.5), Vector2(pz.end.x - 0.4, pz.position.y + 0.5),
		Vector2(pz.position.x + 0.4, pz.end.y - 0.4), pz.end - Vector2(0.4, 0.4)])
	var ps := _rect("puerta_sur")
	candidatas.append_array([Vector2(ps.position.x + 0.35, ps.end.y - 1.5), Vector2(ps.end.x - 0.35, ps.end.y - 1.5)])
	candidatas.append(Vector2(_rect("soportal_guardia").end.x - 0.3, _rect("soportal_guardia").position.y + 0.4))
	var puerta: Vector2 = _lugar("crematorio")["puerta"]
	candidatas.append_array([puerta + Vector2(-2.5, 0.7), puerta + Vector2(2.5, 0.7)])
	for p in candidatas:
		if _pisable(p) and not _cerca_de_algo(p, 1.6):
			farolas.append(p)                      # se ponen en _crear_objetos (las de gráficos o las de zona.gd)


# Árboles en los huecos que gráficos eligió para que no tapen fachadas ni calles (JARDINES: [tipo, x, y]), del módulo o,
# si no los trae, de su maqueta. Solo los que caen en un jardín de esta ciudad.
func _arboles_de_jardin() -> void:
	var lista = _constante_arte("JARDINES")
	if not lista is Array and ResourceLoader.exists(MAQUETA_ARTE):
		lista = load(MAQUETA_ARTE).get_script_constant_map().get("JARDINES")
	if not lista is Array:
		return
	var en_jardin := {}
	for c in jardines:
		en_jardin[c] = true
	for j in lista:
		var p := Vector2(float(j[1]), float(j[2]))
		if en_jardin.has(Vector2i(floori(p.x), floori(p.y))) and not _cerca_de_algo(p, 1.5):
			colocados.append({"tipo": j[0], "pos": p * T})


func _al_azar(pesos: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in pesos:
		total += pesos[k]
	var r := rng.randi_range(1, total)
	for k in pesos:
		r -= pesos[k]
		if r <= 0:
			return k
	return pesos.keys()[0]


func _junto_a_calle(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _pisable(Vector2(c.x + dx, c.y + dy) + Vector2(0.5, 0.5)):
				return true
	return false


# Casillas de lo que se usa (vecinos, cofres, piezas, notas, detalles, el pie del Árbol y la entrada).
func _preparar_puntos() -> void:
	puntos_clave.clear()
	for lista in [Oak.NPCS, Oak.COFRES, Oak.PIEZAS, Oak.NOTAS]:
		for d in lista:
			if d.has("casilla"):
				puntos_clave.append(d["casilla"])
	for id in Oak.SITIOS_DETALLE:
		puntos_clave.append(Oak.SITIOS_DETALLE[id])
	puntos_clave.append(Vector2(Oak.ARBOL.x, _rect("arbol").end.y))
	puntos_clave.append(Oak.INICIO)


func _cerca_de_algo(p: Vector2, r: float) -> bool:
	for q in puntos_clave:
		if p.distance_to(q) < r:
			return true
	return false


func _pisable(c: Vector2) -> bool:
	var x := floori(c.x)
	var y := floori(c.y)
	return x >= 0 and y >= 0 and x < ANCHO and y < ALTO and muros[y * ANCHO + x] == 0


static func _casillas(r: Rect2) -> Array:
	var lista: Array = []
	for y in range(int(r.position.y), int(ceil(r.end.y))):
		for x in range(int(r.position.x), int(ceil(r.end.x))):
			if x >= 0 and y >= 0 and x < ANCHO and y < ALTO:
				lista.append(Vector2i(x, y))
	return lista


static func _lugar(id: String) -> Dictionary:
	for l in Oak.LUGARES:
		if l["id"] == id:
			return l
	return {}


static func _rect(id: String) -> Rect2:
	return _lugar(id).get("rect", Rect2())


static func _secreto(id: String) -> Dictionary:
	for s in Oak.SECRETOS:
		if s["id"] == id:
			return s
	return {}


# ================================================================= objetos de la ciudad

func _crear_objetos() -> void:
	super._crear_objetos()                         # hierba, decorado, el Árbol, los vecinos y los detalles
	for id in nodos_lugar:                         # el arte de gráficos de cada lugar y de las casas
		mundo_y.add_child(nodos_lugar[id])
	for n in nodos_casas:
		mundo_y.add_child(n)
	for p in farolas:                              # las farolas de las calles: las de gráficos o las de zona.gd
		var f := _arte("farol", _rect_punto(p))
		if f != null:
			mundo_y.add_child(f)
		else:
			_poner_objeto("farola", p * T)
	_poner_cofres()
	_poner_piezas()
	_poner_proyectos()
	_poner_notas()
	_actualizar_piezas()
	# el Patio de las Velas es un rincón escondido: desde el callejón solo se ve la luz de la grieta, no lo de dentro
	var r := r_patio
	velo_patio = Polygon2D.new()
	velo_patio.polygon = PackedVector2Array([r.position * T, Vector2(r.end.x, r.position.y) * T, r.end * T,
		Vector2(r.position.x, r.end.y) * T])
	velo_patio.color = Color(0.02, 0.02, 0.05, 0.88)
	velo_patio.z_index = 25
	add_child(velo_patio)
	velo_patio.modulate.a = 0.0 if _patio_visible() else 1.0


func _patio_visible() -> bool:
	return Progreso.estado(Oak.NOMBRE, "grieta") or (jugador != null and r_patio.has_point(jugador.position / T))


# El dibujo de gráficos para «id» (ciudades/oakhaven_piezas.gd), o null si no hay. Ver el contrato arriba.
func _arte(id: String, rect: Rect2i) -> Node2D:
	if arte == null:
		return null
	var n = arte.crear_pieza(id, rect, T)
	if not n is Node2D:
		n = _hueco_si_pintado(id)
		if n == null:
			return null
	if n.position == Vector2.ZERO:
		n.position = Vector2(rect.position) * T
	return n


# Si el dibujo de su lugar ya pinta esta pieza, nota o detalle (PINTADO_EN), un punto vacío en lugar del provisional.
func _hueco_si_pintado(id: String) -> Node2D:
	if not PINTADO_EN.has(id):
		return null
	var dibujo = _dibujo_de_lugar(PINTADO_EN[id][0])
	var anclas = dibujo.get("anclas") if dibujo != null else null
	if not anclas is Dictionary or not anclas.has(PINTADO_EN[id][1]):
		return null
	var hueco := Node2D.new()
	hueco.name = "pintado_" + id
	return hueco


func _dibujo_de_lugar(id: String) -> Node2D:
	if nodos_lugar.has(id):
		return nodos_lugar[id]
	if id == "arbol" and arbol != null and not arbol_provisional:
		return arbol
	return null


# Dónde suena la fuente: la del dibujo de la plaza (su ancla está a la altura del caño: el pie, una casilla más abajo)
# o, sin arte, el centro de la plaza.
func _sitio_fuente() -> Vector2:
	var plaza_arte = nodos_lugar.get("plaza")
	if plaza_arte != null and plaza_arte.has_method("ancla") and plaza_arte.ancla("fuente") != Vector2.INF:
		return plaza_arte.ancla("fuente") + Vector2(0, T)
	return _rect("plaza").get_center() * T


static func _rect_punto(c: Vector2) -> Rect2i:
	return Rect2i(Vector2i(floori(c.x), floori(c.y)), Vector2i.ONE)


# Un punto invisible en mundo_y (para medir distancias cuando el dibujo es de gráficos).
func _ancla(c: Vector2) -> Node2D:
	var a := Node2D.new()
	a.position = c * T
	mundo_y.add_child(a)
	return a


# El Árbol Milenario sustituye al altar. El «altar» de zona.gd es su pie (ahí se examina); el dibujo va aparte.
func _poner_altar() -> Node2D:
	var r := _rect("arbol")
	var base := Vector2(r.get_center().x, r.end.y) * T
	var ancla := Node2D.new()
	ancla.position = base
	mundo_y.add_child(ancla)
	if nodos_lugar.has("arbol"):
		arbol = nodos_lugar["arbol"]
		nodos_lugar.erase("arbol")
		mundo_y.add_child(arbol)
		return ancla
	arbol_provisional = true
	if not ResourceLoader.exists(IMAGEN_ARBOL):
		arbol = _poner_objeto("arbol", base)
		arbol.scale = Vector2.ONE * 2.0
		return ancla
	var tex: Texture2D = Recursos.obtener(IMAGEN_ARBOL, "zona")
	var s := Sprite2D.new()
	s.texture = sombra_tex
	s.position = base + Vector2(20, 4)
	s.scale = Vector2(tex.get_width() * ESCALA_ARBOL * 0.9, tex.get_width() * ESCALA_ARBOL * 0.3) / 128.0
	sombras.add_child(s)
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() + 3)
	sp.scale = Vector2.ONE * ESCALA_ARBOL
	sp.position = base
	sp.material = mat_viento
	mundo_y.add_child(sp)
	arbol = sp
	var luz := _nueva_luz(Color(1.0, 0.86, 0.6), 0.55, 4.0)    # la copa se ve desde lejos en la hora azul
	luz.position = base + Vector2(0, -tex.get_height() * ESCALA_ARBOL * 0.5)
	add_child(luz)
	return ancla


func _adornar_altar() -> void:
	pass                                           # sin orbe: el Árbol no es un altar


# Los detalles de canon de progreso.gd, en su sitio nuevo (SITIOS_DETALLE): la puerta del crematorio y el pórtico.
func _poner_detalles() -> void:
	for d in Progreso.detalles_de(Oak.INDICE):
		var c: Vector2 = Oak.SITIOS_DETALLE.get(d["id"], plaza + Vector2(3, -2))
		var n := _arte(d["id"], _rect_punto(c))
		if n != null:
			mundo_y.add_child(n)
			detalles.append([_ancla(c), d])
		else:
			detalles.append([_poner_objeto("estela", c * T), d])


# Cofres hechos a mano, con su id escrito (no el de su posición). Los escondidos o a la vista brillan mientras están
# cerrados (el de la ronda se ve desde el mercado; el de las raíces, entre las hojas del Árbol).
func _poner_cofres() -> void:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	for c in Oak.COFRES:
		var abierto := abiertos.has(c["id"])
		var pos: Vector2 = c["casilla"] * T
		var sp := _poner_objeto("cofre_abierto" if abierto else "cofre", pos)
		cofres.append([sp, c["id"], abierto])
		var tipo: String = _secreto(c.get("secreto", "")).get("tipo", "")
		if not abierto and tipo in ["cofre escondido", "cofre a la vista"] and not _arte_tiene_estado(c["id"]):
			destellos[c["id"]] = _destello_fijo(pos + Vector2(0, -34), 0.2 if c.has("brilla_desde") else 0.12,
				Color(1.0, 0.85, 0.4), 30)


func _poner_piezas() -> void:
	for p in Oak.PIEZAS:
		var c: Vector2 = p["casilla"]
		var n := _arte(p["id"], _rect_punto(c))
		if n != null:
			mundo_y.add_child(n)
		else:
			n = _pieza_provisional(p)
		piezas.append([n, p, c * T])


func _pieza_provisional(p: Dictionary) -> Node2D:
	var c: Vector2 = p["casilla"]
	match p["id"]:
		"oak_barril":
			return _poner_objeto("oak_barril", c * T)
		"oak_tablon_gremio":                          # V11: el tablón del gremio, con su dibujo de tablón
			return _poner_objeto("oak_tablon", c * T)
		"oak_torre":
			return _poner_objeto("oak_puerta", Vector2(c.x, _rect("torre").end.y) * T)
		"oak_ronda_bajar":
			return _poner_objeto("oak_escalera", c * T)
		"oak_grieta":
			var g := _poner_objeto("oak_grieta", Vector2(c.x, _rect("grieta").end.y) * T)
			_destello_fijo(Vector2(c.x, _rect("grieta").end.y - 0.35) * T, 0.42, Color(1.0, 0.72, 0.4), 1)   # luz de velas
			return g
	if p["id"].begins_with("oak_farol_"):
		return _poner_objeto("farola", c * T)
	return _poner_objeto("estela", c * T)


func _poner_notas() -> void:
	for nd in Oak.NOTAS:
		if not nd.has("casilla"):                  # (la de los requisados sale del cofre)
			continue
		var c: Vector2 = nd["casilla"]
		var n := _arte(nd["id"], _rect_punto(c))
		if n != null:
			mundo_y.add_child(n)
		else:
			n = _poner_objeto(DIBUJO_NOTA.get(nd["id"], "oak_tablon"), c * T)
			if nd["id"] == "nota_oak_velas":
				for h in n.get_children():         # velas: llamas pequeñas
					var llama := h as CPUParticles2D
					if llama != null:
						llama.amount = 8
						llama.emission_sphere_radius = 16.0
						llama.scale_amount_min = 0.02
						llama.scale_amount_max = 0.04
		notas.append([n, nd, c * T])


# Un brillo que late (cofres que llaman la atención, la luz de la grieta).
func _destello_fijo(pos: Vector2, escala: float, color: Color, z: int) -> Sprite2D:
	var b := Sprite2D.new()
	b.texture = luz_tex
	b.material = mat_aditivo
	b.modulate = Color(color, 0.55)
	b.position = pos
	b.scale = Vector2.ONE * escala
	b.z_index = z
	add_child(b)
	var t := b.create_tween().set_loops()
	t.tween_property(b, "modulate:a", 0.15, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "modulate:a", 0.55, 1.1).set_trans(Tween.TRANS_SINE)
	return b


# Los faroles de la ronda, encendidos o apagados según la partida, y los estados del arte de gráficos.
func _actualizar_piezas() -> void:
	for e in piezas:
		var id: String = e[1]["id"]
		if id.begins_with("oak_farol_"):
			_encender(e[0], Progreso.estado(Oak.NOMBRE, id.trim_prefix("oak_")))
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	for n in _nodos_con_estados():
		for i in [1, 2, 3]:
			var f := "farol_%d" % i
			n.call("poner_estado", _farol_del_dibujo(n, f), Progreso.estado(Oak.NOMBRE, f))
		for c in Oak.COFRES:
			n.call("poner_estado", c["id"], not abiertos.has(c["id"]))
			n.call("poner_estado", _estado_abierto(c["id"]), abiertos.has(c["id"]))


# El estado del dibujo para el farol «farol_N» de la partida. Se emparejan por su sitio, de norte a sur: el farol N de
# la partida es la pieza oak_farol_N (ciudades/oakhaven.gd) y el dibujo numera los suyos con su propio orden (en el de
# gráficos, el 1 es el del norte y en la partida, el del sur). Sin anclas (otro módulo), el mismo nombre.
func _farol_del_dibujo(n: Node, estado: String) -> String:
	var anclas = n.get("anclas")
	if not anclas is Dictionary or not anclas.has("farol_1"):
		return estado
	var de_partida: Array = Oak.PIEZAS.filter(func(p): return p["id"].begins_with("oak_farol_"))
	de_partida.sort_custom(func(a, b): return a["casilla"].y < b["casilla"].y)
	var del_dibujo: Array = ["farol_1", "farol_2", "farol_3"].filter(func(k): return anclas.has(k))
	del_dibujo.sort_custom(func(a, b): return anclas[a].y < anclas[b].y)
	for i in mini(de_partida.size(), del_dibujo.size()):
		if de_partida[i]["id"].trim_prefix("oak_") == estado:
			return del_dibujo[i]
	return estado


# El estado del dibujo que dice que un cofre está abierto («oak_cofre_raices» → «cofre_raices_abierto», el destello
# entre las hojas del Árbol, que se ve mientras NO está puesto).
static func _estado_abierto(id_cofre: String) -> String:
	return id_cofre.trim_prefix("oak_") + "_abierto"


# Los dibujos de lugares de gráficos que tienen estados (pieza.gd: poner_estado y tiene_estado).
func _nodos_con_estados() -> Array:
	var r: Array = []
	var todos: Array = nodos_lugar.values()
	if arbol != null and not arbol_provisional:
		todos.append(arbol)
	for n in todos:
		if is_instance_valid(n) and n.has_method("poner_estado"):
			r.append(n)
	return r


func _arte_tiene_estado(nombre: String) -> bool:
	for n in _nodos_con_estados():
		if n.has_method("tiene_estado") and (n.call("tiene_estado", nombre) or n.call("tiene_estado", _estado_abierto(nombre))):
			return true
	return false


func _encender(n: Node2D, si: bool) -> void:
	if n.has_method("encender"):
		n.call("encender", si)
		return
	n.self_modulate = Color.WHITE if si else Color(0.5, 0.5, 0.56)
	for h in n.get_children():
		var luz := h as PointLight2D
		if luz != null:
			luz.visible = si
		var llama := h as CPUParticles2D
		if llama != null:
			llama.visible = si
			llama.emitting = si


func _farol_encendido(p: Dictionary) -> bool:
	return p["id"].begins_with("oak_farol_") and Progreso.estado(Oak.NOMBRE, p["id"].trim_prefix("oak_"))


# ================================================================= dibujos provisionales

func _objeto(tipo: String) -> Dictionary:
	if not OBJETOS_OAK.has(tipo) or texturas_obj.has(tipo):
		return super._objeto(tipo)
	var d: Dictionary = OBJETOS_OAK[tipo].duplicate()
	d["tex"] = ImageTexture.create_from_image(_cargar_cache("obj_%s_o%d" % [tipo, VERSION_OAK], _dibujar_objeto.bind(tipo)))
	texturas_obj[tipo] = d
	return d


func _dibujar_objeto(tipo: String) -> Image:
	if not OBJETOS_OAK.has(tipo):
		return super._dibujar_objeto(tipo)
	var tam: Vector2i = OBJETOS_OAK[tipo]["tam"]
	var img := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
	match tipo:
		"oak_barril":
			_pintar_barril(img)
		"oak_tablon":
			_pintar_tablon(img)
		"oak_letrero":
			_pintar_letrero(img)
		"oak_atril":
			_pintar_atril(img)
		"oak_velas":
			_pintar_velas(img)
		"oak_grieta":
			_pintar_grieta(img)
		"oak_escalera":
			_pintar_escalera(img)
		"oak_puerta":
			_pintar_puerta_torre(img)
	return img


# Barril de sidra: duelas, dos aros de hierro y la tapa.
func _pintar_barril(img: Image) -> void:
	var w := img.get_width()
	var mitad := int(w * 0.5)
	for y in range(14, 60):
		var hw := 17.0 + 5.0 * sin(PI * (y - 14) / 46.0)
		for x in w:
			var u := (x - w * 0.5) / hw
			if absf(u) > 1.0:
				continue
			var c := Color8(146, 96, 52) * (0.62 + (0.6 - u * 0.4) * 0.5)
			if posmod(x - mitad, 7) == 0:
				c = c.darkened(0.25)
			if absi(y - 23) <= 1 or absi(y - 51) <= 1:
				c = Color8(66, 62, 68).lightened(0.25 * (1.0 - u))
			img.set_pixel(x, y, Color(c, 1.0))
	for y in range(8, 21):
		for x in w:
			var e := Vector2((x - w * 0.5) / 17.0, (y - 14.0) / 6.0).length()
			if e <= 1.0:
				img.set_pixel(x, y, Color8(178, 130, 78) if e < 0.78 else Color8(92, 60, 34))


# Tablón de anuncios con tejadillo y papeles clavados.
func _pintar_tablon(img: Image) -> void:
	var madera := Color8(112, 76, 44)
	_px_rect(img, Rect2i(14, 30, 7, 76), madera.darkened(0.2))
	_px_rect(img, Rect2i(75, 30, 7, 76), madera.darkened(0.2))
	_px_rect(img, Rect2i(8, 24, 80, 52), madera)
	_px_rect(img, Rect2i(8, 24, 80, 3), madera.lightened(0.2))
	_px_rect(img, Rect2i(4, 16, 88, 9), madera.darkened(0.35))
	for papel in [Rect2i(14, 32, 22, 28), Rect2i(40, 30, 18, 22), Rect2i(62, 34, 20, 30), Rect2i(42, 56, 16, 14)]:
		_px_rect(img, papel, Color8(226, 214, 184))
		for ly in range(papel.position.y + 5, papel.end.y - 3, 4):
			_px_rect(img, Rect2i(papel.position.x + 3, ly, papel.size.x - 6, 1), Color8(120, 110, 96))


# El cuervo de hierro oxidado del Cuervo, colgado de un poste.
func _pintar_letrero(img: Image) -> void:
	var hierro := Color8(92, 64, 50)
	_px_rect(img, Rect2i(18, 20, 6, 94), Color8(70, 50, 34))
	_px_rect(img, Rect2i(18, 20, 52, 5), hierro.darkened(0.2))
	_px_linea(img, Vector2(24, 42), Vector2(42, 24), 1.5, hierro.darkened(0.2))
	_px_linea(img, Vector2(52, 25), Vector2(52, 37), 0.8, hierro.darkened(0.4))
	_px_linea(img, Vector2(64, 25), Vector2(64, 35), 0.8, hierro.darkened(0.4))
	_px_disco(img, Vector2(58, 50), 10.0, hierro)
	_px_disco(img, Vector2(66, 41), 5.5, hierro)
	_px_linea(img, Vector2(70, 41), Vector2(77, 43), 1.4, hierro.lightened(0.2))
	_px_linea(img, Vector2(50, 54), Vector2(41, 61), 2.6, hierro.darkened(0.1))
	_px_linea(img, Vector2(56, 59), Vector2(54, 67), 0.8, hierro.darkened(0.3))
	_px_linea(img, Vector2(61, 59), Vector2(62, 67), 0.8, hierro.darkened(0.3))
	_px_disco(img, Vector2(67, 40), 1.3, Color8(226, 170, 96))
	var rng := RandomNumberGenerator.new()                       # óxido
	rng.seed = 7
	for i in 90:
		var p := Vector2i(rng.randi_range(40, 78), rng.randi_range(34, 64))
		var c := img.get_pixelv(p)
		if c.a > 0.5:
			img.set_pixelv(p, c.lerp(Color8(176, 96, 46), 0.55))


# Atril con el libro de guardia abierto.
func _pintar_atril(img: Image) -> void:
	var madera := Color8(104, 70, 42)
	_px_rect(img, Rect2i(29, 40, 6, 40), madera.darkened(0.15))
	_px_rect(img, Rect2i(16, 74, 32, 6), madera.darkened(0.3))
	for y in range(22, 42):
		var k := (y - 22) / 20.0
		_px_rect(img, Rect2i(int(10 - k * 2), y, int(44 + k * 4), 1), madera)
	_px_rect(img, Rect2i(13, 18, 18, 18), Color8(232, 222, 196))
	_px_rect(img, Rect2i(33, 18, 18, 18), Color8(222, 212, 186))
	_px_rect(img, Rect2i(31, 17, 2, 20), Color8(120, 50, 40))
	for ly in range(22, 34, 3):
		_px_rect(img, Rect2i(15, ly, 14, 1), Color8(110, 100, 90))
		_px_rect(img, Rect2i(35, ly, 14, 1), Color8(110, 100, 90))


# Altar pequeño de piedra con el anillo partido y velas encendidas.
func _pintar_velas(img: Image) -> void:
	var piedra := Color8(132, 126, 118)
	_px_rect(img, Rect2i(12, 38, 56, 28), piedra)
	_px_rect(img, Rect2i(10, 34, 60, 6), piedra.lightened(0.15))
	_px_rect(img, Rect2i(12, 62, 56, 4), piedra.darkened(0.3))
	_px_anillo(img, Vector2(40, 52), 7.0)
	for x in [20, 33, 47, 60]:
		var alto := 14 if x in [33, 47] else 10
		_px_rect(img, Rect2i(x - 2, 34 - alto, 5, alto), Color8(238, 230, 210))
		_px_disco(img, Vector2(x, 34 - alto - 3), 2.2, Color8(255, 210, 110))


# Grieta en el muro del callejón: oscura en los bordes y con luz de velas dentro.
func _pintar_grieta(img: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 35
	var x := 32.0
	for y in range(30, 92):
		x = clampf(x + rng.randf_range(-1.6, 1.6), 26.0, 38.0)
		var k := sin(PI * (y - 30) / 62.0)
		var ancho := 2.0 + 3.0 * k
		for xx in range(int(x - ancho), int(x + ancho) + 1):
			var borde := absf(xx - x) > ancho - 1.2
			img.set_pixel(xx, y, Color8(26, 20, 18) if borde else Color8(255, 196, 112).darkened(0.3 * (1.0 - k)))


# Boca de la escalera de la torre, en la ronda.
func _pintar_escalera(img: Image) -> void:
	_px_rect(img, Rect2i(10, 8, 44, 32), Color8(34, 30, 30))
	_px_rect(img, Rect2i(8, 6, 48, 3), Color8(120, 112, 104))
	_px_rect(img, Rect2i(8, 39, 48, 3), Color8(90, 84, 78))
	for i in 4:
		_px_rect(img, Rect2i(14, 12 + i * 7, 36, 3), Color8(110, 80, 50).darkened(i * 0.12))


# Puerta de la Torre de la Campana: arco de madera con herrajes.
func _pintar_puerta_torre(img: Image) -> void:
	var madera := Color8(98, 64, 38)
	for y in range(8, 84):
		for x in range(6, 50):
			if y < 30 and Vector2(x, y).distance_to(Vector2(28, 30)) > 22.0:
				continue
			var c := madera.darkened(0.18 if posmod(x - 6, 9) == 0 else 0.0)
			if absi(y - 44) <= 1 or absi(y - 70) <= 1:
				c = Color8(60, 58, 62)
			img.set_pixel(x, y, c)
	_px_disco(img, Vector2(38, 58), 3.0, Color8(180, 150, 80))


# ================================================================= Kael

func _crear_jugador() -> void:
	super._crear_jugador()
	if not _pisable(jugador.position / T):         # una posición que ya no es calle (o una prueba): a la puerta
		jugador.position = Oak.INICIO * T
		camara.reset_smoothing()
		RenderingServer.global_shader_parameter_set("jugador_pos", jugador.position)
		if hierba_pies != null:
			hierba_pies.visible = _hay_hierba(jugador.position)


func _physics_process(delta: float) -> void:
	if viajando:
		return
	super._physics_process(delta)
	if saliendo or _en_dialogo() or barra_activa:
		return
	if not Progreso.estado(Oak.NOMBRE, "vista_raices") and r_raices.has_point(jugador.position / T):
		Oak.aplicar_senal("oak:vista_raices")      # la primera vez que se llega a las raíces
		_avisar(_texto_vista("oak_vista_raices"))
		_guardar()


func _process(delta: float) -> void:
	super._process(delta)
	_musica()
	_siguiente_aviso()
	_arbol_translucido(delta)
	_mirar_arbol(delta)
	_comentarios(delta)
	_vida(delta)
	_rutinas(delta)
	if velo_patio != null:
		velo_patio.modulate.a = move_toward(velo_patio.modulate.a, 0.0 if _patio_visible() else 1.0, delta * 2.0)


# Lo que dicen los héroes al explorar (dialogos/comentarios.gd). La llegada y el cofre los lleva zona.gd; aquí, el
# momento de la llegada (el de Oakhaven) y el de quedarse quietos. Nunca durante un diálogo, un fundido o un menú.
func _momento_llegada() -> String:
	return "llegar:oakhaven"


func _ocupado_para_comentar() -> bool:
	return viajando or super._ocupado_para_comentar()


func _comentarios(delta: float) -> void:
	if ui == null or jugador == null:
		return
	if quieto_t < 0.0:                             # pausa tras un comentario por estar quietos
		quieto_t = minf(quieto_t + delta, 0.0)
		return
	if _ocupado_para_comentar() or tiene_destino or jugador.velocity.length() > 5.0:
		quieto_t = 0.0                             # moverse reinicia la espera
		return
	quieto_t += delta
	if quieto_t >= QUIETO_COMENTARIO:
		quieto_t = -PAUSA_COMENTARIOS if _comentar("quieto") else 0.0


# Oakhaven vivo (ciudades/oakhaven_vida.gd): al pasar cerca, un vecino o una voz de la calle dice algo sobre su cabeza,
# sin abrir diálogo. Una frase a la vez, con pausas, nunca durante un diálogo, un fundido o un menú, ni a la vez que
# un comentario de los héroes.
func _vida(delta: float) -> void:
	if jugador == null:
		return
	for k in voz_quien.keys():
		voz_quien[k] -= delta
	if is_instance_valid(voz_globo):
		if _en_dialogo() or viajando or saliendo:
			voz_globo.queue_free()
			voz_globo = null
		return
	voz_pausa -= delta
	if voz_pausa > 0.0 or _ocupado_para_comentar() or _comentario_en_pantalla():
		return
	var mejor := {}
	var dist := Vida.RADIO * T
	for n in npcs:
		var id: String = n[1].get("id", "")
		var d := jugador.position.distance_to(n[0].position)
		if d < dist and voz_quien.get(id, 0.0) <= 0.0:
			var s: Sprite2D = n[0]
			mejor = {"id": id, "pie": s.position, "alto": s.texture.get_height() * s.scale.y, "anonimo": false}
			dist = d
	for v in Vida.VOCES:
		var p: Vector2 = v["casilla"] * T
		var d := jugador.position.distance_to(p)
		if d < dist and voz_quien.get(v["id"], 0.0) <= 0.0:
			mejor = {"id": v["id"], "pie": p, "alto": 90.0, "anonimo": true}
			dist = d
	if mejor.is_empty():
		return
	var texto := Vida.frase(mejor["id"], franja, voz_dichos)
	voz_quien[mejor["id"]] = Vida.PAUSA_QUIEN
	if texto == "":
		return
	voz_dichos[texto] = true
	voz_pausa = Vida.duracion(texto) + Vida.PAUSA
	voz_globo = _globo(texto, mejor["pie"] - Vector2(0, mejor["alto"] + 12.0), mejor["anonimo"])
	voz_globo.set_meta("quien", mejor["id"])


# La hora de la ciudad (ciudades/oakhaven_vida.gd): cada vecino a su sitio de esa franja (con un fundido si «animar»),
# su paseo si le toca, las frases de esa hora y lo que suena. Se recuerda en la sesión (Engine «oak_franja»).
func _poner_franja(f: String, animar: bool) -> void:
	if not f in Vida.FRANJAS:
		f = Vida.FRANJA_AL_LLEGAR
	franja = f
	Engine.set_meta("oak_franja", f)
	Sonido.fijar_momento(self, Vida.MOMENTO_SONIDO[f])
	voz_dichos.clear()
	for n in npcs:
		_poner_en_rutina(n, animar)


func _poner_en_rutina(n: Array, animar: bool) -> void:
	var id: String = n[1].get("id", "")
	var r := Vida.rutina(id, franja)
	if r.is_empty():
		return
	var s: Sprite2D = n[0]
	if paseos.has(id):
		paseos[id].kill()
		paseos.erase(id)
	if not s.has_meta("sombra"):                      # la sombra que puso zona.gd, para moverla con él
		for sb in sombras.get_children():
			if sb.position.distance_to(s.position + Vector2(0, 2)) < 1.0:
				s.set_meta("sombra", sb)
	var destino: Vector2 = r["casilla"] * T
	if not animar or s.position == destino:
		s.position = destino
		_pasear(n, r)
		return
	var t := s.create_tween()
	t.tween_property(s, "modulate:a", 0.0, 0.4)
	t.tween_callback(func():
		s.position = destino
		_pasear(n, r))
	t.tween_property(s, "modulate:a", 1.0, 0.4)


# El paseo de la rutina («pasea»): va y viene entre «casilla» y «hasta», despacio, con una pausa en cada punta.
func _pasear(n: Array, r: Dictionary) -> void:
	if r.get("hace", "") != "pasea" or not r.has("hasta"):
		return
	var s: Sprite2D = n[0]
	var a: Vector2 = r["casilla"] * T
	var b: Vector2 = r["hasta"] * T
	var dur := a.distance_to(b) / (T * 1.1)
	var t := s.create_tween().set_loops()
	t.tween_callback(func(): s.flip_h = b.x < a.x)
	t.tween_property(s, "position", b, dur).set_trans(Tween.TRANS_SINE)
	t.tween_interval(2.0)
	t.tween_callback(func(): s.flip_h = a.x < b.x)
	t.tween_property(s, "position", a, dur).set_trans(Tween.TRANS_SINE)
	t.tween_interval(2.0)
	paseos[n[1].get("id", "")] = t


# Pasa el tiempo de la franja (no durante un diálogo ni un fundido) y, mientras se habla, los paseos se paran; las
# sombras siguen a su vecino.
func _rutinas(delta: float) -> void:
	var parado: bool = _en_dialogo() or viajando
	for id in paseos:
		if parado:
			paseos[id].pause()
		else:
			paseos[id].play()
	for n in npcs:
		var sb = n[0].get_meta("sombra", null)
		if sb != null and is_instance_valid(sb):
			sb.position = n[0].position + Vector2(0, 2)
	if parado or saliendo:
		return
	franja_t += delta
	var siguiente := Vida.franja_siguiente(franja)
	if franja_t >= Vida.DURACION_FRANJA and siguiente != franja:
		franja_t = 0.0
		_poner_franja(siguiente, true)


func _comentario_en_pantalla() -> bool:
	for n in ui.get_children():
		if n.name.begins_with("comentario"):
			return true
	return false


# La frase sobre la cabeza (o en la puerta, si es una voz): sin luz ni ambiente que la oscurezcan, sube un poco y se va.
func _globo(texto: String, pos: Vector2, anonimo: bool) -> Node2D:
	var g := Node2D.new()
	g.name = "voz_vecino"
	g.position = pos
	g.z_index = 30
	g.modulate.a = 0.0
	var l := Label.new()
	l.text = ("«%s»" % texto) if anonimo else texto
	l.add_theme_font_override("font", EstiloUI.cursiva() if anonimo else EstiloUI.normal())
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7) if anonimo else EstiloUI.LUZ_CLARA)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.1, 0.95))
	l.add_theme_constant_override("outline_size", 7)
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	l.material = m
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(620, 34)
	l.position = Vector2(-310, -34)
	g.add_child(l)
	add_child(g)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(g, "position:y", pos.y - 10.0, Vida.duracion(texto)).set_trans(Tween.TRANS_SINE)
	t.tween_property(g, "modulate:a", 0.0, 0.35)
	t.tween_callback(g.queue_free)
	return g


# En las raíces, la cámara sube hasta el borde de arriba de la ciudad para que se vea la copa del Árbol entera (sin
# pasar del borde y sin perder de vista a Kael).
func _mirar_arbol(delta: float) -> void:
	if jugador == null or camara == null:
		return
	var medio := get_viewport_rect().size.y * 0.5 / camara.zoom.y
	var objetivo := 0.0
	if r_raices.has_point(jugador.position / T):
		objetivo = clampf(medio - maxf(jugador.position.y, medio), -200.0, 0.0)
	camara.offset.y = move_toward(camara.offset.y, objetivo, delta * 480.0)


# musica.gd elige la música por la escena; mientras no conozca esta, la ciudad pide la suya («ciudad»). Cuando la conozca
# (una línea en contexto_de, pedida en el informe), esto no hace nada.
func _musica() -> void:
	if musica_conoce or musica_nodo.contexto == "ciudad" or get_tree().current_scene != self:
		return
	musica_nodo.pedir("ciudad")


# Detrás de la copa del Árbol, Kael se vería tapado: la copa se vuelve translúcida.
func _arbol_translucido(delta: float) -> void:
	var s := arbol as Sprite2D
	if not arbol_provisional or s == null or s.texture == null:
		return
	var ancho := s.texture.get_width() * s.scale.x * 0.45
	var alto := s.texture.get_height() * s.scale.y * 0.95
	var p := jugador.position - s.position
	var detras := p.y < -8.0 and p.y > -alto and absf(p.x) < ancho
	s.modulate.a = move_toward(s.modulate.a, 0.45 if detras else 1.0, delta * 3.0)


# ================================================================= vecinos, piezas y notas

# Los vecinos de ciudades/oakhaven.gd; los que tienen muñeco propio en el arte (muneco_de) lo llevan, ya sin «tinte».
func _npcs() -> Array:
	if vecinos.is_empty():
		var con_munecos := arte != null and _tiene_funcion(arte, "muneco_de")
		for d in Oak.NPCS:
			var v: Dictionary = d
			if con_munecos:
				var ruta: String = arte.muneco_de(d["id"], d["imagen"])
				if ruta != d["imagen"] and ResourceLoader.exists(ruta):
					v = d.duplicate()
					v["imagen"] = ruta
					v.erase("tinte")
			vecinos.append(v)
	return vecinos


func _dialogo_npc(n: Array) -> String:
	return Oak.dialogo_de(n[1].get("id", ""), n[2])


func _comprobar_cerca() -> void:
	super._comprobar_cerca()
	pieza_cerca = null
	nota_cerca = null
	var mejor := _distancia_elegida()
	var en_alto := _en_alto(jugador.position)
	for e in piezas:
		if _farol_encendido(e[1]) or _en_alto(e[2]) != en_alto:   # la ronda va en alto: no se usa desde abajo
			continue
		var d: float = jugador.position.distance_to(e[2])
		if d < RADIO_PIEZA and d < mejor:
			mejor = d
			pieza_cerca = e
	for e in notas:
		var d: float = jugador.position.distance_to(e[2])
		if d < RADIO_PIEZA and d < mejor:
			mejor = d
			pieza_cerca = null
			nota_cerca = e
	if pieza_cerca == null and nota_cerca == null:
		return
	cofre_cerca = null
	detalle_cerca = null
	npc_cerca = null
	boton_examinar.visible = true
	if pieza_cerca != null:
		var p: Dictionary = pieza_cerca[1]
		boton_examinar.text = p["accion"] if Oak.cumple(p["si"]) else "Examinar"
	else:
		boton_examinar.text = "Examinar"


# Para zona.gd: con una pieza o una nota a mano, el botón no se esconde un instante cada fotograma (eso anulaba la
# pulsación con el dedo). Mismo criterio que arriba, sin vecinos ni cofres (zona.gd solo pregunta si no hay ninguno).
func _hay_otra_accion() -> bool:
	var en_alto := _en_alto(jugador.position)
	for e in piezas:
		if not _farol_encendido(e[1]) and _en_alto(e[2]) == en_alto and jugador.position.distance_to(e[2]) < RADIO_PIEZA:
			return true
	for e in notas:
		if jugador.position.distance_to(e[2]) < RADIO_PIEZA:
			return true
	return false


# A qué distancia está lo que eligió zona.gd (cofre, detalle o vecino); INF si nada (o solo el Árbol).
func _distancia_elegida() -> float:
	for x in [cofre_cerca, detalle_cerca, npc_cerca]:
		if x != null and boton_examinar.visible:
			return jugador.position.distance_to(x[0].position)
	return INF


func _en_alto(px: Vector2) -> bool:
	return r_ronda.has_point(px / T)


func _accion() -> void:
	if viajando:
		return
	if pieza_cerca != null:
		_usar_pieza(pieza_cerca)
		return
	if nota_cerca != null:
		_leer_nota(nota_cerca)
		return
	super._accion()


func _usar_pieza(e: Array) -> void:
	var p: Dictionary = e[1]
	if p["id"] == "oak_tablon_gremio":                # V11: el tablón del gremio abre su ventana
		_abrir_gremio()
		return
	if not Oak.cumple(p["si"]):
		_avisar(p["texto_sin"], "examinar", true)
		_avisos_hallazgo(Hallazgos.al_examinar(Oak.INDICE, "pieza:" + p["id"]), 0.0)   # (hallazgos.gd)
		return
	var primera_vista: bool = p["id"] == "oak_torre" and not Progreso.estado(Oak.NOMBRE, "vista_torre")
	var aviso_senal := Oak.aplicar_senal(p["senal"]) if p["senal"] != "" else ""
	var texto: String = p["texto"]
	if p.has("lleva_a"):
		var a: Vector2 = p["lleva_a"]
		if p["id"] == "oak_grieta" and jugador.position.y > e[2].y:   # la grieta se pasa en los dos sentidos
			a = p["casilla"] * 2.0 - p["lleva_a"]
			texto = ""
		_viajar(a, "puerta_abre" if p["id"] in ["oak_torre", "oak_ronda_bajar"] else "")
	if texto != "" and aviso_senal != "" and texto.length() + aviso_senal.length() < 90:
		texto += " " + aviso_senal                 # una sola frase: «El farol prende. Uno menos. Farol encendido (1 de 3).»
		aviso_senal = ""
	_avisar(texto, "" if p.has("lleva_a") else "examinar", true)
	if primera_vista:
		_avisar(_texto_vista("oak_vista_torre"))
		Sonido.efecto("campana", {"retraso": 0.8})  # arriba, la campana de la torre (tanda 3 de sonido)
	_avisar(aviso_senal, _efecto_de(p["senal"]))
	_actualizar_piezas()
	if aviso_senal != "" or primera_vista or p["senal"] != "":
		_guardar()


func _leer_nota(e: Array) -> void:
	var n: Dictionary = e[1]
	_avisar(n["texto"], "examinar", true)
	if Oak.ver_nota(n["id"]):
		_avisar("Nueva nota en el Diario: «%s»" % n["nombre"], "pagina")
		_guardar()


# Con un fundido, como el ascensor de la Garganta: subir a la ronda, bajar o pasar la grieta.
func _viajar(a: Vector2, efecto := "") -> void:
	viajando = true
	tiene_destino = false
	boton_examinar.visible = false
	if efecto != "":
		Sonido.efecto(efecto)                      # sonido.gd
	var t := create_tween()
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.3)
	t.tween_callback(func():
		jugador.position = a * T
		camara.reset_smoothing())
	t.tween_property(fundido, "color:a", 0.0, 0.35)
	t.tween_callback(func(): viajando = false)


func _texto_vista(id: String) -> String:
	var s := _secreto(id)
	if s.has("texto_pv07") and Progreso.hito("pv_07"):
		return s["texto_pv07"]
	return s.get("texto", "")


# El brazalete también brilla cerca de la grieta del callejón, mientras no se haya pasado.
func _brazalete() -> void:
	super._brazalete()
	if Progreso.estado(Oak.NOMBRE, "grieta"):
		return
	var d := jugador.position.distance_to(_secreto("oak_secreto_velas")["casilla"] * T)
	if d > RADIO_BRAZALETE * 1.6:
		brillo_grieta = false
	elif d < RADIO_BRAZALETE and not brillo_grieta:
		brillo_grieta = true
		_brillo_brazalete()


# ================================================================= cofres

func _abrir_cofre(c: Array) -> void:
	if Oak.cofre(c[1]).is_empty():
		super._abrir_cofre(c)
		return
	var r := Oak.abrir_cofre(c[1])
	if r.has("bloqueado"):
		Sonido.efecto("cerrada")                   # sonido.gd
		_mostrar_aviso(r["bloqueado"])
		return
	c[2] = true
	var d := _objeto("cofre_abierto")
	c[0].texture = d["tex"]
	c[0].offset = -d["origen"]
	if destellos.has(c[1]):
		destellos[c[1]].queue_free()
		destellos.erase(c[1])
	_actualizar_piezas()                           # (el destello del arte de gráficos, si lo pinta él)
	if r.is_empty():                               # ya estaba abierto (no debería pasar: se dibuja abierto)
		return
	Sonido.efecto("cofre")                         # la tapa y, después, el premio (sonido.gd)
	Sonido.efecto("tesoro", {"retraso": 0.3})
	_avisar(r["texto"], "", true)
	_poner_oro()
	var brillo := Sprite2D.new()
	brillo.texture = luz_tex
	brillo.material = mat_aditivo
	brillo.modulate = Color(1.0, 0.85, 0.3, 0.9)
	brillo.position = c[0].position + Vector2(0, -30)
	brillo.scale = Vector2(0.2, 0.2)
	add_child(brillo)
	var t := create_tween()
	t.tween_property(brillo, "scale", Vector2(0.9, 0.9), 0.4)
	t.parallel().tween_property(brillo, "modulate:a", 0.0, 0.6)
	t.tween_callback(brillo.queue_free)
	if r["nota"] != "":
		_avisar("Nueva nota en el Diario: «%s»" % Oak.nota(r["nota"])["nombre"], "pagina")
	_comentar_luego("cofre", 1.2)                  # alguien del grupo lo comenta, tras el premio (zona.gd)
	_guardar()


# ================================================================= posada

# El botón POSADA pregunta antes: «¿Qué va a ser? Dormir / Sopa / Rumor» (ciudades/oakhaven_posada.gd, menu_dialogo).
# Así la sopa y los rumores no dependen de hablar con la posadera ni de su misión. «Dormir» sigue en _posada.
func _boton_posada() -> void:
	var D = get_node_or_null("/root/Dialogic")
	if D == null:
		_posada()
		return
	if D.current_timeline != null or viajando or saliendo:
		return
	var t := DialogicTimeline.new()
	t.from_text(Posada.menu_dialogo())
	tiene_destino = false
	boton_examinar.visible = false
	D.start(t)


func _pagar_posada() -> bool:
	# ciudades/oakhaven_posada.gd, lo mismo que usará el Oakhaven 3D: la noche gratis de «Tres favores para el Cuervo»
	# (invita la posadera) o PRECIO_DORMIR, que es el PRECIO_POSADA de zona.gd
	noche_invitada = Progreso.estado(Oak.NOMBRE, "noche_gratis")
	return Posada.pagar_noche()


# Al despertar, una charla de posada nueva si la hay (CHARLAS_POSADA: queda vista) o la escena corta de siempre con
# los que están en el grupo (ESCENAS_POSADA; las dos en ciudades/oakhaven.gd).
func _tras_posada() -> void:
	franja_t = 0.0
	_poner_franja("manana", true)                # ha amanecido: rutinas, frases y sonido de la mañana
	_actualizar_posada()
	_empezar_dialogo(Oak.escena_al_despertar())
	if noche_invitada:
		noche_invitada = false
		_avisar(Oak.TEXTO_NOCHE_GRATIS)
	_guardar()


func _actualizar_posada() -> void:
	for b in botones_hud:
		if b.get_meta("clave", "") == "POSADA":
			b.text = "POSADA (gratis)" if Progreso.estado(Oak.NOMBRE, "noche_gratis") else "POSADA (%d)" % PRECIO_POSADA


# ================================================================= señales de los diálogos y avisos

# [signal arg="oak:…"] de los diálogos: misiones, pagos y recompensas (una sola vez; ciudades/oakhaven.gd).
func _al_senal(arg) -> void:
	var s := str(arg)
	if not s.begins_with("oak:"):
		return
	cambios = true
	if s == "oak:rumor":                         # la posadera lo cuenta al acabar este diálogo (_al_acabar_dialogo)
		rumor_pendiente = Posada.rumor()["texto"]
		return
	if s == "oak:dormir":                        # se descansa al acabar el diálogo (_posada de zona.gd)
		dormir_pendiente = true
		return
	if s.begins_with("oak:servicio_"):            # V10: la forja, las armaduras o la botica (servicios.gd)
		servicio_pendiente = s.trim_prefix("oak:servicio_")
		return
	var t := Oak.aplicar_senal(s)
	if t == "":
		return
	_avisar(t, _efecto_de(s))
	_poner_oro()
	_actualizar_posada()
	_actualizar_piezas()


func _al_acabar_dialogo() -> void:
	_poner_oro()
	if dormir_pendiente:
		dormir_pendiente = false
		get_tree().create_timer(0.2).timeout.connect(func():   # (Dialogic acaba de cerrar: un momento)
			if is_instance_valid(self) and not saliendo:
				_posada())
	if servicio_pendiente != "":
		var sv := servicio_pendiente
		servicio_pendiente = ""
		get_tree().create_timer(0.2).timeout.connect(func():   # (Dialogic acaba de cerrar: un momento)
			if is_instance_valid(self) and not saliendo:
				_abrir_servicio(sv))
	if rumor_pendiente != "":
		var texto := rumor_pendiente
		rumor_pendiente = ""
		get_tree().create_timer(0.2).timeout.connect(func():   # (Dialogic acaba de cerrar: un momento)
			if is_instance_valid(self) and not saliendo:
				_contar_rumor(texto))
	if cambios:
		cambios = false
		_guardar()


# Los avisos de un hallazgo (hallazgos.gd), en la cola de avisos de la ciudad: uno detrás de otro, tras el que esté.
func _avisos_hallazgo(textos: Array, _desde: float) -> void:
	if textos.is_empty():
		return
	for t in textos:
		_avisar(t)
	Sonido.efecto("tesoro", {"retraso": 0.3})
	_poner_oro()
	_guardar()


# El rumor de la posadera (ciudades/oakhaven_posada.gd), en su caja de diálogo: una frase hecha al momento.
func _contar_rumor(texto: String) -> void:
	var D = get_node_or_null("/root/Dialogic")
	if D == null or D.current_timeline != null:
		_avisar(texto)
		return
	var t := DialogicTimeline.new()
	t.from_text("join posadera (normal) center\nposadera: %s\nleave posadera" % texto)
	tiene_destino = false
	boton_examinar.visible = false
	D.start(t)


static func _efecto_de(s: String) -> String:
	if s == "":
		return ""
	if s in ["oak:pip_pagar", "oak:sopa"]:
		return "monedas"
	if s.begins_with("oak:farol_"):                # Kael enciende un farol de la ronda (tanda 3 de sonido)
		return "farol"
	if s.ends_with("_aceptados") or s == "oak:lavanda_pedida":
		return "pagina"
	if s.ends_with("_hechos") or s == "oak:lavanda_entregada":
		return "tesoro"
	return "ui_confirmar"


# Los avisos de la ciudad, de uno en uno: «ya» lo enseña ahora (lo que acaba de hacer el jugador); si no, espera a que
# termine el aviso de antes y el diálogo (durante un diálogo la interfaz no se ve).
func _avisar(texto: String, efecto := "", ya := false) -> void:
	if texto == "":
		return
	if ya:
		if efecto != "":
			Sonido.efecto(efecto)                  # sonido.gd
		_mostrar_aviso(texto)
	else:
		avisos.append([texto, efecto])


func _siguiente_aviso() -> void:
	if avisos.is_empty() or saliendo or _en_dialogo():
		return
	if tween_aviso != null and tween_aviso.is_valid() and tween_aviso.is_running():
		return
	var a: Array = avisos.pop_front()
	_avisar(a[0], a[1], true)


func _guardar() -> void:
	guardar_posicion()
	Progreso.guardar(scene_file_path)              # en las pruebas no escribe (progreso.gd)


# V10: el servicio de quien atiende (servicios.gd). Mientras está abierto, Kael no anda (como la tienda).
func _abrir_servicio(servicio: String) -> void:
	if tienda_abierta:
		return
	tienda_abierta = true
	tiene_destino = false
	var capa := CanvasLayer.new()
	capa.layer = 5
	add_child(capa)
	var n = load("res://servicios.gd").abrir(capa, servicio)
	servicio_abierto = n
	if n == null:
		tienda_abierta = false
		capa.queue_free()
		return
	n.cerrado.connect(func():
		tienda_abierta = false
		servicio_abierto = null
		capa.queue_free()
		_poner_oro())
