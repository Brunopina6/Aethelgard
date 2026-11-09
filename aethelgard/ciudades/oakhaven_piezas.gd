extends RefCounted
# El arte de Oakhaven (T-089, gráficos): monta cada pieza de la ciudad como un Node2D listo para poner en «mundo_y»
# (el nodo con y_sort de zona.gd). Lo usa ciudad_oakhaven.gd (narrativa); el trazado y la lógica son suyos.
#
#   const Piezas := preload("res://ciudades/oakhaven_piezas.gd")
#   var p := Piezas.crear_pieza("taberna", Rect2i(11, 19, 10, 6), T)   # null si no hay arte para ese id
#   if p: mundo_y.add_child(p)
#
# QUÉ ES CADA PIEZA. Un id por lugar de ciudades/oakhaven.gd que tiene arte (taberna, crematorio, arbol, concejo,
# torre, ronda, mercado…) más piezas sueltas de relleno (casa_*, farol…): ids() da la lista y rect_de(id) la huella
# para la que se dibujó. El arte está horneado en 3/4 con la proyección de la ciudad (64 px por casilla; lo que se
# alza sube 64 px por metro): cada imagen cae en su píxel exacto. Si se pide otra huella, la pieza se centra abajo en
# ella (y avisa); si se pide otro tamaño de casilla, la pieza entera se escala.
#
# ANCLAS (Pieza.ancla(nombre) → posición global): «puerta», «humo», «farol_puerta», «letrero», «farol_1»…; cada
# pieza documenta las suyas en arte_datos.gd. Sirven para poner PNJ, cofres, avisos o sonidos en su sitio.
#
# ORDEN DE DIBUJADO (qué tapa a Kael y qué no). Todo va dentro de la pieza con y_sort: cada imagen es un hijo cuyo
# «y» es la línea con la que se ordena frente a Kael (Kael más al sur, por delante; más al norte, por detrás):
#   - cuerpo (tipo «edificio»): ordena con la fachada sur de la huella (rect.end.y). Kael al norte de esa línea
#     queda detrás y la imagen se aclara en un círculo a su alrededor (edificio.gdshader). Tapa todo lo de detrás.
#   - delanteras y letreros: ordenan con su propia línea (el letrero del cuervo, con la calle a 0,75 casillas de la
#     fachada) y se mecen alrededor de su punto de cuelgue (vaiven.gdshader).
#   - suelo: la calcomanía de sombra y de luz cálida en el empedrado. Ordena con su borde de arriba, así que queda
#     DEBAJO de todo lo que está encima (Kael, PNJ, objetos). Mezcla premultiplicada: suma la luz y oscurece la sombra.
#   - efectos (humo, halos de faroles y ventanas, luciérnagas): delante de su edificio.
# Ninguna imagen recibe luces 2D ni el CanvasModulate: la luz de la hora azul ya va pintada (unshaded). Con el
# ambiente de la ciudad, el suelo de casillas y los personajes sí se tiñen (ver AMBIENTE).
#
# COLISIONES: los edificios no traen choque; los da la rejilla de muros de la ciudad (LUGARES con «pisable»: false).
# Las piezas que hay que rodear dentro de una zona pisable (fuente, puestos, barriles) traen un StaticBody2D propio.
#
# VECINOS: muneco_de(id, imagen_de_siempre) da el muñeco 2D propio de la posadera, Bastián, Doña Encina y Albar
# (MUNECOS). Esos ya llevan su ropa: NO se les aplica el «tinte» de ciudades/oakhaven.gd (solo a los de siempre).
#
# LUZ DE LA CIUDAD: AMBIENTE (el CanvasModulate) y LUZ_JUGADOR (la luz de Kael) para que el suelo y los personajes
# casen con el arte; las farolas, mejor las «farol» de aquí (halo y charco de luz pintados) que las de zona.gd, que
# llevan una PointLight2D cada una (luces reales: solo en el perfil alto, guía visual).
#
# COSTE (estimado, sin medir: ver docs/memory/agents/graficos.md): cada pieza son 5-22 nodos (el Concejo, con sus
# columnas, el que más); ninguna luz 2D; partículas, solo las luciérnagas del árbol (14). Texturas sin comprimir en la
# GPU (RGBA8); las calcomanías del suelo, a 1/4 de resolución, y las raíces del árbol, a 1/2.

const Arte := preload("res://ciudades/oakhaven_arte/arte_datos.gd")
const Pieza := preload("res://ciudades/oakhaven_arte/pieza.gd")
const CARPETA := "res://ciudades/oakhaven_arte/"
const T_ARTE := 64

# Ambiente recomendado para la ciudad (el CanvasModulate de zona.gd, estilo «ciudad»): tiñe el suelo de casillas y
# a los personajes para que casen con el arte horneado a la hora azul. El de hoy es (0.62, 0.58, 0.74).
const AMBIENTE := Color(0.5, 0.52, 0.74)
# Y la luz que lleva Kael (luz_jugador de zona.gd: energía 0,8 y escala 3,2 en la ciudad) es de pleno día para la
# hora azul: alumbra 400 px a la redonda. Recomendada en Oakhaven: un farol de mano, pequeño y tenue.
const LUZ_JUGADOR := {"energia": 0.32, "escala": 1.9}

# Relleno de casas que PROPONE gráficos para que la ciudad no quede vacía entre los lugares de canon (lo usa la maqueta;
# la ciudad de verdad decide el suyo). Ninguna casa pisa ni TAPA (con su tejado) un lugar pisable, un PNJ, una nota,
# una pieza ni un cofre de ciudades/oakhaven.gd (lo comprueba prueba_oakhaven_arte). Cada casa es un muro.
const RELLENO := [
	# En 3/4, una casa tapa lo que queda al norte de su huella hasta la altura de su tejado (unas 7 casillas): por
	# eso hay casas al NORTE de las calles y de la plaza (fachada a la calle) y, al sur, jardines y huertos.
	# al norte de la Calle del Cuervo y la fila de detrás
	{"id": "casa_5x5", "rect": Rect2i(1, 20, 5, 5)}, {"id": "casa_5x4", "rect": Rect2i(6, 21, 5, 4)},
	{"id": "casa_6x4", "rect": Rect2i(21, 21, 6, 4)}, {"id": "casa_3x4", "rect": Rect2i(27, 21, 3, 4)},
	{"id": "casa_4x4", "rect": Rect2i(31, 21, 4, 4)},
	{"id": "casa_6x5", "rect": Rect2i(1, 14, 6, 5)}, {"id": "casa_4x4", "rect": Rect2i(7, 15, 4, 4)},
	{"id": "casa_5x4", "rect": Rect2i(11, 15, 5, 4)}, {"id": "casa_3x4", "rect": Rect2i(16, 15, 3, 4)},
	{"id": "casa_6x4", "rect": Rect2i(19, 15, 6, 4)}, {"id": "casa_5x5", "rect": Rect2i(25, 14, 5, 5)},
	{"id": "casa_4x4", "rect": Rect2i(15, 9, 4, 4)}, {"id": "casa_6x5", "rect": Rect2i(20, 8, 6, 5)},
	{"id": "casa_3x4", "rect": Rect2i(26, 9, 3, 4)},
	# al este del Concejo y al norte de la Calle del Mercado
	{"id": "casa_4x4", "rect": Rect2i(52, 17, 4, 4)}, {"id": "casa_5x4", "rect": Rect2i(52, 21, 5, 4)},
	{"id": "casa_4x5", "rect": Rect2i(70, 20, 4, 5)}, {"id": "casa_4x4", "rect": Rect2i(74, 21, 4, 4)},
	# al suroeste, lejos de la calle, del patio del Cuervo y del Patio de las Velas
	{"id": "casa_5x4", "rect": Rect2i(1, 28, 5, 4)}, {"id": "casa_5x5", "rect": Rect2i(1, 34, 5, 5)},
	{"id": "casa_5x4", "rect": Rect2i(10, 39, 5, 4)}, {"id": "casa_4x5", "rect": Rect2i(15, 41, 4, 5)},
	{"id": "casa_5x4", "rect": Rect2i(20, 48, 5, 4)}, {"id": "casa_6x4", "rect": Rect2i(26, 48, 6, 4)},
	# al este de la Calle Mayor y al sur del mercado, a 8 casillas de la plaza y de los puestos
	{"id": "casa_4x5", "rect": Rect2i(42, 40, 4, 5)}, {"id": "casa_5x4", "rect": Rect2i(50, 40, 5, 4)},
	{"id": "casa_6x4", "rect": Rect2i(56, 40, 6, 4)}, {"id": "casa_4x4", "rect": Rect2i(63, 40, 4, 4)},
	{"id": "casa_6x5", "rect": Rect2i(50, 46, 6, 5)}, {"id": "casa_5x4", "rect": Rect2i(57, 47, 5, 4)},
	{"id": "casa_6x4", "rect": Rect2i(62, 47, 6, 4)},
	# farolas (un farol cada 5 casillas en la Calle Mayor, como pide el diseño) y ropa tendida
	{"id": "farol", "rect": Rect2i(38, 33, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(41, 38, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(38, 43, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(41, 50, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(35, 21, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(45, 30, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(35, 30, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(7, 27, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(28, 27, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(61, 27, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(71, 27, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(67, 33, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(67, 39, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(41, 17, 1, 1), "suelto": true},
	{"id": "farol", "rect": Rect2i(33, 11, 1, 1), "suelto": true}, {"id": "farol", "rect": Rect2i(46, 11, 1, 1), "suelto": true},
	{"id": "ropa_tendida", "rect": Rect2i(22, 32, 3, 1), "suelto": true},
	{"id": "ropa_tendida", "rect": Rect2i(11, 27, 3, 1), "suelto": true},
]

# Muñecos del mundo 2D propios de los vecinos nuevos: los de personajes/npc/ con otra ropa (cada color por zonas de
# tono, la piel y el pelo conservados; ver oakhaven_arte/fuente/munecos.py). Ya llevan su color: NO se tiñen.
# Si un vecino no está aquí, el de siempre (con su «tinte»).
const MUNECOS := {
	"posadera": "res://ciudades/oakhaven_arte/munecos/posadera.png",   # aldeana: vestido vino, panecillos en la cesta
	"bastian": "res://ciudades/oakhaven_arte/munecos/bastian.png",     # pícaro: azul y pardo (a 0,8: es un niño)
	"encina": "res://ciudades/oakhaven_arte/munecos/encina.png",       # maga: verde musgo y bronce, pelo blanco
	"albar": "res://ciudades/oakhaven_arte/munecos/albar.png",         # caballero: gris ceniza y plata, pelo plateado
}

static var _mats := {}
static var _blanco: Texture2D


# El muñeco del mundo 2D para un vecino de Oakhaven: el propio si lo hay; si no, la imagen de siempre (con su tinte).
static func muneco_de(id_vecino: String, por_defecto: String) -> String:
	return MUNECOS.get(id_vecino, por_defecto)


static func ids() -> Array:
	return Arte.PIEZAS.keys()


static func tiene(id: String) -> bool:
	return Arte.PIEZAS.has(id)


# La huella (casillas) para la que se dibujó la pieza; Rect2i() si no hay arte.
static func rect_de(id: String) -> Rect2i:
	return Arte.PIEZAS[id]["rect"] if Arte.PIEZAS.has(id) else Rect2i()


static func crear_pieza(id: String, rect_casillas: Rect2i, tam_casilla: int) -> Node2D:
	if not Arte.PIEZAS.has(id) or tam_casilla <= 0:
		return null
	var d: Dictionary = Arte.PIEZAS[id]
	var diseno: Rect2i = d["rect"]
	if rect_casillas.size == Vector2i.ZERO:
		rect_casillas = diseno
	elif rect_casillas.size != diseno.size:
		push_warning("Oakhaven: la pieza «%s» se dibujó para %s y se pone en %s (centrada abajo)" % [id, diseno, rect_casillas])
	var raiz: Node2D = Pieza.new()
	raiz.name = "pieza_" + id
	raiz.id = id
	raiz.y_sort_enabled = true
	var esc := float(tam_casilla) / T_ARTE
	raiz.scale = Vector2(esc, esc)
	var desfase := Vector2(rect_casillas.position.x + rect_casillas.size.x * 0.5 - diseno.position.x - diseno.size.x * 0.5,
		rect_casillas.end.y - diseno.end.y)
	raiz.position = (Vector2(diseno.position) + desfase) * tam_casilla
	var base := Vector2(diseno.position) * T_ARTE
	raiz.huella = Rect2(Vector2.ZERO, Vector2(diseno.size) * T_ARTE)
	var orden_cuerpo := float(diseno.end.y * T_ARTE) - base.y
	var px := 0
	for s in d["sprites"]:
		var n := _sprite(s, base)
		raiz.add_child(n)
		px += int(s["tam"].x * s["tam"].y / pow(float(s.get("escala", 1)), 2.0))
		if s.get("tipo", "") == "edificio" and s["capa"] == "cuerpo":
			orden_cuerpo = s["orden"] - base.y
		_registrar_estado(raiz, n, s)
	if d.has("suelo"):
		raiz.add_child(_suelo(d["suelo"], base))
		var e := float(d["suelo"].get("escala", 1))
		px += int(d["suelo"]["tam"].x * d["suelo"]["tam"].y / (e * e))
	for k in d["anclas"]:
		raiz.anclas[k] = d["anclas"][k] - base
	for e in d.get("efectos", []):
		var n := _efecto(e, raiz.anclas, orden_cuerpo)
		if n != null:
			raiz.add_child(n)
			_registrar_estado(raiz, n, e)
	for c in d.get("choques", []):
		raiz.add_child(_choque(c, base))
	raiz.coste = {"nodos": _contar(raiz), "texturas_px": px}
	return raiz


# ================================================================= montaje

static func _sprite(s: Dictionary, base: Vector2) -> Node2D:
	var tex: Texture2D = load(CARPETA + s["tex"])
	var orden := Vector2(s["pos"].x, s["orden"]) - base
	if s.get("tipo", "") == "letrero":
		var nodo := Node2D.new()
		nodo.name = s["capa"]
		nodo.position = Vector2(s["pivote"].x - base.x, orden.y)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.position = s["pivote"] - base - nodo.position
		sp.offset = s["pos"] - s["pivote"]
		sp.material = _material("vaiven")
		nodo.add_child(sp)
		return nodo
	var sp := Sprite2D.new()
	sp.name = s["capa"]
	sp.texture = tex
	sp.centered = false
	sp.position = orden
	var esc := float(s.get("escala", 1))              # capas suaves guardadas a menor resolución (las raíces)
	sp.scale = Vector2(esc, esc)
	sp.offset = (s["pos"] - base - orden) / esc
	sp.material = _material("edificio" if s.get("tipo", "") == "edificio" else "objeto")
	if s.get("viento", 0.0) > 0.0:
		sp.material = _material("copa")
	return sp


static func _suelo(s: Dictionary, base: Vector2) -> Node2D:
	var sp := Sprite2D.new()
	sp.name = "suelo"
	sp.texture = load(CARPETA + s["tex"])
	sp.centered = false
	sp.position = s["pos"] - base          # ordena con su borde de arriba: debajo de quien lo pisa
	sp.scale = Vector2.ONE * float(s.get("escala", 1))   # guardada a media resolución (todo en ella es suave)
	sp.material = _material("suelo")
	return sp


# Efectos en vivo, baratos: humo (una imagen con sombreado), halos (un círculo que suma luz), luciérnagas.
static func _efecto(e: Dictionary, anclas: Dictionary, orden_cuerpo: float) -> Node2D:
	if not anclas.has(e.get("ancla", "")):
		return null
	var a: Vector2 = anclas[e["ancla"]]
	var orden := orden_cuerpo + float(e.get("delante", 2.0))
	var envoltura := Node2D.new()
	envoltura.name = "%s_%s" % [e["tipo"], e["ancla"]]
	envoltura.position = Vector2(a.x, orden)
	match e["tipo"]:
		"humo":
			var alto := float(e.get("alto", 3.0)) * T_ARTE
			var ancho := alto * 0.55 * float(e.get("escala", 1.0)) + 30.0
			var sp := _quad(Vector2(ancho, alto))
			sp.position = a - Vector2(ancho * 0.5, alto) - envoltura.position
			sp.material = _material("humo_frio" if e.get("color", "") == "frio" else "humo_calido")
			envoltura.add_child(sp)
		"halo", "brillo":
			var r := float(e.get("radio", 1.0)) * T_ARTE
			var sp := _quad(Vector2(r, r) * 2.0)
			sp.position = a - Vector2(r, r) - envoltura.position
			var clave := "halo_%s_%s_%s" % [e.get("color", "farol"), e.get("fuerza", 0.5), e.get("parpadeo", 1.0)]
			if not _mats.has(clave):
				var m := ShaderMaterial.new()
				m.shader = load(CARPETA + "halo.gdshader")
				var col: Color = {"farol": Color(1.0, 0.72, 0.38), "ventana": Color(1.0, 0.62, 0.3),
					"vela": Color(1.0, 0.66, 0.32), "frio": Color(0.62, 0.72, 1.0),
					"oro": Color(1.0, 0.85, 0.45)}.get(e.get("color", "farol"), Color(1.0, 0.72, 0.38))
				m.set_shader_parameter("color", col)
				m.set_shader_parameter("fuerza", float(e.get("fuerza", 0.5)))
				m.set_shader_parameter("parpadeo", float(e.get("parpadeo", 1.0)))
				_mats[clave] = m
			sp.material = _mats[clave]
			envoltura.add_child(sp)
		"luciernagas":
			var p := CPUParticles2D.new()
			p.amount = int(e.get("cantidad", 12))
			p.lifetime = 5.0
			p.preprocess = 5.0
			p.local_coords = false
			p.texture = _punto()
			p.material = _material("halo_add")
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			var caja: Vector2 = Vector2(e.get("caja", Vector2(4, 2))) * T_ARTE * 0.5
			p.emission_rect_extents = caja
			p.gravity = Vector2(0, -4)
			p.direction = Vector2(0, -1)
			p.spread = 180.0
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 14.0
			p.scale_amount_min = 0.5
			p.scale_amount_max = 1.0
			var g := Gradient.new()
			g.offsets = PackedFloat32Array([0.0, 0.15, 0.5, 0.85, 1.0])
			g.colors = PackedColorArray([Color(0.91, 0.96, 0.6, 0.0), Color(0.91, 0.96, 0.6, 0.9), Color(0.91, 0.96, 0.6, 0.2),
				Color(0.91, 0.96, 0.6, 0.95), Color(0.91, 0.96, 0.6, 0.0)])
			p.color_ramp = g
			p.position = a - envoltura.position
			envoltura.add_child(p)
		_:
			return null
	return envoltura


static func _choque(c: Dictionary, base: Vector2) -> Node2D:
	var cuerpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(c["tam"]) * T_ARTE
	forma.shape = r
	cuerpo.add_child(forma)
	cuerpo.position = Vector2(c["centro"]) * T_ARTE - base
	return cuerpo


static func _registrar_estado(raiz: Node, n: Node, d: Dictionary) -> void:
	for clave in ["estado", "estado_no"]:
		if d.has(clave):
			var e: String = d[clave]
			if not raiz.estados.has(e):
				raiz.estados[e] = {"si": [], "no": []}
			raiz.estados[e]["si" if clave == "estado" else "no"].append(n)
			n.visible = clave == "estado_no"      # de partida, el estado está apagado


static func _contar(n: Node) -> int:
	var k := 1
	for c in n.get_children():
		k += _contar(c)
	return k


static func _quad(tam: Vector2) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = _textura_blanca()
	sp.centered = false
	sp.scale = tam / 4.0
	return sp


static func _textura_blanca() -> Texture2D:
	if _blanco == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_blanco = ImageTexture.create_from_image(img)
	return _blanco


static func _punto() -> Texture2D:
	var clave := "_punto"
	if not _mats.has(clave):
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 16
		t.height = 16
		_mats[clave] = t
	return _mats[clave]


static func _material(tipo: String) -> Material:
	if _mats.has(tipo):
		return _mats[tipo]
	var m: Material
	match tipo:
		"edificio", "copa":
			var sm := ShaderMaterial.new()
			sm.shader = load(CARPETA + "edificio.gdshader")
			if tipo == "copa":
				sm.set_shader_parameter("viento", 6.0)
			m = sm
		"vaiven":
			var sm := ShaderMaterial.new()
			sm.shader = load(CARPETA + "vaiven.gdshader")
			m = sm
		"humo_calido", "humo_frio":
			var sm := ShaderMaterial.new()
			sm.shader = load(CARPETA + "humo.gdshader")
			sm.set_shader_parameter("ruido", load(CARPETA + "ruido.png"))
			if tipo == "humo_frio":                                  # el crematorio: blanco frío (#C9D3E0)
				sm.set_shader_parameter("color", Color(0.79, 0.83, 0.88, 0.62))
				sm.set_shader_parameter("velocidad", 0.035)
			m = sm
		"suelo":
			var cm := CanvasItemMaterial.new()
			cm.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
			cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			m = cm
		"halo_add":
			var cm := CanvasItemMaterial.new()
			cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			m = cm
		_:
			var cm := CanvasItemMaterial.new()
			cm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			m = cm
	_mats[tipo] = m
	return m
