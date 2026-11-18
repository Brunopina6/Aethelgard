extends SceneTree
# Velaria enganchada al combate (V12, 19/11; combate_velaria.gd), en combates de verdad (combate.tscn, GRUPOS[30]), sin
# ventana y con datos aislados. El combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo.
#   U. Apagada: el interruptor «velaria_v12» apagado por defecto y fuera de la partida; preparar() no cambia nada; solo
#      GRUPOS[30] la trae y no sale al azar; su carpeta no se precarga apagada; fila de afinidades.
#   A. Encendida, Kael solo, solo con ataques: entra con su clip; avisa el destello un turno antes (señal «aviso» del
#      modelo, «⚠ Cargando» sobre su vida, ningún daño); en el siguiente lo suelta (una señal «impacto», un solo cambio
#      de PV, y el daño llega DESPUÉS de soltar la luz) y se recompone el turno siguiente; el corte de ala (un impacto, un
#      cambio de PV); Defender deja el destello en la mitad o menos; Kael gana y Velaria cae con su clip de derrota.
#      Sonidos: cada aviso y cada impacto piden su sonido UNA vez y en el mismo fotograma de su señal; el aviso del corte,
#      una vez por corte y antes de su impacto; la entrada, una vez.
#   B. Apagada en su grupo (a mano, «grupo=30» sin el interruptor): personalidad «agresivo», nunca avisa; su golpe es
#      el corte de ala, con un solo impacto.
# Lo que hace en cada turno lo decide el combate (con la semilla fija); si en un combate no llega a avisar, a usar el
# corte o a ver un destello defendido, la prueba repite con otra semilla (hasta 8).

const ARCHIVO := "user://prueba_velaria_combate.save"
const MAX_FOTOGRAMAS := 9000
const V := preload("res://combate_velaria.gd")

var P
var G
var C
var c = null
var z = null                                      # el diccionario de Velaria
var zp = null                                     # su modelo 3D
var fallos: Array = []
var hechos: Array = []
var visto := {"entrada": false, "aviso": 0, "destello": 0, "corte": 0, "recupera": 0, "defendida": 0}
var sonidos: Array = []                           # [nombre, fotograma] que pide combate.gd (señal sonido_pedido)


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
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", V.INTERRUPTOR]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _combate(activos: Dictionary, semilla: int, encendida: bool) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	if encendida:
		Engine.set_meta(V.INTERRUPTOR, true)
	Engine.set_meta("zona", "desierto")              # sin «zona limpia»: no huye sola
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", V.GRUPOS_PRUEBA[0])
	c = load("res://combate.tscn").instantiate()
	sonidos.clear()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))   # antes de _ready: la entrada
	root.add_child(c)
	seed(semilla)
	z = c.enemigos[0]
	zp = c._p3d(z)


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(5)


func _probar() -> void:
	await _esperar(10)
	_u()
	for i in 8:
		await _a(20261119 + i * 7)
		if visto["aviso"] > 0 and visto["corte"] > 0 and visto["defendida"] > 0:
			break
	_ok(visto["entrada"], "A: Velaria no entra con su clip")
	_ok(visto["aviso"] > 0 and visto["destello"] > 0 and visto["recupera"] > 0, "A: no se vio aviso → destello → recomponerse: %s" % visto)
	_ok(visto["corte"] > 0, "A: no se vio el corte de ala: %s" % visto)
	_ok(visto["defendida"] > 0, "A: no se vio un destello defendido: %s" % visto)
	await _b()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos), " ", visto)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- U. apagada
func _u() -> void:
	_limpiar()
	_ok(not V.ACTIVO_POR_DEFECTO and not V.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not V.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "velaria", "personalidad": "agresivo"}
	V.preparar(e)
	_ok(e["personalidad"] == "agresivo" and not V.es(e), "U: apagada, preparar() cambia a Velaria")
	Engine.set_meta(V.INTERRUPTOR, true)
	V.preparar(e)
	_ok(V.es(e), "U: encendida, preparar() no le da su personalidad")
	Engine.remove_meta(V.INTERRUPTOR)
	for i in C.GRUPOS.size():
		var con: bool = C.GRUPOS[i].any(func(x): return x[0] == V.CLAVE)
		_ok(con == (i in V.GRUPOS_PRUEBA), "U: GRUPOS[%d] %s a Velaria" % [i, "trae" if con else "no trae"])
	for n in C.AL_AZAR_POR_TAMANO:
		_ok(not V.GRUPOS_PRUEBA.any(func(g): return g in C.AL_AZAR_POR_TAMANO[n]), "U: su grupo sale al azar con %d" % n)
	_ok(V.GRUPOS_PRUEBA.all(func(g): return g >= C.GRUPOS_AL_AZAR), "U: su grupo está entre los de al azar")
	_ok(load("res://recursos.gd").APAGADOS.get("res://enemigos/velaria/", "") == V.INTERRUPTOR, "U: su carpeta se precargaría apagada")
	_ok(load("res://combate_afinidades.gd").TABLA.has(V.CLAVE), "U: no está en la tabla de afinidades")
	_ok(C.MODELOS.has("velaria") and C.ENEMIGOS["velaria"]["modelo"] == "velaria", "U: falta su modelo en MODELOS")
	for s in ["velaria_aviso_destello", "velaria_destello", "velaria_aviso_corte", "velaria_corte", "velaria_entrada"]:
		_ok(load("res://sonido.gd").EFECTOS.has(s), "U: el sonido «%s» no está en el catálogo" % s)
	hechos.append("U: apagada")


# ---------------------------------------------------------------- A. encendida, Kael solo
func _a(semilla: int) -> void:
	_combate({"Kael": 1}, semilla, true)
	_ok(z["modelo"] == "velaria" and zp != null and zp.has_method("avisar") and V.es(z), "A: el grupo 30 no es Velaria en 3D con su personalidad")
	if zp == null:
		await _cerrar()
		return
	var avisos := [0]
	var impactos := [0]
	var derrota := [false]
	var marcas: Array = []                          # [qué, fotograma] de las señales del modelo
	zp.aviso.connect(func(_a):
		avisos[0] += 1
		marcas.append(["aviso", Engine.get_process_frames()]))
	zp.impacto.connect(func(a):
		impactos[0] += 1
		marcas.append([a, Engine.get_process_frames()]))
	zp.clip_terminado.connect(func(clip): if clip == "derrota": derrota[0] = true)
	await _esperar(2)
	if zp._clip == "entrada" or zp._entrando:
		visto["entrada"] = true
	var kael: Dictionary = c.heroes[0]
	var pv_antes: int = kael["hp"]
	var f_cambio := -1
	var cambios := 0
	var turno_z := false
	var cargaba := false
	var defendio := false
	var impactos0 := 0
	var avisos0 := 0
	var f_impacto := -1
	var pv_turno := 0
	var cargaba_antes := false
	var recupera_antes := false
	var recuperaba := false
	var f_fin := -1
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		if kael["hp"] != pv_antes:
			if turno_z:
				cambios += 1
				f_cambio = Engine.get_process_frames()
			pv_antes = kael["hp"]
		if turno_z and impactos[0] > impactos0 and f_impacto < 0:
			f_impacto = Engine.get_process_frames()
		if c.estado != "enemigo" and not turno_z:     # cómo estaba justo antes de su turno
			cargaba_antes = z.get("cargando", false)
			recupera_antes = z.get("recupera", false)
		if c.estado == "enemigo" and not turno_z:      # empieza el turno de Velaria
			turno_z = true
			cargaba = cargaba_antes
			recuperaba = recupera_antes
			cambios = 0
			f_cambio = -1
			f_impacto = -1
			impactos0 = impactos[0]
			avisos0 = avisos[0]
			pv_turno = kael["hp"]
		elif c.estado != "enemigo" and turno_z:        # acaba su turno: qué hizo
			turno_z = false
			var golpes: int = impactos[0] - impactos0
			if recuperaba:
				visto["recupera"] += 1
				_ok(golpes == 0 and cambios == 0 and c.registro.text.contains("recompone"), "A: al recomponerse golpea %d veces («%s»)" % [golpes, c.registro.text])
			elif cargaba:
				visto["destello"] += 1
				_ok(golpes == 1 and cambios <= 1, "A: el destello golpea %d veces y cambia los PV %d veces" % [golpes, cambios])
				_ok(z.get("recupera", false), "A: tras el destello no queda recomponiéndose")
				_ok(f_cambio < 0 or (f_impacto >= 0 and f_cambio > f_impacto), "A: el daño del destello (fotograma %d) no llega después de soltar la luz (%d)" % [f_cambio, f_impacto])
				if defendio:
					visto["defendida"] += 1
					var sin_defensa: int = int(z["atk"] * V.MULT_DESTELLO * (1.5 if z.get("furia", false) else 1.0)) + 3 - int(kael.get("def", 0) / 2.0)
					var dano: int = pv_turno - kael["hp"]
					_ok(dano >= 1 and dano <= int(sin_defensa * 0.5) + 1, "A: defendiendo, el destello quita %d (sin defender, hasta %d)" % [dano, sin_defensa])
			elif z.get("cargando", false):
				visto["aviso"] += 1
				_ok(avisos[0] - avisos0 == 1 and golpes == 0 and cambios == 0, "A: el aviso avisa %d veces, golpea %d y cambia PV %d" % [avisos[0] - avisos0, golpes, cambios])
				_ok(z["lbl_estado"].text.contains("Cargando"), "A: no se ve «⚠ Cargando» sobre su vida")
			elif golpes > 0:
				visto["corte"] += 1
				_ok(golpes == 1 and cambios <= 1, "A: el corte golpea %d veces y cambia los PV %d veces" % [golpes, cambios])
			defendio = false
		if c.estado == "menu" and c.actor is Dictionary and c.actor["nombre"] == "Kael":
			if z.get("cargando", false) and visto["defendida"] == 0:
				defendio = true
				c._defender()                          # ante el destello anunciado, en guardia
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(z)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 90:
			break
	_ok(c.estado == "fin" and z["hp"] <= 0 and kael["hp"] > 0, "A: Kael solo no gana (Kael %d PV, Velaria %d)" % [kael["hp"], z["hp"]])
	await _esperar(30)
	_ok(derrota[0] or zp._muerta, "A: Velaria no cae con su clip de derrota")
	_sonidos_a(marcas)
	await _cerrar()
	hechos.append("A (semilla %d)" % semilla)


# Los sonidos de Velaria (sonido.gd, tanda 4): cada aviso e impacto se pide UNA vez por su señal y en su mismo fotograma;
# el aviso del corte, al lanzarse (antes de su impacto); la entrada, una vez. Se mira lo que pide combate.gd.
func _sonidos_a(marcas: Array) -> void:
	var cuenta := func(n: String) -> int: return sonidos.filter(func(s): return s[0] == n).size()
	var de := func(q: String) -> Array: return marcas.filter(func(m): return m[0] == q)
	_ok(cuenta.call("velaria_entrada") == 1, "sonido: la entrada se pide %d veces" % cuenta.call("velaria_entrada"))
	for par in [["aviso", "velaria_aviso_destello"], ["destello_de_velo", "velaria_destello"], ["corte_de_ala", "velaria_corte"]]:
		var senales: Array = de.call(par[0])
		var pedidos: Array = sonidos.filter(func(s): return s[0] == par[1])
		_ok(pedidos.size() == senales.size(), "sonido: %s se pide %d veces para %d señales" % [par[1], pedidos.size(), senales.size()])
		for i in mini(pedidos.size(), senales.size()):
			_ok(pedidos[i][1] == senales[i][1], "sonido: %s no va en el fotograma de su señal (%d y %d)" % [par[1], pedidos[i][1], senales[i][1]])
	var cortes: Array = de.call("corte_de_ala")
	var avisos_c: Array = sonidos.filter(func(s): return s[0] == V.AVISO_CORTE)
	_ok(avisos_c.size() == cortes.size(), "sonido: el aviso del corte se pide %d veces para %d cortes" % [avisos_c.size(), cortes.size()])
	for i in mini(avisos_c.size(), cortes.size()):
		_ok(avisos_c[i][1] < cortes[i][1], "sonido: el aviso del corte no va antes de su impacto")


# ---------------------------------------------------------------- B. apagada en su grupo
func _b() -> void:
	_combate({"Kael": 5}, 11, false)
	_ok(z["personalidad"] == "agresivo" and not V.es(z), "B: apagada, Velaria tiene la personalidad «%s»" % z["personalidad"])
	if zp == null:
		_ok(false, "B: sin su modelo 3D")
		await _cerrar()
		return
	var avisos := [0]
	var impactos: Array = []
	zp.aviso.connect(func(_a): avisos[0] += 1)
	zp.impacto.connect(func(a): impactos.append(a))
	var turno_z := false
	var turnos := 0
	for fr in 6000:
		await _esperar(1)
		if c.estado == "enemigo" and not turno_z:
			turno_z = true
		elif c.estado != "enemigo" and turno_z:
			turno_z = false
			turnos += 1
			if turnos >= 2:
				break
		if c.estado == "menu" and c.actor is Dictionary:
			c._defender()                              # Kael solo se defiende: se ven sus turnos
		if c.estado == "fin":
			break
	_ok(turnos >= 1, "B: Velaria no llega a actuar")
	_ok(avisos[0] == 0, "B: apagada avisa %d veces" % avisos[0])
	_ok(impactos.size() == turnos and impactos.all(func(a): return a == V.CORTE), "B: apagada, %d turnos y estos impactos %s" % [turnos, impactos])
	await _cerrar()
	hechos.append("B: apagada, %d turnos con el corte" % turnos)
