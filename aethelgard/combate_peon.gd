extends RefCounted
# V12, bestiario de producción (13/11/2026): e01 · el Peón de Linde, hostigador común de Pastos Verdes y los caminos.
# APAGADO: solo con el interruptor «enemigos_v12» (el de los modelos propios de la fase C: combate.gd ENEMIGOS_V12).
# Encendido: sale en los encuentros al azar de Pastos Verdes (llanura) con una probabilidad PROB_AL_AZAR, en el grupo de
# su tamaño (1, 2 o 3 héroes: GRUPOS[22], [23] o [24]), y lucha con esta personalidad. Esos grupos son también sus
# combates de prueba («-- grupo=22 enemigos_v12»). Apagado, Peon.es() es falso para todos, nadie elige esos grupos y el
# combate es el de siempre (la huella no cambia).
# Modelo y clips: enemigos/peon_linde/ (peon_linde.glb; guion fuente/crear_peon_linde.py). Diseño y conversión al ATB:
# docs/v12/BESTIARIO_V12.md. Informe: docs/memory/agents/combate_v12_bestiario.md.
#
# Papel (ficha e01 del bestiario): hostigador ágil y frágil. Vida, ataque, premios y escalado, los de
# ENEMIGOS["peon_linde"] y combate_escalado.gd (región «llanura»), sin fórmulas nuevas. Tres ataques adaptados al ATB,
# cada uno con su aviso, su impacto (UNA vez, en el instante del clip) y su recuperación:
#   · A1 Piquete cruzado (peso 50; a uno, ×1,0): cruza las estacas ante la máscara y las abre en diagonal. Aviso dentro del
#     clip (0,55 s). Contra: Defender.
#   · A2 Estaca de aviso (peso 30; a uno, a distancia, ×0,85): desde su sitio, rodilla en tierra, lanza la estaca derecha a
#     la retaguardia (la curandera si ha curado; si no, quien menos vida tenga). El daño cae AL LLEGAR. Nunca dos seguidos
#     (la réplica tarda un turno en «volver»). Contra: Defender (mitad), la Guardia de Garon (se la lleva él).
#   · A3 Zancada de lindero (peso 20; EN FILA, ×1,3 al marcado y ×0,5 al de detrás): el aviso de 0,9 s es un TURNO de
#     preparación («⚠ Zancada» sobre él y una marca sobre el héroe elegido). El turno siguiente avanza con una estocada:
#     los dos en el mismo instante del impacto, y RETROCESO (el empuje de 0,4 m): quien la recibe sin defender pierde
#     RETROCESO_ATB de su barra ATB (nunca quien ya tiene su turno en la cola). Se corta como en la V11: un cuarto de su
#     vida mientras se prepara, o Quiebra → aturdido, pierde el turno, y no vuelve a prepararla en su turno siguiente
#     («consume medio CD»). Nunca dos seguidas. Contra: Defender (mitad y sin retroceso), Guardia, cortarla.
# Ritmo (ficha: «máximo dos ataques seguidos antes de una pausa»): tras dos ataques seguidos, su turno siguiente SE
# REPLIEGA (retroceso, sin atacar; la ventana para castigarle) y busca flanco: su ataque siguiente va a la retaguardia.
# Golpes grandes (≥ GOLPE_PESADO de su vida) ponen la herida fuerte. Sonido (sonido.gd, «peon_linde_*» y «peon_*»): cada
# uno una vez y en su instante.

const CLAVE := "peon_linde"
const PERSONALIDAD := "peon_linde"
const INTERRUPTOR := "enemigos_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_POR_TAMANO := {1: 22, 2: 23, 3: 24}   # combate.gd GRUPOS: sus encuentros (y combates de prueba)
const ZONA := "llanura"                            # Pastos Verdes
const PROB_AL_AZAR := 0.25                         # con el interruptor: uno de cada cuatro encuentros de la llanura
const PESOS := {"piquete": 50.0, "estaca": 30.0, "zancada": 20.0}
const MULT_PIQUETE := 1.0
const MULT_ESTACA := 0.85
const MULT_ZANCADA := 1.3
const MULT_FILA := 0.5
const RETROCESO_ATB := 0.15                        # fracción de ATB_MAX que pierde quien recibe la Zancada sin defender
const RACHA_MAX := 2
const GOLPE_PESADO := 0.12
const VUELO_S := 0.30                              # lo que tarda la estaca en llegar
const COLOR_OCRE := Color(0.86, 0.56, 0.24)
const COLOR_POLVO := Color(0.74, 0.64, 0.48)
const COLOR_MARCA := Color(0.95, 0.72, 0.36)
const SONIDOS := {"estaca": "peon_estaca", "carga": "peon_carga", "rota": "peon_rota", "derrumbe": "peon_derrumbe"}


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD


static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


# combate.gd grupo_al_azar: con el interruptor, en la llanura, a veces su grupo; si no, -1 (y no tira ningún dado: el
# azar de siempre no cambia con el interruptor apagado).
static func grupo_al_azar(cuantos: int) -> int:
	if not activo() or str(Engine.get_meta("zona", "llanura")) != ZONA:
		return -1
	if randf() >= PROB_AL_AZAR:
		return -1
	return int(GRUPOS_POR_TAMANO.get(clampi(cuantos, 1, 3), 22))


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("pl_contador"):
		f["pl_contador"] = {}
	f["pl_contador"][k] = int(f["pl_contador"].get(k, 0)) + 1


static func al_entrar(c, e: Dictionary, p) -> void:
	if not es(e) or p == null or not p.has_signal("evento") or e.get("pl_conectado", false):
		return
	e["pl_conectado"] = true
	p.evento.connect(_al_evento.bind(c, e))


static func _al_evento(clip: String, nombre: String, c, e: Dictionary) -> void:
	if nombre == "suelo" and clip == "derrota":
		c._sonar(SONIDOS["derrumbe"])
		c._particulas(c._suelo_de(e), Color(COLOR_POLVO, 0.85), Color(COLOR_POLVO, 0.0), 16, 1.0, Vector2(40, 120), 70.0,
			Vector2(0, -1), 80.0, Vector2(0, 60), 0.16)
		c._temblor(3.0)
	elif nombre == "pisada" and clip == "zancada":
		c._particulas(c._suelo_de(e) + Vector2(60, 0), Color(COLOR_POLVO, 0.9), Color(COLOR_POLVO, 0.0), 12, 0.6,
			Vector2(40, 140), 40.0, Vector2(0, -1), 60.0, Vector2(0, 160), 0.12)


# ================================================================= lo que se lee

static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	var o = e.get("pl_objetivo", null)
	if e.get("cargando", false) and o is Dictionary and int(o.get("hp", 0)) > 0:
		r.append("⚠ Zancada: %s" % o["nombre"])
	if e.get("pl_aturdido", false):
		r.append("Aturdido")
	elif e.get("pl_replegado", false):
		r.append("Busca flanco")
	return r


static func info(e: Dictionary) -> Array:
	if e.get("cargando", false):
		return ["⚠ Prepara la Zancada en fila: defiéndete o dale fuerte y la cortas"]
	if e.get("pl_aturdido", false):
		return ["Aturdido: pierde su turno"]
	if e.get("pl_replegado", false):
		return ["Se ha replegado: su próximo golpe irá a la retaguardia"]
	return []


# ================================================================= su turno (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["pl_turno"] = int(f.get("pl_turno", 0)) + 1
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	if f.get("recupera", false):                          # la Zancada cortada: aturdido, pierde el turno
		await _recuperar(c, f)
		return
	if f.get("cargando", false):
		await _zancada(c, f, vivos, mult)
		return
	if int(f.get("pl_racha", 0)) >= RACHA_MAX:
		await _replegarse(c, f)
		return
	var ataque := _elegir(f)
	match ataque:
		"zancada":
			await _avisar(c, f, vivos)
		"estaca":
			await _estaca(c, f, vivos, mult)
		_:
			await _piquete(c, f, vivos, mult)


# Pesos 50/30/20 entre los ataques posibles: la Estaca y la Zancada no se repiten seguidas, y la Zancada no vuelve a
# prepararse en el turno siguiente a cortársela (medio CD).
static func _elegir(f: Dictionary) -> String:
	var ultimo := str(f.get("pl_ultimo", ""))
	var pesos := PESOS.duplicate()
	if ultimo == "estaca":
		pesos.erase("estaca")
	if ultimo in ["zancada", "aviso"] or int(f.get("pl_turno", 0)) - int(f.get("pl_corte_turno", -10)) <= 1:
		pesos.erase("zancada")
	var total := 0.0
	for k in pesos:
		total += float(pesos[k])
	var r := randf() * total
	for k in ["piquete", "estaca", "zancada"]:
		if not pesos.has(k):
			continue
		r -= float(pesos[k])
		if r < 0.0:
			return k
	return "piquete"


static func _objetivo(c, f: Dictionary, vivos: Array) -> Dictionary:
	var flanco: bool = f.get("pl_replegado", false)
	f["pl_replegado"] = false
	return c._elegir_objetivo("agresivo" if flanco else "bruto", vivos)


static func _piquete(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(_objetivo(c, f, vivos))
	c.registro.text = "%s cruza sus estacas contra %s" % [f["nombre"], obj["nombre"]]
	f["pl_ataque"] = "piquete"
	f["pl_resto"] = []
	_contar(f, "piquete")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_PIQUETE * mult) + randi_range(-2, 2), "")
	f.erase("pl_ataque")
	_tras_ataque(f, "piquete")


static func _estaca(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["pl_replegado"] = false
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))   # la retaguardia: la curandera o el más débil
	c.registro.text = "%s hinca la rodilla y lanza una estaca contra %s" % [f["nombre"], obj["nombre"]]
	c._numero_flotante(f, "¡Estaca!", COLOR_OCRE, 30)
	f["pl_ataque"] = "estaca"
	f["pl_resto"] = []
	_contar(f, "estaca")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_ESTACA * mult) + randi_range(-2, 2), "")
	f.erase("pl_ataque")
	_tras_ataque(f, "estaca")


static func _tras_ataque(f: Dictionary, cual: String) -> void:
	f["pl_ultimo"] = cual
	f["pl_racha"] = int(f.get("pl_racha", 0)) + 1


static func _avisar(c, f: Dictionary, vivos: Array) -> void:
	var obj: Dictionary = c._elegir_objetivo("agresivo", vivos)
	f["cargando"] = true
	f["carga_recibido"] = 0
	f["pl_objetivo"] = obj
	f["pl_racha"] = 0
	_contar(f, "aviso_zancada")
	c._marcar_aviso(f, true)                              # la señal de aviso de siempre sobre él, hasta que golpea
	_marcar(c, f, obj)                                    # y una marca sobre el héroe elegido
	var p = c._p3d(f)
	if p != null and p.has_method("cargar"):
		p.cargar()
	c._sonar(SONIDOS["carga"])
	c.registro.text = "%s alza la rodilla y echa atrás las estacas: ¡Zancada contra %s y quien vaya detrás!" % [
		f["nombre"], obj["nombre"]]
	c._numero_flotante(f, "⚠ ¡Zancada!", Color(1.0, 0.8, 0.2), 34)
	c._numero_flotante(obj, "⚠ Zancada", COLOR_MARCA, 28)
	c._actualizar()
	await c.get_tree().create_timer(1.2).timeout
	f["pl_ultimo"] = "aviso"


# El de detrás en la fila: el siguiente héroe vivo de la formación (si no hay, el anterior).
static func vecino(c, obj: Dictionary) -> Dictionary:
	var lista: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var i := -1
	for k in lista.size():
		if is_same(lista[k], obj):
			i = k
	if i < 0 or lista.size() < 2:
		return {}
	return lista[i + 1] if i + 1 < lista.size() else lista[i - 1]


static func _zancada(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["cargando"] = false
	f.erase("carga_recibido")
	c._marcar_aviso(f, false)
	var marcado = f.get("pl_objetivo", null)
	if not (marcado is Dictionary) or int(marcado["hp"]) <= 0:
		marcado = c._elegir_objetivo("agresivo", vivos)
	_marcar(c, f, null)
	f.erase("pl_objetivo")
	var obj: Dictionary = c._cubre(marcado)               # la Guardia de Garon: el golpe principal se lo lleva él
	var detras := vecino(c, marcado)
	if not detras.is_empty() and is_same(detras, obj):    # (Garon cubre al marcado y era el de detrás: el otro lado)
		detras = vecino(c, obj)
		if not detras.is_empty() and is_same(detras, marcado):
			detras = {}
	c.registro.text = "¡%s avanza de una zancada y ensarta a %s%s!" % [f["nombre"], obj["nombre"],
		(" y a %s" % detras["nombre"]) if not detras.is_empty() else ""]
	f["pl_ataque"] = "zancada"
	f["pl_resto"] = [] if detras.is_empty() else [detras]
	f["pl_dano_resto"] = int(f["atk"] * MULT_FILA * mult)
	_contar(f, "zancada")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_ZANCADA * mult) + randi_range(-2, 3), "")
	f.erase("pl_ataque")
	f["pl_resto"] = []
	f["pl_ultimo"] = "zancada"
	f["pl_racha"] = int(f.get("pl_racha", 0)) + 1


static func _replegarse(c, f: Dictionary) -> void:
	f["pl_racha"] = 0
	f["pl_replegado"] = true
	_contar(f, "repliegue")
	c.registro.text = "%s se repliega y busca un flanco" % f["nombre"]
	c._numero_flotante(f, "Se repliega", Color(0.8, 0.85, 0.75), 28)
	var p = c._p3d(f)
	if p != null and p.has_method("retroceder"):
		f["animando"] = true
		await p.retroceder()
		f["animando"] = false
	else:
		await c.get_tree().create_timer(0.65).timeout
	c._actualizar()
	await c.get_tree().create_timer(0.3).timeout
	f["pl_ultimo"] = "repliegue"


static func _recuperar(c, f: Dictionary) -> void:
	f["recupera"] = false
	f["pl_aturdido"] = false
	f["pl_racha"] = 0
	f.erase("aturdido")
	_contar(f, "recupera")
	c.registro.text = "%s, aturdido, se sacude el barro" % f["nombre"]
	var p = c._p3d(f)
	if p != null:
		p.reposo()
	c._numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
	c._actualizar()
	await c.get_tree().create_timer(0.8).timeout
	f["pl_ultimo"] = "recupera"


# ================================================================= el golpe recibido (combate.gd _vigilar_carga)

static func vigilar(c, f: Dictionary, d: int) -> void:
	var p = c._p3d(f)
	if p != null and "golpe_pesado" in p:
		p.golpe_pesado = d >= ceili(f["hp_max"] * GOLPE_PESADO)
	if f["hp"] <= 0:                                      # derrotado: su aviso y su marca, fuera
		if f.get("cargando", false):
			f["cargando"] = false
			c._marcar_aviso(f, false)
		_marcar(c, f, null)
		return
	if not f.get("cargando", false):
		return
	if c.golpe_ruptura:
		_aturdir(c, f, "¡Quiebra!", "¡Kael y Garon rompen la Zancada de %s!" % f["nombre"])
		return
	f["carga_recibido"] = int(f.get("carga_recibido", 0)) + d
	if f["carga_recibido"] >= ceili(f["hp_max"] * c.UMBRAL_INTERRUPCION):
		_aturdir(c, f, "¡Interrumpido!", "¡%s pierde el equilibrio y no suelta la Zancada!" % f["nombre"])


static func _aturdir(c, f: Dictionary, cartel: String, texto: String) -> void:
	f["cargando"] = false
	f["recupera"] = true
	f["aturdido"] = true
	f["pl_aturdido"] = true
	f["pl_corte_turno"] = int(f.get("pl_turno", 0))
	f.erase("carga_recibido")
	f.erase("pl_objetivo")
	_contar(f, "zancada_cortada")
	c._marcar_aviso(f, false)
	_marcar(c, f, null)
	var p = c._p3d(f)
	if p != null and p.has_method("aturdido"):
		p.aturdido()
	c._sonar(SONIDOS["rota"])
	c._numero_flotante(f, cartel, Color(1.0, 0.92, 0.45), 36, Vector2(0, -60))
	c.registro.text = texto
	c._particulas(c._centro(f) + Vector2(0, -40), Color(COLOR_POLVO, 0.95), Color(COLOR_POLVO, 0.0), 12, 0.7,
		Vector2(60, 160), 40.0, Vector2(0, -1), 70.0, Vector2(0, 420), 0.10)
	c._temblor(3.0)
	c._actualizar()


# ================================================================= animación (combate.gd _animar_golpe)

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var ataque := str(o.get("pl_ataque", "piquete"))
	var hecho := [false]
	# el impacto: el golpe al principal (su sonido, una vez) y, en el MISMO instante, al de detrás (Zancada)
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
		_golpear_resto(c, o, obj, ataque)
	var p = c._p3d(o)
	if p == null:                                          # sin su modelo (no debería pasar): un golpe sin más
		if c._es_sprite(o):
			await c._anim_fisico_sprite(o, obj, golpe)
		else:
			golpe.call()
			await c.get_tree().create_timer(0.5).timeout
	elif ataque == "estaca":
		await _lanzar(c, o, obj, golpe)
	else:
		await _ir_y_golpear(c, o, obj, golpe, ataque)
	if not hecho[0]:
		golpe.call()


static func _golpear_resto(c, o: Dictionary, obj: Dictionary, ataque: String) -> void:
	var golpeados: Array = []
	if obj["hp"] > 0 and not c.ultimo_esquivado:
		golpeados.append(obj)
	if ataque == "zancada":
		_trazo(c, o, obj)
		c._temblor(5.0)
	for h0 in o.get("pl_resto", []):
		if h0["hp"] <= 0:
			continue
		var d2: int = maxi(1, int(o.get("pl_dano_resto", 0)) - int(h0.get("def", 0) / 2.0))
		if h0.get("defendiendo", false):
			d2 = maxi(1, int(d2 * 0.5))
		c._golpe_visual(h0, c._quitar_pv(h0, d2), "")
		golpeados.append(h0)
	if ataque == "zancada":
		for h in golpeados:
			retroceso(c, h)


# El empuje de la Zancada en el ATB: quien la recibe sin defender pierde RETROCESO_ATB de su barra. Nunca a quien ya está
# en la cola de turnos (no le quita el turno ni se lo duplica) ni a quien ha caído.
static func retroceso(c, h: Dictionary) -> bool:
	if h["hp"] <= 0 or h.get("defendiendo", false) or float(h.get("atb", 0.0)) >= c.ATB_MAX:
		return false
	for x in c.cola:
		if is_same(x, h):
			return false
	h["atb"] = maxf(0.0, float(h["atb"]) - c.ATB_MAX * RETROCESO_ATB)
	h["pl_retrocesos"] = int(h.get("pl_retrocesos", 0)) + 1
	c._numero_flotante(h, "Retroceso", COLOR_OCRE, 26, Vector2(30, -30))
	return true


# Corre (en zigzag) hasta el héroe, el clip con su impacto, retrocede a saltitos y vuelve a su sitio.
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
	var medio := base.lerp(destino, 0.5) + Vector2(0, -45.0 if randf() < 0.5 else 45.0)   # el zigzag: busca un flanco
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", medio, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t1.tween_property(rig, "position", destino, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t1.finished
	Sonido.voz(o, "ataque")
	if ataque == "zancada" and p.has_method("zancada"):
		await p.zancada(golpe)
	elif p.has_method("piquete"):
		await p.piquete(golpe)
	else:
		await p.atacar_hacha(golpe)
	golpe.call()                                           # (sin el clip, o cortado: el golpe igualmente, una vez)
	if o["hp"] > 0:
		var atras := destino.lerp(base, 0.35)              # retrocede a saltitos (retreat_step) y vuelve
		if p.has_method("retroceder"):
			var t2: Tween = c.create_tween()
			t2.tween_property(rig, "position", atras, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await p.retroceder()
		p.mirar(-ida, 0.2)
		p.correr()
		var t3: Tween = c.create_tween()
		t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t3.finished
		p.mirar_frente(0.25)
		if o.get("recupera", false) and p.has_method("aturdido"):
			p.aturdido()
		else:
			p.reposo()
	rig.z_index = 0
	o["animando"] = false


# A2: desde su sitio, mira al héroe, el clip «lanzar» y, al soltar, la estaca vuela; el daño, al llegar.
static func _lanzar(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	o["animando"] = true
	p.mirar(Vector3(1, 0, 0.25), 0.2)
	Sonido.voz(o, "ataque")
	var llego := [false]
	var al_soltar := func():
		var desde: Vector2 = _pantalla_mano(c, o)
		_volar(c, desde, c._centro(obj), func():
			c._sonar(SONIDOS["estaca"])
			c._particulas(c._centro(obj), Color(COLOR_POLVO, 1.0), Color(COLOR_POLVO, 0.0), 12, 0.6, Vector2(60, 180),
				30.0, Vector2(0, -1), 140.0, Vector2(0, 420), 0.10)
			golpe.call()
			llego[0] = true)
	if p.has_method("lanzar"):
		await p.lanzar(al_soltar)
	else:
		await p.atacar_hacha(al_soltar)
	var t0 := 0
	while not llego[0] and t0 < 60:                          # (la estaca aún en el aire: espera a que llegue)
		await c.get_tree().process_frame
		t0 += 1
	if not llego[0]:
		golpe.call()
	if o["hp"] > 0:
		p.mirar_frente(0.25)
		p.reposo()
	o["animando"] = false


static func _pantalla_mano(c, o: Dictionary) -> Vector2:
	var p = c._p3d(o)
	if p == null or not p.has_method("punto_mano") or not o.has("cam3d"):
		return c._centro(o) + Vector2(30, -60)
	var cam: Camera3D = o["cam3d"]
	var spr: Sprite2D = o["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(cam.unproject_position(p.punto_mano())))


# La estaca en vuelo: un palo de madera con la punta embarrada y las bandas ocre y blanca, casi recto (vuela rápida), y
# detrás una línea punteada de polvo (un nodo, 0,3 s).
static func _volar(c, desde: Vector2, hasta: Vector2, al_llegar: Callable) -> void:
	var n := Node2D.new()
	n.z_index = 7
	n.position = desde
	c.escena.add_child(n)
	var dir := (hasta - desde).normalized()
	var estela := []
	n.draw.connect(func():
		for i in estela.size():
			n.draw_circle(estela[i] - n.position, 3.0, Color(COLOR_POLVO, 0.15 + 0.6 * float(i) / maxf(1.0, estela.size())))
		var a := -dir * 46.0
		var b := dir * 30.0
		n.draw_line(a, b, Color(0.66, 0.50, 0.32), 7.0)
		n.draw_line(b, b + dir * 18.0, Color(0.32, 0.24, 0.16), 4.0)
		n.draw_line(a, a + dir * 10.0, Color(0.74, 0.31, 0.15), 8.0)
		n.draw_line(a + dir * 10.0, a + dir * 18.0, Color(0.93, 0.91, 0.84), 8.0))
	var t: Tween = c.create_tween()
	t.tween_method(func(k: float):
		if not is_instance_valid(n):
			return
		n.position = desde.lerp(hasta, k) + Vector2(0, -sin(k * PI) * 24.0)
		if estela.size() == 0 or (estela[-1] as Vector2).distance_to(n.position) > 22.0:
			estela.append(n.position)
			if estela.size() > 8:
				estela.pop_front()
		n.queue_redraw(), 0.0, 1.0, VUELO_S)
	t.tween_callback(func():
		if is_instance_valid(n):
			n.queue_free()
		al_llegar.call())


# El trazo ocre de la Zancada: una línea que atraviesa al marcado y al de detrás, y se apaga en 0,35 s.
static func _trazo(c, o: Dictionary, obj: Dictionary) -> void:
	var pts: Array = [c._centro(obj)]
	for h in o.get("pl_resto", []):
		pts.append(c._centro(h))
	var a: Vector2 = pts[0] - Vector2(120, 0)
	var b: Vector2 = pts[-1] + Vector2(80, 0)
	var n := Node2D.new()
	n.z_index = 6
	c.escena.add_child(n)
	var vida := [1.0]
	n.draw.connect(func():
		n.draw_line(a, b, Color(COLOR_OCRE, 0.85 * vida[0]), 10.0 * vida[0] + 2.0)
		n.draw_line(a, b, Color(1.0, 0.92, 0.7, 0.9 * vida[0]), 3.0))
	var t: Tween = c.create_tween()
	t.tween_method(func(k: float):
		vida[0] = 1.0 - k
		if is_instance_valid(n):
			n.queue_redraw(), 0.0, 1.0, 0.35)
	t.tween_callback(n.queue_free)


# ================================================================= la marca sobre el héroe elegido

static func _marcar(c, f: Dictionary, obj) -> void:
	var antes = f.get("pl_marca", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("pl_marca")
	if obj == null:
		return
	var s = c._sena_arte("aviso", obj, {"dur": 9999.0, "color": COLOR_MARCA})
	s.position = c._centro(obj) + Vector2(0, -150)
	f["pl_marca"] = s


# combate.gd _actualizar: si cae él o el héroe marcado, la marca fuera.
static func repasar(f: Dictionary) -> void:
	var m = f.get("pl_marca", null)
	if m == null:
		return
	var o = f.get("pl_objetivo", null)
	if int(f["hp"]) <= 0 or not (o is Dictionary) or int(o.get("hp", 0)) <= 0:
		if is_instance_valid(m):
			m.queue_free()
		f.erase("pl_marca")


# combate.gd _comprobar_fin: al acabar (victoria, derrota o huida), su marca fuera.
static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if not es(e):
			continue
		var n = e.get("pl_marca", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
		e.erase("pl_marca")


static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		var n = e.get("pl_marca", null)
		if es(e) and n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:pl_marca" % e["nombre"])
	return r
