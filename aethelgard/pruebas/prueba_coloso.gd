extends SceneTree
# El Coloso de la Falla (V9, jefe 2; combate_coloso.gd), en combates de verdad con «-- auto»:
#   A. Fase 1: piel de piedra (un golpe físico hace la mitad; la magia, entera). Puño de la Falla forzado: al
#      descargarlo queda EXPUESTO (puntos débiles dibujados, «✦ Expuesto» sobre su vida, su sonido una vez) y un golpe
#      de verdad de Kael hace ×1,5 × 1,25; en su turno siguiente se recompone y la ventana se cierra. Garon lee las
#      inscripciones (ESGRIMA, «Leer runas»: 3 PM; el menú se abre sin errores): la piel se abre 2 turnos del Coloso y
#      vuelve. Al bajar del 50 %, la fase 2: coraza rúnica puesta (la magia de verdad de Lya hace la mitad; los golpes,
#      enteros), más rápido; en su turno cambia a la piel de piedra; el Derrumbe rúnico alcanza a todo el grupo y abre la
#      ventana. Victoria: combate fijo ganado, +2 Mineral rúnico (material con venta) y el Fragmento de armadura antigua.
#   A2. El mismo combate otra vez: sin premio.
#   B. Derrota: no se apunta como ganado ni da premio (reintento seguro).
#   C. Datos: el modelo 3D sin GLB usa el respaldo 2D; el Fragmento y el Mineral, con su sitio y su venta.
# Ayudas de la prueba (no del juego): el grupo a nivel 9, y en la fase 1 la vida del Coloso y la de los héroes se
# rellenan para que los ataques automáticos no adelanten las fases. Ganar así no prueba la estrategia de un jugador.
# Datos aislados; la partida en memoria (no se escribe nada).

const LIMITE := 5000
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que la semilla se pone en cada caso
# DESPUÉS de root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos con ella (como prueba_gorthor_v12.gd).
# Antes había un seed(12) al empezar que el primer _ready deshacía: los tres casos eran al azar. El caso A se empieza
# diferido: desde _initialize el add_child no ejecuta el _ready al momento (la raíz aún no está en el árbol). Cada caso imprime
# «SEMILLA» y una «TRAZA» por paso del guion (fotograma del caso, paso y PV de todos).
const SEMILLA := 12
const K := preload("res://combate_coloso.gd")

var c: Node
var fase := ""
var frames := 0
var fallos := 0
var paso := 0
var f_paso := 0
var Inv
var sonidos: Array = []
var golpe := -2                 # lo que quitó el último golpe de verdad (-1: en curso; -2: ninguno)
var sin_ayuda := false
var antes_hp := {}
var vel_fase1 := 0.0


func _initialize() -> void:
	if not "auto" in OS.get_cmdline_user_args():
		print("FALLO: falta «-- auto»")
		quit(1)
		return
	Inv = load("res://inventario.gd")
	for k in ["decisiones", "combates_ganados", "hitos", "inventario", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var G = load("res://grupo.gd")
	for n in G.miembros():
		G.datos()[n]["nivel"] = 9
		G.datos()[n]["pv"] = -1
	_datos()
	_empezar.call_deferred("A")                   # (diferido: en _initialize la raíz aún no está en el árbol y el _ready
	                                              # del combate llegaría después de la semilla)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: [%s] %s" % [fase, t])


func _ok(t: String) -> void:
	print("OK [%s] %s" % [fase, t])


func _empezar(f: String) -> void:
	if c != null:
		c.queue_free()
		c = null
	fase = f
	frames = 0
	paso = 0
	f_paso = 0
	sonidos.clear()
	Engine.time_scale = 1.0
	Engine.set_meta("grupo_combate", K.GRUPO)
	Engine.set_meta("combate_fijo", K.COMBATE)
	Engine.set_meta("desde_mapa", false)
	Engine.set_meta("zona", "garganta")
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)                                 # (aquí su _ready hace randomize())
	seed(SEMILLA)                                     # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                     # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA %d · caso %s" % [SEMILLA, f])
	c.sonido_pedido.connect(func(n): sonidos.append(n))


func _coloso() -> Dictionary:
	for e in c.enemigos:
		if K.es_coloso(e):
			return e
	return {}


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _siguiente(p: int) -> void:
	paso = p
	f_paso = frames
	var pv := []
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA [%s] f%05d paso %d · %s" % [fase, frames, p, ", ".join(pv)])


func _terminar(siguiente: String) -> void:
	print("caso %s: terminado en %d fotogramas" % [fase, frames])
	if siguiente == "":
		print("FALLOS: %d" % fallos)
		quit(1 if fallos > 0 else 0)
	else:
		_empezar(siguiente)


func _process(_d: float) -> bool:
	if c == null or not is_instance_valid(c):
		return false
	frames += 1
	if frames > LIMITE:
		_fallo("no termina (paso %d, estado %s)" % [paso, c.estado])
		_terminar({"A": "A2", "A2": "B", "B": ""}[fase])
		return false
	var g := _coloso()
	if g.is_empty():
		return false
	match fase:
		"A":
			_ayudas(g)
			_caso_a(g)
		"A2":
			_caso_a2(g)
		"B":
			_caso_b(g)
	return false


# Que los ataques automáticos no adelanten la fase 2 ni tumben al grupo mientras se prueba la fase 1.
func _ayudas(g: Dictionary) -> void:
	if sin_ayuda or golpe == -1 or c.estado == "fin":
		return
	if paso < 20 and g["hp"] > 0 and g["hp"] < g["hp_max"] * 0.9:   # (ningún golpe solo baja del 90 % al 50 %)
		g["hp"] = g["hp_max"]
	for h in c.heroes:
		if h["hp"] > 0 and h["hp"] < h["hp_max"] * 0.5:
			h["hp"] = h["hp_max"]


# Un golpe de verdad (combate.gd _animar_golpe, con su animación) sin que nadie más actúe mientras dura.
func _golpe_real(origen: Dictionary, g: Dictionary, dano: int, magia: String) -> void:
	golpe = -1
	c.estado = "accion"
	var antes: int = g["hp"]
	await c._animar_golpe(origen, g, dano, magia)
	golpe = antes - g["hp"]
	if c.estado == "accion":
		c.estado = "esperando"


func _forzar_turno(g: Dictionary) -> void:
	if not c.cola.any(func(x): return is_same(x, g)):   # (si ya espera su turno, no se le mete dos veces)
		g["atb"] = 99.99


func _caso_a(g: Dictionary) -> void:
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	var garon := _heroe("Garon")
	match paso:
		0:
			if frames < 30 or c.estado != "esperando":
				return
			if kael.is_empty() or lya.is_empty() or garon.is_empty():
				_fallo("faltan héroes en el combate: %s" % [c.heroes.map(func(h): return h["nombre"])])
				_terminar("A2")
				return
			if g.get("fase2", false):
				_fallo("empieza en la fase 2")
			var fis: int = K.dano_recibido(100, "", lya, g)
			var fis_k: int = K.dano_recibido(100, "", kael, g)
			var mag: int = K.dano_recibido(100, "Agua", lya, g)
			if fis != 50 or fis_k != 50 or mag != 100:
				_fallo("fase 1: golpe %d, golpe de Kael %d, magia %d (debían ser 50, 50 y 100)" % [fis, fis_k, mag])
			if not "Piel de piedra" in g["lbl_estado"].text:
				_fallo("fase 1: sobre su vida no pone «Piel de piedra» («%s»)" % g["lbl_estado"].text)
			var otro := {"clave": "gorthor", "hp": 100}
			if K.dano_recibido(100, "", kael, otro) != 100 or K.dano_recibido(100, "Fuego", lya, otro) != 100:
				_fallo("las reglas del Coloso cambian el daño a otro enemigo")
			_ok("fase 1: piel de piedra (golpe 100 → %d, magia 100 → %d)" % [fis, mag])
			g["cargando"] = true                       # el Puño de la Falla, preparado
			g["objetivo_carga"] = kael
			c._marcar_aviso(g, true)
			_forzar_turno(g)
			_siguiente(1)
		1:
			if not g.get("expuesto", false) or c.estado != "esperando":
				return
			if not g.has("puntos_nodo") or not is_instance_valid(g["puntos_nodo"]):
				_fallo("ventana: no se dibujan los puntos débiles")
			if g.get("cargando", false) or g.has("aviso_nodo"):
				_fallo("ventana: sigue cargando o con la señal de aviso")
			c._actualizar()
			if not "Expuesto" in g["lbl_estado"].text:
				_fallo("ventana: sobre su vida no pone «Expuesto» («%s»)" % g["lbl_estado"].text)
			if sonidos.count("coloso_expuesto") != 1:
				_fallo("ventana: su sonido se pidió %d veces" % sonidos.count("coloso_expuesto"))
			if K.dano_recibido(100, "", lya, g) != 150 or K.dano_recibido(100, "", kael, g) != 188 \
					or K.dano_recibido(100, "Rayo", lya, g) != 100:
				_fallo("ventana: golpe %d, Kael %d, magia %d (debían ser 150, 188 y 100)" % [K.dano_recibido(100, "", lya, g),
					K.dano_recibido(100, "", kael, g), K.dano_recibido(100, "Rayo", lya, g)])
			g["hp"] = g["hp_max"]
			_golpe_real(kael, g, 80, "")
			_siguiente(2)
		2:
			if golpe < 0:
				return
			if not golpe in [150, 240]:                  # 240: crítico (128 × 1,875)
				_fallo("ventana: un golpe de verdad de Kael de 80 quitó %d (150, o 240 con crítico)" % golpe)
			else:
				_ok("ventana: expuesto tras el Puño, puntos débiles y un golpe de Kael de 80 quita %d (×1,875)" % golpe)
			golpe = -2
			_forzar_turno(g)
			_siguiente(3)
		3:
			if g.get("expuesto", false) or c.estado != "esperando":
				return
			if g.has("puntos_nodo"):
				_fallo("al recomponerse, los puntos débiles siguen")
			if K.dano_recibido(100, "", lya, g) != 50:
				_fallo("al recomponerse no vuelve la piel de piedra")
			_ok("su turno siguiente: se recompone y la ventana se cierra")
			_siguiente(4)
		4:
			if c.estado != "esperando":
				return
			garon["mp"] = maxi(garon["mp"], 10)
			garon["mp_max"] = maxi(garon["mp_max"], garon["mp"])
			c.actor = garon
			c.estado = "menu"
			c.menu.heroe_actual = garon                # (como si Garon hubiera abierto su menú)
			c._menu_esgrima()                          # con «Leer runas»
			var en_menu := false
			for n in c.menu.find_children("*", "", true, false):
				if "text" in n and str(n.get("text")) == K.LECTURA["nombre"]:
					en_menu = true
			if not en_menu:
				_fallo("ESGRIMA de Garon no muestra «%s» contra el Coloso" % K.LECTURA["nombre"])
			var pm: int = garon["mp"]
			c._leer_runas()
			if garon["mp"] != pm - K.LECTURA["coste"]:
				_fallo("Leer runas gastó %d PM (debía %d)" % [pm - garon["mp"], K.LECTURA["coste"]])
			if int(g.get("lectura_turnos", 0)) != K.TURNOS_LECTURA:
				_fallo("Leer runas: %d turnos (debían ser %d)" % [int(g.get("lectura_turnos", 0)), K.TURNOS_LECTURA])
			if K.dano_recibido(100, "", lya, g) != 100 or K.motivo_lectura(g) == "":
				_fallo("con las runas leídas, un golpe hace %d (debía 100) o se pueden leer otra vez" % K.dano_recibido(100, "", lya, g))
			_siguiente(5)
		5:
			if c.estado != "esperando":
				return
			if not "Runas leídas" in g["lbl_estado"].text:
				_fallo("con las runas leídas, sobre su vida no lo pone («%s»)" % g["lbl_estado"].text)
			_ok("Garon lee las runas: 3 PM, la piel se abre (golpe 100 → 100)")
			_forzar_turno(g)
			_siguiente(6)
		6:
			if int(g.get("lectura_turnos", 0)) > 1 or c.estado != "esperando":
				return
			_forzar_turno(g)
			_siguiente(7)
		7:
			if int(g.get("lectura_turnos", 0)) > 0 or c.estado != "esperando":
				return
			if not g.get("expuesto", false) and K.dano_recibido(100, "", lya, g) != 50:
				_fallo("tras dos turnos suyos, la piel de piedra no vuelve")
			_ok("la lectura dura 2 turnos del Coloso y la piel vuelve")
			g["cargando"] = false                      # para que la fase 2 empiece limpia
			g["expuesto"] = false
			c._marcar_aviso(g, false)
			c._marcar_puntos(g, false)
			vel_fase1 = g["vel"]
			c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.45))
			_siguiente(20)
		20:
			if not g.get("fase2", false) or g.get("fase2_pendiente", false) or c.estado != "esperando":
				return
			if not g.get("coraza_runica", false):
				_fallo("fase 2: no lleva la coraza rúnica al empezar")
			if K.dano_recibido(100, "Fuego", lya, g) != 50 or K.dano_recibido(100, "", lya, g) != 100:
				_fallo("fase 2 con coraza: magia %d, golpe %d (debían ser 50 y 100)" % [K.dano_recibido(100, "Fuego", lya, g),
					K.dano_recibido(100, "", lya, g)])
			if g["vel"] <= vel_fase1:
				_fallo("fase 2: no va más rápido (%.1f)" % g["vel"])
			c._actualizar()
			if not "Coraza rúnica" in g["lbl_estado"].text:
				_fallo("fase 2: sobre su vida no pone «Coraza rúnica» («%s»)" % g["lbl_estado"].text)
			_golpe_real(lya, g, 100, "Fuego")
			_siguiente(21)
		21:
			if golpe < 0:
				return
			if golpe != 50:
				_fallo("fase 2: un Fuego de verdad de Lya de 100 quitó %d con la coraza rúnica (debía 50)" % golpe)
			else:
				_ok("fase 2: las runas despiertan, más rápido; con la coraza rúnica un Fuego de 100 quita 50")
			golpe = -2
			_forzar_turno(g)
			_siguiente(22)
		22:
			if g.get("coraza_runica", false) or c.estado != "esperando":
				return
			g["cargando"] = false
			c._marcar_aviso(g, false)
			if K.dano_recibido(100, "", lya, g) != 50 and not g.get("expuesto", false):
				_fallo("fase 2 sin coraza: el golpe no hace la mitad (piel de piedra)")
			if K.dano_recibido(100, "Agua", lya, g) != 100:
				_fallo("fase 2 sin coraza: la magia no hace entera")
			if not "Piel de piedra" in g["lbl_estado"].text and not g.get("expuesto", false):
				_fallo("fase 2: al cambiar, sobre su vida no pone «Piel de piedra» («%s»)" % g["lbl_estado"].text)
			_ok("fase 2: en su turno alterna a la piel de piedra (golpe 50, magia 100)")
			sin_ayuda = true
			antes_hp.clear()
			for h in c.heroes:
				if h["hp"] > 0:
					h["hp"] = h["hp_max"]
					antes_hp[h["nombre"]] = h["hp"]
			sonidos.clear()
			g["expuesto"] = false
			c._marcar_puntos(g, false)
			g["cargando"] = true                       # el Derrumbe rúnico, preparado
			_forzar_turno(g)
			_siguiente(23)
		23:
			if not g.get("expuesto", false) or c.estado != "esperando":
				return
			for h in c.heroes:
				if antes_hp.has(h["nombre"]) and h["hp"] >= antes_hp[h["nombre"]]:
					_fallo("el Derrumbe rúnico no alcanzó a %s" % h["nombre"])
			if sonidos.count("coloso_expuesto") != 1:
				_fallo("tras el Derrumbe, el sonido de la ventana se pidió %d veces" % sonidos.count("coloso_expuesto"))
			_ok("fase 2: el Derrumbe rúnico alcanza a todo el grupo y abre la ventana")
			sin_ayuda = false
			c._quitar_pv(g, g["hp"])
			c._comprobar_fin()
			_siguiente(24)
		24:
			if not Engine.get_meta("combates_ganados", {}).get(K.COMBATE, false):
				if frames - f_paso > 60:
					_fallo("victoria: el combate fijo no queda ganado")
					_terminar("A2")
				return
			if Inv.cantidad(K.MATERIAL) != K.CANTIDAD_MATERIAL:
				_fallo("victoria: %s: %d (debía %d)" % [K.MATERIAL, Inv.cantidad(K.MATERIAL), K.CANTIDAD_MATERIAL])
			if Inv.datos()["equipables"].count(K.ACCESORIO) != 1:
				_fallo("victoria: el Fragmento de armadura antigua no se recibe una vez")
			if g.has("puntos_nodo"):
				_fallo("victoria: los puntos débiles siguen tras caer")
			_ok("victoria: combate fijo ganado, +%d %s y el Fragmento de armadura antigua" % [K.CANTIDAD_MATERIAL, K.MATERIAL])
			_siguiente(25)
		25:
			if frames - f_paso > 30:
				_terminar("A2")


func _caso_a2(g: Dictionary) -> void:
	if paso == 0 and frames > 30 and c.estado == "esperando":
		c._quitar_pv(g, g["hp"])
		c._comprobar_fin()
		if Inv.cantidad(K.MATERIAL) != K.CANTIDAD_MATERIAL or Inv.datos()["equipables"].count(K.ACCESORIO) != 1:
			_fallo("repetir el combate duplica el premio (%s: %d)" % [K.MATERIAL, Inv.cantidad(K.MATERIAL)])
		else:
			_ok("repetirlo ya ganado no da el premio otra vez")
		_siguiente(1)
	elif paso == 1 and frames - f_paso > 30:
		for k in ["combates_ganados", "inventario"]:
			if Engine.has_meta(k):
				Engine.remove_meta(k)
		_terminar("B")


func _caso_b(g: Dictionary) -> void:
	if paso == 0 and frames > 30 and c.estado == "esperando":
		for h in c.heroes:
			c._quitar_pv(h, h["hp"])
		c._comprobar_fin()
		_siguiente(1)
	elif paso == 1 and frames - f_paso > 30:
		if c.estado != "fin":
			_fallo("derrota: el combate no termina")
		if Engine.get_meta("combates_ganados", {}).get(K.COMBATE, false):
			_fallo("derrota: se apunta como ganado")
		if Inv.cantidad(K.MATERIAL) != 0 or K.ACCESORIO in Inv.datos()["equipables"]:
			_fallo("derrota: da el premio")
		if g["hp"] <= 0:
			_fallo("derrota: el Coloso cae")
		_ok("derrota: ni ganado ni premio (se puede reintentar)")
		_terminar("")


# C. Datos, sin combate.
func _datos() -> void:
	fase = "C"
	var C = load("res://combate.gd")
	var m3: Dictionary = C.MODELOS["coloso_falla"]
	var e: Dictionary = C.ENEMIGOS[K.CLAVE]
	if not C.MODELOS.has(m3.get("respaldo", "")) or C.MODELOS[m3["respaldo"]].get("tipo", "") != "imagen":
		_fallo("el modelo 3D no tiene un respaldo 2D de imagen")
	if not C.ANIM.has("coloso_falla") or not C.ANIM.has("coloso_falla2d"):
		_fallo("faltan sus filas en ANIM")
	if not ResourceLoader.exists(C.MODELOS["coloso_falla2d"]["imagen"]):
		_fallo("no existe la imagen del respaldo 2D")
	if e["modelo"] == "coloso_falla" and not (ResourceLoader.exists(m3["script"]) and ResourceLoader.exists(m3["rutas"][0])):
		print("AVISO: el Coloso usa la entrada 3D sin su GLB; combate.gd tomará el respaldo 2D")
	if K.MODELO_3D and not ResourceLoader.exists(K.GLB_3D):
		_fallo("combate_coloso.MODELO_3D activo sin el GLB")
	if C.GRUPOS[K.GRUPO][0][0] != K.CLAVE:
		_fallo("GRUPOS[%d] no es el Coloso" % K.GRUPO)
	var Extra = load("res://equipo_extra.gd")
	var mats: Dictionary = Extra.materiales()
	if not mats.has(K.MATERIAL) or int(mats[K.MATERIAL]["venta"]) <= 0:
		_fallo("el %s no es un material con venta" % K.MATERIAL)
	if not Extra.disponible(K.ACCESORIO):
		_fallo("el Fragmento de armadura antigua no está disponible (su efecto sin enganchar)")
	if not load("res://hallazgos.gd").FUERA.has(K.ACCESORIO):
		_fallo("el Fragmento no explica en hallazgos.gd (FUERA) cómo se consigue")
	_ok("datos: respaldo 2D, ANIM, grupo %d, material con venta (%d) y accesorio disponible con su FUERA" % [K.GRUPO,
		int(mats.get(K.MATERIAL, {}).get("venta", 0))])
