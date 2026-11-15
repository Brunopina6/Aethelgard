extends RefCounted
# Sunken City 3D (V12, 15/11), sector «Popa Rota → Cubierta Mayor»: el trazado, en metros, con los ejes de la escena (x al
# este, z al sur, y arriba) y las casillas del diseño (docs/diseno/ciudades_y_lugares.md §2.2: x = casilla x, z = casilla
# y; el barco va de la popa, al sur, a la proa, al norte). Lo usan la escena (zonas3d/sunken_3d.gd), su escenario
# (zonas3d/sunken/casco.gd), las pruebas y el guion de Blender (zonas3d/sunken/fuente/crear_sunken.py, con LAS MISMAS
# medidas: si se cambia una, se cambia en los dos).
#
# Por dónde se anda: solo por las tablas (los rectángulos de ANDABLE), fuera de lo que estorba (BLOQUEOS y los vecinos).
# Kael va en línea recta y se para en el primer punto prohibido (vista3d.gd): por eso todo el sector son tramos rectos
# (muelle → brecha de la popa → la Quilla → la rampa → la Cubierta Mayor) y los desvíos salen en ángulo recto (el pasillo
# del Archivo, el balcón de estribor), sin callejones.
# Alturas: el muelle, la cubierta de popa y la Quilla a ras (0); el Archivo, 0,8 (una rampa en su pasillo); la Cubierta
# Mayor y el balcón, ALTO_CUBIERTA (la rampa del norte de la Quilla). La laguna, a NIVEL_AGUA.

const ALTO_CUBIERTA := 1.2
const ALTO_ARCHIVO := 0.8
const NIVEL_AGUA := -0.85

# Lo que se pisa (nombre → Rect2 en x, z). El orden importa poco: altura() mira las rampas primero.
const MUELLE := Rect2(38.6, 52.6, 2.8, 8.0)          # el muelle de tablas por el que se llega (entra por la brecha)
const POPA := Rect2(33.6, 44.2, 12.8, 9.0)           # la cubierta de popa, dentro del espejo roto
const PASO_ARCHIVO := Rect2(46.4, 44.6, 3.4, 2.0)    # pasillo al Archivo: rampa de 0 (x 46,4) a 0,8 (x 48,6)
const ARCHIVO := Rect2(49.6, 42.0, 6.2, 5.8)         # el Archivo del Águila (antiguo camarote del capitán), por dentro
const QUILLA := Rect2(38.4, 31.2, 3.2, 13.2)         # la pasarela sobre la quilla, bajo las costillas
const RAMPA := Rect2(38.4, 28.8, 3.2, 2.4)           # sube a la Cubierta Mayor: de 0 (z 31,2) a ALTO_CUBIERTA (z 28,8)
const CUBIERTA := Rect2(30.0, 18.6, 20.0, 10.2)      # la Cubierta Mayor (la plaza)
const BALCON := Rect2(50.0, 21.0, 4.6, 4.6)          # el balcón de estribor (mira al dique de la Astraea)
const ANDABLE := [MUELLE, POPA, PASO_ARCHIVO, ARCHIVO, QUILLA, RAMPA, CUBIERTA, BALCON]
const RAMPA_ARCHIVO_X := Vector2(46.4, 48.6)

# Lo que estorba dentro de lo andable (Rect2). Los muros del Archivo quedan fuera de su rectángulo.
const BLOQUEOS := [
	# el espejo de popa, a los lados de la brecha: es curvo (crear_sunken.py, popa_z), más hondo en las aletas
	Rect2(32.4, 52.2, 3.6, 2.4), Rect2(36.0, 52.9, 2.0, 1.6), Rect2(42.0, 52.9, 2.0, 1.6), Rect2(44.0, 52.2, 3.6, 2.4),
	Rect2(49.6, 42.0, 6.2, 0.7),                                # los archivadores del Archivo (pared norte)
	Rect2(51.6, 44.0, 2.2, 0.8),                                # la mesa de Ulla
	Rect2(54.6, 45.9, 0.6, 0.6),                                # el atril de los contratos
	Rect2(39.2, 22.4, 1.6, 1.6),                                # el pie del palo mayor
	Rect2(30.0, 18.6, 4.8, 2.6),                                # el puesto del mercado (la tienda)
	Rect2(43.4, 24.8, 2.2, 1.8),                                # la brazola de la escotilla
	Rect2(46.8, 18.6, 3.2, 1.6),                                # cajas y redes junto a la barandilla de proa
	Rect2(30.0, 26.2, 1.4, 2.0),                                # barriles
	Rect2(31.0, 27.6, 2.2, 0.6),                                # el cañón viejo hecho macetero
	Rect2(37.4, 28.2, 0.4, 0.4), Rect2(42.2, 28.2, 0.4, 0.4),   # los postes de los faroles de la rampa
	Rect2(41.2, 18.6, 3.6, 0.5),                                # las cuerdas de la proa en obras
	Rect2(50.0, 25.6, 0.9, 0.9),                                # el pie de la costilla de la plaza, en el balcón
	Rect2(33.6, 44.2, 2.0, 1.8),                                # redes y barril de la popa (y sus choques del GLB)
	Rect2(45.05, 51.35, 1.4, 0.65), Rect2(34.25, 50.95, 1.4, 0.65),
	Rect2(44.45, 44.72, 0.7, 0.56), Rect2(34.85, 48.32, 0.7, 0.56),   # cajones de la popa
]

# Sitios (x, z): la altura la pone altura().
const INICIO := Vector2(40.0, 57.8)       # al llegar del mapa: en el muelle, mirando a la brecha de la popa
const SALIDA := Vector2(40.0, 60.0)       # «Mapa del mundo»: el final del muelle
const ULLA := Vector2(52.7, 43.3)         # tras su mesa, bajo la lona del Archivo
const BREA := Vector2(36.6, 24.6)         # en la Cubierta Mayor, junto al palo mayor (diseño: 38, 24)
const PALO := Vector2(40.0, 23.2)         # el palo mayor
const COSTILLAS_QUILLA := [44.0, 38.0, 32.0]   # costillas que cruzan la Quilla (z): cada una con su farol…
const COSTILLA_OSCURA := 38.0                  # …menos esta, la del medio (el secreto: «la que no alumbra»)
const COSTILLAS_CUBIERTA := [26.0, 20.0]
const COSTILLAS_PROA := [14.0, 9.5]
const COSTILLA_POPA := 50.0                    # la de la popa, rota por un lado

# Puntos de interacción: id → [x, z, radio, texto del botón]. (Los vecinos van aparte: ULLA y BREA.)
const PIEZAS := {
	"popa": [40.0, 55.3, 1.5, "Examinar el espejo de popa"],
	"grabado": [37.5, 52.5, 1.2, "Leer el grabado"],
	"tabla": [38.75, 38.0, 1.0, "Mirar bajo la tabla"],
	"contratos": [54.2, 46.8, 1.3, "Examinar los contratos"],
	"palo": [40.0, 24.7, 1.3, "Examinar el palo mayor"],
	"tienda": [32.4, 22.3, 1.5, "Ver el puesto"],
	"escotilla": [44.5, 27.4, 1.3, "Examinar la escotilla"],
	"lona": [53.8, 23.3, 1.5, "Mirar la lona"],
	"proa": [43.0, 19.7, 1.4, "Examinar las cuerdas"],   # (al este del palo: desde ahí se ve el mascarón)
}
const RADIO_NPC := 2.3
const RADIO_SALIDA := 1.2
const ARMAR_SALIDA := 2.6

# Zonas de cámara: [inclinación, distancia mínima, máxima]. En el norte de la Cubierta Mayor, más baja: se ve el mascarón.
const CAMARA := [50.0, 13.0, 18.0]
const CAMARA_ARCHIVO := [58.0, 9.0, 12.0]
const CAMARA_CUBIERTA := [46.0, 14.0, 19.0]
const CAMARA_PROA := [30.0, 18.0, 22.0]
const CAMARA_BALCON := [42.0, 15.0, 19.0]
const PROA_Z := 21.6                       # en la Cubierta Mayor, al norte de esto: la cámara de la proa


static func andable(x: float, z: float) -> bool:
	var q := Vector2(x, z)
	for r in ANDABLE:
		if (r as Rect2).has_point(q):
			return true
	return false


static func bloqueado(x: float, z: float, margen := 0.3) -> bool:
	var q := Vector2(x, z)
	for r in BLOQUEOS:
		if (r as Rect2).grow(margen).has_point(q):
			return true
	return false


# ¿No se puede estar en p? Fuera de las tablas o dentro de algo que estorba (los vecinos, aparte: sunken_3d.gd).
static func prohibido(x: float, z: float) -> bool:
	return not andable(x, z) or bloqueado(x, z)


# La altura de lo que se pisa en (x, z).
static func altura(x: float, z: float) -> float:
	var q := Vector2(x, z)
	if RAMPA.has_point(q):
		return ALTO_CUBIERTA * clampf((RAMPA.end.y - z) / RAMPA.size.y, 0.0, 1.0)
	if CUBIERTA.has_point(q) or BALCON.has_point(q):
		return ALTO_CUBIERTA
	if PASO_ARCHIVO.has_point(q):
		return ALTO_ARCHIVO * clampf((x - RAMPA_ARCHIVO_X.x) / (RAMPA_ARCHIVO_X.y - RAMPA_ARCHIVO_X.x), 0.0, 1.0)
	if ARCHIVO.has_point(q):
		return ALTO_ARCHIVO
	return 0.0


static func en_mundo(c: Vector2) -> Vector3:
	return Vector3(c.x, altura(c.x, c.y), c.y)


static func pieza(id: String) -> Vector3:
	var d: Array = PIEZAS[id]
	return en_mundo(Vector2(d[0], d[1]))


# La zona del sector donde está p (para la cámara, los pasos y las pruebas).
static func zona(x: float, z: float) -> String:
	var q := Vector2(x, z)
	if MUELLE.has_point(q) and z > POPA.end.y:
		return "muelle"
	if ARCHIVO.has_point(q):
		return "archivo"
	if BALCON.has_point(q):
		return "balcon"
	if CUBIERTA.has_point(q):
		return "proa" if z < PROA_Z else "cubierta"
	if QUILLA.has_point(q) or RAMPA.has_point(q):
		return "quilla"
	return "popa"


static func camara(x: float, z: float) -> Array:
	match zona(x, z):
		"archivo":
			return CAMARA_ARCHIVO
		"cubierta":
			return CAMARA_CUBIERTA
		"proa":
			return CAMARA_PROA
		"balcon":
			return CAMARA_BALCON
	return CAMARA
