extends SceneTree
# El Gran Bosque Verde 3D (V12, migración región a región, 12/11): que tiene todo lo de la 2D (zona.gd, lugar 1) y que las
# partidas valen en las dos. Sin ventana, con «-- 3d sin_prologo». Partida propia (user://prueba_gran_bosque3d.save) y un
# user://ajustes.cfg que se crea y se borra (datos aislados).
#   0. Los datos: zonas3d/gran_bosque/disposicion_2d.gd sigue siendo lo que genera zona.gd (caminos, rincones, puentes,
#      cofres con sus ids, objetos y máscaras de agua, muros y camino).
#   1. 3D por defecto y 2D elegible (modo3d.gd, POR_DEFECTO_2D_ELEGIBLE; Ajustes «granbosque3d» y «granbosque2d»).
#   2. Partidas: una de la 2D (zona.tscn y el lugar 1) abre la 3D en la misma casilla; una de la 3D con la 2D elegida
#      abre la 2D en una casilla donde se puede estar; las de otros lugares (Oakhaven generada, Sunken City), como antes.
#      Y cada sitio andable de una sale andable en la otra.
#   3. Entrar: Kael en la entrada sobre el suelo, el lugar y la zona en Engine, el ambiente «bosque», el grupo.
#   4. Los tres cofres de los rincones con su id de la 2D y el MISMO premio que la 2D (abierto en una, abierto en la otra).
#   5. El Diente de Grimfang (cofre del hallazgo, junto al campamento), una vez.
#   6. El detalle «bosque_armadura»: el brazalete brilla cerca; al examinarlo, su texto, al Diario y la Hoja sin Nombre
#      (una vez, guardada, desaparece de entre las raíces); encontrada en la 2D, en la 3D no está.
#   7. El altar: el texto del lugar.
#   8. Encuentros: la probabilidad de la 2D (zona «bosque») y el combate con su vuelta al mismo sitio.
#   9. Guardar y cargar en la 3D.
#  10. Recorrido sin caerse: de la entrada al altar por el camino (los dos puentes), los rincones, la rampa del mirador, y
#      puntos al azar: nunca fuera del mundo ni bajo el suelo.
#  11. La salida al mapa.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const REGION := "res://zonas3d/gran_bosque_3d.tscn"
const ZONA_2D := "res://zona.tscn"
const ARCHIVO := "user://prueba_gran_bosque3d.save"
const AJUSTES := "user://ajustes.cfg"
const ID_HOJA := "hall_hoja_sin_nombre"
const ID_DIENTE := "hall_diente_grimfang"
const IDS_COFRES := ["1_3004_2814", "1_1339_2335", "1_1541_1723"]   # zona.gd, lugar 1 (el volcado del 12/11)

var P
var R
var M3
var H
var T
var D
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
	for k in ["pos_3d", "pos_3d_ok", "pos_3d_lugar", "pos_zona", "pos_zona_ok", "pos_zona_lugar", "lugar", "comentarios_dichos"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	load("res://grupo.gd").empezar_solo()


func _lugar_2d() -> void:
	var l: Dictionary = load("res://mapa.gd").LUGARES[1]
	Engine.set_meta("lugar", {"indice": 1, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "bosque", "texto": l["texto"]})


func _probar() -> void:
	P = load("res://progreso.gd")
	R = root.get_node("Recursos")
	M3 = load("res://modo3d.gd")
	H = load("res://hallazgos.gd")
	T = load("res://zonas3d/gran_bosque/trazado.gd")
	D = load("res://zonas3d/gran_bosque/disposicion_2d.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	_datos()
	_elegir()
	_partidas()
	await _entrar()
	await _cofres()
	await _diente()
	await _detalle()
	await _altar()
	await _encuentro()
	await _guardar_cargar()
	await _recorrido()
	await _salida()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	if FileAccess.file_exists(AJUSTES):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= 0. los datos de la 2D

func _cerca(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.003


func _datos() -> void:
	var d: Dictionary = load("res://pruebas/herramientas/volcar_bosque_2d.gd").datos()
	if d["agua"] != D.AGUA or d["muros"] != D.MUROS or d["camino"] != D.CAMINO:
		_fallo("0: las máscaras (agua, muros, camino) ya no son las de zona.gd: vuelve a volcar (volcar_bosque_2d.gd)")
	if not _cerca(d["meta"], D.META) or d["caminos"].size() != D.CAMINOS.size() or d["puentes"].size() != D.PUENTES.size():
		_fallo("0: el altar, los caminos o los puentes ya no son los de zona.gd")
	else:
		for i in D.CAMINOS.size():
			for k in D.CAMINOS[i].size():
				if not _cerca(d["caminos"][i][k], D.CAMINOS[i][k]):
					_fallo("0: el camino %d ya no es el de zona.gd" % i)
					break
	var ids: Array = d["cofres"].map(func(c): return c[0])
	if ids != IDS_COFRES or D.COFRES.map(func(c): return c[0]) != IDS_COFRES:
		_fallo("0: los ids de los cofres cambian (%s): las partidas con cofres abiertos los perderían" % [ids])
	if d["objetos"].size() != D.OBJETOS.size():
		_fallo("0: zona.gd pone %d objetos y el volcado tiene %d" % [d["objetos"].size(), D.OBJETOS.size()])
	else:
		for i in D.OBJETOS.size():
			if d["objetos"][i][0] != D.OBJETOS[i][0] or not _cerca(d["objetos"][i][1], D.OBJETOS[i][1]):
				_fallo("0: el objeto %d (%s) ya no está donde lo pone zona.gd" % [i, D.OBJETOS[i][0]])
				break
	print("OK 0: la disposición es la de zona.gd (%d fallos)" % fallos.size())


# ================================================================= 1. 3D por defecto, 2D elegible

func _ajuste(valor) -> void:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		c.load(AJUSTES)
	if valor == null:
		if c.has_section_key("regiones", "granbosque3d"):
			c.erase_section_key("regiones", "granbosque3d")
	else:
		c.set_value("regiones", "granbosque3d", valor)
	c.set_value("audio", "Musica", 63)
	c.save(AJUSTES)


func _elegir() -> void:
	if not M3.activo():
		_fallo("1: la exploración 3D no está activa (falta «-- 3d»)")
		return
	var casos := [[PackedStringArray(["3d"]), false, true, "con «-- 3d» (por defecto)"],
		[PackedStringArray([]), true, true, "en la APK experimental (rebelum3d)"],
		[PackedStringArray([]), false, false, "sin la exploración 3D"],
		[PackedStringArray(["3d", "granbosque2d"]), false, false, "con «granbosque2d»"],
		[PackedStringArray(["3d", "granbosque2d", "granbosque3d"]), false, true, "con «granbosque2d» y «granbosque3d»"]]
	for c in casos:
		if M3.region_activa_con(1, c[0], c[1]) != c[2]:
			_fallo("1: el Gran Bosque 3D %s debería estar %s" % [c[3], "activo" if c[2] else "apagado (va la 2D)"])
	if M3.EN_PRUEBAS.has(1):
		_fallo("1: el Gran Bosque está en EN_PRUEBAS")
	if FileAccess.file_exists(AJUSTES):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	if M3.escena_de(1) != REGION:
		_fallo("1: sin ajustes, el mapa no lleva al bosque 3D (%s)" % M3.escena_de(1))
	_ajuste(false)
	if M3.region_activa(1) or M3.escena_de(1) != "":
		_fallo("1: con «2D (la de siempre)» elegida, el mapa lleva al bosque 3D")
	var c := ConfigFile.new()
	c.load(AJUSTES)
	if c.get_value("audio", "Musica", 0) != 63:
		_fallo("1: elegir el bosque toca otros ajustes")
	_ajuste(true)
	if not M3.region_activa(1):
		_fallo("1: con la 3D elegida, va la 2D")
	for i in [2, 0]:                                       # las otras, como estaban
		if not M3.region_activa(i):
			_fallo("1: la región %d ya no va en 3D por defecto" % i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	print("OK 1: 3D por defecto y 2D elegible (%d fallos)" % fallos.size())


# ================================================================= 2. partidas de la 2D y de la 3D

func _partidas() -> void:
	_limpiar()
	var l: Dictionary = load("res://mapa.gd").LUGARES[1]
	var lugar := {"indice": 1, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "bosque", "texto": l["texto"]}
	var claro: Vector2 = T.lugar("claro")
	var r: String = P.restaurar({"escena_guardada": ZONA_2D, "lugar": lugar, "pos_zona": claro * 64.0, "pos_zona_ok": true,
		"pos_zona_lugar": 1})
	if r != REGION:
		_fallo("2: una partida guardada en el bosque 2D no abre el 3D (%s)" % r)
	elif not Engine.get_meta("pos_3d_ok", false) or int(Engine.get_meta("pos_3d_lugar", -1)) != 1 \
			or (Engine.get_meta("pos_3d") as Vector3).distance_to(T.mundo(claro)) > 0.6:
		_fallo("2: la partida de la 2D no entra en la misma casilla (%s)" % Engine.get_meta("pos_3d", null))
	r = P.restaurar({"escena_guardada": ZONA_2D, "lugar": lugar})
	if r != REGION or Engine.get_meta("pos_3d_ok", false):
		_fallo("2: una partida de la 2D sin posición no entra por la entrada del 3D")
	# con la 2D elegida: la partida del 3D abre la 2D, en una casilla donde se puede estar
	_ajuste(false)
	var p3: Vector3 = T.en_mundo(T.lugar("campamento") + Vector2(1.0, 1.0))
	r = P.restaurar({"escena_guardada": REGION, "lugar": lugar, "pos_3d": p3, "pos_3d_ok": true, "pos_3d_lugar": 1})
	if r != ZONA_2D:
		_fallo("2: con la 2D elegida, la partida del 3D abre «%s»" % r)
	elif not Engine.get_meta("pos_zona_ok", false) or int(Engine.get_meta("pos_zona_lugar", -1)) != 1 \
			or int(Engine.get_meta("lugar", {}).get("indice", -1)) != 1:
		_fallo("2: la 2D no sabe en qué casilla del bosque estaba")
	elif (Engine.get_meta("pos_zona") as Vector2).distance_to(T.casilla(p3.x, p3.z) * 64.0) > 200.0:
		_fallo("2: la 2D pone a Kael lejos de donde estaba en el 3D")
	# sin «lugar» en la partida: se pone el del bosque
	Engine.remove_meta("lugar")
	r = P.restaurar({"escena_guardada": REGION, "pos_3d": p3, "pos_3d_ok": true, "pos_3d_lugar": 1})
	if r != ZONA_2D or int(Engine.get_meta("lugar", {}).get("indice", -1)) != 1 or Engine.get_meta("lugar", {}).get("zona", "") != "bosque":
		_fallo("2: sin «lugar» en la partida, la 2D no sabría que es el Gran Bosque")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	# otros lugares de zona.tscn, como antes
	r = P.restaurar({"escena_guardada": ZONA_2D, "lugar": {"indice": 5, "nombre": "Sunken City", "tipo": "ciudad", "zona": "ciudad", "texto": "x"}})
	if r != ZONA_2D:
		_fallo("2: una partida de Sunken City ya no abre zona.tscn (%s)" % r)
	r = P.restaurar({"escena_guardada": ZONA_2D, "lugar": {"indice": 4, "nombre": "Mar de Arena de Calid", "tipo": "lugar", "zona": "desierto", "texto": "x"}})
	if r != ZONA_2D:
		_fallo("2: una partida del Mar de Arena 2D ya no abre zona.tscn (%s)" % r)
	# cada sitio andable de la 2D (camino y rincones) cae en un sitio andable del 3D, y al revés
	var malos := 0
	var muestras := 0
	for cam in D.CAMINOS:
		for i in cam.size() - 1:
			for k in 8:
				var c: Vector2 = cam[i].lerp(cam[i + 1], k / 8.0)
				if c.y > T.ENTRADA_2D.y:
					continue
				muestras += 1
				var p: Vector3 = T.desde_2d(c * 64.0)
				if T.prohibido(p.x, p.z) or absf(p.y - T.altura(p.x, p.z)) > 0.01:
					malos += 1
				var v: Vector2 = T.a_2d(T.en_mundo(c))
				var cv: Vector2 = v / 64.0
				if T.en_agua(cv) or T.muro(cv) or not T.libre_2d(cv):
					malos += 1
	for k in 300:
		var c := Vector2(randf_range(2, D.ANCHO - 2), randf_range(2, D.ALTO - 2))
		var v: Vector2 = T.a_2d(T.en_mundo(c)) / 64.0
		muestras += 1
		if T.en_agua(v) or T.muro(v) or not T.libre_2d(v) or v.y > T.ENTRADA_2D.y + 0.01:
			malos += 1
	if malos > 0:
		_fallo("2: %d de %d posiciones no caen en un sitio andable al pasar de una versión a la otra" % [malos, muestras])
	_limpiar()
	print("OK 2: partidas en los dos sentidos (%d fallos)" % fallos.size())


# ================================================================= escenas

func _abrir(escena: String) -> Variant:
	if escena == ZONA_2D:
		_lugar_2d()
	var vieja: int = current_scene.get_instance_id() if current_scene != null else 0
	change_scene_to_file(escena)
	var listo := func():
		if current_scene == null or current_scene.get_instance_id() == vieja or current_scene.scene_file_path != escena or R.cambiando:
			return false
		return current_scene.get("kael") != null if escena == REGION else current_scene.get("jugador") != null
	if not await _hasta(listo, 120.0):
		_fallo("no se abre %s" % escena)
		return null
	await _esperar(8)
	var z = current_scene
	if escena == REGION:
		z.pasos = -100000                                  # sin encuentros al azar durante la prueba
	return z


func _junto(r, p: Vector3) -> String:
	r._colocar_kael(p)
	r._ultima = r.kael.global_position
	r._bloqueo = 0.0
	r._comprobar_cerca()
	return r.cerca


# ================================================================= 3. entrar

func _entrar() -> void:
	_limpiar()
	Engine.set_meta("pos_3d_ok", false)
	var r = await _abrir(REGION)
	if r == null:
		return
	var k: Vector3 = r.kael.global_position
	if k.distance_to(T.en_mundo(T.ENTRADA_2D)) > 0.5:
		_fallo("3: Kael no empieza en la entrada (%s)" % k)
	if absf(k.y - T.altura(k.x, k.z)) > 0.2:
		_fallo("3: Kael no está sobre el suelo (%.2f frente a %.2f)" % [k.y, T.altura(k.x, k.z)])
	if Engine.get_meta("zona", "") != "bosque" or int(Engine.get_meta("lugar", {}).get("indice", -1)) != 1:
		_fallo("3: el combate y la 2D no sabrían que es el bosque (zona «%s», lugar %s)" % [Engine.get_meta("zona", ""), Engine.get_meta("lugar", {})])
	var mus = root.get_node_or_null("Musica")
	if mus != null and not await _hasta(func(): return mus.contexto == "bosque", 10.0):
		_fallo("3: no suena el ambiente del bosque (contexto «%s»)" % mus.contexto)
	if r.get_node_or_null("Suelo") == null and r.find_child("Suelo", true, false) == null:
		_fallo("3: no hay suelo")
	if r.escenario.cofres.size() < 3:
		_fallo("3: faltan cofres (%d)" % r.escenario.cofres.size())
	if r.get_node_or_null("MarcaSalida") == null:
		_fallo("3: la salida no está señalada")
	if not P.hay_partida():
		_fallo("3: no se guarda al entrar")
	print("OK 3: entrar (%d fallos)" % fallos.size())


# ================================================================= 4. cofres

func _premio(abrir: Callable) -> Array:
	var inv = load("res://inventario.gd")
	var antes := [inv.oro(), inv.cantidad("Poción"), inv.cantidad("Éter")]
	await abrir.call()
	return [inv.oro() - antes[0], inv.cantidad("Poción") - antes[1], inv.cantidad("Éter") - antes[2]]


func _cofre_2d(z, id: String) -> Array:
	for c in z.cofres:
		if c[1] == id:
			return c
	return []


func _cofres() -> void:
	for id in IDS_COFRES:
		_limpiar()
		var z = await _abrir(ZONA_2D)
		if z == null:
			return
		var c2: Array = _cofre_2d(z, id)
		if c2.is_empty():
			_fallo("4: la 2D no tiene el cofre %s" % id)
			continue
		var en_2d: Array = await _premio(func():
			z._abrir_cofre(c2)
			await _esperar(2))
		_limpiar()
		var r = await _abrir(REGION)
		if r == null:
			return
		if not r.escenario.cofres.has(id):
			_fallo("4: el bosque 3D no tiene el cofre %s" % id)
			continue
		var cf: Dictionary = r.escenario.cofres[id]
		if _junto(r, cf["pos"] + Vector3(0, 0, 1.2)) != "cofre:" + id or r.boton_accion.text != "Abrir cofre":
			_fallo("4: junto al cofre %s no sale «Abrir cofre» (cerca = «%s»)" % [id, r.cerca])
			continue
		var en_3d: Array = await _premio(func():
			r._accion()
			await _esperar(2))
		if en_3d != en_2d or en_3d == [0, 0, 0]:
			_fallo("4: el cofre %s da %s en el 3D y %s en la 2D" % [id, en_3d, en_2d])
		if not Engine.get_meta("cofres_abiertos", {}).has(id) or not r.escenario.cofres[id]["abierto"]:
			_fallo("4: el cofre %s no queda abierto" % id)
		var g = P.leer(ARCHIVO)
		if g == null or not g.get("cofres_abiertos", {}).has(id):
			_fallo("4: la partida guardada no lleva el cofre %s abierto" % id)
		var n := [load("res://inventario.gd").oro()]
		_junto(r, cf["pos"] + Vector3(0, 0, 1.2))
		if r.cerca == "cofre:" + id:
			_fallo("4: el cofre %s abierto se puede abrir otra vez" % id)
		# abierto en el 3D: en la 2D también
		z = await _abrir(ZONA_2D)
		if z != null and not _cofre_2d(z, id).is_empty() and not _cofre_2d(z, id)[2]:
			_fallo("4: abierto en el 3D, el cofre %s sigue cerrado en la 2D" % id)
		if load("res://inventario.gd").oro() != n[0]:
			_fallo("4: abrir la 2D cambia el oro")
	# abierto en la 2D: en el 3D también
	_limpiar()
	Engine.set_meta("cofres_abiertos", {IDS_COFRES[0]: true})
	var r2 = await _abrir(REGION)
	if r2 != null and not r2.escenario.cofres[IDS_COFRES[0]]["abierto"]:
		_fallo("4: abierto en la 2D, el cofre sigue cerrado en el 3D")
	print("OK 4: los tres cofres, con su id y su premio de la 2D (%d fallos)" % fallos.size())


# ================================================================= 5. el Diente de Grimfang

func _equipables() -> Array:
	return load("res://inventario.gd").datos()["equipables"]


func _diente() -> void:
	_limpiar()
	var disponible: bool = not H.cofres_de(1).filter(func(h): return h[0] == ID_DIENTE).is_empty()
	var r = await _abrir(REGION)
	if r == null:
		return
	if not disponible:
		if r.escenario.cofres.has(ID_DIENTE):
			_fallo("5: el cofre del Diente está aunque el hallazgo no se puede dar (en la 2D no sale)")
		print("OK 5: el Diente de Grimfang no se puede dar aún (como en la 2D)")
		return
	if not r.escenario.cofres.has(ID_DIENTE):
		_fallo("5: no está el cofre del Diente de Grimfang")
		return
	var cf: Dictionary = r.escenario.cofres[ID_DIENTE]
	if cf["pos"].distance_to(T.en_mundo(T.lugar("campamento"))) > 6.0:
		_fallo("5: el cofre del Diente no está junto al campamento")
	if _junto(r, cf["pos"] + Vector3(0, 0, 1.2)) != "cofre:" + ID_DIENTE:
		_fallo("5: junto al cofre del Diente no sale «Abrir cofre» (%s)" % r.cerca)
		return
	r._accion()
	await _esperar(3)
	if not H.encontrado(ID_DIENTE) or not "diente_grimfang" in _equipables():
		_fallo("5: el cofre no da el Diente de Grimfang")
	var g = P.leer(ARCHIVO)
	if g == null or not g.get("cofres_abiertos", {}).has(ID_DIENTE):
		_fallo("5: la partida guardada no lleva el Diente")
	r = await _abrir(REGION)
	if r != null and not r.escenario.cofres[ID_DIENTE]["abierto"]:
		_fallo("5: al volver, el cofre del Diente está cerrado")
	print("OK 5: el Diente de Grimfang, una vez (%d fallos)" % fallos.size())


# ================================================================= 6. el detalle y la Hoja sin Nombre

func _detalle() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	if r.escenario.hoja == null or not is_instance_valid(r.escenario.hoja):
		_fallo("6: la Hoja sin Nombre no está entre las raíces")
	var sitio: Vector3 = r._sitio_detalle()
	# el brazalete: brilla al acercarse (a pasos), no desde lejos
	r._colocar_kael(r._sitio_libre(sitio + Vector3(0, 0, 9.0)))
	r._paso()
	if r.brillados.has("bosque_armadura"):
		_fallo("6: el brazalete brilla desde lejos")
	r._colocar_kael(r._sitio_libre(sitio + Vector3(-1.5, 0, 3.0)))
	r._paso()
	if not r.brillados.has("bosque_armadura") or r.kael.get_node_or_null("BrilloBrazalete") == null:
		_fallo("6: el brazalete no brilla cerca del detalle")
	var junto: Vector3 = r._sitio_libre(sitio + Vector3(-1.2, 0, 1.2))
	if _junto(r, junto) != "detalle" or r.boton_accion.text != "Examinar":
		_fallo("6: junto a la armadura no sale «Examinar» (cerca = «%s»)" % r.cerca)
		return
	r._accion()
	await _esperar(3)
	if not P.visto("bosque_armadura"):
		_fallo("6: examinar la armadura no la apunta en el Diario")
	if r.aviso.text != P.detalles_de(1)[0]["texto"]:
		_fallo("6: no sale el texto del detalle («%s»)" % r.aviso.text)
	if not H.encontrado(ID_HOJA) or not "hoja_sin_nombre" in _equipables():
		_fallo("6: examinar la armadura no da la Hoja sin Nombre")
	var g = P.leer(ARCHIVO)
	if g == null or not g.get("cofres_abiertos", {}).has(ID_HOJA) or not g.get("lore_visto", {}).has("bosque_armadura"):
		_fallo("6: la partida guardada no lleva la Hoja ni el detalle")
	var texto: String = H.hallazgo(ID_HOJA)["texto"]
	if not await _hasta(func(): return r.aviso.text == texto, 20.0):
		_fallo("6: no sale el aviso de la Hoja (sale «%s»)" % r.aviso.text)
	if not await _hasta(func(): return r.get_node_or_null("HojaSinNombre") == null, 15.0):
		_fallo("6: la Hoja sigue entre las raíces tras cogerla")
	var n: int = _equipables().count("hoja_sin_nombre")
	_junto(r, junto)
	r._accion()
	await _esperar(5)
	if _equipables().count("hoja_sin_nombre") != n:
		_fallo("6: examinar otra vez da otra Hoja")
	r = await _abrir(REGION)
	if r != null and r.escenario.hoja != null:
		_fallo("6: al volver, la Hoja vuelve a estar")
	# encontrada en la 2D: en el 3D no está ni se vuelve a dar
	_limpiar()
	Engine.set_meta("cofres_abiertos", {ID_HOJA: true})
	r = await _abrir(REGION)
	if r != null:
		if r.escenario.hoja != null:
			_fallo("6: encontrada en la 2D, la Hoja sigue en el 3D")
		_junto(r, r._sitio_libre(r._sitio_detalle() + Vector3(-1.2, 0, 1.2)))
		r._accion()
		await _esperar(3)
		if "hoja_sin_nombre" in _equipables():
			_fallo("6: encontrada en la 2D, el 3D la vuelve a dar")
	# encontrada en el 3D: la 2D no la da otra vez
	_limpiar()
	Engine.set_meta("cofres_abiertos", {ID_HOJA: true})
	Engine.set_meta("lore_visto", {"bosque_armadura": true})
	var z = await _abrir(ZONA_2D)
	if z != null and not z.detalles.is_empty():
		z.jugador.position = z.detalles[0][0].position + Vector2(20, 20)
		z._comprobar_cerca()
		z._accion()
		await _esperar(5)
		if "hoja_sin_nombre" in _equipables():
			_fallo("6: encontrada en el 3D, la 2D la vuelve a dar")
	print("OK 6: el detalle de la armadura y la Hoja sin Nombre (%d fallos)" % fallos.size())


# ================================================================= 7. el altar

func _altar() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	if _junto(r, r._sitio_libre(r._sitio_altar() + Vector3(0, 0, 2.0))) != "altar":
		_fallo("7: junto al altar no sale «Examinar» (%s)" % r.cerca)
		return
	r._accion()
	await _esperar(2)
	if r.aviso.text != load("res://mapa.gd").LUGARES[1]["texto"]:
		_fallo("7: el altar no da el texto del lugar («%s»)" % r.aviso.text)
	print("OK 7: el altar (%d fallos)" % fallos.size())


# ================================================================= 8. encuentros

func _encuentro() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	if r.ZONA != "bosque" or r.PROB_ENCUENTRO != load("res://zona.gd").PROB_ENCUENTRO or r.PASOS_MIN != load("res://zona.gd").PASOS_MIN:
		_fallo("8: los encuentros no son los de la 2D")
	if absf(r.LONG_PASO - load("res://zona.gd").LONG_PASO / 64.0 * T.K) > 0.001:
		_fallo("8: un paso no mide lo mismo que en la 2D")
	var sitio: Vector3 = T.en_mundo(T.lugar("claro") + Vector2(1.5, 1.5))
	r._colocar_kael(r._sitio_libre(sitio))
	var donde: Vector3 = r.kael.global_position
	r.encuentro()
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == "res://combate.tscn" and not R.cambiando, 60.0):
		_fallo("8: el encuentro no lleva al combate")
		return
	if Engine.get_meta("escena_retorno", "") != REGION or Engine.get_meta("zona", "") != "bosque":
		_fallo("8: el combate no sabe volver al bosque o no es de bosque")
	await _esperar(10)
	R.cambiar_escena(REGION)                              # la vuelta, como la hace combate.gd
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null and not R.cambiando, 60.0):
		_fallo("8: no se vuelve al bosque")
		return
	await _esperar(5)
	if current_scene.kael.global_position.distance_to(donde) > 0.6:
		_fallo("8: tras el combate, Kael no vuelve al mismo sitio (%s frente a %s)" % [current_scene.kael.global_position, donde])
	print("OK 8: encuentros y vuelta (%d fallos)" % fallos.size())


# ================================================================= 9. guardar y cargar

func _guardar_cargar() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	var sitio: Vector3 = r._sitio_libre(T.en_mundo(T.lugar("ruinas") + Vector2(-2.0, 2.0)))
	r._colocar_kael(sitio)
	r.guardar_posicion()
	P.guardar(REGION)
	_limpiar()
	var escena: String = P.cargar()
	if escena != REGION:
		_fallo("9: la partida guardada en el bosque carga «%s»" % escena)
		return
	r = await _abrir(REGION)
	if r != null and r.kael.global_position.distance_to(sitio) > 0.6:
		_fallo("9: al cargar, Kael no está donde se guardó")
	print("OK 9: guardar y cargar (%d fallos)" % fallos.size())


# ================================================================= 10. recorrido sin caerse

func _andar_recto(r, hacia: Vector3, segundos := 25.0) -> bool:
	r.destino = r._ajustar_destino(hacia)
	var ok := await _hasta(func(): return not is_instance_valid(r) or r.destino == null, segundos)
	return ok and is_instance_valid(r) and Vector2(r.kael.global_position.x - hacia.x, r.kael.global_position.z - hacia.z).length() < 1.6


# Andar hasta «hacia»; si algo se pone delante (una columna de las ruinas, un tronco: la 2D también los tiene), como un
# jugador: rodearlo por un lado o por el otro.
func _andar(r, hacia: Vector3, segundos := 25.0) -> bool:
	if await _andar_recto(r, hacia, segundos):
		return true
	for intento in 3:
		var k: Vector3 = r.kael.global_position
		var dir := Vector3(hacia.x - k.x, 0, hacia.z - k.z).normalized()
		var lado := Vector3(-dir.z, 0, dir.x)
		for s in [1.0, -1.0]:
			var desvio: Vector3 = k + lado * s * (2.0 + intento) + dir * 1.5
			await _andar_recto(r, desvio, 8.0)
			if await _andar_recto(r, hacia, segundos):
				return true
	return false


func _en_el_mundo(r, donde: String) -> void:
	var k: Vector3 = r.kael.global_position
	var c: Vector2 = T.casilla(k.x, k.z)
	if is_nan(k.y) or k.y < T.altura(k.x, k.z) - 0.3 or k.y < T.FONDO_AGUA - 0.1 or c.x < 0 or c.y < 0 or c.x > D.ANCHO or c.y > D.ALTO + 2:
		_fallo("10: Kael fuera del mundo o bajo el suelo en %s (%s)" % [donde, k])


func _recorrido() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	r.salida["armada"] = false                             # la prueba no sale por el sur
	var camino: Array = D.CAMINOS[0].slice(1)              # de la entrada al altar, por el puente
	for i in camino.size():
		var c: Vector2 = camino[i]
		if i == camino.size() - 1:
			c += Vector2(0, 2.4)                           # delante del altar
		if not await _andar(r, T.en_mundo(c)):
			_fallo("10: por el camino no se llega a la casilla %s (Kael en %s)" % [c, T.casilla(r.kael.global_position.x, r.kael.global_position.z)])
			r._colocar_kael(r._sitio_libre(T.en_mundo(c)))
		_en_el_mundo(r, "el camino %d" % i)
	# las ramas a los rincones (la del claro cruza el otro puente)
	for rama in D.CAMINOS.slice(1):
		r._colocar_kael(r._sitio_libre(T.en_mundo(rama[0])))
		for k in range(1, rama.size()):
			if not await _andar(r, r._sitio_libre(T.en_mundo(rama[k]))):
				_fallo("10: por la rama no se llega a %s (Kael en %s)" % [rama[k], T.casilla(r.kael.global_position.x, r.kael.global_position.z)])
				break
			_en_el_mundo(r, "la rama %s" % rama[0])
	# el mirador por su rampa
	r._colocar_kael(r._sitio_libre(T.en_mundo(T.RAMPA_2D)))
	if not await _andar(r, T.mundo(T.MIRADOR_2D)) or not T.en_mirador(r.kael.global_position):
		_fallo("10: no se sube al mirador por la rampa (Kael en %s, a %.2f m)" % [T.casilla(r.kael.global_position.x, r.kael.global_position.z), r.kael.global_position.y])
	if not await _andar(r, T.en_mundo(T.RAMPA_2D)):
		_fallo("10: no se baja del mirador por la rampa")
	# por el agua no se pasa (fuera de los puentes)
	var pu: Array = D.PUENTES[0]
	var lado: Vector2 = (pu[1] as Vector2).orthogonal()
	r._colocar_kael(r._sitio_libre(T.en_mundo(pu[0] - pu[1] * 4.5)))
	await _andar(r, T.en_mundo(pu[0] + lado * 3.0 + pu[1] * 0.0), 6.0)
	var cc: Vector2 = T.casilla(r.kael.global_position.x, r.kael.global_position.z)
	if T.agua(cc) > 0.56 and not T.en_puente(cc, 0.2):
		_fallo("10: Kael anda por el agua (%s)" % cc)
	# puntos al azar: andar un rato en una dirección, siempre sobre el suelo y dentro
	seed(12)
	for k in 30:
		var c := Vector2(randf_range(3, D.ANCHO - 3), randf_range(3, D.ALTO - 3))
		var p: Vector3 = T.en_mundo(c)
		if T.prohibido(p.x, p.z) or r.escenario.bloqueado(p.x, p.z):
			continue
		r._colocar_kael(p)
		var dir := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
		r.destino = r._ajustar_destino(p + dir * 12.0)
		await _esperar(40)
		_en_el_mundo(r, "un punto al azar (%s)" % c)
	print("OK 10: recorrido (%d fallos)" % fallos.size())


# ================================================================= 11. la salida

func _salida() -> void:
	_limpiar()
	var r = await _abrir(REGION)
	if r == null:
		return
	r._colocar_kael(T.en_mundo(T.ENTRADA_2D + Vector2(0, -3.0)))
	r._ultima = r.kael.global_position
	r.salida["armada"] = false
	await _esperar(5)
	await _andar(r, T.en_mundo(T.SALIDA_2D), 10.0)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == P.MAPA and not R.cambiando, 20.0):
		_fallo("11: andando a la salida del sur no se vuelve al mapa (Kael en %s)" % (T.casilla(r.kael.global_position.x, r.kael.global_position.z) if is_instance_valid(r) else "?"))
	print("OK 11: salida al mapa (%d fallos)" % fallos.size())
