extends RefCounted
# V12, enemigos (12/11/2026): el Gólem de ámbar, «el Guardián del Nido», con su modelo propio y su forma de luchar.
# APAGADO: solo con el interruptor «enemigos_v12» (el de los modelos propios de la fase C: combate.gd ENEMIGOS_V12).
# Encendido, el Gólem del nido de la Garganta (GRUPOS[6], con Grimfang, combate fijo «garganta_nido»: donde ya salía)
# deja la personalidad «bruto» y lucha con esta; sus combates de prueba (GRUPOS[20] y [21], «-- grupo=20 enemigos_v12»)
# sirven para 1, 2 y 3 héroes. Apagado, Golem.es() es falso para todos y el combate es el de siempre.
# Modelo y clips: enemigos/golem_ambar/ (golem_ambar_v2.glb; guion fuente/crear_golem_ambar.py con «v2»).
# Informe: docs/memory/agents/combate_v12_enemigos.md.
#
# Papel: élite de mazmorra (el que guarda el nido); ancho, pesado; inmune al Rayo, débil al Hielo y resiste el Fuego
# (combate_afinidades.gd, sin tocar). Vida, ataque, premios y escalado, los de ENEMIGOS["golem_ambar"]. Tres acciones,
# cada una con preparación, ejecución, impacto y recuperación, y su respuesta con lo que ya existe:
#   · Puñetazo (a uno al azar, ×1,0 con la fuerza bruta de siempre: ×0,9-1,3): alza el puño y lo descarga.
#   · Terrón de ámbar (a distancia, ×1,1): arranca un terrón del nido de su espalda (se oye crujir la resina), se echa
#     atrás y lo lanza por encima del hombro A LA RETAGUARDIA (la curandera si ha curado; si no, quien menos vida
#     tenga). No se acerca: el terrón vuela y el daño cae AL LLEGAR. Defender lo deja a la mitad y la Guardia de Garon
#     se lo lleva él. Nunca dos seguidos.
#   · Pisotón (aviso un turno): «levanta los puños» y sale «⚠ ¡Pisotón!» sobre él. Su turno siguiente salta y cae con
#     los dos pies y los dos puños: a todos ×1,0, todos en el impacto (onda de polvo). Después recupera el aliento un
#     turno (la ventana). Se corta como en la V11: un cuarto de su vida mientras carga o Quiebra → aturdido, pierde el
#     turno. Defender lo deja a la mitad.
# Sonido (sonido.gd, «golem_ambar_*» y «golem_*», WAV de audio/efectos/golem/): cada uno una vez y en su instante.

const CLAVE := "golem_ambar"
const PERSONALIDAD := "golem_nido"
const INTERRUPTOR := "enemigos_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPO_SOLO := 20                    # combate.gd GRUPOS: sus combates de prueba (no salen al azar)
const GRUPO_CON_SLIME := 21
const MULT_PUNO := 1.0
const MULT_TERRON := 1.1
const MULT_PISOTON := 1.0
const PROB_PISOTON := 0.3
const PROB_TERRON := 0.4
const GOLPE_PESADO := 0.12
const VUELO_S := 0.35                     # lo que tarda el terrón en llegar
const COLOR_AMBAR := Color(1.0, 0.68, 0.18)
const COLOR_POLVO := Color(0.82, 0.70, 0.50)
const SONIDOS := {"terron": "golem_terron", "agarra": "golem_agarra", "carga": "golem_carga", "rota": "golem_rota",
	"derrumbe": "golem_derrumbe"}


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD


static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("gn_contador"):
		f["gn_contador"] = {}
	f["gn_contador"][k] = int(f["gn_contador"].get(k, 0)) + 1


static func al_entrar(c, e: Dictionary, p) -> void:
	if not es(e) or p == null or not p.has_signal("evento") or e.get("gn_conectado", false):
		return
	e["gn_conectado"] = true
	p.evento.connect(_al_evento.bind(c, e))


static func _al_evento(clip: String, nombre: String, c, e: Dictionary) -> void:
	if nombre == "agarra" and clip == "lanzar":
		c._sonar(SONIDOS["agarra"])
		c._particulas(c._centro(e) + Vector2(20, -90), Color(COLOR_AMBAR, 0.95), Color(COLOR_AMBAR, 0.0), 10, 0.6,
			Vector2(20, 80), 30.0, Vector2(0, -1), 120.0, Vector2(0, 200), 0.1)
	elif nombre == "suelo" and clip == "derrota":
		c._sonar(SONIDOS["derrumbe"])
		c._particulas(c._suelo_de(e), Color(COLOR_POLVO, 0.85), Color(COLOR_POLVO, 0.0), 20, 1.2, Vector2(40, 140), 80.0,
			Vector2(0, -1), 80.0, Vector2(0, 60), 0.2)
		c._temblor(7.0)


# ================================================================= lo que se lee

static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("cargando", false):
		r.append("⚠ Pisotón")
	if e.get("gn_aturdido", false):
		r.append("Aturdido")
	elif e.get("recupera", false):
		r.append("Sin aliento")
	return r


static func info(e: Dictionary) -> Array:
	if e.get("cargando", false):
		return ["⚠ Prepara el Pisotón a todos: defiéndete o dale fuerte y lo cortas"]
	if e.get("gn_aturdido", false):
		return ["Aturdido: pierde su turno"]
	if e.get("recupera", false):
		return ["Sin aliento: no ataca en su turno siguiente"]
	return []


# ================================================================= su turno (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["gn_turno"] = int(f.get("gn_turno", 0)) + 1
	if f.get("recupera", false):
		await _recuperar(c, f)
		return
	if f.get("cargando", false):
		await _pisoton(c, f, vivos, mult)
		return
	var ultimo := str(f.get("gn_ultimo", ""))
	var pp: float = PROB_PISOTON + (c.ELITE["prob_patron"] if f.get("elite", false) else 0.0)
	var r := randf()
	if r < pp:
		await _avisar(c, f)
	elif ultimo != "terron" and r < pp + PROB_TERRON:
		await _terron(c, f, vivos, mult)
	else:
		await _puno(c, f, vivos, mult)


static func _puno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("bruto", vivos))
	c.registro.text = "%s descarga el puño contra %s" % [f["nombre"], obj["nombre"]]
	f["gn_ataque"] = "puno"
	f["gn_resto"] = []
	_contar(f, "puno")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_PUNO * mult * randf_range(0.9, 1.3)) + randi_range(-2, 3), "")
	f.erase("gn_ataque")
	f["gn_ultimo"] = "puno"


static func _terron(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))   # la curandera; si no, el más débil
	c.registro.text = "%s arranca un terrón de ámbar del nido y lo lanza contra %s" % [f["nombre"], obj["nombre"]]
	c._numero_flotante(f, "¡Terrón!", COLOR_AMBAR, 30)
	f["gn_ataque"] = "terron"
	f["gn_resto"] = []
	_contar(f, "terron")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_TERRON * mult) + randi_range(-2, 3), "")
	f.erase("gn_ataque")
	f["gn_ultimo"] = "terron"


static func _avisar(c, f: Dictionary) -> void:
	f["cargando"] = true
	f["carga_recibido"] = 0
	_contar(f, "aviso_pisoton")
	c._marcar_aviso(f, true)
	var p = c._p3d(f)
	if p != null and p.has_method("cargar"):
		p.cargar()
	c._sonar(SONIDOS["carga"])
	c.registro.text = "%s levanta los puños: ¡va a golpear a todos!" % f["nombre"]
	c._numero_flotante(f, "⚠ ¡Pisotón!", Color(1.0, 0.8, 0.2), 34)
	c._actualizar()
	await c.get_tree().create_timer(1.2).timeout
	f["gn_ultimo"] = "aviso"


static func _pisoton(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["cargando"] = false
	f.erase("carga_recibido")
	c._marcar_aviso(f, false)
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	var principal: Dictionary = c._cubre(vivos[int(vivos.size() / 2.0)], false)
	var resto: Array = []
	for h0 in vivos:
		if not is_same(h0, principal):
			resto.append(h0)
	var dano := int(f["atk"] * MULT_PISOTON * mult)
	c.registro.text = "¡%s da un pisotón que alcanza a todos!" % f["nombre"]
	f["gn_ataque"] = "pisoton"
	f["gn_resto"] = resto
	f["gn_dano_resto"] = dano
	_contar(f, "pisoton")
	await c._animar_golpe(f, principal, dano + randi_range(-2, 3), "")
	f.erase("gn_ataque")
	f["gn_resto"] = []
	f["gn_ultimo"] = "pisoton"
	if f["hp"] > 0:
		f["recupera"] = true                              # la ventana: su turno siguiente recupera el aliento
		c._actualizar()


static func _recuperar(c, f: Dictionary) -> void:
	var aturdido: bool = f.get("gn_aturdido", false)
	f["recupera"] = false
	f["gn_aturdido"] = false
	f.erase("aturdido")
	_contar(f, "recupera")
	c.registro.text = ("%s, aturdido, se sacude la resina" if aturdido else "%s recupera el aliento") % f["nombre"]
	var p = c._p3d(f)
	if p != null:
		p.reposo()
	c._numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
	c._actualizar()
	await c.get_tree().create_timer(0.8).timeout
	f["gn_ultimo"] = "recupera"


# ================================================================= el golpe recibido (combate.gd _vigilar_carga)

static func vigilar(c, f: Dictionary, d: int) -> void:
	var p = c._p3d(f)
	if p != null and "golpe_pesado" in p:
		p.golpe_pesado = d >= ceili(f["hp_max"] * GOLPE_PESADO)
	if f["hp"] <= 0 or not f.get("cargando", false):
		return
	if c.golpe_ruptura:
		_aturdir(c, f, "¡Quiebra!", "¡Kael y Garon rompen el Pisotón de %s!" % f["nombre"])
		return
	f["carga_recibido"] = int(f.get("carga_recibido", 0)) + d
	if f["carga_recibido"] >= ceili(f["hp_max"] * c.UMBRAL_INTERRUPCION):
		_aturdir(c, f, "¡Interrumpido!", "¡%s pierde el equilibrio y no suelta el Pisotón!" % f["nombre"])


static func _aturdir(c, f: Dictionary, cartel: String, texto: String) -> void:
	f["cargando"] = false
	f["recupera"] = true
	f["aturdido"] = true
	f["gn_aturdido"] = true
	f.erase("carga_recibido")
	_contar(f, "pisoton_cortado")
	c._marcar_aviso(f, false)
	var p = c._p3d(f)
	if p != null and p.has_method("aturdido"):
		p.aturdido()
	c._sonar(SONIDOS["rota"])
	c._numero_flotante(f, cartel, Color(1.0, 0.92, 0.45), 36, Vector2(0, -60))
	c.registro.text = texto
	c._particulas(c._centro(f) + Vector2(0, -60), Color(COLOR_AMBAR, 0.95), Color(COLOR_AMBAR, 0.0), 14, 0.8,
		Vector2(60, 180), 40.0, Vector2(0, -1), 70.0, Vector2(0, 420), 0.12)
	c._temblor(4.0)
	c._actualizar()


# ================================================================= animación (combate.gd _animar_golpe)

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var ataque := str(o.get("gn_ataque", "puno"))
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
		_golpear_resto(c, o, obj, ataque)
	var p = c._p3d(o)
	if p == null:                                          # el respaldo 2D: su animación de siempre
		if c._es_sprite(o):
			await c._anim_fisico_sprite(o, obj, golpe)
		elif c.MODELOS[o["modelo"]].get("tipo", "") == "imagen":
			await c._anim_fisico_imagen(o, obj, golpe)
		else:
			golpe.call()
			await c.get_tree().create_timer(0.5).timeout
	elif ataque == "terron":
		await _lanzar(c, o, obj, golpe)
	else:
		await _ir_y_golpear(c, o, obj, golpe, ataque)
	if not hecho[0]:
		golpe.call()


static func _golpear_resto(c, o: Dictionary, obj: Dictionary, ataque: String) -> void:
	if ataque == "pisoton":
		var y: float = c._suelo_de(obj).y
		c._onda(Vector2(c._suelo_de(obj).x, y), COLOR_POLVO, 40.0, 320.0, 0.8, 12.0)
		c._particulas(c._suelo_de(obj), Color(COLOR_POLVO, 0.9), Color(COLOR_POLVO, 0.0), 24, 1.0, Vector2(80, 240), 90.0,
			Vector2(0, -1), 70.0, Vector2(0, 160), 0.18)
		c._temblor(10.0)
	var resto: Array = o.get("gn_resto", [])
	var dano := int(o.get("gn_dano_resto", 0))
	for h0 in resto:
		if h0["hp"] <= 0:
			continue
		var h: Dictionary = c._cubre(h0, false)
		if h["hp"] <= 0:
			continue
		var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
		if h.get("defendiendo", false):
			d2 = maxi(1, int(d2 * 0.5))
		c._golpe_visual(h, c._quitar_pv(h, d2), "")


# El Terrón: desde su sitio, mira al héroe, el clip «lanzar» y, al soltar, el terrón vuela; el daño, al llegar.
static func _lanzar(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	o["animando"] = true
	p.mirar(Vector3(1, 0, 0.25), 0.2)
	Sonido.voz(o, "ataque")
	var llego := [false]
	var al_soltar := func():
		var desde: Vector2 = _pantalla_mano(c, o)
		_volar(c, desde, c._centro(obj), func():
			c._sonar(SONIDOS["terron"])
			c._particulas(c._centro(obj), Color(COLOR_AMBAR, 1.0), Color(COLOR_AMBAR, 0.0), 18, 0.7, Vector2(80, 220),
				30.0, Vector2(0, -1), 160.0, Vector2(0, 500), 0.12)
			golpe.call()
			c._temblor(5.0)
			llego[0] = true)
	if p.has_method("lanzar"):
		await p.lanzar(al_soltar)
	else:
		await p.atacar_hacha(al_soltar)
	var t0 := 0
	while not llego[0] and t0 < 60:                          # (el terrón aún en el aire: espera a que llegue)
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
		return c._centro(o) + Vector2(30, -100)
	var cam: Camera3D = o["cam3d"]
	var spr: Sprite2D = o["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(cam.unproject_position(p.punto_mano())))


# El terrón en vuelo: un trozo facetado de ámbar con su brillo, en arco, girando (un nodo, 0,35 s).
static func _volar(c, desde: Vector2, hasta: Vector2, al_llegar: Callable) -> void:
	var n := Node2D.new()
	n.z_index = 7
	n.position = desde
	c.escena.add_child(n)
	n.draw.connect(func():
		n.draw_circle(Vector2.ZERO, 30.0, Color(COLOR_AMBAR, 0.25))
		var pts := PackedVector2Array()
		for i in 6:
			var a := TAU * i / 6.0
			pts.append(Vector2(cos(a), sin(a)) * (16.0 if i % 2 == 0 else 12.0))
		n.draw_colored_polygon(pts, COLOR_AMBAR)
		n.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.92, 0.6), 2.0))
	var t: Tween = c.create_tween()
	t.tween_method(func(k: float):
		if not is_instance_valid(n):
			return
		n.position = desde.lerp(hasta, k) + Vector2(0, -sin(k * PI) * 90.0)
		n.rotation = k * TAU * 1.5, 0.0, 1.0, VUELO_S)
	t.tween_callback(func():
		if is_instance_valid(n):
			n.queue_free()
		al_llegar.call())


# Corre hasta el héroe, el clip con su impacto y vuelve (como combate.gd _anim_ataque_3d).
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
	if ataque == "pisoton":
		await p.golpe_fuerte(golpe)
	else:
		await p.atacar_hacha(golpe)
	golpe.call()
	if o["hp"] > 0:
		p.mirar(-ida, 0.2)
		p.correr()
		var t3: Tween = c.create_tween()
		t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t3.finished
		p.mirar_frente(0.25)
		if o.get("gn_aturdido", false) and p.has_method("aturdido"):
			p.aturdido()
		else:
			p.reposo()
	rig.z_index = 0
	o["animando"] = false
