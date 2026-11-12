extends RefCounted
# V12, enemigos (12/11/2026): el Guardián de piedra, «el Centinela del Anillo», con su modelo propio y su forma de
# luchar. APAGADO: solo con el interruptor «enemigos_v12» (el mismo que pone los modelos propios de la fase C: combate.gd
# ENEMIGOS_V12). Encendido, el Guardián de los encuentros al azar de Pastos Verdes con el grupo de tres (GRUPOS[4], con
# un Grimfang: donde ya salía) deja la personalidad «jefe» y lucha con esta; y sus combates de prueba (GRUPOS[18] y
# [19], «-- grupo=18») sirven para 1, 2 y 3 héroes. Con el interruptor apagado no se llama nada de aquí que cambie el
# combate: Centinela.es() es falso para todos y el combate (y su huella, prueba_combate_huella) es el de siempre.
# Modelo y clips: enemigos/guardian_piedra/ (guardian_piedra_v2.glb; guion fuente/crear_guardian_piedra.py «v2»).
# Informe: docs/memory/agents/combate_v12_enemigos.md.
#
# Papel: élite de Pastos Verdes (la estatua del templo que despierta), lento y duro. Sus vida, ataque, premios y
# escalado por región son los de ENEMIGOS["guardian"] (sin tocar). Cuatro acciones, cada una con preparación,
# ejecución, impacto y recuperación, y cada una con su respuesta en lo que el jugador ya tiene:
#   · Tajo (a uno, ×1,0): alza el mandoble sobre el hombro y corta en diagonal. Va a por la curandera si ha curado.
#   · Barrido del Anillo (a todos, ×0,9): tensa el mandoble a su derecha (la preparación se ve: el anillo gira deprisa
#     y la runa se enciende) y barre a ras de cintura. Defender lo deja a la mitad. Nunca dos seguidos.
#   · Juicio del Anillo (aviso un turno): alza el mandoble y el anillo; sale «⚠ ¡Juicio!» sobre él y una marca sobre el
#     héroe elegido. Su turno siguiente lo clava contra ese héroe (×2,2) y las lascas alcanzan a los demás (×0,6).
#     Respuestas: DEFENDER (a la mitad), la GUARDIA de Garon (se lo lleva él), o CORTARLO: si mientras carga le quitáis
#     un cuarto de su vida (combate.gd UMBRAL_INTERRUPCION, la regla de la V11) o con Quiebra, pierde el equilibrio,
#     se queda aturdido y pierde su turno siguiente.
#   · Escudo del Anillo (con menos del 60 % de vida): el anillo baja delante del pecho. Hasta su turno siguiente los
#     golpes le hacen la mitad (la «defensa» de siempre, f["defendiendo"]), pero LA MAGIA LO ROMPE: queda aturdido y
#     pierde el turno (como la guardia del Slime). Si nadie lo rompe, su turno siguiente suelta el anillo con un Barrido.
# Sonido (sonido.gd, claves «guardian_*» y «centinela_*», WAV de audio/efectos/centinela/; procedencia en
# docs/audio/efectos_procedencia.csv): cada uno una vez y en su instante (el barrido y el Juicio, en el impacto del
# clip por la señal «impacto» que ya escucha combate.gd _sonidos_bestia; la tensión, el escudo y el derrumbe, por la
# señal «evento» del clip; el aviso y la rotura, aquí). El golpe en sí suena como siempre (Sonido.golpe, una vez).

const CLAVE := "guardian"
const PERSONALIDAD := "centinela"
const INTERRUPTOR := "enemigos_v12"
const ACTIVO_POR_DEFECTO := false
# combate.gd GRUPOS: sus combates de prueba (no salen al azar)
const GRUPO_SOLO := 18
const GRUPO_CON_SLIME := 19
const MULT_TAJO := 1.0
const MULT_BARRIDO := 0.9
const MULT_JUICIO := 2.2
const MULT_LASCAS := 0.6
const PROB_JUICIO := 0.35
const PROB_ESCUDO := 0.4
const PROB_BARRIDO := 0.4
const VIDA_ESCUDO := 0.6                  # el escudo, solo por debajo de esta parte de su vida
const ESPERA_ESCUDO := 4                  # turnos suyos entre un escudo y el siguiente
const GOLPE_PESADO := 0.12                # un golpe de esta parte de su vida (o más) le hace tambalearse de verdad
const COLOR_ANILLO := Color(0.30, 0.95, 0.85)   # el verde agua de su rendija y su anillo (guardian_piedra_3d.gd)
const COLOR_PIEDRA := Color(0.80, 0.77, 0.69)
const SONIDOS := {"carga": "centinela_carga", "escudo": "centinela_escudo", "rota": "centinela_rota",
	"tension": "centinela_tension", "derrumbe": "centinela_derrumbe"}


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


# combate.gd _elegir_enemigos, dentro del interruptor de los modelos propios: el Guardián lucha con esta personalidad.
static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD


static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("cn_contador"):
		f["cn_contador"] = {}
	f["cn_contador"][k] = int(f["cn_contador"].get(k, 0)) + 1


# combate.gd, al empezar (con su clip de entrada): los sonidos de los instantes con nombre de sus clips.
static func al_entrar(c, e: Dictionary, p) -> void:
	if not es(e) or p == null or not p.has_signal("evento") or e.get("cn_conectado", false):
		return
	e["cn_conectado"] = true
	p.evento.connect(_al_evento.bind(c, e))


static func _al_evento(clip: String, nombre: String, c, e: Dictionary) -> void:
	if nombre == "tension":
		c._sonar(SONIDOS["tension"])
		_chispas_anillo(c, e)
	elif nombre == "escudo":
		c._sonar(SONIDOS["escudo"])
	elif nombre == "suelo" and clip == "derrota":
		c._sonar(SONIDOS["derrumbe"])
		_polvo(c, e)


# ================================================================= lo que se lee

static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("cn_escudo", false):
		r.append("Escudo del Anillo")
	var o = e.get("cn_objetivo", null)
	if e.get("cargando", false) and o is Dictionary and int(o.get("hp", 0)) > 0:
		r.append("⚠ Juicio: %s" % o["nombre"])
	if e.get("cn_aturdido", false):
		r.append("Aturdido")
	return r


static func info(e: Dictionary) -> Array:
	if e.get("cn_escudo", false):
		return ["Escudo del Anillo: golpes a la mitad; la magia lo rompe"]
	if e.get("cargando", false):
		return ["⚠ Prepara el Juicio: defiéndete o dale fuerte y lo cortas"]
	if e.get("cn_aturdido", false):
		return ["Aturdido: pierde su turno"]
	return []


# ================================================================= su turno (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["cn_turno"] = int(f.get("cn_turno", 0)) + 1
	if f.get("recupera", false):                         # tras perder la carga o el escudo: aturdido, pierde el turno
		await _recuperar(c, f)
		return
	if f.get("cn_escudo", false):                        # nadie lo rompió: suelta el anillo con un barrido
		_quitar_escudo(c, f)
		await _barrido(c, f, vivos, mult, true)
		return
	if f.get("cargando", false):
		await _juicio(c, f, vivos, mult)
		return
	var ultimo := str(f.get("cn_ultimo", ""))
	var desde_juicio: int = f["cn_turno"] - int(f.get("cn_turno_juicio", -10))
	var desde_escudo: int = f["cn_turno"] - int(f.get("cn_turno_escudo", -10))
	var pj: float = PROB_JUICIO + (c.ELITE["prob_patron"] if f.get("elite", false) else 0.0)
	if desde_juicio > 2 and randf() < pj:
		await _anunciar_juicio(c, f, vivos)
	elif f["hp"] < f["hp_max"] * VIDA_ESCUDO and desde_escudo > ESPERA_ESCUDO and randf() < PROB_ESCUDO:
		await _escudo(c, f)
	elif vivos.size() >= 2 and ultimo != "barrido" and randf() < PROB_BARRIDO:
		await _barrido(c, f, vivos, mult, false)
	else:
		await _tajo(c, f, vivos, mult)


static func _tajo(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("jefe", vivos))
	c.registro.text = "%s alza el mandoble contra %s" % [f["nombre"], obj["nombre"]]
	f["cn_ataque"] = "tajo"
	f["cn_resto"] = []
	_contar(f, "tajo")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_TAJO * mult) + randi_range(-2, 3), "")
	f.erase("cn_ataque")
	f["cn_ultimo"] = "tajo"


static func _barrido(c, f: Dictionary, vivos: Array, mult: float, tras_escudo: bool) -> void:
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	var dano := int(f["atk"] * MULT_BARRIDO * mult)
	var principal: Dictionary = c._cubre(vivos[int(vivos.size() / 2.0)], false)   # el del medio: el barrido pasa por todos
	var resto: Array = []
	for h0 in vivos:
		if not is_same(h0, principal):
			resto.append(h0)
	c.registro.text = ("¡%s suelta el anillo y barre a todo el grupo!" if tras_escudo else
		"¡%s tensa el mandoble: barrido a todo el grupo!") % f["nombre"]
	c._numero_flotante(f, "¡Barrido!", Color(1.0, 0.8, 0.2), 30)
	f["cn_ataque"] = "barrido"
	f["cn_resto"] = resto
	f["cn_dano_resto"] = dano
	_contar(f, "barrido")
	await c._animar_golpe(f, principal, dano + randi_range(-2, 2), "")
	f.erase("cn_ataque")
	f["cn_resto"] = []
	f["cn_ultimo"] = "barrido"


static func _anunciar_juicio(c, f: Dictionary, vivos: Array) -> void:
	var obj: Dictionary = c._elegir_objetivo("jefe", vivos)
	f["cargando"] = true
	f["carga_recibido"] = 0
	f["cn_objetivo"] = obj
	f["cn_turno_juicio"] = int(f.get("cn_turno", 0))
	_contar(f, "aviso_juicio")
	c._marcar_aviso(f, true)                             # la señal de aviso sobre él (la de siempre), hasta que golpea
	_marcar(c, f, obj)                                   # y una marca sobre el héroe elegido
	var p = c._p3d(f)
	if p != null and p.has_method("cargar"):
		p.cargar()
	c._sonar(SONIDOS["carga"])
	c.registro.text = "%s alza el mandoble y el anillo: ¡prepara el Juicio contra %s!" % [f["nombre"], obj["nombre"]]
	c._numero_flotante(f, "⚠ ¡Juicio!", Color(1.0, 0.8, 0.2), 34)
	c._numero_flotante(obj, "⚠ Juicio", COLOR_ANILLO, 28)
	_chispas_anillo(c, f)
	c._actualizar()
	await c.get_tree().create_timer(1.2).timeout
	f["cn_ultimo"] = "aviso"


static func _juicio(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["cargando"] = false
	f.erase("carga_recibido")
	c._marcar_aviso(f, false)
	var obj = f.get("cn_objetivo", null)
	if not (obj is Dictionary) or int(obj["hp"]) <= 0:
		obj = c._elegir_objetivo("jefe", vivos)
	obj = c._cubre(obj)                                  # la Guardia de Garon: se lo lleva él
	_marcar(c, f, null)
	f.erase("cn_objetivo")
	var resto: Array = []
	for h0 in vivos:
		if not is_same(h0, obj) and h0["hp"] > 0:
			resto.append(h0)
	c.registro.text = "¡%s descarga el Juicio del Anillo sobre %s!" % [f["nombre"], obj["nombre"]]
	f["cn_ataque"] = "juicio"
	f["cn_resto"] = resto
	f["cn_dano_resto"] = int(f["atk"] * MULT_LASCAS * mult)
	_contar(f, "juicio")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_JUICIO * mult) + randi_range(-2, 3), "")
	f.erase("cn_ataque")
	f["cn_resto"] = []
	f["cn_ultimo"] = "juicio"


static func _escudo(c, f: Dictionary) -> void:
	f["cn_escudo"] = true
	f["defendiendo"] = true                              # la defensa de siempre: los golpes a la mitad (_animar_golpe)
	f["cn_turno_escudo"] = int(f.get("cn_turno", 0))
	_contar(f, "escudo")
	c.registro.text = "%s baja su anillo como un escudo. ¡La magia lo puede romper!" % f["nombre"]
	c._numero_flotante(f, "Escudo del Anillo", COLOR_ANILLO, 30)
	var p = c._p3d(f)
	f["animando"] = true
	if p != null and p.has_method("guardia"):
		p.guardia()
		await c.get_tree().create_timer(0.55).timeout     # el instante «escudo» del clip (suena por la señal evento)
	else:
		c._sonar(SONIDOS["escudo"])
	f["animando"] = false
	if f["hp"] > 0:
		c._onda(c._centro(f) + Vector2(0, 40), COLOR_ANILLO, 40.0, 150.0, 0.6, 6.0)
		c._particulas(c._centro(f), Color(COLOR_ANILLO, 0.9), Color(COLOR_ANILLO, 0.0), 18, 0.7, Vector2(30, 90), 60.0,
			Vector2(0, -1), 180.0, Vector2(0, -40), 0.12)
	c._actualizar()
	await c.get_tree().create_timer(0.6).timeout
	f["cn_ultimo"] = "escudo"


static func _quitar_escudo(c, f: Dictionary) -> void:
	f["cn_escudo"] = false
	f["defendiendo"] = false
	var p = c._p3d(f)
	if p != null and p.has_method("fin_guardia"):
		p.fin_guardia()
	c._actualizar()


static func _recuperar(c, f: Dictionary) -> void:
	f["recupera"] = false
	f["cn_aturdido"] = false
	f.erase("aturdido")
	_contar(f, "recupera")
	c.registro.text = "%s, aturdido, recompone la piedra" % f["nombre"]
	var p = c._p3d(f)
	if p != null:
		p.reposo()
	c._numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
	c._actualizar()
	await c.get_tree().create_timer(0.8).timeout
	f["cn_ultimo"] = "recupera"


# ================================================================= el golpe recibido (combate.gd _vigilar_carga)

# Se llama con cada golpe que le quita vida (después de quitársela, antes de dibujarlo): rompe el escudo con magia,
# corta el Juicio y elige el clip de herida (ligero o fuerte).
static func vigilar(c, f: Dictionary, d: int) -> void:
	var p = c._p3d(f)
	if p != null and "golpe_pesado" in p:
		p.golpe_pesado = d >= ceili(f["hp_max"] * GOLPE_PESADO)
	if f["hp"] <= 0:
		return
	if f.get("cn_escudo", false) and c.golpe_magico:
		f["cn_escudo"] = false
		f["defendiendo"] = false
		_aturdir(c, f, "¡Escudo roto!", "¡La magia rompe el escudo de %s! Pierde su turno." % f["nombre"])
		_contar(f, "escudo_roto")
		return
	if not f.get("cargando", false):
		return
	if c.golpe_ruptura:
		_aturdir(c, f, "¡Quiebra!", "¡Kael y Garon rompen el Juicio de %s!" % f["nombre"])
		_contar(f, "juicio_cortado")
		return
	f["carga_recibido"] = int(f.get("carga_recibido", 0)) + d
	if f["carga_recibido"] >= ceili(f["hp_max"] * c.UMBRAL_INTERRUPCION):
		_aturdir(c, f, "¡Interrumpido!", "¡%s pierde el equilibrio y no suelta el Juicio!" % f["nombre"])
		_contar(f, "juicio_cortado")


static func _aturdir(c, f: Dictionary, cartel: String, texto: String) -> void:
	f["cargando"] = false
	f["recupera"] = true
	f["aturdido"] = true
	f["cn_aturdido"] = true
	f.erase("carga_recibido")
	f.erase("cn_objetivo")
	c._marcar_aviso(f, false)
	_marcar(c, f, null)
	var p = c._p3d(f)
	if p != null and p.has_method("aturdido"):
		p.aturdido()
	c._sonar(SONIDOS["rota"])
	c._numero_flotante(f, cartel, Color(1.0, 0.92, 0.45), 36, Vector2(0, -60))
	c.registro.text = texto
	c._particulas(c._centro(f) + Vector2(0, -60), Color(COLOR_PIEDRA, 0.95), Color(COLOR_PIEDRA, 0.0), 14, 0.8,
		Vector2(60, 180), 40.0, Vector2(0, -1), 70.0, Vector2(0, 420), 0.12)
	c._temblor(4.0)
	c._actualizar()


# ================================================================= animación (combate.gd _animar_golpe)

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var ataque := str(o.get("cn_ataque", "tajo"))
	var hecho := [false]
	# el impacto del clip: el golpe al principal (su sonido, una vez) y, en el MISMO instante, a los demás
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
		_golpear_resto(c, o, obj, ataque)
	var p = c._p3d(o)
	if p == null:                                          # el respaldo 2D (sin su modelo): su animación de siempre
		if c._es_sprite(o):
			await c._anim_fisico_sprite(o, obj, golpe)
		elif c.MODELOS[o["modelo"]].get("tipo", "") == "imagen":
			await c._anim_fisico_imagen(o, obj, golpe)
		else:
			golpe.call()
			await c.get_tree().create_timer(0.5).timeout
	else:
		await _ir_y_golpear(c, o, obj, golpe, ataque)
	if not hecho[0]:
		golpe.call()


static func _golpear_resto(c, o: Dictionary, obj: Dictionary, ataque: String) -> void:
	match ataque:
		"barrido":
			_tajo_arco(c, o, obj)
			c._temblor(7.0)
		"juicio":
			c._onda(c._suelo_de(obj), COLOR_ANILLO, 30.0, 260.0, 0.7, 10.0)
			c._particulas(c._suelo_de(obj) + Vector2(0, -20), Color(COLOR_PIEDRA, 1.0), Color(0.6, 0.58, 0.52, 0.0), 22,
				0.9, Vector2(120, 320), 50.0, Vector2(0, -1), 60.0, Vector2(0, 700), 0.16)
			c._destello(c._centro(obj), COLOR_ANILLO, 1.2)
	var resto: Array = o.get("cn_resto", [])
	if resto.is_empty():
		return
	var dano := int(o.get("cn_dano_resto", 0))
	for h0 in resto:
		if h0["hp"] <= 0:
			continue
		var h: Dictionary = c._cubre(h0, false)            # quien cubre Garon: el golpe se lo lleva él
		if h["hp"] <= 0:
			continue
		var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
		if h.get("defendiendo", false):
			d2 = maxi(1, int(d2 * 0.5))
		c._golpe_visual(h, c._quitar_pv(h, d2), "")


# Corre hasta el héroe, el clip con su impacto y vuelve (como combate.gd _anim_ataque_3d, con el barrido).
static func _ir_y_golpear(c, o: Dictionary, obj: Dictionary, golpe: Callable, ataque: String) -> void:
	var p = c._p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var hueco: float = c.ANIM[o["modelo"]].get("distancia", 120.0) + c.ANIM[obj["modelo"]].get("distancia", 120.0) * 0.4
	var destino := base + Vector2(c._centro(obj).x - hueco - c._centro(o).x, (c._pos_ataque(obj).y - o["pos"].y) * 0.8)
	if obj.has("centro_ofs") and o.has("centro_ofs"):
		destino.y = base.y + (c._suelo_de(obj).y - c._suelo_de(o).y)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.15)
	p.correr()
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	Sonido.voz(o, "ataque")
	var al_golpear := func():
		golpe.call()
		if ataque == "juicio":
			c._temblor(10.0)
	match ataque:
		"barrido":
			if p.has_method("barrido"):
				await p.barrido(al_golpear)
			else:
				await p.atacar_hacha(al_golpear)
		"juicio":
			await p.golpe_fuerte(al_golpear)
		_:
			await p.atacar_hacha(al_golpear)
	golpe.call()                                           # (sin el clip, o cortado: el golpe igualmente, una vez)
	if o["hp"] > 0:
		p.mirar(-ida, 0.2)
		p.correr()
		var t3: Tween = c.create_tween()
		t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t3.finished
		p.mirar_frente(0.25)
		if o.get("recupera", false) and p.has_method("aturdido"):
			p.aturdido()
		else:
			p.reposo()
	rig.z_index = 0
	o["animando"] = false


# ================================================================= efectos (2D, con presupuesto: pocos nodos y cortos)

# El filo del barrido: un arco blanco verdoso que cruza a todo el grupo y se apaga en 0,3 s.
static func _tajo_arco(c, o: Dictionary, obj: Dictionary) -> void:
	var xs: Array = [c._centro(obj).x]
	for h in o.get("cn_resto", []):
		xs.append(c._centro(h).x)
	var x0: float = xs.min() - 90.0
	var x1: float = xs.max() + 90.0
	var y: float = c._centro(obj).y + 20.0
	var n := Node2D.new()
	n.material = c.mat_aditivo
	n.z_index = 6
	c.escena.add_child(n)
	var est := {"t": 0.0}
	n.draw.connect(func():
		var k: float = est["t"]
		var pts := PackedVector2Array()
		for i in 17:
			var u := i / 16.0
			pts.append(Vector2(lerpf(x0, x1, u), y - sin(u * PI) * 70.0))
		var a := 1.0 - k
		n.draw_polyline(pts, Color(COLOR_ANILLO, 0.55 * a), 26.0 * (1.0 - 0.5 * k), true)
		n.draw_polyline(pts, Color(1, 1, 1, 0.9 * a), 7.0, true))
	var t: Tween = c.create_tween()
	t.tween_method(func(v: float):
		est["t"] = v
		n.queue_redraw(), 0.0, 1.0, 0.3)
	t.tween_callback(n.queue_free)


static func _chispas_anillo(c, f: Dictionary) -> void:
	if not f.has("rig") or f["hp"] <= 0:
		return
	c._particulas(c._centro(f) + Vector2(0, -80), Color(COLOR_ANILLO, 0.95), Color(COLOR_ANILLO, 0.0), 16, 0.8,
		Vector2(20, 70), 50.0, Vector2(0, -1), 180.0, Vector2(0, -30), 0.1)


static func _polvo(c, f: Dictionary) -> void:
	if not f.has("rig"):
		return
	c._particulas(c._suelo_de(f), Color(0.78, 0.74, 0.64, 0.8), Color(0.7, 0.66, 0.58, 0.0), 20, 1.2, Vector2(40, 140),
		70.0, Vector2(0, -1), 80.0, Vector2(0, 60), 0.2)
	c._temblor(6.0)


# ================================================================= la marca sobre el héroe elegido

static func _marcar(c, f: Dictionary, obj) -> void:
	var antes = f.get("cn_marca", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("cn_marca")
	if obj == null:
		return
	var s = c._sena_arte("aviso", obj, {"dur": 9999.0, "color": COLOR_ANILLO})
	s.position = c._centro(obj) + Vector2(0, -150)
	f["cn_marca"] = s


# combate.gd _actualizar: si cae él o el héroe marcado, la marca fuera.
static func repasar(f: Dictionary) -> void:
	var m = f.get("cn_marca", null)
	if m == null:
		return
	var o = f.get("cn_objetivo", null)
	if int(f["hp"]) <= 0 or not (o is Dictionary) or int(o.get("hp", 0)) <= 0:
		if is_instance_valid(m):
			m.queue_free()
		f.erase("cn_marca")


# combate.gd _comprobar_fin: al acabar (victoria, derrota o huida), su marca fuera.
static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if not es(e):
			continue
		var n = e.get("cn_marca", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
		e.erase("cn_marca")


static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		var n = e.get("cn_marca", null)
		if es(e) and n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:cn_marca" % e["nombre"])
	return r
