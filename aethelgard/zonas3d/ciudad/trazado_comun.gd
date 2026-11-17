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


# ¿Se aclara este bloque cuando tapa a Kael? Las cubiertas y las copas, siempre; los pilares, postes y troncos finos y
# altos (fino_alto), también (17/11, Redmi); el resto, si su trazado lo pone en OCULTABLES.
static func ocultable(b: Array, ocultables: Array) -> bool:
	return String(b[5]) in TIPOS_OCULTABLES or String(b[0]) in ocultables or fino_alto(b)


# Un pilar, poste o pie de farol (≤ FINO por los dos lados) es más estrecho que Kael: de LEJOS no lo tapa (se le ve a los
# lados). De CERCA sí: en el Redmi (16/11, lonja de la plaza) un pilar de 0,5 m justo delante de Kael lo tapaba casi entero
# (su figura mide unos 0,5 m de ancho en pantalla). Por eso un fino a menos de FINO_CERCA de Kael (en planta) cuenta como
# los demás (tapan), y los finos que llegan a la altura del pecho (fino_alto: ALTO_FINO) son ocultables: la escena los
# aclara cuando cortan un rayo a Kael, cerca o lejos (sector.gd, aclarar).
const FINO := 0.6
const FINO_CERCA := 2.0
const ALTO_FINO := 1.2


static func fino(b: Array) -> bool:
	var r: Rect2 = b[2]
	return r.size.x <= FINO + 0.001 and r.size.y <= FINO + 0.001   # (margen: Rect2 guarda float32; 0,6 queda en 0,6000000238)


# Un fino que tapa el pecho o la cabeza: un pilar, un poste o un tronco, o algo pequeño COLGADO (un farol, una tablilla
# de los caminos: decor sin choque); no una caja baja en el suelo.
static func fino_alto(b: Array) -> bool:
	return fino(b) and String(b[5]) != "puerta" and (float(b[4]) >= ALTO_FINO or (String(b[5]) == "decor" and not b[6]))


# Los bloques que cortan el segmento desde → hasta: [[id, ocultable]] (sin los finos a más de FINO_CERCA de «hasta»).
# Filtra antes por la planta.
static func tapan(bloques: Array, ocultables: Array, desde: Vector3, hasta: Vector3) -> Array:
	var r: Array = []
	var planta := Rect2(Vector2(minf(desde.x, hasta.x), minf(desde.z, hasta.z)), Vector2.ZERO).expand(Vector2(
		maxf(desde.x, hasta.x), maxf(desde.z, hasta.z))).grow(VUELO_TEJADO + 0.01)
	var h := Vector2(hasta.x, hasta.z)
	for b in bloques:
		if not (b[2] as Rect2).intersects(planta, true):
			continue
		if fino(b) and distancia_planta(b[2], h) > FINO_CERCA:
			continue
		for c in cajas_bloque(b):
			if (c as AABB).intersects_segment(desde, hasta):
				r.append([b[0], ocultable(b, ocultables)])
				break
	return r


# Distancia en planta de p a un rectángulo (0 dentro).
static func distancia_planta(r: Rect2, p: Vector2) -> float:
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)).distance_to(p)


# CUERPO de Kael (17/11, Redmi): Kael choca como un PUNTO (lo andable del plano y el rayo de las rodillas por delante), así
# que al andar pegado a una pared, un pilar o una jardinera alta media figura quedaba DENTRO del bloque y, desde la cámara,
# tapada de lado (Rampa de las Raíces, pórtico de las Raíces; RADIO_CUERPO es media figura). La distancia en planta de (x, z) al bloque
# sólido más cercano que suba más de ALTO_PARED por encima de «y» (lo que se pisa ahí), hasta «radio» como mucho. Los
# bloques bajos (bancos, parterres, el pilón) no cuentan: delante de las piernas es lo normal. Los finos (pilares de
# ≤ 0,6 m) tampoco: se aclaran (fino_alto) y su franja cerraba los pasos estrechos de los soportales (el del Cuervo,
# entre el pilar y el puesto del tonelero: recorrido, 17/11).
const RADIO_CUERPO := 0.3
# (por encima de la cintura: el pilón de la fuente, 0,7, un pretil de 0,9 o el puesto del tonelero, 0,85 sobre el
# soportal del Cuervo, no; con 0,8 el puesto cerraba el soportal, que deja 0,6 m entre él y los pilares: recorrido)
const ALTO_PARED := 1.0


static func holgura(bloques: Array, x: float, z: float, y: float, radio := RADIO_CUERPO) -> float:
	var p := Vector2(x, z)
	var h := radio
	for b in bloques:
		if b[6] and float(b[3]) + float(b[4]) > y + ALTO_PARED and not fino(b):
			h = minf(h, distancia_planta(b[2], p))
	return h
