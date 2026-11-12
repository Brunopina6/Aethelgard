extends RefCounted
# Hallazgos y notas en las regiones 3D (V12, fase 2: migración región a región; primero la Garganta del Diablo).
# Las zonas 2D los tienen desde zona.gd (hallazgos.gd y las notas de progreso.gd); cada región 3D los engancha con este
# módulo, sin repetir la lógica: mismos ids y misma forma de guardarse, así una partida vale en la 2D y en la 3D.
#   - Hallazgos (hallazgos.gd): al examinar algo («detalle:<id>», «altar», «pieza:<id>»), lo que toca se da una sola
#     vez y se apunta en «cofres_abiertos» con su id «hall_…» (si ya se encontró en la 2D, no sale).
#   - Notas (progreso.gd, CIUDADES y ver_nota): se leen al examinarlas y van al Diario; se apuntan en «lore_visto».
# Lo que se ve (el objeto, su destello) lo pone cada región con su arte; aquí solo la lógica y los avisos.
# La región tiene que tener _mostrar_aviso(texto, segundos), guardar_posicion() y scene_file_path (todas las de
# zonas3d/ los tienen). Se guarda la partida tras un hallazgo o una nota nueva (salvo en los bancos de medida).

const Hallazgos := preload("res://hallazgos.gd")
const Progreso := preload("res://progreso.gd")
const ENTRE_AVISOS := 3.6                # segundos entre un aviso y el siguiente (zona.gd, _avisos_hallazgo)
const DURA_AVISO := 3.0
const DURA_NOTA := 4.5                   # el texto de una nota (como Pastos Verdes 3D)
const TRAS_NOTA := 4.6                   # «Nueva nota en el Diario», después del texto


# ¿Queda algo por encontrar al examinar «que» en ese lugar? (para enseñar el objeto en su sitio mientras tanto)
static func hallazgo_pendiente(lugar: int, que: String) -> bool:
	for h in Hallazgos.de_lugar(lugar):
		if h["al"] == que and not Hallazgos.encontrado(h["id"]):
			return true
	return false


# Al examinar «que» en el lugar: si toca un hallazgo, se da (una vez), sus avisos salen uno tras otro desde «desde»
# segundos, suena «tesoro» y se guarda. Devuelve cuándo queda libre el aviso («desde» si no había nada).
static func hallazgo_al_examinar(region: Node, lugar: int, que: String, desde: float) -> float:
	var textos: Array = Hallazgos.al_examinar(lugar, que)
	if textos.is_empty():
		return desde
	avisos(region, textos, desde)
	_sonido(region, "tesoro", {"retraso": desde + 0.3})
	_guardar(region)
	return desde + ENTRE_AVISOS * textos.size()


# Unos avisos, uno detrás de otro, desde «desde» segundos.
static func avisos(region: Node, textos: Array, desde: float, dura := DURA_AVISO) -> void:
	for i in textos.size():
		var t: String = textos[i]
		var cuando := desde + ENTRE_AVISOS * i
		if cuando <= 0.0:
			region._mostrar_aviso(t, dura)
		else:
			# (un método de la región, no una lambda que la guarde: si se sale antes, la conexión se va con ella; V12, Oakhaven)
			region.get_tree().create_timer(cuando).timeout.connect(region._mostrar_aviso.bind(t, dura))


# La nota más cercana a «p» dentro de «radio» (en planta, con la altura parecida), o {}. Cada nota, un diccionario con
# al menos «datos» (los de su módulo: id, nombre, texto) y «pos» (el sitio donde se examina).
static func nota_cerca(notas: Array, p: Vector3, radio: float, alto := 2.5) -> Dictionary:
	var mejor := {}
	var dist := radio
	for n in notas:
		var q: Vector3 = n["pos"]
		var d := Vector2(p.x - q.x, p.z - q.z).length()
		if d < dist and absf(p.y - q.y) < alto:
			dist = d
			mejor = n
	return mejor


# Leer una nota: su texto, «examinar», se apaga su destello («brillo», si lo tiene) y, si es nueva, al Diario (con su
# aviso) y se guarda. Devuelve true si era nueva.
static func leer_nota(region: Node, nota: Dictionary) -> bool:
	var d: Dictionary = nota["datos"]
	region._mostrar_aviso(d["texto"], DURA_NOTA)
	_sonido(region, "examinar")
	var brillo = nota.get("brillo")
	if brillo != null and is_instance_valid(brillo):
		brillo.queue_free()
	nota["brillo"] = null
	if not Progreso.ver_nota(d["id"]):
		return false
	var nombre: String = d["nombre"]
	region.get_tree().create_timer(TRAS_NOTA).timeout.connect(region._mostrar_aviso.bind("Nueva nota en el Diario: «%s»" % nombre, 2.4))
	_sonido(region, "pagina", {"retraso": TRAS_NOTA})
	_guardar(region)
	return true


static func _sonido(region: Node, clave: String, opciones := {}) -> void:
	var s = region.get_node_or_null("/root/Sonido")
	if s != null:
		s.efecto(clave, opciones)


static func _guardar(region: Node) -> void:
	if Engine.has_meta("banco_proto"):
		return
	region.guardar_posicion()
	Progreso.guardar(region.scene_file_path)
