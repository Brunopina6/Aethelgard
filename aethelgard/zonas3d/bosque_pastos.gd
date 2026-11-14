extends Node3D
# «El bosque que no recuerda» en Pastos Verdes 3D (fase 3, 10/11; docs/fase3_bosque/AVENTURA_JUGABLE.md).
# Lo crea zonas3d/pastos_verdes_3d.gd (preparar) y le pregunta en cada fotograma qué hay cerca (cerca_de), qué hacer al
# pulsar el botón (accion), qué objetivo mostrar (texto_objetivo) y qué diálogo toca con Tilo (dialogo_tilo).
# Todo se guarda en la partida con claves que ya existen: «hitos» (bq_*), «decisiones» (guardian_bosque) y el
# inventario. Sin modelos de terceros: formas sencillas, como Tilo, la estela y el cofre.
#
# Recorrido: árbol marcado (junto a Tilo) → lirios (río) → surcos (este) → ramas (Garon abre la senda) → ruinas con la
# inscripción, el manantial, savia y un cofre → claro del noreste, donde duerme el Guardián.

const T := preload("res://dialogos/notas/bosque.gd")
const B := preload("res://combate_bosque.gd")
const GRUPO_GUARDIAN := 11                 # combate.gd, GRUPOS[11]
const RADIO := 2.2                         # como RADIO_ACCION de la región
const RADIO_CLARO := 3.2                   # al llegar tan cerca del Guardián, despierta (si ya se sabe qué le pasa)
const PISTAS := ["bq_pista_planta", "bq_pista_rastro", "bq_pista_inscripcion"]

# Sitios aproximados (x, z); cada cosa se coloca en el hueco libre más cercano (_sitio).
const SITIO_ARBOL := Vector3(0.5, 0, -7.5)
const SITIO_LIRIOS := Vector3(4.4, 0, 9.0)
const SITIO_SURCOS := Vector3(17.5, 0, -9.5)
const SITIO_RAMAS := Vector3(-6.0, 0, -5.0)
const SITIO_RUINAS := Vector3(-12.0, 0, -12.0)
const SITIO_MANANTIAL := Vector3(-16.0, 0, -8.5)
const SITIO_COFRE := Vector3(-8.0, 0, -17.0)
const SITIO_CLARO := Vector3(17.0, 0, -18.5)
const SITIO_ORBE := Vector3(-9.0, 0, -10.0)        # el altar del orbe, en las ruinas (V9: los dos futuros del bosque)
# Encargo «Canela se ha perdido» (V9; datos/encargos_pastos.gd): huellas hacia las ramas y la perra en las ruinas.
const SITIOS_HUELLAS := [Vector3(-7.5, 0, 2.0), Vector3(-8.5, 0, -2.5)]
const SITIO_PERRO := Vector3(-6.5, 0, -14.0)
# Materiales: [id del punto, material, sitio, ¿solo tras abrir la senda?]
const RECOLECCION := [
	["bq_rec_hierba_1", "Hierba lunar", Vector3(4.5, 0, 6.5), false],
	["bq_rec_hierba_2", "Hierba lunar", Vector3(4.4, 0, -9.0), false],
	["bq_rec_hierba_3", "Hierba lunar", Vector3(13.6, 0, 6.0), false],
	["bq_rec_hierba_4", "Hierba lunar", Vector3(-12.5, 0, -6.0), true],
	["bq_rec_musgo_1", "Musgo de piedra", Vector3(-4.5, 0, 10.5), false],
	["bq_rec_musgo_2", "Musgo de piedra", Vector3(18.0, 0, -12.5), false],
	["bq_rec_musgo_3", "Musgo de piedra", Vector3(-16.5, 0, -14.5), true],
	["bq_rec_savia_1", "Savia clara", Vector3(19.5, 0, 5.0), false],
	["bq_rec_savia_2", "Savia clara", Vector3(-12.0, 0, -18.5), true],
]
const CLAVE_REC := {"Hierba lunar": "rec_hierba_lunar", "Musgo de piedra": "rec_musgo_piedra", "Savia clara": "rec_savia_clara"}
const COLOR_REC := {"Hierba lunar": Color(0.75, 0.95, 1.0), "Musgo de piedra": Color(0.45, 0.7, 0.35), "Savia clara": Color(1.0, 0.85, 0.45)}

var r                                       # la región (pastos_verdes_3d.gd)
var puntos: Array = []                      # {"id", "nodo", "boton"}
var arbol: Node3D
var runas: Array = []
var ramas: Node3D
var guardian: Node3D
var _t := 0.0
var _bebido := false                        # el manantial, una vez por visita
var _ciervo_visto := false
# 14/11: las dos, para toda la visita (sesión, Engine; sin clave nueva de partida): volver de un combate recarga la
# escena y antes el ciervo volvía a salir y el manantial a curar. Las quita pastos_verdes_3d.gd al salir de la región.
const VISITA := ["bq_visita_bebido", "bq_visita_ciervo"]
var _destellos_pista: Array = []            # lirios, surcos e inscripción: solo brillan cuando ya sirven (bq_arbol)
var _claro_armado := false                  # el Guardián despierta al llegar, no al volver aquí tras el combate
var _aviso_claro := false
var _final_pendiente := ""                  # diálogo del desenlace al volver del combate
var alquimia: Node = null                   # la pantalla de alquimia abierta (alquimia_menu.gd)
var boton_alquimia: Button


static func P():
	return load("res://progreso.gd")


static func activa() -> bool:
	return P().hito("pv_14")


static func pistas() -> int:
	var n := 0
	for h in PISTAS:
		if P().hito(h):
			n += 1
	return n


func preparar(region) -> void:
	r = region
	name = "BosqueQueNoRecuerda"
	_crear_boton_alquimia()
	if not activa():
		return
	_construir.call_deferred()


# ================================================================= construir el escenario de la aventura

func _construir() -> void:
	await get_tree().physics_frame                  # los huecos libres se miran con la física ya lista
	await get_tree().physics_frame
	arbol = _crear_arbol(_sitio(SITIO_ARBOL))
	_punto("arbol", arbol, "Examinar el árbol")
	if not P().hito("bq_resuelto"):
		_punto("lirios", _crear_lirios(_sitio(SITIO_LIRIOS)), "Examinar los lirios")
		_punto("surcos", _crear_surcos(_sitio(SITIO_SURCOS)), "Examinar los surcos")
	if not P().hito("bq_senda"):
		ramas = _crear_ramas(_sitio(SITIO_RAMAS))
		_punto("ramas", ramas, "Mirar las ramas")
	else:
		_crear_senda_abierta()
	for rec in RECOLECCION:
		if P().hito(rec[0]) or (rec[3] and not P().hito("bq_senda")):
			continue
		_punto("rec:" + rec[0], _crear_material(_sitio(rec[2]), rec[1]), "Recoger: " + rec[1])
	_crear_perro_y_huellas()
	_crear_claro()
	_claro_armado = r.kael == null or r._dist_plana(r.kael.global_position, SITIO_CLARO) > RADIO_CLARO
	if P().hito("bq_resuelto") and not P().hito("bq_final_visto"):
		_final_pendiente = "bq_" + B.desenlace()


func _crear_senda_abierta() -> void:
	if not P().hito("bq_resuelto"):
		_punto("inscripcion", _crear_inscripcion(_sitio(SITIO_RUINAS)), "Leer la inscripción")
	else:
		_crear_inscripcion(_sitio(SITIO_RUINAS))
	_punto("manantial", _crear_manantial(_sitio(SITIO_MANANTIAL)), "Beber del manantial")
	if not P().hito("bq_cofre_senda"):
		_punto("cofre_senda", _crear_cofrecito(_sitio(SITIO_COFRE)), "Abrir el cofre")
	_punto("orbe", _crear_altar_orbe(_sitio(SITIO_ORBE)), "Mirar el orbe")
	if P().hito("enc_perro_pedido") and not P().hito("enc_perro_encontrado") and _pos_punto("perro") == Vector3.INF:
		_punto("perro", _crear_perro(_sitio(SITIO_PERRO)), "Coger a Canela")


# Hueco libre más cercano a «c» (fuera del río y de lo prohibido), en el suelo.
func _sitio(c: Vector3) -> Vector3:
	for radio in [0.0, 0.7, 1.4, 2.1, 2.8, 3.5]:
		for k in 8:
			var a := TAU * k / 8.0
			var q: Vector3 = c + Vector3(cos(a), 0, sin(a)) * radio
			q.y = r.altura(q.x, q.z)
			if not r._prohibido(q) and r._hueco_libre(q, 0.45):
				return q
	return Vector3(c.x, r.altura(c.x, c.z), c.z)


func _punto(id: String, nodo: Node3D, boton: String) -> void:
	puntos.append({"id": id, "nodo": nodo, "boton": boton})


func _quitar_punto(id: String) -> void:
	for p in puntos.duplicate():
		if p["id"] == id:
			if is_instance_valid(p["nodo"]):
				p["nodo"].queue_free()
			puntos.erase(p)


# ================================================================= lo que pregunta la región

# {"id", "boton"} de lo que hay al alcance (o {}).
func cerca_de(pos: Vector3) -> Dictionary:
	if not activa():
		return {}
	var mejor := {}
	var dmin := RADIO
	for p in puntos:                                 # el más cercano al alcance
		if not is_instance_valid(p["nodo"]):
			continue
		if p["id"] in ["lirios", "surcos", "inscripcion"] and not P().hito("bq_arbol"):
			continue                                # antes de empezar a investigar, solo son paisaje
		var d: float = r._dist_plana(pos, p["nodo"].global_position)
		if d < dmin:
			dmin = d
			mejor = {"id": p["id"], "boton": p["boton"]}
	return mejor


func ocupado() -> bool:
	return alquimia != null and is_instance_valid(alquimia)


func dialogo_tilo() -> String:
	if not P().hito("bq_inicio"):
		return "bq_tilo_1"
	if not P().hito("bq_resuelto"):
		return "bq_tilo_durante"
	return "bq_tilo_" + B.desenlace()


func texto_objetivo() -> String:
	if not activa():
		return ""
	var Pr = P()
	if not Pr.hito("bq_inicio"):
		return "Habla con Tilo: algo le pasa al árbol de su puesto."
	if not Pr.hito("bq_arbol"):
		return "Examina el árbol marcado."
	if pistas() < 3:
		return T.TEXTOS["objetivo_pistas"] % pistas()
	if not Pr.hito("bq_resuelto"):
		if not Pr.hito("bq_guardian_visto"):
			return "Ve al claro del noreste (Lya puede preparar antes un elixir)."
		return "Enfréntate al Guardián del Bosque."
	var Oak = load("res://ciudades/oakhaven.gd")
	if not Pr.estado(Oak.NOMBRE, "encina_bosque"):
		return "Cuéntaselo a Doña Encina, en Oakhaven."
	return ""


# Cada fotograma (desde _comprobar_mision de la región): el Guardián, el ciervo y el diálogo del desenlace.
func comprobar(pos: Vector3, delta: float) -> void:
	_t += delta
	_animar(delta)
	_actualizar_boton_alquimia()
	if not activa() or r.ocupado() or ocupado():
		return
	if _final_pendiente != "":
		var id := _final_pendiente
		_final_pendiente = ""
		P().poner_hito("bq_final_visto")
		_dialogo(id)
		return
	if P().hito("bq_senda") and not _ciervo_visto and not Engine.get_meta(VISITA[1], false) \
			and r._dist_plana(pos, SITIO_RUINAS) < 7.0:
		_ciervo_visto = true
		Engine.set_meta(VISITA[1], true)
		_ciervo(SITIO_RUINAS + Vector3(2.5, 0, -2.0))
	var d: float = r._dist_plana(pos, SITIO_CLARO)
	if d > RADIO_CLARO + 1.0:
		_claro_armado = true
		_aviso_claro = false
		return
	if d > RADIO_CLARO or not _claro_armado or P().hito("bq_resuelto"):
		return
	if pistas() < 3 or not P().hito("bq_pistas"):
		if not _aviso_claro:
			_aviso_claro = true
			r._mostrar_aviso(T.TEXTOS["guardian_dormido_pronto"], 3.5)
		return
	_claro_armado = false
	P().poner_hito("bq_guardian_visto")
	_dialogo("bq_guardian")


# ================================================================= acciones

func accion(id: String) -> void:
	var Pr = P()
	match id:
		"arbol":
			if Pr.hito("bq_resuelto"):
				r._mostrar_aviso(_texto_arbol_final(), 3.0)
			elif not Pr.hito("bq_inicio"):
				r._mostrar_aviso(T.TEXTOS["arbol_marcado"], 3.0)
			elif not Pr.hito("bq_arbol"):
				_dialogo("bq_arbol")
			else:
				r._mostrar_aviso(T.TEXTOS["arbol_marcado"], 3.0)
		"lirios", "surcos", "inscripcion":
			var h: String = {"lirios": "bq_pista_planta", "surcos": "bq_pista_rastro", "inscripcion": "bq_pista_inscripcion"}[id]
			if Pr.hito(h):
				r._mostrar_aviso("Ya lo habéis examinado.", 1.6)
			else:
				_dialogo(h)
		"ramas":
			if not Pr.hito("bq_pista_rastro"):              # (14/11: qué falta, sin decir dónde está la pista)
				r._mostrar_aviso(T.TEXTOS["ramas_bloqueadas"] + " Antes conviene entender qué le pasa al bosque.", 3.5)
			elif not load("res://grupo.gd").activos().has("Garon"):
				r._mostrar_aviso(T.TEXTOS["ramas_bloqueadas"] + " Pesan demasiado para apartarlas sin Garon.", 3.5)
			else:
				_dialogo("bq_senda")
		"claro":
			r._mostrar_aviso(T.TEXTOS["claro_purificado" if B.desenlace() == "purificado" else "claro_derrotado"], 3.2)
		"orbe":
			_mirar_orbe()
		"huellas_0", "huellas_1":
			if not P().hito("enc_perro_huellas"):
				P().poner_hito("enc_perro_huellas")
				Sonido.efecto("examinar")
			r._mostrar_aviso("Huellas pequeñas de perro. Van hacia el norte, hacia unas ramas caídas." if not P().hito("bq_senda")
				else "Huellas pequeñas de perro. Siguen por la senda, hacia las ruinas.", 3.0)
			_guardar()
		"perro":
			_dialogo("enc_perro")
		"manantial":
			_beber()
		"cofre_senda":
			_abrir_cofrecito()
		_:
			if id.begins_with("rec:"):
				_recoger(id.trim_prefix("rec:"))


func _texto_arbol_final() -> String:
	return "Las runas se han apagado y la corteza vuelve a ser verde." if B.desenlace() == "purificado" \
		else "Las runas se han apagado, pero el árbol sigue gris."


func _dialogo(id: String) -> void:
	if not r._empezar_dialogo(id):
		tras_dialogo(id)                           # sin Dialogic (o con otro abierto), la aventura no se atasca


# Lo que pasa al terminar cada diálogo de la aventura (la región lo llama desde _tras_dialogo).
func tras_dialogo(id: String) -> void:
	var Pr = P()
	match id:
		"bq_tilo_1":
			Pr.poner_hito("bq_inicio")
			_pulso_arbol()
		"bq_arbol":
			Pr.poner_hito("bq_arbol")
			Pr.poner_hito("bq_alquimia")
			r._mostrar_aviso("Lya puede preparar remedios: botón ALQUIMIA.", 3.0)
		"bq_pista_planta", "bq_pista_rastro", "bq_pista_inscripcion":
			Pr.poner_hito(id)
			Sonido.efecto("misterio")
			r._mostrar_aviso("Señales del olvido: %d/3" % pistas(), 2.2)
			if pistas() >= 3 and not Pr.hito("bq_pistas"):
				_dialogo.call_deferred("bq_pistas")
				return
		"bq_pistas":
			Pr.poner_hito("bq_pistas")
			r._mostrar_aviso("Nueva investigación de Lya: «La savia que recuerda».", 3.0)
		"bq_senda":
			Pr.poner_hito("bq_senda")
			_quitar_punto("ramas")
			Sonido.efecto("examinar")
			_crear_senda_abierta()
			for rec in RECOLECCION:
				if rec[3] and not Pr.hito(rec[0]):
					_punto("rec:" + rec[0], _crear_material(_sitio(rec[2]), rec[1]), "Recoger: " + rec[1])
		"bq_purificado", "bq_derrotado":            # V9: se abren los oficios de Kael y Garon
			r._mostrar_aviso("Kael y Garon quieren probar lo aprendido: forja y runas en el menú (Objetos).", 3.6)
		"enc_perro":
			Pr.poner_hito("enc_perro_huellas")
			Pr.poner_hito("enc_perro_encontrado")
			_quitar_punto("perro")
			for k in 2:
				_quitar_punto("huellas_%d" % k)
			_canela_sigue()
			Sonido.efecto("union")
			r._mostrar_aviso("Canela os sigue. Llevádsela a Pip, en Oakhaven.", 3.0)
		"bq_orbe_a":
			Pr.poner_hito("bq_orbe_a")
			_vision(false)
		"bq_orbe_b":
			Pr.poner_hito("bq_orbe_b")
			Pr.poner_hito("bq_futuros")
			_vision(false)
			var I = load("res://investigacion.gd")
			if I.estado("lya_savia") == "en_curso":
				I.avanzar("lya_savia", 1)
			r._mostrar_aviso("Lo que Lya ha visto en el orbe adelanta «La savia que recuerda».", 3.2)
		"bq_guardian":
			r._encuentro(B.COMBATE, GRUPO_GUARDIAN, "¡El Guardián despierta!")
			return
	_guardar()


func _guardar() -> void:
	r.guardar_posicion()
	P().guardar(r.scene_file_path)


func _recoger(id: String) -> void:
	for rec in RECOLECCION:
		if rec[0] != id:
			continue
		if P().hito(id):
			return
		P().poner_hito(id)
		load("res://inventario.gd").agregar_objeto(rec[1], 1)
		_quitar_punto("rec:" + id)
		Sonido.efecto("tesoro")
		r._mostrar_aviso(T.TEXTOS[CLAVE_REC[rec[1]]] + "  (+1)", 2.6)
		_guardar()
		return


func _beber() -> void:
	if _bebido or Engine.get_meta(VISITA[0], false):
		r._mostrar_aviso(T.TEXTOS["manantial_ya"], 2.4)
		return
	_bebido = true
	Engine.set_meta(VISITA[0], true)
	load("res://grupo.gd").curar_todos()
	Sonido.efecto("pocion")
	var texto: String = T.TEXTOS["manantial"]
	if not P().hito("bq_manantial"):                 # la primera vez, hierba lunar de la orilla
		P().poner_hito("bq_manantial")
		load("res://inventario.gd").agregar_objeto("Hierba lunar", 1)
		texto += "  (+1 Hierba lunar)"
	r._mostrar_aviso(texto, 3.0)
	_guardar()


func _abrir_cofrecito() -> void:
	if P().hito("bq_cofre_senda"):
		return
	P().poner_hito("bq_cofre_senda")
	var Inv = load("res://inventario.gd")
	Inv.agregar_objeto(B.ESENCIA, 1)
	Inv.ganar_oro(60)
	_quitar_punto("cofre_senda")
	Sonido.efecto("tesoro")
	r._mostrar_aviso(T.TEXTOS["cofre_senda"] + "  (+1 Esencia de enfoque, +60 monedas)", 3.2)
	_guardar()


# ================================================================= alquimia

func _crear_boton_alquimia() -> void:
	boton_alquimia = Button.new()
	boton_alquimia.text = "ALQUIMIA"
	boton_alquimia.position = Vector2(980, 506)
	boton_alquimia.custom_minimum_size = Vector2(270, 80)
	boton_alquimia.add_theme_font_size_override("font_size", 26)
	boton_alquimia.focus_mode = Control.FOCUS_NONE
	boton_alquimia.visible = false
	boton_alquimia.pressed.connect(abrir_alquimia)
	r._capa_ui.add_child(boton_alquimia)


func puede_alquimia() -> bool:
	return P().hito("bq_alquimia") and load("res://grupo.gd").activos().has("Lya")


func _actualizar_boton_alquimia() -> void:
	if boton_alquimia != null:
		boton_alquimia.visible = puede_alquimia() and not ocupado() and not r.ocupado() and not r.saliendo \
			and not r.cinematica and not r.en_banco()


func abrir_alquimia() -> void:
	if ocupado() or not puede_alquimia():
		return
	r._parar_kael()
	alquimia = load("res://alquimia_menu.gd").new()
	alquimia.cerrado.connect(func():
		alquimia = null
		_guardar())
	r.add_child(alquimia)


# ================================================================= formas (sin modelos de terceros)

func _mat(c: Color, brillo := false) -> StandardMaterial3D:
	return r._mat_simple(c, brillo)


func _crear_arbol(p: Vector3) -> Node3D:
	var resuelto: bool = P().hito("bq_resuelto")
	var purificado: bool = B.desenlace() == "purificado"
	# el mismo árbol de copa con viento que el resto de la región (sendero_puente.gd), de un verde ceniciento mientras el
	# olvido lo marca y verde vivo si se purificó el bosque
	var hojas := Color(0.34, 0.62, 0.26) if purificado else Color(0.6, 0.64, 0.58)
	var n: Node3D = r._arbol_viento(p, 3.8, hojas)
	n.name = "bq_arbol"
	if purificado:                                   # florece
		for k in 7:
			var a := TAU * k / 7.0
			var flor := SphereMesh.new()
			flor.radius = 0.12
			flor.height = 0.2
			r._pieza(n, flor, _mat(Color(1.0, 0.75, 0.85), true), Vector3(cos(a) * 1.0, 3.2 + sin(a * 2.0) * 0.3, sin(a) * 1.0))
	elif not resuelto:                               # runas pálidas que laten
		for k in 4:
			var runa := BoxMesh.new()
			runa.size = Vector3(0.1, 0.22, 0.02)
			var a := TAU * k / 4.0 + 0.4
			var m: MeshInstance3D = r._pieza(n, runa, _mat(Color(0.8, 0.95, 1.0), true), Vector3(cos(a) * 0.27, 1.0 + k * 0.32, sin(a) * 0.27),
				Vector3(0, -rad_to_deg(a) + 90.0, 0))
			runas.append(m)
	return n


func _pulso_arbol() -> void:
	if arbol != null:                               # un destello en las runas (el árbol tiene física: no se escala)
		r._destello(arbol, Vector3(0, 1.6, 0), 0.5)


func _crear_lirios(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_lirios"
	n.position = p
	add_child(n)
	for k in 5:
		var a := TAU * k / 5.0
		var tallo := CylinderMesh.new()
		tallo.top_radius = 0.012
		tallo.bottom_radius = 0.02
		tallo.height = 0.5
		var q := Vector3(cos(a) * 0.25, 0.25, sin(a) * 0.25)
		r._pieza(n, tallo, _mat(Color(0.55, 0.58, 0.55)), q)
		var flor := SphereMesh.new()
		flor.radius = 0.08
		flor.height = 0.12
		r._pieza(n, flor, _mat(Color(0.82, 0.82, 0.84), true), q + Vector3(0, 0.27, 0))   # sin color: ceniza
	if not P().hito("bq_pista_planta"):
		_destellos_pista.append(r._destello(n, Vector3(0, 0.6, 0), 0.35))
	return n


func _crear_surcos(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_surcos"
	n.position = p
	add_child(n)
	for k in 6:                                      # raíces que asoman en fila hacia el oeste (las ruinas)
		var raiz := CapsuleMesh.new()
		raiz.radius = 0.07
		raiz.height = 0.9
		r._pieza(n, raiz, _mat(Color(0.36, 0.27, 0.18)), Vector3(-k * 0.55, 0.05, sin(k * 1.3) * 0.2), Vector3(0, 10.0 * k, 90))
	if not P().hito("bq_pista_rastro"):
		_destellos_pista.append(r._destello(n, Vector3(0, 0.4, 0), 0.35))
	return n


func _crear_ramas(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_ramas"
	n.position = p
	add_child(n)
	for k in 5:
		var rama := CylinderMesh.new()
		rama.top_radius = 0.05
		rama.bottom_radius = 0.09
		rama.height = 1.8
		r._pieza(n, rama, _mat(Color(0.4, 0.3, 0.2)), Vector3(sin(k) * 0.3, 0.3 + k * 0.12, cos(k * 1.7) * 0.3),
			Vector3(15.0 * k, 37.0 * k, 75))
	var hojas := SphereMesh.new()
	hojas.radius = 0.55
	hojas.height = 0.7
	r._pieza(n, hojas, _mat(Color(0.35, 0.45, 0.22)), Vector3(0.3, 0.6, 0))
	return n


func _crear_inscripcion(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_ruinas"
	n.position = p
	add_child(n)
	var losa := BoxMesh.new()
	losa.size = Vector3(1.0, 1.3, 0.25)
	r._pieza(n, losa, _mat(Color(0.62, 0.6, 0.55)), Vector3(0, 0.65, 0))
	for k in 3:                                      # columnas rotas alrededor
		var col := CylinderMesh.new()
		col.top_radius = 0.18
		col.bottom_radius = 0.22
		col.height = 0.6 + k * 0.4
		var a := TAU * k / 3.0 + 0.5
		r._pieza(n, col, _mat(Color(0.66, 0.64, 0.58)), Vector3(cos(a) * 1.6, col.height / 2.0, sin(a) * 1.6))
	if not P().hito("bq_pista_inscripcion"):
		_destellos_pista.append(r._destello(n, Vector3(0, 1.1, 0.2), 0.35))
	return n


func _crear_manantial(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_manantial"
	n.position = p
	add_child(n)
	var borde := CylinderMesh.new()
	borde.top_radius = 0.7
	borde.bottom_radius = 0.75
	borde.height = 0.22
	r._pieza(n, borde, _mat(Color(0.58, 0.56, 0.5)), Vector3(0, 0.11, 0))
	var agua := CylinderMesh.new()
	agua.top_radius = 0.58
	agua.bottom_radius = 0.58
	agua.height = 0.04
	r._pieza(n, agua, _mat(Color(0.45, 0.75, 0.9), true), Vector3(0, 0.22, 0))
	return n


func _crear_cofrecito(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_cofre"
	n.position = p
	add_child(n)
	var caja := BoxMesh.new()
	caja.size = Vector3(0.6, 0.35, 0.4)
	r._pieza(n, caja, _mat(Color(0.5, 0.33, 0.18)), Vector3(0, 0.18, 0))
	var tapa := BoxMesh.new()
	tapa.size = Vector3(0.62, 0.1, 0.42)
	r._pieza(n, tapa, _mat(Color(0.85, 0.68, 0.3)), Vector3(0, 0.4, 0))
	r._destello(n, Vector3(0, 0.6, 0), 0.4)
	return n


func _crear_material(p: Vector3, que: String) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_material"
	n.position = p
	add_child(n)
	var c: Color = COLOR_REC[que]
	match que:
		"Hierba lunar":
			for k in 4:
				var hoja := CylinderMesh.new()
				hoja.top_radius = 0.005
				hoja.bottom_radius = 0.03
				hoja.height = 0.35
				r._pieza(n, hoja, _mat(c, true), Vector3(cos(k * 1.6) * 0.07, 0.17, sin(k * 1.6) * 0.07), Vector3(cos(k) * 15, 0, sin(k) * 15))
		"Musgo de piedra":
			var roca := SphereMesh.new()
			roca.radius = 0.32
			roca.height = 0.4
			r._pieza(n, roca, _mat(Color(0.55, 0.55, 0.52)), Vector3(0, 0.15, 0))
			var musgo := SphereMesh.new()
			musgo.radius = 0.22
			musgo.height = 0.16
			r._pieza(n, musgo, _mat(c), Vector3(0, 0.33, 0))
		"Savia clara":
			var gota := SphereMesh.new()
			gota.radius = 0.09
			gota.height = 0.16
			r._pieza(n, gota, _mat(c, true), Vector3(0, 0.9, 0))
			var cuenco := CylinderMesh.new()
			cuenco.top_radius = 0.14
			cuenco.bottom_radius = 0.1
			cuenco.height = 0.12
			r._pieza(n, cuenco, _mat(Color(0.45, 0.32, 0.2)), Vector3(0, 0.06, 0))
	r._destello(n, Vector3(0, 0.5, 0), 0.3)
	return n


# El claro del noreste: el Guardián dormido (su modelo 3D si existe; si no, formas), o lo que queda tras el desenlace.
func _crear_claro() -> void:
	var p := _sitio(SITIO_CLARO)
	var n := Node3D.new()
	n.position = p
	add_child(n)
	# el Claro del Guardián (V9, gráficos: zonas3d/bosque/claro_guardian.gd): menhires, raíces y tocón-trono, según el estado
	if ResourceLoader.exists("res://zonas3d/bosque/claro_guardian.gd"):
		load("res://zonas3d/bosque/claro_guardian.gd").crear(r, p, B.desenlace() if P().hito("bq_resuelto") else "dormido", self)
	if P().hito("bq_resuelto"):
		n.name = "bq_claro_" + B.desenlace()
		_punto("claro", n, "Examinar el claro")
		return
	n.name = "bq_guardian_dormido"
	guardian = n
	var guion := "res://enemigos/guardian_bosque/guardian_bosque_3d.gd"   # su modelo 3D (animaciones, Blender)
	if ResourceLoader.exists(guion) and ResourceLoader.exists("res://enemigos/guardian_bosque/guardian_bosque.glb"):
		var g = load(guion).new()
		g.dormido_al_empezar = true                    # arrodillado, con el musgo del sueño y el corazón tenue
		n.add_child(g)
		n.rotation.y = PI * 0.75                         # mira hacia el camino
		return
	var tronco := CylinderMesh.new()                 # sin modelo: un gigante de madera arrodillado, cubierto de musgo
	tronco.top_radius = 0.55
	tronco.bottom_radius = 0.8
	tronco.height = 2.2
	r._pieza(n, tronco, _mat(Color(0.38, 0.29, 0.2)), Vector3(0, 1.1, 0), Vector3(12, 0, 0))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.5
	cabeza.height = 0.8
	r._pieza(n, cabeza, _mat(Color(0.33, 0.45, 0.25)), Vector3(0, 2.4, 0.25))
	var corazon := SphereMesh.new()
	corazon.radius = 0.16
	corazon.height = 0.3
	r._pieza(n, corazon, _mat(Color(0.75, 1.0, 0.45), true), Vector3(0, 1.4, 0.6))
	for k in 2:
		var brazo := CylinderMesh.new()
		brazo.top_radius = 0.1
		brazo.bottom_radius = 0.2
		brazo.height = 1.6
		r._pieza(n, brazo, _mat(Color(0.36, 0.27, 0.18)), Vector3(-0.8 + 1.6 * k, 1.1, 0.4), Vector3(30, 0, -25 + 50 * k))


func _crear_manantial_claro() -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(1.4, 0, 0.6)
	var agua := CylinderMesh.new()
	agua.top_radius = 0.5
	agua.bottom_radius = 0.5
	agua.height = 0.04
	var mi := MeshInstance3D.new()
	mi.mesh = agua
	mi.material_override = _mat(Color(0.5, 0.8, 0.95), true)
	mi.position = Vector3(0, 0.05, 0)
	n.add_child(mi)
	return n


# El ciervo de niebla: aparece, mira y se deshace (acontecimiento sin combate).
func _ciervo(p: Vector3) -> void:
	var n := Node3D.new()
	n.name = "bq_ciervo"
	p.y = r.altura(p.x, p.z)
	n.position = p
	add_child(n)
	var mat := _mat(Color(0.88, 0.92, 1.0), true)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.0
	var cuerpo := CapsuleMesh.new()
	cuerpo.radius = 0.22
	cuerpo.height = 1.0
	var c: MeshInstance3D = r._pieza(n, cuerpo, mat, Vector3(0, 0.9, 0), Vector3(0, 0, 90))
	var cuello := CapsuleMesh.new()
	cuello.radius = 0.09
	cuello.height = 0.6
	r._pieza(n, cuello, mat, Vector3(0.45, 1.25, 0), Vector3(0, 0, 30))
	for k in 4:
		var pata := CylinderMesh.new()
		pata.top_radius = 0.035
		pata.bottom_radius = 0.03
		pata.height = 0.7
		r._pieza(n, pata, mat, Vector3(-0.3 + 0.6 * (k % 2), 0.35, -0.12 + 0.24 * int(k / 2.0)))
	r._mostrar_aviso(T.TEXTOS["ciervo"], 3.2)
	Sonido.efecto("misterio")
	var t := create_tween()
	t.tween_property(mat, "albedo_color:a", 0.55, 0.8)
	t.tween_interval(1.6)
	t.parallel().tween_property(n, "position:x", p.x + 1.5, 2.4)
	t.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	t.tween_callback(n.queue_free)
	if c == null:
		return


func _animar(_delta: float) -> void:
	animar_orbe()
	var sirven: bool = P().hito("bq_arbol")
	for d in _destellos_pista:
		if is_instance_valid(d):
			d.visible = sirven
	_animar_canela(_delta)
	for m in runas:                                  # las runas laten
		if is_instance_valid(m):
			m.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 3.0))
	if guardian != null and is_instance_valid(guardian) and guardian.get_child_count() > 0 \
			and not ResourceLoader.exists("res://enemigos/guardian_bosque/guardian_bosque.glb"):
		guardian.rotation.x = deg_to_rad(sin(_t * 0.8) * 1.5)   # respira, dormido


# ================================================================= el orbe del altar (V9: «los futuros que nunca existieron»)
# Propuesta experimental, pendiente de canon: el orbe de los altares (zona.gd, _adornar_altar) no tenía función. Aquí, en
# las ruinas de la senda, muestra dos futuros del bosque que aún no han pasado: el que llega si el Guardián se purifica
# (bq_orbe_a) y el que llega si cae (bq_orbe_b). Verlos los dos (bq_futuros) adelanta un paso la investigación de Lya.
# Sin universos paralelos: dos diálogos y un tinte de pantalla.
var orbe: MeshInstance3D
var _velo: ColorRect


func _mirar_orbe() -> void:
	var Pr = P()
	if Pr.hito("bq_resuelto"):
		r._mostrar_aviso("El orbe ya no muestra dos caminos: solo el bosque tal como es ahora.", 3.0)
		return
	if not Pr.hito("bq_orbe_a"):
		_vision(true, Color(0.75, 1.0, 0.55, 0.22))
		_dialogo("bq_orbe_a")
	elif not Pr.hito("bq_orbe_b"):
		_vision(true, Color(0.55, 0.55, 0.6, 0.32))
		_dialogo("bq_orbe_b")
	else:
		r._mostrar_aviso("El orbe late despacio. Los dos futuros siguen ahí, esperando.", 2.6)


# El velo de color sobre la pantalla mientras dura la visión.
func _vision(si: bool, c := Color.TRANSPARENT) -> void:
	if si:
		Sonido.efecto("orbe_vision")                   # V9: la resonancia cristalina de la visión (sonido.gd)
		if _velo == null:
			_velo = ColorRect.new()
			_velo.size = Vector2(1280, 720)
			_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r._capa_ui.add_child(_velo)
			r._capa_ui.move_child(_velo, 0)          # debajo de los botones y del diálogo
		_velo.color = Color(c, 0.0)
		create_tween().tween_property(_velo, "color:a", c.a, 0.8)
	elif _velo != null:
		Sonido.efecto("orbe_cierra")                   # V9: la visión se cierra (sonido.gd)
		var v := _velo
		_velo = null
		var t := create_tween()
		t.tween_property(v, "color:a", 0.0, 0.8)
		t.tween_callback(v.queue_free)


func _crear_altar_orbe(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_altar_orbe"
	n.position = p
	add_child(n)
	var base := CylinderMesh.new()
	base.top_radius = 0.35
	base.bottom_radius = 0.45
	base.height = 0.9
	base.radial_segments = 8
	r._pieza(n, base, _mat(Color(0.6, 0.58, 0.54)), Vector3(0, 0.45, 0))
	var losa := CylinderMesh.new()
	losa.top_radius = 0.5
	losa.bottom_radius = 0.5
	losa.height = 0.08
	losa.radial_segments = 8
	r._pieza(n, losa, _mat(Color(0.66, 0.64, 0.6)), Vector3(0, 0.94, 0))
	var esfera := SphereMesh.new()
	esfera.radius = 0.22
	esfera.height = 0.44
	orbe = r._pieza(n, esfera, _mat(Color(0.8, 1.0, 0.7), true), Vector3(0, 1.45, 0))
	if not P().hito("bq_futuros"):
		r._destello(n, Vector3(0, 1.45, 0), 0.5)
	return n


func animar_orbe() -> void:
	if orbe != null and is_instance_valid(orbe):
		orbe.position.y = 1.45 + 0.08 * sin(_t * 1.6)
		orbe.rotation.y = _t * 0.6


# ================================================================= encargo «Canela se ha perdido» (V9)
# Pip lo pide en Oakhaven (ciudades/oakhaven.gd, señal oak:pip_perro). Aquí: dos rastros de huellas en el camino que
# llevan a las ramas; tras abrir la senda (Garon), Canela en las ruinas; al encontrarla os sigue por la región.
var canela: Node3D


func _crear_perro_y_huellas() -> void:
	var Pr = P()
	if not Pr.hito("enc_perro_pedido") or Pr.hito("enc_perro_encontrado"):
		if Pr.hito("enc_perro_encontrado") and not Pr.hito("enc_perro_devuelto"):
			_canela_sigue()
		return
	for k in SITIOS_HUELLAS.size():
		_punto("huellas_%d" % k, _crear_huellas(_sitio(SITIOS_HUELLAS[k])), "Examinar las huellas")
	if Pr.hito("bq_senda") and _pos_punto("perro") == Vector3.INF:
		_punto("perro", _crear_perro(_sitio(SITIO_PERRO)), "Coger a Canela")


func _pos_punto(id: String) -> Vector3:
	for p in puntos:
		if p["id"] == id and is_instance_valid(p["nodo"]):
			return p["nodo"].global_position
	return Vector3.INF


func _crear_huellas(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_huellas"
	n.position = p
	add_child(n)
	for k in 5:                                      # pisadas en fila hacia el norte
		var pata := CylinderMesh.new()
		pata.top_radius = 0.05
		pata.bottom_radius = 0.05
		pata.height = 0.01
		r._pieza(n, pata, _mat(Color(0.32, 0.24, 0.16)), Vector3(0.12 * (k % 2) - 0.06, 0.02, -k * 0.3))
	r._destello(n, Vector3(0, 0.3, 0), 0.25)
	return n


func _crear_perro(p: Vector3, brillo := true) -> Node3D:
	var n := Node3D.new()
	n.name = "bq_canela"
	n.position = p
	add_child(n)
	var pelo := _mat(Color(0.78, 0.52, 0.28))
	var cuerpo := CapsuleMesh.new()
	cuerpo.radius = 0.13
	cuerpo.height = 0.5
	r._pieza(n, cuerpo, pelo, Vector3(0, 0.3, 0), Vector3(90, 0, 0))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.11
	cabeza.height = 0.2
	r._pieza(n, cabeza, pelo, Vector3(0, 0.45, -0.27))
	for k in 2:                                      # orejas: la izquierda, doblada
		var oreja := BoxMesh.new()
		oreja.size = Vector3(0.05, 0.1, 0.02)
		r._pieza(n, oreja, _mat(Color(0.6, 0.38, 0.2)), Vector3(-0.06 + 0.12 * k, 0.56 if k == 1 else 0.52, -0.27),
			Vector3(0 if k == 1 else 60, 0, 0))
	for k in 4:
		var pata := CylinderMesh.new()
		pata.top_radius = 0.025
		pata.bottom_radius = 0.025
		pata.height = 0.2
		r._pieza(n, pata, pelo, Vector3(-0.07 + 0.14 * (k % 2), 0.1, -0.15 + 0.3 * int(k / 2.0)))
	var cola := CylinderMesh.new()
	cola.top_radius = 0.01
	cola.bottom_radius = 0.03
	cola.height = 0.22
	r._pieza(n, cola, pelo, Vector3(0, 0.4, 0.28), Vector3(-40, 0, 0))
	if brillo:
		r._destello(n, Vector3(0, 0.7, 0), 0.3)
	return n


# Canela sigue a Kael por la región hasta devolvérsela a Pip.
func _canela_sigue() -> void:
	if canela != null and is_instance_valid(canela):
		return
	var p: Vector3 = r.kael.global_position if r.kael != null else Vector3.ZERO
	canela = _crear_perro(p + Vector3(1.0, 0, 1.0), false)


func _animar_canela(delta: float) -> void:
	if canela == null or not is_instance_valid(canela) or r.kael == null:
		return
	var objetivo: Vector3 = r.kael.global_position + Vector3(0.9, 0, 0.9)
	var d := canela.global_position.distance_to(objetivo)
	if d > 12.0:
		canela.global_position = objetivo                  # tras un salto grande (recolocación), a su lado
	elif d > 0.4:
		var q := canela.global_position.move_toward(objetivo, delta * 4.5)
		q.y = r.altura(q.x, q.z)
		canela.look_at(Vector3(objetivo.x, q.y, objetivo.z), Vector3.UP, true)
		canela.global_position = q
