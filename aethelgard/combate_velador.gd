extends RefCounted
# V12, bestiario de producción (13/11/2026): e02 · el Velador de Corteza, defensor común del Gran Bosque Verde.
# APAGADO: solo con el interruptor «enemigos_v12». Encendido: sale en los encuentros al azar del bosque con una
# probabilidad PROB_AL_AZAR, en el grupo de su tamaño (GRUPOS[25], [26] o [27]), que son también sus combates de prueba
# («-- grupo=25 enemigos_v12»). Apagado, Velador.es() es falso para todos, nadie elige esos grupos y el combate es el de
# siempre. Modelo y clips: enemigos/velador_corteza/ (guion fuente/crear_velador_corteza.py). Diseño y conversión al ATB:
# docs/v12/BESTIARIO_V12.md. Informe: docs/memory/agents/combate_v12_bestiario.md.
#
# Papel (ficha e02): defensor lento y duro. Vida, ataque, premios y escalado, los de ENEMIGOS["velador_corteza"] y
# combate_escalado.gd (región «bosque»). Rasgo y tres ataques adaptados al ATB, cada impacto UNA vez en su instante:
#   · Guardia de anillos (el documento: «protege con el escudo; tras bloquear dos golpes abre la guardia»): fuera de sus
#     ataques está EN GUARDIA con la defensa de siempre de los enemigos («defendiendo»: golpes a la mitad). Al segundo
#     golpe que para, la guardia se ABRE hasta el final de su turno siguiente (golpes enteros): la respuesta es golpearle
#     dos veces flojo y luego fuerte. Mientras prepara la Raíz no está en guardia.
#   · A1 Mazazo de poda (peso 50; a uno, ×1,35): alza la maza sobre el hombro y la deja caer (aviso en el clip, 0,9 s).
#   · A2 Empuje de anillos (peso 30; a uno, ×0,65 + RETROCESO del 20 % de la barra ATB: el empuje de 0,8 m).
#   · A3 Raíz de umbral (peso 20; un turno de aviso: clava la maza y señala a uno; su turno siguiente brotan tres raíces
#     bajo él, a distancia, ×0,9 + RETROCESO del 15 %: el «lento 20 % 2 s» del documento, que en el ATB es tiempo
#     perdido). Se corta como en la V11 (un cuarto de su vida o Quiebra → aturdido, pierde el turno). Nunca dos seguidas.
# Lo que no se ha adaptado: «no bloquea por detrás» (el combate no tiene espaldas).

const CLAVE := "velador_corteza"
const PERSONALIDAD := "velador_corteza"
const INTERRUPTOR := "enemigos_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_POR_TAMANO := {1: 25, 2: 26, 3: 27}
const ZONA := "bosque"                            # Gran Bosque Verde
const PROB_AL_AZAR := 0.25
const PESOS := {"mazazo": 50.0, "empuje": 30.0, "raiz": 20.0}
const MULT_MAZAZO := 1.35
const MULT_EMPUJE := 0.65
const MULT_RAIZ := 0.9
const RETROCESO_EMPUJE := 0.20
const RETROCESO_RAIZ := 0.15
const BLOQUEOS := 2                               # golpes parados antes de abrir la guardia
const GOLPE_PESADO := 0.12
const COLOR_MUSGO := Color(0.30, 0.86, 0.76)
const COLOR_ASTILLA := Color(0.62, 0.48, 0.32)
const COLOR_RAIZ := Color(0.36, 0.26, 0.18)
const SONIDOS := {"bloqueo": "velador_bloqueo", "abre": "velador_abre", "carga": "velador_carga",
	"rota": "velador_rota", "derrumbe": "velador_derrumbe"}


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD
		e["defendiendo"] = true                    # empieza en guardia
		e["vl_bloqueos"] = 0


static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


static func grupo_al_azar(cuantos: int) -> int:
	if not activo() or str(Engine.get_meta("zona", "llanura")) != ZONA:
		return -1
	if randf() >= PROB_AL_AZAR:
		return -1
	return int(GRUPOS_POR_TAMANO.get(clampi(cuantos, 1, 3), 25))


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("vl_contador"):
		f["vl_contador"] = {}
	f["vl_contador"][k] = int(f["vl_contador"].get(k, 0)) + 1


static func al_entrar(c, e: Dictionary, p) -> void:
	if not es(e) or p == null or e.get("vl_conectado", false):
		return
	e["vl_conectado"] = true
	if p.has_method("guardia"):
		p.guardia(true)
	if p.has_signal("evento"):
		p.evento.connect(_al_evento.bind(c, e))


static func _al_evento(clip: String, nombre: String, c, e: Dictionary) -> void:
	if nombre == "suelo" and clip == "derrota":
		c._sonar(SONIDOS["derrumbe"])
		c._particulas(c._suelo_de(e), Color(COLOR_ASTILLA, 0.85), Color(COLOR_ASTILLA, 0.0), 18, 1.1, Vector2(40, 140),
			80.0, Vector2(0, -1), 80.0, Vector2(0, 60), 0.18)
		c._temblor(5.0)
	elif nombre == "clava":
		c._particulas(c._suelo_de(e) + Vector2(50, 0), Color(COLOR_RAIZ, 0.9), Color(COLOR_RAIZ, 0.0), 12, 0.6,
			Vector2(30, 120), 30.0, Vector2(0, -1), 60.0, Vector2(0, 200), 0.12)


# ================================================================= lo que se lee

static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	var o = e.get("vl_objetivo", null)
	if e.get("cargando", false) and o is Dictionary and int(o.get("hp", 0)) > 0:
		r.append("⚠ Raíz: %s" % o["nombre"])
	if e.get("vl_aturdido", false):
		r.append("Aturdido")
	elif e.get("vl_abierta", false):
		r.append("Guardia abierta")
	elif e.get("defendiendo", false):
		r.append("Guardia (%d/%d)" % [int(e.get("vl_bloqueos", 0)), BLOQUEOS])
	return r


static func info(e: Dictionary) -> Array:
	if e.get("cargando", false):
		return ["⚠ Prepara la Raíz de umbral: defiéndete o dale fuerte y la cortas"]
	if e.get("vl_aturdido", false):
		return ["Aturdido: pierde su turno"]
	if e.get("vl_abierta", false):
		return ["Guardia abierta: los golpes entran enteros hasta su próximo turno"]
	if e.get("defendiendo", false):
		return ["En guardia: golpes a la mitad; dos golpes le abren la guardia"]
	return []


# ================================================================= su turno

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["vl_turno"] = int(f.get("vl_turno", 0)) + 1
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	var abierta_antes: bool = f.get("vl_abierta", false)
	if f.get("recupera", false):
		await _recuperar(c, f)
	elif f.get("cargando", false):
		await _raiz(c, f, vivos, mult)
	else:
		match _elegir(f):
			"raiz":
				await _avisar(c, f, vivos)
			"empuje":
				await _empuje(c, f, vivos, mult)
			_:
				await _mazazo(c, f, vivos, mult)
	if f["hp"] > 0 and not f.get("cargando", false) and not f.get("recupera", false):
		if abierta_antes or not f.get("vl_abierta", false):
			_guardia(c, f, true)                          # su turno acabó: vuelve a la guardia (la abierta, también)


static func _elegir(f: Dictionary) -> String:
	var pesos := PESOS.duplicate()
	if str(f.get("vl_ultimo", "")) in ["raiz", "aviso"] or int(f.get("vl_turno", 0)) - int(f.get("vl_corte_turno", -10)) <= 1:
		pesos.erase("raiz")
	var total := 0.0
	for k in pesos:
		total += float(pesos[k])
	var r := randf() * total
	for k in ["mazazo", "empuje", "raiz"]:
		if not pesos.has(k):
			continue
		r -= float(pesos[k])
		if r < 0.0:
			return k
	return "mazazo"


static func _guardia(c, f: Dictionary, si: bool) -> void:
	f["defendiendo"] = si
	f["vl_abierta"] = false
	f["vl_bloqueos"] = 0
	var p = c._p3d(f)
	if p != null and p.has_method("guardia"):
		p.guardia(si)
	c._actualizar()


static func _mazazo(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("bruto", vivos))
	c.registro.text = "%s alza la maza de poda contra %s" % [f["nombre"], obj["nombre"]]
	f["vl_ataque"] = "mazazo"
	_contar(f, "mazazo")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_MAZAZO * mult) + randi_range(-2, 2), "")
	f.erase("vl_ataque")
	f["vl_ultimo"] = "mazazo"


static func _empuje(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("bruto", vivos))
	c.registro.text = "%s embiste con el escudo de anillos a %s" % [f["nombre"], obj["nombre"]]
	f["vl_ataque"] = "empuje"
	_contar(f, "empuje")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_EMPUJE * mult) + randi_range(-1, 2), "")
	f.erase("vl_ataque")
	f["vl_ultimo"] = "empuje"


static func _avisar(c, f: Dictionary, vivos: Array) -> void:
	var obj: Dictionary = c._elegir_objetivo("agresivo", vivos)
	_guardia(c, f, false)                                  # clava la maza: sin guardia mientras prepara
	f["cargando"] = true
	f["carga_recibido"] = 0
	f["vl_objetivo"] = obj
	_contar(f, "aviso_raiz")
	c._marcar_aviso(f, true)
	_marcar(c, f, obj)
	var p = c._p3d(f)
	if p != null and p.has_method("cargar"):
		p.cargar()
	c._sonar(SONIDOS["carga"])
	c.registro.text = "%s clava la maza en la tierra y señala a %s: ¡raíces!" % [f["nombre"], obj["nombre"]]
	c._numero_flotante(f, "⚠ ¡Raíz de umbral!", Color(1.0, 0.8, 0.2), 34)
	c._numero_flotante(obj, "⚠ Raíz", COLOR_MUSGO, 28)
	c._actualizar()
	await c.get_tree().create_timer(1.2).timeout
	f["vl_ultimo"] = "aviso"


static func _raiz(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["cargando"] = false
	f.erase("carga_recibido")
	c._marcar_aviso(f, false)
	var marcado = f.get("vl_objetivo", null)
	if not (marcado is Dictionary) or int(marcado["hp"]) <= 0:
		marcado = c._elegir_objetivo("agresivo", vivos)
	_marcar(c, f, null)
	f.erase("vl_objetivo")
	var obj: Dictionary = c._cubre(marcado)
	c.registro.text = "¡Las raíces del umbral atrapan a %s!" % obj["nombre"]
	f["vl_ataque"] = "raiz"
	_contar(f, "raiz")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_RAIZ * mult) + randi_range(-2, 2), "")
	f.erase("vl_ataque")
	f["vl_ultimo"] = "raiz"


static func _recuperar(c, f: Dictionary) -> void:
	f["recupera"] = false
	f["vl_aturdido"] = false
	f.erase("aturdido")
	_contar(f, "recupera")
	c.registro.text = "%s, aturdido, arranca la maza de la tierra" % f["nombre"]
	var p = c._p3d(f)
	if p != null:
		p.reposo()
	c._numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
	c._actualizar()
	await c.get_tree().create_timer(0.8).timeout
	f["vl_ultimo"] = "recupera"


# ================================================================= el golpe recibido (combate.gd _vigilar_carga)

static func vigilar(c, f: Dictionary, d: int) -> void:
	var p = c._p3d(f)
	if p != null and "golpe_pesado" in p:
		p.golpe_pesado = d >= ceili(f["hp_max"] * GOLPE_PESADO)
	if f["hp"] <= 0:
		if f.get("cargando", false):
			f["cargando"] = false
			c._marcar_aviso(f, false)
		_marcar(c, f, null)
		return
	if f.get("defendiendo", false) and not f.get("vl_abierta", false):
		f["vl_bloqueos"] = int(f.get("vl_bloqueos", 0)) + 1
		_contar(f, "bloqueo")
		if f["vl_bloqueos"] >= BLOQUEOS:
			f["defendiendo"] = false
			f["vl_abierta"] = true
			_contar(f, "guardia_abierta")
			var pz = c._p3d(f)
			if pz != null and pz.has_method("guardia"):
				pz.guardia(false)
			c._sonar(SONIDOS["abre"])
			c._numero_flotante(f, "¡Guardia abierta!", Color(1.0, 0.92, 0.45), 32, Vector2(0, -60))
			c.registro.text = "¡El escudo de %s cede! Los golpes entran enteros hasta su próximo turno." % f["nombre"]
			c._particulas(c._centro(f), Color(COLOR_ASTILLA, 0.95), Color(COLOR_ASTILLA, 0.0), 14, 0.7, Vector2(60, 180),
				40.0, Vector2(0, -1), 90.0, Vector2(0, 420), 0.12)
		else:
			c._sonar(SONIDOS["bloqueo"])
		c._actualizar()
		return
	if not f.get("cargando", false):
		return
	if c.golpe_ruptura:
		_aturdir(c, f, "¡Quiebra!", "¡Kael y Garon rompen la Raíz de %s!" % f["nombre"])
		return
	f["carga_recibido"] = int(f.get("carga_recibido", 0)) + d
	if f["carga_recibido"] >= ceili(f["hp_max"] * c.UMBRAL_INTERRUPCION):
		_aturdir(c, f, "¡Interrumpido!", "¡%s pierde la maza y no suelta las raíces!" % f["nombre"])


static func _aturdir(c, f: Dictionary, cartel: String, texto: String) -> void:
	f["cargando"] = false
	f["recupera"] = true
	f["aturdido"] = true
	f["vl_aturdido"] = true
	f["vl_corte_turno"] = int(f.get("vl_turno", 0))
	f.erase("carga_recibido")
	f.erase("vl_objetivo")
	_contar(f, "raiz_cortada")
	c._marcar_aviso(f, false)
	_marcar(c, f, null)
	var p = c._p3d(f)
	if p != null and p.has_method("aturdido"):
		p.aturdido()
	c._sonar(SONIDOS["rota"])
	c._numero_flotante(f, cartel, Color(1.0, 0.92, 0.45), 36, Vector2(0, -60))
	c.registro.text = texto
	c._temblor(3.0)
	c._actualizar()


# ================================================================= animación

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var ataque := str(o.get("vl_ataque", "mazazo"))
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
		_tras_impacto(c, o, obj, ataque)
	var p = c._p3d(o)
	o["defendiendo"] = false                               # atacando no bloquea (el documento)
	if p == null:
		golpe.call()
		await c.get_tree().create_timer(0.5).timeout
	elif ataque == "raiz":
		await _raices(c, o, obj, golpe)
	else:
		await _ir_y_golpear(c, o, obj, golpe, ataque)
	if not hecho[0]:
		golpe.call()


static func _tras_impacto(c, o: Dictionary, obj: Dictionary, ataque: String) -> void:
	if obj["hp"] <= 0 or c.ultimo_esquivado:
		return
	if ataque == "empuje":
		c._onda(c._centro(obj), COLOR_ASTILLA, 20.0, 110.0, 0.4, 6.0)
		retroceso(c, obj, RETROCESO_EMPUJE)
	elif ataque == "raiz":
		retroceso(c, obj, RETROCESO_RAIZ)
	elif ataque == "mazazo":
		c._particulas(c._centro(obj), Color(COLOR_ASTILLA, 1.0), Color(COLOR_ASTILLA, 0.0), 10, 0.5, Vector2(60, 180),
			40.0, Vector2(0, -1), 120.0, Vector2(0, 420), 0.08)
		c._temblor(4.0)


# El empuje / la lentitud en el ATB (como el Retroceso del Peón): quien lo recibe sin defender pierde parte de su barra;
# nunca quien ya está en la cola de turnos.
static func retroceso(c, h: Dictionary, fraccion: float) -> bool:
	if h["hp"] <= 0 or h.get("defendiendo", false) or float(h.get("atb", 0.0)) >= c.ATB_MAX:
		return false
	for x in c.cola:
		if is_same(x, h):
			return false
	h["atb"] = maxf(0.0, float(h["atb"]) - c.ATB_MAX * fraccion)
	c._numero_flotante(h, "Retroceso", COLOR_ASTILLA, 26, Vector2(30, -30))
	return true


# Anda (pesado) hasta el héroe, el clip con su impacto, y vuelve.
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
	p.mirar(ida, 0.2)
	p.correr()
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", destino, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	Sonido.voz(o, "ataque")
	if ataque == "empuje" and p.has_method("empuje"):
		await p.empuje(golpe)
	elif p.has_method("mazazo"):
		await p.mazazo(golpe)
	else:
		await p.atacar_hacha(golpe)
	golpe.call()
	if o["hp"] > 0:
		p.mirar(-ida, 0.25)
		p.correr()
		var t3: Tween = c.create_tween()
		t3.tween_property(rig, "position", base, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t3.finished
		p.mirar_frente(0.3)
		if o.get("recupera", false) and p.has_method("aturdido"):
			p.aturdido()
		else:
			p.reposo()
	rig.z_index = 0
	o["animando"] = false


# A3: desde su sitio; en el impacto del clip brotan tres raíces bajo el héroe (el daño, entonces).
static func _raices(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	o["animando"] = true
	p.mirar(Vector3(1, 0, 0.25), 0.2)
	Sonido.voz(o, "ataque")
	var al_brotar := func():
		_brotar(c, c._suelo_de(obj))
		golpe.call()
		c._temblor(4.0)
	if p.has_method("raiz"):
		await p.raiz(al_brotar)
	else:
		await p.atacar_hacha(al_brotar)
	if o["hp"] > 0:
		p.mirar_frente(0.25)
		p.reposo()
	o["animando"] = false


# Tres raíces rígidas que emergen y se hunden (0,6 s) bajo el héroe: polígonos dibujados, un nodo.
static func _brotar(c, pie: Vector2) -> void:
	var n := Node2D.new()
	n.z_index = 6
	n.position = pie
	c.escena.add_child(n)
	var alto := [0.0]
	n.draw.connect(func():
		for k in 3:
			var x := -46.0 + 46.0 * k
			var h: float = alto[0] * (110.0 if k == 1 else 80.0)
			var pts := PackedVector2Array([Vector2(x - 14, 6), Vector2(x - 4, -h * 0.6), Vector2(x + 2, -h),
				Vector2(x + 8, -h * 0.55), Vector2(x + 14, 6)])
			n.draw_colored_polygon(pts, COLOR_RAIZ)
			n.draw_polyline(pts, Color(COLOR_MUSGO, 0.9), 2.0))
	var t: Tween = c.create_tween()
	t.tween_method(func(k: float):
		alto[0] = sin(k * PI)
		if is_instance_valid(n):
			n.queue_redraw(), 0.0, 1.0, 0.6)
	t.tween_callback(n.queue_free)


# ================================================================= la marca

static func _marcar(c, f: Dictionary, obj) -> void:
	var antes = f.get("vl_marca", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("vl_marca")
	if obj == null:
		return
	var s = c._sena_arte("aviso", obj, {"dur": 9999.0, "color": COLOR_MUSGO})
	s.position = c._centro(obj) + Vector2(0, -150)
	f["vl_marca"] = s


static func repasar(f: Dictionary) -> void:
	var m = f.get("vl_marca", null)
	if m == null:
		return
	var o = f.get("vl_objetivo", null)
	if int(f["hp"]) <= 0 or not (o is Dictionary) or int(o.get("hp", 0)) <= 0:
		if is_instance_valid(m):
			m.queue_free()
		f.erase("vl_marca")


static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if not es(e):
			continue
		var n = e.get("vl_marca", null)
		if n != null and is_instance_valid(n):
			n.queue_free()
		e.erase("vl_marca")
