extends RefCounted
# V12 (12/11/2026): Humbaba, el Corazón del Bosque Muerto, en el combate ATB (combate.gd). JEFE NUEVO Y APAGADO: no sale
# en ningún encuentro salvo con el interruptor «humbaba_v12» (Engine.set_meta o «-- humbaba_v12»: el santuario del Gran
# Bosque Verde, zonas3d/gran_bosque_3d.gd) o en su combate de prueba (GRUPOS[17] de combate.gd: «-- grupo=17»). No
# sustituye al Guardián del Bosque ni cambia el canon. Modelo y clips: enemigos/humbaba/ (fuente/crear_humbaba.py).
# Informe: docs/memory/agents/animaciones_v12_humbaba.md. Nombres de fases y ataques: los del encargo del usuario.
#
# Cómo funciona (todo en el diccionario del luchador, «hb_*»; nada se guarda en la partida):
#   - Una máquina de estados por turno suyo: cambio de fase pendiente → transformación (su acción del turno);
#     vulnerable → se pone en pie; Réquiem cargado → lo descarga; si no, el ataque que toca en el ciclo de su fase.
#   - Fases por vida (UMBRALES, ajustables): 1 «El Guardián Despierta» (Puño, Raíces, Guadaña; punto débil: el núcleo,
#     que queda AL ALCANCE tras el Puño), 2 «El Bosque Enfermo» (el núcleo se agrieta y se vuelve verde; añade el
#     Aliento, el Ojo del Juicio y la Llamada), 3 «Corazón del Abismo» (la armadura se rompe: los golpes ya no se frenan;
#     el Abrazo, los combinados y el Réquiem del Bosque Eterno, avisado un turno antes y que lo deja vulnerable).
#   - Cada ataque (ATAQUES): su clip, su evento de impacto (el daño llega en ese instante del clip, no al acabar),
#     multiplicador, objetivos, estado, efectos, sonido, fases y cómo se contrarresta.
#   - Defensa: la corteza frena los golpes físicos (×0,8) en las fases 1 y 2; el fuego le hace ×1,4 (es madera);
#     núcleo al alcance ×1,4 a los golpes; vulnerable tras el Réquiem ×1,6 a todo.
# Sonido: reutiliza efectos que el juego ya tiene (el Guardián del Bosque, la corteza, el jefe; sonido.gd), con su
# licencia ya registrada: no añade audio nuevo. Una identidad sonora propia queda pendiente.

const CLAVE := "humbaba"
const INTERRUPTOR := "humbaba_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPO := 17                              # combate.gd GRUPOS[17]
const COMBATE := "gran_bosque_humbaba"         # combate fijo (desde el santuario del Gran Bosque)
const UMBRALES := [0.70, 0.35]                 # vida a la que empiezan las fases 2 y 3
const NOMBRES_FASE := {1: "El Guardián Despierta", 2: "El Bosque Enfermo", 3: "Corazón del Abismo"}
const CICLOS := {
	1: ["puno", "raices", "guadana", "puno", "guadana", "raices"],
	2: ["aliento", "puno", "ojo", "llamada", "raices", "guadana", "ojo"],
	3: ["abrazo", "combo_raices", "requiem", "ojo", "combo_guadana", "aliento", "requiem"],
}
const MULT_CORTEZA := 0.8
const MULT_FUEGO := 1.4
const MULT_NUCLEO := 1.4
const MULT_VULNERABLE := 1.6
const COMBO := 0.7                             # cada golpe de un combinado
const INVOCADO := "zarzalin"                   # los condenados: criaturas del bosque que ya tiene el juego
const TOPE_INVOCADOS := 2
const RAICES_TURNOS := 1                       # turnos que pierde quien queda atrapado por las raíces
const CORRUPCION_TURNOS := 3
const CORRUPCION_PCT := 0.06                   # de su vida máxima, al empezar cada turno suyo (no le deja por debajo de 1)
const PROB_LIBERARSE := 0.35                   # Abrazo: + 0,35 si defendía; la Guardia de Garon se lleva el agarre
const MAX_RAICES_ARENA := 9                    # tope de raíces dibujadas por el Réquiem (y de troncos)
const COLOR_TURQUESA := Color(0.35, 1.0, 0.86)
const COLOR_ENFERMO := Color(0.66, 0.95, 0.35)
const COLOR_AVISO := Color(1.0, 0.82, 0.3)
const ATAQUES := {
	"puno": {"nombre": "Puño del Bosque Primordial", "clip": "atk_puno", "mult": 1.5, "objetivos": "zona", "fases": [1, 2, 3],
		"estado": "", "sonido": "guardian_bosque_golpe", "contra": "Solo alcanza la zona marcada; Defender, a la mitad. Deja el núcleo al alcance"},
	"raices": {"nombre": "Raíces Devoradoras", "clip": "atk_raices", "mult": 0.8, "objetivos": "todos", "fases": [1, 2, 3],
		"estado": "raices", "sonido": "guardian_bosque_ataque", "contra": "Defender evita quedar atrapado y deja el daño a la mitad"},
	"guadana": {"nombre": "Guadaña de Raíces", "clip": "atk_guadana", "mult": 1.0, "objetivos": "todos", "fases": [1, 2, 3],
		"estado": "", "sonido": "corteza_ataque", "contra": "Defender, a la mitad"},
	"aliento": {"nombre": "Aliento de la Putrefacción", "clip": "atk_aliento", "mult": 0.55, "objetivos": "todos", "fases": [2, 3],
		"estado": "corrupcion", "sonido": "guardian_bosque_carga", "contra": "Defender evita la corrupción; curar la limpia"},
	"ojo": {"nombre": "El Ojo del Juicio", "clip": "atk_ojo", "mult": 2.1, "objetivos": "uno", "fases": [2, 3],
		"estado": "", "sonido": "carga_jefe", "contra": "La carga se ve venir: Defender, a la mitad; la Guardia de Garon lo para"},
	"llamada": {"nombre": "Llamada de los Condenados", "clip": "atk_llamada", "mult": 0.0, "objetivos": "invoca", "fases": [2, 3],
		"estado": "", "sonido": "guardian_bosque_fase2", "contra": "Como mucho %d a la vez; caen con él" % TOPE_INVOCADOS},
	"abrazo": {"nombre": "Abrazo de la Muerte", "clip": "atk_abrazo", "mult": 0.9, "objetivos": "uno", "fases": [3],
		"estado": "agarre", "sonido": "corteza_ataque", "contra": "Puede soltarse entre los dos aprietos (más fácil defendiendo); la Guardia de Garon"},
	"requiem": {"nombre": "Réquiem del Bosque Eterno", "clip": "requiem_golpe", "mult": 2.0, "objetivos": "todos", "fases": [3],
		"estado": "", "sonido": "guardian_bosque_derrumbe", "contra": "Se avisa un turno antes: Defender, a la mitad. Después queda vulnerable"},
}


# ¿Está encendido? «-- humbaba_v12» o Engine.set_meta("humbaba_v12", true).
static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


static func es(f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE


static func fase_de(f: Dictionary) -> int:
	return int(f.get("hb_fase", 1))


# La fase que le toca por su vida (la transformación se hace al empezar su turno siguiente).
static func fase_por_vida(f: Dictionary) -> int:
	var r := float(f["hp"]) / maxf(1.0, float(f["hp_max"]))
	if r <= UMBRALES[1]:
		return 3
	if r <= UMBRALES[0]:
		return 2
	return 1


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("hb_contador"):
		f["hb_contador"] = {}
	f["hb_contador"][k] = int(f["hb_contador"].get(k, 0)) + 1


# ================================================================= daño que recibe (combate.gd, junto a los demás)

static func dano_recibido(dano: int, magia: String, _origen: Dictionary, objetivo: Dictionary) -> int:
	if not es(objetivo):
		return dano
	var m := 1.0
	if objetivo.get("hb_vulnerable", false):
		m *= MULT_VULNERABLE
	if magia == "":
		if objetivo.get("hb_nucleo", false):
			m *= MULT_NUCLEO
		elif fase_de(objetivo) < 3 and not objetivo.get("hb_vulnerable", false):
			m *= MULT_CORTEZA
	elif magia == "Fuego":
		m *= MULT_FUEGO
	if is_equal_approx(m, 1.0):
		return dano
	return maxi(1, int(round(dano * m)))


static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	r.append("Fase %d" % fase_de(e))
	if e.get("hb_vulnerable", false):
		r.append("¡Vulnerable!")
	elif e.get("hb_nucleo", false):
		r.append("¡Núcleo al alcance!")
	elif fase_de(e) < 3:
		r.append("Corteza")
	if e.get("hb_requiem", false):
		r.append("⚠ Réquiem")
	return r


static func info(e: Dictionary) -> Array:
	var t: Array = ["%s (fase %d)" % [NOMBRES_FASE[fase_de(e)], fase_de(e)]]
	if e.get("hb_vulnerable", false):
		t.append("¡Vulnerable! Todo ×1,6")
	elif e.get("hb_nucleo", false):
		t.append("Núcleo al alcance: golpes ×1,4")
	elif fase_de(e) < 3:
		t.append("Corteza: golpes ×0,8; el fuego ×1,4")
	else:
		t.append("Sin corteza; el fuego ×1,4")
	if e.get("hb_requiem", false):
		t.append("⚠ Réquiem del Bosque Eterno: ¡defendeos!")
	return t


static func aviso_turno(enemigos: Array) -> String:
	for e in enemigos:
		if es(e) and e["hp"] > 0 and e.get("hb_requiem", false):
			return "⚠ %s prepara el Réquiem del Bosque Eterno: ¡defendeos!" % e["nombre"]
	return ""


# ================================================================= estados de los héroes (combate.gd _siguiente_turno)

# Al empezar el turno de un héroe: la corrupción le quita vida y, si las raíces le tienen, pierde el turno (true).
static func tic_heroe(c, h: Dictionary) -> bool:
	if int(h.get("hb_corrupcion", 0)) > 0:
		h["hb_corrupcion"] = int(h["hb_corrupcion"]) - 1
		var d := maxi(1, int(h["hp_max"] * CORRUPCION_PCT))
		d = mini(d, int(h["hp"]) - 1)
		if d > 0:
			c._quitar_pv(h, d)
			c._numero_flotante(h, "%d" % d, COLOR_ENFERMO, 30)
		c._particulas(c._centro(h), Color(0.6, 0.9, 0.3, 0.8), Color(0.3, 0.5, 0.1, 0.0), 12, 0.8, Vector2(20, 60), 30.0,
			Vector2(0, -1), 40.0, Vector2(0, -60), 0.12)
		if h["hb_corrupcion"] <= 0:
			h.erase("hb_corrupcion")
			c._numero_flotante(h, "Sin corrupción", Color(0.85, 0.95, 0.8), 24, Vector2(0, -40))
	if int(h.get("hb_raices", 0)) > 0:
		h["hb_raices"] = int(h["hb_raices"]) - 1
		h["atb"] = 0.0
		c.actor = null
		c.registro.text = "Las raíces sujetan a %s: pierde el turno" % h["nombre"]
		c._numero_flotante(h, "¡Atrapado!", Color(0.7, 0.55, 0.35), 30)
		if h["hb_raices"] <= 0:
			h.erase("hb_raices")
			_quitar_nodo(h, "hb_raiz_nodo")
		c._actualizar()
		return true
	return false


# Curar limpia la corrupción (combate.gd _aplicar_cura llama aquí; sin ella, nada).
static func al_curar(h: Dictionary) -> void:
	h.erase("hb_corrupcion")


static func estados_heroe(h: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if int(h.get("hb_raices", 0)) > 0:
		r.append("Raíces")
	if int(h.get("hb_corrupcion", 0)) > 0:
		r.append("Corrupción %d" % int(h["hb_corrupcion"]))
	return r


# ================================================================= su turno (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	if not f.has("hb_fase"):
		f["hb_fase"] = 1
		f["hb_paso"] = {1: 0, 2: 0, 3: 0}
	var p = c._p3d(f)
	if f.get("hb_nucleo", false):                         # el núcleo vuelve a cubrirse al empezar su turno
		f["hb_nucleo"] = false
		c._marcar_puntos(f, false)
	var nueva := fase_por_vida(f)
	if nueva > fase_de(f) and not f.get("hb_requiem", false):
		await _cambiar_fase(c, f, nueva)
		return
	if f.get("hb_vulnerable", false):
		await _recuperarse(c, f)
		return
	if f.get("hb_requiem", false):
		await _requiem_descarga(c, f, vivos, mult)
		return
	var fase := fase_de(f)
	var ciclo: Array = CICLOS[fase]
	var i: int = int(f["hb_paso"][fase]) % ciclo.size()
	f["hb_paso"][fase] = i + 1
	var que: String = ciclo[i]
	if que == "llamada" and _invocados_vivos(c) >= TOPE_INVOCADOS:
		que = "ojo"                                       # (tope: si ya están, el Ojo)
	f["hb_ultimo"] = que
	_contar(f, que)
	match que:
		"puno":
			await _puno(c, f, vivos, mult, 1.0)
		"raices":
			await _raices(c, f, vivos, mult, 1.0)
		"guadana":
			await _guadana(c, f, vivos, mult, 1.0)
		"aliento":
			await _aliento(c, f, vivos, mult)
		"ojo":
			await _ojo(c, f, vivos, mult)
		"llamada":
			await _llamada(c, f)
		"abrazo":
			await _abrazo(c, f, vivos, mult)
		"combo_raices":                                    # combinados de la fase 3: dos ataques seguidos, ×0,7
			c.registro.text = "¡%s encadena sus golpes!" % f["nombre"]
			await _raices(c, f, vivos, mult, COMBO)
			if f["hp"] > 0 and _vivos(c).size() > 0:
				await _puno(c, f, _vivos(c), mult, COMBO)
		"combo_guadana":
			c.registro.text = "¡%s encadena sus golpes!" % f["nombre"]
			await _guadana(c, f, vivos, mult, COMBO)
			if f["hp"] > 0 and _vivos(c).size() > 0:
				await _raices(c, f, _vivos(c), mult, COMBO)
		"requiem":
			await _requiem_aviso(c, f)


static func _vivos(c) -> Array:
	return c.heroes.filter(func(h): return h["hp"] > 0)


static func _invocados_vivos(c) -> int:
	return c.enemigos.filter(func(e): return e.get("hb_invocado", false) and e["hp"] > 0 and not e.get("huido", false)).size()


# Golpe a un héroe (lo que hace combate.gd en los ataques a todos del Coloso): defensa, Defender, daño y su golpe.
static func _golpear(c, h: Dictionary, base: int, defendido_mitad := true) -> int:
	if h["hp"] <= 0:
		return 0
	var d: int = maxi(1, base + randi_range(-2, 3) - int(h.get("def", 0) / 2.0))
	if defendido_mitad and h.get("defendiendo", false):
		d = maxi(1, int(d * 0.5))
	var real: int = c._quitar_pv(h, d)
	c._golpe_visual(h, real, "")
	return real


# ---------------------------------------------------------------- 1 · Puño del Bosque Primordial

static func _puno(c, f: Dictionary, vivos: Array, mult: float, k: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
	var zona: Array = [obj]                                # la zona: el objetivo y el héroe más cercano a él
	var cerca = null
	for h in vivos:
		if is_same(h, obj) or h["hp"] <= 0:
			continue
		if cerca == null or c._centro(h).distance_to(c._centro(obj)) < c._centro(cerca).distance_to(c._centro(obj)):
			cerca = h
	if cerca != null and c._centro(cerca).distance_to(c._centro(obj)) < 260.0:
		zona.append(cerca)
	c.registro.text = "%s alza el Puño del Bosque Primordial sobre %s" % [f["nombre"], " y ".join(zona.map(func(h): return h["nombre"]))]
	var base := int(f["atk"] * ATAQUES["puno"]["mult"] * mult * k)
	var marcas: Array = []
	var al_evento := func(ev: String):
		if ev == "aviso":
			for h in zona:
				marcas.append(_zona_suelo(c, h, COLOR_AVISO))
	var impacto := func():
		c._sonar(ATAQUES["puno"]["sonido"])
		Sonido.golpe(true)
		c._temblor(14.0)
		var pm := pantalla(c, f, "mano_i")
		_onda(c, pm, Color(0.8, 0.7, 0.5), 260.0, 0.5)
		c._particulas(pm, Color(0.6, 0.5, 0.38, 0.9), Color(0.4, 0.33, 0.25, 0.0), 30, 0.9, Vector2(80, 260), 40.0,
			Vector2(0, -1), 60.0, Vector2(0, 500), 0.16)
		for h in zona:
			_golpear(c, h, base)
		for m in marcas:
			_quitar(m)
		c._actualizar()
	await _atacar(c, f, "puno", impacto, al_evento)
	for m in marcas:
		_quitar(m)
	if f["hp"] > 0:                                        # el núcleo queda al alcance hasta su turno siguiente
		f["hb_nucleo"] = true
		_contar(f, "nucleo")
		c._marcar_puntos(f, true)
		c._numero_flotante(f, "¡Núcleo al alcance!", COLOR_TURQUESA, 32)
		c._actualizar()


# ---------------------------------------------------------------- 2 · Raíces Devoradoras (objetos aparte bajo cada héroe)

static func _raices(c, f: Dictionary, vivos: Array, mult: float, k: float) -> void:
	c.registro.text = "%s hunde la garra: ¡Raíces Devoradoras!" % f["nombre"]
	var base := int(f["atk"] * ATAQUES["raices"]["mult"] * mult * k)
	var objs: Array = vivos.filter(func(h): return h["hp"] > 0)
	var impacto := func():
		c._sonar(ATAQUES["raices"]["sonido"])
		Sonido.golpe()
		c._temblor(8.0)
		for h in objs:
			if h["hp"] <= 0:
				continue
			var nodo := _raiz_bajo(c, h)
			_golpear(c, h, base)
			if not h.get("defendiendo", false) and h["hp"] > 0:     # Defender: no queda atrapado
				h["hb_raices"] = RAICES_TURNOS
				_quitar_nodo(h, "hb_raiz_nodo")
				h["hb_raiz_nodo"] = nodo
			else:
				_desvanecer(c, nodo, 0.9)
		c._actualizar()
	var al_evento := func(ev: String):
		if ev == "hundir":
			c._particulas(pantalla(c, f, "mano_i"), Color(0.5, 0.42, 0.3, 0.9), Color(0.3, 0.25, 0.2, 0.0), 22, 0.8,
				Vector2(60, 200), 30.0, Vector2(0, -1), 50.0, Vector2(0, 450), 0.14)
			c._temblor(5.0)
	await _atacar(c, f, "raices", impacto, al_evento)


# ---------------------------------------------------------------- 3 · Aliento de la Putrefacción

static func _aliento(c, f: Dictionary, vivos: Array, mult: float) -> void:
	c.registro.text = "%s toma aire... ¡Aliento de la Putrefacción!" % f["nombre"]
	var base := int(f["atk"] * ATAQUES["aliento"]["mult"] * mult)
	var objs: Array = vivos.filter(func(h): return h["hp"] > 0)
	var nube: Array = [null]
	var al_evento := func(ev: String):
		match ev:
			"aviso":
				c._sonar(ATAQUES["aliento"]["sonido"])
			"aliento_inicio":
				nube[0] = _esporas(c, f, objs)
			"aliento_fin":
				if nube[0] != null and is_instance_valid(nube[0]):
					nube[0].emitting = false
					c.get_tree().create_timer(1.6).timeout.connect(nube[0].queue_free)
				nube[0] = null
	var impacto := func():
		for h in objs:
			if h["hp"] <= 0:
				continue
			_golpear(c, h, base)
			if not h.get("defendiendo", false) and h["hp"] > 0:
				h["hb_corrupcion"] = CORRUPCION_TURNOS
				c._numero_flotante(h, "Corrupción", COLOR_ENFERMO, 26, Vector2(0, -50))
		c._actualizar()
	await _atacar(c, f, "aliento", impacto, al_evento)
	if nube[0] != null and is_instance_valid(nube[0]):
		nube[0].queue_free()


# ---------------------------------------------------------------- 4 · Guadaña de Raíces (barrido horizontal)

static func _guadana(c, f: Dictionary, vivos: Array, mult: float, k: float) -> void:
	c.registro.text = "Una guadaña de raíz brota del brazo de %s..." % f["nombre"]
	var base := int(f["atk"] * ATAQUES["guadana"]["mult"] * mult * k)
	var objs: Array = vivos.filter(func(h): return h["hp"] > 0)
	var impacto := func():
		c._sonar(ATAQUES["guadana"]["sonido"])
		Sonido.golpe(true)
		_tajo(c, objs)
		for h in objs:
			_golpear(c, h, base)
		c._actualizar()
	await _atacar(c, f, "guadana", impacto)


# ---------------------------------------------------------------- 5 · El Ojo del Juicio (rayo desde el ojo)

static func _ojo(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
	c.registro.text = "El ojo de %s se enciende: ¡el Ojo del Juicio busca a %s!" % [f["nombre"], obj["nombre"]]
	var base := int(f["atk"] * ATAQUES["ojo"]["mult"] * mult)
	var nodos := {}
	var al_evento := func(ev: String):
		match ev:
			"carga":
				c._sonar(ATAQUES["ojo"]["sonido"])
				nodos["carga"] = _halo(c, pantalla(c, f, "ojo"), _color_fase(f), 0.0, 1.0, 0.8)
				nodos["marca"] = _zona_suelo(c, obj, _color_fase(f))
			"rayo_inicio":
				_quitar(nodos.get("carga"))
				nodos["rayo"] = _rayo(c, pantalla(c, f, "ojo"), c._centro(obj), _color_fase(f))
	var impacto := func():
		Sonido.golpe(true)
		c._temblor(9.0)
		c._particulas(c._centro(obj), _color_fase(f), Color(1, 1, 1, 0), 26, 0.6, Vector2(80, 240), 20.0, Vector2(0, -1),
			180.0, Vector2.ZERO, 0.18)
		_golpear(c, obj, base)
		_quitar(nodos.get("marca"))
		c._actualizar()
	await _atacar(c, f, "ojo", impacto, al_evento)
	for k in nodos:
		_quitar(nodos[k])


# ---------------------------------------------------------------- 6 · Llamada de los Condenados (con tope)

static func _llamada(c, f: Dictionary) -> void:
	c.registro.text = "%s clava su bastón: ¡Llamada de los Condenados!" % f["nombre"]
	var impacto := func():
		c._sonar(ATAQUES["llamada"]["sonido"])
		c._temblor(10.0)
		_onda(c, pantalla(c, f, "baston_punta"), _color_fase(f), 220.0, 0.6)
	var al_evento := func(ev: String):
		if ev == "invocar":
			invocar(c, f)
	await _atacar(c, f, "llamada", impacto, al_evento)


# Los condenados entran como entran los enemigos al empezar (los mismos datos, el mismo escalado y el mismo rig).
static func invocar(c, f: Dictionary) -> Array:
	var nuevos: Array = []
	var cuantos := mini(2, TOPE_INVOCADOS - _invocados_vivos(c))
	var sitios := [Vector2(300, 110), Vector2(430, 40)]
	var Esc = load("res://combate_escalado.gd")
	var zona: String = Engine.get_meta("zona", "llanura")
	var nivel: int = load("res://progreso.gd").nivel_grupo()
	for i in cuantos:
		var e: Dictionary = c.ENEMIGOS[INVOCADO].duplicate(true)
		Esc.aplicar(e, zona, nivel, c.combate_fijo)
		e["hero"] = false
		e["clave"] = INVOCADO
		e["hb_invocado"] = true
		e["hp_max"] = e["hp"]
		e["atb"] = 0.0
		var usado: int = int(f.get("hb_invocados_total", 0))
		f["hb_invocados_total"] = usado + 1
		e["nombre"] = "%s %s" % [e["nombre"], "ABCDEFGHIJ"[usado % 10]]
		var sitio: Vector2 = sitios[i % sitios.size()]
		e["pos"] = Vector2(sitio.x * c.ENEMIGOS_X.x + c.ENEMIGOS_X.y, sitio.y)
		var mod: Dictionary = c.MODELOS[e["modelo"]]
		if mod.get("tipo", "") == "3d" and c._ruta_3d(mod) == "" and mod.has("respaldo"):
			e["modelo"] = mod["respaldo"]
		c.enemigos.append(e)
		c._crear_rig(e)
		c._crear_sombra(e)
		c._crear_vida_enemigo(e)
		var pe = c._p3d(e)
		if pe != null and pe.has_method("entrada"):
			pe.entrada()
		c._particulas(c._suelo_de(e), Color(0.4, 0.9, 0.7, 0.9), Color(0.2, 0.4, 0.3, 0.0), 24, 0.9, Vector2(60, 200), 40.0,
			Vector2(0, -1), 40.0, Vector2(0, 300), 0.15)
		nuevos.append(e)
		_contar(f, "invocado")
	if not nuevos.is_empty():
		c._numero_flotante(f, "¡Los condenados acuden!", _color_fase(f), 30)
	c._actualizar()
	return nuevos


# ---------------------------------------------------------------- 7 · Abrazo de la Muerte (agarre y oportunidad de soltarse)

static func _abrazo(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
	c.registro.text = "%s alarga la garra hacia %s..." % [f["nombre"], obj["nombre"]]
	var base := int(f["atk"] * ATAQUES["abrazo"]["mult"] * mult)
	var estado := {"agarrado": false, "suelto": false, "aprietos": 0}
	var al_evento := func(ev: String):
		match ev:
			"agarre":
				estado["agarrado"] = true
				obj["hb_agarrado"] = true
				c.registro.text = "¡%s atrapa a %s en su Abrazo de la Muerte!" % [f["nombre"], obj["nombre"]]
				c._sonar(ATAQUES["abrazo"]["sonido"])
				_llevar(c, f, obj, 0.45)
			"apretar_1":
				pass
			"soltar":
				_soltar(c, obj)
	var impacto := func():
		if estado["suelto"] or obj["hp"] <= 0:
			return
		estado["aprietos"] += 1
		Sonido.golpe(estado["aprietos"] == 2)
		c._temblor(6.0)
		_golpear(c, obj, int(base * (1.0 if estado["aprietos"] == 1 else 1.3)), false)
		if estado["aprietos"] == 1 and obj["hp"] > 0:      # la oportunidad de soltarse, entre un aprieto y el otro
			var prob := PROB_LIBERARSE + (0.35 if obj.get("defendiendo", false) else 0.0)
			if randf() < prob:
				estado["suelto"] = true
				_contar(f, "liberado")
				c._numero_flotante(obj, "¡Se libera!", Color(0.85, 1.0, 0.8), 30)
				c.registro.text = "¡%s se libera del abrazo!" % obj["nombre"]
				_soltar(c, obj)
		c._actualizar()
	await _atacar(c, f, "abrazo", impacto, al_evento)
	_soltar(c, obj)


static func _llevar(c, f: Dictionary, obj: Dictionary, dur: float) -> void:
	var rig: Node2D = obj["rig"]
	if not obj.has("hb_rig_base"):
		obj["hb_rig_base"] = rig.position
	var t := 0.0
	while obj.get("hb_agarrado", false) and is_instance_valid(rig) and c.is_inside_tree():
		var mano := pantalla(c, f, "mano_i")
		var destino: Vector2 = obj["hb_rig_base"] + (mano - c._centro(obj)) + Vector2(0, 40)   # (_centro no se mueve con el rig)
		t += c.get_process_delta_time()
		rig.position = rig.position.lerp(destino, clampf(t / dur, 0.15, 0.5))
		await c.get_tree().process_frame


static func _soltar(c, obj: Dictionary) -> void:
	if not obj.get("hb_agarrado", false):
		return
	obj["hb_agarrado"] = false
	obj.erase("hb_sigue")
	var rig: Node2D = obj["rig"]
	var base: Vector2 = obj.get("hb_rig_base", obj.get("rig_base", rig.position))
	obj.erase("hb_rig_base")
	var t: Tween = c.create_tween()
	t.tween_property(rig, "position", base, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): c._temblor(4.0))


# ---------------------------------------------------------------- el Réquiem del Bosque Eterno (fase 3)

# Turno 1: se hunde en la tierra, las raíces cubren la arena y queda cargando (sin daño). Se avisa de cuatro maneras:
# el cartel, «⚠ Réquiem» sobre su vida, la señal dibujada y una marca bajo cada héroe.
static func _requiem_aviso(c, f: Dictionary) -> void:
	c.registro.text = "%s hunde los brazos en la tierra: ¡el Réquiem del Bosque Eterno se acerca!" % f["nombre"]
	f["hb_requiem"] = true
	_contar(f, "requiem_aviso")
	c._marcar_aviso(f, true)
	c._numero_flotante(f, "⚠ ¡Réquiem del Bosque Eterno!", COLOR_AVISO, 34)
	c._sonar("carga_jefe")
	var p = c._p3d(f)
	var al_evento := func(ev: String):
		if ev == "raices_arena" or ev == "hundir":
			if not f.has("hb_arena"):
				f["hb_arena"] = _raices_arena(c, f)
				c._temblor(7.0)
	f["animando"] = true
	if p != null and p.has_method("requiem_preparar"):
		await p.requiem_preparar(al_evento)
	else:
		al_evento.call("raices_arena")
		await c.get_tree().create_timer(1.2).timeout
	f["animando"] = false
	var marcas: Array = []
	for h in _vivos(c):
		marcas.append(_zona_suelo(c, h, COLOR_AVISO))
	f["hb_marcas"] = marcas
	c._actualizar()


# Turno 2: estalla (troncos, onda) contra todos y queda vulnerable hasta su turno siguiente.
static func _requiem_descarga(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["hb_requiem"] = false
	c._marcar_aviso(f, false)
	c.registro.text = "¡%s desata el Réquiem del Bosque Eterno!" % f["nombre"]
	_contar(f, "requiem")
	var base := int(f["atk"] * ATAQUES["requiem"]["mult"] * mult)
	var objs: Array = vivos.filter(func(h): return h["hp"] > 0)
	var troncos: Array = []
	var al_evento := func(ev: String):
		if ev == "troncos":
			for h in objs:
				if troncos.size() < MAX_RAICES_ARENA:
					troncos.append(_tronco(c, c._suelo_de(h)))
	var impacto := func():
		c._sonar(ATAQUES["requiem"]["sonido"])
		Sonido.golpe(true)
		c._temblor(18.0)
		c._fogonazo(_color_fase(f), 0.5, 0.7)
		_onda(c, pantalla(c, f, "nucleo"), _color_fase(f), 700.0, 0.8)
		for h in objs:
			_golpear(c, h, base)
		for m in f.get("hb_marcas", []):
			_quitar(m)
		f.erase("hb_marcas")
		c._actualizar()
	var p = c._p3d(f)
	f["animando"] = true
	var golpes := [0]
	var imp := func():
		golpes[0] += 1
		if golpes[0] == 1:
			impacto.call()
	if p != null and p.has_method("requiem_descargar"):
		await p.requiem_descargar(imp, al_evento)
	else:
		al_evento.call("troncos")
		imp.call()
		await c.get_tree().create_timer(1.0).timeout
	if golpes[0] == 0:
		imp.call()
	f["animando"] = false
	for t in troncos:
		_desvanecer(c, t, 1.2)
	_quitar_lista(f.get("hb_arena", []))
	f.erase("hb_arena")
	if f["hp"] > 0:
		f["hb_vulnerable"] = true
		_contar(f, "vulnerable")
		c._marcar_puntos(f, true)
		c._numero_flotante(f, "¡Vulnerable!", COLOR_TURQUESA, 36)
		c.registro.text = "¡%s queda vulnerable: su núcleo late al descubierto!" % f["nombre"]
		c._actualizar()
		await c.get_tree().create_timer(0.5).timeout


static func _recuperarse(c, f: Dictionary) -> void:
	f["hb_vulnerable"] = false
	c._marcar_puntos(f, false)
	c.registro.text = "%s se alza de nuevo" % f["nombre"]
	_contar(f, "recupera")
	var p = c._p3d(f)
	f["animando"] = true
	if p != null and p.has_method("recuperarse"):
		await p.recuperarse()
	else:
		await c.get_tree().create_timer(0.8).timeout
	f["animando"] = false
	c._actualizar()


# ---------------------------------------------------------------- las fases

static func _cambiar_fase(c, f: Dictionary, n: int) -> void:
	f["hb_fase"] = n
	_contar(f, "fase%d" % n)
	c.registro.text = "%s: «%s»" % [f["nombre"], NOMBRES_FASE[n]]
	var p = c._p3d(f)
	var al_evento := func(ev: String):
		if ev == "cambio":
			c._sonar("guardian_bosque_fase2" if n == 2 else "fase2")
			c._fogonazo(COLOR_ENFERMO if n == 2 else COLOR_TURQUESA, 0.45, 0.8)
			c._temblor(12.0)
			c._numero_flotante(f, "Fase %d · %s" % [n, NOMBRES_FASE[n]], COLOR_ENFERMO if n == 2 else COLOR_TURQUESA, 36)
			if n >= 3:                                   # la armadura de corteza salta en astillas
				c._particulas(c._centro(f), Color(0.6, 0.5, 0.4, 1.0), Color(0.35, 0.28, 0.2, 0.0), 36, 1.2, Vector2(150, 420),
					60.0, Vector2(0, -1), 120.0, Vector2(0, 700), 0.2)
	f["animando"] = true
	if p != null and p.has_method("cambiar_fase"):
		await p.cambiar_fase(n, al_evento)
	else:
		al_evento.call("cambio")
		await c.get_tree().create_timer(1.2).timeout
	f["animando"] = false
	c._actualizar()


static func _color_fase(f: Dictionary) -> Color:
	return COLOR_ENFERMO if fase_de(f) == 2 else COLOR_TURQUESA


# ================================================================= animación (combate.gd _animar_golpe y el resto)

static func _atacar(c, f: Dictionary, ataque: String, impacto: Callable, al_evento := Callable()) -> void:
	var p = c._p3d(f)
	f["animando"] = true
	var golpes := [0]
	var imp := func():
		golpes[0] += 1
		impacto.call()
	if p != null and p.has_method("atacar"):
		await p.atacar(ataque, imp, al_evento)
	else:                                                 # sin su 3D (respaldo 2D): el aviso, una espera y el golpe
		if al_evento.is_valid():
			al_evento.call("aviso")
		await c.get_tree().create_timer(0.6).timeout
	var n_imp: int = 2 if ataque == "abrazo" else 1
	while golpes[0] < n_imp and f["hp"] > 0:              # (cortado o sin clip: los golpes que falten, una vez)
		imp.call()
	f["animando"] = false


# Un golpe suyo a un héroe por la vía de siempre (Juicio de Garon contra él no pasa por aquí): el Puño de un respaldo.
static func animar_golpe(c, o: Dictionary, _obj: Dictionary, impacto: Callable) -> void:
	await _atacar(c, o, "puno", impacto)


# Un punto de su cuerpo en la escena del combate (como _punto_magia de combate.gd).
static func pantalla(c, f: Dictionary, nombre: String) -> Vector2:
	var p = c._p3d(f)
	if p == null or not p.has_method("punto") or not f.has("cam3d"):
		return c._centro(f)
	var cam: Camera3D = f["cam3d"]
	var spr: Sprite2D = f["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(cam.unproject_position(p.punto(nombre))))


# ================================================================= efectos (nodos 2D aparte, con tope, que se borran solos)

static func _zona_suelo(c, h: Dictionary, color: Color) -> Node2D:
	var n := Node2D.new()
	n.position = c._suelo_de(h)
	n.z_index = 1
	var l := Line2D.new()
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a) * 95.0, sin(a) * 28.0))
	l.points = pts
	l.width = 5.0
	l.default_color = Color(color, 0.85)
	n.add_child(l)
	var b = c._brillo(Color(color, 0.35))
	b.scale = Vector2(1.6, 0.5)
	n.add_child(b)
	c.escena.add_child(n)
	var t := n.create_tween().set_loops()
	t.tween_property(n, "modulate:a", 0.45, 0.35)
	t.tween_property(n, "modulate:a", 1.0, 0.35)
	return n


static func _raiz_bajo(c, h: Dictionary) -> Node2D:
	var n := Node2D.new()
	n.position = c._suelo_de(h)
	n.z_index = 4
	for k in 5:
		var pol := Polygon2D.new()
		var x := -70.0 + k * 35.0 + randf_range(-8, 8)
		var alto := randf_range(70, 150)
		var ancho := randf_range(12, 20)
		pol.polygon = PackedVector2Array([Vector2(x - ancho, 0), Vector2(x + ancho, 0), Vector2(x + ancho * 0.3, -alto * 0.6),
			Vector2(x + randf_range(-20, 20), -alto)])
		pol.color = Color(0.33, 0.26, 0.19).lerp(Color(0.42, 0.5, 0.25), randf() * 0.4)
		n.add_child(pol)
	n.scale = Vector2(1, 0.05)
	c.escena.add_child(n)
	n.create_tween().tween_property(n, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return n


static func _esporas(c, f: Dictionary, objs: Array) -> CPUParticles2D:
	var boca := pantalla(c, f, "boca")
	var centro := Vector2.ZERO
	for h in objs:
		centro += c._centro(h)
	centro = centro / maxf(1.0, objs.size()) if not objs.is_empty() else boca + Vector2(300, 200)
	var dir := (centro - boca).normalized()
	var p: CPUParticles2D = c._particulas(boca, Color(0.62, 0.85, 0.3, 0.85), Color(0.35, 0.45, 0.15, 0.0), 40, 1.4,
		Vector2(260, 520), 18.0, dir, 22.0, Vector2(0, 40), 0.3, true)
	return p


static func _tajo(c, objs: Array) -> void:
	if objs.is_empty():
		return
	var l := Line2D.new()
	var a: Vector2 = c._centro(objs[0])
	var pts := PackedVector2Array()
	var xs: Array = objs.map(func(h): return c._centro(h).x)
	var x0: float = xs.min() - 160.0
	var x1: float = xs.max() + 160.0
	var y := a.y
	for i in 17:
		var t := i / 16.0
		pts.append(Vector2(lerpf(x0, x1, t), y + sin(t * PI) * -60.0))
	l.points = pts
	l.width = 16.0
	l.default_color = Color(0.85, 1.0, 0.92, 0.9)
	l.z_index = 6
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	l.gradient = g
	c.escena.add_child(l)
	_desvanecer(c, l, 0.45)


static func _halo(c, pos: Vector2, color: Color, desde: float, hasta: float, dur: float) -> Node2D:
	var b = c._brillo(color)
	b.position = pos
	b.z_index = 6
	b.scale = Vector2.ONE * maxf(0.05, desde)
	c.escena.add_child(b)
	b.create_tween().tween_property(b, "scale", Vector2.ONE * hasta, dur).set_trans(Tween.TRANS_SINE)
	return b


static func _rayo(c, desde: Vector2, hasta: Vector2, color: Color) -> Node2D:
	var n := Node2D.new()
	n.z_index = 6
	for w in [[34.0, 0.35], [14.0, 0.95]]:
		var l := Line2D.new()
		l.points = PackedVector2Array([desde, hasta])
		l.width = w[0]
		l.default_color = Color(color.lightened(0.3), w[1])
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		n.add_child(l)
	c.escena.add_child(n)
	var t := n.create_tween().set_loops()
	t.tween_property(n, "modulate:a", 0.7, 0.08)
	t.tween_property(n, "modulate:a", 1.0, 0.08)
	return n


static func _onda(c, pos: Vector2, color: Color, radio: float, dur: float) -> void:
	var l := Line2D.new()
	l.width = 6.0
	l.default_color = Color(color, 0.9)
	l.position = pos
	l.z_index = 5
	c.escena.add_child(l)
	var poner := func(r: float):
		var pts := PackedVector2Array()
		for i in 41:
			var a := TAU * i / 40.0
			pts.append(Vector2(cos(a), sin(a) * 0.35) * r)
		l.points = pts
	poner.call(10.0)
	var t := l.create_tween().set_parallel()
	t.tween_method(poner, 10.0, radio, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, dur)
	t.chain().tween_callback(l.queue_free)


static func _raices_arena(c, f: Dictionary) -> Array:
	var r: Array = []
	var desde := pantalla(c, f, "mano_i")
	var heroes: Array = _vivos(c)
	for k in mini(MAX_RAICES_ARENA, 3 + heroes.size() * 2):
		var l := Line2D.new()
		var meta: Vector2
		if k < heroes.size():
			meta = c._suelo_de(heroes[k])
		else:
			meta = desde + Vector2(randf_range(150, 900), randf_range(-40, 160))
		var pts := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			pts.append(desde.lerp(meta, t) + Vector2(0, sin(t * 9.0 + k) * 14.0))
		l.points = pts
		l.width = randf_range(10, 18)
		l.default_color = Color(0.32, 0.25, 0.18, 0.95)
		l.z_index = 1
		var w := Curve.new()
		w.add_point(Vector2(0, 1))
		w.add_point(Vector2(1, 0.25))
		l.width_curve = w
		c.escena.add_child(l)
		l.modulate.a = 0.0
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.4)
		r.append(l)
	return r


static func _tronco(c, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos + Vector2(randf_range(-40, 40), 10)
	n.z_index = 5
	var pol := Polygon2D.new()
	var alto := randf_range(220, 300)
	pol.polygon = PackedVector2Array([Vector2(-40, 0), Vector2(40, 0), Vector2(26, -alto * 0.7), Vector2(8, -alto),
		Vector2(-14, -alto * 0.85), Vector2(-28, -alto * 0.5)])
	pol.color = Color(0.36, 0.3, 0.24)
	n.add_child(pol)
	var veta := Line2D.new()
	veta.points = PackedVector2Array([Vector2(-6, -10), Vector2(4, -alto * 0.4), Vector2(-2, -alto * 0.8)])
	veta.width = 5.0
	veta.default_color = Color(0.45, 1.0, 0.85, 0.9)
	n.add_child(veta)
	n.scale = Vector2(1, 0.02)
	c.escena.add_child(n)
	n.create_tween().tween_property(n, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return n


static func _desvanecer(c, n, dur: float) -> void:
	if n == null or not is_instance_valid(n):
		return
	var t: Tween = n.create_tween()
	t.tween_property(n, "modulate:a", 0.0, dur)
	t.tween_callback(n.queue_free)


static func _quitar(n) -> void:
	if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
		n.queue_free()


static func _quitar_lista(l: Array) -> void:
	for n in l:
		_quitar(n)


static func _quitar_nodo(d: Dictionary, k: String) -> void:
	_quitar(d.get(k, null))
	d.erase(k)


# ================================================================= al acabar (combate.gd _comprobar_fin)

# Si cae él, los condenados se deshacen con él (el combate se gana). Devuelve cuántos se deshicieron.
static func al_caer(c) -> int:
	var hb = c.enemigos.filter(func(e): return es(e))
	if hb.is_empty() or hb.any(func(e): return e["hp"] > 0):
		return 0
	var n := 0
	for e in c.enemigos:
		if e.get("hb_invocado", false) and e["hp"] > 0:
			e["hp"] = 0
			n += 1
			if e.has("rig"):
				e["rig"].create_tween().tween_property(e["rig"], "modulate:a", 0.0, 0.8)
	return n


static func al_acabar(c) -> void:
	for e in c.enemigos:
		if es(e):
			c._marcar_puntos(e, false)
			c._marcar_aviso(e, false)
			_quitar_lista(e.get("hb_arena", []))
			e.erase("hb_arena")
			_quitar_lista(e.get("hb_marcas", []))
			e.erase("hb_marcas")
	for h in c.heroes:
		_quitar_nodo(h, "hb_raiz_nodo")
		h.erase("hb_raices")
		h.erase("hb_corrupcion")
		if h.get("hb_agarrado", false):
			_soltar(c, h)


# Nodos suyos que siguen en la escena (para las pruebas: al acabar no debe quedar ninguno).
static func nodos_vivos(c) -> Array:
	var r: Array = []
	for e in c.enemigos:
		if not es(e):
			continue
		for k in ["hb_arena", "hb_marcas"]:
			for n in e.get(k, []):
				if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
					r.append("%s:%s" % [e["nombre"], k])
	for h in c.heroes:
		var n = h.get("hb_raiz_nodo", null)
		if n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:raiz" % h["nombre"])
	return r


# ================================================================= el mapa (zonas3d/gran_bosque_3d.gd)

# El grupo de su combate fijo si el interruptor está encendido; -1 si no (sin tirar dados).
static func grupo_santuario() -> int:
	return GRUPO if activo() else -1
