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
#     siguiente.
#
# e01_a2 · Avance del Portón (14/11, noche; mismo método): «embestida recta, corredor de 1 m y avance máximo de 3 m»
#   · Aviso dentro del clip (anticipación 1,00 s): al empezar, una FRANJA en el suelo desde él hasta el blanco (y algo
#     más allá, el de detrás); se fija a 0,75 s; la carrera va de 1,00 a 1,45 (el combate lo desplaza: el clip va en el
#     sitio) y el IMPACTO, a 1,30, al llegar.
#   · EN FILA, como la Prensa: el elegido ×1,1 del ataque (12-16 de la ficha con su ataque de 13) y el de detrás ×0,5.
#   · Empuje de 0,7 m → RETROCESO del 25 % de la barra ATB (la regla del 15 % para 0,4 m, a escala), sin defender.
#   · Recarga compartida: tras cada especial, sus turnos de guardia; luego el SIGUIENTE especial de la rotación.
#   · Cifras PROPUESTAS (×1,1, 25 %): sin partidas reales todavía.
#
# e01_a3 · Sello de Clausura (15/11; mismo método): «un círculo de radio 1,3 m a máximo 5 m, fijado antes de activar»
#   · El centro: el héroe vivo a ≤ 5 m con más aliados a ≤ 1,3 m (empate: el que elegiría «agresivo»); si nadie está a
#     ≤ 5 m, el punto a 5 m hacia el más cercano. La Guardia de Garon no cambia el centro: cubre en el impacto.
#   · Aviso dentro del clip (anticipación 1,30 s): la marca de cerradura aparece a 0,20 s sobre el centro y lo sigue hasta
#     0,80 s, cuando el centro se FIJA (un pulso marfil); a 1,30 s (IMPACTO, activo [1,30, 1,50)) golpea a TODOS los
#     héroes vivos que estén dentro del círculo en ese momento, UNA vez por ejecución y objetivo; la marca se borra.
#   · Daño ARCANO (magia: sin restar la defensa física, sin crítico ni esquiva; defender lo deja a la mitad; el Anillo del
#     Alba cuenta como contra cualquier magia) de SELLO_DANO_MIN a SELLO_DANO_MAX × mult.
#   · −15 % de velocidad (ATB) durante 1 turno del afectado: la barra que le lleva a su PRÓXIMO turno se llena más
#     despacio; al llegarle el turno, vuelve a su velocidad (si ya tenía la barra llena, cuenta la siguiente). No silencia
#     ni inmoviliza.
#   · Raíz quieta: no anda; el clip va en su sitio.
#   · cooldown_own_turns = 3: tres turnos de guardia tras el Sello.
#   · Rotación de los tres especiales con su recarga: Prensa, G, G, Avance, G, G, Sello, G, G, G, Prensa…
#   · TODAS las cifras del Sello (y su escala en píxeles) son PROPUESTA, sin equilibrar: constantes SELLO_* de abajo.
#   · Muerte a media Prensa: no golpea (enemigo_v12_3d.gd no llama al impacto si está muerto y aquí se comprueba su vida)
#     y la marca se borra (vigilar, repasar y al_acabar).

const CLAVE := "meshy_e01"
const PERSONALIDAD := "meshy_e01"
const INTERRUPTOR := "meshy_e01"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_PRUEBA := [28, 29]
const ATAQUE_ID := "e01_a1"
const ATAQUE_ID_A2 := "e01_a2"
const MULT_PORTON := 1.1
const RETROCESO_PORTON := 0.25
const T_CARRERA := 1.0
const T_FRENO := 1.45
const FRANJA_ANCHO := 64.0                        # px (el corredor de 1 m, aplastado como las demás marcas)
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

# ---- e01_a3 · Sello de Clausura: PROPUESTA, sin equilibrar (15/11). Todo lo configurable del Sello está aquí. ----
const ATAQUE_ID_A3 := "e01_a3"
const SELLO_DANO_MIN := 9                         # daño arcano (ficha: 9-13), × mult del turno
const SELLO_DANO_MAX := 13
const SELLO_RADIO_M := 1.3                        # radio del círculo
const SELLO_ALCANCE_M := 5.0                      # el centro, a 5 m como mucho del Custodio
const SELLO_REDUCCION_VEL := 0.15                 # −15 % de velocidad (ATB)…
const SELLO_TURNOS_LENTO := 1                     # …durante 1 turno del afectado
const SELLO_CD_TURNOS := 3                        # cooldown_own_turns de la ficha
const T_SELLO_MARCA := 0.20                       # la marca aparece (evento «aviso» del clip)
const T_SELLO_FIJA := 0.80                        # el centro se fija (evento «fija_direccion»)
const T_SELLO_IMPACTO := 1.30                     # IMPACTO (evento «impacto»; activo hasta 1,50)
const SELLO_APLASTADO := 0.32                     # el suelo visto en la pantalla (como las demás marcas)
const COLOR_SELLO := Color(0.17, 0.15, 0.22)      # el disco de cerradura, opaco
const COLOR_MARFIL := Color(0.97, 0.93, 0.82)     # el pulso y el borde (sin luces: solo dibujo 2D)
# Rotación de especiales y la recarga de cada uno (cooldown_own_turns).
const ROTACION := ["prensa", "porton", "sello"]
const CD_DE := {"prensa": CD_TURNOS, "porton": CD_TURNOS, "sello": SELLO_CD_TURNOS}

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
	if not clip in ["ataque", "e01__attack_prensa", "porton", "e01__attack_porton", "sello", "e01__attack_sello"]:
		return
	var at: Dictionary = e.get("e01_ataque", {})
	if at.is_empty() or int(e["hp"]) <= 0:
		return
	if nombre == "aviso":
		at["t_aviso"] = Engine.get_process_frames()
		if at.get("ataque", "") == ATAQUE_ID_A3:
			_marcar_sello(c, e, at)
		elif at.get("ataque", "") == ATAQUE_ID_A2:
			_marcar_franja(c, e, at)
		else:
			_marcar(c, e, at)
	elif nombre == "fija_direccion":
		at["t_fija"] = Engine.get_process_frames()
		if at.get("ataque", "") == ATAQUE_ID_A3:
			at["centro"] = _centro_sello(c, e, at)        # desde aquí no se mueve
			at["centro_fijo"] = true
			var n = at.get("marca_nodo", null)
			if n != null and is_instance_valid(n):
				n.position = at["centro"]
			_pulso(c, at["centro"])
		_fijar(e)
	elif nombre == "fin_activo":
		at["t_fin_activo"] = Engine.get_process_frames()


# ================================================================= lo que se lee

# 15/11 (Redmi, APK cbc0536): el contador cuenta TURNOS SUYOS (los que juega: en cada guardia, uno menos de recarga), no
# tiempo, y ahora lo dice. Antes, en el turno previo al especial (recarga 0) la etiqueta se quedaba sin contador y el
# panel solo decía «En guardia»: se pasaba de «Sello en 2» a nada, sin el aviso de que el siguiente era el Sello.
# turnos_para_especial: en cuántos turnos suyos llega el especial que toca (1 = su próximo turno).
static func turnos_para_especial(e: Dictionary) -> int:
	return maxi(0, int(e.get("e01_cd", 0))) + 1


static func nombre_corto(especial: String) -> String:
	return {"porton": "Avance", "sello": "Sello"}.get(especial, "Prensa")


static func nombre_largo(especial: String) -> String:
	return {"porton": "Avance del Portón", "sello": "Sello de Clausura"}.get(especial, "Prensa del Umbral")


static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("e01_guardia", false):
		r.append("Guardia")
	var n := turnos_para_especial(e)
	if n > 1:
		r.append("%s en %d turnos suyos" % [nombre_corto(_siguiente(e)), n])
	else:
		r.append("⚠ %s: su próximo turno" % nombre_corto(_siguiente(e)))
	return r


static func info(e: Dictionary) -> Array:
	var r: Array = []
	if e.get("e01_guardia", false):
		r.append("En guardia: golpes a la mitad")
	var n := turnos_para_especial(e)
	if n > 1:
		r.append("%s en %d turnos suyos (antes, %d de guardia)" % [nombre_largo(_siguiente(e)), n, n - 1])
	elif _siguiente(e) == "porton":
		r.append("⚠ Su próximo turno: Avance del Portón, embestida en fila (defiéndete)")
	elif _siguiente(e) == "sello":
		r.append("⚠ Su próximo turno: Sello de Clausura, un círculo en el suelo (magia; frena la barra)")
	else:
		r.append("⚠ Su próximo turno: Prensa del Umbral, en fila (defiéndete)")
	return r


# ================================================================= su turno (IA)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	f["e01_turno"] = int(f.get("e01_turno", 0)) + 1
	if f.get("e01_guardia", false):                     # la guardia dura hasta su turno siguiente
		f["e01_guardia"] = false
		f["defendiendo"] = false
	vivos = vivos.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	match _elegir(f):
		"prensa":
			await _prensa(c, f, vivos, mult)
		"porton":
			await _porton(c, f, vivos, mult)
		"sello":
			await _sello(c, f, vivos, mult)
		_:
			await _guardia(c, f)


static func _elegir(f: Dictionary) -> String:
	return "guardia" if int(f.get("e01_cd", 0)) > 0 else _siguiente(f)


# El especial que toca: el siguiente de la ROTACION tras el último (el primero, la Prensa).
static func _siguiente(f: Dictionary) -> String:
	var i: int = ROTACION.find(str(f.get("e01_especial", "")))
	return ROTACION[(i + 1) % ROTACION.size()] if i >= 0 else ROTACION[0]


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
	f["e01_especial"] = "prensa"


# e01_a2: el mismo esquema que la Prensa (objetivos en fila, Guardia de Garon, una vez por ejecución y objetivo).
static func _porton(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var marcado: Dictionary = c._elegir_objetivo("agresivo", vivos)
	var obj: Dictionary = c._cubre(marcado)
	var detras := vecino(c, marcado)
	if not detras.is_empty() and is_same(detras, obj):
		detras = vecino(c, obj)
		if not detras.is_empty() and is_same(detras, marcado):
			detras = {}
	_instancias += 1
	var at := {"id": _instancias, "ataque": ATAQUE_ID_A2, "principal": obj, "resto": [] if detras.is_empty() else [detras],
		"dano_resto": int(f["atk"] * MULT_PORTON * MULT_FILA * mult), "golpeados": {}, "t_impacto": -1,
		"retroceso": RETROCESO_PORTON}
	f["e01_ataque"] = at
	_contar(f, "porton")
	c.registro.text = "%s baja la cabeza: ¡Avance del Portón contra %s%s!" % [f["nombre"], obj["nombre"],
		(" y %s" % detras["nombre"]) if not detras.is_empty() else ""]
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_PORTON * mult) + randi_range(-2, 2), "")
	_quitar_marca(f)
	f.erase("e01_ataque")
	f["e01_ultimo"] = at
	f["e01_cd"] = CD_TURNOS
	f["e01_especial"] = "porton"


# ================================================================= e01_a3 · Sello de Clausura

# Píxeles de la pantalla por metro del mundo: los de su propio modelo (su ventana 3D muestra «alto_vista» metros en
# «vp.y» píxeles y se dibuja a «esc»). 840 × 0,6 / 3,0 = 168 px/m.
static func px_por_m(c) -> float:
	var m: Dictionary = c.MODELOS.get(CLAVE, {})
	if m.is_empty():
		return 168.0
	return float(m["vp"].y) * float(m["esc"]) / float(m["alto_vista"])


# La distancia en el suelo, en metros: la pantalla aplasta la profundidad (SELLO_APLASTADO), así que lo vertical cuenta más.
static func distancia_m(c, a: Vector2, b: Vector2) -> float:
	var d := b - a
	return Vector2(d.x, d.y / SELLO_APLASTADO).length() / px_por_m(c)


# El centro: el héroe vivo a ≤ SELLO_ALCANCE_M con más aliados vivos a ≤ SELLO_RADIO_M (empate: el que elegiría
# «agresivo»). Si nadie está a su alcance, el punto a SELLO_ALCANCE_M hacia el más cercano (y no lleva principal).
static func elegir_centro(c, f: Dictionary, vivos: Array) -> Dictionary:
	var pie: Vector2 = c._suelo_de(f)
	var cerca: Array = vivos.filter(func(h): return h["hp"] > 0 and distancia_m(c, pie, c._suelo_de(h)) <= SELLO_ALCANCE_M)
	if cerca.is_empty():
		var lejos: Array = vivos.filter(func(h): return h["hp"] > 0)
		if lejos.is_empty():
			return {"principal": {}, "punto": pie}
		lejos.sort_custom(func(a, b): return distancia_m(c, pie, c._suelo_de(a)) < distancia_m(c, pie, c._suelo_de(b)))
		var d: Vector2 = c._suelo_de(lejos[0]) - pie
		var real := Vector2(d.x, d.y / SELLO_APLASTADO).normalized() * SELLO_ALCANCE_M * px_por_m(c)
		return {"principal": {}, "punto": pie + Vector2(real.x, real.y * SELLO_APLASTADO)}
	var mejor := -1
	var empatados: Array = []
	for h in cerca:
		var n := 0
		for o in vivos:
			if o["hp"] > 0 and not is_same(o, h) and distancia_m(c, c._suelo_de(h), c._suelo_de(o)) <= SELLO_RADIO_M:
				n += 1
		if n > mejor:
			mejor = n
			empatados = [h]
		elif n == mejor:
			empatados.append(h)
	var elegido: Dictionary = empatados[0] if empatados.size() == 1 else c._elegir_objetivo("agresivo", empatados)
	return {"principal": elegido, "punto": c._suelo_de(elegido), "aliados": mejor}


# El centro ahora: fijo desde 0,80; antes, sobre el principal (si sigue vivo) o el punto elegido.
static func _centro_sello(c, _f: Dictionary, at: Dictionary) -> Vector2:
	if at.get("centro_fijo", false):
		return at["centro"]
	var h: Dictionary = at.get("principal", {})
	if not h.is_empty() and h["hp"] > 0:
		return c._suelo_de(h)
	return at["centro"]


# Los héroes vivos dentro del círculo de «centro».
static func dentro_del_sello(c, centro: Vector2) -> Array:
	return c.heroes.filter(func(h): return h["hp"] > 0 and distancia_m(c, centro, c._suelo_de(h)) <= SELLO_RADIO_M)


# e01_a3: en su sitio (raíz quieta), la marca desde 0,20, el centro fijo a 0,80 y el IMPACTO a 1,30 a todos los de dentro.
static func _sello(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var eleccion := elegir_centro(c, f, vivos)
	_instancias += 1
	var principal: Dictionary = eleccion["principal"]
	var at := {"id": _instancias, "ataque": ATAQUE_ID_A3, "principal": principal, "resto": [], "golpeados": {},
		"t_impacto": -1, "centro": eleccion["punto"], "centro_fijo": false, "mult": mult, "dentro": [], "danos": {},
		"aliados_cerca": int(eleccion.get("aliados", -1))}
	f["e01_ataque"] = at
	_contar(f, "sello")
	c.registro.text = "%s gira la llave de su pecho: ¡Sello de Clausura%s!" % [f["nombre"],
		(" sobre %s" % principal["nombre"]) if not principal.is_empty() else ""]
	var golpe := func():
		if int(at["t_impacto"]) >= 0 or int(f["hp"]) <= 0:     # una vez; y muerto a medias, nada
			return
		at["t_impacto"] = Engine.get_process_frames()
		var centro := _centro_sello(c, f, at)
		at["centro"] = centro
		at["centro_fijo"] = true
		_quitar_marca(f)
		var dentro: Array = dentro_del_sello(c, centro)
		at["dentro"] = dentro.map(func(h): return h["nombre"])
		var golpeados: Array = []
		c.dano_magico_entrante = true                         # V12, accesorios: es magia (Anillo del Alba)
		for h in dentro:
			var obj: Dictionary = c._cubre(h)                 # la Guardia de Garon: se lo lleva él (una vez)
			if obj["hp"] <= 0 or not _registrar(f, at, obj):
				continue
			var d: int = maxi(1, int(randi_range(SELLO_DANO_MIN, SELLO_DANO_MAX) * mult))
			if obj.get("defendiendo", false):
				d = maxi(1, int(d * 0.5))
			d = c.Acc12.reducir(c, obj, d)
			var real: int = c._quitar_pv(obj, d)
			c._golpe_visual(obj, real, "")
			at["danos"][obj["nombre"]] = real
			golpeados.append(obj)
		c.dano_magico_entrante = false
		for h in golpeados:
			if lentitud(c, f, h):
				_contar(f, "lentitud")
		if not golpeados.is_empty():
			Sonido.golpe(false, golpeados.any(func(h): return h.get("defendiendo", false)))
		_pulso(c, centro)
		c._temblor(3.0)
	var p = c._p3d(f)
	if p == null or not p.has_method("sello"):
		await c.get_tree().create_timer(T_SELLO_IMPACTO).timeout
		golpe.call()
		await c.get_tree().create_timer(0.5).timeout
	else:
		f["animando"] = true
		Sonido.voz(f, "ataque")
		await p.sello(golpe)
		f["animando"] = false
	_quitar_marca(f)
	f.erase("e01_ataque")
	f["e01_ultimo"] = at
	f["e01_cd"] = CD_DE["sello"]
	f["e01_especial"] = "sello"
	c._actualizar()


# −SELLO_REDUCCION_VEL de velocidad hasta que le llegue su próximo turno (SELLO_TURNOS_LENTO). Se guarda lo quitado y se
# devuelve lo mismo (si otra cosa cambia su velocidad entre medias, no se pisa). Si ya estaba lento, no se acumula.
static func lentitud(c, f: Dictionary, h: Dictionary) -> bool:
	if h["hp"] <= 0 or h.has("e01_lento"):
		return false
	var quitado: float = float(h["vel"]) * SELLO_REDUCCION_VEL
	h["vel"] = float(h["vel"]) - quitado
	var lleno: bool = float(h.get("atb", 0.0)) >= c.ATB_MAX or c.cola.any(func(x): return is_same(x, h))
	h["e01_lento"] = {"quitado": quitado, "turnos": SELLO_TURNOS_LENTO, "espera_vaciar": lleno, "atb_max": c.ATB_MAX}
	if not f.has("e01_lentos"):
		f["e01_lentos"] = []
	f["e01_lentos"].append(h)
	c._numero_flotante(h, "Lento", COLOR_MARFIL, 26, Vector2(30, -30))
	return true


# Cada fotograma (repasar): al llegarle el turno al afectado (la barra llena), recupera su velocidad. Si al recibirlo ya
# la tenía llena, cuenta la siguiente barra.
static func _repasar_lentos(f: Dictionary, forzar := false) -> void:
	var lista: Array = f.get("e01_lentos", [])
	for h in lista.duplicate():
		var l = h.get("e01_lento", null)
		if not (l is Dictionary):
			lista.erase(h)
			continue
		var atb := float(h.get("atb", 0.0))
		if l["espera_vaciar"] and atb < float(l["atb_max"]):
			l["espera_vaciar"] = false
		if forzar or h["hp"] <= 0 or (not l["espera_vaciar"] and atb >= float(l["atb_max"])):
			l["turnos"] = int(l["turnos"]) - 1
			if forzar or h["hp"] <= 0 or int(l["turnos"]) <= 0:
				h["vel"] = float(h["vel"]) + float(l["quitado"])
				h.erase("e01_lento")
				lista.erase(h)
				_contar(f, "lentitud_fin")
			else:
				l["espera_vaciar"] = true


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
			if retroceso(c, h, float(at.get("retroceso", RETROCESO))):
				_contar(o, "retroceso")
		_polvo(c, obj)
	var p = c._p3d(o)
	var a2: bool = at.get("ataque", "") == ATAQUE_ID_A2
	if p == null or not p.has_method("porton" if a2 else "prensa"):
		golpe.call()
		await c.get_tree().create_timer(0.5).timeout
		return
	if a2:
		await _embestir(c, o, obj, golpe)
	else:
		await _ir_y_prensar(c, o, obj, golpe)


# El empuje de 0,4 m en el ATB: −15 % de la barra a quien lo recibe sin defender; nunca a quien ya está en la cola.
static func retroceso(c, h: Dictionary, cuanto := RETROCESO) -> bool:
	if h["hp"] <= 0 or h.get("defendiendo", false) or float(h.get("atb", 0.0)) >= c.ATB_MAX:
		return false
	for x in c.cola:
		if is_same(x, h):
			return false
	h["atb"] = maxf(0.0, float(h["atb"]) - c.ATB_MAX * cuanto)
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


# El Avance: aguanta en su sitio la anticipación (el clip), embiste en la carrera [1,00, 1,45) hasta el blanco (el
# impacto, a 1,30, lo da el clip), frena allí y vuelve andando. Muerto a medias, se queda donde cae.
static func _embestir(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var hueco: float = c.ANIM[o["modelo"]].get("distancia", 120.0) * 0.55 + c.ANIM[obj["modelo"]].get("distancia", 120.0) * 0.4
	var destino := base + Vector2(c._centro(obj).x - hueco - c._centro(o).x, (c._pos_ataque(obj).y - o["pos"].y) * 0.8)
	if obj.has("centro_ofs") and o.has("centro_ofs"):
		destino.y = base.y + (c._suelo_de(obj).y - c._suelo_de(o).y)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.25)
	var t1: Tween = c.create_tween()
	t1.tween_interval(T_CARRERA)
	t1.tween_property(rig, "position", destino, T_FRENO - T_CARRERA).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Sonido.voz(o, "ataque")
	await p.porton(golpe)
	if t1.is_valid() and t1.is_running():
		t1.kill()
	if o["hp"] > 0:
		var dur := clampf(rig.position.distance_to(base) / 260.0, 0.6, 1.4)
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


# La franja del Avance: un corredor en el suelo desde sus pies hasta el blanco y un poco más (el de detrás).
static func _marcar_franja(c, f: Dictionary, at: Dictionary) -> void:
	_quitar_marca(f)
	var raiz := Node2D.new()
	raiz.name = "MarcaAvance"
	raiz.z_index = 1
	c.escena.add_child(raiz)
	var a: Vector2 = c._suelo_de(f)
	var b: Vector2 = c._suelo_de(at["principal"])
	var dir := (b - a).normalized() if a.distance_to(b) > 1.0 else Vector2.RIGHT
	var fin := b + dir * (110.0 if not at["resto"].is_empty() else 50.0)
	var lado := Vector2(-dir.y, dir.x * 0.32) * FRANJA_ANCHO * 0.5 + Vector2(0, FRANJA_ANCHO * 0.16)
	var poli := PackedVector2Array([a - lado, fin - lado, fin + lado, a + lado])
	var r := Node2D.new()
	raiz.add_child(r)
	var fija := [false]
	var alfa := [0.0]
	r.draw.connect(func():
		r.draw_colored_polygon(poli, Color(COLOR_MARCA, (0.32 if fija[0] else 0.18) * alfa[0]))
		var borde := poli.duplicate()
		borde.append(poli[0])
		r.draw_polyline(borde, Color(COLOR_MARCA, (0.95 if fija[0] else 0.7) * alfa[0]), 6.0 if fija[0] else 4.0))
	f["e01_marca"] = raiz
	f["e01_marca_fija"] = fija
	var t: Tween = raiz.create_tween()
	t.tween_method(func(k: float):
		alfa[0] = k
		r.queue_redraw(), 0.0, 1.0, 0.25)


# La marca del Sello: un disco de cerradura (oscuro, opaco) con su ojo de llave y el borde marfil, del radio del círculo,
# en el suelo sobre el centro. Aparece a 0,20 s y, hasta que se fija a 0,80 s, se pone sobre el centro de ese momento.
static func _marcar_sello(c, f: Dictionary, at: Dictionary) -> void:
	_quitar_marca(f)
	var raiz := Node2D.new()
	raiz.name = "MarcaSello"
	# En el suelo DEBAJO de los luchadores (con las sombras, que se pintan encima): el disco es opaco y, encima de ellos,
	# taparía los pies de quien está dentro (visto en las capturas del 15/11). Las otras marcas, translúcidas, siguen igual.
	var suelo = c.get("sombras")
	if suelo is Node2D:
		suelo.add_child(raiz)
		suelo.move_child(raiz, 0)
	else:
		raiz.z_index = 1
		c.escena.add_child(raiz)
	var r := Node2D.new()
	r.position = _centro_sello(c, f, at)
	r.scale = Vector2(1.0, SELLO_APLASTADO)
	raiz.add_child(r)
	var radio: float = SELLO_RADIO_M * px_por_m(c)
	var fija := [false]
	var alfa := [0.0]
	r.draw.connect(func():
		var a: float = alfa[0]
		r.draw_circle(Vector2.ZERO, radio, Color(COLOR_SELLO, (0.82 if fija[0] else 0.55) * a))
		r.draw_arc(Vector2.ZERO, radio, 0.0, TAU, 72, Color(COLOR_MARFIL, (1.0 if fija[0] else 0.7) * a), 8.0 if fija[0] else 5.0)
		r.draw_arc(Vector2.ZERO, radio * 0.78, 0.0, TAU, 72, Color(COLOR_MARFIL, 0.35 * a), 3.0)
		# el ojo de la cerradura, en el mismo plano del suelo
		var k := radio * 0.16
		r.draw_circle(Vector2(0, -k * 1.6), k, Color(COLOR_MARFIL, 0.9 * a))
		r.draw_colored_polygon(PackedVector2Array([Vector2(-k * 0.55, -k * 1.2), Vector2(k * 0.55, -k * 1.2),
			Vector2(k * 0.9, k * 2.2), Vector2(-k * 0.9, k * 2.2)]), Color(COLOR_MARFIL, 0.9 * a)))
	f["e01_marca"] = raiz
	f["e01_marca_fija"] = fija
	at["marca_nodo"] = r
	var t: Tween = raiz.create_tween()
	t.tween_method(func(k: float):
		alfa[0] = k
		if is_instance_valid(r):
			if not at.get("centro_fijo", false):
				r.position = _centro_sello(c, f, at)
			r.queue_redraw(), 0.0, 1.0, 0.25)


# Un pulso marfil que se abre en el suelo (al fijar el centro y al golpear). Sin luces: la onda 2D de siempre.
static func _pulso(c, centro: Vector2) -> void:
	c._onda(centro, Color(COLOR_MARFIL, 0.9), 24.0, SELLO_RADIO_M * px_por_m(c), 0.4, 6.0)


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
	if f.has("e01_lentos"):                                 # Sello: la lentitud dura hasta el próximo turno del afectado
		_repasar_lentos(f)


static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if es(e):
			_quitar_marca(e)
			_repasar_lentos(e, true)                        # (la velocidad de los héroes, la de antes)


static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		var n = e.get("e01_marca", null)
		if es(e) and n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
			r.append("%s:e01_marca" % e["nombre"])
	return r
