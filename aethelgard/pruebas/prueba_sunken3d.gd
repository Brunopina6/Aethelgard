extends SceneTree
# V12 (15/11), Sunken City 3D, sector «Popa Rota → Cubierta Mayor» (zonas3d/sunken_3d.gd; EN PRUEBAS tras «sunken3d»).
# Con «sunken3d» (lista_pruebas.txt, prueba_sunken3d):
#   1. Interruptor en pruebas y entrada DESDE EL MAPA (mapa.gd _entrar) por el muelle (INICIO), con el lugar 5, la zona
#      «ciudad» (sin encuentros) y el ambiente «puerto».
#   2. El recorrido con el controlador real (destino → vista3d.gd, en línea recta, con física): del muelle a cada pieza y a
#      cada vecino por tramos rectos; en cada final, el botón ofrece lo que toca. Nada de lo andable cae en un bloqueo; lo
#      de fuera (la laguna, la proa en obras, el Casco) no se pisa.
#   3. Guardar y cargar ANTES de nada (la partida del juego, Progreso.cargar): se vuelve por el muelle.
#   4. La misión «El sello de la capitana» con Dialogic de verdad (Intro en cada frase): Ulla la empieza; el palo mayor sin
#      la pista no da el sello; Brea da la pista; el palo, el sello; el Diario enseña solo los pasos conocidos y las pistas
#      oídas; guardar y cargar A MITAD (mismo sitio y estado); Ulla la cierra y da el Bronce del Águila UNA vez.
#   5. El secreto: el grabado; la tabla de la costilla que no alumbra (sin farol) da la paga UNA vez.
#   6. La recompensa en la forja de Kael: reservada hasta estudiarla; estudiarla; forjar la Guarda del Águila una vez.
#   7. El detalle «sunken_contratos» (mismo id) y la tienda del lugar 5 (la Moneda del Águila).
#   8. Guardar y cargar DESPUÉS (todo sigue igual); partida antigua sin las claves; salida al mapa y vuelta a entrar.
#   9. Sin referencias rotas: diálogos y personajes, frases ≤ 110 letras, datos del catálogo, condiciones del Diario y
#      comentarios del grupo (Lya y Garon solo si están).
# Sin «sunken3d» (prueba_sunken3d_apagada): el mapa lleva a la 2D (zona.tscn), una partida de la 2D se queda en la 2D y una
# de la 3D vuelve a la 2D por su entrada.
# Partida propia (Engine «archivo_partida_prueba»): nunca la de verdad. Imprime «FALLOS: n».

const REGION := "res://zonas3d/sunken_3d.tscn"
const ARCHIVO := "user://prueba_sunken3d.save"
# (sin precargar nada de la región: con sus guiones ya cargados en el hilo principal, la carga en segundo plano de
# Recursos.cambiar_escena fallaba al entrar desde el mapa; se cargan después de entrar, como en el juego)
var T
var Sunk
var M = load("res://modo3d.gd")
var P = load("res://progreso.gd")
var Inv = load("res://inventario.gd")
var E = load("res://encargos.gd")
var v
var fallos := 0

# Rutas rectas desde el muelle (x, z). Cada pieza: la ruta y el sitio final donde se pulsa.
const A_POPA := [Vector2(40.0, 57.8), Vector2(40.0, 50.0)]
const A_QUILLA := A_POPA + [Vector2(40.0, 44.0), Vector2(40.0, 33.0)]
const A_CUBIERTA := A_QUILLA + [Vector2(40.0, 27.6)]
const RUTAS := {
	"popa": [Vector2(40.0, 57.8), Vector2(40.0, 55.6)],
	"grabado": A_POPA + [Vector2(37.5, 50.0), Vector2(37.5, 52.4)],
	"ulla": A_POPA + [Vector2(40.0, 45.9), Vector2(47.0, 45.9), Vector2(52.6, 45.9), Vector2(52.6, 45.3)],
	"contratos": A_POPA + [Vector2(40.0, 45.9), Vector2(47.0, 45.9), Vector2(53.4, 45.9), Vector2(53.6, 47.3)],
	"tabla": A_POPA + [Vector2(40.0, 44.0), Vector2(38.8, 40.0), Vector2(38.8, 38.2)],
	"palo": A_CUBIERTA + [Vector2(40.0, 24.8)],
	"brea": A_CUBIERTA + [Vector2(37.4, 26.6)],
	"tienda": A_CUBIERTA + [Vector2(36.0, 27.6), Vector2(32.6, 22.4)],
	"escotilla": A_CUBIERTA + [Vector2(44.5, 27.6)],
	"proa": A_CUBIERTA + [Vector2(42.0, 27.6), Vector2(42.0, 21.0), Vector2(43.0, 19.8)],
	"lona": A_CUBIERTA + [Vector2(47.4, 27.6), Vector2(47.4, 23.4), Vector2(53.6, 23.4)],
}


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(t: String) -> void:
	print("OK " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, max_frames := 600) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _limpiar_partida() -> void:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok", "comentarios_dichos"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _cargar_region() -> void:
	change_scene_to_file(REGION)
	await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null, 300)
	await _frames(20)
	v = current_scene


# «Continuar»: la partida que guardó el juego (Progreso.cargar) y su escena.
func _continuar(donde: String) -> String:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "pos_3d_ok"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var escena: String = P.cargar()
	if escena != REGION:
		_mal("%s: la partida guardada no vuelve a Sunken City 3D («%s»)" % [donde, escena])
	await _cargar_region()
	return escena


func _kael() -> Vector2:
	return Vector2(v.kael.global_position.x, v.kael.global_position.z)


# Anda como un jugador: destino en cada punto (el mismo camino que un toque: _ajustar_destino) y espera a llegar.
func _andar(ruta: Array, nombre: String) -> bool:
	for c in ruta:
		var meta: Vector3 = T.en_mundo(c)
		v.destino = v._ajustar_destino(meta)
		# (hasta que se para: con un destino nuevo antes de llegar al anterior, vista3d.gd _vigilar_atasco compara con la
		# distancia que quedaba al anterior y lo daba por atascado; como un jugador, se toca el siguiente punto al llegar)
		await _hasta(func(): return v.destino == null, 30 * 12)
		if _kael().distance_to(c) > 0.6:
			_mal("ruta «%s»: no llega a %s (se queda en %s; %s)" % [nombre, c, _kael(), _que_estorba(c)])
			return false
	return true


func _dialogo_entero() -> String:
	var dg = root.get_node_or_null("Dialogic")
	if dg == null:
		_mal("sin Dialogic")
		return ""
	await _hasta(func(): return dg.current_timeline != null, 60)
	if dg.current_timeline == null:
		return ""
	var ruta: String = dg.current_timeline.resource_path
	var n := 0
	while dg.current_timeline != null and n < 900:
		if n % 5 == 4 and dg.current_state in [dg.States.IDLE, dg.States.REVEALING_TEXT]:
			dg.Inputs.handle_input()
		await process_frame
		n += 1
	if dg.current_timeline != null:
		_mal("el diálogo %s no acaba" % ruta.get_file())
		dg.end_timeline(true)
	await _frames(4)
	return ruta


# Va a una pieza, comprueba el botón y la usa (Intro). Devuelve el diálogo que salió, si salió alguno.
func _usar(id: String) -> String:
	if not await _andar(RUTAS[id], id):
		return ""
	await _frames(3)
	v._comprobar_cerca()
	if v.cerca != id or not v.boton_accion.visible:
		_mal("en «%s» el botón no ofrece la pieza (cerca=«%s», visible %s)" % [id, v.cerca, v.boton_accion.visible])
		return ""
	v._bloqueo = 0.0
	var e := InputEventAction.new()
	e.action = "ui_accept"
	e.pressed = true
	v._unhandled_input(e)
	await _frames(3)
	var dg = root.get_node_or_null("Dialogic")
	if dg != null and dg.current_timeline != null:
		return await _dialogo_entero()
	return ""


func _de_vuelta() -> void:
	v._colocar_kael(T.en_mundo(T.INICIO))
	await _frames(3)


func _correr() -> void:
	await _frames(2)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	if not "sunken3d" in OS.get_cmdline_user_args():
		_apagada()
		return
	_limpiar_partida()
	P.cargar()                                               # partida nueva en el archivo de la prueba
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("partida_lista", true)

	# ---------------------------------------------------------------- 1. interruptor y entrada desde el mapa
	if M.region_activa_con(5, PackedStringArray(["3d"]), false):
		_mal("1: sin «sunken3d» la 3D está activa")
	if not M.region_activa_con(5, PackedStringArray(["3d", "sunken3d"]), false):
		_mal("1: con «sunken3d» la 3D no está activa")
	if not M.EN_PRUEBAS.has(5) or M.POR_DEFECTO_2D_ELEGIBLE.has(5) or not 5 in M.EQUIVALENTES_ZONA:
		_mal("1: Sunken City no está en pruebas (o no tiene su 2D equivalente)")
	if M.escena_de(5) != REGION:
		_mal("1: encendida, el mapa no lleva a la 3D (%s)" % M.escena_de(5))
	await _desde_el_mapa()
	T = load("res://zonas3d/sunken/trazado.gd")
	Sunk = load("res://ciudades/sunken.gd")
	if v == null or v.scene_file_path != REGION:
		_mal("1: desde el mapa no se entra en Sunken City 3D")
		_fin()
		return
	if _kael().distance_to(T.INICIO) > 0.3 or absf(v.kael.global_position.y - 0.0) > 0.25:
		_mal("1: no se entra por el muelle (%s)" % v.kael.global_position)
	var l: Dictionary = Engine.get_meta("lugar", {})
	var mus = root.get_node_or_null("Musica")
	if int(l.get("indice", -1)) != 5 or Engine.get_meta("zona", "") != "ciudad" or (mus != null and mus.contexto_de(v) != "puerto"):
		_mal("1: lugar/zona/ambiente mal (%s, %s)" % [l, Engine.get_meta("zona", "")])
	else:
		_ok("1: interruptor en pruebas; desde el mapa, por el muelle (lugar 5, zona «ciudad», ambiente «puerto»)")

	# ---------------------------------------------------------------- 2. lo andable y los bloqueos
	var malos: Array = []
	for r in T.ANDABLE:
		for i in 25:
			for j in 25:
				var q := (r as Rect2).position + (r as Rect2).size * Vector2((i + 0.5) / 25.0, (j + 0.5) / 25.0)
				if not T.prohibido(q.x, q.y) and q.distance_to(T.ULLA) > 0.7 and q.distance_to(T.BREA) > 0.7:
					var y: float = T.altura(q.x, q.y)
					var hit = _suelo(Vector3(q.x, y + 2.0, q.y))
					if hit == null or absf(hit - y) > 0.12:
						malos.append("%s (suelo %s, y %.2f)" % [q, hit, y])
	if not malos.is_empty():
		_mal("2: lo andable sin suelo a su altura: %s" % [malos.slice(0, 5)])
	for fuera in [Vector2(40.0, 62.0), Vector2(28.0, 40.0), Vector2(40.0, 16.0), Vector2(44.5, 25.6), Vector2(43.0, 36.0)]:
		if not v._prohibido(T.en_mundo(fuera)):
			_mal("2: se puede pisar %s (laguna, proa, escotilla o casa)" % fuera)
	var piezas_ok := 0
	for id in RUTAS:
		await _de_vuelta()
		if await _andar(RUTAS[id], id):
			await _frames(3)
			v._comprobar_cerca()
			if v.cerca != id:
				_mal("2: al final de la ruta de «%s» el botón ofrece «%s»" % [id, v.cerca])
			else:
				piezas_ok += 1
	if piezas_ok == RUTAS.size():
		_ok("2: lo andable tiene suelo; laguna, proa y casas no se pisan; las %d piezas y vecinos, alcanzables andando en línea recta desde el muelle" % piezas_ok)
	# las costillas: tres cruzan la Quilla y la del medio no tiene farol
	var faroles_quilla := 0
	for k in v.casco.anclas:
		if String(k) in ["farol_44", "farol_32"]:
			faroles_quilla += 1
	if faroles_quilla != 2 or v.casco.faroles.any(func(p): return absf(p.z - T.COSTILLA_OSCURA) < 0.2 and absf(p.x - 40.9) < 0.2):
		_mal("2: la costilla que no alumbra tiene farol (o faltan los otros)")
	else:
		_ok("2: costillas de la Quilla con farol en 44 y 32, sin farol en 38 (la pista del secreto)")

	# ---------------------------------------------------------------- 3. guardar y cargar ANTES
	await _de_vuelta()
	P.guardar(REGION)                                        # (lo que hace la escena al entrar: sin posición, por el muelle)
	await _continuar("antes")
	if _kael().distance_to(T.INICIO) > 0.4 or Sunk.estado("sello_pedido") or Sunk.paga_encontrada():
		_mal("3: tras cargar antes de nada, cambia algo (%s)" % _kael())
	else:
		_ok("3: guardar y cargar antes de nada: por el muelle y sin estado")

	# ---------------------------------------------------------------- 4. la misión
	var mis: Dictionary = E.de("sunk_sello")
	if mis.is_empty() or E.estado(mis) != "oculto":
		_mal("4: la misión no está en el registro o ya ha empezado")
	var r1 := await _usar("ulla")
	if not r1.ends_with("sunk_ulla_pedido.dtl") or not Sunk.estado("sello_pedido") or E.estado(mis) != "activo":
		_mal("4: Ulla no empieza la misión (%s)" % r1.get_file())
	elif E.paso_actual(mis).get("id", "") != "brea" or E.pasos_conocidos(mis).size() != 1 or E.pistas_conocidas(mis).size() != 1:
		_mal("4: el Diario adelanta pasos o pistas (%s)" % [E.pasos_conocidos(mis)])
	else:
		_ok("4a: Ulla empieza «El sello de la capitana»; el Diario enseña un paso y una pista")
	await _de_vuelta()
	await _usar("palo")
	if Sunk.estado("sello_hallado") or not v.ultimo_aviso.contains("remendada"):
		_mal("4: sin la pista, el palo mayor da el sello («%s»)" % v.ultimo_aviso)
	var r2 := await _usar("brea")
	if not r2.ends_with("sunk_brea_sello.dtl") or not Sunk.estado("sello_pista") or E.paso_actual(mis).get("id", "") != "sello":
		_mal("4: Brea no da la pista (%s)" % r2.get_file())
	else:
		_ok("4b: el palo sin la pista solo enseña la bandera; Brea da la adivinanza; el Diario: «Busca el sello…»")
	# guardar y cargar A MITAD (en la Cubierta Mayor, con la pista y sin el sello)
	var aqui := _kael()
	v._guardar()
	await _continuar("a mitad")
	if _kael().distance_to(aqui) > 0.4 or not Sunk.estado("sello_pista") or Sunk.estado("sello_hallado"):
		_mal("4: tras cargar a mitad, cambia algo (%s / %s)" % [_kael(), aqui])
	else:
		_ok("4c: guardar y cargar a mitad: el mismo sitio (%s) y la misión igual" % _kael())
	await _de_vuelta()
	await _usar("palo")
	if not Sunk.estado("sello_hallado") or E.paso_actual(mis).get("id", "") != "volver" or E.pistas_conocidas(mis).size() != 3:
		_mal("4: el palo con la pista no da el sello (%s)" % v.ultimo_aviso)
	await _de_vuelta()
	var bronce0: int = Inv.cantidad(Sunk.MATERIAL)
	var r3 := await _usar("ulla")
	await _frames(10)
	if not r3.ends_with("sunk_ulla_fin.dtl") or E.estado(mis) != "hecho" or Inv.cantidad(Sunk.MATERIAL) != bronce0 + 1:
		_mal("4: Ulla no cierra la misión con el bronce (%s, %d)" % [r3.get_file(), Inv.cantidad(Sunk.MATERIAL)])
	await _de_vuelta()
	var r4 := await _usar("ulla")
	if not r4.ends_with("sunk_ulla_despues.dtl") or Inv.cantidad(Sunk.MATERIAL) != bronce0 + 1:
		_mal("4: hablar otra vez con Ulla da más bronce o repite (%s)" % r4.get_file())
	else:
		_ok("4d: el sello en el palo; Ulla cierra la misión y da el Bronce del Águila una sola vez; luego dice otra cosa")
	await _de_vuelta()
	var r5 := await _usar("brea")
	if not r5.ends_with("sunk_brea_despues.dtl"):
		_mal("4: Brea no reacciona al contrato sellado (%s)" % r5.get_file())

	# ---------------------------------------------------------------- 5. el secreto
	await _de_vuelta()
	await _usar("grabado")
	if not Sunk.estado("grabado_visto") or not v.ultimo_aviso.contains("no alumbra"):
		_mal("5: el grabado no se lee")
	var oro0: int = Inv.oro()
	var eter0: int = Inv.cantidad("Éter")
	await _de_vuelta()
	await _usar("tabla")
	await _frames(5)
	if not Sunk.paga_encontrada() or Inv.oro() != oro0 + 80 or Inv.cantidad("Éter") != eter0 + 1:
		_mal("5: la tabla no da la paga (oro %d → %d)" % [oro0, Inv.oro()])
	v._bloqueo = 0.0
	v.cerca = "tabla"
	v._accion()
	await _frames(3)
	if Inv.oro() != oro0 + 80 or Inv.cantidad("Éter") != eter0 + 1 or not v.ultimo_aviso.contains("ya no queda"):
		_mal("5: la tabla da la paga dos veces")
	else:
		_ok("5: el grabado («la costilla que no alumbra») y la tabla suelta: 80 monedas y 1 Éter, una sola vez")

	# ---------------------------------------------------------------- 6. la recompensa en la forja de Kael
	var I = load("res://investigacion.gd")
	var Ta = load("res://talleres.gd")
	if not Ta.reservado(Sunk.MATERIAL):
		_mal("6: el bronce se puede vender o gastar antes de estudiarlo")
	if not I.visible("kael_bronce_aguila") or I.empezar("kael_bronce_aguila") != "":
		_mal("6: no se puede estudiar «El bronce del casco»")
	I.avanzar("kael_bronce_aguila")
	var vit0: int = int(load("res://grupo.gd").estadisticas("Kael")["atributos"]["vitalidad"])
	if I.estado("kael_bronce_aguila") != "completada" or Ta.puede("kael_guarda_aguila") != "":
		_mal("6: estudiado, la receta no se puede forjar («%s»)" % Ta.puede("kael_guarda_aguila"))
	elif not Ta.reservado(Sunk.MATERIAL):   # (la tienda no ofrece vender lo reservado: tienda.gd, _pintar)
		_mal("6: estudiado pero sin forjar, el bronce se puede vender (y la Guarda quedaría perdida)")
	elif not Ta.fabricar("kael_guarda_aguila") or Inv.cantidad(Sunk.MATERIAL) != 0 \
			or int(load("res://grupo.gd").estadisticas("Kael")["atributos"]["vitalidad"]) != vit0 + 2:
		_mal("6: forjar la Guarda del Águila no da +2 de vitalidad o no gasta el bronce")
	elif Ta.fabricar("kael_guarda_aguila") or Ta.puede("kael_guarda_aguila") == "":
		_mal("6: la Guarda del Águila se forja dos veces")
	elif Ta.reservado(Sunk.MATERIAL):
		_mal("6: forjada la Guarda, el bronce sigue reservado")
	else:
		_ok("6: el bronce, reservado hasta estudiarlo; la Guarda del Águila: +2 de vitalidad para siempre, una vez")

	# ---------------------------------------------------------------- 7. el detalle y la tienda
	await _de_vuelta()
	await _usar("contratos")
	if not P.visto("sunken_contratos") or P.detalles_de(5)[0]["id"] != "sunken_contratos":
		_mal("7: el detalle «sunken_contratos» no queda visto")
	else:
		_ok("7a: el detalle de canon «sunken_contratos», con su id, en el atril del Archivo")
	await _de_vuelta()
	await _usar("tienda")
	await _frames(10)
	if v.abierto == null or not load("res://equipo_extra.gd").en_tienda(5).size() > 0:
		_mal("7: la tienda no se abre o no es la del lugar 5")
	else:
		_ok("7b: el puesto abre la tienda del lugar 5 (%s)" % [load("res://equipo_extra.gd").en_tienda(5)])
	if v.abierto != null:
		v.abierto.queue_free()
		v.abierto = null
	await _frames(3)

	# ---------------------------------------------------------------- 8. DESPUÉS, partida antigua, salida y vuelta
	v._colocar_kael(T.en_mundo(Vector2(52.6, 45.6)))
	await _frames(3)
	v._guardar()
	var oro1: int = Inv.oro()
	await _continuar("después")
	if _kael().distance_to(Vector2(52.6, 45.6)) > 0.4 or absf(v.kael.global_position.y - T.ALTO_ARCHIVO) > 0.2 \
			or E.estado(mis) != "hecho" or not Sunk.paga_encontrada() or Inv.oro() != oro1 or not P.visto("sunken_contratos"):
		_mal("8: tras cargar al final, cambia algo (%s)" % v.kael.global_position)
	else:
		_ok("8a: guardar y cargar después, en el Archivo (en alto): todo igual")
	var antigua := {"escena_guardada": REGION, "lugar": {"indice": 5, "nombre": "Sunken City", "tipo": "ciudad", "zona": "ciudad", "texto": "x"},
		"inventario": Engine.get_meta("inventario"), "grupo": Engine.get_meta("grupo")}
	for k in P.CLAVES + ["pos_3d", "pos_3d_ok", "partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var esc: String = P.restaurar(antigua)
	await _cargar_region()
	if esc != REGION or v == null or Sunk.estado("sello_pedido") or Sunk.paga_encontrada() \
			or not Sunk.dialogo_de("ulla").ends_with("sunk_ulla_pedido.dtl") or E.estado(E.de("sunk_sello")) != "oculto":
		_mal("8: una partida antigua sin las claves no carga limpia (%s)" % esc)
	else:
		_ok("8b: partida antigua (sin mazmorras, cofres ni lore): carga, por el muelle y todo por hacer")
	v._colocar_kael(T.en_mundo(Vector2(40.0, 57.2)))
	v.salida["armada"] = true
	await _frames(3)
	v.destino = T.en_mundo(T.SALIDA)
	await _hasta(func(): return current_scene != null and current_scene.scene_file_path == P.MAPA, 400)
	if current_scene == null or current_scene.scene_file_path != P.MAPA:
		_mal("8: el final del muelle no lleva al mapa")
	else:
		await _frames(30)
		await _desde_el_mapa()
		if v == null or v.scene_file_path != REGION or _kael().distance_to(T.INICIO) > 0.3:
			_mal("8: al volver a entrar no se llega por el muelle")
		else:
			_ok("8c: salida al mapa por el muelle y vuelta a entrar por el mismo sitio")

	# ---------------------------------------------------------------- 9. referencias y textos
	_referencias()
	_fin()


# Entrar desde el mapa como mapa.gd _entrar: en el mapa, el lugar 5 y lo que deja en Engine, y la escena que elige
# (modo3d.escena_de). La carga en segundo plano de Recursos.cambiar_escena falla en las pruebas sin ventana con
# --fixed-fps 30 (también con Ciclópea 3D: es del entorno de pruebas; en el juego y sin --fixed-fps entra bien), así que
# aquí se cambia de escena directamente.
func _desde_el_mapa() -> void:
	if current_scene == null or current_scene.scene_file_path != P.MAPA:
		change_scene_to_file(P.MAPA)
		await _hasta(func(): return current_scene != null and current_scene.scene_file_path == P.MAPA, 300)
		await _frames(30)
	var mapa = current_scene
	var lugar: Dictionary = mapa.lugares[5]
	Engine.set_meta("lugar", {"indice": 5, "nombre": lugar["nombre"], "tipo": lugar["tipo"],
		"zona": load("res://mapa.gd").ZONA_LUGAR[5], "texto": lugar["texto"]})
	Engine.set_meta("pos_mapa_ok", true)
	Engine.set_meta("pos_zona_ok", false)
	Engine.set_meta("pos_3d_ok", false)
	var ruta: String = load("res://modo3d.gd").escena_de(5)
	if ruta != REGION:
		_mal("el mapa no elige la 3D para el lugar 5 («%s»)" % ruta)
		return
	await _cargar_region()


# Lo que para a Kael (para el mensaje de fallo): el choque delante, a la altura de las rodillas, o lo prohibido.
func _que_estorba(c: Vector2) -> String:
	var k: Vector3 = v.kael.global_position
	var meta: Vector3 = T.en_mundo(c)
	var dir := Vector3(meta.x - k.x, 0, meta.z - k.z).normalized()
	var desde := Vector3(k.x, k.y + 0.6, k.z)
	var q := PhysicsRayQueryParameters3D.create(desde, desde + dir * 0.6)
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		return "choque «%s» en %s" % [r["collider"].name, r["position"]]
	var p := k + dir * 0.15
	var q2 := PhysicsRayQueryParameters3D.create(Vector3(p.x, k.y + 0.55, p.z), Vector3(p.x, k.y - 8.0, p.z))
	var r2: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q2)
	var abajo := "nada" if r2.is_empty() else "«%s/%s» y %.2f normal %s" % [r2["collider"].get_parent().name, r2["collider"].name, r2["position"].y, r2["normal"]]
	return "prohibido %s, abajo %s, y_kael %.2f, altura %s, destino %s" % [v._prohibido(p), abajo, k.y, v._altura_suelo(p, k.y), v.destino]


func _suelo(desde: Vector3):
	var q := PhysicsRayQueryParameters3D.create(desde, desde + Vector3(0, -6, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	return r["position"].y if not r.is_empty() else null


func _referencias() -> void:
	var malos: Array = []
	var dir := DirAccess.open("res://dialogos/sunken")
	var dtl := 0
	for f in dir.get_files():
		if not f.ends_with(".dtl"):
			continue
		dtl += 1
		for linea in FileAccess.get_file_as_string("res://dialogos/sunken/" + f).split("\n"):
			if linea.contains(":") and not linea.begins_with("["):
				var texto := linea.substr(linea.find(":") + 1).strip_edges()
				if texto.length() > 110:
					malos.append("%s: frase de %d letras" % [f, texto.length()])
				for prohibida in ["Érebo", "corazón", "recuerdo", "brazalete", "Astraea", "hambre"]:
					if texto.to_lower().contains(prohibida.to_lower()):
						malos.append("%s: «%s» (restricción de canon)" % [f, prohibida])
	for id in ["ulla", "brea"]:
		if not ResourceLoader.exists(Sunk.PERSONAJES[id]):
			malos.append("falta el personaje " + id)
		var pg := FileAccess.get_file_as_string("res://project.godot")
		if not pg.contains("\"%s\": \"%s\"" % [id, Sunk.PERSONAJES[id]]):
			malos.append("%s no está en project.godot" % id)
	for e in ["sunk_ulla_pedido", "sunk_ulla_pendiente", "sunk_ulla_fin", "sunk_ulla_despues", "sunk_brea", "sunk_brea_sello", "sunk_brea_despues"]:
		if not ResourceLoader.exists(Sunk.RUTA + e + ".dtl"):
			malos.append("falta " + e)
	var errores: Array = load("res://datos/catalogo.gd").validar()
	if not errores.is_empty():
		malos.append_array(errores)
	var m: Dictionary = load("res://datos/encargos_sunken.gd").MISIONES[0]
	for c in [m["empieza"], m["fin"]] + m["pasos"].map(func(p): return p["hecho"]) + m["pistas"].map(func(p): return p["si"]):
		if not str(c).begins_with("estado_de:sunken/"):
			malos.append("condición rara: %s" % c)
	# los comentarios del grupo: solo quien está (con Lya y Garon, Lya y la respuesta de Garon; con Kael solo, Kael)
	if Engine.has_meta("comentarios_dichos"):
		Engine.remove_meta("comentarios_dichos")
	var c1: Dictionary = Sunk.comentario("llegar", ["Kael", "Lya", "Garon"])
	var c2: Dictionary = Sunk.comentario("lona", ["Kael"])
	if c1.get("quien", "") != "Lya" or c1.get("respuesta", {}).get("quien", "") != "Garon" or c2.get("quien", "") != "Kael" \
			or not Sunk.comentario("llegar", ["Kael", "Lya", "Garon"]).is_empty():
		malos.append("comentarios del grupo: %s / %s" % [c1, c2])
	for t in [Sunk.TEXTO_POPA, Sunk.TEXTO_BANDERA, Sunk.TEXTO_SELLO, Sunk.TEXTO_GRABADO, Sunk.TEXTO_TABLA_LEIDO, Sunk.TEXTO_ESCOTILLA, Sunk.TEXTO_PROA, Sunk.TEXTO_LONA]:
		if t.length() > 110:
			malos.append("texto de %d letras: %s" % [t.length(), t])
	if malos.is_empty():
		_ok("9: %d diálogos y 2 personajes registrados, frases ≤ 110 sin términos vetados, catálogo válido, condiciones del Diario y comentarios del grupo" % dtl)
	else:
		_mal("9: %s" % [malos])


# Sin «sunken3d»: el mapa lleva a la 2D; una partida de la 2D se queda en la 2D; una de la 3D vuelve a la 2D por su entrada.
func _apagada() -> void:
	T = load("res://zonas3d/sunken/trazado.gd")
	if M.elegida("sunken3d"):
		_mal("apagada: Ajustes de esta pasada ya traen la 3D elegida")
	if M.escena_de(5) != "":
		_mal("apagada: el mapa lleva a la 3D (%s)" % M.escena_de(5))
	Engine.set_meta("pos_zona_ok", false)
	if M.escena_equivalente("res://zona.tscn", 5) != "":
		_mal("apagada: una partida de la 2D se va a la 3D")
	var r: String = P.restaurar({"escena_guardada": "res://zona.tscn", "lugar": {"indice": 5, "nombre": "Sunken City", "tipo": "ciudad", "zona": "ciudad", "texto": "x"}})
	if r != "res://zona.tscn":
		_mal("apagada: una partida de la Sunken City 2D ya no abre zona.tscn (%s)" % r)
	Engine.set_meta("pos_3d", T.en_mundo(Vector2(40.0, 30.0)))
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", 5)
	var e: String = M.escena_equivalente(REGION, 5)
	if e != "res://zona.tscn" or Engine.get_meta("pos_zona_ok", false) or int(Engine.get_meta("lugar", {}).get("indice", -1)) != 5:
		_mal("apagada: una partida de la 3D no vuelve a la 2D por su entrada («%s», %s)" % [e, Engine.get_meta("pos_zona_ok", false)])
	else:
		_ok("apagada: el mapa lleva a la 2D; una partida de la 2D se queda; una de la 3D abre la 2D por su entrada")
	_fin()


func _fin() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
