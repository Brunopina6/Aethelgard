extends SceneTree
# Zarzalín enganchado al combate (T-097), en combates de verdad (combate.tscn, grupo 10), sin ventana y con datos
# aislados. El combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo.
#   A. Kael solo, nivel 1, solo con ataques: entra de un salto; avisa un turno antes (señal «aviso» del modelo, «⚠
#      Cargando» sobre su vida y ningún daño ese turno); embiste en el siguiente (un solo impacto y un solo cambio de
#      PV) y recupera el aliento el turno después; el colmillo lateral (un impacto, un cambio de PV); Kael gana y
#      Zarzalín cae con su clip de derrota. Defender ante la embestida la deja en la mitad o menos.
#   B. Kael y Lya: huir con Zarzalín vivo (no da experiencia).
# Lo que hace en cada turno lo decide el combate (con la semilla fija); si en un combate no llega a avisar o a usar el
# colmillo, la prueba repite con otra semilla (hasta 8). Ganar así no prueba la estrategia de un jugador.

const ARCHIVO := "user://prueba_zarzalin_combate.save"
const MAX_FOTOGRAMAS := 9000

var P
var G
var c = null
var z = null                                      # el diccionario de Zarzalín
var zp = null                                     # su modelo 3D
var fallos: Array = []
var hechos: Array = []
var visto := {"entrada": false, "aviso": 0, "embestida": 0, "colmillo": 0, "recupera": 0, "defendida": 0}
var fotos := ""
var n_foto := 0


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _combate(activos: Dictionary, semilla: int) -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")              # sin «zona limpia»: no huye solo
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 10)
	c = load("res://combate.tscn").instantiate()
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
	for i in 8:
		await _a(20261109 + i * 7)
		if visto["aviso"] > 0 and visto["colmillo"] > 0 and visto["defendida"] > 0:
			break
	_ok(visto["entrada"], "A: Zarzalín no entra de un salto")
	_ok(visto["aviso"] > 0 and visto["embestida"] > 0 and visto["recupera"] > 0, "A: no se vio aviso → embestida → recuperación: %s" % visto)
	_ok(visto["colmillo"] > 0, "A: no se vio el colmillo lateral: %s" % visto)
	_ok(visto["defendida"] > 0, "A: no se vio una embestida defendida: %s" % visto)
	await _b()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos), " ", visto)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- A. Kael solo
func _a(semilla: int) -> void:
	_combate({"Kael": 1}, semilla)
	_ok(z["modelo"] == "zarzalin" and zp != null and zp.has_method("avisar"), "A: el grupo 10 no es Zarzalín en 3D")
	if zp == null:
		await _cerrar()
		return
	var avisos := [0]
	var impactos := [0]
	var derrota := [false]
	zp.aviso.connect(func(_a): avisos[0] += 1)
	zp.impacto.connect(func(_a): impactos[0] += 1)
	zp.clip_terminado.connect(func(clip): if clip == "derrota": derrota[0] = true)
	if fotos != "":                                 # con «fotos=<carpeta>» (y ventana): el aviso, cada impacto y la derrota
		zp.aviso.connect(func(_a): _foto.call_deferred("aviso"))
		zp.impacto.connect(func(a): _foto.call_deferred(a))
		zp.clip_terminado.connect(func(clip): if clip == "derrota": _foto.call_deferred("derrota"))
		_foto.call_deferred("entrada")
	await _esperar(2)
	if zp._clip == "entrada" or zp._entrando:
		visto["entrada"] = true
	var kael: Dictionary = c.heroes[0]
	var pv_antes: int = kael["hp"]
	var cambios := 0
	var turno_z := false
	var cargaba := false
	var defendio := false
	var impactos0 := 0
	var avisos0 := 0
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
			pv_antes = kael["hp"]
		if c.estado != "enemigo" and not turno_z:     # cómo estaba justo antes de su turno
			cargaba_antes = z.get("cargando", false)
			recupera_antes = z.get("recupera", false)
		if c.estado == "enemigo" and not turno_z:      # empieza el turno de Zarzalín
			turno_z = true
			cargaba = cargaba_antes
			recuperaba = recupera_antes
			cambios = 0
			impactos0 = impactos[0]
			avisos0 = avisos[0]
			pv_turno = kael["hp"]
		elif c.estado != "enemigo" and turno_z:        # acaba su turno: qué hizo
			turno_z = false
			var golpes: int = impactos[0] - impactos0
			if recuperaba:
				visto["recupera"] += 1
				_ok(golpes == 0 and cambios == 0 and c.registro.text.contains("recupera"), "A: al recuperar golpea %d veces («%s»)" % [golpes, c.registro.text])
			elif cargaba:
				visto["embestida"] += 1
				_ok(golpes == 1 and cambios <= 1, "A: la embestida golpea %d veces y cambia los PV %d veces" % [golpes, cambios])
				_ok(z.get("recupera", false), "A: tras embestir no queda en recuperación")
				if defendio:
					visto["defendida"] += 1
					var sin_defensa: int = int(z["atk"] * 1.8 * (1.5 if z.get("furia", false) else 1.0)) + 3 - int(kael.get("def", 0) / 2.0)
					var dano: int = pv_turno - kael["hp"]
					_ok(dano >= 1 and dano <= int(sin_defensa * 0.5) + 1, "A: defendiendo, la embestida quita %d (sin defender, hasta %d)" % [dano, sin_defensa])
			elif z.get("cargando", false):
				visto["aviso"] += 1
				_ok(avisos[0] - avisos0 == 1 and golpes == 0 and cambios == 0, "A: el aviso avisa %d veces, golpea %d y cambia PV %d" % [avisos[0] - avisos0, golpes, cambios])
				_ok(z["lbl_estado"].text.contains("Cargando"), "A: no se ve «⚠ Cargando» sobre su vida")
			elif golpes > 0:
				visto["colmillo"] += 1
				_ok(golpes == 1 and cambios <= 1, "A: el colmillo golpea %d veces y cambia los PV %d veces" % [golpes, cambios])
			defendio = false
		if c.estado == "menu" and c.actor is Dictionary and c.actor["nombre"] == "Kael":
			if z.get("cargando", false) and visto["defendida"] == 0:
				defendio = true
				c._defender()                          # ante la embestida anunciada, en guardia
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(z)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
		if f_fin >= 0 and fr - f_fin > 90:
			break
	_ok(c.estado == "fin" and z["hp"] <= 0 and kael["hp"] > 0, "A: Kael solo no gana (Kael %d PV, Zarzalín %d)" % [kael["hp"], z["hp"]])
	await _esperar(30)
	_ok(derrota[0] or zp._muerta, "A: Zarzalín no cae con su clip de derrota")
	await _cerrar()
	hechos.append("A (semilla %d)" % semilla)


# ---------------------------------------------------------------- B. huir
func _b() -> void:
	_combate({"Kael": 2, "Lya": 1}, 7)
	for fr in 3000:
		await _esperar(1)
		if c.estado == "menu" and c.actor is Dictionary:
			break
	var exp0: int = G.datos()["Kael"]["exp"]
	c._escapar()
	await _esperar(60)
	_ok(c.estado == "fin" and z["hp"] > 0, "B: no se huye o Zarzalín no sigue vivo")
	_ok(G.datos()["Kael"]["exp"] == exp0, "B: huir da experiencia")
	await _cerrar()
	hechos.append("B: huir")


# Una captura (solo con ventana y «fotos=»): espera dos fotogramas para que se vea el golpe.
func _foto(nombre: String) -> void:
	await _esperar(2)
	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return
	n_foto += 1
	img.save_png(fotos.path_join("%02d_%s.png" % [n_foto, nombre]))
