extends RefCounted
# V12 (19/11/2026): Cencerrante, la campana de pastor con patas (T-097, bestiario 01, segunda bestia; «apoyo en un camino
# abandonado»). Modelo y clips ya en la V12 (enemigos/cencerrante/, cencerrante_3d.gd); ficha:
# REBELUM_Bestiario/Fichas_e_integracion.txt (toque_de_alarma 0,73 s y campanada_baja 0,53 s). Documento:
# docs/v12/CENCERRANTE_V12.md.
#
# APAGADO: solo con su interruptor «cencerrante_v12» (Engine.set_meta("cencerrante_v12", true) o «-- cencerrante_v12»),
# que enciende el banco de pruebas de Auditoría en su caso («cencerrante», banco_pruebas.gd). Nunca sale al azar: solo en
# sus combates de prueba GRUPOS[31] (con un Zarzalín) y GRUPOS[32] (solo), que hay que pedir a mano. Apagado, preparar()
# no cambia nada (queda la personalidad «agresivo» de ENEMIGOS; sus golpes los hace con la campanada baja) y no hay
# tiradas nuevas.
#
# Encendido (personalidad «cencerrante», turno()), con el mismo patrón que el Zarzalín (combate.gd _turno_zarzalin):
#   · toque_de_alarma: UNA activación por combate (el aviso y el refuerzo, como pide la ficha). La campana toma impulso
#     («cencerrante_aviso_alarma» al empezar el clip) y repica (señal «aviso» del modelo → «cencerrante_alarma», UNA vez,
#     por combate.gd _sonidos_bestia). Ningún daño.
#       - Con aliados vivos: el siguiente golpe de UN aliado (el de más ataque) irá reforzado (×MULT_REFUERZO). Se ve
#         «▲ Reforzado» sobre su vida hasta que golpea; el refuerzo se gasta en ese golpe (combate.gd _animar_golpe,
#         reforzar()). Él no prepara nada.
#       - Solo: prepara SU propio ataque («⚠ Cargando», el cartel dice a quién va) y el turno siguiente da la campanada
#         fuerte (×MULT_PROPIA; Defender, a la mitad, como cualquier golpe; Garon puede cubrir). Nadie más se refuerza.
#   · campanada_baja: se acerca a saltitos, «cencerrante_aviso_campanada» al empezar el clip y el impacto (daño y
#     «cencerrante_campanada», por la señal «impacto») UNA vez, en el ancla del clip (0,533 s). Vuelve a su sitio.
# Separación: IA = turno(); daño = combate.gd _animar_golpe (su impacto, una vez); presentación = cencerrante_3d.gd.
# Cifras PROPUESTAS, sin equilibrar: PROB_TOQUE_*, MULT_* y su fila de combate.gd ENEMIGOS.

const CLAVE := "cencerrante"
const PERSONALIDAD := "cencerrante"
const INTERRUPTOR := "cencerrante_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_PRUEBA := [31, 32]                 # 31: con un Zarzalín (el refuerzo); 32: solo (su propio ataque)
const TOQUE := "toque_de_alarma"
const CAMPANADA := "campanada_baja"
const SONIDO_TOQUE := "cencerrante_aviso_alarma"      # sonido.gd (tanda 4): al empezar el toque (toma impulso)
const SONIDO_REPIQUE := "cencerrante_alarma"          # el repique del toque (la señal «aviso» del modelo, 0,733 s)
const SONIDO_CAMPANADA := "cencerrante_aviso_campanada"   # al empezar el clip de la campanada (carga de lado)
const MARCA := "reforzado_cencerrante"          # en el aliado: su siguiente golpe va reforzado (se gasta al golpear)
const PROB_TOQUE_CON_ALIADOS := 1.0             # PROPUESTA: con aliados, su primer turno es el toque (es de apoyo)
const PROB_TOQUE_SOLO := 0.4                    # PROPUESTA (la del aviso del Zarzalín)
const MULT_REFUERZO := 1.3                      # PROPUESTA: el golpe del aliado reforzado
const MULT_PROPIA := 1.6                        # PROPUESTA: su campanada preparada (el Zarzalín embiste a ×1,8)
const FRENTE_RESPALDO := 0.3                    # m de la boca de la campana por delante de su sitio si no se mide


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


# combate.gd _elegir_enemigos: con el interruptor, su personalidad (si no, nada).
static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD


# El Cencerrante con su personalidad (la IA de turno()).
static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


# El Cencerrante con su modelo 3D (encendido o no): sus golpes los anima animar_golpe().
static func de_el(c, f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE and c._p3d(f) != null \
		and c._p3d(f).has_method("campana")


# combate.gd _sonidos_bestia: el nombre del sonido de su señal «aviso» (el repique), o "" si no es él.
static func sonido_aviso(e: Dictionary) -> String:
	return SONIDO_REPIQUE if str(e.get("clave", "")) == CLAVE else ""


# combate.gd _animar_golpe, al empezar: si el que golpea lleva el refuerzo del toque, su golpe ×MULT_REFUERZO y el
# refuerzo se gasta (una vez). Sin la marca (siempre, con el Cencerrante apagado), el mismo daño y nada más.
static func reforzar(c, origen: Dictionary, dano: int) -> int:
	if not origen.get(MARCA, false):
		return dano
	origen.erase(MARCA)
	c._numero_flotante(origen, "¡Reforzado!", Color(1.0, 0.8, 0.35), 28)
	return int(dano * MULT_REFUERZO)


# combate.gd _actualizar: lo que se lee sobre la vida de un enemigo reforzado.
static func estados(e: Dictionary) -> Array:
	return ["▲ Reforzado"] if e.get(MARCA, false) else []


# ================================================================= IA (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	if f.get("cargando", false):                    # tocó estando solo el turno anterior: su campanada preparada
		f["cargando"] = false
		c._marcar_aviso(f, false)
		var objetivo = f.get("objetivo_carga", null)
		if objetivo == null or objetivo["hp"] <= 0:
			objetivo = c._elegir_objetivo("agresivo", vivos)
		objetivo = c._cubre(objetivo)               # Garon puede cubrir al que avisó
		f.erase("objetivo_carga")
		c.registro.text = "¡%s descarga la campanada sobre %s!" % [f["nombre"], objetivo["nombre"]]
		await c._animar_golpe(f, objetivo, int(f["atk"] * MULT_PROPIA * mult) + randi_range(-2, 3), "")
		return
	if not f.get("toque_usado", false):
		var aliado := _aliado_a_reforzar(c, f)
		var prob := PROB_TOQUE_CON_ALIADOS if not aliado.is_empty() else PROB_TOQUE_SOLO
		if randf() < prob:
			await _toque(c, f, aliado, vivos)
			return
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
	c.registro.text = "%s ataca a %s" % [f["nombre"], obj["nombre"]]
	await c._animar_golpe(f, obj, int(f["atk"] * mult) + randi_range(-2, 3), "")


# El aliado vivo de más ataque (ni él, ni el que huyó, ni el rendido), o {} si está solo.
static func _aliado_a_reforzar(c, f: Dictionary) -> Dictionary:
	var mejor := {}
	for e in c.enemigos:
		if is_same(e, f) or e["hp"] <= 0 or e.get("huido", false) or e.get("rendido", false):
			continue
		if mejor.is_empty() or int(e["atk"]) > int(mejor["atk"]):
			mejor = e
	return mejor


# El toque de alarma (una vez por combate): con aliado, lo refuerza; solo, prepara su propio ataque.
static func _toque(c, f: Dictionary, aliado: Dictionary, vivos: Array) -> void:
	var p = c._p3d(f)
	f["toque_usado"] = true
	if not aliado.is_empty():
		aliado[MARCA] = true
		c.registro.text = "%s toca a rebato: ¡el próximo golpe de %s irá reforzado!" % [f["nombre"], aliado["nombre"]]
		c._numero_flotante(f, "¡Alarma!", Color(1.0, 0.8, 0.35), 32)
		c._numero_flotante(aliado, "▲ Reforzado", Color(1.0, 0.8, 0.35), 28)
	else:
		var objetivo: Dictionary = c._elegir_objetivo("agresivo", vivos)
		f["cargando"] = true
		c._marcar_aviso(f, true)
		f["objetivo_carga"] = objetivo
		c.registro.text = "%s toca a rebato a solas: ¡prepara su campanada contra %s!" % [f["nombre"], objetivo["nombre"]]
		c._numero_flotante(f, "⚠ ¡Campanada!", Color(1.0, 0.8, 0.2), 32)
	c._actualizar()
	c._sonar(SONIDO_TOQUE)                           # toma impulso; el repique suena con la señal «aviso» del modelo
	if p != null and p.has_method("avisar"):
		await p.avisar(TOQUE)
	else:
		await c.get_tree().create_timer(1.0).timeout


# ================================================================= animación (combate.gd _animar_golpe)

# La campanada baja: se acerca a saltitos hasta donde la boca de la campana llega al héroe en el impacto del clip (su
# sitio en reposo + el alcance del clip, como el Zarzalín), el clip (con su avance) y vuelve a su sitio. El impacto de
# _animar_golpe (daño, Sonido.golpe y voz), UNA vez; si cae a medias antes de golpear, no golpea.
static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var p = c._p3d(o)
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var m: Dictionary = c.MODELOS[o["modelo"]]
	var px_m: float = m["vp"].y / m["alto_vista"] * m["esc"]
	var adelante: float = _frente(p) + p.alcance(CAMPANADA)
	var pies_x: float = c._centro(obj).x - 30.0 - adelante * px_m
	var destino := base + Vector2(pies_x - c._suelo_de(o).x, c._suelo_de(obj).y - c._suelo_de(o).y)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.15)
	p.correr()                                       # a saltitos
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	p.mirar(ida, 0.1)
	c._sonar(SONIDO_CAMPANADA)                       # las bestias no tienen voz de «ataque»: carga de lado con el marco
	await p.atacar(CAMPANADA, golpe)
	if not hecho[0] and o["hp"] > 0:                 # sin el clip (o cortado): el golpe igualmente, una vez
		golpe.call()
	if o["hp"] > 0:
		p.mirar(-ida, 0.2)
		p.correr()
	var t3: Tween = c.create_tween()
	t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	if o["hp"] > 0:
		p.mirar_frente(0.25)
		p.reposo()
	rig.z_index = 0
	o["animando"] = false


# Metros de la boca de la campana por delante de su sitio, en reposo (con su escala), medidos en las pistas del clip.
static func _frente(p) -> float:
	if p == null or not p.has_method("_campana_en"):
		return FRENTE_RESPALDO
	var z: float = p._campana_en("reposo", 0.0).z * float(p.escala)
	if z <= 0.0 or z > 1.5:
		return FRENTE_RESPALDO
	return z
