extends RefCounted
# V12, fase 9 (PILOTO, 14/11/2026): meshy_e01 · el Custodio de Porcelana (nombre de diseño), del FBX de Meshy del
# usuario con rig, clips y un especial hechos aquí (enemigos/meshy_e01/; docs/v12/CUSTODIO_E01_V12.md). No confundir con
# el bestiario common_e01…e10 (Peón de Linde, Velador…): otro paquete, otro espacio de nombres.
#
# APAGADO: solo con su interruptor propio «meshy_e01» (Engine.set_meta("meshy_e01", true) o «-- meshy_e01»). Nunca sale
# en los encuentros al azar (no tiene gancho en grupo_al_azar): solo en sus combates de prueba GRUPOS[28] (él solo) y
# GRUPOS[29] (con un Slime), que hay que pedir a mano («-- grupo=28 meshy_e01»). Apagado, es() es falso para todos y el
# combate es el de siempre (sin tiradas del generador nuevas).
#
# Separación (PROMPT_MAESTRO §5): IA = turno()/_elegir (qué hace en su turno); ejecutor = _prensa (objetivos, daño
# propuesto, recarga); daño = combate.gd _animar_golpe (el impacto, UNA vez) y _golpear_resto, con la deduplicación
# attack_instance_id + target_id; presentación = meshy_e01_3d.gd (el clip y sus instantes) y la marca de aviso.
# El reloj de los instantes es el del clip (señal «evento» de enemigo_v12_3d.gd, que sigue la reproducción real).
#
# e01_a1 · Prensa del Umbral (ataques_propuestos.json, adaptado al ATB con las reglas de docs/v12/BESTIARIO_V12.md §2):
#   · Aviso dentro del clip (0,90 s < un turno; «no convertir un aviso visual en una ocasión de esquivar que no existe»):
#     al empezar el clip (0,00) se marca en el suelo el rectángulo frontal sobre el blanco y quien vaya detrás; a 0,65 s
#     la marca se FIJA (no persigue a nadie) y se vuelve sólida; en el IMPACTO (0,90) se resuelve el daño y se borra.
#   · «Rectángulo frontal de 1,4 × 1,8 m; un impacto por objetivo» → EN FILA: el elegido ×1,4 del ataque y el de detrás
#     en la formación ×0,5 de eso (la regla del bestiario para «en fila»); cada uno UNA vez por ejecución.
#   · Empuje de 0,4 m → RETROCESO del 15 % de la barra ATB a quien lo recibe sin defender (como la Zancada del Peón,
#     0,4 m); nunca a quien ya está en la cola de turnos.
#   · cooldown_own_turns = 2 (no cooldown_s: el combate es por turnos): tras la Prensa se salta sus dos turnos propios
#     siguientes; en ellos se pone en GUARDIA (la defensa de siempre de los enemigos: golpes a la mitad) hasta su turno
#     siguiente. Es un piloto: los otros dos especiales (a2 Avance del Portón y a3 Sello de Clausura) están pendientes.
#   · Muerte a media Prensa: no golpea (enemigo_v12_3d.gd no llama al impacto si está muerto y aquí se comprueba su vida)
#     y la marca se borra (vigilar, repasar y al_acabar).

const CLAVE := "meshy_e01"
const PERSONALIDAD := "meshy_e01"
const INTERRUPTOR := "meshy_e01"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_PRUEBA := [28, 29]
const ATAQUE_ID := "e01_a1"
const MULT_PRENSA := 1.4
const MULT_FILA := 0.5
const CD_TURNOS := 2
const RETROCESO := 0.15
const T_FIJA := 0.65
const T_IMPACTO := 0.90
const T_FIN_ACTIVO := 1.10
const COLOR_MARCA := Color(1.0, 0.74, 0.32)
const COLOR_CERAMICA := Color(0.93, 0.90, 0.82)
const COLOR_POLVO := Color(0.72, 0.66, 0.55)
const MARCA_TAM := Vector2(150.0, 190.0)          # el rectángulo en el suelo (aplastado como _onda: ×0,32 en vertical)

static var _instancias := 0                       # attack_instance_id: uno por ejecución de la Prensa


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD
		e["e01_cd"] = 0


static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("e01_contador"):
		f["e01_contador"] = {}
	f["e01_contador"][k] = int(f["e01_contador"].get(k, 0)) + 1


static func al_entrar(c, e: Dictionary, p) -> void:
	if not es(e) or p == null or e.get("e01_conectado", false):
		return
	e["e01_conectado"] = true
	if p.has_signal("evento"):
		p.evento.connect(_al_evento.bind(c, e))


# Los instantes del clip (presentación): la marca aparece en el aviso y se fija a 0,65 s.
static func _al_evento(clip: String, nombre: String, c, e: Dictionary) -> void:
	if clip != "ataque" and clip != "e01__attack_prensa":
		return
	var at: Dictionary = e.get("e01_ataque", {})
	if at.is_empty() or int(e["hp"]) <= 0:
		return
	if nombre == "aviso":
		at["t_aviso"] = Engine.get_process_frames()
		_marcar(c, e, at)
	elif nombre == "fija_direccion":
		at["t_fija"] = Engine.get_process_frames()
		_fijar(e)
	elif nombre == "fin_activo":
		at["t_fin_activo"] = Engine.get_process_frames()


# ================================================================= lo que se lee

static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("e01_guardia", false):
		r.append("Guardia")
	if int(e.get("e01_cd", 0)) > 0:
		r.append("Prensa en %d" % (int(e["e01_cd"]) + 1))
	return r


static func info(e: Dictionary) -> Array:
	if e.get("e01_guardia", false):
		return ["En guardia: golpes a la mitad hasta su próximo turno"]
	if int(e.get("e01_cd", 0)) > 0:
		return ["Recupera la Prensa: se cubre en sus próximos %d turnos" % int(e["e01_cd"])]
	return ["⚠ Su próximo turno: Prensa del Umbral, en fila (defiéndete)"]


# ================================================================= su turno (IA)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["e01_turno"] = int(f.get("e01_turno", 0)) + 1
	if f.get("e01_guardia", false):                     # la guardia dura hasta su turno siguiente
		f["e01_guardia"] = false
		f["defendiendo"] = false
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	if _elegir(f) == "prensa":
		await _prensa(c, f, vivos, mult)
	else:
		await _guardia(c, f)


static func _elegir(f: Dictionary) -> String:
	return "guardia" if int(f.get("e01_cd", 0)) > 0 else "prensa"


static func _guardia(c, f: Dictionary) -> void:
	f["e01_cd"] = maxi(0, int(f.get("e01_cd", 0)) - 1)     # un turno propio menos de recarga
	f["e01_guardia"] = true
	f["defendiendo"] = true
	_contar(f, "guardia")
	c.registro.text = "%s cruza los brazos de porcelana y aguanta" % f["nombre"]
	c._numero_flotante(f, "Guardia", Color(0.85, 0.88, 0.95), 30)
	var p = c._p3d(f)
	if p != null:
		p.reposo()
	c._actualizar()
	await c.get_tree().create_timer(0.8).timeout


# El vecino en la fila: el siguiente héroe vivo de la formación (si no hay, el anterior). Como el del Peón.
static func vecino(c, obj: Dictionary) -> Dictionary:
	var lista: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var i := -1
	for k in lista.size():
		if is_same(lista[k], obj):
			i = k
	if i < 0 or lista.size() < 2:
		return {}
	return lista[i + 1] if i + 1 < lista.size() else lista[i - 1]


# ================================================================= ejecutor

static func _prensa(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var marcado: Dictionary = c._elegir_objetivo("agresivo", vivos)
	var obj: Dictionary = c._cubre(marcado)                 # la Guardia de Garon: el principal se lo lleva él
	var detras := vecino(c, marcado)
	if not detras.is_empty() and is_same(detras, obj):      # (Garon cubre al marcado y era el de detrás: el otro lado)
		detras = vecino(c, obj)
		if not detras.is_empty() and is_same(detras, marcado):
			detras = {}
	_instancias += 1
	var at := {"id": _instancias, "ataque": ATAQUE_ID, "principal": obj, "resto": [] if detras.is_empty() else [detras],
		"dano_resto": int(f["atk"] * MULT_PRENSA * MULT_FILA * mult), "golpeados": {}, "t_impacto": -1}
	f["e01_ataque"] = at
	_contar(f, "prensa")
	c.registro.text = "%s alza los puños: ¡Prensa del Umbral contra %s%s!" % [f["nombre"], obj["nombre"],
		(" y %s" % detras["nombre"]) if not detras.is_empty() else ""]
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_PRENSA * mult) + randi_range(-2, 2), "")
	_quitar_marca(f)
	f.erase("e01_ataque")
	f["e01_ultimo"] = at
	f["e01_cd"] = CD_TURNOS


# Daño UNA vez por (ejecución, objetivo). Devuelve si este golpe cuenta.
static func _registrar(f: Dictionary, at: Dictionary, h: Dictionary) -> bool:
	var clave := "%d:%s" % [int(at["id"]), str(h.get("nombre", ""))]
	if at["golpeados"].has(clave):
		_contar(f, "duplicado_evitado")
		return false
	at["golpeados"][clave] = Engine.get_process_frames()
	return true


# ================================================================= daño y presentación (combate.gd _animar_golpe)

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var at: Dictionary = o.get("e01_ataque", {})
	if at.is_empty():                                       # (no debería pasar: un golpe sin ejecución)
		impacto.call()
		return
	var golpe := func():
		if int(at["t_impacto"]) >= 0 or int(o["hp"]) <= 0:  # una vez; y muerto a medias, nada
			return
		at["t_impacto"] = Engine.get_process_frames()
		_quitar_marca(o)
		if _registrar(o, at, obj):
			impacto.call()
		var golpeados: Array = []
		if obj["hp"] > 0 and not c.ultimo_esquivado:
			golpeados.append(obj)
		for h in at["resto"]:
			if h["hp"] <= 0 or not _registrar(o, at, h):
				continue
			var d2: int = maxi(1, int(at["dano_resto"]) - int(h.get("def", 0) / 2.0))
			if h.get("defendiendo", false):
				d2 = maxi(1, int(d2 * 0.5))
			c._golpe_visual(h, c._quitar_pv(h, d2), "")
			golpeados.append(h)
		for h in golpeados:
			if retroceso(c, h):
				_contar(o, "retroceso")
		_polvo(c, obj)
	var p = c._p3d(o)
	if p == null or not p.has_method("prensa"):
		golpe.call()
		await c.get_tree().create_timer(0.5).timeout
		return
	await _ir_y_prensar(c, o, obj, golpe)


# El empuje de 0,4 m en el ATB: −15 % de la barra a quien lo recibe sin defender; nunca a quien ya está en la cola.
static func retroceso(c, h: Dictionary) -> bool:
	if h["hp"] <= 0 or h.get("defendiendo", false) or float(h.get("atb", 0.0)) >= c.ATB_MAX:
		return false
	for x in c.cola:
		if is_same(x, h):
			return false
	h["atb"] = maxf(0.0, float(h["atb"]) - c.ATB_MAX * RETROCESO)
	c._numero_flotante(h, "Retroceso", COLOR_POLVO, 26, Vector2(30, -30))
	return true


# Anda pesado hasta el blanco, la Prensa con su impacto (el clip manda), y vuelve andando.
static func _ir_y_prensar(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var hueco: float = c.ANIM[o["modelo"]].get("distancia", 120.0) + c.ANIM[obj["modelo"]].get("distancia", 120.0) * 0.4
	var destino := base + Vector2(c._centro(obj).x - hueco - c._centro(o).x, (c._pos_ataque(obj).y - o["pos"].y) * 0.8)
	if obj.has("centro_ofs") and o.has("centro_ofs"):
		destino.y = base.y + (c._suelo_de(obj).y - c._suelo_de(o).y)
	var dur := clampf(rig.position.distance_to(destino) / 260.0, 0.6, 1.4)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.25)
	p.andar()
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", destino, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	Sonido.voz(o, "ataque")
	if o["hp"] > 0:
		await p.prensa(golpe)
	if o["hp"] > 0:
		p.mirar(-ida, 0.3)
		p.andar()
		var t3: Tween = c.create_tween()
		t3.tween_property(rig, "position", base, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t3.finished
		p.mirar_frente(0.3)
		p.reposo()
	rig.z_index = 0
	o["animando"] = false


static func _polvo(c, obj: Dictionary) -> void:
	var pie: Vector2 = c._suelo_de(obj)
	c._onda(pie, Color(COLOR_POLVO, 0.85), 24.0, 120.0, 0.45, 7.0)
	c._particulas(pie, Color(COLOR_CERAMICA, 1.0), Color(COLOR_CERAMICA, 0.0), 12, 0.55, Vector2(80, 220), 40.0,
		Vector2(0, -1), 70.0, Vector2(0, 520), 0.10)
	c._temblor(4.0)


# ================================================================= la marca (aviso)

static func _marcar(c, f: Dictionary, at: Dictionary) -> void:
	_quitar_marca(f)
	var raiz := Node2D.new()
	raiz.name = "MarcaPrensa"
	raiz.z_index = 1
	c.escena.add_child(raiz)
	var blancos: Array = [at["principal"]] + at["resto"]
	var fija := [false]
	var alfa := [0.0]
	for h in blancos:
		if h["hp"] <= 0:
			continue
		var r := Node2D.new()
		r.position = c._suelo_de(h)                      # fija: no sigue al objetivo después
		r.scale = Vector2(1.0, 0.32)
		raiz.add_child(r)
		r.draw.connect(func():
			var rect := Rect2(-MARCA_TAM * 0.5, MARCA_TAM)
			r.draw_rect(rect, Color(COLOR_MARCA, (0.34 if fija[0] else 0.2) * alfa[0]), true)
			r.draw_rect(rect, Color(COLOR_MARCA, (0.95 if fija[0] else 0.75) * alfa[0]), false, 6.0 if fija[0] else 4.0))
	f["e01_marca"] = raiz
	f["e01_marca_fija"] = fija
	var t: Tween = raiz.create_tween()
	t.tween_method(func(k: float):
		alfa[0] = k
		for r in raiz.get_children():
			r.queue_redraw(), 0.0, 1.0, 0.25)


static func _fijar(f: Dictionary) -> void:
	var m = f.get("e01_marca", null)
	if m == null or not is_instance_valid(m):
		return
	var fija: Array = f.get("e01_marca_fija", [false])
	fija[0] = true
	for r in m.get_children():
		r.queue_redraw()


static func _quitar_marca(f: Dictionary) -> void:
	var m = f.get("e01_marca", null)
	if m != null and is_instance_valid(m):
		m.queue_free()
	f.erase("e01_marca")
	f.erase("e01_marca_fija")


# ================================================================= vigilancia y limpieza

# combate.gd _vigilar_carga: un golpe recibido. La Prensa no se corta con daño (su aviso es parte del clip, no un turno),
# pero si cae, la marca se va (y el clip no golpea: está muerto).
static func vigilar(_c, f: Dictionary, _d: int) -> void:
	if f["hp"] <= 0:
		_quitar_marca(f)
		if f.get("e01_guardia", false):
			f["e01_guardia"] = false


static func repasar(f: Dictionary) -> void:
	if f.has("e01_marca") and (int(f["hp"]) <= 0 or f.get("huido", false)):
		_quitar_marca(f)


static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if es(e):
			_quitar_marca(e)


static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		var n = e.get("e01_marca", null)
		if es(e) and n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:e01_marca" % e["nombre"])
	return r
