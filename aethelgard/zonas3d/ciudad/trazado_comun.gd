extends RefCounted
# CIUDAD COMPLETA de Oakhaven (V12, 16/11, M0; EXPERIMENTAL, PROPUESTA [P]): las funciones COMUNES de los trazados de
# sector (zonas3d/ciudad/sectores/<id>/trazado.gd). Cada trazado guarda sus datos (SUELOS, BLOQUES, ANCLAS, PUERTAS…)
# con el MISMO formato que el del barrio (zonas3d/barrio/trazado.gd) y llama a estas funciones pasándoles sus listas:
# así las reglas de qué se pisa y a qué altura son las mismas en los ocho sectores. Documentación: docs/v12/CIUDAD_OAKHAVEN.md.
#
# Formatos (los del barrio):
#   SUELO  [sector, Rect2 (x, z, ancho, fondo), eje ("" llano, "x" o "z"), cota al principio, cota al final]
#          «Al principio» = lado oeste (eje x) o norte (eje z), es decir, Rect2.position. Rect2 semiabierto.
#   BLOQUE [id, sector, Rect2 en planta, base (y del suelo de debajo), alto sobre la base, tipo, sólido]
#          Tipos: casa (con tejado), muro, bajo, puerta, decor, terreno, arbol, cubierta (lo que pasa por ENCIMA de lo
#          andable: soportales, pasos cubiertos, lonjas, arcos) y copa (follaje alto). Lo sólido deja de ser andable.

const ALTO_CABEZA := 1.5                   # (cámara → cabeza de Kael, para la visibilidad)
# El tejado de una casa sobresale esto por cada lado. En la MAQUETA, 0: con vuelo, el alero de una fachada que da a una
# calle de norte a sur queda encima de la franja de calle pegada a ella y tapa la cabeza de Kael desde la cámara (que está
# al sur); los aleros de verdad llegan con el kit, y lo que tape lo aclara la escena (OCULTABLES).
const VUELO_TEJADO := 0.0
const GRUESO_TEJADO := 0.45
const TIPOS := ["casa", "muro", "bajo", "puerta", "decor", "terreno", "arbol", "cubierta", "copa"]
const TIPOS_ARRIBA := ["cubierta", "copa", "puerta"]   # se dibujan desde su base (no se hunden 0,5 m en el suelo)
const TIPOS_OCULTABLES := ["cubierta", "copa"]          # siempre se aclaran si tapan a Kael


# El índice del SUELO que hay en (x, z), o −1.
static func suelo_en(suelos: Array, x: float, z: float) -> int:
	var q := Vector2(x, z)
	for i in suelos.size():
		if (suelos[i][1] as Rect2).has_point(q):
			return i
	return -1


# El bloque sólido que ocupa (x, z), o "".
static func bloque_en(bloques: Array, x: float, z: float) -> String:
	var q := Vector2(x, z)
	for b in bloques:
		if b[6] and (b[2] as Rect2).has_point(q):
			return b[0]
	return ""


static func andable(suelos: Array, bloques: Array, x: float, z: float) -> bool:
	return suelo_en(suelos, x, z) >= 0 and bloque_en(bloques, x, z) == ""


# La cota de un suelo en (x, z) (rampas y escalones, lineales).
static func cota_suelo(s: Array, x: float, z: float) -> float:
	var r: Rect2 = s[1]
	match String(s[2]):
		"x":
			return lerpf(s[3], s[4], clampf((x - r.position.x) / r.size.x, 0.0, 1.0))
		"z":
			return lerpf(s[3], s[4], clampf((z - r.position.y) / r.size.y, 0.0, 1.0))
	return float(s[3])


# La cota de lo que se pisa en (x, z); fuera de los suelos, la del suelo más cercano (para colocar cosas al borde).
static func altura(suelos: Array, x: float, z: float) -> float:
	if suelos.is_empty():
		return 0.0
	var i := suelo_en(suelos, x, z)
	if i < 0:
		i = suelo_cercano(suelos, x, z)
	return cota_suelo(suelos[i], x, z)


static func suelo_cercano(suelos: Array, x: float, z: float) -> int:
	var mejor := 0
	var dmin := INF
	for i in suelos.size():
		var r: Rect2 = suelos[i][1]
		var c := Vector2(clampf(x, r.position.x, r.end.x), clampf(z, r.position.y, r.end.y))
		var d := c.distance_to(Vector2(x, z))
		if d < dmin:
			dmin = d
			mejor = i
	return mejor


# Un ancla del sector, en el suelo (la «y» escrita es para leerla; manda altura()). Un nombre que no existe avisa y da
# el primer suelo.
static func ancla(anclas: Dictionary, suelos: Array, id: String) -> Vector3:
	if not anclas.has(id):
		push_warning("Ciudad: no hay ancla «%s»" % id)
		var r: Rect2 = suelos[0][1]
		return Vector3(r.get_center().x, altura(suelos, r.get_center().x, r.get_center().y), r.get_center().y)
	var a: Vector3 = anclas[id]
	return Vector3(a.x, altura(suelos, a.x, a.z), a.z)


# Las cotas de las cuatro esquinas de un suelo: [noroeste, noreste, suroeste, sureste] (x0z0, x1z0, x0z1, x1z1).
static func esquinas(s: Array) -> Array:
	var r: Rect2 = s[1]
	var a: float = s[3]
	var b: float = s[4]
	match String(s[2]):
		"x":
			return [a, b, a, b]
		"z":
			return [a, a, b, b]
	return [a, a, a, a]


# Las cajas que se DIBUJAN de un bloque (en metros, AABB): el cuerpo y, si es una casa, su tejado con vuelo. Son las
# mismas para el blockout, la maqueta lejana y la prueba de visibilidad (rayo de la cámara a la cabeza de Kael).
static func cajas_bloque(b: Array) -> Array:
	var r: Rect2 = b[2]
	var base: float = b[3]
	var alto: float = b[4]
	var tipo: String = b[5]
	var abajo := base if tipo in TIPOS_ARRIBA else base - 0.5
	var r_cajas: Array = [AABB(Vector3(r.position.x, abajo, r.position.y), Vector3(r.size.x, base + alto - abajo, r.size.y))]
	if tipo == "casa":
		var t := r.grow(VUELO_TEJADO)
		r_cajas.append(AABB(Vector3(t.position.x, base + alto - 0.025, t.position.y), Vector3(t.size.x, GRUESO_TEJADO, t.size.y)))
	return r_cajas


# ¿Se aclara este bloque cuando tapa a Kael? Las cubiertas y las copas, siempre; el resto, si su trazado lo pone en
# OCULTABLES.
static func ocultable(b: Array, ocultables: Array) -> bool:
	return String(b[5]) in TIPOS_OCULTABLES or String(b[0]) in ocultables


# Un pilar, poste o pie de farol (≤ FINO por los dos lados) es más estrecho que Kael: no lo tapa (se le ve a los lados).
const FINO := 0.6


static func fino(b: Array) -> bool:
	var r: Rect2 = b[2]
	return r.size.x <= FINO and r.size.y <= FINO


# Los bloques que cortan el segmento desde → hasta: [[id, ocultable]] (sin los finos). Filtra antes por la planta.
static func tapan(bloques: Array, ocultables: Array, desde: Vector3, hasta: Vector3) -> Array:
	var r: Array = []
	var planta := Rect2(Vector2(minf(desde.x, hasta.x), minf(desde.z, hasta.z)), Vector2.ZERO).expand(Vector2(
		maxf(desde.x, hasta.x), maxf(desde.z, hasta.z))).grow(VUELO_TEJADO + 0.01)
	for b in bloques:
		if fino(b) or not (b[2] as Rect2).intersects(planta, true):
			continue
		for c in cajas_bloque(b):
			if (c as AABB).intersects_segment(desde, hasta):
				r.append([b[0], ocultable(b, ocultables)])
				break
	return r
