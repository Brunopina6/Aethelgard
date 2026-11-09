extends SceneTree
# Prueba de Oakhaven jugada (T-089, fase 2): la ciudad hecha a mano (ciudad_oakhaven.gd) con los datos de
# ciudades/oakhaven.gd. Sin ventana, con «-- 3d sin_prologo» (con la exploración 3D existe lo que depende de ella: la
# lavanda de Rosa en Pastos Verdes y el cofre de los requisados, que espera a que Kael haya salido de la ciudad).
# Usa su propia partida (user://prueba_oakhaven.save, Engine «archivo_partida_prueba»): nunca toca la de verdad.
#   1. Entrar desde el mapa (botón «Entrar» junto a Oakhaven): se abre ciudad_oakhaven.tscn con Kael en la Puerta del
#      Sur, la música de la ciudad, los ocho vecinos en su casilla, los cuatro cofres cerrados, las piezas, las notas,
#      los detalles de canon en su sitio nuevo y el Árbol en lugar del altar.
#   2. Trazado: se pisa justo lo que ciudades/oakhaven.gd dice que se pisa (salvo la grieta, que se pasa de lado); desde
#      la puerta se llega andando a los ocho vecinos, a las notas y a los cofres de la calle, y no a la ronda ni al Patio
#      de las Velas; la taberna, un jardín y el muro de la grieta no se atraviesan.
#   3. Hablar con los ocho: el botón dice su nombre, se abre el diálogo que toca y se recorre entero; la segunda vez,
#      otro (se turnan).
#   4. El secreto de Pip (una moneda) y la misión «Tres favores para el Cuervo» entera, con su recompensa una sola vez;
#      la posada con la noche gratis (no cobra, cura y sale la escena del grupo) y después pagando.
#   5. Piezas: la torre (la vista, solo la primera vez), un farol antes de la misión (no se enciende), «Los faroles de la
#      ronda» entera con Bastián; desde el suelo no se usa lo de la ronda; la grieta en los dos sentidos (el brazalete
#      brilla cerca y el patio se ve al pasar).
#   6. Un cofre una sola vez (premio exacto y en «cofres_abiertos») y el de los requisados, cerrado hasta PV-02.
#   7. Una nota: su aviso, «lore_visto» y la sección «Notas» del Diario, sin completar ningún acto.
#   8. Salir por la puerta al mapa y volver: lo abierto sigue abierto y lo hecho, hecho; las conexiones a Dialogic no se
#      acumulan.
#   9. Guardar y cargar: se vuelve a la ciudad, al mismo sitio y con todo igual.
#  10. «Lavanda para el Árbol»: Rosa la pide; en Pastos Verdes 3D sale el ramito, se coge una vez; se entrega a Rosa y
#      Doña Encina da las gracias.
#  11. El camino del arte de gráficos, con un módulo falso (pruebas/oakhaven_arte_falso.gd, Engine «oakhaven_arte_prueba»):
#      los dibujos van a su sitio, bajo los edificios y las casas con dibujo hay muro invisible, se pisa lo mismo que sin
#      arte, no se pinta la provisional de lo que tiene dibujo, los estados (faroles y cofres) y el ambiente.
# Lo que comprueba del dibujo provisional (la luz de los faroles) solo lo mira si el farol es el provisional.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const MAPA := "res://mapa.tscn"
const CIUDAD := "res://ciudad_oakhaven.tscn"
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ARCHIVO := "user://prueba_oakhaven.save"
const T := 64.0

var P
var inv
var G
var R
var D
var Mus
var fallos: Array = []
var hechos: Array = []
var senales: Array = []                   # señales de Dialogic del diálogo en curso
var pregunta_abierta := false
var frame_pregunta := 0


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


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _en(ruta: String) -> bool:
	return _escena() == ruta and not R.cambiando and current_scene.get("jugador") != null


func _conexiones() -> Array:
	return [D.signal_event.get_connections().size(), D.timeline_ended.get_connections().size()]


func _al_senal(a) -> void:
	senales.append(str(a))


func _al_pregunta(_info) -> void:
	pregunta_abierta = true
	frame_pregunta = Engine.get_process_frames()


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


# ================================================================= utilidades de juego

# Recorre el diálogo abierto hasta el final. En cada pregunta elige la opción que toque de «elegir» (1, 2…; si se
# acaban, la 1). Devuelve las señales que han llegado.
func _recorrer(elegir: Array = []) -> Array:
	senales = []
	var cola := elegir.duplicate()
	pregunta_abierta = false
	var limite := Time.get_ticks_msec() + 30000
	var ultimo := 0
	while D.current_timeline != null and Time.get_ticks_msec() < limite:
		await process_frame
		var f := Engine.get_process_frames()
		if pregunta_abierta:
			if f - frame_pregunta >= 10:
				pregunta_abierta = false
				D.Choices.select_choice(cola.pop_front() if not cola.is_empty() else 1)
				ultimo = f
			continue
		if D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT] and f - ultimo >= 4:
			D.Inputs.handle_input()
			ultimo = f
	if D.current_timeline != null:
		_fallo("un diálogo no termina (%s)" % D.current_timeline.resource_path)
		D.end_timeline(true)
	await _esperar(4)
	return senales.duplicate()


func _vecino(z, id: String) -> Variant:
	for n in z.npcs:
		if n[1].get("id", "") == id:
			return n
	return null


# Habla con un vecino como un jugador: se pone a su lado, mira el botón y pulsa. Devuelve la ruta del diálogo abierto.
func _hablar(z, id: String, elegir: Array = []) -> String:
	var n = _vecino(z, id)
	if n == null:
		_fallo("no está el vecino «%s»" % id)
		return ""
	var esperado: String = Oak.dialogo_de(id, n[2])
	z.jugador.position = n[0].position + Vector2(40, 30)
	await _esperar(3)
	z._comprobar_cerca()
	var boton := "Hablar con " + str(n[1].get("corto", ""))
	if not z.boton_examinar.visible or z.boton_examinar.text != boton:
		_fallo("junto a %s el botón dice «%s» (visible: %s), no «%s»" % [id, z.boton_examinar.text, z.boton_examinar.visible, boton])
	z._accion()
	await _esperar(2)
	if D.current_timeline == null:
		_fallo("hablar con %s no abre ningún diálogo (tocaba %s)" % [id, esperado])
		return ""
	var ruta: String = D.current_timeline.resource_path
	if ruta != esperado:
		_fallo("%s: se abre %s y tocaba %s" % [id, ruta, esperado])
	await _recorrer(elegir)
	return ruta


func _pieza(z, id: String) -> Variant:
	for e in z.piezas:
		if e[1]["id"] == id:
			return e
	return null


func _cofre(z, id: String) -> Variant:
	for c in z.cofres:
		if c[1] == id:
			return c
	return null


# Usa una pieza como un jugador: se pone «desde» (casillas), mira que se elija esa pieza y el botón, y pulsa.
func _usar(z, id: String, desde: Vector2, boton: String) -> void:
	z.jugador.position = desde * T
	await _esperar(3)
	z._comprobar_cerca()
	if z.pieza_cerca == null or z.pieza_cerca[1]["id"] != id:
		_fallo("en %s no se elige la pieza %s (%s)" % [desde, id, z.pieza_cerca[1]["id"] if z.pieza_cerca != null else "nada"])
		return
	if z.boton_examinar.text != boton:
		_fallo("%s: el botón dice «%s», no «%s»" % [id, z.boton_examinar.text, boton])
	z._accion()
	await _esperar(2)
	await _hasta(func(): return not z.viajando, 5.0)
	await _esperar(3)


func _cerca_de(z, casilla: Vector2, margen := 0.3) -> bool:
	return z.jugador.position.distance_to(casilla * T) < margen * T


func _aviso_llega(z, texto: String, segundos := 12.0) -> bool:
	return await _hasta(func(): return z.aviso.text == texto, segundos)


func _entrar_desde_el_mapa() -> Variant:
	if _escena() != MAPA:
		change_scene_to_file(MAPA)
	if not await _hasta(func(): return _en(MAPA), 60.0):
		_fallo("no se abre el mapa (%s)" % _escena())
		return null
	await _esperar(10)
	var m = current_scene
	m.jugador.position = m.lugares[0]["pos"] + Vector2(20, 0)
	m._comprobar_cerca()
	if not m.boton_entrar.visible or m.cerca != m.lugares[0]:
		_fallo("junto a Oakhaven no sale «Entrar»")
	m._entrar()
	if not await _hasta(func(): return _en(CIUDAD), 90.0):
		_fallo("desde el mapa no se entra en la ciudad hecha a mano (%s)" % _escena())
		return null
	await _esperar(10)
	return current_scene


# ================================================================= la prueba

func _probar() -> void:
	P = load("res://progreso.gd")
	inv = load("res://inventario.gd")
	G = load("res://grupo.gd")
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	Mus = root.get_node_or_null("Musica")
	if D == null or not load("res://modo3d.gd").activo():
		_fallo("hace falta Dialogic y «-- 3d»")
		_terminar()
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)          # como si la partida se hubiera cargado al arrancar
	Engine.set_meta("prologo_visto", true)
	G.empezar_solo()                                # partida nueva de la versión experimental: Kael, solo
	D.signal_event.connect(_al_senal)
	D.Choices.question_shown.connect(_al_pregunta)
	await _esperar(3)
	var base := _conexiones()
	var z = await _entrar_desde_el_mapa()
	if z == null:
		_terminar()
		return
	await _entrada(z, base)
	await _trazado(z)
	await _vecinos(z)
	await _favores(z)
	await _posada(z)
	await _torre_y_faroles(z)
	await _grieta(z)
	await _cofres(z)
	await _nota(z)
	z = await _salir_y_volver(z, base)
	if z != null:
		z = await _guardar_y_cargar(z)
	if z != null:
		z = await _lavanda(z)
	if z != null:
		await _con_arte(z)
	_terminar()


func _terminar() -> void:
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	Engine.remove_meta("oakhaven_arte_prueba")
	print("OK Oakhaven jugada: ", ", ".join(PackedStringArray(hechos)))
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Al entrar.
func _entrada(z, base: Array) -> void:
	if not _cerca_de(z, Oak.INICIO, 1.0):
		_fallo("1: Kael no aparece en la Puerta del Sur (%s)" % (z.jugador.position / T))
	if Mus != null and not await _hasta(func(): return Mus.contexto == "ciudad", 5.0):
		_fallo("1: la música de la ciudad no suena (contexto «%s»)" % Mus.contexto)
	if z.lugar.get("nombre", "") != "Oakhaven" or not z.es_ciudad:
		_fallo("1: el lugar no es la ciudad de Oakhaven (%s)" % z.lugar)
	if z.npcs.size() != Oak.NPCS.size():
		_fallo("1: hay %d vecinos y no %d" % [z.npcs.size(), Oak.NPCS.size()])
	for n in z.npcs:
		if n[0].position != n[1]["casilla"] * T:
			_fallo("1: %s no está en su casilla" % n[1]["id"])
	var ids := []
	for c in z.cofres:
		ids.append(c[1])
		if c[2]:
			_fallo("1: el cofre %s ya está abierto al entrar" % c[1])
	if ids != Oak.COFRES.map(func(c): return c["id"]):
		_fallo("1: los cofres son %s" % [ids])
	if z.piezas.size() != Oak.PIEZAS.size():
		_fallo("1: hay %d piezas y no %d" % [z.piezas.size(), Oak.PIEZAS.size()])
	if z.notas.size() != Oak.NOTAS.filter(func(n): return n.has("casilla")).size():
		_fallo("1: hay %d notas en la ciudad" % z.notas.size())
	if z.detalles.size() != P.detalles_de(0).size():
		_fallo("1: hay %d detalles de canon" % z.detalles.size())
	for dt in z.detalles:
		if dt[0].position != Oak.SITIOS_DETALLE[dt[1]["id"]] * T:
			_fallo("1: el detalle %s no está en su sitio nuevo" % dt[1]["id"])
	if z.altar.position != Vector2(40, 9) * T or z.arbol == null:
		_fallo("1: el Árbol no está en lugar del altar (%s)" % (z.altar.position / T))
	if z._boton_hud("POSADA").text != "POSADA (30)":
		_fallo("1: el botón de la posada dice «%s»" % z._boton_hud("POSADA").text)
	if _conexiones() != [base[0] + 1, base[1] + 1]:
		_fallo("1: conexiones a Dialogic %s (antes de entrar, %s)" % [_conexiones(), base])
	hechos.append("entrar desde el mapa")


# 2. Lo que se pisa, lo que se alcanza andando y lo que choca.
func _trazado(z) -> void:
	var malas: Array = []
	var grieta: Rect2 = Oak.LUGARES.filter(func(l): return l["id"] == "grieta")[0]["rect"]
	for y in z.ALTO:
		for x in z.ANCHO:
			var c := Vector2(x + 0.5, y + 0.5)
			var pisable := false
			var edificio := false
			for l in Oak.LUGARES:
				if l["rect"].has_point(c):
					pisable = pisable or l["pisable"]
					edificio = edificio or not l["pisable"]
			var esperado := pisable and not edificio and not grieta.has_point(c)
			if esperado != (z.muros[y * z.ANCHO + x] == 0):
				malas.append(Vector2i(x, y))
	if not malas.is_empty():
		_fallo("2: %d casillas no se pisan como dicen los datos (p. ej. %s)" % [malas.size(), malas.slice(0, 6)])
	var desde_puerta := _alcanzables(z, Oak.INICIO)
	var desde_ronda := _alcanzables(z, _pieza(z, "oak_torre")[1]["lleva_a"])
	var desde_patio := _alcanzables(z, _pieza(z, "oak_grieta")[1]["lleva_a"])
	for n in Oak.NPCS:
		if not desde_puerta.has(Vector2i(n["casilla"])):
			_fallo("2: desde la puerta no se llega a %s" % n["id"])
	for c in Oak.COFRES:
		var en_calle: bool = not c["id"] in ["oak_cofre_velas", "oak_cofre_ronda"]
		if desde_puerta.has(Vector2i(c["casilla"])) != en_calle:
			_fallo("2: el cofre %s %s desde la puerta" % [c["id"], "no se alcanza" if en_calle else "se alcanza"])
	if not desde_ronda.has(Vector2i(_cofre(z, "oak_cofre_ronda")[0].position / T)):
		_fallo("2: desde la ronda no se llega a su cofre")
	if not desde_patio.has(Vector2i(_cofre(z, "oak_cofre_velas")[0].position / T)):
		_fallo("2: desde el patio no se llega al cofre de las velas")
	for nd in Oak.NOTAS:
		if nd.has("casilla"):
			var a: Dictionary = desde_patio if nd["id"] == "nota_oak_velas" else desde_puerta
			if not a.has(Vector2i(nd["casilla"])):
				_fallo("2: no se llega a la nota %s" % nd["id"])
	for id in ["oak_farol_1", "oak_farol_2", "oak_farol_3", "oak_ronda_bajar"]:
		var c: Vector2i = Vector2i(_pieza(z, id)[1]["casilla"])
		if desde_puerta.has(c) or not desde_ronda.has(c):
			_fallo("2: %s no está solo en la ronda" % id)
	for l in Oak.LUGARES:
		if l["id"] in ["ronda", "patio_velas"]:
			for y in range(int(l["rect"].position.y), int(l["rect"].end.y)):
				for x in range(int(l["rect"].position.x), int(l["rect"].end.x)):
					if desde_puerta.has(Vector2i(x, y)):
						_fallo("2: desde la puerta se llega andando a %s (%d, %d)" % [l["id"], x, y])
	# choques de verdad (con la física): la taberna, un jardín junto a una calle y el muro de la grieta
	var jardin := Vector2i(-1, -1)
	for c in z.jardines:
		if c.x > 2 and z.muros[c.y * z.ANCHO + c.x - 1] == 0 and z.muros[c.y * z.ANCHO + c.x - 2] == 0 \
				and z.npcs.all(func(n): return n[0].position.distance_to((Vector2(c) + Vector2(0.5, 0.5)) * T) > 3.0 * T):
			jardin = c
			break
	if jardin.x < 0:
		_fallo("2: no hay ningún jardín junto a una calle")
	var casos := [["la taberna", Vector2(17.5, 25.6), "ui_up", func(p): return p.y >= 25.0 * T - 1.0],
		["el muro de la grieta", Vector2(23.5, 34.6), "ui_down", func(p): return p.y <= 35.0 * T + 1.0]]
	if jardin.x >= 0:
		casos.append(["un jardín", Vector2(jardin.x - 0.6, jardin.y + 0.5), "ui_right",
			func(p): return p.x <= jardin.x * T + 1.0])
	for caso in casos:
		z.jugador.position = caso[1] * T
		await _esperar(2)
		Input.action_press(caso[2])
		await _esperar(30)
		Input.action_release(caso[2])
		await _esperar(2)
		if not caso[3].call(z.jugador.position):
			_fallo("2: Kael atraviesa %s (acaba en %s)" % [caso[0], z.jugador.position / T])
	hechos.append("trazado")


# Casillas a las que se llega andando desde «desde» (casillas pisables, 4 vecinas).
func _alcanzables(z, desde: Vector2) -> Dictionary:
	var r := {}
	var cola: Array = [Vector2i(desde)]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		if r.has(c) or c.x < 0 or c.y < 0 or c.x >= z.ANCHO or c.y >= z.ALTO or z.muros[c.y * z.ANCHO + c.x] != 0:
			continue
		r[c] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			cola.append(c + d)
	return r


# 3. Los ocho vecinos y el turno de sus diálogos.
func _vecinos(z) -> void:
	for n in Oak.NPCS:
		await _hablar(z, n["id"], [2])
	if await _hablar(z, "albar") != Oak.ruta_dialogo("oak_albar_puerta"):
		_fallo("3: la segunda vez, Albar no dice otra cosa")
	hechos.append("hablar con los ocho vecinos")


# 4. El secreto de Pip y «Tres favores para el Cuervo».
func _favores(z) -> void:
	var oro: int = inv.oro()
	await _hablar(z, "pip", [1])                    # oak_pip_secreto: pagar
	if inv.oro() != oro - 1 or not Oak.cumple("decision:pip_oak=pagado"):
		_fallo("4: pagar a Pip no cobra una moneda o no apunta la decisión (%d → %d)" % [oro, inv.oro()])
	if not await _aviso_llega(z, "Le das una moneda a Pip."):
		_fallo("4: tras pagar a Pip no sale el aviso («%s»)" % z.aviso.text)
	if await _hablar(z, "pip") != Oak.ruta_dialogo("oak_pip_despues"):
		_fallo("4: después de pagar, Pip no dice lo de después")
	await _hablar(z, "posadera")                    # la segunda vez: los tres favores
	if Oak.estado_mision("oak_favores") != "en_curso":
		_fallo("4: la posadera no da la misión (%s)" % Oak.estado_mision("oak_favores"))
	if not await _aviso_llega(z, "Misión: Tres favores para el Cuervo."):
		_fallo("4: no sale el aviso de la misión («%s»)" % z.aviso.text)
	await _usar(z, "oak_barril", Vector2(12, 29.7), "Subir el barril")
	if not P.estado("oakhaven", "favor_barril") or not "Favor hecho (1 de 3)." in z.aviso.text:
		_fallo("4: el barril no cuenta («%s»)" % z.aviso.text)
	await _hablar(z, "rosa")
	await _hablar(z, "pip")
	if not (P.estado("oakhaven", "favor_flores") and P.estado("oakhaven", "favor_cucharon")):
		_fallo("4: las flores o el cucharón no cuentan")
	var pociones: int = inv.cantidad("Poción")
	await _hablar(z, "posadera")
	if Oak.estado_mision("oak_favores") != "hecha" or inv.cantidad("Poción") != pociones + 2:
		_fallo("4: la misión no acaba o no da 2 Pociones (%d → %d)" % [pociones, inv.cantidad("Poción")])
	if not P.estado("oakhaven", "noche_gratis") or z._boton_hud("POSADA").text != "POSADA (gratis)":
		_fallo("4: no queda la noche gratis («%s»)" % z._boton_hud("POSADA").text)
	if Oak.aplicar_senal("oak:favores_hechos") != "" or inv.cantidad("Poción") != pociones + 2:
		_fallo("4: la recompensa se da dos veces")
	await _usar(z, "oak_barril", Vector2(12, 29.7), "Examinar")
	if z.aviso.text != Oak.pieza("oak_barril")["texto_sin"]:
		_fallo("4: el barril, hecho el favor, dice «%s»" % z.aviso.text)
	hechos.append("Tres favores para el Cuervo")


# Posada: la noche gratis y la escena del grupo; luego, pagando.
func _posada(z) -> void:
	G.guardar_vida("Kael", 1, 0)
	var oro: int = inv.oro()
	z._posada()
	if not await _hasta(func(): return D.current_timeline != null, 6.0):
		_fallo("4: tras la posada no sale la escena del grupo")
	elif D.current_timeline.resource_path != Oak.escena_posada():
		_fallo("4: la escena de la posada es %s (tocaba %s)" % [D.current_timeline.resource_path, Oak.escena_posada()])
	await _recorrer()
	var e: Dictionary = G.estadisticas("Kael")
	if inv.oro() != oro or P.estado("oakhaven", "noche_gratis"):
		_fallo("4: la noche gratis cobra o no se gasta (%d → %d)" % [oro, inv.oro()])
	if int(G.datos()["Kael"]["pv"]) != int(e["pv_max"]):
		_fallo("4: la posada no cura (PV %s de %s)" % [G.datos()["Kael"]["pv"], e["pv_max"]])
	if not await _aviso_llega(z, Oak.TEXTO_NOCHE_GRATIS):
		_fallo("4: no se dice que invita la posadera («%s»)" % z.aviso.text)
	if z._boton_hud("POSADA").text != "POSADA (30)":
		_fallo("4: tras la noche gratis, el botón dice «%s»" % z._boton_hud("POSADA").text)
	z._posada()
	await _hasta(func(): return D.current_timeline != null, 6.0)
	await _recorrer()
	if inv.oro() != oro - 30:
		_fallo("4: la posada pagando no cobra 30 (%d → %d)" % [oro, inv.oro()])
	hechos.append("posada")


# 5. La torre, la ronda y sus faroles.
func _torre_y_faroles(z) -> void:
	z.jugador.position = Vector2(75.7, 42.3) * T        # al pie de la torre, junto a la ronda (que va en alto)
	await _esperar(3)
	z._comprobar_cerca()
	if z.pieza_cerca != null and z.pieza_cerca[1]["id"] == "oak_ronda_bajar":
		_fallo("5: desde el suelo se puede usar la escalera de la ronda")
	await _usar(z, "oak_torre", Vector2(73.5, 43.2), "Subir")
	if not _cerca_de(z, Oak.pieza("oak_torre")["lleva_a"]) or not P.estado("oakhaven", "vista_torre"):
		_fallo("5: subir a la torre no lleva a la ronda (%s)" % (z.jugador.position / T))
	var vista: String = Oak.SECRETOS.filter(func(s): return s["id"] == "oak_vista_torre")[0]["texto"]
	if not await _aviso_llega(z, vista):
		_fallo("5: la primera vez no sale la vista desde la torre («%s»)" % z.aviso.text)
	await _usar(z, "oak_farol_1", Vector2(76.5, 39.1), "Examinar")
	if P.estado("oakhaven", "farol_1") or z.aviso.text != Oak.pieza("oak_farol_1")["texto_sin"]:
		_fallo("5: sin la misión, el farol se enciende o dice «%s»" % z.aviso.text)
	await _usar(z, "oak_ronda_bajar", Vector2(76.5, 41.2), "Bajar")
	if not _cerca_de(z, Oak.pieza("oak_ronda_bajar")["lleva_a"]):
		_fallo("5: bajar de la ronda no deja al pie de la torre (%s)" % (z.jugador.position / T))
	await _hablar(z, "bastian")                     # la segunda vez: los faroles de la ronda
	if not P.estado("oakhaven", "faroles"):
		_fallo("5: Bastián no da la misión de los faroles")
	await _usar(z, "oak_torre", Vector2(73.5, 43.2), "Subir")
	await _esperar(20)
	if z.avisos.any(func(a): return a[0] == vista):
		_fallo("5: la vista desde la torre sale otra vez")
	for i in [1, 2, 3]:
		var id := "oak_farol_%d" % i
		var c: Vector2 = Oak.pieza(id)["casilla"]
		await _usar(z, id, c + Vector2(0, 0.6), "Encender")
		if not P.estado("oakhaven", "farol_%d" % i) or not ("Farol encendido (%d de 3)." % i) in z.aviso.text:
			_fallo("5: el farol %d no se enciende («%s»)" % [i, z.aviso.text])
		var e = _pieza(z, id)
		if not _luz_de_farol(e[0]):
			_fallo("5: el farol %d encendido no da luz" % i)
		z._comprobar_cerca()
		if z.pieza_cerca != null and z.pieza_cerca[1]["id"] == id:
			_fallo("5: un farol encendido se sigue pudiendo encender")
	await _usar(z, "oak_ronda_bajar", Vector2(76.5, 41.2), "Bajar")
	await _hablar(z, "bastian")
	if Oak.estado_mision("oak_faroles") != "hecha":
		_fallo("5: contárselo a Bastián no acaba la misión (%s)" % Oak.estado_mision("oak_faroles"))
	hechos.append("torre, ronda y Los faroles de la ronda")


# La grieta del callejón, en los dos sentidos.
func _grieta(z) -> void:
	z.jugador.position = Vector2(23.5, 34.6) * T
	await _esperar(2)
	z._brazalete()
	if not z.brillo_grieta:
		_fallo("5: el brazalete no brilla junto a la grieta")
	if z.velo_patio.modulate.a < 0.9:
		_fallo("5: desde el callejón se ve el Patio de las Velas")
	await _usar(z, "oak_grieta", Vector2(23.5, 34.6), "Pasar")
	if not _cerca_de(z, Oak.pieza("oak_grieta")["lleva_a"]) or not P.estado("oakhaven", "grieta"):
		_fallo("5: pasar la grieta no lleva al patio (%s)" % (z.jugador.position / T))
	await _esperar(40)
	if z.velo_patio.modulate.a > 0.1:
		_fallo("5: al pasar la grieta, el patio sigue a oscuras")
	await _usar(z, "oak_grieta", Vector2(23.5, 36.4), "Pasar")
	if not _cerca_de(z, Vector2(23.5, 34.0)):
		_fallo("5: la grieta no se pasa de vuelta (%s)" % (z.jugador.position / T))
	hechos.append("la grieta")


# 6. Un cofre una sola vez y el de los requisados.
func _cofres(z) -> void:
	var oro: int = inv.oro()
	var pociones: int = inv.cantidad("Poción")
	z.jugador.position = Vector2(43, 4.4) * T
	await _esperar(3)
	z._comprobar_cerca()
	if z.cofre_cerca == null or z.cofre_cerca[1] != "oak_cofre_raices" or z.boton_examinar.text != "Abrir cofre":
		_fallo("6: junto al cofre de las raíces no sale «Abrir cofre» («%s»)" % z.boton_examinar.text)
	z._accion()
	await _esperar(3)
	if inv.oro() != oro + 100 or inv.cantidad("Poción") != pociones + 1:
		_fallo("6: el cofre de las raíces no da 100 monedas y 1 Poción (%d → %d, %d → %d)" % [oro, inv.oro(), pociones,
			inv.cantidad("Poción")])
	if not Engine.get_meta("cofres_abiertos", {}).has("oak_cofre_raices") or not _cofre(z, "oak_cofre_raices")[2]:
		_fallo("6: el cofre de las raíces no queda abierto")
	if z.destellos.has("oak_cofre_raices"):
		_fallo("6: el cofre abierto sigue brillando")
	z._comprobar_cerca()
	if z.boton_examinar.visible and z.boton_examinar.text == "Abrir cofre":
		_fallo("6: el cofre abierto se puede volver a abrir")
	z._abrir_cofre(_cofre(z, "oak_cofre_raices"))
	if inv.oro() != oro + 100 or inv.cantidad("Poción") != pociones + 1:
		_fallo("6: el cofre da el premio dos veces")
	var req = _cofre(z, "oak_cofre_requisados")
	z.jugador.position = Vector2(47, 51.9) * T
	await _esperar(3)
	z._comprobar_cerca()
	z._accion()
	await _esperar(3)
	if req[2] or Engine.get_meta("cofres_abiertos", {}).has("oak_cofre_requisados") \
			or z.aviso.text != Oak.cofre("oak_cofre_requisados")["bloqueado"]:
		_fallo("6: con la exploración 3D y sin PV-02, los requisados se abren («%s»)" % z.aviso.text)
	P.poner_hito("pv_02")                           # Kael ya ha salido de la ciudad
	z._comprobar_cerca()
	z._accion()
	await _esperar(3)
	if not req[2] or not P.visto("nota_oak_requisados"):
		_fallo("6: tras PV-02, los requisados no se abren o no dejan su nota")
	if not await _aviso_llega(z, "Nueva nota en el Diario: «Objetos requisados»"):
		_fallo("6: no se avisa de la nota de los requisados («%s»)" % z.aviso.text)
	hechos.append("un cofre una sola vez y los requisados")


# 7. Una nota y el Diario.
func _nota(z) -> void:
	var n: Dictionary = Oak.nota("nota_oak_bando")
	z.jugador.position = (n["casilla"] + Vector2(0, 0.7)) * T
	await _esperar(3)
	z._comprobar_cerca()
	if z.nota_cerca == null or z.nota_cerca[1]["id"] != n["id"] or z.boton_examinar.text != "Examinar":
		_fallo("7: junto al bando no sale «Examinar»")
	z._accion()
	await _esperar(2)
	if z.aviso.text != n["texto"] or not P.visto(n["id"]):
		_fallo("7: el bando no se lee o no queda en el Diario («%s»)" % z.aviso.text)
	if not await _aviso_llega(z, "Nueva nota en el Diario: «%s»" % n["nombre"]):
		_fallo("7: no se avisa de la nota nueva")
	for a in P.ACTOS:
		if P.acto_completo(a):
			_fallo("7: una nota completa el acto «%s»" % a["nombre"])
	var d = load("res://diario.gd").new()
	z.ui.add_child(d)
	await _esperar(3)
	var textos: Array = []
	for c in d.cuerpo.get_children():
		if c is Label:
			textos.append(c.text.strip_edges())
	for t in ["Notas", "Bando de la plaza · Oakhaven", n["texto"], "Objetos requisados · Oakhaven"]:
		if not t in textos:
			_fallo("7: el Diario no enseña «%s»" % t)
	if "Altar de las velas · Oakhaven" in textos:
		_fallo("7: el Diario enseña una nota sin leer")
	d._cerrar()
	await _esperar(3)
	hechos.append("una nota en el Diario")


# 8. Salir al mapa y volver.
func _salir_y_volver(z, base: Array) -> Variant:
	z._salir()
	if not await _hasta(func(): return _en(MAPA), 60.0):
		_fallo("8: salir de la ciudad no lleva al mapa (%s)" % _escena())
		return null
	if _conexiones() != base:
		_fallo("8: al salir, las conexiones a Dialogic son %s (antes de entrar, %s)" % [_conexiones(), base])
	z = await _entrar_desde_el_mapa()
	if z == null:
		return null
	if _conexiones() != [base[0] + 1, base[1] + 1]:
		_fallo("8: al volver, las conexiones a Dialogic son %s (se acumulan)" % [_conexiones()])
	for id in ["oak_cofre_raices", "oak_cofre_requisados"]:
		if not _cofre(z, id)[2]:
			_fallo("8: al volver, el cofre %s está cerrado" % id)
	if z.destellos.has("oak_cofre_raices") or not z.destellos.has("oak_cofre_ronda"):
		_fallo("8: los destellos de los cofres no son los de antes")
	for n in z.npcs:
		if n[2] != 0:
			_fallo("8: al volver, %s sigue con su turno de antes" % n[1]["id"])
	if Oak.estado_mision("oak_favores") != "hecha" or Oak.estado_mision("oak_faroles") != "hecha":
		_fallo("8: al volver, las misiones no siguen hechas")
	var luces := 0
	for e in z.piezas:
		if e[1]["id"].begins_with("oak_farol_") and _luz_de_farol(e[0]):
			luces += 1
	if luces != 3:
		_fallo("8: al volver, %d faroles de la ronda dan luz (3)" % luces)
	if z.velo_patio.modulate.a > 0.1:
		_fallo("8: al volver, el Patio de las Velas sigue a oscuras")
	hechos.append("salir y volver")
	return z


# 9. Guardar y cargar.
func _guardar_y_cargar(z) -> Variant:
	var sitio := Vector2(41.2, 27.6)
	z.jugador.position = sitio * T
	await _esperar(3)
	z._guardar()
	var guardada = P.leer(ARCHIVO)
	if guardada == null or guardada.get("escena_guardada", "") != CIUDAD:
		_fallo("9: la partida no se guarda en la ciudad (%s)" % (guardada.get("escena_guardada", "") if guardada else "nada"))
		return z
	var oro: int = inv.oro()
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {}).duplicate()
	var lore: Dictionary = Engine.get_meta("lore_visto", {}).duplicate()
	var hitos: Dictionary = Engine.get_meta("hitos", {}).duplicate()
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("partida_lista")
	var escena: String = P.cargar()
	if escena != CIUDAD:
		_fallo("9: al cargar se vuelve a «%s» y no a la ciudad" % escena)
		return null
	var vieja: int = z.get_instance_id()            # (la escena de antes se libera: no se guarda en la lambda)
	change_scene_to_file(escena)                    # como la pantalla de carga
	if not await _hasta(func(): return _en(CIUDAD) and current_scene.get_instance_id() != vieja, 60.0):
		_fallo("9: al cargar no se abre la ciudad")
		return null
	await _esperar(10)
	z = current_scene
	if not _cerca_de(z, sitio, 0.2):
		_fallo("9: al cargar, Kael está en %s y no en %s" % [z.jugador.position / T, sitio])
	if inv.oro() != oro or Engine.get_meta("cofres_abiertos", {}) != abiertos or Engine.get_meta("lore_visto", {}) != lore \
			or Engine.get_meta("hitos", {}) != hitos:
		_fallo("9: lo cargado no es lo guardado (oro, cofres, notas o hitos)")
	if not _cofre(z, "oak_cofre_raices")[2]:
		_fallo("9: al cargar, el cofre abierto está cerrado")
	hechos.append("guardar y cargar")
	return z


# 10. «Lavanda para el Árbol», con Pastos Verdes 3D.
func _lavanda(z) -> Variant:
	await _hablar(z, "rosa")                        # npc_rosa
	if await _hablar(z, "rosa") != Oak.ruta_dialogo("oak_rosa_lavanda") or not P.estado("oakhaven", "lavanda"):
		_fallo("10: Rosa no pide la lavanda")
	if not Oak.lavanda_disponible():
		_fallo("10: tras pedirla, la lavanda no está disponible")
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	if not await _hasta(func(): return _escena() == REGION and current_scene.get("kael") != null, 120.0):
		_fallo("10: no se abre Pastos Verdes 3D")
		return null
	await _esperar(20)
	var r = current_scene
	if r.lavanda == null:
		_fallo("10: en Pastos Verdes no está el ramito de lavanda")
		return null
	r._colocar_kael(r.lavanda.global_position + Vector3(0.9, 0, 0.4))
	await _esperar(4)
	r._comprobar_cerca()
	if r.cerca != "lavanda" or r.boton_accion.text != "Coger la lavanda":
		_fallo("10: junto a la lavanda no sale «Coger la lavanda» (%s, «%s»)" % [r.cerca, r.boton_accion.text])
	r._accion()
	await _esperar(4)
	if not P.estado("oakhaven", "lavanda_cogida") or r.lavanda != null or r.aviso.text != Oak.LAVANDA["texto"]:
		_fallo("10: la lavanda no se coge («%s»)" % r.aviso.text)
	r._comprobar_cerca()
	if r.cerca == "lavanda":
		_fallo("10: la lavanda se puede coger dos veces")
	Engine.set_meta("pos_zona_ok", false)
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return _en(CIUDAD), 60.0):
		_fallo("10: no se vuelve a la ciudad")
		return null
	await _esperar(10)
	z = current_scene
	var pociones: int = inv.cantidad("Poción")
	await _hablar(z, "rosa")                        # lo de la misión va primero
	if Oak.estado_mision("oak_lavanda") != "hecha" or inv.cantidad("Poción") != pociones + 2:
		_fallo("10: entregar la lavanda no acaba la misión o no da 2 Pociones")
	await _hablar(z, "encina")
	if not P.estado("oakhaven", "encina_gracias"):
		_fallo("10: Doña Encina no da las gracias")
	hechos.append("Lavanda para el Árbol (con Pastos Verdes 3D)")
	return z


# ¿Da luz este farol? El provisional (la farola de zona.gd) lleva su PointLight2D; el de gráficos, encender().
func _luz_de_farol(n: Node) -> bool:
	if n.get("encendida") != null:                 # el falso del apartado 11 (y uno de gráficos que lo apunte)
		return n.get("encendida")
	if n.has_method("encender"):
		return true                                # (lo dibuja gráficos: aquí no se puede ver)
	for h in n.get_children():
		if h is PointLight2D and h.visible:
			return true
	return false


# 11. El camino del arte de gráficos, con un módulo falso que apunta lo que se le pide.
func _con_arte(z) -> void:
	var sin_arte: PackedByteArray = z.muros.duplicate()
	var farolas_sin: int = z.farolas.size()
	Engine.set_meta("oakhaven_arte_prueba", "res://pruebas/oakhaven_arte_falso.gd")
	Engine.set_meta("pos_zona_ok", false)
	var vieja: int = z.get_instance_id()
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return _en(CIUDAD) and current_scene.get_instance_id() != vieja, 60.0):
		_fallo("11: con el arte falso no se abre la ciudad")
		return
	await _esperar(10)
	z = current_scene
	var Falso = load("res://pruebas/oakhaven_arte_falso.gd")
	if z.arte != Falso:
		_fallo("11: la ciudad no usa el módulo de arte de la prueba")
		return
	# lo que se pisa es lo mismo; bajo los edificios con dibujo (y las casas), muro invisible
	var cambia := 0
	for i in sin_arte.size():
		if (sin_arte[i] == 0) != (z.muros[i] == 0):
			cambia += 1
	if cambia > 0:
		_fallo("11: con arte se pisan %d casillas distintas" % cambia)
	for id in ["taberna", "crematorio"]:
		var r: Rect2 = Oak.LUGARES.filter(func(l): return l["id"] == id)[0]["rect"]
		for y in range(int(r.position.y), int(r.end.y)):
			for x in range(int(r.position.x), int(r.end.x)):
				if z.muros[y * z.ANCHO + x] != 3:
					_fallo("11: bajo el dibujo de %s no hay muro invisible (%d, %d)" % [id, x, y])
					break
	# cada dibujo, en mundo_y y en su sitio
	var por_id := {}
	for n in z.mundo_y.get_children():
		if n.get("id") != null and n.get("rect") != null:
			if not por_id.has(n.id):
				por_id[n.id] = []
			por_id[n.id].append(n)
	for id in ["taberna", "crematorio", "ronda", "arbol", "oak_farol_1", "oak_torre", "nota_oak_cuervo", "oak_sello"]:
		if not por_id.has(id):
			_fallo("11: no está el dibujo de «%s»" % id)
	if por_id.has("taberna") and por_id["taberna"][0].position != Vector2(11, 19) * T:
		_fallo("11: el dibujo de la taberna no está en la esquina de su huella (%s)" % (por_id["taberna"][0].position / T))
	if por_id.get("farol", []).size() != farolas_sin:
		_fallo("11: hay %d farolas de gráficos y %d sitios de farola" % [por_id.get("farol", []).size(), farolas_sin])
	var casas: Array = por_id.get("casa_4x4", [])
	if casas.is_empty():
		_fallo("11: no se pide ninguna casa de 4 × 4 al arte")
	for c in casas:
		for y in range(c.rect.position.y, c.rect.end.y):
			for x in range(c.rect.position.x, c.rect.end.x):
				if z.muros[y * z.ANCHO + x] != 3:
					_fallo("11: bajo una casa con dibujo no hay muro invisible (%d, %d)" % [x, y])
	# lo que tiene dibujo no lleva el provisional; los estados y el ambiente
	if z.arbol == null or z.arbol.get("id") != "arbol" or z.arbol_provisional:
		_fallo("11: el Árbol no es el dibujo de gráficos")
	if _pieza(z, "oak_farol_1")[0].get("id") != "oak_farol_1" or not _pieza(z, "oak_farol_1")[0].encendida:
		_fallo("11: el farol 1 no es el dibujo de gráficos o no se le enciende (ya estaba encendido)")
	for nt in z.notas:
		if nt[1]["id"] == "nota_oak_cuervo" and nt[0].get("id") != "nota_oak_cuervo":
			_fallo("11: el letrero del cuervo sigue siendo el provisional")
	var ronda = por_id.get("ronda", [null])[0]
	if ronda != null:
		if not ronda.estados.get("farol_1", false) or ronda.estados.get("oak_cofre_ronda", null) != true:
			_fallo("11: la ronda no recibe sus estados (%s)" % [ronda.estados])
		if ronda.estados.get("oak_cofre_raices", null) != false:
			_fallo("11: la ronda no sabe que el cofre de las raíces está abierto (%s)" % [ronda.estados])
	if z.destellos.has("oak_cofre_ronda"):
		_fallo("11: el cofre de la ronda lleva el destello provisional y el de gráficos")
	var ambiente: CanvasModulate = null
	for n in z.get_children():
		if n is CanvasModulate:
			ambiente = n
	if ambiente == null or ambiente.color != Falso.AMBIENTE:
		_fallo("11: la luz ambiente no es la del arte (%s)" % (ambiente.color if ambiente else "nada"))
	Engine.remove_meta("oakhaven_arte_prueba")
	hechos.append("el camino del arte (falso)")
