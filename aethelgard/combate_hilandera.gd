extends RefCounted
# V12 (19/11/2026): la Hilandera del Eco, el artrópodo de una gruta que orienta las placas del lomo hacia los sonidos de
# la cueva (T-097, bestiario 01, élite; D-075: modelo de Meshy del usuario, licencia SIN CONFIRMAR → solo APK de prueba
# privadas). Modelo y clips: enemigos/hilandera/ (hilandera_3d.gd; fuentes_blender/crear_clips.py). Ficha:
# REBELUM_Bestiario/Fichas_e_integracion.txt (mordida_resonante 0,73 s y trama_de_eco 0,83 s). Documento:
# docs/v12/HILANDERA_V12.md.
#
# APAGADA: solo con su interruptor «hilandera_v12» (Engine.set_meta("hilandera_v12", true) o «-- hilandera_v12»), que
# enciende el banco de pruebas de Auditoría en su caso («hilandera», banco_pruebas.gd). Nunca sale al azar: solo en su
# combate de prueba GRUPOS[33], que hay que pedir a mano. Apagada, preparar() no cambia nada (queda la personalidad
# «agresivo» de ENEMIGOS; sus golpes los hace con la mordida) y no hay tiradas nuevas.
#
# Encendida (personalidad «hilandera», turno()), con el mismo patrón que Velaria (combate_velaria.gd):
#   · mordida_resonante, en dos turnos. El primero MARCA a su presa: alza el frente y orienta las placas (avisar() del
#     modelo; su señal «aviso» → «hilandera_aviso_mordida», UNA vez, por combate.gd _sonidos_bestia), «⚠ Cargando» y la
#     señal de aviso sobre su vida y OTRA señal sobre el héroe marcado (sprites, sin partículas: se lee en cualquier
#     perfil gráfico, como pide la ficha), ningún daño. El turno siguiente se acerca correteando y le muerde
#     (×MULT_MORDIDA; Defender, a la mitad, como cualquier golpe; Garon puede cubrirle): «hilandera_aviso_mordida» al
#     alzar el frente (la señal «aviso» del clip) y el impacto (daño y «hilandera_mordida») UNA vez, en el ancla del
#     clip (0,733 s). Vuelve a su sitio.
#   · trama_de_eco: desde su sitio alza las placas («hilandera_aviso_trama») y suelta un pulso a TODO el grupo con UNA
#     sola resolución (en el ancla del clip, 0,833 s: el daño de todos a la vez y «hilandera_trama» una vez). El turno
#     siguiente se recupera sin atacar (la ficha: «intercala un turno de recuperación»).
#   No tiene golpe suelto: cada turno marca, muerde, teje la trama o se recupera (presión predecible).
# Separación: IA = turno(); daño = combate.gd _animar_golpe (su impacto, una vez); presentación = hilandera_3d.gd.
# Cifras PROPUESTAS [P], sin equilibrar: PROB_TRAMA, MULT_* y su fila de combate.gd ENEMIGOS (decisión del usuario).

const CLAVE := "hilandera"
const PERSONALIDAD := "hilandera"
const INTERRUPTOR := "hilandera_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_PRUEBA := [33]
const MORDIDA := "mordida_resonante"
const TRAMA := "trama_de_eco"
const PROB_TRAMA := 0.4                         # PROPUESTA: la trama cuando no hay presa marcada (si no, marca)
const MULT_MORDIDA := 1.6                       # PROPUESTA: castiga al marcado (el Zarzalín embiste a ×1,8)
const MULT_TRAMA := 0.8                         # PROPUESTA: el pulso, a cada héroe
const COLOR_ECO := Color(0.66, 0.5, 1.0)        # el violeta de sus placas
const FRENTE_RESPALDO := 0.45                   # m de las mandíbulas por delante de su sitio si no se pueden medir


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


# combate.gd _elegir_enemigos: con el interruptor, su personalidad (si no, nada).
static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD


# La Hilandera con su personalidad (la IA de turno()).
static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


# La Hilandera con su modelo 3D (encendida o no): sus ataques los anima animar_golpe().
static func de_ella(c, f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE and c._p3d(f) != null \
		and c._p3d(f).has_method("placas")


# ================================================================= IA (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	if f.get("recupera", false):                    # tras la trama: recoge las placas, sin atacar
		f["recupera"] = false
		c.registro.text = "%s recoge las placas del lomo" % f["nombre"]
		c._numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
		await c.get_tree().create_timer(0.8).timeout
		return
	if f.get("cargando", false):                    # marcó el turno anterior: muerde a su presa
		f["cargando"] = false
		c._marcar_aviso(f, false)
		var objetivo = f.get("objetivo_carga", null)
		if objetivo == null or objetivo["hp"] <= 0:
			objetivo = c._elegir_objetivo("agresivo", vivos)
		objetivo = c._cubre(objetivo)               # Garon puede cubrir al marcado
		f.erase("objetivo_carga")
		_marcar(c, f, null)
		c.registro.text = "¡%s muerde a %s con las mandíbulas resonantes!" % [f["nombre"], objetivo["nombre"]]
		f["ataque_3d"] = MORDIDA
		await c._animar_golpe(f, objetivo, int(f["atk"] * MULT_MORDIDA * mult) + randi_range(-2, 3), "")
		f.erase("ataque_3d")
		return
	if randf() < PROB_TRAMA:                        # la trama de eco: a todo el grupo, una resolución
		var principal: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
		f["recupera"] = true
		f["hl_trama"] = {"vivos": vivos.duplicate(), "dano": int(f["atk"] * MULT_TRAMA * mult)}
		c.registro.text = "%s alza las placas: ¡la trama de eco alcanza a todo el grupo!" % f["nombre"]
		f["ataque_3d"] = TRAMA
		await c._animar_golpe(f, principal, int(f["atk"] * MULT_TRAMA * mult) + randi_range(-1, 2), "")
		f.erase("ataque_3d")
		f.erase("hl_trama")
		return
	var presa: Dictionary = c._elegir_objetivo("agresivo", vivos)   # marca a su presa
	f["cargando"] = true
	f["objetivo_carga"] = presa
	c._marcar_aviso(f, true)
	_marcar(c, f, presa)
	c.registro.text = "%s orienta las placas hacia %s: ¡lo ha marcado!" % [f["nombre"], presa["nombre"]]
	c._numero_flotante(f, "⚠ ¡Mordida!", Color(1.0, 0.8, 0.2), 32)
	c._actualizar()
	var p = c._p3d(f)
	if p != null and p.has_method("avisar"):
		await p.avisar(MORDIDA)
	else:
		await c.get_tree().create_timer(1.0).timeout


# ================================================================= animación (combate.gd _animar_golpe)

# El impacto de _animar_golpe (daño, Sonido.golpe y voz), UNA vez. Si cae a medias antes de golpear, no golpea.
static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var ataque := str(o.get("ataque_3d", MORDIDA))
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
		if ataque == TRAMA:
			_pulso_resto(c, o, obj)
	if ataque == TRAMA:
		await _trama(c, o, golpe)
	else:
		await _mordida(c, o, obj, golpe)
	if not hecho[0] and o["hp"] > 0:                 # sin el clip (o cortado): el golpe igualmente, una vez
		golpe.call()


# La mordida: se acerca correteando hasta donde sus mandíbulas llegan a la presa en el impacto del clip (su sitio en
# reposo + el alcance del clip, como el Cencerrante), el clip (con su avance) y vuelve a su sitio.
static func _mordida(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var m: Dictionary = c.MODELOS[o["modelo"]]
	var px_m: float = m["vp"].y / m["alto_vista"] * m["esc"]
	var adelante: float = _frente(p) + p.alcance(MORDIDA)
	var pies_x: float = c._centro(obj).x - 30.0 - adelante * px_m
	var destino := base + Vector2(pies_x - c._suelo_de(o).x, c._suelo_de(obj).y - c._suelo_de(o).y)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.15)
	p.correr()                                       # corretea
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	p.mirar(ida, 0.1)
	await p.atacar(MORDIDA, golpe)                   # su señal «aviso» (alza el frente) pide el sonido del aviso
	if o["hp"] > 0:
		p.mirar(-ida, 0.2)
		p.correr()
	if o["hp"] > 0:                                  # si cae en la mordida (la Réplica), cae donde está
		var t3: Tween = c.create_tween()
		t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t3.finished
	if o["hp"] > 0:
		p.mirar_frente(0.25)
		p.reposo()
	rig.z_index = 0
	o["animando"] = false


# La trama: desde su sitio, mirando al grupo. En el impacto del clip, el pulso (un anillo violeta que se abre desde las
# placas: un solo sprite, sin partículas de por medio, se ve con efectos reducidos) y el daño de todos a la vez.
static func _trama(c, o: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	o["animando"] = true
	p.mirar(Vector3(1, 0, 0.1), 0.15)
	var al_pulso := func():
		_anillo(c, _pantalla(c, o))
		golpe.call()
	await p.atacar(TRAMA, al_pulso)
	if o["hp"] > 0:
		p.mirar_frente(0.25)
	o["animando"] = false


# El resto del grupo, en el MISMO impacto que el principal (una resolución): las reglas del golpe a todos de combate.gd
# (_turno_patron, plan «todos»): menos la mitad de la defensa, Defender a la mitad, Garon cubre con su guardia.
static func _pulso_resto(c, o: Dictionary, principal: Dictionary) -> void:
	var t: Dictionary = o.get("hl_trama", {})
	var dano := int(t.get("dano", int(o["atk"] * MULT_TRAMA)))
	for h0 in t.get("vivos", []):
		if is_same(h0, principal) or h0["hp"] <= 0:
			continue
		var h: Dictionary = c._cubre(h0, false)
		if h["hp"] <= 0:
			continue
		var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
		if h.get("defendiendo", false):
			d2 = maxi(1, int(d2 * 0.5))
		c._golpe_visual(h, c._quitar_pv(h, d2), "")
	o["hl_pulsos"] = int(o.get("hl_pulsos", 0)) + 1     # (para las pruebas: cuántas resoluciones de la trama)
	c._temblor(6.0)


static func _anillo(c, desde: Vector2) -> void:
	var g: Sprite2D = c._brillo(COLOR_ECO)
	g.z_index = 7
	g.position = desde
	g.scale = Vector2(0.4, 0.4)
	g.modulate = Color(COLOR_ECO, 0.95)
	c.escena.add_child(g)
	var tw: Tween = c.create_tween()
	tw.tween_property(g, "scale", Vector2(3.2, 1.6), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(g, "modulate:a", 0.0, 0.45)
	tw.tween_callback(g.queue_free)


# Las placas de la Hilandera (hilandera_3d.gd placas()) en las medidas de la escena del combate.
static func _pantalla(c, o: Dictionary) -> Vector2:
	var p = c._p3d(o)
	if p == null or not p.has_method("placas") or not o.has("cam3d") or not o.has("partes") \
			or not o["partes"].has("sprite"):
		return c._centro(o)
	var cam: Camera3D = o["cam3d"]
	var spr: Sprite2D = o["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(cam.unproject_position(p.placas())))


# Metros de las mandíbulas por delante de su sitio, en reposo (con su escala), medidos en las pistas del clip.
static func _frente(p) -> float:
	if p == null or not p.has_method("_cabeza_en"):
		return FRENTE_RESPALDO
	var z: float = p._cabeza_en("reposo", 0.0).z * float(p.escala)
	if z <= 0.0 or z > 1.5:
		return FRENTE_RESPALDO
	return z


# ================================================================= la marca sobre la presa

# La señal de aviso encima del héroe marcado, hasta que muerde. «obj» null: fuera.
static func _marcar(c, f: Dictionary, obj) -> void:
	var antes = f.get("hl_marca", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("hl_marca")
	if obj == null:
		return
	var s = c._sena_arte("aviso", obj, {"dur": 9999.0, "color": COLOR_ECO})
	s.position = c._centro(obj) + Vector2(0, -150)
	f["hl_marca"] = s


# combate.gd _actualizar: si cae ella o el héroe marcado, la marca fuera (no queda nada colgado).
static func repasar(f: Dictionary) -> void:
	var m = f.get("hl_marca", null)
	if m == null:
		return
	var o = f.get("objetivo_carga", null)
	if int(f["hp"]) <= 0 or not (o is Dictionary) or int(o.get("hp", 0)) <= 0:
		if is_instance_valid(m):
			m.queue_free()
		f.erase("hl_marca")


# combate.gd _comprobar_fin: al acabar el combate (victoria o derrota), su marca, fuera.
static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		var n = e.get("hl_marca", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
		e.erase("hl_marca")


# Nodos que deja en la escena (para las pruebas: al acabar no debe quedar ninguno).
static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		var n = e.get("hl_marca", null)
		if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:hl_marca" % e["nombre"])
	return r
