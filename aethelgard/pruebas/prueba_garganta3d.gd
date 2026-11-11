extends SceneTree
# Prueba de la Garganta del Diablo 3D (zonas3d/garganta_3d.tscn), con la exploración 3D y su argumento
# («-- 3d garganta3d sin_prologo»). Recorre la mazmorra de verdad: escenas con Recursos.cambiar_escena, Kael andando
# (física y zonas prohibidas de la región) y combate.tscn de verdad.
#   0. modo3d: desde el 12/11 (V12) la 3D va por defecto con la exploración 3D, también en la APK experimental, y
#      «garganta2d» (o la 2D elegida en Ajustes: prueba_garganta3d_examinables) lleva a la 2D; el cofre del nido tiene
#      el identificador de la 2D; las posiciones de la 2D se convierten a sitios de la 3D.
#   1. Del mapa, el lugar 2 lleva a la Garganta 3D (no a la 2D); se entra por la entrada, con la zona «garganta».
#   2. Los puentes colgantes se cruzan andando (la tablazón cuelga); el ritmo de encuentros es el de la 2D.
#   3. Los pilares de los puentes (detalle de lore) se examinan y quedan vistos.
#   4. Sin la palanca: el ascensor no se mueve y la puerta sellada no cede ni deja pasar.
#   5. La escalera de la presa baja andando de la cornisa alta a la baja.
#   6. La palanca: queda apuntada (mazmorras.garganta.palanca), el levadizo baja y se cruza andando, la puerta se abre y
#      se cruza, y el ascensor sube a la entrada.
#   7. El nido: bajar andando dispara su combate fijo (grupo 6); se gana (combate.gd) y se vuelve al pie de la bajada;
#      el gólem ya no está y el combate no se repite.
#   8. El cofre raro: 300 monedas, 2 Éter y un Incienso de Ceniza, una sola vez; la partida guardada lo lleva.
#   9. Gorthor: entrar en la arena dispara el combate del jefe (grupo 5, «jefe»); se pierde y se vuelve antes de la
#      arena, sin repetirlo nada más volver.
#  10. Guardar en el altar y cargar: se vuelve a la 3D, al mismo sitio, con todo lo hecho.
#  11. Salir al mapa por la entrada; el mapa vuelve a llevar a la 3D. Una partida guardada dentro de la Garganta 2D:
#      modo3d.escena_equivalente la lleva a la 3D (y, si progreso.gd ya lo usa, también al cargarla).
#  12. Una partida con la Garganta 2D terminada (palanca, nido, cofre y Gorthor): la 3D sale terminada (levadizo bajado,
#      puerta abierta, sin gólem ni Gorthor, cofre abierto) y la arena «guarda silencio».
# Guarda de verdad, pero solo en su archivo (user://prueba_garganta3d.save, Engine «archivo_partida_prueba»). Termina
# con «FALLOS: n» y quit(1) si algo no se cumple.

const REGION := "res://zonas3d/garganta_3d.tscn"
const GARGANTA_2D := "res://garganta.tscn"
const MAPA := "res://mapa.tscn"
const COMBATE := "res://combate.tscn"
const ARCHIVO := "user://prueba_garganta3d.save"
const ESPERA_MAX_MS := 45000
const TOL := 0.6

var frames := 0
var paso := 0
var sub := 0
var t_paso := 0
var f_paso := 0
var R
var P
var T
var M3
var inv
var fallos: Array = []
var minimo_y := 0.0
var cruzo_hueco := false
var antes := {}
var despues := {}
var guardado_en := Vector3.ZERO


func _initialize() -> void:
	R = root.get_node("Recursos")
	P = load("res://progreso.gd")
	T = load("res://zonas3d/garganta/trazado.gd")
	M3 = load("res://modo3d.gd")
	inv = load("res://inventario.gd")
	_comprobar_modo3d()
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	Engine.set_meta("partida_lista", true)              # como si la partida se hubiera cargado al arrancar
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto", "incienso"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	change_scene_to_file(MAPA)
	_siguiente(1)


# ================================================================= 0. modo3d y equivalencias (sin escenas)

func _comprobar_modo3d() -> void:
	if not M3.activo():
		_fallo_fatal("la exploración 3D no está activa (falta «-- 3d»)")
		return
	if M3.escena_de(2) != REGION:
		fallos.append("0: con «garganta3d», el lugar 2 no lleva a la Garganta 3D (lleva a «%s»)" % M3.escena_de(2))
	var casos := [[PackedStringArray(["3d"]), false, true, "con «-- 3d» sin «garganta3d» (por defecto, V12)"],
		[PackedStringArray([]), true, true, "en la APK experimental (rebelum3d) sin argumento (por defecto, V12)"],
		[PackedStringArray(["garganta3d"]), false, false, "con «garganta3d» pero sin la exploración 3D"],
		[PackedStringArray(["3d", "garganta2d"]), false, false, "con «-- 3d garganta2d» (la 2D elegida)"],
		[PackedStringArray(["3d", "garganta3d"]), false, true, "con «-- 3d garganta3d»"]]
	for c in casos:
		if M3.region_activa_con(2, c[0], c[1]) != c[2]:
			fallos.append("0: la Garganta 3D %s debería estar %s" % [c[3], "activa" if c[2] else "apagada (va la 2D)"])
	if not M3.region_activa_con(10, PackedStringArray(["3d"]), false):
		fallos.append("0: Pastos Verdes 3D ya no sale con «-- 3d»")
	# el cofre del nido: el mismo identificador que en la 2D (zona.gd, _id_cofre)
	var g2 = load("res://garganta.gd")
	var z2 = load("res://zona.gd")
	var px: Vector2 = g2.COFRE_NIDO * z2.T
	var id2 := "%d_%d_%d" % [g2.INDICE, int(px.x), int(px.y)]
	var r3 = load("res://zonas3d/garganta_3d.gd")
	if id2 != r3.ID_COFRE_NIDO:
		fallos.append("0: el cofre del nido es «%s» en la 2D y «%s» en la 3D" % [id2, r3.ID_COFRE_NIDO])
	# posiciones de la 2D (en píxeles) → sitios de la 3D
	for c in [[Vector2(47, 33.2), T.PALANCA, "la palanca"], [Vector2(3, 10.8), T.INICIO, "la entrada"],
			[Vector2(31, 50.6), T.VUELTA_NIDO, "el nido"], [Vector2(70, 9), T.VUELTA_GORTHOR, "la arena"]]:
		var p3: Vector3 = r3.posicion_desde_2d(c[0] * 64.0)
		if Vector2(p3.x - c[1].x, p3.z - c[1].z).length() > 2.5 or absf(p3.y - c[1].y) > 1.0:
			fallos.append("0: %s de la 2D cae en %s en la 3D" % [c[2], p3])
		elif not T.andable(p3, false):
			fallos.append("0: %s de la 2D cae en un sitio que no se pisa (%s)" % [c[2], p3])
	# por dónde se anda: lo que sí y lo que no
	var si := [Vector3(-12, 0, 37), Vector3(-12, 0, 15), Vector3(-12, 0, 10.5), Vector3(0, -4, 29.5), Vector3(11, -8, 0),
		Vector3(5.5, -11, 15), Vector3(1.1, -14, 6.6), Vector3(-8.5, 0, -31), Vector3(11, -8, -30)]
	var no := [Vector3(0, -8, -5), Vector3(-14.5, 0, 15), Vector3(-12, 0, 47), Vector3(0, 0, -12), Vector3(14.6, -8, 0),
		Vector3(-16, 0, 0)]
	for p in si:
		if not T.andable(p, false):
			fallos.append("0: %s debería pisarse" % p)
	for p in no:
		if T.andable(p, false):
			fallos.append("0: %s no debería pisarse" % p)
	if not T.andable(Vector3(0, -4, T.LEVADIZO_Z), true) or T.andable(Vector3(0, -4, T.LEVADIZO_Z), false):
		fallos.append("0: el levadizo solo se pisa bajado")
	print("OK 0: modo3d, identificadores y trazado comprobados (%d fallos)" % fallos.size())


# ================================================================= utilidades

func _fallo_fatal(texto: String) -> void:
	fallos.append(texto)
	_terminar()


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _siguiente(n: int) -> void:
	paso = n
	sub = 0
	t_paso = Time.get_ticks_msec()
	f_paso = frames


func _lista(ruta: String, n := 8) -> bool:
	return _escena() == ruta and not R.cambiando and frames - f_paso >= n


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Kael en «p», con la y del suelo de debajo.
func _poner(r, p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 2.0, 0), p - Vector3(0, 6.0, 0))
	var hit: Dictionary = r.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		p.y = hit["position"].y
	r._colocar_kael(p)
	r._ultima = p


func _andar(r, hacia: Vector3) -> void:
	r.destino = r._ajustar_destino(hacia)
	f_paso = frames


# true cuando Kael ha dejado de andar (llegó o se paró)
func _parado(r) -> bool:
	return r.destino == null and frames - f_paso > 3


func _inventario() -> Dictionary:
	return {"oro": inv.oro(), "Éter": inv.cantidad("Éter"), "Incienso": inv.cantidad(P.INCIENSO)}


# ================================================================= recorrido

func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo_fatal("el paso %d.%d no terminó en %d s (escena=%s)" % [paso, sub, ESPERA_MAX_MS / 1000, _escena()])
		return true
	var r = current_scene
	if r != null and _escena() == REGION and "pasos" in r:
		r.pasos = 0                                    # sin encuentros al azar mientras anda (solo en la prueba)
	match paso:
		1:
			if _lista(MAPA, 20):
				r.cerca = r.lugares[2]
				r._entrar()
				_siguiente(2)
		2:
			if _escena() == GARGANTA_2D:
				_fallo_fatal("1: del mapa se ha entrado en la Garganta 2D")
				return true
			if _lista(REGION, 10):
				_entrada(r)
		3:
			_puentes(r)
		4:
			_sin_palanca(r)
		5:
			_escalera(r)
		6:
			_palanca(r)
		7:
			_nido(r)
		8:
			_cofre(r)
		9:
			_gorthor(r)
		10:
			_guardar_y_cargar(r)
		11:
			_salida(r)
		99:
			return _terminar()
	return paso == 100


func _entrada(r) -> void:
	if _plana(r.kael.global_position, T.INICIO) > 1.0:
		fallos.append("1: Kael no entra por la entrada (%s)" % r.kael.global_position)
	if Engine.get_meta("zona", "") != "garganta":
		fallos.append("1: la zona de los combates no es «garganta»")
	for b in r.find_children("*", "Button", true, false):
		if b.text in r.BOTONES_BANCO:
			fallos.append("1: sigue el botón de banco «%s»" % b.text)
	if r.info.visible:
		fallos.append("1: se ve la ayuda de teclas del prototipo")
	if T.ritmo(Vector3(-12, 0, 15)) != 2.0 or T.ritmo(Vector3(11, -8, 10)) != 0.5 or T.ritmo(Vector3(-12, 0, 37)) != 0.0 \
			or T.ritmo(Vector3(1.1, -14, 6.6)) != 0.0 or T.ritmo(Vector3(-12, 0, -8)) != 0.0:
		fallos.append("1: el ritmo de encuentros no es el de la 2D")
	for i in r.PASOS_MIN - 1:
		r._paso()
	if r.saliendo:
		fallos.append("1: hubo un encuentro en los pasos seguros")
	print("OK 1: del mapa a la Garganta 3D, por la entrada; ritmo de encuentros como en la 2D")
	_poner(r, Vector3(-12, 0, 21.0))
	minimo_y = 0.0
	_siguiente(3)
	_andar(r, Vector3(-12, 0, 0.5))


func _puentes(r) -> void:
	var p: Vector3 = r.kael.global_position
	if sub == 0:
		minimo_y = minf(minimo_y, p.y)
		if T.en_hueco(p.z) and p.y < -0.15:
			cruzo_hueco = true
		if not _parado(r):
			return
		if p.z > 1.5 or absf(p.y) > 0.3:
			fallos.append("2: Kael no cruzó los dos puentes (se quedó en %s)" % p)
		elif not cruzo_hueco or minimo_y > -0.2:
			fallos.append("2: Kael no pasó por la tablazón colgada (y mínima %.2f)" % minimo_y)
		else:
			print("OK 2: cruzó los dos puentes colgantes andando (bajó hasta y = %.2f sobre los huecos)" % minimo_y)
		sub = 1
		f_paso = frames
		return
	if frames - f_paso < 75:                           # el grupo le sigue por los puentes (zonas3d/grupo_3d.gd)
		return
	if r.grupo != null:
		for n in r.grupo.nodos():
			var q: Vector3 = n.global_position
			if q.z > 6.0 or q.y < -0.8 or _plana(q, p) > 6.0:
				fallos.append("2: %s no siguió a Kael por los puentes (está en %s)" % [n.name, q])
		print("OK 2b: el grupo (%d) le sigue por los puentes" % r.grupo.nodos().size())
	# 3. los pilares de los puentes
	_poner(r, Vector3(-12.6, 0, T.DETALLE_PUENTES.z))
	r._comprobar_cerca()
	if r.cerca != "detalle_p2":
		fallos.append("3: junto a los pilares no sale «Examinar» (cerca = «%s»)" % r.cerca)
	else:
		r._accion()
		if not P.visto("garganta_puentes") or not r.aviso.text.begins_with("Cada pilar"):
			fallos.append("3: examinar los pilares no apunta el detalle (aviso «%s»)" % r.aviso.text)
		else:
			print("OK 3: los pilares de los puentes se examinan (garganta_puentes)")
	_siguiente(4)


func _sin_palanca(r) -> void:
	match sub:
		0:
			r._bloqueo = 0.0
			_poner(r, T.ASCENSOR_ARRIBA)
			r._comprobar_cerca()
			if r.cerca != "ascensor_arriba":
				fallos.append("4: junto al ascensor de arriba no sale el botón (cerca = «%s»)" % r.cerca)
			else:
				r._accion()
				if r.viajando or not r.aviso.text.begins_with("El ascensor no se mueve"):
					fallos.append("4: sin la palanca, el ascensor se mueve (aviso «%s»)" % r.aviso.text)
			r._bloqueo = 0.0
			_poner(r, Vector3(-12, 0, -17.5))
			r._comprobar_cerca()
			if r.cerca != "puerta" or r.boton_accion.text != "Examinar la puerta":
				fallos.append("4: junto a la puerta no sale «Examinar la puerta» (cerca = «%s»)" % r.cerca)
			else:
				r._accion()
				if not r.aviso.text.begins_with("Una puerta sellada"):
					fallos.append("4: la puerta no dice que está sellada")
			_andar(r, Vector3(-12, 0, -24.0))
			sub = 1
		1:
			if _parado(r):
				var z: float = r.kael.global_position.z
				if z < -19.5:
					fallos.append("4: sin la palanca, Kael pasa la puerta sellada (z = %.2f)" % z)
				else:
					print("OK 4: sin la palanca, el ascensor no se mueve y la puerta no cede ni deja pasar (Kael en z = %.2f)" % z)
				_poner(r, Vector3(-9.6, 0, 29.5))
				_andar(r, Vector3(9.0, -8.0, 29.5))
				_siguiente(5)


func _escalera(r) -> void:
	if not _parado(r):
		return
	var p: Vector3 = r.kael.global_position
	if _plana(p, Vector3(9.0, -8.0, 29.5)) > TOL or absf(p.y - T.BAJO) > 0.3:
		fallos.append("5: Kael no bajó la escalera de la presa (se quedó en %s)" % p)
	else:
		print("OK 5: bajó andando la escalera de la presa, de la cornisa alta a la baja")
	_siguiente(6)


func _palanca(r) -> void:
	match sub:
		0:
			_poner(r, Vector3(11.4, T.BAJO, -6.0))
			r._comprobar_cerca()
			if r.cerca != "palanca" or r.boton_accion.text != "Tirar de la palanca":
				fallos.append("6: junto a la palanca no sale «Tirar de la palanca» (cerca = «%s»)" % r.cerca)
			r.cerca = "palanca"
			r._bloqueo = 0.0
			r._accion()
			if not P.estado("garganta", "palanca"):
				fallos.append("6: la palanca no queda apuntada en mazmorras.garganta")
			var guardada = P.leer(ARCHIVO)
			if guardada == null or not guardada.get("mazmorras", {}).get("garganta", {}).get("palanca", false):
				fallos.append("6: la partida guardada no lleva la palanca")
			sub = 1
		1:
			if not r.tirando and r.levadizo.get("choque") != null:
				if r.puerta.get("choque") != null:
					fallos.append("6: la puerta sigue cerrada tras la palanca")
				r._comprobar_cerca()
				if r.boton_accion.text != "Palanca bajada":
					fallos.append("6: la palanca no dice «Palanca bajada»")
				_poner(r, Vector3(10.2, T.BAJO, T.LEVADIZO_Z))
				_andar(r, Vector3(-11.0, T.ALTO, T.LEVADIZO_Z))
				sub = 2
			elif frames - f_paso > 300:
				fallos.append("6: el levadizo no terminó de bajar")
				_siguiente(7)
		2:
			if _parado(r):
				var p: Vector3 = r.kael.global_position
				if _plana(p, Vector3(-11.0, 0, T.LEVADIZO_Z)) > TOL or absf(p.y) > 0.3:
					fallos.append("6: Kael no cruzó el levadizo bajado (se quedó en %s)" % p)
				else:
					print("OK 6a: el levadizo bajó y se cruza andando, de la cornisa baja a la alta")
				_andar(r, Vector3(10.2, T.BAJO, T.LEVADIZO_Z))      # y de vuelta, de la alta a la baja
				sub = 21
		21:
			if _parado(r):
				var p: Vector3 = r.kael.global_position
				if _plana(p, Vector3(10.2, 0, T.LEVADIZO_Z)) > TOL or absf(p.y - T.BAJO) > 0.3:
					fallos.append("6: Kael no cruzó el levadizo de vuelta (se quedó en %s)" % p)
				else:
					print("OK 6a2: y de vuelta, de la cornisa alta a la baja")
				_poner(r, Vector3(-12, 0, -16.5))
				_andar(r, Vector3(-12, 0, -23.4))
				sub = 3
		3:
			if _parado(r):
				var p: Vector3 = r.kael.global_position
				if p.z > -22.8:
					fallos.append("6: con la palanca, Kael no pasa la puerta (z = %.2f)" % p.z)
				else:
					print("OK 6b: la puerta se abrió y se cruza")
				r._bloqueo = 0.0
				_poner(r, T.ASCENSOR_ABAJO)
				r._comprobar_cerca()
				if r.cerca != "ascensor_abajo" or r.boton_accion.text != "Subir a la entrada":
					fallos.append("6: junto al ascensor de abajo no sale «Subir a la entrada»")
				r._accion()
				sub = 4
		4:
			if not r.viajando and frames - f_paso > 10:
				var p: Vector3 = r.kael.global_position
				if _plana(p, T.ASCENSOR_ARRIBA) > TOL or absf(p.y - T.ALTO) > 0.3:
					fallos.append("6: el ascensor no subió a la entrada (Kael en %s)" % p)
				else:
					print("OK 6c: el ascensor sube a la entrada")
				_poner(r, Vector3(6.2, T.BAJO, 19.8))
				_andar(r, T.VUELTA_NIDO + Vector3(0, 0, -0.3))
				_siguiente(7)


func _nido(r) -> void:
	match sub:
		0:                                            # bajando la escalera; al pisar el nido, el combate
			if r != null and _escena() == REGION and _parado(r) and not r.saliendo:
				var p: Vector3 = r.kael.global_position
				if absf(p.y - T.NIDO) > 0.3:
					fallos.append("7: Kael no bajó la escalera del nido (se quedó en %s)" % p)
					_siguiente(8)
					return
				_andar(r, T.COFRE_NIDO)
				sub = 1
		1:
			if _escena() == REGION and r.saliendo:
				if Engine.get_meta("combate_fijo", "") != "garganta_nido" or Engine.get_meta("grupo_combate", -1) != 6 \
						or Engine.get_meta("escena_retorno", "") != REGION or Engine.get_meta("tipo_combate", "") != "normal":
					fallos.append("7: el combate del nido no lleva sus datos (%s, %s, %s)" % [Engine.get_meta("combate_fijo", "-"),
						Engine.get_meta("grupo_combate", -1), Engine.get_meta("escena_retorno", "-")])
				if _plana(Engine.get_meta("pos_3d"), T.VUELTA_NIDO) > 0.05:
					fallos.append("7: tras el combate del nido no se volverá al pie de la bajada")
				sub = 2
			elif _escena() == REGION and _parado(r) and frames - f_paso > 60:
				fallos.append("7: Kael llegó al nido sin combate (%s)" % r.kael.global_position)
				_siguiente(8)
		2:
			if _lista(COMBATE, 5):
				print("OK 7a: al pisar el nido empieza su combate fijo (grupo 6); se gana")
				r._fin_combate(true)
				sub = 3
		3:
			if _lista(REGION, 10):
				var p: Vector3 = r.kael.global_position
				if not P.ganado("garganta_nido"):
					fallos.append("7: ganar el combate del nido no lo apunta")
				if _plana(p, T.VUELTA_NIDO) > TOL:
					fallos.append("7: tras el combate, Kael aparece a %.2f m del pie de la bajada" % _plana(p, T.VUELTA_NIDO))
				if r.golem != null:
					fallos.append("7: el gólem sigue en el nido tras vencerlo")
				_andar(r, T.COFRE_NIDO + Vector3(1.4, 0, 1.2))
				sub = 4
		4:
			if _parado(r):
				if r.saliendo:
					fallos.append("7: el combate del nido se repite tras ganarlo")
				else:
					print("OK 7b: vuelta al pie de la bajada, sin gólem; el combate del nido no se repite")
				_siguiente(8)


func _cofre(r) -> void:
	r._comprobar_cerca()
	if r.cerca != "cofre":
		fallos.append("8: junto al cofre no sale «Abrir cofre» (cerca = «%s», Kael en %s)" % [r.cerca, r.kael.global_position])
	antes = _inventario()
	r._bloqueo = 0.0
	r._accion()
	despues = _inventario()
	if despues["oro"] - antes["oro"] != 300 or despues["Éter"] - antes["Éter"] != 2 or despues["Incienso"] - antes["Incienso"] != 1:
		fallos.append("8: el cofre raro no da su premio (%s → %s)" % [antes, despues])
	if not Engine.get_meta("cofres_abiertos", {}).has(r.ID_COFRE_NIDO):
		fallos.append("8: el cofre no queda abierto con el identificador de la 2D")
	r._bloqueo = 0.0
	r.cerca = "cofre"
	r._accion()
	r._abrir_cofre()
	if _inventario() != despues:
		fallos.append("8: abrir el cofre otra vez da más (%s)" % _inventario())
	var guardada = P.leer(ARCHIVO)
	if guardada == null or not guardada.get("cofres_abiertos", {}).has(r.ID_COFRE_NIDO) or guardada["inventario"]["oro"] != despues["oro"]:
		fallos.append("8: la partida guardada no lleva el cofre abierto y su premio")
	else:
		print("OK 8: el cofre raro da 300 monedas, 2 Éter y un Incienso, una sola vez, y se guarda")
	_poner(r, Vector3(-12, 0, -21.0))
	_andar(r, Vector3(-9.0, 0, -30.0))
	_siguiente(9)


func _gorthor(r) -> void:
	match sub:
		0:
			if _escena() == REGION and r.saliendo:
				if Engine.get_meta("combate_fijo", "") != "garganta_gorthor" or Engine.get_meta("grupo_combate", -1) != 5 \
						or Engine.get_meta("tipo_combate", "") != "jefe":
					fallos.append("9: el combate de Gorthor no lleva sus datos")
				if _plana(Engine.get_meta("pos_3d"), T.VUELTA_GORTHOR) > 0.05:
					fallos.append("9: tras perder con Gorthor no se volverá antes de la arena")
				sub = 1
			elif _escena() == REGION and _parado(r) and frames - f_paso > 60:
				fallos.append("9: Kael entró en la arena sin combate (%s)" % r.kael.global_position)
				_siguiente(10)
		1:
			if _lista(COMBATE, 5):
				print("OK 9a: al entrar en la arena empieza el combate de Gorthor (grupo 5, jefe); se pierde")
				r._volver_al_mapa()
				sub = 2
		2:
			if _lista(REGION, 30):
				var antes_n := fallos.size()
				var p: Vector3 = r.kael.global_position
				if P.ganado("garganta_gorthor"):
					fallos.append("9: perder con Gorthor lo apunta como ganado")
				if _plana(p, T.VUELTA_GORTHOR) > TOL:
					fallos.append("9: tras perder, Kael aparece a %.2f m de la vuelta" % _plana(p, T.VUELTA_GORTHOR))
				if r.saliendo:
					fallos.append("9: el combate de Gorthor se repite nada más volver")
				if r.gorthor == null:
					fallos.append("9: Gorthor no espera en la arena (tras perder sigue ahí)")
				if fallos.size() == antes_n:
					print("OK 9b: vuelta antes de la arena, sin repetir el combate; Gorthor sigue esperando")
				_siguiente(10)


func _guardar_y_cargar(r) -> void:
	match sub:
		0:
			r._bloqueo = 0.0
			_poner(r, T.GUARDADO_2 + Vector3(1.6, 0, 0))
			r._comprobar_cerca()
			if r.cerca != "guardado_2" or r.boton_accion.text != "Guardar partida":
				fallos.append("10: junto al altar no sale «Guardar partida» (cerca = «%s»)" % r.cerca)
			r.cerca = "guardado_2"
			r._accion()
			guardado_en = r.kael.global_position
			var guardada = P.leer(ARCHIVO)
			if guardada == null or guardada.get("escena_guardada", "") != REGION or not guardada.get("pos_3d_ok", false):
				fallos.append("10: el altar no guarda la partida en la Garganta 3D")
			for k in P.CLAVES:                                   # como al abrir el juego: se carga del archivo
				if Engine.has_meta(k):
					Engine.remove_meta(k)
			Engine.remove_meta("partida_lista")
			var escena: String = P.cargar()
			if escena != REGION:
				fallos.append("10: al cargar, la partida no vuelve a la Garganta 3D (vuelve a «%s»)" % escena)
			change_scene_to_file(REGION)
			f_paso = frames
			sub = 1
		1:
			if _lista(REGION, 10):
				var p: Vector3 = r.kael.global_position
				if _plana(p, guardado_en) > TOL:
					fallos.append("10: tras cargar, Kael aparece a %.2f m de donde guardó" % _plana(p, guardado_en))
				if not r.palanca_bajada() or r.levadizo.get("choque") == null or r.puerta.get("choque") != null:
					fallos.append("10: tras cargar, la palanca, el levadizo o la puerta no están como se dejaron")
				if not r.cofre_abierto() or r.golem != null or not P.ganado("garganta_nido") or P.ganado("garganta_gorthor"):
					fallos.append("10: tras cargar, el nido, el cofre o Gorthor no están como se dejaron")
				if _inventario() != despues:
					fallos.append("10: tras cargar, el inventario es %s y no %s" % [_inventario(), despues])
				print("OK 10: guardar en el altar y cargar vuelve a la Garganta 3D, al mismo sitio y con todo lo hecho")
				_poner(r, Vector3(-12, 0, 38.0))
				_andar(r, T.SALIDA + Vector3(0, 0, 0.5))
				_siguiente(11)


func _salida(r) -> void:
	match sub:
		0:
			if _lista(MAPA, 8):
				if Engine.get_meta("pos_3d_ok", true):
					fallos.append("11: al salir al mapa no se borra la posición de la Garganta")
				r.cerca = r.lugares[2]
				r.en_encuentro = false
				r._entrar()
				f_paso = frames
				sub = 1
		1:
			if _escena() == GARGANTA_2D:
				fallos.append("11: al volver a entrar desde el mapa se ha colado la Garganta 2D")
				_siguiente(99)
			elif _lista(REGION, 10):
				if _plana(r.kael.global_position, T.INICIO) > 1.0:
					fallos.append("11: al volver a entrar, Kael no está en la entrada")
				print("OK 11a: salida al mapa por la entrada y vuelta a entrar: otra vez la 3D")
				_partida_2d()
				# 12. una partida con la Garganta 2D terminada: los mismos identificadores la dejan igual en la 3D
				Engine.set_meta("mazmorras", {"garganta": {"palanca": true}})
				Engine.set_meta("combates_ganados", {"garganta_nido": true, "garganta_gorthor": true})
				Engine.set_meta("cofres_abiertos", {"2_1984_3238": true})
				Engine.set_meta("pos_3d_ok", false)
				change_scene_to_file(REGION)
				f_paso = frames
				sub = 2
		2:
			if _lista(REGION, 10):
				if r.levadizo.get("choque") == null or r.puerta.get("choque") != null or r.golem != null \
						or r.gorthor != null or not r.cofre_abierto():
					fallos.append("12: con la Garganta 2D terminada, la 3D no sale terminada (levadizo, puerta, gólem, Gorthor o cofre)")
				_poner(r, Vector3(-12, 0, -21.0))
				_andar(r, Vector3(-9.0, 0, -30.0))
				sub = 3
		3:
			if _parado(r):
				if r.saliendo:
					fallos.append("12: con Gorthor vencido, la arena vuelve a dar su combate")
				elif not r.aviso.text.begins_with("La arena guarda silencio"):
					fallos.append("12: con Gorthor vencido, la arena no «guarda silencio» (aviso «%s»)" % r.aviso.text)
				else:
					print("OK 12: con la Garganta 2D terminada, la 3D sale terminada y la arena guarda silencio")
				_siguiente(99)


# Una partida guardada dentro de la Garganta 2D (escena garganta.tscn, posición en píxeles) con la 3D activa.
func _partida_2d() -> void:
	Engine.set_meta("pos_zona", Vector2(47, 33.2) * 64.0)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 2)
	var en_3d: String = M3.escena_equivalente(GARGANTA_2D)
	if en_3d != REGION:
		fallos.append("11: modo3d no lleva una partida de la Garganta 2D a la 3D")
	elif not Engine.get_meta("pos_3d_ok", false) or Engine.get_meta("pos_3d_lugar", -1) != 2 \
			or _plana(Engine.get_meta("pos_3d"), T.PALANCA) > 2.5:
		fallos.append("11: la posición de la 2D (junto a la palanca) no se convierte a la 3D")
	else:
		print("OK 11b: modo3d.escena_equivalente lleva una partida de la Garganta 2D a la 3D, junto a la palanca")
	var d := {"escena_guardada": GARGANTA_2D, "pos_zona": Vector2(47, 33.2) * 64.0, "pos_zona_ok": true, "pos_zona_lugar": 2,
		"mazmorras": {"garganta": {"palanca": true}}}
	var escena: String = P.restaurar(d)
	if escena == REGION:
		print("OK 11c: al cargar una partida de la Garganta 2D, progreso.gd ya la lleva a la 3D")
	else:
		print("AVISO 11c: al cargar una partida de la Garganta 2D se abre «%s»: falta el cambio pedido en progreso.gd" % escena
			+ " (restaurar → modo3d.escena_equivalente); hasta entonces esa partida abre la 2D")


func _terminar() -> bool:
	_borrar()
	if Engine.has_meta("archivo_partida_prueba"):
		Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	paso = 100
	return true


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
