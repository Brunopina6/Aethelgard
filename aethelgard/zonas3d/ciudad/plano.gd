extends RefCounted
# CIUDAD COMPLETA de Oakhaven (V12, 16/11, M0; EXPERIMENTAL y APAGADA: solo desde el banco de pruebas de Auditoría):
# EL PLANO, como datos estáticos. Es el ACUERDO entre los agentes de maqueta: qué caja es de cada sector, a qué cota
# está y por dónde se pasa de uno a otro (CONEXIONES, con su ancho y su cota exactos). Lo que hay DENTRO de cada sector
# lo dice su trazado (zonas3d/ciudad/sectores/<id>/trazado.gd, mismo contrato que el del barrio). Plan aprobado como
# propuesta: docs/v12/CIUDAD_OAKHAVEN_PLAN.md; lo hecho y cómo se trabaja: docs/v12/CIUDAD_OAKHAVEN.md.
# Todo es PROPUESTA [P] salvo lo marcado [C] (canon citado en el plan §0).
#
# Ejes: x al este, z al SUR, y arriba, en metros. Origen: el centro de la fuente de la Plaza del Tapiz. La ciudad sube
# hacia el norte (la Puerta del Sur a cota 0, el Árbol Milenario a 16): la cámara, al sur y sin girar, mira cuesta arriba.
#
# REGLAS DEL ACUERDO (las comprueba pruebas/prueba_ciudad_plano.gd):
#   1. Las cajas de SECTORES no se pisan (Rect2 semiabiertos) y cada SUELO de un sector cae DENTRO de su caja.
#   2. Ningún bloque sólido de un sector cae sobre lo andable de otro.
#   3. En cada CONEXION, a los dos lados del borde y en todo su ancho, el suelo está a la COTA acordada y LLANO al menos
#      LLANO_BORDE metros hacia dentro de cada sector: cada agente remata su lado sin mirar el del otro.
#   4. Entre casillas vecinas de 0,25 m no hay saltos de más de SALTO_MAX (tampoco dentro de un sector): las escaleras son
#      rampas continuas (como el atajo del barrio) y los niveles distintos se separan con muro, pretil o vacío.
#   5. Todo lo andable de la ciudad se alcanza desde la Puerta del Sur.
#   6. Kael se ve desde la cámara en lo andable: lo que tape el rayo a su cabeza ha de ser «ocultable» (la escena lo
#      aclara): las cubiertas y copas siempre; las casas, si su trazado las pone en OCULTABLES.

const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")

const LLANO_BORDE := 1.0
const SALTO_MAX := 0.3
const ANCHO_CALLE := 2.5                   # mínimo de una calle (plan §2)
const ANCHO_PASAJE := 1.6                  # mínimo de un pasaje

# ---------------------------------------------------------------------------------------------------- sectores
# caja: Rect2 (x, z, ancho, fondo); cota: Vector2(mínima, máxima) de lo que se pisa; vecinos: los de CONEXIONES; ref: el
# ancla global de su punto de referencia (plan §2); agente: quién lo maqueta (plan §6).
# (M0) Las cajas del plan se ajustaron para que NO se solapen (en el plan, la 1 y la 5 compartían x −45..5): la 5 queda al
# suroeste entera (x −100..−30) y la 1 entre la 5 y la 8; la Calle Mayor baja dentro de la 2 hasta z 62; la 3 llega a
# z −15 para tocar a la 7 (Subida de la Colina). La Colina del Crematorio (x 60..105, z −92..−15; COLINA) no es un
# sector andable: la dibuja el trazado de la 3, que es quien sube a su pie.
const SECTORES := {
	"puerta_sur": {"n": 1, "nombre": "Puerta del Sur y Caravanas", "caja": Rect2(-30.0, 62.0, 75.0, 33.0),
		"cota": Vector2(0.0, 1.0), "vecinos": ["plaza_tapiz", "ribera", "pasajes"], "ref": "ref_puerta_sur", "agente": "A"},
	"plaza_tapiz": {"n": 2, "nombre": "Plaza del Tapiz y Gran Mercado", "caja": Rect2(-30.0, -15.0, 75.0, 77.0),
		"cota": Vector2(0.0, 4.0), "vecinos": ["puerta_sur", "barrio_alto", "cuervo", "oficios", "pasajes"],
		"ref": "ref_plaza_tapiz", "agente": "A"},
	"oficios": {"n": 3, "nombre": "Calle de los Oficios", "caja": Rect2(45.0, -15.0, 60.0, 70.0),
		"cota": Vector2(3.0, 10.0), "vecinos": ["plaza_tapiz", "barrio_alto", "ribera"], "ref": "ref_oficios", "agente": "B"},
	"terrazas": {"n": 4, "nombre": "Las Terrazas", "caja": Rect2(-100.0, -92.0, 70.0, 87.0),
		"cota": Vector2(3.0, 12.0), "vecinos": ["cuervo", "barrio_alto"], "ref": "ref_terrazas", "agente": "D"},
	"pasajes": {"n": 5, "nombre": "Pasajes Viejos", "caja": Rect2(-100.0, 50.0, 70.0, 45.0),
		"cota": Vector2(1.0, 2.0), "vecinos": ["plaza_tapiz", "cuervo", "puerta_sur"], "ref": "ref_pasajes", "agente": "C"},
	"cuervo": {"n": 6, "nombre": "Patio del Cuervo", "caja": Rect2(-100.0, -5.0, 70.0, 55.0),
		"cota": Vector2(2.0, 3.0), "vecinos": ["plaza_tapiz", "terrazas", "pasajes"], "ref": "ref_cuervo", "agente": "C"},
	"barrio_alto": {"n": 7, "nombre": "Barrio Alto de las Raíces", "caja": Rect2(-30.0, -92.0, 90.0, 77.0),
		"cota": Vector2(4.0, 16.0), "vecinos": ["plaza_tapiz", "terrazas", "oficios"], "ref": "ref_barrio_alto", "agente": "D"},
	"ribera": {"n": 8, "nombre": "La Ribera Baja", "caja": Rect2(45.0, 55.0, 65.0, 40.0),
		"cota": Vector2(-2.0, 3.0), "vecinos": ["puerta_sur", "oficios"], "ref": "ref_ribera", "agente": "B"},
}
const ORDEN := ["puerta_sur", "plaza_tapiz", "oficios", "terrazas", "pasajes", "cuervo", "barrio_alto", "ribera"]
const CAJA_CIUDAD := Rect2(-100.0, -92.0, 210.0, 187.0)
const COLINA := Rect2(60.0, -92.0, 45.0, 77.0)          # Colina del Crematorio [C]: solo por fuera; la dibuja «oficios»

# Los trazados de cada sector (mismo contrato que el del barrio).
const TRAZADOS := {
	"puerta_sur": preload("res://zonas3d/ciudad/sectores/puerta_sur/trazado.gd"),
	"plaza_tapiz": preload("res://zonas3d/ciudad/sectores/plaza_tapiz/trazado.gd"),
	"oficios": preload("res://zonas3d/ciudad/sectores/oficios/trazado.gd"),
	"terrazas": preload("res://zonas3d/ciudad/sectores/terrazas/trazado.gd"),
	"pasajes": preload("res://zonas3d/ciudad/sectores/pasajes/trazado.gd"),
	"cuervo": preload("res://zonas3d/ciudad/sectores/cuervo/trazado.gd"),
	"barrio_alto": preload("res://zonas3d/ciudad/sectores/barrio_alto/trazado.gd"),
	"ribera": preload("res://zonas3d/ciudad/sectores/ribera/trazado.gd"),
}

# ---------------------------------------------------------------------------------------------------- conexiones
# EL ACUERDO DE BORDES. Cada conexión es un tramo de borde entre dos sectores: borde "x" (la línea x = «en», recorrida en
# z de «desde» a «hasta») o "z" (la línea z = «en», recorrida en x). ancho = hasta − desde. cota: la del suelo a los dos
# lados, llano LLANO_BORDE hacia dentro. tipo: calle (≥ 2,5 m) o pasaje (≥ 1,6 m). Nombres [C] del plan o [P].
const CONEXIONES := [
	{"id": "calle_mayor", "nombre": "Calle Mayor [C]", "a": "puerta_sur", "b": "plaza_tapiz", "borde": "z", "en": 62.0,
		"desde": -4.0, "hasta": 4.0, "cota": 0.0, "tipo": "calle"},
	{"id": "calle_arbol", "nombre": "Calle del Árbol [P]", "a": "plaza_tapiz", "b": "barrio_alto", "borde": "z", "en": -15.0,
		"desde": -5.0, "hasta": 5.0, "cota": 4.0, "tipo": "calle"},
	{"id": "calle_cuervo", "nombre": "Calle del Cuervo [C]", "a": "plaza_tapiz", "b": "cuervo", "borde": "x", "en": -30.0,
		"desde": 20.0, "hasta": 26.0, "cota": 2.0, "tipo": "calle"},
	{"id": "calle_mercado", "nombre": "Calle del Mercado [C]", "a": "plaza_tapiz", "b": "oficios", "borde": "x", "en": 45.0,
		"desde": 20.0, "hasta": 26.0, "cota": 3.0, "tipo": "calle"},
	{"id": "escaleras_terrazas", "nombre": "Escaleras de las Terrazas [P]", "a": "cuervo", "b": "terrazas", "borde": "z",
		"en": -5.0, "desde": -62.0, "hasta": -58.0, "cota": 3.0, "tipo": "calle"},
	{"id": "terrazas_altas", "nombre": "Escaleras de las Terrazas, arriba [P]", "a": "terrazas", "b": "barrio_alto",
		"borde": "x", "en": -30.0, "desde": -64.0, "hasta": -60.0, "cota": 12.0, "tipo": "calle"},
	{"id": "paso_botica", "nombre": "Paso Cubierto de la Botica [P]", "a": "pasajes", "b": "plaza_tapiz", "borde": "x",
		"en": -30.0, "desde": 54.0, "hasta": 57.0, "cota": 2.0, "tipo": "pasaje"},
	{"id": "subida_colina", "nombre": "Subida de la Colina [C]", "a": "oficios", "b": "barrio_alto", "borde": "z", "en": -15.0,
		"desde": 50.0, "hasta": 54.0, "cota": 10.0, "tipo": "calle"},
	{"id": "rampa_carros", "nombre": "Rampa de los Carros [P]", "a": "puerta_sur", "b": "ribera", "borde": "x", "en": 45.0,
		"desde": 76.0, "hasta": 82.0, "cota": 0.0, "tipo": "calle"},
	{"id": "pasaje_velas", "nombre": "Pasaje del Corro [P]", "a": "cuervo", "b": "pasajes", "borde": "z", "en": 50.0,
		"desde": -70.0, "hasta": -68.0, "cota": 2.0, "tipo": "pasaje"},
	{"id": "arco_pasajes", "nombre": "Arco de los Pasajes [P]", "a": "pasajes", "b": "puerta_sur", "borde": "x", "en": -30.0,
		"desde": 80.0, "hasta": 83.0, "cota": 1.0, "tipo": "calle"},
	{"id": "escalera_molino", "nombre": "Escalera del Molino [P]", "a": "oficios", "b": "ribera", "borde": "z", "en": 55.0,
		"desde": 60.0, "hasta": 63.0, "cota": 3.0, "tipo": "calle"},
]

# ---------------------------------------------------------------------------------------------------- anclas globales
# Puntos EN el suelo (la «y» = altura(); la escrita es para leerla). Referencias de cada sector, la entrada, y los lugares
# RESERVADOS del plan §3 (sitio previsto; los sistemas no se implementan en esta fase). Las entradas previstas de los
# edificios son las PUERTAS de cada trazado (puertas()).
const INICIO := Vector3(0.0, 0.0, 86.0)
const ANCLAS := {
	"inicio": Vector3(0.0, 0.0, 86.0),                      # al entrar desde el banco: el patio de caravanas, mirando al norte
	"puerta_sur": Vector3(0.0, 0.0, 91.5),                  # ante la Puerta del Sur [C] (la única salida al mapa)
	"ref_puerta_sur": Vector3(0.0, 0.0, 91.5),
	"ref_plaza_tapiz": Vector3(0.0, 4.0, -4.6),             # ante la fuente de la Plaza del Tapiz [C] (lado norte)
	"ref_oficios": Vector3(68.0, 4.8, 21.4),                # ante la forja de Maese Ferro [C pendiente]
	"ref_terrazas": Vector3(-60.0, 12.0, -64.0),            # el lavadero de la terraza alta [P]
	"ref_pasajes": Vector3(-56.0, 1.44, 70.0),              # el Patio de las Velas [C]
	"ref_cuervo": Vector3(-78.0, 3.0, 6.4),                 # ante la Taberna del Cuervo Oxidado [C]
	"ref_barrio_alto": Vector3(0.0, 16.0, -83.0),           # al pie del Árbol Milenario [C]
	"ref_ribera": Vector3(96.0, -2.0, 72.0),                # bajo la Torre de la Campana [C]
	"reserva_rastreadores_caravanas": Vector3(25.0, 0.0, 85.0),   # [P] señales en las lonas del patio de caravanas
	"reserva_rastreadores_almacen": Vector3(92.0, -2.0, 86.0),    # [P] el fondo del almacén de la Ribera Baja
	"reserva_piezas_patio": Vector3(-80.0, 10.0, -50.0),          # [P] un patio de las Terrazas (la Pieza Huérfana)
	"reserva_piezas_taller": Vector3(55.0, 3.5, 21.4),            # [P] los talleres de la Calle de los Oficios
	"reserva_feria_plaza": Vector3(-8.0, 2.0, 18.0),              # [P] Feria de los Oficios: puestos en la plaza baja
	"reserva_feria_patio": Vector3(-74.0, 3.0, 22.0),             # [P] Feria de los Oficios: la celebración en el patio
}

# ---------------------------------------------------------------------------------------------------- grafo global
# El grafo de la CIUDAD, de sector a sector: «s_<sector>» es su referencia y «c_<conexión>» el centro del borde. Es
# topológico (para rutas de vecinos de un sector a otro y para las pruebas): una arista NO es un tramo recto; dentro de
# cada sector manda su propio GRAFO (cuando su agente lo haga). Lo construye grafo().

# ---------------------------------------------------------------------------------------------------- cámara
# La MISMA cámara que la muestra de la calle y el barrio (10,8 m sobre el foco, 14,2 m al sur, 25°, campo 38°, sin girar).
# Diferencia con el barrio: el foco sigue la ALTURA de Kael entera (en el barrio, ×0,6: allí solo había 1,4 m de desnivel;
# aquí hay 16). Sin zona, el foco es Kael; las zonas de cada trazado (CAMARA_ZONAS, modos del barrio) se mezclan con él
# por su peso, así que el foco es continuo en toda la ciudad.
const OFFSET_CAMARA := Vector3(0.0, 10.8, 14.2)
const INCLINACION := 25.0
const CAMPO := 38.0
const MARGEN_CAMARA := 2.5


# ==================================================================================================== funciones

# El sector cuya CAJA contiene (x, z), o "".
static func sector_en_caja(x: float, z: float) -> String:
	var q := Vector2(x, z)
	for s in ORDEN:
		if (SECTORES[s]["caja"] as Rect2).has_point(q):
			return s
	return ""


# El sector de (x, z): el de su suelo si se pisa; si no, el de su caja; si no, "".
static func sector_de(x: float, z: float) -> String:
	return sector_en_caja(x, z)


static func trazado(id: String):
	return TRAZADOS.get(id)


# ¿Se puede estar en (x, z)? Lo dice el trazado del sector de esa caja (sus suelos caen dentro de su caja).
# (18/11, coste: MEDIDAS_PC.md §7) Con el ÍNDICE por casillas (abajo): solo los suelos y sólidos de la casilla de (x, z), en
# vez de recorrer todos los bloques del sector (el trazado: Comun.andable). Mismo resultado (prueba_ciudad_plano lo compara).
static func andable(x: float, z: float) -> bool:
	var s := sector_en_caja(x, z)
	if s == "":
		return false
	var q := Vector2(x, z)
	var c = _indice().get(Vector2i(floori(q.x / CELDA_INDICE), floori(q.y / CELDA_INDICE)))
	if c == null:
		return false
	var d = c.get(s)
	if d == null:
		return false
	var en_suelo := false
	for r in d[0]:
		if (r as Rect2).has_point(q):
			en_suelo = true
			break
	if not en_suelo:
		return false
	for r in d[1]:
		if (r as Rect2).has_point(q):
			return false
	return true


# (18/11, coste de los arreglos del Redmi: MEDIDAS_PC.md §7) ÍNDICE por casillas de CELDA_INDICE m, hecho una vez: en cada
# casilla, por sector, [suelos, sólidos] que la tocan (para andable) y, en «holgura», [sector, rect, techo] de los sólidos
# que cuentan para el CUERPO (Comun.holgura: no finos) crecidos Comun.RADIO_CUERPO (+1 cm). andable y holgura miraban todos
# los bloques del sector en cada llamada (55-270 µs en el PC por paso de Kael, rayo del grupo o toque); con el índice,
# solo los de la casilla. Las cajas son las mismas Rect2 y has_point/distancia_planta, las mismas: el resultado no cambia.
const CELDA_INDICE := 2.0
static var _celdas := {}


static func _indice() -> Dictionary:
	if _celdas.is_empty():
		for s in ORDEN:
			var t = TRAZADOS[s]
			for su in t.SUELOS:
				for k in _casillas(su[1]):
					_de_sector(k, s)[0].append(su[1])
			for b in t.BLOQUES:
				if not b[6]:
					continue
				for k in _casillas(b[2]):
					_de_sector(k, s)[1].append(b[2])
				if not Comun.fino(b):
					var techo := float(b[3]) + float(b[4])
					for k in _casillas((b[2] as Rect2).grow(Comun.RADIO_CUERPO + 0.01)):
						var c: Dictionary = _celdas[k]
						if not c.has("holgura"):
							c["holgura"] = []
						c["holgura"].append([s, b[2], techo])
	return _celdas


# Las casillas que toca r (y las crea en el índice).
static func _casillas(r: Rect2) -> Array:
	var ks: Array = []
	for j in range(floori(r.position.y / CELDA_INDICE), floori(r.end.y / CELDA_INDICE) + 1):
		for i in range(floori(r.position.x / CELDA_INDICE), floori(r.end.x / CELDA_INDICE) + 1):
			var k := Vector2i(i, j)
			if not _celdas.has(k):
				_celdas[k] = {}
			ks.append(k)
	return ks


static func _de_sector(k: Vector2i, s: String) -> Array:
	var c: Dictionary = _celdas[k]
	if not c.has(s):
		c[s] = [[], []]
	return c[s]


# (17/11, Redmi) El CUERPO de Kael: cuánto sitio hay en (x, z) hasta la pared, pilar o jardinera alta más cercana
# (trazado_comun.holgura), de su sector o del de al lado, hasta Comun.RADIO_CUERPO; 0 si no es andable. «holgado»: cabe
# entero. La escena no deja que Kael se META en la franja (ciudad.gd, _altura_suelo); lo andable del plano no cambia.
static func holgura(x: float, z: float) -> float:
	if not andable(x, z):
		return 0.0
	var y := altura(x, z)
	var p := Vector2(x, z)
	var h := Comun.RADIO_CUERPO
	# (18/11) solo los sólidos de la casilla (índice, arriba); los de fuera están a más de RADIO_CUERPO y no cambian h
	var c: Dictionary = _indice().get(Vector2i(floori(p.x / CELDA_INDICE), floori(p.y / CELDA_INDICE)), {})
	for e in c.get("holgura", []):
		if float(e[2]) > y + Comun.ALTO_PARED and distancia_a_sector(e[0], p) < Comun.RADIO_CUERPO:
			h = minf(h, Comun.distancia_planta(e[1], p))
	return h


static func holgado(x: float, z: float) -> bool:
	return holgura(x, z) >= Comun.RADIO_CUERPO - 0.001


# La cota de lo que se pisa en (x, z) (fuera de lo andable, la del suelo más cercano de su sector; fuera de la ciudad, 0).
static func altura(x: float, z: float) -> float:
	var s := sector_en_caja(x, z)
	if s == "":
		return 0.0
	return TRAZADOS[s].altura(x, z)


# Un ancla: las globales y, si no, la de un trazado con el formato «<sector>/<ancla>».
static func ancla(id: String) -> Vector3:
	if ANCLAS.has(id):
		var a: Vector3 = ANCLAS[id]
		return Vector3(a.x, altura(a.x, a.z), a.z)
	if "/" in id and TRAZADOS.has(id.get_slice("/", 0)):
		return TRAZADOS[id.get_slice("/", 0)].ancla(id.get_slice("/", 1))
	push_warning("Ciudad: no hay ancla «%s»" % id)
	return Vector3(INICIO.x, altura(INICIO.x, INICIO.z), INICIO.z)


# Distancia en planta de (x, z) a la caja de un sector (0 dentro).
static func distancia_a_sector(id: String, p: Vector2) -> float:
	var r: Rect2 = SECTORES[id]["caja"]
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)).distance_to(p)


static func conexion(id: String) -> Dictionary:
	for c in CONEXIONES:
		if c["id"] == id:
			return c
	return {}


# El centro del borde de una conexión, en el suelo.
static func centro_conexion(c: Dictionary) -> Vector3:
	var m: float = (float(c["desde"]) + float(c["hasta"])) * 0.5
	var p := Vector2(float(c["en"]), m) if c["borde"] == "x" else Vector2(m, float(c["en"]))
	return Vector3(p.x, altura(p.x, p.y), p.y)


# Un punto a «dentro» metros del borde, del lado del sector «lado» (a o b), en «t» ∈ [0, 1] del ancho.
static func punto_conexion(c: Dictionary, lado: String, dentro: float, t := 0.5) -> Vector3:
	var along: float = lerpf(float(c["desde"]), float(c["hasta"]), t)
	var en: float = c["en"]
	var caja: Rect2 = SECTORES[c[lado]]["caja"]
	if c["borde"] == "x":
		var x := en + dentro if caja.has_point(Vector2(en + 0.01, along)) else en - dentro
		return Vector3(x, altura(x, along), along)
	var z := en + dentro if caja.has_point(Vector2(along, en + 0.01)) else en - dentro
	return Vector3(along, altura(along, z), z)


# El grafo global: {nodo: [vecinos]} (ver arriba).
static func grafo() -> Dictionary:
	var g := {}
	for s in ORDEN:
		g["s_" + s] = []
	for c in CONEXIONES:
		var n: String = "c_" + c["id"]
		g[n] = ["s_" + c["a"], "s_" + c["b"]]
		g["s_" + c["a"]].append(n)
		g["s_" + c["b"]].append(n)
	return g


# Dónde está cada nodo del grafo (en el suelo).
static func nodo(n: String) -> Vector3:
	if n.begins_with("s_"):
		return ancla(SECTORES[n.trim_prefix("s_")]["ref"])
	return centro_conexion(conexion(n.trim_prefix("c_")))


# Todas las puertas previstas: [[sector, id, {fuera, mira, radio, texto, ancla}]].
static func puertas() -> Array:
	var r: Array = []
	for s in ORDEN:
		var t = TRAZADOS[s]
		for id in t.PUERTAS:
			r.append([s, id, t.PUERTAS[id]])
	return r


# ---------------------------------------------------------------------------------------------------- cámara

static var _zonas: Array = []


static func zonas_camara() -> Array:
	if _zonas.is_empty():
		for s in ORDEN:
			for z in TRAZADOS[s].CAMARA_ZONAS:
				_zonas.append(z)
	return _zonas


static func peso_zona(zona: Dictionary, x: float, z: float) -> float:
	var r: Rect2 = zona["rect"]
	var d := minf(minf(x - r.position.x, r.end.x - x), minf(z - r.position.y, r.end.y - z))
	if d <= 0.0:
		return 0.0
	return smoothstep(0.0, MARGEN_CAMARA, d)


static func _foco_zona(zona: Dictionary, k: Vector3) -> Vector2:
	match String(zona["modo"]):
		"x":
			var zr: float = zona["z_riel"]
			var rx: Vector2 = zona["x"]
			return Vector2(clampf(k.x, rx.x, rx.y), zr + minf(0.0, k.z - zr) * 0.55)
		"eje":
			var ez: Vector2 = zona["z"]
			return Vector2(float(zona["eje"]), clampf(k.z + float(zona.get("atraso", 0.0)), ez.x, ez.y))
	var lx: Vector2 = zona["x"]
	var lz: Vector2 = zona["z"]
	return Vector2(clampf(k.x, lx.x, lx.y), clampf(k.z, lz.x, lz.y))


# Adónde va el foco con Kael en k: la media pesada de las zonas y, con el peso que falte hasta 1, el propio Kael.
static func foco_camara(k: Vector3) -> Vector3:
	var suma := 0.0
	var acc := Vector2.ZERO
	for zona in zonas_camara():
		var w := peso_zona(zona, k.x, k.z)
		if w > 0.0:
			acc += _foco_zona(zona, k) * w
			suma += w
	var resto := maxf(0.0, 1.0 - suma)
	acc += Vector2(k.x, k.z) * resto
	var f := acc / maxf(suma + resto, 0.0001)
	return Vector3(f.x, k.y, f.y)


static func posicion_camara(k: Vector3) -> Vector3:
	return foco_camara(k) + OFFSET_CAMARA


static func poner_camara(c: Camera3D, foco: Vector3) -> void:
	c.projection = Camera3D.PROJECTION_PERSPECTIVE
	c.global_position = foco + OFFSET_CAMARA
	c.global_rotation = Vector3(deg_to_rad(-INCLINACION), 0.0, 0.0)
	c.fov = CAMPO


# Lo que corta el rayo de la cámara (puesta para Kael en k) a su cabeza: [[sector, id, ocultable]]. «sectores»: en cuáles
# mirar (por defecto, todos).
static func tapan_a_kael(k: Vector3, sectores: Array = ORDEN) -> Array:
	var desde := posicion_camara(k)
	var hasta := k + Vector3(0.0, Comun.ALTO_CABEZA, 0.0)
	var r: Array = []
	for s in sectores:
		var t = TRAZADOS[s]
		for x in Comun.tapan(t.BLOQUES, t.OCULTABLES, desde, hasta):
			r.append([s, x[0], x[1]])
	return r


# Los SUELOS que corta ese mismo rayo (un punto del rayo por DEBAJO de la tapa de un suelo, rampas incluidas, hasta 4 m
# por debajo): un nivel más alto al sur de Kael lo taparía y la escena no lo aclara. ["<sector>/<índice>"]. Como la ciudad
# sube hacia el norte, debe salir vacío.
static func suelos_que_tapan(k: Vector3) -> Array:
	var desde := posicion_camara(k)
	var hasta := k + Vector3(0.0, Comun.ALTO_CABEZA, 0.0)
	var planta := Rect2(Vector2(minf(desde.x, hasta.x), minf(desde.z, hasta.z)), Vector2.ZERO).expand(
		Vector2(maxf(desde.x, hasta.x), maxf(desde.z, hasta.z))).grow(0.01)
	var n := int(ceil(desde.distance_to(hasta) / 0.2))
	var r: Array = []
	for s in ORDEN:
		var suelos: Array = TRAZADOS[s].SUELOS
		for i in suelos.size():
			var re: Rect2 = suelos[i][1]
			if not re.intersects(planta, true):
				continue
			for j in n:
				var p := desde.lerp(hasta, float(j) / n)
				if re.has_point(Vector2(p.x, p.z)):
					var y := Comun.cota_suelo(suelos[i], p.x, p.z)
					if p.y < y - 0.02 and p.y > y - 4.0:
						r.append("%s/%d" % [s, i])
						break
	return r
