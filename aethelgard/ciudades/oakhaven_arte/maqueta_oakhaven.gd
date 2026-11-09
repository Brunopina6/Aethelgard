extends "res://zona.gd"
# Maqueta de Oakhaven con el arte nuevo (T-089, gráficos). SOLO para ver y comparar el arte dentro del juego: el
# suelo de casillas, la luz, la interfaz y Kael son los de zona.gd, como en la ciudad de verdad. No es la ciudad
# (esa es ciudad_oakhaven.gd, de narrativa): no tiene diálogos, misiones, cofres ni guardado propio.
#   - Trazado: ciudades/oakhaven.gd (LUGARES pisables = empedrado; no pisables = muro) y el borde con la Puerta del
#     Sur abierta, como pide narrativa.
#   - Arte: cada pieza de oakhaven_piezas.gd en su huella, y el relleno de casas que propone gráficos (RELLENO).
#   - Ambiente: Piezas.AMBIENTE (la hora azul del suelo y de los personajes).
# Se abre con pruebas/prueba_oakhaven_arte_fotos.gd (o en el editor). No toca la partida: zona.gd guarda al entrar,
# así que se abre SIEMPRE con datos aislados.

const Oak := preload("res://ciudades/oakhaven.gd")
const Piezas := preload("res://ciudades/oakhaven_piezas.gd")

var piezas_puestas: Array = []          # [id, nodo]

# Jardines y huertos al sur de las calles (donde una casa taparía la calle con su tejado), con la vegetación que ya
# tiene el juego (decorado de zona.gd: cerezos, árboles de Quaternius, arbustos y flores). Los árboles, a 4 casillas
# o más de cualquier sitio pisable que tengan al norte; los arbustos y las flores, donde sea.
const JARDINES := [
	["cerezo", 7.5, 33.0], ["q_arbol", 13.0, 34.5], ["cerezo", 17.5, 34.0], ["q_arbol", 29.0, 33.5], ["cerezo", 32.0, 35.0],
	["q_otono", 8.0, 37.0], ["q_arbusto_flor", 16.5, 30.5], ["q_arbusto_flor", 20.0, 30.0], ["q_flores", 27.0, 30.0],
	["q_arbusto_flor", 31.0, 29.5], ["q_flores_amarillas", 6.5, 29.5],
	["cerezo", 44.0, 36.5], ["q_arbol", 47.0, 37.5], ["q_arbusto_flor", 43.0, 32.5], ["q_flores", 46.5, 33.0],
	["q_arbol", 52.0, 37.0], ["cerezo", 58.0, 36.5], ["q_arbol", 64.0, 37.0], ["q_arbusto", 55.0, 34.0],
	["q_arbusto_flor", 61.0, 34.5], ["q_arbol", 72.0, 32.0], ["cerezo", 74.5, 35.0], ["q_arbusto_flor", 71.5, 29.0],
	["q_arbol", 4.0, 42.0], ["cerezo", 7.0, 46.0], ["q_arbol", 12.0, 47.5], ["q_otono", 2.5, 50.0], ["cerezo", 31.0, 44.0],
	["q_arbol", 36.0, 48.0], ["q_pino", 58.0, 6.0], ["q_pino", 74.0, 6.5], ["q_pino", 57.5, 17.5],
	["q_arbol", 3.0, 4.0], ["cerezo", 8.0, 3.5], ["q_arbol", 12.0, 6.0], ["q_otono", 27.0, 4.0], ["q_arbol", 53.5, 5.0],
	["cerezo", 54.0, 12.0],
]


func _leer_lugar() -> void:
	super._leer_lugar()
	lugar = {"indice": Oak.INDICE, "nombre": "Oakhaven", "tipo": "ciudad", "zona": "llanura", "texto": Oak.TEXTO_ARBOL}
	nombre_estilo = "ciudad"
	estilo = ESTILOS["ciudad"].duplicate()
	estilo["ambiente"] = Piezas.AMBIENTE
	estilo["hierba_alta"] = 0.0
	estilo["objetos"] = {}
	es_ciudad = true
	semilla = 1000 + Oak.INDICE * 7919


func _generar_disposicion() -> void:
	plaza = Oak.PLAZA
	meta = Oak.ARBOL
	salida_x = Oak.SALIDA_X
	ancho_camino = 1.0
	var vw := ANCHO + 1
	camino_v.resize(vw * (ALTO + 1))
	agua_v.resize(vw * (ALTO + 1))
	camino_v.fill(0)
	agua_v.fill(0)
	for d in Oak.LUGARES:
		if not d["pisable"]:
			continue
		var r: Rect2 = d["rect"]
		for vy in range(int(r.position.y), int(r.end.y) + 1):
			for vx in range(int(r.position.x), int(r.end.x) + 1):
				if vx >= 0 and vx <= ANCHO and vy >= 0 and vy <= ALTO:
					camino_v[vy * vw + vx] = 1
	muros.resize(ANCHO * ALTO)
	muros.fill(0)
	for y in ALTO:
		for x in ANCHO:
			var borde := x == 0 or y == 0 or x == ANCHO - 1 or y == ALTO - 1
			if borde and not (y == ALTO - 1 and x >= 37 and x < 44):
				muros[y * ANCHO + x] = 1
	var solidos: Array = []
	for d in Oak.LUGARES:
		if not d["pisable"]:
			solidos.append(Rect2i(d["rect"]))
	for c in Piezas.RELLENO:
		if not c.get("suelto", false):
			solidos.append(c["rect"])
	solidos += [Rect2i(20, 35, 3, 1), Rect2i(24, 35, 3, 1)]     # el muro de la grieta, a los lados del paso
	for r in solidos:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if x >= 0 and x < ANCHO and y >= 0 and y < ALTO:
					muros[y * ANCHO + x] = 2
	colocados.clear()
	for j in JARDINES:
		colocados.append({"tipo": j[0], "pos": Vector2(j[1], j[2]) * T})


func _crear_objetos() -> void:
	super._crear_objetos()
	altar.visible = false                         # el Árbol Milenario hace de «meta»
	for id in Piezas.ids():
		if id.begins_with("casa_") or id in ["farol", "ropa_tendida"]:     # sueltas: van con el relleno
			continue
		var n := Piezas.crear_pieza(id, Piezas.rect_de(id), T)
		if n != null:
			mundo_y.add_child(n)
			piezas_puestas.append([id, n])
	for c in Piezas.RELLENO:
		var n := Piezas.crear_pieza(c["id"], c["rect"], T)
		if n != null:
			mundo_y.add_child(n)
			piezas_puestas.append([c["id"], n])


func _crear_iluminacion() -> void:
	super._crear_iluminacion()
	if luz_jugador != null:                       # la luz de Kael, la de un farol de mano a la hora azul
		luz_jugador.energy = Piezas.LUZ_JUGADOR["energia"]
		luz_jugador.texture_scale = Piezas.LUZ_JUGADOR["escala"]


func _sitio_detalle(donde: String) -> Vector2:
	for d in load("res://progreso.gd").detalles_de(Oak.INDICE):
		if d["donde"] == donde and Oak.SITIOS_DETALLE.has(d["id"]):
			return Oak.SITIOS_DETALLE[d["id"]]
	return super._sitio_detalle(donde)


func _poner_npcs() -> void:
	for d in Oak.NPCS:
		var ruta: String = Piezas.muneco_de(d["id"], d["imagen"])
		if not ResourceLoader.exists(ruta):
			continue
		var tex: Texture2D = load(ruta)
		var p: Vector2 = d["casilla"] * T
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		var esc := 0.5 * float(d.get("escala", 1.0))
		s.scale = Vector2.ONE * esc
		s.position = p
		if ruta == d["imagen"] and d.has("tinte"):         # sin muñeco propio: el de siempre teñido (como narrativa)
			s.modulate = d["tinte"]
		mundo_y.add_child(s)
		var sombra := Sprite2D.new()
		sombra.texture = sombra_tex
		sombra.position = p + Vector2(0, 2)
		sombra.scale = Vector2(60, 20) / 128.0
		sombras.add_child(sombra)
		npcs.append([s, {"nombre": d["nombre"], "frases": d["frases"]}, 0])
