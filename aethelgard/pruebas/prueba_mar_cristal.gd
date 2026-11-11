extends SceneTree
# El Mar de Cristal (V12; zonas3d/mar_cristal_3d.gd y zonas3d/mar_cristal/*). Sin ventana y con datos aislados:
#   A. Carga en los perfiles alto y bajo: con las piezas de gráficos (modelos/desierto), la cartógrafa, sin buscador al
#      empezar y sin errores; Kael en la entrada y sobre la arena.
#   B. «La caravana perdida» de principio a fin (los diálogos se cortan: su efecto se aplica igual): Ismena presta el
#      buscador; los restos; el sello con el buscador (y no antes de examinar los restos); la tormenta al ir al norte (el
#      buscador no oye y no se excava; niebla espesa); el cobijo la hace amainar y destapa las ruinas; la llave; la
#      trampilla (mural y Oren); la recompensa una sola vez (150 monedas, buscador de nivel 2 y la Aguja de Resonancia).
#   C. Recarga: al volver a entrar con la partida volcada, las ruinas siguen destapadas, Oren está en el campamento,
#      el buscador sigue siendo de Kael y lo único no vuelve a salir.
#   D. Andar: de la entrada al campamento y a los restos sin atascarse; el estanque y las rocas no se pisan.
#   E. Bramavidrio: en la arena que tiembla avisa (surco); si Kael sale, se va; si se queda, emerge y pide su combate
#      fijo (grupo 13, «mc_bramavidrio»).
# Uso: --headless --path aethelgard --script res://pruebas/prueba_mar_cristal.gd --fixed-fps 30 -- 3d mardecristal sin_prologo

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const PERFILES := ["bajo", "alto"]           # el bajo solo carga y anda; el alto, todo (y acaba en el combate)

var P
var B
var Inv
var fallos := 0
var frames := 0
var fase := ""
var f_fase := 0
var ip := 0
var v
var volcado: Dictionary = {}
var oro0 := 0
var datos_t := {}
var tramos: Array = []
var i_tramo := 0
var t_combate := 0                     # ms: el combate carga en un hilo, a su ritmo (no al de --fixed-fps)


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(c: bool, t: String) -> void:
	if not c:
		_mal(t)


func _initialize() -> void:
	P = load("res://progreso.gd")
	B = load("res://buscador.gd")
	Inv = load("res://inventario.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	_cargar()


func _cargar() -> void:
	Engine.set_meta("incienso", 100000)                     # sin encuentros al azar: el paseo no depende de la suerte
	Engine.set_meta("calidad_proto", PERFILES[ip])
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	v = null
	_fase("cargar")


func _fase(n: String) -> void:
	fase = n
	f_fase = frames
	print("· ", n)


func _en(f: int) -> bool:
	return frames - f_fase >= f


func _poner(x: float, z: float) -> void:
	v._colocar_kael(Vector3(x, 0, z))
	v._ultima = v.kael.global_position


# Corta el diálogo abierto (si hay): Dialogic avisa del final y la misión aplica su efecto.
func _cortar() -> bool:
	var dg = root.get_node_or_null("Dialogic")
	if dg != null and dg.current_timeline != null:
		dg.end_timeline(true)
		return true
	return false


func _hito(h: String) -> bool:
	return P.hito(h)


func _process(_dt: float) -> bool:
	frames += 1
	if frames > 30 * 400:
		_mal("se pasa de tiempo en la fase «%s»" % fase)
		return _fin()
	match fase:
		"cargar":
			if current_scene != null and current_scene.scene_file_path == REGION and _en(20):
				v = current_scene
				_comprobar_carga()
				if PERFILES[ip] == "alto":
					_fase("hablar")
				else:
					_fase("andar")
		# ---------------------------------------------------------------- B. la misión (solo en el perfil alto)
		"hablar":
			_poner(T.CARTOGRAFA.x, T.CARTOGRAFA.y + 1.4)
			v._bloqueo = 0.0
			v.mision.accion(v, "cartografa")
			_fase("hablar2")
		"hablar2":
			if _en(45):
				var dg = root.get_node_or_null("Dialogic")
				print("  diálogo: actual «%s», timeline %s" % [v.dialogo_actual, dg.current_timeline if dg != null else "sin Dialogic"])
				print("  cortado: ", _cortar())
				_fase("hablar3")
		"hablar3":
			if _en(45):
				_ok(_hito("mc_inicio") and B.tiene() and v.hud.boton.visible, "B: Ismena no presta el buscador (hito %s, tiene %s, botón %s, diálogo «%s»)" % [_hito("mc_inicio"), B.tiene(), v.hud.boton.visible, v.dialogo_actual])
				_ok(B.pendientes(v.REGION_BUSCADOR, v.SEMILLA).all(func(h): return h["id"] != "sello_caravana"),
					"B: el sello pita antes de examinar los restos")
				_poner(T.CARAVANA.x, T.CARAVANA.y + 2.0)
				v.mision.accion(v, "restos")
				_fase("restos")
		"restos":
			if _en(45):
				_cortar()
				_fase("restos2")
		"restos2":
			if _en(45):
				_ok(_hito("mc_caravana"), "B: examinar los restos no da mc_caravana")
				_poner(55.5, 57.4)
				v.hud.activo = true
				v.hud.refrescar()
				_fase("sello")
		"sello":
			if _en(45):
				_ok(v.hud.puede_excavar(), "B: encima del sello no se puede excavar")
				v.hud.excavar()
				_fase("sello2")
		"sello2":
			if _en(50):
				_ok(_hito("mc_sello") and Inv.cantidad("Sello de la caravana") == 1, "B: no sale el sello (o sale dos veces)")
				_poner(50.0, 50.0)                               # al norte de los restos: la tormenta
				_fase("tormenta")
		"tormenta":
			if _en(45):
				_ok(_hito("mc_tormenta") and v.clima.en_tormenta() and v.clima.narrativa, "B: al ir al norte no se levanta la tormenta")
				_cortar()
				_fase("tormenta2")
		"tormenta2":
			if _en(30 * 6):                                      # 6 s: ya es fuerte
				_ok(v.clima.tormenta_fuerte(), "B: la tormenta no llega a fuerte (fuerza %.2f)" % v.clima.fuerza)
				var env: Environment = (v.get_node("Ambiente") as WorldEnvironment).environment
				_ok(env.fog_density > 0.05, "B: con tormenta la niebla no se espesa (%.3f)" % env.fog_density)
				_ok(not v.hud.puede_excavar() and v.clima.buscador_estorbado() > 0.99, "B: con tormenta se puede excavar o el buscador oye")
				_ok(not _hito("mc_ruinas"), "B: la tormenta destapa las ruinas sin llegar al cobijo")
				_poner(T.COBIJO.x, T.COBIJO.y)
				_fase("cobijo")
		"cobijo":
			if _hito("mc_ruinas"):
				_ok(_en(30 * 5), "B: la tormenta amaina sin esperar en el cobijo")
				_fase("cobijo2")
			elif _en(30 * 12):
				_mal("B: en el cobijo la tormenta no amaina")
				_fase("cobijo2")
		"cobijo2":
			if _en(30 * 4):
				_ok(v.terreno.arco_ruinas.position.y > T.altura(T.RUINAS.x, T.RUINAS.y) - 0.3, "B: el arco no sale de la arena")
				_poner(49.0, 21.3)
				_fase("llave")
		"llave":
			if _en(45):
				_ok(not v.clima.en_tormenta(), "B: la tormenta sigue en las ruinas")
				v.hud.excavar()
				_fase("llave2")
		"llave2":
			if _en(50):
				_ok(_hito("mc_llave") and Inv.cantidad("Llave de vidrio") == 1, "B: no sale la llave")
				_poner(T.TRAMPILLA.x, T.TRAMPILLA.y + 1.2)
				v.mision.accion(v, "trampilla")
				_fase("trampilla")
		"trampilla":
			if _en(45):
				_cortar()                                        # el mural
				_fase("trampilla2")
		"trampilla2":
			if _en(45):
				_cortar()                                        # Oren
				_fase("trampilla3")
		"trampilla3":
			if _en(45):
				_ok(_hito("mc_superviviente") and v.oren != null, "B: abrir la trampilla no rescata a Oren")
				oro0 = Inv.oro()
				_poner(T.CARTOGRAFA.x, T.CARTOGRAFA.y + 1.4)
				v.mision.accion(v, "cartografa")
				_fase("fin")
		"fin":
			if _en(45):
				_cortar()
				_fase("fin2")
		"fin2":
			if _en(45):
				_ok(_hito("mc_fin"), "B: hablar con Ismena al final no da mc_fin")
				_ok(Inv.oro() == oro0 + 150, "B: la paga no son 150 monedas (%d → %d)" % [oro0, Inv.oro()])
				_ok(B.nivel() >= 2 and B.tiene(), "B: el buscador no queda para Kael de nivel 2")
				_ok("aguja_resonancia" in Inv.datos()["equipables"], "B: no se recibe la Aguja de Resonancia")
				v.mision.accion(v, "cartografa")                 # otra vez: sin premio
				_cortar()
				_fase("fin3")
		"fin3":
			if _en(45):
				_cortar()
				_ok(Inv.oro() == oro0 + 150, "B: la recompensa se repite")
				volcado = P.volcar(REGION)
				_fase("recargar")
		# ---------------------------------------------------------------- C. recarga
		"recargar":
			for k in P.CLAVES:
				if Engine.has_meta(k):
					Engine.remove_meta(k)
			P.restaurar(volcado)
			Engine.set_meta("incienso", 100000)
			Engine.set_meta("partida_lista", true)
			change_scene_to_file(REGION)
			v = null
			_fase("recargar2")
		"recargar2":
			if current_scene != null and current_scene.scene_file_path == REGION and _en(20):
				v = current_scene
				_ok(v.mision.ruinas_reveladas() and absf(v.terreno.arco_ruinas.position.y - T.altura(T.RUINAS.x, T.RUINAS.y)) < 0.05,
					"C: al recargar, las ruinas vuelven a estar enterradas")
				_ok(v.oren != null and B.tiene() and v.hud.boton.visible, "C: al recargar falta Oren o el buscador")
				_ok(B.pendientes(v.REGION_BUSCADOR, v.SEMILLA).all(func(h): return h["id"] != "sello_caravana" and h["id"] != "llave_vidrio"),
					"C: al recargar, lo único vuelve a pitar")
				_ok(not v.clima.en_tormenta(), "C: al recargar con la misión hecha, hay tormenta")
				_fase("andar")
		# ---------------------------------------------------------------- D. andar
		"andar":                                                 # por el camino, como lo haría quien juega, tramo a tramo
			_poner(T.ENTRADA.x, T.ENTRADA.z)
			tramos = [Vector3(44.0, 0, 97.0), Vector3(38.5, 0, 97.5), Vector3(44.0, 0, 90.0), Vector3(46.0, 0, 80.0),
				Vector3(T.CARAVANA.x, 0, T.CARAVANA.y + 4.0)]
			i_tramo = 0
			v.destino = v._ajustar_destino(tramos[0])
			_fase("andar2")
		"andar2":
			if v.destino == null or _en(30 * 15):
				var meta: Vector3 = tramos[i_tramo]
				var d: float = Vector2(v.kael.global_position.x - meta.x, v.kael.global_position.z - meta.z).length()
				if d >= 1.0:
					_mal("D: [%s] no llega andando a %s (queda a %.1f m, Kael en %s, destino %s)" % [PERFILES[ip], meta, d, v.kael.global_position, v.destino])
				i_tramo += 1
				if i_tramo < tramos.size() and d < 1.0:
					v.destino = v._ajustar_destino(tramos[i_tramo])
					_fase("andar2")
				else:
					_ok(v.get("_prohibido").call(Vector3(T.OASIS.x, 0, T.OASIS.y)) and v.get("_prohibido").call(Vector3(6, 0, 24)),
						"D: el estanque o una roca se pueden pisar")
					if PERFILES[ip] == "bajo":
						return _siguiente()
					_fase("gusano")
		# ---------------------------------------------------------------- E. Bramavidrio
		"gusano":
			v.clima.sistemicas = false
			_poner(80.0, 40.0)
			_ok(v.gusano.arena_blanda(v.kael.global_position), "E: (80, 40) no es arena blanda")
			_fase("gusano2")
		"gusano2":
			if v.gusano.estado == "aviso":
				_ok(v.gusano._lomo != null and v.gusano._lomo.visible, "E: el aviso no tiene surco")
				_poner(T.CAMINO[3].x, T.CAMINO[3].y)              # al camino: se va
				_fase("gusano3")
			elif _en(30 * 6):
				_mal("E: en la arena que tiembla no avisa")
				_fase("gusano3")
		"gusano3":
			if _en(45):
				_ok(v.gusano.estado == "descanso", "E: al salir de la arena blanda no se va (%s)" % v.gusano.estado)
				v.gusano.estado = "calma"
				_poner(80.0, 40.0)
				_fase("gusano4")
		"gusano4":
			if v.saliendo:
				_ok(str(Engine.get_meta("combate_fijo", "")) == "mc_bramavidrio" and int(Engine.get_meta("grupo_combate", -1)) == 13,
					"E: al emerger no pide su combate fijo")
				_fase("gusano5")
			elif _en(30 * 20):
				_mal("E: quedándose en la arena blanda no emerge (estado %s)" % v.gusano.estado)
				return _siguiente()
		"gusano5":                                              # se espera al combate (Recursos cambia de escena)
			if t_combate == 0:
				t_combate = Time.get_ticks_msec()
			var en_combate: bool = current_scene != null and current_scene.scene_file_path == "res://combate.tscn"
			if en_combate and _en(60) or Time.get_ticks_msec() - t_combate > 30000:
				_ok(en_combate, "E: el combate de Bramavidrio no llega a cargar")
				return _siguiente()
	return false


func _comprobar_carga() -> void:
	var p: String = PERFILES[ip]
	_ok(v.terreno._modelos >= 20, "A: [%s] faltan piezas de gráficos (%d)" % [p, v.terreno._modelos])
	_ok(v.cartografa != null and v.get_node_or_null("Cartografa") != null, "A: [%s] falta la cartógrafa" % p)
	_ok(absf(v.kael.global_position.z - T.ENTRADA.z) < 0.5, "A: [%s] Kael no está en la entrada" % p)
	_ok(absf(v.kael.global_position.y - T.altura(T.ENTRADA.x, T.ENTRADA.z)) < 0.3, "A: [%s] Kael no está sobre la arena" % p)
	if PERFILES[ip] == "bajo":
		_ok(not B.tiene() and not v.hud.boton.visible, "A: Kael empieza con el buscador")
	print("  [%s] piezas %d, perfil %s" % [p, v.terreno._modelos, v.nombre_perfil])


func _siguiente() -> bool:
	ip += 1
	if ip >= PERFILES.size():
		return _fin()
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("combate_fijo")
	Engine.remove_meta("grupo_combate")
	_cargar()
	return false


func _fin() -> bool:
	Engine.remove_meta("calidad_proto")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
