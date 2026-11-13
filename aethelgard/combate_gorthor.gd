extends RefCounted
# V12, enemigos (12/11/2026): Gorthor el Devorador con su modelo propio, su herida fuerte, su ataque de fase 2 y su
# sonido. APAGADO: solo con el interruptor «enemigos_v12» (el de los modelos propios: combate.gd ENEMIGOS_V12).
# NO es un módulo que lo rehaga: Gorthor sigue luchando con lo que ya tiene en combate.gd (personalidad «jefe», su golpe
# devastador avisado, las fases al 50 %, Devorar, el último aliento con la decisión de Kael, el perdón y su premio).
# Esto solo AÑADE, con ganchos mínimos («V12, Gorthor» en combate.gd):
#   · La Hoguera del Devorador (solo en la fase 2, la Furia del Abismo; nunca a la vez que el golpe devastador):
#     AVISO un turno: clava la cuchilla al rojo delante (hoguera_carga) y se queda apoyado en ella con las vetas
#     latiendo; sale «⚠ ¡Hoguera!» sobre él, la señal de aviso de siempre y un círculo de brasas bajo cada héroe. Su
#     turno siguiente la arranca del suelo con un giro y las brasas ESTALLAN bajo todo el grupo: ×1,2 a cada uno, todos
#     en el impacto del clip. Respuestas: DEFENDER (a la mitad), la GUARDIA de Garon (cubre a uno), APAGARLA con una
#     magia de Agua (Agua, Torrente o Maremoto: el agua sobre las brasas) o CORTARLA como cualquier carga (un cuarto
#     de su vida mientras la prepara, o Quiebra). Apagada o cortada, se tambalea (aturdido) y pierde su turno siguiente.
#   · Herida fuerte: un golpe de ≥ 12 % de su vida pone recibir_golpe_fuerte.
#   · Sonido en sus momentos (señal «evento» de sus clips): el rugido (entrada, Furia del Abismo y la Hoguera), el
#     trago (Devorar) y las rodillas (último aliento); la Hoguera al clavar y al estallar; «apagada» al cortarla.
# Apagado, Gorthor.es() es falso: ni un dado más, y la huella del combate (E8) es la de siempre.
# Modelo y clips: enemigos/gorthor/ (gorthor_v2.glb; guion fuente/crear_gorthor.py con «v2»).

const CLAVE := "gorthor"
const INTERRUPTOR := "enemigos_v12"
const ACTIVO_POR_DEFECTO := false
const MULT_HOGUERA := 1.2
const PROB_HOGUERA := 0.3
const ESPERA_HOGUERA := 3                 # turnos suyos entre una Hoguera y la siguiente
const GOLPE_PESADO := 0.12
const MAGIA_QUE_APAGA := "Agua"           # combate.gd magia_sel (Agua, Torrente y Maremoto son sus tres niveles)
const COLOR_BRASA := Color(1.0, 0.42, 0.10)   # el de sus vetas (gorthor_3d.gd COLOR_BRILLO)
const COLOR_VAPOR := Color(0.85, 0.92, 1.0)
const SONIDOS := {"rugido": "gorthor_rugido", "trago": "gorthor_trago", "rodillas": "gorthor_rodillas",
	"clava": "gorthor_hoguera_carga", "hoguera": "gorthor_hoguera", "apagada": "gorthor_apagada"}


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


static func es(f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE and not f.get("hero", false) and activo()


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("gt_contador"):
		f["gt_contador"] = {}
	f["gt_contador"][k] = int(f["gt_contador"].get(k, 0)) + 1


# combate.gd, al empezar: los sonidos de los instantes con nombre de sus clips.
static func al_entrar(c, e: Dictionary, p) -> void:
	if not es(e) or p == null or not p.has_signal("evento") or e.get("gt_conectado", false):
		return
	e["gt_conectado"] = true
	p.evento.connect(_al_evento.bind(c, e))


static func _al_evento(clip: String, nombre: String, c, e: Dictionary) -> void:
	match nombre:
		"rugido", "trago", "rodillas":
			_contar(e, "son_" + nombre)
			c._sonar(SONIDOS[nombre])
		"clava":
			if clip == "hoguera_carga":
				c._sonar(SONIDOS["clava"])
				c._particulas(c._suelo_de(e) + Vector2(40, -10), Color(COLOR_BRASA, 1.0), Color(COLOR_BRASA, 0.0), 16, 0.8,
					Vector2(40, 160), 30.0, Vector2(0, -1), 70.0, Vector2(0, 180), 0.12)
				c._temblor(4.0)


# ================================================================= lo que se lee

static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("gt_hoguera", false):
		r.append("⚠ Hoguera (el Agua la apaga)")
	if e.get("gt_aturdido", false):
		r.append("Aturdido")
	return r


static func info(e: Dictionary) -> Array:
	if e.get("gt_hoguera", false):
		return ["⚠ Prepara la Hoguera a todos: defiéndete, apágala con Agua o dale fuerte y la cortas"]
	if e.get("gt_aturdido", false):
		return ["Aturdido: pierde su turno"]
	return []


# combate.gd _actualizar: si cae, se rinde o acaba el combate, las brasas y la Hoguera, fuera.
static func repasar(f: Dictionary) -> void:
	if not f.has("gt_marcas"):
		return
	if int(f["hp"]) <= 0 or f.get("rendido", false) or not f.get("gt_hoguera", false):
		f["gt_hoguera"] = false
		_quitar_marcas(f)


static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if es(e):
			_quitar_marcas(e)


static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		var n = e.get("gt_marcas", null)
		if es(e) and n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:gt_marcas" % e["nombre"])
	return r


# ================================================================= su turno (combate.gd _turno_enemigo, antes de Devorar)

# Devuelve true si este turno ha sido suyo (aturdido, la Hoguera o su aviso); false: lo de siempre (Devorar, el golpe
# devastador o el ataque).
static func turno(c, f: Dictionary, vivos: Array, mult: float) -> bool:
	f["gt_turno"] = int(f.get("gt_turno", 0)) + 1
	if f.get("gt_aturdido", false):
		await _recuperar(c, f)
		return true
	if f.get("gt_hoguera", false):
		await _hoguera(c, f, vivos, mult)
		return true
	if not f.get("fase2", false) or f.get("cargando", false):
		return false
	if int(f["gt_turno"]) - int(f.get("gt_turno_hoguera", -10)) <= ESPERA_HOGUERA:
		return false
	if randf() >= PROB_HOGUERA:
		return false
	await _avisar(c, f, vivos)
	return true


static func _avisar(c, f: Dictionary, vivos: Array) -> void:
	f["gt_hoguera"] = true
	f["gt_recibido"] = 0
	f["gt_turno_hoguera"] = int(f.get("gt_turno", 0))
	_contar(f, "aviso_hoguera")
	c._marcar_aviso(f, true)
	_marcar(c, f, vivos)
	var p = c._p3d(f)
	f["animando"] = true
	if p != null and p.has_method("preparar_hoguera"):
		p.preparar_hoguera()
	else:
		c._sonar(SONIDOS["clava"])
	c.registro.text = "¡%s clava la cuchilla al rojo: las brasas van a estallar bajo todo el grupo! (el Agua las apaga)" % f["nombre"]
	c._numero_flotante(f, "⚠ ¡Hoguera!", Color(1.0, 0.8, 0.2), 34)
	c._actualizar()
	await c.get_tree().create_timer(1.3).timeout
	f["animando"] = false


static func _hoguera(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["gt_hoguera"] = false
	f.erase("gt_recibido")
	c._marcar_aviso(f, false)
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		_quitar_marcas(f)
		return
	var principal: Dictionary = c._cubre(vivos[int(vivos.size() / 2.0)], false)
	var resto: Array = []
	for h0 in vivos:
		if not is_same(h0, principal):
			resto.append(h0)
	var dano := int(f["atk"] * MULT_HOGUERA * mult)
	c.registro.text = "¡%s arranca la cuchilla: la Hoguera del Devorador estalla bajo todo el grupo!" % f["nombre"]
	f["gt_ataque"] = "hoguera"
	f["gt_resto"] = resto
	f["gt_dano_resto"] = dano
	_contar(f, "hoguera")
	await c._animar_golpe(f, principal, dano + randi_range(-2, 3), "")
	f.erase("gt_ataque")
	f["gt_resto"] = []
	_quitar_marcas(f)


static func _recuperar(c, f: Dictionary) -> void:
	f["gt_aturdido"] = false
	_contar(f, "recupera")
	c.registro.text = "%s, aturdido, se sacude el vapor de las vetas" % f["nombre"]
	var p = c._p3d(f)
	if p != null:
		p.reposo()
	c._numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
	c._actualizar()
	await c.get_tree().create_timer(0.8).timeout


# ================================================================= el golpe recibido (combate.gd _vigilar_carga)

static func vigilar(c, f: Dictionary, d: int) -> void:
	var p = c._p3d(f)
	if p != null and "golpe_pesado" in p:
		p.golpe_pesado = d >= ceili(f["hp_max"] * GOLPE_PESADO)
	if f["hp"] <= 0 or f.get("rendido", false) or not f.get("gt_hoguera", false):
		return
	if c.golpe_magico and str(c.magia_sel) == MAGIA_QUE_APAGA:
		_aturdir(c, f, "¡Apagada!", "¡El agua apaga las brasas de %s! Pierde su turno." % f["nombre"], true)
		return
	if c.golpe_ruptura:
		_aturdir(c, f, "¡Quiebra!", "¡Kael y Garon rompen la Hoguera de %s!" % f["nombre"], false)
		return
	f["gt_recibido"] = int(f.get("gt_recibido", 0)) + d
	if f["gt_recibido"] >= ceili(f["hp_max"] * c.UMBRAL_INTERRUPCION):
		_aturdir(c, f, "¡Interrumpido!", "¡%s pierde el equilibrio y no arranca la cuchilla!" % f["nombre"], false)


static func _aturdir(c, f: Dictionary, cartel: String, texto: String, agua: bool) -> void:
	f["gt_hoguera"] = false
	f["gt_aturdido"] = true
	f.erase("gt_recibido")
	_contar(f, "apagada" if agua else "cortada")
	c._marcar_aviso(f, false)
	_quitar_marcas(f)
	var p = c._p3d(f)
	if p != null and p.has_method("aturdido"):
		p.aturdido()
	c._sonar(SONIDOS["apagada"])
	c._numero_flotante(f, cartel, Color(1.0, 0.92, 0.45), 36, Vector2(0, -60))
	c.registro.text = texto
	var col: Color = COLOR_VAPOR if agua else COLOR_BRASA
	c._particulas(c._centro(f) + Vector2(20, -40), Color(col, 0.9), Color(col, 0.0), 16, 1.0, Vector2(40, 140), 50.0,
		Vector2(0, -1), 50.0, Vector2(0, -80), 0.16)
	c._temblor(4.0)
	c._actualizar()


# ================================================================= animación (combate.gd _animar_golpe)

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
		_estallido(c, o, obj)
	var p = c._p3d(o)
	o["animando"] = true
	if p != null and p.has_method("hoguera"):
		p.mirar(Vector3(1, 0, 0.25), 0.15)
		await p.hoguera(golpe)
	else:
		golpe.call()
		await c.get_tree().create_timer(0.6).timeout
	if not hecho[0]:
		golpe.call()
	if p != null and o["hp"] > 0 and not o.get("rendido", false):
		p.mirar_frente(0.25)
	o["animando"] = false


# El estallido: brasas bajo cada héroe, su sonido una vez y el daño a los demás en el mismo instante que al principal.
static func _estallido(c, o: Dictionary, obj: Dictionary) -> void:
	c._sonar(SONIDOS["hoguera"])
	c._temblor(10.0)
	var todos: Array = [obj]
	todos.append_array(o.get("gt_resto", []))
	for h in todos:
		c._particulas(c._suelo_de(h), Color(COLOR_BRASA, 1.0), Color(1.0, 0.85, 0.3, 0.0), 22, 0.8, Vector2(120, 320), 40.0,
			Vector2(0, -1), 30.0, Vector2(0, 260), 0.16)
	var dano := int(o.get("gt_dano_resto", 0))
	for h0 in o.get("gt_resto", []):
		if h0["hp"] <= 0:
			continue
		var h: Dictionary = c._cubre(h0, false)
		if h["hp"] <= 0:
			continue
		var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
		if h.get("defendiendo", false):
			d2 = maxi(1, int(d2 * 0.5))
		c._golpe_visual(h, c._quitar_pv(h, d2), "")


# ================================================================= las brasas bajo los héroes (un nodo, con presupuesto)

static func _marcar(c, f: Dictionary, vivos: Array) -> void:
	_quitar_marcas(f)
	var n := Node2D.new()
	n.material = c.mat_aditivo
	n.z_index = 1
	c.escena.add_child(n)
	var sitios: Array = []
	for h in vivos:
		sitios.append(c._suelo_de(h))
	var est := {"t": 0.0}
	n.draw.connect(func():
		var k: float = 0.5 + 0.5 * sin(est["t"] * TAU * 1.6)
		for s in sitios:
			n.draw_set_transform(s, 0.0, Vector2(1.0, 0.32))
			n.draw_circle(Vector2.ZERO, 70.0, Color(COLOR_BRASA, 0.18 + 0.18 * k))
			n.draw_arc(Vector2.ZERO, 70.0, 0, TAU, 40, Color(1.0, 0.75, 0.3, 0.55 + 0.35 * k), 5.0)
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	var t: Tween = n.create_tween().set_loops()
	t.tween_method(func(v: float):
		est["t"] = v
		n.queue_redraw(), 0.0, 1.0, 1.0)
	f["gt_marcas"] = n


static func _quitar_marcas(f: Dictionary) -> void:
	var n = f.get("gt_marcas", null)
	if n != null and is_instance_valid(n):
		n.queue_free()
	f.erase("gt_marcas")
