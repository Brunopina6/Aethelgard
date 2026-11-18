extends SceneTree
# El Cencerrante enganchado al combate (V12, 19/11; combate_cencerrante.gd), en combates de verdad (combate.tscn,
# GRUPOS[31] con un Zarzalín y GRUPOS[32] solo), sin ventana y con datos aislados. El combate no guarda (sin
# «desde_mapa») y la partida apunta a su propio archivo.
#   U. Apagado: el interruptor «cencerrante_v12» apagado por defecto y fuera de la partida; preparar() no cambia nada;
#      solo GRUPOS[31] y [32] lo traen y no salen al azar; su carpeta no se precarga apagado; fila de afinidades; el
#      refuerzo (reforzar()) multiplica una sola vez y sin la marca no cambia nada.
#   A. Encendido, con un Zarzalín (GRUPOS[31]; Kael, Lya y Garon): entra con su clip; su primer turno es el toque de
#      alarma: la señal «aviso» del modelo UNA vez en todo el combate, ningún daño ni impacto, el Zarzalín queda
#      reforzado («▲ Reforzado» sobre su vida) y él NO prepara su propio ataque; el refuerzo se pone una vez y se gasta
#      en el siguiente golpe del Zarzalín (un solo impacto en ese turno); la campanada baja con un impacto; ganan los
#      héroes y cae con su derrota. Sonidos: el toque («cencerrante_aviso_alarma») y su repique («cencerrante_alarma»,
#      en el fotograma de la señal) UNA vez; cada campanada pide su aviso antes y su impacto una vez en su fotograma.
#   B. Encendido y solo (GRUPOS[32], Kael solo): el toque prepara SU ataque («⚠ Cargando», sin daño, nadie reforzado) y
#      el turno siguiente la campanada preparada golpea una vez; Defender la deja a la mitad o menos; nunca toca dos
#      veces; Kael gana.
#   C. Apagado en su grupo (a mano, «grupo=31» sin el interruptor): personalidad «agresivo», nunca toca ni refuerza; sus
#      golpes son la campanada baja, con un solo impacto.
# Lo que hace en cada turno lo decide el combate (con la semilla fija); si en B no llega a tocar, la prueba repite con
# otra semilla (hasta 8).

const ARCHIVO := "user://prueba_cencerrante_combate.save"
const MAX_FOTOGRAMAS := 12000
const K := preload("res://combate_cencerrante.gd")


class Falso:                                      # lo único de combate.gd que usa reforzar(): el número flotante
	var numeros := 0

	func _numero_flotante(_f, _t, _c, _s) -> void:
		numeros += 1


var P
var G
var C
var c = null
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []                           # [nombre, fotograma] que pide combate.gd (señal sonido_pedido)
var visto := {"toque_aliado": 0, "refuerzo_gastado": 0, "campanada": 0, "toque_solo": 0, "preparada": 0, "defendida": 0}


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	C = load("res://combate.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", K.INTERRUPTOR]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _combate(activos: Dictionary, grupo: int, semilla: int, encendido: bool) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	if encendido:
		Engine.set_meta(K.INTERRUPTOR, true)
	Engine.set_meta("zona", "desierto")              # sin «zona limpia»: nadie huye solo
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))   # antes de _ready: la entrada
	root.add_child(c)
	seed(semilla)


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(5)


func _de(clave: String) -> Dictionary:
	for e in c.enemigos:
		if e["clave"] == clave:
			return e
	return {}


func _pv_heroes() -> int:
	var t := 0
	for h in c.heroes:
		t += int(h["hp"])
	return t


func _cuenta(n: String) -> int:
	return sonidos.filter(func(s): return s[0] == n).size()


func _probar() -> void:
	await _esperar(10)
	_u()
	await _a()
	for i in 8:
		await _b(20261119 + i * 7)
		if visto["toque_solo"] > 0 and visto["preparada"] > 0 and visto["defendida"] > 0:
			break
	_ok(visto["toque_solo"] > 0 and visto["preparada"] > 0, "B: no se vio toque a solas → campanada preparada: %s" % visto)
	_ok(visto["defendida"] > 0, "B: no se vio una campanada preparada defendida: %s" % visto)
	await _c()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos), " ", visto)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- U. apagado
func _u() -> void:
	_limpiar()
	_ok(not K.ACTIVO_POR_DEFECTO and not K.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not K.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "cencerrante", "personalidad": "agresivo"}
	K.preparar(e)
	_ok(e["personalidad"] == "agresivo" and not K.es(e), "U: apagado, preparar() cambia al Cencerrante")
	Engine.set_meta(K.INTERRUPTOR, true)
	K.preparar(e)
	_ok(K.es(e), "U: encendido, preparar() no le da su personalidad")
	var z := {"clave": "zarzalin", "personalidad": "embiste"}
	K.preparar(z)
	_ok(z["personalidad"] == "embiste", "U: encendido, preparar() cambia a otro enemigo")
	Engine.remove_meta(K.INTERRUPTOR)
	for i in C.GRUPOS.size():
		var con: bool = C.GRUPOS[i].any(func(x): return x[0] == K.CLAVE)
		_ok(con == (i in K.GRUPOS_PRUEBA), "U: GRUPOS[%d] %s al Cencerrante" % [i, "trae" if con else "no trae"])
	_ok(C.GRUPOS[31].any(func(x): return x[0] == "zarzalin") and C.GRUPOS[32].size() == 1, "U: GRUPOS[31] sin Zarzalín o GRUPOS[32] no es él solo")
	for n in C.AL_AZAR_POR_TAMANO:
		_ok(not K.GRUPOS_PRUEBA.any(func(g): return g in C.AL_AZAR_POR_TAMANO[n]), "U: su grupo sale al azar con %d" % n)
	_ok(K.GRUPOS_PRUEBA.all(func(g): return g >= C.GRUPOS_AL_AZAR), "U: su grupo está entre los de al azar")
	_ok(load("res://recursos.gd").APAGADOS.get("res://enemigos/cencerrante/", "") == K.INTERRUPTOR, "U: su carpeta se precargaría apagado")
	_ok(load("res://combate_afinidades.gd").TABLA.has(K.CLAVE), "U: no está en la tabla de afinidades")
	_ok(C.MODELOS.has("cencerrante") and C.ENEMIGOS["cencerrante"]["modelo"] == "cencerrante"
		and C.ENEMIGOS["cencerrante"]["personalidad"] == "agresivo", "U: falta su modelo en MODELOS o no es «agresivo» apagado")
	for s in [K.SONIDO_TOQUE, K.SONIDO_REPIQUE, K.SONIDO_CAMPANADA, "cencerrante_campanada", "cencerrante_entrada"]:
		_ok(load("res://sonido.gd").EFECTOS.has(s), "U: el sonido «%s» no está en el catálogo" % s)
	# reforzar(): sin la marca, el mismo daño y sin tocar nada; con ella, ×MULT_REFUERZO una sola vez
	var sin := {"nombre": "x"}
	var falso := Falso.new()
	_ok(K.reforzar(falso, sin, 40) == 40 and sin.size() == 1 and falso.numeros == 0, "U: sin la marca, reforzar() cambia el golpe")
	var con := {"nombre": "x", K.MARCA: true}
	var d1: int = K.reforzar(falso, con, 40)
	var d2: int = K.reforzar(falso, con, 40)
	_ok(d1 == int(40 * K.MULT_REFUERZO) and d2 == 40 and not con.has(K.MARCA) and falso.numeros == 1,
		"U: el refuerzo da %d y luego %d (esperado %d y 40, una sola vez)" % [d1, d2, int(40 * K.MULT_REFUERZO)])
	hechos.append("U: apagado")


# ---------------------------------------------------------------- A. encendido, con un Zarzalín
func _a() -> void:
	_combate({"Kael": 6, "Lya": 6, "Garon": 6}, 31, 20261119, true)
	var k: Dictionary = _de("cencerrante")
	var z: Dictionary = _de("zarzalin")
	var kp = c._p3d(k) if not k.is_empty() else null
	var zp = c._p3d(z) if not z.is_empty() else null
	_ok(not k.is_empty() and kp != null and kp.has_method("campana") and K.es(k), "A: el grupo 31 no trae al Cencerrante en 3D con su personalidad")
	_ok(not z.is_empty() and zp != null and z["personalidad"] == "embiste", "A: el grupo 31 no trae al Zarzalín de siempre")
	if kp == null or zp == null:
		await _cerrar()
		return
	var avisos: Array = []                          # fotogramas de la señal «aviso» del Cencerrante
	var impactos: Array = []                        # [ataque, fotograma] del Cencerrante
	var imp_z := [0]
	var derrota := [false]
	kp.aviso.connect(func(_x): avisos.append(Engine.get_process_frames()))
	kp.impacto.connect(func(x): impactos.append([x, Engine.get_process_frames()]))
	kp.clip_terminado.connect(func(clip): if clip == "derrota": derrota[0] = true)
	zp.impacto.connect(func(_x): imp_z[0] += 1)
	await _esperar(2)
	_ok(kp._clip == "entrada" or kp._entrando, "A: el Cencerrante no entra con su clip")
	var quien = null                                # el enemigo que actúa (c.atacante_actual)
	var cambios := 0
	var pv_previo := 0
	var imp0 := 0
	var impz0 := 0
	var av0 := 0
	var marcado_antes := false
	var subidas := 0
	var bajadas := 0
	var f_fin := -1
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		var pv := _pv_heroes()
		if quien == null and c.atacante_actual != null:             # empieza el turno de un enemigo
			quien = c.atacante_actual
			pv_previo = pv
			cambios = 0
			imp0 = impactos.size()
			impz0 = imp_z[0]
			av0 = avisos.size()
		var marcado: bool = z.get(K.MARCA, false)
		if marcado and not marcado_antes:
			subidas += 1
			var txt: String = z["lbl_estado"].text if z.has("lbl_estado") else "(sin rótulo)"
			_ok(txt.contains("Reforzado"), "A: el Zarzalín reforzado no lo dice sobre su vida («%s»)" % txt)
		if marcado_antes and not marcado:
			bajadas += 1
			_ok(is_same(quien, z), "A: el refuerzo se gasta fuera del turno del Zarzalín")
		marcado_antes = marcado
		if quien != null and pv != pv_previo:
			cambios += 1
		pv_previo = pv
		if quien != null and c.atacante_actual == null:             # acaba: qué hizo
			if is_same(quien, k):
				var golpes: int = impactos.size() - imp0
				if avisos.size() > av0:
					visto["toque_aliado"] += 1
					_ok(golpes == 0 and cambios == 0, "A: el toque golpea %d veces y cambia PV %d veces" % [golpes, cambios])
					_ok(z.get(K.MARCA, false) or z["hp"] <= 0, "A: tras el toque el Zarzalín no queda reforzado")
					_ok(not k.get("cargando", false) and not k.get(K.MARCA, false), "A: con aliado, el toque prepara su propio ataque")
				elif golpes > 0:
					visto["campanada"] += 1
					_ok(golpes == 1 and cambios <= 1, "A: la campanada golpea %d veces y cambia PV %d veces" % [golpes, cambios])
			elif is_same(quien, z) and bajadas > 0 and visto["refuerzo_gastado"] == 0:
				visto["refuerzo_gastado"] += 1
				_ok(imp_z[0] - impz0 == 1, "A: el golpe reforzado del Zarzalín da %d impactos" % (imp_z[0] - impz0))
			quien = null
		if c.estado == "menu" and c.actor is Dictionary:
			if not k.get("toque_usado", false) or (z["hp"] > 0 and (z.get(K.MARCA, false) or z.get("cargando", false))):
				c._defender()                          # hasta ver el toque y el golpe reforzado, en guardia
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(z if z["hp"] > 0 else k)   # primero el Zarzalín: así el Cencerrante llega a usar la campanada
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 90:
			break
	_ok(c.estado == "fin" and k["hp"] <= 0 and z["hp"] <= 0, "A: los héroes no ganan (Cencerrante %d PV, Zarzalín %d, héroes %d)" % [k["hp"], z["hp"], _pv_heroes()])
	_ok(visto["toque_aliado"] == 1 and avisos.size() == 1, "A: el toque se da %d veces (señales: %d); debe ser una" % [visto["toque_aliado"], avisos.size()])
	_ok(subidas == 1 and bajadas == 1, "A: el refuerzo se pone %d veces y se gasta %d (debe ser una y una)" % [subidas, bajadas])
	_ok(visto["refuerzo_gastado"] == 1, "A: no se vio el golpe reforzado del Zarzalín")
	_ok(visto["campanada"] > 0, "A: no se vio la campanada baja: %s" % visto)
	_ok(impactos.all(func(x): return x[0] == K.CAMPANADA), "A: impactos que no son la campanada: %s" % str(impactos))
	await _esperar(30)
	_ok(derrota[0] or kp._muerta, "A: el Cencerrante no cae con su clip de derrota")
	# sonidos: el toque y su repique, una vez (el repique en el fotograma de la señal); cada campanada, su aviso antes
	# y su impacto una vez, en el fotograma de su señal; la entrada, una vez
	_ok(_cuenta("cencerrante_entrada") == 1, "sonido: la entrada se pide %d veces" % _cuenta("cencerrante_entrada"))
	_ok(_cuenta(K.SONIDO_TOQUE) == 1, "sonido: el toque se pide %d veces" % _cuenta(K.SONIDO_TOQUE))
	var rep: Array = sonidos.filter(func(s): return s[0] == K.SONIDO_REPIQUE)
	_ok(rep.size() == 1 and avisos.size() == 1 and rep[0][1] == avisos[0], "sonido: el repique se pide %s para la señal %s" % [str(rep), str(avisos)])
	_ok(_cuenta("cencerrante_aviso_toque") == 0, "sonido: se pide «cencerrante_aviso_toque», que no existe")
	_sonidos_campanada(impactos, "A")
	await _cerrar()
	hechos.append("A: toque con aliado una vez, refuerzo gastado por el Zarzalín, %d campanadas" % visto["campanada"])


func _sonidos_campanada(impactos: Array, parte: String) -> void:
	var golpes: Array = sonidos.filter(func(s): return s[0] == "cencerrante_campanada")
	var avisos_c: Array = sonidos.filter(func(s): return s[0] == K.SONIDO_CAMPANADA)
	_ok(golpes.size() == impactos.size(), "sonido %s: la campanada se pide %d veces para %d impactos" % [parte, golpes.size(), impactos.size()])
	for i in mini(golpes.size(), impactos.size()):
		_ok(golpes[i][1] == impactos[i][1], "sonido %s: la campanada no va en el fotograma de su impacto (%d y %d)" % [parte, golpes[i][1], impactos[i][1]])
	_ok(avisos_c.size() == impactos.size(), "sonido %s: el aviso de la campanada se pide %d veces para %d impactos" % [parte, avisos_c.size(), impactos.size()])
	for i in mini(avisos_c.size(), impactos.size()):
		_ok(avisos_c[i][1] < impactos[i][1], "sonido %s: el aviso de la campanada no va antes de su impacto" % parte)


# ---------------------------------------------------------------- B. encendido y solo
func _b(semilla: int) -> void:
	_combate({"Kael": 5}, 32, semilla, true)
	var k: Dictionary = _de("cencerrante")
	var kp = c._p3d(k) if not k.is_empty() else null
	_ok(c.enemigos.size() == 1 and kp != null and K.es(k), "B: el grupo 32 no es el Cencerrante solo, en 3D y con su personalidad")
	if kp == null:
		await _cerrar()
		return
	var avisos := [0]
	var impactos: Array = []
	kp.aviso.connect(func(_x): avisos[0] += 1)
	kp.impacto.connect(func(x): impactos.append([x, Engine.get_process_frames()]))
	var kael: Dictionary = c.heroes[0]
	var turno := false
	var cargaba_antes := false
	var cargaba := false
	var defendio := false
	var pv0 := 0
	var cambios := 0
	var pv_previo: int = kael["hp"]
	var imp0 := 0
	var av0 := 0
	var f_fin := -1
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		if turno and kael["hp"] != pv_previo:
			cambios += 1
		pv_previo = kael["hp"]
		if not turno and c.atacante_actual == null:
			cargaba_antes = k.get("cargando", false)
		if not turno and c.atacante_actual != null:
			turno = true
			cargaba = cargaba_antes
			pv0 = kael["hp"]
			cambios = 0
			imp0 = impactos.size()
			av0 = avisos[0]
		elif turno and c.atacante_actual == null:
			turno = false
			var golpes: int = impactos.size() - imp0
			if avisos[0] > av0:
				visto["toque_solo"] += 1
				_ok(avisos[0] - av0 == 1 and golpes == 0 and cambios == 0, "B: el toque a solas avisa %d, golpea %d y cambia PV %d" % [avisos[0] - av0, golpes, cambios])
				_ok(k.get("cargando", false) and k["lbl_estado"].text.contains("Cargando"), "B: a solas, el toque no prepara su ataque («%s»)" % k["lbl_estado"].text)
				_ok(not k.get(K.MARCA, false), "B: a solas, el toque lo refuerza como a un aliado")
			elif cargaba:
				visto["preparada"] += 1
				_ok(golpes == 1 and cambios <= 1, "B: la campanada preparada golpea %d veces y cambia PV %d" % [golpes, cambios])
				if defendio:
					visto["defendida"] += 1
					var sin_defensa: int = int(k["atk"] * K.MULT_PROPIA * (1.5 if k.get("furia", false) else 1.0)) + 3 - int(kael.get("def", 0) / 2.0)
					var dano: int = pv0 - kael["hp"]
					_ok(dano >= 1 and dano <= int(sin_defensa * 0.5) + 1, "B: defendiendo, la campanada preparada quita %d (sin defender, hasta %d)" % [dano, sin_defensa])
			defendio = false
		if c.estado == "menu" and c.actor is Dictionary:
			if k.get("cargando", false):
				defendio = true
				c._defender()                          # ante la campanada anunciada, en guardia
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(k)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 90:
			break
	_ok(c.estado == "fin" and k["hp"] <= 0 and kael["hp"] > 0, "B: Kael solo no gana (Kael %d PV, Cencerrante %d)" % [kael["hp"], k["hp"]])
	_ok(avisos[0] <= 1, "B: a solas toca %d veces (una como mucho)" % avisos[0])
	_ok(_cuenta(K.SONIDO_TOQUE) == avisos[0] and _cuenta(K.SONIDO_REPIQUE) == avisos[0],
		"B: el toque y su repique se piden %d y %d veces para %d toques" % [_cuenta(K.SONIDO_TOQUE), _cuenta(K.SONIDO_REPIQUE), avisos[0]])
	_sonidos_campanada(impactos, "B")
	await _cerrar()
	hechos.append("B (semilla %d, %d toque)" % [semilla, avisos[0]])


# ---------------------------------------------------------------- C. apagado en su grupo
func _c() -> void:
	_combate({"Kael": 10}, 31, 11, false)
	var k: Dictionary = _de("cencerrante")
	var z: Dictionary = _de("zarzalin")
	var kp = c._p3d(k) if not k.is_empty() else null
	_ok(not k.is_empty() and k["personalidad"] == "agresivo" and not K.es(k), "C: apagado, el Cencerrante tiene la personalidad «%s»" % k.get("personalidad", ""))
	if kp == null:
		_ok(false, "C: sin su modelo 3D")
		await _cerrar()
		return
	var avisos := [0]
	var impactos: Array = []
	kp.aviso.connect(func(_x): avisos[0] += 1)
	kp.impacto.connect(func(x): impactos.append(x))
	var quien = null
	var turnos := 0
	var marcas := 0
	var imp0 := 0
	for fr in 8000:
		await _esperar(1)
		if z.get(K.MARCA, false) or k.get(K.MARCA, false):
			marcas += 1
		if quien == null and c.atacante_actual != null:
			quien = c.atacante_actual
			imp0 = impactos.size()
		elif quien != null and c.atacante_actual == null:
			if is_same(quien, k):
				turnos += 1
				_ok(impactos.size() - imp0 <= 1, "C: un turno apagado con %d impactos" % (impactos.size() - imp0))
			quien = null
			if (turnos >= 2 and impactos.size() >= 1) or turnos >= 5:
				break
		if c.estado == "menu" and c.actor is Dictionary:
			c._defender()                              # Kael solo se defiende: se ven sus turnos
		if c.estado == "fin":
			break
	_ok(turnos >= 1, "C: el Cencerrante no llega a actuar")
	_ok(avisos[0] == 0 and marcas == 0 and not k.get("toque_usado", false), "C: apagado toca %d veces y refuerza %d fotogramas" % [avisos[0], marcas])
	_ok(impactos.size() >= 1 and impactos.size() <= turnos and impactos.all(func(a): return a == K.CAMPANADA), "C: apagado, %d turnos y estos impactos %s" % [turnos, impactos])
	_ok(_cuenta(K.SONIDO_TOQUE) == 0 and _cuenta(K.SONIDO_REPIQUE) == 0, "C: apagado suena el toque")
	await _cerrar()
	hechos.append("C: apagado, %d turnos con la campanada" % turnos)
