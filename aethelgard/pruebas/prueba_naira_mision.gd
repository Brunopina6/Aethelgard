extends SceneTree
# La misión de incorporación de Naira, «La única noche que cabe en un día» (V12, 12/11; PROTOTIPO APAGADO:
# zonas3d/mar_cristal/naira_mision.gd y observatorio.gd, interruptor «naira_v12» de grupo.gd, encendido solo aquí).
# Sin ventana y con datos aislados, sobre una partida con «La caravana perdida» terminada (mc_fin):
#   A. SIN el interruptor: nada nuevo (ni módulo, ni observatorio, ni explanada, ni plomadas, ni piezas, ni personaje de
#      Dialogic); Oren e Ismena dicen lo de siempre; la partida volcada no trae nada de Naira.
#   B. CON el interruptor, la misión entera con los hitos en orden: el rumor (Oren), la torre (andando desde las ruinas),
#      el primer encuentro, las tres plomadas con el buscador (una en la arena que tiembla), GUARDAR Y CARGAR a mitad, la
#      medición, el eclipse (luz, cielo, cámara, nadie se mueve), el combate fijo (Kael, Lya y Naira; Garon en la
#      reserva) PERDIDO (vuelve el grupo de antes, sigue la totalidad) y GANADO sin golpes a Naira (medición perfecta y
#      Lente ahumada), la luz que vuelve (la de antes, exacta), el Almanaque, la unión (Naira en la reserva y la
#      Formación) y una recarga final.
#   Los diálogos se cortan: su efecto se aplica igual (como en prueba_mar_cristal). Los combates los lleva la prueba.
#   C. Los textos: cada intervención de los nr_*.dtl cabe (≤ 70 caracteres) y quien habla existe en ese momento.
# Con «fotos=<carpeta>» y ventana, capturas de los momentos clave; con «perfil=bajo|medio», en ese perfil (alto si no).
# Uso: --path aethelgard --script res://pruebas/prueba_naira_mision.gd --fixed-fps 30 -- 3d mardecristal sin_prologo

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const COMBATE := "res://combate.tscn"
const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const O := preload("res://zonas3d/mar_cristal/observatorio.gd")
const M := preload("res://zonas3d/mar_cristal/naira_mision.gd")
const HITOS_MC := ["mc_inicio", "mc_caravana", "mc_sello", "mc_tormenta", "mc_ruinas", "mc_llave", "mc_superviviente", "mc_fin"]
const DIALOGOS := ["nr_campamento_rumor", "nr_torre_puerta", "nr_plomadas_espera", "nr_medicion", "nr_eclipse_antes",
	"nr_eclipse_reintento", "nr_eclipse_despues", "nr_catalogo", "nr_union"]

var P
var G
var B
var Inv
var fallos := 0
var frames := 0
var fase := ""
var f_fase := 0
var v
var c
var volcado: Dictionary = {}
var fondo0: Color
var ambiente0: Color
var sol0 := 0.0
var orden: Array = []                  # los hitos nr_* en el orden en que aparecen
var tramos: Array = []
var i_tramo := 0
var i_plomada := 0
var fotos := ""
var n_foto := 0
var foto_cielo := false
var perfil := "alto"                   # «perfil=bajo|medio|alto» (el bajo tiene su luz propia: LUZ_SIN_SOMBRAS)
var t_ms := 0
var t_inicio := 0                     # (18/11) reloj del tope global


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(cond: bool, t: String) -> void:
	if not cond:
		_mal(t)


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	B = load("res://buscador.gd")
	Inv = load("res://inventario.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	_textos()
	_partida()
	Engine.set_meta("naira_v12", false)
	_cargar("A")


# Una partida con «La caravana perdida» terminada (el buscador ya es de Kael) y el grupo de siempre.
func _partida() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for k in ["combate_fijo", "grupo_combate", "nr_medicion_eclipse", "nr_medidor"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	for h in HITOS_MC:
		P.poner_hito(h)
	Engine.set_meta("buscador", {"nivel": 2, "tiene": true})
	G.datos()


func _cargar(siguiente: String) -> void:
	Engine.set_meta("incienso", 100000)
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	v = null
	_fase("cargar_" + siguiente)


func _fase(n: String) -> void:
	fase = n
	f_fase = frames
	print("· ", n)


func _en(f: int) -> bool:
	return frames - f_fase >= f


func _poner(x: float, z: float) -> void:
	v._colocar_kael(Vector3(x, 0, z))
	v._ultima = v.kael.global_position


func _cortar() -> bool:
	var dg = root.get_node_or_null("Dialogic")
	if dg != null and dg.current_timeline != null:
		dg.end_timeline(true)
		return true
	return false


func _hito(h: String) -> bool:
	return P.hito(h)


func _apuntar_orden() -> void:
	for h in P.HITOS_NAIRA:
		if _hito(h) and not h in orden:
			orden.append(h)


func _usar(id: String) -> void:
	v._bloqueo = 0.0
	v.cerca = id
	v._accion()


func _foto(nombre: String) -> void:
	if fotos == "" or DisplayServer.get_name() == "headless":
		return
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		n_foto += 1
		img.save_png(fotos.path_join("%02d_%s.png" % [n_foto, nombre]))
		print("  foto ", nombre)


func _process(_dt: float) -> bool:
	frames += 1
	_apuntar_orden()
	# (18/11) tope por RELOJ (300 s; normal, unos 10 s). Era de 27000 fotogramas, y mientras Recursos.cambiar_escena carga
	# en su hilo (tiempo real) los fotogramas sin ventana vuelan: con la carga retrasada 5 s se agotaba en la fase
	# «aclara» (docs/v12/PRUEBAS_CARRERAS_18_11.md).
	if t_inicio == 0:
		t_inicio = Time.get_ticks_msec()
	if Time.get_ticks_msec() - t_inicio > 300000:
		_mal("se pasa de tiempo en la fase «%s»" % fase)
		return _fin()
	match fase:
		# ---------------------------------------------------------------- A. sin el interruptor
		"cargar_A":
			if _region_lista():
				_ok(v.naira == null and v.get_node_or_null("Observatorio") == null, "A: sin interruptor hay misión u observatorio")
				_ok(T.llanos_extra.is_empty(), "A: sin interruptor se aplana la explanada")
				_ok(B.hallazgos(v.REGION_BUSCADOR, v.SEMILLA).size() == 22, "A: sin interruptor cambian los hallazgos (%d)" % B.hallazgos(v.REGION_BUSCADOR, v.SEMILLA).size())
				_ok(v._piezas_al_alcance().all(func(p): return not str(p[0]).begins_with("nr_")), "A: sin interruptor hay piezas nr_*")
				var dg = root.get_node_or_null("Dialogic")
				if dg != null:
					var util = load("res://addons/dialogic/Core/DialogicResourceUtil.gd")
					print("  personajes de Dialogic con «naira»: ", util.get_directory("dch").has("naira"))
				_poner(T.CARTOGRAFA.x - 1.6, T.CARTOGRAFA.y + 1.6)
				_usar("oren")
				_fase("A2")
		"A2":
			if _en(20):
				_ok(v.dialogo_actual == "" and not _hito("nr_rumor"), "A: sin interruptor Oren cuenta el rumor («%s»)" % v.dialogo_actual)
				_ok(v.aviso.text.begins_with("Oren:"), "A: sin interruptor Oren no dice lo de siempre («%s»)" % v.aviso.text)
				var d: Dictionary = P.volcar(REGION)
				var texto := JSON.stringify(d)
				_ok(not texto.contains("nr_") and not texto.contains("Naira") and not texto.contains("naira_mision"),
					"A: sin interruptor la partida trae algo de Naira")
				_ok(G.activos() == ["Kael", "Lya", "Garon"] and G.reserva().is_empty(), "A: sin interruptor cambia el grupo")
				print("  A: sin interruptor, todo como siempre")
				_partida()
				Engine.set_meta("naira_v12", true)
				_cargar("B")
		# ---------------------------------------------------------------- B. con el interruptor
		"cargar_B":
			if _region_lista():
				_ok(v.naira != null and v.get_node_or_null("Observatorio") != null, "B: con interruptor no hay observatorio")
				_ok(v.naira.obs.naira != null, "B: Naira no está en la puerta (modelo)")
				_ok(absf(T.altura(O.TORRE.x, O.TORRE.y + 3.0)) < 0.05, "B: la explanada no está aplanada")
				_ok(v._prohibido(Vector3(O.TORRE.x, 0, O.TORRE.y)), "B: la torre se puede atravesar")
				_ok(B.hallazgos(v.REGION_BUSCADOR, v.SEMILLA).size() == 25, "B: no están las tres plomadas en el buscador")
				_ok(B.pendientes(v.REGION_BUSCADOR, v.SEMILLA).all(func(h): return not str(h["id"]).begins_with("nr_")),
					"B: las plomadas pitan antes de hablar con Naira")
				var env: Environment = (v.get_node("Ambiente") as WorldEnvironment).environment
				fondo0 = env.background_color
				ambiente0 = env.ambient_light_color
				sol0 = (v.get_node("Sol") as DirectionalLight3D).light_energy
				_poner(T.CARTOGRAFA.x - 1.6, T.CARTOGRAFA.y + 1.6)
				_usar("oren")
				_fase("rumor")
		"rumor":
			if _en(90):
				_ok(v.dialogo_actual == "nr_campamento_rumor", "B: Oren no cuenta el rumor («%s»)" % v.dialogo_actual)
				_foto("rumor")
				_cortar()
				_fase("rumor2")
		"rumor2":
			if _en(30):
				_ok(_hito("nr_rumor") and not _hito("nr_observatorio"), "B: el rumor no da nr_rumor")
				_poner(47.0, 24.5)                             # de las ruinas a la torre, andando (por el sur de la columna b)
				tramos = [Vector3(54.0, 0, 24.5), Vector3(62.0, 0, 18.0), Vector3(O.PUERTA.x, 0, O.PUERTA.y + 1.6)]
				i_tramo = 0
				v.destino = v._ajustar_destino(tramos[0])
				_fase("andar")
		"andar":
			if v.destino == null or _en(30 * 15):
				var meta: Vector3 = tramos[i_tramo]
				var d: float = Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length()
				_ok(d < 1.2, "B: no se llega andando a %s (queda a %.1f m, Kael en %s)" % [meta, d, v.kael.global_position])
				i_tramo += 1
				if i_tramo < tramos.size() and d < 1.2:
					v.destino = v._ajustar_destino(tramos[i_tramo])
					_fase("andar")
				else:
					_poner(O.PUERTA.x, O.PUERTA.y + 1.6)
					_fase("torre")
		"torre":
			if _en(20):
				v._comprobar_cerca()
				_ok(v.cerca == "nr_naira" and v.boton_accion.text == "Hablar con la astrónoma", "B: en la puerta no se habla con la astrónoma (%s, «%s»)" % [v.cerca, v.boton_accion.text])
				_foto("observatorio")
				_usar("nr_naira")
				_fase("torre2")
		"torre2":
			if _en(90):
				_ok(v.dialogo_actual == "nr_torre_puerta", "B: en la torre no empieza el primer encuentro")
				_foto("primer_encuentro")
				_cortar()
				_fase("torre3")
		"torre3":
			if _en(30):
				_ok(_hito("nr_observatorio"), "B: el primer encuentro no da nr_observatorio")
				_ok(B.pendientes(v.REGION_BUSCADOR, v.SEMILLA).filter(func(h): return str(h["id"]).begins_with("nr_plomada")).size() == 3,
					"B: tras el encuentro no pitan las tres plomadas")
				_usar("nr_naira")
				_fase("espera")
		"espera":
			if _en(20):
				_ok(v.dialogo_actual == "nr_plomadas_espera", "B: hablar con Naira sin plomadas no da su espera")
				_cortar()
				_fase("espera2")
		"espera2":
			if _en(30):
				_usar("nr_naira")
				_fase("espera3")
		"espera3":
			if _en(10):
				_ok(v.dialogo_actual == "" and v.aviso.text.begins_with("Naira: «Faltan"), "B: la segunda vez no dice qué falta («%s»)" % v.aviso.text)
				i_plomada = 0
				_fase("plomada")
		"plomada":                                             # junto a la torre, el cañón y la arena que tiembla
			if _en(10):
				var u: Dictionary = B.REGIONES[v.REGION_BUSCADOR]["unicos"].filter(func(x): return x["id"] == M.PLOMADAS[i_plomada])[0]
				v.gusano.activo = false                           # Bramavidrio, quieto mientras se cava (se prueba en prueba_mar_cristal)
				_poner(u["pos"].x, u["pos"].y + 0.3)
				v.hud.activo = true
				v.hud.refrescar()
				_fase("plomada2")
		"plomada2":
			if _en(30):
				_ok(v.hud.puede_excavar(), "B: encima de %s no se puede excavar" % M.PLOMADAS[i_plomada])
				v.hud.excavar()
				_fase("plomada3")
		"plomada3":
			if _en(60):
				_ok(_hito(M.PLOMADAS[i_plomada]), "B: no sale %s" % M.PLOMADAS[i_plomada])
				_ok(Inv.cantidad(M.OBJETO_PLOMADA) == i_plomada + 1, "B: plomadas en el inventario: %d" % Inv.cantidad(M.OBJETO_PLOMADA))
				i_plomada += 1
				v.gusano.activo = true
				_poner(O.PUERTA.x, O.PUERTA.y + 1.6)
				if i_plomada == 2:
					_ok(not _hito("nr_plomadas"), "B: con dos plomadas ya está nr_plomadas")
					volcado = P.volcar(REGION)                    # guardar y cargar a mitad
					_fase("recargar")
				elif i_plomada < 3:
					_fase("plomada")
				else:
					_fase("medicion")
		"recargar":
			for k in P.CLAVES:
				if Engine.has_meta(k):
					Engine.remove_meta(k)
			P.restaurar(volcado)
			_cargar("B2")
		"cargar_B2":
			if _region_lista():
				_ok(_hito("nr_observatorio") and _hito("nr_plomada_1") and _hito("nr_plomada_2") and not _hito("nr_plomada_3"),
					"C: al cargar a mitad se pierden hitos")
				var pend: Array = B.pendientes(v.REGION_BUSCADOR, v.SEMILLA).map(func(h): return h["id"])
				_ok(not "nr_plomada_1" in pend and not "nr_plomada_2" in pend and "nr_plomada_3" in pend,
					"C: al cargar a mitad, las plomadas encontradas vuelven a pitar o la que falta no")
				_ok(v.naira.obs.naira != null and Inv.cantidad(M.OBJETO_PLOMADA) == 2, "C: al cargar a mitad falta Naira o las plomadas")
				_fase("plomada")
		"medicion":
			if _en(10):
				_ok(_hito("nr_plomadas"), "B: con las tres no está nr_plomadas")
				v._comprobar_cerca()
				_ok(v.boton_accion.text == "Darle las plomadas", "B: el botón no dice «Darle las plomadas» («%s»)" % v.boton_accion.text)
				_usar("nr_naira")
				_fase("medicion2")
		"medicion2":
			if _en(20):
				_ok(v.dialogo_actual == "nr_medicion", "B: no empieza la medición")
				_cortar()
				_fase("oscurece")
		"oscurece":
			if _en(30 * 4):
				_ok(_hito("nr_medicion") and Inv.cantidad(M.OBJETO_PLOMADA) == 0 and v.naira.obs.plomadas.size() == 4,
					"B: la medición no se queda las plomadas")
				_ok(v.naira.estado == "oscurece" and v.ocupado() and v.naira.camara != null, "B: no empieza el momento del eclipse")
				_ok(v.naira.eclipse > 0.2 and v.naira.eclipse < 0.8, "B: la luz no baja poco a poco (%.2f)" % v.naira.eclipse)
				_foto("oscurece")
				_fase("totalidad")
		"totalidad":
			if v.naira.estado == "totalidad" and v.dialogo_actual == "" and not foto_cielo:
				foto_cielo = true                              # el momento, sin el diálogo todavía
				_foto("cielo_eclipse")
			if v.dialogo_actual == "nr_eclipse_antes":
				_fase("totalidad2")
			elif _en(30 * 16):
				_mal("B: la totalidad no llega a nr_eclipse_antes (estado %s, eclipse %.2f)" % [v.naira.estado, v.naira.eclipse])
				return _fin()
		"totalidad2":
			if _en(90):
				var env: Environment = (v.get_node("Ambiente") as WorldEnvironment).environment
				_ok(v.naira.eclipse >= 1.0 and env.background_color.get_luminance() < fondo0.get_luminance() * 0.4,
					"B: en la totalidad el cielo no se oscurece")
				_ok((v.get_node("Sol") as DirectionalLight3D).light_energy < sol0 * 0.3, "B: en la totalidad el sol no baja")
				_ok(v.naira.obs.cielo.visible and v.naira.mirar_arriba > 10.0, "B: en la totalidad la cámara no mira al cielo (%.1f°)" % v.naira.mirar_arriba)
				_foto("totalidad")
				_cortar()
				t_ms = Time.get_ticks_msec()
				_fase("combate1")
		"combate1", "combate2":
			if _combate_listo():
				var nombres: Array = c.heroes.map(func(h): return h["nombre"])
				_ok(nombres.has("Naira") and nombres.has("Kael") and nombres.has("Lya") and not nombres.has("Garon"),
					"B: el combate del eclipse no es de Kael, Lya y Naira (%s)" % [nombres])
				_ok(c.combate_fijo == M.COMBATE and G.reserva() == ["Garon"], "B: combate fijo «%s», reserva %s" % [c.combate_fijo, G.reserva()])
				_ok(c._orden_huir()["apagado"], "B: del eclipse se puede huir")
				if fase == "combate1":
					_foto("combate")
				_fase(fase + "_preparar")
			elif Time.get_ticks_msec() - t_ms > 40000:
				_mal("B: el combate del eclipse no carga")
				return _fin()
		"combate1_preparar", "combate2_preparar":           # Naira prepara su Eclipse (lo que mira el Medidor)
			var n: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Naira")[0]
			if _en(3) and not _en(4):
				n["conjuro"] = {"familia": "naira_eclipse", "nivel": 1, "objs": [], "recibido": 0}
			if fase == "combate1_preparar" and _en(8) and not _en(9):
				n["hp"] = maxi(1, int(n["hp"]) - 5)               # un golpe mientras prepara
			if _en(12):
				n.erase("conjuro")
				var med: Dictionary = Engine.get_meta("nr_medicion_eclipse", {})
				if fase == "combate1_preparar":
					_ok(int(med.get("golpes", 0)) == 1 and med.get("preparo", false), "B: el medidor no ve el golpe (%s)" % med)
					for h in c.heroes:                            # pierden
						h["hp"] = 0
				else:
					_ok(int(med.get("golpes", 1)) == 0 and med.get("preparo", false), "B: el medidor ve golpes (%s)" % med)
					for e in c.enemigos:                          # ganan
						e["hp"] = 0
				c._comprobar_fin()
				t_ms = Time.get_ticks_msec()
				_fase("vuelta_perdida" if fase == "combate1_preparar" else "vuelta_ganada")
		"vuelta_perdida":
			if _region_lista():
				_ok(not _hito("nr_eclipse") and v.naira.estado == "totalidad" and v.naira.eclipse >= 1.0,
					"B: al perder no sigue la totalidad")
				_ok(G.activos() == ["Kael", "Lya", "Garon"] and not "Naira" in G.en_el_grupo() and not Engine.has_meta("grupo_miembros"),
					"B: al perder no vuelve el grupo de antes (%s / %s)" % [G.activos(), G.en_el_grupo()])
				_ok(M._guardado().is_empty(), "B: al perder queda la formación de antes guardada")
				_ok(not G.disponible("Naira") or G.datos().has("Naira"), "B: Naira sin datos tras luchar")
				_ok(not _hito("nr_union") and not P.hito("nr_eclipse_perfecto"), "B: al perder hay hitos de más")
				_poner(O.PUERTA.x, O.PUERTA.y + 1.6)
				_usar("nr_naira")
				_fase("reintento")
			elif Time.get_ticks_msec() - t_ms > 40000:
				_mal("B: tras perder no se vuelve a la región")
				return _fin()
		"reintento":
			if _en(20):
				_ok(v.dialogo_actual == "nr_eclipse_reintento", "B: tras perder, hablar con Naira no da el reintento")
				_cortar()
				t_ms = Time.get_ticks_msec()
				_fase("combate2")
		"vuelta_ganada":
			if _region_lista():
				_ok(_hito("nr_eclipse") and _hito("nr_eclipse_perfecto") and Inv.cantidad(M.LENTE) == 1,
					"B: al ganar sin golpes no hay nr_eclipse, nr_eclipse_perfecto o la Lente")
				_ok(P.ganado(M.COMBATE) and G.activos() == ["Kael", "Lya", "Garon"] and not "Naira" in G.en_el_grupo(),
					"B: al ganar no vuelve el grupo de antes")
				_fase("despues")
			elif Time.get_ticks_msec() - t_ms > 40000:
				_mal("B: tras ganar no se vuelve a la región")
				return _fin()
		"despues":
			if v.dialogo_actual == "nr_eclipse_despues":
				_fase("despues2")
			elif _en(30 * 5):
				_mal("B: tras ganar no empieza nr_eclipse_despues")
				_fase("aclara")
		"despues2":
			if _en(90):
				_foto("despues")
				_cortar()
				_fase("aclara_mitad")
		"aclara_mitad":
			if _en(30 * 3):
				_ok(v.naira.estado == "aclara" and v.naira.eclipse > 0.0 and v.naira.eclipse < 1.0, "B: la luz no vuelve poco a poco")
				_foto("aclara")
				_fase("aclara")
		"aclara":
			if _en(30 * 8):
				var env: Environment = (v.get_node("Ambiente") as WorldEnvironment).environment
				_ok(v.naira.estado == "" and v.naira.eclipse == 0.0 and v.naira.camara == null and not v.naira.obs.cielo.visible,
					"B: la luz no vuelve del todo (%s, %.2f)" % [v.naira.estado, v.naira.eclipse])
				_ok(env.background_color.is_equal_approx(fondo0) and env.ambient_light_color.is_equal_approx(ambiente0)
					and is_equal_approx((v.get_node("Sol") as DirectionalLight3D).light_energy, sol0),
					"B: tras el eclipse la luz no es la de antes")
				_foto("luz_vuelve")
				_poner(O.ATRIL.x - 0.4, O.ATRIL.y + 1.4)
				v._comprobar_cerca()
				_ok(v.cerca == "nr_almanaque", "B: junto al atril no se puede mirar el Almanaque (%s)" % v.cerca)
				_usar("nr_almanaque")
				_fase("catalogo")
		"catalogo":
			if _en(90):
				_ok(v.dialogo_actual == "nr_catalogo", "B: el Almanaque no abre nr_catalogo")
				_foto("catalogo")
				_cortar()
				_fase("catalogo2")
		"catalogo2":
			if _en(30):
				_ok(_hito("nr_catalogo") and not _hito("nr_union"), "B: el Almanaque no da nr_catalogo")
				_poner(O.PUERTA.x, O.PUERTA.y + 1.6)
				_usar("nr_naira")
				_fase("union")
		"union":
			if _en(90):
				_ok(v.dialogo_actual == "nr_union", "B: hablar con Naira no da la unión")
				_foto("union")
				_cortar()
				_fase("union2")
		"union2":
			if _en(30):
				_ok(_hito("nr_union") and "Naira" in G.en_el_grupo() and G.reserva() == ["Naira"], "B: Naira no se une a la reserva (%s)" % [G.reserva()])
				_ok(G.hay_formacion(), "B: tras la unión no aparece la Formación")
				_ok(Inv.cantidad(M.ALMANAQUE) == 1, "B: no se recibe el Almanaque")
				_ok(v.naira.obs.naira == null, "B: Naira sigue en la puerta tras unirse")
				_foto("unida")
				_comprobar_orden()
				volcado = P.volcar(REGION)
				for k in P.CLAVES:
					if Engine.has_meta(k):
						Engine.remove_meta(k)
				P.restaurar(volcado)
				_cargar("final")
		"cargar_final":
			if _region_lista():
				_ok(G.reserva() == ["Naira"] and G.activos() == ["Kael", "Lya", "Garon"], "C: al recargar cambia el grupo")
				_ok(v.naira.obs.naira == null and v._piezas_al_alcance().all(func(p): return p[0] != "nr_naira" and p[0] != "nr_almanaque"),
					"C: al recargar vuelve Naira a la puerta")
				_ok(v.naira.eclipse == 0.0 and not v.naira.obs.cielo.visible, "C: al recargar hay eclipse")
				return _fin()
	return false


func _region_lista() -> bool:
	if current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null:
		if v != current_scene:
			v = current_scene
			f_fase = frames
		return _en(20)
	return false


func _combate_listo() -> bool:
	if current_scene != null and current_scene.scene_file_path == COMBATE:
		if c != current_scene:
			c = current_scene
			f_fase = frames
		return _en(60)
	return false


func _comprobar_orden() -> void:
	var esperado: Array = ["nr_rumor", "nr_observatorio", "nr_plomada_1", "nr_plomada_2", "nr_plomada_3", "nr_plomadas",
		"nr_medicion", "nr_eclipse", "nr_eclipse_perfecto", "nr_catalogo", "nr_union"]
	_ok(orden == esperado, "B: los hitos no van en orden: %s" % [orden])
	print("  orden de los hitos: ", orden)


# C. Los textos de los diálogos: ≤ 70 caracteres por intervención y nadie que no esté.
func _textos() -> void:
	var presentes := ["kael", "lya", "garon", "naira", "oren", "ismena"]
	for d in DIALOGOS:
		var ruta := "res://dialogos/mar_cristal/%s.dtl" % d
		var f := FileAccess.open(ruta, FileAccess.READ)
		if f == null:
			_mal("C: falta %s" % ruta)
			continue
		var lineas := 0
		for l in f.get_as_text().split("\n"):
			var i := l.find(": ")
			if l.begins_with("join") or l.begins_with("leave") or l.begins_with("update") or l.begins_with("[") or i < 0:
				continue
			var quien := l.substr(0, i)
			var texto := l.substr(i + 2)
			lineas += 1
			_ok(quien in presentes, "C: %s: habla «%s»" % [d, quien])
			_ok(texto.length() <= 70, "C: %s: «%s» mide %d" % [d, texto, texto.length()])
			_ok(not (quien in ["oren", "ismena"]) or d == "nr_campamento_rumor", "C: %s: %s fuera del campamento" % [d, quien])
			for prohibida in ["recuerd", "guarda", "corazon", "corazón", "anillo", "Érebo", "Erebo", "Morgath", "Rebelum"]:
				_ok(not texto.contains(prohibida), "C: %s: «%s» toca algo reservado (%s)" % [d, texto, prohibida])
		_ok(lineas > 0, "C: %s sin intervenciones" % d)


func _fin() -> bool:
	Engine.remove_meta("calidad_proto")
	Engine.remove_meta("naira_v12")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
