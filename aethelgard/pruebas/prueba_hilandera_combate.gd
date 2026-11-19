extends SceneTree
# La Hilandera del Eco enganchada al combate (V12, 19/11; combate_hilandera.gd), en combates de verdad (combate.tscn,
# GRUPOS[33]), sin ventana y con datos aislados. El combate no guarda (sin «desde_mapa») y la partida apunta a su propio
# archivo.
#   U. Apagada: el interruptor «hilandera_v12» apagado por defecto y fuera de la partida; preparar() no cambia nada; solo
#      GRUPOS[33] la trae y no sale al azar; su carpeta no se precarga apagada; fila de afinidades, modelo y sonidos; el
#      anillo del pulso es suyo: hueco, violeta y sin mezcla aditiva (revisión 19/11).
#   A. Encendida, con Kael, Lya y Garon: entra con su clip. Mientras no se haya visto todo, los héroes se defienden; luego
#      atacan hasta ganar. En cada turno suyo:
#        · MARCA: una señal «aviso», ningún impacto ni cambio de PV, «⚠ Cargando» sobre su vida y la señal sobre el héroe
#          marcado (un nodo vivo, visible) y en el registro la frase neutra «¡es su presa!» con su nombre;
#        · MORDIDA (el turno siguiente a marcar): un impacto «mordida_resonante», como mucho un cambio de PV y solo del
#          objetivo, la marca fuera y vuelve a su sitio; defendida, la mitad o menos;
#        · TRAMA: un impacto «trama_de_eco», UNA resolución (todos los héroes vivos pierden PV una vez y en el MISMO
#          fotograma), UN anillo y queda recuperándose;
#        · RECUPERACIÓN (siempre el turno siguiente a la trama): ningún impacto ni cambio de PV.
#      Los héroes ganan, cae con su clip de derrota y no quedan marcas. Sonidos: cada señal «aviso» e «impacto» pide su
#      sonido (hilandera_aviso_mordida / _aviso_trama / _mordida / _trama) UNA vez y en el fotograma de su señal; la
#      entrada, una vez.
#   B. Apagada en su grupo (a mano, «grupo=33» sin el interruptor): personalidad «agresivo», nunca marca ni teje la
#      trama; sus golpes son la mordida, con un solo impacto.
# Lo que hace en cada turno lo decide el combate (con la semilla fija); si en un combate no llega a verse todo, la prueba
# repite con otra semilla (hasta 8).

const ARCHIVO := "user://prueba_hilandera_combate.save"
const MAX_FOTOGRAMAS := 20000
const H := preload("res://combate_hilandera.gd")
const ACTIVOS := {"Kael": 8, "Lya": 8, "Garon": 8}

var P
var G
var C
var c = null
var z = null                                      # el diccionario de la Hilandera
var zp = null                                     # su modelo 3D
var fallos: Array = []
var hechos: Array = []
var visto := {"entrada": false, "marca": 0, "mordida": 0, "defendida": 0, "trama": 0, "recupera": 0, "vuelta": 0}
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
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", H.INTERRUPTOR]:
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
		Engine.set_meta(H.INTERRUPTOR, true)
	Engine.set_meta("zona", "desierto")              # sin «zona limpia»: no huye sola
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", H.GRUPOS_PRUEBA[0])
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


func _todo_visto() -> bool:
	return visto["marca"] > 0 and visto["mordida"] > 0 and visto["defendida"] > 0 and visto["trama"] > 0 \
		and visto["recupera"] > 0


func _probar() -> void:
	await _esperar(10)
	_u()
	for i in 8:
		await _a(20261119 + i * 7)
		if _todo_visto():
			break
	_ok(visto["entrada"], "A: la Hilandera no entra con su clip")
	_ok(visto["marca"] > 0 and visto["mordida"] > 0, "A: no se vio marca → mordida: %s" % visto)
	_ok(visto["defendida"] > 0, "A: no se vio una mordida defendida: %s" % visto)
	_ok(visto["trama"] > 0 and visto["recupera"] > 0, "A: no se vio trama → recuperación: %s" % visto)
	_ok(visto["vuelta"] == visto["mordida"], "A: tras %d mordidas solo vuelve a su sitio %d veces" % [visto["mordida"], visto["vuelta"]])
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
	_ok(not H.ACTIVO_POR_DEFECTO and not H.activo(), "U: el interruptor no está apagado por defecto")
	_ok(not H.INTERRUPTOR in P.CLAVES, "U: el interruptor se guardaría en la partida")
	var e := {"clave": "hilandera", "personalidad": "agresivo"}
	H.preparar(e)
	_ok(e["personalidad"] == "agresivo" and not H.es(e), "U: apagada, preparar() cambia a la Hilandera")
	Engine.set_meta(H.INTERRUPTOR, true)
	H.preparar(e)
	_ok(H.es(e), "U: encendida, preparar() no le da su personalidad")
	Engine.remove_meta(H.INTERRUPTOR)
	for i in C.GRUPOS.size():
		var con: bool = C.GRUPOS[i].any(func(x): return x[0] == H.CLAVE)
		_ok(con == (i in H.GRUPOS_PRUEBA), "U: GRUPOS[%d] %s a la Hilandera" % [i, "trae" if con else "no trae"])
	for n in C.AL_AZAR_POR_TAMANO:
		_ok(not H.GRUPOS_PRUEBA.any(func(g): return g in C.AL_AZAR_POR_TAMANO[n]), "U: su grupo sale al azar con %d" % n)
	_ok(H.GRUPOS_PRUEBA.all(func(g): return g >= C.GRUPOS_AL_AZAR), "U: su grupo está entre los de al azar")
	_ok(load("res://recursos.gd").APAGADOS.get("res://enemigos/hilandera/", "") == H.INTERRUPTOR, "U: su carpeta se precargaría apagada")
	_ok(load("res://combate_afinidades.gd").TABLA.has(H.CLAVE), "U: no está en la tabla de afinidades")
	_ok(C.MODELOS.has("hilandera") and C.ENEMIGOS["hilandera"]["modelo"] == "hilandera", "U: falta su modelo en MODELOS")
	for s in ["hilandera_aviso_mordida", "hilandera_mordida", "hilandera_aviso_trama", "hilandera_trama", "hilandera_entrada",
			"hilandera_herido", "hilandera_caida"]:
		_ok(load("res://sonido.gd").EFECTOS.has(s), "U: el sonido «%s» no está en el catálogo" % s)
	_anillo_u()
	hechos.append("U: apagada")


# El pulso de la trama (revisión 19/11): un ANILLO del violeta de sus placas, hueco en el centro y sin mezcla aditiva
# (la textura de brillo aditiva salía como un resplandor blanquecino sobre el cuerpo, no como un anillo violeta).
func _anillo_u() -> void:
	var metodos: Array = (H as Script).get_script_method_list().map(func(m): return m["name"])
	if not "sprite_anillo" in metodos:
		_ok(false, "U: no hay sprite_anillo(): el pulso de la trama no es un anillo propio")
		return
	var hs = load("res://combate_hilandera.gd")      # (sin el preload: que la prueba cargue aunque falte la función)
	var s: Sprite2D = hs.call("sprite_anillo")
	_ok(s.material == null, "U: el anillo lleva material %s (aditivo: sale blanquecino)" % s.material)
	var t = s.texture
	_ok(t is GradientTexture2D and t.fill == GradientTexture2D.FILL_RADIAL, "U: el anillo no es una textura radial")
	if t is GradientTexture2D:
		var gr: Gradient = t.gradient
		var centro: Color = gr.sample(0.0)
		var borde: Color = gr.sample(1.0)
		var banda := Color(0, 0, 0, 0)
		for i in 101:
			var k: Color = gr.sample(i / 100.0)
			if k.a > banda.a:
				banda = k
		var tinte: Color = Color(banda.r * s.modulate.r, banda.g * s.modulate.g, banda.b * s.modulate.b, banda.a * s.modulate.a)
		_ok(centro.a < 0.05 and borde.a < 0.05, "U: el anillo no es hueco (centro %.2f, borde %.2f)" % [centro.a, borde.a])
		_ok(tinte.a >= 0.8, "U: la banda del anillo apenas se ve (alfa %.2f)" % tinte.a)
		_ok(tinte.b > tinte.g + 0.25 and tinte.r > tinte.g + 0.05, "U: la banda del anillo no es violeta: %s" % tinte)
	s.free()


# ---------------------------------------------------------------- A. encendida, Kael, Lya y Garon
func _a(semilla: int) -> void:
	_combate(ACTIVOS, semilla, true)
	_ok(z["modelo"] == "hilandera" and zp != null and zp.has_method("placas") and H.es(z), "A: el grupo 33 no es la Hilandera en 3D con su personalidad")
	if zp == null:
		await _cerrar()
		return
	var avisos := [0]
	var impactos: Array = []                        # [ataque, fotograma]
	var derrota := [false]
	var marcas: Array = []                          # [qué, fotograma] de las señales del modelo
	zp.aviso.connect(func(a):
		avisos[0] += 1
		marcas.append(["aviso:" + a, Engine.get_process_frames()]))
	zp.impacto.connect(func(a):
		impactos.append([a, Engine.get_process_frames()])
		marcas.append([a, Engine.get_process_frames()]))
	zp.clip_terminado.connect(func(clip): if clip == "derrota": derrota[0] = true)
	await _esperar(2)
	if zp._clip == "entrada" or zp._entrando:
		visto["entrada"] = true
	var pv_antes := {}
	for h in c.heroes:
		pv_antes[h["nombre"]] = h["hp"]
	var cambios: Array = []                         # [héroe, fotograma, cuánto] durante su turno
	var turno_z := false
	var antes := {"cargando": false, "recupera": false, "objetivo": null}
	var en_turno := {}
	var impactos0 := 0
	var avisos0 := 0
	var pulsos0 := 0
	var anillos0 := 0
	var ultimo := ""                                # lo último que hizo (para ver que la trama va seguida de recuperar)
	var f_fin := -1
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		for h in c.heroes:
			if h["hp"] != pv_antes[h["nombre"]]:
				if turno_z:
					cambios.append([h["nombre"], Engine.get_process_frames(), pv_antes[h["nombre"]] - h["hp"]])
				pv_antes[h["nombre"]] = h["hp"]
		if c.estado != "enemigo" and not turno_z:     # cómo estaba justo antes de su turno
			antes = {"cargando": z.get("cargando", false), "recupera": z.get("recupera", false),
				"objetivo": z.get("objetivo_carga", null)}
		if c.estado == "enemigo" and not turno_z:      # empieza el turno de la Hilandera
			turno_z = true
			en_turno = antes.duplicate()
			var obj = en_turno["objetivo"]
			en_turno["defendia"] = obj is Dictionary and obj.get("defendiendo", false)
			en_turno["pv_obj"] = obj["hp"] if obj is Dictionary else 0
			en_turno["vivos"] = c.heroes.filter(func(h): return h["hp"] > 0).map(func(h): return h["nombre"])
			cambios.clear()
			impactos0 = impactos.size()
			avisos0 = avisos[0]
			pulsos0 = int(z.get("hl_pulsos", 0))
			anillos0 = int(z.get("hl_anillos", 0))
		elif c.estado != "enemigo" and turno_z:        # acaba su turno: qué hizo
			turno_z = false
			var golpes: Array = impactos.slice(impactos0).map(func(x): return x[0])
			var n_avisos: int = avisos[0] - avisos0
			if en_turno["recupera"]:
				visto["recupera"] += 1
				_ok(golpes.is_empty() and cambios.is_empty() and c.registro.text.contains("recoge"), "A: al recuperarse golpea %s y cambia PV %s («%s»)" % [golpes, cambios, c.registro.text])
				ultimo = "recupera"
			elif en_turno["cargando"]:
				visto["mordida"] += 1
				var obj: Dictionary = en_turno["objetivo"]
				_ok(golpes == [H.MORDIDA] and cambios.size() <= 1, "A: la mordida golpea %s y cambia los PV %s" % [golpes, cambios])
				_ok(cambios.all(func(x): return x[0] == obj["nombre"]), "A: la mordida quita PV a otro que el marcado (%s): %s" % [obj["nombre"], cambios])
				_ok(H.nodos_vivos(c.enemigos).is_empty(), "A: tras la mordida sigue la marca sobre la presa")
				_ok(not z.get("cargando", false), "A: tras la mordida sigue cargando")
				if z["hp"] > 0 and z["rig"].position.distance_to(z["rig_base"]) < 1.0:
					visto["vuelta"] += 1
				if en_turno["defendia"]:
					visto["defendida"] += 1
					var sin_defensa: int = int(z["atk"] * H.MULT_MORDIDA * (1.5 if z.get("furia", false) else 1.0)) + 3 - int(obj.get("def", 0) / 2.0)
					var dano: int = en_turno["pv_obj"] - obj["hp"]
					_ok(dano >= 0 and dano <= int(sin_defensa * 0.5) + 1, "A: defendiendo, la mordida quita %d (sin defender, hasta %d)" % [dano, sin_defensa])
				ultimo = "mordida"
			elif golpes == [H.TRAMA]:
				visto["trama"] += 1
				_ok(ultimo != "trama", "A: dos tramas seguidas sin recuperarse")
				_ok(int(z.get("hl_pulsos", 0)) - pulsos0 == 1, "A: la trama se resuelve %d veces" % (int(z.get("hl_pulsos", 0)) - pulsos0))
				_ok(int(z.get("hl_anillos", 0)) - anillos0 == 1, "A: la trama abre %d anillos (uno por pulso)" % (int(z.get("hl_anillos", 0)) - anillos0))
				var quienes: Array = cambios.map(func(x): return x[0])
				var fotos: Array = cambios.map(func(x): return x[1])
				_ok(quienes.size() == en_turno["vivos"].size() and en_turno["vivos"].all(func(n): return quienes.count(n) == 1), "A: la trama no alcanza una vez a cada héroe vivo %s: %s" % [en_turno["vivos"], cambios])
				_ok(fotos.all(func(f): return f == fotos[0]), "A: la trama no se resuelve en un solo fotograma: %s" % [cambios])
				# (la prueba mira los PV al empezar cada fotograma: el daño del pulso del fotograma N se ve en el N o el N+1)
				_ok(fotos.is_empty() or fotos[0] - impactos[impactos0][1] in [0, 1], "A: el daño de la trama (fotograma %s) no va con su pulso (%d)" % [fotos, impactos[impactos0][1]])
				_ok(z.get("recupera", false) or z["hp"] <= 0, "A: tras la trama no queda recuperándose")
				ultimo = "trama"
			elif z.get("cargando", false):
				visto["marca"] += 1
				_ok(n_avisos == 1 and golpes.is_empty() and cambios.is_empty(), "A: la marca avisa %d veces, golpea %s y cambia PV %s" % [n_avisos, golpes, cambios])
				_ok(z["lbl_estado"].text.contains("Cargando"), "A: no se ve «⚠ Cargando» sobre su vida")
				var m = z.get("hl_marca", null)
				_ok(m != null and is_instance_valid(m) and m.visible and z.get("objetivo_carga", null) is Dictionary, "A: no se ve la señal sobre el héroe marcado")
				# (revisión 19/11: frase neutra, sin «lo/la», que concuerde con Lya, Naira o Nix igual que con Kael)
				var presa = z.get("objetivo_carga", null)
				var txt: String = c.registro.text
				_ok(presa is Dictionary and txt.contains(presa["nombre"]) and txt.contains("¡es su presa!") and not txt.contains("lo ha marcado"),
					"A: el registro de la marca no es la frase neutra: «%s»" % txt)
				ultimo = "marca"
			else:
				_ok(false, "A: turno sin marca, mordida, trama ni recuperación: golpes %s, avisos %d, cambios %s" % [golpes, n_avisos, cambios])
		if c.estado == "menu" and c.actor is Dictionary:
			if not _todo_visto():
				c._defender()                          # mientras no se ha visto todo, en guardia (la mordida defendida)
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(z)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 90:
			break
	_ok(c.estado == "fin" and z["hp"] <= 0 and c.heroes.any(func(h): return h["hp"] > 0), "A: los héroes no ganan (Hilandera %d PV)" % z["hp"])
	await _esperar(45)
	_ok(derrota[0] or zp._muerta, "A: la Hilandera no cae con su clip de derrota")
	_ok(H.nodos_vivos(c.enemigos).is_empty(), "A: al acabar queda su marca: %s" % [H.nodos_vivos(c.enemigos)])
	_sonidos_a(marcas)
	await _cerrar()
	hechos.append("A (semilla %d)" % semilla)


# Los sonidos de la Hilandera (sonido.gd, tanda 4): cada señal se pide UNA vez y en su mismo fotograma; la entrada, una.
func _sonidos_a(marcas: Array) -> void:
	var cuenta := func(n: String) -> int: return sonidos.filter(func(s): return s[0] == n).size()
	var de := func(q: String) -> Array: return marcas.filter(func(m): return m[0] == q)
	_ok(cuenta.call("hilandera_entrada") == 1, "sonido: la entrada se pide %d veces" % cuenta.call("hilandera_entrada"))
	for par in [["aviso:" + H.MORDIDA, "hilandera_aviso_mordida"], ["aviso:" + H.TRAMA, "hilandera_aviso_trama"],
			[H.MORDIDA, "hilandera_mordida"], [H.TRAMA, "hilandera_trama"]]:
		var senales: Array = de.call(par[0])
		var pedidos: Array = sonidos.filter(func(s): return s[0] == par[1])
		_ok(pedidos.size() == senales.size(), "sonido: %s se pide %d veces para %d señales" % [par[1], pedidos.size(), senales.size()])
		for i in mini(pedidos.size(), senales.size()):
			_ok(pedidos[i][1] == senales[i][1], "sonido: %s no va en el fotograma de su señal (%d y %d)" % [par[1], pedidos[i][1], senales[i][1]])


# ---------------------------------------------------------------- B. apagada en su grupo
func _b() -> void:
	_combate({"Kael": 5}, 11, false)
	_ok(z["personalidad"] == "agresivo" and not H.es(z), "B: apagada, la Hilandera tiene la personalidad «%s»" % z["personalidad"])
	if zp == null:
		_ok(false, "B: sin su modelo 3D")
		await _cerrar()
		return
	var impactos: Array = []
	zp.impacto.connect(func(a): impactos.append(a))
	var turno_z := false
	var turnos := 0
	var cargo := false
	for fr in 6000:
		await _esperar(1)
		if z.get("cargando", false) or z.has("hl_marca") or z.get("recupera", false):
			cargo = true
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
	_ok(turnos >= 1, "B: la Hilandera no llega a actuar")
	_ok(not cargo, "B: apagada marca, carga o se recupera")
	_ok(impactos.size() == turnos and impactos.all(func(a): return a == H.MORDIDA), "B: apagada, %d turnos y estos impactos %s" % [turnos, impactos])
	await _cerrar()
	hechos.append("B: apagada, %d turnos con la mordida" % turnos)
