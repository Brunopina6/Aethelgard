extends SceneTree
# La Garganta del Diablo 3D por defecto, con lo que la 2D da al explorar (V12, migración región a región, 12/11).
# Sin ventana, con «-- 3d sin_prologo» (SIN «garganta3d»: se comprueba que ya no hace falta). Partida propia
# (user://prueba_garganta3d_examinables.save) y un user://ajustes.cfg que se crea y se borra (datos aislados).
#   0. Elegir 2D o 3D (modo3d.gd, POR_DEFECTO_2D_ELEGIBLE): con la exploración 3D, la 3D por defecto; «garganta2d» o
#      [regiones] garganta3d = false en Ajustes (quien eligió la 2D), la 2D; true, la 3D. Sin la exploración 3D, nunca.
#      Partidas: una guardada en la 2D abre la 3D; una guardada en la 3D con la 2D elegida abre la 2D por su entrada.
#      El resto del archivo de ajustes no se toca.
#   1. El Báculo del Peregrino (hallazgos.gd, «hall_baculo_peregrino»): se ve junto al pilar; al examinar el pilar,
#      después del texto del detalle, su aviso y el arma a «equipables», una sola vez; el báculo desaparece; la partida
#      guardada lo lleva; al volver a entrar ya no está; examinar otra vez no da nada.
#   2. Compatible con la 2D: encontrado en la 2D, en la 3D no sale; encontrado en la 3D, la 2D (garganta.tscn, el pilar)
#      no lo da otra vez.
#   3. Las notas (dialogos/notas/garganta.gd): las cuatro con su objeto y su destello; al lado, «Examinar»; al pulsar,
#      su texto, al Diario una sola vez («lore_visto»), se apaga el destello y se guarda; al volver a entrar, sin
#      destello; los botones de siempre (pilar, ascensores, palanca, guardados) siguen donde estaban.
#   4. El brazalete: brilla (sonido y destello en la muñeca) cerca de un detalle sin ver, una vez hasta alejarse, no desde
#      la otra cornisa ni con el detalle ya visto (zona.gd, _brazalete).
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const REGION := "res://zonas3d/garganta_3d.tscn"
const GARGANTA_2D := "res://garganta.tscn"
const ARCHIVO := "user://prueba_garganta3d_examinables.save"
const AJUSTES := "user://ajustes.cfg"
const ID := "hall_baculo_peregrino"
const JUNTO_PILAR := Vector3(11.4, -8.0, -31.0)       # a 1,6 m del pilar y lejos de las cintas

var P
var R
var M3
var H
var T
var NG
var fallos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for k in ["pos_3d", "pos_3d_ok", "pos_3d_lugar", "pos_zona", "pos_zona_ok", "pos_zona_lugar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	load("res://grupo.gd").empezar_solo()


func _equipables() -> Array:
	return load("res://inventario.gd").datos()["equipables"]


func _probar() -> void:
	P = load("res://progreso.gd")
	R = root.get_node("Recursos")
	M3 = load("res://modo3d.gd")
	H = load("res://hallazgos.gd")
	T = load("res://zonas3d/garganta/trazado.gd")
	NG = load("res://dialogos/notas/garganta.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	_elegir()
	await _baculo()
	await _compatible_2d()
	await _notas()
	await _brazalete()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= 0. 2D o 3D

func _ajuste(valor) -> void:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		c.load(AJUSTES)
	if valor == null:
		if c.has_section_key("regiones", "garganta3d"):
			c.erase_section_key("regiones", "garganta3d")
	else:
		c.set_value("regiones", "garganta3d", valor)
	c.set_value("audio", "Musica", 63)                  # algo que no es suyo: no se toca
	c.save(AJUSTES)


func _elegir() -> void:
	if "garganta3d" in OS.get_cmdline_user_args():
		_fallo("0: esta prueba va sin «garganta3d» (lista_pruebas.txt)")
	if not M3.activo():
		_fallo("0: la exploración 3D no está activa (falta «-- 3d»)")
		return
	var casos := [[PackedStringArray(["3d"]), false, true, "con «-- 3d» (por defecto)"],
		[PackedStringArray([]), true, true, "en la APK experimental (rebelum3d) sin argumento"],
		[PackedStringArray([]), false, false, "sin la exploración 3D"],
		[PackedStringArray(["garganta3d"]), false, false, "con «garganta3d» pero sin la exploración 3D"],
		[PackedStringArray(["3d", "garganta2d"]), false, false, "con «garganta2d»"],
		[PackedStringArray(["3d", "garganta2d", "garganta3d"]), false, true, "con «garganta2d» y «garganta3d»"]]
	for c in casos:
		if M3.region_activa_con(2, c[0], c[1]) != c[2]:
			_fallo("0: la Garganta 3D %s debería estar %s" % [c[3], "activa" if c[2] else "apagada (va la 2D)"])
	if M3.EN_PRUEBAS.has(M3.GARGANTA):
		_fallo("0: la Garganta sigue en EN_PRUEBAS")
	for k in [M3.MAR_CRISTAL]:                             # las demás regiones en pruebas, como estaban (Oakhaven va
	                                                       # por defecto desde el 12/11: prueba_oakhaven3d_completo)
		if M3.region_activa_con(k, PackedStringArray(["3d"]), false):
			_fallo("0: la región %d ya no está en pruebas" % k)
	if FileAccess.file_exists(AJUSTES):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	if M3.eleccion("garganta3d") != null or M3.escena_de(2) != REGION:
		_fallo("0: sin ajustes, el mapa no lleva a la 3D (%s)" % M3.escena_de(2))
	_ajuste(false)                                         # quien eligió la 2D la conserva
	if M3.region_activa(2) or M3.escena_de(2) != "":
		_fallo("0: con «2D (la de siempre)» elegida, el mapa lleva a la 3D")
	var r: String = P.restaurar({"escena_guardada": REGION, "lugar": {"indice": 2, "nombre": "Garganta del Diablo"}})
	if r != GARGANTA_2D or Engine.get_meta("pos_zona_ok", true):
		_fallo("0: con la 2D elegida, una partida guardada en la 3D abre «%s» (debería abrir la 2D por su entrada)" % r)
	var c := ConfigFile.new()
	c.load(AJUSTES)
	if c.get_value("audio", "Musica", 0) != 63:
		_fallo("0: elegir la Garganta toca otros ajustes")
	_ajuste(true)
	if not M3.region_activa(2):
		_fallo("0: con la 3D elegida, va la 2D")
	_ajuste(null)
	if not M3.region_activa(2):
		_fallo("0: sin elección (clave quitada), va la 2D")
	r = P.restaurar({"escena_guardada": GARGANTA_2D, "lugar": {"indice": 2, "nombre": "Garganta del Diablo"},
		"pos_zona": T.ANCLAS[0][0] * 64.0, "pos_zona_ok": true, "pos_zona_lugar": 2})
	if r != REGION:
		_fallo("0: una partida guardada en la 2D no abre la 3D por defecto (%s)" % r)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	_limpiar()
	print("OK 0: 3D por defecto, 2D elegible y partidas de las dos (%d fallos)" % fallos.size())


# ================================================================= escenas

func _abrir(escena: String) -> Variant:
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)
	if escena == GARGANTA_2D:
		var l: Dictionary = load("res://mapa.gd").LUGARES[2]
		Engine.set_meta("lugar", {"indice": 2, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "garganta", "texto": l["texto"]})
	var vieja: int = current_scene.get_instance_id() if current_scene != null else 0
	change_scene_to_file(escena)
	var listo := func():
		if current_scene == null or current_scene.get_instance_id() == vieja or current_scene.scene_file_path != escena or R.cambiando:
			return false
		return current_scene.get("kael") != null if escena == REGION else current_scene.get("jugador") != null
	if not await _hasta(listo, 120.0):
		_fallo("no se abre %s" % escena)
		return null
	await _esperar(10)
	var z = current_scene
	if escena == REGION:
		z.pasos = -100000                                  # sin encuentros al azar durante la prueba
	return z


func _junto(r, p: Vector3) -> String:
	r._colocar_kael(p)
	r._ultima = p
	r._bloqueo = 0.0
	r._comprobar_cerca()
	return r.cerca


# ================================================================= 1. el Báculo del Peregrino

func _baculo() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	if r.baculo == null or not is_instance_valid(r.baculo) or r.get_node_or_null("BaculoPeregrino") == null:
		_fallo("1: el báculo no está junto al pilar")
	elif r.baculo.global_position.distance_to(T.PILAR_PEREGRINO) > 0.1:
		_fallo("1: el báculo no está en el pilar (%s)" % r.baculo.global_position)
	if "baculo_peregrino" in _equipables():
		_fallo("1: el báculo ya está en el equipo al empezar")
	if _junto(r, JUNTO_PILAR) != "detalle_p8" or r.boton_accion.text != "Examinar":
		_fallo("1: junto al pilar no sale «Examinar» (cerca = «%s»)" % r.cerca)
		return
	r._accion()
	if not H.encontrado(ID) or not "baculo_peregrino" in _equipables():
		_fallo("1: examinar el pilar no da el Báculo del Peregrino")
	var guardada = P.leer(ARCHIVO)
	if guardada == null or not guardada.get("cofres_abiertos", {}).has(ID) \
			or not "baculo_peregrino" in guardada.get("inventario", {}).get("equipables", []):
		_fallo("1: la partida guardada no lleva el báculo")
	var texto: String = H.hallazgo(ID)["texto"]
	if r.aviso.text == texto:
		_fallo("1: el aviso del báculo tapa el texto del pilar")
	if not await _hasta(func(): return r.aviso.text == texto, 30.0):
		_fallo("1: no sale el aviso del báculo (sale «%s»)" % r.aviso.text)
	if not await _hasta(func(): return r.aviso.text != texto and r.aviso.text.find("Báculo del Peregrino") >= 0, 30.0):
		_fallo("1: no sale lo que se consigue (sale «%s»)" % r.aviso.text)
	if r.baculo != null or not await _hasta(func(): return r.get_node_or_null("BaculoPeregrino") == null, 10.0):
		_fallo("1: el báculo sigue junto al pilar tras cogerlo")
	var n: int = _equipables().count("baculo_peregrino")
	_junto(r, JUNTO_PILAR)
	r._accion()
	await _esperar(5)
	if _equipables().count("baculo_peregrino") != n:
		_fallo("1: examinar el pilar otra vez da otro báculo")
	r = await _abrir(REGION)                               # salir y volver a entrar
	if r != null and (r.baculo != null or r.get_node_or_null("BaculoPeregrino") != null):
		_fallo("1: al volver a entrar, el báculo vuelve a estar")
	print("OK 1: el Báculo del Peregrino, una vez, guardado (%d fallos)" % fallos.size())


# ================================================================= 2. compatible con la 2D

func _compatible_2d() -> void:
	_limpiar()
	Engine.set_meta("cofres_abiertos", {ID: true})        # encontrado en la 2D
	var r = await _abrir(REGION)
	if r == null:
		return
	if r.baculo != null:
		_fallo("2: encontrado en la 2D, en la 3D sigue el báculo")
	_junto(r, JUNTO_PILAR)
	r._accion()
	await _esperar(5)
	if "baculo_peregrino" in _equipables():
		_fallo("2: encontrado en la 2D, la 3D lo vuelve a dar")
	# encontrado en la 3D: la 2D no lo da otra vez
	_limpiar()
	r = await _abrir(REGION)
	if r == null:
		return
	_junto(r, JUNTO_PILAR)
	r._accion()
	await _esperar(5)
	if not H.encontrado(ID):
		_fallo("2: no se encuentra en la 3D")
	var n: int = _equipables().count("baculo_peregrino")
	var z = await _abrir(GARGANTA_2D)
	if z == null:
		return
	var det = null
	for d in z.detalles:
		if d[1]["id"] == "garganta_pilar":
			det = d
	if det == null:
		_fallo("2: la Garganta 2D no pone el pilar")
		return
	z.jugador.position = det[0].position + Vector2(30, 24)
	await _esperar(3)
	z._comprobar_cerca()
	z._accion()
	await _esperar(10)
	if _equipables().count("baculo_peregrino") != n:
		_fallo("2: encontrado en la 3D, la 2D lo vuelve a dar")
	print("OK 2: el báculo vale en la 2D y en la 3D (%d fallos)" % fallos.size())


# ================================================================= 3. las notas

func _notas() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	if r.notas.size() != NG.NOTAS.size():
		_fallo("3: %d notas en la Garganta 3D (los datos tienen %d)" % [r.notas.size(), NG.NOTAS.size()])
	for n in r.notas:
		var id: String = n["datos"]["id"]
		var brillo = n["brillo"]
		if brillo == null or not is_instance_valid(brillo):
			_fallo("3: %s no tiene destello sin leer" % id)
		# se llega andando: un sitio que se pisa a menos de su radio (la nota puede estar al borde, fuera del paso)
		var p: Vector3 = n["pos"]
		var pie = null
		for k in 48:
			var q: Vector3 = p + Vector3(cos(k * 0.79), 0, sin(k * 0.79)) * (0.3 + 0.1 * floorf(k / 4.0))
			if T.andable(q, false) and Vector2(q.x - p.x, q.z - p.z).length() < NG.RADIO - 0.3:
				pie = q
				break
		if pie == null:
			_fallo("3: a %s no se llega andando (%s)" % [id, p])
			continue
		if _junto(r, pie) != "nota:" + id or r.boton_accion.text != "Examinar":
			_fallo("3: junto a %s sale «%s»" % [id, r.cerca])
			continue
		r._accion()
		if r.aviso.text != n["datos"]["texto"]:
			_fallo("3: %s no enseña su texto (sale «%s»)" % [id, r.aviso.text])
		if not P.visto(id) or n["brillo"] != null:
			_fallo("3: %s no queda leída o no se apaga su destello" % id)
		if P.ver_nota(id):
			_fallo("3: %s cuenta dos veces" % id)
		var g = P.leer(ARCHIVO)
		if g == null or not g.get("lore_visto", {}).has(id):
			_fallo("3: la partida guardada no lleva %s" % id)
		await _esperar(4)
	# los botones de siempre siguen donde estaban
	for c in [["detalle_p8", JUNTO_PILAR], ["ascensor_arriba", T.ASCENSOR_ARRIBA], ["ascensor_abajo", T.ASCENSOR_ABAJO],
			["palanca", T.PALANCA], ["guardado_1", T.GUARDADO_1], ["guardado_2", T.GUARDADO_2], ["detalle_p2", T.DETALLE_PUENTES]]:
		if _junto(r, c[1]) != c[0]:
			_fallo("3: junto a «%s» sale «%s»" % [c[0], r.cerca])
	r = await _abrir(REGION)
	if r != null:
		for n in r.notas:
			if n["brillo"] != null:
				_fallo("3: al volver a entrar, %s sigue con destello" % n["datos"]["id"])
	print("OK 3: las notas de la Garganta 3D (%d fallos)" % fallos.size())


# ================================================================= 4. el brazalete (la pista de la 2D, zona.gd)

func _brillos(r) -> int:
	var n := 0
	for c in r.kael.get_children():
		if str(c.name).begins_with("BrilloBrazalete") and not c.is_queued_for_deletion():
			n += 1
	return n


func _brazalete() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	var cerca := Vector3(-12.0, 0.0, 13.0)               # a 3,4 m de los pilares de los puentes (sin ver)
	_junto(r, cerca)
	r._brazalete()
	if not r.brillados.has("garganta_puentes") or _brillos(r) != 1:
		_fallo("4: cerca de los pilares sin ver, el brazalete no brilla")
	r._brazalete()
	if _brillos(r) != 1:
		_fallo("4: el brazalete brilla otra vez sin alejarse")
	_junto(r, Vector3(-12.0, 0.0, 30.0))                  # lejos: se vuelve a armar
	r._brazalete()
	if r.brillados.has("garganta_puentes"):
		_fallo("4: al alejarse no se vuelve a armar")
	_junto(r, Vector3(11.0, -8.0, 12.0))                  # debajo, en la cornisa baja: no cuenta
	r._brazalete()
	if r.brillados.has("garganta_puentes"):
		_fallo("4: brilla desde la cornisa de abajo")
	Engine.set_meta("lore_visto", {"garganta_puentes": true})
	await _esperar(40)
	_junto(r, cerca)
	r._brazalete()
	if r.brillados.has("garganta_puentes") or _brillos(r) != 0:
		_fallo("4: brilla junto a un detalle ya visto")
	print("OK 4: el brazalete brilla cerca de un detalle sin ver (%d fallos)" % fallos.size())
