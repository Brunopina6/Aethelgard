extends SceneTree
# Bramavidrio en combates de verdad (V12; combate_bramavidrio.gd y sus ganchos en combate.gd), sin ventana y con datos
# aislados. Combate fijo «mc_bramavidrio» (grupo 13), en el desierto y como jefe. El combate no guarda (sin
# «desde_mapa») y la partida apunta a su propio archivo.
#   A. Kael, Lya y Garon a nivel 10 (el del desierto, acto II) con una estrategia de jugador sencilla (defender la
#      Fractura, cargar contra el Aliento, curar con Lya): en cada turno del gusano se mira qué hizo y que lo hizo bien:
#        Embestida: un impacto (señal del modelo), un héroe alcanzado, su golpe sordo una vez y en el mismo fotograma.
#        Avisos: ningún daño, la señal de aviso una vez, el cartel arriba y «⚠ Fractura»/«⚠ Aliento» sobre su vida, el
#          rugido (Fractura) o el temblor de la succión (Aliento) una vez.
#        Fractura: un impacto, todos alcanzados una vez (salvo Garon si cubre), quien defiende recibe la mitad o menos y
#          no se tambalea, el temblor una vez en el fotograma del impacto.
#        Aliento: un impacto, todos alcanzados, el rugido una vez en el fotograma del impacto; el turno siguiente jadea.
#        Nada encadenado: cada especial se avisa el turno anterior, entre dos especiales soltados hay otro turno suyo, y
#          entre el aviso y el golpe actúa al menos un héroe.
#      Gana; el premio (2 Reliquias de vidrio) una vez y el combate fijo apuntado. A2: otra vez, sin premio.
#   B. Interrupción: con la mitad de vida (la prueba se la quita al empezar) prepara el Aliento; cargando contra él se
#      corta («cortado»), queda aturdido, su turno siguiente lo pierde y no hay impacto del Aliento.
#   C. Defender el Aliento: los tres en guardia reciben la mitad o menos.
#   D. Kael y Lya a nivel 10 (dos héroes): con la misma estrategia, ganan en alguna de hasta cuatro semillas.
#   E. Derrota (Kael y Lya a nivel 1): el combate acaba sin bloquearse, no se apunta como ganado ni da premio.
#   F. Combate real con ataques automáticos (los tres a nivel 10): termina sin bloquearse (se apunta quién gana). Ganar
#      así no prueba la estrategia de un jugador.
#   G. Detalles: el tambaleo quita TAMBALEO a quien no defiende y nada a quien defiende o ya espera turno; lo que se lee.
#   V12, Bramavidrio v2 (11/11, efectos de los ataques): en cada turno, que se crean los efectos de ese ataque
#     (Embestida: anticipación, destello, estela y golpe de arena; Fractura: sombra, grietas, placas, nube a ras de suelo,
#     placas que se asientan y se acaban; Aliento: succión con los héroes inclinados mientras aspira, y el chorro que
#     barre y alcanza a cada héroe en pie); que mientras ataca se dibuja delante de algún héroe y al acabar vuelve a su
#     sitio, detrás de todos; que al morir se vuelve (DIR_DERROTA) y cae detrás de los héroes; que al acabar cada combate
#     no queda ningún efecto suyo en la escena, los dibujos de los héroes vuelven a su sitio y no crecen los nodos
#     huérfanos. Sirve con las dos versiones del modelo («-- bramavidrio_version=1» para la v1).
#   Pulido (12/11): en cada turno suyo el orden frente a cada héroe cambia como mucho dos veces (delante al atacar y
#     detrás al acabar: sin parpadeos; con la v3 Garon parpadeaba encima y debajo de la cabeza); al cerrar cada combate el
#     bucle de la succión no suena. H: se cierra el combate a medias mientras aspira: el bucle calla y no quedan nodos
#     sueltos. I: muere mientras aspira: el bucle calla, sin succión, héroes derechos, sin cartel y sin Aliento.
# Con «medir» solo se mide el equilibrio (varias semillas, 2 y 3 héroes, jugador y automático) y se imprime.
# Con «fotos=<carpeta>» (y ventana) saca capturas de cada ataque en su momento clave.
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que la semilla se pone DESPUÉS de
# root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos con ella (como prueba_gorthor_v12.gd). Antes se
# sembraba antes de add_child y cada combate era al azar («hasta cuatro semillas» eran cuatro combates al azar). Cada
# combate imprime «SEMILLA» y una «TRAZA» por turno (fotograma del combate, quién o qué hizo el gusano, PV de todos).

const ARCHIVO := "user://prueba_bramavidrio_combate.save"
var B                                   # combate_bramavidrio.gd (con load: usa el autoload Sonido)
const MAX_FOTOGRAMAS := 16000

var P
var G
var Inv
var c = null
var z = null
var zp = null
var fallos: Array = []
var hechos: Array = []
var fotos := ""
var n_foto := 0
var sonidos: Array = []                 # [nombre, fotograma] que pide combate.gd (señal sonido_pedido)
var impactos: Array = []                # [ataque, fotograma] (señal impacto del modelo)
var avisos: Array = []
var medir := false
var huerfanos0 := -1                    # nodos huérfanos antes del primer combate (Performance)
var frente_visto := {}                  # ataque → se dibujó delante de algún héroe (V12, Bramavidrio v2)
var tiro_visto := false                 # los héroes se inclinaron mientras aspiraba
var cambios_orden := {}                 # (pulido, 12/11) héroe → veces que el gusano pasa de detrás a delante o al revés en su turno
var encima_ant := {}


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Inv = load("res://inventario.gd")
	B = load("res://combate_bramavidrio.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
		if a == "medir":
			medir = true
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			"prueba_curar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _combate(activos: Dictionary, semilla: int, ganados := {}) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("combates_ganados", ganados.duplicate())
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", B.GRUPO)
	Engine.set_meta("combate_fijo", B.COMBATE)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	impactos.clear()
	avisos.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)                                     # (aquí su _ready hace randomize())
	seed(semilla)                                         # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                         # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA %d · %s" % [semilla, str(activos)])
	z = c.enemigos[0]
	zp = c._p3d(z)
	if zp != null:
		zp.impacto.connect(func(a): impactos.append([a, Engine.get_process_frames()]))
		zp.aviso.connect(func(a): avisos.append([a, Engine.get_process_frames()]))
		if fotos != "":
			_conectar_fotos()


func _cerrar() -> void:
	if c != null:
		await _sin_efectos()
		c.queue_free()
		c = null
	await _esperar(5)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if huerfanos0 < 0:
		huerfanos0 = h
	_ok(h <= huerfanos0, "al cerrar el combate hay %d nodos huérfanos (antes %d)" % [h, huerfanos0])


# V12, Bramavidrio v2: al acabar un combate, sus efectos se borran solos (se espera a que acaben los que duran más) y
# los dibujos de los héroes vuelven a su sitio.
func _sin_efectos() -> void:
	if c.brama == null:
		return
	for i in 240:
		if c.brama.efectos_vivos().is_empty():
			break
		await process_frame
	_ok(c.brama.efectos_vivos().is_empty(), "quedan efectos de Bramavidrio en la escena: %s" % str(c.brama.efectos_vivos()))
	_ok(c.brama.chorro == null or not is_instance_valid(c.brama.chorro), "el chorro sigue en la escena")
	_ok(not c.brama._tirando, "los héroes siguen inclinados hacia él")
	_ok(not _bucle_suena(), "al acabar el combate el bucle de la succión sigue sonando")   # (pulido, 12/11)
	for h in c.heroes:
		if h.has("cuerpo_pos0") and h["hp"] > 0:
			_ok(h["cuerpo"].position.distance_to(h["cuerpo_pos0"]) < 0.5,
				"el dibujo de %s no vuelve a su sitio (%s, debía %s)" % [h["nombre"], h["cuerpo"].position, h["cuerpo_pos0"]])


func _probar() -> void:
	await _esperar(10)
	huerfanos0 = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if medir:
		await _medir()
	else:
		var solo := ""                                     # «solo=ACB»: solo esas partes (para las capturas)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("solo="):
				solo = a.substr(5)
		for p in ["A", "B", "C", "D", "E", "F", "H", "I"]:
			if solo == "" or solo.contains(p):
				await call("_" + p.to_lower())
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= el bucle de un combate

# Juega un combate hasta el final. «estrategia»: «jugador» o «auto». «op»: «defender_aliento», «vida» (parte de su vida
# al empezar), «hasta_corte» (para tras el turno siguiente al corte), «comprobar» (las comprobaciones de cada turno).
func _jugar(estrategia: String, op := {}) -> Dictionary:
	var r := {"acciones": [], "gana": false, "fin": false, "fotogramas": 0, "min_vida": 1.0, "cortes": 0,
		"turnos_heroe": 0, "danos": {}}
	if op.has("vida"):
		z["hp"] = int(z["hp_max"] * float(op["vida"]))
		z["normales"] = int(op.get("normales", 0))      # con 1, su primer turno ya prepara el especial que toque
		c._actualizar()
	var comprobar: bool = op.get("comprobar", true)
	var turno := false
	var ant := {}
	var previo := _foto_estado()
	var f_fin := -1
	var decidido := -1
	var tras_corte := -1
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		r["fotogramas"] = fr
		for h in c.heroes:
			r["min_vida"] = minf(r["min_vida"], float(h["hp"]) / h["hp_max"])
		if c.estado == "enemigo" and not turno:            # (su turno empieza en el _process del combate: se compara
			turno = true                                   # con cómo estaba el fotograma anterior)
			ant = previo
			frente_visto.clear()
			cambios_orden.clear()             # (pulido, 12/11) cuántas veces cambia delante/detrás de cada héroe
			encima_ant.clear()
		elif c.estado != "enemigo" and turno:
			turno = false
			var que := _que_hizo(ant)
			r["acciones"].append(que)
			_traza(fr, "Bramavidrio: " + que)
			if comprobar:
				_comprobar_turno(que, ant, r)
			if tras_corte >= 0:
				tras_corte += 1
		if turno:
			_contar_cambios_orden()
		if turno and c.brama != null and c.brama._frente:  # V12, Bramavidrio v2: delante de algún héroe al atacar
			var i_gusano: int = z["rig"].get_index()
			if c.heroes.any(func(h): return h["rig"].get_index() < i_gusano):
				frente_visto["si"] = true
		if c.brama != null and c.brama._tirando:
			tiro_visto = true
		if fotos != "":                                    # capturas: la anticipación de la embestida, un héroe que
			_fotos_bucle()                                 # le ataca y el Aliento cortado
		if c.estado != "enemigo":
			previo = _foto_estado()
		if c.brama != null and int(c.brama.contador.get("cortado", 0)) > r["cortes"]:
			r["cortes"] = int(c.brama.contador["cortado"])
			if tras_corte < 0:
				tras_corte = 0
		if op.get("hasta_corte", false) and tras_corte >= 1 and not turno:
			break
		if c.brama != null and c.brama.succion != null:     # (pulido, 12/11) H e I: mientras aspira
			r["aspirando"] = int(r.get("aspirando", 0)) + 1
			if op.get("hasta_aspirar", false) and r["aspirando"] >= 10:
				break
			if op.get("matar_aspirando", false) and r["aspirando"] == 10 and z["hp"] > 1:
				z["hp"] = 1
				r["bucle_al_matar"] = _bucle_suena()
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_traza(fr, "turno de " + str(c.actor["nombre"]))
			_decidir(estrategia, op)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 120:
			break
	r["fin"] = c.estado == "fin"
	r["gana"] = z["hp"] <= 0 and c.heroes.any(func(h): return h["hp"] > 0)
	r["turnos_heroe"] = c.turnos_heroe
	return r


# Una línea por turno: fotograma del combate, quién y qué, y los PV de todos (para reproducir una semilla concreta).
func _traza(fr: int, que: String) -> void:
	var pv := []
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA %05d %s · %s" % [fr, que, ", ".join(pv)])


func _decidir(estrategia: String, op: Dictionary) -> void:
	var a: Dictionary = c.actor
	if estrategia == "auto":
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(z)
		return
	var esp: String = str(z.get("especial", "")) if z.get("cargando", false) else ""
	if esp == "sismico" or (esp == "aliento" and op.get("defender_aliento", false)):
		c._defender()
		return
	if esp == "aliento":                                      # cargar contra él: Lya con Fuego, Garon con Juicio
		if a["nombre"] == "Lya" and a["mp"] >= 8:
			c._elegir_hechizo("Fuego", 1, true)
		elif a["nombre"] == "Garon" and a["mp"] >= c.TECNICAS_GARON["Juicio"]["coste"]:
			c._tecnica_garon("Juicio", z)
		else:
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(z)
		return
	if a["nombre"] == "Lya":
		var heridos: Array = c.heroes.filter(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.55)
		var sabe_bendicion: bool = c._hechizos(a).any(func(h): return h[0] == "Cura" and h[1] == 2)
		if heridos.size() >= 2 and sabe_bendicion and a["mp"] >= 16:
			c._elegir_hechizo("Cura", 2, true)
			return
		if heridos.size() >= 1 and a["mp"] >= 6:
			c._elegir_hechizo("Cura", 1, true)
			return
		if a["mp"] >= 20:
			c._elegir_hechizo("Fuego", 1, true)
			return
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(z)


func _foto_estado() -> Dictionary:
	var hp := {}
	var defiende := {}
	for h in c.heroes:
		hp[h["nombre"]] = h["hp"]
		defiende[h["nombre"]] = h.get("defendiendo", false)
	return {"hp": hp, "defiende": defiende, "cargando": z.get("cargando", false), "especial": z.get("especial", ""),
		"recupera": z.get("recupera", false), "cont": c.brama.contador.duplicate() if c.brama != null else {},
		"sonidos": sonidos.size(), "impactos": impactos.size(), "avisos": avisos.size(), "f": Engine.get_process_frames(),
		"turnos_heroe": c.turnos_heroe, "aviso_turnos": int(z.get("aviso_turnos", -1)), "furia": z.get("furia", false),
		"atk": z["atk"], "carga": int(z.get("carga_recibido", 0)), "umbral": B.umbral_de(z),
		"creados": c.brama.creados.duplicate() if c.brama != null else {}}


func _que_hizo(ant: Dictionary) -> String:
	var cont: Dictionary = c.brama.contador if c.brama != null else {}
	for k in ["fractura", "aliento", "aviso_sismico", "aviso_aliento", "embestida", "recupera", "sigue"]:
		if int(cont.get(k, 0)) > int(ant["cont"].get(k, 0)):
			return k
	return "nada"


func _comprobar_turno(que: String, ant: Dictionary, r: Dictionary) -> void:
	var golpeados: Array = []
	var dano := {}
	for h in c.heroes:
		var d: int = int(ant["hp"][h["nombre"]]) - int(h["hp"])
		if d > 0:
			golpeados.append(h["nombre"])
			dano[h["nombre"]] = d
	var nuevos_imp: Array = impactos.slice(ant["impactos"])
	var nuevos_son: Array = sonidos.slice(ant["sonidos"])
	var cuenta := func(n: String) -> Array: return nuevos_son.filter(func(s): return s[0] == n)
	var mult := 1.5 if ant["furia"] else 1.0
	# V12, Bramavidrio v2: los efectos de este turno (combate_bramavidrio.gd, «creados» y «contador»)
	var creados: Dictionary = c.brama.creados
	var hechos_fx := func(clase: String) -> int: return int(creados.get(clase, 0)) - int(ant["creados"].get(clase, 0))
	var veces := func(k: String) -> int: return int(c.brama.contador.get(k, 0)) - int(ant["cont"].get(k, 0))
	var i_gusano: int = z["rig"].get_index()
	_ok(not c.brama._frente and c.heroes.all(func(h): return h["rig"].get_index() > i_gusano) or z["hp"] <= 0,
		"%s: al acabar su turno no vuelve detrás de los héroes" % que)
	for n in cambios_orden:                            # (pulido, 12/11) sin parpadeos: delante y detrás, una vez cada uno
		_ok(int(cambios_orden[n]) <= 2, "%s: el orden frente a %s cambia %d veces en su turno (parpadea)" % [que, n, cambios_orden[n]])
	match que:
		"embestida":
			if zp != null:
				for k in ["anticipacion", "fija", "estela", "golpe_embestida"]:
					_ok(hechos_fx.call(k) == 1, "embestida: el efecto «%s» sale %d veces" % [k, hechos_fx.call(k)])
				_ok(frente_visto.has("si"), "embestida: no se dibuja delante de ningún héroe al lanzarse")
				_ok(z["rig"].position.distance_to(z["rig_base"]) < 1.0, "embestida: su dibujo no vuelve a su agujero (%s, debía %s)" % [z["rig"].position, z["rig_base"]])
		"fractura":
			if zp != null:
				for k in ["sombra_caida", "grietas", "nube_suelo"]:
					_ok(hechos_fx.call(k) == 1, "fractura: el efecto «%s» sale %d veces" % [k, hechos_fx.call(k)])
				_ok(hechos_fx.call("placa") == (4 if c.movil else 7), "fractura: %d placas" % hechos_fx.call("placa"))
				for k in ["placas_suelo", "placas_asientan", "placas_fin"]:
					_ok(veces.call(k) == 1, "fractura: «%s» sale %d veces" % [k, veces.call(k)])
				_ok(frente_visto.has("si"), "fractura: no se dibuja delante de ningún héroe al caer")
				_ok(c.brama._fx.is_empty(), "fractura: sus placas siguen apuntadas")
		"aviso_aliento":
			_ok(hechos_fx.call("succion") == 1 and c.brama.succion != null, "aviso del Aliento: no aspira arena del suelo")
		"aliento":
			var en_pie: int = c.heroes.filter(func(h): return int(ant["hp"][h["nombre"]]) > 0).size()
			_ok(hechos_fx.call("chorro") == 1, "aliento: el chorro sale %d veces" % hechos_fx.call("chorro"))
			_ok(veces.call("chorro_alcanza") == en_pie, "aliento: el chorro alcanza a %d de %d" % [veces.call("chorro_alcanza"), en_pie])
			_ok(c.brama.succion == null and not c.brama._tirando, "aliento: sigue aspirando después de soltarlo")
			_ok(tiro_visto, "aliento: los héroes no se inclinaron mientras aspiraba")
	match que:
		"embestida":
			_ok(nuevos_imp.size() == 1 and nuevos_imp[0][0] == "embestida", "embestida: impactos %s" % str(nuevos_imp))
			_ok(golpeados.size() <= 1, "embestida: alcanza a %s" % str(golpeados))
			var t: Array = cuenta.call(B.sonido("embestida"))   # V12, sonido (12/11): el de la identidad elegida
			_ok(t.size() == 1 and nuevos_imp.size() == 1 and t[0][1] == nuevos_imp[0][1],
				"embestida: su golpe sordo %s no va una vez en el impacto %s" % [str(t), str(nuevos_imp)])
		"aviso_sismico", "aviso_aliento":
			var es_s: bool = que == "aviso_sismico"
			_ok(golpeados.is_empty(), "%s: hace daño %s" % [que, str(dano)])
			_ok(nuevos_imp.is_empty(), "%s: golpea %s" % [que, str(nuevos_imp)])
			_ok(avisos.size() - int(ant["avisos"]) == 1, "%s: la señal de aviso sale %d veces" % [que, avisos.size() - int(ant["avisos"])])
			_ok(z.get("cargando", false) and z["lbl_estado"].text.contains("⚠ Fractura" if es_s else "⚠ Aliento"),
				"%s: no se lee sobre su vida («%s»)" % [que, z["lbl_estado"].text])
			_ok(c.brama.cartel != null and is_instance_valid(c.brama.cartel) and c.brama.cartel_titulo.text.contains(
				"Fractura" if es_s else "Aliento"), "%s: no sale el cartel" % que)
			var n_s: int = cuenta.call(B.sonido("rugido") if es_s else B.sonido("succion")).size()
			_ok(n_s == 1, "%s: su sonido (%s) se pide %d veces" % [que, "rugido" if es_s else "temblor", n_s])
			_ok(c.cola.count(z) == 0, "%s: el gusano sigue en la cola" % que)
		"fractura":
			_ok(nuevos_imp.size() == 1 and nuevos_imp[0][0] == "sismico", "fractura: impactos %s" % str(nuevos_imp))
			var vivos_antes: Array = c.heroes.filter(func(h): return int(ant["hp"][h["nombre"]]) > 0)
			_ok(golpeados.size() == vivos_antes.size() or c.heroes.any(func(h): return h.has("guardia_de")),
				"fractura: alcanza a %s de %d" % [str(golpeados), vivos_antes.size()])
			var base: int = int(ant["atk"] * B.MULT_FRACTURA * mult) + 3
			for h in vivos_antes:
				if ant["defiende"][h["nombre"]] and dano.has(h["nombre"]) and not h.has("guardia_de"):
					var tope: int = int((base - int(h.get("def", 0) / 2.0)) * 0.5) + 1
					_ok(dano[h["nombre"]] <= tope, "fractura: %s defendiendo recibe %d (tope %d)" % [h["nombre"], dano[h["nombre"]], tope])
					r["defendida"] = int(r.get("defendida", 0)) + 1
			var t: Array = cuenta.call(B.sonido("fractura"))
			_ok(t.size() == 1 and nuevos_imp.size() == 1 and t[0][1] == nuevos_imp[0][1], "fractura: temblor %s, impacto %s" % [str(t), str(nuevos_imp)])
			_ok(cuenta.call(B.sonido("rugido")).is_empty(), "fractura: ruge otra vez al caer")
			_ok(int(ant["turnos_heroe"]) - int(ant["aviso_turnos"]) >= 1, "fractura: ningún héroe actuó desde el aviso")
			_ok(c.brama.cartel == null, "fractura: el cartel sigue")
		"aliento":
			_ok(nuevos_imp.size() == 1 and nuevos_imp[0][0] == "aliento", "aliento: impactos %s" % str(nuevos_imp))
			var r2: Array = cuenta.call(B.sonido("chorro"))
			_ok(r2.size() == 1 and nuevos_imp.size() == 1 and r2[0][1] == nuevos_imp[0][1], "aliento: rugido %s, impacto %s" % [str(r2), str(nuevos_imp)])
			_ok(int(ant["turnos_heroe"]) - int(ant["aviso_turnos"]) >= 1, "aliento: ningún héroe actuó desde el aviso")
			_ok(z.get("recupera", false) or z["hp"] <= 0, "aliento: después no queda jadeando")
			r["cargas"] = r.get("cargas", []) + ["%d/%d" % [ant["carga"], ant["umbral"]]]
			var base_a: int = int(ant["atk"] * B.MULT_ALIENTO * mult) + 3
			for h in c.heroes:
				if ant["defiende"][h["nombre"]] and dano.has(h["nombre"]) and not h.has("guardia_de"):
					var tope: int = int((base_a - int(h.get("def", 0) / 2.0)) * 0.5) + 1
					_ok(dano[h["nombre"]] <= tope, "aliento: %s defendiendo recibe %d (tope %d)" % [h["nombre"], dano[h["nombre"]], tope])
					r["aliento_defendido"] = int(r.get("aliento_defendido", 0)) + 1
		"recupera", "sigue":
			_ok(golpeados.is_empty() and nuevos_imp.is_empty(), "%s: hace daño %s o golpea %s" % [que, str(dano), str(nuevos_imp)])
	for n in dano:
		r["danos"][que] = r["danos"].get(que, []) + [dano[n]]


# Nada encadenado: cada especial soltado viene de su aviso en el turno anterior del gusano y, entre dos soltados, hay al
# menos otro turno suyo.
func _patron(acciones: Array, quien: String) -> void:
	var ultimo_suelto := -10
	for i in acciones.size():
		var a: String = acciones[i]
		if a == "fractura" or a == "aliento":
			var previo: String = acciones[i - 1] if i > 0 else ""
			var esperado: String = "aviso_sismico" if a == "fractura" else "aviso_aliento"
			_ok(previo == esperado or previo == "sigue", "%s: %s sin su aviso antes (%s)" % [quien, a, str(acciones)])
			_ok(i - ultimo_suelto >= 2, "%s: dos especiales seguidos (%s)" % [quien, str(acciones)])
			ultimo_suelto = i
		if i > 0 and acciones[i - 1] in ["fractura", "aliento"]:
			_ok(not a.begins_with("aviso") and a != "fractura" and a != "aliento",
				"%s: tras un especial, %s (%s)" % [quien, a, str(acciones)])


# ================================================================= A. tres héroes, estrategia de jugador

func _a() -> void:
	var r := {}
	var semilla := 0
	for i in 4:
		semilla = 20261111 + i * 13
		Engine.set_meta("prueba_curar", false)
		await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, semilla)
		var reliquias0: int = Inv.cantidad(B.PREMIO)       # (tras _combate: la partida en memoria empieza de cero)
		_ok(zp != null and z["modelo"] == "bramavidrio", "A: Bramavidrio no está en 3D (%s)" % z["modelo"])
		_ok(c.brama != null, "A: no se crea su nodo (combate_bramavidrio.gd)")
		_ok(c._orden_huir()["apagado"] and c._orden_huir()["motivo"] == "Bramavidrio cierra el paso",
			"A: HUIR no está apagado con su motivo")
		await _esperar(3)
		_ok(zp != null and (zp._entrando or zp._clip == "emerger"), "A: no emerge al empezar")
		r = await _jugar("jugador")
		print("A semilla %d: %s" % [semilla, _resumen(r)])
		_patron(r["acciones"], "A")
		if r["gana"]:
			_ok(Inv.cantidad(B.PREMIO) == reliquias0 + B.PREMIO_CANTIDAD, "A: el premio no llega (%d → %d)" % [reliquias0, Inv.cantidad(B.PREMIO)])
			_ok(Engine.get_meta("combates_ganados", {}).get(B.COMBATE, false), "A: el combate fijo no queda ganado")
			_ok(load("res://zonas3d/mar_cristal/gusano.gd").vencido(), "A: en la región, el gusano no se da por vencido (gusano.gd vencido())")
			_ok(zp._muerta, "A: no cae con su derrota")
			# V12, Bramavidrio v2: al morir se vuelve hacia atrás y cae detrás de los héroes (no encima)
			_ok(c.brama._girado, "A: al morir no se vuelve")
			var meta: float = atan2(B.DIR_DERROTA.x, B.DIR_DERROTA.z) - zp._yaw0
			_ok(absf(wrapf(zp.pivote.rotation.y - meta, -PI, PI)) < 0.05, "A: al morir no mira hacia DIR_DERROTA (%.2f, debía %.2f)" % [zp.pivote.rotation.y, meta])
			_ok(c.heroes.all(func(h): return h["rig"].get_index() > z["rig"].get_index()), "A: caído, se dibuja delante de algún héroe")
			var cab: Vector2 = c.brama._suelo_cabeza()
			var garon: Array = c.heroes.filter(func(h): return h["nombre"] == "Garon")
			if not garon.is_empty():
				_ok(cab.y < c._suelo_de(garon[0]).y, "A: caído, su cabeza queda delante de Garon (%s, Garon %s)" % [cab, c._suelo_de(garon[0])])
			_ok(_sonido(B.sonido("embestida")) >= 1, "A: sin sonidos del gusano")
			await _cerrar()
			break
		await _cerrar()
	_ok(r.get("gana", false), "A: con tres héroes a nivel 10 y estrategia no gana en 4 semillas")
	_ok(r["acciones"].has("embestida") and r["acciones"].has("fractura"), "A: no se ven la embestida y la Fractura: %s" % str(r["acciones"]))
	_ok(int(r.get("defendida", 0)) >= 1, "A: ninguna Fractura defendida")
	hechos.append("A (semilla %d, %d turnos del gusano)" % [semilla, r["acciones"].size()])
	# A2. otra vez, ya ganado: sin premio
	await _combate({"Kael": 30, "Lya": 30, "Garon": 30}, 5, {B.COMBATE: true})
	var reliquias1: int = Inv.cantidad(B.PREMIO)
	var r2 := await _jugar("auto", {"comprobar": false, "vida": 0.08})   # (casi vencido: aquí solo se mira el premio)
	_ok(r2["gana"], "A2: a nivel 30 no gana")
	_ok(Inv.cantidad(B.PREMIO) == reliquias1, "A2: el premio se repite")
	await _cerrar()
	hechos.append("A2: sin premio la segunda vez")


# ================================================================= B. interrupción del Aliento

func _b() -> void:
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, 31)
	var r := await _jugar("jugador", {"vida": 0.5, "normales": 1, "hasta_corte": true})
	print("B: %s" % _resumen(r))
	var i: int = r["acciones"].find("aviso_aliento")
	_ok(i >= 0, "B: con la mitad de vida no prepara el Aliento: %s" % str(r["acciones"]))
	_ok(r["cortes"] >= 1, "B: cargando contra él no se corta el Aliento: %s" % str(r["acciones"]))
	_ok(not r["acciones"].has("aliento"), "B: el Aliento sale aunque se cortó: %s" % str(r["acciones"]))
	if i >= 0 and i + 1 < r["acciones"].size():
		_ok(r["acciones"][i + 1] == "recupera", "B: tras el corte no pierde su turno: %s" % str(r["acciones"]))
	_ok(not impactos.any(func(x): return x[0] == "aliento"), "B: hay impacto del Aliento")
	_ok(_sonido(c.Artes.SONIDO_ESTADO["rota"]) >= 1, "B: el corte no suena")
	await _cerrar()
	hechos.append("B: Aliento cortado")


# ================================================================= C. defender el Aliento

func _c() -> void:
	var r := {}
	for s in [41, 43, 47]:
		await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, s)
		r = await _jugar("jugador", {"vida": 0.5, "normales": 1, "defender_aliento": true})
		print("C semilla %d: %s" % [s, _resumen(r)])
		_patron(r["acciones"], "C")
		await _cerrar()
		if int(r.get("aliento_defendido", 0)) >= 1:
			break
	_ok(int(r.get("aliento_defendido", 0)) >= 1, "C: ningún Aliento defendido: %s" % str(r["acciones"]))
	hechos.append("C: Aliento defendido")


# ================================================================= D. dos héroes

func _d() -> void:
	var gana := false
	var r := {}
	for i in 4:
		await _combate({"Kael": 10, "Lya": 10}, 20261112 + i * 17)
		r = await _jugar("jugador")
		print("D semilla %d: %s" % [20261112 + i * 17, _resumen(r)])
		_patron(r["acciones"], "D")
		_ok(r["fin"], "D: el combate no termina")
		await _cerrar()
		if r["gana"]:
			gana = true
			break
	_ok(gana, "D: con Kael y Lya a nivel 10 es imposible (4 semillas)")
	hechos.append("D: dos héroes " + ("ganan" if gana else "pierden"))


# ================================================================= E. derrota

func _e() -> void:
	await _combate({"Kael": 1, "Lya": 1}, 51)
	var reliquias0: int = Inv.cantidad(B.PREMIO)
	var r := await _jugar("auto", {"comprobar": true})
	print("E: %s" % _resumen(r))
	_ok(r["fin"] and not r["gana"], "E: a nivel 1 no pierde o no acaba")
	_ok(not Engine.get_meta("combates_ganados", {}).get(B.COMBATE, false), "E: perder lo apunta como ganado")
	_ok(Inv.cantidad(B.PREMIO) == reliquias0, "E: perder da premio")
	_ok(c.brama.cartel == null and c.brama.succion == null, "E: quedan avisos en pantalla tras la derrota")
	await _cerrar()
	hechos.append("E: derrota")


# ================================================================= F. automático, y G. detalles

func _f() -> void:
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, 61)
	var r := await _jugar("auto")
	print("F (automático): %s" % _resumen(r))
	_ok(r["fin"], "F: el combate automático no termina")
	_patron(r["acciones"], "F")
	hechos.append("F: automático, %s" % ("gana" if r["gana"] else "pierde"))
	await _cerrar()
	# G. el tambaleo y lo que se lee
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, 71)
	await _esperar(5)
	var k: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Kael")[0]
	var l: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Lya")[0]
	var g: Dictionary = c.heroes.filter(func(h): return h["nombre"] == "Garon")[0]
	c.estado = "accion"                                  # nadie actúa mientras se mira
	k["atb"] = 60.0
	l["atb"] = 60.0
	l["defendiendo"] = true
	g["atb"] = c.ATB_MAX
	if not c.cola.has(g):
		c.cola.append(g)
	c.brama._a_todos(c.heroes.filter(func(h): return h["hp"] > 0), 10, true)
	_ok(is_equal_approx(k["atb"], 60.0 - B.TAMBALEO), "G: Kael no se tambalea (%.1f)" % k["atb"])
	_ok(is_equal_approx(l["atb"], 60.0), "G: Lya defendiendo se tambalea (%.1f)" % l["atb"])
	_ok(is_equal_approx(g["atb"], c.ATB_MAX) and c.cola.count(g) == 1, "G: Garon, que esperaba turno, cambia (%.1f)" % g["atb"])
	z["cargando"] = true
	z["especial"] = "aliento"
	z["carga_recibido"] = 10
	_ok("⚠ Aliento: córtalo 10/%d" % c.brama.umbral_corte() in B.estados(z), "G: estados del Aliento: %s" % str(B.estados(z)))
	_ok(str(B.info(z)).contains("quítale"), "G: la lista no dice cómo cortarlo: %s" % str(B.info(z)))
	z["especial"] = "sismico"
	_ok(str(B.info(z)).contains("defendeos"), "G: la lista no dice cómo responder a la Fractura: %s" % str(B.info(z)))
	z["cargando"] = false
	await _cerrar()
	hechos.append("G: tambaleo y textos")


# ================================================================= medir el equilibrio

func _medir() -> void:
	for grupo in [{"Kael": 10, "Lya": 10, "Garon": 10}, {"Kael": 10, "Lya": 10}] if OS.get_cmdline_user_args().has("rapido") else [{"Kael": 10, "Lya": 10, "Garon": 10}, {"Kael": 10, "Lya": 10}, {"Kael": 9, "Lya": 9, "Garon": 9},
			{"Kael": 12, "Lya": 12, "Garon": 12}]:
		for est in ["jugador", "auto"]:
			var ganadas := 0
			for i in 5:
				await _combate(grupo, 900 + i * 11)
				var r := await _jugar(est, {"comprobar": true})
				if r["gana"]:
					ganadas += 1
				print("MEDIDA %s %s semilla %d: %s" % [str(grupo), est, 900 + i * 11, _resumen(r)])
				await _cerrar()
			print("MEDIDA %s %s: gana %d de 5" % [str(grupo), est, ganadas])
	hechos.append("medidas")


func _resumen(r: Dictionary) -> String:
	var medias := {}
	for k in r["danos"]:
		var l: Array = r["danos"][k]
		var s := 0
		for v in l:
			s += v
		medias[k] = "%d (%d-%d)" % [int(s / maxf(1, l.size())), l.min(), l.max()]
	return "%s en %.0f s, %d turnos de héroe, vida mínima %d %%, cortes %d, gusano %d/%d PV, acciones %s, daños %s, carga al soltar el Aliento %s, partículas a la vez como mucho %d" % [
		"GANA" if r["gana"] else "PIERDE", r["fotogramas"] / 30.0, r["turnos_heroe"], int(r["min_vida"] * 100), r["cortes"],
		z["hp"], z["hp_max"], str(r["acciones"]), str(medias), str(r.get("cargas", [])), c.brama.particulas_max if c.brama != null else -1]


func _sonido(n: String) -> int:
	return sonidos.filter(func(s): return s[0] == n).size()


# ================================================================= capturas (con ventana y «fotos=»)

func _conectar_fotos() -> void:
	zp.rompe_arena.connect(func(): _foto_en("entrada_rompe_arena", 6), CONNECT_ONE_SHOT)
	zp.impacto.connect(func(a):
		_foto_en("impacto_" + a, 4 if a != "aliento" else 6)
		_foto_en("impacto_" + a + "_despues", 14)
		if a != "embestida":                              # V12, Bramavidrio v2: el final del barrido y el polvo que se posa
			_foto_en("impacto_" + a + "_final", 21))
	zp.aviso.connect(func(a): _foto_en("aviso_" + a, 24 if a == "aliento" else 12))
	zp.caida.connect(func():
		_foto_en("derrota_caida", 6)
		_foto_en("victoria", 45))


func _foto_en(nombre: String, espera: int) -> void:
	await _esperar(espera)
	if c == null:
		return
	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return
	n_foto += 1
	img.save_png(fotos.path_join("%02d_%s.png" % [n_foto, nombre]))


var _fotos_hechas := {}


func _fotos_bucle() -> void:
	var t: String = c.registro.text
	for par in [["clava sus ocelos", "embestida_fija", 15], ["clava sus ocelos", "embestida_se_lanza", 27],
			["Kael ataca", "kael_ataca", 16], ["Garon ataca", "garon_ataca", 22],
			["Lya lanza", "lya_lanza", 30], ["se atraganta", "aliento_cortado", 6]]:
		if t.contains(par[0]) and int(_fotos_hechas.get(par[1], 0)) < 1:
			_fotos_hechas[par[1]] = 1
			_foto_en(par[1], par[2])


# ================================================================= pulido (12/11): orden sin parpadeos, salir y morir aspirando

# Cada fotograma de su turno: si el gusano pasa de detrás a delante de un héroe (o al revés), se cuenta. Al acabar el
# turno, _comprobar_turno pide como mucho dos cambios por héroe (delante al atacar y detrás al acabar): antes, con la
# v3, la Embestida hacía parpadear a Garon encima y debajo de la cabeza (pruebas/fotos_bramavidrio_pulido.gd).
func _contar_cambios_orden() -> void:
	if z == null or not z.has("rig") or not is_instance_valid(z["rig"]):
		return
	var rig: Node2D = z["rig"]
	for h in c.heroes:
		var hr: Node2D = h["rig"]
		var encima: bool = rig.z_index > hr.z_index or (rig.z_index == hr.z_index and rig.get_index() > hr.get_index())
		if encima_ant.has(h["nombre"]) and encima_ant[h["nombre"]] != encima:
			cambios_orden[h["nombre"]] = int(cambios_orden.get(h["nombre"], 0)) + 1
		encima_ant[h["nombre"]] = encima


# ¿Suena el bucle de la succión (y no se está apagando)?
func _bucle_suena() -> bool:
	for p in root.get_node("Sonido")._todas():
		if is_instance_valid(p) and p.playing and String(p.get_meta("efecto", "")) == B.BUCLE_SUCCION \
				and not p.get_meta("apagando", false):
			return true
	return false


# H. Se sale del combate a medias mientras aspira (el combate se cierra de golpe, como al volver a la portada): el bucle
#    de la succión, que sonaba, calla con el combate; no quedan nodos sueltos.
func _h() -> void:
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, 81)
	var r := await _jugar("jugador", {"vida": 0.5, "normales": 1, "defender_aliento": true, "hasta_aspirar": true,
		"comprobar": false})
	_ok(int(r.get("aspirando", 0)) >= 10, "H: no llega a aspirar: %s" % str(r["acciones"]))
	_ok(_bucle_suena(), "H: mientras aspira no suena el bucle de la succión")
	c.queue_free()
	c = null
	await _esperar(5)
	_ok(not _bucle_suena(), "H: cerrado el combate a medias, el bucle de la succión sigue sonando")
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(h <= huerfanos0, "H: cerrado a medias quedan %d nodos huérfanos (antes %d)" % [h, huerfanos0])
	hechos.append("H: salir aspirando")


# I. Muere mientras aspira el Aliento: el bucle calla, la arena deja de subir, los héroes se enderezan y no queda el
#    cartel; el combate acaba en victoria y se limpia.
func _i() -> void:
	await _combate({"Kael": 10, "Lya": 10, "Garon": 10}, 91)
	var r := await _jugar("auto", {"vida": 0.5, "normales": 1, "matar_aspirando": true, "comprobar": false})
	print("I: %s" % _resumen(r))
	_ok(r.get("bucle_al_matar", false), "I: el bucle de la succión no sonaba al dejarlo a 1 PV")
	_ok(r["gana"], "I: no muere")
	_ok(not _bucle_suena(), "I: muerto aspirando, el bucle de la succión sigue sonando")
	_ok(c.brama.succion == null and not c.brama._tirando and c.brama.cartel == null,
		"I: muerto aspirando quedan la succión (%s), los héroes inclinados (%s) o el cartel (%s)" % [
		c.brama.succion != null, c.brama._tirando, c.brama.cartel != null])
	_ok(not impactos.any(func(x): return x[0] == "aliento"), "I: muerto aspirando, suelta el Aliento")
	await _cerrar()
	hechos.append("I: muere aspirando")
